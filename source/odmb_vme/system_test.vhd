-- SYSTEM_TEST: Provides utilities for testing components of ODMB

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity SYSTEM_TEST is
  port (
    DEVICE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);
    INDATA  : in std_logic_vector(15 downto 0);
    STROBE  : in std_logic;
    WRITER  : in std_logic;
    SLOWCLK : in std_logic;
    CLK80   : in std_logic;
    RST     : in std_logic;

    OUTDATA : out std_logic_vector(15 downto 0);
    DTACK   : out std_logic;

    -- DDU PRBS signals
    DDU_PRBS_EN      : out std_logic;
    DDU_PRBS_TST_CNT : out std_logic_vector(15 downto 0);
    DDU_PRBS_RD_EN   : out std_logic;
    DDU_PRBS_ERR_CNT : in  std_logic_vector(15 downto 0);

    -- PC PRBS signals
    PC_PRBS_EN      : out std_logic;
    PC_PRBS_TST_CNT : out std_logic_vector(15 downto 0);
    PC_PRBS_RD_EN   : out std_logic;
    PC_PRBS_ERR_CNT : in  std_logic_vector(15 downto 0);

    -- OTMB PRBS signals
    OTMB_TX : in  std_logic_vector(48 downto 0);
    OTMB_RX : out std_logic_vector(5 downto 0)
    );
end SYSTEM_TEST;

architecture SYSTEM_TEST_Arch of SYSTEM_TEST is
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

  component PRBS_GEN is
    port (
      DOUT : out std_logic;

      CLK    : in std_logic;
      RST    : in std_logic;
      ENABLE : in std_logic
      );
  end component;

  signal cmddev                                : std_logic_vector (15 downto 0);
  signal w_ddu_prbs_en, w_pc_prbs_en           : std_logic;
  signal r_ddu_prbs_err_cnt, r_pc_prbs_err_cnt : std_logic;
  signal strobe_pulse                          : std_logic;
  signal dtack_inner                           : std_logic;

  signal start_otmb_prbs_rx                     : std_logic;
  signal pulse_otmb_prbs_tx_end                 : std_logic;
  signal otmb_prbs_tx_rst                       : std_logic;
  signal otmb_prbs_rx_rst                       : std_logic;
  signal otmb_prbs_tx_en, otmb_prbs_tx_en_b     : std_logic;
  signal pulse_otmb_prbs_rx_end                 : std_logic;
  signal otmb_prbs_tx_xor                       : std_logic_vector(48 downto 0);
  signal otmb_prbs_tx                           : std_logic;
  signal otmb_prbs_tx_err                       : std_logic;
  signal q_otmb_prbs_tx                         : std_logic;
  signal w_otmb_prbs_en, r_otmb_prbs_err_cnt    : std_logic;
  signal otmb_prbs_rx_cycles                    : integer;
  signal otmb_prbs_rx_sequences                 : std_logic_vector (15 downto 0);
  signal otmb_prbs_rx_en, otmb_prbs_rx_en_b     : std_logic;
  signal otmb_prbs_rx                           : std_logic;
  signal otmb_tx_err_cnt                        : integer;
  signal q_otmb_prbs_tx_en, q_otmb_prbs_tx_en_b : std_logic;
  signal qq_otmb_prbs_tx_en                     : std_logic;
  signal mux_otmb_tx                            : std_logic_vector(48 downto 0);
  signal q_otmb_tx                              : std_logic_vector(48 downto 0);
  
