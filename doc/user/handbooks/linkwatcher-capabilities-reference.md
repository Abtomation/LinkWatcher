---
id: PD-UGD-004
description: "Complete reference of all detection patterns, parsers, and update triggers"
type: Product Documentation
category: User Guide
version: 1.1
created: 2026-04-07
updated: 2026-08-18
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

**Applies to every parser below**: a path built only from dot segments — `../`, `../../`, `./..` — is **not** a reference (PD-BUG-149). It names no artifact, so a bare parent-directory token written inside quotes or backticks is treated as notation and left alone. Previously it was registered like any other path, and when its containing file moved to a different depth the rewrite re-depthed it along with the real links, silently changing the prose — a sentence reading "carries 7 `../` links" came back as "carries 7 `../../` links". The same token written in **link syntax** — `[parent](../)` — is an authored reference and is still detected and updated; only bare tokens are suppressed. A directory whose name merely begins with dots (`..hidden/x`) has a named segment and is unaffected.

**Surrounding whitespace does not change any of this** (PD-BUG-151). The rule above once held only for the *tight* spelling: a token written with padding inside its delimiters — `` ` ../../ ` `` — was still registered, and on a depth-changing move the whole span **including its padding** was replaced, so the notation was destroyed rather than re-depthed (`` ` ../../ ` `` became `` `..` ``). In YAML and JSON that damage landed in structured config **values**, not prose, and it was silent — the span was counted as an updated link. A padded token is now recognised as the same notation and left alone, in every parser.

The underlying cause was that a target's surrounding whitespace was captured as **part of the reference**. It no longer is: a reference now records its path trimmed, and its recorded position covers exactly that path. That guarantee was itself only half-kept until PD-BUG-150: it held where the *path* carried the padding, but not where a parser trimmed the path and left the recorded position covering the whitespace anyway. A PowerShell **quoted directory** written with padding — `$dir = "  doc/target  "` — was the case that reached it: the path was re-pointed correctly on a move, but the spacing around it was overwritten, silently, and the link still counted as updated. Both halves now hold, in every parser, so a move re-points a link without ever re-spelling how it was written. This also repairs a quieter failure — a padded reference that named something real, such as `" ../doc/sub "`, never resolved on disk and so was **silently skipped** when its file moved, going stale with no warning. Such a reference now follows the move, and the whitespace the author wrote around it is preserved.

**An inline markdown link written with padding follows a move too** (PD-BUG-152). CommonMark allows whitespace around a link destination, and `[x]( ../doc/y.md )` renders exactly like `[x](../doc/y.md)` — but the padded spelling was never updated, in either direction: neither when the file *containing* it moved, nor when the file it *points at* moved. The second case is the broader one, since it reaches every file referencing a moved target, and it was completely silent — no warning, and the link still counted as updated. Both are fixed, and the spacing is written back exactly as authored. This is the same principle applied throughout: a move changes **where** a link points, never **how** it was written.

**A link destination wrapped in angle brackets follows a move too** (PD-BUG-155). CommonMark lets a destination be enclosed in angle brackets — `[x](<doc/a b.md>)`, and the same for a reference definition, `[label]: <doc/a b.md>` — and **requires** that form when the path contains a space, which is the only reason to reach for it. Those brackets are link syntax, not part of the path, but they used to be recorded as part of the target. Nothing then matched: a file that moved was never recognised as the thing such a link pointed at, so the link was left untouched on **both** paths — when the file containing it moved, and when the file it pointed at moved. It was silent in the strongest sense available: the reference was never even selected, so there was no warning, no count, and no skipped-link report. A stale link of this kind was also invisible to `--validate`, which discarded any angle-wrapped target as a `<placeholder>` before checking it. All of that is fixed, and the brackets are written back exactly as authored. The same applies to an angle-wrapped destination inside a PowerShell string. A validation scan now verifies these links too (PD-BUG-156). It previously refused to check **any** target containing a space, so a path that needed the angle form for that very reason was followed correctly on a move yet never verified by a scan — a stale one was reported by nothing, and the documented recovery of running `--validate` after a blind window did not cover the class. The refusal was a deliberate noise filter and is still applied to *heuristically* detected paths, where a space almost always means the text is prose or a shell command rather than a path; it is no longer applied to **explicit link syntax** — `[text](path)`, `[label]: path`, `<a href="path">` — where the author wrote deliberate link markup and a space is part of the filename. Removing the filter outright was measured on this repository at 54 additional reports, none of them real.

