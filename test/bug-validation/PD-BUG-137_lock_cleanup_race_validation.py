#!/usr/bin/env python3
"""
Manual validation for PD-BUG-137: the panel-initiated stop leaves a stale
.linkwatcher.lock behind.

The panel races itself. Its poller reads every project's lock file each cycle
(`read_lock_pid` -> `Path.read_text`) and keeps polling throughout shutdown,
while the stop worker unlinks that same file on another thread. Windows opens
files without FILE_SHARE_DELETE, so an overlapping read makes the unlink fail
with PermissionError (WinError 32) -- which the old `cleanup_lock` swallowed
into a bare `False`, indistinguishable from a deliberately untouched foreign
lock. The panel then logged `lock_removed=False` with no diagnostic and the
stale lock survived.

That is why the incident looked structural but was not: the explicit per-row
stop at 13:50 removed the lock and the window-close stop at 14:10 did not, using
the same code on the same project. A race, not a branch.

The poller is one confirmed holder, not necessarily THE holder in the original
incident: it reads each lock roughly every 2.5 s for well under a millisecond,
so a collision with the single instant of the unlink is rare. An antivirus
scanner examining the files of a process that was just terminated fits a
frequently-recurring failure better. The fix does not need to know which: the
backoff addresses any holder, and the new WARNING names the real one next time.

This validation does NOT need a daemon: the contended resource is the lock file,
not the process. It puts a reader thread on the lock and measures how often a
delete succeeds, first with a naive single attempt (the old behaviour) and then
through the real `cleanup_lock`.

How to validate:

  1. python test/bug-validation/PD-BUG-137_lock_cleanup_race_validation.py probe
     Default mode: a *periodic* reader, opening and closing every 25 ms -- still
     about a hundred times more aggressive than the real poller, so it is a
     conservative stand-in.
     -> "naive single unlink"  = pre-fix. Expect a substantial number of losses.
     -> "cleanup_lock (fixed)" = shipped. Expect ZERO.
     -> Exit 0 when the fixed path lost nothing and the naive path lost
        something (i.e. the run actually exercised the defect).

  2. `probe --stress` puts a CONTINUOUS reader on the file, holding it open
     essentially all the time. This is far beyond the design target and the
     fixed path still loses occasionally -- measured 93/150 naive vs 13/150
     fixed. Recorded deliberately: the backoff is a large probability
     reduction, not a guarantee, and the honest claim is the smaller one.

  3. `probe --hold` keeps one handle open across the whole backoff window so
     even the retries fail. The point there is the WARNING `cleanup_lock` now
     emits, naming the lock, the owner PID, the attempt count and the OS error
     -- the information whose absence made the original incident undiagnosable.

  4. python test/bug-validation/PD-BUG-137_lock_cleanup_race_validation.py cleanup

Diagnosed 2026-08-25. The mechanism class was confirmed in isolation (this
probe); an end-to-end panel reproduction requires an unlucky-timed window close
and did not occur in three attempts.
"""

import logging
import shutil
import sys
import threading
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "src"))

from linkwatcher.linkwatcher_control_panel.discovery import LOCK_FILE_NAME  # noqa: E402
from linkwatcher.linkwatcher_control_panel.lifecycle import cleanup_lock  # noqa: E402
from linkwatcher.linkwatcher_control_panel.panel_log import PANEL_LOGGER_NAME  # noqa: E402

PLAYGROUND = Path("C:/tmp/pd137-lock-race")
LOCK = PLAYGROUND / LOCK_FILE_NAME
OWNER_PID = 12345
TRIALS = 150


# How the stand-in reader contends for the lock file.
PERIODIC = "periodic"  # open/close every 25 ms — conservative poller stand-in
STRESS = "stress"  # continuous open/close — beyond the design target
HOLD = "hold"  # one handle held open across the whole backoff window

PERIODIC_INTERVAL_SECONDS = 0.025


