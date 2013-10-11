library ieee;
library work;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library hdlmacro;
use hdlmacro.hdlmacro.all;

entity BPI_PORT is
  
  port (

    CLK  : in  std_logic; -- SLOWCLK
    RST      : in  std_logic;

    DEVICE   : in  std_logic;
    STROBE   : in  std_logic;
    COMMAND  : in  std_logic_vector(9 downto 0);
    WRITE_B   : in  std_logic; -- WRITER

    INDATA   : in  std_logic_vector(15 downto 0);
    OUTDATA  : out std_logic_vector(15 downto 0);

    DTACK_B    : out std_logic; -- DTACK

-- BPI controls
    BPI_RST : out std_logic;
    BPI_CMD_FIFO_DATA : out std_logic_vector(15 downto 0);
    BPI_WE : out std_logic;
    BPI_RE : out std_logic;
    BPI_DSBL : out std_logic;
    BPI_ENBL : out std_logic;
    BPI_CFG_DL : out std_logic;
    BPI_CFG_UL : out std_logic;

    BPI_RBK_FIFO_DATA : in std_logic_vector(15 downto 0);
    BPI_RBK_WRD_CNT : in std_logic_vector(10 downto 0);
    BPI_STATUS : in std_logic_vector(15 downto 0);
    BPI_TIMER : in std_logic_vector(31 downto 0);
    BPI_MODE : out std_logic;
    BPI_CFG_DATA_SEL : out std_logic;
    BPI_CFG_REG0 : in std_logic_vector(15 downto 0);
    BPI_CFG_REG1 : in std_logic_vector(15 downto 0);
    BPI_CFG_REG2 : in std_logic_vector(15 downto 0);
    BPI_CFG_REG3 : in std_logic_vector(15 downto 0);
    BPI_CFG_BUSY : in std_logic;
    BPI_DONE : in std_logic
   
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
  
  signal CMDDEV : unsigned(12 downto 0);
  signal WRITE_CTRL_REG,D_DTACK_WRITE_CTRL_REG,Q_DTACK_WRITE_CTRL_REG: std_logic;
  signal READ_CFG_REG,D_DTACK_READ_CFG_REG,Q_DTACK_READ_CFG_REG: std_logic;
  signal SEND_BPI_CFG_UL,D_DTACK_SEND_BPI_CFG_UL,Q_DTACK_SEND_BPI_CFG_UL: std_logic;
  signal SEND_BPI_CFG_DL,D_DTACK_SEND_BPI_CFG_DL,Q_DTACK_SEND_BPI_CFG_DL: std_logic;
  signal SEND_BPI_RST,D_DTACK_SEND_BPI_RST,Q_DTACK_SEND_BPI_RST: std_logic;
  signal SEND_BPI_DSBL,D_DTACK_SEND_BPI_DSBL,Q_DTACK_SEND_BPI_DSBL: std_logic;
  signal SEND_BPI_ENBL,D_DTACK_SEND_BPI_ENBL,Q_DTACK_SEND_BPI_ENBL: std_logic;
  signal WRITE_CMD_FIFO,D_DTACK_WRITE_CMD_FIFO,Q_DTACK_WRITE_CMD_FIFO: std_logic;
  signal READ_RBK_FIFO,D_DTACK_READ_RBK_FIFO,Q_DTACK_READ_RBK_FIFO: std_logic;
  signal READ_RBK_FIFO_NW,D_DTACK_READ_RBK_FIFO_NW,Q_DTACK_READ_RBK_FIFO_NW: std_logic;
  signal READ_BPI_STATUS,D_DTACK_READ_BPI_STATUS,Q_DTACK_READ_BPI_STATUS: std_logic;
  signal READ_BPI_TIMER_L,D_DTACK_READ_BPI_TIMER_L,Q_DTACK_READ_BPI_TIMER_L: std_logic;
  signal READ_BPI_TIMER_H,D_DTACK_READ_BPI_TIMER_H,Q_DTACK_READ_BPI_TIMER_H: std_logic;

  signal DTACK_INNER : std_logic;

  signal BPI_CFG_REG_SEL : std_logic_vector(1 downto 0);
  
begin  --Architecture

-- Decode instruction
  CMDDEV <= unsigned(DEVICE & COMMAND & "00");  -- Variable that looks like the VME commands we input
  
  WRITE_CTRL_REG    <= '1' when (CMDDEV = x"1010") else '0'; -- COMMAND = 0x004
  READ_CFG_REG      <= '1' when (CMDDEV = x"1014") else '0'; -- COMMAND = 0x005
  SEND_BPI_CFG_UL   <= '1' when (CMDDEV = x"1018") else '0'; -- COMMAND = 0x006
  SEND_BPI_CFG_DL   <= '1' when (CMDDEV = x"101C") else '0'; -- COMMAND = 0x007
  SEND_BPI_RST      <= '1' when (CMDDEV = x"1020") else '0'; -- COMMAND = 0x008
  SEND_BPI_DSBL     <= '1' when (CMDDEV = x"1024") else '0'; -- COMMAND = 0x009
  SEND_BPI_ENBL     <= '1' when (CMDDEV = x"1028") else '0'; -- COMMAND = 0x00A
  WRITE_CMD_FIFO    <= '1' when (CMDDEV = x"102C") else '0'; -- COMMAND = 0x00B
  READ_RBK_FIFO     <= '1' when (CMDDEV = x"1030") else '0'; -- COMMAND = 0x00C
  READ_RBK_FIFO_NW  <= '1' when (CMDDEV = x"1034") else '0'; -- COMMAND = 0x00D
  READ_BPI_STATUS   <= '1' when (CMDDEV = x"1038") else '0'; -- COMMAND = 0x00E
  READ_BPI_TIMER_L  <= '1' when (CMDDEV = x"103C") else '0'; -- COMMAND = 0x00F
  READ_BPI_TIMER_H  <= '1' when (CMDDEV = x"1040") else '0'; -- COMMAND = 0x010

-- Generate DTACK

  D_DTACK_WRITE_CTRL_REG <= '1' when (WRITE_CTRL_REG='1' and STROBE='1') else '0';
  FD_DTACK_WRITE_CTRL_REG : FD port map (Q_DTACK_WRITE_CTRL_REG,CLK, D_DTACK_WRITE_CTRL_REG);
  DTACK_INNER <= '0' when (Q_DTACK_WRITE_CTRL_REG='1') else 'Z';

  D_DTACK_READ_CFG_REG <= '1' when (READ_CFG_REG='1' and STROBE='1') else '0';
  FD_DTACK_READ_CFG_REG : FD port map (Q_DTACK_READ_CFG_REG,CLK, D_DTACK_READ_CFG_REG);
  DTACK_INNER <= '0' when (Q_DTACK_READ_CFG_REG='1') else 'Z';

  D_DTACK_SEND_BPI_CFG_UL <= '1' when (SEND_BPI_CFG_UL='1' and STROBE='1' and BPI_CFG_BUSY='0') else '0';
  FD_DTACK_SEND_BPI_CFG_UL : FD port map (Q_DTACK_SEND_BPI_CFG_UL,CLK, D_DTACK_SEND_BPI_CFG_UL);
  DTACK_INNER <= '0' when (Q_DTACK_SEND_BPI_CFG_UL='1') else 'Z';

  D_DTACK_SEND_BPI_CFG_DL <= '1' when (SEND_BPI_CFG_DL='1' and STROBE='1' and BPI_CFG_BUSY='0') else '0';
  FD_DTACK_SEND_BPI_CFG_DL : FD port map (Q_DTACK_SEND_BPI_CFG_DL,CLK, D_DTACK_SEND_BPI_CFG_DL);
  DTACK_INNER <= '0' when (Q_DTACK_SEND_BPI_CFG_DL='1') else 'Z';

  D_DTACK_SEND_BPI_RST <= '1' when (SEND_BPI_RST='1' and STROBE='1') else '0';
  FD_DTACK_SEND_BPI_RST : FD port map (Q_DTACK_SEND_BPI_RST,CLK, D_DTACK_SEND_BPI_RST);
  DTACK_INNER <= '0' when (Q_DTACK_SEND_BPI_RST='1') else 'Z';

  D_DTACK_SEND_BPI_ENBL <= '1' when (SEND_BPI_ENBL='1' and STROBE='1' and BPI_DONE='1') else '0';
  FD_DTACK_SEND_BPI_ENBL : FD port map (Q_DTACK_SEND_BPI_ENBL,CLK, D_DTACK_SEND_BPI_ENBL);
  DTACK_INNER <= '0' when (Q_DTACK_SEND_BPI_ENBL='1') else 'Z';

  D_DTACK_SEND_BPI_DSBL <= '1' when (SEND_BPI_DSBL='1' and STROBE='1') else '0';
  FD_DTACK_SEND_BPI_DSBL : FD port map (Q_DTACK_SEND_BPI_DSBL,CLK, D_DTACK_SEND_BPI_DSBL);
  DTACK_INNER <= '0' when (Q_DTACK_SEND_BPI_DSBL='1') else 'Z';

  D_DTACK_WRITE_CMD_FIFO <= '1' when (WRITE_CMD_FIFO='1' and STROBE='1') else '0';
  FD_DTACK_WRITE_CMD_FIFO : FD port map (Q_DTACK_WRITE_CMD_FIFO,CLK, D_DTACK_WRITE_CMD_FIFO);
  DTACK_INNER <= '0' when (Q_DTACK_WRITE_CMD_FIFO='1') else 'Z';

  D_DTACK_READ_RBK_FIFO <= '1' when (READ_RBK_FIFO='1' and STROBE='1') else '0';
  FD_DTACK_READ_RBK_FIFO : FD port map (Q_DTACK_READ_RBK_FIFO,CLK, D_DTACK_READ_RBK_FIFO);
  DTACK_INNER <= '0' when (Q_DTACK_READ_RBK_FIFO='1') else 'Z';

  D_DTACK_READ_RBK_FIFO_NW <= '1' when (READ_RBK_FIFO_NW='1' and STROBE='1') else '0';
  FD_DTACK_READ_RBK_FIFO_NW : FD port map (Q_DTACK_READ_RBK_FIFO_NW,CLK, D_DTACK_READ_RBK_FIFO_NW);
  DTACK_INNER <= '0' when (Q_DTACK_READ_RBK_FIFO_NW='1') else 'Z';

  D_DTACK_READ_BPI_STATUS <= '1' when (READ_BPI_STATUS='1' and STROBE='1') else '0';
  FD_DTACK_READ_BPI_STATUS : FD port map (Q_DTACK_READ_BPI_STATUS,CLK, D_DTACK_READ_BPI_STATUS);
  DTACK_INNER <= '0' when (Q_DTACK_READ_BPI_STATUS='1') else 'Z';

  D_DTACK_READ_BPI_TIMER_L <= '1' when (READ_BPI_TIMER_L='1' and STROBE='1') else '0';
  FD_DTACK_READ_BPI_TIMER_L : FD port map (Q_DTACK_READ_BPI_TIMER_L,CLK, D_DTACK_READ_BPI_TIMER_L);
  DTACK_INNER <= '0' when (Q_DTACK_READ_BPI_TIMER_L='1') else 'Z';

  D_DTACK_READ_BPI_TIMER_H <= '1' when (READ_BPI_TIMER_H='1' and STROBE='1') else '0';
  FD_DTACK_READ_BPI_TIMER_H : FD port map (Q_DTACK_READ_BPI_TIMER_H,CLK, D_DTACK_READ_BPI_TIMER_H);
  DTACK_INNER <= '0' when (Q_DTACK_READ_BPI_TIMER_H='1') else 'Z';

  DTACK_B <= DTACK_INNER;

-- CTRL_REG

  FDCE_B3 : FDCE port map (BPI_MODE,STROBE,WRITE_CTRL_REG,RST,INDATA(3));
  FDCE_B2 : FDCE port map (BPI_CFG_DATA_SEL,STROBE,WRITE_CTRL_REG,RST,INDATA(2));
  FDCE_B1 : FDCE port map (BPI_CFG_REG_SEL(1),STROBE,WRITE_CTRL_REG,RST,INDATA(1));
  FDCE_B0 : FDCE port map (BPI_CFG_REG_SEL(0),STROBE,WRITE_CTRL_REG,RST,INDATA(0));

-- PULSE COMMANDS
  
  PULSE_BPI_WE : PULSE_EDGE port map(BPI_WE, open, CLK, RST, 1, D_DTACK_WRITE_CMD_FIFO);
  PULSE_BPI_RE : PULSE_EDGE port map(BPI_RE, open, CLK, RST, 1, D_DTACK_READ_RBK_FIFO);

  PULSE_CFG_UL : PULSE_EDGE port map(BPI_CFG_UL, open, CLK, RST, 1, SEND_BPI_CFG_UL);
  PULSE_CFG_DL : PULSE_EDGE port map(BPI_CFG_DL, open, CLK, RST, 1, SEND_BPI_CFG_DL);
  PULSE_BPI_RST : PULSE_EDGE port map(BPI_RST, open, CLK, RST, 1, SEND_BPI_RST);
  PULSE_BPI_ENBL : PULSE_EDGE port map(BPI_ENBL, open, CLK, RST, 1, SEND_BPI_ENBL);
  PULSE_BPI_DSBL : PULSE_EDGE port map(BPI_DSBL, open, CLK, RST, 1, SEND_BPI_DSBL);

-- Generate OUTDATA

  OUTDATA <= BPI_CFG_REG0 when (STROBE='1' and READ_CFG_REG='1' and (BPI_CFG_REG_SEL="00")) else 
             BPI_CFG_REG1 when (STROBE='1' and READ_CFG_REG='1' and (BPI_CFG_REG_SEL="01")) else 
             BPI_CFG_REG2 when (STROBE='1' and READ_CFG_REG='1' and (BPI_CFG_REG_SEL="10")) else 
             BPI_CFG_REG3 when (STROBE='1' and READ_CFG_REG='1' and (BPI_CFG_REG_SEL="11")) else (others => 'Z');
  OUTDATA <= BPI_RBK_FIFO_DATA when (STROBE='1' and READ_RBK_FIFO='1') else (others => 'Z');
  OUTDATA <= "00000" & BPI_RBK_WRD_CNT when (STROBE='1' and READ_RBK_FIFO_NW='1') else (others => 'Z');
  OUTDATA <= BPI_STATUS when (STROBE='1' and READ_BPI_STATUS='1') else (others => 'Z');
  OUTDATA <= BPI_TIMER(15 downto 0) when (STROBE='1' and READ_BPI_TIMER_L='1') else (others => 'Z');
  OUTDATA <= BPI_TIMER(31 downto 16) when (STROBE='1' and READ_BPI_TIMER_H='1') else (others => 'Z');

-- Generate CMD_FIFO INPUT DATA
  FDCE_GEN: for i in 0 to 15 generate
  begin
  	FDCE_CMD_FIFO_DATA : FDCE port map (BPI_CMD_FIFO_DATA(i),STROBE,WRITE_CMD_FIFO,RST,INDATA(i));
  end generate FDCE_GEN;	
  

end BPI_PORT_Arch;
