"""
Tests for the duplicate instance prevention (lock file) mechanism.

This module tests the lock file acquisition, release, and edge cases
implemented in main.py to prevent multiple LinkWatcher instances.
"""

import os
import subprocess

# Import the lock file functions from main
import sys
from pathlib import Path
from unittest.mock import patch

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from main import LOCK_FILE_NAME, _is_pid_running, acquire_lock, release_lock  # noqa: E402

pytestmark = [
    pytest.mark.feature("0.1.1"),
    pytest.mark.priority("Critical"),
    pytest.mark.test_type("unit"),
    pytest.mark.specification(
        "test/specifications/feature-specs/test-spec-0-1-1-core-architecture.md"
    ),
]


class TestLockFile:
    """Test cases for the lock file mechanism."""

    def test_lock_file_created_on_acquire(self, tmp_path):
        """Test that acquire_lock creates a .linkwatcher.lock file."""
        lock_file = acquire_lock(tmp_path)
        try:
            assert lock_file is not None
            assert lock_file.exists()
            assert lock_file.name == LOCK_FILE_NAME
        finally:
            release_lock(lock_file)

    def test_lock_file_contains_valid_pid(self, tmp_path):
        """Test that the lock file contains the current process PID."""
        lock_file = acquire_lock(tmp_path)
        try:
            content = lock_file.read_text().strip()
            assert content == str(os.getpid())
        finally:
            release_lock(lock_file)

    def test_lock_file_removed_on_release(self, tmp_path):
        """Test that release_lock removes the lock file."""
        lock_file = acquire_lock(tmp_path)
        assert lock_file.exists()
        release_lock(lock_file)
        assert not lock_file.exists()

    def test_stale_lock_file_overridden(self, tmp_path):
        """Test that a lock file with a dead PID is overridden."""
        lock_file_path = tmp_path / LOCK_FILE_NAME
        # Write a PID that is very unlikely to be running
        lock_file_path.write_text("999999999")

        with patch("main._is_pid_running", return_value=False):
            lock_file = acquire_lock(tmp_path)
            try:
                assert lock_file is not None
                assert lock_file.exists()
                content = lock_file.read_text().strip()
                assert content == str(os.getpid())
            finally:
                release_lock(lock_file)

    def test_duplicate_instance_prevented(self, tmp_path):
        """Test that a second instance is prevented when a live PID lock exists."""
        lock_file_path = tmp_path / LOCK_FILE_NAME
        fake_pid = os.getpid() + 1
        lock_file_path.write_text(str(fake_pid))

        with patch("main._is_pid_running", return_value=True):
            with pytest.raises(SystemExit) as exc_info:
                acquire_lock(tmp_path)

        assert exc_info.value.code == 1

    def test_corrupt_lock_file_handled(self, tmp_path):
        """Test that a lock file with non-numeric content is treated as stale."""
        lock_file_path = tmp_path / LOCK_FILE_NAME
        lock_file_path.write_text("not-a-pid")

        lock_file = acquire_lock(tmp_path)
        try:
            assert lock_file is not None
            assert lock_file.exists()
            content = lock_file.read_text().strip()
            assert content == str(os.getpid())
        finally:
            release_lock(lock_file)

    def test_release_lock_with_none(self):
        """Test that release_lock handles None gracefully."""
        # Should not raise
        release_lock(None)

    def test_release_lock_already_deleted(self, tmp_path):
        """Test that release_lock handles already-deleted lock file."""
        lock_file = acquire_lock(tmp_path)
        lock_file.unlink()  # Delete before release
        # Should not raise
        release_lock(lock_file)

    def test_is_pid_running_current_process(self):
        """Test that _is_pid_running returns True for current process."""
        assert _is_pid_running(os.getpid()) is True

    def test_is_pid_running_invalid_pid(self):
        """Test that _is_pid_running returns False for non-existent PID."""
        assert _is_pid_running(999999999) is False

    def test_acquire_lock_refuses_when_live_rival_holds_lock(self, tmp_path):
        """Regression for PD-BUG-099: when a real, live rival process already holds
        the lock, a second start must refuse loudly (SystemExit) rather than
        overwrite it and run concurrently.

        Complements test_duplicate_instance_prevented (which mocks _is_pid_running)
        by exercising the full real path end-to-end: the atomic
        os.open(O_CREAT|O_EXCL) hits the rival's on-disk lock, _read_lock_owner_pid
        reads the rival's PID, and the real _is_pid_running confirms the rival is
        alive — so acquire_lock exits(1) instead of double-acquiring, the condition
        behind the multi-instance log-rotation storm.
        """
        # A real, different, live process acting as the rival lock owner.
        rival = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(30)"])
        try:
            lock_file_path = tmp_path / LOCK_FILE_NAME
            lock_file_path.write_text(str(rival.pid))

            with pytest.raises(SystemExit) as exc_info:
                acquire_lock(tmp_path)
            assert exc_info.value.code == 1
        finally:
            rival.terminate()
            rival.wait(timeout=5)

    def test_acquire_lock_defers_to_owner_filling_empty_lock(self, tmp_path, monkeypatch):
        """Regression for TD255: a rival that wins the atomic create but has not
        yet written its PID leaves a momentarily-empty lock. A second starter must
        settle-read until the owner's PID appears and then defer (SystemExit) — it
        must NOT treat the empty body as stale and reclaim the live owner's lock.
        """
        rival = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(30)"])
        try:
            lock_file_path = tmp_path / LOCK_FILE_NAME
            lock_file_path.write_text("")  # lock exists but PID not yet written

            original_read_text = Path.read_text
            read_calls = {"count": 0}

            def fake_read_text(self, *args, **kwargs):
                if self.name == LOCK_FILE_NAME:
                    read_calls["count"] += 1
                    # First read hits the empty window; then the owner's PID appears.
                    return "" if read_calls["count"] < 2 else str(rival.pid)
                return original_read_text(self, *args, **kwargs)

            monkeypatch.setattr(Path, "read_text", fake_read_text)

            with pytest.raises(SystemExit) as exc_info:
                acquire_lock(tmp_path)
            assert exc_info.value.code == 1
            assert read_calls["count"] >= 2, "settle-read must re-read before deciding"
        finally:
            rival.terminate()
            rival.wait(timeout=5)

    def test_acquire_lock_reclaims_persistently_empty_lock(self, tmp_path):
        """Regression for TD255: an empty lock whose PID never appears (creator
        died mid-window) is a genuine orphan — after the settle-read gives up it
        must be reclaimed, not block startup forever.
        """
        lock_file_path = tmp_path / LOCK_FILE_NAME
        lock_file_path.write_text("")  # empty and stays empty (orphan)

        lock_file = acquire_lock(tmp_path)
        try:
            assert lock_file is not None
            assert lock_file.exists()
            assert lock_file.read_text().strip() == str(os.getpid())
        finally:
            release_lock(lock_file)
