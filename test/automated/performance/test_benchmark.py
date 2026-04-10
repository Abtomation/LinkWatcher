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
from typing import List

import pytest
from watchdog.events import FileMovedEvent

from linkwatcher import LinkDatabase, LinkParser, LinkWatcherService
from linkwatcher.models import LinkReference
from linkwatcher.move_detector import MoveDetector
from linkwatcher.validator import LinkValidator

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


class TestUpdaterBenchmark:
    """Benchmark tests for file update throughput."""

    @pytest.mark.performance
    def test_bm_004_updater_throughput(self, temp_project_dir):
        """
        BM-004: Updater throughput

        Measures how fast the updater rewrites references across files
        when a single target file is moved. 50 source files each
        referencing one target file.
        Expected: >10 files updated per second.
        """
        num_files = 50
        target_file = temp_project_dir / "target.txt"
        target_file.write_text("Target content")

        # Create source files that reference the target
        for i in range(num_files):
            src = temp_project_dir / f"src_{i:03d}.md"
            src.write_text(
                f"# Source {i}\n\n" f"- [Target](target.txt)\n" f'- See "target.txt" for details\n'
            )

        # Scan to populate the database
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Collect references pointing to target
        refs = service.link_db.get_references_to_file("target.txt")
        assert len(refs) >= num_files, f"Expected ≥{num_files} refs, got {len(refs)}"

        # Move the target and measure update time
        new_target = temp_project_dir / "moved" / "target.txt"
        new_target.parent.mkdir()
        target_file.rename(new_target)

        start_time = time.time()
        move_event = FileMovedEvent(str(target_file), str(new_target))
        service.handler.on_moved(move_event)
        elapsed = time.time() - start_time

        files_per_sec = num_files / max(elapsed, 1e-9)

        print(f"\nUpdater throughput ({num_files} files):")
        print(f"  {elapsed:.3f}s total")
        print(f"  {files_per_sec:.1f} files/sec")

        assert (
            files_per_sec > 10
        ), f"Updater throughput {files_per_sec:.1f} files/sec (expected >10)"

        # Verify a sample was actually updated
        sample = (temp_project_dir / "src_000.md").read_text()
        assert "moved/target.txt" in sample


class TestValidationBenchmark:
    """Benchmark tests for validation mode performance."""

    @pytest.mark.performance
    def test_bm_005_validation_mode(self, temp_project_dir):
        """
        BM-005: Validation mode performance

        Measures full workspace validation scan on 100 files.
        Expected: Complete within 10 seconds.
        """
        num_files = 100
        create_benchmark_files(temp_project_dir, num_files)

        validator = LinkValidator(str(temp_project_dir))

        start_time = time.time()
        result = validator.validate()
        elapsed = time.time() - start_time

        print(f"\nValidation mode ({num_files} file sets):")
        print(f"  {elapsed:.3f}s total")
        print(f"  Files scanned: {result.files_scanned}")
        print(f"  Links checked: {result.links_checked}")
        print(f"  Broken links: {len(result.broken_links)}")

        assert elapsed < 10.0, f"Validation took {elapsed:.2f}s (expected <10s)"
        assert result.files_scanned > 0, "Should scan files"
        assert result.links_checked > 0, "Should check links"


class TestCorrelationBenchmark:
    """Benchmark tests for delete+create move correlation timing."""

    @pytest.mark.performance
    def test_bm_006_correlation_timing(self, temp_project_dir):
        """
        BM-006: Delete+create correlation timing

        Measures how fast MoveDetector correlates delete+create pairs.
        20 file moves simulated as sequential buffer_delete + match_created_file.
        Expected: <100ms average per correlation, 100% match rate.
        """
        num_moves = 20
        matched = 0
        timings = []

        # Create files to get real file sizes
        files = []
        for i in range(num_moves):
            src = temp_project_dir / f"file_{i:03d}.txt"
            src.write_text(f"Content {i}")
            dest = temp_project_dir / "dest"
            dest.mkdir(exist_ok=True)
            files.append((src, dest / f"file_{i:03d}.txt"))

        # Use MoveDetector directly (no callbacks needed for timing)
        moves_detected = []

        def on_move(old_path, new_path):
            moves_detected.append((old_path, new_path))

        def on_delete(path):
            pass

        detector = MoveDetector(
            on_move_detected=on_move,
            on_true_delete=on_delete,
            delay=10.0,
        )

        for src, dest in files:
            rel_src = str(src.relative_to(temp_project_dir))
            rel_dest = str(dest.relative_to(temp_project_dir))

            # Simulate the move: delete then create
            detector.buffer_delete(rel_src, str(src))

            # Move the file on disk
            src.rename(dest)

            # Time the correlation
            start = time.time()
            old_path = detector.match_created_file(rel_dest, str(dest))
            correlation_time = time.time() - start

            timings.append(correlation_time)
            if old_path is not None:
                matched += 1

        # Shut down the daemon worker
        detector._stopped = True
        detector._wake.set()

        avg_ms = (sum(timings) / len(timings)) * 1000
        max_ms = max(timings) * 1000
        match_rate = matched / num_moves * 100

        print(f"\nCorrelation timing ({num_moves} moves):")
        print(f"  Average: {avg_ms:.2f}ms")
        print(f"  Max: {max_ms:.2f}ms")
        print(f"  Match rate: {match_rate:.0f}%")

        assert avg_ms < 100, f"Average correlation {avg_ms:.2f}ms (expected <100ms)"
        assert match_rate == 100, f"Match rate {match_rate:.0f}% (expected 100%)"
