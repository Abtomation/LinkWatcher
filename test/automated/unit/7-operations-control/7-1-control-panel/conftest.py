"""
Shared fixtures for the LinkWatcher Control Panel test suite (feature 7.1.1).

The **fake process table** below is the foundation seam the test spec
(TE-TSP-045 § "Dependencies Between Tests") requires before any discovery,
lifecycle, or integration test: unit tests must never spawn or inspect real
daemon processes.  Everything else here builds the real temp-file surfaces the
panel reads — lock files, the central registry, per-project directories — so the
code under test exercises genuine filesystem behavior.

Fixtures
--------
- ``daemons``            — factory for realistic daemon process entries
- ``fake_process_table`` — scriptable stand-in for ``PsutilProcessTable``
- ``fake_clock``         — injectable monotonic clock (no real waiting)
- ``make_project``       — build a :class:`ProjectInfo` backed by real temp dirs
- ``write_lock``         — write a project's ``.linkwatcher.lock``
- ``write_registry``     — write a central ``project-registry.json``
- ``write_launcher``     — drop a stub launcher script into a project (Phase C)
- ``fake_runner``        — scriptable launcher invocations (Phase C)
- ``fake_terminator``    — records terminations, removes PIDs from the table (Phase C)
- ``fake_log_stat``      — controllable log-stat source driving the drain heuristic (Phase C)

Helpers are reached through fixtures rather than imported from this module: the
feature test directories are not Python packages, so a ``from .conftest import``
would depend on pytest's sys.path insertion.

Command lines produced by ``daemons.argv()`` mirror what the launcher really
spawns (observed from a live daemon): a venv-shim parent and a base-interpreter
child sharing near-identical arguments, with the project root passed via
``--project-root``.
"""

import json
from pathlib import Path
from typing import Iterable, List, Optional, Sequence

import pytest

from linkwatcher.linkwatcher_control_panel.discovery import LOCK_FILE_NAME, ProcessEntry
from linkwatcher.linkwatcher_control_panel.lifecycle import LogStat, RunResult
from linkwatcher.linkwatcher_control_panel.model import ProjectInfo


class DaemonFactory:
    """Builds process-table entries that look like real LinkWatcher daemons."""

    # Stand-ins for the deployed install paths seen in a real daemon cmdline.
    VENV_PYTHON = r"C:\Users\tester\bin\.linkwatcher-venv\Scripts\python.exe"
    BASE_PYTHON = r"C:\Users\tester\AppData\Local\Programs\Python\python.exe"
    MAIN_PY = r"C:\Users\tester\bin\main.py"

    def argv(self, project_root, python: Optional[str] = None) -> List[str]:
        """The argv list the launcher gives a daemon for *project_root*."""
        root = str(project_root)
        return [
            python or self.VENV_PYTHON,
            self.MAIN_PY,
            "--project-root",
            root,
            "--log-file",
            str(Path(root) / "logs" / "linkwatcher" / "LinkWatcherLog.txt"),
        ]

    def entry(
        self,
        pid: int,
        project_root,
        *,
        python: Optional[str] = None,
        create_time: float = 100.0,
        ppid: Optional[int] = 1,
    ) -> ProcessEntry:
        """A single daemon process bound to *project_root*."""
        return ProcessEntry(
            pid=pid,
            cmdline=tuple(self.argv(project_root, python)),
            create_time=create_time,
            ppid=ppid,
        )

    def pair(
        self,
        project_root,
        *,
        parent_pid: int = 1000,
        child_pid: int = 1001,
        create_time: float = 100.0,
    ) -> List[ProcessEntry]:
        """A realistic two-process daemon: venv-shim parent + interpreter child.

        The child starts marginally later than the parent, so tests can assert
        that uptime is taken from the *oldest* member of the pair.
        """
        return [
            self.entry(parent_pid, project_root, python=self.VENV_PYTHON, create_time=create_time),
            self.entry(
                child_pid,
                project_root,
                python=self.BASE_PYTHON,
                create_time=create_time + 0.5,
                ppid=parent_pid,
            ),
        ]

    def unrelated(self, pid: int = 4242, ppid: int = 1) -> ProcessEntry:
        """A process that is emphatically not a LinkWatcher daemon."""
        return ProcessEntry(
            pid=pid, cmdline=(r"C:\Windows\System32\notepad.exe",), create_time=50.0, ppid=ppid
        )


class FakeProcessTable:
    """Scriptable process table implementing the ``snapshot()`` seam.

    Tests mutate the table between polls to simulate daemons appearing and
    disappearing — the external-change convergence the panel must track.
    """

    def __init__(self, entries: Iterable[ProcessEntry] = ()):
        self.entries: List[ProcessEntry] = list(entries)
        self.snapshot_calls = 0

    def snapshot(self) -> List[ProcessEntry]:
        self.snapshot_calls += 1
        return list(self.entries)

    def set_entries(self, entries: Iterable[ProcessEntry]) -> None:
        self.entries = list(entries)

    def add(self, entries: Iterable[ProcessEntry]) -> None:
        self.entries.extend(entries)

    def remove(self, *pids: int) -> None:
        self.entries = [entry for entry in self.entries if entry.pid not in pids]