### Markdown (.md)

| Pattern | Example |
|---------|---------|
| Standard links | `[text](path/file.md)` |
| Reference definitions | `[label]: path/file.md "title"` |
| Angle-bracket destinations | `[text](<path/file with space.md>)`, `[label]: <path/file with space.md>` |
| HTML anchors | `<a href="path/file.md">` |
| Quoted file paths | `"path/file.ext"` or `'path/file.ext'` |
| Quoted directory paths | `"path/to/dir"` |
| Backtick paths | `` `path/to/file.ext` `` and `` `path/to/dir` `` |
| Bare paths | `process-framework/scripts/file` (2+ segments required) |
| @-prefixed paths | `@doc/path/to/file.md` |
| YAML frontmatter values | `target_area: linkwatcher/parsers` in leading `---...---` block |


A directory reference must sit inside a **properly paired** pair of delimiters (PD-BUG-135). The gap *between* two literals is not a reference: writing `` `dev.bat dev-setup` / `dev.bat pre-commit` `` no longer registers `" / "` as a directory, and a span that opens on one quote style and closes on another is rejected outright. Pairing is judged per line, so a line whose delimiters genuinely do not balance (an unmatched prose apostrophe, or nested backticks that markdown itself renders as plain text) can lose a reference on that line. This also **recovers** references the old behaviour hid: a bogus span straddling a real backticked directory used to claim that text first and suppress it, so the real reference was never tracked and silently did not follow a move.
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
| Escaped double-quoted values | `key: "logs\\sub\\x.txt"` |
| Escaped paths inside compound strings | `key: "pwsh -File logs\\sub\\run.ps1 -Quick"` |
| Quoted directory inside a compound string | `key: "pwsh.exe -File 'doc/technical/design'"` |

Multi-document YAML streams (multiple `---` separated documents) are fully supported — all documents are walked. Falls back to generic parser only on true YAMLError. Double-quoted scalars carrying backslash escapes are detected and updated (PD-BUG-126); plain and single-quoted scalars take backslashes literally and were never affected. This applies to a path embedded in a compound string too (PD-BUG-130) — the path inside the command is what gets tracked and rewritten, never the command as a whole, and the surrounding text is left untouched. A **directory** inside a compound string is tracked too, but only when it is **quoted** (PD-BUG-131) — the same delimiter rule the markdown, generic, python and PowerShell parsers have always applied to extensionless paths. An *unquoted* directory in a compound value is not a reference; it no longer registers the whole command string as one either, so a value carrying command *syntax* — a parenthesis bound directly to a word (`Bash(`), or a bracket used as a standalone test operator (`[ -d path ]`) — is recognised as a command rather than a path. A filename that merely contains a space and a parenthesis (`assets/img (1).png`) is unaffected.

### JSON (.json)

| Pattern | Example |
|---------|---------|
| Full-string file values | `"path/file.ext"` |
| Embedded paths in strings | `"Bash(python doc/scripts/run.py *)"` |
| Directory path values | `"path/to/dir"` |
| Escape-bearing values | `"logs\\sub\\x.txt"`, `"logs\/sub"`, `"\u0078.txt"` |
| Escaped paths inside compound strings | `"Bash(python logs\\sub\\run.py *)"` |
| Quoted directory inside a compound string | `"Bash([ -d \"doc/technical/design\" ])"` |

