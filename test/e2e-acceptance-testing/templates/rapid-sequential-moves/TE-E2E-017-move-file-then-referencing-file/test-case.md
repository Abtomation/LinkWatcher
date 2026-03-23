---
id: TE-E2E-017
type: E2E Acceptance Test Case
group: TE-E2G-007
feature_ids: ["1.1.1, 0.1.2, 2.2.1"]
workflow: WF-004
priority: P2
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044 S-014
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-017 Move File Then Move Referencing File

## Preconditions

- [ ] LinkWatcher is running and monitoring the workspace project directory
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group rapid-sequential-moves`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] Neither `project/archive/` nor `project/guides/` directories exist yet

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/docs/readme.md` | Referencing file (will also be moved) | Contains link `[Config](../config/settings.md)` |
| `project/config/settings.md` | Referenced file (moved first) | `# Settings` with description |

## Steps

1. **Start LinkWatcher**: Ensure LinkWatcher is running and monitoring the workspace project directory
   - **Tool**: Command Line
   - **Target**: `python main.py` pointed at the workspace

2. **Wait for initial scan**: Allow LinkWatcher to complete its startup scan
   - **Duration**: Wait 3-5 seconds
   - **Observe**: Log output confirming initial scan is complete

3. **Move referenced file**: Move `project/config/settings.md` to `project/archive/settings.md`
   - **Tool**: Command Line / File Explorer
   - **Target**: `project/config/settings.md` -> `project/archive/settings.md`

4. **Wait briefly**: Allow partial processing before the second move
   - **Duration**: Wait 500ms
   - **Observe**: LinkWatcher may begin processing the first move

5. **Move referencing file**: Move `project/docs/readme.md` to `project/guides/readme.md`
   - **Tool**: Command Line / File Explorer
   - **Target**: `project/docs/readme.md` -> `project/guides/readme.md`

6. **Wait for processing**: Allow LinkWatcher to detect and process both moves
   - **Duration**: Wait 3-5 seconds for all file system events to process
   - **Observe**: Log output showing detection of both moves and link re-adjustment

7. **Verify results**: Check that the final `guides/readme.md` has the correct relative link to `archive/settings.md`
   - **Tool**: Text editor
   - **Target**: `project/guides/readme.md`

## Scripted Action

**Script**: `run.ps1`
**Action**: Moves `project/config/settings.md` to `project/archive/settings.md`, waits 500ms, then moves `project/docs/readme.md` to `project/guides/readme.md`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `guides/readme.md` | Config link | `[Config](../config/settings.md)` | `[Config](../archive/settings.md)` |

The link path from `guides/` to `archive/` is `../archive/settings.md`. Both `docs/` and `guides/` are sibling directories at the project root, so the relative path to `archive/settings.md` is the same from either location.

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of `config/settings.md` move to `archive/settings.md`
- LinkWatcher log shows link update in `docs/readme.md` (first adjustment)
- LinkWatcher log shows detection of `docs/readme.md` move to `guides/readme.md`
- LinkWatcher log shows link re-adjustment in `guides/readme.md` if needed (second adjustment)
- Final state of `guides/readme.md` has correct relative path regardless of processing order

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-017` — compares workspace against `expected/`
- [ ] **Log check**: Check application log for detection of both moves

## Pass Criteria

- [ ] `guides/readme.md` contains `[Config](../archive/settings.md)` (correct relative path from final location)
- [ ] `archive/settings.md` exists with original content
- [ ] `docs/readme.md` no longer exists (was moved to `guides/`)
- [ ] `config/settings.md` no longer exists (was moved to `archive/`)
- [ ] No errors or warnings in application log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- This test validates that LinkWatcher correctly handles the case where both a referenced file and its referencing file are moved in rapid succession.
- The key challenge is that LinkWatcher must either: (a) update the link after the first move and re-adjust after the second, or (b) compute the correct final relative path considering both moves. Either approach should produce the correct result.
- In this specific case, `docs/` and `guides/` are both siblings of `archive/`, so the relative path `../archive/settings.md` happens to be the same from both locations.
