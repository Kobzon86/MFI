/*
 * Power-on reset module
 */

module por #(
  
  parameter FAMILY = "Cyclone V"
  
)(
  
  input  reset_n,
  
  output clock,
  output half_clock,
  output quarter_clock,
  
  output out_reset_req,
  output out_reset_n
);
  
  
  
  logic       clock_reg         /* synthesis keep */;
  logic       half_clock_reg    /* synthesis keep */;
  logic       quarter_clock_reg /* synthesis keep */;
  logic       reset_req_reg     /* synthesis keep */;
  logic [1:0] reset_n_reg       /* synthesis keep */;
  
  assign clock            = clock_reg;
  assign half_clock       = half_clock_reg;
  assign quarter_clock    = quarter_clock_reg;
  assign out_reset_req    = reset_req_reg;
  assign out_reset_n      = reset_n_reg[1];
  
  
  
  generate
    
    if( FAMILY == "Cyclone V" ) begin
      
      initial
      begin
        $display( "POR: Devioce FAMILY is Cyclone V" );
        $display( "POR: Internal oscillator frequency is about 80 MHz" );
      end
      
      logic cyclone_v_clock /* synthesis keep */;
      
      cyclonev_oscillator cyclonev_oscillator_i (
        .oscena ( reset_n         ),
        .clkout ( cyclone_v_clock )
      );
      
      assign clock_reg = cyclone_v_clock;
      
    end else begin
      
      initial
      begin
        $display( "POR: Unknown device FAMILY" );
        $display( "POR: Using ring oscillator on LEs" );
      end
      
      genvar i;
      
      localparam delay_chain = 8;
      
      logic                   ring_osc_clock  /* synthesis keep */;
      logic [delay_chain-1:0] clock_reg_delay /* synthesis keep */;
      
      for( i = 0; i < ( delay_chain - 1 ); i = i + 1 ) begin : clock_delay_gen
        assign clock_reg_delay[i] = ~clock_reg_delay[i+1];
      end
      
      assign clock_reg_delay[delay_chain-1] = clock_reg_delay[0] & reset_n;
      assign ring_osc_clock                 = clock_reg_delay[0] & reset_n;
      assign clock_reg                      = ring_osc_clock;
      
    end
    
  endgenerate
  
  
  
  logic [1:0] half_clock_shift;
  logic [7:0] half_clock_timer;
  logic       half_clock_locked;
  
  always @( posedge clock_reg or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      half_clock_reg    <= 1'b0;
      half_clock_shift  <= 2'b00;
      half_clock_timer  <= 8'd0;
      half_clock_locked <= 1'b0;
      
    end else begin
      
      if( half_clock_shift[0] ^ half_clock_shift[1] ) begin
        if( half_clock_timer < 8'd255 ) begin
          half_clock_locked <= 1'b0;
          half_clock_timer  <= half_clock_timer + 8'd1;
        end else
          half_clock_locked <= 1'b1;
      end else begin
        half_clock_timer  <= 8'd0;
        half_clock_locked <= 1'b0;
      end
      
      half_clock_shift <= { half_clock_shift[0], half_clock_reg };
      half_clock_reg   <= ( half_clock_reg === 1'b1 ) ? 1'b0 : 1'b1;
      
    end
    
  end
  
  
  
  logic [1:0] quarter_clock_shift;
  logic [7:0] quarter_clock_timer;
  logic       quarter_clock_locked;
  
  always @( posedge half_clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      quarter_clock_reg    <= 1'b0;
      quarter_clock_shift  <= 2'b00;
      quarter_clock_timer  <= 8'd0;
      quarter_clock_locked <= 1'b0;
      
    end else begin
      
      if( quarter_clock_shift[0] ^ quarter_clock_shift[1] ) begin
        if( quarter_clock_timer < 8'd255 ) begin
          quarter_clock_locked <= 1'b0;
          quarter_clock_timer  <= quarter_clock_timer + 8'd1;
        end else
          quarter_clock_locked <= 1'b1;
      end else begin
        quarter_clock_timer  <= 8'd0;
        quarter_clock_locked <= 1'b0;
      end
      
      quarter_clock_shift <= { quarter_clock_shift[0], quarter_clock_reg };
      quarter_clock_reg   <= ( quarter_clock_reg === 1'b1 ) ? 1'b0 : 1'b1;
      
    end
    
  end
  
  
  
  logic                      half_clock_locked_meta;
  logic                      half_clock_locked_latch;
  logic                      quarter_clock_locked_meta;
  logic                      quarter_clock_locked_latch;
  
  always @( posedge clock_reg or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      reset_req_reg <= 1'b0;
      reset_n_reg   <= 2'b00;
      
      { half_clock_locked_latch,    half_clock_locked_meta    } <= 2'b00;
      { quarter_clock_locked_latch, quarter_clock_locked_meta } <= 2'b00;
      
    end else begin
      
      reset_req_reg <= reset_n_reg[1] ^ reset_n_reg[0];
      reset_n_reg   <= { reset_n_reg[0], ( half_clock_locked_latch & quarter_clock_locked_latch ) };
      
      { half_clock_locked_latch,    half_clock_locked_meta    } <= { half_clock_locked_meta,    half_clock_locked    };
      { quarter_clock_locked_latch, quarter_clock_locked_meta } <= { quarter_clock_locked_meta, quarter_clock_locked };
      
    end
    
  end
  
  
  
endmodule
