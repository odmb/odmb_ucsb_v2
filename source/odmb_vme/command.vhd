library ieee;
library work;
use work.Latches_Flipflops.all;
use ieee.std_logic_1164.all;

entity COMMAND_MODULE is
  port (

    FASTCLK: in std_logic;
    SLOWCLK: in std_logic;

    GA : in std_logic_vector(5 downto 0);
    ADR : in std_logic_vector(23 downto 1);
    AM : in std_logic_vector(5 downto 0);

    AS : in std_logic;
    DS0 : in std_logic;
    DS1 : in std_logic;
    LWORD : in std_logic;
    WRITER : in std_logic; --NOTE: this is the only signal whose name was changed
    IACK : in std_logic;
    BERR : in std_logic;
    SYSFAIL : in std_logic;
    
    DEVICE   : out std_logic_vector(9 downto 0);
    STROBE   : out std_logic;
    COMMAND  : out std_logic_vector(9 downto 0);
    ADRS     : out std_logic_vector(17 downto 2);  --NOTE: output of ADRS
 
    TOVME_B    : out std_logic;
    DOE_B    : out std_logic;
 	 
    DIAGOUT  : out std_logic_vector(19 downto 0);
    LED      : out std_logic_vector(2 downto 0)
	 
    );
end COMMAND_MODULE;

architecture COMMAND_MODULE_Arch of COMMAND_MODULE is

  --Declaring internal signals
  signal CGA : std_logic_vector(5 downto 0);  --NOTE: replacing CGAP with CGA(5)
  signal AMS : std_logic_vector(5 downto 0);
  SIGNAL ADRS_INNER : std_logic_vector(23 downto 1);
  signal GOODAM : std_logic;
  signal VALIDAM : std_logic;
  signal VALIDGA : std_logic;
  signal SYSOK : std_logic;
  signal OLDCRATE : std_logic;
  signal PRE_BOARDENB : std_logic;
  signal BROADCAST : std_logic;
  signal BOARDENB : std_logic;
  signal BOARD_SEL_NEW : std_logic;
  signal ASYNSTRB : std_logic;
  signal ASYNSTRB_NOT : std_logic;
  signal FASTCLK_NOT : std_logic;
  signal STROBE_TEMP1 : std_logic;
  signal STROBE_TEMP2 : std_logic;
  signal ADRSHIGH : std_logic;
  signal D1,C1,Q1,D2,C2,Q2,D3,C3,Q3,D4,C4 : std_logic;
  signal D1_second,C1_second,Q1_second,D2_second,C2_second,Q2_seconD : std_logic;
  signal D3_second,C3_second,Q3_second,D4_second,C4_second,Q4_second,D5_second,C5_second : std_logic;
  signal TOVME_INNER : std_logic;
 
  signal CE_DOE_B, CLR_DOE_B : std_logic;
  signal TIMER : std_logic_vector(7 downto 0);
  signal TOVME_INNER_B : std_logic;
  signal blank1, blank2 : std_logic;
  signal ADRSDEV : std_logic_vector(4 downto 0);
 
  -----------------------------------------------------------------------------

