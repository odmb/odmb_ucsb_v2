LIBRARY ieee;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_1164.all;

--  Entity Declaration

ENTITY vme_master IS
	PORT
	(

		clk : IN STD_LOGIC;
		rstn : IN STD_LOGIC;
		sw_reset : IN STD_LOGIC;

		vme_cmd : in STD_LOGIC;
		vme_cmd_rd : out STD_LOGIC;

		vme_wr : in STD_LOGIC;
		vme_addr : in STD_LOGIC_VECTOR(23 downto 1);
		vme_wr_data : in STD_LOGIC_VECTOR(15 downto 0);
		vme_rd : in STD_LOGIC;
		vme_rd_data : out STD_LOGIC_VECTOR(15 downto 0);

		ga : OUT STD_LOGIC_VECTOR(5 downto 0);
		
		addr : OUT STD_LOGIC_VECTOR(23 downto 1);
		am : OUT STD_LOGIC_VECTOR(5 downto 0);
		as : OUT STD_LOGIC;

		data_in : IN STD_LOGIC_VECTOR(15 downto 0);
		data_out : OUT STD_LOGIC_VECTOR(15 downto 0);
		ds0 : OUT STD_LOGIC;
		ds1 : OUT STD_LOGIC;
		oe_b : OUT STD_LOGIC;

		dtack : IN STD_LOGIC;
		
		iack : OUT STD_LOGIC;
		lword : OUT STD_LOGIC;
		write_b : OUT STD_LOGIC;

		berr : OUT STD_LOGIC;
		sysfail : OUT STD_LOGIC
	);
	
END vme_master;


--  Architecture Body

ARCHITECTURE vme_master_architecture OF vme_master IS

constant t1 : std_logic_vector := "00001000";
constant t2 : std_logic_vector := "00001000";
constant t3 : std_logic_vector := "00001000";
constant t4 : std_logic_vector := "00001000";
constant t5 : std_logic_vector := "00010000";

type state_type is (IDLE, CMD, WR_BEGIN, WR_AS_LOW, WR_DS_LOW, WR_DTACK_LOW, WR_AS_HIGH, WR_DS_HIGH, WR_DTACK_HIGH, WR_END);
    
signal next_state, current_state: state_type;

signal cnt_en, cnt_res : std_logic;
signal cnt_out : std_logic_vector(7 downto 0);

signal ad_load: std_logic;
signal d_load: std_logic;
signal reg_addr : STD_LOGIC_VECTOR(23 downto 1);
signal reg_data  : STD_LOGIC_VECTOR(15 downto 0);
signal reg_wr, reg_rd : STD_LOGIC;

begin

  berr <= '0';
  sysfail <= '1';
  lword <= '1';
  ga <= "101010";
  am <= "111010";
  
  
cnt: process (clk, rstn, sw_reset, cnt_en, cnt_res)

variable cnt_data : std_logic_vector(7 downto 0);

begin

	if ((rstn = '0') or (sw_reset = '1')) then
		cnt_data := (OTHERS => '0');
	elsif (rising_edge(clk)) then
		if (cnt_res = '1') then
			cnt_data := (OTHERS => '0');
		elsif (cnt_en = '1') then    
			cnt_data := cnt_data + 1;
		end if;              
	end if; 

	cnt_out <= cnt_data;
	
end process;
		
ad_regs: process (d_load, ad_load, rstn, sw_reset, clk, reg_addr, reg_data, data_in)

begin
  
	if ((rstn = '0') or (sw_reset = '1')) then
		reg_addr <= (OTHERS => '0');
		reg_data <= (OTHERS => '0');
		reg_wr <= '0';
		reg_rd <= '0';
	elsif rising_edge(clk) and (ad_load = '1')then
		reg_addr <= vme_addr;
		reg_data <= vme_wr_data;
		reg_wr <= vme_wr;
		reg_rd <= vme_rd;
	end if;
  addr <= reg_addr;
  data_out <= reg_data;
	if ((rstn = '0') or (sw_reset = '1')) then
		vme_rd_data <= (OTHERS => '0');
	elsif rising_edge(clk) and (d_load = '1')then
		vme_rd_data <= data_in;
	end if;

