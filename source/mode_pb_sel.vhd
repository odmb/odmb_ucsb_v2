LIBRARY ieee;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_1164.all;

--  Entity Declaration

ENTITY mode_pb_sel IS
	PORT
	(
		pb0 : IN STD_LOGIC;
		pb1 : IN STD_LOGIC;
		pb2 : IN STD_LOGIC;
		pb3 : IN STD_LOGIC;
		pb_reset : OUT STD_LOGIC;
		lb_en : OUT STD_LOGIC;
		lb_ff_en : OUT STD_LOGIC;
		tm_en : OUT STD_LOGIC
	);
	
END mode_pb_sel;


--  Architecture Body

ARCHITECTURE mode_pb_sel_architecture OF mode_pb_sel IS


begin

mode_pb_sel_proc : process(pb0, pb1, pb2, pb3)

begin

		pb_reset <= pb0;
		
		if (pb0 = '1')then
			lb_en <= '0';
		elsif(rising_edge(pb1)) then
			lb_en <= '1';
		end if;              

		if (pb0 = '1')then
			lb_ff_en <= '0';
		elsif(rising_edge(pb2)) then
			lb_ff_en <= '1';
		end if;              

		if (pb0 = '1')then
			tm_en <= '0';
		elsif(rising_edge(pb3)) then
			tm_en <= '1';
		end if;              
      
end process;

END mode_pb_sel_architecture;
