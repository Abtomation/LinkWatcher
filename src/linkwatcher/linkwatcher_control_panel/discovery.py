"""
Daemon discovery for the LinkWatcher Control Panel — registry + locks + psutil.

Every poll cycle this module rebuilds the panel's picture of reality from three
external surfaces it only ever *reads*: the central ``project-registry.json``,
each project's ``.linkwatcher.lock``, and the OS process table.  It adds no
daemon-side contract (TDD §4.4).

AI Context
----------
- **Three-way identity (D-T5) is the safety invariant.** A process counts as a
  given project's daemon only when its command line contains ``main.py`` *and*
  its ``--project-root`` argument names that project's root.  A lock-file PID
  match alone is never sufficient — PIDs get recycled, and the panel must never
  act on the wrong process.  Everything downstream (Phase C's terminate) re-runs
  this same test at kill time.
- **Path comparison is normalized, not literal.** Observed reality proves this is
  required, not defensive padding: the registry stores
  ``C:\\Users\\...\\LinkWatcher`` while the running daemon's command line carries
  ``c:\\Users\\...\\LinkWatcher`` — a literal substring test (what the launcher's
  ``Test-LinkWatcherAlreadyRunning`` does) misses its own daemon.  We compare the
  *value* of ``--project-root`` after case-folding and separator normalization,
  which also removes a substring false-positive (root ``C:\\proj\\App`` must not
  match a daemon for ``C:\\proj\\AppExtra``).  A daemon whose command line
  carries no ``--project-root`` is unidentifiable and is therefore never claimed.
- **The daemon is a process *pair***: a venv-shim parent plus a base-interpreter
  child with near-identical command lines.  ``pids`` always carries the whole
  pair, resolved by walking parent/child links *within* the matching set.
- **Every input is untrusted.** A missing/garbage lock, an unparseable registry,
  and a vanished project root each degrade into a surfaced state — never an
  exception, never a crashed poll thread.
- **Testability seam**: ``ProcessTable`` is injected.  Unit tests drive a
  scripted fake table (:class:`ProcessEntry` records) and never real processes.
"""

from __future__ import annotations

import json
import re
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, NamedTuple, Optional, Sequence, Set, Tuple

from .model import DaemonSnapshot, DaemonStatus, ProjectInfo
from .panel_log import get_panel_logger

# Written by main.py's acquire_lock() in each project root (feature 0.1.1).
LOCK_FILE_NAME = ".linkwatcher.lock"

# Per-project layout the launcher and validator already assume.
_CONFIG_RELPATH = Path("tools") / "linkwatcher" / "linkwatcher-config.yaml"
_LOG_DIR_RELPATH = Path("logs") / "linkwatcher"

# The daemon entry point, as it appears in the command line.
_ENTRY_SCRIPT = "main.py"
_PROJECT_ROOT_FLAG = "--project-root"

# Fallback extraction for a raw (unsplit) command-line string.
_ROOT_FROM_RAW = re.compile(r'--project-root[=\s]+(?:"([^"]*)"|(\S+))', re.IGNORECASE)


# --------------------------------------------------------------------------- #
# Process table seam
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class ProcessEntry:
    """One OS process, reduced to the fields identity resolution needs."""

    pid: int
    cmdline: Tuple[str, ...]
    create_time: Optional[float] = None
    ppid: Optional[int] = None


class PsutilProcessTable:
    """Real process table, backed by ``psutil`` (imported lazily).

    Processes that vanish or deny access mid-enumeration are skipped rather than
    aborting the pass — a poll must always produce a usable picture.
    """

    def snapshot(self) -> List[ProcessEntry]:
        import psutil

        entries: List[ProcessEntry] = []
        for proc in psutil.process_iter(["pid", "ppid", "cmdline", "create_time"]):
            try:
                info = proc.info
                entries.append(
                    ProcessEntry(
                        pid=info["pid"],
                        cmdline=tuple(info.get("cmdline") or ()),
                        create_time=info.get("create_time"),
                        ppid=info.get("ppid"),
                    )
                )
            except (psutil.NoSuchProcess, psutil.AccessDenied, KeyError, TypeError):
                continue
        return entries


# --------------------------------------------------------------------------- #
# Identity primitives
# --------------------------------------------------------------------------- #
def normalize_path(value) -> str:
    """Case-fold and normalize separators so two spellings of a path compare equal.

    Windows paths differ harmlessly in drive-letter case and separator style;
    treating those as different roots is what breaks literal matching.
    """
    text = str(value).strip().strip('"').replace("/", "\\")
    return text.rstrip("\\").casefold()


def extract_project_root(cmdline: Sequence[str]) -> Optional[str]:
    """Return the raw ``--project-root`` value from *cmdline*, or ``None``.

    Handles the split-argv form (``["--project-root", "C:\\x"]``), the
    ``--project-root=C:\\x`` form, and a single raw command-line string.
    """
    if not cmdline:
        return None

    argv = list(cmdline)
    for index, token in enumerate(argv):
        lowered = token.casefold()
        if lowered == _PROJECT_ROOT_FLAG:
            if index + 1 < len(argv):
                return argv[index + 1].strip('"')
            return None
        if lowered.startswith(_PROJECT_ROOT_FLAG + "="):
            return token.split("=", 1)[1].strip('"')

    # Not split into argv (raw command-line string) — fall back to a regex.
    match = _ROOT_FROM_RAW.search(" ".join(argv))
    if match:
        return (match.group(1) or match.group(2)).strip('"')
    return None


