---
id: PF-STA-106
type: Process Framework
category: State Tracking
version: 1.0
created: 2026-06-04
updated: 2026-06-04
enhancement_name: per-folder-path-resolution-override
target_feature: 6.1.1
inherited_dimensions: PE,EM,SE,OB
---

# Enhancement State Tracking: Per-Folder Path Resolution Override

> **TEMPORARY FILE**: This file tracks enhancement work on an existing feature. Created by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068). Move to `state-tracking/temporary/old/` when all steps are complete.

## Enhancement Overview

| Metadata | Value |
|----------|-------|
| **Target Feature** | 6.1.1 — Link Validation |
| **Secondary Features Affected** | None — the config key is added to `config/settings.py` as a mechanism (mirroring prior validation keys like `validation_ignored_patterns`); this is not a Configuration System (0.1.3) enhancement. Link Updating (2.2.1) was considered but deliberately **excluded** (see Change Request). |
| **Dependent (non-product) work** | End-to-end use requires two items tracked **outside** this product enhancement: (1) a **framework IMP** to make the daemon load a per-project config file via `--config` (modify `start_linkwatcher_background.ps1` to auto-create a committed, non-distributed config from an inlined skeleton and pass it) — without this, the field is only reachable via a manual `--config`; (2) **consumer config creation** in each project (e.g. appdev's `blueprint/` override), propagated to existing projects via appdev's per-project-migrations. This product enhancement (field + validator + tests) is independently shippable and `--config`-usable. |
| **Enhancement Description** | Add a path_resolution_overrides config key so --validate resolves absolute-from-host links inside a designated folder (e.g. a blueprint/template folder) against <project_root>/<folder>/ instead of <project_root>/. Validation-only, backward-compatible (no behavior change when the key is absent). |
| **Change Request** | PD-FRQ-005 (source: PRJ-000 appdev — link-validation feedback). Template/blueprint folders (e.g. `appdev/blueprint/`) ship to other projects where they become the root, so their absolute-from-host links (`/process-framework/foo.md`) are authored from the rollout target's perspective and are reported broken when `--validate` runs from the dev-workspace root. Add a per-folder resolution-base override so such links validate against the folder's effective base. Current workaround (`Convert-BlueprintLinks.py`) is a one-way rewrite that destroys the original link shape. **Scope reduced 2026-06-04** by human partner from validation+updates to **validation-only** (the Link Updating / 2.2.1 portion is dropped — see Dimension Impact). |
| **Human Approval** | 2026-06-04 — Classification (Enhancement) + target feature (6.1.1) confirmed; scope reduced to validation-only by human partner. |
| **Affected Workflows** | WF-009 (Link health audit) — validation behavior only; no change to which workflows the feature participates in. |
| **Estimated Sessions** | 1 |
| **Created By** | Feature Request Evaluation (PF-TSK-067) |

## Scope Assessment

| Criterion | Assessment |
|-----------|------------|
| **Files Affected** | ~4 code/test + docs. **Code:** `src/linkwatcher/config/settings.py` (new `path_resolution_overrides` field), `src/linkwatcher/validator.py` (`_target_exists` + `_target_exists_at_root` honor the per-folder base). **Tests:** `test/automated/unit/6-link-validation-reporting/6-0-link-validation-reporting/test_validator.py` (new cases). **Examples/docs:** a `config-examples/*.yaml` entry; user handbooks (`configuration-guide.md`, `quick-reference.md`, `link-validation.md`) + `linkwatcher-capabilities-reference.md` config table. |
| **Design Docs to Amend** | None — 6.1.1 is Tier 1 (no FDD/TDD/ADR). Implementation Plan (PD-IMP-002) is reference-only. |
| **New Tests Required** | Yes — new unit cases (override applied for a file under the folder; non-override folder still flagged; no-config backward-compat; data-value/at-prefix fallback honors the override). No existing tests need to change behavior. |
| **Interface Impact** | Public config interface (new `path_resolution_overrides` key) but **backward-compatible** — no behavior change when the key is absent. Validator-internal resolution changes only; no CLI flag added. |
| **Session Estimate** | Single session — contained change (one config field + two validator methods + unit tests), no design docs to amend. |

## Existing Documentation Inventory

| Document Type | ID | Location | Action Needed |
|---------------|-----|----------|---------------|
| Feature State File | PD-FIS-055 | [6.1.1-Link Validation-implementation-state.md](../features/6.1.1-Link%20Validation-implementation-state.md) | Update on completion (Step 18) |
| FDD | N/A | None exists (Tier 1) | No change |
| TDD | N/A | None exists (Tier 1) | No change |
| ADR | N/A | None exists | No change |
| Test Specification | N/A | None exists (Tier 1 — unit tests cover directly) | No change |
| Implementation Plan | PD-IMP-002 | [6-1-1-link-validation-implementation-plan.md](../../technical/implementation-plans/6-1-1-link-validation-implementation-plan.md) | Reference only |
| User Handbook | PD-UGD-003 | [link-validation.md](../../user/handbooks/link-validation.md) | Amend (Step 17) — document new config key |

## Dimension Impact Assessment

> **Reference**: [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md)
>
> Inherited from parent feature (6.1.1): PE (Critical), EM (Relevant), SE (Relevant), OB (Relevant)
> **Additional for this enhancement**: none — no new dimensions introduced.
> **Reduced for this enhancement**: none. **Note:** DI (Data Integrity) stays **Not Applicable** because validation is read-only. The dropped Link Updating (2.2.1) scope is precisely what would have elevated DI to Critical (writes files during moves) — keeping the enhancement validation-only is what holds DI out of scope and keeps this low-risk.

### Key Dimension Considerations

- **Security & Data Protection (SE)**: The override base is config-supplied. Keep effective resolution within `<project_root>/<folder>/` semantics; do not let an override enable path-traversal outside intended bounds. Validation is read-only, so the failure mode is misresolution (false negative/positive), not file corruption.
- **Extensibility & Maintainability (EM)**: New config knob — model it on the existing `parser_type_extensions: Dict[str, str]` field in `settings.py`. Default empty (`{}`) so absent config is a no-op. Document semantics inline.
- **Performance & Scalability (PE)**: `--validate` scans the whole workspace, so the per-link base lookup must stay cheap (precompute the folder→base map; longest-prefix match on the source file's relative path). Expected overhead negligible.
- **Observability (OB)**: Emit a debug log when an override base is applied to a resolution, to aid debugging false positives/negatives in blueprint folders.

## Execution Steps

> **Structure**: These steps follow the standard feature development workflow from the [Task Transition Registry](../../infrastructure/task-transition-registry.md). Each block corresponds to a task type in the workflow. The Feature Request Evaluation task (PF-TSK-067) marks each block as **Applicable** or **Not applicable** based on the enhancement scope. The Feature Enhancement task (PF-TSK-068) executes applicable blocks in order.

---

### Step 1: Tier Reassessment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Documentation Tier Adjustment (PF-TSK-011)](../../tasks/cyclical/documentation-tier-adjustment-task.md)
- **Rationale**: Minor, contained config + resolution change to a Tier 1 feature; does not increase complexity. Current tier remains appropriate.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 2: FDD Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [FDD Creation (PF-TSK-010)](../../tasks/02-design/fdd-creation-task.md)
- **Rationale**: 6.1.1 is Tier 1 — no FDD exists and the enhancement doesn't warrant creating one.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [System Architecture Review (PF-TSK-019)](../../tasks/01-planning/system-architecture-review.md)
- **Rationale**: Works within the existing validator path-resolution architecture; adds a config-driven base override, not a new cross-cutting pattern. (Validation-only scope means no shared-resolver centralization is needed — that would only matter if the Link Updating path were also in scope.)
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [API Design (PF-TSK-020)](../../tasks/02-design/api-design-task.md)
- **Rationale**: No external/service API. The only "interface" is the new config key, handled in the config (Data Layer) step.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Database Schema Design (PF-TSK-021)](../../tasks/02-design/database-schema-design-task.md)
- **Rationale**: No database in LinkWatcher.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 6: TDD Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [TDD Creation (PF-TSK-022)](../../tasks/02-design/tdd-creation-task.md)
- **Rationale**: 6.1.1 is Tier 1 — no TDD exists; the change is simple enough not to warrant one.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 7: Test Specification

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Test Specification Creation (PF-TSK-012)](../../tasks/03-testing/test-specification-creation-task.md)
- **Rationale**: Tier 1 feature — no formal test specification exists. New behavior is covered directly by unit tests added in Step 15.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 8: Feature Implementation Planning

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning-task.md)
- **Rationale**: Straightforward single-session change; the file/order of changes is already clear from this state file (config field → validator resolution → tests).
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 9: Data Layer Implementation

