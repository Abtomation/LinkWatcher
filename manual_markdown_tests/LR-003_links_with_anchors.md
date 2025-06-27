# LR-003: Links with Anchors

This file tests links that include anchor/fragment identifiers with REAL files.

## Links with anchors:
- [Documentation section](test_project/docs/readme.md#features)
- [Config section](test_project/config/settings.yaml#app)
- [API method](test_project/api/reference.txt#get-users)

## Different anchor formats:
- [Dashed anchor](test_project/docs/readme.md#quick-links)
- [File with anchor](test_project/root.txt#section-1)
- [Another anchor](test_project/file1.txt#content)

## Mixed content:
- [No anchor](test_project/file1.txt)
- [With anchor](test_project/docs/readme.md#documentation)
- [Another no anchor](test_project/file2.txt)

## Complex anchors:
- [Complex anchor](test_project/docs/readme.md#links-to-other-files)

**Expected Results:**
- Should find all file paths with their anchors preserved
- Should handle both files with and without anchors
- Anchors should be preserved in link targets

**Manual Testing:**
- All base files actually exist
- You can move the files to test that anchor links are updated correctly
- Anchors may or may not exist in the actual files, but the parser should still detect the links