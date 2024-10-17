`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
//	    Calculate beam dc current values  
//  
//      output: I_val32, signed number wth 32 bit range, in pA.
//      output: I_val16, for DAC binary 
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on July 24,2019
//
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
	output reg [15:0] DAC_code, //signed 16 bit, in unit of uA
	output reg RDY	 // one clk pulse to signal transfer to slow fifo
    );

parameter  	ADC_WIDTH = 16;
parameter   DAC_WIDTH = 16;
parameter  	SF_WIDTH = 32;
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
					 
					 							 
wire signed [SF_WIDTH-1:0] fpgcBEAM,fpgBEAM,fpkBEAM,fpMciroA,fpMciroA_G,fpNanoA /*synthesis keep*/; //beam dc fp value in uA,nA
wire [DAC_WIDTH-1:0] DAC /*synthesis keep*/; //DAC code for beam dc value

wire [SF_WIDTH-1:0] NanoA32; //beam dc value 32 bit in nA
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

 
always@ (posedge clk) begin
		if(Data_In_Valid) begin RDY <= 1; I_val32 <= NanoA32; DAC_code <= {~DAC[15],DAC[14:0]}; end
		else RDY <= 0;	
end  //always

endmodule
