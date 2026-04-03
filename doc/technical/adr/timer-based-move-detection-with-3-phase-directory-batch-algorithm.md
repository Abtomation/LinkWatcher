---
id: PD-ADR-041
type: Product Documentation
category: Architecture Decision Records
version: 1.0
created: 2026-03-27
updated: 2026-03-27
feature_id: 1.1.1
feature_name: File System Monitoring
retrospective: true
---

# ADR-041: Timer-Based Move Detection with 3-Phase Directory Batch Algorithm

> **Retrospective ADR**: These decisions were made during original implementation (pre-framework) and documented retroactively to resolve TD063. Content is reverse-engineered from source code analysis of `linkwatcher/move_detector.py` and `linkwatcher/dir_move_detector.py`.

*Created: 2026-03-27*
*Last updated: 2026-03-27*

## Status

**Accepted** (retrospective — design confirmed in production code)

## Context

LinkWatcher must detect file and directory moves in real-time to update all references across a project. On Windows, the `watchdog` library does not reliably emit native `FileMovedEvent` or `DirMovedEvent` events. Instead, file moves are reported as separate `file_deleted` and `file_created` events, and directory moves are reported as a single `directory_deleted` event followed by N individual `file_created` events for each file that was inside the directory.

Three design tensions shaped the move detection architecture:

1. **Event fragmentation**: A single user action (moving a file or directory) produces multiple discrete filesystem events with no built-in correlation. The system must reconstruct the user's intent from these fragments.

2. **Timing uncertainty**: The delay between delete and create events varies based on filesystem speed, directory size, and system load. Events may arrive milliseconds apart or seconds apart. There is no signal indicating "all events for this operation are complete."

3. **Scale asymmetry**: A single-file move produces exactly 2 events (1 delete + 1 create), but a directory move with 100 files produces 101 events (1 dir delete + 100 file creates). The detection algorithm must handle both efficiently without blocking the watchdog event thread.

The key architectural question: **How should fragmented filesystem events be correlated into logical move operations, and how should the system decide when correlation is complete?**

## Decision

Three tightly coupled design decisions implement move detection across two modules:

### 1. Delete+Create Correlation for File Moves (`MoveDetector`)

Individual file moves are detected by buffering delete events and matching them against subsequent create events. A match is confirmed when:

- The created file has the **same filename** (basename) as a pending delete
- The created file has the **same file size** (or the delete's size was unavailable)
- The match occurs within the **configurable delay window** (default: 10 seconds)

```python
# Matching logic in match_created_file():
if os.path.basename(deleted_path) == created_filename:
    if delete_size == 0 or created_size == delete_size:
        return deleted_path  # Move confirmed
```

Each pending delete has a **per-path timer**. If no matching create arrives before the timer expires, the delete is confirmed as a true deletion and forwarded to the deletion callback.

### 2. 3-Phase Batch Detection for Directory Moves (`DirectoryMoveDetector`)

Directory moves use a stateful 3-phase algorithm that processes the stream of file_created events as a batch:

**Phase 1 — Buffer**: When a `directory_deleted` event arrives, snapshot all files known to the link database under that directory. Store them in a `_PendingDirMove` object and start the max timeout timer.

**Phase 2 — Match**: As `file_created` events arrive, correlate them with the pending directory:
- **First match**: Infer the new directory location by comparing the created file's path structure against known old paths. This establishes `pending.new_dir`.
- **Subsequent matches**: Verify created files by checking if their path starts with the inferred `new_dir` prefix. On each match, reset the settle timer.

**Phase 3 — Process**: Triggered when either (a) all expected files are matched, (b) the settle timer fires (no new matches for `settle_delay` seconds), or (c) the max timeout fires. The directory move callback is invoked, and any unmatched files are verified against the filesystem — files found at the new location are accepted, files still at the old location are flagged, and truly missing files are treated as deletions.

### 3. Dual-Timer Strategy

The two detectors use different timer strategies appropriate to their complexity:

**`MoveDetector` — Single expiry timer per path**:
- One `threading.Timer` per pending delete (default: 10s)
- Simple timeout: if no match arrives, confirm as true delete
- Timer is cancelled when a match is found

**`DirectoryMoveDetector` — Dual timers per pending directory**:
- **Max timeout** (default: 300s): Safety net ensuring the pending state is always cleaned up, even for very large directories
- **Settle timer** (default: 5s): Reset on each file match, fires when the stream of matching creates stops arriving. This provides adaptive completion — the system doesn't wait the full max timeout but also doesn't declare completion prematurely if files are still arriving

```
Timeline for directory move of 50 files:
  t=0s     dir_deleted event → Phase 1: buffer, start max_timer(300s)
  t=0.1s   file_created #1 → Phase 2: infer new_dir, start settle_timer(5s)
  t=0.2s   file_created #2 → reset settle_timer(5s)
  ...
  t=2.5s   file_created #50 → all matched → Phase 3: process immediately

Partial match scenario (5 of 50 files):
  t=0s     dir_deleted → buffer, max_timer(300s)
  t=0.1s   file_created #1 → infer new_dir, settle_timer(5s)
  ...
  t=0.5s   file_created #5 → reset settle_timer(5s)
  t=5.5s   settle_timer fires → Phase 3: process with 5 matched, 45 unmatched
```

## Impact Assessment

| Area | Impact | Notes |
|------|--------|-------|
| Technical risk | Low | Timer-based approach is well-understood; thread safety via single lock per detector |
| Implementation effort | Medium | Two separate but coordinated modules; dual-timer logic adds complexity |
| Affected components | `move_detector.py`, `dir_move_detector.py`, `handler.py` (orchestration) | Handler routes events to the appropriate detector |
| Performance impact | Low | Timers are lightweight; matching is O(n) over pending deletes (typically small) |
| Memory impact | Low | Pending state is bounded by active move operations (typically 0-2 concurrent) |

## Consequences

### Positive

- **Reliable move detection on Windows**: Works around watchdog's inability to emit native move events on Windows NTFS/ReFS
- **No filesystem polling**: Pure event-driven with timers only as timeouts, not polling intervals
- **Graceful degradation**: Partial directory matches are processed with unmatched files verified against filesystem
- **Configurable timing**: All delays are parameterized (`delay`, `max_timeout`, `settle_delay`), allowing tuning for different project sizes and filesystem speeds
- **Thread-safe**: Both detectors use `threading.Lock` to protect shared state; timer callbacks and watchdog events can arrive concurrently
- **Non-blocking**: Directory move processing runs on a separate daemon thread to avoid blocking the watchdog event thread

### Negative

- **Inherent race window**: If a file is genuinely deleted and a new file with the same name/size is created within the delay window, it will be misidentified as a move. The 10s default is a practical trade-off
- **Timer resource usage**: Each pending delete spawns a `threading.Timer` thread. Under pathological conditions (mass deletion), this could create many timer threads, though they are short-lived and daemon
- **First-match inference**: The directory move algorithm infers `new_dir` from the first matching file. If that file is a false positive, the entire directory move detection could be wrong. Filename + path structure matching mitigates this
- **No cross-directory-move deduplication**: If a file moves between two directories that are both being tracked as pending moves, the first detector to match claims the file

## Alternatives

### Alternative 1: Watchdog Native Move Events Only

**Description**: Rely solely on watchdog's `FileMovedEvent` / `DirMovedEvent`.

**Pros**:
- Zero implementation complexity
- No timers or buffering needed

**Cons**:
- **Non-functional on Windows**: watchdog does not reliably emit move events on Windows NTFS. This is documented in watchdog's issue tracker and is the primary reason this ADR exists.
- Would require users to be on Linux/macOS with inotify/FSEvents backends

**Why not chosen**: LinkWatcher is developed and primarily used on Windows. This alternative would make the core feature non-functional on the target platform.

### Alternative 2: Global Timer with Single Event Queue

**Description**: Buffer all delete and create events in a single queue, process them all after a fixed global timeout.

**Pros**:
- Simpler implementation — one timer, one queue
- Natural batching of related events

**Cons**:
- **Latency**: Every move detection waits the full timeout regardless of whether matches are found immediately
- **Cross-contamination**: Unrelated deletes and creates in different directories would be in the same queue
- **No early completion**: Cannot process directory moves as soon as all files are matched

**Why not chosen**: The per-path timer approach provides immediate feedback when matches are found, and the settle timer provides adaptive completion for directory moves. A global timer would introduce unnecessary latency for the common case.

### Alternative 3: Filesystem Polling After Delete

**Description**: When a delete event is received, poll the filesystem to check if the file appeared elsewhere.

**Pros**:
- Would catch moves where the filename changes
- No dependency on create event timing

**Cons**:
- **Expensive**: Requires scanning potentially the entire project directory tree for each deletion
- **Ambiguous**: A file appearing at a new location could be a copy, not a move
- **Latency**: Filesystem scanning takes time proportional to project size

**Why not chosen**: Event correlation is more efficient and provides higher confidence that a delete+create pair represents a single move operation.

### Alternative 4: Fixed Timeout for Directory Moves (No Settle Timer)

**Description**: Use only the max timeout timer for directory moves, without the adaptive settle timer.

**Pros**:
- Simpler timer logic
- Predictable completion time

**Cons**:
- **Wastes time**: For a 10-file directory move that completes in 0.5s, the system would wait the full max timeout (300s) before processing
- **No adaptive behavior**: Cannot distinguish between "still receiving files" and "done receiving files"

**Why not chosen**: The settle timer provides adaptive completion — processing happens within seconds of the last file arriving, rather than waiting the full max timeout. This is critical for user experience, as link updates should happen promptly after the move completes.

## References

- `linkwatcher/move_detector.py` — Per-file move detection implementation
- `linkwatcher/dir_move_detector.py` — Directory batch move detection implementation
- `linkwatcher/handler.py` — Event routing and orchestration between detectors
- [TDD: File System Monitoring (PD-TDD-023)](/doc/technical/tdd/tdd-1-1-1-file-system-monitoring-t2.md) — Technical design for the overall monitoring system
- [FDD: File System Monitoring (PD-FDD-024)](/doc/functional-design/fdds/fdd-1-1-1-file-system-monitoring.md) — Functional design for file system monitoring
- [Validation: Architectural Consistency R2 Batch A (PD-VAL-046)](/doc/validation/reports/architectural-consistency/PD-VAL-046-architectural-consistency-features-0.1.1-0.1.2-0.1.3-1.1.1.md) — Validation report that identified TD063
