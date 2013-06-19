`timescale 1ns / 1ps

module daq_ddu_out #(
		     parameter SIM_SPEEDUP = 0
		     )
   (
    input 	 RST,
    // External signals
    input 	 RX_DDU_N, // GTX receive data in - signal
    input 	 RX_DDU_P, // GTX receive data in + signal
    output 	 TX_DDU_N, // GTX transmit data out - signal
    output 	 TX_DDU_P, // GTX transmit data out + signal
    // Reference clocks ideally straight from the IBUFDS_GTXE1 output 
    input 	 REF_CLK_80, // 80 MHz for  DDU data rate
    // Internal signals
    input [15:0] TXD, // Data to be transmitted
    input 	 TXD_VLD, // Flag for valid data;
    output 	 DDU_DATA_CLK         // Clock that should be used for passing data and controls to this module
    );
   
   localparam IDLE2 = 16'h50BC;

   wire 	 usr_clk_wordwise;
   
   // Physical interface signals
   reg [1:0] 	 tx_ddu_k;
   reg [15:0] 	 tx_ddu_data;
   
//   wire 	 txout_clk80;
 //  wire 	 pll_lock_ddu;
 //  wire 	 rst_done_ddu;

   assign DDU_DATA_CLK = usr_clk_wordwise;
   
   BUFG ddu_clk_i (.O(usr_clk_wordwise),.I(REF_CLK_80));
   
   //-----------------------------------------------------------------------------
   // Main body of code
   //-----------------------------------------------------------------------------

   //--------------------------------------------------------------------
   // GTX PMA reset circuitry
   //--------------------------------------------------------------------

   gtx_80_ddu_custom #
     (
      .WRAPPER_SIM_GTXRESET_SPEEDUP   (SIM_SPEEDUP)      // Set this to 1 for simulation
      )
   gtx_80_ddu_custom_i
     (
      //_____________________________________________________________________
      //_____________________________________________________________________
      //GTX0  (X0Y4)
      .GTX0_DOUBLE_RESET_CLK_IN       (usr_clk_wordwise),
      //----------------- Receive Ports - RX Data Path interface -----------------
      .GTX0_RXRESET_IN                (RST),
      //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
      .GTX0_RXN_IN                    (RX_DDU_N),
      .GTX0_RXP_IN                    (RX_DDU_P),
      //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
      .GTX0_TXCHARISK_IN              (tx_ddu_k),
      //---------------- Transmit Ports - TX Data Path interface -----------------
      .GTX0_TXDATA_IN                 (tx_ddu_data),
      .GTX0_TXOUTCLK_OUT              (txout_clk80),
      .GTX0_TXRESET_IN                (RST),
      .GTX0_TXUSRCLK2_IN              (usr_clk_wordwise),
      //-------------- Transmit Ports - TX Driver and OOB signaling --------------
      .GTX0_TXN_OUT                   (TX_DDU_N),
      .GTX0_TXP_OUT                   (TX_DDU_P),
      //--------------------- Transmit Ports - TX PLL Ports ----------------------
      .GTX0_GTXTXRESET_IN             (RST),
      .GTX0_MGTREFCLKTX_IN            (REF_CLK_80),
      .GTX0_PLLTXRESET_IN             (RST),
      .GTX0_TXPLLLKDET_OUT            (pll_lock_ddu),
      .GTX0_TXRESETDONE_OUT           (rst_done_ddu)
      );

   // Pipeline and multiplexer

   always @(posedge usr_clk_wordwise)
     begin
	if (TXD_VLD)
	  begin
	     tx_ddu_data <= TXD;
	     tx_ddu_k <= 2'b00;
	  end
	else
	  begin
	     tx_ddu_data <= IDLE2;
	     tx_ddu_k <= 2'b01;
	  end
     end

endmodule
