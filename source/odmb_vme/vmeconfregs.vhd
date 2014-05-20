-- VMECONFREGS: Assigns values to the configuration registers and permanent registers.
-- Triple voting is employed for radiation hardness.

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
    NREGS  : integer := 16;             -- Number of Configuration registers
    NCONST : integer := 16;              -- Number of Protected registers
    NFEB   : integer := 7               -- Number of DCFEBs
    );    
  port (
    SLOWCLK : in std_logic;
    CLK     : in std_logic;
    RST     : in std_logic;

    DEVICE   : in  std_logic;
    STROBE   : in  std_logic;
    COMMAND  : in  std_logic_vector(9 downto 0);
    WRITER   : in  std_logic;
    DTACK    : out std_logic;
    VME_AS_B : in  std_logic;

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

-- Configuration registers    
    LCT_L1A_DLY   : out std_logic_vector(5 downto 0);
    OTMB_PUSH_DLY : out integer range 0 to 63;
    ALCT_PUSH_DLY : out integer range 0 to 63;

    INJ_DLY    : out std_logic_vector(4 downto 0);
    EXT_DLY    : out std_logic_vector(4 downto 0);
    CALLCT_DLY : out std_logic_vector(3 downto 0);

    ODMB_ID      : out std_logic_vector(15 downto 0);
    NWORDS_DUMMY : out std_logic_vector(15 downto 0);
    KILL         : out std_logic_vector(NFEB+2 downto 1);
    CRATEID      : out std_logic_vector(7 downto 0);

-- From BPI_PORT
    BPI_CFG_UL_PULSE   : in std_logic;
    BPI_CFG_DL_PULSE   : in std_logic;
    BPI_CONST_UL_PULSE : in std_logic;
    BPI_CONST_DL_PULSE : in std_logic;

-- From BPI_CTRL
    CC_CFG_REG_IN : in std_logic_vector(15 downto 0);

-- From/to BPI_CFG_CONTROLLER
    BPI_CFG_BUSY    : in  std_logic;
    BPI_CONST_BUSY  : in  std_logic;
    CC_CFG_REG_WE   : in  integer range 0 to NREGS;
    CC_CONST_REG_WE : in  integer range 0 to NREGS;
    BPI_CFG_REGS    : out cfg_regs_array;
    BPI_CONST_REGS  : out cfg_regs_array
    );
end VMECONFREGS;


architecture VMECONFREGS_Arch of VMECONFREGS is

  constant FW_VERSION       : std_logic_vector(15 downto 0) := x"0305";
  constant FW_ID            : std_logic_vector(15 downto 0) := x"0001";
  constant FW_MONTH_DAY     : std_logic_vector(15 downto 0) := x"0520";
  constant FW_YEAR          : std_logic_vector(15 downto 0) := x"2014";
  constant able_write_const : std_logic                     := '0';

  constant cfg_reg_mask_we   : std_logic_vector(15 downto 0) := x"FDFF";
  constant const_reg_mask_we : std_logic_vector(15 downto 0) := x"FFE1";
  constant cfg_reg_init : cfg_regs_array := (x"FFF0", x"FFF1", x"FFF2", x"FFF3",
                                             x"FFF4", x"FFF5", x"FFF6", x"FFF7",
                                             x"FFF8", FW_VERSION, x"FFFA", x"FFFB",
                                             x"FFFC", x"FFFD", x"FFFE", x"FFFF");
  constant const_reg_init : cfg_regs_array := (x"FFF0", FW_VERSION, FW_ID, FW_MONTH_DAY, 
                                               FW_YEAR, x"FFF5", x"FFF6", x"FFF7",
                                               x"FFF8", x"FFF9", x"FFFA", x"FFFB",
                                               x"FFFC", x"FFFD", x"FFFE", x"FFFF");
  constant cfg_reg_mask : cfg_regs_array := (x"003f", x"003f", x"003f", x"003f", x"001f",
                                             x"001f", x"000f", x"01ff", x"00ff", x"ffff",
                                             x"ffff", x"ffff", x"ffff", x"ffff", x"ffff", x"ffff");
  signal cfg_reg_clk, const_reg_clk, do_cfg, do_const : std_logic := '0';
  signal bit_const                                    : std_logic := '0';

  type   rh_reg is array (2 downto 0) of std_logic_vector(15 downto 0);
  type   rh_reg_array is array (0 to NREGS) of rh_reg;
  signal cfg_reg_triple : rh_reg_array;
  signal cfg_regs       : cfg_regs_array;

  signal cfg_reg_we, cfg_reg_index, vme_cfg_reg_we : integer range 0 to NREGS;
  signal cfg_reg_in                                : std_logic_vector(15 downto 0) := (others => '0');

  signal const_reg_triple : rh_reg_array;
  signal const_regs       : cfg_regs_array;

  signal const_reg_index, const_reg_index_p1 : integer range 0 to NCONST;
  signal const_reg_we, vme_const_reg_we      : integer range 0 to NREGS;
  signal const_reg_in                        : std_logic_vector(15 downto 0) := (others => '0');

  signal cmddev                     : std_logic_vector (15 downto 0);
  signal dd_dtack, d_dtack, q_dtack : std_logic := '0';

  signal   w_mask_vme, r_mask_vme     : std_logic;
  constant mask_vme_def               : std_logic_vector(NCONST-1 downto 0) := (others => '0');
  signal   mask_vme                   : std_logic_vector(15 downto 0)       := (others => '0');
  signal   mask_vme_rst, mask_vme_pre : std_logic_vector(NCONST-1 downto 0);

