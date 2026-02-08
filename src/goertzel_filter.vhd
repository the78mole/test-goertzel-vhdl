-------------------------------------------------------------------------------
-- Title      : Goertzel Filter
-- Project    : test-goertzel-vhdl
-------------------------------------------------------------------------------
-- File       : goertzel_filter.vhd
-- Author     : 
-- Company    : 
-- Created    : 2026-02-07
-- Last update: 2026-02-07
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Parametrizable digital filter using the Goertzel algorithm.
--              The Goertzel algorithm is an efficient method for detecting
--              specific frequency components in a signal, similar to computing
--              a single bin of a DFT.
-------------------------------------------------------------------------------
-- License    : See LICENSE file
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity goertzel_filter is
  generic (
    DATA_WIDTH    : integer := 16;    -- Input data width
    COEFF_WIDTH   : integer := 16;    -- Coefficient width
    SAMPLE_COUNT  : integer := 100    -- Number of samples (N)
  );
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;
    enable        : in  std_logic;
    data_in       : in  signed(DATA_WIDTH-1 downto 0);
    data_valid_in : in  std_logic;
    coeff         : in  signed(COEFF_WIDTH-1 downto 0);  -- 2*cos(2*pi*k/N) in Q15 format
    
    magnitude_out : out unsigned(DATA_WIDTH*2-1 downto 0);
    data_valid_out: out std_logic;
    busy          : out std_logic
  );
end entity goertzel_filter;

architecture rtl of goertzel_filter is
  
  -- Internal signals for Goertzel algorithm
  signal s1, s2           : signed(DATA_WIDTH*2-1 downto 0);
  signal sample_counter   : integer range 0 to SAMPLE_COUNT;
  signal processing       : std_logic;
  signal magnitude_reg    : unsigned(DATA_WIDTH*2-1 downto 0);
  signal valid_out_reg    : std_logic;
  
  -- State machine
  type state_type is (IDLE, PROCESSING_SAMPLES, CALCULATE_MAGNITUDE);
  signal state : state_type;
  
begin
  
  busy <= processing;
  magnitude_out <= magnitude_reg;
  data_valid_out <= valid_out_reg;
  
  process(clk)
    variable s0 : signed(DATA_WIDTH*2-1 downto 0);
    variable temp : signed(DATA_WIDTH*3-1 downto 0);
    variable temp_scaled : signed(DATA_WIDTH*2-1 downto 0);
    variable s1_sq : signed(DATA_WIDTH*4-1 downto 0);
    variable s2_sq : signed(DATA_WIDTH*4-1 downto 0);
    variable cross_term : signed(DATA_WIDTH*4-1 downto 0);
    variable coeff_s1_s2 : signed(DATA_WIDTH*5-1 downto 0);
    variable mag_sq : signed(DATA_WIDTH*4-1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        s1 <= (others => '0');
        s2 <= (others => '0');
        sample_counter <= 0;
        processing <= '0';
        state <= IDLE;
        magnitude_reg <= (others => '0');
        valid_out_reg <= '0';
        
      else
        -- Default values
        valid_out_reg <= '0';
        
        case state is
          
          when IDLE =>
            if enable = '1' then
              s1 <= (others => '0');
              s2 <= (others => '0');
              sample_counter <= 0;
              processing <= '1';
              state <= PROCESSING_SAMPLES;
            end if;
            
          when PROCESSING_SAMPLES =>
            if data_valid_in = '1' then
              -- Goertzel iteration: s(n) = x(n) + coeff * s(n-1) - s(n-2)
              -- where coeff = 2*cos(2*pi*k/N) in Q(COEFF_WIDTH-2) format (e.g., Q14)
              
              -- temp = coeff * s1 (multiply coefficient by previous state)
              temp := s1 * coeff;
              -- Scale down by coefficient fixed-point position (shift right by 14 bits for Q14)
              temp_scaled := resize(temp(DATA_WIDTH*3-1 downto 14), DATA_WIDTH*2);
              
              -- s0 = x(n) + temp_scaled - s2
              s0 := resize(data_in, DATA_WIDTH*2) + temp_scaled - s2;
              
              -- Update state pipeline: s(n-2) <= s(n-1), s(n-1) <= s(n)
              s2 <= s1;
              s1 <= s0;
              
              sample_counter <= sample_counter + 1;
              
              if sample_counter = SAMPLE_COUNT - 1 then
                state <= CALCULATE_MAGNITUDE;
              end if;
            end if;
            
          when CALCULATE_MAGNITUDE =>
            -- Goertzel magnitude calculation:
            -- magnitude^2 = s1^2 + s2^2 - coeff * s1 * s2
            -- where s1 = s(N), s2 = s(N-1)
            
            s1_sq := s1 * s1;
            s2_sq := s2 * s2;
            
            -- Cross term: coeff * s1 * s2 (in Q14 format)
            coeff_s1_s2 := s1 * s2 * coeff;
            -- Scale down from Q14
            cross_term := resize(coeff_s1_s2(DATA_WIDTH*5-1 downto 14), DATA_WIDTH*4);
            
            -- magnitude^2 = s1^2 + s2^2 - cross_term
            mag_sq := s1_sq + s2_sq - cross_term;
            
            -- Ensure non-negative result
            if mag_sq < 0 then
              magnitude_reg <= (others => '0');
            else
              -- Scale down to fit output width
              -- Take middle bits to represent the magnitude squared
              magnitude_reg <= unsigned(mag_sq(DATA_WIDTH*3-1 downto DATA_WIDTH));
            end if;
            
            valid_out_reg <= '1';
            processing <= '0';
            state <= IDLE;
            
        end case;
      end if;
    end if;
  end process;
  
end architecture rtl;
