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
module tdo_mux(
  input TDO_0C,
  input TDO_17,
  input [32:0] FSEL,
  output reg TDO);

  
  always @(TDO_0C or TDO_17 or FSEL)
		 case (FSEL)
		    33'h000001000: TDO <= TDO_0C;
		    33'h000800000: TDO <= TDO_17;
		    default: TDO <= 1'b0;
		 endcase
  
  
endmodule
