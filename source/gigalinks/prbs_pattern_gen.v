
///////////////////////////////////////////////////////////////////////////////
//
//    File Name:  PatternLib.v
//      Version:  2.2  
//         Date:  05/14/03
//        Model:  Library of test bit-patterns.
//
//      Company:  Xilinx, Inc.
//  Contributor:  Mike Matera
//
//   Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
//                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
//                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
//                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
//                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
//                APPLICATION OR STANDARD, XILINX IS MAKING NO
//                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
//                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
//                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
//                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
//                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
//                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
//                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
//                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
//                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
//                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//                PURPOSE.
//
//                (c) Copyright 2003 Xilinx, Inc.
//                All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////
//
// Summary:
//
//   This file contains many modlues.  It is broken up into
// three sections:
//
// I. Polynomial Implementation Section.
//      This section contains modules that implement specific
//      PRBS polynomials and any thing else that must be done,
//      such as data inversion.
//
// II. PRBS Generator Section.
//      This section contains generalized modules for creating
//      n-bit PRBS patterns.  Each module in this section may
//      implement any polynomial (maximal length or not).
//
// III. Intermediate Expression Section.
//      The intermediate expression (IX) modules are used to
//      generate the cascaded logic required to generate 20-bit
//      remainders every clock cycle.
//
// Constant Summary:
//
// NOTE: As of version 1.4 file allows the option of compiling
//       Type1 or Type2 LFSRs using compile time flags.  The
//       following flags are MUTUALY EXCLUSIVE (define only one).
//
// WITH_TYPE1
//   Defined to instantiate Type1 LFSRs.
//
// WITH_TYPE2
//   Defined to instantiate Type1 LFSRs.
//
// PatternLib.v,v 1.9 2003/03/24 23:22:24 matera
//----------------------------------------------------------------
`ifdef PATTERNLIB `else 
 `define PATTERNLIB

`define WITH_TYPE1

