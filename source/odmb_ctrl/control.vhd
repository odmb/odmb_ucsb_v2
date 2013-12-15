-- CONTROL: Monitor state of the nine data FIFOs and creates DDU packet when FIFOs are non-empty.

library ieee;
library work;
library unisim;
library hdlmacro;
use hdlmacro.hdlmacro.CB16CE;
use hdlmacro.hdlmacro.IFD_1;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.and_reduce;
use ieee.std_logic_misc.or_reduce;

entity CONTROL is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );  
  port (

      CSP_CONTROL_FSM_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);
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
    OEFIFO_B  : out std_logic_vector(NFEB+2 downto 1);
    RENFIFO_B : out std_logic_vector(NFEB+2 downto 1);

-- from FIFOs
    FFOR_B      : in std_logic_vector(NFEB+2 downto 1);
    DATAIN      : in std_logic_vector(15 downto 0);
    DATAIN_LAST : in std_logic;

-- From JTAGCOM
    JOEF : in std_logic_vector(NFEB+2 downto 1);

-- From CRATEID in SETFEBDLY, and GA
    DAQMBID : in std_logic_vector(11 downto 0);

-- FROM SW1
    GIGAEN : in std_logic;

-- TO CAFIFO
    FIFO_POP : out std_logic;

-- TO DDUFIFO
    EOF : out std_logic;

-- FROM CAFIFO
    cafifo_l1a_dav   : in std_logic_vector(NFEB+2 downto 1);
    cafifo_l1a_match : in std_logic_vector(NFEB+2 downto 1);
    cafifo_l1a_cnt   : in std_logic_vector(23 downto 0);
    cafifo_bx_cnt    : in std_logic_vector(11 downto 0);
    cafifo_lost_pckt : in std_logic_vector(NFEB+2 downto 1)
    );
end CONTROL;

architecture CONTROL_arch of CONTROL is
  signal   LOGICL : std_logic                    := '0';
  --Adam signal LOGICH : std_logic := '1'; --signal is now a constant
  constant LOGICH : std_logic                    := '1';
  signal   ZERO7  : std_logic_vector(6 downto 0) := (others => '0');
  signal   ZERO8  : std_logic_vector(7 downto 0) := (others => '0');
  --Adam signal ZERO9 : std_logic_vector(8 downto 0) := (others => '0'); --signal is now a constant
  constant ZERO9  : std_logic_vector(8 downto 0) := (others => '0');
  signal   ZERO10 : std_logic_vector(9 downto 0) := (others => '0');

  signal cafifo_l1a_dav_corr : std_logic_vector(NFEB downto 1);
-- PAGE 1
  signal BUSY                : std_logic;
  signal GEMPTY_D            : std_logic_vector(3 downto 1);

  signal STARTREAD_RST, STARTREAD                        : std_logic                    := '0';
  signal OEHDR                                           : std_logic_vector(8 downto 1) := (others => '0');
  signal OEHDRA, OEHDRB                                  : std_logic                    := '0';
  signal DOHDR                                           : std_logic                    := '0';
  signal TAIL_RST, DDCNT_EN_RST, DDCNT_TC, OKDATA, DODAT : std_logic                    := '0';
  --Adam signal TAIL_RST, DDCNT_EN_RST, DDCNT_CEO, DDCNT_TC, OKDATA, DODAT : std_logic := '0'; --remove DDCNT_CEO (not used)
  signal DDCNT_EN                                        : std_logic_vector(1 downto 0);
  signal DDCNT                                           : std_logic_vector(15 downto 0);

  signal STARTTAIL_CE, STARTTAIL : std_logic := '0';
  signal TAIL                    : std_logic_vector(8 downto 1);
  signal TAILA, TAILB            : std_logic := '0';
  signal DOTAIL                  : std_logic := '0';

  signal DAV_D                  : std_logic := '0';
  signal DAV_D1, DAV_D2, DAV_D3 : std_logic := '0';

  signal POP_D                        : std_logic_vector(4 downto 1);
  signal TAILDONE, STPOP, L1ONLY, POP : std_logic := '0';

  signal FIFO_POP_RST, FIFO_POP_INNER, FIFO_POP_D : std_logic;

