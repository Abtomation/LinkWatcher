---
id: PF-INF-001
type: Process Framework
category: Infrastructure Analysis
version: 3.0
created: 2025-08-22
updated: 2026-04-02
purpose: Process Framework Task Registry
scope: All Process Framework Tasks with Scripts and Manual Updates
---

# Process Framework Task Registry

## Purpose

This document serves as the **comprehensive registry** of all process framework tasks, their automation scripts, and the files they update (both state tracking and other files). This registry provides complete visibility into:

- Which tasks have automation scripts vs. manual processes
- What files each task updates (state tracking, documentation, created artifacts)
- Where task outputs are stored
- Which tasks maintain this registry itself

## 🎯 Automation Status Summary

### ✅ Fully Automated Tasks (Script + State Updates)

- **FDD Creation Task** - Complete automation with feature tracking updates
- **TDD Creation Task** - Complete automation with feature tracking updates
- **System Architecture Review Task** - Complete automation with feature tracking and architecture tracking updates
- **Test Specification Creation Task** - Complete automation with feature tracking updates
- **ADR Creation Task** - Complete automation with architecture tracking, feature tracking, and documentation map updates
- **API Design Task** - Complete automation with feature tracking updates and automatic API specification linking
- **Database Schema Design Task** - Complete automation with feature tracking updates and DB Design column linking
- **UI/UX Design Task** - Complete automation with feature tracking updates and UI Design column linking
- **Technical Debt Assessment Task** - Complete automation with technical debt tracking updates and bidirectional linking system
- **E2E Acceptance Test Execution Task** - Full pipeline automation for scripted tests (Setup → Execute → Verify → Update tracking)

### 🔄 Semi-Automated Tasks (Script + Manual/Script Updates Required)

- **New Task Creation Process** - Script updates four documentation files including task registry (IMP-283)
- **Feature Tier Assessment Task** - Requires running `Update-FeatureTrackingFromAssessment.ps1` after assessment creation
- **Integration & Testing Task** - Script creates files and initial state updates, requires manual completion status updates
- **Test Audit Task** - Manual audit judgment, automated state updates with intelligent feature-level aggregation
- **Bug Triage Task** - Manual bug evaluation with automated state updates via `Update-BugStatus.ps1`
- **Bug Fixing Task** - Manual bug resolution with automated status lifecycle management via `Update-BugStatus.ps1`
- **Feature Request Evaluation** - Manual classification with scripted state file creation (`Update-FeatureRequest.ps1`, `New-EnhancementState.ps1`)
- **Feature Enhancement** - Manual enhancement steps with automated finalization via `Finalize-Enhancement.ps1`
- **Feature Implementation Planning** - Manual planning with scripted plan/state file creation
- **E2E Acceptance Test Case Creation** - Script creates structure; test case content is manual
- **Project Initiation** - Human provides data; `New-TestInfrastructure.ps1` scaffolds infrastructure
- **Codebase Feature Discovery** - Manual analysis with scripted state file creation
- **Retrospective Documentation Creation** - Reuses existing design doc scripts; validation automated

### 🔄 Semi-Automated Tasks (Manual Process + Automated Validation)

- **Feature Implementation Task** (⚠️ DEPRECATED) - Manual coding with automated quality validation and bug discovery integration
- **Foundation Feature Implementation Task** - Manual foundational coding with comprehensive automated validation and bug discovery integration
- **Code Refactoring Task** - Manual refactoring with scripted planning (`New-RefactoringPlan.ps1`) and tech debt management

### 🔧 Manual Tasks (No Automation)

- **Code Review Task** - Manual code analysis with quality assurance and bug discovery integration
- **Release Deployment Task** - Manual deployment coordination with validation and bug discovery integration
- **UI Implementation** - Manual UI component and screen implementation
- **State Management Implementation** - Manual state layer implementation
- **Quality Validation** - Manual quality auditing across multiple dimensions
- **Implementation Finalization** - Manual deployment preparation and state file archival
- **Validation Preparation** - Manual feature/dimension selection and validation planning
- **Codebase Feature Analysis** - Manual deep analysis with partial test registration automation
- **Framework Domain Adaptation** - Manual domain-specific terminology migration

### 🚨 Critical Automation Gaps Identified

1. **Feature Tier Assessment**: Requires separate script execution for state updates
2. **Integration & Testing Task (PF-TSK-053)**: Requires manual status updates after test completion

## State File Update Frequency Analysis

### Critical Files (Updated by Multiple Tasks)

| State File                                                                                          | Update Count        | Automation Priority |
| --------------------------------------------------------------------------------------------------- | ------------------- | ------------------- |
| [Feature Tracking](../../doc/state-tracking/permanent/feature-tracking.md)                                 | 25+ tasks           | **CRITICAL**        |
| [Bug Tracking](../../doc/state-tracking/permanent/bug-tracking.md)                                         | 10+ tasks           | **HIGH**            |
| [Test Tracking](../../test/state-tracking/permanent/test-tracking.md)         | 6 tasks             | **HIGH**            |
| [Architecture Tracking](../../doc/state-tracking/permanent/architecture-tracking.md)                       | 4 tasks             | **HIGH**            |
| Feature Implementation State Files                                                                   | 10+ tasks           | **HIGH**            |
| [E2E Test Tracking](../../test/state-tracking/permanent/e2e-test-tracking.md)                              | 3 tasks             | **HIGH**            |
| [Feature Request Tracking](../../doc/state-tracking/permanent/feature-request-tracking.md)                 | 2 tasks             | **MEDIUM**          |
| [User Workflow Tracking](../../doc/state-tracking/permanent/user-workflow-tracking.md)                      | 3 tasks             | **MEDIUM**          |
| [Technical Debt Tracking](../../doc/state-tracking/permanent/technical-debt-tracking.md)                   | 3 tasks             | **MEDIUM**          |
| Pytest Markers (via [test_query.py](/process-framework/scripts/test/test_query.py))                               | 2 tasks             | **MEDIUM**          |
| [Documentation Map](../PF-documentation-map.md)                                                        | 6+ validation tasks | **MEDIUM**          |
| [Validation Tracking](../../doc/state-tracking/temporary/validation/archive/validation-tracking-1.md) | 11 validation tasks | **MEDIUM**          |

## Task Catalog

### **SETUP TASKS**

#### **S1. Project Initiation** ([PF-TSK-059](../tasks/00-setup/project-initiation-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Human provides project data; scripts scaffold infrastructure)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-TestInfrastructure.ps1`](../scripts/file-creation/00-setup/New-TestInfrastructure.ps1)
- **Output Directory:** Project root (`project-config.json`), `languages-config/`, `test/`
- **Auto-Update Function:** Scaffolds test directory structure, tracking files, and TE-id-registry from project-config.json

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `project-config.json` | Manual | Project configuration with name, language, paths, features list |
| **Creates** | `languages-config/{language}/{language}-config.json` | Manual | Language-specific command configurations for testing, linting, coverage |
| **Creates** | `test/` directory structure | `New-TestInfrastructure.ps1` | Test directories, tracking files, TE-id-registry.json |
| **Creates** | [`user-workflow-tracking.md`](../../doc/state-tracking/permanent/user-workflow-tracking.md) | Manual | User workflow to feature mapping |
| **Creates** | CI/CD infrastructure (optional) | Manual | Pipeline configs, pre-commit hooks, dev scripts |

**🎯 KEY IMPACTS**

- **Primary output:** Project configuration and test infrastructure scaffolding
- **Enables next steps:** Codebase Feature Discovery (existing projects), Feature Discovery (new projects)
- **Dependencies:** None — this is the starting point for new projects or framework adoption

#### **S2. Codebase Feature Discovery** ([PF-TSK-064](../tasks/00-setup/codebase-feature-discovery.md))

**🔧 Process Type:** 🔧 **Manual with Script Support** (Human analyzes code; scripts create tracking structure)

**📋 AUTOMATION DETAILS**

- **Scripts:** [`New-RetrospectiveMasterState.ps1`](../scripts/file-creation/00-setup/New-RetrospectiveMasterState.ps1), [`New-FeatureImplementationState.ps1`](../scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1)
- **Output Directory:** `doc/state-tracking/features/`, `process-framework/state-tracking/temporary/`
- **Auto-Update Function:** Scripts create state files; feature tracking requires manual updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Retrospective Master State File | `New-RetrospectiveMasterState.ps1` | Tracks 3-phase retrospective onboarding progress |
| **Creates** | Feature Implementation State Files (multiple) | `New-FeatureImplementationState.ps1` | One per discovered feature in `doc/state-tracking/features/` |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Add discovered features with initial status |
| **Updates** | [`user-workflow-tracking.md`](../../doc/state-tracking/permanent/user-workflow-tracking.md) | Manual | Map features to user workflows |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Populates feature inventory from existing codebase
- **Enables next steps:** Codebase Feature Analysis (PF-TSK-065)
- **Dependencies:** Requires Project Initiation (PF-TSK-059) or existing project-config.json

#### **S3. Codebase Feature Analysis** ([PF-TSK-065](../tasks/00-setup/codebase-feature-analysis.md))

**🔧 Process Type:** 🔧 **Manual with Partial Automation** (Deep analysis is manual; test registration partially automated)

**📋 AUTOMATION DETAILS**

- **Scripts:** [`test_query.py`](../scripts/test/test_query.py), [`New-TestFile.ps1`](../scripts/file-creation/03-testing/New-TestFile.ps1)
- **Output Directory:** Feature state files in `doc/state-tracking/features/`
- **Auto-Update Function:** Test file registration automated; analysis is manual

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | Feature Implementation State Files | Manual | Enriched with design decisions, dependencies, test coverage analysis |
| **Updates** | [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) | `New-TestFile.ps1` | Register existing test files with pytest markers |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Update Test Status column |
| **Updates** | Retrospective Master State File | Manual | Mark Phase 2 progress |

**🎯 KEY IMPACTS**

- **Primary state file:** Feature Implementation State Files - Enriched with implementation analysis
- **Secondary coordination:** [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) - Existing tests registered
- **Enables next steps:** Retrospective Documentation Creation (PF-TSK-066)
- **Dependencies:** Requires Codebase Feature Discovery (PF-TSK-064)

#### **S4. Retrospective Documentation Creation** ([PF-TSK-066](../tasks/00-setup/retrospective-documentation-creation.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Uses existing design doc scripts; validation automated)

**📋 AUTOMATION DETAILS**

- **Scripts:** Reuses design task scripts (`New-FDD.ps1`, `New-tdd.ps1`, `New-TestSpecification.ps1`, `New-ArchitectureDecision.ps1`, etc.)
- **Validation Script:** [`Validate-StateTracking.ps1`](../scripts/validation/Validate-StateTracking.ps1)
- **Output Directory:** Various (`doc/functional-design/fdds/`, `doc/technical/tdd/`, `doc/technical/adr/`, `test/specifications/`)

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | FDDs, TDDs, ADRs, Test Specifications | Existing design scripts | Tier-appropriate design documents for each discovered feature |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Design scripts | Tier assignments, document links, status progression |
| **Updates** | [`documentation-map.md`](../PF-documentation-map.md) | Design scripts | New documents registered |
| **Updates** | Retrospective Master State File | Manual | Archive upon completion |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Completes retrospective documentation workflow
- **Enables next steps:** Normal development workflow (implementation, validation, etc.)
- **Dependencies:** Requires Codebase Feature Analysis (PF-TSK-065)

