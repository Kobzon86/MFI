/*
 * LVDS Display Interface deserializer.
 */

module ldi_sdr_deserializer(
  
  input            serial_clock,
  input            serial_data,
  
  input            clock,
  output reg [6:0] data
  
);
  
  
  
  (* altera_attribute = "-name FAST_INPUT_REGISTER on" *) reg serial_data_meta;
  reg serial_data_latch;
  
  always @( posedge serial_clock ) begin
    { serial_data_latch, serial_data_meta } <= { serial_data_meta, serial_data };
  end
  
  
  
  reg [6:0] data_shift;
  
  always @( posedge serial_clock ) begin
    data_shift <= { data_shift[5:0], serial_data_latch };
  end
  
  
  
  always @( posedge clock ) begin
    data <= data_shift;
  end
  
  
  
endmodule
