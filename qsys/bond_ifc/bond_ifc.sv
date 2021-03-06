module bond_ifc (
	input                csi_clk                     ,
	input                rsi_reset                   ,
	input  logic [ 25:0] avs_slave_address           ,
	input  logic [ 15:0] avs_slave_byteenable        ,
	input  logic         avs_slave_read              ,
	output logic [127:0] avs_slave_readdata          ,
	output logic         avs_slave_readdatavalid     ,
	input  logic         avs_slave_write             ,
	input  logic [127:0] avs_slave_writedata         ,
	output logic         avs_slave_waitrequest       ,
	input  logic [  3:0] avs_slave_burstcount        ,
	input  logic         avs_slave_beginbursttransfer,
	output logic [ 25:0] avm_ddr0_address            ,
	output logic [  7:0] avm_ddr0_byteenable         ,
	output logic         avm_ddr0_read               ,
	input  logic [ 63:0] avm_ddr0_readdata           ,
	input  logic         avm_ddr0_readdatavalid      ,
	output logic         avm_ddr0_write              ,
	output logic [ 63:0] avm_ddr0_writedata          ,
	input  logic         avm_ddr0_waitrequest        ,
	output logic [  3:0] avm_ddr0_burstcount         ,
	output logic         avm_ddr0_beginbursttransfer ,
	output logic [ 25:0] avm_ddr1_address            ,
	output logic [  7:0] avm_ddr1_byteenable         ,
	output logic         avm_ddr1_read               ,
	input  logic [ 63:0] avm_ddr1_readdata           ,
	input  logic         avm_ddr1_readdatavalid      ,
	output logic         avm_ddr1_write              ,
	output logic [ 63:0] avm_ddr1_writedata          ,
	input  logic         avm_ddr1_waitrequest        ,
	output logic [  3:0] avm_ddr1_burstcount         ,
	output logic         avm_ddr1_beginbursttransfer
);

	assign avs_slave_waitrequest   = avm_ddr0_waitrequest && avm_ddr1_waitrequest;
	assign avs_slave_readdatavalid = avm_ddr0_readdatavalid && avm_ddr1_readdatavalid;
	assign avs_slave_readdata      = {avm_ddr1_readdata, avm_ddr0_readdata};

	always_comb
		begin
			avm_ddr0_burstcount         = avs_slave_burstcount;
			avm_ddr0_address            = avs_slave_address;
			avm_ddr0_read               = avs_slave_read;
			avm_ddr0_write              = avs_slave_write;
			avm_ddr0_beginbursttransfer = avs_slave_beginbursttransfer;
			avm_ddr1_burstcount         = avs_slave_burstcount;
			avm_ddr1_address            = avs_slave_address;
			avm_ddr1_read               = avs_slave_read;
			avm_ddr1_write              = avs_slave_write;
			avm_ddr1_beginbursttransfer = avs_slave_beginbursttransfer;
		end

	always_comb
		begin
			avm_ddr0_writedata  = avs_slave_writedata[63:0];
			avm_ddr1_writedata  = avs_slave_writedata[127:64];
			avm_ddr0_byteenable = avs_slave_byteenable[7:0];
			avm_ddr1_byteenable = avs_slave_byteenable[15:8];
		end


endmodule