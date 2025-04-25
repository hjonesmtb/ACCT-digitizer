`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
//	Channel block: encapsulating the logic for one channel
// by: Shengli Liu, Diagnostics, TRIUMF
/*
 * Modification history:
 * Apr.29,2020: added clk_en to lpf_IIR.v, affect both input and output filters;
 *              added 2nd  output filter;
 * Apr.13,2022: added SA_Valid, to switch DAC outptu to BF method when ISIS_pulse is missing, and not in Cal mode.
 *              added IIR_OUT_K for both BF method and SA method.
 * Dec. 8,2022: added DC_METHOD (diode_clamp), remvoed TC_METHOD.
 
 * Apr 3 2025: Changed HIST input to sa_in, so it's not averaged.
 */

module Channel_Block(
 input SCLK,
 input SYS_CLK,
 input SYS_RST,
 
 input Data_Valid,
 input [ADC_DATA_WIDTH-1:0] din0,
 
 input ISIS_pulse,
 input ISIS_pulse_lost,
 
 input toroid_polarity,
 input [2:0] toroid_type,
 input [1:0] METHOD, 
 input [2:0] AVG_MODE,
 input [2:0] HIST_MODE,
 input [1:0] OUTAVG_MODE,
 input [15:0] CAL_REG,

 input [1:0] ch_gain, 
 input [2:0] waveform_sel,
 input ch_cal_on,
 
 input [15:0] TRIP_TH, //16 bit integer, unit=100nA
 
 input [31:0] IIR_OUT_BF_K1,
 input [31:0] IIR_OUT_BF_K2,
 input [31:0] IIR_OUT_SA_K1,
 input [31:0] IIR_OUT_SA_K2,
 
 input [15:0] ALPHA,
 
 input [SF_WIDTH-1:0] FP_G,
 input [SF_WIDTH-1:0] FP_Z,

 input [SF_WIDTH-1:0] FP_SLOPE,
 input [SF_WIDTH-1:0] FP_OFFSET,
 
 input [15:0] CON_REG,
 input [15:0] STATUS_REG,

 input [15:0] temp,
 
 // to DAC
 output DAC_CSn,
 output DAC_clk,
 output DAC_data,
 
 //to fast fifo
 output [FFIFO_WIDTH-1:0] fifo_din,
 output fifo_din_valid,
 
 output reg trip, //beam value trip
 output overflow,
 
 output [ADC_DATA_WIDTH-1:0] N_sample,
 output [7:0] DC_Index,
 output [ADC_DATA_WIDTH-1:0] BL_SA,
 output signed [ADC_DATA_WIDTH-1:0] peak,
 output signed [SF_WIDTH-1:0] peaknA,
 output signed [SF_WIDTH-1:0] fpDC,
 output signed [SF_WIDTH-1:0] fpVBL,
 
 output signed [31:0] BEAMnA,
 
 output processing_done,
 output [31:0] debug
 );

`include "src/param.v"


//`define COMB_FILTER 1  //comment if don't need comb filter for 2C toroid 
//`define BOX_FILTER_METHOD 1  //comment if don't need BOX filter \
`define SYN_AVG_METHOD 1  //comment if don't this method

// The fllowing two 5th IIR consumes 50% FPGA Logic Blocks
//`define INPUT_5TH_FILTER 1 
//`define OUTPUT_5TH_FILTER 1 

wire [SF_WIDTH-1:0] fpDIN,fpVBL_BF,fpVBL_DC,fpVBL_TC,fpVLP,fpBL,fpAVG,fpINT, fpBEAM, fpBEAM0, fpBEAM1,fpBEAM2;//*synthesis keep*/;
wire [ADC_DATA_WIDTH-1:0] BEAM0,VLP,VBL_BF,VBL_DC,VBL,VSA,hist_data,VSA_comp/*synthesis keep*/;	
wire [ADC_DATA_WIDTH-1:0] BL,BL_BF,BL_TC/*synthesis keep*/;

wire avg_valid/*synthesis keep*/;
wire bf_overflow; 
wire [ADC_DATA_WIDTH-1:0] combf_out;
wire combf_overflow;
wire sa_overflow;

wire hist_valid/*synthesis keep*/;
wire hist_overflow;

wire [ADC_DATA_WIDTH-1:0] din = toroid_polarity? (~din0 + 1) : din0;

