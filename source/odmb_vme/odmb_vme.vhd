-- ODMB_VME: Handles the VME protocol and selects VME device

-- Device 0 => TESTCTRL
-- Device 1 => CFEBJTAG
-- Device 2 => ODMBJTAG
-- Device 3 => VMEMON
-- Device 4 => VMECONFREGS
-- Device 5 => TESTFIFOS
-- Device 6 => BPI_PORT
-- Device 7 => SYSTEM_MON
-- Device 8 => LVDBMON
-- Device 9 => SYSTEM_TEST

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity ODMB_VME is
  generic (
    NFEB : integer range 1 to 7 := 7    -- Number of DCFEBS
    );  
  port (
    CSP_SYSTEM_TEST_PORT_LA_CTRL : inout std_logic_vector (35 downto 0);
    CSP_BPI_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);
-- VME signals

    cmd_adrs        : out std_logic_vector(15 downto 0);
    vme_addr        : in  std_logic_vector (23 downto 1);  -- adr(23 downto 1)
    vme_data_in     : in  std_logic_vector (15 downto 0);  -- data(15 downto 0)
    vme_data_out    : out std_logic_vector (15 downto 0);  -- data(15 downto 0)
    vme_am          : in  std_logic_vector (5 downto 0);   -- am(5 downto 0)
    vme_ga          : in  std_logic_vector (4 downto 0);   -- ga*(4 downto 0)
    vme_gap         : in  std_logic;                       -- ga*(5)
    vme_ds_b        : in  std_logic_vector(1 downto 0);    -- ids1*,ids0*
    vme_as_b        : in  std_logic;                       -- ias*
    vme_lword_b     : in  std_logic;                       -- ilword*
    vme_write_b     : in  std_logic;                       -- iwrite*
    vme_iack_b      : in  std_logic;                       -- inack*
    vme_sysreset_b  : in  std_logic;                       -- isysrst*
    vme_sysfail_b   : in  std_logic;                       -- isysfail*
    vme_sysfail_out : out std_logic;                       -- NEW
    vme_berr_b      : in  std_logic;                       -- iberr*
    vme_berr_out    : out std_logic;                       -- NEW
    vme_dtack_b     : out std_logic;                       -- odtack*
    vme_tovme       : out std_logic;                       -- tovme
    vme_tovme_b     : out std_logic;                       -- tovme*
    vme_doe         : out std_logic;                       -- doe
    vme_doe_b       : out std_logic;                       -- doe*

-- Clock

    clk160 : in std_logic;              -- For dcfeb prbs (160MHz)
    clk80  : in std_logic;              -- For testctrl (80MHz)
    clk    : in std_logic;              -- NEW (fastclk -> 40MHz)
    clk_s1 : in std_logic;              -- NEW (midclk -> fastclk/4 -> 10MHz)
    clk_s2 : in std_logic;              -- NEW (slowclk -> midclk/4 -> 2.5MHz)
    clk_s3 : in std_logic;  -- NEW (slowclk2 -> midclk/8 -> 12.5MHz)

-- Reset

    rst       : in  std_logic;          -- Firmware reset
    pon_reset : in  std_logic;          -- Power on reset
    led_pulse : out std_logic;

-- JTAG Signals To/From DCFEBs

    dl_jtag_tck : out std_logic_vector (6 downto 0);
    dl_jtag_tms : out std_logic;
    dl_jtag_tdi : out std_logic;
    dl_jtag_tdo : in  std_logic_vector (6 downto 0);

-- JTAG Signals To/From DMB_CTRL

    mbc_jtag_tck : out std_logic;
    mbc_jtag_tms : out std_logic;
    mbc_jtag_tdi : out std_logic;
    mbc_jtag_tdo : in  std_logic;

-- JTAG Signals To/From ODMB JTAG

    odmb_jtag_sel : out std_logic;
    odmb_jtag_tck : out std_logic;
    odmb_jtag_tms : out std_logic;
    odmb_jtag_tdi : out std_logic;
    odmb_jtag_tdo : in  std_logic;

-- Done from DCFEB FPGA (CFEBPRG)

    dcfeb_done : in std_logic_vector(NFEB downto 1);

-- From/To LVMB

    lvmb_pon   : out std_logic_vector(7 downto 0);
    pon_load   : out std_logic;
    pon_oe_b   : out std_logic;
    r_lvmb_pon : in  std_logic_vector(7 downto 0);
    lvmb_csb   : out std_logic_vector(6 downto 0);
    lvmb_sclk  : out std_logic;
    lvmb_sdin  : out std_logic;
    lvmb_sdout : in  std_logic;

    diagout_cfebjtag : out std_logic_vector(17 downto 0);
    diagout_lvdbmon  : out std_logic_vector(17 downto 0);

-- From VMEMON
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

    tp_sel        : out std_logic_vector(15 downto 0);
    odmb_ctrl     : out std_logic_vector(15 downto 0);
    dcfeb_ctrl    : out std_logic_vector(15 downto 0);
    ODMB_DATA_SEL : out std_logic_vector(7 downto 0);
    odmb_data     : in  std_logic_vector(15 downto 0);
    TXDIFFCTRL    : out std_logic_vector(3 downto 0);  -- Controls the TX voltage swing
    LOOPBACK      : out std_logic_vector(2 downto 0);  -- For internal loopback tests

    -- TESTCTRL
    tc_l1a         : out std_logic;
    tc_alct_dav    : out std_logic;
    tc_otmb_dav    : out std_logic;
    tc_lct         : out std_logic_vector(NFEB downto 0);
    ddu_data       : in  std_logic_vector(15 downto 0);
    ddu_data_valid : in  std_logic;
    tc_run         : out std_logic;
    ts_out         : out std_logic_vector(31 downto 0);
    dduclk         : in  std_logic;

    -- VMECONFREGS outputs
    ALCT_PUSH_DLY : out std_logic_vector(4 downto 0);
    OTMB_PUSH_DLY : out std_logic_vector(4 downto 0);
    PUSH_DLY      : out std_logic_vector(4 downto 0);
    LCT_L1A_DLY   : out std_logic_vector(5 downto 0);
    INJ_DLY       : out std_logic_vector(4 downto 0);
    EXT_DLY       : out std_logic_vector(4 downto 0);
    CALLCT_DLY    : out std_logic_vector(3 downto 0);
    NWORDS_DUMMY  : out std_logic_vector(15 downto 0);
    KILL          : out std_logic_vector(NFEB+2 downto 1);
    CRATEID       : out std_logic_vector(7 downto 0);

    -- ALCT/OTMB FIFO signals
    alct_fifo_data_in    : in std_logic_vector(17 downto 0);
    alct_fifo_data_valid : in std_logic;
    otmb_fifo_data_in    : in std_logic_vector(17 downto 0);
    otmb_fifo_data_valid : in std_logic;

    -- PC FIFO signals
    pc_tx_fifo_rst     : out std_logic;
    pc_tx_fifo_rden    : out std_logic;
    pc_tx_fifo_dout    : in  std_logic_vector(15 downto 0);
    pc_tx_fifo_wrd_cnt : in  std_logic_vector(11 downto 0);
    pc_rx_fifo_rst     : out std_logic;
    pc_rx_fifo_rden    : out std_logic;
    pc_rx_fifo_dout    : in  std_logic_vector(15 downto 0);
    pc_rx_fifo_wrd_cnt : in  std_logic_vector(11 downto 0);

    -- DDU FIFO signals
    ddu_tx_fifo_rst     : out std_logic;
    ddu_tx_fifo_rden    : out std_logic;
    ddu_tx_fifo_dout    : in  std_logic_vector(15 downto 0);
    ddu_tx_fifo_wrd_cnt : in  std_logic_vector(11 downto 0);
    ddu_rx_fifo_rst     : out std_logic;
    ddu_rx_fifo_rden    : out std_logic;
    ddu_rx_fifo_dout    : in  std_logic_vector(15 downto 0);
    ddu_rx_fifo_wrd_cnt : in  std_logic_vector(11 downto 0);

    -- TESTFIFOS
    TFF_DOUT    : in  std_logic_vector(15 downto 0);
    TFF_WRD_CNT : in  std_logic_vector(11 downto 0);
    TFF_RST     : out std_logic_vector(NFEB downto 1);
    TFF_SEL     : out std_logic_vector(NFEB downto 1);
    TFF_RDEN    : out std_logic_vector(NFEB downto 1);

    -- SYSMON
    VP    : in std_logic;
    VN    : in std_logic;
    VAUXP : in std_logic_vector(15 downto 0);
    VAUXN : in std_logic_vector(15 downto 0);

    -- To/From BPI_PORT 
    BPI_RST           : out std_logic;  -- Resets BPI interface state machines
    BPI_CMD_FIFO_DATA : out std_logic_vector(15 downto 0);  -- Data for command FIFO
    BPI_WE            : out std_logic;  -- Command FIFO write enable  (pulse one clock cycle for one write)
    BPI_RE            : out std_logic;  -- Read back FIFO read enable  (pulse one clock cycle for one read)
    BPI_DSBL          : out std_logic;  -- Disable parsing of BPI commands in the command FIFO (while being filled)
    BPI_ENBL          : out std_logic;  -- Enable  parsing of BPI commands in the command FIFO
    BPI_RBK_FIFO_DATA : in  std_logic_vector(15 downto 0);  -- Data on output of the Read back FIFO
    BPI_RBK_WRD_CNT   : in  std_logic_vector(10 downto 0);  -- Word count of the Read back FIFO (number of available reads)
    BPI_STATUS        : in  std_logic_vector(15 downto 0);  -- FIFO status bits and latest value of the PROM status register. 
    BPI_TIMER         : in  std_logic_vector(31 downto 0);  -- General timer
    
