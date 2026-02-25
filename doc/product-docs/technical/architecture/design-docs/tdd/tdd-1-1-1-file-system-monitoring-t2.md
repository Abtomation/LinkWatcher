---
id: PD-TDD-023
type: Technical Design Document
category: TDD Tier 2
version: 1.0
created: 2026-02-19
updated: 2026-02-20
feature_id: 1.1.1
feature_name: File System Monitoring
consolidates: [1.1.1-1.1.5]
tier: 2
retrospective: true
---

# Lightweight Technical Design Document: Event Handler

> **Retrospective Document**: This TDD describes the existing technical design of the LinkWatcher Event Handler, documented after implementation during framework onboarding (PF-TSK-066). Content is reverse-engineered from source code analysis.
>
> **Source**: Derived from [1.1.2 Implementation State](../../../../../process-framework/state-tracking/features/1.1.2-event-handler-implementation-state.md) and source code analysis of `linkwatcher/handler.py`.

## 1. Overview

### 1.1 Purpose

The Event Handler (`LinkMaintenanceHandler`) is the central coordinator for real-time file system event processing. It bridges the watchdog file monitoring layer and the link maintenance subsystems (database, parser, updater). It receives raw OS-level file events and orchestrates the full "file moved → links updated" pipeline, including a timer-based mechanism to detect moves reported as delete+create pairs.

### 1.2 Related Features

| Feature | Relationship | Description |
|---------|-------------|-------------|
| 0.1.3 In-Memory Database | Consumer | Queries `get_references_to_file()` to find all files referencing a moved file; calls `remove_file_links()` on deletion |
| 2.1.1 Parser Framework | Consumer | Calls `parse_file()` after a move to rebuild the moved file's link entries |
| 2.2.1 Link Updater | Consumer | Calls `update_references()` to rewrite link paths in referencing files |
| 0.1.5 Path Utilities | Consumer | Calls `should_monitor_file()` and `should_ignore_directory()` to filter events |
| 0.1.1 Core Architecture | Provider | `LinkWatcherService` creates the handler and registers it with the Observer |
| 1.1.1 Watchdog Integration | Provider | watchdog Observer dispatches events to this handler |
| 3.1.1 Logging Framework | Cross-cutting | Uses `get_logger()` with `@with_context` decorator for structured event logging |

## 2. Key Requirements

**Key technical requirements this design satisfies:**

1. **Reliable move detection**: Handle both native `on_moved` events and the delete+create move pattern used by some tools (git, file managers) — using a 2-second timer buffer
2. **Directory move support**: Correctly update all files within a moved directory by walking the new directory location and calculating old→new path mappings
3. **Event deduplication**: Prevent the same file move from triggering duplicate processing when multiple events arrive for the same operation
4. **Atomic link update pipeline**: For each detected move, execute the full pipeline (find references → update files → rescan moved file) without leaving the database in a partial state
5. **Thread safety**: Protect the `pending_deletes` buffer from concurrent access by the watchdog daemon thread (calling `on_deleted`/`on_created`) and the timer callback thread (calling `_execute_delete`)

## 3. Quality Attribute Requirements

### 3.1 Performance Requirements

- **Response Time**: Link update pipeline completes within seconds of a file move event; no blocking operations on the watchdog observer thread itself
- **Throughput**: Designed for human-speed file operations (not bulk automated moves); single-threaded event processing is sufficient
- **Resource Usage**: `pending_deletes` dict accumulates entries only within 2-second windows; cleaned up immediately on processing; minimal memory footprint

### 3.2 Security Requirements

- **Data Protection**: Processes file paths only; no sensitive data; path values come from the OS via watchdog
- **Input Validation**: File filtering via `should_monitor_file()` prevents processing of system files, build outputs, and ignored directories

### 3.3 Reliability Requirements

- **Error Handling**: Each event handler catches exceptions per-file — errors in one file's processing don't abort the entire pipeline; errors are logged and counted in statistics
- **Data Integrity**: After processing a move, the moved file is rescanned to ensure the database accurately reflects its new location
- **Thread Safety**: `threading.Lock` (`move_detection_lock`) protects all access to `pending_deletes`; timer callback and `on_created` can race without data corruption
- **Monitoring**: Statistics counters (`files_moved`, `files_deleted`, `files_created`, `links_updated`, `errors`) provide operational visibility

