	component qsys_common is
		port (
			arinc429_inputa                    : in    std_logic_vector(15 downto 0) := (others => 'X'); -- inputa
			arinc429_inputb                    : in    std_logic_vector(15 downto 0) := (others => 'X'); -- inputb
			arinc429_outputa                   : out   std_logic_vector(5 downto 0);                     -- outputa
			arinc429_outputb                   : out   std_logic_vector(5 downto 0);                     -- outputb
			arinc429_slewrate                  : out   std_logic_vector(5 downto 0);                     -- slewrate
			arinc429_testab                    : out   std_logic_vector(1 downto 0);                     -- testab
			arinc708_inputa                    : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- inputa
			arinc708_inputb                    : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- inputb
			arinc708_outputa                   : out   std_logic_vector(1 downto 0);                     -- outputa
			arinc708_outputb                   : out   std_logic_vector(1 downto 0);                     -- outputb
			arinc708_tx_inh                    : out   std_logic_vector(1 downto 0);                     -- tx_inh
			arinc708_rx_en                     : out   std_logic_vector(1 downto 0);                     -- rx_en
			clock_out_clk                      : out   std_logic;                                        -- clk
			ddr_0_mem_a                        : out   std_logic_vector(14 downto 0);                    -- mem_a
			ddr_0_mem_ba                       : out   std_logic_vector(2 downto 0);                     -- mem_ba
			ddr_0_mem_ck                       : out   std_logic_vector(0 downto 0);                     -- mem_ck
			ddr_0_mem_ck_n                     : out   std_logic_vector(0 downto 0);                     -- mem_ck_n
			ddr_0_mem_cke                      : out   std_logic_vector(0 downto 0);                     -- mem_cke
			ddr_0_mem_cs_n                     : out   std_logic_vector(0 downto 0);                     -- mem_cs_n
			ddr_0_mem_dm                       : out   std_logic_vector(1 downto 0);                     -- mem_dm
			ddr_0_mem_ras_n                    : out   std_logic_vector(0 downto 0);                     -- mem_ras_n
			ddr_0_mem_cas_n                    : out   std_logic_vector(0 downto 0);                     -- mem_cas_n
			ddr_0_mem_we_n                     : out   std_logic_vector(0 downto 0);                     -- mem_we_n
			ddr_0_mem_reset_n                  : out   std_logic;                                        -- mem_reset_n
			ddr_0_mem_dq                       : inout std_logic_vector(15 downto 0) := (others => 'X'); -- mem_dq
			ddr_0_mem_dqs                      : inout std_logic_vector(1 downto 0)  := (others => 'X'); -- mem_dqs
			ddr_0_mem_dqs_n                    : inout std_logic_vector(1 downto 0)  := (others => 'X'); -- mem_dqs_n
			ddr_0_mem_odt                      : out   std_logic_vector(0 downto 0);                     -- mem_odt
			ddr_1_mem_a                        : out   std_logic_vector(14 downto 0);                    -- mem_a
			ddr_1_mem_ba                       : out   std_logic_vector(2 downto 0);                     -- mem_ba
			ddr_1_mem_ck                       : out   std_logic_vector(0 downto 0);                     -- mem_ck
			ddr_1_mem_ck_n                     : out   std_logic_vector(0 downto 0);                     -- mem_ck_n
			ddr_1_mem_cke                      : out   std_logic_vector(0 downto 0);                     -- mem_cke
			ddr_1_mem_cs_n                     : out   std_logic_vector(0 downto 0);                     -- mem_cs_n
			ddr_1_mem_dm                       : out   std_logic_vector(1 downto 0);                     -- mem_dm
			ddr_1_mem_ras_n                    : out   std_logic_vector(0 downto 0);                     -- mem_ras_n
			ddr_1_mem_cas_n                    : out   std_logic_vector(0 downto 0);                     -- mem_cas_n
			ddr_1_mem_we_n                     : out   std_logic_vector(0 downto 0);                     -- mem_we_n
			ddr_1_mem_reset_n                  : out   std_logic;                                        -- mem_reset_n
			ddr_1_mem_dq                       : inout std_logic_vector(15 downto 0) := (others => 'X'); -- mem_dq
			ddr_1_mem_dqs                      : inout std_logic_vector(1 downto 0)  := (others => 'X'); -- mem_dqs
			ddr_1_mem_dqs_n                    : inout std_logic_vector(1 downto 0)  := (others => 'X'); -- mem_dqs_n
			ddr_1_mem_odt                      : out   std_logic_vector(0 downto 0);                     -- mem_odt
			ddr_clk_in_0_clk                   : in    std_logic                     := 'X';             -- clk
			ddr_clk_in_1_clk                   : in    std_logic                     := 'X';             -- clk
			ddr_global_reset_0_reset_n         : in    std_logic                     := 'X';             -- reset_n
			ddr_global_reset_1_reset_n         : in    std_logic                     := 'X';             -- reset_n
			ddr_oct_0_rzqin                    : in    std_logic                     := 'X';             -- rzqin
			ddr_oct_1_rzqin                    : in    std_logic                     := 'X';             -- rzqin
			ddr_soft_reset_0_reset_n           : in    std_logic                     := 'X';             -- reset_n
			ddr_soft_reset_1_reset_n           : in    std_logic                     := 'X';             -- reset_n
			ddr_status_0_local_init_done       : out   std_logic;                                        -- local_init_done
			ddr_status_0_local_cal_success     : out   std_logic;                                        -- local_cal_success
			ddr_status_0_local_cal_fail        : out   std_logic;                                        -- local_cal_fail
			ddr_status_1_local_init_done       : out   std_logic;                                        -- local_init_done
			ddr_status_1_local_cal_success     : out   std_logic;                                        -- local_cal_success
			ddr_status_1_local_cal_fail        : out   std_logic;                                        -- local_cal_fail
			discr_cmd_in_vwet                  : out   std_logic;                                        -- vwet
			discr_cmd_in_ths_int               : out   std_logic;                                        -- ths_int
			discr_cmd_in_ths_sel               : out   std_logic;                                        -- ths_sel
			discr_cmd_in_sense                 : out   std_logic;                                        -- sense
			discr_cmd_in_export                : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			discr_cmd_out_fault                : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- fault
			discr_cmd_out_export               : out   std_logic_vector(3 downto 0);                     -- export
			gpio_in_port                       : in    std_logic_vector(31 downto 0) := (others => 'X'); -- in_port
			gpio_out_port                      : out   std_logic_vector(31 downto 0);                    -- out_port
			i2c_clk                            : inout std_logic                     := 'X';             -- clk
			i2c_data                           : inout std_logic                     := 'X';             -- data
			pcie_npor_npor                     : in    std_logic                     := 'X';             -- npor
			pcie_npor_pin_perst                : in    std_logic                     := 'X';             -- pin_perst
			pcie_refclk_clk                    : in    std_logic                     := 'X';             -- clk
			pcie_serial_rx_in0                 : in    std_logic                     := 'X';             -- rx_in0
			pcie_serial_tx_out0                : out   std_logic;                                        -- tx_out0
			por_reset_n                        : in    std_logic                     := 'X';             -- reset_n
			pu_backlight_drv_en                : out   std_logic_vector(1 downto 0);                     -- drv_en
			pu_backlight_out_en_n              : out   std_logic_vector(1 downto 0);                     -- out_en_n
			pu_backlight_pwm                   : out   std_logic_vector(2 downto 0);                     -- pwm
			pu_backlight_fault                 : in    std_logic                     := 'X';             -- fault
			pu_i2c_clk                         : inout std_logic                     := 'X';             -- clk
			pu_i2c_data                        : inout std_logic                     := 'X';             -- data
			pu_type_ext                        : out   std_logic_vector(1 downto 0);                     -- ext
			reset_out_reset_n                  : out   std_logic;                                        -- reset_n
			reset_out_reset_req                : out   std_logic;                                        -- reset_req
			video_av_in_0_vid_clk              : in    std_logic                     := 'X';             -- vid_clk
			video_av_in_0_vid_data             : in    std_logic_vector(23 downto 0) := (others => 'X'); -- vid_data
			video_av_in_0_vid_de               : in    std_logic                     := 'X';             -- vid_de
			video_av_in_0_vid_datavalid        : in    std_logic                     := 'X';             -- vid_datavalid
			video_av_in_0_vid_locked           : in    std_logic                     := 'X';             -- vid_locked
			video_av_in_0_vid_f                : in    std_logic                     := 'X';             -- vid_f
			video_av_in_0_vid_v_sync           : in    std_logic                     := 'X';             -- vid_v_sync
			video_av_in_0_vid_h_sync           : in    std_logic                     := 'X';             -- vid_h_sync
			video_av_in_0_vid_color_encoding   : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_color_encoding
			video_av_in_0_vid_bit_width        : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_bit_width
			video_av_in_0_sof                  : out   std_logic;                                        -- sof
			video_av_in_0_sof_locked           : out   std_logic;                                        -- sof_locked
			video_av_in_0_refclk_div           : out   std_logic;                                        -- refclk_div
			video_av_in_0_clipping             : out   std_logic;                                        -- clipping
			video_av_in_0_padding              : out   std_logic;                                        -- padding
			video_av_in_0_overflow             : out   std_logic;                                        -- overflow
			video_av_in_1_vid_clk              : in    std_logic                     := 'X';             -- vid_clk
			video_av_in_1_vid_data             : in    std_logic_vector(23 downto 0) := (others => 'X'); -- vid_data
			video_av_in_1_vid_de               : in    std_logic                     := 'X';             -- vid_de
			video_av_in_1_vid_datavalid        : in    std_logic                     := 'X';             -- vid_datavalid
			video_av_in_1_vid_locked           : in    std_logic                     := 'X';             -- vid_locked
			video_av_in_1_vid_f                : in    std_logic                     := 'X';             -- vid_f
			video_av_in_1_vid_v_sync           : in    std_logic                     := 'X';             -- vid_v_sync
			video_av_in_1_vid_h_sync           : in    std_logic                     := 'X';             -- vid_h_sync
			video_av_in_1_vid_color_encoding   : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_color_encoding
			video_av_in_1_vid_bit_width        : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_bit_width
			video_av_in_1_sof                  : out   std_logic;                                        -- sof
			video_av_in_1_sof_locked           : out   std_logic;                                        -- sof_locked
			video_av_in_1_refclk_div           : out   std_logic;                                        -- refclk_div
			video_av_in_1_clipping             : out   std_logic;                                        -- clipping
			video_av_in_1_padding              : out   std_logic;                                        -- padding
			video_av_in_1_overflow             : out   std_logic;                                        -- overflow
			video_cpu_in_vid_clk               : in    std_logic                     := 'X';             -- vid_clk
			video_cpu_in_vid_data              : in    std_logic_vector(31 downto 0) := (others => 'X'); -- vid_data
			video_cpu_in_vid_de                : in    std_logic                     := 'X';             -- vid_de
			video_cpu_in_vid_datavalid         : in    std_logic                     := 'X';             -- vid_datavalid
			video_cpu_in_vid_locked            : in    std_logic                     := 'X';             -- vid_locked
			video_cpu_in_vid_f                 : in    std_logic                     := 'X';             -- vid_f
			video_cpu_in_vid_v_sync            : in    std_logic                     := 'X';             -- vid_v_sync
			video_cpu_in_vid_h_sync            : in    std_logic                     := 'X';             -- vid_h_sync
			video_cpu_in_vid_color_encoding    : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_color_encoding
			video_cpu_in_vid_bit_width         : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_bit_width
			video_cpu_in_sof                   : out   std_logic;                                        -- sof
			video_cpu_in_sof_locked            : out   std_logic;                                        -- sof_locked
			video_cpu_in_refclk_div            : out   std_logic;                                        -- refclk_div
			video_cpu_in_clipping              : out   std_logic;                                        -- clipping
			video_cpu_in_padding               : out   std_logic;                                        -- padding
			video_cpu_in_overflow              : out   std_logic;                                        -- overflow
			video_ic_outputs                   : out   std_logic_vector(7 downto 0);                     -- outputs
			video_out_vid_clk                  : in    std_logic                     := 'X';             -- vid_clk
			video_out_vid_data                 : out   std_logic_vector(23 downto 0);                    -- vid_data
			video_out_underflow                : out   std_logic;                                        -- underflow
			video_out_vid_mode_change          : out   std_logic;                                        -- vid_mode_change
			video_out_vid_std                  : out   std_logic;                                        -- vid_std
			video_out_vid_datavalid            : out   std_logic;                                        -- vid_datavalid
			video_out_vid_v_sync               : out   std_logic;                                        -- vid_v_sync
			video_out_vid_h_sync               : out   std_logic;                                        -- vid_h_sync
			video_out_vid_f                    : out   std_logic;                                        -- vid_f
			video_out_vid_h                    : out   std_logic;                                        -- vid_h
			video_out_vid_v                    : out   std_logic;                                        -- vid_v
			video_tmds_in_0_vid_clk            : in    std_logic                     := 'X';             -- vid_clk
			video_tmds_in_0_vid_data           : in    std_logic_vector(47 downto 0) := (others => 'X'); -- vid_data
			video_tmds_in_0_vid_de             : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- vid_de
			video_tmds_in_0_vid_datavalid      : in    std_logic                     := 'X';             -- vid_datavalid
			video_tmds_in_0_vid_locked         : in    std_logic                     := 'X';             -- vid_locked
			video_tmds_in_0_vid_f              : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- vid_f
			video_tmds_in_0_vid_v_sync         : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- vid_v_sync
			video_tmds_in_0_vid_h_sync         : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- vid_h_sync
			video_tmds_in_0_vid_color_encoding : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_color_encoding
			video_tmds_in_0_vid_bit_width      : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_bit_width
			video_tmds_in_0_sof                : out   std_logic;                                        -- sof
			video_tmds_in_0_sof_locked         : out   std_logic;                                        -- sof_locked
			video_tmds_in_0_refclk_div         : out   std_logic;                                        -- refclk_div
			video_tmds_in_0_clipping           : out   std_logic;                                        -- clipping
			video_tmds_in_0_padding            : out   std_logic;                                        -- padding
			video_tmds_in_0_overflow           : out   std_logic;                                        -- overflow
			video_tmds_in_1_vid_clk            : in    std_logic                     := 'X';             -- vid_clk
			video_tmds_in_1_vid_data           : in    std_logic_vector(47 downto 0) := (others => 'X'); -- vid_data
			video_tmds_in_1_vid_de             : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- vid_de
			video_tmds_in_1_vid_datavalid      : in    std_logic                     := 'X';             -- vid_datavalid
			video_tmds_in_1_vid_locked         : in    std_logic                     := 'X';             -- vid_locked
			video_tmds_in_1_vid_f              : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- vid_f
			video_tmds_in_1_vid_v_sync         : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- vid_v_sync
			video_tmds_in_1_vid_h_sync         : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- vid_h_sync
			video_tmds_in_1_vid_color_encoding : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_color_encoding
			video_tmds_in_1_vid_bit_width      : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- vid_bit_width
			video_tmds_in_1_sof                : out   std_logic;                                        -- sof
			video_tmds_in_1_sof_locked         : out   std_logic;                                        -- sof_locked
			video_tmds_in_1_refclk_div         : out   std_logic;                                        -- refclk_div
			video_tmds_in_1_clipping           : out   std_logic;                                        -- clipping
			video_tmds_in_1_padding            : out   std_logic;                                        -- padding
			video_tmds_in_1_overflow           : out   std_logic                                         -- overflow
		);
	end component qsys_common;

	u0 : component qsys_common
		port map (
			arinc429_inputa                    => CONNECTED_TO_arinc429_inputa,                    --           arinc429.inputa
			arinc429_inputb                    => CONNECTED_TO_arinc429_inputb,                    --                   .inputb
			arinc429_outputa                   => CONNECTED_TO_arinc429_outputa,                   --                   .outputa
			arinc429_outputb                   => CONNECTED_TO_arinc429_outputb,                   --                   .outputb
			arinc429_slewrate                  => CONNECTED_TO_arinc429_slewrate,                  --                   .slewrate
			arinc429_testab                    => CONNECTED_TO_arinc429_testab,                    --                   .testab
			arinc708_inputa                    => CONNECTED_TO_arinc708_inputa,                    --           arinc708.inputa
			arinc708_inputb                    => CONNECTED_TO_arinc708_inputb,                    --                   .inputb
			arinc708_outputa                   => CONNECTED_TO_arinc708_outputa,                   --                   .outputa
			arinc708_outputb                   => CONNECTED_TO_arinc708_outputb,                   --                   .outputb
			arinc708_tx_inh                    => CONNECTED_TO_arinc708_tx_inh,                    --                   .tx_inh
			arinc708_rx_en                     => CONNECTED_TO_arinc708_rx_en,                     --                   .rx_en
			clock_out_clk                      => CONNECTED_TO_clock_out_clk,                      --          clock_out.clk
			ddr_0_mem_a                        => CONNECTED_TO_ddr_0_mem_a,                        --              ddr_0.mem_a
			ddr_0_mem_ba                       => CONNECTED_TO_ddr_0_mem_ba,                       --                   .mem_ba
			ddr_0_mem_ck                       => CONNECTED_TO_ddr_0_mem_ck,                       --                   .mem_ck
			ddr_0_mem_ck_n                     => CONNECTED_TO_ddr_0_mem_ck_n,                     --                   .mem_ck_n
			ddr_0_mem_cke                      => CONNECTED_TO_ddr_0_mem_cke,                      --                   .mem_cke
			ddr_0_mem_cs_n                     => CONNECTED_TO_ddr_0_mem_cs_n,                     --                   .mem_cs_n
			ddr_0_mem_dm                       => CONNECTED_TO_ddr_0_mem_dm,                       --                   .mem_dm
			ddr_0_mem_ras_n                    => CONNECTED_TO_ddr_0_mem_ras_n,                    --                   .mem_ras_n
			ddr_0_mem_cas_n                    => CONNECTED_TO_ddr_0_mem_cas_n,                    --                   .mem_cas_n
			ddr_0_mem_we_n                     => CONNECTED_TO_ddr_0_mem_we_n,                     --                   .mem_we_n
			ddr_0_mem_reset_n                  => CONNECTED_TO_ddr_0_mem_reset_n,                  --                   .mem_reset_n
			ddr_0_mem_dq                       => CONNECTED_TO_ddr_0_mem_dq,                       --                   .mem_dq
			ddr_0_mem_dqs                      => CONNECTED_TO_ddr_0_mem_dqs,                      --                   .mem_dqs
			ddr_0_mem_dqs_n                    => CONNECTED_TO_ddr_0_mem_dqs_n,                    --                   .mem_dqs_n
			ddr_0_mem_odt                      => CONNECTED_TO_ddr_0_mem_odt,                      --                   .mem_odt
			ddr_1_mem_a                        => CONNECTED_TO_ddr_1_mem_a,                        --              ddr_1.mem_a
			ddr_1_mem_ba                       => CONNECTED_TO_ddr_1_mem_ba,                       --                   .mem_ba
			ddr_1_mem_ck                       => CONNECTED_TO_ddr_1_mem_ck,                       --                   .mem_ck
			ddr_1_mem_ck_n                     => CONNECTED_TO_ddr_1_mem_ck_n,                     --                   .mem_ck_n
			ddr_1_mem_cke                      => CONNECTED_TO_ddr_1_mem_cke,                      --                   .mem_cke
			ddr_1_mem_cs_n                     => CONNECTED_TO_ddr_1_mem_cs_n,                     --                   .mem_cs_n
			ddr_1_mem_dm                       => CONNECTED_TO_ddr_1_mem_dm,                       --                   .mem_dm
			ddr_1_mem_ras_n                    => CONNECTED_TO_ddr_1_mem_ras_n,                    --                   .mem_ras_n
			ddr_1_mem_cas_n                    => CONNECTED_TO_ddr_1_mem_cas_n,                    --                   .mem_cas_n
			ddr_1_mem_we_n                     => CONNECTED_TO_ddr_1_mem_we_n,                     --                   .mem_we_n
			ddr_1_mem_reset_n                  => CONNECTED_TO_ddr_1_mem_reset_n,                  --                   .mem_reset_n
			ddr_1_mem_dq                       => CONNECTED_TO_ddr_1_mem_dq,                       --                   .mem_dq
			ddr_1_mem_dqs                      => CONNECTED_TO_ddr_1_mem_dqs,                      --                   .mem_dqs
			ddr_1_mem_dqs_n                    => CONNECTED_TO_ddr_1_mem_dqs_n,                    --                   .mem_dqs_n
			ddr_1_mem_odt                      => CONNECTED_TO_ddr_1_mem_odt,                      --                   .mem_odt
			ddr_clk_in_0_clk                   => CONNECTED_TO_ddr_clk_in_0_clk,                   --       ddr_clk_in_0.clk
			ddr_clk_in_1_clk                   => CONNECTED_TO_ddr_clk_in_1_clk,                   --       ddr_clk_in_1.clk
			ddr_global_reset_0_reset_n         => CONNECTED_TO_ddr_global_reset_0_reset_n,         -- ddr_global_reset_0.reset_n
			ddr_global_reset_1_reset_n         => CONNECTED_TO_ddr_global_reset_1_reset_n,         -- ddr_global_reset_1.reset_n
			ddr_oct_0_rzqin                    => CONNECTED_TO_ddr_oct_0_rzqin,                    --          ddr_oct_0.rzqin
			ddr_oct_1_rzqin                    => CONNECTED_TO_ddr_oct_1_rzqin,                    --          ddr_oct_1.rzqin
			ddr_soft_reset_0_reset_n           => CONNECTED_TO_ddr_soft_reset_0_reset_n,           --   ddr_soft_reset_0.reset_n
			ddr_soft_reset_1_reset_n           => CONNECTED_TO_ddr_soft_reset_1_reset_n,           --   ddr_soft_reset_1.reset_n
			ddr_status_0_local_init_done       => CONNECTED_TO_ddr_status_0_local_init_done,       --       ddr_status_0.local_init_done
			ddr_status_0_local_cal_success     => CONNECTED_TO_ddr_status_0_local_cal_success,     --                   .local_cal_success
			ddr_status_0_local_cal_fail        => CONNECTED_TO_ddr_status_0_local_cal_fail,        --                   .local_cal_fail
			ddr_status_1_local_init_done       => CONNECTED_TO_ddr_status_1_local_init_done,       --       ddr_status_1.local_init_done
			ddr_status_1_local_cal_success     => CONNECTED_TO_ddr_status_1_local_cal_success,     --                   .local_cal_success
			ddr_status_1_local_cal_fail        => CONNECTED_TO_ddr_status_1_local_cal_fail,        --                   .local_cal_fail
			discr_cmd_in_vwet                  => CONNECTED_TO_discr_cmd_in_vwet,                  --       discr_cmd_in.vwet
			discr_cmd_in_ths_int               => CONNECTED_TO_discr_cmd_in_ths_int,               --                   .ths_int
			discr_cmd_in_ths_sel               => CONNECTED_TO_discr_cmd_in_ths_sel,               --                   .ths_sel
			discr_cmd_in_sense                 => CONNECTED_TO_discr_cmd_in_sense,                 --                   .sense
			discr_cmd_in_export                => CONNECTED_TO_discr_cmd_in_export,                --                   .export
			discr_cmd_out_fault                => CONNECTED_TO_discr_cmd_out_fault,                --      discr_cmd_out.fault
			discr_cmd_out_export               => CONNECTED_TO_discr_cmd_out_export,               --                   .export
			gpio_in_port                       => CONNECTED_TO_gpio_in_port,                       --               gpio.in_port
			gpio_out_port                      => CONNECTED_TO_gpio_out_port,                      --                   .out_port
			i2c_clk                            => CONNECTED_TO_i2c_clk,                            --                i2c.clk
			i2c_data                           => CONNECTED_TO_i2c_data,                           --                   .data
			pcie_npor_npor                     => CONNECTED_TO_pcie_npor_npor,                     --          pcie_npor.npor
			pcie_npor_pin_perst                => CONNECTED_TO_pcie_npor_pin_perst,                --                   .pin_perst
			pcie_refclk_clk                    => CONNECTED_TO_pcie_refclk_clk,                    --        pcie_refclk.clk
			pcie_serial_rx_in0                 => CONNECTED_TO_pcie_serial_rx_in0,                 --        pcie_serial.rx_in0
			pcie_serial_tx_out0                => CONNECTED_TO_pcie_serial_tx_out0,                --                   .tx_out0
			por_reset_n                        => CONNECTED_TO_por_reset_n,                        --                por.reset_n
			pu_backlight_drv_en                => CONNECTED_TO_pu_backlight_drv_en,                --       pu_backlight.drv_en
			pu_backlight_out_en_n              => CONNECTED_TO_pu_backlight_out_en_n,              --                   .out_en_n
			pu_backlight_pwm                   => CONNECTED_TO_pu_backlight_pwm,                   --                   .pwm
			pu_backlight_fault                 => CONNECTED_TO_pu_backlight_fault,                 --                   .fault
			pu_i2c_clk                         => CONNECTED_TO_pu_i2c_clk,                         --             pu_i2c.clk
			pu_i2c_data                        => CONNECTED_TO_pu_i2c_data,                        --                   .data
			pu_type_ext                        => CONNECTED_TO_pu_type_ext,                        --            pu_type.ext
			reset_out_reset_n                  => CONNECTED_TO_reset_out_reset_n,                  --          reset_out.reset_n
			reset_out_reset_req                => CONNECTED_TO_reset_out_reset_req,                --                   .reset_req
			video_av_in_0_vid_clk              => CONNECTED_TO_video_av_in_0_vid_clk,              --      video_av_in_0.vid_clk
			video_av_in_0_vid_data             => CONNECTED_TO_video_av_in_0_vid_data,             --                   .vid_data
			video_av_in_0_vid_de               => CONNECTED_TO_video_av_in_0_vid_de,               --                   .vid_de
			video_av_in_0_vid_datavalid        => CONNECTED_TO_video_av_in_0_vid_datavalid,        --                   .vid_datavalid
			video_av_in_0_vid_locked           => CONNECTED_TO_video_av_in_0_vid_locked,           --                   .vid_locked
			video_av_in_0_vid_f                => CONNECTED_TO_video_av_in_0_vid_f,                --                   .vid_f
			video_av_in_0_vid_v_sync           => CONNECTED_TO_video_av_in_0_vid_v_sync,           --                   .vid_v_sync
			video_av_in_0_vid_h_sync           => CONNECTED_TO_video_av_in_0_vid_h_sync,           --                   .vid_h_sync
			video_av_in_0_vid_color_encoding   => CONNECTED_TO_video_av_in_0_vid_color_encoding,   --                   .vid_color_encoding
			video_av_in_0_vid_bit_width        => CONNECTED_TO_video_av_in_0_vid_bit_width,        --                   .vid_bit_width
			video_av_in_0_sof                  => CONNECTED_TO_video_av_in_0_sof,                  --                   .sof
			video_av_in_0_sof_locked           => CONNECTED_TO_video_av_in_0_sof_locked,           --                   .sof_locked
			video_av_in_0_refclk_div           => CONNECTED_TO_video_av_in_0_refclk_div,           --                   .refclk_div
			video_av_in_0_clipping             => CONNECTED_TO_video_av_in_0_clipping,             --                   .clipping
			video_av_in_0_padding              => CONNECTED_TO_video_av_in_0_padding,              --                   .padding
			video_av_in_0_overflow             => CONNECTED_TO_video_av_in_0_overflow,             --                   .overflow
			video_av_in_1_vid_clk              => CONNECTED_TO_video_av_in_1_vid_clk,              --      video_av_in_1.vid_clk
			video_av_in_1_vid_data             => CONNECTED_TO_video_av_in_1_vid_data,             --                   .vid_data
			video_av_in_1_vid_de               => CONNECTED_TO_video_av_in_1_vid_de,               --                   .vid_de
			video_av_in_1_vid_datavalid        => CONNECTED_TO_video_av_in_1_vid_datavalid,        --                   .vid_datavalid
			video_av_in_1_vid_locked           => CONNECTED_TO_video_av_in_1_vid_locked,           --                   .vid_locked
			video_av_in_1_vid_f                => CONNECTED_TO_video_av_in_1_vid_f,                --                   .vid_f
			video_av_in_1_vid_v_sync           => CONNECTED_TO_video_av_in_1_vid_v_sync,           --                   .vid_v_sync
			video_av_in_1_vid_h_sync           => CONNECTED_TO_video_av_in_1_vid_h_sync,           --                   .vid_h_sync
			video_av_in_1_vid_color_encoding   => CONNECTED_TO_video_av_in_1_vid_color_encoding,   --                   .vid_color_encoding
			video_av_in_1_vid_bit_width        => CONNECTED_TO_video_av_in_1_vid_bit_width,        --                   .vid_bit_width
			video_av_in_1_sof                  => CONNECTED_TO_video_av_in_1_sof,                  --                   .sof
			video_av_in_1_sof_locked           => CONNECTED_TO_video_av_in_1_sof_locked,           --                   .sof_locked
			video_av_in_1_refclk_div           => CONNECTED_TO_video_av_in_1_refclk_div,           --                   .refclk_div
			video_av_in_1_clipping             => CONNECTED_TO_video_av_in_1_clipping,             --                   .clipping
			video_av_in_1_padding              => CONNECTED_TO_video_av_in_1_padding,              --                   .padding
			video_av_in_1_overflow             => CONNECTED_TO_video_av_in_1_overflow,             --                   .overflow
			video_cpu_in_vid_clk               => CONNECTED_TO_video_cpu_in_vid_clk,               --       video_cpu_in.vid_clk
			video_cpu_in_vid_data              => CONNECTED_TO_video_cpu_in_vid_data,              --                   .vid_data
			video_cpu_in_vid_de                => CONNECTED_TO_video_cpu_in_vid_de,                --                   .vid_de
			video_cpu_in_vid_datavalid         => CONNECTED_TO_video_cpu_in_vid_datavalid,         --                   .vid_datavalid
			video_cpu_in_vid_locked            => CONNECTED_TO_video_cpu_in_vid_locked,            --                   .vid_locked
			video_cpu_in_vid_f                 => CONNECTED_TO_video_cpu_in_vid_f,                 --                   .vid_f
			video_cpu_in_vid_v_sync            => CONNECTED_TO_video_cpu_in_vid_v_sync,            --                   .vid_v_sync
			video_cpu_in_vid_h_sync            => CONNECTED_TO_video_cpu_in_vid_h_sync,            --                   .vid_h_sync
			video_cpu_in_vid_color_encoding    => CONNECTED_TO_video_cpu_in_vid_color_encoding,    --                   .vid_color_encoding
			video_cpu_in_vid_bit_width         => CONNECTED_TO_video_cpu_in_vid_bit_width,         --                   .vid_bit_width
			video_cpu_in_sof                   => CONNECTED_TO_video_cpu_in_sof,                   --                   .sof
			video_cpu_in_sof_locked            => CONNECTED_TO_video_cpu_in_sof_locked,            --                   .sof_locked
			video_cpu_in_refclk_div            => CONNECTED_TO_video_cpu_in_refclk_div,            --                   .refclk_div
			video_cpu_in_clipping              => CONNECTED_TO_video_cpu_in_clipping,              --                   .clipping
			video_cpu_in_padding               => CONNECTED_TO_video_cpu_in_padding,               --                   .padding
			video_cpu_in_overflow              => CONNECTED_TO_video_cpu_in_overflow,              --                   .overflow
			video_ic_outputs                   => CONNECTED_TO_video_ic_outputs,                   --           video_ic.outputs
			video_out_vid_clk                  => CONNECTED_TO_video_out_vid_clk,                  --          video_out.vid_clk
			video_out_vid_data                 => CONNECTED_TO_video_out_vid_data,                 --                   .vid_data
			video_out_underflow                => CONNECTED_TO_video_out_underflow,                --                   .underflow
			video_out_vid_mode_change          => CONNECTED_TO_video_out_vid_mode_change,          --                   .vid_mode_change
			video_out_vid_std                  => CONNECTED_TO_video_out_vid_std,                  --                   .vid_std
			video_out_vid_datavalid            => CONNECTED_TO_video_out_vid_datavalid,            --                   .vid_datavalid
			video_out_vid_v_sync               => CONNECTED_TO_video_out_vid_v_sync,               --                   .vid_v_sync
			video_out_vid_h_sync               => CONNECTED_TO_video_out_vid_h_sync,               --                   .vid_h_sync
			video_out_vid_f                    => CONNECTED_TO_video_out_vid_f,                    --                   .vid_f
			video_out_vid_h                    => CONNECTED_TO_video_out_vid_h,                    --                   .vid_h
			video_out_vid_v                    => CONNECTED_TO_video_out_vid_v,                    --                   .vid_v
			video_tmds_in_0_vid_clk            => CONNECTED_TO_video_tmds_in_0_vid_clk,            --    video_tmds_in_0.vid_clk
			video_tmds_in_0_vid_data           => CONNECTED_TO_video_tmds_in_0_vid_data,           --                   .vid_data
			video_tmds_in_0_vid_de             => CONNECTED_TO_video_tmds_in_0_vid_de,             --                   .vid_de
			video_tmds_in_0_vid_datavalid      => CONNECTED_TO_video_tmds_in_0_vid_datavalid,      --                   .vid_datavalid
			video_tmds_in_0_vid_locked         => CONNECTED_TO_video_tmds_in_0_vid_locked,         --                   .vid_locked
			video_tmds_in_0_vid_f              => CONNECTED_TO_video_tmds_in_0_vid_f,              --                   .vid_f
			video_tmds_in_0_vid_v_sync         => CONNECTED_TO_video_tmds_in_0_vid_v_sync,         --                   .vid_v_sync
			video_tmds_in_0_vid_h_sync         => CONNECTED_TO_video_tmds_in_0_vid_h_sync,         --                   .vid_h_sync
			video_tmds_in_0_vid_color_encoding => CONNECTED_TO_video_tmds_in_0_vid_color_encoding, --                   .vid_color_encoding
			video_tmds_in_0_vid_bit_width      => CONNECTED_TO_video_tmds_in_0_vid_bit_width,      --                   .vid_bit_width
			video_tmds_in_0_sof                => CONNECTED_TO_video_tmds_in_0_sof,                --                   .sof
			video_tmds_in_0_sof_locked         => CONNECTED_TO_video_tmds_in_0_sof_locked,         --                   .sof_locked
			video_tmds_in_0_refclk_div         => CONNECTED_TO_video_tmds_in_0_refclk_div,         --                   .refclk_div
			video_tmds_in_0_clipping           => CONNECTED_TO_video_tmds_in_0_clipping,           --                   .clipping
			video_tmds_in_0_padding            => CONNECTED_TO_video_tmds_in_0_padding,            --                   .padding
			video_tmds_in_0_overflow           => CONNECTED_TO_video_tmds_in_0_overflow,           --                   .overflow
			video_tmds_in_1_vid_clk            => CONNECTED_TO_video_tmds_in_1_vid_clk,            --    video_tmds_in_1.vid_clk
			video_tmds_in_1_vid_data           => CONNECTED_TO_video_tmds_in_1_vid_data,           --                   .vid_data
			video_tmds_in_1_vid_de             => CONNECTED_TO_video_tmds_in_1_vid_de,             --                   .vid_de
			video_tmds_in_1_vid_datavalid      => CONNECTED_TO_video_tmds_in_1_vid_datavalid,      --                   .vid_datavalid
			video_tmds_in_1_vid_locked         => CONNECTED_TO_video_tmds_in_1_vid_locked,         --                   .vid_locked
			video_tmds_in_1_vid_f              => CONNECTED_TO_video_tmds_in_1_vid_f,              --                   .vid_f
			video_tmds_in_1_vid_v_sync         => CONNECTED_TO_video_tmds_in_1_vid_v_sync,         --                   .vid_v_sync
			video_tmds_in_1_vid_h_sync         => CONNECTED_TO_video_tmds_in_1_vid_h_sync,         --                   .vid_h_sync
			video_tmds_in_1_vid_color_encoding => CONNECTED_TO_video_tmds_in_1_vid_color_encoding, --                   .vid_color_encoding
			video_tmds_in_1_vid_bit_width      => CONNECTED_TO_video_tmds_in_1_vid_bit_width,      --                   .vid_bit_width
			video_tmds_in_1_sof                => CONNECTED_TO_video_tmds_in_1_sof,                --                   .sof
			video_tmds_in_1_sof_locked         => CONNECTED_TO_video_tmds_in_1_sof_locked,         --                   .sof_locked
			video_tmds_in_1_refclk_div         => CONNECTED_TO_video_tmds_in_1_refclk_div,         --                   .refclk_div
			video_tmds_in_1_clipping           => CONNECTED_TO_video_tmds_in_1_clipping,           --                   .clipping
			video_tmds_in_1_padding            => CONNECTED_TO_video_tmds_in_1_padding,            --                   .padding
			video_tmds_in_1_overflow           => CONNECTED_TO_video_tmds_in_1_overflow            --                   .overflow
		);

