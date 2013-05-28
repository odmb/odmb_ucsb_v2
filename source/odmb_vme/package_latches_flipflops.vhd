-- March 7, 2013

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package Latches_Flipflops is

-----------------------------------------------------------------------------

-- Modules in UNISIM (12) 

-----------------------------------------------------------------------------

  procedure FD (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic);
  -----------------------------------------------------------------------------
  procedure FD_1 (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic);
  -----------------------------------------------------------------------------
  procedure FDE (
    signal D : in std_logic;
    signal C : in std_logic;
    signal CE : in std_logic;
    signal Q : out std_logic);
  -----------------------------------------------------------------------------
  procedure FDC (
    signal D: in std_logic;
    signal C: in std_logic;
    signal CLR: in std_logic;
    signal Q: out std_logic);
  -----------------------------------------------------------------------------
  procedure FDC_1 (
    signal D: in std_logic;
    signal C: in std_logic;
    signal CLR: in std_logic;
    signal Q: out std_logic);
  -----------------------------------------------------------------------------
  procedure FDCE (
    signal D: in std_logic;
    signal C: in std_logic;
    signal CE: in std_logic;
    signal CLR: in std_logic;
    signal Q: out std_logic);
  -----------------------------------------------------------------------------
  procedure FDCE_1 (
    signal D: in std_logic;
    signal C: in std_logic;
    signal CE: in std_logic;
    signal CLR: in std_logic;
    signal Q: out std_logic);
  -----------------------------------------------------------------------------
   procedure FDP (
    signal D: in std_logic;
    signal C: in std_logic;
    signal PRE: in std_logic;
    signal Q: out std_logic);
  -----------------------------------------------------------------------------
   procedure FDP_1 (
    signal D: in std_logic;
    signal C: in std_logic;
    signal PRE: in std_logic;
    signal Q: out std_logic);
  -----------------------------------------------------------------------------
   procedure FDPE (
    signal D: in std_logic;
    signal C: in std_logic;
    signal CE: in std_logic;
    signal PRE: in std_logic;
    signal Q: out std_logic);
  -----------------------------------------------------------------------------
   procedure FDPE_1 (
    signal D: in std_logic;
    signal C: in std_logic;
    signal CE: in std_logic;
    signal PRE: in std_logic;
    signal Q: out std_logic);
  -----------------------------------------------------------------------------
   procedure FDR (
    signal D: in std_logic;
    signal C: in std_logic;
    signal R: in std_logic;
    signal Q: out std_logic);

  -----------------------------------------------------------------------------

-- Modules not in UNISIM, but with equivalent modules in UNISIM (2) 

  -----------------------------------------------------------------------------

  procedure IFD (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic);
  -----------------------------------------------------------------------------
  procedure IFD_1 (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic);
  -----------------------------------------------------------------------------
  procedure IFDI (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic);

-----------------------------------------------------------------------------

-- Modules in hdlMacro (8) 

-----------------------------------------------------------------------------

  procedure SR8CLE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L : in std_logic;
    signal SLI : in std_logic;
    signal D : in std_logic_vector(7 downto 0);
    signal Q_in : in std_logic_vector(7 downto 0);
    signal Q       : out std_logic_vector(7 downto 0));
  -----------------------------------------------------------------------------
  procedure SR16CE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal SLI : in std_logic;
    signal Q_in : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0));
  -----------------------------------------------------------------------------
  procedure SR16CLE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L : in std_logic;
    signal SLI : in std_logic;
    signal D : in std_logic_vector(15 downto 0);
    signal Q_in : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0));
  -----------------------------------------------------------------------------
  procedure CB4CE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal Q_in    : in std_logic_vector(3 downto 0);
    signal Q       : out std_logic_vector(3 downto 0);
    signal CEO     : out std_logic;
    signal TC      : out std_logic);
-------------------------------------------------------------------------------
  procedure CB8CE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal Q_in    : in std_logic_vector(7 downto 0);
    signal Q       : out std_logic_vector(7 downto 0);
    signal CEO     : out std_logic;
    signal TC      : out std_logic);
-------------------------------------------------------------------------------
  procedure CB16CE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal Q_in    : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0);
    signal CEO     : out std_logic;
    signal TC      : out std_logic);
