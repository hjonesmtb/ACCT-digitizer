/*
 * Top Level system description for Toroid Digital Processor module.
 * This project was based upon the Target Protect Module 1039.
 * Shengli Liu, April 3, 2019
 * History: created on April 3,2019 (copied from Target Protect 1039 FPGA project)'
 * Modified IO for MB v3, Nov.29,2019
 * 2020/01/13: added gain adjust factors, added trip_threhold.
 * 2020/03/10: removed channel gain correction: FP_CHX_GX.
 *             added second channel implementation.
 * 2020/04/30: added output avgerging.
 * 2020/05/11: change Hist.v .. DC_index > 9 to > 8, to prevent oscillating at high Dc.
 * 2020/11/10: added FP_CH1_K10,K11; Added FPGA_LED to indicate ISIS pulse; removed Module_ID1.
 * 2020/11/27: added polarity resverse, changed BL2A S= 20uA/V.
 * 2022/04/13: added SA_valid in channel_block.v; Expand Module_ID to 8 Characters, removed DAC_slope,off.
 *          added IIR_OUT_K for both BF method and SA method, change IIR_IN_K1,K2 to default 0.1/0.9 constant.
 * 2022/06/07: added toroid_type : 2C, S=24uA/V.
 * 2022/10/28: added ALPHA parameter access for Comb method.
 * 2022/12/08: added diode_clamp method. removed TC method.
 * 2023/01/03: removed DC correction, added FP_G,FP_Z for gain and zero correction.
 * 2023/01/05: added bottom.v, to replace Hist to find BL for syn_avg method.
 * 2023/05/05: reuse hist.V, to replace bottom.v to find BL for syn_avg method, to fix error at very low DC during startup. 
 
 * 2024/09/11: changed droop compensation to 3/2^18. Increased fast fifo to 8192 words.
 * oct 2024  : changed fast fifo to 16k. Removed unused commands.
 */
 
parameter FPGA_VERSION_NO = 32'd20250528; //yyyy_mm_dd_hh:
// taken from may 2023

module DE10_NANO_SoC_GHRD(

    //////////// CLOCK //////////
    input               FPGA_CLK1_50,
    input               FPGA_CLK2_50,
    input               FPGA_CLK3_50,

    //////////// HDMI //////////
    inout               HDMI_I2C_SCL,
    inout               HDMI_I2C_SDA,
    inout               HDMI_I2S,
    inout               HDMI_LRCLK,
    inout               HDMI_MCLK,
    inout               HDMI_SCLK,
    output              HDMI_TX_CLK,
    output   [23: 0]    HDMI_TX_D,
    output              HDMI_TX_DE,
    output              HDMI_TX_HS,
    input               HDMI_TX_INT,
    output              HDMI_TX_VS,

    //////////// HPS //////////
    inout               HPS_CONV_USB_N,
    output   [14: 0]    HPS_DDR3_ADDR,
    output   [ 2: 0]    HPS_DDR3_BA,
    output              HPS_DDR3_CAS_N,
    output              HPS_DDR3_CK_N,
    output              HPS_DDR3_CK_P,
    output              HPS_DDR3_CKE,
    output              HPS_DDR3_CS_N,
    output   [ 3: 0]    HPS_DDR3_DM,
    inout    [31: 0]    HPS_DDR3_DQ,
    inout    [ 3: 0]    HPS_DDR3_DQS_N,
    inout    [ 3: 0]    HPS_DDR3_DQS_P,
    output              HPS_DDR3_ODT,
    output              HPS_DDR3_RAS_N,
    output              HPS_DDR3_RESET_N,
    input               HPS_DDR3_RZQ,
    output              HPS_DDR3_WE_N,
    output              HPS_ENET_GTX_CLK,
    inout               HPS_ENET_INT_N,
    output              HPS_ENET_MDC,
    inout               HPS_ENET_MDIO,
    input               HPS_ENET_RX_CLK,
    input    [ 3: 0]    HPS_ENET_RX_DATA,
    input               HPS_ENET_RX_DV,
    output   [ 3: 0]    HPS_ENET_TX_DATA,
    output              HPS_ENET_TX_EN,
    inout               HPS_GSENSOR_INT,
    inout               HPS_I2C0_SCLK,
    inout               HPS_I2C0_SDAT,
    inout               HPS_I2C1_SCLK,
    inout               HPS_I2C1_SDAT,
    inout               HPS_KEY,
    inout               HPS_LED,
    inout               HPS_LTC_GPIO,
    output              HPS_SD_CLK,
    inout               HPS_SD_CMD,
    inout    [ 3: 0]    HPS_SD_DATA,
    output              HPS_SPIM_CLK,
    input               HPS_SPIM_MISO,
    output              HPS_SPIM_MOSI,
    inout               HPS_SPIM_SS,
    input               HPS_UART_RX,
    output              HPS_UART_TX,
    input               HPS_USB_CLKOUT,
    inout    [ 7: 0]    HPS_USB_DATA,
    input               HPS_USB_DIR,
    input               HPS_USB_NXT,
    output              HPS_USB_STP,

	 //////////// GPIO //////////
	 input GPIO_0_16, //RF_CLK_23, 
	 input GPIO_0_1, //RF_lost, 
	 input GPIO_1_3,  //ISIS_pulse	
	 
	 output GPIO_1_29,  //ADC1_SDI
	 output GPIO_1_31,  //ADC1_SCLK
	 input  GPIO_1_33,  //ADC1_SDO
	 output GPIO_1_35,  //ADC1_CNV
	 
	 output GPIO_1_19,  //ADC2_SDI
	 output GPIO_1_21,  //ADC2_SCLK
	 input  GPIO_1_23,  //ADC2_SDO
	 output GPIO_1_25,  //ADC2_CNV
	
	 
	 input  GPIO_0_32,  //HPS_Cold_Reset 
	 output GPIO_0_34,  //.
	 output GPIO_0_35,  //LED_Comm
	 		 
	 //i2c eeprom
	 output GPIO_1_6, //SCL
	 inout  GPIO_1_8, //SDA
	
 	 //Temp sensor DHT11
	 inout  GPIO_0_28, //DHT11 Sig
    
	 //P1 FPGA test connector
	 output  GPIO_1_10, //Test 0 
	 output  GPIO_1_11, //Test 1 
	 output  GPIO_1_12, //Test 2 
	 output  GPIO_1_13, //Test 3 
	 output  GPIO_1_14, //Test 4 
	 output  GPIO_1_15, //Test 5 
	 output  GPIO_1_16, //Test 6 
	 output  GPIO_1_17, //Test 6 
	   
	//calibration SW
	output GPIO_0_2,  //ch2_cal_on
   output GPIO_0_10,  //ch1_cal_on
		

	//DC SW
	output GPIO_0_14,  //ch1_DC_on
   output GPIO_0_6,  //ch2_DC_on
	
	//DAC output
	output GPIO_0_13,  //ch1_DAC_CSn
	output GPIO_0_11,  //ch1_DAC_clk
	output GPIO_0_12,  //ch1_DAC_data
	
	output GPIO_0_5,  //ch2_DAC_CSn
	output GPIO_0_3,  //ch2_DAC_clk
	output GPIO_0_4,  //ch2_DAC_data
	
	
	
    //////////// KEY //////////
    input    [ 1: 0]    KEY,

    //////////// LED //////////
    output   [ 7: 0]    LED,

    //////////// SW //////////
    input    [ 3: 0]    SW
);


