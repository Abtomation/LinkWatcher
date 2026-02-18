#!/usr/bin/env python3
"""
Start the link watcher service with better debugging
"""

import os
import subprocess
import sys


def main():
    print("Starting Link Watcher Service...")

    # Use the actual working LinkWatcher
    linkwatcher_path = r"C:\Users\ronny\bin\main.py"

    try:
        # Run the actual working LinkWatcher
        subprocess.run([sys.executable, linkwatcher_path], check=True)
    except KeyboardInterrupt:
        print("\nStopping service...")
    except Exception as e:
        print(f"Error starting LinkWatcher: {e}")


if __name__ == "__main__":
    main()
