-- VMECONFREGS: Assign values to registers used in ODMB_CTRL

library ieee;
library work;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VMECONFREGS is
  generic (
    NFEB : integer range 1 to 7 := 7  -- Number of DCFEBS, 7 in the final design
    );    
  port (

    SLOWCLK : in std_logic;
    RST     : in std_logic;

    DEVICE  : in std_logic;
    STROBE  : in std_logic;
    COMMAND : in std_logic_vector(9 downto 0);
    WRITER  : in std_logic;

    INDATA  : in  std_logic_vector(15 downto 0);
    OUTDATA : out std_logic_vector(15 downto 0);

    DTACK : out std_logic;

    ALCT_PUSH_DLY : out std_logic_vector(4 downto 0);
    OTMB_PUSH_DLY : out std_logic_vector(4 downto 0);
    PUSH_DLY      : out std_logic_vector(4 downto 0);
    LCT_L1A_DLY   : out std_logic_vector(5 downto 0);

    INJ_DLY    : out std_logic_vector(4 downto 0);
    EXT_DLY    : out std_logic_vector(4 downto 0);
    CALLCT_DLY : out std_logic_vector(3 downto 0);

    NWORDS_DUMMY : out std_logic_vector(15 downto 0);
    KILL         : out std_logic_vector(NFEB+2 downto 1);
    CRATEID      : out std_logic_vector(6 downto 0)
    );
end VMECONFREGS;



architecture VMECONFREGS_Arch of VMECONFREGS is

  signal DTACK_INNER : std_logic;
  signal CMDDEV      : unsigned(12 downto 0);

  constant FW_VERSION                                   : std_logic_vector(15 downto 0) := x"0106";
  signal   OUT_FW_VERSION                               : std_logic_vector(15 downto 0) := (others => '0');
  signal   R_FW_VERSION, D_R_FW_VERSION, Q_R_FW_VERSION : std_logic                     := '0';

  signal OUT_LCT_L1A                         : std_logic_vector(15 downto 0) := (others => '0');
  signal LCT_L1A_DLY_INNER                   : std_logic_vector(5 downto 0);
  signal W_LCT_L1A, D_W_LCT_L1A, Q_W_LCT_L1A : std_logic                     := '0';
  signal R_LCT_L1A, D_R_LCT_L1A, Q_R_LCT_L1A : std_logic                     := '0';

  signal OUT_OTMB_PUSH                             : std_logic_vector(15 downto 0) := (others => '0');
  signal OTMB_PUSH_DLY_INNER                       : std_logic_vector(4 downto 0);
  signal W_OTMB_PUSH, D_W_OTMB_PUSH, Q_W_OTMB_PUSH : std_logic                     := '0';
  signal R_OTMB_PUSH, D_R_OTMB_PUSH, Q_R_OTMB_PUSH : std_logic                     := '0';

  signal OUT_PUSH                   : std_logic_vector(15 downto 0) := (others => '0');
  signal PUSH_DLY_INNER             : std_logic_vector(4 downto 0);
  signal W_PUSH, D_W_PUSH, Q_W_PUSH : std_logic                     := '0';
  signal R_PUSH, D_R_PUSH, Q_R_PUSH : std_logic                     := '0';

  signal OUT_ALCT_PUSH                             : std_logic_vector(15 downto 0) := (others => '0');
  signal ALCT_PUSH_DLY_INNER                       : std_logic_vector(4 downto 0);
  signal W_ALCT_PUSH, D_W_ALCT_PUSH, Q_W_ALCT_PUSH : std_logic                     := '0';
  signal R_ALCT_PUSH, D_R_ALCT_PUSH, Q_R_ALCT_PUSH : std_logic                     := '0';

  signal OUT_INJ_DLY                         : std_logic_vector(15 downto 0) := (others => '0');
  signal INJ_DLY_INNER                       : std_logic_vector(4 downto 0);
  signal W_INJ_DLY, D_W_INJ_DLY, Q_W_INJ_DLY : std_logic                     := '0';
  signal R_INJ_DLY, D_R_INJ_DLY, Q_R_INJ_DLY : std_logic                     := '0';

  signal OUT_EXT_DLY                         : std_logic_vector(15 downto 0) := (others => '0');
  signal EXT_DLY_INNER                       : std_logic_vector(4 downto 0);
  signal W_EXT_DLY, D_W_EXT_DLY, Q_W_EXT_DLY : std_logic                     := '0';
  signal R_EXT_DLY, D_R_EXT_DLY, Q_R_EXT_DLY : std_logic                     := '0';

  signal OUT_CALLCT_DLY                               : std_logic_vector(15 downto 0) := (others => '0');
  signal CALLCT_DLY_INNER                             : std_logic_vector(3 downto 0);
  signal W_CALLCT_DLY, D_W_CALLCT_DLY, Q_W_CALLCT_DLY : std_logic                     := '0';
  signal R_CALLCT_DLY, D_R_CALLCT_DLY, Q_R_CALLCT_DLY : std_logic                     := '0';

  constant NWORDS_DUMMY_DEF                                       : std_logic_vector(15 downto 0) := x"0008";
  signal   OUT_NWORDS_DUMMY                                       : std_logic_vector(15 downto 0);
  signal   NWORDS_DUMMY_INNER, NWORDS_DUMMY_RST, NWORDS_DUMMY_PRE : std_logic_vector(15 downto 0);
  signal   W_NWORDS_DUMMY, D_W_NWORDS_DUMMY, Q_W_NWORDS_DUMMY     : std_logic;
  signal   R_NWORDS_DUMMY, D_R_NWORDS_DUMMY, Q_R_NWORDS_DUMMY     : std_logic;

  signal OUT_KILL                   : std_logic_vector(15 downto 0) := (others => '0');
  signal KILL_INNER                 : std_logic_vector(NFEB+2 downto 1);
  signal W_KILL, D_W_KILL, Q_W_KILL : std_logic                     := '0';
  signal R_KILL, D_R_KILL, Q_R_KILL : std_logic                     := '0';

  signal OUT_CRATEID                         : std_logic_vector(15 downto 0) := (others => '0');
  signal CRATEID_INNER                       : std_logic_vector(6 downto 0);
  signal W_CRATEID, D_W_CRATEID, Q_W_CRATEID : std_logic                     := '0';
  signal R_CRATEID, D_R_CRATEID, Q_R_CRATEID : std_logic                     := '0';

