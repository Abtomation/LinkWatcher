---
id: PF-STA-111
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-08-17
updated: 2026-08-18
enhancement_name: code-review-gap-closure
inherited_dimensions: AC:Critical, SE:Critical, UX:Critical, DI:Critical, CQ:Critical (elevated from Relevant), OB:Critical (elevated from Relevant), ID:Relevant, DA:Relevant, EM:Relevant, PE:Relevant
target_feature: 7.1.1
---

# Enhancement State Tracking: Code Review Gap Closure

> **TEMPORARY FILE**: This file tracks enhancement work on an existing feature. Created by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068). Move to `state-tracking/temporary/old/` when all steps are complete.

> **⚠️ Link-depth note (framework defect, corrected here)**: the generating template carries its
> links at `../../..` depth, which is correct from `process-framework/templates/04-implementation/`
> but resolves to `doc/tasks/…` from this file's actual location. All 17 links in the generated
> file were broken; they are corrected to `../../../process-framework/…` below. Filed as a
> framework improvement so the next generated file is clean (see Session Log).

## Enhancement Overview

| Metadata | Value |
|----------|-------|
| **Target Feature** | 7.1.1 — LinkWatcher Control Panel ([state file](../../features/7.1.1-LinkWatcher-Control-Panel-implementation-state.md)) |
| **Secondary Features Affected** | None. The panel is a leaf supervisor and no product feature depends on it. `deployment/install_global.py` and `pyproject.toml` are co-owned with the release/dev tooling, which is deliberately process rather than a tracked feature. |
| **Enhancement Description** | Close the 19 product-path implementation gaps CR-2 through CR-20 recorded by Code Review on 2026-08-17 in the feature 7.1.1 state file §10: one Critical config-destruction defect, four Major findings, eleven Minor and three Suggestion. Excludes CR-1 (hook auto-open), which is a framework-path fix filed as PF-IMP-2032. |
| **Change Request** | Ad-hoc human request, 2026-08-17: *"work on feature 7.1.1"*. Resolved at the classification checkpoint to closing the Code Review gap table — the feature's own §11 next step. No originating `PD-FRQ-*` row exists. |
| **Human Approval** | 2026-08-17 — classification (Enhancement), target feature (7.1.1) and full-scope option (all 19 product-path findings) all confirmed by the human partner at the combined Step 7 / Step 17 checkpoint. |
| **Estimated Sessions** | 3 |
| **Created By** | Feature Request Evaluation (PF-TSK-067) |

### Source of the work items

The authoritative finding list is the **Open Implementation Gaps** table in the target feature's
[state file §10](../../features/7.1.1-LinkWatcher-Control-Panel-implementation-state.md). It is not
duplicated here — each execution block below names the CR-IDs it covers, so the executing task
reads the finding text from §10 and records outcomes back into it.

| Severity | Findings | Count |
|----------|----------|-------|
| 🔴 Critical | CR-2 | 1 |
| 🟠 Major | CR-3, CR-4, CR-5, CR-6 | 4 |
| 🟡 Minor | CR-7 … CR-17 | 11 |
| 🔵 Suggestion | CR-18, CR-19, CR-20 | 3 |
| ⛔ **Out of scope** | CR-1 (framework path → PF-IMP-2032) | 1 |

> **🚨 Release-gating dependency — read before finalizing.** CR-1 is **not** closed by this
> enhancement. Acceptance criteria FR-8, UI-7, BR-8 and the AC-11 first clause therefore remain
> **UNMET** when every block below is done, because the fix lives in
> `process-framework/tools/linkWatcher/start_linkwatcher_hook_wrapper.ps1` (framework path) and a
> local edit there is reverted by the next rollout — which is exactly what happened on 2026-08-14.
> **PF-IMP-2032** must land through Process Improvement before the feature can legitimately reach
> `🟢 Completed`; the re-review this enhancement routes to will otherwise bounce it on the same
> criterion. Do not "close" AC-11 in any record from inside this enhancement.

## Scope Assessment

