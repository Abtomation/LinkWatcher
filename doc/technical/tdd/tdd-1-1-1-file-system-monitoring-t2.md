---
id: PD-TDD-023
type: Technical Design Document
category: TDD Tier 2
version: 1.0
created: 2026-02-19
updated: 2026-04-09
feature_id: 1.1.1
feature_name: File System Monitoring
consolidates: [1.1.1-1.1.5]
tier: 2
retrospective: true
---

# Lightweight Technical Design Document: Event Handler

> **Retrospective Document**: This TDD describes the existing technical design of the LinkWatcher Event Handler, documented after implementation during framework onboarding (PF-TSK-066). Content is reverse-engineered from source code analysis.
>
> **Source**: Derived from [1.1.2 Implementation State](../../state-tracking/features/archive/1.1.2-event-handler-implementation-state.md) and source code analysis of `src/linkwatcher/handler.py`, `src/linkwatcher/move_detector.py`, and `src/linkwatcher/dir_move_detector.py`.

## 1. Overview

### 1.1 Purpose

The Event Handler subsystem is the central coordinator for real-time file system event processing. It bridges the watchdog file monitoring layer and the link maintenance subsystems (database, parser, updater). It receives raw OS-level file events and orchestrates the full "file moved → links updated" pipeline, including timer-based mechanisms to detect moves reported as delete+create pairs.

The subsystem is implemented as four modules:
- **`src/linkwatcher/handler.py`** — `LinkMaintenanceHandler`: Central coordinator that receives watchdog events, delegates to detectors, and orchestrates the link update pipeline
- **`src/linkwatcher/reference_lookup.py`** — `ReferenceLookup`: Reference resolution and DB management — multi-format path lookup, stale reference retry, database cleanup after moves, and file rescanning (extracted from handler.py via TD022)
- **`src/linkwatcher/move_detector.py`** — `MoveDetector`: Per-file move detection state machine (delete+create correlation with priority-queue expiry via single worker thread)
- **`src/linkwatcher/dir_move_detector.py`** — `DirectoryMoveDetector`: Batch directory move detection state machine (3-phase: detect, confirm, apply)

### 1.2 Related Features

| Feature | Relationship | Description |
|---------|-------------|-------------|
| 0.1.2 In-Memory Database | Consumer | Queries `get_references_to_file()` to find all files referencing a moved file; calls `remove_file_links()` during move cleanup (PD-BUG-035: no longer on timer-based deletion — stale entries left for self-healing) |
| 2.1.1 Parser Framework | Consumer | Calls `parse_file()` to rebuild link entries after a move; calls `parse_content()` for single-read within-file link updates (PD-BUG-025) |
| 2.2.1 Link Updater | Consumer | Calls `update_references()` to rewrite link paths in referencing files |
| 0.1.5 Path Utilities | Consumer | Calls `should_monitor_file()` and `should_ignore_directory()` to filter events |
| 0.1.1 Core Architecture | Provider | `LinkWatcherService` creates the handler and registers it with the Observer |
| 1.1.1 Watchdog Integration | Provider | watchdog Observer dispatches events to this handler |
| 3.1.1 Logging Framework | Cross-cutting | Uses `get_logger()` with `@with_context` decorator for structured event logging |

## 2. Key Requirements

**Key technical requirements this design satisfies:**

1. **Reliable move detection**: Handle both native `on_moved` events and the delete+create move pattern used by some tools (git, file managers) — using a 10-second timer buffer for per-file moves
2. **Directory move support**: Correctly update all files within a moved directory, as well as references to the directory path itself (e.g., quoted directory paths in scripts). Two mechanisms: (a) native `DirMovedEvent` via recursive walk, and (b) batch directory move detection via delete+create correlation (PD-BUG-019 fix) for Windows where watchdog fires individual file events instead of `DirMovedEvent`
3. **Event deduplication**: Prevent the same file move from triggering duplicate processing when multiple events arrive for the same operation
4. **Atomic link update pipeline**: For each detected move, execute the full pipeline (find references → update files → rescan moved file) without leaving the database in a partial state
5. **Thread safety**: Each detector module encapsulates its own thread-safe state — `MoveDetector` protects its pending deletes dict and priority queue, `DirectoryMoveDetector` protects its pending directory moves dict — preventing concurrent access issues between the watchdog daemon thread, worker/timer threads, and directory move processing threads

