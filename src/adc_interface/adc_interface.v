/*
 * SPI Interface for the ADS8689. Default settings are good for this use case
 * so no values are written to adc. Simply sets the slave select line based 
 * on the conversion timer, and shifts everything to an output register.
 * Asserts data ready when data is good.
 * The ADC output words are 32 bits, however only the first 16 of those
 * are ADC data (the reset are ADC status registers we don't care about)
 * so are reads are truncated to 16 bits.
 * Written by David Bascelli
 * August 2018
 */
module adc_interface
    (
        // Signals to/from adc
        input                           ADC_MISO,   // SPI data from ADC
        output                          ADC_MOSI,   // SPI data to ADC
        output                          ADC_SCLK,   // Clock to ADC, essentially 
                                                        // a gated SPI_CLK
        output                          ADC_SS,     // ADC Slave Select. Also triggers
                                                        // the ADC conversion 

        // Signals to/from system
        input                           SPI_CLK,    // A 10 MHz clock for driving 
                                                        // the ADC SPI bus
        input                           SYS_RST,    // System Reset
    
        output  [ADC_DATA_WIDTH-1:0]    DOUT,       // Data output
        output                          DRDY        // Data ready signal
    );
    `include "../param.v"

    assign ADC_MOSI = 0;

    reg ADC_SCLK_LATCH;
    assign ADC_SCLK = ADC_SCLK_LATCH & SPI_CLK;

    reg ADC_SS_LATCH;
    assign ADC_SS = ADC_SS_LATCH;

    reg [ADC_DATA_WIDTH-1:0] DOUT_LATCH;
    assign DOUT = DOUT_LATCH;

    reg DRDY_LATCH;
    assign DRDY = DRDY_LATCH;

    // Definition of states
    parameter   RESET_STATE     = 5'b00001, 
                IDLE_STATE      = 5'b00010, 
                CONVD_STATE     = 5'b00100, 
                RECV_STATE      = 5'b01000, 
                OUTPUT_STATE    = 5'b10000;

    reg [4:0] STATE;
    reg [4:0] NEXT_STATE;

    // Output shift register
    wire [ADC_DATA_WIDTH-1:0] shift_out_value;
    shift_reg
        #( 
            .N(ADC_DATA_WIDTH)
        ) 
        shift_out ( 
            .CLK(SPI_CLK), 
            .RST(SYS_RST), 
            .IN(ADC_MISO), 
            .OUT(shift_out_value)
        );

    // SPI_CLK cycle counter (5 bit counter)
    reg spi_clk_cnt_rst;
    wire spi_clk_cnt_done;
    timer 
        #( 
            .MATCH_VALUE(ADC_DATA_WIDTH - 2), // Starts at zero, 16 cycles
            .COUNTER_BITS(6)
        ) 
        spi_clk_cnt ( 
            .CLK(SPI_CLK), 
            .RST(spi_clk_cnt_rst || SYS_RST), 
            .DONE(spi_clk_cnt_done)
        );

    // ADC cycle time (waits 10 uS)
    reg cycle_cnt_rst;
    wire cycle_cnt_done;
    timer
        #( 
            .MATCH_VALUE(ADC_SPI_TIMER_WAIT - 1),
            .COUNTER_BITS(10)
        ) 
        cycle_cnt (
            .CLK(SPI_CLK),
            .RST(cycle_cnt_rst || SYS_RST),
            .DONE(cycle_cnt_done)
        );

    // Calculate Next State
    always @ (STATE or cycle_cnt_done or spi_clk_cnt_done)
    begin: CALC_NEXT_STATE
        case (STATE)
            RESET_STATE:
                NEXT_STATE <= IDLE_STATE;
            IDLE_STATE:
                if (cycle_cnt_done) NEXT_STATE <= CONVD_STATE;
					 else NEXT_STATE <= IDLE_STATE;
            CONVD_STATE:
                NEXT_STATE <= RECV_STATE;
            RECV_STATE:
                if (spi_clk_cnt_done) NEXT_STATE <= OUTPUT_STATE;
					 else NEXT_STATE <= RECV_STATE;
            OUTPUT_STATE:
                NEXT_STATE <= IDLE_STATE;
            default: NEXT_STATE <= RESET_STATE;
        endcase

    end

    // Go to the next state
    always @ (posedge SPI_CLK, posedge SYS_RST)
    begin: STATE_CLOCK
        if (SYS_RST) STATE = RESET_STATE;
        else STATE = NEXT_STATE;
    end

    // Calculate the output for each state
    always @(STATE or shift_out_value or DOUT_LATCH)
    begin: STATE_OUTUT
        case (STATE)
            IDLE_STATE: // We are waiting for conversion to finish
                begin
                    cycle_cnt_rst <= 0; // Start Counting for our next cycle
                    spi_clk_cnt_rst <= 1;
                    ADC_SS_LATCH <= 1;
                    ADC_SCLK_LATCH <= 0;
                    DRDY_LATCH <= 0;
                    //DOUT_LATCH <= DOUT_LATCH; //Latch data
                end
            CONVD_STATE: //Conversion is done, select device and wait one clock cycle
                begin
                    cycle_cnt_rst <= 1; 
                    spi_clk_cnt_rst <= 1;
                    ADC_SS_LATCH <= 0; // Select the device
                    ADC_SCLK_LATCH <= 0; // Done start clocking yet
                    //DRDY_LATCH <= 0;
                    //DOUT_LATCH <= DOUT_LATCH; //Latch data
                end
            RECV_STATE: // We wait to shift in 16 bits of adc data
                begin
                    cycle_cnt_rst <= 1;
                    spi_clk_cnt_rst <= 0; //Count 16 cycles
                    ADC_SS_LATCH <= 0; // Start transmission
                    ADC_SCLK_LATCH <= 1; //Ungate the clock
                   // DRDY_LATCH <= 0;
                   // DOUT_LATCH <= DOUT_LATCH; //Latch data
                end
            OUTPUT_STATE: //Signal that the iytoyt data us good
                begin
                    cycle_cnt_rst <= 1; //Reset counters
                    spi_clk_cnt_rst <= 1;
                    ADC_SS_LATCH <= 1; //End transmission
                    ADC_SCLK_LATCH <= 0; //stop clock
                    DRDY_LATCH <= 1; //Data is ready
                    DOUT_LATCH <= shift_out_value; //Move data from shift register to output latch
                end
            default: //This is also the RESET_STATE
                begin
                    cycle_cnt_rst <= 1;
                    spi_clk_cnt_rst <= 1;
                    ADC_SS_LATCH <= 1;
                    ADC_SCLK_LATCH <= 0;
                    DRDY_LATCH <= 0;
                    DOUT_LATCH <= 0;
                end
        endcase
    end


    

endmodule // adc_interface
