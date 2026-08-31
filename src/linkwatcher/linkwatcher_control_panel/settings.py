"""
Panel settings and child-registry resolution for the LinkWatcher Control Panel.

The Control Panel is a *pure supervisor* (see the feature TDD, PD-TDD-033): it
holds no persistent daemon state.  The only settings it reads are a small,
all-optional ``panel-config.yaml`` file that lives beside ``main.py`` in the
install directory, plus the location of the child registry that lists the
workspaces to supervise (``project-registry.json``, or ``framework-registry.json``
at a framework-builder).

AI Context
----------
- **Entry points**:
  - :func:`load_panel_settings` — read ``<install_dir>/panel-config.yaml`` into a
    :class:`PanelSettings`, tolerating a missing file (all defaults), a partial
    file (per-key override), and invalid values (default kept + a surfaced
    warning; never raises).
  - :func:`resolve_registry_path` — locate the child registry via the
    precedence chain below, returning a :class:`RegistryResolution`.
- **Registry resolution order** (highest to lowest):
    1. ``--registry`` CLI argument
    2. ``LINKWATCHER_PROJECT_REGISTRY`` environment variable
    3. ``project_registry`` key in ``panel-config.yaml``
    4. Workspace-owned child registry — when the workspace root owns a
       ``process-framework-central/`` holding a child registry, supervise from
       it.  This answers for a non-leaf workspace (a framework lists its
       projects; a framework-builder lists its frameworks).  The root is
       ``--project-root`` when given, else the current directory taken exactly
       (never walked up — see :func:`resolve_registry_path`).
    5. Parent-pointer discovery — read the parent-pointer in the workspace's
       framework face (from an explicit ``--project-root`` first, then by walking
       up from the current working directory) and use the child registry that
       parent owns.  This answers for a **leaf** workspace, whose supervisor list
       genuinely lives in its parent.  Tiers 4-5 are the zero-config path: the
       hook that auto-opens the panel passes its own ``--project-root``; a manual
       launch is answered by the implied root when it is standing in a workspace
       that owns a registry, and by the cwd walk-up from anywhere inside a leaf.
    6. Unresolved → an error state (distinct from the *empty registry* case,
       which is the calm EC-8 empty state handled downstream).
- **Testability**: ``env``, ``project_root``, and ``cwd`` are injectable seams so
  registry resolution is deterministic in tests without touching the real
  environment or the repository's own pointer file.
"""

import json
import math
import os
from dataclasses import dataclass
from pathlib import Path
from typing import List, Mapping, NamedTuple, Optional, Set

import yaml

from .panel_log import get_panel_logger

# Environment variable consulted at resolution tier 2.
REGISTRY_ENV_VAR = "LINKWATCHER_PROJECT_REGISTRY"

# File name of the panel settings file, located in the install directory.
PANEL_CONFIG_FILENAME = "panel-config.yaml"

# Name of the directory holding a workspace's child registry, and the registry
# filenames that may live there.  A workspace indexes its children under a
# role-derived filename — a framework lists projects, a framework-builder lists
# frameworks — so both names are recognized (PD-BUG-148).  The list is explicit
# rather than a glob: the same directory also holds ID registries
# (``PF-id-registry-central.json``), which are not child registries.
_CENTRAL_DIRNAME = "process-framework-central"
_CHILD_REGISTRY_FILENAMES = ("project-registry.json", "framework-registry.json")

# The pointer file naming a workspace's parent, inside its framework face.  The
# canonical name is ``.framework-parent-pointer``; the legacy name is still
# present in the field and remains accepted.
_FACE_DIRNAME = "process-framework"
_POINTER_FILENAMES = (".framework-parent-pointer", ".framework-central-pointer")

# Where a workspace declares its own layout, including the face location.
_PROJECT_CONFIG_RELPATH = Path("doc") / "project-config.json"


