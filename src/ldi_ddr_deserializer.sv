/*
 * LVDS Display Interface deserializer.
 */

module ldi_ddr_deserializer(
  
  input            serial_clock,
  input            serial_data,
  
  input            clock,
  output reg [6:0] data
  
);
  
  
  
  (* altera_attribute = "-name FAST_INPUT_REGISTER on" *) reg serial_data_rise_meta;
  reg serial_data_rise_latch;
  
  always @( posedge serial_clock ) begin
    { serial_data_rise_latch, serial_data_rise_meta } <= { serial_data_rise_meta, serial_data };
  end
  
  
  
  (* altera_attribute = "-name FAST_INPUT_REGISTER on" *) reg serial_data_fall_meta;
  reg serial_data_fall_latch;
  
  always @( negedge serial_clock ) begin
    { serial_data_fall_latch, serial_data_fall_meta } <= { serial_data_fall_meta, serial_data };
  end
  
  
  
  reg [3:0] data_rise_shift;
  
  always @( posedge serial_clock ) begin
    data_rise_shift <= { data_rise_shift[2:0], serial_data_rise_latch };
  end
  
  
  
  reg [3:0] data_fall_shift;
  
  always @( negedge serial_clock ) begin
    data_fall_shift <= { data_fall_shift[2:0], serial_data_fall_latch };
  end
  
  
  
  reg [7:0] data_shift;
  
  always @( posedge serial_clock ) begin
    data_shift <= { data_rise_shift[3], data_fall_shift[3],
                    data_rise_shift[2], data_fall_shift[2],
                    data_rise_shift[1], data_fall_shift[1],
                    data_rise_shift[0], data_fall_shift[0] };
  end
  
  
  
  reg serial_clock_meta;
  reg serial_clock_latch;
  
  always @( posedge clock ) begin
    
    if( serial_clock_latch == 1'b1 )
      data <= data_shift[7:1];
    else
      data <= data_shift[6:0];
    
    { serial_clock_latch, serial_clock_meta } <= { serial_clock_meta, serial_clock };
    
  end
  
  
  
endmodule
