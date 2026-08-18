"""
Panel settings and project-registry resolution for the LinkWatcher Control Panel.

The Control Panel is a *pure supervisor* (see the feature TDD, PD-TDD-033): it
holds no persistent daemon state.  The only settings it reads are a small,
all-optional ``panel-config.yaml`` file that lives beside ``main.py`` in the
install directory, plus the location of the central ``project-registry.json``
that lists the projects to supervise.

AI Context
----------
- **Entry points**:
  - :func:`load_panel_settings` — read ``<install_dir>/panel-config.yaml`` into a
    :class:`PanelSettings`, tolerating a missing file (all defaults), a partial
    file (per-key override), and invalid values (default kept + a surfaced
    warning; never raises).
  - :func:`resolve_registry_path` — locate ``project-registry.json`` via the
    precedence chain below, returning a :class:`RegistryResolution`.
- **Registry resolution order** (highest to lowest):
    1. ``--registry`` CLI argument
    2. ``LINKWATCHER_PROJECT_REGISTRY`` environment variable
    3. ``project_registry`` key in ``panel-config.yaml``
    4. ``.framework-central-pointer`` discovery — read
       ``<project-root>/process-framework/.framework-central-pointer`` (from an
       explicit ``--project-root`` first, then by walking up from the current
       working directory) and join ``process-framework-central/
       project-registry.json``.  This is the zero-config path: the hook that
       auto-opens the panel passes its own ``--project-root``, and a manual
       launch from inside any registered project is discovered by the cwd
       walk-up.  Reuses the framework's canonical "where is central?" locator
       rather than a second source of truth.
    5. Unresolved → an error state (distinct from the *empty registry* case,
       which is the calm EC-8 empty state handled downstream).
- **Testability**: ``env``, ``project_root``, and ``cwd`` are injectable seams so
  registry resolution is deterministic in tests without touching the real
  environment or the repository's own pointer file.
"""

import math
import os
from dataclasses import dataclass
from pathlib import Path
from typing import List, Mapping, NamedTuple, Optional

import yaml

# Environment variable consulted at resolution tier 2.
REGISTRY_ENV_VAR = "LINKWATCHER_PROJECT_REGISTRY"

# File name of the panel settings file, located in the install directory.
PANEL_CONFIG_FILENAME = "panel-config.yaml"

# Relative location of the central-pointer file inside a registered project,
# and of the registry inside the central directory it points at.
_POINTER_RELPATH = Path("process-framework") / ".framework-central-pointer"
_REGISTRY_RELPATH = Path("process-framework-central") / "project-registry.json"


@dataclass
class PanelSettings:
    """Operator-tunable panel settings, all optional with safe defaults.

    Loaded from ``<install_dir>/panel-config.yaml``.  The numeric fields drive
    the drain/poll timing of later phases; ``project_registry`` is an optional
    explicit path to the central ``project-registry.json`` (resolution tier 3).
    """

    grace_period_seconds: float = 20.0
    log_idle_threshold_seconds: float = 3.0
    poll_interval_seconds: float = 2.5
    project_registry: Optional[str] = None


class LoadedSettings(NamedTuple):
    """Result of :func:`load_panel_settings`: the settings plus any warnings.

    Warnings are human-readable strings describing values that were rejected
    (and defaulted).  Callers log them to the panel log and may surface them in
    the UI; tests assert on them directly.
    """

    settings: PanelSettings
    warnings: List[str]


@dataclass
class RegistryResolution:
    """Outcome of :func:`resolve_registry_path`.

    Exactly one meaningful state:
      - resolved  → ``path`` set, ``source`` in {cli, env, config, pointer}
      - unresolved → ``path`` is ``None``, ``source == "unresolved"``,
        ``error`` carries operator guidance.
    """

    path: Optional[Path]
    source: str
    error: Optional[str] = None

    @property
    def resolved(self) -> bool:
        return self.path is not None


