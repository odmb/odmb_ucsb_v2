-- PCFIFO: Takes the DDU packets, and Produces continuous packets suitable for ethernet

library ieee;
library work;
library unisim;
library unimacro;
library hdlmacro;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use work.ucsb_types.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use hdlmacro.hdlmacro.all;

entity pcfifo is
  generic (
    NFIFO : integer range 1 to 16 := 16);  -- Number of FIFOs in PCFIFO
  port(

    clk_in  : in std_logic;
    clk_out : in std_logic;
    rst     : in std_logic;

    tx_ack : in std_logic;

    dv_in   : in std_logic;
    ld_in   : in std_logic;
    data_in : in std_logic_vector(15 downto 0);

    dv_out   : out std_logic;
    data_out : out std_logic_vector(15 downto 0)
    );

end pcfifo;


architecture pcfifo_architecture of pcfifo is

  type fsm_state_type is (IDLE, FIFO_TX, FIFO_TX_HEADER, FIFO_TX_EPKT, IDLE_ETH);
  signal pcfifo_current_state : fsm_state_type := IDLE;
  signal pcfifo_next_state    : fsm_state_type := IDLE;

  signal pcfifo_rden  : std_logic;
  signal pcfifo_empty : std_logic;
  signal pcfifo_out   : std_logic_vector(15 downto 0);
  signal pcfifo_ld    : std_logic;

  signal ld_in_q, ld_in_pulse : std_logic                    := '0';
  signal ld_out, ld_out_pulse : std_logic                    := '0';
  signal tx_ack_q             : std_logic_vector(2 downto 0) := (others => '0');
  signal tx_ack_q_b           : std_logic                    := '1';

  signal fifo_in, fifo_out   : std_logic_vector(17 downto 0);
  signal fifo_empty          : std_logic;
  signal fifo_full, fifo_rst : std_logic;
  signal fifo_wren           : std_logic;

  signal pkt_cnt_out : std_logic_vector(7 downto 0) := (others => '0');

-- Guido 10/28 => split long data packets
  signal word_cnt_en, word_cnt_rst : std_logic                     := '0';
  signal word_cnt_out              : std_logic_vector(15 downto 0) := (others => '0');

  -- IDLE_ETH ensures the interframe gap of 96 bits between packets
  signal idle_cnt_en, idle_cnt_rst : std_logic            := '0';
  signal idle_cnt                  : integer range 0 to 20 := 0;

  signal dv_in_pulse, q_ld_in : std_logic := '0';
  signal first_in  : std_logic := '1';
  -- Clock cycles it takes to reach the end of the FIFO_CASCADE
  constant nwait_fifo            : integer   := NFIFO * 8;

  signal epkt_cnt_total : std_logic_vector(15 downto 0) := (others => '0');
  signal epkt_cnt_en    : std_logic;
  
begin


-- FIFOs
  DV_PULSE_EDGE : pulse_edge port map(dv_in_pulse, open, clk_in, rst, 1, dv_in);
  FDLDIN        : FD port map(ld_in_q, clk_in, ld_in);

  FDFIRST  : FDCP port map(first_in, ld_in_q, dv_in_pulse, '1', rst);
  fifo_wren <= dv_in;
  fifo_in   <= first_in & ld_in & data_in;
  PULSERST : PULSE_EDGE port map(fifo_rst, open, clk_out, '0', 3, rst);

  PC_FIFO_CASCADE : FIFO_CASCADE
    generic map (
      NFIFO        => NFIFO,            -- number of FIFOs in cascade
      DATA_WIDTH   => 18,               -- With of data packets
      WR_FASTER_RD => true)   -- Set int_clk to WRCLK if faster than RDCLK

    port map(
      DO    => fifo_out,                -- Output data
      EMPTY => fifo_empty,              -- Output empty
      FULL  => fifo_full,               -- Output full
      EOF   => open,                    -- Output EOF
      BOF   => open,

      DI    => fifo_in,                 -- Input data
      RDCLK => clk_out,                 -- Input read clock
      RDEN  => pcfifo_rden,                 -- Input read enable
      RST   => fifo_rst,                -- Input reset
      WRCLK => clk_in,                  -- Input write clock
      WREN  => fifo_wren                -- Input write enable
      );

  pcfifo_out   <= fifo_out(15 downto 0);
  pcfifo_ld    <= fifo_out(16);
  pcfifo_empty <= fifo_empty;

  FDCACK   : FDC port map(tx_ack_q(0), tx_ack, tx_ack_q(2), tx_ack_q_b);
  FDACK_Q  : FD port map(tx_ack_q(1), clk_out, tx_ack_q(0));
  FDACK_QQ : FD port map(tx_ack_q(2), clk_out, tx_ack_q(1));
  tx_ack_q_b <= not tx_ack_q(2);

-- FSMs
  DS_LDIN : DELAY_SIGNAL generic map (nwait_fifo) port map (q_ld_in, CLK_IN, nwait_fifo, ld_in);
  LDIN_PE  : pulse_edge port map(ld_in_pulse, open, CLK_OUT, RST, 1, q_ld_in);
  LDOUT_PE : pulse_edge port map(ld_out_pulse, open, CLK_OUT, RST, 1, ld_out);

-- Generation of counter for total packets sent
  epkt_cnt_total_pro : process (rst, clk_out, epkt_cnt_en)
  begin
    if (rst = '1') then
      epkt_cnt_total <= (others => '0');
    elsif (rising_edge(clk_out)) then
      if (epkt_cnt_en = '1') then
        epkt_cnt_total <= epkt_cnt_total + 1;
      end if;
    end if;
  end process;

