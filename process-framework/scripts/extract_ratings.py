#!/usr/bin/env python3
# OWNERSHIP: FWK-FB (FrameworkBuilder) - canonical at FrameworkBuilder; anywhere else a received copy. Edit only at the owning workspace. An agent may only modify files its workspace owns.
"""Extract ratings from feedback form markdown files for feedback_db.py record.

Parses feedback form markdown and outputs JSON matching the
feedback-db-input-template.json schema, ready for:
    python process-framework/scripts/feedback_db.py record --json output.json

Also hosts the shared artifact-key resolver (resolve_artifact_key / resolve_artifact_cell —
PF-PRO-072 Phase 4) that validates the improvement tracker's Artifacts column and backs
`feedback_db.py resolve-key`: portable ID, unique filename, path-qualified skill file, bare
skill name, directory token, and the closed class:<name> vocabulary (ARTIFACT_CLASS_TOKENS).

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
    "PF-DOC", "PF-FST", "PF-GDE", "PF-INF", "PF-MAI", "PF-MTH", "PF-TEM", "PF-TSK", "PF-VIS",
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
                sorted(k for k in data.get("prefixes", {}) if re.fullmatch(r"[A-Z]{2,4}-[A-Z]{3}", k))
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


# --- Artifact-key resolution for the tracker's Artifacts column (PF-PRO-072 Phase 4) ---
#
# The central improvement tracker's Artifacts column carries the SAME keys the ratings DB
# uses (tool_doc_id form), so a row's predicted targets and the logged change history stay
# joinable — but a key is validated against the tree on WRITE, which the DB's own write-side
# resolver never did (25 junk keys measured at proposal time). Never free prose. Kinds:
#
#   artifact   a portable framework ID (PF-TSK-009) or, for an ID-less artifact, its filename
#              (Update-ProcessImprovement.ps1), path-qualified by the shortest trailing path
#              that disambiguates a shared basename (imp-triage/SKILL.md); a bare craft-skill
#              name resolves to its SKILL.md
#   directory  a trailing-slash directory that exists (tasks/support/, languages-config/)
#   class      class:<name> from ARTIFACT_CLASS_TOKENS — the closed cross-cutting vocabulary
#   literal    '—' (no target recorded yet — Intake and pilots) and 'TBD' (no decidable target)
#
# Two index tiers, consulted in order: the FRAMEWORK tier (process-framework/ plus the
# craft-skill roots) and, only when it has no hit, the WORKSPACE tier (test/, doc/, the central
# trackers, root operating files). A fixture copy of a script under test/ therefore never makes
# the real one ambiguous, while an FB-level test suite or a root CLAUDE.md is still resolvable.
# Ambiguity within a tier is refused with candidates — the caller retypes a qualified form.

ARTIFACT_CLASS_TOKENS: dict[str, str] = {
    # token -> what it covers (informational; membership is the validation)
    "class:core-files": "the budgeted core files (core-file-budgets.json: tasks/**, guides/**, operating files)",
    "class:task-definitions": "tasks/**/*.md",
    "class:support-tasks": "tasks/support/*.md",
    "class:craft-skills": ".claude/skills/*/** (SKILL.md and references/)",
    "class:guides": "guides/**/*.md",
    "class:templates": "templates/**/*",
    "class:creation-scripts": "scripts/file-creation/**/*.ps1",
    "class:validation-scripts": "scripts/validation/*.ps1",
    "class:helpers": "scripts/Common-ScriptHelpers/*.psm1",
    "class:tests": "test/**/*.Tests.ps1",
}

ARTIFACT_LITERALS = ("—", "TBD")
_LITERAL_ALIASES = {"-": "—", "--": "—", "tbd": "TBD"}

# Directories never indexed: VCS/runtime residue, archived material, and sandboxes. A nested
# workspace (a directory carrying doc/project-config.json with a project name — a child, a
# synthetic E2E producer, a rollout seed) is pruned by that test, not by name.
_INDEX_PRUNE_DIRS = frozenset(
    {".git", "node_modules", "__pycache__", ".pytest_cache", "logs", "old", "sandboxes", ".locks"}
)
# Fixture subtrees by naming convention: sandbox centrals and synthetic workspaces (E2E cases,
# unit fixtures) carry copies of every tracker and script; indexing them would make the real
# artifact ambiguous. The E2E case directory itself stays indexed (a directory token can name it).
_INDEX_PRUNE_NAME_RE = re.compile(r"^(sandbox|synthetic)")
_E2E_CASE_CHILDREN = frozenset({"expected", "project"})
_artifact_index_cache: list[dict] | None = None


def _index_workspace_root() -> Path | None:
    """Nearest ancestor of the framework root carrying a doc/project-config.json with a project
    name — the same test feedback_db's _find_workspace_root applies, so an unfilled blueprint
    seed (empty name) is skipped. None when no such ancestor exists (a detached copy)."""
    current = _FRAMEWORK_ROOT
    while current != current.parent:
        if _is_named_workspace(current):
            return current
        current = current.parent
    return None


def _is_named_workspace(directory: Path) -> bool:
    cfg = directory / "doc" / "project-config.json"
    if not cfg.is_file():
        return False
    try:
        return bool(json.loads(cfg.read_text(encoding="utf-8")).get("project", {}).get("name"))
    except (OSError, ValueError):
        return False


def _walk_tree(root: Path, *, skip_roots: list[Path], prune_feedback: bool) -> tuple[dict, set]:
    """Return ({relpath: Path}, {reldir + '/'}) for every file/dir under root, pruning
    _INDEX_PRUNE_DIRS, nested named workspaces, any of skip_roots, and (workspace tier only)
    the central feedback/ tree — thousands of forms that are never change targets."""
    files: dict[str, Path] = {}
    dirs: set[str] = set()
    skip = {p.resolve() for p in skip_roots}
    stack = [root]
    while stack:
        current = stack.pop()
        try:
            entries = sorted(current.iterdir(), key=lambda p: p.name)
        except OSError:
            continue
        for entry in entries:
            if entry.is_dir():
                if entry.name in _INDEX_PRUNE_DIRS or _INDEX_PRUNE_NAME_RE.match(entry.name):
                    continue
                if entry.name in _E2E_CASE_CHILDREN and entry.parent.name.startswith("TE-E2E-"):
                    continue
                if entry.resolve() in skip:
                    continue
                if entry != root and _is_named_workspace(entry):
                    continue
                if prune_feedback and entry.name == "feedback" and entry.parent.name == "process-framework-central":
                    continue
                dirs.add(entry.relative_to(root).as_posix() + "/")
                stack.append(entry)
            elif entry.is_file():
                files[entry.relative_to(root).as_posix()] = entry
    return files, dirs


def build_artifact_index() -> list[dict]:
    """The two index tiers, framework first. Each tier: {'label', 'files', 'dirs', 'basenames'}."""
    global _artifact_index_cache
    if _artifact_index_cache is not None:
        return _artifact_index_cache

    ws_root = _index_workspace_root()
    # Framework tier roots: the framework tree, then every craft-skill root this level can see —
    # the skills beside the framework tree (a consumer face) and the workspace's root / producer
    # skill sets (FB's canonical set lives at blueprint/.claude/skills). De-duplicated by path.
    skill_roots: list[Path] = []
    for candidate in (
        _FRAMEWORK_ROOT.parent / ".claude" / "skills",
        (ws_root / ".claude" / "skills") if ws_root else None,
        (ws_root / "blueprint" / ".claude" / "skills") if ws_root else None,
    ):
        if candidate and candidate.is_dir() and candidate.resolve() not in {r.resolve() for r in skill_roots}:
            skill_roots.append(candidate)

    framework_files: dict[str, Path] = {}
    framework_dirs: set[str] = set()
    for root in [_FRAMEWORK_ROOT, *skill_roots]:
        f, d = _walk_tree(root, skip_roots=[], prune_feedback=False)
        for rel, path in f.items():
            framework_files.setdefault(rel, path)
        framework_dirs |= d
    # Accepted (and stripped) leading path forms per tier: the tree's own directory name, as an
    # author who copies a path from the workspace root would type it. The first entry is also the
    # qualifier for a root-level file whose basename is shared (process-framework/README.md).
    framework_prefixes = [
        f"{_FRAMEWORK_ROOT.name}/",
        f"blueprint/{_FRAMEWORK_ROOT.name}/",
        ".claude/skills/",
        "blueprint/.claude/skills/",
    ]
    tiers = [_make_tier("framework", framework_files, framework_dirs, framework_prefixes)]

    if ws_root is not None:
        f, d = _walk_tree(ws_root, skip_roots=[_FRAMEWORK_ROOT, *skill_roots], prune_feedback=True)
        tiers.append(_make_tier("workspace", f, d, [f"{ws_root.name}/"]))

    _artifact_index_cache = tiers
    return tiers


def _make_tier(label: str, files: dict[str, Path], dirs: set[str], prefixes: list[str]) -> dict:
    basenames: dict[str, list[str]] = {}
    for rel in files:
        basenames.setdefault(rel.rsplit("/", 1)[-1], []).append(rel)
    return {"label": label, "files": files, "dirs": dirs, "basenames": basenames, "prefixes": prefixes}


def _strip_tier_prefix(key: str, tier: dict) -> str | None:
    """The key with one of the tier's accepted leading path forms removed, or None when it
    carries none (a bare or suffix-form key, matched by suffix instead)."""
    for prefix in tier["prefixes"]:
        if key.startswith(prefix):
            return key[len(prefix):]
    return None


def _shortest_unique_suffix(relpath: str, population, tier: dict | None = None) -> str:
    """The convention's canonical form for a shared basename: the shortest trailing path that
    names exactly one file in the population (imp-triage/SKILL.md, unit/README.md). A root-level
    file that shares its basename with a deeper one has no parent segment to qualify with, so it
    takes the tree's own name (process-framework/README.md, FrameworkBuilder/CLAUDE.md)."""
    parts = relpath.split("/")
    for n in range(1, len(parts)):
        suffix = "/".join(parts[-n:])
        hits = [p for p in population if p == suffix or p.endswith("/" + suffix)]
        if len(hits) == 1:
            return suffix
    if len(parts) > 1:
        return relpath  # the full path is exact-matched first on lookup, so it is unambiguous
    if tier and tier["prefixes"]:
        return tier["prefixes"][0] + relpath
    return relpath


