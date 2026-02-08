# The Goertzel Algorithm

## Introduction

The Goertzel algorithm is a digital signal processing technique for efficiently detecting specific frequency components in a signal. Named after Gerald Goertzel who published it in 1958, it provides an efficient alternative to the Discrete Fourier Transform (DFT) when only a few frequency bins need to be computed.

## Mathematical Background

### The Discrete Fourier Transform (DFT)

The DFT converts a sequence of N complex or real numbers into another sequence of complex numbers representing the frequency domain. For a given frequency bin k, the DFT is defined as:

```
X(k) = Σ(n=0 to N-1) x(n) · e^(-j2πkn/N)
```

Where:
- `x(n)` is the input signal at sample n
- `X(k)` is the frequency component at bin k
- `N` is the total number of samples
- `j` is the imaginary unit

### The Goertzel Algorithm

The Goertzel algorithm computes a single DFT coefficient X(k) more efficiently than the general DFT formula. It reformulates the DFT computation as a digital filtering problem.

#### Core Principle

The algorithm is based on the following relationship:

```
X(k) = e^(-j2πk/N) · y_k(N)
```

Where `y_k(n)` is the output of a second-order IIR (Infinite Impulse Response) filter defined by:

```
y_k(n) = x(n) + 2·cos(2πk/N)·y_k(n-1) - y_k(n-2)
```

With initial conditions: `y_k(-1) = y_k(-2) = 0`

#### Algorithm Steps

1. **Initialization**: Set `s(-1) = s(-2) = 0`

2. **Iteration** (for n = 0 to N-1):
   ```
   s(n) = x(n) + 2·cos(2πk/N)·s(n-1) - s(n-2)
   ```

3. **Final Computation**:
   ```
   Real[X(k)] = s(N-1) - cos(2πk/N)·s(N-2)
   Imag[X(k)] = sin(2πk/N)·s(N-2)
   ```

4. **Magnitude**:
   ```
   |X(k)| = sqrt(Real[X(k)]² + Imag[X(k)]²)
   ```
   
   Or simplified:
   ```
   |X(k)|² = s(N-1)² + s(N-2)² - 2·cos(2πk/N)·s(N-1)·s(N-2)
   ```

## Advantages

1. **Computational Efficiency**: 
   - Requires only one multiply and two additions per sample
   - More efficient than FFT when detecting only a few frequencies
   - FFT: O(N log N) operations for all bins
   - Goertzel: O(N) operations per frequency bin

2. **Memory Efficiency**:
   - Only needs to store two previous state variables
   - No need to store all N samples in memory

3. **Real-time Capability**:
   - Can process samples as they arrive
   - Doesn't require the entire block to be buffered before processing

4. **Selective Frequency Analysis**:
   - Compute only the frequencies of interest
   - Ideal for applications like DTMF detection

## Disadvantages

1. **Not Efficient for Many Frequencies**:
   - If you need to compute many frequency bins, FFT becomes more efficient
   - Break-even point is typically around N/log₂(N) frequency bins

2. **Requires Coefficient Precision**:
   - The coefficient 2·cos(2πk/N) must be computed accurately
   - Fixed-point implementations need careful scaling

## Applications

### 1. DTMF (Dual-Tone Multi-Frequency) Detection
- Telephone keypad tone detection
- Only 8 specific frequencies need to be detected
- Perfect use case for Goertzel algorithm

### 2. Frequency Monitoring
- Power line frequency monitoring (50 Hz / 60 Hz)
- Heart rate monitoring
- Vibration analysis

### 3. Tone Detection
- FSK (Frequency Shift Keying) demodulation
- Musical note detection
- Sonar signal processing

### 4. Interference Detection
- Detecting specific interference frequencies
- Narrow-band signal detection in wide-band noise

## VHDL Implementation Considerations

### Fixed-Point Arithmetic

In hardware implementations, fixed-point arithmetic is typically used instead of floating-point for efficiency:

1. **Coefficient Representation**:
   - The coefficient `2·cos(2πk/N)` must be scaled to fixed-point
   - Example: For 16-bit fixed point with 14 fractional bits:
     ```
     coeff_fixed = round(2·cos(2πk/N) × 2^14)
     ```

