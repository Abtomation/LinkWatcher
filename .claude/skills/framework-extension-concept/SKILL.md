---
name: framework-extension-concept
description: >-
  Craft for customizing a Framework Extension Concept document well — the "how to fill it"
  half of the framework's Framework Extension task (PF-TSK-026). Covers template-variant
  selection for New-FrameworkExtensionConcept.ps1 (-Type Creation/Modification/Hybrid,
  -Minimal, -Pattern), section-by-section customization judgment (Extension Type pruning, the
  Modification-Focused completeness tables, Existing Project Precedents research, Interfaces
  to Existing Framework mapping, scope and implementation-strategy sections), the
  adapt-don't-copy discipline for industry taxonomies, the non-standard concept shapes
  (not-adopted evaluation record with re-open conditions; one-time-migration reframe), and a
  concept validation checklist;
  worked examples (including a fully populated Modification-type concept) and troubleshooting
  in a reference. Activated from the Framework Extension task's Check-Recommended-Skills step
  (via recommended_skills); not an impact-analysis, pilot-decision, or implementation skill —
  those stay with the task's own steps and checkpoints.
user-invocable: false
---

# Framework Extension Concept Craft

This skill owns the **craft** of turning the structural template emitted by
`New-FrameworkExtensionConcept.ps1` into a comprehensive, reviewable concept document. The
**task (PF-TSK-026 Framework Extension)** owns everything else: pre-concept analysis, the
concept-direction and full-package checkpoints, impact analysis, the pilot-vs-full-rollout
decision, state tracking, and the multi-session implementation phases.

> **Division of labor.** The task owns process; this skill owns concept-document judgment.
> The script creates only a TEMPLATE — every bracketed placeholder and guidance text must be
> replaced; approval outcomes stay with the human partner at the task's checkpoints.

## Template-variant selection (decide before running the script)

- **`-Type Creation`** — entirely new artifacts (new tasks, templates, scripts). Template
  focuses on new-artifact definitions and multi-session plans.
- **`-Type Modification`** — changes to existing artifacts only (steps added to tasks,
  template/guide updates). Template centers on the three completeness tables below.
- **`-Type Hybrid`** — both; full template with all sections (also the base template).
- **`-Minimal`** — small-scope creation extension (single artifact): slim template with just
  Purpose, Precedents, Artifact Definition, Open Questions, Approval.
- **`-Pattern`** — cross-cutting convention/architecture touching many artifacts with no
  single new task: drops the per-task numbered-step skeleton and fixed multi-session plan for
  a free-form Core Pattern section and an adaptive (pilot-aware) roadmap; `-Type` then only
  stamps the metadata.

## Customization sequence

1. **Content replacement** — replace every `[bracketed placeholder]`, delete template
   guidance text, customize headings, prune sections the selected type marks for removal.
2. **Content development** — expand brief descriptions, add concrete technical detail and
   usage examples, define measurable success criteria.
3. **Integration planning** — map dependencies on existing components, identify integration
   points, plan the multi-session roadmap with human review checkpoints at milestones.

> **⚠️ Adaptation discipline**: define categories, levels, and terminology that fit the
> framework's architecture. Study the framework's existing patterns AND established industry
> taxonomies (the task's pre-concept analysis step), then adapt — neither copy industry
> terminology blindly nor reinvent what proven external models already solve.

## Section-by-section judgment

- **Extension Type** — select the type, replace the placeholder, and **delete** the blocks
  the selection obsoletes (Creation: drop the Modification-Focused block; Modification: drop
  "New Artifacts Created" / "New Tasks Required" / "New Permanent State Files Required";
  Hybrid: keep all).
- **Modification-Focused tables** *(Modification/Hybrid only)* — the completeness contract:
  every file that *reads* a modified artifact must be found before implementation, or
  references silently rot.
  - **State Tracking Audit**: every state file the extension modifies, with the specific
    field/section change. Grep for state files referencing the changed artifacts.
  - **Guide Update Inventory**: every guide, task, and doc referencing the modified
    artifacts. Grep the file paths and task IDs involved.
  - **Automation Integration Strategy**: every script that reads or writes the modified
    artifacts, the required change, and backward compatibility.
  - Fill the **Discovery method** and **Cross-reference impact** rows — reviewers verify you
    swept for readers rather than guessed. For an id/string migration, sweep the whole repo
    from its root — the `test/` tree included, since test fixtures embed literal ids — and
    classify each hit: update, preserve as historical record, or leave as synthetic fixture.
- **Existing Project Precedents** — research **before** designing the Core Process Overview
  or artifact lists: search for existing workflows/patterns solving similar problems, fill
  the table with concrete file paths (never generic), verify each precedent by reading it,
  and write Key Takeaways (what to reuse, what gaps exist, what is genuinely new).
- **Interfaces to Existing Framework** — map every touchpoint: task interfaces (direction —
  upstream input, downstream consumer, modified-by), state-file interfaces (specific fields/
  sections), artifact interfaces (templates, guides, tracking files). Verify with grep for
  task IDs, paths, and state-file names. An unlisted touchpoint is a missed one — err toward
  over-documenting.
- **Executive Summary** — extension name, 1–2 sentence description, specific benefits,
  planned implementation approach. No placeholders left.
- **Extension Overview / Scope Definition** — actual components and capabilities, target
  users, integration points, and explicit **exclusions** (what the extension will NOT do).
- **Implementation Strategy** — real planned sessions with per-phase deliverables,
  inter-component dependencies, and human review checkpoints.

## Two non-standard concept shapes

- **Evaluation record (concept ends "not adopted")** — a declined concept is still authored
  in full: it becomes the evidence record the task archives and cites as the IMP's rejection
  reason. Repurpose the proposal-shaped sections: **Implementation Roadmap → Disposition**
  (each evaluated candidate's outcome on the evidence), **Pilot vs. Full Rollout → N/A**,
  **Success Criteria → verification-quality criteria** (what evidence would have to change),
  and add a **Re-Open Conditions** section of falsifiable, testable triggers — "if the shared
  substrate stops being shared", "if project count exceeds N" — never "revisit later". Worked
  example: appdev's framework-tree-partition evaluation (PF-PRO-057).
- **One-time migration / namespace change (Modification type)** — "When to Use This
  Extension" and "Example Use Cases" assume a recurring capability; for an extension that
  runs once, reframe them to the durable capability the migration leaves behind, or prune
  them where nothing durable remains.

## Validation checklist (before presenting for review)

- **Completeness**: no `[brackets]` or guidance text left; every section specific and
  actionable; extension name consistent throughout.
- **Technical accuracy**: component list complete and realistic; integration points
  identified; dependencies mapped; timeline feasible.
- **Framework alignment**: aligns with framework principles; naming follows framework
  standards; integration respects existing architecture; success criteria measurable.

## Reference index

- [references/worked-examples.md](references/worked-examples.md) — before/after customization
  examples (Creation-type snippets and a fully populated Modification-type concept with all
  three completeness tables) plus troubleshooting (scope too broad, review rejection,
  multi-session stalls, integration conflicts). Load when you want a pattern to imitate or a
  concept runs into friction.
- [references/edge-cases.md](references/edge-cases.md) — consult-on-stumble record for the
  Framework Extension task (directive-granted concept-direction approval; out-of-workspace
  work items as drafted-text-for-owner deliverables). Consult on an error, surprise, or
  ambiguous fork at any task step; maintained per the workspace Standing Orders.
