-- PRBS_GEN: Generate a 2^7-1 PRBS sequence (x^7 + x^6 + 1 polynomial)

library ieee;
use ieee.std_logic_1164.all;

entity PRBS_GEN is
  port (
    DOUT : out std_logic;

    CLK    : in std_logic;
    RST    : in std_logic;
    ENABLE : in std_logic
    );
end PRBS_GEN;

architecture PRBS_GEN_Arch of PRBS_GEN is

  signal lfsr : std_logic_vector(6 downto 0) := "0000001";

begin

  lfsr_proc : process (clk, enable, rst)
    variable bit : std_logic;
  begin
    if (RST = '1') then
      lfsr <= "0000001";  -- Any non-zero value is good
    elsif (rising_edge(CLK)) then
      if enable = '1' then
        bit  := lfsr(0) xor lfsr(1);
        lfsr <= bit & lfsr(6 downto 1);
      end if;
    end if;
  end process;

  DOUT <= lfsr(0);
  
end PRBS_GEN_Arch;
