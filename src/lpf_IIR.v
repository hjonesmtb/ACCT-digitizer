`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// LPF_IIR:  based on Bill R. lowpass5.bdf of UCN BPM Module 1012 processor
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on June 20,2019
// last modified: 
// January/04/2023: added recover from overflow:NAN

module LPF_IIR(
    input FCLK,
    input in_valid,   

	input [31:0] data_in,
	
	input [31:0] K1, //fixed point coeff.
	input [31:0] K2, //fixed point coeff.
	 
    output  [31:0] data_out

    );
 
parameter  SF_WIDTH = 32;

//info: 
//single pole IIR LPF: 

//first order IIR LPF: 
// difference equation: y[n] = (1-d)*x[n] + d*y[n-1]
// d is called decay factor
// d = e^(-1/tao), tao = 1/(2Pi*Fc); tao is called time constant, Fc is normalized 3dB
// frequency.
// T: sampling period
// tao*T is the time constant is second;
// Fc/T is the 3dB frequnecy is Hz.

//Y[n] = K2*Y[n-1] + K1*X[n], abs(K1)+abs(K2) = 1, HPF: K2 = (-1,0), LPF: K2 = (0,1);  
//K2 = e^(-1/tao) = e^(-2pi*Fc), tao is time constant, Fc is the 3dB frequency.
//so tao = -1/ln(K2), Fc = -ln(K2)/2pi;

// 2^24 = 16,777,216

//input filter default:
//parameter K1 = 32'd1677722;  //0.1 = 1677722/2^24
//parameter K2 = 32'd15099494; //0.9 = 15099494/2^24

//-----------------------------------------------------
// Calculate the Tc (time constant in Second), BW:
// The T sampling period is not necessary ADC rate, it depends on the rate of "in_valid";
// for SA method, T = AvgTimes (ms), ie 4,8,16,32,64,128,..., ms
// tao = -1/ln(K2), 
// Tc = tao*T = [-1/ln(K2)] * T ;
// for AvgTimes = 4, then T = 4 ms, following is using this T:
// K2 = 0.9, Tc = [-1/ln(0.9)] * 4 = 38 ms; 
// K2 = 0.99, Tc = [-1/ln(0.99)] * 4 = 400 ms; 
// K2 = 0.999, Tc = [-1/ln(0.999)] * 4 = 4000 ms; 
//---------------------------------------------------------

wire nan1,nan2,nan3/*synthesis keep*/;
wire overflow = nan1 | nan2 | nan3;


wire [SF_WIDTH-1:0] fpK1/*synthesis keep*/;
wire [SF_WIDTH-1:0] fpK2/*synthesis keep*/;

wire [SF_WIDTH-1:0] X,Y,XK,Y1K;
reg [SF_WIDTH-1:0] Y1;

assign X = data_in;
assign data_out = Y;

/*
altfp_fx2fp_gate conv_inst1 (.dataa(K1), .clk_en(in_valid), .clock(FCLK), .result(fpK1)); 
altfp_fx2fp_gate conv_inst2 (.dataa(K2), .clk_en(in_valid), .clock(FCLK), .result(fpK2)); 

altfp_mul_gate mul_inst1 (.dataa(data_in), .datab(fpK1), .clk_en(in_valid), .clock(FCLK), .result(S1) );   
altfp_mul_gate mul_inst2 (.dataa(data_out), .datab(fpK2), .clk_en(in_valid), .clock(FCLK), .result(FB) );    	 

altfp_add_gate add_inst1 (.dataa(S1), .datab(FB), .clk_en(in_valid), .clock(FCLK), .result(S2) );
*/

altfp_fx2fp conv_inst1 (.dataa(K1), .clock(FCLK), .result(fpK1)); 
altfp_fx2fp conv_inst2 (.dataa(K2), .clock(FCLK), .result(fpK2)); 

altfp_mul mul_inst1 (.dataa(X), .datab(fpK1), .clock(FCLK), .nan(nan1), .result(XK) );   
altfp_mul mul_inst2 (.dataa(Y1), .datab(fpK2), .clock(FCLK), .nan(nan2), .result(Y1K) );    	 

altfp_add add_inst1 (.dataa(XK), .datab(Y1K), .clock(FCLK), .nan(nan3), .result(Y) ); 

always @(posedge FCLK)  
  begin 
   if (overflow) Y1 <= 32'd0;
      else 
        if (in_valid) begin Y1 <= Y; end
  end

endmodule