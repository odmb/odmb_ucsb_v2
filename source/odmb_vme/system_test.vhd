-- SYSTEM_TEST: Provides utilities for testing components of ODMB

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use unisim.vcomponents.all;

entity SYSTEM_TEST is
  port (
    --CSP_FREE_AGENT_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);

    DEVICE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);
    INDATA  : in std_logic_vector(15 downto 0);
    STROBE  : in std_logic;
    WRITER  : in std_logic;
    SLOWCLK : in std_logic;
    CLK     : in std_logic;
    CLK160  : in std_logic;
    RST     : in std_logic;

    OUTDATA : out std_logic_vector(15 downto 0);
    DTACK   : out std_logic;

    -- DDU/PC/DCFEB COMMON PRBS
    PRBS_TYPE : out std_logic_vector(2 downto 0);

    -- DDU PRBS signals
    DDU_PRBS_TX_EN   : out std_logic;
    DDU_PRBS_RX_EN   : out std_logic;
    DDU_PRBS_TST_CNT : out std_logic_vector(15 downto 0);
    DDU_PRBS_ERR_CNT : in  std_logic_vector(15 downto 0);

    -- PC PRBS signals
    PC_PRBS_TX_EN   : out std_logic;
    PC_PRBS_RX_EN   : out std_logic;
    PC_PRBS_TST_CNT : out std_logic_vector(15 downto 0);
    PC_PRBS_ERR_CNT : in  std_logic_vector(15 downto 0);

    -- DCFEB PRBS signals
    DCFEB_PRBS_FIBER_SEL : out std_logic_vector(3 downto 0);
    DCFEB_PRBS_EN        : out std_logic;
    DCFEB_PRBS_RST       : out std_logic;
    DCFEB_PRBS_RD_EN     : out std_logic;
    DCFEB_RXPRBSERR      : in  std_logic;
    DCFEB_PRBS_ERR_CNT   : in  std_logic_vector(15 downto 0);

    -- OTMB PRBS signals
    OTMB_TX : in  std_logic_vector(48 downto 0);
    OTMB_RX : out std_logic_vector(5 downto 0)
    );
end SYSTEM_TEST;

architecture SYSTEM_TEST_Arch of SYSTEM_TEST is

  --component csp_systemtest_la is
  --  port (
  --    CLK     : in    std_logic := 'X';
  --    DATA    : in    std_logic_vector (199 downto 0);
  --    TRIG0   : in    std_logic_vector (7 downto 0);
  --    CONTROL : inout std_logic_vector (35 downto 0)
  --    );
  --end component;

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

  component COUNT_EDGES is
    generic (
      WIDTH : integer := 16
      );
    port (
      COUNT : out std_logic_vector(WIDTH-1 downto 0);

      CLK : in std_logic;
      RST : in std_logic;
      CE  : in std_logic
      );
  end component;

  signal cmddev                                : std_logic_vector (15 downto 0);
  signal w_ddu_prbs_tx_en, w_pc_prbs_tx_en     : std_logic;
  signal w_ddu_prbs_rx_en, w_pc_prbs_rx_en     : std_logic;
  signal r_ddu_prbs_err_cnt, r_pc_prbs_err_cnt : std_logic;
  signal strobe_pulse                          : std_logic;

