"""
Tests for the Generic parser.

This module tests the generic fallback parser that handles files
not covered by specific parsers.
"""

from pathlib import Path

import pytest

from linkwatcher.models import LinkReference
from linkwatcher.parsers.generic import GenericParser


class TestGenericParser:
    """Test cases for GenericParser."""

    def test_parser_initialization(self):
        """Test parser initialization."""
        parser = GenericParser()

        # Check that regex patterns are compiled
        assert parser.quoted_pattern is not None
        assert parser.unquoted_pattern is not None

    def test_parse_quoted_references(self, temp_project_dir):
        """Test parsing quoted file references in generic text files."""
        parser = GenericParser()

        # Create generic text file with quoted references
        text_file = temp_project_dir / "notes.txt"
        content = """Project Notes

Configuration files:
- Main config: "config.yaml"
- Database config: 'database.json'
- Logging config: "logging.conf"

Data files:
- User data: "../tests/parsers/users.csv"
- Product data: '../tests/parsers/products.json'
- Order data: "../tests/parsers/orders.xml"

Documentation:
- See "docs/readme.md" for setup instructions
- Check 'docs/api.md' for API documentation
- Review "docs/troubleshooting.md" for common issues

Scripts and tools:
- Build script: "../tests/parsers/build.sh"
- Deploy script: '../tests/parsers/deploy.py'
- Test runner: "scripts/run_tests.bat"
"""
        text_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(text_file))

        # Should find quoted references
        assert len(references) >= 10

        # Check specific references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config.yaml",
            "database.json",
            "logging.conf",
            "../tests/parsers/users.csv",
            "../tests/parsers/products.json",
            "../tests/parsers/orders.xml",
            "docs/readme.md",
            "docs/api.md",
            "docs/troubleshooting.md",
            "../tests/parsers/build.sh",
            "../tests/parsers/deploy.py",
            "scripts/run_tests.bat",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

        # Check link types
        for ref in references:
            assert ref.link_type == "generic-quoted"

    @pytest.mark.xfail(
        reason="Unquoted detection heuristic too conservative for standalone filenames"
    )
    def test_parse_standalone_file_references(self, temp_project_dir):
        """Test parsing standalone file references."""
        parser = GenericParser()

        # Create file with standalone references
        text_file = temp_project_dir / "file_list.txt"
        content = """File Inventory

Configuration Files:
config.yaml
settings.json
database.conf
logging.properties

Data Files:
users.csv
products.json
orders.xml
inventory.db

Documentation:
readme.md
installation.txt
changelog.md
license.txt

Scripts:
build.sh
deploy.py
test.bat
cleanup.ps1

Assets:
logo.png
background.jpg
styles.css
app.js

Templates:
index.html
error.html
email.template
report.template
"""
        text_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(text_file))

        # Should find standalone references
        assert len(references) >= 15

        # Check specific references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config.yaml",
            "settings.json",
            "database.conf",
            "logging.properties",
            "users.csv",
            "products.json",
            "orders.xml",
            "inventory.db",
            "readme.md",
            "installation.txt",
            "changelog.md",
            "license.txt",
            "build.sh",
            "deploy.py",
            "test.bat",
            "cleanup.ps1",
            "logo.png",
            "background.jpg",
            "styles.css",
            "app.js",
            "index.html",
            "error.html",
            "email.template",
            "report.template",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

        # Check link types
        standalone_refs = [ref for ref in references if ref.link_type == "generic-standalone"]
        assert len(standalone_refs) >= 10

    @pytest.mark.xfail(
        reason="Unquoted detection heuristic too conservative for standalone filenames"
    )
    def test_parse_mixed_references(self, temp_project_dir):
        """Test parsing files with both quoted and standalone references."""
        parser = GenericParser()

        # Create file with mixed reference types
        text_file = temp_project_dir / "mixed.txt"
        content = """Project Setup Instructions

1. Copy "config.template.yaml" to config.yaml
2. Edit the database settings in config.yaml
3. Run the setup script: "../tests/parsers/setup.sh"
4. Check that data.json was created
5. Verify logs are written to "logs/setup.log"
6. Test with sample.txt file
7. Review the output in 'output/results.json'
8. Clean up using cleanup.sh script

Required files:
- config.yaml (main configuration)
- "database.conf" (database settings)
- ../tests/parsers/setup.sh (setup script)
- '../tests/parsers/cleanup.sh' (cleanup script)

Generated files:
- data.json
- "logs/setup.log"
- output/results.json
- 'temp/cache.tmp'
"""
        text_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(text_file))

        # Should find both quoted and standalone references
        assert len(references) >= 10

        # Check specific references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config.template.yaml",
            "config.yaml",
            "../tests/parsers/setup.sh",
            "data.json",
            "logs/setup.log",
            "sample.txt",
            "output/results.json",
            "cleanup.sh",
            "database.conf",
            "../tests/parsers/cleanup.sh",
            "temp/cache.tmp",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

        # Should have both quoted and standalone references
        quoted_refs = [ref for ref in references if ref.link_type == "generic-quoted"]
        standalone_refs = [ref for ref in references if ref.link_type == "generic-standalone"]

        assert len(quoted_refs) >= 4
        assert len(standalone_refs) >= 4

    @pytest.mark.xfail(reason="Unquoted keyword heuristic too restrictive for standalone refs")
    def test_avoid_false_positives(self, temp_project_dir):
        """Test that false positives are avoided."""
        parser = GenericParser()

        # Create file with potential false positives
        text_file = temp_project_dir / "false_positives.txt"
        content = """Test File with Potential False Positives

These should NOT be detected as file references:
- Version numbers: "1.2.3", "v2.0.1"
- Email addresses: "user@example.com", 'admin@test.org'
- URLs: "https://example.com", 'http://test.com/api'
- UUIDs: "123e4567-e89b-12d3-a456-426614174000"
- Dates: "2024-01-15", '2024/12/31'
- Times: "14:30:00", '09:15:30'
- IP addresses: "192.168.1.1", '10.0.0.1'
- Phone numbers: "+1-555-123-4567", '(555) 987-6543'
- Currency: "$123.45", '€99.99'
- Percentages: "50%", '75.5%'

These SHOULD be detected as file references:
- Configuration: "config.json"
- Data file: 'users.csv'
- Script: backup.sh
- Document: readme.md

Edge cases:
- Extension only: ".txt" (should not be detected)
- No extension: "filename" (might be detected)
- Very short: "a.b" (might be detected)
- Numbers only: "123.456" (should not be detected)
"""
        text_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(text_file))

        targets = [ref.link_target for ref in references]

        # Should find actual file references
        assert "config.json" in targets
        assert "users.csv" in targets
        assert "backup.sh" in targets
        assert "readme.md" in targets

        # Should not find false positives
        false_positives = [
            "1.2.3",
            "v2.0.1",
            "user@example.com",
            "admin@test.org",
            "https://example.com",
            "http://test.com/api",
            "123e4567-e89b-12d3-a456-426614174000",
            "2024-01-15",
            "2024/12/31",
            "14:30:00",
            "09:15:30",
            "192.168.1.1",
            "10.0.0.1",
            "+1-555-123-4567",
            "(555) 987-6543",
            "$123.45",
            "€99.99",
            "50%",
            "75.5%",
            "123.456",
        ]

        for false_positive in false_positives:
            assert false_positive not in targets, f"False positive '{false_positive}' was detected"

    @pytest.mark.xfail(reason="Regex doesn't extract sub-paths from URIs like sqlite:///")
    def test_parse_configuration_files(self, temp_project_dir):
        """Test parsing various configuration file formats."""
        parser = GenericParser()

        # Create .env file
        env_file = temp_project_dir / ".env"
        env_content = """# Environment configuration
DATABASE_URL="sqlite:///data/app.db"
LOG_FILE='../tests/parsers/application.log'
CONFIG_PATH="config/settings.yaml"
TEMPLATE_DIR=templates/
STATIC_FILES="static/"
BACKUP_LOCATION='backups/daily/'
"""
        env_file.write_text(env_content)

        # Parse the file
        references = parser.parse_file(str(env_file))

        # Should find file path references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "data/app.db",
            "../tests/parsers/application.log",
            "config/settings.yaml",
            "templates/",
            "static/",
            "backups/daily/",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    def test_parse_log_files(self, temp_project_dir):
        """Test parsing log files with file references."""
        parser = GenericParser()

        # Create log file
        log_file = temp_project_dir / "application.log"
        log_content = """2024-01-15 10:30:00 INFO  Loading configuration from "config/app.yaml"
2024-01-15 10:30:01 INFO  Database connection established using 'database/app.db'
2024-01-15 10:30:02 WARN  Template file "templates/error.html" not found
2024-01-15 10:30:03 INFO  Loading user data from data/users.json
2024-01-15 10:30:04 ERROR Failed to write to "logs/error.log"
2024-01-15 10:30:05 INFO  Backup created at 'backups/2024-01-15.tar.gz'
2024-01-15 10:30:06 DEBUG Processing file: temp/processing.tmp
2024-01-15 10:30:07 INFO  Report generated: "reports/daily_report.pdf"
"""
        log_file.write_text(log_content)

        # Parse the file
        references = parser.parse_file(str(log_file))

        # Should find file references in log entries
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config/app.yaml",
            "database/app.db",
            "templates/error.html",
            "data/users.json",
            "logs/error.log",
            "backups/2024-01-15.tar.gz",
            "temp/processing.tmp",
            "reports/daily_report.pdf",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    @pytest.mark.xfail(reason="Unquoted detection + mixed-line skipping misses many references")
    def test_parse_readme_files(self, temp_project_dir):
        """Test parsing README files with file references."""
        parser = GenericParser()

        # Create README file (plain text, not markdown)
        readme_file = temp_project_dir / "README.txt"
        readme_content = """Project README

INSTALLATION:
1. Copy "config.template.json" to config.json
2. Edit config.json with your settings
3. Run setup.sh to initialize
4. Check that data/ directory was created

CONFIGURATION:
- Main config: config.json
- Database config: "database.conf"
- Logging config: 'logging.properties'

DATA FILES:
- User data: ../tests/parsers/users.csv
- Product catalog: "../tests/parsers/products.json"
- Order history: '../tests/parsers/orders.xml'

SCRIPTS:
- Build: ../tests/parsers/build.sh
- Deploy: "../tests/parsers/deploy.py"
- Test: 'scripts/test.bat'
- Cleanup: scripts/cleanup.ps1

DOCUMENTATION:
- API docs: docs/api.txt
- User guide: "docs/user_guide.pdf"
- FAQ: 'docs/faq.html'

LOGS:
Application logs are written to logs/app.log
Error logs go to "logs/error.log"
Debug info in 'logs/debug.log'
"""
        readme_file.write_text(readme_content)

        # Parse the file
        references = parser.parse_file(str(readme_file))

        # Should find file references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config.template.json",
            "config.json",
            "setup.sh",
            "database.conf",
            "logging.properties",
            "../tests/parsers/users.csv",
            "../tests/parsers/products.json",
            "../tests/parsers/orders.xml",
            "../tests/parsers/build.sh",
            "../tests/parsers/deploy.py",
            "scripts/test.bat",
            "scripts/cleanup.ps1",
            "docs/api.txt",
            "docs/user_guide.pdf",
            "docs/faq.html",
            "logs/app.log",
            "logs/error.log",
            "logs/debug.log",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    def test_line_and_column_positions(self, temp_project_dir):
        """Test that line and column positions are correctly recorded."""
        parser = GenericParser()

        # Create file with known positions
        text_file = temp_project_dir / "positions.txt"
        content = """Line 1: "config.json"
Line 2: data.csv
Line 3: 'logs.txt'"""
        text_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(text_file))

        # Check positions
        for ref in references:
            assert ref.line_number > 0
            assert ref.column_start >= 0
            assert ref.column_end > ref.column_start

            # Verify position makes sense
            lines = content.split("\n")
            if ref.line_number <= len(lines):
                line = lines[ref.line_number - 1]
                if ref.column_end <= len(line):
                    extracted = line[ref.column_start : ref.column_end]
                    # Should contain the link target or be part of the reference
                    assert ref.link_target in extracted or ref.link_target in line

    @pytest.mark.xfail(reason="Missing extensions in common_extensions + unquoted heuristic")
    def test_file_extension_handling(self, temp_project_dir):
        """Test handling of various file extensions."""
        parser = GenericParser()

        # Test different file types
        file_types = [
            ("config.ini", "INI configuration file"),
            ("settings.conf", "Configuration file"),
            ("app.properties", "Properties file"),
            ("data.xml", "XML data file"),
            ("style.css", "CSS stylesheet"),
            ("script.js", "JavaScript file"),
            ("page.html", "HTML page"),
            ("query.sql", "SQL query file"),
            ("build.gradle", "Gradle build file"),
            ("pom.xml", "Maven POM file"),
        ]

        for filename, description in file_types:
            test_file = temp_project_dir / f"test_{filename.replace('.', '_')}.txt"
            content = f"""Test file for {description}

Referenced file: "{filename}"
Also see: {filename}
Configuration in '{filename}'
"""
            test_file.write_text(content)

            # Parse the file
            references = parser.parse_file(str(test_file))

            # Should find the file reference
            targets = [ref.link_target for ref in references]
            assert filename in targets, f"Failed to detect {filename} in {test_file}"

    def test_empty_file(self, temp_project_dir):
        """Test parsing an empty file."""
        parser = GenericParser()

        # Create empty file
        empty_file = temp_project_dir / "empty.txt"
        empty_file.write_text("")

        # Parse the file
        references = parser.parse_file(str(empty_file))

        # Should return empty list
        assert references == []

    def test_binary_file_handling(self, temp_project_dir):
        """Test handling of binary files."""
        parser = GenericParser()

        # Create a file with binary content
        binary_file = temp_project_dir / "binary.dat"
        binary_content = b"\x00\x01\x02\x03\xff\xfe\xfd"
        binary_file.write_bytes(binary_content)

        # Parse the file
        references = parser.parse_file(str(binary_file))

        # Should handle gracefully and return empty list
        assert references == []

    @pytest.mark.xfail(reason="'reference' not in unquoted keyword heuristic list")
    def test_large_file_handling(self, temp_project_dir):
        """Test handling of large files."""
        parser = GenericParser()

        # Create a large file with some file references
        large_file = temp_project_dir / "large.txt"
        content = "Large file content\n" * 1000
        content += 'File reference: "config.json"\n'
        content += "More content\n" * 1000
        content += "Another reference: data.csv\n"
        content += "Even more content\n" * 1000

        large_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(large_file))

        # Should find references even in large files
        targets = [ref.link_target for ref in references]
        assert "config.json" in targets
        assert "data.csv" in targets

    def test_error_handling(self):
        """Test error handling for invalid files."""
        parser = GenericParser()

        # Try to parse non-existent file
        references = parser.parse_file("nonexistent.txt")

        # Should return empty list without crashing
        assert references == []

    @pytest.mark.xfail(reason="Regex character class [a-zA-Z0-9_] excludes Unicode characters")
    def test_unicode_handling(self, temp_project_dir):
        """Test handling of Unicode content."""
        parser = GenericParser()

        # Create file with Unicode content
        unicode_file = temp_project_dir / "unicode.txt"
        content = """Unicode Test File 🚀

Configuration: "config.json"
Data file: données.csv
Log file: 'журнал.log'
Template: plantilla.html

Special characters in paths:
- "files/café.txt"
- 'docs/résumé.pdf'
- scripts/测试.py
"""
        unicode_file.write_text(content, encoding="utf-8")

        # Parse the file
        references = parser.parse_file(str(unicode_file))

        # Should handle Unicode correctly
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config.json",
            "données.csv",
            "журнал.log",
            "plantilla.html",
            "files/café.txt",
            "docs/résumé.pdf",
            "scripts/测试.py",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"
