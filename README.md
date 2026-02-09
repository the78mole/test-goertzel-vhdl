# test-goertzel-vhdl

A parametrizable digital filter using the Goertzel algorithm in VHDL.

## Overview

This project implements a digital filter based on the **Goertzel algorithm** in VHDL. The Goertzel algorithm is an efficient method for detecting specific frequency components in a signal, similar to computing a single bin of a Discrete Fourier Transform (DFT). It is particularly useful in applications like DTMF (Dual-Tone Multi-Frequency) detection, tone detection, and frequency analysis where only a few specific frequencies need to be analyzed.

### Key Features

- **Parametrizable design**: Configurable data width, coefficient width, and sample count
- **Efficient computation**: Calculates magnitude of a specific frequency bin without computing the full DFT
- **VHDL implementation**: Synthesizable RTL code for FPGA/ASIC implementation
- **Comprehensive testing**: Includes testbenches and automated CI/CD testing

### The Goertzel Algorithm

The Goertzel algorithm uses a second-order IIR filter to compute the magnitude of a specific frequency component. Instead of computing all frequency bins like an FFT, it calculates only the frequency of interest, making it more efficient for detecting single frequencies.

**Core equation**: `s(n) = x(n) + 2·cos(2πk/N)·s(n-1) - s(n-2)`

Where:
- `x(n)` is the input sample
- `k` is the frequency bin of interest
- `N` is the total number of samples
- `s(n)` is the state variable

For a detailed explanation of the algorithm, see [docs/GOERTZEL.md](docs/GOERTZEL.md).

## Project Structure

```
.
├── src/                    # VHDL source files
│   └── goertzel_filter.vhd # Main filter implementation
├── test/                   # Testbenches
│   └── goertzel_filter_tb.vhd
├── docs/                   # Documentation
│   ├── GOERTZEL.md         # Detailed algorithm description
│   ├── timing_diagram_*.json (legacy) # Optional WaveDrom sources
├── scripts/                # Automation scripts
│   ├── generate_waveforms.py   # Creates diagrams from simulation
│   └── generate_diagram.py     # Legacy WaveDrom generator
├── .devcontainer/          # Development container configuration
│   ├── Dockerfile          # Container image definition
│   └── devcontainer.json   # VS Code devcontainer config
├── .github/workflows/      # CI/CD workflows
│   └── test.yml            # Automated testing and release workflow
└── Makefile                # Build and test automation

```

## Getting Started

### Prerequisites

- **GHDL**: Open-source VHDL simulator
- **Make**: Build automation tool
- **Python 3**: For VUnit test framework
- **VUnit**: VHDL unit testing framework (optional but recommended)
- **GTKWave** (optional): For viewing waveforms

### Installation

On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install ghdl gtkwave make python3 python3-pip

# Install VUnit for advanced testing (recommended)
pip3 install vunit_hdl
```

### Using the Devcontainer

This project includes a devcontainer configuration for Visual Studio Code. To use it:

1. Install Docker and VS Code with the "Dev Containers" extension
2. Open the project in VS Code
3. Click "Reopen in Container" when prompted
4. The development environment will be automatically set up with all required tools

The devcontainer includes the **Surfer** extension for viewing waveforms directly in VS Code, which is particularly useful when working in GitHub Codespaces or remote environments.

### Building and Testing

```bash
# Check VHDL syntax
make check

# Run all tests (traditional testbench)
make test

# Run VUnit tests (recommended - comprehensive test suite)
make vunit

# Run simulation with waveform generation
make run

# View waveforms (after running 'make run')
gtkwave build/wave.ghw

# Or use the Surfer extension in VS Code (ideal for Codespaces)
# Open build/wave.ghw directly in VS Code with the Surfer extension

