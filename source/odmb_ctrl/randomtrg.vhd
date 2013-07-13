library unisim;
library ieee;
library work;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
library hdlmacro; use hdlmacro.hdlmacro.all;

entity RANDOMTRG is
  generic (
    NFEB : integer range 1 to 7 := 5  -- Number of DCFEBS, 7 in the final design
    );  
  port (
    CLK         : in std_logic;
    RST         : in std_logic;

    DIN         : in std_logic;
    DRCK        : in std_logic;
    SEL2        : in std_logic;
    SHIFT       : in std_logic;
    UPDATE      : in std_logic;

    FLOAD       : in std_logic;      -- INSTR19
    FTSTART     : in std_logic;      -- INSTR20
    FBURST      : in std_logic;      -- INSTR32

    ENL1RLS     : in std_logic;
    
    PREL1RLS    : out std_logic;    
    SELRAN      : out std_logic;
    GTRGOUT     : out std_logic;
    LCTOUT      : out std_logic_vector(NFEB downto 0);
    PULSE       : out std_logic
    );

end RANDOMTRG;

architecture RANDOMTRG_Arch of RANDOMTRG is

  signal LOGICH : std_logic := '1';

-- Page 1 -> Page 5
  type LCT_PIPE_TYPE is array (NFEB downto 1) of std_logic_vector(161 downto 0);
  signal LCT_PIPE : LCT_PIPE_TYPE;
  signal FDBK : std_logic_vector(NFEB downto 0);
  type OR_TYPE is array (NFEB downto 1) of std_logic_vector(8 downto 1);
  signal LCT_OR : OR_TYPE;
  type AND_TYPE is array (NFEB downto 1) of std_logic_vector(3 downto 1);
  signal LCT_AND : OR_TYPE;
  signal LCT_D, LCT_CLR : std_logic_vector(NFEB downto 1);
  type LCT_TYPE is array (NFEB downto 1) of std_logic_vector(16 downto 0);
  signal LCT_Q : LCT_TYPE;
  signal SELRAN_INNER : std_logic;
-- Page 6
  signal LCT_AB : std_logic_vector(87 downto 0);
-- Page 7
  signal GTRG_PIPE : std_logic_vector(167 downto 0);
  signal GTRG_OR : std_logic_vector(8 downto 1);
  signal GTRG_AND : std_logic_vector(3 downto 1);
-- Page 8
  signal  GTRGB_PIPE : std_logic_vector(87 downto 0);
  signal  EVNT_CNT_CEO, EVNT_CNT_TC, EVNT_CNT_CLR : std_logic;
  signal  EVNT : std_logic_vector(15 downto 0);
  signal  BURST1000, EVNT1000, FINISH1000 : std_logic;
  signal  PPREL1RLS, PREL1RLS_INNER, PREL1RLS_RST, PREL1RLS_Q : std_logic;
-- Page 9
  signal  FBA : std_logic_vector(35 downto 0);
  signal  FBB : std_logic_vector(36 downto 0);
  signal  FBC : std_logic_vector(39 downto 0);
  signal  FBD : std_logic_vector(41 downto 0);
-- Page 10
  signal  FBY : std_logic_vector(34 downto 0);
  signal  FBI : std_logic_vector(38 downto 0);
  signal  FBJ : std_logic_vector(44 downto 0);
  signal  FBK : std_logic_vector(45 downto 0);
-- Page 11
  signal  FBL : std_logic_vector(54 downto 0);
  signal  FBM : std_logic_vector(56 downto 0);
  signal  FBN : std_logic_vector(61 downto 0);
  signal  FBO : std_logic_vector(62 downto 0);
-- Page 12
  signal  FBE : std_logic_vector(47 downto 0);
  signal  FBF : std_logic_vector(49 downto 0);
  signal  FBG : std_logic_vector(52 downto 0);
  signal  FBH : std_logic_vector(55 downto 0);
