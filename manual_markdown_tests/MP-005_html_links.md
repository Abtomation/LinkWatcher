# MP-005: HTML Links Test

This file tests HTML links in markdown.

## Standard markdown links (should work):
- [Markdown link](markdown.txt)

## HTML links (currently not supported):
- <a href="file1.txt">HTML Link 1</a>
- <a href="docs/file2.md">HTML Link 2</a>
- <a href="config.json" title="Config">Configuration</a>

## Mixed content:
- [Markdown](markdown-file.txt) and <a href="html-file.txt">HTML</a> links

## Various HTML formats:
- <a href='single-quotes.txt'>Single quotes</a>
- <a href="spaces in name.txt">Spaces in filename</a>

**Expected Results:**
- Should find: markdown.txt, file1.txt, docs/file2.md, config.json, markdown-file.txt, html-file.txt, single-quotes.txt, spaces in name.txt

**Current Parser Issue:**
The current parser doesn't support HTML links and may have issues with spaces in filenames.