| Criterion | Assessment |
|-----------|------------|
| **Files Affected** | **11 source files.** Panel subpackage (9): `config_edit.py` (CR-2, CR-3), `discovery.py` (CR-4, CR-5), `settings.py` (CR-10, CR-11), `lifecycle.py` (CR-8, CR-9, CR-12), `model.py` (CR-7, CR-14), `app.py` (CR-7, CR-19), `views/config_pane.py` (CR-2, CR-15), `views/main_window.py` (CR-6, CR-16), plus subpackage-wide DEBUG instrumentation (CR-13). Outside the subpackage (2): `deployment/install_global.py` (CR-17, CR-20), `pyproject.toml` (CR-18). |
| **Design Docs to Amend** | **TDD PD-TDD-033** — §4.4 identity rule (CR-4/CR-5 change what counts as this project's daemon) and a status note on §4.5/§9 recording that hook auto-open is unimplemented and tracked as PF-IMP-2032. **Test Spec TE-TSP-045** — the Edge-Case Coverage table asserted EC-10/EC-11 covered; CR-2/CR-3 prove that coverage inadequate. **FDD PD-FDD-034 — no change** (the specs are correct; these are conformance failures). **UI Design PD-UIX-003 — no change**: it already specifies `Alt+S` = Start (§4.2 line 216), `Ctrl+S` = Save (line 464) and arrow-key list navigation (line 521), so CR-6 and CR-15 are code-into-conformance fixes, not spec changes. **ADR — N/A** (none exist for this feature). |
| **New Tests Required** | **Yes — new cases in existing files, no new test file.** Regression coverage per finding across `test_panel_config_edit.py`, `test_panel_discovery.py`, `test_panel_settings.py`, `test_panel_lifecycle.py`, `test_panel_model.py`, `test_panel_views.py`, `test_panel_integration.py`. Every added assertion must be load-bearing: state the condition under which it would fail, and mutation-verify it. |
| **Interface Impact** | **Internal only** for the panel (no public API — PD-FDD-034 introduces no API contract, and no core module imports the panel). Two externally visible surfaces do change: the declared dependency floor in `pyproject.toml` (CR-18) and installer wrapper generation (CR-17, CR-20). |
| **Session Estimate** | **Multi-session (3).** Rationale: 19 findings over 11 files, with a mandatory full-suite run and a clean-scratch-install verification. Sessions are cut by **defect class**, not by severity order, because CR-2/CR-3/CR-10/CR-11 are one class (a narrow `except OSError` around a call that raises from the `ValueError` family, escaping a documented "never raises" contract) and are cheapest to fix as a single sweep. |

## Existing Documentation Inventory

| Document Type | ID | Location | Action Needed |
|---------------|-----|----------|---------------|
| Feature State File | PD-FIS-056 | [7.1.1-LinkWatcher-Control-Panel-implementation-state.md](../../features/7.1.1-LinkWatcher-Control-Panel-implementation-state.md) | Update on completion (§10 outcomes per CR-ID, §2, §5, §11) |
| FDD | PD-FDD-034 | [fdd-7-1-1-linkwatcher-control-panel.md](../../../functional-design/fdds/fdd-7-1-1-linkwatcher-control-panel.md) | No change — findings are conformance failures against a correct spec |
| TDD | PD-TDD-033 | [tdd-7-1-1-linkwatcher-control-panel-t2.md](../../../technical/architecture/design-docs/tdd/tdd-7-1-1-linkwatcher-control-panel-t2.md) | Amend — §4.4 identity rule; §4.5/§9 auto-open status note |
| UI Design | PD-UIX-003 | [ui-design-7-1-1-linkwatcher-control-panel.md](../../../technical/design/ui-ux/features/ui-design-7-1-1-linkwatcher-control-panel.md) | No change — code is brought into conformance with it |
| ADR | N/A | None exists | No change |
| Test Specification | TE-TSP-045 | [test-spec-7-1-1-linkwatcher-control-panel.md](../../../../test/specifications/feature-specs/test-spec-7-1-1-linkwatcher-control-panel.md) | Amend — new scenarios + Edge-Case Coverage table correction (EC-10/EC-11) |
| Implementation Plan | PD-IMP-003 | [7-1-1-...-implementation-plan.md](../../../technical/implementation-plans/7-1-1-linkwatcher-control-panel-implementation-plan.md) | No change — `status: Completed`; this enhancement is not a new phase of the original plan |

## Dimension Impact Assessment

> **Reference**: [Development Dimensions Guide](../../../../process-framework/guides/framework/development-dimensions-guide.md)
>
> Inherited from parent feature (7.1.1): AC:Critical, SE:Critical, UX:Critical, DI:Critical, CQ:Relevant, ID:Relevant, DA:Relevant, EM:Relevant, PE:Relevant, OB:Relevant
> **Additional for this enhancement**: **CQ (Code Quality & Standards) → Critical** — the dominant defect class *is* a CQ failure: narrow `except OSError` clauses around calls that raise from the `ValueError` family, escaping documented "never raises" contracts. It produced the one Critical finding and three of the Minors. **OB (Observability) → Critical** — four findings are observability failures (CR-13 absent DEBUG instrumentation despite `--debug`; CR-16 errors never reaching the panel log the status bar points the user to; CR-19 UI-thread exceptions vanishing under `pythonw`; CR-3 a blocked save with no log entry), and the panel log is the standing record for "why was my daemon force-stopped".
> **Reduced for this enhancement**: none.

### Key Dimension Considerations

- **Data Integrity (DI — Critical)**: CR-2 destroys another project's configuration file while reporting "Saved."; CR-14 silently discards unsaved edits. Every fix must preserve the existing guarantee that a refused save leaves the file byte-identical (Code Review verified all four refusal paths — do not regress them). Re-verify atomic `os.replace` behaviour after touching the save pipeline.
- **Code Quality & Standards (CQ — Critical, elevated)**: fix the *class*, not the four instances. Sweep every `except` clause in the subpackage against what its guarded call can actually raise, and re-state each module's raising contract in its docstring. `read_config`, `load_panel_settings` and `save_config` all advertise "never raises" and all three can.
- **Security & Data Protection (SE — Critical)**: CR-4/CR-5 weaken the three-way identity guarantee that D-T5 exists to enforce — a `main.py --validate` scan or a wrapper shell must never be claimable as a project's daemon, because the claim authorizes termination. CR-9 (PATH-relative `pwsh.exe`, current-directory-first search) and CR-18 (dependency floor admitting CVE-2023-40590) are the other two. Keep the kill-time re-verification intact.
- **Accessibility / UX Compliance (UX — Critical)**: CR-6 leaves the daemon list unreachable without a mouse — a direct breach of the keyboard-operability requirement the UI Design lists as a checklist item. CR-15 makes `Alt+S` in the config editor **start a daemon** instead of saving. Verify both against a real window, not only headless rules.
- **Architectural Consistency (AC — Critical)**: CR-7 admits a stale poll snapshot overwriting a newer one — a truthful-state violation in the model layer. Any sequencing fix must stay inside the existing observable-model + dispatcher-queue pattern; Tk stays single-threaded, views stay render-from-model-only.
- **Observability (OB — Critical, elevated)**: after this enhancement, a forced termination, a blocked save, a worker exception and a UI-thread callback exception must each leave a panel-log record, and `--debug` must produce the TDD §7.1 instrumentation it advertises.
- **Documentation Alignment (DA — Relevant)**: records that claim the hook auto-open was delivered must be corrected rather than quietly left (TDD §4.5/§9 status note; the feature state file rows already corrected by Code Review). Do not mark AC-11 met.
- **Integration & Dependencies (ID — Relevant)**: installer and packaging changes (CR-17, CR-18, CR-20) sit outside the automated suite — they need a real clean-scratch-install run, not test-suite green.
- **Performance & Scalability (PE — Relevant)**: CR-12 leaks two undeletable `%TEMP%` files per Start; CR-7's guard must not serialize or stall the poll loop. The accepted cold-start limitation stays out of scope (owned by Performance & E2E Test Scoping).
- **Extensibility & Maintainability (EM — Relevant)**: keep fixes on the existing injectable seams so they stay testable without a display; do not introduce a widget dependency into a display-free module.

## Execution Steps

> **Structure**: These steps follow the standard feature development workflow from the [Task Transition Registry](../../../../process-framework/infrastructure/task-transition-registry.md). Each block corresponds to a task type in the workflow. The Feature Request Evaluation task (PF-TSK-067) marks each block as **Applicable** or **Not applicable** based on the enhancement scope. The Feature Enhancement task (PF-TSK-068) executes applicable blocks in order.

---

### Step 1: Tier Reassessment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Documentation Tier Adjustment (PF-TSK-011)](../../../../process-framework/tasks/cyclical/documentation-tier-adjustment-task.md)
- **Rationale**: Not applicable — defect closure inside the existing design. No new subsystem, no new external surface, no change to the complexity factors that produced 🟠 Tier 2 (PD-ASS-201). Finding *count* is not a reassessment trigger; complexity divergence is, and there is none.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 2: FDD Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [FDD Creation (PF-TSK-027)](../../../../process-framework/tasks/02-design/fdd-creation-task.md)
- **Rationale**: Not applicable — every finding is a **conformance failure against a correct specification**, not a specification change. PD-FDD-034 already states the contracts being breached (EC-10 config-read robustness, EC-11 invalid-value explanation, BR-9, AC-12, and the keyboard-operability requirement). Amending it would rewrite a correct document to match defective code.
- **Adaptation Notes**: N/A — but do **not** mark FR-8 / UI-7 / BR-8 / AC-11 as met anywhere: they stay UNMET pending PF-IMP-2032.
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [System Architecture Review (PF-TSK-019)](../../../../process-framework/tasks/01-planning/system-architecture-review.md)
- **Rationale**: Not applicable — all fixes work within the established architecture (observable model, worker threads → dispatcher queue → UI thread, display-free rendering rules). CR-7's poll sequencing is a refinement *of* that pattern, not a new one; no cross-cutting concern is introduced and no ADR is warranted.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [API Design (PF-TSK-020)](../../../../process-framework/tasks/02-design/api-design-task.md)
- **Rationale**: Not applicable — the feature introduces no API contract by design (PD-FDD-034); the panel manages daemons purely through pre-existing external surfaces. Nothing in the CR set adds one.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Database Schema Design (PF-TSK-021)](../../../../process-framework/tasks/02-design/database-schema-design-task.md)
- **Rationale**: Not applicable — no database, no schema, no migrations (feature state file §5). The only persisted panel state is `panel-config.yaml` and the transient `panel.port`.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 6: TDD Amendment

