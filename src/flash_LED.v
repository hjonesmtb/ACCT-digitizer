//////////////////////////////////////////////////////////////////////////////////
module flash_LED(
    input clk,  //10 MHz clock
	 output led

    );
//parameter  	FLASH_PERIOD = 200; //ms   
//parameter  MAX = 1000000*(FLASH_PERIOD/100);
reg [22: 0] counter;
assign led = counter[22];
always @(posedge clk)  counter <= counter + 1;
    
endmodule