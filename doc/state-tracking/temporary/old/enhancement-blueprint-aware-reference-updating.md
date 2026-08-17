---
id: PF-STA-110
description: "Enhancement State Tracking: Blueprint-Aware Reference Updating."
type: Process Framework
category: State Tracking
version: 1.1
created: 2026-06-25
updated: 2026-06-29
target_feature: 2.2.1
enhancement_name: blueprint-aware-reference-updating
inherited_dimensions: SE,DI,EM,PE,OB
---

# Enhancement State Tracking: Blueprint-Aware Reference Updating

> **TEMPORARY FILE**: This file tracks enhancement work on an existing feature. Created by Feature Request Evaluation (PF-TSK-067), consumed by Feature Enhancement (PF-TSK-068). Move to `state-tracking/temporary/old/` when all steps are complete.

## Enhancement Overview

| Metadata | Value |
|----------|-------|
| **Target Feature** | 2.2.1 — Link Updating |
| **Secondary Features Affected** | None as a *target*. The fix touches `validator.py` (6.1.1 Link Validation) for a behavior-preserving extraction of the shared resolution-override helper, and the `PathResolver` constructor wiring in `service.py` (0.1.1 Core Architecture). The `path_resolution_overrides` config key already exists (0.1.3 Configuration System) — no schema change. |
| **Enhancement Description** | Extend the path_resolution_overrides virtual-root resolution (currently validate-only, in validator.py) to the live move/update path (PathResolver), so that host-absolute (/...) references between files in an override folder such as blueprint/ are matched and rewritten when a file is moved or renamed. Enables LinkWatcher to maintain references during blueprint restructuring/renaming, where links are intentionally written against the rollout-target root rather than the on-disk blueprint layout. |
| **Change Request** | Human partner wants LinkWatcher to maintain references during blueprint restructuring/renaming (e.g. adding a `-task` suffix to all task files, or reorganizing the blueprint tree). Blueprint links are "broken on purpose" — written against the rollout-target root, not blueprint's on-disk layout — so the live update path cannot match them today. Restructuring blueprint was the founding purpose of LinkWatcher, and blueprint is the primary place the human needs it. |
| **Human Approval** | 2026-06-25 — Classification (Enhancement) and target feature (2.2.1 Link Updating) confirmed by human partner |
| **Estimated Sessions** | 2–3 (Session 1: design — TDD/FDD/test-spec amendment + lightweight impl plan; Session 2: implementation + tests + integration + code review + user docs + state update; Session 3 contingency if review surfaces rework) |
| **Created By** | Feature Request Evaluation (PF-TSK-067) |

## Scope Assessment

| Criterion | Assessment |
|-----------|------------|
| **Files Affected** | ~4 source + tests. **Core**: `src/linkwatcher/path_resolver.py` (resolve `/…` against override base on input; strip base back off on output to preserve virtual-root style). **Shared helper**: extract `_build_resolution_overrides` + `_resolution_base_for` out of `validator.py` into a shared location (e.g. `utils.py` or a small `resolution_overrides.py`) consumed by both validator and PathResolver. **Refactor**: `src/linkwatcher/validator.py` (consume shared helper — behavior-preserving). **Wiring**: `src/linkwatcher/service.py` (plumb `path_resolution_overrides` config into the `PathResolver` constructor). Tests: `test/automated/unit/2-link-parsing-update/.../test_updater.py` + a blueprint-scenario integration/E2E test. |
| **Design Docs to Amend** | TDD (PD-TDD-026) — **Amend** (core: document override-aware resolution in PathResolver + shared helper). FDD (PD-FDD-027) — **Amend (lightweight)**: one subsection on override-folder reference maintenance. ADR — none (extends existing config concept; the virtual-root design decision is captured in the TDD amendment). |
| **New Tests Required** | Yes — new unit tests for override-aware resolution (input match + output base-stripping + non-override regression) and a blueprint-move integration/E2E scenario. |
| **Interface Impact** | Internal: `PathResolver.__init__` gains a `path_resolution_overrides` parameter. Public config interface unchanged (`path_resolution_overrides` key already exists). **User-visible behavior change**: file moves inside an override folder now rewrite host-absolute references — the capabilities reference currently documents this override as validate-only, so docs must be corrected. |
| **Session Estimate** | Multi-session (2–3). Core path-resolution engine change with Critical Data-Integrity risk (rewrites files based on a new match path); warrants a design pass, careful test coverage, and a real blueprint dry-run before live use. |

## Existing Documentation Inventory

