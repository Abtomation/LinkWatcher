@echo off
REM LinkWatcher Development Commands for Windows

if "%1"=="" goto help
if "%1"=="help" goto help
if "%1"=="install" goto install
if "%1"=="install-dev" goto install-dev
if "%1"=="test" goto test
if "%1"=="test-quick" goto test-quick
if "%1"=="test-all" goto test-all
if "%1"=="coverage" goto coverage
if "%1"=="lint" goto lint
if "%1"=="format" goto format
if "%1"=="type-check" goto type-check
if "%1"=="clean" goto clean
if "%1"=="build" goto build
if "%1"=="pre-commit" goto pre-commit
if "%1"=="ci-test" goto ci-test
if "%1"=="dev-setup" goto dev-setup

:help
echo LinkWatcher Development Commands for Windows:
echo.
echo Setup:
echo   dev install      Install production dependencies
echo   dev install-dev  Install development dependencies
echo.
echo Testing:
echo   dev test         Run quick tests (unit + parsers)
echo   dev test-quick   Run quick development tests
echo   dev test-all     Run all tests including slow ones
echo   dev coverage     Run tests with coverage report
echo.
echo Quality:
echo   dev lint         Run linting checks
echo   dev format       Format code with black and isort
echo   dev type-check   Run type checking with mypy
echo.
echo Build:
echo   dev clean        Clean build artifacts
echo   dev build        Build package
echo.
echo CI/CD:
echo   dev pre-commit   Install pre-commit hooks
echo   dev ci-test      Run CI test suite locally
echo   dev dev-setup    Setup development environment
goto end

:install
echo Installing production dependencies...
pip install -r requirements.txt
goto end

:install-dev
echo Installing development dependencies...
pip install -r requirements.txt
pip install -r requirements-test.txt
pip install -e ".[dev]"
goto end

:test
echo Running quick tests...
python run_tests.py --quick
goto end

:test-quick
echo Running quick development tests...
python run_tests.py --unit --parsers
goto end

:test-all
echo Running all tests...
python run_tests.py --all
goto end

:coverage
echo Running tests with coverage...
python run_tests.py --coverage
echo Coverage report generated in htmlcov/index.html
goto end

:lint
echo Running linting checks...
flake8 linkwatcher tests --max-line-length=100 --extend-ignore=E203,W503
black --check linkwatcher tests
isort --check-only linkwatcher tests
goto end

:format
echo Formatting code...
black linkwatcher tests
isort linkwatcher tests
goto end

:type-check
echo Running type checking...
mypy linkwatcher --ignore-missing-imports
goto end

:clean
echo Cleaning build artifacts...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
for /d %%d in (*.egg-info) do if exist "%%d" rmdir /s /q "%%d"
if exist .pytest_cache rmdir /s /q .pytest_cache
if exist .coverage del .coverage
if exist htmlcov rmdir /s /q htmlcov
for /d /r . %%d in (__pycache__) do @if exist "%%d" rmdir /s /q "%%d" 2>nul
for /r . %%f in (*.pyc) do @if exist "%%f" del "%%f" 2>nul
echo Clean complete.
goto end

:build
call :clean
echo Building package...
python -m build
goto end

:pre-commit
echo Installing pre-commit hooks...
python -m pre_commit install
python -m pre_commit install --hook-type commit-msg
goto end

:ci-test
echo Running CI test suite locally...
python run_tests.py --discover
python run_tests.py --unit --coverage
python run_tests.py --parsers
python run_tests.py --integration
goto end

:dev-setup
call :install-dev
call :pre-commit
echo Development environment setup complete!
echo Run 'dev test' to verify everything works.
goto end

:end
