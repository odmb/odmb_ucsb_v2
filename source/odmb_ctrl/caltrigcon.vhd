library unisim;
library unimacro;
library ieee;
library work;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity CALTRIGCON is
  generic (
    NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
    );  
  port (
    CLKIN         : in std_logic;
    CLKSYN     : in std_logic;
     RST         : in std_logic;
   
    DIN     : in std_logic;
    DRCK     : in std_logic;
    SEL2     : in std_logic;
    SHIFT : in std_logic;
    FLOAD    : in std_logic;
    FCYC    : in std_logic;
    FCYCM    : in std_logic;

    CCBPED    : in std_logic;

    LCTOUT       : out std_logic;
    GTRGOUT : out std_logic
    );

end CALTRIGCON;

architecture CALTRIGCON_Arch of CALTRIGCON is

signal LOGICH : std_logic := '1';
signal DIN_M1 : std_logic;
signal WREN_EN, WREN_D, WREN_Q : std_logic;
signal CYCLE_CLK, CYCLE_CLR, CYCLE, RDEN_D : std_logic;
signal STOP : std_logic;
signal FIFO_WREN, FIFO_RDEN, FIFO_FULL, FIFO_EMPTY : std_logic;
signal FIFO_IN, FIFO_OUT : std_logic_vector(1 downto 0);
signal FIFO_WRCOUNT, FIFO_RDCOUNT : std_logic_vector(11 downto 0);

begin  --Architecture

-- Generate FIFO_IN
  FDDIN : FD port map(DIN_M1, CLKIN, DIN);
  FIFO_IN <= DIN & DIN_M1;
  
-- Generate FIFO_WREN 
  WREN_EN <= SEL2 and FLOAD and SHIFT;
  WREN_D <= not WREN_Q;
  FDCEWREN : FDCE port map(WREN_Q, DRCK, WREN_EN, RST, WREN_D);
  FDWREN : FD port map(FIFO_WREN, DRCK, WREN_Q);
    
-- Generate FIFO_RDEN 
  CYCLE_CLK <= CCBPED or FCYC;
  CYCLE_CLR <= STOP or RST;
  FDCCYCLE : FDC port map(CYCLE, CYCLE_CLK, CYCLE_CLR, LOGICH);
  RDEN_D <= CYCLE or FCYCM;
  FDERDEN : FDE port map(FIFO_RDEN, CLKIN, CLKSYN, RDEN_D);
   
-- Generate STOP
  STOP <= FIFO_EMPTY;
  
-- Generate LCTOUT / Generate GTRGOUT
  LCTOUT <= FIFO_OUT(0);
  GTRGOUT <= FIFO_OUT(1);
    
    
FIFO_L1A_LCT_MOD : FIFO_DUALCLOCK_MACRO
   generic map (
      DEVICE => "VIRTEX6",            		-- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET => X"0080",  		-- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080", 		-- Sets the almost empty threshold
      DATA_WIDTH => 2,   						-- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "18Kb",            		-- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => FALSE) 	-- Sets the FIFO FWFT to TRUE or FALSE
   port map (
      ALMOSTEMPTY => open,   			-- Output almost empty 
      ALMOSTFULL => open,     			-- Output almost full
      DO => FIFO_OUT,        		-- Output data
      EMPTY => FIFO_EMPTY,               	-- Output empty
      FULL => FIFO_FULL,                 	-- Output full
      RDCOUNT => FIFO_RDCOUNT,      -- Output read count
      RDERR => open,               			-- Output read error
      WRCOUNT => FIFO_WRCOUNT,      -- Output write count
      WRERR => open,               			-- Output write error
      DI => FIFO_IN,              -- Input data
      RDCLK => CLKIN,         -- Input read clock
      RDEN => FIFO_RDEN,          -- Input read enable
      RST => RST,                   		-- Input reset
      WRCLK => DRCK,         -- Input write clock
      WREN => FIFO_WREN           -- Input write enable
   );


end CALTRIGCON_Arch;