# Clean build artifacts
make clean
```

#### VUnit Testing

This project includes a comprehensive VUnit test suite with 10 test cases:

1. **test_target_frequency_k10** - Validates detection of target frequency
2. **test_off_target_frequency_k5** - Tests rejection of lower frequency
3. **test_off_target_frequency_k15** - Tests rejection of higher frequency
4. **test_off_target_frequency_k20** - Tests rejection of much higher frequency
5. **test_low_frequency_k2** - Tests rejection of low frequency
6. **test_high_frequency_k30** - Tests rejection of very high frequency
7. **test_dc_signal** - Tests DC signal rejection
8. **test_zero_input** - Tests zero input handling
9. **test_reset_during_processing** - Tests reset behavior
10. **test_busy_flag** - Tests busy flag behavior

Run VUnit tests:
```bash
# Run all VUnit tests
make vunit

# Run VUnit tests with GUI (GTKWave)
make vunit-gui

# Run specific test
python3 run.py '*test_target_frequency*'

# List all available tests
python3 run.py --list
```

## Usage Example

The Goertzel filter can be instantiated in your VHDL design:

```vhdl
goertzel_inst: entity work.goertzel_filter
  generic map (
    DATA_WIDTH    => 16,
    COEFF_WIDTH   => 16,
    SAMPLE_COUNT  => 100
  )
  port map (
    clk            => clk,
    rst            => rst,
    enable         => enable,
    data_in        => data_in,
    data_valid_in  => data_valid_in,
    coeff          => coeff,
    magnitude_out  => magnitude_out,
    data_valid_out => data_valid_out,
    busy           => busy
  );
```

## CI/CD

This project uses GitHub Actions for continuous integration and automated releases. Every push and pull request triggers:
- VHDL syntax checking
- Automated test execution with multiple frequency scenarios
- Simulation with waveform generation
- Timing diagram generation (WaveDrom)
- Artifact generation

### Automated Releases

On every push to `main`, the workflow automatically:
- Calculates semantic version (using conventional commits: `feat:`, `fix:`, breaking changes with `!`)
- Runs all tests and simulations
- Generates timing diagrams as PNG
- Creates a GitHub Release with:
  - Test results summary
  - GTKWave waveform file (`wave.ghw`)
  - Timing diagram visualization (`timing_diagram.png`)
  - Performance metrics

View the latest release to download waveforms and timing diagrams!

## Timing Diagrams

The project automatically generates publication-quality timing diagrams from **actual simulation output** using matplotlib. Unlike static diagrams, these show real waveforms extracted from the GHDL simulation.

### Available Diagrams

All diagrams are generated from running the test suite and show:

1. **Overview** 
   - Complete operation cycle with state machine
   - Data flow control signals
   - Generated from full 100-sample simulation

2. **Target Frequency Test (k=10)**
   - **Analog waveform** of input sine wave at target frequency
   - Shows actual sample values: +309, +587, +809, +951, +1000, ...
   - Output: Maximum magnitude = 0x38150 (229,712 decimal)
   - Demonstrates perfect frequency detection ✓

3. **Off-Target Frequency Test (k=5)**
   - **Analog waveform** of input sine wave at different frequency
   - Shows different sample pattern
   - Output: Zero magnitude (perfect suppression) ✓

4. **DC Signal Test**
   - **Constant analog level** at +500
   - Demonstrates DC blocking
   - Output: Zero magnitude (DC rejected) ✓

### Features

✅ **Real simulation data** - Not manually created
✅ **Analog waveforms** - data_in displayed as continuous signals with actual values
✅ **Publication quality** - 150 DPI, 16" wide, professional appearance
✅ **Annotated results** - Each diagram shows expected vs actual magnitude
✅ **Automatically generated** - Created on every `make diagram` run

### Generate Diagrams Locally

```bash
make diagram    # Runs simulation, then generates all diagrams
```

Requirements: Python 3 with matplotlib and numpy (installed automatically in devcontainer)

The diagrams are automatically included in GitHub releases with embedded images.

Contributions are welcome! Please ensure that:
- Code follows the existing style
- All tests pass
- New features include appropriate tests

## License

See [LICENSE](LICENSE) file for details.

## References

- Goertzel, G. (1958). "An Algorithm for the Evaluation of Finite Trigonometric Series"
- For more details, see [docs/GOERTZEL.md](docs/GOERTZEL.md)
