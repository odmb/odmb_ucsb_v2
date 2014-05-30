----------------------------------------------------------------------------------
-- Company: UCSB
-- Engineer/Physicists: Guido Magazzu, Frank Golf, Manuel Franco Sevilla, David Nash
--                      Tom Danielson, Adam Dishaw, Jack Bradmiller-Feld
--
-- Create Date:     03/03/2013
-- Project Name:    ODMB_UCSB_V2
-- Target Devices:  Virtex-6
-- Tool versions:   ISE 12.3
-- Description:     Official firmware for the ODMB.V2
----------------------------------------------------------------------------------

library work;
library ieee;
library work;
library unisim;
library unimacro;
library hdlmacro;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.ucsb_types.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use hdlmacro.hdlmacro.all;

entity ODMB_UCSB_V2 is
  generic (
    IS_SIMULATION : integer range 0 to 1 := 0;  -- Set to 1 by test bench in simulation 
    NFEB          : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );  
  port (

-- From/To VME connector To/From MBV

    vme_data        : inout std_logic_vector(15 downto 0);
    vme_addr        : in    std_logic_vector(23 downto 1);
    vme_am          : in    std_logic_vector(5 downto 0);
    vme_gap         : in    std_logic;
    vme_ga          : in    std_logic_vector(4 downto 0);
    --vme_bg0         : in    std_logic;
    --vme_bg1         : in    std_logic;
    --vme_bg2         : in    std_logic;
    --vme_bg3         : in    std_logic;
    vme_as_b        : in    std_logic;
    vme_ds_b        : in    std_logic_vector(1 downto 0);
    --vme_sysreset_b  : in    std_logic;
    vme_sysfail_b   : in    std_logic;
    vme_sysfail_out : out   std_logic;
    vme_berr_b      : in    std_logic;
    vme_berr_out    : out   std_logic;
    vme_iack_b      : in    std_logic;
    vme_lword_b     : in    std_logic;
    vme_write_b     : in    std_logic;
    --vme_clk         : in    std_logic;
    vme_dtack_v6_b  : inout std_logic;
    vme_tovme       : out   std_logic;  -- not (tovme)
    vme_doe_b       : out   std_logic;

    tc_run_out : out std_logic;         -- OK           NEW!

-- BPI Prom signals To/From bpi_interface

    prom_a        : inout std_logic_vector(22 downto 0);
    prom_a_21_rs0 : out   std_logic;    -- not connected in v.2
    prom_a_22_rs1 : out   std_logic;    -- not connected in v.2
    prom_d        : inout std_logic_vector(15 downto 0);
    prom_cs_b     : out   std_logic;
    prom_oe_b     : out   std_logic;
    prom_we_b     : out   std_logic;
    prom_le_b     : out   std_logic;

-- From/To PPIB (connectors J3 and J4)

    dcfeb_tck       : out   std_logic_vector(NFEB downto 1);
    dcfeb_tms       : inout std_logic;
    dcfeb_tdi       : inout std_logic;
    dcfeb_tdo       : in    std_logic_vector(NFEB downto 1);
    dcfeb_bc0       : out   std_logic;
    dcfeb_resync    : out   std_logic;
    odmb_hardrst_b  : out   std_logic;  -- Generates REPROG_B
    dcfeb_reprgen_b : out   std_logic;
    dcfeb_injpls    : out   std_logic;
    dcfeb_extpls    : out   std_logic;
    dcfeb_l1a       : out   std_logic;
    dcfeb_l1a_match : out   std_logic_vector(NFEB downto 1);
    dcfeb_done      : in    std_logic_vector(NFEB downto 1);

-- From/To odmb_ucsb_v2 JTAG port (through IC34)

    v6_tck      : out std_logic;
    v6_tms      : out std_logic;
    v6_tdi      : out std_logic;
    v6_jtag_sel : out std_logic;

    --odmb_tms : in std_logic;
    --odmb_tdi : in std_logic;
    odmb_tdo : in std_logic;

-- From/To J6 (J3) connector to ODMB_CTRL

    ccb_cmd      : in  std_logic_vector(5 downto 0);
    ccb_cmd_s    : in  std_logic;
    ccb_data     : in  std_logic_vector(7 downto 0);
    ccb_data_s   : in  std_logic;
    ccb_cal      : in  std_logic_vector(2 downto 0);
    ccb_crsv     : in  std_logic_vector(4 downto 0);
    ccb_drsv     : in  std_logic_vector(1 downto 0);
    ccb_rsvo     : in  std_logic_vector(4 downto 0);
    ccb_rsvi     : out std_logic_vector(2 downto 0);
    ccb_bx0      : in  std_logic;
    ccb_bxrst    : in  std_logic;
    ccb_l1arst   : in  std_logic;
    ccb_l1acc    : in  std_logic;
    ccb_l1rls    : out std_logic;
    ccb_clken    : in  std_logic;
    ccb_evcntres : in  std_logic;

    ccb_hardrst : in std_logic;
    ccb_softrst : in std_logic;

-- From J6/J7 (J3/J4) to FIFOs

    otmb   : in std_logic_vector(17 downto 0);
    alct   : in std_logic_vector(17 downto 0);
    rawlct : in std_logic_vector(NFEB downto 0);
    --otmbffclk : in std_logic;

-- From/To J3/J4 t/fromo ODMB_CTRL

    otmbdav   : in  std_logic;          --  lctdav1
    alctdav   : in  std_logic;          --  lctdav2
--    rsvtd : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);     
    rsvtd_in  : in  std_logic_vector(2 downto 0);  -- rsvt_in(1:2) are rawlct(6:7) 
    rsvtd_out : out std_logic_vector(2 downto 0);
    lctrqst   : out std_logic_vector(2 downto 1);

-- From/To QPLL (From/To DAQMBV)

    qpll_autorestart : out std_logic;
    qpll_reset       : out std_logic;
    --qpll_f0sel       : in  std_logic_vector(3 downto 0);
    qpll_locked      : in  std_logic;
    qpll_error       : in  std_logic;
    qpll_clk40MHz_p  : in  std_logic;
    qpll_clk40MHz_n  : in  std_logic;
    --qpll_clk80MHz_p  : in  std_logic;
    --qpll_clk80MHz_n  : in  std_logic;
    qpll_clk160MHz_p : in  std_logic;
    qpll_clk160MHz_n : in  std_logic;

-- From/To LVMB (From/To DAQMBV and DAQMBC)

    lvmb_pon   : out std_logic_vector(7 downto 0);
    pon_load   : out std_logic;
    pon_en_b   : out std_logic;
    r_lvmb_pon : in  std_logic_vector(7 downto 0);
    lvmb_csb   : out std_logic_vector(6 downto 0);
    lvmb_sclk  : out std_logic;
    lvmb_sdin  : out std_logic;
    lvmb_sdout : in  std_logic;

-- To LEDs

    ledg : out std_logic_vector(6 downto 1);
    ledr : out std_logic_vector(6 downto 1);

-- From Push Buttons

    pb : in std_logic_vector(1 downto 0);

-- From/To Test Connector for Single-Ended signals

    d : out std_logic_vector(63 downto 0);

-- From/To Test Points

    test_point : out std_logic_vector(50 downto 13);

-- From/To RX 

    orx_p     : in  std_logic_vector(12 downto 1);
    orx_n     : in  std_logic_vector(12 downto 1);
    orx_rx_en : out std_logic;
    orx_en_sd : out std_logic;
    orx_sd    : in  std_logic;
    orx_sq_en : out std_logic;

-- From/To OT1 (GigaBit Link)

    gl0_tx_p  : out std_logic;
    gl0_tx_n  : out std_logic;
    gl0_rx_p  : in  std_logic;
    gl0_rx_n  : in  std_logic;
    gl0_clk_p : in  std_logic;
    gl0_clk_n : in  std_logic;

-- From/To OT2 (GigaBit Link)

    gl1_tx_p  : out std_logic;
    gl1_tx_n  : out std_logic;
    gl1_rx_p  : in  std_logic;
    gl1_rx_n  : in  std_logic;
    gl1_clk_p : in  std_logic;
    gl1_clk_n : in  std_logic;

-- From IC31 

    done_in : in std_logic;

    -- To SYSMON
    p1v0_sm_p     : in std_logic;
    p1v0_sm_n     : in std_logic;
    p2v5_sm_p     : in std_logic;
    p2v5_sm_n     : in std_logic;
    lv_p3v3_sm_p  : in std_logic;
    lv_p3v3_sm_n  : in std_logic;
    p5v_sm_p      : in std_logic;
    p5v_sm_n      : in std_logic;
    p5v_lvmb_sm_p : in std_logic;
    p5v_lvmb_sm_n : in std_logic;
    p3v3_pp_sm_p  : in std_logic;
    p3v3_pp_sm_n  : in std_logic;
    therm1_p      : in std_logic;
    therm1_n      : in std_logic;
    therm2_p      : in std_logic;
    therm2_n      : in std_logic;

    otmb_tx_tb : in std_logic_vector(48 downto 0)
    );
end ODMB_UCSB_V2;

architecture ODMB_UCSB_V2_ARCH of ODMB_UCSB_V2 is

  component ODMB_VME is
    port (
      CSP_FREE_AGENT_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);
      CSP_BPI_PORT_LA_CTRL        : inout std_logic_vector(35 downto 0);
      CSP_LVMB_LA_CTRL            : inout std_logic_vector(35 downto 0);
-- VME signals

      cmd_adrs        : out std_logic_vector(15 downto 0);
      vme_addr        : in  std_logic_vector (23 downto 1);  -- adr(23 downto 1)
      vme_data_in     : in  std_logic_vector (15 downto 0);  -- data_in(15 downto 0)
      vme_data_out    : out std_logic_vector (15 downto 0);  -- data_out(15 downto 0)
      vme_am          : in  std_logic_vector (5 downto 0);  -- am(5 downto 0)
      vme_ga          : in  std_logic_vector (4 downto 0);  -- iga(4 downto 0) -> ga*(4 downto 0)
      vme_gap         : in  std_logic;  -- iga(5) -> ga*(5)
      vme_ds_b        : in  std_logic_vector(1 downto 0);  -- ids1* -> ds1*, ids0* -> ds0*
      vme_as_b        : in  std_logic;  -- ias* -> as*
      vme_lword_b     : in  std_logic;  -- ilword* -> lword*
      vme_write_b     : in  std_logic;  -- iwrite* -> write*
      vme_iack_b      : in  std_logic;  -- inack* -> iack*
      --vme_sysreset_b  : in  std_logic;  -- isysrst* -> sysrest*
      vme_sysfail_b   : in  std_logic;  -- isysfail* -> sysfail
      vme_sysfail_out : out std_logic;  -- NEW (N.1)
      vme_berr_b      : in  std_logic;  -- iberr* -> berr*
      vme_berr_out    : out std_logic;  -- NEW (N.1)
      vme_dtack_b     : out std_logic;  -- dtack* -> odtack*
      vme_tovme       : out std_logic;  -- tovme
      vme_tovme_b     : out std_logic;  -- tovme*
      vme_doe         : out std_logic;  -- doe
      vme_doe_b       : out std_logic;  -- doe*

-- Clock

      clk160      : in std_logic;       -- For dcfeb prbs (160MHz)
      clk80       : in std_logic;       -- For testctrl (80MHz)
      clk         : in std_logic;       -- fpgaclk (40MHz)
      clk_s1      : in std_logic;       -- midclk (10MHz) 
      clk_s2      : in std_logic;       -- slowclk (2.5MHz)
      clk_s3      : in std_logic;       -- slowclk2 (1.25MHz)
      qpll_locked : in std_logic;

-- Reset

      rst       : in  std_logic;        -- Firmware reset
      pon_reset : in  std_logic;        -- Power on reset
      led_pulse : out std_logic;

-- JTAG signals To/From DCFEBs

      dl_jtag_tck : out std_logic_vector (6 downto 0);
      dl_jtag_tms : out std_logic;
      dl_jtag_tdi : out std_logic;
      dl_jtag_tdo : in  std_logic_vector (6 downto 0);

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
      TEST_BC0        : out std_logic;
      TEST_PED        : out std_logic;
      TEST_LCT        : out std_logic;
      OTMB_LCT_RQST   : out std_logic;
      OTMB_EXT_TRIG   : out std_logic;

      MASK_L1A      : out std_logic_vector(NFEB downto 0);
      tp_sel        : out std_logic_vector(15 downto 0);
      odmb_ctrl     : out std_logic_vector(15 downto 0);
      odmb_data_sel : out std_logic_vector(7 downto 0);
      odmb_data     : in  std_logic_vector(15 downto 0);
      TXDIFFCTRL    : out std_logic_vector(3 downto 0);  -- Controls the TX voltage swing
      LOOPBACK      : out std_logic_vector(2 downto 0);  -- For internal loopback tests

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
      LCT_L1A_DLY   : out std_logic_vector(5 downto 0);
      OTMB_PUSH_DLY : out integer range 0 to 63;
      ALCT_PUSH_DLY : out integer range 0 to 63;
      INJ_DLY       : out std_logic_vector(4 downto 0);
      EXT_DLY       : out std_logic_vector(4 downto 0);
      CALLCT_DLY    : out std_logic_vector(3 downto 0);
      ODMB_ID       : out std_logic_vector(15 downto 0);
      NWORDS_DUMMY  : out std_logic_vector(15 downto 0);
      KILL          : out std_logic_vector(NFEB+2 downto 1);
      CRATEID       : out std_logic_vector(7 downto 0);

      -- ALCT/OTMB FIFO signals
      alct_fifo_data_in    : in std_logic_vector(17 downto 0);
      alct_fifo_data_valid : in std_logic;
      otmb_fifo_data_in    : in std_logic_vector(17 downto 0);
      otmb_fifo_data_valid : in std_logic;

      -- PC_TX FIFO signals
      pc_tx_fifo_rst     : out std_logic;
      pc_tx_fifo_rden    : out std_logic;
      pc_tx_fifo_dout    : in  std_logic_vector(15 downto 0);
      pc_tx_fifo_wrd_cnt : in  std_logic_vector(15 downto 0);
      pc_rx_fifo_rst     : out std_logic;
      pc_rx_fifo_rden    : out std_logic;
      pc_rx_fifo_dout    : in  std_logic_vector(15 downto 0);
      pc_rx_fifo_wrd_cnt : in  std_logic_vector(15 downto 0);

      -- DDU FIFO signals
      ddu_tx_fifo_rst     : out std_logic;
      ddu_tx_fifo_rden    : out std_logic;
      ddu_tx_fifo_dout    : in  std_logic_vector(15 downto 0);
      ddu_tx_fifo_wrd_cnt : in  std_logic_vector(15 downto 0);
      ddu_rx_fifo_rst     : out std_logic;
      ddu_rx_fifo_rden    : out std_logic;
      ddu_rx_fifo_dout    : in  std_logic_vector(15 downto 0);
      ddu_rx_fifo_wrd_cnt : in  std_logic_vector(15 downto 0);

      -- TESTFIFOS
      TFF_DOUT    : in  std_logic_vector(15 downto 0);
      TFF_WRD_CNT : in  std_logic_vector(11 downto 0);
      TFF_RST     : out std_logic_vector(NFEB downto 1);
      TFF_SEL     : out std_logic_vector(NFEB downto 1);
      TFF_RDEN    : out std_logic_vector(NFEB downto 1);

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

      BPI_CFG_UL_PULSE : out std_logic;
      BPI_CFG_DL_PULSE : out std_logic;
      BPI_DONE         : in  std_logic;
      BPI_CFG_REG_WE   : in  std_logic;
      BPI_CFG_REG_IN   : in  std_logic_vector(15 downto 0);

      --To SYSMON
      VP    : in std_logic;
      VN    : in std_logic;
      VAUXP : in std_logic_vector(15 downto 0);
      VAUXN : in std_logic_vector(15 downto 0);

      -- DDU/PC/DCFEB COMMON PRBS
      PRBS_TYPE : out std_logic_vector(2 downto 0);

      -- DDU PRBS signals
      DDU_PRBS_TX_EN   : out std_logic;
      DDU_PRBS_RX_EN   : out std_logic;
      DDU_PRBS_TST_CNT : out std_logic_vector(15 downto 0);
      DDU_PRBS_ERR_CNT : in  std_logic_vector(15 downto 0);

      -- PC PRBS signals
      PC_PRBS_TX_EN   : out std_logic;
      PC_PRBS_RX_EN   : out std_logic;
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

  end component;  -- ODMB_VME


  component ODMB_CTRL is
    generic (
      NFIFO       : integer range 1 to 16  := 16;  -- Number of FIFOs in PCFIFO
      NFEB        : integer range 1 to 7   := 7;  -- Number of DCFEBS, 7 in the final design
      CAFIFO_SIZE : integer range 1 to 128 := 128  -- Number FIFO words in CAFIFO
      );  
    port (
      CSP_FREE_AGENT_PORT_LA_CTRL  : inout std_logic_vector(35 downto 0);
      CSP_CONTROL_FSM_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);
      clk40                        : in    std_logic;
      clk80                        : in    std_logic;
      clk160                       : in    std_logic;
      reset                        : in    std_logic;

      ga : in std_logic_vector(4 downto 0);

      ccb_cmd    : in  std_logic_vector (5 downto 0);  -- ccbcmnd(5 downto 0) - from J3
      ccb_cmd_s  : in  std_logic;       -- ccbcmnd(6) - from J3
      ccb_data   : in  std_logic_vector (7 downto 0);  -- ccbdata(7 downto 0) - from J3
      ccb_data_s : in  std_logic;       -- ccbdata(8) - from J3
      ccb_cal    : in  std_logic_vector (2 downto 0);  -- ccbcal(2 downto 0) - from J3
      ccb_crsv   : in  std_logic_vector (4 downto 0);  -- NEW [ccbrsv(6)], ccbrsv(3 downto 0) - from J3
      ccb_drsv   : in  std_logic_vector (1 downto 0);  -- ccbrsv(5 downto 4) - from J3
      ccb_rsvo   : in  std_logic_vector (4 downto 0);  -- NEW [ccbrsv(11)], ccbrsv(10 downto 7) - from J3
      ccb_rsvi   : out std_logic_vector (2 downto 0);  -- ccbrsv(14 downto 12) - to J3
      ccb_bx0    : in  std_logic;       -- bx0 - from J3
      ccb_bxrst  : in  std_logic;       -- bxrst - from J3
      ccb_l1acc  : in  std_logic;       -- l1acc - from J3
      ccb_l1arst : in  std_logic;       -- l1rst - from J3
      ccb_l1rls  : out std_logic;       -- l1rls - to J3
      ccb_clken  : in  std_logic;       -- clken - from J3

      rawlct   : in std_logic_vector (NFEB downto 0);  -- rawlct(5 downto 0) - from J4
      alct_dav : in std_logic;          -- lctdav1 - from J4
      otmb_dav : in std_logic;          -- lctdav2 - from J4

