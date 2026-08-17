---
id: PF-TSK-024
type: Process Framework
category: Task Definition
version: 1.4
created: 2025-07-26
updated: 2026-07-28
description: "Implement foundation features (0.x.x) that provide architectural foundations for the application"
complexity: complex
use_when: >-
  Implementing foundation features (0.x.x) that provide architectural foundations for the application
automation: semi
scripts:
  - ../../scripts/validation/Quick-ValidationCheck.ps1
  - ../../scripts/file-creation/06-maintenance/New-BugReport.ps1
trigger_status:
  - raw: "`feature-tracking.md` + Feature impl state file → Feature ID = `0.x.x` + task = `not_started` in sequence"
output_status:
  - raw: "`feature-tracking.md` → `👀 Needs Review`; Feature impl state file → task = `completed`"
next_tasks:
  - task: ../06-maintenance/code-review-task.md
    condition: "Review foundation implementation for quality and architectural compliance"
  - task: feature-implementation-planning-task.md
    condition: "Plan and implement regular features that build upon this foundation"
---

# Foundation Feature Implementation Task

> **▶ Execute this task under the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md).** This file holds only this task's specific content; the universal contract every task shares lives once in the protocol and is mandatory here.

## Purpose & Context

Specialized task for implementing foundation features (0.x.x) that provide architectural foundations for the application

## AI Agent Role

**Role**: Software Architect
**Mindset**: Systems thinking, long-term vision, pattern-focused
**Focus Areas**: Cross-cutting concerns, reusable patterns, system integration, architectural foundations
**Communication Style**: Discuss architectural implications and long-term impact, ask about system-wide effects and pattern consistency

## Context Requirements

- **Critical (Must Read):**

  - [Foundation Feature Template](../../templates/04-implementation/foundation-feature-template.md) - Template for foundation feature structure and architectural documentation

  - [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md) - Ongoing architectural decisions and evolution

- **Important (Load If Space):**

  - [Architectural Framework Usage Guide](../../guides/01-planning/architectural-framework-usage-guide.md) - **ESSENTIAL**: Conceptual reference for the Architectural Integration Framework (components + context-loading order)
  - [Feature Implementation Planning](feature-implementation-planning-task.md) - Base implementation planning process for comparison
  - [ADR Template](../../templates/02-design/adr-template.md) - For documenting architectural decisions
  - [Source Code Layout](../../../doc/technical/architecture/source-code-layout.md) - Consult for correct file placement within feature directories

- **Reference Only (Access When Needed):**
  - [Technical Design Document Template](../../templates/02-design/tdd-t3-template.md) - For complex architectural specifications
  - [Documentation Map](../../PF-documentation-map.md) - For understanding document relationships

## Process

> **🚨 CRITICAL: All work MUST be implemented incrementally with explicit human feedback at EACH checkpoint.**
>
> **⚠️ MANDATORY: Never proceed past a checkpoint without presenting findings and getting explicit approval.**

### Preparation

1. **Check Recommended Skills**: Read the active language-config (`languages-config/{language}/{language}-config.json`) and `project-config.json` for `recommended_skills` entries keyed to `foundation-feature-implementation-task`. If a matching skill is available in the session, activate it before starting implementation work.
2. **Review Architecture Context**: Study current architectural foundations
3. **Review Dimension Profile**: Read the feature's Dimension Profile from its implementation state file. Foundation features (0.x.x) typically have Critical AC and EM dimensions — verify the profile and note all Critical dimensions that must be explicitly addressed during implementation
4. **Analyze Cross-Cutting Impact**: Identify which components and features will be affected by this foundation implementation
5. **Create Foundation Feature Structure**: Use [Foundation Feature Template](../../templates/04-implementation/foundation-feature-template.md) to establish the feature structure
6. **🚨 CHECKPOINT**: Present architecture context review, dimension profile review, cross-cutting impact analysis, and foundation feature structure to human partner for approval before implementation

### Execution

7. **Implement Core Foundation Logic**: Develop the foundational functionality with architectural awareness, ensuring Critical dimensions from the Dimension Profile are addressed throughout implementation
8. **Document Architectural Decisions**: If significant architectural choices were made during implementation, create ADRs using the script:
   ```powershell
   # Create ADR for architectural decisions
   process-framework/scripts/file-creation/02-design/New-ArchitectureDecision.ps1 -Title "Foundation Feature Architecture Decision" -Context "Foundation implementation context"
   ```
   Drive the content customization with the [`architecture-decision` craft skill](../../../.claude/skills/architecture-decision/SKILL.md) — the ADR customization craft home (replaces the retired Architecture Decision Creation Guide).
