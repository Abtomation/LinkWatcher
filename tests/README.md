# LinkWatcher Test Suite

This directory contains the comprehensive test suite for LinkWatcher, including automated tests, manual procedures, and test documentation.

## 📋 Test Documentation Files

### **../tests/../tests/../test/../test/TEST_PLAN.md** - Test Strategy & Procedures
**Purpose**: High-level test planning and strategy document
**Contains**:
- Test methodology and approach
- Test execution matrices organized by priority (P0-P3)
- Environment setup and configuration
- Risk assessment and mitigation strategies
- Manual test procedures and checklists

**When to use**:
- Planning test execution campaigns
- Understanding test strategy and priorities
- Setting up test environments
- Conducting manual testing procedures

### **../tests/../tests/../tests/../tests/../tests/../test/../test/../test/../test/../test/TEST_CASE_STATUS.md** - Implementation Tracking & Mapping
**Purpose**: Complete tracking of test case implementation status
**Contains**:
- Mapping of all 111 test cases to their exact implementations
- Test execution metrics and infrastructure status
- Implementation status by priority and category
- Test execution commands and debugging information
- Quality metrics and coverage analysis

**When to use**:
- Finding the exact implementation of a specific test case
- Checking implementation status and coverage
- Understanding test execution metrics
- Locating test methods by test case ID
- Tracking test infrastructure status

### **../tests/../tests/../test/../test/TEST_CASE_TEMPLATE.md** - New Test Case Template
**Purpose**: Template for creating new test cases
**When to use**: Adding new test cases to the suite

## 🗂️ Directory Structure

```
tests/
├── unit/                          # Unit tests (35+ methods)
│   ├── test_config.py            # Configuration management tests
│   ├── test_database.py          # Database operations tests
│   ├── test_parser.py            # Parser unit tests
│   ├── test_service.py           # Service layer tests
│   └── test_updater.py           # Link updater tests
├── integration/                   # Integration tests (45+ methods)
│   ├── test_complex_scenarios.py # Complex file operation scenarios
│   ├── test_error_handling.py    # Error handling and recovery
│   ├── test_file_movement.py     # File movement detection
│   ├── test_link_updates.py      # Link update operations
│   ├── test_service_integration.py # Service integration tests
│   └── test_windows_platform.py  # Windows-specific tests
├── parsers/                       # Parser tests (80+ methods)
│   ├── test_dart.py              # Dart file parser tests
│   ├── test_generic.py           # Generic text parser tests
│   ├── test_json.py              # JSON parser tests
│   ├── test_markdown.py          # Markdown parser tests
│   ├── test_python.py            # Python parser tests
│   └── test_yaml.py              # YAML parser tests
├── performance/                   # Performance tests (5+ methods)
│   └── test_large_projects.py    # Large project handling tests
├── manual/                        # Manual testing procedures
│   ├── test_procedures.md         # Manual test cases and checklists
│   └── manual_test/              # Manual test project structure
├── fixtures/                      # Test data and sample files
│   ├── sample_markdown.md         # Sample markdown for testing
│   ├── sample_config.yaml         # Sample YAML configuration
│   └── sample_data.json           # Sample JSON data
├── conftest.py                    # Pytest configuration and fixtures
├── utils.py                       # Test utilities and helpers
├── TEST_PLAN.md                   # Test strategy and procedures
├── TEST_CASE_STATUS.md            # Test case implementation tracking
└── TEST_CASE_TEMPLATE.md          # Template for new test cases
```

## 🚀 Quick Start

### **1. Install Dependencies**
```bash
pip install ".[test]"
```

### **2. Run Quick Development Tests**
```bash
python run_tests.py --quick
```

### **3. Run All Tests**
```bash
python run_tests.py --all --coverage
```

### **4. Run by Category**
```bash
python run_tests.py --unit --verbose    # Unit tests only
python run_tests.py --integration       # Integration tests only
python run_tests.py --parsers          # Parser tests only
python run_tests.py --performance      # Performance tests
python run_tests.py --critical         # Critical tests only
```

