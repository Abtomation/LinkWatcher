#!/usr/bin/env python3
"""Query test metadata from pytest markers via AST parsing.

Reads pytestmark assignments from test files without importing them.
Single source of truth: the markers in the code.

Usage:
    python test_query.py --feature 0.1.1          # Tests covering a feature
    python test_query.py --type unit               # All unit tests
    python test_query.py --summary                 # Test count per feature
    python test_query.py --dump --format yaml      # Full dump for validation
    python test_query.py --dump --format json      # Full dump as JSON
    python test_query.py --file test/automated/unit/test_service.py  # Single file
"""

import argparse
import ast
import json
import os
import sys
from pathlib import Path


def find_project_root():
    """Walk up from script location to find the project root (contains pyproject.toml)."""
    current = Path(__file__).resolve().parent
    for _ in range(10):
        if (current / "pyproject.toml").exists():
            return current
        current = current.parent
    print("ERROR: Could not find project root (no pyproject.toml found)", file=sys.stderr)
    sys.exit(1)


def extract_markers(filepath):
    """Extract pytest markers from a Python file via AST.

    Returns a dict with keys: feature, priority, test_type, specification,
    cross_cutting. Missing markers return None (or [] for cross_cutting).
    """
    markers = {
        "feature": None,
        "priority": None,
        "test_type": None,
        "specification": None,
        "cross_cutting": [],
    }

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            source = f.read()
        tree = ast.parse(source, filename=str(filepath))
    except (SyntaxError, UnicodeDecodeError) as e:
        print(f"WARNING: Could not parse {filepath}: {e}", file=sys.stderr)
        return None

    for node in ast.iter_child_nodes(tree):
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == "pytestmark":
                _parse_pytestmark(node.value, markers)
                return markers

    return None  # No pytestmark found


def _parse_pytestmark(value_node, markers):
    """Parse the pytestmark assignment value (List or single Call)."""
    if isinstance(value_node, ast.List):
        for elt in value_node.elts:
            _parse_marker_call(elt, markers)
    elif isinstance(value_node, ast.Call):
        _parse_marker_call(value_node, markers)


def _parse_marker_call(node, markers):
    """Parse a single pytest.mark.XXX(...) call."""
    if not isinstance(node, ast.Call):
        return

    # Extract marker name from pytest.mark.<name>
    func = node.func
    if not isinstance(func, ast.Attribute):
        return

    marker_name = func.attr

    # Get the first positional argument
    if not node.args:
        return

    arg = node.args[0]

    if marker_name == "feature":
        markers["feature"] = _get_constant(arg)
    elif marker_name == "priority":
        markers["priority"] = _get_constant(arg)
    elif marker_name == "test_type":
        markers["test_type"] = _get_constant(arg)
    elif marker_name == "specification":
        markers["specification"] = _get_constant(arg)
    elif marker_name == "cross_cutting":
        if isinstance(arg, ast.List):
            markers["cross_cutting"] = [_get_constant(e) for e in arg.elts if _get_constant(e)]


def _get_constant(node):
    """Extract a constant value from an AST node."""
    if isinstance(node, ast.Constant):
        return node.value
    return None


