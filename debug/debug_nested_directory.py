#!/usr/bin/env python3
"""
Debug the nested directory movement test case.
"""

import sys
import tempfile
from pathlib import Path

# Add the project root to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from watchdog.events import DirMovedEvent

from linkwatcher.service import LinkWatcherService


def debug_nested_directory():
    """Debug the nested directory movement test case."""

    print("🔍 Debugging Nested Directory Movement")
    print("=" * 60)

    # Create temporary directory (exact same as test)
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_project_dir = Path(temp_dir)

        # Setup nested directory structure (exact same as test)
        src_dir = temp_project_dir / "src"
        src_dir.mkdir()
        utils_dir = src_dir / "utils"
        utils_dir.mkdir()

        # Create nested files
        string_utils = utils_dir / "string_utils.py"
        string_utils.write_text("def format_string(): pass")

        file_utils = utils_dir / "file_utils.py"
        file_utils.write_text("def read_file(): pass")

        # Create subdirectory in utils
        common_dir = utils_dir / "common"
        common_dir.mkdir()
        helpers = common_dir / "helpers.py"
        helpers.write_text("def helper_func(): pass")

        # Create files with references
        main_py = temp_project_dir / "main.py"
        main_content = """# Main application
from src.utils.string_utils import format_string
from src.utils.file_utils import read_file
# Also see "src/utils/common/helpers.py"
"""
        main_py.write_text(main_content)

        readme = temp_project_dir / "README.md"
        readme_content = """# Project

Utilities:
- [String Utils](src/utils/string_utils.py)
- [File Utils](src/utils/file_utils.py)
- [Helpers](src/utils/common/helpers.py)
"""
        readme.write_text(readme_content)

        print(f"📄 Initial file contents:")
        print(f"\nmain.py:")
        print(main_py.read_text())
        print(f"\nREADME.md:")
        print(readme.read_text())

        # Initialize service
        service = LinkWatcherService(str(temp_project_dir))
        service._initial_scan()

        # Show what references were found
        print(f"\n📋 References found:")
        all_refs = []
        for target, refs in service.link_db.links.items():
            for ref in refs:
                all_refs.append(
                    (ref.file_path, ref.line_number, ref.link_type, target, ref.link_text)
                )

        all_refs.sort(key=lambda x: (x[0], x[1]))
        for file_path, line_num, link_type, target, link_text in all_refs:
            print(f"   • {file_path}:{line_num} → '{target}' ('{link_text}', {link_type})")

        # Move utils directory to helpers
        print(f"\n🔄 Moving directory...")
        helpers_dir = src_dir / "helpers"
        utils_dir.rename(helpers_dir)

        print(f"   src/utils/ → src/helpers/")

        # Process directory move
        print(f"\n⚡ Processing move event...")
        move_event = DirMovedEvent(str(utils_dir), str(helpers_dir))
        service.handler.on_moved(move_event)

        # Show final file contents
        print(f"\n📄 Final file contents:")
        print(f"\nmain.py:")
        print(main_py.read_text())
        print(f"\nREADME.md:")
        print(readme.read_text())

        # Check specific expectations
        main_updated = main_py.read_text()
        print(f"\n🎯 Checking expectations:")
        print(
            f"   • 'src.helpers.string_utils' in main.py: {'src.helpers.string_utils' in main_updated}"
        )
        print(
            f"   • 'src.helpers.file_utils' in main.py: {'src.helpers.file_utils' in main_updated}"
        )
        print(
            f"   • 'src/helpers/common/helpers.py' in main.py: {'src/helpers/common/helpers.py' in main_updated}"
        )


if __name__ == "__main__":
    debug_nested_directory()
