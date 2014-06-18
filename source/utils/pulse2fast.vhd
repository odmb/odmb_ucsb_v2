-- PULSE2FAST: Creates a one clock cycle long pulse if rising edge in a
-- faster or equal clock domain.
-- Based on "Crossing the abyss: asynchonous signals in a synchronous world"

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity PULSE2FAST is
  port (
    DOUT     : out std_logic := '0';
    CLK_DOUT : in  std_logic;
    RST      : in  std_logic;
    DIN      : in  std_logic
    );
end PULSE2FAST;

architecture PULSE2FAST_Arch of PULSE2FAST is
  signal pulse : std_logic_vector(0 to 2);
begin

  FD0 : FDC generic map(INIT => '1') port map(pulse(0), CLK_DOUT, RST, DIN);
  FD1 : FDC generic map(INIT => '1') port map(pulse(1), CLK_DOUT, RST, pulse(0));
  FD2 : FDC generic map(INIT => '1') port map(pulse(2), CLK_DOUT, RST, pulse(1));

  DOUT <= pulse(1) and not pulse(2);
  
end PULSE2FAST_Arch;
