
//self trigger: Feb.14,2019

`timescale 1ns / 1ps
module self_trigger(
	input [ADC_BIT_WIDTH-1:0] signal, //postive going signal
	input [ADC_BIT_WIDTH-1:0] threshold, //postive value, ADC bin number
   input in_valid,
	input clk, //
	
	output reg [ADC_BIT_WIDTH-1:0] BL, //base line 
	output reg gate //indicates the pulse width
	
);

	parameter ADC_BIT_WIDTH = 16;
	parameter DATA_WIDTH = 16;

//averaging 4 samples
reg signed [DATA_WIDTH-1:0] buf_1,buf_2,buf_3,buf_4;
wire signed [DATA_WIDTH-1:0] add12,add123,add1234;

wire signed [DATA_WIDTH-1:0]  div4 = {add1234[15], add1234[15],add1234[15:2]}; //divided by 4	
reg  signed [DATA_WIDTH-1:0]  fit_avg/*synthesis keep*/;
wire overflow1;

always @(posedge clk)  
begin 
  if (in_valid) begin 
		buf_1 <=  signal; 
		buf_2 <=  buf_1; 
		buf_3 <=  buf_2;
		buf_4 <=  buf_3;
		fit_avg <= div4;
  end		
end 

lpm_addsub lpm_add_inst1 ( .add_sub(1'b1), .dataa(buf_1), .datab(buf_2), .result(add12));
lpm_addsub lpm_add_inst2 ( .add_sub(1'b1), .dataa(add12), .datab(buf_3), .result(add123));
lpm_addsub lpm_add_inst3 ( .add_sub(1'b1), .dataa(add123), .datab(buf_4), .result(add1234), .overflow(overflow1));
// end averaging 

// gate algorithm:
// if two samples (fixed interval) differs greater than threhold, then the first sample time is the pulse start or end time

reg signed [DATA_WIDTH-1:0] buf_5,buf_6,buf_7,buf_8;
reg signed [DATA_WIDTH-1:0] buf_9,buf_10,buf_11,buf_12;

wire signed [DATA_WIDTH-1:0] diff = fit_avg - buf_8/*synthesis keep*/;

wire [DATA_WIDTH-1:0] abs_diff/*synthesis keep*/;
wire sign_bit/*synthesis keep*/;
assign sign_bit = diff[ADC_BIT_WIDTH-1];
assign abs_diff = sign_bit? ~diff : diff;

always @(posedge clk)  
begin 
  if (in_valid) begin 
		buf_5 <=  fit_avg; 
		buf_6 <=  buf_5; 
		buf_7 <=  buf_6;
		buf_8 <=  buf_7;
		buf_9 <=  buf_8; 
		buf_10 <=  buf_9; 
		buf_11 <=  buf_10;
		buf_12 <=  buf_11;
  end		
end 


parameter state_idle = 0,
          state_fall = 1;
	 					
reg [1:0] state/*synthesis keep*/;

always @ (posedge clk)
begin
	case(state)
		state_idle: 
		begin
			if ((abs_diff > threshold) && (sign_bit == 0)) 
				begin BL <= buf_12; gate <= 1; state <= state_fall; end
			else gate <= 0;	
		end	
		state_fall:
		begin
			if ((abs_diff > threshold) && (sign_bit == 1)) begin
				gate <= 0; state <= state_idle;
				end
		end
		
		default:
		begin
		gate <= 0;
		state <= state_idle;
		end
	endcase
end 
				

endmodule
