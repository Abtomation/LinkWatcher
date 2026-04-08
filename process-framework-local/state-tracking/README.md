---
id: PD-STA-000
type: Process Framework
category: State Tracking
version: 1.2
created: 2023-06-15
updated: 2026-04-03
---

# State Tracking

This directory contains state tracking files that maintain the current status of the project. These files serve as the source of truth for project state and enable the self-documenting workflow of the task-based approach.

## Purpose

State tracking files help to:

1. Maintain project status between sessions
2. Provide clear inputs for tasks
3. Document the outputs of completed tasks
4. Enable seamless transitions between different tasks
5. Eliminate the need for explicit handover documentation

## Available State Files

### Product State (`doc/state-tracking/permanent/`)

| State File | Purpose | Updated By |
|------------|---------|------------|
| [feature-tracking.md](../../doc/state-tracking/permanent/feature-tracking.md) | Track the status of all features | Feature Tier Assessment, TDD Creation, Test Specification Creation, Feature Implementation, Code Review |
| [feature-request-tracking.md](../../doc/state-tracking/permanent/feature-request-tracking.md) | Intake queue for product feature requests | Feature Request Evaluation |
| [bug-tracking.md](../../doc/state-tracking/permanent/bug-tracking.md) | Track reported bugs, triage status, and fixes | Bug Triage, Bug Fixing |
| [technical-debt-tracking.md](../../doc/state-tracking/permanent/technical-debt-tracking.md) | Track and manage technical debt items | Code Review, Process Improvement, Feature Implementation |
| [architecture-tracking.md](../../doc/state-tracking/permanent/architecture-tracking.md) | Cross-cutting architectural state and AI agent continuity | System Architecture Review, ADR Creation |
| [user-workflow-tracking.md](../../doc/state-tracking/permanent/user-workflow-tracking.md) | Track user workflow completion for E2E test readiness | Feature Implementation, E2E Test Execution |

### Test State (`test/state-tracking/permanent/`)

| State File | Purpose | Updated By |
|------------|---------|------------|
| [test-tracking.md](../../test/state-tracking/permanent/test-tracking.md) | Track implementation status of test cases derived from test specifications | Test Specification Creation, Feature Implementation, Code Review |
| [e2e-test-tracking.md](../../test/state-tracking/permanent/e2e-test-tracking.md) | Track E2E acceptance test case creation and execution status | E2E Test Case Creation, E2E Test Execution |

### Process Framework State (`process-framework-local/state-tracking/permanent/`)

| State File | Purpose | Updated By |
|------------|---------|------------|
| [process-improvement-tracking.md](permanent/process-improvement-tracking.md) | Track process improvement initiatives and their status | Process Improvement, Tools Review |


## State File Structure

Each state file follows a consistent structure:

1. **Header**: File purpose and last update information
2. **Status Legend**: Explanation of status codes and meanings
3. **Main Content**: Structured data about the tracked items
4. **History**: Record of significant changes

## Updating State Files

When updating state files:

1. Follow the structure defined in the file
2. Update the "Last Updated" timestamp
3. Make atomic changes (one logical change per commit)
4. Include a brief note in the history section for significant changes

## Creating New State Files

To create a new state file:

1. Use the [state file template](../../process-framework/templates/support/state-file-template.md)
2. Focus on a specific aspect of project state
3. Define clear status codes and transitions
4. Document which tasks update this state file
5. Add the state file to this index

## Temporary State Files

### Purpose
Temporary state files in the `temporary/` directory track multi-session implementation work, complex task creation processes, or evaluation implementations. These files provide detailed tracking during active development phases.

### Lifecycle Management
- **Creation**: Use `support/New-TempTaskState.ps1` to create temporary state files
- **Active Use**: Update regularly during implementation sessions
- **Completion**: When all objectives are met, **move** (don't delete) to `temporary/old/` directory
- **Archival**: Files in `temporary/old/` serve as historical reference and lessons learned

### Archiving Policy
**IMPORTANT**: Temporary state files should **never be deleted**. They contain valuable historical information about:
- Implementation decisions and rationale
- Challenges encountered and solutions found
- Session-by-session progress tracking
- Lessons learned for future similar work

**Correct Process**:
1. ✅ Move completed temporary files to `temporary/old/`
2. ✅ Update any references to reflect the new location
3. ✅ Maintain the file for historical reference

**Incorrect Process**:
1. ❌ Delete temporary files after completion
2. ❌ Remove historical tracking information

### Directory Structure
```
process-framework-local/state-tracking/    # Process framework state
├── permanent/                             # Long-term process state files
├── temporary/                             # Active temporary state files
│   └── old/                               # Archived temporary state files
└── README.md

doc/state-tracking/permanent/              # Product state files
test/state-tracking/permanent/             # Test state files
```
