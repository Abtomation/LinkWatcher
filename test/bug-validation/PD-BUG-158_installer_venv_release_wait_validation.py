"""Manual validation for PD-BUG-158 — installer aborts on a false venv-lock reading.

WHAT THE BUG IS
    deployment/install_global.py stops every process running from the install
    venv, then on the very next statement tests whether the venv python.exe is
    free. Killing is asynchronous: Windows finishes tearing the process tree
    down and releases the executable's file handle a moment after taskkill
    returns. The gate has no tolerance for that moment, so a release deploy
    aborts before copying any files, reporting a running process that is
    already gone.

WHAT THIS SCRIPT SHOWS YOU
    Phase A reproduces the OLD behaviour against your real, running daemons:
    kill them exactly as the installer did, then check the lock immediately.
    A "LOCKED" verdict there is the abort you saw during the v2.2.1 deploy.
    Phase B runs the FIXED code path on the same machine and shows the gate
    coming back clear. Phase C prints the old and new abort messages side by
    side against this machine, so the diagnostics half of the bug — a message
    asserting a running process when none exists — is observable rather than
    merely asserted.

    The window is short (52 ms when measured on 2026-08-31) and INTERMITTENT —
    one run in two reproduced it. Phase A therefore repeats several times and
    reports a hit count. Zero hits does not mean the bug is absent; it means
    this machine was fast that minute. Phase B is the part that must be clean
    every time.

HOW TO RUN
    1. Make sure at least one LinkWatcher daemon is running (ideally two —
       more processes widen the window). Start them from your projects with
       process-framework/tools/linkWatcher/start_linkwatcher_background.ps1
    2. python test/bug-validation/PD-BUG-158_installer_venv_release_wait_validation.py
    3. The script STOPS your daemons — that is the point. It prints the exact
       command to restart each one when it is done. Nothing is installed,
       copied, or written; only processes are stopped.
"""

import sys
import time
from pathlib import Path

_PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(_PROJECT_ROOT / "deployment"))

import install_global as ig  # noqa: E402

INSTALL_DIR = Path.home() / "bin"
VENV_DIR = INSTALL_DIR / ".linkwatcher-venv"
PHASE_A_ROUNDS = 4


def live_daemons():
    return ig.find_venv_daemon_processes(VENV_DIR)


def show_daemons(procs):
    for pid, cmd in procs:
        print(f"      PID {pid:<7} project={ig.project_root_from_cmdline(cmd)}")


def restart_hint(roots):
    print("\n   Restart your daemons with (one per project):")
    for root in roots:
        print(
            f'      pwsh.exe -ExecutionPolicy Bypass -File "{root}\\process-framework'
            f'\\tools\\linkWatcher\\start_linkwatcher_background.ps1"'
        )
    print("   (A FrameworkBuilder-style workspace keeps that script under blueprint/.)")
    print("   They also come back on their own at the next session start of each project.")


def old_stop_then_check():
    """The pre-fix sequence: kill every enumerated PID, then check at once."""
    import subprocess

    procs = live_daemons()
    if not procs:
        return None, None, [ig.project_root_from_cmdline(c) for _, c in procs]

    roots = [ig.project_root_from_cmdline(c) for _, c in procs]
    t0 = time.perf_counter()
    for pid, _ in procs:
        subprocess.run(["taskkill", "/F", "/T", "/PID", str(pid)], capture_output=True)
    verdict = ig.venv_python_locked(INSTALL_DIR)  # <-- the gate, no tolerance
    elapsed_to_clear = None
    if verdict:
        while (time.perf_counter() - t0) < 30:
            if not ig.venv_python_locked(INSTALL_DIR):
                elapsed_to_clear = (time.perf_counter() - t0) * 1000
                break
            time.sleep(0.005)
    return verdict, elapsed_to_clear, roots


def wait_for_daemons(expected, limit=45):
    print(f"   waiting for {expected} daemon(s) to come back ", end="", flush=True)
    for _ in range(limit):
        if len(live_daemons()) >= expected:
            print(" ok")
            time.sleep(1.5)
            return True
        print(".", end="", flush=True)
        time.sleep(1)
    print(" TIMED OUT")
    return False


