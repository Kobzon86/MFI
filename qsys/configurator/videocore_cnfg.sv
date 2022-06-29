/*
 * Configurator
 */

module videocore_cnfg #(
  
  parameter VIDECORE_ADDR = 0
  
)(
  
  input               reset_n,
  input               clock,
  
  input               amm_waitrequest,
  output logic        amm_write,
  output logic        amm_read,
  output logic [31:0] amm_address,
  output logic  [31:0] amm_writedata,
  input               amm_readdatavalid,
  input   [31:0] amm_readdata,
  input logic  [7:0] gp_inputs,
  output logic [7:0] gp_outputs
  
);
  
  enum logic[3:0] {
    AMM_IDLE ,
    AMM_WRITE,
    AMM_READ ,
    AMM_ACK ,
    AMM_DECID,
    AMM_COMPL,
    DDR_RESET
  } amm_state;

logic [1:0]pu_type;
logic write_all;
wire GPIO_DDR_TOP_INIT_DONE = gp_inputs[0];
wire GPIO_DDR_BOT_INIT_DONE = gp_inputs[1];
wire GPIO_DDR_TOP_CAL_SUCCESS = gp_inputs[2];
wire GPIO_DDR_BOT_CAL_SUCCESS = gp_inputs[3];
wire [1:0] pu_in = gp_inputs[5:4];
logic [23:0] width;
logic [23:0] height;
always_comb 
  case(pu_type)
    2'd2:begin
      width = 24'd1920;
      height = 24'd1080;
    end
    2'd1:begin
      width = 24'd1024;
      height = 24'd768;
    end
    default:begin
      width = 24'd640;
      height = 24'd480;
    end
  endcase

logic [4:0] reg_num;
logic [15:0]CVI_CONTROL_ADDR [3:0];
assign CVI_CONTROL_ADDR[3] = VIDECORE_ADDR+16'h200;
assign CVI_CONTROL_ADDR[2] = VIDECORE_ADDR+16'h100;
assign CVI_CONTROL_ADDR[1] = VIDECORE_ADDR+16'h80 ;
assign CVI_CONTROL_ADDR[0] = VIDECORE_ADDR+16'h0;

localparam MIX_INP_CONTROL_EN0      = 1'b0  ;
localparam MIX_INP_CTRL_ALPHA_MODE0 = 2'h1  ;
localparam MIX_INP_CTRL_EN_CONSUME0 = 1'b0  ;

localparam MIX_INP_CONTROL_EN1      = 1'b0  ;
localparam MIX_INP_CTRL_ALPHA_MODE1 = 2'h1  ;
localparam MIX_INP_CTRL_EN_CONSUME1 = 1'b0  ;

localparam MIX_INP_CONTROL_EN2      = 1'b1;
localparam MIX_INP_CTRL_ALPHA_MODE2 = 2'h2;
localparam MIX_INP_CTRL_EN_CONSUME2 = 1'b0;

logic [23:0] write_regs [30:0];
localparam  CVI_CONTROL1        = 24'h1;       assign write_regs[0 ] = 24'h000_000 + CVI_CONTROL1;
localparam  CVI_CONTROL2        = 24'h1;       assign write_regs[1 ] = 24'h080_000 + CVI_CONTROL2;
localparam  CVI_CONTROL3        = 24'h1;       assign write_regs[2 ] = 24'h100_000 + CVI_CONTROL3;
localparam  CVI_CONTROL4        = 24'h1;       assign write_regs[3 ] = 24'h200_000 + CVI_CONTROL4;
                                               assign write_regs[4 ] = 24'h410000 + ( write_all ? 24'h2  : 24'h1  );
                                               assign write_regs[5 ] = 24'h414000 + ( write_all ? 24'h4  : 24'h1  );
                                               assign write_regs[6 ] = 24'h60C000 + ( write_all ? width  : 24'd460);
                                               assign write_regs[7 ] = 24'h610000 + ( write_all ? height : 24'd160);
                                               assign write_regs[8 ] = 24'h80c000 + ( write_all ? width  : 24'd60 );
                                               assign write_regs[9 ] = 24'h810000 + ( write_all ? height : 24'd160);
localparam MIX_CONTROL              = 24'h1  ; assign write_regs[10] = 24'hC00_000 + MIX_CONTROL;
                                               assign write_regs[11] = 24'hC0C_000 + width;
                                               assign write_regs[12] = 24'hC10_000 + height;
localparam MIX_BACKGROUND_RED       = 24'h0  ; assign write_regs[13] = 24'hC14_000 + MIX_BACKGROUND_RED;
localparam MIX_BACKGROUND_GREEN     = 24'h0  ; assign write_regs[14] = 24'hC18_000 + MIX_BACKGROUND_GREEN;
localparam MIX_BACKGROUND_BLUE      = 24'h0  ; assign write_regs[15] = 24'hC1C_000 + MIX_BACKGROUND_BLUE;
                                               assign write_regs[16] = 24'hC28_000 + {MIX_INP_CTRL_ALPHA_MODE0, MIX_INP_CTRL_EN_CONSUME0, MIX_INP_CONTROL_EN0};
