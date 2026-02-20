---
id: PF-PRO-004
type: Process Framework
category: Proposal
version: 2.0
created: 2026-02-20
updated: 2026-02-20
extension_name: Tech-Agnostic Testing Pipeline
extension_description: Make the testing framework tech-stack agnostic, add cross-cutting test support, register existing tests, and update onboarding tasks for proper test handling in future projects
extension_scope: Testing task definitions, templates, scripts, tracking infrastructure, existing test registration, and onboarding task updates
---

# Tech-Agnostic Testing Pipeline - Framework Extension Concept

## Document Metadata
| Metadata | Value |
|----------|-------|
| Document Type | Framework Extension Concept |
| Created Date | 2026-02-20 |
| Status | Awaiting Human Review |
| Extension Name | Tech-Agnostic Testing Pipeline |
| Extension Scope | Testing tasks, templates, scripts, tracking, cross-cutting specs, onboarding task updates |
| Author | AI Agent & Human Partner |

---

## 1. Purpose & Context

**Brief Description**: Transform the framework's testing pipeline from a Dart/Flutter-coupled system into a tech-stack agnostic, project-configurable testing workflow that supports cross-cutting integration tests, integrates with existing test suites, and combines framework traceability with practical execution guidance.

### Extension Overview

The current framework testing pipeline (Test Specification Creation → Test Implementation → Test Audit) is functionally sound in its lifecycle design but has three critical gaps when applied to the LinkWatcher project:

1. **Technology coupling**: Scripts, templates, and task definitions contain hardcoded Dart/Flutter/BreakoutBuddies references that prevent use with Python/pytest
2. **Per-feature fragmentation**: Integration tests spanning multiple features have no proper home in the per-feature test specification model
3. **No migration path**: Existing test suites (165+ methods in LinkWatcher) cannot be registered in the framework without re-creating them through the full pipeline

This extension solves all three by making the pipeline configurable via `project-config.json`, adding a cross-cutting test specification concept, defining a registration workflow for existing tests, and updating the onboarding tasks to properly handle test files in future project adoptions.

### Key Distinction from Existing Framework Components

| Existing Component | Purpose | Scope |
|-------------------|---------|-------|
| **Structure Change Task** | Reorganizes existing framework components | Rearrangement of current elements |
| **Process Improvement Task** | Makes granular improvements to existing processes | Optimization of current workflows |
| **New Task Creation Process** | Creates individual new tasks | Single task creation |
| **Tech-Agnostic Testing Pipeline** *(This Extension)* | **Transforms multi-component testing subsystem to be project-configurable, adds new test categories, and updates onboarding for test handling** | **Cross-cutting changes to 7+ tasks, 2+ templates, 2+ scripts, tracking infrastructure, and onboarding workflow** |

## 2. When to Use This Extension

This framework extension should be used when:

- **Adopting the framework into a non-Dart project**: Any project using Python, JavaScript, Go, Rust, etc. that needs the testing pipeline
- **A project has an existing test suite**: Pre-existing tests need to be registered in the framework without re-implementation
- **Integration tests cross feature boundaries**: Tests that exercise multiple features simultaneously need proper specification and tracking
- **Test execution guidance is needed alongside traceability**: Projects need both "which tests verify which requirement" (framework) and "which tests to run when" (execution matrix)

### Example Use Cases
- LinkWatcher (Python/pytest): 165+ existing test methods across unit, integration, parser, and performance categories need framework registration
- Any future project onboarded via the framework that has existing tests
- Projects with behavior-oriented test organization (e.g., by user action rather than by feature)

## 3. Core Process Overview

### Phase 1: Genericization (Remove tech coupling)
1. **Update New-TestFile.ps1** - Read `project-config.json` to determine language, select appropriate template, and generate correct test file structure
2. **Create test-file-template.py** - Python/pytest equivalent of the existing test-file-template.dart
3. **Update test-implementation-task.md** - Replace hardcoded BreakoutBuddies paths with relative references, make test types configurable
4. **Update test-audit-task.md** - Replace hardcoded BreakoutBuddies paths with relative references

### Phase 2: Cross-cutting test support (New capability)
5. **Create cross-cutting test spec template** - New template for test specifications that span multiple features
6. **Extend test-registry.yaml schema** - Add `crossCuttingFeatures` field for tests linked to multiple features
7. **Add cross-cutting test analysis to existing tasks** - Add optional cross-cutting test identification guidance to PF-TSK-053 (Integration and Testing); add cross-cutting template reference to PF-TSK-012 (Test Specification Creation) as available option
8. **Create `/test/specifications/cross-cutting-specs/` directory** - Storage for cross-cutting test specifications

