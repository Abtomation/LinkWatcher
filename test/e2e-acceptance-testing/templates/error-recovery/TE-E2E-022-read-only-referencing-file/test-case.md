---
id: TE-E2E-022
type: E2E Acceptance Test Case
group: TE-E2G-011
feature_ids: ["0.1.1, 2.2.1, 3.1.1"]
workflow: WF-009
priority: P2
execution_mode: scripted
estimated_duration: 5 minutes
source: Cross-Cutting Spec PF-TSP-044 S-019
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-022 Read-Only Referencing File

## Preconditions

- [ ] LinkWatcher is running with `--project-root <workspace>/project`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group error-recovery`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] LinkWatcher has completed initial scan and is idle
- [ ] `project/docs/readme.md` has NOT yet been set to read-only (run.ps1 handles this)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/docs/readme.md` | Referencing file that will be set READ-ONLY before the move | Contains `[Schema](../data/schema.md)` and `[Guide](guide.md)` |
| `project/docs/guide.md` | Writable referencing file with a link to schema.md | Contains `[Schema](../data/schema.md)` |
| `project/data/schema.md` | Target file that will be moved | Contains schema documentation |

## Steps

1. **Start LinkWatcher**: Launch LinkWatcher against the workspace project directory
   - **Tool**: Command Line
   - **Command**: `python main.py --project-root <workspace>/project`

2. **Wait for initial scan**: Wait for LinkWatcher to complete the initial file scan
   - **Duration**: Wait 3-5 seconds for initial scan to complete
   - **Observe**: Log output confirming initial scan is done

3. **Set readme.md to read-only and move target file**: Execute run.ps1 which sets readme.md read-only, then moves schema.md
   - **Tool**: run.ps1 (scripted action)
   - **Target**: Sets `project/docs/readme.md` to read-only, then moves `project/data/schema.md` to `project/reference/schema.md`

4. **Wait for event processing**: Allow LinkWatcher to detect the move and attempt updates
   - **Duration**: Wait 3-5 seconds for file system events to propagate and update attempts
   - **Observe**: Log output showing update attempt on guide.md and error/warning for readme.md

5. **Verify guide.md was updated**: Open guide.md and confirm the link was updated
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/docs/guide.md` should contain `[Schema](../reference/schema.md)`

6. **Verify readme.md was NOT updated**: Open readme.md and confirm it still has the old link
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/docs/readme.md` should still contain `[Schema](../data/schema.md)`

7. **Check log for error message**: Verify the log contains a warning/error about the failed update to readme.md
   - **Tool**: Log file or terminal output
   - **Observe**: Error or warning message mentioning readme.md and permission/read-only

## Scripted Action

**Script**: `run.ps1`
**Action**: Sets project/docs/readme.md to read-only, creates reference/ directory, then moves project/data/schema.md to project/reference/schema.md

## Expected Results

### File Changes

| File | Expected State |
|------|---------------|
| `project/docs/guide.md` | UPDATED — link changed from `[Schema](../data/schema.md)` to `[Schema](../reference/schema.md)` |
| `project/docs/readme.md` | UNCHANGED — still contains `[Schema](../data/schema.md)` (read-only, write blocked) |
| `project/reference/schema.md` | EXISTS — file was moved from data/ |
| `project/data/schema.md` | DELETED — file was moved away |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- Log contains error or warning about failure to update readme.md (mentioning permission denied, read-only, or access error)
- Log confirms successful update of guide.md
- LinkWatcher does NOT crash — continues running after the write failure
- LinkWatcher processes subsequent events normally (not stuck in error state)

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-022` — compares workspace against `expected/`
- [ ] **Log check**: Check application log for error/warning about readme.md and successful update of guide.md

## Pass Criteria

- [ ] `project/docs/guide.md` contains updated link `[Schema](../reference/schema.md)`
- [ ] `project/docs/readme.md` still contains original link `[Schema](../data/schema.md)` (unchanged due to read-only)
- [ ] `project/reference/schema.md` exists with the original schema content
- [ ] Application log contains an error or warning message about failing to update readme.md
- [ ] LinkWatcher process remains running after the error (no crash)

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- After test execution, the read-only attribute on readme.md should be cleared to avoid issues with workspace cleanup. The test orchestrator or cleanup script should handle: `Set-ItemProperty "project/docs/readme.md" -Name IsReadOnly -Value $false`
- This test validates graceful error handling: LinkWatcher should update what it can, log what it cannot, and continue operating.
- If LinkWatcher crashes on the PermissionError, this is a critical resilience bug.
- If LinkWatcher skips updating guide.md because readme.md failed, this indicates an incorrect "fail-all" behavior instead of the expected "best-effort" behavior.