- **Status**: [x] Complete — session 2: §4.4 step 2 + D-T5 (four-way identity, raw-argv restriction). Session 3: §4.5 status note recording hook auto-open as NOT IMPLEMENTED and tracked as PF-IMP-2032, plus the §9 scope note. PD-TDD-033 v1.5 → v1.7
- **Applicable**: Yes
- **Referenced Task Doc**: [TDD Creation (PF-TSK-015)](../../../../process-framework/tasks/02-design/tdd-creation-task.md)
- **Rationale**: Applicable — two changes alter what the TDD documents. CR-4/CR-5 change the **§4.4 three-way identity rule** (a process must be discriminated by executable name / run mode, so a `main.py --validate` scan is never claimed, and the raw-string regex fallback that claims wrapper shells is removed or narrowed); this is the D-T5 invariant, so the design text must move with the code. Separately, §4.5 and the §9 handoff describe hook auto-open as in-scope work of this feature — they need a status note recording it as unimplemented and tracked on the framework path.
- **Adaptation Notes**: Amend in place, do not create a new TDD. (a) §4.4 step 2 + D-T5: add the executable/run-mode discrimination criterion and state the fallback's disposition, keeping the existing normalized-equality rule (never substring) intact. (b) §4.5 / §9: add a dated note that `start_linkwatcher_hook_wrapper.ps1` carries no auto-open call at HEAD or in history, that the 2026-08-10 change was reverted by the 2026-08-14 rollout, and that re-implementation is **PF-IMP-2032** (Process Improvement, framework path) — the design intent stands, the delivery claim does not. (c) Confirm §7.1 DEBUG instrumentation needs **no** amendment — CR-13 implements what §7.1 already requires. Bump the TDD version and `updated:` date per its own convention.
- **Deliverable**: PD-TDD-033 amended (§4.4, §4.5/§9 status note), version bumped
- **Session**: 2 (the §4.4 half, with CR-4/CR-5) and 3 (the §4.5/§9 status note, at close-out)

---

### Step 7: Test Specification

- **Status**: [x] Complete — UNIT-C7/C8, UNIT-S7, UNIT-M8 (s1); UNIT-D11/D12, UNIT-M9, UNIT-L12…L15 (s2); INT-10, UNIT-P1 (s3). EC-10/EC-11 coverage rows corrected with an explicit over-claim note. Coverage line reconciled to 83/83. TE-TSP-045 v1.4 → v1.7
- **Applicable**: Yes
- **Referenced Task Doc**: [Test Specification Creation (PF-TSK-012)](../../../../process-framework/tasks/03-testing/test-specification-creation-task.md)
- **Rationale**: Applicable — TE-TSP-045's **Edge-Case Coverage table (EC-1…EC-11)** claims EC-10 and EC-11 are covered, and CR-2/CR-3 prove that coverage does not reach the failure that matters (a non-UTF-8 file, a type-invalid value). A spec that certifies coverage it does not have will re-certify the same gap at the next audit, so the spec is amended alongside the tests.
- **Adaptation Notes**: Amend TE-TSP-045, do not create a new spec. Add scenarios for: non-UTF-8 config read (EC-10), type-invalid YAML through the real validator (EC-11), the selection-switch failure path that leaves header and editor disagreeing (CR-2's actual mechanism — a pane-state scenario, not just a reader scenario), identity rejection of `--validate` scans and wrapper shells, non-finite panel settings, non-UTF-8 `panel-config.yaml`, stale-snapshot ordering, and arrow-key list navigation. Correct the Edge-Case Coverage table so EC-10/EC-11 point at the *new* cases. Note in the spec that CRLF normalization in `log_tail.py` remains uncovered (TD264, Test Audit TE-TAR-094) and is **not** in this enhancement's scope.
- **Deliverable**: TE-TSP-045 amended (new scenarios + corrected Edge-Case Coverage table), version bumped
- **Session**: 1 (EC-10/EC-11 scenarios), 2 (identity + UX scenarios), 3 (table reconciliation)

---

### Step 8: Feature Implementation Planning

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Feature Implementation Planning (PF-TSK-044)](../../../../process-framework/tasks/04-implementation/feature-implementation-planning-task.md)
- **Rationale**: Not applicable — the work is already enumerated, located and severity-ordered by the §10 CR table, and sequenced by the Session Boundary Planning section of this file. A separate PD-IMP document would duplicate both, against the framework's own "update state files rather than create new docs" principle. PD-IMP-003 stays `Completed`.
- **Adaptation Notes**: N/A — this file's Session Boundary Planning discharges the planning need.
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 9: Data Layer Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Data Layer Implementation (PF-TSK-051)](../../../../process-framework/tasks/04-implementation/data-layer-implementation.md)
- **Rationale**: Not applicable — this feature has no data layer (no models, repositories, or database integration). Config file I/O is handled by `config_edit.py`, which is engine code under Step 11a.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 10: State Management Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [State Management Implementation (PF-TSK-056)](../../../../process-framework/tasks/04-implementation/state-management-implementation.md)
- **Rationale**: Not applicable **as a decomposed task**, though `model.py` genuinely is this feature's state layer. The feature was deliberately built without this task (state file §9 Decision 1: engine phases including `model.py` ran under Core Logic Implementation), so CR-7 and CR-14 are executed under Step 11a to keep this enhancement consistent with how the code was built. Flagged rather than silently skipped.
- **Adaptation Notes**: N/A — `model.py` findings (CR-7, CR-14) are covered by Step 11a.
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 11: UI Implementation