-------------------------------------------------------------------------------
  procedure CB4RE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal R     : in  std_logic;
    signal Q_in : in std_logic_vector(3 downto 0);
    signal Q       : out std_logic_vector(3 downto 0);
    signal CEO : out std_logic;
    signal TC      : out std_logic);
-------------------------------------------------------------------------------
  procedure CB8RE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal R     : in  std_logic;
    signal Q_in : in std_logic_vector(7 downto 0);
    signal Q       : out std_logic_vector(7 downto 0);
    signal CEO : out std_logic;
    signal TC      : out std_logic);
  -----------------------------------------------------------------------------
  procedure CB2CLED (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L : in std_logic;
    signal UP : in std_logic;
    signal D : in std_logic_vector(1 downto 0);
    signal Q_in : in std_logic_vector(1 downto 0);
    signal Q       : out std_logic_vector(1 downto 0);
    signal CEO : out std_logic;
    signal TC      : out std_logic);
-------------------------------------------------------------------------------
  procedure CB4CLED (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L : in std_logic;
    signal UP : in std_logic;
    signal D : in std_logic_vector(3 downto 0);
    signal Q_in : in std_logic_vector(3 downto 0);
    signal Q       : out std_logic_vector(3 downto 0);
    signal CEO : out std_logic;
    signal TC      : out std_logic);

-----------------------------------------------------------------------------

-- Modules not in UNISIM and not in hdlMacro (2) 

-----------------------------------------------------------------------------

  procedure REGFD (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic);
  -----------------------------------------------------------------------------
  procedure SR16LCE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal SLI : in std_logic;
    signal Q_in : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0));
  -----------------------------------------------------------------------------
  procedure SR16CLRE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L : in std_logic;
    signal SLI : in std_logic;
    signal D : in std_logic_vector(15 downto 0);
    signal Q_in : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0));
  -----------------------------------------------------------------------------
  procedure VOTE (
    signal D0 : in std_logic;
    signal D1 : in std_logic;
    signal D2 : in std_logic;
    signal Q : out std_logic);
  -----------------------------------------------------------------------------
  procedure ILD6 (
    signal D: in std_logic_vector(5 downto 0);
    signal G: in std_logic;
    signal Q: out std_logic_vector(5 downto 0));
  -------------------------------------------------------------------------------
  procedure SRL16 (
    signal D       : in  std_logic;
    signal C     : in  std_logic;
--  signal A : in integer;
    signal A       : in std_logic_vector(3 downto 0);
    signal SHR_IN : in std_logic_vector(15 downto 0);
    signal SHR_OUT : out std_logic_vector(15 downto 0);
    signal Q      : out std_logic);
  -------------------------------------------------------------------------------
  procedure CB10UPDN (
    signal UP     : in  std_logic;
    signal CE     : in  std_logic;
    signal C      : in  std_logic;
    signal CLR    : in  std_logic;
    signal Q      : out std_logic_vector(9 downto 0);
    signal FULL : out std_logic;
    signal EMPTY1 : out std_logic);
  -----------------------------------------------------------------------------
  procedure BXNDLY (
    signal DIN     : in  std_logic;
    signal CLK     : in  std_logic;
    signal DELAY   : in  std_logic_vector(4 downto 0);
    signal DOUT    : out std_logic);
  -----------------------------------------------------------------------------
  procedure TMPLCTDLY (
    signal DIN       : in  std_logic;
    signal CLK      : in  std_logic;
    signal DELAY : in std_logic_vector(2 downto 0);
    signal DOUT       : out std_logic);
  -----------------------------------------------------------------------------
  procedure LCTDLY (
    signal DIN       : in  std_logic;
    signal CLK      : in  std_logic;
    signal DELAY : in std_logic_vector(5 downto 0);
    signal XL1ADLY : in std_logic_vector(1 downto 0);
    signal L1FD : in std_logic_vector(3 downto 0);
    signal DOUT       : out std_logic);
  -----------------------------------------------------------------------------
  procedure PUSHDLY (
    signal DIN       : in  std_logic;
    signal CLK      : in  std_logic;
    signal DELAY : in std_logic_vector(4 downto 0);
    signal DOUT       : out std_logic);
  -----------------------------------------------------------------------------

end Latches_Flipflops;

package body Latches_Flipflops is

-----------------------------------------------------------------------------

-- Modules in UNISIM 

