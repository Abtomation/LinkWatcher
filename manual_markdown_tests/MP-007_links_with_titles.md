# MP-007: Links with Titles Test

This file tests links with title attributes.

## Links with different title formats:
- [Link 1](file1.txt "This is title 1")
- [Link 2](file2.txt 'Single quote title')
- [Link 3](file3.txt (Parentheses title))

## Reference links with titles:
[ref1]: reference1.txt "Reference title 1"
[ref2]: reference2.txt 'Reference title 2'

## Image with title:
![Image](test_project/manual_test.py "Image title")

## Mixed titles and no titles:
- [No title](no-title.txt)
- [With title](with-title.txt "Has a title")

**Expected Results:**
- Should find: file1.txt, file2.txt, file3.txt, reference1.txt, reference2.txt, image.png, no-title.txt, with-title.txt
- Should extract ONLY the file path, NOT the title text

**Current Parser Issue:**
The parser includes title text in the link target (e.g., 'test_project/test_project/file1.txt "This is title 1"' instead of just test_project/file1.txton/file1.txt/file1.txtn/file1.txt').