-- PAGE 2
  signal OEHDTL, OEHDTL_D : std_logic;
  --Adam signal FENDAV : std_logic_vector(NFEB+2 downto 1); --used only to assign unused fendaverr
  --Adam signal FENDAVERR : std_logic; --not used

  signal DATA_HDR, DATA_TAIL : std_logic_vector(15 downto 0);

  signal HDR_W1, HDR_W2, HDR_W3, HDR_W4, HDR_W5, HDR_W6, HDR_W7, HDR_W8 : std_logic_vector(15 downto 0);  --Adam Add initialization
  --Adam signal TAIL_W1, TAIL_W2, TAIL_W3, TAIL_W4, TAIL_W5, TAIL_W6, TAIL_W7, TAIL_W8 : std_logic_vector(15 downto 0); --TAIL_W7 and TAIL_W8 not used
  signal TAIL_W1, TAIL_W2, TAIL_W3, TAIL_W4, TAIL_W5, TAIL_W6           : std_logic_vector(15 downto 0);  --Adam Add Initialization

-- PAGE 3 
  signal GLRFD                : std_logic;
  signal RDY_CE, RDY, FIFORDY : std_logic_vector(NFEB+2 downto 1);

  signal P_AND_FIFORDY               : std_logic_vector(NFEB+2 downto 1);
  signal DISDAV, DISDAV_D, DISDAV_DD : std_logic;

-- PAGE 4
  signal R, R_RST                                                     : std_logic_vector(NFEB+2 downto 1);
  signal P                                                            : std_logic_vector(NFEB+2 downto 1);
  signal OE                                                           : std_logic_vector(NFEB+2 downto 1);
  signal DOEALL, OEALL, OEALL_D, OEDATA, OEDATA_D, OEDATA_DD, POPLAST : std_logic;
  signal DATA_AVAIL                                                   : std_logic;
  signal OEDATA_DAV                                                   : std_logic_vector(1 downto 0);
  signal JRDFF, JRDFF_D                                               : std_logic;
  --Adam signal EODATA, DATAON : std_logic; --not used

-- PAGE 5
  signal DONE_VEC, OE_Q               : std_logic_vector(NFEB+2 downto 1);
  signal OOE, RENFIFO_B_D             : std_logic_vector(NFEB+2 downto 1);
  signal OEFIFO_B_INNER               : std_logic_vector(NFEB+2 downto 1);
  signal OEFIFO_B_D, OEFIFO_B_PRE     : std_logic_vector(NFEB+2 downto 1);
  signal OEFIFO_B_D_D, OEFIFO_B_D_D_D : std_logic_vector(NFEB+2 downto 1);

-- PAGE 6
  signal DATA_A, DATA_B, DATA_C, DATA_D : std_logic_vector(15 downto 0) := (others => '0');
  signal DONE, LAST_RST                 : std_logic;
  signal LAST                           : std_logic                     := '0';
  signal LAST_TMP                       : std_logic                     := '0';
  signal LAST_TMP_1                     : std_logic                     := '0';

-- PAGE 7
  signal DATANOEND, DAVNODATA, DAVNODATA_D, ERRORD : std_logic_vector(NFEB+2 downto 1);
  signal NOEND_RST, NOEND_CEO, NOEND_TC, RSTCNT    : std_logic;
  signal NOEND                                     : std_logic_vector(15 downto 0);
  signal CRC, REG_CRC                              : std_logic_vector(23 downto 0) := (others => '0');
  signal CRCEN, CRCEN_D, CRCEN_Q                   : std_logic;
  signal DATA_CRC                                  : std_logic_vector(15 downto 0);
  signal TAIL78, DTAIL78, DTAIL7, DTAIL8           : std_logic;

-- PAGE 8
  signal JREF : std_logic_vector(NFEB+2 downto 1);

  constant fmt_vers              : std_logic_vector(1 downto 0)      := "01";
  constant l1a_dav_mismatch : std_logic                         := '0';
  constant ovlp             : std_logic_vector(5 downto 1)      := "00000";
  constant sync             : std_logic_vector(3 downto 0)      := "0000";
  constant alct_to_end      : std_logic                         := '0';
  constant alct_to_start    : std_logic                         := '0';
  constant otmb_to_end      : std_logic                         := '0';
  constant otmb_to_start    : std_logic                         := '0';
  constant dcfeb_to_end     : std_logic_vector(NFEB downto 1)   := (others => '0');
  constant dcfeb_to_start   : std_logic_vector(NFEB downto 1)   := (others => '0');
  constant data_fifo_full   : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  constant data_fifo_half   : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  constant dmb_l1pipe       : std_logic_vector(7 downto 0)      := (others => '0');

  signal GEMPTY_TMP : std_logic;        --Adam Add initialization


