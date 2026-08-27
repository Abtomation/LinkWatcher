#!/usr/bin/env python3
"""
Manual validation for PD-BUG-136: the Control Panel's drain terminates a daemon
while a buffered move-correlation is still open, silently dropping the reference
update FDD 7-1-1-BR-3 requires the drain to let finish.

Why a delete+create, not a rename: a rename (Move-Item / os.replace) reaches the
daemon as a NATIVE move event and is applied in ~200 ms, so it can never be
"in flight".  Only a delete whose matching create arrives later leaves the daemon
holding a buffered correlation -- and while it waits it writes NOTHING, so its
log signature is byte-for-byte identical to an idle daemon's.  That is exactly
what the drain mistakes for quiescence.

This script drives the REAL panel drain (`drain_and_terminate`) with the panel's
real defaults against a REAL daemon, so the observation is the production path,
not a simulation.  The daemon under test must run FROM REPO SOURCE -- the
deployed ~/bin daemon lags the fix.

The playground lives OUTSIDE the repo (C:/tmp) so the repository's own daemon
does not index it and confound the observation.

How to validate:

  1. python test/bug-validation/PD-BUG-136_drain_correlation_window_validation.py setup
     -> Creates C:/tmp/pd136-playground/ with docs/guide.md referencing
        notes/setup.md, and a config carrying move_detect_delay: 10.

  2. In a SEPARATE terminal, start a repo-source daemon against the playground
     and let it settle (~5 s, until "monitoring_started" appears):
        python main.py --project-root C:/tmp/pd136-playground `
                       --config C:/tmp/pd136-playground/tools/linkwatcher/linkwatcher-config.yaml `
                       --log-file C:/tmp/pd136-playground/logs/linkwatcher/LinkWatcherLog.txt

  3. python test/bug-validation/PD-BUG-136_drain_correlation_window_validation.py drain
     The script prints the BEFORE state, then:
       - deletes notes/setup.md          (the daemon buffers the delete, silently)
       - starts the panel's real drain   (as closing the panel window does)
       - re-creates the file at archive/setup.md 5 s later, INSIDE the daemon's
         10 s correlation window but AFTER the 3 s log-idle threshold
       - waits for the drain to terminate the daemon, then prints the AFTER state

     -> WITHOUT the fix: the drain reports quiescent after ~3 s and kills the
        daemon before the create lands.  guide.md still reads ../notes/setup.md
        -- the reference update is LOST.  The file is intact, never truncated:
        the failure is silent loss, not corruption.
     -> WITH the fix: the drain holds for the correlation window, the create is
        correlated, and guide.md reads ../archive/setup.md before the daemon is
        terminated.

  3b. `drain --mid-drain` covers the code-review F1 case: the drain starts FIRST
     against a daemon whose log is already old (so the entry-time age check
     correctly picks the fast path), and only then does the delete land. Pre-F1
     the drain resolved at ~3 s and killed the daemon before the create; the
     window is now re-armed by the delete itself, so the update completes.

  4. python test/bug-validation/PD-BUG-136_drain_correlation_window_validation.py cleanup

Reproduced and diagnosed 2026-08-25; the E2E case TE-E2E-036 originally filed
against this bug used a rename and therefore could not exercise it.
"""

import shutil
import sys
import threading
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "src"))

from linkwatcher.linkwatcher_control_panel.discovery import (  # noqa: E402
    PsutilProcessTable,
    is_daemon_for,
)
from linkwatcher.linkwatcher_control_panel.lifecycle import (  # noqa: E402
    PsutilTerminator,
    drain_and_terminate,
)
from linkwatcher.linkwatcher_control_panel.model import ProjectInfo  # noqa: E402

PLAYGROUND = Path("C:/tmp/pd136-playground")
LOG_DIR = PLAYGROUND / "logs" / "linkwatcher"
CONFIG = PLAYGROUND / "tools" / "linkwatcher" / "linkwatcher-config.yaml"
GUIDE = PLAYGROUND / "docs" / "guide.md"
SOURCE = PLAYGROUND / "notes" / "setup.md"
TARGET = PLAYGROUND / "archive" / "setup.md"

# The panel's shipped defaults (PanelSettings) -- the values a real close uses.
PANEL_IDLE_THRESHOLD = 3.0
PANEL_GRACE_PERIOD = 20.0

# When the create lands: after the 3 s idle threshold, well inside the 10 s
# correlation window.  This gap is what makes the correlation genuinely pending.
CREATE_DELAY_SECONDS = 5.0

SETUP_NOTES = "# Setup Notes\n\nPlain markdown, moved while the panel closes.\n"


def setup():
    if PLAYGROUND.exists():
        shutil.rmtree(PLAYGROUND)
    LOG_DIR.mkdir(parents=True)
    CONFIG.parent.mkdir(parents=True, exist_ok=True)
    GUIDE.parent.mkdir(parents=True, exist_ok=True)
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    GUIDE.write_text(
        "# Guide\n\nThe setup instructions live in [Setup Notes](../notes/setup.md).\n",
        encoding="utf-8",
    )
    SOURCE.write_text(SETUP_NOTES, encoding="utf-8")
    CONFIG.write_text(
        "monitored_extensions:\n"
        "  - .md\n"
        "  - .yaml\n"
        "  - .json\n"
        "ignored_directories:\n"
        "  - .git\n"
        "  - logs\n"
        "move_detect_delay: 10\n"
        "create_backups: false\n"
        "dry_run_mode: false\n",
        encoding="utf-8",
    )
    print(f"Playground created: {PLAYGROUND}")
    print("Now start a repo-source daemon against it (see module docstring, step 2).")


