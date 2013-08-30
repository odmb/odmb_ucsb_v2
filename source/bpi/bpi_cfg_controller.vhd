library IEEE;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_1164.all;

entity bpi_cfg_controller is
  port(

    clk : in std_logic;
    rst : in std_logic;

    bpi_cfg_ul_start : in std_logic;
    bpi_cfg_dl_start : in std_logic;
    bpi_cfg_done     : in std_logic;
    bpi_cfg_reg0     : in std_logic_vector(15 downto 0);
    bpi_cfg_reg1     : in std_logic_vector(15 downto 0);
    bpi_cfg_reg2     : in std_logic_vector(15 downto 0);
    bpi_cfg_reg3     : in std_logic_vector(15 downto 0);

    bpi_dis          : out std_logic;
    bpi_en           : out std_logic;
    bpi_cfg_reg_we_i : in  std_logic;
    bpi_cfg_reg_we_o : out std_logic_vector(3 downto 0);
    bpi_cfg_busy     : out std_logic;
    bpi_cfg_data_sel : in  std_logic;
    bpi_cmd_fifo_we  : out std_logic;
    bpi_cmd_fifo_in  : out std_logic_vector(15 downto 0)

    );

end bpi_cfg_controller;

--}} End of automatically maintained section

architecture bpi_cfg_ctrl_architecture of bpi_cfg_controller is

  type state_type is (IDLE, BPI_DISABLE, BPI_FIFO_LOAD_DL, BPI_ENABLE_DL, BPI_WAIT4DONE_DL,
                      BPI_FIFO_LOAD_UL, BPI_ENABLE_UL, BPI_WAIT4DONE_UL);

  signal next_state, current_state : state_type;

  constant NW_DL : integer := 19;       -- 4xN_REGS
  constant NW_UL : integer := 12;       -- 3xN_REGS

  type fifo_data_dl is array (NW_DL-1 downto 0) of std_logic_vector(15 downto 0);

  signal bpi_cmd_fifo_data_dl : fifo_data_dl;

  type fifo_data_ul is array (NW_UL-1 downto 0) of std_logic_vector(15 downto 0);

  signal bpi_cmd_fifo_data_ul : fifo_data_ul;

  signal cnt_en, cnt_res : std_logic;
  signal cnt_out         : integer;

  signal bpi_cfg_ul : std_logic := '0';
  signal bpi_cfg_dl : std_logic := '0';

  signal bpi_cfg_ul_reset : std_logic := '0';
  signal bpi_cfg_dl_reset : std_logic := '0';

  signal bpi_cfg_reg_sel     : integer   := 0;
  signal bpi_cfg_reg_sel_rst : std_logic := '0';

begin

-- Download Assignments (Configuration Registers to PROM)
  
  bpi_cmd_fifo_data_dl(0) <= x"0017";   -- Load Address in Bank 0
  bpi_cmd_fifo_data_dl(1) <= x"0000";   -- Set Offset = 0 
  bpi_cmd_fifo_data_dl(2) <= x"0014";   -- Unlock Bank 0 (command = 0x14 => 0xe8)
  
  bpi_cmd_fifo_data_dl(3) <= x"0017";   -- Load Address in Bank 0
  bpi_cmd_fifo_data_dl(4) <= x"0000";   -- Set Offset = 0 
  bpi_cmd_fifo_data_dl(5) <= x"002b";  -- Program in Bank 0 (command = 0x0b => 0xe8)
  bpi_cmd_fifo_data_dl(6) <= x"fed0" when (bpi_cfg_data_sel = '0') else bpi_cfg_reg0;  -- Set Data
  
  bpi_cmd_fifo_data_dl(7) <= x"0017";   -- Load Address in Bank 1
  bpi_cmd_fifo_data_dl(8) <= x"0001";   -- Set Offset = 1 
  bpi_cmd_fifo_data_dl(9) <= x"002b";  -- Program in Bank 1 (command = 0x0b => 0xe8)
  bpi_cmd_fifo_data_dl(10)<= x"fed1" when (bpi_cfg_data_sel = '0') else bpi_cfg_reg1;  -- Set Data
  
  bpi_cmd_fifo_data_dl(11) <= x"0017";  -- Load Address in Bank 2
  bpi_cmd_fifo_data_dl(12) <= x"0002";  -- Set Offset = 2 
  bpi_cmd_fifo_data_dl(13) <= x"002b";  -- Program in Bank 2 (command = 0x0b => 0xe8)
  bpi_cmd_fifo_data_dl(14) <= x"fed2" when (bpi_cfg_data_sel = '0') else bpi_cfg_reg2;  -- Set Data
  
  bpi_cmd_fifo_data_dl(15) <= x"0017";  -- Load Address in Bank 3
  bpi_cmd_fifo_data_dl(16) <= x"0003";  -- Set Offset = 3 
  bpi_cmd_fifo_data_dl(17) <= x"002b";  -- Program in Bank 3 (command = 0x0b => 0xe8)
  bpi_cmd_fifo_data_dl(18) <= x"fed3" when (bpi_cfg_data_sel = '0') else bpi_cfg_reg3;  -- Set Data

