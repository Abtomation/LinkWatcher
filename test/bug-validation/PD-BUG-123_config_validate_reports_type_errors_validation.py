r"""
Manual validation test for PD-BUG-123: LinkWatcherConfig.validate() raised on a
type-invalid config value instead of reporting it as an issue.

PURPOSE:
  Verify that a well-formed YAML config carrying a wrongly typed value produces
  an issue list naming the offending key — and that the daemon therefore tells
  the operator WHICH key is wrong instead of dying with a raw Python message.

  validate()'s contract is to *return* a list of issues, so every caller
  reasonably treats it as non-raising. It performed type-dependent operations
  (.upper(), <= 0, iteration) directly on values that arrived unvalidated from
  YAML. main.py calls it during startup inside a broad `except Exception`, so an
  exception escaping validate() became one generic fatal_error carrying a raw
  Python message, instead of the precise per-key `config_issue` lines written
  just below that call.

  _from_dict's unguarded set(value) was the same defect one layer earlier: for
  `monitored_extensions: 7` it raised during loading, before validate() — the
  function whose job is to report it — was ever reached.

HOW TO RUN:
  python test/bug-validation/PD-BUG-123_config_validate_reports_type_errors_validation.py

WHAT IT DOES (reproducible by hand: write one of these config files and start
the daemon with --config pointing at it):
  1. Writes a config file per case into a temp directory.
  2. Loads it through the real LinkWatcherConfig.from_file(), then validate().
  3. Prints what the operator would see, and checks the offending key is named.
  4. Runs the real daemon (main.py --config <bad file>) for the headline case
     and shows the actual startup output the operator gets.

EXPECTED RESULT (fixed):
  Every case returns an issue list naming the offending key. The daemon prints a
  config_issue line naming that key and exits 1.

PRE-FIX BEHAVIOUR (the bug):
  log_level: 5              -> AttributeError: 'int' object has no attribute 'upper'
  max_file_size_mb: "big"   -> TypeError: '<=' not supported between 'str' and 'int'
  move_detect_delay: "x"    -> TypeError: '<=' not supported between 'str' and 'int'
  monitored_extensions: 7   -> TypeError: 'int' object is not iterable (during LOADING)
  monitored_extensions: ".md" -> silently became {'.','m','d'}: three nonsense extensions
  max_file_size_mb: true    -> silently accepted (bool is a subclass of int) as size 1
  ...and the daemon reported only a generic fatal_error with the raw message.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from linkwatcher.config.settings import LinkWatcherConfig  # noqa: E402

# (label, yaml body, key that must be named in the reported issue)
CASES = [
    ("log_level: 5", "log_level: 5\n", "log_level"),
    ('max_file_size_mb: "big"', 'max_file_size_mb: "big"\n', "max_file_size_mb"),
    ('move_detect_delay: "x"', 'move_detect_delay: "x"\n', "move_detect_delay"),
    ("monitored_extensions: 7", "monitored_extensions: 7\n", "monitored_extensions"),
    (
        'monitored_extensions: ".md"  (silent pre-fix)',
        'monitored_extensions: ".md"\n',
        "monitored_extensions",
    ),
    ("max_file_size_mb: true  (silent pre-fix)", "max_file_size_mb: true\n", "max_file_size_mb"),
    ("ignored_directories: 7", "ignored_directories: 7\n", "ignored_directories"),
    ("validation_extensions: 7", "validation_extensions: 7\n", "validation_extensions"),
]

# Configs that are valid or semantically (not type-) invalid: these must behave
# exactly as they always have. They are the discriminating condition — without
# them, "reports an issue" could be satisfied by a validate() that rejects
# everything.
CONTROLS = [
    ("valid config", "log_level: DEBUG\nmax_file_size_mb: 10\n", []),
    ("negative size", "max_file_size_mb: -1\n", ["max_file_size_mb must be positive"]),
    (
        # Wording updated by PD-BUG-129: the dot check now covers all three
        # extension-bearing fields, so the issue names the offending key.
        "extension without a dot",
        'monitored_extensions: ["md"]\n',
        ["monitored_extensions entry 'md' should start with a dot"],
    ),
    ("float delay", "move_detect_delay: 2.5\n", []),
    ("list of extensions", 'monitored_extensions: [".md", ".txt"]\n', []),
]


def run_validation():
    print("=" * 72)
    print("PD-BUG-123: config validate() reports type errors - validation")
    print("=" * 72)

    results = {}

    print("\n[1] Type-invalid values must be REPORTED, not raised...")
    with tempfile.TemporaryDirectory() as tmpdir:
        for label, body, expected_key in CASES:
            cfg = Path(tmpdir) / "cfg.yaml"
            cfg.write_text(body, encoding="utf-8")
            print("\n    config: %s" % label)
            try:
                config = LinkWatcherConfig.from_file(str(cfg))
            except Exception as e:
                print("      from_file RAISED %s: %s" % (type(e).__name__, e))
                results["reports %s" % label] = False
                continue
            try:
                issues = config.validate()
            except Exception as e:
                print("      validate() RAISED %s: %s" % (type(e).__name__, e))
                results["reports %s" % label] = False
                continue

            for issue in issues:
                print("      operator sees: %s" % issue)
            ok = any(expected_key in issue for issue in issues)
            if not issues:
                print("      operator sees: (nothing — value silently accepted)")
            results["reports %s" % label] = ok

    print("\n[2] Controls — existing behaviour must be untouched...")
    with tempfile.TemporaryDirectory() as tmpdir:
        for label, body, expected in CONTROLS:
            cfg = Path(tmpdir) / "cfg.yaml"
            cfg.write_text(body, encoding="utf-8")
            print("\n    config: %s" % label)
            try:
                issues = LinkWatcherConfig.from_file(str(cfg)).validate()
            except Exception as e:
                print("      RAISED %s: %s" % (type(e).__name__, e))
                results["control: %s" % label] = False
                continue
            print("      issues: %r" % (issues,))
            print("      wanted: %r" % (expected,))
            results["control: %s" % label] = issues == expected

    print("\n[3] Daemon startup — what the operator actually gets...")
    print("    (hand-repro: python main.py --config <the bad file>)")
    print("    NOTE ON ASSERTIONS: checking only that the key name appears in the")
    print("    output is VACUOUS — the key also appears inside a raw traceback.")
    print("    These checks require the structured `config_issue` line AND the")
    print("    absence of a traceback, which a pre-fix run cannot satisfy.")
    repo_root = Path(__file__).parent.parent.parent

    # log_level is the bug's own headline field and the one that needed the
    # main.py half of the fix: _apply_logging_config consumed it BEFORE
    # config.validate() ran, so guarding validate() alone left this case still
    # dying with a raw ValueError.
    daemon_cases = [
        ("log_level: 5", "log_level: 5\n", "log_level"),
        ('max_file_size_mb: "big"', 'max_file_size_mb: "big"\n', "max_file_size_mb"),
    ]

    for label, body, expected_key in daemon_cases:
        with tempfile.TemporaryDirectory() as tmpdir:
            cfg = Path(tmpdir) / "cfg.yaml"
            cfg.write_text(body, encoding="utf-8")
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

            emits_config_issue = "config_issue" in combined and expected_key in combined
            no_traceback = "Traceback (most recent call last)" not in combined
            results["daemon reports config_issue for %s" % label] = emits_config_issue
            results["daemon emits no traceback for %s" % label] = no_traceback
            results["daemon exits non-zero for %s" % label] = proc.returncode != 0

    print("\n[4] Verifying...")
    all_passed = True
    for label, ok in results.items():
        print("    [%s] %s" % ("PASS" if ok else "FAIL", label))
        all_passed = all_passed and ok

    print("\n" + "=" * 72)
    if all_passed:
        print("RESULT: ALL CHECKS PASSED - type-invalid values are reported by key,")
        print("        existing validation is unchanged, and the daemon says which")
        print("        key is wrong instead of dying with a raw Python message.")
    else:
        print("RESULT: SOME CHECKS FAILED - see the FAIL lines above.")
    print("=" * 72)
    return all_passed


if __name__ == "__main__":
    success = run_validation()
    sys.exit(0 if success else 1)
