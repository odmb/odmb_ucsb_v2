library ieee;
library work;
use work.Latches_Flipflops.all;
use ieee.std_logic_1164.all;

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

  signal CMDHIGH : std_logic;
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
  signal D_ADCDATA,Q_ADCDATA : std_logic_vector(7 downto 0);
  signal CMDDEV : std_logic_vector(4 downto 0);
  
begin  --Architecture

-- Decode instruction
  CMDHIGH <= '1' when (COMMAND(9) = '0' and COMMAND(8) = '0' and COMMAND(7) = '0' and COMMAND(6) = '0'
                       and COMMAND(5) = '0' and COMMAND(4) = '0' and DEVICE = '1') else '0';
  CMDDEV <= CMDHIGH & COMMAND(3) & COMMAND(2) & COMMAND(1) & COMMAND(0);

  WRITEADC        <= '1' when (CMDDEV = "10000") else '0';
  READMON         <= '1' when (CMDDEV = "10001") else '0';
  WRITEPOWER      <= '1' when (CMDDEV = "10100") else '0';
  READPOWER       <= '1' when (CMDDEV = "10101") else '0';
  READPOWERSTATUS <= '1' when (CMDDEV = "10110") else '0';
  SELADC          <= '1' when (CMDDEV = "11000") else '0';
  READADC         <= '1' when (CMDDEV = "11001") else '0';

-- Generate OUTDATA
  FDCE(INDATA(0),STROBE,SELADC,RST,SELADC_vector(1));
  FDCE(INDATA(1),STROBE,SELADC,RST,SELADC_vector(2));
  FDCE(INDATA(2),STROBE,SELADC,RST,SELADC_vector(3));
  OUTDATA(2 downto 0) <= SELADC_vector(3 downto 1) when (STROBE='1' and READADC='1') else "ZZZ";
  D_OUTDATA <= '1' when (STROBE='1' and READADC='1') else '0';
  FD(D_OUTDATA,SLOWCLK,Q_OUTDATA);
  DTACK_INNER <= '0' when (Q_OUTDATA='1') else 'Z';

-- Generate DTACK_2
  D_DTACK_2 <= SELADC and STROBE;
  FD(D_DTACK_2,SLOWCLK,Q_DTACK_2);
  DTACK_INNER <= '0' when (Q_DTACK_2='1') else 'Z';

-- Generate OUTDATA_2
  FDCE(INDATA(0),STROBE,WRITEPOWER,RST,LVTURNON_INNER(1));
  FDCE(INDATA(1),STROBE,WRITEPOWER,RST,LVTURNON_INNER(2));
  FDCE(INDATA(2),STROBE,WRITEPOWER,RST,LVTURNON_INNER(3));
  FDCE(INDATA(3),STROBE,WRITEPOWER,RST,LVTURNON_INNER(4));
  FDCE(INDATA(4),STROBE,WRITEPOWER,RST,LVTURNON_INNER(5));
  FDCE(INDATA(5),STROBE,WRITEPOWER,RST,LVTURNON_INNER(6));
  FDCE(INDATA(6),STROBE,WRITEPOWER,RST,LVTURNON_INNER(7));
  FDCE(INDATA(7),STROBE,WRITEPOWER,RST,LVTURNON_INNER(8));

  OUTDATA(7 downto 0) <= LVTURNON_INNER(8 downto 1) when (STROBE='1' and READPOWER='1') else
                         R_LVTURNON(8 downto 1) when (STROBE='1' and READPOWERSTATUS='1') else
                         "ZZZZZZZZ";
  D_OUTDATA_2 <= '1' when (STROBE='1' and READPOWER='1') else
                 '1' when (STROBE='1' and READPOWERSTATUS='1') else
                 '0';

  FD(D_OUTDATA_2,SLOWCLK,Q_OUTDATA_2);
  DTACK_INNER <= '0' when (Q_OUTDATA_2='1') else 'Z';
  
-- Generate DTACK_4
  D_DTACK_4 <= '1' when (WRITEPOWER='1' and STROBE='1') else '0';
  FD(D_DTACK_4,SLOWCLK,Q_DTACK_4);
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
  FDC(VCC,C_LOADON,LOADON_INNER,Q1_LOADON);
  FD(Q1_LOADON,SLOWCLK,Q2_LOADON);
  FD(Q2_LOADON,SLOWCLK,LOADON_INNER);

