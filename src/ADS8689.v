/*
 * Simplified SPI Interface for the ADS8689 whose default settings are good for this use case
 * Analog input range: +/-12.288 V
 * no values are written to ADC. 
 * Only shifts out 16 bit ADC conversion result.
 * Shengli Liu, Nov.1,2018
 */
module ADS8689
    (
        // Signals to/from adc
        input                           miso,   // SPI data from ADC
        output                          mosi,   // SPI data to ADC
        output reg                      sclk,   // SPI_CLK to ADC 
                                                        
        output reg                      ss,     // ADC Slave Select. Also triggers ADC conversion 
                                                       

        // Signals to/from system
        input                           clk,    // A 10 MHz clock for driving                                                     
        input                           rst,    // System Reset
    
        output reg [15:0]    DOUT,       // Data output
        output reg                         DRDY        // Data ready signal
    );

    parameter   state_idle      = 0, 
                state_sclk_rise = 1, 
                state_sclk_fall = 2, 
                state_end       = 3,
					 state_clr = 4;

    reg [4:0] state;
    reg [4:0] cnt;
    reg [9:0] timer_cnt;  
    reg [15:0] sr; 
    
    parameter ADC_PERIOD = 10000; //10KHz, Max 100 KHz for  ADS8689
    parameter CLK_FREQ = 10000000; //10MHZ, Max 66 MHz for  ADS8689
    parameter TARGET = CLK_FREQ/ADC_PERIOD; //1000 counts
    
    reg start_conv;
    assign mosi = 0;
     
always @ (posedge clk)  
 // if (timer_cnt >= TARGET) begin timer_cnt <= 0; start_conv <= 1; end
 // else begin start_conv <= 0; timer_cnt <= timer_cnt + 1; end
  begin 
     timer_cnt <= timer_cnt + 1;
     start_conv <= &timer_cnt;
  end	  
  
always @ (posedge clk) 
begin
	if (rst) 
		begin
			state <= state_idle;
			cnt <= 0;
			DRDY <= 0;
			sclk <= 0;
			ss <= 1;
						
		end
	else 
		case (state)
				state_idle:									
					begin 
						if(start_conv)	
						  begin 
						    ss <= 0;							 
							 state <= state_sclk_rise; 
						  end	
						else
						  begin
						   ss <= 1;
						   cnt <= 0;
						   sclk <= 0;
						  end  			
					end
				state_sclk_rise:  
					begin          					  
					  sclk <= 1;
					  sr <= {sr[14:0],miso};	
					  state <= state_sclk_fall; 	
		            end
		        state_sclk_fall:  
					begin          					  
					  sclk <= 0;
					  if (cnt >= 15) state <= state_end;
					  else begin cnt <= cnt + 1; state <= state_sclk_rise; end 	
		            end    
				state_end:
					begin  
					  ss <= 1;
                 DOUT <= sr;
            	  DRDY <= 1; 
            	  cnt <= 0;
					  state <= state_clr;
					end	  
				state_clr:
					begin  
					  DRDY <= 0; 
            	  state <= state_idle;
					end	     
	
				default:
				  state <= state_idle;
		
		endcase
		
end //end always

    

endmodule // adc_interface
