-- ODMB_CTRL: Controls triggers, calibration, and the data path

library ieee;
library work;
use work.Latches_Flipflops.all;
use ieee.std_logic_1164.all;

entity ODMB_CTRL is
  generic (
    NFIFO     : integer range 1 to 16 := 8;  -- Number of FIFOs in PCFIFO
    NFEB      : integer range 1 to 7  := 7;  -- Number of DCFEBS, 7 in the final design
    FIFO_SIZE : integer range 1 to 64 := 16  -- Number FIFO words in CAFIFO
    );  
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
    ccb_cmd_s  : in  std_logic;         -- ccbcmnd(6) - from J3
    ccb_data   : in  std_logic_vector (7 downto 0);  -- ccbdata(7 downto 0) - from J3
    ccb_data_s : in  std_logic;         -- ccbdata(8) - from J3
    ccb_cal    : in  std_logic_vector (2 downto 0);  -- ccbcal(2 downto 0) - from J3
    ccb_crsv   : in  std_logic_vector (4 downto 0);  -- NEW [ccbrsv(6)], ccbrsv(3 downto 0) - from J3
    ccb_drsv   : in  std_logic_vector (1 downto 0);  -- ccbrsv(5 downto 4) - from J3
    ccb_rsvo   : in  std_logic_vector (4 downto 0);  -- NEW [ccbrsv(11)], ccbrsv(10 downto 7) - from J3
    ccb_rsvi   : out std_logic_vector (2 downto 0);  -- ccbrsv(14 downto 12) - to J3
    ccb_bx0    : in  std_logic;         -- bx0 - from J3
    ccb_bxrst  : in  std_logic;         -- bxrst - from J3
    ccb_l1acc  : in  std_logic;         -- l1acc - from J3
    ccb_l1arst : in  std_logic;         -- l1rst - from J3
    ccb_l1rls  : out std_logic;         -- l1rls - to J3
    ccb_clken  : in  std_logic;         -- clken - from J3

    rawlct    : in  std_logic_vector (NFEB downto 0);  -- rawlct(5 downto 0) - from J4
    tmb_dav   : in  std_logic;          -- previously lctdav1, from J4
    alct_dav  : in  std_logic;          -- previously lctdav2, from J4
    lctrqst   : out std_logic_vector (2 downto 1);  -- lctrqst(2 downto 1) - to J4
    rsvtd_in  : in  std_logic_vector(4 downto 0);  -- OK   spare(2 DOWNTO 0) - to J4
    rsvtd_out : out std_logic_vector(2 downto 0);  -- OK           spare(7 DOWNTO 3) - from J4

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

-- From/To Data FIFOs

    data_fifo_re : out std_logic_vector(NFEB+2 downto 1);
    data_fifo_oe : out std_logic_vector(NFEB+2 downto 1);

    fifo_out : in std_logic_vector(15 downto 0);
    fifo_eof : in std_logic;

    fifo_empty_b : in std_logic_vector(NFEB+2 downto 1);  -- emptyf*(7 DOWNTO 1) - from FIFOs 

-- From CAFIFO to Data FIFOs
    dcfeb_fifo_wr_en     : out std_logic_vector(NFEB downto 1);
    alct_fifo_wr_en      : out std_logic;
    tmb_fifo_wr_en       : out std_logic;
    cafifo_l1a_match_in  : out std_logic_vector(NFEB+2 downto 1);  -- From TRGCNTRL to CAFIFO to generate Data  
    cafifo_l1a_match_out : out std_logic_vector(NFEB+2 downto 1);  -- From CAFIFO to CONTROL  
    cafifo_l1a_cnt       : out std_logic_vector(23 downto 0);
    cafifo_l1a_dav       : out std_logic_vector(NFEB+2 downto 1);
    cafifo_bx_cnt        : out std_logic_vector(11 downto 0);

    cafifo_wr_addr : out std_logic_vector(3 downto 0);
    cafifo_rd_addr : out std_logic_vector(3 downto 0);

    ext_dcfeb_l1a_cnt7 : out std_logic_vector(23 downto 0);
    dcfeb_l1a_dav7     : out std_logic;


-- To PCFIFO
    gl_pc_tx_ack : in std_logic;
    dduclk       : in std_logic;
    pcclk        : in std_logic;
    eof_data     : in std_logic_vector(NFEB+2 downto 1);