`timescale               100ps/10ps 

//----------------------------------------------------------------
//
// I. Polynomial Implementation Section.
//   A. Contents
//     1. PRBS_32BIT   : Non Standard 32-bit PRBS.
//     2. ITU_T_O150_51: ITU-T Recomendation O.150 section 5.1.
//     3. ITU_T_O150_52: ITU-T Recomendation O.150 section 5.2.
//     4. ITU_T_O150_53: ITU-T Recomendation O.150 section 5.3.
//     5. ITU_T_O150_54: ITU-T Recomendation O.150 section 5.4.
//     6. ITU_T_O150_55: ITU-T Recomendation O.150 section 5.5.
//     7. ITU_T_O150_56: ITU-T Recomendation O.150 section 5.6.
//     8. ITU_T_O150_57: ITU-T Recomendation O.150 section 5.7.
//     9. ITU_T_O150_58: ITU-T Recomendation O.150 section 5.8.
//    10. PRBS_7BIT    : Non Standard 7-bit PRBS.
//
//   B. Port Summary.
//
//     data_out[19:00] (synchronous: clock_in)
//        Pattern data.
//
//     advance_in (synchronous: clock_in)
//        Enable pin for the pattern generators.  data_out will
//        update every cycle this pin is held high.
//
//     reset_in (synchronous: clock_in)
//        Synchronous reset. 
//
//     clock_in (clock: buffered)
//        Pattern clock.
//
//----------------------------------------------------------------

module PRBS_32BIT (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // 32-bit Pattern (not specd)
   //   :
   //   : Shifter Stages  :  32
   //   : Length          :  2^31 - 1 = 4G bits
   //   : Longest Sequence:  32 (not-inverted)
   //   : Poly            :  x^32 + x^31 + x^30 + x^10
   //   :
   //   : 0000 0000 0100 0000 0000 0000 0000 0111
   //   :    0    0    4    0    0    0    0    7
   //-------------------------------------------------------------------------
   parameter      POLY       = 32'h00400007;
   parameter      MAX_LENGTH = 1'b0;
   
   PRBSGen32 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(data_out), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );
   
endmodule

module PRBS_ITU_T_O150_58 (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // ITU-T Recommendation O.150 Section 5.8
   //   :
   //   : Shifter Stages  :  31
   //   : Length          :  2^31 - 1 = 2,147,483,647 bits
   //   : Longest Sequence:  31 (inverted)
   //   : Poly            :  x^31 + x^28
   //   :
   //   : 000 0000 0000 0000 0000 0000 0000 1001
   //   :   0    0    0    0    0    0    0    9
   //-------------------------------------------------------------------------
   parameter      POLY       = 31'h00000009;
   parameter      MAX_LENGTH = 1'b0;
   
   wire [19:00]   data_inverted;
   assign data_out = ~ data_inverted;

   PRBSGen31 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(data_inverted), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );
   
endmodule

module PRBS_ITU_T_O150_57 (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // ITU-T Recommendation O.150 Section 5.7
   //   :
   //   : Shifter Stages  :  29
   //   : Length          :  2^29 - 1 = 536,870,911 bits
   //   : Longest Sequence:  29 (inverted)
   //   : Poly            :  x^29 + x^27
   //   :
   //   : 0 0000 0000 0000 0000 0000 0000 0101
   //   : 0    0    0    0    0    0    0    5
   //-------------------------------------------------------------------------
   parameter      POLY       = 29'h00000005;
   parameter      MAX_LENGTH = 1'b0;
   
   wire [19:00]   data_inverted;
   assign data_out = ~ data_inverted;

   PRBSGen29 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(data_inverted), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );
   
endmodule

module PRBS_ITU_T_O150_56 (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // ITU-T Recommendation O.150 Section 5.6
   //   :
   //   : Shifter Stages  :  23
   //   : Length          :  2^23 - 1 = 8,388,607 bits
   //   : Longest Sequence:  23 (inverted)
   //   : Poly            :  x^23 + x^18
   //   :
   //   : 000 0000 0000 0000 0010 0001
   //   :   0    0    0    0    2    1
   //-------------------------------------------------------------------------
   parameter      POLY       = 23'h000021;
   parameter      MAX_LENGTH = 1'b0;
   
   wire [19:00]   data_inverted;
   assign data_out = ~ data_inverted;

   PRBSGen23 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(data_inverted), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );

endmodule

module PRBS_ITU_T_O150_55 (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // ITU-T Recommendation O.150 Section 5.5
   //   :
   //   : Shifter Stages  :  20
   //   : Length          :  2^20 - 1 = 1,048,575 bits
   //   : Longest Sequence:  14 (special sequence)
   //   : Poly            :  x^20 + x^17
   //   : NOTE            :  This pattern uses zeros suppression.
   //   :
   //   : 0000 0000 0000 0000 1001
   //   :    0    0    0    0    9
   //-------------------------------------------------------------------------
   parameter      POLY       = 20'h00009;
   parameter      MAX_LENGTH = 1'b0;

   //
   // Zeros suppression:
   //
   reg [19:00]    prbs_data_out__pipe1, data_out; 
   wire [19:00]   prbs_data_out__pipe0;

   wire [32:00]   history = {prbs_data_out__pipe1[18:00], prbs_data_out__pipe0[19:06]};

   always @ (posedge clock_in) begin
      if (reset_in) begin
         prbs_data_out__pipe1 <= 20'b1;
      end else if (advance_in) begin
         prbs_data_out__pipe1 <= prbs_data_out__pipe0;
      end
   end

   always @ (posedge clock_in) begin
      if (reset_in) begin
         data_out <= 20'b1;
      end else if (advance_in) begin
         data_out[19] <= prbs_data_out__pipe1[19] | ~(| history[32:19]);
         data_out[18] <= prbs_data_out__pipe1[18] | ~(| history[31:18]);
         data_out[17] <= prbs_data_out__pipe1[17] | ~(| history[30:17]);
         data_out[16] <= prbs_data_out__pipe1[16] | ~(| history[29:16]);
         data_out[15] <= prbs_data_out__pipe1[15] | ~(| history[28:15]);
         data_out[14] <= prbs_data_out__pipe1[14] | ~(| history[27:14]);
         data_out[13] <= prbs_data_out__pipe1[13] | ~(| history[26:13]);
         data_out[12] <= prbs_data_out__pipe1[12] | ~(| history[25:12]);
         data_out[11] <= prbs_data_out__pipe1[11] | ~(| history[24:11]);
         data_out[10] <= prbs_data_out__pipe1[10] | ~(| history[23:10]);
         data_out[09] <= prbs_data_out__pipe1[09] | ~(| history[22:09]);
         data_out[08] <= prbs_data_out__pipe1[08] | ~(| history[21:08]);
         data_out[07] <= prbs_data_out__pipe1[07] | ~(| history[20:07]);
         data_out[06] <= prbs_data_out__pipe1[06] | ~(| history[19:06]);
         data_out[05] <= prbs_data_out__pipe1[05] | ~(| history[18:05]);
         data_out[04] <= prbs_data_out__pipe1[04] | ~(| history[17:04]);
         data_out[03] <= prbs_data_out__pipe1[03] | ~(| history[16:03]);
         data_out[02] <= prbs_data_out__pipe1[02] | ~(| history[15:02]);
         data_out[01] <= prbs_data_out__pipe1[01] | ~(| history[14:01]);
         data_out[00] <= prbs_data_out__pipe1[00] | ~(| history[13:00]);
      end
   end
   
   PRBSGen20 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(prbs_data_out__pipe0), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );

endmodule

module PRBS_ITU_T_O150_54 (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // ITU-T Recommendation O.150 Section 5.4
   //   :
   //   : Shifter Stages  :  20
   //   : Length          :  2^20 - 1 = 1,048,575 bits
   //   : Longest Sequence:  19 (non-inverted)
   //   : Poly            :  x^20 + x^3
   //   :
   //   : 0010 0000 0000 0000 0001
   //   :    2    0    0    0    1
   //-------------------------------------------------------------------------
   parameter      POLY       = 20'h20001;
   parameter      MAX_LENGTH = 1'b0;
   
   PRBSGen20 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(data_out), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );

endmodule

module PRBS_ITU_T_O150_53 (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // ITU-T Recommendation O.150 Section 5.3
   //   :
   //   : Shifter Stages  :  15
   //   : Length          :  2^15 - 1 = 32,767 bits
   //   : Longest Sequence:  15 (inverted)
   //   : Poly            :  x^15 + x^14
   //   :
   //   : 000 0000 0000 0011
   //   :   0    0    0    3
   //-------------------------------------------------------------------------
   parameter      POLY       = 15'h003;
   parameter      MAX_LENGTH = 1'b0;
   
   wire [19:00]   data_inverted;
   assign data_out = ~ data_inverted;

   PRBSGen15 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(data_inverted), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );

endmodule

module PRBS_ITU_T_O150_52 (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // ITU-T Recommendation O.150 Section 5.2
   //   :
   //   : Shifter Stages  :  11
   //   : Length          :  2^11 - 1 = 2047 bits
   //   : Longest Sequence:  10 (non-inverted)
   //   : Poly            :  x^11 + x^9
   //   :
   //   : 000 0000 0101
   //   :   0    0    5
   //-------------------------------------------------------------------------
   parameter      POLY       = 11'h005;
   parameter      MAX_LENGTH = 1'b0;
   
   PRBSGen11 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(data_out), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );

endmodule

module PRBS_ITU_T_O150_51 (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // ITU-T Recommendation O.150 Section 5.1
   //   :
   //   : Shifter Stages  :  9
   //   : Length          :  2^9 - 1 = 511 bits
   //   : Longest Sequence:  8 (non-inverted)
   //   : Poly            :  x^9 + x^5
   //   :
   //   : 0 0001 0001
   //   : 0    1    1
   //-------------------------------------------------------------------------
   parameter      POLY       = 09'h011;
   parameter      MAX_LENGTH = 1'b0;
   
   PRBSGen09 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(data_out), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );

endmodule

module PRBS_7BIT (data_out, advance_in, reset_in, clock_in);
   output [19:00] data_out;
   input          advance_in, reset_in, clock_in;
   
   //-------------------------------------------------------------------------
   // 7-bit Low Stress Pattern (not spec'd)
   //   :
   //   : Shifter Stages  :  7
   //   : Length          :  2^7 - 1 = 127 bits
   //   : Longest Sequence:  5 (non-inverted)
   //   : Poly            :  x^7 + x^6
   //   :
   //   : 000 0011
   //   :   0    3
   //-------------------------------------------------------------------------
   parameter      POLY       = 07'h03;
   parameter      MAX_LENGTH = 1'b0;
   
   PRBSGen07 prbs 
      (
       .poly_in(POLY), .length_in(MAX_LENGTH), 
       .data_out(data_out), 
       .advance_in(advance_in), 
       .reset_in(reset_in),
       .clock_in(clock_in)
       );

endmodule

//----------------------------------------------------------------
//
// II. PRBS Generator Section.
//   A. Contents:
//     1. PRBSGen32: 32-bit implementation
//     2. PRBSGen31: 31-bit implementation
//     3. PRBSGen29: 29-bit implementation
//     4. PRBSGen23: 23-bit implementation
//     5. PRBSGen20: 20-bit implementation
//     6. PRBSGen15: 15-bit implementation
//     7. PRBSGen11: 11-bit implementation
//     8. PRBSGen09:  9-bit implementation
//     9. PRBSGen07:  7-bit implementation
//
//   B. Port Summary.
//
//     data_out[19:00] (synchronous: clock_in)
//        Pattern data.
//
//     advance_in (synchronous: clock_in)
//        Enable pin for the pattern generators.  data_out will
//        update every cycle this pin is held high.
//
//     poly_in[XX:00] (synchronous: clock_in)
//        Number representing the LFSR's polynomial.
//
//     length_in (synchronous: clock_in)
//        High if the LFSR should be maximal length.
//
//     reset_in (synchronous: clock_in)
//        Synchronous reset. 
//
//     clock_in (clock: buffered)
//        Pattern clock.
//
//----------------------------------------------------------------
module PRBSGen32(data_out, advance_in, reset_in,
                 poly_in, length_in, clock_in
                 );

   output [19:00] data_out;
   input [31:00]  poly_in;
   input          length_in, advance_in, reset_in, clock_in;
   
   reg [31:00]    PRBS;
   reg [19:00]    data_out;
   
   wire [31:00]   ix00, ix01, ix02, ix03, ix04, ix05, ix06, ix07, ix08, ix09, ix10, ix11, ix12, ix13, ix14, ix15, ix16, ix17, ix18, ix19;

   IX32 intermediate_expression00(ix00, PRBS, poly_in, length_in);
   IX32 intermediate_expression01(ix01, ix00, poly_in, length_in);
   IX32 intermediate_expression02(ix02, ix01, poly_in, length_in);
   IX32 intermediate_expression03(ix03, ix02, poly_in, length_in);
   IX32 intermediate_expression04(ix04, ix03, poly_in, length_in);
   IX32 intermediate_expression05(ix05, ix04, poly_in, length_in);
   IX32 intermediate_expression06(ix06, ix05, poly_in, length_in);
   IX32 intermediate_expression07(ix07, ix06, poly_in, length_in);
   IX32 intermediate_expression08(ix08, ix07, poly_in, length_in);
   IX32 intermediate_expression09(ix09, ix08, poly_in, length_in);
   IX32 intermediate_expression10(ix10, ix09, poly_in, length_in);
   IX32 intermediate_expression11(ix11, ix10, poly_in, length_in);
   IX32 intermediate_expression12(ix12, ix11, poly_in, length_in);
   IX32 intermediate_expression13(ix13, ix12, poly_in, length_in);
   IX32 intermediate_expression14(ix14, ix13, poly_in, length_in);
   IX32 intermediate_expression15(ix15, ix14, poly_in, length_in);
   IX32 intermediate_expression16(ix16, ix15, poly_in, length_in);
   IX32 intermediate_expression17(ix17, ix16, poly_in, length_in);
   IX32 intermediate_expression18(ix18, ix17, poly_in, length_in);
   IX32 intermediate_expression19(ix19, ix18, poly_in, length_in);

   always @ (posedge clock_in) begin
      if (reset_in) begin 
         PRBS <= 32'b11111111111111111111111111111111;
         data_out <= 1;
      end else if (advance_in) begin
         PRBS <= ix19;
         data_out <= {ix00[31], ix01[31], ix02[31], ix03[31], ix04[31], ix05[31], ix06[31], ix07[31], ix08[31], ix09[31], ix10[31], ix11[31], ix12[31], ix13[31], ix14[31], ix15[31], ix16[31], ix17[31], ix18[31], ix19[31]};
      end
   end
endmodule

module PRBSGen31(data_out, advance_in, reset_in,
                 poly_in, length_in, clock_in
                 );

   output [19:00] data_out;
   input [30:00]  poly_in;
   input          length_in, advance_in, reset_in, clock_in;
   
   reg [30:00]    PRBS;
   reg [19:00]    data_out;
   
   wire [30:00]   ix00, ix01, ix02, ix03, ix04, ix05, ix06, ix07, ix08, ix09, ix10, ix11, ix12, ix13, ix14, ix15, ix16, ix17, ix18, ix19;

   IX31 intermediate_expression00(ix00, PRBS, poly_in, length_in);
   IX31 intermediate_expression01(ix01, ix00, poly_in, length_in);
   IX31 intermediate_expression02(ix02, ix01, poly_in, length_in);
   IX31 intermediate_expression03(ix03, ix02, poly_in, length_in);
   IX31 intermediate_expression04(ix04, ix03, poly_in, length_in);
   IX31 intermediate_expression05(ix05, ix04, poly_in, length_in);
   IX31 intermediate_expression06(ix06, ix05, poly_in, length_in);
   IX31 intermediate_expression07(ix07, ix06, poly_in, length_in);
   IX31 intermediate_expression08(ix08, ix07, poly_in, length_in);
   IX31 intermediate_expression09(ix09, ix08, poly_in, length_in);
   IX31 intermediate_expression10(ix10, ix09, poly_in, length_in);
   IX31 intermediate_expression11(ix11, ix10, poly_in, length_in);
   IX31 intermediate_expression12(ix12, ix11, poly_in, length_in);
   IX31 intermediate_expression13(ix13, ix12, poly_in, length_in);
   IX31 intermediate_expression14(ix14, ix13, poly_in, length_in);
   IX31 intermediate_expression15(ix15, ix14, poly_in, length_in);
   IX31 intermediate_expression16(ix16, ix15, poly_in, length_in);
   IX31 intermediate_expression17(ix17, ix16, poly_in, length_in);
   IX31 intermediate_expression18(ix18, ix17, poly_in, length_in);
   IX31 intermediate_expression19(ix19, ix18, poly_in, length_in);

   always @ (posedge clock_in) begin
      if (reset_in) begin 
         PRBS <= 31'b1111111111111111111111111111111;
         data_out <= 1;
      end else if (advance_in) begin
         PRBS <= ix19;
         data_out <= {ix00[30], ix01[30], ix02[30], ix03[30], ix04[30], ix05[30], ix06[30], ix07[30], ix08[30], ix09[30], ix10[30], ix11[30], ix12[30], ix13[30], ix14[30], ix15[30], ix16[30], ix17[30], ix18[30], ix19[30]};
      end
   end
endmodule

module PRBSGen29(data_out, advance_in, reset_in,
                 poly_in, length_in, clock_in
                 );

   output [19:00] data_out;
   input [28:00]  poly_in;
   input          length_in, advance_in, reset_in, clock_in;
   
   reg [28:00]    PRBS;
   reg [19:00]    data_out;
   
   wire [28:00]   ix00, ix01, ix02, ix03, ix04, ix05, ix06, ix07, ix08, ix09, ix10, ix11, ix12, ix13, ix14, ix15, ix16, ix17, ix18, ix19;
   
   IX29 intermediate_expression00(ix00, PRBS, poly_in, length_in);
   IX29 intermediate_expression01(ix01, ix00, poly_in, length_in);
   IX29 intermediate_expression02(ix02, ix01, poly_in, length_in);
   IX29 intermediate_expression03(ix03, ix02, poly_in, length_in);
   IX29 intermediate_expression04(ix04, ix03, poly_in, length_in);
   IX29 intermediate_expression05(ix05, ix04, poly_in, length_in);
   IX29 intermediate_expression06(ix06, ix05, poly_in, length_in);
   IX29 intermediate_expression07(ix07, ix06, poly_in, length_in);
   IX29 intermediate_expression08(ix08, ix07, poly_in, length_in);
   IX29 intermediate_expression09(ix09, ix08, poly_in, length_in);
   IX29 intermediate_expression10(ix10, ix09, poly_in, length_in);
   IX29 intermediate_expression11(ix11, ix10, poly_in, length_in);
   IX29 intermediate_expression12(ix12, ix11, poly_in, length_in);
   IX29 intermediate_expression13(ix13, ix12, poly_in, length_in);
   IX29 intermediate_expression14(ix14, ix13, poly_in, length_in);
   IX29 intermediate_expression15(ix15, ix14, poly_in, length_in);
   IX29 intermediate_expression16(ix16, ix15, poly_in, length_in);
   IX29 intermediate_expression17(ix17, ix16, poly_in, length_in);
   IX29 intermediate_expression18(ix18, ix17, poly_in, length_in);
   IX29 intermediate_expression19(ix19, ix18, poly_in, length_in);

   always @ (posedge clock_in) begin
      if (reset_in) begin 
         PRBS <= 29'b11111111111111111111111111111;
         data_out <= 1;
      end else if (advance_in) begin
         PRBS <= ix19;
         data_out <= {ix00[28], ix01[28], ix02[28], ix03[28], ix04[28], ix05[28], ix06[28], ix07[28], ix08[28], ix09[28], ix10[28], ix11[28], ix12[28], ix13[28], ix14[28], ix15[28], ix16[28], ix17[28], ix18[28], ix19[28]};
      end
   end
endmodule

module PRBSGen23(data_out, advance_in, reset_in,
                 poly_in, length_in, clock_in
                 );

   output [19:00] data_out;
   input [22:00]  poly_in;
   input          length_in, advance_in, reset_in, clock_in;
   
   reg [22:00]    PRBS;
   reg [19:00]    data_out;
   
   wire [22:00]   ix00, ix01, ix02, ix03, ix04, ix05, ix06, ix07, ix08, ix09, ix10, ix11, ix12, ix13, ix14, ix15, ix16, ix17, ix18, ix19;

   IX23 intermediate_expression00(ix00, PRBS, poly_in, length_in);
   IX23 intermediate_expression01(ix01, ix00, poly_in, length_in);
   IX23 intermediate_expression02(ix02, ix01, poly_in, length_in);
   IX23 intermediate_expression03(ix03, ix02, poly_in, length_in);
   IX23 intermediate_expression04(ix04, ix03, poly_in, length_in);
   IX23 intermediate_expression05(ix05, ix04, poly_in, length_in);
   IX23 intermediate_expression06(ix06, ix05, poly_in, length_in);
   IX23 intermediate_expression07(ix07, ix06, poly_in, length_in);
   IX23 intermediate_expression08(ix08, ix07, poly_in, length_in);
   IX23 intermediate_expression09(ix09, ix08, poly_in, length_in);
   IX23 intermediate_expression10(ix10, ix09, poly_in, length_in);
   IX23 intermediate_expression11(ix11, ix10, poly_in, length_in);
   IX23 intermediate_expression12(ix12, ix11, poly_in, length_in);
   IX23 intermediate_expression13(ix13, ix12, poly_in, length_in);
   IX23 intermediate_expression14(ix14, ix13, poly_in, length_in);
   IX23 intermediate_expression15(ix15, ix14, poly_in, length_in);
   IX23 intermediate_expression16(ix16, ix15, poly_in, length_in);
   IX23 intermediate_expression17(ix17, ix16, poly_in, length_in);
   IX23 intermediate_expression18(ix18, ix17, poly_in, length_in);
   IX23 intermediate_expression19(ix19, ix18, poly_in, length_in);

   always @ (posedge clock_in) begin
      if (reset_in) begin 
         PRBS <= 23'b11111111111111111111111;
         data_out <= 1;
      end else if (advance_in) begin
         PRBS <= ix19;
         data_out <= {ix00[22], ix01[22], ix02[22], ix03[22], ix04[22], ix05[22], ix06[22], ix07[22], ix08[22], ix09[22], ix10[22], ix11[22], ix12[22], ix13[22], ix14[22], ix15[22], ix16[22], ix17[22], ix18[22], ix19[22]};
      end
   end
endmodule

module PRBSGen20(data_out, advance_in, reset_in,
                 poly_in, length_in, clock_in
                 );

   output [19:00] data_out;
   input [19:00]  poly_in;
   input          length_in, advance_in, reset_in, clock_in;
   
   reg [19:00]    PRBS;
   reg [19:00]    data_out;
   
   wire [19:00]   ix00, ix01, ix02, ix03, ix04, ix05, ix06, ix07, ix08, ix09, ix10, ix11, ix12, ix13, ix14, ix15, ix16, ix17, ix18, ix19;

   IX20 intermediate_expression00(ix00, PRBS, poly_in, length_in);
   IX20 intermediate_expression01(ix01, ix00, poly_in, length_in);
   IX20 intermediate_expression02(ix02, ix01, poly_in, length_in);
   IX20 intermediate_expression03(ix03, ix02, poly_in, length_in);
   IX20 intermediate_expression04(ix04, ix03, poly_in, length_in);
   IX20 intermediate_expression05(ix05, ix04, poly_in, length_in);
   IX20 intermediate_expression06(ix06, ix05, poly_in, length_in);
   IX20 intermediate_expression07(ix07, ix06, poly_in, length_in);
   IX20 intermediate_expression08(ix08, ix07, poly_in, length_in);
   IX20 intermediate_expression09(ix09, ix08, poly_in, length_in);
   IX20 intermediate_expression10(ix10, ix09, poly_in, length_in);
   IX20 intermediate_expression11(ix11, ix10, poly_in, length_in);
   IX20 intermediate_expression12(ix12, ix11, poly_in, length_in);
   IX20 intermediate_expression13(ix13, ix12, poly_in, length_in);
   IX20 intermediate_expression14(ix14, ix13, poly_in, length_in);
   IX20 intermediate_expression15(ix15, ix14, poly_in, length_in);
   IX20 intermediate_expression16(ix16, ix15, poly_in, length_in);
   IX20 intermediate_expression17(ix17, ix16, poly_in, length_in);
   IX20 intermediate_expression18(ix18, ix17, poly_in, length_in);
   IX20 intermediate_expression19(ix19, ix18, poly_in, length_in);

   always @ (posedge clock_in) begin
      if (reset_in) begin 
         PRBS <= 20'b11111111111111111111;
         data_out <= 1;
      end else if (advance_in) begin
         PRBS <= ix19;
         data_out <= {ix00[19], ix01[19], ix02[19], ix03[19], ix04[19], ix05[19], ix06[19], ix07[19], ix08[19], ix09[19], ix10[19], ix11[19], ix12[19], ix13[19], ix14[19], ix15[19], ix16[19], ix17[19], ix18[19], ix19[19]};
      end
   end
endmodule

module PRBSGen15(data_out, advance_in, reset_in,
                 poly_in, length_in, clock_in
                 );

   output [19:00] data_out;
   input [14:00]  poly_in;
   input          length_in, advance_in, reset_in, clock_in;
   
   reg [14:00]    PRBS;
   reg [19:00]    data_out;
   
   wire [14:00]   ix00, ix01, ix02, ix03, ix04, ix05, ix06, ix07, ix08, ix09, ix10, ix11, ix12, ix13, ix14, ix15, ix16, ix17, ix18, ix19;

   IX15 intermediate_expression00(ix00, PRBS, poly_in, length_in);
   IX15 intermediate_expression01(ix01, ix00, poly_in, length_in);
   IX15 intermediate_expression02(ix02, ix01, poly_in, length_in);
   IX15 intermediate_expression03(ix03, ix02, poly_in, length_in);
   IX15 intermediate_expression04(ix04, ix03, poly_in, length_in);
   IX15 intermediate_expression05(ix05, ix04, poly_in, length_in);
   IX15 intermediate_expression06(ix06, ix05, poly_in, length_in);
   IX15 intermediate_expression07(ix07, ix06, poly_in, length_in);
   IX15 intermediate_expression08(ix08, ix07, poly_in, length_in);
   IX15 intermediate_expression09(ix09, ix08, poly_in, length_in);
   IX15 intermediate_expression10(ix10, ix09, poly_in, length_in);
   IX15 intermediate_expression11(ix11, ix10, poly_in, length_in);
   IX15 intermediate_expression12(ix12, ix11, poly_in, length_in);
   IX15 intermediate_expression13(ix13, ix12, poly_in, length_in);
   IX15 intermediate_expression14(ix14, ix13, poly_in, length_in);
   IX15 intermediate_expression15(ix15, ix14, poly_in, length_in);
   IX15 intermediate_expression16(ix16, ix15, poly_in, length_in);
   IX15 intermediate_expression17(ix17, ix16, poly_in, length_in);
   IX15 intermediate_expression18(ix18, ix17, poly_in, length_in);
   IX15 intermediate_expression19(ix19, ix18, poly_in, length_in);

   always @ (posedge clock_in) begin
      if (reset_in) begin 
         PRBS <= 15'b111111111111111;
         data_out <= 1;
      end else if (advance_in) begin
         PRBS <= ix19;
         data_out <= {ix00[14], ix01[14], ix02[14], ix03[14], ix04[14], ix05[14], ix06[14], ix07[14], ix08[14], ix09[14], ix10[14], ix11[14], ix12[14], ix13[14], ix14[14], ix15[14], ix16[14], ix17[14], ix18[14], ix19[14]};
      end
   end
endmodule

module PRBSGen11(data_out, advance_in, reset_in,
                 poly_in, length_in, clock_in
                 );

   output [19:00] data_out;
   input [10:00]  poly_in;
   input          length_in, advance_in, reset_in, clock_in;
   
   reg [10:00]    PRBS;
   reg [19:00]    data_out;
   
   wire [10:00]   ix00, ix01, ix02, ix03, ix04, ix05, ix06, ix07, ix08, ix09, ix10, ix11, ix12, ix13, ix14, ix15, ix16, ix17, ix18, ix19;

   IX11 intermediate_expression00(ix00, PRBS, poly_in, length_in);
   IX11 intermediate_expression01(ix01, ix00, poly_in, length_in);
   IX11 intermediate_expression02(ix02, ix01, poly_in, length_in);
   IX11 intermediate_expression03(ix03, ix02, poly_in, length_in);
   IX11 intermediate_expression04(ix04, ix03, poly_in, length_in);
   IX11 intermediate_expression05(ix05, ix04, poly_in, length_in);
   IX11 intermediate_expression06(ix06, ix05, poly_in, length_in);
   IX11 intermediate_expression07(ix07, ix06, poly_in, length_in);
   IX11 intermediate_expression08(ix08, ix07, poly_in, length_in);
   IX11 intermediate_expression09(ix09, ix08, poly_in, length_in);
   IX11 intermediate_expression10(ix10, ix09, poly_in, length_in);
   IX11 intermediate_expression11(ix11, ix10, poly_in, length_in);
   IX11 intermediate_expression12(ix12, ix11, poly_in, length_in);
   IX11 intermediate_expression13(ix13, ix12, poly_in, length_in);
   IX11 intermediate_expression14(ix14, ix13, poly_in, length_in);
   IX11 intermediate_expression15(ix15, ix14, poly_in, length_in);
   IX11 intermediate_expression16(ix16, ix15, poly_in, length_in);
   IX11 intermediate_expression17(ix17, ix16, poly_in, length_in);
   IX11 intermediate_expression18(ix18, ix17, poly_in, length_in);
   IX11 intermediate_expression19(ix19, ix18, poly_in, length_in);

   always @ (posedge clock_in) begin
      if (reset_in) begin 
         PRBS <= 11'b11111111111;
         data_out <= 1;
      end else if (advance_in) begin
         PRBS <= ix19;
         data_out <= {ix00[10], ix01[10], ix02[10], ix03[10], ix04[10], ix05[10], ix06[10], ix07[10], ix08[10], ix09[10], ix10[10], ix11[10], ix12[10], ix13[10], ix14[10], ix15[10], ix16[10], ix17[10], ix18[10], ix19[10]};
      end
   end
endmodule

module PRBSGen09(data_out, advance_in, reset_in,
                 poly_in, length_in, clock_in
                 );

   output [19:00] data_out;
   input [08:00]  poly_in;
   input          length_in, advance_in, reset_in, clock_in;
   
   reg [08:00]    PRBS;
   reg [19:00]    data_out;
   
   wire [08:00]   ix00, ix01, ix02, ix03, ix04, ix05, ix06, ix07, ix08, ix09, ix10, ix11, ix12, ix13, ix14, ix15, ix16, ix17, ix18, ix19;

   IX09 intermediate_expression00(ix00, PRBS, poly_in, length_in);
   IX09 intermediate_expression01(ix01, ix00, poly_in, length_in);
   IX09 intermediate_expression02(ix02, ix01, poly_in, length_in);
   IX09 intermediate_expression03(ix03, ix02, poly_in, length_in);
   IX09 intermediate_expression04(ix04, ix03, poly_in, length_in);
   IX09 intermediate_expression05(ix05, ix04, poly_in, length_in);
   IX09 intermediate_expression06(ix06, ix05, poly_in, length_in);
   IX09 intermediate_expression07(ix07, ix06, poly_in, length_in);
   IX09 intermediate_expression08(ix08, ix07, poly_in, length_in);
   IX09 intermediate_expression09(ix09, ix08, poly_in, length_in);
   IX09 intermediate_expression10(ix10, ix09, poly_in, length_in);
   IX09 intermediate_expression11(ix11, ix10, poly_in, length_in);
   IX09 intermediate_expression12(ix12, ix11, poly_in, length_in);
   IX09 intermediate_expression13(ix13, ix12, poly_in, length_in);
   IX09 intermediate_expression14(ix14, ix13, poly_in, length_in);
   IX09 intermediate_expression15(ix15, ix14, poly_in, length_in);
   IX09 intermediate_expression16(ix16, ix15, poly_in, length_in);
   IX09 intermediate_expression17(ix17, ix16, poly_in, length_in);
   IX09 intermediate_expression18(ix18, ix17, poly_in, length_in);
   IX09 intermediate_expression19(ix19, ix18, poly_in, length_in);

   always @ (posedge clock_in) begin
      if (reset_in) begin 
         PRBS <= 9'b111111111;
         data_out <= 1;
      end else if (advance_in) begin
         PRBS <= ix19;
         data_out <= {ix00[08], ix01[08], ix02[08], ix03[08], ix04[08], ix05[08], ix06[08], ix07[08], ix08[08], ix09[08], ix10[08], ix11[08], ix12[08], ix13[08], ix14[08], ix15[08], ix16[08], ix17[08], ix18[08], ix19[08]};
      end
   end
endmodule

module PRBSGen07(data_out, advance_in, reset_in,
                 poly_in, length_in, clock_in
                 );

   output [19:00] data_out;
   input [06:00]  poly_in;
   input          length_in, advance_in, reset_in, clock_in;
   
   reg [06:00]    PRBS;
   reg [19:00]    data_out;
   
   wire [06:00]   ix00, ix01, ix02, ix03, ix04, ix05, ix06, ix07, ix08, ix09, ix10, ix11, ix12, ix13, ix14, ix15, ix16, ix17, ix18, ix19;

   IX07 intermediate_expression00(ix00, PRBS, poly_in, length_in);
   IX07 intermediate_expression01(ix01, ix00, poly_in, length_in);
   IX07 intermediate_expression02(ix02, ix01, poly_in, length_in);
   IX07 intermediate_expression03(ix03, ix02, poly_in, length_in);
   IX07 intermediate_expression04(ix04, ix03, poly_in, length_in);
   IX07 intermediate_expression05(ix05, ix04, poly_in, length_in);
   IX07 intermediate_expression06(ix06, ix05, poly_in, length_in);
   IX07 intermediate_expression07(ix07, ix06, poly_in, length_in);
   IX07 intermediate_expression08(ix08, ix07, poly_in, length_in);
   IX07 intermediate_expression09(ix09, ix08, poly_in, length_in);
   IX07 intermediate_expression10(ix10, ix09, poly_in, length_in);
   IX07 intermediate_expression11(ix11, ix10, poly_in, length_in);
   IX07 intermediate_expression12(ix12, ix11, poly_in, length_in);
   IX07 intermediate_expression13(ix13, ix12, poly_in, length_in);
   IX07 intermediate_expression14(ix14, ix13, poly_in, length_in);
   IX07 intermediate_expression15(ix15, ix14, poly_in, length_in);
   IX07 intermediate_expression16(ix16, ix15, poly_in, length_in);
   IX07 intermediate_expression17(ix17, ix16, poly_in, length_in);
   IX07 intermediate_expression18(ix18, ix17, poly_in, length_in);
   IX07 intermediate_expression19(ix19, ix18, poly_in, length_in);

   always @ (posedge clock_in) begin
      if (reset_in) begin 
         PRBS <= 7'b1111111;
         data_out <= 1;
      end else if (advance_in) begin
         PRBS <= ix19;
         data_out <= {ix00[06], ix01[06], ix02[06], ix03[06], ix04[06], ix05[06], ix06[06], ix07[06], ix08[06], ix09[06], ix10[06], ix11[06], ix12[06], ix13[06], ix14[06], ix15[06], ix16[06], ix17[06], ix18[06], ix19[06]};
      end
   end
endmodule

//----------------------------------------------------------------
//
// III. Intermediate Expression Section.
//   A. Contents:
//     1. IX31: 31-bit implementation
//     2. IX29: 29-bit implementation
//     3. IX23: 23-bit implementation
//     4. IX20: 20-bit implementation
//     5. IX15: 15-bit implementation
//     6. IX11: 11-bit implementation
//     6. IX09:  9-bit implementation
//     6. IX07:  7-bit implementation
//
//   B. Port Summary.
//
//     exp_out[19:00] (asynchronous)
//        Value of the LFSR at time T(n+1).
//
//     exp_in[19:00] (asynchronous)
//        Value of the LFSR at time T(n).
//
//     poly_in[XX:00] (asynchronous)
//        Number representing the LFSR's polynomial.
//
//     length_in (asynchronous)
//        High if the LFSR should be maximal length.
//
//----------------------------------------------------------------
`ifdef WITH_TYPE1 
module IX32 (exp_out, exp_in, poly_in, length_in);
   output [31:00] exp_out;
   input [31:00]  exp_in, poly_in;
   input          length_in;

   assign exp_out[00] = (exp_in[00] & poly_in[31]) ^
                        (exp_in[01] & poly_in[30]) ^
                        (exp_in[02] & poly_in[29]) ^
                        (exp_in[03] & poly_in[28]) ^
                        (exp_in[04] & poly_in[27]) ^
                        (exp_in[05] & poly_in[26]) ^
                        (exp_in[06] & poly_in[25]) ^
                        (exp_in[07] & poly_in[24]) ^
                        (exp_in[08] & poly_in[23]) ^
                        (exp_in[09] & poly_in[22]) ^
                        (exp_in[10] & poly_in[21]) ^
                        (exp_in[11] & poly_in[20]) ^
                        (exp_in[12] & poly_in[19]) ^
                        (exp_in[13] & poly_in[18]) ^
                        (exp_in[14] & poly_in[17]) ^
                        (exp_in[15] & poly_in[16]) ^
                        (exp_in[16] & poly_in[15]) ^
                        (exp_in[17] & poly_in[14]) ^
                        (exp_in[18] & poly_in[13]) ^
                        (exp_in[19] & poly_in[12]) ^
                        (exp_in[20] & poly_in[11]) ^
                        (exp_in[21] & poly_in[10]) ^
                        (exp_in[22] & poly_in[09]) ^
                        (exp_in[23] & poly_in[08]) ^
                        (exp_in[24] & poly_in[07]) ^
                        (exp_in[25] & poly_in[06]) ^
                        (exp_in[26] & poly_in[05]) ^
                        (exp_in[27] & poly_in[04]) ^
                        (exp_in[28] & poly_in[03]) ^
                        (exp_in[29] & poly_in[02]) ^
                        (exp_in[30] & poly_in[01]) ^
                        (exp_in[31] & poly_in[00]) ^ length_in;

   assign exp_out[31:01] = exp_in[30:00];
