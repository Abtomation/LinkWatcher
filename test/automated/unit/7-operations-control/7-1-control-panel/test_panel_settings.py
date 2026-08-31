"""
Document Metadata:
ID: TE-TST-141
Type: Test File
Category: Test
Version: 1.0
Created: 2026-07-15
Updated: 2026-07-15
Component Name: settings
Feature Id: 7.1.1
Language: Python
Test Name: panel_settings
Test Type: Unit

Unit tests for the Control Panel settings module
(``linkwatcher.linkwatcher_control_panel.settings``):

- panel-config.yaml loading — defaults, partial override, invalid values
  (UNIT-S1…S3, TDD §4.1)
- project-registry resolution order — CLI > env > config-key > the child
  registry the workspace root owns > parent-pointer discovery > unresolved
  (UNIT-S4…S5).  The two auto-locate tiers are the checkpoint-approved additions
  to the TDD's three-source chain (recorded as design decisions in the feature
  state file).
"""

import logging
import math
import re
from contextlib import contextmanager
from pathlib import Path
from typing import List, Optional

import pytest

from linkwatcher.linkwatcher_control_panel.panel_log import PANEL_LOGGER_NAME
from linkwatcher.linkwatcher_control_panel.settings import (
    REGISTRY_ENV_VAR,
    PanelSettings,
    load_panel_settings,
    resolve_registry_path,
)

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def _write_config(dir_path: Path, text: str) -> None:
    (Path(dir_path) / "panel-config.yaml").write_text(text, encoding="utf-8")


def _make_pointer(project_root: Path, central_dir: Path) -> Path:
    """Build a registered-project pointer chain in temp dirs.

    Writes ``<project_root>/process-framework/.framework-central-pointer`` ->
    *central_dir* and the registry file under *central_dir*.  Returns the
    registry path the resolver is expected to discover.
    """
    pf = Path(project_root) / "process-framework"
    pf.mkdir(parents=True, exist_ok=True)
    (pf / ".framework-central-pointer").write_text(str(central_dir), encoding="utf-8")
    registry = Path(central_dir) / "process-framework-central" / "project-registry.json"
    registry.parent.mkdir(parents=True, exist_ok=True)
    registry.write_text('{"projects": {}}', encoding="utf-8")
    return registry


# --------------------------------------------------------------------------- #
# UNIT-S1 — Defaults
# --------------------------------------------------------------------------- #
def test_defaults_when_config_missing(tmp_path):
    """UNIT-S1: no panel-config.yaml → grace 20 s, log-idle 3 s, poll 2.5 s."""
    result = load_panel_settings(tmp_path)

    assert result.settings == PanelSettings(
        grace_period_seconds=20.0,
        log_idle_threshold_seconds=3.0,
        poll_interval_seconds=2.5,
        project_registry=None,
    )
    assert result.warnings == []


# --------------------------------------------------------------------------- #
# UNIT-S2 — Partial override
# --------------------------------------------------------------------------- #
def test_partial_override_keeps_other_defaults(tmp_path):
    """UNIT-S2: a file with only grace_period_seconds overrides that key alone."""
    _write_config(tmp_path, "grace_period_seconds: 45\n")

    result = load_panel_settings(tmp_path)

    assert result.settings.grace_period_seconds == 45.0
    assert result.settings.log_idle_threshold_seconds == 3.0
    assert result.settings.poll_interval_seconds == 2.5
    assert result.warnings == []


# --------------------------------------------------------------------------- #
# UNIT-S3 — Invalid values
# --------------------------------------------------------------------------- #
def test_invalid_values_default_with_warning(tmp_path):
    """UNIT-S3: non-numeric and negative values → defaults + surfaced warnings."""
    _write_config(
        tmp_path,
        "grace_period_seconds: not-a-number\npoll_interval_seconds: -5\n",
    )

    result = load_panel_settings(tmp_path)

    # Bad values fall back to defaults — never a crash.
    assert result.settings.grace_period_seconds == 20.0
    assert result.settings.poll_interval_seconds == 2.5
    # Each rejected key is named in a warning so the operator learns it was ignored.
    assert any("grace_period_seconds" in w for w in result.warnings)
    assert any("poll_interval_seconds" in w for w in result.warnings)


