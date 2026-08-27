"""Corrected watch-root deletion predicate for watchdog on Windows (PD-BUG-141).

AI Context
----------
- **Problem this solves**: watchdog 6.0.0's ``winapi._is_observed_path_deleted``
  decides whether the watched directory has gone away by comparing the
  handle's **NT device** path against the **DOS** watch path::

      GetFinalPathNameByHandleW(handle, buff, ..., VOLUME_NAME_NT)
      return buff.value != path        # \\Device\\HarddiskVolume3\\... != C:\\...

  Those two forms never match, so the predicate is a **constant true** — it
  answers "deleted" for a perfectly healthy directory.  Measured 2026-08-26:
  it returns ``True`` for a healthy, a deleted *and* a moved root alike, so it
  carries no information at all.

- **Why that is dangerous**: ``read_directory_changes`` consults it from its
  ``except OSError`` arm.  Any transient error other than
  ``ERROR_OPERATION_ABORTED`` is therefore rewritten into a synthetic
  ``FILE_ACTION_DELETED_SELF`` event, and ``WindowsApiEmitter.queue_events``
  calls ``self.stop()`` on that action.  One recoverable hiccup — a quota
  shortfall, a network-share blip — permanently ends the watch, and the
  original error is discarded rather than raised, so nothing records why.

- **Why identity rather than paths**: the question is "does this handle still
  refer to the directory sitting at the watch path?", which is about object
  identity, not spelling.  On Windows a directory has many true spellings —
  through a junction, through a ``subst`` drive, with or without the
  ``\\\\?\\`` extended-length prefix, in any case, with or without a trailing
  separator — and a path compare has to normalize away every one of them.  It
  cannot: ``GetFinalPathNameByHandleW`` resolves a junction to its *target*,
  so a junction-rooted or ``subst``-rooted watch compares unequal no matter
  how carefully the strings are normalized, and the predicate stays constant
  true for exactly those projects.  Comparing the volume serial plus file
  index of the two handles asks the real question directly and needs no
  normalization at all: same object means healthy, different object means the
  root was replaced, nothing openable means it is gone.

- **The fix trap this deliberately avoids**: swapping ``VOLUME_NAME_NT`` for
  ``VOLUME_NAME_DOS`` looks like the one-line fix and is **not** one.
  ``GetFinalPathNameByHandleW`` then returns a ``\\\\?\\``-prefixed path, which
  still compares unequal to the watch path, so the predicate stays constant
  true.  A change that appears to fix the bug while changing nothing is worse
  than no change.

- **Known residual — an unreachable root reads as deleted**: when the path
  cannot be opened at all, this returns ``True``.  That is right for a real
  deletion and wrong for a *transient* unavailability, the network-share blip
  being the case that matters: the share drops, the open fails, and the watch
  ends on what was a recoverable condition.  Distinguishing "gone" from
  "briefly unreachable" needs a retry policy with a timeout, which is a
  different feature from answering the predicate correctly, and it belongs
  above this shim rather than inside a vendor patch.  Local-disk transient
  errors — the quota shortfall, the buffer hiccup — are fully covered, because
  the directory stays openable throughout.

- **What a transient error does now**: nothing here absorbs it.  The corrected
  predicate returns ``False``, ``read_directory_changes`` re-raises, and the
  error propagates with its winerror intact — which is what the bug asks for.
  The emitter thread still dies (``EventEmitter.run`` has no exception guard,
  a separate upstream defect), but it dies *loudly*: a traceback on stderr,
  which both the launcher and the Control Panel capture to
  ``logs/linkwatcher/LinkWatcherError.txt``, and ``WatchLivenessMonitor``
  reporting ``observer_emitter_died`` before the daemon stops.

- **Scope**: this patches one private vendor function and nothing else.  If a
  future watchdog renames or removes it, installation degrades to a no-op and
  the caller is expected to warn (see ``service.py``), rather than the daemon
  failing to start.  Nothing at module import touches the Win32 API, so this
  module stays importable on non-Windows platforms.
"""

