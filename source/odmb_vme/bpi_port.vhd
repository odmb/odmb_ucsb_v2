-- BPI_PORT: Controls via VME the BPI engine that writes FW and registers to the PROM

library ieee;
library work;
library unisim;
library hdlmacro;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use hdlmacro.hdlmacro.all;

entity BPI_PORT is
  port (
    CSP_BPI_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);

    CLK : in std_logic;                 -- 40 MHz
    RST : in std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);
    WRITE_B : in std_logic;

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    -- BPI controls
    BPI_RST           : out std_logic;
    BPI_CMD_FIFO_DATA : out std_logic_vector(15 downto 0);
    BPI_WE            : out std_logic;
    BPI_RE            : out std_logic;
    BPI_DSBL          : out std_logic;
    BPI_ENBL          : out std_logic;
    BPI_CFG_DL        : out std_logic;
    BPI_CFG_UL        : out std_logic;

    BPI_RBK_FIFO_DATA : in  std_logic_vector(15 downto 0);
    BPI_RBK_WRD_CNT   : in  std_logic_vector(10 downto 0);
    BPI_STATUS        : in  std_logic_vector(15 downto 0);
    BPI_TIMER         : in  std_logic_vector(31 downto 0);
    BPI_CFG_UL_PULSE  : out std_logic;  -- TD new
    BPI_CFG_DL_PULSE  : out std_logic;  -- TD new
    BPI_CFG_REG0      : in  std_logic_vector(15 downto 0);
    BPI_CFG_REG1      : in  std_logic_vector(15 downto 0);
    BPI_CFG_REG2      : in  std_logic_vector(15 downto 0);
    BPI_CFG_REG3      : in  std_logic_vector(15 downto 0);
    BPI_CFG_REG_IN    : out std_logic_vector(15 downto 0);
    BPI_CFG_REG_WE    : out std_logic_vector(3 downto 0);
    BPI_CFG_BUSY      : in  std_logic;
    BPI_DONE          : in  std_logic

    );
end BPI_PORT;


architecture BPI_PORT_Arch of BPI_PORT is

  component csp_bpi_port_la is
    port (
      CLK     : in    std_logic := 'X';
      DATA    : in    std_logic_vector (127 downto 0);
      TRIG0   : in    std_logic_vector (7 downto 0);
      CONTROL : inout std_logic_vector (35 downto 0)
      );
  end component;

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

  signal cmddev                 : unsigned(12 downto 0);
  signal bpi_cfg_data_sel_inner : std_logic;

  signal d_dtack, q_dtack, dtack_inner : std_logic;
  signal w_cfg_reg, d_dtack_w_cfg_reg  : std_logic;
  signal r_cfg_reg                     : std_logic;
  signal send_bpi_rst, bpi_rst_inner   : std_logic;
  signal send_bpi_dsbl                 : std_logic;
  signal r_rbk_fifo_nw                 : std_logic;
  signal r_bpi_status                  : std_logic;
  signal r_bpi_timer_l                 : std_logic;
  signal r_bpi_timer_h                 : std_logic;

  signal bpi_enbl_inner, bpi_dsbl_inner                                           : std_logic;
  signal send_bpi_enbl, d_dtack_send_bpi_enbl, q_dtack_send_bpi_enbl              : std_logic;
  signal rst_send_bpi_enbl, dd_dtack_send_bpi_enbl, ddd_dtack_send_bpi_enbl       : std_logic;
  signal send_bpi_cfg_ul                                                          : std_logic;
  signal d_dtack_cfg_ul_dl, q_dtack_cfg_ul_dl                                     : std_logic;
  signal rst_cfg_ul_dl, dd_dtack_cfg_ul_dl, ddd_dtack_cfg_ul_dl                   : std_logic;
  signal d_dtack_cfg_ul_init, q_dtack_cfg_ul_init                                 : std_logic;
  signal rst_cfg_ul_init, dd_dtack_cfg_ul_init                                    : std_logic;
  signal send_bpi_cfg_dl                                                          : std_logic;
  signal w_cmd_fifo, d_dtack_w_cmd_fifo                                           : std_logic;
  signal r_rbk_fifo, d_dtack_r_rbk_fifo, q_dtack_r_rbk_fifo, q_dtack_r_rbk_fifo_b : std_logic;

  signal d_write_cfg_reg : std_logic_vector(3 downto 0);

  signal bpi_cfg_reg_sel                                : std_logic_vector(1 downto 0);
  signal out_ctrl_reg                                   : std_logic_vector(15 downto 0);
  signal bpi_cfg_ul_pulse_inner, bpi_cfg_dl_pulse_inner : std_logic;  --TD
  signal bpi_done_pulse                                 : std_logic;

  signal bpi_port_csp_data                  : std_logic_vector(127 downto 0);
  signal bpi_port_csp_trig                  : std_logic_vector(7 downto 0);
  signal bpi_cfg_ul_inner, bpi_cfg_dl_inner : std_logic;
  signal bpi_cfg_reg_in_inner               : std_logic_vector(15 downto 0);

  signal rst_b            : std_logic := '1';
  signal rst_done_pulse   : std_logic := '0';
  signal rst_done_pulse_b : std_logic := '1';
  signal rst_cfg_ul_pulse : std_logic := '0';

