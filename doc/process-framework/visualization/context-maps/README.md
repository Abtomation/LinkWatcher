---
id: PF-VIS-000
type: Process Framework
category: Visualization
version: 1.0
created: 2025-06-11
updated: 2025-06-11
---

# Context Maps

Context Maps are visual diagrams showing only the components relevant to specific tasks. They're designed to help AI agents quickly understand the essential context for a task without loading excessive documentation into their limited context windows.

## Purpose & Benefits

- Provides a focused view of only the components relevant to a specific task
- Reduces context window usage by visually representing relationships
- Helps AI agents prioritize which components to focus on first
- Standardizes the way components and their relationships are described
- Improves session continuity by establishing shared mental models

## How to Use Context Maps

1. **At the start of a task**:

   - Reference the appropriate context map in the "Context Requirements" section
   - Begin by understanding critical components (red) before important ones (blue)
   - Use the map to identify which documents need to be loaded into context

2. **During implementation**:

   - Refer back to the map when adding new components or interactions
   - Ensure new code maintains the relationships shown in the map
   - Use component names consistently as shown in the map

3. **For handoffs between AI sessions**:
   - Include a reference to the relevant context map in your session summary
   - Note any changes to component relationships made during your session

## Map Organization

Context maps are organized by task type:

- `/01-planning/` through `/07-deployment/` - Maps for categorized development tasks
- `/support/` - Maps for support and infrastructure tasks
- `/cyclical/` - Maps for recurring tasks that follow defined cycles

## Creating New Context Maps

When creating a new context map:

1. Use the [template.md](../../templates/templates/context-map-template.md) as a starting point
2. Follow the [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md)
3. Include only components directly relevant to the task
4. Clearly mark component priorities (critical, important, reference)
5. Create the map in the appropriate task type directory
6. Update the task document to reference the new map

## Available Context Maps

### Discrete Tasks

- [Bug Fixing Map](06-maintenance/bug-fixing-map.md) - Components for fixing bugs
- [Code Review Map](06-maintenance/code-review-map.md) - Components for reviewing code changes
- [Feature Implementation Map](04-implementation/feature-implementation-map.md) - Components for feature development and implementation (all complexity levels)
- [Feature Discovery Map](01-planning/feature-discovery-map.md) - Components for exploring and defining features
- [Feature Tier Assessment Map](01-planning/feature-tier-assessment-map.md) - Components for assessing feature complexity
- [Process Improvement Map](support/process-improvement-map.md) - Components for improving development processes
- [Release Deployment Map](07-deployment/release-deployment-map.md) - Components for release and deployment
- [Structure Change Map](support/structure-change-map.md) - Components for implementing structural changes
- [TDD Creation Map](02-design/tdd-creation-map.md) - Components for creating technical design documents
- [Test Specification Creation Map](03-testing/test-specification-creation-map.md) - Components for creating comprehensive test specifications

### Cyclical Tasks

- [Documentation Review Map](cyclical/documentation-review-map.md) - Components for reviewing documentation
- [Documentation Tier Adjustment Map](cyclical/documentation-tier-adjustment-map.md) - Components for adjusting documentation tiers
- [Tools Review Map](support/tools-review-map.md) - Components for reviewing development tools
- [New Task Creation Process Map](support/new-task-creation-process-map.md) - Components for creating new task definitions

## Related Resources

- [Visual Notation Guide](/doc/process-framework/guides/guides/visual-notation-guide.md) - Standard notation used in context maps
- [Component Relationship Index](/doc/product-docs/technical/architecture/component-relationship-index.md) - Complete reference of component relationships