import ctypes
import os

# Stamped on our replacement so re-installation is a no-op rather than a
# wrapper stack, and so the vendor original is never restored by accident.
_PATCH_MARKER = "_linkwatcher_pd_bug_141"


def _make_corrected_predicate(winapi):
    """Build the replacement predicate bound to the given winapi module.

    The Win32 binding lives here rather than at module scope so that importing
    this module never touches ``ctypes.WinDLL`` or ``ctypes.wintypes``, neither
    of which exists off Windows.  Only ``install_watch_root_deletion_fix``
    calls this, and only after its ``os.name`` guard.
    """
    from ctypes import wintypes

    class _BY_HANDLE_FILE_INFORMATION(ctypes.Structure):
        _fields_ = [
            ("dwFileAttributes", wintypes.DWORD),
            ("ftCreationTime", wintypes.FILETIME),
            ("ftLastAccessTime", wintypes.FILETIME),
            ("ftLastWriteTime", wintypes.FILETIME),
            ("dwVolumeSerialNumber", wintypes.DWORD),
            ("nFileSizeHigh", wintypes.DWORD),
            ("nFileSizeLow", wintypes.DWORD),
            ("nNumberOfLinks", wintypes.DWORD),
            ("nFileIndexHigh", wintypes.DWORD),
            ("nFileIndexLow", wintypes.DWORD),
        ]

    # argtypes are not optional here: without them ctypes marshals the handle
    # as a C int and truncates it on 64-bit Windows.
    get_file_information = ctypes.WinDLL("kernel32").GetFileInformationByHandle
    get_file_information.restype = wintypes.BOOL
    get_file_information.argtypes = (wintypes.HANDLE, ctypes.POINTER(_BY_HANDLE_FILE_INFORMATION))

    def _identity_of_handle(handle):
        """The (volume, file index) pair identifying the directory, or None."""
        info = _BY_HANDLE_FILE_INFORMATION()
        if not get_file_information(handle, ctypes.byref(info)):
            return None
        return (info.dwVolumeSerialNumber, info.nFileIndexHigh, info.nFileIndexLow)

    def _identity_of_path(path):
        """The identity of whatever directory is at ``path`` right now, or None.

        None means nothing openable is there — deleted, moved away, or (see the
        residual noted in the module docstring) briefly unreachable.
        """
        try:
            probe = winapi.get_directory_handle(path)
        except OSError:
            return None
        try:
            return _identity_of_handle(probe)
        finally:
            winapi.CloseHandle(probe)

    def _is_observed_path_deleted(handle, path):
        watched = _identity_of_handle(handle)
        if watched is None:
            # The watch handle itself is unusable — the watch is gone by any
            # reasonable reading, and honouring the deletion is the safe answer.
            return True

        current = _identity_of_path(path)
        if current is None:
            return True

        # Something is there, but is it still *our* directory?  A root that was
        # moved away and replaced by a new directory at the same path is a
        # different object, and counts as gone.
        return watched != current

    setattr(_is_observed_path_deleted, _PATCH_MARKER, True)
    return _is_observed_path_deleted


def install_watch_root_deletion_fix():
    """Install the corrected predicate into watchdog's winapi module.

    Safe to call repeatedly. Returns True when the corrected predicate is in
    place (installed now or already present), False when the patch does not
    apply — a non-Windows platform, no winapi backend, or a watchdog release
    that no longer exposes the function.
    """
    if os.name != "nt":
        return False

    try:
        from watchdog.observers import winapi
    except ImportError:
        return False

    current = getattr(winapi, "_is_observed_path_deleted", None)
    if current is None:
        # A future watchdog may have renamed, removed, or already fixed this.
        # Do not invent the symbol — leave the module exactly as found.
        return False

    if getattr(current, _PATCH_MARKER, False):
        return True

    winapi._is_observed_path_deleted = _make_corrected_predicate(winapi)
    return True
