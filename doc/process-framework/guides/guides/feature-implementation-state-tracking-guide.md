---
id: PF-GDE-043
type: Document
category: General
version: 1.2
created: 2025-10-30
updated: 2026-02-19
guide_category: Development Process
guide_description: Comprehensive guide for creating and maintaining feature implementation state documents as living, bidirectional documentation throughout development sessions
related_tasks: PF-TSK-044
guide_title: Feature Implementation State Tracking Guide
guide_status: Active
---

# Feature Implementation State Tracking Guide

## Overview

This guide explains how to create and maintain **feature implementation state tracking documents** that serve as living documentation throughout a feature's entire lifecycle. These documents provide a single source of truth for feature implementation, replacing sequential handover documents with continuously-updated permanent records.

## When to Use

Use feature implementation state tracking when:

- Starting implementation of a new feature using the decomposed implementation workflow (starting with Feature Implementation Planning, PF-TSK-044)
- Implementing complex features that span multiple AI sessions or developers
- Tracking progress across multiple implementation tasks
- Need to maintain context across session boundaries
- Creating permanent documentation that remains useful post-implementation
- Providing a central reference for future feature extensions or maintenance

> **🚨 CRITICAL**: Feature state documents are **NEVER archived**. They serve as permanent feature documentation throughout the entire feature lifecycle and beyond.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Template Structure Analysis](#template-structure-analysis)
4. [Living Documentation Principles](#living-documentation-principles)
5. [Bidirectional Documentation Standard](#bidirectional-documentation-standard)
6. [Step-by-Step Instructions](#step-by-step-instructions)
7. [Update Patterns and Best Practices](#update-patterns-and-best-practices)
8. [Quality Assurance](#quality-assurance)
9. [Examples](#examples)
10. [Troubleshooting](#troubleshooting)
11. [Related Resources](#related-resources)

## Prerequisites

Before creating a feature implementation state document, ensure you have:

- **Feature Design Document** (TDD or Lightweight Design) completed and approved
- **Feature ID** assigned (typically during Feature Implementation Planning task)
- **Implementation Mode** determined (Mode B - Decomposed Implementation)
- **Understanding** of decomposed task sequence (each subtask has its own unique task ID assigned via ID registry)
- **Access** to the feature implementation state template (PF-TEM-037)

## Background

### The Problem with Traditional Handover Documents

Traditional implementation tracking uses sequential handover documents:

- Created at task boundaries only
- Provide one-way information transfer
- Become outdated quickly
- Difficult to maintain context across sessions
- Often abandoned after feature completion

### The Living Document Solution

Feature implementation state documents solve these problems by:

- **Continuous Updates**: Updated throughout implementation, not just at task boundaries
- **Single Source of Truth**: One document tracks all feature context and progress
- **Permanent Record**: Remains valuable long after feature completion
- **Session Continuity**: Provides complete context for resuming work
- **Bidirectional Traceability**: Links code to documentation and vice versa

## Template Structure Analysis

The feature implementation state template (PF-TEM-037) contains 12 major sections organized to support the entire feature lifecycle:

### Core Tracking Sections

1. **Feature Overview** - High-level feature description and business value (stable throughout implementation)
2. **Current State Summary** - 30-second snapshot of what's working, in progress, and blocked RIGHT NOW
3. **Implementation Progress** - Detailed task-by-task progress through decomposed implementation sequence
4. **Documentation Inventory** - Index of all design, user, and developer documentation related to the feature, plus any pre-existing project documentation identified during onboarding audit

#### Understanding "Existing Project Documentation" Subsection

Section 4 includes an **"Existing Project Documentation"** subsection for onboarding scenarios where the process framework is adopted into an existing project:

- **When populated**: During Codebase Feature Discovery (PF-TSK-064), step 4
- **When confirmed**: During Codebase Feature Analysis (PF-TSK-065), as part of per-feature analysis
- **When consumed**: During Retrospective Documentation Creation (PF-TSK-066), to extract content before writing from scratch
- **For new projects**: This subsection reads _"No pre-existing project documentation identified."_ — not applicable when the framework is used from the start

**Confirmation statuses**: `Unconfirmed` → `Confirmed` / `Partially Accurate` / `Outdated`

### Code and Integration Sections

5. **Code Inventory** - Complete inventory of files created, modified, and used by the feature (see detailed explanation below)
6. **Dependencies** - Feature, system, and code-level dependencies tracking
7. **Design Decisions** - Architectural choices, patterns, and their rationale

#### Understanding Code Inventory Subsections

The Code Inventory section has three critical subsections with **different purposes**:

**a. Files This Feature Imports (Direct Dependencies)**
- **Purpose**: Document what THIS feature needs to function
- **What to list**: All `import` statements FROM this feature's code
- **Example**: If `handler.py` has `from .logging import get_logger`, list `logging.py`
- **Use case**: Understanding dependencies when deploying or testing this feature

**b. Files That Depend On This Feature (Reverse Dependencies)**
- **Purpose**: Document which files USE this feature (impact analysis)
- **What to list**: All files that have `import` statements TO this feature's files
- **Example**: If `service.py` has `from .database import LinkDatabase`, and this is the `database` feature, list `service.py`
- **Use case**: When modifying this feature, know which files to check/test for breaking changes

**c. Files Created/Modified by This Feature**
- **Purpose**: Document ownership and scope
- **What to list**: All files this feature created or changed
- **Use case**: Understanding the complete footprint of this feature

> **🚨 CRITICAL**: Do NOT confuse (a) and (b). They are opposite directions:
> - (a) = What does my feature import? (Direct deps)
> - (b) = Who imports my feature? (Reverse deps for impact analysis)

### Problem and Solution Tracking

8. **Issues & Resolutions Log** - Problems encountered and their resolutions across sessions
9. **Next Steps** - Clear actionable guidance for next session or developer

### Quality and Learning Sections

10. **Quality Metrics** - Code quality, test coverage, and performance metrics
11. **API Documentation Reference** - Quick reference to full API documentation for the feature
12. **Lessons Learned** - Insights for improving future implementations and AI collaboration

## Living Documentation Principles

### What Makes This a "Living Document"

Feature state documents serve **different purposes at different stages**:

| Lifecycle Stage           | Primary Purpose                                                     | Key Sections Updated                                               |
| ------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **During Planning**       | Design validation, task sequencing                                  | Feature Overview, Implementation Progress, Dependencies            |
| **During Implementation** | Progress tracking, context preservation                             | Current State, Implementation Progress, Code Inventory, Issues Log |
| **During Testing**        | Quality validation, issue tracking                                  | Quality Metrics, Issues Log, Next Steps                            |
| **Post-Implementation**   | Permanent feature documentation, design decisions reference         | Documentation Inventory, Design Decisions, Lessons Learned         |
| **During Maintenance**    | Context for bug fixes, dependency understanding                     | Issues Log, Code Inventory, Dependencies                           |
| **During Extension**      | Foundation for modifications, understanding existing implementation | Feature Overview, Code Inventory, Design Decisions                 |
| **During Onboarding**     | Existing doc audit, content validation, extraction source          | Documentation Inventory (Existing Project Documentation)           |

### Update Frequency Guidelines

**Update After EVERY Work Session:**

- Current State Summary
- Next Steps
- Implementation Progress (current task)

**Update Immediately When Occurred:**

- Issues & Resolutions Log (when problems discovered)
- Code Inventory (when files created/modified)
- Design Decisions (when architectural choices made)

**Update Continuously Throughout Implementation:**

- Lessons Learned (capture insights as they occur)
- Quality Metrics (as tests written and coverage measured)
- Documentation Inventory (as documentation created)

**Never Archive**: The document remains active and useful throughout the feature's entire lifetime.

## Bidirectional Documentation Standard

### The Bidirectional Principle

**CRITICAL REQUIREMENT**: Feature markers must exist in **BOTH locations**:

1. **In State Document**: List files created/modified/used by the feature
2. **In Code Files**: Add feature markers directly in source code

This bidirectional approach ensures:

- Code can be traced to feature documentation
- Feature documentation can be traced to code
- No orphaned code or documentation
- Clear understanding of feature boundaries
- Easy impact analysis for changes

### Code Documentation Requirements

#### When CREATING New Files

Add a header comment at the top of the file:

```dart
// FEATURE: PF-FEA-XXX
// Feature Name: Booking Management System
// Created: 2025-01-20
// Purpose: Handles all booking-related operations for escape room reservations
//
// This file is part of the Booking Management feature and implements the
// BookingRepository for data persistence operations.

import 'package:flutter/foundation.dart';
// ... rest of imports

class BookingRepository {
  // ... implementation
}
```

**Required Elements:**

- Feature ID (PF-FEA-XXX)
- Feature Name
- Creation Date
- Clear purpose statement

#### When MODIFYING Existing Code

Add inline markers at modification points:

```dart
class UserRepository {
  // ... existing code ...

  // [FEATURE: PF-FEA-012] Booking Integration
  // Added: 2025-01-20 - Link users to their booking history
  Future<List<Booking>> getUserBookings(String userId) async {
    // Implementation that references bookings
    return await _bookingService.getBookingsByUser(userId);
  }

  // [FEATURE: PF-FEA-012] User Profile Extension
  // Modified: 2025-01-20 - Added bookingsCount field to user profile
  // Original: Returned only name, email, and profile_picture
  Future<UserProfile> getUserProfile(String userId) async {
    final profile = await _getUserData(userId);
    // NEW: Include bookings count
    final bookingsCount = await _getBookingsCount(userId);
    return profile.copyWith(bookingsCount: bookingsCount);
  }

  // ... rest of existing code ...
}
```

**Required Elements:**

- Feature ID with inline marker `[FEATURE: PF-FEA-XXX]`
- Brief description of change
- Date added/modified
- Context about what was changed (for modifications)

#### When USING Existing Code

If your feature uses existing code without modification, add a comment to the **USED file** (not your feature code):

```dart
// lib/services/auth_service.dart

// USED BY FEATURES: PF-FEA-008, PF-FEA-012, PF-FEA-015
// PF-FEA-008 (User Profile): Uses getCurrentUser() for profile data retrieval
// PF-FEA-012 (Booking System): Uses signIn() and getCurrentUser() for booking flow authentication
// PF-FEA-015 (Review System): Uses getCurrentUser() for review authorship

class AuthService {
  // ... implementation ...
}
```

**Required Elements:**

- List of all feature IDs that use this code
- Brief explanation of HOW each feature uses it

### Source of Truth Hierarchy

1. **Code Files** = Detailed feature markers (authoritative source)
2. **State Document** = Feature-centric overview and navigation

The state document's Code Inventory section provides high-level tracking, but code files contain the detailed markers.

## Step-by-Step Instructions

### Step 1: Create the Feature State Document

**When**: At the start of Feature Implementation Planning (the planning task will have its own unique task ID)

1. Navigate to the templates directory:

   ```bash
   cd doc/process-framework/templates/templates/
   ```

2. Copy the feature implementation state template:

   ```bash
   # Use the feature ID as the filename
   cp feature-implementation-state-template.md \
      ../../state-tracking/features/[feature-id]-implementation-state.md
   ```

3. **Naming Convention**: Use format `[feature-id]-implementation-state.md`

   - Example: `PF-FEA-012-implementation-state.md`
   - Use flat structure (one file per feature, no subdirectories)

4. **Location**: Always place in `doc/process-framework/state-tracking/features/`

**Expected Result**: You have a new state document ready for customization with correct naming and location.

### Step 2: Populate Core Metadata

1. Open the newly created state document

2. Update the YAML frontmatter metadata:

   ```yaml
   ---
   id: [Auto-assigned PF-FIS-XXX by ID registry]
   type: Process Framework
   category: Feature Implementation State
   version: 1.0
   created: [YYYY-MM-DD - today's date]
   updated: [YYYY-MM-DD - today's date]
   feature_id: [Your feature ID, e.g., PF-FEA-012]
   feature_name: [Descriptive name, e.g., "Booking Management System"]
   status: PLANNING
   implementation_mode: Mode B - Decomposed Implementation
   ---
   ```

3. **Status Values**: Use appropriate status for current stage
   - `PLANNING` - During Feature Implementation Planning task
   - `IN_PROGRESS` - During active implementation
   - `TESTING` - During testing and validation
   - `COMPLETE` - Implementation complete, pre-deployment
   - `DEPLOYED` - Feature deployed to production
   - `MAINTAINED` - Post-deployment, ongoing maintenance

**Expected Result**: Metadata accurately reflects feature identity and current status.

### Step 3: Complete Feature Overview Section

This section remains **stable throughout implementation**. Complete it thoroughly during planning.

1. **Write Feature Description** (2-3 paragraphs):

   - What the feature does
   - Why it exists
   - How it fits into the larger application

2. **Document Business Value**:

   - **User Need**: What problem this solves for users
   - **Business Goal**: What business objective this achieves
   - **Success Metrics**: How success will be measured post-deployment

3. **Define Scope**:
   - **In Scope**: List all capabilities included in this feature
   - **Out of Scope**: Explicitly list capabilities excluded or deferred

**Expected Result**: Anyone reading this section understands the feature's purpose, value, and boundaries without needing external documentation.

### Step 4: Initialize Tracking Sections

During planning, set up sections that will be updated throughout implementation:

1. **Current State Summary**:

   - Set status to `PLANNING`
   - Set completion to `0%`
   - Leave "What's Working" empty
   - Document planning activities in "What's In Progress"

2. **Implementation Progress**:

   - List all planned decomposed tasks in sequence (each task will have its own unique ID from ID registry)
   - Mark the current planning task as `[⚙]` (in progress)
   - Mark remaining tasks as `[ ]` (not started)
   - Document dependencies for each task

3. **Documentation Inventory**:

   - Link to feature design document
   - List planned user and developer documentation
   - **For onboarding/retrospective mode**: Populate "Existing Project Documentation" with docs from project survey (PF-TSK-064 step 4), all marked `Unconfirmed`

4. **Dependencies**:
   - Document all feature dependencies discovered during planning
   - List all required services and packages
   - Identify code dependencies based on design

**Expected Result**: All tracking sections are initialized and ready for continuous updates throughout implementation.

### Step 5: Maintain During Implementation

**Update the document continuously** as you implement the feature:

#### After EVERY Work Session:

1. **Update Current State Summary**:

   - Update "Last Updated" timestamp
   - Update completion percentage
   - Move completed items from "In Progress" to "Working"
   - Add new items to "In Progress"
   - Update or remove blockers

2. **Update Next Steps**:
   - Document 1-3 immediate next actions with specifics
   - Update upcoming work items
   - Add any new questions that need answers
   - Provide clear starting point for next session

#### As Implementation Progresses:

3. **Update Implementation Progress**:

   - Mark tasks complete with checkboxes
   - Document completion dates and durations
   - Verify success criteria met
   - List deliverables completed
   - Add session notes with important context

4. **Update Code Inventory**:

   - Add entries for each file created
   - Document all modifications to existing files
   - List test files as they're created
   - Track database/schema changes
   - **Always add corresponding code markers to actual files**

5. **Log Issues Immediately**:

   - Document problems when discovered
   - Track investigation steps
   - Document resolutions
   - Note prevention strategies

6. **Capture Design Decisions**:
   - Document why architectural choices were made
   - Explain trade-offs considered
   - Note implications for future work
   - Include validation criteria

**Expected Result**: The document always reflects current feature state and provides complete context for next session.

### Step 6: Complete Quality Sections

As testing and validation occur:

1. **Update Quality Metrics**:

   - Run linting and document results
   - Track test coverage percentages
   - Measure performance metrics
   - Document standards compliance

2. **Update API Documentation Reference**:

   - Link to full API documentation as it's created
   - Document public APIs exposed by the feature
   - List key integration points

3. **Capture Lessons Learned**:
   - Document what went well and why
   - Note what could be improved
   - Record effective AI collaboration patterns
   - Provide recommendations for similar features

**Expected Result**: Comprehensive quality documentation that supports deployment decisions and future improvements.

### Step 7: Finalize for Deployment

Before marking feature as COMPLETE:

1. **Verify All Sections Complete**:

   - [ ] All tasks marked complete in Implementation Progress
   - [ ] All code files documented in Code Inventory
   - [ ] All issues either resolved or tracked for future work
   - [ ] Quality metrics meet project standards
   - [ ] Documentation inventory complete and accurate

2. **Update Status**:

   - Change status from `IN_PROGRESS` to `COMPLETE`
   - Set completion to `100%`
   - Update timestamp

3. **Complete Lessons Learned**:
   - Ensure insights captured
   - Document recommendations for similar features
   - Note process framework improvements needed

**Expected Result**: Feature state document provides complete permanent record of feature implementation.

### Step 8: Maintain Post-Deployment

**Do NOT archive this document**. Continue to maintain it:

1. **Update for Bug Fixes**:

   - Add to Issues Log
   - Update Code Inventory if files modified
   - Track resolutions

2. **Update for Extensions**:

   - Document new capabilities added
   - Update Dependencies if new integrations
   - Add to Design Decisions for architectural changes

3. **Keep as Reference**:
   - Use for understanding feature context during maintenance
   - Reference when making related changes
   - Consult for dependency impact analysis

**Expected Result**: Document remains valuable indefinitely as permanent feature documentation.

## Update Patterns and Best Practices

### Session Start Pattern

When beginning a work session:

1. Read "Current State Summary" (30-second orientation)
2. Read "Next Steps" → "Immediate Next Actions"
3. Review "Issues & Resolutions Log" for any blockers
4. Check "Implementation Progress" for current task status
5. Review "Code Inventory" to understand what exists

### Session End Pattern

Before ending a work session:

1. Update "Current State Summary" with today's progress
2. Update "Implementation Progress" for current task
3. Add to "Code Inventory" for any files created/modified
4. Log any issues encountered to "Issues & Resolutions Log"
5. Update "Next Steps" with clear guidance for next session
6. Update "updated" timestamp in metadata

### Problem Documentation Pattern

When encountering an issue:

1. **Immediately** add to Issues & Resolutions Log
2. Document: Status, Severity, Problem, Impact, Investigation steps
3. Update "What's Blocked" in Current State Summary if applicable
4. Document resolution when solved
5. Add prevention strategy

### Design Decision Pattern

When making architectural choices:

1. Document in Design Decisions section immediately
2. Include: Options considered, Decision made, Rationale, Implications
3. Note validation criteria for verifying correctness
4. Cross-reference in Implementation Progress for the relevant task

### Code Inventory Synchronization

Keep Code Inventory synchronized with actual code:

1. **Before** creating a file: Plan entry in Code Inventory
2. **While** creating file: Add `// FEATURE: PF-FEA-XXX` marker to code
3. **After** creating file: Complete Code Inventory entry
4. For modifications: Document both in Code Inventory and with inline `[FEATURE:]` markers
5. Keep status column current (`COMPLETE`, `IN_PROGRESS`, `PLANNED`)

## Quality Assurance

### Self-Review Checklist

Before marking a task complete, verify:

#### Documentation Completeness

- [ ] All required sections completed for current implementation stage
- [ ] Code Inventory matches actual files created/modified
- [ ] All code files have appropriate feature markers
- [ ] Design decisions documented for major architectural choices
- [ ] Issues logged and resolved (or tracked for future work)

#### Accuracy and Consistency

- [ ] Timestamps are current
- [ ] Status fields accurately reflect current state
- [ ] Completion percentages are realistic
- [ ] Task success criteria accurately documented
- [ ] Dependencies correctly identified and documented

#### Quality and Usability

- [ ] Next Steps provide clear guidance for next session
- [ ] Current State Summary provides useful 30-second orientation
- [ ] Documentation links are valid and accurate
- [ ] Examples and context are sufficient for understanding
- [ ] Lessons learned capture valuable insights

### Validation Criteria

**Functional Validation**:

- Document serves its purpose as session continuity tool
- Next developer/AI can resume work without additional context
- All feature code can be traced from Code Inventory

**Content Validation**:

- Information is accurate and up-to-date
- Design decisions have clear rationale
- Issues documentation includes root cause and resolution

**Integration Validation**:

- Links to design documents work
- Links to related features accurate
- Task IDs reference correct process framework tasks
- Feature markers in code match Code Inventory

**Standards Validation**:

- Follows template structure (PF-TEM-037)
- Uses correct status values and terminology
- Adheres to bidirectional documentation standard
- Meets project documentation quality standards

### Common Quality Issues

| Issue                          | Impact                            | Prevention                                |
| ------------------------------ | --------------------------------- | ----------------------------------------- |
| Stale "Next Steps"             | Next session wastes time          | Update before EVERY session end           |
| Missing code markers           | Lost traceability                 | Add markers WHEN creating/modifying files |
| Incomplete issue documentation | Can't understand past problems    | Document immediately when discovered      |
| Outdated Current State         | Confusion about actual status     | Update after EVERY work session           |
| Missing design rationale       | Can't understand why choices made | Document decisions WHEN made              |

## Examples

### Example 1: Creating State Document for Booking Feature

**Scenario**: Starting implementation of a booking management feature (PF-FEA-012) during decomposed implementation.

**Step-by-Step Process**:

1. **Create document** (during Planning task):

   ```bash
   cp doc/process-framework/templates/templates/feature-implementation-state-template.md \
      doc/process-framework/state-tracking/features/PF-FEA-012-implementation-state.md
   ```

2. **Populate metadata**:

   ```yaml
   ---
   id: PF-FIS-012
   type: Process Framework
   category: Feature Implementation State
   version: 1.0
   created: 2025-01-20
   updated: 2025-01-20
   feature_id: PF-FEA-012
   feature_name: Booking Management System
   status: PLANNING
   implementation_mode: Mode B - Decomposed Implementation
   ---
   ```

3. **Complete Feature Overview**:

   - Describe booking feature purpose and functionality
   - Document business value (improve booking conversion rate)
   - Define scope (in scope: booking creation, cancellation; out of scope: payment processing)

4. **Initialize tracking sections**:

   - List all 7 decomposed tasks (each with its own unique task ID from ID registry)
   - Mark the planning task as in progress (using its assigned task ID)
   - Document dependencies on User Auth and Escape Room Catalog features

5. **Update continuously** during implementation:
   - After completing Data Layer task: Mark complete, document models and repos created
   - After State Management task: Update code inventory with providers and state classes
   - Throughout: Log issues, document design decisions, track progress

**Result**: Complete permanent documentation of booking feature implementation available for future reference.

### Example 2: Resuming Work After Session Break

**Scenario**: You're an AI agent starting a new session on the booking feature. Previous session ended mid-implementation.

**Process**:

1. **Open state document**:
   `doc/process-framework/state-tracking/features/PF-FEA-012-implementation-state.md`

2. **Read Current State Summary** (30 seconds):

   - Status: IN_PROGRESS
   - Current Task: State Management Implementation (using its unique task ID)
   - Completion: 45%
   - What's Working: ✓ Data models complete, ✓ Repository working
   - What's In Progress: ⚙ Creating Riverpod providers, ⚙ Implementing state notifiers

3. **Check Next Steps**:

   - Immediate Action #1: Complete BookingNotifier implementation in `lib/notifiers/booking_notifier.dart`
   - Files to work in: Listed clearly
   - Estimate: 1 hour

4. **Review Issues Log**:

   - Issue #1 (RESOLVED): Database query optimization - solution documented
   - Issue #2 (IN_PROGRESS): State management pattern decision - current investigation status

5. **Check Code Inventory**:

   - See what files already exist
   - Understand what's been created vs. what's planned

6. **Start work** with complete context:
   - Know exactly where to continue
   - Understand past decisions
   - Aware of any blockers or issues

**Result**: Productive session start with zero context loss, even with different AI instance or developer.

## Troubleshooting

### Document Feels Overwhelming

**Symptom**: The state document seems too complex or time-consuming to maintain.

**Cause**: Trying to complete all sections perfectly from the start, or updating all sections every time.

**Solution**:

1. Focus on the **essential sections** first: Current State, Implementation Progress, Next Steps
2. Update sections **as you naturally interact with them** during work
3. Use the "Update Patterns" (Session Start, Session End, Problem Documentation)
4. Remember: Maintaining this document **saves time** by preserving context

### Code Markers Are Inconsistent

**Symptom**: Some files have feature markers, others don't, or markers use different formats.

**Cause**: Adding markers as an afterthought instead of during file creation/modification.

**Solution**:

1. Make adding markers part of your **immediate workflow**:
   - Create file → Add header marker → Write code
   - Modify file → Add inline marker → Make change
2. Use the exact format patterns shown in this guide
3. Review Code Inventory regularly to catch missing markers

### State Document Becomes Outdated

**Symptom**: Document doesn't reflect current feature state, making it unhelpful.

**Cause**: Forgetting to update after work sessions, or only updating at task boundaries.

**Solution**:

1. **Session End Protocol**: Never end a session without updating these three sections:
   - Current State Summary
   - Next Steps
   - Implementation Progress (current task)
2. Set a reminder or use a checklist before session end
3. Update "updated" timestamp to know when document was last maintained

### Can't Find Information Quickly

**Symptom**: Spending too much time searching through the document for specific information.

**Cause**: Not using document structure effectively.

**Solution**:

1. Use the **Table of Contents pattern**:
   - Quick orientation? → Current State Summary
   - What's next? → Next Steps → Immediate Next Actions
   - Understanding past decisions? → Design Decisions
   - Finding specific code? → Code Inventory
   - Problems from previous sessions? → Issues & Resolutions Log
2. Use your editor's search function (Ctrl+F / Cmd+F)
3. Use Markdown headers for navigation in editors that support it

### Uncertainty About Level of Detail

**Symptom**: Not sure how detailed to make entries in various sections.

**Cause**: Template provides structure but not detail guidelines for all scenarios.

**Solution**: Use these heuristics:

- **Current State Summary**: High-level only (3-5 items per subsection)
- **Implementation Progress**: Enough detail that someone else could understand what was done
- **Code Inventory**: One row per file, list key components but not every function
- **Design Decisions**: Focus on **why** (rationale), not just **what**
- **Issues Log**: Enough detail to understand and prevent in future
- **Next Steps**: Specific enough that next person knows exactly what to do

### Difficulty Maintaining Bidirectional Documentation

**Symptom**: Code markers and Code Inventory getting out of sync.

**Cause**: Treating them as separate update tasks instead of one atomic operation.

**Solution**:

1. **Atomic Update Pattern**:
   ```
   1. Before touching code: Open state document Code Inventory section
   2. Create/modify code file with feature marker
   3. Immediately update Code Inventory entry
   4. Repeat for each file
   ```
2. During code reviews, verify both locations updated
3. Run periodic audits to check synchronization

## Related Resources

### Process Framework Documentation

- [Feature Implementation Task Decomposition Proposal](../../proposals/proposals/feature-implementation-task-decomposition-proposal.md) - Background on decomposed implementation approach
- [Feature Implementation State Template (PF-TEM-037)](../../templates/templates/feature-implementation-state-template.md) - Template structure used by this guide
- [Feature Implementation Planning (PF-TSK-044)](../../tasks/04-implementation/feature-implementation-planning-task.md) - Entry point for decomposed feature implementation

### Related Tasks

Each decomposed implementation task has its own unique task ID assigned via the ID registry system (created using New-Task.ps1):

- **Feature Implementation Planning** (unique task ID): When you initially create the state document
- **Data Layer Implementation** (unique task ID): When implementing data models and repositories
- **State Management Implementation** (unique task ID): When implementing state providers and notifiers
- **UI Implementation** (unique task ID): When implementing user interface components
- **Testing Implementation** (unique task ID): When implementing tests
- **Integration** (unique task ID): When integrating all components
- **Implementation Finalization** (unique task ID): When you complete and finalize the state document

### Related Templates

- [Feature Design Template](../../templates/templates/feature-design-template.md) - Design document referenced from state document
- [Task Template](../../templates/templates/task-template.md) - Task structure referenced in Implementation Progress

### External Resources

- [Living Documentation Principles](https://en.wikipedia.org/wiki/Living_documentation) - Background on living documentation concept
- [Bidirectional Traceability](https://en.wikipedia.org/wiki/Requirements_traceability) - Principles behind bidirectional documentation

---

## Guide Version History

| Version | Date       | Changes Made                                                                                                              | Changed By        |
| ------- | ---------- | ------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| 1.0     | 2025-01-30 | Initial guide creation: extracted instructional content from PF-TEM-037, added comprehensive examples and troubleshooting | Process Framework |
| 1.1     | 2025-01-30 | Updated task references: clarified that decomposed tasks receive unique IDs from ID registry, not lettered subtasks       | Process Framework |
| 1.2     | 2026-02-19 | Added "Existing Project Documentation" subsection guidance, onboarding lifecycle row, Step 4 onboarding note              | Process Framework |

---

**Document Maintenance Note**: This guide should be updated when:

- Template structure (PF-TEM-037) changes significantly
- New best practices for state tracking discovered
- Common issues identified that need troubleshooting guidance
- Process framework task structure changes (decomposed implementation tasks)
