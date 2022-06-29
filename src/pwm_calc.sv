module pwm_calc #(
	parameter SP_NAME = "NONE"
)(
	input                clk           ,
	input  signed [15:0] pwm_max       ,
	input  signed [15:0] pwm_min       ,
	input  signed [15:0] test_manual   ,
	input  signed [15:0] test_sensors  ,
	input  signed [15:0] test_analogext,
	output signed [15:0] pwm_val
);

	localparam SENS_MAX   = 16'hFFF;
	localparam ANALOG_MAX = 16'h1FF;

	logic signed [19:0] SENS_MAX_VAL;
	logic signed [19:0] EXT_MAX_VAL ;
	logic signed [19:0] SENS_MIN_VAL;
	logic signed [19:0] EXT_MIN_VAL ;
	logic signed [19:0] L_val       ;
	logic signed [19:0] L_sens      ;
	logic signed [19:0] L_ext       ;
	logic signed [19:0] L_val_th    ;
	logic signed [19:0] L_sens_th   ;
	logic signed [19:0] L_ext_th    ;

	logic signed [15:0] pwm_d;

	assign pwm_d = pwm_max - pwm_min; // 800-35=765

	assign SENS_MAX_VAL = signed'( signed'( pwm_d >> 1 ) + pwm_min ); 			// 417
	assign EXT_MAX_VAL  = signed'( signed'( pwm_d >> 1 ) + pwm_min  ) >>> 2;	// 104
	assign SENS_MIN_VAL = signed'( pwm_min - signed'( pwm_d >>> 1 ) );			// -347
	assign EXT_MIN_VAL  = signed'( pwm_min - signed'( pwm_d >>> 1 ) ) >>> 2;	// -87


	logic [16:0] source;

	altsource_probe #(
		.sld_auto_instance_index("YES"  ),
		.sld_instance_index     (0      ),
		.instance_id            (SP_NAME),
		.probe_width            (0      ),
		.source_width           (17     ),
		.source_initial_value   ("0"    ),
		.enable_metastability   ("NO"   )
	) altsource_probe_sel (
		.source    (source),
		.source_ena(1'b1  )
	);



	integer signed L_total, L_total_th;

	always_ff @(posedge clk)
		begin
			L_val  <= ( test_manual - signed'( {1'b0, 1'b1} ) ) * pwm_d / 16'hE + pwm_min; // (4-1)*765/14+35 = 199
			L_sens <= signed'(pwm_min +  signed'( signed'( signed'( ( test_sensors   << 1'b1 ) - SENS_MAX ) * pwm_d ) /  signed'( SENS_MAX << 1 ) ) ); // -346
			L_ext  <= signed'(pwm_min +  signed'( signed'( signed'( ( test_analogext << 1'b1 ) - ANALOG_MAX ) * pwm_d ) /  signed'( ANALOG_MAX << 1 ) ) ); // -348

			L_val_th  <= ( L_val < pwm_min ) ? pwm_min : ( L_val > pwm_max ) ? pwm_max : L_val; // 199
			L_sens_th <= ( L_sens < SENS_MIN_VAL ) ? SENS_MIN_VAL : (L_sens > SENS_MAX_VAL) ? SENS_MAX_VAL : L_sens; // -346
			L_ext_th  <= ( L_ext < EXT_MIN_VAL ) ? EXT_MIN_VAL : (L_ext > EXT_MAX_VAL) ? EXT_MAX_VAL : L_ext; // -87

			L_total    <= L_val_th + L_sens_th + L_ext_th;
			L_total_th <= (L_total < pwm_min) ? pwm_min : (L_total > pwm_max) ? pwm_max : L_total;
		end

	assign pwm_val = ( source[16] == 1'b1 ) ? source[15:0] : L_total_th[15:0];

endmodule