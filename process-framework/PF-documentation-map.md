---
id: PF-MAI-001
type: Process Framework
category: Documentation Map
version: 2.0
created: 2023-06-15
updated: 2026-02-20
---

# Process Framework Documentation Map

This document indexes all process framework documentation in the `process-framework` directory — tasks, templates, guides, scripts, and context maps.

> **See also**: [Product Documentation Map](/doc/PD-documentation-map.md) | [Test Documentation Map](/test/TE-documentation-map.md)

## Process Framework Documents

These documents describe how we work and our development processes:

### Task Definitions

Our tasks are organized to mirror the `tasks` directory structure:

> **📋 Recent Enhancement (2025-08-01)**: All task definitions now include **AI Agent Role** sections that specify the professional role, mindset, focus areas, and communication style for optimal AI agent behavior during task execution.

#### 00 - Setup Tasks

- [Task: Codebase Feature Discovery](tasks/00-setup/codebase-feature-discovery.md) - Discover all features in existing codebase and assign every source file
- [Task: Codebase Feature Analysis](tasks/00-setup/codebase-feature-analysis.md) - Analyze implementation patterns, dependencies, and design decisions
- [Task: Retrospective Documentation Creation](tasks/00-setup/retrospective-documentation-creation.md) - Create tier assessments and required design documentation
- [Task: Project Initiation](tasks/00-setup/project-initiation-task.md) - Initial project setup including ../doc/project-config.json creation

#### 01 - Planning Tasks

- [Task: Feature Request Evaluation](tasks/01-planning/feature-request-evaluation.md) - Classify change requests as new features or enhancements, scope enhancements, and create Enhancement State Tracking Files
- [Task: Feature Tier Assessment](tasks/01-planning/feature-tier-assessment-task.md) - Assess complexity of new features
- [Task: Feature Discovery](tasks/01-planning/feature-discovery-task.md) - Identify and document potential new features
- [Task: System Architecture Review](tasks/01-planning/system-architecture-review.md) - Evaluate how new features fit into existing system architecture before implementation

#### 02 - Design Tasks

- [Task: FDD Creation](tasks/02-design/fdd-creation-task.md) - Create Functional Design Documents for Tier 2+ features
- [Task: TDD Creation](tasks/02-design/tdd-creation-task.md) - Create Technical Design Documents
- [Task: ADR Creation](tasks/02-design/adr-creation-task.md) - Document significant architectural decisions with context, alternatives, and consequences
- [Task: API Design](tasks/02-design/api-design-task.md) - Design comprehensive API contracts and specifications before implementation begins
- [Task: Database Schema Design](tasks/02-design/database-schema-design-task.md) - Plan data model changes before coding to prevent data integrity issues

#### 03 - Testing Tasks

- [Task: Test Specification Creation](tasks/03-testing/test-specification-creation-task.md) - Create comprehensive test specifications from TDDs
- [Task: E2E Acceptance Test Case Creation](tasks/03-testing/e2e-acceptance-test-case-creation-task.md) - Create concrete, reproducible E2E acceptance test cases from test specifications with exact steps, file contents, and expected outcomes
- [Task: E2E Acceptance Test Execution](tasks/03-testing/e2e-acceptance-test-execution-task.md) - Execute E2E acceptance test cases systematically, record results, and report issues through human interaction with the running system
- [Task: Test Audit](tasks/03-testing/test-audit-task.md) - Systematic quality assessment of test implementations using six evaluation criteria

#### 04 - Implementation Tasks

- [Task: Feature Implementation Planning](tasks/04-implementation/feature-implementation-planning-task.md) - Analyze design documentation and create detailed implementation plan with task sequencing and dependency mapping
- [Task: Foundation Feature Implementation](tasks/04-implementation/foundation-feature-implementation-task.md) - Implement foundation features (0.x.x) that provide architectural foundations for the application
- [Task: Core Logic Implementation](tasks/04-implementation/core-logic-implementation.md) - General-purpose coding task for non-foundation features: create modules, wire integration points, write tracked unit tests
- [Task: Data Layer Implementation](tasks/04-implementation/data-layer-implementation.md) - Implement data models, repositories, and database integration for feature
- [Task: UI Implementation](tasks/04-implementation/ui-implementation.md) - Build user interface components and layouts for feature
- [Task: State Management Implementation](tasks/04-implementation/state-management-implementation.md) - Implement state management layer connecting data layer to UI layer
- [Task: Integration and Testing](tasks/04-implementation/integration-and-testing.md) - Integrate components and establish comprehensive test coverage
- [Task: Quality Validation](tasks/04-implementation/quality-validation.md) - Validate implementation against quality standards and business requirements
- [Task: Implementation Finalization](tasks/04-implementation/implementation-finalization.md) - Complete remaining items and prepare feature for production
- [Task: Feature Enhancement](tasks/04-implementation/feature-enhancement.md) - Execute enhancement steps from Enhancement State Tracking File, adapting existing task guidance to amendment context

#### 05 - Validation Tasks

