---
id: PF-TSK-015
type: Process Framework
category: Task Definition
version: 1.5
created: 2023-06-15
updated: 2025-01-27
task_type: Discrete
change_notes: "v1.5 - Added Information Flow and Separation of Concerns sections for IMP-097/IMP-098"
---

# Technical Design Document (TDD) Creation

## Purpose & Context

Create a detailed technical design document for a feature that provides a comprehensive blueprint for implementation, ensuring architectural consistency and facilitating effective collaboration between developers. The document's depth and detail are adjusted based on the feature's complexity tier, ensuring sufficient context while minimizing documentation overhead for simpler features.

## AI Agent Role

**Role**: Technical Lead
**Mindset**: Design-first thinking, risk-aware, collaborative
**Focus Areas**: Technical specifications, risk mitigation, team coordination, design validation
**Communication Style**: Present design options with pros/cons and risk assessment, ask about technical constraints and requirements

## When to Use

- After FDD Creation for Tier 2+ features (functional requirements are defined)
- After Feature Tier Assessment for Tier 1 features (simple features without FDD requirement)
- Before beginning implementation of a feature
- When a feature requires architectural decisions
- When multiple developers will be working on the same feature
- When integration with existing systems needs planning
- When preparing to hand off work to a new AI agent session

## Information Flow

