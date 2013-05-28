library ieee;
library work;
use work.Latches_Flipflops.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity TESTCTRL is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );  

  port (
    CLK     : in std_logic;
    DDUCLK  : in std_logic;
    SLOWCLK : in std_logic;
    RST     : in std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    L1A            : out std_logic;
    ALCT_DAV       : out std_logic;
    TMB_DAV        : out std_logic;
    LCT            : out std_logic_vector(NFEB downto 0);
    DDU_DATA       : in  std_logic_vector(15 downto 0);
    DDU_DATA_VALID : in  std_logic;
    TC_RUN         : out std_logic;
    TS_OUT         : out std_logic_vector(31 downto 0)
    );

end TESTCTRL;

architecture TESTCTRL_Arch of TESTCTRL is

  --Declaring internal signals
  signal CMDHIGH, WRITE_FIFO, READ_FIFO, WRITE_FSR, READ_FSR, READ_STR, READ_WRC, READ_RDC, READ_TRC : std_logic;
  signal FSR_vector                                                                                  : std_logic_vector(12 downto 0);
  signal E_DTACK, D_DTACK                                                                            : std_logic;
  signal D_DTACK_WRITE_FSR, E_DTACK_WRITE_FSR                                                        : std_logic;
  signal D_DTACK_READ_FSR, E_DTACK_READ_FSR                                                          : std_logic;
  signal D_DTACK_WRITE_STR, E_DTACK_WRITE_STR                                                        : std_logic;
  signal D_DTACK_READ_STR, E_DTACK_READ_STR                                                          : std_logic;
  signal D_DTACK_WRITE_WRC, E_DTACK_WRITE_WRC                                                        : std_logic;
  signal D_DTACK_READ_WRC, E_DTACK_READ_WRC                                                          : std_logic;
  signal D_DTACK_WRITE_RDC, E_DTACK_WRITE_RDC                                                        : std_logic;
  signal D_DTACK_READ_RDC, E_DTACK_READ_RDC                                                          : std_logic;
  signal D_DTACK_READ_TRC, E_DTACK_READ_TRC                                                          : std_logic;
  signal D_DTACK_READ_FIFO, E1_DTACK_READ_FIFO, E2_DTACK_READ_FIFO, E_DTACK_READ_FIFO                : std_logic;
  signal D_DTACK_WRITE_FIFO, E1_DTACK_WRITE_FIFO, E2_DTACK_WRITE_FIFO, E_DTACK_WRITE_FIFO            : std_logic;
  signal D_DTACK_FR, E_DTACK_FR                                                                      : std_logic;
  signal E_READ_FIFO                                                                                 : std_logic;
  signal I1_FIFO_RD_EN, I2_FIFO_RD_EN, I3_FIFO_RD_EN, C_FIFO_RD_EN, FIFO_RD                          : std_logic_vector(3 downto 0);
  signal I1_FIFO_WR_EN, I2_FIFO_WR_EN, I3_FIFO_WR_EN, C_FIFO_WR_EN, FIFO_WR                          : std_logic_vector(3 downto 0);

  signal I1_INDATA, I2_INDATA, FIFO_WR_DATA : std_logic_vector(15 downto 0);

  signal event_rd : std_logic;

  signal ts_cnt_out, ts_fifo_out : std_logic_vector(31 downto 0);

  type   tc_fifo_cnt_data_type is array (3 downto 0) of std_logic_vector(10 downto 0);
  signal tc_fifo_wr_cnt, tc_fifo_rd_cnt : tc_fifo_cnt_data_type;

  type     tc_fifo_in_type is array (3 downto 0) of std_logic_vector(15 downto 0);
  signal   tc_fifo_in                                                 : tc_fifo_in_type;
  signal   fifo_sel                                                   : std_logic_vector(3 downto 0);
  signal   fifo_str                                                   : std_logic_vector(15 downto 0);
  signal   fifo_wrc                                                   : std_logic_vector(10 downto 0);
  signal   fifo_rdc                                                   : std_logic_vector(10 downto 0);
  signal   fifo_data                                                  : std_logic_vector(15 downto 0);
  signal   fifo_rd_en, fifo_wr_en                                     : std_logic_vector(3 downto 0);
  signal   tc_fifo_rd_en, tc_fifo_wr_en, tc_fifo_wr_ck, tc_fifo_rd_ck : std_logic_vector(3 downto 0);
  signal   tc_run_inner                                               : std_logic     := '0';
  signal   tc_fifo_out                                                : tc_fifo_in_type;
  signal   tc_fifo_full, tc_fifo_afull, tc_fifo_aempty, tc_fifo_empty : std_logic_vector(3 downto 0);
  signal   event_fifo_out                                             : std_logic_vector(15 downto 0);
  signal   tc_fifo_rst                                                : std_logic;
  signal   ts_cnt_rst                                                 : std_logic;
  type     boolean_array is array (3 downto 0) of boolean;
  constant tc_fifo_fwft                                               : boolean_array := (false, true, true, true);

  signal trg_cnt_rst      : std_logic;
  signal trg_cnt_sel      : std_logic_vector(3 downto 0);
  type   lct_cnt_data_type is array (7 downto 0) of std_logic_vector(15 downto 0);
  signal lct_cnt_out      : lct_cnt_data_type;
  signal l1a_cnt_out      : std_logic_vector(15 downto 0);
  signal alct_dav_cnt_out : std_logic_vector(15 downto 0);
  signal tmb_dav_cnt_out  : std_logic_vector(15 downto 0);
  signal trg_cnt_data     : std_logic_vector(15 downto 0);

  signal l1a_inner      : std_logic;
  signal alct_dav_inner : std_logic;
  signal tmb_dav_inner  : std_logic;
  signal lct_inner      : std_logic_vector(NFEB downto 0);