begin

  cafifo_l1a_dav_corr(NFEB downto 1) <= cafifo_l1a_dav(NFEB downto 1) xnor cafifo_l1a_match(NFEB downto 1);

  GEMPTY_TMP <= and_reduce(cafifo_l1a_dav(9 downto 8)) when (cafifo_l1a_match(9) = '1' and cafifo_l1a_match(8) = '1') else
                cafifo_l1a_dav(9) when (cafifo_l1a_match(9) = '1' and cafifo_l1a_match(8) = '0') else
                cafifo_l1a_dav(8) when (cafifo_l1a_match(9) = '0' and cafifo_l1a_match(8) = '1') else
                and_reduce(cafifo_l1a_dav_corr(NFEB downto 1)) and or_reduce(cafifo_l1a_match(NFEB downto 1));

--  Generate BUSY (page 1)
--  FDC(GEMPTY, CLKCMS, POP, GEMPTY_D(1));
  FDC_GEN_BUSY1 : FDC port map (GEMPTY_D(1), CLKCMS, POP, GEMPTY_TMP);
  FDCE_GEN_BUSY : FDCE port map (GEMPTY_D(2), CLK, GLRFD, POP, GEMPTY_D(1));
  FDC_GEN_BUSY2 : FDC port map (GEMPTY_D(3), CLK, POP, GEMPTY_D(2));
  FDC_GEN_BUSY3 : FDC port map (BUSY, CLK, POP, GEMPTY_D(3));

-- Generate OEHDR (page 1)
  STARTREAD_RST <= RST or OEHDR(1);
  FDC_OEHDR_LOGICH : FDC port map (STARTREAD, BUSY, STARTREAD_RST, LOGICH);
  FDC_OEHDR_START  : FDC port map (OEHDR(1), CLK, RST, STARTREAD);
  FDC_OEHDR1       : FDC port map (OEHDR(2), CLK, RST, OEHDR(1));
  FDC_OEHDR2       : FDC port map (OEHDR(3), CLK, RST, OEHDR(2));
  FDC_OEHDR_GEN    : for i in 3 to 7 generate
  begin
    FDC_OEHDR : FDC port map (OEHDR(i+1), CLK, POP, OEHDR(i));
  end generate FDC_OEHDR_GEN;

-- Generate OEHDRA / Generata OEHDRB (page 1)
  OEHDRA <= OEHDR(1) or OEHDR(2) or OEHDR(3) or OEHDR(4);
  OEHDRB <= OEHDR(5) or OEHDR(6) or OEHDR(7) or OEHDR(8);

-- Generate DOHDR (new)
  DOHDR <= OEHDRA or OEHDRB;

-- Generate OKDATA / Generate DODAT (page 1)
  TAIL_RST     <= RST or TAIL(1);
  DDCNT_EN_RST <= RST or OKDATA;        -- modified!
--  DDCNT_EN_RST <= RST or EODATA;
  FDCE_OKDATA   : FDCE port map (DDCNT_EN(0), CLK, OEHDR(8), TAIL_RST, BUSY);
  FDC_LOGICH    : FDC port map (DDCNT_EN(1), DDCNT_EN(0), DDCNT_EN_RST, LOGICH);
  --Adam CB16CE_OKDATA : CB16CE port map (DDCNT_CEO, DDCNT, DDCNT_TC, CLK, DDCNT_EN(1), TAIL_RST);
  CB16CE_OKDATA : CB16CE port map (open, DDCNT, DDCNT_TC, CLK, DDCNT_EN(1), TAIL_RST);
--  OKDATA <= DDCNT(8) and DDCNT(7) and DDCNT(6); -- modified!
  OKDATA       <= '1' when DDCNT(2 downto 0) = "100" else '0';  -- modified by G&M
--  DATAON <= not (DDCNT(8) and DDCNT(7) and DDCNT(6)); -- modified!
  FDC_OKDATA    : FDC port map (DODAT, CLK, TAIL(1), OKDATA);
