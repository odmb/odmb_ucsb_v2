library ieee;
library work;
use work.Latches_Flipflops.all;
use ieee.std_logic_1164.all;
use work.ucsb_types.all;


entity CFEBJTAG is
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
    TCK       : out std_logic_vector(7 downto 1);
    TDI       : out std_logic;
    TMS       : out std_logic;
    FEBTDO    : in  std_logic_vector(7 downto 1);

    LED     : out std_logic;
    DIAGOUT : out std_logic_vector(17 downto 0)
    );
end CFEBJTAG;

architecture CFEBJTAG_Arch of CFEBJTAG is
  signal LOGICH : std_logic := '1';

  signal CMDHIGH                                                 : std_logic;
--  signal CMDDEV                                                  : std_logic_vector(4 downto 0);
  signal CMDDEV                                                  : std_logic_vector(15 downto 0);
  signal INSTSHFT_ARB, INSTSHFT_SP                               : std_logic;
  signal DATASHFT, INSTSHFT, READTDO, SELCFEB, READCFEB, RSTJTAG : std_logic;
  signal TAILSP                                                  : std_logic;
  signal TAILSP_NOT                                              : std_logic;
  signal RST_TAIL                                                : std_logic;
  signal RST_SP                                                  : std_logic;

  signal SELFEB                                   : std_logic_vector(7 downto 1);
  signal D_DTACK_SELCFEB, Q_DTACK_SELCFEB         : std_logic;
  signal D_DTACK_READCFEB, Q_DTACK_READCFEB       : std_logic;
  signal D1_LOAD, D2_LOAD, CLR_LOAD, Q_LOAD, LOAD : std_logic;

  signal Q_BUSY, D_BUSY, CLR_BUSY, BUSY, BUSYP1                           : std_logic;
  signal C_IHEADEN, CLR_IHEADEN, IHEADEN                                  : std_logic;
  signal SHIHEAD                                                          : std_logic;
  signal R_DONEIHEAD, Q_DONEIHEAD, CEO_DONEIHEAD, TC_DONEIHEAD, DONEIHEAD : std_logic;
  signal QV_DONEIHEAD                                                     : std_logic_vector(3 downto 0);
  signal Q3_SHIHEAD_TMS, Q4_SHIHEAD_TMS, Q5_SHIHEAD_TMS                   : std_logic;
  signal CE_SHIHEAD_TMS, Q1_SHIHEAD_TMS, Q2_SHIHEAD_TMS                   : std_logic;


  signal C_DHEADEN, CLR_DHEADEN, DHEADEN                                  : std_logic;
  signal SHDHEAD                                                          : std_logic;
  signal CE_DONEDHEAD                                                     : std_logic;
  signal R_DONEDHEAD, Q_DONEDHEAD, CEO_DONEDHEAD, TC_DONEDHEAD, DONEDHEAD : std_logic;
  signal QV_DONEDHEAD                                                     : std_logic_vector(3 downto 0);
  signal Q3_SHDHEAD_TMS, Q4_SHDHEAD_TMS, Q5_SHDHEAD_TMS                   : std_logic;
  signal CE_SHDHEAD_TMS, Q1_SHDHEAD_TMS, Q2_SHDHEAD_TMS                   : std_logic;
  signal C_DONEDHEAD                                                      : std_logic;


  signal SHDATA, SHDATAX, CE_SHIFT1 : std_logic;


  signal DV_DONEDATA, QV_DONEDATA                                          : std_logic_vector(3 downto 0);
  signal CE_DONEDATA, CLR_DONEDATA, UP_DONEDATA, CEO_DONEDATA, TC_DONEDATA : std_logic;
  signal D_DONEDATA                                                        : std_logic;
  signal DONEDATA                                                          : std_logic_vector(1 downto 0) := (others => '0');


  signal CE_TAILEN, CLR_TAILEN, TAILEN               : std_logic;
  signal SHTAIL                                      : std_logic;
  signal CE_DONETAIL, CLR_DONETAIL, Q_DONETAIL       : std_logic;
  signal CEO_DONETAIL, TC_DONETAIL, C_DONETAIL       : std_logic;
  signal QV_DONETAIL                                 : std_logic_vector(3 downto 0);
  signal DONETAIL                                    : std_logic;
  signal CE_SHTAIL_TMS, Q1_SHTAIL_TMS, Q2_SHTAIL_TMS : std_logic;


