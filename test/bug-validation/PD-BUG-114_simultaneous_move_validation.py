"""
Manual validation test for PD-BUG-114: relative link not updated when both the
referencing and the referenced file move in the same operation.

PURPOSE:
  Verify that when file A links to file B and BOTH files move in one operation
  (two quick `mv` commands — both files leave their old disk locations before
  LinkWatcher processes either event), A's link to B is rewritten to account
  for BOTH changes: A's new depth and B's new directory.

HOW TO RUN:
  python test/bug-validation/PD-BUG-114_simultaneous_move_validation.py

WHAT IT DOES (reproducible by hand: create the files, then run both `mv`
commands in one shell line while LinkWatcher runs):
  1. Creates a temp project mirroring the reported instance:
       state-tracking/temporary/A.md   (links to B and twice to unmoved C)
       proposals/B.md
       other/C.md
  2. Initializes LinkWatcher, then moves BOTH files on disk first:
       A -> state-tracking/temporary/old/A.md
       B -> proposals/old/B.md
     and only then delivers the two move events (both orders are shown).
  3. Prints A.md BEFORE and AFTER so you can compare.

EXPECTED RESULT (fixed):
  - [B](../../proposals/B.md)  ->  [B](../../../proposals/old/B.md)
  - Both [C](../../other/C.md) links re-depthed to ../../../other/C.md
  - Same outcome in BOTH event orders.

PRE-FIX BEHAVIOUR (the bug):
  - The C links are re-depthed correctly, but the B link stays exactly as
    authored (../../proposals/B.md) — broken, resolving to neither the old
    nor the new location. LinkWatcher reports nothing (silent skip).
"""

import shutil
import sys
import tempfile
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from watchdog.events import FileMovedEvent  # noqa: E402

from linkwatcher.service import LinkWatcherService  # noqa: E402


def setup_project(root: Path):
    (root / "state-tracking" / "temporary" / "old").mkdir(parents=True)
    (root / "proposals" / "old").mkdir(parents=True)
    (root / "other").mkdir(parents=True)

    a = root / "state-tracking" / "temporary" / "A.md"
    b = root / "proposals" / "B.md"
    c = root / "other" / "C.md"

    b.write_text("# B\n", encoding="utf-8")
    c.write_text("# C\n", encoding="utf-8")
    a.write_text(
        "# A\n"
        "Link to moved-with-me: [B](../../proposals/B.md)\n"
        "Link to unmoved 1: [C](../../other/C.md)\n"
        "Link to unmoved 2: [C again](../../other/C.md)\n",
        encoding="utf-8",
    )
    return a, b


def run_order(order: str) -> bool:
    root = Path(tempfile.mkdtemp(prefix=f"pd_bug_114_{order}_"))
    try:
        a_old, b_old = setup_project(root)
        a_new = root / "state-tracking" / "temporary" / "old" / "A.md"
        b_new = root / "proposals" / "old" / "B.md"

        print(f"\n--- Event order: {order} ---")
        print("\nA.md BEFORE:")
        print(a_old.read_text(encoding="utf-8"))

        service = LinkWatcherService(str(root))
        service._initial_scan()

        # Both files move on disk BEFORE either event is processed —
        # this is what two quick `mv` commands produce in reality.
        a_old.rename(a_new)
        b_old.rename(b_new)

        ev_a = FileMovedEvent(str(a_old), str(a_new))
        ev_b = FileMovedEvent(str(b_old), str(b_new))
        events = [ev_a, ev_b] if order == "A-event-first" else [ev_b, ev_a]
        for event in events:
            service.handler.on_moved(event)

        content = a_new.read_text(encoding="utf-8")
        print("A.md AFTER:")
        print(content)

        b_ok = (
            "[B](../../../proposals/old/B.md)" in content
            and "](../../proposals/B.md)" not in content
        )
        c_ok = content.count("(../../../other/C.md)") == 2
        print(f"  B link corrected:      {'PASS' if b_ok else 'FAIL  <-- the bug'}")
        print(f"  C links re-depthed:    {'PASS' if c_ok else 'FAIL'}")
        return b_ok and c_ok
    finally:
        shutil.rmtree(root, ignore_errors=True)


def run_form_preservation():
    """Code review follow-up (2026-08-10): an in-place rename must not reformat links.

    Removing the same-directory early return — required so a target that
    vanished mid-operation reaches the repair path — initially routed EVERY
    in-place rename through os.path.relpath, which returns a canonical path.
    Links that were never wrong got rewritten: ./x to x, backslashes to
    forward slashes, dir/ to dir.  Reproducible by hand: rename any file in
    place while LinkWatcher runs and diff it.
    """
    root = Path(tempfile.mkdtemp())
    try:
        (root / "docs").mkdir()
        (root / "assets").mkdir()
        (root / "assets" / "logo.png").write_bytes(b"x")
        (root / "docs" / "target.md").write_text("# T\n", encoding="utf-8")

        a_old = root / "docs" / "A.md"
        before = (
            "# A\n"
            "Dot-slash form:     [T](./target.md)\n"
            "Trailing-slash dir: [assets](../assets/)\n"
        )
        a_old.write_text(before, encoding="utf-8")

        service = LinkWatcherService(str(root))
        service._initial_scan()

        a_new = root / "docs" / "B.md"
        a_old.rename(a_new)  # rename WITHIN docs/ — nothing else moves
        service.handler.on_moved(FileMovedEvent(str(a_old), str(a_new)))
        after = a_new.read_text(encoding="utf-8")

        print("\n--- Scenario 3: in-place rename preserves authored link form ---")
        print("BEFORE (docs/A.md):")
        print(before)
        print("AFTER  (docs/B.md):")
        print(after)
        ok = after == before
        print(f"  Authored form preserved: {'PASS' if ok else 'FAIL  <-- links reformatted'}")
        return ok
    finally:
        shutil.rmtree(root, ignore_errors=True)


def run_validation():
    print("=" * 64)
    print("PD-BUG-114: Simultaneous-move link update validation")
    print("=" * 64)

    ok1 = run_order("A-event-first")
    ok2 = run_order("B-event-first")
    ok3 = run_form_preservation()

    print("\n" + "=" * 64)
    if ok1 and ok2 and ok3:
        print("RESULT: PASS — link corrected in both event orders, authored form preserved")
    else:
        if not (ok1 and ok2):
            print("RESULT: FAIL — stale link survived (PD-BUG-114 present)")
        if not ok3:
            print("RESULT: FAIL — in-place rename reformatted links that were never wrong")
    print("=" * 64)
    return ok1 and ok2 and ok3


if __name__ == "__main__":
    sys.exit(0 if run_validation() else 1)
