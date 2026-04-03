---
id: PD-TDD-021
type: Product Documentation
category: Technical Design Document
version: 1.0
created: 2026-02-19
updated: 2026-02-25
tier: 3
feature_id: 0.1.1
feature_name: Core Architecture
consolidates: [0.1.1, 0.1.2 (Data Models), 0.1.5 (Path Utilities)]
retrospective: true
---

# Technical Design Document: Core Architecture

> **Retrospective Document**: This TDD describes the existing technical design of the LinkWatcher Core Architecture, documented after implementation during framework onboarding (PF-TSK-066). Content is reverse-engineered from source code analysis.
>
> **Source**: Derived from source code analysis of `linkwatcher/service.py`, `linkwatcher/__init__.py`, `linkwatcher/models.py`, `linkwatcher/utils.py`, and `main.py`.

>
> **Scope Note**: This feature consolidates old 0.1.1 (Core Architecture), 0.1.2 (Data Models), and 0.1.5 (Path Utilities).

## 1. Overview

### 1.1 Purpose

The Core Architecture defines the service-oriented, modular structure of LinkWatcher. The central `LinkWatcherService` class acts as an Orchestrator/Facade — instantiating, wiring, and managing the lifecycle of all subsystems (database, parser, updater, handler, observer) without implementing any business logic itself.

### 1.2 Scope

**In Scope**:
- `LinkWatcherService` class design and lifecycle management
- Package public API via `__init__.py`
- CLI entry point (`main.py`) and argument parsing
- Signal handling for graceful shutdown
- Component wiring and dependency injection

**Out of Scope**:
- File event handling logic (→ 1.1.1 Event Handler)
- Link parsing logic (→ 2.1.1 Parser Framework)
- Link update logic (→ 2.2.1 Link Updater)
- In-memory storage (→ 0.1.2 In-Memory Database)
- Logging implementation (→ 3.1.1 Logging Framework)

### 1.3 Related Features

| Feature | Relationship | Description |
|---------|-------------|-------------|
| _(Data Models)_ | _(part of 0.1.1)_ | LinkReference and FileOperation data classes (consolidated from old 0.1.2) |
| 0.1.2 In-Memory Database | Component dependency | Provides LinkDatabase for link storage |
| 0.1.3 Configuration System | Configuration dependency | Provides LinkWatcherConfig for service configuration |
| _(Path Utilities)_ | _(part of 0.1.1)_ | Path normalization functions (consolidated from old 0.1.5) |
| 1.1.1 Event Handler | Runtime dependency | Provides LinkMaintenanceHandler for event processing (includes Watchdog integration) |
| 2.1.1 Parser Framework | Component dependency | Provides LinkParser for link extraction |
| 2.2.1 Link Updater | Component dependency | Provides LinkUpdater for file modification |
| 3.1.1 Logging Framework | Cross-cutting | Provides structured logging via get_logger() |

## 2. Requirements

### 2.1 Functional Requirements

See [FDD PD-FDD-022](../../functional-design/fdds/fdd-0-1-1-core-architecture.md) for complete functional requirements. Key requirements driving technical design:

- **0.1.1-FR-1**: Single orchestrator entry point coordinating all subsystems
- **0.1.1-FR-2**: Initial recursive scan with link database population
- **0.1.1-FR-3**: Continuous file system monitoring after scan
- **0.1.1-FR-5**: Graceful shutdown via OS signal handling
- **0.1.1-FR-7**: Public Python API via package import

### 2.2 Quality Attribute Requirements

#### Performance Requirements

- **Startup Time**: Initial scan of 1000+ files completes within seconds
- **Event Latency**: File move events detected and processed sub-second (watchdog latency + handler processing)
- **Memory Usage**: In-memory database scales linearly with number of tracked links
- **CPU Usage**: Idle CPU usage minimal (sleep-based polling loop with watchdog event threading)

#### Security Requirements

- **File Access**: Service only modifies files within the monitored project directory
- **Path Safety**: All paths normalized through 0.1.5 Path Utilities to prevent traversal
- **Signal Handling**: Only SIGINT and SIGTERM are intercepted; no arbitrary signal handling

