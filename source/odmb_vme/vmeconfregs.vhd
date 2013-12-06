-- VMECONFREGS: Assigns values to the configuration registers. Uses triple
-- voting for radiation hardness.

library ieee;
library work;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use work.ucsb_types.all;

entity VMECONFREGS is
  generic (
    NREGS : integer := 16;              -- Number of Configuration registers
    NFEB  : integer := 7                -- Number of DCFEBs
    );    
  port (
    SLOWCLK : in std_logic;
    CLK     : in std_logic;
    RST     : in std_logic;

    DEVICE  : in  std_logic;
    STROBE  : in  std_logic;
    COMMAND : in  std_logic_vector(9 downto 0);
    WRITER  : in  std_logic;
    DTACK   : out std_logic;

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

-- Configuration registers    
    ALCT_PUSH_DLY : out std_logic_vector(4 downto 0);
    OTMB_PUSH_DLY : out std_logic_vector(4 downto 0);
    PUSH_DLY      : out std_logic_vector(4 downto 0);
    LCT_L1A_DLY   : out std_logic_vector(5 downto 0);

    INJ_DLY    : out std_logic_vector(4 downto 0);
    EXT_DLY    : out std_logic_vector(4 downto 0);
    CALLCT_DLY : out std_logic_vector(3 downto 0);

    ODMB_ID      : out std_logic_vector(15 downto 0);
    NWORDS_DUMMY : out std_logic_vector(15 downto 0);
    KILL         : out std_logic_vector(NFEB+2 downto 1);
    CRATEID      : out std_logic_vector(7 downto 0);

-- From BPI_PORT
    BPI_CFG_UL_PULSE : in std_logic;
    BPI_CFG_DL_PULSE : in std_logic;

-- From BPI_CTRL
    CC_CFG_REG_IN : in std_logic_vector(15 downto 0);

-- From/to BPI_CFG_CONTROLLER
    BPI_CFG_BUSY  : in  std_logic;
    CC_CFG_REG_WE : in  integer range 0 to NREGS;
    BPI_CFG_REGS  : out cfg_regs_array
    );
end VMECONFREGS;


architecture VMECONFREGS_Arch of VMECONFREGS is

  constant FW_VERSION : std_logic_vector(15 downto 0) := x"0201";

  constant cfg_reg_mask_we : std_logic_vector(15 downto 0) := x"FDFF";  -- CFG_REG9 not enabled for write
  constant cfg_reg_init : cfg_regs_array := (x"FFF0", x"FFF1", x"FFF2", x"FFF3",
                                             x"FFF4", x"FFF5", x"FFF6", x"FFF7",
                                             x"FFF8", FW_VERSION, x"FFFA", x"FFFB",
                                             x"FFFC", x"FFFD", x"FFFE", x"FFFF");
  constant cfg_reg_mask : cfg_regs_array := (x"003f", x"001f", x"001f", x"001f", x"001f",
                                             x"001f", x"000f", x"01ff", x"00ff", x"ffff",
                                             x"ffff", x"ffff", x"ffff", x"ffff", x"ffff", x"ffff");
  type   rh_reg is array (2 downto 0) of std_logic_vector(15 downto 0);
  type   rh_reg_array is array (0 to 15) of rh_reg;
  signal cfg_reg_triple : rh_reg_array;
  signal cfg_regs       : cfg_regs_array;

  signal cfg_reg_we, cfg_reg_index, vme_cfg_reg_we : integer range 0 to NREGS;

  signal cfg_reg_in  : std_logic_vector(15 downto 0) := (others => '0');
  signal cfg_reg_clk : std_logic;

  signal cmddev                     : std_logic_vector (15 downto 0);
  signal dd_dtack, d_dtack, q_dtack : std_logic := '0';

  signal   w_mask_vme, r_mask_vme     : std_logic;
  constant mask_vme_def               : std_logic_vector(15 downto 0) := x"FBFF";  -- FFFF to write unique ID
  signal   mask_vme                   : std_logic_vector(15 downto 0) := x"FBFF";  -- FFFF to write unique ID
  signal   mask_vme_rst, mask_vme_pre : std_logic_vector(15 downto 0);

begin

  cmddev     <= "000" & DEVICE & COMMAND & "00";
  w_mask_vme <= '1' when (cmddev = x"1100" and WRITER = '0') else '0';
  r_mask_vme <= '1' when (cmddev = x"1100" and WRITER = '1') else '0';