def _strip_leading_dot_slash(key: str) -> str:
    while key.startswith("./"):
        key = key[2:]
    return key.lstrip("/")


def _suffix_hits(key: str, population) -> list[str]:
    return [p for p in population if p == key or p.endswith("/" + key)]


def _result(raw, *, ok, canonical=None, kind=None, path=None, error=None, candidates=None) -> dict:
    return {
        "raw": raw,
        "ok": ok,
        "canonical": canonical,
        "kind": kind,
        "path": path,
        "error": error,
        "candidates": sorted(candidates or []),
    }


def resolve_artifact_key(raw: str) -> dict:
    """Resolve ONE Artifacts-column key to its canonical form, or refuse it with a reason.

    Returns {'raw', 'ok', 'canonical', 'kind', 'path', 'error', 'candidates'}; kind is one of
    literal | class | directory | id | file | skill. Never guesses: an ambiguous basename lists
    its candidates (shortest unique suffixes) and a portable ID absent from this tree is refused
    — a typo, or another workspace's artifact, whose row belongs in that workspace's tracker.
    """
    key = (raw or "").strip()
    if not key:
        return _result(raw, ok=False, error="empty key — pass an artifact key, '—', or 'TBD'")
    key = _LITERAL_ALIASES.get(key.lower(), key) if key.lower() in _LITERAL_ALIASES else key
    if key in ARTIFACT_LITERALS:
        return _result(raw, ok=True, canonical=key, kind="literal")

    if key.startswith("class:"):
        if key in ARTIFACT_CLASS_TOKENS:
            return _result(raw, ok=True, canonical=key, kind="class")
        return _result(
            raw, ok=False,
            error="unknown class token — the closed vocabulary is: " + ", ".join(sorted(ARTIFACT_CLASS_TOKENS)),
            candidates=list(ARTIFACT_CLASS_TOKENS),
        )

    tiers = build_artifact_index()

    if key.endswith("/"):
        norm = _strip_leading_dot_slash(key)
        for tier in tiers:
            stripped = _strip_tier_prefix(norm, tier)
            if stripped is not None and stripped in tier["dirs"]:
                return _result(raw, ok=True, canonical=stripped, kind="directory", path=stripped)
            if norm in tier["dirs"]:
                return _result(raw, ok=True, canonical=norm, kind="directory", path=norm)
            hits = [d for d in tier["dirs"] if d.endswith("/" + norm)]
            if len(hits) == 1:
                return _result(raw, ok=True, canonical=norm, kind="directory", path=hits[0])
            if len(hits) > 1:
                return _result(
                    raw, ok=False, kind="directory",
                    error=f"ambiguous directory token — {len(hits)} directories end in '{norm}'; use a longer trailing path",
                    candidates=[_shortest_unique_suffix(h.rstrip("/"), [x.rstrip("/") for x in tier["dirs"]], tier) + "/" for h in hits],
                )
        return _result(raw, ok=False, kind="directory", error="no such directory in the framework or workspace tree")

    if re.fullmatch(r"[A-Z]{2,4}-[A-Z]{3}-\d+", key):
        if not is_portable_id(key):
            return _result(
                raw, ok=False, kind="id",
                error="not a portable framework ID (a project-instance pool) — name the blueprint template or script instead",
            )
        index = build_id_index()
        paths = sorted(p for p, doc_id in index.items() if doc_id == key and "/" in p)
        if paths:
            return _result(raw, ok=True, canonical=key, kind="id", path=paths[0])
        return _result(
            raw, ok=False, kind="id",
            error="portable ID not found in this framework tree — a typo, or another workspace's artifact (its row belongs in that workspace's tracker)",
        )

    norm = _strip_leading_dot_slash(key)
    if "/" in norm:
        for tier in tiers:
            stripped = _strip_tier_prefix(norm, tier)
            if stripped is not None and stripped in tier["files"]:
                return _file_result(raw, stripped, tier)
            if norm in tier["files"]:
                return _file_result(raw, norm, tier)
            hits = _suffix_hits(norm, tier["files"])
            if len(hits) == 1:
                return _file_result(raw, hits[0], tier)
            if len(hits) > 1:
                return _result(
                    raw, ok=False, kind="file",
                    error=f"ambiguous path — {len(hits)} files end in '{norm}'; use one of the candidates",
                    candidates=[_shortest_unique_suffix(h, tier["files"], tier) for h in hits],
                )
        return _result(raw, ok=False, kind="file", error="no such file in the framework or workspace tree")

    for tier in tiers:
        hits = tier["basenames"].get(norm, [])
        if len(hits) == 1:
            return _file_result(raw, hits[0], tier)
        if len(hits) > 1:
            return _result(
                raw, ok=False, kind="file",
                error=f"ambiguous basename — {len(hits)} files are named '{norm}'; use one of the candidates",
                candidates=[_shortest_unique_suffix(h, tier["files"], tier) for h in hits],
            )
        # A bare craft-skill name stands for its entry file (imp-triage -> imp-triage/SKILL.md).
        if "." not in norm and f"{norm}/SKILL.md" in tier["files"]:
            return _result(raw, ok=True, canonical=f"{norm}/SKILL.md", kind="skill", path=f"{norm}/SKILL.md")
    return _result(
        raw, ok=False, kind="file",
        error="not found — no file, directory token or class token by that name (keys are never free prose)",
    )


