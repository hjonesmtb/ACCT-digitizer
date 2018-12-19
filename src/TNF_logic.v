`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// BL1A TARGET protect logic: based on document TNFSUM.doc,T1SUM.doc, T2SUM.doc;	    
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.12,2018
//
// Name-channel Mapping: 
// Note: channel is the Analog current input channel of 1039 module;
//      
//Tabel 1: common for all T1,T2,TNF
// TH_Index channel Signal  Threshold(uA)    Signal_meaning     Notes
// 0        0       U_value     U_th                            external input
// 1        1       D_value     D_th            
// 2        2       L_value     L_th            
// 3        3       R_value     R_th            
// 4        4       Halo_value  Halo_th         
// 5        5       Den_value   Den_th          
// 6        6       Tot_value   Tot_th                          external input
// 7        7       HV_value    HV_th          ProtectMonitorHV external input 
// 8                absLR_value LMR_th         |L-R|            calculated
// 9                absUD_value UMD_th         |U-D|            calculated
// 10               absDT_value DMT_th         |D-T|            calculated
// 11               SOT_value   SOT_th         Sum/Total        calculated     
// 12               TMS_value   TMS_th         Total-Sum        calculated             
                         
                     
//Tabel 2: Specific to TNF
// Mask_Index   Signal    Mask_TNF(default) Digi_channel
// 0             |L-R|_OK    1             
// 1             |D-U|_OK    1             
// 2             |D-T|_OK    1
// 3             Halo_OK     1
// 4             <30uA_OK    1 
// 5             <80uA_OK    1
// 6             HV_OK       1 
// 7             Prof_OK     1              0
// 8             Prot_OK     1              1           
// 9             TRIMAC_OK   1              2  
// 10            VAC_OK      1              3



//////////////////////////////////////////////////////////////////////////////////
module TNF_logic(
    input clk,   
	input rst,
	input [7:0] digi_in, //8 channel digital input
	input [15:0] mask,
	input [ADC_BIT_WIDTH-1:0] analog_in[7:0], //8 analog input  
	input [ADC_BIT_WIDTH-1:0] thresh[15:0], //16 trip threshold 
	
	output [ADC_BIT_WIDTH-1:0] readback[15:0], //16 analog values for read back	
	output [31:0] status,  //legacy: 32 bit status 
	output [7:0] relay,
	output fault     

    );

parameter  	ADC_BIT_WIDTH = 16;
//parameter  	SF_WIDTH = 32;

//Assign monitor ananolg signal according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
wire [ADC_BIT_WIDTH-1:0] U_value = analog_in[0];
wire [ADC_BIT_WIDTH-1:0] D_value = analog_in[1];
wire [ADC_BIT_WIDTH-1:0] L_value = analog_in[2];
wire [ADC_BIT_WIDTH-1:0] R_value = analog_in[3];
wire [ADC_BIT_WIDTH-1:0] Halo_value = analog_in[4];
wire [ADC_BIT_WIDTH-1:0] Den_value = analog_in[5];
wire [ADC_BIT_WIDTH-1:0] Tot_value = analog_in[6];
wire [ADC_BIT_WIDTH-1:0] HV_value = analog_in[7];

//Assign threshold according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
wire [ADC_BIT_WIDTH-1:0] U_th = thresh[0];
wire [ADC_BIT_WIDTH-1:0] D_th = thresh[1];
wire [ADC_BIT_WIDTH-1:0] L_th = thresh[2];
wire [ADC_BIT_WIDTH-1:0] R_th = thresh[3];
wire [ADC_BIT_WIDTH-1:0] Halo_th = thresh[4];
wire [ADC_BIT_WIDTH-1:0] Den_th = thresh[5];
wire [ADC_BIT_WIDTH-1:0] Tot_th = thresh[6];
wire [ADC_BIT_WIDTH-1:0] HV_th = thresh[7];
wire [ADC_BIT_WIDTH-1:0] LMR_th = thresh[8];
wire [ADC_BIT_WIDTH-1:0] UMD_th = thresh[9];
wire [ADC_BIT_WIDTH-1:0] DMT_th = thresh[10];
wire [ADC_BIT_WIDTH-1:0] SOT_th = thresh[11];
wire [ADC_BIT_WIDTH-1:0] TMS_th = thresh[12];

//Assign read_back according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
assign readback[0] = U_value;
assign readback[1] = D_value;
assign readback[2] = L_value;
assign readback[3] = R_value;
assign readback[4] = Halo_value;
assign readback[5] = Den_value;
assign readback[6] = Tot_value;
assign readback[7] = HV_value;
assign readback[8] = absLR_value;
assign readback[9] = absUD_value;
assign readback[10] = absDT_value;
assign readback[11] = SOT_value;
assign readback[12] = TMS_value; 

//Assign digital input signal according to Table 2 above:
wire Prof_OK = digi_in[0];
wire Prot_OK = digi_in[1];
wire TRIMAC_OK = digi_in[2];
wire VAC_OK = digi_in[3];



////////////////////////////////////////////////////////
wire WD = 1'b1; //FPGA watchdog: so far I don't know what could be used, Dec.12,2018
wire [15:0] absLR_value = (L_value > R_value)? (L_value-R_value)
                  : (R_value-L_value);								
wire absLR_OK  = absLR_value < LMR_th;

wire [15:0] absUD_value = (D_value-U_value)? (D_value-U_value)
                  : (U_value-D_value);
wire absDU_OK  = absUD_value < UMD_th;

wire [15:0] absDT_value = (Den_value-Tot_value)? (Den_value-Tot_value)
                  : (Tot_value-Den_value);
wire absDT_OK  = absDT_value < DMT_th;

wire [15:0] TMS_value = 16'b0; 
wire [15:0] SOT_value = 16'b0; 

  
wire Halo_OK = Halo_value < Halo_th;
wire T30uA_OK = Tot_value < 30;
wire T80uA_OK = Tot_value < 80;
wire HV_OK = HV_value < HV_th;

wire TNF_SUM1 = WD & absLR_OK & absDU_OK & absDT_OK & Halo_OK & T80uA_OK & HV_OK & TRIMAC_OK & VAC_OK; 
wire TNF_SUM2 = (T30uA_OK | ~Prof_OK) & (Prof_OK ^ Prot_OK);  
wire TNF_SUMMARY = TNF_SUM1 & TNF_SUM2;

	
wire Prof_HV_En = Prof_OK;
wire Prot_HV_En = Prot_OK;
wire DT_en = absDT_OK;
wire T80uA_en = T80uA_OK;
wire T30uA_en = (T30uA_OK | ~Prof_OK);
wire Prof_Prot_en = (Prof_OK ^ Prot_OK);


assign relay[0] = TNF_SUMMARY;
assign relay[1] = Prof_OK;
assign relay[2] = Prot_OK;
assign relay[3] = absDT_OK;
assign relay[4] = T80uA_OK;
assign relay[5] = (T30uA_OK | ~Prof_OK);
assign relay[6] = (Prof_OK ^ Prot_OK);

assign relay[7] = 1'b1; //not in use

assign status[0] = WD;  
assign status[1] = absLR_OK;
assign status[2] = absDU_OK;  
assign status[3] = absDT_OK;  
assign status[4] = Halo_OK;  
assign status[5] = T30uA_OK;  
assign status[6] = T80uA_OK;  
assign status[7] = HV_OK;  

assign status[8] = Prof_OK;  
assign status[9] = Prot_OK;  
assign status[10] = TRIMAC_OK;  
assign status[11] = VAC_OK;  

assign status[16:12] = 5'b0; //not in use

assign status[17] = relay[0];
assign status[18] = relay[1];
assign status[19] = relay[2];
assign status[20] = relay[3];
assign status[21] = relay[4];
assign status[22] = relay[5];
assign status[23] = relay[6];

assign status[31:24] = 8'b0;

assign fault = ~&relay; //= 1,only when realy bits are all 1

endmodule
