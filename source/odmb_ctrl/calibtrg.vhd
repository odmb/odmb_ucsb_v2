library IEEE;
library work;
use work.Latches_Flipflops.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;

entity CALIBTRG is
  port (
    CMSCLK      : in  std_logic;
    CLK80       : in  std_logic;
    RST         : in  std_logic;
    PLSINJEN    : in  std_logic;
    CCBPLS      : in  std_logic;
    CCBINJ      : in  std_logic;
    FPLS        : in  std_logic;
    FINJ        : in  std_logic;
    FPED        : in  std_logic;
    PRELCT      : in  std_logic;
    PREGTRG     : in  std_logic;
    INJ_DLY     : in  std_logic_vector(4 downto 0);
    EXT_DLY     : in  std_logic_vector(4 downto 0);
    CALLCT_DLY  : in  std_logic_vector(3 downto 0);
    LCT_L1A_DLY : in  std_logic_vector(5 downto 0);
    RNDMPLS     : in  std_logic;
    RNDMGTRG    : in  std_logic;
    PEDESTAL    : out std_logic;
    CAL_GTRG    : out std_logic;
    CALLCT      : out std_logic;
    INJBACK     : out std_logic;
    PLSBACK     : out std_logic;
-- SCPSYN AND SCOPE have not been implemented
-- and we do not intend to implement them (we think)
--    SCPSYN : out std_logic; 
--    SYNCIF : out std_logic;
    LCTRQST     : out std_logic;
    INJPLS      : out std_logic
    );
end CALIBTRG;

architecture CALIBTRG_arch of CALIBTRG is
  component LCTDLY is  -- Aligns RAW_LCT with L1A by 2.4 us to 4.8 us
    port (
      DIN   : in std_logic;
      CLK   : in std_logic;
      DELAY : in std_logic_vector(5 downto 0);

      DOUT : out std_logic
      );
  end component;

  signal BC0_CMD, BC0_RST, BC0_INNER                     : std_logic;
  signal START_TRG_CMD, START_TRG_RST, START_TRG_INNER   : std_logic;
  signal STOP_TRG_CMD, STOP_TRG_RST, STOP_TRG_INNER      : std_logic;
  signal L1ASRST_CMD, L1ASRST_RST, L1ASRST_CLK_CMD       : std_logic;
  signal L1ASRST_CNT_RST, L1ASRST_CNT_CEO, L1ASRST_INNER : std_logic;
  signal L1ASRST_CNT                                     : std_logic_vector(15 downto 0);
  signal TTCCAL_CMD, TTCCAL_RST, TTCCAL_INNER            : std_logic_vector(2 downto 0);
  signal CCBINJIN_1, CCBINJIN_2, CCBINJIN_3              : std_logic;
  signal CCBPLSIN_1, CCBPLSIN_2, CCBPLSIN_3              : std_logic;
  signal PLSINJEN_1, PLSINJEN_RST, PLSINJEN_INV          : std_logic;
  signal BX0_1                                           : std_logic;
  signal BXRST_1                                         : std_logic;
  signal CLKEN_1                                         : std_logic;
  signal L1ARST_1                                        : std_logic;

  signal LOGICH  : std_logic                    := '1';
  signal LOGICH4 : std_logic_vector(3 downto 0) := "1111";
  signal LOGIC5  : std_logic_vector(3 downto 0) := "0101";

  signal FINJ_INV, PREINJ_1, PREINJ                                       : std_logic;
  signal FPLS_INV, PREPLS_1, PREPLS                                       : std_logic;
  signal INJ_CMD, INJ_1, INJ_2, INJ_3, INJ_4, INJ_5_A, INJ_5_B, INJ_INNER : std_logic;
  signal INJ_CNT                                                          : std_logic_vector(15 downto 0);
  signal PLS_CMD, PLS_1, PLS_2, PLS_3, PLS_4, PLS_5_A, PLS_5_B, PLS_INNER : std_logic;
  signal PLS_CNT                                                          : std_logic_vector(15 downto 0);
  signal PEDESTAL_INV                                                     : std_logic;
  signal RSTPLS_CMD, RSTPLS, RSTPLS_CNT_CEO, RSTPLS_CNT_TC, RSTPLS_1      : std_logic;
  signal RSTPLS_CNT                                                       : std_logic_vector(7 downto 0);
  signal INJPLS_CMD, INJPLS_RST, INJPLS_1, INJPLS_INNER                   : std_logic;
  signal CAL_GTRG_CMD, CAL_GTRG_1                                         : std_logic;
  --signal SR1_OUT, SR2_OUT, SR3_OUT, SR4_OUT, SR5_OUT, SR6_OUT                         : std_logic;
  --signal SR7_OUT, SR8_OUT, SR9_OUT, SR10_OUT, SR11_OUT, SR12_OUT, SR13_OUT            : std_logic;
  --signal SR1_CNT, SR2_CNT, SR3_CNT, SR4_CNT, SR5_CNT, SR6_CNT, SR7_CNT                : std_logic_vector(15 downto 0);
  --signal SR8_CNT, SR9_CNT, SR10_CNT, SR11_CNT, SR12_CNT, SR13_CNT : std_logic_vector(15 downto 0);
  signal SR14_CNT, SR15_CNT                                               : std_logic_vector(15 downto 0);
  signal M4_OUT, M4_OUT_CLK, M2_OUT, M2_OUT_CLK                           : std_logic;
  signal LCTRQST_INNER, CALLCT_1, CALLCT_2, CALLCT_3, CALLCT_INNER        : std_logic;
  signal PEDESTAL_INNER                                                   : std_logic;
  signal XL1ADLY_INNER                                                    : std_logic_vector(1 downto 0);
