`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: calcuation with 16 bit ADC signed data
// boxfilter:  same functions as boxfilter.v, but impletmented with memory block in FPGA to save LU resource.
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on July 22,2019
// last modified: 
// 

module boxfilter_sr(
    input clk,
    input in_valid,   
    input rst,
    input [15:0] window, //search window size, not in use
	 	 
    input [15:0] data_in, //input data 
	
    output reg signed [15:0] data_out, //output data, with BL substraced
	 output reg signed [15:0] BL, //base line
	 output overflow //calculation overflow 

    );
 
parameter  DATA_WIDTH = 16;
parameter  AVG_WINDOW = 4; //box filter : averaging window size
parameter  SEARCH_WIN = 256; //is actually 1024, i.e 1024 us for 1MSPS ADC data
parameter  SR_TAPS = 4;
parameter  SR_TAPS_DIS = 4;
parameter  SR_DATA = SEARCH_WIN;
parameter  SR_BLOCKS = SEARCH_WIN;
 


reg signed [DATA_WIDTH-1:0] buf_1,buf_2,buf_3,buf_4;
wire signed [DATA_WIDTH-1:0] add12,add123,add1234;
wire signed [DATA_WIDTH-1:0] data_in_BL;

always @(posedge clk)  
begin 
  if (in_valid) begin 
		buf_1 <=  {data_in[15],data_in[15],data_in[15:2]};  //data_in is divided by 4 first to prevent overflow
		buf_2 <=  buf_1; 
		buf_3 <=  buf_2;
		buf_4 <=  buf_3;
  end		
end 



lpm_addsub lpm_add_inst1 ( .add_sub(1'b1), .dataa(buf_1), .datab(buf_2), .result(add12));
lpm_addsub lpm_add_inst2 ( .add_sub(1'b1), .dataa(add12), .datab(buf_3), .result(add123));
lpm_addsub lpm_add_inst3 ( .add_sub(1'b1), .dataa(add123), .datab(buf_4), .result(add1234), .overflow(overflow));

//wire signed [DATA_WIDTH-1:0]  div4 = {add1234[15], add1234[15],add1234[15:2]}; //divided by 4	

reg  signed [DATA_WIDTH-1:0]  fit_avg/*synthesis keep*/;

wire signed [DATA_WIDTH-1:0] sbuf[SR_DATA-1:0]/*synthesis keep*/;
wire signed [DATA_WIDTH-1:0] sr_data[SR_DATA:0]/*synthesis keep*/;

always @(posedge clk) if (in_valid) begin fit_avg <= add1234; end
assign sr_data[0] = fit_avg;

wire [SR_DATA-1:0]  pass/*synthesis keep*/;
wire [SR_DATA-1:0]  step/*synthesis keep*/;
wire [SR_DATA-1:0]  found/*synthesis keep*/;
wire [SR_DATA-1:0]  sign;

wire same_sign = (&step) | (~(|step));

genvar i;
generate 
for (i = 0; i < SR_BLOCKS ; i = i + 4) 
   begin: gate_group
	 shift_reg data_gate_1(.clock(clk),.clken(in_valid),.shiftin(sr_data[i]),.shiftout(sr_data[i+4]),
	 .taps0x(sbuf[i]),
	 .taps1x(sbuf[i+1]),
	 .taps2x(sbuf[i+2]),
	 .taps3x(sbuf[i+3]));
	
    data_gate dg1(.clk(clk),.in_valid(in_valid), .pass(pass[i]),.data(sbuf[i]),.step(step[i]),.found(found[i]),.sign_step(sign[i]));	
    data_gate dg2(.clk(clk),.in_valid(in_valid), .pass(pass[i+1]),.data(sbuf[i+1]),.step(step[i+1]),.found(found[i+1]));	
    data_gate dg3(.clk(clk),.in_valid(in_valid), .pass(pass[i+2]),.data(sbuf[i+2]),.step(step[i+2]),.found(found[i+2]));
    data_gate dg4(.clk(clk),.in_valid(in_valid), .pass(pass[i+3]),.data(sbuf[i+3]),.step(step[i+3]),.found(found[i+3]));
  
    assign pass[i] = same_sign? 1 : sign[0]? step[i] : ~step[i];
    assign pass[i+1] = same_sign? 1 : sign[0]? step[i+1] : ~step[i+1];
    assign pass[i+2] = same_sign? 1 : sign[0]? step[i+2] : ~step[i+2];
    assign pass[i+3] = same_sign? 1 : sign[0]? step[i+3] : ~step[i+3];
	 
	end	
endgenerate 


reg [255:0] all/*synthesis keep*/;
reg [127:0] half/*synthesis keep*/;
reg [11:0] index/*synthesis keep*/;


reg [3:0] state/*synthesis keep*/;
parameter state_0 = 0, state_1 = 1, state_2 = 2, state_3 = 3, state_4 = 4,
          state_5 = 5, state_6 = 6, state_7 = 7, state_8 = 8, state_9 = 9,
          state_10 = 10, state_11 = 11;
					
always @(posedge clk) 
  case (state)
      state_0: if (|found) begin all <= found; index <= 0; state <= state_1; end
    	state_1: begin  //1024	           
    	           if (|all[SEARCH_WIN-1:SEARCH_WIN/2]) begin index <= index + (SEARCH_WIN>>1); half[SEARCH_WIN/2-1:0] <= all[SEARCH_WIN-1:SEARCH_WIN/2]; end
    	           else half[SEARCH_WIN/2-1:0] <= all[SEARCH_WIN/2-1:0]; 
					  state <= state_2; 
    	         end		
    	state_2: begin //512 	           
    	           if (|half[SEARCH_WIN/2-1:SEARCH_WIN/4]) begin index <= index + (SEARCH_WIN>>2); all[SEARCH_WIN/4-1:0] <= half[SEARCH_WIN/2-1:SEARCH_WIN/4]; end
    	           else all[SEARCH_WIN/4-1:0] <= half[SEARCH_WIN/4-1:0]; 
					  state <= state_3; 
    	         end		
    	
    	state_3: begin //256 	           
    	           if (|all[SEARCH_WIN/4-1:SEARCH_WIN/8]) begin index <= index + (SEARCH_WIN>>3); half[SEARCH_WIN/8-1:0] <= all[SEARCH_WIN/4-1:SEARCH_WIN/8]; end
    	           else half[SEARCH_WIN/8-1:0] <= all[SEARCH_WIN/8-1:0]; 
					  state <= state_4;
    	         end	
		
    	
    	state_4: begin //128 	           
    	           if (|half[SEARCH_WIN/8-1:SEARCH_WIN/16]) begin index <= index + (SEARCH_WIN>>4); all[SEARCH_WIN/16-1:0] <= half[SEARCH_WIN/8-1:SEARCH_WIN/16]; end
    	           else all[SEARCH_WIN/16-1:0] <= half[SEARCH_WIN/16-1:0]; 
					  state <= state_5; 
    	         end		
 
					
    	state_5: begin //64 	           
    	           if (|all[SEARCH_WIN/16-1:SEARCH_WIN/32]) begin index <= index + (SEARCH_WIN>>5); half[SEARCH_WIN/32-1:0] <= all[SEARCH_WIN/16-1:SEARCH_WIN/32]; end
    	           else half[SEARCH_WIN/32-1:0] <= all[SEARCH_WIN/32-1:0]; 
					  state <= state_6; 
    	         end		
    	         
    	state_6: begin //32	           
    	           if (|half[SEARCH_WIN/32-1:SEARCH_WIN/64]) begin index <= index + (SEARCH_WIN>>6); all[SEARCH_WIN/64-1:0] <= half[SEARCH_WIN/32-1:SEARCH_WIN/64]; end
    	           else all[SEARCH_WIN/64-1:0] <= half[SEARCH_WIN/64-1:0]; 
    	           state <= state_7; 
    	         end		  
					

		state_7: begin //16 	           
    	           if (|all[SEARCH_WIN/64-1:SEARCH_WIN/128]) begin index <= index + (SEARCH_WIN>>7); half[SEARCH_WIN/128-1:0] <= all[SEARCH_WIN/64-1:SEARCH_WIN/128]; end
    	           else half[SEARCH_WIN/128-1:0] <= all[SEARCH_WIN/128-1:0]; 
    	           state <= state_8; 
    	         end	
		 	         
    	state_8: begin //8 	           
    	           if (|half[SEARCH_WIN/128-1:SEARCH_WIN/256]) begin index <= index + (SEARCH_WIN>>8); all[SEARCH_WIN/256-1:0] <= half[SEARCH_WIN/128-1:SEARCH_WIN/256]; end
    	           else all[SEARCH_WIN/256-1:0] <= half[SEARCH_WIN/256-1:0]; 
    	           state <= state_9; 
    	         end		
	   
		state_9: begin //1 
		           BL <= sbuf[index]; state <= state_0;  
		         end	
	   
	/*
    	state_9: begin //4 	           
    	           if (|all[SEARCH_WIN/256-1:SEARCH_WIN/512]) begin index <= index + (SEARCH_WIN>>9); half[SEARCH_WIN/512-1:0] <= all[SEARCH_WIN/256-1:SEARCH_WIN/512]; end
    	           else half[SEARCH_WIN/512-1:0] <= all[SEARCH_WIN/512-1:0]; 
    	           state <= state_10; 
    	         end	
  	         
  
      state_10: begin //2 	           
    	           if (|half[SEARCH_WIN/512-1:SEARCH_WIN/1024]) begin index <= index + (SEARCH_WIN>>10); all[SEARCH_WIN/1024-1:0] <= half[SEARCH_WIN/512-1:SEARCH_WIN/1024]; end
    	           else all[SEARCH_WIN/1024-1:0] <= half[SEARCH_WIN/1024-1:0]; 
    	           state <= state_11; 
    	         end		
   	                                                                                                                     
		state_11: begin //1 
		           BL <= sbuf[index]; state <= state_0;  
		         end	
	*/
	
	    default: state <= state_0;
  endcase

lpm_addsub lpm_sub_inst1 ( .add_sub(1'b0), .dataa(fit_avg), .datab(BL), .result(data_in_BL));
always @(posedge clk) if (in_valid) data_out <= data_in_BL;
                
endmodule