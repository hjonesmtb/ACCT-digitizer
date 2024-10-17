`timescale 1ns / 1ps
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// IIR: 1st order: Y[n] = K1*Y[n-1] + K2*X[n], HPF: K1 = (-1,0), LPF: K1 = (0,1);  
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on June 20,2019
// last modified: 
// 
module IIR(
   input FCLK,
   input in_valid,  
	input HighPass,  //1 = high pass, 0 = low pass

	input [31:0] data_in,
	
	input [31:0] fpK1, 
	input [31:0] fpK2, 
	 
    output reg [31:0] data_out

    );
 
parameter  SF_WIDTH = 32;

//default:
//parameter K1 = 0x3dcccccd  //0.1
//parameter K2 = 0x3f666666  //0.9

wire [SF_WIDTH-1:0] S1;
wire [SF_WIDTH-1:0] S2;
wire [SF_WIDTH-1:0] FB;

wire [SF_WIDTH-1:0] sfpK2 = HighPass? {1'b1,fpK2[30:0]} : fpK2 ;

altfp_mul mul_inst1 (.dataa(data_in), .datab(fpK1), .clock(FCLK), .result(S1) );   
altfp_mul mul_inst2 (.dataa(data_out), .datab(sfpK2), .clock(FCLK), .result(FB) );    	 

altfp_add add_inst1 (.dataa(S1), .datab(FB), .clock(FCLK), .result(S2) ); 

always @(posedge FCLK)  if (in_valid) data_out <=  S2;
 
endmodule