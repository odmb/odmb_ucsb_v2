-- VMEMON: Sends out FLFCTRL with monitoring values

library ieee;
library work;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VMEMON is
  port (

    SLOWCLK : in std_logic;
    RST     : in std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    FW_RESET : out std_logic;
    RESYNC   : out std_logic;
    REPROG_B : out std_logic;
    TEST_INJ : out std_logic;
    TEST_PLS : out std_logic;

    TP_SEL     : out std_logic_vector(15 downto 0);
    ODMB_CTRL  : out std_logic_vector(15 downto 0);
    DCFEB_CTRL : out std_logic_vector(15 downto 0);
    ODMB_DATA  : in  std_logic_vector(15 downto 0)

    );
end VMEMON;


architecture VMEMON_Arch of VMEMON is

  component PULSE_EDGE is
    port (
      DOUT   : out std_logic;
      PULSE1 : out std_logic;
      CLK    : in  std_logic;
      RST    : in  std_logic;
      NPULSE : in  integer;
      DIN    : in  std_logic
      );
  end component;

  signal DTACK_INNER : std_logic;
  signal CMDDEV      : unsigned(12 downto 0);

  signal CMDHIGH                                  : std_logic;
  signal BUSY                                     : std_logic;
  signal W_ODMB_CTRL, R_ODMB_CTRL, READ_ODMB_DATA : std_logic;
  signal W_DCFEB_CTRL, R_DCFEB_CTRL               : std_logic;

  signal ODMB_CTRL_INNER, DCFEB_CTRL_INNER                  : std_logic_vector(15 downto 0) := (others => '0');
  signal D_OUTDATA_1, Q_OUTDATA_1, D_OUTDATA_2, Q_OUTDATA_2 : std_logic;

  signal OUT_TP_SEL, TP_SEL_INNER         : std_logic_vector(15 downto 0) := (others => '0');
  signal W_TP_SEL, D_W_TP_SEL, Q_W_TP_SEL : std_logic                     := '0';
  signal R_TP_SEL, D_R_TP_SEL, Q_R_TP_SEL : std_logic                     := '0';

  signal ODMB_RST, DCFEB_RST                                          : std_logic_vector(15 downto 0) := (others => '0');
  signal RESYNC_RST, REPROG_RST, TEST_INJ_RST, TEST_PLS_RST, RESET_RST : std_logic                     := '0';
  signal REPROG, DO_RESYNC                                             : std_logic                     := '0';

begin

-- generate CMDHIGH / generate WRITECTRL / generate READCTRL / generate READDATA
  CMDDEV <= unsigned(DEVICE & COMMAND & "00");  -- Variable that looks like the VME commands we input  

  W_TP_SEL <= '1' when (CMDDEV = x"1020") else '0';
  R_TP_SEL <= '1' when (CMDDEV = x"1024") else '0';

  CMDHIGH        <= '1' when (COMMAND(9 downto 4) = "000000" and DEVICE = '1') else '0';
  W_ODMB_CTRL    <= '1' when (COMMAND(3 downto 0) = "0000" and CMDHIGH = '1')  else '0';
  R_ODMB_CTRL    <= '1' when (COMMAND(3 downto 0) = "0001" and CMDHIGH = '1')  else '0';
  READ_ODMB_DATA <= '1' when (COMMAND(3 downto 0) = "0010" and CMDHIGH = '1') else '0';
  W_DCFEB_CTRL   <= '1' when (COMMAND(3 downto 0) = "0100" and CMDHIGH = '1') else '0';
  R_DCFEB_CTRL   <= '1' when (COMMAND(3 downto 0) = "0101" and CMDHIGH = '1') else '0';


-- Write TP_SEL
  GEN_TP_SEL : for I in 15 downto 0 generate
  begin
    FD_W_TP_SEL : FDCE port map(TP_SEL_INNER(I), STROBE, W_TP_SEL, RST, INDATA(I));
  end generate GEN_TP_SEL;
  TP_SEL      <= TP_SEL_INNER;
  D_W_TP_SEL  <= '1' when (STROBE = '1' and W_TP_SEL = '1') else '0';
  FD_DTACK_TP_SEL : FD port map(Q_W_TP_SEL, SLOWCLK, D_W_TP_SEL);
  DTACK_INNER <= '0' when (Q_W_TP_SEL = '1')                else 'Z';

