library ieee;
library work;
use work.Latches_Flipflops.all;
--use work.CFEBJTAG;
--use work.Command_Module;
use ieee.std_logic_1164.all;
Library unisim;
use UNISIM.vcomponents.all;
--use UNISIM.vpck.all;
use UNISIM.all;


entity dcfeb_v6 is
  generic (
    dcfeb_addr : std_logic_vector(3 downto 0) := "1000"  -- DCFEB address
    );  
port
	(
	  clk: IN STD_LOGIC;
	  dcfebclk: IN STD_LOGIC;
	  rst: IN STD_LOGIC;
	  l1a : IN STD_LOGIC;
	  l1a_match : IN STD_LOGIC;
	  tx_ack : IN STD_LOGIC;
	  dcfeb_dv : OUT STD_LOGIC;
    dcfeb_data : OUT STD_LOGIC_VECTOR(15 downto 0);
    adc_mask: OUT STD_LOGIC_VECTOR(11 downto 0);
	  dcfeb_fsel: OUT STD_LOGIC_VECTOR(32 downto 0);
	  dcfeb_jtag_ir: OUT STD_LOGIC_VECTOR(9 downto 0);
	  trst: IN STD_LOGIC;
	  tck: IN STD_LOGIC;
	  tms: IN STD_LOGIC;
	  tdi: IN STD_LOGIC;
    rtn_shft_en : OUT STD_LOGIC;
	  tdo: OUT STD_LOGIC);

end dcfeb_v6 ;


ARCHITECTURE dcfeb_v6_arch of dcfeb_v6  is


COMPONENT dcfeb_data_gen is
   port(
  
   clk : in std_logic;
   dcfebclk : in std_logic;
   rst : in std_logic;
   l1a : in std_logic;
   l1a_match : in std_logic;
   tx_ack : in std_logic;
   dcfeb_addr : in std_logic_vector(3 downto 0);
   dcfeb_dv : out std_logic;
   dcfeb_data : out std_logic_vector(15 downto 0)
	
	);

end COMPONENT; 

COMPONENT tdo_mux
  port(
  
    TDO_0C : in std_ulogic;
    TDO_17 : in std_ulogic;
    FSEL : in std_logic_vector(32 downto 0);
    TDO : out std_ulogic);

end COMPONENT;

COMPONENT BGB_BSCAN_emulator is

  port(

		IR 		: out std_logic_vector(9 downto 0);
		
		CAPTURE1 : out std_ulogic;
		DRCK1    : out std_ulogic;
		RESET1   : out std_ulogic;
		SEL1     : out std_ulogic;
		SHIFT1   : out std_ulogic;
		UPDATE1  : out std_ulogic;
		RUNTEST1  : out std_ulogic;
		TDO1		: in  std_ulogic;
		
		CAPTURE2 : out std_ulogic;
		DRCK2    : out std_ulogic;
		RESET2   : out std_ulogic;
		SEL2     : out std_ulogic;
		SHIFT2   : out std_ulogic;
		UPDATE2  : out std_ulogic;
		RUNTEST2  : out std_ulogic;
		TDO2		: in  std_ulogic;

		TDO3		: in  std_ulogic;
		TDO4		: in  std_ulogic;

      TDO	: out std_ulogic;

      TCK	: in  std_ulogic;
      TDI	: in  std_ulogic;
      TMS	: in  std_ulogic;
      TRST	: in  std_ulogic
    );

end COMPONENT;

COMPONENT instr_dcd is

  port(
    TCK	: in  std_ulogic;
    DRCK	: in  std_ulogic;
    SEL	: in  std_ulogic; 
    TDI	: in  std_ulogic;
    UPDATE	: in  std_ulogic;
    SHIFT	: in  std_ulogic;
    RST	: in  std_ulogic;
    CLR	: in  std_ulogic;
    F	: out  std_logic_vector (32 downto 0);
    TDO	: out  std_ulogic
  );

end COMPONENT;

COMPONENT user_wr_reg is
  generic (
     width : integer := 12;
     def_value : std_logic_vector (11 downto 0) := "111111111111"
  );
  port (
    TCK	: in  std_ulogic;
    DRCK	: in  std_ulogic;
    FSEL	: in  std_ulogic;
    SEL	: in  std_ulogic;
    TDI	: in  std_ulogic;
    DSY_IN	: in  std_ulogic;
    SHIFT	: in  std_ulogic;
    UPDATE	: in  std_ulogic;
    RST	: in  std_ulogic;
    DSY_CHAIN	: in  std_ulogic;
    PO	: out  std_logic_vector (width-1 downto 0);
    TDO	: out  std_ulogic;
    DSY_OUT	: out  std_ulogic
  );    
 
end COMPONENT;

