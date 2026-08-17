---
id: TE-TAR-091
type: Document
category: General
version: 1.0
created: 2026-08-13
updated: 2026-08-13
audit_date: 2026-08-13
auditor: AI Agent
description: "Test audit report for feature 7.1.1 (Automated)"
feature_id: 7.1.1
test_file_path: test/automated/unit/7-operations-control/7-1-control-panel/test_panel_integration.py
---

# Test Audit Report - Feature 7.1.1

## Audit Overview

| Field | Value |
|-------|-------|
| **Feature ID** | 7.1.1 |
| **Test File ID** | test_panel_integration.py |
| **Test File Location** | `test/automated/unit/7-operations-control/7-1-control-panel/test_panel_integration.py` |
| **Feature Category** | MAIN |
| **Auditor** | AI Agent |
| **Audit Date** | 2026-08-13 |
| **Audit Status** | ✅ Audit Approved |
| **Audit Round** | Round 1, Session 2 (pipelines & view logic) |

## Test Files Audited

| Test File | Location | Test Cases | Status |
|-----------|----------|------------|--------|
| test_panel_integration.py | test/automated/unit/7-operations-control/7-1-control-panel/test_panel_integration.py | 22 | ✅ Audit Approved |

## Audit Evaluation

### 1. Purpose Fulfillment
**Question**: Does the test really fulfill its intended purpose?

**Assessment**: PASS

**Findings**:
- All nine specified scenarios (INT-1…INT-9) are implemented and traceable by scenario ID.
- Convergence is asserted in **exact poll cycles**, not "eventually": INT-1 asserts STOPPED after cycle 1, mutates the fake process table, then asserts RUNNING after cycle 2 — which is precisely the TDD §7.1 convergence target (within 2 poll cycles), tested as a bound rather than as an outcome.
- INT-8 worker-error isolation is the strongest section. Each of the four worker surfaces (start, stop, validation, discovery) plus the UI-thread dispatcher is asserted on three axes simultaneously: the failing surface degrades correctly, a **real `panel.log` file** contains the specific event name, and a *neighbouring project's row is unaffected*. Isolation is verified against an actual bystander, not asserted in the abstract.
- The dispatcher test proves the property that matters for queue isolation: given three queued callbacks where the middle one throws, `applied == ["before", "after"]` — work queued *behind* a failure still runs, and the queue drains (`pending.empty()`).
- Discovery failure is tested as a recoverable, one-cycle cost: the error surfaces on the model, then the very next healthy cycle restores the rows and clears the error — the "one bad cycle" contract rather than merely "does not crash".
- INT-7 uses a **real** `save_config` against a real config file rather than a stub, honoring the TDD D-T6 rule that the config validator is never mocked.

**Evidence**:
- `test_int8_discovery_failure_is_surfaced_and_recovers_next_cycle` asserts `rows() == []`, both halves of the error text, the log event, and then full recovery on the next cycle — five assertions spanning the whole failure-and-recovery arc.
- `test_int8_stop_worker_exception_releases_the_row_to_poll_truth` additionally asserts `controller.is_busy(...) is False`, verifying the busy guard is released on the exception path so a retry remains possible — the detail that turns "handled the error" into "recovered from the error".

**Recommendations**:
- None for this criterion.

#### Assertion Quality Assessment

- **Assertion density**: 4.59 (101 assertions across 22 test methods) — the highest of the ten panel files, appropriate for pipeline tests that must assert on state at several points along a flow. No zero-assertion test methods.
- **Behavioral assertions**: Behavioral throughout, and multi-axis. Pipeline tests characteristically assert the primary outcome, the side effect (log content), and the non-effect (neighbouring row unchanged) in the same test. No weak `is not None`-only assertions.
- **Edge case assertions**: Strong. Covers the duplicate-start race, a zero-target close, an in-flight stop adopted by shutdown rather than double-drained, a hung worker hitting the watchdog backstop, a raising consumer inside the poll thread, and a failing callback inside the dispatcher.
- **Mutation testing** _(optional)_: Not performed — no mutation-testing tool is configured for this project.

---

### 2. Coverage Completeness
**Question**: Are all implementable scenarios covered with tests?

**Assessment**: PASS (with a documented architectural observation)

**Code Coverage Data** _(from `Run-Tests.ps1 -All -Coverage`, 2026-08-13)_:

