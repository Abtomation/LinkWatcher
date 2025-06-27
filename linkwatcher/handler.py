"""
File system event handler for the LinkWatcher system.

This module handles file system events (move, delete, create) and
coordinates the appropriate responses.
"""

import os
import time
import threading
from pathlib import Path

from colorama import Fore, Style
from watchdog.events import (
    FileCreatedEvent,
    FileDeletedEvent,
    FileMovedEvent,
    FileSystemEventHandler,
)

from .database import LinkDatabase
from .models import FileOperation
from .parser import LinkParser
from .updater import LinkUpdater
from .utils import should_ignore_directory, should_monitor_file


class LinkMaintenanceHandler(FileSystemEventHandler):
    """
    Handles file system events and maintains link integrity.

    This handler responds to file moves, deletions, and creations by:
    1. Updating the link database
    2. Finding affected references
    3. Updating files with broken links
    """

    def __init__(
        self, link_db: LinkDatabase, parser: LinkParser, updater: LinkUpdater, project_root: str
    ):
        super().__init__()
        self.link_db = link_db
        self.parser = parser
        self.updater = updater
        self.project_root = Path(project_root).resolve()

        # Configuration
        self.monitored_extensions = {".md", ".yaml", ".yml", ".dart", ".py", ".json", ".txt"}
        self.ignored_dirs = {".git", ".dart_tool", "node_modules", ".vscode", "build", "dist"}

        # Delayed move detection
        self.pending_deletes = {}  # {file_path: (timestamp, file_size)}
        self.move_detection_delay = 2.0  # seconds to wait for create after delete
        self.move_detection_lock = threading.Lock()

        # Statistics
        self.stats = {
            "files_moved": 0,
            "files_deleted": 0,
            "files_created": 0,
            "links_updated": 0,
            "errors": 0,
        }

    def on_moved(self, event):
        """Handle file/directory move events."""
        if event.is_directory:
            self._handle_directory_moved(event)
        else:
            self._handle_file_moved(event)

    def on_deleted(self, event):
        """Handle file/directory deletion events."""
        if event.is_directory:
            self._handle_directory_deleted(event)
        else:
            self._handle_file_deleted(event)

    def on_created(self, event):
        """Handle file/directory creation events."""
        if not event.is_directory and self._should_monitor_file(event.src_path):
            self._handle_file_created(event)

    def _handle_file_moved(self, event: FileMovedEvent):
        """Handle individual file move."""
        old_path = self._get_relative_path(event.src_path)
        new_path = self._get_relative_path(event.dest_path)

        if not old_path or not new_path:
            return

        print(f"{Fore.CYAN}📁 File moved: {old_path} → {new_path}")

        try:
            # Get all references to the old file - try multiple path formats
            references = []

            # Try exact path match
            refs_exact = self.link_db.get_references_to_file(old_path)
            references.extend(refs_exact)
            print(f"{Fore.CYAN}Found {len(refs_exact)} references with exact path: {old_path}")

            # Try relative path variations (remove leading directory components)
            # For example: "test/source_dir/file.md" -> "source_dir/file.md"
            path_parts = old_path.split("/")
            if len(path_parts) > 2:  # Has at least 2 directory levels
                relative_path = "/".join(path_parts[1:])  # Remove first directory
                refs_relative = self.link_db.get_references_to_file(relative_path)
                references.extend(refs_relative)
                print(
                    f"{Fore.CYAN}Found {len(refs_relative)} references with relative path: {relative_path}"
                )

                # Also try backslash version for Windows
                relative_path_backslash = relative_path.replace("/", "\\")
                refs_backslash = self.link_db.get_references_to_file(relative_path_backslash)
                references.extend(refs_backslash)
                print(
                    f"{Fore.CYAN}Found {len(refs_backslash)} references with backslash path: {relative_path_backslash}"
                )

            # Try just filename
            old_filename = os.path.basename(old_path)
            refs_filename = self.link_db.get_references_to_file(old_filename)
            references.extend(refs_filename)
            print(f"{Fore.CYAN}Found {len(refs_filename)} references with filename: {old_filename}")

            # Remove duplicates
            seen = set()
            unique_references = []
            for ref in references:
                key = (ref.file_path, ref.line_number, ref.link_target)
                if key not in seen:
                    seen.add(key)
                    unique_references.append(ref)

            references = unique_references

            if references:
                print(f"{Fore.YELLOW}🔗 Updating {len(references)} unique references...")

                # Update the references
                update_stats = self.updater.update_references(references, old_path, new_path)

                # Update the database - need to update for each path variation that had references
                # Try exact path match
                if self.link_db.get_references_to_file(old_path):
                    self.link_db.update_target_path(old_path, new_path)

                # Try relative path variations
                path_parts = old_path.split("/")
                if len(path_parts) > 2:  # Has at least 2 directory levels
                    relative_old_path = "/".join(path_parts[1:])  # Remove first directory
                    relative_new_path = "/".join(new_path.split("/")[1:])  # Remove first directory
                    if self.link_db.get_references_to_file(relative_old_path):
                        self.link_db.update_target_path(relative_old_path, relative_new_path)

                    # Also try backslash version for Windows
                    relative_old_path_backslash = relative_old_path.replace("/", "\\")
                    relative_new_path_backslash = relative_new_path.replace("/", "\\")
                    if self.link_db.get_references_to_file(relative_old_path_backslash):
                        self.link_db.update_target_path(
                            relative_old_path_backslash, relative_new_path_backslash
                        )

                # Try just filename
                old_filename = os.path.basename(old_path)
                new_filename = os.path.basename(new_path)
                if self.link_db.get_references_to_file(old_filename):
                    self.link_db.update_target_path(old_filename, new_filename)

                # Update statistics
                self.stats["links_updated"] += update_stats["references_updated"]
                self.stats["errors"] += update_stats["errors"]

                # Report results
                if update_stats["files_updated"] > 0:
                    print(f"{Fore.GREEN}✓ Updated links in {update_stats['files_updated']} files")
                else:
                    print(f"{Fore.YELLOW}⚠ No files needed updating")
            else:
                print(f"{Fore.YELLOW}⚠ No references found to update")

            # If the moved file contains links, update its entries
            if self._should_monitor_file(event.dest_path):
                self._rescan_file_links(event.dest_path)

            self.stats["files_moved"] += 1

        except Exception as e:
            print(f"{Fore.RED}✗ Error handling file move: {e}")
            self.stats["errors"] += 1

    def _handle_directory_moved(self, event: FileMovedEvent):
        """Handle directory move - affects all files within."""
        old_dir = self._get_relative_path(event.src_path)
        new_dir = self._get_relative_path(event.dest_path)

        print(f"{Fore.CYAN}📂 Directory moved: {old_dir} → {new_dir}")

        try:
            # Find all files that were moved
            moved_files = []
            for root, dirs, files in os.walk(event.dest_path):
                # Skip ignored directories
                dirs[:] = [d for d in dirs if d not in self.ignored_dirs]

                for file in files:
                    file_path = os.path.join(root, file)
                    if self._should_monitor_file(file_path):
                        rel_new_path = self._get_relative_path(file_path)
                        # Calculate what the old path would have been
                        rel_old_path = rel_new_path.replace(new_dir, old_dir, 1)
                        moved_files.append((rel_old_path, rel_new_path))

            # Update each moved file
            total_references_updated = 0
            for old_file_path, new_file_path in moved_files:
                # Find references BEFORE updating database
                references = self.link_db.get_references_to_file(old_file_path)
                
                # For Python files, also check for module references (without .py extension)
                if old_file_path.endswith('.py'):
                    old_module_path = old_file_path[:-3]  # Remove .py extension
                    new_module_path = new_file_path[:-3]  # Remove .py extension
                    module_references = self.link_db.get_references_to_file(old_module_path)
                    
                    # Update module references separately
                    if module_references:
                        module_update_stats = self.updater.update_references(
                            module_references, old_module_path, new_module_path
                        )
                        total_references_updated += module_update_stats["references_updated"]
                        self.stats["errors"] += module_update_stats["errors"]
                        
                        # Update database for module references
                        self.link_db.update_target_path(old_module_path, new_module_path)

                # Update file contents FIRST (while database still has old references)
                if references:
                    update_stats = self.updater.update_references(
                        references, old_file_path, new_file_path
                    )
                    total_references_updated += update_stats["references_updated"]
                    self.stats["errors"] += update_stats["errors"]
                
                # Update database AFTER file contents are updated
                self.link_db.update_target_path(old_file_path, new_file_path)

                # Rescan the file for its own links
                abs_new_path = os.path.join(self.project_root, new_file_path)
                self._rescan_file_links(abs_new_path)

            print(
                f"{Fore.GREEN}✓ Updated {total_references_updated} reference(s) for {len(moved_files)} moved files"
            )
            self.stats["links_updated"] += total_references_updated
            self.stats["files_moved"] += len(moved_files)

        except Exception as e:
            print(f"{Fore.RED}✗ Error handling directory move: {e}")
            self.stats["errors"] += 1

    def _handle_file_deleted(self, event: FileDeletedEvent):
        """Handle file deletion with delayed move detection."""
        deleted_path = self._get_relative_path(event.src_path)
        
        # Get file info before it's gone
        file_size = 0
        try:
            if os.path.exists(event.src_path):
                file_size = os.path.getsize(event.src_path)
        except:
            pass

        print(f"{Fore.RED}🗑️ File deleted: {deleted_path}")

        # Buffer this delete event for potential move detection
        with self.move_detection_lock:
            self.pending_deletes[deleted_path] = (time.time(), file_size)

        # Schedule delayed processing
        timer = threading.Timer(self.move_detection_delay, self._process_delayed_delete, [deleted_path])
        timer.start()

    def _process_delayed_delete(self, deleted_path: str):
        """Process a delete event after the move detection delay."""
        with self.move_detection_lock:
            if deleted_path not in self.pending_deletes:
                return  # Already processed as a move
            
            # Remove from pending deletes
            del self.pending_deletes[deleted_path]

        # Process as actual deletion
        try:
            # Remove from database
            self.link_db.remove_file_links(deleted_path)

            # Find references to the deleted file (these are now broken)
            references = self.link_db.get_references_to_file(deleted_path)
            if references:
                print(
                    f"{Fore.YELLOW}⚠️ Found {len(references)} broken reference(s) to deleted file"
                )
                # Note: We don't auto-fix broken references to deleted files
                # This is intentional - user should decide what to do
                for ref in references:
                    print(f"   {Fore.YELLOW}• {ref.file_path}:{ref.line_number} - {ref.link_text}")

            self.stats["files_deleted"] += 1

        except Exception as e:
            print(f"{Fore.RED}✗ Error handling file deletion: {e}")
            self.stats["errors"] += 1

    def _handle_directory_deleted(self, event: FileDeletedEvent):
        """Handle directory deletion."""
        deleted_dir = self._get_relative_path(event.src_path)
        print(f"{Fore.RED}🗑️ Directory deleted: {deleted_dir}")

        # For directory deletion, we'd need to clean up all files within
        # This is complex and might be better handled by a full rescan
        print(f"{Fore.YELLOW}⚠️ Directory deletion detected. Consider running a full rescan.")

    def _handle_file_created(self, event: FileCreatedEvent):
        """Handle file creation with move detection."""
        created_path = self._get_relative_path(event.src_path)
        
        # Check if this might be a move operation
        potential_move_source = self._detect_potential_move(created_path, event.src_path)
        
        if potential_move_source:
            # Handle as move operation
            print(f"{Fore.CYAN}📁 Detected move: {potential_move_source} → {created_path}")
            self._handle_detected_move(potential_move_source, created_path)
        else:
            # Handle as regular file creation
            print(f"{Fore.GREEN}📄 File created: {created_path}")
            try:
                # Scan the new file for links
                self._rescan_file_links(event.src_path)
                self.stats["files_created"] += 1
            except Exception as e:
                print(f"{Fore.RED}✗ Error handling file creation: {e}")
                self.stats["errors"] += 1

    def _detect_potential_move(self, created_path: str, created_abs_path: str) -> str:
        """Detect if a file creation is actually part of a move operation."""
        with self.move_detection_lock:
            if not self.pending_deletes:
                return None
            
            # Get file size of created file
            try:
                created_size = os.path.getsize(created_abs_path)
            except:
                return None
            
            # Look for a recently deleted file with same name and size
            created_filename = os.path.basename(created_path)
            current_time = time.time()
            
            for deleted_path, (delete_time, delete_size) in list(self.pending_deletes.items()):
                # Check if delete was recent enough
                if current_time - delete_time > self.move_detection_delay:
                    continue
                    
                # Check if filename matches
                deleted_filename = os.path.basename(deleted_path)
                if created_filename == deleted_filename:
                    # Check if size matches (if we have size info)
                    if delete_size == 0 or created_size == delete_size:
                        # This looks like a move!
                        del self.pending_deletes[deleted_path]
                        return deleted_path
            
            return None

    def _handle_detected_move(self, old_path: str, new_path: str):
        """Handle a detected move operation."""
        try:
            # Create a synthetic move event and handle it
            project_root_str = str(self.project_root)
            class SyntheticMoveEvent:
                def __init__(self, src_path, dest_path):
                    self.src_path = os.path.join(project_root_str, src_path)
                    self.dest_path = os.path.join(project_root_str, dest_path)
                    self.is_directory = False
            
            synthetic_event = SyntheticMoveEvent(old_path, new_path)
            self._handle_file_moved(synthetic_event)
            
        except Exception as e:
            print(f"{Fore.RED}✗ Error handling detected move: {e}")
            self.stats["errors"] += 1

    def _rescan_file_links(self, file_path: str):
        """Rescan a file and update the link database."""
        try:
            rel_path = self._get_relative_path(file_path)

            # Remove existing links from this file
            self.link_db.remove_file_links(rel_path)

            # Parse and add new links
            references = self.parser.parse_file(file_path)
            for ref in references:
                # Update the reference to use relative path
                ref.file_path = rel_path
                self.link_db.add_link(ref)

            if references:
                print(f"{Fore.GREEN}📊 Scanned {len(references)} link(s) in {rel_path}")

        except Exception as e:
            print(f"{Fore.YELLOW}Warning: Could not rescan {file_path}: {e}")

    def _should_monitor_file(self, file_path: str) -> bool:
        """Check if a file should be monitored."""
        return should_monitor_file(file_path, self.monitored_extensions, self.ignored_dirs)

    def _get_relative_path(self, abs_path: str) -> str:
        """Convert absolute path to relative path from project root."""
        try:
            abs_path_obj = Path(abs_path).resolve()
            return str(abs_path_obj.relative_to(self.project_root)).replace("\\", "/")
        except ValueError:
            # Path is outside project root
            return abs_path.replace("\\", "/")

    def get_stats(self) -> dict:
        """Get handler statistics."""
        return self.stats.copy()

    def reset_stats(self):
        """Reset statistics counters."""
        for key in self.stats:
            self.stats[key] = 0
