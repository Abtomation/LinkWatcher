---
name: architecture-decision
description: >-
  Craft for customizing an Architecture Decision Record (PD-ADR) well — how to document an
  architectural decision's context, the decision itself, impact assessment, structured
  alternatives, and consequences. Craft home for ADR creation across the framework: activated from
  the System Architecture Review (PF-TSK-019) and Retrospective Documentation Creation
  (PF-TSK-066) Check-Recommended-Skills steps, and referenced at other tasks' conditional
  ADR-trigger moments. Not an architecture-analysis, TDD-authoring, or implementation skill.
user-invocable: false
---

# Architecture Decision Craft

This skill owns the **craft** of customizing an Architecture Decision Record — *how* to fill a
PD-ADR document well. Its bound hosts are **System Architecture Review (PF-TSK-019)** and
**Retrospective Documentation Creation (PF-TSK-066)**, which activate it at their
Check-Recommended-Skills steps; other tasks (Bug Fixing, Core Logic Implementation, Code
Refactoring, Foundation Feature Implementation) reference it at their conditional **ADR-trigger**
moments. The activating task owns everything else: task selection, checkpoints, document creation
via script, state-file updates, and the feedback form.

> **Division of labor.** The task owns process; this skill owns craft. Do **not** run checkpoints,
> create the document, or write state from this skill — those stay in the task. This skill drives
> the ADR content customization once the task decides an ADR is warranted.

## Reference-don't-bundle: framework scripts this craft uses

This skill bundles **no executables**. The **task** creates the document with
`process-framework/scripts/file-creation/02-design/New-ArchitectureDecision.ps1` — always via the
script, never hand-authored, so the PD-ADR id, metadata, and structure stay framework-consistent.

## When an ADR is warranted

Create an ADR for any **discrete architectural decision worth recording**: a technology or pattern
choice with trade-offs, a design decision that affects system structure or behavior, a decision
future reviews will want the rationale for. Not restricted to foundation features — any feature
whose implementation embodies such a decision qualifies. One ADR per focused decision; bundle
multiple decisions only when they are tightly coupled and cannot be superseded separately.

## Document structure and interdependencies

**Required**: Title (clear decision name) · Status (Proposed / Accepted / Deprecated / Superseded)
· Context · Decision · Consequences. **Important**: Impact Assessment · Alternatives · References.

**Context** justifies the **Decision**; the Decision drives **Consequences** and the **Impact
Assessment**; **Alternatives** support the Decision with comparative evidence; **Status** tells the
reader how to weight everything; **References** back the reasoning.

## Customization decision points

- **Scope** — one focused decision per ADR (default) vs. multiple tightly-coupled decisions.
  Favor separability: can each decision be superseded on its own later?
- **Context depth** — high-level for well-understood problems with stakeholder alignment;
  comprehensive when the decision needs detailed justification or the audience is unfamiliar.
- **Alternatives depth** — brief mention for obvious decisions with a clear superior option;
  detailed comparative analysis for real trade-offs or likely future reconsideration.
- **Consequences specificity** — general categories when impacts are uncertain (early-stage);
  specific measurable impacts for critical decisions with concrete metrics.
- **Status progression** — conservative (Proposed → Accepted → Implemented) for high-risk
  decisions; rapid for low-risk or urgent ones.

## Section content craft

- **Context**: the problem statement, constraints, and the triggering event — enough that a new
  reader understands *why* a decision was needed.
- **Decision**: specific and actionable — "Use X for state management", never "improve state
  management". Answer "what exactly will be done", not "what problem needs solving". Include
  implementation constraints or guidelines.
- **Impact Assessment**: technical risk (Low/Medium/High), implementation effort, affected
  components, migration required (yes/no), performance impact, security implications.
- **Alternatives**: for each one considered — name, specific pros, specific cons, and the concrete
  rejection rationale grounded in project constraints (not superficial dismissals). Document all
  viable alternatives, not just obvious ones; quantify comparisons where possible.
- **Consequences**: both positive and negative, short- and long-term, consistent with the Impact
  Assessment.
- **References**: supporting documentation, related ADRs/assessments, standards that influenced
  the decision.

**Retrospective mode** (documenting an already-implemented decision, e.g. during onboarding):
document the pattern the code embodies and **mark unknowns clearly** — alternatives that may have
been considered and unrecoverable rationale are labeled as such, not invented.

## Self-review checklist

- [ ] Title names the decision; Status accurate
- [ ] Context explains problem + motivation; Decision specific, actionable, unambiguous
- [ ] Impact Assessment covers risk / effort / components / migration / performance / security
- [ ] Every considered alternative has structured pros/cons + a real rejection reason
- [ ] Consequences include both positive and negative impacts
- [ ] No conflict with existing ADRs; related ADRs and assessments cross-referenced

Worked examples (state-management selection; database migration strategy):
[references/worked-examples.md](references/worked-examples.md).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Decision statement vague / open to interpretation | Problem restated instead of solution | Rewrite as a specific action ("Use X…"); add implementation constraints; confirm it answers "what exactly will be done" |
| Alternatives shallow, rejections superficial | Insufficient research or rushed decision | Research each alternative's pros/cons and implementation implications; ground rejections in project constraints; quantify where possible |
