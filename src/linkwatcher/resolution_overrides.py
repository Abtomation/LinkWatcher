"""
Shared virtual-root resolution-override helpers.

``path_resolution_overrides`` maps a folder to a resolution *base*: files
under that folder write their host-absolute (``/...``) references against
``<project_root>/<base>/`` — a *virtual* root — instead of the project root.
The canonical use case is a blueprint folder whose links target the
rollout-destination layout rather than the blueprint's on-disk location.

This module holds the normalization and folder-match logic ONCE, consumed by
both ``LinkValidator`` (validate mode) and ``PathResolver`` (live move/update
path, v1.1 blueprint-aware reference updating).  Keeping a single copy is
deliberate: two implementations of the virtual-root algorithm would let
``--validate`` and live updates drift apart (see PD-TDD-026,
"Override-Aware Path Resolution").

Pure functions, no I/O.
"""

from typing import Dict, List, Optional, Tuple


def build_resolution_overrides(raw: Optional[Dict[str, str]]) -> List[Tuple[str, str]]:
    """Normalise the configured folder→base path-resolution overrides.

    Keys (folders) and values (bases) are normalised to forward slashes
    with leading/trailing slashes stripped.  The result is sorted by
    descending folder length so the **first** prefix match in
    ``resolution_base_for_rel`` is the longest (most specific) one.  Folders
    that normalise to empty are dropped.
    """
    items: List[Tuple[str, str]] = []
    for folder, base in (raw or {}).items():
        norm_folder = folder.replace("\\", "/").strip("/")
        norm_base = base.replace("\\", "/").strip("/")
        if not norm_folder:
            continue
        items.append((norm_folder, norm_base))
    items.sort(key=lambda fb: len(fb[0]), reverse=True)
    return items


def resolution_base_for_rel(
    overrides: List[Tuple[str, str]], source_rel: str
) -> Optional[Tuple[str, str]]:
    """Return the ``(folder, base)`` override matching *source_rel*, or ``None``.

    *overrides* is the length-sorted list produced by
    ``build_resolution_overrides``; *source_rel* is a project-root-relative,
    forward-slash source path.  Longest-prefix match wins when folders nest.
    Returns ``None`` when the file lies outside every configured folder —
    callers then resolve ``/...`` links against the project root exactly as
    before (backward-compatible no-op).
    """
    for folder, base in overrides:  # longest folder first
        if source_rel == folder or source_rel.startswith(folder + "/"):
            return (folder, base)
    return None
