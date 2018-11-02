/*
 * Test bench fr the timer module
 * Written by David Bascelli
 * August 2018
 */
`timescale 10ns/1ns
`define OVL_ASSERT_ON
`include "assert_always.vlib"
`include "assert_never.vlib"
module test;
    reg reset = 0;
    reg clk = 0;

    reg passed = 1;

    wire done;
    
    timer 
        #(
            .MATCH_VALUE(5)
        )
        dut
        (
            .CLK(clk),
            .RST(reset),
            .DONE(done)
        );

    assert_never 
        #(
            `OVL_ERROR,
            `OVL_ASSERT,
            "timer_overflow",
            `OVL_COVER_NONE
        )
        timer_overflow
        (
            .clk(clk),
            .reset_n(~reset),
            .test_expr(dut.count > 5)
        );

    assert_always
        #(
            `OVL_ERROR,
            `OVL_ASSERT,
            "too_few_bits",
            `OVL_COVER_NONE
        )
        too_few_bits
        (
            .clk(clk),
            .reset_n(~reset),
            .test_expr(dut.MATCH_VALUE < 2**dut.COUNTER_BITS)
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
        #100
        if (done !== 0) passed = 0;
        reset = 0;
        #20
        if (done !== 0) passed = 0;
        #20
        if (done !== 0) passed = 0;
        #10
        if (done !== 1) passed = 0;
        #60
        reset = 1;
        #10
        if (done !== 0) passed = 0;
        #10
        reset = 0;
        #10
        if (done !== 0) passed = 0;
        #40
        if (done !== 1) passed = 0;
        
        if (passed)
            $display("Test Passed");
        else
            $display("Test Failed");

        $finish;


    end

endmodule // test
