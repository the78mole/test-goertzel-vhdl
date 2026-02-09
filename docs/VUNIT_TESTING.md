# VUnit Testing Guide

This project uses VUnit, a unit testing framework for VHDL/SystemVerilog, to provide comprehensive automated testing.

## Quick Start

### Prerequisites
- Python 3
- GHDL simulator
- VUnit (install with `pip3 install vunit_hdl`)

### Running Tests

```bash
# Run all tests
make vunit

# Or run directly with Python
python3 run.py --minimal

# Run with GUI (opens GTKWave for each test)
make vunit-gui
# or
python3 run.py -g

# List all available tests
python3 run.py --list

# Run specific test(s) by pattern matching
python3 run.py '*target_frequency*'
python3 run.py '*test_busy_flag*'

# Run tests verbosely
python3 run.py -v

# Run tests in parallel (4 threads)
python3 run.py -p 4
```

## Test Suite Overview

The VUnit test suite includes 10 comprehensive test cases:

### Frequency Detection Tests
1. **test_target_frequency_k10** - Validates that the filter correctly detects the target frequency (k=10) with high magnitude output (> 30000)
2. **test_off_target_frequency_k5** - Verifies that a frequency outside the target bin (k=5) produces low magnitude (< 10000)
3. **test_off_target_frequency_k15** - Tests rejection of higher frequency (k=15)
4. **test_off_target_frequency_k20** - Tests rejection of much higher frequency (k=20)
5. **test_low_frequency_k2** - Tests rejection of low frequency (k=2)
6. **test_high_frequency_k30** - Tests rejection of very high frequency (k=30)

### Signal Handling Tests
7. **test_dc_signal** - Validates that DC signals (constant value) produce low magnitude output
8. **test_zero_input** - Tests that zero input produces zero magnitude output

### Control Logic Tests
9. **test_reset_during_processing** - Verifies that resetting during processing correctly returns the filter to idle state
10. **test_busy_flag** - Validates the busy flag behavior throughout the filter operation cycle

## Test Structure

Each test follows this pattern:
1. Reset the DUT
2. Enable the filter
3. Feed test data (100 samples)
4. Wait for processing to complete
5. Validate outputs using VUnit's `check()` function

## Understanding Test Results

VUnit provides clear output:
- ✓ **pass** - Test passed all assertions
- ✗ **fail** - Test failed at least one assertion
- Test execution time is shown for each test
- Failed tests show detailed error messages with expected vs. actual values

### Example Output
```
pass goertzel_lib.goertzel_filter_vunit_tb.test_target_frequency_k10     (0.2 seconds)
pass goertzel_lib.goertzel_filter_vunit_tb.test_off_target_frequency_k5  (0.2 seconds)
...
============================================================================================
pass 10 of 10
============================================================================================
All passed!
```

## Adding New Tests

To add a new test case, edit `test/goertzel_filter_vunit_tb.vhd`:

```vhdl
elsif run("test_my_new_case") then
  -- Your test code here
  info("Testing my new case");
  
  -- Test setup
  rst <= '1';
  wait for CLK_PERIOD * 2;
  rst <= '0';
  
  -- Test execution
  -- ... your test logic ...
  
  -- Assertions
  check(condition, "Error message if condition is false");
  
end if;
```

The test will automatically be discovered and added to the test suite.

## CI/CD Integration

VUnit is ideal for continuous integration:

```yaml
# .github/workflows/test.yml
- name: Run VUnit Tests
  run: |
    pip3 install vunit_hdl
    python3 run.py --minimal --xunit-xml test-results.xml
```

## Benefits of VUnit

1. **Organized Tests** - Each test case is isolated and named
2. **Fast Execution** - Tests can run in parallel
3. **Clear Results** - Easy to see which tests pass/fail
4. **CI/CD Ready** - Generates standard test reports (JUnit XML)
5. **Selective Testing** - Run specific tests by pattern
6. **Debugging** - Can open waveforms for failed tests
7. **Professional** - Industry-standard testing framework

## Documentation

For more information about VUnit:
- Official documentation: https://vunit.github.io/
- GitHub repository: https://github.com/VUnit/vunit
- User guide: https://vunit.github.io/user_guide.html

## Troubleshooting

### VUnit not found
```bash
pip3 install vunit_hdl
```

### GHDL not found
```bash
sudo apt-get install ghdl
```

### Tests failing
Run with verbose output to see detailed information:
```bash
python3 run.py -v
```

View the test output files in `vunit_out/test_output/` for detailed logs.