-- From GigaLinks

      grx0_data       : in std_logic_vector(15 downto 0);
      grx0_data_valid : in std_logic;
      grx1_data       : in std_logic_vector(15 downto 0);
      grx1_data_valid : in std_logic;

-- From GigaLinks

      gtx0_data       : out std_logic_vector(15 downto 0);
      gtx0_data_valid : out std_logic;
      gtx1_data       : out std_logic_vector(15 downto 0);
      gtx1_data_valid : out std_logic;
      ddu_eof         : out std_logic;

-- From/To FIFOs

      data_fifo_re : out std_logic_vector(NFEB+2 downto 1);
      data_fifo_oe : out std_logic_vector(NFEB+2 downto 1);

      fifo_out : in std_logic_vector(15 downto 0);
      fifo_eof : in std_logic;

      fifo_empty_b   : in std_logic_vector(NFEB+2 downto 1);  -- emptyf*(7 DOWNTO 1) - from FIFOs
      fifo_half_full : in std_logic_vector(NFEB+2 downto 1);  -- 

-- From CAFIFO to Data FIFOs
      cafifo_l1a           : out std_logic;
      cafifo_l1a_match_in  : out std_logic_vector(NFEB+2 downto 1);  -- From TRGCNTRL to CAFIFO to generate Data  
      cafifo_l1a_match_out : out std_logic_vector(NFEB+2 downto 1);  -- From CAFIFO to CONTROL  
      cafifo_l1a_cnt       : out std_logic_vector(23 downto 0);
      cafifo_l1a_dav       : out std_logic_vector(NFEB+2 downto 1);
      cafifo_bx_cnt        : out std_logic_vector(11 downto 0);

      cafifo_prev_next_l1a_match : out std_logic_vector(15 downto 0);
      cafifo_prev_next_l1a       : out std_logic_vector(15 downto 0);
      control_debug              : out std_logic_vector(15 downto 0);
      cafifo_debug               : out std_logic_vector(15 downto 0);
      cafifo_wr_addr             : out std_logic_vector(7 downto 0);
      cafifo_rd_addr             : out std_logic_vector(7 downto 0);

      ext_dcfeb_l1a_cnt7 : out std_logic_vector(23 downto 0);
      dcfeb_l1a_dav7     : out std_logic;
      l1acnt_rst         : in  std_logic;
      bxcnt_rst          : in  std_logic;

-- To PCFIFO
      gl_pc_tx_ack : in std_logic;
      pcclk        : in std_logic;
-- To CONTROL
      dduclk       : in std_logic;
      eof_data     : in std_logic_vector(NFEB+2 downto 1);

-- From ALCT,OTMB,DCFEBs to CAFIFO
      alct_dv     : in std_logic;
      otmb_dv     : in std_logic;
      dcfeb0_dv   : in std_logic;
      dcfeb0_data : in std_logic_vector(15 downto 0);
      dcfeb1_dv   : in std_logic;
      dcfeb1_data : in std_logic_vector(15 downto 0);
      dcfeb2_dv   : in std_logic;
      dcfeb2_data : in std_logic_vector(15 downto 0);
      dcfeb3_dv   : in std_logic;
      dcfeb3_data : in std_logic_vector(15 downto 0);
      dcfeb4_dv   : in std_logic;
      dcfeb4_data : in std_logic_vector(15 downto 0);
      dcfeb5_dv   : in std_logic;
      dcfeb5_data : in std_logic_vector(15 downto 0);
      dcfeb6_dv   : in std_logic;
      dcfeb6_data : in std_logic_vector(15 downto 0);

