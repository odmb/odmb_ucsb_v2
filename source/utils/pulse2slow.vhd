-- PULSE2SLOW: Creates a one clock cycle long pulse if rising edge in a
-- slower clock domain.
-- Based on "Crossing the abyss: asynchonous signals in a synchronous world"

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity PULSE2SLOW is
  port (
    DOUT     : out std_logic;
    CLK_DOUT : in  std_logic;
    CLK_DIN  : in  std_logic;
    RST      : in  std_logic;
    DIN      : in  std_logic
    );
end PULSE2SLOW;

architecture PULSE2SLOW_Arch of PULSE2SLOW is
  signal pulse : std_logic_vector(0 to 4);
begin
  -- Fast clock domain (CLK_DIN)
  pulse(0) <= pulse(1) when DIN = '0' else not pulse(1);
  FD1 : FDC port map(pulse(1), CLK_DIN, RST, pulse(0));

  -- Slow clock domain (CLK_DOUT)
  FD2 : FDC port map(pulse(2), CLK_DOUT, RST, pulse(1));
  FD3 : FDC port map(pulse(3), CLK_DOUT, RST, pulse(2));
  FD4 : FDC port map(pulse(4), CLK_DOUT, RST, pulse(3));

  DOUT <= pulse(3) xor pulse(4);
  
end PULSE2SLOW_Arch;