begin  --Architecture

-- Decode instruction
  CMDDEV <= unsigned(DEVICE & COMMAND & "00");  -- Variable that looks like the VME commands we input  

  W_LCT_L1A      <= '1' when (CMDDEV = x"1000" and WRITER = '0') else '0';
  W_OTMB_PUSH    <= '1' when (CMDDEV = x"1004" and WRITER = '0') else '0';
  W_PUSH         <= '1' when (CMDDEV = x"1008" and WRITER = '0') else '0';
  W_ALCT_PUSH    <= '1' when (CMDDEV = x"100C" and WRITER = '0') else '0';
  W_INJ_DLY      <= '1' when (CMDDEV = x"1010" and WRITER = '0') else '0';
  W_EXT_DLY      <= '1' when (CMDDEV = x"1014" and WRITER = '0') else '0';
  W_CALLCT_DLY   <= '1' when (CMDDEV = x"1018" and WRITER = '0') else '0';
  W_KILL         <= '1' when (CMDDEV = x"101C" and WRITER = '0') else '0';
  W_CRATEID      <= '1' when (CMDDEV = x"1020" and WRITER = '0') else '0';
  W_NWORDS_DUMMY <= '1' when (CMDDEV = x"1028" and WRITER = '0') else '0';

  R_LCT_L1A      <= '1' when (CMDDEV = x"1000" and WRITER = '1') else '0';
  R_OTMB_PUSH    <= '1' when (CMDDEV = x"1004" and WRITER = '1') else '0';
  R_PUSH         <= '1' when (CMDDEV = x"1008" and WRITER = '1') else '0';
  R_ALCT_PUSH    <= '1' when (CMDDEV = x"100C" and WRITER = '1') else '0';
  R_INJ_DLY      <= '1' when (CMDDEV = x"1010" and WRITER = '1') else '0';
  R_EXT_DLY      <= '1' when (CMDDEV = x"1014" and WRITER = '1') else '0';
  R_CALLCT_DLY   <= '1' when (CMDDEV = x"1018" and WRITER = '1') else '0';
  R_KILL         <= '1' when (CMDDEV = x"101C" and WRITER = '1') else '0';
  R_CRATEID      <= '1' when (CMDDEV = x"1020" and WRITER = '1') else '0';
  R_FW_VERSION   <= '1' when (CMDDEV = x"1024" and WRITER = '1') else '0';
  R_NWORDS_DUMMY <= '1' when (CMDDEV = x"1028" and WRITER = '1') else '0';