#### Reliability Requirements

- **Error Isolation**: Individual file processing errors do not crash the service
- **Thread Safety**: Observer runs on daemon thread; service manages thread lifecycle
- **Clean Shutdown**: `try/finally` ensures Observer.stop() and Observer.join() are always called
- **No Data Loss**: Link database is rebuilt on every startup; no persistent state to corrupt

#### Usability Requirements

- **CLI Interface**: Standard argument parsing with `--help` support
- **Console Feedback**: Colored output with progress indicators during scan
- **Configuration Flexibility**: Multiple config sources (CLI, env, file, defaults)

### 2.3 Constraints

- Python 3.8+ required (f-strings, pathlib, dataclasses)
- Windows-primary platform (path handling, terminal colors)
- Single-process design (no multi-process or distributed architecture)
- Blocking foreground process (background execution via external scripts)

## 3. Architecture

### 3.1 Component Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        main.py (CLI)                             │
│  argparse → config loading → LinkWatcherService instantiation    │
└──────────────────────┬───────────────────────────────────────────┘
                       │ creates & starts
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                   LinkWatcherService                              │
│  (Orchestrator/Facade - service.py)                              │
│                                                                  │
│  __init__(project_root, config=None):                            │
│    ├── LinkDatabase()              ← 0.1.2                       │
│    ├── LinkParser()                ← 2.1.1                       │
│    ├── LinkUpdater(project_root)   ← 2.2.1                       │
│    ├── LinkMaintenanceHandler(     ← 1.1.1                       │
│    │     link_db, parser, updater, project_root,                 │
│    │     monitored_extensions, ignored_directories)              │
│    └── register signal handlers (SIGINT, SIGTERM)                │
│                                                                  │
│  start(initial_scan=True):                                       │
│    ├── Optional: _initial_scan()   ← 1.1.1 (Initial Scan)        │
│    ├── Observer(handler, path)     ← 1.1.1 (Watchdog)           │
│    ├── observer.start()                                          │
│    └── while self.running: sleep(1)  ← 1.1.1 (Monitoring)       │
│                                                                  │
│  stop():                                                         │
│    ├── self.running = False                                      │
│    ├── observer.stop()                                           │
│    ├── observer.join()                                           │
│    └── _print_final_stats()                                      │
│                                                                  │
│  get_status() → dict          ← Runtime inspection               │
│  force_rescan()               ← Clears DB + re-runs scan        │
│  set_dry_run(enabled)         ← Delegates to LinkUpdater        │
│  add_parser(ext, parser)      ← Registers parser + extension    │
│  check_links() → dict         ← Validates all links on disk     │
└──────────────────────────────────────────────────────────────────┘
```

### 3.2 Data Flow

```
1. STARTUP PHASE:
   main.py → parse args → load config → LinkWatcherService(project_root, config=config)

2. INITIAL SCAN PHASE:
   service.start() → os.walk(project_dir) → for each file:
     LinkParser.parse(file) → [LinkReference, ...] → LinkDatabase.add_links()

3. MONITORING PHASE:
   Observer → file system event → LinkMaintenanceHandler.on_moved(event):
     LinkDatabase.get_links_for_target(old_path) → [LinkReference, ...]
     LinkUpdater.update_links(links, old_path, new_path) → modified files
     LinkDatabase.update_targets(old_path, new_path)

4. SHUTDOWN PHASE:
   SIGINT/SIGTERM → _signal_handler() → self.running = False
   → observer.stop() → observer.join() → print_statistics()
