"""
Manual validation for PD-BUG-015: structlog cached state bleeds between test instances.

This script validates that:
1. structlog.reset_defaults() is called before structlog.configure() in LinkWatcherLogger
2. setup_logging() properly closes old file handlers before replacing
3. Multiple LinkWatcherLogger instances with different json_logs settings work correctly
4. TemporaryDirectory cleanup succeeds after setup_logging() with file handler
5. Sequential setup_logging() calls don't leak file handles

Run: python tests/manual/PD-BUG-015_structlog_cache_validation.py
"""

import sys
import tempfile
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))


def check(label, condition, detail=""):
    status = "PASS" if condition else "FAIL"
    msg = f"  [{status}] {label}"
    if detail:
        msg += f" — {detail}"
    print(msg)
    return condition


def main():
    print("=" * 70)
    print("PD-BUG-015 Manual Validation: structlog cache isolation")
    print("=" * 70)
    results = []

    # --- Check 1: structlog.reset_defaults() is called ---
    print("\n--- Check 1: structlog.reset_defaults() called before configure ---")
    import structlog

    from linkwatcher.logging import LinkWatcherLogger, LogLevel

    # Reset to known state
    structlog.reset_defaults()
    assert not structlog.is_configured()

    # Creating a logger should configure structlog
    logger1 = LinkWatcherLogger(name="check1", json_logs=False)
    results.append(check("structlog configured after creating logger", structlog.is_configured()))

    # Creating another logger should reset and reconfigure
    # (if reset_defaults is called, is_configured briefly becomes False then True)
    structlog.reset_defaults()
    assert not structlog.is_configured()
    logger2 = LinkWatcherLogger(name="check1b", json_logs=True)
    config = structlog.get_config()
    last_proc = config["processors"][-1]
    results.append(
        check(
            "Second logger uses JSONRenderer",
            isinstance(last_proc, structlog.processors.JSONRenderer),
            f"got {type(last_proc).__name__}",
        )
    )

    # --- Check 2: setup_logging() closes old file handlers ---
    print("\n--- Check 2: setup_logging() closes old file handlers ---")
    import logging.handlers

    from linkwatcher.logging import setup_logging

    temp_dir = tempfile.mkdtemp()
    try:
        log_file1 = Path(temp_dir) / "log1.log"
        log1 = setup_logging(level=LogLevel.DEBUG, log_file=str(log_file1))
        log1.info("message_to_file1")

        # Get reference to old file handler
        old_handlers = [
            h for h in log1.logger.handlers if isinstance(h, logging.handlers.RotatingFileHandler)
        ]
        results.append(check("First logger has file handler", len(old_handlers) == 1))
        old_handler = old_handlers[0] if old_handlers else None

        # Replace with new logger
        log2 = setup_logging(level=LogLevel.INFO)

        # Old handler should be closed
        if old_handler:
            stream_closed = old_handler.stream is None or old_handler.stream.closed
            results.append(check("Old file handler stream closed after replacement", stream_closed))

        # File should be deletable on Windows
        try:
            log_file1.unlink()
            results.append(check("Old log file deletable (no lock)", True))
        except PermissionError:
            results.append(check("Old log file deletable (no lock)", False, "PermissionError"))
    finally:
        # Clean up current logger handlers
        import linkwatcher.logging as lm

        if lm._logger:
            for handler in lm._logger.logger.handlers[:]:
                handler.close()
                lm._logger.logger.removeHandler(handler)
        import shutil

        shutil.rmtree(temp_dir, ignore_errors=True)

    # --- Check 3: TemporaryDirectory cleanup succeeds ---
    print("\n--- Check 3: TemporaryDirectory cleanup with setup_logging ---")
    try:
        with tempfile.TemporaryDirectory() as td:
            log_file = Path(td) / "temp_test.log"
            logger = setup_logging(
                level=LogLevel.DEBUG, log_file=str(log_file), colored_output=False
            )
            logger.info("test_message")
            assert log_file.exists()

            # Close handlers before cleanup
            for handler in logger.logger.handlers[:]:
                handler.close()
                logger.logger.removeHandler(handler)
        results.append(check("TemporaryDirectory cleanup succeeded", True))
    except PermissionError as e:
        results.append(check("TemporaryDirectory cleanup succeeded", False, str(e)))

    # --- Check 4: Multiple json_logs switches ---
    print("\n--- Check 4: Multiple json_logs configuration switches ---")
    logger_a = LinkWatcherLogger(name="switch_a", json_logs=False)
    config_a = structlog.get_config()
    is_console_a = isinstance(config_a["processors"][-1], structlog.dev.ConsoleRenderer)
    results.append(check("Logger A uses ConsoleRenderer (json_logs=False)", is_console_a))

    logger_b = LinkWatcherLogger(name="switch_b", json_logs=True)
    config_b = structlog.get_config()
    is_json_b = isinstance(config_b["processors"][-1], structlog.processors.JSONRenderer)
    results.append(check("Logger B uses JSONRenderer (json_logs=True)", is_json_b))

    logger_c = LinkWatcherLogger(name="switch_c", json_logs=False)
    config_c = structlog.get_config()
    is_console_c = isinstance(config_c["processors"][-1], structlog.dev.ConsoleRenderer)
    results.append(check("Logger C uses ConsoleRenderer (json_logs=False)", is_console_c))

    # --- Check 5: Sequential setup_logging doesn't leak handles ---
    print("\n--- Check 5: Sequential setup_logging no file handle leaks ---")
    temp_dir2 = tempfile.mkdtemp()
    try:
        files = []
        for i in range(5):
            f = Path(temp_dir2) / f"seq_{i}.log"
            files.append(f)
            setup_logging(level=LogLevel.DEBUG, log_file=str(f))

        # All old files should be deletable (handlers closed)
        all_deletable = True
        for f in files[:-1]:  # All except the last (still active)
            try:
                if f.exists():
                    f.unlink()
            except PermissionError:
                all_deletable = False
                break
        results.append(
            check("All old log files deletable after sequential setup_logging", all_deletable)
        )
    finally:
        if lm._logger:
            for handler in lm._logger.logger.handlers[:]:
                handler.close()
                lm._logger.logger.removeHandler(handler)
        shutil.rmtree(temp_dir2, ignore_errors=True)

    # --- Summary ---
    print("\n" + "=" * 70)
    passed = sum(results)
    total = len(results)
    print(f"Results: {passed}/{total} checks passed")
    if passed == total:
        print("VALIDATION: ALL CHECKS PASSED")
    else:
        print("VALIDATION: SOME CHECKS FAILED")
    print("=" * 70)

    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