Falls back to generic parser on JSONDecodeError. Values written with any JSON escape sequence are detected and updated (PD-BUG-126): JSON has no escape-free string form, so a Windows-style path can only be authored with doubled backslashes. Such a value is rewritten in the authoring style it was found in — a doubled backslash comes back doubled, so the file stays valid. The same holds for a path embedded in a compound string such as a permission pattern or a hook command (PD-BUG-130), including one whose surrounding literal is escaped while the path itself is not — the path is tracked and rewritten, the command text around it is not. A **directory** inside a compound string is tracked too, but only when it is **quoted** (PD-BUG-131) — the same delimiter rule the markdown, generic, python and PowerShell parsers have always applied to extensionless paths. An *unquoted* directory in a compound value is not a reference; it no longer registers the whole command string as one either, so a value carrying command *syntax* — a parenthesis bound directly to a word (`Bash(`), or a bracket used as a standalone test operator (`[ -d path ]`) — is recognised as a command rather than a path. A filename that merely contains a space and a parenthesis (`assets/img (1).png`) is unaffected.

### PowerShell (.ps1, .psm1)

| Pattern | Example |
|---------|---------|
| Quoted file paths | `"path/file.ps1"` or `'path/file.ps1'` |
| Quoted directory paths | `"path/to/dir"` |
| Embedded markdown links | `[text](path/to/file)` inside strings, including an angle-bracket destination |
| Unquoted paths | In comments and text |
| Block comments | `<# ... #>` content |
| Here-strings | `@"..."@` and `@'...'@` content |

A directory reference must sit inside a **properly paired** pair of delimiters (PD-BUG-135). The gap *between* two literals is not a reference: writing `` `dev.bat dev-setup` / `dev.bat pre-commit` `` no longer registers `" / "` as a directory, and a span that opens on one quote style and closes on another is rejected outright. Pairing is judged per line, so a line whose delimiters genuinely do not balance (an unmatched prose apostrophe, or nested backticks that markdown itself renders as plain text) can lose a reference on that line. In PowerShell the guard is **not confined to directory references**, unlike the markdown and generic parsers above: the same pairing test also gates the parser's general quoted-path pass, which classifies **file** paths (the two scans were merged into one), so an unpaired span is rejected for quoted file paths as well.

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

A directory reference must sit inside a **properly paired** pair of delimiters (PD-BUG-135) — the same rule the markdown and PowerShell parsers apply. The gap *between* two quoted literals is not a reference.

## What Triggers Updates

### File Moves (primary trigger)

Three detection strategies:

1. **Native OS move events** — Direct `FileMovedEvent` from watchdog
2. **Delete+Create correlation** — Windows editors don't emit native move events; DELETE buffered, matched with CREATE within `move_detect_delay` (default 10s) by basename + file size
3. **Directory batch detection** — Windows reports dir deletes as individual file DELETEs; `DirectoryMoveDetector` collects and matches with CREATEs under new parent (up to 300s timeout)

**On move detection, LinkWatcher**:
- Updates all references pointing to the moved file across the entire project
- Updates the database entry for the moved file's own path
- Fixes relative links inside the moved file itself. Each such link is rewritten at the exact
  position it was found, so two links on one line never interfere — previously a markdown link
  could be re-depthed a second time by the pass belonging to a *different* link, silently
  pointing it at another file (PD-BUG-153). For a markdown link whose visible text is exactly
  its target — `[doc/a.md](doc/a.md)` — **both halves** now follow the move, matching what
  LinkWatcher has always done for the same link in any other file. Text that merely resembles
  the target is left alone: the rule is exact equality, so a backtick-wrapped or
  differently-worded label is never rewritten.
- Updates references to directory paths
- **Override-folder virtual-root links** (v2.2): when the moved file lives under a folder configured in `path_resolution_overrides`, host-absolute `/...` references to it from other files in that folder are matched against the folder's virtual root and rewritten, preserving their `/...` style (the blueprint-restructuring use case). References from files outside every override folder are never affected; a rewrite only fires when the resolved target is the actually-moved file and the new target exists on disk. Logged as `update_resolution_override_applied`.

### File Deletions

- Confirmed after `move_detect_delay` with no matching CREATE
- Removes file from internal database

### New File Creation

- Scanned for links if extension is in `monitored_extensions`
- Links added to internal database

### File Modifications