## 3. Quality Attribute Requirements

### 3.1 Performance Requirements

- **Response Time**: Link update pipeline completes within seconds of a file move event; no blocking operations on the watchdog observer thread itself. Directory moves are processed on separate daemon threads to avoid blocking event delivery
- **Throughput**: Designed for human-speed file operations (not bulk automated moves); single-threaded event processing for per-file moves, threaded batch processing for directory moves
- **Resource Usage**: `MoveDetector` uses a single daemon worker thread regardless of pending delete count (O(1) threads via heapq priority queue); `_pending` dict accumulates entries only within 10-second windows; `DirectoryMoveDetector.pending_dir_moves` dict holds directory state for up to 300 seconds (max timeout); both cleaned up immediately on processing; minimal memory footprint

### 3.2 Security Requirements

- **Data Protection**: Processes file paths only; no sensitive data; path values come from the OS via watchdog
- **Input Validation**: File filtering via `should_monitor_file()` prevents processing of system files, build outputs, and ignored directories

### 3.3 Reliability Requirements

- **Error Handling**: Each event handler catches exceptions per-file — errors in one file's processing don't abort the entire pipeline; errors are logged and counted in statistics
- **Data Integrity**: After processing a move, the moved file is rescanned to ensure the database accurately reflects its new location
- **Thread Safety**: Each detector encapsulates its own `threading.Lock` — `MoveDetector._lock` protects per-file move state and priority queue; `DirectoryMoveDetector._lock` protects batch directory move state. The worker thread, `on_created` handler, and directory move processing threads can race without data corruption
- **Monitoring**: Statistics counters (`files_moved`, `files_deleted`, `files_created`, `links_updated`, `errors`) provide operational visibility; protected by `_stats_lock` (PD-BUG-026) for thread-safe increments from observer, worker, and timer threads

### 3.4 Usability Requirements

- **Transparency**: All operations emit structured log messages — users see exactly what was detected and updated
- **Error Messages**: Errors during file processing are logged with context (file path, operation type) rather than failing silently

## 4. Technical Design

### 4.1 Data Models

**Primary data model: `FileOperation`** (from `src/linkwatcher/models.py`):

```python
@dataclass
class FileOperation:
    operation_type: str        # "moved", "deleted", "created"
    old_path: Optional[str]    # Original file path (before move)
    new_path: Optional[str]    # New file path (after move)
    timestamp: datetime        # Event timestamp
```

**4-module architecture** (after TD005 God Class decomposition + TD022 ReferenceLookup extraction):