### **DISCRETE TASKS**

#### **1. Feature Tier Assessment Task** ([PF-TSK-002](../tasks/01-planning/feature-tier-assessment-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script creates files, requires update script execution)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-Assessment.ps1`](../scripts/file-creation/01-planning/New-Assessment.ps1)
- **Output Directory:** [`assessments/`](../../doc/documentation-tiers/assessments)
- **Auto-Update Function:** **REQUIRES** running [`Update-FeatureTrackingFromAssessment.ps1`](../scripts/update/Update-FeatureTrackingFromAssessment.ps1)

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[ART-ASS-XXX]-[FeatureId]-[feature-name].md` | `New-Assessment.ps1` | Assessment document with tier analysis |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `Update-FeatureTrackingFromAssessment.ps1` | Status: "⬜ Not Started" → "📊 Assessment Created"<br/>• Add tier emoji (🔵/🟠/🔴)<br/>• Set API Design: "Yes"/"No"<br/>• Set DB Design: "Yes"/"No"<br/>• Link to assessment document<br/>**⚠️ MUST run update script after assessment creation** |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Initiates feature documentation workflow
- **Enables next steps:** FDD Creation (Tier 2+), TDD Creation (all tiers)
- **Dependencies:** Requires feature discovery completion

#### **2. FDD Creation Task** ([PF-TSK-027](../tasks/02-design/fdd-creation-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-FDD.ps1`](../scripts/file-creation/02-design/New-FDD.ps1)
- **Output Directory:** [`fdds/`](../../doc/functional-design/fdds)
- **Auto-Update Function:** Built-in automated feature tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `fdd-[feature-id]-[feature-name].md` | `New-FDD.ps1` | Functional design document with requirements and specifications |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-FDD.ps1` | Status: "📊 Assessment Created" → "📋 FDD Created"<br/>• Add FDD document link in FDD column<br/>• Add FDD creation date to Notes |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Advances feature documentation workflow
- **Enables next steps:** TDD Creation, Feature Implementation
- **Dependencies:** Requires Feature Tier Assessment (Tier 2+ features only)

#### **3. TDD Creation Task** ([PF-TSK-015](../tasks/02-design/tdd-creation-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-tdd.ps1`](../scripts/file-creation/02-design/New-tdd.ps1)
- **Output Directory:** [`tdd/`](../../doc/technical/tdd)
- **Auto-Update Function:** Built-in automated feature tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `tdd-[FeatureId]-[feature-name]-t[Tier].md` | `New-tdd.ps1` | Technical design document with architecture and implementation details |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-tdd.ps1` | Status: "📋 FDD Created" (Tier 2+) or "📊 Assessment Created" (Tier 1) → "📝 TDD Created"<br/>• Add TDD link in Tech Design column<br/>• Add TDD creation date to Notes column |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Completes technical design phase
- **Enables next steps:** Test Specification Creation, API Design, Database Schema Design
- **Dependencies:** Requires Feature Tier Assessment, optionally FDD Creation (Tier 2+)

#### **4. Test Specification Creation Task** ([PF-TSK-012](../tasks/03-testing/test-specification-creation-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-TestSpecification.ps1`](../scripts/file-creation/03-testing/New-TestSpecification.ps1)
- **Output Directory:** [`feature-specs/`](../../test/specifications/feature-specs)
- **Auto-Update Function:** Built-in automated feature tracking updates via `Update-DocumentTrackingFiles`

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `test-spec-[FeatureId]-[FeatureName].md` | `New-TestSpecification.ps1` | Comprehensive test specification document |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-TestSpecification.ps1` | Status: "🏗️ Architecture Reviewed" → "📋 Specs Created"<br/>• Add Test Spec link in Test Spec column<br/>• Add specification creation date to Notes |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Updates feature test status
- **Enables next steps:** Integration & Testing Task (PF-TSK-053)
- **Dependencies:** Requires System Architecture Review completion

#### **5. Integration & Testing Task** ([PF-TSK-053](../tasks/04-implementation/integration-and-testing.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script creates files and initial state updates, manual completion required)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-TestFile.ps1`](../scripts/file-creation/03-testing/New-TestFile.ps1)
- **Output Directory:** [`test/`](../../test) (various subdirectories)
- **Auto-Update Function:** Built-in automated initial state tracking via `Update-TestImplementationStatus`
- **Validation Script:** [`Validate-TestTracking.ps1`](../scripts/validation/Validate-TestTracking.ps1)
- **Manual Updates Required:** Test completion status, test case counts after implementation

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Test files (multiple) | `New-TestFile.ps1` | Test files in appropriate test directories with pytest markers (feature, priority, test_type) |
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) | `New-TestFile.ps1` | Status: "📝 Specification Created" → "🟡 Implementation In Progress"<br/>• Add test file links with correct relative paths<br/>• Use filename as display name<br/>• Update test cases count, last updated date, notes |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-TestFile.ps1` | Update Test Status based on implementation progress<br/>• Automatic status mapping from test implementation to feature tracking<br/>• Coordinate status across multiple state files |
| **Updates** | Feature Implementation State File (if applicable) | Manual | Test implementation details, coverage metrics, and testing notes |

**🎯 KEY IMPACTS**

- **Primary state file:** [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) - Tracks implementation progress with clickable file links
- **Secondary coordination:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Updates feature test status
- **Pytest markers:** Written into test files as single source of truth (query via `test_query.py`)
- **Bug discovery integration:** Includes systematic bug identification during test development with standardized reporting via `New-BugReport.ps1`
- **Manual completion required:** Status updates from 🟡 Implementation In Progress to 🔄 Ready for Validation, test case counts
- **Enables next steps:** Test Audit Task, Quality Validation (PF-TSK-054), Bug Triage (for discovered bugs)
- **Dependencies:** Requires feature implementation completion; Test Specification (if exists) provides test blueprint

#### **6. Test Audit Task** ([PF-TSK-030](../tasks/03-testing/test-audit-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual audit judgment, automated state updates)

**📋 AUTOMATION DETAILS**

- **Report Script:** [`New-TestAuditReport.ps1`](../scripts/file-creation/03-testing/New-TestAuditReport.ps1)
- **State Update Script:** [`Update-TestFileAuditState.ps1`](../scripts/update/Update-TestFileAuditState.ps1)
- **Output Directory:** [`test/audits/`](../../test/audits)
- **Auto-Update Function:** **FULLY AUTOMATED** state file updates with intelligent aggregation

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[TE-TAR-XXX]-[feature-id]-[test-file-id].md` | `New-TestAuditReport.ps1` | Test audit report with quality assessment and recommendations |
| **Updates** | [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) | `New-TestAuditReport.ps1` | Appends audit report link in Notes column for the target test file (preserves Test File/Case) |
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) | `Update-TestFileAuditState.ps1` | **AUTOMATED**: Update individual test file audit status with comprehensive details<br/>• Audit status (✅ Tests Approved/🔴 Audit Failed/🔄 Needs Update)<br/>• Detailed audit results (passed/failed test counts)<br/>• Auditor information and major findings<br/>• Audit date and completion timestamp |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `Update-TestFileAuditState.ps1` | **AUTOMATED**: Intelligent aggregated test status calculation<br/>• 🔴 Tests Failed Audit (any test fails)<br/>• 🟡 Tests Partially Approved (mixed statuses)<br/>• ✅ Tests Approved (all tests approved)<br/>• Last audit date tracking |

**🎯 KEY IMPACTS**

- **Primary state file:** [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) - Quality gate for test completion with automated audit tracking
- **Intelligent aggregation:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Automated feature-level test status based on all test files
- **Quality assurance:** Validates test implementation meets standards with comprehensive audit trail
- **Bug discovery integration:** Includes comprehensive bug identification during audit process with standardized reporting via `New-BugReport.ps1`
- **Enables next steps:** Feature Implementation (if tests approved), Bug Triage (for discovered bugs)
- **Dependencies:** Requires Test Implementation completion

#### **7. Feature Implementation Task** (PF-TSK-004) — ⚠️ DEPRECATED

> **DEPRECATED**: PF-TSK-004 has been replaced by the decomposed implementation tasks (PF-TSK-044, PF-TSK-051, PF-TSK-052, PF-TSK-053, PF-TSK-054, PF-TSK-055, PF-TSK-056). For new feature implementation, start with [Feature Implementation Planning (PF-TSK-044)](../tasks/04-implementation/feature-implementation-planning-task.md). For enhancements to existing features, use [Feature Request Evaluation (PF-TSK-067)](../tasks/01-planning/feature-request-evaluation.md) → [Feature Enhancement (PF-TSK-068)](../tasks/04-implementation/feature-enhancement.md).

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual implementation with automated quality validation)

**📋 AUTOMATION DETAILS**

- **Implementation Script:** No automation script (manual coding)
- **Validation Scripts:**
  - [`Quick-ValidationCheck.ps1`](../scripts/validation/Quick-ValidationCheck.ps1) - Fast health check
  - [`Run-FoundationalValidation.ps1`](../scripts/validation/Run-FoundationalValidation.ps1) - Code quality validation for selected features
- **Output Directory:** `scripts/validation/validation-reports/`
- **Auto-Update Function:** Automated quality validation reporting

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Validation reports | [`Quick-ValidationCheck.ps1`](../scripts/validation/Quick-ValidationCheck.ps1) | Quick health check reports (console/JSON/CSV output) |
| **Creates** | Quality validation reports | [`Run-FoundationalValidation.ps1`](../scripts/validation/Run-FoundationalValidation.ps1) | Code quality validation reports for selected features |
| **Creates** | `[api-name]-docs.md` (API features only) | Manual | API Consumer Documentation with usage examples and integration guidance |
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Update implementation status (🟡 In Progress/🔄 Needs Revision/🟢 Completed)<br/>• Add implementation start and completion dates<br/>• Link to relevant pull request or commit<br/>• **API Design column**: Manually add consumer documentation link for API features<br/>• Document design deviations with justification |
| **Updates** | [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) | Manual | Update test implementation status during development<br/>• Change status based on implementation progress |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Core feature development tracking
- **Quality validation:** Automated validation ensures implementation meets quality standards
- **API consumer documentation:** Creates post-implementation consumer documentation for API features with working examples
- **Architecture impact:** Updates component relationships and dependencies
- **Bug discovery integration:** Includes systematic bug identification during Quality Assurance phase with standardized reporting via `New-BugReport.ps1`
- **Enables next steps:** Code Review Task, Bug Fixing (if needed), Bug Triage (for discovered bugs)
- **Dependencies:** Requires Test Audit approval, completed design documents
- **⚠️ Automation Enhancement:** Now includes automated quality validation with reporting

#### **7a. Data Layer Implementation Task** ([PF-TSK-051](../tasks/04-implementation/data-layer-implementation.md))

**🔧 Process Type:** 🔧 **Manual Task** (No automation)

**📋 AUTOMATION DETAILS**

