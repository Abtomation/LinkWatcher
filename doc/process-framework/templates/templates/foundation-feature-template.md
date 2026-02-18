---
id: PF-TEM-030
type: Process Framework
category: Template
version: 1.0
created: 2025-07-25
updated: 2025-07-25
usage_context: Process Framework - Task Creation
description: Template for implementing foundation features (0.x.x) that provide architectural foundations for regular features
creates_document_prefix: PF-TSK
template_for: Task
creates_document_category: Task
creates_document_version: 1.0
creates_document_type: Process Framework
---

# Foundation Feature Implementation Task Template

## Purpose & Context

This template guides the implementation of foundation features (0.x.x) that provide architectural foundations for regular features. Foundation features are cross-cutting architectural work that affects multiple features and requires specialized handling within the architectural integration framework.

## When to Use This Template

- When implementing foundation features identified during System Architecture Review
- When architectural work is cross-cutting and affects multiple features
- When architectural foundations must be established before regular feature implementation
- When working on 0.x.x features in the feature tracking system

## Context Requirements

- **Critical (Must Read):**

  - [Architecture Context Package](../../product-docs/technical/architecture/context-packages/[architecture-area]-context.md) - Bounded architectural context for this work
  - [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md) - Current architectural state and decisions
  - [Foundation Feature Specification](../../product-docs/technical/architecture/assessments/[feature-name]-foundation-specification.md) - Detailed requirements from System Architecture Review
  - [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Foundation feature status and dependencies

- **Important (Load If Space):**
  - [Related ADRs](../../product-docs/technical/architecture/design-docs/adr/) - Architectural decisions relevant to this foundation
  - [Dependent Features](../../state-tracking/permanent/feature-tracking.md) - Features that will be unblocked by this foundation
  - [System Architecture Documentation](../../product-docs/technical/architecture/README.md) - Overall system architecture context

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ ARCHITECTURAL CONTINUITY: Update Architecture Context Package and Architecture Tracking throughout the work.**

### Preparation

1. **Load Architectural Context**: Review Architecture Context Package for bounded context and current focus
2. **Understand Foundation Scope**: Review foundation feature specification from System Architecture Review
3. **Check Architectural State**: Review Architecture Tracking to understand current architectural decisions and progress
4. **Identify Dependencies**: Understand which features depend on this foundation work
5. **Prepare Implementation Environment**: Set up development environment with architectural constraints in mind

### Execution

6. **Implement Foundation Components**:
   - Follow architectural patterns and decisions from context package
   - Implement core architectural components (interfaces, base classes, patterns)
   - Ensure implementation aligns with architectural constraints
7. **Create Architectural Documentation**:
   - Document architectural patterns implemented
   - **Create ADRs for architectural decisions made** using existing ADR system:
     ```powershell
     cd doc/product-docs/technical/architecture/design-docs/adr/
     ../../scripts/file-creation/New-ArchitectureDecision.ps1 -Title "[Decision Title]" -Status "Proposed"
     ```
   - Document integration patterns for dependent features
8. **Validate Foundation Implementation**:
   - Test architectural components work as designed
   - Verify integration points are properly defined
   - Ensure foundation meets requirements of dependent features
9. **Update Architectural Assets**:
   - Update Architecture Context Package with implementation results
   - Update Architecture Tracking with completion status and outcomes
   - Document any architectural decisions made during implementation

### Finalization

10. **Prepare Handover Documentation**: Create clear guidance for implementing dependent features
11. **Update Feature Dependencies**: Update dependent features in Feature Tracking with foundation completion
12. **Validate Architectural Continuity**: Ensure next agent has sufficient context to continue architectural work
13. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Foundation Implementation** - Core architectural components implemented according to specification
- **Updated Architecture Context Package** - Context package updated with implementation results and next steps
- **Updated Architecture Tracking** - Architecture tracking updated with foundation completion and outcomes
- **Architectural Documentation** - Documentation of patterns, interfaces, and integration points
- **New or Updated ADRs** - Architectural Decision Records created using existing ADR system (`New-ArchitectureDecision.ps1`)
- **Handover Documentation** - Clear guidance for implementing dependent features
- **Updated Feature Tracking** - Foundation feature marked complete, dependent features updated

## State Tracking

The following state files must be updated as part of this task:

- [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md) - Update with foundation implementation outcomes
- [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) - Mark foundation feature complete, update dependent features
- [Architecture Context Package](../../product-docs/technical/architecture/context-packages/[architecture-area]-context.md) - Update with implementation results

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] Foundation implementation complete and tested
  - [ ] Architecture Context Package updated with implementation results
  - [ ] Architecture Tracking updated with completion status
  - [ ] Architectural documentation created or updated
  - [ ] ADRs created using existing ADR system (`New-ArchitectureDecision.ps1`) for architectural decisions made
  - [ ] Handover documentation prepared for dependent features
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md) updated with outcomes
  - [ ] [Feature Tracking](../../state-tracking/permanent/feature-tracking.md) foundation feature marked complete
  - [ ] [Architecture Context Package](../../product-docs/technical/architecture/context-packages/[architecture-area]-context.md) updated with results
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "Foundation Feature Implementation" and context "[Foundation Feature Name]"

## Next Tasks

- [**Regular Feature Implementation**](../tasks/04-implementation/feature-implementation-task.md) - Implement features that depend on this foundation
- [**Additional Foundation Features**](foundation-feature-template.md) - If multiple foundations needed

## Related Resources

- [Architectural Integration Framework Concept](../../proposals/proposals/architectural-integration-framework-concept.md) - Framework overview and principles
- [System Architecture Review Task](../tasks/01-planning/system-architecture-review-task.md) - Task that identifies foundation features
- [Task Transition Guide](../../guides/guides/task-transition-guide.md) - Guidance for transitioning from foundation to regular features
- [Architecture Decision Records System](../../product-docs/technical/architecture/design-docs/adr/README.md) - Existing ADR system with `New-ArchitectureDecision.ps1` script

## Template Usage Notes

### Customization Points

- Replace `[architecture-area]` with specific architectural area (data, auth, api, etc.)
- Replace `[feature-name]` with specific foundation feature name
- Replace `[Foundation Feature Name]` with human-readable foundation feature name
- Update context package references to match actual architecture area

### Context Loading Strategy

1. **Architecture Context Package** (highest priority - bounded and focused)
2. **Architecture Tracking** (current architectural state)
3. **Foundation Feature Specification** (detailed requirements)
4. **Related ADRs** (architectural decisions)
5. **Dependent Features** (impact understanding)

### Success Indicators

- Foundation implementation enables dependent feature development
- Architecture Context Package provides clear guidance for next agent
- Architecture Tracking accurately reflects new architectural state
- Dependent features can proceed without additional architectural work
