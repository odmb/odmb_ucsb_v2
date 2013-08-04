-- ODMB_VME: Handles the VME protocol and selects VME device

-- Device 0 => TESTCTRL
-- Device 1 => CFEBJTAG
-- Device 2 => ODMBJTAG
-- Device 3 => VMEMON
-- Device 4 => VMECONFREGS
-- Device 5 => TESTFIFOS
-- Device 8 => LVDBMON

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity ODMB_VME is
  generic (
    NFEB : integer range 1 to 7 := 7    -- Number of DCFEBS
    );  
  port (

-- VME signals

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

    clk80  : in std_logic;              -- For testctrl (80MHz)
    clk    : in std_logic;              -- NEW (fastclk -> 40MHz)
    clk_s1 : in std_logic;              -- NEW (midclk -> fastclk/4 -> 10MHz)
    clk_s2 : in std_logic;              -- NEW (slowclk -> midclk/4 -> 2.5MHz)
    clk_s3 : in std_logic;  -- NEW (slowclk2 -> midclk/8 -> 12.5MHz)

-- Reset

    rst       : in  std_logic;          -- iglobalrst
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
    OPT_RESET_PULSE : out std_logic;
    FW_RESET        : out std_logic;
    RESYNC          : out std_logic;
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
    KILL          : out std_logic_vector(NFEB+2 downto 1);
    CRATEID       : out std_logic_vector(6 downto 0);

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
    TFF_RDEN    : out std_logic_vector(NFEB downto 1)


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
    port (
      SLOWCLK : in std_logic;
      CLK40   : in std_logic;
      RST     : in std_logic;

      DEVICE  : in std_logic;
      STROBE  : in std_logic;
      COMMAND : in std_logic_vector(9 downto 0);

      INDATA  : in  std_logic_vector(15 downto 0);
      OUTDATA : out std_logic_vector(15 downto 0);

      DTACK : out std_logic;

      OPT_RESET_PULSE : out std_logic;
      FW_RESET        : out std_logic;
      RESYNC          : out std_logic;
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


  component VMECONFREGS is
    port (
      SLOWCLK : in std_logic;
      RST     : in std_logic;

      DEVICE  : in std_logic;
      STROBE  : in std_logic;
      COMMAND : in std_logic_vector(9 downto 0);

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

      KILL    : out std_logic_vector(NFEB+2 downto 1);
      CRATEID : out std_logic_vector(6 downto 0)
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

  component LVDBMON is
    port (

      SLOWCLK : in std_logic;
      RST     : in std_logic;

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
      device8_outdata : in  std_logic_vector(15 downto 0);
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

  signal cmd_adrs : std_logic_vector(15 downto 0);

  signal outdata_vmemon      : std_logic_vector(15 downto 0);
  signal outdata_vmeconfregs : std_logic_vector(15 downto 0);
  signal outdata_testfifos   : std_logic_vector(15 downto 0);

  signal outdata_testctrl : std_logic_vector(15 downto 0);

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

      DTACK => vme_dtack_b,

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

      DTACK => vme_dtack_b,

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

      DTACK => vme_dtack_b,

      INITJTAGS => '0',                 -- to be defined
      TCK       => odmb_jtag_tck,
      TDI       => odmb_jtag_tdi,
      TMS       => odmb_jtag_tms,
      ODMBTDO   => odmb_jtag_tdo,

      JTAGSEL => odmb_jtag_sel,

      LED => led_odmbjtag
      );


  DEV3_VMEMON : VMEMON
    port map (
      SLOWCLK => clk_s2,
      CLK40   => clk,
      RST     => rst,

      DEVICE  => device(3),
      STROBE  => strobe,
      COMMAND => cmd,

      INDATA  => vme_data_in,
      OUTDATA => outdata_vmemon,

      DTACK => vme_dtack_b,

      OPT_RESET_PULSE => opt_reset_pulse,
      FW_RESET        => fw_reset,
      RESYNC          => resync,
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
      RST     => RST,

      DEVICE  => DEVICE(4),
      STROBE  => STROBE,
      COMMAND => CMD,

      INDATA  => VME_DATA_IN,
      OUTDATA => OUTDATA_VMECONFREGS,

      DTACK         => VME_DTACK_B,
      ALCT_PUSH_DLY => ALCT_PUSH_DLY,
      OTMB_PUSH_DLY => OTMB_PUSH_DLY,
      PUSH_DLY      => PUSH_DLY,
      LCT_L1A_DLY   => LCT_L1A_DLY,

      INJ_DLY    => INJ_DLY,
      EXT_DLY    => EXT_DLY,
      CALLCT_DLY => CALLCT_DLY,

      KILL    => KILL,
      CRATEID => CRATEID
      );

  DEV5_TESTFIFOS : TESTFIFOS
    port map (
      SLOWCLK => CLK_S2,
      RST     => RST,
      CLK40   => CLK,

      DEVICE  => DEVICE(5),
      STROBE  => STROBE,
      COMMAND => CMD,

      INDATA  => VME_DATA_IN,
      OUTDATA => OUTDATA_TESTFIFOS,

      DTACK => VME_DTACK_B,

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

  DEV8_LVDBMON : LVDBMON
    port map(
      SLOWCLK => clk_s2,
      RST     => rst,

      DEVICE  => device(8),
      STROBE  => strobe,
      COMMAND => cmd,
      WRITER  => vme_write_b,

      INDATA  => vme_data_in,
      OUTDATA => outdata_lvdbmon,

      DTACK => vme_dtack_b,

      LVADCEN => lvmb_csb,
      ADCCLK  => lvmb_sclk,
      ADCDATA => lvmb_sdin,
      ADCIN   => lvmb_sdout,

      LVTURNON   => lvmb_pon,
      R_LVTURNON => r_lvmb_pon,
      LOADON     => pon_load,

      DIAGLVDB => diagout_lvdbmon

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

      DTACK => vme_dtack_b,

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
      device8_outdata => outdata_lvdbmon,
      outdata         => vme_data_out
      );

  PULSE_LED : PULSE_EDGE port map(led_pulse, open, clk_s3, rst, 200000, strobe);

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


end ODMB_VME_architecture;