-- Write LCT_L1A_DLY
  GEN_LCT_L1A_DLY : for I in 5 downto 0 generate
  begin
    FD_W_LCT_L1A : FDCE port map(LCT_L1A_DLY_INNER(I), STROBE, W_LCT_L1A, RST, INDATA(I));
  end generate GEN_LCT_L1A_DLY;
  LCT_L1A_DLY <= LCT_L1A_DLY_INNER;
  D_W_LCT_L1A <= '1' when (STROBE = '1' and W_LCT_L1A = '1') else '0';
  FD_DTACK_LCT_L1A : FD port map(Q_W_LCT_L1A, SLOWCLK, D_W_LCT_L1A);
  DTACK_INNER <= '0' when (Q_W_LCT_L1A = '1')                else 'Z';

-- Read LCT_L1A_DLY
  OUT_LCT_L1A(15 downto 6) <= (others => '0');
  OUT_LCT_L1A(5 downto 0)  <= LCT_L1A_DLY_INNER when (STROBE = '1' and R_LCT_L1A = '1') else
                              (others => 'Z');

  D_R_LCT_L1A <= '1' when (STROBE = '1' and R_LCT_L1A = '1') else '0';
  FD_R_LCT_L1A : FD port map(Q_R_LCT_L1A, SLOWCLK, D_R_LCT_L1A);
  DTACK_INNER <= '0' when (Q_R_LCT_L1A = '1')                else 'Z';

-- Write OTMB_PUSH_DLY
  GEN_OTMB_PUSH_DLY : for I in 4 downto 0 generate
  begin
    FD_W_OTMB_PUSH : FDCE port map(OTMB_PUSH_DLY_INNER(I), STROBE, W_OTMB_PUSH, RST, INDATA(I));
  end generate GEN_OTMB_PUSH_DLY;
  OTMB_PUSH_DLY <= OTMB_PUSH_DLY_INNER;
  D_W_OTMB_PUSH <= '1' when (STROBE = '1' and W_OTMB_PUSH = '1') else '0';
  FD_DTACK_OTMB_PUSH : FD port map(Q_W_OTMB_PUSH, SLOWCLK, D_W_OTMB_PUSH);
  DTACK_INNER   <= '0' when (Q_W_OTMB_PUSH = '1')                else 'Z';

-- Read OTMB_PUSH_DLY
  OUT_OTMB_PUSH(15 downto 5) <= (others => '0');
  OUT_OTMB_PUSH(4 downto 0)  <= OTMB_PUSH_DLY_INNER when (STROBE = '1' and R_OTMB_PUSH = '1') else
                                (others => 'Z');

  D_R_OTMB_PUSH <= '1' when (STROBE = '1' and R_OTMB_PUSH = '1') else '0';
  FD_R_OTMB_PUSH : FD port map(Q_R_OTMB_PUSH, SLOWCLK, D_R_OTMB_PUSH);
  DTACK_INNER   <= '0' when (Q_R_OTMB_PUSH = '1')                else 'Z';

-- Write PUSH_DLY
  GEN_PUSH_DLY : for I in 4 downto 0 generate
  begin
    FD_W_PUSH : FDCE port map(PUSH_DLY_INNER(I), STROBE, W_PUSH, RST, INDATA(I));
  end generate GEN_PUSH_DLY;
  PUSH_DLY    <= PUSH_DLY_INNER;
  D_W_PUSH    <= '1' when (STROBE = '1' and W_PUSH = '1') else '0';
  FD_DTACK_PUSH : FD port map(Q_W_PUSH, SLOWCLK, D_W_PUSH);
  DTACK_INNER <= '0' when (Q_W_PUSH = '1')                else 'Z';

