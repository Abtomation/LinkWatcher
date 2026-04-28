---
id: PF-STA-092
type: Document
category: General
version: 1.0
created: 2026-04-16
updated: 2026-04-16
change_name: move-source-code-to-src-layout
---

# Structure Change State: Move Source Code to src Layout

> **Lightweight state file**: This change has a detailed proposal document. This file tracks **execution progress only** — see the proposal for rationale, affected files, and migration strategy.

## Next Session Instructions

**Status**: SC-012 is nearly complete. Phases 1-4 all done. Only Phase 5 finalization remains.

**What to do next** (in order):
1. Archive proposal to `proposals/old/`
2. Archive this state file + sc-012-stale-reference-review.md to `state-tracking/temporary/old/`
3. Complete feedback form (PF-TSK-014)
4. Mark completion criteria checkboxes

## Structure Change Overview
- **Change Name**: Move Source Code to src Layout
- **Change ID**: SC-012
- **Proposal Document**: [PF-PRO-025](/process-framework-local/proposals/old/structure-change-move-source-code-to-src-layout-proposal.md)
- **Change Type**: Directory Reorganization
- **Scope**: Move linkwatcher/ to src/linkwatcher/ for standard Python src layout
- **Expected Completion**: 2026-04-30

## Implementation Roadmap

> **Cross-check reminder**: Verify every file in the proposal's affected files table appears in at least one phase checklist below.

### Phase 1: Preparation (Session 1)
- [x] **Impact analysis**: Systematic grep, script audit, task audit, infrastructure review
  - **Status**: COMPLETED
- [x] **Create proposal**: PF-PRO-025
  - **Status**: COMPLETED
- [x] **Checkpoint**: Present proposal + impact matrix for human approval
  - **Status**: COMPLETED
- [x] **Delegation planning**: Classify deliverables and get approval — all direct execution
  - **Status**: COMPLETED

### Phase 2: Directory Move + LinkWatcher (Session 1)
- [x] **Delete stale `linkwatcher.egg-info/`**
  - **Status**: COMPLETED
- [x] **Move `linkwatcher/` → `src/linkwatcher/`** (with LinkWatcher running)
  - **Status**: COMPLETED
  - First attempt failed: moved while LinkWatcher was stopped, so no move event detected
  - Second attempt: moved back, restarted LinkWatcher, waited for initial scan, then moved — directory batch detection triggered successfully
- [x] **LinkWatcher processed the move**: 29 files detected, 227 files updated
  - **Status**: COMPLETED
- [x] **Verify**: Grep for stale `linkwatcher/` paths (excluding `src/linkwatcher/`)
  - **Status**: COMPLETED — 256 files reviewed via sc-012-stale-reference-review.md (Session 2)

#### Findings: Why 256 Files Were Not Updated

LinkWatcher detected the directory move and updated 227 files. However, 256 files retain stale `linkwatcher/` references. Root cause analysis identified three bugs and one process issue:

**Bug PD-BUG-093 (root cause for majority)**: The markdown backtick path parser regex captures `:line_number` suffixes as part of the `link_target`. For example, `` `linkwatcher/handler.py:503` `` is stored in the database as `linkwatcher/handler.py:503`. When LinkWatcher looks for references to `linkwatcher/handler.py` (the moved file), the `:503` suffix prevents matching. This affects ~1500 occurrences across ~200 files.

**Bug PD-BUG-092**: Directory paths without trailing slash and without file extension (e.g., `linkwatcher/parsers` in YAML frontmatter) are not recognized as directory references and not updated. Affects ~50 occurrences.

**Bug PD-BUG-091 (observability)**: The `directory_move_completed` log entry reports `total_references_updated=0` despite hundreds of files being updated. Counter does not capture actual update activity.

**Process issue PF-IMP-558**: Persistent documentation (refactoring plans, tech debt tracking) embeds `file:line_number` references that become stale after any code edit. These accounted for the majority of missed updates and are a maintenance burden independent of this move.

**Breakdown of 256 remaining files**:
- 107 archived refactoring plans (historical — completed work)
- 36 archived feature state files (historical)
- 40 validation reports (inline prose)
- 15 TDDs/FDDs/ADRs (source path references)
- 58 other (tech debt tracking, test audits, guides, feedback, config)

### Phase 3: Manual Edits (Session 2)
- [x] **`pyproject.toml`**: `where` and `coverage.source` updated (Session 1); `include` and `package-data` verified correct as-is (package name, not path)
  - **Status**: COMPLETED
- [x] **`dev.bat`**: L82-95 flake8/black/isort/mypy paths updated to `src/linkwatcher`
  - **Status**: COMPLETED
- [x] **`deployment/install_global.py`**: `core_dirs` changed to tuple mapping `("src/linkwatcher", "linkwatcher")` for correct source/dest
  - **Status**: COMPLETED
- [x] **`.claude/settings.local.json`**: L28 absolute path updated
  - **Status**: COMPLETED