begin  --Architecture

  csp_bpi_port_la_pm : csp_bpi_port_la
    port map (
      CONTROL => CSP_BPI_PORT_LA_CTRL,
      CLK     => CLK,
      DATA    => bpi_port_csp_data,
      TRIG0   => bpi_port_csp_trig
      );

-- Decode instruction
  CMDDEV <= unsigned(DEVICE & COMMAND & "00");  -- Variable that looks like the VME commands we input

  R_CFG_REG       <= '1' when (CMDDEV = x"1014" and WRITE_B = '1'and STROBE = '1') else '0';  -- COMMAND = 0x005
  SEND_BPI_CFG_UL <= '1' when (CMDDEV = x"1018" and WRITE_B = '0'and STROBE = '1') else
                     '1' when (rst_cfg_ul_pulse = '1') else '0';  -- COMMAND = 0x06
  SEND_BPI_CFG_DL <= '1' when (CMDDEV = x"101C" and WRITE_B = '0'and STROBE = '1') else '0';  -- COMMAND = 0x007
  SEND_BPI_RST    <= '1' when (CMDDEV = x"1020" and WRITE_B = '0'and STROBE = '1') else
                     '1' when (RST_CFG_UL_INIT = '1') else '0';  -- COMMAND = 0x008
  SEND_BPI_DSBL <= '1' when (CMDDEV = x"1024" and WRITE_B = '0') else '0';  -- COMMAND = 0x009
  SEND_BPI_ENBL <= '1' when (CMDDEV = x"1028" and WRITE_B = '0') else '0';  -- COMMAND = 0x00A
  -- TD: DO NOT put W_CMD_FIFO on STROBE: CMD_FIFO_DATA uses STROBE as CLK.
  W_CMD_FIFO    <= '1' when (CMDDEV = x"102C" and WRITE_B = '0')                  else '0';  -- COMMAND = 0x00B
  R_RBK_FIFO    <= '1' when (CMDDEV = x"1030" and WRITE_B = '1')                  else '0';  -- COMMAND = 0x00C
  R_RBK_FIFO_NW <= '1' when (CMDDEV = x"1034" and WRITE_B = '1')                  else '0';  -- COMMAND = 0x00D
  R_BPI_STATUS  <= '1' when (CMDDEV = x"1038" and WRITE_B = '1')                  else '0';  -- COMMAND = 0x00E
  R_BPI_TIMER_L <= '1' when (CMDDEV = x"103C" and WRITE_B = '1')                  else '0';  -- COMMAND = 0x00F
  R_BPI_TIMER_H <= '1' when (CMDDEV = x"1040" and WRITE_B = '1')                  else '0';  -- COMMAND = 0x010
  W_CFG_REG     <= '1' when (CMDDEV = X"1044" and WRITE_B = '0')                  else '0';  -- COMMAND = 0X011

