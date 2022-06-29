/*
* 
*/

module ddr_reset #(
  
  parameter GLOBAL_RESET_TIME = 8_000_000,
  parameter SOFT_RESET_TIME   = 8_000_000,
  parameter READY_TIME        = 8_000_000
  
)(
  
  input  reset_n,
  input  clk,
  
  input  pll_mem_clk,
  input  pll_write_clk,
  input  pll_locked,
  input  pll_write_clk_pre_phy_clk,
  input  pll_addr_cmd_clk,
  input  pll_avl_clk,
  input  pll_config_clk,
  input  pll_mem_phy_clk,
  input  afi_phy_clk,
  input  pll_avl_phy_clk,
  
  input  local_init_done,
  input  local_cal_success,
  input  local_cal_fail,
  
  output ddr_locked,
  
  output gl_reset_n,
  output sw_reset_n,
  output ready
  
);



reg reset_n_meta;
reg reset_n_latch;

always @( posedge clk or negedge reset_n ) begin
  
  if ( reset_n == 1'b0 ) begin
    
    { reset_n_latch, reset_n_meta } <= 2'b00;
    
  end else begin
    
    { reset_n_latch, reset_n_meta } <= { reset_n_meta, 1'b1 };
    
  end
  
end



reg         pll_locked_meta;
reg         pll_locked_latch;
reg [31: 0] gl_reset_timer;
reg  [3: 0] gl_reset_shift;
reg         gl_reset_reg_n;

assign ddr_locked = pll_locked_latch;

always @( posedge clk or negedge reset_n_latch ) begin
  
  if ( reset_n_latch == 1'b0 ) begin
    
    pll_locked_meta  <= 1'b0;
    pll_locked_latch <= 1'b0;
    gl_reset_timer   <= 32'd0;
    gl_reset_shift   <= 4'b0000;
    gl_reset_reg_n   <= 1'b0;
    
  end else begin
    
    if ( pll_locked_latch == 1'b1 ) begin
      
      gl_reset_timer <= 32'd0;
      gl_reset_shift <= 4'b1111;
      
    end else begin
      
      if ( gl_reset_shift == 4'b1111 ) begin
        
        if ( gl_reset_timer < ( GLOBAL_RESET_TIME - 1 ) ) begin
          gl_reset_timer <= ( gl_reset_timer + 1 );
        end else begin
          gl_reset_shift <= 4'b0000;
        end
        
      end else begin
        
        gl_reset_timer <= 32'd0;
        gl_reset_shift <= { gl_reset_shift[2:0], 1'b1 };
        
      end
      
    end
    
    pll_locked_meta  <= pll_locked;
    pll_locked_latch <= pll_locked_meta;
    
    gl_reset_reg_n <= gl_reset_shift[3];
    
  end
  
end



reg         cal_success_meta;
reg         cal_success_latch;
reg [31: 0] sw_reset_timer;
reg  [3: 0] sw_reset_shift;
reg         sw_reset_reg_n;

always @( posedge clk or negedge reset_n_latch ) begin
  
  if ( reset_n_latch == 1'b0 ) begin
    
    cal_success_meta  <= 1'b0;
    cal_success_latch <= 1'b0;
    sw_reset_timer    <= 32'd0;
    sw_reset_shift    <= 4'b0000;
    sw_reset_reg_n    <= 1'b0;
    
  end else begin
    
    if ( pll_locked_latch == 1'b0 ) begin
      
      sw_reset_timer <= 32'd0;
      sw_reset_shift <= 4'b0000;
      
    end else begin
      
      if ( cal_success_latch == 1'b1 ) begin
        
        sw_reset_timer <= 32'd0;
        sw_reset_shift <= 4'b1111;
        
      end else begin
        
        if ( sw_reset_shift == 4'b1111 ) begin
          
          if ( sw_reset_timer < ( SOFT_RESET_TIME - 1 ) ) begin
            sw_reset_timer <= ( sw_reset_timer + 1 );
          end else begin
            sw_reset_shift <= 4'b0000;
          end
          
        end else begin
          
          sw_reset_timer <= 32'd0;
          sw_reset_shift <= { sw_reset_shift[2:0], 1'b1 };
          
        end
        
      end
      
    end
    
    cal_success_meta  <= local_cal_success;
    cal_success_latch <= cal_success_meta;
    
    sw_reset_reg_n <= sw_reset_shift[3];
    
  end
  
end



reg [3:0] ready_shift;
reg       ready_reg;

always @( posedge clk or negedge reset_n_latch ) begin
  
  if ( reset_n_latch == 1'b0 ) begin
    
    ready_shift <= 4'b0000;
    ready_reg <= 1'b0;
    
  end else begin
    
    if ( ( pll_locked_latch == 1'b0 ) || ( cal_success_latch == 1'b0 ) ) begin
      
      ready_shift <= 4'b0000;
			ready_reg   <= 1'b0;
      
    end else begin
      
      ready_shift <= { ready_shift[2:0], 1'b1 };
      ready_reg   <= ready_shift[3];
      
    end
    
  end
  
end



//reg         init_done_meta;
//reg         init_done_latch;
//reg [31: 0] ready_timer;
//reg  [3: 0] ready_shift;
//reg         ready_reg;
//
//always @( posedge clk or negedge reset_n_latch ) begin
//  
//  if ( reset_n_latch == 1'b0 ) begin
//    
//    init_done_meta <= 1'b0;
//    init_done_latch <= 1'b0;
//    ready_timer <= 32'd0;
//    ready_shift <= 4'b0000;
//    ready_reg <= 1'b0;
//    
//  end else begin
//    
//    if ( ( pll_locked_latch == 1'b0 ) || ( cal_success_latch == 1'b0 ) ) begin
//      
//      ready_timer <= 32'd0;
//      ready_shift <= 4'b0000;
//      
//    end else begin
//      
//      if ( init_done_latch == 1'b1 ) begin
//        
//        ready_timer <= 32'd0;
//        ready_shift <= 4'b1111;
//        
//      end else begin
//        
//        if ( ready_shift == 4'b1111 ) begin
//          
//          if ( ready_timer < ( READY_TIME - 1 ) ) begin
//            ready_timer <= ( ready_timer + 1 );
//          end else begin
//            ready_shift <= 4'b0000;
//          end
//          
//        end else begin
//          
//          ready_timer <= 32'd0;
//          ready_shift <= { ready_shift[2: 0], 1'b1 };
//          
//        end
//        
//      end
//      
//    end
//    
//    init_done_meta  <= local_init_done;
//    init_done_latch <= init_done_meta;
//    
//    ready_reg <= ready_shift[3];
//    
//  end
//  
//end



wire [3: 0] probe;
wire [3: 0] source;

altsource_probe #(
  .sld_auto_instance_index ( "YES" ),
  .sld_instance_index ( 0 ),
  .instance_id ( "DDR" ),
  .probe_width ( 4 ),
  .source_width ( 4 ),
  .source_initial_value ( "0" ),
  .enable_metastability ( "NO" )
) altsource_probe_i (
  .source ( source ),
  .probe ( probe ),
  .source_ena ( 1'b1 )
);

assign probe      = { pll_locked, local_init_done, local_cal_success, local_cal_fail };

assign gl_reset_n = ( source[3] == 1'b0 ) ? gl_reset_reg_n : source[2];
assign sw_reset_n = ( source[3] == 1'b0 ) ? sw_reset_reg_n : source[1];
assign ready      = ( source[3] == 1'b0 ) ? ready_reg      : source[0];



endmodule

//synthesis translate_off
module altsource_probe #(
  parameter sld_auto_instance_index = "YES" ,
  parameter sld_instance_index = 0 ,
  parameter instance_id = "DDR" ,
  parameter probe_width = 4 ,
  parameter source_width = 4 ,
  parameter source_initial_value = "0" ,
  parameter enable_metastability = "NO"
)(
  input  [probe_width-1:0] source,
  output [probe_width-1:0] probe,
  input        source_ena
);
  
endmodule
//synthesis translate_on