| Source Module | Coverage % | Uncovered Areas |
|---------------|-----------|-----------------|
| `linkwatcher_control_panel/app.py` | 36% (120 stmts, 77 missed) | 88–144 `ControlPanelApp.__init__` (Tk root); 155, 163–164, 172–179 `post`/`_pump_dispatch_queue`/`_ui_tick`; 186–204 `_on_*` handler delegates; 222–243 `surface`/`_request_foreground`; 257–272 `_on_close`; 283–292 `_finish_shutdown`/`_exit_now`; 296–297 `run` |
| `linkwatcher_control_panel/lifecycle.py` (`ShutdownOrchestrator`) | covered via INT-5/6 | see TE-TAR-090 |

**Overall Project Coverage**: 83% (whole project); 91.6% across the non-widget panel modules.

**Findings**:
- **Existing Implementation Coverage**: All nine specified INT scenarios are covered. The pipeline *logic* is well covered — the orchestration under test lives in `discovery.py`, `lifecycle.py`, `model.py`, and `config_edit.py`, all of which sit at 85–100%.
- **Code Coverage Gaps**: `app.py`'s 36% is structural, not a testing shortfall. The only part of the module reachable without a Tk root is `drain_queue`, which was deliberately extracted to module level in Phase G precisely so the dispatcher could be tested headlessly (feature-state Decision 11a) — and it *is* tested. Everything else is `ControlPanelApp`, whose construction requires a Tk root that the test spec forbids instantiating ("Tk display: Avoided").
- **Architectural observation (the one worth recording)**: the `Pipeline` harness **mirrors** `app.py`'s wiring rather than exercising it. It reproduces the poller → queue → dispatcher → model flow faithfully and imports the real `drain_queue`, but `ControlPanelApp`'s own composition is not itself under test. Consequently `_on_close` → `_finish_shutdown` → `_exit_now` — the AC-9 "close can never hang" path — is verified at the `ShutdownOrchestrator` level (INT-5/INT-6) but not through the app's own close handler. **Risk**: if `app.py`'s wiring changes, the mirror does not automatically follow, and these tests would keep passing against a stale reproduction.
- **Why this is accepted rather than flagged as a defect**: it is the direct consequence of the spec's no-widget rule, it is mitigated by scripted real-Tk runs recorded in the feature state file (Phase D verified a real close-with-running-daemon exiting in 4.9 s; Phase E ran 14/14 checks against a real window), and there is no cheap automated alternative — closing it would require Tk in CI. Recorded so the residual risk is visible rather than implied.
- **Missing Test Scenarios**: None against the specification.
- **Placeholder Test Quality**: N/A — no placeholder tests.
- **Edge Cases Coverage**: Strong — see criterion 1.

**Evidence**:
- `python -m pytest <panel dir> --cov=...app` → `app.py 120 77 36% 88-144, 155, 163-164, 172-179, 186, 189, 192, 195, 198, 202-204, 222-228, 232-243, 257-272, 283-287, 290-292, 296-297` — every uncovered range is inside `ControlPanelApp`; the covered remainder is `drain_queue`.
- The harness docstring is explicit about being a reproduction: "reproduces the app's queue-and-dispatch wiring so the pipeline is exercised exactly as `app.py` drives it, but synchronously" — the mirror is deliberate and documented, not accidental.

**Recommendations**:
- Keep the `Pipeline` harness and `ControlPanelApp` in sync deliberately: when `app.py`'s wiring changes, treat updating the harness as part of that change. Consider a comment cross-reference in `app.py` pointing at the harness.
- Treat `app.py` as an accepted coverage exclusion rather than a coverage target, on the same footing as the `PsutilProcessTable` / `SubprocessRunner` adapters.

---

### 3. Test Quality & Structure
**Question**: Could the test be optimized?

**Assessment**: PASS

**Findings**:
- The `Pipeline` harness is the file's central design decision and a good one: it collapses ten-parameter wiring into `cycle()` / `pump()` / `status()`, so each test reads as a sequence of poll cycles and state assertions rather than plumbing.
- Determinism is engineered deliberately — synchronous `executor`, `post=queue.put`, and a fake clock — so pipeline tests carry no ordering flakiness despite modelling a threaded system.
- Local helpers (`_two_project_pipeline`, `_save_and_notice`) keep the multi-project isolation tests readable; `_save_and_notice` explicitly mirrors `ConfigPane.save` and says so.
- Exception-injecting doubles (`ExplodingTerminator`, `ExplodingRunner`, `FlakyProcessTable`) are small, purpose-named, and defined near use. `FlakyProcessTable` has a flippable `fail` attribute, enabling failure-then-recovery in a single test.