-- Page 13
  signal  FBP : std_logic_vector(57 downto 0);
  signal  FBQ : std_logic_vector(60 downto 0);
  signal  FBR : std_logic_vector(63 downto 0);
-- Page 14
  signal  FBS : std_logic_vector(65 downto 0);
  signal  FBT : std_logic_vector(68 downto 0);
  signal  FBU : std_logic_vector(71 downto 0);
-- Page 15
  signal  FBV : std_logic_vector(73 downto 0);
  signal  FBW : std_logic_vector(79 downto 0);
  signal  FBX : std_logic_vector(81 downto 0);
-- Page 16
  signal SHR_EN, DR_CLK : std_logic;
  signal SHR : std_logic_vector(18 downto 0);
  signal DR : std_logic_vector(18 downto 1);
  signal GTRG_SEL : std_logic_vector(3 downto 1);
  type SEL_TYPE is array (NFEB downto 1) of std_logic_vector(3 downto 1); 
  signal LCT_SEL : SEL_TYPE;

begin  --Architecture

-- Page 1 -> Page 5

-- Generate LCT_PIPE
  GEN1_LCT_PIPE : for I in 1 to nfeb generate
    begin
      FDBK(I) <= LCT_PIPE(I)(161) xnor LCT_PIPE(I)(143);
      LCT_PIPE(I)(0) <= FDBK(I);
      GEN2_LCT_PIPE : for J in 1 to 161 generate
        begin
          FD_J : FD port map(LCT_PIPE(I)(J), CLK, LCT_PIPE(I)(J-1));
        end generate GEN2_LCT_PIPE;
    end generate GEN1_LCT_PIPE;

-- Generate LCT_D

-- LCT_D(1) (Page 1)
--          LCT_PIPE(1)           LCT_AB
-- SEL3 =>  18  34  120           10
-- SEL2 =>  52                    44
-- SEL1 =>  86
-- AND2 =>  1   69  103   137     27   60                             

-- Generate SELRAN (page 1)
SELRAN <= SELRAN_INNER;

-- Generate LCT_D(1)
  LCT_OR(1)(1) <= LCT_PIPE(1)(18) or LCT_SEL(1)(3);
  LCT_OR(1)(2) <= LCT_PIPE(1)(34) or LCT_SEL(1)(3);
  LCT_OR(1)(3) <= LCT_PIPE(1)(120) or LCT_SEL(1)(3);
  LCT_OR(1)(4) <= LCT_AB(10) or LCT_SEL(1)(3);
  LCT_OR(1)(5) <= LCT_PIPE(1)(52) or LCT_SEL(1)(2);
  LCT_OR(1)(6) <= LCT_AB(44) or LCT_SEL(1)(2);
  LCT_OR(1)(7) <= LCT_PIPE(1)(86) or LCT_SEL(1)(1);
  LCT_OR(1)(8) <= LCT_SEL(1)(3) or LCT_SEL(1)(2) or LCT_SEL(1)(1);
  LCT_AND(1)(1) <= OR_REDUCE(LCT_OR(1)(7 downto 1));
  LCT_AND(1)(2) <= LCT_PIPE(1)(1) and LCT_PIPE(1)(69) and LCT_PIPE(1)(103) and LCT_PIPE(1)(137) and LCT_AB(27) and LCT_AB(60);
  LCT_AND(1)(3) <= LCT_AND(1)(1) and LCT_AND(1)(2) and LCT_OR(1)(8) and SELRAN_INNER;

-- LCT_D(2) (Page 2)
--          LCT_PIPE(2)           LCT_AB
-- SEL3 =>  18  86  120           10
-- SEL2 =>  52  68        
-- SEL1 =>                        27
-- AND2 =>  1   35  103  137      44   60                             

