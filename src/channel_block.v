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
 
 input [31:0] DIODE_TH,     //threshold
 input [31:0] DIODE_NCrev,  //negtive reverse of C
 input [31:0] DIODE_R1rev, //reverse of R1
 input [31:0] DIODE_R2rev, //sf, the reverse of the diode conducting resistiance 
 
 input [15:0] ALPHA,
 input [31:0] DCR_PU,
 input [31:0] DCR_PD,
 
 input [SF_WIDTH-1:0] FP_G,
 input [SF_WIDTH-1:0] FP_Z,

 input [SF_WIDTH-1:0] FP_SLOPE,
 input [SF_WIDTH-1:0] FP_OFFSET,
 
 input [15:0] CON_REG,
 input [15:0] STATUS_REG,
 input [1:0] relay_contact,
 input [15:0] temp,
 
 // to DAC
 output DAC_CSn,
 output DAC_clk,
 output DAC_data,
 
 //to fast fifo
 output [FFIFO_WIDTH-1:0] fifo_din,
 output fifo_din_valid,
 
//slow fifo interface 
 output [SFIFO_WIDTH-1:0] slow_fifo_dout ,
 output [7:0] sfifo_rd_wd,
 input sfifo_rd,
 
 output reg trip, //beam value trip
 output overflow
 

 
);

`include "src/param.v"


//`define COMB_FILTER 1  //comment if don't need comb filter for 2C toroid 
//`define BOX_FILTER_METHOD 1  //comment if don't need BOX filter \
`define SYN_AVG_METHOD 1  //comment if don't this method

// The fllowing two 5th IIR consumes 50% FPGA Logic Blocks
//`define INPUT_5TH_FILTER 1 
//`define OUTPUT_5TH_FILTER 1 

wire [SF_WIDTH-1:0] fpDIN,fpVBL_BF,fpVBL_DC,fpVBL_TC,fpVLP,fpBL,fpVBL,fpAVG,fpINT,fpBEAM0,fpBEAM1,fpBEAM2;//*synthesis keep*/;
wire [ADC_DATA_WIDTH-1:0] BEAM0,VLP,VBL_BF,VBL_DC,VBL,VSA,hist_data/*synthesis keep*/;	
wire [ADC_DATA_WIDTH-1:0] BL,BL_BF,BL_TC,BL_SA, N_sample/*synthesis keep*/;
wire [SF_WIDTH-1:0] fpDC;

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

wire signed [15:0] peak;
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
								
wire [7:0] HIST_AVG = (HIST_MODE == 3'b000)? 4 : 
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
	.pulse_len(pulse_len),

	.overflow(sa_overflow)
);

//added on January05,2023 to replace Hist which needs too much RAM resources failed to fit 2 channel.
/*bottom syn_BL_inst(
	.clk(SCLK), // SCLK 35 MHz
	.signal(VSA),
	.in_valid(avg_valid), // valid for the one period of the input signal
	.min(BL_SA) //BL for syn_averaging method
    );
*/


