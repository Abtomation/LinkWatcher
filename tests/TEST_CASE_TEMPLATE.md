# Test Case Template

Use this template to document new test cases consistently.

📖 **For detailed instructions on using this template, see [Test Case Guide](../docs/test-case-guide.md)**

## 📋 Test Case Template

### **Test Case ID**: [Category]-[Number] (e.g., FM-001, LR-005, DB-003)

### **Test Case Title**: [Brief descriptive title]

### **Category**: [File Movement | Link References | Database | Parser | etc.]

### **Priority**: [Critical | High | Medium | Low]

### **Test Type**: [Unit | Integration | System | Performance | Manual]

### **Description**
[Detailed description of what this test case validates]

### **Preconditions**
- [List any setup requirements]
- [Initial state needed]
- [Dependencies that must be met]

### **Test Data**
- [Input files needed]
- [Configuration settings]
- [Environment setup]

### **Test Steps**
1. [Step 1 - Action to perform]
2. [Step 2 - Next action]
3. [Step 3 - Continue...]
4. [Step N - Final action]

### **Expected Results**
- [Expected outcome 1]
- [Expected outcome 2]
- [Expected outcome N]

### **Actual Results**
- [To be filled during test execution]
- [Record what actually happened]

### **Pass/Fail Criteria**
- **Pass**: [Specific conditions that indicate success]
- **Fail**: [Specific conditions that indicate failure]

### **Test Status**: [Not Run | Pass | Fail | Blocked | Skip]

### **Execution Notes**
- [Any observations during test execution]
- [Issues encountered]
- [Variations from expected behavior]

### **Automation Status**: [Manual | Automated | Partially Automated]

### **Automation Script**: [Path to automated test if applicable]

### **Related Test Cases**: [List related test case IDs]

### **Bug References**: [Link to any bugs found during this test]

### **Last Updated**: [Date]
### **Updated By**: [Name]

---

## 📝 Example Test Case

### **Test Case ID**: FM-001

### **Test Case Title**: Single File Rename in Same Directory

### **Category**: File Movement

### **Priority**: Critical

### **Test Type**: Integration

### **Description**
Verify that when a file is renamed in the same directory, all references to that file are correctly updated to use the new filename.

### **Preconditions**
- LinkWatcher service is running
- Test project contains files with links
- File to be renamed exists and has references

### **Test Data**
- Source file: `test.txt`
- Target file: `renamed_test.txt`
- Files with references: `doc1.md`, `doc2.md`, `config.yaml`

### **Test Steps**
1. Start LinkWatcher service in test project directory
2. Verify initial scan completes successfully
3. Confirm `test.txt` exists and has references in database
4. Rename `test.txt` to `renamed_test.txt` using file system operation
5. Wait for LinkWatcher to detect and process the change
6. Verify all reference files have been updated

### **Expected Results**
- LinkWatcher detects the file rename event
- Database is updated to reflect new filename
- All files referencing `test.txt` are updated to reference `renamed_test.txt`
- No references to old filename remain
- File content is preserved except for the link updates
- Console shows successful update messages

### **Actual Results**
[To be filled during execution]

### **Pass/Fail Criteria**
- **Pass**: All references updated correctly, no old references remain, no errors
- **Fail**: Any reference not updated, old references remain, or errors occur

### **Test Status**: Not Run

### **Execution Notes**
[To be filled during execution]

### **Automation Status**: Automated

### **Automation Script**: `tests/test_file_movement.py::test_single_file_rename`

### **Related Test Cases**: FM-002, FM-003, DB-003

### **Bug References**: None

### **Last Updated**: 2024-12-19
### **Updated By**: Test Team

---

📖 **For complete category definitions, ID assignment rules, priority guidelines, and test case management procedures, see [Test Case Guide](../docs/test-case-guide.md)**
