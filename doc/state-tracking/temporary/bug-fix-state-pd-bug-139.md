---
id: PF-STA-112
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-08-25
updated: 2026-08-27
affected_dimensions: DI OB ID
bug_id: PD-BUG-139
bug_name: panel-started-daemon-logged-zero-file-events-for-its-entire-lifetime
severity: High
---

# Bug Fix State: PD-BUG-139 — Daemon silently stops receiving file events while reporting healthy

> **TEMPORARY FILE**: This file tracks multi-session bug fix work for complex/architectural bugs. Created by Bug Fixing task (PF-TSK-007) when effort is "Large". Move to `state-tracking/temporary/old/` when fix is verified and closed.

## Bug Fix Overview

| Metadata | Value |
|----------|-------|
| **Bug ID** | PD-BUG-139 |
| **Bug Title** | Daemon silently stops receiving file events while reporting healthy |
| **Severity** | High |
| **Affected Feature** | 1.1.1 - File System Monitoring |
| **Estimated Sessions** | 3 |
| **Created** | 2026-08-25 |

## Root Cause Analysis

- **Symptom**: A running daemon delivered file events during its initial scan (`replaying_deferred_events count=2` at 14:09:47.372), then delivered nothing for its remaining 34 s of life. A move performed at ~14:10:21 inside the watched tree produced no log record and no reference update. The daemon reported healthy throughout and the panel polled it as running.

- **Root Cause (detection gap — PROVEN)**: `service.py` monitors watch health with `self.observer.is_alive()` only ([service.py:163](../../../src/linkwatcher/service.py)). That checks the watchdog **dispatcher** thread. On Windows the actual event *producer* is a separate per-watch **emitter** thread (`WindowsApiEmitter`), and watchdog can lose it while the observer thread keeps running. When that happens the daemon is permanently blind, `observer.is_alive()` stays `True` forever, and nothing is logged. This is the gap left by the PD-BUG-018 fix: that fix detects a *dead observer thread*; this is a *live observer with no working emitter*.

  Measured (probe `probe_emitter_liveness.py`, watchdog 6.0.0, `WindowsApiObserver`):

  | Scenario | `observer.is_alive()` | emitter alive | events delivered after | stderr |
  |----------|----------------------|---------------|------------------------|--------|
  | A. control (healthy) | True | True | 4 | — |
  | B. emitter self-stop | **True** | False | **0** | **none** |
  | C. `queue_events` raises | **True** | False | **0** | traceback |

  Scenario B reproduces the bug signature exactly: alive, silent, permanent, no diagnostic output of any kind.

- **Upstream defect found (PROVEN, watchdog 6.0.0)**: `winapi._is_observed_path_deleted()` decides "the watch root was deleted" by comparing `GetFinalPathNameByHandleW(..., VOLUME_NAME_NT)` against the watch path. The first returns an **NT device path**, the second is a **DOS path**, so they can never be equal. Measured on a healthy, existing directory (probe `probe_observed_path_deleted.py`):

  ```
  watch path passed in      : C:\Users\ronny\AppData\Local\Temp\pd139_nt_km_7qo7k
  GetFinalPathNameByHandleW : \Device\HarddiskVolume3\Users\ronny\AppData\Local\Temp\pd139_nt_km_7qo7k
  directory still exists    : True
  _is_observed_path_deleted(healthy, existing dir) -> True
  ```

  Consequence: **any** transient `OSError` out of `ReadDirectoryChangesW` (other than `ERROR_OPERATION_ABORTED`) is misread as a deletion of the watch root, which makes `WindowsApiEmitter.queue_events()` call `self.stop()` — killing the emitter silently and permanently, with the `OSError` swallowed so no traceback is produced.

