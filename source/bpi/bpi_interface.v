`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:10:16 03/09/2011 
// Design Name: 
// Module Name:    bpi_interface 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module bpi_interface
  (
   input 	     CLK, // 40 MHz clock
   input 	     RST,
   input [22:0]      ADDR, //Bank/Array Address 
   input [15:0]      CMD_DATA_OUT, //Command or Data being written to FLASH device
   input [1:0] 	     OP, //Operation: 00-standby, 01-write, 10-read, 11-not allowed(standby)
   input 	     EXECUTE,
   output [15:0]     DATA_IN, //Data read from FLASH device
   output 	     LOAD_DATA, //Clock enable signal for capturing Data read from FLASH device
   output 	     BUSY, //Operation in progress signal (not ready)
   // signals for Dual purpose data lines
   input 	     BPI_ACTIVE, // set to 1 when data lines are for BPI communications.
   input [15:0]      DUAL_DATA, // Data provided for non BPI communications
   // external connections cooresponding to I/O pins
   output reg [22:0] bpi_ad_out_r,
   output [15:0]     data_out_i,
   output [5:0]      PROM_CONTROL,
   inout [22:0]      BPI_AD,
   inout [15:0]      CFG_DAT,
   output 	     RS0,
   output 	     RS1,
   output 	     FCS_B,
   output 	     FOE_B,
   output 	     FWE_B,
   output 	     FLATCH_B
   );

   wire [22:0] 	 bpi_ad_in;
   wire [22:0] 	 bpi_dir;
   wire [15:0] 	 data_dir;
   reg [15:0] 	 data_out_r;
   wire 	 rs0_out;
   wire 	 rs1_out;
   wire 	 fcs,foe,fwe,flatch_addr;
   reg 		 read;
   reg 		 write;
   wire 	 capture;
   wire [15:0] 	 leds_out;
   wire 	 clk100k;
   wire 	 q15;
   


   IOBUF #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) IOBUF_BPI_AD[22:0] (.O(bpi_ad_in),.IO(BPI_AD),.I(bpi_ad_out_r),.T(bpi_dir));
   IOBUF #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) IOBUF_CFG_DAT[15:0] (.O(DATA_IN),.IO(CFG_DAT),.I(data_out_i),.T(data_dir));
   OBUFT  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_RS0 (.O(RS0),.I(rs0_out),.T(1'b1)); //always tri-state for after programming finishes
   OBUFT  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_RS1 (.O(RS1),.I(rs1_out),.T(1'b1)); //always tri-state for after programming finishes
   OBUF  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_FCS_B (.O(FCS_B),.I(~fcs));
   OBUF  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_FOE_B (.O(FOE_B),.I(~foe));
   OBUF  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_FWE_B (.O(FWE_B),.I(~fwe));
   OBUF  #(.DRIVE(12),.IOSTANDARD("DEFAULT"),.SLEW("SLOW")) OBUF_FLATCH (.O(FLATCH_B),.I(~flatch_addr));

   assign PROM_CONTROL = {rs0_out, rs1_out, ~fcs, ~foe, ~fwe, ~flatch_addr};
   assign bpi_dir    = 23'h000000;  // always output the address lines
   assign data_dir   = {16{foe}};   //Tristat fpga data outputs when the flash is output enable (foe)
   assign rs0_out    = 1'b0;
   assign rs1_out    = 1'b0;
   assign data_out_i = (fcs | BPI_ACTIVE) ? data_out_r : DUAL_DATA;

   always @(posedge CLK)
     begin
	if(capture) begin
	   bpi_ad_out_r   <= ADDR[22:0];
	   data_out_r     <= CMD_DATA_OUT;
	   write          <= OP[0];
	   read           <= OP[1];
	end
     end
   
   BPI_intrf_FSM 
     BPI_intrf_FSM1(
		    .BUSY(BUSY),
		    .CAP(capture),
		    .E(fcs),
		    .G(foe),
		    .L(flatch_addr),
		    .LOAD(LOAD_DATA),
		    .W(fwe),
		    .CLK(CLK),
		    .EXECUTE(EXECUTE),
		    .READ(read),
		    .RST(RST),
		    .WRITE(write)
		    );

endmodule
