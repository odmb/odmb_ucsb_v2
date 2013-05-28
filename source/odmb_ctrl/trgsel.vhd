library unisim;
library ieee;
library work;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity TRGSEL is
  port (
    RST : in std_logic;

    BTDI     : in std_logic;
    SEL2     : in std_logic;
    DRCK     : in std_logic;
    UPDATE   : in std_logic;
    SHIFT    : in std_logic;

    FLOAD    : in std_logic;

    TDO    : out std_logic;
    JTRGEN : out std_logic_vector(3 downto 0)
    );

end TRGSEL;

architecture TRGSEL_Arch of TRGSEL is

  signal SHR_EN, DR_CLK : std_logic;
  signal SHR            : std_logic_vector(4 downto 0);
  signal DR             : std_logic_vector(4 downto 1);

begin  --Architecture
  
  SHR_EN <= SHIFT and SEL2 and FLOAD;
  DR_CLK <= UPDATE and SEL2 and FLOAD;
  SHR(0) <= BTDI;
  GEN_SHR : for I in 1 to 4 generate
  begin
    FDPE_I : FDPE port map(SHR(I), DRCK, SHR_EN, RST, SHR(I-1));
    FDP_I  : FDP port map(DR(I), DR_CLK, RST, SHR(I));
  end generate GEN_SHR;
  JTRGEN(3 downto 0) <= DR(4 downto 1);
  
  TDO <= SHR(4);

end TRGSEL_Arch;
