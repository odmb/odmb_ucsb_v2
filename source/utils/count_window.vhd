-- COUNT_WINDOW: Counts number of CCs a signal is high in time window

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use work.ucsb_types.all;

entity COUNT_WINDOW is
  generic (
    WIDTH : integer := 16;
    WINDOW : integer := 63 -- In CC
    );
  port (
    COUNT : out std_logic_vector(WIDTH-1 downto 0);

    CLK : in std_logic;
    RST : in std_logic;
    DIN  : in std_logic
    );
end COUNT_WINDOW;

architecture COUNT_WINDOW_ARCH of COUNT_WINDOW is
  signal din_q, din_q_window : std_logic := '0';
  signal count_inner : std_logic_vector(WIDTH-1 downto 0);  
begin

  -- Sync input signal
  FDDIN : FDC port map(din_q, CLK, RST, DIN);

  -- Delay input signal by WINDOW CCs
  DS_DIN : DELAY_SIGNAL generic map(WINDOW) port map(din_q_window, CLK, WINDOW, din_q);

  
  edge_cnt_proc : process (CLK, RST)
  begin
    if (RST = '1') then
      count_inner <= (others => '0');
    elsif rising_edge(CLK) then
      if din_q = '1' and din_q_window = '0' then
        count_inner <= count_inner + 1;
      elsif din_q = '0' and din_q_window = '1' then
        count_inner <= count_inner - 1;
      else     
        count_inner <= count_inner;
      end if;
    end if;
    COUNT <= count_inner;
  end process;

end COUNT_WINDOW_ARCH;