| Document Type | ID | Location | Action Needed |
|---------------|-----|----------|---------------|
| Feature State File | PD-FIS-051 | [2.2.1 Link Updating](../../features/2.2.1-link-updating-implementation-state.md) | Update on completion |
| FDD | PD-FDD-027 | [fdd-2-2-1-link-updater.md](../functional-design/fdds/fdd-2-2-1-link-updater.md) | Amend (lightweight) |
| TDD | PD-TDD-026 | [tdd-2-2-1-link-updater-t2.md](../technical/tdd/tdd-2-2-1-link-updater-t2.md) | Amend |
| ADR | N/A | None — extends existing config concept; design decision captured in TDD amendment | No change |
| Test Specification | PF-TSP-040 | [test-spec-2-2-1-link-updating.md](../../../../test/specifications/feature-specs/test-spec-2-2-1-link-updating.md) | Amend |
| Capabilities Reference | PD-UGD (handbook) | [linkwatcher-capabilities-reference.md](../../../user/handbooks/linkwatcher-capabilities-reference.md) | Amend — override is documented as validate-only; correct to include live update path |

## Dimension Impact Assessment

> **Reference**: [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md)
>
> Inherited from parent feature (2.2.1): SE,DI,EM,PE,OB
> **Additional for this enhancement**: none — no new dimension becomes applicable. UX remains Not Applicable (internal component).
> **Reduced for this enhancement**: none.

### Key Dimension Considerations

- **Data Integrity (DI) — Critical (heightened)**: This is the central risk. The change makes the engine rewrite a class of references it previously left untouched (host-absolute `/…` links in override folders). A wrong resolution base or a missed base-strip on output would corrupt intentionally-"broken" blueprint links across many files at once. Mitigations: reuse the validator's proven base-resolution algorithm; keep the existing disk-existence guards (PD-BUG-095/112) in the match path; require a dry-run on a real blueprint move before live use; regression tests proving non-override behavior is byte-for-byte unchanged.
- **Security & Data Protection (SE) — Critical**: The resolution base is config-controlled. Ensure the resolved base and the resolved target stay under the project root (no path traversal via a crafted base or `../..` in a link). The existing `path_exists_under_root()` guard already enforces this on the match side — confirm it also covers the new resolution path.
- **Extensibility & Maintainability (EM) — Relevant**: Extract the resolution-override logic into a single shared helper so validator and PathResolver cannot drift. Two copies of a virtual-root algorithm is exactly the kind of duplication that causes blueprint to behave differently under `--validate` vs. live updates.
- **Observability (OB) — Relevant**: Emit a distinct log event when override-aware resolution rewrites a host-absolute reference (mirroring the validator's `validation_resolution_override_applied`), so blueprint rewrites are auditable and a misconfigured base is diagnosable.
- **Performance & Scalability (PE) — Relevant**: Negligible new cost — a per-source-file base lookup (the validator already caches this). Ensure the lookup isn't recomputed per-reference within a single file.

## Execution Steps

> **Structure**: These steps follow the standard feature development workflow from the [Task Transition Registry](../../infrastructure/task-transition-registry.md). Each block corresponds to a task type in the workflow. The Feature Request Evaluation task (PF-TSK-067) marks each block as **Applicable** or **Not applicable** based on the enhancement scope. The Feature Enhancement task (PF-TSK-068) executes applicable blocks in order.

---

### Step 1: Tier Reassessment

- **Status**: [x] Complete (2026-06-29) — Tier 2 confirmed appropriate; enhancement extends an existing resolution mechanism to a second code path, adds no new architectural dimension. No change.
- **Applicable**: No
- **Referenced Task Doc**: [Documentation Tier Adjustment (PF-TSK-011)](../../tasks/cyclical/documentation-tier-adjustment-task.md)
- **Rationale**: Not applicable — the enhancement is a contained extension of an existing resolution mechanism to a second code path. It adds no new architectural dimension. The target feature remains Tier 2.
- **Adaptation Notes**: Confirm Tier 2 remains appropriate and proceed.
- **Deliverable**: Confirmation that current Tier 2 is appropriate (no change).
- **Session**: 1

---

### Step 2: FDD Amendment

- **Status**: [x] Complete (2026-06-29) — PD-FDD-027 bumped to v1.1; added "Override-Folder Reference Maintenance" subsection (FR-8/FR-9, BR-8/BR-9, AC-7) describing virtual-root reference maintenance, with mechanics deferred to the TDD.
- **Applicable**: Yes (lightweight)
- **Referenced Task Doc**: [FDD Creation (PF-TSK-010)](../../tasks/02-design/fdd-creation-task.md)
- **Rationale**: The enhancement changes functional behavior — files moved inside an override folder now have their host-absolute references maintained, which they were not before. PD-FDD-027 exists and should record this.
- **Adaptation Notes**: Amend PD-FDD-027 with one subsection describing override-folder reference maintenance (when a source file declares a virtual resolution base, references to a moved file expressed as host-absolute `/…` links are matched and rewritten). Keep it brief; the mechanics live in the TDD.
- **Deliverable**: PD-FDD-027 amended with the override-folder behavior subsection.
- **Session**: 1

---

### Step 3: System Architecture Review

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [System Architecture Review (PF-TSK-019)](../../tasks/01-planning/system-architecture-review.md)
- **Rationale**: Not applicable — the change works within the existing architecture. Extracting the resolution-override logic into a shared helper is a local refactor (one new internal module/function shared by two existing consumers), not a new architectural pattern or cross-cutting concern. The design decision is captured in the TDD amendment (Step 6).
- **Adaptation Notes**: N/A.
- **Deliverable**: N/A.
- **Session**: N/A

---

### Step 4: API Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [API Design (PF-TSK-020)](../../tasks/02-design/api-design-task.md)
- **Rationale**: Not applicable — no API endpoints or contracts. The only interface change is an internal `PathResolver.__init__` parameter; the public config key already exists.
- **Adaptation Notes**: N/A.
- **Deliverable**: N/A.
- **Session**: N/A

---

### Step 5: Database Schema Design Amendment

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Database Schema Design (PF-TSK-021)](../../tasks/02-design/database-schema-design-task.md)
- **Rationale**: Not applicable — LinkWatcher has no database; link storage is an in-memory structure unaffected by this change.
- **Adaptation Notes**: N/A.
- **Deliverable**: N/A.
- **Session**: N/A