-- GLOBAL PRBS
  signal r_prbs_type, w_prbs_type : std_logic;
  signal prbs_type_inner          : std_logic_vector(2 downto 0);

  -- DCFEB PRBS
  constant dcfeb_prbs_rst_cycles : integer := 1;
  constant dcfeb_prbs_lock       : integer := 20000000;
  constant dcfeb_prbs_length     : integer := 119;  -- 10^10 at 1.25 MHZ

  signal w_dcfeb_prbs_en, r_dcfeb_prbs_err_cnt  : std_logic;
  signal w_dcfeb_prbs_fiber, r_dcfeb_prbs_fiber : std_logic;
  signal r_dcfeb_prbs_edge                      : std_logic;
  signal dcfeb_prbs_fiber_sel_inner             : std_logic_vector (3 downto 0);
  signal dcfeb_prbs_rst_cnt                     : integer;
  signal dcfeb_prbs_seq_cnt                     : std_logic_vector (15 downto 0);
  signal dcfeb_prbs_en_cnt                      : integer;
  signal dcfeb_prbs_rd_en_cnt                   : integer;
  signal dcfeb_prbserr_edge_cnt                 : std_logic_vector (15 downto 0);  -- counting the edges
  signal dcfeb_prbs_init_pulse                  : std_logic;
  signal dcfeb_prbs_reset_pulse                 : std_logic;
  signal dcfeb_prbs_rd_en_pulse                 : std_logic;
  signal dcfeb_prbs_en_pulse                    : std_logic;

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
  signal r_otmb_prbs_good_cnt                   : std_logic;
  signal otmb_prbs_rx_cycles                    : integer;
  signal otmb_prbs_rx_sequences                 : std_logic_vector (15 downto 0);
  signal otmb_prbs_rx_en, otmb_prbs_rx_en_b     : std_logic;
  signal otmb_prbs_rx                           : std_logic;
  signal otmb_rx_inner                          : std_logic_vector (5 downto 0);
  signal otmb_tx_err_cnt                        : integer;
  signal q_otmb_prbs_tx_en, q_otmb_prbs_tx_en_b : std_logic;
  signal qq_otmb_prbs_tx_en                     : std_logic;
  signal mux_otmb_tx                            : std_logic_vector(48 downto 0);
  signal q_otmb_tx                              : std_logic_vector(48 downto 0);
  signal otmb_prbs_cnt_rst                      : std_logic;
  signal w_otmb_prbs_cnt_rst                    : std_logic;

  signal   otmb_tx_good_cnt, otmb_tx_good_cnt_int : integer;
  signal   otmb_prbs_tx_en_cnt                    : std_logic_vector (15 downto 0);
  signal   r_otmb_prbs_en_cnt                     : std_logic;
  constant otmb_prbs_length                       : integer := 10000;


  -- Declare the csp stuff here
  --signal free_agent_la_data : std_logic_vector(199 downto 0);
  --signal free_agent_la_trig : std_logic_vector(7 downto 0);
  