def _project() -> ProjectInfo:
    return ProjectInfo(
        project_id="PD136",
        name="pd136-playground",
        root=PLAYGROUND,
        config_path=CONFIG,
        log_dir=LOG_DIR,
    )


def _link_line() -> str:
    for line in GUIDE.read_text(encoding="utf-8").splitlines():
        if "Setup Notes" in line:
            return line.strip()
    return "<link line not found>"


def drain():
    if not GUIDE.exists() or not SOURCE.exists():
        print(f"Playground not in its pristine state ({PLAYGROUND}). Run `setup` first.")
        sys.exit(2)

    project = _project()
    table = PsutilProcessTable()
    running = [e.pid for e in table.snapshot() if is_daemon_for(e, PLAYGROUND)]
    print("=" * 72)
    print("BEFORE")
    print("=" * 72)
    print(f"  guide.md link line : {_link_line()}")
    print(f"  notes/setup.md     : {'present' if SOURCE.exists() else 'absent'}")
    print(f"  archive/setup.md   : {'present' if TARGET.exists() else 'absent'}")
    print(f"  daemon pids seen   : {running or 'NONE -- start the daemon first (step 2)'}")
    if not running:
        sys.exit(2)

    outcome_box = {}

    def run_drain():
        start = time.monotonic()
        outcome_box["outcome"] = drain_and_terminate(
            project,
            idle_threshold=PANEL_IDLE_THRESHOLD,
            grace_period=PANEL_GRACE_PERIOD,
            process_table=table,
            terminator=PsutilTerminator(),
        )
        outcome_box["elapsed"] = time.monotonic() - start

    mid_drain = "--mid-drain" in sys.argv
    print()
    print("=" * 72)
    if mid_drain:
        print("ACTION -- close the panel FIRST, then delete inside the drain  [--mid-drain]")
    else:
        print("ACTION -- delete, close the panel, then create inside the window")
    print("=" * 72)

    worker = threading.Thread(target=run_drain, name="panel-drain", daemon=True)

    if mid_drain:
        # Code-review finding F1: the correlation opens AFTER the drain has begun,
        # so the entry-time age check cannot see it. Pre-F1 the drain read an old
        # log, took the 3 s fast path, and killed the daemon before the create.
        worker.start()
        print("  t+0.0s  panel drain started against a daemon whose log is already old")
        time.sleep(1.0)
        SOURCE.unlink()
        print("  t+1.0s  deleted notes/setup.md -- correlation opens INSIDE the drain")
        time.sleep(CREATE_DELAY_SECONDS)
        TARGET.parent.mkdir(parents=True, exist_ok=True)
        TARGET.write_text(SETUP_NOTES, encoding="utf-8")
        print(
            f"  t+{CREATE_DELAY_SECONDS + 1.0:.1f}s  created archive/setup.md -- "
            "correlation should fire"
        )
    else:
        SOURCE.unlink()
        print("  t+0.0s  deleted notes/setup.md (the daemon buffers this, silently)")
        time.sleep(0.5)
        worker.start()
        print("  t+0.5s  panel drain started (this is what closing the window does)")
        time.sleep(CREATE_DELAY_SECONDS)
        TARGET.parent.mkdir(parents=True, exist_ok=True)
        TARGET.write_text(SETUP_NOTES, encoding="utf-8")
        print(
            f"  t+{CREATE_DELAY_SECONDS + 0.5:.1f}s  created archive/setup.md -- "
            "correlation should fire"
        )

    worker.join(timeout=PANEL_GRACE_PERIOD + 30.0)
    outcome = outcome_box.get("outcome")
    elapsed = outcome_box.get("elapsed", float("nan"))
    time.sleep(1.0)  # let any last write land before reading

    print()
    print("=" * 72)
    print("AFTER")
    print("=" * 72)
    link = _link_line()
    print(f"  guide.md link line : {link}")
    print(f"  drain took         : {elapsed:.1f}s")
    if outcome is not None:
        print(f"  terminated pids    : {list(outcome.terminated)}")
        print(f"  forced termination : {outcome.forced}")
    print(
        f"  guide.md intact    : {GUIDE.read_text(encoding='utf-8').count(chr(10))} lines, "
        f"{GUIDE.stat().st_size} bytes"
    )

    print()
    if "../archive/setup.md" in link:
        print("  PASS -- the drain outlasted the correlation window; the reference followed")
        print("          the move before the daemon was terminated.")
        return 0
    if "../notes/setup.md" in link:
        print("  FAIL -- PD-BUG-136 reproduced: the drain declared quiescence and killed")
        print("          the daemon while the correlation was still buffered. The file is")
        print("          intact and uncorrupted; the reference update was silently LOST.")
        return 1
    print(f"  INCONCLUSIVE -- unexpected link line: {link}")
    return 2


def cleanup():
    if PLAYGROUND.exists():
        shutil.rmtree(PLAYGROUND)
        print(f"Removed {PLAYGROUND}")
    else:
        print(f"Nothing to remove at {PLAYGROUND}")


COMMANDS = {"setup": setup, "drain": drain, "cleanup": cleanup}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(f"Usage: {Path(__file__).name} {{{'|'.join(COMMANDS)}}} [--mid-drain]")
        sys.exit(2)
    result = COMMANDS[sys.argv[1]]()
    sys.exit(result or 0)
