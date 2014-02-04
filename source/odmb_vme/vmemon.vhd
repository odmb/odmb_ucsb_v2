-- VMEMON: Sends out FLFCTRL with monitoring values

library ieee;
library work;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VMEMON is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );    
  port (

    SLOWCLK : in std_logic;
    CLK40   : in std_logic;
    RST     : in std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);
    WRITER  : in std_logic;

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    DCFEB_DONE  : in std_logic_vector(NFEB downto 1);
    QPLL_LOCKED : in std_logic;

    OPT_RESET_PULSE : out std_logic;
    L1A_RESET_PULSE : out std_logic;
    FW_RESET        : out std_logic;
    REPROG_B        : out std_logic;
    TEST_INJ        : out std_logic;
    TEST_PLS        : out std_logic;
    TEST_PED        : out std_logic;
    TEST_LCT        : out std_logic;
    OTMB_LCT_RQST   : out std_logic;
    OTMB_EXT_TRIG   : out std_logic;

    TP_SEL        : out std_logic_vector(15 downto 0);
    ODMB_CTRL     : out std_logic_vector(15 downto 0);
    DCFEB_CTRL    : out std_logic_vector(15 downto 0);
    ODMB_DATA_SEL : out std_logic_vector(7 downto 0);
    ODMB_DATA     : in  std_logic_vector(15 downto 0);
    TXDIFFCTRL    : out std_logic_vector(3 downto 0);  -- Controls the TX voltage swing
    LOOPBACK      : out std_logic_vector(2 downto 0)  -- For internal loopback tests

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

  signal dd_dtack, d_dtack, q_dtack : std_logic;
  signal CMDDEV                     : unsigned(12 downto 0);

  signal BUSY                                  : std_logic;
  signal W_ODMB_CTRL, R_ODMB_CTRL, R_ODMB_DATA : std_logic;
  signal W_DCFEB_CTRL, R_DCFEB_CTRL            : std_logic;

  signal ODMB_CTRL_INNER, DCFEB_CTRL_INNER : std_logic_vector(15 downto 0) := (others => '0');

  signal OUT_TP_SEL, TP_SEL_INNER : std_logic_vector(15 downto 0) := (others => '0');
  signal W_TP_SEL                 : std_logic                     := '0';
  signal R_TP_SEL                 : std_logic                     := '0';

  signal ODMB_RST, DCFEB_RST                                : std_logic_vector(15 downto 0) := (others => '0');
  signal RESYNC_RST, REPROG_RST, TEST_INJ_RST, TEST_PLS_RST : std_logic                     := '0';
  signal LCT_RQST_RST, EXT_TRIG_RST, OPT_RESET_PULSE_RST    : std_logic                     := '0';
  signal REPROG, TEST_LCT_RST, RESET_RST                    : std_logic                     := '0';

  signal OUT_LOOPBACK   : std_logic_vector(15 downto 0) := (others => '0');
  signal LOOPBACK_INNER : std_logic_vector(2 downto 0);
  signal W_LOOPBACK     : std_logic                     := '0';
  signal R_LOOPBACK     : std_logic                     := '0';

  signal OUT_TXDIFFCTRL   : std_logic_vector(15 downto 0) := (others => '0');
  signal TXDIFFCTRL_INNER : std_logic_vector(3 downto 0);
  signal W_TXDIFFCTRL     : std_logic                     := '0';
  signal R_TXDIFFCTRL     : std_logic                     := '0';

  signal OUT_DCFEB_DONE : std_logic_vector(15 downto 0) := (others => '0');
  signal R_DCFEB_DONE   : std_logic                     := '0';

  signal OUT_QPLL_LOCKED : std_logic_vector(15 downto 0) := (others => '0');
  signal R_QPLL_LOCKED   : std_logic                     := '0';

begin

-- generate CMDHIGH / generate WRITECTRL / generate READCTRL / generate READDATA
  CMDDEV <= unsigned(DEVICE & COMMAND & "00");  -- Variable that looks like the VME commands we input  

  W_ODMB_CTRL  <= '1' when (CMDDEV = x"1000" and WRITER = '0') else '0';
  R_ODMB_CTRL  <= '1' when (CMDDEV = x"1000" and WRITER = '1') else '0';
  W_DCFEB_CTRL <= '1' when (CMDDEV = x"1010" and WRITER = '0') else '0';
  R_DCFEB_CTRL <= '1' when (CMDDEV = x"1010" and WRITER = '1') else '0';
  W_TP_SEL     <= '1' when (CMDDEV = x"1020" and WRITER = '0') else '0';
  R_TP_SEL     <= '1' when (CMDDEV = x"1020" and WRITER = '1') else '0';

  W_LOOPBACK    <= '1' when (CMDDEV = x"1100" and WRITER = '0') else '0';
  R_LOOPBACK    <= '1' when (CMDDEV = x"1100" and WRITER = '1') else '0';
  W_TXDIFFCTRL  <= '1' when (CMDDEV = x"1110" and WRITER = '0') else '0';
  R_TXDIFFCTRL  <= '1' when (CMDDEV = x"1110" and WRITER = '1') else '0';
  R_DCFEB_DONE  <= '1' when (CMDDEV = x"1120" and WRITER = '1') else '0';
  R_QPLL_LOCKED <= '1' when (CMDDEV = x"1124" and WRITER = '1') else '0';

  R_ODMB_DATA               <= '1' when (CMDDEV(12) = '1' and CMDDEV(3 downto 0) = x"C") else '0';
  ODMB_DATA_SEL(7 downto 0) <= COMMAND(9 downto 2);


