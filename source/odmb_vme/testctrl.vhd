-- TESTCTRL: Generates internal triggers specifying the pattern and bunch
-- crossing in FIFOs

library ieee;
library work;
library unisim;
library unimacro;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ucsb_types.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;

entity TESTCTRL is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );
  port (
    --CSP_FREE_AGENT_PORT_LA_CTRL : inout std_logic_vector(35 downto 0);
    CLK                          : in    std_logic;
    DDUCLK                       : in    std_logic;
    SLOWCLK                      : in    std_logic;
    RST                          : in    std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    L1A            : out std_logic;
    ALCT_DAV       : out std_logic;
    OTMB_DAV       : out std_logic;
    LCT            : out std_logic_vector(NFEB downto 0);
    DDU_DATA       : in  std_logic_vector(15 downto 0);
    DDU_DATA_VALID : in  std_logic;
    TC_RUN         : out std_logic;
    TS_OUT         : out std_logic_vector(31 downto 0)
    );
end TESTCTRL;

architecture TESTCTRL_Arch of TESTCTRL is

  component csp_systemtest_la is
    port (
      CLK     : in std_logic := 'X';
      DATA    : in std_logic_vector (127 downto 0);
      TRIG0   : in std_logic_vector (7 downto 0);
      CONTROL : inout std_logic_vector (35 downto 0)
      );
  end component;

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

  signal CMDDEV : std_logic_vector(15 downto 0);

  signal WRITE_FIFO, READ_FIFO, WRITE_FSR, READ_FSR                         : std_logic;
  signal READ_STR, READ_WRC, READ_RDC, READ_TRC                             : std_logic;
  signal FSR_vector                                                         : std_logic_vector(9 downto 0);
  signal D_DTACK_WRITE_FSR, E_DTACK_WRITE_FSR                               : std_logic;
  signal D_DTACK_READ_FSR, E_DTACK_READ_FSR                                 : std_logic;
  signal D_DTACK_READ_STR, E_DTACK_READ_STR                                 : std_logic;
  signal D_DTACK_READ_WRC, E_DTACK_READ_WRC                                 : std_logic;
  signal D_DTACK_READ_RDC, E_DTACK_READ_RDC                                 : std_logic;
  signal D_DTACK_READ_TRC, E_DTACK_READ_TRC                                 : std_logic;
  signal D_DTACK_READ_FIFO, E1_DTACK_READ_FIFO                              : std_logic;
  signal E2_DTACK_READ_FIFO, E_DTACK_READ_FIFO                              : std_logic;
  signal D_DTACK_WRITE_FIFO, E1_DTACK_WRITE_FIFO                            : std_logic;
  signal E2_DTACK_WRITE_FIFO, E_DTACK_WRITE_FIFO                            : std_logic;
  signal I1_FIFO_RD_EN, I2_FIFO_RD_EN, I3_FIFO_RD_EN, C_FIFO_RD_EN, FIFO_RD : std_logic_vector(3 downto 0);
  signal I1_FIFO_WR_EN, I2_FIFO_WR_EN, I3_FIFO_WR_EN, C_FIFO_WR_EN, FIFO_WR : std_logic_vector(3 downto 0);

  signal FIFO_WR_DATA : std_logic_vector(15 downto 0);

  signal event_rd : std_logic;

  signal ts_cnt_out, ts_fifo_out : std_logic_vector(31 downto 0);

  type   tc_fifo_cnt_data_type is array (3 downto 0) of std_logic_vector(10 downto 0);
  signal tc_fifo_wr_cnt, tc_fifo_rd_cnt : tc_fifo_cnt_data_type;

  type     tc_fifo_in_type is array (3 downto 0) of std_logic_vector(15 downto 0);
  signal   tc_fifo_in                    : tc_fifo_in_type;
  signal   fifo_sel                      : std_logic_vector(3 downto 0);
  signal   fifo_str                      : std_logic_vector(15 downto 0);
  signal   fifo_wrc                      : std_logic_vector(10 downto 0);
  signal   fifo_rdc                      : std_logic_vector(10 downto 0);
  signal   fifo_data                     : std_logic_vector(15 downto 0);
  signal   fifo_rd_en, fifo_wr_en        : std_logic_vector(3 downto 0);
  signal   tc_fifo_rd_en, tc_fifo_wr_en  : std_logic_vector(3 downto 0);
  signal   tc_fifo_wr_ck, tc_fifo_rd_ck  : std_logic_vector(3 downto 0);
  signal   tc_run_inner                  : std_logic     := '0';
  signal   tc_fifo_out                   : tc_fifo_in_type;
  signal   tc_fifo_full, tc_fifo_afull   : std_logic_vector(3 downto 0);
  signal   tc_fifo_aempty, tc_fifo_empty : std_logic_vector(3 downto 0);
  signal   event_fifo_out                : std_logic_vector(15 downto 0);
  signal   tc_fifo_rst, do_tc_fifo_rst                   : std_logic;
  signal   ts_cnt_rst                    : std_logic;
  type     boolean_array is array (3 downto 0) of boolean;
  constant tc_fifo_fwft                  : boolean_array := (false, true, true, true);

  signal trg_cnt_rst      : std_logic;
  signal trg_cnt_sel      : std_logic_vector(3 downto 0);
  type   lct_cnt_data_type is array (7 downto 0) of std_logic_vector(15 downto 0);
  signal lct_cnt_out      : lct_cnt_data_type;
  signal l1a_cnt_out      : std_logic_vector(15 downto 0);
  signal alct_dav_cnt_out : std_logic_vector(15 downto 0);
  signal otmb_dav_cnt_out : std_logic_vector(15 downto 0);
  signal trg_cnt_data     : std_logic_vector(15 downto 0);

  signal l1a_inner      : std_logic;
  signal alct_dav_inner : std_logic;
  signal otmb_dav_inner : std_logic;
  signal lct_inner      : std_logic_vector(NFEB downto 0);

  signal nrep_cnt               : integer                       := 0;
  signal nrep_vme, nrep_data    : std_logic_vector(15 downto 0) := (others => '0');
  signal w_nrep, d_nrep, q_nrep : std_logic                     := '0';
  signal nrep_rst, nrep_wren    : std_logic                     := '0';

  signal field_data                  : std_logic_vector(15 downto 0) := (others => '0');
  signal r_field, d_dtack_field_nrep : std_logic                     := '0';

  -- Declare the csp stuff here
  signal testctrl_la_data : std_logic_vector(127 downto 0);
  signal testctrl_la_trig : std_logic_vector(7 downto 0);
  
