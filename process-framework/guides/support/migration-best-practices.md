---
id: PF-GDE-003
type: Process Framework
category: Guide
version: 1.1
created: 2025-06-07
updated: 2026-06-16
related_task: PF-TSK-014
description: "Best practices for migrating documentation and framework components"
---

# Migration Best Practices

## Purpose

This guide provides best practices for migrating content between different document structures, formats, or systems in the project. It focuses on maintaining content integrity while evolving documentation structures.

## Migration Planning

### 1. Assessment

- Inventory all content to be migrated
- Classify content by type, complexity, and importance
- Identify content owners and stakeholders
- Evaluate the gap between source and target structures

### 2. Strategy Selection

- **Big Bang**: Migrate everything at once
  - _Best for_: Smaller document sets, critical interdependencies
  - _Challenges_: Higher risk, more intensive effort
- **Phased**: Migrate in planned stages
  - _Best for_: Larger document sets, multiple document types
  - _Challenges_: Managing mixed states, cross-referencing
- **Parallel Run**: Maintain both old and new simultaneously during transition
  - _Best for_: Critical documentation, high-risk changes
  - _Challenges_: Duplication of effort, synchronization issues

### 3. Planning

- Create a detailed migration plan
- Establish a realistic timeline
- Define clear success criteria
- Identify dependencies and critical paths
- Plan for contingencies and rollbacks

## Migration Preparation

### 1. Backup

- Create comprehensive backups of all content
- Verify backup integrity
- Document the backup location and restoration process
- Maintain backups until migration is fully validated

### 2. Mapping

- Create detailed mapping between source and target structures
- Document transformation rules for each content element
- Identify content that needs special handling
- Create templates for the target structure

### 3. Tools and Automation

- Develop scripts for automating repetitive tasks
- Create validation tools to check migration results
- Set up monitoring for the migration process
- Test tools thoroughly before using on production content

### 4. Training

- Train team members on the new structure
- Provide guidance on manual migration steps
- Establish clear communication channels
- Create reference materials for common questions

## Migration Execution

### 1. Pilot Testing

- Start with a small, representative sample
- Validate the migration process
- Refine the process based on results
- Document lessons learned

### 2. Systematic Execution

- Follow the migration plan
- Track progress using clear metrics
- Document deviations from the plan
- Maintain detailed logs of all actions

### 3. Quality Control

- Validate migrated content against quality criteria
- Check for broken links and references
- Verify content integrity and formatting
- Ensure metadata is correctly transferred

### 4. Issue Management

- Establish a clear process for reporting issues
- Prioritize issues based on impact
- Document workarounds for known issues
- Update the migration plan as needed

## Post-Migration Activities

### 1. Verification

- Conduct thorough verification of migrated content
- Check cross-references and links
- Verify functionality of any embedded code or scripts
- Validate against the original success criteria

### 2. Cleanup

- Remove or archive temporary migration artifacts
- Update references to the new structure
- Document the final state of the migration
- Remove duplicate or obsolete content

### 3. Documentation

- Update documentation to reflect the new structure
- Document any changes to workflows or processes
- Create guides for working with the new structure
- Archive migration documentation for future reference

### 4. Feedback Collection

- Collect feedback from users on the new structure
- Identify areas for improvement
- Document lessons learned
- Plan for future refinements

## Common Migration Challenges

### Content Transformation Challenges

- **Structure Mismatch**: When target structure doesn't accommodate source content
  - _Solution_: Create transition mappings or adapt the target structure
- **Format Conversion**: Converting between different markup formats
  - _Solution_: Use proven conversion tools, verify output quality
- **Link Integrity**: Maintaining valid links after restructuring
  - _Solution_: Use link maps, automate link updates, verify all links

### Process Challenges

- **Scope Creep**: Adding unplanned changes during migration
  - _Solution_: Strict change management, separate enhancement requests
- **Timeline Pressure**: Unrealistic deadlines
  - _Solution_: Prioritize critical content, consider phased approach
- **Resource Constraints**: Limited personnel or tools
  - _Solution_: Automation, prioritization, external assistance

### Organizational Challenges

- **Resistance to Change**: Team reluctance to adopt new structures
  - _Solution_: Clear communication, training, demonstrate benefits
- **Knowledge Gaps**: Team unfamiliar with new structures
  - _Solution_: Documentation, examples, mentoring
- **Coordination Issues**: Multiple teams working on migration
  - _Solution_: Clear roles, regular sync meetings, shared tracking

## Migration Patterns

### Content-Preserving Patterns

- **Like-for-Like**: Minimal structural changes, mostly reformatting
- **Section Reorganization**: Same content, different organization
- **Metadata Enhancement**: Adding or refining metadata

### Content-Transforming Patterns

- **Consolidation**: Combining multiple documents into one
- **Splitting**: Dividing one document into multiple
- **Abstraction**: Moving from specific to more general content
- **Specification**: Moving from general to more specific content

