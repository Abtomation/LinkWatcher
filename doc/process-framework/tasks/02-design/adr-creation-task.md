---
id: PF-TSK-028
type: Process Framework
category: Task Definition
version: 1.0
created: 2025-08-03
updated: 2025-08-03
task_type: Discrete
---

# ADR Creation

## Purpose & Context

Create Architecture Decision Records (ADRs) to document significant architectural decisions, their context, alternatives considered, and consequences. This task provides a structured workflow for capturing architectural decisions that impact system design, technology choices, and development patterns.

## AI Agent Role

**Role**: Software Architect
**Mindset**: Strategic, analytical, documentation-focused, decision-oriented
**Focus Areas**: Architectural decision analysis, alternative evaluation, consequence assessment, stakeholder communication
**Communication Style**: Present clear decision rationales, ask probing questions about alternatives and trade-offs, ensure comprehensive documentation of architectural reasoning

## When to Use

- When making significant architectural decisions that affect system design or structure
- When selecting technologies, frameworks, or architectural patterns
- When establishing coding standards, design patterns, or development practices
- When making decisions that have long-term impact on system maintainability or scalability
- When resolving architectural trade-offs or technical debates
- As part of System Architecture Review tasks or Foundation Feature Implementation
- When documenting decisions made during Feature Tier Assessment or TDD Creation

## Context Requirements

[View Context Map for this task](../discrete/visualization/context-maps/discrete/adr-creation-map.md)

- **Critical (Must Read):**

  - **Architectural Decision Context** - Clear understanding of the decision to be documented, including problem statement and constraints
  - [Architecture Decision Creation Guide](../discrete/guides/guides/architecture-decision-creation-guide.md) - Comprehensive guide for customizing ADR templates
  - [ADR Template](../product-docs/templates/templates/adr-template.md) - Template structure and required sections

- **Important (Load If Space):**

  - A-planning/system-architecture-review.md) - For decisions arising from architectural reviews
  - B-design/foundation-feature-implementation-task.md) - For architectural decisions during foundation work
  - A-planning/feature-tier-assessment-task.md) - For decisions identified during complexity assessment
  - [Component Relationship Index](../product-docs/technical/architecture/component-relationship-index.md) - For understanding component interactions

