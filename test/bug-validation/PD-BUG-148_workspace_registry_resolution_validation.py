#!/usr/bin/env python3
"""
Manual validation for PD-BUG-148: the Control Panel supervised the wrong list of
projects at every workspace that is not a leaf.

The panel finds its registry through a precedence chain. Two of the tiers are
auto-locates, and which one answers depends on the workspace's shape:

    workspace shape          owns children?   supervisor list lives in
    -----------------------  ---------------  --------------------------------
    framework-builder        yes              its own framework-registry.json
    framework                yes              its own project-registry.json
    leaf project             no               the registry its PARENT owns

Before the fix the panel only ever did the parent hop, joining a hardcoded
``process-framework-central/project-registry.json`` to whatever the parent
pointer named. That is right for a leaf and wrong for everything else, because a
parent pointer names the PARENT — so a framework got its parent's list instead of
its own, and a framework-builder got nothing at all (its parent's central holds a
``framework-registry.json``, which the loader rejected outright).

The follow-up defect this script also covers (CR-1): the own-registry tier was
reachable only through an explicit ``--project-root``, but the panel launchers
(``linkwatcher-panel.bat`` / ``.ps1``) forward their arguments and add none. So
every manual launch still fell through to the parent hop and showed the wrong
list, with nothing in the window to tell the two apart. The current directory is
now treated as an implied workspace root.

What is deliberately NOT changed: the implied root is the current directory
taken EXACTLY, never walked up. A producer's blueprint tree carries a zero-row
seed registry, and adopting one from an ancestor would render the calm "no
registered projects" empty state while daemons were in fact running — a wrong
answer that looks like a right one. Standing in a blueprint root still reaches
that seed; standing anywhere below it does not.

How to validate:

  1. python test/bug-validation/PD-BUG-148_workspace_registry_resolution_validation.py

     Builds a throwaway portfolio with all four workspace shapes and resolves
     each one twice — once with the pre-fix rule (own registry reachable only
     via an explicit --project-root) and once with the shipped rule:

       -> "PRE-FIX"  = the old behaviour. The framework and framework-builder
          rows show a list that is not theirs.
       -> "POST-FIX" = each workspace supervises its own list; the leaf is
          unchanged, which is the point — the one path that worked must stay
          working.

     Exit 0 only when the pre-fix half really does resolve the wrong registry
     AND the post-fix half resolves the right one. A pre-fix half that already
     looks correct means the halves are not different and the run proves
     nothing.

  2. Then look at YOUR real workspaces, which the script reports read-only at
     the end. Nothing is written or launched there.

  3. To see it in the product, open the panel from a framework workspace root
     (a directory holding ``process-framework-central/project-registry.json``):

         cd <that workspace>
         linkwatcher-panel.bat

     Before the fix the list showed the parent's registered workspaces. It now
     shows that workspace's own projects. ``panel.log`` in the install directory
     records which registry answered, on a line reading
     ``registry resolved via workspace: <path>`` (or ``via pointer`` for a leaf).
"""

import json
import shutil
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "src"))

from linkwatcher.linkwatcher_control_panel import settings as S  # noqa: E402
from linkwatcher.linkwatcher_control_panel.discovery import load_projects  # noqa: E402

SEP = "=" * 78


# --------------------------------------------------------------------------- #
# Throwaway portfolio
# --------------------------------------------------------------------------- #
def _write_registry(root: Path, filename: str, key: str, names) -> Path:
    """Give *root* its own child registry listing *names*."""
    registry = root / "process-framework-central" / filename
    registry.parent.mkdir(parents=True, exist_ok=True)
    rows = {f"ID-{i:03d}": {"name": n, "path": str(root / n)} for i, n in enumerate(names, 1)}
    registry.write_text(json.dumps({key: rows}, indent=2), encoding="utf-8")
    return registry


def _write_pointer(root: Path, parent: Path, face: str = "process-framework") -> None:
    """Point *root* at its parent workspace through its framework face."""
    face_dir = root / face
    face_dir.mkdir(parents=True, exist_ok=True)
    (face_dir / ".framework-parent-pointer").write_text(str(parent), encoding="utf-8")


def build_portfolio(base: Path) -> dict:
    """A miniature of the real shape: producer -> framework -> leaf, plus a seed."""
    producer = base / "Producer"
    framework = base / "Framework"
    leaf = base / "LeafProject"
    blueprint = producer / "blueprint"

    # The producer is self-hosted: its face lives under blueprint/, and it points
    # at itself.  It owns a framework registry listing its child frameworks.
    _write_registry(producer, "framework-registry.json", "frameworks", ["Framework", "Other"])
    _write_pointer(producer, producer, face="blueprint/process-framework")
    (producer / "doc").mkdir(parents=True, exist_ok=True)
    (producer / "doc" / "project-config.json").write_text(
        json.dumps({"paths": {"process_framework": "blueprint/process-framework"}}),
        encoding="utf-8",
    )

    # The framework owns its own project registry AND points at the producer —
    # the two-answers case where the pre-fix rule picked the wrong one.
    _write_registry(framework, "project-registry.json", "projects", ["LeafProject", "Another"])
    _write_pointer(framework, producer)

    # The leaf owns nothing; its supervisor list genuinely lives in its parent.
    _write_pointer(leaf, framework)

    # The blueprint tree carries a ZERO-ROW seed registry (the hazard).
    _write_registry(blueprint, "project-registry.json", "projects", [])
    _write_pointer(blueprint, producer)
    (blueprint / "doc").mkdir(parents=True, exist_ok=True)

    return {
        "framework-builder": producer,
        "framework": framework,
        "leaf project": leaf,
        "blueprint (seed)": blueprint,
        "below blueprint": blueprint / "doc",
    }


