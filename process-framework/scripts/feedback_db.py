#!/usr/bin/env python3
"""Feedback Ratings Database — Persistent storage for feedback form ratings.

Stores quantified ratings from feedback forms in a SQLite database,
enabling trend analysis across Tools Review cycles.

Usage:
    python process-framework/scripts/feedback_db.py init
    python process-framework/scripts/feedback_db.py record --json forms.json
    python process-framework/scripts/feedback_db.py log-change \\
        --tool PF-TSK-009 --date 2026-02-26 --imp IMP-038 \\
        --description "Streamlined from 27 to 14 steps"
    python process-framework/scripts/feedback_db.py list-changes --imp PF-IMP-038
    python process-framework/scripts/feedback_db.py query --task PF-TSK-009
    python process-framework/scripts/feedback_db.py query --tool PF-TSK-007
    python process-framework/scripts/feedback_db.py query --all
    python process-framework/scripts/feedback_db.py list-tools
    python process-framework/scripts/feedback_db.py list-tools --filter integration
    python process-framework/scripts/feedback_db.py list-ratings --tool New-Task.ps1
    python process-framework/scripts/feedback_db.py list-ratings --tool New-Task.ps1 --all-projects
    python process-framework/scripts/feedback_db.py report
    python process-framework/scripts/feedback_db.py report --task PF-TSK-009
    python process-framework/scripts/feedback_db.py alerts
    python process-framework/scripts/feedback_db.py alerts --threshold 2.5 --min-ratings 5
    python process-framework/scripts/feedback_db.py consolidate-tools --dry-run
    python process-framework/scripts/feedback_db.py consolidate-tools
    python process-framework/scripts/feedback_db.py backfill-tool-doc-ids --dry-run
    python process-framework/scripts/feedback_db.py backfill-tool-doc-ids
    python process-framework/scripts/feedback_db.py backfill-tool-doc-ids --all-projects
    python process-framework/scripts/feedback_db.py merge-tool-id --dry-run \\
        --from helpers-reroutes-troubleshooting.md \\
        --to imp-triage/references/helpers-reroutes-troubleshooting.md
    python process-framework/scripts/feedback_db.py trend-changes
    python process-framework/scripts/feedback_db.py trend-changes --min-changes 5 --months 3 --limit 20

Project scoping:
    Writes (record, log-change) stamp rows with the invoking project (from
    doc/project-config.json; --project overrides). Read/repair subcommands split
    by what they treat as identity:
    - Project-scoped (invoking project's rows only): list-tools, list-ratings,
      consolidate-tools, backfill-tool-doc-ids — registration checks and repairs,
      scoped so one project's cleanup cannot touch another's rows; list-ratings
      and backfill-tool-doc-ids accept --all-projects (their logic is
      project-independent).
    - Cross-project (whole DB): query, list-changes, report, alerts,
      trend-changes, merge-tool-id — trend analysis and artifact-identity
      operations: tool_doc_id and task_id name shared framework artifacts, not
      project state.
"""

import argparse
import json
import os
import re
import sqlite3
import sys
from datetime import datetime, timedelta
from pathlib import Path


def _find_workspace_root() -> Path:
    """Walk up from this file to the workspace root — the first ancestor holding a
    doc/project-config.json with a non-empty project.name.

    The name test is what skips appdev's unfilled blueprint/doc/project-config.json
    template, exactly as _resolve_project_name does. Errors are raised, never swallowed:
    a workspace this script cannot locate is a broken checkout, not a reason to guess.
    """
    checked = []
    current = Path(__file__).resolve().parent
    while current != current.parent:
        candidate = current / "doc" / "project-config.json"
        if candidate.exists():
            checked.append(str(candidate))
            try:
                with open(candidate) as f:
                    config = json.load(f)
            except (json.JSONDecodeError, OSError) as exc:
                raise RuntimeError(f"{candidate} exists but could not be read: {exc}") from exc
            if config.get("project", {}).get("name"):
                return current
        current = current.parent
    hint = (
        "  Checked (project.name empty in each):\n" + "\n".join(f"    {p}" for p in checked)
        if checked
        else "  No doc/project-config.json found above script location."
    )
    raise RuntimeError(f"Could not locate the workspace root.\n{hint}")


# Parent-pointer filenames, most-current first (PF-PRO-068 P-5 rename, read-both transition).
# Third implementation of the list — the PowerShell twins live in Core.psm1 and IdRegistry.psm1
# and are pinned identical by ChainWalkParity.Tests.ps1. This one is outside that suite's reach
# (no interop), so it is kept in sync by contract, like the resolution it belongs to.
PARENT_POINTER_NAMES = (".framework-parent-pointer", ".framework-central-pointer")


def _resolve_parent_pointer(fw_dir: Path):
    """Return the parent-pointer file present in fw_dir, or None when neither name exists.

    Accepts both the current and the legacy name for the whole rename transition: a rolled-out
    project can be several rollouts behind, and a rollback can take one back to a pre-rename tag
    at any time. When both names are present and disagree this raises rather than picking one —
    silently preferring either would let two readers resolve different parents.
    """
    found = [fw_dir / name for name in PARENT_POINTER_NAMES if (fw_dir / name).exists()]
    if not found:
        return None
    if len(found) >= 2:
        values = [p.read_text(encoding="utf-8").strip() for p in found]
        if os.path.normcase(os.path.abspath(values[0])) != os.path.normcase(
            os.path.abspath(values[1])
        ):
            raise RuntimeError(
                f"Both parent-pointer names are present in {fw_dir} and they disagree — "
                f"'{PARENT_POINTER_NAMES[0]}' points to '{values[0]}' but "
                f"'{PARENT_POINTER_NAMES[1]}' points to '{values[1]}'. During the rename "
                "transition the rollout writes both with identical content, so a disagreement "
                "means one was hand-edited. Reconcile or delete the stale one."
            )
    return found[0]


def _resolve_own_central(root: Path) -> Path:
    """Return this workspace's governing process-framework-central/ directory.

    Python port of Get-CentralFrameworkPath (Common-ScriptHelpers/Core.psm1), kept in sync
    with it by contract rather than by import — there is no PowerShell interop here:

      - producer face (project_metadata.role 'framework' / 'framework-builder')
            -> the workspace's OWN process-framework-central/
      - leaf ('project', including an absent role)
            -> the parent named by <paths.process_framework>/.framework-central-pointer

    Every failure raises. The no-silent-fallback invariant (PF-PRO-068) applies here
    specifically because the old fallback path — <process-framework>/feedback/ratings.db —
    does not exist in any current layout, so falling back meant creating an EMPTY database
    at a phantom location and reporting success against it.
    """
    config_path = root / "doc" / "project-config.json"
    with open(config_path) as f:
        config = json.load(f)

    role = (config.get("project_metadata") or {}).get("role") or "project"
    if role in ("framework", "framework-builder"):
        return root / "process-framework-central"

    fw_relative = (config.get("paths") or {}).get("process_framework") or "process-framework"
    fw_dir = root / fw_relative
    pointer = _resolve_parent_pointer(fw_dir)
    if pointer is None:
        raise RuntimeError(
            f"No parent pointer found in {fw_dir} (probed "
            f"{' and '.join(PARENT_POINTER_NAMES)}). This workspace has not received a Push "
            "from its parent yet, so central cannot be resolved."
        )
    parent = pointer.read_text(encoding="utf-8").strip()
    if not parent:
        raise RuntimeError(
            f"{pointer} is empty. Re-run the parent's Push-FrameworkUpdate.ps1 to repair."
        )
    central = Path(parent) / "process-framework-central"
    if not central.is_dir():
        raise RuntimeError(
            f"{pointer} points to '{parent}', but the resolved central directory does not "
            f"exist: {central}. The pointer target is stale."
        )
    return central


def _resolve_db_path() -> Path:
    """Resolve the ratings database path: $FRAMEWORK_CENTRAL_OVERRIDE, else OWN CENTRAL.

    Own-central resolution (PF-PRO-068 WI-5) needs no configuration: each workspace's
    ratings live beside its other central instruments, resolved the same way every other
    central write resolves. That is correct at every level — a project's own central IS its
    parent's, so projects keep sharing one DB exactly as before, while a producer face gets
    its own.

    The former `ratings_db_path` domain-config key was RETIRED with this change (owner
    decision, 2026-08-07). It named an absolute machine path, it shipped in a config copied
    into every project, and once resolution is derived it could only ever drift away from
    the answer it was meant to give. Its reader is deleted with it rather than kept as an
    override: keeping the reader would preserve exactly the escape hatch the retirement
    removes. A workspace that genuinely needs its ratings elsewhere gets the env override.

    $FRAMEWORK_CENTRAL_OVERRIDE gives Python the same sandbox-redirect seam the PowerShell
    fleet has, so a hermetic fixture can point both at one directory.

    Nothing here falls back. The pre-retirement code silently degraded to
    <process-framework>/feedback/ratings.db — a path that exists in no current layout — so a
    corrupt config produced a fresh empty database and a run that looked entirely fine.
    """
    override = os.environ.get("FRAMEWORK_CENTRAL_OVERRIDE", "").strip()
    if override:
        if not Path(override).is_dir():
            print(
                f"ERROR: $FRAMEWORK_CENTRAL_OVERRIDE points at a non-existent "
                f"directory: {override}",
                file=sys.stderr,
            )
            sys.exit(1)
        return Path(override) / "feedback" / "ratings.db"

    try:
        central = _resolve_own_central(_find_workspace_root())
    except (RuntimeError, json.JSONDecodeError, OSError) as exc:
        print(
            f"ERROR: could not resolve this workspace's process-framework-central.\n" f"  {exc}",
            file=sys.stderr,
        )
        sys.exit(1)

    db_path = central / "feedback" / "ratings.db"
    if not db_path.parent.exists():
        print(
            f"ERROR: resolved central feedback directory does not exist: "
            f"{db_path.parent}\n"
            f"  Central resolved to: {central}\n"
            f"  Seed the feedback/ directory at that workspace.",
            file=sys.stderr,
        )
        sys.exit(1)
    return db_path