### Special Cases

- **Deprecation**: Marking content as obsolete
- **Archiving**: Moving content to long-term storage. For archiving features from active tracking, follow this checklist:
  1. Audit the feature's cross-reference footprint (grep for feature ID across the project)
  2. Move feature state file to the archive directory (e.g., `features/archive/`)
  3. Update feature-tracking.md: change status to "🗄️ Archived" with rationale and date
  4. Update or archive related design documents (FDDs, TDDs, ADRs, test specs) — add archive notices pointing to replacement docs
  5. Regenerate the affected documentation map(s) so they reflect the archived/moved artifacts — all three are generated, DO-NOT-EDIT projections (PF-PRO-037 / PF-PRO-050), never hand-edited: `Build-DocumentationMap.ps1` for process-framework artifacts (tasks, guides, templates), `… -Tree PD` for product artifacts (TDDs, FDDs, ADRs, validation reports), `… -Tree TE` for test artifacts (test specs, audit reports). A document moved into an `archive/` or `old/` subdir drops off the map — those subtrees are pruned from all three trees (PF-IMP-1376); a document moved elsewhere inside an indexed subtree re-appears under its new path on regeneration, and one moved out of every indexed subtree also drops off (generated maps carry no ~~strikethrough~~ tombstones — the archive notice lives in the artifact and the replacement docs instead)
  6. Triage cross-references: update references that should point to replacement content, leave historical references as-is
  7. Run `Validate-StateTracking.ps1` to confirm no broken links remain
- **Regeneration**: Recreating content from source material — for the specific case of converting a hand-maintained aggregate into a generated projection, see [Converting a Hand-Maintained Aggregate into a Generated Artifact](#converting-a-hand-maintained-aggregate-into-a-generated-artifact) below
- **Translation**: Converting between languages or terminologies

### Converting a Hand-Maintained Aggregate into a Generated Artifact

A recurring framework migration: an aggregate file that was maintained by hand (an index, a registry, a routing table) is converted into a **projection generated from its constituent sources**. Live examples: `PF-documentation-map.md` (generated by `Build-DocumentationMap.ps1` from each artifact's `.SYNOPSIS` / `description:` frontmatter) and the task-metadata projections — `ai-tasks.md` tables, both infrastructure registries, the `tasks/README` catalog (generated by `Build-TaskMetadata.ps1` from each task file's frontmatter + authored sections).

**Cutover procedure:**

1. **Identify the source of every piece.** For each distinct fragment the aggregate currently shows, name where it will come from once generated (a frontmatter field, a script synopsis, a per-item authored section). Fragments with no source are the ones at risk.
2. **Mine existing content into the sources first.** Move any hand-authored content that lives *only* in the aggregate back into its source artifact before switching — anything still living only in the target when the generator first runs is silently lost.
3. **Build the generator and diff against the current file.** Generate to a scratch location and diff against the live hand-maintained file; every difference is either a generator bug or un-mined content — reconcile until the generated output carries the intended content. A `-Check` / drift mode that exits non-zero on mismatch makes this diff reusable as a gate afterward.
4. **Cut over.** Replace the target with generated output and make the **DO-NOT-EDIT header the first edit** — point it at the generator and at the source-of-truth so future editors fix the source, not the projection.
5. **Wire the drift gate.** Add the generator's `-Check` mode to validation / pre-commit so a hand-edited or stale target is caught before commit.

> **⚠️ Parallel-edit overwrite hazard.** From the moment the conversion is decided until forever after, a direct edit to the generated target is **silently destroyed by the next regeneration**. Three things contain it: (a) the mine-then-switch ordering of steps 2–4, so nothing of value lives only in the target; (b) the DO-NOT-EDIT header landed as the *first* cutover action, warning the next editor; (c) the `-Check` drift gate, which fails the build when someone hand-edits anyway. For the rare fragment that genuinely cannot be sourced, use an explicit **`BEGIN/END HAND-WRITTEN` region** the generator preserves verbatim (as `process-framework-task-registry.md` and `task-transition-registry.md` do) rather than leaving it to be clobbered.

## Migration Tools

### Document Analysis Tools

- Content inventories
- Structure analyzers
- Link checkers
- Metadata extractors

### Transformation Tools

- Markdown processors
- XSLT transformations
- Regular expression search/replace
- Custom migration scripts

### Validation Tools

- Schema validators
- Link validators
- Format checkers
- Consistency analyzers

## Related Resources

- [Documentation Structure Guide](../framework/documentation-structure-guide.md)
- <!-- [`template-development` craft skill](../../../.claude/skills/template-development/SKILL.md) - Template/example link commented out -->
- [Structure Change Task](../../tasks/support/structure-change-task.md)
- [`task-creation` craft skill](../../../.claude/skills/task-creation/SKILL.md)