```

### 3.3 State Management

- **Service State**: Single `self.running` boolean flag controls the main loop
- **Component State**: Each subsystem manages its own internal state:
  - `LinkDatabase`: `Dict[str, List[LinkReference]]` (target-indexed)
  - `LinkParser`: Stateless facade over parser registry
  - `LinkUpdater`: Stateless (receives config per operation)
  - `LinkMaintenanceHandler`: Delegates move detection to `MoveDetector` (per-file) and `DirectoryMoveDetector` (batch directory) via callbacks
- **Threading Model**: Observer runs on daemon thread; service main thread polls `self.running`

## 4. Detailed Design

### 4.1 LinkWatcherService Class

```python
class LinkWatcherService:
    """Central orchestrator — coordinates all subsystems."""

    def __init__(self, project_root: str = ".", config: LinkWatcherConfig = None):
        self.project_root = Path(project_root).resolve()
        self.config = config
        self.running = False
        self.link_db = LinkDatabase()
        self.parser = LinkParser()
        self.updater = LinkUpdater(str(self.project_root))
        self.handler = LinkMaintenanceHandler(
            self.link_db, self.parser, self.updater,
            str(self.project_root),
            monitored_extensions=config.monitored_extensions if config else None,
            ignored_directories=config.ignored_directories if config else None,
        )
        self.observer = None  # Created lazily in start()

        # Register signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

    def start(self, initial_scan: bool = True):
        """Start monitoring: optional scan → start observer → poll."""
        if initial_scan:
            self._initial_scan()
        self.observer = Observer()
        self.observer.schedule(self.handler, str(self.project_root), recursive=True)
        self.observer.start()
        self.running = True
        try:
            while self.running:
                time.sleep(1)
        finally:
            self.stop()

    def stop(self):
        """Clean shutdown: stop observer, join thread, report stats."""
        self.running = False
        if self.observer:
            self.observer.stop()
            self.observer.join()
        self._print_final_stats()

    def _signal_handler(self, signum, frame):
        self.running = False

    def _initial_scan(self):
        """Walk project directory, parse all monitored files, populate database."""
        # Uses os.walk with directory pruning via dirs[:] mutation
        # Delegates to self.parser.parse_file() and self.link_db.add_link()

    # --- Public API methods (runtime control & inspection) ---

    def get_status(self) -> dict:
        """Get current service status (running state, project root, DB and handler stats)."""
        # Returns dict with: running, project_root, database_stats, handler_stats, last_scan

    def force_rescan(self):
        """Force a complete rescan of all files. Clears database and re-runs _initial_scan()."""

    def set_dry_run(self, enabled: bool):
        """Enable or disable dry run mode. Delegates to LinkUpdater.set_dry_run()."""

    def add_parser(self, extension: str, parser: BaseParser):
        """Add a custom parser for a specific file extension.
        Registers the parser and adds the extension to handler's monitored set."""

    def check_links(self) -> dict:
        """Check all links and return broken ones.
        Iterates all targets in database, checks filesystem existence (stripping
        #fragment anchors), returns dict with total_checked, broken_count, broken_links."""
```

### 4.2 Data Models (models.py)

```python
@dataclass
class LinkReference:
    """Represents a link reference found in a file."""
    file_path: str        # Source file containing the link
    line_number: int      # Line number where the link appears
    column_start: int     # Column offset of link start
    column_end: int       # Column offset of link end
    link_text: str        # Raw link text as written in the source
    link_target: str      # Resolved target path the link points to
    link_type: str        # Parser type: 'markdown', 'yaml', 'direct', etc.

@dataclass
class FileOperation:
    """Represents a file system operation."""
    operation_type: str   # 'moved', 'deleted', 'created'
    old_path: Optional[str]
    new_path: Optional[str]
    timestamp: datetime