- **Trigger for THIS incident (NOT proven — and not determinable from the preserved evidence)**: three candidate paths lead to silent emitter loss; the evidence discriminates between them as follows.

  | Candidate | Expected fingerprint | Present in evidence? | Verdict |
  |-----------|---------------------|----------------------|---------|
  | Unguarded exception in `EventEmitter.run()` (no `try/except`) | Python traceback on stderr | `LinkWatcherError.txt` is **0 bytes**, and the launcher does redirect stderr (`start_linkwatcher_background.ps1:350`) | **Ruled out** |
  | `is_removed_self` → `emitter.stop()` (incl. the NT-path misfire above) | `directory_deleted` INFO record — `queue_events` queues `DirDeletedEvent(watch.path)` *before* stopping, and `_handle_directory_deleted` logs at INFO ([handler.py:811](../../../src/linkwatcher/handler.py)) | Absent — the log ends at `monitoring_started` | **Ruled out for this incident** |
  | Emitter alive but `read_events()` yielding nothing forever (e.g. repeated `ERROR_OPERATION_ABORTED`, which returns `(buffer, 0)`), or an OS-level watch drop | **none whatsoever** | n/a — leaves no fingerprint | **Remaining candidate; unfalsifiable from the evidence** |

  Handler-side silent-drop (own-output / ignored-directory filters) is ruled out by the triage reproductions: attempts 1–3 exercised the identical workspace, launcher and action and detected the move in 75–191 ms.

  **Consequence for the fix**: the surviving candidate leaves no fingerprint by construction, so no amount of further log forensics on the preserved evidence can identify the trigger, and no trigger-specific fix can be validated. This is the empirical case for detecting the failure at the **delivery level** rather than fixing one suspected trigger.

- **Affected Components**:
  - `src/linkwatcher/service.py` — health poll (the detection gap)
  - `src/linkwatcher/handler.py` — event receipt point (delivery observation site)
  - watchdog 6.0.0 `observers/api.py`, `observers/winapi.py`, `observers/read_directory_changes.py` — third-party, upstream defect

- **Secondary Issues Discovered**:
  1. `EventEmitter.run()` (watchdog `observers/api.py:156`) has no exception guard — any raise kills the emitter permanently.
  2. `_is_observed_path_deleted()` NT-vs-DOS path comparison (above) — a genuine upstream defect worth reporting to watchdog.
  Both are third-party; classified per the Issue Classification and Routing Guide as vendor defects to be worked around locally, not as separate product bugs.

### Affected Dimensions

- **Data Integrity (DI)**: A blind daemon silently drops reference updates — files referencing a moved target are left stale with no error and no user signal. Damage is silent and unbounded in time (the whole remaining daemon lifetime).
- **Observability (OB)**: The core failure mode of the product — "am I still watching?" — is unobservable. The one health signal that exists (`observer_thread_died`) cannot fire for this class, and a healthy-looking log is indistinguishable from a blind daemon.
- **Integration & Dependencies (ID)**: The watchdog dependency's thread liveness is verified, but its *event delivery* never is. The failure originates in third-party code whose silent-failure paths the integration does not defend against.

### Dimension-Informed Fix Requirements

- **DI**: Detection alone is insufficient — on detection the fix must attempt to restore delivery (re-arm the watch) so updates are not silently lost, and must make the gap explicit where restoration is impossible.
- **OB**: The failure must produce a loud, unambiguous ERROR record naming the condition, and the daemon must not continue reporting healthy while blind.
- **ID**: The check must verify the dependency's *observable output* (events actually arriving), not its internal thread state, so it holds regardless of which watchdog internal path failed — including the unfalsifiable candidate above and any future upstream regression.

## Fix Approach

- **Chosen Approach** (human-approved 2026-08-25): two layered health checks plus loud failure — **detect and report, do not recover**.
  1. **Emitter liveness** (`WatchLivenessMonitor._emitters_are_alive`) — every poll, assert the observer has at least one emitter and all are alive. Cheap, conclusive on first observation (a dead thread never revives), and names the condition precisely.
  2. **Delivery canary** (`WatchLivenessMonitor._delivery_is_flowing`) — after `watch_liveness_idle_seconds` of total silence, write a sentinel inside the watched tree and require its event back within `watch_liveness_probe_timeout`. Verifies delivery *end to end*, so it holds regardless of which watchdog internal path failed.
  3. **On established failure**: log ERROR and stop the daemon cleanly. A running-but-blind daemon is strictly worse than a stopped one — it gives false assurance while losing every update.

