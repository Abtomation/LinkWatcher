# Main application entry point
from utils.helpers import format_name

# Configuration
INIT_PATH = "utils/__init__.py"
HELPERS_PATH = "utils/helpers.py"
# See utils/helpers.py for details

def main():
    print(format_name("test"))

if __name__ == "__main__":
    main()
