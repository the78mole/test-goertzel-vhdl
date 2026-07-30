# Makefile for VHDL Goertzel Filter project
# Requires ghdl simulator

# Directories
SRC_DIR = src
TEST_DIR = test
BUILD_DIR = build

# GHDL settings
GHDL = ghdl
GHDL_FLAGS = --std=93 --workdir=$(BUILD_DIR) --work=work
GHDL_RUN_FLAGS = --stop-time=10ms --wave=$(BUILD_DIR)/wave.ghw

# Source files
VHDL_SOURCES = $(SRC_DIR)/goertzel_filter.vhd
VHDL_TESTBENCHES = $(TEST_DIR)/goertzel_filter_tb.vhd

# Targets
.PHONY: all clean test analyze elaborate run diagram vunit vunit-gui

all: test

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Analyze (compile) VHDL sources
analyze: $(BUILD_DIR)
	@echo "Analyzing VHDL sources..."
	$(GHDL) -a $(GHDL_FLAGS) $(VHDL_SOURCES)
	$(GHDL) -a $(GHDL_FLAGS) $(VHDL_TESTBENCHES)

# Elaborate (link) the testbench
elaborate: analyze
	@echo "Elaborating testbench..."
	$(GHDL) -e $(GHDL_FLAGS) goertzel_filter_tb

# Run the simulation
run: elaborate
	@echo "Running simulation..."
	$(GHDL) -r $(GHDL_FLAGS) goertzel_filter_tb $(GHDL_RUN_FLAGS)

# Run tests (without waveform generation for CI)
test: analyze
	@echo "Running tests..."
	$(GHDL) -e $(GHDL_FLAGS) goertzel_filter_tb
	$(GHDL) -r $(GHDL_FLAGS) goertzel_filter_tb --stop-time=10ms
	@echo "Tests completed successfully!"

# Check syntax only
check: $(BUILD_DIR)
	@echo "Checking syntax..."
	$(GHDL) -a $(GHDL_FLAGS) $(VHDL_SOURCES)
	$(GHDL) -a $(GHDL_FLAGS) $(VHDL_TESTBENCHES)
	@echo "Syntax check passed!"

# Generate timing diagram
diagram: $(BUILD_DIR) run
	@echo "Generating timing diagrams from simulation output..."
	@if command -v python3 &> /dev/null; then \
		if python3 -c "import matplotlib" 2>/dev/null; then \
			python3 scripts/generate_waveforms.py; \
		else \
			echo "ERROR: matplotlib not installed."; \
			echo "Install with: pip3 install matplotlib numpy"; \
			exit 1; \
		fi; \
	else \
		echo "ERROR: Python3 not found."; \
		exit 1; \
	fi

# Run VUnit tests
vunit:
	@echo "Running VUnit tests..."
	@if command -v python3 &> /dev/null; then \
		if python3 -c "import vunit" 2>/dev/null; then \
			python3 run.py --minimal; \
		else \
			echo "ERROR: VUnit not installed."; \
			echo "Install with: pip3 install vunit_hdl"; \
			exit 1; \
		fi; \
	else \
		echo "ERROR: Python3 not found."; \
		exit 1; \
	fi

# Run VUnit tests with GUI
vunit-gui:
	@echo "Running VUnit tests with GUI..."
	@if command -v python3 &> /dev/null; then \
		if python3 -c "import vunit" 2>/dev/null; then \
			python3 run.py -g; \
		else \
			echo "ERROR: VUnit not installed."; \
			echo "Install with: pip3 install vunit_hdl"; \
			exit 1; \
		fi; \
	else \
		echo "ERROR: Python3 not found."; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -rf vunit_out
	rm -f *.o *.cf work-obj93.cf

# Help target
help:
	@echo "Available targets:"
	@echo "  all        - Build and run tests (default)"
	@echo "  analyze    - Analyze (compile) VHDL sources"
	@echo "  elaborate  - Elaborate (link) the testbench"
	@echo "  run        - Run simulation with waveform generation"
	@echo "  test       - Run tests without waveform (for CI)"
	@echo "  check      - Check VHDL syntax"
	@echo "  diagram    - Generate all timing diagrams (PNG + SVG)"
	@echo "  vunit      - Run VUnit tests"
	@echo "  vunit-gui  - Run VUnit tests with GUI"
	@echo "  clean      - Remove build artifacts"
	@echo "  help       - Show this help message"
