// Avalon_Slave_Interface_32.v
// Implementation of the IP myAvalonSlaveMM32.
// modified to be straigt forwarding everything to outside of the HPS, SL, Oct11,2018
// changes of this file, need to re-generate in Platform designer.

`timescale 1 ps / 1 ps
module Avalon_Slave_Interface_32 (
		input  wire [15:0] avalon_slave_address,    // avalon_slave.address
		input  wire        avalon_slave_read,       //             .read
		input  wire        avalon_slave_write,      //             .write
		output wire [31:0] avalon_slave_readdata,   //             .readdata
		input  wire [31:0] avalon_slave_writedata,  //             .writedata
		input  wire        avalon_slave_chipselect, //             .chipselect
		input  wire        clk,                     //          clk.clk
		input  wire        reset_n,                 //        reset.reset_n
		output wire [15:0] addr,                    //  conduit_end.addr
		output wire        cs,                      //             .cs
		output wire        read,                    //             .read
		output wire        write,                   //             .write
		input  wire [31:0] readdata,                //             .readdata
		output wire [31:0] writedata,               //             .writedata
		output wire        bus_clk                  //             .bus_clk
	);




	assign avalon_slave_readdata = readdata;

	assign cs = avalon_slave_chipselect;

	assign read = avalon_slave_read;

	assign bus_clk = clk;

	assign addr = avalon_slave_address;

	assign write = avalon_slave_write;

	assign writedata = avalon_slave_writedata;

endmodule
