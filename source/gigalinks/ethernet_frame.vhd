-- ETHERNET_FRAME: Adds ethernet header and trailer to data

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity ETHERNET_FRAME is
  port (
    CLK : in std_logic;                 -- User clock
    RST : in std_logic;                 -- Reset

    TXD_VLD : in std_logic;                      -- Flag for valid data
    TXD     : in std_logic_vector(15 downto 0);  -- Data with no frame

    ROM_CNT_OUT : out std_logic_vector(2 downto 0);

    TXD_ACK   : out std_logic;                     -- TX acknowledgement
    TXD_ISK   : out std_logic_vector(1 downto 0);  -- Data is K character
    TXD_FRAME : out std_logic_vector(15 downto 0)  -- Data to be transmitted
    );
end ETHERNET_FRAME;

architecture ETHERNET_FRAME_ARCH of ETHERNET_FRAME is

  component CRC_GEN is
    port (
      crc_reg : out std_logic_vector(31 downto 0);
      crc     : out std_logic_vector(15 downto 0);

      d       : in std_logic_vector(15 downto 0);
      calc    : in std_logic;
      init    : in std_logic;
      d_valid : in std_logic;
      clk     : in std_logic;
      reset   : in std_logic
      );
  end component;

  constant eth_idle       : std_logic_vector(15 downto 0) := x"50BC";
  constant sop_pre        : std_logic_vector(15 downto 0) := x"55FB";
  constant preamble       : std_logic_vector(15 downto 0) := x"5555";
  constant sof_pre        : std_logic_vector(15 downto 0) := x"D555";
  constant eop            : std_logic_vector(15 downto 0) := x"F7FD";
  constant carrier_extend : std_logic_vector(15 downto 0) := x"F7F7";

  signal txd_dly1, txd_dly2, crc_dly1, crc_dly2 : std_logic_vector(15 downto 0);
  signal txd_vld1, txd_vld2, txd_vld3           : std_logic := '0';
  signal crc_value                              : std_logic_vector(15 downto 0);
  signal crc_calc, crc_clr, crc_dv              : std_logic := '0';

  type   tx_state is (TX_IDLE, TX_HEAD_TRAIL, TX_DATA, TX_CRC);
  signal tx_current_state, tx_next_state : tx_state := TX_IDLE;

  signal rom_cnt_en, rom_cnt_rst : std_logic            := '0';
  signal rom_cnt                 : integer range 0 to 6 := 0;

