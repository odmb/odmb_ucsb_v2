library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_1164.all;
Library unisim;
use UNISIM.vcomponents.all;
--use UNISIM.vpck.all;
use UNISIM.all;

library unisim;
use unisim.Vcomponents.all;



entity BGB_BSCAN_emulator is

  port(

		IR 		: out std_logic_vector(9 downto 0);
		
		CAPTURE1 : out std_ulogic := 'H';
		DRCK1    : out std_ulogic := 'H';
		RESET1   : out std_ulogic := 'H';
		SEL1     : out std_ulogic := 'L';
		SHIFT1   : out std_ulogic := 'L';
		UPDATE1  : out std_ulogic := 'L';
		RUNTEST1  : out std_ulogic := 'L';
		TDO1		: in  std_ulogic;
		
		CAPTURE2 : out std_ulogic := 'H';
		DRCK2    : out std_ulogic := 'H';
		RESET2   : out std_ulogic := 'H';
		SEL2     : out std_ulogic := 'L';
		SHIFT2   : out std_ulogic := 'L';
		UPDATE2  : out std_ulogic := 'L';
		RUNTEST2  : out std_ulogic := 'L';
		TDO2		: in  std_ulogic;

		TDO3		: in  std_ulogic;
		TDO4		: in  std_ulogic;

      TDO	: out std_ulogic;

      TCK	: in  std_ulogic;
      TDI	: in  std_ulogic;
      TMS	: in  std_ulogic;
      TRST	: in  std_ulogic
    );

end BGB_BSCAN_emulator;

architecture BGB_BSCAN_emulator_arch OF BGB_BSCAN_emulator is

--
--  JTAG TAP Controller State Machine
--
component JTAG_TAP_ctrl is
  PORT (
	CAP_DR  : OUT STD_ULOGIC;
	RTIDLE  : OUT STD_ULOGIC;
	SHFT_DR : OUT STD_ULOGIC;
	SHFT_IR : OUT STD_ULOGIC;
	TLRESET : OUT STD_ULOGIC;
	UPDT_DR : OUT STD_ULOGIC;
	UPDT_IR : OUT STD_ULOGIC;
	TCK     : IN STD_ULOGIC;
	TDI     : IN STD_ULOGIC;
	TMS     : IN STD_ULOGIC;
	TRST    : IN STD_ULOGIC
  );
end component;

  constant IR_CAPTURE_VAL		  : std_logic_vector (9 downto 0) := "1111010001";
  constant BYPASS_INSTR         : std_logic_vector (9 downto 0) := "1111111111";
  constant IDCODE_INSTR         : std_logic_vector (9 downto 0) := "1111001001";
  constant USER1_INSTR          : std_logic_vector (9 downto 0) := "1111000010";
  constant USER2_INSTR          : std_logic_vector (9 downto 0) := "1111000011";
  constant USER3_INSTR          : std_logic_vector (9 downto 0) := "1111100010";
  constant USER4_INSTR          : std_logic_vector (9 downto 0) := "1111100011";

--------------------------------------------------------


-----------     signal declaration    -------------------

------------ TAP States ---------------------------------
  signal tap_capture_dr			  : std_ulogic := '0';
  signal tap_shift_dr			  : std_ulogic := '0';
  signal tap_update_dr			  : std_ulogic := '0';
  signal tap_shift_ir			  : std_ulogic := '0';
  signal tap_update_ir			  : std_ulogic := '0';
  signal tap_reset			  : std_ulogic := '0';
  signal tap_runtest			  : std_ulogic := '0';
  signal tap_state			  : std_logic_vector (3 downto 0);

-- signals that change status on falling edge of TCK
  signal capture_tpusr		  : std_ulogic;
  signal shift_tpusr			  : std_ulogic;
  signal update_tpusr		  : std_ulogic;
  signal shift_ir_tpusr		  : std_ulogic;
--  signal update_ir_tpusr	  : std_ulogic;

-- for future expansion  
--  signal SEL3			  : std_ulogic := '0';
--  signal SEL4			  : std_ulogic := '0';

