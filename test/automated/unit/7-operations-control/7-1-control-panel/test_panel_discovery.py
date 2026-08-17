"""
Document Metadata:
ID: TE-TST-142
Type: Test File
Category: Test
Version: 1.0
Created: 2026-07-31
Updated: 2026-07-31
Component Name: discovery
Feature Id: 7.1.1
Language: Python
Test Type: Unit
Test Name: panel_discovery

Unit tests for Control Panel daemon discovery
(``linkwatcher.linkwatcher_control_panel.discovery``):

- classification matrix — RUNNING / STALE_LOCK / lockless orphan / STOPPED
  (UNIT-D1…D6, TDD §4.4)
- three-way identity (D-T5) and process-pair resolution (UNIT-D3/D4/D7)
- defensive parsing of untrusted lock files and registry JSON (UNIT-D8…D10)

The three-way identity tests are the highest-value target in this file: a PID
match alone must never make the panel believe it has found a daemon, because
everything Phase C does to a "found" daemon is a termination.
"""

from pathlib import Path

import pytest

from linkwatcher.linkwatcher_control_panel.discovery import (
    ProcessEntry,
    classify_project,
    extract_project_root,
    is_daemon_for,
    load_projects,
    poll_once,
    read_lock_pid,
)
from linkwatcher.linkwatcher_control_panel.model import DaemonStatus, ProjectInfo

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("TE-TSP-045"),
]


# --------------------------------------------------------------------------- #
# UNIT-D1 — RUNNING classification
# --------------------------------------------------------------------------- #
def test_running_when_lock_pid_matches_live_daemon(
    make_project, write_lock, fake_process_table, daemons
):
    """UNIT-D1: lock PID + main.py + project root agree → RUNNING with the pair."""
    project = make_project()
    fake_process_table.set_entries(
        daemons.pair(project.root, parent_pid=2000, child_pid=2001, create_time=500.0)
        + [daemons.unrelated()]
    )
    write_lock(project, 2001)

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.RUNNING
    assert snapshot.pids == [2000, 2001]
    assert snapshot.detail is None


def test_running_uptime_uses_oldest_process_in_pair(
    make_project, write_lock, fake_process_table, daemons
):
    """UNIT-D1: uptime anchors on the *oldest* create_time of the pair, not the lock's PID."""
    project = make_project()
    fake_process_table.set_entries(
        daemons.pair(project.root, parent_pid=2000, child_pid=2001, create_time=500.0)
    )
    write_lock(project, 2001)  # the child, which started later

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.started_at == 500.0


def test_running_when_project_root_case_differs(
    make_project, write_lock, fake_process_table, daemons
):
    """UNIT-D1 (regression): drive-letter/separator case must not hide a live daemon.

    Observed in production: the registry stores ``C:\\...`` while the running
    daemon's command line carries ``c:\\...``.  A literal substring comparison
    (what the launcher does) classifies LinkWatcher's own daemon as not-running,
    which would then refuse to stop it.
    """
    project = make_project()
    shouty_root = str(project.root).replace("\\", "/").upper()
    fake_process_table.set_entries([daemons.entry(3000, shouty_root, create_time=10.0)])
    write_lock(project, 3000)

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.RUNNING
    assert snapshot.pids == [3000]


# --------------------------------------------------------------------------- #
# UNIT-D2/D3 — STALE_LOCK
# --------------------------------------------------------------------------- #
def test_stale_lock_when_pid_not_running(make_project, write_lock, fake_process_table, daemons):
    """UNIT-D2: lock exists, PID absent from the process table → STALE_LOCK (EC-1/EC-3)."""
    project = make_project()
    fake_process_table.set_entries([daemons.unrelated()])
    write_lock(project, 9999)

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.STALE_LOCK
    assert snapshot.pids == []  # nothing to act on
    assert "9999" in snapshot.detail


