/*
 * SPI Interface for AD4001,AD4009 modified from ADS8689.v 
 * ADC operating mode: /Cs mode, 3 wire, without busy, so far the turbo mode is not working.
 * data rate : max 1.5 MSPS  implemented so far
 * Analog input range: +/-2.5 V
 * Shengli Liu, June 4,2019
 * 
 */
module AD4001
    (
        // Signals to/from adc
        input                           miso,   // SPI data from ADC
        output reg                      mosi,   // SPI data to ADC
        output reg                      sclk,   // SPI_CLK to ADC, 70 MHz
                                                        
        output                          ss,     // triggers ADC conversion 
                                                       

        // Signals to/from system
        input                           clk,    // A 140 MHz clock for driving                                                     
        input                           rst,    // System Reset
        input                           run, // only run ADC when set to 1
		  input 									 start_init, //pulse, system command from initialize code
		  input 									 start_read, //pulse, system command from initialize code
        output reg [7:0] conf_reg, //ADC config reg
		  output reg [15:0]    DOUT,       // Data output
        output reg           DRDY        // Data ready signal
    );

    parameter   state_idle = 0, 
	             state_cnv = 1,
					 state_wait1 = 2,
					 state_wait2 =3, 
                state_sclk_rise = 4, 
                state_sclk_fall = 5, 
                state_end = 6,
					 state_clr = 7,
					 state_init0 = 8,
					 state_init1 = 9,
					 state_init2 = 10,
					 state_init3 = 11,
					 state_rd0 = 12,
					 state_rd1 = 13,
					 state_rd2 = 14,
					 state_rd3 = 15;
					 
	// ADC sampling freq 1.15275MHz (T=0.86749 us) is selected as to be Cyclotron RF 23.055MHz divided by 5*2^2;
   // The ISIS pulser freq = 23.055 MHz divided by 5*2^12 = 1126 Hz.	
	// So 1024 samples = 888.3 us, i.e one period. 
	// This selection is critical for using comb filter which centers at harmonics of 1126 Hz.
	
	//note: The actual RF is slowly drifting between 23.06~23.07 Mhz, with spikes p-p 0.04 MHz, according to XTpage 02.
	
	 parameter ADC_FREQ = 1152.75; //KHz, 500, 1000, 
    parameter CLK_FREQ = 140000; //KHz, 140MHZ 
	 parameter VALID_CYCLE = 4; //Width of DRDY pulse
    
	 //parameter DIV = CLK_FREQ/ADC_FREQ = 121.4487,
	 parameter DIV = 121; // due to the cut-off 0.4487, the actual ADC freq. = 1.15702 MHz
	 parameter TCONV = 46; //328 ns for Tconv requiment
	 parameter CNV_WIDE = 29; //this is about 193+14 ns due to Tquiet1 = 190 ns, Ten=10 ns 
	 
    parameter CONF_BIT = 16'H1403; //Turbo mode bit set to 1
	 parameter READ_BIT = 16'H54FF; //READ Command
	 
	 reg [4:0] state; /*synthesis keep*/
    reg [7:0] cnt;
    reg [9:0] timer_cnt;  
    reg [15:0] sr,sr_rd; 
	 reg conv;  /*synthesis keep*/

	 
	 assign ss = conv;
    
        
    reg start_conv;
    reg init_done;
	 
always @ (posedge clk)  
begin 
		if (timer_cnt >= DIV) begin timer_cnt <= 0; start_conv <= 1; end
		else begin start_conv <= 0; timer_cnt <= timer_cnt + 1; end
end   
////////////////////////////////////////////////////////////////////////////
always @ (posedge clk) 
begin
	if (rst) 
		begin
			state <= state_idle;
			cnt <= 0;
			DRDY <= 0;
			sclk <= 0;
			conv <= 0; mosi <= 1;
			init_done <= 0;
						
		end
	else 
		case (state)
				state_idle:									
					begin 
						if (start_conv & run)	
						  begin 
						    cnt <= 0;	state <= state_cnv; 
						  end	
						if (start_init)
						  begin 
						    conv <= 1;	 cnt <= 0;	sr <= CONF_BIT; state <= state_init0; 
						  end
						if (start_read) 
						  begin 
						    conv <= 1;	 cnt <= 0;	sr <= READ_BIT; state <= state_rd0; 
						  end  
						else begin conv <= 0; mosi <= 1; sclk <= 0; end  			
					end
///////////////////////////////////////////////////////////////////
				state_cnv:  
				   begin 
					  conv <= 1;					
					  if (cnt >= TCONV) begin cnt <= 0; conv <= 0; state <= state_wait1; end
					  else cnt <= cnt + 1;  	
		         end 
				state_wait1:  state <= state_wait2; 
				state_wait2:  state <= state_sclk_rise; 
				state_sclk_rise:  
					begin          					  
					  sclk <= 1;
					  sr <= {sr[14:0],miso};	
					  state <= state_sclk_fall; 	
		         end
		      state_sclk_fall:  
					begin          					  
					  sclk <= 0; 
					  //sr <= {sr[14:0],miso};	
					  if (cnt >= 15) state <= state_end;
					  else begin cnt <= cnt + 1; state <= state_sclk_rise; end 	
		         end    
				state_end:
					begin  
	              DOUT <= sr;
            	  DRDY <= 1; 
					  cnt <= 0;
					  state <= state_clr;
					end	  
				state_clr:
					begin  
					  if (cnt >= VALID_CYCLE-1) begin  DRDY <= 0; state <= state_idle; end
					  else cnt <= cnt + 1;
					 
					end	     
	////////////////////////////////////////////////////////////////////////////
				state_init0:
					begin          					  
					  conv <= 1;	
					  if (cnt >= CNV_WIDE) begin cnt <= 0; conv <= 0; mosi <= sr[15]; state <= state_init1; end
					  else cnt <= cnt + 1;  	
		         end 
	
				state_init1: 
					begin  
                 				
					  sclk <= 1;
					  sr <= {sr[14:0],1'b0};	
					  state <= state_init2; 	
		         end
		      state_init2:  
					begin          					  
					  sclk <= 0; mosi <= sr[15];
					  if (cnt >= 15) state <= state_init3; 
					  else begin cnt <= cnt + 1; state <= state_init1; end 	
		         end    
				state_init3:  
				   begin init_done <= 1; mosi <= 1; state <= state_idle; end
				
////////////////////////////////////////////////////////				
				state_rd0:
					begin          					  
					  conv <= 1;	
					  if (cnt >= CNV_WIDE) begin cnt <= 0; conv <= 0; mosi <= sr[15]; state <= state_rd1; end
					  else cnt <= cnt + 1;  	
		         end 
	
				state_rd1: 
					begin  
                					
					  sclk <= 1;
					  sr <= {sr[14:0],1'b0};	
					  state <= state_rd2; 	
		         end
		      state_rd2:  
					begin          					  
					  sclk <= 0; mosi <= sr[15]; sr_rd <= {sr_rd[14:0],miso};
					  if (cnt >= 15) state <= state_rd3; 
					  else begin cnt <= cnt + 1; state <= state_rd1; end 	
		         end    
				state_rd3:  
				   begin mosi <= 1; conf_reg <= sr_rd[7:0]; state <= state_idle; end	
					
				default:
				  state <= state_idle;
		
		endcase
		
end //end always

    

endmodule // adc_interface
