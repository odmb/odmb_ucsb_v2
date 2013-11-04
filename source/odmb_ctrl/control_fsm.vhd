-- CONTROL: Monitor state of the nine data FIFOs and creates DDU packet when FIFOs are non-empty.

library ieee;
library work;
library unisim;
library hdlmacro;
use hdlmacro.hdlmacro.CB16CE;
use hdlmacro.hdlmacro.IFD_1;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.and_reduce;
use ieee.std_logic_misc.or_reduce;

entity CONTROL_FSM is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );  
  port (

    RST    : in std_logic;
    CLKCMS : in std_logic;
    CLK    : in std_logic;
    STATUS : in std_logic_vector(47 downto 0);
    L1ARST : in std_logic;

-- From DMB_VME
    RDFFNXT : in std_logic;

-- to GigaBit Link
    DOUT : out std_logic_vector(15 downto 0);
    DAV  : out std_logic;

-- to FIFOs
    OEFIFO_B  : out std_logic_vector(NFEB+2 downto 1);
    RENFIFO_B : out std_logic_vector(NFEB+2 downto 1);

-- from FIFOs
    FFOR_B      : in std_logic_vector(NFEB+2 downto 1);
    DATAIN      : in std_logic_vector(15 downto 0);
    DATAIN_LAST : in std_logic;

-- From JTAGCOM
    JOEF : in std_logic_vector(NFEB+2 downto 1);

-- From CRATEID in SETFEBDLY, and GA
    DAQMBID : in std_logic_vector(11 downto 0);

-- FROM SW1
    GIGAEN : in std_logic;

-- TO CAFIFO
    FIFO_POP : out std_logic;

-- TO DDUFIFO
    EOF : out std_logic;

-- FROM CAFIFO
    cafifo_l1a_dav   : in std_logic_vector(NFEB+2 downto 1);
    cafifo_l1a_match : in std_logic_vector(NFEB+2 downto 1);
    cafifo_l1a_cnt   : in std_logic_vector(23 downto 0);
    cafifo_bx_cnt    : in std_logic_vector(11 downto 0)
    );
end CONTROL_FSM;

architecture CONTROL_arch of CONTROL_FSM is

  component PULSE_EDGE is
    port (
      DOUT   : out std_logic;
      PULSE1 : out std_logic;
      CLK    : in  std_logic;
      RST    : in  std_logic;
      NPULSE : in  integer;
      DIN    : in  std_logic
      );
  end component;

  signal fifo_pop_80 : std_logic := '0';

  type   hdr_tail_array is array (8 downto 1) of std_logic_vector(15 downto 0);
  signal hdr_word, tail_word : hdr_tail_array;

  constant fmt_vers         : std_logic_vector(1 downto 0)      := "01";
  constant l1a_dav_mismatch : std_logic                         := '0';
  constant ovlp             : std_logic_vector(5 downto 1)      := "00000";
  constant sync             : std_logic_vector(3 downto 0)      := "0000";
  constant alct_to_end      : std_logic                         := '0';
  constant alct_to_start    : std_logic                         := '0';
  constant otmb_to_end      : std_logic                         := '0';
  constant otmb_to_start    : std_logic                         := '0';
  constant dcfeb_to_end     : std_logic_vector(NFEB downto 1)   := (others => '0');
  constant dcfeb_to_start   : std_logic_vector(NFEB downto 1)   := (others => '0');
  constant data_fifo_full   : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  constant data_fifo_half   : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  constant dmb_l1pipe       : std_logic_vector(7 downto 0)      := (others => '0');

  type   control_state is (IDLE, HDR, WAIT_ALCT_OTMB, TX_ALCT_OTMB, WAIT_DCFEB, TX_DCFEB, TAIL);
  signal control_current_state, control_next_state : control_state := IDLE;

  signal hdr_tail_cnt_en, hdr_tail_cnt_rst : std_logic                     := '0';
  signal hdr_tail_cnt                      : integer range 1 to 8          := 1;
  signal dev_cnt_en                        : std_logic                     := '0';
  signal dev_cnt                           : integer range 1 to 9          := 9;
  signal reg_crc                           : std_logic_vector(23 downto 0) := (others => '0');

begin

