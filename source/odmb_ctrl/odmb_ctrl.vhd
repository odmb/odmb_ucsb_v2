-- ODMB_CTRL: Controls triggers, calibration, and the data path

library ieee;
library work;
use work.Latches_Flipflops.all;
use work.ucsb_types.all;
use ieee.std_logic_1164.all;

entity ODMB_CTRL is
  generic (
    NFIFO       : integer range 1 to 16 := 16;  -- Number of FIFOs in PCFIFO
    NFEB        : integer range 1 to 7  := 7;  -- Number of DCFEBS, 7 in the final design
    CAFIFO_SIZE : integer range 1 to 128 := 128  -- Number FIFO words in CAFIFO
    );  
  port (

-- Chip Scope Pro Logic Analyzer control
    CSP_FREE_AGENT_PORT_LA_CTRL  : inout std_logic_vector(35 downto 0);
    CSP_CONTROL_FSM_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);

    clk40  : in std_logic;
    clk80  : in std_logic;
    clk160 : in std_logic;
    reset  : in std_logic;

    ga : in std_logic_vector(4 downto 0);

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

    rawlct   : in std_logic_vector (NFEB downto 0);  -- rawlct(5 downto 0) - from J4
    otmb_dav : in std_logic;            -- previously lctdav1, from J4
    alct_dav : in std_logic;            -- previously lctdav2, from J4

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

-- From/To Data FIFOs

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
      control_debug : out std_logic_vector(15 downto 0);
    cafifo_debug               : out std_logic_vector(15 downto 0);
    cafifo_wr_addr             : out std_logic_vector(7 downto 0);
    cafifo_rd_addr             : out std_logic_vector(7 downto 0);

    ext_dcfeb_l1a_cnt7 : out std_logic_vector(23 downto 0);
    dcfeb_l1a_dav7     : out std_logic;
    l1acnt_rst         : in  std_logic;
    bxcnt_rst          : in  std_logic;


-- To PCFIFO
    gl_pc_tx_ack : in std_logic;
    dduclk       : in std_logic;
    pcclk        : in std_logic;
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

    dcfeb_injpulse  : out std_logic;    -- inject - to DCFEBs
    dcfeb_extpulse  : out std_logic;    -- extpulse - to DCFEBs
    dcfeb_l1a       : out std_logic;
    dcfeb_l1a_match : out std_logic_vector(NFEB downto 1);
    PEDESTAL        : in  std_logic;
    PEDESTAL_OTMB   : in  std_logic;

    test_ccbinj : in std_logic;
    test_ccbpls : in std_logic;
    test_ccbped : in std_logic;

    lct_err : out std_logic;            -- To an LED in the original design

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

end ODMB_CTRL;