> **📋 Detailed Guidance**: See [Task Transition Guide - Information Flow Section](../../guides/guides/task-transition-guide.md#information-flow-and-separation-of-concerns)

### Inputs from Other Tasks

- **FDD Creation Task** (Tier 2+): Functional requirements, user workflows, business rules, acceptance criteria
- **Feature Tier Assessment**: Complexity tier, documentation requirements, quality attribute priorities
- **API Design Task**: API contracts, endpoint specifications, data access patterns
- **Database Schema Design Task**: Data model, relationships, constraints, security policies
- **UI/UX Design Task** (when applicable): Visual specifications, component details, accessibility requirements, platform adaptations

### Outputs to Other Tasks

- **Test Specification Task**: Technical architecture, component interactions, quality attribute requirements, testing considerations
- **Feature Implementation Task**: Implementation blueprint, component design, technical decisions, code structure guidance

### Cross-Reference Standards

When referencing other tasks' outputs in TDDs:

- Use brief summary (2-5 sentences) + link to source document
- Focus on **implementation-level perspective** (how to build it, not what it does)
- Avoid duplicating functional requirements, API contracts, or database schemas
- Reference quality attribute requirements from System Quality Attributes document

### Separation of Concerns

**✅ TDDs Should Document:**

- Component architecture and design patterns
- Technical implementation approach
- Service and class design
- Algorithm and data structure choices
- Performance optimization strategies
- Error handling and recovery mechanisms
- Technical quality attribute implementation
- Implementation-level security measures
- Code organization and module structure

**❌ TDDs Should NOT Document:**

- Functional requirements (owned by FDD)
- User workflows and acceptance criteria (owned by FDD)
- API endpoint contracts (owned by API Design Task)
- Database table schemas (owned by Database Schema Design Task)
- Test cases and test data (owned by Test Specification Task)
- Business rules and validation logic (owned by FDD)

## Context Requirements

[View Context Map for this task](../discrete/visualization/context-maps/discrete/tdd-creation-map.md)

- **Critical (Must Read):**

  - **Functional Design Document (FDD)** - For Tier 2+ features, the FDD created in the previous step containing functional requirements and user flows
  - [System Quality Attributes](/doc/product-docs/technical/architecture/quality-attributes.md) - **MANDATORY**: System-wide quality requirements that must be analyzed and integrated into all TDDs
  - [TDD Templates](/doc/product-docs/technical/architecture/design-docs) - Tier-specific templates for technical design documents:
  - [T1 Template](/doc/product-docs/templates/templates/tdd-t1-template.md) - For Tier 1 (simple) features
  - [T2 Template](/doc/product-docs/templates/templates/tdd-t2-template.md) - For Tier 2 (moderate) features
  - [T3 Template](/doc/product-docs/templates/templates/tdd-t3-template.md) - For Tier 3 (complex) features
  - [Feature Assessment](../discrete/methodologies/documentation-tiers/assessments) - The tier assessment for the selected feature

- **Important (Load If Space):**

  - [Project Structure](/doc/product-docs/technical/architecture/project-structure.md) - Information about the project architecture
  - [Technical Design Documents](/doc/product-docs/technical/design) - Existing design documents for reference
  - [Component Relationship Index](/doc/product-docs/technical/architecture/component-relationship-index.md) - For understanding component interactions

- **Reference Only (Access When Needed):**
  - [Feature Tracking](../discrete/state-tracking/permanent/feature-tracking.md) - To identify features that have been assessed but need TDDs
  - [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - For interpreting context map diagrams

## Process

> **🚨 CRITICAL: This task is NOT complete until ALL steps including feedback forms are finished! 🚨**
>
> **⚠️ MANDATORY: Use the .../../scripts/file-creation/New-tdd.ps1 script for consistency across all design documents.**
>
> **⚠️ MANDATORY: Request explicit feedback from the human partner during the TDD creation process.**

### Preparation

1. Review the feature's tier assessment document to understand its complexity tier (🔵/🟠/🔴)
2. **For Tier 2+ features**: Review the Functional Design Document (FDD) to understand functional requirements, user flows, and acceptance criteria
3. Identify the appropriate documentation template based on the tier:
   - **Tier 1 🔵**: Use the lightweight planning template (creates tdd-[ID]-[name]-t1.md)
   - **Tier 2 🟠**: Use the standard TDD template (creates tdd-[ID]-[name]-t2.md)
   - **Tier 3 🔴**: Use the comprehensive TDD template (creates tdd-[ID]-[name]-t3.md)
4. Review any existing documentation related to the feature
5. Gather necessary technical context to understand the feature's requirements

### Quality Attribute Analysis (MANDATORY)

6. **Analyze System Quality Attributes**: Review the [System Quality Attributes](/doc/product-docs/technical/architecture/quality-attributes.md) document to understand:
   - System-wide performance, security, reliability, and usability requirements
   - Feature category-specific requirements that apply to this feature
   - Cross-cutting constraints that affect implementation
7. **Map Quality Attributes to Feature**: Identify which quality attributes are most relevant to this specific feature:
   - Performance requirements (response times, throughput, resource usage)
   - Security requirements (authentication, authorization, data protection)
   - Reliability requirements (error handling, recovery, monitoring)
   - Usability requirements (user experience, accessibility)
8. **Set Feature-Specific Quality Targets**: Adapt system-wide quality requirements to this feature's specific context:
   - Define measurable targets based on system-wide requirements
   - Consider feature complexity and user impact
   - Document any quality attribute trade-offs or constraints

### Execution

9. Create the appropriate document using the automation script:

   ```powershell
   # Navigate to the script directory
   cd /doc/product-docs/technical/architecture/design-docs

   # Run the script with the feature information
   ../discrete/New-tdd.ps1 -FeatureId "[Assessment ID]" -FeatureName "[Feature Name]" -Tier "[1, 2, or 3]"
   ```

   The script will:

   - Generate the appropriate template based on the tier (1, 2, or 3)
   - Include the feature ID and name in the document
   - Create a file with standardized naming: tdd-[FeatureID]-[feature-name]-t[Tier].md
   - Store the file in the /tdd subdirectory
   - Ensure the AI Agent Session Handoff Notes section is included

10. Complete the document with appropriate detail for the tier, **including quality attribute requirements and implementation**:

- **Tier 1 🔵**: Key implementation approach, affected components, technical constraints, and relevant quality attribute considerations
- **Tier 2 🟠**: Basic architecture, component interactions, data model, API details, and quality attribute requirements with implementation approach
- **Tier 3 🔴**: Comprehensive design including security, performance, edge cases, testing strategy, and detailed quality attribute implementation with measurement approach

11. **MANDATORY: Include Quality Attribute Sections** in all TDDs:

- **Quality Attribute Requirements**: Feature-specific quality targets based on system-wide requirements
- **Quality Attribute Implementation**: How the technical design achieves quality targets
- **Quality Measurement**: How quality attributes will be monitored and validated

12. Include specific "AI Agent Session Handoff Notes" section in all documents with:

- Summary of decisions made in this session
- Clear next steps for subsequent AI sessions
- Explicit list of files that will need to be modified
- Any specific implementation challenges to be aware of

13. Ensure the documentation includes appropriate diagrams or visual aids:

- **Tier 1 🔵**: Simple component interaction diagram (if needed)
- **Tier 2 🟠**: Data flow diagrams and component architecture
- **Tier 3 🔴**: Comprehensive architecture, sequence diagrams, and state charts

14. **🚨 CRITICAL**: Actively request feedback from your human partner during TDD creation:

- Ask specific questions about technical approach
- Confirm appropriate level of detail for the feature's complexity tier
- Validate security and architectural decisions
- **NEW**: Validate quality attribute requirements and implementation approach

### Finalization

15. Review the document for completeness, clarity, and appropriateness for the complexity tier, **ensuring quality attribute sections are complete**
16. **Verify Automated Updates**: The .../../scripts/file-creation/New-tdd.ps1 script automatically updates feature tracking - verify the updates were applied correctly
17. **🚨 MANDATORY FINAL STEP**: Complete the Task Completion Checklist below

## Outputs

- **Technical Design Document** - New document in `/doc/product-docs/technical/architecture/design-docs/tdd/tdd-[assessment-id]-[feature-name]-t[tier].md`
- **Updated Feature Tracking** - [Feature Tracking](../discrete/state-tracking/permanent/feature-tracking.md) document updated with TDD status
- **AI Session Handoff Notes** - Explicit guidance for the next AI agent session

## State Tracking

The following state files are automatically updated by the .../../scripts/file-creation/New-tdd.ps1 script:

- [Feature Tracking](../discrete/state-tracking/permanent/feature-tracking.md) - Automatically updated with:
  - Status changed from "📋 FDD Created" (for Tier 2+) or "📊 Assessment Created" (for Tier 1) to "📝 TDD Created"
  - Link to TDD document added in the "Tech Design" column
  - TDD creation date added to Notes column

## ⚠️ MANDATORY Task Completion Checklist

**🚨 TASK IS NOT COMPLETE UNTIL ALL ITEMS BELOW ARE CHECKED OFF 🚨**

Before considering this task finished:

- [ ] **Verify Outputs**: Confirm all required outputs have been produced
  - [ ] TDD document created in the correct location using the tier-appropriate template
  - [ ] TDD document follows the required naming convention: `tdd-[assessment-id]-[feature-name]-t[tier].md`
  - [ ] "AI Agent Session Handoff Notes" section is complete and explicit
  - [ ] All required sections for the tier are properly completed according to tier requirements
  - [ ] Technical approach is clearly defined
  - [ ] **MANDATORY**: Quality Attribute Requirements section completed with feature-specific targets
  - [ ] **MANDATORY**: Quality Attribute Implementation section completed with technical approach
  - [ ] **MANDATORY**: Quality Measurement section completed with monitoring approach
  - [ ] Quality attribute analysis integrated throughout technical design
  - [ ] Diagrams and visual aids are included as appropriate for the tier
  - [ ] Human partner feedback has been incorporated
- [ ] **Verify Automated Updates**: Ensure the .../../scripts/file-creation/New-tdd.ps1 script successfully updated state tracking files
  - [ ] Feature Tracking document status automatically updated from "📋 FDD Created" (for Tier 2+) or "📊 Assessment Created" (for Tier 1) to "📝 TDD Created"
  - [ ] Feature Tracking document automatically includes link to TDD in the "Tech Design" column
  - [ ] Feature Tracking document automatically updated with TDD creation date in the "Notes" column
- [ ] **Complete Feedback Forms**: Follow the [Feedback Form Completion Instructions](../../guides/guides/feedback-form-completion-instructions.md) for each tool used, using task ID "PF-TSK-015" and context "TDD Creation"

## Next Tasks

- C-testing/test-specification-creation-task.md) - Create comprehensive test specifications from the TDD for Test-First Development
- B-design/feature-implementation-task.md) - Uses the TDD and test specifications to implement the feature
- B-design/code-review-task.md) - Uses the TDD as a reference for evaluating implementation

## Related Resources

- [TDD Templates](/doc/product-docs/technical/architecture/design-docs) - Tier-specific templates for technical design documents:
  - [T1 Template](/doc/product-docs/templates/templates/tdd-t1-template.md) - For Tier 1 (simple) features
  - [T2 Template](/doc/product-docs/templates/templates/tdd-t2-template.md) - For Tier 2 (moderate) features
  - [T3 Template](/doc/product-docs/templates/templates/tdd-t3-template.md) - For Tier 3 (complex) features
- [TDD Generation Script](/doc/product-docs/technical/architecture/design-docs/tdd/.../../scripts/file-creation/New-tdd.ps1) - Script for generating TDD documents
- [Architecture Decision Records](/doc/product-docs/technical/architecture/design-docs/adr) - Repository of past architectural decisions
- <!-- [API Design Guidelines](/doc/product-docs/technical/architecture/api-design-guidelines.md) - File not found --> - Standards for designing APIs
