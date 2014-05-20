-- TESTFIFOS: Reads test FIFOs written with DCFEB data

library ieee;
library work;
library unisim;
library unimacro;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ucsb_types.all;

entity TESTFIFOS is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );    
  port (

    SLOWCLK : in std_logic;
    RST     : in std_logic;
    CLK40   : in std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);
    WRITER  : in std_logic;

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    -- ALCT/OTMB FIFO signals
    alct_fifo_data_in    : in std_logic_vector(17 downto 0);
    alct_fifo_data_valid : in std_logic;
    otmb_fifo_data_in    : in std_logic_vector(17 downto 0);
    otmb_fifo_data_valid : in std_logic;

    -- PC_TX FIFO signals
    PC_TX_FIFO_DOUT    : in  std_logic_vector(15 downto 0);
    PC_TX_FIFO_WRD_CNT : in  std_logic_vector(15 downto 0);
    PC_TX_FIFO_RST     : out std_logic;
    PC_TX_FIFO_RDEN    : out std_logic;

    -- PC_RX FIFO signals
    PC_RX_FIFO_DOUT    : in  std_logic_vector(15 downto 0);
    PC_RX_FIFO_WRD_CNT : in  std_logic_vector(15 downto 0);
    PC_RX_FIFO_RST     : out std_logic;
    PC_RX_FIFO_RDEN    : out std_logic;

    -- DDU_TX FIFO signals
    DDU_TX_FIFO_DOUT    : in  std_logic_vector(15 downto 0);
    DDU_TX_FIFO_WRD_CNT : in  std_logic_vector(15 downto 0);
    DDU_TX_FIFO_RST     : out std_logic;
    DDU_TX_FIFO_RDEN    : out std_logic;

    -- DDU_RX FIFO signals
    DDU_RX_FIFO_DOUT    : in  std_logic_vector(15 downto 0);
    DDU_RX_FIFO_WRD_CNT : in  std_logic_vector(15 downto 0);
    DDU_RX_FIFO_RST     : out std_logic;
    DDU_RX_FIFO_RDEN    : out std_logic;

    -- HEADER FIFO signals
    DDU_DATA       : in std_logic_vector(15 downto 0);
    DDU_DATA_VALID : in std_logic;
    DDUCLK         : in std_logic;

    -- TFF (DCFEB test FIFOs)
    TFF_DOUT    : in  std_logic_vector(15 downto 0);
    TFF_WRD_CNT : in  std_logic_vector(11 downto 0);
    TFF_RST     : out std_logic_vector(NFEB downto 1);
    TFF_SEL     : out std_logic_vector(NFEB downto 1);
    TFF_RDEN    : out std_logic_vector(NFEB downto 1)
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

  component FIFOWORDS is
    generic (WIDTH : integer := 16);
    port (
      RST   : in  std_logic;
      WRCLK : in  std_logic;
      WREN  : in  std_logic;
      FULL  : in  std_logic;
      RDCLK : in  std_logic;
      RDEN  : in  std_logic;
      COUNT : out std_logic_vector(WIDTH-1 downto 0)
      );
  end component;

  signal dd_dtack, d_dtack, q_dtack : std_logic;
  signal CMDDEV                     : std_logic_vector(15 downto 0);

  type FIFO_RD_TYPE is array (3 downto 0) of std_logic_vector(NFEB downto 1);
  signal FIFO_RD      : FIFO_RD_TYPE;
  signal C_FIFO_RD    : std_logic_vector(NFEB downto 1) := (others => '0');
  signal OUT_TFF_READ : std_logic_vector(15 downto 0)   := (others => '0');
  signal R_TFF_READ   : std_logic                       := '0';

  signal OUT_TFF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_TFF_WRD_CNT   : std_logic                     := '0';

  signal OUT_TFF_SEL   : std_logic_vector(15 downto 0)   := (others => '0');
  signal TFF_SEL_INNER : std_logic_vector(NFEB downto 1) := (others => '0');
  signal TFF_SEL_CODE  : std_logic_vector(2 downto 0)    := (others => '0');

  signal W_TFF_SEL, R_TFF_SEL : std_logic := '0';

  signal W_TFF_RST                 : std_logic                       := '0';
  signal PULSE_TFF_RST, IN_TFF_RST : std_logic_vector(NFEB downto 1) := (others => '0');
  signal TFF_RST_INNER             : std_logic_vector(NFEB downto 1) := (others => '0');

  signal PC_TX_FF_RD                    : std_logic_vector(3 downto 0);
  signal OUT_PC_TX_FF_READ              : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PC_TX_FF_READ, C_PC_TX_FF_RD : std_logic                     := '0';

  signal OUT_PC_TX_FF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PC_TX_FF_WRD_CNT   : std_logic                     := '0';

  signal W_PC_TX_FF_RST : std_logic := '0';

  signal PC_RX_FF_RD                    : std_logic_vector(3 downto 0);
  signal OUT_PC_RX_FF_READ              : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PC_RX_FF_READ, C_PC_RX_FF_RD : std_logic                     := '0';

  signal OUT_PC_RX_FF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PC_RX_FF_WRD_CNT   : std_logic                     := '0';

  signal W_PC_RX_FF_RST : std_logic := '0';

  signal DDU_TX_FF_RD                     : std_logic_vector(3 downto 0);
  signal OUT_DDU_TX_FF_READ               : std_logic_vector(15 downto 0) := (others => '0');
  signal R_DDU_TX_FF_READ, C_DDU_TX_FF_RD : std_logic                     := '0';

  signal OUT_DDU_TX_FF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_DDU_TX_FF_WRD_CNT   : std_logic                     := '0';

  signal W_DDU_TX_FF_RST : std_logic := '0';

  signal DDU_RX_FF_RD                     : std_logic_vector(3 downto 0);
  signal OUT_DDU_RX_FF_READ               : std_logic_vector(15 downto 0) := (others => '0');
  signal R_DDU_RX_FF_READ, C_DDU_RX_FF_RD : std_logic                     := '0';

  signal OUT_DDU_RX_FF_WRD_CNT                      : std_logic_vector(15 downto 0) := (others => '0');
  signal R_DDU_RX_FF_WRD_CNT, D_R_DDU_RX_FF_WRD_CNT : std_logic                     := '0';

  signal W_DDU_RX_FF_RST : std_logic := '0';

  -- OTMB FIFO
  signal OTMB_FF_RD                   : std_logic_vector(3 downto 0);
  signal OTMB_FIFO_DOUT               : std_logic_vector(17 downto 0) := (others => '0');
  signal OUT_OTMB_FF_READ             : std_logic_vector(15 downto 0) := (others => '0');
  signal R_OTMB_FF_READ, C_OTMB_FF_RD : std_logic                     := '0';
  signal OTMB_FIFO_RDEN               : std_logic                     := '0';

  signal OTMB_FIFO_WRD_CNT                      : std_logic_vector(11 downto 0) := (others => '0');
  signal OUT_OTMB_FF_WRD_CNT                    : std_logic_vector(15 downto 0) := (others => '0');
  signal R_OTMB_FF_WRD_CNT, D_R_OTMB_FF_WRD_CNT : std_logic                     := '0';

  signal W_OTMB_FF_RST : std_logic := '0';

  signal otmb_fifo_rd_cnt, otmb_fifo_wr_cnt : std_logic_vector(10 downto 0);
  signal otmb_fifo_empty, otmb_fifo_full    : std_logic;
  signal otmb_fifo_rst, otmb_fifo_reset     : std_logic;

  -- ALCT FIFO
  signal ALCT_FF_RD                   : std_logic_vector(3 downto 0);
  signal ALCT_FIFO_DOUT               : std_logic_vector(17 downto 0) := (others => '0');
  signal OUT_ALCT_FF_READ             : std_logic_vector(15 downto 0) := (others => '0');
  signal R_ALCT_FF_READ, C_ALCT_FF_RD : std_logic                     := '0';
  signal ALCT_FIFO_RDEN               : std_logic                     := '0';

  signal ALCT_FIFO_WRD_CNT   : std_logic_vector(11 downto 0) := (others => '0');
  signal OUT_ALCT_FF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_ALCT_FF_WRD_CNT   : std_logic                     := '0';

  signal W_ALCT_FF_RST : std_logic := '0';

  signal alct_fifo_rd_cnt, alct_fifo_wr_cnt : std_logic_vector(10 downto 0);
  signal alct_fifo_empty, alct_fifo_full    : std_logic;
  signal alct_fifo_rst, alct_fifo_reset     : std_logic;

  -- HDR FIFO
  signal HDR_FF_RD                  : std_logic_vector(3 downto 0);
  signal HDR_FIFO_DOUT              : std_logic_vector(15 downto 0) := (others => '0');
  signal OUT_HDR_FF_READ            : std_logic_vector(15 downto 0) := (others => '0');
  signal R_HDR_FF_READ, C_HDR_FF_RD : std_logic                     := '0';
  signal HDR_FIFO_RDEN              : std_logic                     := '0';

  signal HDR_FIFO_WRD_CNT   : std_logic_vector(11 downto 0) := (others => '0');
  signal OUT_HDR_FF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_HDR_FF_WRD_CNT   : std_logic                     := '0';

  signal W_HDR_FF_RST, hdr_fifo_data_valid : std_logic := '0';

  signal hdr_fifo_empty, hdr_fifo_full         : std_logic;
  signal hdr_fifo_rst, hdr_fifo_reset, hdr_eof : std_logic;

  
  
