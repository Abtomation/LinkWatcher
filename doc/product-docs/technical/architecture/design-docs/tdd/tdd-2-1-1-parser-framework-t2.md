---
id: PD-TDD-025
type: Technical Design Document
category: TDD Tier 2
version: 1.0
created: 2026-02-19
updated: 2026-02-20
feature_id: 2.1.1
feature_name: Link Parsing System
consolidates: [2.1.1, 2.1.2-2.1.7]
tier: 2
retrospective: true
---

# Lightweight Technical Design Document: Parser Framework

> **Retrospective Document**: This TDD describes the existing technical design of the LinkWatcher Parser Framework, documented after implementation during framework onboarding (PF-TSK-066). Content is reverse-engineered from source code analysis.
>
> **Source**: Derived from source code analysis of `linkwatcher/parser.py`, `linkwatcher/parsers/base.py`, and `linkwatcher/parsers/`.
>
> **Scope Note**: This feature consolidates old 2.1.1 (Parser Framework) with all individual parser sub-features: 2.1.2 (Markdown Parser), 2.1.3 (YAML Parser), 2.1.4 (JSON Parser), 2.1.5 (Python Parser), 2.1.6 (Dart Parser), and 2.1.7 (Generic Parser).

## 1. Overview

### 1.1 Purpose

The Parser Framework provides a single, uniform interface for extracting file references from any file type in the project. It is implemented as `LinkParser` in `linkwatcher/parser.py` — a facade that maintains a dispatch dictionary mapping file extensions to pre-instantiated parser objects. Callers invoke `parse_file(file_path)` to parse from disk or `parse_content(content, file_path)` to parse already-read content, and receive a `List[LinkReference]` without needing to know which parser handles which format. Both methods catch all exceptions and return `[]` on failure.

The framework also exposes `BaseParser` (abstract base class in `linkwatcher/parsers/base.py`) as the extension contract. `BaseParser.parse_file()` is a concrete method that reads the file and delegates to the abstract `parse_content()` method, enabling new file format support by subclassing `BaseParser`, implementing `parse_content()`, and calling `add_parser()`.

### 1.2 Related Features

| Feature | Relationship | Description |
| ------- | ------------ | ----------- |
| 0.1.1 Core Architecture (includes Data Models) | Depends On | `LinkReference` is the return type for all `parse_file()` calls |
| 3.1.1 Logging System | Depends On | `LogTimer` wraps every `parse_file()` call for performance tracking |
| _(2.1.2–2.1.7 Individual Parsers)_ | _(consolidated into 2.1.1)_ | All specialized parsers are now part of this feature |
| 2.2.1 Link Updating | Depended On By | `LinkUpdater` calls `LinkParser.parse_file()` to find references to update |

## 2. Key Requirements

1. Dual entry points: `parse_file(file_path)` for disk reads and `parse_content(content, file_path)` for pre-read content — callers never select a parser directly
2. Extension-based dispatch in O(1) time (dict lookup, case-insensitive)
3. All parsers pre-instantiated at startup — no per-call instantiation cost
4. `GenericParser` fallback ensures every file gets at least a best-effort parse
5. Runtime extensibility via `add_parser(ext, parser)` / `remove_parser(ext)` without modifying `LinkParser`

## 3. Quality Attribute Requirements

### 3.1 Performance Requirements

- **Parse Time**: `parse_file()` dispatch overhead is O(1); total parse time is dominated by the delegated parser, not the framework
- **Startup Cost**: All parsers instantiated once at `LinkParser.__init__()` — regex compilation and setup costs are amortized across all calls
- **Resource Usage**: One parser instance per registered extension (6 specialized + 1 generic = 7 objects in memory); negligible footprint

### 3.2 Security Requirements

- **Input Validation**: File path passed directly to the delegated parser — path sanitization is the parser's responsibility
- **Data Protection**: No user credentials or sensitive data flows through the parser framework; reads file content only

### 3.3 Reliability Requirements

- **Error Handling**: Both `LinkParser.parse_file()` and `parse_content()` wrap the delegated call in a `try/except Exception` and return `[]` on any failure, logging a warning. Individual parsers also handle file read errors in `BaseParser.parse_file()` and return empty lists. Exceptions never propagate to callers.
- **Data Integrity**: Parser instances are shared across calls — parsers must be stateless between calls to avoid cross-request contamination
- **Monitoring**: `LogTimer` wraps every `parse_file()` call; timing data available in structured logs

### 3.4 Usability Requirements

