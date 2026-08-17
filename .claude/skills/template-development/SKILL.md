---
name: template-development
description: >-
  Craft for developing and maintaining framework templates well — the judgment half of the
  template-creation work delegated by New Task Creation (PF-TSK-001), Framework Extension
  (PF-TSK-026), and Structure Change (PF-TSK-014). Covers the template design principles
  (clarity, embedded guidance, consistency, flexibility, evolution-readiness), the standard
  template components (metadata, instructional comments, placeholders, required-vs-optional
  sections, extension points), the development process from needs analysis through testing,
  the two-phase New-Template.ps1 creation model, the copyable-instance template archetype,
  and maintenance conventions (versioning, update triggers, migration strategy). Activated
  from PF-TSK-001's and PF-TSK-026's Check-Recommended-Skills steps (via recommended_skills);
  also consulted inline wherever a framework template is created or updated (e.g. Structure
  Change delegation). Not a document-instance customization skill (each template's own
  customization craft owns that) and not a creation-script skill (see creation-script-development).
user-invocable: false
---

# Template Development Craft

This skill owns the **craft** of developing and maintaining framework templates — the design
judgment that makes a template consistent, self-explanatory, and durable. The **creating
task** owns everything else: when a template is needed, checkpoints, ID/registry integrity,
and completion. Primary hosts: **New Task Creation (PF-TSK-001)** (task-specific templates),
**Framework Extension (PF-TSK-026)** (extension templates), and **Structure Change
(PF-TSK-014)** (which delegates template creation/updates here rather than doing them inline).

> **Division of labor.** The task owns process; this skill owns template-design judgment.
> Templates are always scaffolded with `process-framework/scripts/file-creation/support/New-Template.ps1`
> — never hand-created — so IDs and registry state stay correct.

## Design principles

1. **Clarity over completeness** — understandable at a glance; instructions inside the
   template; placeholder text that says what replaces it.
2. **Guidance within** — embed rationale and examples as comments; link relevant resources.
3. **Consistency across templates** — shared naming conventions, structure, and formatting
   with related templates.
4. **Flexibility within constraints** — allow necessary variation while keeping the core
   structure; mark required vs. optional explicitly; support extension without breaking the
   pattern.
5. **Evolution-ready** — versioned, with documented update history and extension points for
   anticipated needs.

## Standard components

- **Metadata frontmatter** — two distinct things. The template's **own** identity (`id: PF-TEM-NNN` /
  `type: Process Framework` / `category: Template` / `version` / `created` / `updated` / `description`),
  and the `creates_document_type` / `creates_document_category` pair describing the documents it
  **generates**. The shared writer reads that pair when it assembles a generated document's frontmatter —
  declare both, or the writer warns and stamps the fallback `type: Document` /
  `category: General`. Keep `creates_document_type` to the artifact's tree (Process Framework |
  Product Documentation | Testing) and `creates_document_category` to its kind, matching what sibling
  templates on the same ID prefix declare. ⚠️ The ID registries name the same pair **transposed** —
  a registry prefix entry stores `category` = tree and `type` = kind — so never copy a registry
  entry's values straight into frontmatter declarations. The template's own `type` / `category` describe the template
  file and are never copied into the output.
- **Instructional comments** — `<!-- ... -->` blocks explaining how to use a section; removed
  when the template is instantiated.
- **Placeholder text** — `[Descriptive placeholder that indicates what content goes here]`.
- **Shared-writer replacement tokens** — the shared writer substitutes `[DOCUMENT_ID]`,
  `[DOCUMENT_NAME]` / `[Document Name]`, `[DATE]`, and `[TIMESTAMP]` in the template **body**
  (frontmatter is regenerated wholesale, not token-replaced; replacements the creation script
  passes win over these on key collision). A body that displays its own document ID must use
  `[DOCUMENT_ID]` — the ID is allocated inside the writer at creation time, so the creation
  script cannot pass it as a replacement, and a hand-written `PD-XXX-NNN`-style placeholder
  ships unreplaced into every created document. Live example: the `# [DOCUMENT_ID]: ...` H1 in
  [technical-findings-template.md](../../../process-framework/templates/01-planning/technical-findings-template.md).
