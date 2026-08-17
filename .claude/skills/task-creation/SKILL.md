---
name: task-creation
description: >-
  Craft for creating and improving framework task definitions well — the "how to fill it" half
  of the framework's New Task Creation Process (PF-TSK-001). Covers the two-phase creation
  model (script-generated meta-template → agent customization), section-by-section
  customization judgment (Purpose, AI Agent Role, Context Requirements priority bands,
  Process phases, Outputs, State Tracking, checklists, Next Tasks transitions), the
  generic-and-reusable standard, lean-operative-steps routing, dependency management, the
  smart-defaults script-invocation documentation pattern, and improvement/structure-evaluation
  criteria for existing tasks; a bundled reference holds the PF-PRO-042 task-metadata schema
  (frontmatter fields, per-category rules, authored metadata sections). Activated from the New
  Task Creation task's Check-Recommended-Skills step (via recommended_skills); the metadata
  schema reference is also consulted wherever task frontmatter is edited. Not a
  task-selection, workflow-routing, or product-feature skill.
user-invocable: false
---

# Task Creation Craft

This skill owns the **craft** of creating and improving task definitions — the judgment that
turns a script-generated meta-template into a functional, consistent task. The **task
(PF-TSK-001 New Task Creation Process)** owns everything else: scope assessment and mode
selection, checkpoints, session sequencing, metadata-projection regeneration, the Framework
Evaluation gate, and the feedback form.

> **Division of labor.** The task owns process; this skill owns customization judgment.
> Nothing here overrides a checkpoint — mode selection and draft approval stay with the human
> partner at the task's checkpoints.

## The two-phase model (hold this frame throughout)

