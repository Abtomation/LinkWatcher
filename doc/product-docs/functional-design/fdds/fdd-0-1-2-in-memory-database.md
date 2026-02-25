---
id: PD-FDD-023
type: Process Framework
category: Functional Design Document
version: 1.0
created: 2026-02-19
updated: 2026-02-20
feature_id: 0.1.2
feature_name: In-Memory Link Database
note: "Was feature 0.1.3, renumbered to 0.1.2 during consolidation"
retrospective: true
---

# In-Memory Database - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher In-Memory Database, documented after implementation during framework onboarding (PF-TSK-066). Content is descriptive ("what is") rather than prescriptive ("what should be").
>
> **Source**: Derived from [0.1.3 Implementation State](../../../process-framework/state-tracking/features/0.1.3-in-memory-database-implementation-state.md), [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md) (Database System section), and source code analysis of `linkwatcher/database.py`.

## Feature Overview

- **Feature ID**: 0.1.3
- **Feature Name**: In-Memory Database
- **Business Value**: Provides instant lookup of all files that reference a given file when that file moves or is renamed, enabling real-time link maintenance without scanning the entire project each time. Eliminates the performance bottleneck that would exist with file-by-file searching.
- **User Story**: As a developer, I want the system to instantly find all files that reference a moved file (in sub-millisecond time), so that link updates happen immediately without noticeable delay, even in large projects with thousands of files.

## Related Documentation

### Architecture Overview Reference

> **📋 Primary Documentation**: [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md) - Database System section
> **👤 Source**: Pre-framework project documentation (Confirmed in PF-TSK-065 analysis)
>
> **Purpose**: Overview of database structure, key features, and operational behavior.

**Functional Architecture Summary** (derived from HOW_IT_WORKS.md):

- The database uses target-indexed storage: `Dict[str, List[LinkReference]]` where keys are target file paths and values are lists of all references to that target
- Provides O(1) lookup performance for the critical operation: "given a moved file, find all files that reference it"
- Thread-safe design supports concurrent access from watchdog observer thread and main service thread
- Handles path normalization and anchor support (links with `#fragment` suffixes) transparently

### Technical Design Reference

> **📋 Primary Documentation**: TDD Creation Task (PF-TSK-015)
> **🔗 Link**: [TDD to be created as part of PF-TSK-066]
>
> **Purpose**: Detailed technical implementation of `LinkDatabase` class, thread-safety mechanisms (single `threading.Lock`), and three-level path resolution algorithm.

**Functional Technical Requirements**:

- Database operations must complete in O(1) time for target path lookups
- Thread safety must prevent data corruption when accessed concurrently from multiple threads
- Path lookups must succeed regardless of whether links were stored with anchors, as relative paths, or as absolute paths

## Functional Requirements

### Core Functionality

- **0.1.3-FR-1**: The system SHALL store all discovered `LinkReference` instances in an in-memory database indexed by their target file path, enabling instant reverse lookup
- **0.1.3-FR-2**: The system SHALL provide O(1) lookup time for finding all files that reference a given target file path
- **0.1.3-FR-3**: The system SHALL handle concurrent access safely when the watchdog observer thread and main service thread access the database simultaneously
- **0.1.3-FR-4**: The system SHALL update all stored references when a file is moved, changing the target path in all affected `LinkReference` instances
- **0.1.3-FR-5**: The system SHALL remove all references from a source file when that file is deleted or its content is rescanned
- **0.1.3-FR-6**: The system SHALL normalize paths consistently to ensure lookups succeed regardless of how the path was originally stored
- **0.1.3-FR-7**: The system SHALL provide database statistics (total links count, total unique targets) for operational reporting

### User Interactions

- **0.1.3-UI-1**: Users do not interact directly with the database — it operates transparently in the background
- **0.1.3-UI-2**: Users see the effect of the database through instant link updates when files are moved (sub-second response time enabled by O(1) lookups)
- **0.1.3-UI-3**: Users receive database statistics on shutdown showing how many links were tracked: "Total links in database: 1,234 | Total unique targets: 567"
- **0.1.3-UI-4**: Users experience reliable operation even in concurrent scenarios (file scanning while new file events arrive) due to thread-safe implementation

### Business Rules

- **0.1.3-BR-1**: Link storage is indexed by target path (not source path), optimizing for the critical operation: "what files reference this moved file?"
- **0.1.3-BR-2**: Path lookups use three-level resolution: (1) exact match, (2) anchor-stripped match (for `file.md#section` links), (3) relative-to-absolute path resolution
- **0.1.3-BR-3**: The database is in-memory only — all data is lost on service restart, requiring a fresh initial scan to rebuild the database
- **0.1.3-BR-4**: Each target path maps to a list of `LinkReference` instances — multiple files can reference the same target, and each reference is tracked separately
- **0.1.3-BR-5**: Path normalization uses the database's own `_normalize_path()` method (independent of `linkwatcher/utils.py`) to ensure consistent key comparison

