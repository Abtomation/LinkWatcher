r"""
Manual validation test for PD-BUG-127: the two log-rotation config fields
bypassed validation and then failed after it.

PURPOSE:
  Verify that a wrongly typed log_file_max_size_mb / log_file_backup_count is
  reported by validate() naming the key — and that the daemon therefore tells
  the operator which key is wrong instead of dying with a raw TypeError or
  starting up and quietly breaking log rotation later.

  validate() iterated a HARDCODED list of five numeric field names while the
  dataclass declared seven. The two omissions are consumed by
  main._apply_logging_config BEFORE config.validate() runs, so nothing checked
  them at any point on the startup path.

HOW TO RUN:
  python test/bug-validation/PD-BUG-127_rotation_config_validation_coverage_validation.py

WHAT IT DOES (reproducible by hand: write one of these config files and start
the daemon with --config pointing at it):
  1. Loads each bad config through the real LinkWatcherConfig and validate().
  2. Runs the real daemon and shows the startup output the operator gets.
  3. Demonstrates, on the real rotating handler, the log-directory consequence
     an unvalidated backup count produced — the part of this bug that was
     silent rather than loud.

EXPECTED RESULT (fixed):
  Every case returns an issue naming the offending key; the daemon prints a
  config_issue line naming it and exits 1; rotation prunes as configured.

PRE-FIX BEHAVIOUR (the bug), all measured:
  log_file_max_size_mb: big    -> validate() returned []; TypeError in the
                                  RotatingFileHandler constructor reached the
                                  operator as a generic fatal_error naming no key
  log_file_max_size_mb: true   -> validate() returned []; silently accepted as
                                  1 MB (bool is a subclass of int)
  log_file_backup_count: x     -> validate() returned []; daemon STARTED, then at
                                  the first rollover TypeError'd inside the stdlib
                                  emit handler, which swallows it: the triggering
                                  record was lost and rotated logs were never
                                  pruned, growing the log directory without bound
  log_file_backup_count: 3.5   -> validate() returned []; TypeError at the
                                  backups[...] slice, same deferred failure
"""

import logging
import subprocess
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from linkwatcher.config.settings import LinkWatcherConfig  # noqa: E402
from linkwatcher.logging import TimestampRotatingFileHandler  # noqa: E402

# (label, yaml body, key that must be named in the reported issue)
CASES = [
    ('log_file_max_size_mb: "big"', 'log_file_max_size_mb: "big"\n', "log_file_max_size_mb"),
    (
        "log_file_max_size_mb: true  (silent pre-fix)",
        "log_file_max_size_mb: true\n",
        "log_file_max_size_mb",
    ),
    ("log_file_max_size_mb: 0", "log_file_max_size_mb: 0\n", "log_file_max_size_mb"),
    ('log_file_backup_count: "x"', 'log_file_backup_count: "x"\n', "log_file_backup_count"),
    (
        "log_file_backup_count: 3.5  (deferred pre-fix)",
        "log_file_backup_count: 3.5\n",
        "log_file_backup_count",
    ),
    ("log_file_backup_count: -1", "log_file_backup_count: -1\n", "log_file_backup_count"),
]

# The discriminating condition: without these, "reports an issue" could be
# satisfied by a validate() that rejects everything.
CONTROLS = [
    ("valid rotation values", "log_file_max_size_mb: 25\nlog_file_backup_count: 7\n", []),
    ("backup count 0 (disables pruning - a real setting)", "log_file_backup_count: 0\n", []),
    ("float on a float-declared field", "move_detect_delay: 2.5\n", []),
    (
        "pinned message wording is unchanged",
        'max_file_size_mb: "big"\n',
        ["max_file_size_mb must be a number (got str)"],
    ),
]


def _rotate(handler, times):
    """Force `times` rollovers through the real handler.

    Spaced over a second each: rotated names carry a second-resolution
    timestamp, so same-second rollovers collide on the backup filename and the
    rename back-off (PD-BUG-099) suppresses the rest — which would hide the
    pruning difference this section exists to show.
    """
    record = logging.LogRecord("n", 20, "p", 1, "x" * 200, None, None)
    for i in range(times):
        if i:
            time.sleep(1.1)
        handler.emit(record)