begin  --Architecture

-- FSR(0) -> select fifo(0) (tc_fifo_ts_l)
-- FSR(1) -> select fifo(1) (tc_fifo_ts_h)
-- FSR(2) -> select fifo(2) (tc_fifo_event)
-- FSR(3) -> select fifo(3) (tc_fifo_ddudata)
-- FSR(5) -> ts_cnt_rst (reset time stamp counter)
-- FSR(6) -> tc_fifo_rst (reset tc fifos)
-- FSR(7) -> trg_cnt_rst (reset trigger counters)
-- FSR(11 downto 8) -> trg_cnt_sel (select trigger counter)

  CMDDEV     <= "000" & DEVICE & COMMAND(9 downto 0) & "00";
  WRITE_FSR  <= '1' when (CMDDEV = x"1020") else '0';  -- WRITE FSR
  READ_FSR   <= '1' when (CMDDEV = x"1024") else '0';  -- READ FSR
  WRITE_FIFO <= '1' when (CMDDEV = x"1008") else '0';  -- WRITE FIFO
  READ_FIFO  <= '1' when (CMDDEV = x"100C") else '0';  -- READ FIFO
  READ_STR   <= '1' when (CMDDEV = x"101C") else '0';  -- READ FIFO STATUS REGISTER
  READ_WRC   <= '1' when (CMDDEV = x"102C") else '0';  -- READ WRITE COUNTER REGISTER
  READ_RDC   <= '1' when (CMDDEV = x"103C") else '0';  -- READ FIFO READ COUNTER REGISTER
  READ_TRC   <= '1' when (CMDDEV = x"1028") else '0';  -- READ TRIGGER COUNTER

  W_NREP  <= '1' when (CMDDEV = x"1030")                            else '0';  -- WRITE NUMBER OF REPETITIONS
  R_FIELD <= '1' when (DEVICE = '1' and CMDDEV(7 downto 0) = x"34") else '0';  -- Read NUMBER OF REPETITIONS

  CREATE_FSR_vector : for I in 9 downto 0 generate
  begin
    FD_FSR_vec : FDCE port map (FSR_vector(I), STROBE, WRITE_FSR, RST, INDATA(I));
  end generate CREATE_FSR_vector;

  FIFO_SEL    <= FSR_vector(3 downto 0);
  do_tc_fifo_rst <= rst or FSR_vector(4);
  PULSE_RESET_TC : NPULSE2FAST port map(tc_fifo_rst, clk, '0', 50, do_tc_fifo_rst);
  
  trg_cnt_rst <= rst or FSR_vector(5);
  trg_cnt_sel <= FSR_vector(9 downto 6);

  -- NREP: VME register and counter
  nrep_rst <= RST;
  GEN_NREP : for I in 0 to 15 generate
    FDNREP : FDCE port map(nrep_vme(I), strobe, w_nrep, nrep_rst, indata(I));
  end generate GEN_NREP;
  PULSENREP : PULSE_EDGE port map(nrep_wren, open, slowclk, rst, 1, d_nrep);

  NREP_PRO : process(nrep_rst, clk, ts_cnt_out, ts_fifo_out, nrep_wren)
  begin
    if (nrep_rst = '1') then
      nrep_cnt   <= 0;
      ts_cnt_rst <= '1';
    elsif rising_edge(clk) then
      if (nrep_wren = '1') then
        nrep_cnt   <= to_integer(unsigned(nrep_vme));
        ts_cnt_rst <= '1';
      elsif (tc_run_inner = '1' and unsigned(ts_fifo_out) < unsigned(ts_cnt_out)) then
        nrep_cnt   <= nrep_cnt - 1;
        ts_cnt_rst <= '1';
      else
        nrep_cnt   <= nrep_cnt;
        ts_cnt_rst <= '0';
      end if;
    end if;
  end process;
  tc_run_inner <= '1' when nrep_cnt > 0 else '0';
  tc_run       <= tc_run_inner;
  nrep_data    <= std_logic_vector(to_unsigned(nrep_cnt, 16));

  field_data <= nrep_data when (CMDDEV(11 downto 8) = x"0") else
                ts_cnt_out(15 downto 0)  when (CMDDEV(11 downto 8) = x"1") else
                ts_fifo_out(15 downto 0) when (CMDDEV(11 downto 8) = x"2") else
                (others => '0');

  OUTDATA <= "000000000000" & FSR_vector(3 downto 0) when (STROBE = '1' and READ_FSR = '1') else
             FIFO_STR(15 downto 0)           when (STROBE = '1' and READ_STR = '1')  else
             "00000" & FIFO_WRC(10 downto 0) when (STROBE = '1' and READ_WRC = '1')  else
             "00000" & FIFO_RDC(10 downto 0) when (STROBE = '1' and READ_RDC = '1')  else
             FIFO_DATA(15 downto 0)          when (STROBE = '1' and READ_FIFO = '1') else
             TRG_CNT_DATA(15 downto 0)       when (STROBE = '1' and READ_TRC = '1')  else
             FIELD_DATA(15 downto 0)         when (STROBE = '1' and R_FIELD = '1')   else
             FIFO_DATA(15 downto 0);

  D_DTACK_READ_FSR   <= READ_FSR and STROBE;
  FD_DTACK_FSR             : FD port map (E_DTACK_READ_FSR, SLOWCLK, D_DTACK_READ_FSR);
  D_DTACK_READ_STR   <= READ_STR and STROBE;
  FD_DTACK_STR             : FD port map (E_DTACK_READ_STR, SLOWCLK, D_DTACK_READ_STR);
  D_DTACK_READ_WRC   <= READ_WRC and STROBE;
  FD_DTACK_WRC             : FD port map (E_DTACK_READ_WRC, SLOWCLK, D_DTACK_READ_WRC);
  D_DTACK_READ_RDC   <= READ_RDC and STROBE;
  FD_DTACK_RDC             : FD port map (E_DTACK_READ_RDC, SLOWCLK, D_DTACK_READ_RDC);
  D_DTACK_READ_FIFO  <= READ_FIFO and STROBE;
  FD_DTACK_READ_FIFO_DE1   : FD port map (E1_DTACK_READ_FIFO, SLOWCLK, D_DTACK_READ_FIFO);
  FD_DTACK_READ_FIFO_E1E2  : FD port map (E2_DTACK_READ_FIFO, SLOWCLK, E1_DTACK_READ_FIFO);
  FD_DTACK_READ_FIFO_E2E   : FD port map (E_DTACK_READ_FIFO, SLOWCLK, E2_DTACK_READ_FIFO);
  D_DTACK_WRITE_FSR  <= WRITE_FSR and STROBE;
  FD_DTACK_WRITE_FSR       : FD port map (E_DTACK_WRITE_FSR, SLOWCLK, D_DTACK_WRITE_FSR);
  D_DTACK_WRITE_FIFO <= WRITE_FIFO and STROBE;
  FD_DTACK_WRITE_FIFO_DE1  : FD port map (E1_DTACK_WRITE_FIFO, SLOWCLK, D_DTACK_WRITE_FIFO);
  FD_DTACK_WRITE_FIFO_E1E2 : FD port map (E2_DTACK_WRITE_FIFO, SLOWCLK, E1_DTACK_WRITE_FIFO);
  E_DTACK_WRITE_FIFO <= E1_DTACK_WRITE_FIFO or E2_DTACK_WRITE_FIFO;
  D_DTACK_READ_TRC   <= READ_TRC and STROBE;
  FD_DTACK_READ_TRC        : FD port map (E_DTACK_READ_TRC, SLOWCLK, D_DTACK_READ_TRC);
  d_nrep             <= w_nrep and strobe;
  d_dtack_field_nrep <= (r_field and strobe) or d_nrep;
  FD_DTACK_W_NREP          : FD port map(q_nrep, slowclk, d_dtack_field_nrep);

  DTACK <= '1' when (E_DTACK_READ_FSR = '1' or E_DTACK_READ_STR = '1' or E_DTACK_READ_WRC = '1' or
                     E_DTACK_READ_RDC = '1' or E_DTACK_READ_FIFO = '1' or E_DTACK_WRITE_FSR = '1' or
                     E_DTACK_WRITE_FIFO = '1' or E_DTACK_READ_TRC = '1' or q_nrep = '1') else '0';


  CREATE_FIFO_RD_EN : for I in 3 downto 0 generate
  begin
    FIFO_RD(I)      <= READ_FIFO and FSR_vector(I);
    FD_FIFO_RD_EN_I1   : FDC port map (I1_FIFO_RD_EN(I), STROBE, C_FIFO_RD_EN(I), FIFO_RD(I));
    FD_FIFO_RD_EN_I1I2 : FDC port map (I2_FIFO_RD_EN(I), SLOWCLK, C_FIFO_RD_EN(I), I1_FIFO_RD_EN(I));
    FD_FIFO_RD_EN_I2I3 : FDC port map (I3_FIFO_RD_EN(I), SLOWCLK, RST, I2_FIFO_RD_EN(I));
    C_FIFO_RD_EN(I) <= RST or I3_FIFO_RD_EN(I);
  end generate CREATE_FIFO_RD_EN;
  FIFO_RD_EN <= I2_FIFO_RD_EN;

  CREATE_FIFO_WR_DATA : for I in 15 downto 0 generate
  begin
    FD_INDATA_I1   : FD port map (FIFO_WR_DATA(I), STROBE, INDATA(I));
  end generate CREATE_FIFO_WR_DATA;


  CREATE_FIFO_WR_EN : for I in 3 downto 0 generate
  begin
    FIFO_WR(I)      <= WRITE_FIFO and FSR_vector(I);
    FD_FIFO_WR_EN_I1   : FDC port map (I1_FIFO_WR_EN(I), STROBE, C_FIFO_WR_EN(I), FIFO_WR(I));
    FD_FIFO_WR_EN_I1I2 : FDC port map (I2_FIFO_WR_EN(I), SLOWCLK, C_FIFO_WR_EN(I), I1_FIFO_WR_EN(I));
    FD_FIFO_WR_EN_I2I3 : FDC port map (I3_FIFO_WR_EN(I), SLOWCLK, RST, I2_FIFO_WR_EN(I));
    C_FIFO_WR_EN(I) <= RST or I3_FIFO_WR_EN(I);
  end generate CREATE_FIFO_WR_EN;
  FIFO_WR_EN <= I2_FIFO_WR_EN;

