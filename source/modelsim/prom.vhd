-- PROM: Model of the XCF128XFTG Xilinx EPROM

library unisim;
library unimacro;
library hdlmacro;
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use hdlmacro.hdlmacro.all;

entity PROM is
  port(
    clk : in std_logic;
    rst : in std_logic;

    we_b : in std_logic;
    cs_b : in std_logic;
    oe_b : in std_logic;
    le_b : in std_logic;

    addr : in    std_logic_vector(22 downto 0);
    data : inout std_logic_vector(15 downto 0)
    );
end PROM;

architecture prom_architecture of PROM is

-- Sep 5
--constant NB : integer := 16;
  constant NBK : integer := 16;
  constant NBL : integer := 128;
  constant NWD : integer := 16;

--signal status_reg : std_logic_vector(15 downto 0) := "1111111010000000"; -- 0xf080

-- signal elec_sig : std_logic_vector(15 downto 0) := "1100111011001010"; -- 0xceca

  signal mem_out : std_logic_vector(15 downto 0) := (others => '0');

  signal read_status_reg : std_logic_vector(NBK-1 downto 0) := (others => '0');
  signal read_elec_sig   : std_logic_vector(NBK-1 downto 0) := (others => '0');
  signal read_array      : std_logic_vector(NBK-1 downto 0) := (others => '0');
  signal program         : std_logic_vector(NBK-1 downto 0) := (others => '0');
  signal buffer_program  : std_logic_vector(NBK-1 downto 0) := (others => '0');

  constant lock_unlock_code    : std_logic_vector(15 downto 0) := x"0060";
  constant unlock_confirm_code : std_logic_vector(15 downto 0) := x"00D0";
  constant lock_confirm_code   : std_logic_vector(15 downto 0) := x"0001";

  constant read_status_reg_code : std_logic_vector(15 downto 0) := x"0070";
  constant read_elec_sig_code   : std_logic_vector(15 downto 0) := x"0090";
  constant read_array_code      : std_logic_vector(15 downto 0) := x"00ff";
  constant program_code         : std_logic_vector(15 downto 0) := x"0040";
  constant buffer_program_code  : std_logic_vector(15 downto 0) := x"00e8";


  signal bk_index : integer := 0;       -- bank address (0 -> 15)
  signal bl_index : integer := 0;       -- block address (0 -> 127)
  signal wd_index : integer := 0;       -- word address (0 -> 15)

  constant manufacturer_code : std_logic_vector(15 downto 0) := x"0049";  -- ES - Bank Address + 0 
  signal   device_code       : std_logic_vector(15 downto 0) := x"506B";  -- ES - Bank Address + 1 

  type   block_array is array (NWD-1 downto 0) of std_logic_vector(15 downto 0);
  type   prom_array is array (NBL-1 downto 0) of block_array;
  signal prom_data : prom_array;

  type   bank_regs is array (NBK-1 downto 0) of std_logic_vector(15 downto 0);
  signal command_reg       : bank_regs;  -- command register
  signal configuration_reg : bank_regs;  -- ES - Bank Address + 5
  signal bank_data         : bank_regs;
  signal bank_out          : bank_regs;
  signal status_reg        : bank_regs;  -- Status Register

  signal program_done : std_logic_vector(NBK-1 downto 0) := (others => '0');

  type   block_regs is array (NBL-1 downto 0) of std_logic_vector(15 downto 0);
  signal block_status : block_regs;     -- ES - Block Address + 2

  signal data_in, data_out : std_logic_vector(15 downto 0);

  signal latched_data : std_logic_vector(15 downto 0) := (others => '0');
  signal latched_addr : std_logic_vector(22 downto 0) := (others => '0');

  signal addr_cnt_out : std_logic_vector(22 downto 0) := (others => '0');

  type   state_type is (AG_IDLE, AG_RUN);
  type   state_array_type is array (NBK-1 downto 0) of state_type;
  signal next_state, current_state : state_array_type;
  signal ag_ld                     : std_logic_vector(NBK-1 downto 0) := (others => '0');
  signal ag_en                     : std_logic_vector(NBK-1 downto 0) := (others => '0');
  signal ag_lw                     : std_logic_vector(NBK-1 downto 0) := (others => '0');
  type   integer_array is array (NBK-1 downto 0) of integer;
  signal ag_ad_cnt_out             : integer_array;
  signal ag_nw_cnt_out             : integer_array;

  signal int_addr : integer;
  signal int_data : integer;

