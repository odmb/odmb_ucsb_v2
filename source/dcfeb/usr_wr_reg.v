`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Marissa Rodenburg
// 
// Create Date:    22:15:40 10/06/2010 
// Design Name:    JTAG
// Module Name:    usr_wr_reg 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
//   Serial in parallel out (sipo) shift register with parameterized width and default value.
//   Can be used in two modes: 1) as an individual shift register using FSEL, TDI, and TDO or
//                             2) daisy chained with other instances to form a long shift register
//                                with a common update (useing DSY_CHAIN, DSY_IN, and DSY_OUT)
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module user_wr_reg(TCK, DRCK, FSEL, SEL, TDI, DSY_IN, SHIFT, UPDATE, RST, DSY_CHAIN, PO, TDO, DSY_OUT);
  
  parameter width = 16;
  parameter def_value = 16'h00;

  input TCK;         // TCK for update register
  input DRCK;        // Data Reg Clock
  input FSEL;        // Function select
  input SEL;         // User mode active
  input TDI;         // Serial Test Data In
  input DSY_IN;      // Serial Daisy chained data in
  input SHIFT;       // Shift state
  input UPDATE;      // Update state
  input RST;         // Reset default state
  input DSY_CHAIN;   // Daisy chain mode
  output reg [width-1:0]  PO;         // Parallel output
  output TDO;        // Serial Test Data Out
  output DSY_OUT;   // Daisy chained serial data out
  
 
  reg[width-1:0] d;
  wire din,ce;
  
  assign TDO     = FSEL & d[0];
  assign DSY_OUT = DSY_CHAIN & d[0];
  assign din     = DSY_CHAIN ? DSY_IN : TDI;
  assign ce      = SHIFT & SEL & (FSEL | DSY_CHAIN);
  
  always @(posedge DRCK or posedge RST) begin // intermediate shift register
    if(RST)
	   d <= def_value;           // default
    else
	   if(ce)
	     d <= {din,d[width-1:1]}; // Shift right
		else
		  d <= d;                  // Hold
  end
  
  always @(posedge TCK or posedge RST) begin  // Parallel output register
    if(RST)
	   PO <= def_value;
	 else
	   if(UPDATE)
        PO <= d;
		else
		  PO <= PO;
  end

endmodule
