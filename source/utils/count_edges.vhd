-- COUNT_EDGES: Counts number of rising edges in signal

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity COUNT_EDGES is
  generic (
    WIDTH : integer := 16
    );
  port (
    COUNT : out std_logic_vector(WIDTH-1 downto 0);

    CLK : in std_logic;
    RST : in std_logic;
    CE  : in std_logic
    );
end COUNT_EDGES;

architecture COUNT_EDGES_ARCH of COUNT_EDGES is
begin

  edge_cnt_proc : process (CLK, RST, CE)
    variable count_inner : std_logic_vector(WIDTH-1 downto 0);
  begin
    if (RST = '1') then
      count_inner := (others => '0');
    elsif rising_edge(CLK) then
      if CE = '1' then
        count_inner := count_inner + 1;
      end if;
    end if;
    COUNT <= count_inner;
  end process;

end COUNT_EDGES_ARCH;
