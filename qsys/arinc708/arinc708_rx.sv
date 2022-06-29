
module arinc708_rx #(
  parameter IN_AVS_CLK = 32'd100000000
  ) (
  input  logic        i_avs_clk             ,
  input  logic        i_avs_rst_n           ,
  //Avalon_ST SRC
  output logic        o_src_rx_valid        ,
  output logic [31:0] o_src_rx_data         ,
  input  logic        i_src_rx_ready        ,
  // Configuration
  input  logic        i_arinc708_rx_en      ,
  output logic        o_arinc708_rx_active  ,
  output logic        o_arinc708_rx_compl_pe,
  output logic        o_arinc708_rx_err_pe  ,
  // ARINC708
  input  logic        i_arinc708_rx_A       ,
  input  logic        i_arinc708_rx_B       ,
  output logic        o_arinc708_rx_On
);

  localparam PERIOD    = IN_AVS_CLK/1000000; //period of A708 bit
  localparam TIMER_CNT = int'(3 * PERIOD/4); // 3/4 of period for synchronization
  localparam DATA_SIZE = 50                ; //count of A708 words in AST words (1600 bits)
  localparam WORD_SIZE = 32                ; //AST word size in bits

  typedef enum logic [ 2:0 ] {
    IDLE,
    START,
    WAIT_EDGE,
    FIX_BIT,
    WAIT_TIMER,
    END
  } e_rx_fsm;

  e_rx_fsm next_state_rx   ;
  e_rx_fsm current_state_rx;

  logic                           bit_cnt_en   ;
  logic [$clog2(WORD_SIZE-1)-1:0] bit_cnt      ; //counter of bits
  logic                           bit_cnt_clr  ;
  logic                           wrd_cnt_en   ;
  logic [$clog2(DATA_SIZE-1)-1:0] wrd_cnt      ; //counter of ast words
  logic                           tmr_cnt_en   ;
  logic [   $clog2(PERIOD-1)-1:0] tmr_cnt      ; //counter of edge timer
  logic [          WORD_SIZE-1:0] ast_wrd      ; //received word
  logic [          WORD_SIZE-1:0] ast_wrd_shift; //shift register
  logic                           ast_wrd_val  ; //flag of AST word receive
  logic                           ast_wrd_val_q;
  logic [                    3:0] edge_reg     ; //register of edge
  logic                           edge_pos     ; //flag of positive edge
  logic                           edge_neg     ; //flag of negative edge
  logic                           edge_clr     ;
  logic                           jitter_det   ; //strobe of jitter on line
  logic                           rst_n        ;
  logic                           finish       ; //strobe of receive ending
  logic                           sync_error   ;

  assign o_src_rx_data = ast_wrd;
  assign o_arinc708_rx_active = !( current_state_rx == IDLE );
  assign o_arinc708_rx_compl_pe = finish;

  //reset generator
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge i_avs_rst_n )
    begin : res_gen
      if ( ~i_avs_rst_n )
        rst_n <= '0;
      else
        rst_n <= i_arinc708_rx_en;
    end

  //jitter detector
  ////////////////////////////////////////////////////////////////////////////
  always_comb
    begin
      if (i_arinc708_rx_A == i_arinc708_rx_B)//lines must be inverse
        jitter_det = 1'b1;
      else
        jitter_det = 1'b0;
    end

  //AST word register
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : word_register
      if ( ~rst_n )
        begin
          o_src_rx_valid <= '0;
          ast_wrd_val_q  <= '0;
          ast_wrd        <= '0;
        end
      else
        begin
          ast_wrd_val_q <= ast_wrd_val;
          if ( ast_wrd_val_q )
            begin
              ast_wrd        <= ast_wrd_shift;
              o_src_rx_valid <= 1'h1;
            end
          else if ( i_src_rx_ready )
            begin
              //ast_wrd        <= '0;//normal realization of AST
              o_src_rx_valid <= '0;
            end
        end
    end

  //AST word shift register (big endian)
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : shift_register
      if ( ~rst_n )
        ast_wrd_shift <= '0;
      else
        begin
          if ( current_state_rx == FIX_BIT )
            begin
              if ( edge_pos )
                ast_wrd_shift <= { 1'b0, ast_wrd_shift[WORD_SIZE-1:1] };
              else if ( edge_neg )
                ast_wrd_shift <= { 1'b1, ast_wrd_shift[WORD_SIZE-1:1] };
              else if ( current_state_rx == IDLE )
                ast_wrd_shift <= '0;
            end
        end
    end

  //edge detector
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : edge_detector
      if ( ~rst_n )
        begin
          edge_reg <= '0;
          edge_pos <= '0;
          edge_neg <= '0;
        end
      else
        begin
          edge_reg <= { edge_reg[2:0], i_arinc708_rx_A };
          if ( edge_reg == 4'b0111 )
            edge_pos <= 1'b1;
          else if ( edge_reg == 4'b1000 )
            edge_neg <= 1'b1;
          else if ( edge_clr )
            begin
              edge_pos <= '0;
              edge_neg <= '0;
            end
        end
    end

  //word counter
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : word_counter
      if ( ~rst_n )
        wrd_cnt <= '0;
      else
        begin
          if ( wrd_cnt_en )
            wrd_cnt <= wrd_cnt + 1'b1;
          else if ( current_state_rx == IDLE )
            wrd_cnt <= '0;
        end
    end

  //error register
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : error_register
      if ( ~rst_n )
        o_arinc708_rx_err_pe <= '0;
      else
        begin
          if ( sync_error )
            o_arinc708_rx_err_pe <= 1'b1;
          // else if ( ast_wrd_val )//normal realization of AST
          else if ( o_src_rx_valid )
            o_arinc708_rx_err_pe <= 1'b0;
        end
    end

  //bit counter
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : bit_counter
      if ( ~rst_n )
        bit_cnt <= '0;
      else
        begin
          if ( bit_cnt_en )
            bit_cnt <= bit_cnt + 1'b1;
          else if ( bit_cnt_clr )
            bit_cnt <= '0;
        end
    end

  //timer counter
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : timer_counter
      if ( ~rst_n )
        tmr_cnt <= '0;
      else
        begin
          if ( tmr_cnt_en )
            tmr_cnt <= tmr_cnt + 1'b1;
          else
            tmr_cnt <= '0;
        end
    end

  //FSM for A708 RX
  ////////////////////////////////////////////////////////////////////////////
  always_ff @( posedge i_avs_clk or negedge rst_n )
    begin : FSM_RX
      if ( ~rst_n )
        current_state_rx <= IDLE;
      else
        current_state_rx <= next_state_rx;
    end

  always_comb
    begin
      unique case ( current_state_rx )
        IDLE : //waiting for start edge
          begin
            next_state_rx = IDLE;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            bit_cnt_clr   = 1'b1;
            tmr_cnt_en    = 1'b0;
            ast_wrd_val   = 1'b0;
            edge_clr      = 1'b0;
            finish        = 1'b0;
            sync_error    = 1'b0;
            if ( edge_pos && !jitter_det )
              next_state_rx = START;
          end
        START : //waiting of start bits
          begin
            next_state_rx = START;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            bit_cnt_clr   = 1'b0;
            tmr_cnt_en    = 1'b1;
            ast_wrd_val   = 1'b0;
            edge_clr      = 1'b1;
            finish        = 1'b0;
            sync_error    = 1'b0;
            if ( tmr_cnt == PERIOD - 1 )
              begin
                bit_cnt_en = 1'b1;
                tmr_cnt_en = 1'b0;
              end
            if ( bit_cnt == 3 && tmr_cnt == PERIOD/4 )//wait for edge set
              begin
                next_state_rx = WAIT_EDGE;
                bit_cnt_clr   = 1'b1;
              end
          end
        WAIT_EDGE : //waiting for edge (syncronization)
          begin
            next_state_rx = WAIT_EDGE;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            bit_cnt_clr   = 1'b0;
            tmr_cnt_en    = 1'b1;
            ast_wrd_val   = 1'b0;
            edge_clr      = 1'b0;
            finish        = 1'b0;
            sync_error    = 1'b0;
            if ( (edge_pos || edge_neg) && !jitter_det )
              begin
                next_state_rx = FIX_BIT;
                tmr_cnt_en    = 1'b0;
              end
            else if ( tmr_cnt == PERIOD - 1 )
              begin
                tmr_cnt_en    = 1'b0;
                sync_error    = 1'b1;
                next_state_rx = FIX_BIT;//continue receive despite on error
              end
          end
        FIX_BIT : //decoding of Manchester code (G.E. Thomas)
          begin
            next_state_rx = WAIT_TIMER;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b1;
            bit_cnt_clr   = 1'b0;
            tmr_cnt_en    = 1'b1;
            ast_wrd_val   = 1'b0;
            edge_clr      = 1'b1;
            finish        = 1'b0;
            sync_error    = 1'b0;
            if (bit_cnt == WORD_SIZE-1)
              begin
                wrd_cnt_en  = 1'b1;
                ast_wrd_val = 1'b1;
              end
          end
        WAIT_TIMER : //waiting for next bit
          begin
            next_state_rx = WAIT_TIMER;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            bit_cnt_clr   = 1'b0;
            tmr_cnt_en    = 1'b1;
            ast_wrd_val   = 1'b0;
            edge_clr      = 1'b1;
            finish        = 1'b0;
            sync_error    = 1'b0;
            if ( wrd_cnt == DATA_SIZE && tmr_cnt == PERIOD/2 )//end of last bit
              begin
                next_state_rx = END;
                tmr_cnt_en    = 1'b0;
                bit_cnt_clr   = 1'b1;
              end
            else if ( tmr_cnt == TIMER_CNT - 1 )
              begin
                next_state_rx = WAIT_EDGE;
                tmr_cnt_en    = 1'b0;
              end
          end
        END :
          begin
            next_state_rx = END;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            bit_cnt_clr   = 1'b0;
            tmr_cnt_en    = 1'b1;
            ast_wrd_val   = 1'b0;
            edge_clr      = 1'b1;
            finish        = 1'b0;
            sync_error    = 1'b0;
            if ( tmr_cnt == PERIOD - 1 )
              begin
                bit_cnt_en = 1'b1;
                tmr_cnt_en = 1'b0;
              end
            if ( bit_cnt == 4 )//control of zero on line
              begin
                next_state_rx = IDLE;
                bit_cnt_clr   = 1'b1;
                finish        = 1'b1;
              end
          end
        default :
          begin
            next_state_rx = IDLE;
            wrd_cnt_en    = 1'b0;
            bit_cnt_en    = 1'b0;
            bit_cnt_clr   = 1'b1;
            tmr_cnt_en    = 1'b0;
            ast_wrd_val   = 1'b0;
            edge_clr      = 1'b1;
            finish        = 1'b0;
            sync_error    = 1'b0;
          end
      endcase
    end

endmodule
