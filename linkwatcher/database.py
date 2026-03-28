"""
Link database for fast lookups and updates.

This module provides an in-memory database of file links that replaces
the need to scan all files every time a change occurs.

AI Context
----------
- **Entry point**: ``LinkDatabase`` (concrete) implements
  ``LinkDatabaseInterface`` (ABC).  All consumers should type-hint
  against the interface.
- **Data structure**: ``self.links`` is a ``dict[str, list[LinkReference]]``
  keyed by *normalized target path*.  All lookups are O(1) by target.
  A ``threading.Lock`` guards all mutations for thread safety.
- **Common tasks**:
  - Adding a query method: acquire ``self._lock``, operate on
    ``self.links``, return copies (not references) to avoid races.
  - Debugging missing references: check ``normalize_path()`` — path
    normalization mismatches are the most common cause.
  - Understanding data flow: service._initial_scan → parser.parse_file
    → database.add_link; handler events → database.remove_file_links /
    update_source_path / get_references_to_file.
"""

import os
import threading
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Set

from .logging import get_logger
from .models import LinkReference
from .utils import normalize_path


class LinkDatabaseInterface(ABC):
    """Abstract interface for link database implementations.

    Defines the contract that any link storage backend must implement.
    Consumers should type-hint against this interface rather than
    the concrete LinkDatabase class.
    """

    @property
    @abstractmethod
    def last_scan(self) -> Optional[float]:
        """Timestamp of the last full scan, or None."""
        ...

    @last_scan.setter
    @abstractmethod
    def last_scan(self, value: Optional[float]):
        ...

    @abstractmethod
    def add_link(self, reference: LinkReference):
        """Add a link reference to the database."""
        ...

    @abstractmethod
    def remove_file_links(self, file_path: str):
        """Remove all links from a specific file."""
        ...

    @abstractmethod
    def get_references_to_file(self, file_path: str) -> List[LinkReference]:
        """Get all references pointing to a specific file."""
        ...

    @abstractmethod
    def update_target_path(self, old_path: str, new_path: str):
        """Update the target path for all references."""
        ...

    @abstractmethod
    def update_source_path(self, old_path: str, new_path: str) -> int:
        """Update file_path on all references whose source matches old_path.

        Returns the number of references updated.
        """
        ...

    @abstractmethod
    def remove_targets_by_path(self, old_path: str) -> int:
        """Remove all target entries whose key normalizes to old_path."""
        ...

    @abstractmethod
    def get_references_to_directory(self, dir_path: str) -> List[LinkReference]:
        """Get all references whose target matches a directory path."""
        ...

    @abstractmethod
    def get_all_targets_with_references(self) -> Dict[str, List[LinkReference]]:
        """Return a snapshot copy of all targets and their references."""
        ...

    @abstractmethod
    def get_source_files(self) -> Set[str]:
        """Return a copy of the set of files that contain links."""
        ...

    @abstractmethod
    def has_target_with_basename(self, filename: str) -> bool:
        """Check if any target key has the given basename.

        Used for fast lookups to determine if a file is referenced
        by any monitored file, without expensive full-path resolution.
        """
        ...

    @abstractmethod
    def clear(self):
        """Clear all data from the database."""
        ...

    @abstractmethod
    def get_stats(self) -> Dict[str, int]:
        """Get database statistics."""
        ...