- Edits to existing monitored files (by any tool: editors, scripts, generators) trigger a re-index of that file's links in the internal database
- Database-only — a modification never rewrites files; only moves/renames trigger reference updates
- Ensures links freshly written into an existing file are known when their target later moves (PD-BUG-102)

### Own-Output Exclusion

- The daemon never indexes or reacts to its own output files (PD-BUG-107): when the effective `--log-file` lives in a directory inside the project, that directory is the exclusion zone, announced at startup via the `own_output_excluded` log event
- Covers the active log, timestamp-rotated siblings, and any colocated files (the standard launcher redirects stdout/stderr and writes validation reports into the same directory — keep new daemon outputs colocated to inherit the exclusion)
- If the log file sits directly in the project root, only the log and its rotation siblings are excluded — never the whole project
- If the log file lives outside the project root, nothing is excluded (PD-BUG-109): an outside log can never be scanned or generate events, and excluding its parent directory would swallow the entire watched tree when that directory is an ancestor of the project root
- Log rotation renames are not treated as file moves: documents referencing the stable log path are not rewritten

### Watch Liveness Monitoring (v2.2)

- The daemon verifies that its file system watch is still **delivering events**, not merely that its
  observer thread is alive (PD-BUG-139). A watch can die silently: the observer keeps running while
  the underlying event emitter is gone, and every file move is then missed with no error and no user
  signal.
- Two layers. A lost emitter thread is reported at once as `observer_emitter_died`. A watch that is
  alive but delivering nothing is caught by a probe that runs **only after the tree has been silent**
  for `watch_liveness_idle_seconds`: a sentinel file is written inside the watched tree and must be
  observed within `watch_liveness_probe_timeout`. After `watch_liveness_failure_threshold`
  consecutive misses this is reported as `watch_delivery_stalled`.
- On confirmed failure the daemon **stops** rather than continuing to run blind — a running-but-blind
  daemon gives false assurance that links are being maintained. Restart it (launcher or Control
  Panel) to restore monitoring; the daemon does not re-arm itself.
- **Restarting does not repair what was already missed.** Any file moved during the blind window left
  its references stale, and the restarted daemon has no record of it. Run a validation scan
  (`--validate`, or the Control Panel's validation action) after any such stop to find them; both
  error messages say so.
- A single missed probe never stops a daemon — `watch_liveness_failure_threshold` is required to be
  at least `2`, and a lower value is rejected at startup as a configuration error. A probe that
  cannot be written is not counted as a delivery failure either. On an active project no probes are
  written at all, because the silence gate is never reached.
- The sentinel is never parsed into the link database, and it does not appear in statistics. It is
  written into the daemon's own log directory when the log lives inside the project (the standard
  launcher layout), which is already excluded from scanning; only when the log sits at the project
  root or outside the project does it fall back to a `.linkwatcher-liveness-probe` dotfile in the
  project root.
- The sentinel does not outlive the daemon (PD-BUG-145). It exists only for the moment of a probe:
  it is deleted as soon as that probe's round trip is decided, so between probes there is no file
  at all. Should a daemon be killed during the brief window a probe is live — the launcher and the
  Control Panel both stop daemons with a hard kill that runs no shutdown code — the next daemon
  sweeps the leftover as it starts. Cleanup cannot rest on shutdown alone for exactly that
  reason: a hard kill runs no Python shutdown code, so the startup sweep is the layer that
  covers a daemon killed mid-probe.
- A **transient error** from the underlying Windows file-observation call (for example a quota
  shortfall) is now surfaced as an error rather than being misread as deletion of the watched
  directory (PD-BUG-141). The daemon still stops — the watch does not survive such an error — but
  the cause is now diagnosable, and the error reaches
  `logs/linkwatcher/LinkWatcherError.txt` with its Windows error code intact.
- Whether the watch root is still there is decided by the directory's **identity**, not by its path
  spelling, so a project watched through a **junction or a `subst` drive** is correctly recognized
  as healthy. A root that is deleted, moved away, or replaced by a different directory at the same
  path is still correctly detected as gone.
