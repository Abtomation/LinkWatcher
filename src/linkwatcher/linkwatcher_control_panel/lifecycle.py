"""
Lifecycle actions for the LinkWatcher Control Panel — start / drain / terminate.

Phase C of the panel implementation (TDD §4.4): start a daemon by shelling out
to the project's own launcher, and stop one by *observational drain* — watch the
newest log file for quiescence, then terminate the verified process pair,
force-terminating (and saying so) when the grace period elapses.  Windows offers
no graceful cross-process signal (``terminate()`` is a hard ``TerminateProcess``),
so drain is a heuristic bounded by ``grace_period_seconds`` (FDD BR-7).

AI Context
----------
- **The termination guard is the point of this module.** The three-way identity
  test (:func:`~.discovery.is_daemon_for`, D-T5) is re-run against a *fresh*
  process snapshot at kill time — never trusted from poll time.  A PID recycled
  between poll and action fails the test and is not touched; when nothing
  passes, nothing is terminated (UNIT-L9).  Termination acts on **every**
  process that passes the kill-time test — the verified pair, plus any
  accidental duplicate daemons for the same project.
- **Start never spawns the daemon directly** (D-T4): it runs the project's own
  ``start_linkwatcher_background.ps1``, inheriting its singleton guards,
  stale-lock reclaim, and crash disposition.  Exit 0 is "started or already
  running" (idempotent, EC-2/AC-10); exit 1 is a surfaced START_FAILED (EC-7).
- **Launcher output is captured via temp files, never pipes.** The launcher's
  spawned daemon inherits our handles and holds them for its lifetime; a
  pipe-capturing parent never sees EOF and hangs indefinitely (documented in
  the launcher's own header, locked in by TE-E2E-009).
- **Lock cleanup mirrors ``main.py``'s self-owned rule**: after a confirmed
  exit the lock is deleted only when it still names a PID we just terminated —
  a foreign lock (reclaimed by a successor) is left intact (UNIT-L10/L11).
- **Model mutations are posted to the UI thread**, except the initial pin,
  which :meth:`LifecycleController.start`/``stop`` place directly because they
  are invoked from UI-thread event handlers.
- **Testability seams**: ``runner`` (launcher subprocess), ``terminator``,
  ``process_table``, ``clock``, ``sleep``, ``log_stat``, and ``executor``
  (worker threading) are all injectable — unit tests drive the entire drain
  state machine with a fake clock and never wait real seconds.
- **Shutdown (Phase D)**: :class:`ShutdownOrchestrator` fans the same drain out
  over every managed daemon on window close — completion is observational
  (the poller keeps running so clean drains resolve), and a watchdog bounds
  the exit regardless of worker state (AC-9).
"""

from __future__ import annotations

import os
import subprocess
import tempfile
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, List, Mapping, NamedTuple, Optional, Sequence, Tuple

from .discovery import LOCK_FILE_NAME, is_daemon_for, read_lock_pid
from .model import AppModel, DaemonStatus, ProjectInfo
from .panel_log import get_panel_logger

# The launcher inside every registered project (the same script the hook runs).
_LAUNCHER_RELPATH = (
    Path("process-framework") / "tools" / "linkWatcher" / "start_linkwatcher_background.ps1"
)

# Bounded launcher wait: the launcher sleeps ~2 s for its post-start check; 30 s
# covers a slow spawn without letting a hung shell pin the row forever.
LAUNCHER_TIMEOUT_SECONDS = 30.0

# How long to wait for terminated processes to leave the process table.
EXIT_WAIT_TIMEOUT_SECONDS = 10.0

# Pin TTLs (TDD §4.3): a pin must outlive the worker that owns it, or the row
# reverts to poll truth while its action is still running.
START_PIN_MARGIN_SECONDS = 5.0

# The stop worker's worst case is `watch_quiescence` (up to the full grace
# period) followed by `wait_for_exit` (up to EXIT_WAIT_TIMEOUT_SECONDS), so the
# drain margin must cover the exit wait plus slack — not the 5 s it used to
# carry, which expired the pin at grace + 5 s while the worker could still be
# working until grace + 10 s.  In that 5 s window the row flipped back to
# Running, re-enabling a Stop button whose click the controller's busy guard
# then swallowed (CR-8).  Same quantity, and deliberately the same value, as
# WATCHDOG_MARGIN_SECONDS below.
DRAIN_PIN_MARGIN_SECONDS = EXIT_WAIT_TIMEOUT_SECONDS + 5.0

