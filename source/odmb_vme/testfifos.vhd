-- TESTFIFOS: Test fifos read via VME for DCFEBs, ALCT, OTMB, DDU, PC

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
    CSP_LVMB_LA_CTRL : inout std_logic_vector(35 downto 0);

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

    -- PC FIFO signals
    pcclk               : in std_logic;
    pc_data_frame       : in std_logic_vector(15 downto 0);
    pc_data_frame_valid : in std_logic;
    pc_rx_data          : in std_logic_vector(15 downto 0);
    pc_rx_data_valid    : in std_logic;

    -- DDU_TX/RX Fifo signals
    dduclk            : in std_logic;
    ddu_data          : in std_logic_vector(15 downto 0);
    ddu_data_valid    : in std_logic;
    ddu_rx_data       : in std_logic_vector(15 downto 0);
    ddu_rx_data_valid : in std_logic;

    -- TFF (DCFEB test FIFOs)
    TFF_DOUT    : in  std_logic_vector(15 downto 0);
    TFF_WRD_CNT : in  std_logic_vector(11 downto 0);
    TFF_RST     : out std_logic_vector(NFEB downto 1);
    TFF_SEL     : out std_logic_vector(NFEB downto 1);
    TFF_RDEN    : out std_logic_vector(NFEB downto 1);
    TFF_MASK    : out std_logic_vector(NFEB downto 1)
    );
end TESTFIFOS;


