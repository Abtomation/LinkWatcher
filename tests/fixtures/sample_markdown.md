# Sample Markdown Document

This is a sample markdown document used for testing the LinkWatcher system.

## Links Section

Here are various types of links:

1. [Standard markdown link](target_file.txt)
2. [Link with anchor](document.md#section)
3. [Relative link](../other/file.md)
4. [Link to config](config/settings.yaml)

## File References

This document also references:
- Configuration file: "app_config.json"
- Data file: 'user_data.csv'
- Template file: templates/main.html

## Code Examples

```python
# This code might reference "helper.py"
import helper
```

## External Links (Should be ignored)

- [GitHub](https://github.com)
- [Email](mailto:test@example.com)
- [FTP](ftp://files.example.com)

## Anchor Links (Should be ignored)

- [Introduction](#introduction)
- [Links Section](#links-section)

## Mixed Content

This paragraph has a [markdown link](mixed.txt) and also mentions "another_file.json" in quotes.
