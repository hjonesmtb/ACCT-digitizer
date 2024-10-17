`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// LPF2_IIR:  2nd oder Butterworth, calculated from :
// https://www-users.cs.york.ac.uk/~fisher/cgi-bin/mkfscript
// Shengli Liu, Diagnostics, TRIUMF
// May 3,2020
// so far, this module is not working. May 04,2020,17:22. 


module LPF2_IIR(
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
parameter a5 = 0; 
parameter a4 = 0; 
parameter a3 = 0;
parameter a2 = 32'h3f800000; //1
parameter a1 = 32'h40000000; //2
parameter a0 = 32'h3f800000; //1

parameter b5 = 0; 
parameter b4 = 0; 
parameter b3 = 0; 
parameter b2 = 32'hbf770f8f; //-0.9650811739
parameter b1 = 32'h3ffb7372; //1.9644605802

parameter G = 32'h3922af56; //gain = 1/6.445440937e+03
//--------------------------------------------------------
*/

//---------------------------------------------
//for Ts=64ms, 5th, f(3db)=1Hz:
parameter a5 = 32'h3f800000; //1
parameter a4 = 32'h40a00000; //5
parameter a3 = 32'h41200000; //10
parameter a2 = 32'h41200000; //10
parameter a1 = 32'h40a00000; //5
parameter a0 = 32'h3f800000; //1

parameter b5 = 32'h3e89d536; //
parameter b4 = 32'hbfd90c33; //
parameter b3 = 32'h408a81b0; //
parameter b2 = 32'hc0b37b83; //
parameter b1 = 32'h406cdf6d; //

parameter G = 32'h393f59e3; //gain 
//---------------------------------------------

wire [SF_WIDTH-1:0] X,Y,Y_scale/*synthesis keep*/;
reg [SF_WIDTH-1:0] X1,X2,X3,X4,X5,Y1,Y2,Y3,Y4,Y5/*synthesis keep*/;

wire [SF_WIDTH-1:0] Y1b,Y2b,Y3b,Y4b,Y5b,X0a,X1a,X2a,X3a,X4a,X5a/*synthesis keep*/;
wire [SF_WIDTH-1:0] XS1,XS2,XS3,XS4,XS5/*synthesis keep*/;
wire [SF_WIDTH-1:0] YS1,YS2,YS3,YS4/*synthesis keep*/;
wire NaN/*synthesis keep*/; 

assign X = data_in;

altfp_mul ymul_inst1 (.dataa(Y1), .datab(b1), .clock(FCLK), .result(Y1b), .nan(NaN) );   
altfp_mul ymul_inst2 (.dataa(Y2), .datab(b2), .clock(FCLK), .result(Y2b) );    	 
altfp_mul ymul_inst3 (.dataa(Y3), .datab(b3), .clock(FCLK), .result(Y3b) );   
altfp_mul ymul_inst4 (.dataa(Y4), .datab(b4), .clock(FCLK), .result(Y4b) );    	 
altfp_mul ymul_inst5 (.dataa(Y5), .datab(b5), .clock(FCLK), .result(Y5b) );    	 

altfp_mul xmul_inst0 (.dataa(X),  .datab(a0), .clock(FCLK), .result(X0a) );    	 
altfp_mul xmul_inst1 (.dataa(X1), .datab(a1), .clock(FCLK), .result(X1a) );    	 
altfp_mul xmul_inst2 (.dataa(X2), .datab(a2), .clock(FCLK), .result(X2a) );    	 
altfp_mul xmul_inst3 (.dataa(X3), .datab(a3), .clock(FCLK), .result(X3a) );    	 
altfp_mul xmul_inst4 (.dataa(X4), .datab(a4), .clock(FCLK), .result(X4a) );    	 
altfp_mul xmul_inst5 (.dataa(X5), .datab(a5), .clock(FCLK), .result(X5a) );    	 

altfp_add xadd_inst1 (.dataa(X5a), .datab(X4a), .clock(FCLK), .result(XS1) ); 
altfp_add xadd_inst2 (.dataa(XS1), .datab(X3a), .clock(FCLK), .result(XS2) ); 
altfp_add xadd_inst3 (.dataa(XS2), .datab(X2a), .clock(FCLK), .result(XS3) ); 
altfp_add xadd_inst4 (.dataa(XS3), .datab(X1a), .clock(FCLK), .result(XS4) ); 
altfp_add xadd_inst5 (.dataa(XS4), .datab(X0a), .clock(FCLK), .result(XS5) ); 

altfp_add yadd_inst1 (.dataa(Y5b), .datab(Y4b), .clock(FCLK), .result(YS1) ); 
altfp_add yadd_inst2 (.dataa(YS1), .datab(Y3b), .clock(FCLK), .result(YS2) ); 
altfp_add yadd_inst3 (.dataa(YS2), .datab(Y2b), .clock(FCLK), .result(YS3) ); 
altfp_add yadd_inst4 (.dataa(YS3), .datab(Y1b), .clock(FCLK), .result(YS4) ); 
altfp_add yadd_inst5 (.dataa(YS4), .datab(XS5), .clock(FCLK), .result(Y) ); 

altfp_mul smul_inst1 (.dataa(Y), .datab(G), .clock(FCLK), .result(Y_scale) );    	 

always @(posedge FCLK)  
begin 
    if (in_valid) 
       begin 
		 if (NaN) begin 
						data_out <= 0;
						X1 <= 0; X2 <= 0; X3 <= 0; X4 <= 0; X5 <= 0;
						Y1 <= 0; Y2 <= 0; Y3 <= 0; Y4 <= 0; Y5 <= 0; 
					 end
		  else begin
						data_out <= Y_scale;
						X1 <= X; X2 <= X1; X3 <= X2; X4 <= X3; X5 <= X4;
						Y1 <= Y; Y2 <= Y1; Y3 <= Y2; Y4 <= Y3; Y5 <= Y4; 
		       end
            				 
       end
end //always
 
endmodule