# --------------------------------------------------------------------------- #
# The two rules
# --------------------------------------------------------------------------- #
def resolve(cwd: Path, *, prefix_rule: bool):
    """Resolve as the panel would for a launcher launch (no --project-root).

    ``prefix_rule`` reproduces the pre-fix behaviour exactly, by making the
    own-registry lookup miss for the implied root only — the parent hop still
    consults it, which is what the pre-fix code did too.
    """
    original = S._own_child_registry
    if prefix_rule:

        def patched(root, *args, **kwargs):
            # *args/**kwargs pass the diagnostic de-duplication set through
            # untouched; this stub only changes WHICH roots miss, never how the
            # real lookup behaves for the others.
            return None if Path(root) == Path(cwd) else original(root, *args, **kwargs)

        S._own_child_registry = patched
    try:
        return S.resolve_registry_path(None, settings=None, env={}, project_root=None, cwd=cwd)
    finally:
        S._own_child_registry = original


def describe(resolution) -> str:
    if not resolution.resolved:
        return "UNRESOLVED (error banner)"
    load = load_projects(resolution.path)
    names = ", ".join(p.name for p in load.projects) or "<empty>"
    return f"via {resolution.source:9} -> {len(load.projects)} row(s): {names}"


def report(title: str, shapes: dict, *, prefix_rule: bool) -> dict:
    print(f"\n{title}")
    print("-" * len(title))
    out = {}
    for label, cwd in shapes.items():
        out[label] = resolve(cwd, prefix_rule=prefix_rule)
        print(f"  cd {label:20} {describe(out[label])}")
    return out


# --------------------------------------------------------------------------- #
# Real workspaces (read-only)
# --------------------------------------------------------------------------- #
def report_real_workspaces() -> None:
    print(f"\n{SEP}\nYOUR REAL WORKSPACES (read-only — nothing is written or launched)\n{SEP}")
    siblings = sorted(p for p in REPO_ROOT.parent.iterdir() if p.is_dir())
    shown = 0
    for root in siblings:
        owns = S._own_child_registry(root) is not None
        points = S._read_parent_pointer(root) is not None
        if not (owns or points):
            continue
        res = S.resolve_registry_path(None, settings=None, env={}, project_root=None, cwd=root)
        print(f"  cd {root.name:22} {describe(res)}")
        shown += 1
    if not shown:
        print("  (no framework workspaces found beside this repository — nothing to show)")


# --------------------------------------------------------------------------- #
def main() -> int:
    base = Path(tempfile.mkdtemp(prefix="pd-bug-148-"))
    print(f"{SEP}\nPD-BUG-148 — which project list does the panel supervise?\n{SEP}")
    print(f"Throwaway portfolio: {base}")
    print("Each row is a manual launch (`linkwatcher-panel.bat`) from that directory.")

    try:
        shapes = build_portfolio(base)
        before = report(
            "PRE-FIX  (own registry needs an explicit --project-root)", shapes, prefix_rule=True
        )
        after = report(
            "POST-FIX (shipped — the current directory is an implied root)",
            shapes,
            prefix_rule=False,
        )

        print(f"\n{SEP}\nVERDICT\n{SEP}")
        problems = []

        # The framework must have been wrong before and right after.
        fw = shapes["framework"]
        own = S._own_child_registry(fw)
        if before["framework"].path == own:
            problems.append(
                "pre-fix half already resolved the framework's OWN registry "
                "— the halves are not different, so this run proves nothing"
            )
        if after["framework"].path != own:
            problems.append("post-fix half did not resolve the framework's own registry")

        # The framework-builder likewise.
        pr = shapes["framework-builder"]
        if after["framework-builder"].path != S._own_child_registry(pr):
            problems.append("post-fix half did not resolve the framework-builder's own registry")

        # The leaf must be untouched — the one path that always worked.
        if before["leaf project"].path != after["leaf project"].path:
            problems.append("leaf resolution CHANGED; the working path must stay working")

        # The implied root must not walk up into the seed.
        if after["below blueprint"].source == "workspace":
            problems.append("the implied root walked up and claimed an ancestor's seed registry")

        for label in ("framework", "framework-builder"):
            print(f"  {label:18} was {describe(before[label])}")
            print(f"  {'':18} now {describe(after[label])}")
        print(f"  {'leaf project':18} unchanged: {describe(after['leaf project'])}")
        print(f"  {'below blueprint':18} seed out of reach: {describe(after['below blueprint'])}")
        print(
            f"\n  Accepted residual: standing in the blueprint root itself still reaches its\n"
            f"  zero-row seed -> {describe(after['blueprint (seed)'])}.\n"
            f"  panel.log names the registry that answered, which is how you tell."
        )

        if problems:
            print("\n  RESULT: FAIL")
            for problem in problems:
                print(f"    - {problem}")
            return 1
        print("\n  RESULT: PASS — each workspace supervises its own list; the leaf is unchanged.")
    finally:
        report_real_workspaces()
        shutil.rmtree(base, ignore_errors=True)
        print(f"\nThrowaway portfolio removed: {base}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