-- Generate LCT_D(2)
  LCT_OR(2)(1) <= LCT_PIPE(2)(18) or LCT_SEL(2)(3);
  LCT_OR(2)(2) <= LCT_PIPE(2)(86) or LCT_SEL(2)(3);
  LCT_OR(2)(3) <= LCT_PIPE(2)(120) or LCT_SEL(2)(3);
  LCT_OR(2)(4) <= LCT_AB(10) or LCT_SEL(2)(3);
  LCT_OR(2)(5) <= LCT_PIPE(2)(52) or LCT_SEL(2)(2);
  LCT_OR(2)(6) <= LCT_PIPE(2)(68) or LCT_SEL(2)(2);
  LCT_OR(2)(7) <= LCT_AB(27) or LCT_SEL(2)(1);
  LCT_OR(2)(8) <= LCT_SEL(2)(3) or LCT_SEL(2)(2) or LCT_SEL(2)(1);
  LCT_AND(2)(1) <= OR_REDUCE(LCT_OR(2)(7 downto 1));
  LCT_AND(2)(2) <= LCT_PIPE(2)(1) and LCT_PIPE(2)(35) and LCT_PIPE(2)(103) and LCT_PIPE(2)(137) and LCT_AB(44) and LCT_AB(60);
  LCT_AND(2)(3) <= LCT_AND(2)(1) and LCT_AND(2)(2) and LCT_OR(2)(8) and SELRAN_INNER;

-- LCT_D(3) (Page 3)
--          LCT_PIPE(3)           LCT_AB
-- SEL3 =>  52  102               27   60
-- SEL2 =>  18  86        
-- SEL1 =>  120                   
-- AND2 =>  1   35  69  137       10   44                            

-- Generate LCT_D(3)
  LCT_OR(3)(1) <= LCT_PIPE(3)(52) or LCT_SEL(3)(3);
  LCT_OR(3)(2) <= LCT_PIPE(3)(102) or LCT_SEL(3)(3);
  LCT_OR(3)(3) <= LCT_AB(27) or LCT_SEL(3)(3);
  LCT_OR(3)(4) <= LCT_AB(60) or LCT_SEL(3)(3);
  LCT_OR(3)(5) <= LCT_PIPE(3)(18) or LCT_SEL(3)(2);
  LCT_OR(3)(6) <= LCT_PIPE(3)(86) or LCT_SEL(3)(2);
  LCT_OR(3)(7) <= LCT_PIPE(3)(120) or LCT_SEL(3)(1);
  LCT_OR(3)(8) <= LCT_SEL(3)(3) or LCT_SEL(3)(2) or LCT_SEL(3)(1);
  LCT_AND(3)(1) <= OR_REDUCE(LCT_OR(3)(7 downto 1));
  LCT_AND(3)(2) <= LCT_PIPE(3)(1) and LCT_PIPE(3)(35) and LCT_PIPE(3)(69) and LCT_PIPE(3)(137) and LCT_AB(10) and LCT_AB(44);
  LCT_AND(3)(3) <= LCT_AND(3)(1) and LCT_AND(3)(2) and LCT_OR(3)(8) and SELRAN_INNER;

-- LCT_D(4) (Page 4)
--          LCT_PIPE(4)           LCT_AB
-- SEL3 =>  52  86  136           44              
-- SEL2 =>  18  120        
-- SEL1 =>                        60                   
-- AND2 =>  1   35  69  103       10   27                            

