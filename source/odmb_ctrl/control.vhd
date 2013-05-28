library IEEE;
library work;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_misc.all;

--Library UNISIM;
--use UNISIM.all;

--use UNISIM.vcomponents.all;
--use UNISIM.vpck.all;
use work.Latches_Flipflops.all;

entity CONTROL is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );  
  port (

    RST : in std_logic;
    CLKCMS : in std_logic;
    CLK    : in std_logic;
    STATUS : in std_logic_vector(47 downto 0);
    L1ARST    : in std_logic;

-- From DMB_VME
    RDFFNXT : in std_logic;


-- from TRGFIFO
--    BXN     : in std_logic_vector(11 downto 0);
--    GEMPTY  : in std_logic;
--    CFEBBX  : in std_logic_vector(3 downto 0);
--    FIFO_L1A_MATCH  : in std_logic_vector(NFEB+2 downto 0);
--    DAVENBL : in std_logic_vector(5 downto 1);

-- to GigaBit Link
    DOUT : out std_logic_vector(15 downto 0);
    DAV  : out std_logic;

-- to FIFOs
    OEFIFO_B  : out std_logic_vector(NFEB+2 downto 1);
    RENFIFO_B : out std_logic_vector(NFEB+2 downto 1);
    OEFFMON_B  : out std_logic_vector(NFEB+2 downto 1);
    RENFFMON_B : out std_logic_vector(NFEB+2 downto 1);

-- from FIFOs
    FFOR_B : in std_logic_vector(NFEB+2 downto 1);
    DATAIN  : in std_logic_vector(15 downto 0);
    DATAIN_LAST : in std_logic;

-- From CONFREGS
    KILLINPUT : in std_logic_vector(NFEB+2 downto 1);

-- From JTAGCOM
    SETLOOPBACK : in std_logic;
    JOEF        : in std_logic_vector(NFEB+2 downto 1);

-- to ???
    DAQMBID : in std_logic_vector(11 downto 0); -- From CRATEID in SETFEBDLY, and GA
    LOOPBACK : out std_logic;
    OEOVLP  : out std_logic;

-- FROM SW1
    GIGAEN : in std_logic;

-- TO CAFIFO
    FIFO_POP : out std_logic;
    
-- TO DDUFIFO
    EOF : out std_logic;
    
-- FROM CAFIFO
    cafifo_l1a_dav : in std_logic_vector(NFEB+2 downto 1);
    cafifo_l1a_match : in std_logic_vector(NFEB+2 downto 1);
    cafifo_l1a_cnt : in std_logic_vector(23 downto 0);
    cafifo_bx_cnt : in std_logic_vector(11 downto 0)
    );
end CONTROL;

architecture CONTROL_arch of CONTROL is
  signal LOGICL : std_logic := '0';
  signal LOGICH : std_logic := '1';
  signal ZERO7 : std_logic_vector(6 downto 0) := (others => '0');
  signal ZERO8 : std_logic_vector(7 downto 0) := (others => '0');
  signal ZERO9 : std_logic_vector(8 downto 0) := (others => '0');
  signal ZERO10 : std_logic_vector(9 downto 0) := (others => '0');
  
-- PAGE 1
  signal BUSY : std_logic;
  signal GEMPTY_D : std_logic_vector(3 downto 1);
  
  signal STARTREAD_RST, STARTREAD : std_logic := '0';
  signal OEHDR : std_logic_vector(8 downto 1) := (others => '0');
  signal OEHDRA, OEHDRB : std_logic := '0';
  signal DOHDR : std_logic := '0';
  signal TAIL_RST, DDCNT_EN_RST, DDCNT_CEO, DDCNT_TC, OKDATA, DODAT : std_logic := '0';
  signal DDCNT_EN : std_logic_vector(1 downto 0);
  signal DDCNT : std_logic_vector(15 downto 0);

  signal STARTTAIL_CE, STARTTAIL : std_logic := '0';
  signal TAIL : std_logic_vector(8 downto 1);
  signal TAILA, TAILB : std_logic := '0';
  signal DOTAIL : std_logic := '0';

  signal DAV_D : std_logic := '0';
  signal DAV_D1,DAV_D2,DAV_D3 : std_logic := '0';

  signal POP_D : std_logic_vector(4 downto 1);
  signal TAILDONE, STPOP, L1ONLY, POP: std_logic := '0';

  signal FIFO_POP_RST, FIFO_POP_INNER, FIFO_POP_D : std_logic;
  
