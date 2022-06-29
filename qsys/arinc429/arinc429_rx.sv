module  arinc429_rx
#(parameter DEVICE_FAMILY       = "Cyclone V",
			IN_AVS_CLK       	= 32'd50000000,
			FIFO_SIZE     		= 16'd4096
)
(    input   wire            i_avs_clk
	,input   wire            i_avs_rst_n 
//Avalon_ST	SRC
    ,output  reg             o_src_rx_valid
    ,output  reg  [31:0] 	 o_src_rx_data 
    ,input   wire            i_src_rx_ready
	
// Configuration
	,input   wire [1:0]	 	 i_arinc429_speed
	,output  reg  			 o_arinc429_rx_par_err 	
// ARINC429_RX		
	,input    wire 			 i_arinc429_rx_A
	,input    wire 			 i_arinc429_rx_B
	
);

localparam DEVIDER_CLK_12_5_KHZ = IN_AVS_CLK/12500/32,
		   DEVIDER_CLK_50_KHZ   = IN_AVS_CLK/50000/32,
		   DEVIDER_CLK_100_KHZ  = IN_AVS_CLK/100000/32;

localparam REG_SIZE_CLK = 16;		   

//////////////////              MODELSIM                 /////////////////////
reg [REG_SIZE_CLK:0] clk_devider;
wire rx_on = !(clk_devider == 0);
wire rst_n = i_avs_rst_n & rx_on;
reg sig_rst_n;

//////////////////              GENERATE CLOCK            /////////////////////
//reg [REG_SIZE_CLK:0] clk_devider;
always @(posedge i_avs_clk or negedge i_avs_rst_n)
 begin 
   if(~i_avs_rst_n) 				clk_devider <= {REG_SIZE_CLK{1'b0}};
   else if(~sig_rst_n)
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
 
reg clk_16x;
always @(posedge i_avs_clk or negedge rst_n)
 begin 
   if(~rst_n) 								clk_16x <= 1'b0;
   else if(cnt_clk >= (clk_devider - 1))	clk_16x <= !clk_16x; 	
 end

//////////////////              ARINC429 RX             ///////////////////// 
wire arinc429_rx_A_p, arinc429_rx_B_p;
DDIN 
#(.INIT_VAL(0),
  .LEN_DATA(2'd2))
ddin_rx
(
/*  input   */  .clk(clk_16x),
/*	input   */  .rst_n(rst_n), 
/*	input 	*/	.in({i_arinc429_rx_A,i_arinc429_rx_B}),
/*	output	*/	.out({arinc429_rx_A_p,arinc429_rx_B_p})
);

wire arinc429_rx_A, arinc429_rx_B;
filter_input
#(.INIT_VAL(0),
  .LEN_DATA(2'd2))
filter_input_rx
(
/*  input   */  .clk(clk_16x),
/*	input   */  .rst_n(rst_n), 
/*	input 	*/	.in({arinc429_rx_A_p,arinc429_rx_B_p}),
/*	input   */  .cnt_const_T(16'd3),
/*	output	*/	.out({arinc429_rx_A,arinc429_rx_B})
);

reg sig_clk;
always @(posedge clk_16x or negedge rst_n)
 begin 
   if(~rst_n) 						sig_clk <= 1'b0;
   else 							sig_clk <= ~(arinc429_rx_A ^ arinc429_rx_B); 	
 end

reg sig_bit;
always @(posedge clk_16x or negedge rst_n)
 begin 
   if(~rst_n) 						 		sig_bit <= 1'b0;
   else if(arinc429_rx_A^arinc429_rx_B)		sig_bit <= arinc429_rx_A; 	
 end
 
reg [11:0] sig_ClkState;
always @(posedge clk_16x or negedge rst_n)
 begin 
   if(~rst_n) 						 		sig_ClkState <= 12'b0;
   else 									sig_ClkState <= {sig_ClkState[10:0],sig_clk}; 	
 end
 
//reg sig_rst_n;
always @(posedge clk_16x or negedge rst_n)
 begin 
   if(~rst_n) 						 										sig_rst_n <= 1'b0;
   else if((sig_ClkState == 12'h0) || (sig_ClkState == 12'hFFF))			sig_rst_n <= 1'b0;
   else 																	sig_rst_n <= 1'b1;
 end
 
reg [5:0] cnt_bit;
always @(posedge sig_clk or negedge sig_rst_n)
 begin 
   if(~sig_rst_n) 			cnt_bit <= 6'b0;
   else if(cnt_bit < 31)	cnt_bit <= cnt_bit + 1'b1;
 end
 
reg sig_valid;
always @(posedge sig_clk or negedge sig_rst_n)
 begin 
   if(~sig_rst_n) 			sig_valid <= 1'b0;
   else if(cnt_bit >= 31)	sig_valid <= 1'b1;
   else 					sig_valid <= 1'b0;
 end
 
reg [31:0] sig_data;
always @(posedge sig_clk or negedge sig_rst_n)
 begin 
   if(~sig_rst_n) 			sig_data <= 32'b0;
   else 					sig_data <= {sig_bit,sig_data[31:1]};
 end
 
reg sig_par;
always @(posedge sig_clk or negedge sig_rst_n)
 begin 
   if(~sig_rst_n) 			sig_par <= 1'b0;
   else 					sig_par <= sig_bit ^ sig_par;
 end

//////////////////              AVALON ST            /////////////////////
wire sig_valid_pe;
PEIN 
#(.INIT_VAL(1'b0),
.LEN_DATA(2'd1))
pein_inst
(
/*  input   */  .clk(i_avs_clk),
/*	input   */  .rst_n(i_avs_rst_n), 
/*	input 	*/	.in(sig_valid),
/*	output	*/	.out(sig_valid_pe)
);

always @(posedge i_avs_clk or negedge rst_n)
 begin 
   if(~rst_n) 								o_src_rx_valid <= 1'b0;
   else if(sig_valid_pe)					o_src_rx_valid <= 1'b1;	
   else	if(i_src_rx_ready)					o_src_rx_valid <= 1'b0;
 end
 
 
always @(posedge i_avs_clk or negedge rst_n)
 begin 
   if(~rst_n) 								o_src_rx_data <= 32'hface_dead;
   else if(sig_valid_pe)					o_src_rx_data <= sig_data;	
   //else	if(i_src_rx_ready)					o_src_rx_data <= 32'hface_dead;
 end 

always @(posedge i_avs_clk or negedge rst_n)
 begin 
   if(~rst_n) 								o_arinc429_rx_par_err <= 1'b0;
   else if(sig_valid_pe)					o_arinc429_rx_par_err <= !sig_par;	
   //else	if(i_src_rx_ready)					o_arinc429_rx_par_err <= 1'b0;
 end 
 
endmodule