architecture ODMB_CTRL_arch of ODMB_CTRL is

  component CRC_CHECKER is
    port (

      RST    : in std_logic;
      CLKCMS : in std_logic;
      CLK    : in std_logic;

      DOUT : in std_logic_vector(15 downto 0);
      DAV  : in std_logic;

      CRC_ERROR : out std_logic
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
      CAL_LCT       : in std_logic;
      CAL_L1A       : in std_logic;
      LCT_L1A_DLY   : in std_logic_vector(5 downto 0);
      OTMB_PUSH_DLY : in integer range 0 to 63;
      ALCT_PUSH_DLY : in integer range 0 to 63;
      PUSH_DLY      : in integer range 0 to 63;
      ALCT_DAV      : in std_logic;
      OTMB_DAV      : in std_logic;

      CAL_MODE      : in std_logic;
      KILL          : in std_logic_vector(NFEB+2 downto 1);
      PEDESTAL      : in std_logic;
      PEDESTAL_OTMB : in std_logic;

      ALCT_DAV_SYNC_OUT : out std_logic;
      OTMB_DAV_SYNC_OUT : out std_logic;

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

  component CONTROL_FSM is
    generic (
      NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
      );  
    port (
-- Chip Scope Pro Logic Analyzer control
      CSP_CONTROL_FSM_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);
      RST                          : in    std_logic;
      CLKCMS                       : in    std_logic;
      CLK                          : in    std_logic;
      STATUS                       : in    std_logic_vector(47 downto 0);
      L1ARST                       : in    std_logic;

-- From DMB_VME
      RDFFNXT : in std_logic;

-- to GigaBit Link
      DOUT : out std_logic_vector(15 downto 0);
      DAV  : out std_logic;

-- to FIFOs
      OEFIFO_B  : out std_logic_vector(NFEB+2 downto 1);
      RENFIFO_B : out std_logic_vector(NFEB+2 downto 1);

-- from FIFOs
      FIFO_HALF_FULL : in std_logic_vector(NFEB+2 downto 1);
      FFOR_B         : in std_logic_vector(NFEB+2 downto 1);
      DATAIN         : in std_logic_vector(15 downto 0);
      DATAIN_LAST    : in std_logic;

-- From LOADFIFO
      JOEF : in std_logic_vector(NFEB+2 downto 1);

-- to ???
      DAQMBID : in std_logic_vector(11 downto 0);  -- From CRATEID in SETFEBDLY, and GA

-- FROM SW1
      GIGAEN : in std_logic;

-- TO CAFIFO
      FIFO_POP : out std_logic;

-- TO PCFIFO
      EOF : out std_logic;

-- DEBUG
    control_debug : out std_logic_vector(15 downto 0);
    
-- FROM CAFIFO
      cafifo_l1a_dav   : in std_logic_vector(NFEB+2 downto 1);
      cafifo_l1a_match : in std_logic_vector(NFEB+2 downto 1);
      cafifo_l1a_cnt   : in std_logic_vector(23 downto 0);
      cafifo_bx_cnt    : in std_logic_vector(11 downto 0);
      cafifo_lost_pckt : in std_logic_vector(NFEB+2 downto 1);
      cafifo_lone      : in std_logic
      );
  end component;

  component cafifo is
    generic (
      NFEB        : integer range 1 to 7  := 7;  -- Number of DCFEBS, 7 in the final design
      CAFIFO_SIZE : integer range 1 to 128 := 128  -- Number of CAFIFO words
      );  
    port(

      CSP_FREE_AGENT_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);
      clk                         : in    std_logic;
      dcfebclk                    : in    std_logic;
      rst                         : in    std_logic;
      l1acnt_rst                  : in    std_logic;
      bxcnt_rst                   : in    std_logic;

      BC0   : in std_logic;
      BXRST : in std_logic;

      l1a          : in std_logic;
      l1a_match_in : in std_logic_vector(NFEB+2 downto 1);

      pop : in std_logic;

      eof_data    : in std_logic_vector(NFEB+2 downto 1);
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

      cafifo_l1a_match : out std_logic_vector(NFEB+2 downto 1);
      cafifo_l1a_cnt   : out std_logic_vector(23 downto 0);
      cafifo_l1a_dav   : out std_logic_vector(NFEB+2 downto 1);
      cafifo_bx_cnt    : out std_logic_vector(11 downto 0);
      cafifo_lost_pckt : out std_logic_vector(NFEB+2 downto 1);
      cafifo_lone      : out std_logic;

      ext_dcfeb_l1a_cnt7 : out std_logic_vector(23 downto 0);
      dcfeb_l1a_dav7     : out std_logic;

      cafifo_prev_next_l1a_match : out std_logic_vector(15 downto 0);
      cafifo_prev_next_l1a       : out std_logic_vector(15 downto 0);
      cafifo_debug               : out std_logic_vector(15 downto 0);
      cafifo_wr_addr             : out std_logic_vector(7 downto 0);
      cafifo_rd_addr             : out std_logic_vector(7 downto 0)
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
  signal cafifo_lost_pckt_out       : std_logic_vector(NFEB+2 downto 1);
  signal cafifo_lone                : std_logic;

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
  signal CAL_LCT       : std_logic;
  signal loadcfeb_cfeb : std_logic_vector(NFEB downto 1);

-- TRGSEL outputs
  signal jtag_trgen : std_logic_vector(3 downto 0);

-- CCBCODE outputs

  signal bx0                : std_logic;
  signal bxrst, ccb_bxrst_b : std_logic;
  signal l1arst             : std_logic;
  signal clken              : std_logic;
  signal bc0                : std_logic;
  signal l1asrst            : std_logic;
  signal ttccal             : std_logic_vector(2 downto 0);


-- LOADFIFO outputs

  signal joef : std_logic_vector(NFEB+2 downto 1);

  signal LOGICL : std_logic := '0';
  signal LOGICH : std_logic := '1';

