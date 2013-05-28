library ieee;
library work;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity INSTRGDC is

  port (
    BTDI   : in  std_logic;             -- TDI from BSCAN_VIRTEX
    DRCK   : in  std_logic;             -- Signals are from BSCAN_VIRTEX
    SEL1   : in  std_logic;
    UPDATE : in  std_logic;
    SHIFT  : in  std_logic;
    D0     : out std_logic;
    FSEL  : in  std_logic_vector(5 downto 0);
    F      : out std_logic_vector(47 downto 1));

end INSTRGDC;


architecture INSTRGDC_Arch of INSTRGDC is

  signal SELUPDATE : std_logic := 'L';     -- Signal to update F (FUNUPD in schematic)
  signal SELSHIFT : std_logic := 'L';      -- Enable shifting BTDI into D
  signal D : std_logic_vector(7 downto 0); -- Registers to hold data from BTDI

begin  -- INSTRGDC_Arch

  SELSHIFT <= SHIFT and SEL1;
  SELUPDATE <= UPDATE and SEL1;
  
  -- purpose: shift BTDI into D[7:0]
  -- type   : combinational
  -- inputs : SELSHIFT,DRCK
  -- outputs: D[7:0]
  PSHIFT : process (SELSHIFT,DRCK)
  begin
    if SELSHIFT='1' then
      if (DRCK='1' and DRCK'event) then
        D(7) <= BTDI;
        D(6 downto 0) <= D(7 downto 1);
      end if;
    end if;
  end process;

  -- purpose: translate D into a mask and latch to F
  -- type   : sequential
  -- inputs : SELUPDATE
  -- outputs: F[47:1]
--  PUPDATE : process (SELUPDATE)
--    variable NUM : integer range 1 to 47;
--    variable MASK : std_logic_vector(47 downto 1) := (others => '0');
--  begin
--    if (SELUPDATE='1' and SELUPDATE'event) then
--      NUM := to_integer(unsigned(D));   -- the bit to set to 1
--      MASK := (others => '0');          -- clear the mask
--      MASK(NUM) := '1';                 -- then set the one bit to 1
--      F <= MASK;                        -- assign the mask to F
--    end if;
--  end process;

-- Guido May 17
  PUPDATE : process (FSEL)
    variable NUM : integer range 0 to 47;
    variable MASK : std_logic_vector(47 downto 0) := (others => '0');
  begin
      NUM := to_integer(unsigned(FSEL));   -- the bit to set to 1
      MASK := (others => '0');          -- clear the mask
      MASK(NUM) := '1';                 -- then set the one bit to 1
      F <= MASK(47 downto 1);                        -- assign the mask to F
  end process;

end INSTRGDC_Arch;