`include "src/param.v"

`define ENABLE_CH2 1  //comment if only use one channel
//`define ENABLE_RF 1  //comment if only use ISIS_pulser signal for SA 

`define 	PCA_GAIN_BIT_L8 configuration[0]
`define 	PCA_GAIN_BIT_H8 configuration[1]

`define 	CON_REG_L8 configuration[2]
`define 	CON_REG_H8 configuration[3]

//DAC correction:
//`define 	FP_SLOPE  {configuration[7],configuration[6],configuration[5],configuration[4]}
//`define 	FP_OFFSET  {configuration[11],configuration[10],configuration[9],configuration[8]}
`define 	MODULE_ID0  {configuration[7],configuration[6],configuration[5],configuration[4]}
`define 	MODULE_ID1  {configuration[11],configuration[10],configuration[9],configuration[8]}

//Gain and offset correction:
`define 	FP_CH0_G  {configuration[15],configuration[14],configuration[13],configuration[12]}
`define 	FP_CH0_Z  {configuration[19],configuration[18],configuration[17],configuration[16]}
`define 	FP_CH1_G  {configuration[23],configuration[22],configuration[21],configuration[20]}
`define 	FP_CH1_Z  {configuration[27],configuration[26],configuration[25],configuration[24]}

`define 	IIR_OUT_BF_K1  {configuration[103],configuration[102],configuration[101],configuration[100]}
`define 	IIR_OUT_BF_K2  {configuration[107],configuration[106],configuration[105],configuration[104]}

`define 	IIR_OUT_SA_K1  {configuration[111],configuration[110],configuration[109],configuration[108]}
`define 	IIR_OUT_SA_K2  {configuration[115],configuration[114],configuration[113],configuration[112]}

`define 	ALPHA  {configuration[121],configuration[120]}
 
parameter sf_DAC_SLOPE = 32'h3f800000; //1 in FP format
parameter sf_DAC_OFFSET = 32'hba83126f; //-0.001 in FP format

 									
//=======================================================
//  REG/WIRE declarations
//=======================================================
wire hps_fpga_reset_n;
wire     [1: 0]     fpga_debounced_buttons;
wire     [6: 0]     fpga_led_internal;
wire     [2: 0]     hps_reset_req;
wire                hps_cold_reset;
wire                hps_warm_reset;
wire                hps_debug_reset;
wire     [27: 0]    stm_hw_events;
wire                fpga_clk_50;

// connection of internal logics

assign LED[7: 1] = fpga_led_internal;
assign fpga_clk_50 = FPGA_CLK1_50;
assign stm_hw_events = {{15{1'b0}}, SW, fpga_led_internal, fpga_debounced_buttons};

//Wires from ADC modules

wire [1:0] ADC_MISO;
wire  ADC_MOSI;
wire  ADC_SCLK;
wire  ADC_SS;

wire [1:0] ch_gain [1:0]; 

wire LED_FAULT = ISIS_pulse_lost | ch1_overflow | ch2_overflow; // status LED
reg comm_act;
reg [15:0] ch_reg;	

wire ch_select = ch_reg[0];
wire [2:0] waveform_sel = ch_reg[5:3];

reg ADC_init_cmd; //pulse to init ADC AD4001 to turbo mode
reg ADC_read_cmd; //pulse to read ADC AD4001 register

wire SCLK/*synthesis keep*/;

wire Cold_Reset_Req;

// GPIO pin mapping :

	wire rf_clk = GPIO_0_16; //external 23.055MHz from RF
   wire rf_lost = GPIO_0_1;
	wire ISIS_pulse = GPIO_1_3;
	
	assign GPIO_1_31  = ADC_SCLK;
	assign GPIO_1_21  = ADC_SCLK;

	
	assign GPIO_1_35  = ADC_SS;
	assign GPIO_1_25  = ADC_SS;
	
	assign GPIO_1_19 = ADC_MOSI;
	assign GPIO_1_29 = ADC_MOSI;
	
	assign GPIO_0_2 = Ch2_Cal_On;  
	assign GPIO_0_10 = Ch1_Cal_On; 

	assign GPIO_0_14 = Ch1_DC_On;
   assign GPIO_0_6 = Ch2_DC_On;
	
	assign Cold_Reset_Req = ~GPIO_0_32;  //HPS_Cold_Reset 

	assign GPIO_0_35 = LED_FAULT;  //LED_COMM, indicating fault
	assign GPIO_0_34 = LED_COMM; //LED_FPGA  indicating data 
 
	assign ADC_MISO[0]  =  GPIO_1_33;
	assign ADC_MISO[1]  =  GPIO_1_23;
	
	//assign GPIO_1_10 = RF_pulse_syn; //test output 0
	//assign GPIO_1_10 = SCLK; //test output 0
	//assign GPIO_1_11 = ISIS_pulse_trimed; //test output 1
	//assign GPIO_1_12 = pulse_start; //Test 2 
	
//not all the IO pn mapping are included here.	
///////////////////////////////////////////////////////////////////////////////////////////	
	
// clock generation
wire SYS_CLK;
wire SYS_RST;
wire pll_locked; //this signal could be used to initialize ADC?

wire rf_clk_pll,CLK35M,CLK140M;
wire ADC_CLK /*synthesis keep*/;
assign SYS_RST = ~hps_fpga_reset_n;


clk35_pll clk_pll_inst0 
	(
		.refclk(FPGA_CLK1_50),
		.rst(SYS_RST),
		.outclk_0(SYS_CLK), // 50 MHz system clock
		.outclk_1(CLK140M),  // 140 MHz ADC driving clock
		.outclk_2(),
		.outclk_3(CLK35M),
		.locked(pll_locked)  //locked output
	);

assign ADC_CLK = CLK140M;
assign SCLK = CLK35M; //processing clock for all floating point math;

wire ISIS_pulse_trimed;
pulse_shaping ISIS_pulse_inst (
	 .clk(SCLK),
	 .in_pulse(ISIS_pulse),
	 .out_pulse(ISIS_pulse_trimed)
	 ); 
	 
//////////////////////////////////////////////////////////////	 
reg RF_pulse_syn;

`ifdef ENABLE_RF	
clk23_pll clk_pll_inst1 
	(
		.refclk(rf_clk), //23MHz
		.rst(SYS_RST),
		
		.outclk_0(),  // 6*23 = 138 MHz ADC driving clock
		.outclk_1(), // 50 MHz system clock
		.outclk_2(rf_clk_pll), //23MHz
		.outclk_3(), // 0.5 *23 = 11.5 Mhz
		.locked()  //locked output
	);


// The ISIS pulser freq = 23.055 MHz divided by 5*2^12 = 1126 Hz.		
//  5*2^12 = 20480
parameter RF_DIV = 20480;

reg [15:0] RF_cnt;
reg RF_pulse; // ~1126 Hz pulse signal and track actual RF

always @ (posedge rf_clk_pll)  
begin 
		if (RF_cnt >= RF_DIV) begin RF_cnt <= 0; RF_pulse <= 1; end
		else begin RF_pulse <= 0; RF_cnt <= RF_cnt + 1; end
