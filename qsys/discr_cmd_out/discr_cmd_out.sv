/*!
 * @brief 
 *
 *
 */

module discr_cmd_out #(
  
  parameter CLOCK_FREQ = 0,
  parameter TIMEOUT_MS = 0,
  parameter COUNT      = 32
  
)(
  
  input clk,
  input reset_n,
  
  output logic        ams_waitrequest,
  input               ams_write,
  input               ams_read,
  input         [1:0] ams_address,
  input        [31:0] ams_writedata,
  output logic        ams_readdatavalid,
  output logic [31:0] ams_readdata,
  
  output logic irq,
  
  input        [COUNT-1:0] fault,
  output logic [COUNT-1:0] out
  
);
  
  
  
  localparam PERIOD_MS = ( CLOCK_FREQ / 1000 );
  localparam TIMEOUT   = ( TIMEOUT_MS * PERIOD_MS );
  
  logic           [COUNT-1:0] dc_control;
  logic           [COUNT-1:0] dc_status;
  logic [$clog2(TIMEOUT)-1:0] dc_timer;
  logic                       dc_timeout;
  
  logic       [1:0] ams_address_d;
  logic [COUNT-1:0] ams_writedata_d;
  
  enum logic[2:0] {
    AMS_STATE_IDLE  = 3'b001,
    AMS_STATE_WRITE = 3'b010,
    AMS_STATE_READ  = 3'b100,
    AMS_STATE_RESET = 3'b111
  } ams_state;
  
  always @( posedge clk or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      dc_control        <= {(COUNT){ 1'b0 }};
      dc_timer          <= {($clog2(TIMEOUT)){ 1'b0 }};
      dc_timeout        <= 1'b0;
      ams_waitrequest   <= 1'b1;
      ams_readdatavalid <= 1'b0;
      ams_readdata      <= 32'h00000000;
      ams_address_d     <= 2'b00;
      ams_writedata_d   <= 32'h00000000;
      ams_state         <= AMS_STATE_RESET;
      
    end else begin
      
      case( ams_state )
      
      AMS_STATE_IDLE: begin
        if( ams_write ) begin
          ams_waitrequest  <= 1'b0;
          ams_address_d    <= ams_address;
          ams_writedata_d  <= ams_writedata;
          dc_timer         <= {($clog2(TIMEOUT)){ 1'b0 }};
          dc_timeout       <= 1'b0;
          ams_state        <= AMS_STATE_WRITE;
        end else if( ams_read ) begin
          ams_waitrequest  <= 1'b0;
          ams_address_d    <= ams_address;
          ams_writedata_d  <= 32'h00000000;
          dc_timer         <= {($clog2(TIMEOUT)){ 1'b0 }};
          dc_timeout       <= 1'b0;
          ams_state        <= AMS_STATE_READ;
        end else begin
          if( TIMEOUT > 0 ) begin
            if( dc_timer < ( TIMEOUT - 1 ) ) begin
              dc_timer   <= dc_timer + { {($clog2(TIMEOUT)-1){ 1'b0 }}, 1'b1 };
              dc_timeout <= 1'b0;
            end else begin
              dc_timeout <= 1'b1;
            end
          end else begin
            dc_timer   <= {($clog2(TIMEOUT)){ 1'b0 }};
            dc_timeout <= 1'b0;
          end
          ams_waitrequest <= 1'b1;
          ams_address_d   <= 2'b00;
          ams_writedata_d <= 32'h00000000;
        end
        ams_readdatavalid <= 1'b0;
        ams_readdata      <= 32'h00000000;
      end
      
      AMS_STATE_WRITE: begin
        case( ams_address_d )
          0: dc_control <= ams_writedata_d[COUNT-1:0];
        endcase
        ams_waitrequest   <= 1'b1;
        ams_readdatavalid <= 1'b0;
        ams_readdata      <= 32'h00000000;
        ams_state         <= AMS_STATE_IDLE;
      end
      
      AMS_STATE_READ: begin
        ams_readdata = '0;
        case( ams_address_d )
          0:       ams_readdata <= dc_control;
          1:       ams_readdata <= dc_status;
          default: ams_readdata <= 32'hDEADC0DE;
        endcase
        ams_waitrequest   <= 1'b1;
        ams_readdatavalid <= 1'b1;
        ams_state         <= AMS_STATE_IDLE;
      end
      
      default: begin
        dc_control        <= {(COUNT){ 1'b0 }};
        dc_timer          <= {($clog2(TIMEOUT)){ 1'b0 }};
        dc_timeout        <= 1'b0;
        ams_waitrequest   <= 1'b1;
        ams_readdatavalid <= 1'b0;
        ams_readdata      <= 32'h00000000;
        ams_state         <= AMS_STATE_IDLE;
      end
      
      endcase
      
    end
    
  end
  
  
  
  logic [COUNT-1:0] dc_control_d;
  logic [COUNT-1:0] dc_status_d;
  
  always @( posedge clk or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      dc_status    <= {(COUNT){ 1'b0 }};
      dc_status_d  <= {(COUNT){ 1'b0 }};
      dc_control_d <= {(COUNT){ 1'b0 }};
      out          <= {(COUNT){ 1'b0 }};
      
    end else begin
      
      dc_status   <= fault;
      dc_status_d <= dc_status;
      
      irq <= ( ( dc_status ^ dc_status_d ) ) ? 1'b1 : 1'b0;
      
      dc_control_d <= dc_control & ~dc_status;
      out          <= ( !dc_timeout ) ? dc_control_d : {(COUNT){ 1'b0 }};
      
    end
    
  end
  
  
  
endmodule : discr_cmd_out
