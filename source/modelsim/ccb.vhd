library unisim;
library ieee;
library work;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
library hdlmacro; use hdlmacro.hdlmacro.all;

entity CCB is

  port (
    clk           : in std_logic;          
    rst           : in std_logic;          
    ccb_cmd       : in  std_logic_vector(5 downto 0);
    ccb_cmd_s     : in  std_logic;
    ccb_data      : in  std_logic_vector(7 downto 0);
    ccb_data_s    : in  std_logic;
    ccb_cal       : in  std_logic_vector(2 downto 0);
   );


end CCB;

ARCHITECTURE CCB_arch of CCB is

  component PULSE_EDGE is
    port (
      DOUT   : out std_logic;
      PULSE1 : out std_logic;
      CLK    : in  std_logic;
      RST    : in  std_logic;
      NPULSE : in  integer;
      DIN    : in  std_logic
      );
  end component;


constant TTCCAL0 : std_logic_vector(5 downto 0) := "101011"; -- code 14
constant TTCCAL1 : std_logic_vector(5 downto 0) := "101010"; -- code 15
constant TTCCAL2 : std_logic_vector(5 downto 0) := "101001"; -- code 16


begin

  PULSE_RESYNC : PULSE_EDGE port map(resync, resync_rst, clk40, '0', 1, STROBE);

  reset <= '1' after 50 ns, '0' after 90 ns;
  crd_enable <= '1' after 100 ns;

  delay <= 1.01 ns after 10000 ns;
  
  fclk <= not fclk after 505 ps;
  fclk_rx <= not fclk_rx after delay;
  
  sclk <= not sclk after 5.05 ns;
  
--  rx_clk <= fclk_rx after 100 ps;
  
  lost_patterns0 <= tx_patterns0 - rx_patterns0;
  lost_patterns1 <= tx_patterns1 - rx_patterns1;

  fh_en_proc : process (tx_dat,rise,reset)
    
  begin
      
    if (reset = '1') then 
      rise <= '0';
    elsif((rise = '0') and rising_edge(tx_dat)) then
      rise <= '1';
    end if; 
    
    fh_en <= rise;
 
    end process;


FH : file_handler
port map
	(en => fh_en,
	 tx_clk => tx_clk,
   tx_period => tx_period,
   rx_period => rx_period);

-- Transmitter
  
PG_MOD : pg_lfsr
port map
	(reset => reset,
	 prg_en => prg_enable,
	 sclk => sclk,
	 dout => prg_data(7 downto 0));

prg_data(9 downto 8) <= "11";

PDR : prg_data_reg
port map
	(prg_data => prg_data,
	 sclk => sclk,
	 r2_prg_data => r2_prg_data);

ENC_MOD : enc_8b10b
port map(
		RESET => reset,
		SBYTECLK => sclk,
		KI => '0',
		AI => prg_data(0), 
		BI => prg_data(1), 
		CI => prg_data(2), 
		DI => prg_data(3), 
		EI => prg_data(4), 
		FI => prg_data(5), 
		GI => prg_data(6), 
		HI => prg_data(7),
		JO => enc_data(9), 
		HO => enc_data(8), 
		GO => enc_data(7), 
		FO => enc_data(6), 
		IO => enc_data(5), 
		EO => enc_data(4), 
		DO => enc_data(3), 
		CO => enc_data(2), 
		BO => enc_data(1), 
		AO => enc_data(0));

EDR : enc_data_reg
port map
	(enc_data => enc_data,
	 sclk => sclk,
	 r1_enc_data => r1_enc_data);

tx_data_sel: process(r2_prg_data, r1_enc_data, enc_enable)
   
	begin

		if (enc_enable = '1')  then
      tx_data <= r1_enc_data; 
		else
      tx_data <= r2_prg_data; 
    end if;    
	
end process;

TX_PC_MOD : pc
port map
	(clk => sclk,
	 reset => reset,
	 en => '1',
	 enc_en => enc_enable,
	 din => tx_data,
	 dout0 => tx_patterns0,
	 dout1 => tx_patterns1);

