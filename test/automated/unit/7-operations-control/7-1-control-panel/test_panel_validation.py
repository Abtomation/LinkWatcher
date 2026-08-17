"""
Document Metadata:
ID: TE-TST-149
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-10
Updated: 2026-08-10
Component Name: validation
Feature Id: 7.1.1
Language: Python
Test Name: panel_validation
Test Type: Unit

Unit tests for the Control Panel validation runner
(``linkwatcher.linkwatcher_control_panel.validation``):

- UNIT-V1 — exit 0 → ``ok`` with 0 broken links
- UNIT-V2 — exit 1 with a report → ``broken`` with the count parsed from the
  report file (path located via stdout's ANSI-colored "Report written to" line,
  falling back to the conventional ``logs/linkwatcher/LinkWatcherBrokenLinks
  .txt``) — the TDD §8 Q3 resolution
- UNIT-V3 — spawn failure / timeout / nonzero without a report → ``failed``
  with the captured reason, never rendered as success (EC-6)
- UNIT-V4 — one run per project at a time; other projects unaffected (BR-6)
- UNIT-V5 — command construction mirrors ``run_linkwatcher_validate.ps1``:
  install venv python, ``--project-root``, ``--config`` only when the
  per-project config exists; no lock is ever taken (the daemon is untouched)
"""

import sys
from pathlib import Path

import pytest

