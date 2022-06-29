/*
 * Backlight control module
 */

module backlight_control #(
  
  parameter [31:0] BASE_ADDRESS = 32'h00000000,
  parameter        PWM_CHANNELS = 3,
  parameter        PWM_WIDTH    = 12
  
)(
  
  input reset_n,
  input clock,
  
  input       night,
  input       light_manual,
  input [4:0] light_cnt,
  input [4:0] illuminance_avg,
  input [4:0] light_mcu,
  
  input               bklt_waitrequest,
  output logic        bklt_read,
  output logic [31:0] bklt_address,
  input               bklt_readdatavalid,
  input        [31:0] bklt_readdata,
  
  output           [PWM_CHANNELS-1:0] pwm_load,
  output [PWM_CHANNELS*PWM_WIDTH-1:0] pwm_value
  
);
  
  
  
  logic night_meta;
  logic night_latch;
  
  always @( posedge clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      { night_latch, night_meta } <= 2'b00;
      
    end else begin
      
      { night_latch, night_meta } <= { night_meta, night };
      
    end
    
  end
  
  
  
  logic                 bklt_read_minimum;
  logic                 bklt_read_maximum;
  logic                 bklt_load;
  logic                 bklt_transaction;
  logic           [7:0] bklt_page;
  logic           [7:0] bklt_offset;
  logic [PWM_WIDTH-1:0] bklt_minimum[PWM_CHANNELS];
  logic [PWM_WIDTH-1:0] bklt_maximum[PWM_CHANNELS];
  logic [PWM_WIDTH-1:0] bklt_values[2*PWM_CHANNELS];
  logic [PWM_WIDTH-1:0] bklt_illuminance;
  
  assign bklt_offset = ( !bklt_read_minimum )               ? ( ( bklt_page << 5 ) |                          8'h01             ) :
                       ( !bklt_read_maximum )               ? ( ( bklt_page << 5 ) |                          8'h1F             ) :
                       ( bklt_page <       PWM_CHANNELS   ) ? ( ( bklt_page << 5 ) |                          light_cnt         ) :
                       ( bklt_page < ( 2 * PWM_CHANNELS ) ) ? ( ( bklt_page << 5 ) |                          light_mcu         ) :
                                                              ( ( bklt_page << 5 ) | ( light_manual ? 8'h10 : illuminance_avg ) ) ;
  
  enum logic[2:0] {
    BKLT_IDLE  = 3'b001,
    BKLT_READ  = 3'b010,
    BKLT_ACK   = 3'b100,
    BKLT_RESET = 3'b111
  } bklt_state;
  
  integer i;
  
  logic [31:0]timer;
  wire timer_event = timer >= 20_000_000;


  always @( posedge clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      for( i = 0; i < PWM_CHANNELS; i = i + 1 ) begin
        bklt_minimum[i] <= {(PWM_WIDTH){ 1'b0 }};
        bklt_maximum[i] <= {(PWM_WIDTH){ 1'b0 }};
      end
      for( i = 0; i < ( 2 * PWM_CHANNELS ); i = i + 1 )
        bklt_values[i] <= {(PWM_WIDTH){ 1'b0 }};      
      bklt_illuminance   <= {(PWM_WIDTH){ 1'b0 }};
      bklt_read_minimum  <= 1'b0;
      bklt_read_maximum  <= 1'b0;
      bklt_load          <= 1'b0;
      bklt_transaction   <= 1'b0;
      bklt_read          <= 1'b0;
      bklt_address       <= 32'h00000000;
      bklt_page          <= 8'd0;
      bklt_state         <= BKLT_RESET;
      
    end else begin
      if( night_latch != night_meta)begin
        bklt_read_minimum  <= 1'b0;
        bklt_read_maximum  <= 1'b0;
        bklt_state         <= BKLT_IDLE;
      end

      case( bklt_state )
        
        BKLT_IDLE: begin
          bklt_read        <= 1'b0;
          bklt_transaction <= 1'b0;
          bklt_load        <= 1'b0;
          bklt_address     <= 32'h00000000;
          bklt_page        <= 8'd0;

          timer <= (timer_event) ? '0 : (timer + 1) ;
          if(timer_event) bklt_state       <= BKLT_READ;
        end
        
        BKLT_READ: begin
          if( !bklt_waitrequest && bklt_transaction ) begin
            bklt_read    <= 1'b0;
            bklt_address <= 32'h00000000;
            bklt_state   <= BKLT_ACK;
          end else begin
            bklt_read        <= 1'b1;
            bklt_transaction <= 1'b1;
            bklt_address     <= { BASE_ADDRESS[31:9], (!night_latch), bklt_offset };
          end
          bklt_load <= 1'b0;
        end
        
        BKLT_ACK: begin
          if( bklt_readdatavalid ) begin
            if( !bklt_read_minimum ) begin
              if( bklt_page < ( PWM_CHANNELS - 1 ) )
                bklt_state <= BKLT_READ;
              else begin
                bklt_read_minimum <= 1'b1;
                bklt_state        <= BKLT_IDLE;
              end
              bklt_load               <= 1'b0;
              bklt_minimum[bklt_page] <= bklt_readdata[PWM_WIDTH-1:0];
            end else if( !bklt_read_maximum ) begin
              if( bklt_page < ( PWM_CHANNELS - 1 ) )
                bklt_state <= BKLT_READ;
              else begin
                bklt_read_maximum <= 1'b1;
                bklt_state        <= BKLT_IDLE;
              end
              bklt_load               <= 1'b0;
              bklt_maximum[bklt_page] <= bklt_readdata[PWM_WIDTH-1:0];
            end else begin
              if( bklt_page < ( 2 * PWM_CHANNELS ) ) begin
                bklt_load              <= 1'b0;
                bklt_values[bklt_page] <= bklt_readdata[PWM_WIDTH-1:0];
                bklt_state             <= BKLT_READ;
              end else begin
                bklt_load        <= 1'b1;
                bklt_illuminance <= bklt_readdata[PWM_WIDTH-1:0];
                bklt_state       <= BKLT_IDLE;
              end
            end
            bklt_page <= bklt_page + 8'd1;
          end
          bklt_transaction <= 1'b0;
          bklt_read        <= 1'b0;
        end
        
        default: begin
          for( i = 0; i < PWM_CHANNELS; i = i + 1 ) begin
            bklt_minimum[i] <= {(PWM_WIDTH){ 1'b0 }};
            bklt_maximum[i] <= {(PWM_WIDTH){ 1'b0 }};
          end
          for( i = 0; i < ( 2 * PWM_CHANNELS ); i = i + 1 )
            bklt_values[i] <= {(PWM_WIDTH){ 1'b0 }};
          bklt_illuminance   <= {(PWM_WIDTH){ 1'b0 }};
          bklt_read_minimum  <= 1'b0;
          bklt_read_maximum  <= 1'b0;
          bklt_load          <= 1'b0;
          bklt_transaction   <= 1'b0;
          bklt_read          <= 1'b0;
          bklt_address       <= 32'h00000000;
          bklt_page          <= 3'd0;
          bklt_state         <= BKLT_IDLE;
        end
        
      endcase
      
    end
    
  end
  
  
  
  logic           [2:0] bklt_load_shift;
  logic                 reg_pwm_load[PWM_CHANNELS];
  logic [PWM_WIDTH-1:0] reg_pwm_value[PWM_CHANNELS];
  logic [PWM_WIDTH-1:0] bklt_sum_values[PWM_CHANNELS];
  
  integer j;
  
  always @( posedge clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      for( j = 0; j < PWM_CHANNELS; j = j + 1 ) begin
        reg_pwm_load[j]    <= 1'b0;
        bklt_sum_values[j] <= {(PWM_WIDTH){ 1'b0 }};
        reg_pwm_value[j]   <= {(PWM_WIDTH){ 1'b0 }};
      end
      
      bklt_load_shift <= 3'b000;
      
    end else begin
      
      for( j = 0; j < PWM_CHANNELS; j = j + 1 ) begin
        reg_pwm_load[j]    <= ( bklt_load_shift[2] ) ? 1'b1 : 1'b0;
        bklt_sum_values[j] <= ( bklt_values[j] + bklt_values[3+j] + bklt_illuminance );
        reg_pwm_value[j]   <= ( bklt_sum_values[j] > bklt_maximum[j] ) ? bklt_maximum[j]    :
                              ( bklt_sum_values[j] < bklt_minimum[j] ) ? bklt_minimum[j]    :
                                                                         bklt_sum_values[j] ;
      end
      
      bklt_load_shift <= { bklt_load_shift[1:0], bklt_load };
      
    end
    
  end
  
  
  
  genvar k;
  
  generate
    for( k = 0; k < PWM_CHANNELS; k = k + 1 ) begin : gen_pwm_value_load
      assign pwm_load[k]                       = reg_pwm_load[k];
      assign pwm_value[k*PWM_WIDTH+:PWM_WIDTH] = reg_pwm_value[k];
    end
  endgenerate
  
  
  
endmodule : backlight_control
