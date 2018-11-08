// Interface to i2C EEPROM : 24AA025E48T
// Modified from AD7417.v of Radon_DAQ project, S.L. January 22, 2009
// usage:
// write : write entire 128 bytes to eeprom from configuration buffer;
// read:  read entire 128 bytes from eeprom to configuration buffer;
// busy:  check status of EEPROM, busy = 1

//total 10 addresses used in this module:
//          8 to 13 W - write to AD7417 register, 
//          14 W - write to AD7417 pointer register
//          15 R - 16 bit status reg for Slow_ADC module
//               - 16'h0001 data reg valid,
//                 indicates that the previous read command is finished
//               - 16'h0002 busy
//               - 16'h0004 error
//          16 R = 16 bit data reg for Slow_ADC module
//          17 W - read command for AD7417, FD contains AD7417 pointer address
//          18 W - AD7417 address

//To read a register in the AD7417, take the register address from the data 
//sheet and write it to addr 14, then write it to register 17 in the FPGA.  Monitor 
//the status register at address 15 until the least significant bit goes high to 
//indicate that the FPGA has finished reading the AD7417 register.  
//Then read the value from the data register at address 16.

//To write to a register in the AD7417, write to addresses 8 to 13.  
//These address are the register address from the data sheet + 8.  To 
//write to the pointer register in the AD7417, write to address 14.

