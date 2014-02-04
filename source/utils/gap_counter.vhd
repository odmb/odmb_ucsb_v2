-- GAP_COUNTER: Counts number of clock cycles between signal1 and signal2

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity GAP_COUNTER is
  generic(MAX_CYCLES : integer := 63);
  port (
    GAP_COUNT : out std_logic_vector(15 downto 0);

    CLK     : in std_logic;
    RST     : in std_logic;
    SIGNAL1 : in std_logic;
    SIGNAL2 : in std_logic
    );
end GAP_COUNTER;

architecture GAP_COUNTER_Arch of GAP_COUNTER is

  type   gap_state_type is (GAP_IDLE, GAP_COUNTING);
  signal gap_next_state, gap_current_state : gap_state_type;
  signal gap_cnt_rst, gap_cnt_en           : std_logic;
  signal gap_cnt_int : integer range 0 to MAX_CYCLES;
  
begin  --Architecture

  gap_cnt : process (CLK, RST, gap_cnt_rst, gap_cnt_en)
    variable gap_cnt_data : integer range 0 to MAX_CYCLES;
  begin
    if (RST = '1') then
      gap_cnt_data := 0;
    elsif (rising_edge(CLK)) then
      if (gap_cnt_rst = '1') then
        gap_cnt_data := 0;
      elsif (gap_cnt_en = '1') then
        gap_cnt_data := gap_cnt_data + 1;
      end if;
    end if;

    gap_cnt_int <= gap_cnt_data;
  end process;

  GAP_COUNT <= std_logic_vector(to_unsigned(gap_cnt_int,16));  

  gap_fsm_regs : process (gap_next_state, RST, CLK)
  begin
    if (RST = '1') then
      gap_current_state <= GAP_IDLE;
    elsif rising_edge(CLK) then
      gap_current_state <= gap_next_state;
    end if;
  end process;

  gap_fsm_logic : process (gap_current_state, signal1, signal2, gap_cnt_int)
  begin
    case gap_current_state is
      when GAP_IDLE =>
        if (signal1 = '1') then
          gap_next_state <= GAP_COUNTING;
          gap_cnt_rst    <= '1';
          gap_cnt_en     <= '0';
        else
          gap_next_state <= GAP_IDLE;
          gap_cnt_rst    <= '0';
          gap_cnt_en     <= '0';
        end if;
        
      when GAP_COUNTING =>
        gap_cnt_rst <= '0';
        if (signal2 = '1' or gap_cnt_int = MAX_CYCLES) then
          gap_next_state <= GAP_IDLE;
          gap_cnt_en     <= '0';
        else
          gap_next_state <= GAP_COUNTING;
          gap_cnt_en     <= '1';
        end if;

      when others =>
        gap_next_state <= GAP_IDLE;
        gap_cnt_rst    <= '1';
        gap_cnt_en     <= '0';
    end case;
  end process;


end GAP_COUNTER_Arch;