- **Script:** None (manual implementation)
- **Output Directory:** `/lib/data/models/[feature]/`, `/lib/data/repositories/[feature]/`, `/test/unit/data/[feature]/`
- **Auto-Update Function:** None

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Data model classes | Manual | Model classes in source data directory with serialization, validation |
| **Creates** | Repository interface | Manual | Repository contract in source repositories directory |
| **Creates** | Repository implementation | Manual | Concrete repository implementation |
| **Creates** | Unit tests | Manual | Test files in `/test/unit/data/[feature]/` for models and repositories |
| **Executes** | Database migrations | Manual | Run database migration scripts to create database schema |
| **Updates** | [Feature Implementation State File](../state-tracking/permanent/feature-[feature-id]-implementation.md) | Manual | Update task sequence tracking, code inventory, implementation notes, issues log |

**🎯 KEY IMPACTS**

- **Primary state file:** Feature Implementation State File - Tracks data layer implementation progress within multi-task feature workflow
- **Code artifacts:** Creates foundational data access layer for feature (models, repositories, database integration)
- **Dependencies:** Provides data access interfaces for state management layer
- **Enables next steps:** State Management Implementation Task (PF-TSK-056), Integration & Testing
- **Prerequisites:** Feature Implementation Planning Task (PF-TSK-044), Database Schema Design completed, migrations prepared

#### **7b. Core Logic Implementation Task** ([PF-TSK-078](../tasks/04-implementation/core-logic-implementation.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual implementation with automated test tracking)

**📋 AUTOMATION DETAILS**

- **Script:** None (manual implementation)
- **Test File Creation:** [`New-TestFile.ps1`](../scripts/file-creation/03-testing/New-TestFile.ps1) - Creates tracked unit test files with pytest markers
- **Bug Reporting:** [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1) - Documents bugs discovered during implementation
- **Output Directory:** Project source directories (feature-dependent)

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Source modules | Manual | Core business logic modules in project source directory |
| **Creates** | Integration wiring | Manual | CLI commands, service registrations, event hooks |
| **Creates** | Unit tests | `New-TestFile.ps1` | Tracked test files with pytest markers in project test directory |
| **Creates** | Bug reports (if applicable) | `New-BugReport.ps1` | Bug reports for issues not fixed in this session |
| **Updates** | [Feature Implementation State Files](../../doc/state-tracking/features) | Manual | Code inventory, task sequence, implementation notes, issues log |
| **Updates** | [Feature Tracking](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Status → 🧪 Testing |
| **Updates** | [Test Tracking](../../test/state-tracking/permanent/test-tracking.md) | `New-TestFile.ps1` | Automated test file links and status |
| **Updates** | [Bug Tracking](../../doc/state-tracking/permanent/bug-tracking.md) | Manual | Bug entries if bugs discovered (optional) |

**🎯 KEY IMPACTS**

- **Primary state file:** Feature Implementation State File - Tracks core logic implementation progress within multi-task feature workflow
- **Code artifacts:** Creates core business logic modules, integration wiring, and tracked unit tests
- **Dependencies:** May depend on Data Layer Implementation (PF-TSK-051) for data access
- **Enables next steps:** Integration & Testing (PF-TSK-053), Quality Validation (PF-TSK-054)
- **Prerequisites:** Feature Implementation Planning (PF-TSK-044), design documentation (TDD/FDD if Tier 2+)

#### **8. Foundation Feature Implementation Task** ([PF-TSK-024](../tasks/04-implementation/foundation-feature-implementation-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual implementation with automated validation)

**📋 AUTOMATION DETAILS**

- **Implementation Script:** No automation script (manual coding)
- **Validation Scripts:**
  - [`Quick-ValidationCheck.ps1`](../scripts/validation/Quick-ValidationCheck.ps1) - Fast health check
  - [`Run-FoundationalValidation.ps1`](../scripts/validation/Run-FoundationalValidation.ps1) - Comprehensive validation
- **Output Directory:** `scripts/validation/validation-reports/`
- **Auto-Update Function:** Automated validation reporting and tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Validation reports | [`Quick-ValidationCheck.ps1`](../scripts/validation/Quick-ValidationCheck.ps1) | Quick health check reports (console/JSON/CSV output) |
| **Creates** | Comprehensive validation reports | [`Run-FoundationalValidation.ps1`](../scripts/validation/Run-FoundationalValidation.ps1) | Detailed validation reports in `scripts/validation/validation-reports/` |
| **Updates** | [`validation-tracking.md`](../../doc/state-tracking/temporary/validation/archive/validation-tracking-1.md) | [`Run-FoundationalValidation.ps1`](../scripts/validation/Run-FoundationalValidation.ps1) | Update validation matrix with report creation dates and links |
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | `architecture-context-packages.md` (deleted) | Manual | Update with new architectural foundations and component relationships |
| **Updates** | [`architecture-tracking.md`](../../doc/state-tracking/permanent/architecture-tracking.md) | Manual | Record foundation implementation and architectural evolution<br/>• Update component status and key decisions |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Update with foundation feature completion status |

**🎯 KEY IMPACTS**

- **Primary state file:** [`architecture-tracking.md`](../../doc/state-tracking/permanent/architecture-tracking.md) - Tracks foundational architectural changes
- **Secondary coordination:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Updates feature completion status
- **Validation integration:** Automated feature validation ensures implementation meets architectural standards
- **Quality assurance:** Comprehensive validation across all 6 validation types (Architectural, Code Quality, Integration, Documentation, Extensibility, AI Agent Continuity)
- **Architecture foundation:** Establishes core architectural components and patterns
- **Bug discovery integration:** Includes systematic bug identification during Finalization phase for architectural and foundation issues with standardized reporting via `New-BugReport.ps1`
- **Enables next steps:** Dependent feature implementations, architectural reviews, Bug Triage (for discovered bugs)
- **Dependencies:** Requires architectural design decisions and planning
- **⚠️ Automation Enhancement:** Now includes automated validation with comprehensive reporting

#### **9. ADR Creation Task** ([PF-TSK-028](../tasks/02-design/adr-creation-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-ArchitectureDecision.ps1`](../scripts/file-creation/02-design/New-ArchitectureDecision.ps1)
- **Output Directory:** [`adr/`](../../doc/technical/adr)
- **Auto-Update Function:** `Update-DocumentTrackingFiles` + Script updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[kebab-case-title].md` | `New-ArchitectureDecision.ps1` | Architecture Decision Record with context, decision, and consequences |
| **Updates** | [`architecture-tracking.md`](../../doc/state-tracking/permanent/architecture-tracking.md) | `New-ArchitectureDecision.ps1` | Update with new architectural decision and its impact<br/>• Record decision context and consequences |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-ArchitectureDecision.ps1` | Update ADR column for related features with link to created ADR |
| **Updates** | [`documentation-map.md`](../PF-documentation-map.md) | `New-ArchitectureDecision.ps1` | Add new ADR to appropriate architecture decisions section based on document ID pattern |

**🎯 KEY IMPACTS**

- **Primary state file:** [`architecture-tracking.md`](../../doc/state-tracking/permanent/architecture-tracking.md) - Records architectural decisions
- **Secondary coordination:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Links decisions to features
- **Documentation registry:** Updates ADR documentation map
- **Enables next steps:** Feature Implementation with architectural guidance
- **Dependencies:** Requires architectural analysis and decision-making

#### **10. API Design Task** ([PF-TSK-020](../tasks/02-design/api-design-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-APISpecification.ps1`](../scripts/file-creation/02-design/New-APISpecification.ps1)
- **Additional Script:** [`New-APIDataModel.ps1`](../scripts/file-creation/02-design/New-APIDataModel.ps1)
- **Output Directory:** [`specifications/`](../../doc/technical/api/specifications/specifications) + [`models/`](../../doc/technical/api/models)
- **Auto-Update Function:** Built-in automated feature tracking updates with intelligent replacement/append logic

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[api-name].md` | `New-APISpecification.ps1` | API specification document with comprehensive contract definition |
| **Creates** | `[api-name]-request.md` | `New-APIDataModel.ps1` | Request data model with validation rules and examples |
| **Creates** | `[api-name]-response.md` | `New-APIDataModel.ps1` | Response data model with complete structure and field definitions |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-APISpecification.ps1` | **AUTOMATED**: Replace "Yes" with first API specification link<br/>• Intelligent replacement: "Yes" → clickable API specification link<br/>• Additional specifications appended with " • " separator<br/>• Correct relative path generation and timestamped automation notes |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-APIDataModel.ps1` | **AUTOMATED**: Append data model links with intelligent logic<br/>• Appends data model links with " • " separator to existing API Design column content<br/>• Automatic relative path calculation and timestamped automation notes |
| **Updates** | [`technical-debt-tracking.md`](../../doc/state-tracking/permanent/technical-debt-tracking.md) | Manual | Record API design decisions that create technical debt |
| **Updates** | `api-models-registry.md` (deleted) | Manual | Add entries for all newly created data models and update "Used By Features" for reused models |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - **FULLY AUTOMATED** API design completion tracking
- **Design-time focus:** Creates contract-first API specifications and data models before implementation
- **Technical debt tracking:** Documents design trade-offs and future improvements (manual)
- **Data models registry:** Maintains registry of all API data models (manual)
- **Enables next steps:** TDD Creation, Test Specification Creation, Feature Implementation
- **Dependencies:** Requires Feature Tier Assessment indicating "Yes" in API Design column

#### **11. Database Schema Design Task** ([PF-TSK-021](../tasks/02-design/database-schema-design-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-SchemaDesign.ps1`](../scripts/file-creation/02-design/New-SchemaDesign.ps1)
- **Output Directory:** [`schemas/`](../../doc/technical/database/schemas) + [`migrations/`](../../doc/technical/database/migrations) + [`diagrams/`](../../doc/technical/database/diagrams)
- **Auto-Update Function:** Built-in automated feature tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[feature-name]-schema-design.md` | `New-SchemaDesign.ps1` | Complete database schema design document with comprehensive data model specification |
| **Creates** | Migration scripts (multiple) | `New-SchemaDesign.ps1` | Database migration files for schema changes with rollback procedures |
| **Creates** | ERD diagrams (multiple) | `New-SchemaDesign.ps1` | Entity-relationship diagrams for visual schema representation |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-SchemaDesign.ps1` | Update DB Design column from "Yes" to link to completed schema design<br/>• Add schema design document link in DB Design column<br/>• Add schema design creation date to Notes |
| **Updates** | [`technical-debt-tracking.md`](../../doc/state-tracking/permanent/technical-debt-tracking.md) | Manual | Add schema optimization opportunities identified during design |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Completes database design requirement with automated state updates
- **Technical debt tracking:** [`technical-debt-tracking.md`](../../doc/state-tracking/permanent/technical-debt-tracking.md) Documents schema optimization opportunities (manual update required)
- **Database evolution:** Creates migration scripts for schema changes
- **Enables next steps:** Feature Implementation with database support
- **Dependencies:** Requires TDD completion and tier assessment with DB Design = "Yes"
- **📋 Multi-file creation:** Creates design document + migrations + diagrams

