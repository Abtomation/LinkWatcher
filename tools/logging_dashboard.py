#!/usr/bin/env python3
"""
Real-time logging dashboard for LinkWatcher.

This script provides a terminal-based dashboard to monitor LinkWatcher
logs, metrics, and performance in real-time.
"""

import argparse
import json
import os
import sys
import threading
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional

try:
    import curses

    CURSES_AVAILABLE = True
except ImportError:
    CURSES_AVAILABLE = False

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from linkwatcher.logging_config import get_config_manager


class LogDashboard:
    """Real-time logging dashboard."""

    def __init__(self, log_file: Optional[str] = None, refresh_rate: float = 1.0):
        self.log_file = Path(log_file) if log_file else None
        self.refresh_rate = refresh_rate
        self.running = False

        # Data storage
        self.recent_logs = deque(maxlen=1000)
        self.metrics = {
            "total_logs": 0,
            "logs_by_level": defaultdict(int),
            "logs_by_component": defaultdict(int),
            "logs_by_operation": defaultdict(int),
            "errors_per_minute": deque(maxlen=60),
            "warnings_per_minute": deque(maxlen=60),
            "performance_data": deque(maxlen=100),
        }

        # Threading
        self.log_reader_thread: Optional[threading.Thread] = None
        self.stop_event = threading.Event()

        # Curses setup
        self.stdscr = None
        self.current_view = "overview"
        self.scroll_position = 0

    def start(self):
        """Start the dashboard."""
        self.running = True
        self.stop_event.clear()

        # Start log reader thread
        if self.log_file and self.log_file.exists():
            self.log_reader_thread = threading.Thread(target=self._read_logs)
            self.log_reader_thread.daemon = True
            self.log_reader_thread.start()

        # Start curses interface
        if CURSES_AVAILABLE:
            curses.wrapper(self._curses_main)
        else:
            self._text_main()

    def stop(self):
        """Stop the dashboard."""
        self.running = False
        self.stop_event.set()

        if self.log_reader_thread:
            self.log_reader_thread.join(timeout=2.0)

    def _read_logs(self):
        """Read logs from file in real-time."""
        if not self.log_file:
            return

        # Start from end of file
        with open(self.log_file, "r") as f:
            f.seek(0, 2)  # Go to end

            while not self.stop_event.wait(0.1):
                line = f.readline()
                if line:
                    self._process_log_line(line.strip())

    def _process_log_line(self, line: str):
        """Process a single log line."""
        try:
            if line.startswith("{"):
                # JSON log format
                log_entry = json.loads(line)
                self._update_metrics(log_entry)
                self.recent_logs.append(log_entry)
            else:
                # Plain text format
                log_entry = {
                    "timestamp": datetime.now().isoformat(),
                    "message": line,
                    "level": "INFO",
                }
                self.recent_logs.append(log_entry)

        except json.JSONDecodeError:
            # Treat as plain text
            log_entry = {"timestamp": datetime.now().isoformat(), "message": line, "level": "INFO"}
            self.recent_logs.append(log_entry)

    def _update_metrics(self, log_entry: Dict):
        """Update metrics from log entry."""
        self.metrics["total_logs"] += 1

        level = log_entry.get("level", "INFO")
        self.metrics["logs_by_level"][level] += 1

        component = log_entry.get("context", {}).get("component", "unknown")
        self.metrics["logs_by_component"][component] += 1

        operation = log_entry.get("context", {}).get("operation", "unknown")
        self.metrics["logs_by_operation"][operation] += 1

        # Track errors and warnings per minute
        now = datetime.now()
        if level == "ERROR":
            self.metrics["errors_per_minute"].append(now)
        elif level == "WARNING":
            self.metrics["warnings_per_minute"].append(now)

        # Track performance data
        if "duration_ms" in log_entry.get("context", {}):
            duration = log_entry["context"]["duration_ms"]
            self.metrics["performance_data"].append(
                {"timestamp": now, "duration": duration, "operation": operation}
            )

    def _curses_main(self, stdscr):
        """Main curses interface."""
        self.stdscr = stdscr
        curses.curs_set(0)  # Hide cursor
        stdscr.nodelay(1)  # Non-blocking input
        stdscr.timeout(int(self.refresh_rate * 1000))

        # Color pairs
        curses.start_color()
        curses.init_pair(1, curses.COLOR_RED, curses.COLOR_BLACK)  # Errors
        curses.init_pair(2, curses.COLOR_YELLOW, curses.COLOR_BLACK)  # Warnings
        curses.init_pair(3, curses.COLOR_GREEN, curses.COLOR_BLACK)  # Success
        curses.init_pair(4, curses.COLOR_CYAN, curses.COLOR_BLACK)  # Info
        curses.init_pair(5, curses.COLOR_MAGENTA, curses.COLOR_BLACK)  # Headers

        while self.running:
            try:
                self._draw_screen()

                # Handle input
                key = stdscr.getch()
                if key == ord("q"):
                    break
                elif key == ord("1"):
                    self.current_view = "overview"
                elif key == ord("2"):
                    self.current_view = "logs"
                elif key == ord("3"):
                    self.current_view = "metrics"
                elif key == ord("4"):
                    self.current_view = "performance"
                elif key == curses.KEY_UP:
                    self.scroll_position = max(0, self.scroll_position - 1)
                elif key == curses.KEY_DOWN:
                    self.scroll_position += 1
                elif key == ord("c"):
                    self._clear_data()

            except KeyboardInterrupt:
                break
            except Exception as e:
                # Log error and continue
                pass

        self.stop()

    def _draw_screen(self):
        """Draw the current screen."""
        if not self.stdscr:
            return

        self.stdscr.clear()
        height, width = self.stdscr.getmaxyx()

        # Header
        header = f"LinkWatcher Logging Dashboard - {self.current_view.title()} View"
        self.stdscr.addstr(0, 0, header.center(width), curses.color_pair(5) | curses.A_BOLD)

        # Navigation
        nav = "1:Overview 2:Logs 3:Metrics 4:Performance Q:Quit C:Clear"
        self.stdscr.addstr(1, 0, nav.center(width), curses.color_pair(4))

        # Content area
        content_start = 3
        content_height = height - content_start - 1

        if self.current_view == "overview":
            self._draw_overview(content_start, content_height, width)
        elif self.current_view == "logs":
            self._draw_logs(content_start, content_height, width)
        elif self.current_view == "metrics":
            self._draw_metrics(content_start, content_height, width)
        elif self.current_view == "performance":
            self._draw_performance(content_start, content_height, width)

        # Status line
        status = f"Total Logs: {self.metrics['total_logs']} | "
        status += f"Errors: {self.metrics['logs_by_level']['ERROR']} | "
        status += f"Warnings: {self.metrics['logs_by_level']['WARNING']} | "
        status += f"Updated: {datetime.now().strftime('%H:%M:%S')}"

        self.stdscr.addstr(height - 1, 0, status[: width - 1])

        self.stdscr.refresh()

    def _draw_overview(self, start_y: int, height: int, width: int):
        """Draw overview screen."""
        y = start_y

        # Summary stats
        self.stdscr.addstr(y, 0, "=== SUMMARY ===", curses.color_pair(5) | curses.A_BOLD)
        y += 2

        total_logs = self.metrics["total_logs"]
        errors = self.metrics["logs_by_level"]["ERROR"]
        warnings = self.metrics["logs_by_level"]["WARNING"]

        self.stdscr.addstr(y, 0, f"Total Logs: {total_logs}")
        y += 1
        self.stdscr.addstr(y, 0, f"Errors: {errors}", curses.color_pair(1))
        y += 1
        self.stdscr.addstr(y, 0, f"Warnings: {warnings}", curses.color_pair(2))
        y += 2

        # Recent activity
        self.stdscr.addstr(y, 0, "=== RECENT ACTIVITY ===", curses.color_pair(5) | curses.A_BOLD)
        y += 2

        recent_count = min(10, len(self.recent_logs))
        for i in range(recent_count):
            if y >= start_y + height - 1:
                break

            log_entry = self.recent_logs[-(i + 1)]
            timestamp = log_entry.get("timestamp", "")[:19]  # Remove microseconds
            level = log_entry.get("level", "INFO")
            message = log_entry.get("message", "")[: width - 25]  # Truncate message

            color = curses.color_pair(4)  # Default
            if level == "ERROR":
                color = curses.color_pair(1)
            elif level == "WARNING":
                color = curses.color_pair(2)
            elif level == "INFO":
                color = curses.color_pair(3)

            line = f"{timestamp} {level:8} {message}"
            self.stdscr.addstr(y, 0, line[: width - 1], color)
            y += 1

    def _draw_logs(self, start_y: int, height: int, width: int):
        """Draw logs screen."""
        y = start_y

        self.stdscr.addstr(y, 0, "=== RECENT LOGS ===", curses.color_pair(5) | curses.A_BOLD)
        y += 2

        # Show logs with scrolling
        log_count = len(self.recent_logs)
        start_idx = max(0, log_count - height + 2 - self.scroll_position)
        end_idx = min(log_count, start_idx + height - 2)

        for i in range(start_idx, end_idx):
            if y >= start_y + height - 1:
                break

            log_entry = self.recent_logs[i]
            timestamp = log_entry.get("timestamp", "")[:19]
            level = log_entry.get("level", "INFO")
            message = log_entry.get("message", "")

            # Truncate long messages
            max_msg_len = width - 30
            if len(message) > max_msg_len:
                message = message[: max_msg_len - 3] + "..."

            color = curses.color_pair(4)
            if level == "ERROR":
                color = curses.color_pair(1)
            elif level == "WARNING":
                color = curses.color_pair(2)
            elif level == "INFO":
                color = curses.color_pair(3)

            line = f"{timestamp} {level:8} {message}"
            self.stdscr.addstr(y, 0, line[: width - 1], color)
            y += 1

    def _draw_metrics(self, start_y: int, height: int, width: int):
        """Draw metrics screen."""
        y = start_y

        self.stdscr.addstr(y, 0, "=== METRICS ===", curses.color_pair(5) | curses.A_BOLD)
        y += 2

        # Logs by level
        self.stdscr.addstr(y, 0, "Logs by Level:", curses.A_BOLD)
        y += 1
        for level, count in self.metrics["logs_by_level"].items():
            color = curses.color_pair(4)
            if level == "ERROR":
                color = curses.color_pair(1)
            elif level == "WARNING":
                color = curses.color_pair(2)

            self.stdscr.addstr(y, 2, f"{level}: {count}", color)
            y += 1

        y += 1

        # Logs by component
        self.stdscr.addstr(y, 0, "Logs by Component:", curses.A_BOLD)
        y += 1
        for component, count in sorted(self.metrics["logs_by_component"].items()):
            if y >= start_y + height - 1:
                break
            self.stdscr.addstr(y, 2, f"{component}: {count}")
            y += 1

    def _draw_performance(self, start_y: int, height: int, width: int):
        """Draw performance screen."""
        y = start_y

        self.stdscr.addstr(y, 0, "=== PERFORMANCE ===", curses.color_pair(5) | curses.A_BOLD)
        y += 2

        if self.metrics["performance_data"]:
            # Calculate stats
            durations = [p["duration"] for p in self.metrics["performance_data"]]
            avg_duration = sum(durations) / len(durations)
            max_duration = max(durations)
            min_duration = min(durations)

            self.stdscr.addstr(y, 0, f"Average Duration: {avg_duration:.2f}ms")
            y += 1
            self.stdscr.addstr(y, 0, f"Max Duration: {max_duration:.2f}ms")
            y += 1
            self.stdscr.addstr(y, 0, f"Min Duration: {min_duration:.2f}ms")
            y += 2

            # Recent performance data
            self.stdscr.addstr(y, 0, "Recent Operations:", curses.A_BOLD)
            y += 1

            recent_count = min(height - (y - start_y) - 1, len(self.metrics["performance_data"]))
            for i in range(recent_count):
                perf_data = self.metrics["performance_data"][-(i + 1)]
                timestamp = perf_data["timestamp"].strftime("%H:%M:%S")
                duration = perf_data["duration"]
                operation = perf_data["operation"]

                color = curses.color_pair(4)
                if duration > 1000:  # Slow operation
                    color = curses.color_pair(1)
                elif duration > 500:
                    color = curses.color_pair(2)

                line = f"{timestamp} {operation:15} {duration:8.2f}ms"
                self.stdscr.addstr(y, 0, line[: width - 1], color)
                y += 1
        else:
            self.stdscr.addstr(y, 0, "No performance data available")

    def _clear_data(self):
        """Clear all collected data."""
        self.recent_logs.clear()
        self.metrics = {
            "total_logs": 0,
            "logs_by_level": defaultdict(int),
            "logs_by_component": defaultdict(int),
            "logs_by_operation": defaultdict(int),
            "errors_per_minute": deque(maxlen=60),
            "warnings_per_minute": deque(maxlen=60),
            "performance_data": deque(maxlen=100),
        }
        self.scroll_position = 0

    def _text_main(self):
        """Fallback text-based interface when curses is not available."""
        print("LinkWatcher Logging Dashboard (Text Mode)")
        print("Curses not available, using simple text output")
        print("Press Ctrl+C to exit")

        try:
            while self.running:
                os.system("clear" if os.name == "posix" else "cls")

                print(f"=== LinkWatcher Dashboard - {datetime.now().strftime('%H:%M:%S')} ===")
                print(f"Total Logs: {self.metrics['total_logs']}")
                print(f"Errors: {self.metrics['logs_by_level']['ERROR']}")
                print(f"Warnings: {self.metrics['logs_by_level']['WARNING']}")
                print()

                print("Recent Logs:")
                recent_count = min(10, len(self.recent_logs))
                for i in range(recent_count):
                    log_entry = self.recent_logs[-(i + 1)]
                    timestamp = log_entry.get("timestamp", "")[:19]
                    level = log_entry.get("level", "INFO")
                    message = log_entry.get("message", "")[:80]
                    print(f"{timestamp} {level:8} {message}")

                time.sleep(self.refresh_rate)

        except KeyboardInterrupt:
            pass

        self.stop()


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="LinkWatcher Logging Dashboard")
    parser.add_argument("--log-file", help="Path to log file to monitor")
    parser.add_argument(
        "--refresh-rate", type=float, default=1.0, help="Refresh rate in seconds (default: 1.0)"
    )
    parser.add_argument("--text-mode", action="store_true", help="Force text mode (disable curses)")

    args = parser.parse_args()

    if args.text_mode:
        global CURSES_AVAILABLE
        CURSES_AVAILABLE = False

    dashboard = LogDashboard(args.log_file, args.refresh_rate)

    try:
        dashboard.start()
    except KeyboardInterrupt:
        dashboard.stop()


if __name__ == "__main__":
    main()
