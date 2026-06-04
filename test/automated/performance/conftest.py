"""
Shared fixtures for the performance test suite.

The two helpers that the per-level performance test files share are exposed here
as factory fixtures. A conftest.py is the only import-safe sharing channel for
this layout: the level dirs (level1-component, level2-operation, …) contain
hyphens, so they are invalid Python package names and cannot be imported across
under pytest's --import-mode=importlib (see pyproject.toml). Fixtures are injected
by pytest regardless of package-ability, so they work where a plain helper module
would not.
"""

import shutil
import tempfile
from pathlib import Path
from typing import List

import pytest
from watchdog.events import FileMovedEvent

from linkwatcher.service import LinkWatcherService


@pytest.fixture
def benchmark_files():
    """Factory: create mixed-format test files for benchmarking.

    Returns a callable ``(base_dir, num_files=100) -> List[Path]`` that writes
    ``num_files`` sets of .md/.txt/.json/.yaml files (4 files per set) with
    cross-references, and returns the created paths.
    """

    def _create(base_dir: Path, num_files: int = 100) -> List[Path]:
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

    return _create


@pytest.fixture
def warmup_service():
    """Factory: prime caches/JIT/import-warmup outside the timed window.

    Returns a callable ``(num_files=5, num_moves=0, dir_move=False) -> None`` that
    instantiates a separate service + initial scan against an external tempdir so
    the warmup files are NOT included in the test's actual scan. Optionally
    exercises move and directory-move event paths to prime the handler hot paths.
    (TD246 / audit Criterion 1.)
    """

    def _warmup(num_files: int = 5, num_moves: int = 0, dir_move: bool = False) -> None:
        with tempfile.TemporaryDirectory() as warmup_dir_str:
            warmup_dir = Path(warmup_dir_str)
            warmup_target = warmup_dir / "warmup_target.txt"
            warmup_target.write_text("Warmup")
            for i in range(num_files):
                wsrc = warmup_dir / f"warmup_src_{i}.md"
                wsrc.write_text(f"# Warmup {i}\n[w](warmup_target.txt)\n")
            svc = LinkWatcherService(str(warmup_dir))
            svc._initial_scan()

            for i in range(num_moves):
                old_path = warmup_dir / f"warmup_src_{i}.md"
                new_path = warmup_dir / f"warmup_moved_{i}.md"
                old_path.rename(new_path)
                svc.handler.on_moved(FileMovedEvent(str(old_path), str(new_path)))

            if dir_move:
                warmup_subdir = warmup_dir / "warmup_subdir"
                warmup_subdir.mkdir()
                (warmup_subdir / "f.md").write_text("# Sub\n[w](../warmup_target.txt)\n")
                svc._initial_scan()
                warmup_moved = warmup_dir / "warmup_subdir_moved"
                shutil.move(str(warmup_subdir), str(warmup_moved))
                ev = FileMovedEvent(str(warmup_subdir), str(warmup_moved))
                ev.is_directory = True
                svc.handler.on_moved(ev)

    return _warmup
