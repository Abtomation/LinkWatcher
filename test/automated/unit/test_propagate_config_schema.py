"""Unit tests for the release-time config-schema propagation diff logic.

Covers ``deployment/propagate_config_schema.py`` (PD-FRQ-006 / PF-PRO-039 Fork 1).
The cross-repo side effects (filing the IMP, syncing the appdev template) are not
exercised here — only the pure, top-level-field diff that decides whether to act.
The load-bearing case is that a *value-only* change inside a variable-key data-map
(e.g. ``path_resolution_overrides``) must NOT register as a schema change.
"""

import sys
from pathlib import Path

import pytest

# deployment/ is not a package on sys.path — add it so the module imports by name.
_DEPLOYMENT_DIR = Path(__file__).resolve().parents[3] / "deployment"
sys.path.insert(0, str(_DEPLOYMENT_DIR))

import propagate_config_schema as pcs  # noqa: E402

# --- field_names: the schema surface is top-level field names only ---


def test_field_names_flat_top_level():
    assert pcs.field_names({"a": 1, "b": "x"}) == {"a", "b"}


def test_field_names_ignores_map_values():
    # A data-map's variable keys are values, not schema — never surfaced.
    assert pcs.field_names({"path_resolution_overrides": {"blueprint": "blueprint"}}) == {
        "path_resolution_overrides"
    }


def test_field_names_ignores_list_values():
    assert pcs.field_names({"validation_extensions": [".md", ".yaml"]}) == {"validation_extensions"}


def test_field_names_non_dict_is_empty():
    assert pcs.field_names(None) == set()
    assert pcs.field_names([1, 2]) == set()


# --- compute_schema_diff: file-to-file, top-level keys only ---


def _write(tmp_path, name, text):
    p = tmp_path / name
    p.write_text(text, encoding="utf-8")
    return p


def test_diff_identical_templates_is_noop(tmp_path):
    wip = _write(tmp_path, "wip.yaml", "path_resolution_overrides: {}\n")
    appdev = _write(tmp_path, "appdev.yaml", "path_resolution_overrides: {}\n")
    diff = pcs.compute_schema_diff(wip, appdev)
    assert diff["changed"] is False
    assert diff["added"] == [] and diff["removed"] == []


def test_diff_value_only_change_in_data_map_is_noop(tmp_path):
    # THE key case (D2): WIP has a configured override value, appdev is empty — same
    # FIELD set, so this must NOT be flagged as a schema change.
    wip = _write(tmp_path, "wip.yaml", "path_resolution_overrides:\n  blueprint: blueprint\n")
    appdev = _write(tmp_path, "appdev.yaml", "path_resolution_overrides: {}\n")
    diff = pcs.compute_schema_diff(wip, appdev)
    assert diff["changed"] is False


def test_diff_added_field_is_flagged(tmp_path):
    wip = _write(
        tmp_path, "wip.yaml", "path_resolution_overrides: {}\nvalidation_extensions: [.md]\n"
    )
    appdev = _write(tmp_path, "appdev.yaml", "path_resolution_overrides: {}\n")
    diff = pcs.compute_schema_diff(wip, appdev)
    assert diff["changed"] is True
    assert diff["added"] == ["validation_extensions"]
    assert diff["removed"] == []


def test_diff_removed_field_is_flagged(tmp_path):
    wip = _write(tmp_path, "wip.yaml", "path_resolution_overrides: {}\n")
    appdev = _write(tmp_path, "appdev.yaml", "path_resolution_overrides: {}\nlegacy_key: true\n")
    diff = pcs.compute_schema_diff(wip, appdev)
    assert diff["changed"] is True
    assert diff["added"] == []
    assert diff["removed"] == ["legacy_key"]


def test_diff_ignores_nested_subkey_changes(tmp_path):
    # Documented limitation: only top-level FIELDS are compared. A sub-key added
    # inside an existing field's value is NOT flagged (no such nested fixed-key
    # field exists today; add a recurse-allowlist for that one field if it ever does).
    wip = _write(tmp_path, "wip.yaml", "opts:\n  a: 1\n  b: 2\n")
    appdev = _write(tmp_path, "appdev.yaml", "opts:\n  a: 1\n")
    diff = pcs.compute_schema_diff(wip, appdev)
    assert diff["changed"] is False


def test_diff_empty_file_treated_as_no_fields(tmp_path):
    wip = _write(tmp_path, "wip.yaml", "path_resolution_overrides: {}\n")
    appdev = _write(tmp_path, "appdev.yaml", "")  # None → {} → no fields
    diff = pcs.compute_schema_diff(wip, appdev)
    assert diff["added"] == ["path_resolution_overrides"]
    assert diff["changed"] is True


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))
