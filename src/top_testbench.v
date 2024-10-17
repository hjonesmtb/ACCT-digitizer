`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Testbench for  simulation with Modelsim_Altera starter 10.5b, compatible to Quaruts Prime standard 18.00
// SL, June 26,2019
// it's best to run Modelsim seperately, there's a Modelsim project has been created.
//////////////////////////////////////////////////////////////////////////////////
module tb();

parameter  	ADC_BIT_WIDTH = 16;
parameter  	SF_WIDTH = 32;

parameter   FP100 = 32'h42c80000;
parameter   FP200 = 32'h43480000;

wire [SF_WIDTH-1:0] fpVLP;
wire [SF_WIDTH-1:0] fpBL;
wire [SF_WIDTH-1:0] fp_add_result;

wire [ADC_BIT_WIDTH-1:0] VLP, BL;

 

reg sclk = 0, clk = 0 ;
reg rst;
reg Data_Valid;
reg enable_pulse_gen;
wire [31:0] data32;
reg  [15:0] data; 
//assign data = {data32[31],data32[14:0]};

//fclk = 20MHz 
always
	#25 clk = ~clk;
//sclk = 0.5MHz 
always
	#1000 sclk = ~sclk;
	
/*
pulse pulse_inst
  (  
   .dclk(clk),
   .reset_n(~rst),
   .enable(enable_pulse_gen),
   .db(data32)
	);	 
	 
	 
altfp_int2fp conv_inst1 (.dataa(db), .clock(clk), .result(fpVLP));   

dc_restore dc_restore_inst(
    .FCLK(clk),
    .in_valid(Data_Valid), 
    .rst(rst),	 
    .VLP(fpVLP),
    .VMIN(fpBL)
    );

altfp_fp2int conv_inst2 (.dataa(fpVLP), .clock(clk), .result(VLP));  
altfp_fp2int conv_inst3 (.dataa(fpBL), .clock(clk), .result(BL));  

*/

	
boxfilter bf_inst(
    .clk(clk),
    .in_valid(Data_Valid),   
    .rst(rst),
	 .window(4), //search window size
	 	 
    .data_in(data), //input data 
	
    .data_out(), //output data, with BL substraced
	.BL(), //base line
	.overflow() //calculation overflow 

    );
	
/////////////////////////////////////////
//test start here

integer rand10;
integer acc,acc1,acc2,acc3,acc4; 
reg enable_data;
reg [10:0] cnt;
parameter TPoints = 500; //points per period
parameter Amp = 1000;

always @(posedge sclk & enable_data)
	begin 
		Data_Valid <= 1; 
		rand10 = $random%10; 
		if (cnt < 100) data <= rand10;
		else if (cnt < 160) data <= Amp + rand10;
		else if (cnt < TPoints) data <= rand10; 
		if (cnt > TPoints) cnt <= 0;
		else cnt <= cnt + 1;
		 
		#50 Data_Valid <= 0; 
	end

initial begin
	$display($time, " << Starting Simulation >> ");
	cnt <= 0;
	rst <= 1;  Data_Valid <= 0;
	enable_data <= 0;

	@(posedge sclk) begin rst <= 0; enable_data <= 1; end
	
	
	#24000;
	
	$display($time, "<< Simulation Complete >>");
	//$stop;
	
end //intital 

endmodule

