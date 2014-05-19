-- NPULSE2SLOW: Creates an n clock cycle long pulse if rising edge in a
-- slower clock domain.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;

entity NPULSE2SLOW is
  port (
    DOUT     : out std_logic;
    CLK_DOUT : in  std_logic;
    CLK_DIN  : in  std_logic;
    RST      : in  std_logic;
    NPULSE   : in  integer;
    DIN      : in  std_logic
    );
end NPULSE2SLOW;

architecture NPULSE2SLOW_Arch of NPULSE2SLOW is
  component PULSE2SLOW is
    port (
      DOUT     : out std_logic;
      CLK_DOUT : in  std_logic;
      CLK_DIN  : in  std_logic;
      RST      : in  std_logic;
      DIN      : in  std_logic
      );
  end component;

  signal pulse1 : std_logic;
  signal pulse_cnt          : integer   := 1;
  signal pulse_cnt_en       : std_logic := '0';
  signal reset_q, clk_pulse : std_logic := '0';

  type pulse_state_type is (PULSE_IDLE, PULSE_COUNTING);
  signal pulse_next_state, pulse_current_state : pulse_state_type;

begin  --Architecture

  PULSE1_PM : PULSE2SLOW port map(pulse1, CLK_DOUT, CLK_DIN, RST, DIN);

  pulse_fsm_regs : process (CLK_DOUT, RST, pulse_cnt_en, pulse_next_state)
  begin
    if (RST = '1') then
      pulse_cnt           <= 1;
      pulse_current_state <= PULSE_IDLE;
    elsif (rising_edge(CLK_DOUT)) then
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

  pulse_fsm_logic : process (pulse1, pulse_current_state, pulse_cnt, NPULSE)
  begin
    case pulse_current_state is
      when PULSE_IDLE =>
        pulse_cnt_en <= '0';
        DOUT         <= '0';
        if (pulse1 = '1') then
          pulse_next_state <= PULSE_COUNTING;
        else
          pulse_next_state <= PULSE_IDLE;
        end if;
        
      when PULSE_COUNTING =>
        DOUT         <= '1';
        pulse_cnt_en <= '1';
        if (pulse_cnt = NPULSE) then
          pulse_next_state <= PULSE_IDLE;
        else
          pulse_next_state <= PULSE_COUNTING;
        end if;

    end case;
  end process;

end NPULSE2SLOW_Arch;
