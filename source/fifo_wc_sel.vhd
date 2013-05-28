LIBRARY ieee;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_1164.all;

--  Entity Declaration

ENTITY fifo_wc_sel IS
	PORT
	(

		fifo_sel : IN STD_LOGIC_VECTOR(7 downto 0);
		fifo0_wc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo1_wc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo2_wc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo3_wc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo4_wc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo5_wc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo6_wc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo7_wc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo_wc : OUT STD_LOGIC_VECTOR(9 downto 0)
		
	);
	
END fifo_wc_sel;

--  Architecture Body

ARCHITECTURE fifo_wc_sel_architecture OF fifo_wc_sel IS

begin
  
fifo_data_sel : process (fifo_sel,fifo0_wc,fifo1_wc,fifo2_wc,fifo3_wc,
                                  fifo4_wc,fifo5_wc,fifo6_wc,fifo7_wc)
    
begin		
					  
   	case fifo_sel is

	    when "00000001" =>	fifo_wc <= fifo0_wc;
	    when "00000010" =>	fifo_wc <= fifo1_wc;
	    when "00000100" =>	fifo_wc <= fifo2_wc;
	    when "00001000" =>	fifo_wc <= fifo3_wc;
	    when "00010010" =>	fifo_wc <= fifo4_wc;
	    when "00100010" =>	fifo_wc <= fifo5_wc;
	    when "01000010" =>	fifo_wc <= fifo6_wc;
	    when "10000010" =>	fifo_wc <= fifo7_wc;
	    when others =>	fifo_wc <= "0000000000";
	      
  end case;
  
end process;

END fifo_wc_sel_architecture;
 