-----------------------------------------------------------------------------

  procedure FD (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic) is
    
  begin 

    if (C='1' and C'event) then
      Q <= D after 100 ps;
    end if;

  end FD;

-------------------------------------------------------------------------------

  procedure FD_1 (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic) is
    
  begin
    if (C='0' and C'event) then
      Q <= D after 100 ps;
    end if;

  end FD_1;

-------------------------------------------------------------------------------

  procedure FDE (
    signal D : in std_logic;
    signal C : in std_logic;
    signal CE : in std_logic;
    signal Q : out std_logic) is
    
  begin

    if (CE='1' and C='1' and C'event) then
      Q <= D after 100 ps;
    end if;

  end FDE;

-------------------------------------------------------------------------------

  procedure FDC (
      signal D: in std_logic;
      signal C: in std_logic;
      signal CLR: in std_logic;
      signal Q: out std_logic) is
      
    begin

      if (CLR='1') then
        Q <= '0' after 100 ps;
      else
        if (C='1' and C'event) then
          Q <= D after 100 ps;
        end if;
      end if;

    end FDC;

-------------------------------------------------------------------------------

  procedure FDC_1 (
      signal D: in std_logic;
      signal C: in std_logic;
      signal CLR: in std_logic;
      signal Q: out std_logic) is
      
    begin

      if (CLR='1') then
        Q <= '0' after 100 ps;
      else
        if (C='0' and C'event) then
          Q <= D after 100 ps;
        end if;
      end if;

    end FDC_1;

 ------------------------------------------------------------------------------

  procedure FDCE (
    signal D: in std_logic;
    signal C: in std_logic;
    signal CE: in std_logic;
    signal CLR: in std_logic;
    signal Q: out std_logic) is

  begin

    if (CLR='1') then
      Q <= '0' after 100 ps;
    else
      if (CE='1' and C='1' and C'event) then
        Q <= D after 100 ps;            
      end if;
    end if;

  end FDCE;

-------------------------------------------------------------------------------

  procedure FDCE_1 (
    signal D: in std_logic;
    signal C: in std_logic;
    signal CE: in std_logic;
    signal CLR: in std_logic;
    signal Q: out std_logic) is

  begin

    if (CLR='1') then
      Q <= '0' after 100 ps;
    else
      if (CE='1' and C='0' and C'event) then
        Q <= D after 100 ps;            
      end if;
    end if;

  end FDCE_1;

-------------------------------------------------------------------------------

  procedure FDP (
      signal D: in std_logic;
      signal C: in std_logic;
      signal PRE: in std_logic;
      signal Q: out std_logic) is
      
    begin

      if (PRE='1') then
        Q <= '1' after 100 ps;
      else
        if (C='1' and C'event) then
          Q <= D after 100 ps;
        end if;
      end if;

    end FDP;

-------------------------------------------------------------------------------

  procedure FDP_1 (
      signal D: in std_logic;
      signal C: in std_logic;
      signal PRE: in std_logic;
      signal Q: out std_logic) is
      
    begin

      if (PRE='1') then
        Q <= '1' after 100 ps;
      else
        if (C='0' and C'event) then
          Q <= D after 100 ps;
        end if;
      end if;

    end FDP_1;

-------------------------------------------------------------------------------

  procedure FDPE (
    signal D: in std_logic;
    signal C: in std_logic;
    signal CE: in std_logic;
    signal PRE: in std_logic;
    signal Q: out std_logic) is

  begin

    if (PRE='1') then
      Q <= '1' after 100 ps;
    else
      if (CE='1' and C='1' and C'event) then
        Q <= D after 100 ps;            
      end if;
    end if;
  end FDPE;

-------------------------------------------------------------------------------

  procedure FDPE_1 (

    signal D: in std_logic;
    signal C: in std_logic;
    signal CE: in std_logic;
    signal PRE: in std_logic;
    signal Q: out std_logic) is

  begin

    if (PRE='1') then
      Q <= '1' after 100 ps;
    else
      if (CE='1' and C='0' and C'event) then
        Q <= D after 100 ps;            
      end if;
    end if;

  end FDPE_1;

-------------------------------------------------------------------------------

  procedure FDR (
      signal D: in std_logic;
      signal C: in std_logic;
      signal R: in std_logic;
      signal Q: out std_logic) is
      
  begin

    if (C='1' and C'event) then
			if (R='1') then
				Q <= '0' after 100 ps;
      else
				Q <= D after 100 ps;
			end if;
		end if;

  end FDR;

  -----------------------------------------------------------------------------

-- Modules not in UNISIM, but with equivalent modules in UNISIM 

  -----------------------------------------------------------------------------

-- equivalent to FD

    procedure IFD (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic) is
    
  begin

    if (C='1' and C'event) then
      Q <= D after 100 ps;
    end if;

  end IFD;

-------------------------------------------------------------------------------

-- equivalent to FD_1

    procedure IFD_1 (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic) is
    
  begin

    if (C='0' and C'event) then
      Q <= D after 100 ps;
    end if;

  end IFD_1;

-------------------------------------------------------------------------------
-- equivalent to FD

    procedure IFDI (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic) is
    
  begin

    if (C='1' and C'event) then
      Q <= D after 100 ps;
    end if;

  end IFDI;

-----------------------------------------------------------------------------

-- Modules not in UNISIM, but in hdlMacro 

-----------------------------------------------------------------------------

  procedure SR8CLE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L       : in std_logic;
    signal SLI     : in std_logic;
    signal D       : in std_logic_vector(7 downto 0);
    signal Q_in    : in std_logic_vector(7 downto 0);
    signal Q       : out std_logic_vector(7 downto 0)) is
    
  begin

    if (CLR='1') then
      Q <= "00000000" after 100 ps;
    elsif (C='1' and C'event) then
		  if (L='1') then
			  Q <= D after 100 ps;
		  elsif (CE='1') then
			  Q(7) <= Q_in(6) after 100 ps;
			  Q(6) <= Q_in(5) after 100 ps;
        Q(5) <= Q_in(4) after 100 ps;
        Q(4) <= Q_in(3) after 100 ps;
        Q(3) <= Q_in(2) after 100 ps;
        Q(2) <= Q_in(1) after 100 ps;
        Q(1) <= Q_in(0) after 100 ps;
        Q(0) <= SLI;
      end if;
    end if;

  end SR8CLE;

-------------------------------------------------------------------------------

  procedure SR16CE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal SLI     : in std_logic;
    signal Q_in    : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0)) is
    
  begin

    if (CLR='1') then
      Q <= "0000000000000000" after 100 ps;
    elsif (CLR='0') then
      if (CE='1' and C='1' and C'event) then
        Q(15) <= Q_in(14) after 100 ps;
        Q(14) <= Q_in(13) after 100 ps;
        Q(13) <= Q_in(12) after 100 ps;
        Q(12) <= Q_in(11) after 100 ps;
        Q(11) <= Q_in(10) after 100 ps;
        Q(10) <= Q_in(9) after 100 ps;
        Q(9) <= Q_in(8) after 100 ps;
        Q(8) <= Q_in(7) after 100 ps;
        Q(7) <= Q_in(6) after 100 ps;
        Q(6) <= Q_in(5) after 100 ps;
        Q(5) <= Q_in(4) after 100 ps;
        Q(4) <= Q_in(3) after 100 ps;
        Q(3) <= Q_in(2) after 100 ps;
        Q(2) <= Q_in(1) after 100 ps;
        Q(1) <= Q_in(0) after 100 ps;
        Q(0) <= SLI;
      end if;
    end if;
    
  end SR16CE;

  -------------------------------------------------------------------------------

  procedure SR16CLE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L       : in std_logic;
    signal SLI     : in std_logic;
    signal D       : in std_logic_vector(15 downto 0);
    signal Q_in    : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0)) is
    
  begin

    if (CLR='1') then
      Q <= "0000000000000000" after 100 ps;
    elsif (C='1' and C'event) then
		  if (L='1') then
			  Q <= D after 100 ps;
		  elsif (CE='1') then
        Q(15) <= Q_in(14) after 100 ps;
        Q(14) <= Q_in(13) after 100 ps;
        Q(13) <= Q_in(12) after 100 ps;
        Q(12) <= Q_in(11) after 100 ps;
        Q(11) <= Q_in(10) after 100 ps;
        Q(10) <= Q_in(9) after 100 ps;
        Q(9) <= Q_in(8) after 100 ps;
        Q(8) <= Q_in(7) after 100 ps;
			  Q(7) <= Q_in(6) after 100 ps;
			  Q(6) <= Q_in(5) after 100 ps;
        Q(5) <= Q_in(4) after 100 ps;
        Q(4) <= Q_in(3) after 100 ps;
        Q(3) <= Q_in(2) after 100 ps;
        Q(2) <= Q_in(1) after 100 ps;
        Q(1) <= Q_in(0) after 100 ps;
        Q(0) <= SLI after 100 ps;
      end if;
    end if;

  end SR16CLE;

-------------------------------------------------------------------------------

  procedure CB4CE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal Q_in    : in std_logic_vector(3 downto 0);
    signal Q       : out std_logic_vector(3 downto 0);
    signal CEO     : out std_logic;
    signal TC      : out std_logic) is
 
	begin
  
    if (CLR='1') then
			Q <= "0000" after 100 ps;
		elsif (CE = '1' and C='1' and C'event) then
			Q <= Q_in + 1 after 100 ps;
		end if;
		
		if (CLR = '1') then
			TC <= '0' after 100 ps;
		elsif (CE = '1' and C='1' and C'event and Q_in="1110") then
			TC <= '1' after 100 ps;
		end if;
	 
		if (CLR = '1') or (CE = '0')then
			CEO <= '0' after 100 ps;
		elsif (CE = '1' and C='1' and C'event and Q_in="1110") then
			CEO <= '1' after 100 ps;
		end if;

  end CB4CE;

-------------------------------------------------------------------------------

  procedure CB8CE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal Q_in    : in std_logic_vector(7 downto 0);
    signal Q       : out std_logic_vector(7 downto 0);
    signal CEO     : out std_logic;
    signal TC      : out std_logic) is    

	begin
  
    if (CLR='1') then
			Q <= "00000000" after 100 ps;
		elsif (CE = '1' and C='1' and C'event) then
			Q <= Q_in + 1 after 100 ps;
		end if;
		
		if (CLR = '1') then
			TC <= '0' after 100 ps;
		elsif (CE = '1' and C='1' and C'event and Q_in="11111110") then
			TC <= '1' after 100 ps;
		end if;
	 
		if (CLR = '1') or (CE = '0')then
			CEO <= '0' after 100 ps;
		elsif (CE = '1' and C='1' and C'event and Q_in="11111110") then
			CEO <= '1' after 100 ps;
		end if;

 end CB8CE;

-------------------------------------------------------------------------------

  procedure CB16CE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal Q_in    : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0);
    signal CEO     : out std_logic;
    signal TC      : out std_logic) is
    
	begin
  
		if (CLR='1') then
			Q <= "0000000000000000" after 100 ps;
		elsif (CE = '1' and C='1' and C'event) then
			Q <= Q_in + 1 after 100 ps;
		end if;
		
		if (CLR = '1') then
			TC <= '0' after 100 ps;
		elsif (CE = '1' and C='1' and C'event and Q_in="1111111111111110") then
			TC <= '1' after 100 ps;
		end if;
	 
		if (CLR = '1') or (CE = '0')then
			CEO <= '0' after 100 ps;
		elsif (CE = '1' and C='1' and C'event and Q_in="1111111111111110") then
			CEO <= '1' after 100 ps;
		end if;

  end CB16CE;

-------------------------------------------------------------------------------

  procedure CB4RE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal R       : in  std_logic;
    signal Q_in    : in std_logic_vector(3 downto 0);
    signal Q       : out std_logic_vector(3 downto 0);
    signal CEO     : out std_logic;
    signal TC      : out std_logic) is
    
	begin
  
		if (C='1' and C'event) then
			if (R='1') then
				Q <= "0000" after 100 ps;
			elsif (CE='1') then    
				Q <= Q_in + 1 after 100 ps;
			end if;
		end if;
		
		if (R = '1') then
			TC <= '0' after 100 ps;
		elsif (Q_in="1110") then
			TC <= '1' after 100 ps;
		end if;
	 
		if (R = '1') then
			CEO <= '0' after 100 ps;
		elsif (CE = '1' and Q_in="1110") then
			CEO <= '1' after 100 ps;
		end if;

 end CB4RE;

-------------------------------------------------------------------------------

    procedure CB8RE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal R       : in  std_logic;
    signal Q_in    : in std_logic_vector(7 downto 0);
    signal Q       : out std_logic_vector(7 downto 0);
    signal CEO     : out std_logic;
    signal TC      : out std_logic) is
    
  begin
		if (C='1' and C'event) then
			if (R='1') then
				Q <= "00000000" after 100 ps;
			elsif (CE='1') then    
				Q <= Q_in + 1 after 100 ps;
			end if;
		end if;
		
		if (R = '1') then
			TC <= '0' after 100 ps;
		elsif (Q_in="11111110") then
			TC <= '1' after 100 ps;
		end if;
	 
		if (R = '1') then
			CEO <= '0' after 100 ps;
		elsif (CE = '1' and Q_in="11111110") then
			CEO <= '1' after 100 ps;
		end if;

  end CB8RE;

-------------------------------------------------------------------------------

   procedure CB2CLED (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L : in std_logic;
    signal UP : in std_logic;
    signal D : in std_logic_vector(1 downto 0);
    signal Q_in       : in std_logic_vector(1 downto 0);
    signal Q       : out std_logic_vector(1 downto 0);
    signal CEO : out std_logic;
    signal TC      : out std_logic) is
    
	begin
  
		if (CLR='1') then
			Q <= "00" after 100 ps;
		elsif (C='1' and C'event) then
			if (L='1') then
				Q <= D after 100 ps;
			elsif (CE='1') then    
				Q <= Q_in + 1 after 100 ps;
			end if;
		end if;
		
		if (CLR = '1') then
			TC <= '0' after 100 ps;
		elsif (UP = '1' and Q_in="10") then
			TC <= '1' after 100 ps;
		elsif (UP = '0' and Q_in="00") then
			TC <= '1' after 100 ps;
		end if;
	 
		if (CLR = '1') then
			CEO <= '0' after 100 ps;
		elsif (CE = '1' and UP = '1' and Q_in="10") then
			CEO <= '1' after 100 ps;
		elsif (CE = '1' and UP = '0' and Q_in="00") then
			CEO <= '1' after 100 ps;
		end if;

  end CB2CLED;

-------------------------------------------------------------------------------

   procedure CB4CLED (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L : in std_logic;
    signal UP : in std_logic;
    signal D : in std_logic_vector(3 downto 0);
    signal Q_in       : in std_logic_vector(3 downto 0);
    signal Q       : out std_logic_vector(3 downto 0);
    signal CEO : out std_logic;
    signal TC      : out std_logic) is

  begin
  
		if (CLR='1') then
			Q <= "0000" after 100 ps;
		elsif (C='1' and C'event) then
			if (L='1') then
				Q <= D after 100 ps;
			elsif (CE='1') and (UP='1') then    
				Q <= Q_in + 1 after 100 ps;
			elsif (CE='1') and (UP='0') then    
				Q <= Q_in - 1 after 100 ps;
			end if;
		end if;
		
		if (CLR = '1') then
			TC <= '0' after 100 ps;
		elsif (UP = '1' and Q_in="1110") then
			TC <= '1' after 100 ps;
		elsif (UP = '0' and Q_in="0000") then
			TC <= '1' after 100 ps;
		end if;
	 
		if (CLR = '1') then
			CEO <= '0' after 100 ps;
		elsif (CE = '1' and UP = '1' and Q_in="1110") then
			CEO <= '1' after 100 ps;
		elsif (CE = '1' and UP = '0' and Q_in="0000") then
			CEO <= '1' after 100 ps;
		end if;
	 
  end CB4CLED;


-----------------------------------------------------------------------------

-- Modules not in UNISIM and not in hdlMacro 

-----------------------------------------------------------------------------

  procedure REGFD (
    signal D : in std_logic;
    signal C : in std_logic;
    signal Q : out std_logic) is
    
  begin

    if (C='1' and C'event) then
      Q <= D after 100 ps;
    end if;

  end REGFD;

------------------------------------------------------------------------------

  procedure SR16LCE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal SLI     : in std_logic;
    signal Q_in    : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0)) is
    
  begin

    if (CLR='1') then
      Q <= "0000000000000000" after 100 ps;
    elsif (CE='1' and C='1' and C'event) then
		  Q(15) <= SLI after 100 ps;
		  Q(14) <= Q_in(15) after 100 ps;
		  Q(13) <= Q_in(14) after 100 ps;
		  Q(12) <= Q_in(13) after 100 ps;
		  Q(11) <= Q_in(12) after 100 ps;
		  Q(10) <= Q_in(11) after 100 ps;
		  Q(9) <= Q_in(10) after 100 ps;
		  Q(8) <= Q_in(9) after 100 ps;
		  Q(7) <= Q_in(8) after 100 ps;
		  Q(6) <= Q_in(7) after 100 ps;
		  Q(5) <= Q_in(6) after 100 ps;
		  Q(4) <= Q_in(5) after 100 ps;
		  Q(3) <= Q_in(4) after 100 ps;
		  Q(2) <= Q_in(3) after 100 ps;
		  Q(1) <= Q_in(2) after 100 ps;
		  Q(0) <= Q_in(1) after 100 ps;
	 end if;
    
  end SR16LCE;

  -------------------------------------------------------------------------------

  procedure SR16CLRE (
    signal C       : in  std_logic;
    signal CE      : in  std_logic;
    signal CLR     : in  std_logic;
    signal L       : in std_logic;
    signal SLI     : in std_logic;
    signal D       : in std_logic_vector(15 downto 0);
    signal Q_in    : in std_logic_vector(15 downto 0);
    signal Q       : out std_logic_vector(15 downto 0)) is
    
  begin

    if (CLR='1') then
      Q <= "0000000000000000" after 100 ps;
    elsif (C='1' and C'event) then
		  if (L='1') then
			   Q <= D after 100 ps;
      elsif (CE='1') then
			   Q(15) <= SLI after 100 ps;          
			   Q(14) <= Q_in(15) after 100 ps;
			   Q(13) <= Q_in(14) after 100 ps;
			   Q(12) <= Q_in(13) after 100 ps;
			   Q(11) <= Q_in(12) after 100 ps;
			   Q(10) <= Q_in(11) after 100 ps;
			   Q(9) <= Q_in(10) after 100 ps;
			   Q(8) <= Q_in(9) after 100 ps;
			   Q(7) <= Q_in(8) after 100 ps;
			   Q(6) <= Q_in(7) after 100 ps;
			   Q(5) <= Q_in(6) after 100 ps;
			   Q(4) <= Q_in(5) after 100 ps;
			   Q(3) <= Q_in(4) after 100 ps;
			   Q(2) <= Q_in(3) after 100 ps;
			   Q(1) <= Q_in(2) after 100 ps;
			   Q(0) <= Q_in(1) after 100 ps;
		  end if;
	 end if;

end SR16CLRE;

------------------------------------------------------------------------------

  procedure VOTE (
    signal D0 : in std_logic;
    signal D1 : in std_logic;
    signal D2 : in std_logic;
    signal Q : out std_logic) is
    
  begin
    if (D0=D1) then
      Q <= D0 after 100 ps;
    elsif (D0=D2) then
      Q <= D0 after 100 ps;
    elsif (D1=D2) then
      Q <= D1 after 100 ps;
    else
      Q <= 'Z' after 100 ps;
    end if;
  end VOTE;

------------------------------------------------------------------------------

  procedure ILD6 (
    signal D: in std_logic_vector(5 downto 0);
    signal G: in std_logic;
    signal Q: out std_logic_vector(5 downto 0)) is
                 
  begin

 	  if (G='1') then
      Q(5 downto 0) <= D(5 downto 0) after 100 ps;
    end if;

  end ILD6;

-------------------------------------------------------------------------------

  procedure SRL16 (
    signal D       : in  std_logic;
    signal C     : in  std_logic;
    signal A       : in std_logic_vector(3 downto 0);
    signal SHR_IN : in std_logic_vector(15 downto 0);
    signal SHR_OUT : out std_logic_vector(15 downto 0);
    signal Q      : out std_logic) is

  begin
    if (C='1' and C'event) then
      SHR_OUT(15 downto 0) <= SHR_IN(14 downto 0) & D after 100 ps;
    end if;
    case A is
      when "0000" => Q <= SHR_IN(0) after 100 ps;
      when "0001" => Q <= SHR_IN(1) after 100 ps;
      when "0010" => Q <= SHR_IN(2) after 100 ps;
      when "0011" => Q <= SHR_IN(3) after 100 ps;
      when "0100" => Q <= SHR_IN(4) after 100 ps;
      when "0101" => Q <= SHR_IN(5) after 100 ps;
      when "0110" => Q <= SHR_IN(6) after 100 ps;
      when "0111" => Q <= SHR_IN(7) after 100 ps;
      when "1000" => Q <= SHR_IN(8) after 100 ps;
      when "1001" => Q <= SHR_IN(9) after 100 ps;
      when "1010" => Q <= SHR_IN(10) after 100 ps;
      when "1011" => Q <= SHR_IN(11) after 100 ps;
      when "1100" => Q <= SHR_IN(12) after 100 ps;
      when "1101" => Q <= SHR_IN(13) after 100 ps;
      when "1110" => Q <= SHR_IN(14) after 100 ps;
      when "1111" => Q <= SHR_IN(15) after 100 ps;
      when others => Q <= SHR_IN(0) after 100 ps;
    end case;

end SRL16;

-------------------------------------------------------------------------------

  procedure CB10UPDN (
    signal UP     : in  std_logic;
    signal CE     : in  std_logic;
    signal C      : in  std_logic;
    signal CLR    : in  std_logic;
    signal Q      : out std_logic_vector(9 downto 0);
    signal FULL : out std_logic;
    signal EMPTY1 : out std_logic) is
  begin
    Q(9 downto 0) <= "0000000000";
    FULL <= '0';
    EMPTY1 <= '1';
  end CB10UPDN;

-------------------------------------------------------------------------------

  procedure BXNDLY (
    signal DIN     : in  std_logic;
    signal CLK     : in  std_logic;
    signal DELAY   : in  std_logic_vector(4 downto 0);
    signal DOUT    : out std_logic) is
  begin
    DOUT <= '1';
  end BXNDLY;

-------------------------------------------------------------------------------

 procedure TMPLCTDLY (
    signal DIN       : in  std_logic;
    signal CLK      : in  std_logic;
    signal DELAY : in std_logic_vector(2 downto 0);
    signal DOUT       : out std_logic) is
    variable DATA : std_logic_vector(7 downto 0);
    variable SEL  : integer;
  begin
    DATA(0) := DIN;
    GEN_DATA : for K in 1 to 7 loop
      if (CLK='1' and CLK'event) then
        DATA(K) := DATA(K-1);
      end if;
    end loop GEN_DATA;
    SEL := conv_integer(DELAY);
    DOUT <= DATA(SEL);
  end TMPLCTDLY;

-------------------------------------------------------------------------------

  procedure LCTDLY (
    signal DIN       : in  std_logic;
    signal CLK      : in  std_logic;
    signal DELAY : in std_logic_vector(5 downto 0);
    signal XL1ADLY : in std_logic_vector(1 downto 0);
    signal L1FD : in std_logic_vector(3 downto 0);
    signal DOUT       : out std_logic) is
  begin
    DOUT <= DIN after 100 ps;
  end LCTDLY;

  -------------------------------------------------------------------------------

  procedure PUSHDLY (
    signal DIN       : in  std_logic;
    signal CLK      : in  std_logic;
    signal DELAY : in std_logic_vector(4 downto 0);
    signal DOUT       : out std_logic) is
    variable DATA1 : std_logic_vector(16 downto 0);
    variable DATA2 : std_logic_vector(16 downto 0);
    variable MUXD, REGD : std_logic;
    variable DELAY1 : std_logic_vector(3 downto 0);
    variable DELAY2 : std_logic_vector(3 downto 0);
    variable SEL1  : integer;
    variable SEL2  : integer;
  begin
    -- First SRL16
    DATA1(0) := DIN;
    GEN_DATA1 : for K in 1 to 16 loop
      if (CLK='1' and CLK'event) then
        DATA1(K) := DATA1(K-1);
      end if;
    end loop GEN_DATA1;
    DELAY1 := DELAY(4) & DELAY(4) & DELAY(4) & DELAY(4);
    if DELAY(4)='1' then
      MUXD := DATA1(conv_integer(DELAY1));
    else
      MUXD := DIN;
    end if;
    if (CLK='1' and CLK'event) then
        REGD := MUXD;
    end if;
    
    -- Second SRL16
    DATA2(0) := REGD;
    GEN_DATA2 : for K in 1 to 16 loop
      if (CLK='1' and CLK'event) then
        DATA2(K) := DATA2(K-1);
      end if;
    end loop GEN_DATA2;
    DELAY2 := DELAY(3 downto 0);
    if (CLK='1' and CLK'event) then
      DOUT <= DATA2(conv_integer(DELAY2));
    end if;
  end PUSHDLY;
  
end Latches_Flipflops;
