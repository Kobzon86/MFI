module arinc_rx_controller 
	#(parameter INPUTFREQUENCY = 50_000_000)
	(
	input             clk, reset    ,
	input             InputA, InputB,
	input      [ 7:0] rxconfig      ,
	input      [ 3:0] rxintmask     ,
	output reg [26:0] rxintflag     ,
	output            IRQ           ,
	input             IRQ_clear     ,
	input      [31:0] bufer_data    ,
	input      [ 9:0] bufer_addr    ,
	input             bufer_rd      ,
	output     [31:0] bufer_q       ,
	input      [ 3:0] flag_mask_addr,
	input             flag_mask_we  ,
	output     [31:0] flag_mask
);
	assign IRQ = |(rxintflag[3:0]&rxintmask);

	reg  unsigned [ 9:0] readed_addr ;
	reg           [ 9:0] bufer_addr_b;
	reg                  bufer_we_b  ;
	wire          [31:0] recieved_word;
	wire [31:0] arincDataOut = rxconfig[7] ? recieved_word : {recieved_word[31:8],
                                              recieved_word[0],recieved_word[1],recieved_word[2],recieved_word[3],
                                              recieved_word[4],recieved_word[5],recieved_word[6],recieved_word[7]};                                              

	true_dual_port_ram_single_clock ram_buf_inst (
		.addr_a(rxconfig[2]?bufer_addr:readed_addr),
		.addr_b(bufer_addr_b                      ),
		.clk   (clk                               ),
		.data_a(bufer_data                        ),
		.data_b(arincDataOut                      ),
		.we_a  (                                  ),
		.we_b  (bufer_we_b                        ),
		.q_a   (bufer_q                           ),
		.q_b   (                                  )
	);
	defparam ram_buf_inst.DATA_WIDTH = 32;
	defparam ram_buf_inst.ADDR_WIDTH = 10;

	reg  [ 3:0] mask_flags_addr     ;
	wire [31:0] flag_mask_q         ;
	wire [ 7:0] mask_arr       [3:0];
	assign mask_arr[0] = flag_mask_q[7:0];assign mask_arr[1]=flag_mask_q[15:8];
	assign mask_arr[2] = flag_mask_q[23:16];assign mask_arr[3]=flag_mask_q[31:24];
	reg         flag_we                                                                      ;
	reg  [ 7:0] flags_data  [3:0]                                                            ;
	wire [31:0] flags_data_b      = {flags_data[3],flags_data[2],flags_data[1],flags_data[0]};

	true_dual_port_ram_single_clock ram_mask_inst (
		.data_a(bufer_data     ),
		.data_b(flags_data_b   ),
		.addr_a(flag_mask_addr ),
		.addr_b(mask_flags_addr),
		.we_a  (flag_mask_we   ),
		.we_b  (flag_we        ),
		.clk   (clk            ),
		.q_a   (flag_mask      ),
		.q_b   (flag_mask_q    )
	);

	defparam ram_mask_inst.DATA_WIDTH = 32;
	defparam ram_mask_inst.ADDR_WIDTH = 4;



	wire RxFlag;
	wire ParErr;
	arinc429_rx arinc429_rx_inst (
		.i_avs_clk            (clk          ), // input  i_avs_clk_sig
		.i_avs_rst_n          (reset        ), // input  i_avs_rst_n_sig
		.o_src_rx_valid       (RxFlag       ), // output  o_src_rx_valid_sig
		.o_src_rx_data        (recieved_word ), // output [31:0] o_src_rx_data_sig
		.i_src_rx_ready       (1'b1         ), // input  i_src_rx_ready_sig
		.i_arinc429_speed     (rxconfig[1:0]), // input [1:0] i_arinc429_speed_sig
		.o_arinc429_rx_par_err(ParErr       ), // output  o_arinc429_rx_par_err_sig
		.i_arinc429_rx_A      (InputA       ), // input  i_arinc429_rx_A_sig
		.i_arinc429_rx_B      (InputB       )  // input  i_arinc429_rx_B_sig
	);

	defparam arinc429_rx_inst.IN_AVS_CLK = INPUTFREQUENCY;


	enum logic [1:0]{waiting, arinc_event,flag_check}state;
	reg unsigned [9:0] diff;
	reg[2:0]cnt;
	wire mask_accepted = (mask_arr[arincDataOut[4:3]]>>(arincDataOut[2:0]))&8'd1; //проверка адреса принятого слова с помощью маски
	wire[7:0]flag_clear_buf=~(8'd1<<(bufer_addr[2:0]));//сдвиг бита для снятия флага принитяого слова

	wire [10:0] addr_to_write = readed_addr+diff        ; //текущий адрес чтения плюс смещение
	wire [ 8:0] cout          = {addr_to_write[10],8'd0}; //перенос при переполнении

	reg        RxFlag_sig   = 0       ;
	reg        bufer_rd_sig = 0       ;
	reg  [7:0] last_addr              ; //последний записанный адрес
	wire       readed_more  = diff=='0;
	assign rxintflag[25:16] = rxconfig[2]?last_addr:diff;
	assign rxintflag[15:6]  = readed_addr-10'd256;
	assign rxintflag[5:4]   = {InputA,InputB};
//assign rxintflag[1]=rxconfig[2]?1'b0:(diff>10'd614);
	always @(posedge clk or negedge reset)
		if(!reset)begin cnt<='0; state<=waiting;
			readed_addr = 10'd256;
			diff        = '0;last_addr='0;rxintflag[26]=1'b0;rxintflag[3:0]='0;
		end
		else begin
			if(RxFlag)RxFlag_sig<=1'b1;
			if(bufer_rd)bufer_rd_sig<=1'b1;
			flags_data[0] <= mask_arr[0];flags_data[1]<=mask_arr[1];flags_data[2]<=mask_arr[2];flags_data[3]<=mask_arr[3];
			rxintflag[2]  <= &diff;
			if(IRQ_clear)rxintflag[3:0]<='0;

			flag_we       <= 1'b0;
			bufer_we_b    <= 1'b0;
			rxintflag[26] <= 1'b0;
			case(state)
				waiting : begin
					cnt <= '0;

					if(rxconfig[1:0]==2'b00)begin
						readed_addr <= 10'd256;
						diff        <= 10'd0;
					end

					if(RxFlag_sig)begin
						if( (!rxconfig[6]) && ParErr )	rxintflag[0]<=1'b1;
						else state<=arinc_event;
						RxFlag_sig <= 1'b0;
					end

					if((!rxconfig[2])&&bufer_rd_sig&&(|diff))begin
						readed_addr  <= (&readed_addr)?10'd256:readed_addr+1'b1;
						diff         <= diff-10'd1;
						bufer_rd_sig <= 1'b0;
					end

					if(rxconfig[2]&&bufer_rd_sig)begin
						state        <= flag_check;
						bufer_rd_sig <= 1'b0;
					end
				end

				arinc_event : begin
					rxintflag[26]                 <= 1'b1;
					flags_data[arincDataOut[4:3]] <= mask_arr[arincDataOut[4:3]]|(8'd1<<(arincDataOut[2:0]));
					cnt                           <= cnt+1'b1;
					case(cnt)
						3'd0 : mask_flags_addr<={1'b0,arincDataOut[7:5]};//адр.масок
						3'd5 : if(mask_accepted)
							begin
								bufer_addr_b <= rxconfig[2]?arincDataOut[7:0]:(addr_to_write[9:0]+cout);
								bufer_we_b   <= 1'b1;
								if(rxconfig[2])last_addr<=arincDataOut[7:0];//адресный режим
								else diff<=(&diff)?diff:diff+1'b1;
								rxintflag[3] <= 1'b1;
							end
						3'd6 : mask_flags_addr<={1'b1,arincDataOut[7:5]};//адр.флагов
						3'd7 : begin state<=waiting; flag_we<=mask_accepted && rxconfig[2];	end
					endcase
				end

				flag_check : begin
					flags_data[bufer_addr[4:3]] <= mask_arr[bufer_addr[4:3]]&flag_clear_buf;
					cnt                         <= cnt+1'b1;
					case(cnt)
						3'd0 : mask_flags_addr<={1'b1,bufer_addr[7:5]};
						3'd3 : begin
							flag_we <= 1'b1;
							state   <= waiting;
						end
					endcase
				end
				default state<=waiting;
			endcase
		end


endmodule


// Quartus Prime Verilog Template
// True Dual Port RAM with single clock

module true_dual_port_ram_single_clock #(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=4) (
	input      [(DATA_WIDTH-1):0] data_a, data_b,
	input      [(ADDR_WIDTH-1):0] addr_a, addr_b,
	input                         we_a, we_b, clk,
	output reg [(DATA_WIDTH-1):0] q_a, q_b
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Port A
	always @ (posedge clk)
		begin
			if (we_a)
				begin
					ram[addr_a] <= data_a;
					q_a         <= data_a;
				end
			else
				begin
					q_a <= ram[addr_a];
				end
		end

	// Port B
	always @ (posedge clk)
		begin
			if (we_b)
				begin
					ram[addr_b] <= data_b;
					q_b         <= data_b;
				end
			else
				begin
					q_b <= ram[addr_b];
				end
		end

endmodule