---

### Step 6: TDD Amendment

- **Status**: [x] Complete (2026-06-29) — PD-TDD-026 bumped to v1.1. Added "Override-Aware Path Resolution (v1.1)" design section (problem, per-file resolution base, input base-aware resolution in `_resolve_to_absolute_path`, output base-stripping in `_convert_to_original_link_type`, PD-BUG-045 no-double-fire, retained PD-BUG-095/112 + SE containment guards, `reference_lookup._filter_relative_links` scope boundary confirmed unchanged, wiring, OB event). Updated PathResolver/LinkUpdater constructor signatures, documented the new shared `resolution_overrides.py` module + its extraction-from-validator behavior-preserving note, and added it to the Internal Dependencies table.
- **Applicable**: Yes
- **Referenced Task Doc**: [TDD Creation (PF-TSK-022)](../../tasks/02-design/tdd-creation-task.md)
- **Rationale**: Core technical design change — this is the primary design record. PD-TDD-026 must document how PathResolver becomes override-aware.
- **Adaptation Notes**: Amend PD-TDD-026 to specify: (1) the shared resolution-override helper extracted from `validator.py` and its two consumers; (2) PathResolver **input** behavior — host-absolute `/…` links from an override-folder source resolve against `<project_root>/<base>/` before matching old_path; (3) PathResolver **output** behavior — when reconstructing a host-absolute link for an override-folder source, strip the base prefix so the virtual-root `/…` style is preserved (not the full disk path); (4) interaction with the existing PD-BUG-045 suffix match and the PD-BUG-095/112 disk-existence/separator guards (no double-fire, guards retained); (5) confirmation that the inside-moved-file path (`reference_lookup._filter_relative_links`) is intentionally unchanged.
- **Deliverable**: PD-TDD-026 amended with the override-aware resolution design.
- **Session**: 1

---

### Step 7: Test Specification

- **Status**: [x] Complete (2026-06-29) — TE-TSP-040 bumped to v1.1. Added "Override-Aware Resolution Tests (v1.1)" subsection with the five scenarios (a) override-source `/…` rewrite preserving virtual-root style, (b) non-override source unchanged regression, (c) non-existent resolved target guarded, (d) PD-BUG-112 separator preservation, (e) directory restructure — plus the byte-for-byte non-override regression assertion and target test-file placement. Marked specified-not-yet-implemented (implemented Session 2 / Step 15).
- **Applicable**: Yes
- **Referenced Task Doc**: [Test Specification Creation (PF-TSK-012)](../../tasks/03-testing/test-specification-creation-task.md)
- **Rationale**: The change adds new, high-risk behavior to a core engine; the scenarios should be specified before implementation given the Data-Integrity exposure.
- **Adaptation Notes**: Amend PF-TSP-040 with scenarios: (a) reference *to* a moved file expressed as host-absolute `/…` from an override-folder source is rewritten, preserving virtual-root style; (b) the same reference from a non-override source is left unchanged; (c) a `/…` reference whose resolved target does not exist on disk is left unchanged (guard); (d) backslash/separator preservation on override rewrites (PD-BUG-112 regression); (e) directory restructure (folder move) inside blueprint updates all affected `/…` references.
- **Deliverable**: PF-TSP-040 amended with override-aware resolution scenarios.
- **Session**: 1

---

### Step 8: Feature Implementation Planning

