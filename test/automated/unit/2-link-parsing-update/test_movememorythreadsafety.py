"""
Document Metadata:
ID: TE-TST-152
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-17
Updated: 2026-08-17
Component Name: ReferenceLookup
Feature Id: 2.2.1
Language: Python
Test Name: MoveMemoryThreadSafety
Test Type: Unit
"""

# MoveMemoryThreadSafety Unit Test — PD-BUG-119 regression tests
#
# Covers the unsynchronized-shared-state defect in ReferenceLookup's move
# memory. The PD-BUG-114 fix added the first cross-event mutable state on this
# class — _recent_moves and _pending_recalcs — as plain dicts, mutated from two
# threads with no lock:
#
#   * the watchdog observer thread, via handler._handle_file_moved
#     (record_move, apply_pending_recalcs, and the _lookup_recent_move /
#     _register_pending_recalc calls reached from _calculate_updated_relative_path)
#   * the DirectoryMoveDetector worker thread, started as a daemon thread in
#     dir_move_detector._trigger_processing, via handler._handle_directory_moved
#
# handler.on_moved has no serializing lock, so the two run concurrently
# whenever a single-file move lands while a directory-move settle window is
# still open — the bulk-restructuring scenario PD-BUG-114 targets.
#
# The interleavings are driven DETERMINISTICALLY rather than by racing: each
# test hooks a callable the production code already invokes inside the
# vulnerable window (a timestamp comparison in _prune_move_memory; the
# time.monotonic() call between setdefault and the store in
# _register_pending_recalc), so the competing thread runs at exactly the
# instruction that matters, inside the real code path.
#
# Test File ID: TE-TST-152
# Created: 2026-08-17

import shutil
import sys
import tempfile
import threading
import time
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from linkwatcher.reference_lookup import ReferenceLookup

