"""Manual validation for PD-BUG-141 — transient ReadDirectoryChangesW error
silently kills the watch (watchdog NT-vs-DOS compare).

WHAT THE BUG IS
---------------
watchdog 6.0.0 decides "has my watched directory been deleted?" by comparing
the handle's NT device path against the DOS watch path. Those forms never
match, so the answer is always "yes, deleted" — even for a healthy directory.
Any transient error from ReadDirectoryChangesW is therefore rewritten into a
synthetic deletion event, and the emitter stops itself permanently.

HOW THE FIX ANSWERS IT
----------------------
Not by normalizing the two path spellings — that cannot work, because a
directory reached through a junction or a subst drive legitimately resolves to
a different path than the one being watched, and would still read as "moved".
The fix compares directory IDENTITY instead: the volume serial number plus
file index of the watch handle against the same pair for whatever directory
sits at the watch path right now. Same object means healthy; different object
means the root was replaced; nothing openable means it is really gone.

HOW TO RUN
----------
    python test/bug-validation/PD-BUG-141_transient_watch_error_validation.py

Part 1 runs automatically and prints the before/after comparison.
Part 2 runs automatically and covers the junction case that motivated
identity-over-paths.
Part 3 asks you to perform a filesystem action in File Explorer.

WHY PART 2 EXISTS
-----------------
The fix must not over-correct. Making the predicate stop crying wolf is only
half of it — a genuine deletion of the watch root must STILL be detected.
Part 2 is the half you can verify with your own hands rather than by trusting
a unit test, because it is driven by a real File Explorer action.
"""

import ctypes
import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "src"))

from watchdog.observers import winapi  # noqa: E402

from linkwatcher.winapi_patch import install_watch_root_deletion_fix  # noqa: E402

RULE = "=" * 72


def _vendor_predicate(handle, path):
    """watchdog 6.0.0's original implementation, verbatim, for comparison."""
    buff = ctypes.create_unicode_buffer(winapi.PATH_BUFFER_SIZE)
    winapi.GetFinalPathNameByHandleW(handle, buff, winapi.PATH_BUFFER_SIZE, winapi.VOLUME_NAME_NT)
    return buff.value != path


def _show_paths(handle, path):
    nt = ctypes.create_unicode_buffer(winapi.PATH_BUFFER_SIZE)
    winapi.GetFinalPathNameByHandleW(handle, nt, winapi.PATH_BUFFER_SIZE, winapi.VOLUME_NAME_NT)
    print("    watch path (what watchdog holds) :", path)
    print("    NT form  (what the OLD code used):", nt.value)
    print("    The OLD code compared those two strings with != and called it deletion.")
    print("    The NEW code ignores spelling and compares directory identity instead.")


def part1_before_and_after():
    print(RULE)
    print("PART 1 — the predicate, before and after the fix")
    print(RULE)

    workspace = tempfile.mkdtemp(prefix="pd_bug_141_manual_")
    handle = winapi.get_directory_handle(workspace)
    try:
        print("\nA healthy directory was just created and is being watched:\n")
        _show_paths(handle, workspace)
        print("\n    The two forms are different spellings of the SAME directory.")
        print("    The old code compared them with != and concluded 'deleted'.\n")

        before = _vendor_predicate(handle, workspace)
        install_watch_root_deletion_fix()
        after = winapi._is_observed_path_deleted(handle, workspace)

        print("    Directory actually exists on disk :", os.path.isdir(workspace))
        print("    OLD watchdog says 'deleted'       :", before, " <-- wrong" if before else "")
        print("    FIXED LinkWatcher says 'deleted'  :", after, " <-- correct" if not after else "")

        print("\n  Consequence of the OLD answer: a transient error (a quota")
        print("  shortfall, a network blip) is turned into a fake deletion event,")
        print("  the emitter calls stop(), and the daemon never sees another file")
        print("  move — while still reporting itself alive.")

        ok = (before is True) and (after is False)
        print("\n  PART 1 RESULT:", "PASS — the fix changes the answer" if ok else "FAIL")
        return ok
    finally:
        try:
            winapi.close_directory_handle(handle)
        except OSError:
            pass
        shutil.rmtree(workspace, ignore_errors=True)


