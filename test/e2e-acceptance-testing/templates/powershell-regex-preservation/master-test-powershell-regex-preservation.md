# Master Test: powershell-regex-preservation

## Metadata

| Field | Value |
|-------|-------|
| Group ID | E2E-GRP-01 |
| Feature | 2.1.1 — Link Parsing System |
| Test Cases Covered | 1 |
| Estimated Duration | 5 minutes |
| Created | 2026-03-15 |
| Last Updated | 2026-03-15 |

## Purpose

Quick validation that regex patterns in PowerShell scripts are not corrupted when the file is moved, while real file path references are correctly updated. Covers PD-BUG-033.

## Preconditions

- [ ] LinkWatcher is running in background (`LinkWatcher/start_linkwatcher_background.ps1`)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group powershell-regex-preservation`
- [ ] Workspace contains pristine copies of all test fixtures

## Quick Validation Sequence

1. **Move PS1 script with regex patterns to a subdirectory**
   - Action: Move `scripts/update/Update-Tracking.ps1` to `scripts/update/sub/Update-Tracking.ps1`
   - Tool: File Explorer (drag and drop)
   - Target: `workspace/scripts/update/Update-Tracking.ps1`
   - Expected: LinkWatcher detects the move and updates links

2. **Verify regex patterns are unchanged and real path is updated**
   - Action: Open the moved file and inspect content
   - Tool: Text editor or `Verify-TestResult.ps1 -Group powershell-regex-preservation`
   - Target: `workspace/scripts/update/sub/Update-Tracking.ps1`
   - Expected: All three regex patterns (`\d+`, `\[x\]\s+`, `(ART-ASS-\d+)`) are byte-identical to original; real path changed from `"../Common-Helpers.psm1"` to `"../../Common-Helpers.psm1"`

## Pass Criteria

- [ ] All regex patterns in the moved file are identical to the original
- [ ] The real file path `"../Common-Helpers.psm1"` is updated to `"../../Common-Helpers.psm1"`
- [ ] No errors in LinkWatcher log
- [ ] Run `Verify-TestResult.ps1 -Group powershell-regex-preservation` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| E2E-001 | [E2E-001-regex-preserved-on-file-move/test-case.md](E2E-001-regex-preserved-on-file-move/test-case.md) | Verify regex patterns in PS1 files are not rewritten when the file is moved, while real paths are still updated |

## Notes

- This group validates the PD-BUG-033 fix in `_calculate_updated_relative_path()` in `reference_lookup.py`
- The fix checks `os.path.exists()` before rewriting a target — regex patterns resolve to non-existent paths, so they are skipped
