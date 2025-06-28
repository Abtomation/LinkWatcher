# LR-002: Relative Links

This file tests relative path link parsing with REAL files.

## Relative path variations:
- [Current directory](file1.txt)
- [Explicit current](../../test_project/documentation/readme.md)
- [Test project root](root.txt)

## Different relative formats:
- [Config file](config/settings.yaml)
- [API docs](api/reference.txt)
- [Assets](assets/logo.png)

## Mixed with different paths:
- [File 1](file1.txt)
- [File 2](file2.txt)
- [Inline](inline.txt)

**Expected Results:**
- Should handle all relative path formats
- Should preserve relative path syntax
- Should work with complex path navigation

**Manual Testing:**
- All files exist in the test_project directory
- You can move files between subdirectories to test relative path updates
- Try moving documentation/readme.md to documentation/readme.md
