
// Created by fizzim.pl version 4.41 on 2012:11:13 at 14:36:17 (www.fizzim.com)

module pkt_proc 
  #(
    parameter MAX_COUNT = 896
  )(
  output reg CKCRC,
  output reg CLR,
  output reg DROP,
  output reg ERR,
  output reg RXVALID,
  output wire [2:0] STATE,
  input CAR_XTEND,
  input CLK,
  input EOP,
  input ERR_PROP,
  input IDLE,
  input wire [11:0] LEN_COUNT,
  input NOK,
  input PRE,
  input RST,
  input SOF,
  input SOP 
);
  
  // state bits
  localparam 
  Wait_for_Pkt  = 3'b000, 
  Bad_Pkt       = 3'b001, 
  CkCRC         = 3'b010, 
  Payload       = 3'b011, 
  Preamble      = 3'b100, 
  Wait_for_Idle = 3'b101; 
  
  reg [2:0] state;
  assign STATE = state;
  reg [2:0] nextstate;
  
  // comb always block
  always @* begin
    nextstate = 3'bxxx; // default to x because default_state_is_x is set
    RXVALID = 0; // default
    case (state)
      Wait_for_Pkt : if      (ERR)         nextstate = Wait_for_Idle;
                     else if (SOF && SOP)  nextstate = Payload;
                     else if (SOP)         nextstate = Preamble;
                     else                  nextstate = Wait_for_Pkt;
      Bad_Pkt      :                       nextstate = Wait_for_Idle;
      CkCRC        :                       nextstate = Wait_for_Idle;
      Payload      : begin
                                           RXVALID = !EOP;
        if                   (ERR)         nextstate = Bad_Pkt;
        else if              (EOP)         nextstate = CkCRC;
        else                               nextstate = Payload;
      end
      Preamble     : if      (ERR)         nextstate = Bad_Pkt;
                     else if (SOF)         nextstate = Payload;
                     else                  nextstate = Preamble;
      Wait_for_Idle: if      (IDLE)        nextstate = Wait_for_Pkt;
                     else                  nextstate = Wait_for_Idle;
    endcase
  end
  
  // Assign reg'd outputs to state bits
  
  // sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST)
      state <= Wait_for_Pkt;
    else
      state <= nextstate;
  end
  
  // datapath sequential always block
  always @(posedge CLK or posedge RST) begin
    if (RST) begin
      CKCRC <= 0;
      CLR <= 0;
      DROP <= 0;
      ERR <= 0;
    end
    else begin
      CKCRC <= 0; // default
      CLR <= 0; // default
      DROP <= 0; // default
      ERR <= 0; // default
      case (nextstate)
        Wait_for_Pkt : begin
                              CLR <= 1;
                              ERR <= NOK || EOP || CAR_XTEND || ERR_PROP;
        end
        Bad_Pkt      :        DROP <= 1;
        CkCRC        :        CKCRC <= 1;
        Payload      :        ERR <= LEN_COUNT > MAX_COUNT;
        Preamble     :        ERR <= !PRE && !SOF;
      endcase
    end
  end
  
  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [103:0] statename;
  always @* begin
    case (state)
      Wait_for_Pkt : statename = "Wait_for_Pkt";
      Bad_Pkt      : statename = "Bad_Pkt";
      CkCRC        : statename = "CkCRC";
      Payload      : statename = "Payload";
      Preamble     : statename = "Preamble";
      Wait_for_Idle: statename = "Wait_for_Idle";
      default      : statename = "XXXXXXXXXXXXX";
    endcase
  end
  `endif

endmodule