def _resolve_project_name() -> str:
    """Resolve project name from doc/project-config.json.

    Walks up from __file__ looking for doc/project-config.json. Skips candidates whose
    project.name is empty so an unfilled blueprint/doc/project-config.json template
    (in appdev's blueprint/ tree) doesn't false-match before the real config above it.
    """
    checked = []
    current = Path(__file__).resolve().parent
    while current != current.parent:
        candidate = current / "doc" / "project-config.json"
        if candidate.exists():
            checked.append(str(candidate))
            try:
                with open(candidate) as f:
                    config = json.load(f)
                name = config.get("project", {}).get("name")
                if name:
                    return name
            except (json.JSONDecodeError, OSError):
                pass
        current = current.parent
    if checked:
        location_hint = "  Checked (project.name empty in each):\n" + "\n".join(
            f"    {p}" for p in checked
        )
    else:
        location_hint = "  No doc/project-config.json found above script location."
    print(
        "ERROR: Could not resolve project name.\n"
        f"{location_hint}\n"
        "  Ensure doc/project-config.json exists with non-empty project.name.",
        file=sys.stderr,
    )
    sys.exit(1)


def _imp_match_key(value: str):
    """Normalize an IMP reference to its numeric token for matching.

    Stored imp_id values mix historical forms ('IMP-038', 'PF-IMP-038',
    'PF-IMP-833 (b)'); the digits identify the improvement regardless of
    prefix, zero padding, or constituent suffix.
    """
    m = re.search(r"IMP-0*(\d+)", value or "")
    return m.group(1) if m else None


DB_DEFAULT_PATH = _resolve_db_path()

# Historical tool_doc_id drift consolidation mapping (PF-IMP-704).
# Each entry maps a non-canonical tool_doc_id to its canonical form per the
# convention documented in PF-TSK-009's tool-change-logging step: PF-TSK-NNN for task definitions,
# filename (with extension) for everything else.
# Used by the `consolidate-tools` subcommand. Idempotent — re-running after
# consolidation is a no-op because the source IDs no longer exist.
CONSOLIDATION_MAPPING = {
    # Stem (without extension) -> canonical filename
    ".ai-entry-point": ".ai-entry-point.md",
    "Common-ScriptHelpers": "Common-ScriptHelpers.psm1",
    "DOMAIN-CONFIG": "domain-config.json",
    "New-ProcessImprovement": "New-ProcessImprovement.ps1",
    "New-RefactoringPlan": "New-RefactoringPlan.ps1",
    "New-ReviewSummary": "New-ReviewSummary.ps1",
    "TableOperations": "TableOperations.psm1",
    "Update-BugStatus": "Update-BugStatus.ps1",
    "Update-ProcessImprovement": "Update-ProcessImprovement.ps1",
    "Update-TechDebt": "Update-TechDebt.ps1",
    "ai-tasks": "ai-tasks.md",
    "feedback_db": "feedback_db.py",
    "test-file-creation-guide": "test-file-creation-guide.md",
    "test-infrastructure-guide": "test-infrastructure-guide.md",
    # Wrong-convention task entry (filename) -> task ID
    "test-audit-task.md": "PF-TSK-030",
}

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS feedback_forms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT NOT NULL,
    form_id TEXT NOT NULL,
    task_id TEXT NOT NULL,
    task_context TEXT,
    feedback_type TEXT NOT NULL,
    form_date TEXT NOT NULL,
    session_duration_minutes INTEGER,
    review_cycle_id TEXT,
    archived_form_path TEXT,
    overall_effectiveness INTEGER CHECK(overall_effectiveness BETWEEN 1 AND 5),
    process_conciseness INTEGER CHECK(process_conciseness BETWEEN 1 AND 5),
    UNIQUE(project_name, form_id)
);

CREATE TABLE IF NOT EXISTS tool_ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT NOT NULL,
    form_id TEXT NOT NULL,
    tool_name TEXT NOT NULL,
    tool_doc_id TEXT,
    effectiveness INTEGER CHECK(effectiveness BETWEEN 1 AND 5),
    clarity INTEGER CHECK(clarity BETWEEN 1 AND 5),
    completeness INTEGER CHECK(completeness BETWEEN 1 AND 5),
    efficiency INTEGER CHECK(efficiency BETWEEN 1 AND 5),
    conciseness INTEGER CHECK(conciseness BETWEEN 1 AND 5),
    FOREIGN KEY (project_name, form_id) REFERENCES feedback_forms(project_name, form_id)
);

CREATE TABLE IF NOT EXISTS tool_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT NOT NULL,
    tool_doc_id TEXT NOT NULL,
    tool_name TEXT,
    change_date TEXT NOT NULL,
    imp_id TEXT,
    description TEXT NOT NULL
);

-- Canonical-key aliases (PF-IMP-1691). Holds only what the frontmatter scan in
-- extract_ratings.build_id_index() cannot derive: RETIRED artifacts (which keep the
-- ID they had — the record outlives the file), historical junk keys ('SCRIPT',
-- 'PF-TSK-022-L', the dead PF-SCR-*/PF-VAL-* pools), prose tool names, and project
-- instances that attribute to their generating blueprint template. Append-only and
-- permanent: an alias is never removed, or the rows it explains lose their key again.
-- Looked up on the raw tool_doc_id first, then on tool_name, so both a bad key and a
-- bad-key-with-good-name resolve through one table.
CREATE TABLE IF NOT EXISTS tool_aliases (
    alias TEXT PRIMARY KEY,
    tool_doc_id TEXT NOT NULL,
    note TEXT
);

CREATE INDEX IF NOT EXISTS idx_forms_task_id ON feedback_forms(task_id);
CREATE INDEX IF NOT EXISTS idx_forms_review_cycle ON feedback_forms(review_cycle_id);
CREATE INDEX IF NOT EXISTS idx_forms_project ON feedback_forms(project_name);
CREATE INDEX IF NOT EXISTS idx_ratings_form_id ON tool_ratings(form_id);
CREATE INDEX IF NOT EXISTS idx_ratings_tool_doc_id ON tool_ratings(tool_doc_id);
CREATE INDEX IF NOT EXISTS idx_ratings_project ON tool_ratings(project_name);
CREATE INDEX IF NOT EXISTS idx_changes_tool_doc_id ON tool_changes(tool_doc_id);
CREATE INDEX IF NOT EXISTS idx_changes_project ON tool_changes(project_name);
"""

MIGRATION_SQL = """
-- Migrate from schema v1 (no project_name) to v2 (with project_name).
-- Recreates tables because SQLite cannot add NOT NULL columns or alter constraints.

ALTER TABLE feedback_forms RENAME TO _old_feedback_forms;
ALTER TABLE tool_ratings RENAME TO _old_tool_ratings;
ALTER TABLE tool_changes RENAME TO _old_tool_changes;

CREATE TABLE feedback_forms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT NOT NULL,
    form_id TEXT NOT NULL,
    task_id TEXT NOT NULL,
    task_context TEXT,
    feedback_type TEXT NOT NULL,
    form_date TEXT NOT NULL,
    session_duration_minutes INTEGER,
    review_cycle_id TEXT,
    archived_form_path TEXT,
    overall_effectiveness INTEGER CHECK(overall_effectiveness BETWEEN 1 AND 5),
    process_conciseness INTEGER CHECK(process_conciseness BETWEEN 1 AND 5),
    UNIQUE(project_name, form_id)
);

CREATE TABLE tool_ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT NOT NULL,
    form_id TEXT NOT NULL,
    tool_name TEXT NOT NULL,
    tool_doc_id TEXT,
    effectiveness INTEGER CHECK(effectiveness BETWEEN 1 AND 5),
    clarity INTEGER CHECK(clarity BETWEEN 1 AND 5),
    completeness INTEGER CHECK(completeness BETWEEN 1 AND 5),
    efficiency INTEGER CHECK(efficiency BETWEEN 1 AND 5),
    conciseness INTEGER CHECK(conciseness BETWEEN 1 AND 5),
    FOREIGN KEY (project_name, form_id) REFERENCES feedback_forms(project_name, form_id)
);

CREATE TABLE tool_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT NOT NULL,
    tool_doc_id TEXT NOT NULL,
    change_date TEXT NOT NULL,
    imp_id TEXT,
    description TEXT NOT NULL
);

INSERT INTO feedback_forms (project_name, form_id, task_id, task_context, feedback_type,
    form_date, session_duration_minutes, review_cycle_id, archived_form_path,
    overall_effectiveness, process_conciseness)
SELECT '{migrate_project}', form_id, task_id, task_context, feedback_type,
    form_date, session_duration_minutes, review_cycle_id, archived_form_path,
    overall_effectiveness, process_conciseness
FROM _old_feedback_forms;

INSERT INTO tool_ratings (project_name, form_id, tool_name, tool_doc_id,
    effectiveness, clarity, completeness, efficiency, conciseness)
SELECT '{migrate_project}', form_id, tool_name, tool_doc_id,
    effectiveness, clarity, completeness, efficiency, conciseness
FROM _old_tool_ratings;

INSERT INTO tool_changes (project_name, tool_doc_id, change_date, imp_id, description)
SELECT '{migrate_project}', tool_doc_id, change_date, imp_id, description
FROM _old_tool_changes;

DROP TABLE _old_feedback_forms;
DROP TABLE _old_tool_ratings;
DROP TABLE _old_tool_changes;

