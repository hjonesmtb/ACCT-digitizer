//Histogram algorithm: Calculate the Base line and plateua of the toroid pulse signal, 1126Hz, DC = 0.1 ~ 99.5%.
//Shengli Liu, Feb.6,2020
//Description: histogram the pulse signal to decide the base line, 
//1. Decide the threshold value = Min + (Max- min)/2;
//2. Base Line = max value of histrogram[0~threhold];
//3. Plateau = max value of historgram[threshold ~ histsize];
 
// clk is SCLK=35 MHz, data rate is 1.15275MHz, so the 1126Hz pulse has 1024 samples.

`timescale 1ns / 1ps
module Hist(
	input clk, // SCLK 35 MHz
	input signed [DATA_WIDTH-1:0] signal,
	input in_valid, //signal valid, data rate is about 1.15275 MHz
	input pulse_start,  //one clock pulse, i.e.   ISIS pulse
	input [7:0] AVG_TIMES, //histogram averaging times: 4,8,16,32,..255

	output  signed [DATA_WIDTH-1:0] BL, 
	output  signed [DATA_WIDTH-1:0] PL,
	output [SF_WIDTH-1:0] fpDC,
	
	output reg hist_valid,
   output reg [DATA_WIDTH-1:0] hist_signal,
	
	output overflow
);

	parameter DATA_WIDTH = 16;
	parameter SF_WIDTH = 32;
	
	parameter PULSE_SIZE = 1024;	
	parameter HIST_SIZE = 4096;
	parameter HIST_DATA_WIDTH = 12;
   
//convert signal value (-32768 ~ 32767) to (0 ~ 4095): (signal + 32768)/16
	wire [HIST_DATA_WIDTH-1:0] signal_12/*synthesis keep*/;
   wire sign = signal[DATA_WIDTH-1];
	assign signal_12 = {~sign,signal[DATA_WIDTH-2:4]}; // i.e. + 0x8000, then divided by 16;
	
	reg [HIST_DATA_WIDTH:0] buf_addr,addr; 
	wire [DATA_WIDTH-1:0] scaled_signal_16;
	wire [HIST_DATA_WIDTH-1:0] scaled_signal/*synthesis keep*/;
	assign scaled_signal = scaled_signal_16[HIST_DATA_WIDTH-1:0];
	
	reg buf_rd_en,buf_wr_en/*synthesis keep*/;

	ram16_1024 buffer_inst (
	.address(buf_addr[HIST_DATA_WIDTH-1:0]), //10 bit address width
	.clock(clk),
	.data({4'b0,signal_12}), //16 bit data width
	.rden(buf_rd_en),
	.wren(buf_wr_en),
	.q(scaled_signal_16) // 16 bit output
	);
	
   reg rd_en, wr_en/*synthesis keep*/;
	reg [DATA_WIDTH-1:0] hist_data_in/*synthesis keep*/; 
	wire [DATA_WIDTH-1:0] hist_data_out/*synthesis keep*/; 
	
	reg [7:0] avg_cnt; //max = 256, number of pulses to histogram.
	
	ram16_4096 hist_ram_inst (
	.address(addr[HIST_DATA_WIDTH-1:0]), //12 bit address width
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
		state_buf: begin 
						 	if (in_valid)  buf_addr <= buf_addr + 1;
					      else 	begin buf_addr <= 0; state <= state_acc0; end
					  end		
		state_acc0:	begin
						  wr_en <= 0;
						  if (~buf_addr[HIST_DATA_WIDTH]) 
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
							if (addr[HIST_DATA_WIDTH])  begin rd_en <= 0; hist_valid <= 0; state <= state_clr0; end
							else begin hist_valid <= 1; hist_signal <= hist_data_out; addr <= addr + 1; end
	   	         end
		
		state_clr0: begin hist_data_in <= 0; addr <= 0; wr_en <= 1; state <= state_clr1; end
	   state_clr1: begin 
		               if (addr[HIST_DATA_WIDTH])  begin wr_en <= 0;  state <= state_idle; end
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

assign BL_scaled = {~peak_bin[HIST_DATA_WIDTH-1],peak_bin[HIST_DATA_WIDTH-2:0],4'b0}; //multiply 16, then minus 0x8000
assign BL = BL_scaled;

//this process finds out threshold: which is the mid-value of the max and min bin that are greater than 0;
always @ (posedge clk ) 
begin
	case(Tstate)
		0:	if (hist_valid) Tstate <= 1;
			else xcnt <= 1;	
		1:if (hist_valid) 
				begin 
					xcnt <= xcnt + 1; 
					if (|hist_signal) begin Min <= xcnt; Tstate <= 2; end
				end	
		2:	if (hist_valid) 
				begin  
					xcnt <= xcnt + 1; 
					if (|hist_signal) begin Max <= xcnt; end
				end
			else begin TH <= Threshold; Tstate <= 0; end
		
		default: Tstate <= 0;
	endcase
end //end always

//this process finds out BL peak
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
					else begin peak_bin <= peaking_bin; Pstate <= 2; end
				end
			else Pstate <= 0;
		2: if (~hist_valid) Pstate <= 0;
		
		default: Pstate <= 0;
	endcase
end //end always

//this process calcutes the duty cycle: counts the total occupancy and BL occupancy
//DC = BL_op*1000/Tot_op in unit of 1/1000;

reg [31:0] BL_op,Tot_op; //occupancy, max = 28 bit = 12 + 16 
reg [31:0] DC_denom,DC_num;
wire [SF_WIDTH-1:0] fpDC_denom,fpDC_num,fpDC_rev;
parameter FP1 = 32'h3f800000; //1 in FP format

altfp_int2fp int2fpconv_inst1 (.dataa(DC_denom), .clock(clk), .result(fpDC_denom)); 
altfp_int2fp int2fpconv_inst2 (.dataa(DC_num), .clock(clk), .result(fpDC_num)); 
altfp_div3232 div_inst1 (.dataa(fpDC_num),. datab(fpDC_denom), .clock(clk), .result(fpDC_rev)); 
altfp_sub sub_inst1 (.dataa(FP1), .datab(fpDC_rev), .clock(clk), .result(fpDC) ); 

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

endmodule

