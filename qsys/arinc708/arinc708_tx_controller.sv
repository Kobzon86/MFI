module arinc708_tx_controller 
    #(parameter INPUTFREQUENCY = 50_000_000)
    (
    input             clk, reset,
    output            OutputA, OutputB,
    input      [ 3:0] txconfig  ,
    input      [ 3:0] txintmask ,
    output reg [26:0] txintflag ,
    output            IRQ       ,
    input             IRQ_clear ,
    input      [31:0] bufer_data,
    input             bufer_wr,
    output  tx_Off
);
assign IRQ=|( txintflag[3:0] & txintmask );
    
wire full;
wire empty;
wire[31:0]q_sig;
wire[8:0]usedw;
reg WrEn = 0; // сигнал старта передачи слова
wire Tr_Ready; // сигнал готовности к передаче
reg Tr_Ready_sig = 0; always @( posedge clk )Tr_Ready_sig <= Tr_Ready; // буфер сигнала

reg rdreq; // запрос чтения из ФИФО
reg rdreq_sig;      always @( posedge clk )rdreq_sig <= rdreq; // буфер сигнала
reg [1:0]WrEn_sig;  always @( posedge clk )WrEn_sig <= { WrEn_sig[0], WrEn }; // ЛЗ сигнала передачи слова

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
//  dcfifo_component.intended_device_family =FAMILY,
    dcfifo_component.lpm_numwords = 512,
    dcfifo_component.lpm_showahead = "ON",
    dcfifo_component.lpm_type = "dcfifo",
    dcfifo_component.lpm_width = 32,
    dcfifo_component.lpm_widthu = 9,
    dcfifo_component.overflow_checking = "ON",
    dcfifo_component.rdsync_delaypipe = 5,
    dcfifo_component.underflow_checking = "ON",
    dcfifo_component.use_eab = "ON",
    dcfifo_component.wrsync_delaypipe = 5;

wire tr_completed; // сигнал завершения передачи пакета
wire tr_active; // сигнал передача выполняется
reg [1:0]enable=0; // ЛЗ сигнала включения передатчика
arinc708_tx arinc708_tx_inst (
    .i_avs_clk             (clk         ), // input  i_avs_clk_sig
    .i_avs_rst_n           (reset       ), // input  i_avs_rst_n_sig
    .i_sink_tx_valid       (WrEn_sig[1] ), // input  i_sink_tx_valid_sig
    .i_sink_tx_data        (q_sig       ), // input [31:0] i_sink_tx_data_sig
    .o_sink_tx_ready       (Tr_Ready    ), // output  o_sink_tx_ready_sig
    .i_arinc708_tx_en      (txconfig[0] ), // input  i_arinc708_tx_en_sig
    .o_arinc708_tx_active  (tr_active   ), // output  o_arinc708_tx_active_sig
    .o_arinc708_tx_compl_pe(tr_completed), // output  o_arinc708_tx_compl_pe_sig
    .o_arinc708_tx_A       (OutputA     ), // output  o_arinc708_tx_A_sig
    .o_arinc708_tx_B       (OutputB     ), // output  o_arinc708_tx_B_sig
    .o_arinc708_tx_Off     (tx_Off      )  // output  o_arinc708_tx_Off_sig
);

defparam arinc708_tx_inst.IN_AVS_CLK = INPUTFREQUENCY; 

wire busy = txconfig[3]; // сигнал занятости памяти со стороны процессора
reg fifo_wr_sig = 0; //флаг готовности к передаче
always@( posedge clk or negedge reset )
if( !reset ) begin txintflag[1] <= 1'b0; enable <=2'b00; end
else begin  

    enable<={enable[0], txconfig[0]};
    
    if( tr_completed ) txintflag[1] <= 1'b1;    
    if( IRQ_clear ) txintflag[1] <= 1'b0;   
    
    fifo_wr_sig <= enable == 2'b11; 
    
    WrEn <= ( !busy ) && ( !empty ) && fifo_wr_sig  && ( !tr_active ) ; 
    
    rdreq <= Tr_Ready && ( !Tr_Ready_sig );
    
end
endmodule