-- Write TP_SEL
  GEN_TP_SEL : for I in 15 downto 0 generate
  begin
    FD_W_TP_SEL : FDCE port map(TP_SEL_INNER(I), STROBE, W_TP_SEL, RST, INDATA(I));
  end generate GEN_TP_SEL;
  TP_SEL <= TP_SEL_INNER;

-- Read TP_SEL
  OUT_TP_SEL(15 downto 0) <= TP_SEL_INNER when (STROBE = '1' and R_TP_SEL = '1') else (others => 'Z');

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
                    RESYNC_RST          when K = 1 else
                    TEST_INJ_RST        when K = 2 else
                    TEST_PLS_RST        when K = 3 else
                    TEST_LCT_RST        when K = 4 else
                    LCT_RQST_RST        when K = 5 else
                    EXT_TRIG_RST        when K = 6 else
                    OPT_RESET_PULSE_RST when K = 7 else
                    RST;
    ODMB_DCFEB_K : FDCE port map (DCFEB_CTRL_INNER(K), STROBE, W_DCFEB_CTRL, DCFEB_RST(K), INDATA(K));
  end generate GEN_DCFEB_CTRL;
  PULSE_REPROG : PULSE_EDGE port map(reprog, reprog_rst, slowclk, rst, 2, dcfeb_ctrl_inner(0));
  PULSE_RESYNC : PULSE_EDGE port map(l1a_reset_pulse, resync_rst, clk40, '0', 1, dcfeb_ctrl_inner(1));
  PULSE_INJ    : PULSE_EDGE port map(test_inj, test_inj_rst, slowclk, rst, 2, dcfeb_ctrl_inner(2));
  PULSE_PLS    : PULSE_EDGE port map(test_pls, test_pls_rst, slowclk, rst, 2, dcfeb_ctrl_inner(3));
  PULSE_L1A    : PULSE_EDGE port map(test_lct, test_lct_rst, clk40, rst, 1, dcfeb_ctrl_inner(4));
  PULSE_LCT    : PULSE_EDGE port map(otmb_lct_rqst, lct_rqst_rst, clk40, rst, 1, dcfeb_ctrl_inner(5));
  PULSE_EXT    : PULSE_EDGE port map(otmb_ext_trig, ext_trig_rst, clk40, rst, 1, dcfeb_ctrl_inner(6));
  PULSE_OPT    : PULSE_EDGE port map(opt_reset_pulse, opt_reset_pulse_rst, clk40, rst, 1, dcfeb_ctrl_inner(7));
  REPROG_B   <= not REPROG;
  DCFEB_CTRL <= DCFEB_CTRL_INNER;

  test_ped <= dcfeb_ctrl_inner(9);

-- Write LOOPBACK
  GEN_LOOPBACK : for I in 2 downto 0 generate
  begin
    FD_W_LOOPBACK : FDCE port map(LOOPBACK_INNER(I), STROBE, W_LOOPBACK, RST, INDATA(I));
  end generate GEN_LOOPBACK;
  LOOPBACK <= LOOPBACK_INNER;

-- Read LOOPBACK
  OUT_LOOPBACK(15 downto 3) <= (others => '0');
  OUT_LOOPBACK(2 downto 0)  <= LOOPBACK_INNER when (STROBE = '1' and R_LOOPBACK = '1') else
                               (others => 'Z');

-- Write TXDIFFCTRL
  GEN_TXDIFFCTRL : for I in 3 downto 0 generate
  begin
    FD_W_TXDIFFCTRL : FDCE port map(TXDIFFCTRL_INNER(I), STROBE, W_TXDIFFCTRL, RST, INDATA(I));
  end generate GEN_TXDIFFCTRL;
  TXDIFFCTRL <= TXDIFFCTRL_INNER;

-- Read TXDIFFCTRL
  OUT_TXDIFFCTRL(15 downto 4) <= (others => '0');
  OUT_TXDIFFCTRL(3 downto 0) <= TXDIFFCTRL_INNER when (STROBE = '1' and R_TXDIFFCTRL = '1') else (others => 'Z');

-- Read DCFEB_DONE
  OUT_DCFEB_DONE <= x"00" & '0' & DCFEB_DONE when (STROBE = '1' and R_DCFEB_DONE = '1') else (others => 'Z');

-- Read QPLL_LOCKED
  OUT_QPLL_LOCKED <= x"000" & "000" & QPLL_LOCKED when (STROBE = '1' and R_QPLL_LOCKED = '1') else (others => 'Z');

  OUTDATA <= ODMB_CTRL_INNER when (R_ODMB_CTRL = '1') else
             DCFEB_CTRL_INNER when (R_DCFEB_CTRL = '1') else
             OUT_TP_SEL       when (R_TP_SEL = '1') else
             OUT_LOOPBACK     when (R_LOOPBACK = '1') else
             OUT_TXDIFFCTRL   when (R_TXDIFFCTRL = '1') else
             OUT_DCFEB_DONE   when (R_DCFEB_DONE = '1') else
             OUT_QPLL_LOCKED  when (R_QPLL_LOCKED = '1') else
             ODMB_DATA        when (R_ODMB_DATA = '1') else
             (others => 'L');

  -- DTACK
  dd_dtack <= STROBE and DEVICE;
  FD_D_DTACK : FDC port map(d_dtack, dd_dtack, q_dtack, '1');
  FD_Q_DTACK : FD port map(q_dtack, SLOWCLK, d_dtack);
  DTACK    <= q_dtack;
  
end VMEMON_Arch;
