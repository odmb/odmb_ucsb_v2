-- LCTDLY: Generates a 2.4-4.0 us delay to sync the LCT signals with the L1A

library ieee;
library work;
library unisim;
--use work.Latches_Flipflops.all;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;

entity LCTDLY is
  
  port (
    DIN     : in  std_logic;
    CLK     : in  std_logic;
    DELAY   : in  std_logic_vector(5 downto 0);
    
    DOUT    : out std_logic
);
end LCTDLY;

architecture LCTDLY_Arch of LCTDLY is

  signal DATA  : std_logic_vector(10 downto 0);
  type DELAY_TYPE is array (3 downto 0) of std_logic_vector(3 downto 0);
  signal DELAY_SRL  : DELAY_TYPE;

begin  --Architecture
  
  -- Fixed delay of 2.4 us (96 clock cycles)
  DATA(0) <= DIN;
  GEN_DATA : for K in 1 to 6 generate
    begin
      SRL16_K : SRL16 port map(DATA(K), '1', '1', '1', '1', CLK, DATA(K-1));
    end generate GEN_DATA;
    
  -- Variable delay between 4 and 64 clock cycles (0.1 us to 1.6 us)
  DELAY_SRL(0) <= DELAY(3 downto 0);
  DELAY_SRL(1) <= "0000" when (DELAY(5 downto 4)="00") else "1111";
  DELAY_SRL(2) <= "1111" when (DELAY(5)='1') else "0000";
  DELAY_SRL(3) <= "1111" when (DELAY(5 downto 4)="11") else "0000";
  
  GEN_DATA2 : for K in 7 to 10 generate
    begin
      SRL16_K : SRL16 port map(DATA(K), DELAY_SRL(K-7)(0), DELAY_SRL(K-7)(1), DELAY_SRL(K-7)(2), DELAY_SRL(K-7)(3), CLK, DATA(K-1));
    end generate GEN_DATA2;
  DOUT <= DATA(10);
  
end LCTDLY_Arch;