endmodule

module IX31 (exp_out, exp_in, poly_in, length_in);
   output [30:00] exp_out;
   input [30:00]  exp_in, poly_in;
   input          length_in;

   assign exp_out[00] = (exp_in[00] & poly_in[30]) ^
                        (exp_in[01] & poly_in[29]) ^
                        (exp_in[02] & poly_in[28]) ^
                        (exp_in[03] & poly_in[27]) ^
                        (exp_in[04] & poly_in[26]) ^
                        (exp_in[05] & poly_in[25]) ^
                        (exp_in[06] & poly_in[24]) ^
                        (exp_in[07] & poly_in[23]) ^
                        (exp_in[08] & poly_in[22]) ^
                        (exp_in[09] & poly_in[21]) ^
                        (exp_in[10] & poly_in[20]) ^
                        (exp_in[11] & poly_in[19]) ^
                        (exp_in[12] & poly_in[18]) ^
                        (exp_in[13] & poly_in[17]) ^
                        (exp_in[14] & poly_in[16]) ^
                        (exp_in[15] & poly_in[15]) ^
                        (exp_in[16] & poly_in[14]) ^
                        (exp_in[17] & poly_in[13]) ^
                        (exp_in[18] & poly_in[12]) ^
                        (exp_in[19] & poly_in[11]) ^
                        (exp_in[20] & poly_in[10]) ^
                        (exp_in[21] & poly_in[09]) ^
                        (exp_in[22] & poly_in[08]) ^
                        (exp_in[23] & poly_in[07]) ^
                        (exp_in[24] & poly_in[06]) ^
                        (exp_in[25] & poly_in[05]) ^
                        (exp_in[26] & poly_in[04]) ^
                        (exp_in[27] & poly_in[03]) ^
                        (exp_in[28] & poly_in[02]) ^
                        (exp_in[29] & poly_in[01]) ^
                        (exp_in[30] & poly_in[00]) ^ length_in;

   assign exp_out[30:01] = exp_in[29:00];
