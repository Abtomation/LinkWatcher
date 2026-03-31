# Post-Move Remaining `process-framework` References

> Generated: 2026-03-30 after moving `process-framework` → `process-framework/`
> Total: ~140 files, ~450 remaining references
>
> **LinkWatcher processing time**: ~2 hours 3 minutes (09:28 → 11:31)
> - 813 files moved detected
> - 2,003 references updated automatically
> - 283 directory-path references updated
> - Log rotated 3 times during processing (~40,000+ log lines)

---

## Analysis: Why LinkWatcher Didn't Update These

Each file is annotated with:
- **Should update?** — Would a perfect LinkWatcher update this?
- **Pattern** — What type of reference is it?
- **Why missed** — Root cause for why LinkWatcher didn't catch it

---

## Root-level config files

**Pattern: Paths in non-link contexts (@ mentions, batch commands, YAML values, JSON values, comments)**
**Should a perfect LinkWatcher update these? YES** — these are real paths that point to files. However, the reference formats are not recognized as links by any parser.

- [ ] `CLAUDE.md` (10 refs) — `@process-framework/...` mentions and backtick-quoted paths in prose. **Why missed**: `@` prefix references and backtick code paths are not parsed as links by the Markdown parser; it only handles `[text](path)` and `[text]: path` patterns.
- [ ] `dev.bat` (8 refs) — PowerShell command strings like `"& doc/process-framework/scripts/..."`. **Why missed**: `.bat` is not a monitored file type at all.
- [ ] `pyproject.toml` (1 ref) — Comment: `# NOTE: Framework wrapper config is in doc/process-framework/...`. **Why missed**: `.toml` is not a monitored file type.
- [ ] `.pre-commit-config.yaml` (1 ref) — YAML value: `entry: pwsh.exe -ExecutionPolicy Bypass -File doc/process-framework/...`. **Why missed**: YAML parser only handles YAML values that look like file paths, but this is an embedded command string.
- [ ] `.claude/settings.local.json` (1 ref) — JSON value: `"Bash(python doc/process-framework/...)"`. **Why missed**: `.claude/` directory is likely not monitored (hidden directory).

## Product docs (`doc/product-docs/`)

- [ ] `doc/product-docs/PD-id-registry.json` (1) — JSON value: `"main": "process-framework/state-tracking"`. **Should update? YES.** **Why missed**: JSON parser updated other entries but this one contains an old path as a directory reference — the parser may not recognize directory paths (no file extension).
- [ ] `doc/product-docs/state-tracking/permanent/technical-debt-tracking.md` (3) — Markdown table prose: tech debt descriptions mentioning the old path. **Should update? NO** — these are historical descriptions of what happened ("identified during doc/process-framework directory move"), not file links. Updating would falsify the historical record.
- [ ] `doc/product-docs/state-tracking/permanent/bug-tracking.md` (5) — Markdown table prose: bug descriptions with old paths. **Should update? PARTIALLY** — same mix of historical descriptions and actual path references.
- [ ] `doc/product-docs/test-audits/README.md` (6) — Prose in file-tree diagrams and section headers: `(script: doc/process-framework/scripts/...)`. **Should update? YES.** **Why missed**: Paths are in prose/parentheses, not in markdown link syntax `[text](path)`.
- [ ] `doc/product-docs/state-tracking/features/archive/4.1.1-test-suite-implementation-state.md` (1) — Markdown link: `[Run-Tests.ps1](../../../../doc/process-framework/scripts/test/Run-Tests.ps1)`. **Should update? YES.** **Why missed**: The relative path `../../../../doc/process-framework/...` traverses up through the old directory structure. LinkWatcher may have failed to resolve this deep relative path correctly after the move.

## Test files (`test/`)

**Pattern: Mix of markdown prose and Python string literals used as test data**