end  

//RF_pulse, ISIS_pulse need to be trimed to be 1 SCLK wide
always @ (posedge SCLK ) 
  begin if (RF_pulse & ~RF_pulse_syn) RF_pulse_syn <= 1; 
        else if (RF_pulse_syn) RF_pulse_syn <= 0; 
  end

`endif  
  
	 
/////////////////////////////////////////////
//only use ch1 DAC for now, Nov29,2019
wire DAC1_CSn,DAC1_clk,DAC1_data;
assign GPIO_0_13 = DAC1_CSn;  
assign GPIO_0_11 = DAC1_clk;
assign GPIO_0_12 = DAC1_data;

wire DAC2_CSn,DAC2_clk,DAC2_data;
assign GPIO_0_5 = DAC2_CSn;  
assign GPIO_0_3 = DAC2_clk;
assign GPIO_0_4 = DAC2_data;

reg [7:0] cal_dc_reg = 50;  //default 50 % Duty cycle;
reg [7:0] cal_amp_reg = 1; //default 1 = 100 mV p-p;


//////////////////////////////////////////////////////////////////////	
wire [ADC_DATA_WIDTH-1:0] ADC_INTERFACE_DOUT [1:0];
reg [ADC_DATA_WIDTH-1:0] Ch_ADC_Reg[1:0];
wire ADC_data_valid;

wire [7:0] ADC0_conf_reg, ADC1_conf_reg;

AD4001 adc_interface_0
	(  .run(1'b1),
		.miso(ADC_MISO[0]),
		.mosi(ADC_MOSI),
		.sclk(ADC_SCLK),
		.ss(ADC_SS),
		.clk(ADC_CLK),
		.rst(SYS_RST),
		.start_init(ADC_init_cmd), //init ADC
		.start_read(ADC_read_cmd), //read ADC register
		.conf_reg(ADC0_conf_reg),
		.DOUT(ADC_INTERFACE_DOUT[0]), //syn to SCLK
		.DRDY(ADC_data_valid) // pulse for 5 ADC_CLK period, i.e. = one SCLK period
	);

`ifdef ENABLE_CH2	
AD4001 adc_interface_1
	(  .run(1'b1),
		.miso(ADC_MISO[1]),
		.mosi(),
		.sclk(),
		.ss(),
		.clk(ADC_CLK),
		.rst(SYS_RST),
		.start_init(ADC_init_cmd),
		.start_read(ADC_read_cmd),
		.conf_reg(ADC1_conf_reg),
		.DOUT(ADC_INTERFACE_DOUT[1]), 
		.DRDY() 
	);	
`endif

//wire [ADC_DATA_WIDTH-1:0] din;
//assign din	= (ch_select == 3'b000)? ADC_INTERFACE_DOUT[0]
//				: (ch_select == 3'b001)? ADC_INTERFACE_DOUT[1]
//				: 16'b0;

wire [FFIFO_WIDTH-1:0] ch1_fifo_din,ch2_fifo_din;
wire ch1_fifo_din_valid,ch2_fifo_din_valid;

wire [SFIFO_WIDTH-1:0] ch1_slow_fifo_dout,ch2_slow_fifo_dout; 
wire [7:0] ch1_sfifo_rd_wd,ch2_sfifo_rd_wd;

wire ch1_overflow,ch2_overflow;
wire ch1_trip,ch2_trip; //channel trip to turn off relay-- relay SW open.

wire syn_pulse = ISIS_pulse_trimed ; //Apr24_2020

/////////////////// - new HJ
wire [15:0] N_sample1, N_sample2;
wire [7:0] DC_Index1, DC_Index2;
wire [15:0] BL_SA1, BL_SA2;
wire [15:0] peak1, peak2;

wire [SF_WIDTH-1:0] peaknA1, peaknA2;
wire [SF_WIDTH-1:0] fpDC1, fpDC2;
wire [SF_WIDTH-1:0] fpVBL1, fpVBL2;				
wire [31:0] BEAMnA1,BEAMnA2;


wire processing_done;
wire ISIS_pulse_lost;

wire [31:0] avg_debug1, avg_debug2;

/////////////////// - new HJ				

Channel_Block Channel_1_inst(
 .SCLK(SCLK),
 .SYS_CLK(SYS_CLK),
 .SYS_RST(SYS_RST),
 
 .Data_Valid(ADC_data_valid),
 .din0(ADC_INTERFACE_DOUT[0]),
 
 .ISIS_pulse(syn_pulse),
 .ISIS_pulse_lost(ISIS_pulse_lost),
 
 .toroid_polarity(ch0_polarity),
 .toroid_type(toroid_type),
 .METHOD(METHOD), 
 .AVG_MODE(AVG_MODE),
 .HIST_MODE(HIST_MODE),
 .OUTAVG_MODE(),
 .CAL_REG({cal_dc_reg,cal_amp_reg}),

 .ch_gain(ch_gain[0]), 
 .waveform_sel(waveform_sel),
 .ch_cal_on(Ch1_Cal_On),

 .IIR_OUT_BF_K1(`IIR_OUT_BF_K1),
 .IIR_OUT_BF_K2(`IIR_OUT_BF_K2),
 .IIR_OUT_SA_K1(`IIR_OUT_SA_K1),
 .IIR_OUT_SA_K2(`IIR_OUT_SA_K2),
 
 .ALPHA(`ALPHA),
   
 .FP_G(`FP_CH0_G),
 .FP_Z(`FP_CH0_Z),
  
 .FP_SLOPE(sf_DAC_SLOPE),
 .FP_OFFSET(sf_DAC_OFFSET),
 
 .CON_REG({`CON_REG_H8,`CON_REG_L8}),
 .STATUS_REG(status_reg),
// .relay_contact(1'b0),
 .temp(temp),
 
 // to DAC
 .DAC_CSn(DAC1_CSn),
 .DAC_clk(DAC1_clk),
 .DAC_data(DAC1_data),
 
 // to fast fifo 
 .fifo_din(ch1_fifo_din),
 .fifo_din_valid(ch1_fifo_din_valid),

 //to/form slow fifo
// .slow_fifo_dout() ,//ch1_slow_fifo_dout
// .sfifo_rd_wd(),//ch1_sfifo_rd_wd
// .sfifo_rd(),//sfifo_rd
 
 //output 
 .trip(),//ch1_trip
 .overflow(ch1_overflow),
 
 .N_sample(N_sample1),
 .DC_Index(DC_Index1),
 .BL_SA(BL_SA1),
 .peak(peak1),
 .peaknA(peaknA1),
 .fpDC(fpDC1),
 .fpVBL(fpVBL1),
 
 .BEAMnA(BEAMnA1),
 .processing_done(processing_done),
 .debug(avg_debug1)
 
);				

//////////////////////////////////////////

