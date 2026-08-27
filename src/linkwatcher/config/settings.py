"""
Configuration classes for the LinkWatcher system.

This module provides configuration management with support for
loading from files, environment variables, and programmatic settings.

AI Context
----------
- **Entry point**: ``LinkWatcherConfig`` dataclass — instantiated by
  service or tests.  Class methods ``from_file()``, ``from_env()``,
  and ``from_dict()`` provide alternative constructors.
- **Precedence chain**: defaults → file → env → CLI, combined via
  ``merge()`` (other's non-default values override this config's).
- **Common tasks**:
  - Adding a config field: add a dataclass field with default, then
    add its env-var mapping in ``from_env()`` and YAML key handling
    in ``_from_dict()``.  Update config-examples/ YAML files.
  - Debugging config loading: ``_from_dict()`` uses ``get_type_hints``
    to auto-detect ``Set`` fields and convert lists to sets;
    ``from_file()`` delegates to PyYAML/json.
  - Understanding type coercion: both ``_from_dict()`` and ``from_env()``
    use type-hint reflection to handle ``Set[str]`` fields generically.
"""

import dataclasses
import json
import logging
import os
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, get_type_hints

import yaml

logger = logging.getLogger(__name__)

# Numeric fields whose lower bound differs from the default "must be positive".
#
# ``log_file_backup_count: 0`` is a real setting rather than a mistake:
# ``TimestampRotatingFileHandler.doRollover`` guards its pruning branch with
# ``if self.backupCount > 0``, so 0 means "rotate but never prune".  Applying
# the blanket positive rule here would reject a value the code deliberately
# handles (PD-BUG-127).
#
# ``watch_liveness_failure_threshold: 2`` is the opposite case — a floor that
# rejects values the default rule would *accept*.  1 is positive, so nothing
# else here would stop it, yet it makes the first missed probe stop the daemon
# and silently voids the guarantee stated in FDD 1.1.1-EC-11 that a single
# missed probe never does (PD-BUG-139).
_NUMERIC_MINIMUMS = {"log_file_backup_count": 0, "watch_liveness_failure_threshold": 2}

# Fields where the schema's ``int`` is load-bearing at runtime, not merely
# nominal.  ``doRollover`` slices with ``backups[self.backupCount:]``, and a
# slice index must be a real ``int`` — ``3.5`` *and* ``3.0`` both raise
# ``TypeError`` there, long after startup (PD-BUG-127).
_WHOLE_NUMBER_MESSAGE = "a whole number"


def _schema_fields(*wanted) -> tuple:
    """Names of ``LinkWatcherConfig`` fields whose declared type is in ``wanted``.

    Coverage is derived from the dataclass rather than listed by hand, so a
    field added to the schema cannot be silently left unvalidated.  That is the
    exact failure this bug records: ``validate()`` iterated a hardcoded list of
    five numeric fields while the schema declared seven, and the two omissions
    (``log_file_max_size_mb``, ``log_file_backup_count``) reached the logging
    handler unchecked (PD-BUG-127).  The same hardcoding in the former
    ``_SET_FIELDS`` tuple was tracked as TD275 and is closed by this helper.
    """
    hints = get_type_hints(LinkWatcherConfig)
    return tuple(
        f.name for f in dataclasses.fields(LinkWatcherConfig) if hints.get(f.name) in wanted
    )


def _numeric_issue(name: str, value: Any) -> Optional[str]:
    """Issue text for one numeric field, or ``None`` when the value is valid.

    Order matters: the "is it a number at all" check runs first so that a
    ``str`` or ``bool`` on an ``int``-declared field keeps the wording the
    PD-BUG-123 suite pins byte-identically.
    """
    if not _is_number(value):
        return _wrong_type(name, value, "a number")

    # An ``int``-declared field means a real ``int``: a whole-valued float is
    # still rejected by a slice index (PD-BUG-127).
    if name in _schema_fields(int) and not isinstance(value, int):
        return _wrong_type(name, value, _WHOLE_NUMBER_MESSAGE)

    minimum = _NUMERIC_MINIMUMS.get(name)
    if minimum is None:
        if value <= 0:
            return f"{name} must be positive"
    elif value < minimum:
        # A floor of 0 reads naturally as "not negative"; any other floor has
        # to state the number, or the message misdescribes the rule.
        return (
            f"{name} must not be negative" if minimum == 0 else f"{name} must be at least {minimum}"
        )

    return None


