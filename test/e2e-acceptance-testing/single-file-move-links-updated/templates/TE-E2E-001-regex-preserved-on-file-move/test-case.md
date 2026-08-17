---
id: TE-E2E-001
description: "E2E acceptance test (WF-001): TE-E2E-001 regex preserved on file move."
type: Testing
category: E2E Acceptance Test Case
group: TE-E2G-001
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
priority: P1
execution_mode: scripted
estimated_duration: 5 minutes
source: Bug Report PD-BUG-033
created: 2026-03-15
updated: 2026-03-15
---

# Test Case: TE-E2E-001 regex preserved on file move

## Preconditions

- [ ] No LinkWatcher instance is watching the workspace — `run.ps1` starts and stops its own workspace-scoped instance via `_lib/lw-e2e-helpers.ps1` (do **not** use `start_linkwatcher_background.ps1`; it ignores `--project-root` and watches the repo root — PD-BUG-053)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow single-file-move-links-updated`
- [ ] Workspace contains pristine copy of this test case's fixtures

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/scripts/update/Update-Tracking.ps1` | PowerShell script with regex patterns and a real path reference | Three regex patterns (`\d+`, `\[x\]`, `\s+`) plus one real file reference (`../Common-Helpers.psm1`) |
| `project/scripts/Common-Helpers.psm1` | Real file that the script references | Minimal module (ensures the real path resolves on disk) |

## Steps

1. **Set up workspace**: Run `Setup-TestEnvironment.ps1 -Workflow single-file-move-links-updated` to copy fixtures into the workspace
   - **Tool**: Command Line
   - **Target**: `process-framework/scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1`

2. **Move the script to a subdirectory**: Drag `Update-Tracking.ps1` from `scripts/update` into a new subdirectory `scripts/update/sub/`
   - **Tool**: File Explorer or VS Code
   - **Target**: `workspace/scripts/update/Update-Tracking.ps1` → `workspace/scripts/update/sub/Update-Tracking.ps1`

3. **Wait**: Allow LinkWatcher to detect the move and process updates
   - **Duration**: Wait ~12 seconds — the move is detected by delete+create correlation, whose window (`move_detect_delay`) defaults to 10s; `Wait-LinkWatcherSettle` uses 12s
   - **Observe**: LinkWatcher log should show the file move detection

4. **Verify the moved file**: Open `workspace/scripts/update/sub/Update-Tracking.ps1` in a text editor
   - **Tool**: VS Code or any text editor
   - **Target**: `workspace/scripts/update/sub/Update-Tracking.ps1`

5. **Compare against expected state**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-001 -Workflow single-file-move-links-updated` or manually compare the file content against `expected/scripts/update/sub/Update-Tracking.ps1`
   - **Tool**: Command Line or visual diff
   - **Target**: Compare workspace file with expected/ file

## Expected Results

### File Changes

| File | Line/Section | Before (original) | After (moved to sub/) |
|------|-------------|--------|-------|
| `Update-Tracking.ps1` | Line 2 (regex `\d+`) | `'ART-ASS-\d+-([0-9]+\.[0-9]+\.[0-9]+)-'` | `'ART-ASS-\d+-([0-9]+\.[0-9]+\.[0-9]+)-'` **(UNCHANGED)** |
| `Update-Tracking.ps1` | Line 5 (regex `\[x\]`) | `'\[x\]\s+Tier\s+(\d+)'` | `'\[x\]\s+Tier\s+(\d+)'` **(UNCHANGED)** |
| `Update-Tracking.ps1` | Line 8 (regex `\d+`) | `'(ART-ASS-\d+)-'` | `'(ART-ASS-\d+)-'` **(UNCHANGED)** |
| `Update-Tracking.ps1` | Line 11 (real path) | `"../Common-Helpers.psm1"` | `"../../Common-Helpers.psm1"` **(UPDATED — one more `../`)** |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows the file move was detected
- Log shows `moved_file_links_updated` for `Update-Tracking.ps1` with `links_updated=1` — only the real path was rewritten (regex targets do not exist on disk, so they are skipped)
- No errors or warnings about regex pattern targets

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-001 -Workflow single-file-move-links-updated` — compares workspace against `expected/` (`-TestCase` without `-Workflow` is rejected)
- [ ] **Visual inspection**: Open the moved file and confirm all three regex patterns are byte-identical to the original, and the real path gained an extra `../`

## Pass Criteria

- [ ] Regex pattern `'ART-ASS-\d+-([0-9]+\.[0-9]+\.[0-9]+)-'` is unchanged after move
- [ ] Regex pattern `'\[x\]\s+Tier\s+(\d+)'` is unchanged after move
- [ ] Regex pattern `'(ART-ASS-\d+)-'` is unchanged after move
- [ ] Real path `"../Common-Helpers.psm1"` is updated to `"../../Common-Helpers.psm1"`
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save the corrupted file content as evidence

## Notes

- This test case reproduces the exact patterns from `Update-FeatureTrackingFromAssessment.ps1` that were corrupted in PD-BUG-033
- The fix is in `_calculate_updated_relative_path()` in `reference_lookup.py` — it checks `os.path.exists()` before rewriting a target
- Regex patterns resolve to non-existent paths on disk, so they are skipped