begin

  bk_index <= to_integer(unsigned(latched_addr(22 downto 19)));
  bl_index <= to_integer(unsigned(latched_addr(22 downto 16)));

  wd_index <= to_integer(unsigned(latched_addr(3 downto 0)));

  int_addr <= to_integer(unsigned(addr(15 downto 0)));
  int_data <= to_integer(unsigned(data(15 downto 0)));

  block_status_proc : process (rst, command_reg, bl_index, bk_index)
  begin
    for i in 0 to NBL-1 loop
      if (rst = '1') then
        block_status(i)(15 downto 1) <= (others => '0');
        block_status(i)(0)           <= '1';
      end if;
    end loop;

    for i in 0 to NBL-1 loop
      if (command_reg(bk_index) = unlock_confirm_code) and (i = bl_index) then
        block_status(i)(15 downto 1) <= (others => '0');
        block_status(i)(0)           <= '0';
      elsif (command_reg(bk_index) = lock_confirm_code) and (i = bl_index) then
        block_status(i)(15 downto 1) <= (others => '0');
        block_status(i)(0)           <= '1';
      end if;
    end loop;
  end process;

  configuration_reg_proc : process (rst)
  begin
    for i in 0 to NBK-1 loop
      if (rst = '1') then
        configuration_reg(i)(15 downto 4) <= "110011001100";
        configuration_reg(i)(3 downto 0)  <= std_logic_vector(to_unsigned(i, 4));
      end if;
    end loop;
  end process;

  status_reg_proc : process (rst)
  begin

    for i in 0 to NBK-1 loop
      if (rst = '1') then
        status_reg(i)(15 downto 12) <= "1111";
        status_reg(i)(11 downto 8)  <= std_logic_vector(to_unsigned(i, 4));
        status_reg(i)(7 downto 0)   <= "10000000";
      end if;
    end loop;
  end process;

-- Latch Command/Data

  ld_proc : process (we_b, cs_b, data_in, bk_index, command_reg, rst)
  begin
    for i in 0 to NBK-1 loop
      if (rst = '1') then
        command_reg(i) <= read_array_code;
      elsif rising_edge(we_b) and (i = bk_index) and ((command_reg(i) = read_array_code) or (data_in = read_array_code)) then
        command_reg(i) <= data_in;
      elsif rising_edge(we_b) and (i = bk_index) and ((command_reg(i) = lock_unlock_code) and (data_in = unlock_confirm_code)) then
        command_reg(i) <= data_in;
      elsif rising_edge(we_b) and (i = bk_index) and ((command_reg(i) = unlock_confirm_code) and (data_in = read_elec_sig_code)) then
        command_reg(i) <= data_in;
      end if;
    end loop;
  end process;

-- Latch Address

  la_proc : process (le_b, cs_b, addr)
  begin
    if rising_edge(le_b) then
      latched_addr <= addr;
    end if;
  end process;

  cmd_dec_proc : process (clk, command_reg)
  begin
    for i in 0 to NBK-1 loop
      if (command_reg(i) = read_status_reg_code) then  -- 0x70
        read_status_reg(i) <= '1';
      else
        read_status_reg(i) <= '0';
      end if;

      if (command_reg(i) = read_elec_sig_code) then  -- 0x90
        read_elec_sig(i) <= '1';
      else
        read_elec_sig(i) <= '0';
      end if;

      if (command_reg(i) = read_array_code) then  -- 0xff
        read_array(i) <= '1';
      else
        read_array(i) <= '0';
      end if;

      if (command_reg(i) = program_code) then  -- 0x40
        program(i) <= '1';
      else
        program(i) <= '0';
      end if;

      if (command_reg(i) = buffer_program_code) then  -- 0xe8
        buffer_program(i) <= '1';
      else
        buffer_program(i) <= '0';
      end if;
    end loop;
  end process;

  out_mux_proc : process (read_status_reg, status_reg, read_elec_sig, read_array, bank_data,
                          bank_out, bk_index, bl_index, wd_index, block_status)
  begin
    for i in 0 to NBK-1 loop
      if (i = bk_index) and (read_status_reg(i) = '1') then
        bank_out(i) <= status_reg(i);
      elsif (i = bk_index) and (read_elec_sig(i) = '1') then
        if (wd_index = 0) then
          bank_out(i) <= manufacturer_code;
        elsif (wd_index = 1) then
          bank_out(i) <= device_code;
        elsif (wd_index = 2) then
          bank_out(i) <= block_status(bl_index);
        elsif (wd_index = 5) then
          bank_out(i) <= configuration_reg(i);
        end if;
      elsif (i = bk_index) and (read_array(i) = '1') then
        bank_out(i) <= bank_data(i);
      else
        bank_out(i) <= status_reg(i);
      end if;
    end loop;

    data_out <= bank_out(bk_index);
  end process;

