"""
Resource Bound Tests for LinkWatcher Performance (Level 4)

Resource-level (Level 4) tests assert bounds on process resource consumption —
memory footprint and CPU usage — rather than wall-clock timing.

Test Cases:
- PH-007: Memory usage monitoring (test_memory_usage_monitoring)
- PH-008: CPU usage monitoring (test_cpu_usage_monitoring)

Split from test_large_projects.py (TD254): scale-level tests (PH-001..006) live in
level3-scale/test_large_projects.py. The shared warmup helper is the `warmup_service`
factory fixture in performance/conftest.py.
"""

import pytest
from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService

pytestmark = [
    pytest.mark.feature("4.1.1"),
    pytest.mark.priority("Extended"),
    pytest.mark.cross_cutting(["0.1.1", "1.1.1", "2.2.1"]),
    pytest.mark.test_type("performance"),
    pytest.mark.performance,  # selectable via `-m performance` (framework perf category / guide baseline cmd)
    pytest.mark.slow,  # both tests run ~21-29s (>10s); Level-4 guide requires slow marker
]


class TestPerformanceMetrics:
    """Tests for performance monitoring and metrics."""

    def test_memory_usage_monitoring(self, temp_project_dir, warmup_service):
        """Monitor memory usage during operations."""
        import os

        psutil = pytest.importorskip("psutil")

        # Warmup BEFORE measuring initial_memory so first-time module/code allocations
        # are not counted in `memory_increase` (TD246 / audit Criterion 1).
        warmup_service(num_files=5)

        # Get current process
        process = psutil.Process(os.getpid())

        # Measure initial memory
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB

        # Create moderate-sized project
        num_files = 200
        for i in range(num_files):
            file_path = temp_project_dir / f"file_{i:03d}.md"
            content = f"# File {i}\n\n"

            # Add references
            for j in range(min(5, num_files)):
                if j != i:
                    content += f"- [File {j}](file_{j:03d}.md)\n"

            file_path.write_text(content)

        # Initialize service and scan
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Measure memory after scan
        after_scan_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = after_scan_memory - initial_memory

        print(f"Memory usage: {initial_memory:.1f}MB -> {after_scan_memory:.1f}MB")
        print(f"Memory increase: {memory_increase:.1f}MB for {num_files} files")

        # Memory usage should be reasonable
        assert memory_increase < 100  # Should not use excessive memory

        # Perform some operations and check for memory leaks
        for i in range(10):
            # Move a file
            old_file = temp_project_dir / f"file_{i:03d}.md"
            new_file = temp_project_dir / f"moved_{i:03d}.md"

            old_file.rename(new_file)
            move_event = FileMovedEvent(str(old_file), str(new_file))
            service.handler.on_moved(move_event)

        # Check memory after operations
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        operation_memory_change = final_memory - after_scan_memory

        print(f"Memory after operations: {final_memory:.1f}MB")
        print(f"Memory change during operations: {operation_memory_change:.1f}MB")

        # Should not have significant memory leaks
        assert abs(operation_memory_change) < 20  # Small changes are acceptable

    def test_cpu_usage_monitoring(self, temp_project_dir, warmup_service):
        """Monitor CPU usage during intensive operations."""
        import os
        import threading

        psutil = pytest.importorskip("psutil")

        # Warmup BEFORE starting cpu_monitor so first-time CPU costs (import init,
        # module loading, JIT) are not counted in the sampling window
        # (TD246 / audit Criterion 1).
        warmup_service(num_files=5, num_moves=1)

        # CPU monitoring function
        cpu_samples = []
        monitoring = True

        # Measure THIS process's CPU only — not host-wide — so the assertion is
        # decoupled from unrelated background load (TD247 / audit Criterion 1).
        process = psutil.Process(os.getpid())

        def monitor_cpu():
            while monitoring:
                cpu_samples.append(process.cpu_percent(interval=0.1))

        # Start CPU monitoring
        monitor_thread = threading.Thread(target=monitor_cpu)
        monitor_thread.start()

        try:
            # Create project and perform intensive operations
            num_files = 100

            # Create files
            for i in range(num_files):
                file_path = temp_project_dir / f"file_{i:03d}.md"
                content = f"# File {i}\n\n"

                # Add many references
                for j in range(min(10, num_files)):
                    if j != i:
                        content += f"- [File {j}](file_{j:03d}.md)\n"
                        content += f'- See "file_{j:03d}.md" for details\n'

                file_path.write_text(content)

            # Initialize and scan
            service = LinkWatcherService(str(temp_project_dir))
            service._initial_scan()

            # Perform multiple file operations
            for i in range(20):
                old_file = temp_project_dir / f"file_{i:03d}.md"
                new_file = temp_project_dir / f"moved_{i:03d}.md"

                old_file.rename(new_file)
                move_event = FileMovedEvent(str(old_file), str(new_file))
                service.handler.on_moved(move_event)

        finally:
            # Stop monitoring
            monitoring = False
            monitor_thread.join()

        # Analyze CPU usage
        if cpu_samples:
            avg_cpu = sum(cpu_samples) / len(cpu_samples)
            max_cpu = max(cpu_samples)

            print(f"CPU usage - Average: {avg_cpu:.1f}%, Peak: {max_cpu:.1f}%")

            # process.cpu_percent reports cores * 100% on multi-core hosts; normalize
            # to per-core average so the threshold's [0, 100] semantics survive the
            # host-wide -> process-CPU switch (TD247 + TD249's PH-008 sub-item).
            cpu_count = psutil.cpu_count() or 1
            assert (avg_cpu / cpu_count) < 80  # Process should not pin every core on average
            # Peak assertion removed (TD249): peaks of interval samplers are
            # unstable and false-positive prone; print above retains diagnostic value.
