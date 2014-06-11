-------------------------------------------------------------------------------
-- Copyright (c) 2014 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.7
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : csp_lvmb_la.vhd
-- /___/   /\     Timestamp  : Mon Jun 09 15:48:18 Romance Daylight Time 2014
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY csp_lvmb_la IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    CLK: in std_logic;
    DATA: in std_logic_vector(99 downto 0);
    TRIG0: in std_logic_vector(7 downto 0));
END csp_lvmb_la;

ARCHITECTURE csp_lvmb_la_a OF csp_lvmb_la IS
BEGIN

END csp_lvmb_la_a;