begin

  -- generate PREINJ (FINJ=INSTR3)
  FINJ_INV <= not FINJ;
  FDCE(FINJ, CMSCLK, PLSINJEN, FINJ_INV, PREINJ_1);
  FDC(PREINJ_1, CMSCLK, RST, PREINJ);

  -- generate PREPLS
  FPLS_INV <= not FPLS;
  FDCE(FPLS, CMSCLK, PLSINJEN, FPLS_INV, PREPLS_1);
  FDC(PREPLS_1, CMSCLK, RST, PREPLS);

  -- generate INJ
  INJ_CMD <= PREINJ or CCBINJ; -- Guido May 17
--  INJ_CMD   <= CCBINJ;
  FDC(LOGICH, INJ_CMD, RSTPLS, INJ_1);
  FDC(INJ_1, CMSCLK, PEDESTAL_INNER, INJ_2);
  SRL16(INJ_2, CLK80, INJ_DLY(4 downto 1), INJ_CNT, INJ_CNT, INJ_3);
  FD(INJ_3, CLK80, INJ_4);
  FD(INJ_4, CLK80, INJ_5_A);
  FD_1(INJ_4, CLK80, INJ_5_B);
--  BUFE(INJ_5_A, INJ_DLY(0), INJ_INNER); -- Modelsim Compile Problem
  INJ_INNER <= INJ_5_A when INJ_DLY(0) = '1' else 'Z';
--  BUFT(INJ_5_B, INJ_DLY(0), INJ_INNER); -- Modelsim Compile Problem
  INJ_INNER <= INJ_5_B when INJ_DLY(0) = '0' else 'Z';
  INJBACK   <= INJ_INNER;


  -- generate PLS
  PLS_CMD <= PREPLS or CCBPLS or PRELCT; -- Guido May 17
--  PLS_CMD   <= CCBPLS;
  FDC(LOGICH, PLS_CMD, RSTPLS, PLS_1);
  FDC(PLS_1, CMSCLK, PEDESTAL_INNER, PLS_2);
  SRL16(PLS_2, CLK80, EXT_DLY(4 downto 1), PLS_CNT, PLS_CNT, PLS_3);
  FD(PLS_3, CLK80, PLS_4);
  FD(PLS_4, CLK80, PLS_5_A);
  FD_1(PLS_4, CLK80, PLS_5_B);
--  BUFE(PLS_5_A, EXT_DLY(0), PLS_INNER); -- Modelsim Compile Problem
  PLS_INNER <= PLS_5_A when EXT_DLY(0) = '1' else 'Z';
--  BUFT(PLS_5_B, EXT_DLY(0), PLS_INNER); -- Modelsim Compile Problem
  PLS_INNER <= PLS_5_B when EXT_DLY(0) = '0' else 'Z';
  PLSBACK   <= PLS_INNER;

  -- generate PEDESTAL (FPED=INSTR5)