- **Status**: [x] Complete (2026-06-05)
- **Applicable**: Yes
- **Referenced Task Doc**: [Data Layer Implementation (PF-TSK-051)](../../tasks/04-implementation/data-layer-implementation.md)
- **Rationale**: The enhancement adds a configuration field (`path_resolution_overrides`) to the config model — the "data layer" for this CLI tool.
- **Adaptation Notes**: Add `path_resolution_overrides: Dict[str, str] = field(default_factory=dict)` to `LinkWatcherConfig` in [config/settings.py](../../../src/linkwatcher/config/settings.py), modelled on the existing `parser_type_extensions` `Dict[str, str]` field. Semantics: maps a folder (relative to `project_root`) → an effective resolution base for absolute-from-host (`/...`) targets in files under that folder. Default `{}` = no-op (backward-compatible). YAML/JSON loading works via the existing `_from_dict` (the dict is set directly); **note** `from_env` does not special-case `Dict`, so env-var support is limited — same known limitation as `parser_type_extensions` (document, don't fix here). Add an inline doc comment and a `config-examples/*.yaml` entry with a blueprint-folder example.
- **Deliverable**: Updated `settings.py` with the new field + a `config-examples/` entry.
- **Session**: 1

---

### Step 10: State Management Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [State Management Implementation (PF-TSK-052)](../../tasks/04-implementation/state-management-implementation.md)
- **Rationale**: No state-management layer in LinkWatcher — config is loaded directly.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 11: UI Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [UI Implementation (PF-TSK-050)](../../tasks/04-implementation/ui-implementation.md)
- **Rationale**: CLI tool — no UI.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 12: Integration & Testing

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: Single subsystem (validator + its config). The validator unit tests construct a `LinkWatcherConfig` and run `validate()`, so they exercise the config→validator path end-to-end at unit level; no separate integration step is warranted. The `config-examples/` YAML is outside the test suite but is trivial illustrative content — sanity-check it during Code Review.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 13: Quality Validation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Quality Validation (PF-TSK-054)](../../tasks/04-implementation/quality-validation.md)
- **Rationale**: Contained change; the SE/PE considerations are covered by Code Review (Step 16). A separate quality-validation pass would be disproportionate.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 14: Implementation Finalization

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Implementation Finalization (PF-TSK-055)](../../tasks/04-implementation/implementation-finalization.md)
- **Rationale**: Single-session enhancement; any cleanup is handled inline.
- **Adaptation Notes**: N/A
- **Deliverable**: N/A
- **Session**: N/A

