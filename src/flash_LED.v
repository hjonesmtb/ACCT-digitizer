//////////////////////////////////////////////////////////////////////////////////
module flash_LED(
    input clk,  //35 MHz
	 input pulse,
	 output pulse_lost,
	 output led

    );
//parameter  	FLASH_PERIOD = 200; //ms   
//parameter  MAX = 1000000*(FLASH_PERIOD/100);

reg [8: 0] counter;
assign led = counter[8];
always @(posedge clk)  
  if (pulse) counter <= counter + 1;
  
reg [ 25:0] timer;
assign pulse_lost = timer[25]; //set if no pulse for 0.95 seconds
always @(posedge clk)  
  if (pulse) timer <= 0; 
  else if (~pulse_lost) timer <= timer + 1;
 
    
endmodule