### **5. Advanced Test Execution**
```bash
# Verbose output with details
pytest -v

# Stop on first failure
pytest -x

# Run specific test file
pytest unit/test_database.py

# Run specific test method
pytest tests/unit/test_database.py::TestLinkDatabase::test_add_reference

# Run tests by marker
pytest -m "critical"
pytest -m "unit"
pytest -m "integration"

# Run tests matching pattern
pytest -k "test_file_movement"
pytest -k "parser"

# Exclude slow tests
pytest -m "not slow"
```

### **6. Coverage Analysis**
```bash
# Generate coverage report
python run_tests.py --coverage

# View coverage by file
coverage report --show-missing

# Generate HTML coverage report
# Open htmlcov/index.html in browser

# Coverage with specific threshold
pytest --cov=linkwatcher --cov-fail-under=90
```

### Find Test Implementation
1. Look up test case ID (e.g., FM-001) in **../tests/../tests/../tests/../tests/../tests/../test/../test/../test/../test/../test/TEST_CASE_STATUS.md**
2. Find the exact test method and file location
3. Navigate to the implementation file

### Check Test Status
- **Overall status**: See TEST_CASE_STATUS.md overview section
- **Specific test case**: Look up test ID in the mapping tables
- **Coverage metrics**: Check the quality metrics section

## 📊 Test Metrics

- **Total Test Cases**: 111 documented test cases
- **Implementation Coverage**: 100%
- **Automated Test Methods**: 165+ methods
- **Manual Procedures**: 10 procedures
- **Test Pass Rate**: 100%

## 🐛 Troubleshooting Test Issues

### **Common Issues and Solutions**

#### **Import Errors**
```bash
# Fix Python path issues
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Install in development mode
pip install -e .
```

#### **Permission Errors**
```bash
# On Windows, run as administrator for some tests
# On Unix, ensure proper file permissions
chmod +x run_tests.py
```

#### **Temporary Directory Issues**
```bash
# Clean up test artifacts
rm -rf /tmp/linkwatcher_test_*

# Set custom temp directory
export TMPDIR=/path/to/custom/temp
```

#### **Database Lock Issues**
```bash
# Remove test database files
find . -name "*.db" -path "*/test*" -delete

# Ensure proper test isolation
pytest --forked
```

## 📈 Performance Benchmarks

### **Expected Performance**
- **Initial Scan**: < 30 seconds for 1000 files
- **File Move Processing**: < 5 seconds for single file
- **Batch Operations**: < 10 seconds for 50 files
- **Memory Usage**: < 100MB for typical projects

### **Coverage Targets**
- **Overall Coverage**: 90%+
- **Critical Path Coverage**: 100%
- **Parser Coverage**: 95%+
- **Database Coverage**: 100%

## 🎯 For AI Assistants

**Key Points**:
1. **../tests/../tests/../test/../test/TEST_PLAN.md** = Strategy and procedures (what to test, how to test)
2. **../tests/../tests/../tests/../tests/../tests/../test/../test/../test/../test/../test/TEST_CASE_STATUS.md** = Implementation tracking (where tests are implemented, current status)
3. All 111 test cases from `docs/testing.md` are fully implemented
4. Use TEST_CASE_STATUS.md to find exact test method locations
5. Test case IDs follow pattern: [Category]-[Number] (e.g., FM-001, LR-002)

**Common Tasks**:
- Finding test implementation → Check TEST_CASE_STATUS.md mapping tables
- Understanding test strategy → Read TEST_PLAN.md
- Adding new tests → Use TEST_CASE_TEMPLATE.md
- Checking test status → Review TEST_CASE_STATUS.md metrics

---

**Last Updated**: 2025-01-27
**Total Test Methods**: 165+ automated tests covering all documented test cases