-- Upload Assignments (PROM to Configuration Registers)

  bpi_cmd_fifo_data_ul(0) <= x"0017";   -- Load Address in Bank 0
  bpi_cmd_fifo_data_ul(1) <= x"0000";   -- Set Offset = 0 
  bpi_cmd_fifo_data_ul(2) <= x"0002";   -- Read One Word 

  bpi_cmd_fifo_data_ul(3) <= x"0017";   -- Load Address in Bank 1
  bpi_cmd_fifo_data_ul(4) <= x"0001";   -- Set Offset = 1 
  bpi_cmd_fifo_data_ul(5) <= x"0002";   -- Read One Word 

  bpi_cmd_fifo_data_ul(6) <= x"0017";   -- Load Address in Bank 2
  bpi_cmd_fifo_data_ul(7) <= x"0002";   -- Set Offset = 0 
  bpi_cmd_fifo_data_ul(8) <= x"0002";   -- Read One Word 

  bpi_cmd_fifo_data_ul(9)  <= x"0017";  -- Load Address in Bank 3
  bpi_cmd_fifo_data_ul(10) <= x"0003";  -- Set Offset = 1 
  bpi_cmd_fifo_data_ul(11) <= x"0002";  -- Read One Word 

-- UL and DL Registers

  ul_reg : process (clk, bpi_cfg_ul_start, bpi_cfg_ul_reset, rst)

  begin

--      if (rst = '1') then
--              bpi_cfg_ul <= '0';
--      elsif (rising_edge(clk)) then
--        if (bpi_cfg_ul_start = '1') then
--                bpi_cfg_ul <= '1';
--        elsif (bpi_cfg_ul_reset = '1') then
--                bpi_cfg_ul <= '0';
--              end if;              
--      end if; 

    if (rst = '1') or (bpi_cfg_ul_reset = '1') then
      bpi_cfg_ul <= '0';
    elsif (rising_edge(bpi_cfg_ul_start)) then
      bpi_cfg_ul <= '1';
    end if;

  end process;

  dl_reg : process (clk, bpi_cfg_dl_start, bpi_cfg_dl_reset, rst)

  begin

--      if (rst = '1') then
--              bpi_cfg_dl <= '0';
--      elsif (rising_edge(clk)) then
--        if (bpi_cfg_dl_start = '1') then
--                bpi_cfg_dl <= '1';
--        elsif (bpi_cfg_dl_reset = '1') then
--                bpi_cfg_dl <= '0';
--              end if;              
--      end if; 

    if (rst = '1') or (bpi_cfg_dl_reset = '1') then
      bpi_cfg_dl <= '0';
    elsif (rising_edge(bpi_cfg_dl_start)) then
      bpi_cfg_dl <= '1';
    end if;

  end process;