```

`LinkReference` is the primary data transfer object — produced by parsers (2.1.1), stored in LinkDatabase (0.1.2), and consumed by LinkUpdater (2.2.1). `FileOperation` records file system events for logging and statistics.

### 4.3 Duplicate Instance Prevention

The service uses a PID-based lock file to prevent multiple instances from running on the same project simultaneously.

**Lock File Location**: `<project_root>/.linkwatcher.lock`

**Lock File Format**: Plain text file containing the PID of the running process (e.g., `12345`).

**Lifecycle**:

1. **Acquisition** (in `main.py`, before `LinkWatcherService` instantiation):
   - Check if `.linkwatcher.lock` exists in the project root
   - If exists, read the PID and check if the process is still alive (`os.kill(pid, 0)` on Unix, `psutil`-free approach via `ctypes` or `os.kill` on Windows)
   - If PID is alive → exit with error message: "LinkWatcher is already running (PID: {pid})"
   - If PID is stale (process not running) → log warning "Overriding stale lock file", delete and recreate
   - If lock file does not exist → create it with current PID
2. **Release** (in `main.py` `finally` block, after `service.start()` returns):
   - Delete the lock file
   - Handles both clean shutdown (Ctrl+C) and exception paths via `try/finally`

**Error Handling**:
- If lock file cannot be created (permissions) → log warning and proceed without lock protection
- If lock file cannot be read (corrupt content) → treat as stale, override with warning

**PowerShell Startup Script**: `start_linkwatcher_background.ps1` also checks for existing python processes associated with LinkWatcher before launching a new instance, providing a secondary guard at the script level.

### 4.4 CLI Entry Point (main.py)

```python
def main():
    parser = argparse.ArgumentParser(description="LinkWatcher - Real-time link maintenance")
    parser.add_argument("--project-root", default=".", help="Project root directory")
    parser.add_argument("--config", help="Configuration file path (YAML or JSON)")
    parser.add_argument("--dry-run", action="store_true", help="Preview changes")
    parser.add_argument("--no-initial-scan", action="store_true", help="Skip initial scan")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")
    parser.add_argument("--quiet", action="store_true", help="Suppress non-error output")
    parser.add_argument("--log-file", help="Log to file")
    parser.add_argument("--version", action="version", version="LinkWatcher 2.0.0")
    args = parser.parse_args()

    # Multi-source config loading: CLI > env > file > defaults
    config = load_config(args.config, args)

    # Lock file prevents duplicate instances
    lock_file = acquire_lock(project_root)
    service = LinkWatcherService(str(project_root), config=config)
    service.start(initial_scan=config.initial_scan_enabled)
```

### 4.5 Package API (__init__.py)

```python
from .database import LinkDatabase
from .logging import LogLevel, LogTimer, get_logger, setup_logging, with_context
from .models import FileOperation, LinkReference
from .parser import LinkParser
from .path_resolver import PathResolver
from .service import LinkWatcherService
from .updater import LinkUpdater