def _reader(path: Path, stop: threading.Event, mode: str):
    """Stand-in for whatever holds the lock file open at the wrong moment."""
    if mode == HOLD:
        try:
            with path.open("r", encoding="utf-8"):
                stop.wait()
        except OSError:
            pass
        return
    while not stop.is_set():
        try:
            path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            pass
        if mode == PERIODIC:
            stop.wait(PERIODIC_INTERVAL_SECONDS)


def _trial(remove, mode: str) -> bool:
    """One contended delete via *remove*; True when the lock is gone after it."""
    PLAYGROUND.mkdir(parents=True, exist_ok=True)
    LOCK.write_text(str(OWNER_PID), encoding="utf-8")
    stop = threading.Event()
    reader = threading.Thread(target=_reader, args=(LOCK, stop, mode), daemon=True)
    reader.start()
    time.sleep(0.002)
    try:
        remove()
    finally:
        stop.set()
        reader.join(timeout=3.0)
    gone = not LOCK.exists()
    if not gone:
        try:
            LOCK.unlink()
        except OSError:
            pass
    return gone


def _naive_unlink():
    """Exactly what cleanup_lock did before the fix: one attempt, error swallowed."""
    try:
        LOCK.unlink()
    except OSError:
        pass


def probe():
    if "--hold" in sys.argv:
        mode = HOLD
    elif "--stress" in sys.argv:
        mode = STRESS
    else:
        mode = PERIODIC
    trials = 5 if mode == HOLD else TRIALS

    naive_lost = sum(1 for _ in range(trials) if not _trial(_naive_unlink, mode))

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter("      panel log | %(levelname)s | %(message)s"))
    panel_logger = logging.getLogger(PANEL_LOGGER_NAME)
    previous = (panel_logger.handlers, panel_logger.level, panel_logger.disabled)
    panel_logger.handlers = [handler]
    panel_logger.setLevel(logging.DEBUG)
    panel_logger.disabled = False
    try:
        fixed_lost = sum(
            1
            for _ in range(trials)
            if not _trial(lambda: cleanup_lock(PLAYGROUND, [OWNER_PID]), mode)
        )
    finally:
        panel_logger.handlers, panel_logger.level, panel_logger.disabled = previous

    print()
    print("=" * 68)
    print(f"Contended lock deletes, {trials} trials each  [reader: {mode}]")
    print("=" * 68)
    print(f"  naive single unlink (pre-fix) : {naive_lost}/{trials} stale locks left behind")
    print(f"  cleanup_lock (fixed)          : {fixed_lost}/{trials} stale locks left behind")
    print()

    if mode == HOLD:
        print("  --hold keeps one handle open across the whole backoff window, so even the")
        print("  fixed path cannot delete it. The point is the WARNING above: the operator")
        print("  is told which lock, whose PID, how many attempts, and the OS error. The")
        print("  pre-fix code returned a bare False and logged nothing at all.")
        return 0

    if mode == STRESS:
        print("  --stress holds the file open essentially continuously, far beyond the")
        print("  design target. The backoff is a large probability reduction, not a")
        print("  guarantee, and a holder that outlasts it still wins. The downstream")
        print("  defences remain the backstop: main.py reclaims a dead-PID lock and")
        print("  discovery surfaces STALE_LOCK.")
        return 0 if fixed_lost < naive_lost else 1

    if naive_lost == 0:
        print("  INCONCLUSIVE -- the naive path never lost the race in this run, so the")
        print("  defect was not exercised. Re-run, or use --stress.")
        return 2
    if fixed_lost == 0:
        print("  PASS -- the backoff rode out every overlap that defeated the old code.")
        return 0
    print("  FAIL -- the fixed path still left a stale lock behind at poller cadence.")
    return 1


def cleanup():
    if PLAYGROUND.exists():
        shutil.rmtree(PLAYGROUND)
        print(f"Removed {PLAYGROUND}")
    else:
        print(f"Nothing to remove at {PLAYGROUND}")


COMMANDS = {"probe": probe, "cleanup": cleanup}

if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    if command not in COMMANDS:
        print(f"Usage: {Path(__file__).name} {{probe [--hold]|cleanup}}")
        sys.exit(2)
    sys.exit(COMMANDS[command]() or 0)
