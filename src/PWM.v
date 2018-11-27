//------------------------------------------------------------------------
// PWM.v
// Generate 3 PWM signals
// January 5,2010, Shengli Liu 
//
//------------------------------------------------------------------------

`timescale 1ns / 1ps

module PWM(
   reset,
   clk, 
	inx,
	iny,
	inz,
	outx,
	outy,
	outz
	 );
   
   parameter COUNT_WIDTH = 7;
   parameter MAX_VALUE = 127; // log2(COUNT_WIDTH)-1
   
   
   input   reset, clk;
   input   [COUNT_WIDTH-1:0] inx,iny,inz; 
  
   output  outx,outy,outz;
   
   reg     outx,outy,outz;
      
   reg [COUNT_WIDTH-1:0] counter;
   reg [1:0] state; 
   parameter state_t0 = 4'd0,
             state_inc = 4'd1,
             state_dec = 4'd2;
   
       
   always @(posedge clk )
   begin
      if (reset == 1)
        begin 
           counter <= 0;
           state <= state_t0;
        end
		else
		  case( state )
           state_t0:
           begin
              counter <= 0; 
              state <= state_inc;
           end
           state_inc:
           begin
              if (counter == MAX_VALUE)
                state <= state_dec;
              else
                  counter <= counter + 1; 
           end
           state_dec:
           begin
               if (counter == 0)
                state <= state_inc;
              else
                  counter <= counter - 1; 
           end                   
           
           default:
           begin
               state <= state_t0;
           end
       endcase
   end
   
      
   
   always @(posedge clk )
   begin
      if (reset == 1) 
        begin
           outx <= 0; outy <= 0;outz <= 0;
        end
		else
		  begin
		     if (counter >= inx) outx <= 0;
		     else  outx <= 1;
		     if (counter >= iny) outy <= 0;
		     else  outy <= 1;
		     if (counter >= inz) outz <= 0;
		     else  outz <= 1;
		 
		  end
   
   end
   
   
   

endmodule
