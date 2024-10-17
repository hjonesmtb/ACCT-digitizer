`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// LPF2_IIR:  2nd oder Butterworth, calculated from :
// https://www-users.cs.york.ac.uk/~fisher/cgi-bin/mkfscript
// Shengli Liu, Diagnostics, TRIUMF
// May 3,2020



module LPF_3th_IIR(
    input FCLK,
    input in_valid,   

	input [31:0] data_in,
	
	//input [31:0] K1, //fixed point coeff.
	//input [31:0] K2, //fixed point coeff.
	 
    output reg [31:0] data_out

    );
 
parameter  SF_WIDTH = 32;

/*
//-------------------------------------------------------
//for Sampling Period = 4 ms, 3nd order, f(3db)=1 Hz
// this LPF has been tested OK, May 04,2020

parameter a2 = 32'h40400000; //3
parameter a1 = 32'h40400000; //3

parameter b3 = 32'h3f737324; //0.9509756650
parameter b2 = 32'hc039a583;//-2.9007269884
parameter b1 = 32'h403cc879; //2.9497358397

parameter G = 32'h3601e2d9; //gain = 
//--------------------------------------------------------
*/


//-------------------------------------------------------
//for Sampling Period = 0.86749 us, 3nd order, f(3db)=65.471 KHz

parameter a2 = 32'h40400000; //3
parameter a1 = 32'h40400000; //3

parameter b3 = 32'h3ef9cef0; //0.4879069313
parameter b2 = 32'hbfe7bcd9;//-1.8104506515
parameter b1 = 32'h40128b84; //2.2897653600

parameter G = 32'h3b86429a; //gain = 
//--------------------------------------------------------


wire [SF_WIDTH-1:0] X,Y,Y_scale;
reg [SF_WIDTH-1:0] X1,X2,X3,X4,X5,Y1,Y2,Y3,Y4,Y5;

wire [SF_WIDTH-1:0] Y1b,Y2b,Y3b,Y4b,Y5b,X1a,X2a,X3a,X4a,X5a;
wire [SF_WIDTH-1:0] XS1,XS2,XS3,XS4,XS5;
wire [SF_WIDTH-1:0] YS1,YS2,YS3,YS4;

assign X = data_in;

altfp_mul ymul_inst1 (.dataa(Y1), .datab(b1), .clock(FCLK), .result(Y1b) );   
altfp_mul ymul_inst2 (.dataa(Y2), .datab(b2), .clock(FCLK), .result(Y2b) );    	 
altfp_mul ymul_inst3 (.dataa(Y3), .datab(b3), .clock(FCLK), .result(Y3b) );    	 

altfp_mul xmul_inst1 (.dataa(X1), .datab(a1), .clock(FCLK), .result(X1a) );    
altfp_mul xmul_inst2 (.dataa(X2), .datab(a2), .clock(FCLK), .result(X2a) );   	 

altfp_add xadd_inst1 (.dataa(X3), .datab(X2a), .clock(FCLK), .result(XS1) ); 
altfp_add xadd_inst2 (.dataa(XS1), .datab(X1a), .clock(FCLK), .result(XS2) ); 
altfp_add xadd_inst3 (.dataa(XS2), .datab(X), .clock(FCLK), .result(XS3) ); 

altfp_add yadd_inst1 (.dataa(Y3b), .datab(Y2b), .clock(FCLK), .result(YS1) ); 
altfp_add yadd_inst2 (.dataa(YS1), .datab(Y1b), .clock(FCLK), .result(YS2) ); 
altfp_add yadd_inst3 (.dataa(YS2), .datab(XS3), .clock(FCLK), .result(Y) ); 

altfp_mul smul_inst1 (.dataa(Y), .datab(G), .clock(FCLK), .result(Y_scale) );    	 


always @(posedge FCLK)  
begin 
    if (in_valid) 
       begin data_out <= Y_scale;
             X1 <= X; X2 <= X1; X3 <= X2;
             Y1 <= Y; Y2 <= Y1; Y3 <= Y2;           
       end
end //always
 
endmodule