begin

  cmddev             <= "000" & DEVICE & COMMAND & "00";
  w_ddu_prbs_tx_en   <= '1' when (cmddev = x"1000" and STROBE = '1' and WRITER = '0') else '0';
  w_ddu_prbs_rx_en   <= '1' when (cmddev = x"1004" and STROBE = '1' and WRITER = '0') else '0';
  r_ddu_prbs_err_cnt <= '1' when (cmddev = x"100C" and WRITER = '1')                  else '0';

  w_pc_prbs_tx_en   <= '1' when (cmddev = x"1100" and STROBE = '1' and WRITER = '0') else '0';
  w_pc_prbs_rx_en   <= '1' when (cmddev = x"1104" and STROBE = '1' and WRITER = '0') else '0';
  r_pc_prbs_err_cnt <= '1' when (cmddev = x"110C" and WRITER = '1')                  else '0';

  w_dcfeb_prbs_en      <= '1' when (cmddev = x"1200" and STROBE = '1' and WRITER = '0') else '0';
  w_dcfeb_prbs_fiber   <= '1' when (cmddev = x"1204" and STROBE = '1' and WRITER = '0') else '0';
  r_dcfeb_prbs_fiber   <= '1' when (cmddev = x"1204" and WRITER = '1')                  else '0';
  r_dcfeb_prbs_edge    <= '1' when (cmddev = x"1208" and WRITER = '1')                  else '0';
  r_dcfeb_prbs_err_cnt <= '1' when (cmddev = x"120C" and WRITER = '1')                  else '0';

  w_prbs_type <= '1' when (cmddev = x"1300" and STROBE = '1' and WRITER = '0') else '0';
  r_prbs_type <= '1' when (cmddev = x"1300" and WRITER = '1')                  else '0';

  w_otmb_prbs_en       <= '1' when (cmddev = x"1400" and STROBE = '1' and WRITER = '0') else '0';
  r_otmb_prbs_en_cnt   <= '1' when (cmddev = x"1404" and WRITER = '1')                  else '0';
  r_otmb_prbs_good_cnt <= '1' when (cmddev = x"1408" and WRITER = '1')                  else '0';
  r_otmb_prbs_err_cnt  <= '1' when (cmddev = x"140C" and WRITER = '1')                  else '0';
  w_otmb_prbs_cnt_rst  <= '1' when (cmddev = x"1410" and STROBE = '1' and WRITER = '0') else '0';

  STROBE_PE : PULSE_EDGE port map(strobe_pulse, open, SLOWCLK, RST, 1, STROBE);

  DDU_PRBS_RX_EN <= w_ddu_prbs_rx_en;
  PC_PRBS_RX_EN  <= w_pc_prbs_rx_en;

  FDC_DDU_TX_PRBS : FDC port map(DDU_PRBS_TX_EN, w_ddu_prbs_tx_en, RST, or_reduce(INDATA));
  FDC_PC_TX_PRBS  : FDC port map(PC_PRBS_TX_EN, w_pc_prbs_tx_en, RST, or_reduce(INDATA));

  GEN_PRBS : for i in 15 downto 0 generate
  begin
    FDC_DDU_PRBS   : FDC port map(DDU_PRBS_TST_CNT(i), w_ddu_prbs_rx_en, RST, INDATA(i));
    FDC_PC_PRBS    : FDC port map(PC_PRBS_TST_CNT(i), w_pc_prbs_rx_en, RST, INDATA(i));
    FDC_DCFEB_PRBS : FDC port map(dcfeb_prbs_seq_cnt(i), w_dcfeb_prbs_en, RST, INDATA(i));
    FDC_OTMB_PRBS  : FDC port map(otmb_prbs_rx_sequences(i), w_otmb_prbs_en, RST, INDATA(i));
  end generate GEN_PRBS;

  GEN_FIBER : for i in 3 downto 0 generate
  begin
    FDC_FIBER : FDC port map(dcfeb_prbs_fiber_sel_inner(i), w_dcfeb_prbs_fiber, RST, INDATA(i));
  end generate GEN_FIBER;
  DCFEB_PRBS_FIBER_SEL <= dcfeb_prbs_fiber_sel_inner;

  GEN_PRBS_SEL : for i in 2 downto 0 generate
  begin
    FDC_PRBS_SEL : FDC port map(prbs_type_inner(i), w_prbs_type, RST, INDATA(i));
  end generate GEN_PRBS_SEL;
  PRBS_TYPE <= prbs_type_inner;

  OUTDATA <= DDU_PRBS_ERR_CNT when (r_ddu_prbs_err_cnt = '1') else
             PC_PRBS_ERR_CNT                                     when (r_pc_prbs_err_cnt = '1')    else
             DCFEB_PRBS_ERR_CNT                                  when (r_dcfeb_prbs_err_cnt = '1') else
             x"000" & dcfeb_prbs_fiber_sel_inner                 when (r_dcfeb_prbs_fiber = '1')   else
             dcfeb_prbserr_edge_cnt                              when (r_dcfeb_prbs_edge = '1')    else
             otmb_prbs_tx_en_cnt                                 when (r_otmb_prbs_en_cnt = '1')   else
             std_logic_vector(to_unsigned(otmb_tx_good_cnt, 16)) when (r_otmb_prbs_good_cnt = '1') else
             std_logic_vector(to_unsigned(otmb_tx_err_cnt, 16))  when (r_otmb_prbs_err_cnt = '1')  else
             x"000" & '0' & prbs_type_inner                      when (r_prbs_type = '1')          else
             (others => 'L');

  DTACK <= strobe_pulse and (w_ddu_prbs_tx_en or w_ddu_prbs_rx_en or r_ddu_prbs_err_cnt or
                             w_pc_prbs_tx_en or w_pc_prbs_rx_en or r_pc_prbs_err_cnt or
                             w_otmb_prbs_en or r_otmb_prbs_en_cnt or w_dcfeb_prbs_en or
                             r_dcfeb_prbs_err_cnt or r_dcfeb_prbs_edge or
                             w_dcfeb_prbs_fiber or r_dcfeb_prbs_fiber or w_prbs_type or
                             r_prbs_type or r_otmb_prbs_good_cnt or r_otmb_prbs_err_cnt or
                             w_otmb_prbs_cnt_rst);

  -- DCFEB PRBS signals
  dcfeb_prbs_rst_cnt   <= dcfeb_prbs_lock+dcfeb_prbs_rst_cycles;
  dcfeb_prbs_en_cnt    <= dcfeb_prbs_length*to_integer(unsigned(dcfeb_prbs_seq_cnt))+dcfeb_prbs_rst_cnt;
  dcfeb_prbs_rd_en_cnt <= dcfeb_prbs_en_cnt-1;

  DCFEBPRBSINIT : PULSE_EDGE port map(dcfeb_prbs_init_pulse, open, CLK160, RST, dcfeb_prbs_lock, w_dcfeb_prbs_en);
  DCFEBPRBSRST  : PULSE_EDGE port map(dcfeb_prbs_reset_pulse, open, CLK160, RST, dcfeb_prbs_rst_cnt, w_dcfeb_prbs_en);
  DCFEBPRBSRDEN : PULSE_EDGE port map(dcfeb_prbs_rd_en_pulse, open, CLK160, RST,
                                      dcfeb_prbs_rd_en_cnt, w_dcfeb_prbs_en);
  DCFEBPRBSEN : PULSE_EDGE port map(dcfeb_prbs_en_pulse, open, CLK160, RST, dcfeb_prbs_en_cnt, w_dcfeb_prbs_en);
  PRBSERR_CNT : COUNT_EDGES port map(dcfeb_prbserr_edge_cnt, DCFEB_RXPRBSERR, RST, '1');

  DCFEB_PRBS_RST   <= dcfeb_prbs_reset_pulse and not dcfeb_prbs_init_pulse;
  DCFEB_PRBS_EN    <= dcfeb_prbs_en_pulse;
  DCFEB_PRBS_RD_EN <= dcfeb_prbs_en_pulse and not dcfeb_prbs_rd_en_pulse;

  -- OTMB PRBS RX test
  otmb_prbs_rx_cycles <= otmb_prbs_length*to_integer(unsigned(otmb_prbs_rx_sequences));

  FD_OTMB_START    : FD port map(start_otmb_prbs_rx, CLK, w_otmb_prbs_en);
  PULSEOTMB_EN     : PULSE_EDGE port map(otmb_prbs_rx_en, open, CLK, RST, otmb_prbs_rx_cycles, start_otmb_prbs_rx);
  otmb_prbs_rx_en_b <= not otmb_prbs_rx_en;
  PULSEOTMB_RX_RST : PULSE_EDGE port map(pulse_otmb_prbs_rx_end, open, SLOWCLK, RST, 2, otmb_prbs_rx_en_b);
  otmb_prbs_rx_rst  <= pulse_otmb_prbs_rx_end or RST;

  PRBS_GEN_PM : PRBS_GEN port map(otmb_prbs_rx, CLK, otmb_prbs_rx_rst, otmb_prbs_rx_en);
  otmb_rx_inner <= (0 => otmb_prbs_rx_en, others => otmb_prbs_rx);
  OTMB_RX       <= otmb_rx_inner;

  -- OTMB PRBS TX test
  otmb_prbs_tx_en   <= q_otmb_tx(48);
  TX_EN_CNT        : COUNT_EDGES port map(otmb_prbs_tx_en_cnt, otmb_prbs_tx_en, rst, '1');
  otmb_prbs_tx_en_b <= not otmb_prbs_tx_en;
  PULSEOTMB_TX_RST : PULSE_EDGE port map(pulse_otmb_prbs_tx_end, open, SLOWCLK, RST, 2, otmb_prbs_tx_en_b);
  otmb_prbs_tx_rst  <= pulse_otmb_prbs_tx_end or RST;

  PE_EN  : PULSE_EDGE port map (q_otmb_prbs_tx_en, open, CLK, RST, 50, otmb_prbs_tx_en);
  q_otmb_prbs_tx_en_b <= not q_otmb_prbs_tx_en;
  PE_EN2 : PULSE_EDGE port map (qq_otmb_prbs_tx_en, open, CLK, RST, 100, q_otmb_prbs_tx_en_b);
  mux_otmb_tx         <= not q_otmb_tx when qq_otmb_prbs_tx_en = '1' else q_otmb_tx;

  PRBS_GEN_TX_PM   : PRBS_GEN port map(otmb_prbs_tx, CLK, otmb_prbs_tx_rst, otmb_prbs_tx_en);
  FD_OTMB_PRBS_TX  : FD port map(q_otmb_prbs_tx, CLK, otmb_prbs_tx);
  GEN_OTMB_PRBS_TX : for index in 48 downto 0 generate
    FD_OTMB_TX : FD port map(q_otmb_tx(index), CLK, OTMB_TX(index));
    otmb_prbs_tx_xor(index) <= mux_otmb_tx(index) xor otmb_prbs_tx;
  end generate GEN_OTMB_PRBS_TX;
  otmb_prbs_tx_err <= or_reduce(otmb_prbs_tx_xor(47 downto 0));

  CNT_RST : PULSE_EDGE port map(otmb_prbs_cnt_rst, open, CLK, RST, 2, w_otmb_prbs_cnt_rst);

  prbs_tx_cnt_proc : process (CLK, otmb_prbs_tx_err, RST, otmb_prbs_tx_en)
    variable bit : std_logic;
  begin
    if (RST = '1' or otmb_prbs_cnt_rst = '1') then
      otmb_tx_err_cnt      <= 0;
      otmb_tx_good_cnt_int <= 0;
      otmb_tx_good_cnt     <= 0;
    elsif (falling_edge(CLK) and otmb_prbs_tx_en = '1') then
      if otmb_prbs_tx_err = '1' then
        otmb_tx_err_cnt <= otmb_tx_err_cnt + 1;
      else
        otmb_tx_good_cnt_int <= otmb_tx_good_cnt_int + 1;
        if otmb_tx_good_cnt_int = otmb_prbs_length then
          otmb_tx_good_cnt     <= otmb_tx_good_cnt + 1;
          otmb_tx_good_cnt_int <= 1;
        end if;
      end if;
    else
      otmb_tx_good_cnt_int <= otmb_tx_good_cnt_int;
      otmb_tx_good_cnt     <= otmb_tx_good_cnt;
      otmb_tx_err_cnt      <= otmb_tx_err_cnt;
    end if;
  end process;