### Phase 3: Migration & onboarding integration (Dual-track)

#### Track A: Register existing LinkWatcher tests
9. **Define bulk registration process** - Document steps to register existing tests in the framework without re-implementing them
10. **Populate test-registry.yaml** - Register all existing LinkWatcher test files with PD-TST IDs and feature mappings
11. **Populate test-implementation-tracking.md** - Add entries for all existing tests at status "Tests Implemented"
12. **Update feature-tracking.md** - Set Test Status for features with registered tests

#### Track B: Update onboarding tasks for test handling
13. **Update Codebase Feature Discovery (PF-TSK-064)** - Add test file classification: when processing files, allow classifying as source file, test file (assigned to feature), or cross-cutting test file
14. **Update Codebase Feature Analysis (PF-TSK-065)** - Add test validation: verify tests actually test what they claim, identify coverage gaps, assess test quality, populate test-registry.yaml and test-implementation-tracking.md
15. **Update Retrospective Documentation Creation (PF-TSK-066)** - Add test spec gap closure: create missing test specifications identified during analysis (not responsible for registry/tracking population)

### Phase 4: Integration & validation
16. **Create validation script** - PowerShell or Python script to verify test-registry.yaml consistency with actual test files on disk
17. **Update documentation-map.md** - Add new templates and cross-cutting spec directory
18. **Complete feedback form** - Task completion per framework requirements

## 4. Expected Outputs

### Phase 1 Outputs (Genericization)
- **Modified New-TestFile.ps1** - Reads project-config.json, selects language-appropriate template
- **New test-file-template.py** - Python/pytest test file template with PD-TST metadata in comments
- **Modified test-implementation-task.md** - Generic paths, configurable test types
- **Modified test-audit-task.md** - Generic paths, no BreakoutBuddies references

### Phase 2 Outputs (Cross-cutting support)
- **New cross-cutting-test-specification-template.md** - Template for multi-feature test specs
- **Extended test-registry.yaml schema** - With `crossCuttingFeatures` and `testType: cross-cutting` support
- **Modified integration-and-testing.md (PF-TSK-053)** - Optional cross-cutting test analysis guidance added
- **Modified test-specification-creation-task.md (PF-TSK-012)** - Reference to cross-cutting template as available option
- **New directory `/test/specifications/cross-cutting-specs/`**

### Phase 3 Outputs (Migration & onboarding)

#### Track A Outputs
- **Populated test-registry.yaml** - All existing LinkWatcher tests registered with IDs and feature mappings
- **Populated test-implementation-tracking.md** - Entries for all existing tests at "Tests Implemented" status
- **Updated feature-tracking.md** - Test Status column reflects registered tests

#### Track B Outputs
- **Modified codebase-feature-discovery.md (PF-TSK-064)** - Test file classification support (source vs test vs cross-cutting)
- **Modified codebase-feature-analysis.md (PF-TSK-065)** - Test validation, coverage gap analysis, registry/tracking population
- **Modified retrospective-documentation-creation.md (PF-TSK-066)** - Test spec gap closure guidance

### Phase 4 Outputs (Validation)
- **Validation script** - `Validate-TestTracking.ps1` (or Python equivalent) that checks registry against disk
- **Updated documentation-map.md** - All new artifacts listed

## 5. Artifact Dependency Map

### New Artifacts Created
| Artifact Type | Name | Purpose | Serves as Input For |
|---------------|------|---------|-------------------|
| Template | test-file-template.py | Python test file generation | New-TestFile.ps1 (Phase 1) |
| Template | cross-cutting-test-specification-template.md | Multi-feature test spec creation | Test Specification Creation task |
| Script | Validate-TestTracking.ps1 | Registry-to-disk consistency check | Test Audit task, CI pipeline |
| Directory | /test/specifications/cross-cutting-specs/ | Storage for cross-cutting specs | Test Specification Creation task |

### Dependencies on Existing Artifacts
| Required Artifact | Source | Usage |
|------------------|--------|-------|
| project-config.json | doc/process-framework/ | Language detection for template selection |
| test-file-template.dart | templates/templates/ | Reference pattern for Python template |
| test-registry.yaml | test/ | Schema extension target |
| test-implementation-tracking.md | state-tracking/permanent/ | Bulk population target |
| feature-tracking.md | state-tracking/permanent/ | Test Status column updates |
| New-TestFile.ps1 | scripts/file-creation/ | Script modification target |
| test-implementation-task.md | tasks/03-testing/ | Task genericization target |
| test-audit-task.md | tasks/03-testing/ | Task genericization target |
| integration-and-testing.md | tasks/04-implementation/ | Cross-cutting analysis addition target |
| codebase-feature-discovery.md | tasks/00-onboarding/ | Test file classification addition target |
| codebase-feature-analysis.md | tasks/00-onboarding/ | Test validation addition target |
| retrospective-documentation-creation.md | tasks/00-onboarding/ | Test spec gap closure addition target |