- **Developer Experience**: Single import (`from linkwatcher.parser import LinkParser`), single call (`parser.parse_file(path)`) — zero configuration for standard file types
- **Extensibility**: New formats require only subclassing `BaseParser` and calling `add_parser()` — no modification to `LinkParser` itself

## 4. Technical Design

### 4.1 Component Architecture

```
LinkParser (Facade)
├── parsers: Dict[str, BaseParser]    ← extension → parser instance registry
│   ├── '.md'              → MarkdownParser
│   ├── '.yaml' / '.yml'   → YamlParser
│   ├── '.json'            → JsonParser
│   ├── '.py'              → PythonParser
│   ├── '.dart'            → DartParser
│   └── '.ps1' / '.psm1'  → PowerShellParser
├── generic_parser: GenericParser     ← universal fallback
│
├── parse_file(file_path) → List[LinkReference]
│   ├── ext = os.path.splitext(file_path)[1].lower()
│   ├── parser = self.parsers.get(ext) or self.generic_parser
│   ├── with LogTimer("file_parsing", self.logger, ...):
│   │       return parser.parse_file(file_path)
│   └── except Exception: return []   ← catches all parser errors
│
├── parse_content(content, file_path) → List[LinkReference]
│   ├── ext = os.path.splitext(file_path)[1].lower()
│   ├── parser = self.parsers.get(ext) or self.generic_parser
│   ├── with LogTimer("content_parsing", self.logger, ...):
│   │       return parser.parse_content(content, file_path)
│   └── except Exception: return []   ← catches all parser errors
│
├── add_parser(ext, parser)           ← runtime registration
├── remove_parser(ext)                ← runtime de-registration
└── get_supported_extensions()        ← registry query

BaseParser (Abstract Interface in parsers/base.py)
├── parse_file(file_path) → List[LinkReference]  ← concrete (reads file, delegates to parse_content)
└── parse_content(content, file_path) → List[LinkReference]  ← abstract method
    (also uses: safe_file_read(), looks_like_file_path(), looks_like_directory_path() from utils.py)
```

### 4.2 Data Flow

```
Caller (service.py / handler.py / scripts/check_links.py)
    │
    ├─ parse_file(file_path)          ← parse from disk
    │  OR
    ├─ parse_content(content, path)   ← parse pre-read content
    │
    ▼
LinkParser (facade)
    │
    ├─ ext = os.path.splitext(file_path)[1].lower()
    ├─ parser = self.parsers.get(ext) or self.generic_parser  ← O(1) dict lookup
    │
    ├─ [parse_file path]:    parser.parse_file(file_path)
    │  [parse_content path]: parser.parse_content(content, file_path)
    │
    ▼
Specialized Parser (MarkdownParser / YamlParser / ...)
    │
    ├─ [parse_file]: safe_file_read(file_path) → content → parse_content()
    ├─ [parse_content]: apply format-specific regex / parsing logic
    └─ return [LinkReference(source_file, target, line, col, link_type), ...]
    │
    ▼ List[LinkReference]
LinkParser (returns to caller; returns [] on any exception)
```

### 4.3 Design Decisions

**Decision 1: Facade + Pre-instantiated Registry**

- **Pattern**: Facade (single entry point) + Registry dict (extension → parser instance)
- **Why**: Pre-instantiation amortizes regex compilation cost; O(1) dispatch; `add_parser()`/`remove_parser()` enable runtime extension without modifying `LinkParser`
- **Implication**: Parser instances must be stateless per-call; all parsers must be importable at module load time

**Decision 2: GenericParser as Universal Fallback**

- **Pattern**: Fallback via `self.parsers.get(ext)` with `self.generic_parser` as default
- **Why**: Zero-configuration coverage of arbitrary file types; best-effort extraction rather than silent gaps for unrecognized extensions
- **Implication**: `GenericParser` is always present; all files receive at least one parse attempt

**Decision 3: Case-insensitive Extension Matching**

- **Pattern**: `ext = os.path.splitext(file_path)[1].lower()` before dict lookup
- **Why**: File systems may present `.MD` or `.Md` variants; normalizing prevents missed parses
- **Implication**: Registry keys must always be stored in lowercase

### 4.4 Quality Attribute Implementation

#### Performance Implementation

`LogTimer` context manager wraps the delegated `parse_file()` call, recording start/end times and logging via `structlog`. No additional overhead beyond the dict lookup.

#### Reliability Implementation

