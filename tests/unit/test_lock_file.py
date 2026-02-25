"""
Tests for the duplicate instance prevention (lock file) mechanism.

This module tests the lock file acquisition, release, and edge cases
implemented in main.py to prevent multiple LinkWatcher instances.
"""

import os

# Import the lock file functions from main
import sys
from pathlib import Path
from unittest.mock import patch

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from main import LOCK_FILE_NAME, _is_pid_running, acquire_lock, release_lock


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
        lock_file_path.write_text(str(os.getpid()))

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