```python
class LinkMaintenanceHandler(FileSystemEventHandler):
    def __init__(self, link_db, parser, updater, project_root,
                 monitored_extensions=None, ignored_directories=None,
                 config=None):
        self.link_db = link_db
        self.parser = parser
        self.updater = updater
        self.project_root = Path(project_root).resolve()
        self.logger = get_logger()

        # Configuration from parameters or DEFAULT_CONFIG
        self.monitored_extensions = monitored_extensions or DEFAULT_CONFIG.monitored_extensions.copy()
        self.ignored_dirs = ignored_directories or DEFAULT_CONFIG.ignored_directories.copy()

        # Move detection timing from config or defaults
        move_delay = config.move_detect_delay if config else DEFAULT_CONFIG.move_detect_delay
        dir_max_timeout = config.dir_move_max_timeout if config else DEFAULT_CONFIG.dir_move_max_timeout
        dir_settle = config.dir_move_settle_delay if config else DEFAULT_CONFIG.dir_move_settle_delay

        # Per-file move detection — delegated to MoveDetector (move_detector.py)
        self._move_detector = MoveDetector(
            on_move_detected=self._handle_detected_move,
            on_true_delete=self._process_true_file_delete,
            delay=move_delay,
        )

        # Batch directory move detection — delegated to DirectoryMoveDetector (dir_move_detector.py)
        self._dir_move_detector = DirectoryMoveDetector(
            link_db=link_db,
            project_root=self.project_root,
            on_dir_move=self._handle_confirmed_dir_move,
            on_true_file_delete=self._process_true_file_delete,
            max_timeout=dir_max_timeout,
            settle_delay=dir_settle,
        )

        # Reference lookup, DB management, and link updates (TD022/TD035)
        self._ref_lookup = ReferenceLookup(
            link_db=link_db,
            parser=parser,
            updater=updater,
            project_root=self.project_root,
            logger=self.logger,
        )

        # Event deferral during initial scan (PD-BUG-053)
        # Events arriving before the link DB is fully populated are queued
        # and replayed after notify_scan_complete() is called.
        self._scan_complete = threading.Event()
        self._scan_complete.set()  # default: process events normally
        self._deferred_events = []
        self._deferred_lock = threading.Lock()

        # Session statistics (protected by _stats_lock — PD-BUG-026)
        self.stats = {
            "files_moved": 0,
            "files_deleted": 0,
            "files_created": 0,
            "links_updated": 0,
            "errors": 0,
        }
        self._stats_lock = threading.Lock()

    # --- Public API for scan lifecycle (PD-BUG-053) ---

    def begin_event_deferral(self):
        """Activate event deferral before initial scan starts."""
        self._scan_complete.clear()

    def notify_scan_complete(self):
        """Signal scan done and replay all deferred events in order."""
        self._scan_complete.set()
        with self._deferred_lock:
            deferred = list(self._deferred_events)
            self._deferred_events.clear()
        for method_name, event in deferred:
            getattr(self, method_name)(event)

    # --- Watchdog error handling ---

    def on_error(self, event):
        """Handle watchdog errors to prevent silent observer thread death."""
        self.logger.error("watchdog_error", error=str(event))
        self._update_stat("errors")

    # --- Internal helper (PD-BUG-046) ---

    def _is_known_reference_target(self, abs_path):
        """Check if a non-monitored file is a known reference target in the DB.
        Delegates to LinkDatabase.has_target_with_basename() for O(1) lookup."""
        return self.link_db.has_target_with_basename(os.path.basename(abs_path))

class MoveDetector:
    """Per-file move detection via delete+create correlation (move_detector.py)."""
    def __init__(self, on_move_detected, on_true_delete, delay=10.0):
        self._pending: Dict[str, Tuple] = {}  # rel_path → (timestamp, file_size, abs_path)
        self._queue: List[Tuple] = []          # heapq of (expiry_time, rel_path)
        self._lock = threading.Lock()
        self._wake = threading.Event()         # Wakes single worker thread
        self._delay = delay  # Expiry buffer for delete+create correlation
        # Single daemon worker thread processes expired entries (TD107)

class DirectoryMoveDetector:
    """Batch directory move detection — 3-phase pipeline (dir_move_detector.py)."""
    def __init__(self, link_db, project_root, on_dir_move, on_true_file_delete, ...):
        self.pending_dir_moves: Dict[str, _PendingDirMove] = {}
        self._lock = threading.Lock()
        self._max_timeout = 300.0   # Max wait for all files
        self._settle_delay = 5.0    # Settle after last match
```

### 4.2 Event Routing Architecture

The handler delegates move detection to two specialized detector modules, each implementing its own state machine:

