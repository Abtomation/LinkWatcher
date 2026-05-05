---
id: PD-REF-200
type: Process Framework
category: Refactoring Plan
version: 1.0
created: 2026-04-28
updated: 2026-04-28
mode: documentation-only
debt_item: TD234
priority: Medium
target_area: doc/technical/tdd/tdd-3-1-1-logging-framework-t2.md
refactoring_scope: Clarify hot-reload claims in PD-TDD-024 logging framework TDD
feature_id: 3.1.1
---

# Documentation Refactoring Plan: Clarify hot-reload claims in PD-TDD-024 logging framework TDD

## Overview
- **Target Area**: doc/technical/tdd/tdd-3-1-1-logging-framework-t2.md
- **Priority**: Medium
- **Created**: 2026-04-28
- **Author**: AI Agent & Human Partner
- **Status**: Complete
- **Mode**: Documentation-only (no code changes, no test impact)
- **Debt Item**: TD234

## Refactoring Scope

### Current Issues

PD-TDD-024 presents `LoggingConfigManager` config hot-reload as a production-active capability. Independent verification shows it is implemented dead code: no production caller instantiates `LoggingConfigManager` and even `tools/logging_dashboard.py` only imports `get_config_manager` without invoking it. The misleading framing appears across nine sections, not just Section 5 named in the original TD.

