---
id: PF-STA-098
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-04-28
updated: 2026-04-28
severity: High
bug_name: linkwatcher-false-positive-corrupts-regex-strings-and-glob-filters-in-code
affected_dimensions: CQ
bug_id: PD-BUG-095
---

# Bug Fix State: PD-BUG-095 — LinkWatcher false-positive corrupts regex strings and glob filters in code

> **TEMPORARY FILE**: This file tracks multi-session bug fix work for complex/architectural bugs. Created by Bug Fixing task (PF-TSK-007) when effort is "Large". Move to `state-tracking/temporary/old/` when fix is verified and closed.

## Bug Fix Overview

| Metadata | Value |
|----------|-------|
| **Bug ID** | PD-BUG-095 |
| **Bug Title** | LinkWatcher false-positive corrupts regex strings and glob filters in code |
| **Severity** | High |
| **Affected Feature** | 1.1.1 — File System Monitoring; 2.1.1 — Parser Framework; 2.2.1 — Link Updater |
| **Estimated Sessions** | 1 |
| **Created** | 2026-04-28 |

## Root Cause Analysis

- **Symptom**: When directories are moved while LinkWatcher is running, regex patterns and glob filter strings inside source files get rewritten as if they were file paths. The path part is updated and `\d`/`\s`/`\w` regex escapes get the backslash converted to a forward slash, producing broken regexes (`\d+` → `/d+`) and broken globs (`'*.md'` → `'../*.md'`).
- **Root Cause**: Two compounding causes.
  1. **Parser-level acceptance**: [`looks_like_file_path`](/src/linkwatcher/utils.py) at [src/linkwatcher/utils.py:189](src/linkwatcher/utils.py#L189) accepts any string with a known extension (e.g., `'*.md'`) or any string containing a `/` or `\` (e.g., `'doc/foo/bar-\d+'`) as a file path, with no filter for glob meta-characters or regex escape sequences. Same issue for [`looks_like_directory_path`](/src/linkwatcher/utils.py) — it rejects `*` for directories but still accepts strings with backslash escape sequences. These strings enter the link database via the PowerShell, Python, and generic parsers.
  2. **Path-resolver corruption**: [`PathResolver._calculate_new_target_relative`](/src/linkwatcher/path_resolver.py) and the underlying [`normalize_path`](/src/linkwatcher/utils.py) at [src/linkwatcher/utils.py:124](src/linkwatcher/utils.py#L124) do `path.replace("\\", "/")` unconditionally. When a regex like `'doc/foo/bar-\d+'` matches the directory-prefix early-exit at [src/linkwatcher/path_resolver.py:117](src/linkwatcher/path_resolver.py#L117) on a `doc/foo` directory move, the backslash in `\d` is normalized to `/`, producing `'doc/bar/bar-/d+'`. Existing PD-BUG-033 existence check sits in `reference_lookup._calculate_updated_relative_path` (used when *source file* moves), but `path_resolver` (used when *target file or directory* moves) has no equivalent guard.
- **Affected Components**:
  - `src/linkwatcher/utils.py` — `looks_like_file_path`, `looks_like_directory_path`, `normalize_path`
  - `src/linkwatcher/path_resolver.py` — `_calculate_new_target_relative` (no existence check before mutation)
  - `src/linkwatcher/parsers/powershell.py`, `parsers/python.py`, `parsers/generic.py` — call into the utils helpers
- **Secondary Issues Discovered**:
  - `Validate-StateTracking.ps1:265-267` contains corrupted regex patterns (`'../^## 4/. Documentation Inventory'`) — needs un-corruption after the bug fix lands.
  - `Update-ScriptReferences.ps1:63` contains corrupted glob `Filter "../*.md"` — needs un-corruption.
  - PD-BUG-033 fix is too narrow: only protects the source-file-move path, not the target/directory-move path.

### Affected Dimensions

> **Reference**: [Development Dimensions Guide](/process-framework/guides/framework/development-dimensions-guide.md)

- **Code Quality (CQ)**: LinkWatcher silently corrupts working source files, breaking regexes and filters across the codebase. The same root pattern (over-broad path detection) exists in multiple parsers; fix must address the shared utility, not just symptom sites.

### Dimension-Informed Fix Requirements

- Fix must reject regex/glob strings at the parser level so they never enter the link database (defense at the upstream boundary).
- Fix must add an existence guard in `path_resolver` parallel to PD-BUG-033 in `reference_lookup` (defense in depth).
- Regression tests must use **negative assertions** ("regex `\d` is NOT corrupted to `/d`"), not just "expected value is present" — per the project's standing test guidance.

## Fix Approach

- **Chosen Approach** (proposed, pending checkpoint approval): two-layer defense.
  1. Add `looks_like_regex_or_glob(text)` helper to `utils.py` that returns True for strings containing glob meta-chars (`*`, `**`, `?` outside path context) and regex escapes / character classes / anchors / alternation. Update `looks_like_file_path` and `looks_like_directory_path` to return False for such strings.
  2. Add an existence check in `path_resolver._calculate_new_target_relative` mirroring PD-BUG-033 — before mutating, verify the resolved path exists; if not, return the original target unchanged.
- **Rationale**: Layer 1 prevents bad data entering the database (cleanest, fixes the root cause). Layer 2 catches anything that slips through Layer 1 plus protects against unrelated false positives (typos, references to deleted files). Mirrors the existing PD-BUG-033 design.
- **Alternatives Considered**:
  1. **Existence check only (skip Layer 1)** — rejected: regex/glob strings would still enter the DB, polluting it and causing CPU work on every move; doesn't fix the parser-level root cause.
  2. **Disable `\` → `/` normalization in `normalize_path`** — rejected: that normalization is needed for cross-platform path handling. Removing it breaks legitimate paths.
  3. **Per-parser glob/regex filters** — rejected: the same logic would be duplicated across PowerShell, Python, and generic parsers. A shared helper in `utils.py` is cleaner.

## Implementation Progress

| File / Component | Change Required | Status | Session |
|------------------|----------------|--------|---------|
| `src/linkwatcher/utils.py` | Add `looks_like_regex_or_glob()`; gate `looks_like_file_path` and `looks_like_directory_path` on it | Not Started | 1 |
| `src/linkwatcher/path_resolver.py` | Add existence guard in `_calculate_new_target_relative` (mirror PD-BUG-033) | Not Started | 1 |
| `test/automated/integration/test_link_updates.py` | Add regression tests for directory-move scenario (Bug 095) | Not Started | 1 |
| `test/automated/parsers/test_*.py` (or `test/automated/unit/test_utils.py`) | Add unit tests for `looks_like_regex_or_glob` and gating behavior | Not Started | 1 |
| `process-framework/scripts/validation/Validate-StateTracking.ps1:265-267` | Restore corrupted regex (`'../^## 4/. ...'` → `'^## 4\. ...'`) | Not Started | 1 |
| `process-framework/scripts/update/Update-ScriptReferences.ps1:63` | Restore corrupted glob (`'../*.md'` → `'*.md'`) | Not Started | 1 |

## Validation Status

- [ ] Regression test(s) written and confirmed FAILING before fix
- [ ] Fix implemented — regression tests now PASSING
- [ ] Full test suite passing
- [ ] Similar patterns checked in sibling components (parsers all share `_looks_like_file_path`/`_looks_like_directory_path` via `BaseParser`, so single utility fix covers them)
- [ ] Manual validation test created (or N/A — fix has automated coverage; bug is internal logic)

**Test Suite Results**: Not yet run.

## Documentation Updates

> Only applicable when fix changes technical design or behavior. Mark N/A if not needed.

| Document | ID | Action | Status |
|----------|----|--------|--------|
| Feature State File (1.1.1, 2.1.1, 2.2.1) | TBD | Verify and update if needed | Pending |
| TDD | PD-TDD for parser framework / link updater | Verify and update if needed | Pending |
| Test Specification | TBD | Verify and update if needed | Pending |
| FDD | fdd-2-1-1 / fdd-2-2-1 | Verify and update if needed | Pending |

## Session Log

### Session 1: 2026-04-28

**Completed**:
- Investigation: traced corruption mechanism through parsers → utils → path_resolver
- Confirmed reproduction: regex `'doc/foo/bar-\d+'` corrupted to `'doc/bar/bar-/d+'` on `doc/foo` directory move
- Confirmed BUG-033 regression tests pass — they protect a different code path (source-file move via `reference_lookup`), not the directory-move path (`path_resolver`)
- Designed two-layer fix; documented approach above

**Next Session** (if scope confirmed L; otherwise complete this session):
- Implement Layer 1 (utils.py helpers + gating)
- Implement Layer 2 (path_resolver existence guard)
- Add regression tests
- Restore corrupted sites in Validate-StateTracking.ps1 and Update-ScriptReferences.ps1

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [ ] Bug status is 🔒 Closed (verified via Code Review)
- [ ] All implementation progress items are Done
- [ ] All validation checks pass
- [ ] Documentation updates completed (or confirmed N/A)
- [ ] Bug tracking entry updated with resolution details