**Evidence**:
- The module docstring pre-empts a reviewer's likely objection about the word "parallel": it states that with the synchronous executor, drains run back-to-back on one shared fake clock, so elapsed fake time is the *sum* of per-project drains, and that assertions target outcomes and bounds rather than wall-clock overlap. That is exactly the caveat an auditor would otherwise raise.

**Recommendations**:
- None.

---

### 4. Performance & Efficiency
**Question**: Are tests efficient and performant?

**Assessment**: PASS (with one improvement opportunity)

**Findings**:
- 22 pipeline tests in ~1.4 s of the 2.03 s Session-2 run. Drains covering 20 s of grace period cost no real time, via the fake clock.
- Two tests legitimately use real threads, to prove the poll thread genuinely runs in production rather than only under the synchronous harness. That is the right call — a purely synchronous suite could not catch a thread that never starts.
- **Improvement opportunity**: `test_a_failing_consumer_does_not_kill_the_poll_thread` uses `deadline.wait(0.3)` — an `Event` that is never set, used purely as a fixed 300 ms sleep — then asserts `len(calls) > 1`. This is the only fixed real-time wait in the entire panel suite and accounts for most of that test's 0.31 s. The margin is generous (poll interval 0.01 s, so ~30 cycles expected against a threshold of 1), so flakiness risk is low but not zero on a heavily loaded machine.
- Notably, the file already contains the better pattern one test earlier: `test_poller_thread_delivers_results_to_the_queue` uses `delivered.wait(timeout=5.0)` — an event-driven wait that returns as soon as the condition holds (~10 ms) and treats the timeout purely as a failure bound, with an assertion message.

**Evidence**:
- Slowest two tests in Session 2, both from this file: `test_a_failing_consumer_does_not_kill_the_poll_thread` 0.31 s, `test_watchdog_forces_completion_when_a_worker_hangs` 0.28 s. Every other test in both files is ≤0.05 s.

**Recommendations**:
- Convert the fixed 300 ms wait to the event-driven pattern already used by its neighbour: set an `Event` on the second consumer call and `wait(timeout=…)` on it. Faster and deterministic. Deliberately **not** applied as a minor fix during this audit — it restructures test control flow, which falls outside the Minor Fix Authority list (assertions, renames, dead code, trivial fixture values, markers, tolerances).

---

### 5. Maintainability
**Question**: Will these tests be maintainable long-term?

**Assessment**: PASS

