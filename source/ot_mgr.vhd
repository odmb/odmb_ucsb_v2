library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity ot_mgr is
  port (
    otx1_tx_en  : out std_logic;
    otx1_tx_dis : out std_logic;
    otx1_reset  : out std_logic;
    otx1_fault  : in  std_logic;
    otx2_tx_en  : out std_logic;
    otx2_tx_dis : out std_logic;
    otx2_reset  : out std_logic;
    otx2_fault  : in  std_logic;
    orx1_rx_en  : out std_logic;
    orx1_en_sd  : out std_logic;
    orx1_sd     : in  std_logic;
    orx1_sq_en  : out std_logic;
    orx2_rx_en  : out std_logic;
    orx2_en_sd  : out std_logic;
    orx2_sd     : in  std_logic;
    orx2_sq_en  : out std_logic
    );

end ot_mgr;


architecture om_architecture of ot_mgr is

begin

  otx1_tx_en  <= '1';
  otx1_tx_dis <= '0';
  otx1_reset  <= '0';
  otx2_tx_en  <= '1';
  otx2_tx_dis <= '0';
  otx2_reset  <= '0';
  orx1_rx_en  <= '1';
  orx1_en_sd  <= '0';
  orx1_sq_en  <= '0';
  orx2_rx_en  <= '1';
  orx2_en_sd  <= '0';
  orx2_sq_en  <= '0';
  
end om_architecture;
