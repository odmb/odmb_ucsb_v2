library ieee;
library work;
library hdlmacro;
use hdlmacro.hdlmacro.all;
library UNISIM;
use UNISIM.vcomponents.all;
use ieee.std_logic_1164.all;
use work.ucsb_types.all;

entity ODMBJTAG is

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
    ODMB_ID : in  std_logic_vector(15 downto 0);

    LED : out std_logic
    );

end ODMBJTAG;

architecture ODMBJTAG_Arch of ODMBJTAG is

  --Declaring internal signals

  constant LOGICH : std_logic := '1';
  constant LOGICL : std_logic := '0';

  signal CMDDEV                               : std_logic_vector(15 downto 0);
  signal DATASHFT, INSTSHFT, READTDO, RSTJTAG : std_logic;

  signal JTAGSEL_INNER : std_logic;

  signal D1_LOAD, D2_LOAD, CLR_LOAD, Q_LOAD, LOAD : std_logic;

  signal Q_BUSY, D_BUSY, CLR_BUSY, BUSY, BUSYP1 : std_logic;

  signal C_IHEADEN, CLR_IHEADEN, IHEADEN                                  : std_logic;
  signal SHIHEAD                                                          : std_logic;
  signal R_DONEIHEAD, Q_DONEIHEAD, CEO_DONEIHEAD, TC_DONEIHEAD, DONEIHEAD : std_logic;
  signal QV_DONEIHEAD                                                     : std_logic_vector(3 downto 0);
  signal CE_SHIHEAD_TMS, Q1_SHIHEAD_TMS, Q2_SHIHEAD_TMS                   : std_logic;
  signal Q3_SHIHEAD_TMS, Q4_SHIHEAD_TMS, Q5_SHIHEAD_TMS                   : std_logic;

  signal C_DHEADEN, CLR_DHEADEN, DHEADEN                                  : std_logic;
  signal SHDHEAD                                                          : std_logic;
  signal R_DONEDHEAD, Q_DONEDHEAD, CEO_DONEDHEAD, TC_DONEDHEAD, DONEDHEAD : std_logic;
  signal QV_DONEDHEAD                                                     : std_logic_vector(3 downto 0);
  signal CE_SHDHEAD_TMS, Q1_SHDHEAD_TMS, Q2_SHDHEAD_TMS                   : std_logic;
  signal Q3_SHDHEAD_TMS, Q4_SHDHEAD_TMS, Q5_SHDHEAD_TMS                   : std_logic;

  signal SHDATA, SHDATAX : std_logic;

  signal DV_DONEDATA, QV_DONEDATA                                          : std_logic_vector(3 downto 0);
  signal CE_DONEDATA, CLR_DONEDATA, UP_DONEDATA, CEO_DONEDATA, TC_DONEDATA : std_logic;
  signal D_DONEDATA                                                        : std_logic;
  signal DONEDATA                                                          : std_logic_vector(1 downto 0);

  signal CE_TAILEN, CLR_TAILEN, TAILEN                     : std_logic;
  signal SHTAIL                                            : std_logic;
  signal CE_DONETAIL, CLR_DONETAIL, Q_DONETAIL, C_DONETAIL : std_logic;
  signal DONETAIL                                          : std_logic;
  signal CE_SHTAIL_TMS, Q1_SHTAIL_TMS, Q2_SHTAIL_TMS       : std_logic;

  signal CE_ENABLE, D_ENABLE, ENABLE : std_logic;

  signal D1_RESETJTAG, Q1_RESETJTAG, Q2_RESETJTAG, Q3_RESETJTAG, CLR_RESETJTAG, RESETJTAG : std_logic;
  signal OKRST                                                                            : std_logic;

  signal CLR_RESETDONE, CEO_RESETDONE, TC_RESETDONE : std_logic;
  signal QV_RESETDONE                               : std_logic_vector(3 downto 0);
  signal RESETDONE                                  : std_logic;

  signal CE_RESETJTAG_TMS, Q1_RESETJTAG_TMS, Q2_RESETJTAG_TMS                   : std_logic;
  signal Q3_RESETJTAG_TMS, Q4_RESETJTAG_TMS, Q5_RESETJTAG_TMS, Q6_RESETJTAG_TMS : std_logic;

  signal CE_TDI : std_logic;
  signal QV_TDI : std_logic_vector(15 downto 0);

  signal RDTDODK : std_logic;

  signal SHFT_EN   : std_logic;
  signal Q_OUTDATA : std_logic_vector(15 downto 0);

  signal D_DTACK, CE_DTACK, CLR_DTACK, Q1_DTACK, Q2_DTACK, Q3_DTACK, Q4_DTACK : std_logic;
  signal dd_dtack_pol, d_dtack_pol, q_dtack_pol                               : std_logic := '0';

  signal default_low, default_high                : std_logic := '1';
  signal polarity_rst, polarity_pre, w_polarity   : std_logic;
  signal rst_b, rst_pulse, rst_pulse_b, pol_pulse : std_logic;
