---
id: PF-PRO-009
type: Document
category: General
version: 1.0
created: 2026-03-22
updated: 2026-03-22
---

# Structure Change Proposal Template

## Overview
Move Feature 4.1.1 (Test Suite) and 5.1.1 (CI/CD Development Tooling) from feature tracking into the process framework as reusable, language-specific templates and guides. Archive both features from feature-tracking.md. Update Project Initiation task to scaffold testing and CI/CD infrastructure for new projects using framework templates.

**Structure Change ID:** SC-PENDING
**Proposer:** AI Agent & Human Partner
**Date Proposed:** 2026-03-22
**Target Implementation Date:** 2026-03-22

## Current Structure

Features 4.1.1 (Test Suite) and 5.1.1 (CI/CD & Development Tooling) are tracked in `feature-tracking.md` as product features alongside the actual product features (parser, database, file monitoring, etc.). Each has:

- Feature state file in `state-tracking/features/`
- FDD in `doc/functional-design/fdds`
- TDD in `doc/technical/tdd`
- Test specification in `test/specifications/feature-specs/`
- Validation reports referencing them

Testing and CI/CD infrastructure is project-specific — each project has its own `pytest.ini`, `conftest.py`, CI pipeline, etc. The framework has no reusable templates or scaffolding for new projects.

### Current File Ownership

```
Feature 4.1.1 owns:
  test/automated/conftest.py          ← fixtures (language-specific pattern)
  test/automated/utils.py             ← test utilities
  test/automated/test_config.py       ← test configuration presets
  pytest.ini                          ← pytest-native config
  test/automated/{unit,integration,parsers,performance}/  ← test directories

Feature 5.1.1 owns:
  dev.bat                             ← dev shortcut script
  .pre-commit-config.yaml             ← code quality hooks
  LinkWatcher_run/*.ps1, *.bat, *.sh  ← startup scripts
  debug/*.py                          ← debug tools
  deployment/*                        ← package building
  scripts/benchmark.py                ← benchmarking
  (deleted: ci.yml, run_tests.py, setup_cicd.py, CONTRIBUTING.md)
```

## Proposed Structure

### Principle

Testing and CI/CD are **framework concerns**, not product features. The framework provides:
- Language-specific templates and guides for scaffolding
- Project Initiation task sets up the skeleton
- Project-specific test *code* stays in the project but is not tracked as a "feature"

### Framework additions

```
process-framework/
├── templates/
│   ├── 07-deployment/
│   │   ├── ci-github-actions-template.yml     ← CI pipeline template
│   │   ├── pre-commit-config-template.yaml    ← Pre-commit hooks template
│   │   └── dev-script-template.bat            ← Dev shortcut template
│   └── 03-testing/
│       └── (existing test templates stay)
├── guides/
│   ├── 03-testing/
│   │   └── testing-setup-guide.md             ← NEW: How to set up testing per language
│   └── 07-deployment/
│       └── cicd-setup-guide.md                ← NEW: How to set up CI/CD per platform
└── languages-config/
    └── python-config.json                     ← Already has testSetup section
```

### Feature tracking changes

```
feature-tracking.md:
  4.1.1 Test Suite        → ARCHIVED ("Generalized into framework")
  5.1.1 CI/CD Tooling     → ARCHIVED ("Generalized into framework")
```

### File ownership after migration

```
Framework-owned (reusable):
  Run-Tests.ps1, test-registry.yaml, test-tracking.md     ← already framework
  python-config.json (testSetup section)                   ← already framework
  Testing setup guide, CI/CD setup guide                   ← NEW
  CI/CI/dev-script templates                               ← NEW

Project-owned (not a feature, just infrastructure):
  pytest.ini, conftest.py, test directories                ← created by Project Initiation
  .pre-commit-config.yaml, dev.bat                         ← created by Project Initiation
  test/automated/**/*.py                                   ← actual test code, tracked by test-tracking.md
  LinkWatcher_run/*, debug/*, deployment/*                  ← project-specific utilities
```

## Rationale

