`timescale 1ns / 1ps
module daq_optical_out #(
			 parameter USE_CHIPSCOPE = 1,
			 parameter SIM_SPEEDUP = 0
			 )
   (
    inout [35:0]      DAQ_TX_VIO_CNTRL, //Chip Scope Pro control signals for virtual I/O
    inout [35:0]      DAQ_TX_LA_CNTRL, //Chip Scope Pro control signals for logic analyzer
    input 	      RST,
    // External signals
    input 	      DAQ_RX_N, // GTX receive data in - signal
    input 	      DAQ_RX_P, // GTX receive data in + signal
    output 	      DAQ_TDIS, // optical transceiver transmit disable signal
    output 	      DAQ_TX_N, // GTX transmit data out - signal
    output 	      DAQ_TX_P, // GTX transmit data out + signal
    // Reference clocks ideally straight from the IBUFDS_GTXE1 output 
    input 	      DAQ_TX_125REFCLK, // 125 MHz for 1 GbE
    input 	      DAQ_TX_125REFCLK_DV2, // 62.5 MHz user clock for 1 GbE
    input 	      DAQ_TX_160REFCLK, // 160 MHz for  2.56 GbE
    // Internal signals
    input 	      L1A_MATCH, // Currently only for logic analyzer input
    input [15:0]      TXD, // Data to be transmitted
    input 	      TXD_VLD, // Flag for valid data; initiates data transfer
    input 	      JDAQ_RATE, // requested DAQ rate from JTAG interface
    output 	      RATE_1_25, // Flag to indicate 1.25 Gbps line rate operation
    output 	      RATE_3_2, // Flag to indicate 3.2 Gbps line rate operation
    output 	      TX_ACK, // Handshake signal indicates preamble has been sent, data flow should start
    output 	      DAQ_DATA_CLK, // Clock that should be used for passing data and controls to this module
    // FIFO signals
    input 	      FIFO_RST,
    input 	      RD_EN_FF,
    input 	      VME_CLK,
    output reg [15:0] FIFO_DATA_OUT,
    output reg [11:0] FIFO_WRD_CNT
   
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
     SOP_PRE = {PRMBL,K27_7},     // Start of Packet plus first preamble word 
     PREAMBLE = {PRMBL,PRMBL},     // Preamble words 
     SOF_PRE = {SOF_BYTE,PRMBL},  // Preamble plus Start of Frame word 
     Carrier_Extend = {K23_7,K23_7},  // Carrier extend 
     End_of_Packet = {K23_7,K29_7};  // End of Packet plus carrier extend 

   ////////////////////////////////////////////////////////////////////////////////////////////////////////
   // Signals
   ////////////////////////////////////////////////////////////////////////////////////////////////////////

   reg [15:0] 	 cnst;
   reg [1:0] 	 kcnst;
   reg [15:0] 	 data1;
   reg 		 crc_calc1;
   
   wire 	 usr_clk_wordwise;
   wire 	 inc_rom;
   wire 	 rst_rom;
   reg [2:0] 	 rom_addr;
   wire [2:0] 	 rom_addr_p1;
   wire [2:0] 	 rom_addr_p2;
   wire [2:0] 	 rom_addr_p3;
   wire [2:0] 	 frm_state;
   wire [3:0] 	 dqrt_state;

   wire 	 clr_crc;
   wire 	 crc_calc;
   wire 	 crc_vld;
   reg 		 crc_vld1, crc_vld2;
   wire [31:0] 	 crc_reg;
   wire [15:0] 	 crc;
   reg [15:0] 	 crc1;
   wire 	 crc_dv;
   

   // Asynchronous reset signals
   wire 	 arst;
   wire 	 man_rst;
   wire 	 reset_i;
   // ASYNC_REG attribute added to simulate actual behavior under
   // asynchronous operating conditions.
   (* ASYNC_REG = "TRUE" *)
   reg [3:0] 	 reset_r;
   (* ASYNC_REG = "TRUE" *)
   reg [ 3:0] 	 pma_reset_r;
   wire 	 pma_reset_i;
   wire 	 txresetdone;
   wire 	 clk_rst_done;
   wire 	 cdv_init;
   
   // Physical interface signals
   wire 	 txreset;
   wire 	 pcs_rst;
   wire 	 div_clk_rst;
   wire [1:0] 	 txbufstatus_float;
   reg [1:0] 	 txcharisk_r;
   reg [15:0] 	 mgt_tx_data_r;
   wire [2:0] 	 ref_clk_sel;
   wire [1:0] 	 txrate_sel;
   wire 	 txrate_done;
   wire 	 word_clk_sel;
   wire [12:0] 	 gtxtest;
   
   // Transceiver clocking signals
   wire 	 txoutclk;
   wire 	 plllock_i;
   
   // DAQ rate control signals
   wire 	 daq_tx_dis;
   wire 	 man_daq_tx_dis;
   wire 	 man_control;
   wire 	 man_daq_rate;
   
   wire 	 daq_rate;
   wire 	 clr_cnt;
   wire 	 inc_cnt;
   reg [3:0] 	 count;

   // FIFO signals
   wire 	 ae_ff, af_ff, empty_ff, full_ff;
   wire [15:0] 	 din_ff, dout_ff;
   wire 	 wren_ff;
   wire 	 rderr_ff, wrerr_ff;
   wire [10:0] 	 rc_ff, wc_ff;
   wire 	 fifo_reset;
   wire [11:0] 	 fifo_wrd_cnt_wire;
   
   

   generate
      if(USE_CHIPSCOPE==1) 
	begin : chipscope_daq_tx
	   wire [15:0] daq_tx_async_in;
	   wire [3:0]  daq_tx_async_out;
	   wire [109:0] daq_tx_la_data;
	   wire [7:0] 	daq_tx_la_trig;

	   wire [3:0] 	dummy_asigs;

	   daq_tx_vio daq_tx_vio_i (
				    .CONTROL(DAQ_TX_VIO_CNTRL), // INOUT BUS [35:0]
				    .ASYNC_IN(daq_tx_async_in), // IN BUS [15:0]
				    .ASYNC_OUT(daq_tx_async_out) // OUT BUS [3:0]
				    );


	   //		 ASYNC_IN [15:0]
	   assign daq_tx_async_in[0]     = reset_i;
	   assign daq_tx_async_in[1]     = pma_reset_i;
	   assign daq_tx_async_in[2]     = arst;
	   assign daq_tx_async_in[3]     = txresetdone;
	   assign daq_tx_async_in[4]     = txreset;
	   assign daq_tx_async_in[5]     = TXD_VLD;
	   assign daq_tx_async_in[6]     = daq_tx_dis;
	   assign daq_tx_async_in[7]     = man_daq_rate;
	   assign daq_tx_async_in[8]     = daq_rate;
	   assign daq_tx_async_in[9]     = plllock_i;
	   assign daq_tx_async_in[10]     = JDAQ_RATE;
	   assign daq_tx_async_in[11]     = RATE_1_25;
	   assign daq_tx_async_in[12]     = RATE_3_2;
	   assign daq_tx_async_in[13]     = word_clk_sel;
	   assign daq_tx_async_in[14]     = txrate_done;
	   assign daq_tx_async_in[15]     = 1'b0;

	   
	   //		 ASYNC_OUT [3:0]
	   assign man_daq_tx_dis     = daq_tx_async_out[0];
	   assign man_rst            = daq_tx_async_out[1];
	   assign man_control        = daq_tx_async_out[2];
	   assign man_daq_rate       = daq_tx_async_out[3];
	   

	   daq_tx_la daq_tx_la_i (
				  .CONTROL(DAQ_TX_LA_CNTRL),
				  .CLK(usr_clk_wordwise),
				  .DATA(daq_tx_la_data), // IN BUS [109:0]
				  .TRIG0(daq_tx_la_trig) // IN BUS [7:0]
				  );
	   
	   // LA Data [109:0]
	   assign daq_tx_la_data[15:0]    = TXD;
	   assign daq_tx_la_data[31:16]   = crc;
	   assign daq_tx_la_data[35:32]   = reset_r;
	   assign daq_tx_la_data[39:36]   = pma_reset_r;
	   assign daq_tx_la_data[40]      = man_rst;
	   assign daq_tx_la_data[41]      = arst;
	   assign daq_tx_la_data[42]      = reset_i;
	   assign daq_tx_la_data[43]      = pma_reset_i;
	   assign daq_tx_la_data[44]      = man_daq_tx_dis;
	   assign daq_tx_la_data[45]      = daq_tx_dis;
	   assign daq_tx_la_data[46]      = txreset;
	   assign daq_tx_la_data[47]      = TXD_VLD;
	   assign daq_tx_la_data[48]      = TX_ACK;
	   assign daq_tx_la_data[49]      = pcs_rst;
	   assign daq_tx_la_data[50]      = man_control;
	   assign daq_tx_la_data[51]      = txrate_done;
	   assign daq_tx_la_data[52]      = man_daq_rate;
	   assign daq_tx_la_data[54:53]   = txrate_sel;
	   assign daq_tx_la_data[57:55]   = ref_clk_sel;
	   assign daq_tx_la_data[59:58]   = txcharisk_r;
	   assign daq_tx_la_data[60]      = word_clk_sel;
	   assign daq_tx_la_data[61]      = plllock_i;
	   assign daq_tx_la_data[62]      = clr_cnt;
	   assign daq_tx_la_data[63]      = inc_cnt;
	   assign daq_tx_la_data[64]      = L1A_MATCH;
	   assign daq_tx_la_data[65]      = 1'b0;
	   assign daq_tx_la_data[66]      = JDAQ_RATE;
	   assign daq_tx_la_data[67]      = RATE_1_25;
	   assign daq_tx_la_data[68]      = RATE_3_2;
	   assign daq_tx_la_data[69]      = daq_rate;
	   assign daq_tx_la_data[73:70]   = count;
	   assign daq_tx_la_data[74]      = crc_dv;
	   assign daq_tx_la_data[75]      = clr_crc;
	   assign daq_tx_la_data[76]      = crc_calc;
	   assign daq_tx_la_data[77]      = crc_vld1;
	   assign daq_tx_la_data[78]      = crc_vld2;
	   assign daq_tx_la_data[79]      = inc_rom;
	   assign daq_tx_la_data[80]      = rst_rom;
	   assign daq_tx_la_data[83:81]   = rom_addr;
	   assign daq_tx_la_data[87:84]   = {1'b0,frm_state};
	   assign daq_tx_la_data[88]      = cdv_init;
	   assign daq_tx_la_data[89]      = div_clk_rst;
	   assign daq_tx_la_data[105:90]  = mgt_tx_data_r;
	   assign daq_tx_la_data[109:106]  = dqrt_state;

	   // LA Trigger [7:0]
	   assign daq_tx_la_trig[0]      = man_rst;
	   assign daq_tx_la_trig[1]      = man_daq_tx_dis;
	   assign daq_tx_la_trig[2]      = TXD_VLD;
	   assign daq_tx_la_trig[3]      = TX_ACK;
	   assign daq_tx_la_trig[4]      = L1A_MATCH;
	   assign daq_tx_la_trig[5]      = txrate_done;
	   assign daq_tx_la_trig[6]      = plllock_i;
	   assign daq_tx_la_trig[7]      = daq_rate;

	end
      else
	begin : no_chipscope_daq_tx
	   assign man_rst = 0;
	   assign man_daq_tx_dis = 0;
	   assign man_control  = 0;
	   assign man_daq_rate = 1;
	end
   endgenerate

   assign DAQ_DATA_CLK = usr_clk_wordwise;
   assign daq_tx_dis = man_daq_tx_dis;
   assign daq_rate = man_control ? man_daq_rate : JDAQ_RATE;
   assign crc_dv = crc_calc | crc_vld;
   
   OBUF  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_DAQ_TDIS (.O(DAQ_TDIS),.I(daq_tx_dis));
   //BUFGMUX daq_clk_mux_i (.O(usr_clk_wordwise),.I0(DAQ_TX_125REFCLK_DV2),.I1(DAQ_TX_160REFCLK),.S(word_clk_sel));
   
   //   BUFG usr_clk_buf (.O(usr_clk_wordwise), .I(DAQ_TX_125REFCLK_DV2));
   assign usr_clk_wordwise = DAQ_TX_125REFCLK_DV2;
   //  assign usr_clk_wordwise = DAQ_TX_160REFCLK;
   
   
   //-----------------------------------------------------------------------------
   // Main body of code
   //-----------------------------------------------------------------------------

   //--------------------------------------------------------------------
   // GTX PMA reset circuitry
   //--------------------------------------------------------------------

   
   assign arst = RST | man_rst;
   
   always@(posedge usr_clk_wordwise or posedge arst)
     if (arst == 1'b1)
       pma_reset_r <= 4'b1111;
     else
       pma_reset_r <= {pma_reset_r[2:0], arst};

   assign pma_reset_i = pma_reset_r[3];
   assign txreset = pma_reset_i | pcs_rst;

   //-------------------------------------------------------------------------
   // Main reset circuitry
   //-------------------------------------------------------------------------

   // Synchronize and extend the external reset signal
   always @(posedge usr_clk_wordwise or posedge arst)
     begin
        if (arst == 1)
          reset_r <= 4'b1111;
        else
          begin
             if (plllock_i == 1)
               reset_r <= {reset_r[2:0], arst};
          end
     end

   // Apply the extended reset pulse to the EMAC
   assign reset_i = reset_r[3];
   assign gtxtest = {11'h400,div_clk_rst,1'b0};

   clk_div_reset
     clk_div_reset_i
       (
	.CLK(usr_clk_wordwise),
	.PLLLKDET(plllock_i),
	.TX_RATE(txrate_sel[0]),
	.INIT(cdv_init),
	.GTXTEST_DONE(clk_rst_done),
	.GTXTEST_BIT1(div_clk_rst)
	);


   DAQ_Rate_Sel_FSM 
     DAQ_Rate_Sel_FSM_i(
			.CDV_INIT(cdv_init),
			.CLK_SEL(ref_clk_sel),
			.CLR_CNT(clr_cnt),
			.INC_CNT(inc_cnt),
			.PCSRST(pcs_rst),
			.RATE_1_25(RATE_1_25),
			.RATE_3_2(RATE_3_2),
			.RATE_SEL(txrate_sel),
			.WRDCLKSEL(word_clk_sel),
			.DQRT_STATE(dqrt_state),
			.CDV_DONE(clk_rst_done),
			.CLK(usr_clk_wordwise),
			.CNT(count),
			.DAQ_RATE(daq_rate),
			.RST(arst),
			.TXRATEDONE(txrate_done)
			);

   always @(posedge usr_clk_wordwise or posedge clr_cnt)
     begin
	if(clr_cnt)
	  count <= 4'd0;
	else
	  if(inc_cnt)
	    count <= count + 1;
	  else
	    count <= count;
     end

   FD FD_rom_addr_01 (.Q(rom_addr_p1[0]),.C(usr_clk_wordwise),.D(rom_addr[0]));  // Here's one way of doing it.
   FD FD_rom_addr_02 (.Q(rom_addr_p1[1]),.C(usr_clk_wordwise),.D(rom_addr[1]));
   FD FD_rom_addr_03 (.Q(rom_addr_p1[2]),.C(usr_clk_wordwise),.D(rom_addr[2]));
   FD FD_rom_addr_11 (.Q(rom_addr_p2[0]),.C(usr_clk_wordwise),.D(rom_addr_p1[0]));  
   FD FD_rom_addr_12 (.Q(rom_addr_p2[1]),.C(usr_clk_wordwise),.D(rom_addr_p1[1]));
   FD FD_rom_addr_13 (.Q(rom_addr_p2[2]),.C(usr_clk_wordwise),.D(rom_addr_p1[2]));
   FD FD_rom_addr_21 (.Q(rom_addr_p3[0]),.C(usr_clk_wordwise),.D(rom_addr_p2[0]));  
   FD FD_rom_addr_22 (.Q(rom_addr_p3[1]),.C(usr_clk_wordwise),.D(rom_addr_p2[1]));
   FD FD_rom_addr_23 (.Q(rom_addr_p3[2]),.C(usr_clk_wordwise),.D(rom_addr_p2[2]));
      
   FIFO_DUALCLOCK_MACRO  
     #(
       .ALMOST_EMPTY_OFFSET(12'h080),	// Sets the almost empty threshold
       .ALMOST_FULL_OFFSET(12'h31E),	// Sets almost full threshold
       .DATA_WIDTH(16),			// Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
       .DEVICE("VIRTEX6"),		// Target device: "VIRTEX5", "VIRTEX6" 
       .FIFO_SIZE ("36Kb"),		// Target BRAM: "18Kb" or "36Kb" 
       .FIRST_WORD_FALL_THROUGH (1)	// Sets the FIFO FWFT to 1 or 0 
       ) PCTX_FIFO (
		    .ALMOSTEMPTY(ae_ff),	// 1-bit output almost empty
		    .ALMOSTFULL(af_ff),	// 1-bit output almost full
		    .DO(dout_ff[15:0]),    // Output data, width defined by DATA_WIDTH parameter
		    .EMPTY(empty_ff),      // 1-bit output empty
		    .FULL(full_ff),        // 1-bit output full
		    .RDCOUNT(rc_ff),       // Output read count, width determined by FIFO depth
		    .RDERR(rderr_ff),      // 1-bit output read error
		    .WRCOUNT(wc_ff),       // Output write count, width determined by FIFO depth
		    .WRERR(wrerr_ff),      // 1-bit output write error
		    .DI(din_ff[15:0]),     // Input data, width defined by DATA_WIDTH parameter
		    .RDCLK(VME_CLK),   // 1-bit input read clock
		    .RDEN(RD_EN_FF),        // 1-bit input read enable
		    .RST(fifo_reset),      // 1-bit input reset
		    .WRCLK(usr_clk_wordwise),   // 1-bit input write clock
		    .WREN(wren_ff)         // 1-bit input write enable
		    );

   assign wren_ff = (rom_addr != 3'd0) || (rom_addr_p3 != 3'd0); 
   assign fifo_reset = FIFO_RST | RST;
   assign din_ff = mgt_tx_data_r;

   fifo_wrd_count #(.width(12)) pctx_fifo_wrd_count(.RST(fifo_reset),.CLK(usr_clk_wordwise),.WE(wren_ff),
						    .RE(RD_EN_FF),.FULL(full_ff),.COUNT(fifo_wrd_cnt_wire));

      always @*
	begin
	   FIFO_DATA_OUT <= dout_ff;
	   FIFO_WRD_CNT <= fifo_wrd_cnt_wire;
     end

   //////////////////////////////////////////////////////////////////////
       //                                                                  //
       // Dual rate GTX transmitter                                        //
       // Set TXPLLREFSELDY == 3'b000 for MGTREFCLKTX0 (DAQ_TX_125REFCLK)  //
       // Set TXPLLREFSELDY == 3'b001 for MGTREFCLKTX1 (DAQ_TX_160REFCLK)  //
       // Set TXRATE == 2'b10 for Divider = 2 (1.25Gbps line rate)         //
       // Set TXRATE == 2'b11 for Divider = 1 ( 3.2Gbps line rate)         //
       // Set word_clk_sel == 0 for 62.5MHz usr_clk_wordwise               //
       // Set word_clk_sel == 1 for 160 MHz usr_clk_wordwise               //
       //                                                                  //
       //////////////////////////////////////////////////////////////////////

   DAQ_GTX_dual_rate_custom #
     (
      .WRAPPER_SIM_GTXRESET_SPEEDUP   (SIM_SPEEDUP)      // Set this to 1 for simulation
      )
   daq_gtx_dual_rate_custom_i
     (
      //_____________________________________________________________________
      //_____________________________________________________________________
      //GTX0  (X0Y12)

      //----------------- Receive Ports - RX Data Path interface -----------------
      .GTX0_RXRESET_IN                (pma_reset_i),
      //----- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
      .GTX0_RXN_IN                    (DAQ_RX_N),
      .GTX0_RXP_IN                    (DAQ_RX_P),
      //---------------------- Receive Ports - RX PLL Ports ----------------------
      .GTX0_GREFCLKRX_IN              (1'b0),
      .GTX0_NORTHREFCLKRX_IN          (2'b00),
      .GTX0_PERFCLKRX_IN              (1'b0),
      .GTX0_RXPLLREFSELDY_IN          (3'b000),
      .GTX0_SOUTHREFCLKRX_IN          (2'b00),
      //-------------- Transmit Ports - 8b10b Encoder Control Ports --------------
      .GTX0_TXCHARISK_IN              (txcharisk_r),
      //----------------------- Transmit Ports - GTX Ports -----------------------
      .GTX0_GTXTEST_IN                (gtxtest),
      //---------------- Transmit Ports - TX Data Path interface -----------------
      .GTX0_TXDATA_IN                 (mgt_tx_data_r),
      .GTX0_TXOUTCLK_OUT              (txoutclk),
      .GTX0_TXRESET_IN                (txreset),
      .GTX0_TXUSRCLK2_IN              (usr_clk_wordwise),
      //-------------- Transmit Ports - TX Driver and OOB signaling --------------
      .GTX0_TXN_OUT                   (DAQ_TX_N),
      .GTX0_TXP_OUT                   (DAQ_TX_P),
      //--------- Transmit Ports - TX Elastic Buffer and Phase Alignment ---------
      .GTX0_TXBUFSTATUS_OUT           (txbufstatus_float),
      //--------------------- Transmit Ports - TX PLL Ports ----------------------
      .GTX0_GREFCLKTX_IN              (1'b0),
      .GTX0_GTXTXRESET_IN             (pma_reset_i),
      .GTX0_MGTREFCLKTX_IN            ({DAQ_TX_160REFCLK,DAQ_TX_125REFCLK}),
      .GTX0_NORTHREFCLKTX_IN          (2'b00),
      .GTX0_PERFCLKTX_IN              (1'b0),
      .GTX0_PLLTXRESET_IN             (pma_reset_i),
      .GTX0_SOUTHREFCLKTX_IN          (2'b00),
      .GTX0_TXPLLLKDET_OUT            (plllock_i),
      .GTX0_TXPLLREFSELDY_IN          (ref_clk_sel),
      .GTX0_TXRATE_IN                 (txrate_sel),
      .GTX0_TXRATEDONE_OUT            (txrate_done),
      .GTX0_TXRESETDONE_OUT           (txresetdone)
      );
   


   //////////////////////////////////////////////////////////////
       //                                                          //
       // ROM for Idles, Preamble, Data Fill, Carrier Extend,      //
       // and inter packet spacing.                                //
       //                                                          //
       //////////////////////////////////////////////////////////////

   always @(posedge usr_clk_wordwise or posedge rst_rom or posedge RST)
     begin
	if(rst_rom | RST)
	  rom_addr <= 3'd0;
	else
	  if(inc_rom)
	    rom_addr <= rom_addr + 1;
	  else
	    rom_addr <= rom_addr;
     end

   always @(posedge usr_clk_wordwise)
     begin: Frame_ROM
	case(rom_addr)
	  4'h0: cnst <= IDLE2;
	  4'h1: cnst <= SOP_PRE;
	  4'h2: cnst <= PREAMBLE;
	  4'h3: cnst <= PREAMBLE;
	  4'h4: cnst <= SOF_PRE;
	  4'h5: cnst <= 16'h0000;
	  4'h6: cnst <= End_of_Packet;
	  4'h7: cnst <= Carrier_Extend;
	  default: cnst <= IDLE2;
	endcase
     end
   // Matching ROM for CHAR_IS_K tags. 
   always @(posedge usr_clk_wordwise)
     begin: Frame_ROM_KWORD
	case(rom_addr)
	  4'h0: kcnst <= 2'b01;
	  4'h1: kcnst <= 2'b01;
	  4'h2: kcnst <= 2'b00;
	  4'h3: kcnst <= 2'b00;
	  4'h4: kcnst <= 2'b00;
	  4'h5: kcnst <= 2'b00;
	  4'h6: kcnst <= 2'b11;
	  4'h7: kcnst <= 2'b11;
	  default: kcnst <= 2'b10;
	endcase
     end 

   Frame_Proc_FSM
     Frame_Proc_FSM_i (
		       .CLR_CRC(clr_crc),
		       .CRC_CALC(crc_calc),
		       .CRC_VLD(crc_vld),
		       .INC_ROM(inc_rom),
		       .RST_ROM(rst_rom),
		       .TX_ACK(TX_ACK),
		       .FRM_STATE(frm_state),
		       .CLK(usr_clk_wordwise),
		       .ROM_ADDR(rom_addr),
		       .RST(arst),
		       .VALID(TXD_VLD) 
		       );

   // Pipeline signals for timing

   always @(posedge usr_clk_wordwise)
     begin
	txcharisk_r <= kcnst;
	crc_vld1 <= crc_vld;
	crc_vld2 <= crc_vld1;
	data1 <= TXD;
	crc_calc1 <= crc_calc;
	crc1 <= crc;
     end
   always @(posedge usr_clk_wordwise, posedge reset_i)
     begin
	if (reset_i)
	  mgt_tx_data_r <= cnst;
	else
	  if(crc_vld1 || crc_vld2)
	    mgt_tx_data_r <= crc1;
	  else if (crc_calc1)
	    mgt_tx_data_r <= data1;
	  else
	    mgt_tx_data_r <= cnst;
     end

   crc_gen crc_gen_i(
		     .crc_reg(crc_reg), 
		     .crc(crc),
		     .d(TXD),
		     .calc(crc_calc),
		     .init(clr_crc),
		     .d_valid(crc_dv),
		     .clk(usr_clk_wordwise),
		     .reset(reset_i)
		     );

endmodule
