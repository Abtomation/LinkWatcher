---
id: TE-E2E-029
type: E2E Acceptance Test Case
group: TE-E2G-005
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
priority: P1
execution_mode: scripted
estimated_duration: 3 minutes
source: Bug Report PD-BUG-102
expected_exit_code: 0
created: 2026-06-12
updated: 2026-06-12
---

# Test Case: TE-E2E-029 External Edit Then Move

## Preconditions

- [ ] LinkWatcher is **stopped** before workspace setup, then **started** after setup (fresh scan)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Workflow single-file-move-links-updated`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] `notes.md` exists at startup scan time and does NOT yet contain a link to `docs/target.md` (the link is written mid-test by an "external tool")

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/notes.md` | Existing monitored file that receives a link mid-test | No reference to `docs/target.md` at startup |
| `project/docs/target.md` | Target file that gets linked and then moved | `# Target Document` heading and body text |

## Steps

1. **Wait for initial scan to complete**: LinkWatcher must finish its startup scan so the mid-test edit arrives as a live modify event
   - **Tool**: LinkWatcher log
   - **Target**: `initial_scan_complete` entry in `linkwatcher-e2e.log`

2. **Write a link into the existing file**: Simulating an external tool (e.g., a PowerShell automation script), append a markdown link to `docs/target.md` into `notes.md`
   - **Tool**: Command Line (`Add-Content`) — must NOT be LinkWatcher itself
   - **Target**: Append `See the [Target](docs/target.md) document.` to `project/notes.md`

3. **Wait for the modify event to be indexed**: The on_modified handler must rescan `notes.md` and add the fresh link to the in-memory database
   - **Duration**: Wait 5 seconds
   - **Observe**: LinkWatcher log shows `file_links_scanned` for `notes.md` with `link_count` ≥ 1

4. **Move the target file**: Move `project/docs/target.md` to `project/archive/target.md`
   - **Tool**: Command Line (`Move-Item`) or File Explorer
   - **Target**: `project/docs/target.md` → `project/archive/target.md`

5. **Wait for LinkWatcher to process**: Allow time for move detection (delete+create correlation window is 10s) and reference updates
   - **Duration**: Wait 12 seconds
   - **Observe**: LinkWatcher log shows move detection and reference update for `notes.md`

6. **Verify the fresh link was rewritten**: Check that the link written mid-test now points to the new location
   - **Tool**: Text editor
   - **Target**: `project/notes.md` link target reads `archive/target.md`

## Scripted Action

**Script**: `run.ps1`
**Action**: Waits for initial scan completion, appends a link to `docs/target.md` into the existing `notes.md`, waits for the modify-event rescan, then moves `docs/target.md` to `archive/target.md`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `notes.md` | Appended line | `See the [Target](docs/target.md) document.` | `See the [Target](archive/target.md) document.` |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows `file_links_scanned` for `notes.md` AFTER the mid-test edit (the on_modified rescan, PD-BUG-102 fix)
- LinkWatcher log shows move detection for `docs/target.md` → `archive/target.md`
- LinkWatcher log shows `file_moved` with `references_count` ≥ 1 — NOT the `no_references_found` warning (the PD-BUG-102 failure signature)
- LinkWatcher log shows a reference update applied to `notes.md`
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-029` — compares workspace against `expected/`
- [ ] **Log check**: Confirm `file_links_scanned` for `notes.md` after the edit, and absence of `no_references_found` after the move

## Pass Criteria

- [ ] The link appended into `notes.md` mid-test points to `archive/target.md` after the move
- [ ] `target.md` exists at `archive/target.md` with original content
- [ ] LinkWatcher log contains `file_links_scanned` for `notes.md` between the edit and the move (modify event was delivered and indexed)
- [ ] LinkWatcher log does NOT contain `no_references_found` for the move of `target.md`
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output (`linkwatcher-e2e.log`) as evidence

## Notes

- Regression guard for PD-BUG-102: before the fix, links written into an EXISTING monitored file by external tools were never indexed (no on_modified handler), so a later move of the link's target ran with `references_count=0` and left the link stale
- The 5 unit regression tests (TestModifyEventRescan in test_move_detection.py) use synthetic watchdog events; this E2E case verifies REAL watchdog modify-event delivery on Windows end-to-end
- The key difference from TE-E2E-008 (file create and move) is that here the REFERENCING file is touched mid-test rather than the target being created mid-test — exercising on_modified instead of on_created
- The edit must happen after `initial_scan_complete`; edits during the startup scan are deferred and replayed, which is a different code path (PD-BUG-053 pattern)
