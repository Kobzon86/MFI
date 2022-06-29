module avm_adv7613_check 
#(parameter IN_CLK_HZ            = 32'd50000000,
            TIMER_DELAY_MKS      = 32'd1, // периодичность запуска рабочего цикла в мкс
			
            AMS_I2C_AMM_ADDRESS       = 8'h0,
            ADV7613_I2C_ADDRESS       = 8'd3,
			ADV7613_TIMER_RESET_MKS   = 32'd10000 // задержка сброса в мкс
)
(
     input                   i_avs_clk
    ,input                   i_avs_rst_n
	
    //Avalon_MM    Master 
    ,output  logic   [31:0]  o_avm_address              
    ,output  logic           o_avm_write     
    ,output  logic   [7:0]   o_avm_writedata  
    ,output  logic           o_avm_read     
    ,input           [7:0]   i_avm_readdata       
    ,input                   i_avm_waitrequest 
    //reset
	,output logic            o_avs_rst_n
	//pio
	,output logic    [7:0]   o_pio
);

typedef enum bit [7:0]
             { IDX_PIO_ADV7613_RESET  = 8'd0, 
			   IDX_PIO_ADV7613_0      = 8'd1,
			   IDX_PIO_ADV7613_1      = 8'd2
             } t_pio_idx;

localparam ADV7613_PWRDWN     = 8'hC,
           ADV7613_PWRDWN_MSK = 8'h20;
      
//////////////////////////////////////////////////////////////////////////////
///////////////                   PARAMETRS                   ////////////////
//////////////////////////////////////////////////////////////////////////////
localparam TIMER_DELAY         = (TIMER_DELAY_MKS*IN_CLK_HZ)/1000000,
           ADV7613_TIMER_RESET = (ADV7613_TIMER_RESET_MKS*IN_CLK_HZ)/1000000;

enum logic [2:0]{
    AMM_RESET,
	AMM_INIT,
    AMM_WAIT_TIMER_DONE,
    AMM_WORK,
    AMM_WORK_DONE,
     
    AMM_WRITE,
    AMM_READ,
    AMM_ACK
  } amm_current_state, amm_prev_state;

typedef enum bit[0:0]{ OP_WRITE = 1'b0, OP_READ = 1'b1 } t_operation;

typedef struct packed {
  t_operation  operation;
  logic [31:0] address;
  logic [15:0]  register;
  logic [7:0] data;
} t_op_array;

//////////////////////////////////////////////////////////////////////////////
typedef enum bit [7:0]
             { IDX_WORK_RD_ADV7613_0_I2C_WAIT_PWRDWN   = 8'd0, 
			   IDX_WORK_RD_ADV7613_1_I2C_WAIT_PWRDWN   = 8'd1
             } t_work_idx;
            
