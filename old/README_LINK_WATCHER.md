# Real-time Link Maintenance System

A modern, reliable link maintenance system that uses file system watching to detect file movements and automatically update all references in real-time.

## 🚀 Quick Start

### 1. Install LinkWatcher Globally
```bash
# In the LinkWatcher directory
python install_global.py
```

### 2. Set Up Your Project
```bash
# In your project directory (e.g., VS_Code/BreakoutBuddies/breakoutbuddies)
python /path/to/LinkWatcher/setup_project.py
```

### 3. Start the Watcher
```bash
# From your project directory
python /path/to/LinkWatcher/link_watcher.py

# Or use convenience scripts created by setup:
./start_linkwatcher.bat  # Windows
./start_linkwatcher.sh   # Linux/Mac

# VS Code: Ctrl+Shift+P → "Tasks: Run Task" → "Start LinkWatcher"
```

### 4. Test It!
- Move any file using drag-and-drop, VS Code rename, or git commands
- Watch as links are updated automatically in real-time! 🎉

## 🌟 Multi-Project Workflow

LinkWatcher is designed to work across multiple projects:

### Installation Pattern
```
📁 VS_Code/
├── 📁 LinkWatcher/           # Tool installation
│   ├── link_watcher_old.py
│   ├── check_links.py
│   └── install_global.py
├── 📁 BreakoutBuddies/
│   └── 📁 breakoutbuddies/   # Your project
│       ├── start_linkwatcher.bat
│       └── .vscode/tasks.json
└── 📁 AnotherProject/        # Another project
    ├── start_linkwatcher.bat
    └── .vscode/tasks.json
```

### Usage Example
```bash
# Install once globally
cd VS_Code/LinkWatcher
python install_global.py

# Set up each project
cd ../BreakoutBuddies/breakoutbuddies
python ../../LinkWatcher/setup_project.py

# Use from project directory
python /path/to/LinkWatcher/link_watcher.py
# LinkWatcher monitors THIS directory automatically!
```

📖 **For detailed setup instructions, see [MULTI_PROJECT_SETUP.md](MULTI_PROJECT_SETUP.md)**

## 🔧 Components

### Core Files
- **`link_watcher.py`** - Main file system watcher service
- **`check_links.py`** - Standalone link checker utility
- **`install_global.py`** - Global installation script
- **`setup_project.py`** - Project-specific setup script

### Generated Files (per project)
- **`start_linkwatcher.bat/ps1/sh`** - Convenience scripts to start the service
- **`.vscode/tasks.json`** - VS Code tasks for running the watcher
- **`requirements.txt`** - Python dependencies

## 🎯 Key Features

### ✅ **Works with Your Preferred Workflow**
- **File Explorer**: Drag-and-drop files ✅
- **VS Code**: Built-in rename/move operations ✅
- **Git Commands**: `git mv` and `git rm` ✅
- **Any Method**: Terminal, scripts, other editors ✅

### ✅ **Real-time Updates**
- Links update **immediately** when files are moved
- No need to remember to run scripts
- Background service monitors continuously

### ✅ **More Reliable**
- No complex git status parsing
- No missed renames or false detections
- Proper file parsing instead of regex

### ✅ **Better Performance**
- Only processes actual file changes
- No full project scans on every operation
- Efficient in-memory link database

## 📋 Usage Examples

### Basic Usage (from any project directory)
```bash
# Start the watcher (runs continuously in current directory)
python /path/to/LinkWatcher/link_watcher.py

# Check links once (no watching)
python /path/to/LinkWatcher/check_links.py

# Check links and save results
python /path/to/LinkWatcher/check_links.py --output my_results.txt
```

### Advanced Options
```bash
# Skip initial scan (faster startup)
python /path/to/LinkWatcher/link_watcher.py --no-initial-scan

# Specify different project root
python /path/to/LinkWatcher/link_watcher.py --project-root /path/to/other/project

# Quiet link checking
python /path/to/LinkWatcher/check_links.py --quiet
```

