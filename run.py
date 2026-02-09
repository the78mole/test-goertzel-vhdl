#!/usr/bin/env python3
"""
VUnit test runner for Goertzel filter project.
This script discovers and runs all VUnit testbenches.
"""

from pathlib import Path
from vunit import VUnit

# Create VUnit instance with explicit settings
vu = VUnit.from_argv(compile_builtins=False)

# Add VHDL builtins
vu.add_vhdl_builtins()

# Add source files to library
lib = vu.add_library("goertzel_lib")
# Add source files first (dependencies)
lib.add_source_files("src/goertzel_filter.vhd")
# Then add test files
lib.add_source_files("test/goertzel_filter_vunit_tb.vhd")

# Run tests
vu.main()