The framework catches all exceptions at the `LinkParser` facade level — both `parse_file()` and `parse_content()` return `[]` on any failure and log a warning. This provides a double safety net: individual parsers handle file read errors in `BaseParser.parse_file()` (returning `[]`), and the facade catches any remaining exceptions from parser logic. Callers are guaranteed to receive a list, never an exception.

## 5. Cross-References

### 5.1 Functional Requirements Reference

> **📋 Primary Documentation**: FDD PD-FDD-026
> **🔗 Link**: [Parser Framework FDD](../../../../functional-design/fdds/fdd-2-1-1-parser-framework.md)

**Brief Summary**: The FDD defines 7 functional requirements covering the `parse_file()` entry point, extension dispatch, GenericParser fallback, runtime `add_parser()`/`remove_parser()` API, `get_supported_extensions()` query, and `LogTimer` performance tracking.

### 5.2 API / Database / Test Spec References

No API Design, Database Schema Design, or Test Specification documents exist for this feature (not required for Tier 2 internal framework components).

## 6. Implementation Plan

> **Retrospective**: This feature is fully implemented. The following reflects the actual implementation structure.

### 6.1 Dependencies

- `linkwatcher/models.py` — `LinkReference` return type
- `linkwatcher/logging.py` — `get_logger()`, `LogTimer`
- `linkwatcher/utils.py` — `safe_file_read()`, `looks_like_file_path()` (used by `BaseParser`)
- All parser modules in `linkwatcher/parsers/` — must be importable at `LinkParser.__init__()` time

### 6.2 Key Files

| File | Role |
| ---- | ---- |
| `linkwatcher/parser.py` | `LinkParser` facade — dispatch registry and public API |
| `linkwatcher/parsers/base.py` | `BaseParser` abstract class — extension contract |
| `linkwatcher/parsers/__init__.py` | Package init — exports all parser classes |
| `linkwatcher/parsers/markdown.py` | `MarkdownParser` — `.md` files. Extracts `[text](path)` links, `[label]: path` reference definitions, `<a href>` tags, quoted file/directory paths (`"path"`, `'path"`, `` `path` ``), and standalone file references. Backtick-delimited paths are treated as quoted strings for both file and directory detection. |
| `linkwatcher/parsers/yaml_parser.py` | `YamlParser` — `.yaml`/`.yml` files. Detects file path references and directory path references (PD-BUG-030). |
| `linkwatcher/parsers/json_parser.py` | `JsonParser` — `.json` files. Detects file path references and directory path references (PD-BUG-030). |
| `linkwatcher/parsers/python.py` | `PythonParser` — `.py` files |
| `linkwatcher/parsers/dart.py` | `DartParser` — `.dart` files |
| `linkwatcher/parsers/powershell.py` | `PowerShellParser` — `.ps1`/`.psm1` files. Extracts paths from `#` line comments, `<# #>` block comments (including `.EXAMPLE`/`.NOTES` sections), quoted string literals, `Join-Path` arguments, and `Import-Module` paths. Uses regex patterns: `quoted_pattern` for double/single-quoted strings, `comment_pattern` for `#` line comments, `block_comment_pattern` for `<# ... #>` regions, `join_path_pattern` for `Join-Path -ChildPath` arguments. |
| `linkwatcher/parsers/generic.py` | `GenericParser` — fallback for all other file types |
| `test/automated/unit/test_parser.py` | Unit tests for `LinkParser` facade |

## 7. Quality Measurement

### 7.1 Performance Monitoring

`LogTimer` records parse duration per file in the structured log. Timing is available in both console and JSON log outputs. The `scripts/benchmark.py` script exercises `LinkParser` at scale for bulk performance measurement.

### 7.2 Reliability Monitoring

Unit tests in `test/automated/unit/test_parser.py` cover the dispatch logic and fallback behavior. Parser correctness is validated by the full parser test suite in `test/automated/parsers/`.

## 8. Open Questions

None — feature is stable and fully implemented. PowerShellParser added 2026-03-13.

## 9. AI Agent Session Handoff Notes

### Current Status

Feature fully implemented and stable. TDD created retrospectively during onboarding (PF-TSK-066, Session 15, 2026-02-19).

### Next Steps

No implementation work needed. Future work would involve:
- Adding a new parser: subclass `BaseParser`, call `LinkParser.add_parser(ext, instance)`
- Extending `get_supported_extensions()` documentation if new formats are added

### Key Decisions

- Facade + Registry pattern (not if/elif, not factory) — see Decision 1 above
- GenericParser always present as fallback — see Decision 2 above
- All parser instances shared (stateless per-call requirement)

### Known Issues

None.