- **Status**: [x] Complete (2026-06-29) — sequenced inline plan written below (Implementation Plan, Session 2). Confirmed the wiring chain by source reading: `service.py:87` constructs `LinkUpdater(str(project_root), python_source_root=...)`; `LinkUpdater.__init__` builds `PathResolver` internally — so the new param threads service → LinkUpdater → PathResolver, mirroring `python_source_root`.
- **Applicable**: Yes (lightweight)
- **Referenced Task Doc**: [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning-task.md)
- **Rationale**: Ordering matters: the shared helper must be extracted (and the validator switched to it, proven behavior-preserving) before PathResolver can consume it. A short sequenced plan de-risks the refactor.
- **Adaptation Notes**: Sequence: (1) extract shared resolution-override helper, point `validator.py` at it, confirm validate suite green (pure refactor, no behavior change); (2) plumb `path_resolution_overrides` from config through `service.py` into `PathResolver.__init__`; (3) implement PathResolver input base-resolution; (4) implement PathResolver output base-stripping; (5) add OB log event; (6) tests at each step. A lightweight inline plan in this state file suffices — no separate PD-IMP document required.
- **Deliverable**: Sequenced step list (inline, lightweight) — see below.
- **Session**: 1

#### Implementation Plan (lightweight, inline — executed in Session 2)

> Anchored to the design in PD-TDD-026 § Override-Aware Path Resolution. Each sub-step has its own test gate; run `Run-Tests.ps1 -All` (or the targeted validate/unit suite noted) before moving on. The two highest-DI-risk sub-steps (P1, P3/P4) get a green suite as a checkpoint.

| # | Sub-step | Files | Verification gate |
|---|----------|-------|-------------------|
| P1 | **Extract shared helper** (behavior-preserving refactor). Create `src/linkwatcher/resolution_overrides.py` with `build_resolution_overrides()` (lifted verbatim from `Validator._build_resolution_overrides`) and `resolution_base_for_rel(overrides, source_rel)`. Repoint `validator.py` to consume it; keep `Validator._resolution_base_for` as a thin wrapper (absolute base + existing `validation_resolution_override_applied` event). | `resolution_overrides.py` (new), `validator.py` | **Validate suite green, unchanged** — pure refactor. Run existing validator tests; no behavior change. |
| P2 | **Plumb config** through the constructor chain. Add `path_resolution_overrides` param to `PathResolver.__init__` (normalize via shared helper, hold length-sorted list) and to `LinkUpdater.__init__` (passthrough). Pass `config.path_resolution_overrides` at `service.py:87`. | `path_resolver.py`, `updater.py`, `service.py` | Constructs cleanly with empty/None override (no-op); existing updater suite green. |
| P3 | **Input base-resolution**. Add `PathResolver._resolution_base_for(source_file)` (relative base via shared helper). In `_resolve_to_absolute_path`, for `is_absolute` targets with a non-empty base, resolve to `"<base>/" + target.lstrip("/")` instead of verbatim. | `path_resolver.py` | New unit test (scenario a) passes — override `/…` reference now matches the moved file. Non-override path (scenario b) byte-for-byte unchanged. |
| P4 | **Output base-stripping**. In `_convert_to_original_link_type`, for `is_absolute` targets with a non-empty base, return `"/" + new_path_norm.removeprefix(base + "/")` so virtual-root style is preserved. Add the `path_exists_under_root` containment guard on the override-resolved target (scenario c). | `path_resolver.py` | Scenarios a, c, d (separator preservation) pass. **Full suite green** — DI checkpoint. Confirm PD-BUG-045 suffix block is bypassed for override links (no double-fire). |
| P5 | **OB log event**. Emit `update_resolution_override_applied` when override resolution rewrites a host-absolute reference. | `path_resolver.py` | Event asserted in a unit test or observed in dry-run log. |
| P6 | **Integration + real-blueprint dry-run** (Step 12). Scenario e (directory restructure). Run a real blueprint single-file rename and a directory move under `dry_run_mode`; confirm correct `/…` rewrites before any live use. | `test_link_updates.py`, manual dry-run | Integration tests pass; documented dry-run output. |

> **Scope-boundary reminder for implementation**: do **not** touch `reference_lookup._filter_relative_links` (inside-moved-file relative links) — out of scope per the TDD scope boundary.

---

### Step 9: Data Layer Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Data Layer Implementation (PF-TSK-051)](../../tasks/04-implementation/data-layer-implementation.md)
- **Rationale**: Not applicable — no data models, repositories, or DB integration. Config plumbing is wiring (Step 8 plan), not a data-layer change.
- **Adaptation Notes**: N/A.
- **Deliverable**: N/A.
- **Session**: N/A

---

### Step 10: State Management Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [State Management Implementation (PF-TSK-052)](../../tasks/04-implementation/state-management-implementation.md)
- **Rationale**: Not applicable — no reactive state-management layer (LinkWatcher is a Python daemon/CLI).
- **Adaptation Notes**: N/A.
- **Deliverable**: N/A.
- **Session**: N/A

---

### Step 11: UI Implementation

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [UI Implementation (PF-TSK-050)](../../tasks/04-implementation/ui-implementation.md)
- **Rationale**: Not applicable — no UI; LinkWatcher is a CLI/daemon.
- **Adaptation Notes**: N/A.
- **Deliverable**: N/A.
- **Session**: N/A