### Benefits
- **Portability**: New projects get testing and CI/CD scaffolding via Project Initiation, not by copying from LinkWatcher
- **Clean feature tracking**: Only product features visible — no infrastructure noise
- **Framework reuse**: Testing patterns (directory conventions, fixture patterns, coverage tracking) are documented once and applied everywhere
- **Accurate documentation**: FDDs/TDDs for 4.1.1 and 5.1.1 are 40-60% stale (reference deleted files). Converting to guides eliminates the drift problem

### Challenges
- **Cross-reference cleanup**: 61+ files reference 5.1.1, 40+ reference 4.1.1. Each needs review.
- **FDD/TDD disposition**: These design docs need to either become framework guides or be archived
- **Validation reports**: 6 validation reports scored these features — historical context needs preservation
- **Test spec conversion**: test-spec-4-1-1 and test-spec-5-1-1 describe infrastructure testing — may convert to framework validation procedures

## Audit Results (2026-03-22)

### Guide Duplication Check

No duplication with proposed new guides:

| Existing guide | Purpose | Proposed guide | Overlap? |
|---|---|---|---|
| test-infrastructure-guide.md (PF-GDE-050) | How test/ connects to framework ("what exists") | Testing setup guide ("how to scaffold") | No |
| integration-and-testing-usage-guide.md (PF-GDE-040) | How to use PF-TSK-053 ("how to write tests") | Testing setup guide ("how to create skeleton") | No |
| No deployment guide exists | — | CI/CD setup guide | No — `07-deployment/` guide directory doesn't exist |

### Testing Tasks — All Current (no updates needed)

| Task | Version | Updated | Deleted file refs? |
|---|---|---|---|
| PF-TSK-012 (Test Spec Creation) | v1.4 | 2026-03-15 | None |
| PF-TSK-030 (Test Audit) | v1.5 | 2026-03-17 | None |
| PF-TSK-053 (Integration & Testing) | v2.1 | 2026-03-02 | None |
| PF-TSK-069 (E2E Test Case Creation) | v1.1 | 2026-03-18 | None |
| PF-TSK-070 (E2E Test Execution) | v1.1 | 2026-03-18 | None |

### Release Deployment Task (PF-TSK-008) — Needs Cleanup

- **Version**: 1.1, last updated 2025-06-08
- **Process is accurate**: correctly references Run-Tests.ps1, test-registry.yaml, test-tracking.md, E2E acceptance tests
- **7 "File not found" entries** for infrastructure that was never created:
  - `release-status.md` (3 refs) — no release status tracking file exists
  - `release-notes-vX.Y.Z.md` — no release notes directory exists
  - `deployment-report-vX.Y.Z.md` — no deployment reports exist
  - `semantic-versioning-guide.md` — never created
  - `rollback-procedures.md` — never created
  - `pipeline-documentation.md` — never created (and CI pipeline was deleted)
- **No references to deleted files** (run_tests.py, ci.yml, etc.)
- **Action**: Clean up "File not found" entries. Create missing release infrastructure or remove references. Update CI/CD pipeline documentation reference since ci.yml was deleted.

## Affected Files

### Archives (move to archive with "Generalized into framework" note)
- `state-tracking/features/4.1.1-test-suite-implementation-state.md`
- `state-tracking/features/5.1.1-cicd-development-tooling-implementation-state.md`
- `doc/functional-design/fdds/fdd-4-1-1-test-suite.md`
- `doc/functional-design/fdds/fdd-5-1-1-cicd-development-tooling.md`
- `doc/technical/tdd/tdd-4-1-1-test-suite-t2.md`
- `doc/technical/tdd/tdd-5-1-1-cicd-development-tooling-t2.md`
- `test/specifications/feature-specs/test-spec-4-1-1-test-suite.md`
- `test/specifications/feature-specs/test-spec-5-1-1-cicd-development-tooling.md`

### Modified
- `state-tracking/permanent/feature-tracking.md` — Archive 4.1.1 and 5.1.1 rows
- `PF-documentation-map.md` — Update references, add new guides
- `tasks/support/project-initiation-task.md` — Add testing/CI scaffolding steps
- `tasks/07-deployment/release-deployment-task.md` — Clean up 7 "File not found" entries, remove stale CI/CD pipeline doc reference
- `languages-config/python-config.json` — Already has testSetup (done)
- `templates/support/language-config-template.json` — Already has testSetup (done)