__all__ = [
    "LinkWatcherService", "LinkDatabase", "LinkParser", "LinkUpdater",
    "PathResolver", "LinkReference", "FileOperation",
    "get_logger", "setup_logging", "LogLevel", "LogTimer", "with_context",
]
```

## 5. Functional Requirements Reference

> **📋 Primary Documentation**: [FDD PD-FDD-022](../../functional-design/fdds/fdd-0-1-1-core-architecture.md)

**Key Functional Requirements Implemented**:

- FR-1 through FR-7 are implemented in `LinkWatcherService` class and `main.py` CLI
- Business rules (BR-1 through BR-5) are enforced in config loading and service startup

**Implementation Mapping**:

| Requirement | Technical Component | Implementation |
|-------------|-------------------|----------------|
| 0.1.1-FR-1 | LinkWatcherService.__init__() | Subsystem instantiation and wiring |
| 0.1.1-FR-2 | LinkWatcherService._initial_scan() | os.walk + parser + database |
| 0.1.1-FR-3 | Observer + handler | Watchdog daemon thread |
| 0.1.1-FR-5 | LinkWatcherService._signal_handler() | signal.signal registration |
| 0.1.1-FR-7 | __init__.py __all__ | Package-level re-exports |
| 0.1.1-FR-8 | main.py lock file logic | PID-based lock file in project root |

## 6. API Specification Reference

No external API — this is an internal service component. The public API surface is the Python package API documented in Section 4.3.

## 7. Database Schema Reference

No database schema — link storage uses an in-memory `Dict[str, List[LinkReference]]` (see 0.1.3 In-Memory Database). State is ephemeral and rebuilt on every startup.

## 8. Quality Attribute Implementation

### 8.1 Performance Implementation

**Startup Optimization**:
- `os.walk()` with in-place `dirs[:]` mutation for directory pruning (avoids descending into excluded dirs)
- File extension check before parsing (avoids parsing non-monitored files)

**Runtime Efficiency**:
- Observer daemon thread handles events asynchronously
- Main thread polling loop (`time.sleep(1)`) has minimal CPU footprint
- Database uses `Dict[str, List]` for O(1) target-path lookups during event processing

### 8.2 Security Implementation

**Path Safety**:
- All file paths normalized through `normalize_path()` (Path Utilities, part of 0.1.1)
- Project directory boundary enforced — service only operates within configured path
- No network access or external service calls

**Process Safety**:
- Signal handler only sets a boolean flag (no complex logic in signal context)
- `try/finally` ensures cleanup runs even on unexpected exceptions

### 8.3 Reliability Implementation

**Error Isolation**:
- Individual file parse errors logged and skipped (scan continues)
- Individual file update errors logged and skipped (monitoring continues)
- Observer thread failures caught in main loop

**Thread Management**:
- Observer runs as daemon thread (auto-terminates if main thread dies)
- `observer.join()` ensures clean thread termination during shutdown
- `try/finally` block guarantees `stop()` is called

### 8.4 Usability Implementation

**CLI Design**:
- Standard `argparse` with `--help` auto-generation
- Sensible defaults (current directory, no dry-run, scan enabled)
- Multiple startup scripts for different environments (`.bat`, `.ps1`, `.sh`, `.py`)

## 9. Quality Measurement

### 9.1 Performance Monitoring

- `LogTimer` context manager available for timing critical operations
- Statistics tracking built into service (files scanned, links found, updates performed)
- Displayed automatically on shutdown

### 9.2 Reliability Monitoring

- All errors logged via structured logging framework (3.1.1)
- Exception handlers prevent service crashes on individual file errors
- Clean shutdown verified by "LinkWatcher stopped" log message

## 10. Testing Reference

**Testability Design**:
- Constructor injection: all subsystems created in `__init__()` can be mocked
- Service methods are independently testable (`_initial_scan`, `start`, `stop`)
- No global state — each `LinkWatcherService` instance is independent

**Existing Test Coverage**:
- `test/automated/unit/test_service.py`: Unit tests for service lifecycle
- `test/automated/integration/test_service_integration.py`: End-to-end service tests
- `test/automated/unit/test_comprehensive_file_monitoring.py`: File monitoring integration
- Multiple integration tests exercise the full service pipeline

## 11. Implementation Plan

**Status**: Fully implemented (retrospective documentation).

### 11.1 Dependencies

All dependencies are implemented and operational:
- Data Models (part of 0.1.1) ✅
- 0.1.2 In-Memory Database ✅
- 0.1.3 Configuration System ✅
- Path Utilities (part of 0.1.1) ✅
- 1.1.1 Event Handler (includes Watchdog integration) ✅
- 2.1.1 Parser Framework ✅
- 2.2.1 Link Updater ✅
- 3.1.1 Logging Framework ✅

### 11.2 Key Source Files

| File | Purpose | LOC (approx) |
|------|---------|---------------|
| `linkwatcher/service.py` | LinkWatcherService class | ~200 |
| `linkwatcher/__init__.py` | Package public API | ~30 |
| `linkwatcher/models.py` | LinkReference and FileOperation data classes | ~30 |
| `linkwatcher/utils.py` | Path utilities (normalize, relative path, file filtering) | ~260 |
| `main.py` | CLI entry point | ~80 |

## 12. Open Questions

No open questions — feature is fully implemented and operational.

## 13. AI Agent Session Handoff Notes

### Current Status

Fully implemented and in production use. Retrospective documentation created during PF-TSK-066.

### Key Decisions

1. **Orchestrator/Facade Pattern**: Service coordinates subsystems without implementing business logic — confirmed as correct architectural choice through code analysis
2. **Signal Handler Registration at Service Level**: Service owns observer lifecycle, so it handles shutdown signals — avoids coupling main.py to observer internals
3. **Lazy Observer Creation**: Observer created in `start()`, not `__init__()`, enabling config changes between construction and startup

### Known Issues

- Signal handling is Unix-style (SIGINT/SIGTERM) — Windows support relies on Python's signal emulation
- Hard-coded extension/directory lists in handler (not from config) — technical debt identified in 1.1.1 (File Filtering)

---

_Retrospective Technical Design Document — documents existing implementation as of 2026-02-19._