def is_daemon_for(entry: ProcessEntry, project_root) -> bool:
    """Three-way identity test (D-T5): entry is *project_root*'s LinkWatcher daemon.

    Requires the entry point (``main.py``) **and** an explicit ``--project-root``
    naming this project.  Both must agree; either alone is not enough.
    """
    if not entry.cmdline:
        return False
    if not any(_ENTRY_SCRIPT in token.casefold() for token in entry.cmdline):
        return False
    observed_root = extract_project_root(entry.cmdline)
    if observed_root is None:
        return False
    return normalize_path(observed_root) == normalize_path(project_root)


def resolve_pair(anchor_pid: int, entries: Sequence[ProcessEntry], matching: Set[int]) -> List[int]:
    """Expand *anchor_pid* to its full daemon pair/chain.

    Walks parent and child links but never leaves *matching* — so an unrelated
    parent shell, or a second project's daemon, can never be pulled in.
    """
    by_pid = {entry.pid: entry for entry in entries}
    children: Dict[int, List[int]] = {}
    for entry in entries:
        if entry.ppid is not None:
            children.setdefault(entry.ppid, []).append(entry.pid)

    seen = {anchor_pid}
    queue = [anchor_pid]
    while queue:
        pid = queue.pop()
        entry = by_pid.get(pid)
        neighbours: List[int] = list(children.get(pid, []))
        if entry is not None and entry.ppid is not None:
            neighbours.append(entry.ppid)
        for neighbour in neighbours:
            if neighbour in matching and neighbour not in seen:
                seen.add(neighbour)
                queue.append(neighbour)
    return sorted(seen)


def read_lock_pid(lock_path: Path) -> Tuple[Optional[int], Optional[str]]:
    """Read a project's lock file → ``(pid, problem)``; never raises.

    ``problem`` is a human-readable reason when the lock exists but yields no
    usable PID (empty or corrupt), so the row can explain itself.
    """
    try:
        body = lock_path.read_text(encoding="utf-8", errors="replace").strip()
    except OSError as exc:
        return None, f"lock file could not be read ({exc})"
    if not body:
        return None, "lock file holds no PID"
    try:
        return int(body), None
    except ValueError:
        return None, f"lock file content is not a PID ({body[:40]!r})"


# --------------------------------------------------------------------------- #
# Registry
# --------------------------------------------------------------------------- #
class RegistryLoad(NamedTuple):
    """Parsed registry: the projects to supervise, plus any surfaced problem."""

    projects: List[ProjectInfo]
    error: Optional[str] = None


def _project_from_entry(project_id: str, entry: dict) -> Optional[ProjectInfo]:
    path = entry.get("path")
    if not isinstance(path, str) or not path.strip():
        return None
    root = Path(path.strip())
    return ProjectInfo(
        project_id=project_id,
        name=str(entry.get("name") or project_id),
        root=root,
        config_path=root / _CONFIG_RELPATH,
        log_dir=root / _LOG_DIR_RELPATH,
    )


def load_projects(registry_path) -> RegistryLoad:
    """Read every registered project from ``project-registry.json``.

    No filtering: ``version_freeze`` marks a project as excluded from *framework
    rollouts*, which says nothing about whether a LinkWatcher daemon runs there
    (frozen projects demonstrably run one).  Hiding such a row would blind the
    panel to a live daemon — the exact problem it exists to solve.  An empty
    registry is a calm empty state (EC-8), distinct from a load error.
    """
    path = Path(registry_path)
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        return RegistryLoad([], f"Project registry could not be read: {path} ({exc})")

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        return RegistryLoad([], f"Project registry is not valid JSON: {path} (line {exc.lineno})")

    if not isinstance(data, dict) or not isinstance(data.get("projects"), dict):
        return RegistryLoad([], f"Project registry has no 'projects' mapping: {path}")

    projects: List[ProjectInfo] = []
    skipped: List[str] = []
    for project_id, entry in data["projects"].items():
        project = _project_from_entry(str(project_id), entry) if isinstance(entry, dict) else None
        if project is None:
            skipped.append(str(project_id))
            continue
        projects.append(project)

    error = f"Registry entries skipped (no usable path): {', '.join(skipped)}" if skipped else None
    return RegistryLoad(projects, error)


