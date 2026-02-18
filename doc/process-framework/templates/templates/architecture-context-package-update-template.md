---
id: PF-TEM-031
type: Process Framework
category: Template
version: 1.1
created: 2025-07-25
updated: 2025-08-03
creates_document_category: Guide
creates_document_prefix: PF-GDE
usage_context: Process Framework - Guide Creation
template_for: Guide
creates_document_version: 1.0
creates_document_type: Process Framework
description: Template for updating Architecture Context Packages during architectural work to ensure AI agent continuity
---
# Architecture Context Package Update Template

## Purpose
This template provides a structured approach for updating Architecture Context Packages during architectural work, ensuring AI agent continuity and maintaining bounded architectural contexts.

## When to Use
- During foundation feature implementation when architectural state changes
- After System Architecture Review when new architectural decisions are made
- When architectural work progresses and context needs to be updated
- At the end of architectural sessions to prepare handover for next agent

## Template Structure

### Section 1: Current Focus Update
```markdown
## 🎯 Current Focus
[Update with current architectural work status]

**Previous Focus**: [What was being worked on before]
**Current Focus**: [What is currently being worked on]
**Progress Made**: [Key progress since last update]
**Next Priority**: [What should be tackled next]
```

### Section 2: Implementation Status Update
```markdown
## 🔗 Implementation Status

- **[Component 1]**: [Updated status with brief description]
  - Previous: [Previous status]
  - Current: [Current status]
  - Changes: [What changed and why]
- **[Component 2]**: [Updated status with brief description]
  - Previous: [Previous status]
  - Current: [Current status]
  - Changes: [What changed and why]
```

### Section 3: Next Agent Instructions Update
```markdown
## 📋 Next Agent Instructions

**Updated Instructions**:
1. [Updated specific action item 1]
2. [Updated specific action item 2]
3. [Updated completion instruction]

**Context Loading Priority**:
1. [Most important context file for next agent]
2. [Second most important context file]
3. [Additional context as space allows]

**Critical Constraints**:
- [Any new constraints discovered during work]
- [Updated constraint information]
```

### Section 4: Quality Attribute Focus Update
```markdown
## 🎯 Quality Attribute Focus

> **Reference**: [System Quality Attributes](/doc/product-docs/technical/architecture/quality-attributes.md)

**Primary Quality Concerns**: [Top 3 quality attributes for this architectural area]
- **[Quality Attribute 1]**: [Current status and focus]
- **[Quality Attribute 2]**: [Current status and focus]
- **[Quality Attribute 3]**: [Current status and focus]

**Key Constraints**: [Critical limitations that affect implementation]
- **[Constraint 1]**: [Description and impact]
- **[Constraint 2]**: [Description and impact]

**Success Criteria**: [How to measure quality attribute achievement]
- **[Metric 1]**: [Target and current status]
- **[Metric 2]**: [Target and current status]

**Cross-Cutting Impact**: [How this area affects system-wide quality attributes]
- **System Performance**: [Impact on overall system performance]
- **System Security**: [Impact on overall system security]
- **System Reliability**: [Impact on overall system reliability]
```

### Section 5: Last Session Summary Update
```markdown
## 🔄 Last Session Summary

**Date**: [Current session date]
**Completed**: [What was finished in this session]
**In Progress**: [What was started but not finished]
**Blocked**: [What couldn't be completed and why]
**Next Priority**: [What should be tackled next]
**Architectural Decisions Made**: [Any ADRs created or decisions made]
**Quality Attribute Progress**: [Progress on quality attribute implementation]
```

## Update Checklist

### Before Updating
- [ ] Review current context package content
- [ ] Identify what has changed since last update
- [ ] Gather information about progress made
- [ ] Identify any new constraints or decisions

### During Update
- [ ] Update Current Focus section with progress
- [ ] Update Implementation Status for all relevant components
- [ ] **NEW**: Update Quality Attribute Focus section with current quality concerns and progress
- [ ] Revise Next Agent Instructions based on current state
- [ ] Update Last Session Summary with session outcomes
- [ ] Verify all links and references are still valid

### After Update
- [ ] Review updated context package for completeness
- [ ] Ensure next agent has clear guidance
- [ ] Verify context package size is manageable for AI context window
- [ ] Update Architecture Tracking with context package update

## Context Package Maintenance Guidelines

### Keep Context Bounded
- **Maximum Size**: Context package should fit comfortably in AI context window
- **Focus Scope**: Maintain clear boundaries around architectural area
- **Essential Only**: Include only information essential for current architectural work

### Maintain Continuity
- **Clear Handovers**: Next agent should understand exactly what to do next
- **Progress Tracking**: Clear indication of what's been completed vs. in progress
- **Decision History**: Key architectural decisions should be traceable

### Update Frequency
- **During Sessions**: Update as architectural work progresses
- **Session End**: Always update at end of architectural session
- **Major Changes**: Update when significant architectural decisions are made
- **Handover Points**: Update before transitioning to different agent or task

