/*
 * Avalon-MM slave to I2C master bridge
 */

module ams_i2c #(
  
  parameter clock_freq = 50_000_000,
  parameter baudrate   = 100_000
  
)(
  
  input               reset_n,
  input               clock,
  
  // Avalon-MM Slave
  output logic        ams_waitrequest,
  input               ams_write,
  input               ams_read,
  input        [15:0] ams_address,
  input         [7:0] ams_writedata,
  output logic        ams_readdatavalid,
  output logic  [7:0] ams_readdata,
  
  // I2C
  inout               scl,
  inout               sda
  
);
  
  
  
  localparam i2c_clock_time = ( clock_freq / baudrate / 8 );
  
  logic  [2:0] i2c_clocks;
  logic [31:0] i2c_clock_cnt;
  
  always @( posedge clock or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      i2c_clocks    <= 0;
      i2c_clock_cnt <= 0;
      
    end else begin
      
      if( i2c_clock_cnt < ( i2c_clock_time - 1 ) )
        i2c_clock_cnt <= i2c_clock_cnt + 1;
      else begin
        i2c_clocks    <= i2c_clocks + 1;
        i2c_clock_cnt <= 0;
      end
      
    end
    
  end
  
  
  
  logic i2c_clock;
  logic i2c_clock_en;
  logic i2c_clock_2x;
  logic i2c_clock_in;
  logic i2c_data_in;
  logic i2c_data;
  
  assign i2c_clock    = i2c_clocks[2];
  assign i2c_clock_2x = i2c_clocks[1];
  assign scl          = ( i2c_clock_en && !i2c_clock ) ? 1'b0 : 1'bz;
  assign sda          = ( i2c_data == 1'b0 ) ? 1'b0 : 1'bz;
  assign i2c_clock_in = ( scl === 1'b0 ) ? 1'b0 : 1'b1;
  
  always @( posedge i2c_clock or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      i2c_data_in <= 1'b1;
      
    end else begin
      
      if( sda === 1'b0 )
        i2c_data_in <= 1'b0;
      else
        i2c_data_in <= 1'b1;
      
    end
    
  end
  
  
  
  logic i2c_write;
  logic i2c_read;
  logic i2c_busy;
  
  logic i2c_write_meta;
  logic i2c_read_meta;
  logic i2c_busy_meta;
  
  logic i2c_write_latch;
  logic i2c_read_latch;
  logic i2c_busy_latch;
  
  always @( posedge clock or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      { i2c_busy_latch, i2c_busy_meta } <= 2'b00;
      
    end else begin
      
      { i2c_busy_latch, i2c_busy_meta } <= { i2c_busy_meta, i2c_busy };
      
    end
    
  end
  
  always @( posedge i2c_clock or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      { i2c_write_latch, i2c_write_meta } <= 2'b00;
      { i2c_read_latch,  i2c_read_meta  } <= 2'b00;
      
    end else begin
      
      { i2c_write_latch, i2c_write_meta } <= { i2c_write_meta, i2c_write };
      { i2c_read_latch,  i2c_read_meta  } <= { i2c_read_meta,  i2c_read  };
      
    end
    
  end
  
  
  
  enum logic[3:0] {
    AMS_STATE_IDLE  = 4'b0001,
    AMS_STATE_WAIT  = 4'b0010,
    AMS_STATE_WRITE = 4'b0100,
    AMS_STATE_READ  = 4'b1000,
    AMS_STATE_RESET = 4'b1111
  } ams_state;
  
  logic [15:0] i2c_address;
  logic  [7:0] i2c_writedata;
  logic        i2c_readdatavalid;
  logic  [7:0] i2c_readdata;
  logic        i2c_dev_error;
  logic        i2c_reg_error;
  
  always @( posedge clock or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      i2c_write         <= 0;
      i2c_read          <= 0;
      i2c_address       <= 0;
      i2c_writedata     <= 0;
      ams_waitrequest   <= 1;
      ams_readdatavalid <= 0;
      ams_readdata      <= 0;
      ams_state         <= AMS_STATE_RESET;
      
    end else begin
      
      case( ams_state )
      
      AMS_STATE_IDLE: begin
        if( !i2c_busy_latch ) begin
          if( ams_write ) begin
            i2c_write       <= 1;
            i2c_read        <= 0;
            i2c_address     <= ams_address;
            i2c_writedata   <= ams_writedata;
            ams_waitrequest <= 0;
            ams_state       <= AMS_STATE_WAIT;
          end else if( ams_read ) begin
            i2c_write       <= 0;
            i2c_read        <= 1;
            i2c_address     <= ams_address;
            i2c_writedata   <= 0;
            ams_waitrequest <= 0;
            ams_state       <= AMS_STATE_WAIT;
          end else begin
            i2c_write       <= 0;
            i2c_read        <= 0;
            i2c_address     <= 0;
            i2c_writedata   <= 0;
            ams_waitrequest <= 1;
          end
        end
        ams_readdatavalid <= 0;
        ams_readdata      <= 0;
      end
      
      AMS_STATE_WAIT: begin
        if( i2c_busy_latch ) begin
          if( i2c_write )
            ams_state <= AMS_STATE_WRITE;
          else if( i2c_read )
            ams_state <= AMS_STATE_READ;
          else
            ams_state <= AMS_STATE_RESET;
          i2c_write <= 0;
          i2c_read  <= 0;
        end
        ams_waitrequest   <= 1;
        ams_readdatavalid <= 0;
        ams_readdata      <= 0;
      end
      
      AMS_STATE_WRITE: begin
        if( !i2c_busy_latch )
          ams_state <= AMS_STATE_IDLE;
        i2c_write         <= 0;
        i2c_read          <= 0;
        ams_waitrequest   <= 1;
        ams_readdatavalid <= 0;
        ams_readdata      <= 0;
      end
      
      AMS_STATE_READ: begin
        if( !i2c_busy_latch ) begin
          ams_readdatavalid <= 1;
          ams_readdata      <= ( i2c_address[8] ) ? { 6'b000000, i2c_reg_error, i2c_dev_error } : i2c_readdata;
          ams_state         <= AMS_STATE_IDLE;
        end
        i2c_write       <= 0;
        i2c_read        <= 0;
        ams_waitrequest <= 1;
      end
      
      default: begin
        i2c_write       <= 0;
        i2c_read        <= 0;
        i2c_address     <= 0;
        i2c_writedata   <= 0;
        ams_waitrequest <= 1;
        ams_state       <= AMS_STATE_IDLE;
      end
      
      endcase
      
    end
    
  end
  
  
  
  enum logic[6:0] {
    I2C_STATE_IDLE      = 7'b0000001,
    I2C_STATE_START     = 7'b0000010,
    I2C_STATE_RESTART   = 7'b0000100,
    I2C_STATE_DATA      = 7'b0001000,
    I2C_STATE_ACK       = 7'b0010000,
    I2C_STATE_STOP      = 7'b0100000,
    I2C_STATE_ACK_ERROR = 7'b1000000,
    I2C_STATE_RESET     = 7'b1111111
  } i2c_state;
  
  enum logic[3:0] {
    WORD_STATE_DEVICE  = 4'b0001,
    WORD_STATE_ADDRESS = 4'b0010,
    WORD_STATE_WRITE   = 4'b0100,
    WORD_STATE_READ    = 4'b1000,
    WORD_STATE_RESET   = 4'b1111
  } i2c_word;
  
  logic       i2c_read_op;
  logic       i2c_read_bit;
	logic       i2c_wait;
  logic [2:0] i2c_bit_cnt;
  logic [7:0] i2c_shift_data;
  
  always @( negedge i2c_clock or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      i2c_read_op       <= 0;
      i2c_read_bit      <= 0;
      i2c_dev_error     <= 0;
      i2c_reg_error     <= 0;
      i2c_bit_cnt       <= 0;
      i2c_shift_data    <= 8'h00;
      i2c_readdatavalid <= 0;
      i2c_readdata      <= 0;
      i2c_busy          <= 0;
      i2c_word          <= WORD_STATE_RESET;
      i2c_state         <= I2C_STATE_RESET;
      
    end else begin
      
      case( i2c_state )
      
      I2C_STATE_IDLE: begin
        if( i2c_write_latch || i2c_read_latch ) begin
          i2c_read_op <= i2c_read_latch;
          i2c_word    <= WORD_STATE_DEVICE;
          i2c_state   <= I2C_STATE_START;
        end
        i2c_busy       <= 0;
        i2c_read_bit   <= 0;
        i2c_dev_error  <= 0;
        i2c_reg_error  <= 0;
        i2c_bit_cnt    <= 0;
        i2c_shift_data <= 8'h00;
      end
      
      I2C_STATE_START, I2C_STATE_RESTART: begin
        i2c_bit_cnt       <= 7;
        i2c_shift_data    <= { i2c_address[15:9], i2c_read_bit };
        i2c_readdatavalid <= 0;
        i2c_readdata      <= 0;
        i2c_busy          <= 1;
        i2c_state         <= I2C_STATE_DATA;
      end
      
      I2C_STATE_DATA: begin
        if( i2c_bit_cnt > 0 ) begin
          if( !i2c_wait )
            i2c_bit_cnt <= i2c_bit_cnt - 1;
        end else begin
          i2c_state <= I2C_STATE_ACK;
        end
        i2c_readdatavalid <= 0;
        i2c_readdata      <= 0;
        i2c_busy          <= 1;
        i2c_shift_data    <= { i2c_shift_data[6:0], i2c_data_in };
      end
      
      I2C_STATE_ACK: begin
        case( i2c_word )
        WORD_STATE_DEVICE: begin
          if( !i2c_data_in ) begin
            if( i2c_read_bit )
              i2c_word <= WORD_STATE_READ;
            else
              i2c_word <= WORD_STATE_ADDRESS;
            i2c_dev_error  <= 0;
            i2c_reg_error  <= 0;
            i2c_bit_cnt    <= 7;
            i2c_shift_data <= i2c_address[7:0];
            i2c_state      <= I2C_STATE_DATA;
          end else begin
            i2c_dev_error <= 1;
            i2c_reg_error <= 0;
            i2c_read_bit  <= 0;
            i2c_word      <= WORD_STATE_RESET;
            i2c_state     <= I2C_STATE_STOP;
          end
          i2c_readdatavalid <= 0;
          i2c_readdata      <= 0;
        end
        WORD_STATE_ADDRESS: begin
          if( !i2c_data_in ) begin
            if( i2c_read_op ) begin
              i2c_read_bit  <= 1;
              i2c_word      <= WORD_STATE_DEVICE;
              i2c_state     <= I2C_STATE_RESTART;
            end else begin
              i2c_read_bit   <= 0;
              i2c_bit_cnt    <= 7;
              i2c_shift_data <= i2c_writedata;
              i2c_word       <= WORD_STATE_WRITE;
              i2c_state      <= I2C_STATE_DATA;
            end
          end else begin
            i2c_dev_error <= 0;
            i2c_reg_error <= 1;
            i2c_read_bit  <= 0;
            i2c_word      <= WORD_STATE_RESET;
            i2c_state     <= I2C_STATE_STOP;
          end
          i2c_readdatavalid <= 0;
          i2c_readdata      <= 0;
        end
        WORD_STATE_READ: begin
          i2c_dev_error     <= 0;
          i2c_reg_error     <= 0;
          i2c_read_bit      <= 0;
          i2c_word          <= WORD_STATE_RESET;
          i2c_state         <= I2C_STATE_STOP;
          i2c_readdatavalid <= 1;
          i2c_readdata      <= i2c_shift_data;
        end
        default: begin
          i2c_dev_error     <= 0;
          i2c_reg_error     <= 0;
          i2c_read_bit      <= 0;
          i2c_readdatavalid <= 0;
          i2c_readdata      <= 0;
          i2c_word          <= WORD_STATE_RESET;
          i2c_state         <= I2C_STATE_STOP;
        end
        endcase
        i2c_busy <= 1;
      end
      
      I2C_STATE_STOP: begin
        i2c_busy  <= 1;
        i2c_word  <= WORD_STATE_RESET;
        i2c_state <= I2C_STATE_IDLE;
      end
      
      default: begin
        i2c_read_op       <= 0;
        i2c_read_bit      <= 0;
        i2c_dev_error     <= 0;
        i2c_reg_error     <= 0;
        i2c_bit_cnt       <= 0;
        i2c_shift_data    <= 8'h00;
        i2c_readdatavalid <= 0;
        i2c_readdata      <= 0;
        i2c_busy          <= 0;
        i2c_word          <= WORD_STATE_RESET;
        i2c_state         <= I2C_STATE_IDLE;
      end
      
      endcase
      
    end
    
  end
  
  
  
  always @( posedge i2c_clock_2x or negedge reset_n ) begin
    
    if( !reset_n ) begin
      
      i2c_clock_en <= 1'b0;
      i2c_data     <= 1'b1;
      
    end else begin
      
      if( i2c_clock )
        i2c_wait <= !i2c_clock_in;
      else
        i2c_wait <= 1'b0;
      
      case( i2c_state )
      
      I2C_STATE_START, I2C_STATE_RESTART: begin
        if( i2c_clock )
          i2c_clock_en <= 1'b1;
        i2c_data <= ~i2c_clock;
      end
      
      I2C_STATE_DATA: begin
        case( i2c_word )
          WORD_STATE_READ: begin
            i2c_data <= 1'b1;
          end
          default: begin
            i2c_data <= i2c_shift_data[7];
          end
        endcase
        i2c_clock_en <= 1'b1;
      end
      
      I2C_STATE_ACK: begin
        i2c_clock_en <= 1'b1;
        i2c_data     <= 1'b1;
      end
      
      I2C_STATE_STOP: begin
        if( i2c_clock )
          i2c_clock_en <= 1'b0;
        i2c_data <= i2c_clock;
      end
      
      default: begin
        i2c_clock_en <= 1'b0;
        i2c_data     <= 1'b1;
      end
      
      endcase
      
    end
    
  end
  
  
  
endmodule : ams_i2c
