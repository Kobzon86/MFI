/*
 * Configurator
 */

module asmi_cntrlr (
  input               reset_n          ,
  input               clock            ,

  input               asmi_amm_waitrequest  ,
  output logic        asmi_amm_write        ,
  output logic        asmi_amm_read         ,
  input        [31:0] asmi_amm_readdata     ,
  input               asmi_amm_readdatavalid,
  output logic [25:0] asmi_amm_address      ,
  output logic [ 6:0] asmi_amm_burstcount   ,
  output logic [31:0] asmi_amm_writedata    ,

  input               ru_amm_waitrequest  ,
  output logic        ru_amm_write        ,
  output logic        ru_amm_read         ,
  input        [31:0] ru_amm_readdata     ,
  input               ru_amm_readdatavalid,
  output logic [4:0]  ru_amm_address      ,
  output logic [31:0] ru_amm_writedata    ,

  input               ams_read         ,
  input               ams_write         ,
  output logic [31:0] ams_readdata     ,
  input        [31:0] ams_writedata     ,
  output logic        ams_waitrequest     ,
  output logic        ams_readdatavalid,
  input  [16:0]       ams_address ,
  output  logic [31:0] CRC
);
localparam ASMI_CSR = 32'h200_0000;
  enum logic [2:0]{
    RU_IDLE,
    RU_WDT_TIMEOUT,
    RU_PAGE_SELECT,
    RU_CONF_MODE,
    RU_WDT_ENABLE,
    RU_WDT_RESET,
    RU_RECONFIG
  } ru_amm_state;
logic cnfgrd;
localparam INTERVAL = 10_000_000;
logic [29:0] timer;
logic [4:0]cntr_ru;
wire timer_event = timer == INTERVAL;

always_ff @(posedge clock or negedge reset_n) begin : proc_
  if(~reset_n) begin
    timer <= '0;
    cnfgrd <= 1'b0;
    ru_amm_state <= RU_IDLE;
    ru_amm_write <= 1'b0;
    cntr_ru <= '0;
  end else begin

    if(ru_amm_state==RU_IDLE)begin
      timer <= timer_event ? '0 : (timer + 1'b1);
      cntr_ru <= '0;
    end
    else begin 
      timer <= '0;
      cntr_ru <= cntr_ru[4] ? '0 : (cntr_ru + 1'b1);
    end

     

     case (ru_amm_state)
       RU_IDLE:begin
         ru_amm_write <= 1'b0;
         if(timer_event) ru_amm_state <= RU_WDT_RESET;
         if(!cnfgrd) ru_amm_state <= RU_WDT_TIMEOUT;
       end
       RU_WDT_TIMEOUT:begin
        if(cntr_ru[4])begin
          ru_amm_write <= 1'b1;
          ru_amm_address <= 4;
          ru_amm_writedata <= 32'h800;
          ru_amm_state <= RU_PAGE_SELECT;
        end
       end
       RU_PAGE_SELECT:begin
        //if(cntr_ru[4])
          if(!ru_amm_waitrequest)begin
            ru_amm_write <= 1'b1;
            ru_amm_address <= 3*4;
            ru_amm_writedata <= 32'h006C4C4F;
            ru_amm_state <= RU_CONF_MODE;
          end
       end
       RU_CONF_MODE:begin
        //if(cntr_ru[4])
          if(!ru_amm_waitrequest)begin
            ru_amm_write <= 1'b1;
            ru_amm_address <= 4*4;
            ru_amm_writedata <= 32'h1;
            ru_amm_state <= RU_WDT_ENABLE;
          end
        end
       RU_WDT_ENABLE:begin
        //if(cntr_ru[4])
          if(!ru_amm_waitrequest)begin
            ru_amm_write <= 1'b1;
            ru_amm_address <= 2*4;
            ru_amm_writedata <= 32'h1;
            ru_amm_state <= RU_IDLE;
            cnfgrd <= 1'b1;
          end
       end 
       RU_WDT_RESET: begin
          ru_amm_write <= 1'b1;
          ru_amm_address <= 5*4;
          ru_amm_writedata <= 32'h1;
          ru_amm_state <= RU_IDLE;
        end
       RU_RECONFIG: begin
          ru_amm_write <= 1'b1;
          ru_amm_address <= 6*4;
          ru_amm_writedata <= 32'h1;
          ru_amm_state <= RU_IDLE;
        end
       default : ru_amm_state <= RU_IDLE;
     endcase
  end