-- Chip ScopePro ILA core
  --csp_systemtest_la_pm : csp_systemtest_la
  --  port map (
  --    CONTROL => CSP_FREE_AGENT_PORT_LA_CTRL,
  --    CLK     => CLK,                   -- Good ol' 40MHz clock here
  --    DATA    => free_agent_la_data,
  --    TRIG0   => free_agent_la_trig
  --    );

  --free_agent_la_trig <= otmb_prbs_tx_en & "0000000";  -- to start with, anyhow.
  --free_agent_la_data <= "00" & x"000000" -- [199:174]
  --                       & otmb_prbs_rx_rst & otmb_prbs_tx_rst  -- [173:172]
  --                       & otmb_prbs_tx & otmb_prbs_rx          -- [171:170]
  --                       & start_otmb_prbs_rx & otmb_prbs_rx_en & otmb_prbs_tx_en & otmb_prbs_tx_err  -- [169:166]
  --                       & otmb_rx_inner(5 downto 0)   -- [165:160]
  --                       & OTMB_TX(47 downto 0)        -- [159:112]
  --                       & mux_otmb_tx(47 downto 0)     -- [111:64]
  --                       & otmb_prbs_tx_en_cnt(15 downto 0)     -- [63:48]                        
  --                       & std_logic_vector(to_unsigned(otmb_tx_err_cnt, 16))  -- [47:32]
  --                       & std_logic_vector(to_unsigned(otmb_tx_good_cnt_int, 16))  -- [31:16]
  --                       & std_logic_vector(to_unsigned(otmb_tx_good_cnt, 16));  -- [15:0]
   

end SYSTEM_TEST_Arch;
