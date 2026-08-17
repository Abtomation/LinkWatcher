"""
Document Metadata:
ID: TE-TST-148
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-10
Updated: 2026-08-10
Component Name: log_tail
Feature Id: 7.1.1
Language: Python
Test Name: panel_log_tail
Test Type: Unit

Unit tests for the Control Panel log tail
(``linkwatcher.linkwatcher_control_panel.log_tail``):

- UNIT-T1 — initial attach seeks to ``max(0, size − 64 KB)``; only the tail
  window is rendered, starting on a line boundary
- UNIT-T2 — polls read appended bytes only (byte offset tracked; partial lines
  assemble across polls)
- UNIT-T3 — rotation/truncation reattaches to the newest ``LinkWatcherLog*.txt``
  (EC-5)
- UNIT-T4 — display buffer bounded, trimmed from the top
- UNIT-T5 — missing log is a calm placeholder state, never an exception; a log
  appearing later is attached automatically

All tests run against real temp files — genuine filesystem behavior, per the
test spec's mock table (TE-TSP-045).
"""

import os
import time
from pathlib import Path

import pytest

from linkwatcher.linkwatcher_control_panel.log_tail import (
    INITIAL_WINDOW_BYTES,
    MAX_BUFFER_LINES,
    LogTail,
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
@pytest.fixture
def log_dir(tmp_path):
    directory = tmp_path / "logs" / "linkwatcher"
    directory.mkdir(parents=True)
    return directory


def write_log(log_dir: Path, text: str, name: str = "LinkWatcherLog.txt") -> Path:
    path = log_dir / name
    path.write_text(text, encoding="utf-8")
    return path


def append_log(path: Path, text: str) -> None:
    with open(path, "a", encoding="utf-8", newline="") as handle:
        handle.write(text)


# --------------------------------------------------------------------------- #
# UNIT-T1 — initial tail window
# --------------------------------------------------------------------------- #
def test_initial_attach_loads_only_the_tail_window(log_dir):
    """A large log opens instantly: only the last 64 KB are read (UNIT-T1)."""
    head = "HEAD-MARKER unique first line\n"
    body = "".join(f"line {i:08d}\n" for i in range(10_000))  # ~140 KB
    write_log(log_dir, head + body)

    tail = LogTail(log_dir)
    update = tail.attach()

    assert update.has_log and update.reattached
    assert "HEAD-MARKER" not in tail.text()
    assert tail.lines()[-1] == "line 00009999"
    # The window opens on a line boundary — no partial first line rendered.
    assert tail.lines()[0].startswith("line ")
    assert len(tail.lines()) <= MAX_BUFFER_LINES


def test_small_log_loads_in_full(log_dir):
    write_log(log_dir, "one\ntwo\n")
    tail = LogTail(log_dir)
    tail.attach()
    assert tail.lines() == ["one", "two"]


# --------------------------------------------------------------------------- #
# UNIT-T2 — incremental reads
# --------------------------------------------------------------------------- #
def test_poll_reads_appended_bytes_only(log_dir):
    """A tick returns exactly the appended text — never a re-read (UNIT-T2)."""
    path = write_log(log_dir, "one\ntwo\n")
    tail = LogTail(log_dir)
    tail.attach()

    append_log(path, "three\n")
    update = tail.poll()

    assert update.appended == "three\n"
    assert not update.reattached
    assert tail.lines() == ["one", "two", "three"]

    # Nothing new → an empty, non-reattaching update.
    idle = tail.poll()
    assert idle.appended == "" and not idle.reattached and idle.has_log


def test_partial_lines_assemble_across_polls(log_dir):
    path = write_log(log_dir, "start\n")
    tail = LogTail(log_dir)
    tail.attach()

    append_log(path, "par")
    tail.poll()
    assert tail.lines() == ["start", "par"]  # trailing partial shown

    append_log(path, "tial\n")
    tail.poll()
    assert tail.lines() == ["start", "partial"]


def test_per_poll_read_is_capped(log_dir):
    """A log burst is absorbed over several ticks, each bounded (UI-thread guard)."""
    path = write_log(log_dir, "")
    tail = LogTail(log_dir, read_limit=8)
    tail.attach()

    append_log(path, "abcdefghijklmnop")  # 16 bytes, cap is 8
    first = tail.poll()
    assert first.appended == "abcdefgh"
    second = tail.poll()
    assert second.appended == "ijklmnop"


# --------------------------------------------------------------------------- #
# UNIT-T3 — rotation / truncation reattach (EC-5)
# --------------------------------------------------------------------------- #
def test_rotation_reattaches_to_newest_log(log_dir):
    """Active log renamed away and restarted smaller → reattach from the start."""
    path = write_log(log_dir, "old content, longer than the fresh file\n")
    tail = LogTail(log_dir)
    tail.attach()

    path.rename(log_dir / "LinkWatcherLog_20260810_120000.txt")
    write_log(log_dir, "fresh\n")  # same active name, smaller size

    update = tail.poll()
    assert update.reattached
    assert tail.lines() == ["fresh"]
    assert tail.path is not None and tail.path.name == "LinkWatcherLog.txt"


def test_truncation_reattaches(log_dir):
    path = write_log(log_dir, "a long first incarnation of the log file\n")
    tail = LogTail(log_dir)
    tail.attach()

    path.write_text("reset\n", encoding="utf-8")  # size shrank in place

    update = tail.poll()
    assert update.reattached
    assert tail.lines() == ["reset"]


def test_newer_sibling_takes_over_when_current_goes_quiet(log_dir):
    """Writer moved to a newer file while the old one still exists → follow it."""
    old = write_log(log_dir, "old\n")
    tail = LogTail(log_dir)
    tail.attach()

    newer = write_log(log_dir, "newer\n", name="LinkWatcherLog_20260810_130000.txt")
    # Force an unambiguous mtime ordering (filesystem timestamps can tie).
    past = time.time() - 60
    os.utime(old, (past, past))

    update = tail.poll()
    assert update.reattached
    assert tail.path == newer
    assert tail.lines() == ["newer"]


# --------------------------------------------------------------------------- #
# UNIT-T4 — bounded buffer
# --------------------------------------------------------------------------- #
def test_buffer_capped_and_trimmed_from_top(log_dir):
    path = write_log(log_dir, "".join(f"l{i}\n" for i in range(50)))
    tail = LogTail(log_dir, max_lines=10)
    tail.attach()

    assert len(tail.lines()) == 10
    assert tail.lines() == [f"l{i}" for i in range(40, 50)]

    append_log(path, "l50\nl51\n")
    tail.poll()
    assert len(tail.lines()) == 10
    assert tail.lines()[0] == "l42"  # trimmed from the top
    assert tail.lines()[-1] == "l51"


def test_default_buffer_cap_matches_the_tdd():
    assert MAX_BUFFER_LINES == 1000
    assert INITIAL_WINDOW_BYTES == 64 * 1024


# --------------------------------------------------------------------------- #
# UNIT-T5 — missing log is calm
# --------------------------------------------------------------------------- #
def test_missing_log_is_a_placeholder_state(log_dir):
    tail = LogTail(log_dir)
    update = tail.attach()
    assert not update.has_log
    assert not tail.has_log
    assert tail.text() == ""

    # Still calm on subsequent polls.
    idle = tail.poll()
    assert not idle.has_log and not idle.reattached


def test_log_appearing_later_is_attached_automatically(log_dir):
    tail = LogTail(log_dir)
    tail.attach()

    write_log(log_dir, "born\n")
    update = tail.poll()

    assert update.has_log and update.reattached
    assert tail.lines() == ["born"]


def test_nonexistent_directory_is_calm(tmp_path):
    tail = LogTail(tmp_path / "never" / "created")
    update = tail.attach()
    assert not update.has_log
    assert tail.poll().has_log is False
