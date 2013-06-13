-- TESTFIFOS: Reads test FIFOs written with DCFEB data

library ieee;
library work;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TESTFIFOS is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );    
  port (

    SLOWCLK : in std_logic;
    RST     : in std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    -- PCTX FIFO signals
    PCTX_FIFO_DOUT    : in  std_logic_vector(15 downto 0);
    PCTX_FIFO_WRD_CNT : in  std_logic_vector(11 downto 0);
    PCTX_FIFO_RST     : out std_logic;
    PCTX_FIFO_RDEN    : out std_logic;

    -- TFF (DCFEB test FIFOs)
    TFF_DOUT : in std_logic_vector(15 downto 0);
    TFF_WRD_CNT  : in std_logic_vector(11 downto 0);
    TFF_RST   : out std_logic_vector(NFEB downto 1);
    TFF_SEL   : out std_logic_vector(NFEB downto 1);
    TFF_RDEN : out std_logic_vector(NFEB downto 1)
    );
end TESTFIFOS;



architecture TESTFIFOS_Arch of TESTFIFOS is

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
  signal CMDDEV      : std_logic_vector(15 downto 0);

  type   FIFO_RD_TYPE is array (3 downto 0) of std_logic_vector(NFEB downto 1);
  signal FIFO_RD                                : FIFO_RD_TYPE;
  signal C_FIFO_RD                              : std_logic_vector(NFEB downto 1) := (others => '0');
  signal OUT_TFF_READ                           : std_logic_vector(15 downto 0)   := (others => '0');
  signal R_TFF_READ, D_R_TFF_READ, Q_R_TFF_READ : std_logic                       := '0';

  signal OUT_TFF_WRD_CNT                                 : std_logic_vector(15 downto 0) := (others => '0');
  signal R_TFF_WRD_CNT, D_R_TFF_WRD_CNT, Q_R_TFF_WRD_CNT : std_logic                     := '0';

  signal OUT_TFF_SEL   : std_logic_vector(15 downto 0)   := (others => '0');
  signal TFF_SEL_INNER : std_logic_vector(NFEB downto 1) := (others => '0');
  signal TFF_SEL_CODE  : std_logic_vector(2 downto 0)    := (others => '0');

  signal W_TFF_SEL, D_W_TFF_SEL, Q_W_TFF_SEL : std_logic := '0';
  signal R_TFF_SEL, D_R_TFF_SEL, Q_R_TFF_SEL : std_logic := '0';

  signal W_TFF_RST, D_W_TFF_RST, Q_W_TFF_RST : std_logic                       := '0';
  signal PULSE_TFF_RST, IN_TFF_RST           : std_logic_vector(NFEB downto 1) := (others => '0');
  signal TFF_RST_INNER                       : std_logic_vector(NFEB downto 1) := (others => '0');

  signal PCTX_FF_RD                         : std_logic_vector(3 downto 0);
  signal OUT_PCTX_FF_READ                   : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PCTX_FF_READ, C_PCTX_FF_RD       : std_logic                     := '0';
  signal D_R_PCTX_FF_READ, Q_R_PCTX_FF_READ : std_logic                     := '0';

  signal OUT_PCTX_FF_WRD_CNT                                         : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PCTX_FF_WRD_CNT, D_R_PCTX_FF_WRD_CNT, Q_R_PCTX_FF_WRD_CNT : std_logic                     := '0';

  signal W_PCTX_FF_RST, D_W_PCTX_FF_RST, Q_W_PCTX_FF_RST : std_logic := '0';
  signal PULSE_PCTX_FF_RST, IN_PCTX_FF_RST               : std_logic := '0';
  signal PCTX_FF_RST_INNER                               : std_logic := '0';

begin  --Architecture


-- Decode instruction
  CMDDEV <= "000" & DEVICE & COMMAND & "00";  -- Variable that looks like the VME commands we input  

  R_TFF_READ    <= '1' when (CMDDEV = x"1000") else '0';
  R_TFF_WRD_CNT <= '1' when (CMDDEV = x"100C") else '0';
  W_TFF_SEL     <= '1' when (CMDDEV = x"1010") else '0';
  R_TFF_SEL     <= '1' when (CMDDEV = x"1014") else '0';
  W_TFF_RST     <= '1' when (CMDDEV = x"1020") else '0';

  R_PCTX_FF_READ    <= '1' when (CMDDEV = x"1100") else '0';
  R_PCTX_FF_WRD_CNT <= '1' when (CMDDEV = x"110C") else '0';
  W_PCTX_FF_RST     <= '1' when (CMDDEV = x"1120") else '0';

