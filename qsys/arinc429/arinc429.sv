module arinc429 #(
	parameter REC_NUMB = 16,
	parameter TR_NUMB  = 6,
	parameter INPUTFREQUENCY = 62_500_000
) (
	input                                  clk              ,
	input                                  reset_n          ,
	input        [         (REC_NUMB-1):0] InputA           ,
	input        [         (REC_NUMB-1):0] InputB           ,
	output       [          (TR_NUMB-1):0] OutputA          ,
	output       [          (TR_NUMB-1):0] OutputB          ,
	output       [          (TR_NUMB-1):0] SlewRate         ,
	output reg   [                    1:0] TestAB           ,
	output logic                           ams_waitrequest  ,
	input                                  ams_write        ,
	input                                  ams_read         ,
	input        [($clog2(REC_NUMB)+16):0] ams_address      ,
	input        [                   31:0] ams_writedata    ,
	output                                 ams_readdatavalid,
	output logic [                   31:0] ams_readdata     ,
	///////////////
	output       [ (REC_NUMB+TR_NUMB-1):0] IRQ
);

//перечисление регистров обмена(всё будет подключено ко входам и выходам)
	reg[26:0]rxconfig[(REC_NUMB-1):0] ;
	reg[5:0]rxintmask[(REC_NUMB-1):0];
	wire[26:0]rxintflag[(REC_NUMB-1):0];

	reg[26:0]txconfig[(TR_NUMB-1):0] ;
	reg[3:0]txintmask[(TR_NUMB-1):0];
	wire[26:0]txintflag[(TR_NUMB-1):0];

	reg[(REC_NUMB-1):0]IRQ_clear='0;
	reg[(REC_NUMB-1):0]IRQ_clear_tx='0;
	localparam rec_number_bits = $clog2(REC_NUMB)+16;
//буферизация входов шины авалон
	reg [                  11:0] addr                ; always @( posedge clk )if(ams_write || ams_read)addr<=ams_address[11:0];
	reg [($clog2(REC_NUMB)-1):0] rec_trans_number    ; always @( posedge clk )if(ams_write || ams_read)rec_trans_number<=ams_address[(rec_number_bits-1):16];
	reg                          reciever_transmitter; always @( posedge clk )if(ams_write || ams_read)reciever_transmitter<=ams_address[rec_number_bits];
	reg                          conf_bit            ; always @( posedge clk )if(ams_write || ams_read)conf_bit<=ams_address[14];

	reg        wr     ; always @( posedge clk  )wr<=ams_write;
	reg [ 3:0] rd     ; always @( posedge clk  )rd<={rd[2:0],ams_read};
	reg [31:0] wr_data; always @( posedge clk  )if(ams_write)wr_data<=ams_writedata;

//регистры управления памятью
wire [31:0]bufer_q[(REC_NUMB-1):0]; // шины слов из буферов данных приемников
wire [31:0]flags_q[(REC_NUMB-1):0]; // шины флагов принятых слов приемников

reg [(REC_NUMB-1):0]rx_mask_wr;   always @( posedge clk )if( conf_bit && (( addr[5:4] == 2'd1 ) || ( addr[5:4] == 2'd2 )) ) rx_mask_wr[rec_trans_number]<=wr; // запись масок прерывания                                                
reg [(REC_NUMB-1):0]rx_buf_rd;    always @( posedge clk )rx_buf_rd[rec_trans_number] <= rd[0] && ( !reciever_transmitter ) && ( !conf_bit ); // сигналы чтения СД из буферов приемников
reg [(TR_NUMB-1):0]tr_buf_wr;     always @( posedge clk )tr_buf_wr[rec_trans_number] <= wr && ( reciever_transmitter ) && ( !conf_bit ); // сигналы записи СД в ФИФО передатчика
////////////////////////////////////

