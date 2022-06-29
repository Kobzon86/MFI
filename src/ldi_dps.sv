/*
 * LVDS Display Interface dynamic phase shift.
 */

module ldi_dps #(
  
  parameter family              = "External",  // "Cyclone IV", "Cyclone V", "External",
  
  parameter clock_freq          = 100_000_000,
  
  parameter hsync_min_period_us = 8,
  parameter hsync_max_period_us = 64,
  
  parameter vsync_min_period_us = 8000,
  parameter vsync_max_period_us = 64000,
  
  parameter de_min_length_us    = 8,
  parameter de_max_length_us    = 64,
  
  parameter locked_timeout_us   = 16000,
  
  parameter post_steps_fast     = 8'd1,
  parameter post_steps_slow     = 8'd2
  
)(
  
  input        reset_n,
  input        clk,
  
  input        pll_locked,
  
  input        hsync,
  input        vsync,
  input        de,
  
  output       dps_reset,
  output       dps_step,
  output       dps_dir,
  output [4:0] dps_cntsel,
  input        dps_done,
  output       dps_locked
  
);
  
  localparam clock_period_us  = clock_freq / 1_000_000;
  
  localparam hsync_min_period = hsync_min_period_us * clock_period_us;
  localparam hsync_max_period = hsync_max_period_us * clock_period_us;
  
  localparam vsync_min_period = vsync_min_period_us * clock_period_us;
  localparam vsync_max_period = vsync_max_period_us * clock_period_us;
  
  localparam de_min_length    = de_min_length_us * clock_period_us;
  localparam de_max_length    = de_max_length_us * clock_period_us;
  
  localparam locked_timeout   = locked_timeout_us * clock_period_us;
  
  localparam max_steps_fast   = 8;
  localparam max_steps_slow   = 56;
  
  
  
  logic [4:0] cntsel_fast;
  logic [4:0] cntsel_slow;
  
  generate
    if( family == "Cyclone V" ) begin
      assign cntsel_fast = 5'b00000;
      assign cntsel_slow = 5'b00001;
    end else if( family == "Cyclone IV" ) begin
      assign cntsel_fast = 5'b00010;
      assign cntsel_slow = 5'b00011;
    end else begin
      assign cntsel_fast = 5'b00000;
      assign cntsel_slow = 5'b00000;
    end
  endgenerate
  
  
  
  logic [1:0] locked_latch;
  logic [2:0] hsync_latch;
  logic [2:0] vsync_latch;
  logic [2:0] de_latch;
  
  always @( posedge clk or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      locked_latch <= 2'b00;
      hsync_latch  <= 3'b000;
      vsync_latch  <= 3'b000;
      de_latch     <= 3'b000;
      
    end else begin
      
      locked_latch <= { locked_latch[0],  pll_locked };
      hsync_latch  <= { hsync_latch[1:0], hsync      };
      vsync_latch  <= { vsync_latch[1:0], vsync      };
      de_latch     <= { de_latch[1:0],    de         };
      
    end
    
  end
  
  
  
  logic [15:0] hsync_period;
  logic        hsync_locked;
  
  logic [23:0] vsync_period;
  logic        vsync_locked;
  
  logic [15:0] de_length;
  logic        de_locked;
  
  always @( posedge clk or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      hsync_period <= 16'd0;
      hsync_locked <= 1'b0;
      
      vsync_period <= 24'd0;
      vsync_locked <= 1'b0;
      
      de_length    <= 16'd0;
      de_locked    <= 1'b0;
      
    end else begin
      
      if( hsync_latch[2:1] == 2'b01 ) begin
        
        if( ( hsync_period >= hsync_min_period ) && ( hsync_period < hsync_max_period ) && ( hsync_period > de_length ) )
          hsync_locked <= 1'b1;
        else
          hsync_locked <= 1'b0;
        
        hsync_period <= 16'd0;
        
      end else begin
        
        if( hsync_period < hsync_max_period )
          hsync_period <= hsync_period + 16'd1;
        
      end
      
      if( vsync_latch[2:1] == 2'b01 ) begin
        
        if( ( vsync_period >= vsync_min_period ) && ( vsync_period < vsync_max_period ) )
          vsync_locked <= 1'b1;
        else
          vsync_locked <= 1'b0;
        
        vsync_period <= 16'd0;
        
      end else begin
        
        if( vsync_period < vsync_max_period )
          vsync_period <= vsync_period + 16'd1;
        
      end
      
      if( de_latch[2:1] == 2'b10 ) begin
        
        if( ( de_length >= de_min_length ) && ( de_length < de_max_length ) )
          de_locked <= 1'b1;
        else
          de_locked <= 1'b0;
        
      end else if( de_latch[1] == 1'b1 ) begin
        
        if( de_length < de_max_length )
          de_length <= de_length + 16'd1;
        
      end else begin
        
        de_length <= 16'd0;
        
      end
      
    end
    
  end
  
  
  
  logic phase_done_neg_meta;
  logic phase_done_neg_latch;
  
  always @( negedge clk or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      { phase_done_neg_latch, phase_done_neg_meta } <= 2'b00;
      
    end else begin
      
      { phase_done_neg_latch, phase_done_neg_meta } <= { phase_done_neg_meta, dps_done };
      
    end
    
  end
  
  
  
  logic phase_done_meta;
  logic phase_done_latch;
  
  always @( posedge clk or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      { phase_done_latch, phase_done_meta } <= 2'b00;
      
    end else begin
      
      { phase_done_latch, phase_done_meta } <= { phase_done_meta, phase_done_neg_latch };
      
    end
    
  end
  
  
  
  localparam state_idle  = 4'b0001;
  localparam state_step  = 4'b0010;
  localparam state_ack   = 4'b0100;
  localparam state_wait  = 4'b1000;
  localparam state_reset = 4'b1111;
  
  logic        phase_locked;
  logic        phase_reset;
  logic        phase_en;
  logic        phase_updn;
  logic  [4:0] phase_cntsel;
  logic  [7:0] phase_steps_fast;
  logic  [7:0] phase_steps_slow;
  logic  [7:0] phase_post_fast;
  logic  [7:0] phase_post_slow;
  logic [31:0] phase_timer;
  logic  [3:0] phase_state;
  
  always @( posedge clk or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      phase_locked     <= 1'b0;
      phase_reset      <= 1'b1;
      phase_en         <= 1'b0;
      phase_updn       <= 1'b0;
      phase_cntsel     <= 5'b00000;
      phase_steps_fast <= 8'd0;
      phase_steps_slow <= 8'd0;
      phase_post_fast  <= 8'd0;
      phase_post_slow  <= 8'd0;
      phase_timer      <= 32'd0;
      phase_state      <= state_reset;
      
    end else begin
      
      case( phase_state )
      
      state_idle: begin
        if( locked_latch[1] ) begin
          if( ( hsync_locked == 1'b1 ) && ( vsync_locked == 1'b1 ) && ( de_locked == 1'b1 ) ) begin
            if( phase_post_fast > 8'd0 ) begin
              if( post_steps_fast[7] ) begin
                phase_updn      <= 1'b0;
                phase_cntsel    <= cntsel_fast;
                phase_post_fast <= phase_post_fast + 8'd1;
                phase_state     <= state_step;
              end else begin
                phase_updn      <= 1'b1;
                phase_cntsel    <= cntsel_fast;
                phase_post_fast <= phase_post_fast - 8'd1;
                phase_state     <= state_step;
              end
            end else if( phase_post_slow > 8'd0 ) begin
              if( post_steps_slow[7] ) begin
                phase_updn      <= 1'b0;
                phase_cntsel    <= cntsel_slow;
                phase_post_slow <= phase_post_slow + 8'd1;
                phase_state     <= state_step;
              end else begin
                phase_updn      <= 1'b1;
                phase_cntsel    <= cntsel_slow;
                phase_post_slow <= phase_post_slow - 8'd1;
                phase_state     <= state_step;
              end
            end
          end else begin
            if( phase_steps_fast < ( max_steps_fast - 1 ) ) begin
              phase_updn       <= 1'b1;
              phase_cntsel     <= cntsel_fast;
              phase_steps_fast <= phase_steps_fast + 8'd1;
              phase_state      <= state_step;
            end else if( phase_steps_slow < ( max_steps_slow - 1 ) ) begin
              phase_updn       <= 1'b1;
              phase_cntsel     <= cntsel_slow;
              phase_steps_fast <= 8'd0;
              phase_steps_slow <= phase_steps_slow + 8'd1;
              phase_state      <= state_step;
            end else begin
              phase_updn       <= 1'b0;
              phase_cntsel     <= 5'b00000;
              phase_steps_fast <= 8'd0;
              phase_steps_slow <= 8'd0;
              phase_state      <= state_reset;
            end
            phase_post_fast <= post_steps_fast;
            phase_post_slow <= post_steps_slow;
          end
        end else begin
          phase_updn   <= 1'b0;
          phase_cntsel <= 5'b00000;
        end
        phase_locked <= 1'b1;
        phase_reset  <= 1'b0;
        phase_en     <= 1'b0;
      end
      
      state_step: begin
        if( phase_done_latch == 1'b0 ) begin
          phase_timer <= 32'd0;
          phase_state <= state_ack;
        end else if( phase_timer < ( locked_timeout - 1 ) ) begin
          phase_timer <= phase_timer + 32'd1;
        end else begin
          phase_timer <= 32'd0;
          phase_state <= state_reset;
        end
        phase_locked <= 1'b0;
        phase_reset  <= 1'b0;
        phase_en     <= 1'b1;
      end
      
      state_ack: begin
        if( phase_done_latch == 1'b1 ) begin
          phase_timer <= 32'd0;
          phase_state <= state_wait;
        end else if( phase_timer < ( locked_timeout - 1 ) ) begin
          phase_timer <= phase_timer + 32'd1;
        end else begin
          phase_timer <= 32'd0;
          phase_state <= state_reset;
        end
        phase_locked <= 1'b0;
        phase_reset  <= 1'b0;
        phase_en     <= 1'b0;
      end
      
      state_wait: begin
        if( phase_timer < ( locked_timeout - 1 ) ) begin
          phase_timer <= phase_timer + 32'd1;
        end else begin
          phase_timer <= 32'd0;
          phase_state <= state_idle;
        end
      end
      
      default: begin
        phase_locked     <= 1'b0;
        phase_reset      <= 1'b1;
        phase_en         <= 1'b0;
        phase_updn       <= 1'b0;
        phase_steps_fast <= 8'd0;
        phase_steps_slow <= 8'd0;
        phase_timer      <= 32'd0;
        phase_state      <= state_idle;
      end
      
      endcase
      
    end
    
  end
  
  
  
  assign dps_reset  = phase_reset;
  assign dps_step   = phase_en;
  assign dps_dir    = phase_updn;
  assign dps_cntsel = phase_cntsel;
  assign dps_locked = phase_locked;
  
  
  
endmodule