9. **Update Architecture Context**: Document new architectural foundations
10. **Establish Patterns**: Document reusable patterns that other features can follow
11. **Implement Tests**: Create tracked tests that validate both functionality and architectural constraints using `New-TestFile.ps1`

    ```powershell
    # Create test files using automation script (writes pytest markers)
    # Test types depend on project language (auto-detected from project-config.json)
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 -TestName "FeatureName" -TestType "Unit" -FeatureId "0.X.Z" -ComponentName "ComponentName" -Priority "Critical"

    # Use Critical priority for foundation features
    # Script automatically:
    # - Writes pytest markers (feature, priority, test_type)
    # - Creates test file from template with proper structure
    # - Updates test-tracking.md with correct file links and status
    # - Updates feature-tracking.md with test implementation progress
    ```
12. **🚨 CHECKPOINT**: Present core foundation implementation, architectural decisions, established patterns, test results, and dimension profile compliance to human partner for review before finalization

### Finalization

13. **Bug Discovery During Foundation Implementation**: Systematically identify and document any bugs discovered during foundation implementation:

   - **Architectural Issues**: Problems with system design or component interactions
   - **Integration Problems**: Issues with existing system integration points
   - **Performance Issues**: Foundation-level performance bottlenecks or inefficiencies
   - **Cross-Cutting Concerns**: Problems affecting multiple system components
   - **Foundation Logic Errors**: Bugs in core foundational functionality
   - **Dependency Issues**: Problems with external dependencies or libraries

14. **Report Discovered Bugs**: If bugs are identified during foundation implementation:

    - Use [../../scripts/file-creation/06-maintenance/New-BugReport.ps1](../../scripts/file-creation/06-maintenance/New-BugReport.ps1) script to create standardized bug reports
    - Follow [Bug Reporting Guide](../../guides/06-maintenance/bug-reporting-guide.md) for consistent documentation
    - Add bug entries to [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Needs Triage
    - Include foundation implementation context and evidence in bug reports
    - Reference specific architectural components or patterns affected
    - Note impact on system architecture and dependent features

    **Example Bug Report Command**:

    ```powershell
    # Create bug report for issues found during foundation implementation
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/06-maintenance/New-BugReport.ps1 -Title "Foundation module causes circular dependency" -Description "New foundation module creates circular dependency between service components" -DiscoveredBy "FeatureImplementation" -Severity "Critical" -Component "Core Foundation" -Environment "Development" -Evidence "Architecture analysis: circular dependency in src/core/"
    ```

15. **Update Architecture Tracking**: Record the foundation implementation in [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md)
16. **Verify Cross-Cutting Integration**: Ensure the foundation properly integrates with existing system components
17. **Document Usage Patterns**: Update documentation to show how other features should interact with this foundation
18. **Flag User Documentation Status**: If this foundation feature has user-visible behavior (CLI options, configuration, workflows), set the User Documentation section in the feature implementation state file to `❌ Needed`. This triggers [User Documentation Creation](../07-deployment/user-documentation-creation.md) later in the workflow. If the feature is internal-only, set to `N/A`.
19. **Run Foundational Validation**: Execute automated validation to ensure implementation meets foundational standards:

    ```powershell
    # Run quick validation check for immediate feedback
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Quick-ValidationCheck.ps1

    # Or run specific checks only (CheckType: All | CodeQuality | Architecture | Integration | Documentation | UI | Testing)
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Quick-ValidationCheck.ps1 -CheckType "CodeQuality"
    pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/validation/Quick-ValidationCheck.ps1 -CheckType "Architecture"
    ```

    For a scored, multi-dimension assessment of the foundation — architectural consistency, code quality, integration, documentation alignment, extensibility, AI agent continuity — run a validation round: [Validation Preparation](../05-validation/validation-preparation.md) selects features and applicable dimensions, then [Dimension Validation](../05-validation/dimension-validation-task.md) executes each one and produces the scored reports.

20. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Foundation Feature Implementation** - Complete implementation of the foundation feature with architectural awareness
- **Architectural Decision Records (ADRs)** - Documentation of significant architectural decisions made during implementation
- **Updated Architecture Context Packages** - Modifications to reflect new architectural foundations and patterns
- **Updated Architecture Tracking** - Record of foundation implementation and its impact on system architecture
- **Foundation Usage Patterns** - Documentation of how other features should interact with this foundation
- **Comprehensive Test Suite** - Tests that validate both functionality and architectural constraints
- **Validation Results** - Quick validation check output confirming implementation meets foundational standards (console, or JSON/CSV persisted via `-OutputPath`)
- **Bug Reports** - Any bugs discovered during foundation implementation documented in [Bug Tracking](../../../doc/state-tracking/permanent/bug-tracking.md) with status 🆕 Needs Triage

## State Tracking

### Automated Updates (via `New-TestFile.ps1`)

- [Test Tracking](../../../test/state-tracking/permanent/test-tracking.md) - Automatically updated with test file links and status
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Automatically updated with test implementation progress

### Manual Updates


- [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md) - Record foundation implementation and architectural evolution
- [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) - Update with foundation feature status (set to "👀 Needs Review" when implementation and testing are complete)

**Automation Available**: Use [Update-FeatureImplementationState.ps1](../../scripts/update/Update-FeatureImplementationState.ps1) to automate state file updates. Run `pwsh.exe -ExecutionPolicy Bypass -Command 'Get-Help <script-path> -Full'` for parameters and inline examples. See also [Script Development Quick Reference](../../guides/support/script-development-quick-reference.md) for cross-cutting invocation patterns.

## ⚠️ MANDATORY Task Completion Checklist

> Completion discipline, output verification, and the feedback form are governed by the [Task Execution Protocol](../../guides/framework/task-execution-protocol-guide.md) (Phase C). The items below are the **task-specific** verifications that plug into it.

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Foundation feature implementation is complete and functional
  - [ ] ADRs created for all significant architectural decisions
  - [ ] Foundation usage patterns documented
  - [ ] Comprehensive test suite created via `New-TestFile.ps1` and passing
  - [ ] Foundational validation executed via `Quick-ValidationCheck.ps1`
  - [ ] Validation results show no Error or Critical findings (Warnings triaged and either fixed or recorded)
  - [ ] Bug discovery performed systematically during foundation implementation
  - [ ] Any discovered bugs reported using ../../scripts/file-creation/06-maintenance/New-BugReport.ps1 script with proper context and evidence
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] Test tracking files automatically updated by `New-TestFile.ps1` (verify correctness)

  - [ ] [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md) updated with implementation record
  - [ ] [Feature Tracking](../../../doc/state-tracking/permanent/feature-tracking.md) updated with status set to "👀 Needs Review"