CREATE INDEX idx_forms_task_id ON feedback_forms(task_id);
CREATE INDEX idx_forms_review_cycle ON feedback_forms(review_cycle_id);
CREATE INDEX idx_forms_project ON feedback_forms(project_name);
CREATE INDEX idx_ratings_form_id ON tool_ratings(form_id);
CREATE INDEX idx_ratings_tool_doc_id ON tool_ratings(tool_doc_id);
CREATE INDEX idx_ratings_project ON tool_ratings(project_name);
CREATE INDEX idx_changes_tool_doc_id ON tool_changes(tool_doc_id);
CREATE INDEX idx_changes_project ON tool_changes(project_name);
"""


class FeedbackDB:
    """Core database operations for feedback ratings."""

    def __init__(self, db_path: Path, project_name: str):
        self.db_path = db_path
        self.project_name = project_name

    def _needs_migration(self, conn: sqlite3.Connection) -> bool:
        """Check if existing database needs project_name migration."""
        cursor = conn.execute("PRAGMA table_info(feedback_forms)")
        columns = [row[1] for row in cursor.fetchall()]
        return "project_name" not in columns

    def _migrate(self, conn: sqlite3.Connection, migrate_project: str):
        """Migrate v1 schema to v2 (add project_name to all tables)."""
        sql = MIGRATION_SQL.replace("{migrate_project}", migrate_project.replace("'", "''"))
        conn.execute("PRAGMA foreign_keys = OFF")
        conn.executescript(sql)
        conn.execute("PRAGMA foreign_keys = ON")
        conn.commit()
        count = conn.execute("SELECT COUNT(*) FROM feedback_forms").fetchone()[0]
        print(
            f"Migration complete: added project_name column to all tables.\n"
            f"  Existing records tagged as project '{migrate_project}' ({count} forms).",
            file=sys.stderr,
        )

    def _ensure_identity_schema(self, conn: sqlite3.Connection):
        """Additively bring an existing database up to the tool-identity schema (PF-IMP-1691).

        Idempotent and non-destructive — unlike the v1->v2 project_name migration, both
        additions are pure ALTER/CREATE, so no table rebuild and no data motion.
        """
        conn.execute(
            "CREATE TABLE IF NOT EXISTS tool_aliases ("
            "alias TEXT PRIMARY KEY, tool_doc_id TEXT NOT NULL, note TEXT)"
        )
        columns = [row[1] for row in conn.execute("PRAGMA table_info(tool_changes)")]
        if "tool_name" not in columns:
            conn.execute("ALTER TABLE tool_changes ADD COLUMN tool_name TEXT")
        conn.commit()

    def _connect(self) -> sqlite3.Connection:
        if not self.db_path.exists():
            self.db_path.parent.mkdir(parents=True, exist_ok=True)
            conn = sqlite3.connect(str(self.db_path))
            conn.row_factory = sqlite3.Row
            conn.execute("PRAGMA foreign_keys = ON")
            conn.executescript(SCHEMA_SQL)
            conn.commit()
            return conn
        conn = sqlite3.connect(str(self.db_path))
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        if self._needs_migration(conn):
            self._migrate(conn, self.project_name)
        self._ensure_identity_schema(conn)
        return conn

    # --- Canonical tool identity (PF-IMP-1691) --------------------------------

    def resolve_tool_doc_id(
        self, raw: str | None, tool_name: str | None = None, conn: sqlite3.Connection = None
    ) -> str | None:
        """Resolve any supplied tool key to its canonical form, or None if unidentifiable.

        The single normalization point for tool identity. Every write path routes
        through it, so the stored key does not depend on what the author typed —
        which is why the historical corruption classes (blank/'N/A' keys, the 'SCRIPT'
        placeholder, invented sub-IDs, filenames for ID-carrying artifacts) could
        accumulate: nothing validated a key before this existed.

        Order: blank -> alias(raw) -> alias(name) -> portable ID -> filename resolved
        to its artifact's ID -> filename as-is. A NON-PORTABLE ID (PF-STA/PD-*/TE-*)
        is by definition not a tool key — those artifacts are project instances whose
        tool is the blueprint template that generated them — so it resolves only via an
        alias, and otherwise returns None for the audit to surface rather than being
        stored as a plausible-looking key.
        """
        from extract_ratings import is_portable_id, resolve_artifact_id  # sibling script

        def normalize_concrete(value):
            """A concrete key -> canonical form: portable ID passthrough, filename -> its
            artifact's ID, non-portable ID discarded. Applied to BOTH the raw key and an
            alias target, so an alias pointing at a filename that later gains an ID
            (the 20 templates, PF-IMP-1691 Phase 3b) resolves through to the ID rather
            than freezing on the filename and re-splitting the history."""
            if is_portable_id(value):
                return value
            if re.fullmatch(r"[A-Z]{2,4}-[A-Z]{3}-\d+", value):
                return None  # non-portable pool: an instance, never a tool key
            return resolve_artifact_id(value) or value

        owns_conn = conn is None
        conn = conn or self._connect()
        try:
            candidate = (raw or "").strip()
            # Absence wearing a value's clothes. 'SCRIPT' is here because 167 rows
            # arrived carrying the template's literal placeholder as their key, with
            # the real filename sitting in tool_name — unrecoverable while the key
            # read as a value, trivially recoverable once it reads as absent.
            if candidate.upper() in ("", "N/A", "NA", "-", "NONE", "TBD", "SCRIPT", "TOOL"):
                candidate = ""
            for key in (candidate, (tool_name or "").strip()):
                if not key:
                    continue
                row = conn.execute(
                    "SELECT tool_doc_id FROM tool_aliases WHERE alias = ?", (key,)
                ).fetchone()
                if row:
                    return normalize_concrete(row["tool_doc_id"]) or row["tool_doc_id"]
            if candidate:
                resolved = normalize_concrete(candidate)
                if resolved is not None:
                    return resolved
                # candidate was a non-portable ID — discard, fall through to the name.
            # No usable key supplied — fall back to deriving one from the display name.
            if tool_name:
                from extract_ratings import derive_tool_doc_id

                derived, _ = derive_tool_doc_id(tool_name)
                if derived and not re.fullmatch(r"[A-Z]{2,4}-[A-Z]{3}-\d+", derived):
                    return derived
                if derived and is_portable_id(derived):
                    return derived
            return None
        finally:
            if owns_conn:
                conn.close()

    def init_db(self, force: bool = False):
        """Create database tables. If force=True, drop and recreate."""
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        conn = self._connect()
        try:
            if force:
                conn.execute("DROP TABLE IF EXISTS tool_changes")
                conn.execute("DROP TABLE IF EXISTS tool_ratings")
                conn.execute("DROP TABLE IF EXISTS feedback_forms")
            conn.executescript(SCHEMA_SQL)
            conn.commit()
            count = conn.execute("SELECT COUNT(*) FROM feedback_forms").fetchone()[0]
            print(f"Database initialized at: {self.db_path}")
            print(f"Existing records: {count} feedback forms")
        finally:
            conn.close()

    def record_form(self, data: dict) -> str:
        """Record a single feedback form with its tool ratings.

        Returns the form_id of the recorded form.

        Per-form project attribution (PF-IMP-833 (e)): if the form dict carries a
        non-empty "project_name" field, that value is used for both the feedback_forms
        and tool_ratings rows; otherwise the instance default (resolved at construction
        from doc/project-config.json) is used. Enables a single invocation to record
        forms spanning multiple projects with correct cross-project attribution.
        """
        required = ["form_id", "task_id", "feedback_type", "form_date"]
        for field in required:
            if field not in data:
                raise ValueError(f"Missing required field: {field}")

        project_name = data.get("project_name") or self.project_name

        conn = self._connect()
        try:
            conn.execute(
                """INSERT OR REPLACE INTO feedback_forms
                   (project_name, form_id, task_id, task_context, feedback_type, form_date,
                    session_duration_minutes, review_cycle_id, archived_form_path,
                    overall_effectiveness, process_conciseness)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    project_name,
                    data["form_id"],
                    data["task_id"],
                    data.get("task_context"),
                    data["feedback_type"],
                    data["form_date"],
                    data.get("session_duration_minutes"),
                    data.get("review_cycle_id"),
                    data.get("archived_form_path"),
                    data.get("overall_effectiveness"),
                    data.get("process_conciseness"),
                ),
            )

            # Delete existing tool ratings for this form (for idempotent re-record)
            conn.execute(
                "DELETE FROM tool_ratings WHERE project_name = ? AND form_id = ?",
                (project_name, data["form_id"]),
            )

            for tool in data.get("tools", []):
                conn.execute(
                    """INSERT INTO tool_ratings
                       (project_name, form_id, tool_name, tool_doc_id,
                        effectiveness, clarity, completeness, efficiency, conciseness)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        project_name,
                        data["form_id"],
                        tool["tool_name"],
                        # Normalize at the write gate, never trust the supplied key
                        # (PF-IMP-1691): hand-authored JSON is one of the paths that
                        # seeded the historical blank/'N/A'/placeholder key classes.
                        self.resolve_tool_doc_id(
                            tool.get("tool_doc_id"), tool.get("tool_name"), conn=conn
                        ),
                        tool.get("effectiveness"),
                        tool.get("clarity"),
                        tool.get("completeness"),
                        tool.get("efficiency"),
                        tool.get("conciseness"),
                    ),
                )

            conn.commit()
            return data["form_id"]
        finally:
            conn.close()

    def record_forms(self, forms: list) -> int:
        """Record multiple feedback forms. Returns count recorded."""
        count = 0
        for form in forms:
            self.record_form(form)
            count += 1
        return count

    def log_change(
        self, tool_doc_id: str, change_date: str, description: str, imp_id: str = None
    ) -> int:
        """Log a tool change. Returns the row id.

        The supplied key is normalized (PF-IMP-1691) so a filename for an ID-carrying
        artifact is stored under that artifact's ID; the raw input is preserved in
        tool_name, which keeps the row human-readable and gives a later repair the same
        recovery handle that made the historical 'SCRIPT' rows salvageable.
        """
        conn = self._connect()
        try:
            canonical = self.resolve_tool_doc_id(tool_doc_id, conn=conn) or tool_doc_id
            cursor = conn.execute(
                """INSERT INTO tool_changes
                   (project_name, tool_doc_id, tool_name, change_date,
                    imp_id, description)
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (self.project_name, canonical, tool_doc_id, change_date, imp_id, description),
            )
            conn.commit()
            return cursor.lastrowid
        finally:
            conn.close()

    def is_known_tool(self, tool_doc_id: str) -> bool:
        """True if tool_doc_id has prior usage in tool_changes or tool_ratings (this project).

        Resolves the key first (PF-IMP-1691) so the unknown-tool gate judges the
        canonical form — otherwise a filename whose artifact has an ID would be
        reported unknown even though its history exists under that ID.
        """
        tool_doc_id = self.resolve_tool_doc_id(tool_doc_id) or tool_doc_id
        conn = self._connect()
        try:
            row = conn.execute(
                """SELECT 1 FROM tool_changes WHERE project_name = ? AND tool_doc_id = ?
                   UNION SELECT 1 FROM tool_ratings WHERE project_name = ? AND tool_doc_id = ?
                   LIMIT 1""",
                (self.project_name, tool_doc_id, self.project_name, tool_doc_id),
            ).fetchone()
            return row is not None
        finally:
            conn.close()

    def list_tools(self, name_filter: str = None) -> list:
        """Return distinct tool_doc_ids with usage counts in both tables (project-scoped)."""
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT tool_doc_id,
                          SUM(CASE WHEN source = 'changes' THEN cnt ELSE 0 END) as changes,
                          SUM(CASE WHEN source = 'ratings' THEN cnt ELSE 0 END) as ratings
                   FROM (
                       SELECT tool_doc_id, 'changes' as source, COUNT(*) as cnt
                       FROM tool_changes
                       WHERE project_name = ? AND tool_doc_id IS NOT NULL
                       GROUP BY tool_doc_id
                       UNION ALL
                       SELECT tool_doc_id, 'ratings' as source, COUNT(*) as cnt
                       FROM tool_ratings
                       WHERE project_name = ? AND tool_doc_id IS NOT NULL
                       GROUP BY tool_doc_id
                   )
                   GROUP BY tool_doc_id
                   ORDER BY tool_doc_id""",
                (self.project_name, self.project_name),
            ).fetchall()
            result = [dict(r) for r in rows]
            if name_filter:
                f = name_filter.lower()
                result = [r for r in result if f in r["tool_doc_id"].lower()]
            return result
        finally:
            conn.close()

    def list_ratings(self, tool_doc_id: str, all_projects: bool = False) -> list:
        """Return raw tool_ratings rows for a tool_doc_id, unjoined (data-quality inspection).

        Unlike query_by_tool (which INNER-JOINs feedback_forms for an analytic history
        view), this reads tool_ratings directly, so the rows that matter for data-quality
        work are all surfaced as stored: orphan rows (form_id with no matching form),
        duplicate (form_id, tool) rows, and NULL-rating phantom rows. Project-scoped by
        default (like list_tools); all_projects=True drops the scope. Ordered to place
        same-form rows adjacent so duplicates are easy to spot.
        """
        conn = self._connect()
        try:
            select = """SELECT id, project_name, form_id, tool_name, tool_doc_id,
                          effectiveness, clarity, completeness, efficiency, conciseness
                   FROM tool_ratings
                   WHERE tool_doc_id = ?"""
            if all_projects:
                rows = conn.execute(
                    select + " ORDER BY project_name, form_id, id",
                    (tool_doc_id,),
                ).fetchall()
            else:
                rows = conn.execute(
                    select + " AND project_name = ? ORDER BY form_id, id",
                    (tool_doc_id, self.project_name),
                ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def query_by_task(self, task_id: str) -> list:
        """Get all feedback forms for a given task, ordered by date."""
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT ff.*, GROUP_CONCAT(tr.tool_name, ', ') as tools_evaluated
                   FROM feedback_forms ff
                   LEFT JOIN tool_ratings tr ON ff.form_id = tr.form_id
                   WHERE ff.task_id = ?
                   GROUP BY ff.form_id
                   ORDER BY ff.form_date""",
                (task_id,),
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def query_by_tool(self, tool_doc_id: str) -> list:
        """Get all ratings for a given tool, ordered by date."""
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT tr.*, ff.form_date, ff.task_id, ff.review_cycle_id
                   FROM tool_ratings tr
                   JOIN feedback_forms ff ON tr.form_id = ff.form_id
                   WHERE tr.tool_doc_id = ?
                   ORDER BY ff.form_date""",
                (tool_doc_id,),
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def query_all(self) -> list:
        """Get all feedback forms with tool count."""
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT ff.*,
                          (SELECT COUNT(*) FROM tool_ratings tr
                           WHERE tr.form_id = ff.form_id) as tool_count
                   FROM feedback_forms ff
                   ORDER BY ff.form_date"""
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def get_task_trends(self, task_id: str) -> list:
        """Get task-level effectiveness/conciseness trends across review cycles."""
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT
                       review_cycle_id,
                       MIN(form_date) as cycle_date,
                       ROUND(AVG(overall_effectiveness), 1) as avg_effectiveness,
                       ROUND(AVG(process_conciseness), 1) as avg_conciseness,
                       COUNT(*) as form_count
                   FROM feedback_forms
                   WHERE task_id = ? AND review_cycle_id IS NOT NULL
                   GROUP BY review_cycle_id
                   ORDER BY MIN(form_date)""",
                (task_id,),
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def get_tool_trends(self, tool_doc_id: str) -> list:
        """Get per-tool rating trends across review cycles."""
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT
                       ff.review_cycle_id,
                       MIN(ff.form_date) as cycle_date,
                       tr.tool_name,
                       ROUND(AVG(tr.effectiveness), 1) as avg_effectiveness,
                       ROUND(AVG(tr.clarity), 1) as avg_clarity,
                       ROUND(AVG(tr.completeness), 1) as avg_completeness,
                       ROUND(AVG(tr.efficiency), 1) as avg_efficiency,
                       ROUND(AVG(tr.conciseness), 1) as avg_conciseness,
                       COUNT(*) as sample_size
                   FROM tool_ratings tr
                   JOIN feedback_forms ff ON tr.form_id = ff.form_id
                   WHERE tr.tool_doc_id = ? AND ff.review_cycle_id IS NOT NULL
                   GROUP BY ff.review_cycle_id
                   ORDER BY MIN(ff.form_date)""",
                (tool_doc_id,),
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def get_tool_changes(self, tool_doc_id: str) -> list:
        """Get all changes for a tool, ordered by date."""
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT * FROM tool_changes
                   WHERE tool_doc_id = ?
                   ORDER BY change_date""",
                (tool_doc_id,),
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def list_changes(self, imp_id: str) -> list:
        """Get all logged tool changes for an IMP, ordered by date.

        Matching normalizes both sides to the numeric IMP token (via
        _imp_match_key), so 'IMP-038', 'PF-IMP-038', and suffixed historical
        forms ('PF-IMP-833 (b)') all match a query in any prefix variant.
        Cross-project by design: IMP IDs come from the central pool, so rows
        logged from other project checkouts belong to the same improvement.
        Caveat: pre-central-pool rows (numbers roughly < 50) used per-project
        sequences, so a low number can match an unrelated old-era improvement —
        the imp_id/project/date columns in the output make those evident.
        """
        key = _imp_match_key(imp_id)
        if key is None:
            return []
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT project_name, tool_doc_id, change_date, imp_id, description
                   FROM tool_changes
                   WHERE imp_id IS NOT NULL
                   ORDER BY change_date, id"""
            ).fetchall()
            return [dict(r) for r in rows if _imp_match_key(r["imp_id"]) == key]
        finally:
            conn.close()

    def get_all_task_trends(self) -> list:
        """Get task-level trends for all tasks across review cycles."""
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT
                       task_id,
                       review_cycle_id,
                       MIN(form_date) as cycle_date,
                       ROUND(AVG(overall_effectiveness), 1) as avg_effectiveness,
                       ROUND(AVG(process_conciseness), 1) as avg_conciseness,
                       COUNT(*) as form_count
                   FROM feedback_forms
                   WHERE review_cycle_id IS NOT NULL
                   GROUP BY task_id, review_cycle_id
                   ORDER BY task_id, MIN(form_date)"""
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def get_tool_rankings(self, min_appearances: int = 2) -> list:
        """Get all-time tool rankings by average overall score."""
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT
                       COALESCE(tr.tool_doc_id, tr.tool_name) as tool_identifier,
                       tr.tool_name,
                       tr.tool_doc_id,
                       ROUND(AVG(tr.effectiveness), 1) as avg_effectiveness,
                       ROUND(AVG(tr.clarity), 1) as avg_clarity,
                       ROUND(AVG(tr.completeness), 1) as avg_completeness,
                       ROUND(AVG(tr.efficiency), 1) as avg_efficiency,
                       ROUND(AVG(tr.conciseness), 1) as avg_conciseness,
                       ROUND((AVG(tr.effectiveness) + AVG(tr.clarity) +
                              AVG(tr.completeness) + AVG(tr.efficiency) +
                              AVG(tr.conciseness)) / 5.0, 1) as avg_overall,
                       COUNT(*) as appearances
                   FROM tool_ratings tr
                   GROUP BY COALESCE(tr.tool_doc_id, tr.tool_name)
                   HAVING COUNT(*) >= ?
                   ORDER BY avg_overall DESC""",
                (min_appearances,),
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def get_summary_stats(self) -> dict:
        """Get overall database statistics."""
        conn = self._connect()
        try:
            forms = conn.execute("SELECT COUNT(*) FROM feedback_forms").fetchone()[0]
            ratings = conn.execute("SELECT COUNT(*) FROM tool_ratings").fetchone()[0]
            changes = conn.execute("SELECT COUNT(*) FROM tool_changes").fetchone()[0]
            cycles = conn.execute(
                "SELECT COUNT(DISTINCT review_cycle_id) FROM feedback_forms WHERE review_cycle_id IS NOT NULL"  # noqa: E501
            ).fetchone()[0]
            tasks = conn.execute("SELECT COUNT(DISTINCT task_id) FROM feedback_forms").fetchone()[0]
            tools = conn.execute(
                "SELECT COUNT(DISTINCT COALESCE(tool_doc_id, tool_name)) FROM tool_ratings"
            ).fetchone()[0]
            return {
                "feedback_forms": forms,
                "tool_ratings": ratings,
                "tool_changes": changes,
                "review_cycles": cycles,
                "unique_tasks": tasks,
                "unique_tools": tools,
            }
        finally:
            conn.close()

    def consolidate_tools(self, mapping: dict, dry_run: bool = False) -> list:
        """Rewrite tool_doc_id rows from non-canonical to canonical forms (project-scoped).

        For each (from_id, to_id) pair in mapping, runs:
            UPDATE tool_changes  SET tool_doc_id = to_id WHERE project_name = ? AND tool_doc_id = from_id
            UPDATE tool_ratings  SET tool_doc_id = to_id WHERE project_name = ? AND tool_doc_id = from_id

        Returns a list of dicts: {"from": str, "to": str, "changes": int, "ratings": int}.
        With dry_run=True, only counts matching rows; no UPDATE runs.
        """
        conn = self._connect()
        try:
            results = []
            for from_id, to_id in mapping.items():
                changes_count = conn.execute(
                    "SELECT COUNT(*) FROM tool_changes WHERE project_name = ? AND tool_doc_id = ?",
                    (self.project_name, from_id),
                ).fetchone()[0]
                ratings_count = conn.execute(
                    "SELECT COUNT(*) FROM tool_ratings WHERE project_name = ? AND tool_doc_id = ?",
                    (self.project_name, from_id),
                ).fetchone()[0]

                if not dry_run and (changes_count or ratings_count):
                    conn.execute(
                        "UPDATE tool_changes SET tool_doc_id = ? "
                        "WHERE project_name = ? AND tool_doc_id = ?",
                        (to_id, self.project_name, from_id),
                    )
                    conn.execute(
                        "UPDATE tool_ratings SET tool_doc_id = ? "
                        "WHERE project_name = ? AND tool_doc_id = ?",
                        (to_id, self.project_name, from_id),
                    )

                results.append(
                    {
                        "from": from_id,
                        "to": to_id,
                        "changes": changes_count,
                        "ratings": ratings_count,
                    }
                )

            if not dry_run:
                conn.commit()
            return results
        finally:
            conn.close()

    def backfill_tool_doc_ids(self, dry_run: bool = False, all_projects: bool = False) -> dict:
        """Fill NULL tool_ratings.tool_doc_id by re-deriving from stored tool_name.

        Re-derivation uses extract_ratings.derive_tool_doc_id (the same rules new
        extraction applies: task ID for task defs, filename otherwise). Historical NULL
        rows predate the filename-capture fix (PF-IMP-935); their tool_name still holds
        the filename, so it can be recovered without re-reading form files.

        NULL-only — never overwrites an existing tool_doc_id. Scoped to the invoking
        project unless all_projects=True (derivation is project-independent, so a
        cross-project repair run is safe; PF-IMP-1690). Idempotent: re-running recovers
        nothing once applied. Rows whose tool_name yields no canonical id (prose names
        like "Test Registry") are left NULL.

        Returns {"null_before", "recovered", "remaining_null", "by_value"}.
        """
        from extract_ratings import derive_tool_doc_id  # sibling script, co-located

        conn = self._connect()
        try:
            # Blank keys ('', 'N/A') are absence wearing a value's clothes: they are not
            # NULL, so a NULL-only scan never saw them, and 70 recoverable rows sat
            # unrepairable behind them. Treat them as unset in BOTH modes so --dry-run
            # reports exactly what a real run would do (PF-IMP-1691).
            unset = (
                "(tool_doc_id IS NULL OR TRIM(tool_doc_id) IN "
                "('', 'N/A', 'NA', '-', 'None', 'TBD'))"
            )
            scope = "" if all_projects else " AND project_name = ?"
            params = () if all_projects else (self.project_name,)
            if not dry_run:
                conn.execute(
                    f"UPDATE tool_ratings SET tool_doc_id = NULL WHERE {unset}" + scope, params
                )
                conn.commit()
            rows = conn.execute(
                f"SELECT id, tool_name FROM tool_ratings WHERE {unset}" + scope, params
            ).fetchall()
            null_before = len(rows)
            recovered = 0
            by_value: dict = {}
            for r in rows:
                # Route through the shared resolver so an alias, a retired artifact's
                # ID, or a filename->ID mapping applies identically here and at extraction.
                derived, _ = derive_tool_doc_id(r["tool_name"] or "")
                tool_doc_id = self.resolve_tool_doc_id(derived, r["tool_name"], conn=conn)
                if not tool_doc_id:
                    continue
                recovered += 1
                by_value[tool_doc_id] = by_value.get(tool_doc_id, 0) + 1
                if not dry_run:
                    conn.execute(
                        "UPDATE tool_ratings SET tool_doc_id = ? WHERE id = ?",
                        (tool_doc_id, r["id"]),
                    )
            if not dry_run:
                conn.commit()
            return {
                "null_before": null_before,
                "recovered": recovered,
                "remaining_null": null_before - recovered,
                "by_value": by_value,
            }
        finally:
            conn.close()

    def merge_tool_id(self, from_id: str, to_id: str, dry_run: bool = False) -> dict:
        """Re-attribute every tool_ratings + tool_changes row from one tool_doc_id to another.

        Repairs convention drift — one artifact registered under two ids, e.g. a bare
        basename alongside its convention-canonical qualified form (PF-IMP-1690).
        Cross-project by design: tool_doc_id is artifact identity, not project state.
        to_id need not pre-exist (merging into a canonical id that has no rows yet is
        legitimate). Idempotent: once merged, a re-run finds zero rows and errors.

        Returns {"ratings_moved", "changes_moved"}. Raises ValueError on from==to or
        when from_id matches no rows in either table (typo guard).
        """
        if from_id == to_id:
            raise ValueError("--from and --to are the same id — nothing to merge.")
        conn = self._connect()
        try:
            ratings = conn.execute(
                "SELECT COUNT(*) FROM tool_ratings WHERE tool_doc_id = ?", (from_id,)
            ).fetchone()[0]
            changes = conn.execute(
                "SELECT COUNT(*) FROM tool_changes WHERE tool_doc_id = ?", (from_id,)
            ).fetchone()[0]
            if ratings == 0 and changes == 0:
                raise ValueError(
                    f"No rows carry tool_doc_id '{from_id}' — nothing to merge "
                    "(check for a typo with list-tools --filter)."
                )
            if not dry_run:
                conn.execute(
                    "UPDATE tool_ratings SET tool_doc_id = ? WHERE tool_doc_id = ?",
                    (to_id, from_id),
                )
                conn.execute(
                    "UPDATE tool_changes SET tool_doc_id = ? WHERE tool_doc_id = ?",
                    (to_id, from_id),
                )
                conn.commit()
            return {"ratings_moved": ratings, "changes_moved": changes}
        finally:
            conn.close()

    def get_change_trends(self, min_changes: int = 3, months: int = 6) -> list:
        """Hotspot view over the tool_changes log: artifacts with >= min_changes logged
        changes in the last `months` months (approximated as 30 days each), most first.

        Makes repeated fixes to the same artifact visible without ad-hoc SQL
        (PF-IMP-1673). Cross-project by design: tool_doc_id is artifact identity.
        Read the two counts together — a high change count with an equally high
        distinct-IMP count is a high-traffic artifact; a distinct-IMP count well
        below the change count signals the same fixes being re-worked.

        Returns rows of {tool_doc_id, changes, distinct_imps, last_change}.
        """
        cutoff = (datetime.now() - timedelta(days=months * 30)).strftime("%Y-%m-%d")
        conn = self._connect()
        try:
            return conn.execute(
                """SELECT tool_doc_id,
                          COUNT(*) as changes,
                          COUNT(DISTINCT imp_id) as distinct_imps,
                          MAX(change_date) as last_change
                   FROM tool_changes
                   WHERE change_date >= ?
                   GROUP BY tool_doc_id
                   HAVING COUNT(*) >= ?
                   ORDER BY changes DESC, tool_doc_id""",
                (cutoff, min_changes),
            ).fetchall()
        finally:
            conn.close()

    def get_alerts(self, threshold: float = 3.0, min_ratings: int = 3) -> list:
        """Get tools with average overall score below threshold.

        Returns tools sorted by avg_overall ascending (worst first).
        Each row includes the lowest-scoring dimension name.
        """
        conn = self._connect()
        try:
            rows = conn.execute(
                """SELECT
                       COALESCE(tr.tool_doc_id, tr.tool_name) as tool_identifier,
                       tr.tool_name,
                       tr.tool_doc_id,
                       ROUND(AVG(tr.effectiveness), 1) as avg_effectiveness,
                       ROUND(AVG(tr.clarity), 1) as avg_clarity,
                       ROUND(AVG(tr.completeness), 1) as avg_completeness,
                       ROUND(AVG(tr.efficiency), 1) as avg_efficiency,
                       ROUND(AVG(tr.conciseness), 1) as avg_conciseness,
                       ROUND((AVG(tr.effectiveness) + AVG(tr.clarity) +
                              AVG(tr.completeness) + AVG(tr.efficiency) +
                              AVG(tr.conciseness)) / 5.0, 1) as avg_overall,
                       COUNT(*) as appearances
                   FROM tool_ratings tr
                   GROUP BY COALESCE(tr.tool_doc_id, tr.tool_name)
                   HAVING COUNT(*) >= ?
                      AND (AVG(tr.effectiveness) + AVG(tr.clarity) +
                           AVG(tr.completeness) + AVG(tr.efficiency) +
                           AVG(tr.conciseness)) / 5.0 < ?
                   ORDER BY avg_overall ASC""",
                (min_ratings, threshold),
            ).fetchall()

            results = []
            for r in rows:
                d = dict(r)
                # Find lowest dimension
                dims = {
                    "effectiveness": d["avg_effectiveness"],
                    "clarity": d["avg_clarity"],
                    "completeness": d["avg_completeness"],
                    "efficiency": d["avg_efficiency"],
                    "conciseness": d["avg_conciseness"],
                }
                lowest_dim = min(dims, key=dims.get)
                d["lowest_dimension"] = f"{lowest_dim} ({dims[lowest_dim]})"
                results.append(d)
            return results
        finally:
            conn.close()


