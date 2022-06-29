/*
 * Configurator
 */

module configurator #(
  
  parameter FAMILY   = "Cyclone V",
  parameter ROM_TYPE = "AUTO",
  parameter ROM_SIZE = 256,
  parameter ROM_INIT = "",
  parameter INPUT_FREQ = 100_000_000,
  parameter ADDR_OUT_WIDTH = 16,
  parameter DATA_OUT_WIDTH = 8,
  parameter DELAY_MS = 0
  
)(
  
  input               reset_n,
  input               clock,
  
  input               amm_waitrequest,
  output logic        amm_write,
  output logic [31:0] amm_address,
  output logic  [DATA_OUT_WIDTH-1:0] amm_writedata,
  
  output logic  [7:0] gp_outs,
  output logic  completed
  
);
  
  localparam ADDR_WIDTH  = $clog2( ROM_SIZE );  
  
  logic                  rom_valid;
  logic [ADDR_WIDTH-1:0] rom_addr;
  logic           [31:0] rom_data;
  
  assign rom_valid = rom_data != 32'hFFFFFFFF;
  localparam DELAY = DELAY_MS * INPUT_FREQ/1000;
  logic [31:0] delay_cntr;
  wire delayed = delay_cntr == DELAY;
  logic [5:0]cntr;
always_ff @( posedge clock or negedge reset_n )
  begin    
    if( !reset_n ) begin      
      rom_addr      <= {(ADDR_WIDTH){ 1'b0 }};
      amm_write     <= 1'b0;
      amm_address   <= 32'h00000000;
      amm_writedata <= 32'h00000000;
      gp_outs       <= 8'h00;
      cntr <= 6'd0;
      completed   <= 1'b0;
      delay_cntr <= '0;
    end else begin
      
      delay_cntr <= (delayed) ? delay_cntr : ( delay_cntr + 32'd1 );

      if(delayed)
        cntr <= cntr[5] ? cntr : (cntr + 6'd1);

      if( !amm_write && cntr[5])  
        amm_write <= rom_valid;      
      else
        if( amm_write && (!amm_waitrequest))begin
          cntr <= 6'd0;
          amm_write <= 1'b0;
          rom_addr  <= rom_addr + { {(ADDR_WIDTH-1){ 1'b0 }}, 1'b1 };
        end

      if(rom_valid)gp_outs       <= rom_data[31:24];
      else gp_outs       <= '0;
      amm_address   <= rom_data[(ADDR_OUT_WIDTH + DATA_OUT_WIDTH)-1:DATA_OUT_WIDTH];
      amm_writedata <= rom_data[DATA_OUT_WIDTH-1:0];
      
      completed   <= !rom_valid;
    end
    
  end
  
  
  
  altsyncram #(
    .address_aclr_a         ( "NONE"                  ),
    .clock_enable_input_a   ( "BYPASS"                ),
    .clock_enable_output_a  ( "BYPASS"                ),
    .init_file              ( ROM_INIT                ),
    .intended_device_family ( FAMILY                  ),
    .lpm_hint               ( "ENABLE_RUNTIME_MOD=NO" ),
    .lpm_type               ( "altsyncram"            ),
    .numwords_a             ( ROM_SIZE                ),
    .operation_mode         ( "ROM"                   ),
    .outdata_aclr_a         ( "NONE"                  ),
    .outdata_reg_a          ( "UNREGISTERED"          ),
    .ram_block_type         ( ROM_TYPE                ),
    .widthad_a              ( ADDR_WIDTH              ),
    .width_a                ( 32                      ),
    .width_byteena_a        ( 1                       )
  ) altsyncram_i (
    .clock0    ( clock    ),
    .address_a ( rom_addr ),
    .q_a       ( rom_data )
  );
  
  
  
endmodule : configurator