- **Rationale**:
  - Check 2 is the *minimum* that fixes this bug, not gold-plating: the only surviving trigger candidate leaves no fingerprint, so a thread-liveness check alone would not have caught this incident. Check 1 is nearly free and supplies the precise diagnosis whose absence made this bug expensive to investigate.
  - Probing **on suspicion** rather than on a timer is what makes the canary viable: a passive "time since last event" heartbeat cannot distinguish a quiet repository from a blind daemon, while an unconditional timer would write constantly. Silence-gated probing means zero writes on active repositories and bounded latency on quiet ones.
  - The delivery check is also the **general workaround** for the two upstream watchdog defects found (below): it detects the *outcome* rather than any one cause, so it needs no monkeypatching of dependency internals and survives future upstream regressions.

- **Alternatives Considered**:
  1. **Emitter-liveness check alone** — rejected: would not have detected this incident. Its detection coverage is a strict subset of the canary's; it was kept only for diagnostic precision and 1-second latency.
  2. **Delivery canary alone** — rejected as *sole* mechanism: sufficient for detection, but reports "delivery stalled" where a lost emitter can be named outright. Keeping check 1 costs ~10 lines.
  3. **Auto-recovery (re-arm the watch in process)** — deliberately deferred. Correct re-arming requires a full re-scan (the DB is stale after a blind window), which is expensive on large trees and would be triggered by a condition we cannot summon on demand; a canary false positive under load would become a flapping re-scan loop. Recovery cannot be tuned before field evidence shows how often this fires. The launcher / Control Panel restart path is an existing, well-tested recovery route.
  4. **Monkeypatch the watchdog defects locally** — rejected: patching a dependency's private functions is fragile across versions, and it would not address the surviving trigger candidate. The delivery check covers all of them at the outcome level.

## Implementation Progress

| File / Component | Change Required | Status | Session |
|------------------|----------------|--------|---------|
| `src/linkwatcher/liveness.py` | **New** — `WatchLivenessMonitor`: emitter-liveness check, silence-gated delivery canary, consecutive-failure threshold | Done | 1 |
| `src/linkwatcher/service.py` | Extract health poll into `_watch_is_healthy()`; build the monitor; sentinel path resolution; `_write_liveness_sentinel` | Done | 1 |
| `src/linkwatcher/handler.py` | `dispatch()` override recording delivery *before* own-output/ignored filtering; consume-and-drop the sentinel; `seconds_since_last_event` / `arm_liveness_probe` / `liveness_probe_observed` | Done | 1 |
| `src/linkwatcher/config/settings.py` | Four `watch_liveness_*` settings with conservative defaults (validation is schema-derived, so no validator changes needed) | Done | 1 |
| `doc/user/handbooks/configuration-guide.md` | Document the four new settings in the Full Reference block | Done | 1 |
| `test/automated/unit/1-file-watching-detection/test_watchliveness.py` | **New** (TE-TST-157) — 15 regression tests | Done | 1 |
| `test/bug-validation/PD-BUG-139_blind_watch_detection_validation.py` | **New** — before/after manual validation | Done | 1 |
| `src/linkwatcher/service.py` | **Code-review fix** — `_liveness_sentinel_path` read the exclusion registry *dict* instead of its `dirs` set, so the own-output branch was unreachable; plus `LIVENESS_SENTINEL_NAME` constant and `_remove_liveness_sentinel()` cleanup in `stop()` | Done | 2 |
| `src/linkwatcher/liveness.py` | **Code-review fix** — both ERROR messages now direct the operator to a `--validate` scan for references left stale during the blind window | Done | 2 |
| `src/linkwatcher/config/settings.py` | **Code-review fix** — `watch_liveness_failure_threshold` floor of 2 via `_NUMERIC_MINIMUMS`, with the below-minimum message generalized beyond the 0 case | Done | 2 |
| `test/automated/unit/1-file-watching-detection/test_watchliveness.py` | **Code-review fix** — +9 tests (15 → 24): sentinel placement and cleanup, repair guidance, threshold floor | Done | 2 |

