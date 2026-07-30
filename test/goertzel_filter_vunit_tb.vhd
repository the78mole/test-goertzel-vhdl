-------------------------------------------------------------------------------
-- Title      : Goertzel Filter VUnit Testbench
-- Project    : test-goertzel-vhdl
-------------------------------------------------------------------------------
-- File       : goertzel_filter_vunit_tb.vhd
-- Author     : 
-- Company    : 
-- Created    : 2026-02-09
-- Last update: 2026-02-09
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: VUnit testbench for the Goertzel filter module with
--              multiple test cases for comprehensive testing.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity goertzel_filter_vunit_tb is
  generic (runner_cfg : string);
end entity goertzel_filter_vunit_tb;

architecture test of goertzel_filter_vunit_tb is
  
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
  
  -- Main test process
  main: process
    variable sample : integer;
    variable mag_freq : unsigned(DATA_WIDTH*2-1 downto 0);
    
    -- Procedure to test a specific frequency
    procedure test_frequency(
      constant freq_bin : integer;
      constant amplitude : real;
      constant expected_high : boolean;
      constant test_name : string
    ) is
      variable mag_value : integer;
    begin
      info("Testing " & test_name & " (frequency bin k=" & integer'image(freq_bin) & ")");
      
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
      
      check(data_valid_out = '1', "Valid output received");
      
      if data_valid_out = '1' then
        mag_freq := magnitude_out;
        mag_value := to_integer(mag_freq);
        
        info(test_name & " - Magnitude (decimal) = " & integer'image(mag_value));
        
        -- Check magnitude expectations
        if expected_high then
          -- For target frequency, expect high magnitude (> 30000)
          check(mag_value > 30000, 
                test_name & " should have high magnitude, got " & integer'image(mag_value));
        else
          -- For non-target frequencies, expect low magnitude (< 10000)
          check(mag_value < 10000, 
                test_name & " should have low magnitude, got " & integer'image(mag_value));
        end if;
      end if;
      
      wait for CLK_PERIOD * 10;
    end procedure;
    
  begin
    test_runner_setup(runner, runner_cfg);
    
    -- Set coefficient for detecting frequency bin k=10 in N=100
    -- coeff = 2*cos(2*pi*k/N) = 2*cos(2*pi*10/100) = 2*cos(pi/5)
    -- Scaled to Q14 fixed point: 2*cos(pi/5) * 2^14 ~= 26509
    coeff <= to_signed(26509, COEFF_WIDTH);
    
    wait for CLK_PERIOD * 5;
    
    while test_suite loop
      
      if run("test_target_frequency_k10") then
        -- Test 1: Target frequency (should have highest magnitude)
        test_frequency(10, 1000.0, true, "Target Frequency k=10");
        
      elsif run("test_off_target_frequency_k5") then
        -- Test 2: Lower frequency outside bin
        test_frequency(5, 1000.0, false, "Off-Target Frequency k=5");
        
      elsif run("test_off_target_frequency_k15") then
        -- Test 3: Higher frequency outside bin
        test_frequency(15, 1000.0, false, "Off-Target Frequency k=15");
        
      elsif run("test_off_target_frequency_k20") then
        -- Test 4: Much higher frequency outside bin
        test_frequency(20, 1000.0, false, "Off-Target Frequency k=20");
        
      elsif run("test_low_frequency_k2") then
        -- Test 5: Low frequency outside bin
        test_frequency(2, 1000.0, false, "Low Frequency k=2");
        
      elsif run("test_high_frequency_k30") then
        -- Test 6: Very high frequency outside bin
        test_frequency(30, 1000.0, false, "Very High Frequency k=30");
        
      elsif run("test_dc_signal") then
        -- Test 7: DC signal (k=0, should produce low output)
        info("Testing DC signal (k=0)");
        
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
        
        check(data_valid_out = '1', "Valid output received for DC test");
        
        if data_valid_out = '1' then
          mag_freq := magnitude_out;
          info("DC Test - Magnitude (decimal) = " & integer'image(to_integer(mag_freq)));
          check(to_integer(mag_freq) < 10000, 
                "DC signal should have low magnitude");
        end if;
        
        wait for CLK_PERIOD * 10;
        
      elsif run("test_zero_input") then
        -- Test 8: All zeros input
        info("Testing zero input signal");
        
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD * 2;
        
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD * 2;
        
        for i in 0 to SAMPLE_COUNT-1 loop
          data_in <= to_signed(0, DATA_WIDTH);
          data_valid_in <= '1';
          wait for CLK_PERIOD;
        end loop;
        
        data_valid_in <= '0';
        
        wait until data_valid_out = '1' for 1 ms;
        
        check(data_valid_out = '1', "Valid output received for zero test");
        
        if data_valid_out = '1' then
          mag_freq := magnitude_out;
          info("Zero Test - Magnitude (decimal) = " & integer'image(to_integer(mag_freq)));
          check(to_integer(mag_freq) = 0, 
                "Zero input should produce zero magnitude");
        end if;
        
        wait for CLK_PERIOD * 10;
        
      elsif run("test_reset_during_processing") then
        -- Test 9: Reset during processing
        info("Testing reset during processing");
        
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD * 2;
        
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Send some samples
        for i in 0 to SAMPLE_COUNT/2-1 loop
          sample := integer(1000.0 * sin(2.0 * MATH_PI * 10.0 * real(i) / real(SAMPLE_COUNT)));
          data_in <= to_signed(sample, DATA_WIDTH);
          data_valid_in <= '1';
          wait for CLK_PERIOD;
        end loop;
        
        data_valid_in <= '0';
        
        -- Reset in the middle
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Check that the filter is idle after reset
        check(busy = '0', "Filter should be idle after reset");
        
        wait for CLK_PERIOD * 10;
        
      elsif run("test_busy_flag") then
        -- Test 10: Busy flag behavior
        info("Testing busy flag behavior");
        
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Check that busy is low initially
        check(busy = '0', "Busy should be low initially");
        
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Check that busy goes high
        check(busy = '1', "Busy should be high after enable");
        
        -- Send samples
        for i in 0 to SAMPLE_COUNT-1 loop
          sample := integer(1000.0 * sin(2.0 * MATH_PI * 10.0 * real(i) / real(SAMPLE_COUNT)));
          data_in <= to_signed(sample, DATA_WIDTH);
          data_valid_in <= '1';
          wait for CLK_PERIOD;
          
          -- Busy should remain high during processing
          if i < SAMPLE_COUNT-1 then
            check(busy = '1', "Busy should stay high during processing");
          end if;
        end loop;
        
        data_valid_in <= '0';
        
        -- Wait for processing to complete
        wait until data_valid_out = '1' for 1 ms;
        
        -- Check that busy goes low after completion
        wait for CLK_PERIOD * 2;
        check(busy = '0', "Busy should be low after completion");
        
        wait for CLK_PERIOD * 10;
        
      end if;
      
    end loop;
    
    test_done <= true;
    test_runner_cleanup(runner);
  end process;
  
  -- Watchdog timer to prevent infinite loops
  test_runner_watchdog(runner, 100 ms);
  
end architecture test;
