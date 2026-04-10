#!/usr/bin/env python3
"""Performance Results Database — Persistent storage for performance test results.

Stores performance test measurements in a SQLite database,
enabling trend analysis and regression detection.

Usage:
    python process-framework/scripts/test/performance_db.py init
    python process-framework/scripts/test/performance_db.py record \\
        --test-id BM-001 --value 144.0 --unit "files/sec"
    python process-framework/scripts/test/performance_db.py record \\
        --test-id BM-001 --value 144.0 --unit "files/sec" --notes "Post-refactor"

Note: The current git commit (HEAD) is automatically captured with each record.
      Visible in 'trend' and 'export' output.
    python process-framework/scripts/test/performance_db.py trend --test-id BM-001 --last 10
    python process-framework/scripts/test/performance_db.py regressions
    python process-framework/scripts/test/performance_db.py export --format csv
"""

import argparse
import csv
import io
import json
import sqlite3
import subprocess
from datetime import datetime
from pathlib import Path


def _resolve_db_path() -> Path:
    """Resolve database path to test/state-tracking/permanent/.

    Script lives at process-framework/scripts/test/performance_db.py,
    so project root is 4 parents up.
    """
    return (
        Path(__file__).resolve().parent.parent.parent.parent
        / "test"
        / "state-tracking"
        / "permanent"
        / "performance-results.db"
    )


DB_PATH = _resolve_db_path()

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_id TEXT NOT NULL,
    value REAL NOT NULL,
    unit TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    git_commit TEXT,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_results_test_id ON results(test_id);
CREATE INDEX IF NOT EXISTS idx_results_timestamp ON results(timestamp);
"""

# Tolerance definitions: test_id -> (operator, threshold, unit)
# 'gt' = value must be greater than threshold (throughput)
# 'lt' = value must be less than threshold (latency)
TOLERANCES = {
    "BM-001": ("gt", 50.0, "files/sec"),
    "BM-002-add": ("lt", 5.0, "seconds"),
    "BM-002-lookup": ("lt", 2.0, "seconds"),
    "BM-002-update": ("lt", 2.0, "seconds"),
    "BM-003": ("lt", 10.0, "seconds"),
    "PH-001-scan": ("lt", 30.0, "seconds"),
    "PH-001-move": ("lt", 5.0, "seconds"),
    "PH-002-scan": ("lt", 10.0, "seconds"),
    "PH-002-move": ("lt", 3.0, "seconds"),
    "PH-003": ("lt", 15.0, "seconds"),
    "PH-004": ("lt", 10.0, "seconds"),
    "PH-005-total": ("lt", 30.0, "seconds"),
    "PH-005-avg": ("lt", 0.5, "seconds"),
}


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
    """Connect to the database."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    return conn


def cmd_init(args: argparse.Namespace) -> None:
    """Initialize the database schema."""
    conn = _connect()
    conn.executescript(SCHEMA_SQL)
    conn.close()
    print(f"Database initialized at: {DB_PATH}")


def cmd_record(args: argparse.Namespace) -> None:
    """Record a performance test result."""
    conn = _connect()
    conn.executescript(SCHEMA_SQL)

    timestamp = datetime.now().isoformat(timespec="seconds")
    git_commit = _get_git_commit()

    conn.execute(
        "INSERT INTO results (test_id, value, unit, timestamp, git_commit, notes) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (args.test_id, args.value, args.unit, timestamp, git_commit, args.notes),
    )
    conn.commit()

    print(f"Recorded: {args.test_id} = {args.value} {args.unit}")
    if git_commit:
        print(f"  Commit: {git_commit}")
    if args.notes:
        print(f"  Notes: {args.notes}")

    # Check tolerance
    if args.test_id in TOLERANCES:
        op, threshold, _unit = TOLERANCES[args.test_id]
        if op == "gt" and args.value < threshold:
            print(f"  WARNING: Below tolerance! {args.value} < {threshold} {_unit}")
        elif op == "lt" and args.value > threshold:
            print(f"  WARNING: Above tolerance! {args.value} > {threshold} {_unit}")

    conn.close()


