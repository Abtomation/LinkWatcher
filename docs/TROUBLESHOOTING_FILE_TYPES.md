# Troubleshooting File Type Monitoring Issues

This guide helps you diagnose and fix issues when certain file types are not being monitored for link updates during move/rename operations.

## 🚨 Quick Diagnosis

If moving/renaming files of a specific type (e.g., `.ps1`, `.sh`, `.bat`) doesn't trigger link updates, follow this checklist:

### 1. Check if File Type is Monitored

**Symptom:** Moving the file doesn't update links, but renaming works partially or not at all.

**Check:** Look at the startup log when LinkWatcher starts:
```
🔧 Configuration:
   • Monitored extensions: .css, .csv, .dart, .gif, .htm, .html, .ico, .jpeg, .jpg, .js, .json, .jsx, .md, .mp3, .mp4, .pdf, .php, .png, .py, .svg, .ts, .tsx, .txt, .vue, .wav, .webp, .xml, .yaml, .yml
```

**Solution:** If your file extension is missing, add it to the monitored extensions.

### 2. Check if File Type has Parser Support

**Symptom:** File type is monitored, but links inside those files are not being parsed/updated.

**Check:** Look for parsing errors in the logs or test if the file type is being parsed during initial scan.

**Solution:** Add parser support for the file type.

## 🔧 Step-by-Step Troubleshooting

### Step 1: Verify File Extension Monitoring

1. **Check Current Configuration**
   ```bash
   # Start LinkWatcher and look for this line in the output:
   # • Monitored extensions: [list of extensions]
   ```

2. **Check Default Configuration**
   - Open `linkwatcher/config/defaults.py`
   - Look for your file extension in the `monitored_extensions` set
   - Example:
   ```python
   monitored_extensions={
       ".md",   # Markdown files
       ".py",   # Python files
       ".ps1",  # PowerShell scripts  ← Should be here
       # ... other extensions
   }
   ```

3. **Add Missing Extension**
   ```python
   # Add your extension to the monitored_extensions set
   ".your_ext",  # Your file type description
   ```

### Step 2: Verify Parser Support

1. **Check if Parser Exists**
   - Look in `linkwatcher/parsers/` directory
   - Common parsers: `markdown.py`, `python.py`, `generic.py`

2. **Check Parser Registration**
   - Open `linkwatcher/parser.py`
   - Look for your file extension in the parser mapping:
   ```python
   def _get_parser_for_file(self, file_path: str):
       ext = Path(file_path).suffix.lower()
       
       if ext == ".md":
           return MarkdownParser()
       elif ext == ".py":
           return PythonParser()
       elif ext == ".your_ext":  # ← Should be here
           return YourParser()
       else:
           return GenericParser()
   ```

### Step 3: Test the Fix

1. **Create Test Files**
   ```bash
   # Create a test file of your type
   echo "content with link to other_file.ext" > test_file.your_ext
   
   # Create a markdown file that references it
   echo "[Link](test_file.your_ext)" > test_reference.md
   ```

2. **Start LinkWatcher**
   ```bash
   python main.py
   ```

3. **Test Move Operation**
   - Move `test_file.your_ext` to a different location
   - Check if `test_reference.md` gets updated

## 🛠️ Common File Type Fixes

### Adding Script File Types

For script files (`.ps1`, `.sh`, `.bat`, `.cmd`):

1. **Add to Monitored Extensions**
   ```python
   # In linkwatcher/config/defaults.py
   monitored_extensions={
       # ... existing extensions
       ".ps1",  # PowerShell scripts
       ".sh",   # Shell scripts
       ".bat",  # Batch files
       ".cmd",  # Command files
   }
   ```

2. **Parser Support**
   - Most script files can use the `GenericParser`
   - No additional parser needed unless you want to parse links inside the scripts

### Adding Configuration File Types

For config files (`.ini`, `.conf`, `.cfg`):

1. **Add to Monitored Extensions**
   ```python
   # In linkwatcher/config/defaults.py
   monitored_extensions={
       # ... existing extensions
       ".ini",   # INI configuration files
       ".conf",  # Configuration files
       ".cfg",   # Configuration files
   }
   ```

### Adding Documentation File Types

For documentation (`.rst`, `.adoc`, `.tex`):

1. **Add to Monitored Extensions**
   ```python
   # In linkwatcher/config/defaults.py
   monitored_extensions={
       # ... existing extensions
       ".rst",   # reStructuredText
       ".adoc",  # AsciiDoc
       ".tex",   # LaTeX
   }
   ```

2. **Consider Custom Parser**
   - These formats may need custom parsers for proper link detection

## 🔍 Debugging Tools

### Enable Debug Logging

1. **Create Debug Config**
   ```yaml
   # debug-config.yaml
   logging:
     level: DEBUG
     handlers:
       console:
         level: DEBUG
   ```

2. **Run with Debug Config**
   ```bash
   python main.py --config debug-config.yaml
   ```

### Manual Testing Script

Create a test script to verify file type handling:

```python
#!/usr/bin/env python3
"""Test file type monitoring."""

import tempfile
from pathlib import Path
from linkwatcher.parser import LinkParser
from linkwatcher.database import LinkDatabase

def test_file_type(extension, content):
    """Test if a file type is properly handled."""
    temp_dir = Path(tempfile.mkdtemp())
    test_file = temp_dir / f"test{extension}"
    test_file.write_text(content)
    
    parser = LinkParser()
    db = LinkDatabase()
    
    # Test parsing
    try:
        refs = parser.parse_file(str(test_file))
        print(f"✅ {extension}: Found {len(refs)} references")
        for ref in refs:
            print(f"   - {ref.link_target} ({ref.link_type})")
    except Exception as e:
        print(f"❌ {extension}: Parsing failed - {e}")
    
    # Cleanup
    import shutil
    shutil.rmtree(temp_dir, ignore_errors=True)

# Test your file type
test_file_type(".your_ext", "content with [link](other_file.ext)")
```

## 📋 Checklist for New File Types

When adding support for a new file type:

- [ ] Add extension to `monitored_extensions` in `defaults.py`
- [ ] Test that file moves trigger events
- [ ] Verify that links TO these files get updated
- [ ] Test that links INSIDE these files get parsed (if needed)
- [ ] Add parser support if the file type contains links
- [ ] Update documentation
- [ ] Add test cases

## 🚨 Common Pitfalls

1. **Case Sensitivity**
   - Extensions are case-sensitive in some contexts
   - Always use lowercase in configuration: `.PS1` → `.ps1`

2. **Parser vs Monitoring**
   - Monitoring = detecting when files move
   - Parsing = finding links inside files
   - You need monitoring for the file to trigger updates
   - You need parsing for links inside the file to be updated

3. **Generic Parser Limitations**
   - The generic parser may not catch all link formats
   - Consider custom parser for complex file types

4. **Configuration Caching**
   - Restart LinkWatcher after configuration changes
   - Configuration is loaded at startup

## 📞 Getting Help

If you're still having issues:

1. **Check the logs** for error messages
2. **Enable debug logging** for detailed information
3. **Test with minimal examples** to isolate the issue
4. **Verify the file extension** is exactly as expected (case, spelling)

## 🔗 Related Documentation

- [Configuration Guide](../QUICK_REFERENCE.md#configuration)
- [Parser Development](../HOW_IT_WORKS.md#parsers)
- [Logging Guide](LOGGING.md)