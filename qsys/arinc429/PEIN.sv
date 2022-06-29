`timescale 1ns/1ps
module PEIN
#(parameter INIT_VAL  = 32'b0,
  parameter LEN_DATA  = 32'b1
)
(   input               	 clk,
	input               	 rst_n, 
	input  [LEN_DATA - 1:0]  in, 
	output [LEN_DATA - 1:0]	 out
);

//первый D триггер
reg [LEN_DATA - 1:0] d1_trigger;
always @(posedge clk or negedge rst_n)
 begin
 if(~rst_n)        				 		     d1_trigger <=  {LEN_DATA{INIT_VAL}};
 else                                        d1_trigger <=  in;		   
end

assign out = in & ~d1_trigger;

endmodule