def test_zero_is_rejected_as_non_positive(tmp_path):
    """UNIT-S3 (boundary): 0 is not a valid positive interval → default + warning."""
    _write_config(tmp_path, "log_idle_threshold_seconds: 0\n")

    result = load_panel_settings(tmp_path)

    assert result.settings.log_idle_threshold_seconds == 3.0
    assert any("log_idle_threshold_seconds" in w for w in result.warnings)


def test_malformed_yaml_does_not_crash(tmp_path):
    """UNIT-S3 (robustness): unparseable YAML → all defaults + a warning, no raise."""
    _write_config(tmp_path, "grace_period_seconds: [unclosed\n")

    result = load_panel_settings(tmp_path)

    assert result.settings == PanelSettings()
    assert result.warnings


# --------------------------------------------------------------------------- #
# UNIT-S4 — Registry resolution order
# --------------------------------------------------------------------------- #
def test_registry_cli_beats_env_and_config(tmp_path):
    """UNIT-S4: an explicit --registry wins over env var and config key."""
    settings = PanelSettings(project_registry="C:/cfg/registry.json")

    res = resolve_registry_path(
        "C:/cli/registry.json",
        settings=settings,
        env={REGISTRY_ENV_VAR: "C:/env/registry.json"},
        cwd=tmp_path,
        project_root=None,
    )

    assert res.source == "cli"
    assert res.path == Path("C:/cli/registry.json")


def test_registry_env_beats_config(tmp_path):
    """UNIT-S4: the env var wins over the config key when no CLI arg is given."""
    settings = PanelSettings(project_registry="C:/cfg/registry.json")

    res = resolve_registry_path(
        None,
        settings=settings,
        env={REGISTRY_ENV_VAR: "C:/env/registry.json"},
        cwd=tmp_path,
        project_root=None,
    )

    assert res.source == "env"
    assert res.path == Path("C:/env/registry.json")


def test_registry_config_used_when_no_cli_or_env(tmp_path):
    """UNIT-S4: the config key is used when neither CLI arg nor env var is set."""
    settings = PanelSettings(project_registry="C:/cfg/registry.json")

    res = resolve_registry_path(None, settings=settings, env={}, cwd=tmp_path, project_root=None)

    assert res.source == "config"
    assert res.path == Path("C:/cfg/registry.json")


def test_registry_pointer_discovery_via_project_root(tmp_path):
    """UNIT-S4 (pointer tier): an explicit --project-root resolves via its pointer.

    Also establishes the resolved/empty distinction: a present-but-empty
    registry resolves successfully (source=pointer), unlike the unresolved case.
    """
    project = tmp_path / "proj"
    central = tmp_path / "central"
    registry = _make_pointer(project, central)

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=project, cwd=tmp_path
    )

    assert res.source == "pointer"
    assert res.path == registry
    assert res.resolved


def test_registry_pointer_discovery_via_cwd_walkup(tmp_path):
    """UNIT-S4 (pointer tier): launched from inside a project, cwd walk-up finds it."""
    project = tmp_path / "proj"
    central = tmp_path / "central"
    registry = _make_pointer(project, central)
    nested = project / "src" / "linkwatcher"
    nested.mkdir(parents=True)

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=None, cwd=nested
    )

    assert res.source == "pointer"
    assert res.path == registry


def test_registry_config_beats_pointer(tmp_path):
    """UNIT-S4: an explicit config key still outranks pointer discovery."""
    project = tmp_path / "proj"
    central = tmp_path / "central"
    _make_pointer(project, central)
    settings = PanelSettings(project_registry="C:/cfg/registry.json")

    res = resolve_registry_path(None, settings=settings, env={}, project_root=project, cwd=tmp_path)

    assert res.source == "config"
    assert res.path == Path("C:/cfg/registry.json")