def cmd_trend(args: argparse.Namespace) -> None:
    """Show trend for a specific test."""
    conn = _connect()
    conn.executescript(SCHEMA_SQL)

    rows = conn.execute(
        "SELECT value, unit, timestamp, git_commit, notes "
        "FROM results WHERE test_id = ? ORDER BY timestamp DESC LIMIT ?",
        (args.test_id, args.last),
    ).fetchall()

    if not rows:
        print(f"No results found for {args.test_id}")
        conn.close()
        return

    print(f"Trend for {args.test_id} (last {len(rows)} results):")
    print(f"{'Timestamp':<22} {'Value':>12} {'Unit':<12} {'Commit':<10} {'Notes'}")
    print("-" * 80)

    for row in reversed(rows):
        notes = row["notes"] or ""
        commit = row["git_commit"] or ""
        print(
            f"{row['timestamp']:<22} {row['value']:>12.3f} {row['unit']:<12} {commit:<10} {notes}"
        )

    # Summary statistics
    values = [row["value"] for row in rows]
    if len(values) >= 2:
        latest = values[0]
        oldest = values[-1]
        change_pct = ((latest - oldest) / oldest) * 100 if oldest != 0 else 0
        direction = "improvement" if _is_improvement(args.test_id, change_pct) else "degradation"
        print(f"\nChange over period: {change_pct:+.1f}% ({direction})")
        print(f"Range: {min(values):.3f} - {max(values):.3f}")

    # Check tolerance
    if args.test_id in TOLERANCES:
        op, threshold, unit = TOLERANCES[args.test_id]
        latest_val = values[0]
        status = "PASS"
        if op == "gt" and latest_val < threshold:
            status = "FAIL"
        elif op == "lt" and latest_val > threshold:
            status = "FAIL"
        print(f"Tolerance: {'>' if op == 'gt' else '<'}{threshold} {unit} — {status}")

    conn.close()


def _is_improvement(test_id: str, change_pct: float) -> bool:
    """Determine if a percentage change is an improvement based on the test type."""
    if test_id in TOLERANCES:
        op = TOLERANCES[test_id][0]
        # For throughput (gt), positive change is improvement
        # For latency (lt), negative change is improvement
        return (op == "gt" and change_pct > 0) or (op == "lt" and change_pct < 0)
    # Default: assume lower is better (latency)
    return change_pct < 0


def cmd_regressions(args: argparse.Namespace) -> None:
    """Show all tests where the latest result violates tolerance."""
    conn = _connect()
    conn.executescript(SCHEMA_SQL)

    # Get the latest result for each test_id
    rows = conn.execute(
        "SELECT test_id, value, unit, timestamp, git_commit "
        "FROM results r1 WHERE timestamp = ("
        "  SELECT MAX(timestamp) FROM results r2 WHERE r2.test_id = r1.test_id"
        ") ORDER BY test_id"
    ).fetchall()

    if not rows:
        print("No results in database.")
        conn.close()
        return

    regressions = []
    for row in rows:
        tid = row["test_id"]
        if tid in TOLERANCES:
            op, threshold, unit = TOLERANCES[tid]
            val = row["value"]
            failed = (op == "gt" and val < threshold) or (op == "lt" and val > threshold)
            if failed:
                regressions.append(
                    {
                        "test_id": tid,
                        "value": val,
                        "unit": row["unit"],
                        "threshold": threshold,
                        "op": op,
                        "timestamp": row["timestamp"],
                        "commit": row["git_commit"],
                    }
                )

    if not regressions:
        print(f"No regressions detected. ({len(rows)} tests checked)")
    else:
        print(f"REGRESSIONS DETECTED ({len(regressions)}/{len(rows)} tests):\n")
        for r in regressions:
            op_str = ">" if r["op"] == "gt" else "<"
            print(f"  {r['test_id']}: {r['value']:.3f} {r['unit']}")
            print(f"    Tolerance: {op_str}{r['threshold']} {r['unit']}")
            print(f"    Captured: {r['timestamp']} (commit: {r['commit'] or 'unknown'})")
            print()

    conn.close()


def cmd_export(args: argparse.Namespace) -> None:
    """Export all results."""
    conn = _connect()
    conn.executescript(SCHEMA_SQL)

    rows = conn.execute(
        "SELECT test_id, value, unit, timestamp, git_commit, notes "
        "FROM results ORDER BY test_id, timestamp"
    ).fetchall()

    if not rows:
        print("No results to export.")
        conn.close()
        return

    if args.format == "csv":
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["test_id", "value", "unit", "timestamp", "git_commit", "notes"])
        for row in rows:
            writer.writerow(
                [
                    row["test_id"],
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
    rec.add_argument("--test-id", required=True, help="Test identifier (e.g., BM-001)")
    rec.add_argument("--value", type=float, required=True, help="Measured value")
    rec.add_argument(
        "--unit", required=True, help='Unit of measurement (e.g., "files/sec", "seconds")'
    )
    rec.add_argument("--notes", default=None, help="Optional notes about this measurement")

    # trend
    trend = subparsers.add_parser("trend", help="Show trend for a specific test")
    trend.add_argument("--test-id", required=True, help="Test identifier")
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

    args = parser.parse_args()

    commands = {
        "init": cmd_init,
        "record": cmd_record,
        "trend": cmd_trend,
        "regressions": cmd_regressions,
        "export": cmd_export,
    }

    commands[args.command](args)


if __name__ == "__main__":
    main()