begin  --Architecture

	-- Generate DOE_B
	CE_DOE_B <= '1' when TOVME_INNER_B='0' and TIMER(7)='0' else '0';
   CLR_DOE_B <= TOVME_INNER_B;
   CB8CE(SLOWCLK,CE_DOE_B,CLR_DOE_B,TIMER,TIMER,blank1,blank2);
	DOE_B <= TIMER(7);

	-- Generate VALIDGA
   CGA <= not GA;
	VALIDGA <= '1' when ((CGA(0) xor CGA(1) xor CGA(2) xor CGA(3) xor CGA(4) xor CGA(5))='1') else '0';        

	-- Generate OLDCRATE / Generate AMS / Generate VALIDAM / Generate GOODAM / Generate FASTCLK_NOT
	OLDCRATE <= '1' when CGA="000000" else '0';
   ILD6(AM(5 downto 0),AS,AMS(5 downto 0));  
	VALIDAM <= '1' when (AMS(0)/=AMS(1) and AMS(3)='1' and AMS(4)='1' and AMS(5)='1' and LWORD='1') else '0';
	GOODAM  <= '1' when (AMS(0)/=AMS(1) and AMS(3)='1' and AMS(4)='1' and AMS(5)='1' and LWORD='1') else '0';
   FASTCLK_NOT <= not FASTCLK;
  
	-- Generate STROBE
	ILD6(ADR(23 downto 18),AS,ADRS_INNER(23 downto 18));
   BOARD_SEL_NEW <= '1' when (ADRS_INNER(23)=CGA(4) and ADRS_INNER(22)=CGA(3) and ADRS_INNER(21)=CGA(2) and ADRS_INNER(20)=CGA(1) and ADRS_INNER(19)=CGA(0)) else '0';
	PRE_BOARDENB <= '1' when (BOARD_SEL_NEW='1' and VALIDGA='1') else '0';
	BROADCAST <= '1' when (ADRS_INNER(21)='0' and ADRS_INNER(19)='1' and ADRS_INNER(22)='1' and ADRS_INNER(23)='1') else '0';
	BOARDENB <= '1' when (OLDCRATE='1' or PRE_BOARDENB='1' or BROADCAST='1') else '0';
	SYSOK <= '1' when (SYSFAIL='1' and IACK='1') else '0';
	(TOVME_INNER_B, TOVME_B, LED(0)) <= std_logic_vector'("001") when (GOODAM='1' and WRITER='1' and SYSOK='1' and BOARDENB='1') else
													std_logic_vector'("110");
	ASYNSTRB <= '1' when (SYSOK='1' and VALIDAM='1' and BOARDENB='1' and DS0='0' and DS1='0') else '0';
   ASYNSTRB_NOT <= not ASYNSTRB;
   FDC(ASYNSTRB,FASTCLK,ASYNSTRB_NOT,STROBE_TEMP1);
   FDC_1(ASYNSTRB,FASTCLK,ASYNSTRB_NOT,STROBE_TEMP2);
	STROBE <= '1' when (STROBE_TEMP1='1' and STROBE_TEMP2='1') else '0';
	
	-- Generate LED(1) / Generate LED(2)
   LED(1) <= not ASYNSTRB;
	LED(2) <= '0' when (STROBE_TEMP1='1' and STROBE_TEMP2='1') else '1';

	-- Generate DIAGOUT -Guido-
    DIAGOUT(0) <= ADRS_INNER(23);
    DIAGOUT(1) <= CGA(4);
    DIAGOUT(2) <= ADRS_INNER(21);
    DIAGOUT(3) <= CGA(2);
    DIAGOUT(4) <= ADRS_INNER(22);
    DIAGOUT(5) <= CGA(3);
    DIAGOUT(6) <= ADRS_INNER(20);
    DIAGOUT(7) <= CGA(1);
    DIAGOUT(8) <= ADRS_INNER(19);
    DIAGOUT(9) <= CGA(0);
    DIAGOUT(10) <= CGA(5);
    DIAGOUT(11) <= VALIDGA;
    DIAGOUT(12) <= SYSOK;
    DIAGOUT(13) <= VALIDAM;
    DIAGOUT(14) <= BOARD_SEL_NEW;
    DIAGOUT(15) <= DS0;
    DIAGOUT(16) <= ASYNSTRB;
    DIAGOUT(17) <= STROBE_TEMP1;
    DIAGOUT(18) <= STROBE_TEMP2;
    DIAGOUT(19) <= FASTCLK_NOT;

	-- Generate COMMAND
    COMMAND(0) <= ADRS_INNER(2);
    COMMAND(1) <= ADRS_INNER(3);
    COMMAND(2) <= ADRS_INNER(4);
    COMMAND(3) <= ADRS_INNER(5);
    COMMAND(4) <= ADRS_INNER(6);
    COMMAND(5) <= ADRS_INNER(7);
    COMMAND(6) <= ADRS_INNER(8);
    COMMAND(7) <= ADRS_INNER(9);
    COMMAND(8) <= ADRS_INNER(10);
    COMMAND(9) <= ADRS_INNER(11);

	-- Generate ADRS
   ILD6(ADR(18 downto 13),AS,ADRS_INNER(18 downto 13));
   ILD6(ADR(12 downto 7),AS,ADRS_INNER(12 downto 7));
   ILD6(ADR(6 downto 1),AS,ADRS_INNER(6 downto 1));
   ADRS <= ADRS_INNER(17 downto 2);

  -- Generate DEVICE
  ADRSHIGH <= '1' when (ADRS_INNER(18)='1' or ADRS_INNER(17)='1' or ADRS_INNER(16)='1') else '0';
  ADRSDEV <= ADRSHIGH & ADRS_INNER(15) & ADRS_INNER(14) & ADRS_INNER(13) & ADRS_INNER(12);
  DEVICE(0) <= '1' when ADRSDEV="00000" else '0';
  DEVICE(1) <= '1' when ADRSDEV="00001" else '0';
  DEVICE(2) <= '1' when ADRSDEV="00010" else '0';
  DEVICE(3) <= '1' when ADRSDEV="00011" else '0';
  DEVICE(4) <= '1' when ADRSDEV="00100" else '0';
  DEVICE(5) <= '1' when ADRSDEV="00101" else '0';
  DEVICE(6) <= '1' when ADRSDEV="00110" else '0';
  DEVICE(7) <= '1' when ADRSDEV="00111" else '0';
  DEVICE(8) <= '1' when ADRSDEV="01000" else '0';
  DEVICE(9) <= '1' when ADRSDEV="01001" else '0';
--  DEVICE(10) <= '1' when ADRSDEV="01010" else '0';
--  DEVICE(11) <= '1' when ADRSDEV="01011" else '0';
--  DEVICE(12) <= '1' when ADRSDEV="01100" else '0';
--  DEVICE(13) <= '1' when ADRSDEV="01101" else '0';
--  DEVICE(14) <= '1' when ADRSDEV="01110" else '0';
--  DEVICE(15) <= '1' when ADRSDEV="01111" else '0';
  
end COMMAND_MODULE_Arch;