altfp_16int2fp int2fpconv_inst1 (.dataa(din), .clock(SCLK), .result(fpDIN)); //needed for LPF_IN 

///////////////////////////////////////////////////////////// 
//Input filter starts 

wire [SF_WIDTH-1:0] fpVLP0,fpVLP1;
`ifdef INPUT_5TH_FILTER
LPF5_IIR LPF_input_inst1(
    .FCLK(SCLK),
    .in_valid(Data_Valid),   
	 .data_in(fpDIN),
	 
	 .data_out(fpVLP1) 
    );
`endif

//input filter default:
parameter IIR_IN_K2 = 32'd1677722;  //0.1 = 1677722/2^24
parameter IIR_IN_K1 = 32'd15099494; //0.9 = 15099494/2^24

LPF_IIR LPF_input_inst2(
    .FCLK(SCLK),
    .in_valid(Data_Valid),   
	 .data_in(fpDIN),
	 
	 .K1(IIR_IN_K1),
	 .K2(IIR_IN_K2),
	 
    .data_out(fpVLP0) 
    );
	 
//assign fpVLP = CON_REG[0]? fpVLP1 : fpVLP0; //uncomment if using 5th order input filter
assign fpVLP = fpVLP0;	 
altfp_fp2int fp2intconv_inst1 (.dataa(fpVLP), .clock(SCLK), .result(VLP));  		 


//input filter ends /////////////////////////////////////////


//// Comb filter starts/////////////////////////
`ifdef COMB_FILTER

combfilter combfilter_inst(
    .clk(SCLK),
    .in_valid(Data_Valid),   
    .alpha(16'd922), //gain factor = alpha/1024, for example, 922/1024 = 0.9004

	 	 
    .data_in(VLP), //from input filter
	
    .data_out(combf_out), //output data
 
	 .overflow(combf_overflow) //calculation overflow 

    );

`endif

// comb filter ends ////////////////////////////	 


//Box filter starts //////////////////////////////////////////
`ifdef BOX_FILTER_METHOD
wire [ADC_DATA_WIDTH-1:0] boxf_in = CB_METHOD? combf_out : VLP;
boxfilter_sr bf_inst(
    .clk(SCLK),
    .in_valid(Data_Valid),   
    .rst(SYS_RST),

  	 .data_in(boxf_in), //input data from ADC 
		 
    .data_out(VBL_BF), //output data, with BL substraced
	 .BL(BL_BF), //base line, output
	 .overflow(bf_overflow) //caculation overflow 

    );

altfp_16int2fp int2fpconv_inst2 (.dataa(VBL_BF), .clock(SCLK), .result(fpVBL_BF)); 
`endif

//Box filter ends ////////////////////////////////////////////////////

//Synchrnous Averaging start//

