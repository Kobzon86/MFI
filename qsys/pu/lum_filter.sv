/*
 * 
 */

module lum_filter #(
  
  parameter        WIDTH   = 5,
  parameter [15:0] COEFF_X = 1,
  parameter [15:0] COEFF_Y = 65535
  
)(
  
  input              clock,
  input              reset_n,
  
  input  [WIDTH-1:0] value_i,
  output [WIDTH-1:0] value_o
  
);
  
  
  
  logic [WIDTH+32:0] mul_x;
  logic [WIDTH+32:0] mul_y;
  logic [WIDTH+32:0] add_xy;
  
  assign value_o = add_xy[WIDTH+31:32];
  
  lpm_mult #(
    .lpm_hint           ( "INPUT_B_IS_CONSTANT=YES,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=5" ),
    .lpm_pipeline       ( 1                                                                             ),
    .lpm_representation ( "UNSIGNED"                                                                    ),
    .lpm_type           ( "LPM_MULT"                                                                    ),
    .lpm_widtha         ( WIDTH + 16                                                                    ),
    .lpm_widthb         ( 16                                                                            ),
    .lpm_widthp         ( WIDTH + 32                                                                    )
  ) lpm_mult_x_i (
    .clock  ( clock                 ),
    .clken  ( reset_n               ),
    .aclr   ( 1'b0                  ),
    .sclr   ( 1'b0                  ),
    .sum    ( 1'b0                  ),
    .dataa  ( { value_i, 16'h0000 } ),
    .datab  ( COEFF_X               ),
    .result ( mul_x                 )
  );
  
  lpm_mult #(
    .lpm_hint           ( "INPUT_B_IS_CONSTANT=YES,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=5" ),
    .lpm_pipeline       ( 1                                                                             ),
    .lpm_representation ( "UNSIGNED"                                                                    ),
    .lpm_type           ( "LPM_MULT"                                                                    ),
    .lpm_widtha         ( WIDTH + 16                                                                    ),
    .lpm_widthb         ( 16                                                                            ),
    .lpm_widthp         ( WIDTH + 32                                                                    )
  ) lpm_mult_y_i (
    .clock  ( clock               ),
    .clken  ( reset_n             ),
    .aclr   ( 1'b0                ),
    .sclr   ( 1'b0                ),
    .sum    ( 1'b0                ),
    .dataa  ( add_xy[WIDTH+32:16] ),
    .datab  ( COEFF_Y             ),
    .result ( mul_y               )
  );
  
  lpm_add_sub #(
    .lpm_direction      ( "ADD"                                  ),
    .lpm_hint           ( "ONE_INPUT_IS_CONSTANT=NO,CIN_USED=NO" ),
    .lpm_pipeline       ( 1                                      ),
    .lpm_representation ( "UNSIGNED"                             ),
    .lpm_type           ( "LPM_ADD_SUB"                          ),
    .lpm_width          ( WIDTH + 32                             )
  ) lpm_add_sub_i (
    .clock  ( clock  ),
    .dataa  ( mul_x  ),
    .datab  ( mul_y  ),
    .result ( add_xy )
  );
  
  
  
endmodule : lum_filter
