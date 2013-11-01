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

  constant LOGICH                   : std_logic                    := '1';
  signal   BUSY                     : std_logic;
  signal   STARTREAD_RST, STARTREAD : std_logic                    := '0';
  signal   OEHDR                    : std_logic_vector(8 downto 1) := (others => '0');

  signal R, R_RST : std_logic_vector(NFEB+2 downto 1);

  signal TAIL_RST, DDCNT_EN_RST, DDCNT_TC, OKDATA, DODAT : std_logic := '0';
  signal TAIL                                            : std_logic_vector(8 downto 1);
  signal STARTTAIL_CE, STARTTAIL                         : std_logic := '0';
  signal TAILDONE, STPOP, L1ONLY, POP                    : std_logic := '0';

  signal FIFO_POP_RST, FIFO_POP_INNER, FIFO_POP_D : std_logic;

  type   hdr_tail_array is array (8 downto 1) of std_logic_vector(15 downto 0);
  signal hdr_word, tail_word : hdr_tail_array;

  constant ZERO9 : std_logic_vector(8 downto 0) := (others => '0');

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

  type   control_state is (IDLE, HDR_TX, TAIL_TX, WAIT_ALCT);
  signal control_current_state, control_next_state : control_state := IDLE;

  signal hdr_tail_cnt_en, hdr_tail_cnt_rst : std_logic                     := '0';
  signal hdr_tail_cnt                      : integer range 1 to 9          := 1;
  signal reg_crc                           : std_logic_vector(23 downto 0) := (others => '0');

begin

  control_fsm_regs : process (control_next_state, RST, CLK)
  begin
    if (RST = '1') then
      control_current_state <= IDLE;
      hdr_tail_cnt          <= 1;
    elsif rising_edge(CLK) then
      control_current_state <= control_next_state;
      if(hdr_tail_cnt_rst = '1') then
        hdr_tail_cnt <= 1;
      elsif(hdr_tail_cnt_en = '1') then
        hdr_tail_cnt <= hdr_tail_cnt + 1;
      end if;
    end if;
  end process;

  control_fsm_logic : process (control_current_state, cafifo_l1a_match, hdr_word, hdr_tail_cnt)
  begin
    DOUT             <= (others => '0');
    DAV              <= '0';
    hdr_tail_cnt_rst <= '0';
    hdr_tail_cnt_en  <= '0';

    case control_current_state is
      when IDLE =>
        hdr_tail_cnt_rst <= '1';
        if (or_reduce(cafifo_l1a_match) = '1') then
          control_next_state <= HDR_TX;
        else
          control_next_state <= IDLE;
        end if;
        
      when HDR_TX =>
        DOUT             <= hdr_word(hdr_tail_cnt);
        DAV              <= '1';
        hdr_tail_cnt_en  <= '1';
        if (hdr_tail_cnt = 8) then
          control_next_state <= WAIT_ALCT;
        else
          control_next_state <= HDR_TX;
        end if;
        
      when WAIT_ALCT =>
        hdr_tail_cnt_rst   <= '1';
        control_next_state <= TAIL_TX;
        
      when TAIL_TX =>
        DOUT             <= tail_word(hdr_tail_cnt);
        DAV              <= '1';
        hdr_tail_cnt_en  <= '1';
        if (hdr_tail_cnt = 8) then
          control_next_state <= IDLE;
        else
          control_next_state <= TAIL_TX;
        end if;
    end case;
  end process;


-- Generate OEHDR (page 1)
  STARTREAD_RST <= RST or OEHDR(1);
  FDC_OEHDR_LOGICH : FDC port map (STARTREAD, BUSY, STARTREAD_RST, LOGICH);
  FDC_OEHDR_START  : FDC port map (OEHDR(1), CLK, RST, STARTREAD);
  FDC_OEHDR1       : FDC port map (OEHDR(2), CLK, RST, OEHDR(1));
  FDC_OEHDR2       : FDC port map (OEHDR(3), CLK, RST, OEHDR(2));
  FDC_OEHDR_GEN    : for i in 3 to 7 generate
  begin
    FDC_OEHDR : FDC port map (OEHDR(i+1), CLK, POP, OEHDR(i));
  end generate FDC_OEHDR_GEN;

  hdr_word(1) <= x"9" & cafifo_l1a_cnt(11 downto 0);
  hdr_word(2) <= x"9" & cafifo_l1a_cnt(23 downto 12);
  hdr_word(3) <= x"9" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & fmt_vers & l1a_dav_mismatch & cafifo_l1a_match(NFEB downto 1);
  hdr_word(4) <= x"9" & cafifo_bx_cnt;
  hdr_word(5) <= x"A" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & fmt_vers & l1a_dav_mismatch & cafifo_l1a_match(NFEB downto 1);
  hdr_word(6) <= x"A" & DAQMBID(11 downto 0);
  hdr_word(7) <= x"A" & cafifo_l1a_match(NFEB+2 downto NFEB+1) & ovlp & cafifo_bx_cnt(4 downto 0);
  hdr_word(8) <= x"A" & sync & fmt_vers & l1a_dav_mismatch & cafifo_l1a_cnt(4 downto 0);

-- Generate TAIL (page 1)
  STARTTAIL_CE <= '1' when (BUSY = '1' and (R(NFEB+2 downto 1) = ZERO9)) else '0';
  FDCE_TAIL     : FDCE port map (STARTTAIL, CLK, STARTTAIL_CE, TAIL(1), DODAT);
  FDC_STARTTAIL : FDC port map (TAIL(1), CLK, RST, STARTTAIL);
  FDC_TAIL1     : FDC port map (TAIL(2), CLK, RST, TAIL(1));
  FDC_TAIL_GEN  : for i in 2 to 7 generate
  begin
    FDC_TAIL : FDC port map (TAIL(i+1), CLK, POP, TAIL(i));
  end generate FDC_TAIL_GEN;

  tail_word(1) <= x"F" & alct_to_end & cafifo_bx_cnt(4 downto 0) & cafifo_l1a_cnt(5 downto 0);
  tail_word(2) <= x"F" & ovlp & dcfeb_to_end;
  tail_word(3) <= x"F" & data_fifo_full(3 downto 1) & otmb_to_start & dmb_l1pipe;
  tail_word(4) <= x"F" & alct_to_start & dcfeb_to_start & data_fifo_full(7 downto 4);
  tail_word(5) <= x"E" & data_fifo_full(NFEB+2 downto NFEB+1) & data_fifo_half(NFEB+2 downto NFEB+1) & otmb_to_end & data_fifo_half(NFEB downto 1);
  tail_word(6) <= x"E" & DAQMBID(11 downto 0);
  tail_word(7) <= x"E" & REG_CRC(22) & REG_CRC(10 downto 0);
  tail_word(8) <= x"E" & REG_CRC(23) & REG_CRC(21 downto 11);


end CONTROL_arch;