-- Read PUSH_DLY
  OUT_PUSH(15 downto 5) <= (others => '0');
  OUT_PUSH(4 downto 0)  <= PUSH_DLY_INNER when (STROBE = '1' and R_PUSH = '1') else
                           (others => 'Z');

  D_R_PUSH    <= '1' when (STROBE = '1' and R_PUSH = '1') else '0';
  FD_R_PUSH : FD port map(Q_R_PUSH, SLOWCLK, D_R_PUSH);
  DTACK_INNER <= '0' when (Q_R_PUSH = '1')                else 'Z';

-- Write ALCT_PUSH_DLY
  GEN_ALCT_PUSH_DLY : for I in 4 downto 0 generate
  begin
    FD_W_ALCT_PUSH : FDCE port map(ALCT_PUSH_DLY_INNER(I), STROBE, W_ALCT_PUSH, RST, INDATA(I));
  end generate GEN_ALCT_PUSH_DLY;
  ALCT_PUSH_DLY <= ALCT_PUSH_DLY_INNER;
  D_W_ALCT_PUSH <= '1' when (STROBE = '1' and W_ALCT_PUSH = '1') else '0';
  FD_DTACK_ALCT_PUSH : FD port map(Q_W_ALCT_PUSH, SLOWCLK, D_W_ALCT_PUSH);
  DTACK_INNER   <= '0' when (Q_W_ALCT_PUSH = '1')                else 'Z';

-- Read ALCT_PUSH_DLY
  OUT_ALCT_PUSH(15 downto 5) <= (others => '0');
  OUT_ALCT_PUSH(4 downto 0)  <= ALCT_PUSH_DLY_INNER when (STROBE = '1' and R_ALCT_PUSH = '1') else
                                (others => 'Z');

  D_R_ALCT_PUSH <= '1' when (STROBE = '1' and R_ALCT_PUSH = '1') else '0';
  FD_R_ALCT_PUSH : FD port map(Q_R_ALCT_PUSH, SLOWCLK, D_R_ALCT_PUSH);
  DTACK_INNER   <= '0' when (Q_R_ALCT_PUSH = '1')                else 'Z';

-- Write INJ_DLY
  GEN_INJ_DLY : for I in 4 downto 0 generate
  begin
    FD_W_INJ_DLY : FDCE port map(INJ_DLY_INNER(I), STROBE, W_INJ_DLY, RST, INDATA(I));
  end generate GEN_INJ_DLY;
  INJ_DLY     <= INJ_DLY_INNER;
  D_W_INJ_DLY <= '1' when (STROBE = '1' and W_INJ_DLY = '1') else '0';
  FD_DTACK_INJ_DLY : FD port map(Q_W_INJ_DLY, SLOWCLK, D_W_INJ_DLY);
  DTACK_INNER <= '0' when (Q_W_INJ_DLY = '1')                else 'Z';

-- Read INJ_DLY
  OUT_INJ_DLY(15 downto 5) <= (others => '0');
  OUT_INJ_DLY(4 downto 0)  <= INJ_DLY_INNER when (STROBE = '1' and R_INJ_DLY = '1') else
                              (others => 'Z');

  D_R_INJ_DLY <= '1' when (STROBE = '1' and R_INJ_DLY = '1') else '0';
  FD_R_INJ_DLY : FD port map(Q_R_INJ_DLY, SLOWCLK, D_R_INJ_DLY);
  DTACK_INNER <= '0' when (Q_R_INJ_DLY = '1')                else 'Z';

