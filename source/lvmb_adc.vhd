-- LVMB_ADC: Simulates one of the 7 ADCs on a LVMB

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_1164.all;

entity LVMB_ADC is
  port (
      scl    : in  std_logic;
      sdi    : in  std_logic;
      sdo    : out std_logic;
      ce     : in  std_logic;
      rst    : in  std_logic;
      device : in  std_logic_vector(3 downto 0)
      );

end LVMB_ADC;

architecture LVMB_ADC_ARCHITECTURE of LVMB_ADC is

  constant adc_ch0 : std_logic_vector(3 downto 0) := "0000";
  constant adc_ch1 : std_logic_vector(3 downto 0) := "0001";
  constant adc_ch2 : std_logic_vector(3 downto 0) := "0010";
  constant adc_ch3 : std_logic_vector(3 downto 0) := "0011";
  constant adc_ch4 : std_logic_vector(3 downto 0) := "0100";
  constant adc_ch5 : std_logic_vector(3 downto 0) := "0101";
  constant adc_ch6 : std_logic_vector(3 downto 0) := "0110";
  constant adc_ch7 : std_logic_vector(3 downto 0) := "0111";

  type state_type is (IDLE, CTRL_SHIFT, ACQUIRE, DATA_LOAD, DATA_SHIFT);

  signal next_state, current_state : state_type;

  signal cnt_en, cnt_res : std_logic := '0';
  signal cnt_out         : std_logic_vector(3 downto 0) := (others => '0');

  signal data_ld  : std_logic := '0';
  signal data_sh  : std_logic := '0';
  signal data_reg : std_logic_vector(11 downto 0) := (others => '0');

  signal ctrl_sh  : std_logic := '0';
  signal ctrl_reg : std_logic_vector(6 downto 0) := (others => '0');

  signal sh_out, int_sdo : std_logic := '0';

begin

--  sdo <= 'H';
  
  cnt : process (scl, cnt_en, cnt_res)
    variable cnt_data : std_logic_vector(3 downto 0);
  begin

    if (rising_edge(scl)) then
      if (cnt_res = '1') then
        cnt_data := (others => '0');
      elsif (cnt_en = '1') then
        cnt_data := cnt_data + 1;
      end if;
    end if;
    cnt_out <= cnt_data;
  end process;


  ctrl_shifter : process (scl, rst, ctrl_sh, sdi, ctrl_reg)
  begin
    if (rising_edge(scl)) then
      if (rst = '1') then
        ctrl_reg <= (others => '0');
      elsif (ctrl_sh = '1') then
        ctrl_reg(0) <= sdi;
        ctrl_reg(1) <= ctrl_reg(0);
        ctrl_reg(2) <= ctrl_reg(1);
        ctrl_reg(3) <= ctrl_reg(2);
        ctrl_reg(4) <= ctrl_reg(3);
        ctrl_reg(5) <= ctrl_reg(4);
        ctrl_reg(6) <= ctrl_reg(5);
      end if;
    end if;
  end process;

  sdo <= int_sdo when ce = '0' else 'Z';

  data_shifter : process (scl, rst, data_ld, data_sh, sdi, ctrl_reg, data_reg)
  begin
    if (falling_edge(scl)) then
      if (rst = '1') then
        data_reg <= (others => '0');
      elsif (data_ld = '1') then
        case ctrl_reg(6 downto 4) is
          when "000"  => data_reg <= "1111" & device & adc_ch0;
          when "001"  => data_reg <= "1111" & device & adc_ch1;
          when "010"  => data_reg <= "1111" & device & adc_ch2;
          when "011"  => data_reg <= "1111" & device & adc_ch3;
          when "100"  => data_reg <= "1111" & device & adc_ch4;
          when "101"  => data_reg <= "1111" & device & adc_ch5;
          when "110"  => data_reg <= "1111" & device & adc_ch6;
          when "111"  => data_reg <= "1111" & device & adc_ch7;
          when others => data_reg <= "1111" & device & adc_ch0;
        end case;
      elsif (data_sh = '1') then
        data_reg(11) <= data_reg(10);
        data_reg(10) <= data_reg(9);
        data_reg(9)  <= data_reg(8);
        data_reg(8)  <= data_reg(7);
        data_reg(7)  <= data_reg(6);
        data_reg(6)  <= data_reg(5);
        data_reg(5)  <= data_reg(4);
        data_reg(4)  <= data_reg(3);
        data_reg(3)  <= data_reg(2);
        data_reg(2)  <= data_reg(1);
        data_reg(1)  <= data_reg(0);
        data_reg(0)  <= '0';
      end if;
    end if;
    sh_out <= data_reg(11);
  end process;


  fsm_state_regs : process (next_state, rst, scl)
  begin
    if (rst = '1') then
      current_state <= IDLE;
    elsif rising_edge(scl) then
      current_state <= next_state;
    end if;
  end process;


  fsm_comb_logic : process(ce, sdi, cnt_out, sh_out, current_state)
  begin
    case current_state is
      when IDLE =>
        int_sdo <= 'Z';
        cnt_en  <= '0';
        cnt_res <= '1';
        data_ld <= '0';
        data_sh <= '0';
        ctrl_sh <= '0';
        if (ce = '0') and (sdi = '1') then
          next_state <= CTRL_SHIFT;
        else
          next_state <= IDLE;
        end if;

      when CTRL_SHIFT =>
        int_sdo <= '0';
        data_ld <= '0';
        data_sh <= '0';
        ctrl_sh <= '1';
        if (cnt_out = "0110") then
          cnt_en     <= '0';
          cnt_res    <= '1';
          next_state <= ACQUIRE;
        else
          cnt_en     <= '1';
          cnt_res    <= '0';
          next_state <= CTRL_SHIFT;
        end if;
        
      when ACQUIRE =>
        int_sdo <= '0';
        data_ld <= '0';
        data_sh <= '0';
        ctrl_sh <= '0';
        if (cnt_out = "0100") then
          cnt_en     <= '0';
          cnt_res    <= '1';
          next_state <= DATA_LOAD;
        else
          cnt_en     <= '1';
          cnt_res    <= '0';
          next_state <= ACQUIRE;
        end if;

      when DATA_LOAD =>
        int_sdo    <= '0';
        cnt_en     <= '0';
        cnt_res    <= '0';
        data_ld    <= '1';
        data_sh    <= '0';
        ctrl_sh    <= '0';
        next_state <= DATA_SHIFT;

      when DATA_SHIFT =>
        int_sdo <= sh_out;
        data_ld <= '0';
        data_sh <= '1';
        ctrl_sh <= '0';
        if (cnt_out = "1011") then
          cnt_en     <= '0';
          cnt_res    <= '1';
          next_state <= IDLE;
        else
          cnt_en     <= '1';
          cnt_res    <= '0';
          next_state <= DATA_SHIFT;
        end if;

      when others =>
        int_sdo    <= 'Z';
        cnt_en     <= '0';
        cnt_res    <= '1';
        data_ld    <= '0';
        data_sh    <= '0';
        ctrl_sh    <= '0';
        next_state <= IDLE;
    end case;
  end process;

end lvmb_adc_architecture;
