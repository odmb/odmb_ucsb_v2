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
library unisim;
library unimacro;
library hdlmacro;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
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
    vme_bg0         : in    std_logic;
    vme_bg1         : in    std_logic;
    vme_bg2         : in    std_logic;
    vme_bg3         : in    std_logic;
    vme_as_b        : in    std_logic;
    vme_ds_b        : in    std_logic_vector(1 downto 0);
    vme_sysreset_b  : in    std_logic;
    vme_sysfail_b   : in    std_logic;
    vme_sysfail_out : out   std_logic;
    vme_berr_b      : in    std_logic;
    vme_berr_out    : out   std_logic;
    vme_iack_b      : in    std_logic;
    vme_lword_b     : in    std_logic;
    vme_write_b     : in    std_logic;
    vme_clk         : in    std_logic;
    vme_dtack_v6_b  : inout std_logic;
    vme_tovme       : out   std_logic;  -- not (tovme)
    vme_doe_b       : out   std_logic;

    tc_run_out : out std_logic;         -- OK           NEW!

-- From/To PPIB (connectors J3 and J4)

    dcfeb_tck       : out std_logic_vector(NFEB downto 1);
    dcfeb_tms       : out std_logic;
    dcfeb_tdi       : out std_logic;
    dcfeb_tdo       : in  std_logic_vector(NFEB downto 1);
    dcfeb_bco       : out std_logic;
    dcfeb_resync    : out std_logic;
    odmb_hardrst_b  : out std_logic;    -- Generates REPROG_B
    dcfeb_reprgen_b : out std_logic;
    dcfeb_injpls    : out std_logic;
    dcfeb_extpls    : out std_logic;
    dcfeb_l1a       : out std_logic;
    dcfeb_l1a_match : out std_logic_vector(NFEB downto 1);
    dcfeb_done      : in  std_logic_vector(NFEB downto 1);

-- From/To odmb_ucsb_v2 JTAG port (through IC34)

    v6_tck      : out std_logic;
    v6_tms      : out std_logic;
    v6_tdi      : out std_logic;
    v6_jtag_sel : out std_logic;

    odmb_tms : in std_logic;
    odmb_tdi : in std_logic;
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

    otmb      : in std_logic_vector(17 downto 0);
    alct     : in std_logic_vector(17 downto 0);
    rawlct   : in std_logic_vector(NFEB downto 0);
    otmbffclk : in std_logic;

-- From/To J3/J4 t/fromo ODMB_CTRL

    otmbdav    : in  std_logic;          --  lctdav1
    alctdav   : in  std_logic;          --  lctdav2
--    rsvtd : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);     
    rsvtd_in  : in  std_logic_vector(4 downto 0);  -- rsvt_in(1:2) are rawlct(6:7) 
    rsvtd_out : out std_logic_vector(2 downto 0);
    lctrqst   : out std_logic_vector(2 downto 1);

-- From/To QPLL (From/To DAQMBV)

    qpll_autorestart : out std_logic;
    qpll_reset       : out std_logic;
    qpll_f0sel       : in  std_logic_vector(3 downto 0);
    qpll_locked      : in  std_logic;
    qpll_error       : in  std_logic;
    qpll_clk40MHz_p  : in  std_logic;
    qpll_clk40MHz_n  : in  std_logic;
    qpll_clk80MHz_p  : in  std_logic;
    qpll_clk80MHz_n  : in  std_logic;
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

    tph : out std_logic_vector(46 downto 27);
    tpl : out std_logic_vector(23 downto 6);

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

    done_in : in std_logic

    );
end ODMB_UCSB_V2;

