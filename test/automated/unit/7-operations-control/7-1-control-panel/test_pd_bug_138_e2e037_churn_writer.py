"""
Document Metadata:
ID: TE-TST-156
Type: Test File
Category: Test
Version: 1.0
Created: 2026-08-25
Updated: 2026-08-25
Component Name: TE-E2E-037-action
Feature Id: 7.1.1
Language: Python
Test Name: pd-bug-138 e2e037 churn writer
Test Type: Unit

PD-BUG-138 regression: the TE-E2E-037 fixture's churn writer must actually
produce churn, and must fail LOUDLY when it does not.

TE-E2E-037 verifies AC-9 — the Control Panel force-terminates a daemon that never
reaches quiescence. The whole case depends on `action.ps1` keeping the sandbox
daemon continuously busy. In the buggy version the detached writer was launched as

    Start-Process pwsh.exe -ArgumentList @('-NoProfile', ..., '-Command', $inner)

`-ArgumentList` space-joins its elements *without quoting*, so the payload's own
double quotes were consumed as argument delimiters and re-joined by the child. The
markdown link inside the churn body then parsed as a type literal
("Missing ] at end of attribute or type literal"), the child exited 1, and
`-WindowStyle Hidden` plus an unchecked exit code made that completely silent. The
script still printed "Churn writer started", so the daemon went quiet, the drain
completed normally, and the case PASSED while proving nothing about AC-9.

Two contracts are pinned here:
  1. churn is genuinely produced, and keeps being produced (test_churn_*)
  2. producing no churn is a hard, visible failure (test_no_churn_*)

Contract 2 is the one that matters most: without it, any future breakage of the
launch mechanism goes silent again and the case becomes a no-op that reports
success — which is how this fixture reached "Audit Approved" while being inert.
"""

import shutil
import subprocess
import time
from pathlib import Path

import pytest

# parents: [0]=7-1-control-panel [1]=7-operations-control [2]=unit [3]=automated
#          [4]=test [5]=repo root
PROJECT_ROOT = Path(__file__).resolve().parents[5]
ACTION = (
    PROJECT_ROOT
    / "test"
    / "e2e-acceptance-testing"
    / "manage-running-linkwatcher-instances-via-control-panel"
    / "templates"
    / "TE-E2E-037-forced-terminate-on-grace-expiry"
    / "action.ps1"
)

pytestmark = [
    pytest.mark.feature("7.1.1"),
    pytest.mark.priority("Standard"),
    pytest.mark.test_type("unit"),
]


def _pwsh():
    exe = shutil.which("pwsh") or shutil.which("pwsh.exe")
    if not exe:
        pytest.skip("pwsh not available — the fixture under test is PowerShell")
    return exe


def _make_workspace(tmp_path: Path) -> Path:
    """Minimal stand-in for the seeded TE-E2E-037 workspace.

    action.ps1 only requires project/sandbox-a to exist; the witness files are
    included so the fixture shape matches the real one.
    """
    sandbox = tmp_path / "project" / "sandbox-a"
    (sandbox / "notes").mkdir(parents=True)
    (sandbox / "docs").mkdir(parents=True)
    (sandbox / "notes" / "setup.md").write_text("# Setup\n", encoding="utf-8")
    (sandbox / "docs" / "guide.md").write_text(
        "[Setup Notes](../notes/setup.md)\n", encoding="utf-8"
    )
    return tmp_path


def _run_action(workspace: Path, *extra_args, timeout=60):
    return subprocess.run(
        [
            _pwsh(),
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ACTION),
            "-WorkspacePath",
            str(workspace),
            *extra_args,
        ],
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def _churn_files(workspace: Path):
    churn_dir = workspace / "project" / "sandbox-a" / "churn"
    if not churn_dir.is_dir():
        return []
    return sorted(churn_dir.glob("churn-*.md"))


def _churn_snapshot(workspace: Path):
    """(name, size, mtime_ns) per churn file — changes on every write."""
    return {(f.name, f.stat().st_size, f.stat().st_mtime_ns) for f in _churn_files(workspace)}


class TestE2E037ChurnWriter:
    """PD-BUG-138: the churn writer must work, and must not fail silently."""

    def test_churn_writer_actually_produces_continuous_churn(self, tmp_path):
        """THE regression: churn must appear on disk and keep advancing.

        Buggy version: the detached pwsh died on a parse error before its first
        write, so the churn directory stayed empty forever while the script
        reported success.
        """
        workspace = _make_workspace(tmp_path)
        result = _run_action(workspace, "-DurationSeconds", "30")
        try:
            assert result.returncode == 0, (
                f"action.ps1 failed to start the writer:\n"
                f"stdout={result.stdout}\nstderr={result.stderr}"
            )

            # The writer touches a file every 400 ms; allow generous margin.
            deadline = time.time() + 10
            while time.time() < deadline and not _churn_files(workspace):
                time.sleep(0.25)

            produced = _churn_files(workspace)
            assert produced, (
                "no churn files were written — the detached writer never ran.\n"
                f"stdout={result.stdout}\nstderr={result.stderr}"
            )

            # Still writing: a single lucky file is not enough, the daemon must be
            # kept busy continuously or quiescence is reached and AC-9 is untested.
            first = _churn_snapshot(workspace)
            time.sleep(2.0)
            second = _churn_snapshot(workspace)
            assert second != first, (
                "churn stopped advancing — the writer died after its first write; "
                "the daemon would reach quiescence and AC-9 would not be exercised"
            )
        finally:
            _run_action(workspace, "-Stop")

    def test_no_churn_is_reported_as_a_hard_failure(self, tmp_path):
        """The silent-success half of the bug.

        `-DurationSeconds 0` makes the writer exit before writing anything — the
        same end state the parse error produced. The script must NOT claim the
        writer started; it must exit non-zero and leave no PID file behind.
        """
        workspace = _make_workspace(tmp_path)
        result = _run_action(workspace, "-DurationSeconds", "0")

        assert not _churn_files(workspace), "precondition: this run writes no churn"

        # Strong negative assertion: the success claim must be absent, not merely
        # accompanied by a warning somewhere.
        assert "Churn writer started" not in result.stdout, (
            "action.ps1 reported success for a writer that produced no churn — "
            "this is exactly the silent no-op PD-BUG-138 is about.\n"
            f"stdout={result.stdout}"
        )
        assert result.returncode != 0, (
            "action.ps1 exited 0 despite producing no churn.\n"
            f"stdout={result.stdout}\nstderr={result.stderr}"
        )

        # A dead writer's PID file blocks the next run with "already recorded".
        assert not (workspace / "churn.pid").exists(), (
            "a PID file was left behind for a writer that never ran — the operator "
            "must run -Stop before retrying, for a writer that does not exist"
        )

    def test_stop_is_safe_when_no_writer_was_started(self, tmp_path):
        """Boundary: -Stop on a pristine workspace is a no-op, not an error."""
        workspace = _make_workspace(tmp_path)
        result = _run_action(workspace, "-Stop")

        assert result.returncode == 0, f"-Stop errored: {result.stderr}"
        assert "nothing to stop" in result.stdout.lower()
