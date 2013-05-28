`timescale 1ns / 1ps

module lvmb_adc_sdo_mux(
  input int_lvmb_adc_en,
  input [6:0] int_lvmb_adc_sdo,
  input lvmb_adc_sdo,
  input [6:0] adc_ce,
  output reg sdo);

  
  always @(int_lvmb_adc_en or adc_ce or lvmb_adc_sdo or int_lvmb_adc_sdo)
	if (int_lvmb_adc_en == 1'b1) 
		begin
			case (adc_ce)
		    7'b1111110: sdo <= int_lvmb_adc_sdo[0];
		    7'b1111101: sdo <= int_lvmb_adc_sdo[1];
		    7'b1111011: sdo <= int_lvmb_adc_sdo[2];
		    7'b1110111: sdo <= int_lvmb_adc_sdo[3];
		    7'b1101111: sdo <= int_lvmb_adc_sdo[4];
		    7'b1011111: sdo <= int_lvmb_adc_sdo[5];
		    7'b0111111: sdo <= int_lvmb_adc_sdo[6];
		    default: sdo <= 1'b0;
			endcase
		end
	else if (int_lvmb_adc_en == 1'b0) 
		begin
			sdo <= lvmb_adc_sdo;
		end
  
  
endmodule