#### **12. UI/UX Design Task** (PF-TSK-043 — task file not present in this project)

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-UIDesign.ps1`](../scripts/file-creation/02-design/New-UIDesign.ps1)
- **Output Directory:** [`design/ui-ux/`](../../doc/technical/design/ui-ux) with subdirectories:
  - `design-system/` - Design system documentation
  - `mockups/` - UI mockups and high-fidelity designs
  - `wireframes/` - Low-fidelity wireframes
  - `user-flows/` - User flow diagrams
- **Auto-Update Function:** Built-in automated feature tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PD-UIX-XXX]-[feature-name]-[type].md` | `New-UIDesign.ps1` | UI/UX design document (design-system, mockup, wireframe, or user-flow) with comprehensive visual specifications |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-UIDesign.ps1` | Update UI Design column from "TBD" to link to completed UI design<br/>• Add UI design document link in UI Design column<br/>• Add design creation date to Notes |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Completes UI/UX design requirement with automated state updates
- **Design consistency:** Ensures visual design standards are documented before implementation
- **User experience planning:** Creates user flows and interaction patterns
- **Implementation guidance:** Provides clear design specifications for developers
- **Enables next steps:** Feature Implementation with UI/UX design support
- **Dependencies:** Requires TDD completion and feature assessment
- **📋 Multi-type creation:** Creates design documents across 4 design types (design-system, mockup, wireframe, user-flow)

#### **13. Code Review Task** ([PF-TSK-005](../tasks/06-maintenance/code-review-task.md))

**🔧 Process Type:** 🔧 **Manual Process** (No automation - requires human code analysis)

**📋 AUTOMATION DETAILS**

- **Script:** No automation script
- **Output Directory:** N/A
- **Auto-Update Function:** Manual updates only

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Update code review status (🟢 Completed/🔄 Needs Revision)<br/>• Add review date, reviewer information<br/>• Link to review document, list major findings |
| **Updates** | [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) | Manual | Update test status based on review findings<br/>• Confirm "✅ Tests Implemented" or change to "🔴 Tests Failing"/"🔄 Needs Update" |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Quality gate for feature completion
- **Test validation:** Confirms test implementation quality and coverage
- **Quality assurance:** Validates code meets standards and requirements
- **Bug discovery integration:** Includes systematic bug identification during code review with standardized reporting via `New-BugReport.ps1`
- **Enables next steps:** Release Deployment (if approved), Bug Fixing (if issues found), Bug Triage (for discovered bugs)
- **Dependencies:** Requires Feature Implementation completion
- **⚠️ Automation Gap:** Medium-priority candidate for automated code quality checks

#### **14. Bug Triage Task** ([PF-TSK-041](../tasks/06-maintenance/bug-triage-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual evaluation with automated state updates)

**📋 AUTOMATION DETAILS**

- **Script:** [`Update-BugStatus.ps1`](../scripts/update/Update-BugStatus.ps1)
- **Output Directory:** N/A (updates existing state files)
- **Auto-Update Function:** Automated bug status transitions and state tracking

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) | [`Update-BugStatus.ps1`](../scripts/update/Update-BugStatus.ps1) | Update bug status from 🆕 Reported to 🔍 Triaged<br/>• Automated priority (P1-P4) and scope (S/M/L) assignments<br/>• Automated status emoji updates (🔍 Triaged)<br/>• Automated timestamp and notes updates<br/>• Auto-moves bugs between active/Closed sections on Close/Reopen<br/>**Usage:** `.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Triaged" -Priority "High" -Scope "S"` |

**🎯 KEY IMPACTS**

- **Primary state file:** [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) - Central bug registry and prioritization with automated state management
- **Quality gate:** Ensures bugs are properly evaluated before development resources are allocated
- **Resource allocation:** Provides priority-based assignment recommendations
- **Enables next steps:** Bug Fixing (for triaged bugs), Feature Implementation (if bugs reveal feature gaps)
- **Dependencies:** Requires bug reports from users, testing, or code review

#### **15. Bug Fixing Task** ([PF-TSK-007](../tasks/06-maintenance/bug-fixing-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual coding with automated status lifecycle management)

**📋 AUTOMATION DETAILS**

- **Script:** [`Update-BugStatus.ps1`](../scripts/update/Update-BugStatus.ps1)
- **State Tracking Script:** [`New-BugFixState.ps1`](../scripts/file-creation/06-maintenance/New-BugFixState.ps1) (conditional — Large-effort or architectural bugs only)
- **Output Directory:** [`temporary/`](../state-tracking/temporary/) (for multi-session bug fix state files)
- **Auto-Update Function:** Automated bug status transitions through complete lifecycle

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) | [`Update-BugStatus.ps1`](../scripts/update/Update-BugStatus.ps1) | Update bug status through lifecycle:<br/>• 🔍 Triaged → 🔧 In Progress → 🧪 Testing → ✅ Fixed → 🟢 Closed<br/>• Automated status emoji updates and timestamp tracking<br/>• Automated notes management and metadata tracking<br/>• Automated fix details, root cause, and PR linking<br/>• **Closure automation**: auto-moves bug to Closed Bugs section, recalculates Bug Statistics<br/>**Usage Examples:**<br/>• Start: `.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress"`<br/>• Complete: `.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Fixed" -FixDetails "Details" -RootCause "Cause" -TestsAdded "Yes" -PullRequestUrl "URL"`<br/>• Close: `.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Closed" -VerificationNotes "Verified in production"` |

**🎯 KEY IMPACTS**

- **Primary state file:** [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) - Tracks bug resolution progress through complete lifecycle with automated state management
- **Quality improvement:** Resolves identified issues and defects systematically
- **Enables next steps:** Testing (🧪), Code Review, Bug Verification, Release Deployment
- **Dependencies:** Requires triaged bugs from Bug Triage Task
- **Integration:** Works with all development tasks that perform bug discovery

#### **16. Code Refactoring Task** ([PF-TSK-022](../tasks/06-maintenance/code-refactoring-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Scripts create planning files and conditional temporary state tracking, manual implementation with comprehensive state updates)

**📋 AUTOMATION DETAILS**

- **Planning Script:** [`New-RefactoringPlan.ps1`](../scripts/file-creation/06-maintenance/New-RefactoringPlan.ps1) (supports `-Lightweight` and `-DocumentationOnly` switches)
- **Templates:** Standard ([`refactoring-plan-template.md`](../templates/06-maintenance/refactoring-plan-template.md)), Documentation-only ([`documentation-refactoring-plan-template.md`](../templates/06-maintenance/documentation-refactoring-plan-template.md)), or Lightweight ([`lightweight-refactoring-plan-template.md`](../templates/06-maintenance/lightweight-refactoring-plan-template.md))
- **State Tracking Script:** [`New-TempTaskState.ps1`](../scripts/file-creation/support/New-TempTaskState.ps1) (standard path only)
- **Bug Reporting Script:** [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1)
- **ADR Creation Script:** [`New-ArchitectureDecision.ps1`](../scripts/file-creation/02-design/New-ArchitectureDecision.ps1) (for architectural refactoring, standard path only)
- **Output Directory:** [`plans/`](../../doc/refactoring/plans), [`temporary/`](../state-tracking/temporary/)
- **Auto-Update Function:** Partial automation with comprehensive manual state updates
- **Effort Gate:** Step 1 classifies as Lightweight (≤15 min, single file, no architectural impact) or Standard

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | [`[PF-RFP-XXX]-[refactoring-scope].md`](/doc/refactoring/plans/) | [`New-RefactoringPlan.ps1`](../scripts/file-creation/06-maintenance/New-RefactoringPlan.ps1) | Detailed refactoring plan with scope, approach, and timeline |
| **Creates** | [`[PF-TTS-XXX]-[task-context].md`](../state-tracking/temporary/) | [`New-TempTaskState.ps1`](../scripts/file-creation/support/New-TempTaskState.ps1) | Work-in-progress tracking for refactoring sessions (conditional: ≥ 5 items or 3+ sessions; otherwise use refactoring plan's Implementation Tracking) |
| **Creates** | [`[PF-ADR-XXX]-[decision-title].md`](../architecture/adrs/) | [`New-ArchitectureDecision.ps1`](../scripts/file-creation/02-design/New-ArchitectureDecision.ps1) | Architecture Decision Records for architectural refactoring |
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) | [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1) | Add bugs discovered during refactoring with 4-tier severity decision matrix |
| **Updates** | [`technical-debt-tracking.md`](../../doc/state-tracking/permanent/technical-debt-tracking.md) | [`Update-TechDebt.ps1`](../scripts/update/Update-TechDebt.ps1) | Status transitions: Open → InProgress → Resolved/Rejected (auto-moves to Recently Resolved) |
| **Updates** | [`architecture-tracking.md`](../../doc/state-tracking/permanent/architecture-tracking.md) | Manual | Improve feature status (e.g., "🔄 Needs Revision" → "🧪 Testing") |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | For foundation features (0.x.x), document architectural improvements |
| **Updates** | [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) | Manual | Note test improvements or new test requirements |
| **Updates** | Product documentation (TDD, FDD, feature state file, test spec) | Manual | When refactoring changes module boundaries, interfaces, or design patterns (Step 12) |

**🎯 KEY IMPACTS**