-- From ALCT,TMB,DCFEBs to CAFIFO
    alct_dv     : in std_logic;
    tmb_dv      : in std_logic;
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

    dcfeb_injpulse  : out std_logic;    -- inject - to DCFEBs
    dcfeb_extpulse  : out std_logic;    -- extpulse - to DCFEBs
    dcfeb_l1a       : out std_logic;
    dcfeb_l1a_match : out std_logic_vector(NFEB downto 1);

    tck : in  std_logic;
    tdi : in  std_logic;
    tms : in  std_logic;
    tdo : out std_logic;

    test_ccbinj : in std_logic;
    test_ccbpls : in std_logic;

    lct_err : out std_logic;            -- To an LED in the original design
    leds    : out std_logic_vector(6 downto 0);

    cal_mode   : in std_logic;
    cal_trgsel : in std_logic;
    cal_trgen  : in std_logic_vector(3 downto 0);

    ALCT_PUSH_DLY : in std_logic_vector(4 downto 0);
    TMB_PUSH_DLY  : in std_logic_vector(4 downto 0);
    PUSH_DLY      : in std_logic_vector(4 downto 0);
    LCT_L1A_DLY   : in std_logic_vector(5 downto 0);
    INJ_DLY       : in std_logic_vector(4 downto 0);
    EXT_DLY       : in std_logic_vector(4 downto 0);
    CALLCT_DLY    : in std_logic_vector(3 downto 0);
    KILL          : in std_logic_vector(NFEB+2 downto 1);
    CRATEID       : in std_logic_vector(6 downto 0);

    ddu_data_valid : out std_logic
    );

end ODMB_CTRL;


