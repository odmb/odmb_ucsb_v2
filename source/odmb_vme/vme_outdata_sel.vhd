library ieee;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_1164.all;

--  Entity Declaration

entity vme_outdata_sel is
  port (

    device          : in  std_logic_vector(9 downto 0);
    device0_outdata : in  std_logic_vector(15 downto 0);
    device1_outdata : in  std_logic_vector(15 downto 0);
    device2_outdata : in  std_logic_vector(15 downto 0);
    device3_outdata : in  std_logic_vector(15 downto 0);
    device4_outdata : in  std_logic_vector(15 downto 0);
    device5_outdata : in  std_logic_vector(15 downto 0);
    device7_outdata : in  std_logic_vector(15 downto 0);
    device8_outdata : in  std_logic_vector(15 downto 0);
    outdata         : out std_logic_vector(15 downto 0)
    );
end vme_outdata_sel;

--  Architecture Body
architecture vme_outdata_sel_architecture of vme_outdata_sel is

begin

  outdata <= device0_outdata when device = "0000000001" else
             device1_outdata when device = "0000000010" else
             device2_outdata when device = "0000000100" else
             device3_outdata when device = "0000001000" else
             device4_outdata when device = "0000010000" else
             device5_outdata when device = "0000100000" else
             device7_outdata when device = "0010000000" else
             device8_outdata when device = "0100000000" else
             "0000000000000000";

end vme_outdata_sel_architecture;
