# MP-009: Escaped Characters Test

This file tests handling of escaped markdown characters.

## Links with escaped characters in filenames:
- [Escaped brackets](file\[1\].txt)
- [Escaped parentheses](file\(2\).txt)
- [Escaped backslash](file\\3.txt)

## Escaped link syntax (should NOT be links):
- \[Not a link\](not-link.txt)
- This is \[escaped\] text

## Valid links mixed with escaped text:
- [Real link](real.txt) and \[fake link\](fake.txt)
- \[Escaped\] [Valid link](valid.txt)

## Special characters in filenames:
- [File with spaces](file with spaces.txt)
- [File with dots](file.name.txt)
- [File with dashes](file-name.txt)

**Expected Results:**
- Should find: file\[1\].txt, file\(2\).txt, file\\3.txt, real.txt, valid.txt, file with spaces.txt, file.name.txt, file-name.txt
- Should NOT find: not-link.txt, fake.txt (these are escaped)

**Current Parser Issue:**
The parser doesn't understand escaped markdown syntax and may find escaped links.