wire [31:0] fpPeak;
altfp_16int2fp int2fpconv_inst4 (.dataa(peak), .clock(SCLK), .result(fpPeak)); 
`ifdef SYN_AVG_METHOD

wire [15:0] AVG_TIMES = (AVG_MODE == 3'b000)? 4 : 
                        (AVG_MODE == 3'b001)? 8 :
								(AVG_MODE == 3'b010)? 16 :
								(AVG_MODE == 3'b011)? 32 :
								(AVG_MODE == 3'b100)? 64 :
								(AVG_MODE == 3'b101)? 128 :
								(AVG_MODE == 3'b110)? 256 :
								(AVG_MODE == 3'b111)? 512 : 1;
								
wire [7:0] HIST_AVG =   (HIST_MODE == 3'b000)? 4 : 
                        (HIST_MODE == 3'b001)? 8 :
								(HIST_MODE == 3'b010)? 16 :
								(HIST_MODE == 3'b011)? 32 :
								(HIST_MODE == 3'b100)? 64 :
								(HIST_MODE == 3'b101)? 128 :
								(HIST_MODE == 3'b110)? 256 :
								(HIST_MODE == 3'b111)? 512 : 4;	

wire signed [31:0] INT; 
wire [ADC_DATA_WIDTH-1:0] sa_in = VLP; //from input filter

reg cal_pulse_syn;
//cal_pulse_syn needs to be trimed to be 1 SCLK wide
always @ (posedge SCLK ) 
  begin if (cal_pulse_40 & ~cal_pulse_syn) cal_pulse_syn <= 1; 
        else if (cal_pulse_syn) cal_pulse_syn <= 0; 
  end

wire pulse_start = ch_cal_on? cal_pulse_syn : ISIS_pulse; 
wire INT_tag;

wire [13:0] pulse_len;

wire [31:0] fpINT_halfper;

syn_averaging syn_avg_inst(
	.clk(SCLK), // SCLK 35 MHz
	.signal(sa_in), 

	.in_valid(Data_Valid), //signal valid, data rate is about 1.15275 MHz
	.pulse_start(pulse_start),  //one clock pulse, i.e.   ISIS pulse
	.AVG_TIMES(AVG_TIMES),	
	.INT_Valid(INT_tag),
	.INT(fpINT),//32 bit signed, integration of the averaged pulse
	.BL(BL_SA),//16 bit signed, Base line. Changed from BL_SA - HJ
	.alpha(ALPHA),
	.N_sample(N_sample), //16 bit, number of samples per pulse
   .avg_valid(avg_valid),
	.avg_signal(VSA), //16 bit signed data
	.avg_signal_comp(VSA_comp),
	.pulse_len(pulse_len),

	.overflow(sa_overflow),
	.debug(debug)
);

//added on January05,2023 to replace Hist which needs too much RAM resources failed to fit 2 channel.
/*bottom syn_BL_inst(
	.clk(SCLK), // SCLK 35 MHz
	.signal(VSA),
	.in_valid(avg_valid), // valid for the one period of the input signal
	.min(BL_SA) //BL for syn_averaging method
    );
*/

//avg_half_period u_avg_half_period (
//    .clk       (SCLK),       // ← 35 MHz system clock
//    .rst       (),      // ← synchronous, active‑high reset
//    .in_valid  (avg_valid),    // ← “sample_in is valid” strobe
//    .sample_in (VSA),    // ← signed 16‑bit sample from ADC/logic
//    .pulse_len (pulse_len),   // ← 16‑bit count of samples per full pulse
//    .avg_fp    (fpINT_halfper), // → 32‑bit averaged value (fixed‑/float‑pt)
//    .avg_val   ()      // → 1‑clk pulse: avg_fp just updated
//);

 //-------------------------------------
wire [15:0] avg_signal_fixed;
wire [13:0] pulse_len_fixed;
wire avg_valid_fixed;

 // Instantiate the DUT
 synavg_fixed uut (
	  .clk(SCLK),
	  .in_valid(Data_Valid),
	  .signal_in(sa_in),
	  .trigger(pulse_start),
	  .avg_signal(avg_signal_fixed),
	  .pulse_len(pulse_len_fixed),
	  .avg_valid(avg_valid_fixed)
 );
// -------------------------------------

//wire [15:0] hist_signal_in;
//wire beam_off;
//findRMS u_beam_det (
//	 .clk       (Data_Valid),     // 1.152 MHz sample clock
//	 .rst       (),      // synchronous, active‑high reset
//	 .sig_in    (sa_in),    // signed 16‑bit signal from BPM / toroid
//	 .threshold (100),      // e.g. 16'd100  → beam‑present threshold
//	 .sig_out   (hist_signal_in),     // 16‑sample moving‑average output
//	 .beamOff   (beam_off)    // 1 = beam below threshold
//);	

reg [5:0] trig_cnt = 0;
wire trigger_hist = (trig_cnt == 3)? 1 : 0;
 
always@(posedge pulse_start) begin
	if(trig_cnt == 3) begin
		trig_cnt <= 0;
	end
	else begin
		trig_cnt <= trig_cnt + 1;
	end
end
	
Hist hist_inst(
	.clk(SCLK), // SCLK 35 MHz
	.signal(VSA), // VSA
	.in_valid(avg_valid), //avg_valid,
	.pulse_start(),  //one clock pulse, i.e.   ISIS pulse
	.AVG_TIMES(HIST_AVG), //8 byte unsigned, histogram averaging times: 4,8,16,32,... pulses * 1024
   .DC_Index(DC_Index), //input
	.pulse_len(pulse_len), // input
	
	.BL(BL_SA), 
	.pulse_height(peak),
	.fpDC100(fpDC), //duty cycle = ( 0 , 100)
	
	.hist_valid(hist_valid),
   .hist_signal(hist_data),
	.overflow(hist_overflow)
);


//altfp_int2fp int2fpconv_inst3 (.dataa(INT), .clock(SCLK), .result(fpINT)); 

`endif
//Synchronous Averaging ends