begin

-- Decode instruction
  CMDDEV <= "000" & DEVICE & COMMAND & "00";

  DATASHFT <= '1' when (DEVICE = '1' and CMDDEV(7 downto 4) = x"0")  else '0';
  INSTSHFT <= '1' when (DEVICE = '1' and CMDDEV(7 downto 0) = x"1C") else '0';
  READTDO  <= '1' when (DEVICE = '1' and CMDDEV(7 downto 0) = x"14") else '0';
  RSTJTAG  <= '1' when (DEVICE = '1' and CMDDEV(7 downto 0) = x"18") else '0';

  w_polarity <= '1' when (cmddev = x"1020" and WRITER = '0' and STROBE = '1') else '0';

  -- Setting polarity of JTAGSEL: V2 default low, V3 default high
  rst_b        <= not RST;
  PULSERST    : PULSE_EDGE port map(rst_pulse, open, SLOWCLK, '0', 18, rst_b);
  rst_pulse_b  <= not rst_pulse;
  PULSEPOL    : PULSE_EDGE port map(pol_pulse, open, SLOWCLK, '0', 1, rst_pulse_b);
  polarity_rst <= '0'         when ODMB_ID(15 downto 12) /= x"3" else pol_pulse;
  polarity_pre <= pol_pulse when ODMB_ID(15 downto 12) /= x"3" else '0';
  FD_POLARITY : FDCP port map(default_low, w_polarity, polarity_rst, default_high, polarity_pre);
  default_high <= not default_low;

-- DTACK polarity
  dd_dtack_pol <= STROBE and DEVICE;
  FD_D_DTACK_POL : FDC port map(d_dtack_pol, dd_dtack_pol, q_dtack_pol, '1');
  FD_Q_DTACK_POL : FD port map(q_dtack_pol, SLOWCLK, d_dtack_pol);

  JTAGSEL_INNER <= DEVICE and STROBE when default_low = '1' else
                   not (DEVICE and STROBE);

-- Generate LOAD
  D1_LOAD  <= DATASHFT or INSTSHFT;
  CLR_LOAD <= LOAD or RST;
  FD_Q_LOAD : FDC port map (Q_LOAD, STROBE, CLR_LOAD, D1_LOAD);
  D2_LOAD  <= '1' when (Q_LOAD = '1' and BUSY = '0') else '0';
  FD_LOAD   : FDC port map (LOAD, SLOWCLK, RST, D2_LOAD);

-- Generate BUSY and BUSYP1
  FD_Q_BUSY : FDC port map (Q_BUSY, SLOWCLK, RST, LOAD);
  CLR_BUSY <= '1' when (((DONEDATA(1) = '1') and (TAILEN = '0')) or (RST = '1') or (DONETAIL = '1')) else '0';
  D_BUSY   <= '1' when (Q_BUSY = '1' or BUSY = '1')                                                  else '0';
  FD_BUSY   : FDC port map (BUSY, SLOWCLK, CLR_BUSY, D_BUSY);
  FD_BUSYP1 : FDC port map (BUSYP1, SLOWCLK, RST, BUSY);