-- When running, the FIFOs are refilled with what they send out
  GEN_TC_FIFO_VALS : for I in 2 downto 0 generate  -- (DDU_DATA,L1A/ALCT_DAV/OTMB_DAV/LCT,TSH,TSL)
  begin
    tc_fifo_wr_ck(I) <= clk            when (tc_run_inner = '1') else slowclk;
    tc_fifo_wr_en(I) <= event_rd       when (tc_run_inner = '1') else fifo_wr_en(I);
    tc_fifo_in(I)    <= tc_fifo_out(I) when (tc_run_inner = '1') else FIFO_WR_DATA;

    tc_fifo_rd_ck(I) <= clk      when (tc_run_inner = '1') else slowclk;
    tc_fifo_rd_en(I) <= event_rd when (tc_run_inner = '1') else fifo_rd_en(I);
  end generate GEN_TC_FIFO_VALS;

  tc_fifo_wr_en(3) <= ddu_data_valid when (tc_run_inner = '1') else fifo_wr_en(3);
  tc_fifo_wr_ck(3) <= dduclk         when (tc_run_inner = '1') else slowclk;
  tc_fifo_rd_en(3) <= fifo_rd_en(3);
  tc_fifo_rd_ck(3) <= slowclk;
  tc_fifo_in(3)    <= ddu_data       when (tc_run_inner = '1') else indata;

  GEN_TC_FIFO : for I in 3 downto 0 generate  -- (DDU_DATA,L1A/ALCT_DAV/OTMB_DAV/LCT,TSH,TSL)
  begin
    TC_FIFO : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE                  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6" 
        ALMOST_FULL_OFFSET      => X"0080",  -- Sets almost full threshold
        ALMOST_EMPTY_OFFSET     => X"0080",  -- Sets the almost empty threshold
        DATA_WIDTH              => 16,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
        FIFO_SIZE               => "36Kb",   -- Target BRAM, "18Kb" or "36Kb" 
        FIRST_WORD_FALL_THROUGH => tc_fifo_fwft(I))  -- Sets the FIFO FWFT to TRUE or FALSE
      port map (
        ALMOSTEMPTY => tc_fifo_aempty(I),    -- Output almost empty 
        ALMOSTFULL  => tc_fifo_afull(I),     -- Output almost full
        DO          => tc_fifo_out(I),  -- Output data
        EMPTY       => tc_fifo_empty(I),     -- Output empty
        FULL        => tc_fifo_full(I),      -- Output full
        RDCOUNT     => tc_fifo_rd_cnt(I),    -- Output read count
        RDERR       => open,            -- Output read error
        WRCOUNT     => tc_fifo_wr_cnt(I),    -- Output write count
        WRERR       => open,            -- Output write error
        DI          => tc_fifo_in(I),   -- Input data
        RDCLK       => tc_fifo_rd_ck(I),     -- Input read clock
        RDEN        => tc_fifo_rd_en(I),     -- Input read enable
        RST         => tc_fifo_rst,     -- Input reset
        WRCLK       => tc_fifo_wr_ck(I),     -- Input write clock
        WREN        => tc_fifo_wr_en(I)      -- Input write enable
        );
  end generate GEN_TC_FIFO;

  FIFO_WRC <= TC_FIFO_WR_CNT(0) when (FIFO_SEL = "0001") else
              TC_FIFO_WR_CNT(1) when (FIFO_SEL = "0010") else
              TC_FIFO_WR_CNT(2) when (FIFO_SEL = "0100") else
              TC_FIFO_WR_CNT(3) when (FIFO_SEL = "1000") else
              (others => '0');

  FIFO_RDC <= TC_FIFO_RD_CNT(0) when (FIFO_SEL = "0001") else
              TC_FIFO_RD_CNT(1) when (FIFO_SEL = "0010") else
              TC_FIFO_RD_CNT(2) when (FIFO_SEL = "0100") else
              TC_FIFO_RD_CNT(3) when (FIFO_SEL = "1000") else
              (others => '0');

  FIFO_DATA <= TC_FIFO_OUT(0) when (FIFO_SEL = "0001") else
               TC_FIFO_OUT(1) when (FIFO_SEL = "0010") else
               TC_FIFO_OUT(2) when (FIFO_SEL = "0100") else
               TC_FIFO_OUT(3) when (FIFO_SEL = "1000") else
               (others => '0');

  FIFO_STR(3 downto 0)   <= tc_fifo_full(0) & tc_fifo_afull(0) & tc_fifo_aempty(0) & tc_fifo_empty(0);
  FIFO_STR(7 downto 4)   <= tc_fifo_full(1) & tc_fifo_afull(1) & tc_fifo_aempty(1) & tc_fifo_empty(1);
  FIFO_STR(11 downto 8)  <= tc_fifo_full(2) & tc_fifo_afull(2) & tc_fifo_aempty(2) & tc_fifo_empty(2);
  FIFO_STR(15 downto 12) <= tc_fifo_full(3) & tc_fifo_afull(3) & tc_fifo_aempty(3) & tc_fifo_empty(3);


  --TS_FIFO_OUT    <= tc_fifo_out(1) & tc_fifo_out(0);
  TS_FIFO_OUT    <= x"0000" & tc_fifo_out(0);  -- mfs: For now, I'm tired of filling this one up
  EVENT_FIFO_OUT <= tc_fifo_out(2);

  TS_CNT : process (CLK, tc_run_inner, RST, ts_cnt_rst)
    variable TS_CNT_DATA : std_logic_vector(31 downto 0);
  begin
    if (RST = '1' or ts_cnt_rst = '1') then
      TS_CNT_DATA := (others => '0');
    elsif (tc_run_inner = '1') and (RISING_EDGE(CLK)) then
      TS_CNT_DATA := std_logic_vector(unsigned(TS_CNT_DATA) + 1);
    end if;

    TS_CNT_OUT <= TS_CNT_DATA;
    TS_OUT     <= TS_CNT_DATA;
  end process;

  TC_FIFO_CTRL : process (CLK, TS_FIFO_OUT, TS_CNT_OUT, EVENT_FIFO_OUT, tc_run_inner)
  begin
    if (tc_run_inner = '1') and (TS_CNT_OUT = TS_FIFO_OUT) then
      EVENT_RD <= '1';
    else
      EVENT_RD <= '0';
    end if;

    if (RISING_EDGE(CLK)) then
      if (tc_run_inner = '1') and (TS_CNT_OUT = TS_FIFO_OUT) then
        L1A_INNER      <= EVENT_FIFO_OUT(10);
        ALCT_DAV_INNER <= EVENT_FIFO_OUT(9);
        OTMB_DAV_INNER <= EVENT_FIFO_OUT(8);
        LCT_INNER      <= EVENT_FIFO_OUT(NFEB downto 0);
      else
        L1A_INNER      <= '0';
        ALCT_DAV_INNER <= '0';
        OTMB_DAV_INNER <= '0';
        LCT_INNER      <= (others => '0');
      end if;
    end if;
  end process;

  L1A      <= L1A_INNER;
  ALCT_DAV <= ALCT_DAV_INNER;
  OTMB_DAV <= OTMB_DAV_INNER;
  LCT      <= LCT_INNER;

  L1A_CNT : process (CLK, tc_run_inner, l1a_inner, trg_cnt_rst, rst)
    variable L1A_CNT_DATA : std_logic_vector(15 downto 0);
  begin
    if (RST = '1' or trg_cnt_rst = '1') then
      L1A_CNT_DATA := (others => '0');
    elsif (tc_run_inner = '1') and (l1a_inner = '1') and (RISING_EDGE(CLK)) then
      L1A_CNT_DATA := std_logic_vector(unsigned(L1A_CNT_DATA) + 1);
    end if;

    L1A_CNT_OUT <= L1A_CNT_DATA;
  end process;

  ALCT_DAV_CNT : process (CLK, tc_run_inner, alct_dav_inner, trg_cnt_rst, rst)
    variable ALCT_DAV_CNT_DATA : std_logic_vector(15 downto 0);
  begin

    if (RST = '1' or trg_cnt_rst = '1') then
      ALCT_DAV_CNT_DATA := (others => '0');
    elsif (tc_run_inner = '1') and (ALCT_DAV_INNER = '1') and (RISING_EDGE(CLK)) then
      ALCT_DAV_CNT_DATA := std_logic_vector(unsigned(ALCT_DAV_CNT_DATA) + 1);
    end if;

    ALCT_DAV_CNT_OUT <= ALCT_DAV_CNT_DATA;
  end process;

  OTMB_DAV_CNT : process (CLK, tc_run_inner, otmb_dav_inner, trg_cnt_rst, rst)
    variable OTMB_DAV_CNT_DATA : std_logic_vector(15 downto 0);
  begin
    if (RST = '1' or trg_cnt_rst = '1') then
      OTMB_DAV_CNT_DATA := (others => '0');
    elsif (tc_run_inner = '1') and (OTMB_DAV_INNER = '1') and (RISING_EDGE(CLK)) then
      OTMB_DAV_CNT_DATA := std_logic_vector(unsigned(OTMB_DAV_CNT_DATA) + 1);
    end if;

    OTMB_DAV_CNT_OUT <= OTMB_DAV_CNT_DATA;
  end process;

  GEN_LCT_CNT_OUT : for I in 0 to 7 generate
  begin
    LCT_CNT_OUT(I) <= (others => '0') when (RST = '1' or trg_cnt_rst = '1') else
                      std_logic_vector(unsigned(LCT_CNT_OUT(I)) + 1) when (tc_run_inner = '1') and (lct_inner(I) = '1') and (RISING_EDGE(CLK)) else
                      LCT_CNT_OUT(I);
  end generate GEN_LCT_CNT_OUT;


  TRG_CNT_DATA <= LCT_CNT_OUT(0) when (TRG_CNT_SEL = "0000") else
                  LCT_CNT_OUT(1)   when (TRG_CNT_SEL = "0001") else
                  LCT_CNT_OUT(2)   when (TRG_CNT_SEL = "0010") else
                  LCT_CNT_OUT(3)   when (TRG_CNT_SEL = "0011") else
                  LCT_CNT_OUT(4)   when (TRG_CNT_SEL = "0100") else
                  LCT_CNT_OUT(5)   when (TRG_CNT_SEL = "0101") else
                  LCT_CNT_OUT(6)   when (TRG_CNT_SEL = "0110") else
                  LCT_CNT_OUT(7)   when (TRG_CNT_SEL = "0111") else
                  L1A_CNT_OUT      when (TRG_CNT_SEL = "1000") else
                  ALCT_DAV_CNT_OUT when (TRG_CNT_SEL = "1001") else
                  OTMB_DAV_CNT_OUT when (TRG_CNT_SEL = "1010") else
                  (others => '0');