-- Guido - Aug 26
    BPI_CFG_UL_BUGGER : out std_logic;
    BPI_CFG_DL_BUGGER : out std_logic;
    BPI_CFG_DONE   : in std_logic;
    BPI_CFG_REG_WE : in std_logic;
    BPI_CFG_REG_IN : in std_logic_vector(15 downto 0);

    -- DDU/PC/DCFEB COMMON PRBS
    PRBS_TYPE : out std_logic_vector(2 downto 0);

    -- DDU PRBS signals
    DDU_PRBS_EN      : out std_logic;
    DDU_PRBS_TST_CNT : out std_logic_vector(15 downto 0);
    DDU_PRBS_ERR_CNT : in  std_logic_vector(15 downto 0);

    -- PC PRBS signals
    PC_PRBS_EN      : out std_logic;
    PC_PRBS_TST_CNT : out std_logic_vector(15 downto 0);
    PC_PRBS_ERR_CNT : in  std_logic_vector(15 downto 0);

    -- DCFEB PRBS signals
    DCFEB_PRBS_FIBER_SEL : out std_logic_vector(3 downto 0);
    DCFEB_PRBS_EN        : out std_logic;
    DCFEB_PRBS_RST       : out std_logic;
    DCFEB_PRBS_RD_EN     : out std_logic;
    DCFEB_RXPRBSERR      : in  std_logic;
    DCFEB_PRBS_ERR_CNT   : in  std_logic_vector(15 downto 0);

    -- OTMB PRBS signals
    OTMB_TX : in  std_logic_vector(48 downto 0);
    OTMB_RX : out std_logic_vector(5 downto 0)
    );

end ODMB_VME;


