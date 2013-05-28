`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The Ohio State University
// Engineer: Marissa Rodenburg
// 
// Create Date:    12:30:24 10/11/2010 
// Design Name: 
// Module Name:    instr_dcd 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
//   Performs instruction register decoding (JTAG User1 register).
//
// Function  Description
// ---------------------------------------
//   0     | No Op 
//   1     | SCAM Reset (not needed in DCFEB)
//   2     | DCFEB status reg shift only
//   3     | DCFEB status reg capture and shift
//   4     | Program Comparator DAC
//   5     | Set Extra L1a Delay
//   6     | Read FIFO 1 -- ADC data (16 channels x 12 bits = 192 bits) wide X (6 chips x 8 sample)/event deep
//   7     | Set F5, F8, and F9 in one serial loop (daisy chained)
//   8     | Set Pre Block End (not needed in DCFEB)
//   9     | Set Comparator Mode and Timing bits
//  10     | Set Buckeye Mask for shifting (default 6'b111111)
//  11     | Shift data to/from Buckeye chips
//  12     | Set ADC configuration MASK
//  13     | Command to initialize ADC
//  14     | Shift data and write to ADC configuration memory
//  15     | Command to restart pipeline
//  16     | Set pipeline depth
//  17     | Perform a bit slip operation for odd deserializers
//  18     | Perform a bit slip operation for even deserializers
//  19     | Set Chip selection register.
//  20     | Set number of samples to readout.
//  21     | Write word to BPI interface FIFO.
//  22     | Read word from BPI readback FIFO.
//  23     | Read status word from BPI interface.
//  24     | Read BPI timer (32 bits).
//  25     | Reset BPI interface.
//  26     | Disable BPI processing.
//  27     | Enable BPI processing.
//  28     | Read SEU 021 error count.
//  29     | Read SEU 120 error count.
//  30     | Clear SEU error counters.
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module instr_dcd(
  input TCK,
  input DRCK,
  input SEL,
  input TDI,
  input UPDATE,
  input SHIFT,
  input RST,
  input CLR,            // clear current instruction
  output reg [32:0] F,
  output TDO);

  reg[7:0] d;
  wire rst_f;
  
  assign TDO = d[0];
  assign rst_f = RST | CLR;
  
  always @(posedge DRCK or posedge RST) begin
    if (RST)
	   d <= 8'h00;
	 else
      if (SEL & SHIFT)
        d <= {TDI,d[7:1]};
		else
		  d <= d;
  end
  
  always @(posedge TCK or posedge rst_f) begin
    if(rst_f)
	   F <= 32'h00000000;
	 else
	   if(UPDATE)
		  case (d)
		    8'h00:   F <= 32'h00000001;
		    8'h01:   F <= 32'h00000002;
		    8'h02:   F <= 32'h00000004;
		    8'h03:   F <= 32'h00000008;
		    8'h04:   F <= 32'h00000010;
		    8'h05:   F <= 32'h00000020;
		    8'h06:   F <= 32'h00000040;
		    8'h07:   F <= 32'h00000080;
		    8'h08:   F <= 32'h00000100;
		    8'h09:   F <= 32'h00000200;
		    8'h0A:   F <= 32'h00000400;
		    8'h0B:   F <= 32'h00000800;
		    8'h0C:   F <= 32'h00001000;
		    8'h0D:   F <= 32'h00002000;
		    8'h0E:   F <= 32'h00004000;
		    8'h0F:   F <= 32'h00008000;
		    8'h10:   F <= 32'h00010000;
		    8'h11:   F <= 32'h00020000;
		    8'h12:   F <= 32'h00040000;
		    8'h13:   F <= 32'h00080000;
		    8'h14:   F <= 32'h00100000;
		    8'h15:   F <= 32'h00200000;
		    8'h16:   F <= 32'h00400000;
		    8'h17:   F <= 32'h00800000;
		    8'h18:   F <= 32'h01000000;
		    8'h19:   F <= 32'h02000000;
		    8'h1A:   F <= 32'h04000000;
		    8'h1B:   F <= 32'h08000000;
		    8'h1C:   F <= 32'h10000000;
		    8'h1D:   F <= 32'h20000000;
		    8'h1E:   F <= 32'h40000000;
		    8'h1F:   F <= 32'h80000000;
		    default: F <= 32'h00000000;
		  endcase
		else
		  F <= F;
  end
  
endmodule