- [ ] `test/audits/README.md` (6) — Same pattern as `doc/product-docs/test-audits/README.md` (prose, file-tree, section headers). **Should update? YES.** **Why missed**: Not in markdown link syntax.
- [ ] `test/state-tracking/permanent/test-tracking.md` (1) — Backtick-quoted path in a markdown list. **Should update? YES.** **Why missed**: Backtick-quoted paths are not parsed as links.
- [ ] `test/e2e-acceptance-testing/README.md` (1) — Bash command in code block. **Should update? YES.** **Why missed**: Code block content is not parsed for links.
- [ ] `test/e2e-acceptance-testing/templates/powershell-regex-preservation/TE-E2E-001-regex-preserved-on-file-move/test-case.md` (1) — **Note**: May be a false positive or the ref is in test fixture data. **Should update? MAYBE** — depends on whether test data should reflect current paths.
- [ ] `test/specifications/feature-specs/archive/test-spec-5-1-1-cicd-development-tooling.md` (1) — Archived spec. **Should update? NO** — historical document.
- [ ] `test/archive/test-registry-archived-2026-03-26.yaml` (1) — Archived YAML. **Should update? NO** — historical archive.
- [ ] `test/automated/unit/test_database.py` (12) — Python string literals used as test data/assertions: `"process-framework/scripts"`. **Should update? YES** — tests will fail if paths don't match reality. **Why missed**: Python parser doesn't update string literals that aren't import/from statements.
- [ ] `test/automated/parsers/test_markdown.py` (11) — Python string literals: test data and assertions. **Should update? YES.** **Why missed**: Same — Python parser limitation.
- [ ] `test/automated/parsers/test_generic.py` (6) — Python string literals in test data. **Should update? YES.** **Why missed**: Same.
- [ ] `test/automated/parsers/test_powershell.py` (3) — Python string literals. **Should update? YES.** **Why missed**: Same.
- [ ] `test/automated/parsers/test_yaml.py` (4) — Python string literals. **Should update? YES.** **Why missed**: Same.
- [ ] `test/automated/parsers/test_json.py` (4) — Python string literals. **Should update? YES.** **Why missed**: Same.
- [ ] `test/automated/bug-validation/PD-BUG-021_directory_path_detection_validation.py` (5) — Python string literals. **Should update? YES.** **Why missed**: Same.

## Source code (`linkwatcher/`)

- [ ] `linkwatcher/validator.py` (1) — Python comment: `# [text](/process-framework/...) means <project_root>/doc/...`. **Should update? YES** — comment describes behavior and uses an example with the old path. **Why missed**: Comments are not parsed for links.

## Process framework scripts

**Pattern: PowerShell string literals (parameter defaults, variable assignments, comments) and Python docstrings**
**Should a perfect LinkWatcher update these? YES** — these are functional paths used in script execution, not historical prose. Except comments which are documentation.
**Why missed**: PowerShell parser only handles source-dot (`. path`), Import-Module, and certain path patterns in code. It doesn't update arbitrary string literals containing paths. Python parser only handles import statements, not docstrings.