--  signal CE_ENABLE, D_ENABLE, ENABLE : std_logic;
  signal CE_TCK_GLOBAL, D_TCK_GLOBAL, TCK_GLOBAL: std_logic;

  signal D1_RESETJTAG, Q1_RESETJTAG, Q2_RESETJTAG        : std_logic;
  signal Q3_RESETJTAG, CLR_RESETJTAG, RESETJTAG          : std_logic;
  signal OKRST, INITJTAGS_Q, INITJTAGS_QQ, INITJTAGS_QQQ : std_logic;
  signal CLR_RESETJTAG_PULSE : std_logic := '0';
  signal rst_init : std_logic := '0';

  signal CLR_RESETDONE, CEO_RESETDONE, TC_RESETDONE : std_logic;
  signal QV_RESETDONE                               : std_logic_vector(3 downto 0);
  signal RESETDONE                                  : std_logic;


  signal CE_RESETJTAG_TMS, Q1_RESETJTAG_TMS, Q2_RESETJTAG_TMS                   : std_logic;
  signal Q3_RESETJTAG_TMS, Q4_RESETJTAG_TMS, Q5_RESETJTAG_TMS, Q6_RESETJTAG_TMS : std_logic;


  signal CE_TDI : std_logic;
  signal QV_TDI : std_logic_vector(15 downto 0);

  signal RDTDODK                                                              : std_logic;
  signal TDO                                                                  : std_logic;
  signal Q_OUTDATA                                                            : std_logic_vector(15 downto 0);
  signal D_DTACK, CE_DTACK, CLR_DTACK, Q1_DTACK, Q2_DTACK, Q3_DTACK, Q4_DTACK : std_logic;
  signal DTACK_INNER                                                          : std_logic;

  signal strobe_slow                                                         : std_logic;


begin


-- COMMAND DECODER
--  CMDHIGH  <= '1' when (DEVICE = '1' and COMMAND(5) = '0' and COMMAND(4) = '0') else '0';
--  INSTSHFTSP <= COMMAND(4) & COMMAND(3) & COMMAND(2) & COMMAND(1) & COMMAND(0);
--  CMDDEV   <= CMDHIGH & COMMAND(3) & COMMAND(2) & COMMAND(1) & COMMAND(0);

--  DATASHFT <= '1' when (CMDDEV(4 downto 2) = "100")                             else '0';
--  INSTSHFT <= '1' when (CMDDEV(4 downto 2) = "111" or CMDDEV = "10111")         else '0';
--  INSTSHFT <= '1' when (CMDDEV(4 downto 2) = "111" or CMDDEV = "10111" or INSTSHFTSP(4 downto 1) = "1001" )   else '0';
--  READTDO  <= '1' when (CMDDEV = "10101")                                       else '0';
--  SELCFEB  <= '1' when (CMDDEV = "11000")                                       else '0';
--  READCFEB <= '1' when (CMDDEV = "11001")                                       else '0';
--  RSTJTAG  <= '1' when (CMDDEV = "10110")                                       else '0';

  CMDDEV <= "000" & DEVICE & COMMAND & "00";
  DATASHFT <= '1' when (DEVICE = '1' and CMDDEV(7 downto 4) = x"0")  else '0';
  INSTSHFT_ARB <= '1' when (DEVICE = '1' and CMDDEV(7 downto 4) = x"3") else '0';
  INSTSHFT_SP <= '1' when (DEVICE = '1' and CMDDEV(7 downto 4) = x"4") else '0';
  INSTSHFT <= '1' when (DEVICE = '1' and (CMDDEV(7 downto 0) = x"1C" or INSTSHFT_ARB = '1' or INSTSHFT_SP = '1') ) else '0';
  READTDO  <= '1' when CMDDEV = x"1014" else '0';
  SELCFEB  <= '1' when CMDDEV = x"1020" else '0';
  READCFEB <= '1' when CMDDEV = x"1024" else '0';
  RSTJTAG  <= '1' when CMDDEV = x"1018" else '0';

