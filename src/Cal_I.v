`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
//	    Calculate beam dc current values  
//  
//      output: I_val32, signed number wth 32 bit range, in pA.
//      output: I_val16, for DAC binary 
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on July 24,2019
// May 5,2023: to replace bottom.vi, and lose weight, since we dont' need 
// LUT DC correction.

/*
wire TC_METHOD = (METHOD == 2'b00);
wire BF_METHOD = (METHOD == 2'b01);
wire TH_METHOD = (METHOD == 2'b10);
wire CB_METHOD = (METHOD == 2'b11); 
*/

//////////////////////////////////////////////////////////////////////////////////
module cal_current(
   input [1:0] METHOD,  //Processing method,see above 
	
	input signed [SF_WIDTH-1:0] fpBEAM, //un-corrected beam value from LPF 
	input [SF_WIDTH-1:0] fpPeak,
	input [SF_WIDTH-1:0] fpDC,
	
	input Data_In_Valid, //one clk wide, 
	input [1:0] PCA_gain, //mini-PCA gain,
	
	input [SF_WIDTH-1:0] FP_G, //Gain and offset correction
	input [SF_WIDTH-1:0] FP_Z,

	
	input [SF_WIDTH-1:0] Slope_FACTOR, // slope for DAC output correction
	input signed [SF_WIDTH-1:0] Offset_FACTOR, // offset for DAC output correction
	
	input [2:0] toroid_type,

	input clk,  //35 MHz 
	input rst,
	
	output [7:0] Index,
	output reg [31:0] I_val32, //signed, in unit of nA
	output reg [31:0] peak32, //signed, in unit of nA
	output reg [15:0] DAC_code, //signed 16 bit, in unit of uA
	output reg RDY	 // one clk pulse to signal transfer to slow fifo
    );

	 initial begin
	 I_val32 = 0;
	 peak32 = 0;
	 end
	 
parameter  	ADC_WIDTH = 16;
parameter   DAC_WIDTH = 16;
//parameter  	SF_WIDTH = 32;
parameter FP1000 = 32'h447a0000; 
parameter CONST_10 = 10;

parameter G3 = 32'h3f800000; //1 in FP format, G0 is 10 mA range
parameter G2 = 32'h3dcccccd; //0.1,G1 is 1 mA range
parameter G1 = 32'h3c23d70a; //0.01,G2 is 100 uA range
parameter G0 = 32'h3a83126f; //0.001,G3 is 10 uA range

parameter ISIS_TOROID_SV = 32'h3d063737; //fp value of 65.535/(200*10); 200 uA/V, 16 bit DAC, +/-5V DAC range
parameter T1_TOROID_SV = 32'h3d863737; //fp of 65.535/(100*10); 100 uA/V, 16 bit DAC, +/-5V DAC range
parameter UCN_TOROID_SV = 32'h3f27c505; //fp of 65.535/(10*10); 10 uA/V, 16 bit DAC, +/-5V DAC range
parameter BL2A_TOROID_SV = 32'h3ea7c505; //fp of 65.535/(20*10); 20 uA/V, 16 bit DAC, +/-5V DAC range
parameter BL2C_TOROID_SV = 32'h3e8bced9; //fp of 65.535/(24*10); 24 uA/V, 16 bit DAC, +/-5V DAC range

//DAC code for output +/-5V is from 0 to 65535:
//DAC = (65535/10)*V + 32768
//plus 32768 is equivalent to make DAC_code[15] = ~DAC[15], if DAC output negtive value.


/*
wire TC_METHOD = (METHOD == 2'b00);
wire BF_METHOD = (METHOD == 2'b01);
wire TH_METHOD = (METHOD == 2'b10);
wire CB_METHOD = (METHOD == 2'b11); 
*/

/*
wire signed [SF_WIDTH-1:0] GC_FACTOR = (PCA_gain == 2'b00)?  GC0_FACTOR : 
							           (PCA_gain == 2'b01)?  GC1_FACTOR : 
										  (PCA_gain == 2'b10)?  GC2_FACTOR : 
										  (PCA_gain == 2'b11)?  GC3_FACTOR : GC0_FACTOR;
*/

wire [SF_WIDTH-1:0] G_FACTOR = (PCA_gain == 2'b00)?  G0 : 
							          (PCA_gain == 2'b01)?  G1 : 
										 (PCA_gain == 2'b10)?  G2 : 
										 (PCA_gain == 2'b11)?  G3 : G0;
										 

wire [SF_WIDTH:0] SV = (toroid_type == 3'b000)?  ISIS_TOROID_SV : 
							  (toroid_type == 3'b001)?  T1_TOROID_SV : 
							  (toroid_type == 3'b010)?  UCN_TOROID_SV :
							  (toroid_type == 3'b011)?  BL2A_TOROID_SV : 
							  (toroid_type == 3'b100)?  BL2C_TOROID_SV : 0;
					 
///////////////////////////////////////////////////
//Duty Cycle calibration array:
//DC values = 0.5,1,3,6,10,30,50,70,90,95 for 10 Index = 0,1,2,3,4,..9.
//Corr.  = 	10 values

/*if using 20, for Corr.=20, then DC values = 0,1,2,3,4,5,6,7,8,9,10,20,30,40,50,60,70,80,90,95 for Index = 0,1,2,...19 */

wire [ADC_WIDTH-1:0] intDC,intDC5; 

wire [3:0] Dec; 
assign intDC5 = intDC + 5; //for carry-in fractional number

altfp_fp2int conv_inst4 (.dataa(fpDC), .clock(clk), .result(intDC));  
wire [7:0] DC = intDC[7:0];  //DC is less than < 100;

wire inside_8_20 = (DC >= 8) & (DC <= 20); 
wire inside_21_40 = (DC >= 21) & (DC <= 40); 
wire inside_41_60 = (DC >= 41) & (DC <= 60); 
wire inside_61_80 = (DC >= 61) & (DC <= 80); 
wire inside_81_92 = (DC >= 81) & (DC <= 92); 
wire inside_93_97 = (DC >= 93) & (DC <= 97); 
wire inside_97_98 = (DC > 97) & (DC <= 98); 
wire inside_98_100 = (DC > 98) & (DC <= 100); 

assign Index = (DC==0) ? 0 :
               ((DC==1)|(DC==2)) ? 1 :
					((DC==3)|(DC==4)) ? 2 :
					((DC==5)|(DC==6)|(DC==7)) ? 3 :
					inside_8_20 ? 4 :
					inside_21_40 ? 5 :
					inside_41_60 ? 6 :
					inside_61_80 ? 7 :
					inside_81_92 ? 8 :
					inside_93_97 ? 9 : 
					inside_97_98 ? 10 :
					inside_98_100 ? 11 :	12;

///////////////////////////////////////////////////////					 							 
wire signed [SF_WIDTH-1:0] fpgBEAM,fpgPeak,fpMciroA,fpPeak_uA, fpMciroA_G,fpPeak_uA_G,fpNanoA,fpNanoA_peak /*synthesis keep*/; //beam dc fp value in uA,nA
wire [DAC_WIDTH-1:0] DAC /*synthesis keep*/; //DAC code for beam dc value

wire [SF_WIDTH-1:0] NanoA32,NanoA_peak32; //beam dc value 32 bit in nA
wire [SF_WIDTH-1:0] DACfp1,DACfp2,DACfp; //DAC value in mV 32 bit

altfp_mul mul_inst0 (.dataa(fpBEAM), .datab(G_FACTOR), .clock(clk), .result(fpgBEAM) ); //Latency = 5  
altfp_mul mul_inst1 (.dataa(fpgBEAM), .datab(FP_G), .clock(clk), .result(fpMciroA_G) ); //Latency = 5  

altfp_add add_inst0 (.dataa(fpMciroA_G), .datab(FP_Z), .clock(clk), .result(fpMciroA) ); //Latency = 7  


altfp_mul mul_inst2 (.dataa(fpMciroA), .datab(FP1000), .clock(clk), .result(fpNanoA) ); //Latency = 5  

altfp_mul mul_inst3 (.dataa(fpNanoA), .datab(SV), .clock(clk), .result(DACfp1) ); //Latency = 5

altfp_mul mul_inst4 (.dataa(DACfp1), .datab(Slope_FACTOR), .clock(clk), .result(DACfp2) ); //Latency = 5  
altfp_add add_inst2 (.dataa(DACfp2), .datab(Offset_FACTOR), .clock(clk), .result(DACfp) ); //Latency = 7  

altfp_fp2int32 conv_inst2 (.dataa(fpNanoA), .clock(clk), .result(NanoA32));  
altfp_fp2int conv_inst3 (.dataa(DACfp), .clock(clk), .result(DAC));  

altfp_mul mul_inst5 (.dataa(fpPeak), .datab(G_FACTOR), .clock(clk), .result(fpgPeak) ); //Latency = 5  
altfp_mul mul_inst6 (.dataa(fpgPeak), .datab(FP_G), .clock(clk), .result(fpPeak_uA_G) ); //Latency = 5  

altfp_add add_inst3 (.dataa(fpPeak_uA_G), .datab(FP_Z), .clock(clk), .result(fpPeak_uA) ); //Latency = 7  


altfp_mul mul_inst7 (.dataa(fpPeak_uA), .datab(FP1000), .clock(clk), .result(fpNanoA_peak) ); //Latency = 5  
altfp_fp2int32 conv_inst5 (.dataa(fpNanoA_peak), .clock(clk), .result(NanoA_peak32)); 
 
always@ (posedge clk) begin
		if(Data_In_Valid) begin RDY <= 1; I_val32 <= NanoA32; peak32 <= NanoA_peak32; DAC_code <= {~DAC[15],DAC[14:0]}; end
		else RDY <= 0;	
end  //always

endmodule