def test_pointer_ignored_when_registry_file_absent(tmp_path):
    """UNIT-S4/S5: a pointer whose central has no registry file → falls through.

    Best-effort discovery must not claim a phantom path; with nothing else
    configured the outcome is the unresolved error state.
    """
    project = tmp_path / "proj"
    pf = project / "process-framework"
    pf.mkdir(parents=True)
    # Pointer exists but the central registry file does not.
    (pf / ".framework-central-pointer").write_text(str(tmp_path / "nowhere"), encoding="utf-8")

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=project, cwd=tmp_path
    )

    assert res.source == "unresolved"
    assert res.path is None


# --------------------------------------------------------------------------- #
# UNIT-S5 — Unresolved registry
# --------------------------------------------------------------------------- #
def test_registry_unresolved_when_no_source(tmp_path):
    """UNIT-S5: no configured source and no reachable pointer → error state.

    Distinct from the empty-registry EC-8 state (a resolved file with zero
    projects) — here nothing resolves at all, so operator guidance is surfaced.
    """
    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=None, cwd=tmp_path
    )

    assert not res.resolved
    assert res.path is None
    assert res.source == "unresolved"
    assert res.error  # operator guidance present


# --------------------------------------------------------------------------- #
# CR-10 / CR-11 — values and encodings that escaped the "never raises" contract
# (Code Review 2026-08-17). UNIT-S3 above covers non-numeric, negative and zero
# values plus malformed YAML, but never a non-finite number or a non-UTF-8 file:
# `.inf`/`.nan` are `float` instances that also fail `value <= 0`, so they passed
# every gate and reached the discovery thread, where `Event.wait(inf)` raises
# OverflowError outside the caller's try and kills the poll loop silently.
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize(
    "key, body, default",
    [
        ("poll_interval_seconds", "poll_interval_seconds: .inf\n", 2.5),
        ("poll_interval_seconds", "poll_interval_seconds: .nan\n", 2.5),
        ("grace_period_seconds", "grace_period_seconds: -.inf\n", 20.0),
        ("log_idle_threshold_seconds", "log_idle_threshold_seconds: .inf\n", 3.0),
    ],
)
def test_non_finite_values_default_with_warning(tmp_path, key, body, default):
    """CR-10: `.inf`/`.nan` are rejected like any other invalid value.

    Discriminating condition: without the finiteness check the value passes
    through (it is a float, and neither `inf` nor `nan` satisfies `<= 0`), so the
    setting comes back as inf/nan instead of the default and no warning is
    recorded.
    """
    _write_config(tmp_path, body)

    result = load_panel_settings(tmp_path)

    assert math.isfinite(getattr(result.settings, key))
    assert getattr(result.settings, key) == default
    assert any(key in w for w in result.warnings)


def test_out_of_range_integer_defaults_with_warning(tmp_path):
    """CR-10: an integer too large to convert to float cannot escape as OverflowError.

    Discriminating condition: `float(10**400)` raises, so without the guarded
    conversion this call propagates OverflowError instead of returning settings.
    """
    _write_config(tmp_path, f"poll_interval_seconds: {'1' * 400}\n")

    result = load_panel_settings(tmp_path)

    assert result.settings.poll_interval_seconds == 2.5
    assert any("poll_interval_seconds" in w for w in result.warnings)


def test_non_utf8_panel_config_defaults_with_warning(tmp_path):
    """CR-11: a non-UTF-8 panel config yields defaults, not an aborted startup.

    `read_text` raises UnicodeDecodeError (a ValueError, not an OSError), which
    used to escape `load_panel_settings` before any window existed — the panel
    simply never opened and logged nothing. Discriminating condition: narrow the
    handler back to OSError and this call raises.
    """
    (tmp_path / "panel-config.yaml").write_bytes(b"poll_interval_seconds: 3.0\n# caf\xe9\n")

    result = load_panel_settings(tmp_path)

    assert result.settings.poll_interval_seconds == 2.5  # the file was not applied
    assert any("not valid UTF-8" in w for w in result.warnings)


