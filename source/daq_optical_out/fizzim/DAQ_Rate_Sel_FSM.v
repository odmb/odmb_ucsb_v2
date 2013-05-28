`timescale 1ns / 1ps
// Created by fizzim.pl version 4.41 on 2012:11:12 at 15:14:04 (www.fizzim.com)

module DAQ_Rate_Sel_FSM (
  output reg CDV_INIT,
  output reg [2:0] CLK_SEL,
  output reg CLR_CNT,
  output reg INC_CNT,
  output reg PCSRST,
  output reg RATE_1_25,
  output reg RATE_3_2,
  output reg [1:0] RATE_SEL,
  output reg WRDCLKSEL,
  output wire [3:0] DQRT_STATE,
  input CDV_DONE,
  input CLK,
  input wire [3:0] CNT,
  input DAQ_RATE,
  input RST,
  input TXRATEDONE 
);
  
  // state bits
  parameter 
  ST_3_2_GBPS  = 4'b0000, 
  RefClk125    = 4'b0001, 
  RefClk160    = 4'b0010, 
  RstClkDiv125 = 4'b0011, 
  RstClkDiv160 = 4'b0100, 
  RstPCS125    = 4'b0101, 
  RstPCS160    = 4'b0110, 
  ST_1_25_GBPS = 4'b0111, 
  WrdClk160    = 4'b1000, 
  WrdClk62_5   = 4'b1001; 
  
  reg [3:0] state;
  assign DQRT_STATE = state;
  reg [3:0] nextstate;
  
  // comb always block
  always @* begin
    nextstate = 4'bxxxx; // default to x because default_state_is_x is set
    case (state)
      ST_3_2_GBPS : if (!DAQ_RATE)    nextstate = RefClk125;
                    else              nextstate = ST_3_2_GBPS;
      RefClk125   : if (TXRATEDONE)   nextstate = WrdClk62_5;
                    else              nextstate = RefClk125;
      RefClk160   : if (TXRATEDONE)   nextstate = WrdClk160;
                    else              nextstate = RefClk160;
      RstClkDiv125: if (CDV_DONE)     nextstate = RstPCS125;
                    else              nextstate = RstClkDiv125;
      RstClkDiv160: if (CDV_DONE)     nextstate = RstPCS160;
                    else              nextstate = RstClkDiv160;
      RstPCS125   : if (CNT == 5'd4)  nextstate = ST_1_25_GBPS;
                    else              nextstate = RstPCS125;
      RstPCS160   : if (CNT == 5'd4)  nextstate = ST_3_2_GBPS;
                    else              nextstate = RstPCS160;
      ST_1_25_GBPS: if (DAQ_RATE)     nextstate = RefClk160;
                    else              nextstate = ST_1_25_GBPS;
      WrdClk160   : if (CNT == 5'd4)  nextstate = RstClkDiv160;
                    else              nextstate = WrdClk160;
      WrdClk62_5  : if (CNT == 5'd4)  nextstate = RstClkDiv125;
                    else              nextstate = WrdClk62_5;
    endcase
  end
  
  // Assign reg'd outputs to state bits
  
  // sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST)
      state <= ST_1_25_GBPS;
//      state <= ST_3_2_GBPS;
    else
      state <= nextstate;
  end
  
  // datapath sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      CDV_INIT <= 1;
      CLK_SEL[2:0] <= 3'b001;
      CLR_CNT <= 0;
      INC_CNT <= 0;
      PCSRST <= 0;
      RATE_1_25 <= 0;
      RATE_3_2 <= 0;
      RATE_SEL[1:0] <= 2'b11;
      WRDCLKSEL <= 1;
    end
    else begin
      CDV_INIT <= 0; // default
      CLK_SEL[2:0] <= 3'b001; // default
      CLR_CNT <= 0; // default
      INC_CNT <= 0; // default
      PCSRST <= 0; // default
      RATE_1_25 <= 0; // default
      RATE_3_2 <= 0; // default
      RATE_SEL[1:0] <= 2'b11; // default
      WRDCLKSEL <= 1; // default
      case (nextstate)
        ST_3_2_GBPS :        RATE_3_2 <= 1;
        RefClk125   : begin
                             CDV_INIT <= 1;
                             CLK_SEL[2:0] <= 3'b000;
                             CLR_CNT <= 1;
                             RATE_SEL[1:0] <= 2'b10;
        end
        RefClk160   : begin
                             CDV_INIT <= 1;
                             CLR_CNT <= 1;
                             WRDCLKSEL <= 0;
        end
        RstClkDiv125: begin
                             CLK_SEL[2:0] <= 3'b000;
                             CLR_CNT <= 1;
                             RATE_SEL[1:0] <= 2'b10;
                             WRDCLKSEL <= 0;
        end
        RstClkDiv160:        CLR_CNT <= 1;
        RstPCS125   : begin
                             CLK_SEL[2:0] <= 3'b000;
                             INC_CNT <= 1;
                             PCSRST <= 1;
                             RATE_SEL[1:0] <= 2'b10;
                             WRDCLKSEL <= 0;
        end
        RstPCS160   : begin
                             INC_CNT <= 1;
                             PCSRST <= 1;
        end
        ST_1_25_GBPS: begin
                             CLK_SEL[2:0] <= 3'b000;
                             RATE_1_25 <= 1;
                             RATE_SEL[1:0] <= 2'b10;
                             WRDCLKSEL <= 0;
        end
        WrdClk160   : begin
                             CDV_INIT <= 1;
                             INC_CNT <= 1;
        end
        WrdClk62_5  : begin
                             CDV_INIT <= 1;
                             CLK_SEL[2:0] <= 3'b000;
                             INC_CNT <= 1;
                             RATE_SEL[1:0] <= 2'b10;
                             WRDCLKSEL <= 0;
        end
      endcase
    end
  end
  
  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [95:0] statename;
  always @* begin
    case (state)
      ST_3_2_GBPS : statename = "ST_3_2_GBPS";
      RefClk125   : statename = "RefClk125";
      RefClk160   : statename = "RefClk160";
      RstClkDiv125: statename = "RstClkDiv125";
      RstClkDiv160: statename = "RstClkDiv160";
      RstPCS125   : statename = "RstPCS125";
      RstPCS160   : statename = "RstPCS160";
      ST_1_25_GBPS: statename = "ST_1_25_GBPS";
      WrdClk160   : statename = "WrdClk160";
      WrdClk62_5  : statename = "WrdClk62_5";
      default     : statename = "XXXXXXXXXXXX";
    endcase
  end
  `endif

endmodule

