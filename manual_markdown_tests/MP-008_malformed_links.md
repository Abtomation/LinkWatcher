# MP-008: Malformed Links Test

This file tests graceful handling of malformed markdown syntax.

## Valid links (should be found):
- [Valid link](valid.txt)

## Malformed links (graceful handling):
- [Missing closing paren](missing.txt
- [Missing opening paren]missing2.txt)
- [Empty link]()
- [](empty-text.txt)
- [Unmatched [brackets](unmatched.txt)
- [Double [[brackets]]](double.txt)

## Edge cases:
- [Link with \[escaped\] brackets](escaped.txt)
- [Link](file.txt) [Another](file2.txt) multiple on line

## Nested brackets:
- [Text with [nested] brackets](nested.txt)

**Expected Results:**
- Should find: valid.txt, unmatched.txt, escaped.txt, file.txt, file2.txt, nested.txt
- Should handle malformed syntax gracefully without crashing
- May or may not find malformed links (depends on implementation)