def is_usable(name: str, value: Any) -> bool:
    """True when ``value`` is a valid setting for the numeric field ``name``.

    Exposed for ``main._apply_logging_config``, which consumes two numeric
    fields *before* ``validate()`` runs and must degrade to the schema default
    rather than carry an unusable value into the logging handler (PD-BUG-127).
    """
    return _numeric_issue(name, value) is None


def schema_default(name: str) -> Any:
    """The dataclass default for ``name`` — the value to fall back to."""
    for f in dataclasses.fields(LinkWatcherConfig):
        if f.name == name:
            return f.default
    raise KeyError(name)


def _is_number(value: Any) -> bool:
    """True for a real int/float, excluding ``bool``.

    ``bool`` is a subclass of ``int``, so ``max_file_size_mb: true`` would
    otherwise satisfy ``value <= 0`` as False and sail through validation as a
    silent size of 1 (PD-BUG-123).
    """
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _is_string_collection(value: Any) -> bool:
    """True for a collection of strings — the authored form of a ``Set[str]``.

    A bare ``str`` is deliberately excluded: ``monitored_extensions: ".md"``
    used to be coerced by ``set(value)`` into ``{'.', 'm', 'd'}``, turning one
    plausible operator mistake into three nonsense extensions (PD-BUG-123).
    """
    if not isinstance(value, (set, frozenset, list, tuple)):
        return False
    return all(isinstance(item, str) for item in value)


def _wrong_type(name: str, value: Any, expected: str) -> str:
    """Render the issue text for a type-invalid config value."""
    return f"{name} must be {expected} (got {type(value).__name__})"


def _extension_fields() -> tuple:
    """Names of ``LinkWatcherConfig`` fields whose values are file extensions.

    Membership follows the ``_extensions`` name suffix every such field already
    uses, so a field added later is checked without being listed here — the
    same derive-rather-than-list rule ``_schema_fields`` applies to the numeric
    checks.  Naming one field literally is exactly what let the other two
    through: ``validation_extensions`` and ``parser_type_extensions`` were both
    unchecked, and both fail silently by matching nothing (PD-BUG-129).
    """
    return tuple(
        f.name for f in dataclasses.fields(LinkWatcherConfig) if f.name.endswith("_extensions")
    )


def _extension_issues(name: str, value: Any) -> List[str]:
    """Issues for one extension-bearing field — empty when every entry is sound.

    Two declared shapes carry extensions: a ``Set[str]`` holds them directly,
    while ``parser_type_extensions`` is a ``Dict[str, str]`` whose *values* are
    the extensions.  A wrongly typed value produces nothing here — the type
    check in ``validate()`` already names that key, and a second issue for the
    same key would only bury it (the PD-BUG-123 ordering rule).

    Case is deliberately not an issue: ``should_monitor_file`` compares
    extensions case-insensitively, so ``.MD`` is a working entry rather than a
    mistake.  A *missing dot* is an issue because it can never match a
    ``splitext`` suffix, which always carries one.
    """
    if isinstance(value, dict):
        entries = [v for v in value.values() if isinstance(v, str)]
    elif _is_string_collection(value):
        entries = list(value)
    else:
        return []

    # Sorted so the issue list is stable — these fields are sets.
    return [
        f"{name} entry '{entry}' should start with a dot"
        for entry in sorted(entries)
        if not entry.startswith(".")
    ]


