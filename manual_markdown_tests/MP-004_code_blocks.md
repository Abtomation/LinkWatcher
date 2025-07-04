# MP-004: Code Blocks Test

This file tests that links inside code blocks are ignored.

## Real link before code:
[Before code](test_project/file1.txt)

## Code block with fake links (should be IGNORED):
```markdown
# Example markdown - these are fake links
- [Fake link 1](test_project/fake1.txt)
- [Fake link 2](test_project/fake2.txt)
```

```python
# Python code with fake links
config_file = "[config](test_project/fake-config.txt)"
docs = "[documentation](test_project/fake-docs.md)"
```

```
Plain code block
[Another fake](test_project/fake-another.txt)
```

## Real link after code:
[After code](test_project/file2.txt)

**Expected Results:**
- Should find ONLY: test_project/file1.txt, test_project/file2.txttion/file2.txt
- Should NOT find: test_project/fake1.txt, test_project/fake2.txt, test_project/fake-config.txt, test_project/fake-docs.md, test_project/fake-another.txt

**Current Parser Issue:**
The current parser will incorrectly find all the fake links in code blocks because it doesn't understand markdown code block syntax.

**Manual Testing:**
- The real files (file1.txt, file2.txt) exist and can be moved/renamed
- The fake files don't exist, so you can see which links the parser incorrectly finds
