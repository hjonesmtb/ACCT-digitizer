`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// find the minimum value from the input signal

//////////////////////////////////////////////////////////////////////////////////
module bottom(

	input clk, // SCLK 35 MHz
	input signed [ADC_BIT_WIDTH-1:0] signal,
	input in_valid, // valid for the one period of the input signal
	output reg signed [ADC_BIT_WIDTH-1:0] min
    );

parameter ADC_BIT_WIDTH = 16;
reg signed [ADC_BIT_WIDTH-1:0] min_reg;
 
reg [1:0] state;
always @ (posedge clk )	
begin
   case(state)
		0: if (in_valid) begin min_reg <= signal; state <= 1; end 
		1: if (in_valid) begin if (min_reg > signal) min_reg <= signal; end 
		  	else  begin min <= min_reg; state <= 0; end 
		default: state <= 0;
	endcase
end	


endmodule