-- PAGE 2
  signal OEHDTL, OEHDTL_D : std_logic;
  signal FENDAV : std_logic_vector(NFEB+2 downto 1);
  signal FENDAVERR : std_logic;

  signal DATA_HDR, DATA_TAIL : std_logic_vector(15 downto 0);
  
  signal HEAD_D12 :  std_logic;
  signal HDR_W1, HDR_W2, HDR_W3, HDR_W4, HDR_W5, HDR_W6, HDR_W7, HDR_W8 : std_logic_vector(15 downto 0);
  signal TAIL_W1, TAIL_W2, TAIL_W3, TAIL_W4, TAIL_W5, TAIL_W6, TAIL_W7, TAIL_W8 : std_logic_vector(15 downto 0);

-- PAGE 3 
  signal GLRFD : std_logic;
  signal L1CNT_RST, L1CNT_CEO_L, L1CNT_TC_L, L1CNT_CEO_H, L1CNT_TC_H : std_logic;
  signal L1CNT : std_logic_vector(23 downto 0);
  
  signal RDY_CE, RDY, FIFORDY : std_logic_vector(NFEB+2 downto 1);
  
  signal P_AND_FIFORDY : std_logic_vector(NFEB+2 downto 1);
  signal DISDAV, DISDAV_D, DISDAV_DD : std_logic;
  
  signal LOOPBACK_Q, LOOPBACK_Q_B : std_logic;
  
-- PAGE 4
  signal R, R_RST : std_logic_vector(NFEB+2 downto 1);
  signal P : std_logic_vector(NFEB+2 downto 1);
  signal OE : std_logic_vector(NFEB+2 downto 1);
  signal DOEALL, OEALL, OEALL_D, OEDATA, OEDATA_D, OEDATA_DD, POPLAST : std_logic;
  signal OEDATA_DAV : std_logic_vector(2 downto 0);
  signal JRDFF, JRDFF_D : std_logic;
  signal EODATA, DATAON : std_logic;
    
-- PAGE 5
  signal DONE_VEC, OE_Q : std_logic_vector(NFEB+2 downto 1);
  signal OOE, RENFIFO_B_D : std_logic_vector(NFEB+2 downto 1);
  signal OEFIFO_B_D, OEFIFO_B_PRE : std_logic_vector(NFEB+2 downto 1);
  signal OEFIFO_B_D_D, OEFIFO_B_D_D_D : std_logic_vector(NFEB+2 downto 1);

-- PAGE 6
  signal DATA_A, DATA_B, DATA_C, DATA_D : std_logic_vector(15 downto 0):=(others=>'0');
  signal DONE, LAST_RST : std_logic;
  signal LAST : std_logic := '0';

-- PAGE 7
  signal DATANOEND, DAVNODATA, DAVNODATA_D, ERRORD : std_logic_vector(NFEB+2 downto 1);
  signal NOEND_RST, NOEND_CEO, NOEND_TC, RSTCNT : std_logic;
  signal NOEND : std_logic_vector(15 downto 0);
  signal CRC, REG_CRC : std_logic_vector(23 downto 0) := (others => '0');
  signal CRCEN, CRCEN_D, CRCEN_Q : std_logic;
  signal DATA_CRC : std_logic_vector(15 downto 0);
  signal TAIL78, DTAIL78, DTAIL7, DTAIL8 : std_logic;
    
-- PAGE 8
  signal JREF : std_logic_vector(NFEB+2 downto 1);

-- PAGE 10
  signal KILL : std_logic_vector(NFEB+2 downto 1);
  signal NSTAT : std_logic_vector(40 downto 20);
  signal STATUS_Q : std_logic_vector(33 downto 27);

  signal ver : std_logic_vector(1 downto 0) := "00";
  signal l1a_dav_mismatch : std_logic := '0';
  signal ovlp : std_logic_vector(5 downto 1) := "00000";
  signal sync : std_logic_vector(3 downto 0) := "0000";
  signal alct_to_end : std_logic := '0';
  signal alct_to_start : std_logic := '0';
  signal tmb_to_end : std_logic := '0';
  signal tmb_to_start : std_logic := '0';
  signal dcfeb_to_end : std_logic_vector(NFEB downto 1) := (OTHERS => '0');
  signal dcfeb_to_start : std_logic_vector(NFEB downto 1) := (OTHERS => '0');
  signal data_fifo_full : std_logic_vector(NFEB+2 downto 1) := (OTHERS => '0');
  signal data_fifo_half : std_logic_vector(NFEB+2 downto 1) := (OTHERS => '0');
  signal dmb_l1pipe : std_logic_vector(7 downto 0) := (OTHERS => '0');
  signal GEMPTY_TMP : std_logic;
  signal DATAIN_LAST_TMP : std_logic;

begin
  
--  DAV <= 'L';

  
  GEMPTY_TMP <= and_reduce(cafifo_l1a_dav(9 downto 8)) when (cafifo_l1a_match(9) = '1' and cafifo_l1a_match(8) = '1') else
                cafifo_l1a_dav(9) when (cafifo_l1a_match(9) = '1' and cafifo_l1a_match(8) = '0') else
                cafifo_l1a_dav(8) when (cafifo_l1a_match(9) = '0' and cafifo_l1a_match(8) = '1') else
                or_reduce(cafifo_l1a_dav(NFEB downto 1));
