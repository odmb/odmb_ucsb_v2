library ieee;
library work;
use work.Latches_Flipflops.all;
use ieee.std_logic_1164.all;

entity FIFOMON is
  
  port (
    SLOWCLK : in std_logic;
    RST : in std_logic;

    DEVICE : in std_logic;
    STROBE : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);
 
    INDATA : in std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);
    
    DTACK : out std_logic;
 
    FIFO_WR_EN : out std_logic_vector(7 downto 0);
    FIFO_RD_EN : out std_logic_vector(7 downto 0);
    FIFO_MODE : out std_logic;
    FIFO_SEL : out std_logic_vector(7 downto 0);
    FIFO_DATA : in std_logic_vector(15 downto 0);
    FIFO_STR :  in std_logic_vector(15 downto 0);
    FIFO_WRC :  in std_logic_vector(9 downto 0);
    FIFO_RDC :  in std_logic_vector(9 downto 0)
    
    );
    
end FIFOMON;

architecture FIFOMON_Arch of FIFOMON is

  --Declaring internal signals
  signal CMDHIGH, WRITE_FIFO, READ_FIFO, WRITE_FSR, READ_FSR, READ_STR, READ_WRC, READ_RDC : std_logic;
  signal FSR_vector : std_logic_vector(8 downto 0);
  signal E_DTACK,D_DTACK : std_logic;
  signal D_DTACK_WRITE_FSR,E_DTACK_WRITE_FSR : std_logic;
  signal D_DTACK_READ_FSR,E_DTACK_READ_FSR : std_logic;
  signal D_DTACK_WRITE_STR,E_DTACK_WRITE_STR : std_logic;
  signal D_DTACK_READ_STR,E_DTACK_READ_STR : std_logic;
  signal D_DTACK_WRITE_WRC,E_DTACK_WRITE_WRC : std_logic;
  signal D_DTACK_READ_WRC,E_DTACK_READ_WRC : std_logic;
  signal D_DTACK_WRITE_RDC,E_DTACK_WRITE_RDC : std_logic;
  signal D_DTACK_READ_RDC,E_DTACK_READ_RDC : std_logic;
  signal D_DTACK_READ_FIFO,E1_DTACK_READ_FIFO,E2_DTACK_READ_FIFO,E_DTACK_READ_FIFO : std_logic;
  signal D_DTACK_WRITE_FIFO,E1_DTACK_WRITE_FIFO,E2_DTACK_WRITE_FIFO,E_DTACK_WRITE_FIFO : std_logic;
  signal D_DTACK_FR,E_DTACK_FR : std_logic;
  signal E_READ_FIFO : std_logic;
  signal I1_FIFO_RD_EN, I2_FIFO_RD_EN, I3_FIFO_RD_EN, C_FIFO_RD_EN, FIFO_RD : std_logic_vector(7 downto 0);
  signal I1_FIFO_WR_EN, I2_FIFO_WR_EN, I3_FIFO_WR_EN, C_FIFO_WR_EN, FIFO_WR : std_logic_vector(7 downto 0);

  signal I1_INDATA, I2_INDATA, FIFO_WR_DATA : std_logic_vector(15 downto 0);
-----------

