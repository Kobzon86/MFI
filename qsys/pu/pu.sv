/*
 * PU communication module
 */

module pu #(
  
  parameter        CLOCK_FREQ         = 100000000,
  parameter        PWM_FREQ           = 1000,
  parameter        DEFAULT_LIGHT      = 16,
  parameter [31:0] PU_BASE_ADDRESS    = 32'h00000000,
  parameter [31:0] COEF_BASE_ADDRESS  = 32'h00000000,
  parameter        LCD_DAC_TYPE       = "PWM",
  parameter        PU_DAC_TYPE        = "SIGMA-DELTA"
  
)(
  
  input               reset_n,
  input               clock,
  
  // Avalon-MM Slave
  output logic        ams_waitrequest,
  input               ams_write,
  input               ams_read,
  input         [3:0] ams_byteenable,
  input         [2:0] ams_address,
  input        [31:0] ams_writedata,
  output logic        ams_readdatavalid,
  output logic [31:0] ams_readdata,
  
  // Avalon-MM Master to I2C core
  input               amm_waitrequest,
  output logic        amm_write,
  output logic        amm_read,
  output logic [31:0] amm_address,
  output logic  [7:0] amm_writedata,
  input               amm_readdatavalid,
  input         [7:0] amm_readdata,
  
  //Avalon-MM Master to backlight ROM
  input               bklt_waitrequest,
  output logic        bklt_read,
  output logic [31:0] bklt_address,
  input               bklt_readdatavalid,
  input        [31:0] bklt_readdata,
  
  input               backlight_night,
  input               backlight_bite,
  input               backlight_fault_n,
  output        [1:0] backlight_drv_en,
  output        [1:0] backlight_out_en_n,
  output        [2:0] backlight_pwm,
  
  output              fhd_reset_n,
  output              fhd_reset_req,
  
  output              xga_reset_n,
  output              xga_reset_req,
  
  output              vga_reset_n,
  output              vga_reset_req,
  
  output              pu_ready_reset_n,
  output              pu_ready_reset_req,
  
  output        [1:0] pu_type
  
);
  
  
  
  localparam PU_TYPE_UNKNOWN = 2'b11;
  localparam PU_TYPE_15INCH  = 2'b10;
  localparam PU_TYPE_12INCH  = 2'b01;
  localparam PU_TYPE_10INCH  = 2'b00;
  
  
  
  localparam PWM_CHANNELS  = 3;
  localparam PWM_WIDTH     = 12;
  localparam PWM_PRESCALER = CLOCK_FREQ / ( 2 ** PWM_WIDTH ) / PWM_FREQ;
  
  
  
  typedef enum {
    OP_WRITE,
    OP_READ
  } t_operation;
  
  typedef struct packed {
    t_operation operation;
    logic [7:0] device;
    logic [7:0] register;
    logic [7:0] data;
  } t_op_array;
  
  localparam [7:0] PU_TYPE_ADDR                     = 8'h42;
  localparam [7:0] PU_TYPE_VALUE                    = 8'h01;
  localparam [7:0] PU_TYPE_POLARITY                 = 8'h05;
  localparam [7:0] PU_TYPE_DIRECTION                = 8'h07;
  
  localparam [7:0] PU_BTN_ADDR                      = 8'h40;
  
  localparam [7:0] PU_BTN_READ_H1_H2_H3_H4_H5       = 8'h01;
  localparam [7:0] PU_BTN_SEL_V4_V5_V6_V7_V8        = 8'h02;
  localparam [7:0] PU_BTN_SEL_V1_V2_V3              = 8'h03;
  
  localparam [7:0] PU_BTN_POLARITY0                 = 8'h04;
  localparam [7:0] PU_BTN_POLARITY1                 = 8'h05;
  localparam [7:0] PU_BTN_DIRECTION0                = 8'h06;
  localparam [7:0] PU_BTN_DIRECTION1                = 8'h07;
  
  localparam [7:0] PU_ENC_ADDR                      = 8'h42;
  localparam [7:0] PU_ENC_VALUE                     = 8'h00;
  localparam [7:0] PU_ENC_POLARITY                  = 8'h04;
  localparam [7:0] PU_ENC_DIRECTION                 = 8'h06;
  
  localparam [7:0] PU_LIGHT_LEFT_ADDR               = 8'h94;
  localparam [7:0] PU_LIGHT_RIGHT_ADDR              = 8'h96;
  localparam [7:0] PU_LIGHT_CFG                     = 8'h02;
  localparam [7:0] PU_LIGHT_E3_E2_E1_E0_M7_M6_M5_M4 = 8'h03;
  localparam [7:0] PU_LIGHT_M3_M2_M1_M0             = 8'h04;
  
  localparam [7:0] MCU_ADDR                         = 8'h60;
  localparam [7:0] MCU_EXT_LIGHT_LSB                = 8'h08;
  localparam [7:0] MCU_EXT_LIGHT_MSB                = 8'h09;
  localparam [7:0] MCU_POWER_STATUS                 = 8'h0B;
  
  localparam [7:0] I2C_ERROR_ADDR                   = 8'h01;
  localparam [7:0] I2C_ERROR_REG                    = 8'h00;
  
  localparam init_array_length = 8'd12;
  t_op_array [init_array_length-1:0] init_array = { { OP_WRITE, PU_ENC_ADDR,         PU_ENC_DIRECTION,                 8'hFF },
                                                    { OP_WRITE, PU_ENC_ADDR,         PU_ENC_POLARITY,                  8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V1_V2_V3,              8'h07 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V4_V5_V6_V7_V8,        8'h1F },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_DIRECTION1,                8'hF8 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_DIRECTION0,                8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_POLARITY1,                 8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_POLARITY0,                 8'h00 },
                                                    { OP_WRITE, PU_LIGHT_RIGHT_ADDR, PU_LIGHT_CFG,                     8'hC3 },
                                                    { OP_WRITE, PU_LIGHT_LEFT_ADDR,  PU_LIGHT_CFG,                     8'hC3 },
                                                    { OP_WRITE, PU_TYPE_ADDR,        PU_TYPE_DIRECTION,                8'hC0 },
                                                    { OP_WRITE, PU_TYPE_ADDR,        PU_TYPE_POLARITY,                 8'h00 } };
  
  localparam work_array_length = 8'd44;
  t_op_array [work_array_length-1:0] work_array = { { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  MCU_ADDR,            MCU_EXT_LIGHT_LSB,                8'h00 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  MCU_ADDR,            MCU_EXT_LIGHT_MSB,                8'h00 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  MCU_ADDR,            MCU_POWER_STATUS,                 8'h00 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_LIGHT_RIGHT_ADDR, PU_LIGHT_M3_M2_M1_M0,             8'h00 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_LIGHT_RIGHT_ADDR, PU_LIGHT_E3_E2_E1_E0_M7_M6_M5_M4, 8'h00 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_LIGHT_LEFT_ADDR,  PU_LIGHT_M3_M2_M1_M0,             8'h00 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_LIGHT_LEFT_ADDR,  PU_LIGHT_E3_E2_E1_E0_M7_M6_M5_M4, 8'h00 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_ENC_ADDR,         PU_ENC_VALUE,                     8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V4_V5_V6_V7_V8,        8'h1F },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_BTN_ADDR,         PU_BTN_READ_H1_H2_H3_H4_H5,       8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V4_V5_V6_V7_V8,        8'h0F },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_BTN_ADDR,         PU_BTN_READ_H1_H2_H3_H4_H5,       8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V4_V5_V6_V7_V8,        8'h17 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_BTN_ADDR,         PU_BTN_READ_H1_H2_H3_H4_H5,       8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V4_V5_V6_V7_V8,        8'h1B },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_BTN_ADDR,         PU_BTN_READ_H1_H2_H3_H4_H5,       8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V4_V5_V6_V7_V8,        8'h1D },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_BTN_ADDR,         PU_BTN_READ_H1_H2_H3_H4_H5,       8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V4_V5_V6_V7_V8,        8'h1E },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V1_V2_V3,              8'h07 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_BTN_ADDR,         PU_BTN_READ_H1_H2_H3_H4_H5,       8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V1_V2_V3,              8'h06 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_BTN_ADDR,         PU_BTN_READ_H1_H2_H3_H4_H5,       8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V1_V2_V3,              8'h05 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_BTN_ADDR,         PU_BTN_READ_H1_H2_H3_H4_H5,       8'h00 },
                                                    { OP_WRITE, PU_BTN_ADDR,         PU_BTN_SEL_V1_V2_V3,              8'h03 },
                                                    { OP_READ,  I2C_ERROR_ADDR,      I2C_ERROR_REG,                    8'h00 },
                                                    { OP_READ,  PU_TYPE_ADDR,        PU_TYPE_VALUE,                    8'h00 } };
  
  
  
  logic [1:0] pu_type_reg;
  
  logic                [39:0] buttons_state;
  
  logic                 [1:0] enc_state[3:0];
  
  logic                       enc_clear[3:0];
  logic                       enc_clear_ack[3:0];
  logic                 [3:0] enc_cnt[3:0];
  
  logic                       light_cnt_req;
  logic                       light_cnt_ack;
  logic                       light_manual;
  logic                       light_manual_d;
  logic                       light_remote;
  logic                       light_remote_d;
  logic                 [4:0] light_cnt;
  logic                 [4:0] light_cnt_d;
  
  logic                [11:0] illuminance_left;
  logic                [11:0] illuminance_right;
  
  logic                 [3:0] pwr_status_mcu;
  logic                 [4:0] light_mcu;
  
  logic                       amm_init_done;
  logic                       amm_transaction;
  logic                [31:0] amm_address_d;
  logic                 [7:0] amm_data_d;
  logic                 [7:0] amm_index;
  
  enum logic[3:0] {
    AMM_IDLE  = 4'b0001,
    AMM_WRITE = 4'b0010,
    AMM_READ  = 4'b0100,
    AMM_ACK   = 4'b1000,
    AMM_RESET = 4'b1111
  } amm_state;
  
  integer i;
  
  always @( posedge clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      for( i = 0; i < 4; i = i + 1 ) begin
        enc_clear_ack[i] <= 1'b0;
        enc_state[i]     <= {(2){ 1'b0 }};
        enc_cnt[i]       <= {(4){ 1'b0 }};
      end
      pu_type_reg       <= {(2){ 1'b0 }};
      buttons_state     <= {(40){ 1'b0 }};
      light_cnt_ack     <= 1'b0;
      light_manual      <= 1'b0;
      light_remote      <= 1'b0;
      light_cnt         <= {(5){ 1'b0 }};
      illuminance_left  <= {(12){ 1'b0 }};
      illuminance_right <= {(12){ 1'b0 }};
      pwr_status_mcu    <= {(4){ 1'b0 }};
      light_mcu         <= {(5){ 1'b0 }};
      amm_write         <= 1'b0;
      amm_read          <= 1'b0;
      amm_address       <= 32'h00000000;
      amm_writedata     <= 8'h00;
      amm_transaction   <= 1'b0;
      amm_address_d     <= 32'h00000000;
      amm_data_d        <= 8'h00;
      amm_init_done     <= 1'b0;
      amm_index         <= {(8){ 1'b0 }};
      amm_state         <= AMM_RESET;
      
    end else begin
      
      case( amm_state )
        
        AMM_IDLE: begin
          if( !amm_init_done ) begin
            if( amm_index < init_array_length ) begin
              if( init_array[amm_index].operation == OP_WRITE ) begin
                amm_address_d <= { PU_BASE_ADDRESS[31:16], init_array[amm_index].device, init_array[amm_index].register };
                amm_data_d    <= init_array[amm_index].data;
                amm_state     <= AMM_WRITE;
              end else begin
                amm_address_d <= { PU_BASE_ADDRESS[31:16], init_array[amm_index].device, init_array[amm_index].register };
                amm_state     <= AMM_READ;
              end
            end else begin
              amm_init_done <= 1'b1;
              amm_index     <= 8'd0;
            end
          end else if( amm_index < work_array_length ) begin
            if( work_array[amm_index].operation == OP_WRITE ) begin
              amm_address_d <= { work_array[amm_index].device, work_array[amm_index].register };
              amm_data_d    <= work_array[amm_index].data;
              amm_state     <= AMM_WRITE;
            end else begin
              amm_address_d <= { work_array[amm_index].device, work_array[amm_index].register };
              amm_state     <= AMM_READ;
            end
          end else begin
            amm_index <= 8'd0;
          end
          for( i = 0; i < 4; i = i + 1 ) begin
            if( enc_clear[i] ) begin
              enc_cnt[i]       <= 1'b0;
              enc_clear_ack[i] <= 1'b1;
            end else begin
              enc_clear_ack[i] <= 1'b0;
            end
          end
          if( light_cnt_req ) begin
            light_cnt_ack <= 1'b1;
            light_manual  <= light_manual_d;
            light_remote  <= light_remote_d;
            light_cnt     <= light_cnt_d;
          end else begin
            light_cnt_ack <= 1'b0;
          end
          amm_write       <= 1'b0;
          amm_read        <= 1'b0;
          amm_address     <= 32'h00000000;
          amm_writedata   <= 8'h00;
          amm_transaction <= 1'b0;
        end
        
        AMM_WRITE: begin
          if( !amm_waitrequest && amm_transaction ) begin
            amm_write     <= 1'b0;
            amm_read      <= 1'b0;
            amm_address   <= 32'h00000000;
            amm_writedata <= 8'h00;
            amm_index     <= amm_index + 8'd1;
            amm_state     <= AMM_IDLE;
          end else begin
            amm_write       <= 1'b1;
            amm_read        <= 1'b0;
            amm_address     <= amm_address_d;
            amm_writedata   <= amm_data_d;
            amm_transaction <= 1'b1;
          end
        end
        
        AMM_READ: begin
          if( !amm_waitrequest && amm_transaction ) begin
            amm_write     <= 1'b0;
            amm_read      <= 1'b0;
            amm_address   <= 32'h00000000;
            amm_writedata <= 8'h00;
            amm_state     <= AMM_ACK;
          end else begin
            amm_write       <= 1'b0;
            amm_read        <= 1'b1;
            amm_address     <= amm_address_d;
            amm_writedata   <= 8'h00;
            amm_transaction <= 1'b1;
          end
        end
        
        AMM_ACK: begin
          if( amm_readdatavalid ) begin
            if( amm_init_done && ( amm_readdata[1:0] == 2'b00 ) ) begin
              case( amm_index )
                8'd1:  pu_type_reg          <= amm_data_d[7:6];
                8'd4:  buttons_state[39:35] <= amm_data_d[7:3];
                8'd7:  buttons_state[34:30] <= amm_data_d[7:3];
                8'd10: buttons_state[29:25] <= amm_data_d[7:3];
                8'd14: buttons_state[24:20] <= amm_data_d[7:3];
                8'd17: buttons_state[19:15] <= amm_data_d[7:3];
                8'd20: buttons_state[14:10] <= amm_data_d[7:3];
                8'd23: buttons_state[9:5]   <= amm_data_d[7:3];
                8'd26: buttons_state[4:0]   <= amm_data_d[7:3];
                8'd29: begin
                  for( i = 0; i < 4; i = i + 1 ) begin
                    case( { enc_state[i], amm_data_d[i*2+:2] } )
                      4'h1, 4'h7, 4'h8, 4'hE: enc_cnt[i] <= ( enc_cnt[i] != 4'd7 ) ? enc_cnt[i] + 4'd1 : 4'd7;
                      4'h2, 4'h4, 4'hB, 4'hD: enc_cnt[i] <= ( enc_cnt[i] != 4'd9 ) ? enc_cnt[i] - 4'd1 : 4'd9;
                      default:                enc_cnt[i] <= 4'd0;
                    endcase
                    enc_state[i] <= amm_data_d[i*2+:2];
                  end
                  if( !light_remote ) begin
                    case( { enc_state[0], amm_data_d[1:0] } )
                      4'h1, 4'h7, 4'h8, 4'hE: light_cnt <= ( light_cnt < 5'd31 ) ? light_cnt + 5'd1 : 5'd31;
                      4'h2, 4'h4, 4'hB, 4'hD: light_cnt <= ( light_cnt >  5'd1 ) ? light_cnt - 5'd1 : light_cnt;
                      default: begin end
                    endcase
                  end
                end
                8'd31: illuminance_left[11:4]  <= amm_data_d;
                8'd33: illuminance_left[3:0]   <= amm_data_d[3:0];
                8'd35: illuminance_right[11:4] <= amm_data_d;
                8'd37: illuminance_right[3:0]  <= amm_data_d[3:0];
                8'd39: pwr_status_mcu          <= amm_data_d[3:0];
                8'd41: light_mcu[4:1]          <= amm_data_d[3:0];
                8'd43: light_mcu[0]            <= amm_data_d[7];
                default: begin end
              endcase
            end
            amm_data_d <= amm_readdata;
            amm_index  <= amm_index + 8'd1;
            amm_state  <= AMM_IDLE;
          end
          amm_write       <= 1'b0;
          amm_read        <= 1'b0;
          amm_address     <= 32'h00000000;
          amm_writedata   <= 8'h00;
          amm_transaction <= 1'b0;
        end
        
        default: begin
          for( i = 0; i < 4; i = i + 1 ) begin
            enc_clear_ack[i] <= 1'b0;
            enc_state[i]     <= {(2){ 1'b0 }};
            enc_cnt[i]       <= {(4){ 1'b0 }};
          end
          pu_type_reg       <= {(2){ 1'b0 }};
          buttons_state     <= {(40){ 1'b0 }};
          light_cnt_ack     <= 1'b0;
          light_manual      <= 1'b0;
          light_remote      <= 1'b0;
          light_cnt         <= DEFAULT_LIGHT;
          illuminance_left  <= {(12){ 1'b0 }};
          illuminance_right <= {(12){ 1'b0 }};
          pwr_status_mcu    <= {(4){ 1'b0 }};
          light_mcu         <= {(5){ 1'b0 }};
          amm_write         <= 1'b0;
          amm_read          <= 1'b0;
          amm_address       <= 32'h00000000;
          amm_writedata     <= 8'h00;
          amm_transaction   <= 1'b0;
          amm_address_d     <= 32'h00000000;
          amm_data_d        <= 8'h00;
          amm_init_done     <= 1'b0;
          amm_index         <= {(8){ 1'b0 }};
          amm_state         <= AMM_IDLE;
        end
        
      endcase
      
    end
    
  end
  
  
  
  logic [4:0] illuminance_left_value;
  logic [4:0] illuminance_right_value;
  wire [6:0] illuminance_left_norm  = ({2'd0,illuminance_left_value}<<1) + illuminance_left_value + (illuminance_left_value>>2);// illuminance_left_norm * 3.25
  wire [6:0] illuminance_right_norm = ({2'd0,illuminance_right_value}<<1) + illuminance_right_value + (illuminance_right_value>>2);
  logic [4:0] illuminance_max;
  logic [4:0] illuminance_avg;
  
  lum_conv lum_conv_left_i (
    .clock   ( clock                  ),
    .reset_n ( reset_n                ),
    .lum_e   ( illuminance_left[11:8] ),
    .lum_m   ( illuminance_left[7:0]  ),
    .lum_out ( illuminance_left_value )
  );
  
  lum_conv lum_conv_right_i (
    .clock   ( clock                   ),
    .reset_n ( reset_n                 ),
    .lum_e   ( illuminance_right[11:8] ),
    .lum_m   ( illuminance_right[7:0]  ),
    .lum_out ( illuminance_right_value )
  );
  
  assign illuminance_max = ( illuminance_left_value > illuminance_right_value ) ? illuminance_left_value : illuminance_right_value;
  
  lum_filter #(
    .WIDTH   ( 5     ),
    .COEFF_X ( 1     ),
    .COEFF_Y ( 65535 )
  ) lum_filter_i (
    .clock   ( clock           ),
    .reset_n ( reset_n         ),
    .value_i ( illuminance_max ),
    .value_o ( illuminance_avg )
  );
  
  
  
  logic  [3:0] ams_byteenable_d;
  logic  [2:0] ams_address_d;
  logic [31:0] ams_writedata_d;
  logic [27:0] ams_access_counter;
  
  enum logic[2:0] {
    AMS_STATE_IDLE  = 3'b001,
    AMS_STATE_WRITE = 3'b010,
    AMS_STATE_READ  = 3'b100,
    AMS_STATE_RESET = 3'b111
  } ams_state;
  
  integer j;
  
  always @( posedge clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      for( j = 0; j < 4; j = j + 1 )
        enc_clear[j] <= 1'b0;
      light_manual_d     <= 1'b0;
      light_remote_d     <= 1'b0;
      light_cnt_d        <= {(5){ 1'b0 }};
      light_cnt_req      <= 1'b0;
      ams_waitrequest    <= 1'b1;
      ams_readdatavalid  <= 1'b0;
      ams_readdata       <= 32'h00000000;
      ams_address_d      <= 3'b000;
      ams_writedata_d    <= 32'h00000000;
      ams_access_counter <= 28'd0;
      ams_state          <= AMS_STATE_RESET;
      
    end else begin
      
      case( ams_state )
        
        AMS_STATE_IDLE: begin
          if( ams_write ) begin
            ams_waitrequest    <= 1'b0;
            ams_byteenable_d   <= ams_byteenable;
            ams_address_d      <= ams_address;
            ams_writedata_d    <= ams_writedata;
            ams_access_counter <= ams_access_counter + 28'd1;
            ams_state          <= AMS_STATE_WRITE;
          end else if( ams_read ) begin
            ams_waitrequest    <= 1'b0;
            ams_byteenable_d   <= ams_byteenable;
            ams_address_d      <= ams_address;
            ams_writedata_d    <= 32'h00000000;
            ams_access_counter <= ams_access_counter + 28'd1;
            ams_state          <= AMS_STATE_READ;
          end else begin
            ams_waitrequest <= 1'b1;
            ams_address_d   <= 3'd0;
            ams_writedata_d <= 32'h00000000;
          end
          for( j = 0; j < 4; j = j + 1 ) begin
            if( enc_clear_ack[j] )
              enc_clear[j] <= 0;
          end
          if( light_cnt_ack )
            light_cnt_req <= 1'b0;
          ams_readdatavalid <= 1'b0;
          ams_readdata      <= 32'h00000000;
        end
        
        AMS_STATE_WRITE: begin
          case( ams_address_d )
            3'd1: begin
              light_cnt_req  <= 1'b1;
              light_manual_d <= ams_writedata_d[6];
              light_remote_d <= ams_writedata_d[5];
              light_cnt_d    <= ams_writedata_d[4:0];
            end
            3'd6: for( j = 0; j < 4; j = j + 1 )
              enc_clear[j] <= ( ams_byteenable_d[j] == 1'b1 ) ? 1'b1 : enc_clear[j];
            default: begin end
          endcase
          ams_waitrequest   <= 1'b1;
          ams_readdatavalid <= 1'b0;
          ams_readdata      <= 32'h00000000;
          ams_state         <= AMS_STATE_IDLE;
        end
        
        AMS_STATE_READ: begin
          case( ams_address_d )
            3'd0: ams_readdata <= { ams_access_counter, 6'b00, pu_type_latch[3:2] };
            3'd1: ams_readdata <= {9'd0,illuminance_right_norm,9'd0,illuminance_left_norm};//{ 8'h00, 3'b000, illuminance_avg, 8'h00, 1'b0, light_manual, light_remote, light_cnt };
            3'd2: ams_readdata <= ~buttons_state[31:0];
            3'd3: ams_readdata <= { 24'h000000, ~buttons_state[39:32] };
            3'd6: for( j = 0; j < 4; j = j + 1 ) begin
              enc_clear[j]         <= ( ams_byteenable_d[j] == 1'b1 ) ? 1'b1 : enc_clear[j];
              ams_readdata[j*8+:8] <= ( ams_byteenable_d[j] == 1'b1 ) ? { 4'h0, enc_cnt[j] } : 8'h00;
            end
            default: ams_readdata <= 32'h00000000;
          endcase
          ams_waitrequest   <= 1'b1;
          ams_readdatavalid <= 1'b1;
          ams_state         <= AMS_STATE_IDLE;
        end
        
        default: begin
          for( j = 0; j < 4; j = j + 1 )
            enc_clear[j] <= 1'b0;
          light_manual_d     <= 1'b0;
          light_remote_d     <= 1'b0;
          light_cnt_d        <= {(5){ 1'b0 }};
          light_cnt_req      <= 1'b0;
          ams_waitrequest    <= 1'b1;
          ams_readdatavalid  <= 1'b0;
          ams_readdata       <= 32'h00000000;
          ams_address_d      <= 3'b000;
          ams_writedata_d    <= 32'h00000000;
          ams_access_counter <= 28'd0;
          ams_state          <= AMS_STATE_IDLE;
        end
        
      endcase
      
    end
    
  end
  
  
  
  logic           [PWM_CHANNELS-1:0] reg_pwm_load;
  logic [PWM_CHANNELS*PWM_WIDTH-1:0] reg_pwm_value;
  
  backlight_control #(
    .BASE_ADDRESS ( COEF_BASE_ADDRESS ),
    .PWM_CHANNELS ( PWM_CHANNELS      ),
    .PWM_WIDTH    ( PWM_WIDTH         )
  ) backlight_control_i (
    .reset_n            ( reset_n            ),
    .clock              ( clock              ),
    .night              ( backlight_night    ),
    .light_manual       ( light_manual       ),
    .light_cnt          ( light_cnt          ),
    .illuminance_avg    ( backlight_bite_instant?'0:illuminance_avg    ),
    .light_mcu          ( light_mcu          ),
    .bklt_waitrequest   ( bklt_waitrequest   ),
    .bklt_read          ( bklt_read          ),
    .bklt_address       ( bklt_address       ),
    .bklt_readdatavalid ( bklt_readdatavalid ),
    .bklt_readdata      ( bklt_readdata      ),
    .pwm_load           ( reg_pwm_load       ),
    .pwm_value          ( reg_pwm_value      )
  );
  
  
  logic backlight_bite_instant;
  logic [1:0] reg_backlight_drv_en;
  logic [1:0] reg_backlight_out_en_n;
  
  always @( posedge clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      reg_backlight_drv_en   <= 2'b00;
      reg_backlight_out_en_n <= 2'b00;
      backlight_bite_instant <= 1'b0;
    end else begin

      if(backlight_bite) backlight_bite_instant <= 1'b1;

      if( pu_timer >= CLOCK_FREQ)
        case( pu_type_latch[3:2] )
          
          2'b10: begin            
              reg_backlight_drv_en   <= ( ( pwr_status_mcu[1:0] != 2'b11 ) ) ? 2'b11 : 2'b00;
            //reg_backlight_drv_en   <= ( backlight_fault_n) ? 2'b11 : 2'b00;
              reg_backlight_out_en_n <= 2'b10;
          end
          
          2'b01: begin
            reg_backlight_drv_en   <=  ( ( pwr_status_mcu[1:0] != 2'b11 ) ) ? 2'b01 : 2'b00;
            //reg_backlight_drv_en   <= ( backlight_fault_n) ? 2'b01 : 2'b00;
            reg_backlight_out_en_n <= 2'b00;
          end
          
          2'b00: begin
            //reg_backlight_drv_en   <= ( backlight_fault_n) ? 2'b10 : 2'b00;
            reg_backlight_drv_en   <= ( ( pwr_status_mcu[1:0] != 2'b11 ) ) ? 2'b10 : 2'b00;
            reg_backlight_out_en_n <= 2'b01;
          end
          
          default: begin
            reg_backlight_drv_en   <= 2'b00;
            reg_backlight_out_en_n <= 2'b00;
          end
          
        endcase
      
    end
    
  end
  
  
  
  genvar k;
  
  logic                 pwm_load[PWM_CHANNELS];
  logic [PWM_WIDTH-1:0] pwm_value[PWM_CHANNELS];
  
  generate
    
    if( PU_DAC_TYPE == "SIGMA-DELTA" ) begin
      for( k = 1; k < PWM_CHANNELS; k = k + 1 ) begin : gen_pwm
        sigma_delta #(
          .CLOCK_PRESCALER ( PWM_PRESCALER ),
          .DAC_WIDTH       ( PWM_WIDTH     )
        ) pu_sigma_delta_i (
          .clock      ( clock            ),
          .reset_n    ( reset_n          ),
          .pwm_load   ( pwm_load[k]      ),
          .pwm_value  ( pwm_value[k]     ),
          .pwm_out    ( backlight_pwm[k] )
        );
      end
    end else if( PU_DAC_TYPE == "PWM" ) begin
      for( k = 1; k < PWM_CHANNELS; k = k + 1 ) begin : gen_pwm
        pwm #(
          .CLOCK_PRESCALER ( PWM_PRESCALER ),
          .PWM_WIDTH       ( PWM_WIDTH     )
        ) pu_pwm_i (
          .clock      ( clock            ),
          .reset_n    ( reset_n          ),
          .pwm_load   ( pwm_load[k]      ),
          .pwm_value  ( pwm_value[k]     ),
          .pwm_out    ( backlight_pwm[k] )
        );
      end
    end else begin
      initial
        $error( "Error: incorrect value of parameter PU_DAC_TYPE == %s. there can be only SIGMA-DELTA or PWM", PU_DAC_TYPE );
    end
    
    if( LCD_DAC_TYPE == "SIGMA-DELTA" ) begin
      sigma_delta #(
        .CLOCK_PRESCALER ( PWM_PRESCALER ),
        .DAC_WIDTH       ( PWM_WIDTH     )
      ) lcd_sigma_delta_i (
        .clock      ( clock            ),
        .reset_n    ( reset_n          ),
        .pwm_load   ( pwm_load[0]      ),
        .pwm_value  ( pwm_value[0]     ),
        .pwm_out    ( backlight_pwm[0] )
      );
    end else if( LCD_DAC_TYPE == "PWM" ) begin
      pwm #(
        .CLOCK_PRESCALER ( PWM_PRESCALER ),
        .PWM_WIDTH       ( PWM_WIDTH     )
      ) lcd_pwm_i (
        .clock      ( clock            ),
        .reset_n    ( reset_n          ),
        .pwm_load   ( pwm_load[0]      ),
        .pwm_value  ( pwm_value[0]     ),
        .pwm_out    ( backlight_pwm[0] )
      );
    end else begin
      initial
        $error( "Error: incorrect value of parameter LCD_DAC_TYPE == %s. there can be only SIGMA-DELTA or PWM", LCD_DAC_TYPE );
    end
    
  endgenerate
  
  
  
  genvar n;
  
  logic [PWM_WIDTH+7:0] bklt_source;
  
  assign backlight_drv_en   = ( bklt_source[PWM_WIDTH+7] == 1'b1 ) ? bklt_source[PWM_WIDTH+6:PWM_WIDTH+5] : reg_backlight_drv_en;
  assign backlight_out_en_n = ( bklt_source[PWM_WIDTH+7] == 1'b1 ) ? bklt_source[PWM_WIDTH+4:PWM_WIDTH+3] : reg_backlight_out_en_n;
  
  generate
    for( n = 0; n < PWM_CHANNELS; n = n + 1 ) begin : gen_pwm_values
      assign pwm_load[n]  = ( bklt_source[PWM_WIDTH+7] == 1'b1 ) ? bklt_source[PWM_WIDTH-1+n] : reg_pwm_load;
      assign pwm_value[n] = ( bklt_source[PWM_WIDTH+7] == 1'b1 ) ? bklt_source[PWM_WIDTH-1:0] : reg_pwm_value[n*PWM_WIDTH+:PWM_WIDTH];
    end
  endgenerate
  
  altsource_probe #(
      .sld_auto_instance_index ( "YES"         ),
      .sld_instance_index      ( 0             ),
      .instance_id             ( "BKLT"        ),
      .probe_width             ( 0             ),
      .source_width            ( PWM_WIDTH + 8 ),
      .source_initial_value    ( "0"           ),
      .enable_metastability    ( "NO"          )
  ) altsource_probe_bklt_i (
      .source_ena              ( reset_n     ),
      .source                  ( bklt_source )
  );
  
  
  
  logic       pu_type_stable;
  logic       pu_type_fhd;
  logic       pu_type_xga;
  logic       pu_type_vga;
  
  logic       pu_ready_reset_req_reg;
  logic [2:0] pu_ready_reset_n_reg;
  
  logic       fhd_reset_req_reg;
  logic [1:0] fhd_reset_n_reg;
  
  logic       xga_reset_req_reg;
  logic [1:0] xga_reset_n_reg;
  
  logic       vga_reset_req_reg;
  logic [1:0] vga_reset_n_reg;
  
  logic [1:0] pu_type_meta;
  logic [3:0] pu_type_latch;


 logic [31:0]pu_timer=0;
 
 
  always @( posedge clock or negedge reset_n )
  begin
    
    if( !reset_n ) begin
      
      pu_ready_reset_req_reg <= 1'b0;
      pu_ready_reset_n_reg   <= 3'b000;
      
      fhd_reset_req_reg      <= 1'b0;
      fhd_reset_n_reg        <= 2'b00;
      
      xga_reset_req_reg      <= 1'b0;
      xga_reset_n_reg        <= 2'b00;
      
      vga_reset_req_reg      <= 1'b0;
      vga_reset_n_reg        <= 2'b00;
      
      { pu_type_latch, pu_type_meta } <= 6'b000000;
    pu_timer <= 0;
    end else begin

          pu_ready_reset_req <= pu_ready_reset_req_reg;
          pu_ready_reset_n   <= pu_ready_reset_n_reg[2];
  
          fhd_reset_req      <= fhd_reset_req_reg;
          fhd_reset_n        <= fhd_reset_n_reg[1];
  
          xga_reset_req      <= xga_reset_req_reg;
          xga_reset_n        <= xga_reset_n_reg[1];
  
          vga_reset_req      <= vga_reset_req_reg;
          vga_reset_n        <= vga_reset_n_reg[1];
  
          pu_type_stable     <= (   pu_type_latch[3:2] == pu_type_latch[1:0] ) ? 1'b1 : 1'b0;
          pu_type_fhd        <= (   pu_type_latch[3:2] == PU_TYPE_15INCH   )   ? 1'b1 : 1'b0;
          pu_type_xga        <= ( ( pu_type_latch[3:2] == PU_TYPE_12INCH ) ||
                                  ( pu_type_latch[3:2] == PU_TYPE_10INCH ) )   ? 1'b1 : 1'b0;
          pu_type_vga        <= (   pu_type_latch[3:2] == PU_TYPE_UNKNOWN  )   ? 1'b1 : 1'b0;
  
          pu_type            <= pu_type_latch;
      //end
        pu_ready_reset_req_reg <= pu_ready_reset_n_reg[2] ^ pu_ready_reset_n_reg[1];
        pu_ready_reset_n_reg   <= ( pu_type_stable ) ? { pu_ready_reset_n_reg[1:0], 1'b1 } : 3'b000;
        
        fhd_reset_req_reg      <= fhd_reset_n_reg[1] ^ fhd_reset_n_reg[0];
        fhd_reset_n_reg        <= ( pu_type_stable ) ? { fhd_reset_n_reg[0], pu_type_fhd } : 2'b00;
        
        xga_reset_req_reg      <= xga_reset_n_reg[1] ^ xga_reset_n_reg[0];
        xga_reset_n_reg        <= ( pu_type_stable ) ? { xga_reset_n_reg[0], pu_type_xga } : 2'b00;
        
        vga_reset_req_reg      <= vga_reset_n_reg[1] ^ vga_reset_n_reg[0];
        vga_reset_n_reg        <= ( pu_type_stable ) ? { vga_reset_n_reg[0], pu_type_vga } : 2'b00;
      
      if( pu_timer < CLOCK_FREQ) begin
        pu_timer <=  pu_timer + 1;
        { pu_type_latch, pu_type_meta } <= { pu_type_latch[1:0], pu_type_meta, pu_type_reg };
      end
      
    end
    
  end
  
  
  
endmodule : pu