- **Primary state file:** [`technical-debt-tracking.md`](../../doc/state-tracking/permanent/technical-debt-tracking.md) - Comprehensive 3-phase debt resolution tracking
- **Secondary coordination:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Updates feature quality status with clear progression path
- **Temporary state management:** Work-in-progress tracking (conditional: < 5 items use refactoring plan's Implementation Tracking section) with archival to [`temporary/old/`](../state-tracking/temporary/old/) if created
- **Bug discovery integration:** Systematic bug identification with 4-tier decision matrix (Critical/High/Medium/Low)
- **Architectural decision capture:** ADR creation for architectural refactoring with context package integration
- **Code quality improvement:** Reduces technical debt and improves maintainability with comprehensive state tracking
- **Enables next steps:** Testing phase for features with improved status, Bug Triage (for discovered bugs), Code Review
- **Dependencies:** Requires technical debt assessment and prioritization
- **⚠️ Enhanced Process:** Now includes comprehensive bug discovery workflow, ADR integration, and 3-phase state management

#### **17. Release Deployment Task** ([PF-TSK-008](../tasks/07-deployment/release-deployment-task.md))

**🔧 Process Type:** 🔧 **Manual Process** (No automation - deployment requires manual coordination)

**📋 AUTOMATION DETAILS**

- **Script:** No automation script
- **Output Directory:** N/A
- **Auto-Update Function:** Manual updates only

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Update deployment status for released features<br/>• Add release version and deployment date |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Tracks feature deployment status
- **Release coordination:** Manages feature releases and version tracking
- **Production deployment:** Moves features from development to production
- **Bug discovery integration:** Includes systematic bug identification during deployment validation with standardized reporting via `New-BugReport.ps1`
- **Enables next steps:** Post-deployment monitoring, user feedback collection, Bug Triage (for discovered bugs)
- **Dependencies:** Requires Code Review approval and successful testing
- **⚠️ Automation Gap:** Medium-priority candidate for deployment status automation

#### **18. User Documentation Creation** ([PF-TSK-081](../tasks/07-deployment/user-documentation-creation.md))

**🔧 Process Type:** 🤖 **Partially Automated** (Script creates handbook files and automates finalization state updates)

**📋 AUTOMATION DETAILS**

- **Creation Script:** [`New-Handbook.ps1`](../scripts/file-creation/07-deployment/New-Handbook.ps1)
- **Finalization Script:** [`Update-UserDocumentationState.ps1`](../scripts/update/Update-UserDocumentationState.ps1)
- **Output Directory:** [`doc/user/handbooks/`](../../doc/user/handbooks)
- **Auto-Update Function:** Auto-assigns PD-UGD IDs, creates handbook from template; finalization script updates feature state file and PF-documentation-map.md

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[handbook-name].md` in `doc/user/handbooks` | `New-Handbook.ps1` | User handbook document with auto-assigned PD-UGD-XXX ID |
| **Updates** | Feature implementation state file | `Update-UserDocumentationState.ps1` | Appends handbook row to Documentation Inventory table |
| **Updates** | [`documentation-map.md`](../PF-documentation-map.md) | `Update-UserDocumentationState.ps1` | Adds handbook entry under User Handbooks section |
| **Updates** | [`README.md`](../../doc/README.md) (if applicable) | Manual | Add handbook to documentation table |

**🎯 KEY IMPACTS**

- **Primary output:** User-facing handbook documents in `doc/user/handbooks`
- **Finalization automation:** `Update-UserDocumentationState.ps1` automates feature state file and PF-documentation-map.md updates
- **Triggered by:** Features with user-visible behavior changes (flagged in feature state files)
- **Enables next steps:** Release & Deployment
- **Dependencies:** Requires feature implementation complete and Code Review passed
- **Template:** [`handbook-template.md`](../templates/07-deployment/handbook-template.md) (PF-TEM-065)

#### **19. System Architecture Review** ([PF-TSK-019](../tasks/01-planning/system-architecture-review.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-ArchitectureAssessment.ps1`](../scripts/file-creation/02-design/New-ArchitectureAssessment.ps1)
- **Output Directory:** [`assessments/`](../../doc/technical/architecture/assessments)
- **Auto-Update Function:** Built-in automated feature tracking and architecture tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PD-AIA-XXX]-[feature-name]-architecture-impact-assessment.md` | `New-ArchitectureAssessment.ps1` | Architecture Impact Assessment document with system integration analysis |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `New-ArchitectureAssessment.ps1` | Status: "📋 FDD Created" → "🏗️ Architecture Reviewed"<br/>• Add Architecture Impact Assessment link in Arch Review column<br/>• Add architecture review completion date to Notes |
| **Updates** | [`architecture-tracking.md`](../../doc/state-tracking/permanent/architecture-tracking.md) | `New-ArchitectureAssessment.ps1` | Add new architecture impact entry with assessment details and cross-references |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Advances feature through architecture review phase
- **Secondary coordination:** [`architecture-tracking.md`](../../doc/state-tracking/permanent/architecture-tracking.md) - Tracks architectural decisions and impacts
- **Enables next steps:** Test Specification Creation, API Design, Database Schema Design
- **Dependencies:** Requires FDD Creation (Tier 2+ features) or TDD Creation (Tier 1 features)

#### **20. Feature Discovery Task** ([PF-TSK-013](../tasks/01-planning/feature-discovery-task.md))

**🔧 Process Type:** 🔧 **Manual Process** (No automation - requires business analysis and stakeholder input)

**📋 AUTOMATION DETAILS**

- **Script:** No automation script
- **Output Directory:** N/A
- **Auto-Update Function:** Manual updates only

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Add new feature entries with initial status "⬜ Not Started" |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Initiates feature development workflow
- **Requirements gathering:** Captures initial feature requirements and scope
- **Enables next steps:** Feature Tier Assessment Task
- **Dependencies:** Requires business requirements and stakeholder input
- **⚠️ Automation Gap:** Low-priority candidate for feature entry automation

#### **21. Feature Request Evaluation** ([PF-TSK-067](../tasks/01-planning/feature-request-evaluation.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Classification is manual; state file creation scripted)

**📋 AUTOMATION DETAILS**

- **Scripts:** [`Update-FeatureRequest.ps1`](../scripts/update/Update-FeatureRequest.ps1), [`New-EnhancementState.ps1`](../scripts/file-creation/04-implementation/New-EnhancementState.ps1)
- **Output Directory:** `doc/state-tracking/temporary/` (enhancement state files), `doc/state-tracking/features/` (new feature state files)
- **Auto-Update Function:** Feature request status transitions, feature tracking updates for enhancements

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Enhancement State Tracking File (enhancements) | `New-EnhancementState.ps1` | Scoped enhancement steps with Dimension Impact Assessment |
| **Creates** | Feature Implementation State File (new features) | `New-FeatureImplementationState.ps1` | For new features routed to Feature Tier Assessment |
| **Updates** | [`feature-request-tracking.md`](../../doc/state-tracking/permanent/feature-request-tracking.md) | `Update-FeatureRequest.ps1` | Request status: Submitted → Classified (New Feature/Enhancement) → Closed |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `Update-FeatureRequest.ps1` | For enhancements: adds enhancement status to existing feature entry |
| **Updates** | [`user-workflow-tracking.md`](../../doc/state-tracking/permanent/user-workflow-tracking.md) | Manual | Updated for new features that map to user workflows |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-request-tracking.md`](../../doc/state-tracking/permanent/feature-request-tracking.md) - Intake queue management
- **Routing function:** Classifies change requests and routes to correct workflow:
  - New features → Feature Tier Assessment (PF-TSK-002)
  - Enhancements → Feature Enhancement (PF-TSK-068) via Enhancement State Tracking File
- **Enables next steps:** Feature Tier Assessment (new features) or Feature Enhancement (enhancements)
- **Dependencies:** Requires feature request in feature-request-tracking.md

#### **22. Feature Implementation Planning** ([PF-TSK-044](../tasks/04-implementation/feature-implementation-planning-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Planning is manual; scripts create plan and state templates)

**📋 AUTOMATION DETAILS**

- **Scripts:** [`New-ImplementationPlan.ps1`](../scripts/file-creation/04-implementation/New-ImplementationPlan.ps1), [`New-FeatureImplementationState.ps1`](../scripts/file-creation/04-implementation/New-FeatureImplementationState.ps1)
- **Output Directory:** `doc/technical/implementation-plans/`, `doc/state-tracking/features/`
- **Auto-Update Function:** Scripts create templates; planning content is manual

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Implementation Plan Document (PD-IMP-XXX) | `New-ImplementationPlan.ps1` | Detailed implementation plan with task sequencing and dependency mapping |
| **Creates** | Feature Implementation State File | `New-FeatureImplementationState.ps1` | Permanent state file tracking feature implementation progress |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Links to implementation plan and feature state file |

**🎯 KEY IMPACTS**

- **Primary output:** Implementation Plan with sequenced tasks and dependency graph
- **Secondary output:** Feature Implementation State File for multi-session tracking
- **Enables next steps:** Data Layer Implementation (PF-TSK-051), Core Logic Implementation (PF-TSK-078), UI Implementation (PF-TSK-052)
- **Dependencies:** Requires completed design documents (TDD, FDD if Tier 2+, Test Specification)

#### **23. UI Implementation** ([PF-TSK-052](../tasks/04-implementation/ui-implementation.md))

**🔧 Process Type:** 🔧 **Manual Task** (No automation)

**📋 AUTOMATION DETAILS**

- **Script:** None (manual implementation)
- **Output Directory:** Project source directories (feature-dependent)
- **Auto-Update Function:** None

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | UI components, screens, navigation | Manual | Reusable components, layouts, route definitions |
| **Creates** | UI tests | Manual | Component and screen tests |
| **Updates** | Feature Implementation State File | Manual | Code Inventory and Implementation Progress sections |

**🎯 KEY IMPACTS**

- **Primary state file:** Feature Implementation State File - Tracks UI implementation progress
- **Code artifacts:** UI components, screen implementations, navigation configuration, UI tests
- **Enables next steps:** Integration & Testing (PF-TSK-053), State Management Implementation (PF-TSK-056)
- **Dependencies:** Requires Feature Implementation Planning (PF-TSK-044), UI/UX Design (if applicable)

#### **24. State Management Implementation** ([PF-TSK-056](../tasks/04-implementation/state-management-implementation.md))

**🔧 Process Type:** 🔧 **Manual Task** (No automation)

**📋 AUTOMATION DETAILS**

- **Script:** None (manual implementation)
- **Output Directory:** Project source directories (feature-dependent)
- **Auto-Update Function:** None

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | State model classes, containers, mutation handlers | Manual | State management layer connecting data to UI |
| **Creates** | State tests | Manual | Unit and integration tests for state management |
| **Updates** | Feature Implementation State File | Manual | Code Inventory and Implementation Progress sections |

**🎯 KEY IMPACTS**

- **Primary state file:** Feature Implementation State File - Tracks state management implementation
- **Code artifacts:** State models, containers/providers, mutation handlers, state tests
- **Enables next steps:** Integration & Testing (PF-TSK-053), UI Implementation (PF-TSK-052)
- **Dependencies:** Requires Data Layer Implementation (PF-TSK-051) for data access interfaces

#### **25. Quality Validation** ([PF-TSK-054](../tasks/04-implementation/quality-validation.md))

**🔧 Process Type:** 🔧 **Manual Task** (No automation — comprehensive quality auditing)

**📋 AUTOMATION DETAILS**

- **Script:** None (manual validation)
- **Output Directory:** N/A
- **Auto-Update Function:** None

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Quality Validation Report | Manual | Quality metrics, performance benchmarks, security audit, accessibility report |
| **Updates** | Feature Implementation State File | Manual | Validation results and quality status |

**🎯 KEY IMPACTS**

- **Primary state file:** Feature Implementation State File - Quality validation results
- **Quality gate:** Validates implementation against quality standards and business requirements
- **Enables next steps:** Implementation Finalization (PF-TSK-055)
- **Dependencies:** Requires Integration & Testing (PF-TSK-053) completion

#### **26. Implementation Finalization** ([PF-TSK-055](../tasks/04-implementation/implementation-finalization.md))

**🔧 Process Type:** 🔧 **Manual Task** (No automation — deployment preparation)

**📋 AUTOMATION DETAILS**

- **Script:** None (manual finalization)
- **Output Directory:** N/A
- **Auto-Update Function:** None

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Release notes, deployment checklist, rollback plan | Manual | Deployment preparation artifacts |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Status updated to "Ready for Deployment" or "Deployed" |
| **Updates** | Feature Implementation State File | Manual | Archived after 100% completion |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Feature reaches deployment-ready status
- **Enables next steps:** Release & Deployment (PF-TSK-008), User Documentation Creation (PF-TSK-081)
- **Dependencies:** Requires Quality Validation (PF-TSK-054) and Code Review (PF-TSK-005) approval

#### **27. Feature Enhancement** ([PF-TSK-068](../tasks/04-implementation/feature-enhancement.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Test runner automated; Finalize-Enhancement.ps1 orchestrates finalization)

**📋 AUTOMATION DETAILS**

- **Scripts:** [`Run-Tests.ps1`](../scripts/test/Run-Tests.ps1), [`Finalize-Enhancement.ps1`](../scripts/update/Finalize-Enhancement.ps1)
- **Output Directory:** N/A (modifies existing code and state files)
- **Auto-Update Function:** Finalize-Enhancement.ps1 restores feature tracking status and archives enhancement state file

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | Enhancement State Tracking File | Manual | Steps marked complete; archived upon finalization |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `Finalize-Enhancement.ps1` | Status restored (removes "🔄 Needs Revision") |
| **Updates** | Feature Implementation State File | Manual | Updated to reflect enhancement changes |
| **Updates** | [`test-tracking.md`](../../test/state-tracking/permanent/test-tracking.md) | Manual | Manual test groups set to "Needs Re-execution" |
| **Updates** | Design documents (FDD, TDD, ADR) | Manual | Amended to reflect enhancement scope |

