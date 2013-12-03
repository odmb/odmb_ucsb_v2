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

    SLOWCLK : in std_logic;
    CLK     : in std_logic;             -- 40 MHz
    RST     : in std_logic;

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
    BPI_CFG_UL_PULSE  : out std_logic;
    BPI_CFG_DL_PULSE  : out std_logic;
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

  signal dd_dtack, d_dtack, q_dtack, dtack_inner : std_logic;
  signal send_bpi_rst, bpi_rst_inner             : std_logic;
  signal send_bpi_dsbl                           : std_logic;
  signal r_rbk_fifo_nw                           : std_logic;
  signal r_bpi_status                            : std_logic;
  signal r_bpi_timer_l                           : std_logic;
  signal r_bpi_timer_h                           : std_logic;

  signal bpi_enbl_inner, bpi_dsbl_inner                              : std_logic;
  signal send_bpi_enbl, d_dtack_send_bpi_enbl, q_dtack_send_bpi_enbl : std_logic;
  signal rst_send_bpi_enbl, dd_dtack_send_bpi_enbl                   : std_logic;
  signal send_bpi_cfg_ul                                             : std_logic;
  signal d_dtack_cfg_ul_dl, q_dtack_cfg_ul_dl                        : std_logic;
  signal rst_cfg_ul_dl, dd_dtack_cfg_ul_dl                           : std_logic;
  signal d_dtack_cfg_ul_init, q_dtack_cfg_ul_init                    : std_logic;
  signal rst_cfg_ul_init, dd_dtack_cfg_ul_init                       : std_logic;
  signal send_bpi_cfg_dl                                             : std_logic;
  signal w_cmd_fifo, r_rbk_fifo, start_w_cmd_fifo                    : std_logic;
  signal dd_dtack_r_rbk_fifo, d_dtack_r_rbk_fifo                     : std_logic;
  signal q_dtack_r_rbk_fifo, q_dtack_r_rbk_fifo_b                    : std_logic;

  signal out_ctrl_reg                                   : std_logic_vector(15 downto 0);
  signal bpi_cfg_ul_pulse_inner, bpi_cfg_dl_pulse_inner : std_logic;  --TD
  signal bpi_done_pulse, bpi_cfg_busy_b                 : std_logic;

  signal bpi_port_csp_data                  : std_logic_vector(127 downto 0);
  signal bpi_port_csp_trig                  : std_logic_vector(7 downto 0);
  signal bpi_cfg_ul_inner, bpi_cfg_dl_inner : std_logic;
  signal start_rst, start_ul                : std_logic;

  signal rst_b            : std_logic := '1';
  signal rst_done_pulse   : std_logic := '0';
  signal rst_done_pulse_b : std_logic := '1';
  signal rst_cfg_ul_pulse : std_logic := '0';

begin  --Architecture

-- Decode instruction
  CMDDEV <= unsigned(DEVICE & COMMAND & "00");  -- Variable that looks like the VME commands we input

  SEND_BPI_CFG_UL <= '1' when (CMDDEV = x"1018" and WRITE_B = '0'and STROBE = '1') else '0';
  SEND_BPI_CFG_DL <= '1' when (CMDDEV = x"101C" and WRITE_B = '0'and STROBE = '1') else '0';
  SEND_BPI_RST    <= '1' when (CMDDEV = x"1020" and WRITE_B = '0'and STROBE = '1') else '0';

  SEND_BPI_DSBL <= '1' when (CMDDEV = x"1024" and WRITE_B = '0') else '0';
  SEND_BPI_ENBL <= '1' when (CMDDEV = x"1028" and WRITE_B = '0') else '0';

  W_CMD_FIFO    <= '1' when (CMDDEV = x"102C" and WRITE_B = '0') else '0';
  R_RBK_FIFO    <= '1' when (CMDDEV = x"1030" and WRITE_B = '1') else '0';
  R_RBK_FIFO_NW <= '1' when (CMDDEV = x"1034" and WRITE_B = '1') else '0';
  R_BPI_STATUS  <= '1' when (CMDDEV = x"1038" and WRITE_B = '1') else '0';
  R_BPI_TIMER_L <= '1' when (CMDDEV = x"103C" and WRITE_B = '1') else '0';
  R_BPI_TIMER_H <= '1' when (CMDDEV = x"1040" and WRITE_B = '1') else '0';