-- Generate IHEADEN
-- C_IHEADEN <= '1' when (STROBE='1' and BUSY='0') else '0';
  C_IHEADEN   <= '1' when (STROBE = '1')                 else '0';
  CLR_IHEADEN <= '1' when (RST = '1' or DONEIHEAD = '1') else '0';
  FD_IHEADEN : FDCE port map (IHEADEN, C_IHEADEN, INSTSHFT, CLR_IHEADEN, COMMAND(0));

-- Generate SHIHEAD
  SHIHEAD <= '1' when (BUSY = '1' and IHEADEN = '1') else '0';

-- Generate DONEIHEAD
  R_DONEIHEAD <= '1' when (LOAD = '1' or RST = '1' or Q_DONEIHEAD = '1') else '0';
  -- old: (SLOWCLK, SHIHEAD, R_DONEIHEAD, QV_DONEIHEAD, QV_DONEIHEAD, CEO_DONEIHEAD, TC_DONEIHEAD)
  CB_DONEIHEAD : CB4RE port map (CEO_DONEIHEAD, QV_DONEIHEAD(0), QV_DONEIHEAD(1), QV_DONEIHEAD(2), QV_DONEIHEAD(3),
                                 TC_DONEIHEAD, SLOWCLK, SHIHEAD, R_DONEIHEAD);
  DONEIHEAD <= '1' when ((QV_DONEIHEAD(1) = '1') and (QV_DONEIHEAD(3) = '1')) else '0';
  FD_DONEIHEAD : FD port map (Q_DONEIHEAD, SLOWCLK, DONEIHEAD);

-- Generate TMS when SHIHEAD=1
  CE_SHIHEAD_TMS <= '1'            when ((SHIHEAD = '1') and (ENABLE = '1')) else '0';
  FD_Q5Q1_SHIHEAD_TMS : FDCE port map (Q1_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, RST, Q5_SHIHEAD_TMS);
  FD_Q1Q2_SHIHEAD_TMS : FDCE port map (Q2_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, RST, Q1_SHIHEAD_TMS);
  FD_Q2Q3_SHIHEAD_TMS : FDPE port map (Q3_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, Q2_SHIHEAD_TMS, RST);
  FD_Q3Q4_SHIHEAD_TMS : FDPE port map (Q4_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, Q3_SHIHEAD_TMS, RST);
  FD_Q4Q5_SHIHEAD_TMS : FDCE port map (Q5_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, RST, Q4_SHIHEAD_TMS);
  TMS            <= Q5_SHIHEAD_TMS when (SHIHEAD = '1')                      else 'Z';

-- Generate DHEADEN
  C_DHEADEN   <= '1' when (STROBE = '1') else '0';
  CLR_DHEADEN <= RST or DONEDHEAD;
  FD_DHEADEN : FDCE port map (DHEADEN, C_DHEADEN, DATASHFT, CLR_DHEADEN, COMMAND(0));

-- Generate SHDHEAD
  SHDHEAD <= '1' when (BUSY = '1' and DHEADEN = '1') else '0';

-- Generate DONEDHEAD
  R_DONEDHEAD <= '1' when (LOAD = '1' or RST = '1' or Q_DONEDHEAD = '1') else '0';
--old: CB4RE(SLOWCLK, SHDHEAD, R_DONEDHEAD, QV_DONEDHEAD, QV_DONEDHEAD, CEO_DONEDHEAD, TC_DONEDHEAD);
  CB_DONEDHEAD : CB4RE port map (CEO_DONEDHEAD, QV_DONEDHEAD(0), QV_DONEDHEAD(1), QV_DONEDHEAD(2), QV_DONEDHEAD(3),
                                 TC_DONEDHEAD, SLOWCLK, SHDHEAD, R_DONEDHEAD);
  DONEDHEAD <= QV_DONEDHEAD(1) and QV_DONEDHEAD(3);
  FD_DONEDHEAD : FD port map (Q_DONEDHEAD, SLOWCLK, DONEDHEAD);

