---
id: PF-TSK-078
type: Process Framework
category: Task Definition
domain: agnostic
version: 1.0
created: 2026-03-24
updated: 2026-03-24
---

# Core Logic Implementation

## Purpose & Context

Implement core business logic modules, wire integration points, and write unit tests for non-foundation features. This is the general-purpose "write the code" task in the decomposed implementation chain, filling the gap between Feature Implementation Planning (which creates the roadmap) and Integration & Testing (which validates the assembled system).

## AI Agent Role

**Role**: Senior Software Engineer
**Mindset**: Pragmatic, quality-focused, pattern-consistent
**Focus Areas**: Clean code, existing pattern adherence, testability, incremental delivery
**Communication Style**: Present implementation choices with trade-offs, flag deviations from TDD/FDD specifications, ask about edge cases and acceptance criteria

## When to Use

- After Feature Implementation Planning (PF-TSK-044) has created the implementation roadmap and feature state file
- When implementing non-foundation features (1.x.x+, 2.x.x+, etc.) that do not require the architectural depth of Foundation Feature Implementation (PF-TSK-022)
- When the feature does not need a separate Data Layer Implementation phase (PF-TSK-051) — or after PF-TSK-051 has completed the data layer
- For Tier 1 features where planning and implementation are lightweight (create module, wire integration, write tests)
- For Tier 2/3 features as the core coding phase between data layer setup and integration testing
- **Prerequisites**: Implementation plan completed (PF-TSK-044), design documentation available (TDD/FDD if applicable), feature state file created

## Context Requirements

[View Context Map for this task](../../visualization/context-maps/04-implementation/core-logic-implementation-map.md)

- **Critical (Must Read):**

  - **Feature Implementation State File** - The permanent state tracking document containing implementation progress, task sequence, context, and **Dimension Profile**
  - **Implementation Plan** - Task sequence and dependencies from Feature Implementation Planning (PF-TSK-044)
  - **TDD (Technical Design Document)** - Module specifications, interface contracts, and component design (if Tier 2+)

- **Important (Load If Space):**

  - **FDD (Functional Design Document)** - Business requirements and acceptance criteria (if Tier 2+)
  - **Existing Source Code** - Review similar modules in the source directory for patterns and conventions
  - [Development Guide](/process-framework/guides/04-implementation/development-guide.md) - Coding best practices and conventions
  - [Definition of Done](/process-framework/guides/04-implementation/definition-of-done.md) - Completion criteria

