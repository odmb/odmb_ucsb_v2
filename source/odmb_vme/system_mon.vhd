library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity SYSTEM_MON is
  port (
    OUTDATA : out std_logic_vector(15 downto 0);
    DTACK   : out std_logic;

    SLOWCLK : in std_logic;
    FASTCLK : in std_logic;
    RST     : in std_logic;
    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);
    WRITER  : in std_logic;
    VP      : in std_logic;
    VN      : in std_logic;
    VAUXP   : in std_logic_vector(15 downto 0);
    VAUXN   : in std_logic_vector(15 downto 0)
    );
end SYSTEM_MON;

architecture SYSTEM_MON_ARCH of SYSTEM_MON is
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

  signal drdy      : std_logic;
  signal den       : std_logic;
  signal q_strobe  : std_logic;
  signal q2_strobe : std_logic;

  signal dd_dtack, d_dtack, q_dtack, rst_dtack : std_logic;

  signal outdata_inner : std_logic_vector(15 downto 0);
  
begin
  SYSMON_PM : SYSMON
    generic map(
      INIT_40          => X"3000",      -- config reg 0
      INIT_41          => X"20f0",      -- config reg 1
      INIT_42          => X"0a00",      -- config reg 2
      INIT_48          => X"3f01",      -- Sequencer channel selection
      INIT_49          => X"ffff",      -- Sequencer channel selection
      INIT_4A          => X"0f00",      -- Sequencer Average selection
      INIT_4B          => X"ffff",      -- Sequencer Average selection
      INIT_4C          => X"0000",      -- Sequencer Bipolar selection
      INIT_4D          => X"0000",      -- Sequencer Bipolar selection
      INIT_4E          => X"0800",      -- Sequencer Acq time selection
      INIT_4F          => X"ffff",      -- Sequencer Acq time selection
      INIT_50          => X"b5ed",      -- Temp alarm trigger
      INIT_51          => X"5999",      -- Vccint upper alarm limit
      INIT_52          => X"e000",      -- Vccaux upper alarm limit
      INIT_53          => X"ca33",      -- Temp alarm OT upper
      INIT_54          => X"a93a",      -- Temp alarm reset
      INIT_55          => X"5111",      -- Vccint lower alarm limit
      INIT_56          => X"caaa",      -- Vccaux lower alarm limit
      INIT_57          => X"ae4e",      -- Temp alarm OT reset
      SIM_DEVICE       => "VIRTEX6",
      SIM_MONITOR_FILE => "/home/adam/odmb_ucsb_v2_testing/source/odmb_vme/auxfile.txt"
      )
    port map(
      ALM          => open,
      BUSY         => open,
      CHANNEL      => open,
      DO           => outdata_inner,
      DRDY         => drdy,
      EOC          => open,
      EOS          => open,
      JTAGBUSY     => open,
      JTAGLOCKED   => open,
      JTAGMODIFIED => open,
      OT           => open,

      CONVST    => '0',
      CONVSTCLK => '0',
      DADDR     => command(8 downto 2),
      DCLK      => FASTCLK,
      DEN       => den,
      DI        => x"0000",
      DWE       => '0',
      RESET     => RST,
      VAUXN     => VAUXN,
      VAUXP     => VAUXP,
      VN        => VN,
      VP        => VP
      );

  OUTDATA <= x"0" & outdata_inner(15 downto 4);  -- Discarding the 4 LSB

  --Enable sysmon output in first full clock cycle after strobe goes high
  FD_STROBE  : FD port map (q_strobe, FASTCLK, STROBE);
  FD_STROBE2 : FD port map (q2_strobe, FASTCLK, q_strobe);
  den <= '1' when (device = '1' and WRITER = '1' and q2_strobe = '0' and q_strobe = '1')
         else '0';

  --DTACK when OUTDATA contains valid data 
  dd_dtack  <= device and strobe;
  FD_D_DTACK : FDC port map(d_dtack, dd_dtack, rst_dtack, '1');
  FD_Q_DTACK : FD port map(q_dtack, SLOWCLK, d_dtack);
  rst_dtack <= q_dtack and drdy;
  DTACK     <= q_dtack;
  
end SYSTEM_MON_ARCH;
