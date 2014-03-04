-- CRC_CHECKER: Checks that the CRC22 of DDU packets is correct

library ieee;
library work;
library unisim;
library hdlmacro;
use hdlmacro.hdlmacro.all;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.and_reduce;
use ieee.std_logic_misc.or_reduce;

entity CRC_CHECKER is
  port (
    RST    : in std_logic;
    CLKCMS : in std_logic;
    CLK    : in std_logic;

-- data from CONTROL to GigaBit Link
    DOUT : in std_logic_vector(15 downto 0);
    DAV  : in std_logic;

    CRC_ERROR : out std_logic
    );
end CRC_CHECKER;

architecture CRC_CHECKER_arch of CRC_CHECKER is

  signal crcen                : std_logic := '0';
  signal crcrst               : std_logic := '0';
  signal crc, reg_crc, crc_in : std_logic_vector(23 downto 0);

  type state_type is (IDLE, HDR_DATA, TAILA, TAIL5, TAIL6, TAIL7, TAIL8);

  signal next_state, current_state : state_type;

begin

-- FSM 
  
  fsm_regs : process (next_state, rst, clk)
  begin
    if ((rst = '1')) then
      current_state <= IDLE;
    elsif rising_edge(clk) then
      current_state <= next_state;
    end if;
  end process;

  fsm_logic : process (dout, dav, current_state)
  begin
    case current_state is
      when IDLE =>
        crc_error <= '0';
        crc_in    <= (others => '0');
        if (dav = '0') then
          crcen      <= '0';
          crcrst     <= '1';
          next_state <= IDLE;
        else
          crcen      <= '1';
          crcrst     <= '0';
          next_state <= HDR_DATA;
        end if;
        
      when HDR_DATA =>
        crc_error <= '0';
        if (dav = '1') then
          crcen <= '1';
        else
          crcen <= '0';
        end if;
        crcrst <= '0';
        if (dout(15 downto 12) = "1111") then
          next_state <= TAILA;
        else
          next_state <= HDR_DATA;
        end if;
        
      when TAILA =>
        crc_error <= '0';
        crcrst    <= '0';
        if (dout(15 downto 12) = "1111") then
          crcen      <= '1';
          next_state <= TAILA;
        else
          crcen      <= '0';
          next_state <= TAIL5;
        end if;

      when TAIL5 =>
        crc_error  <= '0';
        crcen      <= '0';
        crcrst     <= '0';
        next_state <= TAIL6;

      when TAIL6 =>
        crc_error           <= '0';
        crcen               <= '0';
        crcrst              <= '0';
        crc_in(10 downto 0) <= dout(10 downto 0);
        crc_in(22)          <= dout(11);
        next_state          <= TAIL7;

      when TAIL7 =>
        crc_error            <= '0';
        crcen                <= '0';
        crcrst               <= '0';
        crc_in(21 downto 11) <= dout(10 downto 0);
        crc_in(23)           <= dout(11);
        next_state           <= TAIL8;

      when TAIL8 =>
        crcen                                <= '0';
        crcrst                               <= '0';
        if (crc_in = reg_crc) then crc_error <= '0'; else crc_error <= '1'; end if;
        next_state                           <= IDLE;

      when others =>
        crc_error  <= '0';
        crcen      <= '0';
        next_state <= IDLE;
        
    end case;
  end process;

-- Generate REG_CRC input
  CRC(4 downto 0) <= REG_CRC(20 downto 16);
  CRC(5)          <= DOUT(0) xor REG_CRC(0) xor REG_CRC(21);
  CRC(6)          <= DOUT(0) xor DOUT(1) xor REG_CRC(0) xor REG_CRC(1);
  CRC(7)          <= DOUT(1) xor DOUT(2) xor REG_CRC(1) xor REG_CRC(2);
  CRC(8)          <= DOUT(2) xor DOUT(3) xor REG_CRC(2) xor REG_CRC(3);
  CRC(9)          <= DOUT(3) xor DOUT(4) xor REG_CRC(3) xor REG_CRC(4);
  CRC(10)         <= DOUT(4) xor DOUT(5) xor REG_CRC(4) xor REG_CRC(5);
  CRC(11)         <= DOUT(5) xor DOUT(6) xor REG_CRC(5) xor REG_CRC(6);
  CRC(12)         <= DOUT(6) xor DOUT(7) xor REG_CRC(6) xor REG_CRC(7);
  CRC(13)         <= DOUT(7) xor DOUT(8) xor REG_CRC(7) xor REG_CRC(8);
  CRC(14)         <= DOUT(8) xor DOUT(9) xor REG_CRC(8) xor REG_CRC(9);
  CRC(15)         <= DOUT(9) xor DOUT(10) xor REG_CRC(9) xor REG_CRC(10);
  CRC(16)         <= DOUT(10) xor DOUT(11) xor REG_CRC(10) xor REG_CRC(11);
  CRC(17)         <= DOUT(11) xor DOUT(12) xor REG_CRC(11) xor REG_CRC(12);
  CRC(18)         <= DOUT(12) xor DOUT(13) xor REG_CRC(12) xor REG_CRC(13);
  CRC(19)         <= DOUT(13) xor DOUT(14) xor REG_CRC(13) xor REG_CRC(14);
  CRC(20)         <= DOUT(14) xor DOUT(15) xor REG_CRC(14) xor REG_CRC(15);
  CRC(21)         <= DOUT(15) xor REG_CRC(15);
  CRC(22)         <= CRC(0) xor CRC(1) xor CRC(2) xor CRC(3) xor CRC(4) xor CRC(5) xor CRC(6) xor CRC(7) xor CRC(8) xor CRC(9) xor CRC(10);
  CRC(23)         <= CRC(11) xor CRC(12) xor CRC(13) xor CRC(14) xor CRC(15) xor CRC(16) xor CRC(17) xor CRC(18) xor CRC(19) xor CRC(20) xor CRC(21);

  GEN_REG_CRC : for K in 0 to 21 generate
  begin
    FDCE_REG_CRC : FDCE port map (REG_CRC(K), CLK, CRCEN, CRCRST, CRC(K));
  end generate GEN_REG_CRC;
  REG_CRC(23 downto 22) <= (others => '0');
  
end CRC_CHECKER_arch;