Hist hist_inst(
	.clk(SCLK), // SCLK 35 MHz
	.signal(VSA),
	.in_valid(avg_valid), //signal valid,
	.pulse_start(pulse_start),  //one clock pulse, i.e.   ISIS pulse
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

assign overflow = bf_overflow | combf_overflow | sa_overflow | hist_overflow; // algorithm overflow

assign fpVBL = DC_METHOD? fpVBL_DC : 
               BF_METHOD? fpVBL_BF : 
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
wire [SF_WIDTH-1:0] fpBEAM = fpBEAM0;
 	
////////////////////////////////////////////////////////////////////////////

assign fifo_din = (waveform_sel == 3'b000)? {BL,din} : // Raw input signal
						(waveform_sel == 3'b001)? {BL,VLP} : //  LPF waveform
                  (waveform_sel == 3'b010)? {BL,combf_out} : // comb waveform
						(waveform_sel == 3'b011)? {BL,VBL_BF} :  //  Box filter waveform
						(waveform_sel == 3'b100)? {BL_SA,VSA} :      // SA averaged waveform 
						(waveform_sel == 3'b101)? {VLP,VBL_DC} :      // Raw / DC waveform
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

wire processing_done;
wire [DAC_DATA_WIDTH-1:0] DAC_code;
wire signed [31:0] BEAMnA, peaknA;
wire [7:0] DC_Index;

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

///================ Slow FIFO ===================

   wire [7:0] sfifo_wr_wd;
	reg sFIFO_wr;
	reg [SFIFO_WIDTH-1:0] sfifo_data_in;
	wire sfifo_half_full = sfifo_wr_wd[6]; // 64   
	
	slfifo Slow_FIFO (
		.aclr(SYS_RST),
		.data(sfifo_data_in),
		.wrclk(SCLK),
		.rdclk(SYS_CLK),
		.wrreq(sFIFO_wr),
		.rdreq(sfifo_rd),
		.q(slow_fifo_dout),
		.rdusedw(sfifo_rd_wd), 
		.wrusedw(sfifo_wr_wd)
	);  
//	output [7:0]  rdusedw;
//	output [7:0]  wrusedw;
// slfifo is 128 words(32bit) deep, Nov.29,2018
	
//============Packing=================================
	parameter PID = 32'h41434354; // "ACCT"
   
	reg [7:0] p_state;

//data packet size is 8 words (32bit)
	always @(posedge SCLK)
	begin
		if(SYS_RST)
			begin
				p_state <= 0;
				sFIFO_wr<= 0;
			end
		else
			begin
				case(p_state)
					0:if(processing_done && !sfifo_half_full)
						begin sFIFO_wr<= 1; sfifo_data_in <= PID; p_state <= 1; end
					1: begin sfifo_data_in <= {CON_REG,STATUS_REG}; p_state <= 2; end
					2: begin sfifo_data_in <= {relay_contact,temp}; p_state <= 3; end
					3: begin sfifo_data_in <= BEAMnA; p_state <= 4; end
					
					4: begin sfifo_data_in <= {16'b0,N_sample}; p_state <= 5; end
					5: begin sfifo_data_in <= {16'b0,DC_Index}; p_state <= 6; end	
					6: begin sfifo_data_in <= fpDC; p_state <= 7; end	

					7: begin sfifo_data_in <= 0; p_state <= 8; end
					8: begin sfifo_data_in <= 0; p_state <= 9; end
					9: begin sfifo_data_in <= ALPHA; p_state <= 10; end
					10: begin sfifo_data_in <= 0; p_state <= 11; end
					11: begin sfifo_data_in <= 0; p_state <= 12; end	
					12: begin sfifo_data_in <= 0; p_state <= 13; end
					13: begin sfifo_data_in <= 0; p_state <= 14; end

					14: begin sfifo_data_in <= 0; p_state <= 15; end
					15: begin sfifo_data_in <= 0; p_state <= 16; end
					16: begin sfifo_data_in <= 0; p_state <= 17; end
					17: begin sfifo_data_in <= 0; p_state <= 18; end
					18: begin sfifo_data_in <= BL_SA; p_state <= 19; end // BL as integer
					19: begin sfifo_data_in <= peak; p_state <= 20; end // peak as integer
					20: begin sfifo_data_in <= peaknA; p_state <= 21; end // peak as float
					21: begin sfifo_data_in <= 0; p_state <= 22; end
					22: begin sfifo_data_in <= 0; p_state <= 23; end
					23: begin sfifo_data_in <= 0; p_state <= 24; end
					24: begin sfifo_data_in <= 0; p_state <= 25; end
					25: begin sfifo_data_in <= 0; p_state <= 26; end
					
					26: begin sfifo_data_in <= fpVBL; p_state <= 27; end
					27: begin sfifo_data_in <= fpBEAM0; p_state <= 28; end
					28: begin sfifo_data_in <= fpBEAM1; p_state <= 29; end
					29: begin sfifo_data_in <= 0; p_state <= 30; end
					30: begin sfifo_data_in <= 0; p_state <= 31; end
					31: begin sfifo_data_in <= 0; p_state <= 32; end
					32: begin sFIFO_wr<= 0; p_state <= 0; end
					
//					22: begin sfifo_data_in <= FP_GC3; p_state <= 23; end
//					23: begin sfifo_data_in <= FP_GC2; p_state <= 24; end
//					24: begin sfifo_data_in <= FP_GC1; p_state <= 25; end
//					25: begin sfifo_data_in <= FP_GC0; p_state <= 26; end
					default:
						begin sFIFO_wr<= 0; p_state <= 0; end
				endcase
			end

	end


	
	
endmodule