end process;


fsm_state_regs: process (next_state, rstn, sw_reset, clk)

begin
	if ((rstn = '0') or (sw_reset = '1')) then
		current_state <= IDLE;
	elsif rising_edge(clk) then
		current_state <= next_state;	      	
	end if;

end process;


fsm_comb_logic: process(vme_cmd, current_state, cnt_out, vme_wr, vme_addr, vme_wr_data, dtack)
    
begin		
					  
   	case current_state is

	    when IDLE =>	
      write_b <= '0';
			iack <= '0';
			oe_b <= '0';
			as <= '1';
			ds0 <= '1';
			ds1 <= '1';
			d_load <= '0';
			if (vme_cmd = '1') then
			 cnt_en <= '1';
			 cnt_res <= '1';
			 ad_load <= '1';
	 		 vme_cmd_rd <= '0';
			 next_state <= CMD;
			else
			 cnt_en <= '0';
			 cnt_res <= '0';
			 ad_load <= '0';
		 	 vme_cmd_rd <= '0';
			 next_state <= IDLE;
			end if;

	    when CMD =>	
      write_b <= '0';
			oe_b <= '0';
			as <= '1';
			ds0 <= '1';
			ds1 <= '1';
			d_load <= '0';
			ad_load <= '0';
			vme_cmd_rd <= '0';
			if ((reg_wr = '1') or (reg_rd = '1')) then
			 iack <= '1';
			 cnt_en <= '1';
			 cnt_res <= '1';
			 next_state <= WR_BEGIN;
			else
			 iack <= '0';
			 cnt_en <= '0';
			 cnt_res <= '0';
			 next_state <= IDLE;
			end if;

	    when WR_BEGIN =>	
			if (reg_rd = '1') then
			   oe_b <= '1';
			   write_b <= '1';
			else
			   oe_b <= '0';
			   write_b <= '0';
			end if;  
			iack <= '1';
			ds0 <= '1';
			ds1 <= '1';
			d_load <= '0';
			ad_load <= '0';
			vme_cmd_rd <= '0';
			if (cnt_out = t1) then
			 as <= '0';
			 cnt_en <= '1';
			 cnt_res <= '1';
			 next_state <= WR_AS_LOW;
			else
			 as <= '1';
			 cnt_en <= '1';
			 cnt_res <= '0';
			 next_state <= WR_BEGIN;
			end if;

	    when WR_AS_LOW =>	
			if (reg_rd = '1') then
			   oe_b <= '1';
			   write_b <= '1';
			else
			   oe_b <= '0';
			   write_b <= '0';
			end if;  
			iack <= '1';
			as <= '0';
			d_load <= '0';
			ad_load <= '0';
			vme_cmd_rd <= '0';
			if (cnt_out = t2) then
			 ds0 <= '0';
			 ds1 <= '0';
			 cnt_en <= '1';
			 cnt_res <= '1';
			 next_state <= WR_DS_LOW;
			else
			 ds0 <= '1';
			 ds1 <= '1';
			 cnt_en <= '1';
			 cnt_res <= '0';
			 next_state <= WR_AS_LOW;
			end if;

	    when WR_DS_LOW =>	
			if (reg_rd = '1') then
			   oe_b <= '1';
			   write_b <= '1';
			else
			   oe_b <= '0';
			   write_b <= '0';
			end if;  
			iack <= '1';
			as <= '0';
			ds0 <= '0';
			ds1 <= '0';
			d_load <= '0';
			ad_load <= '0';
			vme_cmd_rd <= '0';
			if (dtack = '0') then
			 cnt_en <= '1';
			 cnt_res <= '1';
			 next_state <= WR_DTACK_LOW;
			else
			 cnt_en <= '1';
			 cnt_res <= '1';
			 next_state <= WR_DS_LOW;
			end if;

	    when WR_DTACK_LOW =>	
			if (reg_rd = '1') then
			   oe_b <= '1';
			   write_b <= '1';
			else
			   oe_b <= '0';
			   write_b <= '0';
			end if;  
			iack <= '1';
			ds0 <= '0';
			ds1 <= '0';
			ad_load <= '0';
			vme_cmd_rd <= '0';
			if (cnt_out = t3) then
			 as <= '1';
			 cnt_en <= '1';
			 cnt_res <= '1';
			 if (reg_rd = '1') then
			   d_load <= '1';
			 else
			   d_load <= '0';
			 end if;  
			 next_state <= WR_AS_HIGH;
			else
			 as <= '0';
			 cnt_en <= '1';
			 cnt_res <= '0';
			 next_state <= WR_DTACK_LOW;
			end if;

	    when WR_AS_HIGH =>	
			if (reg_rd = '1') then
			   oe_b <= '1';
			   write_b <= '1';
			else
			   oe_b <= '0';
			   write_b <= '0';
			end if;  
			iack <= '1';
			as <= '1';
			d_load <= '0';
			ad_load <= '0';
		  	vme_cmd_rd <= '0';
			if (cnt_out = t4) then
			 ds0 <= '1';
			 ds1 <= '1';
			 cnt_en <= '1';
			 cnt_res <= '1';
			 next_state <= WR_DS_HIGH;
			else
			 ds0 <= '0';
			 ds1 <= '0';
			 cnt_en <= '1';
			 cnt_res <= '0';
			 next_state <= WR_AS_HIGH;
			end if;

	    when WR_DS_HIGH =>	
			if (reg_rd = '1') then
			   oe_b <= '1';
			   write_b <= '1';
			else
			   oe_b <= '0';
			   write_b <= '0';
			end if;  
			iack <= '1';
			as <= '1';
			ds0 <= '1';
			ds1 <= '1';
			d_load <= '0';
			ad_load <= '0';
		  	vme_cmd_rd <= '0';
			if ((dtack = '1') or (dtack = 'H')) then
			 cnt_en <= '1';
			 cnt_res <= '1';
			 next_state <= WR_DTACK_HIGH;
			else
			 cnt_en <= '1';
			 cnt_res <= '1';
			 next_state <= WR_DS_HIGH;
			end if;

	    when WR_DTACK_HIGH =>	
			as <= '1';
			ds0 <= '1';
			ds1 <= '1';
			d_load <= '0';
			ad_load <= '0';
			if (cnt_out = t5) then
			 iack <= '0';
			 oe_b <= '0';
			 write_b <= '0';
			 cnt_en <= '1';
			 cnt_res <= '1';
		    vme_cmd_rd <= '0';
			 next_state <= WR_END;
			else
			if (reg_rd = '1') then
			   oe_b <= '1';
			   write_b <= '1';
			else
			   oe_b <= '0';
			   write_b <= '0';
			end if;  
			 iack <= '1';
			 cnt_en <= '1';
			 cnt_res <= '0';
		   vme_cmd_rd <= '0';
			 next_state <= WR_DTACK_HIGH;
			end if;

	    when WR_END =>	
			iack <= '0';
			oe_b <= '0';
      write_b <= '0';
			as <= '1';
			ds0 <= '1';
			ds1 <= '1';
			d_load <= '0';
			ad_load <= '0';
		  vme_cmd_rd <= '1';
			cnt_en <= '0';
			cnt_res <= '0';
			if ((vme_cmd = '1') and (vme_wr = '1')) then
			 next_state <= WR_BEGIN;
			else
			 next_state <= IDLE;
			end if;


	    when others =>
			write_b <= '0';
			iack <= '0';
			oe_b <= '0';
			as <= '1';
			ds0 <= '1';
			ds1 <= '1';
			d_load <= '0';
			ad_load <= '0';
		  vme_cmd_rd <= '0';
			cnt_en <= '0';
			cnt_res <= '0';
			next_state <= IDLE;

	end case;

end process;

END vme_master_architecture;