begin  --Architecture


-- Decode instruction
  cmddev <= "000" & DEVICE & COMMAND & "00";  -- Variable that looks like the VME commands we input  

  r_tff_read    <= '1' when (cmddev = x"1000")                  else '0';
  r_tff_wrd_cnt <= '1' when (cmddev = x"100c")                  else '0';
  w_tff_sel     <= '1' when (cmddev = x"1010" and writer = '0') else '0';
  r_tff_sel     <= '1' when (cmddev = x"1010" and writer = '1') else '0';
  w_tff_rst     <= '1' when (cmddev = x"1020" and writer = '0') else '0';

  -- pc_tx: 100 series
  r_pc_tx_ff_read    <= '1' when (cmddev = x"1100")                                   else '0';
  r_pc_tx_ff_wrd_cnt <= '1' when (cmddev = x"110c")                                   else '0';
  w_pc_tx_ff_rst     <= '1' when (cmddev = x"1120" and WRITER = '0' and STROBE = '1') else '0';

  -- pc_rx: 200 series
  r_pc_rx_ff_read    <= '1' when (cmddev = x"1200")                                   else '0';
  r_pc_rx_ff_wrd_cnt <= '1' when (cmddev = x"120c")                                   else '0';
  w_pc_rx_ff_rst     <= '1' when (cmddev = x"1220" and WRITER = '0' and STROBE = '1') else '0';

  -- ddu_tx: 300 series
  r_ddu_tx_ff_read    <= '1' when (cmddev = x"1300")                                   else '0';
  r_ddu_tx_ff_wrd_cnt <= '1' when (cmddev = x"130c")                                   else '0';
  w_ddu_tx_ff_rst     <= '1' when (cmddev = x"1320" and WRITER = '0' and STROBE = '1') else '0';

  -- ddu_rx: 400 series
  r_ddu_rx_ff_read    <= '1' when (cmddev = x"1400")                                   else '0';
  r_ddu_rx_ff_wrd_cnt <= '1' when (cmddev = x"140c")                                   else '0';
  w_ddu_rx_ff_rst     <= '1' when (cmddev = x"1420" and WRITER = '0' and STROBE = '1') else '0';

  -- otmb: 500 series
  r_otmb_ff_read    <= '1' when (cmddev = x"1500")                                   else '0';
  r_otmb_ff_wrd_cnt <= '1' when (cmddev = x"150c")                                   else '0';
  w_otmb_ff_rst     <= '1' when (cmddev = x"1520" and WRITER = '0' and STROBE = '1') else '0';

  -- alct: 600 series
  r_alct_ff_read    <= '1' when (cmddev = x"1600")                                   else '0';
  r_alct_ff_wrd_cnt <= '1' when (cmddev = x"160c")                                   else '0';
  w_alct_ff_rst     <= '1' when (cmddev = x"1620" and WRITER = '0' and STROBE = '1') else '0';

  -- hdr: 700 series
  r_hdr_ff_read    <= '1' when (cmddev = x"1700")                                   else '0';
  r_hdr_ff_wrd_cnt <= '1' when (cmddev = x"170c")                                   else '0';
  w_hdr_ff_rst     <= '1' when (cmddev = x"1720" and WRITER = '0' and STROBE = '1') else '0';