- **Status**: [x] Complete — session 1: CR-2's view half (fail-closed `render`). Session 2: CR-6 (focus pairing + keyboard entry point), CR-15 (mnemonic removed), CR-16 (real error text). All verified in a scripted real-Tk run, 17/17 checks
- **Applicable**: Yes
- **Referenced Task Doc**: [UI Implementation (PF-TSK-052)](../../../../process-framework/tasks/04-implementation/ui-implementation.md)
- **Rationale**: Applicable — four findings are in the view layer, two of them breaching the Critical UX dimension: CR-6 (arrow-key list navigation inert — no row selectable without a mouse), CR-15 (`Alt+S` in the config editor starts a daemon instead of saving), CR-16 (status bar misreports registry-parse and discovery failures, contradicting its own banner), and CR-2's view half (`config_pane.render()` commits `_project_id` before `_load()` can raise).
- **Adaptation Notes**: Extend existing widgets; do not introduce new UI patterns. CR-6: pair `selection_set()` with `focus()` so Tk item focus is non-empty and `Keynav` engages. CR-15: **remove** the unspecified `underline=0` mnemonic from the config-pane Save button — PD-UIX-003 assigns `Alt+S` to Start and `Ctrl+S` to Save, so the code conforms to the spec rather than the spec moving. CR-16: distinguish registry-not-found from registry-parse-failure and discovery-failure, and make sure each reaches `panel.log`, since the status bar tells the user to read it. CR-2 view half: make `_load()` failure leave the pane in a coherent state — either commit `_project_id` only after a successful load, or reset `_mode`/`_baseline`/editor content on the failure path so Save can never be armed against a switched project. Keep rendering decisions in the display-free `views/rendering.py` so they stay headlessly testable; verify CR-6 and CR-15 against a **real window** as well.
- **Deliverable**: `views/main_window.py` and `views/config_pane.py` updated; CR-6/CR-15 verified interactively; new COMP-level cases where the rule is display-free
- **Session**: 1 (CR-2 view half), 2 (CR-6, CR-15, CR-16)

---

### Step 11a: Core Logic Implementation

> **Block added by Feature Request Evaluation.** The 17-block template has no Core Logic
> Implementation block, yet PF-TSK-078 is a live task and is the task under which this feature's
> engine modules (`discovery.py`, `lifecycle.py`, `settings.py`, `model.py`, `config_edit.py`) were
> built. Without this block the majority of the enhancement would have no home and no correct
> quality reference. Recorded as a framework finding in the Session Log.

- **Status**: [x] Complete — all 13 engine-side findings closed: CR-2, CR-3, CR-10, CR-11, CR-14 (s1); CR-4, CR-5, CR-7, CR-8, CR-9, CR-12 (s2); CR-13, CR-19 (s3)
- **Applicable**: Yes
- **Referenced Task Doc**: [Core Logic Implementation (PF-TSK-078)](../../../../process-framework/tasks/04-implementation/core-logic-implementation.md)
- **Rationale**: Applicable — thirteen of the nineteen findings are engine-side: CR-2, CR-3 (`config_edit.py`), CR-4, CR-5 (`discovery.py`), CR-7 (`model.py` + `app.py`), CR-8, CR-9, CR-12 (`lifecycle.py`), CR-10, CR-11 (`settings.py`), CR-13 (subpackage-wide), CR-14 (`model.py`), CR-19 (`app.py`).
- **Adaptation Notes**: Extend existing modules on their existing seams. Work the **defect class first**: CR-2, CR-3, CR-10 and CR-11 are all a narrow `except OSError` around a call that raises from the `ValueError` family (`UnicodeDecodeError`, `AttributeError`/`TypeError`, `OverflowError`) out of a documented "never raises" contract — fix them together and sweep the remaining `except` clauses in the subpackage in the same pass, re-stating each module's raising contract in its docstring. Then: CR-4/CR-5 identity discrimination (keep normalized *equality*, never substring; an unattributable process must still never be claimed); CR-7 sequence-numbered poll snapshots plus an in-flight Refresh/F5 guard, staying inside the dispatcher-queue pattern; CR-8 raise the DRAINING pin TTL above its own worker's worst case so a row cannot revert to Running mid-stop; CR-9 resolve `pwsh.exe` absolutely rather than PATH-relative; CR-12 open the launcher capture temp files with delete-sharing (or relocate them) so the `finally` unlink actually succeeds — and drop the inline "cleaned up by the OS" comment, which the five surviving 2026-08-10 file pairs disprove; CR-13 add the TDD §7.1 DEBUG instrumentation (poll-cycle duration, dispatcher queue depth) so `--debug` means something; CR-14 stop a transient registry read failure from clearing the selection and discarding unsaved edits; CR-19 install a Tk `report_callback_exception` override that routes to the panel log (a UI-thread exception currently vanishes entirely under `pythonw`). Preserve the eight verified positives Code Review recorded on these modules — kill-time re-verification, self-owned lock cleanup, no `shell=True`, the bounded single-instance protocol, byte-identical refusal paths.
- **Deliverable**: Nine panel modules updated; each CR-ID's outcome recorded in feature state file §10
- **Session**: 1 (CR-2, CR-3, CR-10, CR-11, CR-14 + the `except`-clause sweep), 2 (CR-4, CR-5, CR-7, CR-8, CR-9, CR-12), 3 (CR-13, CR-19)

---

### Step 12: Integration & Testing

