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
    CLK : in std_logic;                 -- SLOWCLK
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
    BPI_MODE          : out std_logic_vector(1 downto 0);
    BPI_CFG_DATA_SEL  : out std_logic;
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
  signal bpi_mode_inner         : std_logic_vector(1 downto 0);

  signal d_dtack, q_dtack             : std_logic;
  signal w_ctrl_reg, r_ctrl_reg       : std_logic;
  signal w_cfg_reg, d_dtack_w_cfg_reg : std_logic;
  signal r_cfg_reg                    : std_logic;
  signal send_bpi_rst                 : std_logic;
  signal send_bpi_dsbl                : std_logic;
  signal r_rbk_fifo_nw                : std_logic;
  signal r_bpi_status                 : std_logic;
  signal r_bpi_timer_l                : std_logic;
  signal r_bpi_timer_h                : std_logic;

  signal send_bpi_enbl, d_dtack_send_bpi_enbl, q_dtack_send_bpi_enbl        : std_logic;
  signal rst_send_bpi_enbl, dd_dtack_send_bpi_enbl, ddd_dtack_send_bpi_enbl : std_logic;
  signal send_bpi_cfg_ul, d_dtack_send_bpi_cfg_ul, q_dtack_send_bpi_cfg_ul  : std_logic;
  signal send_bpi_cfg_dl, d_dtack_send_bpi_cfg_dl, q_dtack_send_bpi_cfg_dl  : std_logic;
  signal w_cmd_fifo, d_dtack_w_cmd_fifo                                     : std_logic;
  signal d_dtack_w_ctrl_reg, q_dtack_w_ctrl_reg                             : std_logic;
  signal d_dtack_r_ctrl_reg, q_dtack_r_ctrl_reg                             : std_logic;
  signal r_rbk_fifo, d_dtack_r_rbk_fifo, q_dtack_r_rbk_fifo, q_dtack_r_rbk_fifo_b                 : std_logic;

  signal d_write_cfg_reg : std_logic_vector(3 downto 0);

  signal bpi_cfg_reg_sel : std_logic_vector(1 downto 0);
  signal out_ctrl_reg    : std_logic_vector(15 downto 0);
  
begin  --Architecture

-- Decode instruction
  CMDDEV <= unsigned(DEVICE & COMMAND & "00");  -- Variable that looks like the VME commands we input

  W_CTRL_REG <= '1' when (CMDDEV = x"1010" and WRITE_B = '0') else '0';  -- COMMAND = 0x004
  R_CTRL_REG <= '1' when (CMDDEV = x"1010" and WRITE_B = '1') else '0';  -- COMMAND = 0x004

  R_CFG_REG       <= '1' when (CMDDEV = x"1014") else '0';  -- COMMAND = 0x005
  SEND_BPI_CFG_UL <= '1' when (CMDDEV = x"1018") else '0';  -- COMMAND = 0x006
  SEND_BPI_CFG_DL <= '1' when (CMDDEV = x"101C") else '0';  -- COMMAND = 0x007
  SEND_BPI_RST    <= '1' when (CMDDEV = x"1020") else '0';  -- COMMAND = 0x008
  SEND_BPI_DSBL   <= '1' when (CMDDEV = x"1024") else '0';  -- COMMAND = 0x009
  SEND_BPI_ENBL   <= '1' when (CMDDEV = x"1028") else '0';  -- COMMAND = 0x00A
  W_CMD_FIFO      <= '1' when (CMDDEV = x"102C") else '0';  -- COMMAND = 0x00B
  R_RBK_FIFO      <= '1' when (CMDDEV = x"1030") else '0';  -- COMMAND = 0x00C
  R_RBK_FIFO_NW   <= '1' when (CMDDEV = x"1034") else '0';  -- COMMAND = 0x00D
  R_BPI_STATUS    <= '1' when (CMDDEV = x"1038") else '0';  -- COMMAND = 0x00E
  R_BPI_TIMER_L   <= '1' when (CMDDEV = x"103C") else '0';  -- COMMAND = 0x00F
  R_BPI_TIMER_H   <= '1' when (CMDDEV = x"1040") else '0';  -- COMMAND = 0x010
  W_CFG_REG       <= '1' when (CMDDEV = X"1044") else '0';  -- COMMAND = 0X011

