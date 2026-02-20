---
id: PD-ADR-040
type: Product Documentation
category: Architecture Decision Records
version: 1.0
created: 2026-02-19
updated: 2026-02-19
feature_id: 0.1.3
feature_name: In-Memory Database
retrospective: true
---

# ADR-040: Target-Indexed In-Memory Link Database

> **Retrospective ADR**: This decision was made during original implementation (pre-framework) and documented retroactively during framework onboarding (PF-TSK-066). Content is reverse-engineered from source code analysis of `linkwatcher/database.py`.

*Created: 2026-02-19*
*Last updated: 2026-02-19*

## Status

**Accepted** (retrospective — design confirmed in production code)

## Context

LinkWatcher must track all link references across a project and respond in real-time when files move or are renamed. When a file move event is detected, the system must answer one critical question **instantly**: *"Which files contain links to the file that just moved?"*

Three design tensions shaped the database architecture:

1. **Lookup direction**: The critical operation is target-to-sources lookup ("what files reference this moved file?"), not source-to-targets lookup ("what does this file link to?"). The index structure must optimize for the former.

2. **Concurrency**: The watchdog Observer runs on a daemon thread, while the main service thread performs initial scanning. Both access the database concurrently. Thread safety is required without excessive complexity.

3. **Path diversity**: Markdown and other formats store links in varied forms — relative paths, absolute paths, paths with `#fragment` anchors. A moved file's canonical path may not match how references were stored, so lookups must be resilient to this diversity.

The key architectural question: **How should link references be indexed, protected, and resolved?**

## Decision

Three tightly coupled design decisions implement the in-memory database (`linkwatcher/database.py`):

### 1. Target-Indexed Storage: `Dict[str, List[LinkReference]]`

Links are stored in a dictionary keyed by **target path** (the file being referenced), with values being lists of all `LinkReference` instances that point to that target:

```python
self.links: Dict[str, List[LinkReference]] = {}
```

The critical operation `get_references_to_file(target)` returns all references with O(1) dictionary lookup.

### 2. Single `threading.Lock` for All Operations

All public database methods (`add_link`, `get_references_to_file`, `update_target_path`, `remove_file_links`, `clear`, `get_stats`) acquire a single `threading.Lock` before accessing the dictionary:

```python
self._lock = threading.Lock()

def add_link(self, link: LinkReference) -> None:
    with self._lock:
        ...
```

### 3. Three-Level Path Resolution in `get_references_to_file()`

When looking up references to a moved file, the database attempts three resolution strategies in sequence:

1. **Direct match**: exact path lookup in `self.links`
2. **Anchor-stripped match**: strip `#fragment` suffix and retry (handles `file.md#section` links)
3. **Relative-to-absolute path resolution**: resolve stored relative paths against project root and retry

This handles the practical reality that parsers store links as they appear in source files (relative paths, anchored links) while lookup queries use absolute paths.

## Consequences

### Positive

- **O(1) move response**: When any file moves, all its references are found in O(1) time regardless of project size — no scanning required
- **Simple thread safety**: Single lock eliminates deadlock risk and is straightforward to reason about; event rate (human-speed file operations) never saturates the lock
- **Resilient lookups**: Three-level path resolution handles the full diversity of link storage formats without requiring parsers to normalize before storing
- **Memory-efficient**: Single structure (target-indexed only) rather than maintaining both forward and reverse indexes
- **Clean separation**: Database is a pure repository — no business logic; all consumers interact through a consistent 6-method public API

### Negative

- **Source lookup is O(n)**: Querying "what does this file link to?" requires a full scan of all values — acceptable because this pattern is never used in the core workflow
- **In-memory only**: All data is lost on service restart, requiring a fresh initial scan to rebuild the database on each run
- **No uniqueness enforcement**: Duplicate `add_link()` calls store duplicate entries — callers are responsible for avoiding redundant additions
- **Lock serialization**: All concurrent database operations serialize under one lock — if event throughput increases dramatically, per-key locking would be needed (not a current concern)

## Alternatives

### 1. Source-Indexed Storage

Dictionary keyed by source file path → list of links that file contains.

- **Pros**: O(1) lookup for "what does this file link to?"; natural for rescanning a file after modification
- **Cons**: O(n) lookup for "what references this moved file?" — the critical operation — requiring a full scan of all values
- **Why rejected**: The critical operation on file moves is reverse lookup (target→sources). Source-indexed storage would make every file move event an O(n) scan, which is unacceptable for real-time performance in large projects.

### 2. Bi-Directional Index

Maintain both target-indexed and source-indexed dictionaries simultaneously.

- **Pros**: O(1) for both lookup directions; supports future "rescan on file modify" use cases
- **Cons**: Double memory usage; complex dual-update logic in every write operation; synchronization between two structures under concurrent access
- **Why rejected**: The source-indexed lookup is never needed in the current workflow. Premature optimization that adds real complexity cost without current benefit.

### 3. Per-Key Fine-Grained Locking

Each target path entry protected by its own lock instead of one global lock.

- **Pros**: Better theoretical concurrency — multiple threads could operate on different keys simultaneously
- **Cons**: Lock ordering complexity; deadlock risk when operations touch multiple keys (e.g., `update_target_path` must lock both old and new keys); significant implementation overhead
- **Why rejected**: LinkWatcher is a single-process tool responding to human-speed file system events. The throughput of a coarse-grained single lock is more than sufficient, and the simplicity benefit is substantial.

### 4. Lock-Free Concurrent Data Structures

Use Python's `threading`-safe data types or atomic operations to avoid explicit locking.

- **Pros**: No lock contention; potentially higher throughput
- **Cons**: Python's GIL provides some safety but not the full atomicity needed for compound operations (e.g., check-then-modify); complex to implement correctly; overkill for this use case
- **Why rejected**: The GIL does not protect compound operations. A single explicit lock is simpler, provably correct, and sufficient for the event rate.

### 5. Single-Pass Lookup (No Multi-Level Resolution)

Require all stored paths to be normalized before insertion; accept only exact-match lookups.

- **Pros**: Simpler lookup logic; predictable O(1) with no fallback cost
- **Cons**: Requires all parsers to normalize paths consistently before calling `add_link()`; breaks when parsers store links as they appear in source files (relative, anchored); would require coordinated changes across all 7 parser implementations
- **Why rejected**: Parsers are designed to extract links as-is from source files. Shifting normalization responsibility to parsers would add complexity to each parser and create a fragile contract. The three-level resolution in the database is a better encapsulation of this concern.

## References

- [0.1.3 Implementation State](../../../../../process-framework/state-tracking/features/0.1.3-in-memory-database-implementation-state.md) — Source code analysis with design decisions
- [FDD PD-FDD-023](../../../../functional-design/fdds/fdd-0-1-3-in-memory-database.md) — Functional requirements for In-Memory Database
- [TDD PD-TDD-022](../tdd/tdd-0.1.3-in-memory-database-t2.md) — Technical design document with implementation details
- [HOW_IT_WORKS.md](../../../../../../HOW_IT_WORKS.md) — User-facing architecture overview (Database System section)
- `linkwatcher/database.py` — Primary implementation file

---

_Retrospective Architecture Decision Record — documents pre-framework design choices confirmed through code analysis as of 2026-02-19._
