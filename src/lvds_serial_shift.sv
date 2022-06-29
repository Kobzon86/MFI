module lvds_serial_shift (
    input            serial_clock,
    input            serial_data ,
    input            clock       ,
    output reg [6:0] data
);

    (* altera_attribute = "-name FAST_INPUT_REGISTER on" *) logic serial_data_meta ;
    (* dont_replicate *) logic serial_data_latch;
    (* dont_replicate *) logic [6:0] data_shift;

    /*
    altddio_in #(
        .intended_device_family("Cyclone V" ),
        .invert_input_clocks   ("OFF"       ),
        .lpm_hint              ("UNUSED"    ),
        .lpm_type              ("altddio_in"),
        .power_up_high         ("OFF"       ),
        .width                 (1           )
    ) ALTDDIO_IN_component (
        .datain   (serial_data      ),
        .inclock  (serial_clock     ),
        .dataout_h(serial_data_latch),
        .inclocken(1'b1             )
    );
    */
    
    always @( posedge serial_clock )
        begin
            { serial_data_latch, serial_data_meta } <= { serial_data_meta, serial_data };
            data_shift                              <= { data_shift[5:0], serial_data_latch };
        end

    always @( posedge clock )
        begin
            data <= data_shift;
        end

endmodule