### Not modified (confirmed current)
- `tasks/03-testing/test-specification-creation-task.md` — v1.4, no stale refs
- `tasks/03-testing/test-audit-task.md` — v1.5, no stale refs
- `tasks/03-testing/e2e-acceptance-test-execution-task.md` — v1.1, no stale refs
- `tasks/03-testing/e2e-acceptance-test-case-creation-task.md` — v1.1, no stale refs
- `tasks/04-implementation/integration-and-testing.md` — v2.1, no stale refs
- `guides/03-testing/test-infrastructure-guide.md` — no overlap with new testing setup guide
- `guides/03-testing/integration-and-testing-usage-guide.md` — no overlap with new testing setup guide

### New files
- `guides/03-testing/testing-setup-guide.md` — Language-specific testing scaffolding guide
- `guides/07-deployment/cicd-setup-guide.md` — CI/CD setup guide per platform
- `templates/07-deployment/ci-github-actions-template.yml` — Reusable CI template
- `templates/07-deployment/pre-commit-config-template.yaml` — Reusable pre-commit template
- `templates/07-deployment/dev-script-template.bat` — Reusable dev script template

## Migration Strategy

### Phase 1: Create framework guides and templates
- Extract reusable patterns from 4.1.1 FDD/TDD into testing setup guide
- Extract reusable patterns from 5.1.1 FDD/TDD into CI/CD setup guide
- Create CI, pre-commit, and dev-script templates from current LinkWatcher files

### Phase 2: Update Project Initiation task
- Add testing scaffolding steps (create test directories, conftest.py, pytest.ini from templates)
- Add CI/CD scaffolding steps (create ci.yml, .pre-commit-config.yaml, dev.bat from templates)
- Reference language configs for language-specific setup

### Phase 3: Archive features and clean cross-references
- Archive 4.1.1 and 5.1.1 from feature-tracking.md
- Move FDDs, TDDs, test specs, feature state files to archive directories
- Update PF-documentation-map.md to reference new guides instead
- Add archive notes to validation reports

## Task Modifications

### Project Initiation (PF-TSK)

**Changes needed:**
- Add step: "Set up testing infrastructure" — creates test directories, conftest.py skeleton, pytest.ini from framework templates, using language config
- Add step: "Set up CI/CD infrastructure" — creates CI pipeline, pre-commit config, dev script from framework templates
- Add context requirement: testing setup guide, CI/CD setup guide

**Rationale:** Project Initiation is the natural home for scaffolding — it already sets up project-config.json and language configs.

### Release & Deployment (PF-TSK-008)

**Changes needed:**
- Remove 7 "File not found" references (release-status.md, release notes, deployment reports, guides)
- Either create the missing release infrastructure or simplify the outputs section
- Remove CI/CD Pipeline Documentation reference (pipeline was deleted, no GitHub remote)
- Keep existing Run-Tests.ps1 and E2E test references (confirmed accurate)

**Rationale:** Task is process-accurate but references infrastructure that was never created. Cleaning up prevents confusion during actual release execution.

## Testing Approach

### Success Criteria
- Project Initiation task can scaffold a new Python project with working test infrastructure
- `Run-Tests.ps1 -ListCategories` works on the scaffolded project
- All framework validation scripts pass after migration
- No broken cross-references in PF-documentation-map.md
- feature-tracking.md shows only product features (0.x.x through 3.x.x)

## Rollback Plan

### Trigger Conditions
- Framework guides are incomplete and new projects can't scaffold properly
- Cross-reference cleanup introduces broken links that LinkWatcher can't resolve

### Rollback Steps
1. Restore archived feature state files from archive directories
2. Re-add 4.1.1 and 5.1.1 rows to feature-tracking.md
3. Revert PF-documentation-map.md changes

## Approval

**Approved By:** Human Partner
**Date:** 2026-03-22

**Comments:** Approved. Execute via Structure Change task (PF-TSK-014) in a new session.
