# CI/CD Pipeline Documentation

This document describes the Continuous Integration and Continuous Deployment (CI/CD) pipeline for LinkWatcher.

## 🚀 Pipeline Overview

The CI/CD pipeline is designed to ensure code quality, run comprehensive tests, and automate deployment processes. It consists of multiple stages that run on different triggers.

### **Pipeline Stages**

1. **Test Suite** - Runs on all platforms and Python versions
2. **Performance Tests** - Runs on main branch pushes
3. **Code Quality** - Linting, formatting, and type checking
4. **Security Scan** - Vulnerability and security analysis
5. **Build Package** - Creates distributable packages

## 🔧 GitHub Actions Workflows

### **Main CI Workflow** (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Manual workflow dispatch

**Jobs:**

#### **1. Test Suite**
- **Matrix Strategy**: Tests across multiple Python versions on Windows
  - OS: Windows only
  - Python: 3.11
- **Steps**:
  1. Checkout code
  2. Set up Python environment
  3. Cache pip dependencies
  4. Install dependencies
  5. Run test discovery
  6. Run unit tests with coverage
  7. Run parser tests
  8. Run integration tests
  9. Upload coverage to Codecov

#### **2. Performance Tests**
- **Trigger**: Push to main branch only
- **Environment**: Windows with Python 3.11
- **Steps**:
  1. Run performance test suite
  2. Upload performance results as artifacts

#### **3. Code Quality**
- **Tools**: flake8, black, isort, mypy
- **Steps**:
  1. Run linting checks
  2. Check code formatting
  3. Run type checking

#### **4. Security Scan**
- **Tools**: safety, bandit
- **Steps**:
  1. Check for known vulnerabilities
  2. Run security analysis
  3. Upload security reports

#### **5. Build Package**
- **Trigger**: Push events only
- **Steps**:
  1. Build Python package
  2. Validate package integrity
  3. Upload build artifacts

## 🛠️ Development Workflow

### **Pre-commit Hooks**

Pre-commit hooks run automatically before each commit to ensure code quality:

```bash
# Install pre-commit hooks
make pre-commit

# Or manually
pre-commit install
```

**Hooks included:**
- Trailing whitespace removal
- End-of-file fixing
- YAML/JSON validation
- Merge conflict detection
- Large file detection
- Debug statement detection
- Code formatting (black, isort)
- Linting (flake8)
- Quick test run

### **Local Development Commands**

**Windows Batch Commands:**
```cmd
# Setup development environment
dev dev-setup

# Run quick tests during development
dev test

# Run all tests before pushing
dev test-all

# Check code quality
dev lint

# Format code
dev format

# Run type checking
dev type-check

# Generate coverage report
dev coverage

# Run CI tests locally
dev ci-test
```

**Alternative Makefile Commands:**
```bash
# Setup development environment
make dev-setup

# Run quick tests during development
make test

# Run all tests before pushing
make test-all

# Check code quality
make lint

# Format code
make format

# Run type checking
make type-check

# Generate coverage report
make coverage

# Run CI tests locally
make ci-test
```

## 📊 Test Execution Strategy

### **Test Categories**

1. **Unit Tests** (`tests/unit/`)
   - Fast, isolated component tests
   - Run on every commit
   - Target: 100% pass rate

2. **Parser Tests** (`tests/parsers/`)
   - File-type specific parsing tests
   - Run on every commit
   - Target: 100% pass rate

3. **Integration Tests** (`tests/integration/`)
   - Component interaction tests
   - Run on every commit
   - Allow some failures (marked with `continue-on-error`)

4. **Performance Tests** (`tests/performance/`)
   - Large-scale and timing tests
   - Run on main branch pushes only
   - Allow failures (performance regression detection)

### **Test Execution Matrix**

| Test Type | Frequency | Platform | Python Versions | Failure Policy |
|-----------|-----------|----------|-----------------|----------------|
| Unit | Every commit | Windows | 3.8, 3.9, 3.10, 3.11 | Fail fast |
| Parser | Every commit | Windows | 3.8, 3.9, 3.10, 3.11 | Fail fast |
| Integration | Every commit | Windows | 3.8, 3.9, 3.10, 3.11 | Continue on error |
| Performance | Main branch | Windows | 3.11 | Continue on error |

## 🔍 Quality Gates

### **Pre-commit Quality Gates**
- [ ] Code formatting (black, isort)
- [ ] Linting (flake8)
- [ ] Quick tests pass
- [ ] No debug statements
- [ ] No large files

