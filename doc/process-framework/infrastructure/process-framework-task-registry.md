---
id: PF-INF-001
type: Process Framework
category: Infrastructure Analysis
version: 2.2
created: 2025-08-22
updated: 2025-10-19
purpose: Process Framework Task Registry
scope: All Process Framework Tasks with Scripts and Manual Updates
---

# Process Framework Task Registry

## Purpose

This document serves as the **comprehensive registry** of all process framework tasks, their automation scripts, and the files they update (both state tracking and other files). This registry supports the [Automation Script Infrastructure Improvement Proposal](../proposals/automation-script-infrastructure-improvement.md) by providing complete visibility into:

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
- **Technical Debt Assessment Task** - **NEW**: Complete automation with technical debt tracking updates and bidirectional linking system

### 🔄 Semi-Automated Tasks (Script + Manual/Script Updates Required)

- **New Task Creation Process** - **ENHANCED**: Script now automatically updates three documentation files (documentation-map.md, tasks/README.md, ai-tasks.md), requires manual registry updates
- **Feature Tier Assessment Task** - Requires running `Update-FeatureTrackingFromAssessment.ps1` after assessment creation
- **Test Implementation Task** - Script creates files and initial state updates, requires manual completion status updates and test case counts
- **Test Audit Task** - Manual audit judgment, **FULLY AUTOMATED** state updates with intelligent feature-level aggregation
- **Bug Triage Task** - Manual bug evaluation with **AUTOMATED** state updates via `Update-BugStatus.ps1`
- **Bug Fixing Task** - Manual bug resolution with **AUTOMATED** status lifecycle management via `Update-BugStatus.ps1`

### 🔄 Semi-Automated Tasks (Manual Process + Automated Validation)

- **Feature Implementation Task** - Manual coding process with post-implementation API consumer documentation creation, automated quality validation, and bug discovery integration
- **Foundation Feature Implementation Task** - Manual foundational coding with architectural impact, comprehensive automated validation, and bug discovery integration

### 🔧 Manual Tasks (No Automation)

- **Code Review Task** - Manual code analysis with quality assurance and bug discovery integration
- **Code Refactoring Task** - Manual refactoring with technical debt resolution and bug discovery integration
- **Release Deployment Task** - Manual deployment coordination with validation and bug discovery integration

### 🚨 Critical Automation Gaps Identified

1. **Feature Tier Assessment**: Requires separate script execution for state updates
2. **Test Implementation Task**: Requires manual status updates after test completion

## State File Update Frequency Analysis

### Critical Files (Updated by Multiple Tasks)

| State File                                                                                          | Update Count        | Automation Priority |
| --------------------------------------------------------------------------------------------------- | ------------------- | ------------------- |
| [Feature Tracking](../state-tracking/permanent/feature-tracking.md)                                 | 16+ tasks           | **CRITICAL**        |
| [Bug Tracking](../state-tracking/permanent/bug-tracking.md)                                         | 10+ tasks           | **HIGH**            |
| [Test Implementation Tracking](../state-tracking/permanent/test-implementation-tracking.md)         | 4 tasks             | **HIGH**            |
| [Architecture Tracking](../state-tracking/permanent/architecture-tracking.md)                       | 4 tasks             | **HIGH**            |
| [Technical Debt Tracking](../state-tracking/permanent/technical-debt-tracking.md)                   | 3 tasks             | **MEDIUM**          |
| [Test Registry](../../test/test-registry.yaml)                                                      | 2 tasks             | **MEDIUM**          |
| [Documentation Map](../documentation-map.md)                                                        | 6+ validation tasks | **MEDIUM**          |
| [Foundational Validation Tracking](../state-tracking/temporary/foundational-validation-tracking.md) | 6 validation tasks  | **MEDIUM**          |

## Task Catalog

### **DISCRETE TASKS**

