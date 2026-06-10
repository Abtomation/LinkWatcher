#!/usr/bin/env python3
"""
Release-time config-schema propagation for LinkWatcher.

LinkWatcher is the upstream source of the *project-configurable* per-project
validation config schema — the ``--validate`` keys in
``config-examples/linkwatcher-config.yaml``. Downstream projects receive a
per-project validation config copied from a framework-distributed template that
the framework (appdev) ships. When LinkWatcher adds / removes / renames a
project-configurable key, those downstream configs go stale — and appdev only
acts if it *knows* the schema changed. LinkWatcher originates the change, so its
release is the right detection point (PD-FRQ-006 / PF-PRO-039 "Fork 1").

Run at release time by ``install_global.py``, this module:

1. Resolves the appdev framework root via
   ``process-framework/.framework-central-pointer``.
2. Computes a *keys-only* recursive structural diff between LinkWatcher's WIP
   template (the source of truth) and the framework-distributed template in
   appdev. Values are data and are ignored — only the set of config-key *paths*
   is compared. Templates keep data-maps empty (``path_resolution_overrides: {}``),
   so per-project map entries never leak into the schema (see the WIP template's
   header comment).
3. If the key sets differ:
   a. Files **one** IMP into the central process-improvement intake (via
      ``New-ProcessImprovement.ps1``), flagging HIGH priority and a manual
      per-project config update. (Phase-7 intake has no priority cell, so the
      urgency is carried in the IMP text for the triager.)
   b. Only on a successful IMP filing, syncs (overwrites) the appdev template
      with the WIP version so new projects bootstrap with the latest schema.

It is intentionally **non-fatal and best-effort**: if appdev is not reachable
(e.g. a standalone LinkWatcher clone), it skips silently. The cross-repo writes
happen only when the schema actually changes.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from typing import Any

# Paths relative to the LinkWatcher project root.
WIP_TEMPLATE_REL = Path("config-examples/linkwatcher-config.yaml")
CENTRAL_POINTER_REL = Path("process-framework/.framework-central-pointer")
APPDEV_TEMPLATE_REL = Path(
    "blueprint/process-framework/tools/linkWatcher/linkwatcher-config.template.yaml"
)
IMP_SCRIPT_REL = Path("process-framework/scripts/file-creation/support/New-ProcessImprovement.ps1")

IMP_SOURCE = "LinkWatcher release (install_global.py)"


def field_names(data: Any) -> set:
    """Return the set of top-level config *field names* (the schema surface).

    Comparison is deliberately top-level only: a field's value — scalar, list, or
    map — is data and is never inspected. That makes the diff immune to *variable
    keys* (e.g. the folder names under ``path_resolution_overrides``, which differ
    per project: ``blueprint``, ``example``, ...): changing those values never
    registers as a schema change. PD-FRQ-006 targets config *fields* (top-level
    keys), so this is both the faithful and the robust rule.

    If a future config field becomes a nested *fixed-key* struct whose sub-keys
    must also be watched, recurse into that one field via a small allowlist —
    don't make recursion the default (it cannot distinguish fixed-key structs from
    variable-key data-maps without a schema declaration).
    """
    return set(data.keys()) if isinstance(data, dict) else set()


def _load_yaml_keys(path: Path) -> set:
    import yaml  # local import: deps are installed earlier in the release run

    with open(path, "r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if data is None:
        data = {}
    return field_names(data)


def compute_schema_diff(wip_path: Path, appdev_template_path: Path) -> dict:
    """Keys-only diff between the WIP template and the appdev template.

    Returns ``{"added": [...], "removed": [...], "changed": bool}`` where added /
    removed are sorted lists of config-key paths.
    """
    wip_keys = _load_yaml_keys(wip_path)
    appdev_keys = _load_yaml_keys(appdev_template_path)
    added = sorted(wip_keys - appdev_keys)
    removed = sorted(appdev_keys - wip_keys)
    return {"added": added, "removed": removed, "changed": bool(added or removed)}


def resolve_appdev_root(project_root: Path):
    """Return the appdev root from the central pointer, or None if unresolvable."""
    pointer = project_root / CENTRAL_POINTER_REL
    if not pointer.exists():
        return None
    try:
        appdev = Path(pointer.read_text(encoding="utf-8").strip())
    except OSError:
        return None
    return appdev if appdev.is_dir() else None


def _build_imp_text(diff: dict):
    """Return (description, notes) for the schema-change IMP. Description <= 500 chars."""
    parts = []
    if diff["added"]:
        parts.append("added: " + ", ".join(diff["added"]))
    if diff["removed"]:
        parts.append("removed: " + ", ".join(diff["removed"]))
    delta = "; ".join(parts) if parts else "schema changed"

    description = (
        f"LinkWatcher per-project validation config schema changed ({delta}). "
        "Update & configure each project's tools/linkwatcher/linkwatcher-config.yaml. "
        "Recommended priority: HIGH."
    )
    if len(description) > 500:
        description = description[:497] + "..."

    notes = (
        "Auto-filed by LinkWatcher release (propagate_config_schema.py) on a "
        "project-configurable config-schema change (PD-FRQ-006 / PF-PRO-039 Fork 1). "
        "Recommended triage priority: HIGH. Per-project update mechanism: appdev (PRJ-000) "
        "edits its active tools/linkwatcher/linkwatcher-config.yaml directly; PRJ-001 / PRJ-002 "
        "via per-project migration; PRJ-T01 sandbox via the next Push. The framework-distributed "
        f"template was synced automatically by the release script. Schema delta — {delta}."
    )
    return description, notes


def _file_imp(project_root: Path, description: str, notes: str) -> bool:
    """File the schema-change IMP into central intake via New-ProcessImprovement.ps1."""
    imp_script = project_root / IMP_SCRIPT_REL
    if not imp_script.exists():
        print(f"   WARNING: IMP script not found ({imp_script}) — schema-change IMP NOT filed")
        return False
    try:
        result = subprocess.run(
            [
                "pwsh.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(imp_script),
                "-Source",
                IMP_SOURCE,
                "-Description",
                description,
                "-Notes",
                notes,
                "-Confirm:$false",
            ],
            cwd=str(project_root),
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        print(f"   WARNING: could not run pwsh to file IMP: {exc}")
        return False
    if result.returncode != 0:
        print(
            f"   WARNING: filing schema-change IMP failed (exit {result.returncode}): "
            f"{result.stderr.strip()}"
        )
        return False
    print("   OK: filed config-schema-change IMP into central intake")
    return True


def propagate(project_root: Path) -> dict:
    """Detect a project-configurable config-schema change and propagate the signal.

    Best-effort and non-fatal: returns a status dict; never raises for the
    expected skip / no-op cases. ``action`` is one of: skipped, noop, imp-failed,
    sync-failed, propagated.
    """
    status = {"action": "skipped", "reason": "", "diff": None}

    wip_path = project_root / WIP_TEMPLATE_REL
    if not wip_path.exists():
        status["reason"] = f"WIP template not found: {wip_path}"
        print(f"   Config-schema propagation skipped: {status['reason']}")
        return status

    appdev_root = resolve_appdev_root(project_root)
    if appdev_root is None:
        status["reason"] = "appdev not resolvable (missing/invalid .framework-central-pointer)"
        print(f"   Config-schema propagation skipped: {status['reason']}")
        return status

    appdev_template = appdev_root / APPDEV_TEMPLATE_REL
    if not appdev_template.exists():
        status["reason"] = f"appdev template not found: {appdev_template}"
        print(f"   Config-schema propagation skipped: {status['reason']}")
        return status

    try:
        diff = compute_schema_diff(wip_path, appdev_template)
    except Exception as exc:  # noqa: BLE001 — never let propagation break the release
        status["reason"] = f"diff failed: {exc}"
        print(f"   Config-schema propagation skipped: {status['reason']}")
        return status

    status["diff"] = diff
    if not diff["changed"]:
        status["action"] = "noop"
        print("   Config-schema propagation: no schema change (no-op)")
        return status

    print(
        f"   Config-schema change detected — added: {diff['added'] or '-'}, "
        f"removed: {diff['removed'] or '-'}"
    )
    description, notes = _build_imp_text(diff)

    # IMP first; sync the appdev template only if the signal was filed (so a failed
    # filing leaves the diff intact for the next run rather than silently losing it).
    if not _file_imp(project_root, description, notes):
        status["action"] = "imp-failed"
        status["reason"] = "IMP filing failed; appdev template NOT synced (signal preserved)"
        print(f"   {status['reason']}")
        return status

    try:
        appdev_template.write_text(wip_path.read_text(encoding="utf-8"), encoding="utf-8")
        status["action"] = "propagated"
        print(f"   OK: synced appdev template ({appdev_template})")
    except OSError as exc:
        status["action"] = "sync-failed"
        status["reason"] = f"IMP filed but appdev template sync failed: {exc}"
        print(f"   WARNING: {status['reason']}")
    return status


def main() -> int:
    project_root = Path(__file__).parent.parent.resolve()
    print("\nConfig-schema propagation check...")
    propagate(project_root)
    return 0  # never block the release on the propagation outcome


if __name__ == "__main__":
    sys.exit(main())