-- Read TFF_READ
  GEN_TFF_READ : for I in 1 to NFEB generate
  begin
    FIFO_RD(0)(I) <= R_TFF_READ and TFF_SEL_INNER(I);
    FDC_RD_EN1 : FDC port map(FIFO_RD(1)(I), STROBE, C_FIFO_RD(I), FIFO_RD(0)(I));
    FDC_RD_EN2 : FDC port map(FIFO_RD(2)(I), SLOWCLK, C_FIFO_RD(I), FIFO_RD(1)(I));
    FDC_RD_EN3 : FDC port map(FIFO_RD(3)(I), SLOWCLK, C_FIFO_RD(I), FIFO_RD(2)(I));
    C_FIFO_RD(I)  <= RST or FIFO_RD(3)(I);
    TFF_RDEN(I)   <= FIFO_RD(2)(I);
  end generate GEN_TFF_READ;

  OUT_TFF_READ <= TFF_DOUT when (STROBE = '1' and R_TFF_READ = '1') else (others => 'Z');


-- Read TFF_WRD_CNT
  OUT_TFF_WRD_CNT(15 downto 12) <= (others => '0');
  OUT_TFF_WRD_CNT(11 downto 0)  <= TFF_WRD_CNT when (STROBE = '1' and R_TFF_WRD_CNT = '1') else
                                   (others => 'Z');

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
  TFF_SEL <= TFF_SEL_INNER;