- [Task: Validation Preparation](tasks/05-validation/validation-preparation.md) - Plan validation rounds by selecting features and applicable dimensions, create tracking state file
- [Task: Architectural Consistency Validation](tasks/05-validation/architectural-consistency-validation.md) - Validate selected features for architectural pattern adherence, ADR compliance, and interface consistency
- [Task: Code Quality Standards Validation](tasks/05-validation/code-quality-standards-validation.md) - Validate selected features for code quality standards, SOLID principles, and best practices adherence
- [Task: Integration Dependencies Validation](tasks/05-validation/integration-dependencies-validation.md) - Validate selected features for dependency health, interface contracts, and data flow integrity
- [Task: Documentation Alignment Validation](tasks/05-validation/documentation-alignment-validation.md) - Validate selected features for TDD alignment, ADR compliance, and API documentation accuracy
- [Task: Extensibility Maintainability Validation](tasks/05-validation/extensibility-maintainability-validation.md) - Validate selected features for extension points, configuration flexibility, and testing support
- [Task: AI Agent Continuity Validation](tasks/05-validation/ai-agent-continuity-validation.md) - Validate selected features for context clarity, modular structure, and documentation quality to support AI agent workflow continuity
- [Task: Security & Data Protection Validation](tasks/05-validation/security-data-protection-validation.md) - Validate selected features for security best practices, data protection, input validation, and secrets management
- [Task: Performance & Scalability Validation](tasks/05-validation/performance-scalability-validation.md) - Validate selected features for performance characteristics, resource efficiency, and scalability patterns
- [Task: Observability Validation](tasks/05-validation/observability-validation.md) - Validate selected features for logging coverage, monitoring instrumentation, alerting readiness, and diagnostic traceability
- [Task: Accessibility / UX Compliance Validation](tasks/05-validation/accessibility-ux-compliance-validation.md) - Validate selected features for accessibility standards, UX compliance, keyboard navigation, and inclusive design patterns
- [Task: Data Integrity Validation](tasks/05-validation/data-integrity-validation.md) - Validate selected features for data consistency, constraint enforcement, migration safety, and backup/recovery patterns

#### 06 - Maintenance Tasks

- [Task: Code Review](tasks/06-maintenance/code-review-task.md) - Review code for quality and correctness
- [Task: Code Refactoring](tasks/06-maintenance/code-refactoring-task.md) - Systematic code improvement and technical debt reduction without changing external behavior
  - [Code Refactoring — Lightweight Path](tasks/06-maintenance/code-refactoring-lightweight-path.md) - Process steps and checklist for low-effort refactorings (≤ 15 min, single file)
  - [Code Refactoring — Standard Path](tasks/06-maintenance/code-refactoring-standard-path.md) - Process steps and checklist for medium/complex refactorings (multi-file, architectural)
- [Task: Bug Triage](tasks/06-maintenance/bug-triage-task.md) - Systematically evaluate, prioritize, and assign reported bugs
- [Task: Bug Fixing](tasks/06-maintenance/bug-fixing-task.md) - Diagnose and fix bugs

#### 07 - Deployment Tasks
| PF-TSK-082 | [process-framework/tasks/07-deployment/git-commit-and-push.md](/process-framework/tasks/07-deployment/git-commit-and-push.md) | Documentation | Git Commit and Push | [tasks/README.md](/process-framework/tasks/README.md) |

- [Task: Release Deployment](tasks/07-deployment/release-deployment-task.md) - Manage releases and deployments
- [Task: User Documentation Creation](tasks/07-deployment/user-documentation-creation.md) - Feature introduces or changes user-visible behavior and needs handbook/quick-reference/README updates

#### Cyclical Tasks

- [Task: Documentation Tier Adjustment](tasks/cyclical/documentation-tier-adjustment-task.md) - Adjust documentation requirements
- [Task: Technical Debt Assessment](tasks/cyclical/technical-debt-assessment-task.md) - Systematic approach to identifying, categorizing, and prioritizing technical debt across the codebase

#### Support Tasks

- [Task: New Task Creation Process](tasks/support/new-task-creation-process.md) - Complete process for creating new tasks from concept to implementation-ready definition
- [Task: Process Improvement](tasks/support/process-improvement-task.md) - Improve development processes
- [Task: Structure Change](tasks/support/structure-change-task.md) - Manage structural changes to documentation
- [Task: Framework Extension Task](tasks/support/framework-extension-task.md) - Support task for fundamentally extending the framework with new functionalities and capabilities
- [Task: Tools Review](tasks/support/tools-review-task.md) - Review and improve project tools and templates
- [Task: Framework Evaluation](tasks/support/framework-evaluation.md) - Structurally evaluate the process framework for completeness, consistency, redundancy, accuracy, effectiveness, automation coverage, and scalability
- [Task: Framework Domain Adaptation](tasks/support/framework-domain-adaptation.md) - Systematically adapt the process framework from one business domain to another while preserving core structure

### Core Process Documents

- [Process: Test Query Tool](scripts/test/test_query.py) - AST-based query tool for test metadata from pytest markers (replaces test-registry.yaml — SC-007)
- [Process: Ratings Extraction Tool](scripts/extract_ratings.py) - Parses feedback form markdown and generates JSON for `feedback_db.py record`, eliminating manual JSON construction during PF-TSK-010
- [Process: Enhancement Workflow Concept](../process-framework-local/proposals/old/enhancement-workflow-concept.md) - Framework extension concept for feature enhancement classification and execution workflow
- ~~Process: Code Quality Standards Validation Concept~~ - 🗄️ Removed (file deleted)

### State Tracking Files

#### `state-tracking/permanent`

- [State: Process Improvement Tracking](../process-framework-local/state-tracking/permanent/process-improvement-tracking.md) - Process improvement opportunities and status

### Templates

#### 00 - Setup Templates

- [Template: Retrospective State](templates/00-setup/retrospective-state-template.md) - Template for retrospective documentation state tracking
- [Template: Quality-Assessment-Report](templates/00-setup/quality-assessment-report-template.md) - Template for Quality Assessment Reports created during onboarding for Target-State features

#### 01 - Planning Templates