--  EODATA <= not DATAON; -- modified!
--  FDC(DATAON, CLK, TAIL(1), DODAT); -- modified!

-- Generate TAIL (page 1)
  STARTTAIL_CE <= '1' when (BUSY = '1' and (R(NFEB+2 downto 1) = ZERO9)) else '0';
  FDCE_TAIL     : FDCE port map (STARTTAIL, CLK, STARTTAIL_CE, TAIL(1), DODAT);
  FDC_STARTTAIL : FDC port map (TAIL(1), CLK, RST, STARTTAIL);
  FDC_TAIL1     : FDC port map (TAIL(2), CLK, RST, TAIL(1));
  FDC_TAIL_GEN  : for i in 2 to 7 generate
  begin
    FDC_TAIL : FDC port map (TAIL(i+1), CLK, POP, TAIL(i));
  end generate FDC_TAIL_GEN;

-- Generate TAILA / Generate TAILB (page 1)
  TAILA <= TAIL(1) or TAIL(2) or TAIL(3) or TAIL(4);
  TAILB <= TAIL(5) or TAIL(6) or TAIL(7) or TAIL(8);

-- Generate DOTAIL (new)
  DOTAIL <= TAILA or TAILB;

-- Generate DAV (page 1)
  DAV_D <= (DATA_AVAIL or OEHDTL) and not DISDAV;
  FDC_DAV : FDC port map (DAV, CLK, POP, DAV_D);
--  FDC(DAV_D2, CLK, POP, DAV_D3);
--  DAV <= DAV_D1 and DAV_D2 and DAV_D3;

-- Generate POP (page 1)
  FDC_TAILDONE : FDC port map (TAILDONE, CLK, POP, TAIL(8));
  L1ONLY <= '1' when (OEHDR(4) = '1' and cafifo_l1a_match = ZERO9) else '0';
  STPOP  <= TAILDONE or L1ONLY;
  FDC_POP      : FDC port map (POP_D(1), STPOP, POP, LOGICH);
  FDC_POP_GEN  : for i in 1 to 3 generate
  begin
    FDC_POP_D : FDC port map (POP_D(i+1), CLK, RST, POP_D(i));
  end generate FDC_POP_GEN;
  POP <= RST or POP_D(4);

-- Generate FIFO_POP (page 1)
  FIFO_POP_RST <= FIFO_POP_INNER or RST;
  FDC_FIFO_POP_D     : FDC port map (FIFO_POP_D, STPOP, FIFO_POP_RST, LOGICH);
  FDC_FIFO_POP_INNER : FDC port map (FIFO_POP_INNER, CLKCMS, RST, FIFO_POP_D);
  FIFO_POP     <= FIFO_POP_INNER;


---------------------- PAGE 2 ----------------------  

-- Generate OEHDTL (page 2)
  OEHDTL_D <= DOHDR or DOTAIL;
  FDC_OEHDTL : FDC port map (OEHDTL, CLK, RST, OEHDTL_D);

-- Generate FENDAVERR (page 2)
--  FENDAV <= not KILL(NFEB+2 downto 1) and FIFO_L1A_MATCH(NFEB+2 downto 1);
  --Adam FENDAV <= not KILL and cafifo_l1a_match; --used only to assigned unused fendaverr
  --Adam FENDAVERR <= or_reduce(FENDAV); --not used