architecture ODMB_CTRL_arch of ODMB_CTRL is

  component BGB_BSCAN_emulator is
    port(
      IR : out std_logic_vector(9 downto 0);

      CAPTURE1 : out std_ulogic;
      DRCK1    : out std_ulogic;
      RESET1   : out std_ulogic;
      SEL1     : out std_ulogic;
      SHIFT1   : out std_ulogic;
      UPDATE1  : out std_ulogic;
      RUNTEST1 : out std_ulogic;
      TDO1     : in  std_ulogic;

      CAPTURE2 : out std_ulogic;
      DRCK2    : out std_ulogic;
      RESET2   : out std_ulogic;
      SEL2     : out std_ulogic;
      SHIFT2   : out std_ulogic;
      UPDATE2  : out std_ulogic;
      RUNTEST2 : out std_ulogic;
      TDO2     : in  std_ulogic;

      TDO3 : in std_ulogic;
      TDO4 : in std_ulogic;

      TDO : out std_ulogic;

      TCK  : in std_ulogic;
      TDI  : in std_ulogic;
      TMS  : in std_ulogic;
      TRST : in std_ulogic
      );

  end component;


  component INSTRGDC is
    port (
      BTDI   : in  std_logic;           -- TDI from BSCAN_VIRTEX
      DRCK   : in  std_logic;           -- Signals are from BSCAN_VIRTEX
      SEL1   : in  std_logic;
      UPDATE : in  std_logic;
      SHIFT  : in  std_logic;
      D0     : out std_logic;
      FSEL   : in  std_logic_vector(5 downto 0);
      F      : out std_logic_vector(47 downto 1)
      );

  end component;

  component CONFLOGIC is                -- Used to be discrete logic in JTAGCOM
    generic (
      NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
      );  
    port (
      CLKCMS : in std_logic;
      RST    : in std_logic;

      INSTR  : in std_logic_vector(47 downto 1);
      CCBINJ : in std_logic;
      CCBPLS : in std_logic;
      CCBPED : in std_logic;
      SELRAN : in std_logic;

      CAL_TRGSEL : out std_logic;
      ENACFEB    : out std_logic;
      CAL_MODE   : out std_logic
      );
  end component;


  component CALTRIGCON is
    generic (
      NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
      );  
    port (
      CLKIN  : in std_logic;
      CLKSYN : in std_logic;
      RST    : in std_logic;

      DIN   : in std_logic;
      DRCK  : in std_logic;
      SEL2  : in std_logic;
      SHIFT : in std_logic;
      FLOAD : in std_logic;
      FCYC  : in std_logic;
      FCYCM : in std_logic;

      CCBPED : in std_logic;

      LCTOUT  : out std_logic;
      GTRGOUT : out std_logic
      );

  end component;

  component RANDOMTRG is
    generic (
      NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
      );  
    port (
      CLK : in std_logic;
      RST : in std_logic;

      DIN    : in std_logic;
      DRCK   : in std_logic;
      SEL2   : in std_logic;
      SHIFT  : in std_logic;
      UPDATE : in std_logic;

      FLOAD   : in std_logic;           -- INSTR19
      FTSTART : in std_logic;           -- INSTR20
      FBURST  : in std_logic;           -- INSTR32

      ENL1RLS : in std_logic;

      PREL1RLS : out std_logic;
      SELRAN   : out std_logic;
      GTRGOUT  : out std_logic;
      LCTOUT   : out std_logic_vector(NFEB downto 0);
      PULSE    : out std_logic
      );
  end component;

  component LOADCFEB is
    generic (
      NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
      );  
    port (
      CLK : in std_logic;
      RST : in std_logic;

      BTDI   : in  std_logic;
      DRCK   : in  std_logic;
      SEL2   : in  std_logic;
      SHIFT  : in  std_logic;
      UPDATE : in  std_logic;
      TDO    : out std_logic;

      FLOAD    : in std_logic;
      CALLCT_1 : in std_logic;
      RNDMLCT  : in std_logic_vector(NFEB downto 0);

      LCTFEB : out std_logic_vector(NFEB downto 0);
      CFEB   : out std_logic_vector(NFEB downto 1)
      );
  end component;

  component TRGSEL is
    port (
      RST : in std_logic;

      BTDI   : in std_logic;
      SEL2   : in std_logic;
      DRCK   : in std_logic;
      UPDATE : in std_logic;
      SHIFT  : in std_logic;

      FLOAD : in std_logic;

      TDO    : out std_logic;
      JTRGEN : out std_logic_vector(3 downto 0)
      );
  end component;

  component TRGCNTRL is
    generic (
      NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
      );  
    port (
      CLK           : in std_logic;
      RAW_L1A       : in std_logic;
      RAW_LCT       : in std_logic_vector(NFEB downto 0);
      CAL_LCT       : in std_logic_vector(NFEB downto 0);
      CAL_L1A       : in std_logic;
      LCT_L1A_DLY   : in std_logic_vector(5 downto 0);
      PUSH_DLY      : in std_logic_vector(4 downto 0);
      ALCT_DAV      : in std_logic;
      TMB_DAV       : in std_logic;
      ALCT_PUSH_DLY : in std_logic_vector(4 downto 0);
      TMB_PUSH_DLY  : in std_logic_vector(4 downto 0);

      JTRGEN    : in std_logic_vector(3 downto 0);
      EAFEB     : in std_logic;
      CMODE     : in std_logic;
      CALTRGSEL : in std_logic;
      KILLCFEB  : in std_logic_vector(NFEB downto 1);

      DCFEB_L1A       : out std_logic;
      DCFEB_L1A_MATCH : out std_logic_vector(NFEB downto 1);
      FIFO_PUSH       : out std_logic;
      FIFO_L1A_MATCH  : out std_logic_vector(NFEB+2 downto 0);
      LCT_ERR         : out std_logic
      );
  end component;

  component pcfifo is
    generic (
      NFIFO : integer range 1 to 16 := 8  -- Number of FIFOs in PCFIFO
      );  
    port(

      clk_in  : in std_logic;
      clk_out : in std_logic;
      rst     : in std_logic;

      tx_ack : in std_logic;

      dv_in   : in std_logic;
      ld_in   : in std_logic;
      data_in : in std_logic_vector(15 downto 0);

      dv_out   : out std_logic;
      data_out : out std_logic_vector(15 downto 0)
      );
  end component;

  component CONTROL is
    generic (
      NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
      );  
    port (

      RST    : in std_logic;
      CLKCMS : in std_logic;
      CLK    : in std_logic;
      STATUS : in std_logic_vector(47 downto 0);
      L1ARST : in std_logic;

-- From DMB_VME
      RDFFNXT : in std_logic;

-- to GigaBit Link
      DOUT : out std_logic_vector(15 downto 0);
      DAV  : out std_logic;

-- to FIFOs
      OEFIFO_B   : out std_logic_vector(NFEB+2 downto 1);
      RENFIFO_B  : out std_logic_vector(NFEB+2 downto 1);
      OEFFMON_B  : out std_logic_vector(NFEB+2 downto 1);
      RENFFMON_B : out std_logic_vector(NFEB+2 downto 1);

-- from FIFOs
      FFOR_B      : in std_logic_vector(NFEB+2 downto 1);
      DATAIN      : in std_logic_vector(15 downto 0);
      DATAIN_LAST : in std_logic;

-- From CONFREGS
      KILLINPUT : in std_logic_vector(NFEB+2 downto 1);

      SETLOOPBACK : in std_logic;
-- From LOADFIFO
      JOEF        : in std_logic_vector(NFEB+2 downto 1);

-- to ???
      DAQMBID  : in  std_logic_vector(11 downto 0);  -- From CRATEID in SETFEBDLY, and GA
      LOOPBACK : out std_logic;
      OEOVLP   : out std_logic;

-- FROM SW1
      GIGAEN : in std_logic;

-- TO CAFIFO
      FIFO_POP : out std_logic;

-- TO PCFIFO
      EOF : out std_logic;

-- FROM CAFIFO
      cafifo_l1a_dav   : in std_logic_vector(NFEB+2 downto 1);
      cafifo_l1a_match : in std_logic_vector(NFEB+2 downto 1);
      cafifo_l1a_cnt   : in std_logic_vector(23 downto 0);
      cafifo_bx_cnt    : in std_logic_vector(11 downto 0)
      );
  end component;

  component cafifo is
    generic (
      NFEB      : integer range 1 to 7  := 7;  -- Number of DCFEBS, 7 in the final design
      FIFO_SIZE : integer range 1 to 64 := 16  -- Number of CAFIFO words
      );  
    port(

      clk      : in std_logic;
      dcfebclk : in std_logic;
      rst      : in std_logic;
      resync   : in std_logic;

      BC0   : in std_logic;
      BXRST : in std_logic;

      l1a          : in std_logic;
      l1a_match_in : in std_logic_vector(NFEB+2 downto 1);

      pop : in std_logic;

      eof_data    : in std_logic_vector(NFEB+2 downto 1);
      alct_dv     : in std_logic;
      tmb_dv      : in std_logic;
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

      dcfeb_fifo_wren : out std_logic_vector(NFEB downto 1);
      alct_fifo_wren  : out std_logic;
      tmb_fifo_wren   : out std_logic;

      cafifo_l1a_match : out std_logic_vector(NFEB+2 downto 1);
      cafifo_l1a_cnt   : out std_logic_vector(23 downto 0);
      cafifo_l1a_dav   : out std_logic_vector(NFEB+2 downto 1);
      cafifo_bx_cnt    : out std_logic_vector(11 downto 0);

      ext_dcfeb_l1a_cnt7 : out std_logic_vector(23 downto 0);
      dcfeb_l1a_dav7     : out std_logic;

      cafifo_wr_addr : out std_logic_vector(3 downto 0);
      cafifo_rd_addr : out std_logic_vector(3 downto 0)
      );

  end component;

  component LOADFIFO is
    generic (
      NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
      );  

    port (
      SHIFT  : in  std_logic;
      FENF   : in  std_logic;
      BTDI   : in  std_logic;
      SEL2   : in  std_logic;
      DRCK   : in  std_logic;
      UPDATE : in  std_logic;
      RST    : in  std_logic;
      JOEF   : out std_logic_vector(NFEB+2 downto 1);
      TDO    : out std_logic);

  end component;

  component CCBCODE is
    port (
      CCB_CMD    : in  std_logic_vector(5 downto 0);
      CCB_CMD_S  : in  std_logic;
      CCB_DATA   : in  std_logic_vector(7 downto 0);
      CCB_DATA_S : in  std_logic;
      CMSCLK     : in  std_logic;
      CCB_BXRST  : in  std_logic;
      CCB_BX0    : in  std_logic;
      CCB_L1ARST : in  std_logic;
      CCB_CLKEN  : in  std_logic;
      BX0        : out std_logic;
      BXRST      : out std_logic;
      L1ARST     : out std_logic;
      CLKEN      : out std_logic;
      BC0        : out std_logic;
      L1ASRST    : out std_logic;
      TTCCAL     : out std_logic_vector(2 downto 0)
      );        

  end component;

  component CALIBTRG is
    port (
      CMSCLK      : in  std_logic;
      CLK80       : in  std_logic;
      RST         : in  std_logic;
      PLSINJEN    : in  std_logic;
      CCBPLS      : in  std_logic;
      CCBINJ      : in  std_logic;
      FPLS        : in  std_logic;
      FINJ        : in  std_logic;
      FPED        : in  std_logic;
      PRELCT      : in  std_logic;
      PREGTRG     : in  std_logic;
      INJ_DLY     : in  std_logic_vector(4 downto 0);
      EXT_DLY     : in  std_logic_vector(4 downto 0);
      CALLCT_DLY  : in  std_logic_vector(3 downto 0);
      LCT_L1A_DLY : in  std_logic_vector(5 downto 0);
      RNDMPLS     : in  std_logic;
      RNDMGTRG    : in  std_logic;
      PEDESTAL    : out std_logic;
      CAL_GTRG    : out std_logic;
--    CALLCT_1 : out std_logic;
      CALLCT      : out std_logic;
      INJBACK     : out std_logic;
      PLSBACK     : out std_logic;
-- SCPSYN AND SCOPE have not been implemented
-- and we do not intend to implement them (we think)
--    SCPSYN : out std_logic; 
--    SYNCIF : out std_logic;
      LCTRQST     : out std_logic;
      INJPLS      : out std_logic
      );
  end component;