--  GEMPTY_TMP <= or_reduce(cafifo_l1a_dav);
  --GEMPTY_TMP <= cafifo_l1a_dav)(8) or cafifo_l1a_dav(9);
  
  DATAIN_LAST_TMP <= '1' when (DATAIN(11 downto 0) = "000000001000") else '0';
  
--  Generate BUSY (page 1)
--  FDC(GEMPTY, CLKCMS, POP, GEMPTY_D(1));
  FDC(GEMPTY_TMP, CLKCMS, POP, GEMPTY_D(1));
  FDCE(GEMPTY_D(1), CLK, GLRFD, POP, GEMPTY_D(2));
  FDC(GEMPTY_D(2), CLK, POP, GEMPTY_D(3));
  FDC(GEMPTY_D(3), CLK, POP, BUSY);

-- Generate OEHDR (page 1)
  STARTREAD_RST <= RST or OEHDR(1);
  FDC(LOGICH, BUSY, STARTREAD_RST, STARTREAD);
  FDC(STARTREAD, CLK, RST, OEHDR(1));
  FDC(OEHDR(1), CLK, RST, OEHDR(2));
  FDC(OEHDR(2), CLK, RST, OEHDR(3));
  FDC(OEHDR(3), CLK, POP, OEHDR(4));
  FDC(OEHDR(4), CLK, POP, OEHDR(5));
  FDC(OEHDR(5), CLK, POP, OEHDR(6));
  FDC(OEHDR(6), CLK, POP, OEHDR(7));
  FDC(OEHDR(7), CLK, POP, OEHDR(8));

-- Generate OEHDRA / Generata OEHDRB (page 1)
  OEHDRA <= OEHDR(1) or OEHDR(2) or OEHDR(3) or OEHDR(4);
  OEHDRB <= OEHDR(5) or OEHDR(6) or OEHDR(7) or OEHDR(8);

-- Generate DOHDR (new)
  DOHDR <= OEHDRA or OEHDRB;

-- Generate OKDATA / Generate DODAT (page 1)
  TAIL_RST <= RST or TAIL(1);
  DDCNT_EN_RST <= RST or OKDATA; -- modified!
--  DDCNT_EN_RST <= RST or EODATA;
  FDCE(BUSY, CLK, OEHDR(8), TAIL_RST, DDCNT_EN(0));
  FDC(LOGICH, DDCNT_EN(0), DDCNT_EN_RST, DDCNT_EN(1));
  CB16CE(CLK, DDCNT_EN(1), TAIL_RST, DDCNT, DDCNT, DDCNT_CEO, DDCNT_TC);
--  OKDATA <= DDCNT(8) and DDCNT(7) and DDCNT(6); -- modified!
  OKDATA <= '1' when DDCNT(2 downto 0) = "100" else '0'; -- modified by G&M
--  DATAON <= not (DDCNT(8) and DDCNT(7) and DDCNT(6)); -- modified!
  FDC(OKDATA, CLK, TAIL(1), DODAT);
--  EODATA <= not DATAON; -- modified!
--  FDC(DATAON, CLK, TAIL(1), DODAT); -- modified!
  
-- Generate TAIL (page 1)
  STARTTAIL_CE <= '1' when (BUSY='1' and (R(NFEB+2 downto 1) = ZERO9)) else '0';
  FDCE(DODAT, CLK, STARTTAIL_CE, TAIL(1), STARTTAIL);
  FDC(STARTTAIL, CLK, RST, TAIL(1));
  FDC(TAIL(1), CLK, RST, TAIL(2));
  FDC(TAIL(2), CLK, POP, TAIL(3));
  FDC(TAIL(3), CLK, POP, TAIL(4));
  FDC(TAIL(4), CLK, POP, TAIL(5));
  FDC(TAIL(5), CLK, POP, TAIL(6));
  FDC(TAIL(6), CLK, POP, TAIL(7));
  FDC(TAIL(7), CLK, POP, TAIL(8));

-- Generate TAILA / Generate TAILB (page 1)
  TAILA <= TAIL(1) or TAIL(2) or TAIL(3) or TAIL(4);
  TAILB <= TAIL(5) or TAIL(6) or TAIL(7) or TAIL(8);
  
-- Generate DOTAIL (new)
  DOTAIL <= TAILA or TAILB;
  
-- Generate DAV (page 1)
  DAV_D <= (OEDATA_DAV(2) or OEHDTL) and not DISDAV;
  FDC(DAV_D, CLK, POP, DAV);
--  FDC(DAV_D2, CLK, POP, DAV_D3);
--  DAV <= DAV_D1 and DAV_D2 and DAV_D3;
    
