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

module rx_frame_proc_la(
// Chip Scope Pro Logic Analyzer control -- bgb

   inout [35:0] CSP_PKT_FRM_LA_CTRL,
	
	// inputs
	input CLK,
	input RST,
	// 1000BASE-X PCS/PMA interface
	input [15:0] RXDATA,
	input [1:0] RX_IS_K,
	input [1:0] RXDISPERR,
	input [1:0] RXNOTINTABLE,
	// client inputs
	input FF_FULL,
	input FF_AF,
	// client outputs
	output reg [15:0] FRM_DATA,
	output reg FRM_DATA_VALID,
	output GOOD_CRC,
	output reg CRC_CHK_VLD
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

wire rxvaldat_d1;
reg rxvaldat_d2, rxvaldat_r;
wire crc_valid_r;
wire l1a_valid;
wire [2:0] state;
reg [11:0] len_count;
reg [3:0] state_err;
reg [15:0] data_r,data_d1,data_d2,data_d2_swap;
reg sop,sof_even,sof_odd,pre,eop_even,eop_odd,nok;
reg wrng_sop,idle,car_xtend,err_prop;
wire err;

wire ckcrc;
wire clr;
wire drop;
wire eop;
wire sof;
wire error;

wire [31:0] crc_reg;
wire [15:0] crc;
wire crc_calc;
wire crc_init;
wire crc_dv;
wire crc_mtch;
wire clr_crc_chk;
reg bad_crc;

//-----------------------------------------------------------------------------
// Logic Analyzer
//-----------------------------------------------------------------------------

wire [127:0] csp_pkt_frm_la_data;
wire [7:0]  csp_pkt_frm_la_trig;

//	csp_pkt_frm_la csp_pkt_frm_la_i (
//		 .CONTROL(CSP_PKT_FRM_LA_CTRL),
//		 .CLK(CLK),
//		 .DATA(csp_pkt_frm_la_data), // IN BUS [127:0]
//		 .TRIG0(csp_pkt_frm_la_trig) // IN BUS [7:0]
//	);
	

// LA Trigger [7:0]
	assign csp_pkt_frm_la_trig[0]      = sop;
	assign csp_pkt_frm_la_trig[1]      = sof;
	assign csp_pkt_frm_la_trig[2]      = eop_even;
	assign csp_pkt_frm_la_trig[3]      = eop_odd;
	assign csp_pkt_frm_la_trig[4]      = wrng_sop;
	assign csp_pkt_frm_la_trig[5]      = rxvaldat_d1;
	assign csp_pkt_frm_la_trig[6]      = crc_valid_r;
	assign csp_pkt_frm_la_trig[7]      = l1a_valid;

// LA Data [127:0]
	assign csp_pkt_frm_la_data[15:0]    = data_r;
	assign csp_pkt_frm_la_data[31:16]   = crc;
	assign csp_pkt_frm_la_data[63:32]   = crc_reg;
	assign csp_pkt_frm_la_data[75:64]   = len_count;
	assign csp_pkt_frm_la_data[79:76]   = {1'b0,state};
	assign csp_pkt_frm_la_data[87:80]   = {3'b000,state_err};
	
	assign csp_pkt_frm_la_data[88]      = sop;
	assign csp_pkt_frm_la_data[89]      = sof;
	assign csp_pkt_frm_la_data[90]      = pre;
	assign csp_pkt_frm_la_data[91]      = eop_even;
	assign csp_pkt_frm_la_data[92]      = eop_odd;
	assign csp_pkt_frm_la_data[93]      = eop;
	assign csp_pkt_frm_la_data[94]      = nok;
	assign csp_pkt_frm_la_data[95]      = idle;
	assign csp_pkt_frm_la_data[96]      = car_xtend;
	assign csp_pkt_frm_la_data[97]      = err_prop;
	assign csp_pkt_frm_la_data[98]      = err;
	assign csp_pkt_frm_la_data[99]      = error;
	assign csp_pkt_frm_la_data[100]      = l1a_valid;
	assign csp_pkt_frm_la_data[101]      = rxvaldat_d1;
	assign csp_pkt_frm_la_data[102]      = rxvaldat_r;
	assign csp_pkt_frm_la_data[103]      = crc_valid_r;
	assign csp_pkt_frm_la_data[104]      = ckcrc;
	assign csp_pkt_frm_la_data[105]      = CRC_CHK_VLD;
	assign csp_pkt_frm_la_data[106]      = clr;
	assign csp_pkt_frm_la_data[107]      = drop;
	
	assign csp_pkt_frm_la_data[108]      = crc_calc;
	assign csp_pkt_frm_la_data[109]      = crc_init;
	assign csp_pkt_frm_la_data[110]      = crc_dv;
	assign csp_pkt_frm_la_data[111]      = crc_mtch;
	assign csp_pkt_frm_la_data[112]      = clr_crc_chk;
	assign csp_pkt_frm_la_data[113]      = bad_crc;
	assign csp_pkt_frm_la_data[114]      = sof_odd;
	assign csp_pkt_frm_la_data[115]      = sof_even;
	assign csp_pkt_frm_la_data[116]      = 1'b0;
	assign csp_pkt_frm_la_data[117]      = 1'b0;
	assign csp_pkt_frm_la_data[118]      = 1'b0;
	assign csp_pkt_frm_la_data[119]      = 1'b0;
	assign csp_pkt_frm_la_data[120]      = 1'b0;
	assign csp_pkt_frm_la_data[121]      = 1'b0;
	assign csp_pkt_frm_la_data[122]      = 1'b0;
	assign csp_pkt_frm_la_data[123]      = 1'b0;
	assign csp_pkt_frm_la_data[124]      = 1'b0;
	assign csp_pkt_frm_la_data[125]      = 1'b0;
	assign csp_pkt_frm_la_data[126]      = 1'b0;
	assign csp_pkt_frm_la_data[127]      = 1'b0;

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
