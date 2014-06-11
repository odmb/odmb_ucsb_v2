`timescale 1ns / 1ps

/////////////////////////////////////////////////////////////
//
// Version       Date      Comment
//   3.21    Nov. 13 2012  Packet process with no byte swapping (assumes 16-bit alignment)
//
///////////////////////////////////////////////////////////////
module dmb_receiver #(
		      parameter USE_2p56GbE = 0,
		      parameter SIM_SPEEDUP = 1
		      )
   (
    input 	      RST,
    // External signals
    input 	      ORX_01_N,
    input 	      ORX_01_P,
    input 	      ORX_02_N,
    input 	      ORX_02_P,
    input 	      ORX_03_N,
    input 	      ORX_03_P,
    input 	      ORX_04_N,
    input 	      ORX_04_P,
    input 	      ORX_05_N,
    input 	      ORX_05_P,
    input 	      ORX_06_N,
    input 	      ORX_06_P,
    input 	      ORX_07_N,
    input 	      ORX_07_P,
    input 	      ORX_08_N,
    input 	      ORX_08_P,
    input 	      ORX_09_N,
    input 	      ORX_09_P,
    input 	      ORX_10_N,
    input 	      ORX_10_P,
    input 	      ORX_11_N,
    input 	      ORX_11_P,
    input 	      ORX_12_N,
    input 	      ORX_12_P,
    input [7:1]       KILL,
    output [15:0]     DCFEB1_DATA,
    output [15:0]     DCFEB2_DATA,
    output [15:0]     DCFEB3_DATA,
    output [15:0]     DCFEB4_DATA,
    output [15:0]     DCFEB5_DATA,
    output [15:0]     DCFEB6_DATA,
    output [15:0]     DCFEB7_DATA,
    output [7:1]      DCFEB_DATA_VALID,
    output [7:1]      CRC_VALID,
    output 	      DCFEBCLK, 
    // Internal signals
    input 	      FIFO_VME_MODE,
    input [7:1]       FIFO_RST,
    input [7:1]       FIFO_SEL,
    // PRBS signals
    input [2:0]       PRBS_TYPE,
    input [3:0]       PRBS_FIBER_SEL,
    input 	      PRBS_EN,
    input 	      PRBS_RST, 
    input 	      PRBS_RD_EN,
    output 	      RXPRBSERR, 
    output [15:0]     PRBS_ERR_CNT_OUT,
    // to here.
    input [7:1]       RD_EN_FF,
    input [7:1]       WR_EN_FF,
    input [15:0]      FF_DATA_IN,
    output reg [15:0] FF_DATA_OUT,
    output reg [11:0] FF_WRD_CNT,
    output [15:0]     FF_STATUS,
    input 	      DMBVME_CLK_S2,
    input 	      DAQ_RX_125REFCLK,
    input 	      DAQ_RX_160REFCLK_115_0
    );
   
   wire [12:1] 	      DAQ_TX_N;
   wire [12:1] 	      DAQ_TX_P;


   // Asynchronous reset signals
   wire 	      reset_i;
   // ASYNC_REG attribute added to simulate actual behavior under
   // asynchronous operating conditions.
   (* ASYNC_REG = 1 *)
   reg [3:0] 	      reset_r;
   (* ASYNC_REG = 1 *)
   reg [ 3:0] 	      pma_reset_r;
   wire 	      pma_reset_i;
   wire [12:1] 	      rxresetdone_f;
   
   // Client clocking signals
   wire 	      usr_clk_wordwise;
   wire 	      fifo_wr_ck;

   // Physical interface signals
   wire [15:0] 	      mgt_rx_data_i_f[12:1];
   wire [2:0] 	      rxclkcorcnt_i_f[12:1];
   wire [1:0] 	      rxcharisk_i_f[12:1];
   wire [1:0] 	      rxdisperr_i_f[12:1];
   wire [1:0] 	      rxnotintable_i_f[12:1];
   reg [1:0] 	      rxcharisk_r_f[12:1];
   reg [15:0] 	      mgt_rx_data_r_f[12:1];
   reg [1:0] 	      rxdisperr_r_f[12:1];
   reg [1:0] 	      rxnotintable_r_f[12:1];

   // Transceiver clocking signals
   wire [12:1] 	      rxrecclk_f;
   wire [12:1] 	      plllock_i_f;
   
   // frame proc signals
   wire [15:0] 	      wdata_ff[7:1];
   reg [15:0] 	      din_ff[7:1];
   reg [7:0] 	      din_ff_top[7:1];
   wire [15:0] 	      dout_ff[7:1];
   wire [7:0] 	      dout_ff_top[7:1];
   wire [11:0] 	      wrdc_ff[7:1];
   reg [7:1] 	      wrt_en_ff;
   wire [7:1] 	      wd_vld_ff;
   wire [7:1] 	      rx_good_crc_ff;
   wire [7:1] 	      crc_chk_vld_ff;
   
   // fifo signals
   wire [7:1] 	      ae_ff,aeb_ff;
   wire [7:1] 	      af_ff,afb_ff;
   wire [7:1] 	      mt_ff,mtb_ff;
   wire [7:1] 	      full_ff,fullb_ff;
   wire [10:0] 	      rc_ff[7:1], wc_ff[7:1];
   wire [7:1] 	      rderr_ff,rderrb_ff;
   wire [7:1] 	      wrerr_ff,wrerrb_ff;
   wire [7:1] 	      fifo_reset;

   wire 	      clk_ds_i;
   integer 	      index;
   

   //-----------------------------------------------------------------------------
   // Main body of code
   //-----------------------------------------------------------------------------

   assign DCFEBCLK = usr_clk_wordwise;
   
   //--------------------------------------------------------------------
   // GTX PMA reset circuitry
   //--------------------------------------------------------------------

   always@(posedge clk_ds_i)
     if (RST == 1'b1)
       pma_reset_r <= 4'b1111;
     else
       pma_reset_r <= {pma_reset_r[2:0], RST};

   assign pma_reset_i    = pma_reset_r[3];

   //-------------------------------------------------------------------------
   // Main reset circuitry
   //-------------------------------------------------------------------------

   // Synchronize and extend the external reset signal
   always @(posedge usr_clk_wordwise)
     begin
        if (RST == 1)
          reset_r <= 4'b1111;
        else
          begin
             if (plllock_i_f[1] == 1)
               reset_r <= {reset_r[2:0], RST};
          end
     end

   // Apply the extended reset pulse to the EMAC
   assign reset_i = reset_r[3];


   //-------------------------------------------------------------------------
   // Register the signals between the TEMAC and the GT for timing
   // purposes.
   //-------------------------------------------------------------------------

   always @(posedge usr_clk_wordwise)
     begin
	if (reset_i)
	  begin
             rxcharisk_r_f[1]      <= 2'b00;
             mgt_rx_data_r_f[1]    <= 16'h0000;
             rxdisperr_r_f[1]      <= 2'b00;
             rxnotintable_r_f[1]   <= 2'b00;
	     
             rxcharisk_r_f[2]      <= 2'b00;
             mgt_rx_data_r_f[2]    <= 16'h0000;
             rxdisperr_r_f[2]      <= 2'b00;
             rxnotintable_r_f[2]   <= 2'b00;
	     
             rxcharisk_r_f[3]      <= 2'b00;
             mgt_rx_data_r_f[3]    <= 16'h0000;
             rxdisperr_r_f[3]      <= 2'b00;
             rxnotintable_r_f[3]   <= 2'b00;

             rxcharisk_r_f[4]      <= 2'b00;
             mgt_rx_data_r_f[4]    <= 16'h0000;
             rxdisperr_r_f[4]      <= 2'b00;
             rxnotintable_r_f[4]   <= 2'b00;

             rxcharisk_r_f[5]      <= 2'b00;
             mgt_rx_data_r_f[5]    <= 16'h0000;
             rxdisperr_r_f[5]      <= 2'b00;
             rxnotintable_r_f[5]   <= 2'b00;

             rxcharisk_r_f[6]      <= 2'b00;
             mgt_rx_data_r_f[6]    <= 16'h0000;
             rxdisperr_r_f[6]      <= 2'b00;
             rxnotintable_r_f[6]   <= 2'b00;

             rxcharisk_r_f[7]      <= 2'b00;
             mgt_rx_data_r_f[7]    <= 16'h0000;
             rxdisperr_r_f[7]      <= 2'b00;
             rxnotintable_r_f[7]   <= 2'b00;
	  end
	else
	  begin
	     for (index = 1; index <= 7; index = index + 1)
	       begin
		  if (KILL[index] == 1'b0)
		    begin
		       rxcharisk_r_f[index]      <= rxcharisk_i_f[index];
		       mgt_rx_data_r_f[index]    <= mgt_rx_data_i_f[index];
		       rxdisperr_r_f[index]      <= rxdisperr_i_f[index];
		       rxnotintable_r_f[index]   <= rxnotintable_i_f[index];
		    end
		  else
		    begin
		       rxcharisk_r_f[index]      <= 2'b00;
		       mgt_rx_data_r_f[index]    <= 16'h0000;
		       rxdisperr_r_f[index]      <= 2'b00;
		       rxnotintable_r_f[index]   <= 2'b00;
		    end // else: !if(KILL[index] = 1'b0)
	       end
	  end
     end

   
   BUFG usr_clk_wordwise_i (.O(usr_clk_wordwise),.I(clk_ds_i));
   BUFGMUX fifo_clk_mux_i (.O(fifo_wr_ck),.I0(usr_clk_wordwise),.I1(DMBVME_CLK_S2),.S(FIFO_VME_MODE));

   generate
      if(USE_2p56GbE==1) 
	begin : GbE2p56_rx_gtx    //For 2.56 GbE (line rate of 3.2 Gbps)
	   // Locally buffer the output of the IBUFDS_GTXE1 for reset logic
	   
	   BUFR #(.SIM_DEVICE("VIRTEX6"))
	   bufr_clk_ds (
	    .I   (DAQ_RX_160REFCLK_115_0),
	    .O   (clk_ds_i),
	    .CE  (1'b1),
	    .CLR (1'b0)
	    );
	   
	   MGT_32GBPS_16BIT_1TO12 #
	     (
              .WRAPPER_SIM_GTXRESET_SPEEDUP   (SIM_SPEEDUP)      // Set this to 1 for simulation
	      )
	   mgt_32gbps_16bit_1to12_i
	     (

	      .DCLK_IN          (DMBVME_CLK_S2),
	      .PRBS_TYPE        (PRBS_TYPE),
	      .PRBS_FIBER_SEL	(PRBS_FIBER_SEL),
	      .PRBS_EN          (PRBS_EN),
	      .PRBS_RST         (PRBS_RST),
	      .PRBS_RD_EN       (PRBS_RD_EN),
	      .RXPRBSERR        (RXPRBSERR),
	      .PRBS_ERR_CNT_OUT (PRBS_ERR_CNT_OUT),

              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX0  (X0Y8) fiber 05

	      
              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX0_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX0_RXCHARISK_OUT             (rxcharisk_i_f[5]),
              .GTX0_RXDISPERR_OUT             (rxdisperr_i_f[5]),
              .GTX0_RXNOTINTABLE_OUT          (rxnotintable_i_f[5]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX0_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[5]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX0_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX0_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX0_RXDATA_OUT                (mgt_rx_data_i_f[5]),
              .GTX0_RXRECCLK_OUT              (rxrecclk_f[5]),
              .GTX0_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX0_RXN_IN                    (ORX_05_N),
              .GTX0_RXP_IN                    (ORX_05_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX0_GTXRXRESET_IN             (pma_reset_i),
              .GTX0_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX0_PLLRXRESET_IN             (pma_reset_i),
              .GTX0_RXPLLLKDET_OUT            (plllock_i_f[5]),
              .GTX0_RXRESETDONE_OUT           (rxresetdone_f[5]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX0_TXN_OUT                   (DAQ_TX_N[5]),
              .GTX0_TXP_OUT                   (DAQ_TX_P[5]),

              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX1  (X0Y9) fiber 01

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX1_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX1_RXCHARISK_OUT             (rxcharisk_i_f[1]),
              .GTX1_RXDISPERR_OUT             (rxdisperr_i_f[1]),
              .GTX1_RXNOTINTABLE_OUT          (rxnotintable_i_f[1]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX1_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[1]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX1_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX1_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX1_RXDATA_OUT                (mgt_rx_data_i_f[1]),
              .GTX1_RXRECCLK_OUT              (rxrecclk_f[1]),
              .GTX1_RXUSRCLK2_IN              (usr_clk_wordwise),
              //.GTX1_RXUSRCLK2_IN              (DMBVME_CLK_S2),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX1_RXN_IN                    (ORX_01_N),
              .GTX1_RXP_IN                    (ORX_01_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX1_GTXRXRESET_IN             (pma_reset_i),
              .GTX1_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX1_PLLRXRESET_IN             (pma_reset_i),
              .GTX1_RXPLLLKDET_OUT            (plllock_i_f[1]),
              .GTX1_RXRESETDONE_OUT           (rxresetdone_f[1]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX1_TXN_OUT                   (DAQ_TX_N[1]),
              .GTX1_TXP_OUT                   (DAQ_TX_P[1]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX2  (X0Y10) fiber 04

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX2_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX2_RXCHARISK_OUT             (rxcharisk_i_f[4]),
              .GTX2_RXDISPERR_OUT             (rxdisperr_i_f[4]),
              .GTX2_RXNOTINTABLE_OUT          (rxnotintable_i_f[4]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX2_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[4]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX2_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX2_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX2_RXDATA_OUT                (mgt_rx_data_i_f[4]),
              .GTX2_RXRECCLK_OUT              (rxrecclk_f[4]),
              .GTX2_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX2_RXN_IN                    (ORX_04_N),
              .GTX2_RXP_IN                    (ORX_04_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX2_GTXRXRESET_IN             (pma_reset_i),
              .GTX2_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX2_PLLRXRESET_IN             (pma_reset_i),
              .GTX2_RXPLLLKDET_OUT            (plllock_i_f[4]),
              .GTX2_RXRESETDONE_OUT           (rxresetdone_f[4]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX2_TXN_OUT                   (DAQ_TX_N[4]),
              .GTX2_TXP_OUT                   (DAQ_TX_P[4]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX3  (X0Y11) fiber 02

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX3_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX3_RXCHARISK_OUT             (rxcharisk_i_f[2]),
              .GTX3_RXDISPERR_OUT             (rxdisperr_i_f[2]),
              .GTX3_RXNOTINTABLE_OUT          (rxnotintable_i_f[2]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX3_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[2]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX3_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX3_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX3_RXDATA_OUT                (mgt_rx_data_i_f[2]),
              .GTX3_RXRECCLK_OUT              (rxrecclk_f[2]),
              .GTX3_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX3_RXN_IN                    (ORX_02_N),
              .GTX3_RXP_IN                    (ORX_02_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX3_GTXRXRESET_IN             (pma_reset_i),
              .GTX3_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX3_PLLRXRESET_IN             (pma_reset_i),
              .GTX3_RXPLLLKDET_OUT            (plllock_i_f[2]),
              .GTX3_RXRESETDONE_OUT           (rxresetdone_f[2]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX3_TXN_OUT                   (DAQ_TX_N[2]),
              .GTX3_TXP_OUT                   (DAQ_TX_P[2]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX4  (X0Y12) fiber 03

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX4_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX4_RXCHARISK_OUT             (rxcharisk_i_f[3]),
              .GTX4_RXDISPERR_OUT             (rxdisperr_i_f[3]),
              .GTX4_RXNOTINTABLE_OUT          (rxnotintable_i_f[3]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX4_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[3]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX4_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX4_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX4_RXDATA_OUT                (mgt_rx_data_i_f[3]),
              .GTX4_RXRECCLK_OUT              (rxrecclk_f[3]),
              .GTX4_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX4_RXN_IN                    (ORX_03_N),
              .GTX4_RXP_IN                    (ORX_03_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX4_GTXRXRESET_IN             (pma_reset_i),
              .GTX4_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX4_PLLRXRESET_IN             (pma_reset_i),
              .GTX4_RXPLLLKDET_OUT            (plllock_i_f[3]),
              .GTX4_RXRESETDONE_OUT           (rxresetdone_f[3]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX4_TXN_OUT                   (DAQ_TX_N[3]),
              .GTX4_TXP_OUT                   (DAQ_TX_P[3]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX5  (X0Y13) fiber 11

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX5_RXPOWERDOWN_IN            (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX5_RXCHARISK_OUT             (rxcharisk_i_f[11]),
              .GTX5_RXDISPERR_OUT             (rxdisperr_i_f[11]),
              .GTX5_RXNOTINTABLE_OUT          (rxnotintable_i_f[11]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX5_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[11]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX5_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX5_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX5_RXDATA_OUT                (mgt_rx_data_i_f[11]),
              .GTX5_RXRECCLK_OUT              (rxrecclk_f[11]),
              .GTX5_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX5_RXN_IN                    (ORX_11_N),
              .GTX5_RXP_IN                    (ORX_11_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX5_GTXRXRESET_IN             (pma_reset_i),
              .GTX5_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX5_PLLRXRESET_IN             (pma_reset_i),
              .GTX5_RXPLLLKDET_OUT            (plllock_i_f[11]),
              .GTX5_RXRESETDONE_OUT           (rxresetdone_f[11]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX5_TXN_OUT                   (DAQ_TX_N[11]),
              .GTX5_TXP_OUT                   (DAQ_TX_P[11]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX6  (X0Y14) fiber 10

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX6_RXPOWERDOWN_IN            (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX6_RXCHARISK_OUT             (rxcharisk_i_f[10]),
              .GTX6_RXDISPERR_OUT             (rxdisperr_i_f[10]),
              .GTX6_RXNOTINTABLE_OUT          (rxnotintable_i_f[10]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX6_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[10]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX6_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX6_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX6_RXDATA_OUT                (mgt_rx_data_i_f[10]),
              .GTX6_RXRECCLK_OUT              (rxrecclk_f[10]),
              .GTX6_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX6_RXN_IN                    (ORX_10_N),
              .GTX6_RXP_IN                    (ORX_10_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX6_GTXRXRESET_IN             (pma_reset_i),
              .GTX6_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX6_PLLRXRESET_IN             (pma_reset_i),
              .GTX6_RXPLLLKDET_OUT            (plllock_i_f[10]),
              .GTX6_RXRESETDONE_OUT           (rxresetdone_f[10]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX6_TXN_OUT                   (DAQ_TX_N[10]),
              .GTX6_TXP_OUT                   (DAQ_TX_P[10]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX7  (X0Y15) fiber 12

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX7_RXPOWERDOWN_IN            (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX7_RXCHARISK_OUT             (rxcharisk_i_f[12]),
              .GTX7_RXDISPERR_OUT             (rxdisperr_i_f[12]),
              .GTX7_RXNOTINTABLE_OUT          (rxnotintable_i_f[12]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX7_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[12]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX7_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX7_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX7_RXDATA_OUT                (mgt_rx_data_i_f[12]),
              .GTX7_RXRECCLK_OUT              (rxrecclk_f[12]),
              .GTX7_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX7_RXN_IN                    (ORX_12_N),
              .GTX7_RXP_IN                    (ORX_12_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX7_GTXRXRESET_IN             (pma_reset_i),
              .GTX7_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX7_PLLRXRESET_IN             (pma_reset_i),
              .GTX7_RXPLLLKDET_OUT            (plllock_i_f[12]),
              .GTX7_RXRESETDONE_OUT           (rxresetdone_f[12]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX7_TXN_OUT                   (DAQ_TX_N[12]),
              .GTX7_TXP_OUT                   (DAQ_TX_P[12]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX8  (X0Y16) fiber 07

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX8_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX8_RXCHARISK_OUT             (rxcharisk_i_f[7]),
              .GTX8_RXDISPERR_OUT             (rxdisperr_i_f[7]),
              .GTX8_RXNOTINTABLE_OUT          (rxnotintable_i_f[7]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX8_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[7]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX8_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX8_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX8_RXDATA_OUT                (mgt_rx_data_i_f[7]),
              .GTX8_RXRECCLK_OUT              (rxrecclk_f[7]),
              .GTX8_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX8_RXN_IN                    (ORX_07_N),
              .GTX8_RXP_IN                    (ORX_07_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX8_GTXRXRESET_IN             (pma_reset_i),
              .GTX8_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX8_PLLRXRESET_IN             (pma_reset_i),
              .GTX8_RXPLLLKDET_OUT            (plllock_i_f[7]),
              .GTX8_RXRESETDONE_OUT           (rxresetdone_f[7]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX8_TXN_OUT                   (DAQ_TX_N[7]),
              .GTX8_TXP_OUT                   (DAQ_TX_P[7]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX9  (X0Y17) fiber 08

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX9_RXPOWERDOWN_IN            (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX9_RXCHARISK_OUT             (rxcharisk_i_f[8]),
              .GTX9_RXDISPERR_OUT             (rxdisperr_i_f[8]),
              .GTX9_RXNOTINTABLE_OUT          (rxnotintable_i_f[8]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX9_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[8]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX9_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX9_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX9_RXDATA_OUT                (mgt_rx_data_i_f[8]),
              .GTX9_RXRECCLK_OUT              (rxrecclk_f[8]),
              .GTX9_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX9_RXN_IN                    (ORX_08_N),
              .GTX9_RXP_IN                    (ORX_08_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX9_GTXRXRESET_IN             (pma_reset_i),
              .GTX9_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX9_PLLRXRESET_IN             (pma_reset_i),
              .GTX9_RXPLLLKDET_OUT            (plllock_i_f[8]),
              .GTX9_RXRESETDONE_OUT           (rxresetdone_f[8]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX9_TXN_OUT                   (DAQ_TX_N[8]),
              .GTX9_TXP_OUT                   (DAQ_TX_P[8]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX10  (X0Y18) fiber 09

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX10_RXPOWERDOWN_IN           (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX10_RXCHARISK_OUT            (rxcharisk_i_f[9]),
              .GTX10_RXDISPERR_OUT            (rxdisperr_i_f[9]),
              .GTX10_RXNOTINTABLE_OUT         (rxnotintable_i_f[9]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX10_RXCLKCORCNT_OUT          (rxclkcorcnt_i_f[9]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX10_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX10_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX10_RXDATA_OUT               (mgt_rx_data_i_f[9]),
              .GTX10_RXRECCLK_OUT             (rxrecclk_f[9]),
              .GTX10_RXUSRCLK2_IN             (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX10_RXN_IN                   (ORX_09_N),
              .GTX10_RXP_IN                   (ORX_09_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX10_GTXRXRESET_IN            (pma_reset_i),
              .GTX10_MGTREFCLKRX_IN           (DAQ_RX_160REFCLK_115_0),
              .GTX10_PLLRXRESET_IN            (pma_reset_i),
              .GTX10_RXPLLLKDET_OUT           (plllock_i_f[9]),
              .GTX10_RXRESETDONE_OUT          (rxresetdone_f[9]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX10_TXN_OUT                  (DAQ_TX_N[9]),
              .GTX10_TXP_OUT                  (DAQ_TX_P[9]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX11  (X0Y19) fiber 06

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX11_RXPOWERDOWN_IN           (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX11_RXCHARISK_OUT            (rxcharisk_i_f[6]),
              .GTX11_RXDISPERR_OUT            (rxdisperr_i_f[6]),
              .GTX11_RXNOTINTABLE_OUT         (rxnotintable_i_f[6]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX11_RXCLKCORCNT_OUT          (rxclkcorcnt_i_f[6]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX11_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX11_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX11_RXDATA_OUT               (mgt_rx_data_i_f[6]),
              .GTX11_RXRECCLK_OUT             (rxrecclk_f[6]),
              .GTX11_RXUSRCLK2_IN             (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX11_RXN_IN                   (ORX_06_N),
              .GTX11_RXP_IN                   (ORX_06_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX11_GTXRXRESET_IN            (pma_reset_i),
              .GTX11_MGTREFCLKRX_IN           (DAQ_RX_160REFCLK_115_0),
              .GTX11_PLLRXRESET_IN            (pma_reset_i),
              .GTX11_RXPLLLKDET_OUT           (plllock_i_f[6]),
              .GTX11_RXRESETDONE_OUT          (rxresetdone_f[6]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX11_TXN_OUT                  (DAQ_TX_N[6]),
              .GTX11_TXP_OUT                  (DAQ_TX_P[6])


	      );
	   

	end
      else
	begin: GbE_rx_gtx    //For 1 GbE (line rate of 1.25 Gbps)
	   // Locally buffer the output of the IBUFDS_GTXE1 for reset logic
	   BUFR #(.SIM_DEVICE("VIRTEX6"))
	   bufr_clk_ds (
	    //.I   (DAQ_RX_125REFCLK),
	    .I   (DMBVME_CLK_S2),
	    .O   (clk_ds_i),
	    .CE  (1'b1),
	    .CLR (1'b0)
	    );
	   
	   MGT_125GBPS_16BIT_1TO12 #
	     (
              .WRAPPER_SIM_GTXRESET_SPEEDUP   (SIM_SPEEDUP)      // Set this to 1 for simulation
	      )
	   mgt_125gbps_16bit_1to12_i
	     (
              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX0  (X0Y8) fiber 05
	      .FIBER_SEL(FIBER_SEL),
	      .DRPDO_OUT(PRBS_ERR_CNT_OUT),

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX0_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX0_RXCHARISK_OUT             (rxcharisk_i_f[5]),
              .GTX0_RXDISPERR_OUT             (rxdisperr_i_f[5]),
              .GTX0_RXNOTINTABLE_OUT          (rxnotintable_i_f[5]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX0_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[5]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX0_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX0_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX0_RXDATA_OUT                (mgt_rx_data_i_f[5]),
              .GTX0_RXRECCLK_OUT              (rxrecclk_f[5]),
              .GTX0_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX0_RXN_IN                    (ORX_05_N),
              .GTX0_RXP_IN                    (ORX_05_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX0_GTXRXRESET_IN             (pma_reset_i),
              .GTX0_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX0_PLLRXRESET_IN             (pma_reset_i),
              .GTX0_RXPLLLKDET_OUT            (plllock_i_f[5]),
              .GTX0_RXRESETDONE_OUT           (rxresetdone_f[5]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX0_TXN_OUT                   (DAQ_TX_N[5]),
              .GTX0_TXP_OUT                   (DAQ_TX_P[5]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX1  (X0Y9) fiber 01

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX1_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX1_RXCHARISK_OUT             (rxcharisk_i_f[1]),
              .GTX1_RXDISPERR_OUT             (rxdisperr_i_f[1]),
              .GTX1_RXNOTINTABLE_OUT          (rxnotintable_i_f[1]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX1_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[1]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX1_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX1_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX1_RXDATA_OUT                (mgt_rx_data_i_f[1]),
              .GTX1_RXRECCLK_OUT              (rxrecclk_f[1]),
	      .GTX1_RXUSRCLK2_IN              (usr_clk_wordwise),
              //.GTX1_RXUSRCLK2_IN              (DMBVME_CLK_S2),  // This is to use the 62.5 MHz clk
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX1_RXN_IN                    (ORX_01_N),
              .GTX1_RXP_IN                    (ORX_01_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX1_GTXRXRESET_IN             (pma_reset_i),
	      //        .GTX1_MGTREFCLKRX_IN            (DAQ_RX_160REFCLK_115_0),
              .GTX1_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX1_PLLRXRESET_IN             (pma_reset_i),
              .GTX1_RXPLLLKDET_OUT            (plllock_i_f[1]),
              .GTX1_RXRESETDONE_OUT           (rxresetdone_f[1]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX1_TXN_OUT                   (DAQ_TX_N[1]),
              .GTX1_TXP_OUT                   (DAQ_TX_P[1]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX2  (X0Y10) fiber 04

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX2_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX2_RXCHARISK_OUT             (rxcharisk_i_f[4]),
              .GTX2_RXDISPERR_OUT             (rxdisperr_i_f[4]),
              .GTX2_RXNOTINTABLE_OUT          (rxnotintable_i_f[4]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX2_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[4]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX2_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX2_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX2_RXDATA_OUT                (mgt_rx_data_i_f[4]),
              .GTX2_RXRECCLK_OUT              (rxrecclk_f[4]),
              .GTX2_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX2_RXN_IN                    (ORX_04_N),
              .GTX2_RXP_IN                    (ORX_04_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX2_GTXRXRESET_IN             (pma_reset_i),
              .GTX2_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX2_PLLRXRESET_IN             (pma_reset_i),
              .GTX2_RXPLLLKDET_OUT            (plllock_i_f[4]),
              .GTX2_RXRESETDONE_OUT           (rxresetdone_f[4]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX2_TXN_OUT                   (DAQ_TX_N[4]),
              .GTX2_TXP_OUT                   (DAQ_TX_P[4]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX3  (X0Y11) fiber 02

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX3_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX3_RXCHARISK_OUT             (rxcharisk_i_f[2]),
              .GTX3_RXDISPERR_OUT             (rxdisperr_i_f[2]),
              .GTX3_RXNOTINTABLE_OUT          (rxnotintable_i_f[2]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX3_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[2]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX3_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX3_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX3_RXDATA_OUT                (mgt_rx_data_i_f[2]),
              .GTX3_RXRECCLK_OUT              (rxrecclk_f[2]),
              .GTX3_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX3_RXN_IN                    (ORX_02_N),
              .GTX3_RXP_IN                    (ORX_02_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX3_GTXRXRESET_IN             (pma_reset_i),
              .GTX3_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX3_PLLRXRESET_IN             (pma_reset_i),
              .GTX3_RXPLLLKDET_OUT            (plllock_i_f[2]),
              .GTX3_RXRESETDONE_OUT           (rxresetdone_f[2]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX3_TXN_OUT                   (DAQ_TX_N[2]),
              .GTX3_TXP_OUT                   (DAQ_TX_P[2]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX4  (X0Y12) fiber 03

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX4_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX4_RXCHARISK_OUT             (rxcharisk_i_f[3]),
              .GTX4_RXDISPERR_OUT             (rxdisperr_i_f[3]),
              .GTX4_RXNOTINTABLE_OUT          (rxnotintable_i_f[3]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX4_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[3]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX4_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX4_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX4_RXDATA_OUT                (mgt_rx_data_i_f[3]),
              .GTX4_RXRECCLK_OUT              (rxrecclk_f[3]),
              .GTX4_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX4_RXN_IN                    (ORX_03_N),
              .GTX4_RXP_IN                    (ORX_03_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX4_GTXRXRESET_IN             (pma_reset_i),
              .GTX4_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX4_PLLRXRESET_IN             (pma_reset_i),
              .GTX4_RXPLLLKDET_OUT            (plllock_i_f[3]),
              .GTX4_RXRESETDONE_OUT           (rxresetdone_f[3]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX4_TXN_OUT                   (DAQ_TX_N[3]),
              .GTX4_TXP_OUT                   (DAQ_TX_P[3]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX5  (X0Y13) fiber 11

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX5_RXPOWERDOWN_IN            (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX5_RXCHARISK_OUT             (rxcharisk_i_f[11]),
              .GTX5_RXDISPERR_OUT             (rxdisperr_i_f[11]),
              .GTX5_RXNOTINTABLE_OUT          (rxnotintable_i_f[11]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX5_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[11]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX5_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX5_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX5_RXDATA_OUT                (mgt_rx_data_i_f[11]),
              .GTX5_RXRECCLK_OUT              (rxrecclk_f[11]),
              .GTX5_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX5_RXN_IN                    (ORX_11_N),
              .GTX5_RXP_IN                    (ORX_11_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX5_GTXRXRESET_IN             (pma_reset_i),
              .GTX5_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX5_PLLRXRESET_IN             (pma_reset_i),
              .GTX5_RXPLLLKDET_OUT            (plllock_i_f[11]),
              .GTX5_RXRESETDONE_OUT           (rxresetdone_f[11]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX5_TXN_OUT                   (DAQ_TX_N[11]),
              .GTX5_TXP_OUT                   (DAQ_TX_P[11]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX6  (X0Y14) fiber 10

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX6_RXPOWERDOWN_IN            (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX6_RXCHARISK_OUT             (rxcharisk_i_f[10]),
              .GTX6_RXDISPERR_OUT             (rxdisperr_i_f[10]),
              .GTX6_RXNOTINTABLE_OUT          (rxnotintable_i_f[10]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX6_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[10]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX6_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX6_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX6_RXDATA_OUT                (mgt_rx_data_i_f[10]),
              .GTX6_RXRECCLK_OUT              (rxrecclk_f[10]),
              .GTX6_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX6_RXN_IN                    (ORX_10_N),
              .GTX6_RXP_IN                    (ORX_10_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX6_GTXRXRESET_IN             (pma_reset_i),
              .GTX6_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX6_PLLRXRESET_IN             (pma_reset_i),
              .GTX6_RXPLLLKDET_OUT            (plllock_i_f[10]),
              .GTX6_RXRESETDONE_OUT           (rxresetdone_f[10]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX6_TXN_OUT                   (DAQ_TX_N[10]),
              .GTX6_TXP_OUT                   (DAQ_TX_P[10]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX7  (X0Y15) fiber 12

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX7_RXPOWERDOWN_IN            (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX7_RXCHARISK_OUT             (rxcharisk_i_f[12]),
              .GTX7_RXDISPERR_OUT             (rxdisperr_i_f[12]),
              .GTX7_RXNOTINTABLE_OUT          (rxnotintable_i_f[12]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX7_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[12]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX7_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX7_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX7_RXDATA_OUT                (mgt_rx_data_i_f[12]),
              .GTX7_RXRECCLK_OUT              (rxrecclk_f[12]),
              .GTX7_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX7_RXN_IN                    (ORX_12_N),
              .GTX7_RXP_IN                    (ORX_12_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX7_GTXRXRESET_IN             (pma_reset_i),
              .GTX7_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX7_PLLRXRESET_IN             (pma_reset_i),
              .GTX7_RXPLLLKDET_OUT            (plllock_i_f[12]),
              .GTX7_RXRESETDONE_OUT           (rxresetdone_f[12]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX7_TXN_OUT                   (DAQ_TX_N[12]),
              .GTX7_TXP_OUT                   (DAQ_TX_P[12]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX8  (X0Y16) fiber 07

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX8_RXPOWERDOWN_IN            (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX8_RXCHARISK_OUT             (rxcharisk_i_f[7]),
              .GTX8_RXDISPERR_OUT             (rxdisperr_i_f[7]),
              .GTX8_RXNOTINTABLE_OUT          (rxnotintable_i_f[7]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX8_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[7]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX8_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX8_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX8_RXDATA_OUT                (mgt_rx_data_i_f[7]),
              .GTX8_RXRECCLK_OUT              (rxrecclk_f[7]),
              .GTX8_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX8_RXN_IN                    (ORX_07_N),
              .GTX8_RXP_IN                    (ORX_07_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX8_GTXRXRESET_IN             (pma_reset_i),
              .GTX8_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX8_PLLRXRESET_IN             (pma_reset_i),
              .GTX8_RXPLLLKDET_OUT            (plllock_i_f[7]),
              .GTX8_RXRESETDONE_OUT           (rxresetdone_f[7]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX8_TXN_OUT                   (DAQ_TX_N[7]),
              .GTX8_TXP_OUT                   (DAQ_TX_P[7]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX9  (X0Y17) fiber 08

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX9_RXPOWERDOWN_IN            (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX9_RXCHARISK_OUT             (rxcharisk_i_f[8]),
              .GTX9_RXDISPERR_OUT             (rxdisperr_i_f[8]),
              .GTX9_RXNOTINTABLE_OUT          (rxnotintable_i_f[8]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX9_RXCLKCORCNT_OUT           (rxclkcorcnt_i_f[8]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX9_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX9_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX9_RXDATA_OUT                (mgt_rx_data_i_f[8]),
              .GTX9_RXRECCLK_OUT              (rxrecclk_f[8]),
              .GTX9_RXUSRCLK2_IN              (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX9_RXN_IN                    (ORX_08_N),
              .GTX9_RXP_IN                    (ORX_08_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX9_GTXRXRESET_IN             (pma_reset_i),
              .GTX9_MGTREFCLKRX_IN            (DAQ_RX_125REFCLK),
              .GTX9_PLLRXRESET_IN             (pma_reset_i),
              .GTX9_RXPLLLKDET_OUT            (plllock_i_f[8]),
              .GTX9_RXRESETDONE_OUT           (rxresetdone_f[8]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX9_TXN_OUT                   (DAQ_TX_N[8]),
              .GTX9_TXP_OUT                   (DAQ_TX_P[8]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX10  (X0Y18) fiber 09

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX10_RXPOWERDOWN_IN           (2'b11),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX10_RXCHARISK_OUT            (rxcharisk_i_f[9]),
              .GTX10_RXDISPERR_OUT            (rxdisperr_i_f[9]),
              .GTX10_RXNOTINTABLE_OUT         (rxnotintable_i_f[9]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX10_RXCLKCORCNT_OUT          (rxclkcorcnt_i_f[9]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX10_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX10_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX10_RXDATA_OUT               (mgt_rx_data_i_f[9]),
              .GTX10_RXRECCLK_OUT             (rxrecclk_f[9]),
              .GTX10_RXUSRCLK2_IN             (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX10_RXN_IN                   (ORX_09_N),
              .GTX10_RXP_IN                   (ORX_09_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX10_GTXRXRESET_IN            (pma_reset_i),
              .GTX10_MGTREFCLKRX_IN           (DAQ_RX_125REFCLK),
              .GTX10_PLLRXRESET_IN            (pma_reset_i),
              .GTX10_RXPLLLKDET_OUT           (plllock_i_f[9]),
              .GTX10_RXRESETDONE_OUT          (rxresetdone_f[9]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX10_TXN_OUT                  (DAQ_TX_N[9]),
              .GTX10_TXP_OUT                  (DAQ_TX_P[9]),


              //_____________________________________________________________________
              //_____________________________________________________________________
              //GTX11  (X0Y19) fiber 06

              //---------------------- Loopback and Powerdown Ports ----------------------
              .GTX11_RXPOWERDOWN_IN           (2'b00),
              //--------------------- Receive Ports - 8b10b Decoder ----------------------
              .GTX11_RXCHARISK_OUT            (rxcharisk_i_f[6]),
              .GTX11_RXDISPERR_OUT            (rxdisperr_i_f[6]),
              .GTX11_RXNOTINTABLE_OUT         (rxnotintable_i_f[6]),
              //----------------- Receive Ports - Clock Correction Ports -----------------
              .GTX11_RXCLKCORCNT_OUT          (rxclkcorcnt_i_f[6]),
              //------------- Receive Ports - Comma Detection and Alignment --------------
              .GTX11_RXENMCOMMAALIGN_IN        (1'b1),
              .GTX11_RXENPCOMMAALIGN_IN        (1'b1),
              //----------------- Receive Ports - RX Data Path interface -----------------
              .GTX11_RXDATA_OUT               (mgt_rx_data_i_f[6]),
              .GTX11_RXRECCLK_OUT             (rxrecclk_f[6]),
              .GTX11_RXUSRCLK2_IN             (usr_clk_wordwise),
              //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
              .GTX11_RXN_IN                   (ORX_06_N),
              .GTX11_RXP_IN                   (ORX_06_P),
              //---------------------- Receive Ports - RX PLL Ports ----------------------
              .GTX11_GTXRXRESET_IN            (pma_reset_i),
              .GTX11_MGTREFCLKRX_IN           (DAQ_RX_125REFCLK),
              .GTX11_PLLRXRESET_IN            (pma_reset_i),
              .GTX11_RXPLLLKDET_OUT           (plllock_i_f[6]),
              .GTX11_RXRESETDONE_OUT          (rxresetdone_f[6]),
              //-------------- Transmit Ports - TX Driver and OOB signaling --------------
              .GTX11_TXN_OUT                  (DAQ_TX_N[6]),
              .GTX11_TXP_OUT                  (DAQ_TX_P[6])

	      );


	end
   endgenerate

   assign CRC_VALID = crc_chk_vld_ff;
   
   rx_frame_proc_la rx_frame_proc_1
     (
      // inputs
      .CLK(usr_clk_wordwise),
      .RST(reset_i),
      // 1000BASE-X PCS/PMA interface
      .RXDATA(mgt_rx_data_r_f[1]),
      .RX_IS_K(rxcharisk_r_f[1]),
      .RXDISPERR(rxdisperr_r_f[1]),
      .RXNOTINTABLE(rxnotintable_r_f[1]),
      // client inputs
      .FF_FULL(full_ff[1]),
      .FF_AF(af_ff[1]),
      // client outputs
      .FRM_DATA(wdata_ff[1]),
      .FRM_DATA_VALID(wd_vld_ff[1]),
      .GOOD_CRC(rx_good_crc_ff[1]),
      .CRC_CHK_VLD(crc_chk_vld_ff[1])
      );

   assign DCFEB1_DATA = wdata_ff[1];
   assign DCFEB_DATA_VALID[1] = wd_vld_ff[1];

   rx_frame_proc rx_frame_proc_2
     (

      // inputs
      .CLK(usr_clk_wordwise),
      .RST(reset_i),
      // 1000BASE-X PCS/PMA interface
      .RXDATA(mgt_rx_data_r_f[2]),
      .RX_IS_K(rxcharisk_r_f[2]),
      .RXDISPERR(rxdisperr_r_f[2]),
      .RXNOTINTABLE(rxnotintable_r_f[2]),
      // client inputs
      .FF_FULL(full_ff[2]),
      .FF_AF(af_ff[2]),
      // client outputs
      .FRM_DATA(wdata_ff[2]),
      .FRM_DATA_VALID(wd_vld_ff[2]),
      .GOOD_CRC(rx_good_crc_ff[2]),
      .CRC_CHK_VLD(crc_chk_vld_ff[2])
      );

   assign DCFEB2_DATA = wdata_ff[2];
   assign DCFEB_DATA_VALID[2] = wd_vld_ff[2];

   rx_frame_proc rx_frame_proc_3
     (

      // inputs
      .CLK(usr_clk_wordwise),
      .RST(reset_i),
      // 1000BASE-X PCS/PMA interface
      .RXDATA(mgt_rx_data_r_f[3]),
      .RX_IS_K(rxcharisk_r_f[3]),
      .RXDISPERR(rxdisperr_r_f[3]),
      .RXNOTINTABLE(rxnotintable_r_f[3]),
      // client inputs
      .FF_FULL(full_ff[3]),
      .FF_AF(af_ff[3]),
      // client outputs
      .FRM_DATA(wdata_ff[3]),
      .FRM_DATA_VALID(wd_vld_ff[3]),
      .GOOD_CRC(rx_good_crc_ff[3]),
      .CRC_CHK_VLD(crc_chk_vld_ff[3])
      );

   assign DCFEB3_DATA = wdata_ff[3];
   assign DCFEB_DATA_VALID[3] = wd_vld_ff[3];

   rx_frame_proc rx_frame_proc_4
     (

      // inputs
      .CLK(usr_clk_wordwise),
      .RST(reset_i),
      // 1000BASE-X PCS/PMA interface
      .RXDATA(mgt_rx_data_r_f[4]),
      .RX_IS_K(rxcharisk_r_f[4]),
      .RXDISPERR(rxdisperr_r_f[4]),
      .RXNOTINTABLE(rxnotintable_r_f[4]),
      // client inputs
      .FF_FULL(full_ff[4]),
      .FF_AF(af_ff[4]),
      // client outputs
      .FRM_DATA(wdata_ff[4]),
      .FRM_DATA_VALID(wd_vld_ff[4]),
      .GOOD_CRC(rx_good_crc_ff[4]),
      .CRC_CHK_VLD(crc_chk_vld_ff[4])
      );

   assign DCFEB4_DATA = wdata_ff[4];
   assign DCFEB_DATA_VALID[4] = wd_vld_ff[4];

   rx_frame_proc rx_frame_proc_5
     (

      // inputs
      .CLK(usr_clk_wordwise),
      .RST(reset_i),
      // 1000BASE-X PCS/PMA interface
      .RXDATA(mgt_rx_data_r_f[5]),
      .RX_IS_K(rxcharisk_r_f[5]),
      .RXDISPERR(rxdisperr_r_f[5]),
      .RXNOTINTABLE(rxnotintable_r_f[5]),
      // client inputs
      .FF_FULL(full_ff[5]),
      .FF_AF(af_ff[5]),
      // client outputs
      .FRM_DATA(wdata_ff[5]),
      .FRM_DATA_VALID(wd_vld_ff[5]),
      .GOOD_CRC(rx_good_crc_ff[5]),
      .CRC_CHK_VLD(crc_chk_vld_ff[5])
      );

   assign DCFEB5_DATA = wdata_ff[5];
   assign DCFEB_DATA_VALID[5] = wd_vld_ff[5];

   rx_frame_proc rx_frame_proc_6
     (

      // inputs
      .CLK(usr_clk_wordwise),
      .RST(reset_i),
      // 1000BASE-X PCS/PMA interface
      .RXDATA(mgt_rx_data_r_f[6]),
      .RX_IS_K(rxcharisk_r_f[6]),
      .RXDISPERR(rxdisperr_r_f[6]),
      .RXNOTINTABLE(rxnotintable_r_f[6]),
      // client inputs
      .FF_FULL(full_ff[6]),
      .FF_AF(af_ff[6]),
      // client outputs
      .FRM_DATA(wdata_ff[6]),
      .FRM_DATA_VALID(wd_vld_ff[6]),
      .GOOD_CRC(rx_good_crc_ff[6]),
      .CRC_CHK_VLD(crc_chk_vld_ff[6])
      );

   assign DCFEB6_DATA = wdata_ff[6];
   assign DCFEB_DATA_VALID[6] = wd_vld_ff[6];

   rx_frame_proc rx_frame_proc_7
     (

      // inputs
      .CLK(usr_clk_wordwise),
      .RST(reset_i),
      // 1000BASE-X PCS/PMA interface
      .RXDATA(mgt_rx_data_r_f[7]),
      .RX_IS_K(rxcharisk_r_f[7]),
      .RXDISPERR(rxdisperr_r_f[7]),
      .RXNOTINTABLE(rxnotintable_r_f[7]),
      // client inputs
      .FF_FULL(full_ff[7]),
      .FF_AF(af_ff[7]),
      // client outputs
      .FRM_DATA(wdata_ff[7]),
      .FRM_DATA_VALID(wd_vld_ff[7]),
      .GOOD_CRC(rx_good_crc_ff[7]),
      .CRC_CHK_VLD(crc_chk_vld_ff[7])
      );

   assign DCFEB7_DATA = wdata_ff[7];
   assign DCFEB_DATA_VALID[7] = wd_vld_ff[7];

   /////////////////////////////////////////////////////////////////
       // DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width //
       // ===========|===========|============|=======================//
       //   37-72    |  "36Kb"   |     512    |         9-bit         //
       //   19-36    |  "36Kb"   |    1024    |        10-bit         //
       //   19-36    |  "18Kb"   |     512    |         9-bit         //
       //   10-18    |  "36Kb"   |    2048    |        11-bit         //
       //   10-18    |  "18Kb"   |    1024    |        10-bit         //
       //    5-9     |  "36Kb"   |    4096    |        12-bit         //
       //    5-9     |  "18Kb"   |    2048    |        11-bit         //
       //    1-4     |  "36Kb"   |    8192    |        13-bit         //
       //    1-4     |  "18Kb"   |    4096    |        12-bit         //
       /////////////////////////////////////////////////////////////////
       



   /////////////
       //         //
       // FIFO 1  //
       //         //
       /////////////

   FIFO_DUALCLOCK_MACRO  
     #(
       .ALMOST_EMPTY_OFFSET(12'h080), // Sets the almost empty threshold
       .ALMOST_FULL_OFFSET(12'h31E),  // Sets almost full threshold
       .DATA_WIDTH(16),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
       .DEVICE("VIRTEX6"),  // Target device: "VIRTEX5", "VIRTEX6" 
       .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
       .FIRST_WORD_FALL_THROUGH (1) // Sets the FIFO FWFT to 1 or 0 
       ) FIFO_1 (
		 .ALMOSTEMPTY(ae_ff[1]), // 1-bit output almost empty
		 .ALMOSTFULL(af_ff[1]),   // 1-bit output almost full
		 .DO(dout_ff[1][15:0]),                   // Output data, width defined by DATA_WIDTH parameter
		 .EMPTY(mt_ff[1]),             // 1-bit output empty
		 .FULL(full_ff[1]),               // 1-bit output full
		 .RDCOUNT(rc_ff[1]),         // Output read count, width determined by FIFO depth
		 .RDERR(rderr_ff[1]),             // 1-bit output read error
		 .WRCOUNT(wc_ff[1]),         // Output write count, width determined by FIFO depth
		 .WRERR(wrerr_ff[1]),             // 1-bit output write error
		 .DI(din_ff[1][15:0]),                   // Input data, width defined by DATA_WIDTH parameter
		 .RDCLK(DMBVME_CLK_S2),             // 1-bit input read clock
		 .RDEN(RD_EN_FF[1]),               // 1-bit input read enable
		 .RST(fifo_reset[1]),                 // 1-bit input reset
		 .WRCLK(fifo_wr_ck),             // 1-bit input write clock
		 .WREN(wrt_en_ff[1])                // 1-bit input write enable
		 );

   
   /////////////
       //         //
       // FIFO 2  //
       //         //
       /////////////

   FIFO_DUALCLOCK_MACRO  
     #(
       .ALMOST_EMPTY_OFFSET(12'h080), // Sets the almost empty threshold
       .ALMOST_FULL_OFFSET(12'h31E),  // Sets almost full threshold
       .DATA_WIDTH(16),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
       .DEVICE("VIRTEX6"),  // Target device: "VIRTEX5", "VIRTEX6" 
       .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
       .FIRST_WORD_FALL_THROUGH (1) // Sets the FIFO FWFT to 1 or 0 
       ) FIFO_2 (
		 .ALMOSTEMPTY(ae_ff[2]), // 1-bit output almost empty
		 .ALMOSTFULL(af_ff[2]),   // 1-bit output almost full
		 .DO(dout_ff[2][15:0]),                   // Output data, width defined by DATA_WIDTH parameter
		 .EMPTY(mt_ff[2]),             // 1-bit output empty
		 .FULL(full_ff[2]),               // 1-bit output full
		 .RDCOUNT(rc_ff[2]),         // Output read count, width determined by FIFO depth
		 .RDERR(rderr_ff[2]),             // 1-bit output read error
		 .WRCOUNT(wc_ff[2]),         // Output write count, width determined by FIFO depth
		 .WRERR(wrerr_ff[2]),             // 1-bit output write error
		 .DI(din_ff[2][15:0]),                   // Input data, width defined by DATA_WIDTH parameter
		 .RDCLK(DMBVME_CLK_S2),             // 1-bit input read clock
		 .RDEN(RD_EN_FF[2]),               // 1-bit input read enable
		 .RST(fifo_reset[2]),                 // 1-bit input reset
		 .WRCLK(fifo_wr_ck),             // 1-bit input write clock
		 .WREN(wrt_en_ff[2])                // 1-bit input write enable
		 );

   /////////////
       //         //
       // FIFO 3  //
       //         //
       /////////////

   FIFO_DUALCLOCK_MACRO  
     #(
       .ALMOST_EMPTY_OFFSET(12'h080), // Sets the almost empty threshold
       .ALMOST_FULL_OFFSET(12'h31E),  // Sets almost full threshold
       .DATA_WIDTH(16),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
       .DEVICE("VIRTEX6"),  // Target device: "VIRTEX5", "VIRTEX6" 
       .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
       .FIRST_WORD_FALL_THROUGH (1) // Sets the FIFO FWFT to 1 or 0 
       ) FIFO_3 (
		 .ALMOSTEMPTY(ae_ff[3]), // 1-bit output almost empty
		 .ALMOSTFULL(af_ff[3]),   // 1-bit output almost full
		 .DO(dout_ff[3][15:0]),                   // Output data, width defined by DATA_WIDTH parameter
		 .EMPTY(mt_ff[3]),             // 1-bit output empty
		 .FULL(full_ff[3]),               // 1-bit output full
		 .RDCOUNT(rc_ff[3]),         // Output read count, width determined by FIFO depth
		 .RDERR(rderr_ff[3]),             // 1-bit output read error
		 .WRCOUNT(wc_ff[3]),         // Output write count, width determined by FIFO depth
		 .WRERR(wrerr_ff[3]),             // 1-bit output write error
		 .DI(din_ff[3][15:0]),                   // Input data, width defined by DATA_WIDTH parameter
		 .RDCLK(DMBVME_CLK_S2),             // 1-bit input read clock
		 .RDEN(RD_EN_FF[3]),               // 1-bit input read enable
		 .RST(fifo_reset[3]),                 // 1-bit input reset
		 .WRCLK(fifo_wr_ck),             // 1-bit input write clock
		 .WREN(wrt_en_ff[3])                // 1-bit input write enable
		 );

   /////////////
       //         //
       // FIFO 4  //
       //         //
       /////////////

   FIFO_DUALCLOCK_MACRO  
     #(
       .ALMOST_EMPTY_OFFSET(12'h080), // Sets the almost empty threshold
       .ALMOST_FULL_OFFSET(12'h31E),  // Sets almost full threshold
       .DATA_WIDTH(16),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
       .DEVICE("VIRTEX6"),  // Target device: "VIRTEX5", "VIRTEX6" 
       .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
       .FIRST_WORD_FALL_THROUGH (1) // Sets the FIFO FWFT to 1 or 0 
       ) FIFO_4 (
		 .ALMOSTEMPTY(ae_ff[4]), // 1-bit output almost empty
		 .ALMOSTFULL(af_ff[4]),   // 1-bit output almost full
		 .DO(dout_ff[4][15:0]),                   // Output data, width defined by DATA_WIDTH parameter
		 .EMPTY(mt_ff[4]),             // 1-bit output empty
		 .FULL(full_ff[4]),               // 1-bit output full
		 .RDCOUNT(rc_ff[4]),         // Output read count, width determined by FIFO depth
		 .RDERR(rderr_ff[4]),             // 1-bit output read error
		 .WRCOUNT(wc_ff[4]),         // Output write count, width determined by FIFO depth
		 .WRERR(wrerr_ff[4]),             // 1-bit output write error
		 .DI(din_ff[4][15:0]),                   // Input data, width defined by DATA_WIDTH parameter
		 .RDCLK(DMBVME_CLK_S2),             // 1-bit input read clock
		 .RDEN(RD_EN_FF[4]),               // 1-bit input read enable
		 .RST(fifo_reset[4]),                 // 1-bit input reset
		 .WRCLK(fifo_wr_ck),             // 1-bit input write clock
		 .WREN(wrt_en_ff[4])                // 1-bit input write enable
		 );

   /////////////
       //         //
       // FIFO 5  //
       //         //
       /////////////

   FIFO_DUALCLOCK_MACRO  
     #(
       .ALMOST_EMPTY_OFFSET(12'h080), // Sets the almost empty threshold
       .ALMOST_FULL_OFFSET(12'h31E),  // Sets almost full threshold
       .DATA_WIDTH(16),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
       .DEVICE("VIRTEX6"),  // Target device: "VIRTEX5", "VIRTEX6" 
       .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
       .FIRST_WORD_FALL_THROUGH (1) // Sets the FIFO FWFT to 1 or 0 
       ) FIFO_5 (
		 .ALMOSTEMPTY(ae_ff[5]), // 1-bit output almost empty
		 .ALMOSTFULL(af_ff[5]),   // 1-bit output almost full
		 .DO(dout_ff[5][15:0]),                   // Output data, width defined by DATA_WIDTH parameter
		 .EMPTY(mt_ff[5]),             // 1-bit output empty
		 .FULL(full_ff[5]),               // 1-bit output full
		 .RDCOUNT(rc_ff[5]),         // Output read count, width determined by FIFO depth
		 .RDERR(rderr_ff[5]),             // 1-bit output read error
		 .WRCOUNT(wc_ff[5]),         // Output write count, width determined by FIFO depth
		 .WRERR(wrerr_ff[5]),             // 1-bit output write error
		 .DI(din_ff[5][15:0]),                   // Input data, width defined by DATA_WIDTH parameter
		 .RDCLK(DMBVME_CLK_S2),             // 1-bit input read clock
		 .RDEN(RD_EN_FF[5]),               // 1-bit input read enable
		 .RST(fifo_reset[5]),                 // 1-bit input reset
		 .WRCLK(fifo_wr_ck),             // 1-bit input write clock
		 .WREN(wrt_en_ff[5])                // 1-bit input write enable
		 );

   /////////////
       //         //
       // FIFO 6  //
       //         //
       /////////////

   FIFO_DUALCLOCK_MACRO  
     #(
       .ALMOST_EMPTY_OFFSET(12'h080), // Sets the almost empty threshold
       .ALMOST_FULL_OFFSET(12'h31E),  // Sets almost full threshold
       .DATA_WIDTH(16),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
       .DEVICE("VIRTEX6"),  // Target device: "VIRTEX5", "VIRTEX6" 
       .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
       .FIRST_WORD_FALL_THROUGH (1) // Sets the FIFO FWFT to 1 or 0 
       ) FIFO_6 (
		 .ALMOSTEMPTY(ae_ff[6]), // 1-bit output almost empty
		 .ALMOSTFULL(af_ff[6]),   // 1-bit output almost full
		 .DO(dout_ff[6][15:0]),                   // Output data, width defined by DATA_WIDTH parameter
		 .EMPTY(mt_ff[6]),             // 1-bit output empty
		 .FULL(full_ff[6]),               // 1-bit output full
		 .RDCOUNT(rc_ff[6]),         // Output read count, width determined by FIFO depth
		 .RDERR(rderr_ff[6]),             // 1-bit output read error
		 .WRCOUNT(wc_ff[6]),         // Output write count, width determined by FIFO depth
		 .WRERR(wrerr_ff[6]),             // 1-bit output write error
		 .DI(din_ff[6][15:0]),                   // Input data, width defined by DATA_WIDTH parameter
		 .RDCLK(DMBVME_CLK_S2),             // 1-bit input read clock
		 .RDEN(RD_EN_FF[6]),               // 1-bit input read enable
		 .RST(fifo_reset[6]),                 // 1-bit input reset
		 .WRCLK(fifo_wr_ck),             // 1-bit input write clock
		 .WREN(wrt_en_ff[6])                // 1-bit input write enable
		 );

   /////////////
       //         //
       // FIFO 7  //
       //         //
       /////////////

   FIFO_DUALCLOCK_MACRO  
     #(
       .ALMOST_EMPTY_OFFSET(12'h080), // Sets the almost empty threshold
       .ALMOST_FULL_OFFSET(12'h31E),  // Sets almost full threshold
       .DATA_WIDTH(16),   // Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
       .DEVICE("VIRTEX6"),  // Target device: "VIRTEX5", "VIRTEX6" 
       .FIFO_SIZE ("36Kb"), // Target BRAM: "18Kb" or "36Kb" 
       .FIRST_WORD_FALL_THROUGH (1) // Sets the FIFO FWFT to 1 or 0 
       ) FIFO_7 (
		 .ALMOSTEMPTY(ae_ff[7]), // 1-bit output almost empty
		 .ALMOSTFULL(af_ff[7]),   // 1-bit output almost full
		 .DO(dout_ff[7][15:0]),                   // Output data, width defined by DATA_WIDTH parameter
		 .EMPTY(mt_ff[7]),             // 1-bit output empty
		 .FULL(full_ff[7]),               // 1-bit output full
		 .RDCOUNT(rc_ff[7]),         // Output read count, width determined by FIFO depth
		 .RDERR(rderr_ff[7]),             // 1-bit output read error
		 .WRCOUNT(wc_ff[7]),         // Output write count, width determined by FIFO depth
		 .WRERR(wrerr_ff[7]),             // 1-bit output write error
		 .DI(din_ff[7][15:0]),                   // Input data, width defined by DATA_WIDTH parameter
		 .RDCLK(DMBVME_CLK_S2),             // 1-bit input read clock
		 .RDEN(RD_EN_FF[7]),               // 1-bit input read enable
		 .RST(fifo_reset[7]),                 // 1-bit input reset
		 .WRCLK(fifo_wr_ck),             // 1-bit input write clock
		 .WREN(wrt_en_ff[7])                // 1-bit input write enable
		 );

   assign fifo_reset[1] = FIFO_RST[1];
   assign fifo_reset[2] = FIFO_RST[2];
   assign fifo_reset[3] = FIFO_RST[3];
   assign fifo_reset[4] = FIFO_RST[4];
   assign fifo_reset[5] = FIFO_RST[5];
   assign fifo_reset[6] = FIFO_RST[6];
   assign fifo_reset[7] = FIFO_RST[7];
   
   always @*
     begin
	if(FIFO_VME_MODE)
	  begin
	     din_ff[1] <= FF_DATA_IN;
	     din_ff[2] <= FF_DATA_IN;
	     din_ff[3] <= FF_DATA_IN;
	     din_ff[4] <= FF_DATA_IN;
	     din_ff[5] <= FF_DATA_IN;
	     din_ff[6] <= FF_DATA_IN;
	     din_ff[7] <= FF_DATA_IN;
	     wrt_en_ff[1] <= WR_EN_FF[1];
	     wrt_en_ff[2] <= WR_EN_FF[2];
	     wrt_en_ff[3] <= WR_EN_FF[3];
	     wrt_en_ff[4] <= WR_EN_FF[4];
	     wrt_en_ff[5] <= WR_EN_FF[5];
	     wrt_en_ff[6] <= WR_EN_FF[6];
	     wrt_en_ff[7] <= WR_EN_FF[7];
	  end
	else
	  begin
	     din_ff[1] <= wdata_ff[1];
	     din_ff[2] <= wdata_ff[2];
	     din_ff[3] <= wdata_ff[3];
	     din_ff[4] <= wdata_ff[4];
	     din_ff[5] <= wdata_ff[5];
	     din_ff[6] <= wdata_ff[6];
	     din_ff[7] <= wdata_ff[7];
	     wrt_en_ff[1] <= wd_vld_ff[1];
	     wrt_en_ff[2] <= wd_vld_ff[2];
	     wrt_en_ff[3] <= wd_vld_ff[3];
	     wrt_en_ff[4] <= wd_vld_ff[4];
	     wrt_en_ff[5] <= wd_vld_ff[5];
	     wrt_en_ff[6] <= wd_vld_ff[6];
	     wrt_en_ff[7] <= wd_vld_ff[7];
	  end
     end
   

   always @*
     begin
	case(FIFO_SEL)
	  8'h01:   FF_DATA_OUT <= dout_ff[1];
	  8'h02:   FF_DATA_OUT <= dout_ff[2];
	  8'h04:   FF_DATA_OUT <= dout_ff[3];
	  8'h08:   FF_DATA_OUT <= dout_ff[4];
	  8'h10:   FF_DATA_OUT <= dout_ff[5];
	  8'h20:   FF_DATA_OUT <= dout_ff[6];
	  8'h40:   FF_DATA_OUT <= dout_ff[7];
	  default: FF_DATA_OUT <= 16'h0000;
	endcase
     end

   fifo_wrd_count #(.width(12)) fifo_wrd_count_ff_1(.RST(fifo_reset[1]),.CLK(fifo_wr_ck),.WE(wrt_en_ff[1]),
						    .RE(RD_EN_FF[1]),.FULL(full_ff[1]),.COUNT(wrdc_ff[1]));
   fifo_wrd_count #(.width(12)) fifo_wrd_count_ff_2(.RST(fifo_reset[2]),.CLK(fifo_wr_ck),.WE(wrt_en_ff[2]),
						    .RE(RD_EN_FF[2]),.FULL(full_ff[2]),.COUNT(wrdc_ff[2]));
   fifo_wrd_count #(.width(12)) fifo_wrd_count_ff_3(.RST(fifo_reset[3]),.CLK(fifo_wr_ck),.WE(wrt_en_ff[3]),
						    .RE(RD_EN_FF[3]),.FULL(full_ff[3]),.COUNT(wrdc_ff[3]));
   fifo_wrd_count #(.width(12)) fifo_wrd_count_ff_4(.RST(fifo_reset[4]),.CLK(fifo_wr_ck),.WE(wrt_en_ff[4]),
						    .RE(RD_EN_FF[4]),.FULL(full_ff[4]),.COUNT(wrdc_ff[4]));
   fifo_wrd_count #(.width(12)) fifo_wrd_count_ff_5(.RST(fifo_reset[5]),.CLK(fifo_wr_ck),.WE(wrt_en_ff[5]),
						    .RE(RD_EN_FF[5]),.FULL(full_ff[5]),.COUNT(wrdc_ff[5]));
   fifo_wrd_count #(.width(12)) fifo_wrd_count_ff_6(.RST(fifo_reset[6]),.CLK(fifo_wr_ck),.WE(wrt_en_ff[6]),
						    .RE(RD_EN_FF[6]),.FULL(full_ff[6]),.COUNT(wrdc_ff[6]));
   fifo_wrd_count #(.width(12)) fifo_wrd_count_ff_7(.RST(fifo_reset[7]),.CLK(fifo_wr_ck),.WE(wrt_en_ff[7]),
						    .RE(RD_EN_FF[7]),.FULL(full_ff[7]),.COUNT(wrdc_ff[7]));

   always @*
     begin
	case(FIFO_SEL)
	  8'h01:   FF_WRD_CNT <= wrdc_ff[1];
	  8'h02:   FF_WRD_CNT <= wrdc_ff[2];
	  8'h04:   FF_WRD_CNT <= wrdc_ff[3];
	  8'h08:   FF_WRD_CNT <= wrdc_ff[4];
	  8'h10:   FF_WRD_CNT <= wrdc_ff[5];
	  8'h20:   FF_WRD_CNT <= wrdc_ff[6];
	  8'h40:   FF_WRD_CNT <= wrdc_ff[7];
	  default: FF_WRD_CNT <= 16'h0000;
	endcase
     end

   assign FF_STATUS = {1'b0,full_ff,1'b0,mt_ff};

endmodule

