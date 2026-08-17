"""
On-demand link validation for the Control Panel's Validation pane (TDD §4.6).

Runs ``main.py --validate`` for one project as a short-lived subprocess —
``--validate`` takes no lock, so the project's running daemon is untouched
(BR-6/AC-6).  Command construction mirrors ``run_linkwatcher_validate.ps1``:
the install's dedicated venv python, ``--project-root``, and ``--config`` only
when the per-project config exists.

AI Context
----------
- **Broken-link count extraction (TDD §8 Q3, resolved Phase E, checkpoint-
  approved 2026-08-10)**: the report *path* is parsed from stdout's
  ``Report written to <path>`` line (ANSI-stripped — the CLI prints colored
  output), falling back to the conventional ``<log_dir>/LinkWatcherBrokenLinks
  .txt``; the *count* comes from the report file's stable, colorless
  ``Broken links  : N`` line, falling back to the same line in stdout.  The
  report file is the more stable surface; stdout remains the locator ("the
  report location is owned by the build", per the validate launcher).
- **Exit-code contract** (UNIT-V1…V3): 0 → ``ok`` (0 broken); 1 *with* a
  report → ``broken`` with the parsed count; anything else — spawn failure,
  timeout, nonzero without a report — → ``failed`` with the captured reason,
  never rendered as success (EC-6).
- **One run per project at a time** (UNIT-V4): a second trigger for the same
  project is rejected while its run is in flight; other projects are
  unaffected.  Same busy-guard pattern as :class:`~.lifecycle.LifecycleController`.
- Subprocess capture reuses :class:`~.lifecycle.SubprocessRunner` (temp files,
  bounded wait) — uniform with the launcher path, and a generous timeout turns
  a hung validator into a surfaced ``failed`` instead of a forever-spinner.
"""

from __future__ import annotations

import re
import sys
import threading
from pathlib import Path
from typing import Callable, List, Optional

from .lifecycle import RunResult, SubprocessRunner
from .model import AppModel, ProjectInfo, ValidationRun
from .panel_log import get_panel_logger

# Bound on one validation run; large projects take a while, but a hung
# subprocess must eventually surface as `failed` rather than spin forever.
VALIDATE_TIMEOUT_SECONDS = 600.0

# The report filename the validator writes (LinkValidator.write_report).
REPORT_FILENAME = "LinkWatcherBrokenLinks.txt"

# Colorama/ANSI escape sequences in captured CLI output.
_ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")

# `main.py --validate` prints "📄 Report written to <path>" on completion.
_REPORT_WRITTEN_RE = re.compile(r"Report written to\s+(.+?)\s*$", re.MULTILINE)

# The stable summary line, identical in the report file and the stdout copy.
_BROKEN_COUNT_RE = re.compile(r"Broken links\s*:\s*(\d+)")


def strip_ansi(text: str) -> str:
    """Remove ANSI escape sequences from captured subprocess output."""
    return _ANSI_RE.sub("", text)


def _short(text: str, limit: int = 300) -> str:
    """Collapse *text* to one bounded line for pane/status display."""
    collapsed = " ".join(text.split())
    return collapsed if len(collapsed) <= limit else collapsed[: limit - 1] + "…"


# --------------------------------------------------------------------------- #
# Command construction (UNIT-V5)
# --------------------------------------------------------------------------- #
def validator_python(install_dir) -> str:
    """The interpreter to run ``--validate`` with.

    Prefers the install's dedicated venv python — exactly what
    ``run_linkwatcher_validate.ps1`` resolves — and falls back to
    ``sys.executable`` (the dev-repo case, where the panel already runs under
    the project venv).
    """
    venv_python = Path(install_dir) / ".linkwatcher-venv" / "Scripts" / "python.exe"
    if venv_python.is_file():
        return str(venv_python)
    return sys.executable


def build_validate_command(install_dir, project: ProjectInfo) -> List[str]:
    """The ``main.py --validate`` argument list for *project* (UNIT-V5).

    ``--config`` is appended only when the per-project config exists, mirroring
    the validate launcher's semantics; ``--validate`` takes no lock, so the
    running daemon is never touched (BR-6).
    """
    install_dir = Path(install_dir)
    command = [
        validator_python(install_dir),
        str(install_dir / "main.py"),
        "--project-root",
        str(project.root),
        "--validate",
    ]
    if Path(project.config_path).is_file():
        command += ["--config", str(project.config_path)]
    return command


