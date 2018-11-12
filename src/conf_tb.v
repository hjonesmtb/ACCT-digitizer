/*
conf_tb.v
test bench for conf.v, 
simulating I2C interface and 2-D configuration memory defined in FPGA
*/

`timescale 1ns/1ns

module conf_tb();

reg  [15:0] pca_gain_reg;

tri1       sda;
tri1       scl;

reg        wr_conf;
reg        rd;
reg        wr;

reg        clk;
reg        rst;

conf dut( .SYS_CLK(clk),   
          .SYS_RST(rst),
          
          .wr_conf(wr_conf),
          .rd_eeprom(rd),
          .wr_eeprom(wr),
          
	        .pca_gain_reg(pca_gain_reg),		 
			
          .sda(sda),
          .scl(scl) 
              );
              
             
initial
begin
   // INIT
   pca_gain_reg = 65535;
   
   wr_conf = 0;
   rd = 0;
   wr = 0;
   clk = 0;
   rst = 0;

   #10;

   // rst
   rst = 1;
   #20;
   rst = 0;
   
   // 
   wr_conf = 1;
   #20;
   wr_conf = 0;

   //write eeprom
   wr = 1;
   #20;
   wr = 0;
   

   #1000000;
   $stop;
end

// Match Xport 2.0 50 MHz clock on FPGA (20ns period)
always begin #10; clk = ~clk; end

endmodule