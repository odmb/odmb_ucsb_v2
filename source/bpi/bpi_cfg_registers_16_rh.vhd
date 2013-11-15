library IEEE;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

entity bpi_cfg_registers_16_rh is
  port(

    clk : in std_logic;
    rst : in std_logic;

    bpi_cfg_reg_we : in std_logic_vector(15 downto 0);

    bpi_cfg_reg_in : in std_logic_vector(15 downto 0);

    bpi_cfg_reg0 : out std_logic_vector(15 downto 0);
    bpi_cfg_reg1 : out std_logic_vector(15 downto 0);
    bpi_cfg_reg2 : out std_logic_vector(15 downto 0);
    bpi_cfg_reg3 : out std_logic_vector(15 downto 0);
    bpi_cfg_reg4 : out std_logic_vector(15 downto 0);
    bpi_cfg_reg5 : out std_logic_vector(15 downto 0);
    bpi_cfg_reg6 : out std_logic_vector(15 downto 0);
    bpi_cfg_reg7 : out std_logic_vector(15 downto 0);
    bpi_cfg_reg8 : out std_logic_vector(15 downto 0);
    bpi_cfg_reg9 : out std_logic_vector(15 downto 0);
    bpi_cfg_regA : out std_logic_vector(15 downto 0);
    bpi_cfg_regB : out std_logic_vector(15 downto 0);
    bpi_cfg_regC : out std_logic_vector(15 downto 0);
    bpi_cfg_regD : out std_logic_vector(15 downto 0);
    bpi_cfg_regE : out std_logic_vector(15 downto 0);
    bpi_cfg_regF : out std_logic_vector(15 downto 0)

    );

end bpi_cfg_registers_16_rh;

architecture bpi_cfg_regs_architecture of bpi_cfg_registers_16_rh is

  type   cfg_reg_data is array (15 downto 0) of std_logic_vector(15 downto 0);
-- signal bpi_cfg_reg_in_prom : cfg_reg_data;
-- signal bpi_cfg_reg_in_vme : cfg_reg_data;
  signal bpi_cfg_reg_in_ml : cfg_reg_data;

  type   rh_reg is array (2 downto 0) of std_logic_vector(15 downto 0);
  type   rh_reg_array is array (15 downto 0) of rh_reg;
  signal bpi_cfg_reg : rh_reg_array;

  type   rh_reg_init is array (15 downto 0) of std_logic_vector(15 downto 0);
  signal bpi_cfg_reg_init : rh_reg_init;

  constant FW_VERSION   : std_logic_vector(15 downto 0) := x"0200";
  constant NWORDS_DUMMY : std_logic_vector(15 downto 0) := x"0008";

  constant CFG_REG_MASK       : std_logic_vector(15 downto 0) := x"fdff";  -- CFG_REG9 never enabled for write
  signal   int_bpi_cfg_reg_we : std_logic_vector(15 downto 0);

begin

-- Configuration Registers Set A

  bpi_cfg_reg_init(0)  <= x"aa00";
  bpi_cfg_reg_init(1)  <= x"aa01";
  bpi_cfg_reg_init(2)  <= x"aa02";
  bpi_cfg_reg_init(3)  <= x"aa03";
  bpi_cfg_reg_init(4)  <= x"aa04";
  bpi_cfg_reg_init(5)  <= x"aa05";
  bpi_cfg_reg_init(6)  <= x"aa06";
  bpi_cfg_reg_init(7)  <= x"aa07";
  bpi_cfg_reg_init(8)  <= x"aa08";
  bpi_cfg_reg_init(9)  <= FW_VERSION;
  bpi_cfg_reg_init(10) <= NWORDS_DUMMY;
  bpi_cfg_reg_init(11) <= x"aa0b";
  bpi_cfg_reg_init(12) <= x"aa0c";
  bpi_cfg_reg_init(13) <= x"aa0d";
  bpi_cfg_reg_init(14) <= x"aa0e";
  bpi_cfg_reg_init(15) <= x"aa0f";

  cfg_reg_proc : process (bpi_cfg_reg_we, int_bpi_cfg_reg_we, bpi_cfg_reg_in, bpi_cfg_reg_in_ml,
                          bpi_cfg_reg_init, rst, clk)
  begin
    for i in 0 to 15 loop
      int_bpi_cfg_reg_we(i) <= bpi_cfg_reg_we(i) and cfg_reg_mask(i);
      for j in 0 to 2 loop
        if (rst = '1') then
          bpi_cfg_reg(i)(j) <= bpi_cfg_reg_init(i);
        elsif (rising_edge(clk) and (int_bpi_cfg_reg_we(i) = '1')) then
          bpi_cfg_reg(i)(j) <= bpi_cfg_reg_in;
        else
          bpi_cfg_reg(i)(j) <= bpi_cfg_reg_in_ml(i);
        end if;

      end loop;
    end loop;
  end process;

  ml_proc : process (bpi_cfg_reg)
  begin
    for i in 0 to 15 loop
      if (bpi_cfg_reg(i)(0) = bpi_cfg_reg(i)(1)) then
        bpi_cfg_reg_in_ml(i) <= bpi_cfg_reg(i)(0);
      elsif (bpi_cfg_reg(i)(0) = bpi_cfg_reg(i)(2)) then
        bpi_cfg_reg_in_ml(i) <= bpi_cfg_reg(i)(0);
      elsif (bpi_cfg_reg(i)(1) = bpi_cfg_reg(i)(2)) then
        bpi_cfg_reg_in_ml(i) <= bpi_cfg_reg(i)(1);
      end if;
    end loop;
  end process;

  bpi_cfg_reg0 <= bpi_cfg_reg_in_ml(0);
  bpi_cfg_reg1 <= bpi_cfg_reg_in_ml(1);
  bpi_cfg_reg2 <= bpi_cfg_reg_in_ml(2);
  bpi_cfg_reg3 <= bpi_cfg_reg_in_ml(3);
  bpi_cfg_reg4 <= bpi_cfg_reg_in_ml(4);
  bpi_cfg_reg5 <= bpi_cfg_reg_in_ml(5);
  bpi_cfg_reg6 <= bpi_cfg_reg_in_ml(6);
  bpi_cfg_reg7 <= bpi_cfg_reg_in_ml(7);
  bpi_cfg_reg8 <= bpi_cfg_reg_in_ml(8);
  bpi_cfg_reg9 <= bpi_cfg_reg_in_ml(9);
  bpi_cfg_rega <= bpi_cfg_reg_in_ml(10);
  bpi_cfg_regb <= bpi_cfg_reg_in_ml(11);
  bpi_cfg_regc <= bpi_cfg_reg_in_ml(12);
  bpi_cfg_regd <= bpi_cfg_reg_in_ml(13);
  bpi_cfg_rege <= bpi_cfg_reg_in_ml(14);
  bpi_cfg_regf <= bpi_cfg_reg_in_ml(15);
  
end bpi_cfg_regs_architecture;