- [Template: Assessment](templates/01-planning/assessment-template.md) - Template for feature tier assessments

#### 02 - Design Templates

- [Template: FDD](templates/02-design/fdd-template.md) - Template for creating Functional Design Documents
- [Template: TDD Tier 1](templates/02-design/tdd-t1-template.md) - Template for Tier 1 Technical Design Documents
- [Template: TDD Tier 2](templates/02-design/tdd-t2-template.md) - Template for Tier 2 Technical Design Documents
- [Template: TDD Tier 3](templates/02-design/tdd-t3-template.md) - Template for Tier 3 Technical Design Documents
- [Template: ADR](templates/02-design/adr-template.md) - Template for Architecture Decision Records
- [Template: UI Design](templates/02-design/ui-design-template.md) - Comprehensive template for creating UI/UX Design Documents with wireframes, visual specifications, accessibility requirements, and platform adaptations
- [Template: Architecture Impact Assessment](templates/02-design/architecture-impact-assessment-template.md) - Template for creating architecture impact assessments
- [Template: Architecture](templates/02-design/architecture-template.md) - Template for architecture documentation
- [Template: Architecture Context Package Update](templates/02-design/architecture-context-package-update-template.md) - Template for architecture context package updates
- [Template: API Specification](templates/02-design/api-specification-template.md) - Template for creating comprehensive API contract definitions
- [Template: API Data Model](templates/02-design/api-data-model-template.md) - Template for API data model definitions
- [Template: API Documentation](templates/02-design/api-documentation-template.md) - Template for user-facing API documentation
- [Template: API Reference](templates/02-design/api-reference-template.md) - Template for API reference documentation
- [Template: Schema Design](templates/02-design/schema-design-template.md) - Template for database schema design documents

#### 03 - Testing Templates

- [Template: Test Specification](templates/03-testing/test-specification-template.md) - Template for feature-level test specifications
- [Template: Cross-Cutting Test Specification](templates/03-testing/cross-cutting-test-specification-template.md) - Template for test specifications spanning multiple features
- [Template: Test Audit Report](templates/03-testing/test-audit-report-template.md) - Template for systematic test quality assessment reports
- [Template: Test Audit Report Lightweight](templates/03-testing/test-audit-report-lightweight-template.md) - Lightweight template for test audit reports
- [Template: Test File](templates/03-testing/test-file-template.py.template) - Python test file template with pytest markers
- [Template: E2E Acceptance Master Test](templates/03-testing/e2e-acceptance-master-test-template.md) - Template for group-level master test files with quick validation sequences
- [Template: E2E Acceptance Test Case](templates/03-testing/e2e-acceptance-test-case-template.md) - Template for individual E2E acceptance test case files with exact steps, preconditions, and expected outcomes
- [Template: Test Tracking](templates/03-testing/test-tracking-template.md) - Template for bootstrapping empty test-tracking.md in new projects, used by New-TestInfrastructure.ps1
- [Template: E2E Test Tracking](templates/03-testing/e2e-test-tracking-template.md) - Template for bootstrapping empty e2e-test-tracking.md in new projects, used by New-TestInfrastructure.ps1
- [Template: TE ID Registry](templates/03-testing/TE-id-registry-template.json) - Template for bootstrapping empty TE-id-registry.json in new projects, used by New-TestInfrastructure.ps1
- [Template: Audit Tracking](templates/03-testing/audit-tracking-template.md) - Template for multi-session test audit round tracking state files, used by New-AuditTracking.ps1

#### 04 - Implementation Templates

- [Template: Implementation Plan](templates/04-implementation/implementation-plan-template.md) - Template for creating implementation plan documents that define sequenced execution strategies for feature implementation
- [Template: Implementation Plan Tier 1](templates/04-implementation/implementation-plan-tier1-template.md) - Lightweight implementation plan template for Tier 1 features
- [Template: Foundation Feature](templates/04-implementation/foundation-feature-template.md) - Template for foundation feature structure and architectural documentation
- [Template: Feature Implementation State](templates/04-implementation/feature-implementation-state-template.md) - Full template for feature implementation state tracking files (Tier 2/3)
- [Template: Feature Implementation State Lightweight](templates/04-implementation/feature-implementation-state-lightweight-template.md) - Lightweight template for Tier 1 features and retrospective analysis (7 sections)
- [Template: Enhancement State Tracking](templates/04-implementation/enhancement-state-tracking-template.md) - Template for tracking enhancement work on existing features, used by New-EnhancementState.ps1

#### 05 - Validation Templates

- [Template: Validation Report](templates/05-validation/validation-report-template.md) - Template for creating feature validation reports
- [Template: Validation Tracking](templates/05-validation/validation-tracking-template.md) - Template for validation round tracking state files

#### 06 - Maintenance Templates

- [Template: Bug Fix State Tracking](templates/06-maintenance/bug-fix-state-tracking-template.md) - Template for tracking multi-session complex bug fix work, used by New-BugFixState.ps1
- [Template: Refactoring Plan](templates/06-maintenance/refactoring-plan-template.md) - Template for code refactoring plans
- [Template: Lightweight Refactoring Plan](templates/06-maintenance/lightweight-refactoring-plan-template.md) - Lightweight template for simple refactoring plans
- [Template: Documentation-Only Refactoring Plan](templates/06-maintenance/documentation-refactoring-plan-template.md) - Template for documentation-only refactoring plans (no code metrics/test sections), used by New-RefactoringPlan.ps1 -DocumentationOnly
- [Template: Performance Refactoring Plan](templates/06-maintenance/performance-refactoring-plan-template.md) - Template for performance-focused refactoring plans (I/O counts, timing, throughput, memory baselines), used by New-RefactoringPlan.ps1 -Performance