-- Write MASK_VME
  GEN_MASK_VME : for i in 0 to 15 generate
  begin
    mask_vme_pre(i) <= RST when mask_vme_def(i) = '1' else '0';
    mask_vme_rst(i) <= RST when mask_vme_def(i) = '0' else '0';
    fd_w_mask_vme : fdcpe port map(mask_vme(i), STROBE, w_mask_vme,
                                   mask_vme_rst(i), INDATA(i), mask_vme_pre(i));
  end generate GEN_MASK_VME;


-- Set write enables and output data
  cfg_reg_index <= to_integer(unsigned(cmddev(5 downto 2)));

  OUTDATA <= mask_vme when r_mask_vme = '1' else
             cfg_regs(cfg_reg_index) and cfg_reg_mask(cfg_reg_index);
  BPI_CFG_REGS <= cfg_regs;

  LCT_L1A_DLY   <= cfg_regs(0)(5 downto 0);       -- 0x4000
  OTMB_PUSH_DLY <= cfg_regs(1)(4 downto 0);       -- 0x4004
  PUSH_DLY      <= cfg_regs(2)(4 downto 0);       -- 0x4008
  ALCT_PUSH_DLY <= cfg_regs(3)(4 downto 0);       -- 0x400C
  INJ_DLY       <= cfg_regs(4)(4 downto 0);       -- 0x4010
  EXT_DLY       <= cfg_regs(5)(4 downto 0);       -- 0x4014
  CALLCT_DLY    <= cfg_regs(6)(3 downto 0);       -- 0x4018
  KILL          <= cfg_regs(7)(NFEB+1 downto 0);  -- 0x401C
  CRATEID       <= cfg_regs(8)(7 downto 0);       -- 0x4020
  ODMB_ID       <= cfg_regs(10)(15 downto 0);     -- 0x4028
  NWORDS_DUMMY  <= cfg_regs(11)(15 downto 0);     -- 0x402C

  -- Writing to registers
  vme_cfg_reg_we <= cfg_reg_index when (cmddev(12 downto 6) = "1000000" and WRITER = '0' and BPI_CFG_BUSY = '0'
                                        and mask_vme(cfg_reg_index) = '1') else NREGS;

  cfg_reg_we  <= vme_cfg_reg_we when (bpi_cfg_ul_pulse = '0') else cc_cfg_reg_we;
  cfg_reg_clk <= STROBE         when (bpi_cfg_ul_pulse = '0') else CLK;
  cfg_reg_in  <= INDATA         when (bpi_cfg_ul_pulse = '0') else cc_cfg_reg_in;

  cfg_reg_proc : process (RST, cfg_reg_clk, cfg_reg_we, cfg_reg_in, cfg_regs)
  begin
    for i in 0 to NREGS-1 loop
      for j in 0 to 2 loop
        if (RST = '1') then
          cfg_reg_triple(i)(j) <= cfg_reg_init(i);
        elsif (rising_edge(cfg_reg_clk) and cfg_reg_we = i and cfg_reg_mask_we(i) = '1') then
          cfg_reg_triple(i)(j) <= cfg_reg_in;
        else
          cfg_reg_triple(i)(j) <= cfg_regs(i);
        end if;
      end loop;
    end loop;
  end process;

  ml_proc : process (cfg_reg_triple)    -- Triple voting
  begin
    for i in 0 to NREGS-1 loop
      if (cfg_reg_triple(i)(0) = cfg_reg_triple(i)(1)) then
        cfg_regs(i) <= cfg_reg_triple(i)(0);
      elsif (cfg_reg_triple(i)(0) = cfg_reg_triple(i)(2)) then
        cfg_regs(i) <= cfg_reg_triple(i)(0);
      elsif (cfg_reg_triple(i)(1) = cfg_reg_triple(i)(2)) then
        cfg_regs(i) <= cfg_reg_triple(i)(1);
      end if;
    end loop;
  end process;

-- DTACK
  dd_dtack <= STROBE and DEVICE;
  FD_D_DTACK : FDC port map(d_dtack, dd_dtack, q_dtack, '1');
  FD_Q_DTACK : FD port map(q_dtack, SLOWCLK, d_dtack);
  DTACK    <= q_dtack;

end VMECONFREGS_Arch;
