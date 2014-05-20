-- CROSSCLOCK: Takes a level signal from one clock domain to a different one

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity CROSSCLOCK is
  port (
    DOUT     : out std_logic;
    CLK_DOUT : in  std_logic;
    CLK_DIN  : in  std_logic;
    RST      : in  std_logic;
    DIN      : in  std_logic
    );
end CROSSCLOCK;

architecture CROSSCLOCK_Arch of CROSSCLOCK is
  signal level : std_logic_vector(0 to 4);
begin
  -- Fast clock domain (CLK_DIN)
  FD1 : FDC port map(level(0), CLK_DIN, RST, DIN);

  -- Slow clock domain (CLK_DOUT)
  FD2 : FDC port map(level(1), CLK_DOUT, RST, level(0));
  FD3 : FDC port map(DOUT, CLK_DOUT, RST, level(1));
  
end CROSSCLOCK_Arch;