#### **1. Feature Tier Assessment Task** ([PF-TSK-002](../tasks/01-planning/feature-tier-assessment-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script creates files, requires update script execution)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-Assessment.ps1`](../scripts/file-creation/New-Assessment.ps1)
- **Output Directory:** [`assessments/`](../methodologies/documentation-tiers/assessments/)
- **Auto-Update Function:** **REQUIRES** running [`Update-FeatureTrackingFromAssessment.ps1`](../methodologies/documentation-tiers/Update-FeatureTrackingFromAssessment.ps1)

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[ART-ASS-XXX]-[FeatureId]-[feature-name].md` | `New-Assessment.ps1` | Assessment document with tier analysis |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `Update-FeatureTrackingFromAssessment.ps1` | Status: "⬜ Not Started" → "📊 Assessment Created"<br/>• Add tier emoji (🔵/🟠/🔴)<br/>• Set API Design: "Yes"/"No"<br/>• Set DB Design: "Yes"/"No"<br/>• Link to assessment document<br/>**⚠️ MUST run update script after assessment creation** |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Initiates feature documentation workflow
- **Enables next steps:** FDD Creation (Tier 2+), TDD Creation (all tiers)
- **Dependencies:** Requires feature discovery completion

#### **2. FDD Creation Task** ([PF-TSK-027](../tasks/02-design/fdd-creation-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-FDD.ps1`](../scripts/file-creation/New-FDD.ps1)
- **Output Directory:** [`fdds/`](../../product-docs/functional-design/fdds/)
- **Auto-Update Function:** Built-in automated feature tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `fdd-[feature-id]-[feature-name].md` | `New-FDD.ps1` | Functional design document with requirements and specifications |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-FDD.ps1` | Status: "📊 Assessment Created" → "📋 FDD Created"<br/>• Add FDD document link in FDD column<br/>• Add FDD creation date to Notes |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Advances feature documentation workflow
- **Enables next steps:** TDD Creation, Feature Implementation
- **Dependencies:** Requires Feature Tier Assessment (Tier 2+ features only)

#### **3. TDD Creation Task** ([PF-TSK-015](../tasks/02-design/tdd-creation-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-tdd.ps1`](../scripts/file-creation/New-tdd.ps1)
- **Output Directory:** [`tdd/`](../../product-docs/technical/architecture/design-docs/tdd/tdd/)
- **Auto-Update Function:** Built-in automated feature tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `tdd-[FeatureId]-[feature-name]-t[Tier].md` | `New-tdd.ps1` | Technical design document with architecture and implementation details |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-tdd.ps1` | Status: "📋 FDD Created" (Tier 2+) or "📊 Assessment Created" (Tier 1) → "📝 TDD Created"<br/>• Add TDD link in Tech Design column<br/>• Add TDD creation date to Notes column |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Completes technical design phase
- **Enables next steps:** Test Specification Creation, API Design, Database Schema Design
- **Dependencies:** Requires Feature Tier Assessment, optionally FDD Creation (Tier 2+)

#### **4. Test Specification Creation Task** ([PF-TSK-012](../tasks/03-testing/test-specification-creation-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-TestSpecification.ps1`](../scripts/file-creation/New-TestSpecification.ps1)
- **Output Directory:** [`feature-specs/`](../../../test/specifications/feature-specs/)
- **Auto-Update Function:** Built-in automated feature tracking updates via `Update-DocumentTrackingFiles`

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `test-spec-[FeatureId]-[FeatureName].md` | `New-TestSpecification.ps1` | Comprehensive test specification document |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-TestSpecification.ps1` | Status: "🏗️ Architecture Reviewed" → "📋 Specs Created"<br/>• Add Test Spec link in Test Spec column<br/>• Add specification creation date to Notes |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Updates feature test status
- **Enables next steps:** Test Implementation Task
- **Dependencies:** Requires System Architecture Review completion

#### **5. Test Implementation Task** ([PF-TSK-029](../tasks/03-testing/test-implementation-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script creates files and initial state updates, manual completion required)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-TestFile.ps1`](../scripts/file-creation/New-TestFile.ps1)
- **Output Directory:** [`test/`](../../../test/) (various subdirectories)
- **Auto-Update Function:** Built-in automated initial state tracking via `Update-TestImplementationStatus`
- **Manual Updates Required:** Test completion status, test case counts after implementation

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Test files (multiple) | `New-TestFile.ps1` | Test files in appropriate test directories (unit/integration/widget/e2e) with proper PD-TST IDs |
| **Updates** | [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`test-implementation-tracking.md`](../state-tracking/permanent/test-implementation-tracking.md) | `New-TestFile.ps1` | Status: "📝 Specification Created" → "🟡 Implementation In Progress"<br/>• Add test file links with correct relative paths (../../../test/unit/filename.dart)<br/>• Use filename as display name instead of PD-TST ID<br/>• Update test cases count, last updated date, notes |
| **Updates** | [`test-registry.yaml`](../../../test/test-registry.yaml) | `New-TestFile.ps1` | Add new test file entries with metadata<br/>• Include testId, featureId, testType, componentName<br/>• Set initial status and creation timestamp |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-TestFile.ps1` | Update Test Status based on implementation progress<br/>• Automatic status mapping from test implementation to feature tracking<br/>• Coordinate status across multiple state files |

**🎯 KEY IMPACTS**

- **Primary state file:** [`test-implementation-tracking.md`](../state-tracking/permanent/test-implementation-tracking.md) - Tracks implementation progress with clickable file links
- **Secondary coordination:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Updates feature test status
- **Test registry updates:** [`test-registry.yaml`](../../../test/test-registry.yaml) - Automatically updated with test file metadata
- **Bug discovery integration:** Includes systematic bug identification during test development with standardized reporting via `New-BugReport.ps1`
- **Manual completion required:** Status updates from 🟡 Implementation In Progress to 🔄 Ready for Validation, test case counts
- **Enables next steps:** Test Audit Task, Bug Triage (for discovered bugs)
- **Dependencies:** Requires Test Specification Creation

#### **6. Test Audit Task** ([PF-TSK-030](../tasks/03-testing/test-audit-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual audit judgment, automated state updates)

**📋 AUTOMATION DETAILS**

- **Report Script:** [`New-TestAuditReport.ps1`](../scripts/file-creation/New-TestAuditReport.ps1)
- **State Update Script:** [`Update-TestFileAuditState.ps1`](../scripts/Update-TestFileAuditState.ps1)
- **Output Directory:** [`reports/`](../test-audits/reports/)
- **Auto-Update Function:** **FULLY AUTOMATED** state file updates with intelligent aggregation

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PF-TAR-XXX]-[feature-id]-[test-file-id].md` | `New-TestAuditReport.ps1` | Test audit report with quality assessment and recommendations |
| **Updates** | [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`test-implementation-tracking.md`](../state-tracking/permanent/test-implementation-tracking.md) | `Update-TestFileAuditState.ps1` | **AUTOMATED**: Update individual test file audit status with comprehensive details<br/>• Audit status (✅ Tests Approved/🔴 Audit Failed/🔄 Needs Update)<br/>• Detailed audit results (passed/failed test counts)<br/>• Auditor information and major findings<br/>• Audit date and completion timestamp |
| **Updates** | [`test-registry.yaml`](../../../test/test-registry.yaml) | `Update-TestFileAuditState.ps1` | **AUTOMATED**: Flag for manual review with audit completion status<br/>• Add auditStatus, auditDate, auditor fields |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `Update-TestFileAuditState.ps1` | **AUTOMATED**: Intelligent aggregated test status calculation<br/>• 🔴 Tests Failed Audit (any test fails)<br/>• 🟡 Tests Partially Approved (mixed statuses)<br/>• ✅ Tests Approved (all tests approved)<br/>• Last audit date tracking |