endmodule

module IX29 (exp_out, exp_in, poly_in, length_in);
   output [28:00] exp_out;
   input [28:00]  exp_in, poly_in;
   input          length_in;

   assign exp_out[00] = (exp_in[00] & poly_in[28]) ^
                        (exp_in[01] & poly_in[27]) ^
                        (exp_in[02] & poly_in[26]) ^
                        (exp_in[03] & poly_in[25]) ^
                        (exp_in[04] & poly_in[24]) ^
                        (exp_in[05] & poly_in[23]) ^
                        (exp_in[06] & poly_in[22]) ^
                        (exp_in[07] & poly_in[21]) ^
                        (exp_in[08] & poly_in[20]) ^
                        (exp_in[09] & poly_in[19]) ^
                        (exp_in[10] & poly_in[18]) ^
                        (exp_in[11] & poly_in[17]) ^
                        (exp_in[12] & poly_in[16]) ^
                        (exp_in[13] & poly_in[15]) ^
                        (exp_in[14] & poly_in[14]) ^
                        (exp_in[15] & poly_in[13]) ^
                        (exp_in[16] & poly_in[12]) ^
                        (exp_in[17] & poly_in[11]) ^
                        (exp_in[18] & poly_in[10]) ^
                        (exp_in[19] & poly_in[09]) ^
                        (exp_in[20] & poly_in[08]) ^
                        (exp_in[21] & poly_in[07]) ^
                        (exp_in[22] & poly_in[06]) ^
                        (exp_in[23] & poly_in[05]) ^
                        (exp_in[24] & poly_in[04]) ^
                        (exp_in[25] & poly_in[03]) ^
                        (exp_in[26] & poly_in[02]) ^
                        (exp_in[27] & poly_in[01]) ^
                        (exp_in[28] & poly_in[00]) ^ length_in;

   assign exp_out[28:01] = exp_in[27:00];
