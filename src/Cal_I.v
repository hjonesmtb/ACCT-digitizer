`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
//	    Calculate current i values from ADC input value for 8 channels: 
//              i = ((ADC - 0x8000)/0x8000)*12.288*1000*gain (pA)
//                = (ADC/0x8000 - 1)*12288*gain (pA)
//      12.288: ADC input range, 0x8000: ADC bin for 0 V input, gain = (10,100,1000,10000) (nA/V)         
//      input: ADC 16 bit straight binary, gain
//      output: I_value, signed number wth 32 bit range, in pA.
//      output: I_val16, unsigned positive 16 bit, in unit of 65.5 nA.
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Nov.30,2018
//
//////////////////////////////////////////////////////////////////////////////////
module cal_current(
	input [ADC_BIT_WIDTH-1:0] Data_In[7:0],
	input Data_In_Valid, //one clk wide, freq = ADC sampling freq, 10 KHz ~ 100 KHz
	input [1:0] gain[7:0],
	input clk,  //10 MHz 
	input rst,

	output [31:0] I_value[7:0], //signed, in unit of pA
	output [15:0] I_val16[7:0], //positive 16 bit, in unit of 65.5 nA.
	output reg RDY	
    );

parameter  	ADC_BIT_WIDTH = 16;
parameter  	SF_WIDTH = 32;

parameter  	K1 = 16'd4; // = 122880,  gain = 10 nA/V
parameter  	K2 = 16'd38;// = 1228800,  gain = 100
parameter  	K3 = 16'd375; // = 12288000,  gain = 1000
parameter  	K4 = 16'd3750; // = 122880000,/ gain = 10000

reg [15:0] dataa_sig[7:0];
wire [15:0] k[7:0];
wire [31:0] C_value[7:0];
	
//////define states//////////
parameter    state_idle = 0, 
			 state_mul = 1,
			 state_rdy = 2;		 
		 
reg [3:0] state;
reg [3:0] count;

always@ (posedge clk)begin
	if (rst)begin
		count <= 0;
		RDY <= 0;
		state <= state_idle;
	end
	else begin
		case(state)
			state_idle:
			 begin
				if(Data_In_Valid == 1)begin
					dataa_sig[0] <= Data_In[0] - 16'D32768;
					dataa_sig[1] <= Data_In[1] - 16'D32768;
					dataa_sig[2] <= Data_In[2] - 16'D32768;
					dataa_sig[3] <= Data_In[3] - 16'D32768;
					dataa_sig[4] <= Data_In[4] - 16'D32768;
					dataa_sig[5] <= Data_In[5] - 16'D32768;
					dataa_sig[6] <= Data_In[6] - 16'D32768;
					dataa_sig[7] <= Data_In[7] - 16'D32768;
					state <= state_mul;
				end		
			 end					
			state_mul: //multiply
				begin
					if (count > 5) begin RDY <= 1; state <= state_rdy; end
				    else count <= count + 1'b1;
				end
			state_rdy:
				begin
					count <= 0;
					RDY <= 0;
					state <= state_idle;
				end	
			default: state <= state_idle;	
				
	    endcase
	end
end

genvar i;
generate 
for (i = 0; i < 8 ; i = i + 1) 
	begin: channel
    assign k[i] = (gain[i] == 2'b00)? K1
					  :(gain[i] == 2'b01)? K2
                 :(gain[i] == 2'b10)? K3
                 :(gain[i] == 2'b11)? K4 
                 :K1;
	 lpm_mul	mul_ch (
		.dataa(dataa_sig[i]),
		.datab(k[i]),
		.result(I_value[i])
		);	
  	 assign I_val16[i] = I_value[i][31]? {1'b0,~I_value[i][30:16]}
	                   : I_value[i][31:16];
	end
endgenerate 

endmodule
