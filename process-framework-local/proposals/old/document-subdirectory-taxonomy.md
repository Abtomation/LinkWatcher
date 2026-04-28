---
id: PF-PRO-026
type: Document
category: General
version: 2.0
created: 2026-04-16
updated: 2026-04-17
extension_scope: PD-id-registry.json, DocumentManagement.psm1, New-Handbook.ps1, PF-TSK-081, PF-TSK-059, PF-TSK-064, feature state template
extension_name: Document Subdirectory Taxonomy
extension_description: Two-layer faceted taxonomy (Diátaxis content types + project topics) for scalable user documentation organization
---

# Document Subdirectory Taxonomy - Framework Extension Concept

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept |
| Created Date | 2026-04-16 |
| Status | Approved |
| Extension Name | Document Subdirectory Taxonomy |
| Extension Type | Modification (multi-component) |
| Author | AI Agent & Human Partner |
| Source IMP | PF-IMP-571 |
| Related State File | [PF-STA-093](../state-tracking/temporary/temp-framework-extension-document-subdirectory-taxonomy-extension.md) |

---

## Purpose & Context

**Brief Description**: Add a two-layer faceted documentation taxonomy to the framework — Layer 1 (L1) adopts the industry-standard Diátaxis content-type classification; Layer 2 (L2) is an optional project-specific topic/domain classification. The framework declares the schema, validates via scripts, and integrates analysis and tracking into existing documentation workflows so that documentation completeness is gap-lessly tracked per feature.

### Extension Overview

The framework's document creation pipeline (`New-StandardProjectDocument` in `DocumentManagement.psm1`) already supports a generic `-Subdirectory` parameter (added by IMP-568). However, there is no:
- Central place to *declare* which subdirectories are valid per document type
- Validation to prevent typos or inconsistent category names
- Guidance on which content type a new document belongs to
- Process for analyzing which document types a feature needs
- Tracking for multi-type documentation completion per feature

This extension closes all of those gaps by establishing a **faceted taxonomy** with two orthogonal classification dimensions:

| Layer | Dimension | Question Answered | Source of Values |
|-------|-----------|-------------------|------------------|
| **L1** | Content type | "What kind of help does the reader need?" | Diátaxis — universal, framework-declared defaults |
| **L2** | Topic/domain | "Which part of the system does this document cover?" | Project-specific, declared per project |

The taxonomy directly drives:
- Directory structure: `handbooks/<L1>/[<L2>/]<doc>.md`
- Content type analysis during documentation planning
- Per-feature tracking of which content types are complete vs. pending

### Industry Basis

