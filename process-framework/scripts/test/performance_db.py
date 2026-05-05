#!/usr/bin/env python3
"""Performance Results Database — Persistent storage for performance test results.

Stores performance test measurements in a SQLite database,
enabling trend analysis and regression detection.

Usage:
    python process-framework/scripts/test/performance_db.py init
    python process-framework/scripts/test/performance_db.py record \\
        --test-id BM-NNN --value 144.0 --unit "files/sec"
    python process-framework/scripts/test/performance_db.py record \\
        --test-id BM-NNN --value 144.0 --unit "files/sec" --notes "Post-refactor"

Note: The current git commit (HEAD) is automatically captured with each record.
      Visible in 'trend' and 'export' output.
    python process-framework/scripts/test/performance_db.py trend --test-id BM-NNN --last 10
    python process-framework/scripts/test/performance_db.py regressions
    python process-framework/scripts/test/performance_db.py export --format csv
    python process-framework/scripts/test/performance_db.py list-test-ids
    python process-framework/scripts/test/performance_db.py list-test-ids --filter PH-007

Multi-metric tests record an explicit metric name via --metric (e.g.
``record --test-id PH-001 --metric scan``). Each (test_id, metric) pair is
stored as separate row data; metric is NULL for single-metric tests.

Tolerances are sourced from the project's performance test tracking file at
test/state-tracking/permanent/performance-test-tracking.md (relative to project
root). The script reads the Test ID, Metric, and Tolerance columns of the
markdown tables and keys tolerances by (test_id, metric) tuples. If the file
is absent or no rows parse, tolerance checks silently no-op — useful when
adopting this script in a project that has not yet defined performance
thresholds.

Tolerance column format (one entry per row, single-metric):
  - '<3s', '>50 files/sec'                       → operator + threshold + unit
  - Non-band entries (e.g., '100% rate')         → skipped
"""

import argparse
import csv
import io
import json
import re
import sqlite3
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def _project_root() -> Path:
    """Resolve project root.

    Script lives at process-framework/scripts/test/performance_db.py,
    so project root is 4 parents up.
    """
    return Path(__file__).resolve().parent.parent.parent.parent


def _resolve_db_path() -> Path:
    """Resolve database path to test/state-tracking/permanent/."""
    return _project_root() / "test" / "state-tracking" / "permanent" / "performance-results.db"


def _resolve_tracking_path() -> Path:
    """Resolve the performance test tracking markdown path."""
    return (
        _project_root() / "test" / "state-tracking" / "permanent" / "performance-test-tracking.md"
    )


DB_PATH = _resolve_db_path()
TRACKING_PATH = _resolve_tracking_path()

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_id TEXT NOT NULL,
    metric TEXT,
    value REAL NOT NULL,
    unit TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    git_commit TEXT,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_results_test_id ON results(test_id);
