---
id: PF-GDE-019
type: Process Framework
category: Guide
version: 1.0
created: 2025-08-02
updated: 2025-08-02
---

# Architectural Framework Usage Guide

This guide provides comprehensive instructions for using the Architectural Integration Framework to manage cross-cutting architectural work within the self-documenting development system.

## Overview

The Architectural Integration Framework enables AI agents to work on architectural tasks with continuity and context preservation. It consists of:

- **Architecture Tracking**: Cross-cutting architectural state management
- **Architecture Context Packages**: Bounded, AI-digestible architectural contexts
- **Foundation Feature Integration**: Specialized handling for architectural work (0.x.x features)
- **Enhanced Task Transitions**: Architectural workflow patterns

## When to Use the Architectural Framework

### Foundation Features (0.x.x)

Use the architectural framework for all foundation features that:

- Establish architectural patterns (repository pattern, service layer, etc.)
- Make cross-cutting architectural decisions
- Impact multiple other features
- Require architectural continuity across AI agent sessions

### System Architecture Review

Use when:

- New features impact system architecture
- Architectural decisions need to be made
- Cross-cutting concerns are identified
- Foundation features need to be created

## Step-by-Step Usage Instructions

### For AI Agents Starting Architectural Work

#### Step 1: Load Architectural Context

1. **Start with Feature Tracking**: Identify the foundation feature (0.x.x) you're working on
2. **Click Arch Context Link**: Load the specific Architecture Context Package
3. **Review Architecture Tracking**: Understand current architectural state
4. **Check Related ADRs**: Review architectural decisions

**Context Loading Priority Order**:

1. Architecture Context Package (highest priority)
2. Architecture Tracking (current state)
3. Related ADRs (key decisions)
4. Feature Dependencies (impact understanding)
5. Implementation Details (as space allows)

#### Step 2: Understand Current Focus

From the Architecture Context Package, identify:

- **Current Focus**: What architectural work is active
- **Key Decisions**: What architectural decisions are in place or needed
- **Implementation Status**: What's been done and what's next
- **Next Agent Instructions**: Clear next steps for continuation

#### Step 3: Work on Architectural Implementation

- Follow the Foundation Feature Implementation task process
- Update the Architecture Context Package as you progress
- Document architectural decisions in ADRs
- Update Architecture Tracking with session progress

#### Step 4: Prepare for Handover

Before ending your session:

1. **Update Architecture Context Package**: Reflect current progress and next steps
2. **Update Architecture Tracking**: Add session summary with outcomes
3. **Create/Update ADRs**: Document any architectural decisions made
4. **Update Feature Tracking**: Reflect implementation progress

### For Creating New Architectural Work

#### When System Architecture Review Identifies Foundation Features

1. **Create Foundation Feature**: Add 0.x.x feature to Feature Tracking
2. **Create Architecture Context Package**: Use existing template and patterns
3. **Update Architecture Tracking**: Add new architectural component
4. **Link Everything**: Ensure proper cross-references

#### When New Architectural Areas Are Needed

1. **Create New Context Package**: Follow naming convention `[area]-architecture-context.md`
2. **Add to Architecture Tracking**: Include in Current Architecture State table
3. **Update Feature Tracking**: Link relevant features to new context package
4. **Create Supporting ADRs**: Document architectural decisions

## Architecture Context Package Management

### Structure and Content

Each context package should contain:

- **Current Focus**: Active architectural work
- **Key Architectural Decisions**: ADRs and decision status
- **Implementation Status**: Progress tracking
- **Next Agent Instructions**: Clear handover guidance
- **Connected Features**: Features that depend on this architecture
- **Essential Context Files**: Links to supporting documentation
- **Critical Constraints**: Technical and business constraints
- **Last Session Summary**: Recent progress and next priorities

### Size Guidelines

- **Target Size**: ~100-120 lines (validated optimal size)
- **Information Density**: Essential information only, links to details
- **Context Window Friendly**: Fits comfortably in AI context windows
- **Bounded Scope**: Focus on specific architectural area

### Update Frequency

- **During Active Work**: Update as progress is made
- **Session Handovers**: Always update before ending session
- **Architectural Decisions**: Update when ADRs are created/modified
- **Status Changes**: Update when implementation status changes

## Architecture Tracking Management

### When to Update

- **Session Start**: Review current state
- **Session End**: Add session summary
- **Architectural Decisions**: Update ADR index
- **Status Changes**: Update Current Architecture State table

### Session Summary Format

