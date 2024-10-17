`timescale 1ns / 1ps
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// gating the data according to signal "pass", if finally passed, give "found" signal for 1 clk period.
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on July 11,2019
// last modified: 
// 
/////////////////////////////////////////////////////////////////////
module data_gate (
	 input clk,
    input in_valid,   
    input pass,
	 input [15:0] data, 
	 output reg step,
	 output reg found, //valid if this data is the minimum one
	 output reg sign_step
	 );

	//parameter  DATA_WIDTH = 8;
   parameter   state_0 = 0, 
	            state_1 = 1,
					state_2 = 2,
					state_3 =3, 
               state_4 = 4, 
               state_5 = 5, 
               state_6 = 6,
					state_7 = 7,
					state_8 = 8,
					state_9 = 9,
					state_10 = 10,
					state_11 = 11,
					state_12 = 12,
					state_13 = 13,
					state_14 = 14,
					state_15 = 15,
					state_16 = 16,
					state_17 = 17;
					 	 
	
reg [4:0] state; /*synthesis keep*/

//note: step <= 1 kills this data!
	
always @(posedge clk)  
begin
		case (state)
				state_0:	begin found <= 0; if (in_valid) state <= state_1; end		
				
				state_1:	begin step <= data[15]; sign_step <= 1; state <= state_2;  end 					
				
				state_2:	if (pass) begin step <= data[14];sign_step <= 0;state <= state_3; end
							else begin step <= 1; sign_step <= 0; state <= state_0; end
							
				state_3:		if (pass) begin step <= data[13];state <= state_4; end else begin step <= 1; state <= state_0; end
				state_4:		if (pass) begin step <= data[12];state <= state_5; end else begin step <= 1; state <= state_0; end
				state_5:		if (pass) begin step <= data[11];state <= state_6; end else begin step <= 1; state <= state_0; end	
				state_6:		if (pass) begin step <= data[10];state <= state_7; end else begin step <= 1; state <= state_0; end
				state_7:		if (pass) begin step <= data[9]; state <= state_8;  end else begin step <= 1; state <= state_0; end	
				state_8:		if (pass) begin step <= data[8]; state <= state_9;  end else begin step <= 1; state <= state_0; end	
				state_9:		if (pass) begin step <= data[7]; state <= state_10; end else begin step <= 1; state <= state_0; end	
				state_10:	if (pass) begin step <= data[6]; state <= state_11; end else begin step <= 1; state <= state_0; end	
				state_11:	if (pass) begin step <= data[5]; state <= state_12; end else begin step <= 1; state <= state_0; end	
				state_12:	if (pass) begin step <= data[4]; state <= state_13; end else begin step <= 1; state <= state_0; end	
				state_13:	if (pass) begin step <= data[3]; state <= state_14; end else begin step <= 1; state <= state_0; end	
				state_14:	if (pass) begin step <= data[2]; state <= state_15; end else begin step <= 1; state <= state_0; end	
				state_15:	if (pass) begin step <= data[1]; state <= state_16; end else begin step <= 1; state <= state_0; end	
				state_16:	if (pass) begin step <= data[0] ;state <= state_17; end else begin step <= 1; state <= state_0; end	
				
				state_17:	if (pass) begin found <= 1; step <= 1; state <= state_0; end 
							   else begin  step <= 1; state <= state_0; end
								
				default: state <= state_0;
		endcase
		
end //end always	


 
 
 
endmodule