---
id: PF-STA-100
type: Document
category: General
version: 1.0
created: 2026-04-29
updated: 2026-04-29
change_name: relocate-linkwatcher-run-with-agnostic-startup-script
---

# Structure Change State: Relocate LinkWatcher_run with agnostic startup script

> **⚠️ TEMPORARY FILE**: This file tracks implementation of SC-029. Move to `process-framework-local/state-tracking/temporary/old` after all changes are validated.

## Structure Change Overview

- **Change Name**: Relocate LinkWatcher_run with agnostic startup script
- **Change ID**: SC-029
- **Change Type**: Rename + Refactor + Delete (multi-type, treated as Rename for state-file template choice)
- **Proposal**: PF-PRO-029 (see proposals/old/ after archival)
- **Related Bug**: [PD-BUG-098](../../../../doc/state-tracking/permanent/bug-tracking.md) — LinkWatcher overlapping-substring rewrite corrupted 17 files during this change; fixed manually with LinkWatcher off

## Outcome (final state)

### What was moved

| From (before SC-029) | To (after SC-029) |
|---|---|
| `LinkWatcher_run/start_linkwatcher_background.ps1` (per-project, hardcoded install path) | `process-framework/tools/linkWatcher/start_linkwatcher_background.ps1` (agnostic, shareable) |
| `LinkWatcher_run/.linkwatcher-ignore` (was stale) | (deleted; project-root copy was the active one and moved as below) |
| `LinkWatcher_run/LinkWatcherBrokenLinks.txt` (was stale) | (deleted; project-root copy was the active one and moved as below) |
| `LinkWatcher_run/LinkWatcherError.txt` (was stale) | (deleted) |
| `LinkWatcher_run/logs/` (was stale) | (deleted) |
| `LinkWatcher_run/setup_project.py` | (deleted; obsolete) |
| `deployment/setup_project.py` | (deleted; obsolete) |
| `deployment/install_global.py::update_startup_scripts()` (lines 317-432) + call site | (deleted; obsolete) |
| Project-root `.linkwatcher-ignore` (active) | `process-framework-local/tools/linkWatcher/.linkwatcher-ignore` |
| Project-root `LinkWatcherBrokenLinks.txt` (active) | `process-framework-local/tools/linkWatcher/LinkWatcherBrokenLinks.txt` |
| Project-root `logs/` (active) | `process-framework-local/tools/linkWatcher/logs/` |

### What stayed

- `.linkwatcher.lock` (project root) — semantically belongs at project root for cross-tooling visibility

### Code edits (load-bearing)

- `src/linkwatcher/config/settings.py`: replaced `"LinkWatcher_run"` in `ignored_directories` and `validation_extra_ignored_dirs` with `"process-framework-local/tools/linkWatcher"`; changed `validation_ignore_file` default to the new full path; added `validation_output_dir` field defaulting to the new directory
- `main.py`: `--validate` output_dir now resolves from `config.validation_output_dir` (relative to project_root) before falling back to log-file parent or project_root
- `deployment/install_global.py`: docstring updated; `update_startup_scripts()` removed; `main()` no longer calls it; final usage hint points at the agnostic script
- `test/automated/bug-validation/test_pd-bug-077_startup_venv_validation.py`: startup-script path
- `test/automated/unit/test_validator.py`: renamed `test_linkwatcher_run_dir_ignored` → `test_linkwatcher_local_dir_ignored`; assertion path updated
- `src/linkwatcher/validator.py`: comment about default ignored dirs updated
- `.gitignore`: removed stale `LinkWatcher_run/` globs; added `process-framework-local/tools/linkWatcher/{logs/,LinkWatcherBrokenLinks.txt}`
- `.claude/settings.local.json`: two permission allow-list entries
- `process-framework/scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1`: post-E2E LinkWatcher restart path
- `config-examples/logging-config.yaml`: corrected `validation_ignore_file` example

### Doc references swept

~25 markdown/test files updated to reference new paths via bulk substitution. Archived/historical files (`process-framework-local/feedback/archive/**`, `process-framework-local/proposals/old/**`, `process-framework-local/state-tracking/temporary/old/**`, `doc/refactoring/plans/archive/**`, `doc/state-tracking/features/archive/**`, `doc/validation/reports/**`) intentionally left at original paths as historical snapshots.

## Implementation Checklist

- [x] Refactor startup script to agnostic resolver (env-var + ~/bin auto-detect)
- [x] Pilot resolver in isolation — verified `~/bin` resolution
- [x] Add `$logsDir` to new path + auto-create `.linkwatcher-ignore` skeleton at new location
- [x] Move `.linkwatcher-ignore` and `LinkWatcherBrokenLinks.txt` from project root to `process-framework-local/tools/linkWatcher/`
- [x] Stop running LinkWatcher (4 PIDs killed) + remove lock
- [x] Move `logs/` to new local location
- [x] Move script to `process-framework/tools/linkWatcher/` + fix path-depth
- [x] Update `settings.py` defaults + add `validation_output_dir`
- [x] Update `main.py` to read `validation_output_dir`
- [x] Delete `update_startup_scripts()` from `install_global.py` + both copies of `setup_project.py`
- [x] Update `.gitignore`, `.claude/settings.local.json`, `Run-E2EAcceptanceTest.ps1`, `config-examples/logging-config.yaml`, `test_pd-bug-077`, validator.py comment, test_validator.py
- [x] Bulk-sweep active doc references
- [x] File LinkWatcher overlapping-substring bug as PD-BUG-098
- [x] Repair 17 files corrupted by LinkWatcher's overzealous sweep
- [ ] Delete stale `LinkWatcher_run/` contents and the empty directory
- [ ] Restart LinkWatcher from new script location and verify
- [ ] Run `pytest test_pd-bug-077` + `Validate-StateTracking.ps1`
- [ ] Update PF Documentation Map; update process-improvement-tracking.md
- [ ] Archive proposal and this state file
- [ ] Complete feedback form for PF-TSK-014

## Session Tracking

### Session 1: 2026-04-29
**Focus**: Full execution
**Notable issues**:
- Discovered `.linkwatcher-ignore` was actually at project root (not in `LinkWatcher_run/`); plan adjusted mid-flight to move project-root artifacts instead
- Discovered `install_global.py` regenerates the startup script from a Python f-string template; deleted that function (Option B)
- Discovered second `setup_project.py` in `deployment/`; deleted both
- LinkWatcher itself corrupted 17 files mid-move via overlapping-substring rewrite bug (PD-BUG-098 filed); LinkWatcher stopped, files repaired manually