CREATE INDEX IF NOT EXISTS idx_results_timestamp ON results(timestamp);
"""

# Splits legacy composite test_ids like 'PH-001-scan' or 'PH-007-op-delta' into
# (base_test_id, metric). Used during the one-time migration that introduced
# the explicit `metric` column.
_LEGACY_COMPOSITE_RE = re.compile(r"^([A-Z]+-\d+)-(.+)$")


def _run_migrations(conn: sqlite3.Connection) -> None:
    """Apply idempotent schema migrations.

    Migration 1 (2026-05-04, PF-IMP-717): introduce explicit `metric` column.

    Detects pre-migration databases that lack the `metric` column, adds it,
    and backfills by parsing legacy composite test_ids of the form
    ``<TestID>-<metric>`` into separate (test_id, metric) values. Rows whose
    test_id does not match the composite pattern are left with metric=NULL
    (single-metric tests).

    Idempotent: subsequent calls observe the column already present and
    return immediately.
    """
    columns = {row[1] for row in conn.execute("PRAGMA table_info(results)")}
    if "metric" in columns:
        return
    with conn:
        conn.execute("ALTER TABLE results ADD COLUMN metric TEXT")
        rows = conn.execute("SELECT id, test_id FROM results").fetchall()
        for row in rows:
            match = _LEGACY_COMPOSITE_RE.match(row["test_id"])
            if match:
                base_id, metric = match.group(1), match.group(2)
                conn.execute(
                    "UPDATE results SET test_id = ?, metric = ? WHERE id = ?",
                    (base_id, metric, row["id"]),
                )


# Tolerance definitions parsed from the project's performance-test-tracking.md.
# Keyed by (test_id, metric_or_None) tuples; value is (operator, threshold, unit).
# 'gt' = value must be greater than threshold (throughput)
# 'lt' = value must be less than threshold (latency)

ToleranceKey = tuple[str, str | None]

# Matches a single-metric tolerance like '<3s' or '>50 files/sec'.
_TOLERANCE_RE = re.compile(
    r"^\s*(?P<op>[<>])\s*(?P<threshold>\d+(?:\.\d+)?)\s*(?P<unit>[a-zA-Z%][a-zA-Z/%]*)\s*$"
)


def _parse_tolerance(cell: str) -> tuple[str, float, str] | None:
    """Parse a single-metric tolerance cell.

    Returns (op, threshold, unit) or None if the cell is empty, a placeholder
    ('—'), or a non-band entry (e.g., '100% rate').
    """
    if not cell or cell == "—":
        return None
    match = _TOLERANCE_RE.match(cell)
    if not match:
        return None
    op = "lt" if match.group("op") == "<" else "gt"
    return op, float(match.group("threshold")), match.group("unit")


def _normalize_metric(cell: str) -> str | None:
    """Normalize a Metric column cell to its (test_id, metric) tuple form.

    Returns None for single-metric tests (cells empty or '—'); otherwise the
    metric name as written.
    """
    if not cell or cell == "—":
        return None
    return cell


def _load_tracking() -> tuple[dict[ToleranceKey, tuple[str, float, str]], set[ToleranceKey]]:
    """Parse tolerances and lifecycle status from performance-test-tracking.md.

    Reads the markdown file and extracts, for each data row:
      - Test ID (column 1), Metric (column 2), Status (column 5),
        Tolerance (column 7).

    Multi-metric tests have one row per metric; single-metric tests have
    Metric = '—'. Tolerances key by (test_id, metric_or_None).

    Rows in `⚠️ Needs Re-baseline` are excluded from the tolerances dict (so
    regressions reporting cannot flag stale-baseline artifacts as real
    regressions) and surfaced in a separate set for informational footers.

    Returns ({}, set()) (graceful degradation) if the file is missing or no
    rows parse — tolerance checks then silently no-op. This lets the script
    work in projects that have not yet defined performance thresholds.
    """
    if not TRACKING_PATH.exists():
        return {}, set()
    try:
        content = TRACKING_PATH.read_text(encoding="utf-8")
    except OSError as e:
        print(
            f"Warning: could not read tracking file {TRACKING_PATH}: {e}",
            file=sys.stderr,
        )
        return {}, set()

    tolerances: dict[ToleranceKey, tuple[str, float, str]] = {}
    needs_rebaseline: set[ToleranceKey] = set()
    for line in content.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [cell.strip() for cell in line.split("|")]
        # Leading and trailing '|' produce empty edge cells. A data row in any
        # of the inventory tables has at least 13 column-cells (12 data columns
        # + 2 edges, post Metric-column addition).
        if len(cells) < 9:
            continue
        test_id = cells[1]
        if not test_id:
            continue
        # Skip header rows ("Test ID") and separator rows ("---|---|...").
        if test_id.lower() == "test id":
            continue
        if set(test_id) <= {"-", ":", " "}:
            continue
        metric = _normalize_metric(cells[2])
        key: ToleranceKey = (test_id, metric)
        # Status column: rows in `⚠️ Needs Re-baseline` have invalid tolerances
        # by definition — record the (test_id, metric) and skip the tolerance.
        if "Needs Re-baseline" in cells[5]:
            needs_rebaseline.add(key)
            continue
        parsed = _parse_tolerance(cells[7])
        if parsed is None:
            continue
        tolerances[key] = parsed

    return tolerances, needs_rebaseline


TOLERANCES, NEEDS_REBASELINE_KEYS = _load_tracking()


def _get_git_commit() -> str | None:
    """Get current git commit hash."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def _connect() -> sqlite3.Connection:
    """Connect to the database, ensuring schema and migrations are current."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    conn.executescript(SCHEMA_SQL)
    _run_migrations(conn)
    return conn


def cmd_init(args: argparse.Namespace) -> None:
    """Initialize the database schema."""
    conn = _connect()
    conn.close()
    print(f"Database initialized at: {DB_PATH}")


def _split_legacy_test_id(test_id: str, metric: str | None) -> tuple[str, str | None]:
    """If a legacy composite test_id is passed without an explicit --metric,
    split it into (base_test_id, metric). Otherwise pass through unchanged.

    Transitional shim during the PF-IMP-717 deprecation of the suffix
    convention — lets old documentation invocations keep working until docs
    catch up.
    """
    if metric is not None:
        return test_id, metric
    match = _LEGACY_COMPOSITE_RE.match(test_id)
    if match:
        return match.group(1), match.group(2)
    return test_id, None


def _format_test_label(test_id: str, metric: str | None) -> str:
    """Format a (test_id, metric) pair for human-readable output."""
    return f"{test_id} [{metric}]" if metric else test_id


def cmd_record(args: argparse.Namespace) -> None:
    """Record a performance test result."""
    test_id, metric = _split_legacy_test_id(args.test_id, args.metric)
    conn = _connect()

    timestamp = datetime.now().isoformat(timespec="seconds")
    git_commit = _get_git_commit()

    conn.execute(
        "INSERT INTO results (test_id, metric, value, unit, timestamp, git_commit, notes) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)",
        (test_id, metric, args.value, args.unit, timestamp, git_commit, args.notes),
    )
    conn.commit()

    label = _format_test_label(test_id, metric)
    print(f"Recorded: {label} = {args.value} {args.unit}")
    if git_commit:
        print(f"  Commit: {git_commit}")
    if args.notes:
        print(f"  Notes: {args.notes}")

    # Check tolerance
    key = (test_id, metric)
    if key in TOLERANCES:
        op, threshold, tol_unit = TOLERANCES[key]
        if op == "gt" and args.value < threshold:
            print(f"  WARNING: Below tolerance! {args.value} < {threshold} {tol_unit}")
        elif op == "lt" and args.value > threshold:
            print(f"  WARNING: Above tolerance! {args.value} > {threshold} {tol_unit}")

    conn.close()


def _trend_for_metric(
    conn: sqlite3.Connection, test_id: str, metric: str | None, last: int
) -> None:
    """Print one trend block for a single (test_id, metric) series."""
    if metric is None:
        rows = conn.execute(
            "SELECT value, unit, timestamp, git_commit, notes "
            "FROM results WHERE test_id = ? AND metric IS NULL "
            "ORDER BY timestamp DESC LIMIT ?",
            (test_id, last),
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT value, unit, timestamp, git_commit, notes "
            "FROM results WHERE test_id = ? AND metric = ? "
            "ORDER BY timestamp DESC LIMIT ?",
            (test_id, metric, last),
        ).fetchall()

    label = _format_test_label(test_id, metric)
    if not rows:
        print(f"No results found for {label}")
        return

    print(f"Trend for {label} (last {len(rows)} results):")
    print(f"{'Timestamp':<22} {'Value':>12} {'Unit':<12} {'Commit':<10} {'Notes'}")
    print("-" * 80)
    for row in reversed(rows):
        notes = row["notes"] or ""
        commit = row["git_commit"] or ""
        print(
            f"{row['timestamp']:<22} {row['value']:>12.3f} {row['unit']:<12} {commit:<10} {notes}"
        )

    values = [row["value"] for row in rows]
    if len(values) >= 2:
        latest = values[0]
        oldest = values[-1]
        change_pct = ((latest - oldest) / oldest) * 100 if oldest != 0 else 0
        latest_unit = rows[0]["unit"] or ""
        direction = (
            "improvement"
            if _is_improvement(test_id, metric, change_pct, latest_unit)
            else "degradation"
        )
        print(f"\nChange over period: {change_pct:+.1f}% ({direction})")
        print(f"Range: {min(values):.3f} - {max(values):.3f}")

    key = (test_id, metric)
    if key in TOLERANCES:
        op, threshold, unit = TOLERANCES[key]
        latest_val = values[0]
        status = "PASS"
        if op == "gt" and latest_val < threshold:
            status = "FAIL"
        elif op == "lt" and latest_val > threshold:
            status = "FAIL"
        print(f"Tolerance: {'>' if op == 'gt' else '<'}{threshold} {unit} — {status}")


def cmd_trend(args: argparse.Namespace) -> None:
    """Show trend for a specific test (and optional metric).

    With --metric, shows the trend for that single metric. Without --metric,
    shows trends for every metric recorded under this test_id (including the
    NULL-metric series for single-metric tests).
    """
    test_id, metric = _split_legacy_test_id(args.test_id, args.metric)
    conn = _connect()

    if metric is not None:
        _trend_for_metric(conn, test_id, metric, args.last)
    else:
        metrics = [
            row[0]
            for row in conn.execute(
                "SELECT DISTINCT metric FROM results WHERE test_id = ? "
                "ORDER BY metric IS NULL, metric",
                (test_id,),
            ).fetchall()
        ]
        if not metrics:
            print(f"No results found for {test_id}")
        else:
            for i, m in enumerate(metrics):
                if i > 0:
                    print()
                _trend_for_metric(conn, test_id, m, args.last)

    conn.close()


def _is_improvement(test_id: str, metric: str | None, change_pct: float, unit: str = "") -> bool:
    """Determine if a percentage change is an improvement based on the test type.

    Uses the tolerance op when (test_id, metric) is known. Falls back to a
    unit-string heuristic (rate units containing '/' are treated as throughput)
    when the pair has no tolerance — covers tests whose row is not yet in the
    tracking markdown. Defaults to latency semantics (lower is better) otherwise.
    """
    key = (test_id, metric)
    if key in TOLERANCES:
        op = TOLERANCES[key][0]
        # For throughput (gt), positive change is improvement
        # For latency (lt), negative change is improvement
        return (op == "gt" and change_pct > 0) or (op == "lt" and change_pct < 0)
    if "/" in unit:
        return change_pct > 0
    return change_pct < 0


def cmd_regressions(args: argparse.Namespace) -> None:
    """Show all tests where the latest result violates tolerance."""
    conn = _connect()

    # Get the latest result for each (test_id, metric) pair.
    rows = conn.execute(
        "SELECT test_id, metric, value, unit, timestamp, git_commit "
        "FROM results r1 WHERE timestamp = ("
        "  SELECT MAX(timestamp) FROM results r2 "
        "  WHERE r2.test_id = r1.test_id "
        "    AND ((r2.metric IS NULL AND r1.metric IS NULL) OR r2.metric = r1.metric)"
        ") ORDER BY test_id, metric IS NULL, metric"
    ).fetchall()

    if not rows:
        print("No results in database.")
        conn.close()
        return

    regressions = []
    for row in rows:
        key = (row["test_id"], row["metric"])
        if key in TOLERANCES:
            op, threshold, unit = TOLERANCES[key]
            val = row["value"]
            failed = (op == "gt" and val < threshold) or (op == "lt" and val > threshold)
            if failed:
                regressions.append(
                    {
                        "label": _format_test_label(row["test_id"], row["metric"]),
                        "value": val,
                        "unit": row["unit"],
                        "threshold": threshold,
                        "op": op,
                        "timestamp": row["timestamp"],
                        "commit": row["git_commit"],
                    }
                )

    if not regressions:
        print(f"No regressions detected. ({len(rows)} series checked)")
    else:
        print(f"REGRESSIONS DETECTED ({len(regressions)}/{len(rows)} series):\n")
        for r in regressions:
            op_str = ">" if r["op"] == "gt" else "<"
            print(f"  {r['label']}: {r['value']:.3f} {r['unit']}")
            print(f"    Tolerance: {op_str}{r['threshold']} {r['unit']}")
            print(f"    Captured: {r['timestamp']} (commit: {r['commit'] or 'unknown'})")
            print()

    # Surface series excluded from the regressions check because their tolerance
    # is known-stale (status `⚠️ Needs Re-baseline`). The next action for these
    # is re-baseline (PF-TSK-085), not Bug Triage.
    present_keys = {(row["test_id"], row["metric"]) for row in rows}
    skipped_with_results = sorted(
        _format_test_label(tid, m) for (tid, m) in NEEDS_REBASELINE_KEYS if (tid, m) in present_keys
    )
    if skipped_with_results:
        print(
            f"Note: {len(skipped_with_results)} series skipped (status: "
            f"⚠️ Needs Re-baseline) — re-baseline via PF-TSK-085 to refresh "
            f"tolerances:"
        )
        for label in skipped_with_results:
            print(f"  - {label}")

    conn.close()


def cmd_list_test_ids(args: argparse.Namespace) -> None:
    """List distinct (test_id, metric) series with sample counts and last-seen."""
    conn = _connect()

    rows = conn.execute(
        "SELECT test_id, metric, COUNT(*) AS samples, MAX(timestamp) AS last_seen "
        "FROM results GROUP BY test_id, metric "
        "ORDER BY test_id, metric IS NULL, metric"
    ).fetchall()
    conn.close()

    if args.filter:
        f = args.filter.lower()
        rows = [
            r
            for r in rows
            if f in r["test_id"].lower() or (r["metric"] and f in r["metric"].lower())
        ]

    if not rows:
        if args.filter:
            print(f"No series match filter '{args.filter}'.")
        else:
            print("No results recorded yet.")
        return

    labels = [_format_test_label(r["test_id"], r["metric"]) for r in rows]
    id_width = max(len("Test ID"), max(len(label) for label in labels)) + 2
    samples_width = max(len("Samples"), max(len(str(r["samples"])) for r in rows)) + 2
    last_seen_width = max(len("Last Seen"), max(len(r["last_seen"] or "") for r in rows)) + 2

    print(
        f"{'Test ID':<{id_width}}{'Samples':>{samples_width}}  " f"{'Last Seen':<{last_seen_width}}"
    )
    print("-" * (id_width + samples_width + 2 + last_seen_width))
    for row, label in zip(rows, labels):
        last_seen = row["last_seen"] or ""
        print(
            f"{label:<{id_width}}{row['samples']:>{samples_width}}  "
            f"{last_seen:<{last_seen_width}}"
        )
    print(f"\nTotal: {len(rows)} distinct series")


def cmd_export(args: argparse.Namespace) -> None:
    """Export all results."""
    conn = _connect()

    rows = conn.execute(
        "SELECT test_id, metric, value, unit, timestamp, git_commit, notes "
        "FROM results ORDER BY test_id, metric IS NULL, metric, timestamp"
    ).fetchall()

    if not rows:
        print("No results to export.")
        conn.close()
        return

    if args.format == "csv":
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["test_id", "metric", "value", "unit", "timestamp", "git_commit", "notes"])
        for row in rows:
            writer.writerow(
                [
                    row["test_id"],
                    row["metric"] or "",
                    row["value"],
                    row["unit"],
                    row["timestamp"],
                    row["git_commit"] or "",
                    row["notes"] or "",
                ]
            )
        print(output.getvalue(), end="")
    elif args.format == "json":
        data = [
            {
                "test_id": row["test_id"],
                "metric": row["metric"],
                "value": row["value"],
                "unit": row["unit"],
                "timestamp": row["timestamp"],
                "git_commit": row["git_commit"],
                "notes": row["notes"],
            }
            for row in rows
        ]
        print(json.dumps(data, indent=2))

    conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Performance Results Database — store and query performance test measurements"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # init
    subparsers.add_parser("init", help="Initialize the database schema")

    # record
    rec = subparsers.add_parser("record", help="Record a performance test result")
    rec.add_argument("--test-id", required=True, help="Test identifier (e.g., BM-NNN)")
    rec.add_argument(
        "--metric",
        default=None,
        help='Metric name for multi-metric tests (e.g., "scan", "move"). '
        "Omit for single-metric tests.",
    )
    rec.add_argument("--value", type=float, required=True, help="Measured value")
    rec.add_argument(
        "--unit", required=True, help='Unit of measurement (e.g., "files/sec", "seconds")'
    )
    rec.add_argument("--notes", default=None, help="Optional notes about this measurement")

    # trend
    trend = subparsers.add_parser("trend", help="Show trend for a specific test")
    trend.add_argument("--test-id", required=True, help="Test identifier")
    trend.add_argument(
        "--metric",
        default=None,
        help="Metric name for multi-metric tests. Omit to list all metrics for this test.",
    )
    trend.add_argument(
        "--last", type=int, default=10, help="Number of recent results (default: 10)"
    )

    # regressions
    subparsers.add_parser("regressions", help="Show tests where latest result violates tolerance")

    # export
    exp = subparsers.add_parser("export", help="Export all results")
    exp.add_argument(
        "--format", choices=["csv", "json"], default="csv", help="Export format (default: csv)"
    )

    # list-test-ids
    list_ids = subparsers.add_parser(
        "list-test-ids",
        help="List distinct (test_id, metric) series with sample counts and last-seen timestamp",
    )
    list_ids.add_argument("--filter", help="Case-insensitive substring filter on test_id or metric")

    args = parser.parse_args()

    commands = {
        "init": cmd_init,
        "record": cmd_record,
        "trend": cmd_trend,
        "regressions": cmd_regressions,
        "export": cmd_export,
        "list-test-ids": cmd_list_test_ids,
    }

    commands[args.command](args)


if __name__ == "__main__":
    main()