---

### Step 12: Integration & Testing

- **Status**: [x] Complete (2026-07-06) — P1–P5 implemented per plan (shared `resolution_overrides.py` extracted, validator repointed [validate suite 130 green, unchanged], config plumbed service→LinkUpdater→PathResolver, input base-resolution, output base-stripping + `path_exists_under_root` containment guard, `update_resolution_override_applied` OB event). End-to-end integration tests pass (single-file rename + directory restructure through the real handler/batch flow). **Real-blueprint dry-run executed** against a sandbox copy of the actual FrameworkBuilder blueprint (417 files, real override mapping `blueprint: blueprint`, `dry_run_mode`): (1) single-file rename — 162 refs in 50 files proposed, 0 errors, the real virtual-root ref `/doc/state-tracking/permanent/user-workflow-tracking.md` rewritten to `/doc/...-renamed.md` preserving virtual-root style; (2) directory move `permanent/` → `permanent-renamed/` — 1648 refs across 51 updater calls proposed, 0 errors, virtual-root ref included. Whole-tree MD5 check byte-identical in both runs (dry run wrote nothing). Logs: scratchpad `dryrun-file-rename.log` / `dryrun-dir-move.log`; driver `dryrun_driver.py`. Sandbox used deliberately — renaming inside the live FrameworkBuilder tree would have triggered its deployed (pre-fix) daemon.
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: The change spans config → service wiring → PathResolver → updater and must be verified end-to-end, because the behavior is config-driven (the override base comes from a YAML key the unit tests don't exercise by default).
- **Adaptation Notes**: Verify an actual file move/rename inside a configured override folder rewrites references in sibling files correctly and preserves virtual-root `/…` style. **Run a real blueprint dry-run** (`dry_run_mode`) before any live use, since the override is config-driven and not exercised by the default suite — this is the manual-artifact check the Data-Integrity risk demands. Cover both a single-file rename (the `-task` suffix case) and a directory move (restructure case).
- **Deliverable**: Integration verification passing, including a documented real-blueprint dry-run.
- **Session**: 2

---

### Step 13: Quality Validation

- **Status**: [x] Complete (2026-07-06) — Scoped audit of the changed areas performed per the Adaptation Notes (inline report below). **Deviation (resolved 2026-07-06)**: the referenced task PF-TSK-054 was **merged into Code Review (PF-TSK-005) on 2026-06-15** (task registry tombstone) — ten days before this state file was created, so the step was authored from a pre-merge template copy (the current enhancement template has no Quality Validation step; verified only this instance carries the stale pointer). Human partner confirmed: quality-validation concerns are owned by Code Review, which runs as a **standalone task next session** (see Step 16); this audit stands as supporting analysis for that review.

  **Audit findings (SE/DI/EM/OB/PE against the Dimension Impact Assessment):**
  - **SE — path-traversal containment: PASS.** A config base containing `..` cannot cause an out-of-root rewrite: on input, a `..`-bearing resolved form can never equal a handler-derived `old_path` (always project-root-relative, no `..`), so no match fires; on output, the base-prefix strip only applies when the (handler-derived, `..`-free) new path actually starts with the base. The `path_exists_under_root` guard bounds rewrites to targets that exist under the root. *Minor observation (pre-existing, unchanged)*: `utils.path_exists_under_root` itself does not reject `..` in its candidate; safe here because all callers pass handler-derived paths.
  - **DI — guard retention: PASS.** Atomic write / backup / stale detection untouched (updater gained only a passthrough param). PD-BUG-095/112 early-exit guards untouched. Non-override invariance proven: full baseline suite green (949/949) + explicit byte-for-byte regression anchors (no-config v1.0 behavior test, non-override-source test, relative-links test).
  - **DI — audit finding (FIXED in-session): early-exit hijack of virtual-root links.** The early-exit equality/prefix branches compared the *unresolved* target to `old_path`, so a real root-level move coinciding with a blueprint virtual path (e.g. root `test/x.md` vs blueprint link `/test/x.md`) would wrongly rewrite the blueprint link. Fixed by skipping both early exits for override-source host-absolute targets (`is_virtual_root_link`), making base-aware Step-3 resolution the only match path for them. +2 regression tests (file + directory variants). TDD updated ("Early-exit branches skipped for virtual-root links"). Suite green after fix (954 unit).
  - **EM — single shared algorithm: PASS.** `resolution_overrides.py` is the only copy of normalize + longest-prefix match; validator delegates via thin wrappers (its public test surface preserved), resolver consumes the same functions.
  - **OB — PASS.** `update_resolution_override_applied` emitted on override rewrites, unit-asserted; mirrors the validator's event.
  - **PE — PASS.** Per-source-file base cache (`_resolution_base_cache`); lookup not recomputed per reference. Cache keyed by path string, entries never stale (base depends only on static config + path), growth bounded by distinct source files.
- **Applicable**: Yes
- **Referenced Task Doc**: [Quality Validation (PF-TSK-054)](../../tasks/04-implementation/quality-validation.md)
- **Rationale**: The enhancement modifies a Critical Data-Integrity engine that rewrites files based on a new match path; a dedicated quality audit of the changed areas is warranted beyond integration testing and code review.
- **Adaptation Notes**: Audit the override-aware resolution against the SE/DI considerations in the Dimension Impact Assessment: path-traversal containment of the config-supplied base, retention of the atomic-write / backup / disk-existence (PD-BUG-095/112) guards, and byte-for-byte invariance of non-override resolution. Scope the audit to the changed areas, not the whole feature.
- **Deliverable**: Quality validation report for the changed areas.
- **Session**: 2

---

### Step 14: Implementation Finalization

- **Status**: [ ] Not started
- **Applicable**: No
- **Referenced Task Doc**: [Implementation Finalization (PF-TSK-055)](../../tasks/04-implementation/implementation-finalization.md)
- **Rationale**: Not applicable — closure for this single coherent change is handled inline by Code Review (Step 16), the feature state update (Step 18), and the standard Release & Deployment workflow. No separate finalization pass needed.
- **Adaptation Notes**: N/A.
- **Deliverable**: N/A.
- **Session**: N/A

---

### Step 15: Update Tests

- **Status**: [x] Complete (2026-07-06) — All five TE-TSP-040 v1.1 scenarios implemented. Unit (`test_updater.py::TestOverrideAwareResolution`, 9 tests): (a) override rewrite + anchor preservation, (b) non-override source unchanged + no-config v1.0 byte-for-byte regression anchor (locks the legacy PD-BUG-045 lossy suffix result) + relative-links-unaffected, (c) non-existent-target containment guard + unmoved-path unchanged, (d) backslash separator preserved, plus OB-event assertion. Integration (`test_link_updates.py::TestOverrideAwareBlueprintUpdates`, 2 tests): (a)/(b) single-file rename end-to-end incl. outside-file untouched, (e) directory restructure end-to-end. Full suite: **960 passed** (baseline 949 + 11 new), 3 skipped, 4 xfailed — zero regressions.
- **Applicable**: Yes
- **Referenced Task Doc**: [Integration & Testing (PF-TSK-053)](../../tasks/04-implementation/integration-and-testing.md)
- **Rationale**: New behavior in a Critical-DI engine requires automated coverage matching the Step 7 spec.
- **Adaptation Notes**: Implement the PF-TSP-040 scenarios in `test/automated/unit/2-link-parsing-update/2-0-link-parsing-update/test_updater.py` (and `test_link_updates.py` for integration). Must include a regression assertion that non-override resolution is byte-for-byte unchanged, and a PD-BUG-112-style separator-preservation case on an override rewrite. Use the existing test markers/registry conventions.
- **Deliverable**: New/updated passing test cases for override-aware resolution.
- **Session**: 2

---

### Step 16: Code Review

- **Status**: [x] Routed to next session (2026-07-06) — per human partner direction, the **formal Code Review (PF-TSK-005) runs as its own task in the next session** (the standard Feature Enhancement → Code Review transition), reviewing this enhancement's change set. An in-session preparatory self-review was performed (results below) and stands as input for that review, not as its substitute. Preparatory self-review: **PASS**, no Critical/Major findings. Change set scoped via `git diff HEAD` to the 4 modified src files + new `resolution_overrides.py` (unrelated untracked `linkwatcher_control_panel/` excluded). Automated checks: black clean; flake8 clean except pre-existing E203 (black slice-style conflict, same pattern exists at HEAD). Coverage of changed modules: resolution_overrides 100%, validator 100%, updater 93%, path_resolver 83% (all >80%). Focus-area verdicts: (1) file-rewrite safety — atomic write/backup/stale detection untouched, override path adds its own existence guard; (2) path-traversal containment — see Step 13 audit, PASS; (3) validator refactor genuinely behavior-preserving — pure delegation, 130 validator tests green, 100% coverage; (4) override/non-override non-interference — `is_virtual_root_link` scoping + byte-for-byte v1.0 regression anchors. FDD acceptance criteria validated: FR-8/FR-9/BR-8/BR-9/AC-7 all met with test evidence. 🔵 Suggestions (observations, not filed): `updater.py` passthrough param could carry an `Optional[Dict[str, str]]` annotation; project-wide flake8 `extend-ignore = E203` would resolve the black conflict (pre-existing); `utils.path_exists_under_root` does not itself reject `..` in candidates (pre-existing semantics, all current callers pass handler-derived paths).
- **Applicable**: Yes
- **Referenced Task Doc**: [Code Review (PF-TSK-005)](../../tasks/06-maintenance/code-review-task.md)
- **Rationale**: Core path-resolution logic that rewrites files — review is mandatory and carries the DI/SE rigor de-scoped from Step 13.
- **Adaptation Notes**: Focus review on: file-rewrite safety (existing atomic-write/backup/guards retained); path-traversal containment of the config-supplied base (`path_exists_under_root`); that the validator refactor is genuinely behavior-preserving; and that override and non-override code paths can't interfere. **Framework note**: this is product code, so Code Review (PF-TSK-005) is the correct task (not the inline review used for framework changes).
- **Deliverable**: Code review completed; issues resolved.
- **Session**: 2

---

### Step 17: User Documentation

- **Status**: [x] Complete (2026-07-06) — Corrected the validate-only claim in all four touchpoints: **Capabilities Reference** (config-table row now says validation AND live updates; new "Override-folder virtual-root links" bullet under "On move detection" with safety guards + OB event; validation-mode smart-resolution line mentions the shared override rule), **Configuration Guide** (§ Per-Folder Path Resolution Override rewritten — applies to both paths, blueprint-restructuring use case, rewrite-safety guards, removed "validation-only" bullet), **Link Validation handbook** ("Not validation-only (since v2.2)" bullet with pointer to Configuration Guide), **Quick Reference** (callout now covers live updates). Note: docs say "v2.2" anticipating the next minor release (current 2.1.3); confirm at Release & Deployment.
- **Applicable**: Yes
- **Referenced Task Doc**: [User Documentation Creation (PF-TSK-081)](../../tasks/07-deployment/user-documentation-creation.md)
- **Rationale**: The behavior is user-visible and current docs are now inaccurate — the Capabilities Reference describes `path_resolution_overrides` as validate-only, which this change disproves.
- **Adaptation Notes**: Update [linkwatcher-capabilities-reference.md](../../../user/handbooks/linkwatcher-capabilities-reference.md) (the `path_resolution_overrides` row and the "What LinkWatcher Does NOT Do" / validation sections) and the [Configuration Guide](../../../user/handbooks/configuration-guide.md) to state the override applies to the live move/update path, not just `--validate`. Note the blueprint-restructuring use case.
- **Deliverable**: Updated Capabilities Reference + Configuration Guide.
- **Session**: 2

---

### Step 18: Update Feature State

- **Status**: [x] Complete (2026-07-06) — PD-FIS-051 reconciled (v2.1): §2 Current State Summary (status/task/What's Working/In Progress), §3 enhancement entry, §4 doc inventory (FDD/TDD/test-spec v1.1 dates, TE-TSP-040 ID label corrected, user-doc handbook rows added), §5 Code Inventory (`resolution_overrides.py` new row, path_resolver/updater rows updated), §7 SE/DI reaffirmed with v1.1 guard notes, §10 Next Steps (Code Review next session, then Release). Feature-tracking status restored via `Finalize-Enhancement.ps1 -RestoredStatus "👀 Needs Review"` (Code Review trigger status, per human partner direction that the formal review runs next session).
- **Referenced Task Doc**: N/A — direct state file update
- **Rationale**: Feature state must reflect the enhancement.
- **Adaptation Notes**: Update PD-FIS-051 (2.2.1 Link Updating): add the enhancement to §3 Implementation Progress and §9 Issues & Resolutions Log; note the new `PathResolver` override parameter in §5 Code Inventory; reaffirm the SE/DI considerations in §7. Restore feature-tracking status off "🔄 Needs Enhancement".
- **Deliverable**: Updated PD-FIS-051 and feature-tracking status.
- **Session**: 2

---

## Session Boundary Planning

> **Instructions**: For multi-session enhancements, define which steps belong to each session. For single-session enhancements, this section can be removed.

### Session 1: Design

**Planned Steps**: Steps 1, 2, 6, 7, 8 (Tier confirm, FDD amend, TDD amend, Test Spec amend, lightweight impl plan). Steps 3–5, 9–11 confirmed Not Applicable.
**Goal**: Design and test scenarios fully specified; implementation sequence agreed. No production code changed yet.

### Session 2: Implementation, Verification & Closure

**Planned Steps**: Steps 12, 13, 15, 16, 17, 18 (Integration & blueprint dry-run, quality validation, implement tests, code review, user docs, feature-state update). Step 14 confirmed Not Applicable.
**Goal**: Override-aware resolution implemented and wired; tests passing; real-blueprint dry-run verified; quality-audited; code reviewed; docs corrected; feature state updated. Ready for Release & Deployment.

> **Session 3 (contingency)**: only if Code Review (Step 16) surfaces rework that can't close in Session 2.

> **Implementation note**: per the [Prohibited Git Commands](../../../../CLAUDE.md) rule and the [LinkWatcher-corrupts-test-data-on-move] hazard, the implementation session should be mindful that editing path-dense files (this very enhancement touches resolution of `/…` paths) while the daemon runs can interact with live link updates — verify the active log and run tests before and after any relocation.

## Session Log

### Session 1: 2026-06-29

**Completed**:
- Step 1 (Tier Reassessment) — Tier 2 confirmed, no change.
- Step 2 (FDD Amendment) — PD-FDD-027 → v1.1, added Override-Folder Reference Maintenance subsection.
- Step 6 (TDD Amendment) — PD-TDD-026 → v1.1, added Override-Aware Path Resolution design section + constructor/dependency updates + shared `resolution_overrides.py` module.
- Step 7 (Test Specification) — TE-TSP-040 → v1.1, added five override-aware scenarios + non-override regression assertion.
- Step 8 (Feature Implementation Planning) — sequenced inline plan (P1–P6) written; wiring chain confirmed by source reading.
- Steps 3–5, 9–11 confirmed Not Applicable (per pre-set rationale).

**Issues**:
- None blocking. Design discovery worth recording: the existing PD-BUG-045 suffix match *incidentally* matches some blueprint links today (when override base == folder) but strips the leading slash, losing virtual-root style and only firing for same-subtree sources. The v1.1 base-aware input resolution makes the principled match fire first, bypassing this lossy fallback. Captured in the TDD "no double-fire" note.
- Minor: the state file refers to the test spec as "PF-TSP-040"; the document's actual ID is **TE-TSP-040** (test artifact, not a PF doc). No action needed for design; noted so Session 2 references the right ID.

**Next Session (Session 2 — Implementation, Verification & Closure)**:
- Execute the P1–P6 implementation plan (Step 8) in order. P1 (shared-helper extraction) is a behavior-preserving refactor — validate suite must stay green before proceeding.
- Steps 12 (integration + real-blueprint dry-run), 13 (quality validation), 15 (implement tests), 16 (code review), 17 (user docs: capabilities reference + configuration guide), 18 (feature-state update + Finalize-Enhancement.ps1).
- Heed the implementation note: be mindful of the live daemon when editing path-dense files; verify active log and run tests before/after any relocation.

### Session 2: 2026-07-06

**Completed**:
- P1–P6 implementation plan executed in order, each with its test gate (P1 validator refactor: 130 tests green unchanged; final full suite: 962 passed = 949 baseline + 13 new, 0 regressions).
- Step 15 (Update Tests) — 11 unit + 2 integration tests implementing all five TE-TSP-040 v1.1 scenarios plus anti-hijack regressions; test-tracking.md rows updated (58 / 48 counts).
- Step 12 (Integration & Testing) — end-to-end integration tests + real-blueprint dry-run (sandbox copy, 417 files, real `blueprint: blueprint` mapping): file rename 162 refs / dir move 1648 refs proposed, 0 errors, whole-tree MD5 byte-identical.
- Step 13 (Quality Validation) — scoped SE/DI/EM/OB/PE audit (inline report at Step 13). Found + fixed the early-exit virtual-root hijack (DI); TDD updated; +2 regression tests.
- Step 16 (Code Review) — routed to next session as standalone PF-TSK-005 per human partner; in-session preparatory self-review PASS (no Critical/Major), recorded as review input.
- Step 17 (User Documentation) — validate-only claim corrected in Capabilities Reference, Configuration Guide, Link Validation, Quick Reference.
- Step 18 (Update Feature State) — PD-FIS-051 reconciled (v2.1); feature-tracking restored to 👀 Needs Review via Finalize-Enhancement.ps1; this file archived.

**Issues**:
- Step 13's referenced task (PF-TSK-054) was merged into Code Review on 2026-06-15, before this state file was authored (2026-06-25) — stale pointer in this instance only; current enhancement template verified clean (no Quality Validation step). Noted for feedback: Feature Request Evaluation authored a step from a pre-merge template copy.
- User handbooks reference "v2.2" anticipating the next minor release (current 2.1.3) — confirm at Release & Deployment.

**Next Session**:
- Code Review (PF-TSK-005) of the enhancement change set (feature 2.2.1 at 👀 Needs Review). Then Release & Deployment — the deployed daemon lags repo source; blueprint live use needs the release.

## Finalization Checklist

> **Instructions**: Complete when all applicable execution steps are done. This checklist is part of the Feature Enhancement task (PF-TSK-068) completion process.

- [x] All applicable execution steps marked complete (Steps 1, 2, 6, 7, 8, 12, 13, 15, 17, 18; Step 16 routed to next session as standalone Code Review per human partner)
- [x] All non-applicable steps confirmed as "Not applicable" with rationale (Steps 3–5, 9–11, 14)
- [x] Target feature's implementation state file updated to reflect enhancement (PD-FIS-051 v2.1, 2026-07-06)
- [x] Feature tracking status restored (removed "🔄 Needs Enhancement" → "👀 Needs Review" for next-session Code Review, state file link removed via Finalize-Enhancement.ps1)
- [x] This file archived to `state-tracking/temporary/old/` (via Finalize-Enhancement.ps1)