#### 07 - Deployment Templates

- [Template: Handbook](templates/07-deployment/handbook-template.md) - Template for creating user-facing handbook documents, used by New-Handbook.ps1

#### Cyclical Templates

- [Template: Technical Debt Assessment](templates/cyclical/technical-debt-assessment-template.md) - Template for technical debt assessment reports
- [Template: Debt Item](templates/cyclical/debt-item-template.md) - Template for individual debt item records
- [Template: Prioritization Matrix](templates/cyclical/prioritization-matrix-template.md) - Template for debt prioritization matrices

#### Support Templates

- [Template: Task](templates/support/task-template.md) - Template for creating new task definitions
- [Template: Task Completion](templates/support/task-completion-template.md) - Template for task completion checklists
- [Template: Guide](templates/support/guide-template.md) - Template for creating new guides
- [Template: Template Base](templates/support/template-base-template.md) - Base template for creating new templates
- [Template: Context Map](templates/support/context-map-template.md) - Template for creating new context maps
- [Template: State File](templates/support/state-file-template.md) - Template for creating new tracking files
- [Template: Feedback Form](templates/support/feedback-form-template.md) - Template for creating tool and process feedback forms
- [Template: Feedback DB Input](templates/support/feedback-db-input-template.json) - JSON reference template for `feedback_db.py record --json` input format
- [Template: Language Config](templates/support/language-config-template.json) - JSON template for adding new language configurations to languages-config/
- [Template: Tools Review Summary](templates/support/tools-review-summary-template.md) - Standardized template for Tools Review task (PF-TSK-010) summary output documents
- [Template: Framework Extension Concept](templates/support/framework-extension-concept-template.md) - Template for creating framework extension concept documents
- [Template: Structure Change State](templates/support/structure-change-state-template.md) - Template for tracking multi-session structure change implementation
- [Template: Structure Change State Content Update](templates/support/structure-change-state-content-update-template.md) - Lightweight template for content-only structure changes (no pilot/rollback/metrics sections)
- [Template: Structure Change State From-Proposal](templates/support/structure-change-state-from-proposal-template.md) - Lightweight execution-tracking template for proposal-backed structure changes (phase checklist + session log only)
- [Template: Structure Change State Rename](templates/support/structure-change-state-rename-template.md) - Template for rename-focused structure changes
- [Template: Structure Change Proposal](templates/support/structure-change-proposal-template.md) - Template for structure change proposals
- [Template: Temporary Task Creation State](templates/support/temp-task-creation-state-template.md) - Template for tracking multi-session task creation implementation
- [Template: Temporary Process Improvement State](templates/support/temp-process-improvement-state-template.md) - Template for tracking multi-session process improvement implementation (via `New-TempTaskState.ps1 -Variant ProcessImprovement`)
- [Template: Document Creation Script](templates/support/document-creation-script-template.ps1) - PowerShell template for document creation scripts
- [Template: Update Script](templates/support/update-script-template.ps1) - PowerShell template for state update scripts

#### Meta Templates (`templates/templates/`)

- [Template: Framework Evaluation Report](templates/templates/framework-evaluation-report-template.md) - Template for structured framework evaluation reports with dimension scoring

### Automation Scripts

- [Process: New Feature Request Script](scripts/file-creation/01-planning/New-FeatureRequest.ps1) - PowerShell script for adding product feature requests to feature-request-tracking.md with auto-assigned PD-FRQ IDs
- [Process: New E2E Acceptance Test Case Script](scripts/file-creation/03-testing/New-E2EAcceptanceTestCase.ps1) - PowerShell script for creating E2E acceptance test case directories with auto-assigned E2E IDs, state tracking updates, and master test integration
- [Process: New Bug Report Script](scripts/file-creation/06-maintenance/New-BugReport.ps1) - PowerShell script for creating standardized bug reports during task execution
- [Process: New Bug Fix State Script](scripts/file-creation/06-maintenance/New-BugFixState.ps1) - PowerShell script for creating multi-session bug fix state tracking files (Large-effort bugs)
- [Process: New Handbook Script](scripts/file-creation/07-deployment/New-Handbook.ps1) - PowerShell script for creating user handbook documents with auto-assigned PD-UGD IDs
- [Process: New UI Design Script](scripts/file-creation/02-design/New-UIDesign.ps1) - PowerShell script for creating UI/UX Design documents with auto-assigned IDs and Design Guidelines references
- [Process: New Test Specification Script](scripts/file-creation/03-testing/New-TestSpecification.ps1) - PowerShell script for creating test specifications (supports both feature-specific and cross-cutting modes via -CrossCutting switch)
- [Process: New Process Improvement Script](scripts/file-creation/support/New-ProcessImprovement.ps1) - PowerShell script for adding new improvement opportunities to process-improvement-tracking.md with auto-assigned PF-IMP IDs (supports -BatchFile for bulk JSON input)
- [Process: New Framework Evaluation Report Script](scripts/file-creation/support/New-FrameworkEvaluationReport.ps1) - PowerShell script for creating structured framework evaluation reports with auto-assigned PF-EVR IDs
- [Process: New Test Infrastructure Script](scripts/file-creation/00-setup/New-TestInfrastructure.ps1) - Language-agnostic bootstrapping script for test directory structure, tracking files, and TE-id-registry from ../doc/project-config.json and language config
- [Process: New Quality Assessment Report Script](scripts/file-creation/00-setup/New-QualityAssessmentReport.ps1) - PowerShell script for creating Quality Assessment Reports for Target-State features during onboarding with auto-assigned PD-QAR IDs
- [Process: New Retrospective Master State Script](scripts/file-creation/00-setup/New-RetrospectiveMasterState.ps1) - PowerShell script for creating retrospective master state tracking files for parallel session coordination during PF-TSK-065/PF-TSK-066
- [Process: New Source Structure Script](scripts/file-creation/00-setup/New-SourceStructure.ps1) - Dual-mode script for source code directory scaffolding (-Scaffold) and directory tree maintenance (-Update) based on feature tracking and language config (PF-PRO-002)
- [Process: New Validation Tracking Script](scripts/file-creation/05-validation/New-ValidationTracking.ps1) - PowerShell script for creating validation tracking state files with auto-assigned PF-STA IDs for validation rounds (PF-TSK-077)
- [Process: Generate Validation Summary Script](scripts/file-creation/05-validation/Generate-ValidationSummary.ps1) - PowerShell script for generating consolidated validation summaries from multiple validation reports with codebase health scores and improvement roadmaps
- [Process: New Audit Tracking Script](scripts/file-creation/03-testing/New-AuditTracking.ps1) - PowerShell script for creating test audit tracking state files with auto-populated inventory from test-tracking.md for multi-session audit rounds (PF-TSK-030)
- [Process: New Prioritization Matrix Script](scripts/file-creation/cyclical/New-PrioritizationMatrix.ps1) - PowerShell script for creating technical debt prioritization matrices with auto-assigned PD-TDA IDs (PF-TSK-023)
- [Process: New API Documentation Script](scripts/file-creation/02-design/New-APIDocumentation.ps1) - PowerShell script for creating user-facing API documentation with auto-assigned PD-API IDs (PF-TSK-020)
- [Process: New Review Summary Script](scripts/file-creation/06-maintenance/New-ReviewSummary.ps1) - PowerShell script for creating Tools Review Summary documents with auto-assigned ART-REV IDs and timestamped filenames (PF-TSK-010)

