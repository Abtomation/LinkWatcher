# LinkWatcher Development Makefile

.PHONY: help install install-dev test test-quick test-all coverage lint format clean build docs

# Default target
help:
	@echo "LinkWatcher Development Commands:"
	@echo ""
	@echo "Setup:"
	@echo "  install      Install production dependencies"
	@echo "  install-dev  Install development dependencies"
	@echo ""
	@echo "Testing:"
	@echo "  test         Run quick tests (unit + parsers)"
	@echo "  test-quick   Run quick development tests"
	@echo "  test-all     Run all tests including slow ones"
	@echo "  coverage     Run tests with coverage report"
	@echo ""
	@echo "Quality:"
	@echo "  lint         Run linting checks"
	@echo "  format       Format code with black and isort"
	@echo "  type-check   Run type checking with mypy"
	@echo ""
	@echo "Build:"
	@echo "  clean        Clean build artifacts"
	@echo "  build        Build package"
	@echo "  docs         Generate documentation"
	@echo ""
	@echo "CI/CD:"
	@echo "  pre-commit   Install pre-commit hooks"
	@echo "  ci-test      Run CI test suite locally"

# Installation
install:
	pip install -r requirements.txt

install-dev:
	pip install -r requirements.txt
	pip install -r requirements-test.txt
	pip install -e ".[dev]"

# Testing
test:
	python run_tests.py --quick

test-quick:
	python run_tests.py --unit --parsers

test-all:
	python run_tests.py --all

coverage:
	python run_tests.py --coverage
	@echo "Coverage report generated in htmlcov/index.html"

# Quality checks
lint:
	flake8 linkwatcher tests --max-line-length=100 --extend-ignore=E203,W503
	black --check linkwatcher tests
	isort --check-only linkwatcher tests

format:
	black linkwatcher tests
	isort linkwatcher tests

type-check:
	mypy linkwatcher --ignore-missing-imports

# Build and packaging
clean:
	if exist build rmdir /s /q build
	if exist dist rmdir /s /q dist
	if exist *.egg-info rmdir /s /q *.egg-info
	if exist .pytest_cache rmdir /s /q .pytest_cache
	if exist .coverage del .coverage
	if exist htmlcov rmdir /s /q htmlcov
	for /d /r . %%d in (__pycache__) do @if exist "%%d" rmdir /s /q "%%d"
	for /r . %%f in (*.pyc) do @if exist "%%f" del "%%f"

build: clean
	python -m build

# Documentation
docs:
	@echo "Documentation generation not yet implemented"

# CI/CD helpers
pre-commit:
	pre-commit install
	pre-commit install --hook-type commit-msg

ci-test:
	python run_tests.py --discover
	python run_tests.py --unit --coverage
	python run_tests.py --parsers
	python run_tests.py --integration

# Development workflow
dev-setup: install-dev pre-commit
	@echo "Development environment setup complete!"
	@echo "Run 'make test' to verify everything works."

# Release workflow
release-check: clean lint type-check test-all
	python -m build
	twine check dist/*
	@echo "Release checks passed!"