-- Generate DTACK

  D_DTACK <= '1' when ((W_CTRL_REG = '1' or R_CTRL_REG = '1' or R_CFG_REG = '1' or
                        SEND_BPI_RST = '1' or SEND_BPI_DSBL = '1' or R_RBK_FIFO_NW = '1' or
                        R_BPI_STATUS = '1' or R_BPI_TIMER_L = '1' or R_BPI_TIMER_H = '1' or
                        W_CFG_REG = '1' or W_CMD_FIFO = '1')
                       and STROBE = '1') else '0';
  
  FD_DTACK : FD port map (Q_DTACK, CLK, D_DTACK);

  D_DTACK_SEND_BPI_CFG_UL <= '1' when (SEND_BPI_CFG_UL = '1' and STROBE = '1' and BPI_CFG_BUSY = '0') else '0';
  FD_DTACK_SEND_BPI_CFG_UL : FD port map (Q_DTACK_SEND_BPI_CFG_UL, CLK, D_DTACK_SEND_BPI_CFG_UL);

  D_DTACK_SEND_BPI_CFG_DL <= '1' when (SEND_BPI_CFG_DL = '1' and STROBE = '1' and BPI_CFG_BUSY = '0') else '0';
  FD_DTACK_SEND_BPI_CFG_DL : FD port map (Q_DTACK_SEND_BPI_CFG_DL, CLK, D_DTACK_SEND_BPI_CFG_DL);

  DDD_DTACK_SEND_BPI_ENBL <= SEND_BPI_ENBL and STROBE;
  FD_DD_SEND_BPI_ENBL : FD port map(DD_DTACK_SEND_BPI_ENBL, CLK, DDD_DTACK_SEND_BPI_ENBL);
  FD_D_SEND_BPI_ENBL  : FDC port map(D_DTACK_SEND_BPI_ENBL, DD_DTACK_SEND_BPI_ENBL, RST_SEND_BPI_ENBL, '1');
  FD_SEND_BPI_ENBL    : FD port map(Q_DTACK_SEND_BPI_ENBL, CLK, D_DTACK_SEND_BPI_ENBL);
  RST_SEND_BPI_ENBL       <= BPI_DONE and Q_DTACK_SEND_BPI_ENBL;

  --d_dtack signals for pulse commands
  d_dtack_w_cmd_fifo <= '1' when (w_cmd_fifo = '1' and STROBE = '1') else '0';
  d_dtack_w_cfg_reg  <= '1' when (w_cfg_reg = '1' and STROBE = '1')  else '0';
  d_dtack_r_rbk_fifo <= '1' when (r_rbk_fifo = '1' and STROBE = '1') else '0';
  FD_DTACK_RBKFIFO : FD port map (q_dtack_r_rbk_fifo, CLK, d_dtack_r_rbk_fifo);
  q_dtack_r_rbk_fifo_b <= not q_dtack_r_rbk_fifo;

  DTACK <= q_dtack or q_dtack_send_bpi_cfg_ul or q_dtack_send_bpi_cfg_dl or
           q_dtack_send_bpi_enbl or q_dtack_r_rbk_fifo;

-- CTRL_REG

  FDPE_B4 : FDPE port map (bpi_mode_inner(1), STROBE, W_CTRL_REG, INDATA(4), RST);
  FDCE_B3 : FDCE port map (bpi_mode_inner(0), STROBE, W_CTRL_REG, RST, INDATA(3));
  FDCE_B2 : FDCE port map (BPI_CFG_DATA_SEL_INNER, STROBE, W_CTRL_REG, RST, INDATA(2));
  FDCE_B1 : FDCE port map (BPI_CFG_REG_SEL(1), STROBE, W_CTRL_REG, RST, INDATA(1));
  FDCE_B0 : FDCE port map (BPI_CFG_REG_SEL(0), STROBE, W_CTRL_REG, RST, INDATA(0));

  BPI_MODE         <= bpi_mode_inner;
  BPI_CFG_DATA_SEL <= BPI_CFG_DATA_SEL_INNER;

-- PULSE COMMANDS

  PULSE_BPI_WE : PULSE_EDGE port map(BPI_WE, open, CLK, RST, 1, D_DTACK_W_CMD_FIFO);
  PULSE_BPI_RE : PULSE_EDGE port map(BPI_RE, open, CLK, RST, 1, q_dtack_r_rbk_fifo_b);

  PULSE_CFG_UL   : PULSE_EDGE port map(BPI_CFG_UL, open, CLK, RST, 1, SEND_BPI_CFG_UL);
  PULSE_CFG_DL   : PULSE_EDGE port map(BPI_CFG_DL, open, CLK, RST, 1, SEND_BPI_CFG_DL);
  PULSE_BPI_RST  : PULSE_EDGE port map(BPI_RST, open, CLK, RST, 10, SEND_BPI_RST);
  PULSE_BPI_ENBL : PULSE_EDGE port map(BPI_ENBL, open, CLK, RST, 1, SEND_BPI_ENBL);
  PULSE_BPI_DSBL : PULSE_EDGE port map(BPI_DSBL, open, CLK, RST, 1, SEND_BPI_DSBL);

-- Generate OUTDATA
  OUT_CTRL_REG <= "000" & x"00" & BPI_MODE_INNER & BPI_CFG_DATA_SEL_INNER & BPI_CFG_REG_SEL;

  OUTDATA <= BPI_CFG_REG0 when (STROBE = '1' and R_CFG_REG = '1' and (BPI_CFG_REG_SEL = "00")) else
             BPI_CFG_REG1              when (STROBE = '1' and R_CFG_REG = '1' and (BPI_CFG_REG_SEL = "01")) else
             BPI_CFG_REG2              when (STROBE = '1' and R_CFG_REG = '1' and (BPI_CFG_REG_SEL = "10")) else
             BPI_CFG_REG3              when (STROBE = '1' and R_CFG_REG = '1' and (BPI_CFG_REG_SEL = "11")) else
             BPI_RBK_FIFO_DATA         when (STROBE = '1' and R_RBK_FIFO = '1')                             else
             "00000" & BPI_RBK_WRD_CNT when (STROBE = '1' and R_RBK_FIFO_NW = '1')                          else
             BPI_STATUS                when (STROBE = '1' and R_BPI_STATUS = '1')                           else
             BPI_TIMER(15 downto 0)    when (STROBE = '1' and R_BPI_TIMER_L = '1')                          else
             BPI_TIMER(31 downto 16)   when (STROBE = '1' and R_BPI_TIMER_H = '1')                          else
             OUT_CTRL_REG              when (STROBE = '1' and R_CTRL_REG = '1')                             else
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

  BPI_CFG_REG_IN <= INDATA;

-- Generate CMD_FIFO INPUT DATA
  FDCE_GEN : for i in 0 to 15 generate
  begin
    FDCE_CMD_FIFO_DATA : FDCE port map (BPI_CMD_FIFO_DATA(i), STROBE, W_CMD_FIFO, RST, INDATA(i));
  end generate FDCE_GEN;
  

end BPI_PORT_Arch;
