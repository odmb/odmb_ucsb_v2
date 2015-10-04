-- GIGALINK_PC: Optical transmitter and receiver to/from test PC (OT2, GL1)

library ieee;
library work;
library unimacro;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ucsb_types.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;

entity GIGALINK_PC is
  generic (
    SIM_SPEEDUP : integer := 0
    );
  port (
    -- Global signals
    RST    : in std_logic;
    REFCLK : in std_logic;              -- 125 MHz for PC data rate
    USRCLK  : out std_logic;            -- Data clock coming from the TX PLL

    -- Transmitter signals
    TXD     : in  std_logic_vector(15 downto 0);  -- Data to be transmitted
    TXD_VLD : in  std_logic;            -- Flag for valid data;
    TX_ACK  : out std_logic;  -- TX acknowledgement (ethernet header has finished)
    TXD_N   : out std_logic;            -- GTX transmit data out - signal
    TXD_P   : out std_logic;            -- GTX transmit data out + signal

    TXDIFFCTRL : in std_logic_vector(3 downto 0);  -- Controls the TX voltage swing
    LOOPBACK   : in std_logic_vector(2 downto 0);  -- For internal loopback tests

    -- Receiver signals
    RXD_N   : in  std_logic;            -- GTX receive data in - signal
    RXD_P   : in  std_logic;            -- GTX receive data in + signal
    RXD     : out std_logic_vector(15 downto 0);  -- Data received
    RXD_VLD : out std_logic;            -- Flag for valid data;
    BAD_RX  : out std_logic;           -- Flag for fiber errors;

    TX_FIFO_WREN_OUT : out std_logic;
    TXD_FRAME_OUT    : out std_logic_vector(15 downto 0);
    ROM_CNT_OUT      : out std_logic_vector(2 downto 0);

    -- PRBS signals
    PRBS_TYPE       : in  std_logic_vector(2 downto 0);
    PRBS_TX_EN      : in  std_logic;
    PRBS_RX_EN      : in  std_logic;
    PRBS_EN_TST_CNT : in  std_logic_vector(15 downto 0);
    PRBS_ERR_CNT    : out std_logic_vector(15 downto 0)
    );
end GIGALINK_PC;