class MarkdownReporter:
    """Generate markdown trend reports from the database."""

    def __init__(self, db: FeedbackDB):
        self.db = db

    @staticmethod
    def _trend(delta: float) -> str:
        if delta > 0.2:
            return f"^{delta:+.1f}"
        elif delta < -0.2:
            return f"v{delta:+.1f}"
        else:
            return "="

    @staticmethod
    def _pad(text: str, width: int, align: str = "left") -> str:
        text = str(text)
        if align == "center":
            return text.center(width)
        elif align == "right":
            return text.rjust(width)
        return text.ljust(width)

    def full_report(self) -> str:
        """Generate a full trend report across all tasks and tools."""
        stats = self.db.get_summary_stats()
        lines = [
            "# Feedback Ratings Trend Report",
            "",
            f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')} | "
            f"Forms: {stats['feedback_forms']} | "
            f"Tools: {stats['unique_tools']} | "
            f"Cycles: {stats['review_cycles']}",
            "",
        ]

        # Task effectiveness trends
        lines.append("## Task Effectiveness Trends")
        lines.append("")

        all_trends = self.db.get_all_task_trends()
        if all_trends:
            # Group by task_id
            tasks = {}
            cycles_seen = []
            for row in all_trends:
                tid = row["task_id"]
                cid = row["review_cycle_id"]
                if tid not in tasks:
                    tasks[tid] = {}
                tasks[tid][cid] = row
                if cid not in cycles_seen:
                    cycles_seen.append(cid)

            # Build header
            header = "| Task |"
            separator = "|------|"
            for cid in cycles_seen:
                header += f" {cid} (Eff/Con) |"
                separator += ":-:|"
            header += " Trend |"
            separator += "---:|"
            lines.append(header)
            lines.append(separator)

            for tid in sorted(tasks.keys()):
                row_str = f"| {tid} |"
                values = []
                for cid in cycles_seen:
                    if cid in tasks[tid]:
                        d = tasks[tid][cid]
                        eff = d["avg_effectiveness"]
                        con = d["avg_conciseness"]
                        row_str += f" {eff} / {con} |"
                        values.append((eff, con))
                    else:
                        row_str += " -- |"

                # Calculate trend from last two data points
                if len(values) >= 2:
                    eff_delta = values[-1][0] - values[-2][0]
                    con_delta = values[-1][1] - values[-2][1]
                    row_str += f" {self._trend(eff_delta)} / {self._trend(con_delta)} |"
                else:
                    row_str += " -- |"

                lines.append(row_str)
            lines.append("")

        # Tool rankings
        lines.append("## Tool Rankings (2+ appearances)")
        lines.append("")
        rankings = self.db.get_tool_rankings(min_appearances=2)
        if rankings:
            lines.append("| Tool | Doc ID | Eff | Cla | Com | Eff2 | Con | Avg | N |")
            lines.append("|------|--------|:---:|:---:|:---:|:----:|:---:|:---:|--:|")
            for r in rankings:
                doc_id = r["tool_doc_id"] or "--"
                lines.append(
                    f"| {r['tool_name']} | {doc_id} | "
                    f"{r['avg_effectiveness']} | {r['avg_clarity']} | "
                    f"{r['avg_completeness']} | {r['avg_efficiency']} | "
                    f"{r['avg_conciseness']} | {r['avg_overall']} | "
                    f"{r['appearances']} |"
                )
            lines.append("")

        return "\n".join(lines)

    def task_report(self, task_id: str) -> str:
        """Generate a trend report for a specific task."""
        trends = self.db.get_task_trends(task_id)
        if not trends:
            return f"No data found for task {task_id}."

        lines = [f"## {task_id} — Task-Level Trends", ""]

        # Get all tool_doc_ids used in forms for this task to look up changes
        conn = self.db._connect()
        try:
            tool_ids = conn.execute(
                """SELECT DISTINCT tr.tool_doc_id
                   FROM tool_ratings tr
                   JOIN feedback_forms ff ON tr.form_id = ff.form_id
                   WHERE ff.task_id = ? AND tr.tool_doc_id IS NOT NULL""",
                (task_id,),
            ).fetchall()
            tool_doc_ids = [r[0] for r in tool_ids]
        finally:
            conn.close()

        # Also check for changes on the task itself
        if task_id not in tool_doc_ids:
            tool_doc_ids.insert(0, task_id)

        # Collect all changes for related tools
        all_changes = []
        for tid in tool_doc_ids:
            all_changes.extend(self.db.get_tool_changes(tid))
        all_changes.sort(key=lambda c: c["change_date"])

        # Build the table with interleaved changes
        lines.append("| Cycle | Date | Eff | Con | Forms | Changes |")
        lines.append("|-------|------|:---:|:---:|------:|---------|")

        prev_date = None
        for i, t in enumerate(trends):
            # Insert changes that occurred between previous and current cycle
            if prev_date:
                for ch in all_changes:
                    if prev_date < ch["change_date"] <= t["cycle_date"]:
                        imp = ch["imp_id"] or ""
                        lines.append(
                            f"| | | | | | {imp} ({ch['change_date']}): {ch['description']} |"
                        )

            lines.append(
                f"| {t['review_cycle_id']} | {t['cycle_date']} | "
                f"{t['avg_effectiveness']} | {t['avg_conciseness']} | "
                f"{t['form_count']} | |"
            )
            prev_date = t["cycle_date"]

        lines.append("")

        # Delta summary
        if len(trends) >= 2:
            first = trends[0]
            last = trends[-1]
            eff_delta = last["avg_effectiveness"] - first["avg_effectiveness"]
            con_delta = last["avg_conciseness"] - first["avg_conciseness"]
            lines.append(
                f"**Overall delta**: {eff_delta:+.1f} effectiveness, "
                f"{con_delta:+.1f} conciseness "
                f"({first['review_cycle_id']} -> {last['review_cycle_id']})"
            )
            lines.append("")

        return "\n".join(lines)

    def tool_report(self, tool_doc_id: str) -> str:
        """Generate a trend report for a specific tool."""
        trends = self.db.get_tool_trends(tool_doc_id)
        if not trends:
            return f"No data found for tool {tool_doc_id}."

        tool_name = trends[0]["tool_name"]
        changes = self.db.get_tool_changes(tool_doc_id)

        lines = [f"## {tool_doc_id} — {tool_name}", ""]

        # Rating history
        lines.append("| Cycle | Date | Eff | Cla | Com | Eff2 | Con | Avg | N | Changes |")
        lines.append("|-------|------|:---:|:---:|:---:|:----:|:---:|:---:|--:|---------|")

        prev_date = None
        for t in trends:
            avg = round(
                (
                    t["avg_effectiveness"]
                    + t["avg_clarity"]
                    + t["avg_completeness"]
                    + t["avg_efficiency"]
                    + t["avg_conciseness"]
                )
                / 5.0,
                1,
            )

            # Interleave changes
            if prev_date:
                for ch in changes:
                    if prev_date < ch["change_date"] <= t["cycle_date"]:
                        imp = ch["imp_id"] or ""
                        lines.append(
                            f"| | | | | | | | | | {imp} ({ch['change_date']}): {ch['description']} |"  # noqa: E501
                        )

            lines.append(
                f"| {t['review_cycle_id']} | {t['cycle_date']} | "
                f"{t['avg_effectiveness']} | {t['avg_clarity']} | "
                f"{t['avg_completeness']} | {t['avg_efficiency']} | "
                f"{t['avg_conciseness']} | {avg} | {t['sample_size']} | |"
            )
            prev_date = t["cycle_date"]

        lines.append("")

        # Change analysis
        if len(trends) >= 2:
            lines.append("### Change Analysis")
            lines.append("")
            lines.append("| Dimension | First | Last | Delta | Status |")
            lines.append("|-----------|:-----:|:----:|:-----:|:------:|")

            first = trends[0]
            last = trends[-1]
            for dim in [
                "effectiveness",
                "clarity",
                "completeness",
                "efficiency",
                "conciseness",
            ]:
                f_val = first[f"avg_{dim}"]
                l_val = last[f"avg_{dim}"]
                delta = l_val - f_val
                status = "Improving" if delta > 0.2 else ("Declining" if delta < -0.2 else "Stable")
                lines.append(
                    f"| {dim.capitalize()} | {f_val} | {l_val} | " f"{delta:+.1f} | {status} |"
                )
            lines.append("")

        return "\n".join(lines)