def count_test_functions(filepath):
    """Count test functions and methods in a file via AST."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            source = f.read()
        tree = ast.parse(source, filename=str(filepath))
    except (SyntaxError, UnicodeDecodeError):
        return 0

    count = 0
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.name.startswith("test_"):
                count += 1
    return count


def discover_test_files(test_dir):
    """Find all Python test files under the test directory."""
    test_files = []
    for root, _dirs, files in os.walk(test_dir):
        for fname in sorted(files):
            if fname.startswith("test_") and fname.endswith(".py"):
                test_files.append(os.path.join(root, fname))
    return sorted(test_files)


def collect_all(project_root):
    """Collect metadata from all test files. Returns list of dicts."""
    test_dir = project_root / "test" / "automated"
    results = []

    for filepath in discover_test_files(test_dir):
        markers = extract_markers(filepath)
        if markers is None:
            continue

        rel_path = os.path.relpath(filepath, project_root).replace("\\", "/")
        test_count = count_test_functions(filepath)

        entry = {
            "file": rel_path,
            "feature": markers["feature"],
            "priority": markers["priority"],
            "test_type": markers["test_type"],
            "specification": markers["specification"],
            "cross_cutting": markers["cross_cutting"],
            "test_count": test_count,
        }
        results.append(entry)

    return results


def cmd_feature(entries, feature_id):
    """Show tests covering a specific feature (primary or cross-cutting)."""
    matches = []
    for e in entries:
        if e["feature"] == feature_id or feature_id in (e["cross_cutting"] or []):
            matches.append(e)

    if not matches:
        print(f"No tests found for feature {feature_id}")
        return

    print(f"Tests covering feature {feature_id}:")
    print(f"{'File':<65} {'Type':<12} {'Pri':<10} {'Tests':>5}  Role")
    print("-" * 110)
    for e in matches:
        role = "primary" if e["feature"] == feature_id else "cross-cutting"
        print(
            f"{e['file']:<65} {e['test_type'] or '?':<12} "
            f"{e['priority'] or '?':<10} {e['test_count']:>5}  {role}"
        )
    total = sum(e["test_count"] for e in matches)
    print(f"\n{len(matches)} files, {total} test methods")


def cmd_type(entries, test_type):
    """Show all tests of a given type."""
    matches = [e for e in entries if e["test_type"] == test_type]

    if not matches:
        print(f"No tests found with type '{test_type}'")
        return

    print(f"Tests of type '{test_type}':")
    print(f"{'File':<65} {'Feature':<12} {'Pri':<10} {'Tests':>5}")
    print("-" * 95)
    for e in matches:
        print(
            f"{e['file']:<65} {e['feature'] or '?':<12} "
            f"{e['priority'] or '?':<10} {e['test_count']:>5}"
        )
    total = sum(e["test_count"] for e in matches)
    print(f"\n{len(matches)} files, {total} test methods")


def cmd_summary(entries):
    """Show test count per feature."""
    feature_stats = {}
    for e in entries:
        fid = e["feature"] or "unknown"
        if fid not in feature_stats:
            feature_stats[fid] = {"files": 0, "tests": 0, "types": set()}
        feature_stats[fid]["files"] += 1
        feature_stats[fid]["tests"] += e["test_count"]
        if e["test_type"]:
            feature_stats[fid]["types"].add(e["test_type"])

    print(f"{'Feature':<15} {'Files':>5} {'Tests':>6}  Types")
    print("-" * 55)
    total_files = 0
    total_tests = 0
    for fid in sorted(feature_stats.keys()):
        s = feature_stats[fid]
        types_str = ", ".join(sorted(s["types"]))
        print(f"{fid:<15} {s['files']:>5} {s['tests']:>6}  {types_str}")
        total_files += s["files"]
        total_tests += s["tests"]
    print("-" * 55)
    print(f"{'TOTAL':<15} {total_files:>5} {total_tests:>6}")


def cmd_file(entries, file_path):
    """Show metadata for a single file."""
    # Normalize path for matching
    normalized = file_path.replace("\\", "/")
    match = None
    for e in entries:
        if e["file"] == normalized or e["file"].endswith(normalized):
            match = e
            break

    if not match:
        print(f"No metadata found for: {file_path}")
        return

    print(f"File:           {match['file']}")
    print(f"Feature:        {match['feature']}")
    print(f"Priority:       {match['priority']}")
    print(f"Test Type:      {match['test_type']}")
    print(f"Test Count:     {match['test_count']}")
    print(f"Specification:  {match['specification'] or '(none)'}")
    print(
        f"Cross-cutting:  {', '.join(match['cross_cutting']) if match['cross_cutting'] else '(none)'}"  # noqa: E501
    )


def cmd_dump(entries, fmt):
    """Dump all metadata in structured format."""
    if fmt == "json":
        print(json.dumps(entries, indent=2))
    elif fmt == "yaml":
        # Simple YAML output without requiring PyYAML
        print(
            ".git/objects/3a/b045e54f8acd16e0d036a487eb74c269db1d9f# Auto-generated from pytest markers via test_query.py"
        )
        print("# Source of truth: pytestmark in test files")
        print(f"# Total: {len(entries)} files, {sum(e['test_count'] for e in entries)} tests")
        print()
        print("testFiles:")
        for e in entries:
            print(f"  - file: {e['file']}")
            print(f"    feature: \"{e['feature']}\"")
            print(f"    priority: {e['priority']}")
            print(f"    testType: {e['test_type']}")
            print(f"    testCount: {e['test_count']}")
            if e["specification"]:
                print(f"    specification: {e['specification']}")
            if e["cross_cutting"]:
                cc = ", ".join(f'"{x}"' for x in e["cross_cutting"])
                print(f"    crossCuttingFeatures: [{cc}]")
            print()


def main():
    parser = argparse.ArgumentParser(
        description="Query test metadata from pytest markers (AST-based, no imports).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--feature", metavar="ID", help="Show tests covering a feature (e.g., 0.1.1)"
    )
    group.add_argument(
        "--type", metavar="TYPE", help="Show tests of a type (unit/integration/parser/performance)"
    )
    group.add_argument("--summary", action="store_true", help="Test count per feature")
    group.add_argument("--dump", action="store_true", help="Dump all metadata")
    group.add_argument("--file", metavar="PATH", help="Show metadata for a single file")

    parser.add_argument(
        "--format",
        choices=["yaml", "json"],
        default="yaml",
        help="Output format for --dump (default: yaml)",
    )
    parser.add_argument(
        "--root", metavar="DIR", help="Project root directory (auto-detected if not specified)"
    )

    args = parser.parse_args()

    project_root = Path(args.root) if args.root else find_project_root()
    entries = collect_all(project_root)

    if args.feature:
        cmd_feature(entries, args.feature)
    elif args.type:
        cmd_type(entries, args.type)
    elif args.summary:
        cmd_summary(entries)
    elif args.file:
        cmd_file(entries, args.file)
    elif args.dump:
        cmd_dump(entries, args.format)


if __name__ == "__main__":
    main()