### 3.4 Usability Requirements

- **Transparency**: All operations emit structured log messages — users see exactly what was detected and updated
- **Error Messages**: Errors during file processing are logged with context (file path, operation type) rather than failing silently

## 4. Technical Design

### 4.1 Data Models

**Primary data model: `FileOperation`** (from `linkwatcher/models.py`):

```python
@dataclass
class FileOperation:
    source_path: str      # Original file path (before move)
    dest_path: str        # New file path (after move)
    operation: str        # "moved", "deleted", "created"
    timestamp: float      # Event timestamp
```

**In-handler state:**

```python
class LinkMaintenanceHandler(FileSystemEventHandler):
    def __init__(self, link_db, parser, updater, config, logger):
        self.link_db = link_db
        self.parser = parser
        self.updater = updater
        self.config = config
        self.logger = logger

        # Delayed move detection state
        self.pending_deletes: Dict[str, Dict] = {}
        self.move_detection_lock = threading.Lock()

        # Session statistics
        self.stats = {
            "files_moved": 0,
            "files_deleted": 0,
            "files_created": 0,
            "links_updated": 0,
            "errors": 0,
        }
```

### 4.2 Event Routing Architecture

The handler implements a **state machine with timer-based deferred processing** for move detection:

```
OS Event          Handler Method        Routing Logic
---------         --------------        -------------
FileMovedEvent  → on_moved()          → _handle_file_moved() or _handle_dir_moved()
FileDeletedEvent→ on_deleted()        → _handle_file_deleted() → pending_deletes + Timer(2s)
FileCreatedEvent→ on_created()        → check pending_deletes → _handle_file_moved() or scan
Timer callback  → _execute_delete()  → if still pending → true delete handling
```

**4-tuple deduplication key** for move events:
```python
dedup_key = (source_path, dest_path, file_size, modification_time)
```

### 4.3 Core Processing Pipeline

**File move pipeline** (`_handle_file_moved`):

```python
def _handle_file_moved(self, src_path: str, dest_path: str):
    # Step 1: Find all files that reference the old path
    references = self.link_db.get_references_to_file(src_path)

    # Step 2: Update links in all referencing files
    updated_count = self.updater.update_references(references, src_path, dest_path)

    # Step 3: Rescan the moved file to rebuild its own link entries
    new_links = self.parser.parse_file(dest_path)
    self.link_db.remove_file_links(src_path)
    for link in new_links:
        self.link_db.add_link(link)

    # Step 4: Update statistics and log
    self.stats["files_moved"] += 1
    self.stats["links_updated"] += updated_count
```

**Directory move pipeline** (`_handle_dir_moved`):

```python
def _handle_dir_moved(self, src_dir: str, dest_dir: str):
    # Walk the new directory location
    for root, dirs, files in os.walk(dest_dir):
        for filename in files:
            new_path = os.path.join(root, filename)
            # Calculate old path by path prefix substitution
            old_path = new_path.replace(dest_dir, src_dir, 1)
            if should_monitor_file(new_path, self.config):
                self._handle_file_moved(old_path, new_path)
```

**Delayed delete + move detection** (`_handle_file_deleted`, `on_created`, `_execute_delete`):

```python
def _handle_file_deleted(self, file_path: str):
    with self.move_detection_lock:
        self.pending_deletes[file_path] = {
            "path": file_path,
            "timestamp": time.time(),
        }
    # Schedule delete processing after 2 seconds
    timer = threading.Timer(2.0, self._execute_delete, [file_path])
    timer.daemon = True
    timer.start()

def on_created(self, event):
    # Check if this create matches a pending delete (cross-tool move)
    with self.move_detection_lock:
        # Match by filename (not full path) to handle cross-directory moves
        matching_delete = self._find_matching_delete(event.src_path)
        if matching_delete:
            del self.pending_deletes[matching_delete]
            self._handle_file_moved(matching_delete, event.src_path)
            return
    # No matching delete — true file creation
    self._handle_file_created(event.src_path)

def _execute_delete(self, file_path: str):
    with self.move_detection_lock:
        if file_path not in self.pending_deletes:
            return  # Already processed as a move
        del self.pending_deletes[file_path]
    # Process as true deletion
    self._handle_true_delete(file_path)
```