-- Write SELFEB when SELCFEB=1 (The JTAG initialization should be broadcast)
  rst_init <= RST or initjtags;
  FDPE(INDATA(0), STROBE, SELCFEB, rst_init, SELFEB(1));
  FDPE(INDATA(1), STROBE, SELCFEB, rst_init, SELFEB(2));
  FDPE(INDATA(2), STROBE, SELCFEB, rst_init, SELFEB(3));
  FDPE(INDATA(3), STROBE, SELCFEB, rst_init, SELFEB(4));
  FDPE(INDATA(4), STROBE, SELCFEB, rst_init, SELFEB(5));
  FDPE(INDATA(5), STROBE, SELCFEB, rst_init, SELFEB(6));
  FDPE(INDATA(6), STROBE, SELCFEB, rst_init, SELFEB(7));

-- Syncing STROBE to SLOWCLK
  STROBE_PULSE  : PULSE2SLOW port map(strobe_slow, SLOWCLK, FASTCLK, RST, STROBE);


-- Generate DTACK when SELCFEB=1
  D_DTACK_SELCFEB <= '1' when (STROBE = '1' and SELCFEB = '1') else '0';
  FD(D_DTACK_SELCFEB, FASTCLK, Q_DTACK_SELCFEB);
--    DTACK_INNER <= '0' when (Q_DTACK_SELCFEB='1') else 'Z'; -- BGB commented

-- Write SELFEB to OUTDATA when READCFEB=1
  OUTDATA <= "000000000" & SELFEB(7 downto 1) when (STROBE = '1' and READCFEB = '1') else (others => 'Z');


-- Generate DTACK when READCFEB=1
  D_DTACK_READCFEB <= '1' when (STROBE = '1' and READCFEB = '1') else '0';
  FD(D_DTACK_READCFEB, FASTCLK, Q_DTACK_READCFEB);
--    DTACK_INNER <= '0' when (Q_DTACK_READCFEB='1') else 'Z'; -- BGB commented

-- Generate LOAD
  D1_LOAD  <= DATASHFT or INSTSHFT;
  CLR_LOAD <= LOAD or RST;
  FDC(D1_LOAD, STROBE, CLR_LOAD, Q_LOAD);
  D2_LOAD  <= '1' when (Q_LOAD = '1' and BUSY = '0') else '0';
  FDC(D2_LOAD, SLOWCLK, RST, LOAD);


-- Generate BUSY and BUSYP1
  FDC(LOAD, SLOWCLK, RST, Q_BUSY);
  CLR_BUSY <= '1' when ((DONEDATA(1) = '1' and (TAILEN = '0')) or RST = '1' or DONETAIL = '1') else '0';
  D_BUSY   <= '1' when (Q_BUSY = '1' or BUSY = '1')                                            else '0';
  FDC(D_BUSY, SLOWCLK, CLR_BUSY, BUSY);
  FDC(BUSY, SLOWCLK, RST, BUSYP1);


-- Generate IHEADEN
-- NOTE: The old code set C_IHEADEN based on STROBE only.  The old DMB FW
-- schematics show C_IHEADEN set by STROBE and not BUSY.
-- This is old code.
--    C_IHEADEN <= '1' when (STROBE='1') else '0'; -- BGB commented
-- This is new code.
  C_IHEADEN   <= '1' when (STROBE = '1' and BUSY = '0')  else '0';  -- BGB uncommented
  CLR_IHEADEN <= '1' when (RST = '1' or DONEIHEAD = '1') else '0';
  FDCE(COMMAND(0), C_IHEADEN, INSTSHFT, CLR_IHEADEN, IHEADEN);

