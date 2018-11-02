/*
 * This module breaks out the GPIO pins into the pins from the adc modules
 * Written by David Bascelli
 * August 2018
 */
module pin_mux
    (
        inout   [35: 0] GPIO_0,
        inout   [35: 0] GPIO_1,

        //Broken out pins
	    input           ADC_RST,
		input           SELF_TEST,
		input           CPU_RESET,
		input           EEPROM_SCL,
		inout           EEPROM_SDA,
		input   [2:0]   FP_LED,
		input   [7:0]   OUTPUT_RELAY,
		output  [7:0]   ADC_MISO,
		input   [7:0]   ADC_MOSI,
		input   [7:0]   ADC_SCLK,
		input   [7:0]   ADC_ALARM,
		input   [7:0]   ADC_SS,
		input   [7:0]   ADC_MUX0,
		input   [7:0]   ADC_MUX1
    );
	assign GPIO_0[21]   = ADC_RST;
	assign GPIO_1[10]   = SELF_TEST;
	assign GPIO_0[26]   = CPU_RESET;
	assign GPIO_0[15]   = EEPROM_SCL;
	assign EEPROM_SDA   = GPIO_0[14];
	
    assign GPIO_1[8:6] = FP_LED;

	assign GPIO_1[35] = OUTPUT_RELAY[0];
	assign GPIO_1[33] = OUTPUT_RELAY[1];
	assign GPIO_1[30] = OUTPUT_RELAY[2];
	assign GPIO_1[28] = OUTPUT_RELAY[3];
	assign GPIO_1[26] = OUTPUT_RELAY[4];
	assign GPIO_1[27] = OUTPUT_RELAY[5];
	assign GPIO_1[24] = OUTPUT_RELAY[6];
	assign GPIO_1[23] = OUTPUT_RELAY[7];
	
	assign ADC_MISO     = { GPIO_1[4],  GPIO_0[27], GPIO_0[32], GPIO_1[21],
	                        GPIO_1[18], GPIO_0[17], GPIO_0[9],  GPIO_0[2]   };

	assign GPIO_0[12] = ADC_MOSI[0];
	assign GPIO_0[7]  = ADC_MOSI[1];
	assign GPIO_0[20] = ADC_MOSI[2];
	assign GPIO_0[23] = ADC_MOSI[3];
	assign GPIO_1[12] = ADC_MOSI[4];
	assign GPIO_0[33] = ADC_MOSI[5];
	assign GPIO_0[28] = ADC_MOSI[6];
	assign GPIO_1[3]  = ADC_MOSI[7];

	assign GPIO_0[4]  = ADC_SCLK[0];
	assign GPIO_0[5]  = ADC_SCLK[1];
	assign GPIO_0[18] = ADC_SCLK[2];
	assign GPIO_1[17] = ADC_SCLK[3];
	assign GPIO_0[25] = ADC_SCLK[4];
	assign GPIO_0[34] = ADC_SCLK[5];
	assign GPIO_0[29] = ADC_SCLK[6];
	assign GPIO_1[2]  = ADC_SCLK[7];

	assign GPIO_0[13] = ADC_ALARM[0];
	assign GPIO_0[1]  = ADC_ALARM[1];
	assign GPIO_0[19] = ADC_ALARM[2];
	assign GPIO_1[16] = ADC_ALARM[3];
	assign GPIO_1[14] = ADC_ALARM[4];
	assign GPIO_0[35] = ADC_ALARM[5];
	assign GPIO_0[30] = ADC_ALARM[6];
	assign GPIO_1[1]  = ADC_ALARM[7];

	assign GPIO_0[0]  = ADC_SS[0];
	assign GPIO_0[11] = ADC_SS[1];
	assign GPIO_0[16] = ADC_SS[2];
	assign GPIO_1[20] = ADC_SS[3];
	assign GPIO_1[19] = ADC_SS[4];
	assign GPIO_0[31] = ADC_SS[5];
	assign GPIO_1[0]  = ADC_SS[6];
	assign GPIO_1[5]  = ADC_SS[7];

	assign GPIO_0[10] = ADC_MUX0[0];
	assign GPIO_0[8]  = ADC_MUX0[1];
	assign GPIO_1[32] = ADC_MUX0[2];
	assign GPIO_1[29] = ADC_MUX0[3];
	assign GPIO_1[22] = ADC_MUX0[4];
	assign GPIO_0[22] = ADC_MUX0[5];
	assign GPIO_1[13] = ADC_MUX0[6];
	assign GPIO_1[9]  = ADC_MUX0[7];

	assign GPIO_0[3]  = ADC_MUX1[0];
	assign GPIO_0[6]  = ADC_MUX1[1];
	assign GPIO_1[34] = ADC_MUX1[2];
	assign GPIO_1[31] = ADC_MUX1[3];
	assign GPIO_1[25] = ADC_MUX1[4];
	assign GPIO_1[15] = ADC_MUX1[5];
	assign GPIO_0[24] = ADC_MUX1[6];
	assign GPIO_1[11] = ADC_MUX1[7];

endmodule // pin_mux
