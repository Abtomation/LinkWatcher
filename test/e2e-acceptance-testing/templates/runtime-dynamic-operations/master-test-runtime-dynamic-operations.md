---
id: TE-E2G-005
type: E2E Acceptance Test Group
feature_ids: ["1.1.1", "0.1.2", "2.1.1", "2.2.1"]
workflow: WF-001, WF-002
test_cases_count: 6
estimated_duration: 15 minutes
created: 2026-03-18
updated: 2026-03-18
---

# Master Test: runtime-dynamic-operations

## Purpose

Quick validation sequence covering all test cases in this group. Tests that files and directories created while LinkWatcher is running are properly tracked and their subsequent moves/renames are detected with references updated.

Run this FIRST after a code change. If it passes, all individual test cases are considered validated. If it fails, run individual test cases to isolate the issue.

## Preconditions

- [ ] LinkWatcher is **stopped** before workspace setup (prevents false move detection from setup file operations)
- [ ] Test environment set up via `Setup-TestEnvironment.ps1 -Group runtime-dynamic-operations -Clean`
- [ ] LinkWatcher is **started** after setup (fresh scan indexes fixtures correctly)
- [ ] Wait 5 seconds for initial scan to complete before executing any test steps
- [ ] No pre-existing `docs/`, `archive/`, `utils/`, `lib`, `tools/`, `modules/`, or `components/` directories in any test case workspace

> **Why stop/start?** LW's dir_move_detector correlates delete+create event pairs across the workspace. The cleanup+setup cycle generates event patterns indistinguishable from actual directory moves, corrupting detection state. Stopping LW during setup eliminates this noise.

## Quick Validation Sequence

1. **Create a file and move it (TE-E2E-008)**
   - Action: Create `docs/report.md` in TE-E2E-008's project, wait 5s, move to `archive/report.md`
   - Tool: Command Line or scripted via `run.ps1`
   - Target: `TE-E2E-008-file-create-and-move/project/`
   - Expected: `README.md` and `index.md` links updated from `docs/report.md` to `archive/report.md`

2. **Create a file and rename it (TE-E2E-010)**
   - Action: Create `docs/report.md` in TE-E2E-010's project, wait 5s, rename to `docs/summary.md`
   - Tool: Command Line or scripted via `run.ps1`
   - Target: `TE-E2E-010-file-create-and-rename/project/`
   - Expected: `README.md` and `index.md` links updated from `docs/report.md` to `docs/summary.md`

3. **Create a directory and move it (TE-E2E-009)**
   - Action: Create `utils/` with `helper.py` and `config.yaml` in TE-E2E-009's project, wait 5s, move to `lib`
   - Tool: Command Line or scripted via `run.ps1`
   - Target: `TE-E2E-009-directory-create-and-move/project/`
   - Expected: `README.md` links updated from `utils/helper.py` to `lib/helper.py` and `utils/config.yaml` to `lib/config.yaml`

4. **Create a directory and rename it (TE-E2E-011)**
   - Action: Create `utils/` with `helper.py` and `config.yaml` in TE-E2E-011's project, wait 5s, rename to `tools/`
   - Tool: Command Line or scripted via `run.ps1`
   - Target: `TE-E2E-011-directory-create-and-rename/project/`
   - Expected: `README.md` links updated from `utils/helper.py` to `tools/helper.py` and `utils/config.yaml` to `tools/config.yaml`

5. **Create a nested directory and move it (TE-E2E-013)**
   - Action: Create `modules/` with subdirectories `core/` and `plugins/` containing test files in TE-E2E-013's project, wait 5s, move to `lib`
   - Tool: Command Line or scripted via `run.ps1`
   - Target: `TE-E2E-013-nested-directory-move/project/`
   - Expected: `README.md` links updated from `modules/core/engine.py` to `lib/core/engine.py`, `modules/core/config.yaml` to `lib/core/config.yaml`, and `modules/plugins/auth.py` to `lib/plugins/auth.py`

6. **Create a directory with internal refs and move it (TE-E2E-014)**
   - Action: Create `components/` with `index.md`, `overview.md`, and `utils.md` (with sibling references) in TE-E2E-014's project, wait 5s, move to `modules/`
   - Tool: Command Line or scripted via `run.ps1`
   - Target: `TE-E2E-014-directory-move-internal-refs/project/`
   - Expected: `README.md` external references updated from `components/` to `modules/`; internal sibling references in `index.md` and `overview.md` remain unchanged

## Pass Criteria

- [ ] All 6 steps above produce their expected results
- [ ] No errors in LinkWatcher log
- [ ] Run `Verify-TestResult.ps1 -Group runtime-dynamic-operations` shows all green

## If Failed

Run individual test cases to isolate the issue:

| Test Case | Path | Description |
|-----------|------|-------------|
| TE-E2E-008 | [TE-E2E-008-file-create-and-move/test-case.md](TE-E2E-008-file-create-and-move/test-case.md) | Create a file while LW is running, then move it — verify references update |
| TE-E2E-009 | [TE-E2E-009-directory-create-and-move/test-case.md](TE-E2E-009-directory-create-and-move/test-case.md) | Create a directory with files while LW is running, then move it — verify all references update |
| TE-E2E-010 | [TE-E2E-010-file-create-and-rename/test-case.md](TE-E2E-010-file-create-and-rename/test-case.md) | Create a file while LW is running, then rename it in place — verify references update |
| TE-E2E-011 | [TE-E2E-011-directory-create-and-rename/test-case.md](TE-E2E-011-directory-create-and-rename/test-case.md) | Create a directory with files while LW is running, then rename it — verify all references update |
| TE-E2E-013 | [TE-E2E-013-nested-directory-move/test-case.md](TE-E2E-013-nested-directory-move/test-case.md) | Move top-level directory containing subdirectories with referenced files; verify references at all nesting levels updated |
| TE-E2E-014 | [TE-E2E-014-directory-move-internal-refs/test-case.md](TE-E2E-014-directory-move-internal-refs/test-case.md) | Move directory where files reference each other internally; verify internal relative references remain valid unchanged |

## Notes

- All tests in this group create content at runtime (not pre-existing in fixtures) to verify dynamic file tracking
- File operations (008, 010) test single-file detection; directory operations (009, 011) test batch detection via dir_move_detector
- Move tests (008, 009) change the parent directory; rename tests (010, 011) change only the name within the same parent
- Nested directory move (013) extends 009 with multi-level subdirectories; internal refs test (014) validates that sibling-relative links are preserved
