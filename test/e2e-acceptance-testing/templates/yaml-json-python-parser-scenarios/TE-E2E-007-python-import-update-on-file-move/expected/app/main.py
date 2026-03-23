# Main application entry point
from core.helpers import format_name

# Configuration
INIT_PATH = "utils/__init__.py"
HELPERS_PATH = "core/helpers.py"
# See core/helpers.py for details

def main():
    print(format_name("test"))

if __name__ == "__main__":
    main()
