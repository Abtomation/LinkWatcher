---
id: PF-STA-000
type: Process Framework
category: State Tracking
version: 1.1
created: 2023-06-15
updated: 2025-07-19
---

# State Tracking

This directory contains state tracking files that maintain the current status of the BreakoutBuddies project. These files serve as the source of truth for project state and enable the self-documenting workflow of the task-based approach.

## Purpose

State tracking files help to:

1. Maintain project status between sessions
2. Provide clear inputs for tasks
3. Document the outputs of completed tasks
4. Enable seamless transitions between different tasks
5. Eliminate the need for explicit handover documentation

## Available State Files

| State File | Purpose | Updated By |
|------------|---------|------------|
| [feature-tracking.md](permanent/feature-tracking.md) | Track the status of all features | Feature Tier Assessment, TDD Creation, Test Specification Creation, Feature Implementation, Code Review |
| [test-case-implementation-tracking.md](permanent/test-implementation-tracking.md) | Track implementation status of test cases derived from test specifications | Test Specification Creation, Feature Implementation, Code Review |
| [technical-debt-tracking.md](permanent/technical-debt-tracking.md) | Track and manage technical debt items | Code Review, Process Improvement, Feature Implementation |
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

1. Use the [state file template](../templates/templates/state-file-template.md)
2. Focus on a specific aspect of project state
3. Define clear status codes and transitions
4. Document which tasks update this state file
5. Add the state file to this index

## Temporary State Files

### Purpose
Temporary state files in the `temporary/` directory track multi-session implementation work, complex task creation processes, or evaluation implementations. These files provide detailed tracking during active development phases.

### Lifecycle Management
- **Creation**: Use `New-TempTaskState.ps1` to create temporary state files
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
state-tracking/
├── permanent/          # Long-term project state files
├── temporary/          # Active temporary state files
│   └── old/           # Archived temporary state files
├── ../scripts/file-creation/New-TempTaskState.ps1ion/New-TempTaskState.ps1ion/New-TempTaskState.ps1
└── README.md
```
