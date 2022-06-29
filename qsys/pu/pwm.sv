/*
 *
 */

module pwm #(
  
  parameter CLOCK_PRESCALER = 24,
  parameter PWM_WIDTH       = 12
  
)(
  
  input clock,
  input reset_n,
  
  input                 pwm_load,
  input [PWM_WIDTH-1:0] pwm_value,
  
  output logic pwm_out
  
);
  
  localparam PRESCALER_WIDTH = $clog2( CLOCK_PRESCALER );
  
  
  
  logic                 load_meta;
  logic                 load_latch;
  logic [PWM_WIDTH-1:0] value_meta;
  logic [PWM_WIDTH-1:0] value_latch;
  logic [PWM_WIDTH-1:0] value_latched;
  
  always_ff @( posedge clock or negedge reset_n )
  begin
  	
  	if( !reset_n ) begin
  		
  		load_meta       <= 1'b0;
  		load_latch      <= 1'b0;
  		value_meta      <= {(PWM_WIDTH){ 1'b0 }};
      value_latch     <= {(PWM_WIDTH){ 1'b0 }};
      value_latched   <= {(PWM_WIDTH){ 1'b0 }};
  		
  	end else begin
  		
      if( load_latch )
        value_latched <= value_latch;
      
      { load_latch,  load_meta  } <= { load_meta,  pwm_load  };
      { value_latch, value_meta } <= { value_meta, pwm_value };
      
  	end
  	
  end
  
  
  
  logic                       prescaled_clock;
  logic [PRESCALER_WIDTH-1:0] prescaler;
  
  always_ff @( posedge clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      prescaler <= {(PRESCALER_WIDTH){ 1'b0 }};
      
    end else begin
      
      if( prescaler < CLOCK_PRESCALER ) begin
        prescaled_clock <= 1'b0;
        prescaler       <= prescaler + { {(PRESCALER_WIDTH-1){ 1'b0 }}, 1'b1 };
      end else begin
        prescaled_clock <= 1'b1;
        prescaler       <= {(PRESCALER_WIDTH){ 1'b0 }};
      end
      
    end
    
  end
  
  
  
  logic [PWM_WIDTH-1:0] pwm_counter;
  logic [PWM_WIDTH-1:0] threshold;
  
  always_ff @( posedge clock or negedge reset_n )
  begin
  	
  	if( !reset_n ) begin
  		
  		pwm_counter <= {(PWM_WIDTH){ 1'b0 }};
      threshold   <= {(PWM_WIDTH){ 1'b0 }};
  		
  	end else begin
  		
  		if( prescaled_clock ) begin
        
        if( threshold < value_latched )
          threshold <= threshold + { {(PWM_WIDTH-1){ 1'b0 }}, 1'b1 };
        else if( threshold > value_latched )
          threshold <= threshold - { {(PWM_WIDTH-1){ 1'b0 }}, 1'b1 };
        
  			pwm_out     <= ( pwm_counter < threshold ) ? 1'b1 : 1'b0;
  			pwm_counter <= pwm_counter + { {(PWM_WIDTH-1){ 1'b0 }}, 1'b1 };
        
  		end
  		
  	end
  	
  end
  
  
  
endmodule : pwm