- **Status**: [x] Complete — session 3: CR-17, CR-18, CR-20 in `deployment/install_global.py` and `pyproject.toml`, then a **real clean-scratch install end to end** (copy → generated requirements.txt with the raised GitPython floor → venv created and verified, resolving GitPython 3.1.59 → four wrappers → both --help smoke tests → exit 0). CR-17's failure path was then forced in the installed tree and printed the real stdout diagnostic. Full suite 1324 passed, 3 skipped, 4 xfailed; black/isort/flake8 clean
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../../../process-framework/tasks/04-implementation/integration-and-testing.md)
- **Rationale**: Applicable — changes span nine panel modules plus two artifacts the automated suite never exercises. CR-17 (installer smoke test renders its failure reason from `stderr` while the diagnostic goes to `stdout`, so a real failure prints an empty reason) and CR-20 (install path interpolated into a single-quoted PowerShell literal — an apostrophe in the home directory silently breaks the generated wrapper) are exactly the class of defect that ships green.
- **Adaptation Notes**: Per this block's standing rule, manually verify every artifact outside the test suite: run `deployment/install_global.py` against a **clean scratch directory** end to end (copy → generated `requirements.txt` → venv created and verified → wrappers → both `--help` smoke tests) and confirm the CR-17 failure path now prints a real reason by forcing a failure. Verify CR-18's raised `GitPython>=3.1.41` floor actually resolves in a fresh venv. Verify CR-20 with a path containing an apostrophe. Then run the full unit suite (`Run-Tests.ps1 -All`) plus black / isort / flake8 at the enforced commit gate (`--max-line-length=120 --extend-ignore=E203`), and re-run the live panel scenarios the fixes touch — start/stop against a real daemon, a real `--validate`, and a config save.
- **Deliverable**: `deployment/install_global.py` + `pyproject.toml` updated and verified against a clean install; full suite green; live panel scenarios re-verified
- **Session**: 3

---

### Step 13: Implementation Finalization

- **Status**: [x] Complete — session 3: feature state file §2, §5, §10 and §11 reconciled; per-finding outcomes recorded with verification evidence; tracker pass done (7 files → 🔄 Needs Audit, counts synced to function counts)
- **Applicable**: Yes
- **Referenced Task Doc**: [Implementation Finalization (PF-TSK-055)](../../../../process-framework/tasks/04-implementation/implementation-finalization.md)
- **Rationale**: Applicable — a three-session enhancement needs close-out: reconciling the feature state file, correcting records, and confirming nothing is left half-done before the feature re-enters the review queue.
- **Adaptation Notes**: Adapt to amendment context — no re-finalization of the whole feature. Specifically: record each CR-ID's outcome (fixed / deferred with rationale) in feature state file §10; reconcile §2 (Current Status, Current Task, Completion), §5 inventory rows for every modified file, and §11 Next Steps; keep the CR-1 row's 🔴 annotation and point it at PF-IMP-2032. Known script defect to expect (already recorded in the feature's §11 follow-ups): `Update-FeatureImplementationState.ps1` faults on `👀 Needs Review` because its status switch has no branch for it — the feature-tracking write lands *before* the fault, so run it, verify on disk, then run `Update-WorkflowTracking.ps1` separately.
- **Deliverable**: Feature state file reconciled; per-CR outcomes recorded; no open items left unaccounted
- **Session**: 3

---

### Step 14: Update Tests

- **Status**: [x] Complete — 19 cases (s1), 16 + TD263 (s2), 16 (s3) across seven suites plus the new TE-TST-153. Panel suite 249 → 314; full unit suite 1324. Every added assertion mutation-verified: 6/6, 7/7 and 7/7 mutations turned exactly their own tests red
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../../../process-framework/tasks/04-implementation/integration-and-testing.md)
- **Rationale**: Applicable — every finding changes testable behaviour, and the existing suite was green through all of them, so absence of coverage is itself part of the defect. The panel suite (249 cases across ten files) is where the regression tests belong.
- **Adaptation Notes**: Add cases to the existing ten panel test files; no new test file, so no `New-TestFile.ps1` run is needed. Honour the test spec's standing rule: **no widget instantiation** — assert display-free rules in `views/rendering.py` and use scripted real-Tk runs for the genuinely interactive checks (CR-6, CR-15). Each new assertion must be load-bearing: name the condition under which it fails, then mutation-verify it (break the fix, watch *that* assertion go red, restore). Fixture-visible traps to avoid: tests inject a fake process table, so CR-4/CR-5 need cases built from realistic `--validate` and wrapper-shell command lines, and CR-10/CR-11 need real non-UTF-8 bytes and real `.inf`/`.nan` values on disk. Run `Validate-TestTracking.ps1` (0 errors) after the last session's changes. **No manual/E2E test groups exist for this feature** (verified 2026-08-17 — no WF-010 rows in e2e-test-tracking.md), so there is nothing to set to "Needs Re-execution".
  **Audit-status rule (decided 2026-08-17, human-approved)**: every test file modified by this enhancement ends at **`🔄 Needs Audit`** in test-tracking.md, not retained at `✅ Audit Approved`. Reason: the `✅ Audit Approved` verdict was granted by Audit Round 1 (2026-08-14) against different content, and that same round had to *correct* a false coverage claim in this feature's test spec (CRLF documented as tested in three places with no test — now TD264). Leaving the verdict in place would re-create the exact records-certify-uncovered-content failure this enhancement exists to fix. The verdict is owned by Test Audit (PF-TSK-030) — neither this task nor Code Review may re-grant it. Flip the modified per-file rows at the end of the final session, and expect a Test Audit round downstream of the re-review.
  **Also due in that same final tracker pass**: the per-file **Test Cases Count** cells for every
  modified suite. `Validate-TestTracking.ps1` reports 0 errors but warns on the drift
  (after session 1: `test_panel_settings.py tracked=13, collected=17`). Its `-Fix` switch syncs
  counts **globally**, and two of the three current row mismatches belong to files this enhancement
  never touched — so do not run it mid-enhancement; sync the counts for this enhancement's files
  and surface the other two to their owner rather than sweeping unrelated drift into this change.