- [ ] **Feedback form** completed per the [Task Execution Protocol → Feedback step](../../guides/framework/task-execution-protocol-guide.md#feedback-step) — task ID `PF-TSK-024`, context "Foundation Feature Implementation Task".

## File Operations

| Operation | File Path | Update Method | Details |
|-----------|-----------|---------------|---------|
| **Creates** | Validation results | [`Quick-ValidationCheck.ps1`](../../scripts/validation/Quick-ValidationCheck.ps1) | Quick health check output (console/JSON/CSV) |
| **Updates** | [`bug-tracking.md`](../../../doc/state-tracking/permanent/bug-tracking.md) (if bugs discovered) | [`New-BugReport.ps1`](../../scripts/file-creation/06-maintenance/New-BugReport.ps1)| Add newly discovered bugs with 🆕 Needs Triage status for triage |
| **Updates** | [`architecture-tracking.md`](../../../doc/state-tracking/permanent/architecture-tracking.md) | Manual | Record foundation implementation and architectural evolution<br/>• Update component status and key decisions |
| **Updates** | [`feature-tracking.md`](../../../doc/state-tracking/permanent/feature-tracking.md) | Manual | Update with foundation feature completion status |
| **Updates** | [`test-tracking.md`](../../../test/state-tracking/permanent/test-tracking.md) | `New-TestFile.ps1` (auto) | Automated test registration when creating test files |

## Next Tasks

- [**Code Review Task**](../06-maintenance/code-review-task.md) - Review foundation implementation for quality and architectural compliance
- [**Feature Implementation Planning**](feature-implementation-planning-task.md) - Plan and implement regular features that build upon this foundation

<!-- merged from transition-registry entry: Foundation Feature Implementation -->
### Prerequisites for Transition

- [ ] Foundation feature implementation completed
- [ ] Architecture Context Package updated with implementation results
- [ ] Architecture Tracking updated with session progress
- [ ] ADRs created for architectural decisions made
- [ ] Foundation feature marked complete in Feature Tracking

### Next Task Selection

```
Are there dependent regular features ready for implementation?
├─ Yes → Feature Implementation (for dependent features)
│   └─ Reason: Foundation enables dependent feature development
└─ No → Continue with next foundation feature or architectural work
    └─ Reason: Complete architectural foundation before regular features
```

### Preparation for Next Task

1. **Update Architecture Context Package**: Reflect implementation progress and next priorities
2. **Update Architecture Tracking**: Document session outcomes and handover information
3. **Create/Update ADRs**: Document architectural decisions made during implementation
4. **Validate Foundation**: Ensure foundation feature works as expected before dependent features
5. **Prepare Context for Next Agent**: Ensure clear handover documentation for architectural continuity

## Related Resources


- [Architecture Tracking](../../../doc/state-tracking/permanent/architecture-tracking.md) - Architectural evolution tracking