## Validation Status

- [x] Regression test(s) written and confirmed FAILING before fix — 14 failed / 1 passed pre-fix; failures were missing-capability (`AttributeError`, `ModuleNotFoundError`) and one clean assertion failure, not setup errors. The single pre-fix pass characterizes the watchdog behaviour itself and is expected to pass in both states.
- [x] Fix implemented — regression tests now PASSING (15/15; **25/25** after Session 2)
- [x] Full test suite passing
- [x] Similar patterns checked in sibling components
- [x] Manual validation test created — and it PASSES with a real before/after contrast
- [x] **Session 2** — Code Review findings addressed; 5 new tests confirmed FAILING first, each for its own stated reason
- [x] **Session 2** — verified in the real deployment shape, not only the harness: a real `python main.py` run placed the probe in `logs/linkwatcher/` and left the project root clean
- [x] **Session 2** — registry-misuse sweep repeated across both other `compute_own_output_exclusions` call sites (`handler.py:182`, `service.py` initial scan): both consume the dict correctly, so the defect was a single occurrence

**Test Suite Results**: All passing. The full-suite run additionally caught a missing documentation update via the config schema-drift guard (`test_configschemadrift.py`), which was resolved by documenting the four new settings.

**Manual validation evidence** (`PD-BUG-139_blind_watch_detection_validation.py`, exit 0):

| | `observer.is_alive()` after watch death | daemon kept running | move detected | reference |
|---|---|---|---|---|
| PRE-FIX (detector disabled) | **True** | **yes — blind** | no | left stale |
| POST-FIX (detector enabled) | True | **no — stopped** | n/a | n/a, `observer_emitter_died` logged |

**Secondary defect found and fixed during implementation**: `logger.error("event", message=...)` raises `TypeError` — the logger's first positional parameter *is* `message`. The pre-existing `observer_thread_died` line (`service.py`, from the PD-BUG-018 fix) carried this defect, so the one health-failure log the product already had would have crashed instead of logging. Found because the new code copied that call shape and the manual validation exercised it. All four sites (three new, one pre-existing) now pass context as `detail=`. A repository-wide sweep confirmed no other occurrence.

## Documentation Updates

| Document | ID | Action | Status |
|----------|----|--------|--------|
| Feature State File (1.1.1) | — | Update — bug history, code inventory, test inventory | Done |
| TDD | tdd-1-1-1-file-system-monitoring-t2 | Update — liveness monitor section + event-flow row | Done |
| Test Specification | test-spec-1-1-1-file-system-monitoring | Update — watch-liveness coverage row | Done |
| FDD | fdd-1-1-1-file-system-monitoring | Update — new edge case 1.1.1-EC-11 (also corrected a stale EC-9 checklist range) | Done |
| Configuration Guide | PD-HBK | Update — four new settings | Done |
| Capabilities Reference | PD-HBK | Update — Watch Liveness section, 4 config rows, scope caveat | Done |
| TDD (session 2) | tdd-1-1-1-file-system-monitoring-t2 | Update — sentinel placement in the own-output directory, shutdown removal, and the validated threshold floor | Done |
| FDD (session 2) | fdd-1-1-1-file-system-monitoring | Update — EC-11 now states the two-part recovery (restart, then validate) and that the single-missed-probe guarantee cannot be configured away | Done |
| Capabilities Reference (session 2) | PD-HBK | Update — repair-after-blind-window guidance, threshold floor, sentinel location and cleanup | Done |
| Configuration Guide (session 2) | PD-HBK | Update — threshold minimum noted inline | Done |
| Test Specification (session 2) | test-spec-1-1-1-file-system-monitoring | Update — the watch-liveness row enumerates test classes, so the two new ones (`TestBlindWatchRepairGuidance`, `TestLivenessSentinelPlacement`) and the threshold floor were added; an initial "still accurate" read was wrong and corrected on verification | Done |

