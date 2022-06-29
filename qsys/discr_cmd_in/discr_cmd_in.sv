/*!
 * @brief 
 *
 *
 */

module discr_cmd_in #(
  
  parameter COUNT = 32
  
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
  
  output logic             vwet,
  output logic             ths_int,
  output logic             ths_sel,
  output logic             sense,
  input              [4:0] addr,
  input        [COUNT-1:0] dc_in
  
);
  
  
  
  logic       [4:0] addr_meta;
  logic       [4:0] addr_latch;
  logic             dc_vwet;
  logic             dc_ths_int;
  logic             dc_ths_sel;
  logic             dc_sense;
  logic [COUNT-1:0] dc_status;
  logic             dc_int_clear;
  logic             dc_int_ack;
  logic [COUNT-1:0] dc_int;
  logic [COUNT-1:0] dc_mask;
  
  logic       [1:0] ams_address_d;
  logic      [31:0] ams_writedata_d;
  
  enum logic[2:0] {
    AMS_STATE_IDLE  = 3'b001,
    AMS_STATE_WRITE = 3'b010,
    AMS_STATE_READ  = 3'b100,
    AMS_STATE_RESET = 3'b111
  } ams_state;
  
  always @( posedge clk or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      dc_vwet           <= 0;
      dc_ths_int        <= 0;
      dc_ths_sel        <= 0;
      dc_sense          <= 0;
      dc_int_clear      <= 0;
      dc_mask           <= {(COUNT){ 1'b0 }};
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
          ams_waitrequest <= 1'b0;
          ams_address_d   <= ams_address;
          ams_writedata_d <= ams_writedata;
          ams_state       <= AMS_STATE_WRITE;
        end else if( ams_read ) begin
          ams_waitrequest <= 1'b0;
          ams_address_d   <= ams_address;
          ams_writedata_d <= '0;
          ams_state       <= AMS_STATE_READ;
        end else begin
          ams_waitrequest <= 1'b1;
          ams_address_d   <= '0;
          ams_writedata_d <= '0;
        end
        if( dc_int_ack )
          dc_int_clear <= 1'b0;
        ams_readdatavalid <= 1'b0;
        ams_readdata      <= 32'h00000000;
      end
      
      AMS_STATE_WRITE: begin
        case( ams_address_d )
          0: begin
               dc_sense   <= ams_writedata_d[3]; // when 1: sensing +27V/Open
                                                 // when 0: sensing Open/Gnd
               dc_ths_sel <= ams_writedata_d[2]; // when 1: low to high threshold = 11.2V, high to low threshold =  6.4V
                                                 // when 0: low to high threshold =  9.7V, high to low threshold =  5.6V
               dc_ths_int <= ams_writedata_d[1]; // when 1: low to high threshold = 15.5V, high to low threshold = 11.0V
                                                 // when 0: used external threshold ( dc_ths_sel )
               dc_vwet    <= ams_writedata_d[0]; // when 1: pull-up circuite is connected to 27V
                                                 // when 0: pull-up circuite is disconnected
             end
          3: dc_mask <= ams_writedata_d[COUNT-1:0]; // IRQ mask
        endcase
        ams_waitrequest   <= 1'b1;
        ams_readdatavalid <= 1'b0;
        ams_readdata      <= 32'h00000000;
        ams_state         <= AMS_STATE_IDLE;
      end
      
      AMS_STATE_READ: begin
        ams_readdata = '0;
        case( ams_address_d )
          0: ams_readdata <= { addr_latch,23'b00000000000000000000000,  dc_sense, dc_ths_sel, dc_ths_int, dc_vwet }; // address, thresholds and pull-up settings
          1: begin 
            ams_readdata[26:0] <= dc_status;                                                                              // state of inputs
            ams_readdata[31:27] <= addr_latch;
            end                                                                             // state of inputs
          2: begin
               ams_readdata <= dc_int;                                                                               // IRQ flags
               dc_int_clear <= 1'b1;                                                                                 // clear IRQ flags on read
             end
          3: ams_readdata <= dc_mask;                                                                                // IRQ mask
          default: ams_readdata <= 32'h00000000;
        endcase
        ams_waitrequest   <= 1'b1;
        ams_readdatavalid <= 1'b1;
        ams_state         <= AMS_STATE_IDLE;
      end
      
      default: begin
        dc_vwet           <= 0;
        dc_ths_int        <= 0;
        dc_ths_sel        <= 0;
        dc_sense          <= 0;
        dc_int_clear      <= 0;
        dc_mask           <= {(COUNT){ 1'b0 }};
        ams_waitrequest   <= 1'b1;
        ams_readdatavalid <= 1'b0;
        ams_readdata      <= 32'h00000000;
        ams_state         <= AMS_STATE_IDLE;
      end
      
      endcase
      
    end
    
  end
  
  
  
  logic [COUNT-1:0] dc_status_d;
  logic [COUNT-1:0] dc_int_d;
  
  always @( posedge clk or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      dc_int_ack  <= 1'b0;
      dc_int      <= {(COUNT){ 1'b0 }};
      dc_int_d    <= {(COUNT){ 1'b0 }};
      addr_latch  <= 5'b00000;
      addr_meta   <= 5'b00000;
      dc_status   <= {(COUNT){ 1'b0 }};
      dc_status_d <= {(COUNT){ 1'b0 }};
      vwet        <= 1'b0;
      ths_int     <= 1'b0;
      ths_sel     <= 1'b0;
      sense       <= 1'b0;
      
    end else begin
      
      if( dc_int_clear ) begin
        dc_int_ack <= 1'b1;
        dc_int     <= {(COUNT){ 1'b0 }};
        dc_int_d   <= {(COUNT){ 1'b0 }};
      end else begin
        dc_int_ack <= 1'b0;
        dc_int     <= ( dc_int | ( ( dc_status ^ dc_status_d ) & dc_mask ) );
        dc_int_d   <= dc_int;
      end
      
      irq <= ( ( dc_int ^ dc_int_d ) ) ? 1'b1 : 1'b0;
      
      addr_latch <= addr_meta;
      addr_meta  <= addr;
      
      dc_status   <= dc_status_d;
      dc_status_d <= dc_in;
      
      vwet    <= ( dc_ths_int )  ? ( dc_vwet & ~dc_sense ) :
                 ( !dc_ths_sel ) ? dc_vwet :
                                   1'b0;
      sense   <= ( dc_ths_int ) ? dc_sense :
                 ( dc_ths_sel ) ? 1'b1 :
                                  1'b0;
      ths_sel <= dc_ths_sel;
      ths_int <= dc_ths_int;
      
    end
    
  end
  
  
  
endmodule : discr_cmd_in
