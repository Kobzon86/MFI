module arinc708_tx #(
  parameter IN_AVS_CLK = 32'd100000000
  ) (
  input  logic        i_avs_clk             ,
  input  logic        i_avs_rst_n           ,
  //Avalon_ST SINK
  input  logic        i_sink_tx_valid       ,
  input  logic [31:0] i_sink_tx_data        ,
  output logic        o_sink_tx_ready       ,
  // Configuration
  input  logic        i_arinc708_tx_en      ,
  output logic        o_arinc708_tx_active  ,
  output logic        o_arinc708_tx_compl_pe,
  // ARINC708
  output logic        o_arinc708_tx_A       ,
  output logic        o_arinc708_tx_B       ,
  output logic        o_arinc708_tx_Off
);

  localparam PERIOD    = IN_AVS_CLK/1000000; //period of A708 bit
  localparam DATA_SIZE = 50                ; //count of A708 words in AST words (1600 bits)
  localparam WORD_SIZE = 32                ; //AST word size in bits

  typedef enum logic [ 2:0 ] {
    IDLE,
    START,
    TRANSMIT,
    END
  } e_tx_fsm;

  e_tx_fsm next_state_tx   ;
  e_tx_fsm current_state_tx;

  logic                           bit_cnt_en         ;
  logic [$clog2(WORD_SIZE-1)-1:0] bit_cnt            ; //counter of bits
  logic                           tmr_cnt_en         ;
  logic                           tmr_cnt_en_q       ;
  logic [   $clog2(PERIOD/2-1):0] tmr_cnt            ; //counter of bit timer
  logic [                    2:0] semiperiod_cnt     ; //counter of semiperiod A708 clock for START & STOP
  logic                           wrd_cnt_en         ;
  logic [$clog2(DATA_SIZE-1)-1:0] wrd_cnt            ; //counter of ast words
  logic [          WORD_SIZE-1:0] ast_wrd            ; //word to transmit
  logic [          WORD_SIZE-1:0] ast_wrd_shift      ; //word to transmit
  logic                           sink_tx_ready      ; //flag of AST word refresh
  logic                           sink_tx_ready_q    ;
  logic                           rst_n              ;
  logic                           finish             ; //strobe of transmit ending
  logic                           finish_q           ;
  logic                           clk_a708           ; //1MHz clock
  logic                           clk_a708_q         ;
  logic                           clk_a708_en        ;
  logic                           sink_tx_valid_del  ;
  logic                           sink_tx_valid_del_q;
  logic                           period_1_5         ;

  assign o_arinc708_tx_active = !( current_state_tx == IDLE );

  //reset generator
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge i_avs_rst_n )
    begin : res_gen
      if ( ~i_avs_rst_n )
        rst_n <= '0;
      else
        rst_n <= i_arinc708_tx_en;
    end

  //finish generator
  ////////////////////////////////////////////////////////////////////////////
  assign o_arinc708_tx_compl_pe = finish && !finish_q;//lasts only 1 cycle

  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : finish_gen
      if ( !rst_n )
        finish_q <= '0;
      else
        finish_q <= finish;
    end

  //AST ready generator
  ////////////////////////////////////////////////////////////////////////////
  assign o_sink_tx_ready = sink_tx_ready && !sink_tx_ready_q;//lasts only 1 cycle

  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : rdy_gen
      if ( !rst_n )
        sink_tx_ready_q <= '0;
      else
        sink_tx_ready_q <= sink_tx_ready;
    end

  //A708 coder to Manchester code (G.E. Thomas)
  ////////////////////////////////////////////////////////////////////////////
  always_comb
    begin
      unique case (current_state_tx)
        IDLE :
          begin
            o_arinc708_tx_A = 1'b0;
            o_arinc708_tx_B = 1'b0;
          end
        START :
          begin
            if ( semiperiod_cnt <= 3'h2 )
              begin
                o_arinc708_tx_A = 1'b1;
                o_arinc708_tx_B = 1'b0;
              end
            else
              begin
                o_arinc708_tx_A = 1'b0;
                o_arinc708_tx_B = 1'b1;
              end
          end
        TRANSMIT :
          begin
            o_arinc708_tx_A = ~( ast_wrd_shift[0] ^ clk_a708_q );
            o_arinc708_tx_B = ( ast_wrd_shift[0] ^ clk_a708_q );
          end
        END :
          begin
            if ( semiperiod_cnt <= 3'h2 )
              begin
                o_arinc708_tx_A = 1'b0;
                o_arinc708_tx_B = 1'b1;
              end
            else
              begin
                o_arinc708_tx_A = 1'b1;
                o_arinc708_tx_B = 1'b0;
              end
          end
        default :
          begin
            o_arinc708_tx_A = 1'b0;
            o_arinc708_tx_B = 1'b0;
          end
      endcase
    end

  //TX valid synchronizer
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : tx_valid_sync
      if( !rst_n )
        sink_tx_valid_del <= '0;
      else
        begin
          if ( i_sink_tx_valid )
            sink_tx_valid_del <= 1'b1;
          else if ( sink_tx_valid_del_q )
            sink_tx_valid_del <= 1'b0;
        end
    end

  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin
      if( !rst_n )
        sink_tx_valid_del_q <= '0;
      else if ( clk_a708_en )
        sink_tx_valid_del_q <= sink_tx_valid_del;
    end

  //A708 period counter
  ////////////////////////////////////////////////////////////////////////////
  assign period_1_5 = !tmr_cnt_en_q && ( semiperiod_cnt == 3'h2 || semiperiod_cnt == 3'h5 );

  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : semiperiod_counter
      if ( !rst_n )
        begin
          semiperiod_cnt <= '0;
          tmr_cnt_en_q   <= '0;
        end
      else
        begin
          tmr_cnt_en_q <= tmr_cnt_en;
          if ( !tmr_cnt_en_q )
            begin
              if ( current_state_tx == START || current_state_tx == END )
                semiperiod_cnt <= semiperiod_cnt + 1'b1;
              else
                semiperiod_cnt <= '0;
            end
        end
    end

  //A708 clock generator
  ////////////////////////////////////////////////////////////////////////////
  assign tmr_cnt_en = ( tmr_cnt == PERIOD/2 - 1 ) ? 1'b0 : 1'b1;

  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : clk_gen
      if ( !rst_n )
        clk_a708 <= '0;
      else if ( !tmr_cnt_en )
        clk_a708 <= ~ clk_a708;
    end

  //A708 clock enable generator
  ////////////////////////////////////////////////////////////////////////////
  assign clk_a708_en = clk_a708 && !clk_a708_q;

  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : clk_en_gen
      if ( !rst_n )
        clk_a708_q <= '0;
      else
        clk_a708_q <= clk_a708;
    end

  //timer counter
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : timer_counter
      if ( !rst_n )
        tmr_cnt <= '0;
      else if ( tmr_cnt_en )
        tmr_cnt <= tmr_cnt + 1'b1;
      else
        tmr_cnt <= '0;
    end

  //word counter
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : word_counter
      if ( !rst_n )
        wrd_cnt <= '0;
      else if ( clk_a708_en )
        begin
          if ( wrd_cnt_en )
            wrd_cnt <= wrd_cnt + 1'b1;
          else if ( current_state_tx == IDLE )
            wrd_cnt <= '0;
        end
    end

  //bit counter
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : bit_counter
      if ( !rst_n )
        bit_cnt <= '0;
      else if ( clk_a708_en )
        begin
          if ( bit_cnt_en )
            bit_cnt <= bit_cnt + 1'b1;
          else if ( current_state_tx == IDLE )
            bit_cnt <= '0;
        end
    end

  //AST word register
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : word_register
      if ( !rst_n )
        ast_wrd <= '0;
      // else if ( sink_tx_ready && !sink_tx_ready_q && i_sink_tx_valid )//normal realization of AST
      else if ( sink_tx_ready && !sink_tx_ready_q )
        ast_wrd <= i_sink_tx_data;
    end

  //AST word shift register (big endian)
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : shift_register
      if ( !rst_n )
        ast_wrd_shift <= '0;
      else if ( clk_a708_en )
        begin
          if ( sink_tx_ready )
            ast_wrd_shift <= ast_wrd;
          else if ( current_state_tx == TRANSMIT )
            ast_wrd_shift <= { 1'b0, ast_wrd_shift[WORD_SIZE-1:1] };
        end
    end

  //FSM for A708 TX
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : FSM_TX
      if ( !rst_n )
        current_state_tx <= IDLE;
      else if ( clk_a708_en || period_1_5 )
        current_state_tx <= next_state_tx;
    end

  always_comb
    begin
      unique case ( current_state_tx )
        IDLE : //waiting for valid data
          begin
            next_state_tx = IDLE;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            sink_tx_ready = 1'b0;
            finish        = 1'b0;
            if ( sink_tx_valid_del_q )
              begin
                next_state_tx = START;
                sink_tx_ready = 1'b1;
              end
          end
        START :
          begin
            next_state_tx = START;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            sink_tx_ready = 1'b0;
            finish        = 1'b0;
            if ( semiperiod_cnt == 3'h5 )
              next_state_tx = TRANSMIT;
          end
        TRANSMIT :
          begin
            next_state_tx = TRANSMIT;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b1;
            sink_tx_ready = 1'b0;
            finish        = 1'b0;
            if (bit_cnt == WORD_SIZE - 1 )
              begin
                wrd_cnt_en    = 1'b1;
                sink_tx_ready = 1'b1;//continue transmit despite on i_sink_tx_valid missing
                if ( wrd_cnt == DATA_SIZE - 1 )
                  begin
                    sink_tx_ready = 1'b0;
                    bit_cnt_en    = 1'b0;
                    next_state_tx = END;
                  end
              end
          end
        END :
          begin
            next_state_tx = END;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            sink_tx_ready = 1'b0;
            finish        = 1'b0;
            if ( semiperiod_cnt == 3'h5 )
              begin
                finish        = 1'b1;
                next_state_tx = IDLE;
              end
          end
        default :
          begin
            next_state_tx = IDLE;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            sink_tx_ready = 1'b0;
            finish        = 1'b0;
          end
      endcase
    end

endmodule

