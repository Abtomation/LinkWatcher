---
id: PD-FDD-024
type: Product Documentation
category: Functional Design Document
version: 1.0
created: 2026-02-19
updated: 2026-02-20
feature_id: 1.1.1
feature_name: File System Monitoring
consolidates: [1.1.1 (Watchdog Integration), 1.1.2 (Event Handler), 1.1.3 (Initial Scan), 1.1.4 (File Filtering), 1.1.5 (Real-time Monitoring)]
retrospective: true
---

# Event Handler - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher Event Handler, documented after implementation during framework onboarding (PF-TSK-066). Content is descriptive ("what is") rather than prescriptive ("what should be").
>
> **Source**: Derived from [1.1.2 Implementation State](../../../process-framework/state-tracking/features/1.1.2-event-handler-implementation-state.md), [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md) (Event Handler section), and source code analysis of `linkwatcher/handler.py`.

## Feature Overview

- **Feature ID**: 1.1.2
- **Feature Name**: Event Handler
- **Business Value**: Automatically detects every file move, rename, or delete event and triggers the complete link maintenance workflow — finding all affected files and rewriting their links. This is the central coordinator that makes LinkWatcher's real-time link maintenance possible.
- **User Story**: As a developer, I want the system to automatically detect when I move or rename any file and immediately update all links that reference it, so that I can freely reorganize my project without worrying about broken references.

## Related Documentation

### Architecture Overview Reference

> **📋 Primary Documentation**: [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md) - Event Handler section
> **👤 Source**: Pre-framework project documentation (Confirmed in PF-TSK-065 analysis)
>
> **Purpose**: Overview of event types, detection strategy, and processing pipeline.

**Functional Architecture Summary** (derived from HOW_IT_WORKS.md):

- The handler receives file system events from the watchdog Observer (running on a daemon thread) and coordinates the link maintenance workflow
- Move events trigger a four-step pipeline: find references → update files → rescan moved file → log results
- Delete events use a 2-second buffer to detect moves reported as delete+create pairs by some tools

### Technical Design Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-015)
> **🔗 Link**: [TDD to be created as part of PF-TSK-066]
>
> **Purpose**: Detailed technical implementation of `LinkMaintenanceHandler`, move detection timer mechanism, 4-tuple deduplication, and event routing logic.

**Functional Technical Requirements**:

- Event processing must complete within seconds of a file operation being performed (real-time response)
- Cross-tool move detection (delete+create pairs) must be resolved within the 2-second buffer window
- Directory moves must process every file within the moved directory individually

## Functional Requirements

### Core Functionality