architecture TESTFIFOS_Arch of TESTFIFOS is
  component csp_lvmb_la is
    port (
      CLK     : in    std_logic := 'X';
      DATA    : in    std_logic_vector (99 downto 0);
      TRIG0   : in    std_logic_vector (7 downto 0);
      CONTROL : inout std_logic_vector (35 downto 0)
      );
  end component;

  signal dd_dtack, d_dtack, q_dtack : std_logic;
  signal CMDDEV                     : std_logic_vector(15 downto 0);

  type FIFO_RD_TYPE is array (3 downto 0) of std_logic_vector(NFEB downto 1);
  signal FIFO_RD                   : FIFO_RD_TYPE;
  signal C_FIFO_RD, tff_mask_inner : std_logic_vector(NFEB downto 1) := (others => '0');
  signal OUT_TFF_READ              : std_logic_vector(15 downto 0)   := (others => '0');
  signal R_TFF_READ                : std_logic                       := '0';

  signal OUT_TFF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_TFF_WRD_CNT   : std_logic                     := '0';

  signal OUT_TFF_SEL   : std_logic_vector(15 downto 0)   := (others => '0');
  signal TFF_SEL_INNER : std_logic_vector(NFEB downto 1) := (others => '0');
  signal TFF_SEL_CODE  : std_logic_vector(2 downto 0)    := (others => '0');

  signal W_TFF_SEL, R_TFF_SEL : std_logic := '0';

  signal W_TFF_RST                 : std_logic                       := '0';
  signal PULSE_TFF_RST, IN_TFF_RST : std_logic_vector(NFEB downto 1) := (others => '0');

  -------------------------------- PC FIFOs ----------------------------------------
  signal PC_TX_FIFO_DOUT     : std_logic_vector(15 downto 0);
  signal PC_TX_FIFO_WRD_CNT  : std_logic_vector(15 downto 0);
  signal PC_TX_FIFO_RST      : std_logic;
  signal PC_TX_FIFO_RDEN     : std_logic;
  signal PC_RX_FIFO_DOUT     : std_logic_vector(15 downto 0);
  signal PC_RX_FIFO_WRD_CNT  : std_logic_vector(15 downto 0);
  signal PC_RX_FIFO_RST      : std_logic;
  signal PC_RX_FIFO_RDEN     : std_logic;
  signal DDU_TX_FIFO_DOUT    : std_logic_vector(15 downto 0);
  signal DDU_TX_FIFO_WRD_CNT : std_logic_vector(15 downto 0);
  signal DDU_TX_FIFO_RST     : std_logic;
  signal DDU_TX_FIFO_RDEN    : std_logic;
  signal DDU_RX_FIFO_DOUT    : std_logic_vector(15 downto 0);
  signal DDU_RX_FIFO_WRD_CNT : std_logic_vector(15 downto 0);
  signal DDU_RX_FIFO_RST     : std_logic;
  signal DDU_RX_FIFO_RDEN    : std_logic;

  signal pc_tx_fifo_empty, pc_tx_fifo_full   : std_logic;
  signal pc_rx_fifo_empty, pc_rx_fifo_full   : std_logic;
  signal ddu_tx_fifo_empty, ddu_tx_fifo_full : std_logic;
  signal ddu_rx_fifo_empty, ddu_rx_fifo_full : std_logic;

  signal pc_rx_fifo_rderr, pc_rx_fifo_wrerr   : std_logic := '0';
  signal ddu_rx_fifo_rderr, ddu_rx_fifo_wrerr   : std_logic := '0';

  signal pc_data_frame_wren, pc_rx_data_wren : std_logic;
  signal ddu_data_wren, ddu_rx_data_wren     : std_logic;

  signal pc_rx_fifo_rdcout, pc_rx_fifo_wrcout   : std_logic_vector(10 downto 0);
  signal ddu_rx_fifo_rdcout, ddu_rx_fifo_wrcout : std_logic_vector(10 downto 0);

  signal PC_TX_FF_RD                    : std_logic_vector(3 downto 0);
  signal OUT_PC_TX_FF_READ              : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PC_TX_FF_READ, C_PC_TX_FF_RD : std_logic                     := '0';

  signal OUT_PC_TX_FF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PC_TX_FF_WRD_CNT   : std_logic                     := '0';

  signal W_PC_TX_FF_RST, do_pc_tx_fifo_rst, pc_tx_mask : std_logic := '0';

  signal PC_RX_FF_RD                    : std_logic_vector(3 downto 0);
  signal OUT_PC_RX_FF_READ              : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PC_RX_FF_READ, C_PC_RX_FF_RD : std_logic                     := '0';

  signal OUT_PC_RX_FF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_PC_RX_FF_WRD_CNT   : std_logic                     := '0';

  signal W_PC_RX_FF_RST, do_pc_rx_fifo_rst, pc_rx_mask : std_logic := '0';

  signal DDU_TX_FF_RD                     : std_logic_vector(3 downto 0);
  signal OUT_DDU_TX_FF_READ               : std_logic_vector(15 downto 0) := (others => '0');
  signal R_DDU_TX_FF_READ, C_DDU_TX_FF_RD : std_logic                     := '0';

  signal OUT_DDU_TX_FF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_DDU_TX_FF_WRD_CNT   : std_logic                     := '0';

  signal W_DDU_TX_FF_RST, do_ddu_tx_fifo_rst, ddu_tx_mask : std_logic := '0';

  signal DDU_RX_FF_RD                     : std_logic_vector(3 downto 0);
  signal OUT_DDU_RX_FF_READ               : std_logic_vector(15 downto 0) := (others => '0');
  signal R_DDU_RX_FF_READ, C_DDU_RX_FF_RD : std_logic                     := '0';

  signal OUT_DDU_RX_FF_WRD_CNT                      : std_logic_vector(15 downto 0) := (others => '0');
  signal R_DDU_RX_FF_WRD_CNT, D_R_DDU_RX_FF_WRD_CNT : std_logic                     := '0';

  signal W_DDU_RX_FF_RST, do_ddu_rx_fifo_rst, ddu_rx_mask : std_logic := '0';

  -- OTMB FIFO
  signal OTMB_FF_RD                     : std_logic_vector(3 downto 0);
  signal OTMB_FIFO_DOUT                 : std_logic_vector(17 downto 0) := (others => '0');
  signal OUT_OTMB_FF_READ               : std_logic_vector(15 downto 0) := (others => '0');
  signal R_OTMB_FF_READ, C_OTMB_FF_RD   : std_logic                     := '0';
  signal OTMB_FIFO_RDEN, otmb_fifo_wren : std_logic                     := '0';

  signal OTMB_FIFO_WRD_CNT                      : std_logic_vector(11 downto 0) := (others => '0');
  signal OUT_OTMB_FF_WRD_CNT                    : std_logic_vector(15 downto 0) := (others => '0');
  signal R_OTMB_FF_WRD_CNT, D_R_OTMB_FF_WRD_CNT : std_logic                     := '0';

  signal W_OTMB_FF_RST : std_logic := '0';

  signal otmb_fifo_rd_cnt, otmb_fifo_wr_cnt             : std_logic_vector(10 downto 0);
  signal otmb_fifo_empty, otmb_fifo_full                : std_logic;
  signal otmb_fifo_rst, otmb_fifo_reset, otmb_fifo_mask : std_logic;

  -- ALCT FIFO
  signal ALCT_FF_RD                     : std_logic_vector(3 downto 0);
  signal ALCT_FIFO_DOUT                 : std_logic_vector(17 downto 0) := (others => '0');
  signal OUT_ALCT_FF_READ               : std_logic_vector(15 downto 0) := (others => '0');
  signal R_ALCT_FF_READ, C_ALCT_FF_RD   : std_logic                     := '0';
  signal ALCT_FIFO_RDEN, alct_fifo_wren : std_logic                     := '0';

  signal ALCT_FIFO_WRD_CNT   : std_logic_vector(11 downto 0) := (others => '0');
  signal OUT_ALCT_FF_WRD_CNT : std_logic_vector(15 downto 0) := (others => '0');
  signal R_ALCT_FF_WRD_CNT   : std_logic                     := '0';

  signal W_ALCT_FF_RST : std_logic := '0';

  signal alct_fifo_rd_cnt, alct_fifo_wr_cnt             : std_logic_vector(10 downto 0);
  signal alct_fifo_empty, alct_fifo_full                : std_logic;
  signal alct_fifo_rst, alct_fifo_reset, alct_fifo_mask : std_logic;

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

  signal hdr_fifo_empty, hdr_fifo_full               : std_logic;
  signal hdr_fifo_rst, hdr_fifo_reset, hdr_fifo_mask : std_logic;

  signal csp_lvmb_la_trig : std_logic_vector (7 downto 0);
  signal csp_lvmb_la_data : std_logic_vector (99 downto 0);
  
  
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
  r_ddu_rx_ff_wrd_cnt <= '1' when (cmddev = x"140c") else '0';
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
    TFF_RDEN(I)   <= FIFO_RD(2)(I) and tff_mask_inner(I);
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
  GEN_TFF_RST : for cfeb in NFEB downto 1 generate
  begin
    in_tff_rst(cfeb) <= (STROBE and w_tff_rst and INDATA(cfeb-1)) or RST;
    PULSE_RESET : RESET_FIFO port map(TFF_RST(cfeb), tff_mask_inner(cfeb), CLK40, in_tff_rst(cfeb));
  end generate GEN_TFF_RST;

  TFF_MASK <= tff_mask_inner;

