---
id: PD-FDD-027
type: Product Documentation
category: Functional Design Document
version: 1.0
created: 2026-02-19
updated: 2026-02-20
feature_id: 2.2.1
feature_name: Link Updating
consolidates: [2.2.1, 2.2.2 (Relative Path Calculation), 2.2.3 (Anchor Preservation), 2.2.4 (Dry Run Mode), 2.2.5 (Backup Creation)]
retrospective: true
---

# Link Updater - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher Link Updater, documented after implementation during framework onboarding (PF-TSK-066). Content is descriptive ("what is") rather than prescriptive ("what should be").
>
> **Source**: Derived from [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md) (Link Update Process section) and source code analysis of `linkwatcher/updater.py`.
>
> **Scope Note**: This feature consolidates old 2.2.1 (Link Updater) with all update sub-features: 2.2.2 (Relative Path Calculation), 2.2.3 (Anchor Preservation), 2.2.4 (Dry Run Mode), 2.2.5 (Backup Creation). All are implementation details of the unified updater.

## Feature Overview

- **Feature ID**: 2.2.1
- **Feature Name**: Link Updater
- **Business Value**: Ensures that when files move, all documents referencing them are updated atomically and safely without data loss. Provides the critical "write" half of the LinkWatcher system — parsers find references, the updater fixes them.
- **User Story**: As a developer using LinkWatcher, I want all file references to be automatically and safely updated when I move a file so that I never have broken links in my project.

## Related Documentation

### Architecture Overview Reference

> **Primary Documentation**: [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md) — Link Update Process section
> **Source**: Pre-framework project documentation (Confirmed in PF-TSK-065 analysis)
>
> **Purpose**: Overview of the atomic update pipeline, safety mechanisms, and link-type dispatch.

**Functional Architecture Summary** (derived from HOW_IT_WORKS.md):

- The Link Updater receives a list of `LinkReference` objects and old/new file paths, groups them by containing file, and processes each file with bottom-to-top replacement to preserve position validity
- Atomic writes via temp file + `shutil.move()` ensure no data loss on interruption
- Two safety flags — `dry_run` and `backup_enabled` — allow users to preview changes or create safety copies

### Technical Design Reference

> **Link**: [TDD PD-TDD-026](../../technical/architecture/design-docs/tdd/tdd-2-2-1-link-updater-t2.md) (to be created)
>
> **Purpose**: Detailed technical design of the bottom-to-top sort, link-type dispatch, atomic write mechanism, and statistics tracking.

## Functional Requirements

### Core Functionality

- **2.2.1-FR-1**: The system SHALL update all file references in a single pass per containing file, given a list of `LinkReference` objects and old/new file paths
- **2.2.1-FR-2**: The system SHALL group references by containing file and process each file independently, reading content once and writing once
- **2.2.1-FR-3**: The system SHALL sort references in descending `(line_number, column_start)` order before applying replacements, ensuring earlier positions remain valid
- **2.2.1-FR-4**: The system SHALL compute new targets via `_calculate_new_target()` using relative path calculation from the containing file to the new location
- **2.2.1-FR-5**: The system SHALL dispatch line-level replacement to link-type-specific methods: `_replace_markdown_target()`, `_replace_reference_target()`, or `_replace_at_position()`
- **2.2.1-FR-6**: The system SHALL write modified content via atomic temp-file + `shutil.move()` to prevent data loss on interruption
- **2.2.1-FR-7**: The system SHALL track statistics (`files_updated`, `references_updated`, `errors`) and return them from `update_references()`

### User Interactions

- **2.2.1-UI-1**: No direct user interaction — the Link Updater is invoked by the service layer when file movements are detected
- **2.2.1-UI-2**: Users observe update activity through log output showing which files were modified and how many references were updated
- **2.2.1-UI-3**: Users can enable `dry_run` mode to preview changes without modifying any files
- **2.2.1-UI-4**: Users can enable `backup_enabled` to create `.linkwatcher.bak` copies before modifications

### Business Rules

- **2.2.1-BR-1**: References within a file are always processed bottom-to-top (descending line/column order) to preserve character position validity
- **2.2.1-BR-2**: Atomic writes use a `NamedTemporaryFile` in the same directory as the original file, ensuring same-filesystem `shutil.move()` is an atomic rename
- **2.2.1-BR-3**: When `dry_run=True`, the system logs `[DRY RUN] Would update...` messages and accumulates statistics but performs no file I/O
- **2.2.1-BR-4**: When `backup_enabled=True` (default), a `.linkwatcher.bak` copy is created before the atomic write
- **2.2.1-BR-5**: Backup creation failure is non-blocking — the update proceeds even if backup fails (graceful degradation)
- **2.2.1-BR-6**: Each link type has its own replacement method, ensuring syntax-correct modifications (markdown inline, reference-style, generic position-based)

### Acceptance Criteria

- **2.2.1-AC-1**: Given a markdown file with 3 references to a moved file, all 3 references are updated in a single file write
- **2.2.1-AC-2**: Given multiple references on the same line, the rightmost reference is updated first, preserving position validity for the leftmost
- **2.2.1-AC-3**: Given `dry_run=True`, no files are modified on disk but statistics accurately reflect what would change
- **2.2.1-AC-4**: Given a power failure during write, either the original or fully-updated file exists — never a partial write
- **2.2.1-AC-5**: Given `backup_enabled=True`, a `.linkwatcher.bak` file exists alongside each modified file
- **2.2.1-AC-6**: Given a reference with an anchor (`#section`), the anchor is preserved in the updated path

### Edge Cases and Error Handling

- **2.2.1-EC-1**: File read failure (permissions, encoding) is caught and logged; error count incremented; other files continue processing
- **2.2.1-EC-2**: If a containing file has been deleted between parse and update, the error is logged and skipped
- **2.2.1-EC-3**: References with unknown `link_type` fall back to `_replace_at_position()` using column offset

## UX/UI Considerations

Not applicable — this is an internal subsystem with no direct user interface.

## Dependencies

### Feature Dependencies

- **0.1.1 Core Architecture**: Provides `LinkReference` data type (models.py) with `line_number`, `column_start`, `link_type`, and `link_target` fields
- **3.1.1 Logging System**: Provides `get_logger()`, `LogTimer`, and `with_context()` for structured update logging

### Dependent Features

- **0.1.1 Core Architecture**: Service layer instantiates `LinkUpdater` and calls `update_references()`
- **1.1.1 File System Monitoring**: Triggers link updates via service layer on file system events

### External Dependencies

- `shutil` (stdlib): `shutil.move()` for atomic file replacement
- `tempfile` (stdlib): `NamedTemporaryFile()` for safe writes
- `colorama` (external): Colored console output for update log messages
