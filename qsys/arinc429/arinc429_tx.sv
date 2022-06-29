module  arinc429_tx
#(parameter DEVICE_FAMILY       = "Cyclone V",
			IN_AVS_CLK       	= 32'd50000000,
			FIFO_SIZE           = 16'd64			
)
(    input   wire            i_avs_clk
	,input   wire            i_avs_rst_n 
//Avalon_ST	SINK
    ,input   wire            i_sink_tx_valid
    ,input   wire  [31:0] 	 i_sink_tx_data 
    ,output  wire            o_sink_tx_ready
	
// Configuration
	,input   wire [1:0]	 	 i_arinc429_speed
// ARINC429	
	,output  reg 			 o_arinc429_tx_A
	,output  reg 			 o_arinc429_tx_B
	,output  wire 			 o_arinc429_tx_SLP
);

localparam DEVIDER_CLK_12_5_KHZ = IN_AVS_CLK/12500/4,
		   DEVIDER_CLK_50_KHZ   = IN_AVS_CLK/50000/4,
		   DEVIDER_CLK_100_KHZ  = IN_AVS_CLK/100000/4;

localparam REG_SIZE_CLK = 16;		  

//////////////////              MODELSIM                 /////////////////////
reg [1:0] StateAvlTx;
localparam	STATE_TX_IDLE 	= 2'd0,
			STATE_TX_SEND	= 2'd1,
			STATE_TX_DONE	= 2'd2;
wire start_send_pe;

reg [REG_SIZE_CLK:0] clk_devider;
wire tx_on = !(clk_devider == 0);
wire rst_n = i_avs_rst_n & tx_on;

reg sig_busy;
wire sig_busy_d3;

reg [31:0] sig_data; 
reg sig_par;
//////////////////              GENERATE CLOCK            /////////////////////
assign o_arinc429_tx_SLP = !(clk_devider == DEVIDER_CLK_12_5_KHZ); 
assign o_sink_tx_ready = (StateAvlTx == STATE_TX_IDLE)&&(|clk_devider);

