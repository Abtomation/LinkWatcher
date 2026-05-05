---
id: TE-E2E-026
type: E2E Acceptance Test Case
group: TE-E2G-013
feature_ids: ["0.1.1", "2.1.1", "6.1.1"]
workflow: WF-009
priority: P0
execution_mode: scripted
estimated_duration: 3 minutes
source: WF-009 milestone
lw_flags: ""
created: 2026-04-12
updated: 2026-04-12
---

# Test Case: TE-E2E-026 Validate Clean Workspace

Validation mode scans a workspace where every link target exists. The report should confirm zero broken links and the process should exit with code 0.

## Preconditions

- [ ] LinkWatcher is installed (`pip install -e .` from project root)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group link-validation-audit`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] No other LinkWatcher instance is running against the workspace

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/docs/readme.md` | Markdown file with valid links | `[API Guide](api-guide.md)` and `[Settings](../config/settings.yaml)` |
| `project/docs/api-guide.md` | Link target referenced by readme.md | API documentation content |
| `project/config/settings.yaml` | YAML file with valid path value | `readme: "docs/readme.md"` |

## Steps

1. **Set up test environment**: Copy fixtures to workspace
   - **Tool**: `Setup-TestEnvironment.ps1 -Group link-validation-audit`
   - **Target**: Creates workspace with pristine project/ files

2. **Run validation**: Execute LinkWatcher in validation mode against the workspace project
   - **Tool**: Command Line
   - **Command**: `python main.py --validate --project-root <workspace>/project --log-file <workspace>/validate.log`

3. **Check exit code**: Confirm the process exited with code 0
   - **Tool**: Command Line
   - **Check**: `echo $LASTEXITCODE` (PowerShell) or `echo $?` (bash)

4. **Check report file**: Open `<workspace>/LinkWatcherBrokenLinks.txt` and inspect contents
   - **Tool**: Text editor
   - **Target**: Report file in workspace directory

5. **Verify project files unchanged**: Confirm no files in project/ were modified
   - **Tool**: `Verify-TestResult.ps1 -TestCase TE-E2E-026`

## Scripted Action

**Script**: `run.ps1`
**Action**: Runs `python main.py --validate --project-root <workspace>/project --log-file <workspace>/validate.log` and captures exit code

## Expected Results

### File Changes

No file changes — validation mode is read-only. All files in `project/` remain identical to their initial state.

See `expected/` directory for complete post-test file state (mirrors `project/` exactly).

### Behavioral Outcomes

- Process exits with code **0**
- Report file `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` is created in workspace directory
- Report shows `Broken links  : 0`
- Report shows `No broken links found.`
- Report shows files scanned count ≥ 3 (the three fixture files)

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-026` — confirms project files are unmodified
- [ ] **Report inspection**: Open `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` and confirm clean report
- [ ] **Exit code check**: Confirm process exited with code 0

## Pass Criteria

- [ ] Exit code is 0
- [ ] `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` exists in workspace directory
- [ ] Report contains `Broken links  : 0`
- [ ] Report contains `No broken links found.`
- [ ] All project files are byte-identical to their initial state (verified by Verify-TestResult.ps1)

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- If false positives are reported, check whether validation_ignored_patterns or context-aware skipping needs adjustment
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- Validation mode does not start the file watcher — it runs a single scan and exits
- No lock file is created during validation
- The `--log-file` flag controls where `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` is written (parent directory of the log file)
