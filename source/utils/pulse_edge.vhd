-- PULSE_EDGE: Creates a pulse one clock cycle long if rising edge

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;

entity PULSE_EDGE is
  port (
    DOUT    : out std_logic;
    PULSE1  : out std_logic;
    --CSP_OUT : out std_logic_vector(10 downto 0);
    CLK     : in  std_logic;
    RST     : in  std_logic;
    NPULSE : in  integer;
    DIN     : in  std_logic
    );
end PULSE_EDGE;

architecture PULSE_EDGE_Arch of PULSE_EDGE is

  signal pulse1_inner, pulse1_d : std_logic;

  signal pulse_cnt          : integer   := 1;
  signal pulse_cnt_en       : std_logic := '0';
  signal reset_q, clk_pulse : std_logic := '0';

  type   pulse_state_type is (PULSE_IDLE, PULSE_COUNTING);
  signal pulse_next_state, pulse_current_state : pulse_state_type;
  --signal state                                 : std_logic_vector(1 downto 0);

begin  --Architecture

  --CSP_OUT <= PULSE1_D & PULSE1_INNER & PULSE1_B & state  & pulse_cnt_en
  --           & std_logic_vector(to_unsigned(pulse_cnt, 5));
  
  FDDIN      : FDC port map(pulse1_d, DIN, pulse1_inner, '1');
  FDPULSE1_A : FD port map(pulse1_inner, CLK, pulse1_d);
  PULSE1 <= pulse1_inner;

  pulse_fsm_regs : process (CLK, RST, pulse_cnt_en, pulse_next_state)
  begin
    if (RST = '1') then
      pulse_cnt           <= 1;
      pulse_current_state <= PULSE_IDLE;
    elsif (rising_edge(CLK)) then
      pulse_current_state <= pulse_next_state;
      if(pulse_cnt_en = '1') then
        if(pulse_cnt = NPULSE) then
          pulse_cnt <= 1;
        else
          pulse_cnt <= pulse_cnt + 1;
        end if;
      end if;
    end if;
  end process;


  pulse_fsm_logic : process (pulse1_inner, pulse_current_state, pulse_cnt, NPULSE)
  begin
    case pulse_current_state is
      when PULSE_IDLE =>
        --state        <= "01";
        pulse_cnt_en <= '0';
        DOUT         <= '0';
        if (pulse1_inner = '1') then
          pulse_next_state <= PULSE_COUNTING;
        else
          pulse_next_state <= PULSE_IDLE;
        end if;
        
      when PULSE_COUNTING =>
        --state        <= "10";
        DOUT         <= '1';
        pulse_cnt_en <= '1';
        if (pulse_cnt = NPULSE) then
          pulse_next_state <= PULSE_IDLE;
        else
          pulse_next_state <= PULSE_COUNTING;
        end if;

    end case;
  end process;


end PULSE_EDGE_Arch;