-- Read TFF_SEL
  OUT_TFF_SEL(15 downto 3) <= (others => '0');
  OUT_TFF_SEL(2 downto 0)  <= TFF_SEL_CODE when (STROBE = '1' and R_TFF_SEL = '1') else
                              (others => 'Z');


-- Write TFF_RST (Reset test FIFOs)
  GEN_TFF_RST : for I in NFEB downto 1 generate
  begin
    IN_TFF_RST(I) <= PULSE_TFF_RST(I) or RST;
    FD_W_TFF_RST : FDCE port map(TFF_RST_INNER(I), STROBE, W_TFF_RST, IN_TFF_RST(I), INDATA(I-1));
    PULSE_RESET  : PULSE_EDGE port map(tff_rst(I), pulse_tff_rst(I), slowclk, rst, 1, tff_rst_inner(I));
  end generate GEN_TFF_RST;

-- Read PC_TX_FF_READ
  PC_TX_FF_RD(0)  <= R_PC_TX_FF_READ;
  FDC_PC_TX_RD_EN1 : FDC port map(PC_TX_FF_RD(1), STROBE, C_PC_TX_FF_RD, PC_TX_FF_RD(0));
  FDC_PC_TX_RD_EN2 : FDC port map(PC_TX_FF_RD(2), SLOWCLK, C_PC_TX_FF_RD, PC_TX_FF_RD(1));
  FDC_PC_TX_RD_EN3 : FDC port map(PC_TX_FF_RD(3), SLOWCLK, C_PC_TX_FF_RD, PC_TX_FF_RD(2));
  C_PC_TX_FF_RD   <= RST or PC_TX_FF_RD(3);
  PC_TX_FIFO_RDEN <= PC_TX_FF_RD(2);

  OUT_PC_TX_FF_READ <= PC_TX_FIFO_DOUT when (STROBE = '1' and R_PC_TX_FF_READ = '1') else (others => 'Z');

-- Read PC_TX_FF_WRD_CNT
  OUT_PC_TX_FF_WRD_CNT <= PC_TX_FIFO_WRD_CNT when (STROBE = '1' and R_PC_TX_FF_WRD_CNT = '1') else
                          (others => 'Z');

