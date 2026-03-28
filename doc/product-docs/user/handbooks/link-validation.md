---
id: PD-UGD-003
type: Product Documentation
category: User Guide
version: 1.0
created: 2026-03-27
updated: 2026-03-27
handbook_category: usage
handbook_name: Link Validation
---

# Link Validation

## Overview

LinkWatcher's `--validate` command performs an on-demand scan of your workspace, checking every local file reference across all documentation files (.md, .yaml, .yml, .json) and reporting any broken links — targets that no longer exist on disk.

Unlike the real-time watcher (which reacts to file moves), validation proactively audits the current state of all links. Use it to catch references that became stale through manual edits, external tooling, or other changes not caught by the file watcher.

**What it checks**: Local file paths in Markdown links, YAML values, and JSON values.
**What it does NOT check**: HTTP/HTTPS URLs, Python imports, or paths inside source code files (.py, .ps1, .dart).

## Prerequisites

- LinkWatcher installed (`pip install -e .`)
- A project directory containing files with cross-references

## Quick Start

```cmd
# Scan current directory for broken links
python main.py --validate

# Scan a specific project
python main.py --validate --project-root c:\path\to\project

# Scan with debug output for troubleshooting
python main.py --validate --debug
```

The command prints a summary to the console and writes a detailed report to `LinkWatcherBrokenLinks.txt`.

## Reading the Report

The report is written to `LinkWatcherBrokenLinks.txt` in the same directory as your log file (or the project root if no log file is configured).

```
============================================================
LinkWatcher - Link Validation Report
============================================================

Files scanned : 142
Links checked : 1,203
Broken links  : 3
Duration      : 1.45s

Broken links:
------------------------------------------------------------
  doc/guides/setup.md:15
    -> ../config/old-settings.yaml  (markdown)
  doc/README.md:42
    -> tutorials/getting-started.md  (markdown)
  config/references.yaml:8
    -> scripts/deploy.py  (yaml)
------------------------------------------------------------
```

Each broken link shows:
- **Source file and line number** — where the broken reference is
- **Target path** — the path that doesn't resolve to an existing file
- **Link type** — how the parser classified the reference (markdown, yaml, json, etc.)

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All links are valid |
| `1` | One or more broken links found |

This makes `--validate` suitable for CI/CD pipelines:

```cmd
python main.py --validate --quiet || echo "Broken links detected!"
```

## Configuration

Two configuration keys control validation behavior:

### `validation_ignored_patterns`

A list of substring patterns. Any link target containing one of these substrings is skipped during validation.

```yaml
# linkwatcher-config.yaml
validation_ignored_patterns:
  - "path/to/"          # skip template placeholder paths
  - "example.com/"      # skip example domain references
```

**Default**: `["path/to/", "xxx"]`

**Environment variable**: `LINKWATCHER_VALIDATION_IGNORED_PATTERNS=path/to/,xxx`

### `validation_ignore_file`

Path (relative to project root) to a per-file ignore rules file.

```yaml
validation_ignore_file: "LinkWatcher/.linkwatcher-ignore"
```

**Default**: `"LinkWatcher/.linkwatcher-ignore"`

### Per-File Ignore Rules (`.linkwatcher-ignore`)

For fine-grained suppression, create a `.linkwatcher-ignore` file. Each rule specifies which source files and which target substrings to suppress:

```
# Format: source_glob -> target_substring
# Lines starting with # are comments

# Template files contain intentional placeholder paths
doc/templates/**/*.md -> related-design.md
doc/templates/**/*.md -> related-api.md

# Validation reports reference files as they existed at analysis time
doc/reports/**/*.md -> docs/README.md

# Historical state files reference deleted artifacts
doc/state-tracking/**/*.md -> old-module.py
```

**How it works**: A broken link is suppressed when the source file matches the glob pattern AND the link target contains the substring.

**Best practice**: Prefer fixing the actual broken link over adding an ignore rule. Every rule is a potential blind spot.

## Combining with Other Options

| Combination | Effect |
|-------------|--------|
| `--validate --debug` | Show detailed debug output during scan |
| `--validate --quiet` | Suppress console output, only write report file |
| `--validate --config settings.yaml` | Use custom config for ignored patterns/directories |
| `--validate --log-file run/log.txt` | Write report to `run/LinkWatcherBrokenLinks.txt` |
| `--validate --project-root /other/dir` | Scan a different project directory |

**Note**: `--validate` exits immediately after scanning — it does not start the file watcher. No lock file is created.

## Tips and Best Practices

- **Run validation after bulk operations** — after moving many files, renaming directories, or importing content from another project
- **Use in CI/CD** — add `python main.py --validate --quiet` to your pipeline to catch broken links before merging
- **Start with `--debug`** — if you see unexpected broken links, `--debug` shows which files are scanned and how links are resolved
- **Fix links before adding ignore rules** — ignore rules are for intentional non-paths (template placeholders, prose examples), not for links you haven't gotten around to fixing

## Troubleshooting

### Too many false positives

**Problem:** Validation reports paths that aren't actually broken references (e.g., template placeholders, prose examples).

**Solution:**
1. Add substring patterns to `validation_ignored_patterns` in your config for broad categories
2. Use `.linkwatcher-ignore` for file-specific suppressions
3. Run with `--debug` to see why specific targets are being flagged

### Broken links in source code files

**Problem:** You expected `.py` or `.ps1` files to be scanned but they aren't in the report.

**Solution:** By design, validation only scans documentation files (.md, .yaml, .yml, .json). Source code files contain string literals and comments with paths that are data values, not document cross-references. The real-time watcher handles those.

### Report file location is unexpected

**Problem:** You can't find `LinkWatcherBrokenLinks.txt`.

**Solution:** The report is written to:
1. The parent directory of `--log-file` (if specified)
2. The parent directory of `config.log_file` (if set in config)
3. The project root directory (fallback)

Use `--log-file` to control where the report lands.

### Links with anchors (#section) reported as broken

**Problem:** A link like `doc/guide.md#setup` is reported broken.

**Solution:** The validator strips anchors and checks only the file part (`doc/guide.md`). If the file exists, the link passes. If you see this reported, the file itself is missing — the anchor is not the issue.

## Related Documentation

- [Quick Reference](/doc/product-docs/user/handbooks/quick-reference.md) — All CLI options and configuration
- [Multi-Project Setup](/doc/product-docs/user/handbooks/multi-project-setup.md) — Using LinkWatcher across multiple projects
- [README](/README.md) — Project overview and installation

---

*This handbook is part of the LinkWatcher Product Documentation.*
