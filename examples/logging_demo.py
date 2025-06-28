#!/usr/bin/env python3
"""
Demonstration of LinkWatcher's enhanced logging capabilities.

This script showcases all the logging features including structured logging,
performance monitoring, filtering, and real-time configuration.
"""

import os
import sys
import tempfile
import time
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from linkwatcher.logging import LogLevel, LogTimer, get_logger, setup_logging, with_context
from linkwatcher.logging_config import (
    clear_all_filters,
    filter_by_component,
    filter_by_operation,
    get_config_manager,
    set_log_level,
    setup_advanced_logging,
    show_log_metrics,
)


def demonstrate_basic_logging():
    """Demonstrate basic structured logging."""
    print("\n=== Basic Structured Logging ===")

    logger = get_logger()

    # Basic log messages with context
    logger.info("application_started", version="2.0.0", mode="demo")
    logger.debug("configuration_loaded", config_file="demo.yaml", settings_count=15)
    logger.warning("deprecated_feature_used", feature="old_parser", replacement="new_parser")
    logger.error("file_not_found", file_path="missing.md", operation="file_scan")

    # LinkWatcher-specific convenience methods
    logger.file_moved("docs/old.md", "docs/new.md", references_count=3)
    logger.file_deleted("temp.md", references_count=1)
    logger.links_updated("README.md", references_updated=2)
    logger.scan_progress(files_scanned=150, total_files=200)


def demonstrate_contextual_logging():
    """Demonstrate contextual logging with thread-local context."""
    print("\n=== Contextual Logging ===")

    logger = get_logger()

    # Set context for all subsequent logs
    logger.set_context(operation="file_processing", user_id="demo_user", session_id="abc123")

    logger.info("processing_started", file_count=5)
    logger.debug("file_validated", file_path="test1.md", size_bytes=1024)
    logger.debug("file_validated", file_path="test2.md", size_bytes=2048)
    logger.info("processing_completed", files_processed=5, duration_ms=1250)

    # Clear context
    logger.clear_context()

    # Using decorator for automatic context management
    @with_context(component="parser", file_type="markdown")
    def parse_markdown_file(file_path):
        logger.info("parsing_file", file_path=file_path)
        logger.debug("extracting_links", link_count=3)
        logger.info("parsing_completed", file_path=file_path, links_found=3)

    parse_markdown_file("example.md")


def demonstrate_performance_logging():
    """Demonstrate performance monitoring and timing."""
    print("\n=== Performance Monitoring ===")

    logger = get_logger()

    # Using LogTimer context manager
    with LogTimer("file_processing", logger, file_count=100, operation_type="batch"):
        # Simulate some work
        time.sleep(0.1)
        logger.debug("processing_files", current_file=50)
        time.sleep(0.1)

    # Manual performance logging
    timer_id = logger.performance.start_timer("database_query")
    time.sleep(0.05)  # Simulate database work
    logger.performance.end_timer(timer_id, "database_query", records_processed=500)

    # Log metrics
    logger.performance.log_metric("memory_usage", 256.5, "MB", component="parser")
    logger.performance.log_metric("files_per_second", 45.2, "files/sec", operation="scan")


def demonstrate_log_filtering():
    """Demonstrate runtime log filtering."""
    print("\n=== Runtime Log Filtering ===")

    logger = get_logger()
    config_manager = get_config_manager()

    # Log some messages before filtering
    logger.info("before_filter", component="handler", operation="file_move")
    logger.info("before_filter", component="parser", operation="file_scan")
    logger.info("before_filter", component="updater", operation="link_update")

    # Apply filters
    print("Applying filters: only 'handler' component and 'file_move' operations")
    filter_by_component("handler")
    filter_by_operation("file_move")

    # These should be filtered out
    logger.info("after_filter", component="parser", operation="file_scan")
    logger.info("after_filter", component="updater", operation="link_update")

    # This should pass through
    logger.info("after_filter", component="handler", operation="file_move")

    # Clear filters
    clear_all_filters()
    print("Filters cleared")

    # This should now appear
    logger.info("filters_cleared", component="parser", operation="file_scan")