-- Generate HDR_W (new, page 2)
--  HDR_W1 <= x"9" & L1CNT(11 downto 0);
--  HDR_W2 <= x"9" & L1CNT(23 downto 12);
--  HDR_W3 <= x"9" & FIFO_L1A_MATCH(0) & FIFO_L1A_MATCH(16 downto 11) & FIFO_L1A_MATCH(5 downto 1);
--  HDR_W4 <= x"9" & BXN(11 downto 0);
--  HDR_W5 <= x"A" & FIFO_L1A_MATCH(0) & FENDAVERR & FIFO_L1A_MATCH(16) & FENDAVERR & FIFO_L1A_MATCH(0) & FENDAVERR & FIFO_L1A_MATCH(16) & FIFO_L1A_MATCH(5 downto 1);
--  HDR_W6 <= x"A" & DAQMBID(11 downto 0);
--  HDR_W7 <= x"A" & FIFO_L1A_MATCH(10 downto 6) & BXN(6 downto 0);
--  HDR_W8 <= x"A" & CFEBBX(3 downto 0) & L1CNT(7 downto 0);

  HDR_W1 <= x"9" & cafifo_l1a_cnt(11 downto 0);
  HDR_W2 <= x"9" & cafifo_l1a_cnt(23 downto 12);
  HDR_W3 <= x"9" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & fmt_vers & l1a_dav_mismatch & cafifo_l1a_match(NFEB downto 1);
  HDR_W4 <= x"9" & cafifo_bx_cnt;
  HDR_W5 <= x"A" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & fmt_vers & l1a_dav_mismatch & cafifo_l1a_match(NFEB downto 1);
  HDR_W6 <= x"A" & DAQMBID(11 downto 0);
  HDR_W7 <= x"A" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & ovlp & cafifo_bx_cnt(4 downto 0);
  HDR_W8 <= x"A" & sync & fmt_vers & l1a_dav_mismatch & cafifo_l1a_cnt(4 downto 0);


-- Multiplex HDR_W (new, page 2)
  DATA_HDR <= HDR_W1 when OEHDR(1) = '1' else
              HDR_W2 when OEHDR(2) = '1' else
              HDR_W3 when OEHDR(3) = '1' else
              HDR_W4 when OEHDR(4) = '1' else
              HDR_W5 when OEHDR(5) = '1' else
              HDR_W6 when OEHDR(6) = '1' else
              HDR_W7 when OEHDR(7) = '1' else
              HDR_W8 when OEHDR(8) = '1' else
              (others => '0');


-- Generate TAIL_W (new, page 2)
--  TAIL_W1 <= x"F" & BXN(3 downto 0) & L1CNT(7 downto 0);
--  TAIL_W2 <= x"F" & FIFO_L1A_MATCH(10 downto 6) & NSTAT(40 downto 34);
--  TAIL_W3 <= x"F" & STATUS(14 downto 7) & NSTAT(26 downto 25) & DAVNODATA(7 downto 6);
--  TAIL_W4 <= x"F" & DATANOEND(5 downto 1) & DATANOEND(7 downto 6) & DAVNODATA(5 downto 1);
--  TAIL_W5 <= x"E" & NSTAT(33 downto 27) & NSTAT(24 downto 20);
--  TAIL_W6 <= x"E" & DAQMBID(11 downto 0);
--  TAIL_W7 <= x"E" & REG_CRC(22) & REG_CRC(10 downto 0);
--  TAIL_W8 <= x"E" & REG_CRC(23) & REG_CRC(21 downto 11);

  TAIL_W1 <= x"F" & alct_to_end & cafifo_bx_cnt(4 downto 0) & cafifo_l1a_cnt(5 downto 0);
  TAIL_W2 <= x"F" & ovlp & dcfeb_to_end;
  TAIL_W3 <= x"F" & data_fifo_full(3 downto 1) & otmb_to_start & dmb_l1pipe;
  TAIL_W4 <= x"F" & alct_to_start & dcfeb_to_start & data_fifo_full(7 downto 4);
  TAIL_W5 <= x"E" & data_fifo_full(NFEB+2 downto NFEB+1) & data_fifo_half(NFEB+2 downto NFEB+1) & otmb_to_end & data_fifo_half(NFEB downto 1);
  TAIL_W6 <= x"E" & DAQMBID(11 downto 0);
--  TAIL_W7 <= x"E" & REG_CRC(22) & REG_CRC(10 downto 0);
--  TAIL_W8 <= x"E" & REG_CRC(23) & REG_CRC(21 downto 11);

-- Multiplex TAIL_W (new, page 2)
  DATA_TAIL <= TAIL_W1 when TAIL(1) = '1' else
               TAIL_W2 when TAIL(2) = '1' else
               TAIL_W3 when TAIL(3) = '1' else
               TAIL_W4 when TAIL(4) = '1' else
               TAIL_W5 when TAIL(5) = '1' else
               TAIL_W6 when TAIL(6) = '1' else
--               TAIL_W7 when TAIL(7)='1' else
--               TAIL_W8 when TAIL(8)='1' else
               (others => '0');


-- Generate GLRFD (page 3)
  FDCE_GLRFD : FDCE port map (GLRFD, CLK, GIGAEN, RST, LOGICH);