-- Generate POP (page 1)
  FDC(TAIL(8), CLK, POP, TAILDONE);
  L1ONLY <= '1' when (OEHDR(4)='1' and cafifo_l1a_match = ZERO9) else '0';
  STPOP <= TAILDONE or L1ONLY;
  FDC(LOGICH, STPOP, POP, POP_D(1));
  FDC(POP_D(1), CLK, RST, POP_D(2));
  FDC(POP_D(2), CLK, RST, POP_D(3));
  FDC(POP_D(3), CLK, RST, POP_D(4));
  POP <= RST or POP_D(4);
  
-- Generate FIFO_POP (page 1)
  FIFO_POP_RST <= FIFO_POP_INNER or RST;
  FDC(LOGICH, STPOP, FIFO_POP_RST, FIFO_POP_D);
  FDC(FIFO_POP_D, CLKCMS, RST, FIFO_POP_INNER);
  FIFO_POP <= FIFO_POP_INNER;
  
  
---------------------- PAGE 2 ----------------------  

-- Generate OEHDTL (page 2)
  OEHDTL_D <= DOHDR or DOTAIL;
  FDC(OEHDTL_D, CLK, RST, OEHDTL);   

-- Generate HEAD_D12 (page 2)
  HEAD_D12 <= or_reduce(cafifo_l1a_match);

-- Generate FENDAVERR (page 2)
--  FENDAV <= not KILLINPUT(NFEB+2 downto 1) and FIFO_L1A_MATCH(NFEB+2 downto 1);
  FENDAV <= not KILL and cafifo_l1a_match;
  FENDAVERR <= or_reduce(FENDAV);

-- Generate HDR_W (new, page 2)
--  HDR_W1 <= "100" & HEAD_D12 & L1CNT(11 downto 0);
--  HDR_W2 <= "100" & HEAD_D12 & L1CNT(23 downto 12);
--  HDR_W3 <= "100" & HEAD_D12 & FIFO_L1A_MATCH(0) & FIFO_L1A_MATCH(16 downto 11) & FIFO_L1A_MATCH(5 downto 1);
--  HDR_W4 <= "100" & HEAD_D12 & BXN(11 downto 0);
--  HDR_W5 <= "1010" & FIFO_L1A_MATCH(0) & FENDAVERR & FIFO_L1A_MATCH(16) & FENDAVERR & FIFO_L1A_MATCH(0) & FENDAVERR & FIFO_L1A_MATCH(16) & FIFO_L1A_MATCH(5 downto 1);
--  HDR_W6 <= "1010" & DAQMBID(11 downto 0);
--  HDR_W7 <= "1010" & FIFO_L1A_MATCH(10 downto 6) & BXN(6 downto 0);
--  HDR_W8 <= "1010" & CFEBBX(3 downto 0) & L1CNT(7 downto 0);

  HDR_W1 <= "100" & HEAD_D12 & cafifo_l1a_cnt(11 downto 0);
  HDR_W2 <= "100" & HEAD_D12 & cafifo_l1a_cnt(23 downto 12);
  HDR_W3 <= "100" & HEAD_D12 & cafifo_l1a_match(NFEB+2 downto NFEB+1) & ver & l1a_dav_mismatch & cafifo_l1a_match(NFEB downto 1);
  HDR_W4 <= "100" & HEAD_D12 & cafifo_bx_cnt;
  HDR_W5 <= "1010" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & ver & l1a_dav_mismatch & cafifo_l1a_match(NFEB downto 1);
  HDR_W6 <= "1010" & DAQMBID(11 downto 0);
  HDR_W7 <= "1010" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & ovlp & cafifo_bx_cnt(4 downto 0);
  HDR_W8 <= "1010" & sync & ver & l1a_dav_mismatch & cafifo_l1a_cnt(4 downto 0);


-- Multiplex HDR_W (new, page 2)
  DATA_HDR <= HDR_W1 when OEHDR(1)='1' else
              HDR_W2 when OEHDR(2)='1' else
              HDR_W3 when OEHDR(3)='1' else
              HDR_W4 when OEHDR(4)='1' else
              HDR_W5 when OEHDR(5)='1' else
              HDR_W6 when OEHDR(6)='1' else
              HDR_W7 when OEHDR(7)='1' else
              HDR_W8 when OEHDR(8)='1' else
   (others => '0');


