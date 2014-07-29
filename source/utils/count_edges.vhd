-- COUNT_EDGES: Counts number of rising edges in signal

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity COUNT_EDGES is
  generic (
    WIDTH : integer := 16
    );
  port (
    COUNT : out std_logic_vector(WIDTH-1 downto 0);

    CLK : in std_logic;
    RST : in std_logic;
    DIN  : in std_logic
    );
end COUNT_EDGES;

architecture COUNT_EDGES_ARCH of COUNT_EDGES is
  signal din_q, din_qq : std_logic := '0';
  signal count_inner : std_logic_vector(WIDTH-1 downto 0);  
begin

  FDDIN : FDC port map(din_q, CLK, RST, DIN);
  FDDIN2 : FDC port map(din_qq, CLK, RST, din_q);
  
  edge_cnt_proc : process (CLK, RST)
  begin
    if (RST = '1') then
      count_inner <= (others => '0');
    elsif rising_edge(CLK) then
      if din_q = '1' and din_qq = '0' then
        count_inner <= count_inner + 1;
      end if;
    end if;
    COUNT <= count_inner;
  end process;

end COUNT_EDGES_ARCH;