-- Registers
  signal BypassReg		: std_ulogic := '0';
  signal IR_reg		: std_logic_vector (9 downto 0) := (others => 'X');
  signal ir_int      : std_logic_vector (9 downto 0) := IR_CAPTURE_VAL(9 downto 0);
  signal IDCODEvalue 		: std_logic_vector (31 downto 0) := X"0424A093";
  signal IDreg		         : std_logic_vector (31 downto 0);

-- Instruction decode signals  
--  signal BYPASS_sig		: std_ulogic := '0';
--  signal IDCODE_sig		: std_ulogic := '0';
  signal USER1_sig		: std_ulogic := '0';
  signal USER2_sig		: std_ulogic := '0';
--  signal USER3_sig		: std_ulogic := '0';
--  signal USER4_sig		: std_ulogic := '0';


begin


--
--  JTAG TAP Controller State Machine instantiation
--

JTAG_TAP_ctrl_i : JTAG_TAP_ctrl
  PORT MAP (
	CAP_DR  => tap_capture_dr,
	RTIDLE  => tap_runtest,
	SHFT_DR => tap_shift_dr,
	SHFT_IR => tap_shift_ir,
	TLRESET => tap_reset,
	UPDT_DR => tap_update_dr,
	UPDT_IR => tap_update_ir,
	TCK     => TCK,
	TDI     => TDI,
	TMS     => TMS,
	TRST    => TRST
  );
			
------------- TCK  NEGATIVE EDGE activities ----------
prcs_usr_sigs:process(TCK)
begin
    if(falling_edge(TCK)) then
       capture_tpusr   <= tap_capture_dr;
       shift_tpusr     <= tap_shift_dr;
       update_tpusr    <= tap_update_dr;
       shift_ir_tpusr  <= tap_shift_ir;
--       update_ir_tpusr <= tap_update_ir;
    end if;
end process  prcs_usr_sigs;


--####################################################################
--#####                       JtagIR                             #####
--####################################################################

prcs_JtagIR:process(TCK, TRST)
begin
     if((TRST = '1'))then
        IR_reg <= IDCODE_INSTR;  -- IDCODE instruction is loaded into IR reg.
        ir_int <= IDCODE_INSTR;  -- IDCODE instruction is loaded into IR reg.
     else
        if(rising_edge(TCK)) then
           if(shift_ir_tpusr = '1') then
              IR_reg          <= IR_reg;
              ir_int          <=  (TDI & ir_int(9 downto 1));
           elsif(tap_update_ir = '1') then
              IR_reg          <= ir_int;
              ir_int          <= ir_int;
           else
              IR_reg <= IR_reg;
              ir_int <= ir_int;
           end if;
        end if;
     end if;
  end process  prcs_JtagIR;
  
  IR <= IR_reg;
  
--####################################################################
--#####                       JtagDecodeIR                       #####
--####################################################################

prcs_JtagDecodeIR:process(IR_reg)
begin
	case IR_reg is
		when IR_CAPTURE_VAL =>
--			BYPASS_sig <= '0';
--			IDCODE_sig <= '0';
			USER1_sig  <= '0';
			USER2_sig  <= '0';
--			USER3_sig  <= '0';
--			USER4_sig  <= '0';
		when BYPASS_INSTR => 
--			BYPASS_sig <= '1';
--			IDCODE_sig <= '0';
			USER1_sig  <= '0';
			USER2_sig  <= '0';
--			USER3_sig  <= '0';
--			USER4_sig  <= '0';
		when IDCODE_INSTR => 
--			BYPASS_sig <= '0';
--			USER1_sig  <= '0';
			USER2_sig  <= '0';
--			USER3_sig  <= '0';
--			USER4_sig  <= '0';
		when USER1_INSTR => 
--			BYPASS_sig <= '0';
--			IDCODE_sig <= '0';
			USER1_sig  <= '1';
			USER2_sig  <= '0';
--			USER3_sig  <= '0';
--			USER4_sig  <= '0';
		when USER2_INSTR => 
