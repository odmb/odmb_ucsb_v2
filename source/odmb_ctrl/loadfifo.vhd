library unisim;
library ieee;
library work;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;

entity LOADFIFO is
  generic (
    NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
    );    
  port (
    SHIFT  : in  std_logic;
    FENF   : in  std_logic;
    BTDI   : in  std_logic;
    SEL2   : in  std_logic;
    DRCK   : in  std_logic;
    UPDATE : in  std_logic;
    RST    : in  std_logic;
    JOEF   : out std_logic_vector(NFEB+2 downto 1);
    TDO    : out std_logic);
 
    
end LOADFIFO;

architecture LOADFIFO_Arch of LOADFIFO is

  --Declaring internal signals
  signal Q1_SHIFT,Q2_SHIFT,Q3_SHIFT,LOAD,C_UPDATE : std_logic;
  signal D : std_logic_vector(2 downto 0);
  
  signal JOEF_SHR_EN, JOEF_DR_CLK, JOEF_TDO : std_logic;
  signal JOEF_SHR                           : std_logic_vector(NFEB+3 downto 1);
  signal JOEF_DR                            : std_logic_vector(NFEB+2 downto 1);


-----------

begin  --Architecture


  -- Generate JOEF
  JOEF_SHR_EN <= SHIFT and SEL2 and FENF;
  JOEF_DR_CLK <= UPDATE and SEL2 and FENF;
  JOEF_SHR(NFEB+3) <= BTDI;  
  GEN_JOEF_SHR : for I in NFEB+2 downto 1 generate
  begin
    FDCE_I : FDCE port map(JOEF_SHR(I), DRCK, JOEF_SHR_EN, RST, JOEF_SHR(I+1));
    FDC_I  : FDC port map(JOEF_DR(I), JOEF_DR_CLK, RST, JOEF_SHR(I));
  end generate GEN_JOEF_SHR;
  JOEF(NFEB+2 downto 1) <= JOEF_DR(NFEB+2 downto 1);
  JOEF_TDO                <= JOEF_SHR(1);

end LOADFIFO_Arch;
