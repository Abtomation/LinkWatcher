---
id: TE-E2E-021
type: E2E Acceptance Test Case
group: TE-E2G-010
feature_ids: ["0.1.1, 2.2.1, 0.1.2"]
workflow: WF-008
priority: P2
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044 S-018
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-021 Stop Immediately After File Move

## Preconditions

- [ ] LinkWatcher is running with `--project-root <workspace>/project`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group graceful-shutdown`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] LinkWatcher has completed initial scan and is idle

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/docs/readme.md` | Referencing file with a link to report.md | Contains `[Report](report.md)` |
| `project/docs/report.md` | Target file that will be moved | Contains report content |

## Steps

1. **Start LinkWatcher**: Launch LinkWatcher against the workspace project directory
   - **Tool**: Command Line
   - **Command**: `python main.py --project-root <workspace>/project`

2. **Wait for idle state**: Wait for LinkWatcher to complete the initial file scan
   - **Duration**: Wait 3-5 seconds for initial scan to complete
   - **Observe**: Log output confirming initial scan is done

3. **Move the target file**: Move report.md from docs/ to a new archive/ directory
   - **Tool**: run.ps1 (scripted action)
   - **Target**: `project/docs/report.md` moves to `project/archive/report.md`

4. **Immediately stop LinkWatcher**: Send stop signal as quickly as possible after the move (within 100ms)
   - **Tool**: Test orchestrator or Command Line
   - **Target**: The running LinkWatcher process

5. **Verify file integrity**: Check that readme.md is in one of two valid states (fully updated OR completely untouched)
   - **Tool**: `Verify-TestResult.ps1` or manual inspection
   - **Target**: `project/docs/readme.md`

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates archive/ directory, moves project/docs/report.md to project/archive/report.md, then waits 100ms before returning (stop signal follows immediately from orchestrator)

## Expected Results

### File Changes — Two Valid Outcomes

This test has TWO valid outcomes due to the race condition between the stop signal and the update operation. Both are acceptable:

**Outcome A (update completed before stop)**:

| File | Expected State |
|------|---------------|
| `project/docs/readme.md` | UPDATED — contains `[Report](../archive/report.md)` |
| `project/archive/report.md` | EXISTS — file was moved |

**Outcome B (stop arrived before update)**:

| File | Expected State |
|------|---------------|
| `project/docs/readme.md` | UNCHANGED — still contains `[Report](report.md)` |
| `project/archive/report.md` | EXISTS — file was moved |

The `expected/` directory contains Outcome A (the fully updated state). The verifier must also accept Outcome B as a valid pass.

**NOT acceptable**: Partial update, corrupted content, truncated file, or missing content in readme.md.

### Behavioral Outcomes

- LinkWatcher process exits cleanly (no crash, no hang)
- No error messages or stack traces in the log
- readme.md is in exactly one of the two valid states described above

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-021` — compares workspace against `expected/` (accepts Outcome A)
- [ ] **Manual fallback**: If automated comparison fails, manually check if readme.md matches Outcome B (unchanged link) — this is also a valid pass
- [ ] **Log check**: Check application log for absence of errors, exceptions, or corruption warnings

## Pass Criteria

- [ ] `project/docs/readme.md` contains EITHER `[Report](../archive/report.md)` (Outcome A) OR `[Report](report.md)` (Outcome B) — no other content is acceptable
- [ ] `project/docs/readme.md` is not corrupted: file is valid UTF-8, contains expected markdown structure, and has no truncation
- [ ] `project/archive/report.md` exists and contains the original report content
- [ ] No error messages or stack traces in application log
- [ ] LinkWatcher process exited without hanging (within reasonable timeout)

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- If readme.md contains partial/corrupted content, this is a critical atomicity bug — create a bug report immediately
- Take screenshots or save log output as evidence

## Notes

- This test validates the atomicity guarantee: link updates must be all-or-nothing. A partially written file is never acceptable.
- The `expected/` directory provides Outcome A (fully updated). When running `Verify-TestResult.ps1`, a mismatch on readme.md alone does NOT automatically fail the test — the verifier or human must check for Outcome B.
- The timing of this test is inherently non-deterministic. Either outcome is correct; the important thing is that no partial/corrupt state is ever produced.
- If this test consistently produces Outcome B (never updates), it may indicate that the shutdown is too aggressive. This is not a failure but worth noting for tuning.