begin
  cmddev              <= "000" & DEVICE & COMMAND & "00";
  w_ddu_prbs_en       <= '1' when (cmddev = x"1000" and STROBE = '1' and WRITER = '0') else '0';
  r_ddu_prbs_err_cnt  <= '1' when (cmddev = x"100C" and STROBE = '1' and WRITER = '1') else '0';
  w_pc_prbs_en        <= '1' when (cmddev = x"1100" and STROBE = '1' and WRITER = '0') else '0';
  r_pc_prbs_err_cnt   <= '1' when (cmddev = x"110C" and STROBE = '1' and WRITER = '1') else '0';
  w_otmb_prbs_en      <= '1' when (cmddev = x"1200" and STROBE = '1' and WRITER = '0') else '0';
  r_otmb_prbs_err_cnt <= '1' when (cmddev = x"120C" and STROBE = '1' and WRITER = '1') else '0';

  STROBE_PE : PULSE_EDGE port map(strobe_pulse, open, SLOWCLK, RST, 1, STROBE);

  DDU_PRBS_EN    <= w_ddu_prbs_en;
  DDU_PRBS_RD_EN <= '1' when (r_ddu_prbs_err_cnt = '1' and strobe_pulse = '1') else '0';

  PC_PRBS_EN    <= w_pc_prbs_en;
  PC_PRBS_RD_EN <= '1' when (r_pc_prbs_err_cnt = '1' and strobe_pulse = '1') else '0';

  GEN_PRBS : for i in 15 downto 0 generate
  begin
    FDC_DDU_PRBS  : FDC port map(DDU_PRBS_TST_CNT(i), w_ddu_prbs_en, RST, INDATA(i));
    FDC_PC_PRBS   : FDC port map(PC_PRBS_TST_CNT(i), w_pc_prbs_en, RST, INDATA(i));
    FDC_OTMB_PRBS : FDC port map(otmb_prbs_rx_sequences(i), w_otmb_prbs_en, RST, INDATA(i));
  end generate GEN_PRBS;

  OUTDATA <= DDU_PRBS_ERR_CNT when (r_ddu_prbs_err_cnt = '1') else
             PC_PRBS_ERR_CNT                                    when (r_pc_prbs_err_cnt = '1')   else
             std_logic_vector(to_unsigned(otmb_tx_err_cnt, 16)) when (r_otmb_prbs_err_cnt = '1') else
             (others => 'L');

  dtack_inner <= '0' when (w_ddu_prbs_en = '1' and strobe_pulse = '1')       else 'Z';
  dtack_inner <= '0' when (r_ddu_prbs_err_cnt = '1' and strobe_pulse = '1')  else 'Z';
  dtack_inner <= '0' when (w_pc_prbs_en = '1' and strobe_pulse = '1')        else 'Z';
  dtack_inner <= '0' when (r_pc_prbs_err_cnt = '1' and strobe_pulse = '1')   else 'Z';
  dtack_inner <= '0' when (w_otmb_prbs_en = '1' and strobe_pulse = '1')      else 'Z';
  dtack_inner <= '0' when (r_otmb_prbs_err_cnt = '1' and strobe_pulse = '1') else 'Z';
  DTACK       <= dtack_inner;

  -- OTMB PRBS RX test
  otmb_prbs_rx_cycles <= 127*to_integer(unsigned(otmb_prbs_rx_sequences));

  FD_OTMB_START    : FD port map(start_otmb_prbs_rx, CLK80, w_otmb_prbs_en);
  PULSEOTMB_EN     : PULSE_EDGE port map(otmb_prbs_rx_en, open, CLK80, RST, otmb_prbs_rx_cycles, start_otmb_prbs_rx);
  otmb_prbs_rx_en_b <= not otmb_prbs_rx_en;
  PULSEOTMB_RX_RST : PULSE_EDGE port map(pulse_otmb_prbs_rx_end, open, SLOWCLK, RST, 2, otmb_prbs_rx_en_b);
  otmb_prbs_rx_rst  <= pulse_otmb_prbs_rx_end or RST;

  PRBS_GEN_PM : PRBS_GEN port map(otmb_prbs_rx, CLK80, otmb_prbs_rx_rst, otmb_prbs_rx_en);
  OTMB_RX <= (0 => otmb_prbs_rx_en, others => otmb_prbs_rx);

  -- OTMB PRBS TX test
  otmb_prbs_tx_en   <= q_otmb_tx(48);
  otmb_prbs_tx_en_b <= not otmb_prbs_tx_en;
  PULSEOTMB_TX_RST : PULSE_EDGE port map(pulse_otmb_prbs_tx_end, open, SLOWCLK, RST, 2, otmb_prbs_tx_en_b);
  otmb_prbs_tx_rst  <= pulse_otmb_prbs_tx_end or RST;

  PE_EN  : PULSE_EDGE port map (q_otmb_prbs_tx_en, open, CLK80, RST, 64, otmb_prbs_tx_en);
  q_otmb_prbs_tx_en_b <= not q_otmb_prbs_tx_en;
  PE_EN2 : PULSE_EDGE port map (qq_otmb_prbs_tx_en, open, CLK80, RST, 64, q_otmb_prbs_tx_en_b);
  mux_otmb_tx         <= not q_otmb_tx when qq_otmb_prbs_tx_en = '1' else q_otmb_tx;

  PRBS_GEN_TX_PM   : PRBS_GEN port map(otmb_prbs_tx, CLK80, otmb_prbs_tx_rst, otmb_prbs_tx_en);
  FD_OTMB_PRBS_TX  : FD port map(q_otmb_prbs_tx, CLK80, otmb_prbs_tx);
  GEN_OTMB_PRBS_TX : for index in 48 downto 0 generate
    FD_OTMB_TX : FD port map(q_otmb_tx(index), CLK80, otmb_tx(index));
    otmb_prbs_tx_xor(index) <= mux_otmb_tx(index) xor otmb_prbs_tx;
  end generate GEN_OTMB_PRBS_TX;
  otmb_prbs_tx_err <= or_reduce(otmb_prbs_tx_xor(47 downto 0));

  prbs_tx_cnt_proc : process (CLK80, otmb_prbs_tx_err, RST, otmb_prbs_tx_en)
    variable bit : std_logic;
  begin
    if (RST = '1' or rising_edge(otmb_prbs_tx_en)) then
      otmb_tx_err_cnt <= 0;
    elsif (falling_edge(CLK80)) then
      if otmb_prbs_tx_err = '1' then
        otmb_tx_err_cnt <= otmb_tx_err_cnt + 1;
      end if;
    end if;
  end process;

end SYSTEM_TEST_Arch;