--  PEDESTAL_INV <= not PEDESTAL_INNER;
--  FDC(PEDESTAL_INV, FPED, RST, PEDESTAL_INNER);
  PEDESTAL_INNER     <= FPED;
  PEDESTAL     <= PEDESTAL_INNER;

  -- generate RSTPLS
  RSTPLS_CMD <= PLS_INNER or INJ_INNER;
  CB8CE(CMSCLK, RSTPLS_CMD, RSTPLS, RSTPLS_CNT, RSTPLS_CNT, RSTPLS_CNT_CEO, RSTPLS_CNT_TC);
  FD(RSTPLS_CNT(6), CMSCLK, RSTPLS_1);
  RSTPLS     <= RSTPLS_1 or RST;

  -- generate INJPLS
  INJPLS_CMD <= CCBINJ or CCBPLS;
  FDC(LOGICH, INJPLS_CMD, INJPLS_RST, INJPLS_1);
  FDR(INJPLS_1, CMSCLK, INJPLS_RST, INJPLS_INNER);
  INJPLS_RST <= INJPLS_INNER or RST;
  INJPLS     <= INJPLS_INNER;

  -- generate CAL_GTRG
-- PREGTRG from CALTRIGCON - still to be implemented
--  CAL_GTRG_CMD <= INJPLS_INNER or PREGTRG; 
--  CAL_GTRG_CMD <= INJPLS_INNER;
--  SRL16(CAL_GTRG_CMD, CMSCLK, LOGICH4, SR1_CNT, SR1_CNT, SR1_OUT);
--  SRL16(SR1_OUT, CMSCLK, LOGICH4, SR2_CNT, SR2_CNT, SR2_OUT);
--  SRL16(SR2_OUT, CMSCLK, LOGICH4, SR3_CNT, SR3_CNT, SR3_OUT);
--  SRL16(SR3_OUT, CMSCLK, LOGICH4, SR4_CNT, SR4_CNT, SR4_OUT);
--  SRL16(SR4_OUT, CMSCLK, LOGICH4, SR5_CNT, SR5_CNT, SR5_OUT);
--  M4_OUT       <= SR2_OUT when XL1ADLY = "00" else
--                  SR3_OUT when XL1ADLY = "01" else
--                  SR4_OUT when XL1ADLY = "10" else
--                  SR5_OUT when XL1ADLY = "11";
--  FD(M4_OUT, CMSCLK, M4_OUT_CLK);
--  SRL16(M4_OUT_CLK, CMSCLK, LOGICH4, SR6_CNT, SR6_CNT, SR6_OUT);  -- SR6_OUT = L1CON1
--  SRL16(SR6_OUT, CMSCLK, LOGICH4, SR7_CNT, SR7_CNT, SR7_OUT);
--  SRL16(SR7_OUT, CMSCLK, LOGICH4, SR8_CNT, SR8_CNT, SR8_OUT);
--  SRL16(SR8_OUT, CMSCLK, LOGICH4, SR9_CNT, SR9_CNT, SR9_OUT);
--  SRL16(SR9_OUT, CMSCLK, LOGICH4, SR10_CNT, SR10_CNT, SR10_OUT);
--  SRL16(SR10_OUT, CMSCLK, LOGIC5, SR11_CNT, SR11_CNT, SR11_OUT);  -- SR11_OUT = NO4DLY
--  SRL16(SR11_OUT, CMSCLK, LOGICH4, SR12_CNT, SR12_CNT, SR12_OUT);
--  M2_OUT <= SR11_OUT when CALGDLY(4) = '0' else
--            SR12_OUT when CALGDLY(4) = '1';
--  FD(M2_OUT, CMSCLK, M2_OUT_CLK);       -- M2_OUT_CLK = L1CON2
--  SRL16(M2_OUT_CLK, CMSCLK, CALGDLY(3 downto 0), SR13_CNT, SR13_CNT, SR13_OUT);
----  CAL_GTRG_1 <= SR13_OUT or RNDMGTRG; 
--  CAL_GTRG_1 <= SR13_OUT;               -- Guido May 17
--  FD(CAL_GTRG_1, CMSCLK, CAL_GTRG);

  -- generate CALLCT, LCTRQST
-- PRELCT from CALTRIGCON - still to be implemented
--  LCTRQST_INNER <= INJPLS_INNER or PRELCT;
  LCTRQST_INNER <= INJPLS_INNER;
  LCTRQST       <= LCTRQST_INNER;
  SRL16(LCTRQST_INNER, CMSCLK, LOGICH4, SR14_CNT, SR14_CNT, CALLCT_1);
  FD(CALLCT_1, CMSCLK, CALLCT_2);
  SRL16(CALLCT_2, CMSCLK, CALLCT_DLY, SR15_CNT, SR15_CNT, CALLCT_3);
  FD(CALLCT_3, CMSCLK, CALLCT_INNER);
  CALLCT        <= CALLCT_INNER;

  -- Generate CAL_GTRG
  LCTDLY_GTRG : LCTDLY port map(CALLCT_INNER, CMSCLK, LCT_L1A_DLY, CAL_GTRG);

end CALIBTRG_arch;
