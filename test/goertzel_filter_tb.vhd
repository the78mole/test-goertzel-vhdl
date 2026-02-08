-------------------------------------------------------------------------------
-- Title      : Goertzel Filter Testbench
-- Project    : test-goertzel-vhdl
-------------------------------------------------------------------------------
-- File       : goertzel_filter_tb.vhd
-- Author     : 
-- Company    : 
-- Created    : 2026-02-07
-- Last update: 2026-02-07
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Testbench for the Goertzel filter module.
--              Tests basic functionality with simple test signals.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity goertzel_filter_tb is
end entity goertzel_filter_tb;

architecture test of goertzel_filter_tb is
  
  -- Constants
  constant DATA_WIDTH    : integer := 16;
  constant COEFF_WIDTH   : integer := 16;
  constant SAMPLE_COUNT  : integer := 100;
  constant CLK_PERIOD    : time := 10 ns;
  
  -- DUT signals
  signal clk           : std_logic := '0';
  signal rst           : std_logic := '0';
  signal enable        : std_logic := '0';
  signal data_in       : signed(DATA_WIDTH-1 downto 0) := (others => '0');
  signal data_valid_in : std_logic := '0';
  signal coeff         : signed(COEFF_WIDTH-1 downto 0) := (others => '0');
  signal magnitude_out : unsigned(DATA_WIDTH*2-1 downto 0);
  signal data_valid_out: std_logic;
  signal busy          : std_logic;
  
  -- Test control
  signal test_done     : boolean := false;
  