-- Generate TAIL_W (new, page 2)
--  TAIL_W1 <= "1111" & BXN(3 downto 0) & L1CNT(7 downto 0);
--  TAIL_W2 <= "1111" & FIFO_L1A_MATCH(10 downto 6) & NSTAT(40 downto 34);
--  TAIL_W3 <= "1111" & STATUS(14 downto 7) & NSTAT(26 downto 25) & DAVNODATA(7 downto 6);
--  TAIL_W4 <= "1111" & DATANOEND(5 downto 1) & DATANOEND(7 downto 6) & DAVNODATA(5 downto 1);
--  TAIL_W5 <= "1110" & NSTAT(33 downto 27) & NSTAT(24 downto 20);
--  TAIL_W6 <= "1110" & DAQMBID(11 downto 0);
--  TAIL_W7 <= "1110" & REG_CRC(22) & REG_CRC(10 downto 0);
--  TAIL_W8 <= "1110" & REG_CRC(23) & REG_CRC(21 downto 11);

  TAIL_W1 <= "1111" & alct_to_end & cafifo_bx_cnt(4 downto 0) & cafifo_l1a_cnt(5 downto 0);
  TAIL_W2 <= "1111" & ovlp & dcfeb_to_end;
  TAIL_W3 <= "1111" & data_fifo_full(3 downto 1) & tmb_to_start & dmb_l1pipe;
  TAIL_W4 <= "1111" & alct_to_start & dcfeb_to_start & data_fifo_full(7 downto 4);
  TAIL_W5 <= "1110" & data_fifo_full(NFEB+2 downto NFEB+1) & data_fifo_half(NFEB+2 downto NFEB+1) & tmb_to_end & data_fifo_half(NFEB downto 1);
  TAIL_W6 <= "1110" & DAQMBID(11 downto 0);
--  TAIL_W7 <= "1110" & REG_CRC(22) & REG_CRC(10 downto 0);
--  TAIL_W8 <= "1110" & REG_CRC(23) & REG_CRC(21 downto 11);

-- Multiplex TAIL_W (new, page 2)
  DATA_TAIL <= TAIL_W1 when TAIL(1)='1' else
               TAIL_W2 when TAIL(2)='1' else
               TAIL_W3 when TAIL(3)='1' else
               TAIL_W4 when TAIL(4)='1' else
               TAIL_W5 when TAIL(5)='1' else
               TAIL_W6 when TAIL(6)='1' else
--               TAIL_W7 when TAIL(7)='1' else
--               TAIL_W8 when TAIL(8)='1' else
    (others => '0');


-- Generate GLRFD (page 3)
  FDCE(LOGICH, CLK, GIGAEN, RST, GLRFD);

-- Generate L1CNT (page 3)
  L1CNT_RST <= RST or L1ARST;
  CB16CE(STARTREAD, LOGICH, L1CNT_RST, L1CNT(15 downto 0), L1CNT(15 downto 0), L1CNT_CEO_L, L1CNT_TC_L);
  CB8CE(STARTREAD, L1CNT_CEO_L, L1CNT_RST, L1CNT(23 downto 16), L1CNT(23 downto 16), L1CNT_CEO_H, L1CNT_TC_H);

-- Generate RDY (page 3)
  RDY_CE <= not FIFORDY;
  GEN_RDY : for K in 1 to NFEB+2 generate
  begin
    FD_1(FFOR_B(K), CLK, FIFORDY(K));
    FDCE(DODAT, CLK, RDY_CE(K), POP, RDY(K));
  end generate GEN_RDY;
  
-- Generate DISDAV (page 3)
  P_AND_FIFORDY <= P and FIFORDY;
--  DISDAV_D <= (P_AND_FIFORDY(1) or P_AND_FIFORDY(2) or P_AND_FIFORDY(3) or P_AND_FIFORDY(4) or P_AND_FIFORDY(5) or P_AND_FIFORDY(6) or P_AND_FIFORDY(7));
  DISDAV_D <= or_reduce(P_AND_FIFORDY);
-- One extra clock cycle to align DAV with DOUT
--  FD(DISDAV_D, CLK, DISDAV);
  FD(DISDAV_D, CLK, DISDAV_DD);
  FD(DISDAV_DD, CLK, DISDAV);
  
  -- Generate LOOPBACK (page 3)
  LOOPBACK_Q_B <= not LOOPBACK_Q;
  FDC(LOOPBACK_Q_B, SETLOOPBACK, RST, LOOPBACK_Q);
  LOOPBACK <= LOOPBACK_Q and not BUSY;

-- Generate R (page 4)
  R_RST <= DONE_VEC or ERRORD;   
  GEN_R : for K in 1 to NFEB+2 generate
  begin
    FDC(cafifo_l1a_match(K), BUSY, R_RST(K), R(K));
  end generate GEN_R;
  