-- From/To DCFEBs (FF-EMU-MOD)

      ALCT_DAV_SYNC_OUT : out std_logic;
      OTMB_DAV_SYNC_OUT : out std_logic;

      dcfeb_injpulse  : out std_logic;  -- inject - to DCFEBs
      dcfeb_extpulse  : out std_logic;  -- extpls - to DCFEBs
      dcfeb_l1a       : out std_logic;
      dcfeb_l1a_match : out std_logic_vector(NFEB downto 1);

      pedestal      : in std_logic;
      pedestal_otmb : in std_logic;

      test_ccbinj : in std_logic;
      test_ccbpls : in std_logic;
      test_ccbped : in std_logic;

      lct_err : out std_logic;          -- To an LED in the original design

      cal_mode : in std_logic;

      LCT_L1A_DLY   : in std_logic_vector(5 downto 0);
      OTMB_PUSH_DLY : in integer range 0 to 63;
      ALCT_PUSH_DLY : in integer range 0 to 63;
      PUSH_DLY      : in integer range 0 to 63;
      INJ_DLY       : in std_logic_vector(4 downto 0);
      EXT_DLY       : in std_logic_vector(4 downto 0);
      CALLCT_DLY    : in std_logic_vector(3 downto 0);
      KILL          : in std_logic_vector(NFEB+2 downto 1);
      CRATEID       : in std_logic_vector(7 downto 0)
      ); 
  end component;  -- ODMB_CTRL

  component alct_otmb_data_gen is
    port(
      clk            : in std_logic;
      rst            : in std_logic;
      l1a            : in std_logic;
      alct_l1a_match : in std_logic;
      otmb_l1a_match : in std_logic;
      nwords_dummy   : in std_logic_vector(15 downto 0);

      alct_dv   : out std_logic;
      alct_data : out std_logic_vector(15 downto 0);
      otmb_dv   : out std_logic;
      otmb_data : out std_logic_vector(15 downto 0));
  end component;


  component GIGALINK_PC is
    generic (
      SIM_SPEEDUP : integer := 0
      );
    port (
      -- Global signals
      RST    : in std_logic;
      REFCLK : in std_logic;            -- 125 MHz for PC data rate

      -- Transmitter signals
      TXD     : in  std_logic_vector(15 downto 0);  -- Data to be transmitted
      TXD_VLD : in  std_logic;          -- Flag for valid data;
      TX_ACK  : out std_logic;  -- TX acknowledgement (ethernet header has finished)
      TXD_N   : out std_logic;          -- GTX transmit data out - signal
      TXD_P   : out std_logic;          -- GTX transmit data out + signal
      USRCLK  : out std_logic;          -- Data clock coming from the TX PLL

      TXDIFFCTRL : in std_logic_vector(3 downto 0);  -- Controls the TX voltage swing
      LOOPBACK   : in std_logic_vector(2 downto 0);  -- For internal loopback tests

      -- Receiver signals
      RXD_N   : in  std_logic;          -- GTX receive data in - signal
      RXD_P   : in  std_logic;          -- GTX receive data in + signal
      RXD     : out std_logic_vector(15 downto 0);  -- Data received
      RXD_VLD : out std_logic;          -- Flag for valid data;

      TX_FIFO_WREN_OUT : out std_logic;  -- Flag for valid data;
      TXD_FRAME_OUT    : out std_logic_vector(15 downto 0);
      ROM_CNT_OUT      : out std_logic_vector(2 downto 0);
      -- FIFO signals
      VME_CLK          : in  std_logic;
      TX_FIFO_RST      : in  std_logic;
      TX_FIFO_RDEN     : in  std_logic;
      TX_FIFO_DOUT     : out std_logic_vector(15 downto 0);
      TX_FIFO_WRD_CNT  : out std_logic_vector(15 downto 0);
      RX_FIFO_RST      : in  std_logic;
      RX_FIFO_RDEN     : in  std_logic;
      RX_FIFO_DOUT     : out std_logic_vector(15 downto 0);
      RX_FIFO_WRD_CNT  : out std_logic_vector(15 downto 0);

      -- PRBS signals
      PRBS_TYPE       : in  std_logic_vector(2 downto 0);
      PRBS_TX_EN      : in  std_logic;
      PRBS_RX_EN      : in  std_logic;
      PRBS_EN_TST_CNT : in  std_logic_vector(15 downto 0);
      PRBS_ERR_CNT    : out std_logic_vector(15 downto 0)
      );
  end component;


  component gigalink_ddu is
    generic (
      SIM_SPEEDUP : integer := 0
      );
    port (
      -- Global signals
      REF_CLK_80 : in std_logic;        -- 80 MHz for DDU data rate
      RST        : in std_logic;
      USRCLK  : out std_logic;            -- Data clock coming from the TX PLL

      -- Transmitter signals
      TXD        : in  std_logic_vector(15 downto 0);  -- Data to be transmitted
      TXD_VLD    : in  std_logic;       -- Flag for valid data;
      TX_DDU_N   : out std_logic;       -- GTX transmit data out - signal
      TX_DDU_P   : out std_logic;       -- GTX transmit data out + signal
      TXDIFFCTRL : in  std_logic_vector(3 downto 0);  -- Controls the TX voltage swing
      LOOPBACK   : in  std_logic_vector(2 downto 0);  -- For internal loopback tests

      -- Receiver signals
      RX_DDU_N : in  std_logic;         -- GTX receive data in - signal
      RX_DDU_P : in  std_logic;         -- GTX receive data in + signal
      RXD      : out std_logic_vector(15 downto 0);  -- Data received
      RXD_VLD  : out std_logic;         -- Flag for valid data;

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
  end component;

  component dmb_receiver is
    generic (
      USE_2p56GbE : integer := 0;
      SIM_SPEEDUP : integer := 0
      );
    port (
      --External signals
      RST              : in  std_logic;
      ORX_01_N         : in  std_logic;
      ORX_01_P         : in  std_logic;
      ORX_02_N         : in  std_logic;
      ORX_02_P         : in  std_logic;
      ORX_03_N         : in  std_logic;
      ORX_03_P         : in  std_logic;
      ORX_04_N         : in  std_logic;
      ORX_04_P         : in  std_logic;
      ORX_05_N         : in  std_logic;
      ORX_05_P         : in  std_logic;
      ORX_06_N         : in  std_logic;
      ORX_06_P         : in  std_logic;
      ORX_07_N         : in  std_logic;
      ORX_07_P         : in  std_logic;
      ORX_08_N         : in  std_logic;
      ORX_08_P         : in  std_logic;
      ORX_09_N         : in  std_logic;
      ORX_09_P         : in  std_logic;
      ORX_10_N         : in  std_logic;
      ORX_10_P         : in  std_logic;
      ORX_11_N         : in  std_logic;
      ORX_11_P         : in  std_logic;
      ORX_12_N         : in  std_logic;
      ORX_12_P         : in  std_logic;
      KILL             : in  std_logic_vector(NFEB downto 1);
      DCFEB1_DATA      : out std_logic_vector(15 downto 0);
      DCFEB2_DATA      : out std_logic_vector(15 downto 0);
      DCFEB3_DATA      : out std_logic_vector(15 downto 0);
      DCFEB4_DATA      : out std_logic_vector(15 downto 0);
      DCFEB5_DATA      : out std_logic_vector(15 downto 0);
      DCFEB6_DATA      : out std_logic_vector(15 downto 0);
      DCFEB7_DATA      : out std_logic_vector(15 downto 0);
      DCFEB_DATA_VALID : out std_logic_vector(NFEB downto 1);
      CRC_VALID        : out std_logic_vector(NFEB downto 1);
      DCFEBCLK         : out std_logic;
      
      --Internal signals
      FIFO_VME_MODE          : in  std_logic;
      FIFO_RST               : in  std_logic_vector(NFEB downto 1);
      FIFO_SEL               : in  std_logic_vector(NFEB downto 1);
      RD_EN_FF               : in  std_logic_vector(NFEB downto 1);
      WR_EN_FF               : in  std_logic_vector(NFEB downto 1);
      FF_DATA_IN             : in  std_logic_vector(15 downto 0);
      FF_DATA_OUT            : out std_logic_vector(15 downto 0);
      FF_WRD_CNT             : out std_logic_vector(11 downto 0);
      FF_STATUS              : out std_logic_vector(15 downto 0);
      DMBVME_CLK_S2          : in  std_logic;
      DAQ_RX_125REFCLK       : in  std_logic;
      DAQ_RX_160REFCLK_115_0 : in  std_logic;

      -- PRBS signals
      PRBS_TYPE        : in  std_logic_vector(2 downto 0);
      PRBS_FIBER_SEL   : in  std_logic_vector(3 downto 0);
      PRBS_EN          : in  std_logic;
      PRBS_RST         : in  std_logic;
      PRBS_RD_EN       : in  std_logic;
      RXPRBSERR        : out std_logic;
      PRBS_ERR_CNT_OUT : out std_logic_vector(15 downto 0)

      );
  end component;

  component LVMB_MUX is
    generic (
      NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS
      );  
    port (
      RST : in std_logic;

      SIM_LVMB_EN   : in std_logic;
      SIM_LVMB_CE   : in std_logic_vector(NFEB downto 1);
      REAL_LVMB_SDO : in std_logic;

      SCLK : in  std_logic;
      SDI  : in  std_logic;
      SDO  : out std_logic
      );
  end component;

  component DCFEB_V6 is
    generic (
      dcfeb_addr : std_logic_vector(3 downto 0) := "1000"  -- DCFEB address
      );  
    port
      (clk          : in std_logic;
       dcfebclk     : in std_logic;
       rst          : in std_logic;
       l1a          : in std_logic;
       l1a_match    : in std_logic;
       tx_ack       : in std_logic;
       nwords_dummy : in std_logic_vector(15 downto 0);

       dcfeb_dv      : out std_logic;
       dcfeb_data    : out std_logic_vector(15 downto 0);
       adc_mask      : out std_logic_vector(11 downto 0);
       dcfeb_fsel    : out std_logic_vector(32 downto 0);
       dcfeb_jtag_ir : out std_logic_vector(9 downto 0);
       trst          : in  std_logic;
       tck           : in  std_logic;
       tms           : in  std_logic;
       tdi           : in  std_logic;
       rtn_shft_en   : out std_logic;
       tdo           : out std_logic);
  end component;

  component EOFGEN is
    port(
      clk : in std_logic;
      rst : in std_logic;

      dv_in   : in std_logic;
      data_in : in std_logic_vector(15 downto 0);

      dv_out   : out std_logic;
      data_out : out std_logic_vector(17 downto 0)
      );

  end component;

  component LCTDLY is  -- Aligns RAW_LCT with L1A by 2.4 us to 4.8 us
    port (
      DIN   : in std_logic;
      CLK   : in std_logic;
      DELAY : in std_logic_vector(5 downto 0);

      DOUT : out std_logic
      );
  end component;

  component bpi_ctrl
    port(
      CLK               : in  std_logic;  -- 40 MHz clock
      CLK1MHZ           : in  std_logic;  --  1 MHz clock for timers
      RST               : in  std_logic;
--      Interface Signals to/from VME interface
      BPI_CMD_FIFO_DATA : in  std_logic_vector(15 downto 0);  -- Data for command FIFO
      BPI_WE            : in  std_logic;  -- Command FIFO write enable  (pulse one clock cycle for one write)
      BPI_RE            : in  std_logic;  -- Read back FIFO read enable  (pulse one clock cycle for one read)
      BPI_DSBL          : in  std_logic;  -- Disable parsing of BPI commands in the command FIFO (while being filled)
      BPI_ENBL          : in  std_logic;  -- Enable  parsing of BPI commands in the command FIFO
      BPI_RBK_FIFO_DATA : out std_logic_vector(15 downto 0);  -- Data on output of the Read back FIFO
      BPI_RBK_WRD_CNT   : out std_logic_vector(10 downto 0);  -- Word count of the Read back FIFO (number of available reads)
      BPI_STATUS        : out std_logic_vector(15 downto 0);  -- FIFO status bits and latest value of the PROM status register. 
      BPI_TIMER         : out std_logic_vector(31 downto 0);  -- General timer
-- Signals to/from low level BPI interface
      BPI_BUSY          : in  std_logic;  --  
      BPI_DATA_FROM     : in  std_logic_vector(15 downto 0);  -- 
      BPI_LOAD_DATA     : in  std_logic;  --  
      BPI_ACTIVE        : out std_logic;  --  
      BPI_OP            : out std_logic_vector(1 downto 0);   -- 
      BPI_ADDR          : out std_logic_vector(22 downto 0);  -- 
      BPI_DATA_TO       : out std_logic_vector(15 downto 0);  -- 
      BPI_EXECUTE       : out std_logic;
-- Guido Aug 26
      BPI_DONE          : out std_logic;
      BPI_CFG_REG_WE    : out std_logic;
      BPI_CFG_REG_IN    : out std_logic_vector(15 downto 0)
      );
  end component;

  component bpi_interface
    port(
      CLK          : in    std_logic;   -- 40 MHz clock
      RST          : in    std_logic;
      ADDR         : in    std_logic_vector(22 downto 0);  -- Bank/Array Address 
      CMD_DATA_OUT : in    std_logic_vector(15 downto 0);  -- Command or Data being written to FLASH device
      OP           : in    std_logic_vector(1 downto 0);  -- Operation: 00-standby, 01-write, 10-read, 11-not allowed(standby)
      EXECUTE      : in    std_logic;   -- 
      DATA_IN      : out   std_logic_vector(15 downto 0);  -- Data read from FLASH device
      LOAD_DATA    : out   std_logic;  -- Clock enable signal for capturing Data read from FLASH device
      BUSY         : out   std_logic;  -- Operation in progress signal (not ready)
-- signals for Dual purpose data lines
      BPI_ACTIVE   : in    std_logic;  -- set to 1 when data lines are for BPI communications.
      DUAL_DATA    : in    std_logic_vector(15 downto 0);  -- Data provided for non BPI communications
-- external connections cooresponding to I/O pins
      bpi_ad_out_r : out   std_logic_vector(22 downto 0);  -- 
      data_out_i   : out   std_logic_vector(15 downto 0);  -- 
      PROM_CONTROL : out   std_logic_vector(5 downto 0);  -- 
      BPI_AD       : inout std_logic_vector(22 downto 0);  -- 
      CFG_DAT      : inout std_logic_vector(15 downto 0);  -- 
      RS0          : out   std_logic;   -- 
      RS1          : out   std_logic;   -- 
      FCS_B        : out   std_logic;   -- 
      FOE_B        : out   std_logic;   -- 
      FWE_B        : out   std_logic;   -- 
      FLATCH_B     : out   std_logic    -- 
      );
  end component;


-- Adding csp for bpi signals here
  component csp_bpi_la is
    port(
      CLK     : in    std_logic := 'X';
      DATA    : in    std_logic_vector (299 downto 0);
      TRIG0   : in    std_logic_vector (15 downto 0);
      CONTROL : inout std_logic_vector (35 downto 0)
      );
  end component;

  component csp_controller is
    port (
      CONTROL0 : inout std_logic_vector (35 downto 0);
      CONTROL1 : inout std_logic_vector (35 downto 0);
      CONTROL2 : inout std_logic_vector (35 downto 0);
      CONTROL3 : inout std_logic_vector (35 downto 0);
      CONTROL4 : inout std_logic_vector (35 downto 0)
      );
  end component;

  constant NFIFO : integer := 4;

-- Global signals
  signal FW_RESET    : std_logic := '0';
  signal PB_PULSE    : std_logic := '0';
  signal PB_B        : std_logic_vector(1 downto 0);
  signal odmb_status : std_logic_vector (15 downto 0);

  signal resync, test_inj, test_pls, test_ped, test_bc0, test_l1a, test_lct, test_pb_lct : std_logic := '0';
  signal otmb_lct_rqst, otmb_ext_trig                                                    : std_logic := '0';
  signal l1acnt_rst, bxcnt_rst                                                           : std_logic := '0';
  signal test_otmb_dav, test_alct_dav                                                    : std_logic := '0';
  signal otmb_push_dly_p1, alct_push_dly_p1                                              : integer range 0 to 64;

-- VME Signals

  signal cmd_adrs     : std_logic_vector (15 downto 0);
  signal vme_data_out : std_logic_vector (15 downto 0);
  signal vme_data_in  : std_logic_vector (15 downto 0);
  signal vme_tovme_b  : std_logic;
  signal vme_doe      : std_logic;

  signal v6_jtag_sel_inner                        : std_logic := '0';
  signal v6_tck_inner, v6_tms_inner, v6_tdi_inner : std_logic := '0';
  signal int_vme_dtack_v6_b                       : std_logic;

  signal eof_data : std_logic_vector (NFEB+2 downto 1);

-- ALCT ----------------------
  signal gen_alct_data_valid : std_logic;
  signal gen_alct_data       : std_logic_vector(15 downto 0);
  signal alct_data_valid     : std_logic;
  signal alct_data           : std_logic_vector(15 downto 0);
  signal alct_q, alct_qq     : std_logic_vector(17 downto 0);

  signal rx_alct_data_valid : std_logic;

  signal alct_fifo_data_valid : std_logic;
  signal alct_fifo_data_in    : std_logic_vector(17 downto 0);
  signal alct_fifo_data_out   : std_logic_vector (17 downto 0);

-- OTMB ----------------------
  signal gen_otmb_data_valid : std_logic;
  signal gen_otmb_data       : std_logic_vector(15 downto 0);
  signal otmb_data_valid     : std_logic;
  signal otmb_data           : std_logic_vector(15 downto 0);
  signal otmb_q, otmb_qq     : std_logic_vector(17 downto 0);

  signal rx_otmb_data_valid : std_logic;

  signal otmb_fifo_data_valid : std_logic;
  signal otmb_fifo_data_in    : std_logic_vector(17 downto 0);
  signal otmb_fifo_data_out   : std_logic_vector (17 downto 0);

  signal alct_dav_sync_out, otmb_dav_sync_out : std_logic;


------------------------------

  signal fifo_out : std_logic_vector (15 downto 0);

  -- To PCFIFO
  signal gl_pc_tx_ack : std_logic := '0';

-- JTAG signals To/From MBV

  signal int_tck, int_tdo             : std_logic_vector(7 downto 1);
  signal odmb_tms, odmb_tdi           : std_logic;
  signal dcfeb_tms_out, dcfeb_tdi_out : std_logic;
  signal isnot_ODMB_V3V4              : std_logic := '1';

-- JTAG outputs from internal DCFEBs

  signal gen_tdo : std_logic_vector(7 downto 1) := (others => '0');

-- Signals To DCFEBs from MBC

  signal int_l1a       : std_logic;     -- To be sent out to pins in V2
  signal int_l1a_match : std_logic_vector (NFEB downto 1);  -- To be sent out to pins in V2

-- Monitoring signals

  type l1a_match_cnt_type is array (NFEB downto 1) of std_logic_vector(15 downto 0);
  signal raw_lct_cnt, goodcrc_cnt : l1a_match_cnt_type;

  type dav_cnt_type is array (NFEB+2 downto 1) of std_logic_vector(15 downto 0);
  signal l1a_match_cnt, into_cafifo_dav_cnt : dav_cnt_type;
  signal data_fifo_re_cnt, data_fifo_oe_cnt : dav_cnt_type;
  signal eof_data_cnt, cafifo_l1a_dav_cnt   : dav_cnt_type;
  signal into_cafifo_dav                    : std_logic_vector(NFEB+2 downto 1);

  signal ext_dcfeb_l1a_cnt7 : std_logic_vector(23 downto 0);
  signal dcfeb_l1a_dav7     : std_logic;

  type gap_cnt_type is array (NFEB downto 1) of std_logic_vector(15 downto 0);
  signal lct_l1a_gap                      : gap_cnt_type;
  signal l1a_otmbdav_gap, l1a_alctdav_gap : std_logic_vector(15 downto 0);

  signal alct_dav_cnt, otmb_dav_cnt       : std_logic_vector(15 downto 0);
  signal gtx1_data_valid_cnt, ddu_eof_cnt : std_logic_vector(15 downto 0);
  signal int_l1a_cnt                      : std_logic_vector(15 downto 0);
  signal otmb_tx_inner                    : std_logic_vector(48 downto 0);
  signal qpll_locked_cnt                  : std_logic_vector(15 downto 0);

  signal mask_l1a      : std_logic_vector(NFEB downto 0);
  signal tp_sel_reg    : std_logic_vector(15 downto 0) := (others => '0');
  signal odmb_ctrl_reg : std_logic_vector(15 downto 0) := (others => '0');
  signal odmb_data_sel : std_logic_vector(7 downto 0);
  signal odmb_data     : std_logic_vector(15 downto 0);
  signal pedestal      : std_logic                     := '0';

  -- GIGALINK_PC 
  signal gl1_rx_buf_p, gl1_rx_buf_n : std_logic;
  signal pc_rx_data                 : std_logic_vector(15 downto 0);
  signal pc_rx_data_valid           : std_logic;

  signal pc_tx_fifo_rst     : std_logic;
  signal pc_tx_fifo_rden    : std_logic;
  signal pc_tx_fifo_dout    : std_logic_vector(15 downto 0);
  signal pc_tx_fifo_wrd_cnt : std_logic_vector(15 downto 0);
  signal pc_rx_fifo_rst     : std_logic;
  signal pc_rx_fifo_rden    : std_logic;
  signal pc_rx_fifo_dout    : std_logic_vector(15 downto 0);
  signal pc_rx_fifo_wrd_cnt : std_logic_vector(15 downto 0);
  signal pc_txd_frame       : std_logic_vector(15 downto 0);
  signal rom_cnt_out        : std_logic_vector(2 downto 0);
  signal pc_tx_fifo_wren    : std_logic;

  -- GIGALINK_DDU
  signal gl0_rx_buf_p, gl0_rx_buf_n : std_logic;
  signal ddu_rx_data                : std_logic_vector(15 downto 0);
  signal ddu_rx_data_valid          : std_logic;
  signal txdiffctrl                 : std_logic_vector(3 downto 0);  -- Controls the TX voltage swing
  signal loopback                   : std_logic_vector(2 downto 0);  -- For internal loopback tests

  signal ddu_tx_fifo_rst     : std_logic;
  signal ddu_tx_fifo_rden    : std_logic;
  signal ddu_tx_fifo_dout    : std_logic_vector (15 downto 0);
  signal ddu_tx_fifo_wrd_cnt : std_logic_vector (15 downto 0);
  signal ddu_rx_fifo_rst     : std_logic;
  signal ddu_rx_fifo_rden    : std_logic;
  signal ddu_rx_fifo_dout    : std_logic_vector (15 downto 0);
  signal ddu_rx_fifo_wrd_cnt : std_logic_vector (15 downto 0);

  -- dmb_receiver
  signal CRC_VALID : std_logic_vector(NFEB downto 1) := (others => '0');
  signal RD_EN_FF  : std_logic_vector(NFEB downto 1) := (others => '0');
  signal FF_STATUS : std_logic_vector(15 downto 0);

  constant FIFO_VME_MODE : std_logic                       := '0';  -- We probably will not use VME_MODE on DMB_RX
  constant WR_EN_FF      : std_logic_vector(NFEB downto 1) := (others => '0');
  constant FF_DATA_IN    : std_logic_vector(15 downto 0)   := (others => '0');

  -- CCB
  signal ccb_cmd_bxev                   : std_logic_vector(7 downto 0)  := (others => '0');
  signal ccb_cmd_reg, ccb_data_reg      : std_logic_vector(15 downto 0) := (others => '0');
  signal ccb_other, ccb_rsv             : std_logic_vector(15 downto 0) := (others => '0');
  signal ccb_other_reg, ccb_rsv_reg     : std_logic_vector(15 downto 0) := (others => '0');
  signal ccb_other_reg_b, ccb_rsv_reg_b : std_logic_vector(15 downto 0) := (others => '0');


-- DCFEB I/O Signals

  type dcfeb_data_type is array (NFEB downto 1) of std_logic_vector(15 downto 0);
  signal gen_dcfeb_data                       : dcfeb_data_type;
  signal rx_dcfeb_data                        : dcfeb_data_type;
  signal dcfeb_data                           : dcfeb_data_type;
  signal orx_buf_n, orx_buf_p                 : std_logic_vector(12 downto 1);
  signal gen_dcfeb_data_valid                 : std_logic_vector(NFEB downto 1);
  signal rx_dcfeb_data_valid                  : std_logic_vector(NFEB downto 1);
  signal dcfeb_data_valid_d, dcfeb_data_valid : std_logic_vector(NFEB downto 1);

  signal gen_dcfeb_sel : std_logic       := '0';
  type dcfeb_addr_type is array (1 to NFEB) of std_logic_vector(3 downto 0);
  constant dcfeb_addr  : dcfeb_addr_type := ("0001", "0010", "0011", "0100", "0101", "0110", "0111");

  signal gen_alct_sel, gen_otmb_sel : std_logic;

-- From/To Gigalinks
  signal grx0_data       : std_logic_vector(15 downto 0) := "0000000000000000";
  signal grx0_data_valid : std_logic                     := '0';
  signal grx1_data       : std_logic_vector(15 downto 0) := "0000000000000000";
  signal grx1_data_valid : std_logic                     := '0';

  signal gtx0_data                : std_logic_vector(15 downto 0);
  signal gtx0_data_valid, ddu_eof : std_logic;
  signal gtx1_data                : std_logic_vector(15 downto 0);
  signal gtx1_data_valid          : std_logic;

  signal gl1_clk : std_logic;
  signal gl0_clk, gl0_clk_2     : std_logic;
  signal dduclk, pcclk          : std_logic;

-- PLL Signals

  signal qpll_clk40MHz, qpll_clk160MHz, clk160 : std_logic;

  signal pll1_fb, pll1_fb_slow, pll1_rst, pll1_pd, pll1_locked, pll1_locked_slow : std_logic := '0';

  signal pll_clk80, clk80     : std_logic;  -- reallyfastclk (80MHz) 
  signal pll_clk40, clk40     : std_logic;  -- fastclk (40MHz) 
  signal pll_clk10, clk10     : std_logic;  -- midclk  (10MHz) 
  signal pll_clk5, clk5       : std_logic;  -- Generates clk2p5 and clk1p25
  signal clk2p5, clk2p5_unbuf, clk2p5_inv   : std_logic;  -- slowclk (2.5MHz)
  signal clk1p25, clk1p25_inv : std_logic;  -- slowclk2 (1.25MHz)


-- Other signals

  signal int_dl_jtag_tdo : std_logic_vector(7 downto 1) := "0000000";

  signal int_lvmb_pon                                 : std_logic_vector(7 downto 0);
  signal int_lvmb_csb                                 : std_logic_vector(6 downto 0);
  signal int_lvmb_sclk, int_lvmb_sdin, int_lvmb_sdout : std_logic;

  signal led_pulse : std_logic := '1';

-- Test FIFOs

  type dcfeb_gbrx_data_type is array (NFEB+1 downto 1) of std_logic_vector(15 downto 0);
  signal dcfeb_gbrx_data : dcfeb_gbrx_data_type;

  signal dcfeb_gbrx_data_valid : std_logic_vector(NFEB+1 downto 1) := (others => '0');
  signal dcfeb_gbrx_data_clk   : std_logic_vector(NFEB+1 downto 1) := (others => '0');

  type dcfeb_adc_mask_type is array (NFEB downto 1) of std_logic_vector(11 downto 0);
  signal dcfeb_adc_mask : dcfeb_adc_mask_type;

  type dcfeb_fsel_type is array (NFEB downto 1) of std_logic_vector(32 downto 0);
  signal dcfeb_fsel : dcfeb_fsel_type;

  type dcfeb_jtag_ir_type is array (NFEB downto 1) of std_logic_vector(9 downto 0);
  signal dcfeb_jtag_ir : dcfeb_jtag_ir_type;

  signal diagout_cfebjtag : std_logic_vector(17 downto 0);
  signal diagout_lvdbmon  : std_logic_vector(17 downto 0);

  signal pon_rst_reg, fw_rst_reg, opt_rst_reg                : std_logic_vector (31 downto 0) := (others => '0');
  signal reset, opt_reset, fw_reset_q                        : std_logic                      := '0';
  signal opt_reset_pulse, opt_reset_pulse_q                  : std_logic                      := '0';
  signal l1a_reset_pulse, l1acnt_rst_pulse, l1acnt_rst_start : std_logic                      := '0';
  signal pon_reset                                           : std_logic;

  signal select_diagnostic : integer := 0;

  signal lct_err : std_logic := '0';

-- CAFIFO related signals
  signal data_fifo_oe   : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  signal data_fifo_re   : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  signal data_fifo_re_b : std_logic_vector(NFEB+2 downto 1) := (others => '1');

  signal cafifo_l1a                  : std_logic;
  signal cafifo_l1a_match_in         : std_logic_vector(NFEB+2 downto 1);
  signal cafifo_l1a_match_out        : std_logic_vector(NFEB+2 downto 1);
  signal cafifo_l1a_cnt              : std_logic_vector(23 downto 0);
  signal cafifo_l1a_dav              : std_logic_vector(NFEB+2 downto 1);
  signal cafifo_bx_cnt               : std_logic_vector(11 downto 0);
  signal cafifo_prev_next_l1a_match  : std_logic_vector(15 downto 0);
  signal cafifo_prev_next_l1a        : std_logic_vector(15 downto 0);
  signal cafifo_debug, control_debug : std_logic_vector(15 downto 0);
  signal cafifo_wr_addr              : std_logic_vector(7 downto 0);
  signal cafifo_rd_addr              : std_logic_vector(7 downto 0);


  type dcfeb_fifo_data_type is array (NFEB downto 1) of std_logic_vector(15 downto 0);
  signal dcfeb_fifo_in : dcfeb_fifo_data_type;

  type ext_dcfeb_fifo_data_type is array (NFEB downto 1) of std_logic_vector(17 downto 0);
  signal eofgen_dcfeb_fifo_in    : ext_dcfeb_fifo_data_type;
  signal eofgen_dcfeb_data_valid : std_logic_vector(NFEB downto 1);
  signal dcfeb_fifo_out          : ext_dcfeb_fifo_data_type;
  signal pulse_eof40             : std_logic_vector(NFEB downto 1);


  signal dcfeb_fifo_empty  : std_logic_vector(NFEB downto 1);
  signal dcfeb_fifo_aempty : std_logic_vector(NFEB downto 1);
  signal dcfeb_fifo_afull  : std_logic_vector(NFEB downto 1);
  signal dcfeb_fifo_full   : std_logic_vector(NFEB downto 1);

  signal eof_data_80                       : std_logic_vector(NFEB+2 downto 1);

  signal data_fifo_empty_b                : std_logic_vector(NFEB+2 downto 1);
  signal data_fifo_half_full              : std_logic_vector(NFEB+2 downto 1);
  signal alct_fifo_empty, otmb_fifo_empty : std_logic;
  signal alct_fifo_full, otmb_fifo_full   : std_logic;

  signal raw_l1a, tc_l1a           : std_logic;
  signal raw_lct                   : std_logic_vector(NFEB downto 0);
  signal int_alct_dav, tc_alct_dav : std_logic;
  signal int_otmb_dav, tc_otmb_dav : std_logic;
  signal tc_lct                    : std_logic_vector(NFEB downto 0);

  signal tc_run                                                   : std_logic;
  signal counter_clk, counter_clk_gl0, counter_clk_gl1, reset_cnt : integer   := 0;
  signal clk1, clk2, clk4, clk8, gl0_clk_slow, gl1_clk_2_slow     : std_logic := '0';
  signal clk1_inv, clk2_inv, clk4_inv                             : std_logic := '1';
  signal ts_out                                                   : std_logic_vector(31 downto 0);

  signal led_cnt                 : integer   := 0;
  signal led_cnt_rst, led_cnt_en : std_logic := '0';
  signal reset_q, clk_led        : std_logic := '0';

  type led_state_type is (LED_IDLE, LED_COUNTING);
  signal led_next_state, led_current_state : led_state_type;



-- From VMECONFREGS to odmb_ctrl and odmb_ctrl
  constant push_dly    : integer := 63;  -- It needs to be > alct/otmb_push_dly
  signal alct_push_dly : integer range 0 to 63;
  signal otmb_push_dly : integer range 0 to 63;
  signal lct_l1a_dly   : std_logic_vector(5 downto 0);
  signal inj_dly       : std_logic_vector(4 downto 0);
  signal ext_dly       : std_logic_vector(4 downto 0);
  signal callct_dly    : std_logic_vector(3 downto 0);
  signal odmb_id       : std_logic_vector(15 downto 0);
  signal nwords_dummy  : std_logic_vector(15 downto 0);
  signal kill          : std_logic_vector(nfeb+2 downto 1);
  signal crateid       : std_logic_vector(7 downto 0);

  -- From/to TESTFIFOS to test FIFOs
  signal TFF_DOUT    : std_logic_vector(15 downto 0);
  signal TFF_WRD_CNT : std_logic_vector(11 downto 0);
  signal TFF_RST     : std_logic_vector(NFEB downto 1);
  signal TFF_SEL     : std_logic_vector(NFEB downto 1);
  signal TFF_RDEN    : std_logic_vector(NFEB downto 1);

  signal ddu_data_valid : std_logic;

  signal testctrl_sel : std_logic := '0';

  signal eof : std_logic;

  signal ddu_tx_fifo_rst2, ddu_rx_fifo_rst2 : std_logic := '0';
  signal pc_tx_fifo_rst2, pc_rx_fifo_rst2   : std_logic := '0';

-- BPI Prom signals

  signal bpi_rst           : std_logic;
  signal vme_bpi_rst       : std_logic;
  signal clk1mhz           : std_logic;
  signal counter_clk1mhz   : integer                       := 0;
  signal bpi_we            : std_logic;
  signal bpi_re            : std_logic;
  signal bpi_dsbl          : std_logic;
  signal bpi_enbl          : std_logic;
  signal bpi_busy          : std_logic;
  signal bpi_load_data     : std_logic;
  signal bpi_active        : std_logic;
  signal bpi_execute       : std_logic;
  signal bpi_cmd_fifo_data : std_logic_vector(15 downto 0);
  signal bpi_rbk_fifo_data : std_logic_vector(15 downto 0);
  signal bpi_rbk_wrd_cnt   : std_logic_vector(10 downto 0);
  signal bpi_status        : std_logic_vector(15 downto 0);
  signal bpi_timer         : std_logic_vector(31 downto 0);
  signal bpi_data_from     : std_logic_vector(15 downto 0);
  signal bpi_op            : std_logic_vector(1 downto 0);
  signal bpi_addr          : std_logic_vector(22 downto 0);
  signal bpi_data_to       : std_logic_vector(15 downto 0);
  constant dual_data_leds  : std_logic_vector(15 downto 0) := (others => '0');

  signal bpi_done       : std_logic;
  signal bpi_cfg_reg_we : std_logic;
  signal bpi_cfg_reg_in : std_logic_vector(15 downto 0);

  signal bpi_cfg_ul_pulse : std_logic;
  signal bpi_cfg_dl_pulse : std_logic;

  -- SYSMON
  signal vauxp : std_logic_vector(15 downto 0);
  signal vauxn : std_logic_vector(15 downto 0);

  -- DDU/PC/DCFEB COMMON PRBS
  signal prbs_type : std_logic_vector(2 downto 0);

  -- DDU PRBS
  signal ddu_prbs_tx_en      : std_logic;
  signal ddu_prbs_rx_en      : std_logic;
  signal ddu_prbs_en_tst_cnt : std_logic_vector(15 downto 0);
  signal ddu_prbs_err_cnt    : std_logic_vector(15 downto 0);

  -- PC PRBS
  signal pc_prbs_tx_en      : std_logic;
  signal pc_prbs_rx_en      : std_logic;
  signal pc_prbs_en_tst_cnt : std_logic_vector(15 downto 0);
  signal pc_prbs_err_cnt    : std_logic_vector(15 downto 0);

  -- DCFEB PRBS
  signal dcfeb_prbs_fiber_sel : std_logic_vector(3 downto 0);
  signal dcfeb_prbs_en        : std_logic;
  signal dcfeb_prbs_rst       : std_logic;
  signal dcfeb_prbs_rd_en     : std_logic;
  signal dcfeb_rxprbserr      : std_logic;
  signal dcfeb_prbs_err_cnt   : std_logic_vector(15 downto 0);

  signal otmb_rx : std_logic_vector(5 downto 0);
  signal otmb_tx : std_logic_vector(48 downto 0);

  signal csp_control_fsm_port_la_ctrl : std_logic_vector(35 downto 0);  -- bgb logic analyzer control signals
  signal csp_free_agent_port_la_ctrl  : std_logic_vector(35 downto 0);  -- bgb logic analyzer control signals
  signal csp_bpi_la_ctrl              : std_logic_vector(35 downto 0);  -- for the bpi controller stuff up here
  signal csp_bpi_port_la_ctrl         : std_logic_vector(35 downto 0);  -- for the bpi controller stuff up here
  signal csp_lvmb_la_ctrl             : std_logic_vector(35 downto 0);  -- for the bpi controller stuff up here

  -- since we're at the top level, let's make the other signals for the csp thingy.
  signal csp_bpi_la_data : std_logic_vector(299 downto 0);
  signal csp_bpi_la_trig : std_logic_vector(15 downto 0);
  -- prom_inners for this csp operation
  signal prom_control    : std_logic_vector(5 downto 0);
  signal prom_a_out      : std_logic_vector(22 downto 0);
  signal prom_d_out      : std_logic_vector(15 downto 0);

  constant tp_1 : integer range 31 to 46 := 31;  -- DO NOT USE 46 or 48: DCFEB JTAG signals for ODMB.V2 
  constant tp_2 : integer range 31 to 46 := 35;  -- DO NOT USE 46 or 48: DCFEB JTAG signals for ODMB.V2 
  constant tp_3 : integer range 31 to 46 := 41;  -- DO NOT USE 46 or 48: DCFEB JTAG signals for ODMB.V2 
  constant tp_4 : integer range 31 to 46 := 45;  -- DO NOT USE 46 or 48: DCFEB JTAG signals for ODMB.V2 
  --constant tp_4 : integer range 49 to 49 := 49;  -- DO NOT USE 46 or 48: DCFEB JTAG signals for ODMB.V2 

begin
  
  csp_controller_pm : csp_controller
    port map (
      CONTROL0 => csp_control_fsm_port_la_ctrl,
      CONTROL1 => csp_free_agent_port_la_ctrl,
      CONTROL2 => csp_bpi_la_ctrl,
      CONTROL3 => csp_bpi_port_la_ctrl,
      CONTROL4 => csp_lvmb_la_ctrl
      );

  MBV : ODMB_VME
    port map (

      CSP_FREE_AGENT_PORT_LA_CTRL => csp_free_agent_port_la_ctrl,
      CSP_BPI_PORT_LA_CTRL        => csp_bpi_port_la_ctrl,
      CSP_LVMB_LA_CTRL            => csp_lvmb_la_ctrl,

      cmd_adrs        => cmd_adrs,            -- output
      vme_addr        => vme_addr,            -- input
      vme_data_in     => vme_data_in,         -- input
      vme_data_out    => vme_data_out,        -- output
      vme_am          => vme_am,              -- input
      vme_gap         => vme_gap,             -- input
      vme_ga          => vme_ga,              -- input
      vme_ds_b        => vme_ds_b,            -- input
      vme_as_b        => vme_as_b,            -- input
      vme_lword_b     => vme_lword_b,         -- input
      vme_write_b     => vme_write_b,         -- input
      vme_iack_b      => vme_iack_b,          -- input
      --vme_sysreset_b  => vme_sysreset_b,      -- input
      vme_sysfail_b   => vme_sysfail_b,       -- input
      vme_sysfail_out => vme_sysfail_out,     -- output
      vme_berr_b      => vme_berr_b,          -- input
      vme_berr_out    => vme_berr_out,        -- output
      vme_dtack_b     => int_vme_dtack_v6_b,  -- output
      vme_tovme       => vme_tovme,           -- tovme
      vme_tovme_b     => vme_tovme_b,         -- tovme*
      vme_doe         => vme_doe,             -- doe
      vme_doe_b       => vme_doe_b,           -- doe*

-- Clock

      clk160      => clk160,            -- for dcfeb prbs (160 MHz)
      clk80       => clk80,             -- for testctrl (80MHz)
      clk         => clk40,             -- fpgaclk (40MHz)
      clk_s1      => clk10,             -- midclk (10MHz) 
      clk_s2      => clk2p5,            -- slowclk (2.5MHz)
      clk_s3      => clk1p25,           -- slowclk2 (1.25MHz)
      QPLL_LOCKED => qpll_locked,

-- Reset

      rst       => reset,
      pon_reset => pon_reset,
      led_pulse => led_pulse,

-- JTAG signals To/From DCFEBs

      dl_jtag_tck => int_tck,
      dl_jtag_tms => dcfeb_tms_out,
      dl_jtag_tdi => dcfeb_tdi_out,
      dl_jtag_tdo => int_tdo,

-- JTAG Signals To/From ODMB JTAG

      odmb_jtag_sel => v6_jtag_sel_inner,
      odmb_jtag_tck => v6_tck_inner,
      odmb_jtag_tms => v6_tms_inner,
      odmb_jtag_tdi => v6_tdi_inner,
      odmb_jtag_tdo => odmb_tdo,

-- Done from DCFEB FPGA (CFEBPRG)

      dcfeb_done => dcfeb_done,

-- From/To LVMB

      lvmb_pon   => int_lvmb_pon,
      pon_load   => pon_load,
      pon_oe_b   => pon_en_b,
      r_lvmb_pon => r_lvmb_pon,
      lvmb_csb   => int_lvmb_csb,
      lvmb_sclk  => int_lvmb_sclk,
      lvmb_sdin  => int_lvmb_sdin,
      lvmb_sdout => int_lvmb_sdout,

      diagout_cfebjtag => diagout_cfebjtag,
      diagout_lvdbmon  => diagout_lvdbmon,

-- From VMEMON    
      OPT_RESET_PULSE => opt_reset_pulse,
      L1A_RESET_PULSE => l1a_reset_pulse,
      FW_RESET        => fw_reset,
      reprog_b        => odmb_hardrst_b,
      test_inj        => test_inj,
      test_pls        => test_pls,
      test_ped        => test_ped,
      test_bc0        => test_bc0,
      test_lct        => test_lct,
      OTMB_LCT_RQST   => otmb_lct_rqst,
      OTMB_EXT_TRIG   => otmb_ext_trig,

      MASK_L1A      => mask_l1a,
      tp_sel        => tp_sel_reg,
      odmb_ctrl     => odmb_ctrl_reg,
      odmb_data_sel => odmb_data_sel,
      odmb_data     => odmb_data,
      TXDIFFCTRL    => txdiffctrl,
      LOOPBACK      => loopback,

      -- TESTCTRL
      tc_l1a         => tc_l1a,
      tc_alct_dav    => tc_alct_dav,
      tc_otmb_dav    => tc_otmb_dav,
      tc_lct         => tc_lct,
      ddu_data       => gtx0_data,
      ddu_data_valid => gtx0_data_valid,
      tc_run         => tc_run,
      ts_out         => ts_out,
      dduclk         => dduclk,

      -- VMECONFREGS outputs
      LCT_L1A_DLY   => LCT_L1A_DLY,
      OTMB_PUSH_DLY => OTMB_PUSH_DLY,
      ALCT_PUSH_DLY => ALCT_PUSH_DLY,
      INJ_DLY       => INJ_DLY,
      EXT_DLY       => EXT_DLY,
      CALLCT_DLY    => CALLCT_DLY,
      ODMB_ID       => odmb_id,
      NWORDS_DUMMY  => NWORDS_DUMMY,
      KILL          => KILL,
      CRATEID       => CRATEID,

      -- ALCT/OTMB FIFO signals
      alct_fifo_data_in    => alct_fifo_data_in,
      alct_fifo_data_valid => alct_fifo_data_valid,
      otmb_fifo_data_in    => otmb_fifo_data_in,
      otmb_fifo_data_valid => otmb_fifo_data_valid,

      -- PC_TX FIFO signals
      pc_tx_fifo_rst     => pc_tx_fifo_rst,
      pc_tx_fifo_rden    => pc_tx_fifo_rden,
      pc_tx_fifo_dout    => pc_tx_fifo_dout,
      pc_tx_fifo_wrd_cnt => pc_tx_fifo_wrd_cnt,
      pc_rx_fifo_rst     => pc_rx_fifo_rst,
      pc_rx_fifo_rden    => pc_rx_fifo_rden,
      pc_rx_fifo_dout    => pc_rx_fifo_dout,
      pc_rx_fifo_wrd_cnt => pc_rx_fifo_wrd_cnt,

      -- DDU TX/RX FIFO signals
      ddu_tx_fifo_rst     => ddu_tx_fifo_rst,
      ddu_tx_fifo_rden    => ddu_tx_fifo_rden,
      ddu_tx_fifo_dout    => ddu_tx_fifo_dout,
      ddu_tx_fifo_wrd_cnt => ddu_tx_fifo_wrd_cnt,
      ddu_rx_fifo_rst     => ddu_rx_fifo_rst,
      ddu_rx_fifo_rden    => ddu_rx_fifo_rden,
      ddu_rx_fifo_dout    => ddu_rx_fifo_dout,
      ddu_rx_fifo_wrd_cnt => ddu_rx_fifo_wrd_cnt,

      -- TESTFIFOS
      TFF_DOUT    => TFF_DOUT,
      TFF_WRD_CNT => TFF_WRD_CNT,
      TFF_RST     => TFF_RST,
      TFF_SEL     => TFF_SEL,
      TFF_RDEN    => TFF_RDEN,

      -- BPI controls
      BPI_RST           => vme_bpi_rst,  -- Resets BPI interface state machines
      BPI_CMD_FIFO_DATA => bpi_cmd_fifo_data,  -- Data for command FIFO
      BPI_WE            => bpi_we,  -- Command FIFO write enable  (pulse one clock cycle for one write)
      BPI_RE            => bpi_re,  -- Read back FIFO read enable  (pulse one clock cycle for one read)
      BPI_DSBL          => bpi_dsbl,  -- Disable parsing of BPI commands in the command FIFO (while being filled)
      BPI_ENBL          => bpi_enbl,  -- Enable  parsing of BPI commands in the command FIFO
      BPI_RBK_FIFO_DATA => bpi_rbk_fifo_data,  -- Data on output of the Read back FIFO
      BPI_RBK_WRD_CNT   => bpi_rbk_wrd_cnt,  -- Word count of the Read back FIFO (number of available reads)
      BPI_STATUS        => bpi_status,  -- FIFO status bits and latest value of the PROM status register. 
      BPI_TIMER         => bpi_timer,   -- General timer

      BPI_CFG_UL_PULSE => bpi_cfg_ul_pulse,
      BPI_CFG_DL_PULSE => bpi_cfg_dl_pulse,
      BPI_DONE         => bpi_done,
      BPI_CFG_REG_WE   => bpi_cfg_reg_we,
      BPI_CFG_REG_IN   => bpi_cfg_reg_in,

      -- Adam Aug 15 To SYSMON
      VP    => '0',
      VN    => '0',
      VAUXP => vauxp,
      VAUXN => vauxn,

      PRBS_TYPE => prbs_type,

      -- DDU PRBS signals
      DDU_PRBS_TX_EN   => ddu_prbs_tx_en,
      DDU_PRBS_RX_EN   => ddu_prbs_rx_en,
      DDU_PRBS_TST_CNT => ddu_prbs_en_tst_cnt,
      DDU_PRBS_ERR_CNT => ddu_prbs_err_cnt,

      -- PC PRBS signals
      PC_PRBS_TX_EN   => pc_prbs_tx_en,
      PC_PRBS_RX_EN   => pc_prbs_rx_en,
      PC_PRBS_TST_CNT => pc_prbs_en_tst_cnt,
      PC_PRBS_ERR_CNT => pc_prbs_err_cnt,

      -- DCFEB PRBS signals
      DCFEB_PRBS_FIBER_SEL => dcfeb_prbs_fiber_sel,
      DCFEB_PRBS_EN        => dcfeb_prbs_en,
      DCFEB_PRBS_RST       => dcfeb_prbs_rst,
      DCFEB_PRBS_RD_EN     => dcfeb_prbs_rd_en,
      DCFEB_RXPRBSERR      => dcfeb_rxprbserr,
      DCFEB_PRBS_ERR_CNT   => dcfeb_prbs_err_cnt,

      -- OTMB PRBS signals
      OTMB_TX => OTMB_TX,
      OTMB_RX => OTMB_RX
      );                                -- MBV : ODMB_VME

  MBC : ODMB_CTRL
    generic map(CAFIFO_SIZE => 32)
    port map (

      CSP_FREE_AGENT_PORT_LA_CTRL  => csp_free_agent_port_la_ctrl,
      CSP_CONTROL_FSM_PORT_LA_CTRL => csp_control_fsm_port_la_ctrl,
      clk40                        => clk40,
      clk80                        => clk80,
      clk160                       => clk160,
      reset                        => reset,

      ga => vme_ga,

      ccb_cmd    => ccb_cmd,            -- ccbcmnd(5 downto 0) - from J3
      ccb_cmd_s  => ccb_cmd_s,          -- ccbcmnd(6) - from J3
      ccb_data   => ccb_data,           -- ccbdata(7 downto 0) - from J3
      ccb_data_s => ccb_data_s,         -- ccbdata(8) - from J3
      ccb_cal    => ccb_cal,            -- ccbcal(2 downto 0) - from J3
      ccb_crsv   => ccb_crsv,  -- NEW [ccbrsv(6)], ccbrsv(3 downto 0) - from J3
      ccb_drsv   => ccb_drsv,           -- ccbrsv(5 downto 4) - from J3
      ccb_rsvo   => ccb_rsvo,  -- NEW [ccbrsv(11)], ccbrsv(10 downto 7) - from J3
      ccb_rsvi   => ccb_rsvi,           -- ccbrsv(14 downto 12) - to J3
      ccb_bx0    => ccb_bx0,            -- bx0 - from J3
      ccb_bxrst  => ccb_bxrst,          -- bxrst - from J3
      ccb_l1acc  => raw_l1a,            -- l1acc - from J3 
      ccb_l1arst => ccb_l1arst,         -- l1rst - from J3
      ccb_l1rls  => ccb_l1rls,          -- l1rls - to J3
      ccb_clken  => ccb_clken,          -- clken - from J3

      rawlct   => raw_lct,  -- rawlct(NFEB downto 0) - from -- from testctrl
      otmb_dav => int_otmb_dav,         -- lctdav1 - from J4
      alct_dav => int_alct_dav,         -- lctdav2 - from J4

-- From GigaLinks

      grx0_data       => "0000000000000000",
      grx0_data_valid => '0',
      grx1_data       => "0000000000000000",
      grx1_data_valid => '0',

-- To GigaLinks

      gtx0_data       => gtx0_data,
      gtx0_data_valid => gtx0_data_valid,
      gtx1_data       => gtx1_data,
      gtx1_data_valid => gtx1_data_valid,
      ddu_eof         => ddu_eof,

-- From/To FIFOs

      data_fifo_re => data_fifo_re_b,
      data_fifo_oe => data_fifo_oe,

      fifo_out => fifo_out,
      fifo_eof => eof,

      fifo_empty_b   => data_fifo_empty_b,
      fifo_half_full => data_fifo_half_full,

-- From CAFIFO to Data FIFOs
      cafifo_l1a                 => cafifo_l1a,
      cafifo_l1a_match_in        => cafifo_l1a_match_in,
      cafifo_l1a_match_out       => cafifo_l1a_match_out,
      cafifo_l1a_cnt             => cafifo_l1a_cnt,
      cafifo_l1a_dav             => cafifo_l1a_dav,
      cafifo_bx_cnt              => cafifo_bx_cnt,
      cafifo_prev_next_l1a_match => cafifo_prev_next_l1a_match,
      cafifo_prev_next_l1a       => cafifo_prev_next_l1a,
      control_debug              => control_debug,
      cafifo_debug               => cafifo_debug,
      cafifo_wr_addr             => cafifo_wr_addr,
      cafifo_rd_addr             => cafifo_rd_addr,
      ext_dcfeb_l1a_cnt7         => ext_dcfeb_l1a_cnt7,
      dcfeb_l1a_dav7             => dcfeb_l1a_dav7,

      l1acnt_rst => l1acnt_rst,
      bxcnt_rst  => bxcnt_rst,

-- To PCFIFO
      gl_pc_tx_ack => gl_pc_tx_ack,
      dduclk       => dduclk,
      pcclk        => pcclk,
      eof_data     => eof_data,

-- From ALCT,OTMB,DCFEBs to CAFIFO
      alct_dv     => alct_fifo_data_valid,
      otmb_dv     => otmb_fifo_data_valid,
      dcfeb0_dv   => dcfeb_data_valid(1),
      dcfeb0_data => dcfeb_data(1),
      dcfeb1_dv   => dcfeb_data_valid(2),
      dcfeb1_data => dcfeb_data(2),
      dcfeb2_dv   => dcfeb_data_valid(3),
      dcfeb2_data => dcfeb_data(3),
      dcfeb3_dv   => dcfeb_data_valid(4),
      dcfeb3_data => dcfeb_data(4),
      dcfeb4_dv   => dcfeb_data_valid(5),
      dcfeb4_data => dcfeb_data(5),
      dcfeb5_dv   => dcfeb_data_valid(6),
      dcfeb5_data => dcfeb_data(6),
      dcfeb6_dv   => dcfeb_data_valid(7),
      dcfeb6_data => dcfeb_data(7),


-- From/To DCFEBs (FF-EMU-MOD)

      ALCT_DAV_SYNC_OUT => ALCT_DAV_SYNC_OUT,
      OTMB_DAV_SYNC_OUT => OTMB_DAV_SYNC_OUT,

      dcfeb_l1a_match => int_l1a_match,  -- lctf(5 DOWNTO 1) - to DCFEBs
      dcfeb_l1a       => int_l1a,        -- febrst - to DCFEBs
      dcfeb_injpulse  => dcfeb_injpls,   -- inject - to DCFEBs
      dcfeb_extpulse  => dcfeb_extpls,   -- extpls - to DCFEBs
      pedestal        => pedestal,
      pedestal_otmb   => odmb_ctrl_reg(14),

      test_ccbinj => test_inj,
      test_ccbpls => test_pls,
      test_ccbped => test_ped,

      lct_err => lct_err,

      cal_mode => odmb_ctrl_reg(0),

      LCT_L1A_DLY   => LCT_L1A_DLY,
      OTMB_PUSH_DLY => OTMB_PUSH_DLY,
      ALCT_PUSH_DLY => ALCT_PUSH_DLY,
      PUSH_DLY      => PUSH_DLY,
      INJ_DLY       => INJ_DLY,
      EXT_DLY       => EXT_DLY,
      CALLCT_DLY    => CALLCT_DLY,
      KILL          => KILL,
      CRATEID       => CRATEID
      );                                -- MBC : ODMB_CTRL


---------------------------  Optical tranceivers  ---------------------------
-----------------------------------------------------------------------------
  ddu_tx_fifo_rst2 <= ddu_tx_fifo_rst or reset;
  ddu_rx_fifo_rst2 <= ddu_rx_fifo_rst or reset;

  GIGALINK_DDU_PM : gigalink_ddu
    generic map (SIM_SPEEDUP => IS_SIMULATION)
    port map (
      REF_CLK_80 => gl0_clk,            -- 80 MHz for DDU data rate
      RST        => opt_reset,
      USRCLK        => dduclk,
      -- Transmitter signals
      TXD        => gtx0_data,          -- Data to be transmitted
      TXD_VLD    => gtx0_data_valid,    -- Flag for valid data;
      TX_DDU_N   => gl0_tx_n,           -- GTX transmit data out - signal
      TX_DDU_P   => gl0_tx_p,           -- GTX transmit data out + signal
      TXDIFFCTRL => txdiffctrl,         -- Controls the TX voltage swing
      LOOPBACK   => loopback,           -- For internal loopback tests

      -- Receiver signals
      RX_DDU_N => gl0_rx_buf_n,         -- GTX receive data in - signal
      RX_DDU_P => gl0_rx_buf_p,         -- GTX receive data in + signal
      RXD      => ddu_rx_data,
      RXD_VLD  => ddu_rx_data_valid,

      -- FIFO signals
      VME_CLK         => clk2p5,
      TX_FIFO_RST     => ddu_tx_fifo_rst2,
      TX_FIFO_RDEN    => ddu_tx_fifo_rden,
      TX_FIFO_DOUT    => ddu_tx_fifo_dout,
      TX_FIFO_WRD_CNT => ddu_tx_fifo_wrd_cnt,
      RX_FIFO_RST     => ddu_rx_fifo_rst2,
      RX_FIFO_RDEN    => ddu_rx_fifo_rden,
      RX_FIFO_DOUT    => ddu_rx_fifo_dout,
      RX_FIFO_WRD_CNT => ddu_rx_fifo_wrd_cnt,

      -- DDU PRBS signals
      PRBS_TYPE       => prbs_type,
      PRBS_TX_EN      => ddu_prbs_tx_en,
      PRBS_RX_EN      => ddu_prbs_rx_en,
      PRBS_EN_TST_CNT => ddu_prbs_en_tst_cnt,
      PRBS_ERR_CNT    => ddu_prbs_err_cnt
      );

  pc_tx_fifo_rst2 <= pc_tx_fifo_rst or reset;
  pc_rx_fifo_rst2 <= pc_rx_fifo_rst or reset;

  GIGALINK_PC_PM : gigalink_pc
    generic map (SIM_SPEEDUP => IS_SIMULATION)
    port map (
      RST     => opt_reset,
      REFCLK  => gl1_clk,
      -- Transmitter signals
      TXD     => gtx1_data,             -- Data to be transmitted
      TXD_VLD => gtx1_data_valid,       -- Flag for valid data;
      TX_ACK  => gl_pc_tx_ack,  -- TX acknowledgement (ethernet header has finished)
      TXD_N   => gl1_tx_n,              -- GTX transmit data out - signal
      TXD_P   => gl1_tx_p,              -- GTX transmit data out + signal
      USRCLK  => pcclk,

      TXDIFFCTRL  => txdiffctrl,        -- Controls the TX voltage swing
      LOOPBACK    => loopback,          -- For internal loopback tests
      ROM_CNT_OUT => ROM_CNT_OUT,

      -- Receiver signals
      RXD_N   => gl1_rx_buf_n,          -- GTX receive data in - signal
      RXD_P   => gl1_rx_buf_p,          -- GTX receive data in + signal
      RXD     => pc_rx_data,
      RXD_VLD => pc_rx_data_valid,

      TX_FIFO_WREN_OUT => pc_tx_fifo_wren,
      TXD_FRAME_OUT    => pc_txd_frame,
      -- FIFO signals
      VME_CLK          => clk2p5,
      TX_FIFO_RST      => pc_tx_fifo_rst2,
      TX_FIFO_RDEN     => pc_tx_fifo_rden,
      TX_FIFO_DOUT     => pc_tx_fifo_dout,
      TX_FIFO_WRD_CNT  => pc_tx_fifo_wrd_cnt,
      RX_FIFO_RST      => pc_rx_fifo_rst2,
      RX_FIFO_RDEN     => pc_rx_fifo_rden,
      RX_FIFO_DOUT     => pc_rx_fifo_dout,
      RX_FIFO_WRD_CNT  => pc_rx_fifo_wrd_cnt,

      -- PC PRBS signals
      PRBS_TYPE       => prbs_type,
      PRBS_TX_EN      => pc_prbs_tx_en,
      PRBS_RX_EN      => pc_prbs_rx_en,
      PRBS_EN_TST_CNT => pc_prbs_en_tst_cnt,
      PRBS_ERR_CNT    => pc_prbs_err_cnt
      );


  DMB_RX_PM : dmb_receiver
    generic map (
      --USE_2p56GbE => 0,
      USE_2p56GbE => 1,
      SIM_SPEEDUP => IS_SIMULATION
      )
    port map (
      --External signals
      RST => reset,

      --DAQ_RX_160REFCLK_115_0 => gl0_clk,  -- For the DDU TX simulation

      --DAQ_RX_125REFCLK       => gl1_clk,
      --DMBVME_CLK_S2          => pcclk,  -- Data clock for the PC TX simulation
      --DAQ_RX_160REFCLK_115_0       => clk40,    -- For the PC TX simulation

      DAQ_RX_125REFCLK       => clk40,
      DMBVME_CLK_S2          => clk2p5,
      DAQ_RX_160REFCLK_115_0 => qpll_clk160MHz,


      ORX_01_N => orx_buf_n(1),
      ORX_01_P => orx_buf_p(1),
      ORX_02_N => orx_buf_n(2),
      ORX_02_P => orx_buf_p(2),
      ORX_03_N => orx_buf_n(3),
      ORX_03_P => orx_buf_p(3),
      ORX_04_N => orx_buf_n(4),
      ORX_04_P => orx_buf_p(4),
      ORX_05_N => orx_buf_n(5),
      ORX_05_P => orx_buf_p(5),
      ORX_06_N => orx_buf_n(6),
      ORX_06_P => orx_buf_p(6),
      ORX_07_N => orx_buf_n(7),
      ORX_07_P => orx_buf_p(7),

      ORX_08_N => orx_buf_n(8),
      ORX_08_P => orx_buf_p(8),
      ORX_09_N => orx_buf_n(9),
      ORX_09_P => orx_buf_p(9),
      ORX_10_N => orx_buf_n(10),
      ORX_10_P => orx_buf_p(10),
      ORX_11_N => orx_buf_n(11),
      ORX_11_P => orx_buf_p(11),
      ORX_12_N => orx_buf_n(12),
      ORX_12_P => orx_buf_p(12),

      KILL             => kill(7 downto 1),
      DCFEB1_DATA      => rx_dcfeb_data(1),
      DCFEB2_DATA      => rx_dcfeb_data(2),
      DCFEB3_DATA      => rx_dcfeb_data(3),
      DCFEB4_DATA      => rx_dcfeb_data(4),
      DCFEB5_DATA      => rx_dcfeb_data(5),
      DCFEB6_DATA      => rx_dcfeb_data(6),
      DCFEB7_DATA      => rx_dcfeb_data(7),
      DCFEB_DATA_VALID => rx_dcfeb_data_valid,
      CRC_VALID        => crc_valid,
      DCFEBCLK => clk160,

      --Internal signals
      FIFO_VME_MODE => fifo_vme_mode,
      FIFO_RST      => TFF_RST,
      FIFO_SEL      => TFF_SEL,
      RD_EN_FF      => TFF_RDEN,
      WR_EN_FF      => wr_en_ff,
      FF_DATA_IN    => ff_data_in,
      FF_DATA_OUT   => TFF_DOUT,
      FF_WRD_CNT    => TFF_WRD_CNT,
      FF_STATUS     => ff_status,

      -- PRBS signals
      PRBS_TYPE        => prbs_type,
      PRBS_FIBER_SEL   => dcfeb_prbs_fiber_sel,
      PRBS_EN          => dcfeb_prbs_en,
      PRBS_RST         => dcfeb_prbs_rst,
      PRBS_RD_EN       => dcfeb_prbs_rd_en,
      RXPRBSERR        => dcfeb_rxprbserr,
      PRBS_ERR_CNT_OUT => dcfeb_prbs_err_cnt

      );

--------------------------------  DCFEB data  -------------------------------
-----------------------------------------------------------------------------

  GEN_DCFEB : for I in NFEB downto 1 generate
  begin

    DCFEB_V6_PM : DCFEB_V6
      generic map(
        dcfeb_addr => dcfeb_addr(I))
      port map(
        clk          => clk40,
        dcfebclk     => clk160,
        rst          => reset,
        l1a          => int_l1a,
        l1a_match    => int_l1a_match(I),
        tx_ack       => '1',
        nwords_dummy => nwords_dummy,

        dcfeb_dv      => gen_dcfeb_data_valid(I),
        dcfeb_data    => gen_dcfeb_data(I),
        adc_mask      => dcfeb_adc_mask(I),
        dcfeb_fsel    => dcfeb_fsel(I),
        dcfeb_jtag_ir => dcfeb_jtag_ir(I),
        trst          => reset,
        tck           => int_tck(I),
        tms           => dcfeb_tms_out,
        tdi           => dcfeb_tdi_out,
        rtn_shft_en   => open,
        tdo           => gen_tdo(I));

    dcfeb_data_valid_d(I) <= '0' when kill(I) = '1' else
                             rx_dcfeb_data_valid(I) when (gen_dcfeb_sel = '0') else
                             gen_dcfeb_data_valid(I);
    dcfeb_data(I) <= rx_dcfeb_data(I) when (gen_dcfeb_sel = '0') else gen_dcfeb_data(I);

    FD_DCFEBDV   : FDC port map(dcfeb_data_valid(I), clk160, reset, dcfeb_data_valid_d(I));
    FD_DCFEBDATA : FDVEC port map(dcfeb_fifo_in(I), clk160, reset, dcfeb_data(I));

    dcfeb_tck(I) <= int_tck(I);

    dcfeb_l1a_match(I) <= '0' when mask_l1a(I) = '1' else int_l1a_match(I);

    int_tdo(I) <= dcfeb_tdo(I) when (gen_dcfeb_sel = '0') else gen_tdo(I);

    EOFGEN_PM : EOFGEN
      port map (
        clk => clk160,
        rst => reset,

        dv_in   => dcfeb_data_valid(I),
        data_in => dcfeb_fifo_in(I),

        dv_out   => eofgen_dcfeb_data_valid(I),
        data_out => eofgen_dcfeb_fifo_in(I)
        );

    
    DCFEB_FIFO_CASCADE : FIFO_CASCADE
      generic map (
        NFIFO        => NFIFO,          -- number of FIFOs in cascade
        DATA_WIDTH   => 18,             -- With of data packets
        FWFT         => true,           -- First word fall through
        WR_FASTER_RD => true)   -- Set int_clk to WRCLK if faster than RDCLK

      port map(
        DO        => dcfeb_fifo_out(I),    -- Output data
        EMPTY     => dcfeb_fifo_empty(I),  -- Output empty
        FULL      => dcfeb_fifo_full(I),   -- Output full
        HALF_FULL => data_fifo_half_full(I),
        EOF       => eof_data_80(I),      -- Output EOF
        BOF       => open,

        DI    => eofgen_dcfeb_fifo_in(I),    -- Input data
        RDCLK => dduclk,                     -- Input read clock
        RDEN  => data_fifo_re(I),            -- Input read enable
        RST   => l1acnt_rst,                 -- Input reset
        WRCLK => clk160,                     -- Input write clock
        WREN  => eofgen_dcfeb_data_valid(I)  -- Input write enable
        );

    -- Delay EOF of DCFEBs by PUSH_DLY to be on CAFIFO time
    PULSEEOF40  : PULSE2SLOW port map(pulse_eof40(I), clk40, dduclk, reset, eof_data_80(I));
    DS_EOF_PUSH : DELAY_SIGNAL port map(eof_data(I), clk40, push_dly, pulse_eof40(I));

  end generate GEN_DCFEB;

----------------------------  ALCT and OTMB data  ----------------------------
-----------------------------------------------------------------------------

  ALCT_OTMB_DATA_GEN_PM : alct_otmb_data_gen
    port map(
      clk            => clk40,
      rst            => reset,
      l1a            => cafifo_l1a,
      alct_l1a_match => cafifo_l1a_match_in(NFEB+2),
      otmb_l1a_match => cafifo_l1a_match_in(NFEB+1),
      nwords_dummy   => nwords_dummy,

      alct_dv   => gen_alct_data_valid,
      alct_data => gen_alct_data,
      otmb_dv   => gen_otmb_data_valid,
      otmb_data => gen_otmb_data
      );

  rsvtd_out(0) <= cafifo_l1a                  when otmb_rx(0) = '0' else otmb_rx(3);
  rsvtd_out(1) <= cafifo_l1a_match_in(NFEB+1) when otmb_rx(0) = '0' else otmb_rx(4);
  rsvtd_out(2) <= cafifo_l1a_match_in(NFEB+2) when otmb_rx(0) = '0' else otmb_rx(5);
--  dmb_tx_odmb_inner <= dmb_tx_reserved & lct(7 downto 6) & alct_dav & eof_alct_data(16 downto 15) &
--                       eof_alct_data_valid_b & lct(5 downto 0) & eof_otmb_data_valid_b & otmb_dav &
--                       eof_otmb_data(16 downto 15) & eof_alct_data(14 downto 0) &
--                       eof_otmb_data(14 downto 0);
  otmb_tx      <= rsvtd_in(0) & rsvtd_in(1) & rsvtd_in(2) & rawlct(7 downto 6) & alctdav & alct(16 downto 15) &
                  alct(17) & rawlct(5 downto 0) & otmb(17) & otmb(17) &
                  otmb(16 downto 15) & alct(14 downto 0) &
                  otmb(14 downto 0) when IS_SIMULATION = 0 else otmb_tx_tb;

  ALCT_FIFO_CASCADE : FIFO_CASCADE
    generic map (
      NFIFO        => 3,                -- number of FIFOs in cascade
      DATA_WIDTH   => 18,               -- With of data packets
      FWFT         => true,             -- First word fall through
      WR_FASTER_RD => false)  -- Set int_clk to WRCLK if faster than RDCLK

    port map(
      DO        => alct_fifo_data_out,  -- Output data
      EMPTY     => alct_fifo_empty,     -- Output empty
      FULL      => alct_fifo_full,      -- Output full
      HALF_FULL => data_fifo_half_full(9),
      EOF       => eof_data_80(NFEB+2),    -- Output EOF
      BOF       => open,

      DI    => alct_fifo_data_in,       -- Input data
      RDCLK => dduclk,                  -- Input read clock
      RDEN  => data_fifo_re(NFEB+2),    -- Input read enable
      RST   => l1acnt_rst,              -- Input reset
      WRCLK => clk40,                   -- Input write clock
      WREN  => alct_fifo_data_valid     -- Input write enable
      );

  OTMB_FIFO_CASCADE : FIFO_CASCADE
    generic map (
      NFIFO        => 3,                -- number of FIFOs in cascade
      DATA_WIDTH   => 18,               -- With of data packets
      FWFT         => true,             -- First word fall through
      WR_FASTER_RD => false)  -- Set int_clk to WRCLK if faster than RDCLK

    port map(
      DO        => otmb_fifo_data_out,  -- Output data
      EMPTY     => otmb_fifo_empty,     -- Output empty
      FULL      => otmb_fifo_full,      -- Output full
      HALF_FULL => data_fifo_half_full(8),
      EOF       => eof_data_80(NFEB+1),    -- Output EOF
      BOF       => open,

      DI    => otmb_fifo_data_in,       -- Input data
      RDCLK => dduclk,                  -- Input read clock
      RDEN  => data_fifo_re(NFEB+1),    -- Input read enable
      RST   => l1acnt_rst,              -- Input reset
      WRCLK => clk40,                   -- Input write clock
      WREN  => otmb_fifo_data_valid     -- Input write enable
      );

  PULSEEOFALCT : PULSE2SLOW port map(eof_data(NFEB+2), clk40, dduclk, reset, eof_data_80(NFEB+2));
  PULSEEOFOTMB : PULSE2SLOW port map(eof_data(NFEB+1), clk40, dduclk, reset, eof_data_80(NFEB+1));

-- FIFO MUX
  fifo_out <= dcfeb_fifo_out(1)(15 downto 0) when data_fifo_oe = "111111110" else
              dcfeb_fifo_out(2)(15 downto 0)  when data_fifo_oe = "111111101" else
              dcfeb_fifo_out(3)(15 downto 0)  when data_fifo_oe = "111111011" else
              dcfeb_fifo_out(4)(15 downto 0)  when data_fifo_oe = "111110111" else
              dcfeb_fifo_out(5)(15 downto 0)  when data_fifo_oe = "111101111" else
              dcfeb_fifo_out(6)(15 downto 0)  when data_fifo_oe = "111011111" else
              dcfeb_fifo_out(7)(15 downto 0)  when data_fifo_oe = "110111111" else
              otmb_fifo_data_out(15 downto 0) when data_fifo_oe = "101111111" else
              alct_fifo_data_out(15 downto 0) when data_fifo_oe = "011111111" else
              (others => 'Z');
  eof <= dcfeb_fifo_out(1)(17) when data_fifo_oe = "111111110" else
         dcfeb_fifo_out(2)(17)  when data_fifo_oe = "111111101" else
         dcfeb_fifo_out(3)(17)  when data_fifo_oe = "111111011" else
         dcfeb_fifo_out(4)(17)  when data_fifo_oe = "111110111" else
         dcfeb_fifo_out(5)(17)  when data_fifo_oe = "111101111" else
         dcfeb_fifo_out(6)(17)  when data_fifo_oe = "111011111" else
         dcfeb_fifo_out(7)(17)  when data_fifo_oe = "110111111" else
         otmb_fifo_data_out(17) when data_fifo_oe = "101111111" else
         alct_fifo_data_out(17) when data_fifo_oe = "011111111" else
         '0';

  -- Sync alct and otmb to our clock. Probably not needed
  GENOTMBSYNC : for index in 0 to 17 generate
  begin
    FDALCT  : FD port map(alct_q(index), clk40, alct(index));
    FDALCTQ : FD port map(alct_qq(index), clk40, alct_q(index));
    FDOTMB  : FD port map(otmb_q(index), clk40, otmb(index));
    FDOTMBQ : FD port map(otmb_qq(index), clk40, otmb_q(index));
  end generate GENOTMBSYNC;

  rx_alct_data_valid <= not alct_qq(17);
  alct_data_valid    <= '0' when kill(9) = '1' else
                        rx_alct_data_valid when (gen_dcfeb_sel = '0') else
                        gen_alct_data_valid;

  alct_data <= alct_qq(15 downto 0) when (gen_dcfeb_sel = '0') else
               gen_alct_data;

  rx_otmb_data_valid <= not otmb_qq(17);
  otmb_data_valid    <= '0' when kill(8) = '1' else
                        rx_otmb_data_valid when (gen_dcfeb_sel = '0') else
                        gen_otmb_data_valid;

  otmb_data <= otmb_qq(15 downto 0) when (gen_dcfeb_sel = '0') else
               gen_otmb_data;

  data_fifo_re      <= not data_fifo_re_b;
  data_fifo_empty_b <= alct_fifo_empty & otmb_fifo_empty & dcfeb_fifo_empty;

  ------------------------ TRIGGERS  -------------------------
  -- Raw signals come unsynced from outside
  test_pb_lct <= test_lct or pb_pulse;
  LCTDLY_GTRG : LCTDLY port map(test_pb_lct, clk40, LCT_L1A_DLY, test_l1a);

  testctrl_sel <= odmb_ctrl_reg(9);
  pedestal     <= odmb_ctrl_reg(13);

  raw_l1a <= '1' when test_l1a = '1' else
             tc_l1a when (testctrl_sel = '1') else
             not ccb_l1acc;
  raw_lct <= (others => '1') when test_pb_lct = '1' else
             tc_lct when (testctrl_sel = '1') else
             rawlct;

  tc_run_out <= tc_run;

  otmb_push_dly_p1 <= otmb_push_dly + 1;
  alct_push_dly_p1 <= alct_push_dly + 1;
  DS_OTMB_PUSH : DELAY_SIGNAL generic map (64)port map(test_otmb_dav, clk40, otmb_push_dly_p1, test_l1a);
  DS_ALCT_PUSH : DELAY_SIGNAL generic map (64)port map(test_alct_dav, clk40, alct_push_dly_p1, test_l1a);

  int_alct_dav <= '1' when test_alct_dav = '1' else
                  tc_alct_dav when (testctrl_sel = '1') else
                  alctdav;              -- lctdav2
  int_otmb_dav <= '1' when test_otmb_dav = '1' else
                  tc_otmb_dav when (testctrl_sel = '1') else
                  otmbdav;              -- lctdav1

  --eof_data(9) <= alct_fifo_data_in(16);
  --eof_data(8) <= otmb_fifo_data_in(16);


  ALCT_EOFGEN_PM : EOFGEN
    port map (
      clk => clk40,
      rst => reset,

      dv_in   => alct_data_valid,
      data_in => alct_data,

      dv_out   => alct_fifo_data_valid,
      data_out => alct_fifo_data_in
      );

  OTMB_EOFGEN_PM : EOFGEN
    port map (
      clk => clk40,
      rst => reset,

      dv_in   => otmb_data_valid,
      data_in => otmb_data,

      dv_out   => otmb_fifo_data_valid,
      data_out => otmb_fifo_data_in
      );

  LVMB_MUX_PM : LVMB_MUX
    generic map (NFEB => NFEB)
    port map(
      RST => reset,

      SIM_LVMB_EN   => odmb_ctrl_reg(10),
      SIM_LVMB_CE   => int_lvmb_csb,
      REAL_LVMB_SDO => lvmb_sdout,

      SCLK => int_lvmb_sclk,
      SDI  => int_lvmb_sdin,
      SDO  => int_lvmb_sdout
      );



---------------------------  General assignments  ---------------------------
-----------------------------------------------------------------------------
  lctrqst(1) <= otmb_lct_rqst when otmb_rx(0) = '0' else otmb_rx(0);
  lctrqst(2) <= otmb_ext_trig when otmb_rx(0) = '0' else otmb_rx(1);

  gen_alct_sel  <= odmb_ctrl_reg(7);
  gen_otmb_sel  <= odmb_ctrl_reg(7);
  gen_dcfeb_sel <= odmb_ctrl_reg(7);

  pb_b <= not pb;
  PULSE_PB : PULSE2FAST port map(pb_pulse, clk40, reset, pb_b(1));

  -- From CCB - for production tests
  ccb_cmd_bxev <= ccb_cmd & ccb_evcntres & ccb_bxrst;
  GEN_CCB : for index in 0 to 7 generate
    FDCMD : FDC port map(ccb_cmd_reg(index), ccb_cmd_s, reset, ccb_cmd_bxev(index));
    FDDAT : FDC port map(ccb_data_reg(index), ccb_data_s, reset, ccb_data(index));
  end generate GEN_CCB;

  ccb_rsv   <= "0000" & ccb_crsv(4 downto 0) & ccb_drsv(1 downto 0) & ccb_rsvo(4 downto 0);
  ccb_other <= "00000" & ccb_cal(2 downto 0) & ccb_bx0 & ccb_bxrst & ccb_l1arst & ccb_l1acc
               & ccb_clken & ccb_evcntres & ccb_cmd_s & ccb_data_s;
  GEN_CCB_FD : for index in 0 to 15 generate
    FDOTHER : FDC port map(ccb_other_reg(index), ccb_other(index), reset, ccb_other_reg_b(index));
    FDRSV   : FDC port map(ccb_rsv_reg(index), ccb_rsv(index), reset, ccb_rsv_reg_b(index));
    ccb_other_reg_b(index) <= not ccb_other_reg(index);
    ccb_rsv_reg_b(index)   <= not ccb_rsv_reg(index);
  end generate GEN_CCB_FD;

  -- To DCFEBs
  dcfeb_l1a       <= '0' when mask_l1a(0) = '1' else int_l1a;
  dcfeb_resync    <= resync;
  dcfeb_reprgen_b <= '0';
  dcfeb_bc0       <= test_bc0 or not ccb_bx0;  -- New signal to DCFEB for syncing

  -- To QPLL
  qpll_autorestart <= '1';
  qpll_reset       <= '1';
  --qpll_reset       <= not reset;

  v6_jtag_sel <= v6_jtag_sel_inner;
  v6_tck      <= v6_tck_inner;
  v6_tms      <= v6_tms_inner;
  v6_tdi      <= v6_tdi_inner;

  d <= (others => '0');


---------------------------------  RESETS  ---------------------------------
-----------------------------------------------------------------------------
-- Power ON reset [The FD is to avoid an event on an array]
  FD_FW_RESET  : FD port map(fw_reset_q, clk2p5, fw_reset);
  FD_OPT_RESET : FD port map(opt_reset_pulse_q, clk2p5, opt_reset_pulse);
  pon_rst_reg <= x"3FFFFFFF" when (pll1_locked = '0') else
                 pon_rst_reg(30 downto 0) & '0' when clk2p5'event and clk2p5 = '1' else
                 pon_rst_reg;
  fw_rst_reg <= x"3FFFFFFF" when ((fw_reset_q = '0' and fw_reset = '1') or ccb_softrst = '0') else
                fw_rst_reg(30 downto 0) & '0' when clk2p5'event and clk2p5 = '1' else
                fw_rst_reg;
  opt_rst_reg <= x"3FFFFFFF" when (opt_reset_pulse_q = '0' and opt_reset_pulse = '1') else
                 opt_rst_reg(30 downto 0) & '0' when clk2p5'event and clk2p5 = '1' else
                 opt_rst_reg;
  pon_reset <= pon_rst_reg(31);
  reset     <= fw_rst_reg(31) or pon_rst_reg(31) or not pb(0);  -- Firmware reset
  opt_reset <= opt_rst_reg(31) or pon_rst_reg(31);  -- Optical reset

  -- FIFOs require more than 1 clock cycle to properly reset
  l1acnt_rst_start <= not ccb_evcntres or not ccb_l1arst or l1a_reset_pulse;
  PULSE_L1A    : NPULSE2FAST port map(l1acnt_rst_pulse, clk40, '0', 20, l1acnt_rst_start);
  l1acnt_rst       <= l1acnt_rst_pulse or reset;  -- reset is so long that it created problems
  PULSE_RESYNC : PULSE2SAME port map(resync, clk40, '0', l1acnt_rst_pulse);
  bxcnt_rst        <= not ccb_bxrst or reset;

  PULLUP_dtack_b     : PULLUP port map (vme_dtack_v6_b);
  PULLDOWN_DCFEB_TMS : PULLDOWN port map (dcfeb_tms_out);
  PULLDOWN_ODMB_TMS  : PULLDOWN port map (v6_tms);

  isnot_ODMB_V3V4 <= '1' when (odmb_id(15 downto 12) /= x"3" and odmb_id(15 downto 12) /= x"4") else '0';
  BUF_DCFEBTMS : IOBUF port map(O => odmb_tms, IO => DCFEB_TMS, I => dcfeb_tms_out, T => isnot_ODMB_V3V4);
  BUF_DCFEBTDI : IOBUF port map(O => odmb_tdi, IO => DCFEB_TDI, I => dcfeb_tdi_out, T => isnot_ODMB_V3V4);

  GEN_15 : for I in 0 to 15 generate
  begin
    PULLDOWN_FIFO : PULLDOWN port map (fifo_out(I));
    VME_BUF       : IOBUF port map (O => vme_data_in(I), IO => vme_data(I), I => vme_data_out(I), T => vme_tovme_b);
  end generate GEN_15;

-- From OT1 (GigaBit Link)
  gl0_rx_ibuf_p : IBUF port map (O => gl0_rx_buf_p, I => gl0_rx_p);
  gl0_rx_ibuf_n : IBUF port map (O => gl0_rx_buf_n, I => gl0_rx_n);

-- From OT2 (GigaBit Link)
  gl1_rx_ibuf_p : IBUF port map (O => gl1_rx_buf_p, I => gl1_rx_p);
  gl1_rx_ibuf_n : IBUF port map (O => gl1_rx_buf_n, I => gl1_rx_n);


-- From ORX1

  GEN_ORX : for I in 12 downto 1 generate
  begin
    orx_ibuf_p : IBUF port map (O => orx_buf_p(I), I => orx_p(I));
    orx_ibuf_n : IBUF port map (O => orx_buf_n(I), I => orx_n(I));
  end generate GEN_ORX;

  -- OT Manager
  orx_rx_en <= '1';
  orx_en_sd <= '0';
  orx_sq_en <= '0';

-- Initial Assignments

  lvmb_csb  <= int_lvmb_csb;
  lvmb_sclk <= int_lvmb_sclk;
  lvmb_sdin <= int_lvmb_sdin;

  lvmb_pon <= int_lvmb_pon(7 downto 0);

-----------------------------  Clock management  -----------------------------
-----------------------------------------------------------------------------

  qpll_clk40MHz_buf : IBUFDS port map (I => qpll_clk40MHz_p, IB => qpll_clk40MHz_n, O => qpll_clk40MHz);
  --qpll_clk80MHz_buf : IBUFDS port map (I => qpll_clk80MHz_p, IB => qpll_clk80MHz_n, O => qpll_clk80MHz);
  
  qpll_clk160MHz_buf : IBUFDS_GTXE1 port map (I => qpll_clk160MHz_p, IB => qpll_clk160MHz_n, CEB => '0',
                                              O => qpll_clk160MHz, ODIV2 => open);
  --qpll_clk160MHz_bufg : BUFR generic map (SIM_DEVICE => "VIRTEX6")
  --  port map (O => clk160, CE => '1', CLR => '0', I => qpll_clk160MHz);
  --qpll_clk160MHz_bufg : BUFG port map (O => clk160, I => qpll_clk160MHz);

  -- Clock for PC TX
  gl1_clk_buf_gtxe1 : IBUFDS_GTXE1 port map (I => gl1_clk_p, IB => gl1_clk_n, CEB => '0',
                                             O => gl1_clk, ODIV2 => open);

  -- Clock for DDU TX
  gl0_clk_buf_gtxe1 : IBUFDS_GTXE1 port map (I => gl0_clk_p, IB => gl0_clk_n, CEB => '0',
                                             O => gl0_clk, ODIV2 => gl0_clk_2);

  Divide_Frequency : process(clk40)
  begin
    if clk40'event and clk40 = '1' then
      if counter_clk = 2500000 then
        counter_clk <= 1;
        if clk8 = '1' then
          clk8 <= '0';
        else
          clk8 <= '1';
        end if;
      else
        counter_clk <= counter_clk + 1;
      end if;
      if counter_clk1mhz = 20 then
        counter_clk1mhz <= 1;
        if clk1mhz = '1' then
          clk1mhz <= '0';
        else
          clk1mhz <= '1';
        end if;
      else
        counter_clk1mhz <= counter_clk1mhz + 1;
      end if;
    end if;
  end process Divide_Frequency;
  clk1_inv <= not clk1;
  clk2_inv <= not clk2;
  clk4_inv <= not clk4;
  FD4 : FD port map (clk4, clk8, clk4_inv);
  FD2 : FD port map (clk2, clk4, clk2_inv);
  FD1 : FD port map (clk1, clk2, clk1_inv);

  Divide_Frequency_gl0 : process(dduclk)
  begin
    if dduclk'event and dduclk = '1' then
      if counter_clk_gl0 = 10000000 then
        counter_clk_gl0 <= 1;
        if gl0_clk_slow = '1' then
          gl0_clk_slow <= '0';
        else
          gl0_clk_slow <= '1';
        end if;
      else
        counter_clk_gl0 <= counter_clk_gl0 + 1;
      end if;
    end if;
  end process Divide_Frequency_gl0;

  Divide_Frequency_gl1 : process(pcclk)
  begin
    if pcclk'event and pcclk = '1' then
      if counter_clk_gl1 = 15625000 then
        counter_clk_gl1 <= 1;
        if gl1_clk_2_slow = '1' then
          gl1_clk_2_slow <= '0';
        else
          gl1_clk_2_slow <= '1';
        end if;
      else
        counter_clk_gl1 <= counter_clk_gl1 + 1;
      end if;
    end if;
  end process Divide_Frequency_gl1;

  pll1_rst <= '0';
  pll1_pd  <= '0';

  MMCM_BASE_PLL1 : MMCM_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",  -- Jitter programming ("HIGH","LOW","OPTIMIZED")
      CLKFBOUT_MULT_F    => 16.0,  -- Multiply value for all CLKOUT (5.0-64.0).
      CLKFBOUT_PHASE     => 0.0,  -- Phase offset in degrees of CLKFB (0.00-360.00).
      CLKIN1_PERIOD      => 25.0,  -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      CLKOUT0_DIVIDE_F   => 1.0,  -- Divide amount for CLKOUT0 (1.000-128.000).
      -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT6_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE      => 0.0,
      CLKOUT1_PHASE      => 0.0,
      CLKOUT2_PHASE      => 0.0,
      CLKOUT3_PHASE      => 0.0,
      CLKOUT4_PHASE      => 0.0,
      CLKOUT5_PHASE      => 0.0,
      CLKOUT6_PHASE      => 0.0,
      -- CLKOUT1_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT1_DIVIDE     => 16,         -- clk40 = CMSCLK(40 MHz)
      CLKOUT2_DIVIDE     => 64,   -- clk10 = MIDCLK(10 MHz)               
      CLKOUT3_DIVIDE     => 128,        -- clk5 - generates clk2p5 and clk1p25
      CLKOUT4_DIVIDE     => 8,          -- Not used
      CLKOUT5_DIVIDE     => 16,         -- Not used
      CLKOUT6_DIVIDE     => 16,         -- Not used
      CLKOUT4_CASCADE    => false,  -- Cascase CLKOUT4 counter with CLKOUT6 (TRUE/FALSE)
      CLOCK_HOLD         => false,      -- Hold VCO Frequency (TRUE/FALSE)
      DIVCLK_DIVIDE      => 1,          -- Master division value (1-80)
      REF_JITTER1        => 0.0,  -- Reference input jitter in UI (0.000-0.999).
      STARTUP_WAIT       => false       -- Not supported. Must be set to FALSE.
      )
    port map (
      -- Clock Outputs: 1-bit (each) User configurable clock outputs
      CLKOUT0   => open,                -- 1-bit CLKOUT0 output
      CLKOUT0B  => open,                -- 1-bit Inverted CLKOUT0 output
      CLKOUT1   => pll_clk40,           -- 1-bit CLKOUT1 output
      CLKOUT1B  => open,                -- 1-bit Inverted CLKOUT1 output
      CLKOUT2   => pll_clk10,           -- 1-bit CLKOUT2 output
      CLKOUT2B  => open,                -- 1-bit Inverted CLKOUT2 output
      CLKOUT3   => pll_clk5,            -- 1-bit CLKOUT3 output
      CLKOUT3B  => open,                -- 1-bit Inverted CLKOUT3 output
      CLKOUT4   => pll_clk80,           -- 1-bit CLKOUT4 output
      CLKOUT5   => open,                -- 1-bit CLKOUT5 output
      CLKOUT6   => open,                -- 1-bit CLKOUT6 output
      -- Feedback Clocks: 1-bit (each) Clock feedback ports
      CLKFBOUT  => pll1_fb,             -- 1-bit Feedback clock output
      CLKFBOUTB => open,                -- 1-bit Inverted CLKFBOUT output
      -- Status Port: 1-bit (each) MMCM status ports
      LOCKED    => pll1_locked,         -- 1-bit LOCK output
      -- Clock Input: 1-bit (each) Clock input
      CLKIN1    => qpll_clk40MHz,       -- qpll_clk40MHz,
      -- Control Ports: 1-bit (each) MMCM control ports
      PWRDWN    => pll1_pd,             -- 1-bit Power-down input
      RST       => pll1_rst,            -- 1-bit Reset input
      -- Feedback Clocks: 1-bit (each) Clock feedback ports
      CLKFBIN   => pll1_fb              -- 1-bit Feedback clock input
      );