assign ams_readdatavalid=rd[3]; 
assign ams_waitrequest=1'b0;
always @( posedge clk or negedge reset_n ) 
  if(!reset_n) begin
  TestAB<=2'd0;
  end  else begin
  ams_readdata<='0; // обнуление шины при нормальных условиях
  if(conf_bit)  begin // если конфигурационный бит
    if(addr[5:4]==2'd0)
      case(addr[3:0]) // дешифратор настроечных регистров
        4'h0:begin
          if( wr && reciever_transmitter )              txconfig[rec_trans_number] <= wr_data; // запись конф.рег. передатчиков
          if( rd[2] && reciever_transmitter )           ams_readdata <= txconfig[rec_trans_number]; // чтение конф.рег. передатчиков
          if( wr && ( !reciever_transmitter ))          rxconfig[rec_trans_number] <= wr_data; // запись конф.рег. приемников
          if( rd[2] && ( !reciever_transmitter ))       ams_readdata <= rxconfig[rec_trans_number]; // чтение конф.рег. приемников
          
          if(wr&&(!reciever_transmitter))             TestAB<=wr_data[5:4];//включение тестового режима       
          
        end
        4'h4:begin
          if( wr && ( !reciever_transmitter ))          rxintmask[rec_trans_number] <= wr_data;//запись регистров масок
          if( wr && reciever_transmitter )              txintmask[rec_trans_number] <= wr_data;//                      прерываний
        end
        4'h8:begin
          if( !reciever_transmitter )IRQ_clear[rec_trans_number] <= rd[3]; // выставление сигналов 
          else IRQ_clear_tx[rec_trans_number] <= rd[3];                    //                     очищения прерываний
          if( rd[2] ) 
            if( !reciever_transmitter ) ams_readdata <= rxintflag[rec_trans_number];  // чтение регистров
            else                        ams_readdata <= txintflag[rec_trans_number];  //                  прерываний
        end
      endcase 
    if( ( &addr[5:4] ) || addr[6] )     ams_readdata <= flags_q[rec_trans_number]; // чтение флагов принятых слов приемников  
  end
  else ams_readdata <= bufer_q[rec_trans_number]; // чтение принятых СД
end

wire [3:0]mask_addr = {1'b0, addr[5], addr[3:2]}; // адрес для записи маски флагов СД
wire [3:0]flags_addr = {1'b1, addr[6], addr[3:2]}; // адрес для чтения флагов СД
	genvar i;
	generate for (i=0;i<REC_NUMB;i++) begin:addef
			arinc_rx_controller 
			#( .INPUTFREQUENCY( INPUTFREQUENCY ) )
			arinc_rx_controller_i (
				.clk           (clk                                ), // input  clk_sig
				.reset         (reset_n                            ),
				.rxconfig      (rxconfig[i][7:0]                   ),
				.rxintmask     (rxintmask[i]                       ),
				.rxintflag     (rxintflag[i]                       ),
				.IRQ           (IRQ[i]                             ),
				.IRQ_clear     (IRQ_clear[i]                       ),

				.InputA        (InputA[i]                          ),
				.InputB        (InputB[i]                          ),
				.bufer_data    (wr_data                            ), // input [DATA_WIDTH-1:0] bufer_data_sig
				.bufer_addr    (addr[11:2]                         ), // input [ADDR_WIDTH-1:0] bufer_addr_sig
				.bufer_rd      (rx_buf_rd[i]                       ), // input  bufer_we_sig
				.bufer_q       (bufer_q[i]                         ), // output [DATA_WIDTH-1:0] bufer_q_sig

				.flag_mask_addr(rx_mask_wr[i]?mask_addr:flags_addr ),
				.flag_mask_we  (rx_mask_wr[i]                      ),
				.flag_mask     (flags_q[i]                         )
			);
		end
	endgenerate

	genvar y;
	generate for (y=0;y<TR_NUMB;y++)  begin:gffdf
			arinc_tx_controller 
			#( .INPUTFREQUENCY( INPUTFREQUENCY ) )
			arinc_tx_controller_y (
				.clk       (clk                                              ), // input  clk_sig
				.reset     (reset_n                                          ), // input  reset_sig
				.OutputA   (OutputA[y]                                       ), // output  OutputA_sig
				.OutputB   (OutputB[y]                                       ), // output  OutputB_sig
				.txconfig  ({txconfig[y][26],txconfig[y][7],txconfig[y][1:0]}), // input [3:0] txconfig_sig
				.txintmask (txintmask[y]                                     ), // input [3:0] txintmask_sig
				.txintflag (txintflag[y]                                     ), // output [26:0] txintflag_sig
				.IRQ       (IRQ[REC_NUMB+y]                                  ), // output  IRQ_sig
				.IRQ_clear (IRQ_clear_tx[y]                                  ), // input  IRQ_clear_sig
				.bufer_data(wr_data                                          ), // input [31:0] bufer_data_sig
				.SlewRate  (SlewRate[y]                                      ),
				.bufer_wr  (tr_buf_wr[y]                                     )  // input  bufer_wr_sig
			);
		end
	endgenerate

endmodule