"""
Performance benchmarking script for LinkWatcher.

This script provides performance testing and benchmarking
capabilities for the LinkWatcher system.
"""

import argparse
import shutil
import tempfile
import time
from pathlib import Path
from typing import Dict, List

from linkwatcher import LinkDatabase, LinkParser, LinkWatcherService
from linkwatcher.config import DEFAULT_CONFIG


class LinkWatcherBenchmark:
    """Benchmark suite for LinkWatcher performance."""

    def __init__(self):
        self.results = {}

    def create_test_files(self, base_dir: Path, num_files: int = 100) -> List[Path]:
        """Create test files for benchmarking."""
        files = []

        for i in range(num_files):
            # Create markdown files with various link patterns
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

            # Create target files
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

    def benchmark_parsing(self, files: List[Path]) -> Dict[str, float]:
        """Benchmark file parsing performance."""
        parser = LinkParser()

        # Warm up
        for file in files[:10]:
            if file.suffix == ".md":
                parser.parse_file(str(file))

        # Benchmark parsing
        start_time = time.time()
        total_references = 0

        for file in files:
            if file.suffix in {".md", ".txt", ".json", ".yaml"}:
                references = parser.parse_file(str(file))
                total_references += len(references)

        end_time = time.time()

        return {
            "total_time": end_time - start_time,
            "files_parsed": len(
                [f for f in files if f.suffix in {".md", ".txt", ".json", ".yaml"}]
            ),
            "total_references": total_references,
            "files_per_second": len(files) / (end_time - start_time),
            "references_per_second": total_references / (end_time - start_time),
        }

    def benchmark_database_operations(self, num_operations: int = 1000) -> Dict[str, float]:
        """Benchmark database operations."""
        db = LinkDatabase()

        # Create test references
        from linkwatcher.models import LinkReference

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

        # Benchmark adding references
        start_time = time.time()
        for ref in references:
            db.add_link(ref)
        add_time = time.time() - start_time

        # Benchmark lookups
        start_time = time.time()
        for i in range(0, num_operations, 10):  # Sample every 10th
            db.get_references_to_file(f"file_{i}.txt")
        lookup_time = time.time() - start_time

        # Benchmark updates
        start_time = time.time()
        for i in range(0, num_operations, 20):  # Sample every 20th
            db.update_target_path(f"file_{i}.txt", f"new_file_{i}.txt")
        update_time = time.time() - start_time

        return {
            "add_time": add_time,
            "lookup_time": lookup_time,
            "update_time": update_time,
            "adds_per_second": num_operations / add_time,
            "lookups_per_second": (num_operations // 10) / lookup_time,
            "updates_per_second": (num_operations // 20) / update_time,
        }

    def benchmark_initial_scan(self, project_dir: Path) -> Dict[str, float]:
        """Benchmark initial project scan."""
        service = LinkWatcherService(str(project_dir))

        start_time = time.time()
        service._initial_scan()
        end_time = time.time()

        stats = service.link_db.get_stats()

        return {
            "scan_time": end_time - start_time,
            "files_scanned": stats["files_with_links"],
            "references_found": stats["total_references"],
            "files_per_second": stats["files_with_links"] / (end_time - start_time),
        }

    def run_full_benchmark(self, num_files: int = 100) -> Dict[str, Dict]:
        """Run complete benchmark suite."""
        print(f"🚀 Starting LinkWatcher benchmark with {num_files} files...")

        # Create temporary directory
        temp_dir = Path(tempfile.mkdtemp())
        try:
            # Create test files
            print("📁 Creating test files...")
            files = self.create_test_files(temp_dir, num_files)
            print(f"   Created {len(files)} test files")

            # Benchmark parsing
            print("📊 Benchmarking parsing...")
            parsing_results = self.benchmark_parsing(files)
            self.results["parsing"] = parsing_results

            # Benchmark database operations
            print("🗄️ Benchmarking database operations...")
            db_results = self.benchmark_database_operations(num_files * 2)
            self.results["database"] = db_results

            # Benchmark initial scan
            print("🔍 Benchmarking initial scan...")
            scan_results = self.benchmark_initial_scan(temp_dir)
            self.results["initial_scan"] = scan_results

            return self.results

        finally:
            # Clean up
            shutil.rmtree(temp_dir, ignore_errors=True)

    def print_results(self):
        """Print benchmark results in a formatted way."""
        print("\n" + "=" * 60)
        print("🏆 LINKWATCHER BENCHMARK RESULTS")
        print("=" * 60)

        if "parsing" in self.results:
            r = self.results["parsing"]
            print(f"\n📊 PARSING PERFORMANCE:")
            print(f"   Files parsed: {r['files_parsed']}")
            print(f"   Total references: {r['total_references']}")
            print(f"   Total time: {r['total_time']:.2f}s")
            print(f"   Files/second: {r['files_per_second']:.1f}")
            print(f"   References/second: {r['references_per_second']:.1f}")

        if "database" in self.results:
            r = self.results["database"]
            print(f"\n🗄️ DATABASE PERFORMANCE:")
            print(f"   Adds/second: {r['adds_per_second']:.1f}")
            print(f"   Lookups/second: {r['lookups_per_second']:.1f}")
            print(f"   Updates/second: {r['updates_per_second']:.1f}")

        if "initial_scan" in self.results:
            r = self.results["initial_scan"]
            print(f"\n🔍 INITIAL SCAN PERFORMANCE:")
            print(f"   Files scanned: {r['files_scanned']}")
            print(f"   References found: {r['references_found']}")
            print(f"   Scan time: {r['scan_time']:.2f}s")
            print(f"   Files/second: {r['files_per_second']:.1f}")

        print("\n" + "=" * 60)


def main():
    """Main benchmark entry point."""
    parser = argparse.ArgumentParser(description="LinkWatcher Performance Benchmark")
    parser.add_argument(
        "--files", type=int, default=100, help="Number of test files to create (default: 100)"
    )
    parser.add_argument("--output", type=str, help="Output file for results (optional)")

    args = parser.parse_args()

    # Run benchmark
    benchmark = LinkWatcherBenchmark()
    results = benchmark.run_full_benchmark(args.files)

    # Print results
    benchmark.print_results()

    # Save results if requested
    if args.output:
        import json

        with open(args.output, "w") as f:
            json.dump(results, f, indent=2)
        print(f"\n💾 Results saved to {args.output}")


if __name__ == "__main__":
    main()
