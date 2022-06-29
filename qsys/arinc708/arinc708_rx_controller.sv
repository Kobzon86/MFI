module arinc708_rx_controller 
#(parameter INPUTFREQUENCY = 50_000_000)
    (
    input             clk, reset,
    input             InputA, InputB,
    input      [ 2:0] rxconfig  ,
    input      [ 3:0] rxintmask ,
    output reg [26:0] rxintflag ,
    output            IRQ       ,
    input             IRQ_clear ,
    input      [31:0] bufer_data,
    input      [ 9:0] bufer_addr,
    input             bufer_rd  ,
    output     [31:0] bufer_q
);
assign IRQ=|(rxintflag[2:0]&rxintmask);

reg unsigned[8:0]readed_addr; //текущий адрес чтения 
reg [8:0]bufer_addr_b; // шина адреса памяти для записи со стороный приемника
reg bufer_we_b; // сигнал записи со стороны приемника
wire [31:0]arincDataOut; // шина принятого слова
true_dual_port_ram_single_clock ram_buf_inst ( 
    .addr_a(bufer_addr  ),
    .addr_b(bufer_addr_b),
    .clk   (clk         ),
    .data_a(bufer_data  ),
    .data_b(arincDataOut),
    .we_a  (            ),
    .we_b  (bufer_we_b  ),
    .q_a   (bufer_q     ),
    .q_b   (            )
);
defparam ram_buf_inst.DATA_WIDTH = 32;
defparam ram_buf_inst.ADDR_WIDTH = 9;

wire RxFlag;// сигнал получения слова
wire ParErr;// сигнал ошибки слова
wire packet_recieved; // сигнал получения пакета из 50-ти слов
arinc708_rx arinc708_rx_inst (
    .i_avs_clk             (clk            ), // input  i_avs_clk_sig
    .i_avs_rst_n           (reset          ), // input  i_avs_rst_n_sig
    .o_src_rx_valid        (RxFlag         ), // output  o_src_rx_valid_sig
    .o_src_rx_data         (arincDataOut   ), // output [31:0] o_src_rx_data_sig
    .i_src_rx_ready        (1'b1           ), // input  i_src_rx_ready_sig
    .i_arinc708_rx_en      (rxconfig[0] && ( !rxconfig[1]) ), // input  i_arinc708_rx_en_sig
    .o_arinc708_rx_active  (               ), // output  o_arinc708_rx_active_sig
    .o_arinc708_rx_compl_pe(packet_recieved), // output  o_arinc708_rx_compl_pe_sig
    .o_arinc708_rx_err_pe  (ParErr         ), // output  o_arinc708_rx_err_pe_sig
    .i_arinc708_rx_A       (InputA         ), // input  i_arinc708_rx_A_sig
    .i_arinc708_rx_B       (InputB         ), // input  i_arinc708_rx_B_sig
    .o_arinc708_rx_On      (               )  // output  o_arinc708_rx_On_sig
);

defparam arinc708_rx_inst.IN_AVS_CLK = INPUTFREQUENCY;

reg unsigned[9:0]diff;// текущее смещение прочтенного адреса относительно записанного (для функционала ФИФО)

reg RxFlag_sig = 0;//флаг сигнала получения слова
reg bufer_rd_sig = 0;// флаг сигнала чтения памяти Авалоном
assign rxintflag[22:13] = diff;
assign rxintflag[12:3] = readed_addr;

always @(posedge clk or negedge reset)
    if(!reset)begin 
    readed_addr = '0;
    diff = '0; rxintflag[2:0] = '0;
    end
    else begin

        if( !rxconfig[0] ) begin // при выключение приемника
            readed_addr <= '0; //обнуление ФИФО
            diff <= '0;        //
        end

        if( RxFlag )    RxFlag_sig      <= 1'b1;// установка флага получения слова
        if( bufer_rd )  bufer_rd_sig    <= 1'b1;// установка флага чтения от Авалона
        if( IRQ_clear ) rxintflag[2:0]  <= '0;  // очистка прерываний
        
        bufer_we_b <= 1'b0; //снятие сигнала записи ФИФО в нормальных условиях
        
        if( packet_recieved )rxintflag[0]<=1'b1;// запись прерывания при получении пакета из 50 слов

        if( RxFlag_sig )begin // если флаг получения слова
            if( ParErr ) rxintflag[2]<=1'b1; // вдруг ошибка
            else begin //без ошибки
                bufer_addr_b <= ( readed_addr + diff ); // текущий адрес чтения плюс смещение
                bufer_we_b <= 1'b1; //установка сигнала записи ФИФО
                diff <= ( &diff ) ? diff : ( diff + 1'b1 ); //Увеличение смещения ФИФО ( при максимальном значении не увеличивается )           
            end
            RxFlag_sig <= 1'b0; // снятие флага
        end
        else if( bufer_rd_sig )begin // при чтении слова Авалоном 
            if(|diff)begin           // и наличии новых слов в ФИФО
                readed_addr <= readed_addr + 1'b1; // увеличение прочтенного адреса
                diff <= diff - 10'd1; // уменьшение смещения ФИФО
            end
            bufer_rd_sig <= 1'b0; // снятие флага
        end

    end     
    
endmodule 