### Using Convenience Scripts (after project setup)
```bash
# From your project directory
./start_linkwatcher.bat    # Windows
./start_linkwatcher.sh     # Linux/Mac

# VS Code
# Ctrl+Shift+P → "Tasks: Run Task" → "Start LinkWatcher"
```

## 🛠️ How It Works

### File System Watcher Architecture
```
File Operation (any method)
    ↓
Watchdog detects file system event
    ↓
Link Database identifies affected references
    ↓
Link Updater modifies files with proper parsing
    ↓
Changes are ready for git commit
```

### Supported File Types
- **Markdown** (`.md`) - Full markdown link parsing
- **YAML** (`.yaml`, `.yml`) - File reference detection
- **Dart** (`.dart`) - Import/file references (excluding packages)
- **Python** (`.py`) - File references in strings/comments
- **JSON** (`.json`) - File path values
- **Text** (`.txt`) - Simple file references

### Link Types Detected
- **Markdown links**: `[text](path)` and `[label]: path`
- **Direct file references**: `/path/to/file.ext`
- **Relative paths**: `../other/file.md`
- **Anchored links**: `file.md#section`

## 🔍 Link Checking

### Standalone Link Checker
```bash
# Check all links and show results
python scripts/check_links.py

# Save results to file
python scripts/check_links.py --output broken_links.txt

# Quiet mode (summary only)
python scripts/check_links.py --quiet
```

### What Gets Checked
- ✅ File existence
- ✅ Path validity
- ✅ Project boundary (security)
- ❌ External URLs (skipped)
- ❌ Package references (skipped)
- ❌ Anchor-only links (skipped)

## 🎛️ Configuration

### Monitored Extensions
Edit `link_watcher.py` to change which file types are monitored:
```python
self.monitored_extensions = {'.md', '.yaml', '.yml', '.dart', '.py', '.json', '.txt'}
```

### Ignored Directories
Directories automatically skipped:
```python
self.ignored_dirs = {'.git', '.dart_tool', 'node_modules', '.vscode', 'build', 'dist'}
```

### VS Code Integration
The setup script automatically creates VS Code tasks:
- **"Start Link Watcher"** - Start the background service
- **"Check Links"** - Run link checker once

Access via: `Ctrl+Shift+P` → `Tasks: Run Task`

## 🐛 Troubleshooting

### Common Issues

**"Missing required dependency" error**
```bash
pip install -r scripts/requirements.txt
```

**Watcher not detecting changes**
- Ensure you're in the project root directory
- Check that the file extensions are in `monitored_extensions`
- Verify the directories aren't in `ignored_dirs`

**Links not updating correctly**
- Check the console output for error messages
- Verify file permissions (watcher needs write access)
- Test with `python scripts/check_links.py` to see current state

**Performance issues**
- Use `--no-initial-scan` for faster startup
- Consider reducing `monitored_extensions` if not needed

### Debug Mode
Add debug output by modifying the script:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Getting Help
1. Check the console output for error messages
2. Run `python scripts/check_links.py` to see current link status
3. Review the troubleshooting steps above
4. Check file permissions if the watcher can't update files

## 📈 Key Benefits

### For Developers
- 🎯 **Use your preferred workflow** - drag-and-drop, VS Code, git commands
- ⚡ **Instant feedback** - see links update in real-time
- 🛡️ **Reliable** - no more broken links from missed renames
- 🧘 **Peace of mind** - runs automatically in background

### For Projects
- 📚 **Better documentation** - links stay current automatically
- 🔄 **Easier refactoring** - move files without breaking references
- 👥 **Team friendly** - works regardless of individual workflows
- 🚀 **Improved productivity** - less time fixing broken links

## 🔮 Future Enhancements

Potential improvements for future versions:
- **IDE Extensions** - Native VS Code/IntelliJ integration
- **Git Integration** - Automatic commit of link updates
- **Link Analytics** - Track link usage and health over time
- **Batch Operations** - Handle large-scale file reorganizations
- **Remote Monitoring** - Web dashboard for link status

---

## 📞 Support

This modern, reliable link maintenance system provides seamless file reference management. If you encounter any issues or have suggestions for improvements, please check the troubleshooting section above.

**Happy linking!** 🔗✨
