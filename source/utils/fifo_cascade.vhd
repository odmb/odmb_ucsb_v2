-- FIFO_CASCADE: Cascades FIFOs to increase depth

library ieee;
library unisim;
library unimacro;
library hdlmacro;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use hdlmacro.hdlmacro.all;

entity FIFO_CASCADE is

  generic (
    NFIFO        : integer range 3 to 16 := 3;
    DATA_WIDTH   : integer               := 18;
    WR_FASTER_RD : boolean               := true
    );
  port(
    DO    : out std_logic_vector(DATA_WIDTH-1 downto 0);
    EMPTY : out std_logic;
    FULL  : out std_logic;
    EOF   : out std_logic;
    BOF   : out std_logic;

    DI    : in std_logic_vector(DATA_WIDTH-1 downto 0);
    RDCLK : in std_logic;
    RDEN  : in std_logic;
    RST   : in std_logic;
    WRCLK : in std_logic;
    WREN  : in std_logic
    );

end entity FIFO_CASCADE;

architecture fifo_cascade_arch of FIFO_CASCADE is

  component PULSE_EDGE is
    port (
      DOUT   : out std_logic;
      PULSE1 : out std_logic;
      CLK    : in  std_logic;
      RST    : in  std_logic;
      NPULSE : in  integer;
      DIN    : in  std_logic
      );
  end component;

  type   fifo_data_type is array (NFIFO downto 1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal fifo_in, fifo_out        : fifo_data_type;
  signal fifo_aempty              : std_logic_vector(NFIFO downto 1);
  signal fifo_afull               : std_logic_vector(NFIFO downto 1);
  signal fifo_empty               : std_logic_vector(NFIFO downto 1);
  signal fifo_full                : std_logic_vector(NFIFO downto 1);
  signal fifo_wren, fifo_wrck     : std_logic_vector(NFIFO downto 1);
  signal fifo_rden, fifo_rdck     : std_logic_vector(NFIFO downto 1);
  type   fifo_cnt_type is array (NFIFO downto 1) of std_logic_vector(10 downto 0);
  signal fifo_wr_cnt, fifo_rd_cnt : fifo_cnt_type;
  signal int_clk                  : std_logic := '0';

begin

  int_clk <= WRCLK when (WR_FASTER_RD) else RDCLK;

  -- this is actually the input FIFO
  fifo_wrck(NFIFO) <= WRCLK;
  fifo_wren(NFIFO) <= WREN;
  fifo_in(NFIFO)   <= DI;
  fifo_rdck(NFIFO) <= int_clk;
  fifo_rden(NFIFO) <= not (fifo_empty(NFIFO) or fifo_full(NFIFO-1));

  FIFO_M_NFIFO : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => DATA_WIDTH,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => true)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      ALMOSTEMPTY => fifo_aempty(NFIFO),  -- Output almost empty 
      ALMOSTFULL  => fifo_afull(NFIFO),   -- Output almost full
      DO          => fifo_out(NFIFO),     -- Output data
      EMPTY       => fifo_empty(NFIFO),   -- Output empty
      FULL        => fifo_full(NFIFO),    -- Output full
      RDCOUNT     => fifo_rd_cnt(NFIFO),  -- Output read count
      RDERR       => open,                -- Output read error
      WRCOUNT     => fifo_wr_cnt(NFIFO),  -- Output write count
      WRERR       => open,                -- Output write error
      DI          => fifo_in(NFIFO),      -- Input data
      RDCLK       => fifo_rdck(NFIFO),    -- Input read clock
      RDEN        => fifo_rden(NFIFO),    -- Input read enable
      RST         => RST,                 -- Input reset
      WRCLK       => fifo_wrck(NFIFO),    -- Input write clock
      WREN        => fifo_wren(NFIFO)     -- Input write enable
      );

  GEN_FIFO_M : for I in NFIFO-1 downto 2 generate
  begin

    fifo_wren(I) <= not (fifo_empty(I+1) or fifo_full(I));
    fifo_wrck(I) <= int_clk;
    fifo_in(I)   <= fifo_out(I+1);
    fifo_rden(I) <= not (fifo_empty(I) or fifo_full(I-1));
    fifo_rdck(I) <= int_clk;

    FIFO_MOD : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
        ALMOST_FULL_OFFSET      => X"0080",  -- Sets almost full threshold
        ALMOST_EMPTY_OFFSET     => X"0080",  -- Sets the almost empty threshold
        DATA_WIDTH              => DATA_WIDTH,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
        FIFO_SIZE               => "36Kb",   -- Target BRAM, "18Kb" or "36Kb" 
        FIRST_WORD_FALL_THROUGH => true)  -- Sets the FIFO FWFT to TRUE or FALSE

      port map (
        ALMOSTEMPTY => fifo_aempty(I),  -- Output almost empty 
        ALMOSTFULL  => fifo_afull(I),   -- Output almost full
        DO          => fifo_out(I),     -- Output data
        EMPTY       => fifo_empty(I),   -- Output empty
        FULL        => fifo_full(I),    -- Output full
        RDCOUNT     => fifo_rd_cnt(I),  -- Output read count
        RDERR       => open,            -- Output read error
        WRCOUNT     => fifo_wr_cnt(I),  -- Output write count
        WRERR       => open,            -- Output write error
        DI          => fifo_in(I),      -- Input data
        RDCLK       => fifo_rdck(I),    -- Input read clock
        RDEN        => fifo_rden(I),    -- Input read enable
        RST         => RST,             -- Input reset
        WRCLK       => fifo_wrck(I),    -- Input write clock
        WREN        => fifo_wren(I)     -- Input write enable
        );
  end generate GEN_FIFO_M;

  -- this is actually the output FIFO
  fifo_wren(1) <= not (fifo_empty(2) or fifo_full(1));
  fifo_wrck(1) <= int_clk;
  fifo_in(1)   <= fifo_out(2);
  fifo_rden(1) <= RDEN;
  fifo_rdck(1) <= RDCLK;

  FIFO_M_1 : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => DATA_WIDTH,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "36Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => false)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      ALMOSTEMPTY => fifo_aempty(1),    -- Output almost empty 
      ALMOSTFULL  => fifo_afull(1),     -- Output almost full
      DO          => fifo_out(1),       -- Output data
      EMPTY       => fifo_empty(1),     -- Output empty
      FULL        => fifo_full(1),      -- Output full
      RDCOUNT     => fifo_rd_cnt(1),    -- Output read count
      RDERR       => open,              -- Output read error
      WRCOUNT     => fifo_wr_cnt(1),    -- Output write count
      WRERR       => open,              -- Output write error
      DI          => fifo_in(1),        -- Input data
      RDCLK       => fifo_rdck(1),      -- Input read clock
      RDEN        => fifo_rden(1),      -- Input read enable
      RST         => RST,               -- Input reset
      WRCLK       => fifo_wrck(1),      -- Input write clock
      WREN        => fifo_wren(1)       -- Input write enable
      );  

  --outputs of cascade (from the first and last fifos)
  DO    <= fifo_out(1);                 --out
  EMPTY <= fifo_empty(1);               --out
  FULL  <= fifo_full(NFIFO);            --out
  --out: tells you when packet has finished arriving at FIFO 1
  PULSE_EOF : PULSE_EDGE port map(EOF, open, WRCLK, RST, 1, fifo_in(1)(DATA_WIDTH-2));
  BOF   <= fifo_in(1)(DATA_WIDTH-1);  --OUT: tells you when packet has started arriving at FIFO 1
end fifo_cascade_arch;