- **Deliverable**: New regression cases in seven panel test files; suite green; `Validate-TestTracking.ps1` 0 errors
- **Session**: 1, 2, 3 (alongside each session's fixes)

---

### Step 15: Code Review

- **Status**: [x] Complete (routing) — finalization restores the feature to 👀 Needs Review for the standalone re-review of record; focus areas handed over in the feature state file §11 item 7
- **Applicable**: Yes
- **Referenced Task Doc**: [Code Review (PF-TSK-005)](../../../../process-framework/tasks/06-maintenance/code-review-task.md) — runs as its own session *after* this enhancement is finalized
- **Rationale**: Applicable and non-negotiable — six inherited dimensions are Critical, the changes touch core logic, and this is the **re-review of a feature the previous review bounced**. The enhancement session never performs the review of record.
- **Adaptation Notes**: Routing decision only. Finalize with `Finalize-Enhancement.ps1 -FeatureId "7.1.1" -RestoredStatus "👀 Needs Review"`. Focus areas to hand the reviewer: (1) CR-2's fix at both halves — reader contract *and* pane-state ordering — since the destructive path needed both; (2) the `except`-clause sweep, verified as a class rather than four instances; (3) the CR-4/CR-5 identity change against the D-T5 invariant, including that unattributable processes are still never claimed; (4) that the eight recorded positives on these modules did not regress; (5) **AC-11 / FR-8 / UI-7 / BR-8 remain UNMET pending PF-IMP-2032** — the reviewer should confirm the records say so rather than treat it as a new finding.
- **Deliverable**: Feature routed to a standalone Code Review session (`👀 Needs Review`) at finalization
- **Session**: 3 (routing at finalization)

---

### Step 16: User Documentation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [User Documentation Creation (PF-TSK-081)](../../../../process-framework/tasks/07-deployment/user-documentation-creation.md)
- **Rationale**: Not applicable — **no handbook exists yet to amend.** The feature's §4 carries three `❌ Needed` rows (how-to, reference, explanation) already routed to User Documentation Creation after Performance & E2E Test Scoping, and this enhancement changes no *documented* behaviour: CR-6 and CR-15 bring code into conformance with the UI Design's existing keyboard contract rather than changing it. Writing handbook content now would document behaviour that the re-review may still move.
- **Adaptation Notes**: N/A — per this block's deferral path, the three `❌ Needed` rows in the feature's §4 stay as they are so PF-TSK-081 picks up final behaviour, including the corrected accelerator set.
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 17: Update Feature State

- **Status**: [x] Complete — all 19 outcomes recorded in the feature state file's Gap Closure Outcomes table, with CR-1 carried as ⛔ Out of scope pointing at PF-IMP-2032
- **Applicable**: Yes — always required
- **Referenced Task Doc**: N/A — direct state file update
- **Rationale**: Feature state must always be updated to reflect the enhancement.
- **Adaptation Notes**: Update [feature state file PD-FIS-056](../../features/7.1.1-LinkWatcher-Control-Panel-implementation-state.md) as work progresses, not only at close-out: mark each CR-ID's disposition in the §10 Open Implementation Gaps table (keep the table — it is the review's record of what was found, and the outcome column is what makes it auditable), extend §5 inventory Notes for each modified file, and refresh §2 and §11. `workflows:` metadata is unchanged (WF-010 only) and User Workflow Tracking needs no scope change — WF-010 stays `Pending: 7.1.1` until the feature reaches 🟢 Completed, which PF-IMP-2032 gates.
- **Deliverable**: Updated feature implementation state file with per-finding outcomes
- **Session**: 1, 2, 3 (progressively; reconciled at Step 13)

---

## Session Boundary Planning

> Sessions are cut by **defect class**, not severity order — CR-2, CR-3, CR-10 and CR-11 share one
> root cause and are cheapest to fix in a single sweep, so the Critical arrives with its three
> Minor siblings rather than alone.

### Session 1: Contract escapes and data integrity

**Planned Steps**: 11a (CR-2, CR-3, CR-10, CR-11, CR-14 + subpackage `except`-clause sweep), 11 (CR-2 view half), 7 (EC-10/EC-11 scenarios), 14, 17
**Goal**: No panel path can destroy or lose a configuration file, and no module advertising "never raises" can raise. CR-2 closed at both halves — reader contract *and* pane-state ordering. Suite green with mutation-verified regression cases.

### Session 2: Identity, lifecycle and keyboard operability

**Planned Steps**: 11a (CR-4, CR-5, CR-7, CR-8, CR-9, CR-12), 11 (CR-6, CR-15, CR-16), 6 (§4.4 amendment), 7 (identity + UX scenarios), 14, 17
**Goal**: Only a real daemon for a project can be claimed or terminated; the daemon list is fully keyboard-operable; poll ordering, pin TTL, launcher resolution and temp-file cleanup are correct. TDD §4.4 moved with the code.
**Scope addition (decided 2026-08-17, human-approved)**: close **TD263** in the same pass — the exit-confirmation path in `test_panel_lifecycle.py` (`wait_for_exit` timeout branch, `daemon_exit_unconfirmed` warning) is uncovered *because* `FakeTerminator` removes PIDs synchronously. CR-8 is the DRAINING pin TTL versus its worker's real worst case — the same drain/exit path in the same file — so testing CR-8's fix credibly needs exactly the fixture capability TD263 describes. Close it via `Update-TechDebt.ps1` when the coverage lands, and record it here. **TD264** (CRLF normalization in `log_tail.py`) stays **out of scope** — that module carries no CR finding.

### Session 3: Observability, packaging, integration and close-out

**Planned Steps**: 11a (CR-13, CR-19), 12 (CR-17, CR-18, CR-20 + clean-install verification), 6 (§4.5/§9 status note), 7 (table reconciliation), 13, 14, 15 (routing), 17
**Goal**: Every failure leaves a log record and `--debug` delivers the §7.1 instrumentation; a clean scratch install succeeds and reports real failure reasons; records corrected; feature restored to `👀 Needs Review` for re-review. **AC-11 explicitly left UNMET pending PF-IMP-2032.**

## Session Log

### Session 0 (scoping): 2026-08-17 — Feature Request Evaluation (PF-TSK-067)

**Completed**:
- Classified the request as an **Enhancement** to 7.1.1; target feature and full 19-finding scope approved by the human partner at the combined Step 7 / Step 17 checkpoint.
- Scope, dimension impact (CQ and OB elevated to Critical), and all 18 execution blocks evaluated; this file customized.

**Findings raised this session**:
- **PF-IMP-2032 filed** (central Intake, APP-001) — CR-1 hook auto-open re-implementation on the framework path. It had been recorded *only* inside the feature state file: Code Review named Process Improvement as its destination but filed nothing, and a portfolio-wide search (`hook_wrapper`, `control panel`, `auto-open`, `start_linkwatcher`) found no row. Verified before filing: no `pythonw` / `control_panel` / `Open-ControlPanel` reference in the wrapper in the working tree, and `git log -S'control_panel'` on that file returns no commits — it was never in history.
- **Template link-depth defect** — all 17 relative links in the file this script generates are broken (`../../tasks/…` is correct from `process-framework/templates/04-implementation/` but resolves to `doc/tasks/…` from `doc/state-tracking/temporary/`). Systemic and long-standing: the four archived enhancement files carry 15–19 broken links each, the template holds 16, and `New-EnhancementState.ps1` has no rebasing logic. Corrected in this file; filed as a framework improvement.
- **Template has no Core Logic Implementation block** though PF-TSK-078 is a live task and is where this feature's engine modules were built — thirteen of nineteen findings would have had no home. Added as Step 11a; filed as a framework improvement.
- **Referenced Task Doc IDs verified** — all 16 template-referenced task files exist with the IDs the template claims (PF-TSK-005/011/012/015/019/020/021/027/044/051/052/053/055/056/081). No stale task references.
- **Corrections to the feature's own records**: §11 item 3 (feature untracked in git) is **resolved** — 19 panel modules, `control_panel.py` and the state file are all tracked as of sweep commit `006f5a7`. §11 item 5 names Feature Enhancement as "PF-TSK-069"; the correct ID is **PF-TSK-068** (069 is E2E Acceptance Test Case Creation), and it omitted that an Enhancement State Tracking File must be created first — this file.