-----------

begin  --Architecture

  --All processes will be called CREATE_{name of signal they create}
  --If a process creates more than one signal, one name will be used and then
  --the other possible names will be in the comments
  --This is so the reader can use ctrl+f functions to find relevant processes

-- FSR(0) -> select fifo(0) (tc_fifo_ts_l)
-- FSR(1) -> select fifo(1) (tc_fifo_ts_h)
-- FSR(2) -> select fifo(2) (tc_fifo_event)
-- FSR(3) -> select fifo(3) (tc_fifo_ddudata)
-- FSR(4) -> tc_run (start test run)
-- FSR(5) -> ts_cnt_rst (reset time stamp counter)
-- FSR(6) -> tc_fifo_rst (reset tc fifos)
-- FSR(7) -> trg_cnt_rst (reset trigger counters)
-- FSR(11 downto 8) -> trg_cnt_sel (select trigger counter)

-- COMMAND(3 downto 0) = "1000" (20) -> WRITE FSR
-- COMMAND(3 downto 0) = "1001" (24) -> READ FSR
-- COMMAND(3 downto 0) = "0010" (08) -> WRITE FIFO
-- COMMAND(3 downto 0) = "0011" (0c) -> READ FIFO
-- COMMAND(3 downto 0) = "0111" (1c) -> READ FIFO STATUS REGISTER
-- COMMAND(3 downto 0) = "1011" (2c) -> READ WRITE COUNTER REGISTER
-- COMMAND(3 downto 0) = "1111" (3c) -> READ FIFO READ COUNTER REGISTER
-- COMMAND(3 downto 0) = "1010" (28) -> READ TRIGGER COUNTER
  
  CREATE_DECODE : process (DEVICE, COMMAND, CMDHIGH)
  begin
    if (COMMAND(9 downto 4) = "000000" and DEVICE='1') then
      CMDHIGH <= '1';
    else
      CMDHIGH <= '0';
    end if;

    if (COMMAND(0) = '0' and COMMAND(1) = '0' and COMMAND(2) = '0' and COMMAND(3) = '1' and CMDHIGH = '1') then
      WRITE_FSR <= '1';
    else
      WRITE_FSR <= '0';
    end if;

    if (COMMAND(0) = '1' and COMMAND(1) = '0' and COMMAND(2) = '0' and COMMAND(3) = '1' and CMDHIGH = '1') then
      READ_FSR <= '1';
    else
      READ_FSR <= '0';
    end if;

    if (COMMAND(0) = '0' and COMMAND(1) = '1' and COMMAND(2) = '0' and COMMAND(3) = '0' and CMDHIGH = '1') then
      WRITE_FIFO <= '1';
    else
      WRITE_FIFO <= '0';
    end if;

    if (COMMAND(0) = '1' and COMMAND(1) = '1' and COMMAND(2) = '0' and COMMAND(3) = '0' and CMDHIGH = '1') then
      READ_FIFO <= '1';
    else
      READ_FIFO <= '0';
    end if;

    if (COMMAND(0) = '1' and COMMAND(1) = '1' and COMMAND(2) = '1' and COMMAND(3) = '0' and CMDHIGH = '1') then
      READ_STR <= '1';
    else
      READ_STR <= '0';
    end if;

    if (COMMAND(0) = '1' and COMMAND(1) = '1' and COMMAND(2) = '0' and COMMAND(3) = '1' and CMDHIGH = '1') then
      READ_WRC <= '1';
    else
      READ_WRC <= '0';
    end if;

    if (COMMAND(0) = '1' and COMMAND(1) = '1' and COMMAND(2) = '1' and COMMAND(3) = '1' and CMDHIGH = '1') then
      READ_RDC <= '1';
    else
      READ_RDC <= '0';
    end if;

    if (COMMAND(0) = '0' and COMMAND(1) = '1' and COMMAND(2) = '0' and COMMAND(3) = '1' and CMDHIGH = '1') then
      READ_TRC <= '1';
    else
      READ_TRC <= '0';
    end if;

  end process;

  CREATE_FSR_vector : process (RST, INDATA, WRITE_FSR, STROBE)
  begin
    FDCE(INDATA(0), STROBE, WRITE_FSR, RST, FSR_vector(0));
    FDCE(INDATA(1), STROBE, WRITE_FSR, RST, FSR_vector(1));
    FDCE(INDATA(2), STROBE, WRITE_FSR, RST, FSR_vector(2));
    FDCE(INDATA(3), STROBE, WRITE_FSR, RST, FSR_vector(3));
    FDCE(INDATA(4), STROBE, WRITE_FSR, RST, FSR_vector(4));
    FDCE(INDATA(5), STROBE, WRITE_FSR, RST, FSR_vector(5));
    FDCE(INDATA(6), STROBE, WRITE_FSR, RST, FSR_vector(6));
    FDCE(INDATA(7), STROBE, WRITE_FSR, RST, FSR_vector(7));
    FDCE(INDATA(8), STROBE, WRITE_FSR, RST, FSR_vector(8));
    FDCE(INDATA(9), STROBE, WRITE_FSR, RST, FSR_vector(9));
    FDCE(INDATA(10), STROBE, WRITE_FSR, RST, FSR_vector(10));
    FDCE(INDATA(11), STROBE, WRITE_FSR, RST, FSR_vector(11));
    FDCE(INDATA(12), STROBE, WRITE_FSR, RST, FSR_vector(12));
  end process;

  FIFO_SEL     <= FSR_vector(3 downto 0);
  tc_run_inner <= FSR_vector(4);
  ts_cnt_rst   <= rst or FSR_vector(5);
  tc_fifo_rst  <= rst or FSR_vector(6);
  trg_cnt_rst  <= rst or FSR_vector(7);
  trg_cnt_sel  <= FSR_vector(11 downto 8);

  tc_run <= tc_run_inner;

  CREATE_OUTDATA : process (STROBE, READ_FSR, READ_STR, READ_WRC, READ_RDC, READ_FIFO, FSR_vector, FIFO_STR, FIFO_WRC, FIFO_RDC, SLOWCLK, D_DTACK, E_DTACK)  --Also CREATE_DTACK
  begin
    if (STROBE = '1' and READ_FSR = '1') then
      OUTDATA(15 downto 5) <= (others => '0');
      OUTDATA(4 downto 0)  <= FSR_vector(4 downto 0);
    elsif (STROBE = '1' and READ_STR = '1') then
      OUTDATA(15 downto 0) <= FIFO_STR(15 downto 0);
    elsif (STROBE = '1' and READ_WRC = '1') then
      OUTDATA(15 downto 11) <= (others => '0');
      OUTDATA(10 downto 0)   <= FIFO_WRC(10 downto 0);
    elsif (STROBE = '1' and READ_RDC = '1') then
      OUTDATA(15 downto 11) <= (others => '0');
      OUTDATA(10 downto 0)   <= FIFO_RDC(10 downto 0);
    elsif (STROBE = '1' and READ_FIFO = '1') then
      OUTDATA(15 downto 0) <= FIFO_DATA(15 downto 0);
    elsif (STROBE = '1' and READ_TRC = '1') then
      OUTDATA(15 downto 0) <= TRG_CNT_DATA(15 downto 0);
    else