-- Generate P (page 4, LUT)
--  P(1) <= '1' when (R(7 downto 6)="00" and R(1)='1' and DODAT='1') else '0';
--  P(2) <= '1' when (R(7 downto 6)="00" and R(2 downto 1)="10" and DODAT='1') else '0';
--  P(3) <= '1' when (R(7 downto 6)="00" and R(3 downto 1)="100" and DODAT='1') else '0';
--  P(4) <= '1' when (R(7 downto 6)="00" and R(4 downto 1)="1000" and DODAT='1') else '0';
--  P(5) <= '1' when (R(7 downto 6)="00" and R(5 downto 1)="10000" and DODAT='1') else '0';
--  P(6) <= '1' when (R(7 downto 6)="01" and DODAT='1') else '0';
--  P(7) <= '1' when (R(7)='1' and DODAT='1') else '0';
  P(1) <= '1' when (R(9 downto 8)="00" and R(1)='1' and DODAT='1') else '0';
  P(2) <= '1' when (R(9 downto 8)="00" and R(2 downto 1)="10" and DODAT='1') else '0';
  P(3) <= '1' when (R(9 downto 8)="00" and R(3 downto 1)="100" and DODAT='1') else '0';
  P(4) <= '1' when (R(9 downto 8)="00" and R(4 downto 1)="1000" and DODAT='1') else '0';
  P(5) <= '1' when (R(9 downto 8)="00" and R(5 downto 1)="10000" and DODAT='1') else '0';
  P(6) <= '1' when (R(9 downto 8)="00" and R(6 downto 1)="100000" and DODAT='1') else '0';
  P(7) <= '1' when (R(9 downto 8)="00" and R(7 downto 1)="1000000" and DODAT='1') else '0';
  P(8) <= '1' when (R(9 downto 8)="01" and DODAT='1') else '0';
  P(9) <= '1' when (R(9)='1' and DODAT='1') else '0';

-- Generate OE (page 4)
  OE <= P and RDY;

-- Generate OEALL / Generate DOEALL / Generate OEDATA (page 4)
--  OEALL_D <= OE(1) or OE(2) or OE(3) or OE(4) or OE(5) or OE(6) or OE(7);
  OEALL_D <= or_reduce(OE);
  POPLAST <= POP or LAST;
  FDC(OEALL_D, CLK, POPLAST, OEALL);
  FDC(OEALL, CLK, POP, OEDATA_D);
  FDC(OEALL, CLK, POPLAST, DOEALL);
-- One extra clock cycle to align DAV with DOUT
--  FDC(OEDATA_D, CLK, POP, OEDATA);
  FDC(OEDATA_D, CLK, POP, OEDATA_DD); 
  FDC(OEDATA_DD, CLK, POP, OEDATA);
  
  -- Generate OEDATA_DAV (removes two clock cycles and shifts another)
   FDC(OEDATA, CLK, POP, OEDATA_DAV(0));
   FDC(OEDATA_DAV(0), CLK, POP, OEDATA_DAV(1));
   OEDATA_DAV(2) <= OEDATA_DAV(1) and OEDATA_DAV(0) and OEDATA and OEDATA_DD;
 
  
-- Generate JRDFF (page 4)
  FDC(LOGICH, RDFFNXT, JRDFF, JRDFF_D);
  FDC(JRDFF_D, CLK, RST, JRDFF);
  
  
-- Generate DONE_VEC (page 5)
  GEN_DONE_VEC: for K in 1 to NFEB+2 generate
  begin
    FDC(OE(K), DONE, POP, OE_Q(K));
    DONE_VEC(K) <= POP or OE_Q(K);
  end generate GEN_DONE_VEC;


-- Generate RENFIFO_B (page 5)
  GEN_RENFIFO_B: for K in 1 to NFEB+2 generate
  begin
    FDC(OE(K), CLK, DONE_VEC(K), OOE(K));
    RENFIFO_B_D(K) <= '0' when (JREF(K)='1' or (OOE(K)='1' and LAST='0')) else '1';
    FDP(RENFIFO_B_D(K), CLK, POP, RENFIFO_B(K));
--    FDC(OE(K), CLK, DONE_VEC(K), OOE(K));
--    RENFIFO_B(K) <= '0' when (JREF(K)='1' or (OOE(K)='1' and LAST='0')) else '1';
----    FDP(RENFIFO_B_D(K), CLK, POP, RENFIFO_B(K));
  end generate GEN_RENFIFO_B;


-- Generate OEFIFO_B (page 5)
  GEN_OENFIFO_B: for K in 1 to NFEB+2 generate
  begin
--    OEFIFO_B_D(K) <= '0' when (JOEF(K)='1' or OOE(K)='1') else '1'; -- In original design
    OEFIFO_B_D_D_D(K) <= '0' when (JOEF(K)='1' or OOE(K)='1') else '1'; -- Delayed 1.5 clock cycles to fix problem with last
    OEFIFO_B_PRE(K) <= POP or DONE_VEC(K);