-- Chip ScopePro ILA core
  --csp_systemtest_la_pm : csp_systemtest_la
  --  port map (
  --    CONTROL => CSP_FREE_AGENT_PORT_LA_CTRL,
  --    CLK     => CLK,                   -- Good ol' 40MHz clock here
  --    DATA    => testctrl_la_data,
  --    TRIG0   => testctrl_la_trig
  --    );

  --testctrl_la_trig <= tc_run_inner & "0000000";
  --testctrl_la_data <= "000" & x"000"
  --                    & L1A_INNER & ALCT_DAV_INNER & OTMB_DAV_INNER & LCT_INNER(7 downto 1) -- [112:103]
  --                    & tc_fifo_wr_en(0) & tc_fifo_rd_en(0) & tc_fifo_empty(0) -- [102:100]
  --                    & tc_fifo_in(0) & tc_fifo_out(0) -- [99:68]
  --                    & tc_fifo_wr_en(2) & tc_fifo_rd_en(2) & tc_fifo_empty(2) -- [67:65]
  --                    & tc_fifo_in(2) & tc_fifo_out(2) -- [64:33]
  --                    & ts_cnt_out(15 downto 0)  -- [32:17]
  --                    & tc_run_inner & nrep_data;  -- [16:0]
end TESTCTRL_Arch;
