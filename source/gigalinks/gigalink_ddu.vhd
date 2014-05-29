-- GIGALINK_DDU: Optical transmitter and receiver to/from the DDU (OT1, GL0)

library ieee;
library work;
library unisim;
library unimacro;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ucsb_types.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;

entity GIGALINK_DDU is
  generic (
    SIM_SPEEDUP : integer := 0
    );
  port (
    -- Global signals
    REF_CLK_80 : in std_logic;          -- 80 MHz for DDU data rate
    RST        : in std_logic;
    USRCLK  : out std_logic;            -- Data clock coming from the TX PLL

    -- Transmitter signals
    TXD        : in  std_logic_vector(15 downto 0);  -- Data to be transmitted
    TXD_VLD    : in  std_logic;         -- Flag for valid data;
    TX_DDU_N   : out std_logic;         -- GTX transmit data out - signal
    TX_DDU_P   : out std_logic;         -- GTX transmit data out + signal
    TXDIFFCTRL : in  std_logic_vector(3 downto 0);  -- Controls the TX voltage swing
    LOOPBACK   : in  std_logic_vector(2 downto 0);  -- For internal loopback tests

    -- Receiver signals
    RX_DDU_N : in  std_logic;           -- GTX receive data in - signal
    RX_DDU_P : in  std_logic;           -- GTX receive data in + signal
    RXD      : out std_logic_vector(15 downto 0);  -- Data received
    RXD_VLD  : out std_logic;           -- Flag for valid data;

    -- FIFO signals
    VME_CLK         : in  std_logic;
    TX_FIFO_RST     : in  std_logic;
    TX_FIFO_RDEN    : in  std_logic;
    TX_FIFO_DOUT    : out std_logic_vector(15 downto 0);
    TX_FIFO_WRD_CNT : out std_logic_vector(15 downto 0);
    RX_FIFO_RST     : in  std_logic;
    RX_FIFO_RDEN    : in  std_logic;
    RX_FIFO_DOUT    : out std_logic_vector(15 downto 0);
    RX_FIFO_WRD_CNT : out std_logic_vector(15 downto 0);

    -- PRBS signals
    PRBS_TYPE       : in  std_logic_vector(2 downto 0);
    PRBS_TX_EN      : in  std_logic;
    PRBS_RX_EN      : in  std_logic;
    PRBS_EN_TST_CNT : in  std_logic_vector(15 downto 0);
    PRBS_ERR_CNT    : out std_logic_vector(15 downto 0)
    );
end GIGALINK_DDU;