pytestmark = [
    pytest.mark.feature("2.2.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification("test/specifications/feature-specs/test-spec-2-2-1-link-updating.md"),
]

# How long the main thread lets the competing thread run inside the window.
# Without the fix the competing mutation is a dict write and lands in
# microseconds; with the fix it blocks on the lock for the whole grace period.
# Bounded so a correct implementation costs a fraction of a second per test.
_GRACE_SECONDS = 0.25
_JOIN_TIMEOUT = 5.0


class _HookedTimestamp(float):
    """A move-memory timestamp that runs a hook the first time it is compared.

    _prune_move_memory evaluates ``ts < cutoff`` for every entry inside a list
    comprehension. Seeding one entry with this class lets a test release a
    competing thread at exactly that point — inside the real iteration, with
    entries still to come — instead of hoping a stress loop lands there.
    """

    def __new__(cls, value, hook):
        obj = float.__new__(cls, value)
        obj._hook = hook
        obj._fired = False
        return obj

    def __lt__(self, other):
        if not self._fired:
            self._fired = True
            self._hook()
        return float.__lt__(self, other)


def _run_competing(target):
    """Run target on another thread; return once it has started and had its grace.

    Returns the thread so the caller can join it after leaving the window.
    Never requires completion: under the fix the competing call blocks on the
    lock until the window closes, which is the behavior being verified.
    """
    started = threading.Event()
    errors = []

    def _worker():
        started.set()
        try:
            target()
        except Exception as exc:  # recorded, not raised — this is the other thread
            errors.append(exc)

    thread = threading.Thread(target=_worker, daemon=True)
    thread.start()
    started.wait(_JOIN_TIMEOUT)
    thread.join(_GRACE_SECONDS)
    thread.errors = errors
    return thread


@pytest.fixture
def temp_dir():
    d = tempfile.mkdtemp()
    yield Path(d)
    shutil.rmtree(d, ignore_errors=True)


@pytest.fixture
def lookup(temp_dir):
    """A ReferenceLookup with mocked collaborators — only its own state is under test."""
    db = MagicMock()
    db.get_references_to_file.return_value = []
    db.get_references_to_directory.return_value = []

    parser = MagicMock()
    parser.parse_file.return_value = []
    parser.parse_content.return_value = []

    updater = MagicMock()
    updater.dry_run = False
    updater.backup_enabled = False

    return ReferenceLookup(
        link_db=db,
        parser=parser,
        updater=updater,
        project_root=temp_dir,
        logger=MagicMock(),
    )


class TestPruneDuringConcurrentRegistration:
    """Failure mode 1: RuntimeError from mutating a dict mid-iteration."""

    def test_record_move_survives_registration_during_prune(self, lookup):
        """A concurrent _register_pending_recalc must not blow up record_move.

        _prune_move_memory iterates the inner entries dict in a list
        comprehension. An insert from the other thread changes its size, and
        CPython raises RuntimeError on the next iteration step. Raised here it
        escapes record_move — called at the very top of _handle_file_moved's
        try block — so the except handler abandons the ENTIRE move update, not
        just one link.
        """
        target = "doc/moved-target.md"
        now = time.monotonic()
        competing = []

        def _hook():
            competing.append(
                _run_competing(
                    lambda: lookup._register_pending_recalc(target, "a/old.md", "a/new.md")
                )
            )

        # Trigger entry first, then further entries so the iteration continues
        # past the hook and reaches the size-change check.
        entries = {("seed/old0.md", "seed/new0.md"): _HookedTimestamp(now, _hook)}
        for i in range(1, 6):
            entries[(f"seed/old{i}.md", f"seed/new{i}.md")] = now
        lookup._pending_recalcs = {target: entries}

        # record_move prunes before recording; the hook fires inside that prune.
        lookup.record_move("some/file.md", "other/file.md")

        for thread in competing:
            thread.join(_JOIN_TIMEOUT)
            assert not thread.is_alive(), "competing registration never completed"
            assert not thread.errors, f"competing thread raised: {thread.errors}"

        assert competing, "hook never fired — the test did not reach the prune iteration"
        # The competing registration must be intact, not dropped by the collision.
        assert ("a/old.md", "a/new.md") in lookup._pending_recalcs[target]

    def test_lookup_recent_move_survives_registration_during_prune(self, lookup):
        """Same collision reached through _lookup_recent_move.

        This path is the quieter one: the RuntimeError is swallowed by
        _calculate_updated_relative_path's except block, so the link is left
        silently stale — indistinguishable from the PD-BUG-114 symptom.
        """
        target = "doc/moved-target.md"
        now = time.monotonic()
        competing = []

        def _hook():
            competing.append(
                _run_competing(
                    lambda: lookup._register_pending_recalc(target, "b/old.md", "b/new.md")
                )
            )

        entries = {("seed/old0.md", "seed/new0.md"): _HookedTimestamp(now, _hook)}
        for i in range(1, 6):
            entries[(f"seed/old{i}.md", f"seed/new{i}.md")] = now
        lookup._pending_recalcs = {target: entries}
        lookup._recent_moves = {"x/old.md": ("x/new.md", now)}

        result = lookup._lookup_recent_move("x/old.md")

        for thread in competing:
            thread.join(_JOIN_TIMEOUT)
            assert not thread.is_alive(), "competing registration never completed"
            assert not thread.errors, f"competing thread raised: {thread.errors}"

        assert competing, "hook never fired — the test did not reach the prune iteration"
        # The lookup must still return its answer, not be aborted mid-prune.
        assert result == "x/new.md"


class TestPendingRecalcLostUpdate:
    """Failure mode 2: a registration dropped into an orphaned dict."""

    def test_registration_is_not_lost_to_a_concurrent_apply(self, lookup, temp_dir):
        """apply_pending_recalcs popping mid-registration must not lose the entry.

        _register_pending_recalc does ``entries = setdefault(key, {})`` and then
        stores into ``entries``. A pop between the two leaves the caller writing
        into a dict no longer reachable from _pending_recalcs: the deferred
        repair is gone, with no exception and no log line.

        The assertion is deliberately two-sided — the entry must be either still
        queued or delivered to apply_pending_recalcs. Asserting only "delivered"
        would fail for benign orderings; asserting only "queued" would pass on a
        run that dropped it after consuming nothing.
        """
        target = "doc/vacated-target.md"
        pending_old, pending_new = "docs/old-name.md", "docs/new-name.md"

        # apply_pending_recalcs only repairs entries whose new path exists.
        (temp_dir / "docs").mkdir()
        (temp_dir / pending_new).write_text("body\n", encoding="utf-8")

        delivered = []
        competing = []
        real_monotonic = time.monotonic

        def _fake_repair(old, new, abs_new, backup_enabled=False):
            delivered.append((old, new))
            return 0

        fired = threading.Event()

        def _monotonic_with_hook():
            # Fires in the window between setdefault and the store: the RHS of
            # ``entries[(old, new)] = time.monotonic()`` is evaluated first.
            if not fired.is_set():
                fired.set()
                competing.append(_run_competing(lambda: lookup.apply_pending_recalcs(target)))
            return real_monotonic()

        with patch.object(lookup, "update_links_within_moved_file", side_effect=_fake_repair):
            with patch("linkwatcher.reference_lookup.time.monotonic", _monotonic_with_hook):
                lookup._register_pending_recalc(target, pending_old, pending_new)

        for thread in competing:
            thread.join(_JOIN_TIMEOUT)
            assert not thread.is_alive(), "competing apply never completed"
            assert not thread.errors, f"competing thread raised: {thread.errors}"

        assert fired.is_set(), "hook never fired — the registration window was not reached"

        queued = (pending_old, pending_new) in lookup._pending_recalcs.get(target, {})
        assert queued or (pending_old, pending_new) in delivered, (
            "pending recalc was lost: neither left queued in _pending_recalcs nor "
            "handed to apply_pending_recalcs — the deferred link repair will never run"
        )


class TestNoLockHeldAcrossRepair:
    """Design pin: the repair callback re-enters the guarded methods.

    Not a pre-fix reproduction — unsynchronized code passes this trivially. It
    exists to fail the *wrong* fix: apply_pending_recalcs calls back into
    update_links_within_moved_file, which reaches _lookup_recent_move and
    _register_pending_recalc through _calculate_updated_relative_path. Holding
    a non-reentrant lock across that callback deadlocks the daemon — a strictly
    worse outcome than the race being fixed.
    """

    def test_apply_pending_recalcs_does_not_deadlock_on_reentrant_repair(self, lookup, temp_dir):
        target = "doc/vacated-target.md"
        pending_old, pending_new = "docs/old-name.md", "docs/new-name.md"

        (temp_dir / "docs").mkdir()
        (temp_dir / pending_new).write_text("body\n", encoding="utf-8")

        def _reentrant_repair(old, new, abs_new, backup_enabled=False):
            # Exactly what the real repair reaches via link recalculation.
            lookup._lookup_recent_move("some/other-target.md")
            lookup._register_pending_recalc("another/target.md", old, new)
            lookup.record_move(old, new)
            return 0

        lookup._register_pending_recalc(target, pending_old, pending_new)

        outcome = []

        def _worker():
            with patch.object(lookup, "update_links_within_moved_file", _reentrant_repair):
                outcome.append(lookup.apply_pending_recalcs(target))

        thread = threading.Thread(target=_worker, daemon=True)
        thread.start()
        thread.join(_JOIN_TIMEOUT)

        assert not thread.is_alive(), (
            "apply_pending_recalcs deadlocked: the lock is held across the repair "
            "callback, which re-enters the guarded move-memory methods"
        )
        assert outcome == [0]


class TestConcurrentMoveMemoryStress:
    """Backstop for the interleavings the deterministic tests do not name.

    Covers the read-modify-write on record_move's chain-following loop, which
    snapshots _recent_moves and then writes back. Probabilistic by nature — the
    deterministic tests above are the load-bearing pins; this one widens the
    window (many entries, a short GIL switch interval) so an unsynchronized
    implementation is very likely to surface an error.
    """

    def test_two_threads_hammering_move_memory_raise_nothing(self, lookup):
        now = time.monotonic()
        lookup._recent_moves = {f"seed/{i}.md": (f"seed/moved-{i}.md", now) for i in range(500)}
        lookup._pending_recalcs = {
            "seed/target.md": {(f"p/{i}.md", f"p/moved-{i}.md"): now for i in range(500)}
        }

        errors = []
        barrier = threading.Barrier(2)

        def _mover():
            barrier.wait()
            try:
                for i in range(150):
                    lookup.record_move(f"t1/{i}.md", f"t1/moved-{i}.md")
                    lookup._lookup_recent_move(f"t1/{i}.md")
            except Exception as exc:
                errors.append(exc)

        def _registrar():
            barrier.wait()
            try:
                for i in range(150):
                    lookup._register_pending_recalc("seed/target.md", f"t2/{i}.md", f"t2/n{i}.md")
                    lookup.record_move(f"t2/{i}.md", f"t2/moved-{i}.md")
            except Exception as exc:
                errors.append(exc)

        original_interval = sys.getswitchinterval()
        sys.setswitchinterval(1e-6)
        try:
            threads = [threading.Thread(target=_mover), threading.Thread(target=_registrar)]
            for thread in threads:
                thread.start()
            for thread in threads:
                thread.join(30.0)
                assert not thread.is_alive(), "worker thread hung"
        finally:
            sys.setswitchinterval(original_interval)

        assert not errors, f"concurrent move-memory access raised: {errors}"
        # Every move each thread recorded must still be resolvable.
        for i in range(150):
            assert lookup._lookup_recent_move(f"t1/{i}.md") == f"t1/moved-{i}.md"
            assert lookup._lookup_recent_move(f"t2/{i}.md") == f"t2/moved-{i}.md"
