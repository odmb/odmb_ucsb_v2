-- CAFIFO: Handles which data packets are expected and which have arrived

library ieee;
library unisim;
library unimacro;
library hdlmacro;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use hdlmacro.hdlmacro.all;

entity cafifo is
  generic (
    NFEB      : integer range 1 to 7  := 5;  -- Number of DCFEBS, 7 in the final design
    FIFO_SIZE : integer range 1 to 64 := 16  -- Number of CAFIFO words
    );  
  port(

    clk        : in std_logic;
    dcfebclk   : in std_logic;
    rst        : in std_logic;
    resync     : in std_logic;
    l1acnt_rst : in std_logic;
    bxcnt_rst  : in std_logic;

    BC0   : in std_logic;
    BXRST : in std_logic;

    l1a          : in std_logic;
    l1a_match_in : in std_logic_vector(NFEB+2 downto 1);

    pop : in std_logic;

    eof_data    : in std_logic_vector(NFEB+2 downto 1);
    alct_dv     : in std_logic;
    otmb_dv     : in std_logic;
    dcfeb0_dv   : in std_logic;
    dcfeb0_data : in std_logic_vector(15 downto 0);
    dcfeb1_dv   : in std_logic;
    dcfeb1_data : in std_logic_vector(15 downto 0);
    dcfeb2_dv   : in std_logic;
    dcfeb2_data : in std_logic_vector(15 downto 0);
    dcfeb3_dv   : in std_logic;
    dcfeb3_data : in std_logic_vector(15 downto 0);
    dcfeb4_dv   : in std_logic;
    dcfeb4_data : in std_logic_vector(15 downto 0);
    dcfeb5_dv   : in std_logic;
    dcfeb5_data : in std_logic_vector(15 downto 0);
    dcfeb6_dv   : in std_logic;
    dcfeb6_data : in std_logic_vector(15 downto 0);

    dcfeb_fifo_wren : out std_logic_vector(NFEB downto 1);  -- Not used
    alct_fifo_wren  : out std_logic;                        -- Not used
    otmb_fifo_wren  : out std_logic;                        -- Not used

    cafifo_l1a_match : out std_logic_vector(NFEB+2 downto 1);
    cafifo_l1a_cnt   : out std_logic_vector(23 downto 0);
    cafifo_l1a_dav   : out std_logic_vector(NFEB+2 downto 1);
    cafifo_bx_cnt    : out std_logic_vector(11 downto 0);

    ext_dcfeb_l1a_cnt7 : out std_logic_vector(23 downto 0);
    dcfeb_l1a_dav7     : out std_logic;

    cafifo_wr_addr : out std_logic_vector(3 downto 0);
    cafifo_rd_addr : out std_logic_vector(3 downto 0)
    );

end cafifo;


architecture cafifo_architecture of cafifo is

  signal alct_l1a_dav, otmb_l1a_dav : std_logic;
  signal dcfeb_dv                   : std_logic_vector(NFEB downto 1);

  type rx_state_type is (RX_IDLE, RX_HEADER1, RX_HEADER2, RX_DW);
  type rx_state_array_type is array (NFEB+2 downto 1) of rx_state_type;
  signal rx_next_state, rx_current_state           : rx_state_array_type;
  signal alct_rx_next_state, alct_rx_current_state : rx_state_type;
  signal otmb_rx_next_state, otmb_rx_current_state : rx_state_type;

  signal dcfeb_l1a_dav : std_logic_vector(NFEB downto 1);

  signal l1a_cnt_out : std_logic_vector(23 downto 0);

  type state_type is (FIFO_EMPTY, FIFO_NOT_EMPTY, FIFO_FULL);
  signal next_state, current_state : state_type;

  type dcfeb_l1a_cnt_array_type is array (NFEB downto 1) of std_logic_vector(11 downto 0);
  signal dcfeb_l1a_cnt     : dcfeb_l1a_cnt_array_type;
  signal reg_dcfeb_l1a_cnt : dcfeb_l1a_cnt_array_type;

  type ext_dcfeb_l1a_cnt_array_type is array (NFEB downto 1) of std_logic_vector(23 downto 0);
  signal ext_dcfeb_l1a_cnt : ext_dcfeb_l1a_cnt_array_type;

  type l1a_cnt_array_type is array (FIFO_SIZE-1 downto 0) of std_logic_vector(23 downto 0);
  signal l1a_cnt : l1a_cnt_array_type;

  type bx_cnt_array_type is array (FIFO_SIZE-1 downto 0) of std_logic_vector(15 downto 0);
  signal bx_cnt : bx_cnt_array_type;

  type l1a_array_type is array (FIFO_SIZE-1 downto 0) of std_logic_vector(NFEB+2 downto 1);
  signal l1a_match : l1a_array_type;
  signal l1a_dav   : l1a_array_type;

  type l1a_b_array_type is array (FIFO_SIZE-1 downto 0) of std_logic;
  signal l1a_dav_otmb    : l1a_b_array_type;
  signal l1a_dav_alct : l1a_b_array_type;

  signal l1a_cnt_wren, l1a_match_wren : std_logic;
  signal wr_addr_en, rd_addr_en       : std_logic;
