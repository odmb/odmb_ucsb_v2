-- TRGCNTRL: Applies LCT_L1A_DLY to RAW_LCT[7:1] to sync it with L1A and produce L1A_MATCH[7:1]
-- It also generates the PUSH that load the FIFOs/RAM in TRGFIFO

library unisim;
library ieee;
library work;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity TRGCNTRL is
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
    OTMB_DAV      : in std_logic;
    ALCT_PUSH_DLY : in std_logic_vector(4 downto 0);
    OTMB_PUSH_DLY : in std_logic_vector(4 downto 0);

    JTRGEN    : in std_logic_vector(3 downto 0);
    EAFEB     : in std_logic;
    CMODE     : in std_logic;
    CALTRGSEL : in std_logic;
    KILL      : in std_logic_vector(NFEB+2 downto 1);
    PEDESTAL  : in std_logic;
    PEDESTAL_OTMB  : in std_logic;

    L1A_OTMB_PUSHED_OUT : out std_logic;
    OTMB_DAV_SYNC_OUT   : out std_logic;

    DCFEB_L1A       : out std_logic;
    DCFEB_L1A_MATCH : out std_logic_vector(NFEB downto 1);
    FIFO_PUSH       : out std_logic;
    FIFO_L1A_MATCH  : out std_logic_vector(NFEB+2 downto 0);
    LCT_ERR         : out std_logic
    );

end TRGCNTRL;

architecture TRGCNTRL_Arch of TRGCNTRL is
  component LCTDLY is  -- Aligns RAW_LCT with L1A by 2.4 us to 4.8 us
    port (
      DIN   : in std_logic;
      CLK   : in std_logic;
      DELAY : in std_logic_vector(5 downto 0);

      DOUT : out std_logic
      );
  end component;

  constant logich : std_logic := '1';

  signal JCALSEL, CAL_MODE    : std_logic;
  signal DLY_LCT, LCT, LCT_IN : std_logic_vector(NFEB downto 0);
  signal RAW_L1A_Q, L1A_IN    : std_logic;
  signal L1A                  : std_logic;
  type   LCT_TYPE is array (NFEB downto 0) of std_logic_vector(4 downto 0);
  signal LCT_Q                : LCT_TYPE;
  signal LCT_ERR_D            : std_logic;
  signal L1A_MATCH            : std_logic_vector(NFEB downto 1);
  signal FIFO_L1A_MATCH_INNER            : std_logic_vector(NFEB+2 downto 0);

  signal l1a_push                        : std_logic;
  signal l1a_match_push                  : std_logic_vector(NFEB downto 0);
  signal OTMB_ALCT_DLY                   : std_logic_vector(4 downto 0);
  signal otmb_dav_sync, alct_dav_sync    : std_logic;
  signal l1a_otmb_pushed, l1a_otmb_match : std_logic;
  signal fifo_push_inner                 : std_logic;

begin  --Architecture

-- Generate CAL_MODE / Generate JCALSEL
  CAL_MODE <= CMODE and CALTRGSEL;
  JCALSEL  <= JTRGEN(0) and CAL_MODE;

-- Generate DLY_LCT
  LCT_IN <= CAL_LCT when (JCALSEL = '1') else RAW_LCT;
  GEN_DLY_LCT : for K in 0 to NFEB generate
  begin
    LCTDLY_K : LCTDLY port map(LCT_IN(K), CLK, LCT_L1A_DLY, DLY_LCT(K));
  end generate GEN_DLY_LCT;

-- Generate LCT
--  LCT(0) <= CAL_LCT(0) when (JCALSEL = '1') else DLY_LCT(0);
  LCT(0) <= DLY_LCT(0);
  GEN_LCT : for K in 1 to nfeb generate
  begin
    LCT(K) <= '0' when (KILL(K) = '1') else
--              LCT(0)     when (EAFEB = '1' and CAL_MODE = '0') else
--              CAL_LCT(K) when (JCALSEL = '1') else
              DLY_LCT(K);
  end generate GEN_LCT;

-- Generate LCT_ERR
  LCT_ERR_D <= LCT(0) xor or_reduce(LCT(NFEB downto 1));
  FDLCTERR : FD port map(LCT_ERR, CLK, LCT_ERR_D);

-- Generate L1A / Generate DCFEB_L1A
  L1A_IN <= CAL_L1A when (JTRGEN(1) = '1' and CAL_MODE = '1') else RAW_L1A;

  FDL1A : FD port map(RAW_L1A_Q, CLK, L1A_IN);
--  L1A       <= CAL_L1A when (JTRGEN(1) = '1' and CAL_MODE = '1') else RAW_L1A_Q;
  L1A       <= RAW_L1A_Q;
  DCFEB_L1A <= L1A;

-- Generate DCFEB_L1A_MATCH
  GEN_L1A_MATCH : for K in 1 to NFEB generate
  begin
    LCT_Q(K)(0) <= LCT(K);
    GEN_LCT_Q : for H in 1 to 4 generate
    begin
      FD_H : FD port map(LCT_Q(K)(H), CLK, LCT_Q(K)(H-1));
    end generate GEN_LCT_Q;
    L1A_MATCH(K) <= '1' when (L1A = '1' and KILL(K)='0' and (LCT_Q(K) /= "00000" or PEDESTAL = '1'))  else '0';
  end generate GEN_L1A_MATCH;
  DCFEB_L1A_MATCH <= L1A_MATCH(NFEB downto 1);


-- Generate FIFO_PUSH, FIFO_L1A_MATCH - All signals are pushed a total of ALCT_PUSH_DLY
  L1APUSH       : SRLC32E port map(l1a_push, open, push_dly, logich, clk, l1a);
  L1A_ALCT_PUSH : SRLC32E port map(fifo_push_inner, open, alct_push_dly, logich, clk, l1a_push);

  FIFO_PUSH <= fifo_push_inner;
 
  GEN_L1A_MATCH_PUSH_DLY : for K in 1 to NFEB generate
  begin
    L1AMATCHPUSH   : SRLC32E port map(l1a_match_push(K), open, push_dly, logich, clk, l1a_match(K));
    L1A_MATCH_ALCT : SRLC32E port map(fifo_l1a_match_inner(K), open, alct_push_dly, logich, clk, l1a_match_push(K));
  end generate GEN_L1A_MATCH_PUSH_DLY;

  OTMBDAV_FD     : FD port map(otmb_dav_sync, clk, otmb_dav);
  otmb_alct_dly  <= std_logic_vector(unsigned(alct_push_dly) - unsigned(otmb_push_dly)-1);
  L1A_OTMB_PUSH  : SRLC32E port map(l1a_otmb_pushed, open, otmb_push_dly, logich, clk, l1a_push);
  l1a_otmb_match <= (otmb_dav_sync or pedestal_otmb) and l1a_otmb_pushed and not kill(NFEB+1);
  OTMB_ALCT_PUSH : SRLC32E port map(fifo_l1a_match_inner(NFEB+1), open, otmb_alct_dly, logich, clk, l1a_otmb_match);

  ALCTDAV_FD : FD port map(alct_dav_sync, clk, alct_dav);
  fifo_l1a_match_inner(NFEB+2) <= (alct_dav_sync or pedestal_otmb) and fifo_push_inner and not kill(NFEB+2);

  fifo_l1a_match_inner(0)    <= or_reduce(fifo_l1a_match_inner(NFEB+2 downto 1));
  fifo_l1a_match    <= fifo_l1a_match_inner;

  l1a_otmb_pushed_out <= l1a_otmb_pushed;
  otmb_dav_sync_out   <= otmb_dav_sync;

end TRGCNTRL_Arch;
