-- Package with types used by UCSB
library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package ucsb_types is
  
  type cfg_regs_array is array (0 to 15) of std_logic_vector(15 downto 0);

end ucsb_types;
 
