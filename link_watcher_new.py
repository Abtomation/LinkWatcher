#!/usr/bin/env python3
"""
LinkWatcher - Real-time Link Maintenance System

Main entry point for the restructured LinkWatcher system.
This replaces the monolithic link_watcher.py with a modular architecture.

Usage:
    python link_watcher_new.py [options]

Options:
    --no-initial-scan    Skip initial scan of files
    --project-root DIR   Project root directory (default: current directory)
    --config FILE        Configuration file path
    --dry-run           Enable dry run mode (no file modifications)
    --quiet             Suppress non-error output
"""

import argparse
import sys
from pathlib import Path

# Add the current directory to Python path for imports
sys.path.insert(0, str(Path(__file__).parent))

try:
    from colorama import Fore, Style, init
    from git import InvalidGitRepositoryError, Repo

    from linkwatcher import LinkWatcherService
    from linkwatcher.config import DEFAULT_CONFIG, LinkWatcherConfig
except ImportError as e:
    print(f"Missing required dependency: {e}")
    print("Please install dependencies with: pip install -r requirements.txt")
    sys.exit(1)

# Initialize colorama for cross-platform colored output
init(autoreset=True)


def load_config(config_path: str = None, args=None) -> LinkWatcherConfig:
    """Load configuration from file, environment, and command line arguments."""

    # Start with default configuration
    config = DEFAULT_CONFIG

    # Load from file if specified
    if config_path and Path(config_path).exists():
        try:
            file_config = LinkWatcherConfig.from_file(config_path)
            config = config.merge(file_config)
            print(f"{Fore.GREEN}✓ Loaded configuration from {config_path}")
        except Exception as e:
            print(f"{Fore.YELLOW}⚠️ Warning: Could not load config file {config_path}: {e}")

    # Override with environment variables
    try:
        env_config = LinkWatcherConfig.from_env()
        config = config.merge(env_config)
    except Exception as e:
        print(f"{Fore.YELLOW}⚠️ Warning: Could not load environment config: {e}")

    # Override with command line arguments
    if args:
        if args.dry_run:
            config.dry_run_mode = True
        if args.quiet:
            config.log_level = "ERROR"
            config.colored_output = False
            config.show_statistics = False
        if hasattr(args, "no_initial_scan") and args.no_initial_scan:
            config.initial_scan_enabled = False

    return config


def validate_project_root(project_root: str) -> Path:
    """Validate and return the project root path."""
    root_path = Path(project_root).resolve()

    if not root_path.exists():
        print(f"{Fore.RED}✗ Error: Project root does not exist: {root_path}")
        sys.exit(1)

    if not root_path.is_dir():
        print(f"{Fore.RED}✗ Error: Project root is not a directory: {root_path}")
        sys.exit(1)

    return root_path


def check_git_repository(project_root: Path):
    """Check if we're in a git repository and show warning if not."""
    try:
        repo = Repo(str(project_root))
        if not repo.bare:
            print(f"{Fore.GREEN}✓ Git repository detected")
        else:
            print(f"{Fore.YELLOW}⚠️ Warning: Bare git repository detected")
    except InvalidGitRepositoryError:
        print(
            f"{Fore.YELLOW}⚠️ Warning: Not in a git repository. Link maintenance will still work."
        )


def print_startup_info(config: LinkWatcherConfig, project_root: Path):
    """Print startup information."""
    if not config.colored_output:
        return

    print(f"\n{Fore.CYAN}🚀 LinkWatcher v2.0 - Real-time Link Maintenance System")
    print(f"{Fore.CYAN}{'='*60}")
    print(f"{Fore.CYAN}📁 Project root: {project_root}")
    print(f"{Fore.CYAN}🔧 Configuration:")
    print(f"   • Monitored extensions: {', '.join(sorted(config.monitored_extensions))}")
    print(f"   • Ignored directories: {', '.join(sorted(config.ignored_directories))}")
    print(f"   • Initial scan: {'enabled' if config.initial_scan_enabled else 'disabled'}")
    print(f"   • Dry run mode: {'enabled' if config.dry_run_mode else 'disabled'}")
    print(f"   • Backup creation: {'enabled' if config.create_backups else 'disabled'}")
    print(f"{Fore.CYAN}{'='*60}\n")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="LinkWatcher - Real-time Link Maintenance System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python link_watcher_new.py                    # Start with default settings
  python link_watcher_new.py --no-initial-scan # Skip initial scan
  python link_watcher_new.py --dry-run         # Preview mode only
  python link_watcher_new.py --config my.yaml  # Use custom config
  python link_watcher_new.py --quiet           # Minimal output
        """,
    )

    parser.add_argument(
        "--no-initial-scan",
        action="store_true",
        help="Skip initial scan of files for faster startup",
    )
    parser.add_argument(
        "--project-root", default=".", help="Project root directory (default: current directory)"
    )
    parser.add_argument("--config", help="Configuration file path (YAML or JSON)")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Enable dry run mode (preview changes without modifying files)",
    )
    parser.add_argument("--quiet", action="store_true", help="Suppress non-error output")
    parser.add_argument("--version", action="version", version="LinkWatcher 2.0.0")

    args = parser.parse_args()

    try:
        # Validate project root
        project_root = validate_project_root(args.project_root)

        # Load configuration
        config = load_config(args.config, args)

        # Validate configuration
        config_issues = config.validate()
        if config_issues:
            print(f"{Fore.RED}✗ Configuration issues:")
            for issue in config_issues:
                print(f"   • {issue}")
            sys.exit(1)

        # Check git repository
        if not args.quiet:
            check_git_repository(project_root)

        # Print startup information
        if not args.quiet:
            print_startup_info(config, project_root)

        # Create and configure service
        service = LinkWatcherService(str(project_root))

        # Apply configuration
        service.set_dry_run(config.dry_run_mode)
        service.updater.set_backup_enabled(config.create_backups)
        service.handler.monitored_extensions = config.monitored_extensions
        service.handler.ignored_dirs = config.ignored_directories

        # Add custom parsers if configured
        for extension, parser_class in config.custom_parsers.items():
            try:
                # This would require dynamic loading - simplified for now
                print(f"{Fore.YELLOW}⚠️ Custom parser for {extension} not yet implemented")
            except Exception as e:
                print(f"{Fore.YELLOW}⚠️ Warning: Could not load custom parser for {extension}: {e}")

        # Start the service
        service.start(initial_scan=config.initial_scan_enabled)

    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}👋 LinkWatcher stopped by user")
        sys.exit(0)
    except Exception as e:
        print(f"{Fore.RED}✗ Fatal error: {e}")
        if not args.quiet:
            import traceback

            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
