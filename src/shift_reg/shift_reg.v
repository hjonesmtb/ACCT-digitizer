/*
 * Simple shift register, modified from referencedesigner.com
 * Modified by David Bascelli
 * August 2018
 */
module shift_reg
	#(parameter N=8)
	(
		input CLK, RST,
		input IN,
		output [N-1:0] OUT
	);

	reg [N-1:0] r_reg;
	wire [N-1:0] r_next;


	always @(posedge CLK, posedge RST)
	begin
	  if (RST)
	     r_reg <= 0;
	  else
	     r_reg <= r_next;
	end	

	assign r_next = {r_reg[N-2:0], IN};
	assign OUT = r_reg;


endmodule
