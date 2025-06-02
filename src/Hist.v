//Histogram algorithm: Calculate the Base line, pulse height, and duty cycle of the toroid pulse signal.

// Original algorithm by Shengli Liu, Feb.6,2020
//Description: histogram the pulse signal to decide the base line, and Duty Cycle. 
//1. Decide the threshold value = Min + (Max- min)/2;
//2. Base Line = max value of histrogram[0~threhold];
//3. Plateau = max value of historgram[threshold ~ histsize];
 
// clk is SCLK=35 MHz, data rate is 1.15275MHz, so the 1126Hz pulse has 1024 samples.
// May05,2023: Reduce depth of ram16_4096 to 32768, to cut M10K usage. Should not affect performance.
// since this only reduce the resolution of histogarm to 32768 bin. 

// modified by HJ to also return the signal pulse height, using a similar calculation as the BL.
// Increased buffer size to 16k to accomodate 100 Hz pulse.
// Number of averages limited by latency. For a 100 Hz pulse with 32 avgs, there is 320 ms latency.

`timescale 1ns / 1ps
module Hist(
	input clk, // SCLK 35 MHz
	input signed [15:0] signal,
	input in_valid, //signal valid, data rate is about 1.15275 MHz
	input pulse_start,  //ISIS pulse, not used.
	input [7:0] AVG_TIMES, //histogram averaging times: 4,8,16,32,..255
   input [7:0] DC_Index,
	input [13:0] pulse_len, // length of input pulse. must be < buffer length 
	
	output  signed [15:0] BL, // baseline, in ADC count
	output  signed [15:0] pulse_height, // peak-peak in ADC count
	output [31:0] fpDC100,
	
	output reg hist_valid,
   output reg [15:0] hist_signal,
	
	output overflow
);
	
	parameter DATA_WIDTH = 16;
	parameter SF_WIDTH = 32;
	
	parameter HIST_SIZE = 65536/2; //65536, SL, May 05,2023
	parameter BUFF_ADDR_WIDTH = 14; // changed from 10 - hj
	parameter HIST_DATA_WIDTH = 16;
	parameter HIST_ADDR_WIDTH = 15; 
	
	parameter FP100 = 32'h42c80000; 
   
//convert signal value (-32768 ~ 32767) to (0 ~ 65535): signal + 32768
	wire [HIST_DATA_WIDTH-1:0] signal_12/*synthesis keep*/;
   wire sign = signal[DATA_WIDTH-1];
	assign signal_12 = {~sign,signal[DATA_WIDTH-2:0]}; // i.e. + 0x8000,
	
	reg [BUFF_ADDR_WIDTH:0] buf_addr;
	reg [HIST_ADDR_WIDTH:0] addr; 
	wire [DATA_WIDTH-1:0] scaled_signal_16/*synthesis keep*/;
	wire [HIST_DATA_WIDTH-1:0] scaled_signal/*synthesis keep*/;


  assign scaled_signal = {1'b0,scaled_signal_16[HIST_DATA_WIDTH-1:1]}; //divided by 2.
//changed from below on May05,2023,SL	
//assign scaled_signal = scaled_signal_16[HIST_DATA_WIDTH-1:0];
	
	reg buf_rd_en /*synthesis keep*/;
	wire buf_wr_en /*synthesis keep*/;
	
	//changed to 16384 - Sept 4
	ram16_1024 buffer_inst (
	.address(buf_addr[BUFF_ADDR_WIDTH-1:0]), //10 bit address width
	.clock(clk),
	.data({signal_12}), //16 bit data width
	.rden(buf_rd_en),
	.wren(buf_wr_en),
	.q(scaled_signal_16) // 16 bit output
	);
	
   reg rd_en, wr_en/*synthesis keep*/;
	reg [DATA_WIDTH-1:0] hist_data_in/*synthesis keep*/; 
	wire [DATA_WIDTH-1:0] hist_data_out/*synthesis keep*/; 
	
	reg [7:0] avg_cnt; //max = 256, number of pulses to histogram.
	
	ram16_4096 hist_ram_inst ( //Depth changed to 32K, to cut M10K usage by half, otherwise M10K run out. SL,May05,2023
	.address(addr), //16 bit address width
	.clock(clk),
	.data(hist_data_in), //16 bit data width
	.rden(rd_en),
	.wren(wr_en),
	.q(hist_data_out) // 16 bit
	);   
	
	parameter state_idle = 0,
             state_buf = 1,
				 state_acc0 = 2,
				 state_acc1 = 3,
             state_acc2 = 4,
				 state_acc3 = 5,
				 state_acc4 = 6,
				 state_acc5 = 7,
				 state_acc6 = 8,
				 state_loop = 9,
				 state_rdy0 = 10,
				 state_rdy1 = 11,
				 state_rdy2 = 12,
				 state_rdy3 = 13,
				 state_clr0 = 14,
				 state_clr1 = 15;	 
					
	reg [3:0] state/*synthesis keep*/;
	assign buf_wr_en = in_valid;
	
always @ (posedge clk )
begin
	case(state)
		
		state_idle:	if (in_valid) begin buf_addr <= buf_addr + 1; state <= state_buf; end
		// write buffer of samples while in_valid is high
		state_buf: begin 
						 	if (in_valid)  buf_addr <= buf_addr + 1;
					      else 	begin buf_addr <= 0; state <= state_acc0; end
					  end		
		// start reading from buffer, until buf_addr == pulse_len
		state_acc0:	begin
						  wr_en <= 0;
						  if (buf_addr < pulse_len) //~buf_addr[BUFF_ADDR_WIDTH] - HJ sept 3
								    begin buf_rd_en <= 1; state <= state_acc1;  end
						  else  begin buf_addr <= 0; state <= state_loop; end
						end 			
		state_acc1: begin buf_rd_en <= 0; state <= state_acc2; end
		state_acc2: begin state <= state_acc3; end
		state_acc3: begin 	
							addr <= scaled_signal; rd_en <= 1;
							buf_addr <= buf_addr + 1;
							state <= state_acc4; 
						end
		state_acc4: begin rd_en <= 0; state <= state_acc5; end
		state_acc5: begin state <= state_acc6; end
		state_acc6: begin 
							hist_data_in <= hist_data_out + 1;
							wr_en <= 1;
							state <= state_acc0; 
						end
						
		//////////////////////////////////////////////////////	
		
		state_loop:	begin
						  if (avg_cnt < AVG_TIMES-1) 
								    begin avg_cnt <= avg_cnt + 1; 
											 state <= state_idle; 
									 end
						  else  begin avg_cnt <= 0; state <= state_rdy0; end
						end 	
		
		state_rdy0: begin rd_en <= 1; addr <= 0; state <= state_rdy1; end
		state_rdy1: begin addr <= 1;state <= state_rdy2; end
		state_rdy2: begin addr <= 2; state <= state_rdy3; end
		state_rdy3: begin 
							if (addr[HIST_ADDR_WIDTH])  begin rd_en <= 0; hist_valid <= 0; state <= state_clr0; end
							else begin hist_valid <= 1; hist_signal <= hist_data_out; addr <= addr + 1; end
	   	         end
		
		state_clr0: begin hist_data_in <= 0; addr <= 0; wr_en <= 1; state <= state_clr1; end
	   state_clr1: begin 
		               if (addr[HIST_ADDR_WIDTH])  begin wr_en <= 0;  state <= state_idle; end
							else addr <= addr + 1; 
	   	         end

		default: state <= state_idle;
	endcase
	
end //end always


//find out the first peak, ie. BL
reg [1:0] Tstate, Pstate, Dstate;
reg [HIST_DATA_WIDTH-1:0] xcnt,ycnt,zcnt,Min,Max/*synthesis keep*/;
wire [HIST_DATA_WIDTH-1:0] Range = Max - Min;
wire [HIST_DATA_WIDTH-1:0] Threshold = Min + {1'b0,Range[HIST_DATA_WIDTH-1:1]}/*synthesis keep*/;
reg [HIST_DATA_WIDTH-1:0] TH/*synthesis keep*/;
reg [HIST_DATA_WIDTH-1:0] peak_bin,peaking_bin/*synthesis keep*/;
reg [DATA_WIDTH-1:0] peak/*synthesis keep*/; 
wire [DATA_WIDTH-1:0] BL_scaled/*synthesis keep*/;

// assign BL_scaled = {~peak_bin[HIST_DATA_WIDTH-3],peak_bin[HIST_DATA_WIDTH-4:0],2'b0}; // mulitply 4 minus 2^15. HJ
assign BL_scaled = {~peak_bin[HIST_DATA_WIDTH-2],peak_bin[HIST_DATA_WIDTH-3:0],1'b0}; //Multiply 2 and then minus 0x8000, May08,2023
assign BL = BL_scaled;

//this process finds out threshold: which is the mid-value of the max and min bin that are greater than 0;
always @ (posedge clk ) 
begin
	case(Tstate)
		0:	if (hist_valid) Tstate <= 1;
			else xcnt <= 1;	
		1:if (hist_valid) // get the first non-zero value in the histogram.
				begin 
					xcnt <= xcnt + 1; 
					if (|hist_signal) begin Min <= xcnt; Tstate <= 2; end
				end	
		2:	if (hist_valid) // get the last non-zero value in the histogram.
				begin  
					xcnt <= xcnt + 1; 
					if (|hist_signal) begin Max <= xcnt; end
				end
			else begin TH <= Threshold; Tstate <= 0; end
		
		default: Tstate <= 0;
	endcase
end //end always

//this process finds out BL peak
// find the largest bin that is still below TH ((Max + Min)/2).
always @ (posedge clk ) 
begin
	case(Pstate)
		0:	if (hist_valid) 
				begin 
					ycnt <= ycnt + 1; 
					peak <= 0; 
					Pstate <= 1; 
				end
			else ycnt <= 0;	
		1:	if (hist_valid) 
				begin  
					if (ycnt < TH)
					   begin 
						  ycnt <= ycnt + 1; 
					     if (hist_signal > peak) begin peak <= hist_signal; peaking_bin <= ycnt; end
						end
					else begin 
							 // above 95% DC, just use the minimum value. not enough samples
							 if ( DC_Index > 8) peak_bin <= Min; // was Min
							 else peak_bin <= peaking_bin; 
							 Pstate <= 2;
							end
				end
			else Pstate <= 0;
		2: if (~hist_valid) Pstate <= 0;
		
		default: Pstate <= 0;
	endcase
end //end always


reg [HIST_DATA_WIDTH-1:0] max_cnt;
reg [DATA_WIDTH-1:0] peak_max;
reg [2:0] state_max;
reg [HIST_DATA_WIDTH-1:0] peak_bin_max,peaking_bin_max/*synthesis keep*/;

wire signed [15:0] TOP = {~peak_bin_max[HIST_DATA_WIDTH-2],peak_bin_max[HIST_DATA_WIDTH-3:0],1'b0}; //Multiply 2 and then minus 0x8000
lpm_addsub lpm_sub1 ( .add_sub(1'b0), .dataa(TOP), .datab(BL), .result(pulse_height));

//this process finds out larger peak
// find the largest bin that is above TH ((Max + Min)/2).
always @ (posedge clk ) 
begin
	case(state_max)
		0:	if (hist_valid) 
				begin 
					max_cnt <= max_cnt + 1; 
					peak_max <= 0; 
					state_max <= 1; 
				end
			else max_cnt <= 0;	
			
		1:	if (hist_valid) begin  
					if (max_cnt <= TH) begin 
						max_cnt <= max_cnt + 1;
					end					
					else begin
						state_max <= 2;
					end
			end
			else state_max <= 0;
			
		2:	if (hist_valid) 
				begin  
					 if (max_cnt > TH)
					   begin 
						  max_cnt <= max_cnt + 1; 
					     if (hist_signal > peak_max) begin peak_max <= hist_signal; peaking_bin_max <= max_cnt; end
						end
				end
			else begin
				state_max <= 0;
				peak_bin_max <= peaking_bin_max;
			end
		
		default: state_max <= 0;
	endcase
end //end always

//this process calcutes the duty cycle: counts the total occupancy and BL occupancy

reg [31:0] BL_op,Tot_op; //occupancy, max = 28 bit = 12 + 16 
reg [31:0] DC_denom,DC_num;
wire [SF_WIDTH-1:0] fpDC,fpDC_denom,fpDC_num,fpDC_rev;
parameter FP1 = 32'h3f800000; //1 in FP format

altfp_int2fp int2fpconv_inst1 (.dataa(DC_denom), .clock(clk), .result(fpDC_denom)); 
altfp_int2fp int2fpconv_inst2 (.dataa(DC_num), .clock(clk), .result(fpDC_num)); 
altfp_div3232 div_inst1 (.dataa(fpDC_num),. datab(fpDC_denom), .clock(clk), .result(fpDC_rev)); 
altfp_sub sub_inst1 (.dataa(FP1), .datab(fpDC_rev), .clock(clk), .result(fpDC) ); 
altfp_mul mul_inst2 (.dataa(fpDC), .datab(FP100), .clock(clk), .result(fpDC100) ); 

always @ (posedge clk ) 
begin
	case(Dstate)
		0:	if (hist_valid) 
				begin 
					zcnt <= zcnt + 1; 
					BL_op <= 0; Tot_op <= 0; 
					Dstate <= 1; 
				end
			else zcnt <= 0;	
		1:	if (hist_valid) 
				begin  
					if (zcnt < TH)
					   begin 
						  zcnt <= zcnt + 1; 
					     BL_op <= BL_op + hist_signal; 
						  Tot_op <= Tot_op + hist_signal; 
						end
					else Tot_op <= Tot_op + hist_signal; 
				end
			else begin DC_denom <= Tot_op; DC_num <= BL_op; Dstate <= 0; end
	
		default: Dstate <= 0;
	endcase
end //end always

	initial begin
	hist_valid = 0;
	hist_signal = 0;
	buf_addr = 0;
	addr = 0;
	buf_rd_en = 0;
	rd_en = 0;
	wr_en = 0;
	hist_data_in = 0;
	avg_cnt = 0;
	state = 0;
	Tstate = 0;
	Pstate = 0;
	Dstate = 0;
	xcnt = 0;
	ycnt = 0;
	zcnt = 0;
	Min = 0;
	Max = 0;
	TH = 0;
	peak_bin = 0;
	peaking_bin = 0;
	peak = 0;
	max_cnt = 0;
	peak_max = 0;
	state_max = 0;
	peak_bin_max =0;
	peaking_bin_max = 0;
	end
	
endmodule