-- Generate DTACK

  D_DTACK <= '1' when ((R_CFG_REG = '1' or SEND_BPI_RST = '1' or SEND_BPI_DSBL = '1' or R_RBK_FIFO_NW = '1' or
                        R_BPI_STATUS = '1' or R_BPI_TIMER_L = '1' or R_BPI_TIMER_H = '1' or
                        W_CFG_REG = '1' or W_CMD_FIFO = '1')
                       and STROBE = '1') else '0';

  FDCP_TEST_UL : FDCP port map (bpi_cfg_ul_pulse_inner, BPI_DONE, RST, '0', SEND_BPI_CFG_UL);  -- TD
  FDCP_TEST_DL : FDCP port map (bpi_cfg_dl_pulse_inner, BPI_DONE, RST, '0', SEND_BPI_CFG_DL);  -- TD
  FD_DTACK     : FD port map (Q_DTACK, CLK, D_DTACK);

  -- upload config from PROM on RST
  rst_b            <= not(RST);
  RST_DONE_PE   : PULSE_EDGE port map (rst_done_pulse, open, clk, RST, 20, rst_b);
  rst_done_pulse_b <= not(rst_done_pulse);
  RST_UL_CFG_PE : PULSE_EDGE port map (rst_cfg_ul_pulse, open, clk, RST, 5, rst_done_pulse_b);

  -- rst bpi (mainly rbk_fifo) after initial ul
  FD_DD_CFG_UL_INIT : FD port map(DD_DTACK_CFG_UL_INIT, CLK, rst_cfg_ul_pulse);
  FD_D_CFG_UL_INIT  : FDC port map(D_DTACK_CFG_UL_INIT, DD_DTACK_CFG_UL_INIT, RST_CFG_UL_INIT, '1');
  FD_CFG_UL_INIT    : FD port map(Q_DTACK_CFG_UL_INIT, CLK, D_DTACK_CFG_UL_INIT);
  RST_CFG_UL_INIT <= bpi_done_pulse and Q_DTACK_CFG_UL_INIT;

  -- normal ul/dl operations
  DDD_DTACK_CFG_UL_DL <= (SEND_BPI_CFG_UL or SEND_BPI_CFG_DL) and STROBE;
  FD_DD_CFG_UL_DL : FD port map(DD_DTACK_CFG_UL_DL, CLK, DDD_DTACK_CFG_UL_DL);
  FD_D_CFG_UL_DL  : FDC port map(D_DTACK_CFG_UL_DL, DD_DTACK_CFG_UL_DL, RST_CFG_UL_DL, '1');
  FD_CFG_UL_DL    : FD port map(Q_DTACK_CFG_UL_DL, CLK, D_DTACK_CFG_UL_DL);
  BPI_DONE_PE     : PULSE_EDGE port map(bpi_done_pulse, open, clk, rst, 3, BPI_DONE);
  RST_CFG_UL_DL       <= bpi_done_pulse and Q_DTACK_CFG_UL_DL;

  -- dtack for bpi_enbl
  DDD_DTACK_SEND_BPI_ENBL <= SEND_BPI_ENBL and STROBE;
  FD_DD_SEND_BPI_ENBL : FD port map(DD_DTACK_SEND_BPI_ENBL, CLK, DDD_DTACK_SEND_BPI_ENBL);
  FD_D_SEND_BPI_ENBL  : FDC port map(D_DTACK_SEND_BPI_ENBL, DD_DTACK_SEND_BPI_ENBL, RST_SEND_BPI_ENBL, '1');
  FD_SEND_BPI_ENBL    : FD port map(Q_DTACK_SEND_BPI_ENBL, CLK, D_DTACK_SEND_BPI_ENBL);
  RST_SEND_BPI_ENBL       <= BPI_DONE and Q_DTACK_SEND_BPI_ENBL;

  --d_dtack signals for pulse commands
  d_dtack_w_cmd_fifo   <= '1' when (w_cmd_fifo = '1' and STROBE = '1') else '0';
  d_dtack_w_cfg_reg    <= '1' when (w_cfg_reg = '1' and STROBE = '1')  else '0';
  d_dtack_r_rbk_fifo   <= '1' when (r_rbk_fifo = '1' and STROBE = '1') else '0';
  FD_DTACK_RBKFIFO : FD port map (q_dtack_r_rbk_fifo, CLK, d_dtack_r_rbk_fifo);
  q_dtack_r_rbk_fifo_b <= not q_dtack_r_rbk_fifo;

  DTACK_INNER <= q_dtack or q_dtack_send_bpi_enbl or q_dtack_cfg_ul_init or
                 q_dtack_cfg_ul_dl or q_dtack_r_rbk_fifo;
  DTACK <= DTACK_INNER;

  BPI_CFG_UL_PULSE <= bpi_cfg_ul_pulse_inner;  -- TD
  BPI_CFG_DL_PULSE <= bpi_cfg_dl_pulse_inner;  -- TD