# --------------------------------------------------------------------------- #
# Classification
# --------------------------------------------------------------------------- #
def classify_project(project: ProjectInfo, entries: Sequence[ProcessEntry]) -> DaemonSnapshot:
    """Classify one project's daemon state from the lock file + process table.

    Order of preference — lock-verified pair, then a command-line-identified
    daemon, then the failure states:

    * verified pair alive → RUNNING (uptime = oldest ``create_time`` of the pair)
    * daemon identified by command line while the lock is stale/absent → RUNNING
      with a detail note.  A *live* daemon is never rendered not-running: the
      lock is diagnostic, the process table is truth.
    * lock present but unverifiable (dead PID, recycled PID, corrupt) and no
      daemon found → STALE_LOCK — surfaced, never acted on as live (EC-1/EC-3)
    * nothing at all → STOPPED
    """
    matching = {entry.pid for entry in entries if is_daemon_for(entry, project.root)}
    by_pid = {entry.pid: entry for entry in entries}
    lock_path = project.root / LOCK_FILE_NAME
    lock_exists = lock_path.is_file()
    lock_pid, lock_problem = read_lock_pid(lock_path) if lock_exists else (None, None)

    def running(anchor: int, detail: Optional[str]) -> DaemonSnapshot:
        pids = resolve_pair(anchor, entries, matching)
        times = [by_pid[pid].create_time for pid in pids if by_pid.get(pid) is not None]
        started = min([t for t in times if t is not None], default=None)
        return DaemonSnapshot(project, DaemonStatus.RUNNING, pids, started, detail)

    # 1 — the lock names a process that passes the three-way identity test.
    if lock_pid is not None and lock_pid in matching:
        return running(lock_pid, None)

    # 2 — no verified lock, but the process table shows this project's daemon.
    if matching:
        anchor = min(matching, key=lambda pid: (by_pid[pid].create_time or 0.0, pid))
        if lock_exists:
            detail = (
                f"Lock file is stale ({lock_problem or f'holds PID {lock_pid}'}); "
                "daemon identified by command line."
            )
        else:
            detail = "Running without a lock file (identified by command line)."
        return running(anchor, detail)

    # 3 — a lock with nothing behind it.
    if lock_exists:
        if lock_problem is not None:
            detail = f"Stale lock: {lock_problem}."
        elif lock_pid in by_pid:
            detail = (
                f"Stale lock: PID {lock_pid} is running but is not this project's "
                "LinkWatcher daemon (PID reused)."
            )
        else:
            detail = f"Stale lock: PID {lock_pid} is not running."
        return DaemonSnapshot(project, DaemonStatus.STALE_LOCK, [], None, detail)

    # 4 — nothing running, nothing claimed.
    detail = None
    if not project.root.is_dir():
        detail = f"Project root not found: {project.root}"
    return DaemonSnapshot(project, DaemonStatus.STOPPED, [], None, detail)


# --------------------------------------------------------------------------- #
# Poller
# --------------------------------------------------------------------------- #
class PollResult(NamedTuple):
    """One discovery pass: a snapshot per registered project, plus any error."""

    snapshots: List[DaemonSnapshot]
    error: Optional[str] = None


def poll_once(registry_path, process_table) -> PollResult:
    """Run one full discovery pass; never raises.

    A registry problem yields zero snapshots with the reason attached; an
    unexpected failure is logged and surfaced the same way, so a bad poll costs
    one cycle rather than the poll thread.
    """
    try:
        registry = load_projects(registry_path)
        if not registry.projects:
            return PollResult([], registry.error)
        entries = process_table.snapshot()
        snapshots = [classify_project(project, entries) for project in registry.projects]
        return PollResult(snapshots, registry.error)
    except Exception as exc:  # noqa: BLE001 - a poll failure must not kill the thread
        get_panel_logger().exception("discovery_poll_failed")
        return PollResult([], f"Discovery failed: {exc}")


class DiscoveryPoller:
    """Background thread that runs :func:`poll_once` on a fixed cadence.

    Results are handed to *on_result* on the poller thread; the caller is
    expected to marshal them onto the UI thread (``ControlPanelApp.post``).  The
    thread is a daemon thread and stops promptly — :meth:`stop` interrupts the
    inter-poll wait rather than sleeping it out.
    """

    def __init__(
        self,
        registry_path,
        process_table,
        *,
        interval_seconds: float,
        on_result,
    ):
        self._registry_path = registry_path
        self._process_table = process_table
        self._interval = interval_seconds
        self._on_result = on_result
        self._stop = threading.Event()
        self._thread: Optional[threading.Thread] = None

    def poll_once(self) -> PollResult:
        """Run a single pass (also used directly by tests and manual Refresh)."""
        return poll_once(self._registry_path, self._process_table)

    def start(self) -> None:
        if self._thread is not None:
            return
        self._thread = threading.Thread(target=self._run, name="lw-panel-discovery", daemon=True)
        self._thread.start()

    def stop(self, timeout: Optional[float] = 2.0) -> None:
        self._stop.set()
        if self._thread is not None:
            self._thread.join(timeout=timeout)
            self._thread = None

    def _run(self) -> None:
        while not self._stop.is_set():
            result = self.poll_once()
            try:
                self._on_result(result)
            except Exception:  # noqa: BLE001 - a bad consumer must not kill the poller
                get_panel_logger().exception("discovery_on_result_failed")
            self._stop.wait(self._interval)