begin

  ROM_CNT_OUT <= std_logic_vector(to_unsigned(rom_cnt, 3));

  gen_txd_dly : for ind in 0 to 15 generate
  begin
    FDTXD1 : FD port map(txd_dly1(ind), CLK, TXD(ind));
    FDTXD2 : FD port map(txd_dly2(ind), CLK, txd_dly1(ind));
    FDCRC1 : FD port map(crc_dly1(ind), CLK, crc_value(ind));
    FDCRC2 : FD port map(crc_dly2(ind), CLK, crc_dly1(ind));
  end generate gen_txd_dly;
  FDVL1 : FD port map(txd_vld1, CLK, TXD_VLD);
  FDVL2 : FD port map(txd_vld2, CLK, txd_vld1);
  FDVL3 : FD port map(txd_vld3, CLK, txd_vld2);

  tx_fsm_regs : process (tx_next_state, RST, CLK)
  begin
    if (RST = '1') then
      tx_current_state <= TX_IDLE;
      rom_cnt          <= 0;
    elsif rising_edge(CLK) then
      tx_current_state <= tx_next_state;
      if(rom_cnt_rst = '1') then
        rom_cnt <= 0;
      elsif(rom_cnt_en = '1') then
        rom_cnt <= rom_cnt + 1;
      end if;
    end if;
  end process;

  tx_fsm_logic : process (tx_current_state, TXD_VLD, txd_vld1, txd_vld2, txd_vld3, rom_cnt, txd_dly2, crc_dly2)
  begin
    case tx_current_state is
      when TX_IDLE =>
        TXD_FRAME   <= eth_idle;
        TXD_ACK     <= '0';
        TXD_ISK     <= "01";
        rom_cnt_rst <= '0';
        rom_cnt_en  <= '0';
        crc_calc    <= '0';
        crc_clr     <= '0';
        crc_dv      <= '0';
        if (txd_vld2 = '1') then
          tx_next_state <= TX_HEAD_TRAIL;
        else
          tx_next_state <= TX_IDLE;
        end if;
        
      when TX_HEAD_TRAIL =>
        tx_next_state <= TX_HEAD_TRAIL;
        TXD_ACK       <= '0';
        rom_cnt_rst   <= '0';
        rom_cnt_en    <= '1';
        crc_clr       <= '0';
        case rom_cnt is
          when 0 =>
            TXD_FRAME <= sop_pre;
            TXD_ISK   <= "01";
            crc_calc  <= '0';
            crc_clr   <= '1';
            crc_dv    <= '0';
          when 1 =>
            TXD_FRAME <= preamble;
            TXD_ISK   <= "00";
            crc_calc  <= '0';
            crc_clr   <= '1';
            crc_dv    <= '0';
          when 2 =>
            TXD_FRAME <= preamble;
            TXD_ACK   <= '1';
            TXD_ISK   <= "00";
            crc_calc  <= '1';
            crc_dv    <= '1';
          when 3 =>
            tx_next_state <= TX_DATA;
            TXD_FRAME     <= sof_pre;
            TXD_ISK       <= "00";
            crc_calc      <= '1';
            crc_dv        <= '1';
          when 4 =>
            TXD_FRAME <= eop;
            TXD_ISK   <= "11";
            crc_calc  <= '0';
            crc_dv    <= '0';
          when 5 =>
            tx_next_state <= TX_IDLE;
            TXD_FRAME     <= carrier_extend;
            TXD_ISK       <= "11";
            rom_cnt_rst   <= '1';
            crc_calc      <= '0';
            crc_dv        <= '0';
          when others =>
            tx_next_state <= TX_IDLE;
            TXD_FRAME     <= eth_idle;
            TXD_ISK       <= "01";
            rom_cnt_rst   <= '1';
            crc_calc      <= '0';
            crc_dv        <= '0';
        end case;
        
      when TX_DATA =>
        TXD_FRAME   <= txd_dly2;
        TXD_ACK     <= '0';
        TXD_ISK     <= "00";
        rom_cnt_rst <= '0';
        rom_cnt_en  <= '0';
        crc_clr     <= '0';
        if (TXD_VLD = '1') then
          crc_calc <= '1';
        else
          crc_calc <= '0';
        end if;
        if (txd_vld1 = '1') then
          crc_dv        <= '1';
          tx_next_state <= TX_DATA;
        else
          crc_dv        <= '0';
          tx_next_state <= TX_CRC;
        end if;
        
      when TX_CRC =>
        TXD_FRAME   <= crc_dly2;
        TXD_ACK     <= '0';
        TXD_ISK     <= "00";
        rom_cnt_rst <= '0';
        crc_calc    <= '0';
        crc_clr     <= '0';
        crc_dv      <= '0';
        rom_cnt_en  <= '0';
        if (txd_vld3 = '0') then
          tx_next_state <= TX_HEAD_TRAIL;
        else
          tx_next_state <= TX_CRC;
        end if;
        
      when others =>
        tx_next_state <= TX_IDLE;
        TXD_FRAME     <= eth_idle;
        TXD_ACK       <= '0';
        TXD_ISK       <= "01";
        rom_cnt_rst   <= '1';
        rom_cnt_en    <= '0';
        crc_calc      <= '0';
        crc_clr       <= '0';
        crc_dv        <= '0';
        
    end case;
  end process;


  CRC_GEN_PM : CRC_GEN
    port map (
      crc_reg => open,
      crc     => crc_value,

      d       => TXD,
      calc    => crc_calc,
      init    => crc_clr,
      d_valid => crc_dv,
      clk     => CLK,
      reset   => RST
      );


end ETHERNET_FRAME_ARCH;
