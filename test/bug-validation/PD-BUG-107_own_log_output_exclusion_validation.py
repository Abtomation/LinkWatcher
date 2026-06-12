#!/usr/bin/env python3
"""
Manual validation for PD-BUG-107: the daemon indexes its own log files.
logs/linkwatcher/ is not covered by ignored_directories (the linkWatcher
entry matches case-sensitively), so the daemon's log content enters the
link database — moves rewrite historical log lines — and with the
PD-BUG-102 on_modified rescan, every rescan's own log write fires another
modify event: a self-sustaining loop re-parsing a growing log.

The playground lives OUTSIDE the repo (C:/tmp) so the project's own
daemon doesn't index it and confound the observation. The daemon under
test must run FROM REPO SOURCE (the deployed ~/bin daemon lags the fix).

How to validate:

  1. python test/bug-validation/PD-BUG-107_own_log_output_exclusion_validation.py setup
     -> Creates C:/tmp/pd107-playground/ with a few linked markdown files
        and a logs/linkwatcher/ directory.
  2. In a SEPARATE terminal, start a repo-source daemon against the
     playground and let it run ~30 seconds:
        python main.py --project-root C:/tmp/pd107-playground `
                       --log-file C:/tmp/pd107-playground/logs/linkwatcher/LinkWatcherLog.txt
  3. While it runs, touch a monitored file to generate log traffic:
        Add-Content C:/tmp/pd107-playground/notes.md "edit"
  4. Stop the daemon (Ctrl+C), then:
     python test/bug-validation/PD-BUG-107_own_log_output_exclusion_validation.py check
     -> WITHOUT the fix: the log contains file_links_scanned entries FOR
        THE LOG FILE ITSELF (each log write re-triggered a rescan — the
        loop), and the initial scan indexed logs/linkwatcher/ content.
     -> WITH the fix: a single own_output_excluded startup line; zero
        file_links_scanned entries for anything under logs/linkwatcher/.
  5. python test/bug-validation/PD-BUG-107_own_log_output_exclusion_validation.py cleanup
"""

import shutil
import sys
from pathlib import Path

PLAYGROUND = Path("C:/tmp/pd107-playground")
LOG_DIR = PLAYGROUND / "logs" / "linkwatcher"
LOG_FILE = LOG_DIR / "LinkWatcherLog.txt"


def setup():
    if PLAYGROUND.exists():
        shutil.rmtree(PLAYGROUND)
    LOG_DIR.mkdir(parents=True)
    (PLAYGROUND / "target.md").write_text("# Target\n", encoding="utf-8")
    (PLAYGROUND / "notes.md").write_text("# Notes\n\nSee [target](target.md).\n", encoding="utf-8")
    print(f"Playground created: {PLAYGROUND}")
    print("Now start a repo-source daemon against it (see module docstring, step 2).")


def check():
    if not LOG_FILE.exists():
        print(f"No log file at {LOG_FILE} — did the daemon run? (step 2)")
        sys.exit(2)
    lines = LOG_FILE.read_text(encoding="utf-8", errors="replace").splitlines()

    own_scans = [
        ln
        for ln in lines
        if "file_links_scanned" in ln and ("logs/linkwatcher" in ln or "logs\\linkwatcher" in ln)
    ]
    excluded = [ln for ln in lines if "own_output_excluded" in ln]

    print(f"Log lines total:                              {len(lines)}")
    print(f"Rescans of the daemon's OWN output (loop):    {len(own_scans)}")
    print(f"own_output_excluded startup announcements:    {len(excluded)}")
    for ln in own_scans[:5]:
        print(f"  LOOP EVIDENCE: {ln}")

    if own_scans:
        print("\nRESULT: BUG PRESENT — the daemon rescanned its own output;")
        print("each of those rescans wrote the log line that triggered the next one.")
        sys.exit(1)
    print("\nRESULT: CLEAN — the daemon never indexed or rescanned its own output.")
    if not excluded:
        print("(Note: no own_output_excluded line found — fix not active or no file logging.)")
    sys.exit(0)


def cleanup():
    if PLAYGROUND.exists():
        shutil.rmtree(PLAYGROUND)
        print(f"Removed {PLAYGROUND}")
    else:
        print("Nothing to clean up.")


if __name__ == "__main__":
    actions = {"setup": setup, "check": check, "cleanup": cleanup}
    if len(sys.argv) != 2 or sys.argv[1] not in actions:
        print(__doc__)
        sys.exit(2)
    actions[sys.argv[1]]()