Affected sections in PD-TDD-024:
- §1.1 Purpose — names hot-reload alongside other delivered features
- §2 Key Requirements (#5) — "applies changes to log level and filters within 1 second, without service restart"
- §4.1 — full `LoggingConfigManager` design block presented as active subsystem
- §4.3 Design Patterns — Observer Pattern (config hot-reload) listed as a pattern in use
- §4.4 Reliability Implementation — describes hot-reload error handling as production behavior
- §5.1 Functional Requirements — claims FR-8 (config hot-reload) is implemented by this TDD
- §6.2 Implementation Notes — describes `logging_config.py` as the runtime configuration layer
- §8 Open Questions / Known Tech Debt — references hot-reload limitations as if active
- §9 Key Decisions — "Daemon thread for hot-reload" listed as a key implementation decision

### Scope Discovery

- **Original Tech Debt Description**: "TDD PD-TDD-024 Section 5 claims config hot-reload via LoggingConfigManager with 1-second poll, but main.py and service.py never instantiate LoggingConfigManager; production LinkWatcher requires restart for any config change (only tools/logging_dashboard.py uses it)."
- **Actual Scope Findings**:
  - Confirmed `main.py` and `service.py` never instantiate `LoggingConfigManager` (zero matches in `src/`).
  - The dashboard claim is partly inaccurate — `tools/logging_dashboard.py:30` *imports* `get_config_manager` but never calls it. There is **no callsite** that activates hot-reload anywhere in the codebase.
  - Misleading framing is spread across 9 TDD sections, not only Section 5 (Cross-References, where the claim only surfaces obliquely as the FR-8 reference).
  - The 0.1.3 Configuration System feature state file already documents the no-hot-reload reality as by-design: `doc/state-tracking/features/0.1.3-configuration-system-implementation-state.md:64,272` ("Runtime configuration hot-reload (not implemented)" and "No hot-reload | By design — simplicity over runtime flexibility").
- **Scope Delta**: Expanded from §5 to all nine affected sections. The dashboard parenthetical in the TD is corrected to "imported but never invoked" rather than "the dashboard uses it."

### Drift Mechanism (DA Root Cause)

- **Originating task**: PF-TSK-066 Retrospective Documentation Creation during onboarding (TDD frontmatter: `created: 2026-02-19`, `retrospective: true`).
- **Mechanism**: The retrospective process derived the TDD from "source code analysis of `src/linkwatcher/logging.py` and `src/linkwatcher/logging_config.py`" — a static, what-the-code-does analysis. It correctly described the `LoggingConfigManager` class structure but did not verify whether production callers actually instantiate it at runtime. Source-code-presence was treated as a proxy for runtime-active behavior.
- **Cross-feature blind spot**: The 0.1.3 Configuration System state file already records "No hot-reload — by design" as a known limitation. The 3.1.1 Logging TDD did not cross-reference this and instead presented hot-reload as a delivered capability of the logging feature.
- **Lesson for future retrospective TDDs**: For any feature that documents a capability requiring runtime wiring (hot-reload, watcher threads, plugin loading), retrospectively verify the wiring exists by grepping for instantiation/invocation in the entry-point modules, not just the existence of the class.

### Refactoring Goals

1. Reframe hot-reload throughout PD-TDD-024 from "implemented production capability" to "designed but not wired into production startup" — preserve the design rationale (it remains valuable as documentation of intent) while eliminating the false claim of production behavior.
2. Add a single anchor section/note that explains the gap between design and wiring, and cross-references the 0.1.3 state file's by-design rationale.
3. Correct §5.1's FR-8 claim so a reader using this TDD as a contract reference cannot conclude that FR-8 is satisfied by the current production system.

## Current State Analysis

### Documentation Quality Baseline

- **Accuracy**: Inaccurate on hot-reload — the document implies a runtime-active subsystem that is dead code in production. All other content (logger, context, timer, dual backend) is accurate.
- **Completeness**: Complete on what is documented; missing the explicit gap between design and production wiring for `LoggingConfigManager`.
- **Cross-references**: §5 references FDD PD-FDD-025 and existing tests; the FR-8 reference is the single misleading cross-reference. No broken links.
- **Consistency**: Terminology and formatting consistent — the issue is factual content, not structure.

### Affected Documents

- **Primary**: `doc/technical/tdd/tdd-3-1-1-logging-framework-t2.md` — edits in nine sections listed above.
- **No other documents** require changes:
  - 0.1.3 state file already accurately documents the limitation.
  - 3.1.1 logging feature state file (archived) describes the class as implemented, which is true at the code level — does not need updating.
  - FDD PD-FDD-025 (`doc/functional-design/fdds/fdd-3-1-1-logging-framework.md`) describes FR-8 as a requirement; the requirement itself is fine, only the TDD's claim that FR-8 is *delivered* needs correction.

### Dependencies and Impact

- **Cross-references inbound to the TDD**: Validation reports under `doc/validation/reports/` reference PD-TDD-024 by ID; their content is not affected by clarifying hot-reload framing.
- **State files**: None require updates beyond TD tracking.
- **Risk Assessment**: Low — no behavioral changes, no code touched, no test impact. Risk is limited to introducing prose ambiguity, mitigated by careful wording reviewed at L11 checkpoint.

## Refactoring Strategy

### Approach

Surgical edits — keep §4.1's `LoggingConfigManager` design block intact (it remains an accurate description of the class and is useful for any future caller that wires hot-reload in), but reframe surrounding sections so the reader cannot conclude the capability is production-active. Add one explicit "Production Status" callout near the LoggingConfigManager design block as the canonical statement of the gap, and adjust other sections to reference or echo that callout rather than re-asserting hot-reload.

### Implementation Plan

1. **Phase 1: High-impact reframings** (claims of delivery)
   - Step 1.1: §2 Key Requirements #5 — change from "applies changes... within 1 second, without service restart" to a designed-but-not-wired statement.
   - Step 1.2: §5.1 Brief Summary — remove "config hot-reload (FR-8)" from the list of FRs satisfied; add a note that FR-8 is designed but not wired into production.
   - Step 1.3: §4.1 — add a "Production Status" callout immediately after the `LoggingConfigManager` block stating: not instantiated by `main.py`/`service.py`; only `tools/logging_dashboard.py` imports `get_config_manager` and does not invoke it; cross-reference 0.1.3 state file.

2. **Phase 2: Supporting reframings**
   - Step 2.1: §1.1 Purpose — soften "delivers... runtime config hot-reload" to phrasing that reflects the implemented-but-unwired status.
   - Step 2.2: §4.3 Observer Pattern — keep the pattern entry but note it is a designed pattern not currently exercised at runtime.
   - Step 2.3: §4.4 Reliability Implementation — remove the hot-reload reliability bullet or rephrase to "If wired in the future, …".
   - Step 2.4: §6.2 Implementation Notes — keep mention of the runtime-config layer existing, note it is not wired into production startup.
   - Step 2.5: §8 Known Technical Debt — replace the existing hot-reload limitation note with the actual production status (no hot-reload), pointing to the 0.1.3 by-design rationale.
   - Step 2.6: §9 Key Decisions — keep the daemon-thread choice as a design decision, append "(implemented in `logging_config.py` but not currently activated in production)".

## Verification Approach

- **Link validation**: LinkWatcher running in background; will confirm zero broken links after edits via `python main.py --validate` post-edit if needed.
- **Content accuracy**: Re-grep `main.py`, `src/`, and `tools/` for `LoggingConfigManager` after edits — confirm post-edit prose matches grep results (no production instantiation, dashboard import only, no invocation).
- **Consistency check**: Read the TDD end-to-end after edits to confirm no section continues to assert hot-reload as a delivered capability that contradicts another section's reframed statement.

## Success Criteria

### Documentation Quality Improvements

- **Accuracy**: A reader scanning PD-TDD-024 cannot conclude that LinkWatcher applies config changes at runtime — every section that touches hot-reload either (a) reframes it as designed-but-unwired or (b) defers to the new Production Status callout.
- **Completeness**: PD-TDD-024 explicitly cross-references the 0.1.3 by-design rationale, closing the cross-feature blind spot identified in the drift analysis.
- **Cross-references**: §5.1 FR-8 status accurately reflects the production gap; no implicit claim that FR-8 is satisfied.

### Documentation Integrity

- [ ] All existing cross-references preserved or updated
- [ ] No orphaned references created
- [ ] Terminology consistent with project conventions
- [ ] LinkWatcher confirms no broken links

## Implementation Tracking

### Progress Log

| Date | Phase | Completed Work | Issues Encountered | Next Steps |
|------|-------|----------------|-------------------|------------|
| 2026-04-28 | Planning | PD-REF-200 plan drafted; drift analysis completed; scope expanded from §5 to all 9 affected sections | None | L5 checkpoint, then implement Phase 1 |
| 2026-04-29 | L5 Checkpoint | Plan approved by human partner | None | Implement edits |
| 2026-04-29 | Implementation | Edited 10 sections in PD-TDD-024 (§1.1, §2 #5, §3.3 Config Integrity discovered during verification, §4.1 Production Status callout added, §4.3, §4.4, §5.1, §6.2, §8, §9). Updated TDD frontmatter `updated:` to 2026-04-29. | §3.3 Config Integrity bullet was not in the original plan but was discovered during the verification grep — it asserted hot-reload reliability as a delivered guarantee; reframed to match the rest of the doc. Total: 10 sections edited (vs. 9 in the original plan). | Verify final state, archive plan, mark TD234 resolved |

## Results

### Documentation & State Updates Checklist

**Documentation-only shortcut applied**: Items 1–7 batched as N/A with single justification: *"Documentation-only change — no behavioral code changes; design and state documents do not reference an implementation that needs updating for the clarified hot-reload framing. The TDD itself is the only document that misrepresented production behavior."* Item 8 (TD tracking) checked individually.

1. **Feature implementation state file**: N/A — see batch justification. The 3.1.1 archived state file describes the class as implemented, which remains accurate at the code level.
2. **TDD updated**: ✅ Done — PD-TDD-024 is the target document; 10 sections edited.
3. **Test spec updated**: N/A — see batch justification.
4. **FDD updated**: N/A — see batch justification. PD-FDD-025's FR-8 requirement remains valid; the gap is in the TDD's claim that FR-8 is delivered, which is now corrected in the TDD itself.
5. **ADR updated**: N/A — see batch justification.
6. **Integration Narrative updated**: N/A — see batch justification.
7. **Validation tracking updated**: N/A — see batch justification.
8. **Technical Debt Tracking**: ✅ TD234 marked Resolved (PD-REF-200, 2026-04-29).

### Results Summary

| Aspect | Outcome |
|--------|---------|
| Sections reframed | 10 (1 more than planned — §3.3 Config Integrity discovered during L7-equivalent verification grep) |
| Production Status anchor added | ✅ §4.1 — `#loggingconfigmanager-production-status` |
| Cross-reference to 0.1.3 by-design rationale | ✅ Added in §4.1 callout, §2 Key Req #5, §5.1, §8 |
| FR-8 status corrected | ✅ §5.1 now states 7 of 8 FRs delivered; FR-8 is designed but not delivered |
| `LoggingConfigManager` design block preserved | ✅ §4.1's class block kept verbatim — accurate code documentation |
| LinkWatcher / broken links | No new broken links; all anchor references resolve to the new §4.1 anchor |
| Test impact | None — no code or tests touched |
| New bugs discovered | None |
| Test baseline | Skipped (documentation-only exemption per Lightweight Path L3) |
| Regression test diff | Skipped (documentation-only exemption per Lightweight Path L7) |

### Remaining Technical Debt

None — TD234 fully resolved.

### Drift Mechanism — Forward Lesson

The drift originated in PF-TSK-066 (Retrospective Documentation Creation) where the TDD was derived from static source-code analysis without verifying runtime wiring. The 0.1.3 Configuration System state file already recorded the by-design no-hot-reload limitation, but the 3.1.1 TDD did not cross-reference it. The corrected TDD now does. No process improvement is filed for this single occurrence per the project's "no anti-pattern callouts from a single occurrence" policy; if a second similar drift surfaces in another retrospective TDD, escalate to a process improvement adding "verify runtime wiring, not just class existence" to the retrospective TDD checklist.

## Related Documentation

- [Technical Debt Tracking](/doc/state-tracking/permanent/technical-debt-tracking.md)
- [PD-TDD-024 Logging Framework TDD](/doc/technical/tdd/tdd-3-1-1-logging-framework-t2.md)
- [0.1.3 Configuration System State File](/doc/state-tracking/features/0.1.3-configuration-system-implementation-state.md)
- [PD-FDD-025 Logging Framework FDD](/doc/functional-design/fdds/fdd-3-1-1-logging-framework.md)