**🎯 KEY IMPACTS**

- **Primary state file:** Enhancement State Tracking File - Drives step-by-step enhancement execution
- **Secondary coordination:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Status lifecycle management
- **Enables next steps:** Code Review (PF-TSK-005), User Documentation Creation (PF-TSK-081)
- **Dependencies:** Requires Enhancement State Tracking File from Feature Request Evaluation (PF-TSK-067)

#### **28. E2E Acceptance Test Case Creation** ([PF-TSK-069](../tasks/03-testing/e2e-acceptance-test-case-creation-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script creates structure; test case content is manual)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-E2EAcceptanceTestCase.ps1`](../scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1)
- **Output Directory:** `test/e2e-acceptance-testing/templates/<group>/`
- **Auto-Update Function:** Creates test case directories, updates tracking, integrates with master test files

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Test case directory: `E2E-NNN-<name>/` | `New-E2EAcceptanceTestCase.ps1` | Contains `test-case.md`, `project/`, `expected/`, optional `run.ps1` |
| **Creates** | Master test file (new groups) | `New-E2EAcceptanceTestCase.ps1` | `master-test-<group-name>.md` with quick validation sequences |
| **Updates** | [`e2e-test-tracking.md`](../../test/state-tracking/permanent/e2e-test-tracking.md) | `New-E2EAcceptanceTestCase.ps1` | New E2E acceptance test entries added |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Test Status updated |

**🎯 KEY IMPACTS**

- **Primary state file:** [`e2e-test-tracking.md`](../../test/state-tracking/permanent/e2e-test-tracking.md) - E2E test case inventory
- **Enables next steps:** E2E Acceptance Test Execution (PF-TSK-070)
- **Dependencies:** Requires cross-cutting Test Specification (TE-TSP) and user workflow milestones met

#### **29. E2E Acceptance Test Execution** ([PF-TSK-070](../tasks/03-testing/e2e-acceptance-test-execution-task.md))

**🔧 Process Type:** 🤖 **Fully Automated (scripted tests)** / 🔧 **Manual (non-scripted tests)**

**📋 AUTOMATION DETAILS**

- **Scripts:**
  - [`Setup-TestEnvironment.ps1`](../scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1) - Copies pristine fixtures to workspace
  - [`Run-E2EAcceptanceTest.ps1`](../scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) - Orchestrates scripted test pipeline
  - [`Verify-TestResult.ps1`](../scripts/test/e2e-acceptance-testing/Verify-TestResult.ps1) - Compares workspace against expected state
  - [`Update-TestExecutionStatus.ps1`](../scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1) - Updates tracking with results
  - [`New-BugReport.ps1`](../scripts/file-creation/06-maintenance/New-BugReport.ps1) - Creates bug reports for failures
- **Output Directory:** `test/e2e-acceptance-testing/results/`
- **Auto-Update Function:** Full pipeline automation for scripted tests (Setup → Execute → Verify → Update tracking)

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`e2e-test-tracking.md`](../../test/state-tracking/permanent/e2e-test-tracking.md) | `Update-TestExecutionStatus.ps1` | Execution status (✅ Pass / ❌ Fail) and Last Executed date |
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | `Update-TestExecutionStatus.ps1` | Test Status updated based on E2E results |
| **Updates** | [`bug-tracking.md`](../../doc/state-tracking/permanent/bug-tracking.md) | `New-BugReport.ps1` | Bug reports for test failures |

**🎯 KEY IMPACTS**

- **Primary state file:** [`e2e-test-tracking.md`](../../test/state-tracking/permanent/e2e-test-tracking.md) - Execution results tracking
- **Bug discovery:** Failures generate bug reports via `New-BugReport.ps1`
- **Enables next steps:** Bug Triage (for failures), Release & Deployment (for passes)
- **Dependencies:** Requires E2E Acceptance Test Case Creation (PF-TSK-069)

### **VALIDATION TASKS**

#### **V0. Validation Preparation** ([PF-TSK-077](../tasks/05-validation/validation-preparation.md))

**🔧 Process Type:** 🔧 **Semi-Automated** (Script creates tracking file, manual customization required)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-ValidationTracking.ps1`](../scripts/file-creation/05-validation/New-ValidationTracking.ps1)
- **Output Directory:** `doc/state-tracking/temporary/validation/`
- **Auto-Update Function:** ID registry only; feature×dimension matrix requires manual customization

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Validation Tracking State File | 🤖 Automated | Created via `New-ValidationTracking.ps1 -RoundNumber [N]` |
| **Updates** | [`documentation-map.md`](../PF-documentation-map.md) | Manual | Link to new validation tracking state file |

**🎯 KEY IMPACTS**

- **Entry point:** Required before any validation dimension tasks — selects features, evaluates dimension applicability, creates tracking
- **Primary output:** Validation Tracking State File with feature×dimension matrix and session sequence
- **Enables next steps:** All 11 validation dimension tasks (PF-TSK-031 through PF-TSK-076)
- **Dependencies:** Requires completed features ready for validation

#### **V1-V11. Validation Dimension Tasks** (11 tasks: Architectural Consistency, Code Quality Standards, Integration Dependencies, Documentation Alignment, Extensibility Maintainability, AI Agent Continuity, Security & Data Protection, Performance & Scalability, Observability, Accessibility / UX Compliance, Data Integrity)

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-ValidationReport.ps1`](../scripts/file-creation/05-validation/New-ValidationReport.ps1)
- **Output Directory:** [`reports/[validation-type]/`](../validation/reports/)
- **Auto-Update Function:** `Update-DocumentTrackingFiles`

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PF-VAL-XXX]-[validation-type]-features-[feature-range].md` | Script | Comprehensive validation report for specific validation type |
| **Updates** | [`validation-tracking.md`](../../doc/state-tracking/temporary/validation/archive/validation-tracking-1.md) | Auto | Update validation matrix with report creation date and link<br/>• Update specific validation type column for validated features |
| **Updates** | [`documentation-map.md`](../PF-documentation-map.md) | Auto | Add new validation report to validation reports section<br/>• Include report ID, path, and description |

**🎯 KEY IMPACTS**

- **Primary state file:** [`validation-tracking.md`](../../doc/state-tracking/temporary/validation/archive/validation-tracking-1.md) - Tracks validation completion across features
- **Documentation registry:** Updates validation report catalog
- **Quality assurance:** Validates features meet quality standards
- **Enables next steps:** Feature completion certification, release readiness
- **Dependencies:** Requires completed features for meaningful validation

**📋 VALIDATION TYPES:**

- **20. Architectural Consistency** ([PF-TSK-031](../tasks/05-validation/architectural-consistency-validation.md))
- **21. Code Quality Standards** ([PF-TSK-032](../tasks/05-validation/code-quality-standards-validation.md))
- **22. Integration Dependencies** ([PF-TSK-033](../tasks/05-validation/integration-dependencies-validation.md))
- **23. Documentation Alignment** ([PF-TSK-034](../tasks/05-validation/documentation-alignment-validation.md))
- **24. Extensibility Maintainability** ([PF-TSK-035](../tasks/05-validation/extensibility-maintainability-validation.md))
- **25. AI Agent Continuity** ([PF-TSK-036](../tasks/05-validation/ai-agent-continuity-validation.md))
- **26. Security & Data Protection** ([PF-TSK-072](../tasks/05-validation/security-data-protection-validation.md))
- **27. Performance & Scalability** ([PF-TSK-073](../tasks/05-validation/performance-scalability-validation.md))
- **28. Observability** ([PF-TSK-074](../tasks/05-validation/observability-validation.md))
- **29. Accessibility / UX Compliance** ([PF-TSK-075](../tasks/05-validation/accessibility-ux-compliance-validation.md))
- **30. Data Integrity** ([PF-TSK-076](../tasks/05-validation/data-integrity-validation.md))

### **SUPPORT TASKS**

#### **26. New Task Creation Process** ([PF-TSK-001](../tasks/support/new-task-creation-process.md))

**🔧 Process Type:** ✅ **Fully Automated** (Script creates files and updates all documentation files including task registry)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-Task.ps1`](../scripts/file-creation/support/New-Task.ps1)
- **Output Directory:** [`tasks/[task-type]/`](../tasks/)
- **Auto-Update Function:** **ENHANCED** - Script now handles four documentation file updates automatically (IMP-283)

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[kebab-case-task-name].md` | [`New-Task.ps1`](../scripts/file-creation/support/New-Task.ps1) | New task document with standardized structure |
| **Updates** | [`documentation-map.md`](../PF-documentation-map.md) | [`New-Task.ps1`](../scripts/file-creation/support/New-Task.ps1) | Add new task to appropriate task category section |
| **Updates** | [`tasks/README.md`](../tasks/README.md) | [`New-Task.ps1`](../scripts/file-creation/support/New-Task.ps1) | Add new task to task type table with flexible pattern matching |
| **Updates** | [`ai-tasks.md`](../ai-tasks.md) | [`New-Task.ps1`](../scripts/file-creation/support/New-Task.ps1) | Add new task to AI Tasks main entry point with correct section and table format |
| **Updates** | [`process-framework-task-registry.md`](process-framework-task-registry.md) | [`New-Task.ps1`](../scripts/file-creation/support/New-Task.ps1) | **NEW (IMP-283)**: Add skeleton entry to task registry — customize after task definition is complete |

**🎯 KEY IMPACTS**

- **Primary state file:** [`documentation-map.md`](../PF-documentation-map.md) - Updates task catalog
- **Process framework evolution:** Extends framework capabilities with new tasks
- **Enables next steps:** New task becomes immediately available in AI workflows
- **Dependencies:** Requires task analysis and design completion
- **✅ Automation Gap Closed (IMP-283):** Registry update now automated via New-Task.ps1; drift detected by Validate-StateTracking.ps1 Surface 9

#### **27. Process Improvement Task** ([PF-TSK-009](../tasks/support/process-improvement-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script automates tracking updates, manual implementation)

**📋 AUTOMATION DETAILS**

- **Creation Script:** [`New-ProcessImprovement.ps1`](../scripts/file-creation/support/New-ProcessImprovement.ps1)
- **Update Script:** [`Update-ProcessImprovement.ps1`](../scripts/update/Update-ProcessImprovement.ps1)
- **Output Directory:** N/A (updates in-place)
- **Auto-Update Function:** New entries with auto-assigned PF-IMP IDs; status transitions, completion moves, summary count, update history, frontmatter date

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`process-improvement-tracking.md`](../state-tracking/permanent/process-improvement-tracking.md) | Script | Status-only: updates Status and Last Updated columns in Current table<br/>Completion: moves row from Current to Completed, updates summary count, adds Update History entry |

**🔧 USAGE EXAMPLES**
```powershell
# Status-only update (e.g., Identified → In Progress)
.\Update-ProcessImprovement.ps1 -ImprovementId "IMP-051" -NewStatus "InProgress"

# Complete an improvement
.\Update-ProcessImprovement.ps1 -ImprovementId "IMP-063" -NewStatus "Completed" -Impact "MEDIUM" -ValidationNotes "Description of what was done."

# Reject an improvement
.\Update-ProcessImprovement.ps1 -ImprovementId "IMP-061" -NewStatus "Rejected" -Impact "—" -ValidationNotes "Reason for rejection."