-- PULSE COMMANDS

  PULSE_BPI_WE : PULSE_EDGE port map(BPI_WE, open, CLK, RST, 1, D_DTACK_W_CMD_FIFO);
  PULSE_BPI_RE : PULSE_EDGE port map(BPI_RE, open, CLK, RST, 1, q_dtack_r_rbk_fifo_b);

  PULSE_CFG_UL   : PULSE_EDGE port map(BPI_CFG_UL_INNER, open, CLK, RST, 1, SEND_BPI_CFG_UL);
  PULSE_CFG_DL   : PULSE_EDGE port map(BPI_CFG_DL_INNER, open, CLK, RST, 1, SEND_BPI_CFG_DL);
  PULSE_BPI_RST  : PULSE_EDGE port map(BPI_RST_INNER, open, CLK, RST, 10, SEND_BPI_RST);
  PULSE_BPI_ENBL : PULSE_EDGE port map(BPI_ENBL_INNER, open, CLK, RST, 1, SEND_BPI_ENBL);
  PULSE_BPI_DSBL : PULSE_EDGE port map(BPI_DSBL_INNER, open, CLK, RST, 1, SEND_BPI_DSBL);

  BPI_CFG_UL <= BPI_CFG_UL_INNER;
  BPI_CFG_DL <= BPI_CFG_DL_INNER;
  BPI_RST    <= BPI_RST_INNER;
  BPI_ENBL   <= BPI_ENBL_INNER;
  BPI_DSBL   <= BPI_DSBL_INNER;

  OUTDATA <= BPI_CFG_REG0 when (STROBE = '1' and R_CFG_REG = '1' and (BPI_CFG_REG_SEL = "00")) else
             BPI_CFG_REG1              when (STROBE = '1' and R_CFG_REG = '1' and (BPI_CFG_REG_SEL = "01")) else
             BPI_CFG_REG2              when (STROBE = '1' and R_CFG_REG = '1' and (BPI_CFG_REG_SEL = "10")) else
             BPI_CFG_REG3              when (STROBE = '1' and R_CFG_REG = '1' and (BPI_CFG_REG_SEL = "11")) else
             BPI_RBK_FIFO_DATA         when (STROBE = '1' and R_RBK_FIFO = '1')                             else
             "00000" & BPI_RBK_WRD_CNT when (STROBE = '1' and R_RBK_FIFO_NW = '1')                          else
             BPI_STATUS                when (STROBE = '1' and R_BPI_STATUS = '1')                           else
             BPI_TIMER(15 downto 0)    when (STROBE = '1' and R_BPI_TIMER_L = '1')                          else
             BPI_TIMER(31 downto 16)   when (STROBE = '1' and R_BPI_TIMER_H = '1')                          else
             (others => 'Z');

