`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// LPF2_IIR:  2nd oder Butterworth, calculated from :
// https://www-users.cs.york.ac.uk/~fisher/cgi-bin/mkfscript
// Shengli Liu, Diagnostics, TRIUMF
// May 3,2020



module LPF_2th_IIR(
    input FCLK,
    input in_valid,   

	input [31:0] data_in,
	
	//input [31:0] K1, //fixed point coeff.
	//input [31:0] K2, //fixed point coeff.
	 
    output reg [31:0] data_out

    );
 
parameter  SF_WIDTH = 32;

/*------------------------------------------------
// for sampling period = 32 ms, 2nd order, 1Hz:
parameter fpK1 = 32'hbf40a4e7; //-0.7525161816
parameter fpK2 = 32'h3fdbcd99; //1.7172118349
parameter fpK3 = 32'h40000000; //2
parameter fpG = 32'h3c109b4a; //=1/113.3004963, 1/gain
//-----------------------------------------------
*/

/*
//-------------------------------------------------------
//for Sampling Period = 4 ms, 2nd order, f(3db)=1 Hz


parameter a1 = 32'h40000000; //2

parameter b2 = 32'hbf770f8f; //-0.9650811739
parameter b1 = 32'h3ffb7372; //1.9644605802

parameter G = 32'h3922af56; //gain = 1/6.445440937e+03
//--------------------------------------------------------
*/

//-------------------------------------------------------
//for Sampling Period = 64 ms, 2nd order, f(3db)=1 Hz


parameter a1 = 32'h40000000; //2

parameter b2 = 32'hbf11053a; //-0.5664860047
parameter b1 = 32'h3fb88411; //1.4415303099

parameter G = 32'h3cffe8c5; //gain = 1/3.201134617e+01

//--------------------------------------------------------






wire [SF_WIDTH-1:0] X,Y,Y_scale;
reg [SF_WIDTH-1:0] X1,X2,X3,X4,X5,Y1,Y2,Y3,Y4,Y5;

wire [SF_WIDTH-1:0] Y1b,Y2b,Y3b,Y4b,Y5b,X1a,X2a,X3a,X4a,X5a;
wire [SF_WIDTH-1:0] XS1,XS2,XS3,XS4,XS5;
wire [SF_WIDTH-1:0] YS1,YS2,YS3,YS4;

assign X = data_in;

altfp_mul ymul_inst1 (.dataa(Y1), .datab(b1), .clock(FCLK), .result(Y1b) );   
altfp_mul ymul_inst2 (.dataa(Y2), .datab(b2), .clock(FCLK), .result(Y2b) );    	 

altfp_mul xmul_inst1 (.dataa(X1), .datab(a1), .clock(FCLK), .result(X1a) );    	 

altfp_add xadd_inst1 (.dataa(X2), .datab(X1a), .clock(FCLK), .result(XS1) ); 
altfp_add xadd_inst2 (.dataa(XS1), .datab(X), .clock(FCLK), .result(XS2) ); 

altfp_add yadd_inst1 (.dataa(Y2b), .datab(Y1b), .clock(FCLK), .result(YS1) ); 
altfp_add yadd_inst2 (.dataa(YS1), .datab(XS2), .clock(FCLK), .result(Y) ); 

altfp_mul smul_inst1 (.dataa(Y), .datab(G), .clock(FCLK), .result(Y_scale) );    	 


always @(posedge FCLK)  
begin 
    if (in_valid) 
       begin data_out <= Y_scale;
             X1 <= X; X2 <= X1; 
             Y1 <= Y; Y2 <= Y1;            
       end
end //always
 
endmodule