`ifdef ENABLE_CH2

Channel_Block Channel_2_inst(
 .SCLK(SCLK),
 .SYS_CLK(SYS_CLK),
 .SYS_RST(SYS_RST),
 
 .Data_Valid(ADC_data_valid),
 .din0(ADC_INTERFACE_DOUT[1]),
 
 .ISIS_pulse(syn_pulse),
 .ISIS_pulse_lost(ISIS_pulse_lost),
 
 .toroid_polarity(ch1_polarity),
 .toroid_type(toroid_type),
 .METHOD(METHOD), 
 .AVG_MODE(AVG_MODE),
 .HIST_MODE(HIST_MODE),
 .OUTAVG_MODE(),
 .CAL_REG({cal_dc_reg,cal_amp_reg}),

 .ch_gain(ch_gain[1]), 
 .waveform_sel(waveform_sel),
 .ch_cal_on(Ch2_Cal_On),
 
 .IIR_OUT_BF_K1(`IIR_OUT_BF_K1),
 .IIR_OUT_BF_K2(`IIR_OUT_BF_K2),
 .IIR_OUT_SA_K1(`IIR_OUT_SA_K1),
 .IIR_OUT_SA_K2(`IIR_OUT_SA_K2),
 
 .ALPHA(`ALPHA),
 
 .FP_G(`FP_CH1_G),
 .FP_Z(`FP_CH1_Z),
 
 .FP_SLOPE(sf_DAC_SLOPE),
 .FP_OFFSET(sf_DAC_OFFSET),
 
 .CON_REG({`CON_REG_H8,`CON_REG_L8}),
 .STATUS_REG(status_reg),
 //.relay_contact(1'b0),
 .temp(temp),
 
 // to DAC
 .DAC_CSn(DAC2_CSn),
 .DAC_clk(DAC2_clk),
 .DAC_data(DAC2_data),
 
 // to fast fifo 
 .fifo_din(ch2_fifo_din),
 .fifo_din_valid(ch2_fifo_din_valid),

 //to/form slow fifo
// .slow_fifo_dout() ,//ch2_slow_fifo_dout
// .sfifo_rd_wd(),//ch2_sfifo_rd_wd
// .sfifo_rd(),//sfifo_rd
 
 //output 
 .trip(),//ch2_trip
 .overflow(ch2_overflow),

 .N_sample(N_sample2),
 .DC_Index(DC_Index2),
 .BL_SA(BL_SA2),
 .peak(peak2),
 .peaknA(peaknA2),
 .fpDC(fpDC2),
 .fpVBL(fpVBL2),
 .BEAMnA(BEAMnA2),
 
 .processing_done(),
 .debug(avg_debug2)
 );				

`endif
/////////////////////////////////////////////

///================ Slow FIFO ===================

   wire [7:0] sfifo_wr_wd;
	reg sFIFO_wr;
	reg [SFIFO_WIDTH-1:0] sfifo_data_in;
	wire sfifo_half_full = sfifo_wr_wd[6]; // 64   
	

	 wire [SFIFO_WIDTH-1:0] slow_fifo_dout_2;
	 wire [7:0] sfifo_rd_wd_2;

	slfifo Slow_FIFO (
		.aclr(SYS_RST),
		.data(sfifo_data_in),
		.wrclk(SCLK),
		.rdclk(SYS_CLK),
		.wrreq(sFIFO_wr),
		.rdreq(sfifo_rd),
		.q(slow_fifo_dout_2),
		.rdusedw(sfifo_rd_wd_2), 
		.wrusedw(sfifo_wr_wd)
	);  
	
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
					1: begin sfifo_data_in <= {{`CON_REG_H8,`CON_REG_L8},status_reg}; p_state <= 2; end // pass through
					2: begin sfifo_data_in <= {16'b0,temp}; p_state <= 3; end // pass through
					3: begin sfifo_data_in <= BEAMnA1; p_state <= 4; end // unique
					
					4: begin sfifo_data_in <= BEAMnA2; p_state <= 5; end //unique
					5: begin sfifo_data_in <= {N_sample1,N_sample2}; p_state <= 6; end	 //unique
					6: begin sfifo_data_in <= fpDC1; p_state <= 7; end	//unique

					7: begin sfifo_data_in <= fpDC2; p_state <= 8; end
					8: begin sfifo_data_in <= 8; p_state <= 9; end 
					9: begin sfifo_data_in <= `ALPHA; p_state <= 10; end // pass through
					10: begin sfifo_data_in <= 10; p_state <= 11; end // std_dev of avg1
					11: begin sfifo_data_in <= 11; p_state <= 12; end // std_dev of avg2
					12: begin sfifo_data_in <= 12; p_state <= 13; end 
					13: begin sfifo_data_in <= avg_debug1; p_state <= 14; end 
					14: begin sfifo_data_in <= avg_debug2; p_state <= 15; end
					15: begin sfifo_data_in <= 15; p_state <= 16; end
					16: begin sfifo_data_in <= 16; p_state <= 17; end
					17: begin sfifo_data_in <= 17; p_state <= 18; end
					18: begin sfifo_data_in <= BL_SA1; p_state <= 19; end // unique - BL as integer
					19: begin sfifo_data_in <= peak1; p_state <= 20; end //remove in next rev
					20: begin sfifo_data_in <= peaknA1; p_state <= 21; end // unique - peak in nA (32 bit int)
					21: begin sfifo_data_in <= 18; p_state <= 22; end
					22: begin sfifo_data_in <= BL_SA2; p_state <= 23; end
					23: begin sfifo_data_in <= peak2; p_state <= 24; end //remove in next rev
					24: begin sfifo_data_in <= peaknA2; p_state <= 25; end
					25: begin sfifo_data_in <= 25; p_state <= 26; end
					
					26: begin sfifo_data_in <= fpVBL1; p_state <= 27; end // unique
					27: begin sfifo_data_in <= 27; p_state <= 28; end // std dev of peak1
					28: begin sfifo_data_in <= 28; p_state <= 29; end // std dev of peak2

					29: begin sfifo_data_in <= fpVBL2; p_state <= 30; end
					30: begin sfifo_data_in <= 30; p_state <= 31; end
					31: begin sfifo_data_in <= 31; p_state <= 32; end
					32: begin sFIFO_wr<= 0; p_state <= 0; end
					default:
						begin sFIFO_wr<= 0; p_state <= 0; end
				endcase
			end

	end
	
////////////////

//I2C eeprom interface ////////////////////////////////////
parameter CONF_BUF_SIZE = 128; //max = 128 bytes for 24AA025E48T for user application

reg  [7:0] configuration [CONF_BUF_SIZE-1:0]; //configuration data 
wire [7:0] eeprom_buffer [CONF_BUF_SIZE-1:0];

wire eeprom_busy,eeprom_data_valid;
wire rd_eeprom,wr_eeprom /*synthesis keep*/;

	I2C_eeprom eeprom_inst(
          .clk(SYS_CLK),   
          .rst(SYS_RST),
          .conf_data(configuration),
          .read(rd_eeprom),
          .write(wr_eeprom),
			 
			 .buffer(eeprom_buffer),
			 .busy(eeprom_busy),
			 .valid(eeprom_data_valid),
	
          .SDA(GPIO_1_8),
          .SCL(GPIO_1_6)               
                     );
							

							//================ Defining CPU to FPGA interface ===============
//Avalon Memory Mapped Slave Bus declariation	

wire avalon_read, avalon_write,avalon_cs/*synthesis keep*/;
wire [31:0] avalon_addr,avalon_readdata,avalon_writedata/*synthesis keep*/;

reg [31:0] dout;
assign avalon_readdata = dout;

