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


def parse_session_duration(content: str) -> int | None:
    """Extract session duration in minutes from the overview table."""
    # Match patterns like "Total: ~20 minutes", "Total: 20 minutes", "Total: 20 min"
    match = re.search(r"Total:\s*~?\s*(\d+)\s*min", content)
    if match:
        return int(match.group(1))
    return None


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


def derive_tool_doc_id(name_raw: str) -> tuple[str | None, str]:
    """Derive the canonical tool_doc_id and display name from a tool heading name.

    tool_doc_id is the database key that links ratings to a tool's change history:
    the task ID for a task definition ("New Task Creation (PF-TSK-001)") and the
    FILENAME for everything else — scripts, guides, templates, context maps
    ("New-Task script (New-Task.ps1)"). Both forms are captured from the parens;
    a bare/leading filename name carries its own id inline ("feedback_db.py log-change").
    Returns (tool_doc_id_or_None, display_name_with_parens_stripped).

    Shared by parse_tools (new extraction) and feedback_db.py's backfill subcommand
    (re-derivation of historical NULL rows) so both apply identical rules.
    """
    name_raw = name_raw.strip()
    filename_re = r"[\w.\-]+\.(?:ps1|psm1|py|md|json)"
    paren_pattern = rf"\(({filename_re}|[A-Z]+-[A-Z]+-\d+)\)"
    paren_match = re.search(paren_pattern, name_raw)
    if paren_match:
        display = re.sub(rf"\s*{paren_pattern}\s*", "", name_raw).strip()
        return paren_match.group(1), display
    # Fallback: a heading whose name is (or starts with) a filename carries its
    # tool_doc_id inline — e.g. "New-Task.ps1" or "feedback_db.py log-change".
    file_match = re.match(rf"({filename_re})", name_raw)
    if file_match:
        return file_match.group(1), name_raw
    return None, name_raw


def parse_tools(content: str) -> list[dict]:
    """Extract tool sections with their ratings."""
    tools = []

    # Split on tool headers: ### Tool N: Name or ### Tool N: Name (PF-XXX-NNN)
    tool_pattern = re.compile(r"###\s*Tool\s+\d+:\s*(.+?)(?:\n|$)", re.MULTILINE)
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
        content = filepath.read_text(encoding="utf-8")
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

    duration = parse_session_duration(content)
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
        "session_duration_minutes": duration,
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

    # Expand globs on Windows (shell doesn't expand them)
    files = []
    for pattern in args.files:
        path = Path(pattern)
        if "*" in pattern or "?" in pattern:
            files.extend(sorted(path.parent.glob(path.name)))
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
