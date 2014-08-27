-- RESET_FIFO: Creates a long-enough reset pulse, and protects against RDEN and
-- WREN during reset

library ieee;
library work;
library unisim;
use ieee.std_logic_1164.all;
use work.ucsb_types.all;
use unisim.vcomponents.all;

entity RESET_FIFO is
  generic (
    NCLOCKS : integer range 1 to 100 := 50
    );
  port (
    FIFO_RST  : out std_logic;
    FIFO_MASK : out std_logic;

    CLK     : in std_logic;
    IN_RST  : in std_logic
    );
end RESET_FIFO;

architecture RESET_FIFO_Arch of RESET_FIFO is
  signal rst_pulse, rst_dly, rst_init : std_logic := '0';
begin

  INIT_RST : FDE generic map(INIT => '1') port map(rst_init, CLK, IN_RST, '0');
  PULSE_RST : NPULSE2FAST port map(rst_pulse, CLK, '0', NCLOCKS+1, IN_RST);
  DS_RST    : DELAY_SIGNAL generic map(NCLOCKS) port map(rst_dly, CLK, NCLOCKS, rst_pulse);

  FIFO_RST  <= rst_dly;
  FIFO_MASK <= '0' when (rst_pulse = '1' or rst_dly = '1' or rst_init = '1') else '1';
  
end RESET_FIFO_Arch;