-- clock and reset signals

  signal rst  : std_logic := '0';
  signal rstn : std_logic := '1';

-- jtag signals

  signal initjtags                                      : std_logic  := '0';
  signal drck1, sel1, reset1, shift1, capture1, update1 : std_ulogic := '0';
  signal drck2, sel2, reset2, shift2, capture2, update2 : std_ulogic := '0';
  signal b_tms1, b_tdi1, b_tck1                         : std_ulogic := '0';
  signal b_tms2, b_tdi2, b_tck2                         : std_ulogic := '0';
  signal tdo1                                           : std_ulogic := '0';
  signal tdo2                                           : std_ulogic := '0';

-------------------------------------------------------------------------------

  signal ccbped                                                           : std_logic;
  signal ccbinjin, ccbinjin_1, ccbinjin_2, ccbinjin_3, ccbinj             : std_logic;
  signal ccbplsin, ccbplsin_1, ccbplsin_2, ccbplsin_3, ccbpls             : std_logic;
  signal plsinjen_inner, plsinjen, plsinjen_1, plsinjen_rst, plsinjen_inv : std_logic;

-- INSTRGDC outputs

  signal instr : std_logic_vector(47 downto 1);

-- CONFLOGIC outputs
  signal JTAG_CAL_TRGSEL, ENACFEB, JTAG_CAL_MODE : std_logic;

