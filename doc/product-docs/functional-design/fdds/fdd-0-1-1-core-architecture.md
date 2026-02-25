---
id: PD-FDD-022
type: Process Framework
category: Functional Design Document
version: 1.0
created: 2026-02-19
updated: 2026-02-25
feature_id: 0.1.1
feature_name: Core Architecture
consolidates: [0.1.1, 0.1.2 (Data Models), 0.1.5 (Path Utilities)]
retrospective: true
---

# Core Architecture - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher Core Architecture, documented after implementation during framework onboarding (PF-TSK-066). Content is descriptive ("what is") rather than prescriptive ("what should be").
>
> **Source**: Derived from [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md) and source code analysis of `linkwatcher/service.py`, `linkwatcher/__init__.py`, `linkwatcher/models.py`, `linkwatcher/utils.py`, and `main.py`.
>
> **Scope Note**: This feature consolidates old 0.1.1 (Core Architecture), 0.1.2 (Data Models), and 0.1.5 (Path Utilities) into a single feature covering the service orchestrator, data models, path utilities, and CLI entry point.

## Feature Overview

- **Feature ID**: 0.1.1
- **Feature Name**: Core Architecture
- **Business Value**: Provides a self-contained, configurable service that starts with a single command and runs unattended, automatically maintaining link integrity when files are moved or renamed. Eliminates manual effort of finding and updating broken references across a project.
- **User Story**: As a developer, I want a background service that monitors my project for file moves and automatically updates all references, so that my documentation links and import paths stay valid without manual intervention.

## Related Documentation

### Architecture Overview Reference

> **📋 Primary Documentation**: [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md)
> **👤 Source**: Pre-framework project documentation (Confirmed in PF-TSK-065 analysis)
>
> **Purpose**: Comprehensive architecture overview covering the modular component design, data flow, and operational phases.

**Functional Architecture Summary**:

- The system uses a service-oriented, modular architecture with clear separation between file monitoring, link parsing, in-memory storage, and file updating
- `LinkWatcherService` acts as the sole orchestrator, coordinating all subsystems without implementing their business logic
- Two operational phases: initial scan (build link database) and continuous monitoring (detect and respond to changes)

### Technical Design Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-015)
> **🔗 Link**: [TDD to be created as part of PF-TSK-066]
>
> **Purpose**: Detailed component architecture, design patterns (Orchestrator/Facade), and implementation decisions.

**Functional Technical Requirements**:

- Service startup must complete initial scan before entering monitoring mode
- File system events must be processed in near-real-time (sub-second detection)
- Graceful shutdown must cleanly terminate all background threads without data loss

## Functional Requirements

### Core Functionality

- **0.1.1-FR-1**: The system SHALL provide a single entry point (`LinkWatcherService`) that orchestrates all subsystems (database, parser, updater, handler, observer) through their full lifecycle
- **0.1.1-FR-2**: The system SHALL perform an initial recursive scan of the project directory on startup to build an in-memory database of all file references
- **0.1.1-FR-3**: The system SHALL continuously monitor the project directory for file system events (move, create, delete, rename) after initial scan completes
- **0.1.1-FR-4**: The system SHALL automatically update all references in other files when a monitored file is moved or renamed
- **0.1.1-FR-5**: The system SHALL handle graceful shutdown on SIGINT (Ctrl+C) and SIGTERM signals, stopping the file observer thread cleanly
- **0.1.1-FR-8**: The system SHALL prevent multiple instances from running simultaneously on the same project by acquiring a lock file at startup and releasing it on shutdown. If another instance is already running, the system SHALL exit with an informative error message.
- **0.1.1-FR-6**: The system SHALL report operational statistics upon shutdown (files scanned, links found, updates performed)
- **0.1.1-FR-7**: The system SHALL provide a public Python API via `import linkwatcher` that re-exports all major classes (`LinkWatcherService`, `LinkDatabase`, `LinkParser`, `LinkUpdater`)

### User Interactions

- **0.1.1-UI-1**: Users interact with LinkWatcher through the CLI entry point (`python main.py`) which accepts arguments for project path, configuration file, log level, and operational flags (dry-run, backup)
- **0.1.1-UI-2**: Users receive colored console output showing scan progress, detected file moves, link updates performed, and any errors encountered
- **0.1.1-UI-3**: Users terminate the service by pressing Ctrl+C, which triggers graceful shutdown with a summary of operations performed
- **0.1.1-UI-4**: Users can configure behavior through YAML/JSON config files, environment variables, or CLI flags (multi-source configuration loading with priority: CLI > env > file > defaults)

### Business Rules

- **0.1.1-BR-1**: Configuration loading follows strict priority: CLI arguments override environment variables, which override config file values, which override built-in defaults
- **0.1.1-BR-2**: Initial scan is optional (controlled by `initial_scan` config flag, default: True) — when disabled, the service starts monitoring immediately without building the initial link database
- **0.1.1-BR-3**: Only files with monitored extensions (`.md`, `.yaml`, `.yml`, `.json`, `.py`, `.dart`) are processed during scan and monitoring; all others are ignored
- **0.1.1-BR-4**: Directories listed in the exclusion list (`.git`, `__pycache__`, `node_modules`, etc.) are skipped during both scan and monitoring
- **0.1.1-BR-5**: The service runs as a foreground blocking process (via `while self.running: time.sleep(1)` loop) — background execution requires external process management (e.g., startup scripts)