--			BYPASS_sig <= '0';
--			IDCODE_sig <= '0';
			USER1_sig  <= '0';
			USER2_sig  <= '1';
--			USER3_sig  <= '0';
--			USER4_sig  <= '0';
		when USER3_INSTR => 
--			BYPASS_sig <= '0';
--			IDCODE_sig <= '0';
			USER1_sig  <= '0';
			USER2_sig  <= '0';
--			USER3_sig  <= '1';
--			USER4_sig  <= '0';
		when USER4_INSTR => 
--			BYPASS_sig <= '0';
--			IDCODE_sig <= '0';
			USER1_sig  <= '0';
			USER2_sig  <= '0';
--			USER3_sig  <= '0';
--			USER4_sig  <= '1';
		when others => 
--			BYPASS_sig <= '0';
--			IDCODE_sig <= '0';
			USER1_sig  <= '0';
			USER2_sig  <= '0';
--			USER3_sig  <= '0';
--			USER4_sig  <= '0';
	end case;
end process prcs_JtagDecodeIR;
  
--####################################################################
--#####                       Jtag Bypass Register               #####
--####################################################################
prcs_Bypass_reg: process(TCK)
begin
   if(rising_edge(TCK)) then
		if(shift_tpusr = '1') then
			BypassReg <= TDI;
		else
			BypassReg <= BypassReg;
		end if;
	end if;
end process prcs_Bypass_reg;

--####################################################################
--#####                       Jtag IDCODE Register               #####
--####################################################################
prcs_IDcode_reg: process(TCK)
begin
   if(rising_edge(TCK)) then
		if(shift_tpusr = '1') then
			IDreg <= IDreg(0) & IDreg(31 downto 1);
		else
			IDreg <= IDCODEvalue;
		end if;
	end if;
end process prcs_IDcode_reg;

--####################################################################
--#####                    Select signal outputs                 #####
--####################################################################

	SEL1     <= USER1_sig;
	SEL2     <= USER2_sig;
--	SEL3     <= USER3_sig;
--	SEL4     <= USER4_sig;
      
--####################################################################
--#####                         OUTPUT                           #####
--####################################################################

prcs_JtagTDO:process(shift_tpusr, shift_ir_tpusr, IR_reg, ir_int(0), BypassReg, IDreg(0), TDO1, TDO2, TDO3, TDO4)
begin
	if(shift_tpusr = '1') then
		case IR_reg is
			when BYPASS_INSTR => 
				TDO <= BypassReg;
			when IDCODE_INSTR => 
				TDO <= IDreg(0);
			when USER1_INSTR => 
				TDO <= TDO1;
			when USER2_INSTR => 
				TDO <= TDO2;
			when USER3_INSTR => 
				TDO <= TDO3;
			when USER4_INSTR => 
				TDO <= TDO4;
			when others => 
				TDO <= BypassReg;
		end case;
	elsif(shift_ir_tpusr = '1') then
		TDO <= ir_int(0);
	else
		TDO <= 'Z';
	end if;
end process prcs_JtagTDO;

--####################################################################

  CAPTURE1 <= capture_tpusr;
  DRCK1    <= ((USER1_sig and not tap_shift_dr and not capture_tpusr) or
              (USER1_sig and shift_tpusr and TCK) or
              (USER1_sig and capture_tpusr and TCK));

  RESET1   <= tap_reset;
  RUNTEST1 <= tap_runtest;
  SHIFT1   <= shift_tpusr;
  UPDATE1  <= update_tpusr;

--####################################################################

  CAPTURE2 <= capture_tpusr;
  DRCK2    <= ((USER2_sig and not tap_shift_dr and not capture_tpusr) or
              (USER2_sig and shift_tpusr and TCK) or
              (USER2_sig and capture_tpusr and TCK));

  RESET2   <= tap_reset;
  RUNTEST2 <= tap_runtest;
  SHIFT2   <= shift_tpusr;
  UPDATE2  <= update_tpusr;

end BGB_BSCAN_emulator_arch;
