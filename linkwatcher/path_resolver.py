"""
Path resolution for link target calculation.

This module handles resolving and calculating new link target paths
when files are moved or renamed. It is a pure calculation module
with no file I/O or text replacement logic.
"""

import os
from pathlib import Path

from .logging import get_logger
from .models import LinkReference
from .utils import normalize_path


class PathResolver:
    """
    Resolves new link target paths when files move.

    Handles path analysis, absolute/relative resolution, match detection,
    and conversion back to the original link style.
    """

    def __init__(self, project_root: str = ".", logger=None, python_source_root: str = ""):
        self.project_root = Path(project_root).resolve()
        self.logger = logger or get_logger()
        # Normalized source root prefix (e.g., "src") for stripping from
        # Python import path comparisons.  See PD-BUG-078.
        self._python_source_root = (
            python_source_root.strip("/").strip("\\") if python_source_root else ""
        )

    def calculate_new_target(self, ref: LinkReference, old_path: str, new_path: str) -> str:
        """Calculate the new target path for a reference."""
        original_target = ref.link_target

        # Special handling for Python imports
        if ref.link_type == "python-import":
            return self._calculate_new_python_import(
                original_target, old_path, new_path, ref.file_path
            )

        # Handle anchors
        if "#" in original_target:
            target_part, anchor = original_target.split("#", 1)
            updated_target = self._calculate_new_target_relative(
                target_part, old_path, new_path, ref.file_path
            )
            return f"{updated_target}#{anchor}"
        else:
            return self._calculate_new_target_relative(
                original_target, old_path, new_path, ref.file_path
            )

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
            # Early check: if the original target directly matches the old path,
            # it's a project-root-relative path (e.g., path strings in scripts).
            # Return new_path directly to preserve the root-relative style.
            original_norm = normalize_path(original_target)
            old_norm = normalize_path(old_path)
            if original_norm == old_norm:
                new_norm = normalize_path(new_path)
                # Preserve leading slash if original had one
                if original_target.startswith("/"):
                    return f"/{new_norm}"
                return new_norm

            # Directory prefix match: target is a path under the moved directory
            old_prefix = old_norm.rstrip("/") + "/"
            if original_norm.startswith(old_prefix):
                new_norm = normalize_path(new_path)
                suffix = original_norm[len(old_norm.rstrip("/")) :]
                result = new_norm + suffix
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
            # must be under the same sub-project root.
            suffix_tag = "/" + original_norm
            if old_norm.endswith(suffix_tag):
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
        elif target_norm.startswith("./") or target_norm.startswith("../"):
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
