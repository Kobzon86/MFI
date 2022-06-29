module dev_info #(
parameter INPUT_CLOCK = 100_000_000
  )
(
  input               clk         ,
  input               reset       ,
  input        [ 2:0] ams_address ,
  input               ams_read    ,
  output logic [31:0] ams_readdata,
  output logic [31:0] ams_readdatavalid,

  input        [ 4:0] mkio_address ,
  input        [ 31:0] crc_in

);

`include "./version.svh"

localparam mSEC = INPUT_CLOCK/1000;
logic [31:0]msec_timer;
logic [31:0]runtime;
wire msec_event = (msec_timer == mSEC); 

logic [31:0] info_regs [7:0];
assign info_regs[0] = 32'h4D464441;// "MFDA"
assign info_regs[1] = mkio_address;
assign info_regs[2] = runtime;
assign info_regs[3] = 32'hA;// status
assign info_regs[4] = `number_version;//`include "./number_version.svh";
assign info_regs[5] = crc_in;
assign info_regs[6] = `timestmp; 
assign info_regs[7] = `hash; 

always_ff @( posedge clk or posedge reset )
    if( reset ) begin
      msec_timer <= '0;
      runtime <= '0;
      ams_readdata <= '0;
      msec_timer <= '0;
    end
    else begin
      ams_readdatavalid <= ams_read;
      msec_timer <= msec_event ? '0 : (msec_timer + 1'b1);
      runtime <= msec_event ? (runtime + 1) : runtime;
      if( ams_read ) ams_readdata <= info_regs[ams_address];
    else
      ams_readdata <= '0;
  end

endmodule 