# Preview changes without modifying
.\Update-ProcessImprovement.ps1 -ImprovementId "IMP-051" -NewStatus "InProgress" -WhatIf
```

**🎯 KEY IMPACTS**

- **Primary state file:** [`process-improvement-tracking.md`](../state-tracking/permanent/process-improvement-tracking.md) - Tracks improvement initiatives
- **Incremental implementation:** Requires explicit human approval at each checkpoint
- **Upstream dependency:** Improvements are identified and prioritized by the Tools Review Task (PF-TSK-010)
- **Enables next steps:** No next steps; completes cycle
- **Dependencies:** Requires prioritized improvement in process-improvement-tracking.md

#### **28. Framework Extension Task** ([PF-TSK-026](../tasks/support/framework-extension-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script creates concept files, manual implementation)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-FrameworkExtensionConcept.ps1`](../scripts/file-creation/support/New-FrameworkExtensionConcept.ps1)
- **Output Directory:** [`proposals/`](../proposals/)
- **Auto-Update Function:** Manual updates only

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Framework extension concept document | [`New-FrameworkExtensionConcept.ps1`](../scripts/file-creation/support/New-FrameworkExtensionConcept.ps1) | Detailed concept document for framework extension |
| **Updates** | Multiple process framework files (varies) | Manual | Updates vary based on extension scope |

**🎯 KEY IMPACTS**

- **Framework evolution:** Extends process framework with new capabilities
- **Concept documentation:** Creates structured proposals for framework changes
- **Strategic planning:** Guides framework development and enhancement
- **Enables next steps:** Framework implementation and integration
- **Dependencies:** Requires framework analysis and extension design
- **⚠️ Automation Gap:** Low-priority candidate for extension tracking

#### **29. Structure Change Task** ([PF-TSK-014](../tasks/support/structure-change-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script creates state tracking, manual implementation)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-StructureChangeState.ps1`](../scripts/file-creation/support/New-StructureChangeState.ps1)
- **Output Directory:** [`temporary/`](../state-tracking/temporary/)
- **Auto-Update Function:** Manual updates only

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Structure change state document | Script | Tracks structural changes and their impact |
| **Updates** | Multiple state tracking files (varies) | Manual | Updates vary based on structural changes |

**🎯 KEY IMPACTS**

- **Structure evolution:** Manages changes to framework and documentation structure
- **Change tracking:** Documents structural modifications and their rationale
- **Impact management:** Coordinates updates across affected files and processes
- **Enables next steps:** Structural implementation and validation
- **Dependencies:** Requires structural analysis and change planning
- **⚠️ Automation Gap:** Medium-priority candidate for change impact automation

#### **30. Tools Review Task** ([PF-TSK-010](../tasks/support/tools-review-task.md))

**🔧 Process Type:** 🔧 **Partially Automated** (Review summary creation automated, tool evaluation manual)

**📋 AUTOMATION DETAILS**

- **Review Script:** [`New-ReviewSummary.ps1`](../scripts/file-creation/06-maintenance/New-ReviewSummary.ps1) — Creates review summary documents with auto-assigned ART-REV IDs
- **Improvement Script:** [`New-ProcessImprovement.ps1`](../scripts/file-creation/support/New-ProcessImprovement.ps1) — Adds improvement entries with auto-assigned PF-IMP IDs
- **Output Directory:** `process-framework/feedback/reviews`
- **Auto-Update Function:** Review summary creation and improvement entry creation automated; tool evaluation manual

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `process-framework/feedback/reviews/tools-review-YYYYMMDD.md` | Script | Review summary from template (PF-TEM-046) |
| **Updates** | [`process-improvement-tracking.md`](../state-tracking/permanent/process-improvement-tracking.md) | Script | Adds new improvement entries via New-ProcessImprovement.ps1 |

**🎯 KEY IMPACTS**

- **Tool optimization:** Evaluates and improves development and documentation tools
- **Efficiency improvement:** Identifies better tools and workflows
- **Technology evolution:** Keeps framework aligned with current best practices
- **Enables next steps:** Process Improvement Task
- **Dependencies:** Requires Feedback Forms

#### **31. Framework Evaluation Task** ([PF-TSK-079](../tasks/support/framework-evaluation.md))

**🔧 Process Type:** 🔧 **Partially Automated** (Report creation automated via script, evaluation analysis manual)

**📋 AUTOMATION DETAILS**

- **Report Script:** [`New-FrameworkEvaluationReport.ps1`](../scripts/file-creation/support/New-FrameworkEvaluationReport.ps1) — Creates evaluation report documents with auto-assigned PF-EVR IDs
- **Improvement Script:** [`New-ProcessImprovement.ps1`](../scripts/file-creation/support/New-ProcessImprovement.ps1) — Adds improvement entries with auto-assigned PF-IMP IDs
- **Output Directory:** `process-framework/evaluation-reports`
- **Auto-Update Function:** Report creation and IMP entry creation automated; dimension evaluation manual

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `process-framework/evaluation-reports/YYYYMMDD-framework-evaluation-{scope}.md` | Script | Evaluation report from template (PF-TEM-064) |
| **Updates** | [`process-improvement-tracking.md`](../state-tracking/permanent/process-improvement-tracking.md) | Script | Adds improvement entries via New-ProcessImprovement.ps1 |

**🎯 KEY IMPACTS**

- **Framework quality:** Structurally evaluates process framework across 7 dimensions (Completeness, Consistency, Redundancy, Accuracy, Effectiveness, Automation Coverage, Scalability)
- **Flexible scope:** Can target full framework, specific phases, component types, workflows, or targeted artifact sets
- **Improvement pipeline:** Findings registered as IMP entries for Process Improvement Task follow-up
- **Enables next steps:** Process Improvement Task, Structure Change Task, New Task Creation Process
- **Dependencies:** Requires Documentation Map and AI Tasks System as evaluation entry points

#### **32. Framework Domain Adaptation** ([PF-TSK-080](../tasks/support/framework-domain-adaptation.md))

**🔧 Process Type:** 🔧 **Manual Task** (No automation — systematic domain migration)

**📋 AUTOMATION DETAILS**

- **Script:** None (manual migration)
- **Output Directory:** N/A (modifies existing framework documents)
- **Auto-Update Function:** None

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | Framework documents (multiple) | Manual | Domain-specific terminology translations, adapted templates, updated references |
| **Deletes** | Obsolete domain-specific documents | Manual | Removes documents no longer applicable to new domain |

**🎯 KEY IMPACTS**

- **Framework evolution:** Adapts process framework to new project domains
- **Terminology alignment:** Translates domain-specific terms across all framework documents
- **Cross-reference integrity:** Updates all internal references after domain adaptation
- **Enables next steps:** Normal framework usage in adapted domain
- **Dependencies:** Requires understanding of both source and target domains

### **CYCLICAL TASKS**

#### **32. Technical Debt Assessment Task** ([PF-TSK-023](../tasks/cyclical/technical-debt-assessment-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Scripts create assessment files with bidirectional linking system and automatic registry integration)

**📋 AUTOMATION DETAILS**

- **Assessment Script:** [`New-TechnicalDebtAssessment.ps1`](../scripts/file-creation/cyclical/New-TechnicalDebtAssessment.ps1)
- **Prioritization Matrix Script:** [`New-PrioritizationMatrix.ps1`](../scripts/file-creation/cyclical/New-PrioritizationMatrix.ps1) - Creates standalone impact vs. effort prioritization matrices
- **Debt Item Script:** [`New-DebtItem.ps1`](../scripts/file-creation/cyclical/New-DebtItem.ps1) - **ENHANCED** with assessment linking and automation guidance
- **Registry Update Script:** [`Update-TechDebt.ps1`](../scripts/update/Update-TechDebt.ps1) - Individual debt item management (Add, StatusUpdate, Resolve)
- **Assessment Integration Script:** [`Update-TechnicalDebtFromAssessment.ps1`](../scripts/update/Update-TechnicalDebtFromAssessment.ps1) - **NEW** bulk assessment processing
- **Output Directory:** `assessments/technical-debt/` (not yet created)
- **Auto-Update Function:** **FULLY AUTOMATED** bidirectional linking and registry integration

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PF-TDA-XXX]-[assessment-name].md` | `New-TechnicalDebtAssessment.ps1` | Technical debt assessment document with systematic evaluation and prioritization matrix |
| **Creates** | `[PF-TDI-XXX]-[item-title].md` (multiple) | `New-DebtItem.ps1` | Individual debt item records with **assessment linking** and automation command guidance<br/>• Include `-AssessmentId` parameter for traceability<br/>• Auto-populate assessment reference and registry integration fields<br/>• Provide ready-to-use automation commands |
| **Updates** | [`technical-debt-tracking.md`](../../doc/state-tracking/permanent/technical-debt-tracking.md) | [`Update-TechnicalDebtFromAssessment.ps1`](../scripts/update/Update-TechnicalDebtFromAssessment.ps1) | **FULLY AUTOMATED REGISTRY INTEGRATION:**<br/>• Automatically add new debt items with TD### IDs<br/>• Auto-reference assessment ID (PF-TDA-XXX) in Assessment ID column<br/>• Create bidirectional traceability between registry and assessments<br/>• **Usage:** `.\Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PF-TDA-XXX"` |
| **Updates** | Individual debt item files | [`Update-TechDebt.ps1`](../scripts/update/Update-TechDebt.ps1) | **AUTOMATED REGISTRY INTEGRATION:**<br/>• Auto-update Registry Status: "Not Added" → "Added"<br/>• Auto-assign TD### Registry ID<br/>• Mark items as integrated into permanent tracking system<br/>• Maintain bidirectional linking automatically |

**🎯 KEY IMPACTS**

- **Primary state file:** [`technical-debt-tracking.md`](../../doc/state-tracking/permanent/technical-debt-tracking.md) - **FULLY AUTOMATED** technical debt inventory with assessment traceability
- **Enhanced traceability:** **AUTOMATED** bidirectional linking between assessments, debt items, and registry entries
- **Code quality management:** Identifies and prioritizes technical debt for resolution with systematic assessment methodology
- **Strategic planning:** Informs refactoring and improvement priorities with detailed impact analysis
- **Prevents duplicates:** **AUTOMATED** linking system ensures debt items are properly tracked and not duplicated
- **Workflow efficiency:** **ELIMINATED** manual registry integration bottleneck - assessment findings automatically integrated
- **Enables next steps:** Code Refactoring Task (using prioritized debt items from assessment)
- **Dependencies:** Requires codebase analysis and technical expertise
- **Integration workflow:** **FULLY AUTOMATED** process for moving assessment findings into permanent tracking system
- **⚠️ AUTOMATION BREAKTHROUGH:** Task moved from Semi-Automated to Fully Automated with new registry integration scripts

#### **33. Documentation Tier Adjustment Task** ([PF-TSK-011](../tasks/cyclical/documentation-tier-adjustment-task.md))

**🔧 Process Type:** 🔧 **Manual Process** (No automation — requires complexity re-evaluation)

**📋 AUTOMATION DETAILS**

- **Script:** None (manual evaluation)
- **Output Directory:** N/A
- **Auto-Update Function:** None

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Adjust tier classification when complexity changes during implementation |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../../doc/state-tracking/permanent/feature-tracking.md) - Tier reclassification
- **Triggered by:** Complexity changes discovered during implementation
- **Enables next steps:** Additional design documentation (if tier increases) or documentation reduction (if tier decreases)
- **Dependencies:** Requires active implementation revealing complexity mismatch