### Testing Scripts

- [Process: Run-Tests Script](scripts/test/Run-Tests.ps1) - Language-agnostic test runner that reads ../doc/project-config.json and languages-config/{language}/{language}-config.json for dynamic category-based execution (-Category, -Quick, -All, -Coverage, -ListCategories)
- [Process: Language Configurations](languages-config/README.md) - Language-specific command configurations for framework scripts (testing, linting, coverage)
- [Process: Setup-TestEnvironment Script](scripts/test/e2e-acceptance-testing/Setup-TestEnvironment.ps1) - Copies pristine test fixtures into workspace for clean E2E acceptance test execution
- [Process: Verify-TestResult Script](scripts/test/e2e-acceptance-testing/Verify-TestResult.ps1) - Compares workspace state against expected state after E2E acceptance test execution
- [Process: Run-E2EAcceptanceTest Script](scripts/test/e2e-acceptance-testing/Run-E2EAcceptanceTest.ps1) - Orchestrates scripted E2E acceptance test pipeline: Setup → run.ps1 → wait → Verify
- [Process: Update-TestExecutionStatus Script](scripts/test/e2e-acceptance-testing/Update-TestExecutionStatus.ps1) - Updates e2e-test-tracking.md and feature-tracking.md with E2E acceptance test execution results

### State Update Scripts

- [Process: Update Process Improvement Script](scripts/update/Update-ProcessImprovement.ps1) - Automates status transitions and completion moves in process-improvement-tracking.md
- [Process: Update Feature Request Script](scripts/update/Update-FeatureRequest.ps1) - Classifies and closes feature requests in feature-request-tracking.md, updates feature-tracking.md for enhancements
- [Process: Update Tech Debt Script](scripts/update/Update-TechDebt.ps1) - Automates technical debt lifecycle management: add new items (-Add), status transitions, and resolution moves in technical-debt-tracking.md
- [Process: Update Language Config Script](scripts/update/Update-LanguageConfig.ps1) - Adds fields consistently across all language config files and template to prevent drift (-List to audit, -Section/-FieldName to add)
- [Process: Update Feature Dependencies Script](scripts/update/Update-FeatureDependencies.ps1) - Auto-generates feature-dependencies.md from feature state files (Mermaid graph + priority matrix). Integrated into Validate-StateTracking.ps1 Surface 6
- [Process: Update User Documentation State Script](scripts/update/Update-UserDocumentationState.ps1) - Automates PF-TSK-081 finalization: appends handbook row to feature state file Documentation Inventory and adds entry to documentation-map.md User Handbooks section
- [Process: Update Retrospective Master State Script](scripts/update/Update-RetrospectiveMasterState.ps1) - Atomic updates to retrospective master state Feature Inventory (claim/complete features, recalculate Progress Overview counters) for parallel session coordination during PF-TSK-065/PF-TSK-066

### Validation Scripts