def test_stale_lock_when_pid_recycled(make_project, write_lock, fake_process_table, daemons):
    """UNIT-D3: lock PID is alive but is not a daemon → STALE_LOCK (KR-03).

    The security-adjacent core: a PID match alone must never be accepted, or a
    recycled PID becomes a termination target.
    """
    project = make_project()
    fake_process_table.set_entries([daemons.unrelated(pid=4242)])
    write_lock(project, 4242)

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.STALE_LOCK
    assert snapshot.pids == []
    assert "reused" in snapshot.detail


# --------------------------------------------------------------------------- #
# UNIT-D4 — Wrong project root
# --------------------------------------------------------------------------- #
def test_daemon_for_a_different_root_is_not_claimed(
    make_project, write_lock, fake_process_table, daemons
):
    """UNIT-D4: a live main.py daemon bound to another root is not this project's."""
    project = make_project("PRJ-001", "alpha")
    other = make_project("PRJ-002", "beta")
    fake_process_table.set_entries(daemons.pair(other.root, parent_pid=5000, child_pid=5001))
    write_lock(project, 5000)

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.STALE_LOCK
    assert snapshot.pids == []


def test_root_prefix_does_not_match_a_longer_sibling_root(
    make_project, fake_process_table, daemons
):
    """UNIT-D4 (guard): root ``…/app`` must not match a daemon for ``…/app-extra``.

    A bare substring test would claim the sibling's daemon — and Phase C would
    then terminate the wrong project's processes.
    """
    project = make_project("PRJ-001", "app")
    fake_process_table.set_entries([daemons.entry(6000, str(project.root) + "-extra")])

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.STOPPED
    assert snapshot.pids == []


def test_process_without_project_root_argument_is_never_claimed(
    make_project, fake_process_table, daemons
):
    """UNIT-D4 (guard): main.py with no --project-root is unidentifiable → not claimed.

    ``--project-root`` defaults to the working directory, which is not visible in
    the command line, so such a process cannot be attributed to a project.
    Refusing to claim it is the conservative choice: never terminate what cannot
    be identified.
    """
    project = make_project()
    fake_process_table.set_entries(
        [ProcessEntry(pid=7000, cmdline=(daemons.VENV_PYTHON, daemons.MAIN_PY), create_time=1.0)]
    )

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.STOPPED


# --------------------------------------------------------------------------- #
# UNIT-D5 — Lockless orphan
# --------------------------------------------------------------------------- #
def test_lockless_orphan_is_running_with_detail(make_project, fake_process_table, daemons):
    """UNIT-D5: no lock, but the command-line scan finds the daemon → RUNNING + note."""
    project = make_project()
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=8000, child_pid=8001))

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.RUNNING
    assert snapshot.pids == [8000, 8001]
    assert "without a lock file" in snapshot.detail


def test_live_daemon_outranks_a_stale_lock(make_project, write_lock, fake_process_table, daemons):
    """A stale lock alongside a *live* daemon still renders RUNNING.

    The lock is diagnostic; the process table is truth.  Rendering a running
    daemon as not-running would leave it unstoppable from its own supervisor —
    so the stale lock is surfaced in the detail note instead of hiding the row.
    """
    project = make_project()
    fake_process_table.set_entries(daemons.pair(project.root, parent_pid=8100, child_pid=8101))
    write_lock(project, 9999)  # stale: PID not running

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.RUNNING
    assert snapshot.pids == [8100, 8101]
    assert "stale" in snapshot.detail.lower()


# --------------------------------------------------------------------------- #
# UNIT-D6 — STOPPED
# --------------------------------------------------------------------------- #
def test_stopped_when_no_lock_and_no_process(make_project, fake_process_table, daemons):
    """UNIT-D6: nothing claimed, nothing running → STOPPED, no noise."""
    project = make_project()
    fake_process_table.set_entries([daemons.unrelated()])

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.STOPPED
    assert snapshot.pids == []
    assert snapshot.detail is None


