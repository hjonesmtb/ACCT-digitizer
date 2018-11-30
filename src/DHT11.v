//==========================================================================
//company   :NanJingUniversity JiLing College
//Filename  :dht11.v
//modulename:dht11
//Author    :moyunjie
//Date	    :2016-1-13
//Function  : Read tempearature and humidity from DHT11 sensor
//Modified: Shengli Liu, TRIUMF, Nov.29,2018
//==========================================================================
module dht11(
						i_clk,
						i_rst_n,
						io_data,
					   o_temp,
						o_humi
							);

input i_clk;// 50 MHz
input i_rst_n;//
inout io_data;//
output reg [15:0]o_temp;//
output reg [15:0]o_humi;//
reg o_data;//



reg [39:0]get_data;//dht11 40 bit data
reg [5:0]data_num;//
reg[3:0]crt_state;//

parameter idle		= 4'b0001;//
parameter init		= 4'b0010;//
parameter ans 		= 4'b0100;//
parameter rd_data	= 4'b1000;//
////////



reg data_sam1;//
reg data_sam2;//

reg data_pluse;//
always@(posedge i_clk )
begin
	data_sam1<=io_data;
	data_sam2<=data_sam1;
	data_pluse<=(~data_sam2)&data_sam1;
end


reg[24:0] cnt_1s;// Counter period = 0.67 s, clk = 50 MHz

reg [12:0]cnt_40us;//40us
reg send_indi;
reg r_hold;

always@(posedge i_clk)
	if(!i_rst_n) 
		begin 
			crt_state <= idle; 
			cnt_1s<=25'd0;	
			send_indi<= 0;
			r_hold <= 0;
			o_humi<=16'b0;
			o_temp<=16'b0;
		end	
	else 
	   begin  
		   cnt_1s <= cnt_1s+1'b1;
			case(crt_state)
				idle:if(&cnt_1s )// triggered every 0.67 s @ 50MHz
								crt_state <= init;
					  else begin
								send_indi<=1'b0; r_hold <= 0;
						    end
				
				init:begin
						if ((cnt_1s > 25'd0) && (cnt_1s <= 25'd1000000)) // 20 ms
							begin o_data<=1'b0; send_indi<=1'b1; end
						if ((cnt_1s > 25'd1000000) && (cnt_1s <= 25'd1002000))	//40 us
						   begin o_data<=1'b1; send_indi<=1'b0; end		
						if ((cnt_1s > 25'd1002000 ) && (io_data == 0)) //  20ms+40us and DHT response
								crt_state <= ans;					
				     end
				ans: if(data_pluse)  //io_data rising edge
				     begin  data_num<=6'd0; cnt_40us<=12'd0; crt_state <= rd_data; end

				rd_data: 
					  if(data_pluse | r_hold) //
							begin
								if(cnt_40us >= 12'd2000) // 40 us point from io_data rising edge
									begin
										r_hold<=1'b0;
										if(io_data)
											get_data<={get_data[38:0],1'b1};
										else
											get_data<={get_data[38:0],1'b0}; 
										cnt_40us<=12'd0;
										if(data_num >= 6'd40)  
											begin								
												o_humi<=get_data[39:24];
												o_temp<=get_data[23:8];
												crt_state <= idle;
											end
										else data_num<=data_num+1'b1;	
									end
								else begin r_hold<=1'b1; cnt_40us<=cnt_40us+1'b1;	end
							end
				     	
				
				default:crt_state <= idle;
			endcase
			
		end	
		

assign io_data =send_indi ? o_data : 1'bz;//

endmodule