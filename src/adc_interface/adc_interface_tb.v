/*
 * Test bench for the adc_interface. Fully exercises the model. Reads in
 * a test vector of serialized input for each output.
 * Written by David Bascelli
 * August 2018
 */
`timescale 10ns/1ns
`define OVL_ASSERT_ON
`include "assert_always.vlib"
`include "assert_never.vlib"
module test;
    `include "param.v"
    reg SYS_RST = 0;
    reg SPI_CLK = 0;

    reg ADC_MISO = 0;
    wire ADC_MOSI;
    wire ADC_SCLK;
    wire ADC_SS;

    wire [ADC_DATA_WIDTH-1:0] DOUT;
    wire DRDY;

    reg                         inputData   [10*ADC_DATA_WIDTH-1:0];
    reg [ADC_DATA_WIDTH-1:0]    outputData  [10-1:0];

    reg passed = 1;
    reg [ADC_DATA_WIDTH-1:0] expected = 0;
    reg [7:0] post = 0;

    adc_interface dut
        (
            .ADC_MISO(ADC_MISO),
            .ADC_MOSI(ADC_MOSI),
            .ADC_SCLK(ADC_SCLK),
            .ADC_SS(ADC_SS),
            .SPI_CLK(SPI_CLK),
            .SYS_RST(SYS_RST),
            .DOUT(DOUT),
            .DRDY(DRDY)
        );

    initial begin //10 MHz SPI Clock
        SPI_CLK= 0;
        forever begin
            #50 SPI_CLK= ~ SPI_CLK;
        end
    end
    
    integer i, j;
    initial begin
        $dumpvars(0, test);
        $monitor("Time = %6g, post %d, Passed = %d, STATE = %d", $time, post, passed, dut.STATE);

        $display("Reading in test data");
        $readmemh("inputData.dat", inputData);
        $readmemh("outputData.dat", outputData);

        SYS_RST = 1;
        ADC_MISO = 0;
        #100
        
        // Make sure outputs are cleared
        if (ADC_MOSI !== 0 || ADC_SCLK !== 0 || ADC_SS !== 1 || DOUT !== 0 || DRDY !== 0)passed=0;

        #100 SYS_RST = 0;

        // Move through state transitions to make sure output is correct
        post = 1;
        if (dut.STATE !== 5'b00001) passed = 0; //Should be in reset STATE
        #100 if (dut.STATE !== 5'b00010) passed = 0; //Should be in idle STATE
        if (ADC_SCLK !== 0 || ADC_SS !== 1 || DOUT !== 0 || DRDY !== 0)passed=0;
        post = 2;
        #10000 if (dut.STATE !== 5'b00100) passed = 0; //Should be in CONVD STATE
        if (ADC_SCLK !== 0 || ADC_SS !== 0 || DOUT !== 0 || DRDY !== 0)passed=0;
        post = 3;

        // Wait 100*SPI_CLOCK_FREQ*ADC_CYCLE_TIME
        #100 if (dut.STATE !== 5'b01000) passed = 0; //Should be in recv STATE
        if (ADC_SS !== 0 || DOUT !== 0 || DRDY !== 0)passed=0;
        post = 4;

        //Wait SPI_CLOCK_PERIOD*16
        //Make sure we are getting a clock on the output pin
        if (ADC_SCLK !== 1)passed=0;
        #50
        if (ADC_SCLK !== 0)passed=0;
        #50
        if (ADC_SCLK !== 1)passed=0;
        #50
        if (ADC_SCLK !== 0)passed=0;
        #50
        #1400
        
        if (dut.STATE !== 5'b10000) passed = 0; //Should be in output STATE
        if (ADC_SCLK !== 0 || ADC_SS !== 1 || DOUT !== 0 || DRDY !== 1)passed=0;
        post = 5;

        #100 if (dut.STATE !== 5'b00010) passed = 0; //Should be in idle STATE
        if (ADC_SCLK !== 0 || ADC_SS !== 1 || DOUT !== 0 || DRDY !== 0)passed=0;
        post = 6;

        SYS_RST = 1;
        #100 SYS_RST = 0;
        #100; //Idle State

        // Test Shifting Data Into the system from the test vector and
        // checking the output

        for ( i = 0; i < 10; i++) begin
            wait (~ADC_SS); //Wait for ADC_SS to go low (transmission begins)
            for ( j = 0; j < ADC_DATA_WIDTH; j++) begin
                wait (ADC_SCLK);
                ADC_MISO = inputData[i*ADC_DATA_WIDTH + j];
                wait (~ADC_SCLK);
            end
            wait (DRDY) //Wait for ADC_SS to go high again (transmission done)
            #100
            expected = outputData[i];
            if (expected != outputData[i]) begin
                passed = 0;
                $display("Data Mismatch: Found %d, Expected %d", DOUT, expected);
            end
        end

        #100

        if (passed)
            $display("Test Passed");
        else
            $display("Test Failed");
        $finish;
        
    end
endmodule //test