from linkwatcher.linkwatcher_control_panel.lifecycle import RunResult
from linkwatcher.linkwatcher_control_panel.model import AppModel, DaemonSnapshot, DaemonStatus
from linkwatcher.linkwatcher_control_panel.validation import (
    REPORT_FILENAME,
    ValidationController,
    build_validate_command,
    parse_validation_result,
    strip_ansi,
    validator_python,
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
def write_report(log_dir: Path, broken: int) -> Path:
    """A report file with the validator's stable summary line."""
    report = Path(log_dir) / REPORT_FILENAME
    report.write_text(
        "LinkWatcher - Link Validation Report\n"
        f"Files scanned : 10\nLinks checked : 25\nBroken links  : {broken}\n",
        encoding="utf-8",
    )
    return report


def cyan(text: str) -> str:
    """Wrap *text* in the ANSI color codes colorama emits on captured stdout."""
    return f"\x1b[36m{text}\x1b[0m"


def model_with(project, status=DaemonStatus.RUNNING):
    model = AppModel()
    model.apply_poll([DaemonSnapshot(project=project, status=status, pids=[])])
    return model


# --------------------------------------------------------------------------- #
# UNIT-V1 — clean result
# --------------------------------------------------------------------------- #
def test_exit_zero_is_ok_with_zero_broken(make_project):
    project = make_project()
    result = RunResult(0, "Validating links...\nNo broken links found.\n", "")

    run = parse_validation_result(result, project.log_dir)

    assert run.state == "ok"
    assert run.broken_count == 0
    assert run.error is None


def test_clean_result_still_carries_the_report_path(make_project):
    """The validator writes a report even when clean — surface it."""
    project = make_project()
    report = write_report(project.log_dir, 0)
    stdout = f"...\n{cyan('📄 Report written to ' + str(report))}\n"

    run = parse_validation_result(RunResult(0, stdout, ""), project.log_dir)

    assert run.state == "ok" and run.report_path == report


# --------------------------------------------------------------------------- #
# UNIT-V2 — broken links (TDD §8 Q3 resolution)
# --------------------------------------------------------------------------- #
def test_broken_count_comes_from_the_report_file(make_project):
    """Path located via the ANSI-colored stdout line; count from the report."""
    project = make_project()
    report = write_report(project.log_dir, 3)
    stdout = f"validation output...\n{cyan('📄 Report written to ' + str(report))}\n"

    run = parse_validation_result(RunResult(1, stdout, ""), project.log_dir)

    assert run.state == "broken"
    assert run.broken_count == 3
    assert run.report_path == report


def test_report_found_at_conventional_path_without_stdout_locator(make_project):
    project = make_project()
    report = write_report(project.log_dir, 7)

    run = parse_validation_result(RunResult(1, "", ""), project.log_dir)

    assert run.state == "broken"
    assert run.broken_count == 7
    assert run.report_path == report


def test_count_falls_back_to_stdout_when_report_lacks_the_line(make_project):
    project = make_project()
    report = Path(project.log_dir) / REPORT_FILENAME
    report.write_text("unexpected format\n", encoding="utf-8")
    stdout = f"Broken links  : 5\n{cyan('📄 Report written to ' + str(report))}\n"

    run = parse_validation_result(RunResult(1, stdout, ""), project.log_dir)

    assert run.state == "broken" and run.broken_count == 5


# --------------------------------------------------------------------------- #
# UNIT-V3 — failure is never rendered as success (EC-6)
# --------------------------------------------------------------------------- #
def test_nonzero_without_report_is_failed(make_project):
    project = make_project()

    run = parse_validation_result(RunResult(1, "", "Traceback: boom"), project.log_dir)

    assert run.state == "failed"
    assert "boom" in run.error
    assert run.broken_count is None


def test_unexpected_exit_code_is_failed(make_project):
    project = make_project()
    write_report(project.log_dir, 2)  # even with a report lying around

    run = parse_validation_result(RunResult(3, "", "crashed"), project.log_dir)

    assert run.state == "failed" and "crashed" in run.error


def test_timeout_is_failed(make_project):
    project = make_project()

    run = parse_validation_result(RunResult(None, "", "", timed_out=True), project.log_dir)

    assert run.state == "failed" and "did not finish" in run.error


def test_spawn_failure_surfaces_as_failed(make_project):
    """A runner that raises (missing interpreter) becomes a failed state."""

    class RaisingRunner:
        def run(self, args, timeout):
            raise FileNotFoundError("python.exe not found")

    project = make_project()
    model = model_with(project)
    applied = []
    controller = ValidationController(
        model=model,
        post=lambda cb: applied.append(cb),
        install_dir=project.root,
        runner=RaisingRunner(),
        executor=lambda fn: fn(),
    )

    assert controller.run(project.project_id)
    for callback in applied:
        callback()
    run = model.validation[project.project_id]
    assert run.state == "failed" and "python.exe not found" in run.error


# --------------------------------------------------------------------------- #
# UNIT-V4 — one run per project at a time (BR-6)
# --------------------------------------------------------------------------- #
def test_second_trigger_rejected_while_running_other_projects_unaffected(make_project, fake_runner):
    project_a = make_project("PRJ-001")
    project_b = make_project("PRJ-002")
    model = AppModel()
    model.apply_poll(
        [
            DaemonSnapshot(project=project_a, status=DaemonStatus.RUNNING, pids=[]),
            DaemonSnapshot(project=project_b, status=DaemonStatus.RUNNING, pids=[]),
        ]
    )
    deferred = []
    applied = []
    controller = ValidationController(
        model=model,
        post=lambda cb: applied.append(cb),
        install_dir=project_a.root,
        runner=fake_runner.script(RunResult(0, "clean", "")),
        executor=deferred.append,  # workers held, run stays in flight
    )

    assert controller.run(project_a.project_id) is True
    assert model.validation[project_a.project_id].state == "running"
    assert controller.run(project_a.project_id) is False  # same project rejected
    assert controller.run(project_b.project_id) is True  # other project unaffected

    for worker in deferred:
        worker()
    for callback in applied:
        callback()
    assert model.validation[project_a.project_id].state == "ok"
    assert model.validation[project_b.project_id].state == "ok"
    # Both runs released their busy claim — a new run is accepted again.
    assert controller.run(project_a.project_id) is True


def test_run_for_unknown_project_is_rejected(make_project):
    model = AppModel()
    controller = ValidationController(
        model=model, post=lambda cb: cb(), install_dir=".", executor=lambda fn: fn()
    )
    assert controller.run("PRJ-404") is False


# --------------------------------------------------------------------------- #
# UNIT-V5 — command construction (mirrors run_linkwatcher_validate.ps1)
# --------------------------------------------------------------------------- #
def test_command_without_config(make_project, tmp_path):
    install_dir = tmp_path / "install"
    install_dir.mkdir()
    project = make_project()

    command = build_validate_command(install_dir, project)

    assert command[0] == sys.executable  # no install venv → dev fallback
    assert command[1] == str(install_dir / "main.py")
    assert command[2:5] == ["--project-root", str(project.root), "--validate"]
    assert "--config" not in command


def test_config_appended_only_when_it_exists(make_project, tmp_path):
    install_dir = tmp_path / "install"
    install_dir.mkdir()
    project = make_project()
    Path(project.config_path).write_text("path_resolution_overrides: {}\n", encoding="utf-8")

    command = build_validate_command(install_dir, project)

    assert command[-2:] == ["--config", str(project.config_path)]


def test_install_venv_python_is_preferred(tmp_path):
    install_dir = tmp_path / "install"
    venv_python = install_dir / ".linkwatcher-venv" / "Scripts" / "python.exe"
    venv_python.parent.mkdir(parents=True)
    venv_python.write_text("", encoding="utf-8")

    assert validator_python(install_dir) == str(venv_python)


def test_strip_ansi_removes_color_codes():
    assert strip_ansi(cyan("Report written to C:\\x\\r.txt")) == "Report written to C:\\x\\r.txt"