# --------------------------------------------------------------------------- #
# Result parsing (UNIT-V1…V3; TDD §8 Q3)
# --------------------------------------------------------------------------- #
def _report_path(stdout_clean: str, log_dir) -> Optional[Path]:
    """Locate the written report: the stdout locator line, else the convention."""
    match = _REPORT_WRITTEN_RE.search(stdout_clean)
    if match:
        candidate = Path(match.group(1).strip())
        if candidate.is_file():
            return candidate
    conventional = Path(log_dir) / REPORT_FILENAME
    if conventional.is_file():
        return conventional
    return None


def _count_from_report(report_path: Path) -> Optional[int]:
    try:
        text = Path(report_path).read_text(encoding="utf-8")
    except OSError:
        return None
    match = _BROKEN_COUNT_RE.search(text)
    return int(match.group(1)) if match else None


def parse_validation_result(result: RunResult, log_dir) -> ValidationRun:
    """Map a finished ``--validate`` subprocess to a :class:`ValidationRun`.

    Never renders a failure as success (EC-6): only exit 0, or exit 1 with a
    locatable report, produce a result state.
    """
    if result.timed_out:
        return ValidationRun(
            state="failed",
            error=f"Validation did not finish within {VALIDATE_TIMEOUT_SECONDS:.0f} s",
        )

    stdout_clean = strip_ansi(result.stdout)
    report = _report_path(stdout_clean, log_dir)

    if result.returncode == 0:
        return ValidationRun(state="ok", broken_count=0, report_path=report)

    if result.returncode == 1 and report is not None:
        count = _count_from_report(report)
        if count is None:
            match = _BROKEN_COUNT_RE.search(stdout_clean)
            count = int(match.group(1)) if match else None
        return ValidationRun(state="broken", broken_count=count, report_path=report)

    reason = result.stderr.strip() or stdout_clean.strip()
    if not reason:
        reason = f"Validator exited with code {result.returncode} and no output"
    return ValidationRun(state="failed", error=_short(reason))


# --------------------------------------------------------------------------- #
# Controller (worker orchestration + model updates)
# --------------------------------------------------------------------------- #
class ValidationController:
    """Owns validation worker threads; model updates funnel to the UI thread.

    :meth:`run` is called from UI-thread event handlers, so it may set the
    ``running`` state directly; worker completions go through *post* (the
    app's dispatcher queue).  One run per project at a time (UNIT-V4).
    """

    def __init__(
        self,
        *,
        model: AppModel,
        post: Callable[[Callable[[], None]], None],
        install_dir,
        runner: Optional[SubprocessRunner] = None,
        timeout: float = VALIDATE_TIMEOUT_SECONDS,
        executor: Optional[Callable[[Callable[[], None]], None]] = None,
    ):
        self._model = model
        self._post = post
        self._install_dir = Path(install_dir)
        self._runner = runner if runner is not None else SubprocessRunner()
        self._timeout = timeout
        self._executor = executor
        self._log = get_panel_logger()
        self._busy: set = set()
        self._busy_lock = threading.Lock()

    def is_running(self, project_id: str) -> bool:
        """Whether a validation run is in flight for *project_id*."""
        with self._busy_lock:
            return project_id in self._busy

    def run(self, project_id: str) -> bool:
        """Trigger a validation run; ``False`` if unknown or already running."""
        snapshot = self._model.snapshot_for(project_id)
        if snapshot is None:
            return False
        with self._busy_lock:
            if project_id in self._busy:
                return False
            self._busy.add(project_id)
        project = snapshot.project
        self._model.set_validation(project_id, ValidationRun(state="running"))
        self._run_worker(
            f"lw-panel-validate-{project_id}", lambda: self._worker(project_id, project)
        )
        return True

    # ------------------------------------------------------------------ #
    # Worker (worker thread; model access only via post)
    # ------------------------------------------------------------------ #
    def _worker(self, project_id: str, project: ProjectInfo) -> None:
        try:
            command = build_validate_command(self._install_dir, project)
            result = self._runner.run(command, self._timeout)
            run = parse_validation_result(result, project.log_dir)
            if run.state == "failed":
                self._log.warning("validation_failed project=%s reason=%r", project_id, run.error)
            else:
                self._log.info(
                    "validation_complete project=%s state=%s broken=%s",
                    project_id,
                    run.state,
                    run.broken_count,
                )
        except Exception as exc:  # noqa: BLE001 - worker errors surface, never crash
            self._log.exception("validation_worker_failed project=%s", project_id)
            run = ValidationRun(state="failed", error=_short(f"Validation failed: {exc}"))
        finally:
            with self._busy_lock:
                self._busy.discard(project_id)
        self._post(lambda: self._model.set_validation(project_id, run))

    def _run_worker(self, name: str, fn: Callable[[], None]) -> None:
        if self._executor is not None:
            self._executor(fn)
            return
        threading.Thread(target=fn, name=name, daemon=True).start()
