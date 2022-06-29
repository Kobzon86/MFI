module arinc708 
#(parameter REC_NUMB=2,
  parameter INPUTFREQUENCY = 62_500_000
  )
( 
  input clk,
  input reset_n,
  input [(REC_NUMB-1):0]InputA,
  input [(REC_NUMB-1):0]InputB,
  output [(REC_NUMB-1):0]OutputA,
  output [(REC_NUMB-1):0]OutputB,
  output reg[(REC_NUMB-1):0]TX_INH,
  output reg[(REC_NUMB-1):0]RX_EN,
  
  output logic           ams_waitrequest,
  input                  ams_write,
  input                  ams_read,
  input         [($clog2(REC_NUMB)+15):0]ams_address,
  input         [31:0]ams_writedata,
  output              ams_readdatavalid,
  output logic  [31:0]ams_readdata,

  ///////////////
  output [(REC_NUMB+REC_NUMB-1):0]IRQ
);

//перечисление регистров обмена
reg[26:0]config_reg[(REC_NUMB-1):0] ;//конфигурационные регистры
reg[5:0]intmask[(REC_NUMB-1):0];     //регистры масок прерываний
wire[26:0]intTxflag[(REC_NUMB-1):0]; //регистры прерываний передатчиков
wire[26:0]intRxflag[(REC_NUMB-1):0]; //регистры прерываний приемников

reg[(REC_NUMB-1):0]IRQ_clear = '0;   //сигнал очисткирегистров прерываний
localparam rec_number_bits = $clog2(REC_NUMB) + 16; // старший бит адреса AMM
//////////////////////////////////
//буферизация входов шины авалон
reg[11:0]addr;                                  always @( posedge clk  )if(ams_write || ams_read)addr<=ams_address[11:0]; //выделение значащей части адреса AMM
reg [($clog2(REC_NUMB)-1):0] rec_trans_number;  always @( posedge clk  )if(ams_write || ams_read)rec_trans_number<=ams_address[(rec_number_bits-1):16]; //мультиплексор номера П/П
reg conf_bit;                                   always @( posedge clk  )if(ams_write || ams_read)conf_bit<=ams_address[14]; //конфигурационный бит адреса
reg tr_buf_bit;                                 always @( posedge clk  )if(ams_write || ams_read)tr_buf_bit<=|ams_address[13:11]; //мультиплексор буферов передатчика/приемника

reg wr;                                         always @( posedge clk  )wr<=ams_write; //буфер сигнала записи
reg [3:0]rd;                                    always @( posedge clk  )rd<={rd[2:0],ams_read}; //ЛЗ сигнала чтения 
reg [31:0] wr_data;                             always @( posedge clk  )if(ams_write)wr_data<=ams_writedata; //буфер шины на запись
/////////////////////////////////
//сигналы управления памятью
wire [31:0]bufer_q[(REC_NUMB-1):0]; // шины слов из буферов данных П/П
                                        
reg [(REC_NUMB-1):0]rx_buf_rd;    always @( posedge clk  )rx_buf_rd[rec_trans_number]<=rd[0] &&(!conf_bit)&&(!tr_buf_bit); //сигнал чтения из буфера N-го приемника
reg [(REC_NUMB-1):0]tr_buf_wr;    always @( posedge clk  )tr_buf_wr[rec_trans_number]<=wr &&(!conf_bit)&&tr_buf_bit;       //сигнал записи буфера N-го передатчика
/////////////////////////////////
assign ams_readdatavalid = rd[3];
assign ams_waitrequest = 1'b0;
always @( posedge clk or negedge reset_n ) 
  if(!reset_n) begin  
    IRQ_clear = '0;
  end  else begin
  ams_readdata <= '0;
  if( conf_bit )  begin //если выставлен конфигурационный бит
    if( addr[5:4] == 2'd0 )
      case( addr[3:0] ) // дешифратор настроечных регистров
        4'h0:begin
          if(wr)            config_reg[rec_trans_number]<=wr_data;//запись конфигурационного регистра N-го П/П
          if(rd[2])         ams_readdata<= config_reg[rec_trans_number];//чтение конфигурационного регистра N-го П/П      
          //if(wr)            TX_INH[rec_trans_number]<=!wr_data[1];//выключение передатчика
          if(wr)            RX_EN[rec_trans_number]<=wr_data[0];//включение приемника
          end
        4'h4:begin
          if(wr)            intmask[rec_trans_number]<=wr_data;//запись масок прерывания N-го П/П 
        end
        4'h8:begin
          IRQ_clear[rec_trans_number]<=rd[3];//сброс некоторых прерываний при чтении регистра прерываний приемника
          if(rd[2]) 
            ams_readdata<= intTxflag[rec_trans_number] | intRxflag[rec_trans_number]; //чтение регистра прерываний
        end
        default: begin end 
      endcase 
  end
  else ams_readdata<=bufer_q[rec_trans_number];//вадача слов из буфера данных при чтении
end

genvar i;
generate for( i=0; i<REC_NUMB; i++ ) begin:addef  //создание приемников
arinc708_rx_controller 
#( .INPUTFREQUENCY( INPUTFREQUENCY ) )
arinc708_rx_controller_i (
  .clk       (clk                                      ), // input  clk_sig
  .reset     (reset_n                                  ), // input  reset_sig
  .InputA    (InputA[i]                                ), // input  InputA_sig
  .InputB    (InputB[i]                                ), // input  InputB_sig
  .rxconfig  ({1'd0,config_reg[i][26],config_reg[i][0]}), // input [2:0] rxconfig_sig
  .rxintmask (intmask[i][2:0]                          ), // input [3:0] rxintmask_sig
  .rxintflag (intRxflag[i]                             ), // output [26:0] rxintflag_sig
  .IRQ       (IRQ[i]                                   ), // output  IRQ_sig
  .IRQ_clear (IRQ_clear[i]                             ), // input  IRQ_clear_sig
  .bufer_data(wr_data                                  ), // input [31:0] bufer_data_sig
  .bufer_addr(addr[11:2]                               ), // input [9:0] bufer_addr_sig
  .bufer_rd  (rx_buf_rd[i]                             ), // input  bufer_rd_sig
  .bufer_q   (bufer_q[i]                               )  // output [31:0] bufer_q_sig
);
end
endgenerate


genvar y;
generate for (y=0;y<REC_NUMB;y++)  begin:gffdf //создание передатчиков
arinc708_tx_controller 
#( .INPUTFREQUENCY( INPUTFREQUENCY ) )
arinc708_tx_controller_y (
  .clk       (clk                                                                   ), // input  clk_sig
  .reset     (reset_n                                                               ), // input  reset_sig
  .OutputA   (OutputA[y]                                                            ), // output  OutputA_sig
  .OutputB   (OutputB[y]                                                            ), // output  OutputB_sig
  .txconfig  ({config_reg[y][26],config_reg[y][7],config_reg[y][2],config_reg[y][1]}), // input [3:0] txconfig_sig
  .txintmask (intmask[y][2:1]                                                       ), // input [3:0] txintmask_sig
  .txintflag (intTxflag[y]                                                          ), // output [26:0] txintflag_sig
  .IRQ       (IRQ[REC_NUMB+y]                                                       ), // output  IRQ_sig
  .IRQ_clear (IRQ_clear[y]                                                       ), // input  IRQ_clear_sig
  .bufer_data(wr_data                                                               ), // input [31:0] bufer_data_sig
  .bufer_wr  (tr_buf_wr[y]                                                          ),  // input  bufer_wr_sig
  .tx_Off    (TX_INH[y])
);

end
endgenerate

endmodule