--      OUTDATA(15 downto 0) <= "ZZZZZZZZZZZZZZZZ";
      OUTDATA(15 downto 0) <= FIFO_DATA(15 downto 0);
    end if;
  end process;

  CREATE_DTACK_READ_FSR : process (READ_FSR, STROBE, SLOWCLK, D_DTACK_WRITE_FSR, E_DTACK_WRITE_FSR)
  begin
    D_DTACK_READ_FSR <= READ_FSR and STROBE;
    FD(D_DTACK_READ_FSR, SLOWCLK, E_DTACK_READ_FSR);
    if (E_DTACK_READ_FSR = '1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_READ_STR : process (READ_STR, STROBE, SLOWCLK, D_DTACK_WRITE_STR, E_DTACK_WRITE_STR)
  begin
    D_DTACK_READ_STR <= READ_STR and STROBE;
    FD(D_DTACK_READ_STR, SLOWCLK, E_DTACK_READ_STR);
    if (E_DTACK_READ_STR = '1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_READ_WRC : process (READ_WRC, STROBE, SLOWCLK, D_DTACK_WRITE_WRC, E_DTACK_WRITE_WRC)
  begin
    D_DTACK_READ_WRC <= READ_WRC and STROBE;
    FD(D_DTACK_READ_WRC, SLOWCLK, E_DTACK_READ_WRC);
    if (E_DTACK_READ_WRC = '1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_READ_RDC : process (READ_RDC, STROBE, SLOWCLK, D_DTACK_WRITE_RDC, E_DTACK_WRITE_RDC)
  begin
    D_DTACK_READ_RDC <= READ_RDC and STROBE;
    FD(D_DTACK_READ_RDC, SLOWCLK, E_DTACK_READ_RDC);
    if (E_DTACK_READ_RDC = '1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_READ_FIFO : process (READ_FIFO, STROBE, SLOWCLK, D_DTACK_READ_FIFO, E1_DTACK_READ_FIFO, E2_DTACK_READ_FIFO, E_DTACK_READ_FIFO)
  begin
    D_DTACK_READ_FIFO <= READ_FIFO and STROBE;
    FD(D_DTACK_READ_FIFO, SLOWCLK, E1_DTACK_READ_FIFO);
    FD(E1_DTACK_READ_FIFO, SLOWCLK, E2_DTACK_READ_FIFO);
    FD(E2_DTACK_READ_FIFO, SLOWCLK, E_DTACK_READ_FIFO);
    if (E_DTACK_READ_FIFO = '1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_WRITE_FSR : process (WRITE_FSR, STROBE, SLOWCLK, D_DTACK_WRITE_FSR, E_DTACK_WRITE_FSR)
  begin
    D_DTACK_WRITE_FSR <= WRITE_FSR and STROBE;
    FD(D_DTACK_WRITE_FSR, SLOWCLK, E_DTACK_WRITE_FSR);
    if (E_DTACK_WRITE_FSR = '1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_WRITE_FIFO : process (WRITE_FIFO, STROBE, SLOWCLK, D_DTACK_WRITE_FIFO, E_DTACK_WRITE_FIFO)
  begin
    D_DTACK_WRITE_FIFO <= WRITE_FIFO and STROBE;
    FD(D_DTACK_WRITE_FIFO, SLOWCLK, E1_DTACK_WRITE_FIFO);
    FD(E1_DTACK_WRITE_FIFO, SLOWCLK, E2_DTACK_WRITE_FIFO);
    E_DTACK_WRITE_FIFO <= E1_DTACK_WRITE_FIFO or E2_DTACK_WRITE_FIFO;
    if (E_DTACK_WRITE_FIFO = '1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_DTACK_READ_TRC : process (READ_TRC, STROBE, SLOWCLK, D_DTACK_READ_TRC, E_DTACK_READ_TRC)
  begin
    D_DTACK_READ_TRC <= READ_TRC and STROBE;
    FD(D_DTACK_READ_TRC, SLOWCLK, E_DTACK_READ_TRC);
    if (E_DTACK_READ_TRC = '1') then
      DTACK <= '0';
    else
      DTACK <= 'Z';
    end if;
  end process;

  CREATE_FIFO_RD_EN : process (RST, SLOWCLK, FIFO_RD, FSR_vector, READ_FIFO, STROBE, I1_FIFO_RD_EN, I2_FIFO_RD_EN, I3_FIFO_RD_EN, C_FIFO_RD_EN)
  begin
    FIFO_RD(0)      <= READ_FIFO and FSR_vector(0);
    FDC(FIFO_RD(0), STROBE, C_FIFO_RD_EN(0), I1_FIFO_RD_EN(0));
    FDC(I1_FIFO_RD_EN(0), SLOWCLK, C_FIFO_RD_EN(0), I2_FIFO_RD_EN(0));
    FDC(I2_FIFO_RD_EN(0), SLOWCLK, RST, I3_FIFO_RD_EN(0));
    C_FIFO_RD_EN(0) <= RST or I3_FIFO_RD_EN(0);

    FIFO_RD(1)      <= READ_FIFO and FSR_vector(1);
    FDC(FIFO_RD(1), STROBE, C_FIFO_RD_EN(1), I1_FIFO_RD_EN(1));
    FDC(I1_FIFO_RD_EN(1), SLOWCLK, C_FIFO_RD_EN(1), I2_FIFO_RD_EN(1));
    FDC(I2_FIFO_RD_EN(1), SLOWCLK, RST, I3_FIFO_RD_EN(1));
    C_FIFO_RD_EN(1) <= RST or I3_FIFO_RD_EN(1);

    FIFO_RD(2)      <= READ_FIFO and FSR_vector(2);
    FDC(FIFO_RD(2), STROBE, C_FIFO_RD_EN(2), I1_FIFO_RD_EN(2));
    FDC(I1_FIFO_RD_EN(2), SLOWCLK, C_FIFO_RD_EN(2), I2_FIFO_RD_EN(2));
    FDC(I2_FIFO_RD_EN(2), SLOWCLK, RST, I3_FIFO_RD_EN(2));
    C_FIFO_RD_EN(2) <= RST or I3_FIFO_RD_EN(2);

    FIFO_RD(3)      <= READ_FIFO and FSR_vector(3);
    FDC(FIFO_RD(3), STROBE, C_FIFO_RD_EN(3), I1_FIFO_RD_EN(3));
    FDC(I1_FIFO_RD_EN(3), SLOWCLK, C_FIFO_RD_EN(3), I2_FIFO_RD_EN(3));
    FDC(I2_FIFO_RD_EN(3), SLOWCLK, RST, I3_FIFO_RD_EN(3));
    C_FIFO_RD_EN(3) <= RST or I3_FIFO_RD_EN(3);


    FIFO_RD_EN <= I2_FIFO_RD_EN;

--    if (FSR_vector(7 downto 0) = "00000001") then
--      FIFO_RD_EN(0) <= READ_FIFO and STROBE;
--      FIFO_RD_EN(7 downto 1) <= "0000000";
--    else
--      FIFO_RD_EN(7 downto 0) <= "00000000";
--    end if;  
  end process;

  CREATE_FIFO_WR_DATA : process (STROBE, SLOWCLK, INDATA, I1_INDATA, I2_INDATA)
  begin
    FD(INDATA(0), STROBE, I1_INDATA(0));
    FD(I1_INDATA(0), SLOWCLK, I2_INDATA(0));
    FD(INDATA(1), STROBE, I1_INDATA(1));
    FD(I1_INDATA(1), SLOWCLK, I2_INDATA(1));
    FD(INDATA(2), STROBE, I1_INDATA(2));
    FD(I1_INDATA(2), SLOWCLK, I2_INDATA(2));
    FD(INDATA(3), STROBE, I1_INDATA(3));
    FD(I1_INDATA(3), SLOWCLK, I2_INDATA(3));
    FD(INDATA(4), STROBE, I1_INDATA(4));
    FD(I1_INDATA(4), SLOWCLK, I2_INDATA(4));
    FD(INDATA(5), STROBE, I1_INDATA(5));
    FD(I1_INDATA(5), SLOWCLK, I2_INDATA(5));
    FD(INDATA(6), STROBE, I1_INDATA(6));
    FD(I1_INDATA(6), SLOWCLK, I2_INDATA(6));
    FD(INDATA(7), STROBE, I1_INDATA(7));
    FD(I1_INDATA(7), SLOWCLK, I2_INDATA(7));
    FD(INDATA(8), STROBE, I1_INDATA(8));
    FD(I1_INDATA(8), SLOWCLK, I2_INDATA(8));
    FD(INDATA(9), STROBE, I1_INDATA(9));
    FD(I1_INDATA(9), SLOWCLK, I2_INDATA(9));
    FD(INDATA(10), STROBE, I1_INDATA(10));
    FD(I1_INDATA(10), SLOWCLK, I2_INDATA(10));
    FD(INDATA(11), STROBE, I1_INDATA(11));
    FD(I1_INDATA(11), SLOWCLK, I2_INDATA(11));
    FD(INDATA(12), STROBE, I1_INDATA(12));
    FD(I1_INDATA(12), SLOWCLK, I2_INDATA(12));
    FD(INDATA(13), STROBE, I1_INDATA(13));
    FD(I1_INDATA(13), SLOWCLK, I2_INDATA(13));
    FD(INDATA(14), STROBE, I1_INDATA(14));
    FD(I1_INDATA(14), SLOWCLK, I2_INDATA(14));
    FD(INDATA(15), STROBE, I1_INDATA(15));
    FD(I1_INDATA(15), SLOWCLK, I2_INDATA(15));
    FIFO_WR_DATA <= I2_INDATA;
  end process;


  CREATE_FIFO_WR_EN : process (RST, SLOWCLK, FIFO_WR, FSR_vector, WRITE_FIFO, STROBE, I1_FIFO_WR_EN, I2_FIFO_WR_EN, I3_FIFO_WR_EN, C_FIFO_WR_EN)
  begin

    FIFO_WR(0)      <= WRITE_FIFO and FSR_vector(0);
    FDC(FIFO_WR(0), STROBE, C_FIFO_WR_EN(0), I1_FIFO_WR_EN(0));
    FDC(I1_FIFO_WR_EN(0), SLOWCLK, C_FIFO_WR_EN(0), I2_FIFO_WR_EN(0));
    FDC(I2_FIFO_WR_EN(0), SLOWCLK, RST, I3_FIFO_WR_EN(0));
    C_FIFO_WR_EN(0) <= RST or I3_FIFO_WR_EN(0);

    FIFO_WR(1)      <= WRITE_FIFO and FSR_vector(1);
    FDC(FIFO_WR(1), STROBE, C_FIFO_WR_EN(1), I1_FIFO_WR_EN(1));
    FDC(I1_FIFO_WR_EN(1), SLOWCLK, C_FIFO_WR_EN(1), I2_FIFO_WR_EN(1));
    FDC(I2_FIFO_WR_EN(1), SLOWCLK, RST, I3_FIFO_WR_EN(1));
    C_FIFO_WR_EN(1) <= RST or I3_FIFO_WR_EN(1);

    FIFO_WR(2)      <= WRITE_FIFO and FSR_vector(2);
    FDC(FIFO_WR(2), STROBE, C_FIFO_WR_EN(2), I1_FIFO_WR_EN(2));
    FDC(I1_FIFO_WR_EN(2), SLOWCLK, C_FIFO_WR_EN(2), I2_FIFO_WR_EN(2));
    FDC(I2_FIFO_WR_EN(2), SLOWCLK, RST, I3_FIFO_WR_EN(2));
    C_FIFO_WR_EN(2) <= RST or I3_FIFO_WR_EN(2);

    FIFO_WR(3)      <= WRITE_FIFO and FSR_vector(3);
    FDC(FIFO_WR(3), STROBE, C_FIFO_WR_EN(3), I1_FIFO_WR_EN(3));
    FDC(I1_FIFO_WR_EN(3), SLOWCLK, C_FIFO_WR_EN(3), I2_FIFO_WR_EN(3));
    FDC(I2_FIFO_WR_EN(3), SLOWCLK, RST, I3_FIFO_WR_EN(3));
    C_FIFO_WR_EN(3) <= RST or I3_FIFO_WR_EN(3);

    FIFO_WR_EN <= I2_FIFO_WR_EN;
    
  end process;

  GEN_TC_FIFO_VALS : for I in 2 downto 0 generate  -- (DDU_DATA,L1A/ALCT_DAV/TMB_DAV/LCT,TSH,TSL)
  begin
    tc_fifo_wr_en(I) <= fifo_wr_en(I);
    tc_fifo_wr_ck(I) <= slowclk;
    tc_fifo_rd_en(I) <= event_rd when (tc_run_inner = '1') else fifo_rd_en(I);
    tc_fifo_rd_ck(I) <= clk      when (tc_run_inner = '1') else slowclk;
    --tc_fifo_in(I) <= indata;
    tc_fifo_in(I)    <= FIFO_WR_DATA;

  end generate GEN_TC_FIFO_VALS;
  tc_fifo_wr_en(3) <= ddu_data_valid when (tc_run_inner = '1') else fifo_wr_en(3);
  tc_fifo_wr_ck(3) <= dduclk         when (tc_run_inner = '1') else slowclk;
  tc_fifo_rd_en(3) <= fifo_rd_en(3);
  tc_fifo_rd_ck(3) <= slowclk;
  tc_fifo_in(3)    <= ddu_data       when (tc_run_inner = '1') else indata;



  GEN_TC_FIFO : for I in 3 downto 0 generate  -- (DDU_DATA,L1A/ALCT_DAV/TMB_DAV/LCT,TSH,TSL)

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
        ALMOSTEMPTY => tc_fifo_aempty(I),  -- Output almost empty 
        ALMOSTFULL  => tc_fifo_afull(I),   -- Output almost full
        DO          => tc_fifo_out(I),     -- Output data
        EMPTY       => tc_fifo_empty(I),   -- Output empty
        FULL        => tc_fifo_full(I),    -- Output full
        RDCOUNT     => tc_fifo_rd_cnt(I),  -- Output read count
        RDERR       => open,               -- Output read error
        WRCOUNT     => tc_fifo_wr_cnt(I),  -- Output write count
        WRERR       => open,               -- Output write error
        DI          => tc_fifo_in(I),      -- Input data
        RDCLK       => tc_fifo_rd_ck(I),   -- Input read clock
        RDEN        => tc_fifo_rd_en(I),   -- Input read enable
        RST         => tc_fifo_rst,        -- Input reset
        WRCLK       => tc_fifo_wr_ck(I),   -- Input write clock
        WREN        => tc_fifo_wr_en(I)    -- Input write enable
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


  TS_FIFO_OUT    <= tc_fifo_out(1) & tc_fifo_out(0);
  EVENT_FIFO_OUT <= tc_fifo_out(2);

  TS_CNT : process (CLK, tc_run_inner)

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
        TMB_DAV_INNER  <= EVENT_FIFO_OUT(8);
        LCT_INNER      <= EVENT_FIFO_OUT(NFEB downto 0);
      else
        L1A_INNER      <= '0';
        ALCT_DAV_INNER <= '0';
        TMB_DAV_INNER  <= '0';
        LCT_INNER      <= (others => '0');
      end if;
    end if;

    
  end process;

  L1A      <= L1A_INNER;
  ALCT_DAV <= ALCT_DAV_INNER;
  TMB_DAV  <= TMB_DAV_INNER;
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

  TMB_DAV_CNT : process (CLK, tc_run_inner, tmb_dav_inner, trg_cnt_rst, rst)

    variable TMB_DAV_CNT_DATA : std_logic_vector(15 downto 0);

  begin

    if (RST = '1' or trg_cnt_rst = '1') then
      TMB_DAV_CNT_DATA := (others => '0');
    elsif (tc_run_inner = '1') and (TMB_DAV_INNER = '1') and (RISING_EDGE(CLK)) then
      TMB_DAV_CNT_DATA := std_logic_vector(unsigned(TMB_DAV_CNT_DATA) + 1);
    end if;

    TMB_DAV_CNT_OUT <= TMB_DAV_CNT_DATA;

  end process;

-- LCT_CNT: process (CLK,tc_run_inner,lct_inner,trg_cnt_rst,rst)
-- 
-- TYPE LCT_CNT_DATA_TYPE is array (7 downto 0) of std_logic_vector(15 downto 0);
-- VARIABLE LCT_CNT_DATA  : LCT_CNT_DATA_TYPE;
-- 
-- BEGIN
-- 
--      IF (RST = '1' or trg_cnt_rst = '1') THEN
--              LCT_CNT_DATA := (OTHERS => '0');
--      ELSIF (tc_run_inner = '1') AND (lct_inner(I) = '1') AND (RISING_EDGE(CLK)) then
--              LCT_CNT_DATA := std_logic_vector(unsigned(LCT_CNT_DATA) + 1);
--      END IF;              
--      
--      LCT_CNT_OUT(I) <= LCT_CNT_DATA;
-- 
-- END PROCESS;

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
                  TMB_DAV_CNT_OUT  when (TRG_CNT_SEL = "1010") else
                  (others => '0');

end TESTCTRL_Arch;
