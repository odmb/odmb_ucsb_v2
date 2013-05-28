library unisim;
library ieee;
library work;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity LOADCFEB is
  generic (
    NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
    );  
  port (
    CLK : in std_logic;
    RST : in std_logic;

    CALLCT_1 : in std_logic;
    FLOAD    : in std_logic;
    BTDI     : in std_logic;
    SEL2     : in std_logic;
    DRCK     : in std_logic;
    UPDATE   : in std_logic;
    SHIFT    : in std_logic;
    RNDMLCT  : in std_logic_vector(NFEB downto 0);

    TDO    : out std_logic;
    LCTFEB : out std_logic_vector(NFEB downto 0);
    CFEB   : out std_logic_vector(NFEB downto 1)
    );

end LOADCFEB;

architecture LOADCFEB_Arch of LOADCFEB is

  signal SHR_EN, DR_CLK : std_logic;
  signal LCT_D          : std_logic_vector(NFEB downto 0);
  signal SHR            : std_logic_vector(NFEB downto 0);
  signal DR             : std_logic_vector(NFEB downto 1);

begin  --Architecture
  
  SHR_EN <= SHIFT and SEL2 and FLOAD;
  DR_CLK <= UPDATE and SEL2 and FLOAD;
  SHR(0) <= BTDI;
  GEN_SHR : for I in 1 to NFEB generate
  begin
    FDPE_I : FDPE port map(SHR(I), DRCK, SHR_EN, RST, SHR(I-1));
    FDP_I  : FDP port map(DR(I), DR_CLK, RST, SHR(I));
    --LCT_D(I) <= (CALLCT_1 or RNDMLCT(I)) and DR(I);
    LCT_D(I) <= (CALLCT_1) and DR(I);
    FD_I   : FD port map(LCTFEB(I), CLK, LCT_D(I));
  end generate GEN_SHR;
  CFEB <= DR;

  --LCT_D(0) <= or_reduce(DR) and (CALLCT_1 or RNDMLCT(0));
  LCT_D(0) <= or_reduce(DR) and (CALLCT_1);
  FD_0 : FD port map(LCTFEB(0), CLK, LCT_D(0));

end LOADCFEB_Arch;