-- CALIBTRG outputs

  signal cal_pedestal : std_logic;
  signal cal_gtrg     : std_logic;
  signal inject       : std_logic;
  signal pulse        : std_logic;
  signal prelctrqst   : std_logic;
  signal injplsmon    : std_logic;

-------------------------------------------------------------------------------

  signal status : std_logic_vector(47 downto 0) := (others => '0');

  signal rdffnxt : std_logic := '0';    -- from MBV
  signal daqmbid : std_logic_vector(11 downto 0);

begin

  CALIBTRG_PM : CALIBTRG
    port map (
      CMSCLK      => clk40,
      CLK80       => clk80,
      RST         => reset,
      PLSINJEN    => plsinjen,
      CCBINJ      => ccbinj,
      CCBPLS      => ccbpls,
      FINJ        => test_ccbinj,
      FPLS        => test_ccbpls,
      FPED        => test_ccbped,
--      CCBINJ      => test_ccbinj,
--      CCBPLS      => test_ccbpls,
--      FINJ        => instr(3),
--      FPLS        => instr(4),
--      FPED        => instr(5),
      PRELCT      => prelct,            -- generated by CALTRIGCON
      PREGTRG     => pregtrg,           -- generated by CALTRIGCON
      INJ_DLY     => inj_dly,
      EXT_DLY     => ext_dly,
      CALLCT_DLY  => callct_dly,
      LCT_L1A_DLY => lct_l1a_dly,
      RNDMPLS     => rndmpls,           -- generated by RANDOMTRG
      RNDMGTRG    => rndmgtrg,          -- generated by RANDOMTRG
      PEDESTAL    => cal_pedestal,
      CAL_GTRG    => cal_gtrg,
      CALLCT      => cal_lct,
      INJBACK     => inject,
      PLSBACK     => pulse,
      LCTRQST     => prelctrqst,
      INJPLS      => injplsmon);

  TRGCNTRL_PM : TRGCNTRL
    generic map (NFEB => NFEB)
    port map (
      CLK           => clk40,
      RAW_L1A       => ccb_l1acc,
      RAW_LCT       => rawlct,
      CAL_LCT       => cal_lct,
      CAL_L1A       => cal_gtrg,
      LCT_L1A_DLY   => lct_l1a_dly,
      OTMB_PUSH_DLY => otmb_push_dly,
      ALCT_PUSH_DLY => alct_push_dly,
      PUSH_DLY      => push_dly,
      ALCT_DAV      => alct_dav,
      OTMB_DAV      => otmb_dav,

      CAL_MODE      => cal_mode,
      KILL          => kill(NFEB+2 downto 1),
      PEDESTAL      => pedestal,
      PEDESTAL_OTMB => pedestal_otmb,

      ALCT_DAV_SYNC_OUT => ALCT_DAV_SYNC_OUT,
      OTMB_DAV_SYNC_OUT => OTMB_DAV_SYNC_OUT,

      DCFEB_L1A       => dcfeb_l1a,
      DCFEB_L1A_MATCH => dcfeb_l1a_match,
      FIFO_PUSH       => cafifo_push,
      FIFO_L1A_MATCH  => cafifo_l1a_match_in_inner,
      LCT_ERR         => lct_err
      );

  cafifo_l1a <= cafifo_push;

  CAFIFO_PM : cafifo
    generic map (NFEB => NFEB, CAFIFO_SIZE => CAFIFO_SIZE)
    port map(
      CSP_FREE_AGENT_PORT_LA_CTRL => CSP_FREE_AGENT_PORT_LA_CTRL,
      clk                         => clk40,
      dduclk                    => dduclk,
      rst                         => l1acnt_rst,
      l1acnt_rst                  => l1acnt_rst,
      bxcnt_rst                   => bxcnt_rst,

      BC0   => bc0,
      BXRST => ccb_bxrst_b,

      pop          => cafifo_pop,
      l1a          => cafifo_push,
      l1a_match_in => cafifo_l1a_match_in_inner(NFEB+2 downto 1),

      eof_data => eof_data,


      alct_dv     => alct_dv,
      otmb_dv     => otmb_dv,
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

      cafifo_l1a_match => cafifo_l1a_match_out_inner,
      cafifo_l1a_cnt   => cafifo_l1a_cnt_out,
      cafifo_l1a_dav   => cafifo_l1a_dav_out,
      cafifo_bx_cnt    => cafifo_bx_cnt_out,
      cafifo_lost_pckt => cafifo_lost_pckt_out,
      cafifo_lone      => cafifo_lone,

      ext_dcfeb_l1a_cnt7 => ext_dcfeb_l1a_cnt7,
      dcfeb_l1a_dav7     => dcfeb_l1a_dav7,

      cafifo_prev_next_l1a_match => cafifo_prev_next_l1a_match,
      cafifo_prev_next_l1a       => cafifo_prev_next_l1a,
      cafifo_debug               => cafifo_debug,
      cafifo_wr_addr             => cafifo_wr_addr,
      cafifo_rd_addr             => cafifo_rd_addr
      );

  CONTROL_FSM_PM : CONTROL_FSM
    generic map(NFEB => NFEB)
    port map(
      CSP_CONTROL_FSM_PORT_LA_CTRL => CSP_CONTROL_FSM_PORT_LA_CTRL,
      CLK                          => dduclk, 
      CLKCMS                       => clk40,
      RST                          => l1acnt_rst,
      STATUS                       => status,
      L1ARST                       => l1arst,  -- from CCBCODE

-- From DMB_VME
      RDFFNXT => rdffnxt,  -- from MBV (currently assigned as a signal to '0')

-- to GigaBit Link
      DOUT => ddu_data,
      DAV  => ddu_data_valid_inner,

-- to Data FIFOs
      OEFIFO_B  => data_fifo_oe,
      RENFIFO_B => data_fifo_re,

-- from Data FIFOs
      FIFO_HALF_FULL => fifo_half_full,
      FFOR_B         => fifo_empty_b,
      DATAIN         => fifo_out(15 downto 0),
      DATAIN_LAST    => fifo_eof,

-- From JTAGCOM
      JOEF => joef,                     -- from LOADFIFO

-- From CONFREG and GA
      DAQMBID => daqmbid,

-- FROM SW1
      GIGAEN => LOGICH,

-- TO CAFIFO
      FIFO_POP => cafifo_pop,

-- TO PCFIFO
      EOF => eof,

-- DEBUG
    control_debug => control_debug,
      
-- FROM CAFIFO
      cafifo_l1a_dav   => cafifo_l1a_dav_out,
      cafifo_l1a_match => cafifo_l1a_match_out_inner,
      cafifo_l1a_cnt   => cafifo_l1a_cnt_out,
      cafifo_bx_cnt    => cafifo_bx_cnt_out,
      cafifo_lost_pckt => cafifo_lost_pckt_out,
      cafifo_lone      => cafifo_lone
      );

  PCFIFO_PM : pcfifo
    generic map (NFIFO => NFIFO)

    port map(

      clk_in  => dduclk,
      clk_out => pcclk,
      rst     => l1acnt_rst,

      tx_ack => gl_pc_tx_ack,
      --tx_ack => logich,

      dv_in   => ddu_data_valid_inner,
      ld_in   => eof,
      data_in => ddu_data,

      dv_out   => pc_data_valid,
      data_out => pc_data
      );

  DDUEOF_PULSE : PULSE2SLOW port map(ddu_eof, clk40, dduclk, RESET, eof);
  --ddu_eof <= eof;  -- This counts the number of packets sent to the DDU

  CRC_CHECKER_PM : CRC_CHECKER
    port map (
      RST    => reset,
      CLK    => dduclk,
      CLKCMS => clk40,

      DOUT => ddu_data,
      DAV  => ddu_data_valid_inner,

      CRC_ERROR => open
      );


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

  daqmbid(11 downto 4) <= crateid;
  daqmbid(3 downto 0)  <= not ga(4 downto 1);  -- GA0 not included so that this is ODMB counter


  gtx0_data       <= ddu_data;
  gtx0_data_valid <= ddu_data_valid_inner;
  gtx1_data       <= pc_data;
  gtx1_data_valid <= pc_data_valid;

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
      CCB_BXRST  => ccb_bxrst_b,
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

  dcfeb_injpulse <= inject;
  dcfeb_extpulse <= pulse;

-- from ODMB_CTRL_EMPTY

  ccb_rsvi    <= "000";
  ccb_bxrst_b <= not ccb_bxrst;

end ODMB_CTRL_arch;
