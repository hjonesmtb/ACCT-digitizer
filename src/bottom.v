`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// Find the minimum and maximum values over a 1024-sample window and output:
// - the average of the last 8 such minimum values (BL)
// - the average of the last 16 such minimum values (BL_16)
// - the peak-to-peak amplitude based on average max - average min (peak)
//////////////////////////////////////////////////////////////////////////////////

module bottom #(
    parameter ADC_BIT_WIDTH = 16
)(
    input clk, // SCLK 35 MHz
    input signed [ADC_BIT_WIDTH-1:0] signal,
	 input in_valid,
    output reg signed [ADC_BIT_WIDTH-1:0] BL,
    output reg signed [ADC_BIT_WIDTH-1:0] peak // New peak-to-peak output
);

    reg signed [ADC_BIT_WIDTH-1:0] min_reg;
    reg signed [ADC_BIT_WIDTH-1:0] max_reg;
    reg [9:0] sample_count = 0; // 10 bits to count up to 1023

    // Min pipeline
    reg signed [15:0] min_1, min_2, min_3, min_4;
    reg signed [15:0] min_5, min_6, min_7, min_8;
    reg signed [15:0] min_9, min_10, min_11, min_12;
    reg signed [15:0] min_13, min_14, min_15, min_16;
    reg signed [20:0] min_avg; // sum of 8 min values

    // Max pipeline
    reg signed [15:0] max_1, max_2, max_3, max_4;
    reg signed [15:0] max_5, max_6, max_7, max_8;
    reg signed [15:0] max_9, max_10, max_11, max_12;
    reg signed [15:0] max_13, max_14, max_15, max_16;
    reg signed [20:0] max_avg; // sum of 8 max values
	 reg signed [ADC_BIT_WIDTH-1:0] TOP;

//	reg in_valid_d;           // delayed version of in_valid
//	wire in_valid_rising = in_valid && !in_valid_d;
//	wire in_valid_falling = !in_valid && in_valid_d;
//	


    always @(posedge clk) begin
			//in_valid_d <= in_valid;
			if(in_valid) begin
			  // Start of 1024-sample window: initialize min/max
			  if (sample_count == 0) begin
					min_reg <= signal;
					max_reg <= signal;
			  end
			  else begin
					if (signal < min_reg)
						 min_reg <= signal;
					if (signal > max_reg)
						 max_reg <= signal;
			  end

			  // End of window: update history and compute averages
			  if (sample_count == 1023) begin
					// Shift min pipeline
					min_1 <= min_reg;
					min_2 <= min_1;
					min_3 <= min_2;
					min_4 <= min_3;
					min_5 <= min_4;
					min_6 <= min_5;
					min_7 <= min_6;
					min_8 <= min_7;
					min_9 <= min_8;
					min_10 <= min_9;
					min_11 <= min_10;
					min_12 <= min_11;
					min_13 <= min_12;
					min_14 <= min_13;
					min_15 <= min_14;
					min_16 <= min_15;

					// Shift max pipeline
					max_1 <= max_reg;
					max_2 <= max_1;
					max_3 <= max_2;
					max_4 <= max_3;
					max_5 <= max_4;
					max_6 <= max_5;
					max_7 <= max_6;
					max_8 <= max_7;
					max_9 <= max_8;
					max_10 <= max_9;
					max_11 <= max_10;
					max_12 <= max_11;
					max_13 <= max_12;
					max_14 <= max_13;
					max_15 <= max_14;
					max_16 <= max_15;

					// Compute averages
					min_avg <= min_1 + min_2 + min_3 + min_4 + min_5 + min_6 + min_7 + min_8 +
									  min_9 + min_10 + min_11 + min_12 + min_13 + min_14 + min_15 + min_16;
									  
					max_avg <= max_1 + max_2 + max_3 + max_4 + max_5 + max_6 + max_7 + max_8 +
									  max_9 + max_10 + max_11 + max_12 + max_13 + max_14 + max_15 + max_16;

					BL <= min_avg >>> 4; //min_avg >>> 4; // avg of last 8 min values
					TOP <= max_avg >>> 4; //max_avg >>> 4;
					peak <= TOP - BL; // avg(max) - avg(min), divided by 8

			  end

			  // Increment/reset sample counter
			  sample_count <= sample_count + 1;
		 end 
    end

endmodule
