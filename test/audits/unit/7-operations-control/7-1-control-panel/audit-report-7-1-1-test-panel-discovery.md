---
id: TE-TAR-089
type: Document
category: General
version: 1.0
created: 2026-08-13
updated: 2026-08-13
audit_date: 2026-08-13
auditor: AI Agent
description: "Test audit report for feature 7.1.1 (Automated)"
feature_id: 7.1.1
test_file_path: test/automated/unit/7-operations-control/7-1-control-panel/test_panel_discovery.py
---

# Test Audit Report - Feature 7.1.1

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 7.1.1 |
| **Test File ID** | test_panel_discovery.py |
| **Test File Location** | `test/automated/unit/7-operations-control/7-1-control-panel/test_panel_discovery.py` |
| **Feature Category** | MAIN |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-08-13 |
| **Audit Status** | ✅ Audit Approved |
| **Audit Round** | Round 1, Session 1 (correctness core) |

## Test Files Audited

| Test File | Location | Test Cases | Status |
|-----------|----------|------------|--------|
| test_panel_discovery.py | test/automated/unit/7-operations-control/7-1-control-panel/test_panel_discovery.py | 26 (25 at audit start, +1 minor fix) | ✅ Audit Approved |

## Minor Fixes Applied

Two fixes applied during this audit under [Minor Fix Authority](../../../../../process-framework/tasks/03-testing/test-audit-task.md#minor-fix-authority). Both are single-line additions to existing test methods; neither adds a test method or alters production code.

| # | Change | Why | Effect | Time |
|---|--------|-----|--------|------|
| 1 | Added `([], None)` to the parametrize list of `test_extract_project_root_handles_every_argument_form` | `extract_project_root`'s empty-cmdline guard (discovery.py:122–123) was unexercised. psutil can legitimately report an empty cmdline for a process it cannot fully read. | Covers discovery.py:123 | ~4 min |
| 2 | Added a `no_cmdline` entry and a fourth assertion to `test_is_daemon_for_requires_both_entry_script_and_root` | `is_daemon_for`'s empty-cmdline guard (discovery.py:148–149) was unexercised. This is on the three-way identity path, where failing open would mean claiming an unidentifiable process as a termination target. | Covers discovery.py:149 | ~5 min |

**Combined effect**: `discovery.py` coverage 93% → **94%**; panel suite 249 → 250 passing. `black`, `isort`, and `flake8 --max-line-length=120 --extend-ignore=E203` all clean on the edited file.

## Audit Evaluation

### 1. Purpose Fulfillment
**Question**: Does the test really fulfill its intended purpose?

**Assessment**: PASS

**Findings**:
- All ten specified scenarios (UNIT-D1…D10) are implemented and traceable by scenario ID in the test docstrings.
- The three-way identity rule — which the test spec names the security-adjacent core, since everything the panel does to a "found" daemon is a termination — is tested both at the primitive level (`test_is_daemon_for_requires_both_entry_script_and_root`, asserting each of the three conditions alone is insufficient) and through the classification matrix (recycled PID and wrong-root cases both landing on STALE_LOCK with `pids == []`).
- The file goes materially beyond the specified scenarios with three guards that encode real failure modes, each documented with its rationale: a **production-observed** drive-letter/separator case mismatch (`test_running_when_project_root_case_differs`), a **sibling-prefix** false positive where root `…/app` must not match a daemon for `…/app-extra`, and a process with no `--project-root` at all being refused as unidentifiable.
- Defensive parsing is tested as behavior rather than absence-of-exception: malformed lock content is parametrized over four shapes and asserts both the resulting status *and* that a reason is surfaced; malformed registry JSON asserts the specific error text.
- Classification precedence is pinned by `test_live_daemon_outranks_a_stale_lock`, with the docstring recording *why* (rendering a running daemon as not-running would leave it unstoppable from its own supervisor).

**Evidence**:
- `test_stale_lock_when_pid_recycled` asserts `status is STALE_LOCK`, `pids == []`, and `"reused" in detail` — the empty PID list is the assertion that actually prevents a termination, and it is present rather than implied.
- `test_root_prefix_does_not_match_a_longer_sibling_root` constructs the adversarial input directly (`str(project.root) + "-extra"`), so a naive substring implementation fails the test immediately.
- `test_registry_lists_every_project_including_frozen` documents a deliberate non-filter with its consequence, preventing a future "optimization" from hiding running daemons.

**Recommendations**:
- None beyond the two coverage items already applied as minor fixes.

#### Assertion Quality Assessment

- **Assertion density**: 2.12 (55 assertions across 26 test methods, post-fix; 2.08 at audit start) — above the ≥2 target. No zero-assertion test methods.
- **Behavioral assertions**: Behavioral throughout. Assertions target `DaemonStatus` enum identity, exact PID lists, `started_at` values, derived `Path` objects, and error-text content. No weak `is not None`-only assertions. Notably, negative assertions (`pids == []`) are used to verify that *nothing became a kill target* — the property that actually matters here.
- **Edge case assertions**: Strong. Empty/garbage lock content (4 parametrized shapes), unparseable registry JSON, valid JSON of the wrong shape, empty registry, a registry entry missing its path, a project root that no longer exists, and — after the minor fixes — empty command lines on both identity primitives. Six argument forms are parametrized for `--project-root` extraction, including the raw unsplit command-line form.
- **Mutation testing** _(optional)_: Not performed — no mutation-testing tool is configured for this project.

---

### 2. Coverage Completeness
**Question**: Are all implementable scenarios covered with tests?

**Assessment**: PASS

**Code Coverage Data** _(from `Run-Tests.ps1 -All -Coverage`, 2026-08-13; discovery re-measured post-fix)_:

| Source Module | Coverage % | Uncovered Areas |
|---------------|-----------|-----------------|
| `linkwatcher_control_panel/discovery.py` | **94%** (193 stmts, 12 missed) | 84–100 `PsutilProcessTable.snapshot` (real psutil adapter, mocked by design); 193–194 `read_lock_pid` OSError branch; 387 `DiscoveryPoller.poll_once` delegate |

**Overall Project Coverage**: 83% (whole project); 91.6% across the non-widget panel modules.

**Findings**:
- **Existing Implementation Coverage**: All ten specified scenarios covered, plus five unspecified guards. After the two minor fixes, both identity primitives (`extract_project_root`, `is_daemon_for`) are at full statement coverage — appropriate, since these are the functions that decide whether a process may be terminated.
- **Code Coverage Gaps**: All three remaining gaps are low-risk. `PsutilProcessTable.snapshot` (9 of the 12 missed statements) is the real process-table adapter that the test spec explicitly replaces with `fake_process_table` — testing it would require a real process table and would verify psutil, not the panel. `DiscoveryPoller.poll_once` (387) is a one-line delegate to the module-level function that *is* tested. Excluding the psutil adapter, the module's own logic sits at ~99%.
- **Missing Test Scenarios**: One genuine residual — `read_lock_pid`'s `OSError` branch (193–194), reached when the lock file exists but cannot be read (permissions, or the path being a directory). The function's stated contract is "never raises", and the other two failure shapes (empty, corrupt) are both tested; only the I/O-failure shape is not. Low impact and cheap to close, but it needs a new test method, so it falls outside Minor Fix Authority.
- **Placeholder Test Quality**: N/A — no placeholder tests; every implementation under test exists.
- **Edge Cases Coverage**: Strong — see criterion 1.

**Evidence**:
- Post-fix measurement: `python -m pytest test/automated/unit/7-operations-control/7-1-control-panel/ --cov=linkwatcher.linkwatcher_control_panel.discovery` → `193 12 94% 84-100, 193-194, 387` (down from `193 14 93% 84-100, 123, 149, 193-194, 387`).
- Registry-loading paths are covered across five distinct shapes (valid, malformed JSON, wrong schema, empty, entry-missing-path), each asserting the specific surfaced message rather than merely a non-empty error.

**Recommendations**:
- Consider one test for `read_lock_pid` against an unreadable lock path to complete the "never raises" contract. Low priority; recorded as an improvement opportunity, not registered as tech debt (single trivial branch, no safety consequence — a read failure already yields the same STALE_LOCK rendering as the tested corrupt-content case).

---

### 3. Test Quality & Structure
**Question**: Could the test be optimized?

**Assessment**: PASS

**Findings**:
- Uniform Arrange-Act-Assert with the act step isolated by blank lines; every test exercises exactly one classification decision.
- Fixture composition is clean — `make_project`, `write_lock`, `write_registry`, `fake_process_table`, and `daemons` compose per test without any local helper duplication.
- Parametrization is used where it genuinely collapses repetition (four malformed-lock shapes; six `--project-root` argument forms) and avoided where distinct rationales deserve distinct docstrings — the right judgment call in both directions.
- Section banners map directly onto spec scenario groups, so the file's structure mirrors TE-TSP-045.
- Tests construct adversarial inputs explicitly rather than relying on incidental fixture properties, which keeps the intent legible.

**Evidence**:
- The malformed-lock parametrization `["", "   ", "not-a-pid", "12x34"]` covers empty, whitespace, non-numeric, and partially-numeric in four lines rather than four near-identical tests.
- By contrast, the three UNIT-D4 guards are separate tests because each documents a different real-world failure mode — collapsing them into a parametrize would have destroyed that rationale.

**Recommendations**:
- None.

---

### 4. Performance & Efficiency
**Question**: Are tests efficient and performant?

**Assessment**: PASS

**Findings**:
- No process spawning, no psutil calls, no sleeps. The fake process table makes every classification test pure computation over in-memory tuples.
- Temp-file use is limited to what genuinely needs the filesystem (lock files, registry JSON), via pytest's `tmp_path`, with automatic cleanup.
- No cross-test state: `fake_process_table` is function-scoped and each test seeds its own entries.

**Evidence**:
- 26 tests contribute a negligible share of the 1.54 s measured across the three correctness-core files; the slowest discovery test is 0.02 s.
- Full 10-file panel suite: 250 tests in 9.90 s.

**Recommendations**:
- None.

---

### 5. Maintainability
**Question**: Will these tests be maintainable long-term?

**Assessment**: PASS

**Findings**:
- The strongest documentation in the correctness-core trio. Docstrings record *observed production behavior* and the consequence of getting it wrong — the case-mismatch test notes the registry stores `C:\...` while the daemon's command line carries `c:\...`, and that a literal comparison "classifies LinkWatcher's own daemon as not-running, which would then refuse to stop it".
- Non-obvious deliberate decisions are captured where a maintainer would otherwise "fix" them: frozen projects are listed on purpose; a missing project root is STOPPED-with-detail rather than a new status; a live daemon outranks a stale lock.
- The module docstring identifies the highest-value target in the file, directing review attention correctly.
- Same mild coupling as its siblings: assertions on detail substrings (`"reused"`, `"without a lock file"`, `"not found"`). The chosen fragments are single semantically-loaded words rather than full sentences, which limits the blast radius of rewording. Observation, not a defect.

**Evidence**:
- `test_process_without_project_root_argument_is_never_claimed` explains that `--project-root` defaults to the working directory, which is invisible in the command line, and states the conservative rule: "never terminate what cannot be identified."

**Recommendations**:
- As with the lifecycle file, consider shared constants if detail messages are ever reworded in bulk.

---

### 6. Integration Alignment
**Question**: Do tests align with overall testing strategy?

**Assessment**: PASS

**Findings**:
- Full marker compliance (`feature`, `priority`, `test_type`, `specification`) at module level, consistent with the other nine panel files.
- Exercises the module through its public surface — `classify_project`, `poll_once`, `load_projects`, `read_lock_pid`, `extract_project_root`, `is_daemon_for` — with no patching of private state, honoring the TDD's injectable-seam design.
- Correct division of labour with siblings: this file owns single-pass classification; multi-cycle convergence (INT-1/INT-2) lives in `test_panel_integration.py`. No overlap.
- The fake process table it depends on is the foundation seam the test spec requires to exist before discovery, lifecycle, and integration tests — and it is defined once in the shared local `conftest.py`, as specified.

**Evidence**:
- `Validate-TestTracking.ps1` reports 0 errors across the suite, confirming marker-to-tracking consistency.

**Recommendations**:
- None.

## Overall Audit Summary

### Audit Decision
**Status**: ✅ Audit Approved

**Status Definitions**:
- **✅ Audit Approved**: All implementable tests are complete and high quality
- **🔄 Needs Update**: Existing tests have issues that need fixing
- **🔴 Tests Incomplete**: Missing tests for existing implementations

**Rationale**:
All six criteria pass. All ten specified scenarios (UNIT-D1…D10) are implemented, traceable, and passing, and the file adds five unspecified guards that encode genuine failure modes — including one regression case observed in production. The three-way identity rule, which the test spec identifies as the security-adjacent core of the feature, is verified both at the primitive level and through the classification matrix, with the empty-PID-list assertion that actually prevents a wrongful termination present in every negative case. After two minor fixes applied during this audit, both identity primitives are at full statement coverage. The residual gaps are the psutil boundary adapter (mocked by design) and a single defensive I/O branch of low consequence.

### Critical Issues
- None.

### Improvement Opportunities
- `read_lock_pid`'s `OSError` branch (discovery.py:193–194) is untested, leaving the "never raises" contract verified for two of its three failure shapes. Low priority — an unreadable lock already renders identically to the tested corrupt-content case.
- Detail-string coupling: assertions on human-readable message fragments will break on rewording.

### Strengths Identified
- Negative assertions carry the safety property: every non-claim case asserts `pids == []`, which is the specific fact that prevents a termination — rather than asserting only the status label.
- Production-derived regression cases with their rationale recorded — the drive-letter case-mismatch test documents the exact real-world observation that motivated it.
- Adversarial inputs are constructed explicitly (`str(project.root) + "-extra"`), so a naive substring implementation fails immediately rather than passing by luck.
- Deliberate design decisions are documented at the point of test, protecting them from well-meaning future "fixes".

## Action Items

### For Test Implementation Team
- [ ] Optional, low priority: add one test for `read_lock_pid` against an unreadable lock path to complete the "never raises" contract.

## Audit Completion

### Validation Checklist
- [x] All six evaluation criteria have been assessed
- [x] Specific findings documented with evidence
- [x] Clear audit decision made with rationale
- [x] Action items defined with assignees
- [x] Test implementation tracking updated
- [x] Test registry updated with audit status

### Next Steps
1. Sessions 2 and 3 of Round 1 audit the remaining seven panel test files.
2. Feature 7.1.1 proceeds to Code Review (PF-TSK-005) once the full round completes.

### Follow-up Required
- **Re-audit Date**: Not required (approved).
- **Follow-up Items**: None blocking. The `read_lock_pid` I/O branch is recorded as an improvement opportunity only.

---

**Audit Completed By**: AI Agent
**Completion Date**: 2026-08-13
**Report Version**: 1.0
