-- VMECONFREGS: Assign values to registers used in ODMB_CTRL

library ieee;
library work;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity VMECONFREGS is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );    
  port (

    SLOWCLK : in std_logic;
    CLK     : in std_logic;
    RST     : in std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);
    WRITER  : in std_logic;

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    ALCT_PUSH_DLY : out std_logic_vector(4 downto 0);
    OTMB_PUSH_DLY : out std_logic_vector(4 downto 0);
    PUSH_DLY      : out std_logic_vector(4 downto 0);
    LCT_L1A_DLY   : out std_logic_vector(5 downto 0);

    INJ_DLY    : out std_logic_vector(4 downto 0);
    EXT_DLY    : out std_logic_vector(4 downto 0);
    CALLCT_DLY : out std_logic_vector(3 downto 0);

    NWORDS_DUMMY : out std_logic_vector(15 downto 0);
    KILL         : out std_logic_vector(NFEB+2 downto 1);
    CRATEID      : out std_logic_vector(7 downto 0);

-- From BPI_PORT
    BPI_CFG_UL_PULSE : in std_logic;
    BPI_CFG_DL_PULSE : in std_logic;

-- From BPI_CFG_CONTROLLER
    CC_CFG_REG_IN : in std_logic_vector(15 downto 0);
    CC_CFG_REG_WE : in std_logic_vector(15 downto 0);

-- To BPI_CFG_CONTROLLER
    CFG_REG0 : out std_logic_vector(15 downto 0);
    CFG_REG1 : out std_logic_vector(15 downto 0);
    CFG_REG2 : out std_logic_vector(15 downto 0);
    CFG_REG3 : out std_logic_vector(15 downto 0);
    CFG_REG4 : out std_logic_vector(15 downto 0);
    CFG_REG5 : out std_logic_vector(15 downto 0);
    CFG_REG6 : out std_logic_vector(15 downto 0);
    CFG_REG7 : out std_logic_vector(15 downto 0);
    CFG_REG8 : out std_logic_vector(15 downto 0);
    CFG_REG9 : out std_logic_vector(15 downto 0);
    CFG_REGA : out std_logic_vector(15 downto 0);
    CFG_REGB : out std_logic_vector(15 downto 0);
    CFG_REGC : out std_logic_vector(15 downto 0);
    CFG_REGD : out std_logic_vector(15 downto 0);
    CFG_REGE : out std_logic_vector(15 downto 0);
    CFG_REGF : out std_logic_vector(15 downto 0)
    );
end VMECONFREGS;


