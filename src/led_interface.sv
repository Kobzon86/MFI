/*
 * LED interface for indicate error codes
 */

module led_interface #(
  
  parameter clock_freq      = 50_000_000,
  parameter blink_period_ms = 100,
  parameter pause_before_ms = 1_000,
  parameter pause_after_ms  = 1_000,
  parameter bits_count      = 8
  
)(
  
  input                   reset_n,
  input                   clk,
  input  [bits_count-1:0] parallel_code,
  output                  serial_code
  
);
  
  localparam pause_before = pause_before_ms * ( clock_freq / 1000 );
  localparam pause_after  = pause_after_ms  * ( clock_freq / 1000 );
  localparam blink_period = blink_period_ms * ( clock_freq / 1000 );
  
  
  
  reg  [bits_count-1:0] code_meta;
  reg  [bits_count-1:0] code_latch;
  reg  [bits_count-1:0] current_code;
  reg             [2:0] state_counter;
  reg             [7:0] bit_counter;
  reg            [31:0] before_timer;
  reg            [31:0] after_timer;
  reg            [31:0] blink_timer;
  reg                   serial_code_reg;
  
  assign serial_code = serial_code_reg;
  
  always @( posedge clk or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      code_meta       <= 0;
      code_latch      <= 0;
      current_code    <= 0;
      before_timer    <= 0;
      after_timer     <= 0;
      blink_timer     <= 0;
      state_counter   <= 0;
      bit_counter     <= bits_count - 1'b1;
      serial_code_reg <= 0;
      
    end else begin
      
      if( ( pause_before > 0 ) && ( before_timer < pause_before - 1 ) ) begin
        
        before_timer <= before_timer + 1'b1;
        
      end else if( ( bit_counter > 0 ) || ( state_counter < 7 ) ) begin
        
        if( blink_timer < blink_period - 1 ) begin
          blink_timer <= blink_timer + 1;
        end else begin
          if( state_counter < 7 ) begin
            state_counter <= state_counter + 1'b1;
          end else begin
            state_counter <= 0;
            bit_counter   <= bit_counter - 1'b1;
          end
          blink_timer <= 0;
        end
        
      end else if( ( pause_after > 0 ) && ( after_timer < pause_after - 1 ) ) begin
        
        after_timer <= after_timer + 1;
        
      end else begin
        
        before_timer  <= 0;
        after_timer   <= 0;
        state_counter <= 0;
        bit_counter   <= bits_count - 1'b1;
        current_code  <= code_latch;
        
      end
      
      case( state_counter )
      /*
            4: serial_code_reg <= current_code[bit_counter];
      */
      3, 4, 5: serial_code_reg <= current_code[bit_counter];
            2: serial_code_reg <= 1;
      default: serial_code_reg <= 0;
      endcase
      
      { code_latch, code_meta } <= { code_meta, parallel_code };
      
    end
    
  end
  
  
  
endmodule
