`timescale 1ns/1ps
module DDIN
#(parameter INIT_VAL  = 32'b0,
  parameter LEN_DATA  = 32'b1,
  parameter CNT_TIME  = 32'd2
)
(   input               	 clk,
	input               	 rst_n, 
	input  [LEN_DATA - 1:0]  in, 
	output [LEN_DATA - 1:0]	 out
);

reg [LEN_DATA - 1:0] d_trigger [CNT_TIME - 1: 0];
integer i;
always @(posedge clk or negedge rst_n)
 begin
 if(~rst_n)   
   begin
 	for (i = 0; i < CNT_TIME; i = i + 1) begin
						d_trigger[i] <=  INIT_VAL;
    end 
   end
 else  
   begin
 	for (i = 0; i < CNT_TIME; i = i + 1) begin
          	if(i == 0)  d_trigger[i] <= {d_trigger[i][CNT_TIME - 2:0],in};
			else 		d_trigger[i] <= d_trigger[i-1];
    end 
   end	   
end

assign out = d_trigger[CNT_TIME - 1];

endmodule