- [Process: Validate ID Registry](scripts/validation/Validate-IdRegistry.ps1) - Validates ID registry against actual files in the repository
- [Process: Validate Test Tracking](scripts/validation/Validate-TestTracking.ps1) - Validates pytest markers (via test_query.py) consistency with test-tracking.md and actual test files on disk
- [Process: Validate State Tracking](scripts/validation/Validate-StateTracking.ps1) - Master validation across 13 surfaces: feature-tracking links, feature state files, test-tracking, cross-references, ID counters, feature dependencies, dimension consistency, workflow tracking, task registry completeness, metadata schema conformance, context map orphan detection, ai-tasks.md consistency, and master state consistency
- [Process: Validate Onboarding Completeness](scripts/validation/Validate-OnboardingCompleteness.ps1) - Validates 100% source file coverage and feature state file existence after Codebase Feature Discovery (PF-TSK-064)
- [Process: Validate Feedback Forms](scripts/validation/Validate-FeedbackForms.ps1) - Validates feedback forms for completeness and identifies forms with template placeholders
- [Process: Quick Validation Check](scripts/validation/Quick-ValidationCheck.ps1) - Quick health check for selected features covering code quality, architectural consistency, and implementation status
- [Process: Run Foundational Validation](scripts/validation/Run-FoundationalValidation.ps1) - Comprehensive feature validation across all 6 validation types with detailed reports and tracking updates
- [Process: Validate Audit Report](scripts/validation/Validate-AuditReport.ps1) - Validates Test Audit Reports for completeness, consistency, and quality standards

### Guides

#### 00 - Setup Guides

- [Guide: Onboarding Edge Cases](guides/00-setup/onboarding-edge-cases.md) - Edge-case guidance for ambiguous file assignment, shared utilities, and confidence tagging during codebase onboarding
- [Guide: Source Code Layout](guides/00-setup/source-code-layout-guide.md) - How to fill in the source layout doc, layer definitions, sublayer thresholds, file placement guidance, scale transition criteria

#### 01 - Planning Guides

- [Guide: Assessment](guides/01-planning/assessment-guide.md) - Guide for feature tier assessment
- [Guide: Architectural Framework Usage](guides/01-planning/architectural-framework-usage-guide.md) - Step-by-step guide for using the Architectural Integration Framework to manage cross-cutting architectural work
- [Guide: Feature Granularity](guides/01-planning/feature-granularity-guide.md) - Defines well-scoped features and provides practical tests for validating feature granularity

#### 02 - Design Guides

- [Guide: TDD Creation](guides/02-design/tdd-creation-guide.md) - Guide for customizing Technical Design Document templates
- [Guide: FDD Customization](guides/02-design/fdd-customization-guide.md) - Guide for customizing Functional Design Document templates
- [Guide: UI Design Customization](guides/02-design/ui-design-customization-guide.md) - 19-step guide across 6 phases for customizing UI/UX Design Document templates with tiered examples
- [Guide: API Specification Creation](guides/02-design/api-specification-creation-guide.md) - Guide for customizing API specification templates
- [Guide: API Data Model Creation](guides/02-design/api-data-model-creation-guide.md) - Guide for customizing API data model templates
- [Guide: Architecture Assessment Creation](guides/02-design/architecture-assessment-creation-guide.md) - Guide for customizing architecture assessment templates
- [Guide: Architecture Decision Creation](guides/02-design/architecture-decision-creation-guide.md) - Guide for customizing Architecture Decision Record templates
- [Guide: Schema Design Creation](guides/02-design/schema-design-creation-guide.md) - Guide for customizing database schema design templates

#### 03 - Testing Guides

- [Guide: Test Specification Creation](guides/03-testing/test-specification-creation-guide.md) - Comprehensive guide for using the Test Specification Creation task effectively
- [Guide: Test Audit Usage](guides/03-testing/test-audit-usage-guide.md) - Comprehensive guide for conducting systematic test quality assessments
- [Guide: Test Infrastructure](guides/03-testing/test-infrastructure-guide.md) - How the test/ directory connects to the process framework — directory conventions, automation scripts, tracking relationships, and new-project scaffolding
- [Guide: Test File Creation](guides/03-testing/test-file-creation-guide.md) - Guide for customizing test file templates
- [Guide: Integration & Testing Usage](guides/03-testing/integration-and-testing-usage-guide.md) - Comprehensive guide for using the Integration & Testing task (PF-TSK-053) effectively
- [Guide: E2E Acceptance Test Case Customization](guides/03-testing/e2e-acceptance-test-case-customization-guide.md) - Step-by-step instructions for customizing E2E acceptance test case and master test templates created by New-E2EAcceptanceTestCase.ps1

#### 04 - Implementation Guides

- [Guide: Development](guides/04-implementation/development-guide.md) - Best practices and guidelines for development
- [Guide: Definition of Done](guides/04-implementation/definition-of-done.md) - Clear criteria for when a feature is considered complete
- [Guide: Foundation Feature Implementation Usage](guides/04-implementation/foundation-feature-implementation-usage-guide.md) - Comprehensive guide for using the Foundation Feature Implementation task effectively
- [Guide: Feature Implementation State Tracking](guides/04-implementation/feature-implementation-state-tracking-guide.md) - How to create and maintain feature implementation state tracking documents
- [Guide: Enhancement State Tracking Customization](guides/04-implementation/enhancement-state-tracking-customization-guide.md) - Step-by-step instructions for customizing Enhancement State Tracking files
- [Guide: Implementation Plan Customization](guides/04-implementation/implementation-plan-customization-guide.md) - How to use New-ImplementationPlan.ps1 and customize implementation plan templates

#### 05 - Validation Guides

- [Guide: Documentation](guides/05-validation/documentation-guide.md) - Guidelines for documentation
- [Guide: Feature Validation](guides/05-validation/feature-validation-guide.md) - Comprehensive guide for conducting feature validation using the 6-type validation framework

#### 06 - Maintenance Guides

- [Guide: Code Refactoring Task Usage](guides/06-maintenance/code-refactoring-task-usage-guide.md) - Comprehensive guide for using the Code Refactoring Task effectively
- [Guide: Bug Reporting](guides/06-maintenance/bug-reporting-guide.md) - Standardized procedures for reporting bugs discovered during task execution