- [ ] `process-framework/scripts/IdRegistry.psm1` (3) — Comments (`# Returns: "process-framework/..."`) and function arguments. **Should update? PARTIALLY** — comments are docs, but function args affect behavior.
- [ ] `process-framework/scripts/feedback_db.py` (8) — Docstring usage examples: `python process-framework/scripts/feedback_db.py init`. **Should update? YES** — misleading usage instructions.
- [ ] `process-framework/scripts/AUTOMATION-USAGE-GUIDE.md` (2) — Prose/code blocks with `cd` commands. **Should update? YES.** **Why missed**: Code block content not parsed.
- [ ] `process-framework/scripts/update/Update-ValidationReportState.ps1` (1) — PowerShell comment. **Should update? NICE-TO-HAVE.**
- [ ] `process-framework/scripts/update/Update-TestAuditState.ps1` (1) — PowerShell comment. **Should update? NICE-TO-HAVE.**
- [ ] `process-framework/scripts/update/Update-TechnicalDebtFromAssessment.ps1` (3) — Parameter default `"../doc/process-framework/..."` and variable assignment. **Should update? YES** — script will break. **Why missed**: String literals not recognized as paths by PS parser.
- [ ] `process-framework/scripts/update/Update-ScriptReferences.ps1` (1) — PowerShell string/comment. **Should update? YES.**
- [ ] `process-framework/scripts/update/Update-LanguageConfig.ps1` (1) — PowerShell string/comment. **Should update? YES.**
- [ ] `process-framework/scripts/update/Update-FeatureImplementationState.ps1` (1) — PowerShell string/comment. **Should update? YES.**
- [ ] `process-framework/scripts/update/Update-CodeReviewState.ps1` (1) — PowerShell string/comment. **Should update? YES.**
- [ ] `process-framework/scripts/file-creation/support/New-Task.ps1` (1) — PowerShell string/comment. **Should update? YES.**
- [ ] `process-framework/scripts/file-creation/support/New-Guide.ps1` (1) — PowerShell string/comment. **Should update? YES.**
- [ ] `process-framework/scripts/file-creation/support/New-FrameworkExtensionConcept.ps1` (2) — PowerShell path strings in `Get-Content` and `Remove-Item`. **Should update? YES** — will break. **Why missed**: Paths inside command argument strings not parsed.
- [ ] `process-framework/scripts/file-creation/00-setup/New-RetrospectiveMasterState.ps1` (1) — PowerShell string/comment. **Should update? YES.**
- [ ] `process-framework/scripts/file-creation/02-design/New-APISpecification.ps1` (1) — PowerShell string/comment. **Should update? YES.**
- [ ] `process-framework/scripts/file-creation/02-design/New-APIDataModel.ps1` (1) — PowerShell string/comment. **Should update? YES.**
- [ ] `process-framework/templates/support/document-creation-script-template.ps1` (2) — Comments: `# All file-creation scripts are in doc/process-framework/...`. **Should update? NICE-TO-HAVE** — template comments.

## Process framework tasks + guides + templates (markdown files inside `process-framework/`)

**Common pattern across all these files**: Paths appear in `cd` commands inside code blocks, backtick-quoted inline code, Mermaid diagram nodes, and prose text — NOT in `[text](path)` markdown links.
**Should a perfect LinkWatcher update these? YES** — these are instructional paths that users/agents follow to execute commands.
**Why missed**: The Markdown parser only updates `[text](path)` and `[text]: path` link formats. It does not touch code blocks, backtick-quoted strings, prose path mentions, or Mermaid diagram content.

### Tasks (30 files, ~90 refs)

