"""
Link database for fast lookups and updates.

This module provides an in-memory database of file links that replaces
the need to scan all files every time a change occurs.
"""

import os
import threading
from datetime import datetime
from typing import Dict, List, Optional, Set

from .logging import get_logger
from .models import LinkReference


class LinkDatabase:
    """
    In-memory database of file links for fast lookups and updates.
    This replaces the need to scan all files every time.
    """

    def __init__(self):
        self.links: Dict[str, List[LinkReference]] = {}  # target_file -> [references]
        self.files_with_links: Set[str] = set()  # files that contain links
        self.last_scan: Optional[datetime] = None
        self._lock = threading.Lock()
        self.logger = get_logger()

    def add_link(self, reference: LinkReference):
        """Add a link reference to the database."""
        with self._lock:
            target = self._normalize_path(reference.link_target)
            if target not in self.links:
                self.links[target] = []
            self.links[target].append(reference)
            self.files_with_links.add(reference.file_path)

    def remove_file_links(self, file_path: str):
        """Remove all links from a specific file."""
        with self._lock:
            # Normalize the file path for comparison
            normalized_file_path = self._normalize_path(file_path)
            self.files_with_links.discard(file_path)
            self.files_with_links.discard(normalized_file_path)

            # Remove references from this file
            removed_count = 0
            for target, references in self.links.items():
                original_count = len(references)
                # Use normalized path comparison to handle path variations
                self.links[target] = [
                    ref
                    for ref in references
                    if self._normalize_path(ref.file_path) != normalized_file_path
                ]
                removed_count += original_count - len(self.links[target])

            # Clean up empty entries
            self.links = {k: v for k, v in self.links.items() if v}

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
            normalized_path = self._normalize_path(file_path)
            all_references = []

            # First, try direct lookup by normalized path (most efficient)
            if normalized_path in self.links:
                all_references.extend(self.links[normalized_path])

            # Also check for anchored versions of the same file
            for target_path, references in self.links.items():
                # Check if this target (possibly with anchor) points to our file
                base_target = target_path.split("#", 1)[0] if "#" in target_path else target_path
                if self._normalize_path(base_target) == normalized_path:
                    # Avoid duplicates from the direct lookup above
                    for ref in references:
                        if ref not in all_references:
                            all_references.append(ref)

            # Finally, check all stored references to see if they could refer to this file
            # This handles relative path resolution and filename matching
            for target_path, references in self.links.items():
                for ref in references:
                    if self._reference_points_to_file(ref, normalized_path):
                        # Avoid duplicates
                        if ref not in all_references:
                            all_references.append(ref)

            return all_references

    def _reference_points_to_file(self, ref: LinkReference, target_file_path: str) -> bool:
        """Check if a reference points to the specified file."""
        # Extract the base path from the link target (remove anchor if present)
        link_target = ref.link_target
        if "#" in link_target:
            link_target = link_target.split("#", 1)[0]

        target_norm = self._normalize_path(link_target)
        file_norm = self._normalize_path(target_file_path)

        # Direct match
        if target_norm == file_norm:
            return True

        # Filename match (reference is just filename, target is full path)
        if target_norm == os.path.basename(file_norm):
            # Check if they're in the same directory
            ref_dir = os.path.dirname(self._normalize_path(ref.file_path))
            file_dir = os.path.dirname(file_norm)
            return ref_dir == file_dir

        # Relative path resolution
        ref_dir = os.path.dirname(self._normalize_path(ref.file_path))
        try:
            # Resolve the reference relative to its containing file
            resolved_target = os.path.normpath(os.path.join(ref_dir, target_norm)).replace(
                "\\", "/"
            )
            return resolved_target == file_norm
        except:
            return False

    def update_target_path(self, old_path: str, new_path: str):
        """Update the target path for all references."""
        with self._lock:
            old_normalized = self._normalize_path(old_path)
            new_normalized = self._normalize_path(new_path)

            # Find all keys that need to be updated (including anchored links)
            keys_to_update = []
            for key in self.links.keys():
                # Extract base path from key (remove anchor if present)
                base_key = key.split("#", 1)[0] if "#" in key else key
                if self._normalize_path(base_key) == old_normalized:
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

    def _normalize_path(self, path: str) -> str:
        """Normalize a path for consistent lookups."""
        # Remove leading slash and normalize
        path = path.lstrip("/")
        return os.path.normpath(path).replace("\\", "/")

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
        old_normalized = self._normalize_path(old_path)
        target_normalized = self._normalize_path(target)

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

    def clear(self):
        """Clear all data from the database."""
        with self._lock:
            self.links.clear()
            self.files_with_links.clear()
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
