"""
Pixelle-Video - Streamlit Community Cloud Entry Point
This file is required for Streamlit Community Cloud deployment.
It simply redirects to the main web/app.py entry point.
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).resolve().parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

# Import and run the main app
from web.app import main

if __name__ == "__main__":
    main()