-- CFG_REG_WE generation

  we_proc : process (clk, bpi_cfg_reg_we_i, bpi_cfg_reg_sel, bpi_cfg_reg_sel_rst, rst)

  begin

    if (rst = '1') or (bpi_cfg_reg_sel_rst = '1') then
      bpi_cfg_reg_sel <= 0;
    elsif (rising_edge(clk)) then
      if (bpi_cfg_reg_we_i = '1') then
        bpi_cfg_reg_sel <= bpi_cfg_reg_sel + 1;
      end if;
    end if;

    for i in 0 to 3 loop
      if (i = bpi_cfg_reg_sel) then
        bpi_cfg_reg_we_o(i) <= bpi_cfg_reg_we_i;
      else
        bpi_cfg_reg_we_o(i) <= '0';
      end if;
    end loop;

    
  end process;

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

  fsm_logic : process (bpi_cfg_ul, bpi_cfg_dl, bpi_cfg_done, cnt_out, current_state)

  begin
    
    case current_state is
      
      when IDLE =>
        
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
        if (bpi_cfg_ul = '1') or (bpi_cfg_dl = '1') then
          next_state <= BPI_DISABLE;
        else
          next_state <= IDLE;
        end if;
        
      when BPI_DISABLE =>
        
        bpi_en              <= '0';
        bpi_dis             <= '1';
        bpi_cfg_busy        <= '1';
        bpi_cmd_fifo_we     <= '0';
        bpi_cmd_fifo_in     <= (others => '0');
        cnt_en              <= '1';
        cnt_res             <= '1';
        bpi_cfg_ul_reset    <= '0';
        bpi_cfg_dl_reset    <= '0';
        bpi_cfg_reg_sel_rst <= '0';
        if (bpi_cfg_ul = '1') then
          next_state <= BPI_FIFO_LOAD_UL;
        elsif (bpi_cfg_dl = '1') then
          next_state <= BPI_FIFO_LOAD_DL;
        end if;
        
      when BPI_FIFO_LOAD_UL =>

        bpi_en              <= '0';
        bpi_dis             <= '0';
        bpi_cfg_busy        <= '1';
        cnt_en              <= '1';
        cnt_res             <= '0';
        bpi_cfg_ul_reset    <= '0';
        bpi_cfg_dl_reset    <= '0';
        bpi_cfg_reg_sel_rst <= '0';
        if (cnt_out < NW_UL) then
          bpi_cmd_fifo_we <= '1';
          bpi_cmd_fifo_in <= bpi_cmd_fifo_data_ul(cnt_out);
          next_state      <= BPI_FIFO_LOAD_UL;
        else
          bpi_cmd_fifo_we <= '0';
          bpi_cmd_fifo_in <= (others => '0');
          next_state      <= BPI_ENABLE_UL;
        end if;

      when BPI_FIFO_LOAD_DL =>

        bpi_en              <= '0';
        bpi_dis             <= '0';
        bpi_cfg_busy        <= '1';
        cnt_en              <= '1';
        cnt_res             <= '0';
        bpi_cfg_ul_reset    <= '0';
        bpi_cfg_dl_reset    <= '0';
        bpi_cfg_reg_sel_rst <= '0';
        if (cnt_out < NW_DL) then
          bpi_cmd_fifo_we <= '1';
          bpi_cmd_fifo_in <= bpi_cmd_fifo_data_dl(cnt_out);
          next_state      <= BPI_FIFO_LOAD_DL;
        else
          bpi_cmd_fifo_we <= '0';
          bpi_cmd_fifo_in <= (others => '0');
          next_state      <= BPI_ENABLE_DL;
        end if;

      when BPI_ENABLE_UL =>
        
        bpi_en              <= '1';
        bpi_dis             <= '0';
        bpi_cfg_busy        <= '1';
        bpi_cmd_fifo_we     <= '0';
        bpi_cmd_fifo_in     <= (others => '0');
        cnt_en              <= '0';
        cnt_res             <= '0';
        bpi_cfg_ul_reset    <= '0';
        bpi_cfg_dl_reset    <= '0';
        bpi_cfg_reg_sel_rst <= '1';
        next_state          <= BPI_WAIT4DONE_UL;

      when BPI_ENABLE_DL =>
        
        bpi_en              <= '1';
        bpi_dis             <= '0';
        bpi_cfg_busy        <= '1';
        bpi_cmd_fifo_we     <= '0';
        bpi_cmd_fifo_in     <= (others => '0');
        cnt_en              <= '0';
        cnt_res             <= '0';
        bpi_cfg_ul_reset    <= '0';
        bpi_cfg_dl_reset    <= '0';
        bpi_cfg_reg_sel_rst <= '0';
        next_state          <= BPI_WAIT4DONE_DL;

      when BPI_WAIT4DONE_UL =>
        
        bpi_en              <= '0';
        bpi_dis             <= '0';
        bpi_cfg_busy        <= '1';
        bpi_cmd_fifo_we     <= '0';
        bpi_cmd_fifo_in     <= (others => '0');
        cnt_en              <= '0';
        cnt_res             <= '0';
        bpi_cfg_ul_reset    <= '1';
        bpi_cfg_dl_reset    <= '0';
        bpi_cfg_reg_sel_rst <= '0';
        if (bpi_cfg_done = '1') then
          next_state <= IDLE;
        else
          next_state <= BPI_WAIT4DONE_UL;
        end if;
        
      when BPI_WAIT4DONE_DL =>
        
        bpi_en              <= '0';
        bpi_dis             <= '0';
        bpi_cfg_busy        <= '1';
        bpi_cmd_fifo_we     <= '0';
        bpi_cmd_fifo_in     <= (others => '0');
        cnt_en              <= '0';
        cnt_res             <= '0';
        bpi_cfg_ul_reset    <= '0';
        bpi_cfg_dl_reset    <= '1';
        bpi_cfg_reg_sel_rst <= '0';
        if (bpi_cfg_done = '1') then
          next_state <= IDLE;
        else
          next_state <= BPI_WAIT4DONE_DL;
        end if;
        
      when others =>

        bpi_en           <= '0';
        bpi_dis          <= '0';
        bpi_cfg_busy     <= '0';
        bpi_cmd_fifo_we  <= '0';
        bpi_cmd_fifo_in  <= (others => '0');
        cnt_en           <= '0';
        cnt_res          <= '0';
        bpi_cfg_ul_reset <= '0';
        bpi_cfg_dl_reset <= '0';
        next_state       <= IDLE;
        
    end case;
    
  end process;
  
end bpi_cfg_ctrl_architecture;
