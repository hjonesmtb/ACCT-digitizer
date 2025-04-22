//Synchronous Averaging algorithm for ACCT digital signal processing
//Description: Averaging one peroid of the pulse by pulse, seperated by 'pulse_start'.
//Input: 'pulse_start': one clock, indicates new pulse, 
//       'in_valid': one clock, indicates signal valid, Not synchronous to 'pulse_start';
// 
//for toroid processor. clk is SCLK=35 MHz, data rate is 1.15275MHz

// Oct 10 2024 : modified overflow to detect when pulse length exceeds 16384
// Nov 8 2024  : modified so addr will not overflow, and peak current calc will be correct for all frequencies
// Apr 7 2025: modified so avg_signal is not droop compensated, but the INT output is. 


`timescale 1ns / 1ps
module syn_averaging(
	input clk, // SCLK 35 MHz
	input signed [15:0] signal,
	input in_valid, //signal valid, data rate is about 1.15275 MHz
	input pulse_start,  //one clock pulse, i.e.   ISIS pulse
	input [15:0] AVG_TIMES, //averaging times: 16,32,64,128,256,512
	
	input signed [15:0] BL, 
	input signed [15:0] alpha,
	
	output reg INT_Valid,  //one clk wide, to tag the INT signal
	output reg [31:0] INT, //Integration of the recitified pulse
	output reg [15:0] N_sample,
	output avg_valid,
   output signed [15:0] avg_signal,
	output signed [15:0] avg_signal_comp,
	output reg [13:0] pulse_len, // added sept 3 - HJ
	output overflow,
	output [31:0] debug
);

// ADC sampling freq 1.15275MHz (T=0.86749 us), refer to "AD4001.v"

	//parameter ADC_BIT_WIDTH = 16;
	parameter DATA_WIDTH = 16;
	parameter LONG_WIDTH = 20; // changed from 24 - sept 4 
	
	wire [3:0] SHIFT_BITS = (AVG_TIMES == 4 )? 2 :
	                        (AVG_TIMES == 8 )? 3 :
									(AVG_TIMES == 16 )? 4 :
	                        (AVG_TIMES == 32 )? 5 :
									(AVG_TIMES == 64 )? 6 :
									(AVG_TIMES == 128)? 7 :
									(AVG_TIMES == 256)? 8 :
									(AVG_TIMES == 512)? 9 : 0;
	
	parameter state_idle = 0,
             state_1 = 1,
				 state_2 = 2,
				 state_3 = 3,
             state_4 = 4,
				 state_5 = 5,
				 state_6 = 6;	 
					
	reg [3:0] state/*synthesis keep*/;
	
   reg rd_en, wr_en/*synthesis keep*/;
	reg signed [LONG_WIDTH-1:0] ram_data_in/*synthesis keep*/; 
	wire signed [LONG_WIDTH-1:0] ram_data_out, ram_dout_latched/*synthesis keep*/; 
	
	reg acc_rd_en, acc_wr_en;	
	reg signed [LONG_WIDTH-1:0] acc_data_in, avg_signal_24, avg_signal_24_comp/*synthesis keep*/;	
	wire signed [LONG_WIDTH-1:0] acc_data_out/*synthesis keep*/;
	
	reg [13:0] acc_cnt; //max = 1023
	reg [13:0] addr,acc_waddr,acc_raddr; 
	wire [13:0] acc_addr/*synthesis keep*/;
   assign acc_addr = acc_rd_en? acc_raddr : acc_waddr;
	
	reg new_pulse;
	reg signed[36:0] integral; // integrate pulse (scaled by alpha) bits = 20+14+3 (max alpha = 2^3 - 1 = 9)	
	
	assign debug = avg_signal_comp;
	reg ovf; // oveflow flag that is updated during each pulse
	
always @ (posedge clk )
begin
	 
	case(state)
		state_idle:
		begin 
			if (pulse_start | new_pulse) //new pulse
				begin 
					pulse_len <= addr;
					
					overflow <= ovf;
					ovf <= 0;
					
					addr <= 0;
					new_pulse <= 0;
					//integral <= 0;
					if (acc_cnt < AVG_TIMES-1)
						begin
							acc_cnt <= acc_cnt + 1;
						end
					else  
						begin
							acc_cnt <= 0; 
						end
					state <= state_1;
					//if (in_valid ) begin rd_en <= 1; state <= state_2; end else state <= state_1;
				end 
			else if (in_valid) //next data point within the same pulse
				begin 		
						if(&addr == 1'b1) begin
							ovf <= 1;
						end
						else begin
							addr <= addr + 1;
						end
						rd_en <= 1;
						state <= state_2; 
				end 
		end
		
		state_1: 
		begin
		   if (in_valid) begin rd_en <= 1; state <= state_2; end
		end
		
		state_2: begin 
		            rd_en <= 0;
						if (pulse_start) begin new_pulse <= 1; state <= state_idle; end
					   else state <= state_3; 
					end
					
		state_3: begin 
						if (pulse_start) begin new_pulse <= 1; state <= state_idle; end
					   else state <= state_4; 
					end	
		
		state_4: 
		begin
		  if (pulse_start) begin new_pulse <= 1; state <= state_idle; end
		  else begin 
					if (acc_cnt == 1) //acc_cnt == 1, this is the first pulse. 
						begin
							ram_data_in <= signal;
							//integral <= integral + (ram_data_out - BL)*alpha;
							ram_dout_latched <= ram_data_out;
							//acc_data_in <= ram_dout_latched + (integral>>>22); // changed from ram_data_out
							acc_data_in <= ram_dout_latched;
							acc_waddr <= addr;
							acc_wr_en <= 1; 
						end
					else ram_data_in <= ram_data_out + signal; // possible bug at overflow, last item will grow??
					state <= state_5;
				 end 	
		end  
		
		state_5: 
		begin
		   acc_wr_en <= 0;
			if (pulse_start) begin new_pulse <= 1; state <= state_idle; end
			else begin wr_en <= 1; state <= state_6; end
		end 		

		state_6:
		begin
			if (pulse_start) new_pulse <= 1; 
			wr_en <= 0; 
			state <= state_idle;
		end		
		
		default: state <= state_idle;
	endcase
	
end //end always

// changed to 16384 - sept 4
// changed to 20 bit (max avg = 32 now) - sept 4
ram_24_16k acc_ram_inst (
	.address(addr), //10 bit address width
	.clock(clk),
	.data(ram_data_in), //24 bit data width
	.rden(rd_en),
	.wren(wr_en),
	.q(ram_data_out) // 24 bit
	);   
	
ram_24_16k avg_ram_inst (
	.address(acc_addr), //10 bit address width
	.clock(clk),
	.data(acc_data_in), //24 bit data width
	.rden(acc_rd_en),
	.wren(acc_wr_en),
	.q(acc_data_out) // 24 bit
	);   
	
/////////////////////////////////////////////////////////////////////////
//crate signal start_proc, 1 clk,  to start the processing of the acc waveform
//start accessing the acc memory should not conflict with accumulating waveform.	
//so it should start when acc_cnt == 2, since the acc memrory writting happens during acc_cnt == 1,
//i.e. the first pulse.

reg acc_state; 
reg start_proc;

always @ (posedge clk ) 
begin
	case(acc_state)
		0: if (acc_cnt == 2 ) begin start_proc <= 1; acc_state <= 1; end 
		1: begin
		      start_proc <= 0;
				if (acc_cnt[0] == 1) acc_state <= 0; 
			end
		default: acc_state <= 0;
	endcase
end

//readout the accumulated waveform, divided by AVG_TIMEs, then move to Fast FIFO
//to be readout by Labview.
//throw out last 8 samples: since one period has only 1016 samples for the built-in cal pulses.
//for the reality, this number needs to be adjusted accordingly.

reg [1:0] pro_state;
reg avg_valid_reg/*synthesis keep*/; 

assign avg_valid = avg_valid_reg;
assign avg_signal = avg_signal_24[DATA_WIDTH-1:0];
assign avg_signal_comp = avg_signal_24_comp[DATA_WIDTH-1:0];


always @ (posedge clk )
begin
	case(pro_state)
		0: if (start_proc)  begin acc_rd_en <= 1; acc_raddr <= 0; pro_state <= 1; end
		1: pro_state <= 2; 
		2: begin 
			  if (acc_raddr == pulse_len) begin 
				acc_rd_en <= 0; avg_valid_reg <= 0;
				pro_state <= 3; 
				integral <= 0;
			  end //restart on each pulse
			  else begin 
				acc_raddr <= acc_raddr + 1;  	
				avg_valid_reg <= 1; 
				integral <= integral + (acc_data_out - BL)*alpha; 
			  end
			  
			  avg_signal_24 <= acc_data_out >>> SHIFT_BITS; //keep sign, devided the AVG_TIMES
			  avg_signal_24_comp <= (acc_data_out + (integral >>> 22)) >>> SHIFT_BITS;
			  
			  //avg_signal_24 <= acc_data_out; //keep sign, devided the AVG_TIMES
		   end
		3: begin  pro_state <= 0; end
	   default: pro_state <= 0;
	endcase
end 	

//for each averaged pulse, calculate the Integration: substract base line (BL) and integrating. 
//INT = (X1-BL)+(X2-BL)+...+(Xn-BL)=(X1+X2...+Xn)-n*BL

reg signed [15:0] Xmin/*synthesis keep*/;
reg signed [31:0] Acc,Sum/*synthesis keep*/;
wire signed [31:0] NBL,data_sum/*synthesis keep*/;
wire [31:0] s_data_sum/*synthesis keep*/;

reg [15:0] N/*synthesis keep*/;

reg [1:0] min_state;
always @ (posedge clk )	
begin
   case(min_state)
		0: if (avg_valid) begin INT_Valid <= 0; Acc <= Acc + avg_signal_comp; N <= N + 1; min_state <= 1; end 
		   else begin INT_Valid <= 0; Acc <= 0; N <= 0; end
		1: if (~avg_valid) min_state <= 2; 
			else begin 
					 Acc <= Acc + avg_signal_comp; N <= N + 1; 
				  end 
		2: begin Sum <= Acc; N_sample <= N; min_state <= 3; end 
		3: begin N <= 0; INT_Valid <= 1; INT <= s_data_sum; min_state <= 0; end 
	   default: min_state <= 0;
	endcase
end	
	

lpm_mul mul_signed_inst (
		.dataa(N_sample), //signed 16 bit 
		.datab(BL),  //signed 16 bit 
		.result(NBL)  //signed 32 bit 
		);	
		
lpm_addsub32 lpm_add_signed_1 ( .add_sub(1'b0), .dataa(Sum), .datab(NBL), .result(data_sum));

wire [31:0] fp_sum, fp_len;

altfp_int2fp int2fpconv_inst1 (.dataa(data_sum), .clock(clk), .result(fp_sum));
altfp_int2fp int2fpconv_inst2 (.dataa(pulse_len), .clock(clk), .result(fp_len)); 

altfp_div3232 fpdiv1 (.dataa(fp_sum), .datab(fp_len), .clock(clk), .result(s_data_sum)); 

//lpm_3232div div_i ( .numer(data_sum), .denom(pulse_len), .remain(), .quotient(s_data_sum)); // This causes glitches. Possibly from quantization? Fixed by using FP div.
//assign s_data_sum = {{10{data_sum[31]}},{data_sum[31:10]}};	//divided by 1024, otherwise it's too big.
endmodule
