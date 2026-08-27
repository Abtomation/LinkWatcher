"""
Document Metadata:
ID: TE-TST-159
Type: Test File
Category: Test
Version: 1.1
Created: 2026-08-26
Updated: 2026-08-27
Component Name: LinkWatcherService
Feature Id: 1.1.1
Language: Python
Test Name: WatchRootDeletionPredicate
Test Type: Unit
"""

# WatchRootDeletionPredicate Unit Test
#
# Regression coverage for PD-BUG-141 — a transient ReadDirectoryChangesW
# error silently and permanently killing the file system watch.
#
# watchdog 6.0.0's ``winapi._is_observed_path_deleted`` asks whether the
# watched directory has gone away by comparing the handle's *NT device*
# path (``\Device\HarddiskVolume3\...``) against the *DOS* watch path
# (``C:\...``).  Those two forms never match, so the predicate is a
# CONSTANT TRUE: it answers "deleted" for a perfectly healthy directory.
#
# ``read_directory_changes`` consults it in its ``except OSError`` arm.  So
# ANY transient error other than ERROR_OPERATION_ABORTED is converted into
# a synthetic FILE_ACTION_DELETED_SELF event, whereupon
# ``WindowsApiEmitter.queue_events`` calls ``self.stop()`` and the watch is
# permanently dead — while the Observer keeps reporting itself alive.
#
# The two test classes below cover the two levels that matter:
#   * TestWatchRootDeletionPredicate — the predicate's own truth table.
#   * TestReadDirectoryChangesErrorPath — the consequence that actually
#     bites: a transient error must PROPAGATE, not be silently rewritten
#     into a watch-ending deletion event.
#
# Note on the "healthy" cases: they carry NEGATIVE assertions (the buggy
# ``True`` must not be returned) rather than only asserting ``False``,
# because that is the exact value the defect produces.
#
# Test File ID: TE-TST-159
# Created: 2026-08-26

import ctypes
import os
import shutil
import subprocess
import tempfile

import pytest

