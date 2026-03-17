# Test Case: MT-003 PowerShell Script File Move

## Metadata

| Field | Value |
|-------|-------|
| Test Case ID | MT-003 |
| Group | powershell-parser-patterns (MT-GRP-02) |
| Feature | 2.1.1 — Link Parsing System |
| Priority | P1 |
| Estimated Duration | 3 minutes |
| Created | 2026-03-16 |
| Last Updated | 2026-03-16 |
| Source | Feature 2.1.1 PowerShell parser |

## Preconditions

- [ ] LinkWatcher is running in background (`LinkWatcher_run/start_linkwatcher_background.ps1`)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group powershell-parser-patterns`
- [ ] Workspace contains pristine copy of this test case's fixtures

## Test Fixtures

| File | Purpose | Key Content |
|------|---------|-------------|
| `project/test-powershell-parser-patterns.ps1` | PowerShell script with 11 references to `move-target-2.ps1` | Import-Module, Join-Path, strings, arrays, Write-Output |
| `project/move-target-2.ps1` | Target file to be moved | PowerShell script with `Get-Greeting` function |
| `project/move-target.md` | Secondary target (not moved in this test) | Placeholder markdown file |

## Steps

1. **Move file**: Move `move-target-2.ps1` into a `moved/` subdirectory
   - **Tool**: File Explorer or command line
   - **Target**: `workspace/.../project/move-target-2.ps1` → `workspace/.../project/moved/move-target-2.ps1`

2. **Wait**: Wait 10–15 seconds for LinkWatcher to correlate delete+create events as a move
   - **Duration**: 10–15 seconds
   - **Observe**: Check LinkWatcher_run/LinkWatcherLog_20260317-103751.txt for move detection messages

3. **Verify**: Open `test-powershell-parser-patterns.ps1` and check all path references
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: All 11 occurrences of `move-target-2.ps1` should now read `moved/move-target-2.ps1`

## Expected Results

### File Changes

All 11 occurrences of `move-target-2.ps1` in `test-powershell-parser-patterns.ps1` should be updated to `moved/move-target-2.ps1`. This includes paths in:

- Line comments (Pattern 1): 1 occurrence
- Double-quoted strings (Pattern 2): 1 occurrence
- Single-quoted strings (Pattern 3): 1 occurrence
- Join-Path arguments (Pattern 4): 1 occurrence
- Import-Module comments (Pattern 5): 2 occurrences
- Block comments .NOTES (help block): 1 occurrence
- Here-strings (Pattern 8): 1 occurrence
- Arrays (Pattern 9): 1 occurrence
- Write-Output (Pattern 10): 1 occurrence
- Verification checklist comment: 1 occurrence

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log should show move detection for `move-target-2.ps1`
- LinkWatcher log should show file update for `test-powershell-parser-patterns.ps1`
- `move-target.md` references should NOT be changed (only `move-target-2.ps1` was moved)

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase MT-003` — compares workspace against `expected/`
- [ ] **Manual count**: `(Get-Content "test-powershell-parser-patterns.ps1" | Select-String "moved/move-target-2.ps1").Count` should equal 11

## Pass Criteria

- [ ] All 11 occurrences of `move-target-2.ps1` updated to `moved/move-target-2.ps1`
- [ ] `move-target.md` references unchanged (20 occurrences still intact)
- [ ] No errors in LinkWatcher log during test execution
- [ ] `Verify-TestResult.ps1` comparison passes

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pattern type(s) failed to update
- Create a bug report using `New-BugReport.ps1` if the failure indicates a parser defect
- Save the actual `test-powershell-parser-patterns.ps1` as evidence
