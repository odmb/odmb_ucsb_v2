-- TESTFIFOS: Reads test FIFOs written with DCFEB data

library ieee;
library work;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TESTFIFOS is
  
  port (

    SLOWCLK : in std_logic;
    RST     : in std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    TFF_DATA_OUT : in std_logic_vector(15 downto 0);
    TFF_WRD_CNT  : in std_logic_vector(11 downto 0);

    TFF_SEL   : out std_logic_vector(8 downto 1);
    RD_EN_TFF : out std_logic_vector(8 downto 1)
    );
end TESTFIFOS;



architecture TESTFIFOS_Arch of TESTFIFOS is

  signal DTACK_INNER : std_logic;
  signal CMDDEV      : std_logic_vector(15 downto 0);

  type FIFO_RD_TYPE is array (3 downto 0) of std_logic_vector(8 downto 1);
  signal FIFO_RD : FIFO_RD_TYPE;
  signal C_FIFO_RD   : std_logic_vector(8 downto 1) := (others => '0');
  signal OUT_TFF_READ   : std_logic_vector(15 downto 0) := (others => '0');
  signal R_TFF_READ, D_R_TFF_READ, Q_R_TFF_READ : std_logic := '0';

  signal OUT_TFF_WRD_CNT   : std_logic_vector(15 downto 0) := (others => '0');
  signal R_TFF_WRD_CNT, D_R_TFF_WRD_CNT, Q_R_TFF_WRD_CNT : std_logic := '0';

  signal OUT_TFF_SEL   : std_logic_vector(15 downto 0) := (others => '0');
  signal TFF_SEL_INNER : std_logic_vector(8 downto 1)  := (others => '0');
  signal TFF_SEL_CODE  : std_logic_vector(2 downto 0)  := (others => '0');

  signal W_TFF_SEL, D_W_TFF_SEL, Q_W_TFF_SEL : std_logic := '0';
  signal R_TFF_SEL, D_R_TFF_SEL, Q_R_TFF_SEL : std_logic := '0';

begin  --Architecture

  
-- Decode instruction
  CMDDEV <= "000" & DEVICE & COMMAND & "00";  -- Variable that looks like the VME commands we input  

  R_TFF_READ    <= '1' when (CMDDEV = x"1000") else '0';
  R_TFF_WRD_CNT <= '1' when (CMDDEV = x"100C") else '0';
  W_TFF_SEL     <= '1' when (CMDDEV = x"1010") else '0';
  R_TFF_SEL     <= '1' when (CMDDEV = x"1014") else '0';

-- Read TFF_READ
  GEN_TFF_READ : for I in 1 to 8 generate
  begin
    FIFO_RD(0)(I) <= R_TFF_READ and TFF_SEL_INNER(I);
    FDC_RD_EN1 : FDC port map(FIFO_RD(1)(I), STROBE,  C_FIFO_RD(I), FIFO_RD(0)(I));
    FDC_RD_EN2 : FDC port map(FIFO_RD(2)(I), SLOWCLK, C_FIFO_RD(I), FIFO_RD(1)(I));
    FDC_RD_EN3 : FDC port map(FIFO_RD(3)(I), SLOWCLK, C_FIFO_RD(I), FIFO_RD(2)(I));
    C_FIFO_RD(I) <= RST or FIFO_RD(3)(I);
    RD_EN_TFF(I) <= FIFO_RD(2)(I);
  end generate GEN_TFF_READ;
  
  OUT_TFF_READ <= TFF_DATA_OUT when (STROBE = '1' and R_TFF_READ = '1') else (others => 'Z');

  D_R_TFF_READ <= '1' when (STROBE = '1' and R_TFF_READ = '1') else '0';
  FD_R_TFF_READ : FD port map(Q_R_TFF_READ, SLOWCLK, D_R_TFF_READ);
  DTACK_INNER     <= '0' when (Q_R_TFF_READ = '1')                else 'Z';

  

-- Read TFF_WRD_CNT
  OUT_TFF_WRD_CNT(11 downto 0) <= TFF_WRD_CNT when (STROBE = '1' and R_TFF_WRD_CNT = '1') else (others => 'Z');

  D_R_TFF_WRD_CNT <= '1' when (STROBE = '1' and R_TFF_WRD_CNT = '1') else '0';
  FD_R_TFF_WRD_CNT : FD port map(Q_R_TFF_WRD_CNT, SLOWCLK, D_R_TFF_WRD_CNT);
  DTACK_INNER     <= '0' when (Q_R_TFF_WRD_CNT = '1')                else 'Z';

-- Write TFF_SEL
  GEN_TFF_SEL : for I in 2 downto 0 generate
  begin
    FD_W_TFF_SEL : FDCE port map(TFF_SEL_CODE(I), STROBE, W_TFF_SEL, RST, INDATA(I));
  end generate GEN_TFF_SEL;
  TFF_SEL_INNER <= x"01" when TFF_SEL_CODE = "001" else
                   x"02" when TFF_SEL_CODE = "010" else
                   x"04" when TFF_SEL_CODE = "011" else
                   x"08" when TFF_SEL_CODE = "100" else
                   x"10" when TFF_SEL_CODE = "101" else
                   x"20" when TFF_SEL_CODE = "110" else
                   x"40" when TFF_SEL_CODE = "111" else
                   x"01";
  TFF_SEL     <= TFF_SEL_INNER;
  D_W_TFF_SEL <= '1' when (STROBE = '1' and W_TFF_SEL = '1') else '0';
  FD_DTACK_TFF_SEL : FD port map(Q_W_TFF_SEL, SLOWCLK, D_W_TFF_SEL);
  DTACK_INNER <= '0' when (Q_W_TFF_SEL = '1')                else 'Z';

-- Read TFF_SEL
  OUT_TFF_SEL(2 downto 0) <= TFF_SEL_CODE when (STROBE = '1' and R_TFF_SEL = '1') else (others => 'Z');

  D_R_TFF_SEL <= '1' when (STROBE = '1' and R_TFF_SEL = '1') else '0';
  FD_R_TFF_SEL : FD port map(Q_R_TFF_SEL, SLOWCLK, D_R_TFF_SEL);
  DTACK_INNER <= '0' when (Q_R_TFF_SEL = '1')                else 'Z';


-- General assignments
  OUTDATA <= OUT_TFF_READ when R_TFF_READ = '1' else
             OUT_TFF_SEL when R_TFF_SEL = '1' else
             OUT_TFF_WRD_CNT when R_TFF_WRD_CNT = '1' else
             (others => 'Z');
  DTACK <= DTACK_INNER;
  
end TESTFIFOS_Arch;
