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
    python process-framework/scripts/feedback_db.py query --task PF-TSK-009
    python process-framework/scripts/feedback_db.py query --tool PF-TSK-007
    python process-framework/scripts/feedback_db.py query --all
    python process-framework/scripts/feedback_db.py list-tools
    python process-framework/scripts/feedback_db.py list-tools --filter integration
    python process-framework/scripts/feedback_db.py report
    python process-framework/scripts/feedback_db.py report --task PF-TSK-009
    python process-framework/scripts/feedback_db.py alerts
    python process-framework/scripts/feedback_db.py alerts --threshold 2.5 --min-ratings 5
"""

import argparse
import json
import sqlite3
import sys
from datetime import datetime
from pathlib import Path


def _resolve_db_path() -> Path:
    """Resolve database path: domain-config.json > fallback to local."""
    config_path = Path(__file__).resolve().parent.parent / "domain-config.json"
    if config_path.exists():
        try:
            with open(config_path) as f:
                config = json.load(f)
            db_setting = config.get("ratings_db_path", {})
            if isinstance(db_setting, dict) and db_setting.get("value"):
                db_path = Path(db_setting["value"])
                if not db_path.parent.exists():
                    print(
                        f"ERROR: ratings_db_path parent directory "
                        f"does not exist: {db_path.parent}\n"
                        f"  Configured in: {config_path}\n"
                        f"  Check the 'ratings_db_path.value' setting.",
                        file=sys.stderr,
                    )
                    sys.exit(1)
                return db_path
        except (json.JSONDecodeError, OSError):
            pass
    return Path(__file__).resolve().parent.parent / "feedback" / "ratings.db"


def _resolve_project_name() -> str:
    """Resolve project name from doc/project-config.json."""
    config_path = Path(__file__).resolve().parent.parent.parent / "doc" / "project-config.json"
    if config_path.exists():
        try:
            with open(config_path) as f:
                config = json.load(f)
            name = config.get("project", {}).get("name")
            if name:
                return name
        except (json.JSONDecodeError, OSError):
            pass
    print(
        "ERROR: Could not resolve project name.\n"
        f"  Expected: {config_path}\n"
        "  Ensure doc/project-config.json exists with project.name field.",
        file=sys.stderr,
    )
    sys.exit(1)


DB_DEFAULT_PATH = _resolve_db_path()

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
    change_date TEXT NOT NULL,
    imp_id TEXT,
    description TEXT NOT NULL
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
        return conn

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
        """
        required = ["form_id", "task_id", "feedback_type", "form_date"]
        for field in required:
            if field not in data:
                raise ValueError(f"Missing required field: {field}")

        conn = self._connect()
        try:
            conn.execute(
                """INSERT OR REPLACE INTO feedback_forms
                   (project_name, form_id, task_id, task_context, feedback_type, form_date,
                    session_duration_minutes, review_cycle_id, archived_form_path,
                    overall_effectiveness, process_conciseness)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    self.project_name,
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
                (self.project_name, data["form_id"]),
            )

            for tool in data.get("tools", []):
                conn.execute(
                    """INSERT INTO tool_ratings
                       (project_name, form_id, tool_name, tool_doc_id,
                        effectiveness, clarity, completeness, efficiency, conciseness)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        self.project_name,
                        data["form_id"],
                        tool["tool_name"],
                        tool.get("tool_doc_id"),
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
        """Log a tool change. Returns the row id."""
        conn = self._connect()
        try:
            cursor = conn.execute(
                """INSERT INTO tool_changes
                   (project_name, tool_doc_id, change_date,
                    imp_id, description)
                   VALUES (?, ?, ?, ?, ?)""",
                (self.project_name, tool_doc_id, change_date, imp_id, description),
            )
            conn.commit()
            return cursor.lastrowid
        finally:
            conn.close()

    def is_known_tool(self, tool_doc_id: str) -> bool:
        """True if tool_doc_id has prior usage in tool_changes or tool_ratings (this project)."""
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


def cmd_record(args, db):
    """Handle the 'record' subcommand."""
    if args.json == "-":
        data = json.load(sys.stdin)
    else:
        with open(args.json, "r", encoding="utf-8") as f:
            data = json.load(f)

    if isinstance(data, list):
        count = db.record_forms(data)
        print(f"Recorded {count} feedback forms.")
    else:
        form_id = db.record_form(data)
        tool_count = len(data.get("tools", []))
        print(f"Recorded form {form_id} with {tool_count} tool ratings.")


def _block_unknown_tools(db, tool_ids, new_tool_flag):
    """Block log-change with unknown tool_doc_ids unless --new-tool acknowledged."""
    if new_tool_flag:
        return
    unknown = [t for t in tool_ids if not db.is_known_tool(t)]
    if unknown:
        print("ERROR: Unknown tool_doc_id(s) for this project:", file=sys.stderr)
        for t in unknown:
            print(f"  {t}", file=sys.stderr)
        print(
            "\nRun 'python feedback_db.py list-tools' to browse canonical IDs.",
            file=sys.stderr,
        )
        print(
            "Pass --new-tool if this is a legitimately new tool registration.",
            file=sys.stderr,
        )
        sys.exit(1)


def cmd_log_change(args, db):
    """Handle the 'log-change' subcommand."""
    if not args.batch and not (args.tool and args.date and args.description):
        print(
            "Error: provide either --batch or all of --tool, --date, --description", file=sys.stderr
        )
        sys.exit(1)
    if args.batch:
        src = args.batch
        if src == "-":
            data = json.load(sys.stdin)
        else:
            data = json.loads(Path(src).read_text(encoding="utf-8"))
        if not isinstance(data, list):
            print("Error: --batch JSON must be an array of objects", file=sys.stderr)
            sys.exit(1)
        _block_unknown_tools(db, [entry["tool"] for entry in data], args.new_tool)
        count = 0
        for entry in data:
            row_id = db.log_change(
                tool_doc_id=entry["tool"],
                change_date=entry["date"],
                description=entry["description"],
                imp_id=entry.get("imp"),
            )
            print(
                f"Logged change #{row_id}: {entry['tool']} — "
                f"{entry.get('imp', 'no IMP')} ({entry['date']})"
            )
            count += 1
        print(f"Batch complete: {count} changes logged.")
    else:
        _block_unknown_tools(db, [args.tool], args.new_tool)
        row_id = db.log_change(
            tool_doc_id=args.tool,
            change_date=args.date,
            description=args.description,
            imp_id=args.imp,
        )
        print(f"Logged change #{row_id}: {args.tool} — " f"{args.imp or 'no IMP'} ({args.date})")


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
    p_change.add_argument("--tool", help="Tool document ID")
    p_change.add_argument("--date", help="Date of change (YYYY-MM-DD)")
    p_change.add_argument("--imp", help="Improvement ID (e.g., IMP-038)")
    p_change.add_argument("--description", help="Description of the change")
    p_change.add_argument(
        "--batch",
        help="Path to JSON file with array of "
        '{tool, date, description, imp?} objects, or "-" for stdin',
    )
    p_change.add_argument(
        "--new-tool",
        action="store_true",
        help="Acknowledge a first-time tool_doc_id registration (bypasses unknown-ID block)",
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
        "query": cmd_query,
        "list-tools": cmd_list_tools,
        "report": cmd_report,
        "alerts": cmd_alerts,
    }
    commands[args.command](args, db)


if __name__ == "__main__":
    main()