-- Generate DTACK
  dd_dtack <= '1' when ((send_bpi_rst = '1' or send_bpi_dsbl = '1' or r_rbk_fifo_nw = '1' or
                         r_bpi_status = '1' or r_bpi_timer_l = '1' or r_bpi_timer_h = '1' or
                         w_cmd_fifo = '1')
                        and STROBE = '1') else '0';
  FD_D_DTACK : FDC port map(d_dtack, dd_dtack, q_dtack, '1');
  FD_Q_DTACK : FD port map(q_dtack, SLOWCLK, d_dtack);

  -- DTACK for UL/DL operations
  dd_dtack_cfg_ul_dl <= (send_bpi_cfg_ul or send_bpi_cfg_dl) and STROBE;
  FD_D_CFG_UL_DL : FDC port map(D_DTACK_CFG_UL_DL, DD_DTACK_CFG_UL_DL, RST_CFG_UL_DL, '1');
  FD_CFG_UL_DL   : FD port map(Q_DTACK_CFG_UL_DL, SLOWCLK, D_DTACK_CFG_UL_DL);
  BPI_DONE_PE    : PULSE_EDGE port map(bpi_done_pulse, open, clk, rst, 3, BPI_DONE);
  RST_CFG_UL_DL      <= not BPI_CFG_BUSY and Q_DTACK_CFG_UL_DL;

  -- DTACK for bpi_enbl
  dd_dtack_send_bpi_enbl <= send_bpi_enbl and STROBE;
  FD_D_SEND_BPI_ENBL : FDC port map(d_dtack_send_bpi_enbl, dd_dtack_send_bpi_enbl, rst_send_bpi_enbl, '1');
  FD_SEND_BPI_ENBL   : FD port map(q_dtack_send_bpi_enbl, SLOWCLK, d_dtack_send_bpi_enbl);
  rst_send_bpi_enbl      <= bpi_done and q_dtack_send_bpi_enbl;

  -- DTACK signals for Readback FIFO
  dd_dtack_r_rbk_fifo  <= '1' when (r_rbk_fifo = '1' and STROBE = '1') else '0';
  FD_D_DTACK_R_RBK_FIFO : FDC port map(d_dtack_r_rbk_fifo, dd_dtack_r_rbk_fifo, q_dtack_r_rbk_fifo, '1');
  FD_Q_DTACK_R_RBK_FIFO : FD port map(q_dtack_r_rbk_fifo, SLOWCLK, d_dtack_r_rbk_fifo);
  q_dtack_r_rbk_fifo_b <= not q_dtack_r_rbk_fifo;

  dtack_inner <= q_dtack or q_dtack_send_bpi_enbl or q_dtack_cfg_ul_dl or q_dtack_r_rbk_fifo;
  DTACK       <= dtack_inner;


  -- Setting MUXes for Upload and Download CFG registers
  start_ul       <= SEND_BPI_CFG_UL or rst_cfg_ul_pulse;
  bpi_cfg_busy_b <= not BPI_CFG_BUSY;
  FDCP_TEST_UL : FDCP port map (bpi_cfg_ul_pulse_inner, BPI_DONE, RST, '0', start_ul);
  FDCP_TEST_DL : FDCP port map (bpi_cfg_dl_pulse_inner, bpi_cfg_busy_b, RST, '0', SEND_BPI_CFG_DL);

  -- Upload config from PROM on RST
  rst_b            <= not RST;
  RST_DONE_PE   : PULSE_EDGE port map (rst_done_pulse, open, clk, RST, 20, rst_b);
  rst_done_pulse_b <= not rst_done_pulse;
  RST_UL_CFG_PE : PULSE_EDGE port map (rst_cfg_ul_pulse, open, clk, RST, 5, rst_done_pulse_b);

  -- Reset BPI (mainly rbk_fifo) after initial Upload
  FD_DD_CFG_UL_INIT : FD port map(DD_DTACK_CFG_UL_INIT, CLK, rst_cfg_ul_pulse);
  FD_D_CFG_UL_INIT  : FDC port map(D_DTACK_CFG_UL_INIT, DD_DTACK_CFG_UL_INIT, RST_CFG_UL_INIT, '1');
  FD_CFG_UL_INIT    : FD port map(Q_DTACK_CFG_UL_INIT, SLOWCLK, D_DTACK_CFG_UL_INIT);
  RST_CFG_UL_INIT <= bpi_done_pulse and Q_DTACK_CFG_UL_INIT;

  BPI_CFG_UL_PULSE <= bpi_cfg_ul_pulse_inner;
  BPI_CFG_DL_PULSE <= bpi_cfg_dl_pulse_inner;