def demonstrate_configuration_management():
    """Demonstrate configuration file management."""
    print("\n=== Configuration Management ===")

    # Create a temporary configuration file
    config_data = """
log_level: "DEBUG"
colored_output: true
json_logs: false
show_log_icons: true

filters:
  components:
    - "demo"
    - "example"
  operations:
    - "test_operation"
  level_range:
    min: "INFO"
    max: "ERROR"
"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
        f.write(config_data)
        config_file = f.name

    try:
        # Load configuration
        config_manager = setup_advanced_logging(config_file)
        print(f"Loaded configuration from {config_file}")

        # Test the configuration
        logger = get_logger()
        logger.info("config_test", component="demo", operation="test_operation")
        logger.debug("debug_message", component="demo")  # Should be filtered out by level
        logger.info("filtered_out", component="other")  # Should be filtered out by component

        # Show debug snapshot
        snapshot = config_manager.create_debug_snapshot()
        print(f"Active filters: {snapshot['active_filters']}")

    finally:
        # Clean up
        os.unlink(config_file)


def demonstrate_metrics_collection():
    """Demonstrate metrics collection and reporting."""
    print("\n=== Metrics Collection ===")

    logger = get_logger()
    config_manager = get_config_manager()

    # Generate some log activity
    for i in range(10):
        if i % 3 == 0:
            logger.error("test_error", iteration=i, component="demo")
        elif i % 3 == 1:
            logger.warning("test_warning", iteration=i, component="demo")
        else:
            logger.info("test_info", iteration=i, component="demo")

    # Show current metrics
    show_log_metrics()

    # Get detailed metrics
    metrics = config_manager.get_metrics()
    print(f"Total logs: {metrics['total_logs']}")
    print(f"Error count: {metrics['error_count']}")
    print(f"Warning count: {metrics['warning_count']}")
    print(f"Logs per minute: {metrics['logs_per_minute']:.2f}")


def demonstrate_different_log_levels():
    """Demonstrate different log levels and their usage."""
    print("\n=== Log Levels Demonstration ===")

    logger = get_logger()

    # Start with INFO level
    set_log_level(LogLevel.INFO)
    print("Log level set to INFO")

    logger.debug("debug_message")  # Won't appear
    logger.info("info_message")  # Will appear
    logger.warning("warning_message")  # Will appear
    logger.error("error_message")  # Will appear

    # Change to DEBUG level
    set_log_level(LogLevel.DEBUG)
    print("\nLog level set to DEBUG")

    logger.debug("debug_message")  # Will now appear
    logger.info("info_message")  # Will appear

    # Change to ERROR level
    set_log_level(LogLevel.ERROR)
    print("\nLog level set to ERROR")

    logger.info("info_message")  # Won't appear
    logger.warning("warning_message")  # Won't appear
    logger.error("error_message")  # Will appear


def main():
    """Main demonstration function."""
    print("LinkWatcher Enhanced Logging System Demonstration")
    print("=" * 60)

    # Setup logging with file output for demonstration
    with tempfile.NamedTemporaryFile(mode="w", suffix=".log", delete=False) as f:
        log_file = f.name

    try:
        # Setup enhanced logging
        logger = setup_logging(
            level=LogLevel.DEBUG,
            log_file=log_file,
            colored_output=True,
            show_icons=True,
            json_logs=False,  # Use readable format for demo
        )

        print(f"Logging to file: {log_file}")
        print("Watch the console output and check the log file for JSON format")

        # Run demonstrations
        demonstrate_basic_logging()
        demonstrate_contextual_logging()
        demonstrate_performance_logging()
        demonstrate_log_filtering()
        demonstrate_configuration_management()
        demonstrate_metrics_collection()
        demonstrate_different_log_levels()

        print(f"\n=== Demo Complete ===")
        print(f"Check the log file for detailed JSON logs: {log_file}")
        print("You can also run the logging dashboard:")
        print(f"python tools/logging_dashboard.py --log-file {log_file}")

    except Exception as e:
        print(f"Error during demonstration: {e}")
        import traceback

        traceback.print_exc()

    finally:
        # Note: In a real application, you might want to keep the log file
        # For demo purposes, we'll leave it for inspection
        print(f"Log file preserved at: {log_file}")


if __name__ == "__main__":
    main()
