"""
Document Metadata:
    ID: TE-TST-132
    Type: Test File
    Category: Test
    Version: 1.0
    Created: 2026-04-29
    Updated: 2026-04-29
    Language: Python
    Component Name: main_logging_setup
    Feature Id: 3.1.1
    Test Name: main_logging_setup

Unit tests for main._apply_logging_config — the precedence helper that merges
CLI args and config values into a single setup_logging call (TD232/TD233).
"""

from argparse import Namespace
from unittest.mock import patch

import pytest

import main
from linkwatcher.config import DEFAULT_CONFIG
from linkwatcher.logging import LogLevel

pytestmark = [
    pytest.mark.feature("3.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
]


def _make_args(**overrides):
    """Build an argparse.Namespace with the same attributes main() relies on."""
    base = dict(debug=False, quiet=False, log_file=None, dry_run=False, no_initial_scan=False)
    base.update(overrides)
    return Namespace(**base)


def _make_config(**overrides):
    """Clone DEFAULT_CONFIG and apply overrides for the fields under test."""
    cfg = DEFAULT_CONFIG.merge(DEFAULT_CONFIG)  # shallow clone via merge
    for key, value in overrides.items():
        setattr(cfg, key, value)
    return cfg


class TestApplyLoggingConfigPrecedence:
    """Verify the CLI > config > defaults precedence rule."""

    def test_cli_debug_overrides_config_log_level(self):
        args = _make_args(debug=True)
        config = _make_config(log_level="WARNING")

        with patch.object(main, "setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["level"] == LogLevel.DEBUG

    def test_cli_quiet_overrides_config_log_level(self):
        args = _make_args(quiet=True)
        config = _make_config(log_level="DEBUG")

        with patch.object(main, "setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["level"] == LogLevel.ERROR

    def test_config_log_level_used_when_no_cli_flags(self):
        args = _make_args()
        config = _make_config(log_level="WARNING")

        with patch.object(main, "setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["level"] == LogLevel.WARNING

    def test_cli_log_file_overrides_config_log_file(self):
        args = _make_args(log_file="/tmp/cli.log")
        config = _make_config(log_file="/tmp/config.log")

        with patch.object(main, "setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["log_file"] == "/tmp/cli.log"

    def test_config_log_file_used_when_cli_log_file_absent(self):
        args = _make_args(log_file=None)
        config = _make_config(log_file="/tmp/config.log")

        with patch.object(main, "setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["log_file"] == "/tmp/config.log"


class TestApplyLoggingConfigPropagation:
    """Verify that config-only logging fields propagate to setup_logging."""

    def test_config_only_fields_propagate(self):
        args = _make_args()
        config = _make_config(
            colored_output=False,
            show_log_icons=False,
            json_logs=True,
            log_file_max_size_mb=25,
            log_file_backup_count=7,
        )

        with patch.object(main, "setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        kwargs = mock_setup.call_args.kwargs
        assert kwargs["colored_output"] is False
        assert kwargs["show_icons"] is False
        assert kwargs["json_logs"] is True
        assert kwargs["max_file_size"] == 25 * 1024 * 1024
        assert kwargs["backup_count"] == 7

    def test_quiet_forces_color_and_icons_off_even_when_config_enables_them(self):
        args = _make_args(quiet=True)
        config = _make_config(colored_output=True, show_log_icons=True)

        with patch.object(main, "setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        kwargs = mock_setup.call_args.kwargs
        assert kwargs["colored_output"] is False
        assert kwargs["show_icons"] is False