**🎯 KEY IMPACTS**

- **Primary state file:** [`test-implementation-tracking.md`](../state-tracking/permanent/test-implementation-tracking.md) - Quality gate for test completion with automated audit tracking
- **Intelligent aggregation:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Automated feature-level test status based on all test files
- **Quality assurance:** Validates test implementation meets standards with comprehensive audit trail
- **Bug discovery integration:** Includes comprehensive bug identification during audit process with standardized reporting via `New-BugReport.ps1`
- **Enables next steps:** Feature Implementation (if tests approved), Bug Triage (for discovered bugs)
- **Dependencies:** Requires Test Implementation completion

#### **7. Feature Implementation Task** ([PF-TSK-004](../tasks/04-implementation/feature-implementation-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual implementation with automated quality validation)

**📋 AUTOMATION DETAILS**

- **Implementation Script:** No automation script (manual coding)
- **Validation Scripts:**
  - [`Quick-ValidationCheck.ps1`](../scripts/validation/Quick-ValidationCheck.ps1) - Fast health check
  - [`Run-FoundationalValidation.ps1`](../scripts/validation/Run-FoundationalValidation.ps1) - Code quality validation for foundational features
- **Output Directory:** `scripts/validation/validation-reports/`
- **Auto-Update Function:** Automated quality validation reporting

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Validation reports | [`Quick-ValidationCheck.ps1`](../scripts/validation/Quick-ValidationCheck.ps1) | Quick health check reports (console/JSON/CSV output) |
| **Creates** | Quality validation reports | [`Run-FoundationalValidation.ps1`](../scripts/validation/Run-FoundationalValidation.ps1) | Code quality validation reports for foundational features |
| **Creates** | `[api-name]-docs.md` (API features only) | Manual | API Consumer Documentation with usage examples and integration guidance |
| **Updates** | [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | Manual | Update implementation status (🟡 In Progress/🔄 Needs Revision/🟢 Completed)<br/>• Add implementation start and completion dates<br/>• Link to relevant pull request or commit<br/>• **API Design column**: Manually add consumer documentation link for API features<br/>• Document design deviations with justification |
| **Updates** | [`test-implementation-tracking.md`](../state-tracking/permanent/test-implementation-tracking.md) | Manual | Update test implementation status during development<br/>• Change status based on implementation progress |
| **Updates** | [`component-relationship-index.md`](../../product-docs/technical/architecture/component-relationship-index.md) | Manual | Update if new components or relationships are added<br/>• Document new dependencies |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Core feature development tracking
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
| **Creates** | Data model classes | Manual | Dart model classes in `/lib/data/models/[feature]/` with serialization, validation |
| **Creates** | Repository interface | Manual | Repository contract in `/lib/data/repositories/[feature]/[feature]_repository.dart` |
| **Creates** | Repository implementation | Manual | Concrete repository in `/lib/data/repositories/[feature]/[feature]_repository_impl.dart` |
| **Creates** | Unit tests | Manual | Test files in `/test/unit/data/[feature]/` for models and repositories |
| **Executes** | Database migrations | Manual | Run Supabase migration scripts to create database schema |
| **Updates** | [Feature Implementation State File](../state-tracking/permanent/feature-[feature-id]-implementation.md) | Manual | Update task sequence tracking, code inventory, implementation notes, issues log |

**🎯 KEY IMPACTS**

- **Primary state file:** Feature Implementation State File - Tracks data layer implementation progress within multi-task feature workflow
- **Code artifacts:** Creates foundational data access layer for feature (models, repositories, database integration)
- **Dependencies:** Provides data access interfaces for state management layer
- **Enables next steps:** State Management Implementation Task (PF-TSK-043), Integration & Testing
- **Prerequisites:** Feature Implementation Planning Task (PF-TSK-044), Database Schema Design completed, migrations prepared

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
| **Updates** | [`foundational-validation-tracking.md`](../state-tracking/temporary/foundational-validation-tracking.md) | [`Run-FoundationalValidation.ps1`](../scripts/validation/Run-FoundationalValidation.ps1) | Update validation matrix with report creation dates and links |
| **Updates** | [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`architecture-context-packages.md`](../state-tracking/permanent/architecture-context-packages.md) | Manual | Update with new architectural foundations and component relationships |
| **Updates** | [`architecture-tracking.md`](../state-tracking/permanent/architecture-tracking.md) | Manual | Record foundation implementation and architectural evolution<br/>• Update component status and key decisions |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | Manual | Update with foundation feature completion status |

**🎯 KEY IMPACTS**

- **Primary state file:** [`architecture-tracking.md`](../state-tracking/permanent/architecture-tracking.md) - Tracks foundational architectural changes
- **Secondary coordination:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Updates feature completion status
- **Validation integration:** Automated foundational validation ensures implementation meets architectural standards
- **Quality assurance:** Comprehensive validation across all 6 validation types (Architectural, Code Quality, Integration, Documentation, Extensibility, AI Agent Continuity)
- **Architecture foundation:** Establishes core architectural components and patterns
- **Bug discovery integration:** Includes systematic bug identification during Finalization phase for architectural and foundation issues with standardized reporting via `New-BugReport.ps1`
- **Enables next steps:** Dependent feature implementations, architectural reviews, Bug Triage (for discovered bugs)
- **Dependencies:** Requires architectural design decisions and planning
- **⚠️ Automation Enhancement:** Now includes automated validation with comprehensive reporting

#### **9. ADR Creation Task** ([PF-TSK-028](../tasks/02-design/adr-creation-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-ArchitectureDecision.ps1`](../../../scripts/file-creation/New-ArchitectureDecision.ps1)
- **Output Directory:** [`adr/`](../../../product-docs/technical/architecture/design-docs/adr/adr/)
- **Auto-Update Function:** `Update-DocumentTrackingFiles` + Script updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[kebab-case-title].md` | `New-ArchitectureDecision.ps1` | Architecture Decision Record with context, decision, and consequences |
| **Updates** | [`architecture-tracking.md`](../state-tracking/permanent/architecture-tracking.md) | `New-ArchitectureDecision.ps1` | Update with new architectural decision and its impact<br/>• Record decision context and consequences |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-ArchitectureDecision.ps1` | Update ADR column for related features with link to created ADR |
| **Updates** | [`documentation-map.md`](../documentation-map.md) | `New-ArchitectureDecision.ps1` | Add new ADR to appropriate architecture decisions section based on document ID pattern |

**🎯 KEY IMPACTS**

- **Primary state file:** [`architecture-tracking.md`](../state-tracking/permanent/architecture-tracking.md) - Records architectural decisions
- **Secondary coordination:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Links decisions to features
- **Documentation registry:** Updates ADR documentation map
- **Enables next steps:** Feature Implementation with architectural guidance
- **Dependencies:** Requires architectural analysis and decision-making

#### **10. API Design Task** ([PF-TSK-020](../tasks/02-design/api-design-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-APISpecification.ps1`](../scripts/file-creation/New-APISpecification.ps1)
- **Additional Script:** [`New-APIDataModel.ps1`](../scripts/file-creation/New-APIDataModel.ps1)
- **Output Directory:** [`specifications/`](../../product-docs/technical/api/specifications/specifications/) + [`models/`](../../product-docs/technical/api/models/)
- **Auto-Update Function:** Built-in automated feature tracking updates with intelligent replacement/append logic

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[api-name].md` | `New-APISpecification.ps1` | API specification document with comprehensive contract definition |
| **Creates** | `[api-name]-request.md` | `New-APIDataModel.ps1` | Request data model with validation rules and examples |
| **Creates** | `[api-name]-response.md` | `New-APIDataModel.ps1` | Response data model with complete structure and field definitions |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-APISpecification.ps1` | **AUTOMATED**: Replace "Yes" with first API specification link<br/>• Intelligent replacement: "Yes" → clickable API specification link<br/>• Additional specifications appended with " • " separator<br/>• Correct relative path generation and timestamped automation notes |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-APIDataModel.ps1` | **AUTOMATED**: Append data model links with intelligent logic<br/>• Appends data model links with " • " separator to existing API Design column content<br/>• Automatic relative path calculation and timestamped automation notes |
| **Updates** | [`technical-debt-tracking.md`](../state-tracking/permanent/technical-debt-tracking.md) | Manual | Record API design decisions that create technical debt |
| **Updates** | [`api-models-registry.md`](../state-tracking/permanent/api-models-registry.md) | Manual | Add entries for all newly created data models and update "Used By Features" for reused models |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - **FULLY AUTOMATED** API design completion tracking
- **Design-time focus:** Creates contract-first API specifications and data models before implementation
- **Technical debt tracking:** Documents design trade-offs and future improvements (manual)
- **Data models registry:** Maintains registry of all API data models (manual)
- **Enables next steps:** TDD Creation, Test Specification Creation, Feature Implementation
- **Dependencies:** Requires Feature Tier Assessment indicating "Yes" in API Design column

#### **11. Database Schema Design Task** ([PF-TSK-021](../tasks/02-design/database-schema-design-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-SchemaDesign.ps1`](../scripts/file-creation/New-SchemaDesign.ps1)
- **Output Directory:** [`schemas/`](../../product-docs/technical/database/schemas/) + [`migrations/`](../../product-docs/technical/database/migrations/) + [`diagrams/`](../../product-docs/technical/database/diagrams/)
- **Auto-Update Function:** Built-in automated feature tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[feature-name]-schema-design.md` | `New-SchemaDesign.ps1` | Complete database schema design document with comprehensive data model specification |
| **Creates** | Migration scripts (multiple) | `New-SchemaDesign.ps1` | Database migration files for schema changes with rollback procedures |
| **Creates** | ERD diagrams (multiple) | `New-SchemaDesign.ps1` | Entity-relationship diagrams for visual schema representation |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-SchemaDesign.ps1` | Update DB Design column from "Yes" to link to completed schema design<br/>• Add schema design document link in DB Design column<br/>• Add schema design creation date to Notes |
| **Updates** | [`technical-debt-tracking.md`](../state-tracking/permanent/technical-debt-tracking.md) | Manual | Add schema optimization opportunities identified during design |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Completes database design requirement with automated state updates
- **Technical debt tracking:** [`technical-debt-tracking.md`](../state-tracking/permanent/technical-debt-tracking.md) Documents schema optimization opportunities (manual update required)
- **Database evolution:** Creates migration scripts for schema changes
- **Enables next steps:** Feature Implementation with database support
- **Dependencies:** Requires TDD completion and tier assessment with DB Design = "Yes"
- **📋 Multi-file creation:** Creates design document + migrations + diagrams