Include in Architecture Sessions Summary:

- **Session Date**: When the work was done
- **Focus Area**: What architectural area was worked on
- **Key Outcomes**: What was accomplished
- **Next Agent Context**: What the next agent should focus on
- **Completion Status**: Current phase/status

## Common Patterns and Examples

### Example: Working on Data Architecture

1. **Load Context**: [Data Architecture Context Package](../../product-docs/technical/architecture/context-packages/data-architecture-context.md)
2. **Current Focus**: Repository pattern implementation
3. **Next Steps**: Implement base repository interface
4. **Update Progress**: Reflect implementation in context package
5. **Create ADR**: Document repository pattern decision
6. **Update Tracking**: Add session summary to Architecture Tracking

### Example: Starting New Architectural Area

1. **Identify Need**: System Architecture Review identifies new area
2. **Create Context Package**: `new-area-architecture-context.md`
3. **Add to Tracking**: Include in Current Architecture State
4. **Link Features**: Update Feature Tracking with context links
5. **Document Decisions**: Create initial ADRs

## Best Practices

### Context Management

- **Load Minimal Context**: Start with context package, expand as needed
- **Focus on Essentials**: Keep context packages focused and bounded
- **Link to Details**: Use links for additional information rather than including everything
- **Update Regularly**: Keep context packages current with progress

### Architectural Decisions

- **Document Decisions**: Create ADRs for significant architectural choices
- **Link to Implementation**: Connect ADRs to features and context packages
- **Update Status**: Keep ADR status current (Proposed → Accepted → Superseded)
- **Trace Impact**: Understand which features are affected by decisions

### Session Continuity

- **Clear Handovers**: Always update context packages before ending sessions
- **Next Steps**: Provide clear instructions for the next agent
- **Progress Tracking**: Document what was accomplished and what's next
- **Context Preservation**: Ensure architectural context survives session changes

### Framework Integration

- **Use Existing Processes**: Leverage existing task definitions and workflows
- **Follow Conventions**: Use established patterns for documentation and automation
- **Maintain Links**: Keep cross-references between documents current
- **Validate Consistency**: Ensure framework components stay aligned

## Troubleshooting

### Common Issues and Solutions

#### Context Package Too Large

**Problem**: Context package exceeds optimal size (~120 lines)
**Solution**:

- Move detailed information to linked documents
- Focus on essential information only
- Use hierarchical structure with links to details

#### Architectural Decisions Not Tracked

**Problem**: Architectural decisions made but not documented
**Solution**:

- Create ADRs for all significant decisions
- Update ADR index in Architecture Tracking
- Link ADRs from context packages and Feature Tracking

#### Session Continuity Lost

**Problem**: Next AI agent doesn't understand architectural context
**Solution**:

- Always update context packages before ending sessions
- Provide clear "Next Agent Instructions"
- Update Architecture Tracking with session summary
- Ensure all architectural decisions are documented

#### Framework Components Out of Sync

**Problem**: Context packages, tracking, and feature tracking don't align
**Solution**:

- Regular validation of cross-references
- Update all related documents when making changes
- Use consistent naming and linking conventions
- Validate links are functional

### Getting Help

- **Review Phase 3 Validation**: See successful framework application examples
- **Check Architecture Tracking**: Understand current architectural state
- **Consult Task Definitions**: Follow established task processes
- **Ask for Clarification**: When in doubt, ask your human partner

## Framework Evolution

The Architectural Integration Framework is designed to evolve based on usage experience. Key areas for potential enhancement:

- **Automation Scripts**: Tools for context package generation and updates
- **Validation Tools**: Scripts to ensure framework consistency
- **Additional Context Packages**: New architectural areas as they emerge
- **Enhanced Templates**: Improved templates based on usage patterns

## Related Documentation

- [Architecture Tracking](../state-tracking/permanent/architecture-tracking.md): Current architectural state
- [Task Transition Guide](task-transition-guide.md): Workflow patterns including architectural transitions
- [Foundation Feature Implementation Task](../../tasks/04-implementation/foundation-feature-implementation-task.md): Specialized task for architectural work
- [System Architecture Review Task](../../tasks/01-planning/system-architecture-review.md): Task for architectural analysis
- [Feature Tracking](../state-tracking/permanent/feature-tracking.md): Primary feature tracking with architectural integration

---

**Framework Integration**: Part of Architectural Integration Framework (PF-CON-002)
**Validation Status**: Based on successful Phase 3 validation with Feature 0.1.2