-- Counter to split long data packets
  word_cnt : process (word_cnt_rst, word_cnt_en, rst, clk_out)
    variable word_cnt_data : std_logic_vector(15 downto 0) := (others => '0');
  begin
    if (rst = '1') then
      word_cnt_data := (others => '0');
    elsif (rising_edge(clk_out)) then
      if (word_cnt_rst = '1') then
        word_cnt_data := (others => '0');
      elsif (word_cnt_en = '1') then
        word_cnt_data := word_cnt_data + 1;
      end if;
    end if;

    word_cnt_out <= word_cnt_data;    
  end process;

  pkt_cnt : process (ld_in_pulse, ld_out_pulse, rst, clk_out)
    variable pkt_cnt_data : std_logic_vector(7 downto 0) := (others => '0');
  begin
    if (rst = '1') then
      pkt_cnt_data := (others => '0');
    elsif (rising_edge(clk_out)) then
      if (ld_in_pulse = '1') and (ld_out_pulse = '0') then
        pkt_cnt_data := pkt_cnt_data + 1;
      elsif (ld_in_pulse = '0') and (ld_out_pulse = '1') then
        pkt_cnt_data := pkt_cnt_data - 1;
      end if;
    end if;

    pkt_cnt_out <= pkt_cnt_data;
    
  end process;

  pcfifo_fsm_regs : process (pcfifo_next_state, rst, clk_out, idle_cnt)
  begin
    if (rst = '1') then
      pcfifo_current_state <= IDLE;
    elsif rising_edge(clk_out) then
      pcfifo_current_state <= pcfifo_next_state;
      if(idle_cnt_rst = '1') then
        idle_cnt <= 0;
      elsif(idle_cnt_en = '1') then
        idle_cnt <= idle_cnt + 1;
      end if;
    end if;
    
  end process;

  pcfifo_fsm_logic : process (pcfifo_current_state, pcfifo_out, pcfifo_empty, pcfifo_ld,
                              pkt_cnt_out, tx_ack_q, idle_cnt, word_cnt_out)
  begin
    case pcfifo_current_state is
      when IDLE =>
        dv_out       <= '0';
        data_out     <= (others => '0');
        ld_out       <= '0';
        idle_cnt_rst <= '0';
        idle_cnt_en  <= '0';
        word_cnt_rst <= '0';
        word_cnt_en  <= '0';
        epkt_cnt_en  <= '0';
        if (pkt_cnt_out = "00000000") then
          pcfifo_rden       <= '0';
          pcfifo_next_state <= IDLE;
        else
          pcfifo_rden       <= '1';
          pcfifo_next_state <= FIFO_TX_HEADER;
        end if;
        
      when FIFO_TX_HEADER =>
        dv_out       <= '1';
        data_out     <= pcfifo_out;
        ld_out       <= '0';
        idle_cnt_rst <= '0';
        idle_cnt_en  <= '0';
        word_cnt_rst <= '0';
        word_cnt_en  <= '0';
        epkt_cnt_en  <= '0';
        if (tx_ack_q(0) = '1') then
          pcfifo_rden       <= '1';
          pcfifo_next_state <= FIFO_TX;
        else
          pcfifo_rden       <= '0';
          pcfifo_next_state <= FIFO_TX_HEADER;
        end if;

      when FIFO_TX =>
        dv_out       <= '1';
        data_out     <= pcfifo_out;
        idle_cnt_rst <= '0';
        idle_cnt_en  <= '0';
        word_cnt_rst <= '0';
        word_cnt_en  <= '1';
        epkt_cnt_en  <= '0';
        ld_out       <= '0';
        if pcfifo_ld = '1' or word_cnt_out = x"0FFF" then
          pcfifo_next_state <= FIFO_TX_EPKT;
          pcfifo_rden       <= '0';
        else
          pcfifo_next_state <= FIFO_TX;
          pcfifo_rden       <= '1';
        end if;

      when FIFO_TX_EPKT =>
        dv_out   <= '1';
        data_out <= epkt_cnt_total;
        if (pcfifo_ld = '0') then
          word_cnt_rst <= '0';
          ld_out       <= '0';
        else
          word_cnt_rst <= '1';
          ld_out       <= '1';
        end if;
        idle_cnt_rst  <= '0';
        idle_cnt_en   <= '0';
        word_cnt_en   <= '0';
        epkt_cnt_en   <= '1';
        pcfifo_rden       <= '0';
        pcfifo_next_state <= IDLE_ETH;

      when IDLE_ETH =>
        dv_out       <= '0';
        data_out     <= (others => '0');
        ld_out       <= '0';
        pcfifo_rden      <= '0';
        idle_cnt_en  <= '1';
        epkt_cnt_en  <= '0';
        word_cnt_rst <= '0';
        word_cnt_en  <= '0';
        if (idle_cnt > 12) then
          pcfifo_next_state <= IDLE;
          idle_cnt_rst  <= '1';
        else
          pcfifo_next_state <= IDLE_ETH;
          idle_cnt_rst  <= '0';
        end if;

      when others =>
        dv_out        <= '0';
        data_out      <= (others => '0');
        pcfifo_rden       <= '0';
        ld_out        <= '0';
        idle_cnt_rst  <= '0';
        idle_cnt_en   <= '0';
        word_cnt_rst  <= '0';
        word_cnt_en   <= '0';
        epkt_cnt_en   <= '0';
        pcfifo_next_state <= IDLE;
        
    end case;
    
  end process;

end pcfifo_architecture;