architecture ODMB_VME_architecture of ODMB_VME is

  component TESTCTRL is
    generic (
      NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
      );    
    port (
      CLK     : in std_logic;
      DDUCLK  : in std_logic;
      SLOWCLK : in std_logic;
      RST     : in std_logic;

      DEVICE  : in std_logic;
      STROBE  : in std_logic;
      COMMAND : in std_logic_vector(9 downto 0);

      INDATA  : in  std_logic_vector(15 downto 0);
      OUTDATA : out std_logic_vector(15 downto 0);

      DTACK : out std_logic;

      L1A            : out std_logic;
      ALCT_DAV       : out std_logic;
      OTMB_DAV       : out std_logic;
      LCT            : out std_logic_vector(NFEB downto 0);
      DDU_DATA       : in  std_logic_vector(15 downto 0);
      DDU_DATA_VALID : in  std_logic;
      TC_RUN         : out std_logic;
      TS_OUT         : out std_logic_vector(31 downto 0)
      );
  end component;

  component CFEBJTAG is
    port (
      FASTCLK : in std_logic;
      SLOWCLK : in std_logic;
      RST     : in std_logic;

      DEVICE  : in std_logic;
      STROBE  : in std_logic;
      COMMAND : in std_logic_vector(9 downto 0);
      WRITER  : in std_logic;

      INDATA  : in    std_logic_vector(15 downto 0);
      OUTDATA : inout std_logic_vector(15 downto 0);

      DTACK : out std_logic;

      INITJTAGS : in  std_logic;
      TCK       : out std_logic_vector(7 downto 1);
      TDI       : out std_logic;
      TMS       : out std_logic;
      FEBTDO    : in  std_logic_vector(7 downto 1);

      DIAGOUT : out std_logic_vector(17 downto 0);
      LED     : out std_logic
      );
  end component;

  component ODMBJTAG is
    port (
      FASTCLK : in std_logic;
      SLOWCLK : in std_logic;
      RST     : in std_logic;

      DEVICE  : in std_logic;
      STROBE  : in std_logic;
      COMMAND : in std_logic_vector(9 downto 0);
      WRITER  : in std_logic;

      INDATA  : in  std_logic_vector(15 downto 0);
      OUTDATA : out std_logic_vector(15 downto 0);

      DTACK : out std_logic;

      INITJTAGS : in  std_logic;
      TCK       : out std_logic;
      TDI       : out std_logic;
      TMS       : out std_logic;
      ODMBTDO   : in  std_logic;

      JTAGSEL : out std_logic;

      LED : out std_logic
      );
  end component;

  component VMEMON is
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

      DCFEB_DONE : in std_logic_vector(NFEB downto 1);

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
  end component;


  --component VMECONFREGS is
  --  port (
  --    SLOWCLK : in std_logic;
  --    RST     : in std_logic;

  --    DEVICE  : in std_logic;
  --    STROBE  : in std_logic;
  --    COMMAND : in std_logic_vector(9 downto 0);
  --    WRITER  : in std_logic;

  --    INDATA  : in  std_logic_vector(15 downto 0);
  --    OUTDATA : out std_logic_vector(15 downto 0);

  --    DTACK : out std_logic;

  --    ALCT_PUSH_DLY : out std_logic_vector(4 downto 0);
  --    OTMB_PUSH_DLY : out std_logic_vector(4 downto 0);
  --    PUSH_DLY      : out std_logic_vector(4 downto 0);
  --    LCT_L1A_DLY   : out std_logic_vector(5 downto 0);

  --    INJ_DLY    : out std_logic_vector(4 downto 0);
  --    EXT_DLY    : out std_logic_vector(4 downto 0);
  --    CALLCT_DLY : out std_logic_vector(3 downto 0);

  --    NWORDS_DUMMY : out std_logic_vector(15 downto 0);
  --    KILL         : out std_logic_vector(NFEB+2 downto 1);
  --    CRATEID      : out std_logic_vector(7 downto 0)
  --    );
  --end component;

  component VMECONFREGS is
    port (
      SLOWCLK : in std_logic;
      CLK     : in std_logic;
      RST     : in std_logic;

      DEVICE  : in std_logic;
      STROBE  : in std_logic;
      COMMAND : in std_logic_vector(9 downto 0);
      WRITER  : in std_logic;

      INDATA  : in  std_logic_vector(15 downto 0);
      OUTDATA : out std_logic_vector(15 downto 0);

      DTACK : out std_logic;

      ALCT_PUSH_DLY : out std_logic_vector(4 downto 0);
      OTMB_PUSH_DLY : out std_logic_vector(4 downto 0);
      PUSH_DLY      : out std_logic_vector(4 downto 0);
      LCT_L1A_DLY   : out std_logic_vector(5 downto 0);

      INJ_DLY    : out std_logic_vector(4 downto 0);
      EXT_DLY    : out std_logic_vector(4 downto 0);
      CALLCT_DLY : out std_logic_vector(3 downto 0);

      NWORDS_DUMMY : out std_logic_vector(15 downto 0);
      KILL         : out std_logic_vector(NFEB+2 downto 1);
      CRATEID      : out std_logic_vector(7 downto 0);

      -- From BPI_PORT
      BPI_CFG_UL_PULSE : in std_logic;
      BPI_CFG_DL_PULSE : in std_logic;

-- From BPI_CFG_CONTROLLER
      CC_CFG_REG_IN : in std_logic_vector(15 downto 0);
      CC_CFG_REG_WE : in std_logic_vector(15 downto 0);

-- To BPI_CFG_CONTROLLER
      CFG_REG0 : out std_logic_vector(15 downto 0);
      CFG_REG1 : out std_logic_vector(15 downto 0);
      CFG_REG2 : out std_logic_vector(15 downto 0);
      CFG_REG3 : out std_logic_vector(15 downto 0);
      CFG_REG4 : out std_logic_vector(15 downto 0);
      CFG_REG5 : out std_logic_vector(15 downto 0);
      CFG_REG6 : out std_logic_vector(15 downto 0);
      CFG_REG7 : out std_logic_vector(15 downto 0);
      CFG_REG8 : out std_logic_vector(15 downto 0);
      CFG_REG9 : out std_logic_vector(15 downto 0);
      CFG_REGA : out std_logic_vector(15 downto 0);
      CFG_REGB : out std_logic_vector(15 downto 0);
      CFG_REGC : out std_logic_vector(15 downto 0);
      CFG_REGD : out std_logic_vector(15 downto 0);
      CFG_REGE : out std_logic_vector(15 downto 0);
      CFG_REGF : out std_logic_vector(15 downto 0)

      );
  end component;


  component TESTFIFOS is
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

      -- PC FIFO signals
      pc_tx_fifo_rst     : out std_logic;
      pc_tx_fifo_rden    : out std_logic;
      pc_tx_fifo_dout    : in  std_logic_vector(15 downto 0);
      pc_tx_fifo_wrd_cnt : in  std_logic_vector(11 downto 0);
      pc_rx_fifo_rst     : out std_logic;
      pc_rx_fifo_rden    : out std_logic;
      pc_rx_fifo_dout    : in  std_logic_vector(15 downto 0);
      pc_rx_fifo_wrd_cnt : in  std_logic_vector(11 downto 0);

      -- DDU_TX/RX Fifo signals
      ddu_tx_fifo_rst     : out std_logic;
      ddu_tx_fifo_rden    : out std_logic;
      ddu_tx_fifo_dout    : in  std_logic_vector(15 downto 0);
      ddu_tx_fifo_wrd_cnt : in  std_logic_vector(11 downto 0);
      ddu_rx_fifo_rst     : out std_logic;
      ddu_rx_fifo_rden    : out std_logic;
      ddu_rx_fifo_dout    : in  std_logic_vector(15 downto 0);
      ddu_rx_fifo_wrd_cnt : in  std_logic_vector(11 downto 0);

      -- TFF (DCFEB test FIFOs)
      TFF_DOUT    : in std_logic_vector(15 downto 0);
      TFF_WRD_CNT : in std_logic_vector(11 downto 0);

      TFF_RST  : out std_logic_vector(NFEB downto 1);
      TFF_SEL  : out std_logic_vector(NFEB downto 1);
      TFF_RDEN : out std_logic_vector(NFEB downto 1)
      );
  end component;

  component SYSTEM_MON is
    port (
      OUTDATA : out std_logic_vector(15 downto 0);
      DTACK   : out std_logic;

      SLOWCLK : in std_logic;
      FASTCLK : in std_logic;
      RST     : in std_logic;

      DEVICE  : in std_logic;
      STROBE  : in std_logic;
      COMMAND : in std_logic_vector(9 downto 0);
      WRITER  : in std_logic;

      VP    : in std_logic;
      VN    : in std_logic;
      VAUXP : in std_logic_vector(15 downto 0);
      VAUXN : in std_logic_vector(15 downto 0)
      );
  end component;

  component LVDBMON is
    port (

      SLOWCLK   : in std_logic;
      RST       : in std_logic;
      PON_RESET : in std_logic;         -- Power on reset

      DEVICE  : in std_logic;
      STROBE  : in std_logic;
      COMMAND : in std_logic_vector(9 downto 0);
      WRITER  : in std_logic;

      INDATA  : in  std_logic_vector(15 downto 0);
      OUTDATA : out std_logic_vector(15 downto 0);

      DTACK : out std_logic;

      LVADCEN : out std_logic_vector(6 downto 0);
      ADCCLK  : out std_logic;
      ADCDATA : out std_logic;
      ADCIN   : in  std_logic;

      LVTURNON   : out std_logic_vector(8 downto 1);
      R_LVTURNON : in  std_logic_vector(8 downto 1);
      LOADON     : out std_logic;

      DIAGLVDB : out std_logic_vector(17 downto 0)
      );
  end component;

  component SYSTEM_TEST is
    port (
      CSP_SYSTEM_TEST_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);

      DEVICE  : in std_logic;
      COMMAND : in std_logic_vector(9 downto 0);
      INDATA  : in std_logic_vector(15 downto 0);
      STROBE  : in std_logic;
      WRITER  : in std_logic;
      SLOWCLK : in std_logic;
      CLK     : in std_logic;
      CLK160  : in std_logic;
      RST     : in std_logic;

      OUTDATA : out std_logic_vector(15 downto 0);
      DTACK   : out std_logic;

      -- DDU/PC/DCFEB COMMON PRBS
      PRBS_TYPE : out std_logic_vector(2 downto 0);

      -- DDU PRBS signals
      DDU_PRBS_EN      : out std_logic;
      DDU_PRBS_TST_CNT : out std_logic_vector(15 downto 0);
      DDU_PRBS_ERR_CNT : in  std_logic_vector(15 downto 0);

      -- PC PRBS signals
      PC_PRBS_EN      : out std_logic;
      PC_PRBS_TST_CNT : out std_logic_vector(15 downto 0);
      PC_PRBS_ERR_CNT : in  std_logic_vector(15 downto 0);

      -- DCFEB PRBS signals
      DCFEB_PRBS_FIBER_SEL : out std_logic_vector(3 downto 0);
      DCFEB_PRBS_EN        : out std_logic;
      DCFEB_PRBS_RST       : out std_logic;
      DCFEB_PRBS_RD_EN     : out std_logic;
      DCFEB_RXPRBSERR      : in  std_logic;
      DCFEB_PRBS_ERR_CNT   : in  std_logic_vector(15 downto 0);

      -- OTMB PRBS signals
      OTMB_TX : in  std_logic_vector(48 downto 0);
      OTMB_RX : out std_logic_vector(5 downto 0)
      );
  end component;

  component MBCJTAG is
    port (
      DEVICE    : in std_logic;
      COMMAND   : in std_logic_vector(9 downto 0);
      INDATA    : in std_logic_vector(15 downto 0);
      STROBE    : in std_logic;
      MBCTDO    : in std_logic;
      INITJTAGS : in std_logic;
      WRITER    : in std_logic;
      FASTCLK   : in std_logic;
      SLOWCLK   : in std_logic;
      RST       : in std_logic;

      OUTDATA : out std_logic_vector(15 downto 0);
      DTACK   : out std_logic;
      TDI     : out std_logic;
      TMS     : out std_logic;
      TCK     : out std_logic;
      LED     : out std_logic
      );
  end component;

  -- TD
  component BPI_PORT is
    
    port (
      CSP_BPI_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);
      
      CLK               : in  std_logic;  -- 40MHz clock
      RST               : in  std_logic;  -- system reset
      -- VME selection/control
      DEVICE            : in  std_logic;  -- 1 bit indicating this device has been selected
      STROBE            : in  std_logic;  -- Data strobe synchronized to rising or falling edge of clock and asynchronously cleared
      COMMAND           : in  std_logic_vector(9 downto 0);  -- command portion of VME address
      WRITE_B           : in  std_logic;  -- read/write_bar
      INDATA            : in  std_logic_vector(15 downto 0);  -- data from VME writes to be provided to BPI interface
      OUTDATA           : out std_logic_vector(15 downto 0);  -- data from BPI interface to VME buss for reads
      DTACK             : out std_logic;  -- DTACK bar
      -- BPI PORT signals
      BPI_RST           : out std_logic;  -- Resets BPI interface state machines
      BPI_CMD_FIFO_DATA : out std_logic_vector(15 downto 0);  -- Data for command FIFO
      BPI_WE            : out std_logic;  -- Command FIFO write enable  (pulse one clock cycle for one write)
      BPI_RE            : out std_logic;  -- Read back FIFO read enable  (pulse one clock cycle for one read)
      BPI_DSBL          : out std_logic;  -- Disable parsing of BPI commands in the command FIFO (while being filled)
      BPI_ENBL          : out std_logic;  -- Enable  parsing of BPI commands in the command FIFO
      BPI_CFG_DL        : out std_logic;  -- Download Configuration Regs in Flash PROM
      BPI_CFG_UL        : out std_logic;  -- Upload Configuration Regs from Flash PROM
      BPI_RBK_FIFO_DATA : in  std_logic_vector(15 downto 0);  -- Data on output of the Read back FIFO
      BPI_RBK_WRD_CNT   : in  std_logic_vector(10 downto 0);  -- Word count of the Read back FIFO (number of available reads)
      BPI_STATUS        : in  std_logic_vector(15 downto 0);  -- FIFO status bits and latest value of the PROM status register. 
      -- General timer
      BPI_TIMER         : in  std_logic_vector(31 downto 0);
