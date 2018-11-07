// Slow ADC : AD7417
//
// Bill Burris   Jan 14, 2009

// S.L. modified address space usage. Nov., 2008

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

module Slow_ADC(
          IFCLK,
          clk,   // double SCL freq
          reset_n,
          
          FD,
          GPIFADR,
          Read_Address,
          read,
          write,

          SDA,
          SCL, 
          Temp         
                     );

   parameter USB_WORD_SIZE = 16;
   parameter ID_WORD_SIZE = 3;
   parameter USB_ADDR_SIZE = 5;

   parameter register_base_addr = 8;
   parameter pointer_addr = 14;
   parameter status_addr = 15;
   parameter data_addr = 16;
   parameter command_addr = 17;
   parameter device_addr = 18;


   input IFCLK;
   input clk;
   input reset_n;               

   inout [USB_WORD_SIZE-1:0] FD;
   input [USB_ADDR_SIZE-1 :0] GPIFADR;
   input [7:0] Read_Address;
   input read, write;

   output SCL;
   inout SDA;
   output [7:0] Temp;
   
   reg SCL, serial_data;
   reg [15:0] buffer;
   reg [15:0] data;
   reg [15:0] status;
   reg [7:0] addr;
   reg [3:0] count;
   reg oe;
   reg [1:0] bytes;
   reg [7:0] pointer;
   reg [6:0] AD7417_ADDR;
   reg ack;
   
   parameter temperature_value = 0;
   parameter config_register = 1;
   parameter thyst_register = 2;
   parameter toti_register = 3;
   parameter adc_value = 4;
   parameter config2_register = 5;
   parameter pointer_register = 6;
   
   parameter state_idle =         5'd0,
            state_read_start1 =   5'd1,
            state_read_start2 =   5'd2,
            state_read_addr =     5'd3,
            state_read_ack1 =     5'd4,
            state_read_data1 =    5'd5,
            state_read_ack2 =     5'd6,
            state_read_nak1 =     5'd7,
            state_read_data2 =    5'd8,
            state_read_nak2 =     5'd9,
            state_write_start1 =  5'd10,
            state_write_start2 =  5'd11,
            state_write_addr =    5'd12,
            state_write_ack0 =    5'd13,
            state_write_pointer = 5'd14,
            state_write_ack1 =    5'd15,
            state_write_data1 =   5'd16,
            state_write_ack2 =    5'd17,
            state_write_data2 =   5'd18,
            state_write_ack3 =    5'd19,
            state_stop1 =         5'd20,
            state_stop2 =         5'd21,
            state_stop3 =         5'd22;
            
   reg [4:0] state;
   reg [4:0] next_state;
   reg clear_next_state;
   
   assign Temp = {3'b0,state};
   
   assign SDA = oe? serial_data : 1'bz;
   
   reg Drive_Status, Drive_Data;
   assign FD = Drive_Status? status
            : Drive_Data? data
            : 16'bz
            ;

   parameter state2_idle = 2'd0,
            state2_read_data_reg = 2'd1;
   
   reg [1:0] state2;
   
   always @( posedge IFCLK or negedge reset_n )
   begin
       if( reset_n == 0 )
       begin
          AD7417_ADDR = 7'b0101000;
          Drive_Status <=0;
          Drive_Data <= 0;
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
                     if( read  && (Read_Address == status_addr))  // status reg for this FPGA module
                     begin
                        Drive_Status <= 1;
                        state2 <= state2_read_data_reg;
                     end
                     if( read  && (Read_Address == data_addr))   // data reg for this FPGA module
                     begin
                        Drive_Data <= 1;
                        state2 <= state2_read_data_reg;
                     end
                     if( write && (GPIFADR == device_addr) )
                     begin
                         AD7417_ADDR = {4'b0101,FD[2:0]};
                     end
                     if( write && (GPIFADR == command_addr) )  // trigger read from SADC
                     begin
                        pointer <= FD[7:0];
                        addr <= {AD7417_ADDR,1'b1};
                        case( FD[7:0] )
                           temperature_value:
                              bytes <= 2;
                           config_register:
                              bytes <= 1;
                           thyst_register:
                              bytes <= 2;
                           toti_register:
                              bytes <= 2;
                           adc_value:
                              bytes <= 2;
                           config2_register:
                              bytes <= 1;
                           default:
                              bytes <= 1;
                        endcase
                        next_state <= state_read_start1;
                     end
                     if( write  && (GPIFADR[4:3] == 2'b01) )   // write to SADC registers
                     begin
                        pointer <= {5'b0,GPIFADR[2:0]};
                        buffer <= FD;
                        addr <= {AD7417_ADDR,1'b0};
                        case( GPIFADR[2:0] )
                           temperature_value:
                              bytes <= 2;
                           config_register:
                              bytes <= 1;
                           thyst_register:
                              bytes <= 2;
                           toti_register:
                              bytes <= 2;
                           adc_value:
                              bytes <= 2;
                           config2_register:
                              bytes <= 1;
                           pointer_register:
                              begin
                                bytes <= 0;
                                pointer <= {5'b0,FD[2:0]};
                              end
                           default:
                              bytes <= 1;
                        endcase
                        next_state <= state_write_start1;
                     end
                  end
                  state2_read_data_reg:
                  begin
                     if( !read )
                     begin
                        Drive_Data <= 0;
                        Drive_Status <= 0;
                        state2 <= state2_idle;
                     end
                  end
                  default:
                  begin
                      state2 <= state2_idle;
                  end
            endcase
      end
   end
   
   always @( posedge clk or negedge reset_n )
   begin
       if( reset_n == 0 )
       begin
           SCL <= 1;
           serial_data <= 1;
           oe <= 0;
           data <= 0;
           status <= 0;
           clear_next_state <= 0;
           state <= state_idle;
       end
       else
          case( state )
              state_idle:
              begin
                  status <= status & 16'hFFFD;   // clear busy
                  oe <= 0;
                  if( next_state != state_idle )
                  begin
                     state <= next_state;
                     clear_next_state <= 1;
                  end
                  else
                     ;
              end
              state_read_start1:
              begin
                 oe <= 1;
                 clear_next_state <= 0;
                 status <= (status | 16'h0002) & 16'hFFFA;  // set busy, clear data valid & error
                 serial_data <= 0;
                 state <= state_read_start2;
              end
              state_read_start2:
              begin
                 SCL <= 0;
                 count <= 7;
                 serial_data <= addr[7];
                 state <= state_read_addr;
              end
              state_read_addr:
              begin
                  if( SCL )
                  begin
                     serial_data <= addr[count-1];
                     count <= count - 1;
                     SCL <= 0;
                  end
                  else
                  begin
                      SCL <= 1;
                  end
                  if( count == 0 )
                  begin
                      state <= state_read_ack1;
                  end
              end
              state_read_ack1:
              begin
                  count <= 8;
                  oe <= 0;
                  if( SCL )
                  begin
                     SCL <= 0;
                  end
                  else
                  begin
                     SCL <= 1;
                     if( SDA )  // no acknowledge
                     begin
                        status <= status | 16'h0004;  // set error flag
                        state <= state_idle;
                     end
                     else
                       state <= state_read_data1;
                  end
              end
              state_read_data1:
              begin
                  if( SCL )
                  begin
                     SCL <= 0;
                  end
                  else
                  begin
                     data[count+7] <= SDA;
                     count <= count - 1;
                     SCL <= 1;
                  end
                  if( count == 0 )
                  begin
                     if( bytes == 1 )
                     begin
                        oe <= 1;
                        serial_data <= 1;
                        data[7:0] <= data[15:8];  // for single byte reads
                        state <= state_read_nak1;
                     end
                     else
                     begin
                        oe <= 1;
                        serial_data <= 0;
                        state <= state_read_ack2;
                     end
                  end
              end
              state_read_ack2:   // ack by master
              begin
                 count <= 8;
                 //oe <= 0;
                 if( SCL )
                 begin
                    SCL <= 0;
                 end
                 else
                 begin
                    SCL <= 1;
                    state <= state_read_data2;
                 end
              end
              state_read_nak1:   // nak by master
              begin
                  if( SCL )
                  begin
                     SCL <= 0;
                  end
                  else
                  begin
                     SCL <= 1;
                     status <= status | 16'h0001;   // set data valid flag
                     state <= state_stop1;
                  end
              end
              state_read_data2:
              begin
                  oe <= 0;
                  if( SCL )
                  begin
                     //oe <= 0;
                     SCL <= 0;
                  end
                  else
                  begin
                     data[count-1] <= SDA;
                     count <= count - 1;
                     SCL <= 1;
                  end
                  if( count == 0 )
                  begin
                     oe <= 1;
                     serial_data <= 1;
                     state <= state_read_nak2;
                  end
              end
              state_read_nak2:
              begin
                  if( SCL )
                  begin
                      SCL <= 0;
                  end
                  else
                  begin
                     SCL <= 1;
                     status <= status | 16'h0001;   // set data valid flag
                     state <= state_stop1;
                  end
              end
              state_write_start1:
              begin
                 oe <= 1;
                 clear_next_state <= 0;
                 status <= (status | 16'h0002) & 16'hFFFA;  // set busy, clear data valid & error
                 serial_data <= 0;
                 state <= state_write_start2;
              end
              state_write_start2:
              begin
                 SCL <= 0;
                 count <= 7;
                 serial_data <= addr[7];
                 state <= state_write_addr;
              end
              state_write_addr:
              begin
                  if( SCL )
                  begin
                     serial_data <= addr[count-1];
                     count <= count - 1;
                     SCL <= 0;
                  end
                  else
                  begin
                      SCL <= 1;
                  end
                  if( count == 0 )
                  begin
                     state <= state_write_ack0;
                  end
              end
              state_write_ack0:
              begin
                 count <= 8;
                 oe <= 0;
                 if( SCL )
                 begin
                    SCL <= 0;
                 end
                 else
                 begin
                    SCL <= 1;
                    if( SDA )  // no acknowledge
                    begin
                       status <= status | 16'h0004;  // set error flag
                       state <= state_idle;
                    end
                    else
                       state <= state_write_pointer;
                 end
              end
              state_write_pointer:
              begin
                  oe <= 1;
                  if( SCL )
                  begin
                     serial_data <= pointer[count-1];
                     count <= count - 1;
                     SCL <= 0;
                  end
                  else
                  begin
                      SCL <= 1;
                  end
                  if( count == 0 )
                  begin
                     if( bytes == 0 )
                     begin
                        state <= state_write_ack3;
                     end
                     else
                     begin
                        state <= state_write_ack1;
                     end
                  end
              end
              state_write_ack1:
              begin
                  count <= 8;
                  oe <= 0;
                  if( SCL )
                  begin
                      SCL <= 0;
                  end
                  else
                  begin
                      SCL <= 1;
                      if( SDA )  // no acknowledge
                      begin
                          status <= status | 16'h0004;  // set error flag
                          state <= state_idle;
                      end
                      else
                         state <= state_write_data1;
                  end
              end
              state_write_data1:
              begin
                  oe <= 1;
                  if( SCL )
                  begin
                     serial_data <= buffer[count-1];
                     count <= count - 1;
                     SCL <= 0;
                  end
                  else
                  begin
                      SCL <= 1;
                  end
                  if( count == 0 )
                  begin
                     if( bytes == 1 )
                     begin
                        state <= state_write_ack3;
                     end
                     else
                     begin
                        state <= state_write_ack2;
                     end
                  end
              end
              state_write_ack2:
              begin
                  count <= 8;
                  oe <= 0;
                  if( SCL )
                  begin
                      SCL <= 0;
                  end
                  else
                  begin
                      SCL <= 1;
                      if( SDA )  // no acknowledge
                      begin
                          status <= status | 16'h0004;  // set error flag
                          state <= state_idle;
                      end
                      else
                         state <= state_write_data2;
                  end
              end
              state_write_data2:
              begin
                  oe <= 1;
                  if( SCL )
                  begin
                     serial_data <= buffer[count-1];
                     count <= count - 1;
                     SCL <= 0;
                  end
                  else
                  begin
                      SCL <= 1;
                  end
                  if( count == 0 )
                  begin
                     state <= state_write_ack3;
                  end
              end
              state_write_ack3:
              begin
                  oe <= 0;
                  if( SCL )
                  begin
                      SCL <= 0;
                  end
                  else
                  begin
                      SCL <= 1;
                      if( SDA )  // no acknowledge
                      begin
                          status <= status | 16'h0004;  // set error flag
                          state <= state_idle;
                      end
                      else
                         state <= state_stop1;
                  end
              end
              state_stop1:
              begin
                 oe <= 1;
                 SCL <= 0;
                 serial_data <= 0;
                 state <= state_stop2;
              end
              state_stop2:
              begin
                  SCL <= 1;
                  state <= state_stop3;
              end
              state_stop3:
              begin
                 serial_data <= 1;
                 state <= state_idle;
              end
              default:
              begin
                  state <= state_idle;
              end
          endcase
   end
 

endmodule