-- Generate LCT_D(4)
  LCT_OR(4)(1) <= LCT_PIPE(4)(52) or LCT_SEL(4)(3);
  LCT_OR(4)(2) <= LCT_PIPE(4)(86) or LCT_SEL(4)(3);
  LCT_OR(4)(3) <= LCT_PIPE(4)(136) or LCT_SEL(4)(3);
  LCT_OR(4)(4) <= LCT_AB(44) or LCT_SEL(4)(3);
  LCT_OR(4)(5) <= LCT_PIPE(4)(18) or LCT_SEL(4)(2);
  LCT_OR(4)(6) <= LCT_PIPE(4)(120) or LCT_SEL(4)(2);
  LCT_OR(4)(7) <= LCT_AB(60) or LCT_SEL(4)(1);
  LCT_OR(4)(8) <= LCT_SEL(4)(3) or LCT_SEL(4)(2) or LCT_SEL(4)(1);
  LCT_AND(4)(1) <= OR_REDUCE(LCT_OR(4)(7 downto 1));
  LCT_AND(4)(2) <= LCT_PIPE(4)(1) and LCT_PIPE(4)(35) and LCT_PIPE(4)(69) and LCT_PIPE(4)(103) and LCT_AB(10) and LCT_AB(27);
  LCT_AND(4)(3) <= LCT_AND(4)(1) and LCT_AND(4)(2) and LCT_OR(4)(8) and SELRAN_INNER;

-- LCT_D(5) (Page 5)
--          LCT_PIPE(5)           LCT_AB
-- SEL3 =>  52                    10   44   60              
-- SEL2 =>  18  86        
-- SEL1 =>  120                   
-- AND2 =>  1   35  69  103  137  27                            

-- Generate LCT_D(4)
  LCT_OR(5)(1) <= LCT_PIPE(5)(52) or LCT_SEL(5)(3);
  LCT_OR(5)(2) <= LCT_AB(10) or LCT_SEL(5)(3);
  LCT_OR(5)(3) <= LCT_AB(44) or LCT_SEL(5)(3);
  LCT_OR(5)(4) <= LCT_AB(60) or LCT_SEL(5)(3);
  LCT_OR(5)(5) <= LCT_PIPE(5)(18) or LCT_SEL(5)(2);
  LCT_OR(5)(6) <= LCT_PIPE(5)(86) or LCT_SEL(5)(2);
  LCT_OR(5)(7) <= LCT_PIPE(5)(120) or LCT_SEL(5)(1);
  LCT_OR(5)(8) <= LCT_SEL(5)(3) or LCT_SEL(5)(2) or LCT_SEL(5)(1);
  LCT_AND(5)(1) <= OR_REDUCE(LCT_OR(5)(7 downto 1));
  LCT_AND(5)(2) <= LCT_PIPE(5)(1) and LCT_PIPE(5)(35) and LCT_PIPE(5)(69) and LCT_PIPE(5)(103) and LCT_PIPE(5)(137) and LCT_AB(27);
  LCT_AND(5)(3) <= LCT_AND(5)(1) and LCT_AND(5)(2) and LCT_OR(5)(8) and SELRAN_INNER;
  LCT_D(5) <= LCT_AND(5)(3);

-- Generate LCT_D(6) (Not yet implemented))
--  LCT_D(6) <= LCT_AND(5)(3);

-- Generate LCT_D(7) (Not yet implemented))
--  LCT_D(7) <= LCT_AND(5)(3);
  
-- Generate LCTOUT (Page 1 -> Page 5)
  
  GEN1_LCTOUT : for I in 1 to NFEB generate
    begin
--     LCT_Q(I)(0) <= LCT_D(I);
     FDR_I : FDR port map(LCT_Q(I)(0), CLK, LCT_CLR(I), LCT_D(I));
     GEN2_LCTOUT : for J in 1 to 16 generate
      FD_J : FD port map(LCT_Q(I)(J), CLK, LCT_Q(I)(J-1));
     end generate GEN2_LCTOUT;
     LCT_CLR(I) <= LCT_Q(I)(0) or LCT_Q(I)(1);
    end generate GEN1_LCTOUT;
  
-- Page 6

-- Generate LCT_AB
   LCT_AB(0) <= LCT_AB(87) xnor LCT_AB(74);
   GEN_LCT_AB : for I in 1 to 87 generate
     begin
       FD_I : FD port map(LCT_AB(I), CLK, LCT_AB(I-1));
     end generate GEN_LCT_AB;

