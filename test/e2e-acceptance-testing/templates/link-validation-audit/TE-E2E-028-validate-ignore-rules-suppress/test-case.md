---
id: TE-E2E-028
type: E2E Acceptance Test Case
group: TE-E2G-013
feature_ids: ["0.1.1", "2.1.1", "6.1.1"]
workflow: WF-009
priority: P1
execution_mode: scripted
estimated_duration: 3 minutes
source: WF-009 milestone
lw_flags: ""
expected_exit_code: 1
created: 2026-04-12
updated: 2026-04-12
---

# Test Case: TE-E2E-028 Validate Ignore Rules Suppress

Validation mode scans a workspace with broken links, but a `.linkwatcher-ignore` file contains rules that suppress specific broken links. Suppressed links should not appear in the report; non-matching broken links should still be reported.

## Preconditions

- [ ] LinkWatcher is installed (`pip install -e .` from project root)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group link-validation-audit`
- [ ] Workspace contains pristine copy of this test case's fixtures
- [ ] No other LinkWatcher instance is running against the workspace

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/docs/readme.md` | Markdown with a broken link matching an ignore rule | `[Template](templates/placeholder.md)` (broken, suppressed by ignore rule) |
| `project/docs/guide.md` | Markdown with a broken link NOT matching any ignore rule | `[Old Reference](old/deleted-file.md)` (broken, reported) |
| `project/LinkWatcher/.linkwatcher-ignore` | Ignore rules file | `docs/readme.md -> templates/placeholder.md` |
| `project/linkwatcher-config.yaml` | Config pointing to ignore file | `validation_ignore_file: "LinkWatcher/.linkwatcher-ignore"` |

Two broken links:
1. `docs/readme.md` → `templates/placeholder.md` — **suppressed** by ignore rule (`docs/readme.md -> templates/placeholder.md`)
2. `docs/guide.md` → `old/deleted-file.md` — **not suppressed** (no matching rule)

## Steps

1. **Set up test environment**: Copy fixtures to workspace
   - **Tool**: `Setup-TestEnvironment.ps1 -Group link-validation-audit`
   - **Target**: Creates workspace with pristine project/ files

2. **Run validation**: Execute LinkWatcher in validation mode with the config file
   - **Tool**: Command Line
   - **Command**: `python main.py --validate --project-root <workspace>/project --config <workspace>/project/linkwatcher-config.yaml --log-file <workspace>/validate.log`

3. **Check exit code**: Confirm the process exited with code 1
   - **Tool**: Command Line
   - **Check**: `echo $LASTEXITCODE` (PowerShell) or `echo $?` (bash)

4. **Check report file**: Open `<workspace>/LinkWatcherBrokenLinks.txt` and inspect contents
   - **Tool**: Text editor
   - **Target**: Report file in workspace directory

5. **Verify suppression**: Confirm the report does NOT list the suppressed link from readme.md
   - **Check**: No entry for `docs/readme.md` → `templates/placeholder.md`

6. **Verify reported link**: Confirm the report lists the non-suppressed broken link from guide.md
   - **Check**: Entry for `docs/guide.md` → `old/deleted-file.md`

7. **Verify project files unchanged**: Confirm no files in project/ were modified
   - **Tool**: `Verify-TestResult.ps1 -TestCase TE-E2E-028`

## Scripted Action

**Script**: `run.ps1`
**Action**: Runs `python main.py --validate --project-root <workspace>/project --config <workspace>/project/linkwatcher-config.yaml --log-file <workspace>/validate.log` and captures exit code

## Expected Results

### File Changes

No file changes — validation mode is read-only. All files in `project/` remain identical to their initial state.

See `expected/` directory for complete post-test file state (mirrors `project/` exactly).

### Behavioral Outcomes

- Process exits with code **1** (one non-suppressed broken link remains)
- Report file `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` is created in workspace directory
- Report shows `Broken links  : 1`
- Report contains entry for `docs/guide.md` → `old/deleted-file.md`
- Report does NOT contain entry for `docs/readme.md` → `templates/placeholder.md` (suppressed)

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase TE-E2E-028` — confirms project files are unmodified
- [ ] **Report inspection**: Open `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` and verify suppression worked correctly
- [ ] **Exit code check**: Confirm process exited with code 1

## Pass Criteria

- [ ] Exit code is 1
- [ ] `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` exists in workspace directory
- [ ] Report contains `Broken links  : 1`
- [ ] Report lists `docs/guide.md` with target `old/deleted-file.md`
- [ ] Report does NOT list `docs/readme.md` with target `templates/placeholder.md`
- [ ] All project files are byte-identical to their initial state

## Fail Actions

- Record the failure in e2e-test-tracking.md with status `🔴 Failed`
- Note which pass criterion failed and any observed error messages
- If the suppressed link still appears, check `.linkwatcher-ignore` parsing logic
- If the non-suppressed link is missing, check whether overly broad ignore rules are hiding it
- Create a bug report using `New-BugReport.ps1` if the failure indicates a genuine defect

## Notes

- The `.linkwatcher-ignore` format is: `source_glob -> target_substring` (one rule per line)
- Both the source glob AND target substring must match for a link to be suppressed
- The config file `linkwatcher-config.yaml` must point to the ignore file via `validation_ignore_file`