-- Write PC_TX_FF_RST (Reset PC_TX FIFO)
  PULSE_RESET_PC_TX : PULSE_EDGE port map(PC_TX_FIFO_RST, open, slowclk, rst, 1, w_pc_tx_ff_rst);

-- Read PC_RX_FF_READ
  PC_RX_FF_RD(0)  <= R_PC_RX_FF_READ;
  FDC_PC_RX_RD_EN1 : FDC port map(PC_RX_FF_RD(1), STROBE, C_PC_RX_FF_RD, PC_RX_FF_RD(0));
  FDC_PC_RX_RD_EN2 : FDC port map(PC_RX_FF_RD(2), SLOWCLK, C_PC_RX_FF_RD, PC_RX_FF_RD(1));
  FDC_PC_RX_RD_EN3 : FDC port map(PC_RX_FF_RD(3), SLOWCLK, C_PC_RX_FF_RD, PC_RX_FF_RD(2));
  C_PC_RX_FF_RD   <= RST or PC_RX_FF_RD(3);
  PC_RX_FIFO_RDEN <= PC_RX_FF_RD(2);

  OUT_PC_RX_FF_READ <= PC_RX_FIFO_DOUT when (STROBE = '1' and R_PC_RX_FF_READ = '1') else (others => 'Z');

-- Read PC_RX_FF_WRD_CNT
  OUT_PC_RX_FF_WRD_CNT <= PC_RX_FIFO_WRD_CNT when (STROBE = '1' and R_PC_RX_FF_WRD_CNT = '1') else
                          (others => 'Z');

-- Write PC_RX_FF_RST (Reset PC_RX FIFO)
  PULSE_RESET_PC_RX : PULSE_EDGE port map(pc_rx_fifo_rst, open, slowclk, rst, 1, w_pc_rx_ff_rst);

-- Read DDU_TX_FF_READ
  DDU_TX_FF_RD(0)  <= R_DDU_TX_FF_READ;
  FDC_DDU_TX_RD_EN1 : FDC port map(DDU_TX_FF_RD(1), STROBE, C_DDU_TX_FF_RD, DDU_TX_FF_RD(0));
  FDC_DDU_TX_RD_EN2 : FDC port map(DDU_TX_FF_RD(2), SLOWCLK, C_DDU_TX_FF_RD, DDU_TX_FF_RD(1));
  FDC_DDU_TX_RD_EN3 : FDC port map(DDU_TX_FF_RD(3), SLOWCLK, C_DDU_TX_FF_RD, DDU_TX_FF_RD(2));
  C_DDU_TX_FF_RD   <= RST or DDU_TX_FF_RD(3);
  DDU_TX_FIFO_RDEN <= DDU_TX_FF_RD(2);

  OUT_DDU_TX_FF_READ <= DDU_TX_FIFO_DOUT when (STROBE = '1' and R_DDU_TX_FF_READ = '1') else (others => 'Z');


-- Read DDU_TX_FF_WRD_CNT
  OUT_DDU_TX_FF_WRD_CNT <= DDU_TX_FIFO_WRD_CNT when (STROBE = '1' and R_DDU_TX_FF_WRD_CNT = '1') else
                           (others => 'Z');


-- Write DDU_TX_FF_RST (Reset DDU_TX FIFO)
  PULSE_RESET_DDU_TX : PULSE_EDGE port map(DDU_TX_FIFO_RST, open, SLOWCLK, RST, 1, w_ddu_tx_ff_rst);

-- Read DDU_RX_FF_READ
  DDU_RX_FF_RD(0)  <= R_DDU_RX_FF_READ;
  FDC_DDU_RX_RD_EN1 : FDC port map(DDU_RX_FF_RD(1), STROBE, C_DDU_RX_FF_RD, DDU_RX_FF_RD(0));
  FDC_DDU_RX_RD_EN2 : FDC port map(DDU_RX_FF_RD(2), SLOWCLK, C_DDU_RX_FF_RD, DDU_RX_FF_RD(1));
  FDC_DDU_RX_RD_EN3 : FDC port map(DDU_RX_FF_RD(3), SLOWCLK, C_DDU_RX_FF_RD, DDU_RX_FF_RD(2));
  C_DDU_RX_FF_RD   <= RST or DDU_RX_FF_RD(3);
  DDU_RX_FIFO_RDEN <= DDU_RX_FF_RD(2);

  OUT_DDU_RX_FF_READ <= DDU_RX_FIFO_DOUT when (STROBE = '1' and R_DDU_RX_FF_READ = '1') else (others => 'Z');