---

### Step 15: Update Tests

- **Status**: [x] Complete (2026-06-05)
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: The new resolution behavior needs unit coverage.
- **Adaptation Notes**: Add cases to [test_validator.py](../../../test/automated/unit/6-link-validation-reporting/6-0-link-validation-reporting/test_validator.py): (a) an absolute-from-host link in a file **under** a configured override folder resolves against `<root>/<folder>/` and is **not** flagged broken; (b) the same link in a **non-override** folder is still flagged (backward-compat / no over-reach); (c) with no `path_resolution_overrides` set, behavior is unchanged; (d) the data-value/at-prefix fallback (`_target_exists_at_root`) honors the override; (e) if nested/overlapping override folders are supported, longest-prefix selection wins. Run the full regression suite green afterward.
- **Deliverable**: Updated `test_validator.py`; full regression passing.
- **Session**: 1

---

### Step 16: Code Review

- **Status**: [x] Complete (2026-06-05) — flake8 clean; validator.py 100% coverage maintained; full regression 847 passed/3 skipped/4 xfailed; backward-compat, SE (no new traversal surface), PE (per-file lookup + no-config fast path), longest-prefix correctness, and OB (single per-file debug log) all verified. No bugs/tech-debt/implementation-gaps found.
- **Applicable**: Yes
- **Referenced Task Doc**: [Code Review (PF-TSK-005)](../../tasks/06-maintenance/code-review-task.md)
- **Rationale**: Modifies core validator path-resolution logic — non-trivial.
- **Adaptation Notes**: Focus on: path-resolution correctness (SE — the override must not enable resolution outside the intended base / path traversal), backward-compat when the key is absent, folder-prefix match selection (longest-prefix), and that the per-link lookup stays cheap (PE). Also sanity-check the `config-examples/` YAML entry.
- **Deliverable**: Code review completed; issues resolved.
- **Session**: 1

---

### Step 17: User Documentation

