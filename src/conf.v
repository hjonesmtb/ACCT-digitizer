// Conf.v: functional simulating I2C interface and 2-D configuration array access method
// to be simulate by Modelsim-Altera 10.1d outside of Quartus Prim 18.0
// SL, Nov.9,2018
`timescale 1 ns / 1 ps

module conf(
          SYS_CLK,   
          SYS_RST,
          
          wr_conf,
          rd_eeprom,
          wr_eeprom,
          
	        pca_gain_reg,		 
			
          sda,
          scl 
                   
                     );
input rd_eeprom,wr_eeprom,wr_conf/*synthesis keep*/; 
input SYS_CLK, SYS_RST;
input [15:0] pca_gain_reg;
inout sda;
output scl;
               
parameter CONF_BUF_SIZE = 16; //max = 128 bytes for 24AA025E48T
reg  [7:0] configuration [CONF_BUF_SIZE-1:0]/*synthesis keep*/; //configuration buffer 
wire [7:0] eeprom_buffer [CONF_BUF_SIZE-1:0];
wire eeprom_busy, eeprom_data_valid;

reg [2:0] state/*synthesis keep*/;

always@(posedge SYS_CLK)
   if (SYS_RST) state <= 0;
	else 
                case (state)
				0: if(rd_eeprom) state <= 1;
				   else if (wr_conf) state <= 2;
				1: if (~eeprom_busy && eeprom_data_valid) 
						begin configuration <= eeprom_buffer; state <= 0; end 
				2: begin
						configuration[0] <= pca_gain_reg[7:0];
						configuration[1] <= pca_gain_reg[15:8];
											
						configuration[14] <= 8'b11111010;
						configuration[15] <= 8'b11111010;
						state <= 0;
						
				   end
				default:
				  state <= 0;
                endcase
		
		
I2C_eeprom eeprom_inst(
          .clk(SYS_CLK),   
          .rst(SYS_RST),
          .conf_data(configuration),
          .read(rd_eeprom),
          .write(wr_eeprom),
		 
	 .buffer(eeprom_buffer),
	 .busy(eeprom_busy),
	 .valid(eeprom_data_valid),

          .SDA(sda),
          .SCL(scl)               
                     );
							
endmodule