parameter integer 	SR_ADDR = 0;
parameter integer 	CR_ADDR = 1;
//parameter integer 	MR_ADDR = 2;

parameter integer    FPGA_VER_ADDR = 3;  //FPGA version # 
parameter integer 	CH_SELECT_ADDR = 4; //select channel for FIFO transfer to host 
//parameter integer 	PCA_GAIN_ADDR = 5;

parameter integer 	ADC_INIT_ADDR = 6;

parameter integer 	SFIFO_WD_ADDR = 7;
parameter integer 	SFIFO_ADDR = 8;

parameter integer 	FIFO_CLR_ADDR = 9;
parameter integer 	FIFO_WD_ADDR = 10;
parameter integer 	FIFO_ADDR = 11;

//parameter integer 	BEAM_AVG_ADDR = 12;
//parameter integer 	BEAM_PEAK_ADDR = 13;

parameter integer 	EEPROM_RD_ADDR = 15;
parameter integer 	EEPROM_WR_ADDR = 16;

parameter integer 	CH0_ADDR = 20;
parameter integer 	CH1_ADDR = 21;

parameter integer 	ADC_READ_ADDR = 32;
parameter integer 	CAL_WAVE_ADDR = 33;

parameter integer 	IIR_OUT_BF_K1_ADDR = 38;
parameter integer 	IIR_OUT_BF_K2_ADDR = 39;

//parameter integer 	DCR_PU_ADDR = 40;
//parameter integer 	DCR_PD_ADDR = 41;

parameter integer 	ALPHA_ADDR = 42;

parameter integer 	FP_CH0_G_ADDR = 43;
parameter integer 	FP_CH0_Z_ADDR = 44;
parameter integer 	FP_CH1_G_ADDR = 45;
parameter integer 	FP_CH1_Z_ADDR = 46;

parameter integer 	IIR_OUT_SA_K1_ADDR = 47;
parameter integer 	IIR_OUT_SA_K2_ADDR = 48;

parameter integer 	DAC_SLOPE_ADDR = 49;
parameter integer 	DAC_OFFSET_ADDR = 50;