**Findings**:
- The module docstring is a phase-by-phase map of which scenarios arrived when (Phase B convergence, Phase C actions, Phase D shutdown, Phase E config notice, Phase G error isolation), giving a maintainer the file's growth history and current scope in one read.
- Deliberate limitations are documented rather than left for a reader to discover — the "parallel" caveat, the no-Tk rule, and why the file is marked `unit` despite holding INT scenarios (this project's Python config defines no separate integration directory).
- The `panel_log` fixture asserting against a real log file makes the INT-8 tests self-explanatory: the assertion `"stop_worker_failed" in panel_log()` names the exact production log event, so a maintainer renaming that event learns immediately which contract they broke.
- Principal maintainability risk is the harness/`app.py` mirror-drift recorded under criterion 2 — a documentation and discipline issue rather than a code-quality one.

**Evidence**:
- Tests assert on log *event names* (`discovery_poll_failed`, `dispatch_callback_failed`, `validation_worker_failed`), which are stable machine-readable tokens rather than prose — a better coupling choice than the human-readable detail substrings used elsewhere in the suite.

**Recommendations**:
- Add a pointer in `app.py` to the `Pipeline` harness so the coupling is discoverable from the production side.

---

### 6. Integration Alignment
**Question**: Do tests align with overall testing strategy?

**Assessment**: PASS

**Findings**:
- Full marker compliance (`feature`, `priority("Critical")`, `test_type("unit")`, `specification`), with the `unit` marker choice explained in the docstring rather than left as an apparent inconsistency.
- Honors every rule the test spec sets for this layer: no Tk instantiated; `LinkWatcherConfig` never mocked (INT-7 calls the real `save_config`); fakes injected through designed seams; real temp files where filesystem behavior matters.
- Correct division of labour with its siblings: unit files own component behavior, this file owns composition. Where they touch — e.g. drain semantics — this file asserts the *pipeline* consequence (pin posted, resolved by poll truth) while `test_panel_lifecycle.py` asserts the *mechanism*. No redundant duplication.
- Imports only public surfaces (`drain_queue`, `save_config`, `DiscoveryPoller`, `LifecycleController`, `ShutdownOrchestrator`, `ValidationController`, `config_notice`), confirming the composition seam is genuinely public.

**Evidence**:
- INT-7 imports `config_notice` from `views.rendering` and `save_config` from `config_edit`, composing the two exactly as `ConfigPane.save` does — the integration point is tested through the same public functions production uses.

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
All six criteria pass. All nine specified scenarios (INT-1…INT-9) are implemented, traceable, and passing, with the highest assertion density in the feature (4.59) and a multi-axis assertion style — outcome, side effect, and non-effect on a bystander — that makes the isolation claims genuinely verified rather than asserted. Convergence is tested as a *bound* (within two poll cycles) rather than an eventual outcome, matching the TDD's stated target.

The one substantive observation is architectural rather than a defect: the `Pipeline` harness mirrors `app.py`'s wiring instead of exercising it, so `ControlPanelApp`'s own composition — including the `_on_close` → `_finish_shutdown` → `_exit_now` path — is covered only by scripted real-Tk runs. This follows directly from the test spec's no-widget rule, is documented in the harness docstring, and has no cheap automated remedy. It is recorded here so the residual risk stays visible; it does not warrant withholding approval, since every scenario the specification asks for is covered and the logic those scenarios exercise lives in modules covered at 85–100%.

### Critical Issues
- None.

### Improvement Opportunities
- **Harness/`app.py` mirror drift** (architectural, accepted): keep `Pipeline` in sync with `app.py` deliberately; a wiring change in production will not fail these tests. Suggest a cross-reference comment in `app.py`.
- **One fixed 300 ms real sleep**: `test_a_failing_consumer_does_not_kill_the_poll_thread` uses `deadline.wait(0.3)` as a sleep. Convert to the event-driven pattern its neighbour already uses — faster and deterministic.
- **`ControlPanelApp` close path** (`_on_close`/`_finish_shutdown`/`_exit_now`) has no automated coverage; AC-9 is verified at the orchestrator level and by live runs only.

### Strengths Identified
- **Isolation verified against a real bystander**: every INT-8 case asserts a *neighbouring project's* row is untouched, turning "errors are isolated" from a claim into a measured property.
- **Failure *and* recovery in one test**: the discovery-failure case asserts the surfaced error, then flips the fake to healthy and asserts full recovery on the next cycle — the "one bad cycle, not one bad panel" contract.
- **Queue-behind-a-failure proven**: the dispatcher test asserts `applied == ["before", "after"]`, verifying that work queued behind a throwing callback still runs and the queue drains.
- **Busy-guard release on the exception path** is asserted, so error handling is shown to leave the system retryable rather than merely non-crashing.
- **Self-aware documentation**: the docstring pre-empts the "these drains aren't really parallel" objection and explains the `unit` marker choice — an auditor's likely findings are already answered in the file.

## Action Items

### For Test Implementation Team
- [ ] Convert the 300 ms fixed wait in `test_a_failing_consumer_does_not_kill_the_poll_thread` to an event-driven wait.
- [ ] Add a cross-reference comment in `app.py` pointing at the `Pipeline` harness, so wiring changes prompt a harness update.

## Audit Completion

### Validation Checklist
- [x] All six evaluation criteria have been assessed
- [x] Specific findings documented with evidence
- [x] Clear audit decision made with rationale
- [x] Action items defined with assignees
- [x] Test implementation tracking updated
- [x] Test registry updated with audit status

### Next Steps
1. Session 3 of Round 1 audits the remaining five panel test files (settings, log_tail, validation, config_edit, single_instance).
2. Feature 7.1.1 proceeds to Code Review (PF-TSK-005) once the full round completes.

### Follow-up Required
- **Re-audit Date**: Not required (approved).
- **Follow-up Items**: Mirror-drift risk and the fixed-sleep conversion — recorded here as action items; neither registered as tech debt (no cheap fix for the former, trivial for the latter).

---

**Audit Completed By**: AI Agent
**Completion Date**: 2026-08-13
**Report Version**: 1.0
