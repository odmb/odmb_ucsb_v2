library unisim;
library unimacro;
library hdlmacro;
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use hdlmacro.hdlmacro.all;

entity prom is
   port(
  
   clk   : in std_logic;
   rst   : in std_logic;

   we_b : in std_logic;
   cs_b : in std_logic;
   oe_b : in std_logic;
   le_b : in std_logic;

   addr : in std_logic_vector(22 downto 0);
	 data : inout std_logic_vector(15 downto 0)
	
	);

end prom;

architecture prom_architecture of prom is

constant NW   : integer := 16;

type prom_array is array (NW-1 downto 0) of std_logic_vector(15 downto 0);
    
signal prom_data : prom_array;

signal data_in, data_out : std_logic_vector(15 downto 0);

signal addr_cnt_out : std_logic_vector(22 downto 0);

begin

-- Address Counter

cnt_proc: process (clk, le_b, addr)

variable addr_cnt_data : std_logic_vector(22 downto 0);

begin

	if (rst = '0') then
		addr_cnt_data := (OTHERS => '0');
	elsif (rising_edge(clk)) then
		if (le_b = '0') then
			addr_cnt_data := addr;
		elsif (we_b = '0') or (oe_b = '0') then    
			addr_cnt_data := addr_cnt_data + 1;
		end if;              
	end if; 

	addr_cnt_out <= addr_cnt_data;
	
end process;

-- Memory
	
mem_proc: process (clk, cs_b, we_b, oe_b, addr_cnt_out, prom_data)

begin

	if (cs_b = '0') and (we_b = '0') and (rising_edge(clk)) then
		case addr_cnt_out(3 downto 0) is
		  when "0000" => prom_data(0) <= data_in;
		  when "0001" => prom_data(1) <= data_in;
		  when "0010" => prom_data(2) <= data_in;
		  when "0011" => prom_data(3) <= data_in;
		  when "0100" => prom_data(4) <= data_in;
		  when "0101" => prom_data(5) <= data_in;
		  when "0110" => prom_data(6) <= data_in;
		  when "0111" => prom_data(7) <= data_in;
		  when "1000" => prom_data(8) <= data_in;
		  when "1001" => prom_data(9) <= data_in;
		  when "1010" => prom_data(10) <= data_in;
		  when "1011" => prom_data(11) <= data_in;
		  when "1100" => prom_data(12) <= data_in;
		  when "1101" => prom_data(13) <= data_in;
		  when "1110" => prom_data(14) <= data_in;
		  when "1111" => prom_data(15) <= data_in;
		  when others => prom_data <= prom_data;
    end case;		
	end if; 

	if (cs_b = '0') and (oe_b = '0') and (rising_edge(clk)) then
		case addr_cnt_out(3 downto 0) is
		  when "0000" => data_out <= prom_data(0);
		  when "0001" => data_out <= prom_data(1);
		  when "0010" => data_out <= prom_data(2);
		  when "0011" => data_out <= prom_data(3);
		  when "0100" => data_out <= prom_data(4);
		  when "0101" => data_out <= prom_data(5);
		  when "0110" => data_out <= prom_data(6);
		  when "0111" => data_out <= prom_data(7);
		  when "1000" => data_out <= prom_data(8);
		  when "1001" => data_out <= prom_data(9);
		  when "1010" => data_out <= prom_data(10);
		  when "1011" => data_out <= prom_data(11);
		  when "1100" => data_out <= prom_data(12);
		  when "1101" => data_out <= prom_data(13);
		  when "1110" => data_out <= prom_data(14);
		  when "1111" => data_out <= prom_data(15);
		  when others => data_out <= (others => '0');
    end case;		
	end if; 

end process;

-- Bidirectional Port

GEN_16 : for I in 0 to 15 generate
  begin
    DATA_BUF       : IOBUF port map (O => data_in(I), IO => data(I), I => data_out(I), T => oe_b);
end generate GEN_16;

		
end prom_architecture;
