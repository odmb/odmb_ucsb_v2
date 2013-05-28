`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////
//                                                           //
// FIFO word counter with synchonous reset and               //
// parameterized width                                       //
//                                                           //
///////////////////////////////////////////////////////////////

module fifo_wrd_count #(
	parameter width = 16 // Default counter width in bits
)
(
	input RST,
	input CLK,
	input WE,
	input RE,
	input FULL,
	output reg [width-1:0] COUNT
);

reg re_1;
wire re_trle;
wire ce;
wire up;
wire mt;

initial
begin
   COUNT = 0;
end

assign mt = !(|COUNT);
assign re_trle = ~RE & re_1;
assign ce = (WE^re_trle) && ((WE && !FULL) || (re_trle && !mt));
assign up = WE && !re_trle;

always @ (posedge CLK)
begin
	re_1 <= RE;
end

always @ (posedge CLK)
begin
   if (RST)
      COUNT <= 0;
   else if (ce)
      if (up)
         COUNT <= COUNT + 1;
      else
         COUNT <= COUNT - 1;
   else
      COUNT <= COUNT;
end
endmodule