def test_valid_values_survive_the_new_guards(tmp_path):
    """CR-10 guard rails must not reject legitimate values.

    Discriminating condition: a finiteness/range check written too broadly (e.g.
    rejecting ints, or comparing before conversion) would default these and emit
    warnings.
    """
    _write_config(
        tmp_path,
        "poll_interval_seconds: 3.5\ngrace_period_seconds: 30\nlog_idle_threshold_seconds: 1\n",
    )

    result = load_panel_settings(tmp_path)

    assert result.settings.poll_interval_seconds == 3.5
    assert result.settings.grace_period_seconds == 30.0
    assert result.settings.log_idle_threshold_seconds == 1.0
    assert result.warnings == []


# --------------------------------------------------------------------------- #
# PD-BUG-148 — workspace-owned child-registry tier
#
# The panel resolved the registry by following a project's parent-pointer and
# joining a hardcoded ``process-framework-central/project-registry.json``.  That
# is correct only for a LEAF workspace, whose supervisor list genuinely lives in
# its parent.  At a non-leaf workspace the pointer names the PARENT, so the join
# yields the parent's central - which need not exist, and whose registry need not
# be a project registry.  Measured before the fix: FrameworkBuilder, appdev and
# legal all resolved to nothing; only a leaf project resolved.
#
# The fix looks for a child registry the workspace OWNS, taking that root exactly
# and never walking up (see the walk-up guard test below).
# --------------------------------------------------------------------------- #
def _make_own_registry(root: Path, filename: str, body: Optional[str] = None) -> Path:
    """Give *root* its own child registry under ``process-framework-central/``."""
    registry = Path(root) / "process-framework-central" / filename
    registry.parent.mkdir(parents=True, exist_ok=True)
    default = '{"frameworks": {}}' if filename.startswith("framework") else '{"projects": {}}'
    registry.write_text(body if body is not None else default, encoding="utf-8")
    return registry


def test_own_framework_registry_resolved_at_framework_builder(tmp_path):
    """PD-BUG-148: a framework-builder workspace resolves its OWN registry.

    Its face is not at ``process-framework/`` and it has no parent to borrow
    from, so the pre-fix pointer tier found nothing at all.
    """
    root = tmp_path / "FrameworkBuilder"
    registry = _make_own_registry(root, "framework-registry.json")

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=root, cwd=tmp_path
    )

    assert res.resolved
    assert res.path == registry
    assert res.source == "workspace"


def test_own_project_registry_resolved_at_framework_role(tmp_path):
    """PD-BUG-148: a framework workspace resolves its OWN registry, not its parent's.

    Its pointer names the parent, whose central holds no project registry — the
    mechanism that left appdev and legal unresolved before the fix.
    """
    parent = tmp_path / "parent"
    root = tmp_path / "framework"
    own = _make_own_registry(root, "project-registry.json")
    pf = root / "process-framework"
    pf.mkdir(parents=True, exist_ok=True)
    (pf / ".framework-parent-pointer").write_text(str(parent), encoding="utf-8")

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=root, cwd=tmp_path
    )

    assert res.resolved
    assert res.path == own, "must prefer the workspace's own registry over the parent hop"
    assert res.source == "workspace"


def test_leaf_project_still_resolves_via_parent_pointer(tmp_path):
    """PD-BUG-148 regression guard: the one path that worked must be unchanged.

    A leaf owns no child registry, so the parent hop remains its resolution.
    """
    project = tmp_path / "proj"
    central = tmp_path / "central"
    registry = _make_pointer(project, central)

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=project, cwd=tmp_path
    )

    assert res.path == registry
    assert res.source == "pointer"