# Outcome surfacings (FORCE_STOPPED / START_FAILED) stay visible this long,
# then poll truth wins again (checkpoint-approved 2026-08-10).
OUTCOME_PIN_TTL_SECONDS = 30.0

# Cadence of drain / exit-wait checks (tests inject clock+sleep instead).
CHECK_INTERVAL_SECONDS = 0.25


# --------------------------------------------------------------------------- #
# Launcher invocation (start path)
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class RunResult:
    """Outcome of one launcher invocation. ``returncode`` is ``None`` on timeout."""

    returncode: Optional[int]
    stdout: str
    stderr: str
    timed_out: bool = False


# Prefixes for the launcher's stdout/stderr capture files, and the age after
# which a leftover is considered abandoned by its daemon and safe to remove.
_CAPTURE_OUT_PREFIX = "lw-panel-out-"
_CAPTURE_ERR_PREFIX = "lw-panel-err-"
_CAPTURE_MAX_AGE_SECONDS = 3600.0


def _sweep_stale_captures(now: Optional[float] = None) -> int:
    """Delete launcher capture files left behind by earlier runs (CR-12).

    Best-effort and silent: a file still held by a live daemon simply fails to
    unlink and is retried on a later run.  Only this module's own two prefixes
    are considered, and only entries older than ``_CAPTURE_MAX_AGE_SECONDS``, so
    a capture belonging to a start that is still in flight is never touched.
    Returns the number removed (for tests).
    """
    removed = 0
    reference = time.time() if now is None else now
    try:
        temp_dir = Path(tempfile.gettempdir())
        entries = list(temp_dir.iterdir())
    except OSError:
        return 0
    for entry in entries:
        if not entry.name.startswith((_CAPTURE_OUT_PREFIX, _CAPTURE_ERR_PREFIX)):
            continue
        try:
            if reference - entry.stat().st_mtime < _CAPTURE_MAX_AGE_SECONDS:
                continue
            entry.unlink()
            removed += 1
        except OSError:
            continue  # still held by a running daemon, or already gone
    return removed


class SubprocessRunner:
    """Real launcher invocation: hidden window, temp-file capture, bounded wait.

    Capture MUST be via temp files, not pipes: the launcher's spawned daemon
    inherits this process's handles and holds them for its whole lifetime, so a
    pipe-capturing parent (``subprocess.run(capture_output=True)``) never sees
    EOF and hangs.  The temp files are read after the bounded wait.

    Deleting them then usually *fails*, because the daemon still holds the
    inherited handle and the CRT opens without ``FILE_SHARE_DELETE``.  The
    previous justification for tolerating that — "cleaned up by the OS" — is
    simply not true on Windows: every successful Start left a pair behind, and
    files nearly eight days old were still present when this was measured
    (CR-12).  Since the inheritance is the launcher's to fix and not reachable
    from here, accumulation is instead *bounded*: each run first sweeps captures
    left by earlier runs, which by then are closed and deletable.
    """

    def run(self, args: Sequence[str], timeout: float) -> RunResult:
        _sweep_stale_captures()
        out_fd, out_path = tempfile.mkstemp(prefix=_CAPTURE_OUT_PREFIX, suffix=".txt")
        err_fd, err_path = tempfile.mkstemp(prefix=_CAPTURE_ERR_PREFIX, suffix=".txt")
        try:
            with os.fdopen(out_fd, "wb") as out_file, os.fdopen(err_fd, "wb") as err_file:
                process = subprocess.Popen(
                    list(args),
                    stdout=out_file,
                    stderr=err_file,
                    stdin=subprocess.DEVNULL,
                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
                )
                timed_out = False
                returncode: Optional[int] = None
                try:
                    returncode = process.wait(timeout=timeout)
                except subprocess.TimeoutExpired:
                    timed_out = True
                    process.kill()
            stdout = Path(out_path).read_text(encoding="utf-8", errors="replace")
            stderr = Path(err_path).read_text(encoding="utf-8", errors="replace")
            return RunResult(returncode, stdout, stderr, timed_out)
        finally:
            for path in (out_path, err_path):
                try:
                    os.unlink(path)
                except OSError:
                    pass