The Diátaxis framework (https://diataxis.fr/) is the dominant industry standard for documentation taxonomy, adopted by Django, NumPy, Gatsby, Canonical/Ubuntu, Read the Docs, and hundreds of other projects. It classifies documentation along two axes (learning vs. working, practical vs. theoretical) producing four categories:

- **Tutorials** — learning-oriented guided lessons
- **How-to guides** — task-oriented practical directions
- **Reference** — information-oriented technical facts
- **Explanation** — understanding-oriented conceptual discussion

The two-layer model (content type + topic) follows the faceted-taxonomy pattern from information architecture, where content type answers "what is it?" and topic answers "what is it about?"

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| **Structure Change Task (PF-TSK-014)** | Reorganizes existing framework components | Rearrangement of current elements |
| **Process Improvement Task (PF-TSK-009)** | Makes granular improvements to existing processes | Optimization of current workflows |
| **IMP-568 (-Subdirectory param)** | Generic subdirectory support in document creation | Mechanical plumbing, no validation |
| **Document Subdirectory Taxonomy** *(This Extension)* | Faceted taxonomy: Diátaxis content types + project topics, with analysis and tracking integration | Schema + validation + process + tracking |

## Existing Project Precedents

| Precedent | Where It Lives | What It Does | How It Relates |
|-----------|---------------|--------------|----------------|
| `PD-id-registry.json` `directories` field | `doc/PD-id-registry.json` | Maps named keys to output paths per prefix | Natural home for subdirectory declarations — same registry, new optional fields |
| `New-Handbook.ps1` `ValidateSet` | Script parameter attribute | Hardcodes 5 categories: setup, usage, troubleshooting, configuration, reference | Replaced with config-driven validation |
| `domain-config.json` `document_categories` | `process-framework/domain-config.json` | Declares document *types* (specification, architecture, etc.) | Analogous pattern at a different level — framework doc types vs. user doc content types |
| `-Subdirectory` param in `DocumentManagement.psm1` | `New-StandardProjectDocument` function | Creates subdirectory if passed, no validation | Plumbing layer this extension validates on top of |
| Feature state `Documentation Inventory` table | `feature-implementation-state-template.md` | Tracks per-feature documentation status | Extended to track per-content-type status |

**Key takeaways**: The registry already has the right shape (`directories` per prefix). Adding optional `subdirectories` and `topics` fields follows the established pattern. Validation logic belongs in `New-StandardProjectDocument` (central) rather than individual scripts (distributed). Documentation analysis and tracking integrate into existing feature state files rather than requiring new files.

## Interfaces to Existing Framework

### Task Interfaces

| Existing Task | Interface Type | Description |
|--------------|----------------|-------------|
| PF-TSK-081 (User Documentation Creation) | Modified by extension | Gains Diátaxis analysis step in Preparation phase; creates multiple docs per feature based on analysis; records per-type status |
| PF-TSK-059 (Project Initiation) | Modified by extension | Gains step to declare documentation taxonomy (L1 defaults + optional L2) in `PD-id-registry.json` |
| PF-TSK-064 (Codebase Feature Discovery) | Modified by extension | Gains guidance to classify existing docs by Diátaxis content type during audit |
| PF-TSK-044 (Feature Implementation Planning) | Downstream consumer | Continues to set `❌ Needed` status; PF-TSK-081 now analyzes and may create multiple entries |

### Artifact Interfaces

| Existing Artifact | Relationship | Description |
|------------------|--------------|-------------|
| `doc/PD-id-registry.json` | Updated by extension | New optional `subdirectories` and `topics` fields on `PD-UGD` prefix |
| `DocumentManagement.psm1` | Updated by extension | `New-StandardProjectDocument` gains validation logic |
| `New-Handbook.ps1` | Updated by extension | Replaces hardcoded `ValidateSet`; adds optional `-Topic` parameter |
| `feature-implementation-state-template.md` | Updated by extension | Documentation Inventory gains Content Type column |
| `Update-UserDocumentationState.ps1` | Updated by extension | Accepts `-ContentType` parameter for per-type tracking |

## Modification Details

### Registry Schema Change: `PD-id-registry.json`

Add optional `subdirectories` (L1) and `topics` (L2) fields to any prefix entry. When `subdirectories.values` is present, scripts validate `-Subdirectory`. When `topics.values` is present, scripts validate `-Topic`.

```json
"PD-UGD": {
  "description": "Product Documentation - User Guides",
  "directories": {
    "handbooks": "doc/user/handbooks",
    "default": "handbooks"
  },
  "subdirectories": {
    "description": "L1: Diátaxis content type — the reader's cognitive mode",
    "values": ["tutorials", "how-to", "reference", "explanation"],
    "default": "how-to"
  },
  "topics": {
    "description": "L2: Project-specific topic/domain area — which part of the system the doc covers",
    "values": [],
    "default": null
  },
  "nextAvailable": 9
}
```

**Design decisions**:
- Both `subdirectories` and `topics` are **optional** — prefixes without them accept any value (backward compatible)
- `subdirectories.default` provides the fallback when no L1 category is specified
- `topics.values` empty array means validation is skipped (project hasn't declared L2 yet)
- Path construction: `{directories.handbooks} / {L1} / [{L2}] / {filename}`

### Diátaxis Content Types (L1) — Framework Defaults

| Directory | Diátaxis Category | Question | Example |
|-----------|-------------------|----------|---------|
| `tutorials/` | Tutorials | "Am I learning something new?" | "Your first LinkWatcher project" |
| `how-to/` | How-to guides | "Am I solving a specific problem?" | "How to configure log rotation" |
| `reference/` | Reference | "Am I looking up facts?" | "Complete CLI options reference" |
| `explanation/` | Explanation | "Am I trying to understand why?" | "How LinkWatcher detects file moves" |

### L2 Topics — Project-Specific

The framework does not prescribe L2 values. Each project declares its own topics based on its domain architecture. Typical sources:
- **Feature/module names** (most common for software projects)
- **Product areas** (admin, user, integrations)
- **Resource types** for APIs (users, payments, webhooks)

The framework does prescribe that L2 represents "topic/domain area — which part of the system." Projects should avoid using L2 for orthogonal facets like audience, urgency, or document format (those belong in metadata tags).

### Script Changes

| Existing Script | Current Behavior | Required Change | Backward Compatible? |
|----------------|-----------------|-----------------|---------------------|
| `DocumentManagement.psm1` (`New-StandardProjectDocument`) | Accepts any `-Subdirectory` string | Read `subdirectories.values` and `topics.values` from registry; validate when present; construct path with L1/L2 | Yes — validation only when fields exist |
| `New-Handbook.ps1` | Hardcoded `ValidateSet` on `-Category` | Remove `ValidateSet`; rename `-Category` to `-ContentType` for Diátaxis clarity; add optional `-Topic`; rely on central validation | Mostly — existing callers using `-Category "usage"` still work via param alias |
| `Update-UserDocumentationState.ps1` | Appends row to Documentation Inventory | Accept `-ContentType` parameter; include in row | Yes — new optional param |

### Task Changes

| Task | ID | Change | Priority |
|------|-----|--------|----------|
| **User Documentation Creation** | PF-TSK-081 | New Step 1.5: Diátaxis analysis — evaluate which content types the feature needs using decision matrix. Update Step 6 to pass `-ContentType`. Update state file updates to include Content Type column. | HIGH |
| **Project Initiation** | PF-TSK-059 | Add step to declare documentation taxonomy in PD-id-registry.json with Diátaxis defaults (L1) and empty L2. Project team can customize. | HIGH |
| **Codebase Feature Discovery** | PF-TSK-064 | Add note in existing documentation audit step: classify each found handbook by Diátaxis type for awareness | LOW |

### Template Changes

| Template | Change |
|----------|--------|
| `feature-implementation-state-template.md` | Add **Content Type** column to `### User Documentation` table in Documentation Inventory |

### Diátaxis Decision Matrix (for PF-TSK-081)

This matrix goes into the task definition as guidance:

| Question about the feature/change | If Yes → Likely Needs |
|---|---|
| Complex enough that newcomers need a guided walk-through? | `tutorials` |
| Users will need practical steps to accomplish tasks? | `how-to` |
| Has settings, options, API surface, or CLI details to look up? | `reference` |
| Has architecture/design concepts that are non-obvious? | `explanation` |

A feature can need 0 (internal only), 1, or multiple content types. The analysis is per-feature and produces N entries in the feature state file.

## Success Criteria

### Registry + Scripts
- [ ] `PD-id-registry.json` has `subdirectories` (Diátaxis values) and `topics` (empty) on `PD-UGD`
- [ ] `New-StandardProjectDocument` validates `-Subdirectory` against registry when field exists
- [ ] `New-StandardProjectDocument` passes through any `-Subdirectory` value when field absent
- [ ] `New-Handbook.ps1 -ContentType "invalid"` produces clear error
- [ ] `New-Handbook.ps1 -ContentType "how-to" -Topic "my-topic" -WhatIf` succeeds when both are declared

### Process + Tracking
- [ ] PF-TSK-081 has Diátaxis analysis step with decision matrix
- [ ] Feature state template has Content Type column in Documentation Inventory
- [ ] Update-UserDocumentationState.ps1 accepts `-ContentType`
- [ ] project-initiation-task has step to declare taxonomy

### Integration
- [ ] Existing scripts using `-Subdirectory` without registry fields continue to work
- [ ] PD-documentation-map.md reflects any schema changes
- [ ] All modified scripts tested with `-WhatIf`

## Explicitly Deferred

- **Migration of existing 8 LinkWatcher handbooks** into L1 subdirectories — premature at current scale. Triggered as Structure Change (PF-TSK-014) when handbook count justifies it (~15+).
- **L2 topic declarations for LinkWatcher** — will remain empty. Framework schema supports it; this project doesn't populate it yet.

---

*This concept document was created using the Framework Extension Concept Modification Template as part of the Framework Extension Task (PF-TSK-048). Source: PF-IMP-571.*
