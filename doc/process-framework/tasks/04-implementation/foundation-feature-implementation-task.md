---
id: PF-TSK-024
type: Process Framework
category: Task Definition
version: 1.2
created: 2025-07-26
updated: 2026-03-25
task_type: Discrete
---

# Foundation Feature Implementation Task

## Purpose & Context

Specialized task for implementing foundation features (0.x.x) that provide architectural foundations for the application

## AI Agent Role

**Role**: Software Architect
**Mindset**: Systems thinking, long-term vision, pattern-focused
**Focus Areas**: Cross-cutting concerns, reusable patterns, system integration, architectural foundations
**Communication Style**: Discuss architectural implications and long-term impact, ask about system-wide effects and pattern consistency

## When to Use

- When implementing foundation features (version 0.x.x) that provide architectural foundations for the application
- When a feature has cross-cutting concerns that affect multiple parts of the system
- When implementing features that establish patterns for other features to follow
- When architectural decisions need to be documented alongside feature implementation
- When foundation work requires integration with Architecture Context Packages and Architecture Tracking

## Context Requirements

<!-- [View Context Map for this task](../../../visualization/context-maps/[task-type]/[task-name]-map.md) - Template/example link commented out -->

- **Critical (Must Read):**

  - [Foundation Feature Template](../../templates/04-implementation/foundation-feature-template.md) - Template for foundation feature structure and architectural documentation

  - [Architecture Tracking](../../../product-docs/state-tracking/permanent/architecture-tracking.md) - Ongoing architectural decisions and evolution

- **Important (Load If Space):**

  - [Architectural Framework Usage Guide](../../guides/01-planning/architectural-framework-usage-guide.md) - **ESSENTIAL**: Step-by-step guide for using the architectural framework
  - [Feature Implementation Planning](feature-implementation-planning-task.md) - Base implementation planning process for comparison
  - [ADR Template](../../templates/02-design/adr-template.md) - For documenting architectural decisions
  - [Foundation Feature Implementation Usage Guide](../../guides/04-implementation/foundation-feature-implementation-usage-guide.md) - Task-specific usage guide

