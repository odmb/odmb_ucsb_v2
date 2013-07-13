library ieee;
library work;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library hdlmacro; use hdlmacro.hdlmacro.all;

entity LVDBMON is
  
  port (

    SLOWCLK  : in  std_logic;
    RST      : in  std_logic;

    DEVICE   : in  std_logic;
    STROBE   : in  std_logic;
    COMMAND  : in  std_logic_vector(9 downto 0);
    WRITER   : in  std_logic;

    INDATA   : in  std_logic_vector(15 downto 0);
    OUTDATA  : out std_logic_vector(15 downto 0);

    DTACK    : out std_logic;

    LVADCEN  : out std_logic_vector(6 downto 0);
    ADCCLK   : out std_logic;
    ADCDATA  : out std_logic;
    ADCIN    : in  std_logic;

    LVTURNON : out std_logic_vector(8 downto 1);
    R_LVTURNON : in std_logic_vector(8 downto 1);
    LOADON   : out std_logic;

    DIAGLVDB : out std_logic_vector(17 downto 0)
    );
end LVDBMON;



architecture LVDBMON_Arch of LVDBMON is

  signal BUSY : std_logic;
  signal WRITEADC,READMON,WRITEPOWER,READPOWER,READPOWERSTATUS,SELADC,READADC : STD_LOGIC;
  signal SELADC_vector : std_logic_vector(3 downto 1);
  signal DTACK_INNER : std_logic;
  signal LVTURNON_INNER : std_logic_vector(8 downto 1);
  signal D_OUTDATA,Q_OUTDATA,D_OUTDATA_2,Q_OUTDATA_2,D_DTACK_2,Q_DTACK_2,D_DTACK_4,Q_DTACK_4 : std_logic;
  signal C_LOADON,Q1_LOADON,Q2_LOADON : std_logic;
  signal VCC : std_logic := '1';
  signal LOADON_INNER,ADCCLK_INNER : std_logic;
  signal CE_ADCCLK,CLR_ADCCLK : std_logic;
  signal RSTBUSY,CLKMON : std_logic;
  signal CE1_BUSY,CE2_BUSY,CLR_BUSY,Q1_BUSY,Q2_BUSY,D_BUSY,DONEMON,LOAD : std_logic;
  signal blank1,blank2 : std_logic;
  signal QTIME : std_logic_vector(7 downto 0);
  signal CLR1_LOAD,CLR2_LOAD,Q1_LOAD,Q2_LOAD,Q3_LOAD,Q4_LOAD,CE_LOAD,ASYNLOAD : std_logic;
  signal RDMONBK : std_logic;
  signal CE_OUTDATA_FULL : std_logic;
  signal Q_OUTDATA_FULL : std_logic_vector(15 downto 0);
  signal SLI_ADCDATA,L_ADCDATA,CE_ADCDATA : std_logic;
  signal Q_ADCDATA: std_logic_vector(7 downto 0);
  --signal D_ADCDATA: std_logic_vector(7 downto 0);
  signal CMDDEV : unsigned(12 downto 0);
  
begin  --Architecture

-- Decode instruction
  CMDDEV <= unsigned(DEVICE & COMMAND & "00");  -- Variable that looks like the VME commands we input
  
  WRITEADC        <= '1' when (CMDDEV = x"1000") else '0';
  READMON         <= '1' when (CMDDEV = x"1004") else '0';
  WRITEPOWER      <= '1' when (CMDDEV = x"1010") else '0';
  READPOWER       <= '1' when (CMDDEV = x"1014") else '0';
  READPOWERSTATUS <= '1' when (CMDDEV = x"1018") else '0';
  SELADC          <= '1' when (CMDDEV = x"1020") else '0';
  READADC         <= '1' when (CMDDEV = x"1024") else '0';

-- Generate OUTDATA
  FDCE_GEN: for i in 0 to 2 generate
  begin
  	FDCE_OUT : FDCE port map (SELADC_vector(i+1),STROBE,SELADC,RST,INDATA(i));
  end generate FDCE_GEN;	
  
  OUTDATA <= '0' & x"000" & SELADC_vector(3 downto 1) when (STROBE='1' and READADC='1') else (others => 'Z');

  D_OUTDATA <= '1' when (STROBE='1' and READADC='1') else '0';
  FD_OUTDATA : FD port map (Q_OUTDATA,SLOWCLK,D_OUTDATA);
  DTACK_INNER <= '0' when (Q_OUTDATA='1') else 'Z';

-- Generate DTACK_2
  D_DTACK_2 <= SELADC and STROBE;
  FD_DTACK_2 : FD port map (Q_DTACK_2,SLOWCLK,D_DTACK_2);
  DTACK_INNER <= '0' when (Q_DTACK_2='1') else 'Z';

-- Generate OUTDATA_2
  FDCE_GEN2: for i in 0 to 7 generate
  begin
  	FDCE_OUT2 : FDCE port map (LVTURNON_INNER(i+1),STROBE,WRITEPOWER,RST,INDATA(i));
  end generate FDCE_GEN2;

  OUTDATA <= x"00" & LVTURNON_INNER(8 downto 1) when (STROBE='1' and READPOWER='1') else
                          x"00" & R_LVTURNON(8 downto 1) when (STROBE='1' and READPOWERSTATUS='1') else
                         (others => 'Z');
  D_OUTDATA_2 <= '1' when (STROBE='1' and READPOWER='1') else
                 '1' when (STROBE='1' and READPOWERSTATUS='1') else
                 '0';

  FD_OUTDATA_2 : FD port map (Q_OUTDATA_2,SLOWCLK,D_OUTDATA_2);
  DTACK_INNER <= '0' when (Q_OUTDATA_2='1') else 'Z';
  