def _file_result(raw: str, relpath: str, tier: dict) -> dict:
    """Canonical key for a resolved file: its portable ID when it carries one (the convention's
    ID-first rule), else the shortest unique trailing path — bare when the basename is unique."""
    doc_id = resolve_artifact_id(relpath)
    if doc_id:
        return _result(raw, ok=True, canonical=doc_id, kind="id", path=relpath)
    canonical = _shortest_unique_suffix(relpath, tier["files"], tier)
    kind = "skill" if canonical.endswith("/SKILL.md") else "file"
    return _result(raw, ok=True, canonical=canonical, kind=kind, path=relpath)


def resolve_artifact_cell(cell: str) -> dict:
    """Resolve a whole Artifacts cell ('key; key; ...'): every key resolved, duplicates dropped,
    literals refused when mixed with keys. Returns {'ok', 'canonical', 'keys': [per-key dicts]}."""
    raws = [k.strip() for k in (cell or "").split(";")]
    raws = [k for k in raws if k]
    if not raws:
        return {"ok": False, "canonical": None, "keys": [_result(cell, ok=False, error="empty Artifacts value — pass one or more keys, '—', or 'TBD'")]}
    results = []
    seen: set[str] = set()
    for r in raws:
        res = resolve_artifact_key(r)
        if res["ok"] and res["canonical"] in seen:
            continue
        if res["ok"]:
            seen.add(res["canonical"])
        results.append(res)
    if len(results) > 1 and any(r["ok"] and r["kind"] == "literal" for r in results):
        for r in results:
            if r["ok"] and r["kind"] == "literal":
                r["ok"] = False
                r["error"] = "a literal ('—' / 'TBD') cannot be combined with artifact keys"
    ok = all(r["ok"] for r in results)
    canonical = "; ".join(r["canonical"] for r in results) if ok else None
    return {"ok": ok, "canonical": canonical, "keys": results}


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