-- Generate TMS when SHDHEAD=1
  CE_SHDHEAD_TMS <= '1'            when ((SHDHEAD = '1') and (ENABLE = '1')) else '0';
  FD_Q5Q1_SHDHEAD : FDCE port map (Q1_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, RST, Q5_SHDHEAD_TMS);
  FD_Q1Q2_SHDHEAD : FDCE port map (Q2_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, RST, Q1_SHDHEAD_TMS);
  FD_Q2Q3_SHDHEAD : FDPE port map (Q3_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, Q2_SHDHEAD_TMS, RST);
  FD_Q3Q4_SHDHEAD : FDCE port map (Q4_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, RST, Q3_SHDHEAD_TMS);
  FD_Q5Q4_SHDHEAD : FDCE port map (Q5_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, RST, Q4_SHDHEAD_TMS);
  TMS            <= Q5_SHDHEAD_TMS when (SHDHEAD = '1')                      else 'Z';

-- Generate SHDATA and SHDATAX
  SHDATA  <= '1' when (BUSY = '1' and DHEADEN = '0' and IHEADEN = '0' and DONEDATA(1) = '0') else '0';
  SHDATAX <= '1' when (BUSY = '1' and DHEADEN = '0' and IHEADEN = '0' and DONEDATA(1) = '0') else '0';

-- Generate DONEDATA
  DV_DONEDATA  <= COMMAND(9 downto 6);
  CE_DONEDATA  <= '1' when (SHDATA = '1' and ENABLE = '1')                         else '0';
-- CLR_DONEDATA <= '1' when (RST='1' and DONEDATA_1='1' and DONEDATA='1') else '0';
  CLR_DONEDATA <= '1' when (RST = '1' and DONEDATA(1) = '1' and DONEDATA(0) = '1') else '0';
  UP_DONEDATA  <= '0';                  -- connected to GND
--old:  CB4CLED(SLOWCLK, CE_DONEDATA, CLR_DONEDATA, LOAD, UP_DONEDATA, DV_DONEDATA, QV_DONEDATA, QV_DONEDATA, CEO_DONEDATA, TC_DONEDATA);
  CB_DONEDATA : CB4CLED port map (CEO_DONEDATA, QV_DONEDATA(0), QV_DONEDATA(1), QV_DONEDATA(2), QV_DONEDATA(3),
                                  TC_DONEDATA, SLOWCLK, CE_DONEDATA, CLR_DONEDATA,
                                  DV_DONEDATA(0), DV_DONEDATA(1), DV_DONEDATA(2), DV_DONEDATA(3), LOAD, UP_DONEDATA);

  -- Guido - Missing the 'and' with 'not LOAD'
  D_DONEDATA <= '1' when (QV_DONEDATA = "0000" and LOAD = '0') else '0';
  FD_DONEDATA_D0 : FDCE port map (DONEDATA(0), SLOWCLK, SHDATA, LOAD, D_DONEDATA);
  FD_DONEDATA_01 : FDC port map (DONEDATA(1), SLOWCLK, LOAD, DONEDATA(0));
  --FD_DONEDATA_12 : FDC port map (DONEDATA(2), SLOWCLK, LOAD, DONEDATA(1));

-- Generate TMS when SHDATA=1           -- Guido - BUG!!!!!!!!!!
  TMS <= (TAILEN and D_DONEDATA) when (SHDATA = '1') else 'Z';

-- Generate TAILEN
  CE_TAILEN  <= INSTSHFT or DATASHFT;
  CLR_TAILEN <= RST or DONETAIL;
  FD_TAILEN : FDCE port map (TAILEN, LOAD, CE_TAILEN, CLR_TAILEN, COMMAND(1));

-- Generate SHTAIL
  SHTAIL <= BUSY and DONEDATA(1) and TAILEN;