-- Address Generator for Buffer_Program and Read_N

  ag_fsm_state_regs : process (next_state, rst, we_b)
  begin
    for i in 0 to NBK-1 loop
      if (rst = '1') then
        current_state(i) <= AG_IDLE;
      elsif rising_edge(we_b) then
        current_state(i) <= next_state(i);
      end if;
    end loop;
  end process;


  ag_fsm_comb_logic : process(current_state, ag_nw_cnt_out, command_reg)
  begin
    for i in 0 to NBK-1 loop
      case current_state(i) is
        when AG_IDLE =>
          ag_en(i) <= '0';
          ag_lw(i) <= '0';
          if (command_reg(i) = buffer_program_code) then
            ag_ld(i)      <= '1';
            next_state(i) <= AG_RUN;
          else
            ag_ld(i)      <= '0';
            next_state(i) <= AG_IDLE;
          end if;
          
        when AG_RUN =>
          ag_ld(i) <= '0';
          ag_en(i) <= '1';
          if (ag_nw_cnt_out(i) = 0) then
            ag_lw(i)      <= '1';
            next_state(i) <= AG_IDLE;
          else
            ag_lw(i)      <= '0';
            next_state(i) <= AG_RUN;
          end if;

        when others =>
          ag_ld(i)      <= '0';
          ag_en(i)      <= '0';
          ag_lw(i)      <= '0';
          next_state(i) <= AG_IDLE;
      end case;
    end loop;
  end process;

  ag_ad_cnt_proc : process (rst, we_b, int_addr, ag_ld, ag_en)
    variable ag_ad_cnt_data : integer_array;
  begin
    for i in 0 to NBK-1 loop
      if (rst = '1') then
        ag_ad_cnt_data(i) := 0;
      elsif (rising_edge(we_b)) then
        if (ag_ld(i) = '1') then
          ag_ad_cnt_data(i) := int_addr;
        elsif (ag_en(i) = '1') then
          ag_ad_cnt_data(i) := ag_ad_cnt_data(i) + 1;
        end if;
      end if;

      ag_ad_cnt_out(i) <= ag_ad_cnt_data(i);
    end loop;
  end process;

  ag_nw_cnt_proc : process (rst, we_b, int_data, ag_ld, ag_en)
    variable ag_nw_cnt_data : integer_array;
  begin
    for i in 0 to NBK-1 loop
      if (rst = '1') then
        ag_nw_cnt_data(i) := 0;
      elsif (rising_edge(we_b)) then
        if (ag_ld(i) = '1') then
          ag_nw_cnt_data(i) := int_data;
        elsif (ag_en(i) = '1') then
          ag_nw_cnt_data(i) := ag_nw_cnt_data(i) - 1;
        end if;
      end if;

      ag_nw_cnt_out(i) <= ag_nw_cnt_data(i);
    end loop;
  end process;

-- Memory

  mem_proc : process (clk, cs_b, we_b, oe_b, bk_index, bl_index, command_reg, program_done,
                      data, rst, ag_en, ag_lw)
  begin
-- Initial Memory Reset
    if (rst = '1') then
      for i in 0 to NBL-1 loop
        for j in 0 to NWD-1 loop
          prom_data(i)(j) <= (others => '1');
        end loop;
      end loop;

      for i in 0 to NBK-1 loop
        program_done(i) <= '0';
      end loop;
    end if;

-- Bank Write
    if (rising_edge(we_b)) then
      if ((command_reg(bk_index) = program_code) and (block_status(bl_index)(0) = '0') and (program_done(bk_index) = '0')) then
        prom_data(bl_index)(wd_index) <= data;
        program_done(bk_index)        <= '1';
      elsif ((command_reg(bk_index) = buffer_program_code) and (ag_en(bk_index) = '1') and (block_status(bl_index)(0) = '0') and (program_done(bk_index) = '0')) then
--      prom_data(bl_index)(ag_ad_cnt_out(bk_index)) <= data;
        prom_data(bl_index)(wd_index) <= data;
        program_done(bk_index)        <= ag_lw(bk_index);
      end if;
    end if;

    for i in 0 to NBK-1 loop
      if rising_edge(we_b) and (i = bk_index) and ((command_reg(i) = program_code) and (data_in = read_array_code)) then
        program_done(i) <= '0';
      elsif rising_edge(we_b) and (i = bk_index) and ((command_reg(i) = buffer_program_code) and (data_in = read_array_code)) then
        program_done(i) <= '0';
      end if;
    end loop;

-- Bank Read
    for i in 0 to NBK-1 loop
      if (command_reg(i) = read_array_code) and (cs_b = '0') and (oe_b = '0') and (rising_edge(clk)) then
        bank_data(i) <= prom_data(bl_index)(wd_index);
      end if;
    end loop;
  end process;

-- Bidirectional Port
  GEN_16 : for I in 0 to 15 generate
  begin
    DATA_BUF : IOBUF port map (O => data_in(I), IO => data(I), I => data_out(I), T => oe_b);
  end generate GEN_16;
  
end prom_architecture;