**Next Session**:
- Session 1 per the plan above, entered through **Feature Enhancement (PF-TSK-068)**, which reads this file. Start with the contract-escape class (CR-2 first).

### Session 2: 2026-08-18 — identity, lifecycle and keyboard operability

**Completed** (9 findings — CR-4, CR-5, CR-6, CR-7, CR-8, CR-9, CR-12, CR-15, CR-16 — plus TD263):

- **Identity (CR-4, CR-5).** `is_daemon_for` is now four-way: entry script + project root + an
  explicit `--project-root` + *not* an exit-mode flag. Root extraction no longer regex-searches a
  re-joined argv. TDD §4.4 step 2 and D-T5 amended to match (v1.5 → v1.6).
- **Lifecycle (CR-8, CR-9, CR-12).** DRAINING pin TTL derived from the exit wait so it outlives its
  own worker; `resolve_shell()` walks PATH skipping relative entries; each run sweeps aged launcher
  captures.
- **Ordering (CR-7).** Poll results carry a start-order sequence and the model drops stragglers;
  manual Refresh gained an in-flight guard.
- **Views (CR-6, CR-15, CR-16).** Focus paired with selection plus a keyboard entry point; the
  unspecified Save mnemonic removed; the status bar reports the real error and registry failures now
  reach `panel.log` (logged on change, so a persistent fault is one line rather than one per poll).
- **TD263 closed** — the exit-confirmation timeout path, unreachable while the fake terminator
  removed PIDs synchronously. Resolved via `Update-TechDebt.ps1`.
- Tests: 16 new cases + TD263's; panel suite **249 → 298**, full unit suite **1302 passed, 3
  skipped, 4 xfailed**; black / isort / flake8 clean. Test spec → v1.6 (81 scenarios).

**Evidence gathered against reality, not only fixtures**:

- **CR-4 proven live.** A real `main.py --validate` scan of this project was started and snapshotted:
  the pre-fix logic claimed it as the daemon *alongside* the genuine pair (three PIDs for one
  project, the scan eligible for termination); the fixed logic claims only the pair. The daemon pair
  itself (venv shim + child) still classifies correctly.
- **CR-5 is latent, not live.** Measured honestly: on the current process table the pre-fix logic
  claimed nothing extra — the wrapper shells present mention `main.py` but not `--project-root`. The
  false positive is real in mechanism (proven synthetically) but was not firing at that moment.
- **CR-9's obvious fix does not work.** `shutil.which` returns the current-directory decoy *even
  when given an explicit* `path=`, because it unconditionally prepends `os.curdir` on Windows. Hence
  the manual PATH walk rather than a one-line `which` call.
- **CR-12 measured.** 8 leaked capture files up to 7.9 days old were present in `%TEMP%`, directly
  contradicting the "cleaned up by the OS" comment that justified ignoring the leak.

**Issues / findings**:

- Two of my own errors, both caught by verification rather than review: a test harness that wired
  `on_select` to a recorder instead of to `model.select` (so "the model followed the keyboard"
  failed for a harness reason, not a code one), and a status-update script that wrote three blocks'
  statuses into the *following* blocks because it searched for a placeholder string within a
  character window instead of within the block. The second was found by dumping every block's status
  and reading them, and repaired with a block-scoped rewriter.
- `flake8` caught a genuine defect in my own documentation: `W605 invalid escape sequence` from
  writing `.\pwsh.exe` in a non-raw docstring.

**Next Session** (session 3 — observability, packaging, integration and close-out):

- CR-13 (TDD §7.1 DEBUG instrumentation: poll-cycle duration, dispatcher queue depth) and CR-19
  (Tk `report_callback_exception` → panel log).
- CR-17, CR-18, CR-20 in `deployment/install_global.py` and `pyproject.toml`, then **Step 12** —
  a real clean-scratch-install run, since none of those three is exercised by the test suite.