-- Generate DTACK_4
  D_DTACK_4 <= '1' when (WRITEPOWER='1' and STROBE='1') else '0';
  FD_DTACK_4 : FD port map (Q_DTACK_4,SLOWCLK,D_DTACK_4);
  DTACK_INNER <= '0' when (Q_DTACK_4='1') else 'Z';

-- Generate RDMONBK
  RDMONBK <= '1' when (READMON='1' and STROBE='1' and BUSY='0') else '0';
  DTACK_INNER <= '0' when (RDMONBK='1') else 'Z';

-- Generate LVADCEN
  LVADCEN(0) <= '0' when SELADC_vector(3 downto 1)="000" else '1';
  LVADCEN(1) <= '0' when SELADC_vector(3 downto 1)="001" else '1';
  LVADCEN(2) <= '0' when SELADC_vector(3 downto 1)="010" else '1';
  LVADCEN(3) <= '0' when SELADC_vector(3 downto 1)="011" else '1';
  LVADCEN(4) <= '0' when SELADC_vector(3 downto 1)="100" else '1';
  LVADCEN(5) <= '0' when SELADC_vector(3 downto 1)="101" else '1';
  LVADCEN(6) <= '0' when SELADC_vector(3 downto 1)="110" else '1';

-- Generate LOADON
  C_LOADON <= '1' when (WRITEPOWER='1' and STROBE='1') else '0';
  FDC_LOADON : FDC port map (Q1_LOADON,C_LOADON,LOADON_INNER,VCC);
  FD_LOADON1 : FD port map (Q2_LOADON,SLOWCLK,Q1_LOADON);
  FD_LOADON2 : FD port map (LOADON_INNER,SLOWCLK,Q2_LOADON);

-- Generate OUTDATA
  CE_OUTDATA_FULL <= '1' when (BUSY='1' and RSTBUSY='0' and CLKMON='0') else '0';
  SR16CE_OUTDATA : SR16CE port map (Q_OUTDATA_FULL,SLOWCLK,CE_OUTDATA_FULL,RST,ADCIN);
  OUTDATA(15 downto 0) <= Q_OUTDATA_FULL(15 downto 0) when (RDMONBK='1') else
                          (others => 'Z');
  SLI_ADCDATA <= 'L';
  

-- Generate ADCDATA
  L_ADCDATA <= '1' when (LOAD='1' and CLKMON='0') else '0';
  CE_ADCDATA <= '1' when (BUSY='1' and CLKMON='0') else '0';
  SR8CLE_ADCDATA : SR8CLE port map (Q_ADCDATA,SLOWCLK,CE_ADCDATA,RST,INDATA(7 downto 0),L_ADCDATA,SLI_ADCDATA);
  ADCDATA <= Q_ADCDATA(7);

-- Generate ADCCLK
  CE_ADCCLK <= '1' when (BUSY='1' and RSTBUSY='0') else '0';
  CLR_ADCCLK <= '1' when (BUSY='0' or RST='1') else '0';
  FDCE_ADCCLK : FDCE port map (CLKMON,SLOWCLK,CE_ADCCLK,CLR_ADCCLK,ADCCLK_INNER);     
  ADCCLK_INNER <= not CLKMON;

-- Generate BUSY
  CE1_BUSY <= '1' when (BUSY='1' and CLKMON='0') else '0';
  CLR_BUSY <= Q2_BUSY or RST;
  CB8CE_BUSY : CB8CE port map (blank1,QTIME,blank2,SLOWCLK,CE1_BUSY,CLR_BUSY);
  DONEMON <= '1' when (QTIME(4)='1' and QTIME(3)='1' and QTIME(1)='1') else '0';
  CE2_BUSY <= BUSY and CLKMON;
  FDCE_BUSY : FDCE port map (Q1_BUSY,SLOWCLK,CE2_BUSY,CLR_BUSY,DONEMON);
  FD_BUSY : FD port map(Q2_BUSY,SLOWCLK,Q1_BUSY);
  RSTBUSY <= RST or Q1_BUSY;
  D_BUSY <= LOAD or BUSY;
  FDR_BUSY : FDR port map (BUSY,SLOWCLK,D_BUSY,RSTBUSY);

-- Generate LOAD
  ASYNLOAD <= '1' when (STROBE='1' and WRITEADC='1' and BUSY='0') else '0';
  CLR1_LOAD <= RST or Q2_LOAD;
  FDC_VCC : FDC port map (Q1_LOAD,ASYNLOAD,CLR1_LOAD,VCC);
  FDC_LOAD1 : FDC port map (LOAD,SLOWCLK,RST,Q1_LOAD);
  CE_LOAD <= '1' when (BUSY='1' and CLKMON='0') else '0';
  FDCE_LOAD2 : FDCE port map (Q2_LOAD,SLOWCLK,CE_LOAD,RST,LOAD);
  FDC_LOAD3 : FDC port map (Q3_LOAD,SLOWCLK,RST,Q2_LOAD);

  CLR2_LOAD <= '1' when (RST='1' or WRITEADC='0' or BUSY='0') else '0';
  FDC_LOAD4 : FDC port map (Q4_LOAD,Q3_LOAD,CLR2_LOAD,VCC);
  DTACK_INNER <= '0' when (Q4_LOAD='1') else 'Z';

-- Generate LOADON / Generate DTACK / Generate LVTURNON / Generate ADCLK
  LOADON <= LOADON_INNER;
  DTACK <= DTACK_INNER;
  LVTURNON <= LVTURNON_INNER;
  ADCCLK <= ADCCLK_INNER;

-- Generate DIAGLVDB
  DIAGLVDB(17 downto 0) <= x"000" & L_ADCDATA & BUSY & ADCCLK_INNER & CLKMON & CE_ADCDATA & SLOWCLK;
  
end LVDBMON_Arch;