- **1.1.2-FR-1**: The system SHALL detect when a file is moved or renamed and automatically update all links in other files that reference the moved file
- **1.1.2-FR-2**: The system SHALL detect when a directory is moved or renamed and automatically update all links in other files that reference any file within the moved directory
- **1.1.2-FR-3**: The system SHALL detect when a file is deleted and report all broken links that still reference the deleted file
- **1.1.2-FR-4**: The system SHALL detect moves reported as delete+create pairs (by tools that don't use native move events) and process them as moves rather than separate delete and create operations
- **1.1.2-FR-5**: The system SHALL scan newly created files and add their links to the database so their references are tracked going forward
- **1.1.2-FR-6**: The system SHALL track statistics (files moved, files deleted, files created, links updated, errors) and report them on shutdown
- **1.1.2-FR-7**: The system SHALL NOT process file content changes — only structural changes (moves, renames, deletes, creates) trigger link maintenance

### User Interactions

- **1.1.2-UI-1**: Users move or rename a file using any tool (VS Code, File Explorer, git mv, command line) — LinkWatcher detects the event automatically without any user action
- **1.1.2-UI-2**: Users see a log message confirming the move was detected: "File moved: old/path → new/path"
- **1.1.2-UI-3**: Users see log messages for each file that had its links updated: "Updated links in: file.md (2 references updated)"
- **1.1.2-UI-4**: When a file is deleted, users see a warning if any files still reference it: "Warning: 3 files still reference deleted file: path/to/deleted.md"
- **1.1.2-UI-5**: Users see session statistics on shutdown: "Session summary: 5 files moved, 12 links updated, 0 errors"

### Business Rules

- **1.1.2-BR-1**: Only files that pass the file filter (monitored extensions and non-ignored directories) trigger link maintenance — system files, build outputs, and ignored directories are excluded
- **1.1.2-BR-2**: Delete events are held for 2 seconds before processing; if a matching create event arrives within that window, the pair is processed as a move (not a delete+create)
- **1.1.2-BR-3**: After a file move, the moved file itself is rescanned to rebuild its own link entries in the database, ensuring the database reflects the file's new location
- **1.1.2-BR-4**: Duplicate events for the same file operation are detected and deduplicated to prevent processing the same move multiple times
- **1.1.2-BR-5**: Directory moves process every file within the moved directory individually — each file's references are updated based on the calculated old→new path mapping
- **1.1.2-BR-6**: File content changes (on_modified events) do not trigger link maintenance — LinkWatcher only responds to structural file path changes

## User Experience Flow

1. **Entry Point**: Developer moves a file using any method — no action needed in LinkWatcher itself

2. **File Move (native move event)**:
   - LinkWatcher detects the `on_moved` event from the OS via watchdog
   - System filters: checks if the file is monitored (correct extension, not in an ignored directory)
   - System queries the link database: "what files reference the old path?"
   - System updates each referencing file: rewrites the link to point to the new path
   - System rescans the moved file: rebuilds the database entries for links inside the moved file
   - User sees log confirming the move and the number of links updated

3. **Directory Move (native move event)**:
   - LinkWatcher detects the directory `on_moved` event
   - System walks all files in the new directory location
   - For each file: calculates old path (by subtracting the new directory prefix and adding the old directory prefix)
   - Processes each file's references using the same pipeline as a single file move
   - User sees log entries for each file within the moved directory

4. **Cross-Tool Move (delete+create pair)**:
   - Some tools (git, certain file managers) report moves as a delete event followed by a create event
   - LinkWatcher buffers the delete event for 2 seconds in a pending buffer
   - When the matching create event arrives within 2 seconds: the pair is treated as a move, triggering the full move pipeline
   - If no create arrives within 2 seconds: the delete is processed as a true deletion — broken links are reported
   - User sees the same move confirmation as a native move event

5. **File Deletion**:
   - After the 2-second buffer expires with no matching create, system processes as a true deletion
   - System queries the database for all files that still reference the deleted file
   - Users see a warning log for each file with a now-broken link
   - System removes the deleted file's own link entries from the database

6. **File Creation**:
   - New file is scanned and its links added to the database
   - User sees: "New file detected and scanned: path/to/new-file.md"

7. **Exit Point**: Process completes silently; statistics accumulated for shutdown summary

## Acceptance Criteria

- [x] **1.1.2-AC-1**: Moving a file via VS Code, File Explorer, or command line triggers a log entry confirming the move was detected within seconds
- [x] **1.1.2-AC-2**: All files that contained links to the moved file have those links updated to the new path
- [x] **1.1.2-AC-3**: Moving a directory updates links for every file within it, not just the directory root
- [x] **1.1.2-AC-4**: A delete+create pair occurring within 2 seconds is treated as a move (links updated, not reported as broken)
- [x] **1.1.2-AC-5**: A file deleted without a subsequent create produces a warning for each referencing file
- [x] **1.1.2-AC-6**: Saving file content (without moving) does not trigger any link maintenance activity
- [x] **1.1.2-AC-7**: Session statistics accurately reflect the count of moves, deletions, and link updates

> **Note**: All acceptance criteria are checked as this is a retrospective document — the feature is fully implemented and operational.

## Edge Cases & Error Handling

- **1.1.2-EC-1**: If a file move event arrives but the file has no references in the database, the system logs the move but reports "0 links updated" — no error
- **1.1.2-EC-2**: If a moved file cannot be rescanned (read error), the system logs the error and continues — the move update still proceeds
- **1.1.2-EC-3**: If a referencing file cannot be modified (write error, file locked), the system logs the error, increments the error counter, and continues processing other references
- **1.1.2-EC-4**: If two delete+create pairs arrive simultaneously for different files, each is tracked independently in the pending buffer — no cross-contamination
- **1.1.2-EC-5**: If the same file is moved twice in rapid succession, event deduplication prevents processing the first (now-stale) move after the second has already been processed
- **1.1.2-EC-6**: Files in monitored directories but with unmonitored extensions are ignored — their moves do not trigger link maintenance
- **1.1.2-EC-7**: Events for files within ignored directories (`.git/`, `__pycache__/`, etc.) are silently filtered before any processing occurs

## Dependencies

### Functional Dependencies

- **0.1.3 In-Memory Database**: Provides the link lookup capability — without it, the handler cannot find which files reference a moved file
- **2.1.1 Parser Framework**: Used after a move to rescan the moved file and rebuild its link database entries
- **2.2.1 Link Updater**: Performs the actual file writing to update link paths in referencing files
- **0.1.5 Path Utilities**: Provides the file filtering logic to determine which events should be processed

### Technical Dependencies

- **watchdog** (≥2.0): `FileSystemEventHandler` base class; provides `on_moved`, `on_deleted`, `on_created` event dispatch
- **threading** (stdlib): `threading.Timer` for the 2-second delete buffer; `threading.Lock` for thread-safe pending buffer access

## Success Metrics

- 100% of file moves trigger link updates (no silent failures)
- Link updates complete within seconds of a file move operation
- Zero broken links remain in the project after any file move operation
- Cross-tool moves (delete+create pairs) are correctly detected and processed as moves
- Statistics accurately reflect all operations performed during a session

## Validation Checklist

- [x] All functional requirements clearly defined with Feature ID prefixes (1.1.2-FR-1 through 1.1.2-FR-7)
- [x] User interactions documented (user moves file → automatic detection → log confirmation)
- [x] Business rules specified (2-second buffer, deduplication, directory walk, filter exclusions)
- [x] Acceptance criteria are testable and measurable (1.1.2-AC-1 through 1.1.2-AC-7)
- [x] Edge cases identified with expected behaviors (1.1.2-EC-1 through 1.1.2-EC-7)
- [x] Dependencies mapped (functional: Database, Parser, Updater, PathUtils; technical: watchdog, threading)
- [x] Success metrics defined
- [x] User experience flow covers all event types (native move, directory move, cross-tool move, delete, create)

---

_Retrospective Functional Design Document — documents existing implementation as of 2026-02-19._