-- CALTRIGCON outputs
  signal prelct, pregtrg : std_logic;

-- Switches: SW4->RANDOMTRG inputS
  signal sw4_enl1rls : std_logic := '1';

-- TRGCNTRL outputs
  signal cafifo_l1a_match_in_inner : std_logic_vector(NFEB+2 downto 0);
  signal cafifo_push               : std_logic;  -- PUSH from TRGCNTRL to CAFIFO

-- CAFIFO outputs
  signal cafifo_l1a_match_out_inner : std_logic_vector(NFEB+2 downto 1);
  signal cafifo_l1a_cnt_out         : std_logic_vector(23 downto 0);
  signal cafifo_l1a_dav_out         : std_logic_vector(NFEB+2 downto 1);
  signal cafifo_bx_cnt_out          : std_logic_vector(11 downto 0);

-- CONTROL outputs
  signal cafifo_pop           : std_logic := '0';
  signal eof                  : std_logic := '0';
  signal ddu_data             : std_logic_vector(15 downto 0);
  signal ddu_data_valid_inner : std_logic := 'L';

-- PCFIFO outputs
  signal pc_data       : std_logic_vector(15 downto 0);
  signal pc_data_valid : std_logic;

-- RANDOMTRG outputs
  signal rndmgtrg, rndmpls, selran : std_logic;
  signal rndmlct                   : std_logic_vector(NFEB downto 0);

-- LOADCFEF outputs
  signal CAL_LCT       : std_logic_vector(NFEB downto 0);
  signal loadcfeb_cfeb : std_logic_vector(NFEB downto 1);

-- TRGSEL outputs
  signal jtag_trgen : std_logic_vector(3 downto 0);

-- CCBCODE outputs

  signal bx0     : std_logic;
  signal bxrst   : std_logic;
  signal l1arst  : std_logic;
  signal clken   : std_logic;
  signal bc0     : std_logic;
  signal l1asrst : std_logic;
  signal ttccal  : std_logic_vector(2 downto 0);


-- LOADFIFO outputs

  signal joef     : std_logic_vector(NFEB+2 downto 1);
  signal tdo_fifo : std_logic;

  signal LOGICL : std_logic := '0';
  signal LOGICH : std_logic := '1';

-- CALIBTRG outputs

  signal pedestal   : std_logic;
  signal cal_gtrg   : std_logic;
  signal callct_1   : std_logic;
  signal inject     : std_logic;
  signal pulse      : std_logic;
  signal prelctrqst : std_logic;
  signal injplsmon  : std_logic;

-------------------------------------------------------------------------------

  signal mon_fifo_re : std_logic_vector(NFEB+2 downto 1);
  signal mon_fifo_oe : std_logic_vector(NFEB+2 downto 1);

  signal status : std_logic_vector(47 downto 0) := (others => '0');

  signal rdffnxt     : std_logic := '0';  -- from MBV
  signal setloopback : std_logic := '0';  -- from JTAGCOM
  signal daqmbid     : std_logic_vector(11 downto 0);

begin

