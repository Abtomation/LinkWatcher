---
id: PD-ADR-039
type: Product Documentation
category: Architecture Decision Records
version: 1.0
created: 2026-02-19
updated: 2026-02-19
feature_id: 0.1.1
feature_name: Core Architecture
retrospective: true
---

# ADR-039: Orchestrator/Facade Pattern for Core Architecture

> **Retrospective ADR**: This decision was made during original implementation (pre-framework) and documented retroactively during framework onboarding (PF-TSK-066). Content is reverse-engineered from source code analysis of `linkwatcher/service.py`.

*Created: 2026-02-19*
*Last updated: 2026-02-19*

## Status

**Accepted** (retrospective — pattern confirmed in production code)

## Context

LinkWatcher requires coordination of multiple independent subsystems to deliver its core functionality:

- **File system monitoring** (watchdog Observer on daemon thread)
- **Link parsing** (multi-format parser registry)
- **Link storage** (in-memory target-indexed database)
- **Link updating** (safe file modification with backup)
- **Event handling** (file move/rename detection with timer-based batching)
- **Logging** (structured multi-output logging framework)

A central coordination point was needed to:
1. Instantiate and wire all subsystems together
2. Manage the service lifecycle (start → monitor → shutdown)
3. Handle OS signals (SIGINT/SIGTERM) for graceful shutdown
4. Provide a clean public API (`service.start()` / `service.stop()`)

The key architectural question: **Where should subsystem coordination live, and how much logic should the coordinator contain?**

## Decision

Use the **Orchestrator/Facade pattern** for `LinkWatcherService`:

- The service class coordinates all subsystems but contains **zero business logic**
- All subsystem instances are created in `__init__()` (constructor injection)
- `start()` registers signal handlers, triggers optional initial scan, creates and starts the Observer, then enters a polling loop
- `stop()` sets `self.running = False`, stops and joins the Observer thread, and prints statistics
- Signal handler (`_signal_handler`) only sets the `running` flag — no complex logic in signal context

Additionally, **signal handler registration occurs at the service level** (not in `main.py`), because the service owns the Observer lifecycle and is the appropriate place to manage shutdown.

### Key Design Choices

1. **Lazy Observer creation**: Observer is created in `start()`, not `__init__()`, enabling configuration changes between construction and startup
2. **Daemon thread for Observer**: Auto-terminates if main thread dies unexpectedly
3. **`try/finally` for cleanup**: Guarantees `stop()` runs even on unexpected exceptions
4. **Single `self.running` boolean**: Simple, thread-safe shutdown coordination

## Consequences

### Positive

- **Independent testability**: Each subsystem can be unit tested in isolation; service methods can be tested with mocked subsystems
- **Single responsibility**: `service.py` is a thin coordinator (~200 LOC) — adding capabilities means adding/modifying subsystems, not the service
- **Clean public API**: Consumers only need `LinkWatcherService(config)` → `.start()` → `.stop()`
- **Embeddable**: Service can be used as a library (via `__init__.py` exports) or as a CLI tool (via `main.py`)
- **Constructor injection**: All dependencies visible in `__init__()`, making the wiring explicit

### Negative

- **Signal handler side effect**: Service registers SIGINT/SIGTERM handlers during `start()` — callers embedding the service must be aware this overrides their own signal handling
- **Single-process limitation**: The Orchestrator pattern doesn't scale to multi-process architectures (not needed for LinkWatcher's use case)
- **No dynamic subsystem loading**: Subsystems are hardcoded in `__init__()` — adding a new subsystem requires modifying the service class

## Alternatives

### 1. Monolithic Service

All parsing, database, updating, and event handling logic in a single class.

- **Pros**: Simpler initial implementation, fewer files
- **Cons**: Untestable in isolation, violates SRP, difficult to extend, high coupling
- **Why rejected**: Would make the codebase unmaintainable as feature count grows

### 2. Event Bus / Message-Driven Architecture

Components communicate via events published to a central bus, with no direct dependencies.

- **Pros**: Maximum decoupling, easier to add new consumers
- **Cons**: Added complexity (event bus infrastructure, event types, ordering), harder to debug, overkill for a single-process file watcher tool
- **Why rejected**: Unnecessary complexity for LinkWatcher's scope — the tool runs in a single process with a small number of well-defined subsystems

### 3. Plugin Architecture

Subsystems loaded dynamically from a registry or configuration.

- **Pros**: Extensible without modifying core code
- **Cons**: Discovery complexity, configuration overhead, harder to reason about at startup
- **Why rejected**: LinkWatcher has a fixed, well-known set of subsystems — plugin overhead not justified

## References

- [0.1.1 Implementation State](../../../../../process-framework/state-tracking/features/0.1.1-core-architecture-implementation-state.md) — Source code analysis with design decisions
- [FDD PD-FDD-022](../../../../functional-design/fdds/fdd-0-1-1-core-architecture.md) — Functional requirements for Core Architecture
- [TDD PD-TDD-021](../tdd/tdd-0-1-1-core-architecture-t3.md) — Technical design document with component diagrams
- [HOW_IT_WORKS.md](../../../../../../HOW_IT_WORKS.md) — User-facing architecture overview
- `linkwatcher/service.py` — Primary implementation file (~200 LOC)
- `linkwatcher/__init__.py` — Package public API surface

---

_Retrospective Architecture Decision Record — documents pre-framework design choice confirmed through code analysis as of 2026-02-19._
