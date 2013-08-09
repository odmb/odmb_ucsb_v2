-- ALCT_OTMB_DATA_GEN: Generates packets of dummy ALCT and OTMB data

library ieee;
library unisim;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;

entity alct_otmb_data_gen is
  port(
    clk            : in  std_logic;
    rst            : in  std_logic;
    l1a            : in  std_logic;
    alct_l1a_match : in  std_logic;
    otmb_l1a_match : in  std_logic;
    alct_dv        : out std_logic;
    alct_data      : out std_logic_vector(15 downto 0);
    otmb_dv        : out std_logic;
    otmb_data      : out std_logic_vector(15 downto 0)
    );
end alct_otmb_data_gen;

architecture alct_otmb_data_gen_architecture of alct_otmb_data_gen is

  type state_type is (IDLE, TX_DATA);

  signal alct_next_state, alct_current_state : state_type;
  signal otmb_next_state, otmb_current_state : state_type;

  signal alct_dw_cnt_en, alct_dw_cnt_rst : std_logic;
  signal otmb_dw_cnt_en, otmb_dw_cnt_rst : std_logic;
  signal l1a_cnt_out                     : std_logic_vector(23 downto 0);
  signal alct_dw_cnt_out                 : std_logic_vector(11 downto 0);
  signal otmb_dw_cnt_out                 : std_logic_vector(11 downto 0);
  constant dw_n                          : std_logic_vector(11 downto 0) := x"008";
  signal alct_tx_start, otmb_tx_start    : std_logic;

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

-- dw_counter

  alct_dw_cnt : process (clk, alct_dw_cnt_en, alct_dw_cnt_rst, rst)

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

  otmb_dw_cnt : process (clk, otmb_dw_cnt_en, otmb_dw_cnt_rst, rst)

    variable otmb_dw_cnt_data : std_logic_vector(11 downto 0);

  begin

    if (rst = '1') then
      otmb_dw_cnt_data := (others => '0');
    elsif (rising_edge(clk)) then
      if (otmb_dw_cnt_rst = '1') then
        otmb_dw_cnt_data := (others => '0');
      elsif (otmb_dw_cnt_en = '1') then
        otmb_dw_cnt_data := otmb_dw_cnt_data + 1;
      end if;
    end if;

    otmb_dw_cnt_out <= otmb_dw_cnt_data + 1;
    
  end process;

-- FSM 
  SRL16_TX_ALCT_START : SRL16 port map(alct_tx_start, '1', '1', '1', '1', CLK, alct_l1a_match);
  SRL16_TX_OTMB_START : SRL16 port map(otmb_tx_start, '1', '1', '1', '1', CLK, otmb_l1a_match);

  fsm_regs : process (alct_next_state, otmb_next_state, rst, clk)

  begin
    if (rst = '1') then
      alct_current_state <= IDLE;
      otmb_current_state <= IDLE;
    elsif rising_edge(clk) then
      alct_current_state <= alct_next_state;
      otmb_current_state <= otmb_next_state;
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
          alct_next_state <= TX_DATA;
        else
          alct_next_state <= IDLE;
        end if;
        
      when TX_DATA =>
        alct_data <= x"D" & l1a_cnt_out(7 downto 0) & alct_dw_cnt_out(3 downto 0);
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

  otmb_fsm_logic : process (otmb_tx_start, l1a_cnt_out, otmb_dw_cnt_out, otmb_current_state)
  begin
    case otmb_current_state is
      when IDLE =>
        otmb_data       <= (others => '0');
        otmb_dv         <= '0';
        otmb_dw_cnt_en  <= '0';
        otmb_dw_cnt_rst <= '1';
        if (otmb_tx_start = '1') then
          otmb_next_state <= TX_DATA;
        else
          otmb_next_state <= IDLE;
        end if;
        
      when TX_DATA =>
        otmb_data <= x"B" & l1a_cnt_out(7 downto 0) & otmb_dw_cnt_out(3 downto 0);
        otmb_dv   <= '1';
        if (otmb_dw_cnt_out = dw_n) then
          otmb_dw_cnt_en  <= '0';
          otmb_dw_cnt_rst <= '1';
          otmb_next_state <= IDLE;
        else
          otmb_dw_cnt_en  <= '1';
          otmb_dw_cnt_rst <= '0';
          otmb_next_state <= TX_DATA;
        end if;

      when others =>
        otmb_data       <= (others => '0');
        otmb_dv         <= '0';
        otmb_dw_cnt_en  <= '0';
        otmb_dw_cnt_rst <= '1';
        otmb_next_state <= IDLE;
        
    end case;
  end process;
  
end alct_otmb_data_gen_architecture;