architecture VMECONFREGS_Arch of VMECONFREGS is

  component bpi_cfg_registers is
    port(
      rst : in std_logic;

      clk            : in std_logic;
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
  end component;

  signal CMDDEV : std_logic_vector(15 downto 0);

  signal INNER_CFG_REG0, INNER_CFG_REG1 : std_logic_vector(15 downto 0) := (others => '0');
  signal INNER_CFG_REG2, INNER_CFG_REG3 : std_logic_vector(15 downto 0) := (others => '0');
  signal INNER_CFG_REG4, INNER_CFG_REG5 : std_logic_vector(15 downto 0) := (others => '0');
  signal INNER_CFG_REG6, INNER_CFG_REG7 : std_logic_vector(15 downto 0) := (others => '0');
  signal INNER_CFG_REG8, INNER_CFG_REG9 : std_logic_vector(15 downto 0) := (others => '0');
  signal INNER_CFG_REGA, INNER_CFG_REGB : std_logic_vector(15 downto 0) := (others => '0');
  signal INNER_CFG_REGC, INNER_CFG_REGD : std_logic_vector(15 downto 0) := (others => '0');
  signal INNER_CFG_REGE, INNER_CFG_REGF : std_logic_vector(15 downto 0) := (others => '0');

  signal CFG_REG_IN, VME_CFG_REG_WE : std_logic_vector(15 downto 0) := (others => '0');
  signal CFG_REG_WE                 : std_logic_vector(15 downto 0) := (others => '0');
  signal CFG_REG_RE                 : std_logic_vector(15 downto 0) := (others => '0');
  signal CFG_REG_CK                 : std_logic;

  signal dd_dtack, d_dtack, q_dtack : std_logic;

  type cfg_reg_mask_array is array (0 to 15) of std_logic_vector(15 downto 0);
  constant cfg_reg_mask : cfg_reg_mask_array := (x"003F", x"001F", x"001F", x"001F", x"001F",
                                                 x"001F", x"000F", x"01FF", x"00ff", x"ffff",
                                                 x"ffff", x"ffff", x"ffff", x"ffff", x"ffff", x"ffff");

begin  --Architecture


  CFG_REG_CK <= STROBE         when (BPI_CFG_UL_PULSE = '0') else CLK;
  CFG_REG_WE <= VME_CFG_REG_WE when (BPI_CFG_UL_PULSE = '0') else CC_CFG_REG_WE;
  CFG_REG_IN <= INDATA         when (BPI_CFG_UL_PULSE = '0') else CC_CFG_REG_IN;
  
  
  BPI_CFG_REGS_PM : bpi_cfg_registers
    port map(
      rst => RST,

      clk            => CFG_REG_CK,
      bpi_cfg_reg_we => CFG_REG_WE,
      bpi_cfg_reg_in => CFG_REG_IN,

      bpi_cfg_reg0 => INNER_CFG_REG0,  -- CMDDEV = x"1000" => LCT_L1A_DLY (6 bits)
      bpi_cfg_reg1 => INNER_CFG_REG1,  -- CMDDEV = x"1004" => OTMB_PUSH_DLY (5 bits)
      bpi_cfg_reg2 => INNER_CFG_REG2,  -- CMDDEV = x"1008" => PUSH_DLY (5 bits)
      bpi_cfg_reg3 => INNER_CFG_REG3,  -- CMDDEV = x"100C" => ALCT_PUSH_DLY (5 bits)
      bpi_cfg_reg4 => INNER_CFG_REG4,   -- CMDDEV = x"1010" => INJ_DLY (5 bits)
      bpi_cfg_reg5 => INNER_CFG_REG5,   -- CMDDEV = x"1014" => EXT_DLY (5 bits)
      bpi_cfg_reg6 => INNER_CFG_REG6,  -- CMDDEV = x"1018" => CALLCT_DLY (4 bits)
      bpi_cfg_reg7 => INNER_CFG_REG7,   -- CMDDEV = x"101C" => KILL (9 bits)
      bpi_cfg_reg8 => INNER_CFG_REG8,   -- CMDDEV = x"1020" => CRATEID (8 bits)
      bpi_cfg_reg9 => INNER_CFG_REG9,  -- CMDDEV = x"1024" => FW_VERSION (16 bits) - READ ONLY
      bpi_cfg_regA => INNER_CFG_REGA,  -- CMDDEV = x"1028" => NWORDS_DUMMY (16 bits)
      bpi_cfg_regB => INNER_CFG_REGB,   -- CMDDEV = x"102C" => NOT USED
      bpi_cfg_regC => INNER_CFG_REGC,   -- CMDDEV = x"1030" => NOT USED
      bpi_cfg_regD => INNER_CFG_REGD,   -- CMDDEV = x"1034" => NOT USED
      bpi_cfg_regE => INNER_CFG_REGE,   -- CMDDEV = x"1038" => NOT USED
      bpi_cfg_regF => INNER_CFG_REGF    -- CMDDEV = x"103C" => NOT USED
      );

  LCT_L1A_DLY   <= INNER_CFG_REG0(5 downto 0);
  OTMB_PUSH_DLY <= INNER_CFG_REG1(4 downto 0);
  PUSH_DLY      <= INNER_CFG_REG2(4 downto 0);
  ALCT_PUSH_DLY <= INNER_CFG_REG3(4 downto 0);
  INJ_DLY       <= INNER_CFG_REG4(4 downto 0);
  EXT_DLY       <= INNER_CFG_REG5(4 downto 0);
  CALLCT_DLY    <= INNER_CFG_REG6(3 downto 0);
  KILL          <= INNER_CFG_REG7(8 downto 0);
  CRATEID       <= INNER_CFG_REG8(7 downto 0);
  NWORDS_DUMMY  <= INNER_CFG_REGA(15 downto 0);

  CFG_REG0 <= INNER_CFG_REG0;
  CFG_REG1 <= INNER_CFG_REG1;
  CFG_REG2 <= INNER_CFG_REG2;
  CFG_REG3 <= INNER_CFG_REG3;
  CFG_REG4 <= INNER_CFG_REG4;
  CFG_REG5 <= INNER_CFG_REG5;
  CFG_REG6 <= INNER_CFG_REG6;
  CFG_REG7 <= INNER_CFG_REG7;
  CFG_REG8 <= INNER_CFG_REG8;
  CFG_REG9 <= INNER_CFG_REG9;
  CFG_REGA <= INNER_CFG_REGA;
  CFG_REGB <= INNER_CFG_REGB;
  CFG_REGC <= INNER_CFG_REGC;
  CFG_REGD <= INNER_CFG_REGD;
  CFG_REGE <= INNER_CFG_REGE;
  CFG_REGF <= INNER_CFG_REGF;

-- Decode instruction
  CMDDEV <= "000" & DEVICE & COMMAND & "00";  -- Variable that looks like the VME commands we input  

  VME_CFG_REG_WE(0)  <= '1' when (CMDDEV = x"1000" and WRITER = '0') else '0';
  VME_CFG_REG_WE(1)  <= '1' when (CMDDEV = x"1004" and WRITER = '0') else '0';
  VME_CFG_REG_WE(2)  <= '1' when (CMDDEV = x"1008" and WRITER = '0') else '0';
  VME_CFG_REG_WE(3)  <= '1' when (CMDDEV = x"100C" and WRITER = '0') else '0';
  VME_CFG_REG_WE(4)  <= '1' when (CMDDEV = x"1010" and WRITER = '0') else '0';
  VME_CFG_REG_WE(5)  <= '1' when (CMDDEV = x"1014" and WRITER = '0') else '0';
  VME_CFG_REG_WE(6)  <= '1' when (CMDDEV = x"1018" and WRITER = '0') else '0';
  VME_CFG_REG_WE(7)  <= '1' when (CMDDEV = x"101C" and WRITER = '0') else '0';
  VME_CFG_REG_WE(8)  <= '1' when (CMDDEV = x"1020" and WRITER = '0') else '0';
  VME_CFG_REG_WE(9)  <= '1' when (CMDDEV = x"1024" and WRITER = '0') else '0';  -- FW_VERSION (16 bits) - READ ONLY
  VME_CFG_REG_WE(10) <= '1' when (CMDDEV = x"1028" and WRITER = '0') else '0';
  VME_CFG_REG_WE(11) <= '1' when (CMDDEV = x"102C" and WRITER = '0') else '0';  -- NOT USED
  VME_CFG_REG_WE(12) <= '1' when (CMDDEV = x"1030" and WRITER = '0') else '0';  -- NOT USED
  VME_CFG_REG_WE(13) <= '1' when (CMDDEV = x"1034" and WRITER = '0') else '0';  -- NOT USED
  VME_CFG_REG_WE(14) <= '1' when (CMDDEV = x"1038" and WRITER = '0') else '0';  -- NOT USED
  VME_CFG_REG_WE(15) <= '1' when (CMDDEV = x"103C" and WRITER = '0') else '0';  -- NOT USED

  CFG_REG_RE(0)  <= '1' when (CMDDEV = x"1000" and WRITER = '1') else '0';
  CFG_REG_RE(1)  <= '1' when (CMDDEV = x"1004" and WRITER = '1') else '0';
  CFG_REG_RE(2)  <= '1' when (CMDDEV = x"1008" and WRITER = '1') else '0';
  CFG_REG_RE(3)  <= '1' when (CMDDEV = x"100C" and WRITER = '1') else '0';
  CFG_REG_RE(4)  <= '1' when (CMDDEV = x"1010" and WRITER = '1') else '0';
  CFG_REG_RE(5)  <= '1' when (CMDDEV = x"1014" and WRITER = '1') else '0';
  CFG_REG_RE(6)  <= '1' when (CMDDEV = x"1018" and WRITER = '1') else '0';
  CFG_REG_RE(7)  <= '1' when (CMDDEV = x"101C" and WRITER = '1') else '0';
  CFG_REG_RE(8)  <= '1' when (CMDDEV = x"1020" and WRITER = '1') else '0';
  CFG_REG_RE(9)  <= '1' when (CMDDEV = x"1024" and WRITER = '1') else '0';  -- FW_VERSION (16 bits) - READ ONLY
  CFG_REG_RE(10) <= '1' when (CMDDEV = x"1028" and WRITER = '1') else '0';
  CFG_REG_RE(11) <= '1' when (CMDDEV = x"102C" and WRITER = '1') else '0';  -- NOT USED
  CFG_REG_RE(12) <= '1' when (CMDDEV = x"1030" and WRITER = '1') else '0';  -- NOT USED
  CFG_REG_RE(13) <= '1' when (CMDDEV = x"1034" and WRITER = '1') else '0';  -- NOT USED
  CFG_REG_RE(14) <= '1' when (CMDDEV = x"1038" and WRITER = '1') else '0';  -- NOT USED
  CFG_REG_RE(15) <= '1' when (CMDDEV = x"103C" and WRITER = '1') else '0';  -- NOT USED

-- Output Multiplexer 

  OUTDATA <= (INNER_CFG_REG0 and cfg_reg_mask(0)) when CFG_REG_RE(0) = '1' else
             (INNER_CFG_REG1 and cfg_reg_mask(1))  when CFG_REG_RE(1) = '1'  else
             (INNER_CFG_REG2 and cfg_reg_mask(2))  when CFG_REG_RE(2) = '1'  else
             (INNER_CFG_REG3 and cfg_reg_mask(3))  when CFG_REG_RE(3) = '1'  else
             (INNER_CFG_REG4 and cfg_reg_mask(4))  when CFG_REG_RE(4) = '1'  else
             (INNER_CFG_REG5 and cfg_reg_mask(5))  when CFG_REG_RE(5) = '1'  else
             (INNER_CFG_REG6 and cfg_reg_mask(6))  when CFG_REG_RE(6) = '1'  else
             (INNER_CFG_REG7 and cfg_reg_mask(7))  when CFG_REG_RE(7) = '1'  else
             (INNER_CFG_REG8 and cfg_reg_mask(8))  when CFG_REG_RE(8) = '1'  else
             (INNER_CFG_REG9 and cfg_reg_mask(9))  when CFG_REG_RE(9) = '1'  else
             (INNER_CFG_REGA and cfg_reg_mask(10)) when CFG_REG_RE(10) = '1' else
             (INNER_CFG_REGB and cfg_reg_mask(11)) when CFG_REG_RE(11) = '1' else
             (INNER_CFG_REGC and cfg_reg_mask(12)) when CFG_REG_RE(12) = '1' else
             (INNER_CFG_REGD and cfg_reg_mask(13)) when CFG_REG_RE(13) = '1' else
             (INNER_CFG_REGE and cfg_reg_mask(14)) when CFG_REG_RE(14) = '1' else
             (INNER_CFG_REGF and cfg_reg_mask(15)) when CFG_REG_RE(15) = '1' else
             (others => 'L');

  dd_dtack <= STROBE and (or_reduce(cfg_reg_we) or or_reduce(cfg_reg_re));
  FD_D_DTACK : FDC port map(d_dtack, dd_dtack, q_dtack, '1');
  FD_Q_DTACK : FD port map(q_dtack, SLOWCLK, d_dtack);
  DTACK <= q_dtack;

end VMECONFREGS_Arch;