-- Read DDU_RX_FF_WRD_CNT
  OUT_DDU_RX_FF_WRD_CNT <= DDU_RX_FIFO_WRD_CNT when (STROBE = '1' and R_DDU_RX_FF_WRD_CNT = '1') else
                           (others => 'Z');


-- Write DDU_RX_FF_RST (Reset DDU_RX FIFO)
  PULSE_RESET_DDU_RX : PULSE_EDGE port map(ddu_rx_fifo_rst, open, slowclk, rst, 1, w_ddu_rx_ff_rst);

-- Read OTMB_FF_READ
  OTMB_FF_RD(0)  <= R_OTMB_FF_READ;
  FDC_OTMB_RD_EN1 : FDC port map(OTMB_FF_RD(1), STROBE, C_OTMB_FF_RD, OTMB_FF_RD(0));
  FDC_OTMB_RD_EN2 : FDC port map(OTMB_FF_RD(2), SLOWCLK, C_OTMB_FF_RD, OTMB_FF_RD(1));
  FDC_OTMB_RD_EN3 : FDC port map(OTMB_FF_RD(3), SLOWCLK, C_OTMB_FF_RD, OTMB_FF_RD(2));
  C_OTMB_FF_RD   <= RST or OTMB_FF_RD(3);
  OTMB_FIFO_RDEN <= OTMB_FF_RD(2);

  OUT_OTMB_FF_READ <= OTMB_FIFO_DOUT(15 downto 0) when (STROBE = '1' and R_OTMB_FF_READ = '1') else (others => 'Z');


-- Read OTMB_FF_WRD_CNT
  OUT_OTMB_FF_WRD_CNT(15 downto 12) <= (others => '0');
  OUT_OTMB_FF_WRD_CNT(11 downto 0)  <= OTMB_FIFO_WRD_CNT when (STROBE = '1' and R_OTMB_FF_WRD_CNT = '1') else
                                       (others => 'Z');


-- Write OTMB_FF_RST (Reset OTMB FIFO)
  PULSE_RESET_OTMB : PULSE_EDGE port map(otmb_fifo_rst, open, clk40, rst, 1, w_otmb_ff_rst);

  otmb_fifo_reset <= otmb_fifo_rst or RST;

  OTMB_FIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 18,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => true)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      EMPTY       => otmb_fifo_empty,       -- Output empty
      ALMOSTEMPTY => open,                  -- Output almost empty 
      ALMOSTFULL  => open,                  -- Output almost full
      FULL        => otmb_fifo_full,        -- Output full
      WRCOUNT     => otmb_fifo_wr_cnt,      -- Output write count
      RDCOUNT     => otmb_fifo_rd_cnt,      -- Output read count
      WRERR       => open,                  -- Output write error
      RDERR       => open,                  -- Output read error
      RST         => otmb_fifo_reset,       -- Input reset
      WRCLK       => clk40,                 -- Input write clock
      WREN        => otmb_fifo_data_valid,  -- Input write enable
      DI          => otmb_fifo_data_in,     -- Input data
      RDCLK       => slowclk,               -- Input read clock
      RDEN        => otmb_fifo_rden,        -- Input read enable
      DO          => otmb_fifo_dout         -- Output data
      );

  OTMB_WRD_COUNT : FIFOWORDS
    generic map(12)
    port map(RST   => otmb_fifo_reset, WRCLK => clk40, WREN => otmb_fifo_data_valid, FULL => otmb_fifo_full,
             RDCLK => slowclk, RDEN => otmb_fifo_rden, COUNT => otmb_fifo_wrd_cnt);

