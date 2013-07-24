`timescale 1ns / 1ps
module file_handler_ccb(clk, en, ccb_cmd_s, ccb_cmd, ccb_data_s, ccb_data, ccb_cal);

input wire clk;
input wire en;
output reg ccb_cmd_s;
output reg [5:0] ccb_cmd;
output reg ccb_data_s;
output reg [7:0] ccb_data;
output reg [2:0] ccb_cal;

reg [31:0] ts_cnt;
reg [31:0] ts_in;
reg ccb_cmd_s_in;
reg [5:0] ccb_cmd_in;
reg ccb_data_s_in;
reg [7:0] ccb_data_in;
reg [2:0] ccb_cal_in;

reg event_rd;

integer infile, r;

initial
  begin
    ts_cnt = 32'h00000000;
    ccb_cmd_s = 1'b1;
    ccb_cmd = 6'b000000;
    ccb_data_s = 1'b1;
    ccb_data = 8'b00000000;
    ccb_cal = 3'b111;
  end

always @(posedge clk) #1
    if (en)
        ts_cnt = ts_cnt + 1'b1;

always #1
  if (ts_cnt == ts_in) 
    event_rd = 1'b1;
  else
    event_rd = 1'b0;

always @(posedge clk) #1
  if (event_rd)
    begin
      ccb_cmd_s = ccb_cmd_s_in;
      ccb_cmd = ccb_cmd_in;
      ccb_data_s = ccb_data_s_in;
      ccb_data = ccb_data_in;
      ccb_cal = ccb_cal_in;
    end
  else
    begin
      ccb_cmd_s = 1'b1;
      ccb_cmd = 6'b000000;
      ccb_data_s = 1'b1;
      ccb_data = 8'b00000000;
      ccb_cal = 3'b111;
    end
  

initial #1
  begin
    infile=$fopen("commands\\test_ccb.txt","r");
    r = $fscanf(infile,"%h %b %b %b %b %b\n",ts_in,ccb_cmd_s_in,ccb_cmd_in,ccb_data_s_in,ccb_data_in,ccb_cal_in);
    while (!$feof(infile))
      begin
        @(posedge clk) #1
          if (event_rd)
            r = $fscanf(infile,"%h %b %b %b %b %b\n",ts_in,ccb_cmd_s_in,ccb_cmd_in,ccb_data_s_in,ccb_data_in,ccb_cal_in);
          end
    $fclose(infile);
//    $stop;
 end
endmodule
