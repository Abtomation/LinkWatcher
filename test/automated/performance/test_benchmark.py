"""
Benchmark Tests for LinkWatcher Performance

Converted from scripts/benchmark.py into pytest-integrated performance tests.
Tests parsing throughput, database operations, and initial scan performance.

Test Cases:
- BM-001: File parsing throughput
- BM-002: Database add/lookup/update operations
- BM-003: Initial scan performance
"""

import time
from pathlib import Path
from typing import Dict, List

import pytest

from linkwatcher import LinkDatabase, LinkParser, LinkWatcherService
from linkwatcher.models import LinkReference

pytestmark = [
    pytest.mark.feature("cross-cutting"),
    pytest.mark.priority("Extended"),
    pytest.mark.cross_cutting(["0.1.1", "0.1.2", "2.1.1"]),
    pytest.mark.test_type("performance"),
]


def create_benchmark_files(base_dir: Path, num_files: int = 100) -> List[Path]:
    """Create test files for benchmarking."""
    files = []

    for i in range(num_files):
        md_file = base_dir / f"doc_{i:03d}.md"
        content = f"""# Document {i}

This document contains several links:
- [Link to doc {(i+1) % num_files}](doc_{(i+1) % num_files:03d}.md)
- [Link to text file](file_{i:03d}.txt)
- Reference to "data_{i:03d}.json"
- Standalone reference: config_{i:03d}.yaml

## Section {i}
More content with [relative link](../other/file_{i}.md).
"""
        md_file.write_text(content)
        files.append(md_file)

        txt_file = base_dir / f"file_{i:03d}.txt"
        txt_file.write_text(f"Content for file {i}")
        files.append(txt_file)

        json_file = base_dir / f"data_{i:03d}.json"
        json_file.write_text(f'{{"id": {i}, "name": "file_{i}"}}')
        files.append(json_file)

        yaml_file = base_dir / f"config_{i:03d}.yaml"
        yaml_file.write_text(f"name: config_{i}\nvalue: {i}\n")
        files.append(yaml_file)

    return files


class TestParsingBenchmark:
    """Benchmark tests for file parsing throughput."""

    @pytest.mark.performance
    def test_bm_001_parsing_throughput(self, temp_project_dir):
        """
        BM-001: File parsing throughput

        Measures parsing speed across 100 files with mixed formats.
        Expected: >50 files/second parsing rate.
        """
        num_files = 100
        files = create_benchmark_files(temp_project_dir, num_files)
        parser = LinkParser()

        # Warm up
        for file in files[:10]:
            if file.suffix == ".md":
                parser.parse_file(str(file))

        # Benchmark
        parseable_extensions = {".md", ".txt", ".json", ".yaml"}
        start_time = time.time()
        total_references = 0

        for file in files:
            if file.suffix in parseable_extensions:
                references = parser.parse_file(str(file))
                total_references += len(references)

        elapsed = time.time() - start_time
        files_parsed = len([f for f in files if f.suffix in parseable_extensions])
        files_per_second = files_parsed / elapsed

        print(f"\nParsing: {files_parsed} files in {elapsed:.2f}s")
        print(f"  {files_per_second:.1f} files/second")
        print(f"  {total_references} references found")
        print(f"  {total_references / elapsed:.1f} references/second")

        assert elapsed < 10.0, f"Parsing {files_parsed} files took {elapsed:.2f}s (expected <10s)"
        assert total_references > 0, "Should find at least some references"


class TestDatabaseBenchmark:
    """Benchmark tests for database operations."""

    @pytest.mark.performance
    def test_bm_002_database_operations(self):
        """
        BM-002: Database add/lookup/update throughput

        Measures database CRUD operation speed with 1000 references.
        """
        db = LinkDatabase()
        num_operations = 1000

        references = []
        for i in range(num_operations):
            ref = LinkReference(
                file_path=f"doc_{i}.md",
                line_number=1,
                column_start=0,
                column_end=10,
                link_text=f"file_{i}.txt",
                link_target=f"file_{i}.txt",
                link_type="markdown",
            )
            references.append(ref)

        # Benchmark adds
        start_time = time.time()
        for ref in references:
            db.add_link(ref)
        add_time = time.time() - start_time

        # Benchmark lookups (sample every 10th)
        start_time = time.time()
        for i in range(0, num_operations, 10):
            db.get_references_to_file(f"file_{i}.txt")
        lookup_time = time.time() - start_time

        # Benchmark updates (sample every 20th)
        start_time = time.time()
        for i in range(0, num_operations, 20):
            db.update_target_path(f"file_{i}.txt", f"new_file_{i}.txt")
        update_time = time.time() - start_time

        adds_per_sec = num_operations / max(add_time, 1e-9)
        lookups_per_sec = (num_operations // 10) / max(lookup_time, 1e-9)
        updates_per_sec = (num_operations // 20) / max(update_time, 1e-9)

        print(f"\nDatabase operations ({num_operations} refs):")
        print(f"  Adds:    {adds_per_sec:.0f}/s ({add_time:.3f}s)")
        print(f"  Lookups: {lookups_per_sec:.0f}/s ({lookup_time:.3f}s)")
        print(f"  Updates: {updates_per_sec:.0f}/s ({update_time:.3f}s)")

        assert add_time < 5.0, f"Adding {num_operations} refs took {add_time:.2f}s"
        assert lookup_time < 2.0, f"Lookups took {lookup_time:.2f}s"
        assert update_time < 2.0, f"Updates took {update_time:.2f}s"


class TestInitialScanBenchmark:
    """Benchmark tests for initial project scan."""

    @pytest.mark.performance
    @pytest.mark.slow
    def test_bm_003_initial_scan(self, temp_project_dir):
        """
        BM-003: Initial scan performance

        Measures full project scan time with 100 files.
        Expected: Complete within 10 seconds.
        """
        num_files = 100
        create_benchmark_files(temp_project_dir, num_files)

        service = LinkWatcherService(str(temp_project_dir))

        start_time = time.time()
        service._initial_scan()
        elapsed = time.time() - start_time

        stats = service.link_db.get_stats()

        print(f"\nInitial scan: {elapsed:.2f}s")
        print(f"  Files with links: {stats['files_with_links']}")
        print(f"  Total references: {stats['total_references']}")
        print(f"  Files/second: {stats['files_with_links'] / elapsed:.1f}")

        assert elapsed < 10.0, f"Initial scan took {elapsed:.2f}s (expected <10s)"
        assert stats["files_with_links"] > 0, "Should find files with links"
        assert stats["total_references"] > 0, "Should find references"
