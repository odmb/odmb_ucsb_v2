`timescale 1ns / 1ps
// Created by fizzim.pl version 4.41 on 2012:09:14 at 21:52:49 (www.fizzim.com)

module JTAG_TAP_ctrl (
  output reg CAP_DR,
  output reg RTIDLE,
  output reg SHFT_DR,
  output reg SHFT_IR,
  output reg TLRESET,
  output reg UPDT_DR,
  output reg UPDT_IR,
  input TCK,
  input TDI,
  input TMS,
  input TRST 
);
  
  // state bits
  parameter 
  Test_Logic_Reset = 4'b0000, 
  Capture_DR       = 4'b0001, 
  Capture_IR       = 4'b0010, 
  Exit1_DR         = 4'b0011, 
  Exit1_IR         = 4'b0100, 
  Exit2_DR         = 4'b0101, 
  Exit2_IR         = 4'b0110, 
  Pause_DR         = 4'b0111, 
  Pause_IR         = 4'b1000, 
  Run_Test_Idle    = 4'b1001, 
  Sel_DR_Scan      = 4'b1010, 
  Sel_IR_Scan      = 4'b1011, 
  Shift_DR         = 4'b1100, 
  Shift_IR         = 4'b1101, 
  Update_DR        = 4'b1110, 
  Update_IR        = 4'b1111; 
  
  reg [3:0] state;
  reg [3:0] nextstate;
  
  // comb always block
  always @* begin
    nextstate = 4'bxxxx; // default to x because default_state_is_x is set
    case (state)
      Test_Logic_Reset: if (TMS)  nextstate = Test_Logic_Reset;
                        else      nextstate = Run_Test_Idle;
      Capture_DR      : if (TMS)  nextstate = Exit1_DR;
                        else      nextstate = Shift_DR;
      Capture_IR      : if (TMS)  nextstate = Exit1_IR;
                        else      nextstate = Shift_IR;
      Exit1_DR        : if (TMS)  nextstate = Update_DR;
                        else      nextstate = Pause_DR;
      Exit1_IR        : if (TMS)  nextstate = Update_IR;
                        else      nextstate = Pause_IR;
      Exit2_DR        : if (TMS)  nextstate = Update_DR;
                        else      nextstate = Shift_DR;
      Exit2_IR        : if (TMS)  nextstate = Update_IR;
                        else      nextstate = Shift_IR;
      Pause_DR        : if (TMS)  nextstate = Exit2_DR;
                        else      nextstate = Pause_DR;
      Pause_IR        : if (TMS)  nextstate = Exit2_IR;
                        else      nextstate = Pause_IR;
      Run_Test_Idle   : if (TMS)  nextstate = Sel_DR_Scan;
                        else      nextstate = Run_Test_Idle;
      Sel_DR_Scan     : if (TMS)  nextstate = Sel_IR_Scan;
                        else      nextstate = Capture_DR;
      Sel_IR_Scan     : if (TMS)  nextstate = Test_Logic_Reset;
                        else      nextstate = Capture_IR;
      Shift_DR        : if (TMS)  nextstate = Exit1_DR;
                        else      nextstate = Shift_DR;
      Shift_IR        : if (TMS)  nextstate = Exit1_IR;
                        else      nextstate = Shift_IR;
      Update_DR       : if (TMS)  nextstate = Sel_DR_Scan;
                        else      nextstate = Run_Test_Idle;
      Update_IR       : if (TMS)  nextstate = Sel_DR_Scan;
                        else      nextstate = Run_Test_Idle;
    endcase
  end
  
  // Assign reg'd outputs to state bits
  
  // sequential always block
  always @(posedge TCK or posedge TRST) begin
    if (TRST)
      state <= Test_Logic_Reset;
    else
      state <= nextstate;
  end
  
  // datapath sequential always block
  always @(posedge TCK or posedge TRST) begin
    if (TRST) begin
      CAP_DR <= 0;
      RTIDLE <= 0;
      SHFT_DR <= 0;
      SHFT_IR <= 0;
      TLRESET <= 1;
      UPDT_DR <= 0;
      UPDT_IR <= 0;
    end
    else begin
      CAP_DR <= 0; // default
      RTIDLE <= 0; // default
      SHFT_DR <= 0; // default
      SHFT_IR <= 0; // default
      TLRESET <= 0; // default
      UPDT_DR <= 0; // default
      UPDT_IR <= 0; // default
      case (nextstate)
        Test_Logic_Reset: TLRESET <= 1;
        Capture_DR      : CAP_DR <= 1;
        Run_Test_Idle   : RTIDLE <= 1;
        Shift_DR        : SHFT_DR <= 1;
        Shift_IR        : SHFT_IR <= 1;
        Update_DR       : UPDT_DR <= 1;
        Update_IR       : UPDT_IR <= 1;
      endcase
    end
  end
  
  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [127:0] statename;
  always @* begin
    case (state)
      Test_Logic_Reset: statename = "Test_Logic_Reset";
      Capture_DR      : statename = "Capture_DR";
      Capture_IR      : statename = "Capture_IR";
      Exit1_DR        : statename = "Exit1_DR";
      Exit1_IR        : statename = "Exit1_IR";
      Exit2_DR        : statename = "Exit2_DR";
      Exit2_IR        : statename = "Exit2_IR";
      Pause_DR        : statename = "Pause_DR";
      Pause_IR        : statename = "Pause_IR";
      Run_Test_Idle   : statename = "Run_Test_Idle";
      Sel_DR_Scan     : statename = "Sel_DR_Scan";
      Sel_IR_Scan     : statename = "Sel_IR_Scan";
      Shift_DR        : statename = "Shift_DR";
      Shift_IR        : statename = "Shift_IR";
      Update_DR       : statename = "Update_DR";
      Update_IR       : statename = "Update_IR";
      default         : statename = "XXXXXXXXXXXXXXXX";
    endcase
  end
  `endif

endmodule

