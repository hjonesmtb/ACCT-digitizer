/*
 * Calibration  interface, create 1126 Hz pulse, amplitude and duty cycle variable
 * data rate : 1 MHz
 * Shengli Liu, June 17,2019
 * 
 */
module DAC_control
    (
        // Signals to DAC 
        output   sdi,   // SPI data to DAC
        output   sclk,   // SPI_CLK to DAC, less than 50 MHz                                                     
        output   ss,     // start 
                                                       
        // Signals to/from system
		  input 	 Enable,
		  input [7:0] Dcycle, //duty cycle: 0 ~ 100%, 
		  input [7:0] Amplitude, //0 ~ 100%  
        input   clk,  //50MHz system clock                                                      
        input   rst
        
		  
    );

    parameter   state_idle = 0, 
	             state_pulse_on1 = 1,
					 state_pulse_on2 = 2,
					 state_pulse_off = 3;
					 
					 
	 parameter DAC_WIDTH = 16;  				 
	 parameter DAC_FREQ = 1; //1MSPS, 
    parameter CLK_FREQ = 50; //50MHZ 
    parameter DIV = CLK_FREQ/DAC_FREQ; 
	 parameter PERIOD = 16'd44405; //=50MHz/1126 Hz 
	 //parameter PERIOD = 31'd444050; //=50MHz/1126 Hz 
    //parameter HALF = 31'd222025; //=50MHz/1126 Hz 
	 reg [1:0] state; /*synthesis keep*/

    reg [15:0] cnt; /*synthesis keep*/
	 reg [15:0] timer_cnt;
		 
	 reg [DAC_WIDTH-1:0] DAC_code;  /*synthesis keep*/
       
    reg  start_pulse; /*synthesis keep*/
	 reg  DAC_update;  /*synthesis keep*/
	 
	 wire [15:0] high_level, low_level; 
	 wire unsigned [31:0] on_time;

	 
always @ (posedge clk)  
begin 
		if (timer_cnt >= PERIOD) begin timer_cnt <= 0; start_pulse <= 1; end
		else begin start_pulse <= 0; timer_cnt <= timer_cnt + 1; end
end   
////////////////////////////////////////////////////////////////////////////
always @ (posedge clk) 
begin
	if (rst) 
		begin
			state <= state_idle;
			cnt <= 0;
		end
	else 
		case (state)
				state_idle:									
					begin 
						if (start_pulse && (|Dcycle) && Enable)	//duty cycle != 0
						   begin  
							   cnt <= 0; 
								DAC_code <= high_level; 
								DAC_update <= 1; 
								state <= state_pulse_on1; 
							end 		
					end
				state_pulse_on1: begin DAC_update <= 0; state <= state_pulse_on2; end
				state_pulse_on2:  
				   begin 			  
					  if (cnt >= on_time[15:0]) begin DAC_code <= low_level; DAC_update <= 1; state <= state_pulse_off; end
					  else cnt <= cnt + 1; 	
		         end 

				state_pulse_off: begin DAC_update <= 0; state <= state_idle; end
				
				default:
				  state <= state_idle;
		
		endcase
		
end //end always


DAC DAC_Cal_inst
    ( 
	   .sdi(sdi),   // SPI data to DAC
      .sclk(sclk),   // SPI_CLK to DAC, less than 50 MHz                                                     
      .ss(ss),     // start 
		
 		.code(DAC_code), // code = 0 ~ FSR, i.g. 0 ~ 65535
      .clk(clk),                                                         
      .rst(rst),
		.update(DAC_update)
	
	 );
 
wire unsigned [31:0] mul_p1;  
lpm_mul	mul_const1 (
		.dataa(PERIOD), //16 bit
		.datab(Dcycle),  //16 bit
		.result(mul_p1)  //32 bit
		);	

lpm_div div_const1(
	.denom(16'd100), //16 bit
	.numer(mul_p1),  //32 bit
	.quotient(on_time), //32 bit
	.remain());        //16 bit

wire unsigned [31:0] mul_p2,amp;  

//make offset = 0
assign high_level = {1'b1,amp[15:1]};
assign low_level = {1'b0,amp[15:1]};

lpm_mul	mul_const2 (
		.dataa(16'd65535), //16 bit
		.datab(Amplitude),  //16 bit
		.result(mul_p2)  //32 bit
		);	

lpm_div div_const2(
	.denom(16'd100), //16 bit
	.numer(mul_p2),  //32 bit
	.quotient(amp), //32 bit
	.remain());        //16 bit	
	
endmodule // 
