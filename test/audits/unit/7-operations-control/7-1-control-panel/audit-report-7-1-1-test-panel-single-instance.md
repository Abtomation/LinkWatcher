---
id: TE-TAR-097
type: Document
category: General
version: 1.0
created: 2026-08-13
updated: 2026-08-13
audit_date: 2026-08-13
auditor: AI Agent
description: "Test audit report for feature 7.1.1 (Automated)"
feature_id: 7.1.1
test_file_path: test/automated/unit/7-operations-control/7-1-control-panel/test_panel_single_instance.py
---

# Test Audit Report - Feature 7.1.1

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 7.1.1 |
| **Test File ID** | test_panel_single_instance.py |
| **Test File Location** | `test/automated/unit/7-operations-control/7-1-control-panel/test_panel_single_instance.py` |
| **Feature Category** | MAIN |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-08-13 |
| **Audit Status** | ✅ Audit Approved |
| **Audit Round** | Round 1, Session 3 (peripheral units) |

## Test Files Audited

| Test File | Location | Test Cases | Status |
|-----------|----------|------------|--------|
| test_panel_single_instance.py | test/automated/unit/7-operations-control/7-1-control-panel/test_panel_single_instance.py | 23 functions / 29 cases | ✅ Audit Approved |

## Audit Evaluation

### 1. Purpose Fulfillment
**Question**: Does the test really fulfill its intended purpose?

**Assessment**: PASS

**Findings**:
- All four specified scenarios (UNIT-I1…I4) are implemented and traceable, organized into five `Test*` classes — the only panel test file using class grouping, and appropriate here because each scenario has several facets.
- The suite goes well beyond the four specified scenarios with guards that keep them honest, each addressing a real-world failure mode: a **foreign listener on a recycled port** must not block the panel; a **raising surface callback** must not kill the listener; **release** must only delete a port file it still owns; an **unknown verb** must be rejected without firing the callback.
- **Protocol correctness is tested, not just connectivity**: the banner handshake is asserted as the discriminator (`send_raw(...) == PANEL_BANNER`), which is what distinguishes a genuine panel from any other process that happens to hold the port.
- Error isolation is tested to the standard the rest of the feature sets: after a raising callback, the listener must still serve the *next* request — asserted by sending a second SURFACE and checking both the banner and a second callback.
- Concurrency is covered directly: five threads issue simultaneous SURFACE requests and all five callbacks are asserted to fire.
- Port-file robustness is parametrized across seven unusable shapes with named ids (`empty`, `blank`, `text`, `zero`, `negative`, `out-of-range`, `garbage`), each asserting takeover *and* rewrite.

**Evidence**:
- `test_stale_port_is_taken_over_and_rewritten` constructs a genuinely dead port by binding and immediately closing a probe socket — a real stale-port condition rather than a fabricated number.
- `test_request_before_a_callback_is_wired_still_acks` covers the startup race where a SURFACE arrives before `on_surface` is assigned; the listener must still acknowledge rather than fail.

#### Assertion Quality Assessment

- **Assertion density**: 1.61 (37 assertions across 23 test methods) — **below the ≥2 target, and this was investigated by reading rather than accepted from the metric.** The finding is that the metric understates this file. Two structural reasons: (a) it is the only class-grouped file, so each test is deliberately scoped to a single fact, and (b) several single-assertion tests carry an entire real socket round-trip. `test_bound_port_accepts_a_loopback_connection` has one assertion, but that assertion opens a real TCP connection, sends the SURFACE token, and compares the returned banner — far more verification than an assertion count conveys. **No remediation recommended**; raising the count would mean padding tests with redundant checks.
- **Behavioral assertions**: Behavioral. Assertions target real socket replies, port-file contents on disk, guard outcome fields (`already_running`, `port`, `message`, `warning`), and callback invocation counts. No weak `is not None`-only assertions.
- **Edge case assertions**: Among the strongest in the feature — stale port, seven malformed port-file shapes, recycled port held by a foreign process, raising callback, unknown verb, callback-not-yet-wired, concurrent requests, and release ownership.
- **Mutation testing** _(optional)_: Not performed — no mutation-testing tool is configured for this project.

---

### 2. Coverage Completeness
**Question**: Are all implementable scenarios covered with tests?

**Assessment**: PASS

**Code Coverage Data** _(panel suite, 2026-08-13)_:

| Source Module | Coverage % | Uncovered Areas |
|---------------|-----------|-----------------|
| `linkwatcher_control_panel/single_instance.py` | **90%** (129 stmts, 13 missed) | 207–210, 224–228 socket/OS error branches on bind and client connect; 259–260, 265 listener-thread teardown edges; 291–292, 300–301 port-file write/delete `OSError` handling |

**Overall Project Coverage**: 83% (whole project); 91.6% across the non-widget panel modules.

**Findings**:
- **Existing Implementation Coverage**: All four specified scenarios covered plus seven unspecified guard properties. The protocol itself — bind, publish, connect, SURFACE, banner, takeover, release — is covered end-to-end against real loopback sockets.
- **Code Coverage Gaps**: All thirteen missed statements are **socket and filesystem error branches** (bind failure, connect failure, thread teardown races, port-file write/unlink `OSError`). These are the fail-open paths: the module's documented behavior is that a failure to acquire the single-instance slot must never prevent the panel from starting. Reproducing them deterministically requires simulating OS-level socket failures, which is disproportionate to the risk — the fallback in every case is "proceed as if first launch".
- **Missing Test Scenarios**: None against the specification.
- **Placeholder Test Quality**: N/A — no placeholder tests.
- **Edge Cases Coverage**: Very strong — see criterion 1. The seven-way parametrized malformed-port-file coverage is more thorough than the specification asked for.

**Evidence**:
- `python -m pytest <panel dir> --cov=...single_instance` → `single_instance.py 129 13 90% 207-210, 224-228, 259-260, 265, 291-292, 300-301`.
- Real sockets are used throughout per the test spec's mock table, which lists loopback sockets as **Real (ephemeral ports)** — faking the handshake would test nothing, since the handshake *is* the behavior under test.

**Recommendations**:
- No coverage action recommended. The uncovered branches are fail-open OS-error paths whose worst outcome is a second panel window — a lesser harm than the complexity of simulating socket failures deterministically.

---

### 3. Test Quality & Structure
**Question**: Could the test be optimized?

**Assessment**: PASS

**Findings**:
- The only class-grouped file in the feature, and the grouping earns its place: five `Test*` classes each carrying a scenario docstring, with narrowly-scoped tests inside. This is why its assertion density reads low — a structural consequence of good decomposition, not weak verification.
- **Resource hygiene is handled by fixture, not by discipline**: the `guard` fixture yields and then always calls `release()`, so a test failing mid-way cannot leak a bound socket into subsequent tests. The one test that constructs its own guard uses `try/finally` for the same reason.
- Two well-designed helpers: `send_raw()` speaks the protocol directly (bypassing the client helper, so the listener is tested rather than the client), and `wait_until()` polls a predicate with a timeout.
- `WAIT_TIMEOUT_SECONDS = 5.0` is defined once with a comment explaining the trade-off: generous enough for a loaded CI box, short enough that a real failure fails fast rather than hanging the suite.

**Evidence**:
- `test_second_launch_binds_no_socket_of_its_own` asserts `second.port is None` — verifying the loser holds no resource, not merely that it reported "already running".

**Recommendations**:
- None.

---

### 4. Performance & Efficiency
**Question**: Are tests efficient and performant?

**Assessment**: PASS

**Findings**:
- Real sockets on ephemeral ports, as the spec requires, with no port collisions possible (the OS assigns).
- **Asynchronous assertions are done correctly**: `wait_until()` polls at 10 ms and returns as soon as the predicate holds, so the common case costs milliseconds and the 5 s timeout is purely a failure bound. This is the pattern the integration file's one fixed 300 ms sleep should adopt (recorded in TE-TAR-091).
- The two fixed `time.sleep(0.1)` calls in this file are **correct usage, not the same flaw**: they assert *negatives* — that no duplicate dispatch and no callback-on-unknown-verb occur. You cannot event-wait for something that must never happen, so a bounded settling window is the right tool. The author evidently understood the distinction.

**Evidence**:
- The `wait_until` docstring states the reasoning explicitly: polling "keeps them deterministic without sleeps that are either flaky or slow."
- The file contributes ~1.5 s to the panel suite, the bulk of it the two deliberate 0.1 s negative-assertion windows.

**Recommendations**:
- None.

---

### 5. Maintainability
**Question**: Will these tests be maintainable long-term?

**Assessment**: PASS

