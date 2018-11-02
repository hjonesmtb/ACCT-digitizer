/*
 * Test bench for the filter module. Reads in test vectors and compares 
 * with simulation output.
 * Written by David Bascelli
 * August 2018
 */
`timescale 10ns/1ns
module test;
    `include "../param.v"
    reg reset = 0;
    reg clk = 0;
    reg [ADC_DATA_WIDTH-1:0] in;
    reg drdy = 0;
    wire [ADC_DATA_WIDTH-1:0] out;
    wire dnew;
    reg[ADC_DATA_WIDTH-1:0] inputData[99:0];
    reg[ADC_DATA_WIDTH-1:0] outputData[99:0];

    reg passed = 1;

    reg[ADC_DATA_WIDTH-1:0] outCorrect = 0;
    
    filter dut 
        (
            .DIN(in), 
            .DRDY(drdy),
            .SYS_CLK(clk), 
            .SYS_RST(reset),
            .DOUT(out),
            .DNEW(dnew)
        );

    integer i;
    initial begin
        for (i = 0; i < FILTER_TAPS; i = i + 1)
            $dumpvars(0, test.dut.taps[i]);
        $dumpvars(0, test);

        $display("Reading in test data");
        $readmemh("inputData.dat", inputData);
        $readmemh("outputData.dat", outputData);
        
        reset = 1;
        in=0;
        clk = 0;
        #1 clk = 0;
        #1 clk = 1;
        reset = 0;
        drdy = 0;
        for ( i = 0 ; i <= 99 ; i = i + 1 ) begin
            in = inputData[i];
            if (dnew) passed = 0;
            #1 clk = 0;
            #1 clk = 1;
            drdy = 1;
            #1 clk = 0;
            #1 clk = 1;
            if (dnew) passed = 0;
            #1 clk = 0; //Three cycles of drdy asserted
            #1 clk = 1; //Since only one posedge shoul
            if (!dnew) passed = 0;
            #1 clk = 0;
            #1 clk = 1;
            if (dnew) passed = 0;
            drdy = 0;   //have no change
            #1 clk = 0;
            #1 clk = 1;
            if (dnew) passed = 0;
            outCorrect = outputData[i];
            if (out !== outputData[i]) begin
                $display("Error at %d, input data %d, output expected %d, found %d", 
                                i, inputData[i], outputData[i], out);
                passed = 0;
            end
             
        end

        if (passed)
            $display("Test Passed");
        else
            $display("Test Failed");

        $finish;
    end
endmodule //test
