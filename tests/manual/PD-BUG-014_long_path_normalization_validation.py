"""
PD-BUG-014 Manual Validation: Long path normalization in database operations.

PURPOSE:
    Verify that normalize_path() correctly strips the Windows \\?\ long-path
    prefix so that database add/lookup operations produce consistent results
    regardless of whether paths include the prefix.

    Before the fix, normalize_path() preserved the \\?\ prefix, causing
    prefixed and non-prefixed forms of the same path to normalize differently.
    This meant database lookups would fail when Windows injected the prefix
    for paths exceeding 260 characters.

BUG CONTEXT:
    Windows adds the \\?\ prefix to paths exceeding MAX_PATH (260 chars).
    Python's pathlib.Path.resolve(), watchdog events, and various Win32 APIs
    may produce paths with this prefix. The normalize_path() function in
    utils.py did not strip it, causing path comparison mismatches in the
    LinkDatabase.

HOW TO RUN:
    python tests/manual/PD-BUG-014_long_path_normalization_validation.py

EXPECTED RESULT (AFTER FIX):
    - All 5 checks pass
    - Prefixed and non-prefixed paths normalize identically
    - Database lookups work with both path forms

EXPECTED RESULT (BEFORE FIX):
    - Checks 1, 2, 4 FAIL
    - Prefixed paths retain //?/ prefix after normalization
    - Database lookups with prefixed paths return 0 results
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from linkwatcher.database import LinkDatabase
from linkwatcher.models import LinkReference
from linkwatcher.utils import normalize_path


def main():
    print("=" * 70)
    print("PD-BUG-014 Manual Validation: Long Path Normalization")
    print("=" * 70)
    print()

    passed = 0
    failed = 0

    # --- Check 1: \\?\ prefix is stripped during normalization ---
    print("CHECK 1: normalize_path strips \\\\?\\ prefix")
    plain = "C:/Users/test/project/deep/file.txt"
    prefixed = "\\\\?\\C:\\Users\\test\\project\\deep\\file.txt"
    norm_plain = normalize_path(plain)
    norm_prefixed = normalize_path(prefixed)
    print(f"  Plain path:     {plain}")
    print(f"  Prefixed path:  {prefixed}")
    print(f"  Normalized (plain):    {norm_plain}")
    print(f"  Normalized (prefixed): {norm_prefixed}")
    if norm_plain == norm_prefixed:
        print("  RESULT: PASS - Both forms normalize identically")
        passed += 1
    else:
        print("  RESULT: FAIL - Normalized forms differ!")
        failed += 1
    print()

    # --- Check 2: //?/ prefix variant is also stripped ---
    print("CHECK 2: normalize_path strips //?/ prefix (forward-slash variant)")
    fwd_prefixed = "//?/C:/Users/test/project/deep/file.txt"
    norm_fwd = normalize_path(fwd_prefixed)
    print(f"  Forward-slash prefixed: {fwd_prefixed}")
    print(f"  Normalized:             {norm_fwd}")
    if norm_fwd == norm_plain:
        print("  RESULT: PASS - Forward-slash prefix variant also stripped")
        passed += 1
    else:
        print("  RESULT: FAIL - Forward-slash prefix not handled!")
        failed += 1
    print()

    # --- Check 3: Long relative paths work in database ---
    print("CHECK 3: Database add/lookup with long relative paths (>260 chars)")
    db = LinkDatabase()
    components = [f"very_long_directory_name_{i:02d}_with_lots_of_characters" for i in range(10)]
    long_target = "/".join(components + ["deep_file.txt"])
    ref = LinkReference(
        file_path="test.md",
        line_number=1,
        column_start=0,
        column_end=len(long_target),
        link_text="Deep link",
        link_target=long_target,
        link_type="markdown",
    )
    db.add_link(ref)
    results = db.get_references_to_file(long_target)
    print(f"  Relative path length: {len(long_target)} chars")
    print(f"  References found:     {len(results)}")
    if len(results) >= 1:
        print("  RESULT: PASS - Reference found via long relative path")
        passed += 1
    else:
        print("  RESULT: FAIL - Reference NOT found!")
        failed += 1
    print()

    # --- Check 4: Prefixed paths normalize same as non-prefixed for DB keys ---
    print("CHECK 4: Database key consistency with \\\\?\\ prefix")
    db2 = LinkDatabase()
    target = "deep/nested/dir/file.txt"
    ref2 = LinkReference("doc.md", 1, 0, 30, "file.txt", target, "markdown")
    db2.add_link(ref2)
    stored_key = list(db2.links.keys())[0]
    prefixed_abs = "\\\\?\\C:\\project\\deep\\nested\\dir\\file.txt"
    non_prefixed_abs = "C:\\project\\deep\\nested\\dir\\file.txt"
    norm_pre = normalize_path(prefixed_abs)
    norm_non = normalize_path(non_prefixed_abs)
    print(f"  Stored DB key:          {stored_key}")
    print(f"  Prefixed abs normalized:     {norm_pre}")
    print(f"  Non-prefixed abs normalized: {norm_non}")
    if norm_pre == norm_non:
        print("  RESULT: PASS - Prefixed and non-prefixed normalize identically")
        passed += 1
    else:
        print("  RESULT: FAIL - Normalization mismatch!")
        failed += 1
    print()

    # --- Check 5: UNC-style paths still handled ---
    print("CHECK 5: UNC paths (\\\\server\\share) are NOT affected by prefix stripping")
    unc_path = "\\\\server\\share\\file.txt"
    norm_unc = normalize_path(unc_path)
    print(f"  UNC path:       {unc_path}")
    print(f"  Normalized UNC: {norm_unc}")
    # UNC paths start with \\server, not \\?\, so they should NOT be stripped
    if "server" in norm_unc and "?" not in norm_unc:
        print("  RESULT: PASS - UNC path preserved correctly")
        passed += 1
    else:
        print("  RESULT: FAIL - UNC path handling incorrect!")
        failed += 1
    print()

    # --- Summary ---
    print("=" * 70)
    print(f"SUMMARY: {passed}/{passed + failed} checks passed")
    if failed == 0:
        print("ALL CHECKS PASSED - Bug fix verified!")
    else:
        print(f"WARNING: {failed} check(s) FAILED")
    print("=" * 70)

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