## User Experience Flow

1. **Entry Point**: User runs `python main.py [options]` or uses a startup script (`start_linkwatcher.bat`, `start_linkwatcher.ps1`, etc.)
2. **Configuration**: Service loads configuration from multiple sources (CLI flags, environment variables, config file, defaults) and validates parameters
3. **Initial Scan**: Service recursively walks the project directory, parsing all monitored files and building the in-memory link database. Progress is reported to console.
4. **Monitoring Active**: Service enters continuous monitoring mode. Console displays "Watching for changes..." message. File system events are processed automatically.
5. **File Move Detected**: When a file is moved/renamed:
   - Event handler detects the move via watchdog
   - Database lookup finds all files referencing the moved file
   - Link updater modifies each referencing file with the new path
   - Console displays what was updated
6. **Shutdown**: User presses Ctrl+C → signal handler sets `running = False` → observer thread is stopped and joined → final statistics displayed → process exits cleanly

## Acceptance Criteria

- [x] **0.1.1-AC-1**: Service starts successfully with default configuration and begins monitoring
- [x] **0.1.1-AC-2**: Initial scan processes all files with monitored extensions and populates the link database
- [x] **0.1.1-AC-3**: Moving a file triggers automatic detection and update of all references within sub-second timeframe
- [x] **0.1.1-AC-4**: Ctrl+C triggers graceful shutdown without orphaned threads or processes
- [x] **0.1.1-AC-5**: Service accepts configuration from CLI arguments, environment variables, and config files with correct priority ordering
- [x] **0.1.1-AC-6**: Public API (`import linkwatcher`) provides access to all major classes
- [x] **0.1.1-AC-7**: Operational statistics are displayed on shutdown showing scan/update metrics

> **Note**: All acceptance criteria are checked as this is a retrospective document — the feature is fully implemented and operational.

## Edge Cases & Error Handling

- **0.1.1-EC-1**: If the project directory does not exist, the service logs an error and exits gracefully
- **0.1.1-EC-2**: If a file move occurs during initial scan, the event is queued and processed after scan completion
- **0.1.1-EC-3**: If a referenced file cannot be updated (permission error, locked file), the error is logged and the service continues monitoring other files
- **0.1.1-EC-4**: If the watchdog observer fails to start, the service logs the error and exits
- **0.1.1-EC-5**: Rapid successive file operations (e.g., IDE rename) use a 2-second pending-delete timer to correctly detect moves vs. separate create/delete events
- **0.1.1-EC-6**: If configuration file is malformed or missing, the service falls back to default configuration values
- **0.1.1-EC-7**: If a stale lock file exists (PID no longer running), the service overrides it and acquires the lock
- **0.1.1-EC-8**: If the lock file cannot be created (permissions, read-only filesystem), the service logs a warning and starts without duplicate protection

## Dependencies

### Internal Components (consolidated into this feature)

- **Data Models** (formerly 0.1.2): LinkReference and FileOperation data classes for representing links and file events — `models.py`
- **Path Utilities** (formerly 0.1.5): Windows-native path normalization, file monitoring filters, safe file reading — `utils.py`

### Functional Dependencies

- **0.1.2 In-Memory Link Database**: Thread-safe storage for link references with O(1) target-path lookups
- **0.1.3 Configuration System**: Multi-source configuration loading and validation
- **1.1.1 File System Monitoring**: File system event monitoring, move detection, file filtering
- **2.1.1 Link Parsing System**: Multi-format link extraction from source files
- **2.2.1 Link Updating**: Atomic file modification with safety mechanisms
- **3.1.1 Logging System**: Structured logging with colored console output

### Technical Dependencies

- **watchdog** (>=2.0): File system event monitoring library
- **colorama** (>=0.4): Cross-platform colored terminal output
- **gitpython** (>=3.0, optional): Git repository detection for `.gitignore` support
- **Python** (>=3.8): Runtime environment

## Success Metrics

- Service starts reliably on all supported platforms (Windows primary, Linux/macOS secondary)
- File moves are detected and references updated within seconds
- Graceful shutdown leaves no orphaned background threads
- Zero data loss during normal operation (all link updates applied atomically)
- Users can configure and start the service with a single command

## Validation Checklist

- [x] All functional requirements clearly defined with Feature ID prefixes (0.1.1-FR-1 through 0.1.1-FR-7)
- [x] User interactions documented with specific UI behaviors (0.1.1-UI-1 through 0.1.1-UI-4)
- [x] Business rules specified with validation logic (0.1.1-BR-1 through 0.1.1-BR-5)
- [x] Acceptance criteria are testable and measurable (0.1.1-AC-1 through 0.1.1-AC-7)
- [x] Edge cases identified with expected behaviors (0.1.1-EC-1 through 0.1.1-EC-6)
- [x] Dependencies mapped (both functional and technical)
- [x] Success metrics defined for measuring feature effectiveness
- [x] User experience flow covers all major paths and decision points

---

_Retrospective Functional Design Document — documents existing implementation as of 2026-02-19._
