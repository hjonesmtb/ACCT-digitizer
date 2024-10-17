/*
 * DAC8811 interface
 * data rate : 1 MHz
 * Shengli Liu, June 17,2019
 * 
 */
module DAC
    (
        // Signals to DAC 
        output reg                      sdi,   // SPI data to DAC
        output reg                      sclk,   // SPI_CLK to DAC, less than 50 MHz                                                     
        output reg                      ss,     // start 
                                                       
        // Signals to/from system
		  input 	[15:0]			 code, // code = 0 ~ FSR, i.g. 0 ~ 65535
        input                           clk,                                                         
        input                           rst,
		  input 									 update  //1 clk pulse
        
		  
    );

    parameter   state_idle = 0, 
	             state_cnv = 1,
					 state_sclk_rise = 2;
					 
					 
	 parameter DAC_WIDTH = 16;  				 
	 parameter DAC_FREQ = 1; //1MSPS, 
    parameter CLK_FREQ = 50; //50MHZ 
    parameter DIV = CLK_FREQ/DAC_FREQ; 

	 reg [1:0] state; /*synthesis keep*/
    reg [4:0] cnt;  /*synthesis keep*/
	 reg [7:0] timer_cnt;
    reg [DAC_WIDTH-1:0] sr;  
        
    reg start_conv; /*synthesis keep*/

/*	 
always @ (posedge clk)  
begin 
		if (timer_cnt >= DIV) begin timer_cnt <= 0; start_conv <= 1; end
		else begin start_conv <= 0; timer_cnt <= timer_cnt + 1; end
end
*/
   
////////////////////////////////////////////////////////////////////////////
always @ (posedge clk) 
begin
	if (rst) 
		begin
			state <= state_idle;
			cnt <= 0;
			sclk <= 0;
			ss <= 0; 
							
		end
	else 
		case (state)
				state_idle:									
					begin 
						if (update) //if (start_conv )	
						   begin  
							   ss <= 0;	sr <= code; cnt <= 0; state <= state_cnv; 
							end 
						else begin ss <= 1; sclk <= 0; end 
					
					end
///////////////////////////////////////////////////////////////////
				state_cnv:  
				   begin 			  
			        sclk <= 0;
					  sdi <= sr[DAC_WIDTH-1];
					  if (cnt >= DAC_WIDTH) begin ss <= 1; state <= state_idle; end
					  else begin cnt <= cnt + 1; state <= state_sclk_rise; end 	
		         end 
				state_sclk_rise:  
					begin          					  
					  sclk <= 1;
					  sr <= {sr[DAC_WIDTH-2:0],1'b0};
					  state <= state_cnv; 	
		         end
					
				default:
				  state <= state_idle;
		
		endcase
		
end //end always

    

endmodule // 