-- PULSE COMMANDS

  start_rst        <= SEND_BPI_RST or RST_CFG_UL_INIT;
  PULSE_BPI_RST : PULSE_EDGE port map(BPI_RST_INNER, open, CLK, RST, 10, start_rst);
  start_w_cmd_fifo <= '1' when (w_cmd_fifo = '1' and STROBE = '1') else '0';
  PULSE_BPI_WE  : PULSE_EDGE port map(BPI_WE, open, CLK, RST, 1, start_w_cmd_fifo);
  PULSE_BPI_RE  : PULSE_EDGE port map(BPI_RE, open, CLK, RST, 1, q_dtack_r_rbk_fifo_b);

  PULSE_CFG_UL   : PULSE_EDGE port map(BPI_CFG_UL_INNER, open, CLK, RST, 1, start_ul);
  PULSE_CFG_DL   : PULSE_EDGE port map(BPI_CFG_DL_INNER, open, CLK, RST, 1, SEND_BPI_CFG_DL);
  PULSE_BPI_ENBL : PULSE_EDGE port map(BPI_ENBL_INNER, open, CLK, RST, 1, SEND_BPI_ENBL);
  PULSE_BPI_DSBL : PULSE_EDGE port map(BPI_DSBL_INNER, open, CLK, RST, 1, SEND_BPI_DSBL);

  BPI_CFG_UL <= BPI_CFG_UL_INNER;
  BPI_CFG_DL <= BPI_CFG_DL_INNER;
  BPI_RST    <= BPI_RST_INNER;
  BPI_ENBL   <= BPI_ENBL_INNER;
  BPI_DSBL   <= BPI_DSBL_INNER;

  OUTDATA <= BPI_RBK_FIFO_DATA when (R_RBK_FIFO = '1') else
             "00000" & BPI_RBK_WRD_CNT when (R_RBK_FIFO_NW = '1') else
             BPI_STATUS                when (R_BPI_STATUS = '1')  else
             BPI_TIMER(15 downto 0)    when (R_BPI_TIMER_L = '1') else
             BPI_TIMER(31 downto 16)   when (R_BPI_TIMER_H = '1') else
             (others => 'Z');

-- Generate CMD_FIFO INPUT DATA
  FDCE_GEN : for i in 0 to 15 generate
  begin
    FDCE_CMD_FIFO_DATA : FDCE port map (BPI_CMD_FIFO_DATA(i), STROBE, W_CMD_FIFO, RST, INDATA(i));
  end generate FDCE_GEN;

-- Chip ScopePro
  csp_bpi_port_la_pm : csp_bpi_port_la
    port map (
      CONTROL => CSP_BPI_PORT_LA_CTRL,
      CLK     => CLK,
      DATA    => bpi_port_csp_data,
      TRIG0   => bpi_port_csp_trig
      );

  bpi_port_csp_trig <= "00" & STROBE & BPI_ENBL_INNER & BPI_DSBL_INNER & BPI_RST_INNER
                       & SEND_BPI_CFG_UL & SEND_BPI_CFG_DL;
  bpi_port_csp_data <= "0" & x"000000000000" &
                       std_logic_vector(cmddev) &          --[78:66]
                       x"0000" &        --[65:50]
                       BPI_RBK_FIFO_DATA &                 --[49:34]
                       BPI_RBK_WRD_CNT &                   --[33:23]
                       BPI_CFG_BUSY & BPI_DONE & bpi_done_pulse & STROBE & WRITE_B & RST &  --[22:17]
                       D_DTACK & DD_DTACK_SEND_BPI_ENBL &  --[16:15]
                       D_DTACK_SEND_BPI_ENBL & Q_DTACK_SEND_BPI_ENBL &  --[14:13]
                       bpi_cfg_dl_pulse_inner & SEND_BPI_CFG_DL & BPI_CFG_DL_INNER &  --[12:10]
                       bpi_cfg_ul_pulse_inner & SEND_BPI_CFG_UL & BPI_CFG_UL_INNER &  --[9:7]
                       DD_DTACK & DD_DTACK_CFG_UL_DL & D_DTACK_CFG_UL_DL &  -- [6:4]
                       Q_DTACK_CFG_UL_DL & D_DTACK & Q_DTACK & DTACK_INNER;  --[3:0]
  
  
end BPI_PORT_Arch;
