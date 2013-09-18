-- SYSTEM_TEST: Provides utilities for testing components of ODMB

library ieee;
library unisim;
use ieee.std_logic_1164.all;
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
    RST     : in std_logic;

    OUTDATA : out std_logic_vector(15 downto 0);
    DTACK   : out std_logic;

    -- DDU PRBS signals
    DDU_PRBS_EN          : out std_logic;
    DDU_PRBS_TST_CNT     : out std_logic_vector(15 downto 0);
    DDU_PRBS_ERR_CNT_RST : out std_logic;
    DDU_PRBS_RD_EN       : out std_logic;
    DDU_PRBS_ERR_CNT     : in  std_logic_vector(15 downto 0);
    DDU_PRBS_DRDY        : in  std_logic
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

  signal cmddev                                : std_logic_vector (15 downto 0);
  signal w_ddu_prbs_en, w_ddu_prbs_err_cnt_rst : std_logic;
  signal r_ddu_prbs_err_cnt                    : std_logic;
  signal out_ddu_err_cnt                       : std_logic_vector(15 downto 0);
  signal strobe_pulse, drdy_pulse              : std_logic;
  signal dtack_inner                           : std_logic;

begin
  cmddev        <= "000" & DEVICE & COMMAND & "00";
  w_ddu_prbs_en <= '1' when (cmddev = x"1000" and STROBE = '1' and WRITER = '0')
                   else '0';
  w_ddu_prbs_err_cnt_rst <= '1' when (cmddev = x"1004" and STROBE = '1' and WRITER = '0')
                            else '0';
  r_ddu_prbs_err_cnt <= '1' when (cmddev = x"100C" and STROBE = '1' and WRITER = '1')
                        else '0';

  STROBE_PE : PULSE_EDGE port map(strobe_pulse, open, SLOWCLK, RST, 1, STROBE);
  DRDY_PE   : PULSE_EDGE port map(drdy_pulse, open, SLOWCLK, RST, 1, DDU_PRBS_DRDY);

  DDU_PRBS_EN          <= w_ddu_prbs_en;
  DDU_PRBS_ERR_CNT_RST <= '1' when (w_ddu_prbs_err_cnt_rst = '1' or RST = '1')       else '0';
  DDU_PRBS_RD_EN       <= '1' when (r_ddu_prbs_err_cnt = '1' and strobe_pulse = '1') else '0';

  GEN_DDU_PRBS : for i in 15 downto 0 generate
  begin
    FDC_DDU_PRBS    : FDC port map(DDU_PRBS_TST_CNT(i), w_ddu_prbs_en, RST, INDATA(i));
    FDC_DDU_ERR_CNT : FDC port map(out_ddu_err_cnt(i), DDU_PRBS_DRDY, RST, DDU_PRBS_ERR_CNT(i));
  end generate GEN_DDU_PRBS;

  OUTDATA <= out_ddu_err_cnt when (r_ddu_prbs_err_cnt = '1') else
             (others => 'L');

  dtack_inner <= '0' when (w_ddu_prbs_en = '1' and strobe_pulse = '1')          else 'Z';
  dtack_inner <= '0' when (w_ddu_prbs_err_cnt_rst = '1' and strobe_pulse = '1') else 'Z';
  dtack_inner <= '0' when (r_ddu_prbs_err_cnt = '1' and drdy_pulse = '1')       else 'Z';
  DTACK       <= dtack_inner;
end SYSTEM_TEST_Arch;