Creation scripts (`New-Task.ps1`, `New-Template.ps1`, `New-Guide.ps1`) generate **structural
meta-templates** — correct IDs, metadata, placeholder sections. They do **not** create
ready-to-use content; every placeholder section must be replaced with task-specific content
(the task's customize-content step). Never create a task file manually — script creation is
mandatory for ID-sequence and tracking integrity.

## Section-by-section customization

Model new content on live task files in the same phase directory — they beat any synthetic
example. Per section:

- **Purpose & Context** — 1–2 sentences: what the task accomplishes and its role in the
  workflow. No process detail here.
- **AI Agent Role** — four lines (`Role` / `Mindset` / `Focus Areas` / `Communication Style`),
  each 1 line max. Pick an established professional role matching the task's primary expertise
  (Senior Software Engineer, Software Architect, Debugging Specialist, Code Quality Auditor,
  Product Analyst, Technical Lead, DevOps Engineer, QA Engineer, Business Analyst, …). The
  role tunes mindset and communication, not permissions.
- **Context Requirements** — three priority bands, each entry a real link plus a one-line
  reason: **Critical (Must Read)** = must be in context before work starts; **Important (Load
  If Space)** = valuable, deferrable; **Reference Only (Access When Needed)** = consulted for
  specific operations (state updates, registries).
- **Process** — Preparation → Execution → Finalization, numbered steps in imperative voice.
  Include runnable command examples for automation steps (per the invocation-documentation
  pattern below) and mark decision points and `🚨 CHECKPOINT`s explicitly. Where a step's
  success isn't self-evident from its action, state the observable expected result so the
  executing agent can self-verify before moving on (per-step validation — the same
  "Expected Result" shape the framework's guide template uses).
- **Outputs** — bold output names, exact file paths including subdirectories, and a detailed
  description each. Paths must match the ID registry's directory mappings for the artifact
  type.
- **State Tracking** — name each state file the task updates and exactly what changes
  (status value, row, section). *Design prompt for multi-session tasks*: if the task has both
  transient (per-session) and durable (cross-session) state, design distinct artifacts — a
  durable backlog/log outside the temp dir plus a per-session temp state archived at session
  end. Conflating them loses continuity or persists noise forever.
- **Task Completion Checklist** — specific verification items: output checks, state-file
  checks, feedback form. Customize per task; never leave template boilerplate.
- **File Operations & Next Tasks transition subsections** — authored metadata consumed by the
  generators; see [references/task-metadata-schema.md](references/task-metadata-schema.md)
  before filling frontmatter or either section.
- **Related Resources** — background material only. A lookup table or reference consulted at a
  specific step is linked **at that step** ("per [table X]"), not here — links in the
  execution path get followed; bottom-of-file lists don't.
- **Cyclical tasks additionally** — Cycle Frequency, Trigger Events, Metrics and Evaluation,
  Continuous Improvement sections.

## Craft standards

- **Generic and reusable** — use category references and examples ("business types: B2B, B2C,
  SaaS"), never project-specific details; placeholders in commands. The task ships to every
  project.
- **Lean operative steps** — steps carry the common path. Route conditional, situational, or
  edge-case guidance (entry-mode exceptions, shape-specific safeguards, gate rationale) to the
  task's companion reference or craft skill; additive growth in steps is what makes them long
  enough to get skipped. Prefer rewriting a step to absorb a small exception; route larger
  conditional material out. This is *not* the task-usage-guide anti-pattern — a companion
  holding edge-case detail is correct; one re-narrating the operative workflow is not.
- **New tasks start edge-file-less (PF-PRO-059)** — never author per-incident conditionals or
  rare-situation cautions into the task body or a skill's main flow, and never pre-create an
  empty edge-case file (the execution protocol's consult trigger keys on "if one exists").
  When the first real stumble produces an entry, it lands in the lazily-created edge-case
  file — `references/edge-cases.md` in the owning craft skill, or an ID'd PF-GDE
  `<task-name>-edge-cases-guide.md` via `New-Guide.ps1` where no skill exists — which the
  owning task/skill then names in its reference index.
- **Specific and actionable** — action verbs, imperative language, concrete instructions over
  general guidance; anticipate questions in place.
- **Cite steps by role from outside the file** — a reference to a task's step from any other
  artifact (another task, a guide, a script message or comment, CLAUDE.md, authored metadata
  sections) names the step's role ("the recommended-skills step", "the draft-review
  checkpoint", "at registration"), matching the step's bolded title where one exists; only
  references within the same task file use step numbers. Externally cited numbers become
  load-bearing and push authors into letter-suffix insertions (0a/13b) to dodge renumbering —
  role-based citations keep renumbering a local edit. Convert legacy number citations
  opportunistically when editing a file that carries one.
- **Dependency honesty** — list every file, script, and component the task depends on and
  confirm each exists. A missing dependency gets a clearly marked placeholder plus a
  `⚠️ DEPENDENCY NOTE` callout naming what must be implemented, and an IMP filed for the gap.
  Never reference a non-existent component silently.
- **Draft-review presentation** — at the task's draft-review checkpoint, present the
  customized definition with a structured feedback request (usefulness / clarity / efficiency
  on a 1–5 scale plus open suggestions), and fold the response back into the draft before
  proceeding.

## Documenting script invocations: smart defaults

When a script has smart-defaulted parameters (auto-derived or sensible fallbacks), foreground
the **minimal invocation** — only parameters carrying decision content at the call site — and
relegate explicit overrides to an **"Advanced override"** callout. Exposed auto-defaults teach
copy-paste boilerplate and go stale when the default changes. When a script gains a new smart
default, sweep the three typical stale-exposure sites: the task definition's example block,
the usage guide's invocation patterns, and the script's own SYNOPSIS/EXAMPLE help.

## Improving existing tasks

Focus passes, in order of leverage:

1. **Consistency** — current template format, all required sections present, metadata correct.
2. **Content** — clarity, missing detail or context, outdated information, vaguer steps made
   specific.
3. **Cross-references** — links to other tasks resolve, state-tracking references accurate,
   input/output paths exist.
4. **Usability** — examples where helpful, troubleshooting for common issues, visuals for
   complex flows.
5. **Feedback integration** — read the task's feedback forms; fix the reported pain points.

## Evaluating the overall task structure

When assessing the catalog rather than one task: **completeness** (lifecycle gaps needing new
tasks), **clarity** (unambiguous routing, well-defined boundaries, intuitive names),
**efficiency** (no duplicated effort, right granularity, logical flow), **adaptability**
(accommodates new approaches, scales with the project).

## Reference index

- [references/task-metadata-schema.md](references/task-metadata-schema.md) — the PF-PRO-042
  task-metadata contract: frontmatter fields with per-category required/optional rules, the
  File Operations table spec, the Next Tasks transition subsections, and the
  generated-projection rules (what never gets hand-edited). Load whenever filling or editing
  task frontmatter, File Operations, or Next Tasks subsections — in any task file, not only
  new ones.
