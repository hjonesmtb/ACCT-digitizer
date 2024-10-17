//e-linac faraday cup signal pulse processing
//Shengli Liu, Sept.5,2017
//Description:
//Input: one channel, Negtive going square-shape signal pulse, rise/fall time 0.3us, varied duty cycle, sampling period 10ns; 
//Output: peak (uA), average(uA), pulse width(ns), duty cycle(percentage)


//Aug.20,2018:
//Adding overshoot time, when triggered, the processor starts to calculate the peak value after the overshoot;
//the method is 128 samples averaging.

//Feb.21,2019:
//Adding: accept external trig, and taking out the self-trigger part to a seperate module;
//Adding capability to deal with pulse frequency range from 250KHz to 1 Hz below which will be regarded as DC beam. 
//the minimum pulse width could be handled is around 4 ~ 6 us if overshoot set to be 256 (2.56 us).


//Sept.9,2019:
//modified for toroid processor, only work with self-trggier mode. and clk is SCLK=35 MHz, 
// and ADC sampling, i.e. data rate is 1.15275MHz

`timescale 1ns / 1ps
module pulse_processing(
	input signed [ADC_BIT_WIDTH-1:0] signal,
		
	input [ADC_BIT_WIDTH-1:0] threshold, //postive value, ADC bin number
	input in_valid,
	//input [DATA_WIDTH-1:0] overshoot,
	//input [DATA_WIDTH-1:0] gain_adj,
		
	input clk, // SCLK 35 MHz
   output signed [ADC_BIT_WIDTH-1:0] BL,
	output reg [LONG_WIDTH-1:0] AVG_reg,
	output reg [LONG_WIDTH-1:0] pw_reg, //in unit of 10 ns
	output reg [LONG_WIDTH-1:0] tw_reg, //in unit of 10 ns
	output overflow
);

// ADC sampling freq 1.15275MHz (T=0.86749 us), refer to "AD4001.v"

	parameter ADC_BIT_WIDTH = 16;
	parameter DATA_WIDTH = 16;
	parameter LONG_WIDTH = 32;

	
	//parameter AVG_TIMES = 128; //if changed, also need to change associated code, division
   parameter MAX_PERIOD = 2000000; //=1.7 s, in unit of 0.86749 us

	wire gate; 
	//wire signed [ADC_BIT_WIDTH-1:0] BL;
	
self_trigger self_trig_inst(
	.signal(signal), //postive going signal
	.threshold(threshold),
	.in_valid(in_valid),
	.clk(clk), //
	.BL(BL), 
	.gate(gate) //actually is the gate signal which indicates the pulse width
);

	
	
	
	wire signed [ADC_BIT_WIDTH-1:0] rec_signal = signal - BL/*synthesis keep*/;
	
	parameter state_idle = 0,
             state_update0 = 1,
				 state_update1 = 2,
				 state_pulse = 3,
             state_floor = 4;
				 
					
	reg [5:0] state;

	reg [LONG_WIDTH-1:0] pw,tw; //32 bit pulse width,floor width 
	reg [LONG_WIDTH-1:0] acc_reg,acc,avg_value; //32 bit accumulator, will not overflow for 1 ms pulse, 1024 times summing
	
		
	
	reg [7:0] cnt;
		
always @ (posedge clk )
begin
	case(state)
		state_idle:
		begin 
			if (gate & in_valid) begin state <= state_update0; end
			else //Otherwise calculate noise floor
			   begin 
					tw <= 0; cnt <= 0; acc <= 0;
					pw_reg <= 0;
					tw_reg <= 0;
				end	
		end	
		state_update0: 
		begin
		  tw <= 0;
		  acc <= 0;
		  if ( cnt > 10) begin 
		      AVG_reg <= avg_value;
				state <= state_update1;
			end 
		  else cnt <= cnt + 1;
		end 
		state_update1: 
		begin
		  tw <= tw + 1;
		  acc <= acc + {{16{rec_signal[ADC_BIT_WIDTH-1]}},rec_signal};
		  state <= state_pulse;
		end 		
	//start integrating immediatly		
		state_pulse:
		begin
			if (in_valid & gate) begin 
				tw <= tw + 1;
				acc <= acc + {{16{rec_signal[ADC_BIT_WIDTH-1]}},rec_signal};
			end 	
			if (in_valid & ~gate) begin 
				pw_reg <= tw; 
				tw <= tw + 1; 
				state <= state_floor; 
			end
		end
		
		state_floor: //wait for next pulse or time out if CW beam
		begin
			if (in_valid & ~gate) tw <= tw + 1;	
			if (in_valid & gate) begin 
			   //BL <= signal;
			   tw_reg <= tw;
				acc_reg <= acc;
				cnt <= 0;
			   state <= state_update0;
			end	
			if (tw > MAX_PERIOD) //no pulse time out
			   begin 
				  tw <= 0;
				  state <= state_idle;
				end  
		end					
		default: state <= state_idle;
	endcase
	
end //end always

//multiply acc_reg by 2**8 = 256, to increase the resolution 
lpm_3232div	lpm_3232div_inst (
	.denom ( tw_reg ), //unsigned number 32 bit
	.numer ( {acc_reg[23:0],8'b0} ), //signed number 32 bit
	.quotient ( avg_value ),
	.remain ( )
	);

endmodule