@dataclass
class LinkWatcherConfig:
    """Configuration for the LinkWatcher real-time link maintenance system.

    Configuration precedence (highest to lowest):
        1. CLI arguments — passed directly to LinkWatcherConfig fields
        2. Environment variables — loaded via ``from_env(prefix)``
        3. Configuration file (YAML/JSON) — loaded via ``from_file(path)``
        4. Dataclass defaults — defined on each field below

    Use ``merge()`` to combine two configs: the *other* config's explicitly set
    values override *this* config's values, which enables the precedence
    chain (e.g., ``file_config.merge(env_config).merge(cli_config)``).

    "Explicitly set" means assigned *after* construction — which is what
    ``_from_dict()`` and ``from_env()`` both do, so the file and environment
    layers are recorded automatically.  ``merge()`` used to infer it from
    ``value != default`` instead, which cannot distinguish a field set to its
    own default from one never set at all, so an environment variable set to a
    default was silently discarded and the config file won (PD-BUG-143).  A
    config built by keyword records nothing and keeps the historical
    value-vs-default behaviour, so library callers are unaffected.

    Configuration groups:
        - **File monitoring**: ``monitored_extensions``, ``ignored_directories``
        - **Parsers**: ``enable_<format>_parser`` flags
        - **Update behavior**: ``create_backups``, ``dry_run_mode``, ``atomic_updates``
        - **Performance**: ``max_file_size_mb``, ``initial_scan_enabled``,
          ``scan_progress_interval``
        - **Logging**: ``log_level``, ``colored_output``, ``log_file``,
          ``json_logs``, etc.
        - **Validation**: ``validation_extensions``,
          ``validation_extra_ignored_dirs``,
          ``validation_ignored_patterns``, ``validation_ignore_file``,
          ``validation_output_dir``, ``path_resolution_overrides``
        - **Move detection timing**: ``move_detect_delay``,
          ``dir_move_max_timeout``, ``dir_move_settle_delay``
    """

    # File monitoring settings
    # Single source of truth for the default schema values (PD-BUG-103) —
    # DEFAULT_CONFIG in defaults.py is instantiated from these, never
    # re-declared.
    monitored_extensions: Set[str] = field(
        default_factory=lambda: {
            # Documentation and text files
            ".md",
            ".txt",
            ".yaml",
            ".yml",
            ".json",
            ".xml",
            ".csv",
            # Web development files
            ".html",
            ".htm",
            ".css",
            ".js",
            ".ts",
            ".jsx",
            ".tsx",
            ".vue",
            ".php",
            # Image files (commonly referenced)
            ".png",
            ".jpg",
            ".jpeg",
            ".gif",
            ".svg",
            ".webp",
            ".ico",
            # Document files
            ".pdf",
            # Source code files (project-specific, but commonly referenced)
            ".py",
            ".dart",
            ".ps1",
            ".psm1",
            # Script and config files (PD-BUG-058)
            ".bat",
            ".toml",
            # Media files (commonly referenced in documentation)
            ".mp4",
            ".mp3",
            ".wav",
        }
    )

    # Entries are matched per path component (basename), see
    # FileEventHandler._is_in_ignored_directory and should_monitor_file.
    ignored_directories: Set[str] = field(
        default_factory=lambda: {
            ".git",
            ".dart_tool",
            "node_modules",
            ".vscode",
            "build",
            "dist",
            "__pycache__",
            ".pytest_cache",
            "coverage",
            "target",
            "bin",
            "obj",
            "tests",
            # Covers process-framework/tools/linkWatcher
            # (shareable framework asset, intentionally static)
            "linkWatcher",
        }
    )

    # Parser settings
    enable_markdown_parser: bool = True
    enable_yaml_parser: bool = True
    enable_json_parser: bool = True
    enable_dart_parser: bool = True
    enable_python_parser: bool = True
    enable_powershell_parser: bool = True
    enable_generic_parser: bool = True

    # Update behavior
    create_backups: bool = False
    dry_run_mode: bool = False
    atomic_updates: bool = True

    # Performance settings
    max_file_size_mb: int = 10
    initial_scan_enabled: bool = True
    scan_progress_interval: int = 50

    # Logging settings
    log_level: str = "INFO"
    colored_output: bool = True
    show_statistics: bool = True
    log_file: Optional[str] = None
    log_file_max_size_mb: int = 10
    log_file_backup_count: int = 5
    json_logs: bool = False
    show_log_icons: bool = True
    performance_logging: bool = False

    # Validation settings
    validation_extensions: Set[str] = field(
        default_factory=lambda: {
            ".md",
            ".yaml",
            ".yml",
            ".json",
        }
    )
    validation_extra_ignored_dirs: Set[str] = field(
        default_factory=lambda: {
            "linkWatcher",  # basename match (see ignored_directories comment)
            "old",
            "archive",
            "fixtures",
            "e2e-acceptance-testing",
            "config-examples",
        }
    )
    # Substring patterns matched against link targets during --validate.
    # A broken-link report is suppressed when any pattern appears in the
    # target path (e.g., "path/to/" skips all placeholder paths).
    validation_ignored_patterns: Set[str] = field(
        default_factory=lambda: {
            "path/to/",
            "xxx",
            "LinkWatcher/",
        }
    )
    validation_ignore_file: str = "tools/linkwatcher/.linkwatcher-ignore"

    # Directory (relative to project root) where validation reports are written.
    # When None, falls back to the parent directory of `--log-file` if set,
    # else the project root (legacy behavior).
    validation_output_dir: Optional[str] = "logs/linkwatcher"

    # Parser type-to-extension mapping for extension-aware suffix matching.
    # When the database matches extensionless references (e.g., Python imports)
    # against full file paths, only the mapped extension is considered valid.
    # Types not listed here allow any extension during suffix matching.
    parser_type_extensions: Dict[str, str] = field(
        default_factory=lambda: {
            "python": ".py",
            "dart": ".dart",
        }
    )

    # Per-folder path-resolution overrides for --validate.  Maps a folder
    # (relative to project_root, forward slashes) to an effective resolution
    # base for absolute-from-host links — those starting with "/" — authored in
    # files under that folder.  A blueprint/template folder that ships to other
    # projects (where it becomes the root) writes its "/..." links from the
    # rollout target's perspective; without an override they resolve against
    # <project_root>/ and are reported broken.  With
    #   path_resolution_overrides: {"appdev/blueprint": "appdev/blueprint"}
    # a "/process-framework/x.md" link in appdev/blueprint/foo.md resolves
    # against <project_root>/appdev/blueprint/ instead.  Longest-prefix match
    # wins when folders nest.  Files outside every configured folder are
    # unaffected — their "/..." links still resolve against <project_root>/.
    # Default {} = no-op (validation behavior unchanged when the key is
    # absent).  Validation-only — does not affect the live link-updating
    # pipeline.  NOTE: like parser_type_extensions, env-var loading does not
    # special-case Dict fields, so set this via a config file, not LINKWATCHER_*.
    path_resolution_overrides: Dict[str, str] = field(default_factory=dict)

    # Python source root — when set, strip this prefix from file paths
    # before comparing with Python import targets.  For src/ layout projects,
    # set to "src" so that "src/package/module.py" resolves to "package.module"
    # rather than "src.package.module".  Read from project-config.json
    # paths.source_code at startup; overridable via config file or env var.
    python_source_root: str = ""

    # Move detection timing
    move_detect_delay: float = 10.0
    dir_move_max_timeout: float = 300.0
    dir_move_settle_delay: float = 5.0

    # Watch liveness monitoring (PD-BUG-139).  A watchdog observer can stay
    # alive while its event emitter is gone, leaving the daemon permanently
    # blind but reporting healthy.  These settings govern the delivery check
    # that detects it.  Defaults are deliberately conservative: the probe only
    # runs after a minute of total silence, and three consecutive misses are
    # required before the daemon stops, so a momentarily slow filesystem
    # cannot take down a working watch.
    watch_liveness_enabled: bool = True
    watch_liveness_idle_seconds: float = 60.0
    watch_liveness_probe_timeout: float = 10.0
    watch_liveness_failure_threshold: int = 3

    # ``_EXPLICIT`` is bookkeeping, not a schema field: it is deliberately not
    # declared as a dataclass field so it stays out of ``dataclasses.fields()``
    # — which the validation helpers, the schema-drift test and the docs
    # generator all derive their coverage from.  It lives in ``__dict__``, so
    # every consumer that walks ``__dict__`` (``to_dict`` and both ``merge``
    # loops — the only three in the codebase) skips ``_``-prefixed keys.
    _EXPLICIT = "_explicit_fields"

    def __post_init__(self):
        """Start recording assignments once the generated ``__init__`` is done.

        The record has to be created *here* rather than as a field: the
        dataclass ``__init__`` assigns every field through ``__setattr__``, so
        a record that already existed during ``__init__`` would mark all 39
        fields as explicitly set — and ``from_env()``, which starts from a
        plain ``cls()``, would then override every field in the config it is
        merged into (PD-BUG-143).
        """
        object.__setattr__(self, self._EXPLICIT, set())

    def __setattr__(self, name: str, value: Any):
        """Record post-construction assignments so ``merge()`` knows intent.

        During ``__init__`` the record does not exist yet and nothing is
        tracked — see ``__post_init__``.
        """
        explicit = self.__dict__.get(self._EXPLICIT)
        if explicit is not None and not name.startswith("_"):
            explicit.add(name)
        object.__setattr__(self, name, value)

    def _explicitly_set(self) -> Set[str]:
        """Field names assigned after construction (empty for a plain build)."""
        return self.__dict__.get(self._EXPLICIT) or set()

    @classmethod
    def from_file(cls, config_path: str) -> "LinkWatcherConfig":
        """Load configuration from a file."""
        config_path = Path(config_path)

        if not config_path.exists():
            raise FileNotFoundError(f"Configuration file not found: {config_path}")

        if config_path.suffix.lower() == ".json":
            return cls._from_json(config_path)
        elif config_path.suffix.lower() in [".yaml", ".yml"]:
            return cls._from_yaml(config_path)
        else:
            raise ValueError(f"Unsupported configuration file format: {config_path.suffix}")

    @classmethod
    def _from_json(cls, config_path: Path) -> "LinkWatcherConfig":
        """Load configuration from JSON file."""
        with open(config_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return cls._from_dict(data)

    @classmethod
    def _from_yaml(cls, config_path: Path) -> "LinkWatcherConfig":
        """Load configuration from YAML file."""
        with open(config_path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return cls._from_dict(data)

    @classmethod
    def _from_dict(cls, data: Dict[str, Any]) -> "LinkWatcherConfig":
        """Create configuration from dictionary."""
        config = cls()
        known_fields = {f.name for f in dataclasses.fields(cls)}
        type_hints = get_type_hints(cls)

        # Warn about unknown keys (likely typos)
        for key in data:
            if key not in known_fields:
                logger.warning("Unknown configuration key '%s' — ignored (possible typo?)", key)

        for key, value in data.items():
            if key.startswith("_") or key not in known_fields:
                continue
            field_type = type_hints.get(key)
            if (field_type is Set[str] or field_type is set) and _is_string_collection(value):
                setattr(config, key, set(value))
            else:
                # A wrongly typed value is stored as authored rather than
                # coerced, so validate() can report it naming the key.  set()
                # used to raise here on a non-iterable — before validate(), the
                # function whose job is to report it, was ever reached
                # (PD-BUG-123).
                setattr(config, key, value)

        return config

    @classmethod
    def from_env(cls, prefix: str = "LINKWATCHER_") -> "LinkWatcherConfig":
        """Load configuration from environment variables.

        Environment variable names are derived from field names:
        ``{prefix}{FIELD_NAME_UPPER}`` — e.g. ``LINKWATCHER_DRY_RUN_MODE``.

        Type conversion is automatic based on the field's type annotation:
        ``Set[str]`` splits on ``,``; ``bool`` accepts true/1/yes/on;
        ``int`` and ``float`` are parsed; everything else is kept as a string.
        """
        config = cls()
        type_hints = get_type_hints(cls)

        for f in dataclasses.fields(cls):
            env_var = f"{prefix}{f.name.upper()}"
            if env_var not in os.environ:
                continue

            value = os.environ[env_var]
            field_type = type_hints[f.name]

            if field_type is Set[str] or field_type is set:
                setattr(config, f.name, set(value.split(",")))
            elif field_type is bool:
                setattr(config, f.name, value.lower() in ("true", "1", "yes", "on"))
            elif field_type is int:
                try:
                    setattr(config, f.name, int(value))
                except ValueError:
                    logger.warning(
                        "Invalid value '%s' for env var %s (expected int) — using default",
                        value,
                        env_var,
                    )
            elif field_type is float:
                try:
                    setattr(config, f.name, float(value))
                except ValueError:
                    logger.warning(
                        "Invalid value '%s' for env var %s (expected float) — using default",
                        value,
                        env_var,
                    )
            else:
                setattr(config, f.name, value)

        return config

    def to_dict(self) -> Dict[str, Any]:
        """Convert configuration to dictionary."""
        result = {}

        for key, value in self.__dict__.items():
            # ``_``-prefixed keys are bookkeeping (PD-BUG-143). This dict feeds
            # ``save_to_file``, so letting one through would write a private
            # attribute into the user's YAML or JSON.
            if key.startswith("_"):
                continue
            if isinstance(value, set):
                result[key] = list(value)
            else:
                result[key] = value

        return result

    def save_to_file(self, config_path: str, format: str = "yaml"):
        """Save configuration to file."""
        config_path = Path(config_path)
        data = self.to_dict()

        if format.lower() not in ("json", "yaml", "yml"):
            raise ValueError(f"Unsupported format: {format}")

        # Write to a temporary file first, then atomically replace the target
        dir_path = str(config_path.parent)
        temp_fd = None
        temp_path = None
        try:
            temp_fd, temp_path = tempfile.mkstemp(dir=dir_path, suffix=config_path.suffix)
            with os.fdopen(temp_fd, "w", encoding="utf-8") as f:
                temp_fd = None  # os.fdopen takes ownership of the fd
                if format.lower() == "json":
                    json.dump(data, f, indent=2)
                else:
                    yaml.dump(data, f, default_flow_style=False, indent=2)
            os.replace(temp_path, str(config_path))
            temp_path = None  # successfully moved
        finally:
            if temp_fd is not None:
                os.close(temp_fd)
            if temp_path is not None:
                try:
                    os.unlink(temp_path)
                except OSError:
                    pass

    def merge(self, other: "LinkWatcherConfig") -> "LinkWatcherConfig":
        """Merge this configuration with another, returning a new instance.

        ``other`` wins for every field it set explicitly.  Where it recorded
        nothing — a config built by keyword rather than loaded — the historical
        ``value != default`` inference applies, so programmatic callers keep
        their behaviour (PD-BUG-143).
        """
        merged = LinkWatcherConfig()
        default_config = LinkWatcherConfig()
        other_explicit = other._explicitly_set()

        def _assign(key, value):
            # object.__setattr__, not setattr: copying a field is not the
            # caller expressing intent about it.  Recording these would mark
            # all 39 fields explicit on the result, so merging that result
            # into a third config would overwrite every field of the target.
            object.__setattr__(merged, key, value.copy() if isinstance(value, set) else value)

        # Start with this config's values
        for key, value in self.__dict__.items():
            if key.startswith("_"):
                continue
            _assign(key, value)

        # Override with the other config's values
        for key, value in other.__dict__.items():
            if key.startswith("_"):
                continue

            # Explicitly set wins outright — including when it equals the
            # schema default, which is exactly the case the old
            # value-vs-default inference discarded.
            if key in other_explicit or value != getattr(default_config, key):
                _assign(key, value)

        # The result inherits both inputs' intent, so it can be merged again.
        object.__setattr__(
            merged, self._EXPLICIT, set(self._explicitly_set()) | set(other_explicit)
        )

        return merged

    def validate(self) -> List[str]:
        """Validate configuration and return list of issues.

        **Never raises.** A wrongly typed value is reported as an issue naming
        the key, not thrown (PD-BUG-123).  This method's contract is to *return*
        what is wrong, and its callers rely on that: the daemon calls it during
        startup inside a broad ``except Exception``, so an exception escaping
        here becomes one generic ``fatal_error`` carrying a raw Python message
        instead of the precise per-key ``config_issue`` lines written just below
        that call — leaving the operator with no idea which key is at fault.
        """
        issues = []

        # Check every numeric field the schema declares.  Both the field set
        # and the int-vs-number rule come from the dataclass type hints, so a
        # numeric field added later cannot be left silently unvalidated the way
        # the two log-rotation fields were (PD-BUG-127).
        for name in _schema_fields(int, float):
            issue = _numeric_issue(name, getattr(self, name))
            if issue:
                issues.append(issue)

        # Check log level (a non-str value is reported as the same issue — the
        # key still simply does not name a valid level)
        valid_log_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        if not isinstance(self.log_level, str) or self.log_level.upper() not in valid_log_levels:
            issues.append(f"log_level must be one of: {valid_log_levels}")

        # Check set-valued fields carry a collection of strings.  ``_from_dict``
        # leaves a wrongly typed value raw instead of raising (PD-BUG-123), so
        # every declared Set[str] must be checked here — otherwise that
        # tolerance trades a loud load-time failure for a later runtime one.
        for name in _schema_fields(Set[str], set):
            value = getattr(self, name)
            if not _is_string_collection(value):
                issues.append(_wrong_type(name, value, "a list of strings"))

        # Check extensions format across every field that holds extensions —
        # each only once the value itself is sound, since the type issue above
        # already names a wrongly typed one.
        for name in _extension_fields():
            issues.extend(_extension_issues(name, getattr(self, name)))

        return issues
