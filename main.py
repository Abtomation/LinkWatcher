#!/usr/bin/env python3
"""
LinkWatcher - Real-time Link Maintenance System

Main entry point for the restructured LinkWatcher system.
This replaces the monolithic link_watcher.py with a modular architecture.

Usage:
    python main.py [options]

Options:
    --no-initial-scan    Skip initial scan of files
    --project-root DIR   Project root directory (default: current directory)
    --config FILE        Configuration file path
    --dry-run           Enable dry run mode (no file modifications)
    --quiet             Suppress non-error output
"""

import argparse
import os
import sys
from pathlib import Path

# Add the current directory to Python path for imports
sys.path.insert(0, str(Path(__file__).parent))

try:
    from colorama import Fore, Style, init
    from git import InvalidGitRepositoryError, Repo

    from linkwatcher import LinkWatcherService
    from linkwatcher.config import DEFAULT_CONFIG, LinkWatcherConfig
    from linkwatcher.logging import LogLevel, get_logger, setup_logging
except ImportError as e:
    print(f"Missing required dependency: {e}")
    print("Please install dependencies with: pip install -r requirements.txt")
    sys.exit(1)

# Initialize colorama for cross-platform colored output
init(autoreset=True)


def load_config(config_path: str = None, args=None) -> LinkWatcherConfig:
    """Load configuration from file, environment, and command line arguments."""
    logger = get_logger()

    # Start with default configuration
    config = DEFAULT_CONFIG

    # Load from file if specified
    if config_path and Path(config_path).exists():
        try:
            file_config = LinkWatcherConfig.from_file(config_path)
            config = config.merge(file_config)
            logger.info("config_loaded", config_file=config_path)
        except Exception as e:
            logger.warning("config_load_failed", config_file=config_path, error=str(e))

    # Override with environment variables
    try:
        env_config = LinkWatcherConfig.from_env()
        config = config.merge(env_config)
        logger.debug("environment_config_loaded")
    except Exception as e:
        logger.warning("environment_config_failed", error=str(e))

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


LOCK_FILE_NAME = ".linkwatcher.lock"


def _is_pid_running(pid: int) -> bool:
    """Check if a process with the given PID is still running."""
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def acquire_lock(project_root: Path) -> Path:
    """Acquire a lock file to prevent duplicate instances.

    Returns the lock file path on success.
    Raises SystemExit if another instance is already running.
    """
    lock_file = project_root / LOCK_FILE_NAME

    if lock_file.exists():
        try:
            content = lock_file.read_text().strip()
            existing_pid = int(content)
            if _is_pid_running(existing_pid):
                print(f"{Fore.RED}✗ LinkWatcher is already running (PID: {existing_pid})")
                print(f"{Fore.YELLOW}  Lock file: {lock_file}")
                sys.exit(1)
            else:
                print(
                    f"{Fore.YELLOW}⚠️ Overriding stale lock file (PID {existing_pid} is no longer running)"
                )
        except (ValueError, OSError):
            print(f"{Fore.YELLOW}⚠️ Overriding invalid lock file")

    try:
        lock_file.write_text(str(os.getpid()))
    except OSError as e:
        print(
            f"{Fore.YELLOW}⚠️ Could not create lock file ({e}). "
            f"Duplicate instance protection disabled."
        )
        return None

    return lock_file


def release_lock(lock_file: Path):
    """Release the lock file."""
    if lock_file is not None and lock_file.exists():
        try:
            lock_file.unlink()
        except OSError:
            pass


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="LinkWatcher - Real-time Link Maintenance System",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python main.py                    # Start with default settings
  python main.py --no-initial-scan # Skip initial scan
  python main.py --dry-run         # Preview mode only
  python main.py --config my.yaml  # Use custom config
  python main.py --quiet           # Minimal output
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
    parser.add_argument("--log-file", help="Log to file (in addition to console)")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")
    parser.add_argument("--version", action="version", version="LinkWatcher 2.0.0")

    args = parser.parse_args()

    try:
        # Setup logging first
        log_level = LogLevel.DEBUG if args.debug else LogLevel.INFO
        if args.quiet:
            log_level = LogLevel.ERROR

        logger = setup_logging(
            level=log_level,
            log_file=args.log_file,
            colored_output=not args.quiet,
            show_icons=not args.quiet,
        )

        # Validate project root
        project_root = validate_project_root(args.project_root)

        # Load configuration
        config = load_config(args.config, args)

        # Update logging configuration from config
        if config.log_file and not args.log_file:
            logger = setup_logging(
                level=LogLevel(config.log_level),
                log_file=config.log_file,
                colored_output=config.colored_output and not args.quiet,
                show_icons=config.show_log_icons and not args.quiet,
                json_logs=config.json_logs,
                max_file_size=config.log_file_max_size_mb * 1024 * 1024,
                backup_count=config.log_file_backup_count,
            )

        # Validate configuration
        config_issues = config.validate()
        if config_issues:
            logger.error("configuration_validation_failed", issues=config_issues)
            for issue in config_issues:
                logger.error("config_issue", issue=issue)
            sys.exit(1)

        # Log startup information
        logger.info(
            "linkwatcher_starting",
            version="2.0.0",
            project_root=str(project_root),
            config_file=args.config,
            dry_run=config.dry_run_mode,
        )

        # Check git repository
        if not args.quiet:
            check_git_repository(project_root)

        # Print startup information (for backward compatibility)
        if not args.quiet:
            print_startup_info(config, project_root)

        # Acquire lock file to prevent duplicate instances
        lock_file = acquire_lock(project_root)

        try:
            # Create and configure service
            service = LinkWatcherService(str(project_root), config=config)

            # Apply configuration
            service.set_dry_run(config.dry_run_mode)
            service.updater.set_backup_enabled(config.create_backups)

            # Add custom parsers if configured
            for extension, parser_class in config.custom_parsers.items():
                try:
                    # This would require dynamic loading - simplified for now
                    logger.warning("custom_parser_not_implemented", extension=extension)
                except Exception as e:
                    logger.warning("custom_parser_load_failed", extension=extension, error=str(e))

            # Start the service
            service.start(initial_scan=config.initial_scan_enabled)
        finally:
            release_lock(lock_file)

    except KeyboardInterrupt:
        logger = get_logger()
        logger.info("linkwatcher_stopped_by_user")
        sys.exit(0)
    except SystemExit:
        raise
    except Exception as e:
        logger = get_logger()
        logger.critical("fatal_error", error=str(e), error_type=type(e).__name__)
        if not args.quiet:
            logger.exception("fatal_error_traceback")
        sys.exit(1)


if __name__ == "__main__":
    main()
