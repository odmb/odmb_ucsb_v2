-- FIFOWORDS: Counts number of words in a FIFO that is read slower than it is written

library work;
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.ucsb_types.all;

entity FIFOWORDS is
  generic (
    WIDTH : integer := 16
    );
  port (
    RST : in std_logic;

    WRCLK : in std_logic;
    WREN  : in std_logic;
    FULL  : in std_logic;

    RDCLK : in std_logic;  -- Ignored for now, counts edges of RDEN
    RDEN  : in std_logic;

    COUNT : out std_logic_vector(WIDTH-1 downto 0)
    );

end FIFOWORDS;

architecture FIFOWORDS_ARCH of FIFOWORDS is

  type   word_state_type is (IDLE, WRITING, READING);
  signal word_next_state, word_current_state : word_state_type;
  signal word_wrcnt_en, word_rdcnt_en        : std_logic := '0';
  signal rden_pulse                          : std_logic := '0';

begin

  PULSE_RDEN : PULSE2FAST port map(rden_pulse, WRCLK, RST, RDEN);

  word_cnt_proc : process (WRCLK, RST, word_wrcnt_en, FULL, word_rdcnt_en)
    variable word_cnt_data : std_logic_vector(WIDTH-1 downto 0);
  begin
    if (RST = '1') then
      word_cnt_data := (others => '0');
    elsif rising_edge(WRCLK) then
      if word_wrcnt_en = '1' and FULL = '0' then
        word_cnt_data := word_cnt_data + 1;
      elsif word_rdcnt_en = '1' and word_cnt_data > 0 then
        word_cnt_data := word_cnt_data - 1;
      end if;
    end if;

    COUNT <= word_cnt_data;
    
  end process;

  word_fsm_regs : process (word_next_state, RST, WRCLK)
  begin
    if (RST = '1') then
      word_current_state <= IDLE;
    elsif rising_edge(WRCLK) then
      word_current_state <= word_next_state;
    end if;
  end process;

  word_fsm_logic : process (word_current_state, WREN, rden_pulse)
  begin
    case word_current_state is
      when IDLE =>
        word_wrcnt_en <= '0';
        word_rdcnt_en <= '0';
        if (WREN = '1') then
          word_next_state <= WRITING;
        elsif (rden_pulse = '1') then
          word_next_state <= READING;
        else
          word_next_state <= IDLE;
        end if;
        
      when WRITING =>
        word_wrcnt_en <= '1';
        word_rdcnt_en <= '0';
        if (WREN = '1') then
          word_next_state <= WRITING;
        elsif (rden_pulse = '1') then
          word_next_state <= READING;
        else
          word_next_state <= IDLE;
        end if;

      when READING =>
        word_wrcnt_en <= '0';
        word_rdcnt_en <= '1';
        if (WREN = '1') then
          word_next_state <= WRITING;
        elsif (rden_pulse = '1') then
          word_next_state <= READING;
        else
          word_next_state <= IDLE;
        end if;

      when others =>
        word_next_state <= IDLE;
        word_wrcnt_en   <= '0';
        word_rdcnt_en   <= '0';
        
    end case;
  end process;


end FIFOWORDS_ARCH;