def run_validation():
    print("=" * 72)
    print("PD-BUG-127: log-rotation config fields are validated - validation")
    print("=" * 72)

    results = {}

    print("\n[1] Wrongly typed rotation values must be REPORTED by key...")
    with tempfile.TemporaryDirectory() as tmpdir:
        for label, body, expected_key in CASES:
            cfg = Path(tmpdir) / "cfg.yaml"
            cfg.write_text(body, encoding="utf-8")
            print("\n    config: %s" % label)
            issues = LinkWatcherConfig.from_file(str(cfg)).validate()
            if not issues:
                print("      operator sees: (nothing - value silently accepted)")
            for issue in issues:
                print("      operator sees: %s" % issue)
            results["reports %s" % label] = any(expected_key in i for i in issues)

    print("\n[2] Controls - existing behaviour must be untouched...")
    with tempfile.TemporaryDirectory() as tmpdir:
        for label, body, expected in CONTROLS:
            cfg = Path(tmpdir) / "cfg.yaml"
            cfg.write_text(body, encoding="utf-8")
            issues = LinkWatcherConfig.from_file(str(cfg)).validate()
            print("\n    config: %s" % label)
            print("      issues: %r" % (issues,))
            print("      wanted: %r" % (expected,))
            results["control: %s" % label] = issues == expected

    print("\n[3] Daemon startup - what the operator actually gets...")
    print("    (hand-repro: python main.py --config <the bad file>)")
    print("    A key name alone would be a VACUOUS check - it also appears inside")
    print("    a raw traceback. These require the structured config_issue line")
    print("    AND no traceback, which a pre-fix run cannot satisfy.")
    repo_root = Path(__file__).parent.parent.parent

    daemon_cases = [
        ("log_file_max_size_mb: big", "log_file_max_size_mb: big\n", "log_file_max_size_mb"),
        ('log_file_backup_count: "x"', 'log_file_backup_count: "x"\n', "log_file_backup_count"),
    ]
    for label, body, expected_key in daemon_cases:
        with tempfile.TemporaryDirectory() as tmpdir:
            log_file = Path(tmpdir) / "logs" / "lw.log"
            cfg = Path(tmpdir) / "cfg.yaml"
            # A log file is required: the pre-fix crash happened while BUILDING
            # the rotating handler, which only exists when file logging is on.
            cfg.write_text(body + 'log_file: "%s"\n' % log_file.as_posix(), encoding="utf-8")
            proc = subprocess.run(
                [sys.executable, str(repo_root / "main.py"), "--config", str(cfg)],
                cwd=tmpdir,
                capture_output=True,
                text=True,
                timeout=120,
            )
            combined = (proc.stdout or "") + (proc.stderr or "")
            print("\n    config: %s" % label)
            for line in combined.strip().splitlines()[-4:]:
                print("      %s" % line)
            print("      exit code: %s" % proc.returncode)

            results["daemon reports config_issue for %s" % label] = (
                "config_issue" in combined and expected_key in combined
            )
            results["daemon emits no traceback for %s" % label] = (
                "Traceback (most recent call last)" not in combined
            )
            results["daemon exits non-zero for %s" % label] = proc.returncode != 0

    print("\n[4] The silent consequence - log-directory growth, before vs after...")
    print("    Rotating 3 times with the value the pre-fix code passed through,")
    print("    then with the value that now survives validation.")
    with tempfile.TemporaryDirectory() as tmpdir:
        for label, backup_count in (("unvalidated 'x' (pre-fix)", "x"), ("validated 2", 2)):
            d = Path(tmpdir) / str(backup_count)
            d.mkdir()
            handler = TimestampRotatingFileHandler(
                str(d / "lw.log"), maxBytes=50, backupCount=backup_count, encoding="utf-8"
            )
            try:
                _rotate(handler, 3)
            finally:
                handler.close()
            rotated = sorted(p.name for p in d.glob("lw_*.log"))
            print("\n    backupCount = %r  (%s)" % (backup_count, label))
            print("      rotated files kept: %d %s" % (len(rotated), rotated))
            if backup_count == "x":
                print("      ^ never pruned - this is the unbounded growth the bug caused")
                results["pre-fix value would leave backups unpruned"] = len(rotated) > 2
            else:
                print("      ^ pruned to the configured count")
                results["validated value prunes to the configured count"] = len(rotated) <= 2

    print("\n[5] Verifying...")
    all_passed = True
    for label, ok in results.items():
        print("    [%s] %s" % ("PASS" if ok else "FAIL", label))
        all_passed = all_passed and ok

    print("\n" + "=" * 72)
    if all_passed:
        print("RESULT: ALL CHECKS PASSED - the rotation fields are validated by key,")
        print("        the daemon names the offending key instead of dying with a raw")
        print("        TypeError, and rotation prunes as configured.")
    else:
        print("RESULT: SOME CHECKS FAILED - see the FAIL lines above.")
    print("=" * 72)
    return all_passed


if __name__ == "__main__":
    sys.exit(0 if run_validation() else 1)