- [ ] `process-framework/ai-tasks.md` (1) — `cd doc/process-framework/scripts/...` in code block
- [ ] `process-framework/tasks/README.md` (2)
- [ ] `process-framework/tasks/support/new-task-creation-process.md` (11) — PowerShell command strings with `cd /c/path/to/project/doc/process-framework/...`
- [ ] `process-framework/tasks/support/framework-extension-task.md` (6) — `cd` commands and inline code paths
- [ ] `process-framework/tasks/support/framework-evaluation.md` (4)
- [ ] `process-framework/tasks/support/framework-domain-adaptation.md` (6)
- [ ] `process-framework/tasks/support/tools-review-task.md` (2)
- [ ] `process-framework/tasks/support/structure-change-task.md` (5) — `cd` commands and inline code
- [ ] `process-framework/tasks/00-setup/codebase-feature-discovery.md` (4)
- [ ] `process-framework/tasks/00-setup/project-initiation-task.md` (1)
- [ ] `process-framework/tasks/01-planning/feature-discovery-task.md` (1)
- [ ] `process-framework/tasks/01-planning/feature-request-evaluation.md` (3)
- [ ] `process-framework/tasks/03-testing/e2e-acceptance-test-case-creation-task.md` (1)
- [ ] `process-framework/tasks/03-testing/e2e-acceptance-test-execution-task.md` (4)
- [ ] `process-framework/tasks/03-testing/test-audit-task.md` (4)
- [ ] `process-framework/tasks/03-testing/test-implementation-task.md` (1)
- [ ] `process-framework/tasks/04-implementation/core-logic-implementation.md` (2)
- [ ] `process-framework/tasks/04-implementation/data-layer-implementation.md` (2)
- [ ] `process-framework/tasks/04-implementation/feature-enhancement.md` (1)
- [ ] `process-framework/tasks/04-implementation/foundation-feature-implementation-task.md` (2)
- [ ] `process-framework/tasks/04-implementation/implementation-finalization.md` (2)
- [ ] `process-framework/tasks/04-implementation/integration-and-testing.md` (3)
- [ ] `process-framework/tasks/04-implementation/quality-validation.md` (1)
- [ ] `process-framework/tasks/04-implementation/state-management-implementation.md` (1)
- [ ] `process-framework/tasks/04-implementation/ui-implementation.md` (1)
- [ ] `process-framework/tasks/06-maintenance/bug-fixing-task.md` (3)
- [ ] `process-framework/tasks/06-maintenance/code-refactoring-lightweight-path.md` (1)
- [ ] `process-framework/tasks/06-maintenance/code-refactoring-standard-path.md` (1)
- [ ] `process-framework/tasks/07-deployment/user-documentation-creation.md` (2)
- [ ] `process-framework/tasks/cyclical/technical-debt-assessment-task.md` (1)

### Guides (18 files, ~56 refs)

- [ ] `process-framework/guides/support/document-creation-script-development-guide.md` (7) — Backtick code paths, `Copy-Item` commands, table entries
- [ ] `process-framework/guides/support/guide-creation-best-practices-guide.md` (5) — `cd` commands in code blocks
- [ ] `process-framework/guides/support/task-creation-guide.md` (6)
- [ ] `process-framework/guides/support/state-file-creation-guide.md` (6)
- [ ] `process-framework/guides/support/visualization-creation-guide.md` (1)
- [ ] `process-framework/guides/support/script-development-quick-reference.md` (1)
- [ ] `process-framework/guides/framework/feedback-form-guide.md` (2)
- [ ] `process-framework/guides/framework/feedback-form-completion-instructions.md` (2)
- [ ] `process-framework/guides/02-design/tdd-creation-guide.md` (1)
- [ ] `process-framework/guides/03-testing/test-infrastructure-guide.md` (3)
- [ ] `process-framework/guides/03-testing/test-audit-usage-guide.md` (3)
- [ ] `process-framework/guides/03-testing/integration-and-testing-usage-guide.md` (3)
- [ ] `process-framework/guides/03-testing/e2e-acceptance-test-case-customization-guide.md` (3)
- [ ] `process-framework/guides/04-implementation/development-guide.md` (1)
- [ ] `process-framework/guides/04-implementation/feature-implementation-state-tracking-guide.md` (1)
- [ ] `process-framework/guides/05-validation/feature-validation-guide.md` (1)
- [ ] `process-framework/guides/06-maintenance/bug-reporting-guide.md` (3)
- [ ] `process-framework/guides/cyclical/debt-item-creation-guide.md` (4)

### Templates + other docs (12 files, ~37 refs)

