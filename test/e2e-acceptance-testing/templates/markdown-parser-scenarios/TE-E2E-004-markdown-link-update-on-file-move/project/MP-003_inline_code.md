# MP-003: Inline Code Test

This file tests that links inside inline code are ignored.

## Real links (should be found):
- [Real documentation](test_project/docs/readme.md)
- [Configuration guide](test_project/config/settings.yaml)

## Fake links in inline code (should be IGNORED):
- Use `[fake link](test_project/fake.txt)` syntax for markdown links
- The pattern is `[text](url)` for creating links
- Example: `[config](test_project/fake-config.yaml)` creates a link

## Mixed content:
- Real [working link](test_project/root.txt) and fake `[code example](test_project/fake-example.txt)` link

**Expected Results:**
- Should find ONLY: test_project/docs/readme.md, test_project/config/settings.yaml, test_projects/root.txtt
- Should NOT find: test_project/fake.txt, url, test_project/fake-config.yaml, test_project/fake-example.txt

**Current Parser Issue:**
The current parser will incorrectly find the fake links in backticks because it doesn't understand markdown syntax.

**Manual Testing:**
- The real files exist and can be moved/renamed
- The fake files don't exist, so you can see the difference in behavior
