`timescale 1ns / 1ps
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// DC_RESTORE:  based on Bill R. DC_RESTORE.bdf of UCN BPM Module 1012 processor
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on June 20,2019
// last modified: 
// 
module dc_restore(
    input FCLK,
    input in_valid,   
    input rst,
	 input [31:0] PULL_UP, //fixed point f8.24
	 input [31:0] PULL_DN, //fixed point f8.24
	 
    input [31:0] VLP,
	
    output reg [31:0] VMIN

    );
 
parameter  SF_WIDTH = 32;

//PULL VMIN UP SLOWLY COMPARED TO
//THE 1 mS MAXIMUM BEAM PULSE WIDTH
//THE CONSTANT IS THE FRACTION OF (VLP - VMIN) PER uS
//(VLP - VMIN) WILL BE POSITIVE WHEN THIS PULL IS SELECTED
//weight = sample time / time constant, 8-bit mantissa, 24-bit fraction
//1 us / 20 ms = 5e-5,  5e-5 * 2^24 = 839

//parameter PULL_UP = 32'd839; 

//PULL VMIN DOWN QUICKLY COMPARED TO
//THE 50 uS MINIMUM BEAM HOLE WIDTH
//THE CONSTANT IS IN DAC/uS AND ADC IS 2^12/2 DAC/V
//(VLP - VMIN) WILL BE NEGATIVE WHEN THIS PULL IS SELECTED
//weight = sample time / time constant, 8-bit mantissa, 24-bit fraction
//1 us / 20 us = 0.05,  0.05 * 2^24 = 838860

//parameter PULL_DN = 32'd838860;

wire [SF_WIDTH-1:0] VLP_sub /*synthesis keep*/;
wire [SF_WIDTH-1:0] pull_up_fp,pull_dn_fp /*synthesis keep*/;
wire [SF_WIDTH-1:0] VLP_up,VLP_dn /*synthesis keep*/;
wire [SF_WIDTH-1:0] VLP_up_new,VLP_dn_new /*synthesis keep*/;
wire [SF_WIDTH-1:0] VMIN_buf /*synthesis keep*/;
wire [1:0] MUX /*synthesis keep*/; 

altfp_comp comp_inst1 (.dataa(VLP), .datab(VMIN), .clock(FCLK), .aeb(), .agb(MUX[1]), .alb(MUX[0]) ); //Latency = 3 
altfp_sub inst1 (.dataa(VLP), .datab(VMIN), .clock(FCLK), .result(VLP_sub) ); //Latency = 7 

altfp_fx2fp conv_inst1 (.dataa(PULL_UP), .clock(FCLK), .result(pull_up_fp));  //Latency = 1 
altfp_fx2fp conv_inst2 (.dataa(PULL_DN), .clock(FCLK), .result(pull_dn_fp));  //Latency = 1 

altfp_mul mul_inst1 (.dataa(VLP_sub), .datab(pull_up_fp), .clock(FCLK), .result(VLP_up) ); //Latency = 5   
altfp_mul mul_inst2 (.dataa(VLP_sub), .datab(pull_dn_fp), .clock(FCLK), .result(VLP_dn) ); //Latency = 5    	 

altfp_add add_inst1 (.dataa(VMIN), .datab(VLP_up), .clock(FCLK), .result(VLP_up_new) ); //Latency = 7 
altfp_add add_inst2 (.dataa(VMIN), .datab(VLP_dn), .clock(FCLK), .result(VLP_dn_new) ); //Latency = 7 

assign VMIN_buf = (MUX == 2'b01)? VLP_dn_new :      
                  (MUX == 2'b10)? VLP_up_new : 
                  (MUX == 2'b00)? VMIN: 32'b0; 

always @(posedge FCLK)  
begin 
    if (rst) VMIN <=  32'b0;
    else if (in_valid) VMIN <=  VMIN_buf;
end 
 
 
endmodule