pytestmark = [
    pytest.mark.feature("1.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
    pytest.mark.skipif(
        os.name != "nt",
        reason="PD-BUG-141 is a Windows ReadDirectoryChangesW defect; the patched "
        "code path does not exist on other platforms.",
    ),
]

winapi = pytest.importorskip(
    "watchdog.observers.winapi",
    reason="watchdog's Windows API backend is unavailable on this platform.",
)

from linkwatcher.winapi_patch import install_watch_root_deletion_fix  # noqa: E402


@pytest.fixture(scope="module", autouse=True)
def _patch_installed():
    """LinkWatcher installs the corrected predicate in ``service.start()``.

    Installing it here makes these tests exercise the same function object
    the running daemon uses, rather than a test-local copy.
    """
    install_watch_root_deletion_fix()
    yield


@pytest.fixture
def watched_dir():
    """A real directory with a real open watch handle, as watchdog holds it."""
    created = tempfile.mkdtemp(prefix="pd_bug_141_")
    handle = winapi.get_directory_handle(created)
    yield handle, created
    try:
        winapi.close_directory_handle(handle)
    except OSError:
        pass
    for leftover in (created, created + "_moved"):
        if os.path.isdir(leftover):
            shutil.rmtree(leftover, ignore_errors=True)


@pytest.fixture
def junction_dir():
    """A watch root reached through a junction, with a real open watch handle.

    This is the shape a developer has when the project tree is reached through
    a junction or a ``subst`` drive rather than by its literal path — the
    directory has two true spellings, and the handle resolves to the target
    rather than to the watch path.
    """
    target = tempfile.mkdtemp(prefix="pd_bug_141_target_")
    link = target + "_link"

    created = subprocess.run(["cmd", "/c", "mklink", "/J", link, target], capture_output=True)
    if created.returncode != 0:
        shutil.rmtree(target, ignore_errors=True)
        pytest.skip("junction creation is unavailable in this environment")

    handle = winapi.get_directory_handle(link)
    yield handle, link
    try:
        winapi.close_directory_handle(handle)
    except OSError:
        pass
    subprocess.run(["cmd", "/c", "rmdir", link], capture_output=True)
    shutil.rmtree(target, ignore_errors=True)


class TestWatchRootDeletionPredicate:
    """The predicate must answer 'deleted' only when the root is really gone."""

    def test_healthy_directory_is_not_reported_deleted(self, watched_dir):
        """The defect itself: a live watch root must not read as deleted."""
        handle, path = watched_dir

        verdict = winapi._is_observed_path_deleted(handle, path)

        assert verdict is not True, (
            "PD-BUG-141: a healthy watch root was reported deleted. Any transient "
            "ReadDirectoryChangesW error will now be rewritten into a synthetic "
            "DELETED_SELF event and permanently stop the watch."
        )
        assert verdict is False

    def test_healthy_directory_with_trailing_separator_is_not_reported_deleted(self, watched_dir):
        """A trailing separator is the same directory, not a different one."""
        handle, path = watched_dir

        verdict = winapi._is_observed_path_deleted(handle, path + os.sep)

        assert verdict is not True
        assert verdict is False

    def test_healthy_directory_with_different_case_is_not_reported_deleted(self, watched_dir):
        """Windows paths are case-insensitive; a case difference is not a move."""
        handle, path = watched_dir

        verdict = winapi._is_observed_path_deleted(handle, path.upper())

        assert verdict is not True
        assert verdict is False

    def test_junction_root_is_not_reported_deleted(self, junction_dir):
        """A watch root reached through a junction is healthy, not deleted.

        The decisive case for identity-over-path: the handle and the watch path
        name the SAME directory, but they spell it differently, because
        ``GetFinalPathNameByHandleW`` resolves a junction to its target.  A
        path compare reads that as a move and kills the watch on the next
        transient error; an identity compare sees one directory.

        A ``subst`` drive produces the same divergence by the same mechanism,
        so this case stands in for both.
        """
        handle, link = junction_dir

        verdict = winapi._is_observed_path_deleted(handle, link)

        assert verdict is not True, (
            "PD-BUG-141: a healthy watch root reached through a junction was reported "
            "deleted. Any transient ReadDirectoryChangesW error will stop the watch "
            "permanently for every project reached through a junction or subst drive."
        )
        assert verdict is False

    def test_deleted_directory_is_reported_deleted(self, watched_dir):
        """The genuine case the predicate exists to detect must still work."""
        handle, path = watched_dir
        os.rmdir(path)

        assert winapi._is_observed_path_deleted(handle, path) is True

    def test_moved_directory_is_reported_deleted(self, watched_dir):
        """A watch root moved out from under the handle counts as gone."""
        handle, path = watched_dir
        os.rename(path, path + "_moved")

        assert winapi._is_observed_path_deleted(handle, path) is True

    def test_moved_directory_replaced_at_old_path_is_reported_deleted(self, watched_dir):
        """A same-named replacement is a DIFFERENT directory from the watched one.

        Pins the identity compare against degrading into an existence check: the
        old path exists again, so anything answering by path spelling or by mere
        presence would call this healthy, yet the handle no longer refers to it.
        """
        handle, path = watched_dir
        os.rename(path, path + "_moved")
        os.mkdir(path)

        assert winapi._is_observed_path_deleted(handle, path) is True

    def test_unusable_watch_handle_is_reported_deleted(self, watched_dir):
        """An unusable watch handle counts as gone — and must not crash.

        Pins the ``_identity_of_handle`` failure branch (``winapi_patch.py``
        lines 115 and 138), the one live Windows path the rest of this suite
        never reaches: ``GetFileInformationByHandle`` fails on the handle, the
        watched identity is ``None``, and the predicate answers "deleted"
        rather than raising out of ``read_directory_changes``.

        The watch path itself is healthy, so a predicate that consulted only
        the path would answer False here — the assertion is discriminating on
        the handle branch specifically.
        """
        _handle, path = watched_dir

        assert winapi._is_observed_path_deleted(ctypes.c_void_p(-1), path) is True

    def test_install_is_idempotent(self, watched_dir):
        """Re-installing must not stack wrappers or restore the broken predicate."""
        handle, path = watched_dir
        install_watch_root_deletion_fix()
        install_watch_root_deletion_fix()

        assert winapi._is_observed_path_deleted(handle, path) is False

    def test_install_is_a_no_op_when_the_vendor_symbol_is_absent(self, monkeypatch):
        """A future watchdog may drop or rename the function.

        Installation must degrade to doing nothing rather than crashing the
        daemon at startup.
        """
        monkeypatch.delattr(winapi, "_is_observed_path_deleted", raising=False)

        install_watch_root_deletion_fix()  # must not raise

        assert not hasattr(winapi, "_is_observed_path_deleted")


class TestReadDirectoryChangesErrorPath:
    """The consequence: a transient error must reach the caller as an error."""

    @staticmethod
    def _raise_transient(*_args, **_kwargs):
        # ERROR_NOT_ENOUGH_QUOTA (1453) — a real, recoverable condition, and
        # explicitly not ERROR_OPERATION_ABORTED (995), which has its own arm.
        raise OSError(0, "Insufficient quota to complete the requested service.", None, 1453)

    def test_transient_error_on_a_healthy_root_propagates(self, watched_dir, monkeypatch):
        """PD-BUG-141's user-visible failure, at the level that produces it."""
        handle, path = watched_dir
        monkeypatch.setattr(winapi, "ReadDirectoryChangesW", self._raise_transient)

        with pytest.raises(OSError) as excinfo:
            winapi.read_directory_changes(handle, path, recursive=True)

        assert excinfo.value.winerror == 1453, (
            "PD-BUG-141: the transient error must reach the caller intact so the "
            "cause is diagnosable, instead of being discarded."
        )

    def test_transient_error_does_not_fabricate_a_deletion_event(self, watched_dir, monkeypatch):
        """Negative assertion: the synthetic DELETED_SELF must NOT be produced.

        ``queue_events`` calls ``self.stop()`` on that action, so producing it
        here is precisely what kills the watch permanently.

        This spies on the generator rather than inspecting the returned buffer,
        so the assertion is evaluated on every run. Returning early when the
        error propagates would make the test pass without testing anything —
        it would then only restate the propagation the previous test covers.
        """
        handle, path = watched_dir
        monkeypatch.setattr(winapi, "ReadDirectoryChangesW", self._raise_transient)

        fabricated = []
        monkeypatch.setattr(
            winapi,
            "_generate_observed_path_deleted_event",
            lambda *args, **kwargs: fabricated.append(1),
        )

        with pytest.raises(OSError):
            winapi.read_directory_changes(handle, path, recursive=True)

        assert fabricated == [], (
            "PD-BUG-141: a transient error on a healthy directory was converted "
            "into a synthetic DELETED_SELF event, which stops the emitter."
        )

    def test_genuine_deletion_still_yields_the_deletion_event(self, watched_dir, monkeypatch):
        """Guards against over-fixing: real deletions must still be reported."""
        handle, path = watched_dir
        os.rmdir(path)
        monkeypatch.setattr(winapi, "ReadDirectoryChangesW", self._raise_transient)

        buf, nbytes = winapi.read_directory_changes(handle, path, recursive=True)

        actions = [action for action, _src in winapi._parse_event_buffer(buf, nbytes)]
        assert winapi.FILE_ACTION_DELETED_SELF in actions
