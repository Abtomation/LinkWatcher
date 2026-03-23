---
id: TE-E2E-005
type: E2E Acceptance Test Case
group: TE-E2G-004
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
priority: P1
execution_mode: scripted
estimated_duration: 3 minutes
source: Cross-Cutting Spec PF-TSP-044, Scenario S-003
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-005 YAML Link Update on File Move

## Preconditions

- [ ] LinkWatcher is running and monitoring the workspace directory
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group yaml-json-python-parser-scenarios`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] The `moved/` subdirectory does NOT exist yet in the workspace project

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/config.yaml` | Main YAML config referencing the target file | Simple value, nested value, and array references to `data/settings.conf` |
| `project/pipeline.yaml` | Secondary YAML config with different nesting patterns | Deep-nested and anchor/alias references to `data/settings.conf` |
| `project/data/settings.conf` | Target file that will be moved | Simple configuration content |
| `project/data/schema.sql` | Non-moved file also referenced in YAML | Verifies only moved file references change |

## Steps

1. **Create destination directory**: Create a `moved/` directory inside `project/`
   - **Tool**: File Explorer or Command Line
   - **Target**: `project/moved/`

2. **Move the target file**: Move `project/data/settings.conf` into `project/moved/`
   - **Tool**: File Explorer (drag and drop) or Command Line
   - **Target**: `project/data/settings.conf` → `project/moved/settings.conf`

3. **Wait for LinkWatcher**: Allow time for file system events to be detected and processed
   - **Duration**: Wait 5–10 seconds
   - **Observe**: LinkWatcher log should show detection of the move and reference updates

4. **Verify YAML files updated**: Check that all YAML references to the moved file are updated
   - **Tool**: Text editor (open `config.yaml` and `pipeline.yaml`)
   - **Target**: All paths previously pointing to `data/settings.conf` should now point to `moved/settings.conf`

## Scripted Action

**Script**: `run.ps1`
**Action**: Creates `project/moved/` directory and moves `project/data/settings.conf` to `project/moved/settings.conf`

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `config.yaml` | Line 2 (simple value) | `config_file: data/settings.conf` | `config_file: moved/settings.conf` |
| `config.yaml` | Line 7 (nested value) | `config: data/settings.conf` | `config: moved/settings.conf` |
| `config.yaml` | Line 11 (array entry) | `  - data/settings.conf` | `  - moved/settings.conf` |
| `pipeline.yaml` | Line 5 (deep nested) | `source: data/settings.conf` | `source: moved/settings.conf` |
| `pipeline.yaml` | Line 9 (anchor value) | `config_file: data/settings.conf` | `config_file: moved/settings.conf` |

References to `data/schema.sql` must remain **unchanged** in both files (it was not moved).

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows detection of `data/settings.conf` move
- LinkWatcher log shows updates to `config.yaml` and `pipeline.yaml`
- No errors or warnings in LinkWatcher log

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-005` — compares workspace against `expected/`
- [ ] **Log check**: Check LinkWatcher log for move detection and update messages without errors

## Pass Criteria

- [ ] All 5 YAML references to `data/settings.conf` updated to `moved/settings.conf`
- [ ] All references to `data/schema.sql` remain unchanged
- [ ] YAML files remain valid YAML after updates
- [ ] `Verify-TestResult.ps1` reports all files match expected state
- [ ] No errors or warnings in LinkWatcher log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Save LinkWatcher log output as evidence

## Notes

- Tests simple values, nested values, arrays, deep nesting, and YAML anchors/aliases
- Known limitation: multiline YAML strings are not expected to have paths updated (xfail in unit tests)
- YAML comments containing file paths are NOT parsed by the YAML parser (by design — yaml.safe_load skips comments)
