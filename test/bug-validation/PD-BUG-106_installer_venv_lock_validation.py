#!/usr/bin/env python3
"""
Manual validation for PD-BUG-106: install_global.py venv rebuild fails when
another project's daemon holds the shared venv.

What this script shows (read-only — it never kills processes or copies files):

  1. Every process currently running from the install-dir venv
     (<install>/.linkwatcher-venv), with its owning project — these are the
     daemons the OLD installer never stopped.
  2. Whether the venv's python.exe is currently locked — the exact condition
     that made the v2.1.1 install abort mid-flow with Permission denied.

How to validate the fix:

  1. Start a LinkWatcher daemon for any OTHER project (e.g. open a session in
     appdev, or run its start_linkwatcher_background.ps1).
  2. Run this script:  python test/bug-validation/PD-BUG-106_installer_venv_lock_validation.py
     -> Expect: at least one daemon listed, "LOCKED: yes".
     -> WITHOUT the fix, running the installer now would abort with
        Errno 13 after copying files (partial install state).
  3. Run the installer:  python deployment/install_global.py
     -> Expect (WITH the fix): "OK: Stopped LinkWatcher daemon using install
        venv (PID: ...)" lines naming each project, then a complete install
        (venv rebuilt, wrappers, smoke test, "installed successfully").
  4. Run this script again:
     -> Expect: no daemons listed, "LOCKED: no". Restart your sessions'
        daemons normally (next session start does it automatically).
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "deployment"))

import install_global  # noqa: E402

INSTALL_DIR = Path.home() / "bin"


def main():
    venv_dir = INSTALL_DIR / ".linkwatcher-venv"
    print(f"Install dir : {INSTALL_DIR}")
    print(f"Venv        : {venv_dir} (exists: {venv_dir.exists()})")
    print()

    procs = install_global.find_venv_daemon_processes(venv_dir)
    if procs:
        print(f"Daemons running from the install venv: {len(procs)}")
        for pid, cmdline in procs:
            root = install_global.project_root_from_cmdline(cmdline) or "<unknown project>"
            print(f"  PID {pid}: {root}")
    else:
        print("Daemons running from the install venv: none")

    locked = install_global.venv_python_locked(INSTALL_DIR)
    print(f"\nvenv python.exe LOCKED: {'yes' if locked else 'no'}")
    print(
        "\nA locked venv means the OLD installer would abort mid-install"
        " (Errno 13);\nthe FIXED installer stops the daemons above first and"
        " aborts cleanly (no files\ncopied) if anything still holds the lock."
    )


if __name__ == "__main__":
    main()