-- Generate SHIHEAD
  SHIHEAD <= '1' when (BUSY = '1' and IHEADEN = '1') else '0';


-- Generate DONEIHEAD
  R_DONEIHEAD <= '1' when (LOAD = '1' or RST = '1' or Q_DONEIHEAD = '1')        else '0';  -- Bug in FG Version (missing else '0')
  CB4RE(SLOWCLK, SHIHEAD, R_DONEIHEAD, QV_DONEIHEAD, QV_DONEIHEAD, CEO_DONEIHEAD, TC_DONEIHEAD);
  DONEIHEAD   <= '1' when ((QV_DONEIHEAD(1) = '1') and (QV_DONEIHEAD(3) = '1')) else '0';
  FD(DONEIHEAD, SLOWCLK, Q_DONEIHEAD);


-- Generate TMS when SHIHEAD=1
--  CE_SHIHEAD_TMS <= '1'            when ((SHIHEAD = '1') and (ENABLE = '1')) else '0';
  CE_SHIHEAD_TMS <= '1'            when ((SHIHEAD = '1') and (TCK_GLOBAL = '1')) else '0';
  FDCE(Q5_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, RST, Q1_SHIHEAD_TMS);
  FDCE(Q1_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, RST, Q2_SHIHEAD_TMS);
  FDPE(Q2_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, RST, Q3_SHIHEAD_TMS);
  FDPE(Q3_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, RST, Q4_SHIHEAD_TMS);
  FDCE(Q4_SHIHEAD_TMS, SLOWCLK, CE_SHIHEAD_TMS, RST, Q5_SHIHEAD_TMS);  -- Bug in FG Version (FDCE replaces FDPE)
  TMS            <= Q5_SHIHEAD_TMS when (SHIHEAD = '1')                      else 'Z';  -- Bug in FG Version (Q5_SHDHEAD_TMS replaces '1')

-- generate DHEADEN
-- NOTE: The old code set C_DHEADEN based on STROBE only.  The old DMB FW
-- schematics show C_DHEADEN set by STROBE and not BUSY.
-- This is old code.
--    C_DHEADEN <= '1' when (STROBE='1') else '0'; -- BGB commented out
-- This is new code.
  C_DHEADEN   <= '1' when (STROBE = '1' and BUSY = '0')  else '0';  -- BGB uncommented
  CLR_DHEADEN <= '1' when (RST = '1' or DONEDHEAD = '1') else '0';
  FDCE(COMMAND(0), C_DHEADEN, DATASHFT, CLR_DHEADEN, DHEADEN);  -- Bug in FG Version (DATASHFT replaces INSTSHFT)


-- Generate SHDHEAD
  SHDHEAD <= '1' when (BUSY = '1' and DHEADEN = '1') else '0';
--  CE_DONEDHEAD  <= '1' when (SHDHEAD = '1' and ENABLE = '1') else '0';
  CE_DONEDHEAD  <= '1' when (SHDHEAD = '1' and TCK_GLOBAL = '1') else '0';


-- Generate DONEDHEAD
  R_DONEDHEAD <= '1' when (LOAD = '1' or RST = '1' or Q_DONEDHEAD = '1')       else '0';
  CB4RE(SLOWCLK, CE_DONEDHEAD, R_DONEDHEAD, QV_DONEDHEAD, QV_DONEDHEAD, CEO_DONEDHEAD, TC_DONEDHEAD);
  DONEDHEAD   <= '1' when ((QV_DONEDHEAD(0) = '1')and (QV_DONEDHEAD(1) = '1')) else '0';
--  CB4RE(SLOWCLK, SHDHEAD, R_DONEDHEAD, QV_DONEDHEAD, QV_DONEDHEAD, CEO_DONEDHEAD, TC_DONEDHEAD);
--  DONEDHEAD   <= '1' when ((QV_DONEDHEAD(1) = '1')and (QV_DONEDHEAD(3) = '1')) else '0';
--  FD(DONEDHEAD, SLOWCLK, Q_DONEDHEAD);
  C_DONEDHEAD <= SLOWCLK;
  FD(DONEDHEAD, C_DONEDHEAD, Q_DONEDHEAD);


