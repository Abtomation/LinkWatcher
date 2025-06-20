# LinkWatcher Multi-Project Setup Guide

This guide explains how to use LinkWatcher across multiple projects from a single installation.

## 🎯 Goal

Use LinkWatcher from any project directory while keeping the tool files in one central location.

**Example Structure:**
```
📁 VS_Code/
├── 📁 LinkWatcher/                    # Tool installation (this directory)
│   ├── link_watcher.py
│   ├── check_links.py
│   ├── install_global.py
│   └── setup_project.py
├── 📁 BreakoutBuddies/
│   └── 📁 breakoutbuddies/            # Your project
│       ├── start_linkwatcher.bat      # Generated convenience script
│       └── .vscode/tasks.json         # Generated VS Code tasks
└── 📁 AnotherProject/                 # Another project
    ├── start_linkwatcher.bat
    └── .vscode/tasks.json
```

## 🚀 Setup Steps

### 1. Install LinkWatcher Globally

From the LinkWatcher directory:
```bash
cd c:/Users/ronny/VS_Code/LinkWatcher
python install_global.py
```

This will:
- Install dependencies
- Copy LinkWatcher files to a global location (e.g., `~/LinkWatcher/`)
- Create wrapper scripts for easy access

### 2. Set Up Each Project

For each project where you want to use LinkWatcher:

```bash
# Navigate to your project
cd c:/Users/ronny/VS_Code/BreakoutBuddies/breakoutbuddies

# Run the project setup (adjust path as needed)
python c:/Users/ronny/VS_Code/LinkWatcher/setup_project.py
```

This will:
- Create convenience scripts in your project directory
- Set up VS Code tasks
- Configure the project to use the global LinkWatcher installation

### 3. Use LinkWatcher

From any project directory:

**Direct Usage:**
```bash
# Start watching (from your project directory)
python /path/to/global/LinkWatcher/link_watcher.py

# Check links once
python /path/to/global/LinkWatcher/check_links.py
```

**Using Convenience Scripts:**
```bash
# Windows
./start_linkwatcher.bat

# Linux/Mac
./start_linkwatcher.sh

# VS Code
# Ctrl+Shift+P → "Tasks: Run Task" → "Start LinkWatcher"
```

## 🔧 How It Works

1. **LinkWatcher automatically detects the current working directory** as the project root
2. **No configuration needed** - just run from your project directory
3. **Each project gets its own monitoring session** when you start LinkWatcher from that directory
4. **Links are updated only within the current project** directory tree

## 📋 Usage Examples

### Example 1: BreakoutBuddies Project
```bash
cd c:/Users/ronny/VS_Code/BreakoutBuddies/breakoutbuddies
python ~/LinkWatcher/link_watcher.py
# Now monitoring: c:/Users/ronny/VS_Code/BreakoutBuddies/breakoutbuddies
```

### Example 2: Another Project
```bash
cd c:/Users/ronny/VS_Code/AnotherProject
python ~/LinkWatcher/link_watcher.py
# Now monitoring: c:/Users/ronny/VS_Code/AnotherProject
```

### Example 3: Specific Subdirectory
```bash
cd c:/Users/ronny/VS_Code/BreakoutBuddies/breakoutbuddies/docs
python ~/LinkWatcher/link_watcher.py
# Now monitoring: c:/Users/ronny/VS_Code/BreakoutBuddies/breakoutbuddies/docs
```

## 🎯 Key Benefits

- ✅ **One installation, multiple projects**
- ✅ **No project-specific configuration required**
- ✅ **Automatic project root detection**
- ✅ **Works from any subdirectory**
- ✅ **VS Code integration per project**
- ✅ **Isolated monitoring per project**

## 🛠️ Advanced Options

### Custom Project Root
If you want to monitor a different directory than your current location:
```bash
python ~/LinkWatcher/link_watcher.py --project-root /path/to/other/directory
```

### Skip Initial Scan
For faster startup on large projects:
```bash
python ~/LinkWatcher/link_watcher.py --no-initial-scan
```

### Quiet Link Checking
```bash
python ~/LinkWatcher/check_links.py --quiet
```

## 🔍 Troubleshooting

### "LinkWatcher not found" Error
- Make sure you ran `install_global.py` first
- Check the installation path shown during installation
- Manually specify the path if needed

### "Permission Denied" Error
- Ensure you have write permissions in your project directory
- On Unix systems, make sure shell scripts are executable

### Links Not Updating
- Verify LinkWatcher is monitoring the correct directory
- Check console output for error messages
- Ensure file extensions are supported (`.md`, `.yaml`, `.py`, etc.)

## 📞 Support

If you encounter issues:
1. Run the test: `python test_workflow.py`
2. Check the console output for error messages
3. Verify file permissions
4. Make sure dependencies are installed

---

**Happy linking across all your projects!** 🔗✨