t_op_array work_array[2];
always_comb begin          
//////////////////                WORK ARRAY                 ////////////////
  work_array[0]=  { OP_READ,  AMS_I2C_AMM_ADDRESS[31:0] + ADV7613_I2C_ADDRESS << 8,   ADV7613_PWRDWN[7:0],     8'h00 };                                          // read from AMS_I2C reg POWER_DOWN
  work_array[1]=  { OP_READ,  AMS_I2C_AMM_ADDRESS[31:0] + ADV7613_I2C_ADDRESS << 8,   ADV7613_PWRDWN[7:0],     8'h00 };                                          // read from AMS_I2C reg POWER_DOWN
end

initial begin                            
//////////////////                WORK ARRAY                 ////////////////
  work_array[0]=  { OP_READ,  AMS_I2C_AMM_ADDRESS[31:0] + ADV7613_I2C_ADDRESS << 8,   ADV7613_PWRDWN[7:0],     8'h00 };                                          // read from AMS_I2C reg POWER_DOWN
  work_array[1]=  { OP_READ,  AMS_I2C_AMM_ADDRESS[31:0] + ADV7613_I2C_ADDRESS << 8,   ADV7613_PWRDWN[7:0],     8'h00 };                                          // read from AMS_I2C reg POWER_DOWN
  
  $display( "work_array: size = %0d",$size(work_array));
  $display( "  operation[0],   address[31:0], register[7:0],  data[7:0]");
  for(int i = 0; i < $size(work_array); i++) begin
    $display( " %0d:   'b%b         0x%h        +0x%h(%0d)     0x%h", i,work_array[i].operation, work_array[i].address, work_array[i].register << 0, work_array[i].register, work_array[i].data);
  end
end
//////////////////////////////////////////////////////////////////////////////
//////////////////                   AVM MASTER               ////////////////
//////////////////////////////////////////////////////////////////////////////
logic [31:0]  amm_address   ;
logic         amm_write     ;
logic [7:0]   amm_writedata ;
logic         amm_read      ;
logic [7:0]   amm_readdata  ;
logic         amm_waitrequest;
assign o_avm_address = amm_address;
assign o_avm_write = amm_write;
assign o_avm_writedata = amm_writedata;
assign o_avm_read = amm_read;
assign amm_readdata = i_avm_readdata;
assign amm_waitrequest = i_avm_waitrequest;

logic [31:0]  amm_data   ;
logic  [7:0]  amm_index  ;
logic [15:0]  amm_cnt    ;
logic [7:0]   amm_reg_adr_ofst;
logic         error      ;

wire rst_n = i_avs_rst_n;

always @(posedge i_avs_clk or negedge rst_n) 
  if( !rst_n ) begin
      amm_write          <= 1'b0;
      amm_read           <= 1'b0;
      amm_address        <= '0;
      amm_writedata      <= '0;
      amm_data           <= '0;
      amm_reg_adr_ofst   <= '0;
      amm_index          <= '0;
      amm_cnt            <= '0;
      amm_prev_state     <= AMM_RESET;
      amm_current_state  <= AMM_RESET;
                         
	  error             <= '0;
	  o_pio             <= {'0,3'b111};
	  o_avs_rst_n       <= '1; 
  end else begin
    case( amm_current_state )
      AMM_INIT: begin
        amm_prev_state    <= AMM_INIT;
        begin
          amm_index  <= '0;
          amm_cnt  <= '0;
          amm_current_state  <= AMM_WAIT_TIMER_DONE;
		  
		  error             <= '0;
		  o_pio             <= {'0,3'b111};
		  o_avs_rst_n       <= '1; 
        end
      end   

      AMM_WAIT_TIMER_DONE: begin
        amm_prev_state     <= AMM_WAIT_TIMER_DONE;  
        amm_write          <= 1'b0;
        amm_read           <= 1'b0;
        amm_address        <= '0;
        amm_writedata      <= '0;
        amm_reg_adr_ofst   <= '0;
		
		error              <= '0;
		o_pio              <= {'0,3'b111};	
		o_avs_rst_n        <= '1;
        if( amm_cnt < ( TIMER_DELAY - 1 ) ) 
          amm_cnt  <= amm_cnt + 1'b1;
        else begin
          amm_cnt            <= '0;
          amm_current_state  <= AMM_WORK;
          amm_index          <= '0; 
        end
      end      
        
      AMM_WORK: begin
        amm_prev_state    <= AMM_WORK;
        if( amm_index < $size(work_array) ) begin
          if( work_array[amm_index].operation == OP_WRITE ) begin
            amm_address        <= work_array[amm_index].address + ((work_array[amm_index].register + amm_reg_adr_ofst) << 0);
            amm_write          <= 1'b1;
            amm_writedata      <= work_array[amm_index].data;
            amm_current_state  <= AMM_WRITE;
          end else begin
            amm_address        <= work_array[amm_index].address + ((work_array[amm_index].register + amm_reg_adr_ofst) << 0);
            amm_read           <= 1'b1;
            amm_data           <= work_array[amm_index].data;
            amm_current_state  <= AMM_READ;
          end
        end else begin
          amm_index  <= '0;
          amm_cnt  <= '0;
          amm_current_state  <= AMM_WORK_DONE;
        end
		
		o_pio[IDX_PIO_ADV7613_0]    <= 1'b1;
		o_pio[IDX_PIO_ADV7613_1]    <= 1'b1;
	    if(amm_index == IDX_WORK_RD_ADV7613_0_I2C_WAIT_PWRDWN)      o_pio[IDX_PIO_ADV7613_0]    <= 1'b0;
		else if(amm_index == IDX_WORK_RD_ADV7613_1_I2C_WAIT_PWRDWN) o_pio[IDX_PIO_ADV7613_1]    <= 1'b0;
      end  
      
      AMM_WRITE: begin
        if( !amm_waitrequest) begin
          amm_address       <= '0;
          amm_write         <= 1'b0;
          amm_writedata     <= '0;
          amm_index         <= amm_index + 1'b1;
          amm_current_state <= amm_prev_state;
        end 
      end
      
      AMM_READ: begin
        if( !amm_waitrequest) begin
          amm_address       <= '0;
          amm_read          <= 1'b0;
          amm_data          <= amm_readdata;
          amm_current_state <= AMM_ACK;
        end 
      end
      
      AMM_ACK: begin
        amm_current_state <= amm_prev_state;
        case( amm_prev_state )
          AMM_WORK: begin
            case( amm_index )
              // ADV7613
              IDX_WORK_RD_ADV7613_0_I2C_WAIT_PWRDWN,IDX_WORK_RD_ADV7613_1_I2C_WAIT_PWRDWN : begin 
                    if(amm_data & ADV7613_PWRDWN_MSK)  begin
						error       <= '1;
				    end
					amm_index <= amm_index + 1'b1;
              end
              default: begin 
                    amm_index <= amm_index + 1'b1;
              end
            endcase
          end
        endcase
      end
      
	  AMM_WORK_DONE: begin
	    if( error ) begin
		  o_avs_rst_n <= '0;
		  o_pio[IDX_PIO_ADV7613_RESET]    <= 1'b0;
		  if( amm_cnt < ( ADV7613_TIMER_RESET - 1 ) ) 
            amm_cnt  <= amm_cnt + 1'b1;
          else begin
            amm_cnt            <= '0;
            amm_current_state  <= AMM_WAIT_TIMER_DONE;
          end
		end 
	  end
	  
      default: begin
        amm_write         <= 1'b0;
        amm_read          <= 1'b0;
        amm_address       <= '0;
        amm_writedata     <= '0;
        amm_data          <= '0;
        amm_reg_adr_ofst  <= '0;
        amm_index         <= '0;
        amm_cnt           <= '0;
        amm_prev_state    <= AMM_INIT;
        amm_current_state <= AMM_INIT;
        
		error             <= '0;
		o_pio             <= {'0,3'b111};
		o_avs_rst_n       <= '1; 
      end 
      
    endcase
    
    end

endmodule
             