-- Read PC_TX_FF_READ
  PC_TX_FF_RD(0)  <= R_PC_TX_FF_READ;
  FDC_PC_TX_RD_EN1 : FDC port map(PC_TX_FF_RD(1), STROBE, C_PC_TX_FF_RD, PC_TX_FF_RD(0));
  FDC_PC_TX_RD_EN2 : FDC port map(PC_TX_FF_RD(2), SLOWCLK, C_PC_TX_FF_RD, PC_TX_FF_RD(1));
  FDC_PC_TX_RD_EN3 : FDC port map(PC_TX_FF_RD(3), SLOWCLK, C_PC_TX_FF_RD, PC_TX_FF_RD(2));
  C_PC_TX_FF_RD   <= RST or PC_TX_FF_RD(3);
  PC_TX_FIFO_RDEN <= PC_TX_FF_RD(2) and pc_tx_mask;

  OUT_PC_TX_FF_READ <= PC_TX_FIFO_DOUT when (STROBE = '1' and R_PC_TX_FF_READ = '1') else (others => 'Z');

-- Read PC_TX_FF_WRD_CNT
  OUT_PC_TX_FF_WRD_CNT <= PC_TX_FIFO_WRD_CNT when (STROBE = '1' and R_PC_TX_FF_WRD_CNT = '1') else
                          (others => 'Z');