COMPONENT user_cap_reg is
  generic (
     width : integer := 16
  );
  port  (
    DRCK	: in  std_ulogic;
    FSH	: in  std_ulogic;
    FCAP	: in  std_ulogic;
    SEL	: in  std_ulogic;
    TDI	: in  std_ulogic;
    SHIFT	: in  std_ulogic;
    CAPTURE : in  std_ulogic;
    RST	: in  std_ulogic;
		PI : in std_logic_vector (width-1 downto 0);
    TDO	: out  std_ulogic
    );      
		
end COMPONENT;
 
-------------------------------------------------------------------------------


signal fsel : std_logic_vector(32 downto 0);
--signal adc_mask : std_logic_vector(11 downto 0);
signal bpi_status : std_logic_vector(15 downto 0);
signal int_adc_mask : std_logic_vector(11 downto 0);
signal drck1, sel1, reset1, shift1, capture1, update1 : std_logic;
signal drck2, sel2, reset2, shift2, capture2, update2 : std_logic;
signal tdo_f0c, tdo_f17 : std_logic;
--signal b_tms1, b_tdi1, b_tck1 : std_ulogic;
--signal b_tms2, b_tdi2, b_tck2 : std_ulogic;
signal tdo1 : std_logic;
signal tdo2 : std_logic;
signal tdo3 : std_logic := '0';
signal tdo4 : std_logic := '0';

----------------------------------------------------------------------------

begin

dcfeb_fsel <= fsel;

PMAP_dcfeb_data_gen : dcfeb_data_gen

   port map(
  
	 clk => clk,
	 dcfebclk => dcfebclk,
   rst => rst,
   l1a => l1a,
   l1a_match => l1a_match,
   tx_ack => tx_ack,
   dcfeb_addr => dcfeb_addr,
   dcfeb_dv => dcfeb_dv,
   dcfeb_data => dcfeb_data
	
	);

PMAP_BSCAN : BGB_BSCAN_emulator 
  port map (

		IR => dcfeb_jtag_ir,
		
		CAPTURE1 => capture1,
		DRCK1 => drck1,
		RESET1 => reset1,
		SEL1 => sel1,
		SHIFT1 => shift1,
		UPDATE1 => update1,
		RUNTEST1 => open,
		TDO1 => tdo1,
		
		CAPTURE2 => capture2,
		DRCK2 => drck2,
		RESET2 => reset2,
		SEL2 => sel2,
		SHIFT2 => shift2,
		UPDATE2 => update2,
		RUNTEST2 => open,
		TDO2 => tdo2,

		TDO3 => tdo3,
		TDO4 => tdo4,

		TCK => tck,
		TDI => tdi,
		TMS => tms,
		TDO => tdo,
		TRST => trst
    );
	 
	 rtn_shft_en <= shift2;

PMAP_INSTR_DECODER : instr_dcd
  port map (
    TCK => tck,      -- in
    DRCK => drck1,       -- in 
    SEL => sel1,         -- in 
    TDI => tdi,         -- in 
    UPDATE => update1,   -- in 
    SHIFT => shift1,     -- in
    RST => reset1,       -- in  
    CLR => '0',         -- in
    F => fsel,          -- out
    TDO => tdo1     -- out
  );

PMAP_TDO_MUX : tdo_mux
  port map(
  
    TDO_0C => tdo_f0c,         -- in
    TDO_17 => tdo_f17,         -- in
    FSEL => fsel,         
    TDO => tdo2
  );


PMAP_ADC_MASK : user_wr_reg -- #(.width(12), .def_value(12'hFFF))
--  generic map (
--     width => 12,
--     def_value => "111111111111"
--  );
  port map (
    TCK => tck,         -- in
    DRCK => drck2,       -- in
    FSEL => fsel(12),   -- in
    SEL => sel2,         -- in
    TDI => tdi,         -- in
    DSY_IN => '0',      -- in (not used)
    SHIFT => shift2,     -- in
    UPDATE => update2,   -- in
    RST => reset2,       -- in
    DSY_CHAIN => '0',   -- in (not used)
    PO => adc_mask,     -- out
    TDO => tdo_f0c,      -- out
    DSY_OUT => open     -- out (not used)
  );    
  
-- bgb
-- bgb put the value of adc_mask into bpi_status register for read back
-- bgb

-- Guido
-- bpi_status <= x"B" & int_adc_mask;
-- adc_mask <= int_adc_mask;
bpi_status <= x"fede";
 
PMAP_BPI_STATUS : user_cap_reg -- #(.width(16))
--  generic map (
--     width => 16
--  );
  port map (
    DRCK => drck2,       -- in
    FSH => '0',         -- in (not used)
    FCAP => fsel(23),   -- in
    SEL => sel2,         -- in
    TDI => tdi,         -- in
    SHIFT => shift2,     -- in
    CAPTURE => capture2, -- in
    RST => reset2,       -- in
		PI => bpi_status,  -- in
    TDO => tdo_f17      -- in
    );      
		
 
end dcfeb_v6_arch;