-- Guido - Aug 26
      BPI_CFG_UL_PULSE  : out std_logic;
      BPI_CFG_DL_PULSE  : out std_logic;
--      BPI_CFG_DATA_SEL  : out std_logic;
      BPI_CFG_REG0      : in  std_logic_vector(15 downto 0);
      BPI_CFG_REG1      : in  std_logic_vector(15 downto 0);
      BPI_CFG_REG2      : in  std_logic_vector(15 downto 0);
      BPI_CFG_REG3      : in  std_logic_vector(15 downto 0);
      BPI_CFG_REG_IN    : out std_logic_vector(15 downto 0);
      BPI_CFG_REG_WE    : out std_logic_vector(3 downto 0);
      BPI_CFG_BUSY      : in  std_logic;
      BPI_DONE          : in  std_logic
      );
  end component;

  --component BPI_CFG_CONTROLLER is
  --  port(

  --    clk : in std_logic;
  --    rst : in std_logic;

  --    bpi_cfg_ul_start : in std_logic;
  --    bpi_cfg_dl_start : in std_logic;
  --    bpi_cfg_done     : in std_logic;
  --    bpi_cfg_reg0     : in std_logic_vector(15 downto 0);
  --    bpi_cfg_reg1     : in std_logic_vector(15 downto 0);
  --    bpi_cfg_reg2     : in std_logic_vector(15 downto 0);
  --    bpi_cfg_reg3     : in std_logic_vector(15 downto 0);

  --    bpi_dis          : out std_logic;
  --    bpi_en           : out std_logic;
  --    bpi_cfg_reg_we_i : in  std_logic;
  --    bpi_cfg_reg_we_o : out std_logic_vector(3 downto 0);
  --    bpi_cfg_busy     : out std_logic;
  --    bpi_cfg_data_sel : in  std_logic;
  --    bpi_cmd_fifo_we  : out std_logic;
  --    bpi_cmd_fifo_in  : out std_logic_vector(15 downto 0)
  --    );
  --end component;

  --component bpi_cfg_registers is
  --  port(
  --    clk : in std_logic;
  --    rst : in std_logic;

  --    bpi_cfg_reg_we : in std_logic_vector(3 downto 0);
  --    bpi_cfg_reg_in : in std_logic_vector(15 downto 0);

  --    bpi_cfg_reg0 : out std_logic_vector(15 downto 0);
  --    bpi_cfg_reg1 : out std_logic_vector(15 downto 0);
  --    bpi_cfg_reg2 : out std_logic_vector(15 downto 0);
  --    bpi_cfg_reg3 : out std_logic_vector(15 downto 0)
  --    );
  --end component;

  component BPI_CFG_CONTROLLER is
    port(

      clk : in std_logic;
      rst : in std_logic;

      bpi_cfg_ul_start : in std_logic;
      bpi_cfg_dl_start : in std_logic;
      bpi_cfg_done     : in std_logic;
      bpi_cfg_reg0     : in std_logic_vector(15 downto 0);
      bpi_cfg_reg1     : in std_logic_vector(15 downto 0);
      bpi_cfg_reg2     : in std_logic_vector(15 downto 0);
      bpi_cfg_reg3     : in std_logic_vector(15 downto 0);
      bpi_cfg_reg4     : in std_logic_vector(15 downto 0);
      bpi_cfg_reg5     : in std_logic_vector(15 downto 0);
      bpi_cfg_reg6     : in std_logic_vector(15 downto 0);
      bpi_cfg_reg7     : in std_logic_vector(15 downto 0);
      bpi_cfg_reg8     : in std_logic_vector(15 downto 0);
      bpi_cfg_reg9     : in std_logic_vector(15 downto 0);
      bpi_cfg_rega     : in std_logic_vector(15 downto 0);
      bpi_cfg_regb     : in std_logic_vector(15 downto 0);
      bpi_cfg_regc     : in std_logic_vector(15 downto 0);
      bpi_cfg_regd     : in std_logic_vector(15 downto 0);
      bpi_cfg_rege     : in std_logic_vector(15 downto 0);
      bpi_cfg_regf     : in std_logic_vector(15 downto 0);

      bpi_dis          : out std_logic;
      bpi_en           : out std_logic;
      bpi_cfg_reg_we_i : in  std_logic;
      bpi_cfg_reg_we_o : out std_logic_vector(15 downto 0);
      bpi_cfg_busy     : out std_logic;
--      bpi_cfg_data_sel : in  std_logic;
      bpi_cmd_fifo_we  : out std_logic;
      bpi_cmd_fifo_in  : out std_logic_vector(15 downto 0)
      );
  end component;

  component COMMAND_MODULE is
    port (
      FASTCLK : in std_logic;
      SLOWCLK : in std_logic;

      GA  : in std_logic_vector(5 downto 0);
      ADR : in std_logic_vector(23 downto 1);
      AM  : in std_logic_vector(5 downto 0);

      AS      : in std_logic;
      DS0     : in std_logic;
      DS1     : in std_logic;
      LWORD   : in std_logic;
      WRITER  : in std_logic;
      IACK    : in std_logic;
      BERR    : in std_logic;
      SYSFAIL : in std_logic;

      DEVICE  : out std_logic_vector(9 downto 0);
      STROBE  : out std_logic;
      COMMAND : out std_logic_vector(9 downto 0);
      ADRS    : out std_logic_vector(17 downto 2);

      TOVME_B : out std_logic;
      DOE_B   : out std_logic;

      DIAGOUT : out std_logic_vector(19 downto 0);
      LED     : out std_logic_vector(2 downto 0)
      );
  end component;

  component vme_outdata_sel is
    port (
      device          : in  std_logic_vector(9 downto 0);
      device0_outdata : in  std_logic_vector(15 downto 0);
      device1_outdata : in  std_logic_vector(15 downto 0);
      device2_outdata : in  std_logic_vector(15 downto 0);
      device3_outdata : in  std_logic_vector(15 downto 0);
      device4_outdata : in  std_logic_vector(15 downto 0);
      device5_outdata : in  std_logic_vector(15 downto 0);
      device6_outdata : in  std_logic_vector(15 downto 0);
      device7_outdata : in  std_logic_vector(15 downto 0);
      device8_outdata : in  std_logic_vector(15 downto 0);
      device9_outdata : in  std_logic_vector(15 downto 0);
      outdata         : out std_logic_vector(15 downto 0)
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

  constant LOGICH : std_logic := '1';
  constant LOGICL : std_logic := '0';

  signal ext_vme_ga : std_logic_vector(5 downto 0);

  signal device         : std_logic_vector(9 downto 0);
  signal cmd            : std_logic_vector(9 downto 0);
  signal strobe         : std_logic;
  signal tovme_b, doe_b : std_logic;

  signal diagout_command : std_logic_vector(19 downto 0);
  signal led_command     : std_logic_vector(2 downto 0);

  signal outdata_cfebjtag : std_logic_vector(15 downto 0);
  signal led_cfebjtag     : std_logic;

  signal outdata_odmbjtag : std_logic_vector(15 downto 0);
  signal led_odmbjtag     : std_logic;

  signal outdata_mbcjtag : std_logic_vector(15 downto 0);
  signal led_mbcjtag     : std_logic;

  signal outdata_lvdbmon : std_logic_vector(15 downto 0);


  signal outdata_vmemon      : std_logic_vector(15 downto 0);
  signal outdata_vmeconfregs : std_logic_vector(15 downto 0);
  signal outdata_testfifos   : std_logic_vector(15 downto 0);
  signal outdata_sysmon      : std_logic_vector(15 downto 0);
  signal outdata_bpi_port    : std_logic_vector(15 downto 0);

  signal outdata_testctrl : std_logic_vector(15 downto 0);
  signal outdata_systest  : std_logic_vector(15 downto 0);

  signal test_reg0 : std_logic_vector(15 downto 0) := x"fff0";
  signal test_reg1 : std_logic_vector(15 downto 0) := x"fff1";
  signal test_reg2 : std_logic_vector(15 downto 0) := x"fff2";
  signal test_reg3 : std_logic_vector(15 downto 0) := x"fff3";

  signal cfg_reg0 : std_logic_vector(15 downto 0) := x"ff00";
  signal cfg_reg1 : std_logic_vector(15 downto 0) := x"ff01";
  signal cfg_reg2 : std_logic_vector(15 downto 0) := x"ff02";
  signal cfg_reg3 : std_logic_vector(15 downto 0) := x"ff03";
  signal cfg_reg4 : std_logic_vector(15 downto 0) := x"ff04";
  signal cfg_reg5 : std_logic_vector(15 downto 0) := x"ff05";
  signal cfg_reg6 : std_logic_vector(15 downto 0) := x"ff06";
  signal cfg_reg7 : std_logic_vector(15 downto 0) := x"ff07";
  signal cfg_reg8 : std_logic_vector(15 downto 0) := x"ff08";
  signal cfg_reg9 : std_logic_vector(15 downto 0) := x"ff09";
  signal cfg_rega : std_logic_vector(15 downto 0) := x"ff0a";
  signal cfg_regb : std_logic_vector(15 downto 0) := x"ff0b";
  signal cfg_regc : std_logic_vector(15 downto 0) := x"ff0c";
  signal cfg_regd : std_logic_vector(15 downto 0) := x"ff0d";
  signal cfg_rege : std_logic_vector(15 downto 0) := x"ff0e";
  signal cfg_regf : std_logic_vector(15 downto 0) := x"ff0f";

  signal vme_bpi_cmd_fifo_data, cc_bpi_cmd_fifo_data : std_logic_vector(15 downto 0);
  signal vme_bpi_we, cc_bpi_we                       : std_logic;
  signal vme_bpi_dsbl, cc_bpi_dsbl                   : std_logic;
  signal vme_bpi_enbl, cc_bpi_enbl                   : std_logic;
  signal bpi_cfg_dl                                  : std_logic                    := '0';
  signal bpi_cfg_ul                                  : std_logic                    := '0';
  signal bpi_cfg_reg_we_vec                          : std_logic_vector(3 downto 0) := "0000";
  signal bpi_cfg_ul_pulse, bpi_cfg_dl_pulse          : std_logic;  -- TD
  signal bpi_cfg_busy                                : std_logic;
--  signal bpi_cfg_data_sel                            : std_logic;

-- TD
  signal VME_BPI_CFG_REG_IN     : std_logic_vector(15 downto 0);
  signal VME_BPI_CFG_REG_WE_VEC : std_logic_vector(3 downto 0);
  signal CC_BPI_CFG_REG_IN      : std_logic_vector(15 downto 0);
  signal CC_BPI_CFG_REG_WE_VEC  : std_logic_vector(15 downto 0);
  signal SEL_BPI_CFG_REG_IN     : std_logic_vector(15 downto 0);

  signal dtack_dev : std_logic_vector(9 downto 0);

begin

  DEV0_TESTCTRL : TESTCTRL
    generic map (NFEB => NFEB)
    port map (
      CLK     => clk,
      DDUCLK  => dduclk,
      SLOWCLK => clk_s2,
      RST     => rst,

      DEVICE  => device(0),
      STROBE  => strobe,
      COMMAND => cmd,

      INDATA  => vme_data_in,
      OUTDATA => outdata_testctrl,

      DTACK => dtack_dev(0),

      L1A            => TC_L1A,
      ALCT_DAV       => TC_ALCT_DAV,
      OTMB_DAV       => TC_OTMB_DAV,
      LCT            => TC_LCT,
      DDU_DATA       => DDU_DATA,
      DDU_DATA_VALID => DDU_DATA_VALID,
      TC_RUN         => TC_RUN,
      TS_OUT         => TS_OUT
      );

  DEV1_CFEBJTAG : CFEBJTAG
    port map (
      FASTCLK => clk,
      SLOWCLK => clk_s2,
      RST     => rst,
      DEVICE  => device(1),
      STROBE  => strobe,
      COMMAND => cmd,
      WRITER  => vme_write_b,

      INDATA  => vme_data_in,
      OUTDATA => outdata_cfebjtag,

      DTACK => dtack_dev(1),

      INITJTAGS => '0',                 -- to be defined
      TCK       => dl_jtag_tck,
      TDI       => dl_jtag_tdi,
      TMS       => dl_jtag_tms,
      FEBTDO    => dl_jtag_tdo,

      DIAGOUT => diagout_cfebjtag,
      LED     => led_cfebjtag
      );

  DEV2_ODMBJTAG : ODMBJTAG
    port map (
      FASTCLK => clk,
      SLOWCLK => clk_s2,
      RST     => rst,

      DEVICE  => device(2),
      STROBE  => strobe,
      COMMAND => cmd,
      WRITER  => vme_write_b,

      INDATA  => vme_data_in,
      OUTDATA => outdata_odmbjtag,

      DTACK => dtack_dev(2),

      INITJTAGS => '0',                 -- to be defined
      TCK       => odmb_jtag_tck,
      TDI       => odmb_jtag_tdi,
      TMS       => odmb_jtag_tms,
      ODMBTDO   => odmb_jtag_tdo,

      JTAGSEL => odmb_jtag_sel,

      LED => led_odmbjtag
      );


  DEV3_VMEMON : VMEMON
    generic map (NFEB => NFEB)
    port map (
      SLOWCLK => clk_s2,
      CLK40   => clk,
      RST     => rst,

      DEVICE  => device(3),
      STROBE  => strobe,
      COMMAND => cmd,
      WRITER  => vme_write_b,

      INDATA  => vme_data_in,
      OUTDATA => outdata_vmemon,

      DTACK => dtack_dev(3),

      DCFEB_DONE => dcfeb_done,

      OPT_RESET_PULSE => opt_reset_pulse,
      L1A_RESET_PULSE => l1a_reset_pulse,
      FW_RESET        => fw_reset,
      REPROG_B        => reprog_b,
      TEST_INJ        => test_inj,
      TEST_PLS        => test_pls,
      TEST_PED        => test_ped,
      TEST_LCT        => test_lct,
      OTMB_LCT_RQST   => otmb_lct_rqst,
      OTMB_EXT_TRIG   => otmb_ext_trig,

      TP_SEL        => tp_sel,
      ODMB_CTRL     => odmb_ctrl,
      DCFEB_CTRL    => dcfeb_ctrl,
      ODMB_DATA_SEL => odmb_data_sel,
      ODMB_DATA     => odmb_data,
      TXDIFFCTRL    => txdiffctrl,      -- Controls the TX voltage swing
      LOOPBACK      => loopback         -- For internal loopback tests
      );


  DEV4_VMECONFREGS : VMECONFREGS
    port map (
      SLOWCLK => CLK_S2,
      CLK     => clk,
      RST     => RST,

      DEVICE  => DEVICE(4),
      STROBE  => STROBE,
      COMMAND => CMD,
      WRITER  => VME_WRITE_B,

      INDATA  => VME_DATA_IN,
      OUTDATA => OUTDATA_VMECONFREGS,

      DTACK         => DTACK_DEV(4),
      ALCT_PUSH_DLY => ALCT_PUSH_DLY,
      OTMB_PUSH_DLY => OTMB_PUSH_DLY,
      PUSH_DLY      => PUSH_DLY,
      LCT_L1A_DLY   => LCT_L1A_DLY,

      INJ_DLY    => INJ_DLY,
      EXT_DLY    => EXT_DLY,
      CALLCT_DLY => CALLCT_DLY,

      NWORDS_DUMMY => NWORDS_DUMMY,
      KILL         => KILL,
      CRATEID      => CRATEID,

      -- From BPI_PORT
      BPI_CFG_UL_PULSE => bpi_cfg_ul_pulse,
      BPI_CFG_DL_PULSE => bpi_cfg_dl_pulse,

-- From BPI_CFG_CONTROLLER
      CC_CFG_REG_IN => CC_BPI_CFG_REG_IN,
      CC_CFG_REG_WE => CC_BPI_CFG_REG_WE_VEC,

-- To BPI_CFG_CONTROLLER
      CFG_REG0 => CFG_REG0,
      CFG_REG1 => CFG_REG1,
      CFG_REG2 => CFG_REG2,
      CFG_REG3 => CFG_REG3,
      CFG_REG4 => CFG_REG4,
      CFG_REG5 => CFG_REG5,
      CFG_REG6 => CFG_REG6,
      CFG_REG7 => CFG_REG7,
      CFG_REG8 => CFG_REG8,
      CFG_REG9 => CFG_REG9,
      CFG_REGA => CFG_REGa,
      CFG_REGB => CFG_REGb,
      CFG_REGC => CFG_REGc,
      CFG_REGD => CFG_REGd,
      CFG_REGE => CFG_REGe,
      CFG_REGF => CFG_REGf
      );


  DEV5_TESTFIFOS : TESTFIFOS
    port map (
      SLOWCLK => CLK_S2,
      RST     => RST,
      CLK40   => CLK,

      DEVICE  => DEVICE(5),
      STROBE  => STROBE,
      COMMAND => CMD,
      WRITER  => VME_WRITE_B,

      INDATA  => VME_DATA_IN,
      OUTDATA => OUTDATA_TESTFIFOS,

      DTACK => DTACK_DEV(5),

      -- ALCT/OTMB FIFO signals
      alct_fifo_data_in    => alct_fifo_data_in,
      alct_fifo_data_valid => alct_fifo_data_valid,
      otmb_fifo_data_in    => otmb_fifo_data_in,
      otmb_fifo_data_valid => otmb_fifo_data_valid,

      -- PC FIFO signals
      pc_tx_fifo_rst     => pc_tx_fifo_rst,
      pc_tx_fifo_rden    => pc_tx_fifo_rden,
      pc_tx_fifo_dout    => pc_tx_fifo_dout,
      pc_tx_fifo_wrd_cnt => pc_tx_fifo_wrd_cnt,
      pc_rx_fifo_rst     => pc_rx_fifo_rst,
      pc_rx_fifo_rden    => pc_rx_fifo_rden,
      pc_rx_fifo_dout    => pc_rx_fifo_dout,
      pc_rx_fifo_wrd_cnt => pc_rx_fifo_wrd_cnt,

      -- DDU_TX/RX Fifo signals
      ddu_tx_fifo_rst     => ddu_tx_fifo_rst,
      ddu_tx_fifo_rden    => ddu_tx_fifo_rden,
      ddu_tx_fifo_dout    => ddu_tx_fifo_dout,
      ddu_tx_fifo_wrd_cnt => ddu_tx_fifo_wrd_cnt,
      ddu_rx_fifo_rst     => ddu_rx_fifo_rst,
      ddu_rx_fifo_rden    => ddu_rx_fifo_rden,
      ddu_rx_fifo_dout    => ddu_rx_fifo_dout,
      ddu_rx_fifo_wrd_cnt => ddu_rx_fifo_wrd_cnt,

      -- TFF (DCFEB test FIFOs)
      TFF_DOUT    => TFF_DOUT,
      TFF_WRD_CNT => TFF_WRD_CNT,
      TFF_RST     => TFF_RST,
      TFF_SEL     => TFF_SEL,
      TFF_RDEN    => TFF_RDEN

      );

  -- TD
  DEV6_BPI_PORT : BPI_PORT
    port map (
      CSP_BPI_PORT_LA_CTRL => CSP_BPI_PORT_LA_CTRL,

      CLK               => clk,         -- 2.5MHz clock
      RST               => rst,         -- system reset
      -- VME selection/control
      DEVICE            => device(6),  -- 1 bit indicating this device has been selected
      STROBE            => strobe,  -- Data strobe synchronized to rising or falling edge of clock and asynchronously cleared
      COMMAND           => cmd,         -- command portionn of VME address
      WRITE_B           => vme_write_b,  -- read/write_bar
      INDATA            => vme_data_in,  -- data from VME writes to be provided to BPI interface
      OUTDATA           => outdata_bpi_port,  -- data from BPI interface to VME buss for reads
      DTACK             => dtack_dev(6),  -- DTACK bar
      -- BPI controls
      BPI_RST           => BPI_RST,     -- Resets BPI interface state machines
      BPI_CMD_FIFO_DATA => VME_BPI_CMD_FIFO_DATA,   -- Data for command FIFO
      BPI_WE            => VME_BPI_WE,  -- Command FIFO write enable  (pulse one clock cycle for one write)
      BPI_RE            => BPI_RE,  -- Read back FIFO read enable  (pulse one clock cycle for one read)
      BPI_DSBL          => VME_BPI_DSBL,  -- Disable parsing of BPI commands in the command FIFO (while being filled)
      BPI_ENBL          => VME_BPI_ENBL,  -- Enable  parsing of BPI commands in the command FIFO
      BPI_CFG_DL        => BPI_CFG_DL,  -- Download Configuration Regs in Flash PROM
      BPI_CFG_UL        => BPI_CFG_UL,  -- Upload Configuration Regs from Flash PROM
      BPI_RBK_FIFO_DATA => BPI_RBK_FIFO_DATA,  -- Data on output of the Read back FIFO
      BPI_RBK_WRD_CNT   => BPI_RBK_WRD_CNT,  -- Word count of the Read back FIFO (number of available reads)
      BPI_STATUS        => BPI_STATUS,  -- FIFO status bits and latest value of the PROM status register. 
      BPI_TIMER         => BPI_TIMER,   -- General timer
-- Guido - Aug 26
      BPI_CFG_UL_PULSE  => bpi_cfg_ul_pulse,  -- TD
      BPI_CFG_DL_PULSE  => bpi_cfg_dl_pulse,
--      BPI_CFG_DATA_SEL  => BPI_CFG_DATA_SEL,  -- CFG_REG values into PROM: 0 -> constants stored in CFG_CONTROLLER, 1 -> CFG_REG values
      BPI_CFG_REG0      => CFG_REG0,
      BPI_CFG_REG1      => CFG_REG1,
      BPI_CFG_REG2      => CFG_REG2,
      BPI_CFG_REG3      => CFG_REG3,
      BPI_CFG_REG_IN    => VME_BPI_CFG_REG_IN,      -- not used any more
      BPI_CFG_REG_WE    => VME_BPI_CFG_REG_WE_VEC,  -- not used any more
      BPI_CFG_BUSY      => BPI_CFG_BUSY,
      BPI_DONE          => BPI_CFG_DONE
      );

  DEV7_SYSMON : SYSTEM_MON
    port map(
      OUTDATA => outdata_sysmon,
      DTACK   => dtack_dev(7),

      SLOWCLK => clk_s2,
      FASTCLK => clk,
      RST     => rst,

      DEVICE  => device(7),
      STROBE  => strobe,
      COMMAND => cmd,
      WRITER  => vme_write_b,

      VP    => VP,
      VN    => VN,
      VAUXP => VAUXP,
      VAUXN => VAUXN
      );

  DEV8_LVDBMON : LVDBMON
    port map(
      SLOWCLK   => clk_s2,
      RST       => rst,
      PON_RESET => pon_reset,

      DEVICE  => device(8),
      STROBE  => strobe,
      COMMAND => cmd,
      WRITER  => vme_write_b,

      INDATA  => vme_data_in,
      OUTDATA => outdata_lvdbmon,

      DTACK => dtack_dev(8),

      LVADCEN => lvmb_csb,
      ADCCLK  => lvmb_sclk,
      ADCDATA => lvmb_sdin,
      ADCIN   => lvmb_sdout,

      LVTURNON   => lvmb_pon,
      R_LVTURNON => r_lvmb_pon,
      LOADON     => pon_load,

      DIAGLVDB => diagout_lvdbmon

      );

  DEV9_SYSTEST : SYSTEM_TEST
    port map (
      CSP_SYSTEM_TEST_PORT_LA_CTRL => CSP_SYSTEM_TEST_PORT_LA_CTRL,

      DEVICE  => device(9),
      COMMAND => cmd,
      INDATA  => vme_data_in,
      STROBE  => strobe,
      WRITER  => vme_write_b,
      SLOWCLK => clk_s2,
      CLK     => clk,
      CLK160  => clk_s3,
      RST     => rst,

      OUTDATA => outdata_systest,
      DTACK   => dtack_dev(9),

      -- DDU/PC/DCFEB COMMON PRBS
      PRBS_TYPE => PRBS_TYPE,

      -- DDU PRBS signals
      DDU_PRBS_EN      => DDU_PRBS_EN,
      DDU_PRBS_TST_CNT => DDU_PRBS_TST_CNT,
      DDU_PRBS_ERR_CNT => DDU_PRBS_ERR_CNT,

      -- PC PRBS signals
      PC_PRBS_EN      => PC_PRBS_EN,
      PC_PRBS_TST_CNT => PC_PRBS_TST_CNT,
      PC_PRBS_ERR_CNT => PC_PRBS_ERR_CNT,

      -- DCFEB PRBS signals
      DCFEB_PRBS_FIBER_SEL => DCFEB_PRBS_FIBER_SEL,
      DCFEB_PRBS_EN        => DCFEB_PRBS_EN,
      DCFEB_PRBS_RST       => DCFEB_PRBS_RST,
      DCFEB_PRBS_RD_EN     => DCFEB_PRBS_RD_EN,
      DCFEB_RXPRBSERR      => DCFEB_RXPRBSERR,
      DCFEB_PRBS_ERR_CNT   => DCFEB_PRBS_ERR_CNT,

      --OTMB_PRBS signals
      OTMB_TX => OTMB_TX,
      OTMB_RX => OTMB_RX
      );

  DEVX_MBCJTAG : MBCJTAG
    port map (
      FASTCLK => clk,
      SLOWCLK => clk_s2,
      RST     => rst,
      DEVICE  => LOGICL,
      STROBE  => strobe,
      COMMAND => cmd,
      WRITER  => vme_write_b,

      INDATA  => vme_data_in,
      OUTDATA => outdata_mbcjtag,

      DTACK => open,

      INITJTAGS => '0',                 -- to be defined
      TCK       => mbc_jtag_tck,
      TDI       => mbc_jtag_tdi,
      TMS       => mbc_jtag_tms,
      MBCTDO    => mbc_jtag_tdo,

      LED => led_mbcjtag
      );

  COMMAND_PM : COMMAND_MODULE
    port map (
      FASTCLK => clk,
      SLOWCLK => clk_s2,

      GA  => ext_vme_ga,                -- gap = ga(5)
      ADR => vme_addr,
      AM  => vme_am,

      AS      => vme_as_b,
      DS0     => vme_ds_b(0),
      DS1     => vme_ds_b(1),
      LWORD   => vme_lword_b,
      WRITER  => vme_write_b,
      IACK    => vme_iack_b,
      BERR    => vme_berr_b,
      SYSFAIL => vme_sysfail_b,

      TOVME_B => tovme_b,
      DOE_B   => doe_b,

      DEVICE  => device,
      STROBE  => strobe,
      COMMAND => cmd,
      ADRS    => cmd_adrs,

      DIAGOUT => diagout_command,
      LED     => led_command
      );

  VME_OUT_SEL_PM : vme_outdata_sel
    port map (
      device          => device,
      device0_outdata => outdata_testctrl,
      device1_outdata => outdata_cfebjtag,
      device2_outdata => outdata_odmbjtag,
      device3_outdata => outdata_vmemon,
      device4_outdata => outdata_vmeconfregs,
      device5_outdata => outdata_testfifos,
      device6_outdata => outdata_bpi_port,
      device7_outdata => outdata_sysmon,
      device8_outdata => outdata_lvdbmon,
      device9_outdata => outdata_systest,
      outdata         => vme_data_out
      );

  PULSE_LED : PULSE_EDGE port map(led_pulse, open, clk_s3, rst, 200000, strobe);

  --BPI_CR_PM : BPI_CFG_REGISTERS
  --  port map (
  --    clk => clk_s2,
  --    rst => rst,

  --    bpi_cfg_reg_we => BPI_CFG_REG_WE_VEC,
  --    bpi_cfg_reg_in => BPI_CFG_REG_IN,

  --    bpi_cfg_reg0 => CFG_REG0,
  --    bpi_cfg_reg1 => CFG_REG1,
  --    bpi_cfg_reg2 => CFG_REG2,
  --    bpi_cfg_reg3 => CFG_REG3
  --    );

  --BPI_CC_PM : BPI_CFG_CONTROLLER
  --  port map (
  --    CLK => clk_s2,
  --    RST => rst,

  --    bpi_cfg_dl_start => BPI_CFG_DL,
  --    bpi_cfg_ul_start => BPI_CFG_UL,
  --    bpi_cfg_done     => BPI_CFG_DONE,
  --    bpi_cfg_reg0     => CFG_REG0,
  --    bpi_cfg_reg1     => CFG_REG1,
  --    bpi_cfg_reg2     => CFG_REG2,
  --    bpi_cfg_reg3     => CFG_REG3,

  --    bpi_dis          => CC_BPI_DSBL,
  --    bpi_en           => CC_BPI_ENBL,
  --    bpi_cfg_reg_we_i => BPI_CFG_REG_WE,
  --    bpi_cfg_reg_we_o => BPI_CFG_REG_WE_VEC,
  --    bpi_cfg_busy     => BPI_CFG_BUSY,
  --    bpi_cfg_data_sel => BPI_CFG_DATA_SEL,
  --    bpi_cmd_fifo_we  => CC_BPI_WE,
  --    bpi_cmd_fifo_in  => CC_BPI_CMD_FIFO_DATA
  --    );

  CC_BPI_CFG_REG_IN <= BPI_CFG_REG_IN;

  BPI_CC_PM : BPI_CFG_CONTROLLER
    port map (
      --CLK => clk_s2,
      CLK => clk,
      RST => rst,

      bpi_cfg_dl_start => BPI_CFG_DL,
      bpi_cfg_ul_start => BPI_CFG_UL,
      bpi_cfg_done     => BPI_CFG_DONE,
      bpi_cfg_reg0     => CFG_REG0,
      bpi_cfg_reg1     => CFG_REG1,
      bpi_cfg_reg2     => CFG_REG2,
      bpi_cfg_reg3     => CFG_REG3,
      bpi_cfg_reg4     => CFG_REG4,
      bpi_cfg_reg5     => CFG_REG5,
      bpi_cfg_reg6     => CFG_REG6,
      bpi_cfg_reg7     => CFG_REG7,
      bpi_cfg_reg8     => CFG_REG8,
      bpi_cfg_reg9     => CFG_REG9,
      bpi_cfg_rega     => CFG_REGa,
      bpi_cfg_regb     => CFG_REGb,
      bpi_cfg_regc     => CFG_REGc,
      bpi_cfg_regd     => CFG_REGd,
      bpi_cfg_rege     => CFG_REGe,
      bpi_cfg_regf     => CFG_REGf,

      bpi_dis          => CC_BPI_DSBL,
      bpi_en           => CC_BPI_ENBL,
      bpi_cfg_reg_we_i => BPI_CFG_REG_WE,
      bpi_cfg_reg_we_o => CC_BPI_CFG_REG_WE_VEC,
      bpi_cfg_busy     => BPI_CFG_BUSY,
--      bpi_cfg_data_sel => BPI_CFG_DATA_SEL,
      bpi_cmd_fifo_we  => CC_BPI_WE,
      bpi_cmd_fifo_in  => CC_BPI_CMD_FIFO_DATA
      );


  BPI_CMD_FIFO_DATA <= VME_BPI_CMD_FIFO_DATA when (RST = '0' and BPI_CFG_UL_PULSE = '0' and BPI_CFG_DL_PULSE = '0') else CC_BPI_CMD_FIFO_DATA;
  BPI_WE            <= VME_BPI_WE            when (RST = '0' and BPI_CFG_UL_PULSE = '0' and BPI_CFG_DL_PULSE = '0') else CC_BPI_WE;
  BPI_DSBL          <= VME_BPI_DSBL          when (RST = '0' and BPI_CFG_UL_PULSE = '0' and BPI_CFG_DL_PULSE = '0') else CC_BPI_DSBL;
  BPI_ENBL          <= VME_BPI_ENBL          when (RST = '0' and BPI_CFG_UL_PULSE = '0' and BPI_CFG_DL_PULSE = '0') else CC_BPI_ENBL;
  
  BPI_CFG_UL_BUGGER <= bpi_cfg_ul_pulse;
  BPI_CFG_DL_BUGGER <= bpi_cfg_dl_pulse;
  
  vme_doe_b       <= doe_b;
  vme_doe         <= not doe_b;
  vme_tovme_b     <= tovme_b;
  vme_tovme       <= not tovme_b;
  vme_sysfail_out <= '0';
  vme_berr_out    <= '0';
  vme_sysfail_out <= '0';
  ext_vme_ga      <= vme_gap & vme_ga;

-- From/To LVMB
  pon_oe_b <= '0';

  vme_dtack_b <= not (dtack_dev(0) or dtack_dev(1) or dtack_dev(2) or
                      dtack_dev(3) or dtack_dev(4) or dtack_dev(5) or
                      dtack_dev(6) or dtack_dev(7) or dtack_dev(8) or
                      dtack_dev(9));



end ODMB_VME_architecture;

