# Testing Documentation

This document covers all aspects of testing LinkWatcher, including test cases, procedures, and guidelines.

## 📋 Test Case Categories

### 🚨 **CRITICAL CORE FUNCTIONALITY TESTS**

#### **1. File Movement Detection & Link Updates**

##### **1.1 Basic File Movement**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| FM-001 | Single file rename (same directory) | Rename `file.txt` → `newfile.txt` | All references updated to `newfile.txt` | Critical |
| FM-002 | File move to different directory | Move `docs/file.txt` → `assets/file.txt` | All references updated with new path | Critical |
| FM-003 | File move with rename | Move `docs/old.txt` → `assets/new.txt` | All references updated to new path and name | Critical |
| FM-004 | Directory rename affecting multiple files | Rename `docs/` → `documentation/` | All references to files in directory updated | Critical |
| FM-005 | Nested directory movement | Move `src/utils/` → `src/helpers/` | All nested file references updated | High |

##### **1.2 Link Reference Types**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| LR-001 | Markdown standard links | `[text](file.txt)` with file move | Link updated to new path | Critical |
| LR-002 | Markdown relative links | `[text](../file.txt)` with file move | Relative path correctly updated | Critical |
| LR-003 | Markdown with anchors | `[text](file.txt#section)` with file move | Path updated, anchor preserved | High |
| LR-004 | YAML file references | `file: path/to/file.txt` with file move | YAML value updated | High |
| LR-005 | JSON file references | `{"file": "path/to/file.txt"}` with file move | JSON value updated | High |
| LR-006 | Python imports | `from module import file` with file move | Import statement updated (if supported) | Medium |
| LR-007 | Dart imports | `import 'package:app/file.dart'` with file move | Import path updated | Medium |
| LR-008 | Generic text files | Quoted file references with file move | References updated | Medium |

##### **1.3 Complex Scenarios**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| CS-001 | Multiple references to same file | 5 files referencing `target.txt`, move target | All 5 references updated | Critical |
| CS-002 | Circular references | File A → File B → File A, move File A | Both references updated correctly | High |
| CS-003 | Files with same name in different dirs | Move `docs/file.txt` when `src/file.txt` exists | Only correct references updated | High |
| CS-004 | Case sensitivity handling | Move `File.txt` → `file.txt` on Windows | References updated respecting OS case rules | Medium |
| CS-005 | Special characters in filenames | Move `file with spaces & symbols.txt` | References with special chars updated | Medium |
| CS-006 | Very long file paths | Move file with 200+ char path | Long paths handled correctly | Low |

#### **2. File System Operations**

##### **2.1 Different Movement Methods**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| FSO-001 | VS Code rename (F2) | Rename file via VS Code F2 | Change detected and links updated | Critical |
| FSO-002 | VS Code drag-and-drop | Move file via VS Code explorer | Change detected and links updated | Critical |
| FSO-003 | Windows Explorer drag-and-drop | Move file via Windows Explorer | Change detected and links updated | Critical |
| FSO-004 | Command line mv/move | `mv old.txt new.txt` | Change detected and links updated | High |
| FSO-005 | Git operations | `git mv old.txt new.txt` | Change detected and links updated | High |
| FSO-006 | IDE refactoring operations | Refactor → Rename via IDE | Change detected and links updated | Medium |
| FSO-007 | Batch operations | Move 10 files simultaneously | All changes detected and processed | Medium |

##### **2.2 File Creation & Deletion**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| FCD-001 | New file creation with links | Create file with links to existing files | Links added to database | High |
| FCD-002 | File deletion | Delete file that has references | File removed from database | High |
| FCD-003 | File restoration | Restore deleted file | File re-added to database if links exist | Medium |
| FCD-004 | Temporary file creation | Create .tmp file | Temporary files ignored | Medium |
| FCD-005 | Backup file creation | Create .bak file | Backup files handled appropriately | Low |

#### **3. Parser Accuracy & Edge Cases**

