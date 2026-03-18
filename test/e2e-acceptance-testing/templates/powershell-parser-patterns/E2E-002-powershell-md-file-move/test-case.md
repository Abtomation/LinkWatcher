# Test Case: E2E-002 PowerShell Markdown File Move

## Metadata

| Field | Value |
|-------|-------|
| Test Case ID | E2E-002 |
| Group | powershell-parser-patterns (E2E-GRP-02) |
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
| `project/test-powershell-parser-patterns.ps1` | PowerShell script with 20 references to `move-target.md` across 10 pattern types | Line comments, strings, Join-Path, Test-Path, here-strings, arrays, Write-Host |
| `project/move-target.md` | Target file to be moved | Placeholder markdown file referenced by the PS script |
| `project/move-target-2.ps1` | Secondary target (not moved in this test) | PowerShell script referenced via Import-Module |

## Steps

1. **Move file**: Move `move-target.md` into a `moved/` subdirectory
   - **Tool**: File Explorer or command line
   - **Target**: `workspace/.../project/move-target.md` → `workspace/.../project/moved/move-target.md`

2. **Wait**: Wait 10–15 seconds for LinkWatcher to correlate delete+create events as a move
   - **Duration**: 10–15 seconds
   - **Observe**: Check LinkWatcher_run/LinkWatcherLog_20260317-103751.txt for move detection messages

3. **Verify**: Open `test-powershell-parser-patterns.ps1` and check all path references
   - **Tool**: Text editor or `Verify-TestResult.ps1`
   - **Target**: All 20 occurrences of `move-target.md` should now read `moved/move-target.md`

## Expected Results

### File Changes

All 20 occurrences of `move-target.md` in `test-powershell-parser-patterns.ps1` should be updated to `moved/move-target.md`. This includes paths in:

- Line comments (Pattern 1): 4 occurrences
- Double-quoted strings (Pattern 2): 2 occurrences
- Single-quoted strings (Pattern 3): 1 occurrence
- Join-Path arguments (Pattern 4): 1 occurrence
- Test-Path/Get-Content paths (Pattern 6): 2 occurrences
- -Path/-LiteralPath parameters (Pattern 7): 2 occurrences
- Here-strings (Pattern 8): 1 occurrence
- Arrays (Pattern 9): 1 occurrence
- Write-Host/Warning/Output (Pattern 10): 2 occurrences
- Block comments .EXAMPLE/.NOTES (Patterns in help block): 4 occurrences

See `expected/` directory for complete post-test file state.

### Behavioral Outcomes

- LinkWatcher log should show move detection for `move-target.md`
- LinkWatcher log should show file update for `test-powershell-parser-patterns.ps1`
- `move-target-2.ps1` references should NOT be changed (only `move-target.md` was moved)

## Verification Method

- [ ] **Automated comparison**: Run `Verify-TestResult.ps1 -TestCase E2E-002` — compares workspace against `expected/`
- [ ] **Manual count**: `(Get-Content "test-powershell-parser-patterns.ps1" | Select-String "moved/move-target.md").Count` should equal 20

## Pass Criteria

- [ ] All 20 occurrences of `move-target.md` updated to `moved/move-target.md`
- [ ] `move-target-2.ps1` references unchanged (11 occurrences still intact)
- [ ] No errors in LinkWatcher log during test execution
- [ ] `Verify-TestResult.ps1` comparison passes

## Fail Actions

- Record the failure in test-tracking.md with status `🔴 Failed`
- Note which pattern type(s) failed to update
- Create a bug report using `New-BugReport.ps1` if the failure indicates a parser defect
- Save the actual `test-powershell-parser-patterns.ps1` as evidence