## 6. State Tracking Integration Strategy

### No New Permanent State Files Required
This extension enhances existing state files rather than creating new ones:
- **test-implementation-tracking.md** — Populated with existing test entries
- **feature-tracking.md** — Test Status column updated
- **test-registry.yaml** — Populated with test file entries

### Updates to Existing State Files
- **test-implementation-tracking.md**: Add ~15 entries for existing test files, pre-set to "Tests Implemented"
- **feature-tracking.md**: Update Test Status for features where tests are now registered
- **documentation-map.md**: Add new template and directory entries

### State Update Triggers
- **New test file created via New-TestFile.ps1**: Auto-adds to test-registry.yaml and test-implementation-tracking.md (existing behavior, now generic)
- **Cross-cutting spec created**: Manually added to cross-cutting-specs directory, linked from relevant feature specs
- **Validation script run**: Reports inconsistencies between registry and disk

## 7. Integration Points

| Integration Point | Current Framework Component | Integration Method |
|------------------|----------------------------|-------------------|
| Test file generation | New-TestFile.ps1 + test-file-template.dart | Add project-config.json reader, add Python template, select based on `primary_language` |
| Test specification workflow | PF-TSK-012 (Test Specification Creation) | Add reference to cross-cutting template as available option |
| Cross-cutting test analysis | PF-TSK-053 (Integration and Testing) | Add optional cross-cutting test identification guidance |
| Test implementation tracking | PF-TSK-029 + test-implementation-tracking.md | Remove hardcoded paths, make test types data-driven |
| Test audit workflow | PF-TSK-030 (Test Audit) | Remove hardcoded paths, keep evaluation criteria generic |
| Feature tracking | feature-tracking.md | Bulk update Test Status column for registered tests |
| Onboarding — file classification | PF-TSK-064 (Codebase Feature Discovery) | Add test file classification (source vs test vs cross-cutting) |
| Onboarding — test validation | PF-TSK-065 (Codebase Feature Analysis) | Add test validation, coverage analysis, registry population |
| Onboarding — gap closure | PF-TSK-066 (Retrospective Documentation) | Add test spec creation for identified gaps |

## 8. Implementation Roadmap

### Session 1: Genericization (High Priority)
**Focus**: Remove all tech-stack coupling from existing components

- [ ] Read and update New-TestFile.ps1 to read project-config.json for language detection
- [ ] Create test-file-template.py (Python/pytest equivalent)
- [ ] Update test-implementation-task.md — replace BB paths, make test types generic
- [ ] Update test-audit-task.md — replace BB paths
- [ ] Update test-implementation-tracking.md — remove Dart validation script references
- [ ] Verify all testing components work with LinkWatcher's Python/pytest stack

### Session 2: Cross-cutting Test Support + Existing Test Registration (High Priority)
**Focus**: Add cross-cutting capability and register LinkWatcher's existing tests

- [ ] Create cross-cutting-test-specification-template.md
- [ ] Create /test/specifications/cross-cutting-specs/ directory
- [ ] Extend test-registry.yaml schema with crossCuttingFeatures
- [ ] Add cross-cutting test analysis as optional guidance in PF-TSK-053
- [ ] Add cross-cutting template reference in PF-TSK-012
- [ ] Map all existing LinkWatcher test files to features
- [ ] Populate test-registry.yaml with all existing test entries
- [ ] Populate test-implementation-tracking.md with existing test entries
- [ ] Update feature-tracking.md Test Status column

### Session 3: Onboarding Integration, Validation & Finalization (Medium Priority)
**Focus**: Update onboarding tasks for test handling, create validation tooling, finalize

- [ ] Update PF-TSK-064 (Codebase Feature Discovery) — add test file classification
- [ ] Update PF-TSK-065 (Codebase Feature Analysis) — add test validation and registry population
- [ ] Update PF-TSK-066 (Retrospective Documentation Creation) — add test spec gap closure
- [ ] Create Validate-TestTracking.ps1 validation script
- [ ] Update documentation-map.md with all new artifacts
- [ ] Run validation to verify registry matches disk
- [ ] Update id-registry.json if any new prefixes needed
- [ ] Archive temporary state tracking file
- [ ] Complete feedback form

