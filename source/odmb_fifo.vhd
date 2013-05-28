Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

LIBRARY IEEE;
USE IEEE.std_logic_1164.all; 
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;


ENTITY DMB_fifo IS
	port (
	rst: IN std_logic;
	wr_clk: IN std_logic;
	rd_clk: IN std_logic;
	din: IN std_logic_VECTOR(17 downto 0);
	wr_en: IN std_logic;
	rd_en: IN std_logic;
	dout: OUT std_logic_VECTOR(17 downto 0);
	full: OUT std_logic;
	empty: OUT std_logic;
	prog_full: OUT std_logic;
	prog_empty: OUT std_logic);
END DMB_fifo;

ARCHITECTURE DMB_fifo_arch OF DMB_fifo IS
-- synthesis translate_off

signal	wr_cnt : STD_LOGIC_VECTOR( 11 downto 0);
signal	rd_cnt : STD_LOGIC_VECTOR( 11 downto 0);
signal	wr_err : STD_LOGIC;
signal	rd_err : STD_LOGIC;
begin
 FIFO_SYNC_MACRO_inst : FIFO_SYNC_MACRO
   generic map (
      DEVICE => "VIRTEX6",            -- Target Device: "VIRTEX5, "VIRTEX6" 
      ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
      DATA_WIDTH => 18,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "18Kb")            -- Target BRAM, "18Kb" or "36Kb" 
   port map (
      ALMOSTEMPTY => prog_empty,   -- Output almost empty 
      ALMOSTFULL => prog_full,     -- Output almost full
      DO => dout,                     -- Output data
      EMPTY => empty,               -- Output empty
      FULL => full,                 -- Output full
      RDCOUNT => rd_cnt,           -- Output read count
      RDERR => rd_err,               -- Output read error
      WRCOUNT => wr_cnt,           -- Output write count
      WRERR => wr_err,               -- Output write error
      CLK => wr_clk,                   -- Input clock
      DI => din,                     -- Input data
      RDEN => rd_en,                 -- Input read enable
      RST => rst,                   -- Input reset
      WREN => wr_en                  -- Input write enable
   );

END DMB_fifo_arch;