endmodule

module IX23 (exp_out, exp_in, poly_in, length_in);
   output [22:00] exp_out;
   input [22:00]  exp_in, poly_in;
   input          length_in;

   assign exp_out[00] = (exp_in[00] & poly_in[22]) ^
                        (exp_in[01] & poly_in[21]) ^
                        (exp_in[02] & poly_in[20]) ^
                        (exp_in[03] & poly_in[19]) ^
                        (exp_in[04] & poly_in[18]) ^
                        (exp_in[05] & poly_in[17]) ^
                        (exp_in[06] & poly_in[16]) ^
                        (exp_in[07] & poly_in[15]) ^
                        (exp_in[08] & poly_in[14]) ^
                        (exp_in[09] & poly_in[13]) ^
                        (exp_in[10] & poly_in[12]) ^
                        (exp_in[11] & poly_in[11]) ^
                        (exp_in[12] & poly_in[10]) ^
                        (exp_in[13] & poly_in[09]) ^
                        (exp_in[14] & poly_in[08]) ^
                        (exp_in[15] & poly_in[07]) ^
                        (exp_in[16] & poly_in[06]) ^
                        (exp_in[17] & poly_in[05]) ^
                        (exp_in[18] & poly_in[04]) ^
                        (exp_in[19] & poly_in[03]) ^
                        (exp_in[20] & poly_in[02]) ^
                        (exp_in[21] & poly_in[01]) ^
                        (exp_in[22] & poly_in[00]) ^ length_in;


   assign exp_out[22:01] = exp_in[21:00];
