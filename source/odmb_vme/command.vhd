library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.vcomponents.all;
library work;
library hdlmacro; use hdlmacro.hdlmacro.all;

entity COMMAND_MODULE is
  port (

    FASTCLK : in std_logic;
    SLOWCLK : in std_logic;

    GA  : in std_logic_vector(5 downto 0);
    ADR : in std_logic_vector(23 downto 1);
    AM  : in std_logic_vector(5 downto 0);

    AS      : in std_logic;
    DS0     : in std_logic;
    DS1     : in std_logic;
    LWORD   : in std_logic;
    WRITER  : in std_logic;  --NOTE: this is the only signal whose name was changed
    IACK    : in std_logic;
    BERR    : in std_logic;
    SYSFAIL : in std_logic;

    DEVICE  : out std_logic_vector(9 downto 0);
    STROBE  : out std_logic;
    COMMAND : out std_logic_vector(9 downto 0);
    ADRS    : out std_logic_vector(17 downto 2);  --NOTE: output of ADRS

    TOVME_B : out std_logic;
    DOE_B   : out std_logic;

    DIAGOUT : out std_logic_vector(19 downto 0);
    LED     : out std_logic_vector(2 downto 0)

    );
end COMMAND_MODULE;

architecture COMMAND_MODULE_Arch of COMMAND_MODULE is

  --Declaring internal signals
  signal CGA           : std_logic_vector(5 downto 0);  --NOTE: replacing CGAP with CGA(5)
  signal AMS           : std_logic_vector(5 downto 0);
  signal ADRS_INNER    : std_logic_vector(23 downto 1);
  signal GOODAM        : std_logic;
  signal VALIDAM       : std_logic;
  signal VALIDGA       : std_logic;
  signal SYSOK         : std_logic;
  signal OLDCRATE      : std_logic;
  signal PRE_BOARDENB  : std_logic;
  signal BROADCAST     : std_logic;
  signal BOARDENB      : std_logic;
  signal BOARD_SEL_NEW : std_logic;
  signal ASYNSTRB      : std_logic;
  signal ASYNSTRB_NOT  : std_logic;
  signal FASTCLK_NOT   : std_logic;
  signal STROBE_TEMP1  : std_logic;
  signal STROBE_TEMP2  : std_logic;
  signal ADRSHIGH      : std_logic;

  signal D1, C1, Q1, D2, C2, Q2, D3, C3, Q3, D4, C4                                             : std_logic;
  signal D1_second, C1_second, Q1_second, D2_second, C2_second, Q2_seconD                       : std_logic;
  signal D3_second, C3_second, Q3_second, D4_second, C4_second, Q4_second, D5_second, C5_second : std_logic;
  signal TOVME_INNER                                                                            : std_logic;

  signal CE_DOE_B, CLR_DOE_B : std_logic;
  signal TIMER               : std_logic_vector(7 downto 0);
  signal TOVME_INNER_B       : std_logic;
  signal ADRSDEV             : std_logic_vector(4 downto 0);

  -----------------------------------------------------------------------------