-- Generate RDY (page 3)
  RDY_CE <= not FIFORDY;
  GEN_RDY : for K in 1 to NFEB+2 generate
  begin
    FD_1_RDY : FD_1 port map (FIFORDY(K), CLK, FFOR_B(K));
    FDCE_RDY : FDCE port map (RDY(K), CLK, RDY_CE(K), POP, DODAT);
  end generate GEN_RDY;

-- Generate DISDAV (page 3)
  P_AND_FIFORDY <= P and FIFORDY;
--  DISDAV_D <= (P_AND_FIFORDY(1) or P_AND_FIFORDY(2) or P_AND_FIFORDY(3) or P_AND_FIFORDY(4) or P_AND_FIFORDY(5) or P_AND_FIFORDY(6) or P_AND_FIFORDY(7));
  DISDAV_D      <= or_reduce(P_AND_FIFORDY);
-- One extra clock cycle to align DAV with DOUT
--  FD(DISDAV_D, CLK, DISDAV);
  FD_DISDAV_D  : FD port map (DISDAV_DD, CLK, DISDAV_D);
  FD_DISDAV_DD : FD port map (DISDAV, CLK, DISDAV_DD);

-- Generate R (page 4)
  R_RST <= DONE_VEC or ERRORD;
  GEN_R : for K in 1 to NFEB+2 generate
  begin
    FDC_R : FDC port map (R(K), BUSY, R_RST(K), cafifo_l1a_match(K));
  end generate GEN_R;

-- Generate P (page 4, LUT)
  P(1) <= '1' when (R(9 downto 8) = "00" and R(1) = '1' and DODAT = '1')              else '0';
  P(2) <= '1' when (R(9 downto 8) = "00" and R(2 downto 1) = "10" and DODAT='1')      else '0';
  P(3) <= '1' when (R(9 downto 8) = "00" and R(3 downto 1) = "100" and DODAT='1')     else '0';
  P(4) <= '1' when (R(9 downto 8) = "00" and R(4 downto 1) = "1000" and DODAT='1')    else '0';
  P(5) <= '1' when (R(9 downto 8) = "00" and R(5 downto 1) = "10000" and DODAT='1')   else '0';
  P(6) <= '1' when (R(9 downto 8) = "00" and R(6 downto 1) = "100000" and DODAT='1')  else '0';
  P(7) <= '1' when (R(9 downto 8) = "00" and R(7 downto 1) = "1000000" and DODAT='1') else '0';
  P(8) <= '1' when (R(9 downto 8) = "01" and DODAT = '1') else '0';
  P(9) <= '1' when (R(9) = '1' and DODAT = '1')                                       else '0';

-- Generate OE (page 4)
  OE <= P and RDY;

-- Generate OEALL / Generate DOEALL / Generate OEDATA (page 4)
  OEALL_D <= or_reduce(OE);
  POPLAST <= POP or LAST;
  FDC_OEALL     : FDC port map (OEALL, CLK, POPLAST, OEALL_D);
  FDC_OEDATA    : FDC port map(OEDATA_D, CLK, POP, OEALL);
  FDC_DOEALL    : FDC port map(DOEALL, CLK, POPLAST, OEALL);
-- One extra clock cycle to align DAV with DOUT
  FDC_OEDATA_D  : FDC port map (OEDATA_DD, CLK, POP, OEDATA_D);
  FDC_OEDATA_DD : FDC port map (OEDATA, CLK, POP, OEDATA_DD);

  -- Generate OEDATA_DAV (removes two clock cycles for DCFEB data)
  FDC_OEDATA_DAV0 : FDC port map (OEDATA_DAV(0), CLK, POP, OEDATA);
  FDC_OEDATA_DAV1 : FDC port map (OEDATA_DAV(1), CLK, POP, OEDATA_DAV(0));
  DATA_AVAIL <= OEDATA when and_reduce(OEFIFO_B_INNER(9 downto 8)) = '0' else
                OEDATA_DAV(1) and OEDATA_DAV(0) and OEDATA;


-- Generate JRDFF (page 4)
  FDC_JRDFF  : FDC port map (JRDFF_D, RDFFNXT, JRDFF, LOGICH);
  FDC_JRDFFD : FDC port map (JRDFF, CLK, RST, JRDFF_D);


