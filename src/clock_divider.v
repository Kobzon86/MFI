/*
 * Sigma-delta clock divider
 */

module clock_divider #(
  
  parameter input_frequency  = 100_000_000,
  parameter output_frequency = 16_000_000
  
)(
  
  input  reset_n,
  input  clk,
  
  output output_clk
  
);

localparam divider     = ( output_frequency * 2 );
localparam half_period = ( input_frequency / divider );
localparam delta       = ( input_frequency % divider );



reg reset_n_meta;
reg reset_n_latch;

always @( posedge clk or negedge reset_n ) begin
  
  if( reset_n == 1'b0 ) begin
    
	 { reset_n_meta, reset_n_latch } <= 2'b00;
	 
  end else begin
    
	 { reset_n_meta, reset_n_latch } <= { reset_n_latch, 1'b1 };
	 
  end
  
end



reg [31:0] clock_timer;
reg [31:0] clock_sigma;
reg        clock_output;

always @( posedge clk or negedge reset_n_latch ) begin
  
  if( reset_n_latch == 1'b0 ) begin
    
    clock_timer  <= 32'd0;
    clock_sigma  <= 32'd0;
    clock_output <= 1'b0;
    
  end else begin
    
    if( clock_timer < ( half_period - 1 ) ) begin
      
      clock_timer <= clock_timer + 1;
      
    end else if( clock_sigma < ( divider - 1 ) ) begin
      
      clock_timer  <= 0;
      clock_sigma  <= ( clock_sigma + delta );
      clock_output <= ~clock_output;
      
    end else begin
      
      clock_sigma <= ( clock_sigma - divider );
      
    end
    
  end
  
end



cyclonev_clkena #(
  .clock_type        ( "Auto"            ),
  .ena_register_mode ( "always enabled"  ),
  .lpm_type          ( "cyclonev_clkena" )
) sd1 (
  .ena               ( 1'b1              ),
  .enaout            (                   ),
  .inclk             ( clock_output      ),
  .outclk            ( output_clk        )
);



endmodule
