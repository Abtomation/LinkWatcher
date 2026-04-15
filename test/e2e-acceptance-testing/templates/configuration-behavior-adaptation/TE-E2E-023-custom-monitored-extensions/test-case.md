---
id: TE-E2E-023
type: E2E Acceptance Test Case
group: TE-E2G-012
feature_ids: ["0.1.3", "1.1.1", "3.1.1"]
workflow: WF-006
priority: P3
execution_mode: scripted
estimated_duration: 5 minutes
source: WF-006 user-workflow-tracking
lw_flags: "--config <workspace>/project/config.yaml"
created: 2026-04-12
updated: 2026-04-12
---

# Test Case: TE-E2E-023 Custom Monitored Extensions

## Preconditions

- [ ] LinkWatcher is installed and available via `python main.py`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group configuration-behavior-adaptation`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] LinkWatcher started with `--config <workspace>/project/config.yaml --project-root <workspace>/project`

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/config.yaml` | Config restricting monitored_extensions to `.md` only | `monitored_extensions: [".md"]` |
| `project/docs/readme.md` | Monitored file with link to api-guide.md | `[API Guide](api-guide.md)` |
| `project/docs/references.yaml` | Unmonitored file with path to api-guide.md | `api_guide: "docs/api-guide.md"` |
| `project/docs/api-guide.md` | Target file that will be moved | API documentation content |

## Steps

1. **Start LinkWatcher**: Launch with the restrictive config
   - **Tool**: Command Line
   - **Command**: `python main.py --config <workspace>/project/config.yaml --project-root <workspace>/project`

2. **Wait for initial scan**: Wait for LinkWatcher to index monitored files
   - **Duration**: Wait 3-5 seconds for initial scan to complete
   - **Observe**: Log output confirming initial scan — only `.md` files should be scanned

3. **Move the target file**: Move api-guide.md to archive/
   - **Tool**: run.ps1 (scripted action)
   - **Target**: `project/docs/api-guide.md` moves to `project/archive/api-guide.md`

4. **Wait for event processing**: Allow LinkWatcher to detect and process the move
   - **Duration**: Wait 3-5 seconds for file system events to propagate
   - **Observe**: Log output showing move detection and link update in readme.md

5. **Verify readme.md IS updated**: The `.md` file link should be updated
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/docs/readme.md` should now contain `[API Guide](../archive/api-guide.md)`

6. **Verify references.yaml is NOT updated**: The `.yaml` file path should remain unchanged
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: `project/docs/references.yaml` should still contain `api_guide: "docs/api-guide.md"`

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates archive/ directory and moves project/docs/api-guide.md to project/archive/api-guide.md

## Expected Results

### File Changes

| File | Expected State |
|------|---------------|
| `project/docs/readme.md` | UPDATED — link changed from `[API Guide](api-guide.md)` to `[API Guide](../archive/api-guide.md)` |
| `project/docs/references.yaml` | UNCHANGED — still contains `api_guide: "docs/api-guide.md"` (YAML not monitored) |
| `project/archive/api-guide.md` | EXISTS — file was physically moved |
| `project/docs/api-guide.md` | DELETED — file was moved away |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- Log shows move detection for api-guide.md
- Log shows link update in readme.md (monitored `.md` file)
- Log does NOT show any scan or update activity for references.yaml (unmonitored `.yaml` file)
- LinkWatcher continues running without errors

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-023` — compares workspace against `expected/`
- [ ] **Log check**: Confirm log mentions readme.md update but NOT references.yaml

## Pass Criteria

- [ ] `project/docs/readme.md` contains updated link `[API Guide](../archive/api-guide.md)`
- [ ] `project/docs/references.yaml` still contains original path `api_guide: "docs/api-guide.md"` (unchanged)
- [ ] `project/archive/api-guide.md` exists (file was physically moved)
- [ ] No errors or warnings in application log during test execution

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- This test validates that `monitored_extensions` config actually controls which file types LinkWatcher scans and updates.
- The `.yaml` file is present on disk but should be invisible to LinkWatcher because `.yaml` is not in the configured `monitored_extensions` list.
- If the `.yaml` file IS updated, the `monitored_extensions` filtering is broken.
