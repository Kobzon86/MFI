module Switch #(
    parameter INPUT_NUMBER = 4,
    parameter PIX_IN_PARALLEL = 4,
    parameter OUTPUT_NUMBER = 2
    )
    (
    input         reset,
    input         clock,

    input control_read,
    input control_write,
    input [4:0] control_address,
    input [31:0] control_writedata,
    output logic [31:0] control_readdata,


    input  [24*PIX_IN_PARALLEL-1:0] din_0_data         ,din_1_data         ,din_2_data         ,din_3_data         ,
    input                           din_0_valid        ,din_1_valid        ,din_2_valid        ,din_3_valid        ,
    input                           din_0_startofpacket,din_1_startofpacket,din_2_startofpacket,din_3_startofpacket,
    input                           din_0_endofpacket  ,din_1_endofpacket  ,din_2_endofpacket  ,din_3_endofpacket  ,
    input  [ PIX_IN_PARALLEL-1:0]   din_0_empty        ,din_1_empty        ,din_2_empty        ,din_3_empty        ,
    output logic                    din_0_ready        ,din_1_ready        ,din_2_ready        ,din_3_ready        ,

    input  [24*PIX_IN_PARALLEL-1:0] din_4_data         ,din_5_data         ,din_6_data         ,din_7_data         ,
    input                           din_4_valid        ,din_5_valid        ,din_6_valid        ,din_7_valid        ,
    input                           din_4_startofpacket,din_5_startofpacket,din_6_startofpacket,din_7_startofpacket,
    input                           din_4_endofpacket  ,din_5_endofpacket  ,din_6_endofpacket  ,din_7_endofpacket  ,
    input  [ PIX_IN_PARALLEL-1:0]   din_4_empty        ,din_5_empty        ,din_6_empty        ,din_7_empty        ,
    output logic                    din_4_ready        ,din_5_ready        ,din_6_ready        ,din_7_ready        ,

  
    output logic [24*PIX_IN_PARALLEL-1:0] dout_0_data         ,dout_1_data         ,dout_2_data         ,dout_3_data         ,
    output logic                          dout_0_valid        ,dout_1_valid        ,dout_2_valid        ,dout_3_valid        ,
    output logic                          dout_0_startofpacket,dout_1_startofpacket,dout_2_startofpacket,dout_3_startofpacket,
    output logic                          dout_0_endofpacket  ,dout_1_endofpacket  ,dout_2_endofpacket  ,dout_3_endofpacket  ,
    output logic [PIX_IN_PARALLEL-1:0]    dout_0_empty        ,dout_1_empty        ,dout_2_empty        ,dout_3_empty        ,
    input                                 dout_0_ready        ,dout_1_ready        ,dout_2_ready        ,dout_3_ready        ,

    output logic [24*PIX_IN_PARALLEL-1:0] dout_4_data         ,dout_5_data         ,dout_6_data         ,dout_7_data         ,
    output logic                          dout_4_valid        ,dout_5_valid        ,dout_6_valid        ,dout_7_valid        ,
    output logic                          dout_4_startofpacket,dout_5_startofpacket,dout_6_startofpacket,dout_7_startofpacket,
    output logic                          dout_4_endofpacket  ,dout_5_endofpacket  ,dout_6_endofpacket  ,dout_7_endofpacket  ,
    output logic [PIX_IN_PARALLEL-1:0]    dout_4_empty        ,dout_5_empty        ,dout_6_empty        ,dout_7_empty        ,
    input                                 dout_4_ready        ,dout_5_ready        ,dout_6_ready        ,dout_7_ready        
    
);
localparam INPUT_NUM = 8;
localparam OUTPUT_NUM = 8;
logic [INPUT_NUM-1:0] next_outp_control[INPUT_NUM-1:0];
logic [INPUT_NUM-1:0] outp_control[INPUT_NUM-1:0];
logic [OUTPUT_NUM-1:0] out_changed;
logic output_switch;
logic control;
logic [INPUT_NUM-1:0] consume_mode;
always @(posedge clock or negedge reset)
    if(~reset) begin
        out_changed <= '0;
        for (int i = 0; i < INPUT_NUM; i++) begin
                outp_control[i] <= '0;
                next_outp_control[i] <='0;
            end 
        output_switch <= '0;
        control <= 1'b0;
        consume_mode <= '0;
    end else begin
        output_switch<= 1'b0;
        if(output_switch)begin
            out_changed <= '0;
            for (int i = 0; i < OUTPUT_NUM; i++)
                outp_control[i] <= next_outp_control[i];
        end
        if(control_write)
            case(control_address)
                5'd0:control <= control_writedata[0];
                5'd3:begin
                    output_switch <= control_writedata[0];
                end
                5'd4,5'd5,5'd6,5'd7,5'd8,5'd9,5'd10,5'd11:begin
                    next_outp_control[control_address - 5'd4] <= control_writedata[INPUT_NUM-1:0];
                    out_changed[control_address - 5'd4] <= 1'b1;
                end
                5'd16:consume_mode <= control_writedata[INPUT_NUM-1:0];
                default: begin end
            endcase
        if(control_read)
            case(control_address)
                5'd0:control_readdata <= control;
                5'd4,5'd5,5'd6,5'd7,5'd8,5'd9,5'd10,5'd11:control_readdata <= next_outp_control[control_address - 5'd4];
                5'd16:control_readdata <= consume_mode;
                default: begin end      
            endcase
        else control_readdata <= '0;
    end

logic [24*PIX_IN_PARALLEL-1:0]in_data_sig[INPUT_NUM-1:0];
logic [INPUT_NUM-1:0]in_valid_sig;
logic [INPUT_NUM-1:0]in_sop_sig;
logic [INPUT_NUM-1:0]in_eop_sig;
logic [PIX_IN_PARALLEL-1:0]in_empty_sig[INPUT_NUM-1:0];
assign in_data_sig[0] = din_0_data;assign in_valid_sig[0] = din_0_valid;
assign in_data_sig[1] = din_1_data;assign in_valid_sig[1] = din_1_valid;
assign in_data_sig[2] = din_2_data;assign in_valid_sig[2] = din_2_valid;
assign in_data_sig[3] = din_3_data;assign in_valid_sig[3] = din_3_valid;
assign in_data_sig[4] = din_4_data;assign in_valid_sig[4] = din_4_valid;
assign in_data_sig[5] = din_5_data;assign in_valid_sig[5] = din_5_valid;
assign in_data_sig[6] = din_6_data;assign in_valid_sig[6] = din_6_valid;
assign in_data_sig[7] = din_7_data;assign in_valid_sig[7] = din_7_valid;

assign in_sop_sig[0] = din_0_startofpacket; assign in_eop_sig[0] = din_0_endofpacket; assign in_empty_sig[0] =  din_0_empty;
assign in_sop_sig[1] = din_1_startofpacket; assign in_eop_sig[1] = din_1_endofpacket; assign in_empty_sig[1] =  din_1_empty;
assign in_sop_sig[2] = din_2_startofpacket; assign in_eop_sig[2] = din_2_endofpacket; assign in_empty_sig[2] =  din_2_empty;
assign in_sop_sig[3] = din_3_startofpacket; assign in_eop_sig[3] = din_3_endofpacket; assign in_empty_sig[3] =  din_3_empty;
assign in_sop_sig[4] = din_4_startofpacket; assign in_eop_sig[4] = din_4_endofpacket; assign in_empty_sig[4] =  din_4_empty;
assign in_sop_sig[5] = din_5_startofpacket; assign in_eop_sig[5] = din_5_endofpacket; assign in_empty_sig[5] =  din_5_empty;
assign in_sop_sig[6] = din_6_startofpacket; assign in_eop_sig[6] = din_6_endofpacket; assign in_empty_sig[6] =  din_6_empty;
assign in_sop_sig[7] = din_7_startofpacket; assign in_eop_sig[7] = din_7_endofpacket; assign in_empty_sig[7] =  din_7_empty;

logic [24*PIX_IN_PARALLEL-1:0]data_sig[OUTPUT_NUM-1:0];
logic [OUTPUT_NUM-1:0]valid_sig;
logic [OUTPUT_NUM-1:0]sop_sig;
logic [OUTPUT_NUM-1:0]eop_sig;
logic [PIX_IN_PARALLEL-1:0]empty_sig[OUTPUT_NUM-1:0];
assign dout_0_data = data_sig[0];assign dout_0_valid = valid_sig[0];
assign dout_1_data = data_sig[1];assign dout_1_valid = valid_sig[1];
assign dout_2_data = data_sig[2];assign dout_2_valid = valid_sig[2];
assign dout_3_data = data_sig[3];assign dout_3_valid = valid_sig[3];
assign dout_4_data = data_sig[4];assign dout_4_valid = valid_sig[4];
assign dout_5_data = data_sig[5];assign dout_5_valid = valid_sig[5];
assign dout_6_data = data_sig[6];assign dout_6_valid = valid_sig[6];
assign dout_7_data = data_sig[7];assign dout_7_valid = valid_sig[7];

assign dout_0_startofpacket = sop_sig[0]; assign dout_0_endofpacket = eop_sig[0]; assign dout_0_empty = empty_sig[0];
assign dout_1_startofpacket = sop_sig[1]; assign dout_1_endofpacket = eop_sig[1]; assign dout_1_empty = empty_sig[1];
assign dout_2_startofpacket = sop_sig[2]; assign dout_2_endofpacket = eop_sig[2]; assign dout_2_empty = empty_sig[2];
assign dout_3_startofpacket = sop_sig[3]; assign dout_3_endofpacket = eop_sig[3]; assign dout_3_empty = empty_sig[3];
assign dout_4_startofpacket = sop_sig[4]; assign dout_4_endofpacket = eop_sig[4]; assign dout_4_empty = empty_sig[4];
assign dout_5_startofpacket = sop_sig[5]; assign dout_5_endofpacket = eop_sig[5]; assign dout_5_empty = empty_sig[5];
assign dout_6_startofpacket = sop_sig[6]; assign dout_6_endofpacket = eop_sig[6]; assign dout_6_empty = empty_sig[6];
assign dout_7_startofpacket = sop_sig[7]; assign dout_7_endofpacket = eop_sig[7]; assign dout_7_empty = empty_sig[7];

always_comb
    if((~reset)||(!control)) begin
        for (int i = 0; i < OUTPUT_NUM; i++) begin
            data_sig[i] = '0;
            valid_sig[i] = '0;
            sop_sig[i] = '0;
            eop_sig[i] = '0;
            empty_sig[i] = '0;
        end
    end else begin
    for (int i = 0; i < OUTPUT_NUM; i++) begin
        if(outp_control[i][0])begin
            data_sig[i]  = in_data_sig[0];
            valid_sig[i] = (output_switch && out_changed[i]) ? 1'b1 : in_valid_sig[0];
            sop_sig[i]   = (output_switch && out_changed[i]) ? 1'b0 : in_sop_sig[0];
            eop_sig[i]   = (output_switch && out_changed[i]) ? 1'b1 : in_eop_sig[0];
            empty_sig[i] = in_empty_sig[0];
        end else if(outp_control[i][1])begin
            data_sig[i]  = in_data_sig[1];
            valid_sig[i] = (output_switch && out_changed[i]) ? 1'b1 : in_valid_sig[1];
            sop_sig[i]   = (output_switch && out_changed[i]) ? 1'b0 : in_sop_sig[1];
            eop_sig[i]   = (output_switch && out_changed[i]) ? 1'b1 : in_eop_sig[1];
            empty_sig[i] = in_empty_sig[1];
        end else if(outp_control[i][2])begin
            data_sig[i]  = in_data_sig[2];
            valid_sig[i] = (output_switch && out_changed[i]) ? 1'b1 : in_valid_sig[2];
            sop_sig[i]   = (output_switch && out_changed[i]) ? 1'b0 : in_sop_sig[2];
            eop_sig[i]   = (output_switch && out_changed[i]) ? 1'b1 : in_eop_sig[2];
            empty_sig[i] = in_empty_sig[2];
        end else if(outp_control[i][3])begin
            data_sig[i]  = in_data_sig[3];
            valid_sig[i] = (output_switch && out_changed[i]) ? 1'b1 : in_valid_sig[3];
            sop_sig[i]   = (output_switch && out_changed[i]) ? 1'b0 : in_sop_sig[3];
            eop_sig[i]   = (output_switch && out_changed[i]) ? 1'b1 : in_eop_sig[3];
            empty_sig[i] = in_empty_sig[3];
        end else if(outp_control[i][4])begin
            data_sig[i]  = in_data_sig[4];
            valid_sig[i] = (output_switch && out_changed[i]) ? 1'b1 : in_valid_sig[4];
            sop_sig[i]   = (output_switch && out_changed[i]) ? 1'b0 : in_sop_sig[4];
            eop_sig[i]   = (output_switch && out_changed[i]) ? 1'b1 : in_eop_sig[4];
            empty_sig[i] = in_empty_sig[4];
        end else if(outp_control[i][5])begin
            data_sig[i]  = in_data_sig[5];
            valid_sig[i] = (output_switch && out_changed[i]) ? 1'b1 : in_valid_sig[5];
            sop_sig[i]   = (output_switch && out_changed[i]) ? 1'b0 : in_sop_sig[5];
            eop_sig[i]   = (output_switch && out_changed[i]) ? 1'b1 : in_eop_sig[5];
            empty_sig[i] = in_empty_sig[5];
        end else if(outp_control[i][6])begin
            data_sig[i]  = in_data_sig[6];
            valid_sig[i] = (output_switch && out_changed[i]) ? 1'b1 : in_valid_sig[6];
            sop_sig[i]   = (output_switch && out_changed[i]) ? 1'b0 : in_sop_sig[6];
            eop_sig[i]   = (output_switch && out_changed[i]) ? 1'b1 : in_eop_sig[6];
            empty_sig[i] = in_empty_sig[6];
        end else if(outp_control[i][7])begin
            data_sig[i]  = in_data_sig[7];
            valid_sig[i] = (output_switch && out_changed[i]) ? 1'b1 : in_valid_sig[7];
            sop_sig[i]   = (output_switch && out_changed[i]) ? 1'b0 : in_sop_sig[7];
            eop_sig[i]   = (output_switch && out_changed[i]) ? 1'b1 : in_eop_sig[7];
            empty_sig[i] = in_empty_sig[7];             
        end else begin
            data_sig[i]   = '0;
            valid_sig[i]  = '0;
            sop_sig[i]    = '0;
            eop_sig[i]    = '0;
            empty_sig[i]  = '0;
        end
    end
end

logic [OUTPUT_NUM-1:0]out_ready_sig;
assign out_ready_sig[0] = dout_0_ready;
assign out_ready_sig[1] = dout_1_ready;
assign out_ready_sig[2] = dout_2_ready;
assign out_ready_sig[3] = dout_3_ready;
assign out_ready_sig[4] = dout_4_ready;
assign out_ready_sig[5] = dout_5_ready;
assign out_ready_sig[6] = dout_6_ready;
assign out_ready_sig[7] = dout_7_ready;
logic [OUTPUT_NUM-1:0] ready_check [INPUT_NUM-1:0];
logic [INPUT_NUM-1:0] input_enabled;
genvar i;genvar y;
generate    
    for ( i = 0; i < INPUT_NUM; i++) begin : ZHHZ
        assign input_enabled [i] = |{outp_control[0][i], outp_control[1][i], outp_control[2][i], outp_control[3][i], outp_control[4][i]
                                  ,outp_control[5][i], outp_control[6][i], outp_control[7][i]
                                    };
        for ( y = 0; y < OUTPUT_NUM; y++) begin : HZZH
            assign ready_check[i][y] = (outp_control[y] != (8'd1<<i)) || ( (outp_control[y] == (8'd1<<i) ) & ( out_ready_sig[y] ) );
        end
    end
endgenerate
logic [INPUT_NUM-1:0]ready_sig;
assign din_0_ready = ready_sig[0];
assign din_1_ready = ready_sig[1];
assign din_2_ready = ready_sig[2];
assign din_3_ready = ready_sig[3];
assign din_4_ready = ready_sig[4];
assign din_5_ready = ready_sig[5];
assign din_6_ready = ready_sig[6];
assign din_7_ready = ready_sig[7];
always_comb begin
    for (int i = 0; i < INPUT_NUM; i++) begin
        if(~reset)                               ready_sig[i] = 1'b0;
        else if(!control)                        ready_sig[i] = consume_mode[i]; 
        else if(output_switch && out_changed[i]) ready_sig[i] = 1'b0; 
        else                                     ready_sig[i] = (&ready_check[i]) ? 1'b1 : ( ( !input_enabled[i] ) && consume_mode[i] );  
    end
end

endmodule 
