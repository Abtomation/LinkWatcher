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

import sys
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


class TestBug123InvalidLogLevelDoesNotPreemptValidation:
    """PD-BUG-123: an invalid ``log_level`` raised out of ``_apply_logging_config``
    *before* ``config.validate()`` ever ran.

    ``main()`` calls this helper at line ~450 and ``config.validate()`` at ~453,
    so ``LogLevel(config.log_level)`` raising ``ValueError`` pre-empted the very
    report that names the offending key — the operator got a raw Python message
    from inside the top-level ``except Exception`` instead of a ``config_issue``
    line. Guarding ``validate()`` alone (the settings.py half of this fix) was
    not enough to deliver the bug's stated expectation for ``log_level``, which
    is the field its own headline repro used.

    Contract: logging comes up on a safe default so the diagnosis can be
    *emitted*. This is not a silent fallback — the invalid value is still fatal,
    it is just reported by the function whose contract that is, and ``main()``
    still exits 1.
    """

    @pytest.mark.parametrize("bad_level", [5, "INVALID", None, 2.5, ["DEBUG"]])
    def test_invalid_log_level_does_not_raise(self, bad_level):
        args = _make_args()
        config = _make_config(log_level=bad_level)

        with patch("main.setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.called, "logging must still be configured"

    def test_invalid_log_level_falls_back_to_info(self):
        args = _make_args()
        config = _make_config(log_level=5)

        with patch("main.setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["level"] == LogLevel.INFO

    def test_the_invalid_value_is_still_reported_by_validate(self):
        """The fallback must not make the bad value survivable."""
        config = _make_config(log_level=5)

        issues = config.validate()

        assert any("log_level" in issue for issue in issues), issues

    @pytest.mark.parametrize("level_name", ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"])
    def test_control_valid_levels_are_unaffected(self, level_name):
        """Every valid level must still resolve to itself, not to the fallback."""
        args = _make_args()
        config = _make_config(log_level=level_name)

        with patch("main.setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["level"] == LogLevel(level_name)


class TestBug127InvalidRotationValuesDoNotPreemptValidation:
    """PD-BUG-127: the sibling ordering defect, on the two log-rotation fields.

    `_apply_logging_config` computes `config.log_file_max_size_mb * 1024 * 1024`
    and passes `config.log_file_backup_count` straight to `setup_logging` —
    both *before* `config.validate()` runs in `main()`. Fixing `validate()`
    alone is therefore not enough: `log_file_max_size_mb: big` still reached
    the `RotatingFileHandler` constructor, whose `if maxBytes > 0` raised
    `TypeError` and surfaced as a generic `fatal_error` naming no key.

    Same contract as the `log_level` fallback directly above: logging comes up
    on the schema default so the diagnosis can be *emitted*. The value stays
    fatal — `validate()` reports it and `main()` exits 1.
    """

    @pytest.mark.parametrize("bad_size", ["big", True, None, [10], 0, -5])
    def test_invalid_rotation_size_does_not_raise(self, bad_size):
        args = _make_args()
        config = _make_config(log_file_max_size_mb=bad_size)

        with patch("main.setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.called, "logging must still be configured"

    @pytest.mark.parametrize("bad_count", ["x", True, None, 3.5, -1])
    def test_invalid_backup_count_does_not_raise(self, bad_count):
        args = _make_args()
        config = _make_config(log_file_backup_count=bad_count)

        with patch("main.setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.called, "logging must still be configured"

    def test_invalid_rotation_size_falls_back_to_the_schema_default(self):
        args = _make_args()
        config = _make_config(log_file_max_size_mb="big")

        with patch("main.setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["max_file_size"] == 10 * 1024 * 1024

    def test_invalid_backup_count_falls_back_to_the_schema_default(self):
        args = _make_args()
        config = _make_config(log_file_backup_count="x")

        with patch("main.setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["backup_count"] == 5

    def test_a_handler_built_from_the_fallback_values_actually_works(self, tmp_path):
        """The fallback must produce values the handler accepts — the whole
        point is that startup survives long enough to report the real issue.
        """
        args = _make_args(log_file=str(tmp_path / "lw.log"))
        config = _make_config(log_file_max_size_mb="big", log_file_backup_count="x")

        main._apply_logging_config(args, config)  # raised TypeError pre-fix

    def test_the_invalid_values_are_still_reported_by_validate(self):
        """The fallback must not make the bad values survivable."""
        config = _make_config(log_file_max_size_mb="big", log_file_backup_count="x")

        issues = config.validate()

        assert any("log_file_max_size_mb" in issue for issue in issues), issues
        assert any("log_file_backup_count" in issue for issue in issues), issues

    def test_control_valid_rotation_values_are_passed_through_unchanged(self):
        args = _make_args()
        config = _make_config(log_file_max_size_mb=25, log_file_backup_count=7)

        with patch("main.setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        kwargs = mock_setup.call_args.kwargs
        assert kwargs["max_file_size"] == 25 * 1024 * 1024
        assert kwargs["backup_count"] == 7

    def test_control_zero_backup_count_is_not_treated_as_invalid(self):
        """0 disables pruning — a real setting, not a bad value to replace."""
        args = _make_args()
        config = _make_config(log_file_backup_count=0)

        with patch("main.setup_logging") as mock_setup:
            main._apply_logging_config(args, config)

        assert mock_setup.call_args.kwargs["backup_count"] == 0


class TestBug128ValidatePathValidatesConfig:
    """PD-BUG-128: the caller-side half of the PD-BUG-123 / PD-BUG-127 contract.

    `_apply_logging_config` degrades an unusable value to the schema default and
    defers the diagnosis to `config.validate()`. That deferral is only honest if
    every caller actually runs the second half. `main()`'s daemon branch does;
    its `--validate` branch called the first half and never the second, so an
    unusable value produced a clean report at exit 0 while the daemon refused to
    start on the very same config.

    The blast radius is wider than the rotation keys the report named: the
    missing call gates *every* key `validate()` checks, including
    `validation_extensions` — where it turns a scan that examined nothing into a
    "No broken links found" pass.

    These tests drive `main.main()` end to end rather than the helper, because
    the defect is in the wiring between the two halves, not in either half.
    """

    @staticmethod
    def _tree(tmp_path, link_target=None):
        """A project root holding one markdown file, optionally with a bad link."""
        project = tmp_path / "project"
        project.mkdir()
        body = "# Doc\n\nNo links here.\n"
        if link_target:
            body = "# Doc\n\n[broken](%s)\n" % link_target
        (project / "a.md").write_text(body, encoding="utf-8")
        return project

    @staticmethod
    def _run_validate(project, config_path=None, quiet=True):
        """Run `main.main()` on the --validate path; return its exit code.

        `quiet` is a parameter rather than a constant because `load_config`
        rewrites `config.log_level` to ERROR under `--quiet` (CLI beats config,
        by design) -- so a `log_level` case run quietly would never reach
        `validate()` and would prove nothing about this bug.
        """
        argv = ["main.py", "--validate", "--project-root", str(project)]
        if quiet:
            argv.insert(2, "--quiet")
        if config_path:
            argv += ["--config", str(config_path)]
        with patch.object(sys, "argv", argv):
            with pytest.raises(SystemExit) as excinfo:
                main.main()
        return excinfo.value.code

    def _config(self, tmp_path, body):
        cfg = tmp_path / "lw-config.yaml"
        cfg.write_text(body, encoding="utf-8")
        return cfg

    @pytest.mark.parametrize(
        "body",
        [
            "log_file_max_size_mb: big\n",
            "log_file_backup_count: x\n",
        ],
    )
    def test_an_unusable_config_value_is_not_reported_as_a_clean_run(self, tmp_path, body):
        """The exact defect: exit 0 on a config the daemon rejects.

        Negative assertion on purpose — asserting merely that *some* error is
        emitted would pass while the run still handed automation a clean pass.
        """
        project = self._tree(tmp_path)
        code = self._run_validate(project, self._config(tmp_path, body))

        assert code != 0, "a config the daemon refuses to start on must not validate cleanly"

    def test_an_unusable_log_level_is_not_reported_as_a_clean_run(self, tmp_path):
        """The third field sharing this fallback shape (PD-BUG-123).

        Run without `--quiet`: that flag rewrites `log_level` in `load_config`
        before validation ever sees it, which would mask the very thing under
        test -- the reason this case is not in the parametrized set above.
        """
        project = self._tree(tmp_path)
        cfg = self._config(tmp_path, "log_level: LOUD' + BS_N + '")

        code = self._run_validate(project, cfg, quiet=False)

        assert code != 0, "an unusable log_level must not validate cleanly either"

    def test_the_offending_key_is_named(self, tmp_path, capsys):
        project = self._tree(tmp_path)
        cfg = self._config(tmp_path, "log_file_max_size_mb: big\n")

        self._run_validate(project, cfg)
        output = capsys.readouterr()

        assert "log_file_max_size_mb" in (output.out + output.err)

    def test_a_bad_config_cannot_turn_a_broken_tree_into_a_clean_report(self, tmp_path):
        """The manifestation the report did not name, and the reason this is not cosmetic.

        `validation_extensions` given as a bare string instead of a list is a
        real typo shape that `validate()` does catch. Unchecked, the scan
        matches `Path.suffix` against the characters of that string, examines
        nothing, and reports "No broken links found" at exit 0 — on a tree whose
        link is genuinely broken.
        """
        project = self._tree(tmp_path, link_target="does-not-exist.md")
        cfg = self._config(tmp_path, 'validation_extensions: ".yaml"\n')

        code = self._run_validate(project, cfg)

        assert code != 0, "a vacuous scan must never be reported as a clean pass"

    def test_control_a_clean_tree_with_a_valid_config_still_exits_zero(self, tmp_path):
        project = self._tree(tmp_path)
        cfg = self._config(tmp_path, "log_file_max_size_mb: 25\n")

        assert self._run_validate(project, cfg) == 0

    def test_control_a_broken_link_still_exits_one(self, tmp_path):
        project = self._tree(tmp_path, link_target="does-not-exist.md")

        assert self._run_validate(project) == 1

    def test_control_no_config_file_at_all_still_validates(self, tmp_path):
        project = self._tree(tmp_path)

        assert self._run_validate(project) == 0
