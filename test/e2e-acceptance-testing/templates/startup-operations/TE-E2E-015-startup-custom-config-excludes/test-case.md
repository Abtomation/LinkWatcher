---
id: TE-E2E-015
type: E2E Acceptance Test Case
group: TE-E2G-006
feature_ids: ["0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1"]
workflow: WF-003
priority: P2
execution_mode: scripted
estimated_duration: 5 minutes
source: Cross-Cutting Spec PF-TSP-044 S-012
created: 2026-03-18
updated: 2026-03-18
---

# Test Case: TE-E2E-015 Startup with Custom Config Excludes

## Preconditions

- [ ] LinkWatcher is installed and available via `python main.py`
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group startup-operations`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] No other LinkWatcher instance is running on the workspace directory

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/config.yaml` | Custom config with excluded directory | `ignored_directories: ["excluded"]` |
| `project/docs/readme.md` | Markdown file with links to both excluded and non-excluded files | Link to `../excluded/api-ref.md` and `guide.md` |
| `project/docs/guide.md` | Non-excluded file that will be moved | `# Guide` |
| `project/excluded/api-ref.md` | File inside excluded directory | `# API Reference` |
| `project/excluded/notes.md` | Another file inside excluded directory with internal link | Link to `api-ref.md` |

## Steps

1. **Start LinkWatcher**: Launch LinkWatcher with the custom config pointing at the workspace project directory
   - **Tool**: Command Line
   - **Target**: `python main.py --config <workspace>/project/config.yaml`

2. **Wait for initial scan**: Allow LinkWatcher to complete its startup scan
   - **Duration**: Wait 3-5 seconds for initial scan to complete
   - **Observe**: Log output confirming scan is complete; verify no files from `excluded/` appear in scan output

3. **Move file**: Move `project/docs/guide.md` to `project/archive/guide.md`
   - **Tool**: Command Line / File Explorer
   - **Target**: `project/docs/guide.md` -> `project/archive/guide.md`

4. **Wait for processing**: Allow LinkWatcher to detect and process the move
   - **Duration**: Wait 3-5 seconds for file system events to process
   - **Observe**: Log output showing link update activity for `docs/readme.md`

5. **Stop LinkWatcher**: Terminate the LinkWatcher process
   - **Tool**: Command Line
   - **Target**: Send termination signal (Ctrl+C or process kill)

6. **Verify results**: Check that readme.md updated the guide link but NOT the excluded dir link
   - **Tool**: Text editor
   - **Target**: `project/docs/readme.md`, `project/excluded/notes.md`

## Scripted Action

**Script**: `run.ps1`
**Action**: Moves `project/docs/guide.md` to `project/archive/guide.md` while LinkWatcher is running with a config that excludes the `excluded/` directory

## Expected Results

### File Changes

| File | Line/Section | Before | After |
|------|-------------|--------|-------|
| `docs/readme.md` | Guide link | `[Guide](guide.md)` | `[Guide](../archive/guide.md)` |
| `docs/readme.md` | API Reference link | `[API Reference](../excluded/api-ref.md)` | `[API Reference](../excluded/api-ref.md)` (unchanged) |
| `excluded/api-ref.md` | Entire file | `# API Reference` | `# API Reference` (unchanged) |
| `excluded/notes.md` | Internal link | `[See API](api-ref.md)` | `[See API](api-ref.md)` (unchanged) |

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log shows initial scan completing WITHOUT scanning files in `excluded/` directory
- LinkWatcher log shows detection of `docs/guide.md` move to `archive/guide.md`
- LinkWatcher log shows update of `docs/readme.md` for the guide link
- No log entries referencing files inside `excluded/` directory during monitoring

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-015` — compares workspace against `expected/`
- [ ] **Log check**: Check application log to confirm no files from `excluded/` directory appear in scan or monitoring output

## Pass Criteria

- [ ] `docs/readme.md` contains `[Guide](../archive/guide.md)` (link updated for moved file)
- [ ] `docs/readme.md` contains `[API Reference](../excluded/api-ref.md)` (excluded dir link unchanged)
- [ ] `excluded/api-ref.md` is unchanged from its original content
- [ ] `excluded/notes.md` is unchanged from its original content
- [ ] `archive/guide.md` exists with original content
- [ ] LinkWatcher log contains no references to files in the `excluded/` directory
- [ ] No errors or warnings in application log during test execution

## Fail Actions

- Record the failure in test-tracking.md with status `Failed`
- Note which pass criterion failed and any observed error messages
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect
- Take screenshots or save log output as evidence

## Notes

- The `ignored_directories` config field accepts directory names (not paths). Any directory matching the name at any depth is excluded.
- This test validates both the initial scan exclusion AND the runtime monitoring exclusion.
- If LinkWatcher scans excluded files but does not update them, that is still a partial failure — excluded files should not be scanned at all.
