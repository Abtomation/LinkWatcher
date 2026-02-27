# MP-010: Special Characters in Filenames Test

This file tests parsing and updating of references to files with special
characters in their names (spaces, ampersands, parentheses, brackets, etc.).

Regression test for BUG-007: quoted_pattern regex excluded special characters.

## Standard markdown links (should always parse):
- [File with spaces](test_project/file with spaces.txt)
- [File with ampersand](test_project/file & report.txt)
- [File with parentheses](test_project/file (draft).txt)
- [File with brackets](test_project/file [v2].txt)
- [Combined specials](test_project/notes & ideas (2026).md)

## Double-quoted references (BUG-007 fix target):
- "test_project/file with spaces.txt"
- "test_project/file & report.txt"
- "test_project/file (draft).txt"
- "test_project/file [v2].txt"
- "test_project/notes & ideas (2026).md"

## Single-quoted references (BUG-007 fix target):
- 'test_project/file with spaces.txt'
- 'test_project/file & report.txt'
- 'test_project/file (draft).txt'
- 'test_project/file [v2].txt'
- 'test_project/notes & ideas (2026).md'

## Backtick references (intentionally NOT parsed per BUG-011):
- `test_project/file with spaces.txt`
- `test_project/file & report.txt`

## URLs in quotes (should NOT be parsed as file paths):
- "https://example.com/file.txt"
- 'https://cdn.example.com/assets/image.png'
- "ftp://server.example.com/data.csv"

## Mixed line with special chars and normal refs:
- See "test_project/file with spaces.txt" and also [normal link](test_project/file1.txt)

**Expected Results:**
- Standard markdown links: 5 found (all special character filenames)
- Double-quoted refs: 5 found (spaces, ampersand, parens, brackets, combined)
- Single-quoted refs: 5 found (same set)
- Backtick refs: 0 found (not parsed by design)
- URL refs: 0 found (filtered by looks_like_file_path)
- Mixed line: 2 found (quoted ref + markdown link)
- Total: ~17 references

**BUG-007 Verification:**
Before the fix, only the 5 markdown links would be found.
After the fix, all quoted references with special characters are also found.