-- Write PC_TX_FF_RST (Reset PC_TX FIFO)
  do_pc_tx_fifo_rst <= w_pc_tx_ff_rst or RST;
  PULSE_RESET_PC_TX : RESET_FIFO port map(PC_TX_FIFO_RST, pc_tx_mask, CLK40, do_pc_tx_fifo_rst);

-- Read PC_RX_FF_READ
  PC_RX_FF_RD(0)  <= R_PC_RX_FF_READ;
  FDC_PC_RX_RD_EN1 : FDC port map(PC_RX_FF_RD(1), STROBE, C_PC_RX_FF_RD, PC_RX_FF_RD(0));
  FDC_PC_RX_RD_EN2 : FDC port map(PC_RX_FF_RD(2), SLOWCLK, C_PC_RX_FF_RD, PC_RX_FF_RD(1));
  FDC_PC_RX_RD_EN3 : FDC port map(PC_RX_FF_RD(3), SLOWCLK, C_PC_RX_FF_RD, PC_RX_FF_RD(2));
  C_PC_RX_FF_RD   <= RST or PC_RX_FF_RD(3);
  PC_RX_FIFO_RDEN <= PC_RX_FF_RD(2) and pc_rx_mask;

  OUT_PC_RX_FF_READ <= PC_RX_FIFO_DOUT when (STROBE = '1' and R_PC_RX_FF_READ = '1') else (others => 'Z');

-- Read PC_RX_FF_WRD_CNT
  OUT_PC_RX_FF_WRD_CNT <= PC_RX_FIFO_WRD_CNT when (STROBE = '1' and R_PC_RX_FF_WRD_CNT = '1') else
                          (others => 'Z');

