---
id: TE-E2E-027
type: E2E Acceptance Test Case
group: TE-E2G-013
feature_ids: ["0.1.1", "2.1.1", "6.1.1"]
workflow: WF-009
priority: P0
execution_mode: scripted
estimated_duration: 3 minutes
source: WF-009 milestone
lw_flags: ""
expected_exit_code: 1
created: 2026-04-12
updated: 2026-04-12
---

# Test Case: TE-E2E-027 Validate Broken Links Detected

Validation mode scans a workspace containing intentional broken links across multiple file formats. The report should list each broken link with source file, line number, target path, and link type. The process should exit with code 1.

## Preconditions

- [ ] LinkWatcher is installed (`pip install -e .` from project root)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group link-validation-audit`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] No other LinkWatcher instance is running against the workspace

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/docs/readme.md` | Markdown with one valid and one broken link | `[API Guide](api-guide.md)` (valid) and `[Missing Guide](missing-guide.md)` (broken) |
| `project/docs/api-guide.md` | Valid link target | API documentation content |
| `project/config/refs.json` | JSON file with a broken path value | `"spec": "docs/nonexistent.md"` (broken) |
| `project/config/settings.yaml` | YAML file with a broken path value | `schema: "schemas/missing-schema.yaml"` (broken) |

Three intentional broken links:
1. `docs/readme.md` → `missing-guide.md` (markdown link, does not exist)
2. `config/refs.json` → `docs/nonexistent.md` (JSON value, does not exist)
3. `config/settings.yaml` → `schemas/missing-schema.yaml` (YAML value, does not exist)

## Steps

1. **Set up test environment**: Copy fixtures to workspace
   - **Tool**: `Setup-TestEnvironment.ps1 -Group link-validation-audit`
   - **Target**: Creates workspace with pristine project/ files

2. **Run validation**: Execute LinkWatcher in validation mode against the workspace project
   - **Tool**: Command Line
   - **Command**: `python main.py --validate --project-root <workspace>/project --log-file <workspace>/validate.log`

3. **Check exit code**: Confirm the process exited with code 1
   - **Tool**: Command Line
   - **Check**: `echo $LASTEXITCODE` (PowerShell) or `echo $?` (bash)

4. **Check report file**: Open `<workspace>/LinkWatcherBrokenLinks.txt` and inspect contents
   - **Tool**: Text editor
   - **Target**: Report file in workspace directory

5. **Verify broken link entries**: Confirm report lists all three broken links with correct details
   - **Check**: Each entry shows source file:line, target path, and link type

6. **Verify project files unchanged**: Confirm no files in project/ were modified
   - **Tool**: `Verify-TestResult.ps1 -TestCase TE-E2E-027`

## Scripted Action

**Script**: `run.ps1`
**Action**: Runs `python main.py --validate --project-root <workspace>/project --log-file <workspace>/validate.log` and captures exit code

## Expected Results

### File Changes

No file changes — validation mode is read-only. All files in `project/` remain identical to their initial state.

See `expected/` directory for complete post-test file state (mirrors `project/` exactly).

### Behavioral Outcomes

- Process exits with code **1**
- Report file `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` is created in workspace directory
- Report shows `Broken links  : 3`
- Report contains entry for `docs/readme.md` → `missing-guide.md` (markdown link type)
- Report contains entry for `config/refs.json` → `docs/nonexistent.md` (JSON link type)
- Report contains entry for `config/settings.yaml` → `schemas/missing-schema.yaml` (YAML link type)
- Valid link `docs/readme.md` → `api-guide.md` is NOT listed as broken

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-027` — confirms project files are unmodified
- [ ] **Report inspection**: Open `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` and verify all three broken links are listed
- [ ] **Exit code check**: Confirm process exited with code 1

## Pass Criteria

- [ ] Exit code is 1
- [ ] `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` exists in workspace directory
- [ ] Report contains `Broken links  : 3`
- [ ] Report lists `docs/readme.md` with target `missing-guide.md`
- [ ] Report lists `config/refs.json` with target `docs/nonexistent.md`
- [ ] Report lists `config/settings.yaml` with target `schemas/missing-schema.yaml`
- [ ] Report does NOT list `api-guide.md` as broken (valid link)
- [ ] All project files are byte-identical to their initial state

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- If broken link count is wrong, check whether false positives/negatives occurred
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- The three broken links span markdown, JSON, and YAML formats to verify multi-parser coverage in validation mode
- Validation only checks `.md`, `.yaml`, `.yml`, `.json` by default — source code files (.py, .ps1) are not scanned
- Line numbers in the report depend on exact fixture content — verify against the actual fixture files