`timescale 1 ns / 1 ps

module I2C_eeprom(
          clk,   
          reset_n,
          data,
          read,
          write,
			 busy,

          SDA,
          SCL 
                   
                     );

	parameter CONF_BUF_SIZE = 128; //max for 24AA025E48T 128 bytes
	parameter PAGE_SIZE = 16; // page size of above EEPROM
	parameter CHIP_ADDR = 7'b1010000; //I2C chip select Bits, Defined on PCB
	
   parameter USB_WORD_SIZE = 16;
   parameter ID_WORD_SIZE = 3;
   parameter USB_ADDR_SIZE = 5;

   parameter register_base_addr = 8;
   parameter pointer_addr = 14;
   parameter status_addr = 15;
   parameter data_addr = 16;
   parameter command_addr = 17;
   parameter device_addr = 18;


   input clk;
   input reset_n;               

   input [CONF_BUF_SIZE-1 :0] data[7:0];
	input read, write;
	output reg busy;

   output SCL;
   inout SDA;
   
   reg  [2:0] i2c_addr;
	reg  [7:0] device_byte;
   reg  [7:0] in_data;
   wire [7:0] out_data;  
   reg        i2c_cs;
   reg        i2c_rd;
   reg        i2c_wr;

   reg [CONF_BUF_SIZE-1:0] buffer[7:0];
	reg [7:0] buf_cnt;
	
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

      
/*
   reg [15:0] data;
   reg [15:0] status;
   reg [7:0] addr;

   reg [1:0] bytes;
   reg [7:0] pointer;
   reg [6:0] AD7417_ADDR;
   reg [15:0] buffer;
   
   parameter temperature_value = 0;
   parameter config_register = 1;
   parameter thyst_register = 2;
   parameter toti_register = 3;
   parameter adc_value = 4;
   parameter config2_register = 5;
   parameter pointer_register = 6;
 */
 
   parameter state_idle =        0,
            state_read_start1 =  2,
            state_read_start2 =  3,
            state_read_query0 =  4,
             state_read_addr1 =  5,
            state_read_addr2 =   6,
            state_read_query1 =  7,

            state_read_data1 =   8,
            state_read_data2 =   9,
            state_read_query2 =  10,
            
            state_read_buffer1 = 11,
            state_read_buffer2 = 12,
            
            state_read_data3 =   13,
            state_read_data4 =   14,
             
            state_read_query3 =  15,
            
            state_read_buffer3 = 16,
            state_read_buffer4 = 17,
                        
            state_write_start1 = 18,
            state_write_start2 = 19,
            state_write_query0 = 20,
            
            state_write_addr1 =  21,
            state_write_addr2 =  22,
            state_write_query1 = 23,

            state_write_pointer1 = 24,
            state_write_pointer2 = 25,
            state_write_query2 =   26,
            
            state_write_data1 =   27,
            state_write_data2 =   28,
            state_write_query3 =  29,
                      
            state_stop1 =         30,
            state_stop2 =         31,
            state_stop_query =    32;   
            
   reg [5:0] state;
   reg [5:0] next_state;
   reg clear_next_state;
   
    
   parameter state2_idle = 2'd0,
            state2_read_data_reg = 2'd1;
   
   reg [1:0] state2;
   
   always @( posedge clk or negedge reset_n )
   begin
       if( reset_n == 0 )
       begin
          next_state <= state_idle;
          state2 <= state2_idle;
       end
       else
       begin
           case( state2 )
               state2_idle:
                  begin
                     if( clear_next_state )
                     begin
                         next_state <= state_idle;
                     end
                     else if( read )  
									begin
										device_byte <= ;
										next_state <= state_read_start1;
									end
                     else if( write  )   
									begin
										device_byte <= {CHIP_ADDR,1'b0};
										next_state <= state_write_start1;
									end
                  end
                  
						default:
                  begin
                      state2 <= state2_idle;
                  end
            endcase
      end
   end
   
	
	
   ////////////////////////////////////////////////////////////////////////
       
   always @( posedge clk or negedge reset_n )
   begin
       if( reset_n == 0 )
       begin
           i2c_addr <= 0;
           in_data <= 0;
           i2c_cs <= 0;
           i2c_rd <= 0;
           i2c_wr <= 0;
           
           clear_next_state <= 0;
           state <= state_idle;
       end
       else
          case( state )
              state_idle:
              begin
                  i2c_addr <= 0; in_data <= 0; i2c_cs <= 0; i2c_wr <= 0; i2c_rd <= 0;
                  status <= status & 16'hFFFD;   // clear busy
                  if( next_state != state_idle )
                    begin
                      state <= next_state;
                      clear_next_state <= 1;
                    end
              end
              
              state_0:
                begin
                 status <= (status | 16'h0002) & 16'hFFFA;  // set busy, clear data valid & error
                 i2c_addr <= 0; i2c_cs <= 1; i2c_wr <= 1;   // START on I2C
                 state <= state_1;
                end
              
              state_1:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_2;
                end
              
              state_2:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_3;
                     end
                end
                          
              state_3: //write device control byte: {1010,000,W}
                begin
                  i2c_addr <= 3; in_data <= {CHIP_ADDR,1'b0}; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_4;
                end
                
              state_4:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_5;
                end    
                          
              state_5:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_6;
                     end
                end
             
				 state_6: //write starting address (starting from addr = 0)
                begin
                  i2c_addr <= 3; in_data <= 0; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_7;
                end
              
              state_7:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_8;
                end  
              
              state_8:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_9;
                     end
                end   
				 
				 state_9: //start again on I2C
                begin
                 i2c_addr <= 0; i2c_cs <= 1; i2c_wr <= 1;   
                 state <= state_10;
                end
              
              state_10:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_11;
                end
              
              state_11:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_12;
                     end
                end		 
				 
				 state_12: //write device control byte: {1010,000,R}
                begin
                  i2c_addr <= 3; in_data <= {CHIP_ADDR,1'b1}; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_13;
                end
                
              state_13:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_14;
                end    
                          
              state_14:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0; buf_cnt <= 0;
                       state <= state_15;
                     end
                end
				 
              state_15: //read one byte from I2C
                begin
                  i2c_addr <= 2; in_data <= 1; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_16;
                end
              
              state_16:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_17;
                end  
              
              state_17:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_18;
                     end
                end   
                
               state_18:
                 begin
                  i2c_addr <= 3; i2c_cs <= 1; i2c_rd <= 1; 
                  state <= state_19;
                 end    
             
              state_19:
                 begin
                  buffer[buf_cnt] <= out_data; 
                  i2c_cs <= 0; i2c_rd <= 0;
						if (buf_cnt < CONF_BUF_SIZE - 1) 
							begin 
								buf_cnt <= buf_cnt + 1;
								state <= state_15;
							end	
                  else state <= state_20;
                 end  
              
			     state_20:  //STOP on I2C bus
                begin
                 i2c_addr <= 1; i2c_cs <= 1; i2c_wr <= 1;
                 state <=  state_21;
                 clear_next_state <= 0;
                end
                
              state_21:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_22;
                end
                
              state_22: //Set data Valid flag
                begin
                 i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
							  status <= status | 16'h0001;   // set data valid flag
                       state <= state_idle;
                     end
                end
					 
              
                 
              /////////////////////////////////////////////////////////////////
                     
              
              state_40: //set Status bit and START on I2C bus
                begin
                  
                  status <= (status | 16'h0002) & 16'hFFFA;  // set busy, clear data valid & error
                 
                  i2c_addr <= 0; i2c_cs <= 1; i2c_wr <= 1;
                 
                  state <= state_41;
                end
                
              state_41:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_42;
                end
                
              state_42:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_43;
                     end
                end
                
              state_43: //write device control byte: {1010,000,W}
                begin
                  i2c_addr <= 3; in_data <= {CHIP_ADDR,1'b0}; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_44;
                end
                
              state_44:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_45;
                end    
                          
              state_45:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_46;
                     end
                end
                
              state_46: //write starting address = 0
                begin
                  i2c_addr <= 3; in_data <= 0; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_47;
                end
                
              state_47:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_48;
                end   
                
              state_48:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0; page_cnt <= 0; buf_cnt <= 0;
                       state <= state_49;
                     end
                end   
             
              state_49: //Write 1 byte to I2C
                begin
                  i2c_addr <= 3; in_data <= buffer[page_cnt << 4 + buf_cnt]; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_50;
                end
              
              state_50:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_51;
                end  
              
              state_51:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
							  if (buf_cnt < PAGE_SIZE) 
									begin
								     	buf_cnt <= buf_cnt + 1;
										state <= state_49;
									end	
                       else state <= state_stop1;
                     end
                end   
                
              state_stop1:
                begin
                 i2c_addr <= 1; i2c_cs <= 1; i2c_wr <= 1;
                 state <=  state_stop2;
                 clear_next_state <= 0;
                end
                
              state_stop2:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_stop_query;
                end
                
              state_stop_query:
                begin
                 i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_idle;
                     end
                end
                
              default:
                begin
                  state <= state_idle;
                end
                
          endcase
   end
 

endmodule