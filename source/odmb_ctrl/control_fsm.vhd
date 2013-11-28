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
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity CONTROL_FSM is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );  
  port (

-- Chip Scope Pro Logic Analyzer control

    CSP_CONTROL_FSM_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);

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
    cafifo_bx_cnt    : in std_logic_vector(11 downto 0);
    cafifo_lost_pckt : in std_logic_vector(NFEB+2 downto 1)
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

  component csp_control_fsm_la is
    port (
      CLK     : in    std_logic := 'X';
      DATA    : in    std_logic_vector (127 downto 0);
      TRIG0   : in    std_logic_vector (7 downto 0);
      CONTROL : inout std_logic_vector (35 downto 0)
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
  constant otmb_to_end      : std_logic                         := '0';
  constant dcfeb_to_end     : std_logic_vector(NFEB downto 1)   := (others => '0');
  constant data_fifo_full   : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  constant data_fifo_half   : std_logic_vector(NFEB+2 downto 1) := (others => '0');
  constant dmb_l1pipe       : std_logic_vector(7 downto 0)      := (others => '0');

  type   control_state is (IDLE, HDR, WAIT_ALCT_OTMB, TX_ALCT_OTMB, WAIT_DCFEB, TX_DCFEB, TAIL, WAIT_IDLE);
  signal control_current_state, control_next_state : control_state := IDLE;

  signal hdr_tail_cnt_en, hdr_tail_cnt_rst : std_logic                     := '0';
  signal hdr_tail_cnt                      : integer range 1 to 8          := 1;
  signal dev_cnt_en                        : std_logic                     := '0';
  signal dev_cnt                           : integer range 1 to 9          := 9;
  signal tx_cnt_en, tx_cnt_rst             : std_logic                     := '0';
  signal tx_cnt                            : integer range 1 to 3          := 1;
  signal reg_crc                           : std_logic_vector(23 downto 0) := (others => '0');

  signal q_datain_last : std_logic;

  --Declaring Logic Analyzer signals -- bgb
  signal control_fsm_la_data : std_logic_vector(127 downto 0);
  signal control_fsm_la_trig : std_logic_vector(7 downto 0);

  signal expect_pckt                     : std_logic                     := '0';
  signal dav_inner                       : std_logic                     := '0';
  signal dout_inner                      : std_logic_vector(15 downto 0) := (others => '0');
  signal oefifo_b_inner, renfifo_b_inner : std_logic_vector(NFEB+2 downto 1);
  signal fifo_pop_inner, eof_inner       : std_logic                     := '0';

  signal dev_cnt_svl, hdr_tail_cnt_svl : std_logic_vector(4 downto 0) := (others => '0');

  signal current_state_svl, next_state_svl : std_logic_vector(3 downto 0) := (others => '0');

begin

  -- csp ILA core
  csp_control_fsm_la_pm : csp_control_fsm_la
    port map (
      CONTROL => CSP_CONTROL_FSM_PORT_LA_CTRL,
      CLK     => CLK,
      DATA    => control_fsm_la_data,
      TRIG0   => control_fsm_la_trig
      );

  expect_pckt         <= or_reduce(cafifo_l1a_match);
  dev_cnt_svl         <= std_logic_vector(to_unsigned(dev_cnt, 5));
  hdr_tail_cnt_svl    <= std_logic_vector(to_unsigned(hdr_tail_cnt, 5));
-- trigger assignments (8 bits)
  control_fsm_la_trig <= expect_pckt & q_datain_last & dev_cnt_en & "00000";
  control_fsm_la_data <= "0" & x"000000000000"
                         & next_state_svl & eof_inner & fifo_pop_inner & fifo_pop_80
                         & oefifo_b_inner & renfifo_b_inner & dout_inner(15 downto 0)
                         & hdr_tail_cnt_rst & hdr_tail_cnt_en & dev_cnt_en
                         & cafifo_l1a_dav & cafifo_l1a_match & q_datain_last & expect_pckt
                         & hdr_tail_cnt_svl & dev_cnt_svl & current_state_svl & dav_inner;

-- Needed because DATAIN_LAST does not arrive during the last word
  FDLAST : FD port map(q_datain_last, clk, DATAIN_LAST);

-- Get a 40 MHz pulse for FIFO_POP
  PULSE_FIFO_POP : PULSE_EDGE port map(fifo_pop_inner, open, CLKCMS, RST, 1, fifo_pop_80);

  control_fsm_regs : process (control_next_state, RST, CLK, dev_cnt, dev_cnt_en, tx_cnt, tx_cnt_en)
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
      if(tx_cnt_rst = '1') then
        tx_cnt <= 1;
      elsif(tx_cnt_en = '1' and tx_cnt < 3) then
        tx_cnt <= tx_cnt+1;
      end if;
    end if;
  end process;

  with control_current_state select
    current_state_svl <= x"1" when IDLE,
    x"2"                      when HDR,
    x"3"                      when WAIT_ALCT_OTMB,
    x"4"                      when TX_ALCT_OTMB,
    x"5"                      when WAIT_DCFEB,
    x"6"                      when TX_DCFEB,
    x"7"                      when TAIL,
    x"8"                      when WAIT_IDLE,
    x"0"                      when others;
  
  with control_next_state select
    next_state_svl <= x"1" when IDLE,
    x"2"                   when HDR,
    x"3"                   when WAIT_ALCT_OTMB,
    x"4"                   when TX_ALCT_OTMB,
    x"5"                   when WAIT_DCFEB,
    x"6"                   when TX_DCFEB,
    x"7"                   when TAIL,
    x"8"                   when WAIT_IDLE,
    x"0"                   when others;
  
  control_fsm_logic : process (control_current_state, cafifo_l1a_match, cafifo_l1a_dav, hdr_word,
                               hdr_tail_cnt, dev_cnt, tx_cnt, DATAIN, q_datain_last, tail_word)
  begin
    dout_inner       <= (others => '0');
    dav_inner        <= '0';
    oefifo_b_inner   <= (others => '1');
    renfifo_b_inner  <= (others => '1');
    eof_inner        <= '0';
    fifo_pop_80      <= '0';
    hdr_tail_cnt_rst <= '0';
    hdr_tail_cnt_en  <= '0';
    dev_cnt_en       <= '0';
    tx_cnt_rst       <= '0';
    tx_cnt_en        <= '0';

    case control_current_state is
      when IDLE =>
        hdr_tail_cnt_rst <= '1';
        if (or_reduce(cafifo_l1a_match) = '1') then
          control_next_state <= HDR;
        else
          control_next_state <= IDLE;
        end if;
        
      when HDR =>
        dout_inner      <= hdr_word(hdr_tail_cnt);
        dav_inner       <= '1';
        hdr_tail_cnt_en <= '1';
        if (hdr_tail_cnt = 8) then
          control_next_state <= WAIT_ALCT_OTMB;
          hdr_tail_cnt_rst   <= '1';
        else
          control_next_state <= HDR;
        end if;
        
      when WAIT_ALCT_OTMB =>
        if(cafifo_l1a_match(dev_cnt) = '0' or cafifo_lost_pckt(dev_cnt) = '1') then
          dev_cnt_en <= '1';
          if (dev_cnt = 9) then
            control_next_state <= WAIT_ALCT_OTMB;
          else
            control_next_state <= WAIT_DCFEB;
          end if;
        elsif(cafifo_l1a_dav(dev_cnt) = '1') then
          control_next_state       <= TX_ALCT_OTMB;
          oefifo_b_inner(dev_cnt)  <= '0';
          renfifo_b_inner(dev_cnt) <= '0';
        else
          control_next_state <= WAIT_ALCT_OTMB;
        end if;
        
      when TX_ALCT_OTMB =>
        dout_inner               <= DATAIN;
        dav_inner                <= '1';
        oefifo_b_inner(dev_cnt)  <= '0';
        renfifo_b_inner(dev_cnt) <= '0';
        if(q_datain_last = '1') then
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
        if(cafifo_l1a_match(dev_cnt) = '0' or cafifo_lost_pckt(dev_cnt) = '1') then
          dev_cnt_en <= '1';
          if (dev_cnt = 7) then
            control_next_state <= TAIL;
          else
            control_next_state <= WAIT_DCFEB;
          end if;
        elsif(cafifo_l1a_dav(dev_cnt) = '1') then
          control_next_state       <= TX_DCFEB;
          oefifo_b_inner(dev_cnt)  <= '0';
          renfifo_b_inner(dev_cnt) <= '0';
        else
          control_next_state <= WAIT_DCFEB;
        end if;

      when TX_DCFEB =>
        dout_inner               <= DATAIN;
        oefifo_b_inner(dev_cnt)  <= '0';
        renfifo_b_inner(dev_cnt) <= '0';
        tx_cnt_en                <= '1';
        if (tx_cnt = 3) then
          dav_inner <= '1';
        else
          dav_inner <= '0';
        end if;
        if(q_datain_last = '1') then
          dev_cnt_en <= '1';
          tx_cnt_rst <= '1';
          if (dev_cnt /= 7) then
            control_next_state <= WAIT_DCFEB;
          else
            control_next_state <= TAIL;
          end if;
        else
          control_next_state <= TX_DCFEB;
        end if;

      when TAIL =>
        dout_inner      <= tail_word(hdr_tail_cnt);
        dav_inner       <= '1';
        hdr_tail_cnt_en <= '1';
        if (hdr_tail_cnt = 8) then
          control_next_state <= WAIT_IDLE;
          eof_inner          <= '1';
          fifo_pop_80        <= '1';
          hdr_tail_cnt_rst   <= '1';
        else
          control_next_state <= TAIL;
          eof_inner          <= '0';
          fifo_pop_80        <= '0';
        end if;
        
      when WAIT_IDLE =>
        hdr_tail_cnt_en <= '1';
        if (hdr_tail_cnt = 8) then
          hdr_tail_cnt_rst   <= '1';
          control_next_state <= IDLE;
        else
          control_next_state <= WAIT_IDLE;
        end if;

    end case;
  end process;

  DAV       <= dav_inner;
  DOUT      <= dout_inner;
  OEFIFO_B  <= oefifo_b_inner;
  RENFIFO_B <= renfifo_b_inner;
  FIFO_POP  <= fifo_pop_inner;
  EOF       <= eof_inner;

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
  tail_word(3) <= x"F" & data_fifo_full(3 downto 1) & cafifo_lost_pckt(8) & dmb_l1pipe;
  tail_word(4) <= x"F" & cafifo_lost_pckt(9) & cafifo_lost_pckt(7 downto 1) & data_fifo_full(7 downto 4);
  tail_word(5) <= x"E" & data_fifo_full(NFEB+2 downto NFEB+1) & data_fifo_half(NFEB+2 downto NFEB+1) & otmb_to_end & data_fifo_half(NFEB downto 1);
  tail_word(6) <= x"E" & DAQMBID(11 downto 0);
  tail_word(7) <= x"E" & REG_CRC(22) & REG_CRC(10 downto 0);
  tail_word(8) <= x"E" & REG_CRC(23) & REG_CRC(21 downto 11);


end CONTROL_arch;