-- signal wr_addr_out, rd_addr_out : std_logic_vector(3 downto 0);
  signal wr_addr_out, rd_addr_out     : integer := 0;

  signal wren, rden  : std_logic;
  signal empty, full : std_logic;

  signal alct_fifo_empty, alct_fifo_full    : std_logic;
  signal alct_fifo_wr_en, alct_fifo_rd_en   : std_logic;
  signal alct_fifo_wr_cnt, alct_fifo_rd_cnt : std_logic_vector(8 downto 0);
  signal alct_fifo_in, alct_fifo_out        : std_logic_vector(23 downto 0);

  signal otmb_fifo_empty, otmb_fifo_full    : std_logic;
  signal otmb_fifo_wr_en, otmb_fifo_rd_en   : std_logic;
  signal otmb_fifo_wr_cnt, otmb_fifo_rd_cnt : std_logic_vector(8 downto 0);
  signal otmb_fifo_in, otmb_fifo_out        : std_logic_vector(23 downto 0);

  signal LOGICH                                                           : std_logic := '1';
  signal BX_CNT_CLR, BX_CNT_A_TC, BX_CNT_B_TC, BX_CNT_A_CEO, BX_CNT_B_CEO : std_logic;
  signal BX_CNT_OUT, BX_CNT_INNER                                         : std_logic_vector(15 downto 0);
  signal BX_ORBIT, BX_CNT_RST, BX_CNT_RST_RST                             : std_logic;
  

  
