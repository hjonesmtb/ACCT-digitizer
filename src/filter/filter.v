/* 
 * Simple moving average filter with adjustable taps 
 * Filters samples based on DRDY and assigns output
 * to SYS_CLK
 * Written by David Bascelli
 * August 2018
 */
module filter
    (
        input   [ADC_DATA_WIDTH-1:0]    DIN,    // Data from ADC
        input                           DRDY,   // Signal Indication data is ready
        input                           SYS_CLK,// System Clock
        input                           SYS_RST,// System reset
        output  [ADC_DATA_WIDTH-1:0]    DOUT,   // Filter data output
        output                          DNEW    // New output data 
                                                // alligned to sys_clk
    );
    `include "../param.v"
    
    assign DNEW = dnew_latch;
    reg dnew_latch;
    
    reg dnew_start;
    reg dnew_end;

    integer i;
    integer j;
    reg [ADC_DATA_WIDTH-1:0] taps [0:FILTER_TAPS-1];
    reg [ADC_DATA_WIDTH-1:0] dlatch;
    
    assign DOUT = dlatch;

    always @(posedge DRDY, posedge SYS_RST, posedge dnew_end) begin
        if(SYS_RST) dnew_start = 0;
        if (dnew_end) dnew_start = 0;
        else dnew_start = 1;
    end

    always @(posedge SYS_CLK, posedge SYS_RST) begin
        if (SYS_RST) begin
            dnew_latch = 0;
            dnew_end = 0; 
        end
        else if(dnew_end) begin
            dnew_end = 0; 
            dnew_latch = 0;
        end
        else if (dnew_start) begin
            dnew_latch = 1;
            dnew_end = 1;
        end
    end
     
    always @(posedge SYS_CLK, posedge SYS_RST) begin
        if (SYS_RST) begin
            dlatch = 0;
        end
        else begin
            dlatch = 0;
            for (i = 0; i < FILTER_TAPS; i = i + 1 ) begin
                dlatch = dlatch + taps[i] / FILTER_TAPS;
            end
        end
    end

    always @(posedge DRDY, posedge SYS_RST) begin
        for (j = FILTER_TAPS-1; j >= 0; j = j - 1) begin
            if (SYS_RST)
                taps[j] = 0;
            else if (j == 0)
                taps[j] = DIN;
            else
                taps[j] = taps[j - 1];
        end
    end

endmodule // counter
