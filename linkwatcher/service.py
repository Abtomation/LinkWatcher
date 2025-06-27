"""
Main LinkWatcher service that orchestrates all components.

This module provides the main service class that coordinates the database,
parser, updater, and file system handler.
"""

import os
import signal
import sys
import time
from pathlib import Path

from colorama import Fore, Style
from watchdog.observers import Observer

from .database import LinkDatabase
from .handler import LinkMaintenanceHandler
from .parser import LinkParser
from .updater import LinkUpdater


class LinkWatcherService:
    """
    Main service that orchestrates all LinkWatcher components.

    This service:
    1. Initializes all components
    2. Manages the file system observer
    3. Handles graceful shutdown
    4. Provides status and statistics
    """

    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root).resolve()
        
        # Validate project root exists
        if not self.project_root.exists():
            raise FileNotFoundError(f"Project root does not exist: {self.project_root}")
        
        if not self.project_root.is_dir():
            raise NotADirectoryError(f"Project root is not a directory: {self.project_root}")
        
        self.observer = None
        self.running = False

        # Initialize components
        self.link_db = LinkDatabase()
        self.parser = LinkParser()
        self.updater = LinkUpdater(str(self.project_root))
        self.handler = LinkMaintenanceHandler(
            self.link_db, self.parser, self.updater, str(self.project_root)
        )

        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

    def start(self, initial_scan: bool = True):
        """
        Start the LinkWatcher service.

        Args:
            initial_scan: Whether to perform initial scan of all files
        """
        print(f"{Fore.CYAN}🚀 Starting LinkWatcher service...")
        print(f"{Fore.CYAN}📁 Project root: {self.project_root}")

        try:
            # Perform initial scan if requested
            if initial_scan:
                print(f"{Fore.YELLOW}📊 Performing initial scan...")
                self._initial_scan()
                stats = self.link_db.get_stats()
                print(f"{Fore.GREEN}✓ Initial scan complete:")
                print(f"   • {stats['files_with_links']} files with links")
                print(f"   • {stats['total_references']} total references")
                print(f"   • {stats['total_targets']} unique targets")

            # Setup file system observer
            self.observer = Observer()
            self.observer.schedule(self.handler, str(self.project_root), recursive=True)

            # Start watching
            self.observer.start()
            self.running = True

            print(f"{Fore.GREEN}👁️ LinkWatcher is now monitoring file changes...")
            print(f"{Fore.CYAN}Press Ctrl+C to stop")

            # Keep the service running
            try:
                while self.running:
                    time.sleep(1)
            except KeyboardInterrupt:
                pass

        except Exception as e:
            print(f"{Fore.RED}✗ Error starting service: {e}")
            raise
        finally:
            self.stop()

    def stop(self):
        """Stop the LinkWatcher service."""
        if self.running:
            print(f"\n{Fore.YELLOW}🛑 Stopping LinkWatcher service...")
            self.running = False

            if self.observer:
                self.observer.stop()
                self.observer.join()

            # Print final statistics
            self._print_final_stats()
            print(f"{Fore.GREEN}✓ LinkWatcher stopped")

    def _initial_scan(self):
        """Perform initial scan of all monitored files."""
        scanned_files = 0

        for root, dirs, files in os.walk(self.project_root):
            # Skip ignored directories
            dirs[:] = [d for d in dirs if d not in self.handler.ignored_dirs]

            for file in files:
                file_path = os.path.join(root, file)

                if self.handler._should_monitor_file(file_path):
                    try:
                        references = self.parser.parse_file(file_path)
                        # Normalize file paths to relative paths before storing
                        relative_file_path = self.handler._get_relative_path(file_path)
                        for ref in references:
                            # Update the reference to use relative path
                            ref.file_path = relative_file_path
                            self.link_db.add_link(ref)
                        scanned_files += 1

                        if scanned_files % 50 == 0:  # Progress indicator
                            print(f"{Fore.CYAN}   Scanned {scanned_files} files...")

                    except Exception as e:
                        print(f"{Fore.YELLOW}Warning: Could not scan {file_path}: {e}")

        self.link_db.last_scan = time.time()
        print(f"{Fore.GREEN}   Scanned {scanned_files} files total")

    def _signal_handler(self, signum, frame):
        """Handle shutdown signals."""
        print(f"\n{Fore.YELLOW}Received signal {signum}, shutting down...")
        self.running = False

    def _print_final_stats(self):
        """Print final statistics before shutdown."""
        handler_stats = self.handler.get_stats()
        db_stats = self.link_db.get_stats()

        print(f"\n{Fore.CYAN}📊 Final Statistics:")
        print(f"   Files moved: {handler_stats['files_moved']}")
        print(f"   Files deleted: {handler_stats['files_deleted']}")
        print(f"   Files created: {handler_stats['files_created']}")
        print(f"   Links updated: {handler_stats['links_updated']}")
        print(f"   Errors: {handler_stats['errors']}")
        print(
            f"   Database: {db_stats['total_references']} references to {db_stats['total_targets']} targets"
        )

    def get_status(self) -> dict:
        """Get current service status."""
        return {
            "running": self.running,
            "project_root": str(self.project_root),
            "database_stats": self.link_db.get_stats(),
            "handler_stats": self.handler.get_stats(),
            "last_scan": self.link_db.last_scan,
        }

    def force_rescan(self):
        """Force a complete rescan of all files."""
        print(f"{Fore.YELLOW}🔄 Forcing complete rescan...")
        self.link_db.clear()
        self._initial_scan()
        print(f"{Fore.GREEN}✓ Rescan complete")

    def set_dry_run(self, enabled: bool):
        """Enable or disable dry run mode."""
        self.updater.set_dry_run(enabled)
        if enabled:
            print(f"{Fore.CYAN}🧪 Dry run mode enabled - no files will be modified")
        else:
            print(f"{Fore.GREEN}✏️ Dry run mode disabled - files will be modified")

    def add_parser(self, extension: str, parser):
        """Add a custom parser for a specific file extension."""
        self.parser.add_parser(extension, parser)
        # Update handler's monitored extensions
        self.handler.monitored_extensions.add(extension.lower())

    def check_links(self) -> dict:
        """Check all links and return broken ones."""
        print(f"{Fore.YELLOW}🔍 Checking all links...")

        broken_links = []
        total_checked = 0

        for target_path, references in self.link_db.links.items():
            for ref in references:
                total_checked += 1

                # Check if target file exists
                target_abs_path = os.path.join(self.project_root, target_path)
                if not os.path.exists(target_abs_path):
                    broken_links.append(
                        {"reference": ref, "target_path": target_path, "reason": "File not found"}
                    )

        result = {
            "total_checked": total_checked,
            "broken_count": len(broken_links),
            "broken_links": broken_links,
        }

        if broken_links:
            print(f"{Fore.RED}❌ Found {len(broken_links)} broken link(s)")
            for broken in broken_links[:10]:  # Show first 10
                ref = broken["reference"]
                print(
                    f"   • {ref.file_path}:{ref.line_number} → {broken['target_path']} ({broken['reason']})"
                )
            if len(broken_links) > 10:
                print(f"   ... and {len(broken_links) - 10} more")
        else:
            print(f"{Fore.GREEN}✅ All {total_checked} links are valid")

        return result
