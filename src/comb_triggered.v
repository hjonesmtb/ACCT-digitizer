`timescale 10ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: comb filter centred at 1126 Hz and its harmonics, using external 1126 sync signal.
// combfilter:  
// by: Holden Jones, Diagnostics, TRIUMF
// Histroy: Created on Feb 28 2024
// last modified: 
// Oct. 28, 2022: to multiply (1-alpha/1024), to make gain of comb filter to be 1.

module comb_triggered(
    input clk, // 35 MHz SCLK
    input in_valid,   // 1.15 MHz DRDY signal from ADC
    input rst,
    input [15:0] alpha, //gain factor = alpha/1024, range: 0 ~ 1023, for example, 922/1024 = 0.9004
	 	 
    input signed [15:0] data_in, //input data 
	
    output reg signed [15:0] data_out, //output data
 
	 output overflow //calculation overflow 

    );
 
parameter  DATA_WIDTH = 16;

wire signed [31:0] data_32,data_sum_32/*synthesis keep*/;
wire signed [DATA_WIDTH-1:0] fifo_out,data_sum,k/*synthesis keep*/;

wire overflow1,overflow2;
assign overflow = overflow1 | overflow2;

wire [9:0] fifo_wd/*synthesis keep*/;
reg fifo_rd,fifo_wr/*synthesis keep*/;
wire fifo_full/*synthesis keep*/;

initial begin
	fifo_rd = 0;
	fifo_wr = 0;
end

fifo1024	fifo1024_inst (
	.clock ( clk ),
	.data (data_sum),
	.rdreq ( fifo_rd ),
	.wrreq ( fifo_wr ),
	.full ( fifo_full ),
	.q ( fifo_out ),
	.usedw ( fifo_wd )
	);

lpm_mul mul_inst1 (
		.dataa(alpha), //16 bit, <= 1024, >= 0
		.datab(fifo_out),  //16 bit
		.result(data_32)  //32 bit
		);	

lpm_mul mul_inst2 (
		.dataa(data_sum), //16 bit,
		.datab(k),  //16 bit
		.result(data_sum_32)  //32 bit
		);	
wire signed [DATA_WIDTH-1:0] data_scaled = data_32[25:10]; //divided by 1024, and remove 6 MSB, will not overlfow.
wire signed [DATA_WIDTH-1:0] data_sum_scaled = data_sum_32[25:10]; //divided by 1024, and remove 6 MSB, will not overlfow, to keep gain =1 

lpm_addsub lpm_add_inst1 ( .add_sub(1'b1), .dataa(data_in), .datab(data_scaled), .result(data_sum), .overflow(overflow1));
lpm_addsub lpm_add_inst2 ( .add_sub(1'b0), .dataa(16'D1024), .datab(alpha), .result(k), .overflow(overflow2));
               
					 

reg [3:0] state/*synthesis keep*/;
parameter state_0 = 0, state_1 = 1, state_2 = 2, state_3 = 3, state_4 = 4,
          state_5 = 5, state_6 = 6, state_7 = 7, state_8 = 8, state_9 = 9,
          state_10 = 10, state_11 = 11;
					
	
always @(posedge clk) 
  case (state)
      state_0: begin 
						if (fifo_full && in_valid) state <= state_1;
						if (~fifo_full && in_valid) begin fifo_wr <= 1; state <= state_4; end
					end	
	
    	state_1: begin fifo_rd <= 1; state <= state_2; end	
	   state_2: begin fifo_rd <= 0; state <= state_3; end						
    	state_3: begin 
		           data_out <= data_sum_scaled;
		           if (~fifo_full)  begin fifo_wr <= 1; state <= state_4; end
					  else state <= state_0; 
					end  
		state_4:	begin fifo_wr <= 0; state <= state_0; end		  
					  
    	default: state <= state_0;
  endcase


endmodule

