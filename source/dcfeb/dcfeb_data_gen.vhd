---------------------------------------------------------------------------------------------------
--
-- Title       : dcfeb data generator
-- Design      : 
-- Author      : Guido Magazzù
--
---------------------------------------------------------------------------------------------------
--
-- Description : tx_ctrl RAM FLF
--
---------------------------------------------------------------------------------------------------

library IEEE;
library unisim;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_1164.all;
library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use UNIMACRO.vcomponents.all;
use unisim.vcomponents.all;

entity dcfeb_data_gen is
  port(

    clk       : in std_logic;
    dcfebclk     : in std_logic;
    rst       : in std_logic;
    l1a       : in std_logic;
    l1a_match : in std_logic;

    tx_ack : in std_logic;

    dcfeb_addr : in std_logic_vector(3 downto 0);

    dcfeb_dv   : out std_logic;
    dcfeb_data : out std_logic_vector(15 downto 0)

    );

end dcfeb_data_gen;

--}} End of automatically maintained section

architecture dcfeb_data_gen_architecture of dcfeb_data_gen is

  type state_type is (IDLE, TX_HEADER1, TX_HEADER2, TX_DATA);

  signal next_state, current_state : state_type;

  signal dw_cnt_en, dw_cnt_rst : std_logic;
  signal l1a_cnt_out           : std_logic_vector(23 downto 0);
  signal dw_cnt_out            : std_logic_vector(11 downto 0);
  constant dw_n                : std_logic_vector(11 downto 0) := x"008"; -- x"320" -> 800

  signal tx_start              : std_logic;

  signal l1a_cnt_l_fifo_in     : std_logic_vector(17 downto 0);
  signal l1a_cnt_l_fifo_out    : std_logic_vector(17 downto 0);
  signal l1a_cnt_l_fifo_wrc    : std_logic_vector(9 downto 0);
  signal l1a_cnt_l_fifo_rdc    : std_logic_vector(9 downto 0);
  signal l1a_cnt_l_fifo_empty  : std_logic;
  signal l1a_cnt_l_fifo_full  : std_logic;

  signal l1a_cnt_h_fifo_in     : std_logic_vector(17 downto 0);
  signal l1a_cnt_h_fifo_out    : std_logic_vector(17 downto 0);
  signal l1a_cnt_h_fifo_wrc    : std_logic_vector(9 downto 0);
  signal l1a_cnt_h_fifo_rdc    : std_logic_vector(9 downto 0);
  signal l1a_cnt_h_fifo_empty  : std_logic;
  signal l1a_cnt_h_fifo_full  : std_logic;
  
  signal l1a_cnt_fifo_wr_en    : std_logic;
  signal l1a_cnt_fifo_rd_en    : std_logic;


  signal tx_start_d            : std_logic;

begin

-- l1a_counter
  
  l1a_cnt : process (clk, l1a, rst)

    variable l1a_cnt_data : std_logic_vector(23 downto 0);

  begin

    if (rst = '1') then
      l1a_cnt_data := (others => '0');
    elsif (rising_edge(clk)) then
      if (l1a = '1') then
        l1a_cnt_data := l1a_cnt_data + 1;
      end if;
    end if;

    l1a_cnt_out <= l1a_cnt_data;
    
  end process;

  l1a_cnt_l_fifo_in <= "000000" & l1a_cnt_out(11 downto 0);
  l1a_cnt_h_fifo_in <= "000000" & l1a_cnt_out(23 downto 12);

  l1a_cnt_fifo_ctrl : process (clk, l1a, rst)

  begin

    if (rst = '1') then
      l1a_cnt_fifo_wr_en <= '0';
    elsif (rising_edge(clk)) then 
      if (l1a_match = '1') then
        l1a_cnt_fifo_wr_en <= '1';
      else
        l1a_cnt_fifo_wr_en <= '0';
     	end if;
    end if;

  end process;

-- dw_counter

  dw_cnt : process (dcfebclk, dw_cnt_en, dw_cnt_rst)

    variable dw_cnt_data : std_logic_vector(11 downto 0);

  begin

    if (rst = '1') then
      dw_cnt_data := (others => '0');
    elsif (rising_edge(dcfebclk)) then
      if (dw_cnt_rst = '1') then
        dw_cnt_data := (others => '0');
      elsif (dw_cnt_en = '1') then
        dw_cnt_data := dw_cnt_data + 1;
      end if;
    end if;

    dw_cnt_out <= dw_cnt_data + 1;
    
  end process;

l1a_cnt_l_fifo : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 18,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "18Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => false)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      ALMOSTEMPTY => open,         -- Output almost empty 
      ALMOSTFULL  => open,          -- Output almost full
      DO          => l1a_cnt_l_fifo_out,            -- Output data
      EMPTY       => l1a_cnt_l_fifo_empty,          -- Output empty
      FULL        => l1a_cnt_l_fifo_full,           -- Output full
      RDCOUNT     => l1a_cnt_l_fifo_rdc,         -- Output read count
      RDERR       => open,              -- Output read error
      WRCOUNT     => l1a_cnt_l_fifo_wrc,         -- Output write count
      WRERR       => open,              -- Output write error
      DI          => l1a_cnt_l_fifo_in,           -- Input data
      RDCLK       => dcfebclk,           -- Input read clock
      RDEN        => l1a_cnt_fifo_rd_en,           -- Input read enable
      RST         => rst,               -- Input reset
      WRCLK       => clk,            -- Input write clock
      WREN        => l1a_cnt_fifo_wr_en            -- Input write enable
      );

