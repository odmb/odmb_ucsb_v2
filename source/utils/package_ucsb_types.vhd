-- Package with types used by UCSB
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package ucsb_types is
  
  type cfg_regs_array is array (0 to 15) of std_logic_vector(15 downto 0);

  component RESET_FIFO is
    generic (
      NCLOCKS : integer range 1 to 100 := 50
      );
    port (
      FIFO_RST  : out std_logic;
      FIFO_MASK : out std_logic;

      CLK    : in std_logic;
      IN_RST : in std_logic
      );
  end component;

  component FDVEC is
    generic (
      VEC_MIN : integer := 0;
      VEC_MAX : integer := 15);
    port (
      DOUT : out std_logic_vector(VEC_MAX downto VEC_MIN);
      CLK  : in  std_logic;
      RST  : in  std_logic;
      DIN  : in  std_logic_vector(VEC_MAX downto VEC_MIN)
      );
  end component;

  component CROSSCLOCK is
    port (
      DOUT     : out std_logic;
      CLK_DOUT : in  std_logic;
      CLK_DIN  : in  std_logic;
      RST      : in  std_logic;
      DIN      : in  std_logic
      );
  end component;

  component PULSE2SLOW is
    port (
      DOUT     : out std_logic;
      CLK_DOUT : in  std_logic;
      CLK_DIN  : in  std_logic;
      RST      : in  std_logic;
      DIN      : in  std_logic
      );
  end component;

  component PULSE2FAST is
    port (
      DOUT     : out std_logic;
      CLK_DOUT : in  std_logic;
      RST      : in  std_logic;
      DIN      : in  std_logic
      );
  end component;

  component PULSE2SAME is
    port (
      DOUT     : out std_logic;
      CLK_DOUT : in  std_logic;
      RST      : in  std_logic;
      DIN      : in  std_logic
      );
  end component;

  component NPULSE2FAST is
    port (
      DOUT     : out std_logic;
      CLK_DOUT : in  std_logic;
      RST      : in  std_logic;
      NPULSE   : in  integer;
      DIN      : in  std_logic
      );
  end component;

  component NPULSE2SAME is
    port (
      DOUT     : out std_logic;
      CLK_DOUT : in  std_logic;
      RST      : in  std_logic;
      NPULSE   : in  integer;
      DIN      : in  std_logic
      );
  end component;

  component NPULSE2SLOW is
    port (
      DOUT     : out std_logic;
      CLK_DOUT : in  std_logic;
      CLK_DIN  : in  std_logic;
      RST      : in  std_logic;
      NPULSE   : in  integer;
      DIN      : in  std_logic
      );
  end component;

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

  component DELAY_SIGNAL is
    generic (NCYCLES_MAX : integer := 63);
    port (
      DOUT    : out std_logic;
      CLK     : in  std_logic;
      NCYCLES : in  integer range 0 to NCYCLES_MAX;
      DIN     : in  std_logic
      );
  end component;

  component FIFO_CASCADE is
    generic(
      NFIFO        : integer range 3 to 16 := 3;
      DATA_WIDTH   : integer               := 18;
      FWFT         : boolean               := false;
      WR_FASTER_RD : boolean               := true
      );
    port(
      DO        : out std_logic_vector(DATA_WIDTH-1 downto 0);
      EMPTY     : out std_logic;
      FULL      : out std_logic;
      HALF_FULL : out std_logic;

      DI    : in std_logic_vector(DATA_WIDTH-1 downto 0);
      RDCLK : in std_logic;
      RDEN  : in std_logic;
      RST   : in std_logic;
      WRCLK : in std_logic;
      WREN  : in std_logic
      );
  end component;

  component GAP_COUNTER is
    generic(MAX_CYCLES : integer := 63);
    port (
      GAP_COUNT : out std_logic_vector(15 downto 0);

      CLK     : in std_logic;
      RST     : in std_logic;
      SIGNAL1 : in std_logic;
      SIGNAL2 : in std_logic
      );
  end component;

  component FIFOWORDS is
    generic (WIDTH : integer := 16);
    port (
      RST   : in  std_logic;
      WRCLK : in  std_logic;
      WREN  : in  std_logic;
      FULL  : in  std_logic;
      RDCLK : in  std_logic;
      RDEN  : in  std_logic;
      COUNT : out std_logic_vector(WIDTH-1 downto 0)
      );
  end component;

  component COUNT_EDGES is
    generic (
      WIDTH : integer := 16
      );
    port (
      COUNT : out std_logic_vector(WIDTH-1 downto 0);

      CLK : in std_logic;
      RST : in std_logic;
      DIN : in std_logic
      );
  end component;

  component COUNT_WINDOW is
    generic (
      WIDTH : integer := 16;
      WINDOW : integer := 63 -- In CC
      );
    port (
      COUNT : out std_logic_vector(WIDTH-1 downto 0);

      CLK : in std_logic;
      RST : in std_logic;
      DIN : in std_logic
      );
  end component;

  

end ucsb_types;