-- Page 7

-- Generate GTRG_PIPE
   GTRG_PIPE(0) <= GTRG_PIPE(167) xnor GTRG_PIPE(161);
   GEN_GTRG_PIPE : for I in 1 to 167 generate
     begin
       FD_I : FD port map(GTRG_PIPE(I), CLK, GTRG_PIPE(I-1));
     end generate GEN_GTRG_PIPE;

-- Generate GTRGOUT
  GTRG_OR(1) <= FBO(62) or GTRG_SEL(3);
  GTRG_OR(2) <= FBN(61) or GTRG_SEL(3);
  GTRG_OR(3) <= FBM(56) or GTRG_SEL(3);
  GTRG_OR(4) <= FBL(54) or GTRG_SEL(3);
  GTRG_OR(5) <= FBY(34) or GTRG_SEL(2);
  GTRG_OR(6) <= FBK(45) or GTRG_SEL(2);
  GTRG_OR(7) <= FBJ(44) or GTRG_SEL(1);
  GTRG_OR(8) <= GTRG_SEL(3) or GTRG_SEL(2) or GTRG_SEL(1);
  GTRG_AND(1) <= OR_REDUCE(GTRG_OR(7 downto 1));
  GTRG_AND(2) <= GTRG_PIPE(167) and FBA(35) and FBB(36) and FBC(39) and FBD(41) and FBI(38);
  GTRG_AND(3) <= GTRG_AND(1) and GTRG_AND(2) and GTRG_OR(8) and SELRAN_INNER;

  PPREL1RLS <= GTRG_AND(1) and GTRG_AND(2) and GTRG_OR(8) and ENL1RLS;

-- Page 8

-- Generate GTRGB_PIPE
   GTRGB_PIPE(0) <= GTRGB_PIPE(74) xnor GTRGB_PIPE(87);
   GEN_GTRGB_PIPE : for I in 1 to 87 generate
     begin
       FD_I : FD port map(GTRGB_PIPE(I), CLK, GTRGB_PIPE(I-1));
     end generate GEN_GTRGB_PIPE;

-- Generate BURST1000

   FDC_B1000 : FDC port map(BURST1000, CLK, FINISH1000, LOGICH);
   EVNT_CNT : CB16CE port map(EVNT_CNT_CEO, EVNT, EVNT_CNT_TC, CLK, LOGICH, EVNT_CNT_CLR);
   EVNT1000 <= '1' when (EVNT(9 downto 7) = "111") else '0';
   FD_F1000 : FD port map(FINISH1000, CLK, EVNT1000);

-- Generate PREL1RLS

   FD_PREL1RLS : FD port map(PREL1RLS_Q, CLK, PREL1RLS_INNER);
   PREL1RLS_RST <=  PREL1RLS_INNER or PREL1RLS_Q; 
   FDR_PREL1RLS : FDR port map(PREL1RLS_INNER, CLK, PREL1RLS_RST, PPREL1RLS);
   PREL1RLS <= PREL1RLS_INNER;
   
-- Page 9

-- LFSR35 (FBA)
   FBA(0) <= FBA(35) xnor FBA(33);
   GEN_LFSR35 : for I in 1 to 35 generate
     begin
       FD_I : FD port map(FBA(I), CLK, FBA(I-1));
     end generate GEN_LFSR35;

-- LFSR36 (FBB)
   FBB(0) <= FBB(36) xnor FBB(25);
   GEN_LFSR36 : for I in 1 to 36 generate
     begin
       FD_I : FD port map(FBB(I), CLK, FBB(I-1));
     end generate GEN_LFSR36;

-- LFSR39 (FBC)
   FBC(0) <= FBC(39) xnor FBC(35);
   GEN_LFSR39 : for I in 1 to 39 generate
     begin
       FD_I : FD port map(FBC(I), CLK, FBC(I-1));
     end generate GEN_LFSR39;