-- Generate DONETAIL
  CE_DONETAIL  <= '1' when (SHTAIL = '1' and ENABLE = '1') else '0';
  CLR_DONETAIL <= '1' when (RST = '1' or Q_DONETAIL = '1') else '0';
  -- old : CB4CE(SLOWCLK, CE_DONETAIL, CLR_DONETAIL, QV_DONETAIL, QV_DONETAIL, CEO_DONETAIL, TC_DONETAIL);
  --Adam: Replaced CB4CE with CB2CE
  CB_DONETAIL : CB4CE port map (open, open, DONETAIL, open, open, open,
                                SLOWCLK, CE_DONETAIL, CLR_DONETAIL);
  C_DONETAIL <= SLOWCLK;
  FD_DONETAIL : FD_1 port map (Q_DONETAIL, C_DONETAIL, DONETAIL);

-- Generate TMS when SHTAIL=1
  CE_SHTAIL_TMS <= SHTAIL and ENABLE;
  FD_Q2Q1_SHTAIL_TMS : FDCE port map (Q1_SHTAIL_TMS, SLOWCLK, CE_SHTAIL_TMS, RST, Q2_SHTAIL_TMS);
  FD_Q1Q2_SHTAIL_TMS : FDPE port map (Q2_SHTAIL_TMS, SLOWCLK, CE_SHTAIL_TMS, Q1_SHTAIL_TMS, RST);
  TMS           <= Q2_SHTAIL_TMS when (SHTAIL = '1') else 'Z';

-- Generate ENABLE
  CE_ENABLE <= '1' when (RESETJTAG = '1' or BUSY = '1') else '0';
  D_ENABLE  <= not ENABLE;
  FD_ENABLE : FDCE port map (ENABLE, SLOWCLK, CE_ENABLE, RST, D_ENABLE);

-- Generate RESETJTAG
  D1_RESETJTAG  <= '1' when ((STROBE = '1' and RSTJTAG = '1') or INITJTAGS = '1') else '0';
  FD_Q1_RESETJTAG : FDC port map (Q1_RESETJTAG, FASTCLK, RST, D1_RESETJTAG);
  FD_Q2_RESETJTAG : FDC port map (Q2_RESETJTAG, FASTCLK, RST, Q1_RESETJTAG);
  OKRST         <= '1' when (Q1_RESETJTAG = '1' and Q2_RESETJTAG = '1')           else '0';
  CLR_RESETJTAG <= '1' when (RESETDONE = '1' or RST = '1')                        else '0';
  FD_Q3_RESETJTAG : FDC port map (Q3_RESETJTAG, OKRST, CLR_RESETJTAG, LOGICH);
  FD_RESETJTAG    : FDC port map (RESETJTAG, SLOWCLK, CLR_RESETJTAG, Q3_RESETJTAG);

-- Generate RESETDONE
  CLR_RESETDONE <= not OKRST;
-- old : CB4CE(SLOWCLK, RESETJTAG, CLR_RESETDONE, QV_RESETDONE, QV_RESETDONE, CEO_RESETDONE, TC_RESETDONE);
  CB_RESETDONE : CB4CE port map (CEO_RESETDONE, QV_RESETDONE(0), QV_RESETDONE(1), QV_RESETDONE(2), QV_RESETDONE(3),
                                 TC_RESETDONE, SLOWCLK, RESETJTAG, CLR_RESETDONE);
  RESETDONE <= '1' when (QV_RESETDONE(2) = '1' and QV_RESETDONE(3) = '1') else '0';

-- Generate TMS when RESETJTAG=1
  CE_RESETJTAG_TMS <= (RESETJTAG and ENABLE);
  FD_Q6Q1_RESETJTAG_TMS : FDCE port map (Q1_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, RST, Q6_RESETJTAG_TMS);
  FD_Q1Q2_RESETJTAG_TMS : FDPE port map (Q2_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, Q1_RESETJTAG_TMS, RST);
  FD_Q2Q3_RESETJTAG_TMS : FDPE port map (Q3_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, Q2_RESETJTAG_TMS, RST);
  FD_Q3Q4_RESETJTAG_TMS : FDPE port map (Q4_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, Q3_RESETJTAG_TMS, RST);
  FD_Q4Q5_RESETJTAG_TMS : FDPE port map (Q5_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, Q4_RESETJTAG_TMS, RST);
  FD_Q6Q5_RESETJTAG_TMS : FDPE port map (Q6_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, Q5_RESETJTAG_TMS, RST);
  TMS              <= '1' when (RESETJTAG = '1') else 'Z';