--  status(2 downto 0) <= jtrgen(2 downto 0);         -- from TRGSEL
--  status(3) <= gtrgfifoerr;                         -- from GTRGFIFO
--  status(4) <= sfmwp_b;                             -- from SERFMEM
--  status(5) <= trgsel;                              -- from TRGSEL
--  status(6) <= pedestal;                            -- from CALIBTRG
--  status(14 downto 7) <= updn(7 downto 1);          -- from GTRGFIFO
--  status(19 downto 15) <= daverror(5 downto 1);     -- from GTRGFIFO
--  status(26 downto 20) <= fifo_empty(7 downto 1);   -- from Data FIFOs (ffor_)
--  status(33 downto 27) <= fifo_full(7 downto 1);    -- from Data FIFOs
--  status(40 downto 34) <= fifo_hfull(7 downto 1);   -- from Data FIFOs
--  status(47 downto 41) <= fifo_aempty(7 downto 1);  -- from Data FIFOs
  
  TRGCNTRL_PM : TRGCNTRL
    generic map (NFEB => NFEB)
    port map (
      CLK           => clk40,
      RAW_L1A       => ccb_l1acc,
      RAW_LCT       => rawlct,
      CAL_LCT       => cal_lct,
      CAL_L1A       => cal_gtrg,
      LCT_L1A_DLY   => lct_l1a_dly,
      PUSH_DLY      => push_dly,        -- Not used for now
      ALCT_DAV      => alct_dav,
      TMB_DAV       => tmb_dav,
      ALCT_PUSH_DLY => alct_push_dly,
      TMB_PUSH_DLY  => tmb_push_dly,

      JTRGEN    => cal_trgen,
      EAFEB     => enacfeb,
      CMODE     => cal_mode,
      CALTRGSEL => cal_trgsel,
      KILLCFEB  => kill(NFEB downto 1),

      DCFEB_L1A       => dcfeb_l1a,
      DCFEB_L1A_MATCH => dcfeb_l1a_match,
      FIFO_PUSH       => cafifo_push,
      FIFO_L1A_MATCH  => cafifo_l1a_match_in_inner,
      LCT_ERR         => lct_err
      );

  CAFIFO_PM : cafifo
    generic map (NFEB => NFEB, FIFO_SIZE => FIFO_SIZE)
    port map(
      clk      => clk40,
      dcfebclk => clk160,
      rst      => reset,
      resync   => resync,

      BC0   => bc0,
      BXRST => ccb_bxrst,               -- SHOULD BE bxrst,

--       l1a => dcfeb_l1a,
      l1a          => cafifo_push,
--       l1a_match_in => dcfeb_l1a_match,
      l1a_match_in => cafifo_l1a_match_in_inner(NFEB+2 downto 1),

      eof_data => eof_data,

      pop => cafifo_pop,

      alct_dv     => alct_dv,
      tmb_dv      => tmb_dv,
      dcfeb0_dv   => dcfeb0_dv,
      dcfeb0_data => dcfeb0_data,
      dcfeb1_dv   => dcfeb1_dv,
      dcfeb1_data => dcfeb1_data,
      dcfeb2_dv   => dcfeb2_dv,
      dcfeb2_data => dcfeb2_data,
      dcfeb3_dv   => dcfeb3_dv,
      dcfeb3_data => dcfeb3_data,
      dcfeb4_dv   => dcfeb4_dv,
      dcfeb4_data => dcfeb4_data,
      dcfeb5_dv   => dcfeb5_dv,
      dcfeb5_data => dcfeb5_data,
      dcfeb6_dv   => dcfeb6_dv,
      dcfeb6_data => dcfeb6_data,

      dcfeb_fifo_wren => dcfeb_fifo_wr_en,
      alct_fifo_wren  => alct_fifo_wr_en,
      tmb_fifo_wren   => tmb_fifo_wr_en,

      cafifo_l1a_match => cafifo_l1a_match_out_inner,
      cafifo_l1a_cnt   => cafifo_l1a_cnt_out,
      cafifo_l1a_dav   => cafifo_l1a_dav_out,
      cafifo_bx_cnt    => cafifo_bx_cnt_out,

      ext_dcfeb_l1a_cnt7 => ext_dcfeb_l1a_cnt7,
      dcfeb_l1a_dav7     => dcfeb_l1a_dav7,

      cafifo_wr_addr => cafifo_wr_addr,
      cafifo_rd_addr => cafifo_rd_addr
      );

  CONTROL_PM : CONTROL
    generic map(NFEB => NFEB)
    port map(
      CLK    => dduclk,                 -- CLKDDU?
      CLKCMS => clk40,
      RST    => reset,
      STATUS => status,
      L1ARST => l1arst,                 -- from CCBCODE

-- From DMB_VME
      RDFFNXT => rdffnxt,  -- from MBV (currently assigned as a signal to '0')

-- to GigaBit Link
      DOUT => ddu_data,
      DAV  => ddu_data_valid_inner,

-- to Data FIFOs
      OEFIFO_B   => data_fifo_oe,
      RENFIFO_B  => data_fifo_re,
      OEFFMON_B  => mon_fifo_oe,
      RENFFMON_B => mon_fifo_re,

-- from Data FIFOs
      FFOR_B      => fifo_empty_b,
      DATAIN      => fifo_out(15 downto 0),
--      DATAIN_LAST => LOGICL,  -- Logic 1 when the last DW (800?) is received ????
      DATAIN_LAST => fifo_eof,

-- From CONFREGS
      KILLINPUT => kill,

-- From JTAGCOM
      SETLOOPBACK => setloopback,       -- from JTAGCOM
      JOEF        => joef,              -- from LOADFIFO

-- From CONFREG and GA
      DAQMBID  => daqmbid,
      LOOPBACK => open,
      OEOVLP   => open,

-- FROM SW1
      GIGAEN => LOGICH,

-- TO CAFIFO
      FIFO_POP => cafifo_pop,

-- TO PCFIFO
      EOF => eof,

-- FROM CAFIFO
      cafifo_l1a_dav   => cafifo_l1a_dav_out,
      cafifo_l1a_match => cafifo_l1a_match_out_inner,
      cafifo_l1a_cnt   => cafifo_l1a_cnt_out,
      cafifo_bx_cnt    => cafifo_bx_cnt_out
      );

  PCFIFO_PM : pcfifo
    generic map (NFIFO => NFIFO)

    port map(

      clk_in  => dduclk,
      clk_out => pcclk,
      rst     => reset,

      tx_ack => gl_pc_tx_ack,
      --tx_ack => logich,

      dv_in   => ddu_data_valid_inner,
      ld_in   => eof,
      data_in => ddu_data,

      dv_out   => pc_data_valid,
      data_out => pc_data
      );



  
  mbc_instr <= instr;

  leds <= crateid;

  JTAG_PM : BGB_BSCAN_emulator
    port map (

      IR => mbc_jtag_ir,

      CAPTURE1 => capture1,
      DRCK1    => drck1,
      RESET1   => reset1,
      SEL1     => sel1,
      SHIFT1   => shift1,
      UPDATE1  => update1,
      RUNTEST1 => open,
      TDO1     => tdo1,

      CAPTURE2 => capture2,
      DRCK2    => drck2,
      RESET2   => reset2,
      SEL2     => sel2,
      SHIFT2   => shift2,
      UPDATE2  => update2,
      RUNTEST2 => open,
      TDO2     => tdo2,

      TDO3 => '0',
      TDO4 => '0',

      TCK  => tck,
      TDI  => tdi,
      TMS  => tms,
      TDO  => tdo,
      TRST => reset
      );

  INSTR_DECODER_PM : INSTRGDC
    port map (
      BTDI   => tdi,                    -- TDI from BSCAN_VIRTEX
      DRCK   => drck1,                  -- Signals are from BSCAN_VIRTEX
      SEL1   => sel1,
      SHIFT  => shift1,
      UPDATE => update1,
      D0     => tdo1,
      FSEL   => mbc_instr_sel,
      F      => instr);

  CONFLOGIC_PM : CONFLOGIC              -- Used to be discrete logic in JTAGCOM
    generic map (NFEB => NFEB)
    port map(
      CLKCMS => clk40,
      RST    => reset,

      INSTR  => instr,
      CCBINJ => ccbinj,
      CCBPLS => ccbpls,
      CCBPED => ccbped,
      SELRAN => selran,

      CAL_TRGSEL => jtag_cal_trgsel,
      ENACFEB    => enacfeb,
      CAL_MODE   => jtag_cal_mode
      );


  --CALTRIGCON_PM : CALTRIGCON
  --  generic map (NFEB => NFEB)
  --  port map (
  --    CLKIN  => clk40,
  --    CLKSYN => plsinjen,
  --    RST    => reset,

  --    DIN   => tdi,
  --    DRCK  => drck2,
  --    SEL2  => sel2,
  --    SHIFT => shift2,
  --    FLOAD => instr(6),
  --    FCYC  => instr(7),
  --    FCYCM => instr(8),

  --    CCBPED => ccbped,

  --    LCTOUT  => prelct,
  --    GTRGOUT => pregtrg
  --    );

  prelct  <= '0';
  pregtrg <= '0';

  --RANDOMTRG_PM : RANDOMTRG
  --  generic map (NFEB => NFEB)
  --  port map(
  --    CLK => clk40,
  --    RST => reset,

  --    DIN    => tdi,
  --    DRCK   => drck2,
  --    SEL2   => sel2,
  --    SHIFT  => shift2,
  --    UPDATE => update2,

  --    FLOAD   => instr(19),
  --    FTSTART => instr(20),
  --    FBURST  => instr(22),

  --    ENL1RLS => sw4_enl1rls,

  --    PREL1RLS => ccb_l1rls,
  --    SELRAN   => selran,
  --    GTRGOUT  => rndmgtrg,
  --    LCTOUT   => rndmlct,
  --    PULSE    => rndmpls
  --    );

  -- Assigned here until RANDOMTRG actually does something
  ccb_l1rls <= '0';
  selran    <= '0';
  rndmgtrg  <= '0';
  rndmlct   <= (others => '0');
  rndmpls   <= '0';


  LOADCFEB_PM : LOADCFEB
    generic map (NFEB => NFEB)
    port map (
      CLK => clk40,
      RST => reset,

      BTDI   => tdi,
      DRCK   => drck2,
      SEL2   => sel2,
      SHIFT  => shift2,
      UPDATE => update2,

      TDO => open,

      FLOAD => instr(9),

      CALLCT_1 => callct_1,
      RNDMLCT  => rndmlct,

      LCTFEB => cal_lct,
      CFEB   => loadcfeb_cfeb           -- It does not go anywhere, AFAWK
      );


  --TRGSEL_PM : TRGSEL
  --  port map(
  --    RST => reset,

  --    BTDI   => tdi,
  --    DRCK   => drck2,
  --    SEL2   => sel2,
  --    SHIFT  => shift2,
  --    UPDATE => update2,

  --    FLOAD => instr(37),

  --    TDO    => open,
  --    JTRGEN => jtag_trgen
  --    );

  jtag_trgen <= (others => '0');

  daqmbid(11 downto 5) <= crateid(6 downto 0);
  daqmbid(4 downto 0)  <= ga(4 downto 0);  -- to be inverted - why ga(0) is not included?


  gtx0_data       <= ddu_data;
  gtx0_data_valid <= ddu_data_valid_inner;
  gtx1_data       <= pc_data;
  gtx1_data_valid <= pc_data_valid;

  ddu_data_valid <= ddu_data_valid_inner;

  cafifo_l1a_match_in  <= cafifo_l1a_match_in_inner(NFEB+2 downto 1);
  cafifo_l1a_match_out <= cafifo_l1a_match_out_inner;
  cafifo_l1a_dav       <= cafifo_l1a_dav_out;
  cafifo_l1a_cnt       <= cafifo_l1a_cnt_out;
  cafifo_bx_cnt        <= cafifo_bx_cnt_out;


  CCBCODE_PM : CCBCODE
    port map(
      CCB_CMD    => ccb_cmd,
      CCB_CMD_S  => ccb_cmd_s,
      CCB_DATA   => ccb_data,
      CCB_DATA_S => ccb_data_s,
      CMSCLK     => clk40,
      CCB_BXRST  => ccb_bxrst,
      CCB_BX0    => ccb_bx0,
      CCB_L1ARST => ccb_l1arst,
      CCB_CLKEN  => ccb_clken,
      BX0        => bx0,
      BXRST      => bxrst,
      L1ARST     => l1arst,
      CLKEN      => clken,
      BC0        => bc0,
      L1ASRST    => l1asrst,
      TTCCAL     => ttccal);