wire [LONG_WIDTH-1:0] pulse_AVG/*synthesis keep*/;
wire [LONG_WIDTH-1:0] pulse_width,pulse_period/*synthesis keep*/; 
wire [ADC_DATA_WIDTH-1:0] pulse_BL;
	 
	 

//if ISIS_pulse missing, the DAC output is switched to BF_Method results. SL, 2022-04-13
wire SA_Valid = (~ISIS_pulse_lost) | ch_cal_on; 

assign overflow = sa_overflow; // frequency too low
//CHANGED BY HJ ON APR23 2025	
assign fpVBL = DC_METHOD? fpVBL_DC : 
               BF_METHOD? fpINT_halfper : 
					(SA_METHOD & SA_Valid)? fpINT :
					CB_METHOD? fpVBL_BF : fpVBL_BF;

	
//(SA_METHOD & SA_Valid)? BL_SA :			
assign BL = DC_METHOD? 16'd0 :
            BF_METHOD? BL_BF : 
				SA_METHOD? BL_SA : 
				CB_METHOD? BL_BF : 16'd0;

`ifdef SYN_AVG_METHOD
wire fpVBL_Valid = (SA_METHOD & SA_Valid)? INT_tag : Data_Valid;
`else 
wire fpVBL_Valid = Data_Valid;
`endif
                   
//output filter default:

//parameter LPF_OUT_K1 = 32'd64; //K1 = 2^24 - K2
//parameter LPF_OUT_K2 = 32'd16777152; //time constant = 0.262 seconds

//parameter LPF_OUT_K1 = 32'd168; //K1 = 2^24 - K2
//parameter LPF_OUT_K2 = 32'd16777048; //time constant = 0.1 seconds

//parameter LPF_OUT_K1 = 32'd16777; //K1 = 2^24 - K2
//parameter LPF_OUT_K2 = 32'd16760439; //time constant = 0.01 seconds

//for SA mode, the filter input signal is almost DC signal, and TC = 0.262 will make the  
//output signal looks like "dead", so it needs to use TC = 0.01 seconds.
//and for all other Algorithm, the TC = 0.262 is good.

`ifdef OUTPUT_5TH_FILTER						
//LPF_5th_IIR LPF_output_inst1(
LPF2_IIR LPF_output_inst1(
    .FCLK(SCLK),
    .in_valid(fpVBL_Valid),   
	 .data_in(fpVBL),
    .data_out(fpBEAM1) //a.u. = DC beam current in arbitary unit
    );

