/*
 * LVDS Display Interface dynamic phase shift.
 */

module lvds_ldi_dps #(
    parameter hsync_min_period = 16'd512     ,
    parameter hsync_max_period = 16'd65534   ,
    parameter vsync_min_period = 24'd65536   ,
    parameter vsync_max_period = 24'd16777214,
    parameter locked_timeout   = 32'd5000000 ,
    parameter post_steps       = 32'd0
) (
    input  reset_n   ,
    input  clk       ,
    input  freerun   ,
    input  hsync     ,
    input  vsync     ,
    output dps_reset ,
    output dps_step  ,
    output dps_dir   ,
    input  dps_done  ,
    output dps_locked
);

    enum logic[2:0]{
        state_idle ,
        state_step ,
        state_ack  ,
        state_reset
    } phase_state;

    logic       hsync_clk_meta ;
    logic [1:0] hsync_clk_latch;
    logic       vsync_clk_meta ;
    logic [1:0] vsync_clk_latch;

    logic [15:0] hsync_period;
    logic        hsync_locked;
    logic [23:0] vsync_period;
    logic        vsync_locked;

    logic phase_done_meta ;
    logic phase_done_latch;

    logic phase_done_neg_meta ;
    logic phase_done_neg_latch;

    logic phase_locked;
    logic phase_reset ;
    logic phase_en    ;
    logic phase_updn  ;

    logic [  $clog2(locked_timeout):0] phase_post ;
    logic [$clog2(locked_timeout)-1:0] phase_timer;

    assign dps_reset  = phase_reset;
    assign dps_step   = phase_en;
    assign dps_dir    = phase_updn;
    assign dps_locked = phase_locked;

    always_ff @( posedge clk or negedge reset_n ) 
        begin
            if( reset_n == 1'b0 ) 
                begin
                    { hsync_clk_latch, hsync_clk_meta } <= 3'b000;
                    { vsync_clk_latch, vsync_clk_meta } <= 3'b000;
                end 
            else 
                begin
                    { hsync_clk_latch, hsync_clk_meta } <= { hsync_clk_latch[0], hsync_clk_meta, hsync };
                    { vsync_clk_latch, vsync_clk_meta } <= { vsync_clk_latch[0], vsync_clk_meta, vsync };
                end
        end

    always_ff @( posedge clk or negedge reset_n )
        begin
            if( reset_n == 1'b0 )
                begin
                    hsync_period <= 16'd0;
                    hsync_locked <= 1'b0;
                    vsync_period <= 24'd0;
                    vsync_locked <= 1'b0;
                end
            else
                begin
                    if( hsync_period > hsync_max_period )
                        begin
                            hsync_period <= 16'd0;
                            hsync_locked <= 1'b0;
                        end
                    else
                        begin
                            if( hsync_clk_latch == 2'b01 )
                                begin
                                    if( ( hsync_period >= hsync_min_period ) && ( hsync_period < hsync_max_period ) )
                                        hsync_locked <= 1'b1;
                                    else
                                        hsync_locked <= 1'b0;
                                    hsync_period <= 16'd0;
                                end
                            else
                                hsync_period <= hsync_period + 16'd1;
                        end
                    if( vsync_period > vsync_max_period )
                        begin
                            vsync_period <= 24'd0;
                            vsync_locked <= 1'b0;
                        end
                    else
                        begin
                            if( vsync_clk_latch == 2'b01 )
                                begin
                                    if( ( vsync_period >= vsync_min_period ) && ( vsync_period < vsync_max_period ) )
                                        vsync_locked <= 1'b1;
                                    else
                                        vsync_locked <= 1'b0;
                                    vsync_period <= 24'd0;
                                end
                            else
                                vsync_period <= vsync_period + 24'd1;
                        end
                end
        end

    always_ff @( negedge clk or negedge reset_n )
        begin
            if( reset_n == 1'b0 )
                { phase_done_neg_latch, phase_done_neg_meta } <= 2'b00;
            else
                { phase_done_neg_latch, phase_done_neg_meta } <= { phase_done_neg_meta, dps_done };
        end

    always_ff @( posedge clk or negedge reset_n )
        begin
            if( reset_n == 1'b0 )
                { phase_done_latch, phase_done_meta } <= 2'b00;
            else
                { phase_done_latch, phase_done_meta } <= { phase_done_meta, phase_done_neg_latch };
        end

    always_ff @( posedge freerun or negedge reset_n )
        begin
            if( reset_n == 1'b0 )
                begin
                    phase_locked <= '0;
                    phase_reset  <= '0;
                    phase_en     <= '0;
                    phase_updn   <= '0;
                    phase_post   <= '0;
                    phase_timer  <= '0;
                    phase_state  <= state_reset;
                end
            else
                begin
                    case( phase_state )
                        state_idle :
                            begin
                                if( ( hsync_locked == 1'b1 ) && ( vsync_locked == 1'b1 ) )
                                    begin
                                        if( phase_post > 32'd0 )
                                            begin
                                                phase_locked <= '0;
                                                phase_updn   <= '1;
                                                phase_post   <= phase_post - 1'b1;
                                                phase_state  <= state_step;
                                            end
                                        else
                                            begin
                                                if( phase_post < 0 )
                                                    begin
                                                        phase_locked <= '0;
                                                        phase_updn   <= '0;
                                                        phase_post   <= phase_post + 1'b1;
                                                        phase_state  <= state_step;
                                                    end
                                                else
                                                    begin
                                                        phase_locked <= 1'b1;
                                                        phase_updn   <= '0;
                                                        phase_state  <= state_idle;
                                                    end
                                            end
                                    end
                                else
                                    begin
                                        if( phase_timer < ( locked_timeout - 1'b1 ) )
                                            begin
                                                phase_timer <= phase_timer + 1'b1;
                                                phase_updn  <= '0;
                                                phase_state <= state_idle;
                                            end
                                        else
                                            begin
                                                phase_updn   <= '1;
                                                phase_timer  <= '0;
                                                phase_post   <= post_steps;
                                                phase_state  <= state_step;
                                            end
                                    end
                                phase_reset  <= '0;
                                phase_en     <= '0;
                            end

                        state_step :
                            begin
                                if( phase_done_latch == 1'b0 )
                                    begin
                                        phase_timer  <= '0;
                                        phase_state  <= state_ack;
                                    end
                                else
                                    begin
                                        if( phase_timer < ( locked_timeout - 1 ) )
                                            begin
                                                phase_timer  <= phase_timer + 1'b1;
                                                phase_state  <= state_step;
                                            end
                                        else
                                            begin
                                                phase_timer  <= '0;
                                                phase_state  <= state_reset;
                                            end
                                    end
                                phase_locked <= '0;
                                phase_reset  <= '0;
                                phase_en     <= '1;
                                phase_updn   <= '0;
                            end

                        state_ack :
                            begin
                                if( phase_done_latch == 1'b1 )
                                    begin
                                        phase_timer <= '0;
                                        phase_state <= state_idle;
                                    end
                                else
                                    begin
                                        if( phase_timer < ( locked_timeout - 1 ) )
                                            begin
                                                phase_timer  <= phase_timer + 1'b1;
                                                phase_state  <= state_ack;
                                            end
                                        else
                                            begin
                                                phase_timer  <= '0;
                                                phase_state  <= state_reset;
                                            end
                                    end
                                phase_locked <= '0;
                                phase_reset  <= '0;
                                phase_en     <= '0;
                                phase_updn   <= '0;
                            end

                        default :
                            begin
                                phase_locked <= '0;
                                phase_reset  <= '1;
                                phase_en     <= '0;
                                phase_updn   <= '0;
                                phase_post   <= '0;
                                phase_timer  <= '0;
                                phase_state  <= state_idle;
                            end
                    endcase
                end
        end

endmodule