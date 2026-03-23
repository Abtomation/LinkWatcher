---
id: PD-DES-002
type: Product Documentation
category: Technical Design
version: 1.1
created: 2026-03-18
updated: 2026-03-18
---

# User Workflow Map

This document maps user-facing workflows to the features that enable them. It serves as the bridge between feature-centric development and cross-feature E2E acceptance testing.

**How to use**: When all required features for a workflow reach "Implemented" status, create a cross-cutting E2E test specification for that workflow. See [Proposal PF-PRO-008](/doc/process-framework/proposals/scenario-based-e2e-acceptance-testing.md) for the full process.

**How to identify workflows**: Ask *"What does the user actually DO with this software?"* Each answer is a workflow candidate. Focus on user-visible actions and their expected observable outcomes.

## Workflows

| ID | Workflow | User Action | Required Features | Priority |
|----|----------|-------------|-------------------|----------|
| WF-001 | Single file move → links updated | Move/rename a file (VS Code, File Explorer, git) | 1.1.1, 2.1.1, 2.2.1 | P1 |
| WF-002 | Directory move → contained refs updated | Move/rename a directory | 1.1.1, 0.1.2, 2.1.1, 2.2.1 | P1 |
| WF-003 | Startup → initial project scan | Run `python main.py` or startup script | 0.1.1, 0.1.3, 0.1.2, 2.1.1, 1.1.1, 3.1.1 | P1 |
| WF-004 | Rapid sequential moves → consistency | Move multiple files in quick succession | 1.1.1, 0.1.2, 2.2.1 | P2 |
| WF-005 | Multi-format file move → all parsers handle | Move a file referenced from MD, YAML, JSON, Python, PS1 | 2.1.1, 2.2.1, 1.1.1 | P2 |
| WF-006 | Configuration change → behavior adapts | Edit config file or pass CLI arguments | 0.1.3, 1.1.1, 3.1.1 | P3 |
| WF-007 | Dry-run mode → preview without changes | Start with `--dry-run`, move files, observe logs | 0.1.3, 0.1.1, 2.2.1, 3.1.1 | P3 |
| WF-008 | Graceful shutdown → no corrupted files | Stop the LinkWatcher process (Ctrl+C, kill) | 0.1.1, 2.2.1, 0.1.2 | P2 |

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