#### **12. UI/UX Design Task** ([PF-TSK-043](../tasks/02-design/ui-ux-design-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-UIDesign.ps1`](../scripts/file-creation/New-UIDesign.ps1)
- **Output Directory:** [`design/ui-ux/`](../../product-docs/technical/design/ui-ux/) with subdirectories:
  - `design-system/` - Design system documentation
  - `mockups/` - UI mockups and high-fidelity designs
  - `wireframes/` - Low-fidelity wireframes
  - `user-flows/` - User flow diagrams
- **Auto-Update Function:** Built-in automated feature tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PD-UIX-XXX]-[feature-name]-[type].md` | `New-UIDesign.ps1` | UI/UX design document (design-system, mockup, wireframe, or user-flow) with comprehensive visual specifications |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-UIDesign.ps1` | Update UI Design column from "TBD" to link to completed UI design<br/>• Add UI design document link in UI Design column<br/>• Add design creation date to Notes |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Completes UI/UX design requirement with automated state updates
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
| **Updates** | [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | Manual | Update code review status (🟢 Completed/🔄 Needs Revision)<br/>• Add review date, reviewer information<br/>• Link to review document, list major findings |
| **Updates** | [`test-implementation-tracking.md`](../state-tracking/permanent/test-implementation-tracking.md) | Manual | Update test status based on review findings<br/>• Confirm "✅ Tests Implemented" or change to "🔴 Tests Failing"/"🔄 Needs Update" |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Quality gate for feature completion
- **Test validation:** Confirms test implementation quality and coverage
- **Quality assurance:** Validates code meets standards and requirements
- **Bug discovery integration:** Includes systematic bug identification during code review with standardized reporting via `New-BugReport.ps1`
- **Enables next steps:** Release Deployment (if approved), Bug Fixing (if issues found), Bug Triage (for discovered bugs)
- **Dependencies:** Requires Feature Implementation completion
- **⚠️ Automation Gap:** Medium-priority candidate for automated code quality checks

#### **14. Bug Triage Task** ([PF-TSK-041](../tasks/06-maintenance/bug-triage-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual evaluation with automated state updates)

**📋 AUTOMATION DETAILS**

- **Script:** [`Update-BugStatus.ps1`](../scripts/Update-BugStatus.ps1)
- **Output Directory:** N/A (updates existing state files)
- **Auto-Update Function:** Automated bug status transitions and state tracking

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) | [`Update-BugStatus.ps1`](../scripts/Update-BugStatus.ps1) | Update bug status from 🆕 Reported to 🔍 Triaged<br/>• Automated priority (P1-P4) and severity assignments<br/>• Automated status emoji updates (🔍 Triaged)<br/>• Automated timestamp and notes updates<br/>**Usage:** `.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Triaged" -Priority "High" -Severity "Medium"` |

