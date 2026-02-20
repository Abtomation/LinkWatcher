---
id: PD-FDD-026
type: Product Documentation
category: Functional Design Document
version: 1.0
created: 2026-02-19
updated: 2026-02-19
feature_id: 2.1.1
feature_name: Parser Framework
retrospective: true
---

# Parser Framework - Functional Design Document

> **Retrospective Document**: This FDD describes the existing implemented functionality of the LinkWatcher Parser Framework, documented after implementation during framework onboarding (PF-TSK-066). Content is descriptive ("what is") rather than prescriptive ("what should be").
>
> **Source**: Derived from [2.1.1 Implementation State](../../../process-framework/state-tracking/features/2.1.1-parser-framework-implementation-state.md), [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md) (Parser System section), and source code analysis of `linkwatcher/parser.py` and `linkwatcher/parsers/`.

## Feature Overview

- **Feature ID**: 2.1.1
- **Feature Name**: Parser Framework
- **Business Value**: Enables LinkWatcher to extract file references from any file type through a single, uniform interface. New file formats can be supported without any change to the callers — only a new parser registration is required.
- **User Story**: As a developer running LinkWatcher, I want the system to automatically detect file references in every file type in my project so that all cross-file links are tracked and maintained regardless of file format.

## Related Documentation

### Architecture Overview Reference

> **📋 Primary Documentation**: [HOW_IT_WORKS.md](../../../../HOW_IT_WORKS.md) — Parser System section
> **👤 Source**: Pre-framework project documentation (Confirmed in PF-TSK-065 analysis)
>
> **Purpose**: Overview of the parser registry design, base parser interface, and dispatch mechanism.

**Functional Architecture Summary** (derived from HOW_IT_WORKS.md):

- The Parser Framework provides a single `parse_file(file_path)` entry point that automatically selects the correct parser for any file based on its extension
- Six specialized parsers handle specific formats; a GenericParser provides best-effort fallback for all other file types
- The parser registry is extensible at runtime — new parsers can be registered without modifying existing code

### Technical Design Reference

> **🔗 Link**: [TDD PD-TDD-025](../../technical/architecture/design-docs/tdd/tdd-2-1-1-parser-framework-t2.md)
>
> **Purpose**: Detailed technical design of the Facade + Registry pattern, `LinkParser` class internals, `BaseParser` abstract interface, and dispatch mechanism.

## Functional Requirements

### Core Functionality

- **2.1.1-FR-1**: The system SHALL extract all file references from a given file by calling `parse_file(file_path)` and receive a list of `LinkReference` objects describing each reference found
- **2.1.1-FR-2**: The system SHALL automatically select the appropriate parser for each file based on the file's extension (case-insensitive match)
- **2.1.1-FR-3**: The system SHALL handle files with unrecognized extensions using a GenericParser that attempts best-effort reference extraction
- **2.1.1-FR-4**: The system SHALL support adding new file format parsers at runtime via `add_parser(extension, parser)` without modifying existing code
- **2.1.1-FR-5**: The system SHALL support removing registered parsers at runtime via `remove_parser(extension)`
- **2.1.1-FR-6**: The system SHALL expose `get_supported_extensions()` to allow callers to query which extensions have specialized parsers registered
- **2.1.1-FR-7**: The system SHALL record performance timing for every `parse_file()` call via `LogTimer`

### User Interactions

- **2.1.1-UI-1**: No direct user interaction — the Parser Framework is an internal subsystem invoked by the service layer and event handler
- **2.1.1-UI-2**: Users indirectly observe parser activity through log output showing files scanned and link counts during startup or file events
- **2.1.1-UI-3**: Developers extending the system can register custom parsers programmatically via `add_parser()` without modifying LinkWatcher source code

### Business Rules

- **2.1.1-BR-1**: File extension matching is always case-insensitive (`.MD` is treated identically to `.md`)
- **2.1.1-BR-2**: The dispatch dictionary maps extensions to pre-instantiated parser objects — parsers are created once at startup and reused across all calls (parsers must be stateless per-call)
- **2.1.1-BR-3**: If no specialized parser is registered for an extension, `GenericParser` is used as universal fallback — no file returns zero-result without at least a best-effort parse attempt
- **2.1.1-BR-4**: The default registered parsers cover: `.md`/`.markdown` (Markdown), `.yaml`/`.yml` (YAML), `.json` (JSON), `.py` (Python), `.dart` (Dart)
- **2.1.1-BR-5**: `add_parser()` and `remove_parser()` operate on the live registry — changes take effect immediately for subsequent `parse_file()` calls
- **2.1.1-BR-6**: `GenericParser` cannot be removed via `remove_parser()` without explicitly re-registering an extension; it always handles all unregistered extensions

### Acceptance Criteria

- **2.1.1-AC-1**: Given a `.md` file, `parse_file()` returns only markdown link references (not YAML or JSON references)
- **2.1.1-AC-2**: Given a `.yaml` file, `parse_file()` returns YAML-format file path references
- **2.1.1-AC-3**: Given a `.py` file, `parse_file()` returns Python import path references
- **2.1.1-AC-4**: Given a file with extension `.xyz` (unregistered), `parse_file()` returns whatever `GenericParser` extracts — not an empty list by default
- **2.1.1-AC-5**: After `add_parser('.toml', custom_parser)`, calling `parse_file('pyproject.toml')` routes to `custom_parser`
- **2.1.1-AC-6**: `get_supported_extensions()` returns at minimum `['.md', '.markdown', '.yaml', '.yml', '.json', '.py', '.dart']`
- **2.1.1-AC-7**: Performance timing is logged for every `parse_file()` call

### Error Conditions

- **2.1.1-EC-1**: If the file cannot be read (permissions, missing), the delegated parser handles the error and returns an empty list — `parse_file()` does not raise
- **2.1.1-EC-2**: If a parser raises an unexpected exception, it propagates to the caller (no silent swallowing at the framework level — exception handling is the caller's responsibility)

## Feature Boundaries

**This feature provides**:
- `LinkParser` facade with `parse_file()`, `add_parser()`, `remove_parser()`, `get_supported_extensions()`
- `BaseParser` abstract class defining the parser interface
- Default parser registry (6 specialized parsers + GenericParser fallback)

**This feature does NOT provide**:
- The actual link extraction logic for each format (owned by 2.1.2–2.1.7)
- File system traversal or directory walking (owned by 1.1.3 Initial Scan)
- Persistence of extracted references (owned by 0.1.3 In-Memory Database)