```
OS Event          Handler Method        Routing Logic
---------         --------------        -------------
                                        Phase 0 (all three handlers): if not _scan_complete → _defer_event() and return (PD-BUG-053)

FileMovedEvent  → on_moved()          → directory? → _handle_directory_moved()
                                        file (monitored OR _is_known_reference_target)? → _handle_file_moved()
FileDeletedEvent→ on_deleted()        → directory (or Windows misreported dir-as-file with known DB children)?
                                           → _handle_directory_deleted() → _dir_move_detector → 3-phase pipeline
                                        file (monitored OR _is_known_reference_target)?
                                           → _handle_file_deleted() → _move_detector.buffer_delete() → heapq(expiry=now+delay)
FileCreatedEvent→ on_created()        → _dir_move_detector.match_created_file() → batch match (Phase 2)
                                        _move_detector.match_created_file()     → callback → _handle_detected_move()
                                        neither                                 → scan new file
                                        Note: also processes creates for non-monitored files when move_detector.has_pending (PD-BUG-046)
ErrorEvent      → on_error()          → log watchdog_error, increment errors stat (prevents silent observer thread death)
Worker thread   → MoveDetector._expiry_worker()                → callback → _process_true_file_delete() → if file exists: rescan (PD-BUG-035)
Timer callback  → DirectoryMoveDetector._process_dir_move_settled()  → process batch with unmatched files
Timer callback  → DirectoryMoveDetector._process_dir_move_timeout()  → fallback: process or treat as true delete
```

**Event deferral** (PD-BUG-053): `LinkWatcherService` calls `begin_event_deferral()` before the initial scan, then `notify_scan_complete()` after. During the deferral window, all three event handlers (`on_moved`, `on_deleted`, `on_created`) queue events in `_deferred_events` (protected by `_deferred_lock`) instead of processing them. On scan completion, queued events are replayed in arrival order. This prevents move detection against an incomplete link database.

**Non-monitored reference targets** (PD-BUG-046): `_is_known_reference_target(abs_path)` checks if a file's basename appears as a target key in the link database via `has_target_with_basename()`. This allows moves/deletes of non-monitored files (e.g., `.png`, `.pdf`) to be detected when they are referenced by monitored files.

**Directory move detection on Windows** (PD-BUG-019): Windows watchdog fires `FileDeletedEvent` (with `is_directory=False`) for directory deletes, followed by individual `FileCreatedEvent` for each file. The `DirectoryMoveDetector` detects this via database lookup (`get_files_under_directory`) and routes to a 3-phase batch pipeline:
- **Phase 1 (Detect)**: Buffer known files in `_PendingDirMove`, start 300s max timer only
- **Phase 2 (Confirm)**: First `file_created` match infers `new_dir` via path subtraction; subsequent matches use prefix; settle timer resets per match; count-based completion triggers immediate processing
- **Phase 3 (Apply)**: Processing runs on separate daemon thread; calls back to handler via `on_dir_move` callback → `_handle_confirmed_dir_move` → `_handle_directory_moved`

**4-tuple deduplication key** for move events:
```python
dedup_key = (source_path, dest_path, file_size, modification_time)
```

### 4.3 Core Processing Pipeline

**File move pipeline** (`_handle_file_moved`):

```python
def _handle_file_moved(self, event: FileMovedEvent):
    # Step 1: Resolve relative paths from event
    old_path = self._get_relative_path(event.src_path)
    new_path = self._get_relative_path(event.dest_path)
    if not old_path or not new_path:
        return

    # Step 2: Look up references via ReferenceLookup (TD022 delegation)
    # Uses path-format variations (raw, abs, with/without ./ prefix)
    references = self._ref_lookup.find_references(old_path)

    if references:
        # Step 3: Capture old path variations BEFORE any mutation
        # — required for correct DB cleanup since updates mutate the DB
        old_targets = self._ref_lookup.get_old_path_variations(old_path)

        # Step 4: Update files first (before modifying the DB)
        update_stats = self.updater.update_references(references, old_path, new_path)

        # Step 5: Retry references with stale line numbers
        # (rescans affected files and retries once — TD009 dedup)
        self._ref_lookup.retry_stale_references(old_path, new_path, update_stats)

        # Step 6: Remove old DB entries and rescan affected files
        # moved_file_path skips the moved file — handled by Step 7
        self._ref_lookup.cleanup_after_file_move(
            references, old_targets, moved_file_path=old_path
        )

        self._update_stat("links_updated", update_stats["references_updated"])
        self._update_stat("errors", update_stats["errors"])

    # Step 7: Update links WITHIN the moved file (PD-BUG-025 single-read pattern)
    # Handles content updates AND DB updates for the moved file's own entries
    if self._should_monitor_file(event.dest_path):
        self._update_links_within_moved_file(old_path, new_path, event.dest_path)

    self._update_stat("files_moved")
```