begin
  
  -- Instantiate the Unit Under Test (UUT)
  uut: entity work.goertzel_filter
    generic map (
      DATA_WIDTH    => DATA_WIDTH,
      COEFF_WIDTH   => COEFF_WIDTH,
      SAMPLE_COUNT  => SAMPLE_COUNT
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
  
  -- Clock generation
  clk_process: process
  begin
    while not test_done loop
      clk <= '0';
      wait for CLK_PERIOD/2;
      clk <= '1';
      wait for CLK_PERIOD/2;
    end loop;
    wait;
  end process;
  
  -- Stimulus process
  stim_process: process
    variable sample : integer;
    variable mag_target : unsigned(DATA_WIDTH*2-1 downto 0) := (others => '0');
    variable mag_freq : unsigned(DATA_WIDTH*2-1 downto 0);
    variable mag_high : integer;
    variable mag_low : integer;
    
    -- Procedure to test a specific frequency
    procedure test_frequency(
      constant freq_bin : integer;
      constant amplitude : real;
      constant test_name : string
    ) is
    begin
      report "Testing " & test_name & " (frequency bin k=" & integer'image(freq_bin) & ")...";
      
      -- Reset
      rst <= '1';
      wait for CLK_PERIOD * 2;
      rst <= '0';
      wait for CLK_PERIOD * 2;
      
      -- Enable filter
      enable <= '1';
      wait for CLK_PERIOD;
      enable <= '0';
      wait for CLK_PERIOD * 2;
      
      -- Generate and feed samples of a sine wave at the test frequency
      for i in 0 to SAMPLE_COUNT-1 loop
        sample := integer(amplitude * sin(2.0 * MATH_PI * real(freq_bin) * real(i) / real(SAMPLE_COUNT)));
        data_in <= to_signed(sample, DATA_WIDTH);
        data_valid_in <= '1';
        wait for CLK_PERIOD;
      end loop;
      
      data_valid_in <= '0';
      
      -- Wait for processing to complete
      wait until data_valid_out = '1' for 1 ms;
      
      if data_valid_out = '1' then
        mag_freq := magnitude_out;
        -- Split into high and low parts to avoid overflow
        mag_high := to_integer(mag_freq(DATA_WIDTH*2-1 downto 16));
        mag_low := to_integer(mag_freq(15 downto 0));
        report test_name & " - Magnitude [HEX] = 0x" & 
               integer'image(mag_high) & "_" & integer'image(mag_low);
        
        -- Store target frequency magnitude for comparison
        if freq_bin = 10 then
          mag_target := mag_freq;
        end if;
      else
        report "FAILED: No valid output received for " & test_name severity error;
      end if;
      
      wait for CLK_PERIOD * 10;
    end procedure;
    
  begin
    -- Initialize
    rst <= '1';
    enable <= '0';
    data_in <= (others => '0');
    data_valid_in <= '0';
    
    -- For testing, use coefficient for detecting frequency bin k=10 in N=100
    -- coeff = 2*cos(2*pi*k/N) = 2*cos(2*pi*10/100) = 2*cos(pi/5)
    -- Scaled to fixed point: 2*cos(pi/5) * 2^14 ~= 1.618 * 16384 ~= 26509
    coeff <= to_signed(26509, COEFF_WIDTH);
    
    wait for CLK_PERIOD * 5;
    rst <= '0';
    wait for CLK_PERIOD * 2;
    
    report "===============================================";
    report "Starting Goertzel filter frequency tests...";
    report "Target frequency bin: k=10 (out of N=100)";
    report "===============================================";
    
    -- Test 1: Target frequency (should have highest magnitude)
    test_frequency(10, 1000.0, "Target Frequency (INSIDE bin)");
    
    -- Test 2: Lower frequency outside bin
    test_frequency(5, 1000.0, "Lower Frequency (OUTSIDE bin)");
    
    -- Test 3: Higher frequency outside bin
    test_frequency(15, 1000.0, "Higher Frequency (OUTSIDE bin)");
    
    -- Test 4: Much higher frequency outside bin
    test_frequency(20, 1000.0, "Much Higher Frequency (OUTSIDE bin)");
    
    -- Test 5: Low frequency outside bin
    test_frequency(2, 1000.0, "Low Frequency (OUTSIDE bin)");
    
    -- Test 6: Very high frequency outside bin
    test_frequency(30, 1000.0, "Very High Frequency (OUTSIDE bin)");
    
    -- Test 7: Process DC signal (should produce low output)
    report "Testing DC signal (k=0, OUTSIDE bin)...";
    rst <= '1';
    wait for CLK_PERIOD * 2;
    rst <= '0';
    wait for CLK_PERIOD * 2;
    
    enable <= '1';
    wait for CLK_PERIOD;
    enable <= '0';
    wait for CLK_PERIOD * 2;
    
    for i in 0 to SAMPLE_COUNT-1 loop
      data_in <= to_signed(500, DATA_WIDTH);  -- Constant DC value
      data_valid_in <= '1';
      wait for CLK_PERIOD;
    end loop;
    
    data_valid_in <= '0';
    
    wait until data_valid_out = '1' for 1 ms;
    
    if data_valid_out = '1' then
      mag_freq := magnitude_out;
      mag_high := to_integer(mag_freq(DATA_WIDTH*2-1 downto 16));
      mag_low := to_integer(mag_freq(15 downto 0));
      report "DC Test (k=0) - Magnitude [HEX] = 0x" & 
             integer'image(mag_high) & "_" & integer'image(mag_low);
    end if;
    
    wait for CLK_PERIOD * 10;
    
    -- Final validation
    report "===============================================";
    report "Test Summary:";
    mag_high := to_integer(mag_target(DATA_WIDTH*2-1 downto 16));
    mag_low := to_integer(mag_target(15 downto 0));
    report "Target frequency (k=10) magnitude [HEX]: 0x" & 
           integer'image(mag_high) & "_" & integer'image(mag_low);
    report "Expected: Target frequency should have significantly higher magnitude";
    report "         than frequencies outside the bin.";
    report "===============================================";
    
    assert mag_target > 0 
      report "FAILURE: Target frequency magnitude should be non-zero" 
      severity error;
    
    report "All frequency tests completed!";
    test_done <= true;
    wait;
  end process;
  
end architecture test;