parameter integer MODULE_ID0_ADDR = 71;
parameter integer MODULE_ID1_ADDR = 72;

	
//=======================================================
//=======================================================
soc_system u0(
               //Clock&Reset
               .clk_clk(FPGA_CLK1_50),                                      //                            clk.clk
               .reset_reset_n(hps_fpga_reset_n),                            //                          reset.reset_n
               //HPS ddr3
               .memory_mem_a(HPS_DDR3_ADDR),                                //                         memory.mem_a
               .memory_mem_ba(HPS_DDR3_BA),                                 //                               .mem_ba
               .memory_mem_ck(HPS_DDR3_CK_P),                               //                               .mem_ck
               .memory_mem_ck_n(HPS_DDR3_CK_N),                             //                               .mem_ck_n
               .memory_mem_cke(HPS_DDR3_CKE),                               //                               .mem_cke
               .memory_mem_cs_n(HPS_DDR3_CS_N),                             //                               .mem_cs_n
               .memory_mem_ras_n(HPS_DDR3_RAS_N),                           //                               .mem_ras_n
               .memory_mem_cas_n(HPS_DDR3_CAS_N),                           //                               .mem_cas_n
               .memory_mem_we_n(HPS_DDR3_WE_N),                             //                               .mem_we_n
               .memory_mem_reset_n(HPS_DDR3_RESET_N),                       //                               .mem_reset_n
               .memory_mem_dq(HPS_DDR3_DQ),                                 //                               .mem_dq
               .memory_mem_dqs(HPS_DDR3_DQS_P),                             //                               .mem_dqs
               .memory_mem_dqs_n(HPS_DDR3_DQS_N),                           //                               .mem_dqs_n
               .memory_mem_odt(HPS_DDR3_ODT),                               //                               .mem_odt
               .memory_mem_dm(HPS_DDR3_DM),                                 //                               .mem_dm
               .memory_oct_rzqin(HPS_DDR3_RZQ),                             //                               .oct_rzqin
               //HPS ethernet
               .hps_0_hps_io_hps_io_emac1_inst_TX_CLK(HPS_ENET_GTX_CLK),    //                   hps_0_hps_io.hps_io_emac1_inst_TX_CLK
               .hps_0_hps_io_hps_io_emac1_inst_TXD0(HPS_ENET_TX_DATA[0]),   //                               .hps_io_emac1_inst_TXD0
               .hps_0_hps_io_hps_io_emac1_inst_TXD1(HPS_ENET_TX_DATA[1]),   //                               .hps_io_emac1_inst_TXD1
               .hps_0_hps_io_hps_io_emac1_inst_TXD2(HPS_ENET_TX_DATA[2]),   //                               .hps_io_emac1_inst_TXD2
               .hps_0_hps_io_hps_io_emac1_inst_TXD3(HPS_ENET_TX_DATA[3]),   //                               .hps_io_emac1_inst_TXD3
               .hps_0_hps_io_hps_io_emac1_inst_RXD0(HPS_ENET_RX_DATA[0]),   //                               .hps_io_emac1_inst_RXD0
               .hps_0_hps_io_hps_io_emac1_inst_MDIO(HPS_ENET_MDIO),         //                               .hps_io_emac1_inst_MDIO
               .hps_0_hps_io_hps_io_emac1_inst_MDC(HPS_ENET_MDC),           //                               .hps_io_emac1_inst_MDC
               .hps_0_hps_io_hps_io_emac1_inst_RX_CTL(HPS_ENET_RX_DV),      //                               .hps_io_emac1_inst_RX_CTL
               .hps_0_hps_io_hps_io_emac1_inst_TX_CTL(HPS_ENET_TX_EN),      //                               .hps_io_emac1_inst_TX_CTL
               .hps_0_hps_io_hps_io_emac1_inst_RX_CLK(HPS_ENET_RX_CLK),     //                               .hps_io_emac1_inst_RX_CLK
               .hps_0_hps_io_hps_io_emac1_inst_RXD1(HPS_ENET_RX_DATA[1]),   //                               .hps_io_emac1_inst_RXD1
               .hps_0_hps_io_hps_io_emac1_inst_RXD2(HPS_ENET_RX_DATA[2]),   //                               .hps_io_emac1_inst_RXD2
               .hps_0_hps_io_hps_io_emac1_inst_RXD3(HPS_ENET_RX_DATA[3]),   //                               .hps_io_emac1_inst_RXD3
               //HPS SD card
               .hps_0_hps_io_hps_io_sdio_inst_CMD(HPS_SD_CMD),              //                               .hps_io_sdio_inst_CMD
               .hps_0_hps_io_hps_io_sdio_inst_D0(HPS_SD_DATA[0]),           //                               .hps_io_sdio_inst_D0
               .hps_0_hps_io_hps_io_sdio_inst_D1(HPS_SD_DATA[1]),           //                               .hps_io_sdio_inst_D1
               .hps_0_hps_io_hps_io_sdio_inst_CLK(HPS_SD_CLK),              //                               .hps_io_sdio_inst_CLK
               .hps_0_hps_io_hps_io_sdio_inst_D2(HPS_SD_DATA[2]),           //                               .hps_io_sdio_inst_D2
               .hps_0_hps_io_hps_io_sdio_inst_D3(HPS_SD_DATA[3]),           //                               .hps_io_sdio_inst_D3
               //HPS USB
               .hps_0_hps_io_hps_io_usb1_inst_D0(HPS_USB_DATA[0]),          //                               .hps_io_usb1_inst_D0
               .hps_0_hps_io_hps_io_usb1_inst_D1(HPS_USB_DATA[1]),          //                               .hps_io_usb1_inst_D1
               .hps_0_hps_io_hps_io_usb1_inst_D2(HPS_USB_DATA[2]),          //                               .hps_io_usb1_inst_D2
               .hps_0_hps_io_hps_io_usb1_inst_D3(HPS_USB_DATA[3]),          //                               .hps_io_usb1_inst_D3
               .hps_0_hps_io_hps_io_usb1_inst_D4(HPS_USB_DATA[4]),          //                               .hps_io_usb1_inst_D4
               .hps_0_hps_io_hps_io_usb1_inst_D5(HPS_USB_DATA[5]),          //                               .hps_io_usb1_inst_D5
               .hps_0_hps_io_hps_io_usb1_inst_D6(HPS_USB_DATA[6]),          //                               .hps_io_usb1_inst_D6
               .hps_0_hps_io_hps_io_usb1_inst_D7(HPS_USB_DATA[7]),          //                               .hps_io_usb1_inst_D7
               .hps_0_hps_io_hps_io_usb1_inst_CLK(HPS_USB_CLKOUT),          //                               .hps_io_usb1_inst_CLK
               .hps_0_hps_io_hps_io_usb1_inst_STP(HPS_USB_STP),             //                               .hps_io_usb1_inst_STP
               .hps_0_hps_io_hps_io_usb1_inst_DIR(HPS_USB_DIR),             //                               .hps_io_usb1_inst_DIR
               .hps_0_hps_io_hps_io_usb1_inst_NXT(HPS_USB_NXT),             //                               .hps_io_usb1_inst_NXT
               //HPS SPI
               .hps_0_hps_io_hps_io_spim1_inst_CLK(HPS_SPIM_CLK),           //                               .hps_io_spim1_inst_CLK
               .hps_0_hps_io_hps_io_spim1_inst_MOSI(HPS_SPIM_MOSI),         //                               .hps_io_spim1_inst_MOSI
               .hps_0_hps_io_hps_io_spim1_inst_MISO(HPS_SPIM_MISO),         //                               .hps_io_spim1_inst_MISO
               .hps_0_hps_io_hps_io_spim1_inst_SS0(HPS_SPIM_SS),            //                               .hps_io_spim1_inst_SS0
               //HPS UART
               .hps_0_hps_io_hps_io_uart0_inst_RX(HPS_UART_RX),             //                               .hps_io_uart0_inst_RX
               .hps_0_hps_io_hps_io_uart0_inst_TX(HPS_UART_TX),             //                               .hps_io_uart0_inst_TX
               //HPS I2C1
               .hps_0_hps_io_hps_io_i2c0_inst_SDA(HPS_I2C0_SDAT),           //                               .hps_io_i2c0_inst_SDA
               .hps_0_hps_io_hps_io_i2c0_inst_SCL(HPS_I2C0_SCLK),           //                               .hps_io_i2c0_inst_SCL
               //HPS I2C2
               .hps_0_hps_io_hps_io_i2c1_inst_SDA(HPS_I2C1_SDAT),           //                               .hps_io_i2c1_inst_SDA
               .hps_0_hps_io_hps_io_i2c1_inst_SCL(HPS_I2C1_SCLK),           //                               .hps_io_i2c1_inst_SCL
               //GPIO
               .hps_0_hps_io_hps_io_gpio_inst_GPIO09(HPS_CONV_USB_N),       //                               .hps_io_gpio_inst_GPIO09
               .hps_0_hps_io_hps_io_gpio_inst_GPIO35(HPS_ENET_INT_N),       //                               .hps_io_gpio_inst_GPIO35
               .hps_0_hps_io_hps_io_gpio_inst_GPIO40(HPS_LTC_GPIO),         //                               .hps_io_gpio_inst_GPIO40
               .hps_0_hps_io_hps_io_gpio_inst_GPIO53(HPS_LED),              //                               .hps_io_gpio_inst_GPIO53
               .hps_0_hps_io_hps_io_gpio_inst_GPIO54(HPS_KEY),              //                               .hps_io_gpio_inst_GPIO54
               .hps_0_hps_io_hps_io_gpio_inst_GPIO61(HPS_GSENSOR_INT),      //                               .hps_io_gpio_inst_GPIO61
               //FPGA Partion
               .led_pio_external_connection_export(fpga_led_internal),      //    led_pio_external_connection.export
               .dipsw_pio_external_connection_export(SW),                   //  dipsw_pio_external_connection.export
               .button_pio_external_connection_export(fpga_debounced_buttons),
                                                                            // button_pio_external_connection.export
               //.hps_0_h2f_reset_reset_n(hps_fpga_reset_n),                  //                hps_0_h2f_reset.reset_n
               
					.hps_0_f2h_cold_reset_req_reset_n(~Cold_Reset_Req),          //       hps_0_f2h_cold_reset_req.reset_n
               .hps_0_f2h_debug_reset_req_reset_n(~hps_debug_reset),        //      hps_0_f2h_debug_reset_req.reset_n
               .hps_0_f2h_stm_hw_events_stm_hwevents(stm_hw_events),        //        hps_0_f2h_stm_hw_events.stm_hwevents
               .hps_0_f2h_warm_reset_req_reset_n(~hps_warm_reset),          //       hps_0_f2h_warm_reset_req.reset_n
									                      
					.myavalonbus32_0_conduit_end_addr       (avalon_addr),       //myavalonbus32_0_avalon_slave.address
					.myavalonbus32_0_conduit_end_read       (avalon_read),      // .read
					.myavalonbus32_0_conduit_end_write      (avalon_write),     // .write
					.myavalonbus32_0_conduit_end_readdata   (avalon_readdata),   // .readdata
					.myavalonbus32_0_conduit_end_writedata  (avalon_writedata), // .writedata
					.myavalonbus32_0_conduit_end_cs 			 (avalon_cs),        // .chipselect
					.myavalonbus32_0_conduit_end_bus_clk    ()           //  myavalonbus32_0_clk.clk
		
				
           );

//Avalon Bus interface 	

wire ch0_polarity = `CON_REG_L8[0]; 
wire ch1_polarity = `CON_REG_L8[1]; 

wire ena_ch1_cal = `CON_REG_L8[2];
wire ena_ch2_cal = `CON_REG_L8[3];

