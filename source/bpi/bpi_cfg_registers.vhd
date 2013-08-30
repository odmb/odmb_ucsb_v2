library IEEE;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_1164.all;

entity bpi_cfg_registers is
   port(
  
   clk : in std_logic;
   rst : in std_logic;

   bpi_cfg_reg_we : in std_logic_vector(3 downto 0);
   bpi_cfg_reg_in : in std_logic_vector(15 downto 0);

   bpi_cfg_reg0 : out std_logic_vector(15 downto 0);
   bpi_cfg_reg1 : out std_logic_vector(15 downto 0);
   bpi_cfg_reg2 : out std_logic_vector(15 downto 0);
   bpi_cfg_reg3 : out std_logic_vector(15 downto 0)

	);

end bpi_cfg_registers;

architecture bpi_cfg_regs_architecture of bpi_cfg_registers is

constant CFG_REG0 : std_logic_vector(15 downto 0) := x"fff0";
constant CFG_REG1 : std_logic_vector(15 downto 0) := x"fff1";
constant CFG_REG2 : std_logic_vector(15 downto 0) := x"fff2";
constant CFG_REG3 : std_logic_vector(15 downto 0) := x"fff3";

begin

cfg_reg0_proc : process (rst, clk)

begin
	if (rst = '1')  then
		bpi_cfg_reg0 <= CFG_REG0;
	elsif rising_edge(clk) and (bpi_cfg_reg_we(0) = '1') then
		bpi_cfg_reg0 <= bpi_cfg_reg_in;
	end if;

end process;

cfg_reg1_proc : process (rst, clk)

begin
	if (rst = '1')  then
		bpi_cfg_reg1 <= CFG_REG1;
	elsif rising_edge(clk) and (bpi_cfg_reg_we(1) = '1') then
		bpi_cfg_reg1 <= bpi_cfg_reg_in;
	end if;

end process;

cfg_reg2_proc : process (rst, clk)

begin
	if (rst = '1')  then
		bpi_cfg_reg2 <= CFG_REG2;
	elsif rising_edge(clk) and (bpi_cfg_reg_we(2) = '1') then
		bpi_cfg_reg2 <= bpi_cfg_reg_in;
	end if;

end process;

cfg_reg3_proc : process (rst, clk)

begin
	if (rst = '1')  then
		bpi_cfg_reg3 <= CFG_REG3;
	elsif rising_edge(clk) and (bpi_cfg_reg_we(3) = '1') then
		bpi_cfg_reg3 <= bpi_cfg_reg_in;
	end if;

end process;

end bpi_cfg_regs_architecture;
