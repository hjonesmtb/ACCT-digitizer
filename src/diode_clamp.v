`timescale 1ns / 1ps
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// Diode_Clamp: based on 0531A schematics D-13152A Rev.1, Matlab simulation DC_restore.m
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.08,2022
// last modified: 
// 
module diode_clamp(
    input FCLK,
    input in_valid, 
	 input [31:0] DIODE_TH,     //threshold
	 input [31:0] DIODE_NCrev,  //negtive reverse of C
	 input [31:0] DIODE_R1rev, //reverse of R1
    input [31:0] DIODE_R2rev, //sf, the reverse of the diode conducting resistiance 
	 
	 input [31:0] Vin, //sf
	 	
    output reg [31:0] Vdc //sf

    );
 
parameter  SF_WIDTH = 32;

//        Ic = Vdc(i)/R2; %charging current through R2=10 Mohm
//                 
//        if (Vdc(i) < DTH) Id = Vdc(i)/R1; %discharging current through Diode
//        else Id = 0;
//        end
        
//        Q(i+1) = Q(i) + t_sample*(Ic+Id); 
//        Vc(i+1) = -Q(i+1)/C;
//        Vdc(i+1) = Vin(i) + Vc(i+1); 
        
//parameter R2_rev = 32'h33d6bf95; //1e-7, for reverse of 10 Mohm R2.
//parameter C_rev = 32'hce1f0673;  //SF, -6.67e+8, neg reverse of the Capacitance 0.0015 uF, -1/C.

parameter DT = 32'h3568dd75; //ADC sampling T=0.86749e-6 s
//parameter SCALE = 32'h39200000; //ADC scaling factor = 5/32768, convert ADC value to Volts.
parameter FP1 = 32'h3f800000; //

wire [SF_WIDTH-1:0] Ic,Id, Icd, I, Vdc2, Vexp, Vexp1,DQ, DVC/*synthesis keep*/;
wire [SF_WIDTH-1:0] Vc_buf, Vdc_buf /*synthesis keep*/;
reg  [SF_WIDTH-1:0] Vc /*synthesis keep*/;
wire nan1,nan2,nan3,nan4,nan5/*synthesis keep*/;
wire overflow /*synthesis keep*/; 
assign overflow = nan1 | nan2 | nan3 | nan4 | nan5;

altfp_mul mul_inst1 (.dataa(Vdc), .datab(DIODE_R2rev), .clock(FCLK), .nan(nan1), .result(Ic) ); //Latency = 5   

//below is the linear model for diode : I = K*V, using R1 = 1000 to 4500
//altfp_mul mul_inst2 (.dataa(Vdc), .datab(DIODE_R1rev), .clock(FCLK), .nan(nan2), .result(Id) ); //Latency = 5  

//below is the power model for diode: I = K*V^2, note: using R1= -1e+6
//altfp_mul mul_inst2 (.dataa(Vdc), .datab(Vdc), .clock(FCLK), .nan(nan2), .result(Vdc2) ); //Latency = 5  
//altfp_mul mul_inst0 (.dataa(Vdc2), .datab(DIODE_R1rev), .clock(FCLK), .nan(nan5), .result(Id) ); //Latency = 5  

//below is the exp model for diode: I = K*(Exp(V)-1), using R1=???
altfp_exp exp_inst0 (.data(Vdc), .clock(FCLK), .nan(nan2), .result(Vexp) ); //Latency = 5  
altfp_sub sub_inst0 (.dataa(Vexp), .datab(FP1), .clock(clk), .result(Vexp1) ); //Latency = 7  
altfp_mul mul_inst0 (.dataa(Vexp1), .datab(DIODE_R1rev), .clock(FCLK), .nan(nan5), .result(Id) ); //Latency = 5  


//

altfp_add add_inst1 (.dataa(Ic), .datab(Id), .clock(FCLK), .result(Icd) ); //Latency = 7 

wire BelowTh/*synthesis keep*/;

altfp_comp comp_inst1 (.dataa(Vdc), .datab(DIODE_TH), .clock(FCLK), .aeb(), .agb(), .alb(BelowTh) ); //Latency = 3 

assign I = BelowTh? Icd : Ic ; 

altfp_mul mul_inst3 (.dataa(DT), .datab(I), .clock(FCLK), .nan(nan3), .result(DQ) ); //Latency = 5  
altfp_mul mul_inst4 (.dataa(DQ), .datab(DIODE_NCrev), .clock(FCLK), .nan(nan4), .result(DVC) ); //Latency = 5  
altfp_add add_inst2 (.dataa(Vc), .datab(DVC), .clock(FCLK), .result(Vc_buf) ); //Latency = 7
altfp_add add_inst3 (.dataa(Vin), .datab(Vc_buf), .clock(FCLK), .result(Vdc_buf) ); //Latency = 7

always @(posedge FCLK)  
  begin 
    if (overflow) begin Vdc <= 32'd0; Vc <= 32'd0; end
    else 
	   if (in_valid) begin Vdc <= Vdc_buf; Vc <= Vc_buf; end
  end 
 
endmodule