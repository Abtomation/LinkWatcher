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

The Parser Framework provides a single, uniform interface for extracting file references from any file type in the project. It is implemented as `LinkParser` in `linkwatcher/parser.py` — a facade that maintains a dispatch dictionary mapping file extensions to pre-instantiated parser objects. Callers invoke `parse_file(file_path)` and receive a `List[LinkReference]` without needing to know which parser handles which format.

The framework also exposes `BaseParser` (abstract base class in `linkwatcher/parsers/base.py`) as the extension contract, enabling new file format support by subclassing `BaseParser` and calling `add_parser()`.

### 1.2 Related Features

| Feature | Relationship | Description |
| ------- | ------------ | ----------- |
| 0.1.1 Core Architecture (includes Data Models) | Depends On | `LinkReference` is the return type for all `parse_file()` calls |
| 3.1.1 Logging System | Depends On | `LogTimer` wraps every `parse_file()` call for performance tracking |
| _(2.1.2–2.1.7 Individual Parsers)_ | _(consolidated into 2.1.1)_ | All specialized parsers are now part of this feature |
| 2.2.1 Link Updating | Depended On By | `LinkUpdater` calls `LinkParser.parse_file()` to find references to update |

## 2. Key Requirements

1. Single `parse_file(file_path) → List[LinkReference]` entry point — callers never select a parser directly
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

- **Error Handling**: Individual parsers handle file read errors and return empty lists; the framework does not catch exceptions from parsers (callers handle propagation)
- **Data Integrity**: Parser instances are shared across calls — parsers must be stateless between calls to avoid cross-request contamination
- **Monitoring**: `LogTimer` wraps every `parse_file()` call; timing data available in structured logs

### 3.4 Usability Requirements

- **Developer Experience**: Single import (`from linkwatcher.parser import LinkParser`), single call (`parser.parse_file(path)`) — zero configuration for standard file types
- **Extensibility**: New formats require only subclassing `BaseParser` and calling `add_parser()` — no modification to `LinkParser` itself

## 4. Technical Design

### 4.1 Component Architecture

```
LinkParser (Facade)
├── _parsers: Dict[str, BaseParser]   ← extension → parser instance registry
│   ├── '.md' / '.markdown' → MarkdownParser
│   ├── '.yaml' / '.yml'   → YamlParser
│   ├── '.json'            → JsonParser
│   ├── '.py'              → PythonParser
│   └── '.dart'            → DartParser
├── _default_parser: GenericParser    ← universal fallback
│
├── parse_file(file_path) → List[LinkReference]
│   ├── ext = os.path.splitext(file_path)[1].lower()
│   ├── parser = self._parsers.get(ext, self._default_parser)
│   ├── with LogTimer(...):
│   │       return parser.parse_file(file_path)
│
├── add_parser(ext, parser)           ← runtime registration
├── remove_parser(ext)                ← runtime de-registration
└── get_supported_extensions()        ← registry query

BaseParser (Abstract Interface in parsers/base.py)
└── parse_file(file_path) → List[LinkReference]  ← abstract method
    (also uses: safe_file_read(), looks_like_file_path() from utils.py)
```

### 4.2 Data Flow

```
Caller (service.py / handler.py / scripts/check_links.py)
    │
    ▼ parse_file(file_path)
LinkParser (facade)
    │
    ├─ ext = extension(file_path).lower()
    ├─ parser = _parsers.get(ext, _default_parser)  ← O(1) dict lookup
    │
    ▼ parser.parse_file(file_path)
Specialized Parser (MarkdownParser / YamlParser / ...)
    │
    ├─ safe_file_read(file_path) → raw content
    ├─ apply format-specific regex / parsing logic
    └─ yield LinkReference(source_file, target, line, col, link_type)
    │
    ▼ List[LinkReference]
LinkParser (returns to caller)
```

### 4.3 Design Decisions

**Decision 1: Facade + Pre-instantiated Registry**

- **Pattern**: Facade (single entry point) + Registry dict (extension → parser instance)
- **Why**: Pre-instantiation amortizes regex compilation cost; O(1) dispatch; `add_parser()`/`remove_parser()` enable runtime extension without modifying `LinkParser`
- **Implication**: Parser instances must be stateless per-call; all parsers must be importable at module load time

**Decision 2: GenericParser as Universal Fallback**

- **Pattern**: Default value in `_parsers.get(ext, self._default_parser)`
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

The framework intentionally does not catch exceptions from parsers — propagation to the caller ensures errors are not silently swallowed. Each parser is responsible for its own `try/except` around file reads (returning `[]` on read failure).

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
| `tests/unit/test_parser.py` | Unit tests for `LinkParser` facade |

## 7. Quality Measurement

### 7.1 Performance Monitoring

`LogTimer` records parse duration per file in the structured log. Timing is available in both console and JSON log outputs. The `scripts/benchmark.py` script exercises `LinkParser` at scale for bulk performance measurement.

### 7.2 Reliability Monitoring

Unit tests in `tests/unit/test_parser.py` cover the dispatch logic and fallback behavior. Parser correctness is validated by the full parser test suite in `tests/parsers/`.

## 8. Open Questions

None — feature is stable and fully implemented.

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