architecture ODMB_UCSB_V2_ARCH of ODMB_UCSB_V2 is

  component ODMB_VME is
    port (

-- VME signals

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
      vme_sysreset_b  : in  std_logic;  -- isysrst* -> sysrest*
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

      clk80  : in std_logic;            -- For testctrl (80MHz)
      clk    : in std_logic;            -- fpgaclk (40MHz)
      clk_s1 : in std_logic;            -- midclk (10MHz) 
      clk_s2 : in std_logic;            -- slowclk (2.5MHz)
      clk_s3 : in std_logic;            -- slowclk2 (1.25MHz)

-- Reset

      rst       : in  std_logic;        -- iglobalrst
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

-- JTAG Signals To/From ODMB_CTRL

      mbc_jtag_tck : out std_logic;
      mbc_jtag_tms : out std_logic;
      mbc_jtag_tdi : out std_logic;
      mbc_jtag_tdo : in  std_logic;

-- Done from DCFEB FPGA (CFEBPRG)

      ul_done : in std_logic_vector(6 downto 0);

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
    OPT_RESET_PULSE     : out std_logic;
      FW_RESET : out std_logic;
      RESYNC   : out std_logic;
      REPROG_B : out std_logic;
      TEST_INJ : out std_logic;
      TEST_PLS : out std_logic;
      TEST_PED : out std_logic;
      TEST_LCT : out std_logic;
    OTMB_LCT_RQST : out std_logic;
    OTMB_EXT_TRIG : out std_logic;

      tp_sel        : out std_logic_vector(15 downto 0);
      odmb_ctrl     : out std_logic_vector(15 downto 0);
      dcfeb_ctrl    : out std_logic_vector(15 downto 0);
      odmb_data_sel : out std_logic_vector(7 downto 0);
      odmb_data     : in  std_logic_vector(15 downto 0);
      TXDIFFCTRL    : out std_logic_vector(3 downto 0);  -- Controls the TX voltage swing
      LOOPBACK      : out std_logic_vector(2 downto 0);  -- For internal loopback tests

      tc_l1a         : out std_logic;
      tc_alct_dav    : out std_logic;
      tc_otmb_dav     : out std_logic;
      tc_lct         : out std_logic_vector(NFEB downto 0);
      ddu_data       : in  std_logic_vector(15 downto 0);
      ddu_data_valid : in  std_logic;
      tc_run         : out std_logic;
      ts_out         : out std_logic_vector(31 downto 0);
      dduclk         : in  std_logic;

      -- VMECONFREGS outputs
      ALCT_PUSH_DLY : out std_logic_vector(4 downto 0);
      OTMB_PUSH_DLY  : out std_logic_vector(4 downto 0);
      PUSH_DLY      : out std_logic_vector(4 downto 0);
      LCT_L1A_DLY   : out std_logic_vector(5 downto 0);
      INJ_DLY       : out std_logic_vector(4 downto 0);
      EXT_DLY       : out std_logic_vector(4 downto 0);
      CALLCT_DLY    : out std_logic_vector(3 downto 0);
      KILL          : out std_logic_vector(NFEB+2 downto 1);
      CRATEID       : out std_logic_vector(6 downto 0);

      -- PC_TX FIFO signals
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
      TFF_RDEN    : out std_logic_vector(NFEB downto 1)

      );

  end component;  -- ODMB_VME


  component ODMB_CTRL is
    port (
      clk40  : in std_logic;
      clk80  : in std_logic;
      clk160 : in std_logic;
      reset  : in std_logic;
      resync : in std_logic;

      ga : in std_logic_vector(4 downto 0);

      mbc_instr_sel : in  std_logic_vector(5 downto 0);
      mbc_instr     : out std_logic_vector(47 downto 1);
      mbc_jtag_ir   : out std_logic_vector(9 downto 0);

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

      rawlct    : in  std_logic_vector (NFEB downto 0);  -- rawlct(5 downto 0) - from J4
      alct_dav  : in  std_logic;        -- lctdav1 - from J4
      otmb_dav   : in  std_logic;        -- lctdav2 - from J4
      rsvtd_in  : in  std_logic_vector(4 downto 0);  -- spare(7 DOWNTO 3) - to J4
      rsvtd_out : out std_logic_vector(2 downto 0);  -- spare(2 DOWNTO 0) - from J4

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

      fifo_empty_b : in std_logic_vector(NFEB+2 downto 1);  -- emptyf*(7 DOWNTO 1) - from FIFOs 


-- From CAFIFO to Data FIFOs
      dcfeb_fifo_wr_en     : out std_logic_vector(NFEB downto 1);
      alct_fifo_wr_en      : out std_logic;
      otmb_fifo_wr_en       : out std_logic;
      cafifo_l1a_match_in  : out std_logic_vector(NFEB+2 downto 1);  -- From TRGCNTRL to CAFIFO to generate Data  
      cafifo_l1a_match_out : out std_logic_vector(NFEB+2 downto 1);  -- From CAFIFO to CONTROL  
      cafifo_l1a_cnt       : out std_logic_vector(23 downto 0);
      cafifo_l1a_dav       : out std_logic_vector(NFEB+2 downto 1);
      cafifo_bx_cnt        : out std_logic_vector(11 downto 0);

      cafifo_wr_addr : out std_logic_vector(3 downto 0);
      cafifo_rd_addr : out std_logic_vector(3 downto 0);

      ext_dcfeb_l1a_cnt7 : out std_logic_vector(23 downto 0);
      dcfeb_l1a_dav7     : out std_logic;
      l1acnt_rst         : in  std_logic;
      bxcnt_rst         : in  std_logic;

-- To PCFIFO
      gl_pc_tx_ack : in std_logic;
      pcclk        : in std_logic;
-- To CONTROL
      dduclk       : in std_logic;
      eof_data     : in std_logic_vector(NFEB+2 downto 1);

-- From ALCT,OTMB,DCFEBs to CAFIFO
      alct_dv     : in std_logic;
      otmb_dv      : in std_logic;
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

      dcfeb_injpulse  : out std_logic;  -- inject - to DCFEBs
      dcfeb_extpulse  : out std_logic;  -- extpls - to DCFEBs
      dcfeb_l1a       : out std_logic;
      dcfeb_l1a_match : out std_logic_vector(NFEB downto 1);

      tck : in  std_logic;
      tdi : in  std_logic;
      tms : in  std_logic;
      tdo : out std_logic;

      test_ccbinj : in std_logic;
      test_ccbpls : in std_logic;
      test_ccbped : in std_logic;

      lct_err : out std_logic;          -- To an LED in the original design
      leds    : out std_logic_vector(6 downto 0);

      cal_mode   : in std_logic;
      cal_trgsel : in std_logic;
      cal_trgen  : in std_logic_vector(3 downto 0);

      ALCT_PUSH_DLY : in std_logic_vector(4 downto 0);
      OTMB_PUSH_DLY  : in std_logic_vector(4 downto 0);
      PUSH_DLY      : in std_logic_vector(4 downto 0);
      LCT_L1A_DLY   : in std_logic_vector(5 downto 0);
      INJ_DLY       : in std_logic_vector(4 downto 0);
      EXT_DLY       : in std_logic_vector(4 downto 0);
      CALLCT_DLY    : in std_logic_vector(3 downto 0);
      KILL          : in std_logic_vector(NFEB+2 downto 1);
      CRATEID       : in std_logic_vector(6 downto 0)
      ); 
  end component;  -- ODMB_CTRL

  component alct_otmb_data_gen is
    port(
      clk            : in  std_logic;
      rst            : in  std_logic;
      l1a            : in  std_logic;
      alct_l1a_match : in  std_logic;
      otmb_l1a_match  : in  std_logic;
      alct_dv        : out std_logic;
      alct_data      : out std_logic_vector(15 downto 0);
      otmb_dv         : out std_logic;
      otmb_data       : out std_logic_vector(15 downto 0));
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
      TX_FIFO_WRD_CNT  : out std_logic_vector(11 downto 0);
      RX_FIFO_RST      : in  std_logic;
      RX_FIFO_RDEN     : in  std_logic;
      RX_FIFO_DOUT     : out std_logic_vector(15 downto 0);
      RX_FIFO_WRD_CNT  : out std_logic_vector(11 downto 0)
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
      TX_FIFO_WRD_CNT : out std_logic_vector(11 downto 0);
      RX_FIFO_RST     : in  std_logic;
      RX_FIFO_RDEN    : in  std_logic;
      RX_FIFO_DOUT    : out std_logic_vector(15 downto 0);
      RX_FIFO_WRD_CNT : out std_logic_vector(11 downto 0)
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
      DAQ_RX_160REFCLK_115_0 : in  std_logic
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
      (clk           : in  std_logic;
       dcfebclk      : in  std_logic;
       rst           : in  std_logic;
       l1a           : in  std_logic;
       l1a_match     : in  std_logic;
       tx_ack        : in  std_logic;
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

  component LCTDLY is  -- Aligns RAW_LCT with L1A by 2.4 us to 4.8 us
    port (
      DIN   : in std_logic;
      CLK   : in std_logic;
      DELAY : in std_logic_vector(5 downto 0);

      DOUT : out std_logic
      );
  end component;

-- Global signals
  constant LOGICL   : std_logic := '0';
  constant LOGICH   : std_logic := '1';
  signal   FW_RESET : std_logic := '0';
  signal   PB_PULSE : std_logic := '0';
  signal   PB_B     : std_logic_vector(1 downto 0);

  signal resync, test_inj, test_pls, test_ped, test_l1a, test_lct : std_logic := '0';
  signal otmb_lct_rqst, otmb_ext_trig : std_logic := '0';
  signal l1acnt_rst, bxcnt_rst : std_logic := '0';
  
-- VME Signals

  signal vme_data_out : std_logic_vector (15 downto 0);
  signal vme_data_in  : std_logic_vector (15 downto 0);
  signal vme_tovme_b  : std_logic;
  signal vme_doe      : std_logic;

  signal v6_jtag_sel_inner  : std_logic := '0';
  signal int_vme_dtack_v6_b : std_logic;

  signal eof_data : std_logic_vector (NFEB+2 downto 1);

-- ALCT ----------------------
  signal gen_alct_data_valid    : std_logic;
  signal gen_alct_data          : std_logic_vector(15 downto 0);
  signal eofgen_alct_data_valid : std_logic;
  signal eofgen_alct_data    : std_logic_vector(17 downto 0);

  signal rx_alct_data_valid : std_logic;
  signal rx_alct_data       : std_logic_vector(17 downto 0);

  signal alct_fifo_data_valid : std_logic;
  signal alct_fifo_data_in    : std_logic_vector(17 downto 0);
  signal alct_fifo_data_out   : std_logic_vector (17 downto 0);

  signal alct_request : std_logic;

-- OTMB ----------------------
  signal gen_otmb_data_valid    : std_logic;
  signal gen_otmb_data          : std_logic_vector(15 downto 0);
  signal eofgen_otmb_data_valid : std_logic;
  signal eofgen_otmb_data    : std_logic_vector(17 downto 0);

  signal rx_otmb_data_valid : std_logic;
  signal rx_otmb_data       : std_logic_vector(17 downto 0);

  signal otmb_fifo_data_valid : std_logic;
  signal otmb_fifo_data_in    : std_logic_vector(17 downto 0);
  signal otmb_fifo_data_out   : std_logic_vector (17 downto 0);

  signal otmb_request : std_logic;


------------------------------

  signal fifo_out : std_logic_vector (15 downto 0);

  -- To PCFIFO
  signal gl_pc_tx_ack : std_logic := '0';

-- JTAG signals To/From MBV

  signal int_tck, int_tdo : std_logic_vector(7 downto 1);
  signal int_tms, int_tdi : std_logic;

-- JTAG outputs from internal DCFEBs

  signal gen_tdo : std_logic_vector(7 downto 1) := (others => '0');

-- Signals To DCFEBs from MBC

  signal int_l1a       : std_logic;     -- To be sent out to pins in V2
  signal int_l1a_match : std_logic_vector (NFEB downto 1);  -- To be sent out to pins in V2

  type   l1a_match_cnt_type is array (NFEB downto 1) of std_logic_vector(15 downto 0);
  signal l1a_match_cnt, raw_lct_cnt, crc_cnt : l1a_match_cnt_type;

  type   dav_cnt_type is array (NFEB+2 downto 1) of std_logic_vector(15 downto 0);
  signal into_cafifo_dav_cnt                : dav_cnt_type;
  signal data_fifo_re_cnt, data_fifo_oe_cnt : dav_cnt_type;
  signal dav_cnt_en, into_cafifo_dav        : std_logic_vector(NFEB+2 downto 1);
  type   dav_state_type is (DAV_IDLE, DAV_HIGH);
  type   dav_state_array_type is array (NFEB+2 downto 1) of dav_state_type;
  signal dav_next_state, dav_current_state  : dav_state_array_type;

  signal ext_dcfeb_l1a_cnt7 : std_logic_vector(23 downto 0);
  signal dcfeb_l1a_dav7     : std_logic;

  type   gap_cnt_type is array (NFEB downto 1) of std_logic_vector(15 downto 0);
  signal lct_l1a_gap                       : gap_cnt_type;
  signal gap_cnt_rst, gap_cnt_en           : std_logic_vector(NFEB downto 1);
  type   gap_state_type is (GAP_IDLE, GAP_COUNTING);
  type   gap_state_array_type is array (NFEB downto 1) of gap_state_type;
  signal gap_next_state, gap_current_state : gap_state_array_type;


-- Monitoring signals

  signal tp_sel_reg               : std_logic_vector(15 downto 0) := (others => '0');
  signal odmb_ctrl_reg            : std_logic_vector(15 downto 0) := (others => '0');
  signal dcfeb_ctrl_reg           : std_logic_vector(15 downto 0) := (others => '0');
  signal odmb_data_sel            : std_logic_vector(7 downto 0);
  signal odmb_data                : std_logic_vector(15 downto 0);
  signal mask_l1a, mask_l1a_match : std_logic                     := '0';

  -- GIGALINK_PC 
  signal gl1_rx_buf_p, gl1_rx_buf_n : std_logic;
  signal pc_rx_data                 : std_logic_vector(15 downto 0);
  signal pc_rx_data_valid           : std_logic;

  signal pc_tx_fifo_rst     : std_logic;
  signal pc_tx_fifo_rden    : std_logic;
  signal pc_tx_fifo_dout    : std_logic_vector(15 downto 0);
  signal pc_tx_fifo_wrd_cnt : std_logic_vector(11 downto 0);
  signal pc_rx_fifo_rst     : std_logic;
  signal pc_rx_fifo_rden    : std_logic;
  signal pc_rx_fifo_dout    : std_logic_vector(15 downto 0);
  signal pc_rx_fifo_wrd_cnt : std_logic_vector(11 downto 0);
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
  signal ddu_tx_fifo_wrd_cnt : std_logic_vector (11 downto 0);
  signal ddu_rx_fifo_rst     : std_logic;
  signal ddu_rx_fifo_rden    : std_logic;
  signal ddu_rx_fifo_dout    : std_logic_vector (15 downto 0);
  signal ddu_rx_fifo_wrd_cnt : std_logic_vector (11 downto 0);

  -- dmb_receiver
  signal CRC_VALID : std_logic_vector(NFEB downto 1) := (others => '0');
  signal RD_EN_FF  : std_logic_vector(NFEB downto 1) := (others => '0');
  signal FF_STATUS : std_logic_vector(15 downto 0);

  constant FIFO_VME_MODE : std_logic                       := '0';  -- We probably will not use VME_MODE on DMB_RX
  constant WR_EN_FF      : std_logic_vector(NFEB downto 1) := (others => '0');
  constant FF_DATA_IN    : std_logic_vector(15 downto 0)   := (others => '0');



-- DCFEB I/O Signals

  type   dcfeb_data_type is array (NFEB downto 1) of std_logic_vector(15 downto 0);
  signal gen_dcfeb_data       : dcfeb_data_type;
  signal rx_dcfeb_data        : dcfeb_data_type;
  signal dcfeb_data           : dcfeb_data_type;
  signal orx_buf_n, orx_buf_p : std_logic_vector(12 downto 1);
  signal gen_dcfeb_data_valid : std_logic_vector(NFEB downto 1);
  signal rx_dcfeb_data_valid  : std_logic_vector(NFEB downto 1);
  signal dcfeb_data_valid     : std_logic_vector(NFEB downto 1);

  signal   gen_dcfeb_sel : std_logic       := '0';
  type     dcfeb_addr_type is array (1 to NFEB) of std_logic_vector(3 downto 0);
  constant dcfeb_addr    : dcfeb_addr_type := ("0001", "0010", "0011", "0100", "0101", "0110", "0111");

  signal gen_alct_sel, gen_otmb_sel : std_logic;

-- From/To Gigalinks
  signal grx0_data       : std_logic_vector(15 downto 0) := "0000000000000000";
  signal grx0_data_valid : std_logic                     := '0';
  signal grx1_data       : std_logic_vector(15 downto 0) := "0000000000000000";
  signal grx1_data_valid : std_logic                     := '0';

  signal gtx0_data                        : std_logic_vector(15 downto 0);
  signal gtx0_data_valid, ddu_eof         : std_logic;
  signal gtx1_data                        : std_logic_vector(15 downto 0);
  signal gtx1_data_valid                  : std_logic;
  signal gtx1_data_valid_cnt, ddu_eof_cnt : std_logic_vector(15 downto 0);
  signal int_l1a_cnt                      : std_logic_vector(15 downto 0);

  signal gl1_clk, gl1_clk_2_buf          : std_logic;
  signal gl0_clk, gl0_clk_2, gl0_clk_buf : std_logic;
  signal dduclk, pcclk                   : std_logic;

-- PLL Signals

  signal qpll_clk40MHz, qpll_clk80MHz, qpll_clk160MHz, clk160 : std_logic;

  signal pll1_fb, pll1_fb_slow, pll1_rst, pll1_pd, pll1_locked, pll1_locked_slow : std_logic := '0';

  signal pll_clk80, clk80     : std_logic;  -- reallyfastclk (80MHz) 
  signal pll_clk40, clk40     : std_logic;  -- fastclk (40MHz) 
  signal pll_clk10, clk10     : std_logic;  -- midclk  (10MHz) 
  signal pll_clk5, clk5       : std_logic;  -- Generates clk2p5 and clk1p25
  signal clk2p5, clk2p5_inv   : std_logic;  -- slowclk (2.5MHz)
  signal clk1p25, clk1p25_inv : std_logic;  -- slowclk2 (1.25MHz)


-- Other signals

  signal int_dl_jtag_tdo : std_logic_vector(7 downto 1) := "0000000";

  signal int_lvmb_pon                                 : std_logic_vector(7 downto 0);
  signal int_lvmb_csb                                 : std_logic_vector(6 downto 0);
  signal int_lvmb_sclk, int_lvmb_sdin, int_lvmb_sdout : std_logic;

  signal led_pulse : std_logic := '1';

-- JTAG signals between ODMB_VME and ODMB_CTRL

  signal mbc_jtag_tck : std_logic;
  signal mbc_jtag_tms : std_logic;
  signal mbc_jtag_tdi : std_logic;
  signal mbc_jtag_tdo : std_logic;

-- Test FIFOs

  type   dcfeb_gbrx_data_type is array (NFEB+1 downto 1) of std_logic_vector(15 downto 0);
  signal dcfeb_gbrx_data : dcfeb_gbrx_data_type;

  signal dcfeb_gbrx_data_valid : std_logic_vector(NFEB+1 downto 1) := (others => '0');
  signal dcfeb_gbrx_data_clk   : std_logic_vector(NFEB+1 downto 1) := (others => '0');

  type   dcfeb_adc_mask_type is array (NFEB downto 1) of std_logic_vector(11 downto 0);
  signal dcfeb_adc_mask : dcfeb_adc_mask_type;

  type   dcfeb_fsel_type is array (NFEB downto 1) of std_logic_vector(32 downto 0);
  signal dcfeb_fsel : dcfeb_fsel_type;

  type   dcfeb_jtag_ir_type is array (NFEB downto 1) of std_logic_vector(9 downto 0);
  signal dcfeb_jtag_ir : dcfeb_jtag_ir_type;

  signal mbc_instr : std_logic_vector(47 downto 1);

  signal mbc_jtag_ir : std_logic_vector(9 downto 0);

  signal diagout_cfebjtag : std_logic_vector(17 downto 0);
  signal diagout_lvdbmon  : std_logic_vector(17 downto 0);

  signal pon_rst_reg, fw_rst_reg, opt_rst_reg : std_logic_vector (31 downto 0) := (others => '0');
  signal reset, opt_reset, fw_reset_q : std_logic := '0';
  signal opt_reset_pulse, opt_reset_pulse_q : std_logic := '0';


  signal mbc_leds : std_logic_vector (6 downto 0);

  signal select_diagnostic : integer := 0;

  signal lct_err : std_logic := '0';

-- CAFIFO related signals
  signal data_fifo_oe     : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  signal data_fifo_re     : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  signal data_fifo_re_b   : std_logic_vector(NFEB+2 downto 1) := (others => '1');
  signal dcfeb_fifo_wr_en : std_logic_vector(NFEB downto 1)   := (others => '0');
  signal alct_fifo_wr_en  : std_logic                         := '0';
  signal otmb_fifo_wr_en   : std_logic                         := '0';

  signal cafifo_l1a_match_in  : std_logic_vector(NFEB+2 downto 1);
  signal cafifo_l1a_match_out : std_logic_vector(NFEB+2 downto 1);
  signal cafifo_l1a_cnt       : std_logic_vector(23 downto 0);
  signal cafifo_l1a_dav       : std_logic_vector(NFEB+2 downto 1);
  signal cafifo_bx_cnt        : std_logic_vector(11 downto 0);
  signal cafifo_wr_addr       : std_logic_vector(3 downto 0);
  signal cafifo_rd_addr       : std_logic_vector(3 downto 0);




  type   dcfeb_fifo_data_type is array (NFEB downto 1) of std_logic_vector(15 downto 0);
  signal dcfeb_fifo_in : dcfeb_fifo_data_type;
--  signal dcfeb_fifo_out : dcfeb_fifo_data_type;

  type   ext_dcfeb_fifo_data_type is array (NFEB downto 1) of std_logic_vector(17 downto 0);
  signal eofgen_dcfeb_fifo_in    : ext_dcfeb_fifo_data_type;
  signal eofgen_dcfeb_data_valid : std_logic_vector(NFEB downto 1);
  signal dcfeb_fifo_out          : ext_dcfeb_fifo_data_type;


  type   dcfeb_fifo_cnt_type is array (NFEB downto 1) of std_logic_vector(10 downto 0);
  signal dcfeb_fifo_wr_cnt : dcfeb_fifo_cnt_type;
  signal dcfeb_fifo_rd_cnt : dcfeb_fifo_cnt_type;

  signal alct_fifo_wr_cnt, otmb_fifo_wr_cnt : std_logic_vector(10 downto 0);
  signal alct_fifo_rd_cnt, otmb_fifo_rd_cnt : std_logic_vector(10 downto 0);

  signal dcfeb_fifo_empty  : std_logic_vector(NFEB downto 1);
  signal dcfeb_fifo_aempty : std_logic_vector(NFEB downto 1);
  signal dcfeb_fifo_afull  : std_logic_vector(NFEB downto 1);
  signal dcfeb_fifo_full   : std_logic_vector(NFEB downto 1);

  signal data_fifo_empty_b                 : std_logic_vector(NFEB+2 downto 1);
  signal alct_fifo_empty, otmb_fifo_empty   : std_logic;
  signal alct_fifo_aempty, otmb_fifo_aempty : std_logic;
  signal alct_fifo_afull, otmb_fifo_afull   : std_logic;
  signal alct_fifo_full, otmb_fifo_full     : std_logic;

  signal raw_l1a, tc_l1a           : std_logic;
  signal raw_lct                   : std_logic_vector(NFEB downto 0);
  signal int_alct_dav, tc_alct_dav : std_logic;
  signal int_otmb_dav, tc_otmb_dav   : std_logic;
  signal tc_lct                    : std_logic_vector(NFEB downto 0);

  signal tc_run                                                   : std_logic;
  signal counter_clk, counter_clk_gl0, counter_clk_gl1, reset_cnt : integer   := 0;
  signal clk1, clk2, clk4, clk8, gl0_clk_slow, gl1_clk_2_slow     : std_logic := '0';
  signal clk1_inv, clk2_inv, clk4_inv                             : std_logic := '1';
  signal ts_out                                                   : std_logic_vector(31 downto 0);

  signal led_cnt                 : integer   := 0;
  signal led_cnt_rst, led_cnt_en : std_logic := '0';
  signal reset_q, clk_led        : std_logic := '0';

  type   led_state_type is (LED_IDLE, LED_COUNTING);
  signal led_next_state, led_current_state : led_state_type;



-- From VMECONFREGS to odmb_ctrl and odmb_ctrl
  signal ALCT_PUSH_DLY : std_logic_vector(4 downto 0);
  signal OTMB_PUSH_DLY  : std_logic_vector(4 downto 0);
  signal PUSH_DLY      : std_logic_vector(4 downto 0);
  signal LCT_L1A_DLY   : std_logic_vector(5 downto 0);
  signal INJ_DLY       : std_logic_vector(4 downto 0);
  signal EXT_DLY       : std_logic_vector(4 downto 0);
  signal CALLCT_DLY    : std_logic_vector(3 downto 0);
  signal KILL          : std_logic_vector(NFEB+2 downto 1);
  signal CRATEID       : std_logic_vector(6 downto 0);

  -- From/to TESTFIFOS to test FIFOs
  signal TFF_DOUT    : std_logic_vector(15 downto 0);
  signal TFF_WRD_CNT : std_logic_vector(11 downto 0);
  signal TFF_RST     : std_logic_vector(NFEB downto 1);
  signal TFF_SEL     : std_logic_vector(NFEB downto 1);
  signal TFF_RDEN    : std_logic_vector(NFEB downto 1);

  signal ddu_data_valid : std_logic;

  signal testctrl_sel : std_logic := '0';

  signal eof : std_logic;
  
begin

  MBV : ODMB_VME
    port map (

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
      vme_sysreset_b  => vme_sysreset_b,      -- input
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

      clk80  => clk80,                  -- for testctrl (80MHz)
      clk    => clk40,                  -- fpgaclk (40MHz)
      clk_s1 => clk10,                  -- midclk (10MHz) 
      clk_s2 => clk2p5,                 -- slowclk (2.5MHz)
      clk_s3 => clk1p25,                -- slowclk2 (1.25MHz)

-- Reset

      rst       => reset,
      led_pulse => led_pulse,

-- JTAG signals To/From DCFEBs

      dl_jtag_tck => int_tck,
      dl_jtag_tms => int_tms,
      dl_jtag_tdi => int_tdi,
      dl_jtag_tdo => int_tdo,

-- JTAG Signals To/From ODMB JTAG

      odmb_jtag_sel => v6_jtag_sel_inner,
      odmb_jtag_tck => v6_tck,
      odmb_jtag_tms => v6_tms,
      odmb_jtag_tdi => v6_tdi,
      odmb_jtag_tdo => odmb_tdo,

-- JTAG Signals To/From odmb_ctrl

      mbc_jtag_tck => mbc_jtag_tck,
      mbc_jtag_tms => mbc_jtag_tms,
      mbc_jtag_tdi => mbc_jtag_tdi,
      mbc_jtag_tdo => mbc_jtag_tdo,

-- Done from DCFEB FPGA (CFEBPRG)

      ul_done => dcfeb_done,

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
      FW_RESET => fw_reset,
      resync   => resync,
      reprog_b => odmb_hardrst_b,
      test_inj => test_inj,
      test_pls => test_pls,
      test_ped => test_ped,
      test_lct => test_lct,
      OTMB_LCT_RQST => otmb_lct_rqst,
      OTMB_EXT_TRIG => otmb_ext_trig,

      tp_sel        => tp_sel_reg,
      odmb_ctrl     => odmb_ctrl_reg,
      dcfeb_ctrl    => dcfeb_ctrl_reg,
      odmb_data_sel => odmb_data_sel,
      odmb_data     => odmb_data,
      TXDIFFCTRL    => txdiffctrl,
      LOOPBACK      => loopback,

      -- TESTCTRL
      tc_l1a         => tc_l1a,
      tc_alct_dav    => tc_alct_dav,
      tc_otmb_dav     => tc_otmb_dav,
      tc_lct         => tc_lct,
      ddu_data       => gtx0_data,
      ddu_data_valid => gtx0_data_valid,
      tc_run         => tc_run,
      ts_out         => ts_out,
      dduclk         => dduclk,

      -- VMECONFREGS outputs
      ALCT_PUSH_DLY => ALCT_PUSH_DLY,
      OTMB_PUSH_DLY  => OTMB_PUSH_DLY,
      PUSH_DLY      => PUSH_DLY,
      LCT_L1A_DLY   => LCT_L1A_DLY,
      INJ_DLY       => INJ_DLY,
      EXT_DLY       => EXT_DLY,
      CALLCT_DLY    => CALLCT_DLY,
      KILL          => KILL,
      CRATEID       => CRATEID,

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
      TFF_RDEN    => TFF_RDEN
      );                                -- MBV : ODMB_VME

  MBC : ODMB_CTRL
    port map (

      clk40  => clk40,
      clk80  => clk80,
      clk160 => clk160,
      reset  => reset,
      resync => resync,

      ga => vme_ga,

      mbc_instr_sel => dcfeb_ctrl_reg(15 downto 10),
      mbc_instr     => mbc_instr,
      mbc_jtag_ir   => mbc_jtag_ir,

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

      rawlct    => raw_lct,  -- rawlct(NFEB downto 0) - from -- from testctrl
      otmb_dav   => int_otmb_dav,         -- lctdav1 - from J4
      alct_dav  => int_alct_dav,        -- lctdav2 - from J4
      rsvtd_in  => rsvtd_in,            -- spare(7 DOWNTO 3) - to J4
      rsvtd_out => rsvtd_out,           -- spare(2 DOWNTO 0) - from J4

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

      fifo_empty_b => data_fifo_empty_b,

-- From CAFIFO to Data FIFOs
      dcfeb_fifo_wr_en => dcfeb_fifo_wr_en,
      alct_fifo_wr_en  => alct_fifo_wr_en,
      otmb_fifo_wr_en   => otmb_fifo_wr_en,

      cafifo_l1a_match_in  => cafifo_l1a_match_in,
      cafifo_l1a_match_out => cafifo_l1a_match_out,
      cafifo_l1a_cnt       => cafifo_l1a_cnt,
      cafifo_l1a_dav       => cafifo_l1a_dav,
      cafifo_bx_cnt        => cafifo_bx_cnt,
      cafifo_wr_addr       => cafifo_wr_addr,
      cafifo_rd_addr       => cafifo_rd_addr,
      ext_dcfeb_l1a_cnt7   => ext_dcfeb_l1a_cnt7,
      dcfeb_l1a_dav7       => dcfeb_l1a_dav7,

      l1acnt_rst => l1acnt_rst,
      bxcnt_rst  => bxcnt_rst,
      
-- To PCFIFO
      gl_pc_tx_ack => gl_pc_tx_ack,
      dduclk       => dduclk,
      pcclk        => pcclk,
      eof_data     => eof_data,

-- From ALCT,OTMB,DCFEBs to CAFIFO
      alct_dv     => alct_fifo_data_valid,
      otmb_dv      => otmb_fifo_data_valid,
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

      dcfeb_l1a_match => int_l1a_match,  -- lctf(5 DOWNTO 1) - to DCFEBs
      dcfeb_l1a       => int_l1a,        -- febrst - to DCFEBs
      dcfeb_injpulse  => dcfeb_injpls,   -- inject - to DCFEBs
      dcfeb_extpulse  => dcfeb_extpls,   -- extpls - to DCFEBs

-- From/To ODMB_VME

      tck => mbc_jtag_tck,
      tdi => mbc_jtag_tdi,
      tms => mbc_jtag_tms,
      tdo => mbc_jtag_tdo,

      test_ccbinj => test_inj,
      test_ccbpls => test_pls,
      test_ccbped => test_ped,

      lct_err => lct_err,
      leds    => mbc_leds,

      cal_mode   => odmb_ctrl_reg(4),
      cal_trgsel => odmb_ctrl_reg(5),
      cal_trgen  => odmb_ctrl_reg(3 downto 0),

      ALCT_PUSH_DLY => ALCT_PUSH_DLY,
      OTMB_PUSH_DLY  => OTMB_PUSH_DLY,
      PUSH_DLY      => PUSH_DLY,
      LCT_L1A_DLY   => LCT_L1A_DLY,
      INJ_DLY       => INJ_DLY,
      EXT_DLY       => EXT_DLY,
      CALLCT_DLY    => CALLCT_DLY,
      KILL          => KILL,
      CRATEID       => CRATEID
      );                                -- MBC : ODMB_CTRL


---------------------------  Optical tranceivers  ---------------------------
-----------------------------------------------------------------------------


  GIGALINK_DDU_PM : gigalink_ddu
    generic map (SIM_SPEEDUP => IS_SIMULATION)
    port map (
      REF_CLK_80 => gl0_clk,            -- 80 MHz for DDU data rate
      RST        => opt_reset,
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
      TX_FIFO_RST     => ddu_tx_fifo_rst ,
      TX_FIFO_RDEN    => ddu_tx_fifo_rden ,
      TX_FIFO_DOUT    => ddu_tx_fifo_dout ,
      TX_FIFO_WRD_CNT => ddu_tx_fifo_wrd_cnt ,
      RX_FIFO_RST     => ddu_rx_fifo_rst ,
      RX_FIFO_RDEN    => ddu_rx_fifo_rden ,
      RX_FIFO_DOUT    => ddu_rx_fifo_dout ,
      RX_FIFO_WRD_CNT => ddu_rx_fifo_wrd_cnt

      );


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
      USRCLK  => gl1_clk_2_buf,

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
      TX_FIFO_RST      => pc_tx_fifo_rst ,
      TX_FIFO_RDEN     => pc_tx_fifo_rden ,
      TX_FIFO_DOUT     => pc_tx_fifo_dout ,
      TX_FIFO_WRD_CNT  => pc_tx_fifo_wrd_cnt ,
      RX_FIFO_RST      => pc_rx_fifo_rst ,
      RX_FIFO_RDEN     => pc_rx_fifo_rden ,
      RX_FIFO_DOUT     => pc_rx_fifo_dout ,
      RX_FIFO_WRD_CNT  => pc_rx_fifo_wrd_cnt
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
      --DMBVME_CLK_S2          => gl1_clk_2_buf,  -- Data clock for the PC TX simulation
      --DAQ_RX_160REFCLK_115_0       => clk40,    -- For the PC TX simulation

      DAQ_RX_125REFCLK       => clk40,
      DMBVME_CLK_S2          => clk2p5,
      DAQ_RX_160REFCLK_115_0 => clk160,


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

      --Internal signals
      FIFO_VME_MODE => fifo_vme_mode,
      FIFO_RST      => TFF_RST,
      FIFO_SEL      => TFF_SEL,
      RD_EN_FF      => TFF_RDEN,
      WR_EN_FF      => wr_en_ff,
      FF_DATA_IN    => ff_data_in,
      FF_DATA_OUT   => TFF_DOUT,
      FF_WRD_CNT    => TFF_WRD_CNT,
      FF_STATUS     => ff_status
      );