**Directory move pipeline** (`_handle_directory_moved`):

```python
def _handle_directory_moved(self, event: FileMovedEvent):
    # Resolve relative dir paths (handler operates in project-relative space)
    old_dir = self._get_relative_path(event.src_path)
    new_dir = self._get_relative_path(event.dest_path)

    # Enumerate moved files — PD-BUG-071: extension-only filter (NOT
    # _should_monitor_file) so files are enumerated even when the
    # destination contains an ignored directory name (e.g. docs/ -> build/)
    moved_files = []
    for root, dirs, files in os.walk(event.dest_path):
        for file in files:
            if os.path.splitext(file)[1].lower() in self.monitored_extensions:
                rel_new = self._get_relative_path(os.path.join(root, file))
                rel_old = rel_new.replace(new_dir, old_dir, 1)
                moved_files.append((rel_old, rel_new))

    # Phase 0: Re-key DB source paths from old to new locations BEFORE any
    # reference lookup runs. PD-BUG-050: without this, the updater opens
    # moved files at their old paths and raises Errno 2.
    for old_fp, new_fp in moved_files:
        self.link_db.update_source_path(old_fp, new_fp)

    # Phase 1: Update references to files within the moved directory.
    # Implemented as a batched pipeline (TD128 + TD129):
    #   collect references per file → single batched updater pass across
    #   all referring files → per-file DB cleanup with deduplicated bulk
    #   rescan. Each referring file is opened/written at most once, and
    #   each affected file is rescanned at most once. See helpers
    #   _batch_update_references (Phase 1b) and
    #   _cleanup_and_rescan_moved_files (Phase 1c) for details.
    move_groups, per_file_data, deferred_rescan_files = [], [], set()
    for old_fp, new_fp in moved_files:
        file_refs, module_refs, old_targets = (
            self._ref_lookup.collect_directory_file_refs(old_fp, new_fp)
        )
        per_file_data.append((old_fp, new_fp, file_refs, module_refs, old_targets))
        if file_refs:
            move_groups.append((file_refs, old_fp, new_fp))
        if module_refs:
            # Python module rename: drop the .py suffix for module-form refs
            move_groups.append((module_refs, old_fp[:-3], new_fp[:-3]))
    self._batch_update_references(move_groups)
    self._cleanup_and_rescan_moved_files(per_file_data, deferred_rescan_files)

    # Phase 1.5: Update outward-pointing links inside moved files
    # (PD-BUG-039: directory moves must adjust relative links within
    # moved files, just like individual file moves do).
    for old_fp, new_fp in moved_files:
        abs_new = os.path.join(str(self.project_root), new_fp)
        self._update_links_within_moved_file(old_fp, new_fp, abs_new)

    # Phase 2: Update references to the directory path itself.
    # Delegated to _update_directory_path_references, which groups refs
    # by link_target and computes per-target old->new mappings via prefix
    # replacement. Handles three cases:
    #   - exact match: ref target == old_dir
    #   - subdirectory match: ref target startswith old_dir/
    #     (e.g. old_dir/assessments)
    #   - backslash-variant fallback for Windows-style paths
    self._update_directory_path_references(old_dir, new_dir)

    # Note: parent/ancestor directory-path references are not updated.
    # When a subdirectory moves, the parent directory's own filesystem path is
    # unchanged, so references targeting any ancestor remain valid. The pipeline
    # only adjusts: refs to files in the moved subtree (Phase 1), relative links
    # within moved files (Phase 1.5), and refs to the moved directory itself or
    # its descendants (Phase 2).
```