2. **Overflow Prevention**:
   - Internal state variables must have sufficient width
   - Typical approach: Use 2× input width for intermediate calculations
   - Example: 16-bit input → 32-bit internal state

3. **Rounding and Truncation**:
   - After multiplication with coefficient, result must be right-shifted
   - Choose between truncation or rounding based on accuracy requirements

### State Machine Design

The VHDL implementation typically uses a state machine with three states:

1. **IDLE**: Waiting for processing to start
2. **PROCESSING_SAMPLES**: Iterating through N samples
3. **CALCULATE_MAGNITUDE**: Computing final magnitude after N samples

### Pipelining Considerations

For high-throughput applications:
- Pipeline the multiply-accumulate operations
- May require multiple clock cycles per sample
- Trade-off between throughput and latency

## Parameter Selection

### Sample Count (N)

- **Frequency Resolution**: Δf = fs/N (where fs is sampling frequency)
- Larger N provides better frequency resolution but:
  - Increases processing time
  - Requires more clock cycles
  - May introduce more quantization error

### Target Frequency Bin (k)

- Choose k based on the target frequency: `k = round(f_target × N / f_sampling)`
- Example: To detect 1 kHz with 10 kHz sampling and N=100:
  ```
  k = round(1000 × 100 / 10000) = 10
  ```

### Data Width

- Input data width depends on ADC resolution (typically 12-16 bits)
- Coefficient width should match or exceed input width
- Internal state width: recommended 2× input width minimum

## Performance Analysis

### Computational Complexity

For detecting M frequency bins out of N samples:

- **Goertzel**: ~4N×M real operations
- **FFT**: ~N×log₂(N) real operations (but computes all N bins)

Break-even point (Goertzel vs FFT):
- M ≈ log₂(N) frequency bins

Example for N=1024:
- FFT always computes all 1024 bins: ~10,240 operations
- Goertzel for 1 bin: ~4,096 operations
- Goertzel for 10 bins: ~40,960 operations
- Use Goertzel if you need fewer than ~10 bins

### Resource Utilization (FPGA)

Typical resource usage for 16-bit implementation:
- 1-2 DSP blocks (for multiplication)
- ~500-1000 LUTs (for control logic and additions)
- ~200-400 flip-flops (for state registers)
- Block RAM: minimal (only stores state variables)

## Testing and Validation

### Test Signal Generation

1. **Pure Sine Wave at Target Frequency**:
   ```
   x(n) = A · sin(2πf·n/fs)
   ```
   Expected: Maximum magnitude output

2. **Off-Frequency Sine Wave**:
   Expected: Low magnitude output

3. **DC Signal**:
   Expected: Zero magnitude (if k ≠ 0)

4. **Noise**:
   Expected: Low, distributed magnitude

### Verification Metrics

1. **Frequency Selectivity**: 
   - Measure 3 dB bandwidth
   - Compare with theoretical 1/N resolution

2. **Dynamic Range**:
   - Test with different input amplitudes
   - Verify no overflow or underflow

3. **Accuracy**:
   - Compare with reference DFT implementation
   - Acceptable error typically < 1%

## References

1. Goertzel, G. (1958). "An Algorithm for the Evaluation of Finite Trigonometric Series". 
   American Mathematical Monthly. 65 (1): 34–35.

2. Mitra, S. K. (2006). "Digital Signal Processing: A Computer-Based Approach". 
   McGraw-Hill. Chapter 9.

3. Proakis, J. G., & Manolakis, D. G. (2006). "Digital Signal Processing". 
   Pearson. Chapter 10.

4. Banks, K. (2002). "The Goertzel Algorithm". 
   Embedded Systems Programming.

5. Texas Instruments Application Report SPRA168 (1996). 
   "Implementing Fast Fourier Transform Algorithms of Real-Valued Sequences With the TMS320 DSP Platform".

## Conclusion

The Goertzel algorithm is a powerful tool for selective frequency detection in digital signal processing. Its efficiency in computing individual frequency bins makes it ideal for applications where only a few specific frequencies need to be monitored. The VHDL implementation provides a hardware-efficient solution suitable for FPGA and ASIC designs, particularly in real-time audio and communication systems.