endmodule

module IX20 (exp_out, exp_in, poly_in, length_in);
   output [19:00] exp_out;
   input [19:00]  exp_in, poly_in;
   input          length_in;

   assign exp_out[00] = (exp_in[00] & poly_in[19]) ^
                        (exp_in[01] & poly_in[18]) ^
                        (exp_in[02] & poly_in[17]) ^
                        (exp_in[03] & poly_in[16]) ^
                        (exp_in[04] & poly_in[15]) ^
                        (exp_in[05] & poly_in[14]) ^
                        (exp_in[06] & poly_in[13]) ^
                        (exp_in[07] & poly_in[12]) ^
                        (exp_in[08] & poly_in[11]) ^
                        (exp_in[09] & poly_in[10]) ^
                        (exp_in[10] & poly_in[09]) ^
                        (exp_in[11] & poly_in[08]) ^
                        (exp_in[12] & poly_in[07]) ^
                        (exp_in[13] & poly_in[06]) ^
                        (exp_in[14] & poly_in[05]) ^
                        (exp_in[15] & poly_in[04]) ^
                        (exp_in[16] & poly_in[03]) ^
                        (exp_in[17] & poly_in[02]) ^
                        (exp_in[18] & poly_in[01]) ^
                        (exp_in[19] & poly_in[00]) ^ length_in;

   assign exp_out[19:01] = exp_in[18:00];
endmodule

module IX15 (exp_out, exp_in, poly_in, length_in);
   output [14:00] exp_out;
   input [14:00]  exp_in, poly_in;
   input          length_in;

   assign exp_out[00] = (exp_in[00] & poly_in[14]) ^
                        (exp_in[01] & poly_in[13]) ^
                        (exp_in[02] & poly_in[12]) ^
                        (exp_in[03] & poly_in[11]) ^
                        (exp_in[04] & poly_in[10]) ^
                        (exp_in[05] & poly_in[09]) ^
                        (exp_in[06] & poly_in[08]) ^
                        (exp_in[07] & poly_in[07]) ^
                        (exp_in[08] & poly_in[06]) ^
                        (exp_in[09] & poly_in[05]) ^
                        (exp_in[10] & poly_in[04]) ^
                        (exp_in[11] & poly_in[03]) ^
                        (exp_in[12] & poly_in[02]) ^
                        (exp_in[13] & poly_in[01]) ^
                        (exp_in[14] & poly_in[00]) ^ length_in;

   assign exp_out[14:01] = exp_in[13:00];
endmodule

module IX11 (exp_out, exp_in, poly_in, length_in);
   output [10:00] exp_out;
   input [10:00]  exp_in, poly_in;
   input          length_in;

   assign exp_out[00] = (exp_in[00] & poly_in[10]) ^
                        (exp_in[01] & poly_in[09]) ^
                        (exp_in[02] & poly_in[08]) ^
                        (exp_in[03] & poly_in[07]) ^
                        (exp_in[04] & poly_in[06]) ^
                        (exp_in[05] & poly_in[05]) ^
                        (exp_in[06] & poly_in[04]) ^
                        (exp_in[07] & poly_in[03]) ^
                        (exp_in[08] & poly_in[02]) ^
                        (exp_in[09] & poly_in[01]) ^
                        (exp_in[10] & poly_in[00]) ^ length_in;

   assign exp_out[10:01] = exp_in[09:00];
endmodule

module IX09 (exp_out, exp_in, poly_in, length_in);
   output [08:00] exp_out;
   input [08:00]  exp_in, poly_in;
   input          length_in;

   assign exp_out[00] = (exp_in[00] & poly_in[08]) ^
                        (exp_in[01] & poly_in[07]) ^
                        (exp_in[02] & poly_in[06]) ^
                        (exp_in[03] & poly_in[05]) ^
                        (exp_in[04] & poly_in[04]) ^
                        (exp_in[05] & poly_in[03]) ^
                        (exp_in[06] & poly_in[02]) ^
                        (exp_in[07] & poly_in[01]) ^
                        (exp_in[08] & poly_in[00]) ^ length_in;
   
   assign exp_out[08:01] = exp_in[07:00];
endmodule

module IX07 (exp_out, exp_in, poly_in, length_in);
   output [06:00] exp_out;
   input [06:00]  exp_in, poly_in;
   input          length_in;

   assign exp_out[00] = (exp_in[00] & poly_in[06]) ^
                        (exp_in[01] & poly_in[05]) ^
                        (exp_in[02] & poly_in[04]) ^
                        (exp_in[03] & poly_in[03]) ^
                        (exp_in[04] & poly_in[02]) ^
                        (exp_in[05] & poly_in[01]) ^
                        (exp_in[06] & poly_in[00]) ^ length_in;
   
   assign exp_out[06:01] = exp_in[05:00];
