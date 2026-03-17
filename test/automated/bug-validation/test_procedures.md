# Manual Test Procedures

This document contains manual test procedures for LinkWatcher that require human interaction and cannot be easily automated.

## 🎯 Overview

Manual testing covers:
- **Real-world usage scenarios** - How users actually interact with the system
- **Windows compatibility** - Testing on Windows operating system
- **IDE integration** - Testing with various editors and tools
- **User experience validation** - Ensuring the system is intuitive and reliable
- **Edge cases** - Scenarios that are difficult to automate

## 📋 Test Environment Setup

### **Prerequisites**
- LinkWatcher installed and configured
- Test project with sample files
- Various IDEs/editors available (VS Code, IntelliJ, Notepad++, etc.)
- Windows operating system

### **Test Data Preparation**
Create a test project with:
```
test_project/
├── README.md
├── docs/
│   ├── guide.md
│   ├── api.md
│   └── config.yaml
├── src/
│   ├── main.py
│   ├── utils.py
│   └── config.json
├── assets/
│   ├── logo.png
│   └── styles.css
└── tests/
    ├── test_main.py
    └── fixtures/
        └── sample.json
```

Each file should contain references to other files in the project.

## 🧪 Manual Test Cases

### **MT-001: VS Code Integration**

#### **Objective**
Verify LinkWatcher works correctly with VS Code file operations.

#### **Prerequisites**
- VS Code installed
- LinkWatcher running in test project
- Test project open in VS Code

#### **Test Steps**
1. **Start LinkWatcher**
   ```bash
   cd test_project
   python /path/to/LinkWatcher/link_watcher_new.py
   ```

2. **Verify Initial Scan**
   - Check console output for scan completion
   - Verify no errors reported
   - Note number of files and references found

3. **Test F2 Rename**
   - Select `docs/guide.md` in VS Code Explorer
   - Press F2 to rename
   - Rename to `user-guide.md`
   - **Expected**: LinkWatcher detects change and updates references
   - **Verify**: Check console for update messages
   - **Verify**: Open files that referenced `guide.md` and confirm they now reference `user-guide.md`

4. **Test Drag-and-Drop Move**
   - Drag `src/utils.py` to `src/helpers/` directory (create if needed)
   - **Expected**: LinkWatcher detects move and updates references
   - **Verify**: Check files that imported or referenced `utils.py`

5. **Test Cut-and-Paste Move**
   - Cut `assets/logo.png` (Ctrl+X)
   - Navigate to `assets/images/` (create directory)
   - Paste (Ctrl+V)
   - **Expected**: References in markdown files and CSS updated

#### **Pass Criteria**
- [ ] All file operations detected correctly
- [ ] All references updated accurately
- [ ] No errors in console output
- [ ] VS Code operations feel responsive

#### **Notes**
Record any issues, performance observations, or unexpected behavior.

---

### **MT-002: Windows Explorer Integration**

#### **Objective**
Verify LinkWatcher works with Windows Explorer file operations.

#### **Prerequisites**
- Windows operating system
- LinkWatcher running in test project
- Windows Explorer open to test project

#### **Test Steps**
1. **Test Right-Click Rename**
   - Right-click on `docs/api.md`
   - Select "Rename"
   - Rename to `api-reference.md`
   - **Expected**: LinkWatcher detects and updates references

2. **Test Drag-and-Drop Between Folders**
   - Drag `tests/fixtures/sample.json` to `src/` directory
   - **Expected**: References updated with new path

3. **Test Cut-and-Paste**
   - Right-click `assets/styles.css`
   - Select "Cut"
   - Navigate to `assets/css/` (create directory)
   - Right-click and "Paste"
   - **Expected**: CSS references updated

4. **Test Folder Rename**
   - Right-click `tests/` directory
   - Rename to `testing/`
   - **Expected**: All references to files in tests/ updated to testing/

#### **Pass Criteria**
- [ ] All Windows Explorer operations detected
- [ ] References updated correctly
- [ ] No Windows-specific path issues
- [ ] Performance acceptable for interactive use

---

### **MT-003: Command Line Operations**