- **Reference Only (Access When Needed):**
  - [Technical Design Document Template](../../templates/02-design/tdd-t3-template.md) - For complex architectural specifications
  - [Documentation Map](../../documentation-map.md) - For understanding document relationships
  - [Visual Notation Guide](/doc/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the appropriate automation tools where indicated.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Review Architecture Context**: Study current architectural foundations
2. **Review Dimension Profile**: Read the feature's Dimension Profile from its implementation state file. Foundation features (0.x.x) typically have Critical AC and EM dimensions — verify the profile and note all Critical dimensions that must be explicitly addressed during implementation
3. **Analyze Cross-Cutting Impact**: Identify which components and features will be affected by this foundation implementation
4. **Create Foundation Feature Structure**: Use [Foundation Feature Template](../../templates/04-implementation/foundation-feature-template.md) to establish the feature structure
5. **🚨 CHECKPOINT**: Present architecture context review, dimension profile review, cross-cutting impact analysis, and foundation feature structure to human partner for approval before implementation

### Execution

6. **Implement Core Foundation Logic**: Develop the foundational functionality with architectural awareness, ensuring Critical dimensions from the Dimension Profile are addressed throughout implementation
7. **Document Architectural Decisions**: Create ADRs for significant architectural choices made during implementation
   ```powershell
   # Create ADR for architectural decisions
   cd doc/process-framework/templates
   ../../scripts/file-creation/02-design/New-ArchitectureDecision.ps1 -Title "Foundation Feature Architecture Decision" -Context "Foundation implementation context"
   ```
8. **Update Architecture Context**: Document new architectural foundations
9. **Establish Patterns**: Document reusable patterns that other features can follow
10. **Implement Tests**: Create tracked tests that validate both functionality and architectural constraints using `New-TestFile.ps1`

   ```powershell
   # Create test files using automation script (writes pytest markers)
   # Test types depend on project language (auto-detected from project-config.json)
   cd doc/process-framework/scripts/file-creation/03-testing
   .\New-TestFile.ps1 -TestName "FeatureName" -TestType "Unit" -FeatureId "0.X.Z" -ComponentName "ComponentName" -Priority "Critical"

   # Use Critical priority for foundation features
   # Script automatically:
   # - Writes pytest markers (feature, priority, test_type)
   # - Creates test file from template with proper structure
   # - Updates test-tracking.md with correct file links and status
   # - Updates feature-tracking.md with test implementation progress
   ```
11. **🚨 CHECKPOINT**: Present core foundation implementation, architectural decisions, established patterns, test results, and dimension profile compliance to human partner for review before finalization

### Finalization

12. **Bug Discovery During Foundation Implementation**: Systematically identify and document any bugs discovered during foundation implementation:

   - **Architectural Issues**: Problems with system design or component interactions
   - **Integration Problems**: Issues with existing system integration points
   - **Performance Issues**: Foundation-level performance bottlenecks or inefficiencies
   - **Cross-Cutting Concerns**: Problems affecting multiple system components
   - **Foundation Logic Errors**: Bugs in core foundational functionality
   - **Dependency Issues**: Problems with external dependencies or libraries

13. **Report Discovered Bugs**: If bugs are identified during foundation implementation:

    - Use [../../scripts/file-creation/06-maintenance/New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../../product-docs/state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
    - Include foundation implementation context and evidence in bug reports
    - Reference specific architectural components or patterns affected
    - Note impact on system architecture and dependent features

    **Example Bug Report Command**:

    ```powershell
    # Navigate to the scripts directory from project root
    Set-Location "doc/process-framework/scripts/file-creation"

    # Create bug report for issues found during foundation implementation
    ../../scripts/file-creation/06-maintenance/New-BugReport.ps1 -Title "Foundation module causes circular dependency" -Description "New foundation module creates circular dependency between service components" -DiscoveredBy "FeatureImplementation" -Severity "Critical" -Component "Core Foundation" -Environment "Development" -Evidence "Architecture analysis: circular dependency in src/core/"
    ```

14. **Update Architecture Tracking**: Record the foundation implementation in [Architecture Tracking](../../../product-docs/state-tracking/permanent/architecture-tracking.md)
15. **Verify Cross-Cutting Integration**: Ensure the foundation properly integrates with existing system components
16. **Document Usage Patterns**: Update documentation to show how other features should interact with this foundation
17. **Flag User Documentation Status**: If this foundation feature has user-visible behavior (CLI options, configuration, workflows), set the User Documentation section in the feature implementation state file to `❌ Needed`. This triggers [User Documentation Creation](../07-deployment/user-documentation-creation.md) later in the workflow. If the feature is internal-only, set to `N/A`.
18. **Run Foundational Validation**: Execute automated validation to ensure implementation meets foundational standards:

    **Quick Health Check** (recommended for immediate feedback):

    ```powershell
    # Navigate to validation scripts directory
    Set-Location "scripts\validation"

    # Run quick validation check for immediate feedback
    .\Quick-ValidationCheck.ps1

    # Or run specific checks only
    .\Quick-ValidationCheck.ps1 -CheckType "CodeQuality"
    .\Quick-ValidationCheck.ps1 -CheckType "Structure"
    ```

    **Comprehensive Validation** (recommended for feature completion):

    ```powershell
    # Navigate to validation scripts directory
    Set-Location "scripts\validation"

    # Run comprehensive foundational validation for the implemented feature
    .\Run-FoundationalValidation.ps1 -FeatureIds "[FEATURE-ID]" -ValidationType "All" -GenerateReports -UpdateTracking

    # Example for specific feature
    .\Run-FoundationalValidation.ps1 -FeatureIds "0.2.1" -ValidationType "All" -GenerateReports -UpdateTracking -Detailed
    ```

    **Validation Types Available**:

    - `ArchitecturalConsistency` - Validates design patterns and architectural compliance
    - `CodeQualityStandards` - Checks code style, complexity, and SOLID principles
    - `IntegrationDependencies` - Validates service integration and state management
    - `DocumentationAlignment` - Ensures documentation matches implementation
    - `ExtensibilityMaintainability` - Assesses modularity and scalability
    - `AIAgentContinuity` - Validates code readability and context optimization
    - `All` - Runs all validation types (recommended)

19. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Foundation Feature Implementation** - Complete implementation of the foundation feature with architectural awareness
- **Architectural Decision Records (ADRs)** - Documentation of significant architectural decisions made during implementation
- **Updated Architecture Context Packages** - Modifications to reflect new architectural foundations and patterns
- **Updated Architecture Tracking** - Record of foundation implementation and its impact on system architecture
- **Foundation Usage Patterns** - Documentation of how other features should interact with this foundation
- **Comprehensive Test Suite** - Tests that validate both functionality and architectural constraints
- **Validation Reports** - Automated validation reports confirming implementation meets foundational standards (generated in `scripts/validation/validation-reports/`)
- **Bug Reports** - Any bugs discovered during foundation implementation documented in [Bug Tracking](../../../product-docs/state-tracking/permanent/bug-tracking.md) with status 🆕 Reported

## State Tracking

### Automated Updates (via `New-TestFile.ps1`)

- [Test Tracking](../../../../test/state-tracking/permanent/test-tracking.md) - Automatically updated with test file links and status
- [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) - Automatically updated with test implementation progress

### Manual Updates


- [Architecture Tracking](../../../product-docs/state-tracking/permanent/architecture-tracking.md) - Record foundation implementation and architectural evolution
- [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) - Update with foundation feature status (set to "👀 Ready for Review" when implementation and testing are complete)

**Automation Available**: Use `Update-FeatureImplementationState.ps1` to automate state file updates. See [Automation Usage Guide](../../scripts/AUTOMATION-USAGE-GUIDE.md) for examples.

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Foundation feature implementation is complete and functional
  - [ ] ADRs created for all significant architectural decisions
  - [ ] Foundation usage patterns documented
  - [ ] Comprehensive test suite created via `New-TestFile.ps1` and passing
  - [ ] Foundational validation executed and reports generated (using Quick-ValidationCheck.ps1 and/or Run-FoundationalValidation.ps1)
  - [ ] Validation reports show acceptable quality scores (average ≥ 2.0 on 4-point scale)
  - [ ] Bug discovery performed systematically during foundation implementation
  - [ ] Any discovered bugs reported using ../../scripts/file-creation/06-maintenance/New-BugReport.ps1 script with proper context and evidence
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Test tracking files automatically updated by `New-TestFile.ps1` (verify correctness)

  - [ ] [Architecture Tracking](../../../product-docs/state-tracking/permanent/architecture-tracking.md) updated with implementation record
  - [ ] [Feature Tracking](../../../product-docs/state-tracking/permanent/feature-tracking.md) updated with status set to "👀 Ready for Review"
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-024" and context "Foundation Feature Implementation Task"

## Next Tasks

- [**Code Review Task**](../06-maintenance/code-review-task.md) - Review foundation implementation for quality and architectural compliance
- [**Feature Implementation Planning**](feature-implementation-planning-task.md) - Plan and implement regular features that build upon this foundation

## Related Resources


- [Architecture Tracking](../../../product-docs/state-tracking/permanent/architecture-tracking.md) - Architectural evolution tracking
