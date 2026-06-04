"""
Component Benchmark Tests for LinkWatcher Performance (Level 1)

Converted from scripts/benchmark.py into pytest-integrated performance tests.
Component-level (Level 1) benchmarks isolate a single subsystem: the parser, the
link database, and the updater.

Test Cases:
- BM-001: File parsing throughput
- BM-002: Database add throughput
- BM-007: Database lookup throughput
- BM-008: Database update throughput
- BM-004: Updater throughput

Split from test_benchmark.py (TD254): operation-level benchmarks (BM-003/005/006)
live in level2-operation/test_operation_benchmarks.py. Shared helpers are factory
fixtures in performance/conftest.py.

Timing uses time.perf_counter() for monotonic, sub-microsecond resolution.
"""

import time

import pytest
from watchdog.events import FileMovedEvent

from linkwatcher import LinkDatabase, LinkParser, LinkWatcherService
from linkwatcher.models import LinkReference

pytestmark = [
    pytest.mark.feature("cross-cutting"),
    pytest.mark.priority("Extended"),
    pytest.mark.cross_cutting(["0.1.1", "0.1.2", "2.1.1"]),
    pytest.mark.test_type("performance"),
]


class TestParsingBenchmark:
    """Benchmark tests for file parsing throughput."""

    @pytest.mark.performance
    def test_bm_001_parsing_throughput(self, temp_project_dir, benchmark_files):
        """
        BM-001: File parsing throughput

        Measures parsing speed across 100 files with mixed formats.
        Expected: >50 files/second parsing rate.
        """
        num_files = 100
        files = benchmark_files(temp_project_dir, num_files)
        parser = LinkParser()

        # Warm up
        for file in files[:10]:
            if file.suffix == ".md":
                parser.parse_file(str(file))

        # Benchmark
        parseable_extensions = {".md", ".txt", ".json", ".yaml"}
        start_time = time.perf_counter()
        total_references = 0

        for file in files:
            if file.suffix in parseable_extensions:
                references = parser.parse_file(str(file))
                total_references += len(references)

        elapsed = time.perf_counter() - start_time
        files_parsed = len([f for f in files if f.suffix in parseable_extensions])
        files_per_second = files_parsed / elapsed

        print(f"\nParsing: {files_parsed} files in {elapsed:.2f}s")
        print(f"  {files_per_second:.1f} files/second")
        print(f"  {total_references} references found")
        print(f"  {total_references / elapsed:.1f} references/second")

        assert (
            files_per_second > 50
        ), f"Parsing throughput {files_per_second:.1f} files/sec (expected >50)"
        assert total_references > 0, "Should find at least some references"


class TestDatabaseBenchmark:
    """Benchmark tests for database operations."""

    @pytest.mark.performance
    def test_bm_002_database_operations(self):
        """
        BM-002 / BM-007 / BM-008: Database add / lookup / update throughput

        Adds are timed against a 10000-ref population so the timing window exceeds
        the 100ms noise floor (audit TE-TAR-066 Criterion 1, option a). Lookups and
        updates are timed against a separate 1000-ref database — `get_references_to_file`
        scales with database size, so a smaller, production-realistic db keeps lookup
        timing meaningful and prevents a 10x population from dominating the measurement.
        """
        # Build small db for lookup/update operations (production-realistic db size)
        small_db = LinkDatabase()
        small_num = 1000
        small_refs = []
        for i in range(small_num):
            ref = LinkReference(
                file_path=f"doc_{i}.md",
                line_number=1,
                column_start=0,
                column_end=10,
                link_text=f"file_{i}.txt",
                link_target=f"file_{i}.txt",
                link_type="markdown",
            )
            small_refs.append(ref)
            small_db.add_link(ref)

        # Build references for adds benchmark (larger set for timing precision)
        add_num = 10000
        add_refs = []
        for i in range(add_num):
            ref = LinkReference(
                file_path=f"add_doc_{i}.md",
                line_number=1,
                column_start=0,
                column_end=10,
                link_text=f"add_file_{i}.txt",
                link_target=f"add_file_{i}.txt",
                link_type="markdown",
            )
            add_refs.append(ref)
        add_db = LinkDatabase()

        # Warmup — exercise add/lookup/update paths on a separate db instance
        # to avoid polluting the timed dbs (audit Criterion 1).
        warmup_db = LinkDatabase()
        for ref in small_refs[:100]:
            warmup_db.add_link(ref)
        for i in range(0, 100, 10):
            warmup_db.get_references_to_file(f"file_{i}.txt")
        for i in range(0, 100, 10):
            warmup_db.update_target_path(f"file_{i}.txt", f"warmup_{i}.txt")

        # Benchmark adds (10000 ops on fresh empty db — ~150ms+ window)
        start_time = time.perf_counter()
        for ref in add_refs:
            add_db.add_link(ref)
        add_time = time.perf_counter() - start_time

        # Benchmark lookups (100 ops on 1000-entry db)
        lookup_count = 0
        start_time = time.perf_counter()
        for i in range(0, small_num, 10):
            small_db.get_references_to_file(f"file_{i}.txt")
            lookup_count += 1
        lookup_time = time.perf_counter() - start_time

        # Benchmark updates (50 ops on 1000-entry db)
        update_count = 0
        start_time = time.perf_counter()
        for i in range(0, small_num, 20):
            small_db.update_target_path(f"file_{i}.txt", f"new_file_{i}.txt")
            update_count += 1
        update_time = time.perf_counter() - start_time

        adds_per_sec = add_num / max(add_time, 1e-9)
        lookups_per_sec = lookup_count / max(lookup_time, 1e-9)
        updates_per_sec = update_count / max(update_time, 1e-9)

        print("\nDatabase operations:")
        print(f"  Adds:    {adds_per_sec:.0f}/s ({add_time:.3f}s, {add_num} ops on empty db)")
        print(
            f"  Lookups: {lookups_per_sec:.0f}/s ({lookup_time:.3f}s, {lookup_count} ops on {small_num}-entry db)"
        )
        print(
            f"  Updates: {updates_per_sec:.0f}/s ({update_time:.3f}s, {update_count} ops on {small_num}-entry db)"
        )

        # Tolerances set during TD215 rework; PF-TSK-085 will recalibrate after formal
        # baselines are captured. See performance-test-tracking.md for current values.
        assert add_time < 3.0, f"Adding {add_num} refs took {add_time:.2f}s (expected <3.0s)"
        assert lookup_time < 1.8, f"Lookups took {lookup_time:.2f}s (expected <1.8s)"
        assert update_time < 0.02, f"Updates took {update_time:.3f}s (expected <0.02s)"


class TestUpdaterBenchmark:
    """Benchmark tests for file update throughput."""

    @pytest.mark.performance
    def test_bm_004_updater_throughput(self, temp_project_dir, warmup_service):
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

        # Warmup: prime caches/JIT before the timed move (audit Criterion 1) against
        # an external tempdir, so warmup files are not included in the main service scan.
        warmup_service(num_files=5)

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

        start_time = time.perf_counter()
        move_event = FileMovedEvent(str(target_file), str(new_target))
        service.handler.on_moved(move_event)
        elapsed = time.perf_counter() - start_time

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