#### 07 - Deployment Guides

- [Guide: CI/CD Setup](guides/07-deployment/ci-cd-setup-guide.md) - Guide for scaffolding CI/CD infrastructure (pipelines, pre-commit hooks, dev scripts)

#### Cyclical Guides

- [Guide: Assessment Criteria](guides/cyclical/assessment-criteria-guide.md) - Detailed criteria for identifying technical debt
- [Guide: Prioritization](guides/cyclical/prioritization-guide.md) - Guide for applying impact/effort matrix to prioritize debt
- [Guide: Debt Item Creation](guides/cyclical/debt-item-creation-guide.md) - Guide for customizing technical debt item templates

#### Framework Guides

- [Guide: Development Dimensions](guides/framework/development-dimensions-guide.md) - Single authoritative reference for 10 development dimensions across all task phases (planning, implementation, review, validation)
- [Guide: Terminology](guides/framework/terminology-guide.md) - Explains the terminology separation between Process Framework and Product Documentation
- [Guide: Documentation Structure](guides/framework/documentation-structure-guide.md) - Guide for organizing documentation structure within the framework
- [Guide: Feedback Form](guides/framework/feedback-form-guide.md) - Comprehensive guide for completing feedback forms effectively
- [Guide: Feedback Form Completion Instructions](guides/framework/feedback-form-completion-instructions.md) - Standardized instructions for completing feedback forms (referenced by all tasks)
- [Guide: Task Transition](guides/framework/task-transition-guide.md) - Guidance on when and how to transition between related tasks

#### Support Guides

- [Guide: Visual Notation](guides/support/visual-notation-guide.md) - Standard notation used in diagrams and context maps
- [Guide: Script Development Quick Reference](guides/support/script-development-quick-reference.md) - Quick reference for common script development issues and solutions
- [Guide: Guide Creation Best Practices](guides/support/guide-creation-best-practices-guide.md) - Best practices for creating effective guides within the task framework
- [Guide: State File Creation](guides/support/state-file-creation-guide.md) - Guide for customizing state tracking file templates
- [Guide: Temporary State File Customization](guides/support/temp-state-tracking-customization-guide.md) - Guide for customizing temporary state files for different workflows
- [Guide: Framework Extension Customization](guides/support/framework-extension-customization-guide.md) - Essential guide for customizing Framework Extension Concept documents
- [Guide: Migration Best Practices](guides/support/migration-best-practices.md) - Best practices for migrating documentation and framework components
- [Guide: Process Improvement Task Implementation](guides/support/process-improvement-task-implementation-guide.md) - Practical instructions for executing the Process Improvement task (PF-TSK-009)
- [Guide: Task Creation](guides/support/task-creation-guide.md) - Guide for creating and improving task definitions
- [Guide: Visualization Creation](guides/support/visualization-creation-guide.md) - Guide for creating context maps and other visualizations
- [Guide: Template Development](guides/support/template-development-guide.md) - Guide for developing and maintaining framework templates
- [Guide: Document Creation Script Development](guides/support/document-creation-script-development-guide.md) - Standardized approach for creating documents from templates through PowerShell scripts

### Visualization Resources

- [Context Maps README](visualization/context-maps/README.md) - Guide to using context maps for tasks
- [Context Maps Template](templates/support/context-map-template.md) - Template for creating new context maps

#### 00 - Setup Context Maps

- [Codebase Feature Discovery Map](visualization/context-maps/00-setup/codebase-feature-discovery-map.md) - Components for discovering features in existing codebases
- [Codebase Feature Analysis Map](visualization/context-maps/00-setup/codebase-feature-analysis-map.md) - Components for analyzing implementation patterns and dependencies
- [Retrospective Documentation Creation Map](visualization/context-maps/00-setup/retrospective-documentation-creation-map.md) - Components for creating retrospective design documentation

#### 01 - Planning Context Maps

- [Feature Discovery Map](visualization/context-maps/01-planning/feature-discovery-map.md) - Components for exploring features
- [Feature Request Evaluation Map](visualization/context-maps/01-planning/feature-request-evaluation-map.md) - Components for classifying change requests and scoping enhancements
- [Feature Tier Assessment Map](visualization/context-maps/01-planning/feature-tier-assessment-map.md) - Components for assessing complexity
- [System Architecture Review Map](visualization/context-maps/01-planning/system-architecture-review-map.md) - Components for evaluating system architecture

#### 02 - Design Context Maps

- [API Design Map](visualization/context-maps/02-design/api-design-task-map.md) - Components for designing API contracts and specifications
- [FDD Creation Map](visualization/context-maps/02-design/fdd-creation-map.md) - Components for creating Functional Design Documents
- [TDD Creation Map](visualization/context-maps/02-design/tdd-creation-map.md) - Components for creating design documents

#### 03 - Testing Context Maps

- [Test Specification Creation Map](visualization/context-maps/03-testing/test-specification-creation-map.md) - Components for creating test specifications from TDDs
- [E2E Acceptance Test Case Creation Map](visualization/context-maps/03-testing/e2e-acceptance-test-case-creation-map.md) - Components for creating concrete E2E acceptance test cases from test specifications
- [E2E Acceptance Test Execution Map](visualization/context-maps/03-testing/e2e-acceptance-test-execution-map.md) - Components for executing E2E acceptance test cases and recording results
- [Test Audit Map](visualization/context-maps/03-testing/test-audit-map.md) - Components for systematic test quality assessment workflow

#### 04 - Implementation Context Maps

