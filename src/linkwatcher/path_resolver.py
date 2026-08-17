"""
Path resolution for link target calculation.

This module handles resolving and calculating new link target paths
when files are moved or renamed. It is a pure calculation module
with no file I/O or text replacement logic.

AI Context
----------
Entry point: PathResolver.calculate_new_target(ref, old_path, new_path)
    Dispatches based on link type:
    - Python imports (LinkType.PYTHON_IMPORT) → _calculate_new_python_import()
    - All other link types → _calculate_new_target_relative()
    Anchor fragments (#section) are stripped before resolution and reattached after.

Resolution flow (_calculate_new_target_relative):
    Two early-exit checks run before the match strategies:
    1. Direct path equality — original target equals old_path (root-relative style)
    2. Directory prefix match — original target starts with old_path + "/"

    If neither early-exit matches, 4 match strategies are tried in order:
    1. _match_direct — exact normalized path comparison after resolving to absolute
    2. _match_stripped — strips leading "/" to compare absolute vs relative forms
    3. _match_resolved — resolves old_path relative to source file directory,
       plus a filename-only fallback for bare filenames in the same directory
    4. Suffix match (inline, PD-BUG-045) — for nested project contexts where
       old_path is a full nested path but the link target is a short suffix;
       constrained to source files under the same sub-project root

    On match: _convert_to_original_link_type() reconstructs the link preserving
    the original style (absolute, relative, filename-only, separator style).
    On no match or exception: returns the original target unchanged.

Override-aware resolution (v1.1, PD-TDD-026 "Override-Aware Path Resolution"):
    path_resolution_overrides maps a folder to a resolution base; host-absolute
    (/...) targets in files under such a folder are *virtual-root* links.
    For them, the two early-exit checks and the PD-BUG-045 suffix match are
    all skipped — each compares the unresolved link form, so a real or
    suffix-coinciding path merely coinciding with the virtual path would
    hijack the link. Base-aware Step-3 resolution is their only match path:
    _resolve_to_absolute_path() resolves the target against the folder's
    base, and _convert_to_original_link_type() strips the base back off so
    the rewritten link keeps its /... virtual-root style (containment-guarded;
    emits update_resolution_override_applied).

Python import handler (_calculate_new_python_import):
    Compares extensionless paths (strips .py). Supports python_source_root
    config to strip a prefix like "src/" so imports match project-root paths
    (PD-BUG-078). Uses the same suffix match strategy for nested projects
    (PD-BUG-045).

Key design decisions:
    - Pure calculation: no file I/O, no text replacement (updater.py handles that)
    - Graceful degradation: all exceptions caught and logged, original target returned
    - Path normalization uses forward slashes internally throughout
"""

import os
from pathlib import Path
from typing import Dict, Optional

from .link_types import LinkType
from .logging import get_logger
from .models import LinkReference
from .resolution_overrides import build_resolution_overrides, resolution_base_for_rel
from .utils import normalize_path, path_exists_under_root