l1a_cnt_h_fifo : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
      ALMOST_FULL_OFFSET      => X"0080",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET     => X"0080",    -- Sets the almost empty threshold
      DATA_WIDTH              => 18,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE               => "18Kb",     -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => false)  -- Sets the FIFO FWFT to TRUE or FALSE

    port map (
      ALMOSTEMPTY => open,         -- Output almost empty 
      ALMOSTFULL  => open,          -- Output almost full
      DO          => l1a_cnt_h_fifo_out,            -- Output data
      EMPTY       => l1a_cnt_h_fifo_empty,          -- Output empty
      FULL        => l1a_cnt_h_fifo_full,           -- Output full
      RDCOUNT     => l1a_cnt_h_fifo_rdc,         -- Output read count
      RDERR       => open,              -- Output read error
      WRCOUNT     => l1a_cnt_h_fifo_wrc,         -- Output write count
      WRERR       => open,              -- Output write error
      DI          => l1a_cnt_h_fifo_in,           -- Input data
      RDCLK       => dcfebclk,           -- Input read clock
      RDEN        => l1a_cnt_fifo_rd_en,           -- Input read enable
      RST         => rst,               -- Input reset
      WRCLK       => clk,            -- Input write clock
      WREN        => l1a_cnt_fifo_wr_en            -- Input write enable
      );


-- FSM 

--  SRL16_TX_START : SRL16 port map(tx_start, '1', '1', '1', '1', clk, l1a_match);

  tx_start_d <= not l1a_cnt_h_fifo_empty;
  --SRL16_TX_START : SRL16 port map(tx_start, '0', '0', '0', '1', clk, tx_start_d);
  FD_TX : FD port map(tx_start, clk, tx_start_d);
  
  fsm_regs : process (next_state, rst, dcfebclk)

  begin
    if (rst = '1') then
      current_state <= IDLE;
    elsif rising_edge(dcfebclk) then
      current_state <= next_state;
    end if;

  end process;

  fsm_logic : process (tx_ack, tx_start, l1a_cnt_out, dw_cnt_out, current_state)
  begin
    
    case current_state is
      
      when IDLE =>
        dcfeb_data <= (others => '0');
        dcfeb_dv   <= '0';
        dw_cnt_en  <= '0';
        dw_cnt_rst <= '1';
        if (tx_start = '1') then
          next_state <= TX_HEADER1;
          l1a_cnt_fifo_rd_en <= '1';
        else
          next_state <= IDLE;
          l1a_cnt_fifo_rd_en <= '0';
        end if;
        
      when TX_HEADER1 =>
        l1a_cnt_fifo_rd_en <= '0';
--        dcfeb_data <= dcfeb_addr & l1a_cnt_out(23 downto 12);
        dcfeb_data <= dcfeb_addr & l1a_cnt_h_fifo_out(11 downto 0);
        dcfeb_dv   <= '1';
        dw_cnt_en  <= '0';
        dw_cnt_rst <= '0';
        if (tx_ack = '1') then
          next_state <= TX_HEADER2;
        else
          next_state <= TX_HEADER1;
        end if;
        
      when TX_HEADER2 =>
        l1a_cnt_fifo_rd_en <= '0';
--        dcfeb_data <= dcfeb_addr & l1a_cnt_out(11 downto 0);
        dcfeb_data <= dcfeb_addr & l1a_cnt_l_fifo_out(11 downto 0);
        dcfeb_dv   <= '1';
        dw_cnt_en  <= '0';
        dw_cnt_rst <= '0';
        next_state <= TX_DATA;
        
      when TX_DATA =>
        l1a_cnt_fifo_rd_en <= '0';
-- Guido, Aug 2 
--        dcfeb_data <= dcfeb_addr & dw_cnt_out;
        dcfeb_data <= dcfeb_addr & l1a_cnt_l_fifo_out(7 downto 0) & dw_cnt_out(3 downto 0);
        dcfeb_dv   <= '1';
        if (dw_cnt_out = dw_n) then
          dw_cnt_en  <= '0';
          dw_cnt_rst <= '1';
          next_state <= IDLE;
        else
          dw_cnt_en  <= '1';
          dw_cnt_rst <= '0';
          next_state <= TX_DATA;
        end if;

      when others =>
        l1a_cnt_fifo_rd_en <= '0';
        dcfeb_data <= (others => '0');
        dcfeb_dv   <= '0';
        dw_cnt_en  <= '0';
        dw_cnt_rst <= '1';
        next_state <= IDLE;
        
    end case;
    
  end process;
  
end dcfeb_data_gen_architecture;