begin  --Architecture

  -- Generate DOE_B
  CE_DOE_B  <= '1' when TOVME_INNER_B = '0' and TIMER(7) = '0' else '0';
  CLR_DOE_B <= TOVME_INNER_B;
  CB8CE_DOE : CB8CE port map (open, TIMER, open, SLOWCLK, CE_DOE_B, CLR_DOE_B);
  DOE_B     <= TIMER(7);

  -- Generate VALIDGA
  CGA     <= not GA;
  VALIDGA <= '1' when ((CGA(0) xor CGA(1) xor CGA(2) xor CGA(3) xor CGA(4) xor CGA(5)) = '1') else '0';

  -- Generate OLDCRATE / Generate AMS / Generate VALIDAM / Generate GOODAM / Generate FASTCLK_NOT
  OLDCRATE <= '1' when CGA = "000000" else '0';

  ILD_AM_GEN : for i in 0 to 5 generate
  begin
    ILD_AM : ILD port map(AMS(i), AM(i), AS);
  end generate ILD_AM_GEN;
  VALIDAM     <= '1' when (AMS(0) /= AMS(1) and AMS(5 downto 3) = "111" and LWORD = '1') else '0';
  GOODAM      <= '1' when (AMS(0) /= AMS(1) and AMS(5 downto 3) = "111" and LWORD = '1') else '0';
  FASTCLK_NOT <= not FASTCLK;

  -- Generate STROBE
  ILD_ADRS_GEN : for i in 1 to 23 generate
  begin
    ILD_ADRS : ILD port map(ADRS_INNER(i), ADR(i), AS);
  end generate ILD_ADRS_GEN;

  BOARD_SEL_NEW <= '1' when (ADRS_INNER(23 downto 19) = CGA(4 downto 0))              else '0';
  PRE_BOARDENB  <= '1' when (BOARD_SEL_NEW = '1' and VALIDGA = '1')                   else '0';
  BROADCAST     <= '1' when (ADRS_INNER(23 downto 19) = "11111")                      else '0';
  BOARDENB      <= '1' when (OLDCRATE = '1' or PRE_BOARDENB = '1' or BROADCAST = '1') else '0';
  SYSOK         <= '1' when (SYSFAIL = '1' and IACK = '1')                            else '0';

  (TOVME_INNER_B, TOVME_B, LED(0)) <= std_logic_vector'("001") when (GOODAM = '1' and WRITER = '1' and SYSOK = '1' and BOARDENB = '1') else
                                      std_logic_vector'("110");
  ASYNSTRB     <= '1' when (SYSOK = '1' and VALIDAM = '1' and BOARDENB = '1' and DS0 = '0' and DS1 = '0') else '0';
  ASYNSTRB_NOT <= not ASYNSTRB;

  FDC_STROBE   : FDC port map(STROBE_TEMP1, FASTCLK, ASYNSTRB_NOT, ASYNSTRB);
  FDC_1_STROBE : FDC_1 port map(STROBE_TEMP2, FASTCLK, ASYNSTRB_NOT, ASYNSTRB);
  STROBE <= '1' when (STROBE_TEMP1 = '1' and STROBE_TEMP2 = '1') else '0';

  -- Generate LED(1) / Generate LED(2)
  LED(1) <= not ASYNSTRB;
  LED(2) <= '0' when (STROBE_TEMP1 = '1' and STROBE_TEMP2 = '1') else '1';

  -- Generate DIAGOUT -Guido-
  DIAGOUT(0)  <= ADRS_INNER(23);
  DIAGOUT(1)  <= CGA(4);
  DIAGOUT(2)  <= ADRS_INNER(21);
  DIAGOUT(3)  <= CGA(2);
  DIAGOUT(4)  <= ADRS_INNER(22);
  DIAGOUT(5)  <= CGA(3);
  DIAGOUT(6)  <= ADRS_INNER(20);
  DIAGOUT(7)  <= CGA(1);
  DIAGOUT(8)  <= ADRS_INNER(19);
  DIAGOUT(9)  <= CGA(0);
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
  COMMAND(9 downto 0) <= ADRS_INNER(11 downto 2);

  -- Generate ADRS
  ADRS <= ADRS_INNER(17 downto 2);

  -- Generate DEVICE
  ADRSHIGH <= '1' when (ADRS_INNER(18) = '1' or ADRS_INNER(17) = '1' or ADRS_INNER(16) = '1') else '0';
  ADRSDEV  <= ADRSHIGH & ADRS_INNER(15) & ADRS_INNER(14) & ADRS_INNER(13) & ADRS_INNER(12);

  with ADRSDEV select
    DEVICE <= "0000000001" when "00000",
    "0000000010"           when "00001",
    "0000000100"           when "00010",
    "0000001000"           when "00011",
    "0000010000"           when "00100",
    "0000100000"           when "00101",
    "0001000000"           when "00110",
    "0010000000"           when "00111",
    "0100000000"           when "01000",
    "1000000000"           when "01001",
    "0000000000"           when others;
  
end COMMAND_MODULE_Arch;