def test_cwd_walkup_does_not_claim_an_ancestors_own_registry(tmp_path):
    """PD-BUG-148: the walk-up must not adopt a registry it merely walked past.

    A producer's blueprint/template tree carries a SEED registry with zero rows.
    Resolving to it renders the calm "no registered projects" empty state — a
    wrong answer that looks like a valid one.  Own-registry lookup therefore
    takes its root exactly and never walks up; with no pointer to follow either,
    the walk-up falls through to the error state.
    """
    seed_holder = tmp_path / "blueprint"
    _make_own_registry(seed_holder, "project-registry.json")
    nested = seed_holder / "process-framework" / "guides"
    nested.mkdir(parents=True)

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=None, cwd=nested
    )

    assert res.source == "unresolved", "walk-up must not resolve to an ancestor's own registry"
    assert res.path is None


def test_walkup_past_a_seed_registry_prefers_the_pointer(tmp_path):
    """PD-BUG-148: the real blueprint shape — a seed registry AND a pointer.

    A producer's template tree carries both: its own zero-row seed registry and
    a pointer naming the producer.  The walk-up must follow the pointer to the
    producer's real registry and never adopt the seed, whose empty state would
    read as "nothing is running" (measured: this is the FrameworkBuilder
    ``blueprint/`` shape).
    """
    producer = tmp_path / "Producer"
    real = _make_own_registry(
        producer,
        "framework-registry.json",
        '{"frameworks": {"FWK-X": {"name": "x", "path": "C:/x"}}}',
    )
    blueprint = producer / "blueprint"
    _make_own_registry(blueprint, "project-registry.json", '{"projects": {}}')  # zero-row seed
    pf = blueprint / "process-framework"
    pf.mkdir(parents=True, exist_ok=True)
    (pf / ".framework-central-pointer").write_text(str(producer), encoding="utf-8")
    nested = pf / "guides"
    nested.mkdir(parents=True, exist_ok=True)

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=None, cwd=nested
    )

    assert res.path == real, "must follow the pointer to the real registry, not adopt the seed"
    assert res.source == "pointer"


def test_new_parent_pointer_filename_is_honored(tmp_path):
    """PD-BUG-148: the canonical pointer name is honored, not only the legacy one."""
    project = tmp_path / "proj"
    central = tmp_path / "central"
    pf = project / "process-framework"
    pf.mkdir(parents=True)
    (pf / ".framework-parent-pointer").write_text(str(central), encoding="utf-8")
    registry = central / "process-framework-central" / "project-registry.json"
    registry.parent.mkdir(parents=True, exist_ok=True)
    registry.write_text('{"projects": {}}', encoding="utf-8")

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=project, cwd=tmp_path
    )

    assert res.resolved
    assert res.path == registry


def test_explicit_config_key_still_outranks_workspace_discovery(tmp_path):
    """PD-BUG-148: the three explicit tiers keep precedence over the new tier."""
    root = tmp_path / "FrameworkBuilder"
    _make_own_registry(root, "framework-registry.json")
    settings = PanelSettings(project_registry="C:/cfg/registry.json")

    res = resolve_registry_path(None, settings=settings, env={}, project_root=root, cwd=tmp_path)

    assert res.source == "config"
    assert res.path == Path("C:/cfg/registry.json")


# --------------------------------------------------------------------------- #
# PD-BUG-148 CR-1 — the current directory as an IMPLIED workspace root
#
# The workspace tier above originally answered only for an explicit
# --project-root, but the panel launchers (``linkwatcher-panel.bat`` / ``.ps1``)
# forward their arguments and add none, so every manual launch fell through to
# the parent hop.  Measured
# at appdev before this change: --project-root yielded its own 4 projects, a
# launch from that same directory yielded the parent's 3 frameworks, and nothing
# in the UI told the two apart.
#
# The cwd is therefore treated as an implied root — the directory the operator is
# standing in, checked EXACTLY, never walked up (the walk-up guard above is what
# keeps a producer's zero-row seed registry out of reach).
# --------------------------------------------------------------------------- #
def test_own_registry_resolved_from_cwd_without_an_explicit_project_root(tmp_path):
    """PD-BUG-148 CR-1: launching inside a non-leaf workspace supervises its own list.

    This is the launcher's path: no ``--project-root`` reaches the panel, so
    before this change the workspace tier was unreachable and the parent hop
    answered with the wrong registry.
    """
    root = tmp_path / "framework"
    parent = tmp_path / "parent"
    own = _make_own_registry(root, "project-registry.json")
    # A parent hop that would answer differently — the pre-fix behaviour.
    _make_pointer(root, parent)

    res = resolve_registry_path(None, settings=PanelSettings(), env={}, project_root=None, cwd=root)

    assert res.resolved
    assert res.path == own, "the workspace the operator is standing in owns the answer"
    assert res.source == "workspace"