- **Reference Only (Access When Needed):**
  - **Test Specification** - Expected test coverage and test case details (if created)
  - [Bug Reporting Guide](/process-framework/guides/06-maintenance/bug-reporting-guide.md) - For documenting bugs discovered during implementation
  - [Visual Notation Guide](/process-framework/guides/support/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Update the Feature Implementation State file throughout this task.**
>
> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Review Implementation Context**: Load the Feature Implementation State file and Implementation Plan
   - Understand which modules and components need to be created
   - Review task dependencies — confirm prerequisite tasks (data layer, etc.) are complete
   - Identify the specific deliverables for this coding phase
   - **Read the feature's Dimension Profile** — note Critical dimensions that require explicit attention during implementation (e.g., SE Critical → validate all inputs, PE Critical → avoid O(n²) patterns)
2. **Review Design Documentation**: Study the TDD and FDD (if applicable)
   - Understand interface contracts and module responsibilities
   - Note configuration points and extension requirements
   - Identify integration touchpoints with existing code
3. **Study Existing Patterns**: Review similar implementations in the codebase
   - Examine how comparable modules are structured
   - Note naming conventions, error handling approaches, and logging patterns
   - Identify reusable utilities or base classes
4. **🚨 CHECKPOINT**: Present implementation scope summary to human partner:
   - Which modules/files will be created or modified
   - Which patterns from existing code will be followed
   - Any design questions or ambiguities discovered

### Execution

5. **Create Module Structure**: Set up the module files and directory structure
   - Create source files following project conventions
   - Set up module exports and public API surface
   - Add configuration registration if needed
6. **Implement Core Logic**: Write the business logic incrementally
   - Implement one component/class at a time
   - Follow TDD specifications for interfaces and behavior
   - Use existing patterns for error handling, logging, and validation
   - Wire integration points (CLI commands, service registration, event hooks)
7. **Write Unit Tests**: Create tracked test files alongside the implementation using `New-TestFile.ps1`

   ```powershell
   # Create test files using automation script (writes pytest markers)
   # Test types depend on project language (auto-detected from project-config.json)
   cd process-framework/scripts/file-creation/03-testing
   .\New-TestFile.ps1 -TestName "FeatureName" -TestType "Unit" -FeatureId "X.Y.Z" -ComponentName "ComponentName"

   # Script automatically:
   # - Writes pytest markers (feature, priority, test_type)
   # - Creates test file from template with proper structure
   # - Updates test-tracking.md with correct file links and status
   # - Updates feature-tracking.md with test implementation progress
   ```

   - Test public API and critical code paths
   - Cover error handling and edge cases
   - Follow existing test patterns and conventions
   - Aim for coverage targets defined in the test specification (if available)
8. **🚨 CHECKPOINT**: Present implemented modules, test results, and any TDD deviations to human partner for review
   > **ADR trigger**: If this implementation involved a non-obvious design choice (e.g., choosing between competing patterns, introducing a new architectural pattern, making trade-offs not covered by existing ADRs), recommend creating an ADR via [ADR Creation](../02-design/adr-creation-task.md) (PF-TSK-028) as a follow-up task.

### Finalization

9. **Verify Implementation Completeness**:
   - Run all new unit tests — confirm they pass
   - Run existing test suite — confirm no regressions
   - Verify the module integrates correctly with the rest of the system
   - Check that all implementation plan items for this phase are addressed
   - **Verify Critical dimensions are addressed**: For each Critical dimension in the feature's Dimension Profile, confirm the implementation checklist from the [Development Dimensions Guide](../../guides/framework/development-dimensions-guide.md) has been followed
10. **Bug Discovery**: Systematically identify and document any bugs discovered during implementation or testing:
    - Implementation bugs (logic errors, edge case failures)
    - Integration problems (issues when wiring to existing components)
    - Error handling gaps (missing or inadequate error handling)
    - Tag discovered bugs with affected dimensions (e.g., `-Dims "SE,DI"`) when creating bug reports

    If bugs are found that will not be fixed in this session:

    ```powershell
    # Create standardized bug report
    cd process-framework/scripts/file-creation/06-maintenance
    .\New-BugReport.ps1 -Title "Brief description" -Description "Detailed description" -DiscoveredBy "Development" -Severity "High" -Component "ComponentName" -Environment "Development" -Evidence "Test case or code reference"
    ```

    - Follow [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Reported
11. **Update Feature Tracking**: Update [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) status to 🧪 Testing (feature is implemented and undergoing testing)
12. **Update Feature Implementation State**: Document completed work
    - Update code inventory with new modules and test files
    - Note any deviations from TDD/FDD specifications
    - Document issues encountered and resolutions
    - Mark this task as completed in the task sequence
13. **Flag User Documentation Status**: If this feature has user-visible behavior (CLI options, configuration, workflows), set the User Documentation section in the feature implementation state file to `❌ Needed`. This triggers [User Documentation Creation](../07-deployment/user-documentation-creation.md) later in the workflow. If the feature is internal-only, set to `N/A`.
14. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Source Modules** - New or modified source files implementing the feature's core business logic
- **Unit Tests** - Tracked test files (created via `New-TestFile.ps1`) covering the implemented logic, tracked via pytest markers
- **Integration Wiring** - CLI commands, service registrations, or event hooks connecting the new module to the system
- **Updated Feature Implementation State** - Code inventory and progress tracking updated with new components
- **Bug Reports** (if applicable) - Any bugs discovered during implementation documented via `New-BugReport.ps1` in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md)

## State Tracking

The following state files must be updated as part of this task:

### Automated Updates (via `New-TestFile.ps1`)

- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Automatically updated with test file links and status
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Test Status column automatically updated with implementation progress

### Manual Updates Required

- [Feature Implementation State Files](../../../doc/state-tracking/features) - Update the feature's state file with:
  - Task sequence tracking (mark core logic implementation as in_progress, then completed)
  - Code inventory with new source modules and test files
  - Implementation notes documenting any TDD/FDD deviations or design decisions
  - Issues log if any blockers or problems were encountered
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Update Implementation Status to 🧪 Testing (feature is implemented and undergoing testing)
- [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) - Add entries for any bugs discovered but not fixed in this session

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Source modules created and functional
  - [ ] Integration points wired (CLI, services, events as applicable)
  - [ ] Unit tests created via `New-TestFile.ps1` and all passing
  - [ ] Existing test suite passes (no regressions)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Feature Implementation State file updated with code inventory and task completion
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) status set to 🧪 Testing
  - [ ] Implementation notes document any deviations from design specifications
  - [ ] Test tracking files automatically updated by `New-TestFile.ps1` (verify correctness)
- [ ] **Bug Documentation**: Any bugs discovered but not fixed are documented
  - [ ] Bug reports created via `New-BugReport.ps1` (if applicable)
  - [ ] [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) updated with 🆕 Reported entries (if applicable)
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/framework/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-078" and context "Core Logic Implementation"

## Next Tasks

- [**Integration & Testing**](integration-and-testing.md) (PF-TSK-053) - Validate integration and establish comprehensive test coverage after core logic is implemented
- [**Quality Validation**](quality-validation.md) (PF-TSK-054) - Validate implementation against quality standards
- [**Implementation Finalization**](implementation-finalization.md) (PF-TSK-055) - Complete remaining items and prepare for production

## Related Resources

- [Feature Implementation Planning](feature-implementation-planning-task.md) (PF-TSK-044) - Creates the implementation roadmap this task executes from
- [Data Layer Implementation](data-layer-implementation.md) (PF-TSK-051) - May precede this task when database work is needed
- [Foundation Feature Implementation](foundation-feature-implementation-task.md) (PF-TSK-022) - Alternative for 0.x.x architectural foundation features
- [Development Guide](../../guides/04-implementation/development-guide.md) - Coding best practices
- [Definition of Done](../../guides/04-implementation/definition-of-done.md) - Completion criteria
- [Task Transition Guide](../../guides/framework/task-transition-guide.md) - Guidance on transitioning between decomposed tasks
