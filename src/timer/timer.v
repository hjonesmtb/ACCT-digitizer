/*
 * Simple timer which asserts a signal when the timer value
 * excedes the compare value.
 * Essentially outputs 1 when the clk counts more then match cycles
 * Counts posedge
 * Written by David Bascelli
 * August 2018
 */
module timer
    (
        input   CLK, //The clock (what we are counting)
        input   RST, //Input to reset the current count

        output  DONE //Becomes one when the timer exceds the value
    );
    parameter MATCH_VALUE = 0; //Value we are trying to match to
    parameter COUNTER_BITS = 8; //The number of bits in the counter

    reg [COUNTER_BITS-1:0] count;

    assign DONE = count >= match;
    
    // This is needed because I was getting a very inconsistent
    // error when I compared DONE directly to the MATCH_VALUE
    // Either something to do with how the paramaters was 
    // formated or a glitch in icarus verilog.
    reg [COUNTER_BITS-1:0] match = MATCH_VALUE;
    
    always @(posedge CLK, posedge RST)
        if (RST) begin
            count = 0;
        end
        else if (count < MATCH_VALUE) begin
            count = count + 1;
        end

endmodule // timer