wire [2:0] toroid_type = {`CON_REG_L8[6],`CON_REG_L8[5],`CON_REG_L8[4]};

//CON_REG_L8[7] not in use so far 

wire [2:0] AVG_MODE = {`CON_REG_H8[2],`CON_REG_H8[1],`CON_REG_H8[0]};
wire [2:0] HIST_MODE = {`CON_REG_H8[5],`CON_REG_H8[4],`CON_REG_H8[3]};
wire [1:0] METHOD = {`CON_REG_H8[7],`CON_REG_H8[6]};

wire Ch1_Cal_On = ena_ch1_cal? 1 : 0;
wire Ch2_Cal_On = ena_ch2_cal? 1 : 0;

wire Ch1_DC_On = ~Ch1_Cal_On;
wire Ch2_DC_On = ~Ch2_Cal_On;

wire [15:0] status_reg = {6'b0,ch_gain[1],ch_gain[0],ch_reg[1:0],ch2_overflow, ch1_overflow,ISIS_pulse_lost,1'b0};
	
//{ch7,ch6,...ch0}, each channel use two bits for mux1,mux0

assign ch_gain[0] = `PCA_GAIN_BIT_L8[1:0];
assign ch_gain[1] = `PCA_GAIN_BIT_L8[3:2];


wire [FFIFO_WIDTH-1:0] fast_fifo_dout;
wire [14:0] fifo_word /*synthesis keep*/;
	
reg fifo_clr_reg; //needs to reset by itself after one SYS_CLK
wire avalon_write_i = avalon_write & avalon_cs;
wire avalon_read_i = avalon_read & avalon_cs;

reg avalon_write_o,avalon_read_o /*synthesis keep*/;
wire fifo_rd /*synthesis keep*/;
assign fifo_rd = (avalon_addr == FIFO_ADDR & (avalon_read_i == 1));


wire [SFIFO_WIDTH-1:0] slow_fifo_dout = ch_select? ch2_slow_fifo_dout : ch1_slow_fifo_dout;
wire [7:0] sfifo_rd_wd = ch_select? ch2_sfifo_rd_wd : ch1_sfifo_rd_wd;

wire sfifo_rd /*synthesis keep*/;

assign sfifo_rd = (avalon_addr == SFIFO_ADDR & (avalon_read_i == 1)); 


assign rd_eeprom = (avalon_addr == EEPROM_RD_ADDR & (avalon_write_o == 1)); //load eeprom -> buffer
assign wr_eeprom = (avalon_addr == EEPROM_WR_ADDR & (avalon_write_o == 1));//write buffer -> eeprom

always @ (posedge SYS_CLK)
     avalon_write_o <= avalon_write_i;
	  
always @ (posedge SYS_CLK)
     avalon_read_o <= avalon_read_i;	  

////////////////////////////////////////////////////////////////////////////	  
//Registers and Configuration data write/read  
	  
always@(posedge SYS_CLK)
	if (~eeprom_busy && eeprom_data_valid) configuration <= eeprom_buffer; 
	else begin
   /*   Write to Control Register   */
	if ((avalon_addr == CR_ADDR) & (avalon_write_o == 1) ) 
			{`CON_REG_H8,`CON_REG_L8} <= avalon_writedata[15:0]; 	
	/*   Write to ch_select Register   */
	if ((avalon_addr == CH_SELECT_ADDR) & (avalon_write_o == 1) ) 
			ch_reg <= avalon_writedata[15:0]; 
			  
	/*   Read from Control Register   */		
	if ((avalon_addr == CR_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`CON_REG_H8,`CON_REG_L8}; 

	/*   Read from Status Register   */		
	if ((avalon_addr == SR_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,status_reg}; 
			
   /*   Read FPGA version   */		
	if ((avalon_addr == FPGA_VER_ADDR) & (avalon_read_o == 1)) 
			dout <= FPGA_VERSION_NO; 

	/*   slow fifo occupancy     */		
	if ((avalon_addr == SFIFO_WD_ADDR) & (avalon_read_o == 1)) 
			begin comm_act <= ~comm_act; dout <= {16'b0,8'b0,sfifo_rd_wd_2}; end
	
	/*   Read slow fifo     */		
	if ((avalon_addr == SFIFO_ADDR) & (avalon_read_o == 1)) 
			dout <= slow_fifo_dout_2; 	
	
	/*   Reset fast fifo     */		
	if ((avalon_addr == FIFO_CLR_ADDR) & (avalon_write_o == 1)) 
			fifo_clr_reg <= 1; 	else fifo_clr_reg <= 0; 
	
		/* ADC init pulse    */		
	if ((avalon_addr == ADC_INIT_ADDR) & (avalon_read_o == 1)) 
			ADC_init_cmd <= 1; 	else ADC_init_cmd <= 0; 
	
		/* ADC read command pulse    */		
	if ((avalon_addr == ADC_READ_ADDR) & (avalon_read_o == 1)) 
			ADC_read_cmd <= 1; 	else ADC_read_cmd <= 0; 
  			
	/*   Read fast fifo occupancy    */		
	if ((avalon_addr == FIFO_WD_ADDR) & (avalon_read_o == 1)) 
			dout <= {16'b0,3'b0,fifo_word}; 
			
	/*   Read fast fifo   */		
	if ((avalon_addr == FIFO_ADDR) & (avalon_read_o == 1)) 
			dout <= {16'b0,fast_fifo_dout}; 	
	
//   /*   Write to Mini-PCA Gain bits   */
//	if ((avalon_addr == PCA_GAIN_ADDR) & (avalon_write_o == 1) ) 
//			{`PCA_GAIN_BIT_H8,`PCA_GAIN_BIT_L8} <= avalon_writedata[15:0]; 
//		
//	/*   Read from Mini-PCA Gain Register   */
//	if ((avalon_addr == PCA_GAIN_ADDR) & (avalon_read_o == 1) ) 
//			dout <= {16'b0,`PCA_GAIN_BIT_H8,`PCA_GAIN_BIT_L8};  	
	
	/*   Write/Read to CAL_WAVE  */
	if ((avalon_addr == CAL_WAVE_ADDR) & (avalon_write_o == 1) ) 
		  {cal_amp_reg,cal_dc_reg} <= avalon_writedata[15:0]; 	
	if ((avalon_addr == CAL_WAVE_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,cal_amp_reg,cal_dc_reg};  

	       /*   Write/Read to IIR_OUT_BF_K1  */
	if ((avalon_addr == IIR_OUT_BF_K1_ADDR) & (avalon_write_o == 1) ) 
			`IIR_OUT_BF_K1 <= avalon_writedata; 	
	if ((avalon_addr == IIR_OUT_BF_K1_ADDR) & (avalon_read_o == 1) ) 
			dout <= `IIR_OUT_BF_K1;  
	
	       /*   Write/Read to IIR_OUT_BF_K2  */
	if ((avalon_addr == IIR_OUT_BF_K2_ADDR) & (avalon_write_o == 1) ) 
			`IIR_OUT_BF_K2 <= avalon_writedata; 
   if ((avalon_addr == IIR_OUT_BF_K2_ADDR) & (avalon_read_o == 1) ) 
			dout <= `IIR_OUT_BF_K2;  
			
			/*   Write/Read to IIR_OUT_SA_K1  */
	if ((avalon_addr == IIR_OUT_SA_K1_ADDR) & (avalon_write_o == 1) ) 
			`IIR_OUT_SA_K1 <= avalon_writedata; 
   if ((avalon_addr == IIR_OUT_SA_K1_ADDR) & (avalon_read_o == 1) ) 
			dout <= `IIR_OUT_SA_K1;  
			
	       /*   Write/Read to IIR_OUT_SA_K2  */
	if ((avalon_addr == IIR_OUT_SA_K2_ADDR) & (avalon_write_o == 1) ) 
			`IIR_OUT_SA_K2 <= avalon_writedata; 
   if ((avalon_addr == IIR_OUT_SA_K2_ADDR) & (avalon_read_o == 1) ) 
			dout <= `IIR_OUT_SA_K2;  			
			
			
	      /*   Write/Read to FP_CH0_G  */ 
	if ((avalon_addr == FP_CH0_G_ADDR) & (avalon_write_o == 1) ) 
			`FP_CH0_G <= avalon_writedata; 
	if ((avalon_addr == FP_CH0_G_ADDR) & (avalon_read_o == 1) ) 
			dout <= `FP_CH0_G;  
			 /*   Write/Read to FP_CH0_Z  */ 
	if ((avalon_addr == FP_CH0_Z_ADDR) & (avalon_write_o == 1) ) 
			`FP_CH0_Z <= avalon_writedata; 
	if ((avalon_addr == FP_CH0_Z_ADDR) & (avalon_read_o == 1) ) 
			dout <= `FP_CH0_Z;  
			
	      /*   Write/Read to FP_CH1_G  */ 
	if ((avalon_addr == FP_CH1_G_ADDR) & (avalon_write_o == 1) ) 
			`FP_CH1_G <= avalon_writedata; 
	if ((avalon_addr == FP_CH1_G_ADDR) & (avalon_read_o == 1) ) 
			dout <= `FP_CH1_G;  
			 /*   Write/Read to FP_CH1_Z  */ 
	if ((avalon_addr == FP_CH1_Z_ADDR) & (avalon_write_o == 1) ) 
			`FP_CH1_Z <= avalon_writedata; 
	if ((avalon_addr == FP_CH1_Z_ADDR) & (avalon_read_o == 1) ) 
			dout <= `FP_CH1_Z; 
			
			/*   Write/Read to ALPHA  */			
	if ((avalon_addr == ALPHA_ADDR) & (avalon_write_o == 1) ) 
			`ALPHA <= avalon_writedata; 
	if ((avalon_addr == ALPHA_ADDR) & (avalon_read_o == 1) ) 
			dout <= `ALPHA; 
			
			 /*   Write/Read to MODULE_ID0  */
	if ((avalon_addr == MODULE_ID0_ADDR) & (avalon_write_o == 1) ) 
			`MODULE_ID0 <= avalon_writedata; 
	if ((avalon_addr == MODULE_ID0_ADDR) & (avalon_read_o == 1) ) 
			dout <= `MODULE_ID0;  
		
			 /*   Write/Read to MODULE_ID1  */
	if ((avalon_addr == MODULE_ID1_ADDR) & (avalon_write_o == 1) ) 
			`MODULE_ID1 <= avalon_writedata; 
	if ((avalon_addr == MODULE_ID1_ADDR) & (avalon_read_o == 1) ) 
			dout <= `MODULE_ID1;  
			
end //always

		
////////////////////////////////////////////////////////////
//Fast FIFO to transfer ADC rate data from FPGA to SoC
//fifo4096 has been changed to 32 bit data width, on July 5,2019	
// to fast fifo 
 	
	wire fast_FIFO_rst = SYS_RST | fifo_clr_reg;
   wire fifo_wr /*synthesis keep*/;
	
	wire fast_fifo_full;/*synthesis keep*/
   wire fast_fifo_empty; /*synthesis keep*/
	
	wire [FFIFO_WIDTH-1:0] fifo_din = ch_select? ch2_fifo_din : ch1_fifo_din;
	wire fifo_din_valid = ch_select? ch2_fifo_din_valid : ch1_fifo_din_valid;
	
	// changed to 16384
	fifo4096 Fast_FIFO (
		.aclr(fast_FIFO_rst), //
		.wrclk(SCLK), //
		.rdclk(SYS_CLK), //
		.data(fifo_din), // 32 bit
		.wrreq(fifo_wr), //
		.rdreq(fifo_rd),
		.q(fast_fifo_dout), // 32 bit
		.wrfull(fast_fifo_full), //
		.wrempty(fast_fifo_empty),
		.wrusedw(fifo_word) //
	);
	
	fifo_control fifo_control_inst(
		.RUN(1'b1),
		.rst(SYS_RST),
		.clk(SCLK),

      .fifo_full(fast_fifo_full),
		.fifo_empty(fast_fifo_empty),
		.data_valid(fifo_din_valid), //
		
		.wr(fifo_wr), // output, write Fast fifo
	
		.busy() // output, not in use
	);
	
//=========== DHT11 sensor ========================
	wire [15:0] temp, humi;
dht11 temp_sensor(
	.i_clk(SYS_CLK),
	.i_rst_n(1'b1),
	.io_data(GPIO_0_28),
	.o_temp(temp),
	.o_humi(humi)
	);


//========LED ============================

wire LED_FPGA;
wire LED_COMM = comm_act;

flash_LED flash_led_inst(
    .clk(SCLK),  //35 MHz clock 
	 .pulse(ISIS_pulse_trimed), //1 sclk pulse
	 .pulse_lost(ISIS_pulse_lost), //1 if no isis_pulse for 0.95 seconds
	 .led(LED_FPGA) // 
    );
	
	
// Debounce logic to clean out glitches within 1ms		
debounce debounce_inst(
             .clk(fpga_clk_50),
             .reset_n(hps_fpga_reset_n),
             .data_in(KEY),
             .data_out(fpga_debounced_buttons)
         );
defparam debounce_inst.WIDTH = 2;
defparam debounce_inst.POLARITY = "LOW";
defparam debounce_inst.TIMEOUT = 50000;               // at 50Mhz this is a debounce time of 1ms
defparam debounce_inst.TIMEOUT_WIDTH = 16;            // ceil(log2(TIMEOUT))

// Source/Probe megawizard instance
hps_reset hps_reset_inst(
              .source_clk(fpga_clk_50),
              .source(hps_reset_req)
          );

altera_edge_detector pulse_cold_reset(
                         .clk(fpga_clk_50),
                         .rst_n(hps_fpga_reset_n),
                         .signal_in(Cold_Reset_Req),
                         .pulse_out(hps_cold_reset)
                     );
defparam pulse_cold_reset.PULSE_EXT = 6;
defparam pulse_cold_reset.EDGE_TYPE = 1;
defparam pulse_cold_reset.IGNORE_RST_WHILE_BUSY = 1;

altera_edge_detector pulse_warm_reset(
                         .clk(fpga_clk_50),
                         .rst_n(hps_fpga_reset_n),
                         .signal_in(hps_reset_req[1]),
                         .pulse_out(hps_warm_reset)
                     );
defparam pulse_warm_reset.PULSE_EXT = 2;
defparam pulse_warm_reset.EDGE_TYPE = 1;
defparam pulse_warm_reset.IGNORE_RST_WHILE_BUSY = 1;

altera_edge_detector pulse_debug_reset(
                         .clk(fpga_clk_50),
                         .rst_n(hps_fpga_reset_n),
                         .signal_in(hps_reset_req[2]),
                         .pulse_out(hps_debug_reset)
                     );
defparam pulse_debug_reset.PULSE_EXT = 32;
defparam pulse_debug_reset.EDGE_TYPE = 1;
defparam pulse_debug_reset.IGNORE_RST_WHILE_BUSY = 1;


	
endmodule