def test_missing_project_root_is_stopped_with_detail(tmp_path, fake_process_table):
    """A registered project whose root no longer exists → STOPPED with an explanation.

    Not in the TDD's four-way matrix; classified as STOPPED (rather than a new
    status) so the row stays visible and explains itself instead of silently
    disappearing from the registry listing.
    """
    root = tmp_path / "gone"
    project = ProjectInfo(
        project_id="PRJ-404",
        name="gone",
        root=root,
        config_path=root / "tools" / "linkwatcher" / "linkwatcher-config.yaml",
        log_dir=root / "logs" / "linkwatcher",
    )

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.STOPPED
    assert "not found" in snapshot.detail


# --------------------------------------------------------------------------- #
# UNIT-D7 — Pair resolution
# --------------------------------------------------------------------------- #
def test_pair_resolution_collects_parent_and_child(
    make_project, write_lock, fake_process_table, daemons
):
    """UNIT-D7: the verified process plus its matching parent/child form the pair."""
    project = make_project()
    fake_process_table.set_entries(
        daemons.pair(project.root, parent_pid=9000, child_pid=9001) + [daemons.unrelated(pid=9002)]
    )
    write_lock(project, 9000)  # anchored on the parent

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.pids == [9000, 9001]


def test_pair_resolution_excludes_non_matching_parent(
    make_project, write_lock, fake_process_table, daemons
):
    """UNIT-D7 (guard): a non-daemon parent (e.g. the launching shell) is excluded.

    Pair expansion walks process links but never leaves the verified-match set,
    so the terminate target can never widen to an unrelated process.
    """
    project = make_project()
    fake_process_table.set_entries(
        [
            daemons.unrelated(pid=9100),
            daemons.entry(9101, project.root, python=daemons.BASE_PYTHON, ppid=9100),
        ]
    )
    write_lock(project, 9101)

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.pids == [9101]


# --------------------------------------------------------------------------- #
# UNIT-D8 — Malformed lock
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize("content", ["", "   ", "not-a-pid", "12x34"])
def test_malformed_lock_is_stale_not_an_exception(
    make_project, write_lock, fake_process_table, content
):
    """UNIT-D8: garbage lock content → defensive STALE_LOCK with a reason, no raise."""
    project = make_project()
    write_lock(project, content)

    snapshot = classify_project(project, fake_process_table.snapshot())

    assert snapshot.status is DaemonStatus.STALE_LOCK
    assert snapshot.detail


def test_read_lock_pid_reports_problem_for_corrupt_content(tmp_path):
    """UNIT-D8: the lock reader returns (None, reason) rather than raising."""
    lock = tmp_path / ".linkwatcher.lock"
    lock.write_text("garbage", encoding="utf-8")

    pid, problem = read_lock_pid(lock)

    assert pid is None
    assert problem


# --------------------------------------------------------------------------- #
# UNIT-D9/D10 — Registry
# --------------------------------------------------------------------------- #
def test_malformed_registry_surfaces_error(write_registry, fake_process_table):
    """UNIT-D9: unparseable registry JSON → surfaced error, zero snapshots, no crash."""
    result = poll_once(write_registry(raw="{ not json"), fake_process_table)

    assert result.snapshots == []
    assert "not valid JSON" in result.error


def test_missing_registry_file_surfaces_error(tmp_path, fake_process_table):
    """UNIT-D9: a configured-but-absent registry explains itself (not a silent empty)."""
    result = poll_once(tmp_path / "nope.json", fake_process_table)

    assert result.snapshots == []
    assert "could not be read" in result.error


def test_registry_without_projects_mapping_surfaces_error(write_registry, fake_process_table):
    """UNIT-D9: valid JSON of the wrong shape is an error, not an empty registry."""
    result = poll_once(write_registry(raw='{"metadata": {}}'), fake_process_table)

    assert result.snapshots == []
    assert "projects" in result.error


def test_empty_registry_is_calm_not_an_error(write_registry, fake_process_table):
    """UNIT-D10: zero registered projects → empty snapshot set, no error (EC-8)."""
    result = poll_once(write_registry([]), fake_process_table)

    assert result.snapshots == []
    assert result.error is None