**🎯 KEY IMPACTS**

- **Primary state file:** [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) - Central bug registry and prioritization with automated state management
- **Quality gate:** Ensures bugs are properly evaluated before development resources are allocated
- **Resource allocation:** Provides priority-based assignment recommendations
- **Enables next steps:** Bug Fixing (for triaged bugs), Feature Implementation (if bugs reveal feature gaps)
- **Dependencies:** Requires bug reports from users, testing, or code review

#### **15. Bug Fixing Task** ([PF-TSK-007](../tasks/06-maintenance/bug-fixing-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Manual coding with automated status lifecycle management)

**📋 AUTOMATION DETAILS**

- **Script:** [`Update-BugStatus.ps1`](../scripts/Update-BugStatus.ps1)
- **Output Directory:** N/A (updates existing state files)
- **Auto-Update Function:** Automated bug status transitions through complete lifecycle

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) | [`Update-BugStatus.ps1`](../scripts/Update-BugStatus.ps1) | Update bug status through lifecycle:<br/>• 🔍 Triaged → 🔧 In Progress → 🧪 Testing → ✅ Fixed → 🟢 Closed<br/>• Automated status emoji updates and timestamp tracking<br/>• Automated notes management and metadata tracking<br/>• Automated fix details, root cause, and PR linking<br/>**Usage Examples:**<br/>• Start: `.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "InProgress"`<br/>• Complete: `.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Fixed" -FixDetails "Details" -RootCause "Cause" -TestsAdded "Yes" -PullRequestUrl "URL"`<br/>• Close: `.\Update-BugStatus.ps1 -BugId "BUG-001" -NewStatus "Closed" -VerificationNotes "Verified in production"` |

**🎯 KEY IMPACTS**

- **Primary state file:** [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) - Tracks bug resolution progress through complete lifecycle with automated state management
- **Quality improvement:** Resolves identified issues and defects systematically
- **Enables next steps:** Testing (🧪), Code Review, Bug Verification, Release Deployment
- **Dependencies:** Requires triaged bugs from Bug Triage Task
- **Integration:** Works with all development tasks that perform bug discovery

#### **16. Code Refactoring Task** ([PF-TSK-022](../tasks/06-maintenance/code-refactoring-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Scripts create planning files and temporary state tracking, manual implementation with comprehensive state updates)

**📋 AUTOMATION DETAILS**