endmodule
`endif // WITH_TYPE1

`ifdef WITH_TYPE2  
module IX32 (exp_out, exp_in, poly_in, length_in);
   output [31:00] exp_out;
   input [31:00]  exp_in, poly_in;
   input          length_in;
   assign exp_out[00] = length_in  ^ (exp_in[31] & poly_in[00]);
   assign exp_out[01] = exp_in[00] ^ (exp_in[31] & poly_in[01]);
   assign exp_out[02] = exp_in[01] ^ (exp_in[31] & poly_in[02]);
   assign exp_out[03] = exp_in[02] ^ (exp_in[31] & poly_in[03]);
   assign exp_out[04] = exp_in[03] ^ (exp_in[31] & poly_in[04]);
   assign exp_out[05] = exp_in[04] ^ (exp_in[31] & poly_in[05]);
   assign exp_out[06] = exp_in[05] ^ (exp_in[31] & poly_in[06]);
   assign exp_out[07] = exp_in[06] ^ (exp_in[31] & poly_in[07]);
   assign exp_out[08] = exp_in[07] ^ (exp_in[31] & poly_in[08]);
   assign exp_out[09] = exp_in[08] ^ (exp_in[31] & poly_in[09]);
   assign exp_out[10] = exp_in[09] ^ (exp_in[31] & poly_in[10]);
   assign exp_out[11] = exp_in[10] ^ (exp_in[31] & poly_in[11]);
   assign exp_out[12] = exp_in[11] ^ (exp_in[31] & poly_in[12]);
   assign exp_out[13] = exp_in[12] ^ (exp_in[31] & poly_in[13]);
   assign exp_out[14] = exp_in[13] ^ (exp_in[31] & poly_in[14]);
   assign exp_out[15] = exp_in[14] ^ (exp_in[31] & poly_in[15]);
   assign exp_out[16] = exp_in[15] ^ (exp_in[31] & poly_in[16]);
   assign exp_out[17] = exp_in[16] ^ (exp_in[31] & poly_in[17]);
   assign exp_out[18] = exp_in[17] ^ (exp_in[31] & poly_in[18]);
   assign exp_out[19] = exp_in[18] ^ (exp_in[31] & poly_in[19]);
   assign exp_out[20] = exp_in[19] ^ (exp_in[31] & poly_in[20]);
   assign exp_out[21] = exp_in[20] ^ (exp_in[31] & poly_in[21]);
   assign exp_out[22] = exp_in[21] ^ (exp_in[31] & poly_in[22]);
   assign exp_out[23] = exp_in[22] ^ (exp_in[31] & poly_in[23]);
   assign exp_out[24] = exp_in[23] ^ (exp_in[31] & poly_in[24]);
   assign exp_out[25] = exp_in[24] ^ (exp_in[31] & poly_in[25]);
   assign exp_out[26] = exp_in[25] ^ (exp_in[31] & poly_in[26]);
   assign exp_out[27] = exp_in[26] ^ (exp_in[31] & poly_in[27]);
   assign exp_out[28] = exp_in[27] ^ (exp_in[31] & poly_in[28]);
   assign exp_out[29] = exp_in[28] ^ (exp_in[31] & poly_in[29]);
   assign exp_out[30] = exp_in[29] ^ (exp_in[31] & poly_in[30]);
   assign exp_out[31] = exp_in[30] ^ (exp_in[31] & poly_in[31]);
endmodule

module IX31 (exp_out, exp_in, poly_in, length_in);
   output [30:00] exp_out;
   input [30:00]  exp_in, poly_in;
   input          length_in;
   assign exp_out[00] = length_in  ^ (exp_in[30] & poly_in[00]);
   assign exp_out[01] = exp_in[00] ^ (exp_in[30] & poly_in[01]);
   assign exp_out[02] = exp_in[01] ^ (exp_in[30] & poly_in[02]);
   assign exp_out[03] = exp_in[02] ^ (exp_in[30] & poly_in[03]);
   assign exp_out[04] = exp_in[03] ^ (exp_in[30] & poly_in[04]);
   assign exp_out[05] = exp_in[04] ^ (exp_in[30] & poly_in[05]);
   assign exp_out[06] = exp_in[05] ^ (exp_in[30] & poly_in[06]);
   assign exp_out[07] = exp_in[06] ^ (exp_in[30] & poly_in[07]);
   assign exp_out[08] = exp_in[07] ^ (exp_in[30] & poly_in[08]);
   assign exp_out[09] = exp_in[08] ^ (exp_in[30] & poly_in[09]);
   assign exp_out[10] = exp_in[09] ^ (exp_in[30] & poly_in[10]);
   assign exp_out[11] = exp_in[10] ^ (exp_in[30] & poly_in[11]);
   assign exp_out[12] = exp_in[11] ^ (exp_in[30] & poly_in[12]);
   assign exp_out[13] = exp_in[12] ^ (exp_in[30] & poly_in[13]);
   assign exp_out[14] = exp_in[13] ^ (exp_in[30] & poly_in[14]);
   assign exp_out[15] = exp_in[14] ^ (exp_in[30] & poly_in[15]);
   assign exp_out[16] = exp_in[15] ^ (exp_in[30] & poly_in[16]);
   assign exp_out[17] = exp_in[16] ^ (exp_in[30] & poly_in[17]);
   assign exp_out[18] = exp_in[17] ^ (exp_in[30] & poly_in[18]);
   assign exp_out[19] = exp_in[18] ^ (exp_in[30] & poly_in[19]);
   assign exp_out[20] = exp_in[19] ^ (exp_in[30] & poly_in[20]);
   assign exp_out[21] = exp_in[20] ^ (exp_in[30] & poly_in[21]);
   assign exp_out[22] = exp_in[21] ^ (exp_in[30] & poly_in[22]);
   assign exp_out[23] = exp_in[22] ^ (exp_in[30] & poly_in[23]);
   assign exp_out[24] = exp_in[23] ^ (exp_in[30] & poly_in[24]);
   assign exp_out[25] = exp_in[24] ^ (exp_in[30] & poly_in[25]);
   assign exp_out[26] = exp_in[25] ^ (exp_in[30] & poly_in[26]);
   assign exp_out[27] = exp_in[26] ^ (exp_in[30] & poly_in[27]);
   assign exp_out[28] = exp_in[27] ^ (exp_in[30] & poly_in[28]);
   assign exp_out[29] = exp_in[28] ^ (exp_in[30] & poly_in[29]);
   assign exp_out[30] = exp_in[29] ^ (exp_in[30] & poly_in[30]);
endmodule

module IX29 (exp_out, exp_in, poly_in, length_in);
   output [28:00] exp_out;
   input [28:00]  exp_in, poly_in;
   input          length_in;
   assign exp_out[00] = length_in  ^ (exp_in[28] & poly_in[00]);
   assign exp_out[01] = exp_in[00] ^ (exp_in[28] & poly_in[01]);
   assign exp_out[02] = exp_in[01] ^ (exp_in[28] & poly_in[02]);
   assign exp_out[03] = exp_in[02] ^ (exp_in[28] & poly_in[03]);
   assign exp_out[04] = exp_in[03] ^ (exp_in[28] & poly_in[04]);
   assign exp_out[05] = exp_in[04] ^ (exp_in[28] & poly_in[05]);
   assign exp_out[06] = exp_in[05] ^ (exp_in[28] & poly_in[06]);
   assign exp_out[07] = exp_in[06] ^ (exp_in[28] & poly_in[07]);
   assign exp_out[08] = exp_in[07] ^ (exp_in[28] & poly_in[08]);
   assign exp_out[09] = exp_in[08] ^ (exp_in[28] & poly_in[09]);
   assign exp_out[10] = exp_in[09] ^ (exp_in[28] & poly_in[10]);
   assign exp_out[11] = exp_in[10] ^ (exp_in[28] & poly_in[11]);
   assign exp_out[12] = exp_in[11] ^ (exp_in[28] & poly_in[12]);
   assign exp_out[13] = exp_in[12] ^ (exp_in[28] & poly_in[13]);
   assign exp_out[14] = exp_in[13] ^ (exp_in[28] & poly_in[14]);
   assign exp_out[15] = exp_in[14] ^ (exp_in[28] & poly_in[15]);
   assign exp_out[16] = exp_in[15] ^ (exp_in[28] & poly_in[16]);
   assign exp_out[17] = exp_in[16] ^ (exp_in[28] & poly_in[17]);
   assign exp_out[18] = exp_in[17] ^ (exp_in[28] & poly_in[18]);
   assign exp_out[19] = exp_in[18] ^ (exp_in[28] & poly_in[19]);
   assign exp_out[20] = exp_in[19] ^ (exp_in[28] & poly_in[20]);
   assign exp_out[21] = exp_in[20] ^ (exp_in[28] & poly_in[21]);
   assign exp_out[22] = exp_in[21] ^ (exp_in[28] & poly_in[22]);
   assign exp_out[23] = exp_in[22] ^ (exp_in[28] & poly_in[23]);
   assign exp_out[24] = exp_in[23] ^ (exp_in[28] & poly_in[24]);
   assign exp_out[25] = exp_in[24] ^ (exp_in[28] & poly_in[25]);
   assign exp_out[26] = exp_in[25] ^ (exp_in[28] & poly_in[26]);
   assign exp_out[27] = exp_in[26] ^ (exp_in[28] & poly_in[27]);
   assign exp_out[28] = exp_in[27] ^ (exp_in[28] & poly_in[28]);
endmodule