-- LFSR41 (FBD)
   FBD(0) <= FBD(41) xnor FBD(38);
   GEN_LFSR41 : for I in 1 to 41 generate
     begin
       FD_I : FD port map(FBD(I), CLK, FBD(I-1));
     end generate GEN_LFSR41;

-- Page 10

-- LFSR34 (FBY)
   FBY(0) <= FBY(34) xnor FBY(27) xnor FBY(2) xnor FBY(1);
   GEN_LFSR34 : for I in 1 to 34 generate
     begin
       FD_I : FD port map(FBY(I), CLK, FBY(I-1));
     end generate GEN_LFSR34;

-- LFSR38 (FBI)
   FBI(0) <= FBI(38) xnor FBI(6) xnor FBI(5) xnor FBI(1);
   GEN_LFSR38 : for I in 1 to 38 generate
     begin
       FD_I : FD port map(FBI(I), CLK, FBI(I-1));
     end generate GEN_LFSR38;

-- LFSR44 (FBJ)
   FBJ(0) <= FBJ(44) xnor FBJ(43) xnor FBJ(18) xnor FBJ(17);
   GEN_LFSR44 : for I in 1 to 44 generate
     begin
       FD_I : FD port map(FBJ(I), CLK, FBJ(I-1));
     end generate GEN_LFSR44;

-- LFSR45 (FBK)
   FBK(0) <= FBK(45) xnor FBK(44) xnor FBK(42) xnor FBK(41);
   GEN_LFSR45 : for I in 1 to 45 generate
     begin
       FD_I : FD port map(FBK(I), CLK, FBK(I-1));
     end generate GEN_LFSR45;

-- Page 11

-- LFSR54 (FBL)
   FBL(0) <= FBL(54) xnor FBL(53) xnor FBL(18) xnor FBL(17);
   GEN_LFSR54 : for I in 1 to 54 generate
     begin
       FD_I : FD port map(FBL(I), CLK, FBL(I-1));
     end generate GEN_LFSR54;

-- LFSR56 (FBM)
   FBM(0) <= FBM(56) xnor FBM(55) xnor FBM(35) xnor FBM(34);
   GEN_LFSR56 : for I in 1 to 56 generate
     begin
       FD_I : FD port map(FBM(I), CLK, FBM(I-1));
     end generate GEN_LFSR56;

-- LFSR61 (FBN)
   FBN(0) <= FBN(61) xnor FBN(60) xnor FBN(46) xnor FBN(45);
   GEN_LFSR61 : for I in 1 to 61 generate
     begin
       FD_I : FD port map(FBN(I), CLK, FBN(I-1));
     end generate GEN_LFSR61;

-- LFSR62 (FBO)
   FBO(0) <= FBO(62) xnor FBO(61) xnor FBO(6) xnor FBO(5);
   GEN_LFSR62 : for I in 1 to 62 generate
     begin
       FD_I : FD port map(FBO(I), CLK, FBO(I-1));
     end generate GEN_LFSR62;

-- Page 12

-- LFSR47 (FBE)
   FBE(0) <= FBE(47) xnor FBE(42);
   GEN_LFSR47 : for I in 1 to 47 generate
     begin
       FD_I : FD port map(FBE(I), CLK, FBE(I-1));
     end generate GEN_LFSR47;

-- LFSR49 (FBF)
   FBF(0) <= FBF(49) xnor FBF(40);
   GEN_LFSR49 : for I in 1 to 49 generate
     begin
       FD_I : FD port map(FBF(I), CLK, FBF(I-1));
     end generate GEN_LFSR49;

-- LFSR52 (FBG)
   FBG(0) <= FBG(52) xnor FBG(49);
   GEN_LFSR52 : for I in 1 to 52 generate
     begin
       FD_I : FD port map(FBG(I), CLK, FBG(I-1));
     end generate GEN_LFSR52;