class LinkDatabase(LinkDatabaseInterface):
    """
    In-memory database of file links for fast lookups and updates.
    This replaces the need to scan all files every time.
    """

    def __init__(self):
        self.links: Dict[str, List[LinkReference]] = {}  # target_file -> [references]
        self.files_with_links: Set[str] = set()  # files that contain links
        self._source_to_targets: Dict[str, Set[str]] = {}  # normalized_source -> {target_keys}
        self._last_scan: Optional[float] = None
        self._lock = threading.Lock()
        self.logger = get_logger()

    @property
    def last_scan(self) -> Optional[float]:
        """Timestamp of the last full scan, or None."""
        return self._last_scan

    @last_scan.setter
    def last_scan(self, value: Optional[float]):
        self._last_scan = value

    def add_link(self, reference: LinkReference):
        """Add a link reference to the database."""
        if not reference.link_target:
            return
        with self._lock:
            target = normalize_path(reference.link_target)
            if target not in self.links:
                self.links[target] = []
            # Guard: skip duplicate references (same source file + line + column)
            source_norm = normalize_path(reference.file_path)
            for ref in self.links[target]:
                if (
                    normalize_path(ref.file_path) == source_norm
                    and ref.line_number == reference.line_number
                    and ref.column_start == reference.column_start
                ):
                    return
            self.links[target].append(reference)
            self.files_with_links.add(reference.file_path)
            # Maintain reverse index: source file -> target keys
            if source_norm not in self._source_to_targets:
                self._source_to_targets[source_norm] = set()
            self._source_to_targets[source_norm].add(target)

    def remove_file_links(self, file_path: str):
        """Remove all links from a specific file."""
        with self._lock:
            # Normalize the file path for comparison
            normalized_file_path = normalize_path(file_path)
            self.files_with_links.discard(file_path)
            self.files_with_links.discard(normalized_file_path)

            # Use reverse index to find only the targets referenced by this source
            target_keys = self._source_to_targets.pop(normalized_file_path, set())

            removed_count = 0
            for target in target_keys:
                if target not in self.links:
                    continue
                references = self.links[target]
                original_count = len(references)
                self.links[target] = [
                    ref
                    for ref in references
                    if normalize_path(ref.file_path) != normalized_file_path
                ]
                removed_count += original_count - len(self.links[target])
                # Clean up empty target entry
                if not self.links[target]:
                    del self.links[target]

            # Log removal results
            if removed_count > 0:
                self.logger.info(
                    "references_removed", file_path=file_path, removed_count=removed_count
                )
            else:
                self.logger.warning("no_references_to_remove", file_path=file_path)

    def get_references_to_file(self, file_path: str) -> List[LinkReference]:
        """Get all references pointing to a specific file."""
        with self._lock:
            normalized_path = normalize_path(file_path)
            all_references = []
            seen = set()

            # First, try direct lookup by normalized path (most efficient)
            if normalized_path in self.links:
                for ref in self.links[normalized_path]:
                    seen.add(id(ref))
                    all_references.append(ref)

            # Single pass: check anchored keys and relative-path resolution
            for target_path, references in self.links.items():
                # Check if this target (possibly with anchor) points to our file
                base_target = target_path.split("#", 1)[0] if "#" in target_path else target_path
                if normalize_path(base_target) == normalized_path:
                    for ref in references:
                        if id(ref) not in seen:
                            seen.add(id(ref))
                            all_references.append(ref)
                    continue

                # Check relative path resolution and filename matching
                for ref in references:
                    if id(ref) not in seen and self._reference_points_to_file(ref, normalized_path):
                        seen.add(id(ref))
                        all_references.append(ref)

            return all_references

    def _reference_points_to_file(self, ref: LinkReference, target_file_path: str) -> bool:
        """Check if a reference points to the specified file."""
        # Extract the base path from the link target (remove anchor if present)
        link_target = ref.link_target
        if "#" in link_target:
            link_target = link_target.split("#", 1)[0]

        target_norm = normalize_path(link_target)
        file_norm = normalize_path(target_file_path)

        # Direct match
        if target_norm == file_norm:
            return True

        # Filename match (reference is just filename, target is full path)
        if target_norm == os.path.basename(file_norm):
            # Check if they're in the same directory
            ref_dir = os.path.dirname(normalize_path(ref.file_path))
            file_dir = os.path.dirname(file_norm)
            return ref_dir == file_dir

        # Relative path resolution
        ref_dir = os.path.dirname(normalize_path(ref.file_path))
        try:
            # Resolve the reference relative to its containing file
            resolved_target = os.path.normpath(os.path.join(ref_dir, target_norm)).replace(
                "\\", "/"
            )
            if resolved_target == file_norm:
                return True
        except Exception:
            pass

        # PD-BUG-045: Suffix match for project-root-relative references.
        #
        # Algorithm summary:
        #   1. Check if file_norm ends with "/<target_norm>" (or its
        #      extensionless form), meaning the DB key is a proper suffix of
        #      the full project-relative path.
        #   2. If yes, derive subtree_root = the path prefix before the suffix
        #      (i.e., the inferred sub-project root).
        #   3. Accept the match only if the referring file also lives under
        #      subtree_root — this prevents false positives from identically
        #      named files in unrelated parts of the project.
        #
        # Why this exists: Python imports (e.g., "utils/helpers") resolve from
        # the Python project root, not the importing file's directory. When the
        # LinkWatcher project root is an ancestor of the Python project, the
        # DB key is a proper suffix of the moved file's project-relative path.
        # Also tries with .py extension stripped for extensionless targets.
        suffix = "/" + target_norm
        subtree_root = None
        if file_norm.endswith(suffix):
            subtree_root = file_norm[: -len(suffix)]
        else:
            file_no_ext, ext = os.path.splitext(file_norm)
            if ext and file_no_ext.endswith(suffix):
                subtree_root = file_no_ext[: -len(suffix)]
        if subtree_root is not None:
            ref_path_norm = normalize_path(ref.file_path)
            if ref_path_norm.startswith(subtree_root + "/"):
                return True

        return False

    def update_target_path(self, old_path: str, new_path: str):
        """Update the target path for all references."""
        with self._lock:
            old_normalized = normalize_path(old_path)

            # Find all keys that need to be updated (including anchored links)
            keys_to_update = []
            for key in self.links.keys():
                # Extract base path from key (remove anchor if present)
                base_key = key.split("#", 1)[0] if "#" in key else key
                if normalize_path(base_key) == old_normalized:
                    keys_to_update.append(key)

            # Update each matching key
            for old_key in keys_to_update:
                references = self.links[old_key]
                del self.links[old_key]

                # Update the target in each reference
                for ref in references:
                    ref.link_target = self._update_link_target(ref.link_target, old_path, new_path)

                # Create new key with updated path
                new_key = self._update_link_target(old_key, old_path, new_path)
                self.links[new_key] = references

    def _update_link_target(self, original_target: str, old_path: str, new_path: str) -> str:
        """Update a link target from old path to new path, preserving format."""
        # Handle anchors
        if "#" in original_target:
            target_part, anchor = original_target.split("#", 1)
            updated_target = self._replace_path_part(target_part, old_path, new_path)
            return f"{updated_target}#{anchor}"
        else:
            return self._replace_path_part(original_target, old_path, new_path)

    def _replace_path_part(self, target: str, old_path: str, new_path: str) -> str:
        """Replace the path part while preserving relative/absolute format."""
        old_normalized = normalize_path(old_path)
        target_normalized = normalize_path(target)

        if target_normalized == old_normalized:
            # Exact match - preserve the original format (relative vs absolute)
            if target.startswith("/"):
                return f"/{new_path}"
            else:
                return new_path
        elif target_normalized.endswith(old_normalized):
            # Partial match - replace the ending part
            prefix_len = len(target_normalized) - len(old_normalized)
            prefix = target[:prefix_len] if prefix_len > 0 else ""
            if target.startswith("/"):
                return f"{prefix}{new_path}"
            else:
                return f"{prefix}{new_path}"

        return target  # No match, return original

    def update_source_path(self, old_path: str, new_path: str) -> int:
        """Update file_path on all references whose source matches old_path.

        Returns the number of references updated.
        """
        with self._lock:
            old_normalized = normalize_path(old_path)
            new_normalized = normalize_path(new_path)
            updated = 0

            # Use reverse index to find only the targets referenced by old source
            target_keys = self._source_to_targets.get(old_normalized, set())
            for target in target_keys:
                if target not in self.links:
                    continue
                for ref in self.links[target]:
                    if normalize_path(ref.file_path) == old_normalized:
                        ref.file_path = new_path
                        updated += 1

            # Update reverse index: move entry from old key to new key
            if updated:
                targets = self._source_to_targets.pop(old_normalized, set())
                if new_normalized not in self._source_to_targets:
                    self._source_to_targets[new_normalized] = set()
                self._source_to_targets[new_normalized].update(targets)
                # Update files_with_links tracking set
                self.files_with_links.discard(old_path)
                self.files_with_links.discard(old_normalized)
                self.files_with_links.add(new_path)
            return updated

    def remove_targets_by_path(self, old_path: str) -> int:
        """Remove all target entries whose key normalizes to old_path.

        Handles anchored keys (e.g. 'file.md#section') by comparing the
        base path portion. Returns the number of keys removed.
        """
        with self._lock:
            old_normalized = normalize_path(old_path)
            keys_to_remove = []
            for key in self.links:
                base_key = key.split("#", 1)[0] if "#" in key else key
                if normalize_path(base_key) == old_normalized:
                    keys_to_remove.append(key)
            for key in keys_to_remove:
                del self.links[key]
            return len(keys_to_remove)

    def get_references_to_directory(self, dir_path: str) -> List[LinkReference]:
        """Get all references whose target matches a directory path.

        Finds references where the link_target equals the directory path
        (exact match) or starts with it as a prefix (subdirectory references).
        Used during directory moves to update directory-path string references
        in scripts (e.g., quoted paths in PowerShell files).

        Args:
            dir_path: The directory path to search for.

        Returns:
            Deduplicated list of LinkReference objects targeting this directory.
        """
        with self._lock:
            normalized_dir = normalize_path(dir_path)
            # Ensure prefix ends with "/" for safe prefix matching
            dir_prefix = normalized_dir.rstrip("/") + "/"
            all_references = []
            seen = set()

            for target_path, references in self.links.items():
                normalized_target = normalize_path(target_path)
                # Exact match: target IS the directory path
                # Prefix match: target starts with dir_path/ (subdirectory)
                if normalized_target == normalized_dir or normalized_target.startswith(dir_prefix):
                    for ref in references:
                        if id(ref) not in seen:
                            seen.add(id(ref))
                            all_references.append(ref)

            return all_references

    def get_all_targets_with_references(self) -> Dict[str, List[LinkReference]]:
        """Return a snapshot copy of all targets and their references.

        The returned dict is a shallow copy safe for iteration outside
        the lock. Reference lists are also copied.
        """
        with self._lock:
            return {target: list(refs) for target, refs in self.links.items()}

    def get_source_files(self) -> Set[str]:
        """Return a copy of the set of files that contain links."""
        with self._lock:
            return set(self.files_with_links)

    def has_target_with_basename(self, filename: str) -> bool:
        """Check if any target key has the given basename."""
        with self._lock:
            for target_key in self.links:
                if os.path.basename(target_key) == filename:
                    return True
        return False

    def clear(self):
        """Clear all data from the database."""
        with self._lock:
            self.links.clear()
            self.files_with_links.clear()
            self._source_to_targets.clear()
            self.last_scan = None

    def get_stats(self) -> Dict[str, int]:
        """Get database statistics."""
        with self._lock:
            total_references = sum(len(refs) for refs in self.links.values())
            return {
                "total_targets": len(self.links),
                "total_references": total_references,
                "files_with_links": len(self.files_with_links),
            }