-- Generate DONE_VEC (page 5)
  GEN_DONE_VEC : for K in 1 to NFEB+2 generate
  begin
    FDC_DONE_VEC : FDC port map (OE_Q(K), DONE, POP, OE(K));
    DONE_VEC(K) <= POP or OE_Q(K);
  end generate GEN_DONE_VEC;


-- Generate RENFIFO_B (page 5)
  GEN_RENFIFO_B : for K in 1 to NFEB+2 generate
  begin
    FDC_RENFIFO_B : FDC port map (OOE(K), CLK, DONE_VEC(K), OE(K));
    RENFIFO_B_D(K) <= '0' when (JREF(K) = '1' or (OOE(K) = '1' and LAST = '0')) else '1';
    FDP_RENFIFO_B : FDP port map (RENFIFO_B(K), CLK, RENFIFO_B_D(K), POP);
  end generate GEN_RENFIFO_B;


-- Generate OEFIFO_B (page 5)
  GEN_OENFIFO_B : for K in 1 to NFEB+2 generate
  begin
    OEFIFO_B_D_D_D(K) <= '0' when (JOEF(K) = '1' or OOE(K) = '1') else '1';  -- Delayed 1.5 clock cycles to fix problem with last
    OEFIFO_B_PRE(K)   <= POP or DONE_VEC(K);
    FDP_1_OEFIFO_B_D_D : FDP_1 port map(OEFIFO_B_D_D(K), CLK, OEFIFO_B_D_D_D(K), OEFIFO_B_PRE(K));
    FDP_1_OEFIFO_B_D   : FDP_1 port map(OEFIFO_B_D(K), CLK, OEFIFO_B_D_D(K), OEFIFO_B_PRE(K));
    FDP_OEFIFO_B       : FDP port map (OEFIFO_B_INNER(K), CLK, OEFIFO_B_D(K), OEFIFO_B_PRE(K));
    OEFIFO_B(K)       <= OEFIFO_B_INNER(K);
  end generate GEN_OENFIFO_B;

  -- Generate DOUT (page 6)
  GEN_DOUT : for K in 0 to 15 generate
  begin
    IFD_1_DATA_A : IFD_1 port map(DATA_A(K), CLK, DATAIN(K));
    --IFD_1(DATAIN(K), CLK, DATA_A(K));
    FD_DOUT      : FD port map (DATA_C(K), CLK, DATA_B(K));
    FDC_DOUT     : FDC port map (DOUT(K), CLK, RST, DATA_D(K));
  end generate GEN_DOUT;
  DATA_B <= DATA_A when (DODAT = '1') else
            DATA_HDR  when (DOHDR = '1') else
            DATA_TAIL when (DOTAIL = '1');
  DATA_D <= DATA_CRC when (DTAIL78 = '1') else DATA_C;


-- Generate DONE / Generate LAST (new, page 6)
  FDCE_1_DONE : FDCE_1 port map (LAST, CLK, DOEALL, LAST_RST, DATAIN_LAST);
  FD_LAST     : FD port map (LAST_TMP, CLK, LAST);
  FD_1_LAST   : FD_1 port map (LAST_TMP_1, CLK, LAST);
  FD_DONE     : FD port map (DONE, CLK, LAST_TMP);
  FD_1_DONE   : FD_1 port map (LAST_RST, CLK, LAST_TMP_1);


-- Generate DAVNODATA / Generate DATANOEND / Generate ERRORD (page 7)
  DAVNODATA_D <= R and FIFORDY;
  GEN_ERRORD : for K in 1 to NFEB+2 generate
  begin
    FDC_DAVNODATA  : FDC port map (DAVNODATA(K), DODAT, POP, DAVNODATA_D(K));
    FDCE_DATANOEND : FDCE port map (DATANOEND(K), CLKCMS, RSTCNT, POP, OE(K));
  end generate GEN_ERRORD;
  ERRORD    <= DAVNODATA or DATANOEND;
  NOEND_RST <= DONE or STARTREAD or RSTCNT;
  CB16CE_DATANOEND : CB16CE port map(NOEND_CEO, NOEND, NOEND_TC, CLKCMS, OEALL, NOEND_RST);
  FD_NOEND         : FD port map (RSTCNT, CLKCMS, NOEND(11));