---

## Script Inventory

Complete catalog of all automation scripts in `process-framework/scripts/`. Scripts are organized by function: file creation, state updates, validation, testing, and utilities.

### File Creation Scripts

| Script | Location | Used By Task(s) | Purpose |
|--------|----------|------------------|---------|
| `New-Assessment.ps1` | `file-creation/01-planning/` | PF-TSK-002 | Create tier assessment documents |
| `New-FeatureRequest.ps1` | `file-creation/01-planning/` | PF-TSK-067 | Add feature requests to feature-request-tracking.md |
| `New-FDD.ps1` | `file-creation/02-design/` | PF-TSK-027, PF-TSK-066 | Create Functional Design Documents |
| `New-tdd.ps1` | `file-creation/02-design/` | PF-TSK-015, PF-TSK-066 | Create Technical Design Documents |
| `New-ArchitectureDecision.ps1` | `file-creation/02-design/` | PF-TSK-028, PF-TSK-022, PF-TSK-066 | Create Architecture Decision Records |
| `New-ArchitectureAssessment.ps1` | `file-creation/02-design/` | PF-TSK-019 | Create Architecture Impact Assessments |
| `New-APISpecification.ps1` | `file-creation/02-design/` | PF-TSK-020 | Create API specification documents |
| `New-APIDataModel.ps1` | `file-creation/02-design/` | PF-TSK-020 | Create API data model documents |
| `New-SchemaDesign.ps1` | `file-creation/02-design/` | PF-TSK-021 | Create database schema design documents |
| `New-UIDesign.ps1` | `file-creation/02-design/` | PF-TSK-043 | Create UI/UX design documents |
| `New-ContextMap.ps1` | `file-creation/02-design/` | PF-TSK-001 (indirect) | Create context map visualizations for tasks |
| `New-TestSpecification.ps1` | `file-creation/03-testing/` | PF-TSK-012, PF-TSK-066 | Create test specifications (feature-specific and cross-cutting) |
| `New-TestFile.ps1` | `file-creation/03-testing/` | PF-TSK-053, PF-TSK-065, PF-TSK-078 | Create tracked test files with pytest markers |
| `New-TestAuditReport.ps1` | `file-creation/03-testing/` | PF-TSK-030 | Create test audit reports |
| `New-E2EAcceptanceTestCase.ps1` | `file-creation/03-testing/` | PF-TSK-069 | Create E2E acceptance test case directories |
| `New-ImplementationPlan.ps1` | `file-creation/04-implementation/` | PF-TSK-044 | Create implementation plan documents |
| `New-FeatureImplementationState.ps1` | `file-creation/04-implementation/` | PF-TSK-044, PF-TSK-064, PF-TSK-067 | Create feature implementation state files |
| `New-EnhancementState.ps1` | `file-creation/04-implementation/` | PF-TSK-067 | Create enhancement state tracking files |
| `New-ValidationReport.ps1` | `file-creation/05-validation/` | PF-TSK-031–036, PF-TSK-072–076 | Create validation reports |
| `New-ValidationTracking.ps1` | `file-creation/05-validation/` | PF-TSK-077 | Create validation tracking state files |
| `Generate-ValidationSummary.ps1` | `file-creation/05-validation/` | PF-TSK-077 (indirect) | Generate validation round summaries |
| `New-BugReport.ps1` | `file-creation/06-maintenance/` | Multiple tasks | Create standardized bug reports |
| `New-BugFixState.ps1` | `file-creation/06-maintenance/` | PF-TSK-007 | Create multi-session bug fix state tracking files |
| `New-RefactoringPlan.ps1` | `file-creation/06-maintenance/` | PF-TSK-022 | Create refactoring plans (standard, lightweight, documentation-only, performance) |
| `New-ReviewSummary.ps1` | `file-creation/06-maintenance/` | PF-TSK-010 | Create tools review summary documents |
| `New-Handbook.ps1` | `file-creation/07-deployment/` | PF-TSK-081 | Create user handbook documents |
| `New-TestInfrastructure.ps1` | `file-creation/00-setup/` | PF-TSK-059 | Bootstrap test directory structure from project-config.json |
| `New-RetrospectiveMasterState.ps1` | `file-creation/00-setup/` | PF-TSK-064 | Create retrospective master state for framework adoption |
| `New-Task.ps1` | `file-creation/support/` | PF-TSK-001 | Create new task definitions |
| `New-Template.ps1` | `file-creation/support/` | PF-TSK-001 (indirect) | Create new templates |
| `New-Guide.ps1` | `file-creation/support/` | PF-TSK-001 (indirect) | Create new guides |
| `New-FeedbackForm.ps1` | `file-creation/support/` | All tasks (mandatory) | Create feedback forms for task completion |
| `New-TempTaskState.ps1` | `file-creation/support/` | PF-TSK-022, PF-TSK-009 | Create temporary task state tracking files |
| `New-PermanentState.ps1` | `file-creation/support/` | Various | Create permanent state tracking files |
| `New-StructureChangeState.ps1` | `file-creation/support/` | PF-TSK-014 | Create structure change state tracking files |
| `New-StructureChangeProposal.ps1` | `file-creation/support/` | PF-TSK-014 | Create structure change proposal documents |
| `New-FrameworkExtensionConcept.ps1` | `file-creation/support/` | PF-TSK-026 | Create framework extension concept documents |
| `New-FrameworkEvaluationReport.ps1` | `file-creation/support/` | PF-TSK-079 | Create framework evaluation reports |
| `New-ProcessImprovement.ps1` | `file-creation/support/` | PF-TSK-010, PF-TSK-079 | Add improvement entries to process-improvement-tracking.md |
| `New-TechnicalDebtAssessment.ps1` | `file-creation/cyclical/` | PF-TSK-023 | Create technical debt assessment documents |
| `New-DebtItem.ps1` | `file-creation/cyclical/` | PF-TSK-023 | Create individual debt item records |
| `New-PrioritizationMatrix.ps1` | `file-creation/cyclical/` | PF-TSK-023 | Create technical debt prioritization matrices |
| `New-APIDocumentation.ps1` | `file-creation/02-design/` | PF-TSK-020 | Create user-facing API documentation |

### State Update Scripts

| Script | Location | Used By Task(s) | Purpose |
|--------|----------|------------------|---------|
| `Update-FeatureTrackingFromAssessment.ps1` | `update/` | PF-TSK-002 | Update feature-tracking.md from assessment results |
| `Update-FeatureRequest.ps1` | `update/` | PF-TSK-067 | Classify/close feature requests, update feature-tracking.md |
| `Update-BugStatus.ps1` | `update/` | PF-TSK-041, PF-TSK-007 | Bug status lifecycle management |
| `Update-TestFileAuditState.ps1` | `update/` | PF-TSK-030 | Update test tracking with audit results |
| `Update-ProcessImprovement.ps1` | `update/` | PF-TSK-009 | Process improvement status transitions |
| `Update-TechDebt.ps1` | `update/` | PF-TSK-022, PF-TSK-023 | Tech debt status management (Add, StatusUpdate, Resolve) |
| `Update-TechnicalDebtFromAssessment.ps1` | `update/` | PF-TSK-023 | Bulk assessment→registry integration |
| `Finalize-Enhancement.ps1` | `update/` | PF-TSK-068 | Restore feature tracking status, archive enhancement state |
| `Update-UserDocumentationState.ps1` | `update/` | PF-TSK-081 | Update feature state file and PF-documentation-map.md for handbooks |
| `Update-FeatureImplementationState.ps1` | `update/` | PF-TSK-044, PF-TSK-078 | Update feature implementation state files programmatically |
| `Update-CodeReviewState.ps1` | `update/` | PF-TSK-005 | Update code review state in feature tracking |
| `Update-ValidationReportState.ps1` | `update/` | PF-TSK-031–036, PF-TSK-072–076 | Update validation tracking from report results |
| `Update-BatchFeatureStatus.ps1` | `update/` | Multiple | Batch update feature statuses across feature-tracking.md |
| `Update-FeatureDependencies.ps1` | `update/` | Validate-StateTracking.ps1 | Auto-generate feature-dependencies.md (Mermaid graph + matrix) |
| `Update-WorkflowTracking.ps1` | `update/` | PF-TSK-064, PF-TSK-067 | Update user-workflow-tracking.md feature statuses |
| `Update-LanguageConfig.ps1` | `update/` | Infrastructure | Add fields to all language config files consistently |
| `Update-ScriptReferences.ps1` | `update/` | Infrastructure | Update script path references across documentation |
| `Archive-Feature.ps1` | `update/` | PF-TSK-055 (indirect) | Archive completed feature state files |

### Validation Scripts

| Script | Location | Used By Task(s) | Purpose |
|--------|----------|------------------|---------|
| `Validate-StateTracking.ps1` | `validation/` | PF-TSK-066, multiple | Master validation: 9 surfaces (feature links, state files, test tracking, cross-refs, ID counters, dependencies, dimensions, workflows, task registry) |
| `Validate-TestTracking.ps1` | `validation/` | PF-TSK-053 | Validate pytest markers vs test-tracking.md and disk |
| `Validate-IdRegistry.ps1` | `validation/` | Infrastructure | Validate ID registry against actual files |
| `Validate-FeedbackForms.ps1` | `validation/` | PF-TSK-010 | Validate feedback form completeness |
| `Validate-AuditReport.ps1` | `validation/` | PF-TSK-030 | Validate audit report structure and content |
| `Quick-ValidationCheck.ps1` | `validation/` | PF-TSK-004, PF-TSK-024 | Fast health check (console/JSON/CSV output) |
| `Run-FoundationalValidation.ps1` | `validation/` | PF-TSK-004, PF-TSK-024 | Comprehensive code quality validation |

### Testing Scripts

| Script | Location | Used By Task(s) | Purpose |
|--------|----------|------------------|---------|
| `Run-Tests.ps1` | `test/` | PF-TSK-068, multiple | Language-agnostic test runner (-Category, -Quick, -All, -Coverage) |
| `Setup-TestEnvironment.ps1` | `test/e2e-acceptance-testing/` | PF-TSK-070 | Copy pristine fixtures to workspace |
| `Run-E2EAcceptanceTest.ps1` | `test/e2e-acceptance-testing/` | PF-TSK-070 | Orchestrate scripted E2E test pipeline |
| `Verify-TestResult.ps1` | `test/e2e-acceptance-testing/` | PF-TSK-070 | Compare workspace vs expected state |
| `Update-TestExecutionStatus.ps1` | `test/e2e-acceptance-testing/` | PF-TSK-070 | Update tracking with E2E execution results |
| `test_query.py` | `test/` | PF-TSK-065, PF-TSK-053 | AST-based query tool for pytest markers |
| `feedback_db.py` | `.` | PF-TSK-010 (indirect) | Feedback database recording and querying |

### Orchestration & Utility Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `Start-AutomationMenu.ps1` | `.` | Interactive menu for all automation scripts |
| `Start-BatchAudit.ps1` | `.` | Orchestrate batch test audit sessions |
| `Start-BatchValidation.ps1` | `.` | Orchestrate batch validation sessions |
| `Add-MarkdownTableColumn.ps1` | `.` | Utility: add columns to markdown tables |
| `environment-variable-fallback-pattern.ps1` | `patterns/` | Reference pattern for environment variable handling |