begin
  
  cafifo_wr_addr <= std_logic_vector(to_unsigned(wr_addr_out, cafifo_wr_addr'length));
  cafifo_rd_addr <= std_logic_vector(to_unsigned(rd_addr_out, cafifo_rd_addr'length));

  -- Generate BX_CNT (page 5 TRGFIFO)
  BX_CNT_CLR              <= BC0 or BXRST or BX_CNT_RST;
  BX_CNT_A : CB16CE port map(BX_CNT_A_CEO, BX_CNT_INNER, BX_CNT_A_TC, CLK, LOGICH, BX_CNT_CLR);
  BX_CNT_B : CB4CE port map(BX_CNT_B_CEO, BX_CNT_OUT(12), BX_CNT_OUT(13), BX_CNT_OUT(14), BX_CNT_OUT(15), BX_CNT_B_TC, CLK, LOGICH, RST);
  BX_CNT_OUT(11 downto 0) <= BX_CNT_INNER(11 downto 0);

-- Generate BX_ORBIT (3563 bunch crossings) / Generate BX_CNT_RST (page 5)
--  BX_ORBIT <= '1' when (conv_integer(BX_CNT) = 3563) else '0';
-- 2048 + 1024 = 3072 + 256 = 3328 + 128 = 3456 + 64 = 3520 + 32 = 3552 + 11 = 3563
  BX_ORBIT <= '1' when (BX_CNT_OUT = "0000110111101011") else '0';
  FDCORBIT : FDC port map(BX_CNT_RST, CLK, BX_CNT_RST_RST, BX_ORBIT);
  FDBXRST  : FD port map(BX_CNT_RST_RST, CLK, BX_CNT_RST);



-- Initial assignments

  dcfeb_dv(1) <= dcfeb0_dv;
  dcfeb_dv(2) <= dcfeb1_dv;
  dcfeb_dv(3) <= dcfeb2_dv;
  dcfeb_dv(4) <= dcfeb3_dv;
  dcfeb_dv(5) <= dcfeb4_dv;
  dcfeb_dv(6) <= dcfeb5_dv;
  dcfeb_dv(7) <= dcfeb6_dv;

  dcfeb_l1a_cnt(1) <= dcfeb0_data(11 downto 0) when (dcfeb0_dv = '1') else (others => '0');
  dcfeb_l1a_cnt(2) <= dcfeb1_data(11 downto 0) when (dcfeb1_dv = '1') else (others => '0');
  dcfeb_l1a_cnt(3) <= dcfeb2_data(11 downto 0) when (dcfeb2_dv = '1') else (others => '0');
  dcfeb_l1a_cnt(4) <= dcfeb3_data(11 downto 0) when (dcfeb3_dv = '1') else (others => '0');
  dcfeb_l1a_cnt(5) <= dcfeb4_data(11 downto 0) when (dcfeb4_dv = '1') else (others => '0');
  dcfeb_l1a_cnt(6) <= dcfeb5_data(11 downto 0) when (dcfeb5_dv = '1') else (others => '0');
  dcfeb_l1a_cnt(7) <= dcfeb6_data(11 downto 0) when (dcfeb6_dv = '1') else (others => '0');

  l1a_cnt_regs : process (dcfeb_l1a_cnt, rst, dcfebclk, reg_dcfeb_l1a_cnt)
  begin
    for index_dcfeb in 1 to NFEB loop
      if (rst = '1') then
        reg_dcfeb_l1a_cnt(index_dcfeb) <= (others => '0');
      elsif rising_edge(dcfebclk) then
        reg_dcfeb_l1a_cnt(index_dcfeb) <= dcfeb_l1a_cnt(index_dcfeb);
      end if;
      ext_dcfeb_l1a_cnt(index_dcfeb) <= reg_dcfeb_l1a_cnt(index_dcfeb) & dcfeb_l1a_cnt(index_dcfeb);
    end loop;
    
  end process;


  ext_dcfeb_l1a_cnt7 <= ext_dcfeb_l1a_cnt(7);
  dcfeb_l1a_dav7     <= dcfeb_l1a_dav(7);

  wren <= l1a;
  rden <= pop;

-- RX FSMs 

  rx_fsm_regs : process (rx_next_state, rst, dcfebclk)
  begin
    for dcfeb_index in 1 to NFEB loop
      if (rst = '1') then
        rx_current_state(dcfeb_index) <= RX_IDLE;
      elsif rising_edge(dcfebclk) then
        rx_current_state(dcfeb_index) <= rx_next_state(dcfeb_index);
      end if;
    end loop;
  end process;

  rx_fsm_logic : process (rx_current_state, dcfeb_dv)
  begin
    for dcfeb_index in 1 to NFEB loop
      case rx_current_state(dcfeb_index) is
        when RX_IDLE =>
          dcfeb_fifo_wren(dcfeb_index) <= '0';
          dcfeb_l1a_dav(dcfeb_index)   <= '0';
          if (dcfeb_dv(dcfeb_index) = '1') then
            rx_next_state(dcfeb_index) <= RX_HEADER1;
          else
            rx_next_state(dcfeb_index) <= RX_IDLE;
          end if;
          
        when RX_HEADER1 =>
          dcfeb_fifo_wren(dcfeb_index) <= '0';
          dcfeb_l1a_dav(dcfeb_index)   <= '1';  -- mfs: Set 2 cc high to make it more robust (only problem
                                                -- is if we store 2^16 L1A_CNT in cafifo)
          rx_next_state(dcfeb_index)   <= RX_HEADER2;
          
        when RX_HEADER2 =>
          dcfeb_fifo_wren(dcfeb_index) <= '0';
          dcfeb_l1a_dav(dcfeb_index)   <= '1';
          rx_next_state(dcfeb_index)   <= RX_DW;
          
        when RX_DW =>
          dcfeb_l1a_dav(dcfeb_index) <= '0';
          if (dcfeb_dv(dcfeb_index) = '1') then
            dcfeb_fifo_wren(dcfeb_index) <= '1';
            rx_next_state(dcfeb_index)   <= RX_DW;
          else
            dcfeb_fifo_wren(dcfeb_index) <= '0';
            rx_next_state(dcfeb_index)   <= RX_IDLE;
          end if;

        when others =>
          dcfeb_l1a_dav(dcfeb_index)   <= '0';
          dcfeb_fifo_wren(dcfeb_index) <= '0';
          rx_next_state(dcfeb_index)   <= RX_IDLE;
          
      end case;
    end loop;
  end process;

  alct_rx_fsm_logic : process (alct_rx_current_state, alct_dv)
  begin
    case alct_rx_current_state is
      when RX_IDLE =>
        if (alct_dv = '1') then
          alct_l1a_dav       <= '1';
          alct_fifo_wren     <= '1';
          alct_rx_next_state <= RX_DW;
        else
          alct_l1a_dav       <= '0';
          alct_fifo_wren     <= '0';
          alct_rx_next_state <= RX_IDLE;
        end if;
        
      when RX_DW =>
        alct_l1a_dav <= '0';
        if (alct_dv = '1') then
          alct_fifo_wren     <= '1';
          alct_rx_next_state <= RX_DW;
        else
          alct_fifo_wren     <= '0';
          alct_rx_next_state <= RX_IDLE;
        end if;

      when others =>
        alct_l1a_dav       <= '0';
        alct_fifo_wren     <= '0';
        alct_rx_next_state <= RX_IDLE;
        
    end case;
  end process;

  otmb_rx_fsm_logic : process (otmb_rx_current_state, otmb_dv)
  begin
    case otmb_rx_current_state is
      when RX_IDLE =>
        if (otmb_dv = '1') then
          otmb_l1a_dav       <= '1';
          otmb_fifo_wren     <= '1';
          otmb_rx_next_state <= RX_DW;
        else
          otmb_l1a_dav       <= '0';
          otmb_fifo_wren     <= '0';
          otmb_rx_next_state <= RX_IDLE;
        end if;
        
      when RX_DW =>
        otmb_l1a_dav <= '0';
        if (otmb_dv = '1') then
          otmb_fifo_wren     <= '1';
          otmb_rx_next_state <= RX_DW;
        else
          otmb_fifo_wren     <= '0';
          otmb_rx_next_state <= RX_IDLE;
        end if;

      when others =>
        otmb_l1a_dav       <= '0';
        otmb_fifo_wren     <= '0';
        otmb_rx_next_state <= RX_IDLE;
        
    end case;
  end process;

-- l1a Counter

  l1a_counter : process (clk, l1a, l1acnt_rst, resync)
    variable l1a_cnt_data : std_logic_vector(23 downto 0);
  begin
    if (l1acnt_rst = '1' or resync = '1') then
      l1a_cnt_data := (others => '0');
    elsif (rising_edge(clk)) then
      if (l1a = '1') then
        l1a_cnt_data := l1a_cnt_data + 1;
      end if;
    end if;
    l1a_cnt_out <= l1a_cnt_data + 1;
  end process;

-- Memory

  l1a_cnt_fifo : process (l1a_cnt_wren, wr_addr_out, rst, clk, l1a_cnt_out)
  begin
    if (rst = '1') then
      for index in 0 to FIFO_SIZE-1 loop
        l1a_cnt(index) <= (others => '1');
      end loop;
    elsif rising_edge(clk) then
      if (l1a_cnt_wren = '1') then
        l1a_cnt(wr_addr_out) <= l1a_cnt_out;
      end if;
    end if;
  end process;

  cafifo_l1a_cnt <= l1a_cnt(rd_addr_out);

  bx_cnt_fifo : process (l1a_cnt_wren, wr_addr_out, bxcnt_rst, clk, bx_cnt_out)
  begin
    if (bxcnt_rst = '1') then
      for index in 0 to FIFO_SIZE-1 loop
        bx_cnt(index) <= (others => '0');
      end loop;
    elsif rising_edge(clk) then
      if (l1a_cnt_wren = '1') then  -- mfs: I think we only need 1 wren, also for l1a_match
        bx_cnt(wr_addr_out) <= bx_cnt_out;
      end if;
    end if;
  end process;

  cafifo_bx_cnt <= bx_cnt(rd_addr_out)(11 downto 0);

  l1a_match_fifo : process (l1a_match_wren, wr_addr_out, rst, clk, l1a_match_in)
  begin
    if (rst = '1') then
      for index in 0 to FIFO_SIZE-1 loop
        l1a_match(index) <= (others => '0');
      end loop;
    elsif rising_edge(clk) then
      if (l1a_match_wren = '1') then
        l1a_match(wr_addr_out) <= l1a_match_in;
      end if;
    end if;
  end process;

  cafifo_l1a_match <= l1a_match(rd_addr_out);

  l1a_dav_fifo : process (l1a_cnt, ext_dcfeb_l1a_cnt, dcfeb_l1a_dav, rst, dcfebclk, l1a_match_wren)
  begin
    if (rst = '1') then
      for index in 0 to FIFO_SIZE-1 loop
        l1a_dav(index) <= (others => '0');  
      end loop;
    elsif (l1a_match_wren = '1') then
      l1a_dav(wr_addr_out) <= (others => '0');
    elsif(rising_edge(dcfebclk)) then
      for index in 0 to FIFO_SIZE-1 loop
        for dcfeb_index in 1 to NFEB loop
          if (ext_dcfeb_l1a_cnt(dcfeb_index) = l1a_cnt(index)) and (dcfeb_l1a_dav(dcfeb_index) = '1') then
            l1a_dav(index)(dcfeb_index) <= '1';
          end if;
        end loop;
      end loop;
    end if;
  end process;

  cafifo_l1a_dav(NFEB downto 1) <= l1a_dav(rd_addr_out)(NFEB downto 1);

  alct_fifo_wr_en <= l1a_match_in(9);
  alct_fifo_rd_en <= alct_l1a_dav;
  alct_fifo_in    <= l1a_cnt_out;

  alct_fifo : FIFO_SYNC_MACRO
    generic map (
      DEVICE              => "VIRTEX6",  -- Target Device: "VIRTEX5, "VIRTEX6" 
      ALMOST_FULL_OFFSET  => X"0080",   -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080",   -- Sets the almost empty threshold
      DATA_WIDTH          => 24,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE           => "18Kb")    -- Target BRAM, "18Kb" or "36Kb" 
    port map (
      ALMOSTEMPTY => open,              -- Output almost empty 
      ALMOSTFULL  => open,              -- Output almost full
      DO          => alct_fifo_out,     -- Output data
      EMPTY       => alct_fifo_empty,   -- Output empty
      FULL        => alct_fifo_full,    -- Output full
      RDCOUNT     => alct_fifo_rd_cnt,  -- Output read count
      RDERR       => open,              -- Output read error
      WRCOUNT     => alct_fifo_wr_cnt,  -- Output write count
      WRERR       => open,              -- Output write error
      CLK         => clk,               -- Input clock
      DI          => alct_fifo_in,      -- Input data
      RDEN        => alct_fifo_rd_en,   -- Input read enable
      RST         => rst,               -- Input reset
      WREN        => alct_fifo_wr_en    -- Input write enable
      );

  alct_dv_fifo : process (l1a_cnt, alct_fifo_out, rst, clk)
  begin
    if (rst = '1') then
      for index in 0 to FIFO_SIZE-1 loop
        l1a_dav_alct(index) <= '0';
      end loop;
    elsif rising_edge(clk) then
      for index in 0 to FIFO_SIZE-1 loop
        if (alct_fifo_out(11 downto 0) = l1a_cnt(index)) and (eof_data(9) = '1') then
          l1a_dav_alct(index) <= '1';
        end if;
      end loop;
    end if;
  end process;

  cafifo_l1a_dav(NFEB+2) <= l1a_dav_alct(rd_addr_out);

  otmb_fifo_wr_en <= l1a_match_in(8);
  otmb_fifo_rd_en <= otmb_l1a_dav;
  otmb_fifo_in    <= l1a_cnt_out;

  otmb_fifo : FIFO_SYNC_MACRO
    generic map (
      DEVICE              => "VIRTEX6",  -- Target Device: "VIRTEX5, "VIRTEX6" 
      ALMOST_FULL_OFFSET  => X"0080",   -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080",   -- Sets the almost empty threshold
      DATA_WIDTH          => 24,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE           => "18Kb")    -- Target BRAM, "18Kb" or "36Kb" 
    port map (
      ALMOSTEMPTY => open,              -- Output almost empty 
      ALMOSTFULL  => open,              -- Output almost full
      DO          => otmb_fifo_out,     -- Output data
      EMPTY       => otmb_fifo_empty,   -- Output empty
      FULL        => otmb_fifo_full,    -- Output full
      RDCOUNT     => otmb_fifo_rd_cnt,  -- Output read count
      RDERR       => open,              -- Output read error
      WRCOUNT     => otmb_fifo_wr_cnt,  -- Output write count
      WRERR       => open,              -- Output write error
      CLK         => clk,               -- Input clock
      DI          => otmb_fifo_in,      -- Input data
      RDEN        => otmb_fifo_rd_en,   -- Input read enable
      RST         => rst,               -- Input reset
      WREN        => otmb_fifo_wr_en    -- Input write enable
      );

  otmb_dv_fifo : process (l1a_cnt, otmb_fifo_out, rst, clk)
  begin
    if (rst = '1') then
      for index in 0 to FIFO_SIZE-1 loop
        l1a_dav_otmb(index) <= '0';
      end loop;
    elsif rising_edge(clk) then
      for index in 0 to FIFO_SIZE-1 loop
        if (otmb_fifo_out(11 downto 0) = l1a_cnt(index)) and (eof_data(8) = '1') then
          l1a_dav_otmb(index) <= '1';
        end if;
      end loop;
    end if;
  end process;

  cafifo_l1a_dav(NFEB+1) <= l1a_dav_otmb(rd_addr_out);

-- Address Counters
  addr_counter : process (clk, wr_addr_en, rd_addr_en, rst)
    variable addr_rd_data, addr_wr_data : integer := 0;
  begin
    if (rst = '1') then
      addr_rd_data := 0;
      addr_wr_data := 0;
    elsif (rising_edge(clk)) then
      if (wr_addr_en = '1') then
        if (addr_wr_data = FIFO_SIZE-1) then
          addr_wr_data := 0;
        else
          addr_wr_data := addr_wr_data + 1;
        end if;
      end if;
      if (rd_addr_en = '1') then
        if (addr_rd_data = FIFO_SIZE-1) then
          addr_rd_data := 0;
        else
          addr_rd_data := addr_rd_data + 1;
        end if;
      end if;
    end if;

    wr_addr_out <= addr_wr_data;
    rd_addr_out <= addr_rd_data;
  end process;

-- FSM 
  fsm_regs : process (next_state, rst, clk)
  begin
    if (rst = '1') then
      current_state <= FIFO_EMPTY;
    elsif rising_edge(clk) then
      current_state <= next_state;
    end if;
  end process;

  fsm_logic : process (wren, rden, current_state, wr_addr_out, rd_addr_out)
  begin
    case current_state is
      when FIFO_EMPTY =>
        empty <= '1';
        full  <= '0';
        if (wren = '1') then
          next_state     <= FIFO_NOT_EMPTY;
          wr_addr_en     <= '1';
          rd_addr_en     <= '0';
          l1a_cnt_wren   <= '1';
          l1a_match_wren <= '1';
        else
          next_state     <= FIFO_EMPTY;
          wr_addr_en     <= '0';
          rd_addr_en     <= '0';
          l1a_cnt_wren   <= '0';
          l1a_match_wren <= '0';
        end if;
        
      when FIFO_NOT_EMPTY =>
        empty <= '0';
        full  <= '0';
        if (wren = '1' and rden = '0') then
          if (wr_addr_out = rd_addr_out-1) then
            next_state <= FIFO_FULL;
          else
            next_state <= FIFO_NOT_EMPTY;
          end if;
          l1a_cnt_wren   <= '1';
          l1a_match_wren <= '1';
          wr_addr_en     <= '1';
          rd_addr_en     <= '0';
        elsif (rden = '1' and wren = '0') then
          if (rd_addr_out = wr_addr_out-1) then
            next_state <= FIFO_EMPTY;
          else
            next_state <= FIFO_NOT_EMPTY;
          end if;
          l1a_cnt_wren   <= '0';
          l1a_match_wren <= '0';
          rd_addr_en     <= '1';
          wr_addr_en     <= '0';
        elsif (rden = '1' and wren = '1') then
          next_state     <= FIFO_NOT_EMPTY;
          wr_addr_en     <= '1';
          rd_addr_en     <= '1';
          l1a_cnt_wren   <= '1';
          l1a_match_wren <= '1';
        else
          next_state     <= FIFO_NOT_EMPTY;
          l1a_cnt_wren   <= '0';
          l1a_match_wren <= '0';
          wr_addr_en     <= '0';
          rd_addr_en     <= '0';
        end if;
        
      when FIFO_FULL =>
        empty          <= '0';
        full           <= '1';
        l1a_cnt_wren   <= '0';
        l1a_match_wren <= '0';
        wr_addr_en     <= '0';
        if (rden = '1') then
          next_state <= FIFO_NOT_EMPTY;
          rd_addr_en <= '1';
        else
          next_state <= FIFO_FULL;
          rd_addr_en <= '0';
        end if;

      when others =>
        next_state     <= FIFO_EMPTY;
        empty          <= '0';
        full           <= '0';
        l1a_cnt_wren   <= '0';
        l1a_match_wren <= '0';
        wr_addr_en     <= '0';
        rd_addr_en     <= '0';
        
    end case;
  end process;
end cafifo_architecture;
