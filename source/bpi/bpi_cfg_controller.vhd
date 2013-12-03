-- BPI_CFG_CONTROLLER: Sends the instructions to BPI_CTRL that Upload and Dowload
-- configuration registers to the PROM

library ieee;
library work;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use work.ucsb_types.all;

entity bpi_cfg_controller is
  generic (
    NREGS : integer := 16               -- Number of Configuration registers
    );  
  port(
    clk : in std_logic;
    rst : in std_logic;

-- From VMECONFREGS
    bpi_cfg_reg_we_o : out integer range 0 to NREGS;
    bpi_cfg_regs     : in  cfg_regs_array;

-- From/to BPI_PORT and BPI_CTRL  
    bpi_cfg_ul_start : in std_logic;
    bpi_cfg_dl_start : in std_logic;
    bpi_done         : in std_logic;
    bpi_status       : in std_logic_vector(15 downto 0);

    bpi_dis          : out std_logic;
    bpi_en           : out std_logic;
    bpi_cfg_reg_we_i : in  std_logic;
    bpi_cfg_busy     : out std_logic;
    bpi_cmd_fifo_we  : out std_logic;
    bpi_cmd_fifo_in  : out std_logic_vector(15 downto 0)
    );
end bpi_cfg_controller;

architecture bpi_cfg_ctrl_architecture of bpi_cfg_controller is

  type state_type is (IDLE, BPI_DISABLE, BPI_FIFO_LOAD_DL, BPI_ENABLE_DL, BPI_WAIT4DONE_DL,
                      BPI_FIFO_LOAD_UL, BPI_ENABLE_UL, BPI_WAIT4DONE_UL, BPI_FIFO_LOAD_ER,
                      BPI_ENABLE_ER, BPI_WAIT4DONE_ER);
  signal next_state, current_state : state_type;

  constant NW_ER : integer := 4;        -- 4 erase commands to parse
  constant NW_DL : integer := NREGS+4;
  constant NW_UL : integer := 4;

  type   fifo_data_dl is array (0 to NW_DL-1) of std_logic_vector(15 downto 0);
  signal bpi_cmd_fifo_data_dl : fifo_data_dl;

  type   fifo_data_ul is array (NW_UL-1 downto 0) of std_logic_vector(15 downto 0);
  signal bpi_cmd_fifo_data_ul : fifo_data_ul;

  type   fifo_data_er is array (0 to NW_ER) of std_logic_vector(15 downto 0);
  signal bpi_cmd_fifo_data_er : fifo_data_er;

  signal cnt_en, cnt_res : std_logic;
  signal cnt_out         : integer;

  signal bpi_cfg_ul : std_logic := '0';
  signal bpi_cfg_dl : std_logic := '0';

  signal bpi_cfg_ul_reset : std_logic := '0';
  signal bpi_cfg_dl_reset : std_logic := '0';

  signal bpi_cfg_reg_sel     : integer   := 0;
  signal bpi_cfg_reg_sel_rst : std_logic := '0';

begin

-- Unlock-erase assignments (setting up for DL to PROM)
  bpi_cmd_fifo_data_er(0) <= x"0ff7";   -- bank/block address
  bpi_cmd_fifo_data_er(1) <= x"0000";   -- block offset
  bpi_cmd_fifo_data_er(2) <= x"0014";   -- unlock (?)
  bpi_cmd_fifo_data_er(3) <= x"000a";   -- erase (?)

-- Download Assignments (Configuration Registers to PROM)
  bpi_cmd_fifo_data_dl(0) <= x"0ff7";   -- Load Address in Bank 0 / Block 127
  bpi_cmd_fifo_data_dl(1) <= x"0000";   -- Set Offset = 0 
  bpi_cmd_fifo_data_dl(2) <= x"01ec";   -- Buffer_Program - N = 16
  GEN_DATA : for index in 0 to NREGS-1 generate
    bpi_cmd_fifo_data_dl(index+3) <= bpi_cfg_regs(index);  -- Set data
  end generate GEN_DATA;
  bpi_cmd_fifo_data_dl(NREGS+3) <= x"0005";  -- Set Read Array Mode

-- Upload Assignments (PROM to Configuration Registers)
  bpi_cmd_fifo_data_ul(0) <= x"0ff7";   -- Load Address in Block 0
  bpi_cmd_fifo_data_ul(1) <= x"0000";   -- Set Offset = 0 
  bpi_cmd_fifo_data_ul(2) <= x"01e4";   -- Read_N - N = 16
  bpi_cmd_fifo_data_ul(3) <= x"0005";   -- Set Read Array Mode

-- UL and DL Registers
  ul_reg : process (RST, bpi_cfg_ul_start, bpi_cfg_ul_reset, bpi_cfg_dl_start, bpi_cfg_dl_reset)
  begin
    if (rst = '1') or (bpi_cfg_ul_reset = '1') then
      bpi_cfg_ul <= '0';
    elsif (rising_edge(bpi_cfg_ul_start)) then
      bpi_cfg_ul <= '1';
    end if;

    if (rst = '1') or (bpi_cfg_dl_reset = '1') then
      bpi_cfg_dl <= '0';
    elsif (rising_edge(bpi_cfg_dl_start)) then
      bpi_cfg_dl <= '1';
    end if;
  end process;

-- CFG_REG_WE generation (setting WE to NREGS implies no writing)
  we_proc : process (clk, bpi_cfg_ul, bpi_cfg_reg_we_i, bpi_cfg_reg_sel, bpi_cfg_reg_sel_rst, rst)
  begin
    if (rst = '1') or (bpi_cfg_reg_sel_rst = '1') then
      bpi_cfg_reg_sel <= 0;
    elsif (rising_edge(clk)) then
      if (bpi_cfg_reg_we_i = '1') then
        bpi_cfg_reg_sel <= bpi_cfg_reg_sel + 1;
      end if;
    end if;
  end process;
  bpi_cfg_reg_we_o <= bpi_cfg_reg_sel when (bpi_cfg_reg_we_i = '1' and bpi_cfg_reg_sel < NREGS) else NREGS;

