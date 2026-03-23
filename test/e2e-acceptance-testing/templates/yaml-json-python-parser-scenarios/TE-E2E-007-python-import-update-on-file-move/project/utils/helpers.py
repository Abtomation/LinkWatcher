# Helper utility functions

def format_name(name):
    """Format a name string."""
    return name.strip().title()

def validate_input(data):
    """Validate input data."""
    return data is not None and len(data) > 0