---- Global Clock Buffers

  clk80_buf : BUFG port map (I => pll_clk80, O => clk80);
  clk40_buf : BUFG port map (I => pll_clk40, O => clk40);
  clk10_buf : BUFG port map (I => pll_clk10, O => clk10);
  clk5_buf  : BUFG port map (I => pll_clk5, O => clk5);
  clk2p5_buf  : BUFG port map (I => clk2p5_unbuf, O => clk2p5);

-- Frequency dividers for the 2.5 and 1.25 MHz clocks which are too slow for the PLL 
  clk2p5_inv  <= not clk2p5_unbuf;
  clk1p25_inv <= not clk1p25;
  FD2p5  : FD port map (D => clk2p5_inv, C => clk5, Q => clk2p5_unbuf);
  FD1p25 : FD port map (D => clk1p25_inv, C => clk2p5, Q => clk1p25);


  vme_dtack_v6_b <= int_vme_dtack_v6_b;

  bpi_rst <= reset or vme_bpi_rst;
--  bpi_rst <= reset;
  BPI_ctrl_i : BPI_ctrl
    port map (
--      CLK               => clk2p5,      -- 40 MHz clock
      CLK               => clk40,
      CLK1MHZ           => clk1mhz,     --  1 MHz clock for timers
      RST               => bpi_rst,
-- Interface Signals to/from VME interface
      BPI_CMD_FIFO_DATA => bpi_cmd_fifo_data,  -- Data for command FIFO
      BPI_WE            => bpi_we,  -- Command FIFO write enable  (pulse one clock cycle for one write)
      BPI_RE            => bpi_re,  -- Read back FIFO read enable  (pulse one clock cycle for one read)
      BPI_DSBL          => bpi_dsbl,  -- Disable parsing of BPI commands in the command FIFO (while being filled)
      BPI_ENBL          => bpi_enbl,  -- Enable  parsing of BPI commands in the command FIFO
      BPI_RBK_FIFO_DATA => bpi_rbk_fifo_data,  -- Data on output of the Read back FIFO
      BPI_RBK_WRD_CNT   => bpi_rbk_wrd_cnt,  -- Word count of the Read back FIFO (number of available reads)
      BPI_STATUS        => bpi_status,  -- FIFO status bits and latest value of the PROM status register. 
      BPI_TIMER         => bpi_timer,   -- General timer
-- Signals to/from low level BPI interface
      BPI_BUSY          => bpi_busy,  -- Operation in progress signal (not ready)
      BPI_DATA_FROM     => bpi_data_from,  -- Data read from FLASH device      -- Data read from FLASH device
      BPI_LOAD_DATA     => bpi_load_data,  -- Clock enable signal for capturing Data read from FLASH device
      BPI_ACTIVE        => bpi_active,  -- output set to 1 when data lines are for BPI communications.
      BPI_OP            => bpi_op,  -- Operation: 00-standby, 01-write, 10-read, 11-not allowed(standby)
      BPI_ADDR          => bpi_addr,    -- Bank/Array Address
      BPI_DATA_TO       => bpi_data_to,  -- Command or Data being written to FLASH device
      BPI_EXECUTE       => bpi_execute,
      -- Guido - Aug 26
      BPI_DONE          => bpi_done,
      BPI_CFG_REG_WE    => bpi_cfg_reg_we,
      BPI_CFG_REG_IN    => bpi_cfg_reg_in
      );

  bpi_interface_i : bpi_interface
    port map (
      --CLK          => clk2p5,           -- 40 MHz clock
      CLK          => clk40,
      RST          => bpi_rst,
      ADDR         => bpi_addr,         -- Bank/Array Address 
      CMD_DATA_OUT => bpi_data_to,  -- Command or Data being written to FLASH device
      OP           => bpi_op,  -- Operation: 00-standby, 01-write, 10-read, 11-not allowed(standby)
      EXECUTE      => bpi_execute,
      DATA_IN      => bpi_data_from,    -- Data read from FLASH device
      LOAD_DATA    => bpi_load_data,  -- Clock enable signal for capturing Data read from FLASH device
      BUSY         => bpi_busy,    -- Operation in progress signal (not ready)
-- signals for Dual purpose data lines
      BPI_ACTIVE   => bpi_active,  -- set to 1 when data lines are for BPI communications.
      DUAL_DATA    => dual_data_leds,  -- Data provided for non BPI communications
-- external connections cooresponding to I/O pins
      bpi_ad_out_r => prom_a_out,
      data_out_i   => prom_d_out,
      PROM_CONTROL => prom_control,
      BPI_AD       => prom_a,
      CFG_DAT      => prom_d,
      RS0          => prom_a_21_rs0,
      RS1          => prom_a_22_rs1,
      FCS_B        => prom_cs_b,
      FOE_B        => prom_oe_b,
      FWE_B        => prom_we_b,
      FLATCH_B     => prom_le_b
      );

  csp_bpi_la_pm : csp_bpi_la
    port map (
      CONTROL => csp_bpi_la_ctrl,
      CLK     => clk80,
      DATA    => csp_bpi_la_data,
      TRIG0   => csp_bpi_la_trig
      );

  --csp_bpi_la_trig <= bpi_enbl & bpi_dsbl & cmd_adrs(13 downto 0);

  --csp_bpi_la_data <= "00" & x"0"
  --                   & bpi_cfg_ul_pulse & bpi_cfg_dl_pulse &clk40 & clk2p5  -- [293:290]
  --                   & vme_ds_b & vme_as_b & vme_write_b & vme_dtack_v6_b  -- [289:285]
  --                   & cmd_adrs         -- [284:269]
  --                   & vme_data_in      -- [268:253]
  --                   & bpi_busy & bpi_enbl & bpi_dsbl & bpi_re & bpi_we & vme_bpi_rst & bpi_rst  -- [252:246]
  --                   & bpi_cfg_reg_we & bpi_done & bpi_execute & bpi_active & bpi_load_data  -- [245:241]
  --                   & bpi_op & bpi_cfg_reg_in                -- [240:223]
  --                   & bpi_status & bpi_timer                 -- [222:175]
  --                   & bpi_rbk_wrd_cnt & bpi_addr             -- [174:141]
  --                   & bpi_cmd_fifo_data & bpi_rbk_fifo_data  -- [140:109]
  --                   & bpi_data_from & bpi_data_to            -- [108:77]
  --                   & dual_data_leds   -- [76:61]
  --                   & x"0000"          -- [60:45]
  --                   & prom_control     -- [44:39]
  --                   & prom_a_out       -- [38:16]
  --                   & prom_d_out;      -- [15:0]

