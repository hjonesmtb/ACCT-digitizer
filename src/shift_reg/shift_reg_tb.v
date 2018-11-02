/*
 * Test bench fr the timer module
 * Written by David Bascelli
 * August 2018
 */
`timescale 10ns/1ns
module test;
    reg reset = 0;
    reg clk = 0;

    reg in = 0;
    wire [7:0] out;

    reg passed = 1;

    shift_reg 
        #(
            .N(8)
        )
        dut
        (
            .CLK(clk),
            .RST(reset),
            .IN(in),
            .OUT(out)
        );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end
    
    initial begin
        $dumpvars(0, test);


        reset = 1;
        in = 0;
        #10
        if (out !== 8'b00000000) passed = 0;
        reset = 0;
        in = 0;
        #10 if (out !== 8'b00000000) passed = 0;
        in = 1;
        #10 if (out !== 8'b00000001) passed = 0;
        in = 0;
        #10 if (out !== 8'b00000010) passed = 0;
        in = 1;
        #10 if (out !== 8'b00000101) passed = 0;
        in = 0;
        #20 if (out !== 8'b00010100) passed = 0;
        in = 1;
        #30 if (out !== 8'b10100111) passed = 0;
        in = 0;
        #10 if (out !== 8'b01001110) passed = 0;
        reset = 1;
        in = 0;
        #10 if (out !== 8'b00000000) passed = 0;


        
        if (passed)
            $display("Test Passed");
        else
            $display("Test Failed");

        $finish;


    end

endmodule // test