#### **Objective**
Verify LinkWatcher works with command-line file operations.

#### **Prerequisites**
- Command prompt/terminal access
- LinkWatcher running in test project

#### **Test Steps**
1. **Test `mv` Command (Linux/macOS) or `move` (Windows)**
   ```bash
   # Linux/macOS
   mv src/main.py src/application.py

   # Windows
   move src\main.py src\application.py
   ```
   - **Expected**: References updated

2. **Test `cp` then `rm` (Linux/macOS) or `copy` then `del` (Windows)**
   ```bash
   # Linux/macOS
   cp docs/config.yaml docs/settings.yaml
   rm docs/config.yaml

   # Windows
   copy docs\config.yaml docs\settings.yaml
   del docs\config.yaml
   ```
   - **Expected**: References updated to new file

3. **Test `mkdir` and `mv` for Directory Operations**
   ```bash
   mkdir documentation
   mv docs/* documentation/
   rmdir docs
   ```
   - **Expected**: All references updated to new directory structure

#### **Pass Criteria**
- [ ] Command-line operations detected
- [ ] Cross-platform compatibility verified
- [ ] Batch operations handled correctly

---

### **MT-004: Git Operations**

#### **Objective**
Verify LinkWatcher works with Git file operations.

#### **Prerequisites**
- Git repository initialized in test project
- LinkWatcher running

#### **Test Steps**
1. **Test `git mv`**
   ```bash
   git mv README.md PROJECT_README.md
   ```
   - **Expected**: References updated

2. **Test Branch Switching with File Changes**
   ```bash
   git checkout -b feature-branch
   git mv src/utils.py src/helpers.py
   git add .
   git commit -m "Rename utils to helpers"
   git checkout main
   ```
   - **Expected**: LinkWatcher handles branch switches gracefully

3. **Test Merge Conflicts with File Moves**
   - Create conflicting file moves in different branches
   - Attempt merge
   - **Expected**: LinkWatcher doesn't interfere with Git operations

#### **Pass Criteria**
- [ ] Git operations work normally
- [ ] LinkWatcher doesn't conflict with Git
- [ ] File moves via Git detected correctly

---

### **MT-005: Multiple IDE Testing**

#### **Objective**
Test LinkWatcher with various IDEs and editors.

#### **Test IDEs**
- IntelliJ IDEA / PyCharm
- Sublime Text
- Notepad++
- Atom (if available)
- Vim/Emacs (if available)

#### **Test Steps**
For each IDE:

1. **Open test project**
2. **Perform file rename operation**
3. **Perform file move operation**
4. **Verify LinkWatcher detects changes**
5. **Check for any IDE-specific issues**

#### **Pass Criteria**
- [ ] Works with major IDEs
- [ ] No IDE-specific conflicts
- [ ] Consistent behavior across editors

---

### **MT-006: Performance and Responsiveness**

#### **Objective**
Evaluate user experience and system responsiveness.

#### **Test Steps**
1. **Large Project Test**
   - Create project with 500+ files
   - Start LinkWatcher
   - Measure initial scan time
   - **Expected**: Completes within reasonable time (< 30 seconds)

2. **Rapid Operations Test**
   - Perform multiple file moves quickly
   - **Expected**: System remains responsive
   - **Expected**: All operations processed correctly

3. **Background Operation Test**
   - Start LinkWatcher
   - Continue normal development work
   - **Expected**: No noticeable impact on system performance

#### **Pass Criteria**
- [ ] Initial scan completes in reasonable time
- [ ] System remains responsive during operations
- [ ] No significant impact on development workflow

---

### **MT-007: Error Handling and Recovery**

#### **Objective**
Test system behavior under error conditions.

#### **Test Steps**
1. **Permission Denied Test**
   - Make a file read-only
   - Try to move it
   - **Expected**: Graceful error handling

2. **Disk Full Test** (if safe to test)
   - Fill disk space
   - Attempt file operations
   - **Expected**: Appropriate error messages

3. **Network Drive Test** (if available)
   - Test with files on network drives
   - **Expected**: Works or fails gracefully

