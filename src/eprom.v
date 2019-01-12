// Interface to i2C EEPROM : 24AA025E48T
// Modified from AD7417.v of Radon_DAQ project, S.L. January 22, 2009
// usage:
// write : write entire 128 bytes to eeprom from configuration buffer;
// read:  read entire 128 bytes from eeprom to configuration buffer;
// busy:  check status of EEPROM;


`timescale 1 ns / 1 ps

module I2C_eeprom(
          clk,   
          rst,
          conf_data,
          read,
          write,
			 
			 buffer,
			 busy,
			 valid,

          SDA,
          SCL 
                   
                     );

	parameter CONF_BUF_SIZE = 128; //max 128 bytes for 24AA025E48T 
	parameter PAGE_SIZE = 16; // page size in bytes of above EEPROM
	parameter PAGE_NUM = CONF_BUF_SIZE/PAGE_SIZE; //max 8
	
	parameter CHIP_ADDR = 7'b1010000; //I2C chip select Bits, Defined on PCB
	
  
   input clk;
   input rst;               

   input [7:0] conf_data [CONF_BUF_SIZE-1:0];
	input read, write;
	
	output reg [7:0] buffer [CONF_BUF_SIZE-1:0];
	output reg busy,valid;

   output SCL;
   inout SDA;
   
   reg  [2:0] i2c_addr;
	reg  [7:0] device_byte;
   reg  [7:0] in_data;
   wire [7:0] out_data;  
   reg        i2c_cs;
   reg        i2c_rd;
   reg        i2c_wr;

   
	reg [7:0] buf_cnt;
	reg [4:0] page_cnt,byte_cnt;
	
	
i2c_master i2c_master_inst(
   .addr(i2c_addr), 
   .in_data(in_data), 
   .out_data(out_data), 
   .sda(SDA), 
   .scl(SCL), 
   .cs(i2c_cs), 
   .rd(i2c_rd), 
   .wr(i2c_wr), 
   .clk(clk));

     
 
   parameter state_idle = 0;
   
            
   reg [7:0] state/*synthesis keep*/;
      
   
   ////////////////////////////////////////////////////////////////////////
       
   always @( posedge clk  )
   begin
       if( rst )
       begin
           i2c_addr <= 0;
           in_data <= 0;
           i2c_cs <= 0;
           i2c_rd <= 0;
           i2c_wr <= 0;
			  busy <= 0;
			  valid <= 0;
           
           state <= state_idle;
       end
       else
          case( state )
              state_idle:
              begin
                  i2c_addr <= 0; in_data <= 0; i2c_cs <= 0; i2c_wr <= 0; i2c_rd <= 0;
                  busy <= 0; valid <= 0; // clear busy, valid
						  
                  if( read ) state <= 1;
						else if( write ) state <= 39;
              end
              
              1:
                begin
                 busy <= 1;  // set busy
                 i2c_addr <= 0; i2c_cs <= 1; i2c_wr <= 1;   // START on I2C
                 state <= 2;
                end
              
              2:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 3;
                end
              
              3:
                begin
                  
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= 4;
                     end
                end
                          
              4: //write device control byte: {1010,000,W}
                begin
                  i2c_addr <= 3; in_data <= {CHIP_ADDR,1'b0}; i2c_cs <= 1; i2c_wr <= 1;
                  state <= 5;
                end
                
              5:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 6;
                end    
                          
              6:
                begin
                  
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= 7;
                     end
                end
             
				 7: //write starting address (starting from addr = 0)
                begin
                  i2c_addr <= 3; in_data <= 0; i2c_cs <= 1; i2c_wr <= 1;
                  state <= 8;
                end
              
              8:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 9;
                end  
              
              9:
                begin
                  
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= 10;
                     end
                end   
				 
				 10: //start again on I2C
                begin
                 i2c_addr <= 0; i2c_cs <= 1; i2c_wr <= 1;   
                 state <= 11;
                end
              
              11:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 12;
                end
              
              12:
                begin
                  
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= 13;
                     end
                end		 
				 
				 13: //write device control byte: {1010,000,R}
                begin
                  i2c_addr <= 3; in_data <= {CHIP_ADDR,1'b1}; i2c_cs <= 1; i2c_wr <= 1;
                  state <= 14;
                end
                
              14:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 15;
                end    
                          
              15:
                begin
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0; buf_cnt <= 0;
                       state <= 16;
                     end
                end
				 
              16: //read one byte from I2C
                begin
                  i2c_addr <= 2; in_data <= 1; i2c_cs <= 1; i2c_wr <= 1;
                  state <= 17;
                end
              
              17:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 18;
                end  
              
              18:
                begin
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= 19;
                     end
                end   
                
               19:
                 begin
                  i2c_addr <= 3; i2c_cs <= 1; i2c_rd <= 1; 
                  state <= 20;
                 end    
             
              20:
                 begin
                  buffer[buf_cnt] <= out_data; 
                  i2c_cs <= 0; i2c_rd <= 0;
						if (buf_cnt < CONF_BUF_SIZE - 1) 
							begin 
								buf_cnt <= buf_cnt + 1;
								state <= 16;
							end	
                  else state <= 21;
                 end  
              
			     21:  //STOP on I2C bus
                begin
                 i2c_addr <= 1; i2c_cs <= 1; i2c_wr <= 1;
                 state <=  22;
                 
                end
                
              22:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 23;
                end
                
              23: //Set data Valid flag
                begin
                 if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
							  busy <= 0;  valid <= 1; // clear busy, set data_valid
                       state <= state_idle;
                     end
                end
					 
              
                 
              /////////////////////////////////////////////////////////////////
                     
              39: //pregare to write 
				    begin
					   busy <= 1;  // set busy
						page_cnt <= 0; buf_cnt <= 0; byte_cnt <= 0;
						state <= 40;
					 end
				  
              40: //set busy bit and START on I2C bus
                begin
                  i2c_addr <= 0; i2c_cs <= 1; i2c_wr <= 1;
                  state <= 41;
                end
                
              41:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 42;
                end
                
              42:
                begin
                  
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= 43;
                     end
                end
                
              43: //write device control byte: {1010,000,W}
                begin
                  i2c_addr <= 3; in_data <= {CHIP_ADDR,1'b0}; i2c_cs <= 1; i2c_wr <= 1;
                  state <= 44;
                end
                
              44:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 45;
                end    
                          
              45:
                begin
                  
                  if ((out_data[0] == 0) && (out_data[2] == 0))
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= 46;
                     end
						else if ((out_data[0] == 0) && (out_data[2] == 1))
									state <= 40;
                end
                
              46: //write starting address = 0
                begin
                  i2c_addr <= 3; in_data <= buf_cnt; i2c_cs <= 1; i2c_wr <= 1;
                  state <= 47;
                end
                
              47:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 48;
                end   
                
              48:
                begin
                  
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0; 
                       state <= 49;
                     end
                end   
             
              49: //Write 1 byte to I2C
                begin
                  i2c_addr <= 3; in_data <= conf_data[buf_cnt+byte_cnt]; i2c_cs <= 1; i2c_wr <= 1;
                  state <= 50;
                end
              
              50:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 51;
                end  
              
              51:
                begin
                  
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
							  if (byte_cnt < PAGE_SIZE-1) 
									begin
								     	byte_cnt <= byte_cnt + 1;
										state <= 49;
									end	
                       else state <= 52;
									 
                     end
                end   
              				  		
              52:  //STOP on I2C bus
                begin
                 i2c_addr <= 1; i2c_cs <= 1; i2c_wr <= 1;
                 state <=  53;
                 
                end
                
              53:
                begin
                  i2c_wr <= 0; i2c_rd <= 1; i2c_addr <= 4;
                  state <= 54;
                end
                
              54: //query I2C busy, wait for complete of eeprom programming
                begin
                 
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= 55;
                     end
                end
               
				  55: 
				    begin
                  if (page_cnt < PAGE_NUM-1 ) 
									begin
									  byte_cnt <= 0;
									  page_cnt <= page_cnt + 1; 
									  buf_cnt <= buf_cnt + 16;
								     state <= 40;
									end	
                  else state <= state_idle;
					 end
					 
              default:
                begin
                  state <= state_idle;
                end
                
          endcase
   end
 

endmodule