def test_registry_lists_every_project_including_frozen(tmp_path):
    """Frozen projects are listed: ``version_freeze`` governs framework rollouts, not daemons.

    Filtering on it would hide a genuinely running daemon from its only
    supervisor (frozen projects demonstrably run one).
    """
    registry = tmp_path / "project-registry.json"
    registry.write_text(
        '{"projects": {'
        '"PRJ-000": {"name": "appdev", "path": "C:\\\\x\\\\appdev", "version_freeze": true},'
        '"PRJ-001": {"name": "app", "path": "C:\\\\x\\\\app", "version_freeze": false}}}',
        encoding="utf-8",
    )

    loaded = load_projects(registry)

    assert [p.project_id for p in loaded.projects] == ["PRJ-000", "PRJ-001"]
    assert loaded.error is None


def test_registry_entry_without_path_is_skipped_and_reported(tmp_path):
    """A malformed entry is skipped and named — the rest of the registry still loads."""
    registry = tmp_path / "project-registry.json"
    registry.write_text(
        '{"projects": {"PRJ-001": {"name": "ok", "path": "C:\\\\x\\\\ok"}, '
        '"PRJ-BAD": {"name": "broken"}}}',
        encoding="utf-8",
    )

    loaded = load_projects(registry)

    assert [p.project_id for p in loaded.projects] == ["PRJ-001"]
    assert "PRJ-BAD" in loaded.error


def test_derived_project_paths_follow_the_standard_layout(tmp_path):
    """Config and log-dir paths are derived from the root the launcher/validator assume."""
    registry = tmp_path / "project-registry.json"
    registry.write_text(
        '{"projects": {"PRJ-001": {"name": "app", "path": "C:\\\\x\\\\app"}}}', encoding="utf-8"
    )

    project = load_projects(registry).projects[0]

    assert project.config_path == Path(r"C:\x\app\tools\linkwatcher\linkwatcher-config.yaml")
    assert project.log_dir == Path(r"C:\x\app\logs\linkwatcher")


# --------------------------------------------------------------------------- #
# Identity primitives
# --------------------------------------------------------------------------- #
@pytest.mark.parametrize(
    "argv,expected",
    [
        (["py", "main.py", "--project-root", r"C:\a\b"], r"C:\a\b"),
        (["py", "main.py", r"--project-root=C:\a\b"], r"C:\a\b"),
        (["py", "main.py", "--project-root", r'"C:\a\b"'], r"C:\a\b"),
        ([r'py main.py --project-root "C:\a b\c"'], r"C:\a b\c"),  # raw, unsplit command line
        (["py", "main.py"], None),
        (["py", "main.py", "--project-root"], None),  # flag with no value
        ([], None),  # no command line at all (psutil may report an empty cmdline)
    ],
)
def test_extract_project_root_handles_every_argument_form(argv, expected):
    """Root extraction covers split argv, ``=``-joined, quoted, and raw command lines."""
    assert extract_project_root(argv) == expected


def test_is_daemon_for_requires_both_entry_script_and_root(daemons):
    """Three-way identity: neither main.py alone nor the root alone is sufficient."""
    root = r"C:\a\b"
    entry_ok = daemons.entry(1, root)
    no_main = ProcessEntry(
        pid=2, cmdline=(daemons.VENV_PYTHON, "other.py", "--project-root", root), create_time=1.0
    )
    wrong_root = daemons.entry(3, r"C:\somewhere\else")
    no_cmdline = ProcessEntry(pid=4, cmdline=(), create_time=1.0)

    assert is_daemon_for(entry_ok, root)
    assert not is_daemon_for(no_main, root)
    assert not is_daemon_for(wrong_root, root)
    # A process whose command line psutil could not read is unidentifiable, so it
    # can never be claimed — the same conservative rule as a missing --project-root.
    assert not is_daemon_for(no_cmdline, root)