class PathResolver:
    """
    Resolves new link target paths when files move.

    Handles path analysis, absolute/relative resolution, match detection,
    and conversion back to the original link style.
    """

    def __init__(
        self,
        project_root: str = ".",
        logger=None,
        python_source_root: str = "",
        path_resolution_overrides: Optional[Dict[str, str]] = None,
    ):
        self.project_root = Path(project_root).resolve()
        self.logger = logger or get_logger()
        # Normalized source root prefix (e.g., "src") for stripping from
        # Python import path comparisons.  See PD-BUG-078.
        self._python_source_root = (
            python_source_root.strip("/").strip("\\") if python_source_root else ""
        )
        # Virtual-root resolution overrides for host-absolute (/...) links in
        # override folders (blueprint-aware reference updating, PD-TDD-026
        # "Override-Aware Path Resolution").  Normalized once, longest folder
        # first; empty list => override resolution is a no-op (v1.0 behavior).
        self._resolution_overrides = build_resolution_overrides(path_resolution_overrides)
        # Per-source-file base cache — the base depends only on the (static)
        # config and the source path, so entries never go stale.
        self._resolution_base_cache: Dict[str, str] = {}

    def calculate_new_target(self, ref: LinkReference, old_path: str, new_path: str) -> str:
        """Calculate the new target path for a reference."""
        original_target = ref.link_target

        # Special handling for Python imports
        if ref.link_type == LinkType.PYTHON_IMPORT:
            return self._calculate_new_python_import(
                original_target, old_path, new_path, ref.file_path
            )

        # Handle anchors
        if "#" in original_target:
            target_part, anchor = original_target.split("#", 1)
            updated_target = self._calculate_new_target_relative(
                target_part, old_path, new_path, ref.file_path
            )
            updated_target = self._apply_trailing_separator_style(updated_target, target_part)
            return f"{updated_target}#{anchor}"
        else:
            updated_target = self._calculate_new_target_relative(
                original_target, old_path, new_path, ref.file_path
            )
            return self._apply_trailing_separator_style(updated_target, original_target)

    def _calculate_new_target_relative(
        self, original_target: str, old_path: str, new_path: str, source_file: str
    ) -> str:
        """
        Calculate the new target path using the proposed approach:
        1. Analyze the original link type and characteristics
        2. Convert to absolute path for unambiguous comparison
        3. If it matches the moved file, convert back to original link style with new location
        """
        try:
            original_norm = normalize_path(original_target)
            old_norm = normalize_path(old_path)

            # Override-aware resolution (PD-TDD-026 v1.1): a host-absolute
            # (/...) target from an override-folder source is a *virtual-root*
            # reference — its normalized form must NOT be equality/prefix
            # matched against on-disk paths by the early-exit branches below
            # (false positive when a real root-level path coincides with the
            # virtual path, e.g. a root test/ file moving while a blueprint
            # link says /test/...).  Base-aware Step-3 resolution handles
            # virtual-root links correctly, so skip the early exits for them.
            is_virtual_root_link = original_target.replace("\\", "/").startswith("/") and bool(
                self._resolution_base_for(source_file)
            )

            # Early check: if the original target directly matches the old path,
            # it's a project-root-relative path (e.g., path strings in scripts).
            # Return new_path directly to preserve the root-relative style.
            if not is_virtual_root_link and original_norm == old_norm:
                new_norm = normalize_path(new_path)
                # PD-BUG-112: only backslash-bearing targets are ambiguous here — a
                # forward-slash string that exactly matches a moved path is necessarily
                # a real reference, but a backslash string may be a string literal whose
                # backslashes are escape characters (``\n``, ``\t``) that merely look
                # like the moved directory after normalization. Guard that case by
                # disk existence; if the proposed target isn't real, leave it unchanged.
                # Forward-slash targets keep the pure-calculation fast path.
                if "\\" in original_target and not path_exists_under_root(
                    self.project_root, new_norm
                ):
                    return original_target
                # PD-BUG-112: re-apply the original separator style so backslashes
                # survive instead of being flipped to '/'.
                result = self._apply_separator_style(new_norm, original_target)
                if original_target.startswith("/"):
                    return f"/{result}"
                return result

            # Directory prefix match: target is a path under the moved directory
            old_prefix = old_norm.rstrip("/") + "/"
            if not is_virtual_root_link and original_norm.startswith(old_prefix):
                new_norm = normalize_path(new_path)
                suffix = original_norm[len(old_norm.rstrip("/")) :]
                result_norm = new_norm + suffix
                # PD-BUG-095: Verify the proposed new target actually exists on disk.
                # If it doesn't, the original was likely a regex/glob whose backslash
                # was normalized to '/' (e.g. ``'doc/foo/bar-\\d+'`` → ``'doc/foo/bar-/d+'``)
                # and incidentally matches the moved-directory prefix. Mirrors PD-BUG-033
                # in reference_lookup._calculate_updated_relative_path.
                if not path_exists_under_root(self.project_root, result_norm):
                    return original_target
                # PD-BUG-112: re-apply the original separator style (see early-exit
                # branch) so escape-sequence backslashes in the original are preserved.
                result = self._apply_separator_style(result_norm, original_target)
                if original_target.startswith("/"):
                    return f"/{result}"
                return result

            # Step 1: Analyze the original link type
            link_info = self._analyze_link_type(original_target, source_file)

            # Step 2: Convert original target to absolute path for comparison
            absolute_target = self._resolve_to_absolute_path(
                original_target, source_file, link_info
            )

            # Normalize paths for comparison (use forward slashes)
            absolute_target_norm = absolute_target.replace("\\", "/")
            old_path_norm = old_path.replace("\\", "/")
            new_path_norm = new_path.replace("\\", "/")

            # Step 3: Check if this link refers to the moved file
            # We need to handle both relative and absolute old_path scenarios
            match_found = (
                self._match_direct(absolute_target_norm, old_path_norm)
                or self._match_stripped(absolute_target_norm, old_path_norm)
                or self._match_resolved(absolute_target_norm, old_path_norm, source_file, link_info)
            )

            if match_found:
                # Step 4: Convert new absolute path back to original link style
                return self._convert_to_original_link_type(new_path_norm, source_file, link_info)

            # PD-BUG-045: Suffix match for nested project contexts.
            # When the original target (e.g., "utils/helpers.py") is a suffix of
            # old_path (e.g., "sub/project/utils/helpers.py"), extract the
            # corresponding suffix from new_path.  Constrained: source file
            # must be under the same sub-project root.  Skipped for virtual-root
            # links — like the early exits above, this block compares the
            # *unresolved* link form, so a suffix-coinciding move would hijack
            # a virtual-root link whose true target (<base>/...) did not move,
            # and the lossy rewrite would also drop the /... style.  Base-aware
            # Step-3 resolution is the only match path for virtual-root links.
            suffix_tag = "/" + original_norm
            if not is_virtual_root_link and old_norm.endswith(suffix_tag):
                subtree_root = old_norm[: -len(suffix_tag)]
                source_norm = normalize_path(source_file)
                if source_norm.startswith(subtree_root + "/"):
                    target_depth = original_norm.count("/") + 1
                    new_norm = normalize_path(new_path)
                    new_parts = new_norm.split("/")
                    return "/".join(new_parts[-target_depth:])

            # No match found, return original
            return original_target

        except Exception as e:
            # If the new approach fails, fall back to original target
            self.logger.debug(
                "link_resolution_failed",
                original_target=original_target,
                error=str(e),
                error_type=type(e).__name__,
            )
            return original_target

    def _resolution_base_for(self, source_file: str) -> str:
        """Return the virtual-root resolution base for *source_file*, or ``""``.

        Files under a folder configured in ``path_resolution_overrides`` get
        the configured base (project-root-relative, forward-slash form);
        all other files get ``""`` — meaning their ``/...`` links resolve
        project-root-relative exactly as before (backward-compatible no-op).
        Folder matching is delegated to the shared ``resolution_overrides``
        helper (longest-prefix match); the result is cached per source file
        since the base depends only on the static config and the path.
        """
        if not self._resolution_overrides:
            return ""
        cached = self._resolution_base_cache.get(source_file)
        if cached is not None:
            return cached
        rel = normalize_path(source_file)
        match = resolution_base_for_rel(self._resolution_overrides, rel)
        base = match[1] if match else ""
        self._resolution_base_cache[source_file] = base
        return base

    @staticmethod
    def _apply_separator_style(normalized_path: str, original_target: str) -> str:
        """Render *normalized_path* (forward-slash form) in the separator style of
        *original_target* (PD-BUG-112).

        When the original reference used backslashes, the rewrite must keep them: a
        backslash in a string literal is often an escape character (``\\n``, ``\\t``,
        ``\\"``), and flipping it to '/' corrupts the source (e.g. a Python
        SyntaxError). Mirrors the separator-style reconstruction in
        ``_convert_to_original_link_type``.
        """
        if "\\" in original_target:
            return normalized_path.replace("/", "\\")
        return normalized_path

    @staticmethod
    def _apply_trailing_separator_style(result: str, original_target: str) -> str:
        """Re-append the authored trailing separator stripped during normalization
        (PD-BUG-118).

        Every rewrite branch returns ``normalize_path`` output, and
        ``os.path.normpath`` drops a trailing separator — so a directory
        reference authored as ``doc/x/`` came back as ``doc/x``. That damaged the
        authored form on every rewrite, and made the rewrite differ from the
        original even when the path itself was unchanged, so files were written
        for a difference that carried no meaning.

        Sibling of ``_apply_separator_style`` (PD-BUG-112) and of the authored-
        form guard in ``reference_lookup._calculate_updated_relative_path``,
        whose comment names this exact case: a rewrite changes WHERE a target
        points, never how it was written.
        """
        if not result or not original_target.endswith(("/", "\\")):
            return result
        if result.endswith(("/", "\\")):
            return result
        return result + ("\\" if "\\" in original_target else "/")

    def _match_direct(self, absolute_target_norm: str, old_path_norm: str) -> bool:
        """Check if the resolved target directly matches the old path."""
        return absolute_target_norm == old_path_norm

    def _match_stripped(self, absolute_target_norm: str, old_path_norm: str) -> bool:
        """Check match after stripping leading slashes.

        Handles cases where one path is absolute (/doc/...) and the other
        is relative (doc/...).
        """
        return absolute_target_norm.lstrip("/") == old_path_norm.lstrip("/")

    def _match_resolved(
        self,
        absolute_target_norm: str,
        old_path_norm: str,
        source_file: str,
        link_info: dict,
    ) -> bool:
        """Check match by resolving old_path relative to source, and filename-only fallback.

        Two sub-strategies:
        1. Resolve old_path relative to the source file directory.
        2. For filename-only targets, compare filenames and containing directories.
        """
        # Strategy 1: resolve old_path relative to source file for comparison
        try:
            source_dir = os.path.dirname(source_file.replace("\\", "/"))
            if source_dir and not old_path_norm.startswith("/") and ":" not in old_path_norm:
                resolved_old_path = os.path.normpath(
                    os.path.join(source_dir, old_path_norm)
                ).replace("\\", "/")
                if absolute_target_norm == resolved_old_path:
                    return True
        except Exception:
            pass

        # Strategy 2: filename-only fallback
        try:
            target_filename = os.path.basename(absolute_target_norm)
            old_filename = os.path.basename(old_path_norm)

            if target_filename == old_filename:
                target_dir = os.path.dirname(absolute_target_norm)
                old_dir = os.path.dirname(old_path_norm) if "/" in old_path_norm else ""

                if link_info["is_filename_only"]:
                    source_dir = os.path.dirname(source_file.replace("\\", "/"))
                    if target_dir == source_dir and (not old_dir or old_dir == source_dir):
                        return True
        except Exception:
            pass

        return False

    def _analyze_link_type(self, target: str, source_file: str) -> dict:
        """
        Analyze the link to determine its type and characteristics.
        Returns a dict with link metadata for later reconstruction.
        """
        info = {
            "original_target": target,
            "separator_style": "\\" if "\\" in target else "/",
            "is_absolute": False,
            "is_relative_explicit": False,
            "is_filename_only": False,
        }

        target_norm = target.replace("\\", "/")

        # Check if it's an absolute path (starts with / or drive letter)
        if target_norm.startswith("/") or (len(target_norm) > 1 and target_norm[1] == ":"):
            info["is_absolute"] = True
        # Check if it's explicitly relative (starts with ./ or ../)
        elif target_norm.startswith("./") or target_norm.startswith("../../.."):
            info["is_relative_explicit"] = True
        # Check if it's just a filename (no path separators)
        elif "/" not in target_norm:
            info["is_filename_only"] = True

        return info

    def _resolve_to_absolute_path(self, target: str, source_file: str, link_info: dict) -> str:
        """
        Convert a link target to an absolute path for comparison.
        """
        target_norm = target.replace("\\", "/")
        source_norm = source_file.replace("\\", "/")

        # If already absolute, return as-is
        if link_info["is_absolute"]:
            # Override-aware resolution (PD-TDD-026 v1.1): a host-absolute
            # (/...) target from an override-folder source is written against
            # that folder's *virtual* root, so resolve it against <base>/ to
            # get the comparison form that can match the moved file's on-disk
            # project-root-relative path.  Drive-letter absolutes are never
            # virtual-root links; empty base keeps the v1.0 verbatim behavior.
            if target_norm.startswith("/"):
                base = self._resolution_base_for(source_file)
                if base:
                    return os.path.normpath(f"{base}/{target_norm.lstrip('/')}").replace("\\", "/")
            return target_norm

        # Get the directory containing the source file
        source_dir = os.path.dirname(source_norm)

        # Handle different relative path types
        if link_info["is_filename_only"]:
            # Filename only - assume it's in the same directory as source
            if source_dir:
                return f"{source_dir}/{target_norm}"
            else:
                return target_norm
        else:
            # Relative path - resolve relative to source directory
            if source_dir:
                # Use pathlib for proper relative path resolution
                source_path = Path(source_dir)
                target_path = source_path / target_norm
                # Normalize the resolved path to handle .. and . components
                resolved_path = os.path.normpath(str(target_path)).replace("\\", "/")
                return resolved_path
            else:
                return target_norm

    def _convert_to_original_link_type(
        self, new_absolute_path: str, source_file: str, link_info: dict
    ) -> str:
        """
        Convert an absolute path back to the original link style.
        """
        new_path_norm = new_absolute_path.replace("\\", "/")
        source_norm = source_file.replace("\\", "/")
        source_dir = os.path.dirname(source_norm)

        # If original was absolute, return absolute
        if link_info["is_absolute"]:
            original_target = link_info["original_target"].replace("\\", "/")
            base = self._resolution_base_for(source_file) if original_target.startswith("/") else ""
            if base:
                # Override-aware reconstruction (PD-TDD-026 v1.1): strip the
                # virtual-root base back off so the rewritten link keeps its
                # /... virtual-root style instead of the on-disk path.
                stripped = new_path_norm.lstrip("/")
                # Containment guard (mirrors PD-BUG-095): only rewrite when
                # the proposed target is a real path under the project root —
                # otherwise leave the original reference unchanged.
                if not path_exists_under_root(self.project_root, stripped):
                    return link_info["original_target"]
                if stripped == base or stripped.startswith(base + "/"):
                    remainder = stripped[len(base) :].lstrip("/")
                    result = f"/{remainder}"
                    self.logger.debug(
                        "update_resolution_override_applied",
                        source_file=source_norm,
                        resolution_base=base,
                        new_target=result,
                    )
                else:
                    # Moved outside the virtual root — cannot be expressed as
                    # a virtual-root link; fall back to the absolute form.
                    result = new_path_norm if new_path_norm.startswith("/") else f"/{new_path_norm}"
            else:
                # Ensure the result starts with / to maintain absolute path format
                result = new_path_norm if new_path_norm.startswith("/") else f"/{new_path_norm}"
        # If original was filename-only, check if we can keep it that way
        elif link_info["is_filename_only"]:
            new_filename = os.path.basename(new_path_norm)
            new_dir = os.path.dirname(new_path_norm)

            # Special case: if new_path is also just a filename (no directory),
            # then keep it as filename-only regardless of directories
            if "/" not in new_path_norm and "\\" not in new_path_norm:
                result = new_filename
            # If new file is in same directory as source, keep filename-only
            elif new_dir == source_dir:
                result = new_filename
            else:
                # Need to use relative path
                result = self._calculate_relative_path_between_files(source_file, new_path_norm)
        else:
            # Original was relative - calculate new relative path
            result = self._calculate_relative_path_between_files(source_file, new_path_norm)

        # Apply original separator style
        if link_info["separator_style"] == "\\":
            result = result.replace("/", "\\")

        return result

    def _calculate_relative_path_between_files(self, source_file: str, target_file: str) -> str:
        """Calculate the relative path from source_file to target_file."""
        # Normalize paths
        source_normalized = source_file.replace("\\", "/")
        target_normalized = target_file.replace("\\", "/")

        # Get directory of source file
        source_dir = os.path.dirname(source_normalized)

        # If source is in root directory, target path is just the target
        if not source_dir:
            return target_normalized

        # Calculate relative path using pathlib
        try:
            source_path = Path(source_dir)
            target_path = Path(target_normalized)
            relative_path = os.path.relpath(str(target_path), str(source_path))
            # Normalize path separators to forward slashes
            return relative_path.replace("\\", "/")
        except ValueError:
            # If relative path calculation fails, return absolute path
            return target_normalized

    def _calculate_new_python_import(
        self, original_target: str, old_path: str, new_path: str, source_file: str = ""
    ) -> str:
        """Calculate new target for Python import statements."""
        # For Python imports, original_target is already in slash notation (link_target)
        # We need to compare it directly with the old_path

        # Normalize all paths for comparison
        target_normalized = original_target.replace("\\", "/")
        old_normalized = old_path.replace("\\", "/")
        new_normalized = new_path.replace("\\", "/")

        # PD-BUG-043: Import targets are extensionless (e.g., "utils/helpers")
        # but old_path/new_path may arrive with .py extension from file-move
        # handlers.  Strip extension for comparison.
        old_no_ext = old_normalized[:-3] if old_normalized.endswith(".py") else old_normalized
        new_no_ext = new_normalized[:-3] if new_normalized.endswith(".py") else new_normalized

        # PD-BUG-078: Strip python_source_root prefix from paths so that
        # "src/package/module" compares as "package/module" — matching how
        # Python imports resolve relative to the source root, not project root.
        if self._python_source_root:
            prefix = self._python_source_root + "/"
            if old_no_ext.startswith(prefix):
                old_no_ext = old_no_ext[len(prefix) :]
            if new_no_ext.startswith(prefix):
                new_no_ext = new_no_ext[len(prefix) :]

        # Check if the import path matches the old path (with or without extension)
        if target_normalized == old_normalized or target_normalized == old_no_ext:
            # Exact match - replace entirely
            return new_no_ext
        elif target_normalized.startswith(old_normalized + "/") or target_normalized.startswith(
            old_no_ext + "/"
        ):
            # Partial match - replace the prefix
            prefix = (
                old_normalized if target_normalized.startswith(old_normalized + "/") else old_no_ext
            )
            suffix = target_normalized[len(prefix) :]
            return new_no_ext + suffix

        # PD-BUG-045: Suffix match for nested project contexts.
        # When LinkWatcher's project root is an ancestor of the Python project,
        # old_path is the full nested path (e.g., "sub/project/utils/helpers")
        # but the import target is just "utils/helpers".  Extract the same
        # number of trailing path components from new_path.
        # Constrained: source file must be under the same sub-project root.
        suffix_tag = "/" + target_normalized
        if old_no_ext.endswith(suffix_tag):
            subtree_root = old_no_ext[: -len(suffix_tag)]
            source_norm = normalize_path(source_file)
            if source_norm.startswith(subtree_root + "/"):
                target_depth = target_normalized.count("/") + 1
                new_parts = new_no_ext.split("/")
                return "/".join(new_parts[-target_depth:])

        return original_target  # No change needed
