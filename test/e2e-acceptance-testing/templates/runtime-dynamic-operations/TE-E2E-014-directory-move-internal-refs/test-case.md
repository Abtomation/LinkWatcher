---
id: TE-E2E-014
type: E2E Acceptance Test Case
group: TE-E2G-005
feature_ids: ["1.1.1", "0.1.2", "2.1.1", "2.2.1"]
workflow: WF-002
priority: P2
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044, Scenario S-010
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-014 Directory Move — Internal References Preserved

## Preconditions

- [ ] LinkWatcher is **stopped** before workspace setup
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group runtime-dynamic-operations -Clean`
- [ ] LinkWatcher is **started** after setup (fresh scan indexes README.md references)
- [ ] Wait 5 seconds for initial scan to complete
- [ ] The directory `components/` does NOT exist yet in the workspace project (it will be created by the test)

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/README.md` | External file referencing files inside the directory | Contains links to `components/index.md` and `components/overview.md` |

## Steps

1. **Create the directory with internally-referencing files**: Create `components/` directory with `index.md`, `overview.md`, and `utils.md` — where `index.md` references its siblings via relative paths
   - **Tool**: Command Line or File Explorer
   - **Target**: `project/components/index.md`, `project/components/overview.md`, `project/components/utils.md`

2. **Wait for LinkWatcher to scan**: Allow time for LW to detect and index all new files
   - **Duration**: Wait 5 seconds
   - **Observe**: LinkWatcher log should show detection of all 3 new files

3. **Move the directory**: Move `project/components/` to `project/modules/`
   - **Tool**: File Explorer (drag and drop) or Command Line
   - **Target**: `project/components/` → `project/modules/`

4. **Wait for LinkWatcher to process**: Allow time for directory move detection and reference updates
   - **Duration**: Wait 5–10 seconds
   - **Observe**: LinkWatcher log should show directory move detection and updates to README.md, but NOT modifications to the internal sibling references

5. **Verify external references updated**: Check that README.md now points to files under `modules/`
   - **Tool**: Text editor
   - **Target**: Open `README.md` and check link targets

6. **Verify internal references preserved**: Check that `modules/index.md` still references siblings via unchanged relative paths
   - **Tool**: Text editor
   - **Target**: Open `modules/index.md` and confirm links are still `overview.md` and `utils.md` (not `modules/overview.md`)

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates `project/components/` with `index.md`, `overview.md`, and `utils.md` (containing internal sibling references), waits 5 seconds, then moves the directory to `project/modules/`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `README.md` | Line 3 | `[Component Index](components/index.md)` | `[Component Index](modules/index.md)` |
| `README.md` | Line 5 | `[Overview](components/overview.md)` | `[Overview](modules/overview.md)` |
| `modules/index.md` | Line 3 | `[Overview](overview.md)` | `[Overview](overview.md)` (**unchanged**) |
| `modules/index.md` | Line 5 | `[Utils](utils.md)` | `[Utils](utils.md)` (**unchanged**) |
| `modules/overview.md` | Line 3 | `[Back to Index](index.md)` | `[Back to Index](index.md)` (**unchanged**) |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of new files in `components/`
- LinkWatcher log shows directory move detection from `components/` to `modules/`
- LinkWatcher log shows update to `README.md` for external references
- Internal sibling references in `index.md` and `overview.md` are NOT modified (relative paths between siblings remain valid after a same-level directory move)
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-014` — compares workspace against `expected/`
- [ ] **Log check**: Check LinkWatcher log for directory move detection and that only external references were updated

## Pass Criteria

- [ ] External references in README.md updated from `components/` paths to `modules/` paths
- [ ] Internal sibling references in `modules/index.md` remain as `overview.md` and `utils.md` (not prefixed with directory name)
- [ ] Internal back-reference in `modules/overview.md` remains as `index.md`
- [ ] All 3 files exist at `modules/` with correct content
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output as evidence

## Notes

- This test validates that LinkWatcher correctly distinguishes between external references (which need updating) and internal sibling references (which remain valid after a directory move)
- Internal references use sibling-relative paths (e.g., `overview.md` not `components/overview.md`), so they remain valid regardless of where the containing directory is located
- Complements S-008 (TE-E2E-009) and S-009 (TE-E2E-013) which focus on external reference updates