-- Read TP_SEL
  OUT_TP_SEL(15 downto 0) <= TP_SEL_INNER when (STROBE = '1' and R_TP_SEL = '1') else (others => 'Z');

  D_R_TP_SEL  <= '1' when (STROBE = '1' and R_TP_SEL = '1') else '0';
  FD_R_TP_SEL : FD port map(Q_R_TP_SEL, SLOWCLK, D_R_TP_SEL);
  DTACK_INNER <= '0' when (Q_R_TP_SEL = '1')                else 'Z';


  GEN_ODMB_CTRL : for K in 0 to 15 generate
  begin
    ODMB_RST(K) <= RESET_RST when K = 8 else
                   RST;
    ODMB_CTRL_K : FDCE port map (ODMB_CTRL_INNER(K), STROBE, W_ODMB_CTRL, ODMB_RST(K), INDATA(K));
  end generate GEN_ODMB_CTRL;
  PULSE_RESET : PULSE_EDGE port map(fw_reset, reset_rst, slowclk, rst, 2, odmb_ctrl_inner(8));
  ODMB_CTRL <= ODMB_CTRL_INNER;


  GEN_DCFEB_CTRL : for K in 0 to 15 generate
  begin
    DCFEB_RST(K) <= REPROG_RST when K = 0 else
                    RESYNC_RST   when K = 1 else
                    TEST_INJ_RST when K = 2 else
                    TEST_PLS_RST when K = 3 else
                    RST;
    ODMB_DCFEB_K : FDCE port map (DCFEB_CTRL_INNER(K), STROBE, W_DCFEB_CTRL, DCFEB_RST(K), INDATA(K));
  end generate GEN_DCFEB_CTRL;
  PULSE_REPROG : PULSE_EDGE port map(reprog, reprog_rst, slowclk, rst, 2, dcfeb_ctrl_inner(0));
  DO_RESYNC  <= dcfeb_ctrl_inner(1) or RST or reprog;
  PULSE_RESYNC : PULSE_EDGE port map(resync, resync_rst, slowclk, '0', 2, do_resync);
  PULSE_INJ    : PULSE_EDGE port map(test_inj, test_inj_rst, slowclk, rst, 2, dcfeb_ctrl_inner(2));
  PULSE_PLS    : PULSE_EDGE port map(test_pls, test_pls_rst, slowclk, rst, 2, dcfeb_ctrl_inner(3));
  REPROG_B   <= not REPROG;
  DCFEB_CTRL <= DCFEB_CTRL_INNER;

  OUTDATA(15 downto 0) <= ODMB_CTRL_INNER(15 downto 0) when (STROBE = '1' and R_ODMB_CTRL = '1') else
                          DCFEB_CTRL_INNER(15 downto 0) when (STROBE = '1' and R_DCFEB_CTRL = '1')   else
                          OUT_TP_SEL(15 downto 0)       when (STROBE = '1' and R_TP_SEL = '1')       else
                          ODMB_DATA(15 downto 0)        when (STROBE = '1' and READ_ODMB_DATA = '1') else
                          "ZZZZZZZZZZZZZZZZ";

-- bug in uncleaned version?
  D_OUTDATA_1 <= '1' when ((STROBE = '1') and ((W_ODMB_CTRL = '1') or (R_ODMB_CTRL = '1') or (W_DCFEB_CTRL = '1')
                                               or (R_DCFEB_CTRL = '1'))) else '0';

  FD_OUTDATA_1 : FD port map(Q_OUTDATA_1, SLOWCLK, D_OUTDATA_1);

  DTACK_INNER <= '0' when (Q_OUTDATA_1 = '1') else 'Z';

--  OUTDATA(15 downto 0) <= FLFDATA(15 downto 0) when (STROBE = '1' and READDATA = '1') else (others => '1');
  D_OUTDATA_2 <= '1' when (STROBE = '1' and READ_ODMB_DATA = '1') else '0';

  FD_OUTDATA_2 : FD port map(Q_OUTDATA_2, SLOWCLK, D_OUTDATA_2);

  DTACK_INNER <= '0' when (Q_OUTDATA_2 = '1') else 'Z';

  DTACK <= DTACK_INNER;

end VMEMON_Arch;