- **Required vs. optional sections** — mark optional headings, e.g.
  `## Optional Section Title (if applicable)`.
- **Extension points** — `## Custom Sections (as needed)` with a comment inviting additions.

## Development process

1. **Needs analysis** — identify the document type, collect existing examples, extract common
   patterns and variations, and determine what information every instance must carry.
2. **Structure design** — outline sections, mark required/optional, fix order and hierarchy,
   define metadata requirements.
3. **Content development** — clear placeholders, instructional comments, examples, resource
   links.
4. **Testing** — create sample documents; probe with different use cases; refine unclear
   areas. Test for **usability** (can a user instantiate it without confusion?),
   **completeness** (all necessary sections, all valid variations accommodated, required
   fields marked?), and **consistency** (conventions and terminology match sibling templates?).
5. **Documentation** — record the template's purpose and usage; keep worked examples;
   establish who owns changes.

### Two-phase creation with New-Template.ps1

- **Phase A — structure generation**: `process-framework/scripts/file-creation/support/New-Template.ps1`
  assigns the template ID, generates the standardized skeleton with placeholder content, and
  updates the ID registry. 🚨 The output is a **starting point only** — not functional until
  Phase B.
- **Phase B — content customization**: replace ALL placeholder content with specific,
  actionable guidance, customize the metadata for the document type, develop full section
  content per the design principles, add instructional comments and examples, test by
  creating sample documents, then update references so consumers can find the template.

### Copyable-instance templates

Most templates follow the two-phase model above. A second archetype — the **copyable-instance
template** — has a *body that is the instance structure itself*, copied verbatim into the
target document (by a creation script or by hand). The New-Template.ps1 skeleton is discarded
wholesale: it exists only to register the ID. Use this archetype when the template's value is
a ready-to-paste block (a tracking-table row, a state-file entry, a proposal body) rather
than a section outline to expand. Examples:
[pending-migration-entry-template.md](../../../process-framework/templates/support/pending-migration-entry-template.md)
and the framework-extension concept templates.

Authoring rules for the archetype:

- **Body = exact instance** — the literal structure the consumer pastes, with
  `[bracketed placeholders]` for per-instance values; not a "describe your X here" outline.
- **Drop the skeleton** — after the ID is assigned, replace the generated scaffold entirely;
  keep only the metadata the consumer reads.
- **Match the consumer** — if a creation script copies the body, verify the structure against
  what the script actually substitutes, not by eye alone.

## Maintenance

- **Version control** — semantic versioning (MAJOR.MINOR.PATCH); document changes in the
  update history; maintain backward compatibility where possible and communicate breaking
  changes clearly.
- **Update triggers** — user feedback indicating confusion, new requirements for the document
  type, inconsistencies discovered across instances, or a change in the underlying process.
- **Migration strategy** — plan how existing instances migrate to a new template version;
  script the migration when possible, otherwise provide clear manual guidance and realistic
  timelines. See [Migration Best Practices](../../../process-framework/guides/support/migration-best-practices.md).

## Related craft

- [`creation-script-development`](../creation-script-development/SKILL.md) — the scripts that
  instantiate templates; consult when the template feeds a creation script (placeholder and
  `creates_*` metadata contracts).
- [`state-file-customization`](../state-file-customization/SKILL.md) — customizing state
  tracking files instantiated from the state-file templates.
- [`task-creation`](../task-creation/SKILL.md) — task-definition authoring (task files come
  from `task-template.md` via New-Task.ps1, not New-Template.ps1).
- [Template Base Template](../../../process-framework/templates/support/template-base-template.md) —
  the base structure New-Template.ps1 scaffolds from.
- [Documentation Structure Guide](../../../process-framework/guides/framework/documentation-structure-guide.md) —
  where templates live and how they are organized.