def format_table(rows: list, format_type: str = "table") -> str:
    """Format query results as table, JSON, or CSV."""
    if not rows:
        return "No results found."

    if format_type == "json":
        return json.dumps(rows, indent=2)

    if format_type == "csv":
        keys = rows[0].keys()
        lines = [",".join(keys)]
        for row in rows:
            lines.append(",".join(str(row.get(k, "")) for k in keys))
        return "\n".join(lines)

    # Plain text table
    keys = list(rows[0].keys())
    widths = {k: len(k) for k in keys}
    for row in rows:
        for k in keys:
            widths[k] = max(widths[k], len(str(row.get(k, ""))))

    header = " | ".join(k.ljust(widths[k]) for k in keys)
    sep = "-+-".join("-" * widths[k] for k in keys)
    lines = [header, sep]
    for row in rows:
        lines.append(" | ".join(str(row.get(k, "")).ljust(widths[k]) for k in keys))
    return "\n".join(lines)


def cmd_init(args, db):
    """Handle the 'init' subcommand."""
    db.init_db(force=args.force)


def _load_json_input(source: str, *, hint_stdin_workaround: bool):
    """Load JSON from a file path or '-' for stdin, with actionable error messages.

    hint_stdin_workaround=True surfaces the bash-escape-corruption pattern (PF-IMP-833 (b))
    on stdin parse failures and points to the --batch <path> / --json <path> file workaround.
    """
    if source == "-":
        try:
            return json.load(sys.stdin)
        except json.JSONDecodeError as e:
            msg = [f"ERROR: Failed to parse JSON from stdin: {e}"]
            if hint_stdin_workaround:
                msg.append(
                    "  Hint: bash heredocs and double-quoted strings can corrupt JSON via "
                    "escape-sequence interpretation\n"
                    '  (backticks become command substitution; \\n / \\t / \\" may be reinterpreted).'
                )
                msg.append(
                    "  Workaround: write the JSON to a file and pass --batch <path> "
                    "(or --json <path>) instead of stdin."
                )
            print("\n".join(msg), file=sys.stderr)
            sys.exit(1)
    try:
        return json.loads(Path(source).read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"ERROR: Failed to parse JSON from {source}: {e}", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"ERROR: Could not read {source}: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_record(args, db):
    """Handle the 'record' subcommand."""
    data = _load_json_input(args.json, hint_stdin_workaround=True)

    if isinstance(data, list):
        count = db.record_forms(data)
        print(f"Recorded {count} feedback forms.")
    else:
        form_id = db.record_form(data)
        tool_count = len(data.get("tools", []))
        print(f"Recorded form {form_id} with {tool_count} tool ratings.")


def _block_unknown_tools(db, entries, new_tool_flag):
    """Block log-change with unknown tool_doc_ids.

    entries: list of {"tool": str, "new_tool": bool?} dicts.
    new_tool_flag: global CLI override (--new-tool) — exempts every entry. Use for
        bulk imports only; weakens typo detection across the whole batch.

    An entry escapes the block when ANY of these holds:
      - new_tool_flag is True (global override)
      - entry has "new_tool": True (per-row opt-in for mixed batches, PF-IMP-833 (a))
      - entry's tool is already known to this project (after canonical resolution —
        is_known_tool resolves a filename for an ID-carrying artifact to its ID first,
        so naming a known guide/template by filename is not reported unknown; PF-IMP-1691)
    """
    if new_tool_flag:
        return
    unknown = [
        e["tool"] for e in entries if not e.get("new_tool") and not db.is_known_tool(e["tool"])
    ]
    if unknown:
        print("ERROR: Unknown tool_doc_id(s) for this project:", file=sys.stderr)
        for t in unknown:
            print(f"  {t}", file=sys.stderr)
        # PF-IMP-1691: the key an author typed may resolve to a different canonical
        # form (a filename -> its artifact's ID). When it does, name the resolution at
        # the point of failure rather than costing a fail-then-list-tools round trip.
        # Supersedes the earlier PF-TSK-only suggester (PF-IMP-1570) and the now-inverted
        # "artifact PF-IDs are not tool keys" note (PF-IMP-1395) — under the ID-first
        # convention a portable artifact ID IS the key.
        resolved = []
        for t in unknown:
            canonical = db.resolve_tool_doc_id(t)
            if canonical and canonical != t:
                resolved.append((t, canonical))
        if resolved:
            print(
                "\nNote: the canonical key is the artifact's portable framework ID "
                "(filename only when it has none). Did you mean:",
                file=sys.stderr,
            )
            for typed, canonical in resolved:
                print(f"  {typed} -> {canonical}", file=sys.stderr)
        print(
            "\nRun 'python feedback_db.py list-tools' to browse canonical IDs.",
            file=sys.stderr,
        )
        print(
            "Options to register a new tool:\n"
            '  - Per-row: add "new_tool": true to the relevant entry in --batch JSON\n'
            "    (preserves typo detection on the other entries; PF-IMP-833 (a))\n"
            "  - Global: pass --new-tool to exempt the entire batch\n"
            "    (use for bulk imports only; weakens typo detection)",
            file=sys.stderr,
        )
        # PF-IMP-1653: restate the offending IDs in the final line so a
        # tail-truncated capture still shows which IDs need the remediation above.
        print(
            f"\nBlocked: {len(unknown)} unknown tool_doc_id(s): {', '.join(unknown)}",
            file=sys.stderr,
        )
        sys.exit(1)


def cmd_log_change(args, db):
    """Handle the 'log-change' subcommand."""
    if not args.batch and not (args.tool and args.description):
        print("Error: provide either --batch or both --tool and --description", file=sys.stderr)
        sys.exit(1)
    today = datetime.now().strftime("%Y-%m-%d")
    if args.batch:
        data = _load_json_input(args.batch, hint_stdin_workaround=True)
        if not isinstance(data, list):
            print("Error: --batch JSON must be an array of objects", file=sys.stderr)
            sys.exit(1)
        # PF-IMP-1393 (b): shape-check every entry before any write, so a malformed
        # entry is reported up front instead of crashing the batch mid-write after
        # earlier entries were already logged. Also the basis of --validate-only.
        bad = [
            str(i)
            for i, e in enumerate(data)
            if not isinstance(e, dict) or not e.get("tool") or not e.get("description")
        ]
        if bad:
            print(
                "Error: --batch entries must be objects with non-empty 'tool' and "
                f"'description' (offending indices: {', '.join(bad)})",
                file=sys.stderr,
            )
            sys.exit(1)
        _block_unknown_tools(db, data, args.new_tool)
        if args.validate_only:
            print(f"Validation OK: {len(data)} entries; nothing logged (--validate-only).")
            return
        count = 0
        for entry in data:
            change_date = entry.get("date") or today
            row_id = db.log_change(
                tool_doc_id=entry["tool"],
                change_date=change_date,
                description=entry["description"],
                imp_id=entry.get("imp"),
            )
            print(
                f"Logged change #{row_id}: {entry['tool']} — "
                f"{entry.get('imp', 'no IMP')} ({change_date})"
            )
            count += 1
        print(f"Batch complete: {count} changes logged.")
    else:
        _block_unknown_tools(db, [{"tool": args.tool}], args.new_tool)
        if args.validate_only:
            print("Validation OK: 1 entry; nothing logged (--validate-only).")
            return
        change_date = args.date or today
        row_id = db.log_change(
            tool_doc_id=args.tool,
            change_date=change_date,
            description=args.description,
            imp_id=args.imp,
        )
        print(f"Logged change #{row_id}: {args.tool} — " f"{args.imp or 'no IMP'} ({change_date})")


def cmd_list_changes(args, db):
    """Handle the 'list-changes' subcommand."""
    rows = db.list_changes(args.imp)
    if not rows:
        # Update-ProcessImprovement.ps1's Test-ImpHasLoggedChanges (PF-IMP-1740 (b)) matches
        # this exact "No logged changes match" prefix as its zero-rows signal (the subcommand
        # exits 0 either way) — keep the wording in sync if this line changes.
        print(f"No logged changes match {args.imp}.")
        return
    print(format_table(rows, args.format))
    if args.format == "table":
        print(f"\nTotal: {len(rows)} change(s)")


def cmd_query(args, db):
    """Handle the 'query' subcommand."""
    if args.task:
        rows = db.query_by_task(args.task)
    elif args.tool:
        rows = db.query_by_tool(args.tool)
    elif args.all:
        rows = db.query_all()
    else:
        print("Error: specify --task, --tool, or --all", file=sys.stderr)
        sys.exit(1)

    print(format_table(rows, args.format))


def cmd_report(args, db):
    """Handle the 'report' subcommand."""
    reporter = MarkdownReporter(db)

    if args.task:
        output = reporter.task_report(args.task)
    elif args.tool:
        output = reporter.tool_report(args.tool)
    else:
        output = reporter.full_report()

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Report written to {args.output}")
    else:
        print(output)


def cmd_list_tools(args, db):
    """Handle the 'list-tools' subcommand."""
    rows = db.list_tools(name_filter=args.filter)
    if not rows:
        if args.filter:
            print(f"No tool_doc_ids match filter '{args.filter}'.")
        else:
            print("No tool_doc_ids logged yet for this project.")
        return
    print(format_table(rows))
    print(f"\nTotal: {len(rows)} distinct tool_doc_ids")


def cmd_list_ratings(args, db):
    """Handle the 'list-ratings' subcommand."""
    rows = db.list_ratings(args.tool, all_projects=args.all_projects)
    scope = "all projects" if args.all_projects else f"project '{db.project_name}'"
    if not rows:
        print(f"No tool_ratings rows for tool_doc_id '{args.tool}' ({scope}).")
        return
    print(format_table(rows, args.format))
    if args.format == "table":
        print(f"\nTotal: {len(rows)} rating row(s) for '{args.tool}' ({scope})")


def cmd_consolidate_tools(args, db):
    """Handle the 'consolidate-tools' subcommand."""
    results = db.consolidate_tools(CONSOLIDATION_MAPPING, dry_run=args.dry_run)

    rows = []
    total_changes = 0
    total_ratings = 0
    for r in results:
        if r["changes"] == 0 and r["ratings"] == 0:
            continue
        rows.append(
            {
                "From": r["from"],
                "To": r["to"],
                "Changes": r["changes"],
                "Ratings": r["ratings"],
            }
        )
        total_changes += r["changes"]
        total_ratings += r["ratings"]

    if not rows:
        print("No drift entries found — nothing to consolidate.")
        return

    print(format_table(rows))
    pairs_affected = len(rows)
    if args.dry_run:
        print(
            f"\n[DRY RUN] Would consolidate {total_changes} change(s) and "
            f"{total_ratings} rating(s) across {pairs_affected} pair(s). "
            f"Re-run without --dry-run to apply."
        )
    else:
        print(
            f"\nConsolidated {total_changes} change(s) and "
            f"{total_ratings} rating(s) across {pairs_affected} pair(s)."
        )


def cmd_backfill_tool_doc_ids(args, db):
    """Handle the 'backfill-tool-doc-ids' subcommand."""
    result = db.backfill_tool_doc_ids(dry_run=args.dry_run, all_projects=args.all_projects)

    if result["null_before"] == 0:
        print("No NULL tool_doc_id rows — nothing to backfill.")
        return

    top = sorted(result["by_value"].items(), key=lambda kv: (-kv[1], kv[0]))[:15]
    if top:
        print(format_table([{"tool_doc_id": k, "rows": v} for k, v in top]))

    verb = "Would recover" if args.dry_run else "Recovered"
    suffix = "  Re-run without --dry-run to apply." if args.dry_run else ""
    print(
        f"\n{verb} {result['recovered']} of {result['null_before']} NULL tool_doc_id "
        f"row(s); {result['remaining_null']} remain NULL (unidentifiable tool names).{suffix}"
    )


def cmd_merge_tool_id(args, db):
    """Handle the 'merge-tool-id' subcommand."""
    try:
        result = db.merge_tool_id(args.from_id, args.to_id, dry_run=args.dry_run)
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    verb = "Would re-attribute" if args.dry_run else "Re-attributed"
    suffix = "  Re-run without --dry-run to apply." if args.dry_run else ""
    print(
        f"{verb} {result['ratings_moved']} rating row(s) and {result['changes_moved']} "
        f"change row(s): '{args.from_id}' -> '{args.to_id}'.{suffix}"
    )


def cmd_trend_changes(args, db):
    """Handle the 'trend-changes' subcommand."""
    rows = db.get_change_trends(min_changes=args.min_changes, months=args.months)
    if not rows:
        print(
            f"No artifacts with >= {args.min_changes} logged change(s) "
            f"in the last {args.months} month(s)."
        )
        return
    total = len(rows)
    shown = rows[: args.limit] if args.limit else rows
    print(format_table([dict(r) for r in shown]))
    trunc = f" (showing top {len(shown)})" if len(shown) < total else ""
    print(
        f"\n{total} artifact(s) with >= {args.min_changes} change(s) in the last "
        f"{args.months} month(s){trunc}. Reading: distinct_imps well below changes = "
        "the same fixes being re-worked; roughly equal = high-traffic artifact."
    )


def cmd_alerts(args, db):
    """Handle the 'alerts' subcommand."""
    alerts = db.get_alerts(threshold=args.threshold, min_ratings=args.min_ratings)
    if not alerts:
        print(f"No tools below threshold {args.threshold} " f"(min {args.min_ratings} ratings).")
        sys.exit(0)

    print(f"ALERT: {len(alerts)} tool(s) below threshold {args.threshold}\n")
    rows = []
    for a in alerts:
        rows.append(
            {
                "Tool": a["tool_name"],
                "Doc ID": a["tool_doc_id"] or "--",
                "Avg Score": a["avg_overall"],
                "Ratings": a["appearances"],
                "Lowest Dimension": a["lowest_dimension"],
            }
        )
    print(format_table(rows))
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Feedback Ratings Database — Persistent storage for feedback form ratings."
    )
    parser.add_argument(
        "--db",
        type=Path,
        default=DB_DEFAULT_PATH,
        help=f"Database file path (default: {DB_DEFAULT_PATH})",
    )
    parser.add_argument(
        "--project",
        help="Override project name (default: from doc/project-config.json)",
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # init
    p_init = subparsers.add_parser("init", help="Initialize the database")
    p_init.add_argument("--force", action="store_true", help="Drop and recreate all tables")

    # record
    p_record = subparsers.add_parser("record", help="Record ratings from JSON input")
    p_record.add_argument(
        "--json",
        required=True,
        help='Path to JSON file with form data, or "-" for stdin',
    )

    # log-change
    p_change = subparsers.add_parser("log-change", help="Log a tool modification")
    p_change.add_argument(
        "--tool",
        help=(
            "Tool document ID. Convention: PF-TSK-NNN for task definitions; "
            "filename (e.g., New-FeedbackForm.ps1, feature-validation-guide.md) for "
            "templates, guides, scripts, context maps, handbooks. "
            "Verify with: feedback_db.py list-tools --filter <substring>."
        ),
    )
    p_change.add_argument("--date", help="Date of change (YYYY-MM-DD; default: today)")
    p_change.add_argument("--imp", help="Improvement ID (e.g., IMP-038)")
    p_change.add_argument("--description", help="Description of the change")
    p_change.add_argument(
        "--batch",
        help="Path to JSON file with array of {tool, description, date?, imp?, new_tool?} "
        'objects, or "-" for stdin. "date" defaults to today when omitted. '
        'Per-entry "new_tool": true opts that row out of the '
        "unknown-ID block (PF-IMP-833 (a)) — use for mixed batches containing both "
        "known tools and first-time registrations.",
    )
    p_change.add_argument(
        "--new-tool",
        action="store_true",
        help="Global override: bypass unknown-ID block for the entire batch. Use for bulk "
        'imports only. For mixed batches prefer per-entry "new_tool": true in --batch JSON.',
    )
    p_change.add_argument(
        "--validate-only",
        action="store_true",
        help="Run all input checks (JSON shape, required fields, unknown-tool block) and "
        "exit without logging anything. Exit 0 = the same invocation without this flag "
        "would log cleanly. Used by Update-ProcessImprovement.ps1 to validate a "
        "-LogToolChanges payload before the terminal status move (PF-IMP-1393 (b)).",
    )

    # list-changes
    p_changes = subparsers.add_parser(
        "list-changes",
        help="List logged tool changes for an improvement (all projects)",
    )
    p_changes.add_argument(
        "--imp",
        required=True,
        help="Improvement ID (e.g., PF-IMP-038; matches historical 'IMP-038' rows too)",
    )
    p_changes.add_argument(
        "--format",
        choices=["table", "json", "csv"],
        default="table",
        help="Output format (default: table)",
    )

    # query
    p_query = subparsers.add_parser("query", help="Query ratings data")
    p_query.add_argument("--task", help="Filter by task ID")
    p_query.add_argument("--tool", help="Filter by tool document ID")
    p_query.add_argument("--all", action="store_true", help="Show all forms")
    p_query.add_argument(
        "--format",
        choices=["table", "json", "csv"],
        default="table",
        help="Output format (default: table)",
    )

    # report
    p_report = subparsers.add_parser("report", help="Generate markdown trend report")
    p_report.add_argument("--task", help="Report for specific task")
    p_report.add_argument("--tool", help="Report for specific tool")
    p_report.add_argument("--output", help="Write report to file")

    # list-tools
    p_list = subparsers.add_parser(
        "list-tools",
        help="List distinct tool_doc_ids from tool_changes and tool_ratings (project-scoped)",
    )
    p_list.add_argument("--filter", help="Case-insensitive substring filter on tool_doc_id")

    # list-ratings
    p_list_ratings = subparsers.add_parser(
        "list-ratings",
        help="List raw tool_ratings rows for a tool_doc_id (unjoined; data-quality inspection)",
    )
    p_list_ratings.add_argument(
        "--tool",
        required=True,
        help="Tool document ID whose raw rating rows to list (e.g., New-Task.ps1, PF-TSK-009)",
    )
    p_list_ratings.add_argument(
        "--all-projects",
        action="store_true",
        help="List across all projects (default: current project only, like list-tools)",
    )
    p_list_ratings.add_argument(
        "--format",
        choices=["table", "json", "csv"],
        default="table",
        help="Output format (default: table)",
    )

    # consolidate-tools
    p_consolidate = subparsers.add_parser(
        "consolidate-tools",
        help=(
            "Rewrite historical non-canonical tool_doc_id rows to canonical form "
            "(PF-IMP-704 cleanup). Idempotent."
        ),
    )
    p_consolidate.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview affected rows without applying UPDATEs",
    )

    # backfill-tool-doc-ids
    p_backfill = subparsers.add_parser(
        "backfill-tool-doc-ids",
        help=(
            "Fill NULL tool_ratings.tool_doc_id by re-deriving from stored tool_name "
            "(same rules as extract_ratings). NULL-only, idempotent (PF-IMP-965)."
        ),
    )
    p_backfill.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview recovery counts without applying UPDATEs",
    )
    p_backfill.add_argument(
        "--all-projects",
        action="store_true",
        help=(
            "Backfill NULL rows across every project, not just the invoking one "
            "(derivation is project-independent)"
        ),
    )

    # merge-tool-id
    p_merge = subparsers.add_parser(
        "merge-tool-id",
        help=(
            "Re-attribute every rating + change row from one tool_doc_id to another "
            "(convention-drift repair, PF-IMP-1690). Cross-project; idempotent."
        ),
    )
    p_merge.add_argument(
        "--from",
        dest="from_id",
        required=True,
        help="tool_doc_id to merge away (must currently have rows)",
    )
    p_merge.add_argument(
        "--to",
        dest="to_id",
        required=True,
        help="canonical tool_doc_id to merge into (need not pre-exist)",
    )
    p_merge.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview affected row counts without applying UPDATEs",
    )

    # trend-changes
    p_trend = subparsers.add_parser(
        "trend-changes",
        help=(
            "Hotspot view over the change log: artifacts with >= N logged changes in "
            "the last M months (recurrence detection, PF-IMP-1673). Cross-project."
        ),
    )
    p_trend.add_argument(
        "--min-changes",
        type=int,
        default=3,
        help="Minimum logged changes to list an artifact (default: 3)",
    )
    p_trend.add_argument(
        "--months",
        type=int,
        default=6,
        help="Look-back window in months, approximated as 30 days each (default: 6)",
    )
    p_trend.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Show only the top N rows (default: 0 = all)",
    )

    # alerts
    p_alerts = subparsers.add_parser("alerts", help="Flag tools with ratings below threshold")
    p_alerts.add_argument(
        "--threshold",
        type=float,
        default=3.0,
        help="Alert threshold for average overall score (default: 3.0)",
    )
    p_alerts.add_argument(
        "--min-ratings",
        type=int,
        default=3,
        help="Minimum number of ratings required (default: 3)",
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    project_name = args.project or _resolve_project_name()
    db = FeedbackDB(args.db, project_name)

    commands = {
        "init": cmd_init,
        "record": cmd_record,
        "log-change": cmd_log_change,
        "list-changes": cmd_list_changes,
        "query": cmd_query,
        "list-tools": cmd_list_tools,
        "list-ratings": cmd_list_ratings,
        "report": cmd_report,
        "alerts": cmd_alerts,
        "consolidate-tools": cmd_consolidate_tools,
        "backfill-tool-doc-ids": cmd_backfill_tool_doc_ids,
        "merge-tool-id": cmd_merge_tool_id,
        "trend-changes": cmd_trend_changes,
    }
    commands[args.command](args, db)


if __name__ == "__main__":
    main()