-- Address Counter
  cnt_proc : process (clk, cnt_en, cnt_res, rst)
    variable cnt_data : integer;
  begin
    if (rst = '1') then
      cnt_data := 0;
    elsif (rising_edge(clk)) then
      if (cnt_res = '1') then
        cnt_data := 0;
      elsif (cnt_en = '1') then
        cnt_data := cnt_data + 1;
      end if;
    end if;
    cnt_out <= cnt_data;
  end process;

-- FSM 
  fsm_regs : process (next_state, rst, clk)
  begin
    if (rst = '1') then
      current_state <= IDLE;
    elsif rising_edge(clk) then
      current_state <= next_state;
    end if;
  end process;

  fsm_logic : process (bpi_cfg_ul, bpi_cfg_dl, bpi_done, cnt_out, bpi_status, current_state)
  begin
    bpi_en              <= '0';
    bpi_dis             <= '0';
    bpi_cfg_busy        <= '0';
    bpi_cmd_fifo_we     <= '0';
    bpi_cmd_fifo_in     <= (others => '0');
    cnt_en              <= '0';
    cnt_res             <= '0';
    bpi_cfg_ul_reset    <= '0';
    bpi_cfg_dl_reset    <= '0';
    bpi_cfg_reg_sel_rst <= '0';

    case current_state is
      when IDLE =>
        if (bpi_cfg_ul = '1') or (bpi_cfg_dl = '1') then
          next_state <= BPI_DISABLE;
        else
          next_state <= IDLE;
        end if;

      when BPI_DISABLE =>
        bpi_dis      <= '1';
        bpi_cfg_busy <= '1';
        cnt_en       <= '1';
        cnt_res      <= '1';
        if (bpi_cfg_ul = '1') then
          next_state <= BPI_FIFO_LOAD_UL;
        elsif (bpi_cfg_dl = '1') then
          next_state <= BPI_FIFO_LOAD_ER;
        end if;

      when BPI_FIFO_LOAD_ER =>
        bpi_cfg_busy <= '1';
        cnt_en       <= '1';
        if (cnt_out < NW_ER) then
          bpi_cmd_fifo_we <= '1';
          bpi_cmd_fifo_in <= bpi_cmd_fifo_data_er(cnt_out);
          next_state      <= BPI_FIFO_LOAD_ER;
        else
          bpi_cmd_fifo_we <= '0';
          bpi_cmd_fifo_in <= (others => '0');
          next_state      <= BPI_ENABLE_ER;
        end if;
        
      when BPI_ENABLE_ER =>
        bpi_en       <= '1';
        bpi_cfg_busy <= '1';
        cnt_res      <= '1';            -- Reset counter for DL
        next_state   <= BPI_WAIT4DONE_ER;

      when BPI_WAIT4DONE_ER =>
        bpi_cfg_busy <= '1';
        if (bpi_status(7) = '1') then
          next_state <= BPI_FIFO_LOAD_DL;
          bpi_dis    <= '1';
          cnt_en     <= '1';
        else
          next_state <= BPI_WAIT4DONE_ER;
        end if;
        
      when BPI_FIFO_LOAD_DL =>
        bpi_cfg_busy <= '1';
        cnt_en       <= '1';
        if (cnt_out < NW_DL) then
          bpi_cmd_fifo_we <= '1';
          bpi_cmd_fifo_in <= bpi_cmd_fifo_data_dl(cnt_out);
          next_state      <= BPI_FIFO_LOAD_DL;
        else
          bpi_cmd_fifo_we <= '0';
          bpi_cmd_fifo_in <= (others => '0');
          next_state      <= BPI_ENABLE_DL;
        end if;

      when BPI_ENABLE_DL =>
        bpi_en       <= '1';
        bpi_cfg_busy <= '1';
        next_state   <= BPI_WAIT4DONE_DL;

      when BPI_WAIT4DONE_DL =>
        bpi_cfg_busy <= '1';
        if (bpi_done = '1') then
          bpi_cfg_dl_reset <= '1';
          next_state       <= IDLE;
        else
          bpi_cfg_dl_reset <= '0';
          next_state       <= BPI_WAIT4DONE_DL;
        end if;

      when BPI_FIFO_LOAD_UL =>
        bpi_cfg_busy <= '1';
        cnt_en       <= '1';
        if (cnt_out < NW_UL) then
          bpi_cmd_fifo_we <= '1';
          bpi_cmd_fifo_in <= bpi_cmd_fifo_data_ul(cnt_out);
          next_state      <= BPI_FIFO_LOAD_UL;
        else
          bpi_cmd_fifo_we <= '0';
          bpi_cmd_fifo_in <= (others => '0');
          next_state      <= BPI_ENABLE_UL;
        end if;

      when BPI_ENABLE_UL =>
        bpi_en              <= '1';
        bpi_cfg_busy        <= '1';
        bpi_cfg_reg_sel_rst <= '1';
        next_state          <= BPI_WAIT4DONE_UL;

      when BPI_WAIT4DONE_UL =>
        bpi_cfg_busy <= '1';
        if (bpi_done = '1') then
          bpi_cfg_ul_reset <= '1';
          next_state       <= IDLE;
        else
          bpi_cfg_ul_reset <= '0';
          next_state       <= BPI_WAIT4DONE_UL;
        end if;

    end case;
  end process;
  
end bpi_cfg_ctrl_architecture;
