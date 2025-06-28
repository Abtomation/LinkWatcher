# Test Project

![Logo](assets/logo.png)

This is a test project for manual testing of the LinkWatcher markdown parser.

## Documentation

- [Main Documentation](docs/readmek.md)
- [API Reference](api/reference.txt)
- [Configuration Guide](config/settings.yaml)

## Quick Links

- [Root file](root.txt)
- [File 1](file2.txt) and [File 2](file2.txt)
- [Inline reference](inline.txt)

## Assets

- ![Application Icon](assets/icon.svg)
- ![Logo Image](assets/logo.png)

## Code Examples (should be ignored by parser)

Use this syntax: `[link text](file1.txt)` to create links.

```markdown
# Example markdown - these should be ignored
- [Fake Link 1](fake1.txt)
- [Fake Link 2](fake2.txt)
```

```python
# Python code with fake links
config = "[config](fake-config.txt)"
docs = "[documentation](fake-docs.md)"
```

## Real Links After Code

- [Back to docs](docs/readmek.md)
- [Settings](config/settings.yaml)

---

**Files you can move/rename for testing:**
- `docs/readme.md` → try moving to `documentation/readme.md`
- `config/settings.yaml` → try renaming to `config/app-settings.yaml`
- `api/reference.txt` → try moving to `docs/api-reference.txt`
- `assets/logo.png` → try moving to `images/logo.png`