@dataclass(frozen=True)
class StartOutcome:
    """Result of a start request: launched/already-running, or a surfaced reason."""

    ok: bool
    reason: Optional[str] = None


def launcher_path(project_root: Path) -> Path:
    """The project's own launcher script (start goes only through it, D-T4)."""
    return Path(project_root) / _LAUNCHER_RELPATH


def resolve_shell(env: Optional[Mapping[str, str]] = None) -> str:
    """Absolute path to ``pwsh.exe``, resolved so the *current directory* cannot win.

    Windows ``CreateProcess`` searches the current directory before PATH, so
    spawning a bare ``"pwsh.exe"`` runs whatever sits in the panel's working
    directory (CR-9).  ``shutil.which`` is not a fix: on Windows it unconditionally
    prepends ``os.curdir`` to the search path — measured returning a ``.``-relative
    ``pwsh.exe``
    for a decoy in the working directory *even when given an explicit* ``path=``.

    So the PATH entries are walked directly and every relative one is skipped.
    Falls back to the bare name only when nothing absolute matches, which keeps a
    misconfigured machine working exactly as before rather than failing to start.
    """
    environ = os.environ if env is None else env
    for directory in environ.get("PATH", "").split(os.pathsep):
        directory = directory.strip().strip('"')
        if not directory or not os.path.isabs(directory):
            continue
        for name in ("pwsh.exe", "pwsh"):
            candidate = os.path.join(directory, name)
            if os.path.isfile(candidate):
                return candidate
    get_panel_logger().warning("launcher_shell_unresolved falling_back_to=pwsh.exe")
    return "pwsh.exe"


def _failure_reason(result: RunResult) -> str:
    """Best available human-readable reason for a failed launcher run.

    stderr is preferred, but the launcher reports its failures with
    ``Write-Host`` — which lands on *stdout* — so an empty stderr falls back to
    the stdout error lines (from the first line mentioning "error", to catch the
    launcher's ``Error: ...`` block including any relayed daemon stderr).
    """
    stderr = result.stderr.strip()
    if stderr:
        return stderr
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    for index, line in enumerate(lines):
        if "error" in line.casefold():
            return "\n".join(lines[index:])
    if lines:
        return "\n".join(lines[-3:])
    return f"Launcher exited with code {result.returncode} and no output"