**Per-file move detection** (delegated to `MoveDetector` in `move_detector.py`):

```python
# In handler.py — on_deleted routes file deletes to MoveDetector
def on_deleted(self, event):
    if not event.is_directory:
        self._move_detector.buffer_delete(rel_path, abs_path)

# In handler.py — on_created checks MoveDetector first
def on_created(self, event):
    if self._move_detector.match_created_file(rel_path, abs_path):
        return  # Matched as move — callback fires _handle_detected_move()
    self._handle_file_created(event.src_path)

# In move_detector.py — MoveDetector state machine (TD107: single worker + heapq)
class MoveDetector:
    def buffer_delete(self, rel_path, abs_path):
        with self._lock:
            self._pending[rel_path] = (time.time(), file_size, abs_path)
            heapq.heappush(self._queue, (now + self._delay, rel_path))
        self._wake.set()  # Wake worker thread to recalculate sleep

    def match_created_file(self, rel_path, abs_path):
        with self._lock:
            # Match by filename to handle cross-directory moves
            if match_found:
                del self._pending[deleted_path]  # lazy queue cleanup by worker
                return deleted_path  # caller handles move via callback
        return None

    def _expiry_worker(self):
        # Single daemon thread: sleeps until earliest expiry, confirms true deletes
        while not self._stopped:
            with self._lock:
                # Pop expired entries, skip stale (lazy deletion)
                ...
            for rel_path in expired:
                self._on_delete(rel_path)
            self._wake.wait(timeout=wait_time)
```

**Batch directory move detection** (delegated to `DirectoryMoveDetector` in `dir_move_detector.py`):

```python
# In dir_move_detector.py
class _PendingDirMove:
    """Tracks state for a pending directory move detection."""
    deleted_dir: str             # Original directory path
    known_files: frozenset       # All files known under this directory
    dir_prefix: str              # normalize_path(deleted_dir) + "/"
    total_expected: int          # len(known_files)
    new_dir: Optional[str]       # Inferred from first match (None until then)
    matched_count: int           # Files matched so far
    unmatched: set               # Files not yet matched
    max_timer: Timer             # 300s fallback timer
    settle_timer: Optional[Timer]  # 5s settle after last match

class DirectoryMoveDetector:
    def handle_directory_deleted(self, deleted_dir):
        known_files = self.get_files_under_directory(deleted_dir)
        if known_files:
            pending = _PendingDirMove(deleted_dir, known_files)
            self.pending_dir_moves[deleted_dir] = pending
            # Start only max timer (300s) — no per-file timers
            pending.max_timer = Timer(300.0, self._process_dir_move_timeout, [deleted_dir])

    def match_created_file(self, created_path, created_abs_path):
        # Phase 2: Check each pending dir move for a match
        # First match: infer new_dir via path subtraction
        # Subsequent matches: prefix-based matching
        # All matched: trigger immediate processing on daemon thread

    def _process_dir_move(self, pending):
        # Phase 3: Process on separate thread
        # Calls on_dir_move callback → handler._handle_confirmed_dir_move()
        # Verify unmatched files on filesystem
        # Clean up pending_dir_moves entry
```

### 4.4 Quality Attribute Implementation

#### Performance Implementation

- All event handler methods return quickly — heavy processing delegated to `link_db`, `updater`, `parser`
- Deferred delete processing (via worker thread / timers) ensures delete events don't block the observer thread
- Batch directory move processing runs on separate daemon threads — the watchdog event thread is never blocked by link update I/O

#### Reliability Implementation

- Per-file try/except blocks in `_handle_directory_moved` ensure one failing file doesn't abort the entire directory move
- `MoveDetector._lock` prevents race conditions between the expiry worker thread and `on_created` handler for per-file moves
- `DirectoryMoveDetector._lock` prevents race conditions between event thread and timer/processing threads for batch directory moves
- Post-move rescan ensures database consistency even if the moved file contained its own links
- Batch directory moves: unmatched files are verified on filesystem before being treated as true deletes

