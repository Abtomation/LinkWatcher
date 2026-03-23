# MP-002: Reference Links Test

This file tests reference-style markdown links with REAL files.

## Reference style links:
- [Documentation][doc-ref]
- [Configuration][config-ref]
- [API Guide][api]

## Mixed reference and inline:
- [Inline link](test_project/inline.txt)
- [Reference link][ref1]

## Reference definitions:
[doc-ref]: test_projects/docs/readme.mdd "Documentation"
[config-ref]: test_project/config/settings.yaml[api]: test_project/api/reference.txt"API Documentation"
[ref1]: test_project/file1.txte1.txttion/file8.txttion/file1.txttion/file1.txt

## Unused reference (should still be found):
[unused]: test_project/file2.txttion/file2.txt

**Expected Results:**
- Should find: test_project/inline.txt, test_project/docs/readme.md, test_project/config/settings.yaml, test_project/api/reference.txt, test_project/file1.txt, test_project/file2.txttion/file2.txt
- All these files actually exist and can be moved/renamed for testing!