4. **Service Interruption Test**
   - Stop LinkWatcher during operation
   - Restart
   - **Expected**: Recovers state correctly

#### **Pass Criteria**
- [ ] Errors handled gracefully
- [ ] Clear error messages provided
- [ ] System recovers from interruptions

---

### **MT-008: Windows Compatibility**

#### **Objective**
Verify consistent behavior on Windows operating system.

#### **Test Platform**
- Windows 10/11

#### **Test Steps**
For each platform:

1. **Install and run LinkWatcher**
2. **Test basic file operations**
3. **Test path handling (/ vs \)**
4. **Test case sensitivity behavior**
5. **Test special characters in filenames**

#### **Pass Criteria**
- [ ] Consistent behavior across platforms
- [ ] Proper path handling for each OS
- [ ] Case sensitivity handled correctly

---

### **MT-009: Configuration and Customization**

#### **Objective**
Test configuration options and customization features.

#### **Test Steps**
1. **Test Custom Configuration File**
   ```yaml
   # custom_config.yaml
   monitored_extensions:
     - .md
     - .txt
   ignored_directories:
     - node_modules
     - .git
   dry_run_mode: true
   ```
   - Run with: `python main.py --config custom_config.yaml`

2. **Test Command Line Options**
   ```bash
   python main.py --dry-run
   python main.py --quiet
   python main.py --no-initial-scan
   ```

3. **Test File Type Filtering**
   - Configure to monitor only .md files
   - Move .py file
   - **Expected**: .py move ignored, .md moves processed

#### **Pass Criteria**
- [ ] Configuration options work correctly
- [ ] Command line arguments respected
- [ ] File filtering works as expected

---

### **MT-010: User Experience Validation**

#### **Objective**
Evaluate overall user experience and usability.

#### **Test Steps**
1. **First-Time User Experience**
   - Install LinkWatcher fresh
   - Follow documentation to set up
   - **Evaluate**: How intuitive is the setup process?

2. **Daily Usage Simulation**
   - Use LinkWatcher during normal development
   - Perform typical file operations
   - **Evaluate**: Does it enhance or hinder workflow?

3. **Error Recovery Experience**
   - Intentionally cause errors
   - **Evaluate**: Are error messages helpful?
   - **Evaluate**: Is recovery process clear?

#### **Pass Criteria**
- [ ] Setup process is straightforward
- [ ] Enhances development workflow
- [ ] Error messages are helpful and actionable

---

## 📊 Test Execution Tracking

### **Test Session Information**
- **Date**: ___________
- **Tester**: ___________
- **Environment**: ___________
- **LinkWatcher Version**: ___________

### **Test Results Summary**
| Test Case | Status | Notes |
|-----------|--------|-------|
| MT-001 | ⬜ Pass ⬜ Fail | |
| MT-002 | ⬜ Pass ⬜ Fail | |
| MT-003 | ⬜ Pass ⬜ Fail | |
| MT-004 | ⬜ Pass ⬜ Fail | |
| MT-005 | ⬜ Pass ⬜ Fail | |
| MT-006 | ⬜ Pass ⬜ Fail | |
| MT-007 | ⬜ Pass ⬜ Fail | |
| MT-008 | ⬜ Pass ⬜ Fail | |
| MT-009 | ⬜ Pass ⬜ Fail | |
| MT-010 | ⬜ Pass ⬜ Fail | |

### **Overall Assessment**
- **Critical Issues Found**: ___________
- **Performance Observations**: ___________
- **User Experience Rating** (1-10): ___________
- **Recommendations**: ___________

## 🚨 Issue Reporting

When issues are found during manual testing:

1. **Document the issue clearly**
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details
   - Screenshots if applicable

2. **Classify the severity**
   - Critical: System unusable or data loss
   - High: Major functionality broken
   - Medium: Minor functionality issues
   - Low: Cosmetic or edge case issues

3. **Report through appropriate channels**
   - Create detailed bug report
   - Include test case reference
   - Provide reproduction steps

---

**These manual test procedures ensure LinkWatcher works correctly in real-world usage scenarios and provides a good user experience across different environments and workflows.**