#### Security Implementation

- All event paths pass through `should_monitor_file()` / `should_ignore_directory()` filtering before processing
- No user input involved — all paths come from OS-level watchdog events

## 5. Cross-References

### 5.1 Functional Requirements Reference

> **📋 Primary Documentation**: FDD Creation Task (PF-TSK-010)
> **🔗 Link**: [FDD PD-FDD-024](../../functional-design/fdds/fdd-1-1-1-file-system-monitoring.md) — File System Monitoring Functional Design Document
> **👤 Owner**: FDD Creation Task

**Brief Summary**: The handler implements all 7 functional requirements from FDD PD-FDD-024: native move detection, directory move processing, delete detection, cross-tool move (delete+create) detection, new file scanning, statistics tracking, and exclusion of content change events.

### 5.2 Testing Reference

> **📋 Primary Documentation**: Test Specification Creation Task (PF-TSK-012)
> **🔗 Link**: [Existing integration tests in test/automated/integration/]
>
> **Brief Summary**: The handler is covered primarily through integration tests (`test_file_movement.py`, `test_complex_scenarios.py`, `test_sequential_moves.py`, `test_windows_platform.py`) that verify end-to-end event processing. Unit tests in `test/automated/unit/test_handler.py` cover individual methods.

## 6. Implementation Plan

### 6.1 Dependencies

All dependencies are fully implemented (retrospective document):

- `src/linkwatcher/database.py` (0.1.2) — link database
- `src/linkwatcher/parser.py` (2.1.1) — file parser
- `src/linkwatcher/updater.py` (2.2.1) — link updater
- `src/linkwatcher/utils.py` (0.1.1) — path utilities (part of Core Architecture)
- `src/linkwatcher/reference_lookup.py` (1.1.1) — reference resolution and DB management (extracted from handler.py via TD022)
- `src/linkwatcher/move_detector.py` (1.1.1) — per-file move detection state machine (extracted from handler.py via TD005)
- `src/linkwatcher/dir_move_detector.py` (1.1.1) — batch directory move detection state machine (extracted from handler.py via TD005)

### 6.2 Implementation Notes (Retrospective)

The handler subsystem is implemented across four modules (refactored from a single God Class via TD005, with further extraction via TD022). Key implementation decisions:

1. `@with_context` logging decorator wraps event handlers to add structured log context automatically
2. **Callback-based decoupling**: `MoveDetector` and `DirectoryMoveDetector` communicate with the handler via callbacks (`on_move_detected`, `on_true_delete`, `on_dir_move`), keeping detector modules independent of handler internals
3. `MoveDetector._pending` keys are relative file paths — matching by filename for cross-directory moves
4. `MoveDetector` uses a single daemon worker thread with a heapq priority queue (TD107) — O(1) threads regardless of pending delete count. `DirectoryMoveDetector` timer threads are also daemon threads. Daemon threads do not prevent process shutdown
5. `_PendingDirMove.dir_prefix` must be constructed as `normalize_path(dir) + "/"` (not `normalize_path(dir + "/")`) because `os.path.normpath` strips trailing slashes — discovered during PD-BUG-019 fix
6. Batch directory move processing defers to separate daemon threads to avoid blocking the watchdog event thread, which would cause subsequent file events to queue and timers to expire
7. **Shared stale-reference retry**: Both per-file and directory move pipelines use `ReferenceLookup.retry_stale_references()` (resolved TD009 duplication)
8. **Unified DB update strategy** (TD017): Both pipelines reuse the same DB cleanup primitive — `cleanup_after_file_move()` — ensuring consistent anchor handling, path normalization, and fresh metadata after moves. The file-move pipeline calls `find_references()` and `get_old_path_variations()` directly; the directory-move pipeline wraps those into `collect_directory_file_refs()` so per-file work can be batched at the updater level (TD129) and rescans deduplicated across the whole batch (TD128) via `_cleanup_and_rescan_moved_files`
9. **Composition-based reference delegation** (TD022): Handler delegates all reference lookup and DB management to `ReferenceLookup` instance (`self._ref_lookup`), reducing handler.py from 873 to ~475 lines (46%)