-- Write PC_RX_FF_RST (Reset PC_RX FIFO)
  do_pc_rx_fifo_rst <= w_pc_rx_ff_rst or RST;
  PULSE_RESET_PC_RX : RESET_FIFO port map(pc_rx_fifo_rst, pc_rx_mask, CLK40, do_pc_rx_fifo_rst);

  ----------------------------------------------------------------------------------
  -------------------------------- PC FIFOs ----------------------------------------
  ----------------------------------------------------------------------------------

  pc_data_frame_wren <= pc_tx_mask and pc_data_frame_valid;

  PC_TX_FIFO_CASCADE : FIFO_CASCADE
    generic map (
      NFIFO        => 4,                -- number of FIFOs in cascade
      DATA_WIDTH   => 16,               -- With of data packets
      FWFT         => true,             -- First word fall through
      WR_FASTER_RD => true)  -- Set int_clk to WRCLK if faster than RDCLK

    port map(
      DO        => pc_tx_fifo_dout,     -- Output data
      EMPTY     => pc_tx_fifo_empty,    -- Output empty
      FULL      => pc_tx_fifo_full,     -- Output full
      HALF_FULL => open,

      DI    => pc_data_frame,           -- Input data
      RDCLK => SLOWCLK,                 -- Input read clock
      RDEN  => pc_tx_fifo_rden,         -- Input read enable
      RST   => pc_tx_fifo_rst,          -- Input reset
      WRCLK => pcclk,                   -- Input write clock
      WREN  => pc_data_frame_wren       -- Input write enable
      );

  PC_TX_WRD_COUNT : FIFOWORDS
    port map(RST   => pc_tx_fifo_rst, WRCLK => pcclk, WREN => pc_data_frame_wren,
             FULL  => pc_tx_fifo_full, RDCLK => SLOWCLK, RDEN => pc_tx_fifo_rden,
             COUNT => pc_tx_fifo_wrd_cnt);


  pc_rx_data_wren <= pc_rx_mask and pc_rx_data_valid;

  PC_RX_FIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 16,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => true)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      RST         => pc_rx_fifo_rst,     -- Input reset
      ALMOSTEMPTY => open,               -- Output almost empty 
      ALMOSTFULL  => open,               -- Output almost full
      EMPTY       => pc_rx_fifo_empty,   -- Output empty
      FULL        => pc_rx_fifo_full,    -- Output full
      RDCOUNT     => pc_rx_fifo_rdcout,  -- Output read count
      RDERR       => pc_rx_fifo_rderr,   -- Output read error
      WRCOUNT     => pc_rx_fifo_wrcout,  -- Output write count
      WRERR       => pc_rx_fifo_wrerr,   -- Output write error
      DO          => pc_rx_fifo_dout,    -- Output data
      RDCLK       => SLOWCLK,            -- Input read clock
      RDEN        => pc_rx_fifo_rden,    -- Input read enable
      DI          => pc_rx_data,         -- Input data
      WRCLK       => pcclk,              -- Input write clock
      WREN        => pc_rx_data_wren     -- Input write enable
      );

  PC_RX_WRD_COUNT : FIFOWORDS
    port map(RST   => pc_rx_fifo_rst, WRCLK => pcclk, WREN => pc_rx_data_wren,
             FULL  => pc_rx_fifo_full, RDCLK => SLOWCLK, RDEN => pc_rx_fifo_rden,
             COUNT => pc_rx_fifo_wrd_cnt);


  ----------------------------------------------------------------------------------
  ------------------------------- DDU FIFOs ----------------------------------------
  ----------------------------------------------------------------------------------

  ddu_data_wren <= ddu_tx_mask and ddu_data_valid;

  DDU_TX_FIFO_CASCADE : FIFO_CASCADE
    generic map (
      NFIFO        => 4,                -- number of FIFOs in cascade
      DATA_WIDTH   => 16,               -- With of data packets
      FWFT         => true,             -- First word fall through
      WR_FASTER_RD => true)  -- Set int_clk to WRCLK if faster than RDCLK

    port map(
      DO        => ddu_tx_fifo_dout,    -- Output data
      EMPTY     => ddu_tx_fifo_empty,   -- Output empty
      FULL      => ddu_tx_fifo_full,    -- Output full
      HALF_FULL => open,

      DI    => ddu_data,                -- Input data
      RDCLK => SLOWCLK,                 -- Input read clock
      RDEN  => ddu_tx_fifo_rden,        -- Input read enable
      RST   => ddu_tx_fifo_rst,         -- Input reset
      WRCLK => dduclk,                  -- Input write clock
      WREN  => ddu_data_wren            -- Input write enable
      );

  DDU_TX_WRD_COUNT : FIFOWORDS
    port map(RST   => ddu_tx_fifo_rst, WRCLK => dduclk, WREN => ddu_data_wren,
             FULL  => ddu_tx_fifo_full, RDCLK => SLOWCLK, RDEN => ddu_tx_fifo_rden,
             COUNT => ddu_tx_fifo_wrd_cnt);


  ddu_rx_data_wren <= ddu_rx_mask and ddu_rx_data_valid;

  DDU_RX_FIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 16,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => true)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      RST         => ddu_rx_fifo_rst,     -- Input reset
      ALMOSTEMPTY => open,                -- Output almost empty 
      ALMOSTFULL  => open,                -- Output almost full
      EMPTY       => ddu_rx_fifo_empty,   -- Output empty
      FULL        => ddu_rx_fifo_full,    -- Output full
      RDCOUNT     => ddu_rx_fifo_rdcout,  -- Output read count
      RDERR       => ddu_rx_fifo_rderr,   -- Output read error
      WRCOUNT     => ddu_rx_fifo_wrcout,  -- Output write count
      WRERR       => ddu_rx_fifo_wrerr,   -- Output write error
      DO          => ddu_rx_fifo_dout,    -- Output data
      RDCLK       => SLOWCLK,             -- Input read clock
      RDEN        => ddu_rx_fifo_rden,    -- Input read enable
      DI          => ddu_rx_data,         -- Input data
      WRCLK       => dduclk,              -- Input write clock
      WREN        => ddu_rx_data_wren     -- Input write enable
      );

  DDU_RX_WRD_COUNT : FIFOWORDS
    port map(RST   => ddu_rx_fifo_rst, WRCLK => dduclk, WREN => ddu_rx_data_wren,
             FULL  => ddu_rx_fifo_full, RDCLK => SLOWCLK, RDEN => ddu_rx_fifo_rden,
             COUNT => ddu_rx_fifo_wrd_cnt);