architecture GIGALINK_PC_ARCH of GIGALINK_PC is

  component WRAPPER_GIGALINK_PC
    generic (
      WRAPPER_SIM_GTXRESET_SPEEDUP : integer := 0  -- Set to 1 to speed up sim reset
      );
    port (
      --_________________________________________________________________________
      --GTX0  (X0_Y0)

      ------------------------ Loopback and Powerdown Ports ----------------------
      GTX0_LOOPBACK_IN       : in  std_logic_vector(2 downto 0);
      GTX0_RXPOWERDOWN_IN    : in  std_logic_vector(1 downto 0);
      ----------------------- Receive Ports - 8b10b Decoder ----------------------
      GTX0_RXCHARISK_OUT     : out std_logic_vector(1 downto 0);
      GTX0_RXDISPERR_OUT     : out std_logic_vector(1 downto 0);
      GTX0_RXNOTINTABLE_OUT  : out std_logic_vector(1 downto 0);
      GTX0_RXRUNDISP_OUT     : out std_logic_vector(1 downto 0);
      ------------------- Receive Ports - Clock Correction Ports -----------------
      GTX0_RXCLKCORCNT_OUT   : out std_logic_vector(2 downto 0);
      --------------- Receive Ports - Comma Detection and Alignment --------------
      GTX0_RXBYTEREALIGN_OUT : out std_logic;
      ------------------- Receive Ports - RX Data Path interface -----------------
      GTX0_RXDATA_OUT        : out std_logic_vector(15 downto 0);
      GTX0_RXVALID_OUT       : out std_logic;
      GTX0_RXRESET_IN        : in  std_logic;
      GTX0_RXUSRCLK2_IN      : in  std_logic;
      ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
      GTX0_RXELECIDLE_OUT    : out std_logic;
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
      GTX0_TXOUTCLK_OUT      : out std_logic;
      GTX0_TXRESET_IN        : in  std_logic;
      GTX0_TXUSRCLK2_IN      : in  std_logic;
      ---------------- Transmit Ports - TX Driver and OOB signaling --------------
      GTX0_TXDIFFCTRL_IN     : in  std_logic_vector(3 downto 0);
      GTX0_TXN_OUT           : out std_logic;
      GTX0_TXP_OUT           : out std_logic;
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

  --component WRAPPER_GIGALINK_PC_GTX
  --  generic (
  --    WRAPPER_SIM_GTXRESET_SPEEDUP : integer    := 0;  -- Set to 1 to speed up sim reset
  --    GTX_TX_CLK_SOURCE            : string     := "TXPLL";  -- Share RX PLL parameter
  --    GTX_POWER_SAVE               : bit_vector := "0000000000"  -- Save power parameter
  --    );
  --  port (
  --    --_________________________________________________________________________
  --    --GTX0  (X0_Y0)

  --    ------------------------ Loopback and Powerdown Ports ----------------------
  --    LOOPBACK_IN       : in  std_logic_vector(2 downto 0);
  --    RXPOWERDOWN_IN    : in  std_logic_vector(1 downto 0);
  --    ----------------------- Receive Ports - 8b10b Decoder ----------------------
  --    RXCHARISK_OUT     : out std_logic_vector(1 downto 0);
  --    RXDISPERR_OUT     : out std_logic_vector(1 downto 0);
  --    RXNOTINTABLE_OUT  : out std_logic_vector(1 downto 0);
  --    RXRUNDISP_OUT     : out std_logic_vector(1 downto 0);
  --    ------------------- Receive Ports - Clock Correction Ports -----------------
  --    RXCLKCORCNT_OUT   : out std_logic_vector(2 downto 0);
  --    --------------- Receive Ports - Comma Detection and Alignment --------------
  --    RXBYTEREALIGN_OUT : out std_logic;
  --    ------------------- Receive Ports - RX Data Path interface -----------------
  --    RXDATA_OUT        : out std_logic_vector(15 downto 0);
  --    RXVALID_OUT       : out std_logic;
  --    RXRESET_IN        : in  std_logic;
  --    RXUSRCLK2_IN      : in  std_logic;
  --    ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
  --    RXELECIDLE_OUT    : out std_logic;
  --    RXN_IN            : in  std_logic;
  --    RXP_IN            : in  std_logic;
  --    ------------------------ Receive Ports - RX PLL Ports ----------------------
  --    GTXRXRESET_IN     : in  std_logic;
  --    MGTREFCLKRX_IN    : in  std_logic_vector(1 downto 0);
  --    PLLRXRESET_IN     : in  std_logic;
  --    RXPLLLKDET_OUT    : out std_logic;
  --    RXRESETDONE_OUT   : out std_logic;
  --    ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
  --    TXCHARISK_IN      : in  std_logic_vector(1 downto 0);
  --    ------------------------- Transmit Ports - GTX Ports -----------------------
  --    GTXTEST_IN        : in  std_logic_vector(12 downto 0);
  --    ------------------ Transmit Ports - TX Data Path interface -----------------
  --    TXDATA_IN         : in  std_logic_vector(15 downto 0);
  --    TXOUTCLK_OUT      : out std_logic;
  --    TXRESET_IN        : in  std_logic;
  --    TXUSRCLK2_IN      : in  std_logic;
  --    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
  --    TXDIFFCTRL_IN     : in  std_logic_vector(3 downto 0);
  --    TXN_OUT           : out std_logic;
  --    TXP_OUT           : out std_logic;
  --    --------------- Transmit Ports - TX Driver and OOB signalling --------------
  --    TXPREEMPHASIS_IN  : in  std_logic_vector(3 downto 0);
  --    ----------------------- Transmit Ports - TX PLL Ports ----------------------
  --    GTXTXRESET_IN     : in  std_logic;
  --    MGTREFCLKTX_IN    : in  std_logic_vector(1 downto 0);
  --    PLLTXRESET_IN     : in  std_logic;
  --    TXPLLLKDET_OUT    : out std_logic;
  --    TXRESETDONE_OUT   : out std_logic

  --    );
  --end component;

  component MGT_USRCLK_SOURCE
    generic
      (
        FREQUENCY_MODE   : string := "LOW";
        PERFORMANCE_MODE : string := "MAX_SPEED"
        );
    port
      (
        DIV1_OUT       : out std_logic;
        DIV2_OUT       : out std_logic;
        DCM_LOCKED_OUT : out std_logic;
        CLK_IN         : in  std_logic;
        DCM_RESET_IN   : in  std_logic

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

  component MGT_USRCLK_SOURCE_MMCM
    generic
      (
        MULT        : real    := 2.0;
        DIVIDE      : integer := 2;
        CLK_PERIOD  : real    := 6.4;
        OUT0_DIVIDE : real    := 2.0;
        OUT1_DIVIDE : integer := 2;
        OUT2_DIVIDE : integer := 2;
        OUT3_DIVIDE : integer := 2
        );
    port
      (
        CLK0_OUT        : out std_logic;
        CLK1_OUT        : out std_logic;
        CLK2_OUT        : out std_logic;
        CLK3_OUT        : out std_logic;
        CLK_IN          : in  std_logic;
        MMCM_LOCKED_OUT : out std_logic;
        MMCM_RESET_IN   : in  std_logic
        );
  end component;

  component ETHERNET_FRAME is
    port (
      CLK : in std_logic;               -- User clock
      RST : in std_logic;               -- Reset

      TXD_VLD : in std_logic;                      -- Flag for valid data
      TXD     : in std_logic_vector(15 downto 0);  -- Data with no frame

      ROM_CNT_OUT : out std_logic_vector(2 downto 0);

      TXD_ACK   : out std_logic;                     -- TX acknowledgement
      TXD_ISK   : out std_logic_vector(1 downto 0);  -- Data is K character
      TXD_FRAME : out std_logic_vector(15 downto 0)  -- Data to be transmitted
      );
  end component;

  constant tied_to_ground_i     : std_logic                     := '0';
  constant tied_to_ground_vec_i : std_logic_vector(63 downto 0) := (others => '0');
  constant tied_to_vcc_i        : std_logic                     := '1';
  constant tied_to_vcc_vec_i    : std_logic_vector(7 downto 0)  := (others => '1');
  constant IDLE                 : std_logic_vector(15 downto 0) := x"50BC";

  -- GTXE1 signals
  ------------------------ Loopback and Powerdown Ports ----------------------
  signal gtx0_rxpowerdown_i   : std_logic_vector(1 downto 0);
  ----------------------- Receive Ports - 8b10b Decoder ----------------------
  signal gtx0_rxcharisk_i     : std_logic_vector(1 downto 0);
  signal gtx0_rxdisperr_i     : std_logic_vector(1 downto 0);
  signal gtx0_rxnotintable_i  : std_logic_vector(1 downto 0);
  signal gtx0_rxrundisp_i     : std_logic_vector(1 downto 0);
  ------------------- Receive Ports - Clock Correction Ports -----------------
  signal gtx0_rxclkcorcnt_i   : std_logic_vector(2 downto 0);
  --------------- Receive Ports - Comma Detection and Alignment --------------
  signal gtx0_rxbyterealign_i : std_logic;
  ------------------- Receive Ports - RX Data Path interface -----------------
  signal gtx0_rxreset_i       : std_logic;
  ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
  signal gtx0_rxelecidle_i    : std_logic;
  ------------------------ Receive Ports - RX PLL Ports ----------------------
  signal gtx0_gtxrxreset_i    : std_logic;
  signal gtx0_pllrxreset_i    : std_logic;
  signal gtx0_rxplllkdet_i    : std_logic;
  signal gtx0_rxresetdone_i   : std_logic;
  ------------------------- Transmit Ports - GTX Ports -----------------------
  signal gtx0_gtxtest_i       : std_logic_vector(12 downto 0);
  ------------------ Transmit Ports - TX Data Path interface -----------------
  signal gtx0_txoutclk_i      : std_logic;
  signal gtx0_txreset_i       : std_logic;
  --------------- Transmit Ports - TX Driver and OOB signalling --------------
  signal gtx0_txpreemphasis_i : std_logic_vector(3 downto 0);
  ----------------------- Transmit Ports - TX PLL Ports ----------------------
  signal gtx0_gtxtxreset_i    : std_logic;
  signal gtx0_mgtrefclk_i     : std_logic_vector(1 downto 0);
  signal gtx0_plltxreset_i    : std_logic;
  signal gtx0_txplllkdet_i    : std_logic;
  signal gtx0_txresetdone_i   : std_logic;

  signal rxd_inner        : std_logic_vector(15 downto 0) := (others => '0');
  signal rxd_vld_inner    : std_logic                     := '0';
  signal gtx0_rxvalid_out : std_logic;

  ------------------------ Other GTX ----------------------
  signal gtx0_gtxtest_bit1 : std_logic;

  -- Clocks
  signal usr_clk                 : std_logic;
  signal txoutclk_mmcm0_locked_i : std_logic;
  signal txoutclk_mmcm0_reset_i  : std_logic;
  signal q0_clk0_refclk_i        : std_logic;
  signal q0_clk0_refclk_i_bufg   : std_logic;

  -- Data signals
  signal txd_frame_isk : std_logic_vector(1 downto 0);
  signal txd_frame     : std_logic_vector(15 downto 0);

  signal rxbyterealign_pulse : std_logic := '0';
  signal rxdisperr_pulse     : std_logic := '0';

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

  -- RX data valid is high when the RX is valid and we are not receiving a K character
  -- The pulse avoids some false positives during resets
  PULSE_ALIGN : PULSE_EDGE port map(rxbyterealign_pulse, open, usr_clk,
                                    RST, 10, gtx0_rxbyterealign_i);
  PULSE_DISPERR : PULSE_EDGE port map (rxdisperr_pulse, open, usr_clk,
                                       RST, 10, gtx0_rxdisperr_i(0));
  rxd_vld_inner <= '1' when (gtx0_rxvalid_out = '1'
                             and (rxd_inner(7 downto 0) /= x"BC" or gtx0_rxcharisk_i /= "01")
                             and rxbyterealign_pulse = '0' and gtx0_rxnotintable_i = "00"
                             and rxdisperr_pulse = '0' and gtx0_rxdisperr_i = "00") else '0';
  RXD     <= rxd_inner;
  RXD_VLD <= rxd_vld_inner;
  BAD_RX <= gtx0_rxnotintable_i(0) or gtx0_rxnotintable_i(1) or (not gtx0_rxvalid_out);



  ----------------------------- The GTX Wrapper -----------------------------

  -- Hold the TX/RX in reset till the TX/RX user clocks are stable
  gtx0_txreset_i <= not txoutclk_mmcm0_locked_i;
  gtx0_rxreset_i <= not txoutclk_mmcm0_locked_i;

  gtx0_gtxtest_i       <= b"10000000000" & gtx0_gtxtest_bit1 & '0';
  gtx0_gtxtxreset_i    <= RST;
  gtx0_gtxrxreset_i    <= RST;
  gtx0_plltxreset_i    <= tied_to_ground_i;
  gtx0_txpreemphasis_i <= tied_to_ground_vec_i(3 downto 0);
  gtx0_pllrxreset_i    <= tied_to_ground_i;
  gtx0_rxpowerdown_i   <= tied_to_ground_vec_i(1 downto 0);
  gtx0_mgtrefclk_i     <= '0' & q0_clk0_refclk_i;

  WRAPPER_GIGALINK_PC_PM : WRAPPER_GIGALINK_PC
    generic map (
      WRAPPER_SIM_GTXRESET_SPEEDUP => SIM_SPEEDUP
      )
    port map (
      --_____________________________________________________________________
      --GTX0  (X0Y0)

      ------------------------ Loopback and Powerdown Ports ----------------------
      GTX0_LOOPBACK_IN       => LOOPBACK,
      GTX0_RXPOWERDOWN_IN    => gtx0_rxpowerdown_i,
      ----------------------- Receive Ports - 8b10b Decoder ----------------------
      GTX0_RXCHARISK_OUT     => gtx0_rxcharisk_i,
      GTX0_RXDISPERR_OUT     => gtx0_rxdisperr_i,
      GTX0_RXNOTINTABLE_OUT  => gtx0_rxnotintable_i,
      GTX0_RXRUNDISP_OUT     => gtx0_rxrundisp_i,
      ------------------- Receive Ports - Clock Correction Ports -----------------
      GTX0_RXCLKCORCNT_OUT   => gtx0_rxclkcorcnt_i,
      --------------- Receive Ports - Comma Detection and Alignment --------------
      GTX0_RXBYTEREALIGN_OUT => gtx0_rxbyterealign_i,
      ------------------- Receive Ports - RX Data Path interface -----------------
      GTX0_RXDATA_OUT        => rxd_inner,
      GTX0_RXVALID_OUT       => gtx0_rxvalid_out,
      GTX0_RXRESET_IN        => gtx0_rxreset_i,
      GTX0_RXUSRCLK2_IN      => usr_clk,
      ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
      GTX0_RXELECIDLE_OUT    => gtx0_rxelecidle_i,
      GTX0_RXN_IN            => RXD_N,
      GTX0_RXP_IN            => RXD_P,
      ------------------------ Receive Ports - RX PLL Ports ----------------------
      GTX0_GTXRXRESET_IN     => gtx0_gtxrxreset_i,
      GTX0_MGTREFCLKRX_IN    => q0_clk0_refclk_i,
      GTX0_PLLRXRESET_IN     => gtx0_pllrxreset_i,
      GTX0_RXPLLLKDET_OUT    => gtx0_rxplllkdet_i,
      GTX0_RXRESETDONE_OUT   => gtx0_rxresetdone_i,
      ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
      GTX0_TXCHARISK_IN      => txd_frame_isk,
      ------------------------- Transmit Ports - GTX Ports -----------------------
      GTX0_GTXTEST_IN        => gtx0_gtxtest_i,
      ------------------ Transmit Ports - TX Data Path interface -----------------
      GTX0_TXDATA_IN         => txd_frame,
      GTX0_TXOUTCLK_OUT      => gtx0_txoutclk_i,
      GTX0_TXRESET_IN        => gtx0_txreset_i,
      GTX0_TXUSRCLK2_IN      => usr_clk,
      ---------------- Transmit Ports - TX Driver and OOB signaling --------------
      GTX0_TXDIFFCTRL_IN     => TXDIFFCTRL,
      GTX0_TXN_OUT           => TXD_N,
      GTX0_TXP_OUT           => TXD_P,
      --------------- Transmit Ports - TX Driver and OOB signalling --------------
      GTX0_TXPREEMPHASIS_IN  => gtx0_txpreemphasis_i,
      ----------------------- Transmit Ports - TX PLL Ports ----------------------
      GTX0_GTXTXRESET_IN     => gtx0_gtxtxreset_i,
      GTX0_MGTREFCLKTX_IN    => q0_clk0_refclk_i,
      GTX0_PLLTXRESET_IN     => gtx0_plltxreset_i,
      GTX0_TXPLLLKDET_OUT    => gtx0_txplllkdet_i,
      GTX0_TXRESETDONE_OUT   => gtx0_txresetdone_i,
      -- PRBS Ports --------------------------------------------------------------
      GTX0_PRBSCNTRESET_IN   => prbs_err_cnt_rst,
      GTX0_ENTXPRBSTST_IN    => gtx0_entxprbstst_in,
      GTX0_ENRXPRBSTST_IN    => gtx0_enrxprbstst_in,
      -- DRP Ports ---------------------------------------------------------------
      GTX0_DCLK_IN           => usr_clk,
      GTX0_DEN_IN            => prbs_rd_en_inner,
      GTX0_DRPDO_OUT         => PRBS_ERR_CNT
      );

  --WRAPPER_GIGALINK_PC_GTX_PM : WRAPPER_GIGALINK_PC_GTX
  --  generic map (
  --    WRAPPER_SIM_GTXRESET_SPEEDUP => SIM_SPEEDUP,
  --    GTX_TX_CLK_SOURCE            => "TXPLL",      -- Save power parameter
  --    GTX_POWER_SAVE               => "0000110000"  -- Save power parameter
  --    )
  --  port map (
  --    --_____________________________________________________________________
  --    --GTX0  (X0Y0)

  --    ------------------------ Loopback and Powerdown Ports ----------------------
  --    LOOPBACK_IN       => LOOPBACK,
  --    RXPOWERDOWN_IN    => gtx0_rxpowerdown_i,
  --    ----------------------- Receive Ports - 8b10b Decoder ----------------------
  --    RXCHARISK_OUT     => gtx0_rxcharisk_i,
  --    RXDISPERR_OUT     => gtx0_rxdisperr_i,
  --    RXNOTINTABLE_OUT  => gtx0_rxnotintable_i,
  --    RXRUNDISP_OUT     => gtx0_rxrundisp_i,
  --    ------------------- Receive Ports - Clock Correction Ports -----------------
  --    RXCLKCORCNT_OUT   => gtx0_rxclkcorcnt_i,
  --    --------------- Receive Ports - Comma Detection and Alignment --------------
  --    RXBYTEREALIGN_OUT => gtx0_rxbyterealign_i,
  --    ------------------- Receive Ports - RX Data Path interface -----------------
  --    RXDATA_OUT        => rxd_inner,
  --    RXVALID_OUT       => gtx0_rxvalid_out,
  --    RXRESET_IN        => gtx0_rxreset_i,
  --    RXUSRCLK2_IN      => usr_clk,
  --    ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
  --    RXELECIDLE_OUT    => gtx0_rxelecidle_i,
  --    RXN_IN            => RXD_N,
  --    RXP_IN            => RXD_P,
  --    ------------------------ Receive Ports - RX PLL Ports ----------------------
  --    GTXRXRESET_IN     => gtx0_gtxrxreset_i,
  --    MGTREFCLKRX_IN    => gtx0_mgtrefclk_i,
  --    PLLRXRESET_IN     => gtx0_pllrxreset_i,
  --    RXPLLLKDET_OUT    => gtx0_rxplllkdet_i,
  --    RXRESETDONE_OUT   => gtx0_rxresetdone_i,
  --    ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
  --    TXCHARISK_IN      => txd_frame_isk,
  --    ------------------------- Transmit Ports - GTX Ports -----------------------
  --    GTXTEST_IN        => gtx0_gtxtest_i,
  --    ------------------ Transmit Ports - TX Data Path interface -----------------
  --    TXDATA_IN         => txd_frame,
  --    TXOUTCLK_OUT      => gtx0_txoutclk_i,
  --    TXRESET_IN        => gtx0_txreset_i,
  --    TXUSRCLK2_IN      => usr_clk,
  --    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
  --    TXDIFFCTRL_IN     => TXDIFFCTRL,
  --    TXN_OUT           => TXD_N,
  --    TXP_OUT           => TXD_P,
  --    --------------- Transmit Ports - TX Driver and OOB signalling --------------
  --    TXPREEMPHASIS_IN  => gtx0_txpreemphasis_i,
  --    ----------------------- Transmit Ports - TX PLL Ports ----------------------
  --    GTXTXRESET_IN     => gtx0_gtxtxreset_i,
  --    MGTREFCLKTX_IN    => gtx0_mgtrefclk_i,
  --    PLLTXRESET_IN     => gtx0_plltxreset_i,
  --    TXPLLLKDET_OUT    => gtx0_txplllkdet_i,
  --    TXRESETDONE_OUT   => gtx0_txresetdone_i
  --    );

  USRCLK <= usr_clk;

  ETHERNET_FRAME_PM : ETHERNET_FRAME
    port map (
      CLK => usr_clk,
      RST => RST,

      TXD_VLD => TXD_VLD,
      TXD     => TXD,

      ROM_CNT_OUT => ROM_CNT_OUT,

      TXD_ACK   => TX_ACK,
      TXD_ISK   => txd_frame_isk,
      TXD_FRAME => txd_frame
      );

  gtx0_double_reset_i : DOUBLE_RESET
    port map
    (
      PLLLKDET     => gtx0_txplllkdet_i,
      GTXTEST_BIT1 => gtx0_gtxtest_bit1,
      GTXTEST_DONE => open,
      CLK          => q0_clk0_refclk_i_bufg
      );

  ----------------------------- Reference Clocks ----------------------------

  --Q0_CLK0_REFCLK_IBUFDS_I : IBUFDS_GTXE1
  --  port map (
  --    O     => q0_clk0_refclk_i,
  --    ODIV2 => open,
  --    CEB   => tied_to_ground_i,
  --    I     => REFCLK_P,
  --    IB    => REFCLK_N
  --    );
  q0_clk0_refclk_i <= REFCLK;

  Q0_CLK0_REFCLK_BUFG_I : BUFG
    port map (
      I => q0_clk0_refclk_i,
      O => q0_clk0_refclk_i_bufg
      );

  txoutclk_mmcm0_reset_i <= not gtx0_txplllkdet_i;
  TXOUTCLK_MMCM0_I : MGT_USRCLK_SOURCE_MMCM
    generic map (
      MULT        => 9.0,
      DIVIDE      => 1,
      CLK_PERIOD  => 8.0,
      OUT0_DIVIDE => 18.0,
      OUT1_DIVIDE => 1,
      OUT2_DIVIDE => 1,
      OUT3_DIVIDE => 1
      )
    port map (
      CLK0_OUT        => usr_clk,
      CLK1_OUT        => open,
      CLK2_OUT        => open,
      CLK3_OUT        => open,
      CLK_IN          => gtx0_txoutclk_i,
      MMCM_LOCKED_OUT => txoutclk_mmcm0_locked_i,
      MMCM_RESET_IN   => txoutclk_mmcm0_reset_i
      );

  -- For the PC TX FIFO
  TX_FIFO_WREN_OUT <= '1' when txd_frame /= IDLE else '0';
  TXD_FRAME_OUT    <= txd_frame;

  prbs_rst_cnt   <= prbs_length+prbs_rst_cycles;
  prbs_en_cnt    <= prbs_length*to_integer(unsigned(prbs_en_tst_cnt))+prbs_rst_cnt;
  prbs_rd_en_cnt <= prbs_en_cnt-1;

  PRBS_INIT_PE  : NPULSE2FAST port map(prbs_init_pulse, usr_clk, RST, prbs_length, PRBS_RX_EN);
  PRBS_RST_PE   : NPULSE2FAST port map(prbs_reset_pulse, usr_clk, RST, prbs_rst_cnt, PRBS_RX_EN);
  PRBS_RD_EN_PE : NPULSE2FAST port map(prbs_rd_en_pulse, usr_clk, RST, prbs_rd_en_cnt, PRBS_RX_EN);
  PRBS_EN_PE    : NPULSE2FAST port map(prbs_en_pulse, usr_clk, RST, prbs_en_cnt, PRBS_RX_EN);

  prbs_err_cnt_rst    <= prbs_reset_pulse and not prbs_init_pulse;
  prbs_rd_en_inner    <= prbs_en_pulse and not prbs_rd_en_pulse;
  gtx0_enrxprbstst_in <= PRBS_TYPE when (prbs_en_pulse = '1') else "000";
  gtx0_entxprbstst_in <= PRBS_TYPE when (PRBS_TX_EN = '1')    else "000";

end GIGALINK_PC_ARCH;