localparam MIX_LAYER_POSITION0      = 24'h0  ; assign write_regs[17] = 24'hC2C_000 + MIX_LAYER_POSITION0;
localparam MIX_X_OFFSET0            = 24'h0  ; assign write_regs[18] = 24'hC20_000 + MIX_X_OFFSET0;
localparam MIX_Y_OFFSET0            = 24'h0  ; assign write_regs[19] = 24'hC24_000 + MIX_Y_OFFSET0;
localparam MIX_STATIC_ALPHA0        = 24'h0  ; assign write_regs[20] = 24'hC30_000 + MIX_STATIC_ALPHA0;
                                               assign write_regs[21] = 24'hC3C_000 + {MIX_INP_CTRL_ALPHA_MODE1, MIX_INP_CTRL_EN_CONSUME1, MIX_INP_CONTROL_EN1};
localparam MIX_LAYER_POSITION1      = 24'h1  ; assign write_regs[22] = 24'hC40_000 + MIX_LAYER_POSITION1;
localparam MIX_X_OFFSET1            = 24'h0  ; assign write_regs[23] = 24'hC34_000 + MIX_X_OFFSET1;
localparam MIX_Y_OFFSET1            = 24'h0  ; assign write_regs[24] = 24'hC38_000 + MIX_Y_OFFSET1;
localparam MIX_STATIC_ALPHA1        = 24'h0  ; assign write_regs[25] = 24'hC44_000 + MIX_STATIC_ALPHA1;
                                               assign write_regs[26] = 24'hC50_000 + {MIX_INP_CTRL_ALPHA_MODE2, MIX_INP_CTRL_EN_CONSUME2, MIX_INP_CONTROL_EN2};
localparam  MIX_LAYER_POSITION2 = 24'h2;       assign write_regs[27] = 24'hC54_000 + MIX_LAYER_POSITION2;
localparam  MIX_X_OFFSET2       = 24'h0;       assign write_regs[28] = 24'hC48_000 + MIX_X_OFFSET2;
localparam  MIX_Y_OFFSET2       = 24'h0;       assign write_regs[29] = 24'hC4C_000 + MIX_Y_OFFSET2;
localparam  MIX_STATIC_ALPHA2   = 24'h0;       assign write_regs[30] = 24'hC58_000 + MIX_STATIC_ALPHA2;


logic [7:0] control_rcvd               ;
logic [5:0] cntr                       ;
logic       configured                 ;

logic [25:0]timer;
wire timer_event = timer[25];

always_ff @( posedge clock or negedge reset_n )
  begin    
    if( !reset_n ) begin      
      amm_write     <= 1'b0;
      amm_read <= 1'b0;
      amm_address   <= 32'h00000000;
      amm_writedata <= 32'h00000000;      
      amm_state <= AMM_IDLE;
      configured <= 1'b0;
      pu_type <= 2'd0;
      timer <= '0;
      gp_outputs <= '1;
    end else begin
      gp_outputs <= '1;
      amm_read <= 1'b0;
      timer <= timer_event ? '0 : (timer + 1'b1); 
      if( timer_event && ( amm_state != AMM_IDLE ) )amm_state <= AMM_IDLE;

      case (amm_state)
        AMM_IDLE:begin
          reg_num <= '0;
          cntr <= 6'd0;
          amm_write <= 1'b0;
          pu_type <= pu_in;
          write_all <= 1'b0;

          if(timer_event)begin
            if( !(GPIO_DDR_TOP_INIT_DONE && GPIO_DDR_BOT_INIT_DONE && GPIO_DDR_TOP_CAL_SUCCESS && GPIO_DDR_BOT_CAL_SUCCESS) ) 
              amm_state <= DDR_RESET;
            //else if(!configured)          
            //  amm_state <= AMM_READ;
          end

          //if( pu_type != pu_in )
          //  amm_state <= AMM_READ;
        end
        AMM_READ:begin
          if(reg_num[3]) amm_state <= AMM_DECID;
          else if(!reg_num[2])begin
            amm_address <= CVI_CONTROL_ADDR[reg_num[1:0]];
            amm_read <= 1'b1;
          end
          else begin
            amm_address <= CVI_CONTROL_ADDR[reg_num[1:0]] + 32'd4;
            amm_read <= 1'b1;
          end
          if( ( !amm_waitrequest ) && amm_read )begin 
            amm_state <= AMM_ACK;
            amm_read <= 1'b0;
          end
        end
        AMM_ACK:begin          
          if(amm_readdatavalid)begin
            timer <= '0;
            amm_state <= AMM_READ;
            reg_num <= reg_num + 1'b1;
            if(!reg_num[2])control_rcvd[reg_num] <= amm_readdata[0];
            else control_rcvd[reg_num] <= amm_readdata[10];
          end
        end
        AMM_DECID:begin
          reg_num <= '0;
          //write_all <= &control_rcvd;
          
          amm_state <= AMM_WRITE;
        end
        AMM_WRITE:begin
          
            cntr <= cntr[5] ? cntr : (cntr + 6'd1);
            if( !amm_write && cntr[5] ) 
              amm_write <= 1'b1;   
            else
              if( amm_write && (!amm_waitrequest))begin
                cntr <= 6'd0;
                amm_write <= 1'b0;
                reg_num <= reg_num + 1'b1;
                timer <= '0;
              end
            
            amm_address   <= write_regs[reg_num][23:12];
            amm_writedata <= write_regs[reg_num][11:0];
            
          if( reg_num == ( write_all ? 5'd31 : 5'd13 ) )begin 
            amm_state <= AMM_IDLE;  
            configured <= write_all;
          end
        end

        default : gp_outputs <= '0;
      endcase
      

      
    end
    
  end
  
  
endmodule : videocore_cnfg