##### **3.1 Markdown Parser**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| MP-001 | Standard links | `[text](link.txt)` | Link correctly parsed and stored | Critical |
| MP-002 | Reference links | `[text][ref]` with `[ref]: link.txt` | Both parts parsed correctly | High |
| MP-003 | Inline code with fake links | `\`[fake](link.txt)\`` | Fake links ignored | High |
| MP-004 | Code blocks with fake links | ```\n[fake](link.txt)\n``` | Fake links ignored | High |
| MP-005 | HTML links in markdown | `<a href="link.txt">text</a>` | HTML links parsed | Medium |
| MP-006 | Image links | `![alt](image.png)` | Image links parsed | Medium |
| MP-007 | Links with titles | `[text](link.txt "title")` | Link parsed, title preserved | Medium |
| MP-008 | Malformed links | `[text](link.txt` (missing closing) | Malformed links ignored | Low |
| MP-009 | Escaped characters | `\[not a link\]` | Escaped text ignored | Low |

##### **3.2 YAML Parser**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| YP-001 | Simple values | `file: path/to/file.txt` | File path parsed correctly | High |
| YP-002 | Nested structures | Complex YAML with file refs | All file paths found | High |
| YP-003 | Arrays | `files: [file1.txt, file2.txt]` | All array items parsed | High |
| YP-004 | Multi-line strings | Multi-line string with file paths | File paths in strings found | Medium |
| YP-005 | Comments with file paths | `# See file.txt` | Comments ignored | Medium |
| YP-006 | YAML anchors and aliases | YAML with &anchor and *alias | Anchors handled correctly | Low |

##### **3.3 JSON Parser**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| JP-001 | String values with file paths | `{"file": "path.txt"}` | File path parsed | High |
| JP-002 | Nested objects | Complex JSON with file refs | All file paths found | High |
| JP-003 | Arrays of file paths | `{"files": ["a.txt", "b.txt"]}` | All array items parsed | High |
| JP-004 | Escaped strings | `{"file": "path\\with\\backslashes.txt"}` | Escaped paths handled | Medium |
| JP-005 | Comments in JSON | JSON with // comments (if supported) | Comments handled appropriately | Low |

##### **3.4 Generic Parser**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| GP-001 | Quoted file paths | `"file.txt"` and `'file.txt'` | Both quote types parsed | High |
| GP-002 | Unquoted file paths | `file.txt` in text | Unquoted paths found | High |
| GP-003 | Mixed with other text | `See file.txt for details` | File path extracted from text | Medium |
| GP-004 | False positives | URLs, emails, version numbers | False positives avoided | High |
| GP-005 | Various file extensions | .txt, .md, .py, .dart, etc. | All extensions recognized | Medium |

#### **4. Database Operations**

##### **4.1 Link Database Management**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| DB-001 | Add links correctly | Add new link reference | Link stored with correct metadata | Critical |
| DB-002 | Remove links on file deletion | Delete file with links | All references removed | Critical |
| DB-003 | Update links on file move | Move referenced file | All references updated | Critical |
| DB-004 | Handle duplicates | Same link referenced multiple times | Duplicates handled correctly | High |
| DB-005 | Path normalization | Various path formats (/, \, ./, ../) | All paths normalized consistently | High |
| DB-006 | Case sensitivity handling | Mixed case paths | Case handled per OS requirements | Medium |
| DB-007 | Thread safety | Concurrent database operations | No race conditions or corruption | High |

##### **4.2 Database Persistence**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| DP-001 | Memory management | Large project (1000+ files) | Memory usage remains reasonable | High |
| DP-002 | Performance with scale | Process 1000+ files | Performance remains acceptable | High |
| DP-003 | Cleanup orphaned references | Remove references to deleted files | Database stays clean | Medium |
| DP-004 | Statistics accuracy | Get database statistics | Counts are accurate | Medium |

#### **5. Configuration & Settings**

##### **5.1 File Type Configuration**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| FC-001 | Monitored extensions customization | Custom extension list | Only specified extensions monitored | High |
| FC-002 | Ignored directories functionality | Custom ignore list | Specified directories ignored | High |
| FC-003 | Custom parsers integration | Add custom parser | Custom parser used for files | Medium |
| FC-004 | Parser enable/disable settings | Disable specific parsers | Disabled parsers not used | Medium |

##### **5.2 Behavior Configuration**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| BC-001 | Dry run mode | Enable dry run | Changes previewed, not applied | High |
| BC-002 | Backup creation | Enable backup creation | .bak files created before changes | High |
| BC-003 | Atomic updates | Enable atomic updates | Files updated safely | High |
| BC-004 | Initial scan enable/disable | Disable initial scan | No initial scan performed | Medium |
| BC-005 | Logging levels | Set different log levels | Appropriate messages logged | Medium |

