---
id: TE-E2G-002
type: E2E Acceptance Test Group
feature_ids: ["1.1.1", "2.1.1", "2.2.1"]
workflow: WF-001
test_cases_count: 2
estimated_duration: 6 minutes
created: 2026-03-16
updated: 2026-03-16
---

# Master Test: powershell-parser-patterns

## Purpose

Quick validation sequence covering all test cases in this group. Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher is running in background (`process-framework/tools/linkWatcher/start_linkwatcher_background.ps1`)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group powershell-parser-patterns`
- [ ] Workspace contains pristine copies of all test fixtures

## Quick Validation Sequence

1. **Move markdown file referenced in PowerShell script (TE-E2E-002)**
   - Action: Move `move-target.md` into a `moved/` subdirectory
   - Tool: File Explorer (drag and drop)
   - Target: `workspace/.../project/move-target.md` → `workspace/.../project/moved/move-target.md`
   - Expected: All 20 occurrences of `move-target.md` in `test-powershell-parser-patterns.ps1` updated to `moved/move-target.md` (line comments, strings, Join-Path, Test-Path, here-strings, arrays, Write-Host, block comments). `move-target-2.ps1` references unchanged.

2. **Move PowerShell script file referenced in PowerShell script (TE-E2E-003)**
   - Action: Move `move-target-2.ps1` into a `moved/` subdirectory
   - Tool: File Explorer (drag and drop)
   - Target: `workspace/.../project/move-target-2.ps1` → `workspace/.../project/moved/move-target-2.ps1`
   - Expected: All 11 occurrences of `move-target-2.ps1` in `test-powershell-parser-patterns.ps1` updated to `moved/move-target-2.ps1` (line comments, strings, Join-Path, Import-Module comments, here-strings, arrays, Write-Output, block comments). `move-target.md` references unchanged (already updated in step 1).

## Pass Criteria

- [ ] All 20 `move-target.md` references updated to `moved/move-target.md` after step 1
- [ ] All 11 `move-target-2.ps1` references updated to `moved/move-target-2.ps1` after step 2
- [ ] Non-moved file references remain unchanged at each step
- [ ] No errors in LinkWatcher log
- [ ] Run `Verify-TestResult.ps1 -Group powershell-parser-patterns` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-002 | [TE-E2E-002-powershell-md-file-move/test-case.md](TE-E2E-002-powershell-md-file-move/test-case.md) | Move markdown file referenced in PowerShell script — verify 20 path references updated across 10 pattern types |
| TE-E2E-003 | [TE-E2E-003-powershell-script-file-move/test-case.md](TE-E2E-003-powershell-script-file-move/test-case.md) | Move PowerShell script file — verify 11 path references updated including Import-Module comments |

## Notes

- Both test cases share the same fixture file (`test-powershell-parser-patterns.ps1`) — TE-E2E-002 moves the markdown target, TE-E2E-003 moves the PowerShell target
- Steps are ordered so step 1 moves `move-target.md` first; step 2 then moves `move-target-2.ps1`. The verification script expects this order.
- This group validates Feature 2.1.1 PowerShell parser across 10 pattern types: line comments, double-quoted strings, single-quoted strings, Join-Path, Import-Module, Test-Path/Get-Content, `-Path`/`-LiteralPath` parameters, here-strings, arrays, and Write-Host/Warning/Output