architecture GIGALINK_DDU_ARCH of GIGALINK_DDU is

  component WRAPPER_GIGALINK_DDU is
    generic (
      WRAPPER_SIM_GTXRESET_SPEEDUP : integer := 0  -- Set to 1 to speed up sim reset
      );
    port (
      --_________________________________________________________________________
      --_________________________________________________________________________
      --GTX0  (X0Y4)

      ------------------------ Loopback and Powerdown Ports ----------------------
      GTX0_LOOPBACK_IN       : in  std_logic_vector(2 downto 0);
      ----------------------- Receive Ports - 8b10b Decoder ----------------------
      GTX0_RXDISPERR_OUT     : out std_logic_vector(1 downto 0);
      GTX0_RXNOTINTABLE_OUT  : out std_logic_vector(1 downto 0);
      ------------------- Receive Ports - RX Data Path interface -----------------
      GTX0_RXDATA_OUT        : out std_logic_vector(15 downto 0);
      GTX0_RXVALID_OUT       : out std_logic;
      GTX0_RXCHARISK_OUT     : out std_logic_vector(3 downto 0);
      GTX0_RXBYTEREALIGN_OUT : out std_logic;
      GTX0_RXUSRCLK2_IN      : in  std_logic;
      ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
      GTX0_RXEQMIX_IN        : in  std_logic_vector(2 downto 0);
      GTX0_RXN_IN            : in  std_logic;
      GTX0_RXP_IN            : in  std_logic;
      ------------------------ Receive Ports - RX PLL Ports ----------------------
      GTX0_GTXRXRESET_IN     : in  std_logic;
      GTX0_MGTREFCLKRX_IN    : in  std_logic;
      GTX0_PLLRXRESET_IN     : in  std_logic;
      GTX0_RXPLLLKDET_OUT    : out std_logic;
      GTX0_RXRESETDONE_OUT   : out std_logic;
      ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
      GTX0_TXCHARISK_IN      : in  std_logic_vector(1 downto 0);
      ------------------------- Transmit Ports - GTX Ports -----------------------
      GTX0_GTXTEST_IN        : in  std_logic_vector(12 downto 0);
      ------------------ Transmit Ports - TX Data Path interface -----------------
      GTX0_TXDATA_IN         : in  std_logic_vector(15 downto 0);
      GTX0_TXRESET_IN        : in  std_logic;
      GTX0_TXOUTCLK_OUT      : out std_logic;
      GTX0_TXUSRCLK2_IN      : in  std_logic;
      ---------------- Transmit Ports - TX Driver and OOB signaling --------------
      GTX0_TXDIFFCTRL_IN     : in  std_logic_vector(3 downto 0);
      GTX0_TXN_OUT           : out std_logic;
      GTX0_TXP_OUT           : out std_logic;
      GTX0_TXPOSTEMPHASIS_IN : in  std_logic_vector(4 downto 0);
      --------------- Transmit Ports - TX Driver and OOB signalling --------------
      GTX0_TXPREEMPHASIS_IN  : in  std_logic_vector(3 downto 0);
      ----------------------- Transmit Ports - TX PLL Ports ----------------------
      GTX0_GTXTXRESET_IN     : in  std_logic;
      GTX0_MGTREFCLKTX_IN    : in  std_logic;
      GTX0_PLLTXRESET_IN     : in  std_logic;
      GTX0_TXPLLLKDET_OUT    : out std_logic;
      GTX0_TXRESETDONE_OUT   : out std_logic;
      -- PRBS Ports --------------------------------------------------------------
      GTX0_PRBSCNTRESET_IN   : in  std_logic;
      GTX0_ENTXPRBSTST_IN    : in  std_logic_vector(2 downto 0);
      GTX0_ENRXPRBSTST_IN    : in  std_logic_vector(2 downto 0);
      -- DRP Ports ---------------------------------------------------------------
      GTX0_DCLK_IN           : in  std_logic;
      GTX0_DEN_IN            : in  std_logic;
      GTX0_DRPDO_OUT         : out std_logic_vector(15 downto 0)
      );
  end component;

  component DOUBLE_RESET
    port (
      CLK          : in  std_logic;
      PLLLKDET     : in  std_logic;
      GTXTEST_DONE : out std_logic;
      GTXTEST_BIT1 : out std_logic
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

  constant IDLE        : std_logic_vector(15 downto 0) := x"50BC";
  signal tx_ddu_data   : std_logic_vector(15 downto 0) := (others => '0');
  signal tx_ddu_k      : std_logic_vector(1 downto 0)  := (others => '0');
  signal usr_clk       : std_logic                     := '0';
  signal rxd_inner     : std_logic_vector(15 downto 0) := (others => '0');
  signal rxd_vld_inner : std_logic                     := '0';

  -- wrapper_gigalink_ddu inputs
  signal gtxtest_in            : std_logic_vector(12 downto 0) := "1000000000000";
  signal gtx0_gtxtest_done     : std_logic;
  signal gtx0_gtxtest_bit1     : std_logic;
  signal gtx0_txreset_in       : std_logic;
  signal gtx0_txpreemphasis_in : std_logic_vector(3 downto 0)  := "1000";

  -- wrapper_gigalink_ddu outputs
  signal gtx0_txplllkdet_out    : std_logic;
  signal gtx0_rxvalid_out       : std_logic;
  signal gtx0_rxcharisk_out     : std_logic_vector(3 downto 0);
  signal gtx0_rxbyterealign_out : std_logic;
  signal rxbyterealign_pulse    : std_logic := '0';

  -- FIFO signals
  signal tx_fifo_empty, tx_fifo_full    : std_logic := '0';
  signal rx_fifo_empty, rx_fifo_full    : std_logic := '0';
  signal rx_fifo_rderr, rx_fifo_wrerr   : std_logic := '0';
  signal rx_fifo_rdcout, rx_fifo_wrcout : std_logic_vector(10 downto 0);

  -- PRBS signals
  signal gtx0_entxprbstst_in : std_logic_vector(2 downto 0);
  signal gtx0_enrxprbstst_in : std_logic_vector(2 downto 0);
  signal prbs_err_cnt_rst    : std_logic;
  signal prbs_en_pulse       : std_logic;
  signal prbs_rd_en_pulse    : std_logic;
  signal prbs_init_pulse     : std_logic;
  signal prbs_reset_pulse    : std_logic;
  signal prbs_rd_en_inner    : std_logic;
  constant prbs_rst_cycles   : integer := 1;
  constant prbs_length       : integer := 10001;
  signal prbs_en_cnt         : integer;
  signal prbs_rst_cnt        : integer;
  signal prbs_rd_en_cnt      : integer;
begin

  BUFG_USR : BUFG port map(O => usr_clk, I => ref_clk_80);
  USRCLK <= usr_clk;

  -- RX data valid is high when the RX is valid and we are not receiving a K character
  -- The pulse avoids some false positives during resets
  PULSE_ALIGN : NPULSE2SAME port map(rxbyterealign_pulse, usr_clk, RST, 10000, gtx0_rxbyterealign_out);
  rxd_vld_inner <= '1' when (gtx0_rxvalid_out = '1' and gtx0_rxcharisk_out = x"0" and
                             rxbyterealign_pulse = '0') else '0';
  tx_ddu_data <= TXD  when TXD_VLD = '1' else IDLE;
  tx_ddu_k    <= "00" when TXD_VLD = '1' else "01";
  RXD         <= rxd_inner;
  RXD_VLD     <= rxd_vld_inner;

  gtxtest_in      <= "10000000000" & gtx0_gtxtest_bit1 & '0';
  gtx0_txreset_in <= gtx0_gtxtest_done or RST;


  WRAPPER_GIGALINK_DDU_PM : WRAPPER_GIGALINK_DDU
    generic map (
      WRAPPER_SIM_GTXRESET_SPEEDUP => SIM_SPEEDUP  -- Set to 1 to speed up sim reset
      )
    port map (
      --_________________________________________________________________________
      --_________________________________________________________________________
      --GTX0  (X0Y4)

      ------------------------ Loopback and Powerdown Ports ----------------------
      GTX0_LOOPBACK_IN       => LOOPBACK,
      ----------------------- Receive Ports - 8b10b Decoder ----------------------
      GTX0_RXDISPERR_OUT     => open,
      GTX0_RXNOTINTABLE_OUT  => open,
      ------------------- Receive Ports - RX Data Path interface -----------------
      GTX0_RXDATA_OUT        => rxd_inner,
      GTX0_RXVALID_OUT       => gtx0_rxvalid_out,
      GTX0_RXCHARISK_OUT     => gtx0_rxcharisk_out,
      GTX0_RXBYTEREALIGN_OUT => gtx0_rxbyterealign_out,
      GTX0_RXUSRCLK2_IN      => usr_clk,
      ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
      GTX0_RXEQMIX_IN        => "111",
      GTX0_RXN_IN            => RX_DDU_N,
      GTX0_RXP_IN            => RX_DDU_P,
      ------------------------ Receive Ports - RX PLL Ports ----------------------
      GTX0_GTXRXRESET_IN     => RST,
      GTX0_MGTREFCLKRX_IN    => REF_CLK_80,
      GTX0_PLLRXRESET_IN     => RST,
      GTX0_RXPLLLKDET_OUT    => open,
      GTX0_RXRESETDONE_OUT   => open,
      ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
      GTX0_TXCHARISK_IN      => tx_ddu_k,
      ------------------------- Transmit Ports - GTX Ports -----------------------
      GTX0_GTXTEST_IN        => gtxtest_in,
      ------------------ Transmit Ports - TX Data Path interface -----------------
      GTX0_TXDATA_IN         => tx_ddu_data,
      GTX0_TXRESET_IN        => gtx0_txreset_in,
      GTX0_TXOUTCLK_OUT      => open,
      GTX0_TXUSRCLK2_IN      => usr_clk,
      ---------------- Transmit Ports - TX Driver and OOB signaling --------------
      GTX0_TXDIFFCTRL_IN     => TXDIFFCTRL,
      GTX0_TXN_OUT           => TX_DDU_N,
      GTX0_TXP_OUT           => TX_DDU_P,
      GTX0_TXPOSTEMPHASIS_IN => "00000",
      --------------- Transmit Ports - TX Driver and OOB signalling --------------
      GTX0_TXPREEMPHASIS_IN  => gtx0_txpreemphasis_in,
      ----------------------- Transmit Ports - TX PLL Ports ----------------------
      GTX0_GTXTXRESET_IN     => RST,
      GTX0_MGTREFCLKTX_IN    => REF_CLK_80,
      GTX0_PLLTXRESET_IN     => RST,
      GTX0_TXPLLLKDET_OUT    => gtx0_txplllkdet_out,
      GTX0_TXRESETDONE_OUT   => open,
      -- PRBS Ports --------------------------------------------------------------
      GTX0_PRBSCNTRESET_IN   => prbs_err_cnt_rst,
      GTX0_ENTXPRBSTST_IN    => gtx0_entxprbstst_in,
      GTX0_ENRXPRBSTST_IN    => gtx0_enrxprbstst_in,
      -- DRP Ports ---------------------------------------------------------------
      GTX0_DCLK_IN           => usr_clk,
      GTX0_DEN_IN            => prbs_rd_en_inner,
      GTX0_DRPDO_OUT         => PRBS_ERR_CNT
      );

  -- Double reset required because TXPLL_DIVSEL_OUT = 2
  DOUBLE_RESET_PM : DOUBLE_RESET
    port map (
      CLK          => usr_clk,
      PLLLKDET     => gtx0_txplllkdet_out,
      GTXTEST_DONE => gtx0_gtxtest_done,
      GTXTEST_BIT1 => gtx0_gtxtest_bit1
      );

  TX_FIFO_CASCADE : FIFO_CASCADE
    generic map (
      NFIFO        => 4,                -- number of FIFOs in cascade
      DATA_WIDTH   => 16,               -- With of data packets
      FWFT         => true,             -- First word fall through
      WR_FASTER_RD => true)  -- Set int_clk to WRCLK if faster than RDCLK

    port map(
      DO        => TX_FIFO_DOUT,        -- Output data
      EMPTY     => tx_fifo_empty,       -- Output empty
      FULL      => tx_fifo_full,        -- Output full
      HALF_FULL => open,
      EOF       => open,                -- Output EOF
      BOF       => open,

      DI    => TXD,                     -- Input data
      RDCLK => VME_CLK,                 -- Input read clock
      RDEN  => TX_FIFO_RDEN,            -- Input read enable
      RST   => tx_fifo_rst,             -- Input reset
      WRCLK => usr_clk,                 -- Input write clock
      WREN  => TXD_VLD                  -- Input write enable
      );

  TX_WRD_COUNT : FIFOWORDS
    port map(RST   => tx_fifo_rst, WRCLK => usr_clk, WREN => TXD_VLD, FULL => tx_fifo_full,
             RDCLK => VME_CLK, RDEN => TX_FIFO_RDEN, COUNT => TX_FIFO_WRD_CNT);


  RX_FIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 16,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => true)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      RST         => rx_fifo_rst,       -- Input reset
      ALMOSTEMPTY => open,              -- Output almost empty 
      ALMOSTFULL  => open,              -- Output almost full
      EMPTY       => rx_fifo_empty,     -- Output empty
      FULL        => rx_fifo_full,      -- Output full
      RDCOUNT     => rx_fifo_rdcout,    -- Output read count
      RDERR       => rx_fifo_rderr,     -- Output read error
      WRCOUNT     => rx_fifo_wrcout,    -- Output write count
      WRERR       => rx_fifo_wrerr,     -- Output write error
      DO          => RX_FIFO_DOUT,      -- Output data
      RDCLK       => VME_CLK,           -- Input read clock
      RDEN        => RX_FIFO_RDEN,      -- Input read enable
      DI          => rxd_inner,         -- Input data
      WRCLK       => usr_clk,           -- Input write clock
      WREN        => rxd_vld_inner      -- Input write enable
      );

  RX_WRD_COUNT : FIFOWORDS
    port map(RST   => rx_fifo_rst, WRCLK => usr_clk, WREN => rxd_vld_inner,
             FULL  => rx_fifo_full, RDCLK => VME_CLK, RDEN => RX_FIFO_RDEN,
             COUNT => RX_FIFO_WRD_CNT);

  prbs_rst_cnt   <= prbs_length+prbs_rst_cycles;
  prbs_en_cnt    <= prbs_length*to_integer(unsigned(prbs_en_tst_cnt))+prbs_rst_cnt;
  prbs_rd_en_cnt <= prbs_en_cnt-1;

  PRBS_INIT_PE  : NPULSE2FAST port map(prbs_init_pulse, usr_clk, RST, prbs_length, PRBS_RX_EN);
  PRBS_RST_PE   : NPULSE2FAST port map(prbs_reset_pulse, usr_clk, RST, prbs_rst_cnt, PRBS_RX_EN);
  PRBS_RD_EN_PE : NPULSE2FAST port map(prbs_rd_en_pulse, usr_clk, RST, prbs_rd_en_cnt, PRBS_RX_EN);
  PRBS_EN_PE    : NPULSE2FAST port map(prbs_en_pulse, usr_clk, RST, prbs_en_cnt, PRBS_RX_EN);

  prbs_err_cnt_rst    <= prbs_reset_pulse and not prbs_init_pulse;
  prbs_rd_en_inner    <= prbs_en_pulse and not prbs_rd_en_pulse;
  --  gtx0_enprbstst_in <= "00" & prbs_en_pulse;
  gtx0_enrxprbstst_in <= PRBS_TYPE when (prbs_en_pulse = '1') else "000";
  gtx0_entxprbstst_in <= PRBS_TYPE when (PRBS_TX_EN = '1')    else "000";
end GIGALINK_DDU_ARCH;