`endif

//parameter IIR_OUT_BF_K1 = 32'd67; // default Time const = 0.25 s
//parameter IIR_OUT_BF_K2 = 32'd16777149; //
//parameter IIR_OUT_SA_K1 = 32'd5872026; //default Time const = 0.25 s
//parameter IIR_OUT_SA_K2 = 32'd10905190; //


wire [31:0] IIR_OUT_K1 = BF_METHOD? IIR_OUT_BF_K1 :
                         SA_METHOD? IIR_OUT_SA_K1 : IIR_OUT_BF_K1;
wire [31:0] IIR_OUT_K2 = BF_METHOD? IIR_OUT_BF_K2 :
                         SA_METHOD? IIR_OUT_SA_K2 : IIR_OUT_BF_K2;						
						
LPF_IIR LPF_output_inst2(
    .FCLK(SCLK),
    .in_valid(fpVBL_Valid),   
	 .data_in(fpVBL),
	 
	 .K1(IIR_OUT_K1),
	 .K2(IIR_OUT_K2),
	
	// .K1(32'd419430),  //K1=0.025
	// .K2(32'd16357786), //K2=0.975, 1Hz BW for 4 ms Tsampling.
	 
    .data_out(fpBEAM0) //a.u. = DC beam current in arbitary unit
    );

//wire [SF_WIDTH-1:0] fpBEAM = CON_REG[1]? fpBEAM1 : fpBEAM0; //uncomment if using 5th order outptu filter
assign fpBEAM = fpBEAM0;
 	
////////////////////////////////////////////////////////////////////////////

//assign fifo_din = (waveform_sel == 3'b000)? {BL,din} : // Raw input signal
//						(waveform_sel == 3'b001)? {BL,VLP} : //  LPF waveform
//                  (waveform_sel == 3'b010)? {BL,combf_out} : // comb waveform
//						(waveform_sel == 3'b011)? {BL,VBL_BF} :  //  Box filter waveform
//						(waveform_sel == 3'b100)? {BL_SA,VSA} :      // SA averaged waveform 
//						(waveform_sel == 3'b101)? {VLP,VBL_DC} :      // Raw / DC waveform
//						 32'b0;

assign fifo_din = (waveform_sel == 3'b000)? {din} : // Raw input signal
						(waveform_sel == 3'b001)? {VLP} : //  LPF waveform
                  (waveform_sel == 3'b010)? {combf_out} : // comb waveform
						(waveform_sel == 3'b011)? {VBL_BF} :  //  Box filter waveform
						(waveform_sel == 3'b100)? {VSA_comp} :      // SA averaged waveform 
						(waveform_sel == 3'b101)? {VBL_DC} :      // Raw / DC waveform
						 32'b0;											 
assign fifo_din_valid = (waveform_sel == 3'b100)? avg_valid : Data_Valid;
								  


//00: DC method, 01: box filter method, 10: threshold method, 11: comb filter + box filter

wire DC_METHOD = (METHOD == 2'b00);
//wire BF_METHOD = (METHOD == 2'b01) | ((METHOD == 2'b10) & ISIS_pulse_lost);
//wire SA_METHOD = (METHOD == 2'b10) & (~ISIS_pulse_lost);
wire BF_METHOD = (METHOD == 2'b01);
wire SA_METHOD = (METHOD == 2'b10);
wire CB_METHOD = (METHOD == 2'b11); //0: No Comb filter, 1: enable comb filter (for 2C toroid )

					
//================ Calculate BEAM current and DAC value ==============


wire [DAC_DATA_WIDTH-1:0] DAC_code;

cal_current cal_i_ins(
   .METHOD(METHOD), //this input is not used. 
	.fpBEAM(fpBEAM), //DC beam current to be calibrated by K,B linear fitting
	.fpPeak(fpPeak),
	.fpDC(fpDC), //Measured DutyCycle from Histogram, in unit of percent
	.Data_In_Valid(Data_Valid), 
	.PCA_gain(ch_gain), 
	
	.FP_G(FP_G),
   .FP_Z(FP_Z),
 
	.Slope_FACTOR(FP_SLOPE),
	.Offset_FACTOR(FP_OFFSET),
	
	.toroid_type(toroid_type),

	.clk(SCLK),  //35 MHz 
	.rst(SYS_RST),

	.Index(DC_Index),
	.I_val32(BEAMnA), //signed 32bit, DC beam current ,in unit of nA 
	.peak32(peaknA),
	.DAC_code(DAC_code), //signed 16 bit, DAC bin
	.RDY(processing_done)	
    );

	 
//=========== DAC interface ========================

wire cal_pulse_40;
DAC_control DAC_control_inst
    (
        // Signals to DAC 
        .sdi(DAC_data),   // SPI data to DAC
        .sclk(DAC_clk),   // SPI_CLK to DAC, less than 50 MHz                                                     
        .ss(DAC_CSn),     // start 
        .pulse_start(cal_pulse_40), //output: 40 ns wide
		  
        // input 
		  .ena_cal(ch_cal_on),
		  .Dcycle(CAL_REG[15:8]), //8 bit, duty cycle: 0 ~ 100%, 
		  .Amplitude(CAL_REG[7:0]), //8 bit,0 ~ 100%  
		  .BEAM(DAC_code), //beam dc value to DAC
		  
        .clk(SYS_CLK),  //50MHz system clock                                                      
        .rst(SYS_RST)     
		  
    );	
	 	 

///============== Trip generating ===============		 
`ifdef TRIP_ENABLE		 

wire signed [31:0] trip_trip_na; 
lpm_mul mul_inst (
		.dataa(TRIP_TH), //16 bit, in unit of 100nA
		.datab(100),  //16 bit
		.result(trip_trip_na)  //32 bit
		);	
wire trip_OK = BEAMnA[31]? 1'b1 : BEAMnA < trip_trip_na;
always@ (posedge SCLK) if(~trip_OK) trip <= 1; else trip <= 0;	

`else
wire trip_OK = 1;

`endif

endmodule
