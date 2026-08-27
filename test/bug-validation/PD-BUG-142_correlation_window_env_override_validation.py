#!/usr/bin/env python3
"""
Manual validation for PD-BUG-142: the Control Panel's drain derived its
correlation window from the project config file alone, ignoring the
``LINKWATCHER_MOVE_DETECT_DELAY`` environment override that the daemon merges
over that file value.

Why this matters: the window is how long the drain lets a daemon finish a
buffered move-correlation before terminating it (PD-BUG-136).  If the panel
derives a SHORTER window than the daemon is actually running with, it kills the
daemon mid-correlation and the reference update is silently dropped -- files stay
intact, so nothing looks wrong.  If it derives a LONGER one, the drain over-waits
and risks a needless FORCE_STOPPED.

What you are observing here is the *derivation*, which is the defect itself.  The
downstream consequence -- the dropped reference update -- is already demonstrated
end to end by PD-BUG-136_drain_correlation_window_validation.py; this script does
not repeat that drive.

Three numbers are printed per scenario:

  daemon effective  -- what main.py's load_config() actually resolves, i.e. what
                       the running daemon uses.  This is ground truth.
  panel derives     -- what lifecycle.read_correlation_window() returns now.
  pre-fix (file only) -- what the old hand-rolled YAML read returned, reproduced
                       here so the old wrong answer stays visible after the fix.

PASS means "panel derives" equals "daemon effective" in every scenario.  The
"pre-fix" column differing from ground truth in most scenarios is the point: it
is what this bug was.

The playground lives OUTSIDE the repo (C:/tmp) so the repository's own daemon
does not index it.

How to validate:

  python test/bug-validation/PD-BUG-142_correlation_window_env_override_validation.py

  No daemon needs to be running and nothing in the repo is touched.  The script
  sets LINKWATCHER_MOVE_DETECT_DELAY only inside its own process, never in your
  shell.

To see the failure with your own hands instead of trusting the table, set the
variable yourself before starting a daemon and a panel:

  $env:LINKWATCHER_MOVE_DETECT_DELAY = "30"

then start a daemon for any project whose linkwatcher-config.yaml omits
move_detect_delay, and confirm in the panel that a close drains for ~30 s rather
than ~10 s.  Before the fix it drained for ~10 s and could terminate a daemon
still holding a buffered correlation.
"""

from __future__ import annotations

import math
import os
import shutil
import sys
from pathlib import Path

REPO_SRC = Path(__file__).resolve().parents[2] / "src"
sys.path.insert(0, str(REPO_SRC))

import yaml  # noqa: E402

from linkwatcher.config import LinkWatcherConfig  # noqa: E402
from linkwatcher.linkwatcher_control_panel.lifecycle import (  # noqa: E402
    DEFAULT_MOVE_DETECT_DELAY_SECONDS,
    read_correlation_window,
)

PLAYGROUND = Path("C:/tmp/pd142-playground")
ENV_VAR = "LINKWATCHER_MOVE_DETECT_DELAY"


def daemon_effective(config_path: Path) -> float:
    """What the running daemon resolves -- main.py load_config()'s own chain."""
    config = LinkWatcherConfig()
    if config_path.is_file():
        config = config.merge(LinkWatcherConfig.from_file(str(config_path)))
    config = config.merge(LinkWatcherConfig.from_env())
    return float(config.move_detect_delay)


def pre_fix_file_only(config_path: Path) -> float:
    """The retired hand-rolled read, reproduced so the old answer stays visible."""
    try:
        data = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, yaml.YAMLError):
        return DEFAULT_MOVE_DETECT_DELAY_SECONDS
    if not isinstance(data, dict):
        return DEFAULT_MOVE_DETECT_DELAY_SECONDS
    raw = data.get("move_detect_delay")
    if isinstance(raw, bool) or not isinstance(raw, (int, float)):
        return DEFAULT_MOVE_DETECT_DELAY_SECONDS
    value = float(raw)
    if not math.isfinite(value) or value <= 0:
        return DEFAULT_MOVE_DETECT_DELAY_SECONDS
    return value


SCENARIOS = [
    ("config omits the key, env sets 30", None, "30"),
    ("config states the default 10, env sets 30", 10, "30"),
    ("config sets 25, env sets 30", 25, "30"),
    ("config sets 30, env sets 5 (reverse direction)", 30, "5"),
    ("config sets 25, env sets the default 10", 25, "10"),
    ("config sets 25, no env override", 25, None),
]


def main() -> int:
    if PLAYGROUND.exists():
        shutil.rmtree(PLAYGROUND)
    config_dir = PLAYGROUND / "tools" / "linkwatcher"
    config_dir.mkdir(parents=True)
    config_path = config_dir / "linkwatcher-config.yaml"

    print(f"\nPlayground: {PLAYGROUND}")
    print(f"Daemon default move_detect_delay: {LinkWatcherConfig().move_detect_delay} s")
    print(f"Panel fallback constant:          {DEFAULT_MOVE_DETECT_DELAY_SECONDS} s")
    print(
        "\n(The panel constant is now READ FROM the daemon's own config class, so the\n"
        " two lines above cannot drift apart -- that was TD294.)\n"
    )

    header = f"{'scenario':<46} {'daemon':>8} {'panel':>8} {'pre-fix':>9}  verdict"
    print(header)
    print("-" * len(header))

    failures = 0
    for label, file_value, env_value in SCENARIOS:
        body = "monitored_extensions:\n  - .md\n"
        if file_value is not None:
            body += f"move_detect_delay: {file_value}\n"
        config_path.write_text(body, encoding="utf-8")

        os.environ.pop(ENV_VAR, None)
        if env_value is not None:
            os.environ[ENV_VAR] = env_value
        try:
            truth = daemon_effective(config_path)
            panel = read_correlation_window(config_path)
            old = pre_fix_file_only(config_path)
        finally:
            os.environ.pop(ENV_VAR, None)

        agrees = math.isclose(panel, truth)
        if not agrees:
            failures += 1
        old_note = "same" if math.isclose(old, truth) else f"WRONG by {old - truth:+.0f}s"
        print(
            f"{label:<46} {truth:>8.1f} {panel:>8.1f} {old:>9.1f}  "
            f"{'OK' if agrees else 'MISMATCH'}  ({old_note})"
        )

    print()
    if failures:
        print(f"FAIL: the panel disagrees with the daemon in {failures} scenario(s).")
        print("PD-BUG-142 is present.")
    else:
        print("PASS: the panel derives the daemon's effective window in every scenario.")
        print("Note the pre-fix column: it is wrong wherever the override is active.")
        print(
            "\nAccepted residual: a daemon the panel ADOPTED (started outside the panel,\n"
            "from a different environment) is not covered -- the environment read here is\n"
            "the panel's own.  Recorded in TDD 4.4 beside the log-level residual."
        )

    shutil.rmtree(PLAYGROUND, ignore_errors=True)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
