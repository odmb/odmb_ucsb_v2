library unimacro;
library unisim;
library ieee;
library work;
use unimacro.vcomponents.all;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use work.hdlmacro.all;

entity TRGFIFO is
  generic (
    NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
    );  
  port (
    CLK         : in  std_logic;
    RST         : in  std_logic;
    PUSH        : in  std_logic;
    POP         : in  std_logic;
    BC0         : in  std_logic;
    BXRST       : in  std_logic;
    FIFO_L1A_MATCH_IN   : in  std_logic_vector(NFEB downto 0);
    
    FIFO_L1A_MATCH_OUT : out std_logic_vector(NFEB downto 0);
    FIFO_BX_CNT_OUT : out std_logic_vector(15 downto 0);
    FIFO_FULL_B : out std_logic;
    FIFO_EMPTY_B : out std_logic;
    FIFO_ERR    : out std_logic
    );
    
end TRGFIFO;

architecture TRGFIFO_Arch of TRGFIFO is

  signal LOGICH : std_logic := '1';
  signal BX_CNT_CLR, BX_CNT_A_TC, BX_CNT_B_TC, BX_CNT_A_CEO, BX_CNT_B_CEO: std_logic;
  signal BX_CNT, BX_CNT_INNER : std_logic_vector(15 downto 0);
  signal BX_ORBIT, BX_CNT_RST, BX_CNT_RST_RST : std_logic;
  signal FIFO_WR_EN, FIFO_RD_EN : std_logic;
  signal FIFO_L1A_MATCH_FULL, FIFO_L1A_MATCH_EMPTY : std_logic;
  signal FIFO_L1A_MATCH_RDCOUNT, FIFO_L1A_MATCH_WRCOUNT : std_logic_vector(10 downto 0); 
  signal FIFO_BX_CNT_FULL, FIFO_BX_CNT_EMPTY : std_logic;
  signal FIFO_BX_CNT_RDCOUNT, FIFO_BX_CNT_WRCOUNT : std_logic_vector(9 downto 0); 


begin  --Architecture

-- Generate BX_CNT (page 5)
  BX_CNT_CLR <= BC0 or BXRST or BX_CNT_RST;
  BX_CNT_A : CB16CE port map(BX_CNT_A_CEO, BX_CNT_INNER, BX_CNT_A_TC, CLK, LOGICH, BX_CNT_CLR);
  BX_CNT_B : CB4CE port map(BX_CNT_B_CEO, BX_CNT(15), BX_CNT(14), BX_CNT(13), BX_CNT(12), BX_CNT_B_TC, CLK, LOGICH, RST);
  BX_CNT(11 downto 0) <= BX_CNT_INNER(11 downto 0);

-- Generate BX_ORBIT (3563 bunch crossings) / Generate BX_CNT_RST (page 5)
--  BX_ORBIT <= '1' when (conv_integer(BX_CNT) = 3563) else '0';
-- 2048 + 1024 = 3072 + 256 = 3328 + 128 = 3456 + 64 = 3520 + 32 = 3552 + 11 = 3563
  BX_ORBIT <= '1' when (BX_CNT = "0000110111101011") else '0';
  FDCORBIT : FDC port map(BX_CNT_RST, CLK, BX_CNT_RST_RST, BX_ORBIT);
  FDBXRST  : FD port map(BX_CNT_RST_RST, CLK, BX_CNT_RST);

-- Generate FIFO_WR_EN / Generate FIFO_RD_EN
  FIFO_WR_EN <= PUSH and not FIFO_L1A_MATCH_FULL;
  FIFO_RD_EN <= POP and not FIFO_L1A_MATCH_EMPTY;
  FIFO_ERR   <= (PUSH and FIFO_L1A_MATCH_FULL) or (POP and FIFO_L1A_MATCH_EMPTY) or (FIFO_L1A_MATCH_EMPTY xor FIFO_BX_CNT_EMPTY) or (FIFO_L1A_MATCH_FULL xor FIFO_BX_CNT_FULL);

-- FIFO storing the L1A_MATCH information (page 1, used to be RAM)
  FIFO_L1A_MATCH_MOD : FIFO_SYNC_MACRO
    generic map (
      DEVICE              => "VIRTEX6",  -- Target Device: "VIRTEX5, "VIRTEX6" 
      ALMOST_FULL_OFFSET  => X"0080",   -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080",   -- Sets the almost empty threshold
      DATA_WIDTH          => NFEB+1,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE           => "18Kb")    -- Target BRAM, "18Kb" or "36Kb" 
    port map (
      ALMOSTEMPTY => open,              -- Output almost empty 
      ALMOSTFULL  => open,              -- Output almost full
      DO          => FIFO_L1A_MATCH_OUT,    -- Output data
      EMPTY       => FIFO_L1A_MATCH_EMPTY,  -- Output empty
      FULL        => FIFO_L1A_MATCH_FULL,   -- Output full
      RDCOUNT     => FIFO_L1A_MATCH_RDCOUNT,              -- Output read count
      RDERR       => open,              -- Output read error
      WRCOUNT     => FIFO_L1A_MATCH_WRCOUNT,              -- Output write count
      WRERR       => open,              -- Output write error
      CLK         => CLK,               -- Input clock
      DI          => FIFO_L1A_MATCH_IN,         -- Input data
      RDEN        => FIFO_RD_EN,        -- Input read enable
      RST         => RST,               -- Input reset
      WREN        => FIFO_WR_EN         -- Input write enable
      );

-- FIFO storing the bunch crossing information (page 1, used to be RAM)
  FIFO_BX_CNT_MOD : FIFO_SYNC_MACRO
    generic map (
      DEVICE              => "VIRTEX6",  -- Target Device: "VIRTEX5, "VIRTEX6" 
      ALMOST_FULL_OFFSET  => X"0080",   -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080",   -- Sets the almost empty threshold
      DATA_WIDTH          => 16,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE           => "18Kb")    -- Target BRAM, "18Kb" or "36Kb" 
    port map (
      ALMOSTEMPTY => open,              -- Output almost empty 
      ALMOSTFULL  => open,              -- Output almost full
      DO          => FIFO_BX_CNT_OUT,       -- Output data
      EMPTY       => FIFO_BX_CNT_EMPTY,     -- Output empty
      FULL        => FIFO_BX_CNT_FULL,      -- Output full
      RDCOUNT     => FIFO_BX_CNT_RDCOUNT,              -- Output read count
      RDERR       => open,              -- Output read error
      WRCOUNT     => FIFO_BX_CNT_WRCOUNT,              -- Output write count
      WRERR       => open,              -- Output write error
      CLK         => CLK,               -- Input clock
      DI          => BX_CNT,            -- Input data
      RDEN        => FIFO_RD_EN,        -- Input read enable
      RST         => RST,               -- Input reset
      WREN        => FIFO_WR_EN         -- Input write enable
      );
      
-- Generate FIFO_EMPTY_B / FIFO_FULL_B
  FIFO_EMPTY_B <= not FIFO_L1A_MATCH_EMPTY;
  FIFO_FULL_B <= not FIFO_L1A_MATCH_FULL;


end TRGFIFO_Arch;