-- Read DDU_TX_FF_READ
  DDU_TX_FF_RD(0)  <= R_DDU_TX_FF_READ;
  FDC_DDU_TX_RD_EN1 : FDC port map(DDU_TX_FF_RD(1), STROBE, C_DDU_TX_FF_RD, DDU_TX_FF_RD(0));
  FDC_DDU_TX_RD_EN2 : FDC port map(DDU_TX_FF_RD(2), SLOWCLK, C_DDU_TX_FF_RD, DDU_TX_FF_RD(1));
  FDC_DDU_TX_RD_EN3 : FDC port map(DDU_TX_FF_RD(3), SLOWCLK, C_DDU_TX_FF_RD, DDU_TX_FF_RD(2));
  C_DDU_TX_FF_RD   <= RST or DDU_TX_FF_RD(3);
  DDU_TX_FIFO_RDEN <= DDU_TX_FF_RD(2) and ddu_tx_mask;

  OUT_DDU_TX_FF_READ <= DDU_TX_FIFO_DOUT when (STROBE = '1' and R_DDU_TX_FF_READ = '1') else (others => 'Z');


-- Read DDU_TX_FF_WRD_CNT
  OUT_DDU_TX_FF_WRD_CNT <= DDU_TX_FIFO_WRD_CNT when (STROBE = '1' and R_DDU_TX_FF_WRD_CNT = '1') else
                           (others => 'Z');


-- Write DDU_TX_FF_RST (Reset DDU_TX FIFO)
  do_ddu_tx_fifo_rst <= w_ddu_tx_ff_rst or RST;
  PULSE_RESET_DDU_TX : RESET_FIFO port map(DDU_TX_FIFO_RST, ddu_tx_mask, CLK40, do_ddu_tx_fifo_rst);

-- Read DDU_RX_FF_READ
  DDU_RX_FF_RD(0)  <= R_DDU_RX_FF_READ;
  FDC_DDU_RX_RD_EN1 : FDC port map(DDU_RX_FF_RD(1), STROBE, C_DDU_RX_FF_RD, DDU_RX_FF_RD(0));
  FDC_DDU_RX_RD_EN2 : FDC port map(DDU_RX_FF_RD(2), SLOWCLK, C_DDU_RX_FF_RD, DDU_RX_FF_RD(1));
  FDC_DDU_RX_RD_EN3 : FDC port map(DDU_RX_FF_RD(3), SLOWCLK, C_DDU_RX_FF_RD, DDU_RX_FF_RD(2));
  C_DDU_RX_FF_RD   <= RST or DDU_RX_FF_RD(3);
  DDU_RX_FIFO_RDEN <= DDU_RX_FF_RD(2) and ddu_rx_mask;

  OUT_DDU_RX_FF_READ <= DDU_RX_FIFO_DOUT when (STROBE = '1' and R_DDU_RX_FF_READ = '1') else (others => 'Z');


