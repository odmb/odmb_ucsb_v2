`timescale 1ns / 1ps

module clk_div_reset
(
	input  	CLK,
	input  	PLLLKDET,
	input  	TX_RATE,
	input  	INIT,
   output   GTXTEST_DONE,
	output 	GTXTEST_BIT1
);

   reg        plllkdet_sync;
   reg        plllkdet_r;
   reg [10:0] reset_dly_ctr;
   reg        reset_dly_done;
   reg [3:0]  testdone_f;
	wire zero_match;
	wire hbit_zero;
	wire rst_bit;
	
	assign zero_match = (TX_RATE == 1'b0) ? (reset_dly_ctr == 11'd0) : (reset_dly_ctr[6:0] == 7'h00);
	assign hbit_zero  = (TX_RATE == 1'b0) ? (reset_dly_ctr[10] == 1'b0) : (reset_dly_ctr[6] == 1'b0);
	assign rst_bit    = (TX_RATE == 1'b0) ? reset_dly_ctr[8] : reset_dly_ctr[5];

	always @(posedge CLK)
	begin
   	  plllkdet_r    	<=  PLLLKDET;
   	  plllkdet_sync 	<=  plllkdet_r;
   	end

	assign GTXTEST_BIT1  = reset_dly_done; 
   assign GTXTEST_DONE  = zero_match ? testdone_f[0] : 1'b0;

	always @(posedge CLK)
        begin
    	   if (!plllkdet_sync || INIT) 
              reset_dly_ctr 	<=  11'h7FF;
    	   else if (!zero_match)
              reset_dly_ctr 	<=  reset_dly_ctr - 1'b1;
        end

	always @(posedge CLK)
        begin
    	   if (!plllkdet_sync || INIT) 
              reset_dly_done 	<=  1'b0;
    	   else if (hbit_zero) 
              reset_dly_done 	<=  rst_bit;
        end

	always @(posedge CLK)
        begin
     	   if (!zero_match)
       	    testdone_f  <=  4'b1111;
         else
             testdone_f  <=  {1'b0, testdone_f[3:1]};
        end

endmodule

