/*
 * 
 */

typedef struct packed {
  logic        clock;
  logic        hsync_n;
  logic        vsync_n;
  logic        de;
  logic [23:0] data;
  logic        locked;
} t_parallel_video;

module Analog_Receiver (
  
  input                   av_rx_sfl    ,
  input                   av_rx_llc    ,
  input                   av_rx_hsync_n,
  input                   av_rx_vsync_n,
  output                  av_rx_fb     , // CVBS <> RGB switch?
  input                   av_rx_de     ,
  input  [19:0]           av_rx_data   ,
  
  output t_parallel_video av_video
  
);
  
  
  
  cyclonev_clkena #(
    .clock_type        ( "Auto"            ),
    .ena_register_mode ( "falling edge"    ),
    .lpm_type          ( "cyclonev_clkena" )
  ) ctrl_inst0 (
    .ena    ( 1'b1           ),
    .enaout (                ),
    .inclk  ( av_rx_llc      ),
    .outclk ( av_video.clock )
  );
  
  
  
  logic [19:0] av_data_neg;
  
  always_ff @( negedge av_video.clock or negedge av_rx_sfl )
  begin
    
    if( !av_rx_sfl ) begin
      
      av_data_neg <= 20'h00000;
      
    end else begin
      
      av_data_neg <= av_rx_data;
      
    end
    
  end
  
  
  
  logic [19:0] av_data_p;
  logic [19:0] av_data_n;
  
  always_ff @( posedge av_video.clock or negedge av_rx_sfl )
  begin
    
    if( !av_rx_sfl ) begin
      
      av_data_p <= 20'h00000;
      av_data_n <= 20'h00000;
      
    end else begin
      
      av_data_p <= av_rx_data;
      av_data_n <= av_data_neg;
      
    end
    
  end
  
  
  
  logic [1:0] hsync_n;
  logic [1:0] vsync_n;
  logic [1:0] de;
  
  always_ff @( posedge av_video.clock or negedge av_rx_sfl )
  begin
    
    if( !av_rx_sfl ) begin
      
      hsync_n <= 2'b00;
      vsync_n <= 2'b00;
      de      <= 2'b00;
      
    end else begin
      
      hsync_n <= { hsync_n[0], av_rx_hsync_n };
      vsync_n <= { vsync_n[0], av_rx_vsync_n };
      de      <= { de[0],      av_rx_de      };
      
    end
    
  end
  
  
  
  always_ff @( posedge av_video.clock or negedge av_rx_sfl )
  begin
    
    if( !av_rx_sfl ) begin
      
      av_video.hsync_n <= 1'b0;
      av_video.vsync_n <= 1'b0;
      av_video.de      <= 1'b0;
      av_video.data    <= 24'h000000;
      av_video.locked  <= 1'b0;
      
    end else begin
      
      av_video.hsync_n <= hsync_n[1];
      av_video.vsync_n <= vsync_n[1];
      av_video.de      <= de[1];
      av_video.data    <= { av_data_n[9:6], av_data_n[19:16], av_data_n[15:12], av_data_p[9:6], av_data_p[19:12] };
      av_video.locked  <= 1'b1;
      
    end
    
  end
  
  
  
endmodule