SER_MOD : ser
port map
	(fclk => fclk,
	 sclk => sclk,
	 din => tx_data,
	 dout => tx_dat);

tx_clk <= fclk;

TX_TMON_MOD : t_mon
port map
	(clk => tx_clk,
	 reset => reset,
	 t_out => tx_period);

-- Link

  rx_dat <= tx_dat;

-- Receiver

DCRD_MOD : acdr_21_07_lfsd_cl
port map
	(reset => reset,
	 enable => crd_enable,
	 rx_dat => rx_dat,
	 rx_clk => crd_clk);

rx_clk_sel: process(crd_clk, tx_clk, crd_enable)
   
	begin

		if (crd_enable = '1')  then
      rx_clk <= crd_clk; 
		else
      rx_clk <= tx_clk; 
    end if;    
	
end process;

RX_TMON_MOD : t_mon
port map
	(clk => crd_clk,
	 reset => reset,
	 t_out => rx_period);

DES_MOD : des
port map
	(fclk => rx_clk,
	 din => rx_dat,
	 dout => des_data);

GEN_PD :
  
  for K in 0 to nbit-1 generate
    pd_el : sync
      port map
        (reset,rx_clk,fsm_en(K),enc_enable,pd_det(K),pd_cnt(K),ch_sync(K),ch_sync_pulse(K),lost_ch_sync(K),des_data, ch_data(K));
  end generate GEN_PD;

LSL_MOD : lost_sync_logic
port map
	(sync_pulse => ch_sync_pulse,
	 lost_sync => lost_ch_sync);

DM_MOD : data_mux
port map
	(sync => ch_sync,
	 ch0_data => ch_data(0),
	 ch1_data => ch_data(1),
	 ch2_data => ch_data(2),
	 ch3_data => ch_data(3),
	 ch4_data => ch_data(4),
	 ch5_data => ch_data(5),
	 ch6_data => ch_data(6),
	 ch7_data => ch_data(7),
	 ch8_data => ch_data(8),
	 ch9_data => ch_data(9),
	 dout => sync_rx_data);

RX_PC_MOD : pc
port map
	(clk => rx_clk,
	 reset => reset,
	 en => rx_clk_en,
	 enc_en => enc_enable,
	 din => sync_rx_data,
	 dout0 => rx_patterns0,
	 dout1 => rx_patterns1);
	  
DEC_MOD : dec_8b10b
port map
		(RESET => reset,
		RBYTECLK => recovered_sclk,
		AI => sync_rx_data(0),
		BI => sync_rx_data(1), 
		CI => sync_rx_data(2), 
		DI => sync_rx_data(3), 
		EI => sync_rx_data(4), 
		II => sync_rx_data(5), 
		FI => sync_rx_data(6), 
		GI => sync_rx_data(7), 
		HI => sync_rx_data(8), 
		JI => sync_rx_data(9),	
		KO => open,
		HO => dec_data(7), 
		GO => dec_data(6), 
		FO => dec_data(5), 
		EO => dec_data(4), 
		DO => dec_data(3), 
		CO => dec_data(2), 
		BO => dec_data(1), 
		AO => dec_data(0));

dec_data (9 downto 8) <= "11";

rx_data_sel: process(dec_data, sync_rx_data, enc_enable)
   
	begin

		if (enc_enable = '1')  then
      rx_data <= dec_data; 
		else
      rx_data <= sync_rx_data; 
    end if;    
	
end process;

FSM_EN_CNT_MOD : fsm_en_cnt
port map
	(reset => reset,
	 fclk => rx_clk,
	 fsm_en => fsm_en);


CEG_MOD : clk_en_gen
port map
	(sync => ch_sync,
	 fsm_en => fsm_en,
	 clk_en => rx_clk_en);

CKG_MOD : clk_gen
port map
	(clk_en => rx_clk_en,
	 fclk => rx_clk,
	 reset => reset,
	 sclk => recovered_sclk);


end serdes_acrd_21_07_lfsd_cl_tb_arch;