def part2_junction_root():
    """The case that forced identity-over-paths, and that a path fix cannot reach."""
    print()
    print(RULE)
    print("PART 2 — a watch root reached through a junction")
    print(RULE)

    target = tempfile.mkdtemp(prefix="pd_bug_141_target_")
    link = target + "_link"
    created = subprocess.run(["cmd", "/c", "mklink", "/J", link, target], capture_output=True)
    if created.returncode != 0:
        shutil.rmtree(target, ignore_errors=True)
        print("\n  SKIPPED — this environment does not allow creating a junction.")
        return None

    install_watch_root_deletion_fix()
    handle = winapi.get_directory_handle(link)
    try:
        print("\n  Watching a directory through a junction — the shape you have when")
        print("  the project tree is reached by a link or a subst drive:\n")
        _show_paths(handle, link)

        print("\n    Note the two paths above are DIFFERENT and both correct: the")
        print("    junction resolves to its target. No amount of string")
        print("    normalization makes them equal, so ANY path-comparing check")
        print("    reads this healthy directory as moved.\n")

        verdict = winapi._is_observed_path_deleted(handle, link)
        print("    Directory actually exists on disk :", os.path.isdir(link))
        print("    FIXED LinkWatcher says 'deleted'  :", verdict, "" if verdict else " <-- correct")

        ok = verdict is False
        print(
            "\n  PART 2 RESULT:",
            (
                "PASS — a junction-rooted watch is healthy"
                if ok
                else "FAIL — a junction-rooted watch still reads as deleted"
            ),
        )
        return ok
    finally:
        try:
            winapi.close_directory_handle(handle)
        except OSError:
            pass
        subprocess.run(["cmd", "/c", "rmdir", link], capture_output=True)
        shutil.rmtree(target, ignore_errors=True)


def part3_real_deletion_still_detected():
    print()
    print(RULE)
    print("PART 3 — a REAL deletion must still be detected (your action)")
    print(RULE)

    workspace = tempfile.mkdtemp(prefix="pd_bug_141_manual_")
    handle = winapi.get_directory_handle(workspace)
    install_watch_root_deletion_fix()

    try:
        print("\n  A watched directory has been created for you:\n")
        print("     ", workspace)
        print("\n  Right now, with the directory present, the fixed check says:")
        print(
            "      deleted =",
            winapi._is_observed_path_deleted(handle, workspace),
            "(expected: False)",
        )

        print("\n  NOW DO THIS, using File Explorer (not a script):")
        print("    1. Open the folder above in File Explorer.")
        print("    2. Go up one level, then DELETE or RENAME that folder.")
        print("    3. Come back here and press Enter.\n")
        input("  Press Enter once you have deleted or renamed it... ")

        still_there = os.path.isdir(workspace)
        verdict = winapi._is_observed_path_deleted(handle, workspace)

        print("\n    Directory still on disk           :", still_there)
        print("    FIXED LinkWatcher says 'deleted'  :", verdict)

        if still_there:
            print("\n  PART 3 RESULT: INCONCLUSIVE — the folder is still there.")
            print("  Nothing was deleted or renamed, so there is nothing to detect.")
            return None

        ok = verdict is True
        print(
            "\n  PART 3 RESULT:",
            (
                "PASS — a genuine deletion is still detected"
                if ok
                else "FAIL — the fix over-corrected and now misses real deletions"
            ),
        )
        return ok
    finally:
        try:
            winapi.close_directory_handle(handle)
        except OSError:
            pass
        shutil.rmtree(workspace, ignore_errors=True)


def main():
    if os.name != "nt":
        print("PD-BUG-141 is a Windows-only defect; nothing to validate on this platform.")
        return 0

    one = part1_before_and_after()
    two = part2_junction_root()
    three = part3_real_deletion_still_detected()

    print()
    print(RULE)
    print("SUMMARY")
    print(RULE)
    print("  Part 1 (healthy directory no longer read as deleted):", "PASS" if one else "FAIL")
    print(
        "  Part 2 (junction-rooted watch reads as healthy)      :",
        "SKIPPED" if two is None else ("PASS" if two else "FAIL"),
    )
    print(
        "  Part 3 (real deletion still detected)               :",
        "INCONCLUSIVE" if three is None else ("PASS" if three else "FAIL"),
    )
    print()
    return 0 if (one and two is not False and three is not False) else 1


if __name__ == "__main__":
    sys.exit(main())