-- Generate TCK
  TCK <= JTAGSEL_INNER and ENABLE;

-- Generate TCK
  JTAGSEL <= JTAGSEL_INNER;

-- Generate TDI
  CE_TDI <= (SHDATA and ENABLE);
-- old: SR16CLRE(SLOWCLK, CE_TDI, RST, LOAD, QV_TDI(0), INDATA, QV_TDI, QV_TDI);
-- Incorrect solution: Need to shift right instead of left
-- SR_TDI : SR16CLE port map (QV_TDI,SLOWCLK,CE_TDI,RST,INDATA,LOAD,QV_TDI(0));
  SR_TDI : SR16CLED port map (QV_TDI, SLOWCLK, CE_TDI, RST, INDATA, LOAD, LOGICL, LOGICL, QV_TDI(0));
  TDI    <= QV_TDI(0);

-- Generate RDTDODK
  RDTDODK <= '1' when (STROBE = '1' and READTDO = '1' and BUSYP1 = '0' and BUSY = '0') else '0';

-- Generate OUTDATA
  SHFT_EN              <= SHDATAX and not ENABLE;
-- old: SR16LCE(SLOWCLK, SHFT_EN, RST, ODMBTDO, Q_OUTDATA, Q_OUTDATA);
-- Incorrect solution: Need to shift right instead of left
-- SR_OUTDATA : SR16CE port map (Q_OUTDATA,SLOWCLK,SHFT_EN,RST,ODMBTDO);
-- Indata = throwaway: "Load" bit is set to LOGICL.
  SR_OUTDATA : SR16CLED port map (Q_OUTDATA, SLOWCLK, SHFT_EN, RST, INDATA, LOGICL, LOGICL, LOGICL, ODMBTDO);
  OUTDATA(15 downto 0) <= Q_OUTDATA(15 downto 0) when (RDTDODK = '1') else "ZZZZZZZZZZZZZZZZ";

-- Generate DTACK when DATASHFT=1 or INSTSHFT=1
  D_DTACK   <= (DATASHFT or INSTSHFT);
  CE_DTACK  <= not BUSY;
  CLR_DTACK <= not STROBE;
  FD_DQ1_DTACK  : FDCE port map (Q1_DTACK, SLOWCLK, CE_DTACK, CLR_DTACK, D_DTACK);
-- Old code: commented out prior to change from package latchesAndFlipFlops
-- FDC(Q1_LED, SLOWCLK, CLR_LED, Q2_LED);
-- FD(Q2_LED, SLOWCLK, Q3_LED);
-- FD(Q3_LED, SLOWCLK, Q4_LED);
-- This is the new code; changed to new format
  FD_Q1Q2_DTACK : FDCE port map (Q2_DTACK, SLOWCLK, CE_DTACK, CLR_DTACK, Q1_DTACK);
  FD_Q2Q3_DTACK : FDCE port map (Q3_DTACK, SLOWCLK, CE_DTACK, CLR_DTACK, Q2_DTACK);
  FD_Q3Q4_DTACK : FDCE port map (Q4_DTACK, SLOWCLK, CE_DTACK, CLR_DTACK, Q3_DTACK);

-- DTACK                     
  DTACK <= '1' when (RESETDONE = '1' and INITJTAGS = '0') or
           (RDTDODK = '1') or q_dtack_pol = '1' or
           (Q3_DTACK = '1' and Q4_DTACK = '1') else '0';

-- Generate LED.
  LED <= '0' when (Q3_DTACK = '1' and Q4_DTACK = '1') else '0';

end ODMBJTAG_Arch;