//reg [REG_SIZE_CLK:0] clk_devider;
always @(posedge i_avs_clk or negedge i_avs_rst_n)
 begin 
   if(~i_avs_rst_n) 				clk_devider <= {REG_SIZE_CLK{1'b0}};
   else if(StateAvlTx != STATE_TX_SEND)
		case(i_arinc429_speed)   
			2'b01: 					clk_devider <= DEVIDER_CLK_12_5_KHZ;
			2'b10: 					clk_devider <= DEVIDER_CLK_50_KHZ;
			2'b11: 	 				clk_devider <= DEVIDER_CLK_100_KHZ;
			default: 				clk_devider <= {REG_SIZE_CLK{1'b0}};  
		endcase	
 end 
 
reg [REG_SIZE_CLK - 1:0] cnt_clk;
always @(posedge i_avs_clk or negedge rst_n)
 begin 
   if(~rst_n) 							cnt_clk <= {(REG_SIZE_CLK - 1){1'b0}};
   else if(cnt_clk < (clk_devider - 1))	cnt_clk <= cnt_clk + 1'b1;
   else									cnt_clk <= {(REG_SIZE_CLK - 1){1'b0}};
 end 
 
reg clk_2x;
always @(posedge i_avs_clk or negedge rst_n)
 begin 
   if(~rst_n) 								clk_2x <= 1'b0;
   else if(cnt_clk >= (clk_devider - 1))	clk_2x <= !clk_2x; 	
 end 
//////////////////              ARINC429 TX             ///////////////////// 
reg sig_clk;
always @(posedge clk_2x or negedge rst_n)
 begin 
   if(~rst_n) 						sig_clk <= 1'b0;
   else 							sig_clk <= ~sig_clk; 	
 end

reg [5:0] cnt_bit;
always @(posedge sig_clk or negedge rst_n)
 begin 
   if(~rst_n) 												cnt_bit <= 6'd0;
   else if(start_send_pe)									cnt_bit <= 6'd31; 
   else if(cnt_bit > 0)										cnt_bit <= cnt_bit - 1'b1;
 end  
 
//reg sig_busy;
always @(posedge sig_clk or negedge rst_n)
 begin 
   if(~rst_n) 												sig_busy <= 1'b0;
   else if(start_send_pe)									sig_busy <= 1'b1; 
   else if(cnt_bit > 0)										sig_busy <= 1'b1;
   else 													sig_busy <= 1'b0;   
 end

reg sig_busy_d1;
always @(posedge sig_clk or negedge rst_n)
 begin
 if(~rst_n)        				 		     sig_busy_d1 <= 1'b0;
 else                                        sig_busy_d1 <= sig_busy;		   
end
 
reg [31:0] sig_data_shift;
always @(posedge sig_clk or negedge rst_n)
 begin 
   if(~rst_n) 												sig_data_shift <= 32'hface_dead;
   else if(cnt_bit > 0)										sig_data_shift <= {1'b0,sig_data_shift[31:1]};    
   else 													sig_data_shift <= sig_data;
 end

reg sig_bit;
always @(posedge sig_clk or negedge rst_n)
 begin 
   if(~rst_n) 						 		sig_bit <= 1'b0;
   else if(cnt_bit > 0)						sig_bit <= sig_data_shift[0];
   else 									sig_bit <= !sig_par; 	
 end
 
//reg sig_par;
always @(posedge sig_clk or negedge rst_n)
 begin 
   if(~rst_n) 								sig_par <= 1'b0;
   else if(cnt_bit > 0)						sig_par <= sig_data_shift[0] ^ sig_par; 
   else 									sig_par <= 1'b0;   
 end

always @(posedge clk_2x or negedge rst_n)
 begin 
   if(~rst_n) 										o_arinc429_tx_A <= 1'b0;
   else if(sig_busy_d1)								o_arinc429_tx_A <= sig_bit & sig_clk; 
   else 											o_arinc429_tx_A <= 1'b0;   
 end

always @(posedge clk_2x or negedge rst_n)
 begin 
   if(~rst_n) 										o_arinc429_tx_B <= 1'b0;
   else if(sig_busy_d1)								o_arinc429_tx_B <= !sig_bit & sig_clk; 
   else 											o_arinc429_tx_B <= 1'b0;   
 end
 
wire send_compl_pe;
SYNC_PE SYNC_PE_sig_avs
( 
/*  input   */  .i_reset_n(rst_n),
/*  input   */  .i_async_clk(sig_clk),
/*  input   */  .i_async_in(!sig_busy_d1),
/*  input   */  .i_clk(i_avs_clk),
/*  output  */  .o_sync_out(send_compl_pe)
); 

//////////////////              AVALON ST            /////////////////////
// STATE AVS TX
//reg [1:0] StateAvlTx;
//localparam	STATE_TX_IDLE 	= 2'd0,
//				STATE_TX_SEND	= 2'd1,
//				STATE_TX_DONE	= 2'd2;

always @(posedge i_avs_clk or negedge rst_n)
 begin
 if(~rst_n)        							   				StateAvlTx <=  STATE_TX_IDLE;
 else case(StateAvlTx)                                                               
       STATE_TX_IDLE: 	if(i_sink_tx_valid)					StateAvlTx <=  STATE_TX_SEND;
	   STATE_TX_SEND: 	if(send_compl_pe)					StateAvlTx <=  STATE_TX_DONE;
	   STATE_TX_DONE: 	 									StateAvlTx <=  STATE_TX_IDLE;
	  default: 										   		StateAvlTx <=  STATE_TX_IDLE;  
      endcase			   
end

//wire start_send_pe;
SYNC_PE SYNC_PE_avs_sig
( 
/*  input   */  .i_reset_n(rst_n),
/*  input   */  .i_async_clk(i_avs_clk),
/*  input   */  .i_async_in(StateAvlTx == STATE_TX_SEND),
/*  input   */  .i_clk(sig_clk),
/*  output  */  .o_sync_out(start_send_pe)
); 

//reg [31:0] sig_data; 
always @(posedge i_avs_clk or negedge rst_n)
 begin 
   if(~rst_n) 												sig_data <= 32'hface_dead;
   else if(StateAvlTx == STATE_TX_IDLE)					    sig_data <= i_sink_tx_data;	
 end

endmodule