## Common Update Scenarios

### Scenario 1: Foundation Feature Implementation Progress
```markdown
## 🔗 Implementation Status
- **Repository Interfaces**: ✅ Complete (was ⬜ Not Started)
  - Changes: Base repository interface defined, escape room repository interface created
- **Base Repository**: 🟡 In Progress (was ⬜ Not Started)
  - Changes: Supabase integration layer implemented, error handling patterns defined
```

### Scenario 2: Architectural Decision Made
```markdown
## 🏗️ Key Architectural Decisions
- **ADR-001**: Repository Pattern for Data Access (✅ Accepted - was 📝 Proposed)
  - Decision: Adopted repository pattern with service layer separation
  - Impact: All data access will use repository interfaces
  - Implementation: Base repository created, specific repositories to follow pattern
```

### Scenario 3: Blocked Work
```markdown
## 🔄 Last Session Summary
**Blocked**: Repository implementation blocked by missing database schema
**Reason**: Current schema doesn't support planned repository pattern
**Resolution Needed**: Database schema design task required before continuing
**Next Priority**: Complete database schema design, then resume repository implementation
```

## Architecture Context Package Creation Template

### For New Architecture Context Packages
When creating a new Architecture Context Package, include these quality attribute sections:

```markdown
## 🎯 Quality Attribute Focus

> **Reference**: [System Quality Attributes](/doc/product-docs/technical/architecture/quality-attributes.md)

**Primary Quality Concerns**: [Top 3 quality attributes for this architectural area]
- **Performance**: [How this area impacts system performance]
- **Security**: [How this area impacts system security]
- **Reliability**: [How this area impacts system reliability]

**Key Constraints**: [Critical limitations that affect implementation]
- **Technical Constraints**: [Technology or platform limitations]
- **Business Constraints**: [Business requirements that limit design options]
- **Integration Constraints**: [Constraints from existing system integration]

**Success Criteria**: [How to measure quality attribute achievement]
- **Performance Targets**: [Specific performance metrics and targets]
- **Security Requirements**: [Security compliance and validation criteria]
- **Reliability Metrics**: [Availability, error rate, recovery time targets]

**Cross-Cutting Impact**: [How this area affects system-wide quality attributes]
- **System Performance**: [Impact on overall system performance]
- **System Security**: [Impact on overall system security]
- **System Reliability**: [Impact on overall system reliability]
- **System Usability**: [Impact on overall user experience]

**Quality Attribute Status Tracking**: [Current status of quality attribute implementation]
- **Performance**: [Current status - Not Started/In Progress/Complete]
- **Security**: [Current status - Not Started/In Progress/Complete]
- **Reliability**: [Current status - Not Started/In Progress/Complete]
- **Usability**: [Current status - Not Started/In Progress/Complete]
```

### Quality Attribute Integration Guidelines

#### For Each Architecture Context Package
- **Identify Primary Quality Concerns**: Focus on the 2-3 most important quality attributes for this architectural area
- **Map to System Requirements**: Reference the master quality attributes document for system-wide requirements
- **Define Success Criteria**: Establish measurable criteria for quality attribute achievement
- **Track Implementation Status**: Monitor progress on quality attribute implementation
- **Document Cross-Cutting Impact**: Analyze how this area affects system-wide quality

#### Quality Attribute Mapping by Architecture Area
- **Data Architecture**: Performance (query speed), Security (data protection), Reliability (data integrity)
- **API Architecture**: Performance (response time), Security (authentication), Reliability (error handling)
- **State Management**: Performance (memory usage), Reliability (state consistency), Usability (user experience)
- **Security Architecture**: Security (comprehensive protection), Performance (security overhead), Reliability (secure failure modes)
- **Infrastructure**: Reliability (availability), Performance (scalability), Security (infrastructure protection)

## Integration with Architecture Tracking

### Coordinate Updates
- Update Architecture Context Package first (detailed, bounded context)
- Update Architecture Tracking second (high-level state across all areas)
- Ensure consistency between both tracking mechanisms

### Cross-Reference Information
- Context Package provides detailed context for specific area
- Architecture Tracking provides cross-cutting view of all architectural work
- Both should reference each other for complete picture

## Quality Assurance

### Review Criteria
- [ ] Next agent can understand current state from context package alone
- [ ] All progress since last update is clearly documented
- [ ] Next steps are specific and actionable
- [ ] Context package remains focused and bounded
- [ ] Links and references are valid and accessible

### Common Issues to Avoid
- **Context Bloat**: Adding too much information, making package unwieldy
- **Stale Information**: Leaving outdated status or instructions
- **Unclear Handovers**: Vague or ambiguous next steps
- **Missing Context**: Removing essential information to save space
- **Broken Links**: References to moved or deleted files

---

**Usage Note**: This template should be used as a guide for updating existing Architecture Context Packages. The specific sections and content will vary based on the architectural area and current work being performed.