def _coerce_positive_number(data: dict, key: str, default: float, warnings: List[str]) -> float:
    """Return a positive number for *key*, or *default* with a warning.

    Rejects (and defaults) missing keys silently, but a present-yet-invalid
    value — non-numeric, boolean, non-finite, out of float range, or
    non-positive — is defaulted *and* recorded in *warnings* so the operator
    learns their config value was ignored.

    Total by construction: every ``key in data`` path returns either *default*
    or a finite positive float.  This matters because the returned value becomes
    a thread wait interval and a deadline offset, where a non-finite number
    raises ``OverflowError`` from ``Event.wait`` far from here — outside the
    caller's try — and silently kills the discovery thread, freezing the daemon
    list on its first snapshot with no warning (CR-10).  ``.inf`` and ``.nan``
    used to pass every gate below: both are ``float`` instances, and neither
    satisfies ``value <= 0``.
    """
    if key not in data:
        return default
    value = data[key]
    # bool is a subclass of int — a stray `true`/`false` is not a valid number.
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        warnings.append(
            f"{PANEL_CONFIG_FILENAME}: '{key}' must be a positive number "
            f"(got {value!r}); using default {default}"
        )
        return default
    try:
        number = float(value)
    except (OverflowError, ValueError) as exc:
        # An integer literal too large to convert (e.g. 10**1000).
        warnings.append(
            f"{PANEL_CONFIG_FILENAME}: '{key}' is out of range ({exc}); " f"using default {default}"
        )
        return default
    if not math.isfinite(number):
        warnings.append(
            f"{PANEL_CONFIG_FILENAME}: '{key}' must be a finite number "
            f"(got {value}); using default {default}"
        )
        return default
    if number <= 0:
        warnings.append(
            f"{PANEL_CONFIG_FILENAME}: '{key}' must be positive "
            f"(got {value}); using default {default}"
        )
        return default
    return number


def _settings_from_dict(data: object, warnings: List[str]) -> PanelSettings:
    """Build a :class:`PanelSettings` from a parsed YAML mapping.

    A non-mapping document (list, scalar, ``None``) is treated as empty with a
    warning.  Unknown keys are warned about (likely typos) but ignored.
    """
    settings = PanelSettings()
    if data is None:
        return settings
    if not isinstance(data, dict):
        warnings.append(
            f"{PANEL_CONFIG_FILENAME}: expected a mapping of settings "
            f"(got {type(data).__name__}); using defaults"
        )
        return settings

    known = {
        "grace_period_seconds",
        "log_idle_threshold_seconds",
        "poll_interval_seconds",
        "project_registry",
    }
    for key in data:
        if key not in known:
            warnings.append(
                f"{PANEL_CONFIG_FILENAME}: unknown setting '{key}' — ignored " f"(possible typo?)"
            )

    settings.grace_period_seconds = _coerce_positive_number(
        data, "grace_period_seconds", settings.grace_period_seconds, warnings
    )
    settings.log_idle_threshold_seconds = _coerce_positive_number(
        data, "log_idle_threshold_seconds", settings.log_idle_threshold_seconds, warnings
    )
    settings.poll_interval_seconds = _coerce_positive_number(
        data, "poll_interval_seconds", settings.poll_interval_seconds, warnings
    )

    if "project_registry" in data:
        value = data["project_registry"]
        if isinstance(value, str) and value.strip():
            settings.project_registry = value.strip()
        elif value is not None:
            warnings.append(
                f"{PANEL_CONFIG_FILENAME}: 'project_registry' must be a path "
                f"string (got {value!r}); ignoring"
            )

    return settings


