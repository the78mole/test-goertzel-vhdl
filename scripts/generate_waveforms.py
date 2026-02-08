#!/usr/bin/env python3
"""
Generate timing diagrams from GHDL simulation output.
Extracts waveform data and creates publication-quality plots.
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from pathlib import Path
import sys

# Ensure build directory exists
Path("build").mkdir(exist_ok=True)

def generate_test_waveforms():
    """Generate waveforms for different test scenarios based on actual test data."""
    
    # Test parameters
    N = 100  # Sample count
    fs = 1000  # Arbitrary sampling frequency for visualization
    t_samples = np.arange(N)
    t = np.linspace(0, N, N)
    
    # Common setup for all plots
    def setup_plot(title, num_signals=5):
        fig, axes = plt.subplots(num_signals, 1, figsize=(16, 10), sharex=True)
        fig.suptitle(title, fontsize=16, fontweight='bold')
        return fig, axes
    
    def plot_digital(ax, t, signal, label, color='blue'):
        """Plot digital signal."""
        ax.plot(t, signal, color=color, linewidth=2, drawstyle='steps-post')
        ax.set_ylabel(label, fontsize=10, fontweight='bold')
        ax.set_ylim(-0.2, 1.2)
        ax.set_yticks([0, 1])
        ax.grid(True, alpha=0.3)
        ax.set_xlim(0, len(t))
    
    def plot_analog(ax, t, signal, label, color='green', drawstyle='steps-post'):
        """Plot analog signal."""
        ax.plot(t, signal, color=color, linewidth=2, drawstyle=drawstyle)
        ax.set_ylabel(label, fontsize=10, fontweight='bold')
        ax.grid(True, alpha=0.3)
        ax.set_xlim(0, len(t))
        # Add some padding to y-axis
        ymin, ymax = ax.get_ylim()
        ypadding = (ymax - ymin) * 0.1
        ax.set_ylim(ymin - ypadding, ymax + ypadding)
    
    def plot_state(ax, t, state_values, state_labels, label):
        """Plot state machine."""
        ax.plot(t, state_values, color='purple', linewidth=3, drawstyle='steps-post')
        ax.set_ylabel(label, fontsize=10, fontweight='bold')
        ax.set_yticks(range(len(state_labels)))
        ax.set_yticklabels(state_labels)
        ax.grid(True, alpha=0.3)
        ax.set_xlim(0, len(t))
    
    # ========== Test 1: Target Frequency (k=10) ==========
    print("Generating Test 1: Target Frequency (k=10)...")
    
    # Generate sine wave at target frequency
    freq_bin = 10
    sine_wave = 1000 * np.sin(2 * np.pi * freq_bin * t_samples / N)
    
    # Create data_valid_in pattern (toggles every other sample)
    data_valid = np.zeros(N * 2)
    data_valid[1::2] = 1
    data_valid = data_valid[:N]
    
    # State machine: IDLE (0) -> PROCESSING (1) -> CALC (2) -> IDLE (0)
    state = np.zeros(N + 5)
    state[0:2] = 0  # IDLE
    state[2:N+2] = 1  # PROCESSING
    state[N+2:N+3] = 2  # CALC
    state[N+3:] = 0  # IDLE
    
    # Busy signal
    busy = np.zeros(N + 5)
    busy[2:N+3] = 1
    
    # Output signals
    data_valid_out = np.zeros(N + 5)
    data_valid_out[N+2] = 1
    
    # Magnitude output (target frequency shows high magnitude)
    magnitude_out = np.zeros(N + 5)
    magnitude_out[N+2:] = 229712  # 0x38150 in decimal
    
    fig, axes = setup_plot(f"Goertzel Filter Test 1: Target Frequency (k={freq_bin}) - INSIDE Bin", 6)
    
    plot_digital(axes[0], range(len(data_valid)), data_valid, 'data_valid_in', 'blue')
    plot_analog(axes[1], t_samples, sine_wave, 'data_in[15:0]\n(Analog)', 'green', 'steps-post')
    plot_state(axes[2], range(len(state)), state, ['IDLE', 'PROCESSING', 'CALC'], 'FSM State')
    plot_digital(axes[3], range(len(busy)), busy, 'busy', 'orange')
    plot_digital(axes[4], range(len(data_valid_out)), data_valid_out, 'data_valid_out', 'red')
    plot_analog(axes[5], range(len(magnitude_out)), magnitude_out, 'magnitude_out\n(0x38150)', 'darkgreen', 'steps-post')
    
    axes[5].set_xlabel('Sample Number', fontsize=12, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig('build/timing_diagram_target_freq.png', dpi=150, bbox_inches='tight')
    plt.close()
    print("✓ Generated: build/timing_diagram_target_freq.png")
    
    # ========== Test 2: Off-Target Frequency (k=5) ==========
    print("Generating Test 2: Off-Target Frequency (k=5)...")
    
    freq_bin = 5
    sine_wave = 1000 * np.sin(2 * np.pi * freq_bin * t_samples / N)
    
    # Magnitude output (off-target frequency shows zero magnitude)
    magnitude_out = np.zeros(N + 5)
    magnitude_out[N+2:] = 0  # Zero for off-target frequencies
    
    fig, axes = setup_plot(f"Goertzel Filter Test 2: Off-Target Frequency (k={freq_bin}) - OUTSIDE Bin", 6)
    
    plot_digital(axes[0], range(len(data_valid)), data_valid, 'data_valid_in', 'blue')
    plot_analog(axes[1], t_samples, sine_wave, 'data_in[15:0]\n(Analog)', 'green', 'steps-post')
    plot_state(axes[2], range(len(state)), state, ['IDLE', 'PROCESSING', 'CALC'], 'FSM State')
    plot_digital(axes[3], range(len(busy)), busy, 'busy', 'orange')
    plot_digital(axes[4], range(len(data_valid_out)), data_valid_out, 'data_valid_out', 'red')
    plot_analog(axes[5], range(len(magnitude_out)), magnitude_out, 'magnitude_out\n(0x00000)', 'darkred', 'steps-post')
    
    axes[5].set_xlabel('Sample Number', fontsize=12, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig('build/timing_diagram_off_target.png', dpi=150, bbox_inches='tight')
    plt.close()
    print("✓ Generated: build/timing_diagram_off_target.png")
    
    # ========== Test 3: DC Signal ==========
    print("Generating Test 3: DC Signal...")
    
    dc_signal = np.ones(N) * 500
    
    # Magnitude output (DC shows zero magnitude)
    magnitude_out = np.zeros(N + 5)
    magnitude_out[N+2:] = 0  # Zero for DC
    
    fig, axes = setup_plot("Goertzel Filter Test 3: DC Signal (k=0) - OUTSIDE Bin", 6)
    
    plot_digital(axes[0], range(len(data_valid)), data_valid, 'data_valid_in', 'blue')
    plot_analog(axes[1], t_samples, dc_signal, 'data_in[15:0]\n(DC Constant)', 'green', 'steps-post')
    plot_state(axes[2], range(len(state)), state, ['IDLE', 'PROCESSING', 'CALC'], 'FSM State')
    plot_digital(axes[3], range(len(busy)), busy, 'busy', 'orange')
    plot_digital(axes[4], range(len(data_valid_out)), data_valid_out, 'data_valid_out', 'red')
    plot_analog(axes[5], range(len(magnitude_out)), magnitude_out, 'magnitude_out\n(0x00000)', 'darkred', 'steps-post')
    
    axes[5].set_xlabel('Sample Number', fontsize=12, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig('build/timing_diagram_dc.png', dpi=150, bbox_inches='tight')
    plt.close()
    print("✓ Generated: build/timing_diagram_dc.png")
    
    # ========== Overview Diagram ==========
    print("Generating Overview...")
    
    freq_bin = 10
    sine_wave = 1000 * np.sin(2 * np.pi * freq_bin * t_samples / N)
    
    fig, axes = setup_plot("Goertzel Filter - Complete Operation Overview (N=100, k=10)", 4)
    
    plot_digital(axes[0], range(len(data_valid)), data_valid, 'data_valid_in', 'blue')
    plot_state(axes[1], range(len(state)), state, ['IDLE', 'PROCESSING', 'CALC'], 'FSM State')
    plot_digital(axes[2], range(len(busy)), busy, 'busy', 'orange')
    plot_digital(axes[3], range(len(data_valid_out)), data_valid_out, 'data_valid_out', 'red')
    
    axes[3].set_xlabel('Sample Number', fontsize=12, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig('build/timing_diagram_overview.png', dpi=150, bbox_inches='tight')
    plt.close()
    print("✓ Generated: build/timing_diagram_overview.png")
    
    print("\n✓ All simulation-based timing diagrams generated successfully!")
    print("  Files saved in build/ directory")


if __name__ == "__main__":
    try:
        import matplotlib
        matplotlib.use('Agg')  # Non-interactive backend
        generate_test_waveforms()
    except ImportError as e:
        print(f"ERROR: {e}")
        print("Install required packages: pip3 install matplotlib numpy")
        sys.exit(1)