--------------------------------  DCFEB data  -------------------------------
-----------------------------------------------------------------------------

  GEN_DCFEB : for I in NFEB downto 1 generate
  begin

    dcfeb_data_valid(I) <= '0' when kill(I) = '1' else
                           rx_dcfeb_data_valid(I) when (gen_dcfeb_sel = '0') else
                           gen_dcfeb_data_valid(I);
    dcfeb_data(I) <= rx_dcfeb_data(I) when (gen_dcfeb_sel = '0') else gen_dcfeb_data(I);

    dcfeb_fifo_in(I) <= dcfeb_data(I);

    DCFEB_V6_PM : DCFEB_V6
      generic map(
        dcfeb_addr => dcfeb_addr(I))
      port map(
        clk           => clk40,
        dcfebclk      => clk160,
        rst           => reset,
        l1a           => int_l1a,
        l1a_match     => int_l1a_match(I),
        tx_ack        => logich,
        dcfeb_dv      => gen_dcfeb_data_valid(I),
        dcfeb_data    => gen_dcfeb_data(I),
        adc_mask      => dcfeb_adc_mask(I),
        dcfeb_fsel    => dcfeb_fsel(I),
        dcfeb_jtag_ir => dcfeb_jtag_ir(I),
        trst          => reset,
        tck           => int_tck(I),
        tms           => int_tms,
        tdi           => int_tdi,
        rtn_shft_en   => open,
        tdo           => gen_tdo(I));

    dcfeb_tck(I) <= int_tck(I);

    dcfeb_l1a_match(I) <= '0' when mask_l1a_match = '1' else int_l1a_match(I) or pb_pulse;

    int_tdo(I) <= dcfeb_tdo(I) when (gen_dcfeb_sel = '0') else gen_tdo(I);

    eof_data(I) <= eofgen_dcfeb_fifo_in(I)(17);
    EOFGEN_PM : EOFGEN
      port map (
        clk => clk160,
        rst => reset,

        dv_in   => dcfeb_data_valid(I),
        data_in => dcfeb_fifo_in(I),

        dv_out   => eofgen_dcfeb_data_valid(I),
        data_out => eofgen_dcfeb_fifo_in(I)
        );

    DCFEB_FIFO_PM : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
        ALMOST_FULL_OFFSET      => X"0080",  -- Sets almost full threshold
        ALMOST_EMPTY_OFFSET     => X"0080",  -- Sets the almost empty threshold
        DATA_WIDTH              => 18,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
        FIFO_SIZE               => "36Kb",   -- Target BRAM, "18Kb" or "36Kb" 
        FIRST_WORD_FALL_THROUGH => false)  -- Sets the FIFO FWFT to TRUE or FALSE

      port map (
        ALMOSTEMPTY => dcfeb_fifo_aempty(I),       -- Output almost empty 
        ALMOSTFULL  => dcfeb_fifo_afull(I),        -- Output almost full
        DO          => dcfeb_fifo_out(I),          -- Output data
        EMPTY       => dcfeb_fifo_empty(I),        -- Output empty
        FULL        => dcfeb_fifo_full(I),         -- Output full
        RDCOUNT     => dcfeb_fifo_rd_cnt(I),       -- Output read count
        RDERR       => open,                       -- Output read error
        WRCOUNT     => dcfeb_fifo_wr_cnt(I),       -- Output write count
        WRERR       => open,                       -- Output write error
        DI          => eofgen_dcfeb_fifo_in(I),    -- Input data
        RDCLK       => dduclk,                     -- Input read clock
        RDEN        => data_fifo_re(I),            -- Input read enable
        RST         => reset,                      -- Input reset
        WRCLK       => clk160,                     -- Input write clock
        WREN        => eofgen_dcfeb_data_valid(I)  -- Input write enable
        );

  end generate GEN_DCFEB;