## Session Log

### Session 1: 2026-08-25

**Scope**: Investigation, design approval, implementation, verification, documentation.

**Investigation**
- Ruled out two of three silent-emitter-loss candidates from the preserved evidence (`C:/tmp/pd139-evidence/`): an unguarded exception would have written a traceback (`LinkWatcherError.txt` is 0 bytes and the launcher *does* redirect stderr), and the `is_removed_self` path would have left a `directory_deleted` INFO record (none exists). The surviving candidate leaves no fingerprint by construction, so the trigger is not determinable from this evidence — which is the empirical case for detecting at the delivery level rather than fixing one suspected trigger.
- Measured two genuine upstream watchdog 6.0.0 defects (probes in the session scratchpad): `EventEmitter.run()` has no exception guard, and `_is_observed_path_deleted()` compares an NT device path against a DOS path so it returns True for a healthy directory — meaning any transient `OSError` from `ReadDirectoryChangesW` is misread as a deleted watch root and silently stops the emitter.
- Corrected the bug title: the panel is incidental (`lifecycle.py` shells out to the same launcher a successful reproduction attempt used), so "Panel-started daemon…" pointed investigators at the wrong component.

**Checkpoint (human-approved)**: layered detection (emitter liveness + delivery canary), report-only (no in-process recovery), title corrected.

**Implementation**: see Implementation Progress. Tests were written first and confirmed failing (14 failed / 1 passed) before any production code changed.

**Verification**
- Regression suite: 15/15 passing.
- Full automated suite: **1584 passed, 3 skipped, 3 xfailed, 0 failures**.
- Manual validation (`PD-BUG-139_blind_watch_detection_validation.py`): exit 0, clean before/after — pre-fix the daemon runs blind and leaves the reference stale; post-fix it logs `observer_emitter_died` and stops.
- Real-observer canary verification (both directions): a healthy daemon left idle 15 s past the silence gate kept running with zero failures, the sentinel was written (so the canary genuinely ran), the link database stayed at 1 reference (sentinel never parsed), and a real move was still handled correctly. A separate 24 s observation showed `consecutive_failures` flat at 0 throughout. **No false positive.**
- One intermediate probe appeared to show a false positive; that was a race in the probe itself — it sampled `service.running` before the service thread had set it, so the loop exited at 0.0 s and the database was read pre-scan. Re-run with the race removed, it passes. Recorded because the false-positive risk is the main hazard of this fix and the evidence against it should be legible.

**Decisions taken**
- **E2E re-execution not flagged.** `Update-TestExecutionStatus.ps1 -WhatIf` for feature 1.1.1 shows a cascade of **34 entries across 7 features and 7 workflows**, because the covering E2E tests are cross-cutting. The fix is additive detection: no move-handling code path changed, and the silence gate (60 s default) is never reached in an E2E run measured in seconds. Per the task's guidance to weigh the cascade against the behavioural delta, flagging would bury the genuinely-failing WF-010 signal under 34 spurious ones. WF-010 / TE-E2E-036 — the case that exposed this bug — is already at 🔄 Needs Re-execution and will re-verify it.
- **Upstream defects not worked around in code.** The delivery canary detects the *outcome*, so it covers both watchdog defects and any future upstream regression without monkeypatching dependency internals. The NT-vs-DOS defect is worth reporting upstream and filing separately as a latent path; it is ruled out as the trigger for *this* incident.

**Next session**: Code Review (PF-TSK-005), which closes the bug on approval.

### Session 2: 2026-08-27

**Scope**: Address the Code Review rejection (2026-08-26), re-verify, return to Needs Review.

**Review outcome addressed** — one Major (blocking) plus three Minors, all in this fix's own change set:

