module arinc_tx_controller 
	#(parameter INPUTFREQUENCY = 50_000_000)
	(
	input             clk, reset,
	output            OutputA, OutputB,
	input      [ 3:0] txconfig  ,
	input      [ 3:0] txintmask ,
	output reg [26:0] txintflag ,
	output            IRQ       ,
	output            SlewRate  ,
	input             IRQ_clear ,
	input      [31:0] bufer_data,
	input             bufer_wr
);
	assign IRQ = |(txintflag[3:0]&txintmask);



	wire full ;
	wire empty;
	wire[31:0]q_sig;
	wire[8:0]usedw;
	reg        WrEn         = 0;
	wire       Tr_Ready        ;
	reg  [7:0] Tr_Ready_sig    ; always @(posedge clk)Tr_Ready_sig<={Tr_Ready_sig[6:0],Tr_Ready};
	wire       busy            ;

	reg       rdreq    ;
	reg       rdreq_sig; always @(posedge clk)rdreq_sig<=rdreq;
	reg [1:0] WrEn_sig ; always @(posedge clk)WrEn_sig<={WrEn_sig[0],WrEn};

	dcfifo dcfifo_component (
		.data     (bufer_data         ),
		.rdclk    (clk                ),
		.rdreq    (rdreq&&(!rdreq_sig)),
		.wrclk    (clk                ),
		.wrreq    (bufer_wr           ),
		.q        (q_sig              ),
		.rdempty  (empty              ),
		.wrfull   (full               ),
		.wrusedw  (usedw              ),
		.aclr     (                   ),
		.eccstatus(                   ),
		.rdfull   (                   ),
		.rdusedw  (                   ),
		.wrempty  (                   )
	);
	defparam
//	dcfifo_component.intended_device_family =FAMILY,
		dcfifo_component.lpm_numwords = 512,
			dcfifo_component.lpm_showahead = "OFF",
				dcfifo_component.lpm_type = "dcfifo",
					dcfifo_component.lpm_width = 32,
						dcfifo_component.lpm_widthu = 9,
							dcfifo_component.overflow_checking = "ON",
								dcfifo_component.rdsync_delaypipe = 5,
									dcfifo_component.underflow_checking = "ON",
										dcfifo_component.use_eab = "ON",
											dcfifo_component.wrsync_delaypipe = 5;

wire [31:0] word_to_trancieve = txconfig[2] ? q_sig : {q_sig[31:8],
                                              q_sig[0],q_sig[1],q_sig[2],q_sig[3],q_sig[4],q_sig[5],q_sig[6],q_sig[7]};
	arinc429_tx arinc429_tx_inst (
		.i_avs_clk        (clk              ), // input  i_avs_clk_sig
		.i_avs_rst_n      (reset            ), // input  i_avs_rst_n_sig
		.i_sink_tx_valid  (WrEn_sig[1]      ), // input  i_sink_tx_valid_sig
		.i_sink_tx_data   (word_to_trancieve), // input [31:0] i_sink_tx_data_sig
		.o_sink_tx_ready  (Tr_Ready         ), // output  o_sink_tx_ready_sig
		.i_arinc429_speed (txconfig[1:0]    ), // input [1:0] i_arinc429_speed_sig
		.o_arinc429_tx_A  (OutputA          ), // output  o_arinc429_tx_A_sig
		.o_arinc429_tx_B  (OutputB          ), // output  o_arinc429_tx_B_sig
		.o_arinc429_tx_SLP(SlewRate         )  // output  o_arinc429_tx_SLP_sig
	);

	defparam arinc429_tx_inst.IN_AVS_CLK = INPUTFREQUENCY;

	reg fifo_wr_sig = 0;
//assign txintflag[5:4]={OutputA,OutputB};
	always@(posedge clk or negedge reset)
		if(!reset) begin txintflag[1]<=1'b0; end
		else begin
			txintflag[2] <= full;
			txintflag[1] <= (Tr_Ready&&(!Tr_Ready_sig) )?1'b1:txintflag[1];
			txintflag[0] <= empty;
			if(IRQ_clear)txintflag[1]<=1'b0;

			if(Tr_Ready&&(!Tr_Ready_sig[0]) )fifo_wr_sig<=1'b1;
			else if(Tr_Ready_sig=='0)fifo_wr_sig<=1'b0;

			WrEn  <= 1'b0;
			rdreq <= 1'b0;

			if((!empty)&&(fifo_wr_sig) )begin
				rdreq       <= 1'b1;
				WrEn        <= 1'b1;
				fifo_wr_sig <= 1'b0;
			end
		end
	always@(posedge clk)txintflag[25:16]<=10'd512-usedw;
endmodule