- **Status**: [x] Complete (2026-06-05) — documented `path_resolution_overrides` in configuration-guide.md (new subsection + example-config entry), linkwatcher-capabilities-reference.md (Key Configuration Options row), quick-reference.md (cross-ref note), and link-validation.md (new subsection; intro count 2→3). All edits to existing handbooks (no new PD-UGD doc).
- **Applicable**: Yes
- **Referenced Task Doc**: [User Documentation Creation (PF-TSK-081)](../../tasks/07-deployment/user-documentation-creation.md)
- **Rationale**: Adds a user-visible config key (`path_resolution_overrides`).
- **Adaptation Notes**: Document the new key (with a blueprint/template-folder example) in: [configuration-guide.md](../../user/handbooks/configuration-guide.md), [quick-reference.md](../../user/handbooks/quick-reference.md) config tables, the Key Configuration Options table in [linkwatcher-capabilities-reference.md](../../user/handbooks/linkwatcher-capabilities-reference.md), and the [link-validation.md](../../user/handbooks/link-validation.md) handbook (PD-UGD-003). Keep it lightweight — a row + short example, not a new handbook.
- **Deliverable**: Updated handbook entries.
- **Session**: 1

---

### Step 18: Update Feature State

- **Status**: [x] Complete (2026-06-05) — 6.1.1 state file (PD-FIS-055): added enhancement to "What's Working", recorded `validator.py` (new helpers) + `config/settings.py` + `config-examples/linkwatcher-config.yaml` in Code Inventory, bumped test count to 124, updated dates.
- **Applicable**: Yes
- **Referenced Task Doc**: N/A — direct state file update
- **Rationale**: Feature state must always be updated to reflect the enhancement.
- **Adaptation Notes**: Update the 6.1.1 state file (PD-FIS-055): add `path_resolution_overrides` to capabilities / "What's Working", record the modified files (`config/settings.py`, `validator.py`) in the Code Inventory, and add the enhancement to the change history.
- **Deliverable**: Updated 6.1.1 implementation state file.
- **Session**: 1

---

> **Single-session enhancement** — Session Boundary Planning section omitted. All applicable steps (9, 15, 16, 17, 18) execute in one session.

## Session Log

### Session 1 (2026-06-05): Executed via Feature Enhancement (PF-TSK-068)

**Completed**:
- Step 9 — Added `path_resolution_overrides: Dict[str, str]` (default `{}`) to `config/settings.py` (modelled on `parser_type_extensions`); added `config-examples/linkwatcher-config.yaml` (created as `validation-overrides-config.yaml`, renamed via PF-TSK-014 same day). Validator: `_build_resolution_overrides` (normalise + longest-first sort) and `_resolution_base_for` (per-file base lookup) added; `_target_exists` and `_target_exists_at_root` honor an optional `resolution_base`; `_check_file` computes the base once per file and threads it. Verified end-to-end against a temp workspace (override applied / outside-folder still root / no-config no-op).
- Step 15 — Added 13 unit tests to `test_validator.py` (TestBuildResolutionOverrides, TestResolutionBaseFor, TestPathResolutionOverrides covering cases a–e). Validator suite 124 passed; full regression 847 passed / 3 skipped / 4 xfailed. Updated test-tracking.md count 111→124. `Validate-TestTracking.ps1` — 0 errors.
- Step 16 — Code review: flake8 clean, validator.py 100% coverage, backward-compat/SE/PE/longest-prefix/OB all verified. No findings to route.
- Step 17 — Documented the key in configuration-guide.md, linkwatcher-capabilities-reference.md, quick-reference.md, link-validation.md (existing-handbook edits).
- Step 18 — Updated 6.1.1 state file (PD-FIS-055).
- Finalization doc-accuracy (PF-TSK-068 Phase 4 Step 9) — caught drift beyond the scoped handbooks: updated `link-health-audit-integration-narrative.md` ("four"→"five" validation fields, 6.1.1 resolution role, diagram) and `configuration-change-integration-narrative.md` (added `path_resolution_overrides` row to the exhaustive config-field→consumer table). No FDD/TDD/test-spec exist (Tier 1).

**Issues**:
- None. (Pre-existing, unrelated: `Validate-TestTracking.ps1` reports 7 other rows with count drift and a marker-vs-collection discrepancy on the parametrized class — both pre-existing, left untouched.)

**Next Session**:
- N/A (single session)

## Finalization Checklist

> **Instructions**: Complete when all applicable execution steps are done. This checklist is part of the Feature Enhancement task (PF-TSK-068) completion process.

- [x] All applicable execution steps marked complete (9, 15, 16, 17, 18)
- [x] All non-applicable steps confirmed as "Not applicable" with rationale (1–8, 10–14)
- [x] Target feature's implementation state file updated to reflect enhancement (PD-FIS-055)
- [x] Feature tracking status restored (removed "🔄 Needs Enhancement", set "🔎 Needs Test Scoping", removed state file link from Notes)
- [x] This file archived to `state-tracking/temporary/old/`