- **Planning Script:** [`New-RefactoringPlan.ps1`](../scripts/file-creation/New-RefactoringPlan.ps1)
- **State Tracking Script:** [`New-TempTaskState.ps1`](../scripts/file-creation/New-TempTaskState.ps1)
- **Bug Reporting Script:** [`New-BugReport.ps1`](../scripts/file-creation/New-BugReport.ps1)
- **ADR Creation Script:** [`New-ADR.ps1`](../scripts/file-creation/New-ADR.ps1) (for architectural refactoring)
- **Output Directory:** [`plans/`](../refactoring/plans/), [`temporary/`](../state-tracking/temporary/)
- **Auto-Update Function:** Partial automation with comprehensive manual state updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | [`[PF-RFP-XXX]-[refactoring-scope].md`](../refactoring/plans/) | [`New-RefactoringPlan.ps1`](../scripts/file-creation/New-RefactoringPlan.ps1) | Detailed refactoring plan with scope, approach, and timeline |
| **Creates** | [`[PF-TTS-XXX]-[task-context].md`](../state-tracking/temporary/) | [`New-TempTaskState.ps1`](../scripts/file-creation/New-TempTaskState.ps1) | Work-in-progress tracking for refactoring sessions |
| **Creates** | [`[PF-ADR-XXX]-[decision-title].md`](../architecture/adrs/) | [`New-ADR.ps1`](../scripts/file-creation/New-ADR.ps1) | Architecture Decision Records for architectural refactoring |
| **Updates** | [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) | [`New-BugReport.ps1`](../scripts/file-creation/New-BugReport.ps1) | Add bugs discovered during refactoring with 4-tier severity decision matrix |
| **Updates** | [`technical-debt-tracking.md`](../state-tracking/permanent/technical-debt-tracking.md) | Manual | 3-phase updates: "🔄 In Progress" → "✅ Resolved" |
| **Updates** | [`architecture-tracking.md`](../state-tracking/permanent/architecture-tracking.md) | Manual | Improve feature status (e.g., "🔄 Needs Revision" → "🧪 Testing") |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | Manual | For foundation features (0.x.x), document architectural improvements |
| **Updates** | [`test-implementation-tracking.md`](../state-tracking/permanent/test-implementation-tracking.md) | Manual | Note test improvements or new test requirements |
| **Updates** | [Context Packages](../architecture/context-packages/) | Manual | Update relevant context packages for architectural refactoring |

**🎯 KEY IMPACTS**