def test_implied_root_is_the_cwd_itself_and_is_never_walked_up(tmp_path):
    """PD-BUG-148 CR-1: the implied root must not reach an ancestor's registry.

    Standing one directory *below* a registry-owning workspace is not standing in
    it.  Allowing the implied root to walk up would re-open the seed-registry
    hazard the explicit-root confinement was built to close.
    """
    holder = tmp_path / "blueprint"
    _make_own_registry(holder, "project-registry.json")
    nested = holder / "doc"
    nested.mkdir(parents=True)

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=None, cwd=nested
    )

    assert res.source == "unresolved", "an ancestor's own registry is out of reach"
    assert res.path is None


def test_explicit_project_root_is_not_overridden_by_the_cwd(tmp_path):
    """PD-BUG-148 CR-1: an explicit ``--project-root`` states intent and wins.

    A leaf named explicitly resolves through its parent hop even when the process
    happens to be sitting in a registry-owning workspace.
    """
    leaf = tmp_path / "leaf"
    central = tmp_path / "central"
    expected = _make_pointer(leaf, central)
    elsewhere = tmp_path / "framework"
    decoy = _make_own_registry(elsewhere, "project-registry.json")

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=leaf, cwd=elsewhere
    )

    assert res.path == expected
    assert res.path != decoy, "the cwd must not override an explicit --project-root"
    assert res.source == "pointer"


def test_declared_face_is_read_when_following_the_parent_pointer(tmp_path):
    """PD-BUG-148 CR-4: the declared face is load-bearing for registry resolution.

    A self-hosted producer keeps its face under ``blueprint/`` and has no
    ``process-framework/`` at all, so the pointer is reachable only by reading
    ``paths.process_framework``.  Face handling was otherwise pinned only through
    ``launcher_path``, leaving the resolution path that depends on it uncovered.
    """
    root = tmp_path / "producer"
    central = tmp_path / "central"
    face = root / "blueprint" / "process-framework"
    face.mkdir(parents=True)
    (face / ".framework-parent-pointer").write_text(str(central), encoding="utf-8")
    registry = central / "process-framework-central" / "project-registry.json"
    registry.parent.mkdir(parents=True, exist_ok=True)
    registry.write_text('{"projects": {}}', encoding="utf-8")
    config = root / "doc" / "project-config.json"
    config.parent.mkdir(parents=True, exist_ok=True)
    config.write_text(
        '{"paths": {"process_framework": "blueprint/process-framework"}}', encoding="utf-8"
    )

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=root, cwd=tmp_path
    )

    assert res.resolved, "the pointer is unreachable unless the declared face is read"
    assert res.path == registry
    assert res.source == "pointer"


# --------------------------------------------------------------------------- #
# Resilience of the two hardcoded enumerations (PD-BUG-148 round 3)
# --------------------------------------------------------------------------- #
class _RecordingHandler(logging.Handler):
    """Collect formatted messages from a named logger for assertions."""

    def __init__(self) -> None:
        super().__init__()
        self.messages: List[str] = []

    def emit(self, record: logging.LogRecord) -> None:
        self.messages.append(record.getMessage())