def load_panel_settings(install_dir) -> LoadedSettings:
    """Load ``<install_dir>/panel-config.yaml`` into a :class:`PanelSettings`.

    Never raises: a missing file yields all defaults; an unreadable, non-UTF-8,
    or unparseable file yields defaults with a warning.  Invalid individual
    values are defaulted per-key with a warning.  Returns the settings and the
    warning list together (:class:`LoadedSettings`).

    The non-UTF-8 case is explicit because ``read_text`` raises
    ``UnicodeDecodeError`` — a ``ValueError``, not an ``OSError`` — which used to
    escape this contract and abort panel startup before any window existed, with
    nothing written to the panel log (CR-11).
    """
    warnings: List[str] = []
    config_path = Path(install_dir) / PANEL_CONFIG_FILENAME

    if not config_path.is_file():
        return LoadedSettings(PanelSettings(), warnings)

    try:
        raw = config_path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        warnings.append(
            f"{PANEL_CONFIG_FILENAME}: is not valid UTF-8 "
            f"(byte {exc.start}: {exc.reason}); using defaults"
        )
        return LoadedSettings(PanelSettings(), warnings)
    except OSError as exc:
        warnings.append(f"{PANEL_CONFIG_FILENAME}: could not be read ({exc}); using defaults")
        return LoadedSettings(PanelSettings(), warnings)

    try:
        data = yaml.safe_load(raw)
    except yaml.YAMLError as exc:
        warnings.append(f"{PANEL_CONFIG_FILENAME}: is not valid YAML ({exc}); using defaults")
        return LoadedSettings(PanelSettings(), warnings)

    return LoadedSettings(_settings_from_dict(data, warnings), warnings)


def _discover_registry_via_pointer(
    project_root: Optional[Path], cwd: Optional[Path]
) -> Optional[Path]:
    """Locate the registry through ``.framework-central-pointer``.

    Checks an explicit *project_root* first, then walks up from *cwd* looking for
    ``process-framework/.framework-central-pointer``.  The pointer's contents are
    the central directory; the registry is ``<central>/process-framework-central/
    project-registry.json``.  Returns the registry path only when it exists on
    disk, so an unreachable central falls through to the unresolved error state
    rather than claiming a phantom path.
    """
    candidates: List[Path] = []
    if project_root is not None:
        candidates.append(Path(project_root))
    if cwd is not None:
        start = Path(cwd)
        candidates.append(start)
        candidates.extend(start.parents)

    for root in candidates:
        pointer = root / _POINTER_RELPATH
        if not pointer.is_file():
            continue
        try:
            central = pointer.read_text(encoding="utf-8").strip()
        except OSError:
            continue
        if not central:
            continue
        registry = Path(central) / _REGISTRY_RELPATH
        if registry.is_file():
            return registry
    return None


def resolve_registry_path(
    cli_registry: Optional[str] = None,
    *,
    settings: Optional[PanelSettings] = None,
    project_root: Optional[Path] = None,
    cwd: Optional[Path] = None,
    env: Optional[Mapping[str, str]] = None,
) -> RegistryResolution:
    """Resolve the path to ``project-registry.json`` via the precedence chain.

    Order: ``cli_registry`` → ``LINKWATCHER_PROJECT_REGISTRY`` (``env``) →
    ``settings.project_registry`` → ``.framework-central-pointer`` discovery
    (``project_root`` then ``cwd`` walk-up) → unresolved.

    The three explicit sources return the path they name *as given* (existence is
    checked later, by discovery, which can then surface an informative
    "configured but missing" error).  Pointer discovery, being a best-effort
    auto-locate, only counts when the derived registry actually exists.

    ``env``, ``cwd``, and ``project_root`` are injectable for tests; ``env``
    defaults to ``os.environ`` and ``cwd`` to the process working directory.
    """
    env = os.environ if env is None else env

    if cli_registry:
        return RegistryResolution(Path(cli_registry), "cli")

    env_value = env.get(REGISTRY_ENV_VAR)
    if env_value:
        return RegistryResolution(Path(env_value), "env")

    if settings is not None and settings.project_registry:
        return RegistryResolution(Path(settings.project_registry), "config")

    effective_cwd = Path.cwd() if cwd is None else Path(cwd)
    discovered = _discover_registry_via_pointer(project_root, effective_cwd)
    if discovered is not None:
        return RegistryResolution(discovered, "pointer")

    return RegistryResolution(
        None,
        "unresolved",
        error=(
            "Could not locate project-registry.json. Provide it with --registry, "
            f"the {REGISTRY_ENV_VAR} environment variable, or the "
            f"'project_registry' key in {PANEL_CONFIG_FILENAME}; or launch from "
            "within a registered project so the central pointer can be found."
        ),
    )