--    FDP_1(OEFIFO_B_D(K), CLK, OEFIFO_B_PRE(K), OEFIFO_B(K));  -- In original design 
    FDP_1(OEFIFO_B_D_D_D(K), CLK, OEFIFO_B_PRE(K), OEFIFO_B_D_D(K));  -- Delayed 1.5 clock cycles to fix problem with last
    FDP_1(OEFIFO_B_D_D(K), CLK, OEFIFO_B_PRE(K), OEFIFO_B_D(K));  -- Delayed 1.5 clock cycles to fix problem with last
    FDP(OEFIFO_B_D(K), CLK, OEFIFO_B_PRE(K), OEFIFO_B(K));      --- Delayed 1.5 clock cycles to fix problem with last
--    OEFIFO_B_D(K) <= '0' when (JOEF(K)='1' or OE(K)='1') else '1';
--    OEFIFO_B_PRE(K) <= POP or DONE_VEC(K);
--    FDP_1(OEFIFO_B_D(K), CLK, OEFIFO_B_PRE(K), OEFIFO_B(K));
  end generate GEN_OENFIFO_B;

  -- Generate DOUT (page 6)
  GEN_DOUT : for K in 0 to 15 generate
  begin
    IFD_1(DATAIN(K), CLK, DATA_A(K));
    FD(DATA_B(K), CLK, DATA_C(K));    
    FDC(DATA_D(K), CLK, RST, DOUT(K));
  end generate GEN_DOUT;
  DATA_B <= DATA_A    when (DODAT='1') else 
            DATA_HDR  when (DOHDR='1') else
            DATA_TAIL when (DOTAIL='1');
  DATA_D <= DATA_CRC when (DTAIL78='1') else DATA_C;


-- Generate DONE / Generate LAST (new, page 6)
  FDCE_1(DATAIN_LAST, CLK, DOEALL, LAST_RST, LAST);
--  FDCE_1(DATAIN_LAST_TMP, CLK, DOEALL, LAST_RST, LAST);
  FD(LAST, CLK, DONE);
  FD_1(LAST, CLK, LAST_RST);

  
  
-- Generate DAVNODATA / Generate DATANOEND / Generate ERRORD (page 7)
  DAVNODATA_D <= R and FIFORDY;
  GEN_ERRORD : for K in 1 to NFEB+2 generate
  begin
    FDC(DAVNODATA_D(K), DODAT, POP, DAVNODATA(K));
    FDCE(OE(K), CLKCMS, RSTCNT, POP, DATANOEND(K));
  end generate GEN_ERRORD;
  ERRORD <= DAVNODATA or DATANOEND;
  NOEND_RST <= DONE or STARTREAD or RSTCNT;    
  CB16CE(CLKCMS, OEALL, NOEND_RST, NOEND, NOEND, NOEND_CEO, NOEND_TC);
  FD(NOEND(11), CLKCMS, RSTCNT);
  
  
-- Generate REG_CRC (page 7)
  CRC(4 downto 0) <= REG_CRC(20 downto 16);
  CRC(5) <= DATA_C(0) xor REG_CRC(0) xor REG_CRC(21);
  CRC(6) <= DATA_C(0) xor DATA_C(1) xor REG_CRC(0) xor REG_CRC(1);
  CRC(7) <= DATA_C(1) xor DATA_C(2) xor REG_CRC(1) xor REG_CRC(2);
  CRC(8) <= DATA_C(2) xor DATA_C(3) xor REG_CRC(2) xor REG_CRC(3);
  CRC(9) <= DATA_C(3) xor DATA_C(4) xor REG_CRC(3) xor REG_CRC(4);
  CRC(10) <= DATA_C(4) xor DATA_C(5) xor REG_CRC(4) xor REG_CRC(5);
  CRC(11) <= DATA_C(5) xor DATA_C(6) xor REG_CRC(5) xor REG_CRC(6);
  CRC(12) <= DATA_C(6) xor DATA_C(7) xor REG_CRC(6) xor REG_CRC(7);
  CRC(13) <= DATA_C(7) xor DATA_C(8) xor REG_CRC(7) xor REG_CRC(8);
  CRC(14) <= DATA_C(8) xor DATA_C(9) xor REG_CRC(8) xor REG_CRC(9);
  CRC(15) <= DATA_C(9) xor DATA_C(10) xor REG_CRC(9) xor REG_CRC(10);
  CRC(16) <= DATA_C(10) xor DATA_C(11) xor REG_CRC(10) xor REG_CRC(11);
  CRC(17) <= DATA_C(11) xor DATA_C(12) xor REG_CRC(11) xor REG_CRC(12);
  CRC(18) <= DATA_C(12) xor DATA_C(13) xor REG_CRC(12) xor REG_CRC(13);
  CRC(19) <= DATA_C(13) xor DATA_C(14) xor REG_CRC(13) xor REG_CRC(14);
  CRC(20) <= DATA_C(14) xor DATA_C(15) xor REG_CRC(14) xor REG_CRC(15);
  CRC(21) <= DATA_C(15) xor REG_CRC(15);
  CRC(22) <= CRC(0) xor CRC(1) xor CRC(2) xor CRC(3) xor CRC(4) xor CRC(5) xor CRC(6) xor CRC(7) xor CRC(8) xor CRC(9) xor CRC(10); 
  CRC(23) <= CRC(11) xor CRC(12) xor CRC(13) xor CRC(14) xor CRC(15) xor CRC(16) xor CRC(17) xor CRC(18) xor CRC(19) xor CRC(20) xor CRC(21); 

  GEN_REG_CRC : for K in 0 to 23 generate
  begin
    FDCE(CRC(K), CLK, CRCEN, OEHDR(1), REG_CRC(K));
  end generate GEN_REG_CRC;

  TAIL78 <= TAIL(7) or TAIL(8);
  FD(TAIL78, CLK, DTAIL78);
  FD(TAIL(7), CLK, DTAIL7);
  FD(DTAIL7, CLK, DTAIL8);
  CRCEN_D <= OEHDRA or OEHDRB or TAILA;
  FDC(CRCEN_D, CLK, RST, CRCEN_Q);
  CRCEN <= '1' when (((CRCEN_Q or OEDATA_DD) = '1') and DISDAV_DD='0') else '0';
  DATA_CRC(10 downto 0) <= REG_CRC(10 downto 0) when (DTAIL7='1') else 
                           REG_CRC(21 downto 11) when (DTAIL8='1') else
                           (others => '0');
  DATA_CRC(11) <= REG_CRC(22) when (DTAIL7='1') else 
                  REG_CRC(23) when (DTAIL8='1') else
                  '0';
  DATA_CRC(15 downto 12) <= "1110";