-- Write EXT_DLY
  GEN_EXT_DLY : for I in 4 downto 0 generate
  begin
    FD_W_EXT_DLY : FDCE port map(EXT_DLY_INNER(I), STROBE, W_EXT_DLY, RST, INDATA(I));
  end generate GEN_EXT_DLY;
  EXT_DLY     <= EXT_DLY_INNER;
  D_W_EXT_DLY <= '1' when (STROBE = '1' and W_EXT_DLY = '1') else '0';
  FD_DTACK_EXT_DLY : FD port map(Q_W_EXT_DLY, SLOWCLK, D_W_EXT_DLY);
  DTACK_INNER <= '0' when (Q_W_EXT_DLY = '1')                else 'Z';

-- Read EXT_DLY
  OUT_EXT_DLY(15 downto 5) <= (others => '0');
  OUT_EXT_DLY(4 downto 0)  <= EXT_DLY_INNER when (STROBE = '1' and R_EXT_DLY = '1') else
                              (others => 'Z');

  D_R_EXT_DLY <= '1' when (STROBE = '1' and R_EXT_DLY = '1') else '0';
  FD_R_EXT_DLY : FD port map(Q_R_EXT_DLY, SLOWCLK, D_R_EXT_DLY);
  DTACK_INNER <= '0' when (Q_R_EXT_DLY = '1')                else 'Z';

-- Write CALLCT_DLY
  GEN_CALLCT_DLY : for I in 3 downto 0 generate
  begin
    FD_W_CALLCT_DLY : FDCE port map(CALLCT_DLY_INNER(I), STROBE, W_CALLCT_DLY, RST, INDATA(I));
  end generate GEN_CALLCT_DLY;
  CALLCT_DLY     <= CALLCT_DLY_INNER;
  D_W_CALLCT_DLY <= '1' when (STROBE = '1' and W_CALLCT_DLY = '1') else '0';
  FD_DTACK_CALLCT_DLY : FD port map(Q_W_CALLCT_DLY, SLOWCLK, D_W_CALLCT_DLY);
  DTACK_INNER    <= '0' when (Q_W_CALLCT_DLY = '1')                else 'Z';

-- Read CALLCT_DLY
  OUT_CALLCT_DLY(15 downto 4) <= (others => '0');
  OUT_CALLCT_DLY(3 downto 0)  <= CALLCT_DLY_INNER when (STROBE = '1' and R_CALLCT_DLY = '1') else
                                 (others => 'Z');

  D_R_CALLCT_DLY <= '1' when (STROBE = '1' and R_CALLCT_DLY = '1') else '0';
  FD_R_CALLCT_DLY : FD port map(Q_R_CALLCT_DLY, SLOWCLK, D_R_CALLCT_DLY);
  DTACK_INNER    <= '0' when (Q_R_CALLCT_DLY = '1')                else 'Z';

-- Write NWORDS_DUMMY
  GEN_NWORDS_DUMMY : for I in 15 downto 0 generate
  begin
    NWORDS_DUMMY_PRE(I) <= RST when NWORDS_DUMMY_DEF(I) = '1' else '0';
    NWORDS_DUMMY_RST(I) <= RST when NWORDS_DUMMY_DEF(I) = '0' else '0';
    FD_W_NWORDS_DUMMY : FDCPE port map(NWORDS_DUMMY_INNER(I), STROBE, W_NWORDS_DUMMY,
                                       NWORDS_DUMMY_RST(I), INDATA(I), NWORDS_DUMMY_PRE(I));
  end generate GEN_NWORDS_DUMMY;
  NWORDS_DUMMY     <= NWORDS_DUMMY_INNER;
  D_W_NWORDS_DUMMY <= '1' when (STROBE = '1' and W_NWORDS_DUMMY = '1') else '0';
  FD_DTACK_NWORDS_DUMMY : FD port map(Q_W_NWORDS_DUMMY, SLOWCLK, D_W_NWORDS_DUMMY);
  DTACK_INNER      <= '0' when (Q_W_NWORDS_DUMMY = '1')                else 'Z';

-- Read NWORDS_DUMMY
  OUT_NWORDS_DUMMY <= NWORDS_DUMMY_INNER when (STROBE = '1' and R_NWORDS_DUMMY = '1') else
                      (others => 'Z');

  D_R_NWORDS_DUMMY <= '1' when (STROBE = '1' and R_NWORDS_DUMMY = '1') else '0';
  FD_R_NWORDS_DUMMY : FD port map(Q_R_NWORDS_DUMMY, SLOWCLK, D_R_NWORDS_DUMMY);
  DTACK_INNER      <= '0' when (Q_R_NWORDS_DUMMY = '1')                else 'Z';