-- Read TFF_READ
  GEN_TFF_READ : for I in 1 to NFEB generate
  begin
    FIFO_RD(0)(I) <= R_TFF_READ and TFF_SEL_INNER(I);
    FDC_RD_EN1 : FDC port map(FIFO_RD(1)(I), STROBE, C_FIFO_RD(I), FIFO_RD(0)(I));
    FDC_RD_EN2 : FDC port map(FIFO_RD(2)(I), SLOWCLK, C_FIFO_RD(I), FIFO_RD(1)(I));
    FDC_RD_EN3 : FDC port map(FIFO_RD(3)(I), SLOWCLK, C_FIFO_RD(I), FIFO_RD(2)(I));
    C_FIFO_RD(I)  <= RST or FIFO_RD(3)(I);
    TFF_RDEN(I)  <= FIFO_RD(2)(I);
  end generate GEN_TFF_READ;

  OUT_TFF_READ <= TFF_DOUT when (STROBE = '1' and R_TFF_READ = '1') else (others => 'Z');

  D_R_TFF_READ <= '1' when (STROBE = '1' and R_TFF_READ = '1') else '0';
  FD_R_TFF_READ : FD port map(Q_R_TFF_READ, SLOWCLK, D_R_TFF_READ);
  DTACK_INNER  <= '0' when (Q_R_TFF_READ = '1')                else 'Z';


-- Read TFF_WRD_CNT
  OUT_TFF_WRD_CNT(11 downto 0) <= TFF_WRD_CNT when (STROBE = '1' and R_TFF_WRD_CNT = '1') else (others => 'Z');

  D_R_TFF_WRD_CNT <= '1' when (STROBE = '1' and R_TFF_WRD_CNT = '1') else '0';
  FD_R_TFF_WRD_CNT : FD port map(Q_R_TFF_WRD_CNT, SLOWCLK, D_R_TFF_WRD_CNT);
  DTACK_INNER     <= '0' when (Q_R_TFF_WRD_CNT = '1')                else 'Z';

-- Write TFF_SEL
  GEN_TFF_SEL : for I in 2 downto 0 generate
  begin
    FD_W_TFF_SEL : FDCE port map(TFF_SEL_CODE(I), STROBE, W_TFF_SEL, RST, INDATA(I));
  end generate GEN_TFF_SEL;
  TFF_SEL_INNER <= "0000001" when TFF_SEL_CODE = "001" else
                   "0000010" when TFF_SEL_CODE = "010" else
                   "0000100" when TFF_SEL_CODE = "011" else
                   "0001000" when TFF_SEL_CODE = "100" else
                   "0010000" when TFF_SEL_CODE = "101" else
                   "0100000" when TFF_SEL_CODE = "110" else
                   "1000000" when TFF_SEL_CODE = "111" else
                   "0000001";
  TFF_SEL     <= TFF_SEL_INNER;
  D_W_TFF_SEL <= '1' when (STROBE = '1' and W_TFF_SEL = '1') else '0';
  FD_DTACK_TFF_SEL : FD port map(Q_W_TFF_SEL, SLOWCLK, D_W_TFF_SEL);
  DTACK_INNER <= '0' when (Q_W_TFF_SEL = '1')                else 'Z';

-- Read TFF_SEL
  OUT_TFF_SEL(2 downto 0) <= TFF_SEL_CODE when (STROBE = '1' and R_TFF_SEL = '1') else (others => 'Z');

  D_R_TFF_SEL <= '1' when (STROBE = '1' and R_TFF_SEL = '1') else '0';
  FD_R_TFF_SEL : FD port map(Q_R_TFF_SEL, SLOWCLK, D_R_TFF_SEL);
  DTACK_INNER <= '0' when (Q_R_TFF_SEL = '1')                else 'Z';