**Findings**:
- The module docstring separates the four specified scenarios from "the guard properties that keep those four honest", making the file's intent — and the reason for the extra tests — explicit.
- Protocol constants (`PANEL_BANNER`, `SURFACE_TOKEN`, `PORT_FILENAME`) are imported from the module rather than duplicated as literals, so a protocol change cannot leave tests asserting a stale wire format.
- Parametrized ids (`empty`, `blank`, `text`, `zero`, `negative`, `out-of-range`, `garbage`) make failures self-describing in pytest output.
- Class docstrings restate each scenario in one line, so a failure inside `TestStalePortFile` is immediately locatable against the spec.

**Evidence**:
- `test_foreign_listener_on_a_recycled_port_is_not_mistaken_for_a_panel` carries a docstring explaining the real-world condition it protects against — an unrelated process on a recycled port must not block the panel from starting.

**Recommendations**:
- None.

---

### 6. Integration Alignment
**Question**: Do tests align with overall testing strategy?

**Assessment**: PASS

**Findings**:
- Full marker compliance with `priority("Standard")`.
- Follows the test spec's mock table exactly: loopback sockets **real**, no Tk instantiated. The surfacing action itself (`app.surface()` — deiconify/lift/focus) is correctly out of scope here, since it is Tk-bound and belongs to E2E.
- Correct boundary with siblings: this file owns the single-instance protocol; the app-side dispatch of the surface callback through the queue is exercised in `test_panel_integration.py`.
- Imports only public names (`SingleInstanceGuard`, `surface_existing_instance`, and the three protocol constants).

**Evidence**:
- EC-9 ("second panel instance → surface the existing window") is covered here for the protocol half, with the window-raising half explicitly deferred to E2E — matching the spec's split.

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
All six criteria pass. All four specified scenarios are covered at 90% module coverage, with seven additional guard properties addressing real-world failure modes the specification did not enumerate. The uncovered statements are exclusively fail-open socket and filesystem error branches whose worst outcome is a second panel window.

The file's assertion density (1.61) is below the ≥2 target and was **investigated by reading the tests rather than scored from the metric**. The conclusion is that the metric understates this file: it is the only class-grouped suite, so tests are deliberately scoped to one fact each, and several single-assertion tests carry a complete real socket round-trip. Raising the count would mean padding tests with redundant checks, so no remediation is recommended — the density figure is recorded here with its explanation so a future audit does not re-flag it.

### Critical Issues
- None.

### Improvement Opportunities
- Thirteen uncovered statements in socket/filesystem error branches. Not recommended for action — deterministically simulating OS-level socket failures is disproportionate to a fail-open path.

### Strengths Identified
- **The protocol is tested, not just the connection**: the banner handshake is asserted as the discriminator that distinguishes a real panel from any other process holding the port — which is precisely what makes the recycled-port guard possible.
- **Guards that keep the specified scenarios honest**: a foreign listener on a recycled port must not block the panel; a raising callback must not kill the listener (and the listener must still serve the *next* request); release must only delete a port file it still owns.
- **Seven-way parametrized malformed port-file coverage** with named ids, each asserting both takeover and rewrite.
- **Genuine concurrency coverage**: five simultaneous threaded SURFACE requests, all five callbacks asserted.
- **Resource hygiene by construction**: the `guard` fixture always releases, so a mid-test failure cannot leak a bound socket into the rest of the suite.
- **Correct discrimination between waiting patterns**: event-driven `wait_until()` for positive assertions, bounded settling windows only for negative assertions ("no duplicate dispatch"). The distinction the integration file gets wrong in one place, this file gets right throughout.

## Action Items

### For Test Implementation Team
- [ ] None required.

## Audit Completion

### Validation Checklist
- [x] All six evaluation criteria have been assessed
- [x] Specific findings documented with evidence
- [x] Clear audit decision made with rationale
- [x] Action items defined with assignees
- [x] Test implementation tracking updated
- [x] Test registry updated with audit status

### Next Steps
1. Round 1 completes with this session; feature 7.1.1 proceeds to Code Review (PF-TSK-005).

### Follow-up Required
- **Re-audit Date**: Not required (approved).
- **Follow-up Items**: None. The sub-target assertion density is explained above and should not be re-flagged.

---

**Audit Completed By**: AI Agent
**Completion Date**: 2026-08-13
**Report Version**: 1.0
