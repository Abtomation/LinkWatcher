# LR-001: Standard Links (Parser Level)

This file tests standard markdown link detection at the parser level with REAL files.

## Basic markdown links:
- [Documentation](test_project/docs/readme.md)
- [Configuration](test_project/config/settings.yaml)
- [API Reference](test_project/api/reference.txt)

## Different file types:
- [Text file](test_project/root.txt)
- [YAML config](test_project/config/settings.yaml)
- [Image file](test_project/assets/logo.png)

## Path variations:
- [File 1](test_project/file1.txt)
- [File 2](test_project/file2.txt)
- [Inline reference](test_project/inline.txt)

**Expected Results:**
- Should detect all markdown links correctly
- Should preserve exact link targets
- Should work with various file extensions and paths

**Manual Testing:**
- All referenced files actually exist
- You can move/rename any of these files to test link detection and updates