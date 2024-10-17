`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: shaping ISIS pulse to be 1 clk wide
//////////////////////////////////////////////////////////////////////
module pulse_shaping (
	 input clk,
	 input in_pulse,
	 output reg out_pulse
	 );

	
  				
reg in_pulse_0, in_pulse_1, in_pulse_2, in_pulse_3;
reg [1:0] state; 

always @ (posedge clk )  //prevent meta-stabilty
  begin 
     in_pulse_0 <= in_pulse; 
	  in_pulse_1 <= in_pulse_0; 
	  in_pulse_2 <= in_pulse_1;
	  in_pulse_3 <= in_pulse_2; 
  end

always @ (posedge clk ) 
	begin 
		case (state)
				0:	begin if (in_pulse_3 & ~out_pulse) begin out_pulse <= 1; state <= 1; end	 end	
		      1:	begin out_pulse <= 0; state <= 2; end
				2: begin if (~in_pulse_3) state <= 0; end       
				default: state <= 0;
		endcase
	end	
	
endmodule	