/*
 *
 */

module sigma_delta #(
  
  parameter CLOCK_PRESCALER = 24,
  parameter DAC_WIDTH       = 12
  
)(
  
  input clock,
  input reset_n,
  
  input                 pwm_load,
  input [DAC_WIDTH-1:0] pwm_value,
  
  output logic pwm_out
  
);
  
  localparam PRESCALER_WIDTH = $clog2( CLOCK_PRESCALER );
  
  
  
  logic                 load_meta;
  logic                 load_latch;
  logic [DAC_WIDTH-1:0] value_meta;
  logic [DAC_WIDTH-1:0] value_latch;
  logic [DAC_WIDTH-1:0] value_latched;
  
  always_ff @( posedge clock or negedge reset_n )
  begin
  	
  	if( !reset_n ) begin
  		
  		load_meta       <= 1'b0;
  		load_latch      <= 1'b0;
  		value_meta      <= {(DAC_WIDTH){ 1'b0 }};
      value_latch     <= {(DAC_WIDTH){ 1'b0 }};
      value_latched   <= {(DAC_WIDTH){ 1'b0 }};
  		
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
  
  
  
  logic [DAC_WIDTH+2:0] delta;
  logic [DAC_WIDTH+2:0] sigma;
  logic [DAC_WIDTH+2:0] sigma_d;
  logic [DAC_WIDTH-1:0] threshold;
  
  assign delta = { sigma_d[DAC_WIDTH+1], sigma_d[DAC_WIDTH+1], {(DAC_WIDTH){ 1'b0 }} };
  assign sigma = ( threshold + delta + sigma_d );
  
  always_ff @( posedge clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      threshold <= {(DAC_WIDTH){ 1'b0 }};
      sigma_d   <= {(DAC_WIDTH+2){ 1'b0 }};
      pwm_out   <= 1'b0;
      
    end else begin
      
      if( prescaled_clock ) begin
        
        if( threshold < value_latched )
          threshold <= threshold + { {(DAC_WIDTH-1){ 1'b0 }}, 1'b1 };
        else if( threshold > value_latched )
          threshold <= threshold - { {(DAC_WIDTH-1){ 1'b0 }}, 1'b1 };
        
        sigma_d <= sigma;
        
        pwm_out <= sigma_d[DAC_WIDTH+1];
        
      end
      
    end
    
  end
  
  
  
endmodule : sigma_delta