- **MAJOR — the sentinel never landed where the code said it did.** `_liveness_sentinel_path` iterated the *dict* returned by `compute_own_output_exclusions`, so it walked the key strings `"dirs"` and `"file_stems"`, matched neither as a directory, and fell through to the project-root fallback in **every** deployment. The documented defense-in-depth was unreachable dead code, and each watched project collected a `.linkwatcher-liveness-probe` dotfile in its root that was rewritten every idle window and never removed. Fixed by reading `own_output["dirs"]`.
- **MINOR — no coverage.** `_liveness_sentinel_path` was the only unit in the change set with no test, which is exactly why 15/15 passed over a broken function. Now covered in both branches plus cleanup.
- **MINOR — repair guidance.** Both ERROR messages told the operator to restart, which restores monitoring but repairs nothing; they now also direct them to a `--validate` scan for references left stale during the blind window. DI was a Critical dimension for this bug, so this closes the gap the state file itself named.
- **MINOR — configurable-away guarantee.** `watch_liveness_failure_threshold: 1` passed schema validation (which only rejects values ≤ 0) while voiding the FDD 1.1.1-EC-11 promise that a single missed probe never stops a daemon. Now floored at 2 via `_NUMERIC_MINIMUMS`, with the below-minimum message generalized beyond the 0 case.

**Two further defects found while verifying** — neither was in the review findings:

1. **The sentinel path could be resolved differently at write time and at cleanup time** (it depends on whether the log directory exists yet), so cleanup could name a different file than the probe actually wrote and leave the real one behind. Resolved once and pinned for the daemon's lifetime.
2. **`stop()` never runs on the paths that matter.** Its body is guarded by `if self.running`, and *every* path leaving the monitoring loop — a liveness failure, `_signal_handler` — clears that flag first, so `start()`'s `finally: self.stop()` finds it already False and skips everything. Measured: a validation run whose POST-FIX half self-stopped logged `observer_emitter_died` once and `service_stopping` / `file_observer_stopped` / `service_stopped` **zero** times. Pre-existing since the PD-BUG-018 health-stop path (confirmed against git HEAD), so filed separately as **PD-BUG-144** rather than absorbed here. The sentinel cleanup was placed deliberately *outside* the guard so this fix does not inherit the defect, and a regression test pins that placement.

**Verification**

- Regression suite: 25/25 passing (15 → 25; +10 this session). Five of the new tests were confirmed FAILING first, each for its own stated reason rather than a setup error.
- Coverage of the change set: `liveness.py` 95%, and `_liveness_sentinel_path` — 0% at review time, with no reference to it anywhere in the test tree — now covered.
- Manual validation: extended with a sentinel-placement half and **passes end to end** (exit 0): probe written beside the daemon's own log, project root clean, probe removed on shutdown, blind state still reproduced and still detected.
- **Real-daemon check** (not just the harness): a real `python main.py` run against a scratch project with file logging configured put the probe in `logs/linkwatcher/` and left the project root clean — confirming the fix in the deployment shape, not only in test doubles.

**Harness defects corrected** (both would have produced false confidence):
- `make_service` never created the log directory, so the harness exercised the project-root fallback and would have "verified" a shape no real deployment has.
- The placement wait loop sampled `service.running` before the service thread had set it and exited instantly, reporting a probe that simply had not been written yet — the same race that produced a spurious false positive in Session 1.

**Next session**: Code Review (PF-TSK-005), re-review scoped to this delta per the repeat-review rule.

## Completion Criteria

This file can be archived to `state-tracking/temporary/old/` when:

- [x] Bug status is 🔒 Closed — Code Review 2026-08-27 (PF-TSK-005) approved the Session 2 delta and closed it; two non-blocking residuals filed as PD-BUG-145. Ready to archive to `state-tracking/temporary/old/`.
- [x] All implementation progress items are Done
- [x] All validation checks pass
- [x] Documentation updates completed (or confirmed N/A)
- [x] Bug tracking entry updated with resolution details