-- Read ALCT_FF_READ
  ALCT_FF_RD(0)  <= R_ALCT_FF_READ;
  FDC_ALCT_RD_EN1 : FDC port map(ALCT_FF_RD(1), STROBE, C_ALCT_FF_RD, ALCT_FF_RD(0));
  FDC_ALCT_RD_EN2 : FDC port map(ALCT_FF_RD(2), SLOWCLK, C_ALCT_FF_RD, ALCT_FF_RD(1));
  FDC_ALCT_RD_EN3 : FDC port map(ALCT_FF_RD(3), SLOWCLK, C_ALCT_FF_RD, ALCT_FF_RD(2));
  C_ALCT_FF_RD   <= RST or ALCT_FF_RD(3);
  ALCT_FIFO_RDEN <= ALCT_FF_RD(2);

  OUT_ALCT_FF_READ <= ALCT_FIFO_DOUT(15 downto 0) when (STROBE = '1' and R_ALCT_FF_READ = '1') else (others => 'Z');

-- Read ALCT_FF_WRD_CNT
  OUT_ALCT_FF_WRD_CNT(15 downto 12) <= (others => '0');
  OUT_ALCT_FF_WRD_CNT(11 downto 0)  <= ALCT_FIFO_WRD_CNT when (STROBE = '1' and R_ALCT_FF_WRD_CNT = '1') else
                                       (others => 'Z');

-- Write ALCT_FF_RST (Reset ALCT FIFO)
  PULSE_RESET_ALCT : PULSE_EDGE port map(alct_fifo_rst, open, clk40, rst, 1, w_alct_ff_rst);
  alct_fifo_reset <= alct_fifo_rst or RST;

  ALCT_FIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 18,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => true)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      EMPTY       => alct_fifo_empty,       -- Output empty
      ALMOSTEMPTY => open,                  -- Output almost empty 
      ALMOSTFULL  => open,                  -- Output almost full
      FULL        => alct_fifo_full,        -- Output full
      WRCOUNT     => alct_fifo_wr_cnt,      -- Output write count
      RDCOUNT     => alct_fifo_rd_cnt,      -- Output read count
      WRERR       => open,                  -- Output write error
      RDERR       => open,                  -- Output read error
      RST         => alct_fifo_reset,       -- Input reset
      WRCLK       => clk40,                 -- Input write clock
      WREN        => alct_fifo_data_valid,  -- Input write enable
      DI          => alct_fifo_data_in,     -- Input data
      RDCLK       => slowclk,               -- Input read clock
      RDEN        => alct_fifo_rden,        -- Input read enable
      DO          => alct_fifo_dout         -- Output data
      );

  ALCT_WRD_COUNT : FIFOWORDS
    generic map(12)
    port map(RST   => alct_fifo_reset, WRCLK => clk40, WREN => alct_fifo_data_valid, FULL => alct_fifo_full,
             RDCLK => slowclk, RDEN => alct_fifo_rden, COUNT => alct_fifo_wrd_cnt);

-- Read HDR_FF_WRD_CNT
  OUT_HDR_FF_WRD_CNT(15 downto 12) <= (others => '0');
  OUT_HDR_FF_WRD_CNT(11 downto 0)  <= HDR_FIFO_WRD_CNT when (STROBE = '1' and R_HDR_FF_WRD_CNT = '1') else
                                      (others => 'Z');