## User Experience Flow

1. **Initial Scan**: During startup, the service walks all project files, extracts links, and calls `database.add_link()` for each discovered `LinkReference`. Users see scan progress messages while this builds the database.

2. **Database Population**: Each call to `add_link()` stores the `LinkReference` in a list keyed by its target path. Users are not aware of this internal operation.

3. **File Move Event**: When a file is moved/renamed:
   - Service calls `database.get_references_to_file(old_path)` → returns all files that reference the moved file in O(1) time
   - Users see: "Found 5 files referencing [old_path]"
   - Service calls `database.update_target_path(old_path, new_path)` → bulk-updates all references
   - Users see: "Updated [moved file]: src/docs/guide.md → src/help/guide.md"

4. **File Deletion Event**: When a file is deleted:
   - Service calls `database.get_references_to_file(deleted_path)` → finds all broken links
   - Users see: "Warning: 3 files still reference deleted file [path]"
   - Service calls `database.remove_file_links(source_file)` for cleanup

5. **Shutdown**: Service calls `database.get_stats()` and displays: "Database statistics: 1,234 links to 567 unique files"

## Acceptance Criteria

- [x] **0.1.3-AC-1**: Database provides O(1) lookup time for target path queries (confirmed via unit tests with 10,000+ links)
- [x] **0.1.3-AC-2**: Concurrent access from multiple threads does not corrupt data (tested with simultaneous add/query operations)
- [x] **0.1.3-AC-3**: Moving a file triggers `update_target_path()` which correctly updates all references in the database
- [x] **0.1.3-AC-4**: Path lookups succeed for links stored with anchors (e.g., `file.md#section`) when queried without anchors
- [x] **0.1.3-AC-5**: Path lookups succeed for relative paths that are queried as absolute paths (and vice versa)
- [x] **0.1.3-AC-6**: Database statistics accurately reflect the count of total links and unique target files
- [x] **0.1.3-AC-7**: Data is cleared when `clear()` is called, resetting the database to empty state

> **Note**: All acceptance criteria are checked as this is a retrospective document — the feature is fully implemented and operational.

## Edge Cases & Error Handling

- **0.1.3-EC-1**: If a path is queried that has no references, `get_references_to_file()` returns an empty list (not an error)
- **0.1.3-EC-2**: If `update_target_path()` is called for a target with no references, the operation completes silently (no error, no effect)
- **0.1.3-EC-3**: If the same `LinkReference` is added multiple times (duplicate calls), each is stored separately as the database does not enforce uniqueness
- **0.1.3-EC-4**: If concurrent threads access the database simultaneously, the single `threading.Lock` serializes operations, preventing race conditions
- **0.1.3-EC-5**: If path normalization fails (malformed path), the path is stored as-is and may not match during lookups — this is handled by the three-level resolution strategy
- **0.1.3-EC-6**: If the database grows very large (tens of thousands of links), lookup remains O(1) but memory usage increases linearly (in-memory only, no paging)

## Dependencies

### Functional Dependencies

- **0.1.2 Data Models**: Requires `LinkReference` dataclass to represent individual links stored in the database
- **3.1.1 Logging Framework**: Uses logging to report database operations (add, update, query)

### Technical Dependencies

- **threading** (stdlib): `threading.Lock()` for thread-safe access
- **pathlib** (stdlib): `Path` for path normalization in `_normalize_path()`
- **typing** (stdlib): `Dict`, `List`, `Optional` for type hints
- **Python** (>=3.8): Runtime environment with dictionary ordering guarantees

## Success Metrics

- Lookup performance remains O(1) even with thousands of references (target: sub-millisecond lookups)
- Zero data corruption under concurrent access (verified through multi-threaded integration tests)
- Database accurately tracks all links discovered during initial scan (confirmed by comparing scan output with database stats)
- Memory footprint remains reasonable for typical projects (target: <100MB for projects with 10,000 files)

## Validation Checklist

- [x] All functional requirements clearly defined with Feature ID prefixes (0.1.3-FR-1 through 0.1.3-FR-7)
- [x] User interactions documented (users experience database effects indirectly through fast link updates and statistics)
- [x] Business rules specified (target-indexed storage, three-level path resolution, in-memory only, path normalization)
- [x] Acceptance criteria are testable and measurable (0.1.3-AC-1 through 0.1.3-AC-7)
- [x] Edge cases identified with expected behaviors (0.1.3-EC-1 through 0.1.3-EC-6)
- [x] Dependencies mapped (functional: Data Models, Logging Framework; technical: stdlib threading/pathlib/typing)
- [x] Success metrics defined (O(1) performance, thread safety, accuracy, memory footprint)
- [x] User experience flow covers database lifecycle (population during scan, querying during file events, stats on shutdown)

---

_Retrospective Functional Design Document — documents existing implementation as of 2026-02-19._
