-- FDVEC: Delays a vector one clock cycle

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity FDVEC is
  generic (
    VEC_MIN : integer := 0;
    VEC_MAX : integer := 15);
  port (
    DOUT : out std_logic_vector(VEC_MAX downto VEC_MIN);
    CLK  : in  std_logic;
    RST  : in  std_logic;
    DIN  : in  std_logic_vector(VEC_MAX downto VEC_MIN)
    );
end FDVEC;

architecture FDVEC_Arch of FDVEC is
begin  --Architecture

  GEN_DIN : for index in VEC_MIN to VEC_MAX generate
  begin
    FD_DIN : FDC port map(DOUT(index), CLK, RST, DIN(index));
  end generate GEN_DIN;

end FDVEC_Arch;
