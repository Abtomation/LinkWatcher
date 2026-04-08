---
id: PD-STA-066
type: Product Documentation
category: State Tracking
version: 2.0
created: 2026-03-18
updated: 2026-04-07
previous_id: PD-DES-002
previous_location: doc/technical/design/user-workflow-map.md
---

# User Workflow Tracking

This document maps user-facing workflows to the features that enable them and tracks their implementation and testing status. It serves as the bridge between feature-centric development and cross-feature workflow awareness across all framework phases.

**How to use**:
- **Planning (Phase 01)**: When evaluating a new feature, check which workflows it participates in. Update this file if the feature introduces a new workflow.
- **Design (Phase 02)**: Reference this file when creating FDDs to populate the "Workflow Participation" section.
- **Implementation (Phase 04)**: Check which workflows your feature participates in to verify workflow correctness.
- **Validation (Phase 05)**: Use workflow groupings to batch co-participating features in validation sessions.
- **Maintenance (Phase 06)**: Look up affected workflows when triaging bugs or assessing refactoring blast radius.
- **Testing**: When all required features for a workflow reach "Implemented" status, create a cross-cutting E2E test specification. See [E2E Acceptance Testing Scenarios](/test/specifications/cross-cutting-specs/cross-cutting-spec-e2e-acceptance-testing-scenarios.md).

**How to identify workflows**: Ask *"What does the user actually DO with this software?"* Each answer is a workflow candidate. Focus on user-visible actions and their expected observable outcomes.

**Status derivation**: "Impl Status" is derived from [feature-tracking.md](/doc/state-tracking/permanent/feature-tracking.md). "E2E Status" is derived from [e2e-test-tracking.md](/test/state-tracking/permanent/e2e-test-tracking.md). Both will be auto-updated by `Update-WorkflowTracking.ps1` (called by `Update-FeatureImplementationState.ps1` and `Update-TestExecutionStatus.ps1`) once implemented.

## Workflows

| ID | Workflow | User Action | Required Features | Priority | Impl Status | E2E Status |
|----|----------|-------------|-------------------|----------|-------------|------------|
| WF-001 | Single file move → links updated | Move/rename a file (VS Code, File Explorer, git) | 1.1.1, 2.1.1, 2.2.1 | P1 | All Implemented | 🔄 Re-execution Needed |
| WF-002 | Directory move → contained refs updated | Move/rename a directory | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | P1 | All Implemented | 🔄 Re-execution Needed |
| WF-003 | Startup → initial project scan | Run `python main.py` or startup script | 0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1, 3.1.1 | P1 | Pending: 0.1.1 | 🔄 Re-execution Needed |
| WF-004 | Rapid sequential moves → consistency | Move multiple files in quick succession | 1.1.1, 0.1.2, 2.2.1 | P2 | All Implemented | ✅ Covered |
| WF-005 | Multi-format file move → all parsers handle | Move a file referenced from MD, YAML, JSON, Python, PS1 | 2.1.1, 2.2.1, 1.1.1 | P2 | All Implemented | 🔄 Re-execution Needed |
| WF-006 | Configuration change → behavior adapts | Edit config file or pass CLI arguments | 0.1.3, 1.1.1, 3.1.1 | P3 | All Implemented | Not Tested |
| WF-007 | Dry-run mode → preview without changes | Start with `--dry-run`, move files, observe logs | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | P3 | Pending: 0.1.1 | ✅ Covered |
| WF-008 | Graceful shutdown → no corrupted files | Stop the LinkWatcher process (Ctrl+C, kill) | 0.1.1, 2.2.1, 0.1.2 | P2 | Pending: 0.1.1 | ✅ Covered |

## Workflow Details

<details>
<summary><strong>WF-001: Single File Move</strong></summary>

User moves or renames a single file within the monitored project. All references to that file across the project are automatically updated to reflect the new location. This is the core value proposition of LinkWatcher.
</details>

<details>
<summary><strong>WF-002: Directory Move</strong></summary>

User moves or renames an entire directory. All references to files within that directory are updated, including nested subdirectories. Requires batch lookup in the link database to find all affected references.
</details>

<details>
<summary><strong>WF-003: Startup</strong></summary>

User starts LinkWatcher on an existing project. The system performs an initial scan to catalog all files and their references before beginning real-time monitoring. Involves all core subsystems.
</details>

<details>
<summary><strong>WF-004: Rapid Sequential Moves</strong></summary>

User performs multiple file moves in quick succession (e.g., reorganizing a directory structure). The system correctly processes all moves without missing updates or creating inconsistent state. Tests event batching and concurrent database access.
</details>

<details>
<summary><strong>WF-005: Multi-Format File Move</strong></summary>

User moves a file that is referenced from multiple file formats (markdown, YAML, JSON, Python, PowerShell). All references across all formats are correctly updated. Validates parser breadth.
</details>

<details>
<summary><strong>WF-006: Configuration Change</strong></summary>

User modifies LinkWatcher configuration (exclude directories, change monitored extensions, enable/disable dry-run). The system adapts its behavior accordingly.
</details>

<details>
<summary><strong>WF-007: Dry-Run Mode</strong></summary>

User starts LinkWatcher in dry-run mode to see what changes would be made without actually modifying any files. Useful for verification before enabling live updates.
</details>

<details>
<summary><strong>WF-008: Graceful Shutdown</strong></summary>

User stops LinkWatcher while file moves may be in progress. No files should be left in a corrupted or partially-updated state. Atomic writes ensure either full update or no change.
</details>