- [ ] `process-framework/infrastructure/process-framework-task-registry.md` (4)
- [ ] `process-framework/state-tracking/permanent/process-improvement-tracking.md` (7) — Historical changelog entries in markdown tables. **Should update? NO** — falsifies history.
- [ ] `process-framework/visualization/process-flows/feedback-process-flowchart.md` (5) — Mermaid diagram node text. **Why missed**: Mermaid content not parsed.
- [ ] `process-framework/visualization/context-maps/support/project-initiation-map.md` (1)
- [ ] `process-framework/evaluation-reports/20260325-framework-evaluation-testing-setup-tasks-templates-scripts-guides-state.md` (1)
- [ ] `process-framework/templates/README.md` (1)
- [ ] `process-framework/templates/support/temp-task-creation-state-template.md` (12) — Backtick paths and prose describing where to move/run files
- [ ] `process-framework/templates/support/temp-process-improvement-state-template.md` (2)
- [ ] `process-framework/templates/support/task-completion-template.md` (2)
- [ ] `process-framework/templates/support/structure-change-state-template.md` (4)
- [ ] `process-framework/templates/support/structure-change-state-content-update-template.md` (1)
- [ ] `process-framework/templates/support/structure-change-state-rename-template.md` (1)

## Process framework feedback/reviews

**Pattern: Prose text in feedback forms mentioning paths by name.**
**Should a perfect LinkWatcher update these? NO** — these are historical records of what was discussed/evaluated at a point in time. Updating them would falsify the feedback.

- [ ] `process-framework/feedback/reviews/tools-review-20260328-102622.md` (1)
- [ ] `process-framework/feedback/reviews/tools-review-20260317-141335.md` (1)
- [ ] `process-framework/feedback/reviews/tools-review-20260226.md` (1)
- [ ] `process-framework/feedback/reviews/tools-review-20260221.md` (1)

## Process framework archived feedback

**Same pattern as above — historical records. Should NOT be updated.**