begin

  cmddev    <= "000" & DEVICE & COMMAND & "00";
  bit_const <= or_reduce(cmddev(11 downto 8));

  do_cfg     <= '1' when ((cmddev and x"1F00") = x"1000")                               else '0';
  do_const   <= '1' when ((cmddev and x"10FF") = x"1000" and bit_const = '1')           else '0';
  w_mask_vme <= '1' when (cmddev = x"1FFC" and WRITER = '0' and able_write_const = '1') else '0';
  r_mask_vme <= '1' when (cmddev = x"1FFC" and WRITER = '1')                            else '0';

-- Write MASK_VME
  GEN_MASK_VME : for i in 0 to NCONST-1 generate
  begin
    mask_vme_pre(i) <= RST when mask_vme_def(i) = '1' else '0';
    mask_vme_rst(i) <= RST when mask_vme_def(i) = '0' else '0';
    fd_w_mask_vme : fdcpe port map(mask_vme(i), STROBE, w_mask_vme,
                                   mask_vme_rst(i), INDATA(i), mask_vme_pre(i));
  end generate GEN_MASK_VME;


-- Set write enables and output data
  cfg_reg_index <= to_integer(unsigned(cmddev(5 downto 2)));

  const_reg_index_p1 <= to_integer(unsigned(cmddev(11 downto 8)));
  const_reg_index    <= const_reg_index_p1 - 1 when const_reg_index_p1 > 0 else NCONST;

  OUTDATA <= mask_vme when r_mask_vme = '1' else
             const_regs(const_reg_index) when do_const = '1' else
             cfg_regs(cfg_reg_index) and cfg_reg_mask(cfg_reg_index);
  BPI_CFG_REGS   <= cfg_regs;
  BPI_CONST_REGS <= const_regs;

  LCT_L1A_DLY   <= cfg_regs(0)(5 downto 0);                        -- 0x4000
  OTMB_PUSH_DLY <= to_integer(unsigned(cfg_regs(1)(5 downto 0)));  -- 0x4004
  ALCT_PUSH_DLY <= to_integer(unsigned(cfg_regs(3)(5 downto 0)));  -- 0x400C
  INJ_DLY       <= cfg_regs(4)(4 downto 0);                        -- 0x4010
  EXT_DLY       <= cfg_regs(5)(4 downto 0);                        -- 0x4014
  CALLCT_DLY    <= cfg_regs(6)(3 downto 0);                        -- 0x4018
  KILL          <= cfg_regs(7)(NFEB+1 downto 0);                   -- 0x401C
  CRATEID       <= cfg_regs(8)(7 downto 0);                        -- 0x4020
  NWORDS_DUMMY  <= cfg_regs(10)(15 downto 0);                      -- 0x4028

  ODMB_ID <= const_regs(0)(15 downto 0);  -- 0x4100

  -- Writing configuration registers
  cfg_reg_clk <= STROBE when (BPI_CFG_UL_PULSE = '0' and BPI_CONST_UL_PULSE = '0') else CLK;
  vme_cfg_reg_we <= cfg_reg_index when (do_cfg = '1' and WRITER = '0' and VME_AS_B = '0'
                                        and BPI_CFG_BUSY = '0') else NREGS;

  cfg_reg_we <= vme_cfg_reg_we when (BPI_CFG_UL_PULSE = '0') else cc_cfg_reg_we;
  cfg_reg_in <= INDATA         when (BPI_CFG_UL_PULSE = '0') else cc_cfg_reg_in;

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

  GEN_CFG_TRIPLEVOTING : for ind in 0 to NREGS-1 generate
  begin
    cfg_regs(ind) <= cfg_reg_triple(ind)(0) when (cfg_reg_triple(ind)(0) = cfg_reg_triple(ind)(1)) else
                     cfg_reg_triple(ind)(0) when (cfg_reg_triple(ind)(0) = cfg_reg_triple(ind)(2)) else
                     cfg_reg_triple(ind)(1) when (cfg_reg_triple(ind)(1) = cfg_reg_triple(ind)(2)) else
                     cfg_reg_triple(ind)(0);
  end generate GEN_CFG_TRIPLEVOTING;
  
  -- ml_proc : process (cfg_reg_triple)    -- Triple voting
  -- begin
  --   for i in 0 to NREGS-1 loop
  --     if (cfg_reg_triple(i)(0) = cfg_reg_triple(i)(1)) then
  --       cfg_regs(i) <= cfg_reg_triple(i)(0);
  --     elsif (cfg_reg_triple(i)(0) = cfg_reg_triple(i)(2)) then
  --       cfg_regs(i) <= cfg_reg_triple(i)(0);
  --     elsif (cfg_reg_triple(i)(1) = cfg_reg_triple(i)(2)) then
  --       cfg_regs(i) <= cfg_reg_triple(i)(1);
  --     end if;
  --   end loop;
  -- end process;

  -- Writing protected registers
  const_reg_clk <= STROBE when (BPI_CONST_UL_PULSE = '0') else CLK;
  vme_const_reg_we <= const_reg_index when (do_const = '1' and WRITER = '0' and BPI_CONST_BUSY = '0'
                                            and VME_AS_B = '0' and mask_vme(const_reg_index) = '1') else NCONST;

  const_reg_we <= vme_const_reg_we when (BPI_CONST_UL_PULSE = '0') else cc_const_reg_we;
  const_reg_in <= INDATA           when (BPI_CONST_UL_PULSE = '0') else cc_cfg_reg_in;

  const_reg_proc : process (RST, const_reg_clk, const_reg_we, const_reg_in, const_regs)
  begin
    for i in 0 to NCONST-1 loop
      for j in 0 to 2 loop
        if (RST = '1') then
          const_reg_triple(i)(j) <= const_reg_init(i);
        elsif (rising_edge(const_reg_clk) and const_reg_we = i and const_reg_mask_we(i) = '1') then
          const_reg_triple(i)(j) <= const_reg_in;
        else
          const_reg_triple(i)(j) <= const_regs(i);
        end if;
      end loop;
    end loop;
  end process;

  GEN_CONST_TRIPLEVOTING : for ind in 0 to NCONST-1 generate
  begin
    const_regs(ind) <= const_reg_triple(ind)(0) when (const_reg_triple(ind)(0) = const_reg_triple(ind)(1)) else
                     const_reg_triple(ind)(0) when (const_reg_triple(ind)(0) = const_reg_triple(ind)(2)) else
                     const_reg_triple(ind)(1) when (const_reg_triple(ind)(1) = const_reg_triple(ind)(2)) else
                     const_reg_triple(ind)(0);
  end generate GEN_CONST_TRIPLEVOTING;
  
  --const_ml_proc : process (const_reg_triple)  -- Triple voting
  --begin
  --  for i in 0 to NCONST-1 loop
  --    if (const_reg_triple(i)(0) = const_reg_triple(i)(1)) then
  --      const_regs(i) <= const_reg_triple(i)(0);
  --    elsif (const_reg_triple(i)(0) = const_reg_triple(i)(2)) then
  --      const_regs(i) <= const_reg_triple(i)(0);
  --    elsif (const_reg_triple(i)(1) = const_reg_triple(i)(2)) then
  --      const_regs(i) <= const_reg_triple(i)(1);
  --    end if;
  --  end loop;
  --end process;

-- DTACK
  dd_dtack <= STROBE and DEVICE;
  FD_D_DTACK : FDC port map(d_dtack, dd_dtack, q_dtack, '1');
  FD_Q_DTACK : FD port map(q_dtack, SLOWCLK, d_dtack);
  DTACK    <= q_dtack;

end VMECONFREGS_Arch;