-- End Of Frame to DDUFIFO
  FD(DTAIL8, CLK, EOF);
  
-- Generate JREF (page 8)
  GEN_JREF : for K in 1 to NFEB+2 generate
  begin
    FDE(JRDFF, CLK, JOEF(K), JREF(K));
  end generate GEN_JREF;


-- Generate KILL signals (page 10)
--  KILL <= KILLINPUT;
--  KILL(1) <= '1' when (KILLINPUT(2 downto 0)="001") else '0'; -- KILLALCT
--  KILL(2) <= '1' when (KILLINPUT(2 downto 0)="010") else '0'; -- KILLTMB
--  KILL(3) <= '1' when (KILLINPUT(2 downto 0)="011") else '0'; -- KILLCFEB1
--  KILL(4) <= '1' when (KILLINPUT(2 downto 0)="100") else '0'; -- KILLCFEB2
--  KILL(5) <= '1' when (KILLINPUT(2 downto 0)="101") else '0'; -- KILLCFEB3
--  KILL(6) <= '1' when (KILLINPUT(2 downto 0)="110") else '0'; -- KILLCFEB4
--  KILL(7) <= '1' when (KILLINPUT(2 downto 0)="111") else '0'; -- KILLCFEB5
  KILL <= KILLINPUT;

-- Generate NSTAT(40 downto 34) - Half full KILL logic (page 10)
  NSTAT(40) <= KILL(1) or STATUS(40);
  NSTAT(39) <= KILL(2) or STATUS(39);
  NSTAT(38 downto 34) <= KILL(7 downto 3) or STATUS(38 downto 34);

-- Generate NSTAT(26 downto 20) - Empty KILL logic (page 10)
  NSTAT(26) <= KILL(1) or STATUS(26);
  NSTAT(25) <= KILL(2) or STATUS(25);
  NSTAT(24 downto 20) <= KILL(7 downto 3) or STATUS(24 downto 20);

-- Generate NSTAT(33 downto 27) - Full KILL logic (page 10)
  FDCE(STATUS(33), CLK, STATUS(33), STATUS(40), STATUS_Q(33));
  FDCE(STATUS(32), CLK, STATUS(32), STATUS(39), STATUS_Q(32));
  FDCE(STATUS(31), CLK, STATUS(31), STATUS(38), STATUS_Q(31));
  FDCE(STATUS(30), CLK, STATUS(30), STATUS(37), STATUS_Q(30));
  FDCE(STATUS(29), CLK, STATUS(29), STATUS(36), STATUS_Q(29));
  FDCE(STATUS(28), CLK, STATUS(28), STATUS(35), STATUS_Q(28));
  FDCE(STATUS(27), CLK, STATUS(27), STATUS(34), STATUS_Q(27));
  NSTAT(33) <= not KILL(1) and STATUS_Q(33);
  NSTAT(32) <= not KILL(2) and STATUS_Q(32);
  NSTAT(31 downto 27) <= not KILL(7 downto 3) and STATUS(31 downto 27);







end CONTROL_arch;
