-- TRGCNTRL: Applies LCT_L1A_DLY to RAW_LCT[7:1] to sync it with L1A and produce L1A_MATCH[7:1]
-- It also generates the PUSH that load the FIFOs/RAM in TRGFIFO

library unisim;
library ieee;
library work;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

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
    KILLCFEB  : in std_logic_vector(NFEB downto 1);

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

  signal JCALSEL, CAL_MODE    : std_logic;
  signal DLY_LCT, LCT, LCT_IN : std_logic_vector(NFEB downto 0);
  signal RAW_L1A_Q, L1A_IN    : std_logic;
  signal L1A                  : std_logic;
  type LCT_TYPE is array (NFEB downto 0) of std_logic_vector(4 downto 0);
  signal LCT_Q                : LCT_TYPE;
  signal LCT_ERR_D            : std_logic;
  signal L1A_MATCH            : std_logic_vector(NFEB downto 0);

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
    LCT(K) <= '0' when (KILLCFEB(K) = '1') else
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

-- Generate DCFEB_L1A_MATCH / Generate FIFO_L1A_MATCH (We might add PUSHDLY to FIFO_L1A_MATCH later)
  GEN_L1A_MATCH : for K in 1 to NFEB generate
  begin
    LCT_Q(K)(0) <= LCT(K);
    GEN_LCT_Q : for H in 1 to 4 generate
    begin
      FD_H : FD port map(LCT_Q(K)(H), CLK, LCT_Q(K)(H-1));
    end generate GEN_LCT_Q;
    L1A_MATCH(K) <= '1' when (L1A = '1' and LCT_Q(K) /= "00000") else '0';
  end generate GEN_L1A_MATCH;
  L1A_MATCH(0)    <= or_reduce(L1A_MATCH(NFEB downto 1));
  DCFEB_L1A_MATCH <= L1A_MATCH(NFEB downto 1);


-- Generate FIFO_PUSH
--  FDPUSH : FD port map(FIFO_PUSH, CLK, L1A);
  SRL16_PUSH : SRL16 port map(FIFO_PUSH, PUSH_DLY(0), PUSH_DLY(1), PUSH_DLY(2), PUSH_DLY(3), CLK, L1A);

--  FIFO_L1A_MATCH  <= L1A_MATCH;

-- Generate PUSH_DLY
  GEN_L1A_MATCH_PUSH_DLY : for K in 0 to NFEB generate
  begin
    SRL16_K : SRL16 port map(FIFO_L1A_MATCH(K), PUSH_DLY(0), PUSH_DLY(1), PUSH_DLY(2), PUSH_DLY(3), CLK, L1A_MATCH(K));
  end generate GEN_L1A_MATCH_PUSH_DLY;

-- Generate OTMB_PUSH_DLY
  SRL16_OTMB : SRL16 port map(FIFO_L1A_MATCH(NFEB+1), OTMB_PUSH_DLY(0), OTMB_PUSH_DLY(1), OTMB_PUSH_DLY(2), OTMB_PUSH_DLY(3), CLK, OTMB_DAV);

-- Generate ALCT_PUSH_DLY
  SRL16_ALCT : SRL16 port map(FIFO_L1A_MATCH(NFEB+2), ALCT_PUSH_DLY(0), ALCT_PUSH_DLY(1), ALCT_PUSH_DLY(2), ALCT_PUSH_DLY(3), CLK, ALCT_DAV);

end TRGCNTRL_Arch;