-- Generate BPI_CFG_REG_WE and BPI_CFG_REG_IN

  d_write_cfg_reg(0) <= '1' when ((D_DTACK_W_CFG_REG = '1') and (BPI_CFG_REG_SEL = "00")) else '0';
  PULSE_BPI_REG0_WE : PULSE_EDGE port map(BPI_CFG_REG_WE(0), open, CLK, RST, 1, D_WRITE_CFG_REG(0));

  d_write_cfg_reg(1) <= '1' when ((D_DTACK_W_CFG_REG = '1') and (BPI_CFG_REG_SEL = "01")) else '0';
  PULSE_BPI_REG1_WE : PULSE_EDGE port map(BPI_CFG_REG_WE(1), open, CLK, RST, 1, D_WRITE_CFG_REG(1));

  d_write_cfg_reg(2) <= '1' when ((D_DTACK_W_CFG_REG = '1') and (BPI_CFG_REG_SEL = "10")) else '0';
  PULSE_BPI_REG2_WE : PULSE_EDGE port map(BPI_CFG_REG_WE(2), open, CLK, RST, 1, D_WRITE_CFG_REG(2));

  d_write_cfg_reg(3) <= '1' when ((D_DTACK_W_CFG_REG = '1') and (BPI_CFG_REG_SEL = "11")) else '0';
  PULSE_BPI_REG3_WE : PULSE_EDGE port map(BPI_CFG_REG_WE(3), open, CLK, RST, 1, D_WRITE_CFG_REG(3));

  BPI_CFG_REG_IN_INNER <= INDATA;
  BPI_CFG_REG_IN       <= BPI_CFG_REG_IN_INNER;

-- Generate CMD_FIFO INPUT DATA
  FDCE_GEN : for i in 0 to 15 generate
  begin
    FDCE_CMD_FIFO_DATA : FDCE port map (BPI_CMD_FIFO_DATA(i), STROBE, W_CMD_FIFO, RST, INDATA(i));
  end generate FDCE_GEN;

  bpi_port_csp_trig <= "00" & STROBE & BPI_ENBL_INNER & BPI_DSBL_INNER & BPI_RST_INNER & SEND_BPI_CFG_UL & SEND_BPI_CFG_DL;
  bpi_port_csp_data <= "0" & x"000000000000" &
                       std_logic_vector(cmddev) &  --[78:66]
                       BPI_CFG_REG_IN_INNER &      --[65:50]
                       BPI_RBK_FIFO_DATA &         --[49:34]
                       BPI_RBK_WRD_CNT &           --[33:23]
                       BPI_CFG_BUSY & BPI_DONE & bpi_done_pulse & STROBE & WRITE_B & RST &  --[22:17]
                       DDD_DTACK_SEND_BPI_ENBL & DD_DTACK_SEND_BPI_ENBL &  --[16:15]
                       D_DTACK_SEND_BPI_ENBL & Q_DTACK_SEND_BPI_ENBL &  --[14:13]
                       bpi_cfg_dl_pulse_inner & SEND_BPI_CFG_DL & BPI_CFG_DL_INNER &  --[12:10]
                       bpi_cfg_ul_pulse_inner & SEND_BPI_CFG_UL & BPI_CFG_UL_INNER &  --[9:7]
                       DDD_DTACK_CFG_UL_DL & DD_DTACK_CFG_UL_DL & D_DTACK_CFG_UL_DL &  -- [6:4]
                       Q_DTACK_CFG_UL_DL & D_DTACK & Q_DTACK & DTACK_INNER;  --[3:0]
  
  
end BPI_PORT_Arch;
