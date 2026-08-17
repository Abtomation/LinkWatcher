# Documentation Tier Assessment: Scoring Criteria

The scoring criteria and design-requirement criteria for assessing a feature's documentation tier.
The assessment **procedure** is embedded in the Feature Request Evaluation task (new-feature path)
and reused by the onboarding/setup tasks' tier-assessment steps; this reference is what those
procedures score against. The assessment document (PD-ASS) is always created via
`process-framework/scripts/file-creation/01-planning/New-Assessment.ps1` — never hand-authored —
for correct ID sequencing and template structure (`Get-Help New-Assessment.ps1 -Parameter *` for the full parameter set).

## Scoring

1. Score each complexity factor **1 (Low) / 2 (Medium) / 3 (High)**.
2. Normalized score = **Sum(Score × Weight) / Sum(Weights)**.
3. Assign the tier from the normalized score:
   - **1.0–1.6** → Tier 1 (Simple) 🔵
   - **1.61–2.3** → Tier 2 (Moderate) 🟠
   - **2.31–3.0** → Tier 3 (Complex) 🔴

| Factor | Weight | Low (1) | Medium (2) | High (3) |
|---|---|---|---|---|
| **Scope** | 0.8 | 1 component | 2–3 components | 4+ components |
| **State Management** | 1.2 | Simple local state | Moderate shared state | Complex global state |
| **Data Flow** | 1.5 | Simple flow | Moderate transformations | Complex pipelines |
| **Business Logic** | 2.5 | Simple rules | Moderate rule complexity | Complex rules, many edge cases |
| **UI Complexity** | 0.5 | Standard widgets | Custom widgets | Complex interactive elements |
| **API Integration** | 1.5 | Simple calls | Multiple interactions | Complex orchestration |
| **Database Changes** | 1.2 | No schema changes | Minor schema changes | Major schema changes |
| **Security Concerns** | 2.0 | Standard security | Moderate needs | Complex requirements |
| **New Technologies** | 1.0 | None | Minor | Major |

**Special considerations** (may justify a higher tier than the raw score): high business/technical
risk, unfamiliar domain, core infrastructure many features build on, user-facing critical
features, regulatory/compliance implications.

## Implementation Medium

Before the design evaluation, declare what the feature's deliverable is **made of**. This is
declared, never inferred, and it is a property of the feature, not of individual artifacts.

| Value | The feature's deliverable is… |
|---|---|
| `code` | Entirely code an interpreter or compiler runs. The default, and correct for most features. |
| `instruction` | Entirely instruction artifacts an **agent** executes — markdown procedures, task definitions, prompts. |
| `mixed` | Both, in one feature — e.g. a procedure plus the scripts it invokes. Common; not an edge case. |

Two rules that keep this honest:

- **The workspace declares first.** `project_metadata.medium` in `project-config.json` is `code`
  or `mixed`; a feature may only declare `instruction` or `mixed` in a workspace that is `mixed`.
  Absent means `code`.
- **Medium is not per-artifact.** Artifacts inherit their feature's medium. A `mixed` feature's
  value is a *composition*, and labelling each file would be a hand-maintained duplicate no
  parser reads.

Medium drives two things downstream: whether the Instruction Design dimension can be `Yes`, and
which terminal design document the feature receives (`New-TDD.ps1 -Medium`).

### Feature granularity for instruction work

The granularity guide's tests pass more than one decomposition of instruction work, so the medium
supplies the deciding rule: **a feature is one independently-invocable instruction entry point plus
every artifact that exists to serve it** — its guides, templates, craft skill, and helper scripts.
A second entry point a user or agent would select independently is a **second feature**. Artifacts
serving several entry points route by the existing shared-utility rule: assign to the entry point
they most closely support, and create a shared-infrastructure feature once they exceed ~3 files /
~300 lines with cross-feature impact.

## Design Requirements Evaluation

As part of the assessment, decide whether the feature needs dedicated **Database**, **API**,
**UI**, and/or **Instruction** design documentation — recorded in the assessment document (the
single source of truth, per PF-PRO-002 / PF-IMP-760) and used to route the corresponding design
tasks. They are evaluated and routed in chain order: DB → API → UI → Instruction.

- **UI Design — Yes** if: new screens/layouts, components outside the existing design system,
  complex interaction/navigation flows, custom visual design (animations, illustrations),
  responsive or platform-specific adaptations, accessibility beyond standard, multi-step forms,
  custom data visualizations. **No** if it only reuses existing documented components, is
  backend-only, or makes minor content updates.
- **API Design — Yes** if: new/modified endpoints, complex request/response structures,
  external-service integration, auth/authorization changes affecting APIs, versioning/compat
  concerns, complex validation or transformation, real-time (WebSocket/SSE). **No** if it only
  uses existing documented APIs or simple CRUD on existing endpoints.
- **Database Design — Yes** if: new tables/collections, schema modifications, complex
  relationships/constraints, indexing strategy, data migration, complex queries/procedures,
  DB-level security, retention policies. **No** if it only reads existing structures or does
  simple CRUD on existing tables.
- **Instruction Design — Yes** if the feature's medium is `instruction` or `mixed` **and** its
  instruction part is more than a single self-evident procedure: multiple instruction artifacts
  that reference each other, a procedure with branching or checkpoints, artifacts an agent must
  execute against a contract (named scripts, parameters, cross-document step references), or a
  procedure whose verification needs designing. **No** if the medium is `code`, or if the
  instruction part is one short artifact whose shape is obvious from the requirement.

Record each as Yes/No with a one-line justification in the assessment's Design Requirements
Evaluation section.

> **The Instruction row is the one that fails silently.** A pure-instruction feature that answers
> No to DB, API and UI falls straight through the design chain to a code-shaped terminal document
> asking for its models and repositories — and nothing errors. If the medium is not `code`, the
> Instruction row deserves a deliberate answer rather than a default No.

## Reassessment during implementation

If actual complexity diverges from the initial assessment, reassess and adjust the tier (the
Documentation Tier Adjustment task owns this process). Add a "Reassessment" section to the
original assessment file with the date, reason, re-scored factors, new normalized score/tier, and
update feature tracking. Watch for these triggers:

| Indicator | Example |
|---|---|
| Scope expansion | A simple settings screen now needs complex preference sync |
| Unforeseen technical complexity | A "simple" API integration needs complex data transformation |
| State-management growth | Local-state feature now needs complex global state |
| New security requirements | Feature now handles more sensitive data than expected |
| Integration complexity | Simple API calls now need orchestration + error handling |
| Performance concerns | Needs optimization strategies not anticipated |
| Many new edge cases | Form validation has far more special cases than expected |
| Architectural impact | Requires changes to core application architecture |

Multiple indicators together are a strong signal to reassess.