begin  --Architecture

  --All processes will be called CREATE_{name of signal they create}
  --If a process creates more than one signal, one name will be used and then
  --the other possible names will be in the comments
  --This is so the reader can use ctrl+f functions to find relevant processes

  CREATE_DECODE: process (DEVICE,COMMAND,CMDHIGH)     
  begin
    if (COMMAND(9 downto 4)="000000" and DEVICE='1') then
      CMDHIGH <= '1';
    else
      CMDHIGH <= '0';
    end if;

    if (COMMAND(0)='0' and COMMAND(1)='0' and COMMAND(2)='0' and COMMAND(3)='1' and CMDHIGH='1') then
      WRITE_FSR <= '1';
    else
      WRITE_FSR <= '0';
    end if;

    if (COMMAND(0)='1' and COMMAND(1)='0' and COMMAND(2)='0' and COMMAND(3)='1' and CMDHIGH='1') then
      READ_FSR <= '1';
    else
      READ_FSR <= '0';
    end if;
    
    if (COMMAND(0)='0' and COMMAND(1)='1' and COMMAND(2)='0' and COMMAND(3)='0' and CMDHIGH='1') then
      WRITE_FIFO <= '1';
    else
      WRITE_FIFO <= '0';
    end if;

    if (COMMAND(0)='1' and COMMAND(1)='1' and COMMAND(2)='0' and COMMAND(3)='0' and CMDHIGH='1') then
      READ_FIFO <= '1';
    else
      READ_FIFO <= '0';
    end if;

    if (COMMAND(0)='1' and COMMAND(1)='1' and COMMAND(2)='1' and COMMAND(3)='0' and CMDHIGH='1') then
      READ_STR <= '1';
    else
      READ_STR <= '0';
    end if;

    if (COMMAND(0)='1' and COMMAND(1)='1' and COMMAND(2)='0' and COMMAND(3)='1' and CMDHIGH='1') then
      READ_WRC <= '1';
    else
      READ_WRC <= '0';
    end if;

    if (COMMAND(0)='1' and COMMAND(1)='1' and COMMAND(2)='1' and COMMAND(3)='1' and CMDHIGH='1') then
      READ_RDC <= '1';
    else
      READ_RDC <= '0';
    end if;

  end process;

  CREATE_FSR_vector: process (RST,INDATA,WRITE_FSR,STROBE)
  begin
    FDPE(INDATA(0),STROBE,WRITE_FSR,RST,FSR_vector(0));
    FDPE(INDATA(1),STROBE,WRITE_FSR,RST,FSR_vector(1));
    FDPE(INDATA(2),STROBE,WRITE_FSR,RST,FSR_vector(2));
    FDPE(INDATA(3),STROBE,WRITE_FSR,RST,FSR_vector(3));
    FDPE(INDATA(4),STROBE,WRITE_FSR,RST,FSR_vector(4));
    FDPE(INDATA(5),STROBE,WRITE_FSR,RST,FSR_vector(5));
    FDPE(INDATA(6),STROBE,WRITE_FSR,RST,FSR_vector(6));
    FDPE(INDATA(7),STROBE,WRITE_FSR,RST,FSR_vector(7));
    FDPE(INDATA(8),STROBE,WRITE_FSR,RST,FSR_vector(8));
  end process;
  
  FIFO_SEL <= FSR_vector(7 downto 0);
  FIFO_MODE <= FSR_vector(8);
  
  CREATE_OUTDATA: process (STROBE,READ_FSR,READ_STR,READ_WRC,READ_RDC,READ_FIFO,FSR_vector,FIFO_STR, FIFO_WRC, FIFO_RDC, SLOWCLK,D_DTACK,E_DTACK)  --Also CREATE_DTACK
  begin
    if (STROBE='1' and READ_FSR='1') then
      OUTDATA(15 downto 8) <= "00000000";
      OUTDATA(7 downto 0) <= FSR_vector(7 downto 0);
    elsif (STROBE='1' and READ_STR='1') then
      OUTDATA(15 downto 0) <= FIFO_STR(15 downto 0);
    elsif (STROBE='1' and READ_WRC='1') then
      OUTDATA(15 downto 10) <= "000000";
      OUTDATA(9 downto 0) <= FIFO_WRC(9 downto 0);
    elsif (STROBE='1' and READ_RDC='1') then
      OUTDATA(15 downto 10) <= "000000";
      OUTDATA(9 downto 0) <= FIFO_RDC(9 downto 0);
    elsif (STROBE='1' and READ_FIFO='1') then
      OUTDATA(15 downto 0) <= FIFO_DATA(15 downto 0);
    else
--      OUTDATA(15 downto 0) <= "ZZZZZZZZZZZZZZZZ";
      OUTDATA(15 downto 0) <= FIFO_DATA(15 downto 0);
    end if;