-- Read DDU_RX_FF_WRD_CNT
  OUT_DDU_RX_FF_WRD_CNT <= DDU_RX_FIFO_WRD_CNT when (STROBE = '1' and R_DDU_RX_FF_WRD_CNT = '1') else
                           (others => 'Z');


-- Write DDU_RX_FF_RST (Reset DDU_RX FIFO)
  do_ddu_rx_fifo_rst <= w_ddu_rx_ff_rst or RST;
  PULSE_RESET_DDU_RX : RESET_FIFO port map(ddu_rx_fifo_rst, ddu_rx_mask, clk40, do_ddu_rx_fifo_rst);

-- Read OTMB_FF_READ
  OTMB_FF_RD(0)  <= R_OTMB_FF_READ;
  FDC_OTMB_RD_EN1 : FDC port map(OTMB_FF_RD(1), STROBE, C_OTMB_FF_RD, OTMB_FF_RD(0));
  FDC_OTMB_RD_EN2 : FDC port map(OTMB_FF_RD(2), SLOWCLK, C_OTMB_FF_RD, OTMB_FF_RD(1));
  FDC_OTMB_RD_EN3 : FDC port map(OTMB_FF_RD(3), SLOWCLK, C_OTMB_FF_RD, OTMB_FF_RD(2));
  C_OTMB_FF_RD   <= RST or OTMB_FF_RD(3);
  OTMB_FIFO_RDEN <= OTMB_FF_RD(2) and otmb_fifo_mask;

  OUT_OTMB_FF_READ <= OTMB_FIFO_DOUT(15 downto 0) when (STROBE = '1' and R_OTMB_FF_READ = '1') else (others => 'Z');


-- Read OTMB_FF_WRD_CNT
  OUT_OTMB_FF_WRD_CNT(15 downto 12) <= (others => '0');
  OUT_OTMB_FF_WRD_CNT(11 downto 0)  <= OTMB_FIFO_WRD_CNT when (STROBE = '1' and R_OTMB_FF_WRD_CNT = '1') else
                                       (others => 'Z');


-- Write OTMB_FF_RST (Reset OTMB FIFO)
  otmb_fifo_rst <= w_otmb_ff_rst or RST;
  PULSE_RESET_OTMB : RESET_FIFO port map(otmb_fifo_reset, otmb_fifo_mask, clk40, otmb_fifo_rst);

  otmb_fifo_wren <= otmb_fifo_data_valid and otmb_fifo_mask;

  OTMB_FIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 18,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => true)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      EMPTY       => otmb_fifo_empty,    -- Output empty
      ALMOSTEMPTY => open,               -- Output almost empty 
      ALMOSTFULL  => open,               -- Output almost full
      FULL        => otmb_fifo_full,     -- Output full
      WRCOUNT     => otmb_fifo_wr_cnt,   -- Output write count
      RDCOUNT     => otmb_fifo_rd_cnt,   -- Output read count
      WRERR       => open,               -- Output write error
      RDERR       => open,               -- Output read error
      RST         => otmb_fifo_reset,    -- Input reset
      WRCLK       => clk40,              -- Input write clock
      WREN        => otmb_fifo_wren,     -- Input write enable
      DI          => otmb_fifo_data_in,  -- Input data
      RDCLK       => slowclk,            -- Input read clock
      RDEN        => otmb_fifo_rden,     -- Input read enable
      DO          => otmb_fifo_dout      -- Output data
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
  ALCT_FIFO_RDEN <= ALCT_FF_RD(2) and alct_fifo_mask;

  OUT_ALCT_FF_READ <= ALCT_FIFO_DOUT(15 downto 0) when (STROBE = '1' and R_ALCT_FF_READ = '1') else (others => 'Z');