### 4.4 Quality Attribute Implementation

#### Performance Implementation

- All event handler methods return quickly — heavy processing delegated to `link_db`, `updater`, `parser`
- Timer-based delete processing ensures delete events don't block the observer thread

#### Reliability Implementation

- Per-file try/except blocks in `_handle_dir_moved` ensure one failing file doesn't abort the entire directory move
- `move_detection_lock` prevents race conditions between timer callback and `on_created` handler
- Post-move rescan ensures database consistency even if the moved file contained its own links

#### Security Implementation

- All event paths pass through `should_monitor_file()` / `should_ignore_directory()` filtering before processing
- No user input involved — all paths come from OS-level watchdog events

## 5. Cross-References

### 5.1 Functional Requirements Reference

> **📋 Primary Documentation**: FDD Creation Task (PF-TSK-010)
> **🔗 Link**: [FDD PD-FDD-024](../../../../functional-design/fdds/fdd-1-1-1-file-system-monitoring.md) — File System Monitoring Functional Design Document
> **👤 Owner**: FDD Creation Task

**Brief Summary**: The handler implements all 7 functional requirements from FDD PD-FDD-024: native move detection, directory move processing, delete detection, cross-tool move (delete+create) detection, new file scanning, statistics tracking, and exclusion of content change events.

### 5.2 Testing Reference

> **📋 Primary Documentation**: Test Specification Creation Task (PF-TSK-012)
> **🔗 Link**: [Existing integration tests in tests/integration/]
>
> **Brief Summary**: The handler is covered primarily through integration tests (`test_file_movement.py`, `test_complex_scenarios.py`, `test_sequential_moves.py`, `test_windows_platform.py`) that verify end-to-end event processing. Unit tests in `tests/unit/test_handler.py` cover individual methods.

## 6. Implementation Plan

### 6.1 Dependencies

All dependencies are fully implemented (retrospective document):

- `linkwatcher/database.py` (0.1.2) — link database
- `linkwatcher/parser.py` (2.1.1) — file parser
- `linkwatcher/updater.py` (2.2.1) — link updater
- `linkwatcher/utils.py` (0.1.1) — path utilities (part of Core Architecture)

### 6.2 Implementation Notes (Retrospective)

The handler was implemented as a single class in `linkwatcher/handler.py`. Key implementation decisions:

1. `@with_context` logging decorator wraps event handlers to add structured log context automatically
2. `pending_deletes` keys are full file paths (not basenames) — matching by filename/size comparison for cross-directory moves
3. Timer threads are marked as daemon threads — they do not prevent process shutdown

## 7. Quality Measurement

### 7.1 Performance Monitoring

- Statistics counters provide session-level metrics accessible via `handler.stats`
- Log messages include timing context via `@with_context` decorator

### 7.2 Reliability Monitoring

- Error counter in stats tracks failed file operations
- Structured log messages identify which files failed and why

## 8. Open Questions

None — this is a retrospective document for a fully implemented, stable feature.

**Known Technical Debt**:
- The 2-second delete buffer window is hardcoded — it is not configurable via `LinkWatcherConfig`
- The deduplication mechanism uses a key tuple but the implementation details warrant verification against edge cases with very rapid sequential moves

## 9. AI Agent Session Handoff Notes

### Current Status

**Retrospective TDD** — Feature 1.1.2 Event Handler is fully implemented and stable. This document was created during onboarding (PF-TSK-066) to formally document the design.

### Next Steps

No implementation work needed. Next documentation step: FDD and TDD creation continues for remaining Tier 2 features (3.1.1, 2.1.1, 2.2.1, 4.1.1, 4.1.3, 4.1.4, 4.1.6, 5.1.1, 5.1.2).

### Key Decisions

- **Timer-based move detection** (2-second buffer) chosen over immediate delete processing to reliably detect cross-tool moves
- **No `on_modified` override** is the explicit design decision — content changes are intentionally out of scope
- **Per-file exception handling** in directory moves ensures partial failures don't abort the full pipeline

### Known Issues

None for this feature.
