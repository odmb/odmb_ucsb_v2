`timescale 1ns / 1ps
module file_handler_event(clk, en, l1a, alct_dav, tmb_dav, lct);

input wire clk;
input wire en;
output reg l1a;
output reg [7:0] lct;
output reg alct_dav;
output reg tmb_dav;

reg [31:0] ts_cnt;
reg [31:0] ts_in;
reg l1a_in;
reg alct_dav_in;
reg tmb_dav_in;
reg [7:0] lct_in;

reg event_rd;

integer infile, r;

initial
  begin
    ts_cnt = 32'h00000000;
    l1a = 1'b0;
    lct = 8'b00000000;
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
      l1a = l1a_in;
      alct_dav = alct_dav_in;
      tmb_dav = tmb_dav_in;
      lct = lct_in;
    end
  else
    begin
      l1a = 1'b0;
      alct_dav = 1'b0;
      tmb_dav = 1'b0;
      lct = 8'b00000000;
    end
  

initial #1
  begin
    infile=$fopen("commands\\test_lct_l1a.txt","r");
    r = $fscanf(infile,"%h %b %b %b %b\n",ts_in,l1a_in,alct_dav_in,tmb_dav_in,lct_in);
    while (!$feof(infile))
      begin
        @(posedge clk) #1
          if (event_rd)
            r = $fscanf(infile,"%h %b %b %b %b\n",ts_in,l1a_in,alct_dav_in,tmb_dav_in,lct_in);
          end
    $fclose(infile);
//    $stop;
 end
endmodule
