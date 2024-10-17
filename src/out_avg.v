`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// 
module out_avg(
    input clk,
    input in_valid,   

	 input [31:0] fp_data_in,
	 input [1:0] OUTAVG_MODE, //
	 
    output reg [31:0] fp_data_out

    );
 
parameter  SF_WIDTH = 32;

parameter K1 = 32'h3e800000; // 1/4 in SF format
parameter K2 = 32'h3e000000; // 1/8 in SF format
parameter K3 = 32'h3d800000; // 1/16 in SF format
parameter K4 = 32'h3d000000; // 1/32 in SF format

//parameter K4 = 32'h3b800000; // 1/256

reg [SF_WIDTH-1:0] acc;
wire [SF_WIDTH-1:0] S2,Avg;

reg [7:0] cnt;

wire [7:0] AVG_TIMES = (OUTAVG_MODE == 2'b00)? 4 : 
                       (OUTAVG_MODE == 2'b01)? 8 :
							  (OUTAVG_MODE == 2'b10)? 16 :
							  (OUTAVG_MODE == 2'b11)? 32 : 4;
								  
wire [SF_WIDTH-1:0] 	K = (OUTAVG_MODE == 2'b00)?  K1 : 
								 (OUTAVG_MODE == 2'b01)?  K2 : 
								 (OUTAVG_MODE == 2'b10)?  K3 : 
								 (OUTAVG_MODE == 2'b11)?  K4 : K1;

altfp_add add_inst1 (.dataa(fp_data_in), .datab(acc), .clock(clk), .result(S2) ); 
altfp_mul mul_inst1 (.dataa(S2), .datab(K), .clock(clk), .result(Avg) );    
					
always @ (posedge clk)
if (in_valid) 
	begin
		if (cnt >= AVG_TIMES-1) 
			  begin 
					fp_data_out <= Avg;  //Avg
					acc <= 0; cnt <= 0; 
			  end
		else 
			  begin
				   acc <= S2;
			      cnt <= cnt +1;
			  end
	end
	
	
endmodule	 