- [x] **`.linkwatcher-ignore`**: L133 comment and L174 suppression rule updated
  - **Status**: COMPLETED
- [x] **17 test .py files**: Fixed `src.src.linkwatcher` double-prefix imports → `linkwatcher` (PD-BUG-094 filed)
  - **Status**: COMPLETED

### Phase 4: Verification (Session 2)
- [x] **Reinstall**: `pip install -e .`
  - **Status**: COMPLETED — Successfully installed linkwatcher-2.0.0
- [x] **Test suite**: `pytest test/automated/` — 780 passed, 5 skipped, 4 xfailed
  - **Status**: COMPLETED
- [x] **CLI check**: `python main.py --help` works
  - **Status**: COMPLETED
- [x] **Link validation**: `python main.py --validate` — no new broken links from our changes
  - **Status**: COMPLETED

### Phase 5: Finalization (Session 2)
- [x] **Documentation map updates**: Not needed — source code paths aren't tracked in doc maps
  - **Status**: COMPLETED
- [x] **Cleanup**: Proposal archived to `proposals/old/`
  - **Status**: COMPLETED
- [x] **Feedback form**: PF-FEE-957 completed
  - **Status**: COMPLETED

## Bugs Filed

| Bug ID | Title | Severity | Root Cause |
|--------|-------|----------|------------|
| PD-BUG-091 | Directory move counter reports 0 despite hundreds updated | Low | Counter logic in handler.py |
| PD-BUG-092 | Directory paths without trailing slash not updated | Medium | Parser doesn't recognize bare dir paths |
| PD-BUG-093 | Backtick parser captures `:line_number` as part of path | Medium | Regex captures beyond file extension |
| PD-BUG-094 | Python import update double-applies src/ prefix during directory move | Medium | Substring match replaces within already-updated import |

## Process Improvements Filed

| IMP ID | Description | Priority |
|--------|-------------|----------|
| PF-IMP-558 | Stop embedding file:line_number references in persistent docs | Medium |

## Session Tracking

### Session 1: 2026-04-16 (10:20 — 11:30)
**Focus**: Phases 1–2, bug investigation
**Completed**:
- Phase 1: Impact analysis, proposal (PF-PRO-025), state file, checkpoint, delegation planning
- Phase 2: Directory move `linkwatcher/` → `src/linkwatcher/`, LinkWatcher processed (227 files updated, 256 remaining)
- Bug investigation: root cause analysis of 256 missed files
- Bug reports filed: PD-BUG-091, PD-BUG-092, PD-BUG-093 (all set to Needs Triage)
- Process improvement filed: PF-IMP-558
- Phase 3: `pyproject.toml` partially updated (`where` and `coverage.source`)
- Created [sc-012-stale-reference-review.md](sc-012-stale-reference-review.md) listing all 256 files for systematic review

**Issues/Blockers**:
- 256 files with stale `linkwatcher/` references due to PD-BUG-093 (backtick `:line_number` suffix) and PD-BUG-092 (bare directory paths)
- Bulk replace rejected — too many false positive risks (server log paths, classification heuristics, our own proposal/state file text)
- Must review files 1:1 using the stale reference review tracking file

**Next session plan**:
1. Systematically review 256 files using sc-012-stale-reference-review.md — mark ignored dirs, review rest 1:1, update where needed
2. Complete remaining Phase 3 manual edits (pyproject.toml package-data, dev.bat, install_global.py, .claude/settings.local.json, .linkwatcher-ignore)
3. Phase 4: `pip install -e .`, test suite, CLI check, link validation
4. Phase 5: Documentation maps, cleanup, feedback form

### Session 2: 2026-04-16 (11:26 — )
**Focus**: Phases 2 (stale review), 3, 4, 5
**Completed**:
- Phase 2 verify: Systematic review of all 256 stale files via 4 parallel agents — classified as [I]/[F]/[U]/[B]
- Phase 3: All manual edits completed (dev.bat, install_global.py, settings.local.json, .linkwatcher-ignore, pyproject.toml verified)
- Discovered & fixed: 17 test files with `src.src.linkwatcher` double-prefix imports (PD-BUG-094)
- Phase 4: pip install success, 780 tests pass, CLI works, link validation clean (no new breaks)
- Filed PD-BUG-094: Python import double-prefix during directory move
- Updated sc-012-stale-reference-review.md with all classifications

**Key finding**: pyproject.toml `include` and `package-data` keys use package name (not path) — correct as-is with `where = ["src"]`. No change needed.

## State File Updates Required

- [x] **Documentation Map**: Not needed — source code, not documentation, was moved
  - **Status**: COMPLETED
- [x] **Process Improvement Tracking**: PF-IMP-558 already filed in Session 1
  - **Status**: COMPLETED

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [x] All phases completed successfully
- [x] All proposal-listed files addressed
- [x] Documentation updated
- [x] Feedback form completed
