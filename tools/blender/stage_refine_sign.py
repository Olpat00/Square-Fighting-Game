"""Legacy entry point. Revision 2 replaces the billboard with a small inset plaque.
Regenerate the current complete stage instead of editing obsolete joined mesh names.
"""
import runpy
from pathlib import Path
runpy.run_path(str(Path(__file__).with_name('stage_build.py')),run_name='__main__')