def run_launcher(
    project: ProjectInfo,
    runner: SubprocessRunner,
    timeout: float = LAUNCHER_TIMEOUT_SECONDS,
) -> StartOutcome:
    """Start *project*'s daemon via its own launcher script.

    Exit 0 means started **or** already running — the launcher's singleton
    guards make the call idempotent (EC-2/AC-10), so both are success here.
    """
    script = launcher_path(project.root)
    if not script.is_file():
        return StartOutcome(False, f"Launcher script not found: {script}")
    result = runner.run(
        [resolve_shell(), "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(script)],
        timeout,
    )
    if result.timed_out:
        return StartOutcome(False, f"Launcher did not finish within {timeout:.0f} s")
    if result.returncode == 0:
        return StartOutcome(True)
    return StartOutcome(False, _failure_reason(result))


# --------------------------------------------------------------------------- #
# Drain heuristic (log quiescence watch)
# --------------------------------------------------------------------------- #
class LogStat(NamedTuple):
    """Identity + change signature of the newest log file in a project's log dir."""

    path: Path
    size: int
    mtime: float


def newest_log_stat(log_dir: Path) -> Optional[LogStat]:
    """Stat the newest ``LinkWatcherLog*.txt`` in *log_dir* (rotation-safe).

    "Newest" is by mtime — after a rotation the active log may carry a rotated
    sibling's name, so the filename alone is never trusted.  Returns ``None``
    when no log exists (or the directory is unreadable).
    """
    try:
        candidates = list(Path(log_dir).glob("LinkWatcherLog*.txt"))
    except OSError:
        return None
    best: Optional[LogStat] = None
    for path in candidates:
        try:
            stat = path.stat()
        except OSError:
            continue
        if best is None or stat.st_mtime > best.mtime:
            best = LogStat(path, stat.st_size, stat.st_mtime)
    return best


def watch_quiescence(
    log_dir: Path,
    *,
    idle_threshold: float,
    grace_period: float,
    clock: Callable[[], float] = time.monotonic,
    sleep: Callable[[float], None] = time.sleep,
    log_stat: Callable[[Path], Optional[LogStat]] = newest_log_stat,
    check_interval: float = CHECK_INTERVAL_SECONDS,
) -> bool:
    """Wait for the daemon's log to go quiet; ``True`` = quiescent, ``False`` = grace elapsed.

    Implements the TDD §4.4 drain flowchart: the newest log's (path, size,
    mtime) signature is sampled every *check_interval*; no change for
    *idle_threshold* seconds means the daemon is considered quiescent.  A
    rotation shows up as a signature change (new path/mtime) and correctly
    counts as activity.  **No log file at all is quiescent immediately** — the
    drain must not wait the full grace period on nothing (UNIT-L7).
    """
    started = clock()
    last = log_stat(log_dir)
    if last is None:
        return True
    last_change = started
    while True:
        now = clock()
        if now - last_change >= idle_threshold:
            return True
        if now - started >= grace_period:
            return False
        sleep(check_interval)
        current = log_stat(log_dir)
        if current != last:
            last = current
            last_change = clock()


# --------------------------------------------------------------------------- #
# Termination (guarded, pair-wide) + lock cleanup
# --------------------------------------------------------------------------- #
class PsutilTerminator:
    """Real process termination via psutil (imported lazily, like the table)."""

    def terminate(self, pid: int) -> None:
        import psutil

        try:
            psutil.Process(pid).terminate()
        except psutil.NoSuchProcess:
            pass  # already gone — the exit wait confirms
        except psutil.AccessDenied:
            get_panel_logger().warning("terminate_access_denied pid=%s", pid)


def terminate_project_daemon(
    project: ProjectInfo, process_table: object, terminator: PsutilTerminator
) -> List[int]:
    """Terminate every process that passes the identity test *right now*.

    This is the kill-time guard (D-T5, UNIT-L9): the poll-time snapshot is
    deliberately ignored.  A fresh process-table pass decides what belongs to
    *project*; a recycled PID fails :func:`is_daemon_for` and is never touched,
    and an empty match set terminates nothing.  Returns the terminated PIDs.
    """
    entries = process_table.snapshot()  # type: ignore[attr-defined]
    matching = sorted(entry.pid for entry in entries if is_daemon_for(entry, project.root))
    for pid in matching:
        terminator.terminate(pid)
    return matching


def wait_for_exit(
    pids: Sequence[int],
    process_table: object,
    *,
    timeout: float = EXIT_WAIT_TIMEOUT_SECONDS,
    clock: Callable[[], float] = time.monotonic,
    sleep: Callable[[float], None] = time.sleep,
    check_interval: float = CHECK_INTERVAL_SECONDS,
) -> bool:
    """``True`` once none of *pids* appear in the process table; ``False`` on timeout."""
    remaining = set(pids)
    deadline = clock() + timeout
    while True:
        alive = {e.pid for e in process_table.snapshot()} & remaining  # type: ignore[attr-defined]
        if not alive:
            return True
        if clock() >= deadline:
            return False
        sleep(check_interval)


def cleanup_lock(project_root: Path, terminated_pids: Sequence[int]) -> bool:
    """Delete the project's lock only if it still names a PID we terminated.

    The daemon's own ``release_lock()`` never runs under ``TerminateProcess``,
    so the panel cleans up — but with the same self-owned rule ``main.py``
    applies: a lock now holding a *different* PID belongs to a successor and is
    left intact (UNIT-L10/L11); a corrupt lock is likewise never touched here
    (discovery surfaces it as STALE_LOCK instead).
    """
    lock_path = Path(project_root) / LOCK_FILE_NAME
    if not lock_path.is_file():
        return False
    owner_pid, _problem = read_lock_pid(lock_path)
    if owner_pid is None or owner_pid not in set(terminated_pids):
        return False
    try:
        lock_path.unlink()
        return True
    except OSError:
        return False


@dataclass(frozen=True)
class StopOutcome:
    """Result of one drain-then-terminate pass.

    ``performed`` is ``False`` when the kill-time guard matched nothing (daemon
    already gone, or its PID was recycled) — in that case nothing was
    terminated and the row falls back to poll truth.
    """

    performed: bool
    forced: bool = False
    terminated: Tuple[int, ...] = ()
    exited: bool = True
    lock_removed: bool = False
    detail: Optional[str] = None


def drain_and_terminate(
    project: ProjectInfo,
    *,
    idle_threshold: float,
    grace_period: float,
    process_table: object,
    terminator: PsutilTerminator,
    clock: Callable[[], float] = time.monotonic,
    sleep: Callable[[float], None] = time.sleep,
    log_stat: Callable[[Path], Optional[LogStat]] = newest_log_stat,
) -> StopOutcome:
    """The full stop pipeline: drain watch → guarded pair termination → lock cleanup.

    Runs on a worker thread; every collaborator is injected so tests drive the
    whole pipeline with a fake clock (no real 20 s waits, per TE-TSP-045).
    """
    quiescent = watch_quiescence(
        project.log_dir,
        idle_threshold=idle_threshold,
        grace_period=grace_period,
        clock=clock,
        sleep=sleep,
        log_stat=log_stat,
    )
    terminated = terminate_project_daemon(project, process_table, terminator)
    if not terminated:
        return StopOutcome(
            performed=False,
            detail="No process passed the identity test at kill time; nothing terminated.",
        )
    exited = wait_for_exit(terminated, process_table, clock=clock, sleep=sleep)
    lock_removed = cleanup_lock(project.root, terminated) if exited else False
    if not quiescent:
        detail: Optional[
            str
        ] = f"Force-stopped: log activity continued past the {grace_period:.0f} s grace period."
    else:
        detail = None
    return StopOutcome(
        performed=True,
        forced=not quiescent,
        terminated=tuple(terminated),
        exited=exited,
        lock_removed=lock_removed,
        detail=detail,
    )


# --------------------------------------------------------------------------- #
# Shutdown orchestration (window close, AC-7/AC-9)
# --------------------------------------------------------------------------- #
# A shutdown target in one of these statuses is still being drained; anything
# else means the daemon is resolved — gone (STOPPED, or STALE_LOCK when a
# foreign lock was left intact) or surfaced (FORCE_STOPPED).  The shutdown
# dialog's rendering rules count by the same pair.
STILL_DRAINING_STATUSES = frozenset({DaemonStatus.RUNNING, DaemonStatus.DRAINING})

# The AC-9 backstop margin on top of the grace period: covers the exit wait
# (10 s) plus slack.  The watchdog should never fire in practice — every drain
# is already internally bounded.
WATCHDOG_MARGIN_SECONDS = 15.0


class ShutdownOrchestrator:
    """Close-time drain of every managed daemon (TDD §4.4, FDD AC-7/AC-9).

    Tk-free: the app wires *on_complete* to the actual exit and schedules
    :meth:`watchdog_fired` via ``root.after``.  Targets are the rows whose
    effective status is RUNNING (a stop is dispatched for each through the
    normal controller — parallel worker threads in production) or already
    DRAINING (an in-flight stop is *adopted*: the controller's busy guard
    rejects the duplicate dispatch and the existing drain is simply watched).

    Completion is observational, like everything else in the panel: the poller
    keeps running during shutdown, so a clean drain resolves its DRAINING pin
    to STOPPED and this orchestrator — subscribed to the model — sees every
    target leave the still-draining set.  :meth:`watchdog_fired` forces
    completion regardless of worker state, so close can never hang (AC-9).
    """

    def __init__(
        self,
        *,
        model: AppModel,
        controller: "LifecycleController",
        grace_period_seconds: float,
        on_complete: Callable[[], None],
    ):
        self._model = model
        self._controller = controller
        self._grace = grace_period_seconds
        self._on_complete = on_complete
        self._targets: List[str] = []
        self._completed = False

    @property
    def targets(self) -> List[str]:
        """The project ids being drained (fixed at :meth:`begin`)."""
        return list(self._targets)

    @property
    def watchdog_delay_seconds(self) -> float:
        """When the AC-9 backstop should fire, measured from :meth:`begin`."""
        return self._grace + WATCHDOG_MARGIN_SECONDS

    def begin(self) -> bool:
        """Enter shutdown mode and dispatch the drains.

        Returns ``False`` when nothing needs draining — *on_complete* has then
        already been invoked and the caller may exit without showing a dialog.
        """
        self._targets = [
            row.project.project_id
            for row in self._model.rows()
            if row.status in STILL_DRAINING_STATUSES
        ]
        if not self._targets:
            self._finish()
            return False
        self._model.set_shutting_down(True)
        self._model.subscribe(self._check_done)
        for project_id in self._targets:
            # A False return means the row is already draining (busy guard) —
            # the in-flight stop is adopted, not an error.
            self._controller.stop(project_id)
        self._check_done()
        return True

    def watchdog_fired(self) -> None:
        """AC-9 backstop: complete now regardless of worker state."""
        self._finish()

    def _check_done(self) -> None:
        if self._completed:
            return
        for project_id in self._targets:
            row = self._model.snapshot_for(project_id)
            if row is not None and row.status in STILL_DRAINING_STATUSES:
                return
        self._finish()

    def _finish(self) -> None:
        if self._completed:
            return
        self._completed = True
        self._on_complete()


# --------------------------------------------------------------------------- #
# Controller (worker orchestration + model pins)
# --------------------------------------------------------------------------- #
def _one_line(text: str, limit: int = 200) -> str:
    """Collapse *text* to one bounded line for the single-line detail surface."""
    collapsed = " ".join(text.split())
    return collapsed if len(collapsed) <= limit else collapsed[: limit - 1] + "…"


class LifecycleController:
    """Owns start/stop worker threads; all model mutations funnel to the UI thread.

    :meth:`start` and :meth:`stop` are called from UI-thread event handlers, so
    they may pin the model directly; worker completions go through *post* (the
    app's dispatcher queue).  One action per project at a time — a second
    request while one is in flight is rejected (the toolbar disables the
    buttons, this is the backstop against event races).
    """

    def __init__(
        self,
        *,
        model: AppModel,
        post: Callable[[Callable[[], None]], None],
        process_table: object,
        grace_period_seconds: float,
        log_idle_threshold_seconds: float,
        runner: Optional[SubprocessRunner] = None,
        terminator: Optional[PsutilTerminator] = None,
        clock: Callable[[], float] = time.monotonic,
        sleep: Callable[[float], None] = time.sleep,
        log_stat: Callable[[Path], Optional[LogStat]] = newest_log_stat,
        executor: Optional[Callable[[Callable[[], None]], None]] = None,
    ):
        self._model = model
        self._post = post
        self._process_table = process_table
        self._grace = grace_period_seconds
        self._idle = log_idle_threshold_seconds
        self._runner = runner if runner is not None else SubprocessRunner()
        self._terminator = terminator if terminator is not None else PsutilTerminator()
        self._clock = clock
        self._sleep = sleep
        self._log_stat = log_stat
        self._executor = executor
        self._log = get_panel_logger()
        self._busy: set = set()
        self._busy_lock = threading.Lock()

    # ------------------------------------------------------------------ #
    # Actions (UI thread)
    # ------------------------------------------------------------------ #
    def start(self, project_id: str) -> bool:
        """Request a daemon start; ``False`` if unknown or an action is in flight."""
        project = self._project_for(project_id)
        if project is None or not self._claim(project_id):
            return False
        self._model.pin(
            project_id,
            DaemonStatus.STARTING,
            ttl_seconds=LAUNCHER_TIMEOUT_SECONDS + START_PIN_MARGIN_SECONDS,
        )
        self._run_worker(
            f"lw-panel-start-{project_id}", lambda: self._start_worker(project_id, project)
        )
        return True

    def stop(self, project_id: str) -> bool:
        """Request a drain-then-terminate; ``False`` if unknown or already in flight."""
        project = self._project_for(project_id)
        if project is None or not self._claim(project_id):
            return False
        self._model.pin(
            project_id,
            DaemonStatus.DRAINING,
            ttl_seconds=self._grace + DRAIN_PIN_MARGIN_SECONDS,
        )
        self._run_worker(
            f"lw-panel-stop-{project_id}", lambda: self._stop_worker(project_id, project)
        )
        return True

    def is_busy(self, project_id: str) -> bool:
        """Whether an action is currently in flight for *project_id*."""
        with self._busy_lock:
            return project_id in self._busy

    # ------------------------------------------------------------------ #
    # Workers (worker threads; model access only via post)
    # ------------------------------------------------------------------ #
    def _start_worker(self, project_id: str, project: ProjectInfo) -> None:
        try:
            outcome = run_launcher(project, self._runner)
            if outcome.ok:
                # The STARTING pin stays; the poll observing RUNNING resolves it.
                self._log.info("start_requested project=%s launcher_ok", project_id)
            else:
                self._log.warning("start_failed project=%s reason=%r", project_id, outcome.reason)
                reason = outcome.reason or "unknown reason"
                self._post(
                    lambda: self._model.pin(
                        project_id,
                        DaemonStatus.START_FAILED,
                        ttl_seconds=OUTCOME_PIN_TTL_SECONDS,
                        detail=_one_line(f"Start failed: {reason}"),
                    )
                )
        except Exception as exc:  # noqa: BLE001 - worker errors surface, never crash
            self._log.exception("start_worker_failed project=%s", project_id)
            message = _one_line(f"Start failed unexpectedly: {exc}")
            self._post(
                lambda: self._model.pin(
                    project_id,
                    DaemonStatus.START_FAILED,
                    ttl_seconds=OUTCOME_PIN_TTL_SECONDS,
                    detail=message,
                )
            )
        finally:
            self._release(project_id)

    def _stop_worker(self, project_id: str, project: ProjectInfo) -> None:
        try:
            outcome = drain_and_terminate(
                project,
                idle_threshold=self._idle,
                grace_period=self._grace,
                process_table=self._process_table,
                terminator=self._terminator,
                clock=self._clock,
                sleep=self._sleep,
                log_stat=self._log_stat,
            )
            if not outcome.performed:
                # Guard refusal / daemon already gone: release the row to truth.
                self._log.info("stop_noop project=%s: %s", project_id, outcome.detail)
                self._post(lambda: self._model.clear_pin(project_id))
            elif outcome.forced:
                self._log.warning(
                    "daemon_force_stopped project=%s pids=%s lock_removed=%s",
                    project_id,
                    outcome.terminated,
                    outcome.lock_removed,
                )
                self._post(
                    lambda: self._model.pin(
                        project_id,
                        DaemonStatus.FORCE_STOPPED,
                        ttl_seconds=OUTCOME_PIN_TTL_SECONDS,
                        detail=outcome.detail,
                    )
                )
            else:
                # Clean stop: keep the DRAINING pin — the next poll observes the
                # exit and resolves it to STOPPED without a RUNNING flicker.
                self._log.info(
                    "daemon_stopped project=%s pids=%s lock_removed=%s",
                    project_id,
                    outcome.terminated,
                    outcome.lock_removed,
                )
            if outcome.performed and not outcome.exited:
                self._log.warning(
                    "daemon_exit_unconfirmed project=%s pids=%s (still in process table)",
                    project_id,
                    outcome.terminated,
                )
        except Exception:  # noqa: BLE001 - worker errors surface, never crash
            self._log.exception("stop_worker_failed project=%s", project_id)
            self._post(lambda: self._model.clear_pin(project_id))
        finally:
            self._release(project_id)

    # ------------------------------------------------------------------ #
    # Internals
    # ------------------------------------------------------------------ #
    def _project_for(self, project_id: str) -> Optional[ProjectInfo]:
        snapshot = self._model.snapshot_for(project_id)
        return None if snapshot is None else snapshot.project

    def _claim(self, project_id: str) -> bool:
        with self._busy_lock:
            if project_id in self._busy:
                return False
            self._busy.add(project_id)
            return True

    def _release(self, project_id: str) -> None:
        with self._busy_lock:
            self._busy.discard(project_id)

    def _run_worker(self, name: str, fn: Callable[[], None]) -> None:
        if self._executor is not None:
            self._executor(fn)
            return
        threading.Thread(target=fn, name=name, daemon=True).start()