-- Generate REG_CRC (page 7)
  CRC(4 downto 0) <= REG_CRC(20 downto 16);
  CRC(5)          <= DATA_C(0) xor REG_CRC(0) xor REG_CRC(21);
  CRC(6)          <= DATA_C(0) xor DATA_C(1) xor REG_CRC(0) xor REG_CRC(1);
  CRC(7)          <= DATA_C(1) xor DATA_C(2) xor REG_CRC(1) xor REG_CRC(2);
  CRC(8)          <= DATA_C(2) xor DATA_C(3) xor REG_CRC(2) xor REG_CRC(3);
  CRC(9)          <= DATA_C(3) xor DATA_C(4) xor REG_CRC(3) xor REG_CRC(4);
  CRC(10)         <= DATA_C(4) xor DATA_C(5) xor REG_CRC(4) xor REG_CRC(5);
  CRC(11)         <= DATA_C(5) xor DATA_C(6) xor REG_CRC(5) xor REG_CRC(6);
  CRC(12)         <= DATA_C(6) xor DATA_C(7) xor REG_CRC(6) xor REG_CRC(7);
  CRC(13)         <= DATA_C(7) xor DATA_C(8) xor REG_CRC(7) xor REG_CRC(8);
  CRC(14)         <= DATA_C(8) xor DATA_C(9) xor REG_CRC(8) xor REG_CRC(9);
  CRC(15)         <= DATA_C(9) xor DATA_C(10) xor REG_CRC(9) xor REG_CRC(10);
  CRC(16)         <= DATA_C(10) xor DATA_C(11) xor REG_CRC(10) xor REG_CRC(11);
  CRC(17)         <= DATA_C(11) xor DATA_C(12) xor REG_CRC(11) xor REG_CRC(12);
  CRC(18)         <= DATA_C(12) xor DATA_C(13) xor REG_CRC(12) xor REG_CRC(13);
  CRC(19)         <= DATA_C(13) xor DATA_C(14) xor REG_CRC(13) xor REG_CRC(14);
  CRC(20)         <= DATA_C(14) xor DATA_C(15) xor REG_CRC(14) xor REG_CRC(15);
  CRC(21)         <= DATA_C(15) xor REG_CRC(15);
  CRC(22)         <= CRC(0) xor CRC(1) xor CRC(2) xor CRC(3) xor CRC(4) xor CRC(5) xor CRC(6) xor CRC(7) xor CRC(8) xor CRC(9) xor CRC(10);
  CRC(23)         <= CRC(11) xor CRC(12) xor CRC(13) xor CRC(14) xor CRC(15) xor CRC(16) xor CRC(17) xor CRC(18) xor CRC(19) xor CRC(20) xor CRC(21);

  GEN_REG_CRC : for K in 0 to 23 generate
  begin
    FDCE_REG_CRC : FDCE port map (REG_CRC(K), CLK, CRCEN, OEHDR(1), CRC(K));
  end generate GEN_REG_CRC;

  TAIL78  <= TAIL(7) or TAIL(8);
  FD_DTAIL78 : FD port map (DTAIL78, CLK, TAIL78);
  FD_DTAIL7  : FD port map (DTAIL7, CLK, TAIL(7));
  FD_DTAIL8  : FD port map (DTAIL8, CLK, DTAIL7);
  CRCEN_D <= OEHDRA or OEHDRB or TAILA;
  FDC_CRCEN  : FDC port map (CRCEN_Q, CLK, RST, CRCEN_D);
  CRCEN   <= CRCEN_Q or DATA_AVAIL;

  DATA_CRC(10 downto 0) <= REG_CRC(10 downto 0) when (DTAIL7 = '1') else
                           REG_CRC(21 downto 11) when (DTAIL8 = '1') else
                           (others => '0');
  DATA_CRC(11) <= REG_CRC(22) when (DTAIL7 = '1') else
                  REG_CRC(23) when (DTAIL8 = '1') else
                  '0';
  DATA_CRC(15 downto 12) <= x"E";

-- End Of Frame to DDUFIFO
  FD_EOF : FD port map (EOF, CLK, DTAIL8);

-- Generate JREF (page 8)
  GEN_JREF : for K in 1 to NFEB+2 generate
  begin
    FDE_JREF : FDE port map (JREF(K), CLK, JOEF(K), JRDFF);
  end generate GEN_JREF;


end CONTROL_arch;
