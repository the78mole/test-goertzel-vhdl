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
│   └── GOERTZEL.md         # Detailed algorithm description
├── .devcontainer/          # Development container configuration
│   ├── Dockerfile          # Container image definition
│   └── devcontainer.json   # VS Code devcontainer config
├── .github/workflows/      # CI/CD workflows
│   └── test.yml            # Automated testing workflow
└── Makefile                # Build and test automation

```

## Getting Started

### Prerequisites

- **GHDL**: Open-source VHDL simulator
- **Make**: Build automation tool
- **GTKWave** (optional): For viewing waveforms

### Installation

On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install ghdl gtkwave make
```

### Using the Devcontainer

This project includes a devcontainer configuration for Visual Studio Code. To use it:

1. Install Docker and VS Code with the "Dev Containers" extension
2. Open the project in VS Code
3. Click "Reopen in Container" when prompted
4. The development environment will be automatically set up with all required tools

### Building and Testing

```bash
# Check VHDL syntax
make check

# Run all tests
make test

# Run simulation with waveform generation
make run

# View waveforms (after running 'make run')
gtkwave build/wave.ghw

# Clean build artifacts
make clean
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

This project uses GitHub Actions for continuous integration. Every push and pull request triggers:
- VHDL syntax checking
- Automated test execution
- Artifact generation

## Contributing

Contributions are welcome! Please ensure that:
- Code follows the existing style
- All tests pass
- New features include appropriate tests

## License

See [LICENSE](LICENSE) file for details.

## References

- Goertzel, G. (1958). "An Algorithm for the Evaluation of Finite Trigonometric Series"
- For more details, see [docs/GOERTZEL.md](docs/GOERTZEL.md)