----------------------------  ALCT and OTMB data  ----------------------------
-----------------------------------------------------------------------------

  ALCT_OTMB_DATA_GEN_PM : alct_otmb_data_gen
    port map(
      clk            => clk40,
      rst            => reset,
      l1a            => int_l1a,
      alct_l1a_match => alct_request,
      otmb_l1a_match  => otmb_request,
      alct_dv        => gen_alct_data_valid,
      alct_data      => gen_alct_data,
      otmb_dv         => gen_otmb_data_valid,
      otmb_data       => gen_otmb_data
      );

  ALCT_FIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 18,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => false)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      ALMOSTEMPTY => alct_fifo_aempty,       -- Output almost empty 
      ALMOSTFULL  => alct_fifo_afull,        -- Output almost full
      DO          => alct_fifo_data_out,          -- Output data
      EMPTY       => alct_fifo_empty,        -- Output empty
      FULL        => alct_fifo_full,         -- Output full
      RDCOUNT     => alct_fifo_rd_cnt,       -- Output read count
      RDERR       => open,                   -- Output read error
      WRCOUNT     => alct_fifo_wr_cnt,       -- Output write count
      WRERR       => open,                   -- Output write error
      DI          => alct_fifo_data_in,    -- Input data
      RDCLK       => dduclk,                 -- Input read clock
      RDEN        => data_fifo_re(NFEB+2),   -- Input read enable
      RST         => reset,                  -- Input reset
      WRCLK       => clk40,                  -- Input write clock
      WREN        => alct_fifo_data_valid  -- Input write enable
      );


  OTMB_FIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 18,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => false)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      ALMOSTEMPTY => otmb_fifo_aempty,       -- Output almost empty 
      ALMOSTFULL  => otmb_fifo_afull,        -- Output almost full
      DO          => otmb_fifo_data_out,          -- Output data
      EMPTY       => otmb_fifo_empty,        -- Output empty
      FULL        => otmb_fifo_full,         -- Output full
      RDCOUNT     => otmb_fifo_rd_cnt,       -- Output read count
      RDERR       => open,                  -- Output read error
      WRCOUNT     => otmb_fifo_wr_cnt,       -- Output write count
      WRERR       => open,                  -- Output write error
      DI          => otmb_fifo_data_in,    -- Input data
      RDCLK       => dduclk,                -- Input read clock
      RDEN        => data_fifo_re(NFEB+1),  -- Input read enable
      RST         => reset,                 -- Input reset
      WRCLK       => clk40,                 -- Input write clock
      WREN        => otmb_fifo_data_valid  -- Input write enable
      );

