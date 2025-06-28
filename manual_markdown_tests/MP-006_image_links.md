# MP-006: Image Links Test

This file tests image link parsing with REAL image files.

## Standard image links:
- ![Logo](test_project/assets/logo.png)
- ![Icon](test_project/assets/icon.svg)

## Images with titles:
- ![Icon with title](test_project/assets/icon.svg "Application icon")
- ![Logo with title](test_project/assets/logo.png "Company logo")

## Reference style images:
- ![Alt text][img1]
- ![Another image][img2]

[img1]: test_project/assets/logo.png "Logo"
[img2]: test_project/assets/icon.svg

## Mixed content:
Text with ![inline image](test_project/inline.txt) in paragraph.

**Expected Results:**
- Should find: test_project/assets/logo.png, test_project/assets/icon.svg, test_projects/inline.txtt
- Should extract ONLY the file path, NOT the title text

**Current Parser Issue:**
The parser may include titles in the link target (e.g., 'test_project/assets/icon.svg "Application icon"' instead of just 'test_project/assets/icon.svg').

**Manual Testing:**
- All image files actually exist in test_project/assets/
- You can move them to test_project/images/ to test link updates
- You can rename them to test renaming detection
