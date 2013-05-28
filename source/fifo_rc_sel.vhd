LIBRARY ieee;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_1164.all;

--  Entity Declaration

ENTITY fifo_rc_sel IS
	PORT
	(

		fifo_sel : IN STD_LOGIC_VECTOR(7 downto 0);
		fifo0_rc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo1_rc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo2_rc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo3_rc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo4_rc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo5_rc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo6_rc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo7_rc : IN STD_LOGIC_VECTOR(9 downto 0);
		fifo_rc : OUT STD_LOGIC_VECTOR(9 downto 0)
		
	);
	
END fifo_rc_sel;

--  Architecture Body

ARCHITECTURE fifo_rc_sel_architecture OF fifo_rc_sel IS

begin
  
fifo_data_sel : process (fifo_sel,fifo0_rc,fifo1_rc,fifo2_rc,fifo3_rc,
                                  fifo4_rc,fifo5_rc,fifo6_rc,fifo7_rc)
    
begin		
					  
   	case fifo_sel is

	    when "00000001" =>	fifo_rc <= fifo0_rc;
	    when "00000010" =>	fifo_rc <= fifo1_rc;
	    when "00000100" =>	fifo_rc <= fifo2_rc;
	    when "00001000" =>	fifo_rc <= fifo3_rc;
	    when "00010010" =>	fifo_rc <= fifo4_rc;
	    when "00100010" =>	fifo_rc <= fifo5_rc;
	    when "01000010" =>	fifo_rc <= fifo6_rc;
	    when "10000010" =>	fifo_rc <= fifo7_rc;
	    when others =>	fifo_rc <= "0000000000";
	      
  end case;
  
end process;

END fifo_rc_sel_architecture;
 
