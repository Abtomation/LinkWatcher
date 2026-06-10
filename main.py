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

If you want to store the logs as well
    python main.py --log-file logs/linkwatcher/linkwatcher.txt --debug
"""

import argparse
import os
import sys
import time
from pathlib import Path

# Add the current directory to Python path for imports
sys.path.insert(0, str(Path(__file__).parent))

try:
    from colorama import Fore, init
    from git import InvalidGitRepositoryError, Repo

    from linkwatcher import LinkWatcherService, __version__
    from linkwatcher.config import DEFAULT_CONFIG, LinkWatcherConfig
    from linkwatcher.logging import LogLevel, get_logger, setup_logging
    from linkwatcher.validator import LinkValidator
except ImportError as e:
    print(f"Missing required dependency: {e}")
    print("Please install dependencies with: pip install -e .")
    sys.exit(1)

# Initialize colorama for cross-platform colored output
init(autoreset=True)


def load_config(config_path: str = None, args=None, project_root: str = None) -> LinkWatcherConfig:
    """Load configuration from file, environment, and command line arguments.

    When *project_root* is provided and ``doc/project-config.json`` exists
    there, ``paths.source_code`` is used as a fallback for
    ``python_source_root`` (PD-BUG-078).  Explicit config-file or env-var
    values take precedence.
    """
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

    # PD-BUG-078: Fallback — read python_source_root from project-config.json
    # if not explicitly set via config file or env var.
    if not config.python_source_root and project_root:
        config.python_source_root = _read_source_root_from_project_config(project_root, logger)

    return config


def _read_source_root_from_project_config(project_root: str, logger) -> str:
    """Read paths.source_code from doc/project-config.json as python_source_root fallback."""
    project_config_path = Path(project_root) / "doc" / "project-config.json"
    if not project_config_path.exists():
        return ""
    try:
        import json as _json

        with open(project_config_path, "r", encoding="utf-8") as f:
            data = _json.load(f)
        source_code = data.get("paths", {}).get("source_code", "")
        if source_code:
            logger.debug("python_source_root_from_project_config", source_root=source_code)
        return source_code
    except Exception as e:
        logger.debug("project_config_read_failed", error=str(e))
        return ""


def _apply_logging_config(args, config: LinkWatcherConfig):
    """Re-initialize logging from a merged precedence rule (CLI args > config > defaults).

    Called after load_config() in both the service and validate branches so config-only
    fields (log_level, colored_output, show_log_icons, json_logs, log_file_max_size_mb,
    log_file_backup_count) are consistently applied. Resolves TD232 and TD233.
    """
    if args.debug:
        level = LogLevel.DEBUG
    elif args.quiet:
        level = LogLevel.ERROR
    else:
        level = LogLevel(config.log_level)

    log_file = args.log_file or config.log_file

    return setup_logging(
        level=level,
        log_file=log_file,
        colored_output=config.colored_output and not args.quiet,
        show_icons=config.show_log_icons and not args.quiet,
        json_logs=config.json_logs,
        max_file_size=config.log_file_max_size_mb * 1024 * 1024,
        backup_count=config.log_file_backup_count,
    )


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
    """Check if a process with the given PID is still running.

    Note: os.kill(pid, 0) cannot be used on Windows because signal 0
    equals CTRL_C_EVENT, which actually terminates the target process.
    """
    if sys.platform == "win32":
        import ctypes

        kernel32 = ctypes.windll.kernel32
        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if handle:
            kernel32.CloseHandle(handle)
            return True
        return False
    else:
        try:
            os.kill(pid, 0)
            return True
        except PermissionError:
            return True
        except OSError:
            return False


def _read_lock_owner_pid(lock_file: Path, settle_attempts: int = 5, settle_delay: float = 0.02):
    """Read the owner PID from an existing lock file, tolerating the brief
    create-then-write window in which the lock exists but its PID has not been
    written yet (TD255).

    A rival that just won the atomic ``O_EXCL`` create writes its PID a moment
    later. Reading an *empty* body during that window and treating it as a stale
    lock would let us delete a legitimate fresh lock and double-acquire. So on an
    empty body we re-read a few times before giving up: a live owner's PID appears
    within microseconds, whereas a genuine orphan (creator died before writing)
    stays empty and is correctly reported as None (reclaimable). Non-numeric
    content is genuine corruption — reported as None immediately, no waiting.

    Returns the parsed PID, or None if the body is corrupt or stays empty.
    """
    for _ in range(settle_attempts):
        try:
            body = lock_file.read_text().strip()
        except OSError:
            return None
        if body == "":
            time.sleep(settle_delay)  # create-then-write window — let the owner write its PID
            continue
        try:
            return int(body)
        except ValueError:
            return None  # non-numeric = corruption, reclaim now
    return None  # stayed empty across all attempts = orphan, reclaim


def acquire_lock(project_root: Path) -> Path:
    """Acquire a lock file to prevent duplicate instances.

    Uses an atomic ``O_CREAT | O_EXCL`` create so two near-simultaneous starts
    cannot both win (PD-BUG-099). Exactly one process creates the lock; any
    rival that lost the race observes the existing lock and either exits (if the
    owner is still alive) or reclaims it (if the owner is gone). This replaces
    the former check-then-write sequence, whose gap between ``exists()`` and
    ``write_text()`` let two racers each overwrite the other's lock and run
    concurrently — the condition behind the multi-instance log-rotation storm.

    Returns the lock file path on success, or None if lock creation is
    impossible (protection disabled). Raises SystemExit if another live instance
    already holds the lock.
    """
    lock_file = project_root / LOCK_FILE_NAME

    # Bounded retries: losing to a *stale* lock triggers one reclaim attempt.
    # The bound stops an unbounded loop if a rival keeps recreating the lock.
    for _attempt in range(5):
        try:
            # Atomic create — fails with FileExistsError if the lock exists.
            fd = os.open(lock_file, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        except FileExistsError:
            # Lost the race (or a prior instance's lock survived). Decide
            # whether the current owner is still alive. Settle-read tolerates the
            # rival's create-then-write window so we don't reclaim a lock whose
            # PID is a few microseconds from being written (TD255).
            existing_pid = _read_lock_owner_pid(lock_file)

            if (
                existing_pid is not None
                and existing_pid != os.getpid()
                and _is_pid_running(existing_pid)
            ):
                print(f"{Fore.RED}✗ LinkWatcher is already running (PID: {existing_pid})")
                print(f"{Fore.YELLOW}  Lock file: {lock_file}")
                sys.exit(1)

            # Stale or unreadable lock — remove it and retry the atomic create.
            print(f"{Fore.YELLOW}⚠️ Overriding stale lock file")
            try:
                lock_file.unlink()
            except OSError:
                pass
            continue
        except OSError as e:
            print(
                f"{Fore.YELLOW}⚠️ Could not create lock file ({e}). "
                f"Duplicate instance protection disabled."
            )
            return None
        else:
            # We atomically created the lock — record our PID for diagnostics.
            try:
                os.write(fd, str(os.getpid()).encode("ascii"))
            finally:
                os.close(fd)
            return lock_file

    # Exhausted retries — a rival kept recreating the lock; treat as running.
    print(f"{Fore.RED}✗ LinkWatcher lock is contended; another instance is starting.")
    print(f"{Fore.YELLOW}  Lock file: {lock_file}")
    sys.exit(1)


def release_lock(lock_file: Path):
    """Release the lock file — but only if we still own it.

    A successor that found this process's lock stale could legitimately reclaim
    it (PD-BUG-100): the on-disk PID then belongs to a *different*, live instance.
    Blindly unlinking on shutdown would strip the running successor's lock and
    re-open the multi-instance window, so only delete the lock when it still
    holds our own PID. A foreign or unreadable lock is left untouched.
    """
    if lock_file is None or not lock_file.exists():
        return
    try:
        owner = lock_file.read_text().strip()
    except OSError:
        return
    if owner != str(os.getpid()):
        return  # reclaimed by a successor — not ours to delete
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
  python main.py --validate        # Check all links and report broken ones
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
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Scan workspace for broken links and exit (does not start watcher)",
    )
    parser.add_argument("--version", action="version", version=f"LinkWatcher {__version__}")

    args = parser.parse_args()

    try:
        # Validate project root first (needed for lock check)
        project_root = validate_project_root(args.project_root)

        # --validate mode: scan for broken links and exit (no lock needed)
        if args.validate:
            log_level = LogLevel.DEBUG if args.debug else LogLevel.INFO
            if args.quiet:
                log_level = LogLevel.ERROR
            setup_logging(
                level=log_level,
                colored_output=not args.quiet,
                show_icons=not args.quiet,
            )
            config = load_config(args.config, args, project_root=str(project_root))
            _apply_logging_config(args, config)
            validator = LinkValidator(str(project_root), config)

            if not args.quiet:
                print(f"{Fore.CYAN}🔍 Validating links in {project_root}...")

            result = validator.validate()
            report = LinkValidator.format_report(result)

            if not args.quiet:
                print(report)

            # Determine output directory.
            # Precedence: validation_output_dir (resolved against project_root if relative)
            #             → parent of --log-file/config.log_file → project root.
            log_file = args.log_file or config.log_file
            if config.validation_output_dir:
                vod = Path(config.validation_output_dir)
                if not vod.is_absolute():
                    vod = project_root / vod
                output_dir = str(vod)
            elif log_file:
                output_dir = str(Path(log_file).parent)
            else:
                output_dir = str(project_root)
            report_path = LinkValidator.write_report(result, output_dir)

            if not args.quiet:
                print(f"{Fore.CYAN}📄 Report written to {report_path}")

            sys.exit(0 if result.is_clean else 1)

        # Acquire lock BEFORE setting up file logging to avoid
        # conflicting file handles that kill the running instance
        lock_file = acquire_lock(project_root)

        # Setup logging (safe to open log file now that we hold the lock)
        log_level = LogLevel.DEBUG if args.debug else LogLevel.INFO
        if args.quiet:
            log_level = LogLevel.ERROR

        logger = setup_logging(
            level=log_level,
            log_file=args.log_file,
            colored_output=not args.quiet,
            show_icons=not args.quiet,
        )

        # Load configuration
        config = load_config(args.config, args, project_root=str(project_root))

        # Re-initialize logging from config (CLI args take precedence — see helper)
        logger = _apply_logging_config(args, config)

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
            version=__version__,
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

        try:
            # Create and configure service
            service = LinkWatcherService(str(project_root), config=config)

            # Add custom parsers if configured
            for extension, parser_class in getattr(config, "custom_parsers", {}).items():
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