def main():
    print("=" * 74)
    print("PD-BUG-158 manual validation — installer venv-lock race")
    print("=" * 74)

    procs = live_daemons()
    if not procs:
        print("\nNo LinkWatcher daemon is running from the install venv.")
        print("Start at least one, then re-run this script. Nothing to observe.")
        return 1

    print(f"\nBEFORE — {len(procs)} process(es) running from {VENV_DIR}:")
    show_daemons(procs)
    print(f"      venv python.exe locked: {ig.venv_python_locked(INSTALL_DIR)}  (expected: True)")
    roots = [ig.project_root_from_cmdline(c) for _, c in procs]
    expected = len(procs)

    print("\n" + "-" * 74)
    print(f"PHASE A — the OLD behaviour, {PHASE_A_ROUNDS} rounds")
    print("-" * 74)
    print("Kill exactly as the installer did, then read the gate immediately.")
    print('A "LOCKED" round is the release abort.\n')

    hits = 0
    for rnd in range(1, PHASE_A_ROUNDS + 1):
        if not live_daemons():
            if not wait_for_daemons(expected):
                print("   cannot continue Phase A — restart the daemons manually")
                break
        verdict, cleared, _ = old_stop_then_check()
        if verdict is None:
            break
        if verdict:
            hits += 1
            print(
                f"   round {rnd}: GATE READ **LOCKED**  -> the install would ABORT here"
                f"   (lock cleared {cleared:.0f} ms later, no process left)"
            )
        else:
            print(f"   round {rnd}: gate clear — window missed this time")
        if rnd < PHASE_A_ROUNDS:
            for r in roots:
                _relaunch(r)

    print(f"\n   Phase A result: {hits} of {PHASE_A_ROUNDS} rounds hit the false abort.")
    if hits == 0:
        print("   (Not a pass — the race is intermittent. See the note at the top.)")

    print("\n" + "-" * 74)
    print("PHASE B — the FIXED code path")
    print("-" * 74)
    if not live_daemons():
        for r in roots:
            _relaunch(r)
        wait_for_daemons(expected)
    procs = live_daemons()
    if not procs:
        print("   no daemons to stop — restart them and re-run Phase B")
        restart_hint(roots)
        return 1

    print(
        f"   stopping {len(procs)} process(es) through install_global.stop_daemons_using_venv ..."
    )
    stopped = ig.stop_daemons_using_venv(INSTALL_DIR)
    verdict = ig.venv_python_locked(INSTALL_DIR)  # main()'s next statement
    print(f"\n   GATE after the fixed stop: locked = {verdict}   (expected: False)")
    print(
        "   -> the install proceeds"
        if not verdict
        else "   -> STILL ABORTS — a genuine holder; Phase C shows what it would tell you"
    )

    print("\n" + "-" * 74)
    print("PHASE C — the abort message itself (the diagnostics half of the bug)")
    print("-" * 74)
    print("If the gate ever does read locked, this is what the operator is told.")
    print("Both blocks are rendered against THIS machine, right now, with the")
    print("daemons stopped — so the venv genuinely holds no process.\n")
    print("   OLD (shipped in v2.2.1) — asserts a process that is not there:")
    print("      ERROR: The install venv's python.exe is still locked by a running process.")
    print(f"         Check for processes running from: {VENV_DIR}\n")
    print("   NOW — reports what can actually be observed:")
    print("      ERROR: The install venv's python.exe is still locked.")
    print(f"         {ig.venv_lock_holder_report(INSTALL_DIR)}")
    print(f"         Processes stopped by this installer: {len(stopped)}.")
    print(f"         Install venv: {VENV_DIR}")
    print("         No files were copied — the existing installation is unchanged.")
    print("\n   Compare the first line of each: the old one sends you hunting for a")
    print("   running process. Confirm for yourself that none exists —")
    print(f"      venv processes right now: {ig.find_venv_daemon_processes(VENV_DIR) or 'none'}")

    print("\n" + "=" * 74)
    print("AFTER — venv processes:", live_daemons() or "none")
    restart_hint(roots)
    return 0


def _relaunch(root):
    """Best-effort daemon restart between rounds."""
    import subprocess

    for candidate in (
        Path(root)
        / "process-framework"
        / "tools"
        / "linkWatcher"
        / "start_linkwatcher_background.ps1",
        Path(root)
        / "blueprint"
        / "process-framework"
        / "tools"
        / "linkWatcher"
        / "start_linkwatcher_background.ps1",
    ):
        if candidate.exists():
            subprocess.Popen(
                ["pwsh.exe", "-ExecutionPolicy", "Bypass", "-File", str(candidate)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return


if __name__ == "__main__":
    sys.exit(main())
