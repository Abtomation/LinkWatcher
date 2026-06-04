"""
Operation Benchmark Tests for LinkWatcher Performance (Level 2)

Converted from scripts/benchmark.py into pytest-integrated performance tests.
Operation-level (Level 2) benchmarks exercise an end-to-end operation that spans
multiple subsystems: a full initial scan, a full validation pass, and delete+create
move correlation.

Test Cases:
- BM-003: Initial scan performance
- BM-005: Validation mode performance
- BM-006: Delete+create correlation timing

Split from test_benchmark.py (TD254): component-level benchmarks (BM-001/002/004/007/008)
live in level1-component/test_component_benchmarks.py. Shared helpers are factory
fixtures in performance/conftest.py.

Timing uses time.perf_counter() for monotonic, sub-microsecond resolution.
"""

import time
from pathlib import Path

import pytest

from linkwatcher import LinkWatcherService
from linkwatcher.move_detector import MoveDetector
from linkwatcher.validator import LinkValidator

pytestmark = [
    pytest.mark.feature("cross-cutting"),
    pytest.mark.priority("Extended"),
    pytest.mark.cross_cutting(["0.1.1", "0.1.2", "2.1.1"]),
    pytest.mark.test_type("performance"),
]


class TestInitialScanBenchmark:
    """Benchmark tests for initial project scan."""

    @pytest.mark.performance
    def test_bm_003_initial_scan(self, temp_project_dir, benchmark_files, warmup_service):
        """
        BM-003: Initial scan performance

        Measures full project scan time with 100 file sets (400 files).
        Expected: Complete within 10 seconds.
        """
        num_files = 100
        benchmark_files(temp_project_dir, num_files)

        # Warmup: prime import/JIT/scan hot path on a separate external tempdir
        # before the timed scan (audit Criterion 1). The warmup dir is outside
        # temp_project_dir, so its files are not included in the timed scan.
        warmup_service(num_files=5)

        service = LinkWatcherService(str(temp_project_dir))

        start_time = time.perf_counter()
        service._initial_scan()
        elapsed = time.perf_counter() - start_time

        stats = service.link_db.get_stats()

        print(f"\nInitial scan: {elapsed:.2f}s")
        print(f"  Files with links: {stats['files_with_links']}")
        print(f"  Total references: {stats['total_references']}")
        print(f"  Files/second: {stats['files_with_links'] / elapsed:.1f}")

        assert elapsed < 10.0, f"Initial scan took {elapsed:.2f}s (expected <10s)"
        assert stats["files_with_links"] > 0, "Should find files with links"
        assert stats["total_references"] > 0, "Should find references"


class TestValidationBenchmark:
    """Benchmark tests for validation mode performance."""

    @pytest.mark.performance
    def test_bm_005_validation_mode(self, temp_project_dir, benchmark_files):
        """
        BM-005: Validation mode performance

        Measures full workspace validation scan on 100 file sets (300 files
        validated — .md/.yaml/.json).
        Expected: Complete within 5 seconds.
        """
        import tempfile

        num_files = 100
        benchmark_files(temp_project_dir, num_files)

        # Warmup: run validation on a small separate tempdir to prime caches/JIT
        # before the timed pass (audit Criterion 1). Warmup dir is OUTSIDE
        # temp_project_dir so it's not included in the main validator's scan.
        with tempfile.TemporaryDirectory() as warmup_dir_str:
            warmup_dir = Path(warmup_dir_str)
            benchmark_files(warmup_dir, 5)
            warmup_validator = LinkValidator(str(warmup_dir))
            warmup_validator.validate()

        validator = LinkValidator(str(temp_project_dir))

        start_time = time.perf_counter()
        result = validator.validate()
        elapsed = time.perf_counter() - start_time

        print(f"\nValidation mode ({num_files} file sets):")
        print(f"  {elapsed:.3f}s total")
        print(f"  Files scanned: {result.files_scanned}")
        print(f"  Links checked: {result.links_checked}")
        print(f"  Broken links: {len(result.broken_links)}")

        assert elapsed < 5.0, f"Validation took {elapsed:.2f}s (expected <5s)"
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
        """
        num_moves = 20
        matched = 0
        timings = []

        # Create files to get real file sizes (production set + warmup set)
        files = []
        for i in range(num_moves):
            src = temp_project_dir / f"file_{i:03d}.txt"
            src.write_text(f"Content {i}")
            dest = temp_project_dir / "dest"
            dest.mkdir(exist_ok=True)
            files.append((src, dest / f"file_{i:03d}.txt"))

        warmup_files = []
        warmup_dest = temp_project_dir / "warmup_dest"
        warmup_dest.mkdir(exist_ok=True)
        for i in range(2):
            src = temp_project_dir / f"warmup_{i:03d}.txt"
            src.write_text(f"Warmup {i}")
            warmup_files.append((src, warmup_dest / f"warmup_{i:03d}.txt"))

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

        # Warmup: 2 throwaway delete+create cycles to prime caches/JIT
        for src, dest in warmup_files:
            rel_src = str(src.relative_to(temp_project_dir))
            rel_dest = str(dest.relative_to(temp_project_dir))
            detector.buffer_delete(rel_src, str(src))
            src.rename(dest)
            detector.match_created_file(rel_dest, str(dest))

        for src, dest in files:
            rel_src = str(src.relative_to(temp_project_dir))
            rel_dest = str(dest.relative_to(temp_project_dir))

            # Simulate the move: delete then create
            detector.buffer_delete(rel_src, str(src))

            # Move the file on disk
            src.rename(dest)

            # Time the correlation
            start = time.perf_counter()
            old_path = detector.match_created_file(rel_dest, str(dest))
            correlation_time = time.perf_counter() - start

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

        # Tolerance set during TD215 rework, tightened during re-audit; see
        # performance-test-tracking.md (single source of truth for tolerance basis).
        assert avg_ms < 5, f"Average correlation {avg_ms:.2f}ms (expected <5ms)"
        assert match_rate == 100, f"Match rate {match_rate:.0f}% (expected 100%)"