-- Generate OUTDATA
  CE_OUTDATA_FULL <= '1' when (BUSY='1' and RSTBUSY='0' and CLKMON='0') else '0';
  SR16CE(SLOWCLK,CE_OUTDATA_FULL,RST,ADCIN,Q_OUTDATA_FULL,Q_OUTDATA_FULL);
  OUTDATA(15 downto 0) <= Q_OUTDATA_FULL(15 downto 0) when (RDMONBK='1') else
                          "ZZZZZZZZZZZZZZZZ";
  SLI_ADCDATA <= 'L';
  

-- Generate ADCDATA
  L_ADCDATA <= '1' when (LOAD='1' and CLKMON='0') else '0';
  CE_ADCDATA <= '1' when (BUSY='1' and CLKMON='0') else '0';
  SR8CLE(SLOWCLK,CE_ADCDATA,RST,L_ADCDATA,SLI_ADCDATA,INDATA(7 downto 0),Q_ADCDATA,Q_ADCDATA);
  ADCDATA <= Q_ADCDATA(7);

-- Generate ADCCLK
  CE_ADCCLK <= '1' when (BUSY='1' and RSTBUSY='0') else '0';
  CLR_ADCCLK <= '1' when (BUSY='0' or RST='1') else '0';
  FDCE(ADCCLK_INNER,SLOWCLK,CE_ADCCLK,CLR_ADCCLK,CLKMON);     
  ADCCLK_INNER <= not CLKMON;

-- Generate BUSY
  CE1_BUSY <= '1' when (BUSY='1' and CLKMON='0') else '0';
  CLR_BUSY <= Q2_BUSY or RST;
  CB8CE(SLOWCLK,CE1_BUSY,CLR_BUSY,QTIME,QTIME,blank1,blank2);
  DONEMON <= '1' when (QTIME(4)='1' and QTIME(3)='1' and QTIME(1)='1') else '0';
  CE2_BUSY <= BUSY and CLKMON;
  FDCE(DONEMON,SLOWCLK,CE2_BUSY,CLR_BUSY,Q1_BUSY);
  FD(Q1_BUSY,SLOWCLK,Q2_BUSY);
  RSTBUSY <= RST or Q1_BUSY;
  D_BUSY <= LOAD or BUSY;
  FDR(D_BUSY,SLOWCLK,RSTBUSY,BUSY);

-- Generate LOAD
  ASYNLOAD <= '1' when (STROBE='1' and WRITEADC='1' and BUSY='0') else '0';
  CLR1_LOAD <= RST or Q2_LOAD;
  FDC(VCC,ASYNLOAD,CLR1_LOAD,Q1_LOAD);
  FDC(Q1_LOAD,SLOWCLK,RST,LOAD);
  CE_LOAD <= '1' when (BUSY='1' and CLKMON='0') else '0';
  FDCE(LOAD,SLOWCLK,CE_LOAD,RST,Q2_LOAD);
  FDC(Q2_LOAD,SLOWCLK,RST,Q3_LOAD);

-- Guido: to bring DTACK high after the end of the ADC acquisition (otherwise we need to wait for another code)
--    if (RST='1' or WRITEADC='0') then
  CLR2_LOAD <= '1' when (RST='1' or WRITEADC='0' or BUSY='0') else '0';
  FDC(VCC,Q3_LOAD,CLR2_LOAD,Q4_LOAD);
  DTACK_INNER <= '0' when (Q4_LOAD='1') else 'Z';

-- Generate LOADON / Generate DTACK / Generate LVTURNON / Generate ADCLK
  LOADON <= LOADON_INNER;
  DTACK <= DTACK_INNER;
  LVTURNON <= LVTURNON_INNER;
  ADCCLK <= ADCCLK_INNER;

-- Generate DIAGLVDB
  DIAGLVDB(0) <= SLOWCLK;
  DIAGLVDB(1) <= CE_ADCDATA;
  DIAGLVDB(2) <= CLKMON;
  DIAGLVDB(3) <= ADCCLK_INNER;
  DIAGLVDB(4) <= BUSY;
  DIAGLVDB(5) <= L_ADCDATA;
  DIAGLVDB(17 downto 6) <= "000000000000";   
  
end LVDBMON_Arch;
