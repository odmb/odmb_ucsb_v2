-- EOFGEN: ouputs data with an End-Of-Packet signal in the second to last word

library ieee;
library unisim;
library unimacro;
library hdlmacro;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use hdlmacro.hdlmacro.all;

entity eofgen is
  port(
    clk : in std_logic;
    rst : in std_logic;

    dv_in   : in std_logic;
    data_in : in std_logic_vector(15 downto 0);

    dv_out   : out std_logic;
    data_out : out std_logic_vector(17 downto 0)
    );
end eofgen;

architecture eofgen_architecture of eofgen is
  signal reg1_data, reg2_data, reg3_data : std_logic_vector(15 downto 0);
  signal dv_reg                          : std_logic_vector(2 downto 0);
  signal eof, eof_reg                    : std_logic;

begin

  FD_REG0 : FDC port map(dv_reg(0), CLK, RST, DV_IN);
  FD_REG1 : FDC port map(dv_reg(1), CLK, RST, dv_reg(0));
  FD_REG2 : FDC port map(dv_reg(2), CLK, RST, dv_reg(1));

  eof <= not dv_in and dv_reg(0);
  FD_EOF : FDC port map(eof_reg, CLK, RST, eof);

  GEN_FD_REG : for index in 0 to 15 generate
  begin
    FD_REG_DATA1 : FDC port map(reg1_data(index), CLK, RST, DATA_IN(index));
    FD_REG_DATA2 : FDC port map(reg2_data(index), CLK, RST, reg1_data(index));
    FD_REG_DATA3 : FDC port map(reg3_data(index), CLK, RST, reg2_data(index));
  end generate GEN_FD_REG;

  DATA_OUT <= eof_reg & eof_reg & reg3_data;
  DV_OUT   <= dv_reg(2);
  
end eofgen_architecture;