-- FIFO MUX
  fifo_out <= dcfeb_fifo_out(1)(15 downto 0) when data_fifo_oe = "111111110" else
              dcfeb_fifo_out(2)(15 downto 0) when data_fifo_oe = "111111101" else
              dcfeb_fifo_out(3)(15 downto 0) when data_fifo_oe = "111111011" else
              dcfeb_fifo_out(4)(15 downto 0) when data_fifo_oe = "111110111" else
              dcfeb_fifo_out(5)(15 downto 0) when data_fifo_oe = "111101111" else
              dcfeb_fifo_out(6)(15 downto 0) when data_fifo_oe = "111011111" else
              dcfeb_fifo_out(7)(15 downto 0) when data_fifo_oe = "110111111" else
              otmb_fifo_data_out(15 downto 0)      when data_fifo_oe = "101111111" else
              alct_fifo_data_out(15 downto 0)     when data_fifo_oe = "011111111" else
              (others => 'Z');
  eof <= dcfeb_fifo_out(1)(17) when data_fifo_oe = "111111110" else
         dcfeb_fifo_out(2)(17) when data_fifo_oe = "111111101" else
         dcfeb_fifo_out(3)(17) when data_fifo_oe = "111111011" else
         dcfeb_fifo_out(4)(17) when data_fifo_oe = "111110111" else
         dcfeb_fifo_out(5)(17) when data_fifo_oe = "111101111" else
         dcfeb_fifo_out(6)(17) when data_fifo_oe = "111011111" else
         dcfeb_fifo_out(7)(17) when data_fifo_oe = "110111111" else
         otmb_fifo_data_out(17)      when data_fifo_oe = "101111111" else  -- eof still to be implemented for alct and otmb data
         alct_fifo_data_out(17)     when data_fifo_oe = "011111111" else  -- eof still to be implemented for alct and otmb data
         '0';

  alct_fifo_data_valid <= '0' when kill(9) = '1' else
                          rx_alct_data_valid when (gen_dcfeb_sel = '0') else
                          eofgen_alct_data_valid;

  alct_fifo_data_in <= rx_alct_data when (gen_dcfeb_sel = '0') else
                       eofgen_alct_data;

  rx_alct_data_valid <= not alct(17);
  rx_alct_data       <= alct(16) & alct(16 downto 0);  -- For now, we send EOF in 16 and 17
 
  otmb_fifo_data_valid <= '0' when kill(9) = '1' else
                          rx_otmb_data_valid when (gen_dcfeb_sel = '0') else
                          eofgen_otmb_data_valid;

  otmb_fifo_data_in <= rx_otmb_data when (gen_dcfeb_sel = '0') else
                       eofgen_otmb_data;

  rx_otmb_data_valid <= not otmb(17);
  rx_otmb_data       <= otmb(16) & otmb(16 downto 0);  -- For now, we send EOF in 16 and 17

  data_fifo_re      <= not data_fifo_re_b;
  data_fifo_empty_b <= alct_fifo_empty & otmb_fifo_empty & dcfeb_fifo_empty;

  eof_data(8) <= alct_fifo_data_in(16);
  eof_data(9) <= otmb_fifo_data_in(16);
  alct_request <= '1' when test_l1a = '1' else cafifo_l1a_match_in(NFEB+2);
  otmb_request <= '1' when test_l1a = '1' else cafifo_l1a_match_in(NFEB+1);
                  

  ALCT_EOFGEN_PM : EOFGEN
    port map (
      clk => clk40,
      rst => reset,

      dv_in   => gen_alct_data_valid,
      data_in => gen_alct_data,

      dv_out   => eofgen_alct_data_valid,
      data_out => eofgen_alct_data
      );

  OTMB_EOFGEN_PM : EOFGEN
    port map (
      clk => clk40,
      rst => reset,

      dv_in   => gen_otmb_data_valid,
      data_in => gen_otmb_data,

      dv_out   => eofgen_otmb_data_valid,
      data_out => eofgen_otmb_data
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
  lctrqst(1) <= otmb_lct_rqst;    
  lctrqst(2) <= otmb_ext_trig;    
  
  gen_alct_sel  <= odmb_ctrl_reg(7);
  gen_otmb_sel   <= odmb_ctrl_reg(7);
  gen_dcfeb_sel <= odmb_ctrl_reg(7);

  pb_b <= not pb;
  PULSE_PB : PULSE_EDGE port map(pb_pulse, open, clk40, reset, 1, pb_b(1));

  mask_l1a       <= odmb_ctrl_reg(11);
  mask_l1a_match <= odmb_ctrl_reg(12);

  dcfeb_tms       <= int_tms;
  dcfeb_tdi       <= int_tdi;
  dcfeb_l1a       <= '0' when mask_l1a = '1' else int_l1a or pb_pulse;
  dcfeb_resync    <= resync;
  dcfeb_reprgen_b <= '0';

  -- To QPLL
  qpll_autorestart <= '1';
  qpll_reset       <= not reset;
  dcfeb_bco        <= '0';

  v6_jtag_sel <= v6_jtag_sel_inner;

  d <= (others => '0');


-- Power ON reset [The FD is to avoid an event on an array]
  FD_FW_RESET  : FD port map(fw_reset_q, clk2p5, fw_reset);
  FD_OPT_RESET : FD port map(opt_reset_pulse_q, clk2p5, opt_reset_pulse);
  pon_rst_reg <= x"0FFFFFFF" when (pll1_locked = '0' or (fw_reset_q = '0' and odmb_ctrl_reg(8) = '1')) else
                 pon_rst_reg(30 downto 0) & '0' when clk2p5'event and clk2p5 = '1' else
                 pon_rst_reg;
  fw_rst_reg <= x"0FFFFFFF" when (fw_reset_q = '0' and fw_reset = '1') else
                fw_rst_reg(30 downto 0) & '0' when clk2p5'event and clk2p5 = '1' else
                fw_rst_reg;
  opt_rst_reg <= x"0FFFFFFF" when (opt_reset_pulse_q = '0' and opt_reset_pulse = '1') else
                 opt_rst_reg(30 downto 0) & '0' when clk2p5'event and clk2p5 = '1' else
                 opt_rst_reg;
  reset     <= fw_rst_reg(31) or pon_rst_reg(31) or not pb(0);  -- Firmware reset
  opt_reset <= opt_rst_reg(31) or pon_rst_reg(31);  -- Optical reset

  -- Threw the kitchen sink here. This needs to be checked
  l1acnt_rst <= not ccb_evcntres or not ccb_l1arst or not ccb_softrst or reset; 
  bxcnt_rst <= not ccb_bxrst or reset;
  
  PULLUP_dtack_b     : PULLUP port map (vme_dtack_v6_b);
  PULLDOWN_DCFEB_TMS : PULLDOWN port map (int_tms);
  PULLDOWN_ODMB_TMS  : PULLDOWN port map (v6_tms);

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
  qpll_clk80MHz_buf : IBUFDS port map (I => qpll_clk80MHz_p, IB => qpll_clk80MHz_n, O => qpll_clk80MHz);
  
  qpll_clk160MHz_buf : IBUFDS_GTXE1 port map (I => qpll_clk160MHz_p, IB => qpll_clk160MHz_n, CEB => logicl,
                                              O => qpll_clk160MHz, ODIV2 => open);
  qpll_clk160MHz_bufg : BUFG port map (O => clk160, I => qpll_clk160MHz);

  -- Clock for PC TX
  gl1_clk_buf_gtxe1 : IBUFDS_GTXE1 port map (I => gl1_clk_p, IB => gl1_clk_n, CEB => logicl,
                                             O => gl1_clk, ODIV2 => open);
  pcclk <= gl1_clk_2_buf;

  -- Clock for DDU TX
  gl0_clk_buf_gtxe1 : IBUFDS_GTXE1 port map (I => gl0_clk_p, IB => gl0_clk_n, CEB => logicl,
                                             O => gl0_clk, ODIV2 => gl0_clk_2);
  gl0_clk_bufg : BUFG port map (O => gl0_clk_buf, I => gl0_clk);
  dduclk <= gl0_clk_buf;

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
    end if;
  end process Divide_Frequency;
  clk1_inv <= not clk1;
  clk2_inv <= not clk2;
  clk4_inv <= not clk4;
  FD4 : FD port map (clk4, clk8, clk4_inv);
  FD2 : FD port map (clk2, clk4, clk2_inv);
  FD1 : FD port map (clk1, clk2, clk1_inv);

  Divide_Frequency_gl0 : process(gl0_clk_buf)
  begin
    if gl0_clk_buf'event and gl0_clk_buf = '1' then
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

  Divide_Frequency_gl1 : process(gl1_clk_2_buf)
  begin
    if gl1_clk_2_buf'event and gl1_clk_2_buf = '1' then
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

-- Frequency dividers for the 2.5 and 1.25 MHz clocks which are too slow for the PLL 
  clk2p5_inv  <= not clk2p5;
  clk1p25_inv <= not clk1p25;
  FD2p5  : FD port map (D => clk2p5_inv, C => clk5, Q => clk2p5);
  FD1p25 : FD port map (D => clk1p25_inv, C => clk2p5, Q => clk1p25);


  vme_dtack_v6_b <= int_vme_dtack_v6_b;

  -- Raw signals come unsynced from outside
  LCTDLY_GTRG : LCTDLY port map(test_lct, clk40, LCT_L1A_DLY, test_l1a);

  testctrl_sel <= odmb_ctrl_reg(9);

  raw_l1a <= '1' when test_l1a = '1' else
             tc_l1a when (testctrl_sel = '1') else
             not ccb_l1acc;
  raw_lct(0) <= '1' when test_lct = '1' else
                tc_lct(0) when (testctrl_sel = '1') else
                rawlct(0);
  
  raw_lct(NFEB downto 1) <= (others => '1') when test_lct = '1' else
                            tc_lct(NFEB downto 1) when (testctrl_sel = '1') else
                            rawlct(NFEB downto 1);


  int_alct_dav           <= tc_alct_dav           when (testctrl_sel = '1') else alctdav;  -- lctdav2
  int_otmb_dav            <= tc_otmb_dav            when (testctrl_sel = '1') else otmbdav;  -- lctdav1
  --int_alct_dav <= tc_alct_dav;          -- lctdav2
  --int_otmb_dav  <= tc_otmb_dav;           -- lctdav1
  tc_run_out   <= tc_run;



-----------------------------  Monitoring  -----------------------------
-----------------------------------------------------------------------------

  raw_lct_cnt_proc : process (clk40, raw_lct, reset)
    variable raw_lct_cnt_data : l1a_match_cnt_type;
  begin
    for index in 1 to NFEB loop
      if (reset = '1') then
        raw_lct_cnt_data(index) := (others => '0');
      elsif (rising_edge(clk40)) then
        if (raw_lct(index) = '1') then
          raw_lct_cnt_data(index) := raw_lct_cnt_data(index) + 1;
        end if;
      end if;

      raw_lct_cnt(index) <= raw_lct_cnt_data(index);
    end loop;
  end process;

  l1a_match_cnt_proc : process (clk40, int_l1a_match, reset)
    variable l1a_match_cnt_data : l1a_match_cnt_type;
  begin
    for index in 1 to NFEB loop
      if (reset = '1') then
        l1a_match_cnt_data(index) := (others => '0');
      elsif (rising_edge(clk40)) then
        if (int_l1a_match(index) = '1') then
          l1a_match_cnt_data(index) := l1a_match_cnt_data(index) + 1;
        end if;
      end if;

      l1a_match_cnt(index) <= l1a_match_cnt_data(index);
    end loop;
  end process;

  --crc_cnt_proc : process (crc_valid, reset, gl1_clk_2_buf)
  crc_cnt_proc : process (crc_valid, reset, clk160)
    variable crc_cnt_data : l1a_match_cnt_type;
  begin
    for index in 1 to NFEB loop
      if (reset = '1') then
        crc_cnt_data(index) := (others => '0');
      elsif (rising_edge(clk160)) then
        if (crc_valid(index) = '1') then
          crc_cnt_data(index) := crc_cnt_data(index) + 1;
        end if;
      end if;

      crc_cnt(index) <= crc_cnt_data(index);
    end loop;
  end process;

  -- Defined to count the ALCT and OTMB davs as well 
  into_cafifo_dav(NFEB downto 1) <= dcfeb_data_valid(NFEB downto 1);  -- MUXed from gen and real
  into_cafifo_dav(8)             <= otmb_fifo_data_valid;
  into_cafifo_dav(9)             <= alct_fifo_data_valid;

  into_cafifo_dav_cnt_pro : process (clk40, reset, dav_cnt_en)
    variable dav_cnt_data : dav_cnt_type;
  begin
    for index in 1 to NFEB+2 loop
      if (reset = '1') then
        dav_cnt_data(index) := (others => '0');
      elsif (rising_edge(clk40) and dav_cnt_en(index) = '1') then
        dav_cnt_data(index) := dav_cnt_data(index) + 1;
      end if;

      into_cafifo_dav_cnt(index) <= dav_cnt_data(index);
    end loop;
    
  end process;

  dav_fsm_regs : process (dav_next_state, reset, clk40)
  begin
    for index in 1 to NFEB+2 loop
      if (reset = '1') then
        dav_current_state(index) <= DAV_IDLE;
      elsif rising_edge(clk40) then
        dav_current_state(index) <= dav_next_state(index);
      end if;
    end loop;
  end process;

  dav_fsm_logic : process (dav_current_state, into_cafifo_dav)
  begin
    for index in 1 to NFEB+2 loop
      case dav_current_state(index) is
        when DAV_IDLE =>
          if (into_cafifo_dav(index) = '1') then
            dav_next_state(index) <= DAV_HIGH;
            dav_cnt_en(index)     <= '1';
          else
            dav_next_state(index) <= DAV_IDLE;
            dav_cnt_en(index)     <= '0';
          end if;
          
        when DAV_HIGH =>
          dav_cnt_en(index) <= '0';
          if (into_cafifo_dav(index) = '0') then
            dav_next_state(index) <= DAV_IDLE;
          else
            dav_next_state(index) <= DAV_HIGH;
          end if;

        when others =>
          dav_next_state(index) <= DAV_IDLE;
          dav_cnt_en(index)     <= '0';
          
      end case;
    end loop;
  end process;


  gap_cnt : process (clk40, reset, gap_cnt_rst, gap_cnt_en)
    variable gap_cnt_data : gap_cnt_type;
  begin
    for dcfeb_index in 1 to NFEB loop
      if (reset = '1') then
        gap_cnt_data(dcfeb_index) := (others => '0');
      elsif (rising_edge(clk40)) then
        if (gap_cnt_rst(dcfeb_index) = '1') then
          gap_cnt_data(dcfeb_index) := (others => '0');
        elsif (gap_cnt_en(dcfeb_index) = '1') then
          gap_cnt_data(dcfeb_index) := gap_cnt_data(dcfeb_index) + 1;
        end if;
      end if;

      lct_l1a_gap(dcfeb_index) <= gap_cnt_data(dcfeb_index);
    end loop;
  end process;


  gap_fsm_regs : process (gap_next_state, reset, clk40)
  begin
    for dcfeb_index in 1 to NFEB loop
      if (reset = '1') then
        gap_current_state(dcfeb_index) <= GAP_IDLE;
      elsif rising_edge(clk40) then
        gap_current_state(dcfeb_index) <= gap_next_state(dcfeb_index);
      end if;
    end loop;
  end process;

  gap_fsm_logic : process (gap_current_state, raw_lct, raw_l1a)
  begin
    
    for dcfeb_index in 1 to NFEB loop

      case gap_current_state(dcfeb_index) is
        
        when GAP_IDLE =>
          
          if (raw_lct(dcfeb_index) = '1') then
            gap_next_state(dcfeb_index) <= GAP_COUNTING;
            gap_cnt_rst(dcfeb_index)    <= '1';
            gap_cnt_en(dcfeb_index)     <= '0';
          else
            gap_next_state(dcfeb_index) <= GAP_IDLE;
            gap_cnt_rst(dcfeb_index)    <= '0';
            gap_cnt_en(dcfeb_index)     <= '0';
          end if;
          
        when GAP_COUNTING =>
          if (raw_l1a = '1') then
            gap_next_state(dcfeb_index) <= GAP_IDLE;
            gap_cnt_rst(dcfeb_index)    <= '0';
            gap_cnt_en(dcfeb_index)     <= '0';
          else
            gap_next_state(dcfeb_index) <= GAP_COUNTING;
            gap_cnt_rst(dcfeb_index)    <= '0';
            gap_cnt_en(dcfeb_index)     <= '1';
          end if;

        when others =>
          gap_next_state(dcfeb_index) <= GAP_IDLE;
          gap_cnt_rst(dcfeb_index)    <= '1';
          gap_cnt_en(dcfeb_index)     <= '0';
          
      end case;
      
    end loop;

  end process;


  -- PC packets counter
  gtx0_dv_cnt_proc : process (gtx1_data_valid, reset)
  begin
    if (reset = '1') then
      gtx1_data_valid_cnt <= (others => '0');
    elsif (rising_edge(gtx1_data_valid)) then
      gtx1_data_valid_cnt <= gtx1_data_valid_cnt + 1;
    end if;
  end process;

  int_l1a_cnt_proc : process (int_l1a, reset)
  begin
    if (reset = '1') then
      int_l1a_cnt <= (others => '0');
    elsif (rising_edge(int_l1a)) then
      int_l1a_cnt <= int_l1a_cnt + 1;
    end if;
  end process;

  -- DDU packet counter
  gtx_dv_cnt_proc : process (ddu_eof, reset)
  begin
    if (reset = '1') then
      ddu_eof_cnt <= (others => '0');
    elsif (rising_edge(ddu_eof)) then
      ddu_eof_cnt <= ddu_eof_cnt + 1;
    end if;
  end process;

  gen_data_fifo_re_cnt : for index in 1 to NFEB+2 generate
  begin
    data_fifo_re_cnt(index) <= (others => '0') when (reset = '1') else
                               data_fifo_re_cnt(index) + 1 when rising_edge(data_fifo_re(index)) else
                               data_fifo_re_cnt(index);
  end generate gen_data_fifo_re_cnt;

  gen_data_fifo_oe_cnt : for index in 1 to NFEB+2 generate
  begin
    data_fifo_oe_cnt(index) <= (others => '0') when (reset = '1') else
                               data_fifo_oe_cnt(index) + 1 when rising_edge(data_fifo_oe(index)) else
                               data_fifo_oe_cnt(index);
  end generate gen_data_fifo_oe_cnt;

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
        ledg(4) <= not pll1_locked;
        ledg(5) <= testctrl_sel;
        ledg(6) <= gen_dcfeb_sel;

        ledr(5 downto 1) <= not cafifo_l1a_cnt(4 downto 0);
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



  odmb_status : process (dcfeb_adc_mask, dcfeb_fsel, dcfeb_jtag_ir, mbc_instr, mbc_jtag_ir, odmb_data_sel,
                         l1a_match_cnt, lct_l1a_gap, into_cafifo_dav_cnt, cafifo_l1a_match_out, cafifo_l1a_dav,
                         data_fifo_re_cnt, gtx1_data_valid_cnt, ddu_eof_cnt, data_fifo_oe_cnt, crc_cnt)
  begin
    
    case odmb_data_sel is

      when x"00" => odmb_data <= "0000" & dcfeb_adc_mask(1);
      when x"01" => odmb_data <= dcfeb_fsel(1)(15 downto 0);
      when x"02" => odmb_data <= dcfeb_fsel(1)(31 downto 16);
      when x"03" => odmb_data <= "00" & dcfeb_jtag_ir(1) & "000" & dcfeb_fsel(1)(31);

      when x"04" => odmb_data <= "0000" & dcfeb_adc_mask(2);
      when x"05" => odmb_data <= dcfeb_fsel(2)(15 downto 0);
      when x"06" => odmb_data <= dcfeb_fsel(2)(31 downto 16);
      when x"07" => odmb_data <= "00" & dcfeb_jtag_ir(2) & "000" & dcfeb_fsel(2)(31);

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

      when x"1C" => odmb_data <= mbc_instr(16 downto 1);
      when x"1D" => odmb_data <= mbc_instr(32 downto 17);
      when x"1E" => odmb_data <= '0' & mbc_instr(47 downto 33);
      when x"1F" => odmb_data <= "00" & mbc_jtag_ir(9 downto 0) & "0000";

      when x"20" => odmb_data <= "0000000000" & vme_gap & vme_ga;

      when x"21" => odmb_data <= l1a_match_cnt(1);
      when x"22" => odmb_data <= l1a_match_cnt(2);
      when x"23" => odmb_data <= l1a_match_cnt(3);
      when x"24" => odmb_data <= l1a_match_cnt(4);
      when x"25" => odmb_data <= l1a_match_cnt(5);
      when x"26" => odmb_data <= l1a_match_cnt(6);
      when x"27" => odmb_data <= l1a_match_cnt(7);

      when x"28" => odmb_data <= ts_out(15 downto 0);
      when x"29" => odmb_data <= ts_out (31 downto 16);

      when x"2A" => odmb_data <= "00000000000" & alct_push_dly;
      when x"2B" => odmb_data <= "00000000000" & otmb_push_dly;
      when x"2C" => odmb_data <= "00000000000" & push_dly;
      when x"2D" => odmb_data <= "0000000000" & lct_l1a_dly;

      when x"31" => odmb_data <= lct_l1a_gap(1);
      when x"32" => odmb_data <= lct_l1a_gap(2);
      when x"33" => odmb_data <= lct_l1a_gap(3);
      when x"34" => odmb_data <= lct_l1a_gap(4);
      when x"35" => odmb_data <= lct_l1a_gap(5);
      when x"36" => odmb_data <= lct_l1a_gap(6);
      when x"37" => odmb_data <= lct_l1a_gap(7);

      when x"38" => odmb_data <= "0000000" & cafifo_l1a_match_out;
      when x"39" => odmb_data <= "0000000" & cafifo_l1a_dav;
      when x"3A" => odmb_data <= "00000000" & cafifo_l1a_cnt(23 downto 16);
      when x"3B" => odmb_data <= cafifo_l1a_cnt(15 downto 0);
      when x"3C" => odmb_data <= "0000" & cafifo_bx_cnt;
      when x"3D" => odmb_data <= "00000000" & cafifo_rd_addr & cafifo_wr_addr;
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

      when x"4A" => odmb_data <= ddu_eof_cnt;          -- Number of packets sent to DDU
      when x"4B" => odmb_data <= gtx1_data_valid_cnt;  -- Number of packets sent to PC
      when x"4C" => odmb_data <= data_fifo_oe_cnt(1);  -- from control to FIFOs in top

      when x"51" => odmb_data <= data_fifo_re_cnt(1);  -- from control to FIFOs in top
      when x"52" => odmb_data <= data_fifo_re_cnt(2);  -- from control to FIFOs in top
      when x"53" => odmb_data <= data_fifo_re_cnt(3);  -- from control to FIFOs in top
      when x"54" => odmb_data <= data_fifo_re_cnt(4);  -- from control to FIFOs in top
      when x"55" => odmb_data <= data_fifo_re_cnt(5);  -- from control to FIFOs in top
      when x"56" => odmb_data <= data_fifo_re_cnt(6);  -- from control to FIFOs in top
      when x"57" => odmb_data <= data_fifo_re_cnt(7);  -- from control to FIFOs in top
      when x"58" => odmb_data <= data_fifo_re_cnt(8);  -- from control to FIFOs in top
      when x"59" => odmb_data <= data_fifo_re_cnt(9);  -- from control to FIFOs in top

      when x"61" => odmb_data <= crc_cnt(1);
      when x"62" => odmb_data <= crc_cnt(2);
      when x"63" => odmb_data <= crc_cnt(3);
      when x"64" => odmb_data <= crc_cnt(4);
      when x"65" => odmb_data <= crc_cnt(5);
      when x"66" => odmb_data <= crc_cnt(6);
      when x"67" => odmb_data <= crc_cnt(7);

      when x"71" => odmb_data <= raw_lct_cnt(1);
      when x"72" => odmb_data <= raw_lct_cnt(2);
      when x"73" => odmb_data <= raw_lct_cnt(3);
      when x"74" => odmb_data <= raw_lct_cnt(4);
      when x"75" => odmb_data <= raw_lct_cnt(5);
      when x"76" => odmb_data <= raw_lct_cnt(6);
      when x"77" => odmb_data <= raw_lct_cnt(7);

      when others => odmb_data <= (others => '1');
    end case;
  end process;
  

  tpl(6)  <= raw_lct(1);
  tpl(8)  <= raw_lct(2);
  tpl(10) <= raw_lct(3);
  tpl(12) <= raw_lct(4);
  tpl(14) <= raw_lct(5);
  tpl(16) <= raw_lct(6);
  tpl(18) <= raw_lct(7);
  tpl(7)  <= int_l1a_match(1);
  tpl(9)  <= int_l1a_match(2);
  tpl(11) <= int_l1a_match(3);
  tpl(13) <= int_l1a_match(4);
  tpl(15) <= int_l1a_match(5);
  tpl(17) <= int_l1a_match(6);
  tpl(19) <= int_l1a_match(7);
  tpl(20) <= int_l1a;
  tpl(21) <= gtx0_data_valid;
  tpl(22) <= otmbdav;
  tpl(23) <= alctdav;

  tph(29) <= cafifo_l1a_dav(1);
  tph(30) <= cafifo_l1a_dav(2);
  tph(31) <= gtx0_data_valid;
  tph(32) <= gtx1_data_valid;
  tph(33) <= rawlct(1);
  tph(34) <= rawlct(2);
  tph(35) <= rawlct(3);
  tph(36) <= rawlct(4);
  tph(37) <= rawlct(5);
  tph(38) <= rawlct(6);
  tph(39) <= rawlct(7);
  tph(40) <= lct_err;
  tph(43) <= '0';
  tph(44) <= '0';
  tph(45) <= '0';
  tph(46) <= '0';

  tp_selector : process (tp_sel_reg, gtx0_data_valid, cafifo_l1a_dav, int_l1a_match, dcfeb_data_valid,
                         int_otmb_dav, dcfeb_data, otmb_fifo_data_in, otmb_fifo_data_valid, int_alct_dav,
                         alct_fifo_data_in,
                         alct_fifo_data_valid, ext_dcfeb_l1a_cnt7, dcfeb_l1a_dav7, odmb_tms, odmb_tdi, odmb_tdo,
                         v6_jtag_sel_inner, int_tms, int_tdi, int_tck, int_tdo, raw_lct, rawlct, int_l1a,
                         otmb_lct_rqst, otmb_ext_trig, raw_l1a)
  begin
    case tp_sel_reg is
      when x"0000" =>
        tph(27) <= gtx0_data_valid;
        tph(28) <= cafifo_l1a_dav(7);
        tph(41) <= int_l1a_match(7);
        tph(42) <= dcfeb_data_valid(7);

      when x"0001" =>
        tph(27) <= int_l1a_match(1);
        tph(28) <= cafifo_l1a_dav(1);
        tph(41) <= dcfeb_data(1)(0);
        tph(42) <= dcfeb_data_valid(1);

      when x"0002" =>
        tph(27) <= int_l1a_match(2);
        tph(28) <= cafifo_l1a_dav(2);
        tph(41) <= dcfeb_data(2)(0);
        tph(42) <= dcfeb_data_valid(2);

      when x"0003" =>
        tph(27) <= int_l1a_match(3);
        tph(28) <= cafifo_l1a_dav(3);
        tph(41) <= dcfeb_data(3)(0);
        tph(42) <= dcfeb_data_valid(3);

      when x"0004" =>
        tph(27) <= int_l1a_match(4);
        tph(28) <= cafifo_l1a_dav(4);
        tph(41) <= dcfeb_data(4)(0);
        tph(42) <= dcfeb_data_valid(4);

      when x"0005" =>
        tph(27) <= int_l1a_match(5);
        tph(28) <= cafifo_l1a_dav(5);
        tph(41) <= dcfeb_data(5)(0);
        tph(42) <= dcfeb_data_valid(5);

      when x"0006" =>
        tph(27) <= int_l1a_match(6);
        tph(28) <= cafifo_l1a_dav(6);
        tph(41) <= dcfeb_data(6)(0);
        tph(42) <= dcfeb_data_valid(6);

      when x"0007" =>
        tph(27) <= int_l1a_match(7);
        tph(28) <= cafifo_l1a_dav(7);
        tph(41) <= dcfeb_data(7)(0);
        tph(42) <= dcfeb_data_valid(7);

      when x"0008" =>
        tph(27) <= int_otmb_dav;
        tph(28) <= cafifo_l1a_dav(8);
        tph(41) <= otmb_fifo_data_in(0);
        tph(42) <= otmb_fifo_data_valid;

      when x"0009" =>
        tph(27) <= int_alct_dav;
        tph(28) <= cafifo_l1a_dav(9);
        tph(41) <= alct_fifo_data_in(0);
        tph(42) <= alct_fifo_data_valid;

      when x"000A" =>
        tph(27) <= ext_dcfeb_l1a_cnt7(0);
        tph(28) <= dcfeb_l1a_dav7;
        tph(41) <= dcfeb_data(7)(0);
        tph(42) <= dcfeb_data_valid(7);

      when x"0010" =>
        tph(27) <= odmb_tms;
        tph(28) <= odmb_tdi;
        tph(41) <= odmb_tdo;
        tph(42) <= dcfeb_data_valid(7);

      when x"0011" =>
        tph(27) <= gtx1_data_valid;
        tph(28) <= pc_tx_fifo_wren;
        tph(41) <= pc_txd_frame(0);
        tph(42) <= pc_txd_frame(1);

      when x"0012" =>
        tph(27) <= gtx1_data_valid;
        tph(28) <= gl_pc_tx_ack;
        tph(41) <= rom_cnt_out(0);
        tph(42) <= rom_cnt_out(1);

      when x"0013" =>
        tph(27) <= int_tdi;
        tph(28) <= int_tms;
        tph(41) <= int_tdo(7);
        tph(42) <= int_tck(7);

      when x"0014" =>
        tph(27) <= otmb_lct_rqst;
        tph(28) <= otmb_ext_trig;
        tph(41) <= raw_lct(0);
        tph(42) <= raw_lct(1);

      when x"0015" =>
        tph(27) <= int_l1a;
        tph(28) <= raw_l1a;
        tph(41) <= raw_lct(0);
        tph(42) <= raw_lct(1);

      when x"0016" =>
        tph(27) <= int_l1a;
        tph(28) <= raw_l1a;
        tph(41) <= alctdav;
        tph(42) <= otmbdav;

      when x"0017" =>
        tph(27) <= int_l1a;
        tph(28) <= raw_l1a;
        tph(41) <= alct(16);
        tph(42) <= alct(17);

      when x"0018" =>
        tph(27) <= int_l1a;
        tph(28) <= raw_l1a;
        tph(41) <= otmb(16);
        tph(42) <= otmb(17);

      when others =>
        tph(27) <= int_l1a;
        tph(28) <= raw_lct(1);
        tph(41) <= rawlct(1);
        tph(42) <= int_l1a_match(1);
    end case;
  end process;

end ODMB_UCSB_V2_ARCH;
