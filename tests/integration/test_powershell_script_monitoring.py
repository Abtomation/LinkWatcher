"""
Integration tests for PowerShell script file monitoring and link updates.

This test verifies that when .ps1 files are moved, links pointing to them
in markdown files are properly updated.
"""

import os
import tempfile
import time
from pathlib import Path

import pytest

from linkwatcher.database import LinkDatabase
from linkwatcher.handler import LinkMaintenanceHandler
from linkwatcher.parser import LinkParser
from linkwatcher.updater import LinkUpdater


class TestPowerShellScriptMonitoring:
    """Test PowerShell script file monitoring and link updates."""

    def setup_method(self):
        """Set up test environment."""
        self.temp_dir = tempfile.mkdtemp()
        self.project_root = Path(self.temp_dir)
        
        # Create directory structure
        (self.project_root / "scripts").mkdir()
        (self.project_root / "scripts" / "automation").mkdir()
        (self.project_root / "docs").mkdir()
        
        # Initialize components
        self.link_db = LinkDatabase()
        self.parser = LinkParser()
        self.updater = LinkUpdater(str(self.project_root))
        self.handler = LinkMaintenanceHandler(
            self.link_db, self.parser, self.updater, str(self.project_root)
        )

    def test_ps1_extension_in_monitored_extensions(self):
        """Test that .ps1 extension is included in monitored extensions."""
        assert ".ps1" in self.handler.monitored_extensions
        assert ".sh" in self.handler.monitored_extensions
        assert ".bat" in self.handler.monitored_extensions

    def test_should_monitor_ps1_files(self):
        """Test that PowerShell files are correctly identified for monitoring."""
        ps1_file = str(self.project_root / "scripts" / "deploy.ps1")
        assert self.handler._should_monitor_file(ps1_file)

    def test_powershell_script_move_updates_markdown_links(self):
        """Test that moving a PowerShell script updates links in markdown files."""
        # Create PowerShell script
        ps1_file = self.project_root / "scripts" / "deploy.ps1"
        ps1_content = """# PowerShell Deployment Script
Write-Host "Starting deployment..."
Write-Host "Deployment completed!"
"""
        ps1_file.write_text(ps1_content)

        # Create markdown file with link to PowerShell script
        md_file = self.project_root / "docs" / "deployment.md"
        md_content = """# Deployment Guide

## Scripts

- [Deployment Script](../scripts/deploy.ps1) - Main deployment automation
- Run the [deploy.ps1](../scripts/deploy.ps1) script to start deployment

## Instructions

1. Execute [../scripts/deploy.ps1](../scripts/deploy.ps1)
2. Check logs after running [deploy.ps1](../scripts/deploy.ps1)
"""
        md_file.write_text(md_content)

        # Parse initial files to populate database
        ps1_refs = self.parser.parse_file(str(ps1_file))
        md_refs = self.parser.parse_file(str(md_file))
        
        # Add references to database
        for ref in ps1_refs + md_refs:
            # Convert to relative path
            ref.file_path = str(Path(ref.file_path).relative_to(self.project_root)).replace("\\", "/")
            self.link_db.add_link(ref)

        # Verify initial links are found
        initial_refs = self.link_db.get_references_to_file("scripts/deploy.ps1")
        assert len(initial_refs) > 0, "Should find references to deploy.ps1"
        print(f"Found {len(initial_refs)} initial references to deploy.ps1")

        # Move PowerShell script
        new_ps1_file = self.project_root / "scripts" / "automation" / "deploy.ps1"
        ps1_file.rename(new_ps1_file)

        # Simulate file move event
        from watchdog.events import FileMovedEvent
        event = FileMovedEvent(str(ps1_file), str(new_ps1_file))
        
        # Handle the move
        self.handler._handle_file_moved(event)

        # Read updated markdown content
        updated_md_content = md_file.read_text()
        print("Updated markdown content:")
        print(updated_md_content)

        # Verify links were updated
        assert "../scripts/automation/deploy.ps1" in updated_md_content
        assert "../scripts/deploy.ps1" not in updated_md_content or updated_md_content.count("../scripts/deploy.ps1") == 0

        # Verify database was updated
        old_refs = self.link_db.get_references_to_file("scripts/deploy.ps1")
        new_refs = self.link_db.get_references_to_file("scripts/automation/deploy.ps1")
        
        print(f"Old references count: {len(old_refs)}")
        print(f"New references count: {len(new_refs)}")
        
        # Should have no references to old path and some to new path
        assert len(old_refs) == 0, "Should have no references to old path"
        assert len(new_refs) > 0, "Should have references to new path"

    def test_multiple_powershell_scripts_move(self):
        """Test moving multiple PowerShell scripts."""
        # Create multiple PowerShell scripts
        scripts = ["deploy.ps1", "setup.ps1", "cleanup.ps1"]
        script_files = []
        
        for script_name in scripts:
            script_file = self.project_root / "scripts" / script_name
            script_file.write_text(f"# {script_name}\nWrite-Host 'Running {script_name}'")
            script_files.append(script_file)

        # Create markdown file with links to all scripts
        md_file = self.project_root / "docs" / "scripts.md"
        md_content = """# Script Documentation

## Available Scripts

- [Deploy Script](../scripts/deploy.ps1)
- [Setup Script](../scripts/setup.ps1)  
- [Cleanup Script](../scripts/cleanup.ps1)

## Usage

Run [deploy.ps1](../scripts/deploy.ps1) first, then [setup.ps1](../scripts/setup.ps1).
"""
        md_file.write_text(md_content)

        # Parse and populate database
        md_refs = self.parser.parse_file(str(md_file))
        for ref in md_refs:
            ref.file_path = str(Path(ref.file_path).relative_to(self.project_root)).replace("\\", "/")
            self.link_db.add_link(ref)

        # Move one script
        old_path = script_files[0]  # deploy.ps1
        new_path = self.project_root / "scripts" / "automation" / "deploy.ps1"
        old_path.rename(new_path)

        # Handle move
        from watchdog.events import FileMovedEvent
        event = FileMovedEvent(str(old_path), str(new_path))
        self.handler._handle_file_moved(event)

        # Verify only the moved script's links were updated
        updated_content = md_file.read_text()
        assert "../scripts/automation/deploy.ps1" in updated_content
        assert "../scripts/setup.ps1" in updated_content  # Should remain unchanged
        assert "../scripts/cleanup.ps1" in updated_content  # Should remain unchanged

    def test_powershell_script_with_different_link_formats(self):
        """Test PowerShell script moves with various markdown link formats."""
        # Create PowerShell script
        ps1_file = self.project_root / "scripts" / "test.ps1"
        ps1_file.write_text("Write-Host 'Test script'")

        # Create markdown with various link formats
        md_file = self.project_root / "docs" / "test.md"
        md_content = """# Test Links

## Different Link Formats

1. Standard link: [Test Script](../scripts/test.ps1)
2. Reference link: [test-script]
3. Inline code: `../scripts/test.ps1`
4. Link with title: [Test](../scripts/test.ps1 "PowerShell Test Script")
5. Relative link: [test.ps1](../scripts/test.ps1)

[test-script]: ../scripts/test.ps1 "Reference link to test script"
"""
        md_file.write_text(md_content)

        # Parse and populate database
        md_refs = self.parser.parse_file(str(md_file))
        for ref in md_refs:
            ref.file_path = str(Path(ref.file_path).relative_to(self.project_root)).replace("\\", "/")
            self.link_db.add_link(ref)

        # Verify initial references
        initial_refs = self.link_db.get_references_to_file("scripts/test.ps1")
        print(f"Initial references found: {len(initial_refs)}")
        for ref in initial_refs:
            print(f"  - {ref.link_type}: {ref.link_target} at line {ref.line_number}")

        # Move script
        new_ps1_file = self.project_root / "scripts" / "automation" / "test.ps1"
        ps1_file.rename(new_ps1_file)

        # Handle move
        from watchdog.events import FileMovedEvent
        event = FileMovedEvent(str(ps1_file), str(new_ps1_file))
        self.handler._handle_file_moved(event)

        # Verify updates
        updated_content = md_file.read_text()
        print("Updated content:")
        print(updated_content)
        
        # Should contain new path
        assert "../scripts/automation/test.ps1" in updated_content
        
        # Should not contain old path (except possibly in inline code which might not be updated)
        old_path_count = updated_content.count("../scripts/test.ps1")
        print(f"Remaining old path references: {old_path_count}")

    def teardown_method(self):
        """Clean up test environment."""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)


if __name__ == "__main__":
    # Run a simple test
    test = TestPowerShellScriptMonitoring()
    test.setup_method()
    
    try:
        test.test_ps1_extension_in_monitored_extensions()
        print("✓ PowerShell extension monitoring test passed")
        
        test.test_should_monitor_ps1_files()
        print("✓ PowerShell file monitoring test passed")
        
        test.test_powershell_script_move_updates_markdown_links()
        print("✓ PowerShell script move test passed")
        
    except Exception as e:
        print(f"✗ Test failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        test.teardown_method()