@contextmanager
def _capture_panel_log():
    """Yield a handler recording everything the panel logger emits.

    The panel logger sets ``propagate = False`` once ``setup_panel_log`` has run,
    so records cannot be captured reliably at the root logger — attach directly,
    and restore the prior level so nothing leaks into later tests.
    """
    logger = logging.getLogger(PANEL_LOGGER_NAME)
    handler = _RecordingHandler()
    previous_level = logger.level
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)
    try:
        yield handler
    finally:
        logger.removeHandler(handler)
        logger.setLevel(previous_level)


def test_unrecognized_registry_in_central_directory_is_logged(tmp_path):
    """PD-BUG-148 round 3: a role divergence must not fail silently.

    ``_own_child_registry`` recognizes exactly two filenames.  A workspace whose
    central directory holds some *other* registry falls through to the parent hop
    and the panel then shows the PARENT's list under a perfectly normal
    ``registry resolved via pointer:`` line — the same invisible wrong-answer
    shape as CR-1.  The fall-through is correct; being silent about it is not.
    """
    root = tmp_path / "workspace"
    central = root / "process-framework-central"
    central.mkdir(parents=True)
    (central / "legal-registry.json").write_text('{"matters": {}}', encoding="utf-8")

    with _capture_panel_log() as handler:
        res = resolve_registry_path(
            None, settings=PanelSettings(), env={}, project_root=root, cwd=tmp_path
        )

    assert not res.resolved, "an unrecognized registry must not be adopted"
    logged = "\n".join(handler.messages)
    assert str(central) in logged, "the diagnostic must name the directory it examined"
    assert (
        "project-registry.json" in logged and "framework-registry.json" in logged
    ), "the diagnostic must name what it looked for, so the divergence is actionable"


def test_no_diagnostic_when_the_workspace_simply_owns_no_central_directory(tmp_path):
    """The leaf case is normal, not an anomaly — it must stay silent.

    Guard against the diagnostic above degrading into noise: every leaf project
    reaches ``_own_child_registry`` and finds no central directory at all.
    """
    leaf = tmp_path / "leaf"
    central = tmp_path / "central"
    expected = _make_pointer(leaf, central)

    with _capture_panel_log() as handler:
        res = resolve_registry_path(
            None, settings=PanelSettings(), env={}, project_root=leaf, cwd=tmp_path
        )

    assert res.path == expected
    assert handler.messages == [], "a leaf owning no central directory is the normal path"


def test_non_utf8_parent_pointer_does_not_abort_resolution(tmp_path):
    """PD-BUG-148 round 3: a non-UTF-8 pointer must degrade, not crash.

    ``read_text(encoding="utf-8")`` raises ``UnicodeDecodeError`` — a
    ``ValueError``, not an ``OSError`` — so it escaped the guard here and
    propagated out of resolution, aborting startup before any window existed.
    That is the exact class ``load_panel_settings`` already guards (CR-11).
    """
    root = tmp_path / "leaf"
    face = root / "process-framework"
    face.mkdir(parents=True)
    (face / ".framework-parent-pointer").write_bytes(b"\xff\xfe not utf-8")

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=root, cwd=tmp_path
    )

    assert not res.resolved
    assert res.source == "unresolved"


def test_unreadable_pointer_falls_through_to_the_legacy_filename(tmp_path):
    """A rejected canonical pointer must not shadow a usable legacy one.

    Pins that the guard ``continue``s to the next filename rather than
    abandoning the tier, so a workspace mid-migration still resolves.
    """
    root = tmp_path / "leaf"
    central = tmp_path / "central"
    face = root / "process-framework"
    face.mkdir(parents=True)
    (face / ".framework-parent-pointer").write_bytes(b"\xff\xfe not utf-8")
    (face / ".framework-central-pointer").write_text(str(central), encoding="utf-8")
    registry = central / "process-framework-central" / "project-registry.json"
    registry.parent.mkdir(parents=True, exist_ok=True)
    registry.write_text('{"projects": {}}', encoding="utf-8")

    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=root, cwd=tmp_path
    )

    assert res.resolved, "the legacy pointer must still answer"
    assert res.path == registry
    assert res.source == "pointer"