- [ ] `process-framework/feedback/archive/2026-02/tools-review-20260221/processed-forms/20260219-155547-PF-TSK-066-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-02/tools-review-20260227/processed-forms/20260227-131930-PF-TSK-023-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260304/processed-forms/20260304-003423-PF-TSK-034-feedback.md` (2)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260315/processed-forms/20260314-125525-PF-TSK-014-feedback.md` (2)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260317/processed-forms/20260317-093228-PF-TSK-068-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260317/processed-forms/20260317-110032-PF-TSK-022-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260320/processed-forms/20260318-153810-PF-TSK-009-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260326/processed-forms/20260326-135117-PF-TSK-067-feedback.md` (3)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260328/processed-forms/20260327-232226-PF-TSK-022-feedback.md` (3)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260328/processed-forms/20260327-232434-PF-TSK-022-feedback.md` (2)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260328/processed-forms/20260327-233642-PF-TSK-022-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260328/processed-forms/20260327-234510-PF-TSK-022-feedback.md` (1)
- [ ] `process-framework/feedback/archive/2026-03/tools-review-20260328/processed-forms/20260327-235750-PF-TSK-022-feedback.md` (1)

## Process framework proposals (active)

**Pattern: Prose text describing proposed directory structures and paths.**
**Should a perfect LinkWatcher update these? YES for active proposals** — they describe current state. But only paths that are navigational, not those describing the change itself.

- [ ] `process-framework/proposals/proposals/structure-change-test-directory-consolidation-and-framework-integration-proposal.md` (5)
- [ ] `process-framework/proposals/proposals/structure-change-generalize-testing-and-ci-cd-infrastructure-into-framework-proposal.md` (1)

## Process framework proposals (old)

**Pattern: Historical proposal documents with paths in prose, code blocks, and tables.**
**Should a perfect LinkWatcher update these? NO** — archived proposals are historical records. They describe the state at the time of writing.

- [ ] `process-framework/proposals/proposals/old/structure-change-split-id-registry-into-framework-and-product-registries-proposal.md` (22)
- [ ] `process-framework/proposals/proposals/old/structure-change-marker-based-test-infrastructure-proposal.md` (16)
- [ ] `process-framework/proposals/proposals/old/structure-change-manual-testing-proposal.md` (4)
- [ ] `process-framework/proposals/proposals/old/structure-change-test-directory-consolidation-and-framework-integration-proposal.md` (3)
- [ ] `process-framework/proposals/proposals/old/tech-agnostic-testing-pipeline-concept.md` (1)
- [ ] `process-framework/proposals/proposals/old/single-tracking-surface-proposal.md` (1)
- [ ] `process-framework/proposals/proposals/old/retrospective-task-redesign-summary.md` (5)
- [ ] `process-framework/proposals/proposals/old/document-types-created-by-tasks.md` (2)

## Process framework old state tracking

**Pattern: Completed state tracking files with paths in prose, code blocks, and checklists.**
**Should a perfect LinkWatcher update these? NO** — completed/archived state files are historical records.

- [ ] `process-framework/state-tracking/temporary/old/structure-change-test-directory-consolidation.md` (10)
- [ ] `process-framework/state-tracking/temporary/old/structure-change-split-id-registry-into-framework-and-product-registries.md` (25)
- [ ] `process-framework/state-tracking/temporary/old/structure-change-rename-manual-testing-to-e2e-acceptance-testing.md` (6)
- [ ] `process-framework/state-tracking/temporary/old/structure-change-marker-based-test-infrastructure.md` (1)
- [ ] `process-framework/state-tracking/temporary/old/structure-change-manual-testing-framework.md` (4)
- [ ] `process-framework/state-tracking/temporary/old/structure-change-generalize-validation-framework.md` (2)
- [ ] `process-framework/state-tracking/temporary/old/structure-change-generalize-testing-and-cicd-into-framework.md` (4)
- [ ] `process-framework/state-tracking/temporary/old/retrospective-master-state.md` (1)
- [ ] `process-framework/state-tracking/temporary/old/feature-consolidation-state.md` (3)
- [ ] `process-framework/state-tracking/temporary/old/temp-task-creation-scenario-based-e2e-acceptance-testing.md` (2)
- [ ] `process-framework/state-tracking/temporary/old/temp-task-creation-comprehensive-retrospective-framework-integration.md` (3)
- [ ] `process-framework/state-tracking/temporary/old/temp-task-creation-enhancement-workflow-extension.md` (1)
- [ ] `process-framework/state-tracking/temporary/old/temp-task-creation-domain-adaptation-cleanup.md` (5)
- [ ] `process-framework/state-tracking/temporary/old/temp-task-creation-tech-agnostic-testing-pipeline.md` (9)
- [ ] `process-framework/state-tracking/temporary/old/temp-task-creation-user-documentation-creation.md` (2)
- [ ] `process-framework/state-tracking/temporary/old/UPDATE-CODE-INVENTORY-SECTIONS.md` (1)

---

## Summary: Root Causes

| Root Cause | Refs | Files | Should Fix? |
|-----------|------|-------|-------------|
| **Markdown code blocks / backtick paths** — paths inside `` ` `` or fenced code blocks are not parsed | ~150 | ~50 | YES — these are instructional `cd` commands and paths |
| **Prose path mentions** — paths in plain text, not in link syntax | ~80 | ~30 | YES — navigational, but hard to distinguish from prose |
| **Python string literals** — test data and assertions | ~54 | ~9 | YES — tests will fail |
| **PowerShell string literals** — parameter defaults, variable assignments | ~18 | ~14 | YES — scripts may break |
| **Historical records** — old proposals, archived feedback, completed state files, changelog entries | ~130 | ~40 | NO — falsifies history |
| **Non-monitored file types** — `.bat`, `.toml`, `.claude/` | ~11 | ~4 | YES (manual) |
| **Mermaid diagrams** — paths in flowchart/diagram node text | ~5 | ~2 | YES — misleading diagrams |
| **Python/PS comments** — documentation in code comments | ~5 | ~3 | NICE-TO-HAVE |

### Key Takeaway

The **single biggest gap** is that LinkWatcher's Markdown parser only updates `[text](path)` and `[text]: path` link formats. It does not touch:
- Code blocks (fenced or indented)
- Backtick-quoted inline code
- Prose path mentions
- Mermaid diagram content

This accounts for ~230 of the ~450 remaining references (~51%). The second largest category is historical records (~130 refs) which should NOT be updated.
