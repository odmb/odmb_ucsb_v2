-- PULSE2SAME: Creates a one clock cycle long pulse if rising edge in the
-- same clock domain.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity PULSE2SAME is
  port (
    DOUT     : out std_logic;
    CLK_DOUT : in  std_logic;
    RST      : in  std_logic;
    DIN      : in  std_logic
    );
end PULSE2SAME;

architecture PULSE2SAME_Arch of PULSE2SAME is
  signal pulse : std_logic_vector(0 to 1);
begin

  FD0 : FDC generic map(INIT => '1') port map(pulse(0), CLK_DOUT, RST, DIN);
  FD1 : FDC generic map(INIT => '1') port map(pulse(1), CLK_DOUT, RST, pulse(0));

  DOUT <= pulse(0) and not pulse(1);
  
end PULSE2SAME_Arch;
