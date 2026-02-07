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
  begin
    -- Initialize
    rst <= '1';
    enable <= '0';
    data_in <= (others => '0');
    data_valid_in <= '0';
    
    -- For testing, use coefficient for detecting frequency bin k=10 in N=100
    -- coeff = 2*cos(2*pi*k/N) = 2*cos(2*pi*10/100) = 2*cos(pi/5)
    -- Scaled to fixed point: 2*cos(pi/5) * 2^14 ≈ 1.618 * 16384 ≈ 26509
    coeff <= to_signed(26509, COEFF_WIDTH);
    
    wait for CLK_PERIOD * 5;
    rst <= '0';
    wait for CLK_PERIOD * 2;
    
    report "Starting Goertzel filter test...";
    
    -- Test 1: Process a simple sine wave at the target frequency
    enable <= '1';
    wait for CLK_PERIOD;
    enable <= '0';
    
    wait for CLK_PERIOD * 2;
    
    -- Generate and feed 100 samples of a sine wave
    for i in 0 to SAMPLE_COUNT-1 loop
      -- Simple sine wave approximation (values between -1000 and 1000)
      sample := integer(1000.0 * sin(2.0 * MATH_PI * 10.0 * real(i) / real(SAMPLE_COUNT)));
      data_in <= to_signed(sample, DATA_WIDTH);
      data_valid_in <= '1';
      wait for CLK_PERIOD;
    end loop;
    
    data_valid_in <= '0';
    
    -- Wait for processing to complete
    wait until data_valid_out = '1' for 1 ms;
    
    if data_valid_out = '1' then
      report "Test PASSED: Magnitude output = " & 
             integer'image(to_integer(magnitude_out));
      assert magnitude_out > 0 
        report "FAILURE: Expected non-zero magnitude" 
        severity error;
    else
      report "Test FAILED: No valid output received" severity error;
    end if;
    
    wait for CLK_PERIOD * 10;
    
    -- Test 2: Process DC signal (should produce low output)
    report "Testing DC signal...";
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
      report "DC Test: Magnitude output = " & 
             integer'image(to_integer(magnitude_out));
    end if;
    
    wait for CLK_PERIOD * 10;
    
    report "All tests completed!";
    test_done <= true;
    wait;
  end process;
  
end architecture test;
