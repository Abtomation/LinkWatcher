"""
Default configuration values for the LinkWatcher system.

This module provides the default configuration that can be used
as a starting point or fallback.
"""

from .settings import LinkWatcherConfig

# Default configuration instance
DEFAULT_CONFIG = LinkWatcherConfig(
    # File monitoring settings
    monitored_extensions={
        # Documentation and text files
        ".md",  # Markdown files
        ".txt",  # Text files
        ".yaml",  # YAML files
        ".yml",  # YAML files (alternative extension)
        ".json",  # JSON files
        ".xml",  # XML files
        ".csv",  # CSV data files
        # Web development files
        ".html",  # HTML files
        ".htm",  # HTML files (alternative extension)
        ".css",  # CSS stylesheets
        ".js",  # JavaScript files
        ".ts",  # TypeScript files
        ".jsx",  # React JSX files
        ".tsx",  # React TypeScript JSX files
        ".vue",  # Vue.js components
        ".php",  # PHP files
        # Image files (commonly referenced)
        ".png",  # PNG image files
        ".jpg",  # JPEG image files
        ".jpeg",  # JPEG image files (alternative extension)
        ".gif",  # GIF image files
        ".svg",  # SVG image files (may contain links)
        ".webp",  # WebP image files
        ".ico",  # Icon files
        # Document files
        ".pdf",  # PDF documents
        # Source code files (project-specific, but commonly referenced)
        ".py",  # Python files
        ".dart",  # Dart files
        # Media files (commonly referenced in documentation)
        ".mp4",  # Video files
        ".mp3",  # Audio files
        ".wav",  # Audio files
    },
    ignored_directories={
        ".git",  # Git repository data
        ".dart_tool",  # Dart build tools
        "node_modules",  # Node.js dependencies
        ".vscode",  # VS Code settings
        "build",  # Build output
        "dist",  # Distribution files
        "__pycache__",  # Python cache
        ".pytest_cache",  # Pytest cache
        "coverage",  # Coverage reports
        "docs/_build",  # Documentation build
        "target",  # Rust/Java build target
        "bin",  # Binary files
        "obj",  # Object files
    },
    # Parser settings - all enabled by default
    enable_markdown_parser=True,
    enable_yaml_parser=True,
    enable_json_parser=True,
    enable_dart_parser=True,
    enable_python_parser=True,
    enable_generic_parser=True,
    # Update behavior
    create_backups=False,  # Create .bak files before updates (disabled by default)
    dry_run_mode=False,  # Actually modify files
    atomic_updates=True,  # Use temporary files for safe updates
    # Performance settings
    max_file_size_mb=10,  # Skip files larger than 10MB
    initial_scan_enabled=True,  # Scan all files on startup
    scan_progress_interval=50,  # Show progress every 50 files
    # Logging settings
    log_level="INFO",  # Standard logging level
    colored_output=True,  # Use colors in console output
    show_statistics=True,  # Show statistics on shutdown
    # Advanced settings (empty by default)
    custom_parsers={},  # No custom parsers
    exclude_patterns=set(),  # No additional exclusions
    include_patterns=set(),  # No forced inclusions
)

# Configuration for different environments
DEVELOPMENT_CONFIG = LinkWatcherConfig(
    # More verbose logging for development
    log_level="DEBUG",
    show_statistics=True,
    # Safer defaults for development
    create_backups=False,
    dry_run_mode=False,
    # Standard monitoring
    monitored_extensions=DEFAULT_CONFIG.monitored_extensions.copy(),
    ignored_directories=DEFAULT_CONFIG.ignored_directories.copy(),
)

PRODUCTION_CONFIG = LinkWatcherConfig(
    # Less verbose logging for production
    log_level="WARNING",
    show_statistics=False,
    colored_output=False,
    # Performance optimized
    initial_scan_enabled=False,  # Skip initial scan for faster startup
    max_file_size_mb=5,  # Smaller file size limit
    # Standard monitoring
    monitored_extensions=DEFAULT_CONFIG.monitored_extensions.copy(),
    ignored_directories=DEFAULT_CONFIG.ignored_directories.copy(),
)

TESTING_CONFIG = LinkWatcherConfig(
    # Testing-specific settings
    log_level="DEBUG",
    show_statistics=False,
    colored_output=False,
    # Safe for testing (keep backups enabled for testing backup functionality)
    create_backups=True,
    dry_run_mode=True,  # Don't actually modify files in tests
    # Minimal monitoring for tests
    monitored_extensions={".md", ".txt", ".png", ".svg"},
    ignored_directories={".git", "node_modules"},
)