-- Generate TMS when SHDHEAD=1
--  CE_SHDHEAD_TMS <= '1'            when ((SHDHEAD = '1') and (ENABLE = '1')) else '0';
  CE_SHDHEAD_TMS <= '1'            when ((SHDHEAD = '1') and (TCK_GLOBAL = '1')) else '0';
  FDCE(Q3_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, RST, Q1_SHDHEAD_TMS);
  FDCE(Q1_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, RST, Q2_SHDHEAD_TMS);
  FDPE(Q2_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, RST, Q3_SHDHEAD_TMS);
--  FDCE(Q3_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, RST, Q4_SHDHEAD_TMS);  -- Bug in FG Version (FDCE replaces FDPE)
--  FDCE(Q4_SHDHEAD_TMS, SLOWCLK, CE_SHDHEAD_TMS, RST, Q5_SHDHEAD_TMS);  -- Bug in FG Version (FDCE replaces FDPE)
  TMS            <= Q3_SHDHEAD_TMS when (SHDHEAD = '1')                      else 'Z';  -- Bug in FG Version (Q5_SHDHEAD_TMS replaces '1')

-- Generate SHDATA and SHDATAX
  SHDATA  <= '1' when (BUSY = '1' and DHEADEN = '0' and IHEADEN = '0' and DONEDATA(1) = '0') else '0';
  SHDATAX <= '1' when (BUSY = '1' and DHEADEN = '0' and IHEADEN = '0' and DONEDATA(1) = '0') else '0';


-- Generate DONEDATA
  DV_DONEDATA  <= COMMAND(9 downto 6);
--  CE_DONEDATA  <= '1' when (SHDATA = '1' and ENABLE = '1')                       else '0';
  CE_DONEDATA  <= '1' when (SHDATA = '1' and TCK_GLOBAL = '1')                       else '0';
