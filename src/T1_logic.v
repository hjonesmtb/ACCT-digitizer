`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// BL1A TARGET protect logic: based on document TNFSUM.doc,T1SUM.doc, T2SUM.doc;	    
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.12,2018
// last modified: January 17,2019
// Name-channel Mapping: 
// Note: channel is the Analog current input channel of 1039 module, TH_Index = Read_back index
//      
//Tabel 1: common for all T1,T2,TNF
// TH_Index channel Signal  Threshold(uA)    Signal_meaning     Notes
// readback_Index
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
                         
                     
//Tabel 2: Input signal to Interlock logic 
//Note: mask bit "1" means valid, i.e. is involved in the logic calculation
//!!! mask bit 0~12 are common for all T1,T2,TNF, and is the same as the Threshold index !!!
//!!! mask bit 13~ 15 are Specific to T1  !!!
// Mask_Index   Signal    Mask_TNF(default) Digi_channel
// 0             U_OK       1             
// 1             D_OK       1             
// 2             L_OK       1
// 3             R_OK       1
// 4             Halo_OK    1 
// 5             Den_OK     1
// 6             Tot_OK     1 
// 7             HV_OK      1
// 8             absLR_OK   1              
// 9             absUD_OK   1                         
// 10            absDT_OK   1                
// 11            SOT_OK     1              
// 12            TMS_OK     1              

// 13             T1VAC_OK   1              0
// 14             T2SUM_OK   1              1  
// 15             TNFSUM_OK  1              2




//Tabel 3: Mapping Backpanel channel to logic channel, using this table when connect physical signal cables.
//backpannel lables:
//Aanalog input: starting from left when facing to the backpanel: ch0, 1,2,to 7
//Relay output: starting from left, top row: ch0,1,2,3, bottom row: ch4,5,6,7
//Digi input: save as above Relay output, top row: ch0,1,2,3, bot row: ch4,5,6,7
//!!! Specific to T1  !!!
//Note: Analog input channel is already matched. The channels not mapped are not in use for T1 logic.
//The following table's 1st colomn is the backpanel channel number.
//It has been already mapped in top module to correct GPIO pins.
//Digi-in PCBch   Signal
// 0      2   	TNFSUM_OK
// 1      3   	T2SUM_OK
// 2      0   	
// 3      1   	T1VAC_OK
// 4      6   	Not defined
// 5      7   	Not defined
// 6      4   	Not defined
// 7      5   	Not defined

//Realy   PCBch   Signal
// 0        2     T1_SUMMARY
// 1        4     HALO_HV_En
// 2        6     T1_HV_En
// 3        0     not in use
// 4        3     T1SUM_SAFETY
// 5        5     T2SUM_SAFETY
// 6        7     TNFSUM_SAFETY
// 7        1     not in use

//////////////////////////////////////////////////////////////////////////////////
module T1_logic(
    input clk,   
	input rst,
	input [7:0] digi_in, //8 channel digital input
	input [15:0] mask,
	input [ADC_BIT_WIDTH-1:0] analog_in[7:0], //8 analog input, positive,in unit of 65.5nA  
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

////////////////////////////////////////////////////////
//Interlock Logic: 
// !!! Specific to T1 !!!

wire [15:0] absLR_value = (L_value > R_value)? L_value-R_value
                  : R_value-L_value;					
wire [15:0] absUD_value = (D_value > U_value)? D_value-U_value
                  : U_value-D_value;
wire [15:0] absDT_value = (Den_value > Tot_value)? Den_value-Tot_value
                  : Tot_value-Den_value;; 

//Assign digital input signal according to Table 2 above:
wire T1VAC_OK = digi_in[0];
wire T2SUM_OK = digi_in[1];
wire TNFSUM_OK = digi_in[2];

wire WD = 1'b1; //FPGA watchdog: so far I don't know what could be used, Dec.12,2018

wire L_OK = L_value < L_th;
wire R_OK = R_value < R_th;
wire D_OK = D_value < D_th;
wire U_OK = U_value < U_th;

wire [15:0] SUM_value = L_value + R_value + D_value + U_value;
wire [15:0] SOT_value = SUM_value/Tot_value;
wire [15:0] TMS_value = Tot_value - SUM_value; 


wire SOT_OK = SOT_value < SOT_th;
wire HALO_OK = Halo_value < Halo_th;
wire HV_OK = HV_value < HV_th;

wire Umask = ~mask[0];
wire Dmask = ~mask[1];
wire Lmask = ~mask[2];
wire Rmask = ~mask[3];
wire HALOmask = ~mask[4];
wire HVmask = ~mask[7];
wire SOTmask = ~mask[11];
wire TMSmask = ~mask[12];
wire T1VACmask = ~mask[13];
wire T2SUMmask = ~mask[14];
wire TNFSUMmask = ~mask[15];

 
//output relay contacts
wire T1_SUMMARY = WD & (L_OK|Lmask) & (R_OK|Rmask) & (D_OK|Dmask) & (U_OK|Umask) & (SOT_OK|SOTmask) & (HALO_OK|HALOmask) & (HV_OK|HVmask) & (T1VAC_OK|T1VACmask); 
wire T1SUM_OK = T1_SUMMARY;
wire HALO_HV_En = T1VAC_OK|T1VACmask;
wire T1_HV_En = T1VAC_OK|T1VACmask;
wire T1SUM_SAFETY = T1SUM_OK;
wire T2SUM_SAFETY = T2SUM_OK|T2SUMmask;
wire TNFSUM_SAFETY = TNFSUM_OK|TNFSUMmask;

assign relay[0] = T1_SUMMARY;
assign relay[1] = HALO_HV_En;
assign relay[2] = T1_HV_En;
assign relay[3] = 1'b0; //not in use, set to "0" to save power
assign relay[4] = T1SUM_SAFETY;
assign relay[5] = T2SUM_SAFETY;
assign relay[6] = TNFSUM_SAFETY ;
assign relay[7] = 1'b0; //not in use, set to "0" to save power



assign status[0] = WD;  
assign status[1] = L_OK;
assign status[2] = R_OK;  
assign status[3] = D_OK;  
assign status[4] = U_OK;  
assign status[5] = SOT_OK;  
assign status[6] = HALO_OK;  
assign status[7] = HV_OK;  
assign status[8] = T1VAC_OK;  
assign status[9] = T1SUM_OK;  
assign status[10] = T2SUM_OK;  
assign status[11] = TNFSUM_OK;  
assign status[16:12] = 5'b0; //not in use
assign status[17] = relay[0];
assign status[18] = relay[1];
assign status[19] = relay[2];
assign status[20] = relay[3];
assign status[21] = relay[4];
assign status[22] = relay[5];
assign status[23] = relay[6];
assign status[24] = relay[7];
assign status[31:25] = 7'b0;

assign fault = ~T1_SUMMARY; 
endmodule
