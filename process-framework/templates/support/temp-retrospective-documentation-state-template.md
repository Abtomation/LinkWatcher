---
id: PF-TEM-077
type: Process Framework
category: Template
version: 1.0
created: 2026-05-07
updated: 2026-05-07
task_name: [TASK-NAME]
parent_state: [PF-STA-XXX — retrospective master state file]
feature_id: [X.Y.Z]
description: "Multi-session per-feature state tracking for retrospective documentation creation (PF-TSK-066 Phase 3) — includes Feature Overview, Required Phase 3 Deliverables table (Steps 5–13), Per-Feature Closure Updates table (Steps 15–17), Session Plan (via New-TempTaskState.ps1 -Variant RetrospectiveDocumentation)"
---

# Temporary State: PF-TSK-066 Phase 3 — Feature [X.Y.Z] [Feature Name]

> **⚠️ TEMPORARY FILE**: Tracks multi-session execution of [PF-TSK-066 Phase 3 (Documentation Creation)](../../tasks/00-setup/retrospective-documentation-creation.md) for feature [X.Y.Z] only. Move to `doc/state-tracking/temporary/old/` when all Phase 3 deliverables for this feature are complete and the master state records it as fully documented.
>
> **Use when**: A single feature's Phase 3 cycle spans multiple sessions (typically Tier 2/3 features where Test Spec / QAR / user-doc audit need to be deferred to a follow-up session). For Tier 1 features and small Tier 2 features that fit in one session, track progress in the master retrospective state file directly.
>
> **Parent context**: Scopes a single feature within the broader retrospective onboarding tracked in [parent_state]. Sibling features are handled in their own sessions/trackers.

## Feature Overview

- **Feature**: [X.Y.Z] [Feature Name]
- **Tier**: [1 / 2 / 3] [color emoji] — normalized score [N.NN]
- **Classification**: [As-Built / Target-State] (avg [N.N] / 3.0)
- **Tier validation status (Step 3)**: [⬜ Not started / ✅ Confirmed YYYY-MM-DD — rationale]
- **Feature Implementation State**: [PD-FIS-XXX](../../../doc/state-tracking/features/X.Y.Z-Feature-Name-implementation-state.md)
- **Tier Assessment**: [PD-ASS-XXX](../../../doc/documentation-tiers/assessments/PD-ASS-XXX-X.Y.Z-feature-name.md)
- **Headline risks**: [TDXXX (severity), TDXXX (severity)]

## Required Phase 3 Deliverables

> Status legend: ⬜ Not started | 🟡 In progress | ✅ Complete | ⏭️ Deferred to later session | N/A — Not required

| # | Deliverable | PF-TSK-066 Step | Required by | Status | Doc ID | Session |
| - | ----------- | --------------- | ----------- | ------ | ------ | ------- |
| 1 | FDD ([As-Built / Target-State + Gap Analysis]) | 5 | Tier 2+ | ⬜ | [PD-FDD-XXX] | — |
| 2 | TDD ([Tier N] [As-Built / Target-State + Gap Analysis]) | 6 | Tier 2+ | ⬜ | [PD-TDD-XXX] | — |
| 3 | Test Specification | 7 | Tier 2+ | ⬜ | [TE-TSP-XXX] | — |
| 4 | (Test Migration) | 8 | Tier 2+ with pre-existing tests | [N/A or status] | — | — |
| 5 | ADR(s) — [decision title(s) if any] | 9 (generalized) | When architectural decisions exist | [⬜ / N/A] | [PD-ADR-XXX] | — |
| 6 | UI Design Document | 10 | When PD-ASS says required | [⬜ / N/A] | [PD-UIX-XXX] | — |
| 7 | Database Schema Design | 10 | When PD-ASS says required | [⬜ / N/A] | [PD-SCH-XXX] | — |
| 8 | API Design | 10 | When PD-ASS says required | [⬜ / N/A] | [PD-API-XXX] | — |
| 9 | Tech debt items from gap analysis | 11 | Target-State | ⬜ | TDXXX–TDXXX | — |
| 10 | Quality Assessment Report (PD-QAR) | 12 | Target-State only | [⬜ / N/A] | [PD-QAR-XXX] | — |
| 11 | User Documentation Coverage audit | 13 | All features | ⬜ | [4 ❌/✅ result + flag] | — |

> **Step 9 ADR scope note**: Although PF-TSK-066 Step 9 wording mentions foundation features only, ADRs apply to any feature with genuine architectural decisions. Create ADRs whenever the design warrants them, regardless of feature category.

## Per-Feature Closure Updates (also Phase 3)

| # | Update | PF-TSK-066 Step | Status | Session |
| - | ------ | --------------- | ------ | ------- |
| C1 | Update PD-FIS-XXX (Section 4 Doc Inventory + Quick Links + User Documentation; Section 8 QAR; Section 10 Next Steps) | 15 | ⬜ | — |
| C2 | Update [feature-tracking.md](../../../doc/state-tracking/permanent/feature-tracking.md) — Status flip + Description rewrite + Update History row | 16 | ⬜ | — |
| C3 | Update [retrospective master state](parent_state) — Phase 3 row for [X.Y.Z] + Session log entry | 17 | ⬜ | — |
| C4 | Complete feedback form for session(s) | Final | ⬜ | — |

## Session Plan

### Session 1 — [YYYY-MM-DD]

**Scope**: [What this session covers — e.g., "Design core: FDD + TDD + ADRs + Schema + UI Design + tech-debt deltas + state-file updates"]

**Out of scope this session** (deferred): [What is being deferred and why]

**Order of execution**:
1. [Step 1]
2. [Step 2]
3. [...]

**Checkpoints planned**: [List the human-checkpoint moments per PF-TSK-066]

### Session 2 — [YYYY-MM-DD]

**Scope**: [What this session covers — typically the deferred items + closure]

**Order of execution**:
1. [Step 1]
2. [Step 2]
3. [...]

## Session Log

### Session 1 — [YYYY-MM-DD]

- **Status**: [⬜ Not started / 🟡 In progress / ✅ COMPLETE]
- **Master state log reference**: [Session N entry in retrospective-master-state.md]
- **Completed**:
  - [bullets — created docs with IDs and links, registered TDs, state file updates]
- **Issues / Blockers**:
  - [bullets — script gripes, framework improvement candidates, deferred decisions]
- **Next steps after this session**:
  - [bullets]

### Session 2 — [YYYY-MM-DD]

- **Status**:
- **Master state log reference**:
- **Completed**:
  -
- **Issues / Blockers**:
  -
- **Next steps after this session**:
  -

## Notes / Decisions Log

- **[YYYY-MM-DD]** — [Decision / clarification]: [rationale, links to memory or feedback if persisted]

## Update History

| Date | Change | Updated By |
| ---- | ------ | ---------- |
| [YYYY-MM-DD] | Initial creation — scope plan + Session 1 outline | PF-TSK-066 Phase 3 (this session) |
| [YYYY-MM-DD] | Session 1 complete — [summary]. [Deferred items] → Session 2. | Session 1 closeout |
| [YYYY-MM-DD] | Session 2 complete — [summary]. Phase 3 for [X.Y.Z]: COMPLETE. Tracker ready for archival. | Session 2 closeout |