-- Write KILL
  GEN_KILL : for I in NFEB+2 downto 1 generate
  begin
    FD_W_KILL : FDPE port map(KILL_INNER(I), STROBE, W_KILL, INDATA(I-1), RST);
  end generate GEN_KILL;
  KILL        <= KILL_INNER;
  D_W_KILL    <= '1' when (STROBE = '1' and W_KILL = '1') else '0';
  FD_DTACK_KILL : FD port map(Q_W_KILL, SLOWCLK, D_W_KILL);
  DTACK_INNER <= '0' when (Q_W_KILL = '1')                else 'Z';

-- Read KILL
  OUT_KILL(15 downto NFEB+2) <= (others => '0');
  OUT_KILL(NFEB+1 downto 0)  <= KILL_INNER when (STROBE = '1' and R_KILL = '1') else
                                (others => 'Z');

  D_R_KILL    <= '1' when (STROBE = '1' and R_KILL = '1') else '0';
  FD_R_KILL : FD port map(Q_R_KILL, SLOWCLK, D_R_KILL);
  DTACK_INNER <= '0' when (Q_R_KILL = '1')                else 'Z';

-- Write CRATEID
  GEN_CRATEID : for I in 6 downto 0 generate
  begin
    FD_W_CRATEID : FDCE port map(CRATEID_INNER(I), STROBE, W_CRATEID, RST, INDATA(I));
  end generate GEN_CRATEID;
  CRATEID     <= CRATEID_INNER;
  D_W_CRATEID <= '1' when (STROBE = '1' and W_CRATEID = '1') else '0';
  FD_DTACK_CRATEID : FD port map(Q_W_CRATEID, SLOWCLK, D_W_CRATEID);
  DTACK_INNER <= '0' when (Q_W_CRATEID = '1')                else 'Z';

-- Read CRATEID
  OUT_CRATEID(15 downto 7) <= (others => '0');
  OUT_CRATEID(6 downto 0)  <= CRATEID_INNER when (STROBE = '1' and R_CRATEID = '1') else
                              (others => 'Z');

  D_R_CRATEID <= '1' when (STROBE = '1' and R_CRATEID = '1') else '0';
  FD_R_CRATEID : FD port map(Q_R_CRATEID, SLOWCLK, D_R_CRATEID);
  DTACK_INNER <= '0' when (Q_R_CRATEID = '1')                else 'Z';

-- Read FW_VERSION
  OUT_FW_VERSION <= FW_VERSION when (STROBE = '1' and R_FW_VERSION = '1') else (others => 'Z');

  D_R_FW_VERSION <= '1' when (STROBE = '1' and R_FW_VERSION = '1') else '0';
  FD_R_FW_VERSION : FD port map(Q_R_FW_VERSION, SLOWCLK, D_R_FW_VERSION);
  DTACK_INNER    <= '0' when (Q_R_FW_VERSION = '1')                else 'Z';

-- General assignments
  OUTDATA <= OUT_LCT_L1A when R_LCT_L1A = '1' else
             OUT_OTMB_PUSH    when R_OTMB_PUSH = '1'    else
             OUT_PUSH         when R_PUSH = '1'         else
             OUT_ALCT_PUSH    when R_ALCT_PUSH = '1'    else
             OUT_INJ_DLY      when R_INJ_DLY = '1'      else
             OUT_EXT_DLY      when R_EXT_DLY = '1'      else
             OUT_CALLCT_DLY   when R_CALLCT_DLY = '1'   else
             OUT_KILL         when R_KILL = '1'         else
             OUT_FW_VERSION   when R_FW_VERSION = '1'   else
             OUT_CRATEID      when R_CRATEID = '1'      else
             OUT_NWORDS_DUMMY when R_NWORDS_DUMMY = '1' else
             (others => 'L');
  DTACK <= DTACK_INNER;
  
end VMECONFREGS_Arch;
