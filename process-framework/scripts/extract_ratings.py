#!/usr/bin/env python3
"""Extract ratings from feedback form markdown files for feedback_db.py record.

Parses feedback form markdown and outputs JSON matching the
feedback-db-input-template.json schema, ready for:
    python process-framework/scripts/feedback_db.py record --json output.json

Usage (Phase 7 / centralized layout, 2026-05-11+):
    # Single file (resolved against the central feedback-forms directory)
    python process-framework/scripts/extract_ratings.py \\
        appdev/process-framework-central/feedback/feedback-forms/form1.md

    # Multiple files
    python process-framework/scripts/extract_ratings.py \\
        appdev/process-framework-central/feedback/feedback-forms/*.md

    # With review cycle ID and archived path prefix
    python process-framework/scripts/extract_ratings.py \\
        --review-cycle-id tools-review-20260403 \\
        --archived-prefix \\
            "appdev/process-framework-central/feedback/archive/\\
            2026-04/tools-review-20260403/processed-forms" \\
        appdev/process-framework-central/feedback/feedback-forms/*.md

    # Output to file
    python process-framework/scripts/extract_ratings.py \\
        appdev/process-framework-central/feedback/feedback-forms/*.md -o ratings.json

    # Pipe directly to feedback_db.py
    python process-framework/scripts/extract_ratings.py \\
        appdev/process-framework-central/feedback/feedback-forms/*.md | \\
        python process-framework/scripts/feedback_db.py record --json -
"""

import argparse
import json
import re
import sys
from pathlib import Path