def test_unrecognized_central_is_reported_once_per_directory(tmp_path):
    """PD-BUG-148 round 4: a directory examined twice is not two findings.

    A self-hosted producer's parent-pointer names itself, so the same central
    directory is examined at the own-registry tier and again through the parent
    hop.  Emitting the diagnostic twice invites the reader who counts
    occurrences — the reason to log it at all — to infer two divergent
    workspaces where there is one.
    """
    root = tmp_path / "selfhost"
    central = root / "process-framework-central"
    central.mkdir(parents=True)
    (central / "legal-registry.json").write_text('{"matters": {}}', encoding="utf-8")
    face = root / "process-framework"
    face.mkdir(parents=True)
    (face / ".framework-parent-pointer").write_text(str(root), encoding="utf-8")

    with _capture_panel_log() as handler:
        res = resolve_registry_path(
            None, settings=PanelSettings(), env={}, project_root=root, cwd=tmp_path
        )

    assert not res.resolved
    hits = [m for m in handler.messages if "central_registry_unrecognized" in m]
    assert len(hits) == 1, f"one diagnostic per directory, got {len(hits)}: {hits}"


def test_distinct_unrecognized_centrals_are_each_reported(tmp_path):
    """The de-duplication is per directory, not a one-shot latch.

    Guards the fix above from silencing a genuinely different second workspace:
    a leaf whose own central is unrecognized *and* whose parent's central is too
    must produce both findings.
    """
    parent = tmp_path / "parent"
    parent_central = parent / "process-framework-central"
    parent_central.mkdir(parents=True)
    (parent_central / "legal-registry.json").write_text('{"matters": {}}', encoding="utf-8")

    child = tmp_path / "child"
    child_central = child / "process-framework-central"
    child_central.mkdir(parents=True)
    (child_central / "other-registry.json").write_text('{"things": {}}', encoding="utf-8")
    face = child / "process-framework"
    face.mkdir(parents=True)
    (face / ".framework-parent-pointer").write_text(str(parent), encoding="utf-8")

    with _capture_panel_log() as handler:
        res = resolve_registry_path(
            None, settings=PanelSettings(), env={}, project_root=child, cwd=tmp_path
        )

    assert not res.resolved
    hits = [m for m in handler.messages if "central_registry_unrecognized" in m]
    assert len(hits) == 2, f"two distinct directories are two findings, got {len(hits)}: {hits}"


# --------------------------------------------------------------------------- #
# CR-17 — the unresolved-error string is read from inside an open panel, so
# every remedy it names must be reachable from there.  Pinned as an assertion
# rather than a prose sweep: three review rounds re-broke this same invariant
# in handbook text, each sweep fixing the site the last finding named instead
# of the rule behind it.  A test fails loudly where a sweep structurally cannot.
# --------------------------------------------------------------------------- #
def test_unresolved_error_tells_the_operator_to_close_the_panel_first(tmp_path):
    """The error string must name closing the panel before relaunching.

    This string is rendered as the list-pane banner of an *open* panel
    (``app.py`` → ``main_window.py``), and ``control_panel.py`` returns from the
    single-instance guard **before** :func:`resolve_registry_path` runs.  A
    second launch therefore surfaces the window already on screen and
    re-resolves nothing: ``--registry``, the environment variable, the
    ``panel-config.yaml`` key, ``--project-root`` and launching from the root
    are all discarded.  Without a close-first clause every remedy the banner
    offers is inert exactly where it is read.
    """
    res = resolve_registry_path(
        None, settings=PanelSettings(), env={}, project_root=None, cwd=tmp_path
    )

    assert res.source == "unresolved"
    assert res.error
    assert re.search(r"close (?:the|this) panel", res.error, re.IGNORECASE), (
        "every remedy in this banner needs a second launch, which the "
        "single-instance guard discards — the string must say to close the "
        f"panel first. Got: {res.error!r}"
    )