- **Primary state file:** [`technical-debt-tracking.md`](../state-tracking/permanent/technical-debt-tracking.md) - Comprehensive 3-phase debt resolution tracking
- **Secondary coordination:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Updates feature quality status with clear progression path
- **Temporary state management:** Work-in-progress tracking with archival to [`temporary/old/`](../state-tracking/temporary/old/)
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
| **Updates** | [`bug-tracking.md`](../state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../scripts/file-creation/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Reported status for triage |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | Manual | Update deployment status for released features<br/>• Add release version and deployment date |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Tracks feature deployment status
- **Release coordination:** Manages feature releases and version tracking
- **Production deployment:** Moves features from development to production
- **Bug discovery integration:** Includes systematic bug identification during deployment validation with standardized reporting via `New-BugReport.ps1`
- **Enables next steps:** Post-deployment monitoring, user feedback collection, Bug Triage (for discovered bugs)
- **Dependencies:** Requires Code Review approval and successful testing
- **⚠️ Automation Gap:** Medium-priority candidate for deployment status automation

#### **18. System Architecture Review** ([PF-TSK-019](../tasks/01-planning/system-architecture-review-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-ArchitectureAssessment.ps1`](../scripts/file-creation/New-ArchitectureAssessment.ps1)
- **Output Directory:** [`assessments/`](../../product-docs/technical/architecture/assessments/assessments/)
- **Auto-Update Function:** Built-in automated feature tracking and architecture tracking updates

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PD-AIA-XXX]-[feature-name]-architecture-impact-assessment.md` | `New-ArchitectureAssessment.ps1` | Architecture Impact Assessment document with system integration analysis |
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | `New-ArchitectureAssessment.ps1` | Status: "📋 FDD Created" → "🏗️ Architecture Reviewed"<br/>• Add Architecture Impact Assessment link in Arch Review column<br/>• Add architecture review completion date to Notes |
| **Updates** | [`architecture-tracking.md`](../state-tracking/permanent/architecture-tracking.md) | `New-ArchitectureAssessment.ps1` | Add new architecture impact entry with assessment details and cross-references |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Advances feature through architecture review phase
- **Secondary coordination:** [`architecture-tracking.md`](../state-tracking/permanent/architecture-tracking.md) - Tracks architectural decisions and impacts
- **Enables next steps:** Test Specification Creation, API Design, Database Schema Design
- **Dependencies:** Requires FDD Creation (Tier 2+ features) or TDD Creation (Tier 1 features)

#### **19. Feature Discovery Task** ([PF-TSK-013](../tasks/01-planning/feature-discovery-task.md))

**🔧 Process Type:** 🔧 **Manual Process** (No automation - requires business analysis and stakeholder input)

**📋 AUTOMATION DETAILS**

- **Script:** No automation script
- **Output Directory:** N/A
- **Auto-Update Function:** Manual updates only

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) | Manual | Add new feature entries with initial status "⬜ Not Started" |

**🎯 KEY IMPACTS**

- **Primary state file:** [`feature-tracking.md`](../state-tracking/permanent/feature-tracking.md) - Initiates feature development workflow
- **Requirements gathering:** Captures initial feature requirements and scope
- **Enables next steps:** Feature Tier Assessment Task
- **Dependencies:** Requires business requirements and stakeholder input
- **⚠️ Automation Gap:** Low-priority candidate for feature entry automation

### **VALIDATION TASKS** (All use same automation and file operations)

#### **20-25. Validation Tasks** (6 tasks: Architectural Consistency, Code Quality Standards, Integration Dependencies, Documentation Alignment, Extensibility Maintainability, AI Agent Continuity)

**🔧 Process Type:** 🤖 **Fully Automated** (Script creates files AND updates state)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-ValidationReport.ps1`](../scripts/file-creation/New-ValidationReport.ps1)
- **Output Directory:** [`reports/[validation-type]/`](../validation/reports/)
- **Auto-Update Function:** `Update-DocumentTrackingFiles`

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PF-VAL-XXX]-[validation-type]-features-[feature-range].md` | Script | Comprehensive validation report for specific validation type |
| **Updates** | [`foundational-validation-tracking.md`](../state-tracking/temporary/foundational-validation-tracking.md) | Auto | Update validation matrix with report creation date and link<br/>• Update specific validation type column for validated features |
| **Updates** | [`documentation-map.md`](../documentation-map.md) | Auto | Add new validation report to validation reports section<br/>• Include report ID, path, and description |

**🎯 KEY IMPACTS**

- **Primary state file:** [`foundational-validation-tracking.md`](../state-tracking/temporary/foundational-validation-tracking.md) - Tracks validation completion across features
- **Documentation registry:** Updates validation report catalog
- **Quality assurance:** Validates features meet foundational standards
- **Enables next steps:** Feature completion certification, release readiness
- **Dependencies:** Requires completed features for meaningful validation

**📋 VALIDATION TYPES:**

- **20. Architectural Consistency** ([PF-TSK-031](../tasks/05-validation/architectural-consistency-validation.md))
- **21. Code Quality Standards** ([PF-TSK-032](../tasks/05-validation/code-quality-standards-validation.md))
- **22. Integration Dependencies** ([PF-TSK-033](../tasks/05-validation/integration-dependencies-validation.md))
- **23. Documentation Alignment** ([PF-TSK-034](../tasks/05-validation/documentation-alignment-validation.md))
- **24. Extensibility Maintainability** ([PF-TSK-035](../tasks/05-validation/extensibility-maintainability-validation.md))
- **25. AI Agent Continuity** ([PF-TSK-036](../tasks/05-validation/ai-agent-continuity-validation.md))

### **SUPPORT TASKS**

#### **26. New Task Creation Process** ([PF-TSK-001](../tasks/support/new-task-creation-process.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script creates files and updates multiple documentation files, manual registry updates)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-Task.ps1`](../scripts/file-creation/New-Task.ps1)
- **Output Directory:** [`tasks/[task-type]/`](../tasks/)
- **Auto-Update Function:** **ENHANCED** - Script now handles three documentation file updates automatically

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[kebab-case-task-name].md` | [`New-Task.ps1`](../scripts/file-creation/New-Task.ps1) | New task document with standardized structure |
| **Updates** | [`documentation-map.md`](../documentation-map.md) | [`New-Task.ps1`](../scripts/file-creation/New-Task.ps1) | Add new task to appropriate task category section |
| **Updates** | [`tasks/README.md`](../tasks/README.md) | [`New-Task.ps1`](../scripts/file-creation/New-Task.ps1) | Add new task to task type table with flexible pattern matching |
| **Updates** | [`ai-tasks.md`](../../../ai-tasks.md) | [`New-Task.ps1`](../scripts/file-creation/New-Task.ps1) | **NEW**: Add new task to AI Tasks main entry point with correct section and table format |
| **Updates** | [`process-framework-task-registry.md`](process-framework-task-registry.md) | Manual | Add new task entry with its file update requirements (**THIS FILE**) |

**🎯 KEY IMPACTS**

- **Primary state file:** [`documentation-map.md`](../documentation-map.md) - Updates task catalog
- **Process framework evolution:** Extends framework capabilities with new tasks
- **Enables next steps:** New task becomes immediately available in AI workflows
- **Dependencies:** Requires task analysis and design completion
- **⚠️ Automation Gap:** Medium-priority candidate for automated registry updates

#### **27. Process Improvement Task** ([PF-TSK-009](../tasks/support/process-improvement-task.md))

**🔧 Process Type:** 🔧 **Manual Process** (No automation - varies by improvement type)

**📋 AUTOMATION DETAILS**

- **Script:** No automation script
- **Output Directory:** N/A
- **Auto-Update Function:** Manual updates only

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`process-improvement-tracking.md`](../state-tracking/permanent/process-improvement-tracking.md) | Manual | Status: "Identified" → "In Progress" → "Completed"<br/>• Update improvement initiatives and status<br/>• Add implementation plans and timelines<br/>• Record success metrics and evaluation criteria<br/>• Add completion dates for implemented improvements<br/>• Link to test results and performance data (if testing used)<br/>• **🚨 MANDATORY CLEANUP**: Move completed improvements from "Current Improvement Opportunities" to "Completed Improvements" section |

**🎯 KEY IMPACTS**

- **Primary state file:** [`process-improvement-tracking.md`](../state-tracking/permanent/process-improvement-tracking.md) - Tracks improvement initiatives with mandatory cleanup of completed items
- **Incremental implementation:** Requires explicit human approval at each critical checkpoint with no changes without approval
- **Enables next steps:** No next steps; completes cycle
- **Dependencies:** Requires process analysis and improvement identification, optional comprehensive testing
- **⚠️ Automation Gap:** Variable priority based on improvement type - testing scripts available but core process remains manual

#### **28. Framework Extension Task** ([PF-TSK-026](../tasks/support/framework-extension-task.md))

**🔧 Process Type:** 🔄 **Semi-Automated** (Script creates concept files, manual implementation)

**📋 AUTOMATION DETAILS**

- **Script:** [`New-FrameworkExtensionConcept.ps1`](../scripts/file-creation/New-FrameworkExtensionConcept.ps1)
- **Output Directory:** [`proposals/`](../proposals/)
- **Auto-Update Function:** Manual updates only

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Framework extension concept document | [`New-FrameworkExtensionConcept.ps1`](../scripts/file-creation/New-FrameworkExtensionConcept.ps1) | Detailed concept document for framework extension |
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

- **Script:** [`New-StructureChangeState.ps1`](../scripts/file-creation/New-StructureChangeState.ps1)
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

**🔧 Process Type:** 🔧 **Manual Process** (No automation - requires tool evaluation)

**📋 AUTOMATION DETAILS**

- **Script:** No automation script
- **Output Directory:** N/A
- **Auto-Update Function:** Manual updates only

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Updates** | [`process-improvement-tracking.md`](../state-tracking/permanent/process-improvement-tracking.md) | Manual | Updates with new improvement potential |

**🎯 KEY IMPACTS**

- **Tool optimization:** Evaluates and improves development and documentation tools
- **Efficiency improvement:** Identifies better tools and workflows
- **Technology evolution:** Keeps framework aligned with current best practices
- **Enables next steps:** Process Improvement Task
- **Dependencies:** Requires Feedback Forms
- **⚠️ Automation Gap:** Low-priority candidate for tool evaluation automation

### **CYCLICAL TASKS**

#### **31. Technical Debt Assessment Task** ([PF-TSK-023](../tasks/cyclical/technical-debt-assessment-task.md))

**🔧 Process Type:** 🤖 **Fully Automated** (Scripts create assessment files with bidirectional linking system and automatic registry integration)

**📋 AUTOMATION DETAILS**

- **Assessment Script:** [`New-TechnicalDebtAssessment.ps1`](../scripts/file-creation/New-TechnicalDebtAssessment.ps1)
- **Debt Item Script:** [`New-DebtItem.ps1`](../scripts/file-creation/New-DebtItem.ps1) - **ENHANCED** with assessment linking and automation guidance
- **Registry Update Script:** [`Update-TechnicalDebtTracking.ps1`](../scripts/Update-TechnicalDebtTracking.ps1) - **NEW** individual debt item management
- **Assessment Integration Script:** [`Update-TechnicalDebtFromAssessment.ps1`](../scripts/Update-TechnicalDebtFromAssessment.ps1) - **NEW** bulk assessment processing
- **Output Directory:** [`assessments/technical-debt/`](../assessments/technical-debt/)
- **Auto-Update Function:** **FULLY AUTOMATED** bidirectional linking and registry integration

**📁 FILE OPERATIONS**
| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | `[PF-TDA-XXX]-[assessment-name].md` | `New-TechnicalDebtAssessment.ps1` | Technical debt assessment document with systematic evaluation and prioritization matrix |
| **Creates** | `[PF-TDI-XXX]-[item-title].md` (multiple) | `New-DebtItem.ps1` | Individual debt item records with **assessment linking** and automation command guidance<br/>• Include `-AssessmentId` parameter for traceability<br/>• Auto-populate assessment reference and registry integration fields<br/>• Provide ready-to-use automation commands |
| **Updates** | [`technical-debt-tracking.md`](../state-tracking/permanent/technical-debt-tracking.md) | [`Update-TechnicalDebtFromAssessment.ps1`](../scripts/Update-TechnicalDebtFromAssessment.ps1) | **FULLY AUTOMATED REGISTRY INTEGRATION:**<br/>• Automatically add new debt items with TD### IDs<br/>• Auto-reference assessment ID (PF-TDA-XXX) in Assessment ID column<br/>• Create bidirectional traceability between registry and assessments<br/>• **Usage:** `.\Update-TechnicalDebtFromAssessment.ps1 -AssessmentId "PF-TDA-XXX"` |
| **Updates** | Individual debt item files | [`Update-TechnicalDebtTracking.ps1`](../scripts/Update-TechnicalDebtTracking.ps1) | **AUTOMATED REGISTRY INTEGRATION:**<br/>• Auto-update Registry Status: "Not Added" → "Added"<br/>• Auto-assign TD### Registry ID<br/>• Mark items as integrated into permanent tracking system<br/>• Maintain bidirectional linking automatically |

**🎯 KEY IMPACTS**

- **Primary state file:** [`technical-debt-tracking.md`](../state-tracking/permanent/technical-debt-tracking.md) - **FULLY AUTOMATED** technical debt inventory with assessment traceability
- **Enhanced traceability:** **AUTOMATED** bidirectional linking between assessments, debt items, and registry entries
- **Code quality management:** Identifies and prioritizes technical debt for resolution with systematic assessment methodology
- **Strategic planning:** Informs refactoring and improvement priorities with detailed impact analysis
- **Prevents duplicates:** **AUTOMATED** linking system ensures debt items are properly tracked and not duplicated
- **Workflow efficiency:** **ELIMINATED** manual registry integration bottleneck - assessment findings automatically integrated
- **Enables next steps:** Code Refactoring Task (using prioritized debt items from assessment)
- **Dependencies:** Requires codebase analysis and technical expertise
- **Integration workflow:** **FULLY AUTOMATED** process for moving assessment findings into permanent tracking system
- **⚠️ AUTOMATION BREAKTHROUGH:** Task moved from Semi-Automated to Fully Automated with new registry integration scripts

#### **31. Documentation Tier Adjustment Task** ([PF-TSK-011](../tasks/cyclical/documentation-tier-adjustment-task.md))

**🔧 Process Type:** 🔧 **Manual Process** (No a