- [Feature Enhancement Map](visualization/context-maps/04-implementation/feature-enhancement-map.md) - Components for executing enhancement steps from state file
- [Feature Implementation Map](visualization/context-maps/04-implementation/feature-implementation-map.md) - Components for implementing features
- [Integration & Testing Map](visualization/context-maps/04-implementation/integration-and-testing-map.md) - Components for implementing comprehensive tests and validating integration
- [UI Implementation Map](visualization/context-maps/04-implementation/ui-implementation-map.md) - Components for building user interface components and layouts
- [State Management Implementation Map](visualization/context-maps/04-implementation/state-management-implementation-map.md) - Components for implementing state management layer connecting data to UI
- [Quality Validation Map](visualization/context-maps/04-implementation/quality-validation-map.md) - Components for validating implementation against quality standards and acceptance criteria
- [Implementation Finalization Map](visualization/context-maps/04-implementation/implementation-finalization-map.md) - Components for completing remaining items and preparing feature for production

#### 05 - Validation Context Maps

- [Validation Preparation Map](visualization/context-maps/05-validation/validation-preparation-map.md) - Components for planning validation rounds and creating tracking state files
- [Architectural Consistency Validation Map](visualization/context-maps/05-validation/architectural-consistency-validation-map.md) - Components for validating architectural pattern adherence and ADR compliance
- [Code Quality Standards Validation Map](visualization/context-maps/05-validation/code-quality-standards-validation-map.md) - Components for validating code quality standards and SOLID principles
- [Integration Dependencies Validation Map](visualization/context-maps/05-validation/integration-dependencies-validation-map.md) - Components for validating dependency health, interface contracts, and data flow integrity
- [Documentation Alignment Validation Map](visualization/context-maps/05-validation/documentation-alignment-validation-map.md) - Components for validating TDD alignment, ADR compliance, and API documentation accuracy
- [Extensibility Maintainability Validation Map](visualization/context-maps/05-validation/extensibility-maintainability-validation-map.md) - Components for validating extension points, configuration flexibility, and testing support
- [AI Agent Continuity Validation Map](visualization/context-maps/05-validation/ai-agent-continuity-validation-map.md) - Components for validating context clarity, modular structure, and documentation quality for AI agent workflow continuity
- [Security & Data Protection Validation Map](visualization/context-maps/05-validation/security-data-protection-validation-map.md) - Components for validating security best practices, data protection, and secrets management
- [Performance & Scalability Validation Map](visualization/context-maps/05-validation/performance-scalability-validation-map.md) - Components for validating performance characteristics, resource efficiency, and scalability patterns
- [Observability Validation Map](visualization/context-maps/05-validation/observability-validation-map.md) - Components for validating logging coverage, monitoring instrumentation, and diagnostic traceability
- [Accessibility / UX Compliance Validation Map](visualization/context-maps/05-validation/accessibility-ux-compliance-validation-map.md) - Components for validating accessibility standards, UX compliance, and inclusive design patterns
- [Data Integrity Validation Map](visualization/context-maps/05-validation/data-integrity-validation-map.md) - Components for validating data consistency, constraint enforcement, and recovery patterns

#### 06 - Maintenance Context Maps

- [Bug Fixing Map](visualization/context-maps/06-maintenance/bug-fixing-map.md) - Components for fixing bugs
- [Code Refactoring Map](visualization/context-maps/06-maintenance/code-refactoring-task-map.md) - Components for systematic code improvement and technical debt reduction
- [Code Review Map](visualization/context-maps/06-maintenance/code-review-map.md) - Components for reviewing code changes

#### 07 - Deployment Context Maps

- [Release Deployment Map](visualization/context-maps/07-deployment/release-deployment-map.md) - Components for deployment
- [User Documentation Creation Map](visualization/context-maps/07-deployment/user-documentation-creation-map.md) - Components for creating and maintaining user-facing handbook documentation
- [Git Commit and Push Map](visualization/context-maps/07-deployment/git-commit-and-push-map.md) - Context map for Git Commit and Push task

#### Cyclical Context Maps

- [Documentation Tier Adjustment Map](visualization/context-maps/cyclical/documentation-tier-adjustment-map.md) - Components for adjusting tiers
- [Technical Debt Assessment Map](visualization/context-maps/cyclical/technical-debt-assessment-task-map.md) - Context map for Technical Debt Assessment task

#### Support Context Maps

- [Process Improvement Map](visualization/context-maps/support/process-improvement-map.md) - Components for improving processes
- [Structure Change Map](visualization/context-maps/support/structure-change-map.md) - Components for structural changes
- [Framework Extension Task Map](visualization/context-maps/support/framework-extension-task-map.md) - Context map for Framework Extension Task showing component relationships and workflow
- [Framework Evaluation Map](visualization/context-maps/support/framework-evaluation-map.md) - Context map for Framework Evaluation task showing evaluation scope, dimensions, and output relationships
- [Framework Domain Adaptation Map](visualization/context-maps/support/framework-domain-adaptation-map.md) - Context map for Framework Domain Adaptation task showing adaptation phases, document classification, and execution flow
- [Tools Review Map](visualization/context-maps/support/tools-review-map.md) - Components for reviewing tools


## Maintaining This Documentation

When adding new process framework documentation:
1. Add the entry to the appropriate section in this map
2. Use local relative paths from `process-framework` (no `../process-framework/` prefix needed)
3. For product documentation (FDDs, TDDs, ADRs, validation reports, handbooks), add to [Product Documentation Map](/doc/PD-documentation-map.md) instead
4. For test documentation (test specs, audit reports), add to [Test Documentation Map](/test/TE-documentation-map.md) instead
