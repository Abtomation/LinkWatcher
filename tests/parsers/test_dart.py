"""
Tests for the Dart parser.

This module tests Dart-specific link parsing functionality.
"""

from pathlib import Path

import pytest

from linkwatcher.models import LinkReference
from linkwatcher.parsers.dart import DartParser


class TestDartParser:
    """Test cases for DartParser."""

    def test_parser_initialization(self):
        """Test parser initialization."""
        parser = DartParser()

        # Check that regex patterns are compiled
        assert parser.import_pattern is not None
        assert parser.quoted_pattern is not None
        assert parser.standalone_pattern is not None

    def test_parse_import_statements(self, temp_project_dir):
        """Test parsing Dart import statements."""
        parser = DartParser()

        # Create Dart file with imports
        dart_file = temp_project_dir / "main.dart"
        content = """
import 'dart:io';
import 'dart:convert';

// Local imports
import 'package:flutter/material.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/models/user.dart';

// Relative imports
import '../config/settings.dart';
import 'helpers/tests/parsers/utils.dart';
import 'widgets/custom_button.dart';

// File references in comments and strings
// See "pubspec.yaml" for dependencies
const String configFile = "../tests/parsers/config.json";
const String dataPath = 'data/users.json';

void main() {
  // Load configuration from "config/app.yaml"
  runApp(MyApp());
}
"""
        dart_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(dart_file))

        # Should find various references
        assert len(references) >= 3

        # Check for specific references
        targets = [ref.link_target for ref in references]

        # Should find quoted file references
        assert "pubspec.yaml" in targets
        assert "../tests/parsers/config.json" in targets
        assert "data/users.json" in targets
        assert "config/app.yaml" in targets

        # Check link types
        for ref in references:
            assert ref.link_type in [
                "dart-import",
                "dart-part",
                "dart-quoted",
                "dart-standalone",
                "dart-embedded",
            ]

    def test_parse_asset_references(self, temp_project_dir):
        """Test parsing asset references in Dart files."""
        parser = DartParser()

        # Create Dart file with asset references
        dart_file = temp_project_dir / "assets.dart"
        content = """
class Assets {
  // Image assets
  static const String logo = "assets/images/logo.png";
  static const String background = 'assets/images/background.jpg';
  static const String icon = "assets/icons/app_icon.png";

  // Font assets
  static const String primaryFont = "assets/fonts/roboto.ttf";
  static const String secondaryFont = 'assets/fonts/opensans.ttf';

  // Data assets
  static const String configData = "tests/parsers/config.json";
  static const String localization = 'assets/i18n/en.json';

  // Other file references
  static const String readme = "README.md";
  static const String changelog = 'CHANGELOG.md';
}

// Asset loading functions
Future<String> loadAsset(String path) async {
  // Load from "../tests/parsers/data/default.json"
  return await rootBundle.loadString(path);
}

Widget buildImage() {
  return Image.asset("assets/images/placeholder.png");
}
"""
        dart_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(dart_file))

        # Should find asset references
        assert len(references) >= 8

        # Check specific references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "assets/images/logo.png",
            "assets/images/background.jpg",
            "assets/icons/app_icon.png",
            "assets/fonts/roboto.ttf",
            "assets/fonts/opensans.ttf",
            "tests/parsers/config.json",
            "assets/i18n/en.json",
            "README.md",
            "CHANGELOG.md",
            "../tests/parsers/data/default.json",
            "assets/images/placeholder.png",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    def test_parse_pubspec_references(self, temp_project_dir):
        """Test parsing references to pubspec and other config files."""
        parser = DartParser()

        # Create Dart file with config references
        dart_file = temp_project_dir / "config.dart"
        content = """
/// Configuration management for the Flutter app.
///
/// This class loads configuration from various sources:
/// - Main config: "pubspec.yaml"
/// - App config: "assets/config/app.yaml"
/// - Environment config: 'config/env.json'

import 'dart:convert';
import 'dart:io';

class ConfigManager {
  static const String pubspecPath = "pubspec.yaml";
  static const String appConfigPath = "assets/config/app.yaml";
  static const String envConfigPath = 'config/env.json';

  // Analysis options
  static const String analysisOptions = "analysis_options.yaml";

  // Build configuration
  static const String buildConfig = 'build.yaml';
  static const String androidManifest = "android/app/src/main/AndroidManifest.xml";
  static const String iosInfo = 'ios/Runner/Info.plist';

  /// Load configuration from "config/settings.json"
  Future<Map<String, dynamic>> loadConfig() async {
    final file = File("config/settings.json");
    if (await file.exists()) {
      final contents = await file.readAsString();
      return json.decode(contents);
    }
    return {};
  }

  /// Save configuration to 'config/settings.json'
  Future<void> saveConfig(Map<String, dynamic> config) async {
    final file = File('config/settings.json');
    await file.writeAsString(json.encode(config));
  }
}
"""
        dart_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(dart_file))

        # Should find config file references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "pubspec.yaml",
            "assets/config/app.yaml",
            "config/env.json",
            "analysis_options.yaml",
            "build.yaml",
            "android/app/src/main/AndroidManifest.xml",
            "ios/Runner/Info.plist",
            "config/settings.json",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    def test_skip_package_imports(self, temp_project_dir):
        """Test that package imports are skipped."""
        parser = DartParser()

        # Create Dart file with various imports
        dart_file = temp_project_dir / "imports.dart"
        content = """
// Standard library imports (should be ignored)
import 'dart:io';
import 'dart:convert';
import 'dart:async';

// Package imports (should be ignored)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// Local file imports (might be detected depending on heuristics)
import 'utils.dart';
import 'models/user.dart';
import '../config/settings.dart';

// But file references should be found
const String dataFile = "data.json";
const String configFile = 'config.yaml';
"""
        dart_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(dart_file))

        targets = [ref.link_target for ref in references]

        # Should find file references
        assert "data.json" in targets
        assert "config.yaml" in targets

        # Should not find package imports
        assert "dart:io" not in targets
        assert "package:flutter/material.dart" not in targets
        assert "package:http/http.dart" not in targets

    def test_parse_documentation_comments(self, temp_project_dir):
        """Test parsing file references in documentation comments."""
        parser = DartParser()

        # Create Dart file with doc comments
        dart_file = temp_project_dir / "documented.dart"
        content = """
/// Main application widget.
///
/// This widget serves as the root of the application. Configuration
/// is loaded from "config/app.yaml" and assets are defined in 'pubspec.yaml'.
///
/// Example usage:
/// ```dart
/// // Load data from "data/users.json"
/// final users = await loadUsers();
/// ```
///
/// See also:
/// - Configuration guide: docs/configuration.md
/// - Asset management: docs/assets.md
/// - API documentation: docs/api/index.html
class MyApp extends StatelessWidget {
  /// Creates a new MyApp instance.
  ///
  /// Loads initial configuration from "config/initial.json".
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: MyHomePage(),
    );
  }
}

/// Home page widget.
///
/// Displays data loaded from 'data/home.json' and uses
/// templates from "templates/home.html".
class MyHomePage extends StatefulWidget {
  /// Creates a new MyHomePage.
  ///
  /// The page layout is defined in templates/layout.html
  /// and styles are loaded from 'assets/css/home.css'.
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}
"""
        dart_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(dart_file))

        # Should find references in doc comments
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "config/app.yaml",
            "pubspec.yaml",
            "data/users.json",
            "docs/configuration.md",
            "docs/assets.md",
            "docs/api/index.html",
            "config/initial.json",
            "data/home.json",
            "templates/home.html",
            "templates/layout.html",
            "assets/css/home.css",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    def test_avoid_false_positives(self, temp_project_dir):
        """Test that false positives are avoided."""
        parser = DartParser()

        # Create Dart file with potential false positives
        dart_file = temp_project_dir / "false_positives.dart"
        content = """
class FalsePositives {
  // These should NOT be detected as file references
  static const String version = "1.2.3";
  static const String email = "user@example.com";
  static const String url = "https://example.com/api";
  static const String uuid = "123e4567-e89b-12d3-a456-426614174000";

  // These SHOULD be detected as file references
  static const String configFile = "config.json";
  static const String dataPath = "data/users.csv";

  // Edge cases
  static const String extensionOnly = ".dart";  // Should not be detected
  static const String noExtension = "filename";  // Might be detected

  // Method names and other identifiers
  void loadData() {
    // Method implementation
  }

  String get fileName => "actual_file.txt";  // Should be detected
}

// Regular expressions and patterns
final RegExp pattern = RegExp(r'\\d+\\.\\d+');
final String sqlQuery = "SELECT * FROM users WHERE id = ?";
"""
        dart_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(dart_file))

        targets = [ref.link_target for ref in references]

        # Should find actual file references
        assert "config.json" in targets
        assert "data/users.csv" in targets
        assert "actual_file.txt" in targets

        # Should not find false positives
        assert "1.2.3" not in targets
        assert "user@example.com" not in targets
        assert "https://example.com/api" not in targets
        assert "123e4567-e89b-12d3-a456-426614174000" not in targets
        assert "SELECT * FROM users WHERE id = ?" not in targets

    def test_flutter_specific_patterns(self, temp_project_dir):
        """Test Flutter-specific file reference patterns."""
        parser = DartParser()

        # Create Flutter-specific Dart file
        dart_file = temp_project_dir / "flutter_app.dart"
        content = """
import 'package:flutter/material.dart';

class FlutterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter App'),
        ),
        body: Column(
          children: [
            // Image assets
            Image.asset("assets/images/flutter_logo.png"),
            Image.asset('assets/images/background.jpg'),

            // Icon assets
            Icon(Icons.home),
            ImageIcon(AssetImage("assets/icons/custom_icon.png")),

            // Text with asset references
            Text("Load config from ../tests/parsers/config/app.json"),

            // Network images (should be ignored)
            Image.network("https://example.com/image.png"),

            // File operations
            FutureBuilder(
              future: loadFile("data/content.json"),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? "Loading...");
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Save to "user_data/preferences.json"
            savePreferences();
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Future<String> loadFile(String path) async {
    // Implementation to load from '../tests/parsers/data/default.json'
    return "";
  }

  void savePreferences() {
    // Save to 'user_data/preferences.json'
  }
}

// Widget that loads from multiple asset sources
class AssetWidget extends StatelessWidget {
  final String imagePath = "assets/widgets/default.png";
  final String configPath = 'assets/widgets/config.yaml';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/backgrounds/main.jpg"),
        ),
      ),
      child: Text("Widget content"),
    );
  }
}
"""
        dart_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(dart_file))

        # Should find Flutter asset references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "assets/images/flutter_logo.png",
            "assets/images/background.jpg",
            "assets/icons/custom_icon.png",
            "../tests/parsers/config/app.json",
            "data/content.json",
            "user_data/preferences.json",
            "../tests/parsers/data/default.json",
            "assets/widgets/default.png",
            "assets/widgets/config.yaml",
            "assets/backgrounds/main.jpg",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

        # Should not find network URLs
        assert "https://example.com/image.png" not in targets

    def test_line_and_column_positions(self, temp_project_dir):
        """Test that line and column positions are correctly recorded."""
        parser = DartParser()

        # Create Dart file with known positions
        dart_file = temp_project_dir / "positions.dart"
        content = """
class Config {
  static const String file = "config.json";
  static const String data = 'data.csv';
}
"""
        dart_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(dart_file))

        # Check positions
        for ref in references:
            assert ref.line_number > 0
            assert ref.column_start >= 0
            assert ref.column_end > ref.column_start

            # Verify position makes sense
            lines = content.split("\n")
            if ref.line_number <= len(lines):
                line = lines[ref.line_number - 1]
                if ref.column_end <= len(line):
                    extracted = line[ref.column_start : ref.column_end]
                    # Should contain the link target or be part of the string
                    assert ref.link_target in extracted or ref.link_target in line

    def test_complex_dart_file(self, temp_project_dir):
        """Test parsing a complex Dart file."""
        parser = DartParser()

        # Create complex Dart file
        dart_file = temp_project_dir / "complex.dart"
        content = """
/// Complex Dart application
///
/// Configuration files:
/// - Main config: "pubspec.yaml"
/// - App config: "assets/config/app.yaml"
/// - Build config: 'build.yaml'

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class ComplexApp extends StatefulWidget {
  /// Configuration file path
  static const String configPath = "config/app.json";

  /// Asset paths
  static const Map<String, String> assets = {
    'logo': "assets/images/logo.png",
    'background': 'assets/images/bg.jpg',
    'icon': "assets/icons/app.png",
  };

  /// Data file paths
  static const List<String> dataFiles = [
    "data/users.json",
    "data/products.json",
    'data/orders.csv',
  ];

  @override
  _ComplexAppState createState() => _ComplexAppState();
}

class _ComplexAppState extends State<ComplexApp> {
  /// Load configuration from "config/settings.yaml"
  Future<Map<String, dynamic>> loadConfig() async {
    final file = File("config/settings.yaml");
    // Also check backup config in 'config/backup.yaml'
    final backupFile = File('config/backup.yaml');

    if (await file.exists()) {
      return json.decode(await file.readAsString());
    } else if (await backupFile.exists()) {
      return json.decode(await backupFile.readAsString());
    }

    // Load default from "assets/config/default.json"
    final defaultConfig = await rootBundle.loadString("assets/config/default.json");
    return json.decode(defaultConfig);
  }

  /// Save user preferences to 'user/preferences.json'
  Future<void> savePreferences(Map<String, dynamic> prefs) async {
    final file = File('user/preferences.json');
    await file.writeAsString(json.encode(prefs));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complex App',
      home: Scaffold(
        body: Column(
          children: [
            Image.asset("assets/images/header.png"),
            FutureBuilder(
              future: loadDataFromFile("data/content.json"),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? "Loading...");
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Load data from specified file
  /// Default file is 'data/default.json'
  Future<String> loadDataFromFile(String path) async {
    try {
      final file = File(path);
      return await file.readAsString();
    } catch (e) {
      // Fallback to default file
      final defaultFile = File('data/default.json');
      return await defaultFile.readAsString();
    }
  }
}

/// Utility class for file operations
class FileUtils {
  /// Template directory
  static const String templateDir = "templates/";

  /// Log file path
  static const String logFile = 'logs/app.log';

  /// Database file
  static const String database = "database/app.db";

  /// Load template from "templates/main.html"
  static Future<String> loadTemplate(String name) async {
    final file = File("templates/$name.html");
    return await file.readAsString();
  }

  /// Write log entry to 'logs/debug.log'
  static Future<void> writeLog(String message) async {
    final file = File('logs/debug.log');
    await file.writeAsString("$message\\n", mode: FileMode.append);
  }
}
"""
        dart_file.write_text(content)

        # Parse the file
        references = parser.parse_file(str(dart_file))

        # Should find multiple references
        assert len(references) >= 15

        # Check for expected file references
        targets = [ref.link_target for ref in references]
        expected_targets = [
            "pubspec.yaml",
            "assets/config/app.yaml",
            "build.yaml",
            "config/app.json",
            "assets/images/logo.png",
            "assets/images/bg.jpg",
            "assets/icons/app.png",
            "data/users.json",
            "data/products.json",
            "data/orders.csv",
            "config/settings.yaml",
            "config/backup.yaml",
            "assets/config/default.json",
            "user/preferences.json",
            "assets/images/header.png",
            "data/content.json",
            "data/default.json",
            "templates/",
            "logs/app.log",
            "database/app.db",
            "templates/main.html",
            "logs/debug.log",
        ]

        for expected in expected_targets:
            assert expected in targets, f"Expected target '{expected}' not found in {targets}"

    def test_empty_file(self, temp_project_dir):
        """Test parsing an empty Dart file."""
        parser = DartParser()

        # Create empty file
        dart_file = temp_project_dir / "empty.dart"
        dart_file.write_text("")

        # Parse the file
        references = parser.parse_file(str(dart_file))

        # Should return empty list
        assert references == []

    def test_error_handling(self):
        """Test error handling for invalid files."""
        parser = DartParser()

        # Try to parse non-existent file
        references = parser.parse_file("nonexistent.dart")

        # Should return empty list without crashing
        assert references == []
