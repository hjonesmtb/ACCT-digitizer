// sinewave_gen - for simulation, non-synthesizable
// modified by SL, July 3,2019

`timescale 1 ns / 1 ns

module sinewave
  (  
   input clk,
   input reset,
   
   output reg [31:0] db
	);

     
	
   parameter Amp = 1000;
   parameter Freq = 1000; //Hz
   parameter Delta_T = 1.0e-6; //1 us
   parameter TPi = 6.28; 
    
  
 
   real i, current, Vn, Vn1;
   real Q, Qc, Qd;

   always @(posedge clk)
   begin
       if( reset ) begin db = 0;   end
       else
       begin
           if (i < Max_Current_Points)
              begin
                 current = Total_Charge / (Max_Current_Points * Delta_T);
                 i = i + 1;
              end
              else
              begin
                 current = 0;
              end
              Qc = current * Delta_T * 1.0e-9 * 1.0e-9; //in Coulomb
              Qd = (Vn / Rf) * Delta_T * 1.0e-6 * 1.0e-9; //in Coulomb
              Q = Q + (Qc - Qd);
              Vn1 = (Q / Cf) * 1.0e+12;
              db = Vn * 1.0e6 * 4095;
              Vn = Vn1;
           
           
      end
    end
endmodule