module IX23 (exp_out, exp_in, poly_in, length_in);
   output [22:00] exp_out;
   input [22:00]  exp_in, poly_in;
   input          length_in;
   assign exp_out[00] = length_in  ^ (exp_in[22] & poly_in[00]);
   assign exp_out[01] = exp_in[00] ^ (exp_in[22] & poly_in[01]);
   assign exp_out[02] = exp_in[01] ^ (exp_in[22] & poly_in[02]);
   assign exp_out[03] = exp_in[02] ^ (exp_in[22] & poly_in[03]);
   assign exp_out[04] = exp_in[03] ^ (exp_in[22] & poly_in[04]);
   assign exp_out[05] = exp_in[04] ^ (exp_in[22] & poly_in[05]);
   assign exp_out[06] = exp_in[05] ^ (exp_in[22] & poly_in[06]);
   assign exp_out[07] = exp_in[06] ^ (exp_in[22] & poly_in[07]);
   assign exp_out[08] = exp_in[07] ^ (exp_in[22] & poly_in[08]);
   assign exp_out[09] = exp_in[08] ^ (exp_in[22] & poly_in[09]);
   assign exp_out[10] = exp_in[09] ^ (exp_in[22] & poly_in[10]);
   assign exp_out[11] = exp_in[10] ^ (exp_in[22] & poly_in[11]);
   assign exp_out[12] = exp_in[11] ^ (exp_in[22] & poly_in[12]);
   assign exp_out[13] = exp_in[12] ^ (exp_in[22] & poly_in[13]);
   assign exp_out[14] = exp_in[13] ^ (exp_in[22] & poly_in[14]);
   assign exp_out[15] = exp_in[14] ^ (exp_in[22] & poly_in[15]);
   assign exp_out[16] = exp_in[15] ^ (exp_in[22] & poly_in[16]);
   assign exp_out[17] = exp_in[16] ^ (exp_in[22] & poly_in[17]);
   assign exp_out[18] = exp_in[17] ^ (exp_in[22] & poly_in[18]);
   assign exp_out[19] = exp_in[18] ^ (exp_in[22] & poly_in[19]);
   assign exp_out[20] = exp_in[19] ^ (exp_in[22] & poly_in[20]);
   assign exp_out[21] = exp_in[20] ^ (exp_in[22] & poly_in[21]);
   assign exp_out[22] = exp_in[21] ^ (exp_in[22] & poly_in[22]);
endmodule

module IX20 (exp_out, exp_in, poly_in, length_in);
   output [19:00] exp_out;
   input [19:00]  exp_in, poly_in;
   input          length_in;
   assign exp_out[00] = length_in  ^ (exp_in[19] & poly_in[00]);
   assign exp_out[01] = exp_in[00] ^ (exp_in[19] & poly_in[01]);
   assign exp_out[02] = exp_in[01] ^ (exp_in[19] & poly_in[02]);
   assign exp_out[03] = exp_in[02] ^ (exp_in[19] & poly_in[03]);
   assign exp_out[04] = exp_in[03] ^ (exp_in[19] & poly_in[04]);
   assign exp_out[05] = exp_in[04] ^ (exp_in[19] & poly_in[05]);
   assign exp_out[06] = exp_in[05] ^ (exp_in[19] & poly_in[06]);
   assign exp_out[07] = exp_in[06] ^ (exp_in[19] & poly_in[07]);
   assign exp_out[08] = exp_in[07] ^ (exp_in[19] & poly_in[08]);
   assign exp_out[09] = exp_in[08] ^ (exp_in[19] & poly_in[09]);
   assign exp_out[10] = exp_in[09] ^ (exp_in[19] & poly_in[10]);
   assign exp_out[11] = exp_in[10] ^ (exp_in[19] & poly_in[11]);
   assign exp_out[12] = exp_in[11] ^ (exp_in[19] & poly_in[12]);
   assign exp_out[13] = exp_in[12] ^ (exp_in[19] & poly_in[13]);
   assign exp_out[14] = exp_in[13] ^ (exp_in[19] & poly_in[14]);
   assign exp_out[15] = exp_in[14] ^ (exp_in[19] & poly_in[15]);
   assign exp_out[16] = exp_in[15] ^ (exp_in[19] & poly_in[16]);
   assign exp_out[17] = exp_in[16] ^ (exp_in[19] & poly_in[17]);
   assign exp_out[18] = exp_in[17] ^ (exp_in[19] & poly_in[18]);
   assign exp_out[19] = exp_in[18] ^ (exp_in[19] & poly_in[19]);
endmodule

module IX15 (exp_out, exp_in, poly_in, length_in);
   output [14:00] exp_out;
   input [14:00]  exp_in, poly_in;
   input          length_in;
   assign exp_out[00] = length_in  ^ (exp_in[14] & poly_in[00]);
   assign exp_out[01] = exp_in[00] ^ (exp_in[14] & poly_in[01]);
   assign exp_out[02] = exp_in[01] ^ (exp_in[14] & poly_in[02]);
   assign exp_out[03] = exp_in[02] ^ (exp_in[14] & poly_in[03]);
   assign exp_out[04] = exp_in[03] ^ (exp_in[14] & poly_in[04]);
   assign exp_out[05] = exp_in[04] ^ (exp_in[14] & poly_in[05]);
   assign exp_out[06] = exp_in[05] ^ (exp_in[14] & poly_in[06]);
   assign exp_out[07] = exp_in[06] ^ (exp_in[14] & poly_in[07]);
   assign exp_out[08] = exp_in[07] ^ (exp_in[14] & poly_in[08]);
   assign exp_out[09] = exp_in[08] ^ (exp_in[14] & poly_in[09]);
   assign exp_out[10] = exp_in[09] ^ (exp_in[14] & poly_in[10]);
   assign exp_out[11] = exp_in[10] ^ (exp_in[14] & poly_in[11]);
   assign exp_out[12] = exp_in[11] ^ (exp_in[14] & poly_in[12]);
   assign exp_out[13] = exp_in[12] ^ (exp_in[14] & poly_in[13]);
   assign exp_out[14] = exp_in[13] ^ (exp_in[14] & poly_in[14]);
endmodule

module IX11 (exp_out, exp_in, poly_in, length_in);
   output [10:00] exp_out;
   input [10:00]  exp_in, poly_in;
   input          length_in;
   assign exp_out[00] = length_in  ^ (exp_in[10] & poly_in[00]);
   assign exp_out[01] = exp_in[00] ^ (exp_in[10] & poly_in[01]);
   assign exp_out[02] = exp_in[01] ^ (exp_in[10] & poly_in[02]);
   assign exp_out[03] = exp_in[02] ^ (exp_in[10] & poly_in[03]);
   assign exp_out[04] = exp_in[03] ^ (exp_in[10] & poly_in[04]);
   assign exp_out[05] = exp_in[04] ^ (exp_in[10] & poly_in[05]);
   assign exp_out[06] = exp_in[05] ^ (exp_in[10] & poly_in[06]);
   assign exp_out[07] = exp_in[06] ^ (exp_in[10] & poly_in[07]);
   assign exp_out[08] = exp_in[07] ^ (exp_in[10] & poly_in[08]);
   assign exp_out[09] = exp_in[08] ^ (exp_in[10] & poly_in[09]);
   assign exp_out[10] = exp_in[09] ^ (exp_in[10] & poly_in[10]);
endmodule

module IX09 (exp_out, exp_in, poly_in, length_in);
   output [08:00] exp_out;
   input [08:00]  exp_in, poly_in;
   input          length_in;
   assign exp_out[00] = length_in  ^ (exp_in[08] & poly_in[00]);
   assign exp_out[01] = exp_in[00] ^ (exp_in[08] & poly_in[01]);
   assign exp_out[02] = exp_in[01] ^ (exp_in[08] & poly_in[02]);
   assign exp_out[03] = exp_in[02] ^ (exp_in[08] & poly_in[03]);
   assign exp_out[04] = exp_in[03] ^ (exp_in[08] & poly_in[04]);
   assign exp_out[05] = exp_in[04] ^ (exp_in[08] & poly_in[05]);
   assign exp_out[06] = exp_in[05] ^ (exp_in[08] & poly_in[06]);
   assign exp_out[07] = exp_in[06] ^ (exp_in[08] & poly_in[07]);
   assign exp_out[08] = exp_in[07] ^ (exp_in[08] & poly_in[08]);
endmodule

module IX07 (exp_out, exp_in, poly_in, length_in);
   output [06:00] exp_out;
   input [06:00]  exp_in, poly_in;
   input          length_in;
   assign exp_out[00] = length_in  ^ (exp_in[06] & poly_in[00]);
   assign exp_out[01] = exp_in[00] ^ (exp_in[06] & poly_in[01]);
   assign exp_out[02] = exp_in[01] ^ (exp_in[06] & poly_in[02]);
   assign exp_out[03] = exp_in[02] ^ (exp_in[06] & poly_in[03]);
   assign exp_out[04] = exp_in[03] ^ (exp_in[06] & poly_in[04]);
   assign exp_out[05] = exp_in[04] ^ (exp_in[06] & poly_in[05]);
   assign exp_out[06] = exp_in[05] ^ (exp_in[06] & poly_in[06]);
endmodule
`endif // WITH_TYPE2

`endif

