"""
Document Metadata:
ID: TE-TST-150
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-10
Updated: 2026-08-10
Component Name: config_edit
Feature Id: 7.1.1
Language: Python
Test Name: panel_config_edit
Test Type: Unit

Unit tests for the Control Panel config editor pipeline
(``linkwatcher.linkwatcher_control_panel.config_edit``):

- UNIT-C1 — missing/unreadable config → read-error state; the file is never
  auto-written (EC-10)
- UNIT-C2 — invalid YAML → save blocked with a line-numbered reason; the file
  on disk is untouched (EC-11)
- UNIT-C3 — parses as YAML but fails ``LinkWatcherConfig.validate()`` (the
  **real** validator, never mocked — D-T6) → save blocked, file untouched
- UNIT-C4 — valid content → temp file in the same directory + ``os.replace``;
  the result is byte-identical to the submitted text, no temp residue
- UNIT-C5 — failure injected between temp-write and replace → the original
  file is intact, no truncation
- UNIT-C6 — "Create default config" writes a commented skeleton that
  round-trips through ``LinkWatcherConfig.from_file()``; never overwrites
"""

from pathlib import Path

import pytest

from linkwatcher.config import LinkWatcherConfig
from linkwatcher.linkwatcher_control_panel.config_edit import (
    DEFAULT_CONFIG_SKELETON,
    create_default_config,
    read_config,
    save_config,
)

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]

VALID_TEXT = "max_file_size_mb: 20\nmove_detect_delay: 12.5\n"


@pytest.fixture
def config_path(tmp_path):
    directory = tmp_path / "tools" / "linkwatcher"
    directory.mkdir(parents=True)
    return directory / "linkwatcher-config.yaml"


def no_temp_residue(config_path: Path) -> bool:
    return not list(config_path.parent.glob(".lw-config-save-*"))


# --------------------------------------------------------------------------- #
# UNIT-C1 — read-error states (EC-10)
# --------------------------------------------------------------------------- #
def test_missing_config_reports_missing_and_never_writes(config_path):
    result = read_config(config_path)

    assert result.status == "missing"
    assert str(config_path) in result.error
    assert not config_path.exists()  # reading never creates the file


def test_unreadable_config_reports_error(config_path, monkeypatch):
    config_path.write_text(VALID_TEXT, encoding="utf-8")
    monkeypatch.setattr(
        Path, "read_text", lambda self, **kwargs: (_ for _ in ()).throw(OSError("locked"))
    )

    result = read_config(config_path)

    assert result.status == "error"
    assert "locked" in result.error


def test_readable_config_returns_its_text(config_path):
    config_path.write_text(VALID_TEXT, encoding="utf-8")
    result = read_config(config_path)
    assert result.status == "ok" and result.text == VALID_TEXT


# --------------------------------------------------------------------------- #
# UNIT-C2 — invalid YAML blocked with line numbers (EC-11)
# --------------------------------------------------------------------------- #
def test_invalid_yaml_blocked_with_line_number(config_path):
    config_path.write_text(VALID_TEXT, encoding="utf-8")

    result = save_config(config_path, "max_file_size_mb: 10\nbroken: [unclosed\n")

    assert not result.ok
    assert "Line" in result.error
    assert config_path.read_text(encoding="utf-8") == VALID_TEXT  # untouched
    assert no_temp_residue(config_path)


def test_non_mapping_top_level_blocked(config_path):
    config_path.write_text(VALID_TEXT, encoding="utf-8")

    result = save_config(config_path, "- a\n- b\n")

    assert not result.ok
    assert "mapping" in result.error
    assert config_path.read_text(encoding="utf-8") == VALID_TEXT


# --------------------------------------------------------------------------- #
# UNIT-C3 — invalid values blocked by the real validator (D-T6)
# --------------------------------------------------------------------------- #
def test_invalid_values_blocked_by_real_validator(config_path):
    config_path.write_text(VALID_TEXT, encoding="utf-8")

    result = save_config(config_path, "max_file_size_mb: -1\n")

    assert not result.ok
    assert "max_file_size_mb" in result.error
    assert config_path.read_text(encoding="utf-8") == VALID_TEXT
    assert no_temp_residue(config_path)


def test_multiple_validation_issues_all_reported(config_path):
    result = save_config(config_path, "max_file_size_mb: 0\nmove_detect_delay: -5\n")

    assert not result.ok
    assert "max_file_size_mb" in result.error and "move_detect_delay" in result.error
    assert not config_path.exists()


# --------------------------------------------------------------------------- #
# UNIT-C4 — atomic save
# --------------------------------------------------------------------------- #
def test_valid_save_is_byte_identical(config_path):
    result = save_config(config_path, VALID_TEXT)

    assert result.ok and result.error is None
    assert config_path.read_text(encoding="utf-8") == VALID_TEXT
    assert no_temp_residue(config_path)


def test_save_overwrites_existing_content_atomically(config_path):
    config_path.write_text("max_file_size_mb: 5\n", encoding="utf-8")

    result = save_config(config_path, VALID_TEXT)

    assert result.ok
    assert config_path.read_text(encoding="utf-8") == VALID_TEXT


def test_empty_or_comments_only_config_is_valid(config_path):
    """An empty config means built-in defaults, per the documented contract."""
    result = save_config(config_path, "# defaults only\n")
    assert result.ok
    assert config_path.read_text(encoding="utf-8") == "# defaults only\n"


# --------------------------------------------------------------------------- #
# UNIT-C5 — interrupted save leaves the original intact
# --------------------------------------------------------------------------- #
def test_interrupted_save_leaves_original_intact(config_path):
    config_path.write_text(VALID_TEXT, encoding="utf-8")

    def failing_replace(src, dst):
        raise OSError("power loss between temp-write and replace")

    result = save_config(config_path, "max_file_size_mb: 99\n", replace=failing_replace)

    assert not result.ok
    assert "power loss" in result.error
    assert config_path.read_text(encoding="utf-8") == VALID_TEXT  # no truncation
    assert no_temp_residue(config_path)  # temp cleaned up


# --------------------------------------------------------------------------- #
# UNIT-C6 — default skeleton
# --------------------------------------------------------------------------- #
def test_default_skeleton_round_trips_through_the_real_loader(config_path):
    result = create_default_config(config_path)

    assert result.ok
    assert config_path.is_file()
    config = LinkWatcherConfig.from_file(str(config_path))  # must not raise
    assert config.validate() == []
    # It is a commented skeleton, not a bare mapping.
    assert config_path.read_text(encoding="utf-8").startswith("#")


def test_create_default_never_overwrites(config_path):
    config_path.write_text(VALID_TEXT, encoding="utf-8")

    result = create_default_config(config_path)

    assert not result.ok
    assert "not overwriting" in result.error
    assert config_path.read_text(encoding="utf-8") == VALID_TEXT


def test_create_default_makes_parent_directories(tmp_path):
    deep = tmp_path / "brand" / "new" / "tools" / "linkwatcher" / "linkwatcher-config.yaml"

    result = create_default_config(deep)

    assert result.ok and deep.is_file()


def test_skeleton_content_is_the_module_constant(config_path):
    create_default_config(config_path)
    assert config_path.read_text(encoding="utf-8") == DEFAULT_CONFIG_SKELETON
