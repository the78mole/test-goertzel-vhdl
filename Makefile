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
.PHONY: all clean test analyze elaborate run

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
	$(GHDL) -s $(GHDL_FLAGS) $(VHDL_SOURCES)
	$(GHDL) -s $(GHDL_FLAGS) $(VHDL_TESTBENCHES)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -f *.o *.cf work-obj93.cf

# Help target
help:
	@echo "Available targets:"
	@echo "  all       - Build and run tests (default)"
	@echo "  analyze   - Analyze (compile) VHDL sources"
	@echo "  elaborate - Elaborate (link) the testbench"
	@echo "  run       - Run simulation with waveform generation"
	@echo "  test      - Run tests without waveform (for CI)"
	@echo "  check     - Check VHDL syntax"
	@echo "  clean     - Remove build artifacts"
	@echo "  help      - Show this help message"