- **Reference Only (Access When Needed):**
  - [Existing ADRs](../product-docs/technical/architecture/design-docs/adr/adr) - For consistency and reference
  - [Architecture Documentation](../product-docs/technical/architecture/README.md) - For architectural context
  - [Visual Notation Guide](../discrete/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the ../discrete/../discrete/New-ArchitectureDecision.ps1 script - never create ADRs manually.**

### Preparation

1. **Analyze the Architectural Decision Context**: Gather complete understanding of the decision to be documented

   - Identify the problem or situation requiring an architectural decision
   - Collect relevant background information, constraints, and stakeholder requirements
   - Research alternatives and their trade-offs
   - Understand the consequences and impact of different approaches

2. **Review Existing ADRs**: Check for related decisions or patterns

   - Review existing ADRs in `/doc/product-docs/technical/architecture/design-docs/adr/adr/`
   - Identify any decisions that might be superseded or related
   - Ensure consistency with established architectural patterns

3. **Prepare Decision Parameters**: Collect all information needed for ADR creation
   - **Title**: Clear, descriptive title for the architectural decision
   - **Description**: Brief explanation of what the decision addresses
   - **Status**: Initial status (typically "Proposed" for new decisions)

### Execution

4. **Create ADR Using Automation Script**: Use the ../discrete/../discrete/New-ArchitectureDecision.ps1 script

   ```powershell
   # Navigate to ADR directory
   cd doc/product-docs/technical/architecture/design-docs/adr

   # Create new ADR with basic information
   .\../discrete/../discrete/New-ArchitectureDecision.ps1 -Title "Your Decision Title" -Description "Brief description of the decision" -Status "Proposed"

   # Optional: Open in editor immediately
   .\../discrete/../discrete/New-ArchitectureDecision.ps1 -Title "Your Decision Title" -Description "Brief description" -Status "Proposed" -OpenInEditor
   ```

5. **Complete ADR Documentation**: Follow the Architecture Decision Creation Guide

   - **Context Section**: Provide comprehensive problem statement and background
   - **Decision Section**: Document the specific decision made with clear, actionable statements
   - **Impact Assessment**: Complete all impact areas (technical risk, implementation effort, affected components, migration requirements, performance impact, security implications)
   - **Alternatives Section**: Document all considered alternatives with structured pros/cons analysis
   - **Consequences Section**: List both positive and negative outcomes expected
   - **References Section**: Add supporting documentation and resources

6. **Review and Validate**: Ensure ADR quality and completeness
   - Verify all template sections are properly completed
   - Check that the decision is clear and actionable
   - Ensure alternatives analysis is thorough and objective
   - Validate that consequences are realistic and measurable

### Finalization

7. **Update ADR Status**: Progress the ADR through appropriate status changes

   - Keep as "Proposed" if requiring stakeholder review
   - Change to "Accepted" once decision is approved and ready for implementation
   - Update to "Deprecated" or "Superseded" if decision changes over time

8. **Integrate with Project Documentation**: Ensure proper integration

   - Verify ADR is properly linked in documentation map
   - Reference ADR in related technical design documents
   - Update any affected architectural assessments or reviews

9. **🚨 MANDATORY FINAL STEP**: Complete the [Task Completion Checklist](#task-completion-checklist) below

## Outputs

- **Architecture Decision Record (ADR)** - Complete ADR document in `/doc/product-docs/technical/architecture/design-docs/adr/adr/` with assigned ID (PD-ADR-XXX)
- **Updated Documentation Map** - ADR entry added to the architecture documentation map
- **Architectural Decision Documentation** - Comprehensive record of decision context, alternatives, and consequences

## State Tracking

The following state files must be updated as part of this task:

- [Architecture Tracking](../discrete/state-tracking/permanent/architecture-tracking.md) - Update with new architectural decision and its impact
- [Feature Tracking](../discrete/state-tracking/permanent/feature-tracking.md) - Update ADR column for related features with link to created ADR

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] ADR document created with proper ID (PD-ADR-XXX) and complete content
  - [ ] All ADR template sections properly completed (Context, Decision, Impact Assessment, Alternatives, Consequences, References)
  - [ ] ADR status appropriately set (Proposed/Accepted/etc.)
- [ ] **Update State Files**: Ensure all state tracking files have been updated
  - [ ] [Architecture Tracking](../discrete/state-tracking/permanent/architecture-tracking.md) updated with new architectural decision
  - [ ] [Feature Tracking](../discrete/state-tracking/permanent/feature-tracking.md) updated with ADR link in relevant feature entries
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../discrete/guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-028" and context "ADR Creation"

## Next Tasks

- B-design/feature-implementation-task.md) - Implement features based on architectural decisions documented in ADRs
- B-design/foundation-feature-implementation-task.md) - Implement foundation features with architectural decisions documented
- A-planning/system-architecture-review.md) - Review system architecture incorporating new ADRs

## Related Resources

- [Architecture Decision Creation Guide](../discrete/guides/guides/architecture-decision-creation-guide.md) - Comprehensive guide for creating and customizing ADRs
- [ADR Template](../product-docs/templates/templates/adr-template.md) - Template structure and sections for ADRs
- [../discrete/../discrete/New-ArchitectureDecision.ps1](../../../product-docs/technical/architecture/design-docs/adr/../discrete/../discrete/New-ArchitectureDecision.ps1) - Script for creating new ADRs
- [Existing ADRs](../product-docs/technical/architecture/design-docs/adr/adr) - Reference examples and consistency patterns
- [Architecture Documentation](../product-docs/technical/architecture/README.md) - Broader architectural context and guidelines