-- Get a 40 MHz pulse for FIFO_POP
  PULSE_FIFO_POP : PULSE_EDGE port map(FIFO_POP, open, CLKCMS, RST, 1, fifo_pop_80);

  control_fsm_regs : process (control_next_state, RST, CLK, dev_cnt, dev_cnt_en)
  begin
    if (RST = '1') then
      control_current_state <= IDLE;
      hdr_tail_cnt          <= 1;
      dev_cnt               <= 9;
    elsif rising_edge(CLK) then
      control_current_state <= control_next_state;
      if(hdr_tail_cnt_rst = '1') then
        hdr_tail_cnt <= 1;
      elsif(hdr_tail_cnt_en = '1') then
        hdr_tail_cnt <= hdr_tail_cnt + 1;
      end if;
      if(dev_cnt_en = '1') then
        if(dev_cnt = 9) then
          dev_cnt <= 8;
        elsif(dev_cnt = 8) then
          dev_cnt <= 1;
        elsif(dev_cnt = 7) then
          dev_cnt <= 9;
        else
          dev_cnt <= dev_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  control_fsm_logic : process (control_current_state, cafifo_l1a_match, cafifo_l1a_dav, hdr_word, hdr_tail_cnt, dev_cnt, DATAIN, DATAIN_LAST, tail_word)
  begin
    DOUT             <= (others => '0');
    DAV              <= '0';
    OEFIFO_B         <= (others => '1');
    RENFIFO_B        <= (others => '1');
    EOF              <= '0';
    fifo_pop_80      <= '0';
    hdr_tail_cnt_rst <= '0';
    hdr_tail_cnt_en  <= '0';
    dev_cnt_en       <= '0';

    case control_current_state is
      when IDLE =>
        hdr_tail_cnt_rst <= '1';
        if (or_reduce(cafifo_l1a_match) = '1') then
          control_next_state <= HDR;
        else
          control_next_state <= IDLE;
        end if;
        
      when HDR =>
        DOUT            <= hdr_word(hdr_tail_cnt);
        DAV             <= '1';
        hdr_tail_cnt_en <= '1';
        if (hdr_tail_cnt = 8) then
          control_next_state <= WAIT_ALCT_OTMB;
          hdr_tail_cnt_rst   <= '1';
        else
          control_next_state <= HDR;
        end if;
        
      when WAIT_ALCT_OTMB =>
        if(cafifo_l1a_match(dev_cnt) = '0') then
          dev_cnt_en <= '1';
          if (dev_cnt = 8) then
            control_next_state <= WAIT_DCFEB;
          end if;
        elsif(cafifo_l1a_match(dev_cnt) = cafifo_l1a_dav(dev_cnt)) then
          control_next_state <= TX_ALCT_OTMB;
          if (dev_cnt = 9) then
            OEFIFO_B  <= (9 => '0', others => '1');
            RENFIFO_B <= (9 => '0', others => '1');
          elsif (dev_cnt = 8) then
            OEFIFO_B  <= (8 => '0', others => '1');
            RENFIFO_B <= (8 => '0', others => '1');
          end if;
        else
          control_next_state <= WAIT_ALCT_OTMB;
        end if;
        
      when TX_ALCT_OTMB =>
        DOUT <= DATAIN;
        DAV  <= '1';
        if (dev_cnt = 9) then
          OEFIFO_B  <= (9 => '0', others => '1');
          RENFIFO_B <= (9 => '0', others => '1');
        elsif (dev_cnt = 8) then
          OEFIFO_B  <= (8 => '0', others => '1');
          RENFIFO_B <= (8 => '0', others => '1');
        end if;
        if(DATAIN_LAST = '1') then
          dev_cnt_en <= '1';
          if (dev_cnt = 9) then
            control_next_state <= WAIT_ALCT_OTMB;
          elsif (dev_cnt = 8) then
            control_next_state <= WAIT_DCFEB;
          end if;
        else
          control_next_state <= TX_ALCT_OTMB;
        end if;

      when WAIT_DCFEB =>
        if(cafifo_l1a_match(dev_cnt) = '0') then
          dev_cnt_en <= '1';
          if (dev_cnt = 7) then
            control_next_state <= TAIL;
          end if;
        elsif(cafifo_l1a_match(dev_cnt) = cafifo_l1a_dav(dev_cnt)) then
          control_next_state <= TX_DCFEB;
          OEFIFO_B(dev_cnt)  <= '0';
          RENFIFO_B(dev_cnt) <= '0';
        else
          control_next_state <= WAIT_DCFEB;
        end if;

      when TX_DCFEB =>
        DOUT               <= DATAIN;
        DAV                <= '1';
        OEFIFO_B(dev_cnt)  <= '0';
        RENFIFO_B(dev_cnt) <= '0';
        if(DATAIN_LAST = '1') then
          dev_cnt_en <= '1';
          if (dev_cnt /= 7) then
            control_next_state <= WAIT_DCFEB;
          else
            control_next_state <= TAIL;
          end if;
        end if;

      when TAIL =>
        DOUT            <= tail_word(hdr_tail_cnt);
        DAV             <= '1';
        hdr_tail_cnt_en <= '1';
        if (hdr_tail_cnt = 8) then
          control_next_state <= IDLE;
          EOF                <= '1';
          fifo_pop_80        <= '1';
        else
          control_next_state <= TAIL;
          EOF                <= '0';
          fifo_pop_80        <= '0';
        end if;
    end case;
  end process;

  hdr_word(1) <= x"9" & cafifo_l1a_cnt(11 downto 0);
  hdr_word(2) <= x"9" & cafifo_l1a_cnt(23 downto 12);
  hdr_word(3) <= x"9" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & fmt_vers & l1a_dav_mismatch & cafifo_l1a_match(NFEB downto 1);
  hdr_word(4) <= x"9" & cafifo_bx_cnt;
  hdr_word(5) <= x"A" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & fmt_vers & l1a_dav_mismatch & cafifo_l1a_match(NFEB downto 1);
  hdr_word(6) <= x"A" & DAQMBID(11 downto 0);
  hdr_word(7) <= x"A" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & ovlp & cafifo_bx_cnt(4 downto 0);
  hdr_word(8) <= x"A" & sync & fmt_vers & l1a_dav_mismatch & cafifo_l1a_cnt(4 downto 0);

  tail_word(1) <= x"F" & alct_to_end & cafifo_bx_cnt(4 downto 0) & cafifo_l1a_cnt(5 downto 0);
  tail_word(2) <= x"F" & ovlp & dcfeb_to_end;
  tail_word(3) <= x"F" & data_fifo_full(3 downto 1) & otmb_to_start & dmb_l1pipe;
  tail_word(4) <= x"F" & alct_to_start & dcfeb_to_start & data_fifo_full(7 downto 4);
  tail_word(5) <= x"E" & data_fifo_full(NFEB+2 downto NFEB+1) & data_fifo_half(NFEB+2 downto NFEB+1) & otmb_to_end & data_fifo_half(NFEB downto 1);
  tail_word(6) <= x"E" & DAQMBID(11 downto 0);
  tail_word(7) <= x"E" & REG_CRC(22) & REG_CRC(10 downto 0);
  tail_word(8) <= x"E" & REG_CRC(23) & REG_CRC(21 downto 11);


end CONTROL_arch;