--    FD(D_DTACK,SLOWCLK,E_DTACK);
--    if (E_DTACK='1') then
--      DTACK <= '0';
--    else
--      DTACK <= 'Z';
--    end if;
  end process;

  CREATE_DTACK_READ_FSR: process (READ_FSR,STROBE,SLOWCLK,D_DTACK_WRITE_FSR,E_DTACK_WRITE_FSR)
  begin
    D_DTACK_READ_FSR <= READ_FSR and STROBE;
    FD(D_DTACK_READ_FSR,SLOWCLK,E_DTACK_READ_FSR);
    if (E_DTACK_READ_FSR='1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_READ_STR: process (READ_STR,STROBE,SLOWCLK,D_DTACK_WRITE_STR,E_DTACK_WRITE_STR)
  begin
    D_DTACK_READ_STR <= READ_STR and STROBE;
    FD(D_DTACK_READ_STR,SLOWCLK,E_DTACK_READ_STR);
    if (E_DTACK_READ_STR='1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_READ_WRC: process (READ_WRC,STROBE,SLOWCLK,D_DTACK_WRITE_WRC,E_DTACK_WRITE_WRC)
  begin
    D_DTACK_READ_WRC <= READ_WRC and STROBE;
    FD(D_DTACK_READ_WRC,SLOWCLK,E_DTACK_READ_WRC);
    if (E_DTACK_READ_WRC='1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_READ_RDC: process (READ_RDC,STROBE,SLOWCLK,D_DTACK_WRITE_RDC,E_DTACK_WRITE_RDC)
  begin
    D_DTACK_READ_RDC <= READ_RDC and STROBE;
    FD(D_DTACK_READ_RDC,SLOWCLK,E_DTACK_READ_RDC);
    if (E_DTACK_READ_RDC='1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_READ_FIFO: process (READ_FIFO,STROBE,SLOWCLK,D_DTACK_READ_FIFO,E1_DTACK_READ_FIFO,E2_DTACK_READ_FIFO,E_DTACK_READ_FIFO)
  begin
    D_DTACK_READ_FIFO <= READ_FIFO and STROBE;
    FD(D_DTACK_READ_FIFO,SLOWCLK,E1_DTACK_READ_FIFO);
    FD(E1_DTACK_READ_FIFO,SLOWCLK,E2_DTACK_READ_FIFO);
    FD(E2_DTACK_READ_FIFO,SLOWCLK,E_DTACK_READ_FIFO);
    if (E_DTACK_READ_FIFO='1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_WRITE_FSR: process (WRITE_FSR,STROBE,SLOWCLK,D_DTACK_WRITE_FSR,E_DTACK_WRITE_FSR)
  begin
    D_DTACK_WRITE_FSR <= WRITE_FSR and STROBE;
    FD(D_DTACK_WRITE_FSR,SLOWCLK,E_DTACK_WRITE_FSR);
    if (E_DTACK_WRITE_FSR='1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_WRITE_FIFO: process (WRITE_FIFO,STROBE,SLOWCLK,D_DTACK_WRITE_FIFO,E_DTACK_WRITE_FIFO)
  begin
    D_DTACK_WRITE_FIFO <= WRITE_FIFO and STROBE;
    FD(D_DTACK_WRITE_FIFO,SLOWCLK,E1_DTACK_WRITE_FIFO);
    FD(E1_DTACK_WRITE_FIFO,SLOWCLK,E2_DTACK_WRITE_FIFO);
    E_DTACK_WRITE_FIFO <= E1_DTACK_WRITE_FIFO or E2_DTACK_WRITE_FIFO;
    if (E_DTACK_WRITE_FIFO='1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_FIFO_RD_EN: process (RST,SLOWCLK,FIFO_RD,FSR_vector,READ_FIFO,STROBE,I1_FIFO_RD_EN,I2_FIFO_RD_EN,I3_FIFO_RD_EN,C_FIFO_RD_EN)
  begin
    FIFO_RD(0) <= READ_FIFO and FSR_vector(0);
    FDC(FIFO_RD(0),STROBE,C_FIFO_RD_EN(0),I1_FIFO_RD_EN(0));
    FDC(I1_FIFO_RD_EN(0),SLOWCLK,C_FIFO_RD_EN(0),I2_FIFO_RD_EN(0));
    FDC(I2_FIFO_RD_EN(0),SLOWCLK,RST,I3_FIFO_RD_EN(0));
    C_FIFO_RD_EN(0) <= RST or I3_FIFO_RD_EN(0);

    FIFO_RD(1) <= READ_FIFO and FSR_vector(1);
    FDC(FIFO_RD(1),STROBE,C_FIFO_RD_EN(1),I1_FIFO_RD_EN(1));
    FDC(I1_FIFO_RD_EN(1),SLOWCLK,C_FIFO_RD_EN(1),I2_FIFO_RD_EN(1));
    FDC(I2_FIFO_RD_EN(1),SLOWCLK,RST,I3_FIFO_RD_EN(1));
    C_FIFO_RD_EN(1) <= RST or I3_FIFO_RD_EN(1);

    FIFO_RD(2) <= READ_FIFO and FSR_vector(2);
    FDC(FIFO_RD(2),STROBE,C_FIFO_RD_EN(2),I1_FIFO_RD_EN(2));
    FDC(I1_FIFO_RD_EN(2),SLOWCLK,C_FIFO_RD_EN(2),I2_FIFO_RD_EN(2));
    FDC(I2_FIFO_RD_EN(2),SLOWCLK,RST,I3_FIFO_RD_EN(2));
    C_FIFO_RD_EN(2) <= RST or I3_FIFO_RD_EN(2);

    FIFO_RD(3) <= READ_FIFO and FSR_vector(3);
    FDC(FIFO_RD(3),STROBE,C_FIFO_RD_EN(3),I1_FIFO_RD_EN(3));
    FDC(I1_FIFO_RD_EN(3),SLOWCLK,C_FIFO_RD_EN(3),I2_FIFO_RD_EN(3));
    FDC(I2_FIFO_RD_EN(3),SLOWCLK,RST,I3_FIFO_RD_EN(3));
    C_FIFO_RD_EN(3) <= RST or I3_FIFO_RD_EN(3);

    FIFO_RD(4) <= READ_FIFO and FSR_vector(4);
    FDC(FIFO_RD(4),STROBE,C_FIFO_RD_EN(4),I1_FIFO_RD_EN(4));
    FDC(I1_FIFO_RD_EN(4),SLOWCLK,C_FIFO_RD_EN(4),I2_FIFO_RD_EN(4));
    FDC(I2_FIFO_RD_EN(4),SLOWCLK,RST,I3_FIFO_RD_EN(4));
    C_FIFO_RD_EN(4) <= RST or I3_FIFO_RD_EN(4);

    FIFO_RD(5) <= READ_FIFO and FSR_vector(5);
    FDC(FIFO_RD(5),STROBE,C_FIFO_RD_EN(5),I1_FIFO_RD_EN(5));
    FDC(I1_FIFO_RD_EN(5),SLOWCLK,C_FIFO_RD_EN(5),I2_FIFO_RD_EN(5));
    FDC(I2_FIFO_RD_EN(5),SLOWCLK,RST,I3_FIFO_RD_EN(5));
    C_FIFO_RD_EN(5) <= RST or I3_FIFO_RD_EN(5);

    FIFO_RD(6) <= READ_FIFO and FSR_vector(6);
    FDC(FIFO_RD(6),STROBE,C_FIFO_RD_EN(6),I1_FIFO_RD_EN(6));
    FDC(I1_FIFO_RD_EN(6),SLOWCLK,C_FIFO_RD_EN(6),I2_FIFO_RD_EN(6));
    FDC(I2_FIFO_RD_EN(6),SLOWCLK,RST,I3_FIFO_RD_EN(6));
    C_FIFO_RD_EN(6) <= RST or I3_FIFO_RD_EN(6);

    FIFO_RD(7) <= READ_FIFO and FSR_vector(7);
    FDC(FIFO_RD(7),STROBE,C_FIFO_RD_EN(7),I1_FIFO_RD_EN(7));
    FDC(I1_FIFO_RD_EN(7),SLOWCLK,C_FIFO_RD_EN(7),I2_FIFO_RD_EN(7));
    FDC(I2_FIFO_RD_EN(7),SLOWCLK,RST,I3_FIFO_RD_EN(7));
    C_FIFO_RD_EN(7) <= RST or I3_FIFO_RD_EN(7);

    FIFO_RD_EN <= I2_FIFO_RD_EN;

--    if (FSR_vector(7 downto 0) = "00000001") then
--      FIFO_RD_EN(0) <= READ_FIFO and STROBE;
--      FIFO_RD_EN(7 downto 1) <= "0000000";
--    else
--      FIFO_RD_EN(7 downto 0) <= "00000000";
--    end if;  
  end process;

  CREATE_FIFO_WR_DATA: process (STROBE,SLOWCLK,INDATA,I1_INDATA,I2_INDATA)
  begin
    FD(INDATA(0),STROBE,I1_INDATA(0));
    FD(I1_INDATA(0),SLOWCLK,I2_INDATA(0));
    FD(INDATA(1),STROBE,I1_INDATA(1));
    FD(I1_INDATA(1),SLOWCLK,I2_INDATA(1));
    FD(INDATA(2),STROBE,I1_INDATA(2));
    FD(I1_INDATA(2),SLOWCLK,I2_INDATA(2));
    FD(INDATA(3),STROBE,I1_INDATA(3));
    FD(I1_INDATA(3),SLOWCLK,I2_INDATA(3));
    FD(INDATA(4),STROBE,I1_INDATA(4));
    FD(I1_INDATA(4),SLOWCLK,I2_INDATA(4));
    FD(INDATA(5),STROBE,I1_INDATA(5));
    FD(I1_INDATA(5),SLOWCLK,I2_INDATA(5));
    FD(INDATA(6),STROBE,I1_INDATA(6));
    FD(I1_INDATA(6),SLOWCLK,I2_INDATA(6));
    FD(INDATA(7),STROBE,I1_INDATA(7));
    FD(I1_INDATA(7),SLOWCLK,I2_INDATA(7));
    FD(INDATA(8),STROBE,I1_INDATA(8));
    FD(I1_INDATA(8),SLOWCLK,I2_INDATA(8));
    FD(INDATA(9),STROBE,I1_INDATA(9));
    FD(I1_INDATA(9),SLOWCLK,I2_INDATA(9));
    FD(INDATA(10),STROBE,I1_INDATA(10));
    FD(I1_INDATA(10),SLOWCLK,I2_INDATA(10));
    FD(INDATA(11),STROBE,I1_INDATA(11));
    FD(I1_INDATA(11),SLOWCLK,I2_INDATA(11));
    FD(INDATA(12),STROBE,I1_INDATA(12));
    FD(I1_INDATA(12),SLOWCLK,I2_INDATA(12));
    FD(INDATA(13),STROBE,I1_INDATA(13));
    FD(I1_INDATA(13),SLOWCLK,I2_INDATA(13));
    FD(INDATA(14),STROBE,I1_INDATA(14));
    FD(I1_INDATA(14),SLOWCLK,I2_INDATA(14));
    FD(INDATA(15),STROBE,I1_INDATA(15));
    FD(I1_INDATA(15),SLOWCLK,I2_INDATA(15));
    FIFO_WR_DATA <= I2_INDATA;
end process;


  CREATE_FIFO_WR_EN: process (RST,SLOWCLK,FIFO_WR,FSR_vector,WRITE_FIFO,STROBE,I1_FIFO_WR_EN,I2_FIFO_WR_EN,I3_FIFO_WR_EN,C_FIFO_WR_EN)
  begin

    FIFO_WR(0) <= WRITE_FIFO and FSR_vector(0);
    FDC(FIFO_WR(0),STROBE,C_FIFO_WR_EN(0),I1_FIFO_WR_EN(0));
    FDC(I1_FIFO_WR_EN(0),SLOWCLK,C_FIFO_WR_EN(0),I2_FIFO_WR_EN(0));
    FDC(I2_FIFO_WR_EN(0),SLOWCLK,RST,I3_FIFO_WR_EN(0));
    C_FIFO_WR_EN(0) <= RST or I3_FIFO_WR_EN(0);

    FIFO_WR(1) <= WRITE_FIFO and FSR_vector(1);
    FDC(FIFO_WR(1),STROBE,C_FIFO_WR_EN(1),I1_FIFO_WR_EN(1));
    FDC(I1_FIFO_WR_EN(1),SLOWCLK,C_FIFO_WR_EN(1),I2_FIFO_WR_EN(1));
    FDC(I2_FIFO_WR_EN(1),SLOWCLK,RST,I3_FIFO_WR_EN(1));
    C_FIFO_WR_EN(1) <= RST or I3_FIFO_WR_EN(1);

    FIFO_WR(2) <= WRITE_FIFO and FSR_vector(2);
    FDC(FIFO_WR(2),STROBE,C_FIFO_WR_EN(2),I1_FIFO_WR_EN(2));
    FDC(I1_FIFO_WR_EN(2),SLOWCLK,C_FIFO_WR_EN(2),I2_FIFO_WR_EN(2));
    FDC(I2_FIFO_WR_EN(2),SLOWCLK,RST,I3_FIFO_WR_EN(2));
    C_FIFO_WR_EN(2) <= RST or I3_FIFO_WR_EN(2);

    FIFO_WR(3) <= WRITE_FIFO and FSR_vector(3);
    FDC(FIFO_WR(3),STROBE,C_FIFO_WR_EN(3),I1_FIFO_WR_EN(3));
    FDC(I1_FIFO_WR_EN(3),SLOWCLK,C_FIFO_WR_EN(3),I2_FIFO_WR_EN(3));
    FDC(I2_FIFO_WR_EN(3),SLOWCLK,RST,I3_FIFO_WR_EN(3));
    C_FIFO_WR_EN(3) <= RST or I3_FIFO_WR_EN(3);

    FIFO_WR(4) <= WRITE_FIFO and FSR_vector(4);
    FDC(FIFO_WR(4),STROBE,C_FIFO_WR_EN(4),I1_FIFO_WR_EN(4));
    FDC(I1_FIFO_WR_EN(4),SLOWCLK,C_FIFO_WR_EN(4),I2_FIFO_WR_EN(4));
    FDC(I2_FIFO_WR_EN(4),SLOWCLK,RST,I3_FIFO_WR_EN(4));
    C_FIFO_WR_EN(4) <= RST or I3_FIFO_WR_EN(4);

    FIFO_WR(5) <= WRITE_FIFO and FSR_vector(5);
    FDC(FIFO_WR(5),STROBE,C_FIFO_WR_EN(5),I1_FIFO_WR_EN(5));
    FDC(I1_FIFO_WR_EN(5),SLOWCLK,C_FIFO_WR_EN(5),I2_FIFO_WR_EN(5));
    FDC(I2_FIFO_WR_EN(5),SLOWCLK,RST,I3_FIFO_WR_EN(5));
    C_FIFO_WR_EN(5) <= RST or I3_FIFO_WR_EN(5);

    FIFO_WR(6) <= WRITE_FIFO and FSR_vector(6);
    FDC(FIFO_WR(6),STROBE,C_FIFO_WR_EN(6),I1_FIFO_WR_EN(6));
    FDC(I1_FIFO_WR_EN(6),SLOWCLK,C_FIFO_WR_EN(6),I2_FIFO_WR_EN(6));
    FDC(I2_FIFO_WR_EN(6),SLOWCLK,RST,I3_FIFO_WR_EN(6));
    C_FIFO_WR_EN(6) <= RST or I3_FIFO_WR_EN(6);

    FIFO_WR(7) <= WRITE_FIFO and FSR_vector(7);
    FDC(FIFO_WR(7),STROBE,C_FIFO_WR_EN(7),I1_FIFO_WR_EN(7));
    FDC(I1_FIFO_WR_EN(7),SLOWCLK,C_FIFO_WR_EN(7),I2_FIFO_WR_EN(7));
    FDC(I2_FIFO_WR_EN(7),SLOWCLK,RST,I3_FIFO_WR_EN(7));
    C_FIFO_WR_EN(7) <= RST or I3_FIFO_WR_EN(7);
    
    FIFO_WR_EN <= I2_FIFO_WR_EN;
    
--    if (FSR_vector(7 downto 0) = "00000001") then
--      FIFO_WR_EN(0) <= WRITE_FIFO and STROBE;
--      FIFO_WR_EN(7 downto 1) <= "0000000";
--    else
--      FIFO_WR_EN(7 downto 0) <= "00000000";
--    end if;  
  end process;

end FIFOMON_Arch;