-- generate CCBPED
  ccbped <= '1' when (ccb_cal(2) = '0' or ttccal(2) = '1') else '0';

-- generate CCBINJIN
  ccbinjin <= '1' when (ccb_cal(1) = '0' or ttccal(1) = '1') else '0';

-- generate CCBPLSIN
  ccbplsin <= '1' when (ccb_cal(0) = '0' or ttccal(0) = '1') else '0';

-- generate CCBINJ
  FD(ccbinjin, clk40, ccbinjin_1);
  FD(ccbinjin_1, clk40, ccbinjin_2);
  ccbinjin_3 <= '1' when (plsinjen = '1' and (ccbinjin_1 = '1' or ccbinjin_2 = '1')) else '0';
  FD(ccbinjin_3, clk40, ccbinj);

-- generate CCBPLS
  FD(ccbplsin, clk40, ccbplsin_1);
  FD(ccbplsin_1, clk40, ccbplsin_2);
  ccbplsin_3 <= '1' when (plsinjen = '1' and (ccbplsin_1 = '1' or ccbplsin_2 = '1')) else '0';
  FD(ccbplsin_3, clk40, ccbpls);

-- generate PLSINJEN (CLKSYN inside CALTRIGCON inside of JTAGCOM)
  FDC(LOGICH, reset, plsinjen_rst, plsinjen_1);
  FD(plsinjen_1, clk40, plsinjen_rst);
  FDC(plsinjen_inv, clk40, plsinjen_rst, plsinjen_inner);
  plsinjen     <= plsinjen_inner;
  plsinjen_inv <= not plsinjen_inner;

  CALIBTRG_PM : CALIBTRG
    port map (
      CMSCLK      => clk40,
      CLK80       => clk80,
      RST         => reset,
      PLSINJEN    => plsinjen,
      --   CCBINJ => ccbinj,
      --   CCBPLS => ccbpls,
      CCBINJ      => test_ccbinj,
      CCBPLS      => test_ccbpls,
      FINJ        => instr(3),
      FPLS        => instr(4),
      FPED        => instr(5),
      PRELCT      => prelct,            -- generated by CALTRIGCON
      PREGTRG     => pregtrg,           -- generated by CALTRIGCON
      INJ_DLY     => inj_dly,
      EXT_DLY     => ext_dly,
      CALLCT_DLY  => callct_dly,
      LCT_L1A_DLY => lct_l1a_dly,
      RNDMPLS     => rndmpls,           -- generated by RANDOMTRG
      RNDMGTRG    => rndmgtrg,          -- generated by RANDOMTRG
      PEDESTAL    => pedestal,
      CAL_GTRG    => cal_gtrg,
--    CALLCT_1 : out std_logic;
      CALLCT      => callct_1,
      INJBACK     => inject,
      PLSBACK     => pulse,
-- SCPSYN AND SCOPE have not been implemented
-- and we do not intend to implement them (we think)
--    SCPSYN : out std_logic; 
--    SYNCIF : out std_logic;
      LCTRQST     => prelctrqst,
      INJPLS      => injplsmon);

--dl_gtrig <= cal_gtrg; 
  dcfeb_injpulse <= inject;
  dcfeb_extpulse <= pulse;

  LOADFIFO_PM : LOADFIFO
    generic map (NFEB => NFEB)
    port map(
      FENF   => instr(12),              -- INSTR(12)
      BTDI   => tdi,
      DRCK   => drck2,
      SEL2   => sel2,
      SHIFT  => shift2,
      UPDATE => update2,
      RST    => instr(1),   -- JRST (or RESET or FPGARST or L1ASRST)
      JOEF   => joef,
      TDO    => tdo_fifo);


  TDO2 <= 'L';

-- from ODMB_CTRL_EMPTY

  ccb_rsvi <= "000";

  lctrqst   <= "00";
  rsvtd_out <= "000";

end ODMB_CTRL_arch;
