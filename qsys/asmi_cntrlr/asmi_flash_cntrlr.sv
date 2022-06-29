/*
 * Configurator
 */

module asmi_flash_cntrlr #(
  parameter ASMI_CSR = 32'h200_0000
  )(
  input               reset_n          ,
  input               clock            ,

  input               asmi_amm_waitrequest  ,
  output logic        asmi_amm_write        ,
  output logic        asmi_amm_read         ,
  input        [31:0] asmi_amm_readdata     ,
  input               asmi_amm_readdatavalid,
  output logic [25:0] asmi_amm_address      ,
  output logic [ 6:0] asmi_amm_burstcount   ,
  output logic [31:0] asmi_amm_writedata    ,

  input               ams_mem_read         ,
  input               ams_mem_write         ,
  output logic [31:0] ams_mem_readdata     ,
  input        [31:0] ams_mem_writedata     ,
  output logic        ams_mem_waitrequest     ,
  output logic        ams_mem_readdatavalid,
  input  [16:0]       ams_mem_address ,
  input [6:0]         ams_mem_burstcount

);
wire csr_m = ams_mem_address[16];
assign asmi_amm_write        = ams_mem_write;
assign asmi_amm_read         = ams_mem_read;
assign asmi_amm_address      = ({(csr_m?16'd0:mem_offset),ams_mem_address[15:0]} | (csr_m ? ASMI_CSR : 32'd0));//{mem_offset, ams_mem_address};
assign asmi_amm_burstcount   = ams_mem_burstcount;
assign asmi_amm_writedata    = ams_mem_writedata;
assign ams_mem_readdata      = asmi_amm_readdata;
assign ams_mem_readdatavalid = asmi_amm_readdatavalid;
assign ams_mem_waitrequest   = asmi_amm_waitrequest;

logic[15:0]mem_offset;
always @(posedge clock or negedge reset_n) begin : proc_
  if(~reset_n) begin
     mem_offset<= 0;
  end else begin
    if(csr_m && (ams_mem_address[15:0] == 16'h64))
      if(ams_mem_write) mem_offset <= ams_mem_writedata[15:0];
  end
end

endmodule