#### **6. Performance & Scalability**

##### **6.1 Large Project Handling**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| PH-001 | 1000+ files with links | Project with 1000+ linked files | System handles load efficiently | High |
| PH-002 | Deep directory structures | 10+ level deep directories | All levels processed correctly | Medium |
| PH-003 | Large files | Files near size limits | Large files processed or skipped appropriately | Medium |
| PH-004 | Many references to single file | 100+ references to one file | All references updated efficiently | Medium |
| PH-005 | Rapid file operations | Batch move operations | All operations processed correctly | High |

##### **6.2 Resource Management**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| RM-001 | Memory usage monitoring | Monitor memory during operation | Memory usage stays within limits | High |
| RM-002 | CPU usage during operations | Monitor CPU during heavy operations | CPU usage reasonable | Medium |
| RM-003 | File handle management | Open/close many files | File handles managed properly | Medium |
| RM-004 | Thread management and cleanup | Start/stop service multiple times | Threads cleaned up properly | Medium |

#### **7. Error Handling & Recovery**

##### **7.1 File System Errors**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| EH-001 | Permission denied errors | Access restricted file | Error handled gracefully | High |
| EH-002 | File locked by another process | Try to update locked file | Error handled, retry mechanism works | High |
| EH-003 | Disk full during updates | Fill disk during operation | Error handled, no corruption | Medium |
| EH-004 | Network drive disconnection | Disconnect network drive | Error handled gracefully | Low |
| EH-005 | File corruption scenarios | Corrupt file during processing | Error handled, system continues | Medium |

##### **7.2 Parser Errors**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| PE-001 | Invalid file formats | Corrupted YAML/JSON files | Parser errors handled gracefully | High |
| PE-002 | Encoding issues | Files with different encodings | Encoding issues handled | Medium |
| PE-003 | Very large files | Files exceeding size limits | Large files skipped appropriately | Medium |
| PE-004 | Binary files mistakenly processed | Binary file with monitored extension | Binary files detected and skipped | Medium |

##### **7.3 Recovery Scenarios**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| RS-001 | Service restart after crash | Restart service after unexpected exit | Service recovers state correctly | High |
| RS-002 | Database corruption recovery | Corrupt database file | Database rebuilt or recovered | Medium |
| RS-003 | Partial update failures | Failure during batch update | Partial updates handled correctly | Medium |
| RS-004 | Rollback capabilities | Need to undo changes | Rollback mechanism works | Low |

#### **8. Integration & Compatibility**

##### **8.1 Operating System Compatibility**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| OS-001 | Windows compatibility | Run on Windows 10/11 | Full functionality on Windows | Critical |
| OS-002 | Linux compatibility | Run on Ubuntu/CentOS | Full functionality on Linux | High |
| OS-003 | macOS compatibility | Run on macOS | Full functionality on macOS | Medium |
| OS-004 | Path separator handling | Mixed / and \ in paths | Path separators handled correctly | High |
| OS-005 | File system differences | NTFS, ext4, APFS | Works on different file systems | Medium |

##### **8.2 Tool Integration**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| TI-001 | VS Code integration | Use VS Code tasks | Tasks work correctly | High |
| TI-002 | Git workflow compatibility | Use with git operations | Git operations detected correctly | High |
| TI-003 | Command line usage | Use from command line | CLI interface works correctly | High |
| TI-004 | IDE integration | Use with other editors | Works with different IDEs | Medium |

#### **9. User Interface & Feedback**

##### **9.1 Console Output**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| UI-001 | Colored output functionality | Enable colored output | Colors displayed correctly | Medium |
| UI-002 | Progress indicators | Run initial scan | Progress shown during scan | Medium |
| UI-003 | Error messages clarity | Trigger various errors | Error messages are clear and helpful | High |
| UI-004 | Statistics display accuracy | View statistics | Statistics are accurate | Medium |
| UI-005 | Quiet mode functionality | Enable quiet mode | Minimal output in quiet mode | Medium |

