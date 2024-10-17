`timescale 1ns / 1ps
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// LPF_output:  based on Bill R. lowpass5.bdf of UCN BPM Module 1012 processor
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on June 20,2019
// last modified: 
// 
module LPF_output(
    input FCLK,
    input in_valid,   
 	 //input rst,
	 input [31:0] data_in,
	
    output reg [31:0] data_out

    );
 
parameter  SF_WIDTH = 32;


parameter K1 = 32'd1677722;  //0.1 = 1677722/2^24
parameter K2 = 32'd15099494; //0.9 = 15099494/2^24

wire [SF_WIDTH-1:0] S1;
wire [SF_WIDTH-1:0] S2;
wire [SF_WIDTH-1:0] fpK1,fpK2;
wire [SF_WIDTH-1:0] FB;

altfp_fx2fp conv_inst1 (.dataa(K1), .clock(FCLK), .result(fpK1)); 
altfp_fx2fp conv_inst2 (.dataa(K2), .clock(FCLK), .result(fpK2)); 

altfp_mul mul_inst1 (.dataa(data_in), .datab(fpK1), .clock(FCLK), .result(S1) );   
altfp_mul mul_inst2 (.dataa(data_out), .datab(fpK2), .clock(FCLK), .result(FB) );    	 

altfp_add add_inst1 (.dataa(S1), .datab(FB), .clock(FCLK), .result(S2) ); 

always @(posedge FCLK)  if (in_valid) data_out <=  S2;
 
endmodule