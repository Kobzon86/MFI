`timescale 1ns/1ps
module filter_input
#(parameter INIT_VAL    = 32'b0,
  parameter LEN_DATA    = 32'b1
)
(   input               	 	 clk,
	input               	 	 rst_n, 
	input  	   [LEN_DATA - 1:0]  in,
	input	   [15:0]			 cnt_const_T, 	
	output reg [LEN_DATA - 1:0]	 out
);

reg [LEN_DATA - 1:0] delay_in;   
always @(posedge clk or negedge rst_n)
   begin 
	if(~rst_n) 							delay_in <= {LEN_DATA{1'b0}};
	else 								delay_in <= in;
   end

reg [15:0] cnt_time;
always @(posedge clk or negedge rst_n)
   begin 
	if(~rst_n) 							cnt_time <= 16'b0;
	else if(delay_in != in)				cnt_time <= 16'b0;
	else if(cnt_time < cnt_const_T)  	cnt_time <= cnt_time + 1'b1;
   end

always @(posedge clk or negedge rst_n)
   begin 
	if(~rst_n) 								out <= {LEN_DATA{1'b0}};
	else if(cnt_time == (cnt_const_T - 1))  out <= delay_in;
   end

endmodule
