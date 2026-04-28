---
id: PD-UGD-004
type: Product Documentation
category: User Guide
version: 1.0
created: 2026-04-07
updated: 2026-04-07
handbook_category: usage
handbook_name: LinkWatcher Capabilities Reference
---

# LinkWatcher Capabilities Reference

Authoritative reference for what LinkWatcher detects, updates, and validates. When in doubt about LinkWatcher's behavior, consult this document — do not assume.

## Monitored File Types (Default)

| Category | Extensions |
|----------|-----------|
| Documentation | `.md`, `.txt` |
| Config | `.yaml`, `.yml`, `.json`, `.xml`, `.csv`, `.toml` |
| Web | `.html`, `.htm`, `.css`, `.js`, `.ts`, `.jsx`, `.tsx`, `.vue`, `.php` |
| Source Code | `.py`, `.dart`, `.ps1`, `.psm1`, `.bat` |
| Images | `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.webp`, `.ico` |
| Documents | `.pdf` |
| Media | `.mp4`, `.mp3`, `.wav` |

All extensions are configurable via `monitored_extensions` in config.

## Link Detection by Parser

### Markdown (.md)

| Pattern | Example |
|---------|---------|
| Standard links | `[text](path/file.md)` |
| Reference definitions | `[label]: path/file.md "title"` |
| HTML anchors | `<a href="path/file.md">` |
| Quoted file paths | `"path/file.ext"` or `'path/file.ext'` |
| Quoted directory paths | `"path/to/dir"` |
| Backtick paths | `` `path/to/file.ext` `` and `` `path/to/dir` `` |
| Bare paths | `process-framework/scripts/file` (2+ segments required) |
| @-prefixed paths | `@doc/path/to/file.md` |
| YAML frontmatter values | `target_area: linkwatcher/parsers` in leading `---...---` block |

Mermaid code blocks are skipped (illustrative content, not navigable links). YAML frontmatter values are parsed as YAML (via the YAML parser), so both file and directory path values are detected — including 2-segment bare directory paths that the prose patterns reject.

### Python (.py)

| Pattern | Example |
|---------|---------|
| Quoted file paths | `"path/file.py"` or `'path/file.py'` |
| Quoted directory paths | `"path/to/dir"` |
| Import statements | `import src.utils.string_utils` (dot-to-path conversion) |
| Docstring file paths | Paths inside `"""..."""` blocks |
| Comment file paths | Paths after `#` |

Standard library imports are automatically filtered out. Local imports must start with known prefixes (`src`, `lib`, `app`, `core`, `utils`, `helpers`, `modules`, `packages`) or have 3+ segments.

### YAML (.yaml, .yml)

| Pattern | Example |
|---------|---------|
| Full-string file values | `key: "path/file.ext"` |
| Embedded paths in strings | `"pwsh.exe -File doc/scripts/Run.ps1"` |
| Directory path values | `key: "path/to/dir"` |

Multi-document YAML streams (multiple `---` separated documents) are fully supported — all documents are walked. Falls back to generic parser only on true YAMLError.

### JSON (.json)

| Pattern | Example |
|---------|---------|
| Full-string file values | `"path/file.ext"` |
| Embedded paths in strings | `"Bash(python doc/scripts/run.py *)"` |
| Directory path values | `"path/to/dir"` |

Falls back to generic parser on JSONDecodeError.

### PowerShell (.ps1, .psm1)

| Pattern | Example |
|---------|---------|
| Quoted file paths | `"path/file.ps1"` or `'path/file.ps1'` |
| Quoted directory paths | `"path/to/dir"` |
| Embedded markdown links | `[text](path/to/file)` inside strings |
| Unquoted paths | In comments and text |
| Block comments | `<# ... #>` content |
| Here-strings | `@"..."@` and `@'...'@` content |

### Dart (.dart)

| Pattern | Example |
|---------|---------|
| Import statements | `import 'path/to/file.dart'` |
| Part statements | `part 'path/to/file.dart'` |
| Quoted file paths | `"path/file.dart"` |
| Standalone paths | Bare paths with extensions |

Skips `package:` and `dart:` scheme imports.

### Generic Fallback (all other monitored extensions)