### **CI Quality Gates**
- [ ] All unit tests pass
- [ ] All parser tests pass
- [ ] Code quality checks pass
- [ ] Security scans complete
- [ ] Package builds successfully

### **Release Quality Gates**
- [ ] All tests pass on all platforms
- [ ] Performance benchmarks met
- [ ] Security vulnerabilities addressed
- [ ] Documentation updated
- [ ] Version bumped appropriately

## 📈 Monitoring and Reporting

### **Coverage Reporting**
- **Tool**: Codecov
- **Target**: 90%+ overall coverage
- **Reports**: Generated on Windows + Python 3.11 runs
- **Badge**: Displayed in README

### **Performance Monitoring**
- **Artifacts**: Performance results uploaded as JSON
- **Benchmarks**: Tracked over time
- **Alerts**: Manual review of performance regressions

### **Security Monitoring**
- **Tools**: Safety (dependency vulnerabilities), Bandit (code analysis)
- **Reports**: Uploaded as artifacts
- **Policy**: Continue on error (manual review required)

## 🚨 Failure Handling

### **Test Failures**
1. **Unit/Parser Tests**: Pipeline fails immediately
2. **Integration Tests**: Pipeline continues, manual review required
3. **Performance Tests**: Pipeline continues, results archived
4. **Quality Checks**: Pipeline continues, issues reported

### **Dependency Issues**
- **Cache Misses**: Automatic retry with fresh installation
- **Version Conflicts**: Matrix strategy isolates issues
- **Windows-specific Issues**: Handled with appropriate configurations

### **Build Failures**
- **Package Build**: Pipeline fails, prevents deployment
- **Artifact Upload**: Non-critical, continues with warning

## 🔄 Deployment Strategy

### **Current State**
- **Build Only**: Packages are built and validated
- **No Automatic Deployment**: Manual release process
- **Artifact Storage**: GitHub Actions artifacts

### **Future Enhancements**
- **PyPI Deployment**: Automatic publishing on tagged releases
- **Docker Images**: Container builds for different environments
- **Documentation Deployment**: Automatic docs updates

## 📝 Configuration Files

### **GitHub Actions**
- `.github/workflows/ci.yml` - Main CI/CD pipeline

### **Pre-commit**
- `.pre-commit-config.yaml` - Pre-commit hook configuration

### **Package Configuration**
- `pyproject.toml` - Modern Python packaging configuration
- `setup.py` - Legacy packaging support

### **Development Tools**
- `Makefile` - Development command shortcuts
- `pytest.ini` - Test configuration (legacy)
- `requirements-test.txt` - Test dependencies

## 🎯 Best Practices

### **Commit Messages**
- Use conventional commit format
- Include test case IDs when fixing test issues
- Reference issue numbers for bug fixes

### **Branch Strategy**
- `main` - Production-ready code
- `develop` - Integration branch
- Feature branches - Individual features/fixes

### **Pull Request Process**
1. Create feature branch from `develop`
2. Implement changes with tests
3. Run local quality checks (`make ci-test`)
4. Create pull request to `develop`
5. Wait for CI pipeline to pass
6. Request code review
7. Merge after approval

### **Release Process**
1. Merge `develop` to `main`
2. Tag release with version number
3. Monitor CI pipeline
4. Manual deployment (current)
5. Update documentation

## 🔧 Troubleshooting

### **Common CI Issues**

#### **Test Failures**
```bash
# Run tests locally to reproduce
make test-all

# Check specific test category
python run_tests.py --unit --verbose
```

#### **Dependency Issues**
```bash
# Clear pip cache
pip cache purge

# Reinstall dependencies
pip install -r requirements-test.txt --force-reinstall
```

#### **Windows-Specific Issues**
- Check Windows path handling
- Test locally on Windows
- Add Windows-specific conditions if needed

### **Performance Issues**
- Monitor test execution times
- Optimize slow tests or mark as `@pytest.mark.slow`
- Consider parallel test execution

### **Coverage Issues**
- Check coverage reports in artifacts
- Add tests for uncovered code
- Update coverage exclusions if needed

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Pre-commit Documentation](https://pre-commit.com/)
- [pytest Documentation](https://docs.pytest.org/)
- [Codecov Documentation](https://docs.codecov.com/)

---

**The CI/CD pipeline ensures code quality and reliability while maintaining development velocity. All changes go through automated testing and quality checks before integration.**
