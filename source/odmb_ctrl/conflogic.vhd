-- CONFREGS: Loads via JTAG configuration registers
-- Used to be discrete logic in JTAGCOM in the old design

library unisim;
library ieee;
library work;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use work.hdlmacro.all;

entity CONFLOGIC is  
  generic (
    NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
    );  
  port (
    CLKCMS   : in std_logic;          
    RST      : in std_logic;          

    INSTR    : in std_logic_vector(47 downto 1);
    CCBINJ   : in std_logic;          
    CCBPLS   : in std_logic;          
    CCBPED   : in std_logic;              
    SELRAN   : in std_logic;          

    CAL_TRGSEL   : out std_logic;          
    ENACFEB      : out std_logic;          
    CAL_MODE     : out std_logic         
   );

end CONFLOGIC;

architecture CONFLOGIC_Arch of CONFLOGIC is

  signal LOGICH : std_logic := '1';
  signal CCBCAL_CLK, CCBCAL_CLR, CCBCAL : std_logic;
  signal CB8_CEO, CB8_TC, CB8_TC_Q : std_logic;
  signal CB8_CNT : std_logic_vector(7 downto 0);
  
  signal TRGSEL_INNER, TRGSEL_B, ENACFEB_INNER, ENACFEB_B : std_logic;

begin  --Architecture

  -- Generate CAL_MODE
  CCBCAL_CLK <= CCBPLS or CCBINJ or CCBPED;
  FDCCBCAL : FDC port map(CCBCAL, CCBCAL_CLK, CCBCAL_CLR, LOGICH);
  CB8CCBCAL : CB8CE port map(CB8_CEO, CB8_CNT, CB8_TC, CLKCMS, CCBCAL, CCBCAL_CLR);
  FDTC : FD port map(CB8_TC_Q, CLKCMS, CB8_TC);
  CCBCAL_CLR <= RST or CB8_TC_Q;
  CAL_MODE <= INSTR(3) or INSTR(4) or INSTR(7) or INSTR(8) or CCBCAL or SELRAN;
  
  -- Generate CAL_TRGSEL
  FDCTRGSEL : FDC port map(TRGSEL_B, INSTR(11), RST, TRGSEL_INNER);
  TRGSEL_INNER <= not TRGSEL_B;
  CAL_TRGSEL <= TRGSEL_INNER;
  
  -- Generate ENACFEB
  FDCENACFEB : FDC port map(ENACFEB_B, INSTR(39), RST, ENACFEB_INNER);
  ENACFEB_INNER <= not ENACFEB_B;
  ENACFEB <= ENACFEB_INNER;
  
end CONFLOGIC_Arch;