- **Limitation**: a watch root that becomes *unreachable* — most plausibly a dropped network share —
  cannot be told apart from a deleted one, so monitoring ends and a `directory_deleted` record is
  written naming the project root. If you see one of those, either the directory really was deleted
  or the connection to it was lost; check that the root is reachable before assuming a deletion.
  Restart the daemon to resume monitoring.

## Validation Mode (`--validate`)

- **Read-only** — no file modifications
- Scans workspace for broken file references
- Writes report to `logs/linkwatcher/LinkWatcherBrokenLinks.txt`
- Exits with code 0 (clean) or 1 (broken links found, or configuration invalid - validated before scanning, same as the daemon)
- Default validated extensions: `.md`, `.yaml`, `.yml`, `.json` (configurable via `validation_extensions`)
- Smart resolution: tries source-file-relative first, falls back to project-root-relative; `/...` links in `path_resolution_overrides` folders resolve against the folder's configured base (same rule the live update path uses)
- Context-aware skipping: code blocks, `<details>` archival sections, table rows, template files, placeholder lines
- Target filtering: URLs, shell commands, glob patterns, regex fragments and template placeholders are not checked. A target containing a **space** is filtered too, but only when it was detected heuristically (backtick spans, bare paths, YAML/JSON values) — a space in an explicit `[text](path)`, `[label]: path` or `<a href="path">` destination is part of the filename and **is** checked (PD-BUG-156)

## What LinkWatcher Does NOT Do

- **Does not only update markdown** — it updates ALL monitored file types including `.py`, `.ps1`, `.yaml`, `.json`, `.dart`, and more
- **Does not only update markdown-style links** — it updates Python imports, quoted paths, bare paths, YAML/JSON values, PowerShell here-strings, Dart imports, and more
- **Does not update external URLs** — `http://`, `https://`, `mailto:`, etc. are skipped
- **Does not validate HTML anchors** — `#section` links not checked against heading IDs
- **Does not interact with git** — operates on disk state only
- **Does not do syntax-aware refactoring** — updates textual matches, not AST-based
- **Does not update prose descriptions surrounding a path** — only the path token itself is rewritten. Trailing English describing the target's behavior (e.g., "with X/Y/Z subcommands" in an index line, or a script's `.DESCRIPTION` block) stays unchanged when the linked artifact gains/loses capabilities. Description drift requires a manual sweep.
- **Does not update package manager references** — `requirements.txt` versions, `package.json` dependencies, etc.
- **Does not re-arm a dead watch by itself** — it detects the condition, reports it, and stops; recovery is by restart
- **Does not create backups by default** — configurable via `create_backups: true`

## Key Configuration Options

Keys referenced by the capability sections above (full schema with all settings and defaults: [Configuration Guide](configuration-guide.md)):

| Setting | Default | Purpose |
|---------|---------|---------|
| `monitored_extensions` | 33 extensions | Which file types to watch |
| `enable_*_parser` | all true | Toggle individual parsers |
| `move_detect_delay` | 10s | Window for delete+create correlation |
| `create_backups` | false | Create `.bak` before updates |
| `dry_run_mode` | false | Preview without modifying |
| `validation_extensions` | `.md`, `.yaml`, `.yml`, `.json` | Extensions for `--validate` |
| `watch_liveness_enabled` | `true` | Detect a watch that has stopped delivering events |
| `watch_liveness_idle_seconds` | 60s | Silence before a liveness probe runs |
| `watch_liveness_probe_timeout` | 10s | How long to wait for the probe event |
| `watch_liveness_failure_threshold` | 3 | Consecutive missed probes before the daemon stops |
| `path_resolution_overrides` | `{}` (empty) | Per-folder resolution base for `/...` links — applies to `--validate` **and** live move/rename updates (e.g. blueprint folders) |

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

- [Quick Reference](quick-reference.md) — CLI options, config, examples
- [Link Validation](link-validation.md) — Validation mode details
- [File Type Quick Fix](file-type-quick-fix.md) — Adding file type monitoring
- [File Type Troubleshooting](troubleshooting-file-types.md) — Detailed file type issues

---

*This handbook is part of the LinkWatcher Product Documentation.*
