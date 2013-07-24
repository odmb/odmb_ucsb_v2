library IEEE;
use IEEE.STD_LOGIC_1164.all;

--Library UNISIM;
--use UNISIM.all;

--use UNISIM.vcomponents.all;
--use UNISIM.vpck.all;
use work.Latches_Flipflops.all;

entity  CCBCODE is
  port (
    CCB_CMD : in std_logic_vector(5 downto 0);
    CCB_CMD_S : in std_logic;
    CCB_DATA : in std_logic_vector(7 downto 0);
    CCB_DATA_S : in std_logic;
    CMSCLK : in std_logic;
    CCB_BXRST : in std_logic;
    CCB_BX0 : in std_logic;
    CCB_L1ARST : in std_logic;
    CCB_CLKEN : in std_logic;
    BX0 : out std_logic;
    BXRST : out std_logic;
    L1ARST : out std_logic;
    CLKEN : out std_logic;
    BC0 : out std_logic;  
    L1ASRST : out std_logic;
    TTCCAL : out std_logic_vector(2 downto 0)
    );
end CCBCODE;

architecture CCBCODE_arch of CCBCODE is
  
 -- signal RSTDATA : std_logic;
  signal BC0_CMD, BC0_RST, BC0_INNER : std_logic;
  signal START_TRG_CMD, START_TRG_RST, START_TRG_INNER : std_logic;
  signal STOP_TRG_CMD, STOP_TRG_RST, STOP_TRG_INNER : std_logic;
  signal L1ASRST_CMD, L1ASRST_RST, L1ASRST_CLK_CMD, L1ASRST_CNT_RST, L1ASRST_CNT_CEO, L1ASRST_INNER : std_logic;
  signal L1ASRST_CNT : std_logic_vector(3 downto 0);
  signal TTCCAL_CMD, TTCCAL_RST, TTCCAL_INNER : std_logic_vector(2 downto 0);
  signal CCBINJIN_1 : std_logic;
  signal CCBINJIN_2 : std_logic;
  signal CCBINJIN_3 : std_logic;
  signal CCBPLSIN_1 : std_logic;
  signal CCBPLSIN_2 : std_logic;
  signal CCBPLSIN_3 : std_logic;
  signal PLSINJEN_1 : std_logic;
  signal PLSINJEN_RST : std_logic;
  signal PLSINJEN_INV : std_logic;
  signal BX0_1 : std_logic;
  signal BXRST_1 : std_logic;
  signal CLKEN_1 : std_logic;
  signal L1ARST_1 : std_logic;

  signal LOGICH : std_logic := '1';

  -- commands implemented in this architecture
  -- 111110 ---> generate BC0
  -- 111001 ---> generate START_TRG
  -- 111000 ---> generate STOP_TRG
  -- 111000 ---> generate L1ASRST      
  -- 101011 ---> generate TTCCAL(0)
  -- 101010 ---> generate TTCCAL(1)
  -- 101001 ---> generate TTCCAL(2)    

begin

  -- generate RSTDATA replace with the following (apparently NOT used)
--  RSTDATA <= '1' when (CCB_CMD_S = '0' and CCB_DATA(7 downto 1) = "1010101") else '0';

  -- generate BC0
  BC0_CMD <= '1' when (CCB_CMD_S = '0' and CCB_CMD(5 downto 0) = "111110") else '0';
  FDC(BC0_CMD, CMSCLK, BC0_RST, BC0_INNER);
  FD_1(BC0_INNER, CMSCLK, BC0_RST);
  BC0 <= BC0_INNER;
  
  -- generate START_TRG command
  START_TRG_CMD <= '1' when (CCB_CMD_S = '0' and   CCB_CMD(5 downto 0) = "111001") else '0';
  FDC(START_TRG_CMD, CMSCLK, START_TRG_RST, START_TRG_INNER);
  FD_1(START_TRG_INNER, CMSCLK, START_TRG_RST);

  -- generate STOP_TRG command
  STOP_TRG_CMD <= '1' when (CCB_CMD_S = '0' and   CCB_CMD(5 downto 0) = "111000") else '0';
  FDC(STOP_TRG_CMD, CMSCLK, STOP_TRG_RST, STOP_TRG_INNER);
  FD_1(STOP_TRG_INNER, CMSCLK, STOP_TRG_RST);

  -- generate L1ASRST
  L1ASRST_CMD <= '1' when (CCB_CMD(5 downto 0) = "111100" and CCB_CMD_S = '0') else '0';
  FD(L1ASRST_CMD, CMSCLK, L1ASRST_CLK_CMD);
  FDC(LOGICH, L1ASRST_CLK_CMD, L1ASRST_RST, L1ASRST_INNER);
  L1ASRST_CNT_RST <= not L1ASRST_INNER;
  CB4CE(CMSCLK, L1ASRST_INNER, L1ASRST_CNT_RST, L1ASRST_CNT, L1ASRST_CNT, L1ASRST_CNT_CEO, L1ASRST_RST);
  L1ASRST <= L1ASRST_INNER;
  
  -- generate TTCCAL
  TTCCAL_CMD(0) <= '1' when (CCB_CMD_S = '0' and   CCB_CMD(5 downto 0) = "101011") else '0';
  FDC(TTCCAL_CMD(0), CMSCLK, TTCCAL_RST(0), TTCCAL_INNER(0));
--  FD_1(TTCCAL_INNER(0), CMSCLK, TTCCAL_RST(0));
  FD(TTCCAL_INNER(0), CMSCLK, TTCCAL_RST(0));

  TTCCAL_CMD(1) <= '1' when (CCB_CMD_S = '0' and   CCB_CMD(5 downto 0) = "101010") else '0';
  FDC(TTCCAL_CMD(1), CMSCLK, TTCCAL_RST(1), TTCCAL_INNER(1));
--  FD_1(TTCCAL_INNER(1), CMSCLK, TTCCAL_RST(1));
  FD(TTCCAL_INNER(1), CMSCLK, TTCCAL_RST(1));

  TTCCAL_CMD(2) <= '1' when (CCB_CMD_S = '0' and   CCB_CMD(5 downto 0) = "101001") else '0';
  FDC(TTCCAL_CMD(2), CMSCLK, TTCCAL_RST(2), TTCCAL_INNER(2));
--  FD_1(TTCCAL_INNER(2), CMSCLK, TTCCAL_RST(2));
  FD(TTCCAL_INNER(2), CMSCLK, TTCCAL_RST(2));
  
  TTCCAL <= TTCCAL_INNER;
  
  -- generate BX0, BXRST, CLKENA, L1ARST
  IFD(CCB_BX0   , CMSCLK, BX0_1   );
  IFD(CCB_BXRST , CMSCLK, BXRST_1 );
  IFD(CCB_CLKEN , CMSCLK, CLKEN_1);
  IFD(CCB_L1ARST, CMSCLK, L1ARST_1);

  BX0    <= not BX0_1;
  BXRST  <= not BXRST_1;
  CLKEN <= not CLKEN_1;
  L1ARST <= not L1ARST_1;

end CCBCODE_arch;
