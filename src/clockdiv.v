//------------------------------------------------------------------------
// clockdiv.v
// Generate square wave according to defparam
// default to generate 10 Hz 50% DC square wave
// Nov.26,2018, Shengli Liu 
//
//------------------------------------------------------------------------

`timescale 1ns / 1ps

module clockdiv(input clk, input enable, output oclk);

  parameter CLK_PERIOD = 20;      // ns, clk period default 50 MHz
  parameter CLK_OUT_PERIOD = 100000000; //ns, outptu clock period, default 10 Hz
  parameter DIV = CLK_OUT_PERIOD/CLK_PERIOD;    // Divsion number: 5e+6
  parameter HDIV = DIV/2; 
  parameter CNT_WIDTH = 24;   // 
  

  reg [CNT_WIDTH-1:0] tick = 0;
  reg dclk = 0;
  assign oclk = dclk;
  
  always @(posedge clk)  begin
    if (enable) tick = tick + 1;
    if (enable && (tick >= HDIV)) begin
      tick = 0;
      dclk = ~dclk;
    end
  end
endmodule  