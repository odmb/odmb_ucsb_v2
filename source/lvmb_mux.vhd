-- LVMB_MUX: Simulates the response of the LVMB, and multiplexes the outputs of
--           the real and simulated LVMB.

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_1164.all;

entity LVMB_MUX is
  generic (
    NFEB : integer range 1 to 7 := 7    -- Number of DCFEBS
    );  
  port (
    RST : in std_logic;

    SIM_LVMB_EN   : in std_logic;
    SIM_LVMB_CE   : in std_logic_vector(NFEB downto 1);
    REAL_LVMB_SDO : in std_logic;

    SCLK : in  std_logic;
    SDI  : in  std_logic;
    SDO  : out std_logic
    );
end LVMB_MUX;

architecture LVMB_MUX_ARCH of LVMB_MUX is

  component LVMB_ADC is
    port (
      scl    : in    std_logic;
      sdi    : in    std_logic;
      sdo    : inout std_logic;
      ce     : in    std_logic;
      rst    : in    std_logic;
      device : in    std_logic_vector(3 downto 0)
      );
  end component;

  type     adc_addr_type is array (1 to NFEB) of std_logic_vector(3 downto 0);
  constant adc_addr : adc_addr_type := (x"1", x"2", x"3", x"4", x"5", x"6", x"7");

  signal sim_lvmb_sdo : std_logic_vector(NFEB downto 1);
begin

  GEN_ADC : for ind in NFEB downto 1 generate
  begin
    LVMB_ADC_PM : LVMB_ADC
      port map (
        scl    => SCLK,
        sdi    => SDI,
        sdo    => sim_lvmb_sdo(ind),
        ce     => SIM_LVMB_CE(ind),
        rst    => RST,
        device => adc_addr(ind));
  end generate GEN_ADC;

  SDO <= REAL_LVMB_SDO when SIM_LVMB_EN = '0' else
         sim_lvmb_sdo(1) when SIM_LVMB_CE = "1111110" else
         sim_lvmb_sdo(2) when SIM_LVMB_CE = "1111101" else
         sim_lvmb_sdo(3) when SIM_LVMB_CE = "1111011" else
         sim_lvmb_sdo(4) when SIM_LVMB_CE = "1110111" else
         sim_lvmb_sdo(5) when SIM_LVMB_CE = "1101111" else
         sim_lvmb_sdo(6) when SIM_LVMB_CE = "1011111" else
         sim_lvmb_sdo(7) when SIM_LVMB_CE = "0111111" else
         'Z';
  
end LVMB_MUX_ARCH;
