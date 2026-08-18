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
- project-registry resolution order — CLI > env > config-key >
  ``.framework-central-pointer`` discovery > unresolved (UNIT-S4…S5).
  The pointer-discovery tier is the checkpoint-approved addition to the TDD's
  three-source chain (recorded as a design decision in the feature state file).
"""

import math
from pathlib import Path

import pytest

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
