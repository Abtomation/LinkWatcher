---
id: PD-UGD-001
type: Product Documentation
category: User Guide
version: 1.0
created: 2025-01-01
updated: 2025-01-01
---

# File Type Quick Fix Guide

## 🚨 File Type Not Working? Quick Fix!

### Problem: Moving `.xyz` files doesn't update links

**Most Common Cause:** File extension not monitored

**Quick Fix:**
1. Open `linkwatcher/config/defaults.py`
2. Find the `monitored_extensions` section
3. Add your extension:
   ```python
   monitored_extensions={
       # ... existing extensions
       ".xyz",  # Your file type description
   }
   ```
4. Restart LinkWatcher

### Problem: Links inside `.xyz` files don't get updated

**Cause:** No parser for that file type

**Quick Fix:**
- Most file types work with the default generic parser
- If not, you need a custom parser (see full troubleshooting guide)

## 🔧 Common File Types to Add

Copy-paste these into `monitored_extensions`:

```python
# Script files
".ps1",   # PowerShell scripts
".sh",    # Shell scripts
".bat",   # Batch files
".cmd",   # Command files

# Configuration files
".ini",   # INI files
".conf",  # Config files
".cfg",   # Config files
".env",   # Environment files

# Documentation
".rst",   # reStructuredText
".adoc",  # AsciiDoc
".tex",   # LaTeX

# Data files
".sql",   # SQL files
".log",   # Log files
```

## 🧪 Test Your Fix

1. Add the extension to `monitored_extensions`
2. Restart LinkWatcher
3. Check startup log shows your extension in the monitored list
4. Test moving a file of that type
5. Verify links get updated

## 📖 Need More Help?

See the full [Troubleshooting File Types Guide](troubleshooting-file-types.md) for detailed diagnosis and advanced scenarios.
