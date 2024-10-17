`timescale 1ns / 1ps
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: calcuation with 16 bit ADC signed data
// boxfilter:  based on Matlab simulation file TDP_001.m
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on July 11,2019
// last modified: 
// 

module boxfilter(
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
//parameter  SEARCH_WIN = 1024; //1024 for 1MSPS ADC data
parameter  SEARCH_WIN = 16384; // hj 

reg signed [DATA_WIDTH-1:0] buf_1,buf_2,buf_3,buf_4;
wire signed [DATA_WIDTH-1:0] add12,add123,add1234;
wire signed [DATA_WIDTH-1:0] data_in_BL;

always @(posedge clk)  
begin 
  if (in_valid) begin 
		buf_1 <=  data_in; 
		buf_2 <=  buf_1; 
		buf_3 <=  buf_2;
		buf_4 <=  buf_3;
  end		
end 

lpm_addsub lpm_add_inst1 ( .add_sub(1'b1), .dataa(buf_1), .datab(buf_2), .result(add12));
lpm_addsub lpm_add_inst2 ( .add_sub(1'b1), .dataa(add12), .datab(buf_3), .result(add123));
lpm_addsub lpm_add_inst3 ( .add_sub(1'b1), .dataa(add123), .datab(buf_4), .result(add1234), .overflow(overflow));

wire signed [DATA_WIDTH-1:0]  div4 = {add1234[15], add1234[15],add1234[15:2]}; //divided by 4	
reg  signed [DATA_WIDTH-1:0]  fit_avg/*synthesis keep*/;

reg signed [DATA_WIDTH-1:0] sbuf[SEARCH_WIN:0]/*synthesis keep*/;

always @(posedge clk) if (in_valid) begin fit_avg <= div4;  sbuf[0] <= fit_avg; end

wire [SEARCH_WIN-1:0]  pass;
wire [SEARCH_WIN-1:0]  step;
wire [SEARCH_WIN-1:0]  found;
wire [SEARCH_WIN-1:0]  sign;

wire same_sign = (&step) | (~(|step));

genvar i;
generate 
for (i = 0; i < SEARCH_WIN ; i = i + 1) 
   begin: gate_group
		always @(posedge clk) if (in_valid) sbuf[i+1] <= sbuf[i];
		data_gate dg(.clk(clk),.in_valid(in_valid), .pass(pass[i]),.data(sbuf[i]),.step(step[i]),.found(found[i]),.sign_step(sign[i]));
		assign pass[i] = same_sign? 1 : sign[0]? step[i] : ~step[i];
		//always @(posedge clk) if (in_valid & found[i])  BL <= sbuf[i];
	end	
endgenerate 

reg [SEARCH_WIN-1:0] all/*synthesis keep*/;
reg [SEARCH_WIN/2-1:0] half/*synthesis keep*/;
reg  [14:0] index/*synthesis keep*/;


reg [4:0] state/*synthesis keep*/;
parameter state_0 = 0, state_1 = 1, state_2 = 2, state_3 = 3, state_4 = 4,
          state_5 = 5, state_6 = 6, state_7 = 7, state_8 = 8, state_9 = 9,
          state_10 = 10, state_11 = 11;
			 
parameter state_new1 = 12, state_new2 = 13, state_new3 = 14, state_new4 = 15;
					
always @(posedge clk) 
  case (state)
        state_0: if (|found) begin all <= found; index <= 0; state <= state_1; end
					
    	state_1: begin  //16384           
    	           if (|all[SEARCH_WIN-1:SEARCH_WIN/2]) begin index <= index + (SEARCH_WIN>>1); half[SEARCH_WIN/2-1:0] <= all[SEARCH_WIN-1:SEARCH_WIN/2]; end
    	           else half[SEARCH_WIN/2-1:0] <= all[SEARCH_WIN/2-1:0]; 
					  state <= state_2; 
    	         end		
    	state_2: begin //8192	           
    	           if (|half[SEARCH_WIN/2-1:SEARCH_WIN/4]) begin index <= index + (SEARCH_WIN>>2); all[SEARCH_WIN/4-1:0] <= half[SEARCH_WIN/2-1:SEARCH_WIN/4]; end
    	           else all[SEARCH_WIN/4-1:0] <= half[SEARCH_WIN/4-1:0]; 
					  state <= state_3; 
    	         end		
    	
    	state_3: begin //4096 	           
    	           if (|all[SEARCH_WIN/4-1:SEARCH_WIN/8]) begin index <= index + (SEARCH_WIN>>3); half[SEARCH_WIN/8-1:0] <= all[SEARCH_WIN/4-1:SEARCH_WIN/8]; end
    	           else half[SEARCH_WIN/8-1:0] <= all[SEARCH_WIN/8-1:0]; 
					  state <= state_4;
    	         end	
		
    	
    	state_4: begin //2048 	           
    	           if (|half[SEARCH_WIN/8-1:SEARCH_WIN/16]) begin index <= index + (SEARCH_WIN>>4); all[SEARCH_WIN/16-1:0] <= half[SEARCH_WIN/8-1:SEARCH_WIN/16]; end
    	           else all[SEARCH_WIN/16-1:0] <= half[SEARCH_WIN/16-1:0]; 
					  state <= state_5; 
    	         end		
 
					
    	state_5: begin //1024 	           
    	           if (|all[SEARCH_WIN/16-1:SEARCH_WIN/32]) begin index <= index + (SEARCH_WIN>>5); half[SEARCH_WIN/32-1:0] <= all[SEARCH_WIN/16-1:SEARCH_WIN/32]; end
    	           else half[SEARCH_WIN/32-1:0] <= all[SEARCH_WIN/32-1:0]; 
					  state <= state_6; 
    	         end		
    	         
    	state_6: begin //512	           
    	           if (|half[SEARCH_WIN/32-1:SEARCH_WIN/64]) begin index <= index + (SEARCH_WIN>>6); all[SEARCH_WIN/64-1:0] <= half[SEARCH_WIN/32-1:SEARCH_WIN/64]; end
    	           else all[SEARCH_WIN/64-1:0] <= half[SEARCH_WIN/64-1:0]; 
    	           state <= state_7; 
    	         end		  
					

		state_7: begin //256	           
    	           if (|all[SEARCH_WIN/64-1:SEARCH_WIN/128]) begin index <= index + (SEARCH_WIN>>7); half[SEARCH_WIN/128-1:0] <= all[SEARCH_WIN/64-1:SEARCH_WIN/128]; end
    	           else half[SEARCH_WIN/128-1:0] <= all[SEARCH_WIN/128-1:0]; 
    	           state <= state_8; 
    	         end	
		 	         
    	state_8: begin //128	           
    	           if (|half[SEARCH_WIN/128-1:SEARCH_WIN/256]) begin index <= index + (SEARCH_WIN>>8); all[SEARCH_WIN/256-1:0] <= half[SEARCH_WIN/128-1:SEARCH_WIN/256]; end
    	           else all[SEARCH_WIN/256-1:0] <= half[SEARCH_WIN/256-1:0]; 
    	           state <= state_9; 
    	         end		
    	         
    	state_9: begin //64 	           
    	           if (|all[SEARCH_WIN/256-1:SEARCH_WIN/512]) begin index <= index + (SEARCH_WIN>>9); half[SEARCH_WIN/512-1:0] <= all[SEARCH_WIN/256-1:SEARCH_WIN/512]; end
    	           else half[SEARCH_WIN/512-1:0] <= all[SEARCH_WIN/512-1:0]; 
    	           state <= state_10; 
    	         end	
  	         
  
      state_10: begin //32 	           
    	           if (|half[SEARCH_WIN/512-1:SEARCH_WIN/1024]) begin index <= index + (SEARCH_WIN>>10); all[SEARCH_WIN/1024-1:0] <= half[SEARCH_WIN/512-1:SEARCH_WIN/1024]; end
    	           else all[SEARCH_WIN/1024-1:0] <= half[SEARCH_WIN/1024-1:0]; 
    	           state <= state_new1; 
    	         end	
      state_new1: begin //16 	           
    	           if (|half[SEARCH_WIN/1024-1:SEARCH_WIN/2048]) begin index <= index + (SEARCH_WIN>>11); all[SEARCH_WIN/2048-1:0] <= half[SEARCH_WIN/1024-1:SEARCH_WIN/2048]; end
    	           else all[SEARCH_WIN/2048-1:0] <= half[SEARCH_WIN/2048-1:0]; 
    	           state <= state_new2; 
    	         end
      state_new2: begin //8 	           
    	           if (|half[SEARCH_WIN/2048-1:SEARCH_WIN/4096]) begin index <= index + (SEARCH_WIN>>12); all[SEARCH_WIN/4096-1:0] <= half[SEARCH_WIN/2048-1:SEARCH_WIN/4096]; end
    	           else all[SEARCH_WIN/4096-1:0] <= half[SEARCH_WIN/4096-1:0]; 
    	           state <= state_new3; 
    	         end	
      state_new3: begin //4 	           
    	           if (|half[SEARCH_WIN/4096-1:SEARCH_WIN/8192]) begin index <= index + (SEARCH_WIN>>13); all[SEARCH_WIN/8192-1:0] <= half[SEARCH_WIN/4096-1:SEARCH_WIN/8192]; end
    	           else all[SEARCH_WIN/8192-1:0] <= half[SEARCH_WIN/8192-1:0]; 
    	           state <= state_new4; 
    	         end
     state_new4: begin //2 	           
    	           if (|half[SEARCH_WIN/8192-1:SEARCH_WIN/16384]) begin index <= index + (SEARCH_WIN>>14); all[SEARCH_WIN/16384-1:0] <= half[SEARCH_WIN/8192-1:SEARCH_WIN/16384]; end
    	           else all[SEARCH_WIN/16384-1:0] <= half[SEARCH_WIN/16384-1:0]; 
    	           state <= state_11; 
    	         end	
   	                                                                                                                     
		state_11: begin //1 
		           BL <= sbuf[index]; state <= state_0;  
		         end	
	
	
	    default: state <= state_0;
  endcase

lpm_addsub lpm_sub_inst1 ( .add_sub(1'b0), .dataa(fit_avg), .datab(BL), .result(data_in_BL));
always @(posedge clk) if (in_valid) data_out <= data_in_BL;
                
endmodule