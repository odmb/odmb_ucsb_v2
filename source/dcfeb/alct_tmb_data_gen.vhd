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
use unisim.vcomponents.all;

entity alct_tmb_data_gen is
  port(

    clk            : in  std_logic;
    rst            : in  std_logic;
    l1a            : in  std_logic;
    alct_l1a_match : in  std_logic;
    tmb_l1a_match  : in  std_logic;
    alct_dv        : out std_logic;
    alct_data      : out std_logic_vector(15 downto 0);
    tmb_dv         : out std_logic;
    tmb_data       : out std_logic_vector(15 downto 0)

    );

end alct_tmb_data_gen;

--}} End of automatically maintained section

architecture alct_tmb_data_gen_architecture of alct_tmb_data_gen is

  type state_type is (IDLE, TX_HEADER1, TX_HEADER2, TX_DATA);

  signal alct_next_state, alct_current_state : state_type;
  signal tmb_next_state, tmb_current_state   : state_type;

  signal   alct_dw_cnt_en, alct_dw_cnt_rst : std_logic;
  signal   tmb_dw_cnt_en, tmb_dw_cnt_rst   : std_logic;
  signal   l1a_cnt_out                     : std_logic_vector(23 downto 0);
  signal   alct_dw_cnt_out                 : std_logic_vector(11 downto 0);
  signal   tmb_dw_cnt_out                  : std_logic_vector(11 downto 0);
  constant dw_n                            : std_logic_vector(11 downto 0) := "000000001000";
  signal   alct_tx_start, tmb_tx_start     : std_logic;

begin

-- l1a_counter
  
  l1a_cnt : process (clk, l1a)

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

-- dw_counter

  alct_dw_cnt : process (clk, alct_dw_cnt_en, alct_dw_cnt_rst)

    variable alct_dw_cnt_data : std_logic_vector(11 downto 0);

  begin

    if (rst = '1') then
      alct_dw_cnt_data := (others => '0');
    elsif (rising_edge(clk)) then
      if (alct_dw_cnt_rst = '1') then
        alct_dw_cnt_data := (others => '0');
      elsif (alct_dw_cnt_en = '1') then
        alct_dw_cnt_data := alct_dw_cnt_data + 1;
      end if;
    end if;

    alct_dw_cnt_out <= alct_dw_cnt_data + 1;
    
  end process;

  tmb_dw_cnt : process (clk, tmb_dw_cnt_en, tmb_dw_cnt_rst)

    variable tmb_dw_cnt_data : std_logic_vector(11 downto 0);

  begin

    if (rst = '1') then
      tmb_dw_cnt_data := (others => '0');
    elsif (rising_edge(clk)) then
      if (tmb_dw_cnt_rst = '1') then
        tmb_dw_cnt_data := (others => '0');
      elsif (tmb_dw_cnt_en = '1') then
        tmb_dw_cnt_data := tmb_dw_cnt_data + 1;
      end if;
    end if;

    tmb_dw_cnt_out <= tmb_dw_cnt_data + 1;
    
  end process;

-- FSM 
  SRL16_TX_ALCT_START : SRL16 port map(alct_tx_start, '1', '1', '1', '1', CLK, alct_l1a_match);
  SRL16_TX_TMB_START  : SRL16 port map(tmb_tx_start, '1', '1', '1', '1', CLK, tmb_l1a_match);

  fsm_regs : process (alct_next_state, tmb_next_state, rst, clk)

  begin
    if (rst = '1') then
      alct_current_state <= IDLE;
      tmb_current_state  <= IDLE;
    elsif rising_edge(clk) then
      alct_current_state <= alct_next_state;
      tmb_current_state  <= tmb_next_state;
    end if;

  end process;

  alct_fsm_logic : process (alct_tx_start, l1a_cnt_out, alct_dw_cnt_out, alct_current_state)

  begin
    
    case alct_current_state is
      
      when IDLE =>
        
        alct_data       <= (others => '0');
        alct_dv         <= '0';
        alct_dw_cnt_en  <= '0';
        alct_dw_cnt_rst <= '1';
        if (alct_tx_start = '1') then
          alct_next_state <= TX_HEADER1;
        else
          alct_next_state <= IDLE;
        end if;
        
      when TX_HEADER1 =>
        
        alct_data       <= "1100" & l1a_cnt_out(23 downto 12);
        alct_dv         <= '1';
        alct_dw_cnt_en  <= '0';
        alct_dw_cnt_rst <= '0';
        alct_next_state <= TX_HEADER2;
        
      when TX_HEADER2 =>
        
        alct_data       <= "1100" & l1a_cnt_out(11 downto 0);
        alct_dv         <= '1';
        alct_dw_cnt_en  <= '0';
        alct_dw_cnt_rst <= '0';
        alct_next_state <= TX_DATA;
        
      when TX_DATA =>

        alct_data <= "1100" & alct_dw_cnt_out;
        alct_dv   <= '1';
        if (alct_dw_cnt_out = dw_n) then
          alct_dw_cnt_en  <= '0';
          alct_dw_cnt_rst <= '1';
          alct_next_state <= IDLE;
        else
          alct_dw_cnt_en  <= '1';
          alct_dw_cnt_rst <= '0';
          alct_next_state <= TX_DATA;
        end if;

      when others =>

        alct_data       <= (others => '0');
        alct_dv         <= '0';
        alct_dw_cnt_en  <= '0';
        alct_dw_cnt_rst <= '1';
        alct_next_state <= IDLE;
        
    end case;
    
  end process;

  tmb_fsm_logic : process (tmb_tx_start, l1a_cnt_out, tmb_dw_cnt_out, tmb_current_state)

  begin
    
    case tmb_current_state is
      
      when IDLE =>
        
        tmb_data       <= (others => '0');
        tmb_dv         <= '0';
        tmb_dw_cnt_en  <= '0';
        tmb_dw_cnt_rst <= '1';
        if (tmb_tx_start = '1') then
          tmb_next_state <= TX_HEADER1;
        else
          tmb_next_state <= IDLE;
        end if;
        
      when TX_HEADER1 =>
        
        tmb_data       <= "1011" & l1a_cnt_out(23 downto 12);
        tmb_dv         <= '1';
        tmb_dw_cnt_en  <= '0';
        tmb_dw_cnt_rst <= '0';
        tmb_next_state <= TX_HEADER2;
        
      when TX_HEADER2 =>
        
        tmb_data       <= "1011" & l1a_cnt_out(11 downto 0);
        tmb_dv         <= '1';
        tmb_dw_cnt_en  <= '0';
        tmb_dw_cnt_rst <= '0';
        tmb_next_state <= TX_DATA;
        
      when TX_DATA =>

        tmb_data <= "1011" & tmb_dw_cnt_out;
        tmb_dv   <= '1';
        if (tmb_dw_cnt_out = dw_n) then
          tmb_dw_cnt_en  <= '0';
          tmb_dw_cnt_rst <= '1';
          tmb_next_state <= IDLE;
        else
          tmb_dw_cnt_en  <= '1';
          tmb_dw_cnt_rst <= '0';
          tmb_next_state <= TX_DATA;
        end if;

      when others =>

        tmb_data       <= (others => '0');
        tmb_dv         <= '0';
        tmb_dw_cnt_en  <= '0';
        tmb_dw_cnt_rst <= '1';
        tmb_next_state <= IDLE;
        
    end case;
    
  end process;
  
end alct_tmb_data_gen_architecture;