-- Write HDR_FF_RST (Reset HDR FIFO)
  PULSE_RESET_HDR : PULSE_EDGE port map(hdr_fifo_rst, open, clk40, rst, 1, w_hdr_ff_rst);
  hdr_fifo_reset <= hdr_fifo_rst or RST;

  hdr_fifo_data_valid <= '1' when (DDU_DATA_VALID = '1' and
                                   (DDU_DATA(15 downto 12) = x"9" or DDU_DATA(15 downto 12) = x"A" or
                                    DDU_DATA(15 downto 12) = x"F" or DDU_DATA(15 downto 12) = x"E" or
                                    DDU_DATA(15 downto 12) = x"8")) else '0';

  HDR_FIFO_CASCADE : FIFO_CASCADE
    generic map (
      NFIFO        => 4,                -- number of FIFOs in cascade
      DATA_WIDTH   => 16,               -- With of data packets
      FWFT         => true,             -- First word fall through
      WR_FASTER_RD => true)  -- Set int_clk to WRCLK if faster than RDCLK

    port map(
      DO        => hdr_fifo_dout,       -- Output data
      EMPTY     => hdr_fifo_empty,      -- Output empty
      FULL      => hdr_fifo_full,       -- Output full
      HALF_FULL => open,
      EOF       => hdr_eof,             -- Output EOF
      BOF       => open,

      DI    => DDU_DATA,                -- Input data
      RDCLK => slowclk,                 -- Input read clock
      RDEN  => hdr_fifo_rden,           -- Input read enable
      RST   => hdr_fifo_rst,            -- Input reset
      WRCLK => DDUCLK,                  -- Input write clock
      WREN  => hdr_fifo_data_valid      -- Input write enable
      );

  HDR_WRD_COUNT : FIFOWORDS
    generic map(12)
    port map(RST   => hdr_fifo_reset, WRCLK => clk40, WREN => hdr_fifo_data_valid, FULL => hdr_fifo_full,
             RDCLK => slowclk, RDEN => hdr_fifo_rden, COUNT => hdr_fifo_wrd_cnt);

-- Read HDR_FF_READ
  HDR_FF_RD(0)  <= R_HDR_FF_READ;
  FDC_HDR_RD_EN1 : FDC port map(HDR_FF_RD(1), STROBE, C_HDR_FF_RD, HDR_FF_RD(0));
  FDC_HDR_RD_EN2 : FDC port map(HDR_FF_RD(2), SLOWCLK, C_HDR_FF_RD, HDR_FF_RD(1));
  FDC_HDR_RD_EN3 : FDC port map(HDR_FF_RD(3), SLOWCLK, C_HDR_FF_RD, HDR_FF_RD(2));
  C_HDR_FF_RD   <= RST or HDR_FF_RD(3);
  HDR_FIFO_RDEN <= HDR_FF_RD(2);

  OUT_HDR_FF_READ <= HDR_FIFO_DOUT(15 downto 0) when (STROBE = '1' and R_HDR_FF_READ = '1') else (others => hdr_eof);  -- EOF to avoid warning...

-- General assignments
  OUTDATA <= OUT_TFF_READ when R_TFF_READ = '1' else
             OUT_TFF_SEL           when R_TFF_SEL = '1' else
             OUT_TFF_WRD_CNT       when R_TFF_WRD_CNT = '1' else
             OUT_PC_TX_FF_READ     when R_PC_TX_FF_READ = '1' else
             OUT_PC_TX_FF_WRD_CNT  when R_PC_TX_FF_WRD_CNT = '1' else
             OUT_PC_RX_FF_READ     when R_PC_RX_FF_READ = '1' else
             OUT_PC_RX_FF_WRD_CNT  when R_PC_RX_FF_WRD_CNT = '1' else
             OUT_DDU_TX_FF_READ    when R_DDU_TX_FF_READ = '1' else
             OUT_DDU_TX_FF_WRD_CNT when R_DDU_TX_FF_WRD_CNT = '1' else
             OUT_DDU_RX_FF_READ    when R_DDU_RX_FF_READ = '1' else
             OUT_DDU_RX_FF_WRD_CNT when R_DDU_RX_FF_WRD_CNT = '1' else
             OUT_OTMB_FF_READ      when R_OTMB_FF_READ = '1' else
             OUT_OTMB_FF_WRD_CNT   when R_OTMB_FF_WRD_CNT = '1' else
             OUT_ALCT_FF_READ      when R_ALCT_FF_READ = '1' else
             OUT_ALCT_FF_WRD_CNT   when R_ALCT_FF_WRD_CNT = '1' else
             OUT_HDR_FF_READ       when R_HDR_FF_READ = '1' else
             OUT_HDR_FF_WRD_CNT    when R_HDR_FF_WRD_CNT = '1' else
             (others => 'L');

  -- DTACK
  dd_dtack <= STROBE and DEVICE;
  FD_D_DTACK : FDC port map(d_dtack, dd_dtack, q_dtack, '1');
  FD_Q_DTACK : FD port map(q_dtack, SLOWCLK, d_dtack);
  DTACK    <= q_dtack;
  
end TESTFIFOS_Arch;