def parse_frontmatter(content: str) -> dict:
    """Extract YAML frontmatter fields as a dict."""
    match = re.match(r"---\s*\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return {}
    fields = {}
    for line in match.group(1).splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            fields[key.strip()] = value.strip()
    return fields


def parse_task_level_ratings(content: str) -> tuple[int | None, int | None]:
    """Extract Overall Process Effectiveness and Process Conciseness ratings."""
    effectiveness = None
    conciseness = None

    # Overall Process Effectiveness
    match = re.search(
        r"###\s*Overall Process Effectiveness.*?\*\*Rating \(1-5\)\*\*:\s*(\d+)",
        content,
        re.DOTALL,
    )
    if match:
        effectiveness = int(match.group(1))

    # Process Conciseness
    match = re.search(
        r"###\s*Process Conciseness.*?\*\*Rating \(1-5\)\*\*:\s*(\d+)",
        content,
        re.DOTALL,
    )
    if match:
        conciseness = int(match.group(1))

    return effectiveness, conciseness


def parse_rating_value(text: str) -> int | None:
    """Parse a rating value, returning None for N/A."""
    text = text.strip()
    if text.upper() == "N/A" or not text:
        return None
    try:
        return int(text)
    except ValueError:
        return None


# --- Portable framework ID pools (PF-IMP-1691) --------------------------------
#
# tool_doc_id keys the cross-project ratings DB, so a key must be globally
# unique AND stable. Only IDs allocated from the rolled-out PF-id-registry.json
# qualify: those prefixes mean the same artifact in every project. Project-local
# pools (PF-STA/PF-TMP, PD-*, TE-*) do not — PF-STA-004 already denotes two
# different files in two projects — and their artifacts are project instances
# rather than framework tools, so they are keyed by their generating blueprint
# template instead (resolved via feedback_db's alias table, not here).
_FRAMEWORK_ROOT = Path(__file__).resolve().parent.parent
_PORTABLE_PREFIX_FALLBACK = (
    "PF-DOC",
    "PF-FST",
    "PF-GDE",
    "PF-INF",
    "PF-MAI",
    "PF-MTH",
    "PF-TEM",
    "PF-TSK",
    "PF-VIS",
)
_portable_prefixes_cache: tuple[str, ...] | None = None
_id_index_cache: dict[str, str] | None = None

FILENAME_RE = r"(?:[\w.\-]+/)*[\w.\-]+\.(?:ps1|psm1|py|md|json|yaml|yml)"


def portable_prefixes() -> tuple[str, ...]:
    """Portable ID prefixes, read from the rolled-out PF-id-registry.json.

    Read from the registry rather than hardcoded so a newly added framework pool
    is portable the day it exists. Falls back to the known set if the registry is
    unreadable (e.g. extraction run from outside a framework tree).
    """
    global _portable_prefixes_cache
    if _portable_prefixes_cache is None:
        found: tuple[str, ...] = ()
        try:
            data = json.loads((_FRAMEWORK_ROOT / "PF-id-registry.json").read_text(encoding="utf-8"))
            found = tuple(
                sorted(
                    k for k in data.get("prefixes", {}) if re.fullmatch(r"[A-Z]{2,4}-[A-Z]{3}", k)
                )
            )
        except Exception:
            pass
        _portable_prefixes_cache = found or _PORTABLE_PREFIX_FALLBACK
    return _portable_prefixes_cache


def is_portable_id(value: str) -> bool:
    """True if value is an ID from a portable framework pool (e.g. PF-GDE-068)."""
    match = re.fullmatch(r"([A-Z]{2,4}-[A-Z]{3})-\d+", value or "")
    return bool(match) and match.group(1) in portable_prefixes()


def build_id_index() -> dict[str, str]:
    """Map every framework artifact's filename to its portable ID, from its own frontmatter.

    Scanned rather than maintained by hand: a new guide is resolvable the day it
    exists, and a rename carries its ID along. Both the basename and the tree-relative
    path are indexed; a basename claimed by two different IDs is dropped as ambiguous
    (the path key still resolves it). Artifacts that no longer exist are unreachable
    here by construction — retired-artifact keys live in feedback_db's alias table.
    """
    global _id_index_cache
    if _id_index_cache is not None:
        return _id_index_cache
    index: dict[str, str] = {}
    ambiguous: set[str] = set()
    # Framework-shipped artifacts are not all under process-framework/: the PF-FST
    # state trackers ship in doc/ and framework test material in test/. Scanning the
    # siblings too is safe because is_portable_id filters out the project-local
    # PD-*/TE-* IDs those trees otherwise carry.
    roots = [_FRAMEWORK_ROOT, _FRAMEWORK_ROOT.parent / "doc", _FRAMEWORK_ROOT.parent / "test"]
    for root in roots:
        if not root.is_dir():
            continue
        for path in root.rglob("*.md"):
            try:
                head = path.read_text(encoding="utf-8", errors="ignore")[:800]
            except OSError:
                continue
            match = re.search(r"^id:\s*([A-Z]{2,4}-[A-Z]{3}-\d+)\s*$", head, re.MULTILINE)
            if not match or not is_portable_id(match.group(1)):
                continue
            doc_id = match.group(1)
            index[path.relative_to(root.parent).as_posix()] = doc_id
            base = path.name
            if base in index and index[base] != doc_id:
                ambiguous.add(base)
            else:
                index[base] = doc_id
    for base in ambiguous:
        index.pop(base, None)
    _id_index_cache = index
    return index


def resolve_artifact_id(filename: str) -> str | None:
    """Portable ID for a filename, or None when the artifact carries no ID."""
    index = build_id_index()
    return index.get(filename) or index.get(filename.split("/")[-1])


def derive_tool_doc_id(name_raw: str) -> tuple[str | None, str]:
    """Derive the canonical tool_doc_id and display name from a tool heading name.

    tool_doc_id is the database key that links ratings to a tool's change history.
    It is the **portable framework ID of the blueprint artifact being rated**
    ("Process Improvement (PF-TSK-009)", "PF-GDE-068 reference guide"), and the
    FILENAME only when that artifact carries no ID — scripts, craft skills,
    companion path files, READMEs ("New-Task script (New-Task.ps1)"),
    path-qualified when the non-unique-basename rule applies ("imp-triage/SKILL.md",
    "unit/README.md"). A heading naming an ID-carrying artifact by filename resolves
    to its ID via the frontmatter index, so the stored key does not depend on which
    form the author happened to write (PF-IMP-1691).

    Resolution order — ID forms first, so a heading carrying both wins on the ID:
      1. portable ID alone in parens        "Process Improvement (PF-TSK-009)"
      2. portable ID at heading start       "PF-TSK-009 Task Definition"
      3. filename in parens  -> ID if any   "reference (…-guide.md)" -> PF-GDE-068
      4. filename at start   -> ID if any   "feedback_db.py log-change"
      5. bare skill in parens               "… craft skill (imp-triage)" -> imp-triage/SKILL.md

    Returns (tool_doc_id_or_None, display_name_with_parens_stripped). A None result
    is not a failure to be papered over — it marks a heading no rule identifies, which
    feedback_db's alias table resolves (retired artifacts, historical junk keys, prose
    names) and the audit surfaces when nothing does.

    Shared by parse_tools (new extraction) and feedback_db.py's backfill subcommand
    (re-derivation of historical NULL rows) so both apply identical rules.
    """
    name_raw = name_raw.strip()
    # Strip the feedback-form template's optional-section marker if an author left it on the
    # heading line — e.g. "New-Task.ps1 *(Optional)*" or "... *(Optional — PF-IMP-1290)*". It is
    # a template artifact, not part of the tool name (PF-IMP-1452). tool_doc_id is unaffected (the
    # marker's parens never match the id pattern), but the display tool_name inherited it verbatim.
    name_raw = re.sub(r"\s*\*\(Optional[^)]*\)\*\s*$", "", name_raw).strip()

    # (1) A portable ID alone in parens — the canonical modern form.
    id_paren_pattern = r"\(([A-Z]{2,4}-[A-Z]{3}-\d+)\)"
    id_paren = re.search(id_paren_pattern, name_raw)
    if id_paren and is_portable_id(id_paren.group(1)):
        display = re.sub(rf"\s*{id_paren_pattern}\s*", " ", name_raw).strip()
        return id_paren.group(1), display

    # (2) A portable ID at the heading start — the legacy form used through ~2026-05
    #     ("PF-TSK-009 (Process Improvement task definition)"). Anchored, so an ID
    #     mentioned mid-heading as context never claims the row.
    leading_id = re.match(r"([A-Z]{2,4}-[A-Z]{3}-\d+)\b", name_raw)
    if leading_id and is_portable_id(leading_id.group(1)):
        return leading_id.group(1), name_raw

    # (3)/(4) Filename forms — resolved to the artifact's ID when it carries one.
    #     Optional leading path segments admit the convention's qualified forms
    #     ("process-improvement/SKILL.md"); a slash was previously outside the
    #     class, so every craft-skill rating derived None (PF-IMP-1690).
    file_paren_pattern = rf"\(({FILENAME_RE})\)"
    file_paren = re.search(file_paren_pattern, name_raw)
    if file_paren:
        filename = file_paren.group(1)
        display = re.sub(rf"\s*{file_paren_pattern}\s*", " ", name_raw).strip()
        return resolve_artifact_id(filename) or filename, display
    file_match = re.match(rf"({FILENAME_RE})", name_raw)
    if file_match:
        filename = file_match.group(1)
        return resolve_artifact_id(filename) or filename, name_raw

    # (5) Last-resort fallback: a skill heading naming the skill bare in parens. Fires
    # only when the heading mentions "skill" and the parens hold a lone kebab-case
    # token (≥1 hyphen, no dot), so "New-Task.ps1 (dry-run)" (leading filename wins
    # above) and "update-config (skill)" (no hyphen) never reach it (PF-IMP-1690).
    # Craft skills carry no ID, so the filename form is canonical for them.
    if re.search(r"skill", name_raw, re.IGNORECASE):
        skill_pattern = r"\(([a-z][a-z0-9]*(?:-[a-z0-9]+)+)\)"
        skill_match = re.search(skill_pattern, name_raw)
        if skill_match:
            display = re.sub(rf"\s*{skill_pattern}\s*", " ", name_raw).strip()
            return f"{skill_match.group(1)}/SKILL.md", display
    return None, name_raw


def parse_tools(content: str) -> list[dict]:
    """Extract tool sections with their ratings."""
    tools = []

    # Split on tool headers: ### Tool N: Name or ### Tool N: Name (PF-XXX-NNN).
    # Anchored to line start so inline examples quoting "### Tool 1: ..." mid-line
    # (the template's tool_doc_id blurb) cannot match as phantom tools (PF-IMP-1076).
    tool_pattern = re.compile(r"^###\s*Tool\s+\d+:\s*(.+?)(?:\n|$)", re.MULTILINE)
    tool_matches = list(tool_pattern.finditer(content))

    if not tool_matches:
        return tools

    for i, match in enumerate(tool_matches):
        start = match.start()
        end = tool_matches[i + 1].start() if i + 1 < len(tool_matches) else len(content)
        section = content[start:end]

        tool_doc_id, tool_name = derive_tool_doc_id(match.group(1))

        # Extract each rating dimension — handles both ### and #### headers
        ratings = {}
        for dimension in ("Effectiveness", "Clarity", "Completeness", "Efficiency", "Conciseness"):
            dim_match = re.search(
                rf"#{{2,4}}\s*{dimension}.*?\*\*Rating \(1-5\)\*\*:\s*(\S+)",
                section,
                re.DOTALL,
            )
            if dim_match:
                ratings[dimension.lower()] = parse_rating_value(dim_match.group(1))
            else:
                ratings[dimension.lower()] = None

        tool_entry = {
            "tool_name": tool_name,
            **ratings,
        }
        if tool_doc_id is not None:
            tool_entry["tool_doc_id"] = tool_doc_id
        tools.append(tool_entry)

    return tools


def extract_form(
    filepath: Path, review_cycle_id: str | None = None, archived_prefix: str | None = None
) -> dict | None:
    """Extract all ratings from a single feedback form file."""
    try:
        # utf-8-sig, not utf-8: a leading BOM survives a plain utf-8 decode as
        # U+FEFF at position 0, which defeats parse_frontmatter's anchored
        # re.match and drops the whole form with only a WARNING (PF-IMP-1739).
        content = filepath.read_text(encoding="utf-8-sig")
    except Exception as e:
        print(f"WARNING: Could not read {filepath}: {e}", file=sys.stderr)
        return None

    frontmatter = parse_frontmatter(content)
    if not frontmatter:
        print(f"WARNING: No frontmatter in {filepath.name}, skipping", file=sys.stderr)
        return None

    task_id = frontmatter.get("document_id", "")
    if not task_id:
        print(f"WARNING: No document_id in {filepath.name}, skipping", file=sys.stderr)
        return None

    # Build form_id from filename (without .md)
    form_id = filepath.stem

    # Form date from frontmatter or filename
    form_date = frontmatter.get("created", "")
    if not form_date:
        date_match = re.match(r"(\d{8})", filepath.stem)
        if date_match:
            d = date_match.group(1)
            form_date = f"{d[:4]}-{d[4:6]}-{d[6:8]}"

    task_context = frontmatter.get("task_context", "")
    feedback_type = frontmatter.get("feedback_type", "MultipleTools")

    effectiveness, conciseness = parse_task_level_ratings(content)
    tools = parse_tools(content)

    # Build archived form path
    archived_form_path = None
    if archived_prefix:
        archived_form_path = f"{archived_prefix}/{filepath.name}"

    # PF-IMP-833 (e): emit per-form project_name from frontmatter so a single record
    # invocation correctly attributes forms spanning multiple projects. When absent,
    # the field is omitted entirely so feedback_db.py record_form() falls back to its
    # instance default (cwd-resolved project) — preserves behavior on pre-frontmatter forms.
    project_name = frontmatter.get("project_name", "").strip()

    result = {
        "form_id": form_id,
        "task_id": task_id,
        "task_context": task_context,
        "feedback_type": feedback_type,
        "form_date": form_date,
        "review_cycle_id": review_cycle_id,
        "archived_form_path": archived_form_path,
        "overall_effectiveness": effectiveness,
        "process_conciseness": conciseness,
        "tools": tools,
    }
    if project_name:
        result["project_name"] = project_name
    return result


def main():
    parser = argparse.ArgumentParser(
        description="Extract ratings from feedback form markdown files for feedback_db.py record",
        epilog="Output can be piped directly: "
        "extract_ratings.py forms/*.md | feedback_db.py record --json -",
    )
    parser.add_argument("files", nargs="+", help="Feedback form markdown file(s)")
    parser.add_argument(
        "--review-cycle-id",
        help="Review cycle identifier (e.g., tools-review-20260403)",
    )
    parser.add_argument(
        "--archived-prefix",
        help="Path prefix for archived forms "
        "(e.g., appdev/process-framework-central/feedback/archive/2026-04/...)",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Output file path (default: stdout)",
    )
    args = parser.parse_args()

    # Expand globs on Windows (shell doesn't expand them); a directory argument
    # auto-globs its *.md forms (PF-IMP-994 — previously surfaced as an
    # uninformative "Permission denied" read error).
    files = []
    for pattern in args.files:
        path = Path(pattern)
        if "*" in pattern or "?" in pattern:
            files.extend(sorted(path.parent.glob(path.name)))
        elif path.is_dir():
            md_files = sorted(path.glob("*.md"))
            if not md_files:
                print(f"WARNING: No .md files in directory: {path}", file=sys.stderr)
            else:
                print(
                    f"Expanded directory {path} to {len(md_files)} .md file(s)",
                    file=sys.stderr,
                )
            files.extend(md_files)
        else:
            files.append(path)

    results = []
    for filepath in files:
        if not filepath.exists():
            print(f"WARNING: File not found: {filepath}", file=sys.stderr)
            continue
        form = extract_form(filepath, args.review_cycle_id, args.archived_prefix)
        if form:
            results.append(form)

    output = json.dumps(results, indent=2, ensure_ascii=False)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Extracted {len(results)} form(s) to {args.output}", file=sys.stderr)
    else:
        print(output)
        print(f"Extracted {len(results)} form(s)", file=sys.stderr)


if __name__ == "__main__":
    main()