-- Write TFF_RST (Reset test FIFOs)
  GEN_TFF_RST : for I in NFEB downto 1 generate
  begin
    IN_TFF_RST(I) <= PULSE_TFF_RST(I) or RST;
    FD_W_TFF_RST : FDCE port map(TFF_RST_INNER(I), STROBE, W_TFF_RST, IN_TFF_RST(I), INDATA(I-1));
    PULSE_RESET  : PULSE_EDGE port map(tff_rst(I), pulse_tff_rst(I), slowclk, rst, 1, tff_rst_inner(I));
  end generate GEN_TFF_RST;
  D_W_TFF_RST <= '1' when (STROBE = '1' and W_TFF_RST = '1') else '0';
  FD_DTACK_TFF_RST : FD port map(Q_W_TFF_RST, SLOWCLK, D_W_TFF_RST);
  DTACK_INNER <= '0' when (Q_W_TFF_RST = '1')                else 'Z';

-- Read PCTX_FF_READ
  PCTX_FF_RD(0) <= R_PCTX_FF_READ;
  FDC_RD_EN1 : FDC port map(PCTX_FF_RD(1), STROBE, C_PCTX_FF_RD, PCTX_FF_RD(0));
  FDC_RD_EN2 : FDC port map(PCTX_FF_RD(2), SLOWCLK, C_PCTX_FF_RD, PCTX_FF_RD(1));
  FDC_RD_EN3 : FDC port map(PCTX_FF_RD(3), SLOWCLK, C_PCTX_FF_RD, PCTX_FF_RD(2));
  C_PCTX_FF_RD  <= RST or PCTX_FF_RD(3);
  PCTX_FIFO_RDEN <= PCTX_FF_RD(2);

  OUT_PCTX_FF_READ <= PCTX_FIFO_DOUT when (STROBE = '1' and R_PCTX_FF_READ = '1') else (others => 'Z');

  D_R_PCTX_FF_READ <= '1' when (STROBE = '1' and R_PCTX_FF_READ = '1') else '0';
  FD_R_PCTX_FF_READ : FD port map(Q_R_PCTX_FF_READ, SLOWCLK, D_R_PCTX_FF_READ);
  DTACK_INNER      <= '0' when (Q_R_PCTX_FF_READ = '1')                else 'Z';


-- Read PCTX_FF_WRD_CNT
  OUT_PCTX_FF_WRD_CNT(11 downto 0) <= PCTX_FIFO_WRD_CNT when (STROBE = '1' and R_PCTX_FF_WRD_CNT = '1') else (others => 'Z');

  D_R_PCTX_FF_WRD_CNT <= '1' when (STROBE = '1' and R_PCTX_FF_WRD_CNT = '1') else '0';
  FD_R_PCTX_FF_WRD_CNT : FD port map(Q_R_PCTX_FF_WRD_CNT, SLOWCLK, D_R_PCTX_FF_WRD_CNT);
  DTACK_INNER         <= '0' when (Q_R_PCTX_FF_WRD_CNT = '1')                else 'Z';

-- Write PCTX_FF_RST (Reset PCTX FIFO)
  IN_PCTX_FF_RST  <= PULSE_PCTX_FF_RST or RST;
  FD_W_PCTX_FF_RST     : FDCE port map(PCTX_FF_RST_INNER, STROBE, W_PCTX_FF_RST, IN_PCTX_FF_RST, INDATA(0));
  PULSE_RESET          : PULSE_EDGE port map(pctx_fifo_rst, pulse_pctx_ff_rst, slowclk, rst, 1, pctx_ff_rst_inner);
  D_W_PCTX_FF_RST <= '1' when (STROBE = '1' and W_PCTX_FF_RST = '1') else '0';
  FD_DTACK_PCTX_FF_RST : FD port map(Q_W_PCTX_FF_RST, SLOWCLK, D_W_PCTX_FF_RST);
  DTACK_INNER     <= '0' when (Q_W_PCTX_FF_RST = '1')                else 'Z';

-- General assignments
  OUTDATA <= OUT_TFF_READ when R_TFF_READ = '1' else
             OUT_TFF_SEL         when R_TFF_SEL = '1'         else
             OUT_TFF_WRD_CNT     when R_TFF_WRD_CNT = '1'     else
             OUT_PCTX_FF_READ    when R_PCTX_FF_READ = '1'    else
             OUT_PCTX_FF_WRD_CNT when R_PCTX_FF_WRD_CNT = '1' else
             (others => 'Z');
  DTACK <= DTACK_INNER;
  
end TESTFIFOS_Arch;
