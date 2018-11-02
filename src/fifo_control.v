`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  TRIUMF
// Engineer: Shengli Liu
// Modified from awake bpm module: BLR_gain
// Nov.1,2018
// 
///////////////////////////////////////////////////////////////////////////////////
module fifo_control(
   RUN,
   rst,
	clk,

	fifo_full,
	fifo_empty,
	
	data_valid,    //data is valid, from ADC
	wr,
	
	busy          //to prevent the Fast fifo to be readout by MB
	

    );

parameter  	ADC_BIT_WIDTH = 16;
parameter  	DATA_WIDTH = 16;

 input rst;
 input clk;
 input RUN;
 
 input fifo_full,fifo_empty;
  
 input data_valid;
  
 output reg wr;

 output reg busy;
 

parameter  state_idle = 0; //
parameter  state_load = 1; //
parameter  state_load_end = 2; //

reg [2:0] state;

wire [4*ADC_BIT_WIDTH-1:0] dout_BLR; 


always @ (posedge clk) 
begin
	if (rst) 
		begin
			state <= state_idle;
			
			wr <= 0;
			busy <= 0;
						
		end
	else 
		case (state)
				state_idle:									
					begin  
						if(fifo_empty && RUN)	
						  begin 
						    busy <= 1;							 
							 state <= state_load; 
						  end				
					end
				state_load:  
					begin          					  
					  if (data_valid && ~fifo_full) wr <= 1;  
					  else wr <= 0;
					  if (fifo_full) state <= state_load_end; 		
		         end
				state_load_end:
					begin  
                 	  wr <= 0;
            		  busy <= 0;
					     state <= state_idle;
					  end	  
				   
	
				default:
				  state <= state_idle;
		
		endcase
		
end //end always


endmodule
	