-- LFSR55 (FBH)
   FBH(0) <= FBH(55) xnor FBH(31);
   GEN_LFSR55 : for I in 1 to 55 generate
     begin
       FD_I : FD port map(FBH(I), CLK, FBH(I-1));
     end generate GEN_LFSR55;

-- Page 13

-- LFSR57 (FBP)
   FBP(0) <= FBP(57) xnor FBP(50);
   GEN_LFSR57 : for I in 1 to 57 generate
     begin
       FD_I : FD port map(FBP(I), CLK, FBP(I-1));
     end generate GEN_LFSR57;

-- LFSR60 (FBQ)
   FBQ(0) <= FBQ(60) xnor FBQ(59);
   GEN_LFSR60 : for I in 1 to 60 generate
     begin
       FD_I : FD port map(FBQ(I), CLK, FBQ(I-1));
     end generate GEN_LFSR60;

-- LFSR63 (FBR)
   FBR(0) <= FBR(63) xnor FBR(62);
   GEN_LFSR63 : for I in 1 to 63 generate
     begin
       FD_I : FD port map(FBR(I), CLK, FBR(I-1));
     end generate GEN_LFSR63;

-- Page 14

-- LFSR65 (FBS)
   FBS(0) <= FBS(65) xnor FBS(47);
   GEN_LFSR65 : for I in 1 to 65 generate
     begin
       FD_I : FD port map(FBS(I), CLK, FBS(I-1));
     end generate GEN_LFSR65;

-- LFSR68 (FBT)
   FBT(0) <= FBT(68) xnor FBT(59);
   GEN_LFSR68 : for I in 1 to 68 generate
     begin
       FD_I : FD port map(FBT(I), CLK, FBT(I-1));
     end generate GEN_LFSR68;

-- LFSR71 (FBU)
   FBU(0) <= FBU(71) xnor FBU(65);
   GEN_LFSR71 : for I in 1 to 71 generate
     begin
       FD_I : FD port map(FBU(I), CLK, FBU(I-1));
     end generate GEN_LFSR71;

-- Page 15

-- LFSR73 (FBV)
   FBV(0) <= FBV(73) xnor FBV(48);
   GEN_LFSR73 : for I in 1 to 73 generate
     begin
       FD_I : FD port map(FBV(I), CLK, FBV(I-1));
     end generate GEN_LFSR73;

-- LFSR79 (FBW)
   FBW(0) <= FBW(79) xnor FBW(70);
   GEN_LFSR79 : for I in 1 to 79 generate
     begin
       FD_I : FD port map(FBW(I), CLK, FBW(I-1));
     end generate GEN_LFSR79;

-- LFSR81 (FBX)
   FBX(0) <= FBX(81) xnor FBX(77);
   GEN_LFSR81 : for I in 1 to 81 generate
     begin
       FD_I : FD port map(FBX(I), CLK, FBX(I-1));
     end generate GEN_LFSR81;

-- Page 16

   SHR_EN <= SHIFT and SEL2 and FLOAD;
   DR_CLK <= UPDATE and SEL2 and FLOAD;

   SHR(0) <= DIN;
   GEN_SHR : for I in 1 to 18 generate
     begin
       FDCE_I : FDCE port map(SHR(I), DRCK, SHR_EN, RST, SHR(I-1));
       FDC_I : FDC port map(DR(I), DR_CLK, RST, SHR(I));
     end generate GEN_SHR;

   GTRG_SEL(3 downto 1) <= DR(3 downto 1);
   LCT_SEL(5)(3 downto 1) <= DR(6 downto 4);
   LCT_SEL(4)(3 downto 1) <= DR(9 downto 7);
   LCT_SEL(3)(3 downto 1) <= DR(12 downto 10);
   LCT_SEL(2)(3 downto 1) <= DR(15 downto 13);
   LCT_SEL(1)(3 downto 1) <= DR(18 downto 16);
   
end RANDOMTRG_Arch;