##### **9.2 Logging & Debugging**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| LD-001 | Log levels (DEBUG, INFO, WARNING, ERROR) | Set different log levels | Appropriate messages logged at each level | Medium |
| LD-002 | Log file creation and rotation | Enable file logging | Log files created and rotated properly | Low |
| LD-003 | Debug information completeness | Enable debug logging | Sufficient information for debugging | Medium |
| LD-004 | Performance metrics logging | Enable performance logging | Performance data logged correctly | Low |

#### **10. Edge Cases & Stress Tests**

##### **10.1 Unusual Scenarios**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| EC-001 | Empty files and directories | Process empty files/dirs | Empty items handled correctly | Medium |
| EC-002 | Symbolic links handling | Process symbolic links | Symlinks handled appropriately | Medium |
| EC-003 | Hidden files processing | Process hidden files | Hidden files handled per configuration | Low |
| EC-004 | Files with no extensions | Process extensionless files | Handled according to configuration | Low |
| EC-005 | Very short/long filenames | Process extreme filename lengths | Extreme names handled correctly | Low |
| EC-006 | Unicode in file paths and content | Process Unicode files | Unicode handled correctly | Medium |

##### **10.2 Stress Testing**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| ST-001 | Rapid consecutive file operations | Move files rapidly | All operations processed correctly | High |
| ST-002 | Simultaneous file moves | Move multiple files at once | All moves detected and processed | High |
| ST-003 | Service interruption during operations | Stop service during processing | Graceful shutdown, no corruption | High |
| ST-004 | Memory pressure scenarios | Run with limited memory | System handles memory pressure | Medium |
| ST-005 | Disk I/O limitations | Run with slow disk | System handles I/O limitations | Low |

#### **11. Regression Testing**

##### **11.1 Version Compatibility**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| VC-001 | Configuration migration | Upgrade from v1.0 config | Configuration migrated correctly | High |
| VC-002 | Database format compatibility | Use v1.0 database with v2.0 | Database compatibility maintained | High |
| VC-003 | API changes impact | Use v1.0 API calls | Backward compatibility maintained | High |
| VC-004 | Dependency updates compatibility | Update dependencies | System works with new dependencies | Medium |

##### **11.2 Known Issues**
| Test Case ID | Description | Input | Expected Output | Priority |
|--------------|-------------|-------|-----------------|----------|
| KI-001 | Previously fixed bugs don't reoccur | Test scenarios from old bug reports | Old bugs don't reappear | High |
| KI-002 | Performance regressions detection | Compare performance with previous version | No performance regressions | Medium |
| KI-003 | Feature completeness verification | Test all documented features | All features work as documented | High |

## 🧪 Test Execution Guidelines

### **Test Environment Setup**
1. **Prepare test data**: Sample projects with various file types
2. **Set up automation**: Unit tests, integration tests, performance tests
3. **Document procedures**: Manual test steps and validation criteria
4. **Establish baselines**: Performance benchmarks and success criteria

### **Test Execution Order**
1. **Unit Tests**: Individual component testing
2. **Integration Tests**: Component interaction testing
3. **System Tests**: End-to-end workflow testing
4. **Performance Tests**: Load and stress testing
5. **Regression Tests**: Ensure no functionality loss

### **Success Criteria**
- **Functional**: 100% of critical test cases pass
- **Performance**: Meets established benchmarks
- **Reliability**: No data loss or corruption
- **Usability**: Clear error messages and feedback

### **Test Reporting**
- **Test Results**: Pass/fail status for each test case
- **Coverage Reports**: Code coverage metrics
- **Performance Reports**: Benchmark results
- **Issue Reports**: Bugs found and their severity

## 📊 Test Metrics

### **Coverage Targets**
- **Unit Test Coverage**: 90%+
- **Integration Test Coverage**: 80%+
- **Critical Path Coverage**: 100%

### **Performance Targets**
- **File Processing**: < 100ms per file
- **Memory Usage**: < 100MB for 1000 files
- **Startup Time**: < 5 seconds

### **Quality Gates**
- **Zero Critical Bugs**: No critical issues in release
- **Performance Regression**: < 10% performance degradation
- **Backward Compatibility**: 100% API compatibility

---

**This comprehensive test documentation ensures LinkWatcher quality and reliability across all use cases and scenarios.**
