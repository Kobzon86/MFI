module recalc #(
  parameter NAME = "NONE",
  parameter INIT_FILE = ""
)(
  input         clk_i     ,
  input         DayNight_i,
  input  [ 7:0] ValCode_i ,
  input         load_i    ,
  input         enable_i  ,
  // Outputs
  output        enable_o  ,
  output        load_o    ,
  output [15:0] pwm_o
);

  logic [19:0] source2;

  logic [ 7:0] valcode, valcode_r;
  logic        daynight, daynight_r;
  logic        load, load_r;
  logic        enable, enable_r;
  logic [15:0] pwm_r   ;

  logic [ 4:0] rom_addr;
  logic [15:0] rom_data;

  assign valcode  = ValCode_i ;
  assign daynight = DayNight_i;
  assign load     = load_i    ;
  assign enable   = enable_i  ;

  assign enable_o = (source2[18]) ? source2[17]   : enable_r;
  assign load_o   = (source2[18]) ? source2[16]   : load_r  ;
  assign pwm_o    = (source2[18]) ? source2[15:0] : rom_data;

  assign rom_addr = {daynight, valcode[3:0]};

  altsource_probe #(
    .lpm_type               ("altsource_probe"),
    .lpm_hint               ("UNUSED"         ),
    .sld_auto_instance_index("YES"            ),
    .sld_instance_index     (0                ),
    .SLD_NODE_INFO          (4746752          ),
    .sld_ir_width           (4                ),
    .instance_id            (NAME             ),
    .probe_width            (0                ),
    .source_width           (19               ),
    .source_initial_value   ("0"              ),
    .enable_metastability   ("NO"             )
  ) issp_inst2 (
    .source    (source2),
    .source_clk(clk_i  ),
    .source_ena(1'b1   )
  );

  altsyncram #(
    .address_aclr_a        ("NONE"                                     ),
    .clock_enable_input_a  ("BYPASS"                                   ),
    .clock_enable_output_a ("BYPASS"                                   ),
    .init_file             (INIT_FILE                                  ),
    .intended_device_family("Cyclone V"                                ),
    .lpm_hint              ("ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=brgh"),
    .lpm_type              ("altsyncram"                               ),
    .numwords_a            (32                                         ),
    .operation_mode        ("ROM"                                      ),
    .outdata_aclr_a        ("NONE"                                     ),
    .outdata_reg_a         ("CLOCK0"                                   ),
    .widthad_a             (5                                          ),
    .width_a               (16                                         ),
    .width_byteena_a       (1                                          )
  ) altsyncram_component (
    .address_a(rom_addr  ),
    .clock0   (clk_i     ),
    .q_a      (rom_data  ),
    .address_b(1'b1      ),
    .byteena_a(1'b1      ),
    .byteena_b(1'b1      ),
    .clock1   (1'b1      ),
    .clocken0 (1'b1      ),
    .clocken1 (1'b1      ),
    .clocken2 (1'b1      ),
    .clocken3 (1'b1      ),
    .data_a   ({16{1'b1}}),
    .data_b   (1'b1      ),
    .rden_a   (1'b1      ),
    .rden_b   (1'b1      )
  );



  always_ff @(posedge clk_i)
    begin
      valcode_r  <= valcode;
      daynight_r <= daynight;
      load_r     <= load;
      enable_r   <= enable;
    end

endmodule : recalc
