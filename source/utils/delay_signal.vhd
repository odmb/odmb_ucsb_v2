-- DELAY_SIGNAL: Delays a signal a number of clock cycles with respect to a clock

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity DELAY_SIGNAL is
  generic (NCYCLES_MAX : integer := 63);
  port (
    DOUT    : out std_logic;
    CLK     : in  std_logic;
    NCYCLES : in  integer range 0 to NCYCLES_MAX;
    DIN     : in  std_logic
    );
end DELAY_SIGNAL;

architecture DELAY_SIGNAL_Arch of DELAY_SIGNAL is

  signal din_vector : std_logic_vector(NCYCLES_MAX downto 0) := (others => '0');

begin  --Architecture

  din_vector(0) <= DIN;
  GEN_DIN : for index in 1 to NCYCLES_MAX generate
  begin
    FD_DIN : FD generic map(INIT => '0') port map(din_vector(index), CLK, din_vector(index-1));
  end generate GEN_DIN;

  DOUT <= din_vector(NCYCLES);

end DELAY_SIGNAL_Arch;