-- Read ALCT_FF_WRD_CNT
  OUT_ALCT_FF_WRD_CNT(15 downto 12) <= (others => '0');
  OUT_ALCT_FF_WRD_CNT(11 downto 0)  <= ALCT_FIFO_WRD_CNT when (STROBE = '1' and R_ALCT_FF_WRD_CNT = '1') else
                                       (others => 'Z');

-- Write ALCT_FF_RST (Reset ALCT FIFO)
  alct_fifo_rst <= w_alct_ff_rst or RST;
  PULSE_RESET_ALCT : RESET_FIFO port map(alct_fifo_reset, alct_fifo_mask, clk40, alct_fifo_rst);

  alct_fifo_wren <= alct_fifo_data_valid and alct_fifo_mask;

  ALCT_FIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 18,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => true)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      EMPTY       => alct_fifo_empty,    -- Output empty
      ALMOSTEMPTY => open,               -- Output almost empty 
      ALMOSTFULL  => open,               -- Output almost full
      FULL        => alct_fifo_full,     -- Output full
      WRCOUNT     => alct_fifo_wr_cnt,   -- Output write count
      RDCOUNT     => alct_fifo_rd_cnt,   -- Output read count
      WRERR       => open,               -- Output write error
      RDERR       => open,               -- Output read error
      RST         => alct_fifo_reset,    -- Input reset
      WRCLK       => clk40,              -- Input write clock
      WREN        => alct_fifo_wren,     -- Input write enable
      DI          => alct_fifo_data_in,  -- Input data
      RDCLK       => slowclk,            -- Input read clock
      RDEN        => alct_fifo_rden,     -- Input read enable
      DO          => alct_fifo_dout      -- Output data
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
  hdr_fifo_rst <= w_hdr_ff_rst or RST;
  PULSE_RESET_HDR : RESET_FIFO port map(hdr_fifo_reset, hdr_fifo_mask, clk40, hdr_fifo_rst);

  hdr_fifo_data_valid <= '1' when (DDU_DATA_VALID = '1' and hdr_fifo_mask = '1' and
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

      DI    => DDU_DATA,                -- Input data
      RDCLK => slowclk,                 -- Input read clock
      RDEN  => hdr_fifo_rden,           -- Input read enable
      RST   => hdr_fifo_reset,          -- Input reset
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
  HDR_FIFO_RDEN <= HDR_FF_RD(2) and hdr_fifo_mask;

  OUT_HDR_FF_READ <= HDR_FIFO_DOUT(15 downto 0) when (STROBE = '1' and R_HDR_FF_READ = '1') else (others => '1');

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

  --csp_lvmb_la_pm : csp_lvmb_la
  --  port map (
  --    CONTROL => CSP_LVMB_LA_CTRL,
  --    CLK     => DDUCLK,
  --    DATA    => csp_lvmb_la_data,
  --    TRIG0   => csp_lvmb_la_trig
  --    );

  --csp_lvmb_la_trig <= R_HDR_FF_READ & hdr_fifo_data_valid & DDU_DATA_VALID
  --                    & hdr_fifo_rden & DDU_DATA(15 downto 12);
  --csp_lvmb_la_data <= x"0000000" & "0"
  --                    & R_HDR_FF_WRD_CNT & R_HDR_FF_READ  -- (71:69)
  --                    & STROBE & q_dtack & WRITER         -- (68:66)
  --                    & cmddev          -- (65:50)
  --                    & HDR_FIFO_WRD_CNT                  -- (49:38)
  --                    & hdr_fifo_rst & hdr_fifo_dout      -- (37:21)
  --                    & hdr_fifo_empty & hdr_fifo_full & hdr_fifo_rden  -- (20:18)
  --                    & DDU_DATA & DDU_DATA_VALID & hdr_fifo_data_valid;  -- (17:0)
end TESTFIFOS_Arch;