## 7. Quality Measurement

### 7.1 Performance Monitoring

- Statistics counters provide session-level metrics accessible via `handler.stats`
- Log messages include timing context via `@with_context` decorator

### 7.2 Reliability Monitoring

- Error counter in stats tracks failed file operations
- Structured log messages identify which files failed and why

## 8. Open Questions

None — this is a retrospective document for a fully implemented, stable feature.

**Known Technical Debt** (post TD005/TD009/TD018 resolution):
- ~~TD005 God Class~~ — Resolved: handler.py decomposed into 3 modules (839 lines, down from 1281); further decomposed to 4 modules via TD022/TD035 (~475 lines)
- ~~TD009 Duplicated Stale Retry~~ — Resolved: shared `_retry_stale_references()` method used by both pipelines
- ~~TD018 Untracked Timers~~ — Resolved: `MoveDetector` now tracks timers in `_timers` dict, cancels on match/re-buffer (PF-REF-032). Further improved by TD107: replaced N timer threads with single worker thread + heapq priority queue (PD-REF-106)
- ~~TD017 Inconsistent DB Update~~ — Resolved: directory moves now use same remove+rescan pattern as file moves (PF-REF-033)
- ~~The per-file delete buffer delay (10s) is passed as a constructor parameter to `MoveDetector` but not yet exposed via `LinkWatcherConfig`~~ — Resolved: `config.move_detect_delay` now flows through `__init__` to `MoveDetector(delay=...)` (TD191)
- The deduplication mechanism uses a key tuple but the implementation details warrant verification against edge cases with very rapid sequential moves

## 9. AI Agent Session Handoff Notes

### Current Status

**Retrospective TDD** — Feature 1.1.1 File System Monitoring is fully implemented and stable. Originally created during onboarding (PF-TSK-066). Updated 2026-02-26 with PD-BUG-019 batch directory move detection design. Updated 2026-03-02 to reflect TD005 God Class decomposition. Updated 2026-03-04 to reflect 4-module architecture (handler.py + move_detector.py + dir_move_detector.py + reference_lookup.py) and correct pseudocode drift (TD045). Updated 2026-03-13 to add directory-path reference update logic in directory move pipeline (Enhancement PF-STA-053). Updated 2026-04-09 (TD191/PD-REF-179): added config parameter, event deferral API (PD-BUG-053), on_error(), _is_known_reference_target (PD-BUG-046), Phase 0 deferral in event routing, _stats_lock (PD-BUG-026).

### Next Steps

No outstanding implementation work. TD005 and TD009 resolved. PD-BUG-019 verified. Directory-path reference updates added (PF-STA-053). Parent directory prefix replacement added (PF-STA-058).

### Key Decisions

- **4-module architecture** (TD005/TD022): Handler decomposed into coordinator (`handler.py`) + two detector modules (`move_detector.py`, `dir_move_detector.py`) + reference lookup module (`reference_lookup.py`) communicating via callbacks and composition
- **Timer-based move detection** (10-second buffer) chosen over immediate delete processing to reliably detect cross-tool per-file moves
- **Batch directory move detection** (PD-BUG-019) uses 3-phase approach with 300s max timer + 5s settle timer + count-based completion
- **No `on_modified` override** is the explicit design decision — content changes are intentionally out of scope
- **Per-file exception handling** in directory moves ensures partial failures don't abort the full pipeline
- **`normalize_path(dir) + "/"`** pattern (not `normalize_path(dir + "/")`) required because `os.path.normpath` strips trailing slashes
- **Shared stale-reference retry** (TD009): Single `_retry_stale_references()` method used by both per-file and directory move pipelines

### Known Issues

None currently outstanding.
