`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Ben Bylsma
// 
// Create Date:    10/12/2012 
// Design Name:    ODMB
// Module Name:    rx_frame_proc 
//
//   Identifies and processes incoming data packets from the DCFEBs.  Creates a valid data flag
//   for downstream processing, calculates the CRC for the packet and compares to the transmitted
//   CRC, creates a "good_crc" flag and a valid CRC signal.
//
//////////////////////////////////////////////////////////////////////////////////

module rx_frame_proc
  (
   
   // inputs
   input 	     CLK,
   input 	     RST,
   // 1000BASE-X PCS/PMA interface
   input [15:0]      RXDATA,
   input [1:0] 	     RX_IS_K,
   input [1:0] 	     RXDISPERR,
   input [1:0] 	     RXNOTINTABLE,
   // client inputs
   input 	     FF_FULL,
   input 	     FF_AF,
   // client outputs
   output reg [15:0] FRM_DATA,
   output reg 	     FRM_DATA_VALID,
   output 	     GOOD_CRC,
   output reg 	     CRC_CHK_VLD
   );

   ////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
    // ================================= Ethernet Parameters Common to both Receive and Transmit ======== //
    // -------------------------------------------------------------------------------------------------- //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

   // Define Octet constants
   localparam
     D2_2  = 8'h42,        
     D5_6  = 8'hC5,        
     D16_2 = 8'h50,        
     D21_5 = 8'hB5,        
     K28_5 = 8'hBC,      
     K23_7 = 8'hF7,     // /R/ Carrier Extend
     K27_7 = 8'hFB,     // /S/ SOP
     K29_7 = 8'hFD,     // /T/ EOP
     K30_7 = 8'hFE,     // /V/ ERROR_Prop
     PRMBL = 8'h55,     // Preamble octet
     SOF_BYTE = 8'hD5;  // Start of Frame octet

   localparam
     IDLE1 = {D5_6,K28_5},
     IDLE2 = {D16_2,K28_5},
     PREAMBLE1 = {PRMBL,K27_7},     // Start of Packet plus first preamble word 
     PREAMBLE2 = {PRMBL,PRMBL},     // Preamble words 
     PREAMBLE3 = {PRMBL,PRMBL},     // Preamble words 
     PREAMBLE4 = {SOF_BYTE,PRMBL},  // Preamble plus Start of Frame word 
     Carrier_Extend = {K23_7,K23_7},  // Carrier extend 
     End_of_Packet = {K23_7,K29_7};  // End of Packet plus carrier extend 

   ////////////////////////////////////////////////////////////////////////////////////////////////////////
   // Signals
   ////////////////////////////////////////////////////////////////////////////////////////////////////////

   wire 	     rxvaldat_d1;
   reg 		     rxvaldat_d2, rxvaldat_r;
   wire 	     crc_valid_r;
   wire 	     l1a_valid;
   wire [2:0] 	     state;
   reg [11:0] 	     len_count;
   reg [3:0] 	     state_err;
   reg [15:0] 	     data_r,data_d1,data_d2,data_d2_swap;
   reg 		     sop,sof_even,sof_odd,pre,eop_even,eop_odd,nok;
   reg 		     wrng_sop,idle,car_xtend,err_prop;
   wire 	     err;
   reg 		     swap_bytes;

   wire 	     ckcrc;
   wire 	     clr;
   wire 	     drop;
   wire 	     eop;
   wire 	     sof;
   wire 	     error;

   wire [31:0] 	     crc_reg;
   wire [15:0] 	     crc;
   wire 	     crc_calc;
   wire 	     crc_init;
   wire 	     crc_dv;
   wire 	     crc_mtch;
   wire 	     clr_crc_chk;
   reg 		     bad_crc;


   always @ (posedge CLK)
     begin
	idle <= (RX_IS_K == 2'b01)  && ((RXDATA[15:0] == IDLE1) || (RXDATA[15:0] == IDLE2));
	car_xtend <= (RX_IS_K[1] == 1'b1) && (RXDATA[15:8] == K23_7) || (RX_IS_K[0] == 1'b1) && (RXDATA[7:0] == K23_7);
	err_prop <= (RX_IS_K[1] == 1'b1) && (RXDATA[15:8] == K30_7) || (RX_IS_K[0] == 1'b1) && (RXDATA[7:0] == K30_7);
	wrng_sop <= (RX_IS_K[1] == 1'b1) && (RXDATA[15:8] == K27_7);
	sop <= (RX_IS_K[0] == 1'b1) && (RXDATA[7:0]  == K27_7);
	eop_odd  <= (RX_IS_K[1] == 1'b1) && (RXDATA[15:8] == K29_7);
	eop_even <= (RX_IS_K[0] == 1'b1) && (RXDATA[7:0] == K29_7);
	pre <= !rxvaldat_d1 && ((RXDATA[15:8] == PRMBL) || (RXDATA[7:0] == PRMBL));
	sof_odd <= !rxvaldat_d1 && (RXDATA[15:8] == SOF_BYTE);
	sof_even <= !rxvaldat_d1 && (RXDATA[7:0] == SOF_BYTE);
	nok <= (RX_IS_K == 2'b00);
     end
   
   assign in_err = !clr && ((RXDISPERR != 2'b00) || (RXNOTINTABLE != 2'b00));
   assign out_err = clr && ((RXDISPERR != 2'b00) || (RXNOTINTABLE != 2'b00));
   assign rx_err = in_err || (sop && (FF_FULL || FF_AF)) || wrng_sop;
   assign        eop = eop_odd || eop_even;
   assign        sof = sof_even || sof_odd;
   assign      error = rx_err || err;
   assign     last_crc = ~rxvaldat_d1 & rxvaldat_d2;
   assign crc_valid_r = ~rxvaldat_d1 & rxvaldat_r;
   assign   l1a_valid = rxvaldat_d1 & ~rxvaldat_r;
   assign crc_calc = rxvaldat_d1 & rxvaldat_r;
   assign crc_dv = crc_calc | last_crc;
   assign crc_mtch = (data_r == crc);
   assign crc_init = sop;
   assign clr_crc_chk = sop;
   assign GOOD_CRC = !bad_crc;

   always @ (posedge CLK)
     begin
	data_d1 <= RXDATA;
	data_d2 <= data_d1;
	data_r <= data_d2;
	rxvaldat_d2 <= rxvaldat_d1;
	rxvaldat_r <= rxvaldat_d2;
	FRM_DATA_VALID <= rxvaldat_d1 & rxvaldat_r;
	FRM_DATA       <= data_r;
	CRC_CHK_VLD <= ckcrc;
     end

   pkt_proc  #(
	       .MAX_COUNT(812)
	       )
   pkt_proc_i(
	      .CKCRC(ckcrc),
	      .CLR(clr),
	      .DROP(drop),
	      .ERR(err),
	      .RXVALID(rxvaldat_d1),
	      .STATE(state),
	      .CAR_XTEND(car_xtend),
	      .CLK(CLK),
	      .EOP(eop),
	      .ERR_PROP(err_prop),
	      .IDLE(idle),
	      .LEN_COUNT(len_count),
	      .NOK(nok),
	      .PRE(pre),
	      .RST(RST),
	      .SOF(sof),
	      .SOP(sop)
	      );

   crc32_bgb crc_gen_i(
		       .crc_reg(crc_reg), 
		       .crc(crc),
		       .d(data_r),
		       .calc(crc_calc),
		       .init(crc_init),
		       .d_valid(crc_dv),
		       .clk(CLK),
		       .reset(RST)
		       );


   always @(posedge CLK or posedge RST)
     begin
	if(RST)
	  bad_crc <= 1'b0;
	else
	  if(crc_valid_r)
	    bad_crc <= !crc_mtch;
	  else if(clr_crc_chk)
	    bad_crc <= 1'b0;
	  else
	    bad_crc <= bad_crc;
     end

   always @(posedge CLK)
     begin: DATA_LEN_REG
	if (clr)
	  len_count <= 12'h000;
	else if (rxvaldat_d1 && rxvaldat_r)
	  len_count <= len_count + 1;
	else
	  len_count <= len_count;
     end

   always @(posedge CLK or posedge RST)
     begin: STATE_ERR_REG
	if (RST)
	  state_err <= 0;
	else
	  if(clr)
	    state_err <= 0;
	  else if (err)
	    state_err <= {error,state};
	  else
	    state_err <= state_err;
     end

endmodule