------------------------------------  Monitoring  ------------------------------------
---------------------------------------------------------------------------------------

  -- To SYSMON
  vauxp <= x"00" & p5v_lvmb_sm_p & p1v0_sm_p & therm1_p & p2v5_sm_p
           & p3v3_pp_sm_p & therm2_p & p5v_sm_p & lv_p3v3_sm_p;
  vauxn <= x"00" & p5v_lvmb_sm_n & p1v0_sm_n & therm1_n & p2v5_sm_n
           & p3v3_pp_sm_n & therm2_n & p5v_sm_n & lv_p3v3_sm_n;


  INTL1A_CNT  : COUNT_EDGES port map(int_l1a_cnt, clk40, l1acnt_rst, int_l1a);
  ALCTDAV_CNT : COUNT_EDGES port map(alct_dav_cnt, clk40, reset, int_alct_dav);
  OTMBDAV_CNT : COUNT_EDGES port map(otmb_dav_cnt, clk40, reset, int_otmb_dav);
  DDUEOF_CNT  : COUNT_EDGES port map(ddu_eof_cnt, clk40, reset, ddu_eof);
  PCOF_CNT    : COUNT_EDGES port map(gtx1_data_valid_cnt, pcclk, reset, gtx1_data_valid);
  LOCKED_CNT  : COUNT_EDGES port map(qpll_locked_cnt, dduclk, reset, qpll_locked);

  NFEB_CNT : for dev in 1 to NFEB generate
  begin
    RAWLCT_CNT : COUNT_EDGES port map(raw_lct_cnt(dev), clk40, reset, raw_lct(dev));
    CRC_CNT    : COUNT_EDGES port map(goodcrc_cnt(dev), clk160, reset, crc_valid(dev));
    LCTL1AGAP  : GAP_COUNTER generic map (200) port map(lct_l1a_gap(dev), clk40, reset, raw_lct(dev), int_l1a);
  end generate NFEB_CNT;

  NFEB2_CNT : for dev in 1 to NFEB+2 generate
  begin
    FIFOOE_CNT    : COUNT_EDGES port map(data_fifo_oe_cnt(dev), dduclk, reset, data_fifo_oe(dev));
    FIFORE_CNT    : COUNT_EDGES port map(data_fifo_re_cnt(dev), dduclk, reset, data_fifo_re(dev));
    L1AMATCH_CNT  : COUNT_EDGES port map(l1a_match_cnt(dev), clk40, reset, cafifo_l1a_match_in(dev));
    PACKET_CNT    : COUNT_EDGES port map(into_cafifo_dav_cnt(dev), clk40, reset, into_cafifo_dav(dev));
    DATAEOF_CNT   : COUNT_EDGES port map(eof_data_cnt(dev), clk40, reset, eof_data(dev));
    CAFIFODAV_CNT : COUNT_EDGES port map(cafifo_l1a_dav_cnt(dev), dduclk, reset, cafifo_l1a_dav(dev));
  end generate NFEB2_CNT;

  L1AALCTGAP : GAP_COUNTER port map(l1a_alctdav_gap, clk40, reset, raw_l1a, int_alct_dav);
  L1AOTMBGAP : GAP_COUNTER port map(l1a_otmbdav_gap, clk40, reset, raw_l1a, int_otmb_dav);

  -- Defined to count the ALCT and OTMB davs as well 
  into_cafifo_dav(NFEB downto 1) <= dcfeb_data_valid(NFEB downto 1);  -- MUXed from gen and real
  into_cafifo_dav(8)             <= otmb_fifo_data_valid;
  into_cafifo_dav(9)             <= alct_fifo_data_valid;



  clk_led <= clk2p5;
  FDRESET : FD port map(reset_q, clk_led, reset);

  led_cnt_proc : process (clk_led, reset, led_cnt_en)
    variable led_cnt_data : integer := 0;
  begin
    if (reset = '1') then
      led_cnt_data := 0;
    elsif (rising_edge(clk_led)) then
      if led_cnt_rst = '1' then
        led_cnt_data := 0;
      elsif(led_cnt_en = '1') then
        led_cnt_data := led_cnt_data + 1;
      end if;
    end if;

    led_cnt <= led_cnt_data;
  end process;


  led_fsm_regs : process (clk_led, led_next_state, reset)
  begin
    if (reset = '1') then
      led_current_state <= LED_IDLE;
    elsif rising_edge(clk_led) then
      led_current_state <= led_next_state;
    end if;
  end process;

  led_fsm_logic : process (led_current_state, reset, led_cnt, clk2, gl0_clk_slow,
                           gl1_clk_2_slow, pb, cafifo_l1a_cnt)
  begin
    case led_current_state is
      when LED_IDLE =>
        ledg(1) <= gl0_clk_slow;
        ledg(2) <= gl1_clk_2_slow;
        ledg(3) <= clk1;
        --ledg(4) <= pedestal;
        ledg(4) <= not qpll_locked;
        ledg(5) <= testctrl_sel;
        ledg(6) <= gen_dcfeb_sel;

        ledr(5 downto 1) <= not int_l1a_cnt(4 downto 0);
        ledr(6)          <= pb(1) and not led_pulse;

        if (reset = '0' and reset_q = '1') then
          led_next_state <= LED_COUNTING;
          led_cnt_rst    <= '1';
          led_cnt_en     <= '0';
        else
          led_next_state <= LED_IDLE;
          led_cnt_rst    <= '0';
          led_cnt_en     <= '0';
        end if;
        
      when LED_COUNTING =>
        ledg(1) <= clk4;
        ledg(2) <= clk2;
        ledg(3) <= clk1;
        ledg(4) <= clk1;
        ledg(5) <= clk2;
        ledg(6) <= clk4;
        ledr(1) <= clk4;
        ledr(2) <= clk2;
        ledr(3) <= clk1;
        ledr(4) <= clk1;
        ledr(5) <= clk2;
        ledr(6) <= clk4;
        if (led_cnt > 4000000) then
          led_next_state <= LED_IDLE;
          led_cnt_rst    <= '0';
          led_cnt_en     <= '0';
        else
          led_next_state <= LED_COUNTING;
          led_cnt_rst    <= '0';
          led_cnt_en     <= '1';
        end if;

      when others =>
        led_next_state <= LED_IDLE;
        ledr           <= (others => '0');
        ledg           <= (others => '0');
        led_cnt_rst    <= '1';
        led_cnt_en     <= '0';
        
    end case;
  end process;

  odmb_status <= x"00" & "000" & orx_sd & vme_berr_b & qpll_error & QPLL_LOCKED & DONE_IN;

  odmb_status_pro : process (odmb_status, odmb_ctrl_reg, dcfeb_adc_mask, dcfeb_fsel, dcfeb_jtag_ir, odmb_data_sel,
                             l1a_match_cnt, lct_l1a_gap, into_cafifo_dav_cnt, cafifo_l1a_match_out, cafifo_l1a_dav,
                             data_fifo_re_cnt, gtx1_data_valid_cnt, ddu_eof_cnt, data_fifo_oe_cnt, goodcrc_cnt,
                             alct_dav_cnt, otmb_dav_cnt, cafifo_rd_addr, cafifo_wr_addr,
                             cafifo_prev_next_l1a_match, cafifo_prev_next_l1a, cafifo_debug, control_debug)
  begin
    
    case odmb_data_sel is

      when x"00" => odmb_data <= odmb_status;
      when x"01" => odmb_data <= odmb_ctrl_reg;

      when x"02" => odmb_data <= cafifo_debug;  --cafifo_empty & cafifo_full & cafifo_state_slv & timeout_state_1
                                                --& timeout_state_9 & lone(rd_addr_out) & lost_pckt(rd_addr_out)(8 downto 2);
      when x"03" => odmb_data <= cafifo_prev_next_l1a;
      when x"04" => odmb_data <= cafifo_prev_next_l1a_match;

      when x"05" => odmb_data <= control_debug;  --'0' & dev_cnt_svl & '0' & hdr_tail_cnt_svl & current_state_svl;
      when x"06" => odmb_data <= x"0000";
      when x"07" => odmb_data <= x"0000";

      when x"08" => odmb_data <= "0000" & dcfeb_adc_mask(3);
      when x"09" => odmb_data <= dcfeb_fsel(3)(15 downto 0);
      when x"0A" => odmb_data <= dcfeb_fsel(3)(31 downto 16);
      when x"0B" => odmb_data <= "00" & dcfeb_jtag_ir(3) & "000" & dcfeb_fsel(3)(31);

      when x"0C" => odmb_data <= "0000" & dcfeb_adc_mask(4);
      when x"0D" => odmb_data <= dcfeb_fsel(4)(15 downto 0);
      when x"0E" => odmb_data <= dcfeb_fsel(4)(31 downto 16);
      when x"0F" => odmb_data <= "00" & dcfeb_jtag_ir(4) & "000" & dcfeb_fsel(4)(31);

      when x"10" => odmb_data <= "0000" & dcfeb_adc_mask(5);
      when x"11" => odmb_data <= dcfeb_fsel(5)(15 downto 0);
      when x"12" => odmb_data <= dcfeb_fsel(5)(31 downto 16);
      when x"13" => odmb_data <= "00" & dcfeb_jtag_ir(5) & "000" & dcfeb_fsel(5)(31);

      when x"14" => odmb_data <= "0000" & dcfeb_adc_mask(6);
      when x"15" => odmb_data <= dcfeb_fsel(6)(15 downto 0);
      when x"16" => odmb_data <= dcfeb_fsel(6)(31 downto 16);
      when x"17" => odmb_data <= "00" & dcfeb_jtag_ir(6) & "000" & dcfeb_fsel(6)(31);

      when x"18" => odmb_data <= "0000" & dcfeb_adc_mask(7);
      when x"19" => odmb_data <= dcfeb_fsel(7)(15 downto 0);
      when x"1A" => odmb_data <= dcfeb_fsel(7)(31 downto 16);
      when x"1B" => odmb_data <= "00" & dcfeb_jtag_ir(7) & "000" & dcfeb_fsel(7)(31);

      when x"1C" => odmb_data <= x"0000";
      when x"1D" => odmb_data <= x"0000";
      when x"1E" => odmb_data <= x"0000";
      when x"1F" => odmb_data <= x"0000";

      when x"20" => odmb_data <= "0000000000" & vme_gap & vme_ga;

      when x"21" => odmb_data <= l1a_match_cnt(1);
      when x"22" => odmb_data <= l1a_match_cnt(2);
      when x"23" => odmb_data <= l1a_match_cnt(3);
      when x"24" => odmb_data <= l1a_match_cnt(4);
      when x"25" => odmb_data <= l1a_match_cnt(5);
      when x"26" => odmb_data <= l1a_match_cnt(6);
      when x"27" => odmb_data <= l1a_match_cnt(7);
      when x"28" => odmb_data <= l1a_match_cnt(8);
      when x"29" => odmb_data <= l1a_match_cnt(9);


      when x"2A" => odmb_data <= std_logic_vector(to_unsigned(alct_push_dly, 16));
      when x"2B" => odmb_data <= std_logic_vector(to_unsigned(otmb_push_dly, 16));
      when x"2C" => odmb_data <= std_logic_vector(to_unsigned(push_dly, 16));
      when x"2D" => odmb_data <= "0000000000" & lct_l1a_dly;
      when x"2E" => odmb_data <= ts_out(15 downto 0);
      when x"2F" => odmb_data <= ts_out(31 downto 16);

      when x"31" => odmb_data <= lct_l1a_gap(1);
      when x"32" => odmb_data <= lct_l1a_gap(2);
      when x"33" => odmb_data <= lct_l1a_gap(3);
      when x"34" => odmb_data <= lct_l1a_gap(4);
      when x"35" => odmb_data <= lct_l1a_gap(5);
      when x"36" => odmb_data <= lct_l1a_gap(6);
      when x"37" => odmb_data <= lct_l1a_gap(7);
      when x"38" => odmb_data <= l1a_otmbdav_gap;
      when x"39" => odmb_data <= l1a_alctdav_gap;

      when x"3A" => odmb_data <= "00000000" & cafifo_l1a_cnt(23 downto 16);
      when x"3B" => odmb_data <= cafifo_l1a_cnt(15 downto 0);
      when x"3C" => odmb_data <= "0000" & cafifo_bx_cnt;
      when x"3D" => odmb_data <= cafifo_rd_addr & cafifo_wr_addr;
      when x"3E" => odmb_data <= "0000000" & cafifo_l1a_match_in;
      when x"3F" => odmb_data <= int_l1a_cnt;

      when x"41" => odmb_data <= into_cafifo_dav_cnt(1);
      when x"42" => odmb_data <= into_cafifo_dav_cnt(2);
      when x"43" => odmb_data <= into_cafifo_dav_cnt(3);
      when x"44" => odmb_data <= into_cafifo_dav_cnt(4);
      when x"45" => odmb_data <= into_cafifo_dav_cnt(5);
      when x"46" => odmb_data <= into_cafifo_dav_cnt(6);
      when x"47" => odmb_data <= into_cafifo_dav_cnt(7);
      when x"48" => odmb_data <= into_cafifo_dav_cnt(8);
      when x"49" => odmb_data <= into_cafifo_dav_cnt(9);

      when x"4A" => odmb_data <= ddu_eof_cnt;  -- Number of packets sent to DDU
      when x"4B" => odmb_data <= gtx1_data_valid_cnt;  -- Number of packets sent to PC
      when x"4C" => odmb_data <= data_fifo_oe_cnt(1);  -- from control to FIFOs in top
      when x"4D" => odmb_data <= "0000000" & cafifo_l1a_match_out;
      when x"4E" => odmb_data <= "0000000" & cafifo_l1a_dav;
      when x"4F" => odmb_data <= qpll_locked_cnt;

      when x"51" => odmb_data <= data_fifo_re_cnt(1);  -- from control to FIFOs in top
      when x"52" => odmb_data <= data_fifo_re_cnt(2);  -- from control to FIFOs in top
      when x"53" => odmb_data <= data_fifo_re_cnt(3);  -- from control to FIFOs in top
      when x"54" => odmb_data <= data_fifo_re_cnt(4);  -- from control to FIFOs in top
      when x"55" => odmb_data <= data_fifo_re_cnt(5);  -- from control to FIFOs in top
      when x"56" => odmb_data <= data_fifo_re_cnt(6);  -- from control to FIFOs in top
      when x"57" => odmb_data <= data_fifo_re_cnt(7);  -- from control to FIFOs in top
      when x"58" => odmb_data <= data_fifo_re_cnt(8);  -- from control to FIFOs in top
      when x"59" => odmb_data <= data_fifo_re_cnt(9);  -- from control to FIFOs in top
      when x"5A" => odmb_data <= ccb_cmd_reg;
      when x"5B" => odmb_data <= ccb_data_reg;
      when x"5C" => odmb_data <= ccb_other_reg;
      when x"5D" => odmb_data <= ccb_rsv_reg;

      when x"61" => odmb_data <= goodcrc_cnt(1);
      when x"62" => odmb_data <= goodcrc_cnt(2);
      when x"63" => odmb_data <= goodcrc_cnt(3);
      when x"64" => odmb_data <= goodcrc_cnt(4);
      when x"65" => odmb_data <= goodcrc_cnt(5);
      when x"66" => odmb_data <= goodcrc_cnt(6);
      when x"67" => odmb_data <= goodcrc_cnt(7);

      when x"71" => odmb_data <= raw_lct_cnt(1);
      when x"72" => odmb_data <= raw_lct_cnt(2);
      when x"73" => odmb_data <= raw_lct_cnt(3);
      when x"74" => odmb_data <= raw_lct_cnt(4);
      when x"75" => odmb_data <= raw_lct_cnt(5);
      when x"76" => odmb_data <= raw_lct_cnt(6);
      when x"77" => odmb_data <= raw_lct_cnt(7);
      when x"78" => odmb_data <= otmb_dav_cnt;
      when x"79" => odmb_data <= alct_dav_cnt;

      when x"81" => odmb_data <= eof_data_cnt(1);  -- Number of packets arrived in full
      when x"82" => odmb_data <= eof_data_cnt(2);  -- Number of packets arrived in full
      when x"83" => odmb_data <= eof_data_cnt(3);  -- Number of packets arrived in full
      when x"84" => odmb_data <= eof_data_cnt(4);  -- Number of packets arrived in full
      when x"85" => odmb_data <= eof_data_cnt(5);  -- Number of packets arrived in full
      when x"86" => odmb_data <= eof_data_cnt(6);  -- Number of packets arrived in full
      when x"87" => odmb_data <= eof_data_cnt(7);  -- Number of packets arrived in full
      when x"88" => odmb_data <= eof_data_cnt(8);  -- Number of packets arrived in full
      when x"89" => odmb_data <= eof_data_cnt(9);  -- Number of packets arrived in full

      when x"91" => odmb_data <= cafifo_l1a_dav_cnt(1);  -- Times data has been available
      when x"92" => odmb_data <= cafifo_l1a_dav_cnt(2);  -- Times data has been available
      when x"93" => odmb_data <= cafifo_l1a_dav_cnt(3);  -- Times data has been available
      when x"94" => odmb_data <= cafifo_l1a_dav_cnt(4);  -- Times data has been available
      when x"95" => odmb_data <= cafifo_l1a_dav_cnt(5);  -- Times data has been available
      when x"96" => odmb_data <= cafifo_l1a_dav_cnt(6);  -- Times data has been available
      when x"97" => odmb_data <= cafifo_l1a_dav_cnt(7);  -- Times data has been available
      when x"98" => odmb_data <= cafifo_l1a_dav_cnt(8);  -- Times data has been available
      when x"99" => odmb_data <= cafifo_l1a_dav_cnt(9);  -- Times data has been available

      when others => odmb_data <= (others => '1');
    end case;
  end process;


  test_point(13) <= raw_lct(1);
  test_point(15) <= raw_lct(2);
  test_point(17) <= raw_lct(3);
  test_point(19) <= raw_lct(4);
  test_point(21) <= raw_lct(5);
  test_point(23) <= raw_lct(6);
  test_point(25) <= raw_lct(7);
  test_point(14) <= int_l1a_match(1);
  test_point(16) <= int_l1a_match(2);
  test_point(18) <= int_l1a_match(3);
  test_point(20) <= int_l1a_match(4);
  test_point(22) <= int_l1a_match(5);
  test_point(24) <= int_l1a_match(6);
  test_point(26) <= int_l1a_match(7);
  test_point(27) <= int_l1a;
  test_point(28) <= gtx0_data_valid;
  test_point(29) <= int_otmb_dav;
  test_point(30) <= int_alct_dav;

  --test_point(29) <= cafifo_l1a_dav(1);
  --test_point(30) <= cafifo_l1a_dav(2);
  --test_point(31) <= gtx0_data_valid;
  --test_point(32) <= gtx1_data_valid;
  --test_point(33) <= rawlct(1);
  --test_point(34) <= rawlct(2);
  --test_point(35) <= rawlct(3);
  --test_point(36) <= rawlct(4);
  --test_point(37) <= rawlct(5);
  --test_point(38) <= rawlct(6);
  --test_point(39) <= rawlct(7);
  --test_point(40) <= lct_err;
  --test_point(44) <= '0';
  --test_point(46) <= '0';

  test_point(47) <= dcfeb_tdi_out;
  test_point(48) <= lct_err;
  test_point(49) <= dcfeb_tms_out;
  test_point(50) <= '1';

  tp_selector : process (tp_sel_reg, gtx0_data_valid, cafifo_l1a_dav, int_l1a_match, dcfeb_data_valid,
                         int_otmb_dav, dcfeb_data, otmb_fifo_data_in, otmb_fifo_data_valid, int_alct_dav,
                         alct_fifo_data_in,
                         alct_fifo_data_valid, ext_dcfeb_l1a_cnt7, dcfeb_l1a_dav7, odmb_tdo,
                         v6_jtag_sel_inner, dcfeb_tms_out, dcfeb_tdi_out, int_tck, int_tdo, raw_lct, rawlct,
                         int_l1a, cafifo_l1a,
                         otmb_lct_rqst, otmb_ext_trig, raw_l1a, ALCT_DAV_SYNC_OUT, OTMB_DAV_SYNC_OUT,
                         dcfeb_prbs_en, dcfeb_prbs_rst, dcfeb_prbs_rd_en, dcfeb_rxprbserr,
                         int_lvmb_sclk, int_lvmb_sdin, lvmb_sdout, int_lvmb_csb, alct_qq, otmb_qq,
                         nwords_dummy, lct_l1a_dly)
  begin
    case tp_sel_reg is
      when x"0000" =>
        test_point(46 downto 31) <= (
          tp_1   => '0',
          tp_2   => '1',
          tp_3   => nwords_dummy(0),
          tp_4   => lct_l1a_dly(0),
          others => '0');

      when x"0001" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a_match(1),
          tp_2   => cafifo_l1a_dav(1),
          tp_3   => dcfeb_data(1)(0),
          tp_4   => dcfeb_data_valid(1),
          others => '0');

      when x"0002" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a_match(2),
          tp_2   => cafifo_l1a_dav(2),
          tp_3   => dcfeb_data(2)(0),
          tp_4   => dcfeb_data_valid(2),
          others => '0');

      when x"0003" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a_match(3),
          tp_2   => cafifo_l1a_dav(3),
          tp_3   => dcfeb_data(3)(0),
          tp_4   => dcfeb_data_valid(3),
          others => '0');

      when x"0004" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a_match(4),
          tp_2   => cafifo_l1a_dav(4),
          tp_3   => dcfeb_data(4)(0),
          tp_4   => dcfeb_data_valid(4),
          others => '0');

      when x"0005" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a_match(5),
          tp_2   => cafifo_l1a_dav(5),
          tp_3   => dcfeb_data(5)(0),
          tp_4   => dcfeb_data_valid(5),
          others => '0');

      when x"0006" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a_match(6),
          tp_2   => cafifo_l1a_dav(6),
          tp_3   => dcfeb_data(6)(0),
          tp_4   => dcfeb_data_valid(6),
          others => '0');

      when x"0007" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a_match(7),
          tp_2   => cafifo_l1a_dav(7),
          tp_3   => dcfeb_data(7)(0),
          tp_4   => dcfeb_data_valid(7),
          others => '0');

      when x"0008" =>
        test_point(46 downto 31) <= (
          tp_1   => int_otmb_dav,
          tp_2   => cafifo_l1a_dav(8),
          tp_3   => otmb_fifo_data_in(0),
          tp_4   => otmb_fifo_data_valid,
          others => '0');

      when x"0009" =>
        test_point(46 downto 31) <= (
          tp_1   => int_alct_dav,
          tp_2   => cafifo_l1a_dav(9),
          tp_3   => alct_fifo_data_in(0),
          tp_4   => alct_fifo_data_valid,
          others => '0');

      when x"000A" =>
        test_point(46 downto 31) <= (
          tp_1   => ext_dcfeb_l1a_cnt7(0),
          tp_2   => dcfeb_l1a_dav7,
          tp_3   => dcfeb_data(7)(0),
          tp_4   => dcfeb_data_valid(7),
          others => '0');

      when x"0010" =>
        test_point(46 downto 31) <= (
          tp_1   => odmb_tdo,
          tp_2   => odmb_tdo,
          tp_3   => odmb_tdo,
          tp_4   => dcfeb_data_valid(7),
          others => '0');

      when x"0011" =>
        test_point(46 downto 31) <= (
          tp_1   => gtx1_data_valid,
          tp_2   => pc_tx_fifo_wren,
          tp_3   => pc_txd_frame(0),
          tp_4   => pc_txd_frame(1),
          others => '0');

      when x"0012" =>
        test_point(46 downto 31) <= (
          tp_1   => gtx1_data_valid,
          tp_2   => gl_pc_tx_ack,
          tp_3   => rom_cnt_out(0),
          tp_4   => rom_cnt_out(1),
          others => '0');

      when x"0013" =>
        test_point(46 downto 31) <= (
          tp_1   => dcfeb_tdi_out,
          tp_2   => dcfeb_tms_out,
          tp_3   => int_tdo(7),
          tp_4   => int_tck(7),
          others => '0');

      when x"0014" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_lct_rqst,
          tp_2   => otmb_ext_trig,
          tp_3   => raw_lct(0),
          tp_4   => raw_lct(1),
          others => '0');

      when x"0015" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a,
          tp_2   => raw_l1a,
          tp_3   => raw_lct(0),
          tp_4   => raw_lct(1),
          others => '0');

      when x"0016" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a,
          tp_2   => raw_l1a,
          tp_3   => alctdav,
          tp_4   => otmbdav,
          others => '0');

      when x"0017" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a,
          tp_2   => raw_l1a,
          tp_3   => alct(16),
          tp_4   => alct(17),
          others => '0');

      when x"0018" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a,
          tp_2   => raw_l1a,
          tp_3   => otmb(16),
          tp_4   => otmb(17),
          others => '0');

      when x"0019" =>
        test_point(46 downto 31) <= (
          tp_1   => ALCT_DAV_SYNC_OUT,
          tp_2   => cafifo_l1a,
          tp_3   => otmbdav,
          tp_4   => OTMB_DAV_SYNC_OUT,
          others => '0');

      when x"001A" =>
        test_point(46 downto 31) <= (
          tp_1   => ccb_cal(2),
          tp_2   => ccb_cal(1),
          tp_3   => ccb_cal(0),
          tp_4   => ccb_cmd(5),
          others => '0');

      when x"001B" =>
        test_point(46 downto 31) <= (
          tp_1   => ccb_cmd(4),
          tp_2   => ccb_cmd(3),
          tp_3   => ccb_cmd(2),
          tp_4   => ccb_cmd(1),
          others => '0');

      when x"001C" =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a,
          tp_2   => ccb_cal(1),
          tp_3   => ccb_cal(0),
          tp_4   => raw_l1a,
          others => '0');

      when x"001D" =>
        test_point(46 downto 31) <= (
          tp_1   => vme_ds_b(0),
          tp_2   => vme_as_b,
          tp_3   => vme_dtack_v6_b,
          tp_4   => vme_write_b,
          others => '0');

      when x"001E" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_rx(5),
          tp_2   => otmb_rx(4),
          tp_3   => otmb_rx(3),
          tp_4   => otmb_rx(2),
          others => '0');

      when x"001F" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_rx(1),
          tp_2   => otmb_rx(0),
          tp_3   => rawlct(1),
          tp_4   => int_l1a_match(1),
          others => '0');

      when x"0020" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(48),
          tp_2   => otmb_tx(47),
          tp_3   => otmb_tx(46),
          tp_4   => otmb_tx(45),
          others => '0');

      when x"0021" =>
        test_point(46 downto 31) <= (
          tp_1   => alct_qq(17),
          tp_2   => alct_qq(16),
          tp_3   => alct_qq(15),
          tp_4   => alct_qq(14),
          others => '0');

      when x"0022" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_qq(17),
          tp_2   => otmb_qq(16),
          tp_3   => otmb_qq(15),
          tp_4   => otmb_qq(14),
          others => '0');

      when x"0023" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(36),
          tp_2   => otmb_tx(35),
          tp_3   => otmb_tx(34),
          tp_4   => otmb_tx(33),
          others => '0');

      when x"0024" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(32),
          tp_2   => otmb_tx(31),
          tp_3   => otmb_tx(30),
          tp_4   => otmb_tx(29),
          others => '0');

      when x"0025" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(28),
          tp_2   => otmb_tx(27),
          tp_3   => otmb_tx(26),
          tp_4   => otmb_tx(25),
          others => '0');

      when x"0026" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(24),
          tp_2   => otmb_tx(23),
          tp_3   => otmb_tx(22),
          tp_4   => otmb_tx(21),
          others => '0');

      when x"0027" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(20),
          tp_2   => otmb_tx(19),
          tp_3   => otmb_tx(18),
          tp_4   => otmb_tx(17),
          others => '0');

      when x"0028" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(16),
          tp_2   => otmb_tx(15),
          tp_3   => otmb_tx(14),
          tp_4   => otmb_tx(13),
          others => '0');

      when x"0029" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(12),
          tp_2   => otmb_tx(11),
          tp_3   => otmb_tx(10),
          tp_4   => otmb_tx(9),
          others => '0');

      when x"002A" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(8),
          tp_2   => otmb_tx(7),
          tp_3   => otmb_tx(6),
          tp_4   => otmb_tx(5),
          others => '0');

      when x"002B" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(4),
          tp_2   => otmb_tx(3),
          tp_3   => otmb_tx(2),
          tp_4   => otmb_tx(1),
          others => '0');

      when x"002C" =>
        test_point(46 downto 31) <= (
          tp_1   => otmb_tx(0),
          tp_2   => raw_lct(1),
          tp_3   => rawlct(1),
          tp_4   => int_l1a_match(1),
          others => '0');

      when x"002D" =>
        test_point(46 downto 31) <= (
          tp_1   => dcfeb_prbs_en,
          tp_2   => dcfeb_prbs_rst,
          tp_3   => dcfeb_prbs_rd_en,
          tp_4   => dcfeb_rxprbserr,
          others => '0');

      when x"002E" =>
        test_point(46 downto 31) <= (
          tp_1   => v6_jtag_sel_inner,
          tp_2   => v6_tck_inner,
          tp_3   => v6_tms_inner,
          tp_4   => v6_tdi_inner,
          others => '0');

      when x"002F" =>
        test_point(46 downto 31) <= (
          tp_1   => lvmb_sdout,
          tp_2   => int_lvmb_sclk,
          tp_3   => int_lvmb_sdin,
          tp_4   => int_lvmb_csb(0),
          others => '0');

      when others =>
        test_point(46 downto 31) <= (
          tp_1   => int_l1a,
          tp_2   => raw_lct(1),
          tp_3   => rawlct(1),
          tp_4   => int_l1a_match(1),
          others => '0');
    end case;
  end process;

  
end ODMB_UCSB_V2_ARCH;
