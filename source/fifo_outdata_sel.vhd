LIBRARY ieee;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_1164.all;

--  Entity Declaration

ENTITY fifo_outdata_sel IS
	PORT
	(

		fifo_sel : IN STD_LOGIC_VECTOR(7 downto 0);
		fifo0_outdata : IN STD_LOGIC_VECTOR(15 downto 0);
		fifo1_outdata : IN STD_LOGIC_VECTOR(15 downto 0);
		fifo2_outdata : IN STD_LOGIC_VECTOR(15 downto 0);
		fifo3_outdata : IN STD_LOGIC_VECTOR(15 downto 0);
		fifo4_outdata : IN STD_LOGIC_VECTOR(15 downto 0);
		fifo5_outdata : IN STD_LOGIC_VECTOR(15 downto 0);
		fifo6_outdata : IN STD_LOGIC_VECTOR(15 downto 0);
		fifo7_outdata : IN STD_LOGIC_VECTOR(15 downto 0);
		fifo_outdata : OUT STD_LOGIC_VECTOR(15 downto 0)
		
	);
	
END fifo_outdata_sel;

--  Architecture Body

ARCHITECTURE fifo_outdata_sel_architecture OF fifo_outdata_sel IS

begin
  
fifo_data_sel : process (fifo_sel,fifo0_outdata,fifo1_outdata,fifo2_outdata,fifo3_outdata,
                                  fifo4_outdata,fifo5_outdata,fifo6_outdata,fifo7_outdata)
    
begin		
					  
   	case fifo_sel is

	    when "00000001" =>	fifo_outdata <= fifo0_outdata;
	    when "00000010" =>	fifo_outdata <= fifo1_outdata;
	    when "00000100" =>	fifo_outdata <= fifo2_outdata;
	    when "00001000" =>	fifo_outdata <= fifo3_outdata;
	    when "00010010" =>	fifo_outdata <= fifo4_outdata;
	    when "00100010" =>	fifo_outdata <= fifo5_outdata;
	    when "01000010" =>	fifo_outdata <= fifo6_outdata;
	    when "10000010" =>	fifo_outdata <= fifo7_outdata;
	    when others =>	fifo_outdata <= "0000000000000000";
	      
  end case;
  
end process;

END fifo_outdata_sel_architecture;
 