def workspace_face_dir(root: Path) -> Path:
    """Return *root*'s framework face directory.

    The face is usually ``<root>/process-framework``, but a workspace may declare
    another location in ``doc/project-config.json`` (``paths.process_framework``)
    — a self-hosted producer keeps its face under ``blueprint/``, for instance.
    Consulting the declaration keeps the panel from assuming one layout for every
    workspace (PD-BUG-148).

    Falls back to the conventional location whenever the declaration is missing,
    unreadable, or malformed: this is a best-effort locator, never a hard
    dependency on a workspace shipping a config file.
    """
    default = Path(root) / _FACE_DIRNAME
    try:
        data = json.loads((Path(root) / _PROJECT_CONFIG_RELPATH).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return default
    if not isinstance(data, dict):
        return default
    paths = data.get("paths")
    declared = paths.get("process_framework") if isinstance(paths, dict) else None
    if isinstance(declared, str) and declared.strip():
        return Path(root) / declared.strip()
    return default


@dataclass
class PanelSettings:
    """Operator-tunable panel settings, all optional with safe defaults.

    Loaded from ``<install_dir>/panel-config.yaml``.  The numeric fields drive
    the drain/poll timing of later phases; ``project_registry`` is an optional
    explicit path to a child registry (resolution tier 3).
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
      - resolved  → ``path`` set, ``source`` in
        {cli, env, config, workspace, pointer}
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


def _own_child_registry(root: Path, reported: Optional[Set[str]] = None) -> Optional[Path]:
    """Return the child registry *root* owns, or ``None`` if it owns none.

    A workspace that has children keeps their registry in its own
    ``process-framework-central/``.  A leaf workspace has no children and so no
    such directory — that is the signal to fall back to the parent hop, not an
    error.

    The recognized filenames are an enumeration of the roles that exist today.
    A central directory holding *some other* registry is therefore a role
    divergence, and falling through silently would repeat this bug's own failure
    shape: the panel would show the PARENT's list under a perfectly ordinary
    ``registry resolved via pointer:`` line.  The fall-through is right; being
    quiet about it is not, so that one case is logged (PD-BUG-148).

    *reported* carries the central directories already reported within one
    resolution, so a directory examined twice is not two findings: a self-hosted
    producer's pointer names itself, and the same central is then reached at the
    own-registry tier and again through the parent hop.  De-duplication is per
    directory, never a one-shot latch — a leaf and its parent both diverging are
    two genuine findings.
    """
    central = Path(root) / _CENTRAL_DIRNAME
    for filename in _CHILD_REGISTRY_FILENAMES:
        registry = central / filename
        if registry.is_file():
            return registry
    if central.is_dir():
        key = os.path.normcase(str(central))
        if reported is None or key not in reported:
            if reported is not None:
                reported.add(key)
            get_panel_logger().warning(
                "central_registry_unrecognized dir=%s looked_for=%s",
                central,
                ",".join(_CHILD_REGISTRY_FILENAMES),
            )
    return None


def _read_parent_pointer(root: Path) -> Optional[Path]:
    """Return the parent workspace *root* points at, or ``None``.

    ``UnicodeDecodeError`` is guarded alongside ``OSError``: it is a
    ``ValueError``, so it escaped this contract and propagated out of resolution,
    aborting the panel before any window existed — the same class that once broke
    ``load_panel_settings`` (CR-11).  An unreadable pointer skips to the next
    filename rather than abandoning the tier, so a workspace still mid-migration
    resolves through its legacy pointer (PD-BUG-148).
    """
    face = workspace_face_dir(root)
    for filename in _POINTER_FILENAMES:
        pointer = face / filename
        if not pointer.is_file():
            continue
        try:
            parent = pointer.read_text(encoding="utf-8").strip()
        except (OSError, UnicodeDecodeError) as exc:
            get_panel_logger().warning("parent_pointer_unreadable path=%s error=%s", pointer, exc)
            continue
        if parent:
            return Path(parent)
    return None


def _discover_registry_via_pointer(
    project_root: Optional[Path], cwd: Optional[Path], reported: Optional[Set[str]] = None
) -> Optional[Path]:
    """Locate the registry by following a workspace's parent-pointer.

    Checks an explicit *project_root* first, then walks up from *cwd*.  The
    pointer names the parent workspace; the registry is the child registry that
    parent owns.  Returns a path only when the registry exists on disk, so an
    unreachable parent falls through to the unresolved error state rather than
    claiming a phantom path.

    This tier answers for a **leaf** workspace, whose supervisor list genuinely
    lives in its parent.  A workspace that owns a child registry is answered
    earlier, by :func:`_own_child_registry` — see ``resolve_registry_path``.
    """
    candidates: List[Path] = []
    if project_root is not None:
        candidates.append(Path(project_root))
    if cwd is not None:
        start = Path(cwd)
        candidates.append(start)
        candidates.extend(start.parents)

    for root in candidates:
        parent = _read_parent_pointer(root)
        if parent is None:
            continue
        registry = _own_child_registry(parent, reported)
        if registry is not None:
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
    """Resolve the path to the child registry via the precedence chain.

    Order: ``cli_registry`` → ``LINKWATCHER_PROJECT_REGISTRY`` (``env``) →
    ``settings.project_registry`` → the child registry the workspace root owns
    (``project_root``, else ``cwd`` taken exactly) → parent-pointer discovery
    (``project_root`` then ``cwd`` walk-up) → unresolved.

    The two auto-locate tiers split by workspace shape: a non-leaf workspace owns
    its children's registry and supervises from it; a leaf owns none and hops to
    the one its parent owns.  The own-registry tier accepts an *implied* root —
    the cwd — because the launchers pass no ``--project-root``, but only the cwd
    itself: an ancestor's registry is one merely walked past, and adopting a
    producer's zero-row seed would render "no registered projects" while daemons
    were in fact running.

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
    # A workspace that owns a child registry supervises from it directly.  The
    # root is the one ``--project-root`` names, or — when none is given, which is
    # what the launchers do — the directory the operator is standing in.  Without
    # that implied root this tier was unreachable from a manual launch, so a
    # non-leaf workspace silently got its PARENT's registry (PD-BUG-148 CR-1).
    #
    # The implied root is the cwd EXACTLY and is never walked up.  A walk-up
    # would adopt a registry it merely walked past — a producer's blueprint tree
    # carries a zero-row seed registry, and resolving to it renders the calm
    # "no registered projects" empty state, a wrong answer that looks like a
    # right one.  Ancestors therefore keep pointer-only semantics and fail closed
    # to the error banner (PD-BUG-148).
    reported: Set[str] = set()
    own = _own_child_registry(project_root if project_root is not None else effective_cwd, reported)
    if own is not None:
        return RegistryResolution(own, "workspace")

    discovered = _discover_registry_via_pointer(project_root, effective_cwd, reported)
    if discovered is not None:
        return RegistryResolution(discovered, "pointer")

    return RegistryResolution(
        None,
        "unresolved",
        # Read from inside an open panel (this string is the list-pane banner),
        # and every remedy it names takes effect only at startup: the
        # single-instance guard in control_panel.py returns before resolution
        # runs, so a second launch surfaces this window and discards them all.
        # The close-first clause is what makes the guidance actionable where it
        # is read (PD-BUG-148 CR-17); test_panel_settings.py pins it.
        error=(
            "Could not locate a project registry. Close the panel first — a "
            "second launch only surfaces this window and re-resolves nothing "
            "— then relaunch, providing a registry with --registry, the "
            f"{REGISTRY_ENV_VAR} environment variable, or the "
            f"'project_registry' key in {PANEL_CONFIG_FILENAME}; or naming the "
            "workspace with --project-root — or launching from its root "
            "directory — so the registry it owns, or the one its parent owns, "
            "can be found."
        ),
    )