--    CLR_DONEDATA <= '1' when (RST='1' and DONEDATA(1)='1' and DONEDATA(0)='1') else '0'; -- BGB should be an or
  CLR_DONEDATA <= '1' when (RST = '1' or DONEDATA(1) = '1' or DONEDATA(0) = '1') else '0';  -- BGB should be an or
  UP_DONEDATA  <= '0';                  -- connected to GND
  CB4CLED(SLOWCLK, CE_DONEDATA, CLR_DONEDATA, LOAD, UP_DONEDATA, DV_DONEDATA, QV_DONEDATA, QV_DONEDATA, CEO_DONEDATA, TC_DONEDATA);  -- Bug in FG Version (DV_DONEDATA vs D_DONEDATA)
  D_DONEDATA   <= '1' when (QV_DONEDATA = "0000" and LOAD = '0')                 else '0';  -- Bug in FG Version (D_DONEDATA vs (DONEDATA(1))
  FDCE(D_DONEDATA, SLOWCLK, SHDATA, LOAD, DONEDATA(0));  -- Bug in FG Version (D_DONEDATA vs (DONEDATA(1))
  FDC(DONEDATA(0), SLOWCLK, LOAD, DONEDATA(1));
  --FDC(DONEDATA(1), SLOWCLK, LOAD, DONEDATA(2));


-- Generate TMS when SHDATA=1 -- Guido - BUG!!!!!!!!!!
  TMS <= (TAILEN and D_DONEDATA) when (SHDATA = '1') else 'Z';  -- Bug in FG Version (D2_DONEDATA replaces DONEDATA(1))

-- Generate TAILEN
  CE_TAILEN  <= '1' when (INSTSHFT = '1' or DATASHFT = '1') else '0';
  CLR_TAILEN <= '1' when (RST = '1' or DONETAIL = '1')      else '0';
  FDCE(COMMAND(1), LOAD, CE_TAILEN, CLR_TAILEN, TAILEN);

-- Generate SHTAIL
  SHTAIL <= '1' when (BUSY = '1' and DONEDATA(1) = '1' and TAILEN = '1') else '0';
  FDCE(INSTSHFT_SP, LOAD, CE_TAILEN, CLR_TAILEN, TAILSP);
  TAILSP_NOT <= '0' when (TAILSP = '1') else '1';
  SET_SP_RST : PULSE2SAME port map(RST_SP, SLOWCLK, CLR_TAILEN, TAILSP_NOT);

-- Generate DONETAIL
-- NOTE: I think there was a bug in the old FW.  SLOWCLK was passed to FD_1, it
-- should be not SLOWCLK based on the OLD DMB FW schematics
--  CE_DONETAIL  <= '1' when (SHTAIL = '1' and ENABLE = '1') else '0';
  CE_DONETAIL  <= '1' when (SHTAIL = '1' and TCK_GLOBAL = '1') else '0';
  CLR_DONETAIL <= '1' when (RST = '1' or Q_DONETAIL = '1') else '0';
  CB4CE(SLOWCLK, CE_DONETAIL, CLR_DONETAIL, QV_DONETAIL, QV_DONETAIL, CEO_DONETAIL, TC_DONETAIL);
  DONETAIL     <= QV_DONETAIL(0) when (TAILSP = '1') else QV_DONETAIL(1);
-- This is old code.
  C_DONETAIL   <= SLOWCLK;              -- Bug in FG Version (old code was ok)
-- This is new code;
--  C_DONETAIL <= not SLOWCLK;    
  FD_1(DONETAIL, C_DONETAIL, Q_DONETAIL);


-- Generate TMS when SHTAIL=1
--  CE_SHTAIL_TMS <= '1'           when ((SHTAIL = '1') and (ENABLE = '1')) else '0';
  CE_SHTAIL_TMS <= '1'           when ((SHTAIL = '1') and (TCK_GLOBAL = '1')) else '0';
  RST_TAIL <=  '1'               when (RST = '1' or RST_SP = '1') else '0';
  FDCE(Q2_SHTAIL_TMS, SLOWCLK, CE_SHTAIL_TMS, RST_TAIL, Q1_SHTAIL_TMS);
  FDPE(Q1_SHTAIL_TMS, SLOWCLK, CE_SHTAIL_TMS, RST_TAIL, Q2_SHTAIL_TMS);
-- This code from Frank.
--  TMS <= '1' when (SHTAIL = '1') else 'Z';
-- This code from Guido.
  TMS           <= Q2_SHTAIL_TMS when (SHTAIL = '1')                      else 'Z';


-- Generate ENABLE
--  CE_ENABLE <= '1' when (RESETJTAG = '1' or BUSY = '1') else '0';
  CE_TCK_GLOBAL <= '1' when (RESETJTAG = '1' or BUSY = '1') else '0';
--  D_ENABLE  <= not ENABLE;
  D_TCK_GLOBAL  <= not TCK_GLOBAL;
--  FDCE(D_ENABLE, SLOWCLK, CE_ENABLE, RST, ENABLE);
  FDCE(D_TCK_GLOBAL, SLOWCLK, CE_TCK_GLOBAL, RST, TCK_GLOBAL);


-- Generate RESETJTAG and OKRST 
  -- INITJTAGS comes from odmb_ucsb_v2 when the DCFEBs DONE bits go high
  FDC(INITJTAGS, SLOWCLK, RST, INITJTAGS_Q);
  FDC(INITJTAGS_Q, SLOWCLK, RST, INITJTAGS_QQ);
  FDC(INITJTAGS_QQ, SLOWCLK, RST, INITJTAGS_QQQ);
  D1_RESETJTAG  <= '1' when ((STROBE = '1' and RSTJTAG = '1') or INITJTAGS = '1') else '0';
  FDC(D1_RESETJTAG, SLOWCLK, RST, Q1_RESETJTAG);
  FDC(Q1_RESETJTAG, SLOWCLK, RST, Q2_RESETJTAG);
  OKRST         <= '1' when (Q1_RESETJTAG = '1' and Q2_RESETJTAG = '1')           else '0';
  CLR_RESETJTAG <= '1' when (RESETDONE = '1' or RST = '1')                        else '0';
  FDC(LOGICH, OKRST, CLR_RESETJTAG, Q3_RESETJTAG);
  FDC(Q3_RESETJTAG, SLOWCLK, CLR_RESETJTAG, RESETJTAG);


-- Generate RESETDONE 
  -- PULSE2SLOW only works if the signal is 1 CC long in the original clock domain
  RESETJTAG_PULSE  : PULSE2FAST port map(CLR_RESETJTAG_PULSE, FASTCLK, '0', CLR_RESETJTAG);
  RESETDONE_PULSE  : PULSE2SLOW port map(CLR_RESETDONE, SLOWCLK, FASTCLK, '0', CLR_RESETJTAG_PULSE);
  CB4CE(SLOWCLK, RESETJTAG, CLR_RESETDONE, QV_RESETDONE, QV_RESETDONE, CEO_RESETDONE, TC_RESETDONE);
  RESETDONE     <= '1' when (QV_RESETDONE(2) = '1' and QV_RESETDONE(3) = '1') else '0';


-- Generate DTACK when RESETDONE=1 AND INITJTAGS=0
--    DTACK_INNER <= '0' when (RESETDONE='1' and INITJTAGS='0') else 'Z'; -- bgb commented out

-- Generate TMS when RESETJTAG=1
--  CE_RESETJTAG_TMS <= (RESETJTAG and ENABLE);
  CE_RESETJTAG_TMS <= (RESETJTAG and TCK_GLOBAL);
  FDCE(Q6_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, RST, Q1_RESETJTAG_TMS);
  FDPE(Q1_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, RST, Q2_RESETJTAG_TMS);
  FDPE(Q2_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, RST, Q3_RESETJTAG_TMS);
  FDPE(Q3_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, RST, Q4_RESETJTAG_TMS);
  FDPE(Q4_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, RST, Q5_RESETJTAG_TMS);
  FDPE(Q5_RESETJTAG_TMS, SLOWCLK, CE_RESETJTAG_TMS, RST, Q6_RESETJTAG_TMS);
  TMS              <= Q6_RESETJTAG_TMS when (RESETJTAG = '1') else 'Z';  -- BGB

-- Generate TCK
  TCK(1) <= SELFEB(1) and TCK_GLOBAL;
  TCK(2) <= SELFEB(2) and TCK_GLOBAL;
  TCK(3) <= SELFEB(3) and TCK_GLOBAL;
  TCK(4) <= SELFEB(4) and TCK_GLOBAL;
  TCK(5) <= SELFEB(5) and TCK_GLOBAL;
  TCK(6) <= SELFEB(6) and TCK_GLOBAL;
  TCK(7) <= SELFEB(7) and TCK_GLOBAL;


-- Generate TDI
--  CE_TDI <= (SHDATA and ENABLE);
  CE_TDI <= (SHDATA and TCK_GLOBAL);
  SR16CLRE(SLOWCLK, CE_TDI, RST, LOAD, QV_TDI(0), INDATA, QV_TDI, QV_TDI);
  TDI    <= QV_TDI(0);


-- Generate TDO
  TDO <= FEBTDO(1) when SELFEB = "0000001" else
         FEBTDO(2) when SELFEB = "0000010" else
         FEBTDO(3) when SELFEB = "0000100" else
         FEBTDO(4) when SELFEB = "0001000" else
         FEBTDO(5) when SELFEB = "0010000" else
         FEBTDO(6) when SELFEB = "0100000" else
         FEBTDO(7) when SELFEB = "1000000" else
-- This is old code.
         '0';  -- BGB This is a mux now not multiple drivers
-- This is new code.           
--           'Z'; 

-- Generate RDTDODK
  RDTDODK <= '1' when (STROBE = '1' and READTDO = '1' and BUSYP1 = '0' and BUSY = '0') else '0';


-- Generate DTACK when RDTDODK=1-- generate DTACK when RDTDODK=1

--    DTACK_INNER <= '0' when (RDTDODK='1') else 'Z'; -- BGB commented out

-- Generate OUTDATA
--  CE_SHIFT1            <= SHDATAX and not ENABLE;               -- BGB
  CE_SHIFT1            <= SHDATAX and not TCK_GLOBAL;               -- BGB
  SR16LCE(SLOWCLK, CE_SHIFT1, RST, TDO, Q_OUTDATA, Q_OUTDATA);  -- BGB
  OUTDATA(15 downto 0) <= Q_OUTDATA(15 downto 0) when (RDTDODK = '1') else "ZZZZZZZZZZZZZZZZ";

--BGB commented out
-- Generate DTACK when DATASHFT=1 or INSTSHFT=1
--    D_DTACK <= (DATASHFT or INSTSHFT);   
--    CE_DTACK <= not BUSY;
--    CLR_DTACK <= not STROBE;
--    FDCE(D_DTACK, SLOWCLK, CE_DTACK, CLR_DTACK, Q1_DTACK);
--    FDCE(Q1_DTACK, SLOWCLK, CE_DTACK, CLR_DTACK, Q2_DTACK);
--    FDCE(Q2_DTACK, SLOWCLK, CE_DTACK, CLR_DTACK, Q3_DTACK);
--    FDCE(Q3_DTACK, SLOWCLK, CE_DTACK, CLR_DTACK, Q4_DTACK);
--       DTACK_INNER <= '0' when (Q3_DTACK='1' and Q4_DTACK='1') else 'Z';

-- BGB back to old DMB logic
  D_DTACK   <= (DATASHFT or INSTSHFT);
  CE_DTACK  <= not BUSY;
  CLR_DTACK <= not STROBE;
  FDCE(D_DTACK, SLOWCLK, CE_DTACK, CLR_DTACK, Q1_DTACK);
  FDC(Q1_DTACK, SLOWCLK, CLR_DTACK, Q2_DTACK);
  FD(Q2_DTACK, SLOWCLK, Q3_DTACK);
  FD(Q3_DTACK, SLOWCLK, Q4_DTACK);

-- BGB
  DTACK_INNER <= '1' when (Q_DTACK_SELCFEB = '1') or
                 (Q_DTACK_READCFEB = '1') or
                 (RESETDONE = '1' and INITJTAGS_QQQ = '0') or
                 (RDTDODK = '1') or
                 (Q1_DTACK = '1' and Q2_DTACK = '1' and Q3_DTACK = '1' and Q4_DTACK = '1') else '0';
                                        -- BGB

-- DTACK_INNER ----> DTACK
  DTACK <= DTACK_INNER;


-- Generate LED.
  LED <= CE_SHIHEAD_TMS;  


-- generate DIAGOUT
  DIAGOUT(0)  <= LOAD;
--  DIAGOUT(1)  <= ENABLE;
  DIAGOUT(1)  <= TCK_GLOBAL;
  DIAGOUT(2)  <= BUSY;
  DIAGOUT(3)  <= RDTDODK;
  DIAGOUT(4)  <= QV_DONEIHEAD(3);
  DIAGOUT(5)  <= Q1_SHIHEAD_TMS;
  DIAGOUT(6)  <= RESETJTAG;
  DIAGOUT(7)  <= SHDATAX;
  DIAGOUT(8)  <= SLOWCLK;
  DIAGOUT(9)  <= READTDO;
  DIAGOUT(10) <= RSTJTAG;
  DIAGOUT(11) <= DHEADEN;
  DIAGOUT(12) <= IHEADEN;
  DIAGOUT(13) <= DONEDATA(1);
  DIAGOUT(14) <= SHIHEAD;
  DIAGOUT(15) <= DONEIHEAD;
  DIAGOUT(16) <= SELCFEB;
  DIAGOUT(17) <= DEVICE;


end CFEBJTAG_Arch;