## 9. Success Criteria

### Functional Success Criteria
- [ ] **New-TestFile.ps1 generates Python test files** when project-config.json specifies `primary_language: "Python"`
- [ ] **Cross-cutting test specs** can be created and linked to multiple features
- [ ] **All existing 165+ test methods** are registered in test-registry.yaml
- [ ] **Validation script** confirms registry matches actual test files on disk
- [ ] **Onboarding tasks handle test files** — Discovery classifies, Analysis validates and populates tracking, Documentation closes gaps

### Integration Success Criteria
- [ ] **No BreakoutBuddies references** remain in any testing task, template, or script
- [ ] **No Dart/Flutter assumptions** remain in any generic testing component
- [ ] **project-config.json** is the single source of truth for tech-stack choices
- [ ] **Existing TEST_PLAN.md and TEST_CASE_STATUS.md** are preserved alongside framework tracking (not replaced)

### Quality Success Criteria
- [ ] **Zero regression**: Existing framework functionality unchanged for projects that use Dart
- [ ] **Test pipeline complete**: Spec → Implement → Audit workflow works end-to-end for Python/pytest
- [ ] **Cross-cutting specs documented**: At least one cross-cutting spec created as proof of concept
- [ ] **Feature traceability**: Every test file traceable to at least one feature ID

## 10. Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| New-TestFile.ps1 modification breaks Dart projects | High | Keep test-file-template.dart alongside .py; language selection is additive, not replacing |
| Bulk registration creates inconsistent IDs | Medium | Run validation script after registration to verify |
| Cross-cutting spec concept too complex | Low | Start with one proof-of-concept spec; simplify if needed |
| test-registry.yaml schema change breaks existing tooling | Medium | Schema extension is additive — new optional fields only |
| Onboarding task modifications break existing workflow | Medium | Changes are additive — new classification option alongside existing source file handling |
| PF-TSK-029/PF-TSK-053 overlap not resolved | Low | Noted as known issue; both tasks serve different workflow paths (test-first vs post-implementation). Resolution deferred to avoid scope creep |

## 11. Known Issues & Scope Boundaries

### PF-TSK-029 (Test Implementation) / PF-TSK-053 (Integration and Testing) Overlap

Both tasks create tests but serve different workflow paths:
- **PF-TSK-029** (03-testing): Test-first approach — creates tests from test specifications before implementation. Uses PD-TST IDs, auto-updates test-registry.yaml, test-implementation-tracking.md, and feature-tracking.md.
- **PF-TSK-053** (04-implementation): Post-implementation verification — creates integration tests after code is written. Part of the decomposed implementation chain. Currently bypasses all test tracking infrastructure (no PD-TST IDs, no registry updates).

**Decision**: This overlap is noted but NOT addressed by this extension. Merging or restructuring these tasks would risk breaking existing workflow paths and is out of scope. Cross-cutting test analysis is added to PF-TSK-053 as optional guidance; a more integrated approach can be evaluated in a future Process Improvement cycle.

---

## Human Review Checklist

**This concept requires human review before implementation can begin.**

### Concept Validation
- [ ] **Extension Necessity**: Confirm this requires framework extension vs. individual fixes
- [ ] **Scope Appropriateness**: Verify scope covers the right changes (not too broad/narrow)
- [ ] **Integration Feasibility**: Review integration points with existing framework
- [ ] **Resource Requirements**: Assess the 3-session implementation plan

### Technical Review
- [ ] **Workflow Definition**: Review the proposed Phase 1-4 process (including dual-track Phase 3)
- [ ] **Artifact Dependencies**: Validate which files are created vs. modified
- [ ] **State Tracking Strategy**: Approve the "enhance existing, no new state files" approach
- [ ] **Cross-cutting concept**: Approve the two-tier test specification model
- [ ] **Onboarding restructure**: Approve Discovery/Analysis/Documentation test handling split
- [ ] **Known issues**: Acknowledge PF-TSK-029/PF-TSK-053 overlap as deferred

### Approval Decision
- [ ] **APPROVED**: Concept is approved for implementation
- [ ] **NEEDS REVISION**: Concept needs changes before approval
- [ ] **REJECTED**: Concept is not suitable for framework extension

**Human Reviewer**: ___
**Review Date**: ___
**Decision**: ___
**Comments**: ___

---

*This concept document was created as part of the Framework Extension Task (PF-TSK-026).*
