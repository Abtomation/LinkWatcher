# MP-001: Standard Links Test

This file tests basic markdown link parsing with REAL files.

## Standard markdown links:
- [Documentation](test_project/docs/readme.md)
- [Configuration](test_project/config/settings.yaml)
- [API Reference](test_project/api/reference.txt)

## Links with different paths:
- [Root file](test_project/root.txt)
- [File 1](test_project/file1.txt)
- [File 2](test_project/file2.txt)

## Mixed content:
Text before [inline link](test_project/inline.txt) and after.

Multiple [link1](test_project/file1.txt) and [link2](test_project/file2.txt) on same line.

**Expected Results:**
- Should find: test_project/docs/readme.md, test_project/config/settings.yaml, test_project/api/reference.txt, test_project/root.txt, test_project/file1.txt, test_project/file2.txt, test_project/inline.txt
- All these files actually exist and can be moved/renamed for testing!