class FakeClock:
    """Monotonic clock under test control — advanced explicitly, never slept."""

    def __init__(self, start: float = 0.0):
        self.now = start

    def __call__(self) -> float:
        return self.now

    def advance(self, seconds: float) -> float:
        self.now += seconds
        return self.now


class FakeRunner:
    """Scriptable launcher invocations implementing the ``run()`` seam.

    Defaults to the launcher's success output.  ``script(*results)`` replaces
    the responses: they are consumed in order, the last one repeating.  Every
    invocation is recorded in ``calls`` as ``(args, timeout)``.
    """

    def __init__(self):
        self.results: List[RunResult] = []
        self.calls: List[tuple] = []

    def script(self, *results: RunResult) -> "FakeRunner":
        self.results = list(results)
        return self

    def run(self, args: Sequence[str], timeout: float) -> RunResult:
        self.calls.append((list(args), float(timeout)))
        if not self.results:
            return RunResult(0, "LinkWatcher started successfully in background (PID: 4321)", "")
        if len(self.results) == 1:
            return self.results[0]
        return self.results.pop(0)


class FakeTerminator:
    """Records terminations; a linked table has the PID removed (process 'dies')."""

    def __init__(self, table: Optional[FakeProcessTable] = None):
        self.terminated: List[int] = []
        self.table = table

    def terminate(self, pid: int) -> None:
        self.terminated.append(pid)
        if self.table is not None:
            self.table.remove(pid)


class FakeLogStat:
    """Controllable stand-in for ``newest_log_stat`` driving the drain heuristic.

    ``current`` is what the next call returns; tests (typically from an injected
    ``sleep`` callback) call :meth:`touch` to simulate log activity or set
    ``current = None`` to simulate a missing log.
    """

    def __init__(self, current: Optional[LogStat] = None):
        self.current: Optional[LogStat] = (
            current
            if current is not None
            else LogStat(Path("LinkWatcherLog.txt"), size=100, mtime=1.0)
        )
        self.calls = 0

    def __call__(self, _log_dir) -> Optional[LogStat]:
        self.calls += 1
        return self.current

    def touch(self) -> None:
        """Simulate log activity: the newest log grew."""
        if self.current is not None:
            self.current = LogStat(
                self.current.path, self.current.size + 10, self.current.mtime + 0.1
            )


@pytest.fixture
def daemons():
    """Factory for daemon process entries (see :class:`DaemonFactory`)."""
    return DaemonFactory()


@pytest.fixture
def fake_process_table():
    """An empty scriptable process table (see :class:`FakeProcessTable`)."""
    return FakeProcessTable()


@pytest.fixture
def fake_clock():
    """An injectable clock starting at 0.0 (see :class:`FakeClock`)."""
    return FakeClock()


@pytest.fixture
def make_project(tmp_path):
    """Factory: a :class:`ProjectInfo` whose root really exists on disk."""

    def _make(project_id: str = "PRJ-001", name: Optional[str] = None) -> ProjectInfo:
        root = tmp_path / (name or project_id)
        (root / "logs" / "linkwatcher").mkdir(parents=True, exist_ok=True)
        (root / "tools" / "linkwatcher").mkdir(parents=True, exist_ok=True)
        return ProjectInfo(
            project_id=project_id,
            name=name or project_id,
            root=root,
            config_path=root / "tools" / "linkwatcher" / "linkwatcher-config.yaml",
            log_dir=root / "logs" / "linkwatcher",
        )

    return _make


@pytest.fixture
def write_lock():
    """Factory: write a project's ``.linkwatcher.lock`` with arbitrary content."""

    def _write(project: ProjectInfo, content) -> Path:
        lock = project.root / LOCK_FILE_NAME
        lock.write_text(str(content), encoding="utf-8")
        return lock

    return _write


@pytest.fixture
def write_launcher():
    """Factory: drop a stub launcher script into a project (never executed)."""

    def _write(project: ProjectInfo) -> Path:
        script = (
            project.root
            / "process-framework"
            / "tools"
            / "linkWatcher"
            / "start_linkwatcher_background.ps1"
        )
        script.parent.mkdir(parents=True, exist_ok=True)
        script.write_text("# test stub - never executed", encoding="utf-8")
        return script

    return _write


@pytest.fixture
def fake_runner():
    """A scriptable launcher runner, defaulting to success (see :class:`FakeRunner`)."""
    return FakeRunner()


@pytest.fixture
def fake_terminator(fake_process_table):
    """A recording terminator linked to ``fake_process_table`` (see :class:`FakeTerminator`)."""
    return FakeTerminator(fake_process_table)


@pytest.fixture
def fake_log_stat():
    """A controllable log-stat source (see :class:`FakeLogStat`)."""
    return FakeLogStat()


@pytest.fixture
def write_registry(tmp_path):
    """Factory: write a central ``project-registry.json`` listing *projects*.

    Pass ``raw=`` to write arbitrary (including malformed) content instead.
    """

    def _write(projects: Sequence[ProjectInfo] = (), *, raw: Optional[str] = None) -> Path:
        registry = tmp_path / "project-registry.json"
        if raw is not None:
            registry.write_text(raw, encoding="utf-8")
            return registry
        payload = {
            "projects": {
                p.project_id: {"name": p.name, "path": str(p.root), "version_freeze": False}
                for p in projects
            }
        }
        registry.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        return registry

    return _write