end



  (*noprune*)logic completed;
  //(*noprune*)logic [31:0] CRC;
logic [15:0] mem_offset;
logic read_op ;
logic write_op;
logic [15:0] addr_buf;
logic [31:0] writedata_buf;
logic csr_m;
  enum logic [2:0]{
    AMM_STATE_IDLE,
    AMM_STATE_FOURBYTE,
    AMM_STATE_WRWT,
    AMM_STATE_ACK,
    AMM_STATE_READ,
    AMM_STATE_STOP
  } asmi_amm_state;

  logic [6:0] cntr;
  (*noprune*)logic [31:0]recieved;
  always_ff @( posedge clock or negedge reset_n )
    if( !reset_n )
      begin
        cntr        <= '0;
        CRC         <= 32'hFFFFFFFF;
        asmi_amm_read    <= 1'b0;
        asmi_amm_write   <= 1'b0;
        completed   <= 1'b0;
        asmi_amm_address <= '0;
        asmi_amm_state   <= AMM_STATE_IDLE;
        recieved    <= '0;
      end
    else begin
      asmi_amm_read       <= (!asmi_amm_address[25]) && (asmi_amm_state == AMM_STATE_READ);
      asmi_amm_write      <= 1'b0;
      asmi_amm_burstcount <= 7'd64;
      case (asmi_amm_state)
        AMM_STATE_IDLE : begin
          if(!completed) asmi_amm_state <= AMM_STATE_FOURBYTE;
          else begin            
            asmi_amm_read <= read_op;
            asmi_amm_write <= write_op;
            asmi_amm_address <= ({(csr_m?16'd0:mem_offset),addr_buf} | (csr_m ? ASMI_CSR : 32'd0));//<<2
            asmi_amm_burstcount <= 7'd1;
            asmi_amm_writedata <= writedata_buf;
          end
        end
        AMM_STATE_FOURBYTE : begin
          asmi_amm_write     <= 1'b1;
          asmi_amm_address   <= ASMI_CSR + 32'h4C;
          asmi_amm_writedata <= 32'd1;
          asmi_amm_state     <= AMM_STATE_WRWT;
        end
        AMM_STATE_WRWT : begin
          asmi_amm_address <= '0;
          asmi_amm_state   <= AMM_STATE_READ;
        end
        AMM_STATE_READ : begin
          cntr <= '0;
          if(!asmi_amm_address[25])asmi_amm_state <= AMM_STATE_ACK;
          else begin 
            asmi_amm_state   <= AMM_STATE_IDLE;
            completed <= 1'b1;
          end
        end
        AMM_STATE_ACK : begin
          if(asmi_amm_readdatavalid)begin
            CRC      <= CRC ^ asmi_amm_readdata;
            cntr     <= cntr + 1'b1;
            recieved <= recieved + 1'b1;
          end
          if(cntr[6])begin
            asmi_amm_state   <= AMM_STATE_READ;
            asmi_amm_address <= asmi_amm_address + 26'd256;
          end
        end

        default : begin
        end
      endcase

    end
    always_ff @(posedge clock or negedge reset_n)
      if(~reset_n)
        begin
          ams_readdatavalid <= 1'b0;
          read_op <= 1'b0;
          write_op <= 1'b0;
        end
      else
        begin  


          read_op <= ams_read;
          write_op <= ams_write;
          addr_buf <= ams_address[15:0];
          csr_m <= ams_address[16];
          writedata_buf <= ams_writedata;
          ams_readdatavalid <= asmi_amm_readdatavalid;
          ams_readdata <= asmi_amm_readdata;

          if(ams_address[16:0] == 17'h10064)begin
            ams_readdata <= mem_offset;
            if(ams_write) mem_offset <= ams_writedata;
          end
        end

assign ams_waitrequest = 1'b0; //!(!asmi_amm_waitrequest && (asmi_amm_write || asmi_amm_read));




endmodule