| Pattern | Example |
|---------|---------|
| Quoted file paths | `"path/file.ext"` |
| Quoted directory paths | `"path/to/dir"` |
| Unquoted paths | Only if no quoted paths on same line; requires `/` or `\` separators or file-related keywords |

## What Triggers Updates

### File Moves (primary trigger)

Three detection strategies:

1. **Native OS move events** — Direct `FileMovedEvent` from watchdog
2. **Delete+Create correlation** — Windows editors don't emit native move events; DELETE buffered, matched with CREATE within `move_detect_delay` (default 10s) by basename + file size
3. **Directory batch detection** — Windows reports dir deletes as individual file DELETEs; `DirectoryMoveDetector` collects and matches with CREATEs under new parent (up to 300s timeout)

**On move detection, LinkWatcher**:
- Updates all references pointing to the moved file across the entire project
- Updates the database entry for the moved file's own path
- Fixes relative links inside the moved file itself
- Updates references to directory paths

### File Deletions

- Confirmed after `move_detect_delay` with no matching CREATE
- Removes file from internal database

### New File Creation

- Scanned for links if extension is in `monitored_extensions`
- Links added to internal database

## Validation Mode (`--validate`)

- **Read-only** — no file modifications
- Scans workspace for broken file references
- Writes report to `LinkWatcherBrokenLinks.txt`
- Exits with code 0 (clean) or 1 (broken links found)
- Default validated extensions: `.md`, `.yaml`, `.yml`, `.json` (configurable via `validation_extensions`)
- Smart resolution: tries source-file-relative first, falls back to project-root-relative
- Context-aware skipping: code blocks, `<details>` archival sections, table rows, template files, placeholder lines

## What LinkWatcher Does NOT Do

- **Does not only update markdown** — it updates ALL monitored file types including `.py`, `.ps1`, `.yaml`, `.json`, `.dart`, and more
- **Does not only update markdown-style links** — it updates Python imports, quoted paths, bare paths, YAML/JSON values, PowerShell here-strings, Dart imports, and more
- **Does not update external URLs** — `http://`, `https://`, `mailto:`, etc. are skipped
- **Does not validate HTML anchors** — `#section` links not checked against heading IDs
- **Does not interact with git** — operates on disk state only
- **Does not do syntax-aware refactoring** — updates textual matches, not AST-based
- **Does not update package manager references** — `requirements.txt` versions, `package.json` dependencies, etc.
- **Does not create backups by default** — configurable via `create_backups: true`

## Key Configuration Options

| Setting | Default | Purpose |
|---------|---------|---------|
| `monitored_extensions` | 24 extensions | Which file types to watch |
| `ignored_directories` | `.git`, `node_modules`, etc. | Dirs to skip |
| `create_backups` | false | Create `.bak` before updates |
| `dry_run_mode` | false | Preview without modifying |
| `atomic_updates` | true | Use temp files for safe writes |
| `max_file_size_mb` | 10 | Skip files larger than this |
| `move_detect_delay` | 10s | Window for delete+create correlation |
| `enable_*_parser` | all true | Toggle individual parsers |
| `validation_extensions` | `.md`, `.yaml`, `.yml`, `.json` | Extensions for `--validate` |
| `python_source_root` | none | Strip prefix for `src/` layout projects |

Config precedence: CLI args > Environment variables (`LINKWATCHER_*`) > Config file (YAML/JSON) > Defaults.

## Ignore System (`.linkwatcher-ignore`)

Suppresses false positives in validation mode:

```
# Format: source_glob -> target_substring
process-framework/templates/**/*.md -> related-design.md
doc/validation/**/*.md -> docs/README.md
```

Both source glob and target substring must match to suppress a broken link report.

## Related Documentation

- [Quick Reference](/doc/user/handbooks/quick-reference.md) — CLI options, config, examples
- [Link Validation](/doc/user/handbooks/link-validation.md) — Validation mode details
- [File Type Quick Fix](/doc/user/handbooks/file-type-quick-fix.md) — Adding file type monitoring
- [File Type Troubleshooting](/doc/user/handbooks/troubleshooting-file-types.md) — Detailed file type issues

---

*This handbook is part of the LinkWatcher Product Documentation.*
