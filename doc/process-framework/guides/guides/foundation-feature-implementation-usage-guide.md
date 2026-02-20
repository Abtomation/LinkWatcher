---
id: PF-GDE-038
type: Document
category: General
version: 1.0
created: 2025-08-01
updated: 2025-08-01
guide_title: Foundation Feature Implementation Usage Guide
guide_description: Comprehensive guide for using the Foundation Feature Implementation task effectively
guide_status: Active
---
# Foundation Feature Implementation Usage Guide

## Overview

This guide provides comprehensive instructions for using the Foundation Feature Implementation Task (PF-TSK-024) effectively. Foundation features are architectural components (version 0.x.x) that provide the structural foundation for regular business features. This task differs significantly from regular feature implementation due to its architectural focus and cross-cutting impact.

## When to Use

Use this guide when:

- Implementing foundation features identified during System Architecture Review
- Working on features with version 0.x.x in the feature tracking system
- Implementing architectural components that affect multiple features
- Establishing patterns that other features will follow
- Creating cross-cutting concerns like authentication, data access, or API infrastructure

> **🚨 CRITICAL**: Foundation features require architectural awareness and must integrate with Architecture Context Packages and Architecture Tracking throughout implementation

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Template Structure Analysis](#template-structure-analysis) *(Optional - for template customization guides)*
4. [Customization Decision Points](#customization-decision-points) *(Optional - for template customization guides)*
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Quality Assurance](#quality-assurance) *(Optional - for template customization guides)*
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)
9. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- **Task Definition Access**: Read the complete [Foundation Feature Implementation Task](../../tasks/04-implementation/foundation-feature-implementation-task.md) definition
- **Architectural Context**: Access to [Architecture Context Packages](../../state-tracking/permanent/architecture-context-packages.md) for the relevant architectural area
- **Foundation Specification**: Foundation feature specification from System Architecture Review
- **Development Environment**: Set up with architectural constraints and dependencies
- **ADR System Access**: Familiarity with the existing ADR system and `New-ArchitectureDecision.ps1` script

## Background

Foundation features are fundamentally different from regular business features:

**Foundation Features (0.x.x)**:
- Provide architectural infrastructure for other features
- Have cross-cutting impact affecting multiple components
- Require integration with Architecture Context Packages
- Must establish patterns for other features to follow
- Need comprehensive architectural documentation (ADRs)

**Key Concepts**:
- **Architecture Context Packages**: Bounded architectural context that provides focused guidance
- **Architecture Tracking**: State tracking for architectural decisions and evolution
- **Cross-Cutting Concerns**: Functionality that affects multiple features (auth, data access, API patterns)
- **Architectural Patterns**: Reusable solutions that other features should follow

## Template Structure Analysis

[Optional section for template customization guides. Analyze the template structure section by section, explaining the purpose of each part and how they work together. Include:
- Template sections breakdown
- Required vs. optional sections
- Section interdependencies
- Customization impact areas]

## Customization Decision Points

[Optional section for template customization guides. Identify key decision points users must make when customizing the template. Include:
- Critical customization choices
- Decision criteria and guidelines
- Impact of different choices
- Recommended approaches for common scenarios]

## Step-by-Step Instructions

### 1. Preparation Phase

1. **Load Architecture Context Package**
   - Navigate to the relevant Architecture Context Package for your foundation area
   - Review current architectural state and focus areas
   - Understand existing patterns and constraints

2. **Review Foundation Specification**
   - Study the foundation feature specification from System Architecture Review
   - Identify cross-cutting impacts and dependencies
   - Note which features will depend on this foundation

3. **Check Architecture Tracking**
   - Review current architectural decisions and progress
   - Understand how this foundation fits into the overall architectural evolution

**Expected Result:** Clear understanding of architectural context, foundation requirements, and cross-cutting impacts

### 2. Implementation Phase

1. **Implement Foundation Components**
   ```dart
   // Example: Creating a foundation service pattern
   abstract class FoundationService {
     Future<void> initialize();
     void dispose();
   }

   class AuthenticationService extends FoundationService {
     @override
     Future<void> initialize() async {
       // Foundation implementation
     }
   }
   ```

2. **Create Architectural Decision Records**
   ```powershell
   cd doc/product-docs/technical/architecture/design-docs/adr/
   ../../scripts/file-creation/New-ArchitectureDecision.ps1 -Title "Foundation Authentication Pattern" -Status "Proposed"
   ```

3. **Update Architecture Context Package**
   - Document new architectural patterns implemented
   - Update context with implementation results
   - Note integration points for dependent features

**Expected Result:** Foundation components implemented with proper architectural documentation

### 3. Finalization Phase

1. **Update Architecture Tracking**
   - Record foundation implementation completion
   - Document architectural evolution and outcomes
   - Note any architectural decisions made during implementation

2. **Prepare Handover Documentation**
   - Create clear guidance for implementing dependent features
   - Document usage patterns and integration points
   - Provide examples of how other features should use the foundation

3. **Update Feature Dependencies**
   - Mark foundation feature as complete in Feature Tracking
   - Update dependent features to reflect foundation availability

**Expected Result:** Complete foundation implementation with comprehensive architectural documentation and clear guidance for dependent features

### Validation and Testing

[Optional subsection for template customization guides. Include within the relevant step above or as a separate step. Provide:
- Methods to validate the customized template
- Testing procedures to ensure functionality
- Integration testing with related components
- Quality checks and verification steps]

## Quality Assurance

[Optional section for template customization guides. Provide comprehensive quality assurance guidance including:

### Self-Review Checklist
- [ ] Template sections are properly customized
- [ ] All required fields are completed
- [ ] Customization aligns with task requirements
- [ ] Cross-references and links are correct
- [ ] Examples are relevant and accurate

### Validation Criteria
- Functional validation: Template works as intended
- Content validation: Information is accurate and complete
- Integration validation: Template integrates properly with related components
- Standards validation: Follows project conventions and standards

### Integration Testing Procedures
- Test template with related scripts and tools
- Verify workflow integration points
- Validate cross-references and dependencies
- Confirm compatibility with existing framework components]

## Examples

### Example 1: Authentication Foundation Feature

**Scenario**: Implementing a foundation authentication system that will be used by user management, API security, and session handling features.

**Architecture Context Package**: `auth-context.md`
**Foundation Specification**: `authentication-foundation-specification.md`

**Implementation Steps**:
1. Load auth context package to understand current authentication state
2. Implement core authentication interfaces and base classes
3. Create ADR for authentication pattern decisions
4. Update auth context package with new patterns
5. Document integration patterns for dependent features

```dart
// Foundation authentication pattern
abstract class AuthenticationProvider {
  Future<AuthResult> authenticate(Credentials credentials);
  Future<void> logout();
  Stream<AuthState> get authStateStream;
}

class SupabaseAuthProvider extends AuthenticationProvider {
  // Implementation following architectural patterns
}
```

**Result**: Complete authentication foundation with clear patterns for user management, API security, and session handling features to follow

### Example 2: Data Access Foundation Feature

**Scenario**: Implementing a foundation data access layer that establishes patterns for all database interactions.

**Implementation Focus**:
- Repository pattern establishment
- Database connection management
- Query optimization patterns
- Error handling standards

**Result**: Standardized data access patterns that all business features can follow consistently

## Troubleshooting

### Architecture Context Package Not Found

**Symptom:** Cannot locate the Architecture Context Package for the foundation area

**Cause:** Architecture Context Package may not exist for this architectural area yet

**Solution:**
1. Check if the architectural area is covered by an existing context package
2. If not, create a new Architecture Context Package using the appropriate template
3. Consult with architectural stakeholders to define the bounded context

### Foundation Specification Unclear

**Symptom:** Foundation requirements are ambiguous or incomplete

**Cause:** System Architecture Review may not have provided sufficient detail

**Solution:**
1. Return to System Architecture Review task to clarify requirements
2. Engage with stakeholders to define clear architectural boundaries
3. Document assumptions and get approval before proceeding

### Cross-Cutting Impact Assessment Difficult

**Symptom:** Difficulty identifying which features will be affected by the foundation

**Cause:** Lack of clear feature dependency mapping

**Solution:**
1. Review Feature Tracking to identify related features
2. Analyze existing codebase for similar patterns
3. Consult Architecture Tracking for historical context
4. Create impact assessment document if needed

## Feature Implementation Mode Selection

> **📋 New Enhancement**: This section provides guidance for selecting between integrated and decomposed modes for regular feature implementation (non-foundation features).

### Overview

Regular feature implementation (non-0.x.x features) can be performed in two modes:

Regular feature implementation uses the **Decomposed Mode**: Seven focused tasks (PF-TSK-044, PF-TSK-051, PF-TSK-056, PF-TSK-052, PF-TSK-053, PF-TSK-054, PF-TSK-055) with explicit layer separation. Start with [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning-task.md).

> **Note**: The former "Integrated Mode" (PF-TSK-004) has been deprecated. All new feature implementations should use the decomposed workflow.

### When to Use Simplified Decomposed Mode

**✅ Use a subset of decomposed tasks when:**
- Feature can be completed in a single session
- Implementation is straightforward with minimal complexity
- Minimal layer separation (e.g., UI-only changes, simple backend updates)

**✅ Integrated Mode Advantages:**
- Faster for simple features (less task overhead)
- Single context to manage
- Familiar workflow for most developers
- Direct implementation without decomposition planning

**❌ Integrated Mode Disadvantages:**
- Context loss between sessions for complex features
- Difficult to track progress across multiple sessions
- No explicit layer separation guidance
- Handoffs between team members less structured

### When to Use Decomposed Mode (7 Tasks)

**✅ Use Decomposed Mode when:**
- Multi-session implementation expected (complex features)
- Feature has distinct layers (data, state, UI) requiring focused attention
- Context preservation is critical between sessions
- Team collaboration requires clear handoffs and responsibilities
- Session management and progress tracking are important
- Clear separation of concerns needed for code quality
- Feature complexity warrants structured implementation approach

**✅ Decomposed Mode Advantages:**
- Excellent context preservation between sessions via Feature Implementation State File
- Clear progress tracking across implementation layers
- Explicit separation of concerns (data → state → UI)
- Structured handoffs between AI agents or team members
- Granular quality gates at each layer transition
- Better session management for complex features

**❌ Decomposed Mode Disadvantages:**
- More overhead for simple features (7 tasks vs. 1)
- Requires Feature Implementation State File maintenance
- More planning and decomposition upfront
- May feel over-engineered for straightforward features

### Decomposed Mode Task Sequence

When using decomposed mode, follow this sequence:

```
1. Feature Implementation Planning (PF-TSK-044)
   ↓ [Create implementation roadmap]
2. Data Layer Implementation (PF-TSK-051)
   ↓ [Implement models, repositories, migrations]
3. State Management Implementation (PF-TSK-056)
   ↓ [Implement Riverpod providers and notifiers]
4. UI Implementation (PF-TSK-052)
   ↓ [Build widgets and screens]
5. Integration & Testing (PF-TSK-053)
   ↓ [Integrate layers and test]
6. Quality Validation (PF-TSK-054)
   ↓ [Validate quality standards]
7. Implementation Finalization (PF-TSK-055)
   ↓ [Prepare for deployment]
```

Each task updates the **Feature Implementation State File** to preserve context between sessions.

### Decision Framework

Use this decision tree to select the appropriate mode:

```
Is the feature expected to take multiple sessions?
├─ YES → Will the feature involve multiple layers (data, state, UI)?
│   ├─ YES → Use Decomposed Mode (granular tasks)
│   └─ NO → Consider team preference
│       ├─ Need context preservation → Use Decomposed Mode
│       └─ Prefer simplicity → Use Integrated Mode
└─ NO → Can the feature be completed in a single session?
    ├─ YES → Use Integrated Mode (single task)
    └─ NO → Use Decomposed Mode (multi-session expected)
```

### Mode Selection Examples

**Example 1: Simple UI Update → Integrated Mode**
- Task: Update button styling across app
- Complexity: Low (UI-only, single file changes)
- Sessions: 1 session expected
- **Decision**: Use simplified decomposed mode (skip Data Layer, State Management — go straight to UI Implementation)

**Example 2: New User Profile Feature → Decomposed Mode**
- Task: Complete user profile management with data persistence
- Complexity: High (data layer + state management + UI + tests)
- Sessions: 3-5 sessions expected
- Layers: Data models, repositories, providers, widgets, tests
- **Decision**: Use Decomposed Mode (PF-TSK-044 → PF-TSK-051 → PF-TSK-056 → PF-TSK-052 → PF-TSK-053 → PF-TSK-054 → PF-TSK-055)

**Example 3: API Integration → Consider Factors**
- Task: Integrate third-party API for notifications
- Complexity: Medium (API client + state management + error handling)
- Sessions: 2 sessions expected
- Factors to consider:
  - If clear layer separation needed → Decomposed Mode
  - If single developer, continuous work → Integrated Mode
  - If team handoff expected → Decomposed Mode

### Transitioning Between Modes

**Can you switch modes mid-implementation?**

- **From Integrated to Decomposed**: Yes, but requires creating Feature Implementation State File and documenting current progress across layers
- **From Decomposed to Integrated**: Not recommended (already committed to granular approach)

**Best Practice**: Make mode selection decision **before starting implementation** based on expected complexity and session count.

### State Tracking Differences

| Aspect | Integrated Mode | Decomposed Mode |
|--------|-----------------|-----------------|
| **State File** | Feature Tracking only | Feature Tracking + Feature Implementation State File |
| **Progress Tracking** | Overall status only | Granular per-layer progress |
| **Context Preservation** | Manual session notes | Structured state file updates |
| **Handoff Support** | Limited | Explicit via state file |
| **Code Inventory** | Not tracked | Detailed file-by-file tracking |

### Related Resources for Mode Selection

- [Task Transition Guide](task-transition-guide.md) - Decomposed task workflow details
- [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning-task.md) - Entry point for decomposed implementation
- [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning.md) - Decomposed mode entry point
- [Feature Implementation State Template](../../templates/templates/feature-implementation-state-template.md) - State file for decomposed mode
- [Feature Implementation State Tracking Guide](feature-implementation-state-tracking-guide.md) - Guide for maintaining state file

## Related Resources

- [Foundation Feature Implementation Task](../../tasks/04-implementation/foundation-feature-implementation-task.md) - Complete task definition
- [Foundation Feature Template](../../templates/templates/foundation-feature-template.md) - Template for foundation feature structure
- [Architecture Context Packages](../../state-tracking/permanent/architecture-context-packages.md) - Architectural context management
- [Architecture Tracking](../../state-tracking/permanent/architecture-tracking.md) - Architectural evolution tracking
- [System Architecture Review Task](../../tasks/01-planning/system-architecture-review.md) - Task that identifies foundation features
- [Feature Implementation Planning](../../tasks/04-implementation/feature-implementation-planning-task.md) - Regular feature implementation entry point for comparison
- [ADR Template](../../templates/templates/adr-template.md) - For documenting architectural decisions

<!--
TEMPLATE USAGE GUIDANCE:

ENHANCED METADATA:
- related_script: Include if this guide helps customize templates created by a specific script
- related_tasks: Include task IDs that this guide supports (comma-separated)
- These fields enhance traceability and make guides easier to discover and maintain

TEMPLATE CUSTOMIZATION GUIDE SECTIONS:
For guides that help customize templates created by scripts, use these optional sections:
- Template Structure Analysis: Break down the template structure and explain each section
- Customization Decision Points: Guide users through key customization decisions
- Validation and Testing: Include within Step-by-Step Instructions for testing procedures
- Quality Assurance: Provide comprehensive QA guidance with checklists and validation criteria

GENERAL GUIDE SECTIONS:
All guides use the standard sections: Overview, When to Use, Prerequisites, Background,
Step-by-Step Instructions, Examples, Troubleshooting, Related Resources
-->