- TDD §4.5/§9 hook auto-open status note; test-spec table reconciliation.
- **Step 13 finalization**: reconcile the feature state file, then the tracker pass — flip every
  modified test file to `🔄 Needs Audit` and sync only *this enhancement's* per-file test counts
  (`-Fix` is global; two unrelated files' mismatches belong to their owner).
- **Step 15 routing**: `Finalize-Enhancement.ps1 -FeatureId "7.1.1" -RestoredStatus "👀 Needs Review"`.
  AC-11 / FR-8 / UI-7 / BR-8 stay UNMET pending PF-IMP-2032 — do not restore 🟢 Completed.

### Session 3: 2026-08-18 — observability, packaging, integration and close-out

**Completed** (5 findings — CR-13, CR-17, CR-18, CR-19, CR-20 — and the close-out):

- **Observability (CR-13, CR-19).** Dispatcher queue depth logged at DEBUG when non-empty; poll-cycle
  duration logged per pass and escalated to WARNING past the §7.1 500 ms budget; Tk's
  `report_callback_exception` routed to the panel log with its traceback. Both rules were extracted to
  module-level Tk-free functions first, following the Decision 11a precedent, so they are assertable
  without a display — the subpackage previously held exactly one `.debug()` call while `--debug`
  advertised verbose logging.
- **Packaging (CR-17, CR-18, CR-20).** Smoke-test reasons render from whichever stream carries them;
  GitPython floor raised above the CVE-bearing releases; the install path escaped before interpolation
  into a single-quoted PowerShell literal.
- **Step 12 real-install verification.** A full clean-scratch install ran end to end (exit 0), the
  fresh venv resolved GitPython 3.1.59, and CR-17's failure path was forced in the *installed* tree and
  printed the real diagnostic where it previously printed nothing.
- **Close-out.** TDD → v1.7 (§4.5 now records hook auto-open as NOT IMPLEMENTED, pointing at
  PF-IMP-2032); Test Spec → v1.7 (83 scenarios); feature state file §2/§10/§11 reconciled; tracker pass
  completed.

**Findings raised this session**:

- **PF-IMP-2037 filed** — no framework script can set a test-tracking row to the awaiting-audit status
  the tracker itself defines. `Update-TestFileAuditState.ps1` offers only the audit task's own verdicts,
  and nothing else writes that value, so the approved-verdict-no-longer-matches-content case forces a
  hand-edit of a tracked state file. The same filing records that the Test Cases Count column counts
  test *functions* — a count taken from pytest's collection output is wrong for every parametrized file,
  which is exactly the mistake made and corrected here.
- **A test I added was green in isolation and red in the suite.** `caplog.at_level(logging.DEBUG)` raises
  the level on the *root* logger, but other tests call `setup_panel_log()`, which sets the panel logger to
  INFO — so the DEBUG record was dropped before caplog could see it. Fixed by scoping the level to the
  panel logger. Worth remembering: a logging assertion that passes alone proves nothing about the suite.

**Enhancement complete.** All 19 product-path findings closed. **CR-1 remains open by design** and is
tracked as PF-IMP-2032 on the framework path; FR-8, UI-7, BR-8 and the first clause of AC-11 stay UNMET,
so the feature is restored to `👀 Needs Review` and must **not** be moved to `🟢 Completed` until that
IMP lands.

### Session 1: 2026-08-17 — contract escapes and data integrity

**Completed** (5 of 19 findings; the whole session-1 defect class):

- **CR-2 (Critical), both halves.** `read_config` reports a non-UTF-8 file as `error` instead of
  letting `UnicodeDecodeError` escape its "never raises" contract, and deliberately does not decode
  leniently (lossy text would be written back on the next save). `config_pane.render` additionally
  fails closed if `_load()` raises for *any* reason — state fields land before widget calls, so
  `_mode` can never remain `"ok"` with the previous project's baseline while Save resolves the
  switched project's path. The reader fix removes the known trigger; the ordering fix removes the
  class.
- **CR-3 (Major).** `save_config` converts a raise from the real loader/validator into a blocked
  save with an operator-facing explanation plus a `panel.log` entry; `OSError` is re-raised so the
  outer handler still owns genuine I/O failure.
- **CR-10, CR-11 (Minor).** `_coerce_positive_number` is total (guarded `float()` conversion,
  finiteness check); `load_panel_settings` handles a non-UTF-8 file.
- **CR-14 (Minor).** `apply_poll` no longer treats a no-rows-plus-error poll as "zero projects".
- **Step 7**: UNIT-C7 / UNIT-C8 / UNIT-S7 / UNIT-M8 added to TE-TSP-045 and the EC-10/EC-11
  Edge-Case Coverage rows corrected with an explicit note that they previously over-claimed.
- **Step 14**: 19 regression cases across three suites. Panel suite **249 → 269**; full unit suite
  **1273 passed, 3 skipped, 4 xfailed**; black / isort / flake8 clean at the enforced gate.
- **Step 17**: per-CR outcomes recorded in the feature state file's new Gap Closure Outcomes table.

**Issues / findings**:

- **Root cause of CR-3 is not in the panel** — `LinkWatcherConfig.validate()` and `_from_dict`
  neither coerce nor type-check, so a wrongly typed value raises instead of being reported in the
  issue list `validate()` exists to return (measured across four value types). The **daemon** is
  exposed too: `main.py:453` calls the same `validate()` at startup, so an operator gets a generic
  `fatal_error` with a raw Python message instead of a precise `config_issue`. Filed against
  feature 0.1.3 as **PD-BUG-123**. The panel fix is still required independently — a pane must
  handle whatever an external module throws (its CQ-Critical obligation).
- **One of my own new assertions was vacuous on first attempt.** The CR-14 `last_refresh` test
  passed even with the fix removed: two real `datetime.now()` calls that close together land inside
  one Windows clock-granularity tick and compare equal. Rewritten with an injected `refreshed_at`,
  then re-verified red. Caught only because every assertion was mutation-verified — a
  pass-on-green-only check would have shipped it as false comfort.
- **A test I wrote failed for the right reason and taught the model's rule**: a DRAINING pin is
  resolved by an observed STOPPED status, and `_snapshot`'s default *is* STOPPED, so the pin
  resolved immediately. Fixture corrected to pin against a RUNNING row, with the reason recorded in
  the test so the next author does not repeat it.
- **No test previously asserted the old "clear everything on a failed poll" behaviour** — the whole
  119-test model/integration/views set stayed green through the CR-14 change, confirming that path
  was untested rather than intentionally specified.
- Deviation from this file's own Step 17 note: outcomes are recorded in a **companion table** in
  §10 rather than as an added column on the 20-row gaps table, so each outcome can carry its
  verification evidence and Code Review's table stays as written.

**Next Session** (session 2 — identity, lifecycle, keyboard operability):

- CR-4, CR-5 (`discovery.py` identity: discriminate executable / run mode so a `main.py --validate`
  scan is never claimed; narrow or remove the wrapper-shell regex fallback) → then amend TDD §4.4
  and D-T5 to match.
- CR-6, CR-15, CR-16 (`views/`): pair `selection_set()` with `focus()`; remove the unspecified
  `Alt+S` mnemonic from the config Save button (PD-UIX-003 assigns `Alt+S` to Start, `Ctrl+S` to
  Save); split registry-not-found from parse/discovery failure and route each to `panel.log`.
- CR-7, CR-8, CR-9, CR-12 (`model.py`/`app.py`/`lifecycle.py`): poll sequence numbers + in-flight
  Refresh guard; raise the DRAINING pin TTL above its worker's worst case; resolve `pwsh.exe`
  absolutely; open the launcher capture temp files with delete-sharing and drop the inline
  "cleaned up by the OS" comment.
- **Fold in TD263** (approved 2026-08-17): the `FakeTerminator` synchronous-removal limitation that
  leaves the exit-confirmation path uncovered is the fixture capability CR-8 needs anyway.
- Verify CR-6 and CR-15 against a real window, not only headless rules.

## Finalization Checklist

> **Instructions**: Complete when all applicable execution steps are done. This checklist is part of the Feature Enhancement task (PF-TSK-068) completion process.

- [ ] All applicable execution steps marked complete
- [ ] All non-applicable steps confirmed as "Not applicable" with rationale
- [ ] Target feature's implementation state file updated to reflect enhancement
- [ ] Feature tracking status restored (removed "🔄 Needs Enhancement", set appropriate status, removed state file link)
- [ ] This file archived to `state-tracking/temporary/old/`
- [ ] **Enhancement-specific**: every CR-ID from §10 carries a recorded outcome (fixed / deferred with rationale) — none silently dropped
- [ ] **Enhancement-specific**: AC-11 / FR-8 / UI-7 / BR-8 still recorded as UNMET, with PF-IMP-2032 named as the gating item — the feature must not be restored to `🟢 Completed`
