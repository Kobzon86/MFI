module avalon_pwm #(
	parameter CLK_PRESCALER_WIDTH = 16, // Prescaler (frequency divider) counter width
	parameter PWM_COUNTER_WIDTH   = 8 , // PWM counter width (duty cycle resolution)
	parameter PWM_OUTPUTS_COUNT   = 4 , // Number of PWM output pins
	parameter PRELOAD_REGS        = 0 , // Use preload registers for duty cycle values
	parameter CONSTANT_MAX        = 0 , // Output constant high level at 100% duty cycle
	parameter PULSE_DITHER        = 0   // Dither the PWM pulse (increases frequency above PWM period)
) (
	input                                clk       ,
	input                                reset_n   ,
	input                                chipselect,
	input        [                  5:0] address   ,
	input                                write     ,
	input        [                 31:0] writedata ,
	input                                read      ,
	output logic [                 31:0] readdata  ,
	output logic                         irq       ,
	output logic [PWM_OUTPUTS_COUNT-1:0] pwm_out
);

	logic [CLK_PRESCALER_WIDTH-1:0] fdiv_reg                       ; // Prescaler
	logic [CLK_PRESCALER_WIDTH-1:0] fdiv_cnt                       ;
	logic [  PWM_COUNTER_WIDTH-1:0] duty_reg[PWM_OUTPUTS_COUNT-1:0]; // Duty cycle registers
	logic [  PWM_COUNTER_WIDTH-1:0] duty_val[PWM_OUTPUTS_COUNT-1:0]; // Duty cycle values (registers in case of preload)
	logic [    PWM_COUNTER_WIDTH:0] pwm_cnt                        ; // PWM cycle counter (extra bit remembers the direction on a triangle)
	logic [  PWM_OUTPUTS_COUNT-1:0] pol_reg                        ; // Polarity bits
	logic [                    3:0] ctrl_reg                       ; // Control register
	logic [  PWM_COUNTER_WIDTH-1:0] pwm_val                        ; // counter value following a triangle
	logic fdiv_rd, pol_rd, ctrl_rd, duty_rd[PWM_OUTPUTS_COUNT-1:0];
	logic fdiv_wr, pol_wr, ctrl_wr, duty_wr[PWM_OUTPUTS_COUNT-1:0];

	integer i;


	// Address mux
	always_comb
		begin
			fdiv_wr = chipselect & write & (address == 6'd0 );   // address 0 : prescaler (Fpwm = Fclk/(prescaler+1))
			fdiv_rd = chipselect & read  & (address == 6'd0 );
			pol_wr  = chipselect & write & (address == 6'd1 );    // address 1 : polarity bits per PWM channel
			pol_rd  = chipselect & read  & (address == 6'd1 );
			ctrl_wr = chipselect & write & (address == 6'd2 );   // address 2 : control (1 = OUT_ENA, 2 = CNT_ENA, 4 = IRQL_ENA, 8 = IRQH_ENA)
			ctrl_rd = chipselect & read  & (address == 6'd2 );
			for(i = 0; i < PWM_OUTPUTS_COUNT; i = i + 1)
				begin
					duty_wr[i] = chipselect & write & address[5] & ((address[4:0] == i) ? 1'd1 : 1'd0);  // addresses 32..64 : duty_reg
					duty_rd[i] = chipselect & read  & address[5] & (address[4:0] == i);
				end
		end

	// Avalon registers write
	always_ff @(posedge clk or negedge reset_n)
		begin
			if (reset_n == 0)
				begin
					fdiv_reg <= 0;
					pol_reg  <= 0;
					ctrl_reg <= 4'b0011; // Default state: PWM active, no IRQs
					for(i = 0; i < PWM_OUTPUTS_COUNT; i = i + 1)
						duty_reg[i] <= 0;
				end
			else
				begin
					if (fdiv_wr) fdiv_reg <= writedata[CLK_PRESCALER_WIDTH-1:0];
					if (pol_wr)  pol_reg  <= writedata[PWM_OUTPUTS_COUNT-1:0];
					if (ctrl_wr) ctrl_reg <= writedata[3:0];
					for(i = 0; i < PWM_OUTPUTS_COUNT; i = i + 1)
						if (duty_wr[i]) duty_reg[i] <= writedata[PWM_COUNTER_WIDTH-1:0];
				end
		end

	// Avalon registers read
	always_comb
		begin
			readdata = 0; //32'd0;  // Default value
			if (fdiv_rd) readdata = {{(32-CLK_PRESCALER_WIDTH) {1'd0}}, fdiv_reg};
			if (pol_rd)  readdata = {{(32-PWM_OUTPUTS_COUNT) {1'd0}}, pol_reg};
			if (ctrl_rd) readdata = {28'd0, ctrl_reg};
			for(i = 0; i < PWM_OUTPUTS_COUNT; i = i + 1)
				if (duty_rd[i]) readdata = {{(32-PWM_COUNTER_WIDTH) {1'd0}}, duty_reg[i]};
		end

	// Counters
	always_ff @(posedge clk or negedge reset_n)
		begin
			if (reset_n == 0)
				begin
					fdiv_cnt <= 0;
					pwm_cnt  <= 0;
				end
			else
				begin
					if (fdiv_cnt == fdiv_reg)
						begin
							fdiv_cnt <= 0;
							pwm_cnt  <= pwm_cnt + 1;
							if (pwm_cnt[PWM_COUNTER_WIDTH-1:0] == 0)
								irq <= ((pwm_cnt[PWM_COUNTER_WIDTH] == 0) & ctrl_reg[2]) | ((pwm_cnt[PWM_COUNTER_WIDTH] == 1) & ctrl_reg[3]);
						end
					else
						if(ctrl_reg[1])
							fdiv_cnt <= fdiv_cnt + 1;
				end

		end

	// Preload registers
	always_ff @(posedge clk or negedge reset_n)
		begin
			if (PRELOAD_REGS == 1)
				begin
					if (reset_n == 0)
						for(i = 0; i < PWM_OUTPUTS_COUNT; i = i + 1)
							duty_val[i] <= 0;
					else
						if ((fdiv_cnt == fdiv_reg) & (pwm_cnt[PWM_COUNTER_WIDTH-1:0] == 0))
							for(i = 0; i < PWM_OUTPUTS_COUNT; i = i + 1)
								duty_val[i] <= duty_reg[i];
				end
		end

	// No preload registers
	always_comb
		if (PRELOAD_REGS == 0)
			for(i = 0; i < PWM_OUTPUTS_COUNT; i = i + 1) duty_val[i] = duty_reg[i];

	// Cycle counter type selection
	always_comb
		if (PULSE_DITHER == 1)
			for(i = 0; i < PWM_COUNTER_WIDTH; i = i + 1) pwm_val[i] <= pwm_cnt[PWM_COUNTER_WIDTH-i-1]; // Dithered counter
		else
			pwm_val = pwm_cnt[PWM_COUNTER_WIDTH-1:0] ^ {(PWM_COUNTER_WIDTH) {pwm_cnt[PWM_COUNTER_WIDTH]}}; // Triangle counter

	// PWM outputs
	always_ff @(posedge clk or negedge reset_n)
		begin
			for(i = 0; i < PWM_OUTPUTS_COUNT; i = i + 1)
				begin
					if (reset_n == 0) pwm_out[i] <= 0;
					else if (ctrl_reg[0] == 0) pwm_out[i] <= 0;
					else if (pwm_val < duty_val[i]) pwm_out[i] <= !pol_reg[i];
					else if (pwm_val > duty_val[i]) pwm_out[i] <= pol_reg[i]; // Save output for 1 cycle for a constant level at 0% and 100% duty cycle
					else if (CONSTANT_MAX == 0)     pwm_out[i] <= pol_reg[i]; // Or set the output to zero if constant output not required
				end
		end


endmodule