/*
 * 
 */

module lum_conv (
  
  input clock,
  input reset_n,
  
  input [3:0] lum_e,
  input [7:0] lum_m,
  
  output [4:0] lum_out
  
);
  
  
  
  logic [23:0] lum_result;
  
  assign lum_out = ( (lum_e == 4'b1111) || (|lum_result[16:13])  ) ? 5'b11111 : lum_result[12:8];
  
  lpm_mult #(
    .lpm_hint           ( "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=5" ),
    .lpm_pipeline       ( 1                                                     ),
    .lpm_representation ( "UNSIGNED"                                            ),
    .lpm_type           ( "LPM_MULT"                                            ),
    .lpm_widtha         ( 16                                                    ),
    .lpm_widthb         ( 8                                                     ),
    .lpm_widthp         ( 24                                                    )
  ) lpm_mult_i (
    .clock  ( clock                 ),
    .clken  ( reset_n               ),
    .aclr   ( 1'b0                  ),
    .sclr   ( 1'b0                  ),
    .sum    ( 1'b0                  ),
    .dataa  ( ( 16'h0001 << lum_e ) ),
    .datab  ( lum_m                 ),
    .result ( lum_result            )
  );
  
  
  
endmodule : lum_conv
