LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.milstd_1553_pkg.ALL;

ENTITY MilStd1553_Transceiver IS
	PORT(
		Avalon_nReset         : IN  STD_LOGIC := '0';
		Avalon_Clock          : IN  STD_LOGIC;
		
		AVS_waitrequest       : OUT STD_LOGIC;
		AVS_address           : IN  STD_LOGIC_VECTOR(  1 DOWNTO 0 );
		AVS_byteenable        : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AVS_read              : IN  STD_LOGIC;
		AVS_readdata          : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH_PKG - 1 ) DOWNTO 0 );
		AVS_readdatavalid     : OUT STD_LOGIC;
		AVS_write             : IN  STD_LOGIC;
		AVS_writedata         : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH_PKG - 1 ) DOWNTO 0 );
		
		----------- for PCIE Slave Avalon-MM port -----------------
		AV2PCIE_waitrequest   : OUT STD_LOGIC;
		AV2PCIE_address       : IN  STD_LOGIC_VECTOR( ( RAM_RX_ADDR_WIDTH_PKG - 1 ) DOWNTO 0 );
		AV2PCIE_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2PCIE_read          : IN  STD_LOGIC;
		AV2PCIE_readdata      : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH_PKG - 1 ) DOWNTO 0 );
		AV2PCIE_readdatavalid : OUT STD_LOGIC;
		AV2PCIE_write         : IN  STD_LOGIC;
		AV2PCIE_writedata     : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH_PKG - 1 ) DOWNTO 0 );
		
		-------------- for RAM Master Avalon-MM port 1 ------------
		AV2RAM_waitrequest    : IN  STD_LOGIC;
		AV2RAM_address        : OUT STD_LOGIC_VECTOR( ( RAM_RX_ADDR_WIDTH_PKG - 1 ) DOWNTO 0 );
		AV2RAM_byteenable     : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2RAM_read           : OUT STD_LOGIC;
		AV2RAM_readdata       : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH_PKG - 1 ) DOWNTO 0 );
		AV2RAM_readdatavalid  : IN  STD_LOGIC;
		AV2RAM_write          : OUT STD_LOGIC;
		AV2RAM_writedata      : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH_PKG - 1 ) DOWNTO 0 );
		
		-------------- for RAM Master Avalon-MM port 2 ------------
		AV2RAM2_waitrequest    : IN  STD_LOGIC;
		AV2RAM2_address        : OUT STD_LOGIC_VECTOR( ( RAM_RX_ADDR_WIDTH_PKG - 1 ) DOWNTO 0 );
		AV2RAM2_byteenable     : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2RAM2_read           : OUT STD_LOGIC;
		AV2RAM2_readdata       : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH_PKG - 1 ) DOWNTO 0 );
		AV2RAM2_readdatavalid  : IN  STD_LOGIC;
		AV2RAM2_write          : OUT STD_LOGIC;
		AV2RAM2_writedata      : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH_PKG - 1 ) DOWNTO 0 );
		
		Interrupt             : OUT STD_LOGIC;
		
		LineTurnOFF1          : OUT STD_LOGIC;
		LineTurnOFF2          : OUT STD_LOGIC;
		
		MilStd1553_Clock      : IN  STD_LOGIC;
		
		MilStd1553_TxEn1      : OUT STD_LOGIC;
		MilStd1553_RxEn1      : OUT STD_LOGIC;
		MilStd1553_LineIA1    : IN  STD_LOGIC;
		MilStd1553_LineIB1    : IN  STD_LOGIC;
		MilStd1553_LineOA1    : OUT STD_LOGIC;
		MilStd1553_LineOB1    : OUT STD_LOGIC;
		
		MilStd1553_TxEn2      : OUT STD_LOGIC;
		MilStd1553_RxEn2      : OUT STD_LOGIC;
		MilStd1553_LineIA2    : IN  STD_LOGIC;
		MilStd1553_LineIB2    : IN  STD_LOGIC;
		MilStd1553_LineOA2    : OUT STD_LOGIC;
		MilStd1553_LineOB2    : OUT STD_LOGIC;
		NodeAddrHard          : IN  STD_LOGIC_VECTOR( 4 DOWNTO 0 )
		
	);
	
END MilStd1553_Transceiver;





ARCHITECTURE logic OF MilStd1553_Transceiver IS
	
	COMPONENT AVMM_Master_FIFO IS
	GENERIC(
		CLOCK_FREQUENCE       : INTEGER := 62500000;
		AVM_WRITE_ACKNOWLEDGE : INTEGER := 15;
		AVM_READ_ACKNOWLEDGE  : INTEGER := 15;
		AVM_DATA_WIDTH        : INTEGER := 32;
		AVM_ADDR_WIDTH        : INTEGER := 16;
		FIFO_WORDS_NUM        : INTEGER := 32;
		FIFO_USED_WIDTH       : INTEGER := 5
	);  
	PORT(
		nReset            : IN  STD_LOGIC;
		Clock             : IN  STD_LOGIC;
		WrEn              : IN  STD_LOGIC;
		RdEn              : IN  STD_LOGIC;
		AddrIn            : IN  STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
		WrDataIn          : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		ByteEnCode        : IN  STD_LOGIC_VECTOR( ( ( AVM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
		Ready             : OUT STD_LOGIC;
		RdDataOut         : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		avm_waitrequest   : IN  STD_LOGIC;
		avm_readdata      : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		avm_readdatavalid : IN  STD_LOGIC;
		avm_address       : OUT STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
		avm_byteenable    : OUT STD_LOGIC_VECTOR( ( ( AVM_DATA_WIDTH / 8 ) - 1 )  DOWNTO 0 );
		avm_read          : OUT STD_LOGIC;
		avm_write         : OUT STD_LOGIC;
		avm_writedata     : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 )
	);
	END COMPONENT;


	
	COMPONENT milstd1553_RxControl IS
	GENERIC(
		AddrWidth : INTEGER := 11;
		DataWidth : INTEGER := 32
	);
	PORT(
		Enable     : IN  STD_LOGIC;
		Clk        : IN  STD_LOGIC;
		
		nEmpty0     : IN  STD_LOGIC; 
		TxErr0      : IN  STD_LOGIC; 
		
		nEmpty1     : IN  STD_LOGIC; 
		TxErr1      : IN  STD_LOGIC; 
		
		
		WordIn     : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		WordStat   : IN  STD_LOGIC_VECTOR(  1 DOWNTO 0 );
		ParError   : IN  STD_LOGIC;
		
		NodeAddr   : IN  STD_LOGIC_VECTOR(  4 DOWNTO 0 );
		
		WaitReq    : IN  STD_LOGIC;
		RdReq0     : OUT STD_LOGIC;
		RdReq1     : OUT STD_LOGIC;
		WrEn       : OUT STD_LOGIC;
		DataOut    : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		ByteEn     : OUT STD_LOGIC_VECTOR( ( ( DataWidth / 8 ) - 1 ) DOWNTO 0 ); 
		RAMAddr    : OUT STD_LOGIC_VECTOR( ( AddrWidth - 1 ) DOWNTO 0 );
		StateReg   : OUT STD_LOGIC_VECTOR(  7 DOWNTO 0 );
		Manage     : OUT STD_LOGIC_VECTOR(  7 DOWNTO 0 );
		ComReady   : OUT STD_LOGIC;
		RxChan     : OUT STD_LOGIC;
		Data_Com   : OUT STD_LOGIC;
		
		RxWrdCnt   : OUT STD_LOGIC_VECTOR( 5 DOWNTO 0 );
		RxSubAddr  : OUT STD_LOGIC_VECTOR( 4 DOWNTO 0 );
		RxTx       : OUT STD_LOGIC;
		TxBlock0   : OUT STD_LOGIC;  -- for enable/disable transmitter in other channel
		TxBlock1   : OUT STD_LOGIC;
		BuffBusy   : IN  STD_LOGIC
		
	);	
	END COMPONENT;

	
	
	COMPONENT milstd1553rxphy IS
	PORT(
		Enable      : IN  STD_LOGIC;
		ClockIn     : IN  STD_LOGIC;  -- x16 freq = 16 MHz
		InputA      : IN  STD_LOGIC;
		InputB      : IN  STD_LOGIC;
		RdClk       : IN  STD_LOGIC;
		RdEn        : IN  STD_LOGIC;
		Transmit    : IN  STD_LOGIC;----
		TxWord      : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 );---
		TxErr       : OUT STD_LOGIC;
		Strobe      : OUT STD_LOGIC;
		nEmpty      : OUT STD_LOGIC;
		DataOut     : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		StatOut     : OUT STD_LOGIC_VECTOR(  1 DOWNTO 0 ); -- 10 = COMMAND_STATUS; 01 = DATA
		ParError    : OUT STD_LOGIC;
		Rx_Flag     : OUT STD_LOGIC
		
	);
	END COMPONENT;




	COMPONENT milstd1553txphy IS
	PORT(
		Enable    :  IN STD_LOGIC;
		Clk16MHz  :  IN STD_LOGIC;
		WrClk     :  IN STD_LOGIC;
		WrEn      :  IN STD_LOGIC;
		WordIn    :  IN STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
		WordStat  :  IN STD_LOGIC_VECTOR(  1 DOWNTO 0 );
		OutA      : OUT STD_LOGIC;
		OutB      : OUT STD_LOGIC;
		Transmit  : OUT STD_LOGIC;
		TxWord    : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		TxInhibit : OUT STD_LOGIC;
		Full      : OUT STD_LOGIC	
	);
	END COMPONENT;
	
	

	COMPONENT milstd1553_TxControl IS
	GENERIC(
		RAM_DataWidth : INTEGER := 32;
		AddrWidth     : INTEGER := 32;
		AvAddrWidth   : INTEGER := 32
	);
	PORT(
		Enable    : IN STD_LOGIC;
		Clk       : IN STD_LOGIC;
		
		----------- MANAGE interface ------------
		Manage    : IN STD_LOGIC_VECTOR(  7 DOWNTO 0 );
		ComReady  : IN STD_LOGIC;
		RxChan    : IN STD_LOGIC;
		Data_Com  : IN STD_LOGIC;
		
		---------- RAM Interface -----------------
		Addr      : OUT STD_LOGIC_VECTOR( ( AddrWidth - 1 ) DOWNTO 0 );
		ByteEn    : OUT STD_LOGIC_VECTOR( ( ( RAM_DataWidth / 8 ) - 1 ) DOWNTO 0 );
		RdEn      : OUT STD_LOGIC;
		Load      : IN STD_LOGIC;
		WordIn    : IN STD_LOGIC_VECTOR( ( RAM_DataWidth - 1 ) DOWNTO 0 );
		
		-------- Tx Wr FIFO interfcae --------------
		DataOut    : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		WordStat   : OUT STD_LOGIC_VECTOR(  1 DOWNTO 0 );
		FIFO_WrEn0 : OUT STD_LOGIC;
		FIFO_WrEn1 : OUT STD_LOGIC;
		FIFO_Full0 : IN  STD_LOGIC;
		FIFO_Full1 : IN  STD_LOGIC;
		
		---------- Config -----------------
		NodeAddr    : IN STD_LOGIC_VECTOR( 4 DOWNTO 0 );	
		TstNodeAddr : IN STD_LOGIC_VECTOR( 4 DOWNTO 0 );
		TstSubAddr  : IN STD_LOGIC_VECTOR( 4 DOWNTO 0 );
		TstWordNum  : IN STD_LOGIC_VECTOR( 4 DOWNTO 0 );
		TstTxChan   : IN STD_LOGIC;
		TestEn      : IN STD_LOGIC;
		
		---------- WORK STATES -------------
		StateReg     : OUT STD_LOGIC_VECTOR(  7 DOWNTO 0 );
		SendWordsNum : OUT STD_LOGIC_VECTOR( 5 DOWNTO 0 ) := ( OTHERS => '0' );
		
		TxStart   : IN STD_LOGIC;
		TxComplete   : IN STD_LOGIC;
		BuffBusy  : IN STD_LOGIC
		
	
	);	
	
	END COMPONENT;
	
	
	COMPONENT ram_mux IS 
	GENERIC(
		RamAddrWidth : INTEGER := 13;
		RdAddrWidth  : INTEGER := 12;
		WrAddrWidth  : INTEGER := 13;
		BEWidth      : INTEGER := 4
	);
	PORT(
		Clk        : IN STD_LOGIC;
		RdEn       : IN STD_LOGIC;
		WrEn       : IN STD_LOGIC;
		RdAddr     : IN STD_LOGIC_VECTOR( ( RdAddrWidth - 1 ) DOWNTO 0 );
		RdByteEn   : IN STD_LOGIC_VECTOR( ( BEWidth - 1 ) DOWNTO 0 );
		WrAddr     : IN STD_LOGIC_VECTOR( ( WrAddrWidth - 1 ) DOWNTO 0 );
		WrByteEn   : IN STD_LOGIC_VECTOR( ( BEWidth - 1 ) DOWNTO 0 );
		WrDataIn   : IN STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		RamRdEn    : OUT STD_LOGIC;
		RamWrEn    : OUT STD_LOGIC;
		RamAddr    : OUT STD_LOGIC_VECTOR( ( RamAddrWidth - 1 ) DOWNTO 0 );
		RamWrData  : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		RamByteEn  : OUT STD_LOGIC_VECTOR( ( BEWidth - 1 ) DOWNTO 0 )
	);
	END COMPONENT;
	
	


	COMPONENT mil_RxPhyMUX IS
	PORT(
		RxWord1       : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
		RxWordStat1   : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		RxParErr1     : IN  STD_LOGIC;
		RdEn1         : IN  STD_LOGIC;
		RxWord2       : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
		RxWordStat2   : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		RxParErr2     : IN  STD_LOGIC;
		RdEn2         : IN  STD_LOGIC;
		RxWordOut     : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		RxWordStatOut : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		RxParErrOut   : OUT STD_LOGIC
		
	);
	END COMPONENT;
	
	

	
	COMPONENT TxPhyDMUX IS
	PORT(
		WordIN   : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		StatIN   : IN  STD_LOGIC_VECTOR(  1 DOWNTO 0 );
		WrEn0    : IN  STD_LOGIC;
		WrEn1    : IN  STD_LOGIC;
		WordOut0 : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		StatOut0 : OUT STD_LOGIC_VECTOR(  1 DOWNTO 0 );
		WordOut1 : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		StatOut1 : OUT STD_LOGIC_VECTOR(  1 DOWNTO 0 )
	);
	END COMPONENT;
	


	
	--COMPONENT AvMM2Mux1 IS
	--GENERIC(
		--DataWidth : INTEGER := 32;
		--AddrWidth : INTEGER := 16
	--);
	--PORT(
		--Avalon_Clock       : IN STD_LOGIC;
		--Avalon_nReset      : IN STD_LOGIC;
		------------------ Avalon-MM IN1 --------------------------------------
		--AV2RAM_waitrequest   : OUT STD_LOGIC;
		--AV2RAM_address       : IN  STD_LOGIC_VECTOR( ( AddrWidth - 1 )  DOWNTO 0 );
		--AV2RAM_byteenable    : IN  STD_LOGIC_VECTOR( (DataWidth/8 - 1 ) DOWNTO 0 );
		--AV2RAM_read          : IN  STD_LOGIC;
		--AV2RAM_readdata      : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		--AV2RAM_readdatavalid : OUT STD_LOGIC;
		--AV2RAM_write         : IN  STD_LOGIC;
		--AV2RAM_writedata     : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
	
		----------------- Avalon-MM IN2  ---------------------------------------	
		--AV2RAM2_waitrequest   : OUT STD_LOGIC;
		--AV2RAM2_address       : IN  STD_LOGIC_VECTOR( ( AddrWidth - 1 ) DOWNTO 0 );
		--AV2RAM2_byteenable    : IN  STD_LOGIC_VECTOR( ( DataWidth/8 - 1 ) DOWNTO 0 );
		--AV2RAM2_read          : IN  STD_LOGIC;
		--AV2RAM2_readdata      : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		--AV2RAM2_readdatavalid : OUT STD_LOGIC;
		--AV2RAM2_write         : IN  STD_LOGIC;
		--AV2RAM2_writedata     : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		
		----------------- Avalon-MM OUT --------------------------------------
		--AVMO_waitrequest   : IN  STD_LOGIC;
		--AVMO_address       : OUT STD_LOGIC_VECTOR( ( AddrWidth - 1 ) DOWNTO 0 );
		--AVMO_byteenable    : OUT STD_LOGIC_VECTOR( ( DataWidth/8 - 1 ) DOWNTO 0 );
		--AVMO_read          : OUT STD_LOGIC;
		--AVMO_readdata      : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		--AVMO_readdatavalid : IN  STD_LOGIC;
		--AVMO_write         : OUT STD_LOGIC;
		--AVMO_writedata     : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 )
	--);
	--END COMPONENT;
	

	
	COMPONENT timer IS
	PORT(
		Enable   : IN  STD_LOGIC;
		Clk_x16  : IN  STD_LOGIC;
		Time     : IN  STD_LOGIC_VECTOR( 19 DOWNTO 0 );
		ARST     : IN  STD_LOGIC;
		Single   : IN  STD_LOGIC; -- 1 = Single, 0 - continuous work
		Ready    : OUT STD_LOGIC
	);
	END COMPONENT;



	COMPONENT pgen IS
	GENERIC(
		Edge : STD_LOGIC
	);
	PORT(
		Enable : IN  STD_LOGIC;
		Clk    : IN  STD_LOGIC;
		Input  : IN  STD_LOGIC;
		Output : OUT STD_LOGIC
	);	
	END COMPONENT;
	
	--======================== CONSTANTS =================================
	CONSTANT AV_RAM_ADDR_WIDTH : INTEGER := RAM_RX_ADDR_WIDTH_PKG; --12;
	CONSTANT RAM_DATA_WIDTH    : INTEGER := RAM_DATA_WIDTH_PKG;    --32;
	CONSTANT RAM_ADDR_WIDTH    : INTEGER := RAM_RX_ADDR_WIDTH_PKG; --12;
	CONSTANT TX_RAM_ADDR_WIDTH : INTEGER := RAM_TX_ADDR_WIDTH_PKG; --12;
	
	CONSTANT TIMER_PAUSE_US     : INTEGER := 2;
	CONSTANT TIMER_CLK_FREQ_MHZ : INTEGER := 16;
	CONSTANT TIME_PAUSE         : STD_LOGIC_VECTOR := STD_LOGIC_VECTOR( TO_UNSIGNED( (TIMER_CLK_FREQ_MHZ * TIMER_PAUSE_US), 20 ) );
	
	CONSTANT DATA_OP            : STD_LOGIC := '1';
	CONSTANT COM_OP             : STD_LOGIC := '0';
	
	--======================== DATA TYPES ==================================
	TYPE   T_Avalon_State     IS ( AVALON_RESET, AVALON_IDLE, AVALON_WRITE, AVALON_ACK_WRITE, AVALON_READ, AVALON_ACK_READ );
	TYPE   T_Conf_Registers   IS ARRAY( 3 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	
	
	--========================== SIGNALS =======================================
	SIGNAL Signal_SlaveState  : T_Avalon_State   := AVALON_RESET;
	--SIGNAL Signal_Registers   : T_Conf_Registers := ( x"00000000", x"00000000", x"00000000", ( OTHERS => '1' ), ( OTHERS => '0' ), ( OTHERS => '0' ), ( OTHERS => '1' ), ( OTHERS => '0') );
	-- Signal_Registers(0) - ConfigREG (Receiver config register) R 
	-- Signal_Registers(1) - IntMaskREG ( Interrupt mask register) R
	-- Signal_Registers(2) - IntFlagREG ( Interrupt flags register) W (from RxSTATE, signal Transmit from TxPHY and calculations)
	-- Signal_Registers(3) - StateREG W (from MANAGE bytes 0 and 1 and CW_In)
	-- Signal_Registers(4-7) - reseved
	
	SIGNAL Signal_Registers   : T_Conf_Registers := ( ( OTHERS => '0' ), ( OTHERS => '0' ), ( OTHERS => '1' ), ( OTHERS => '0') );
	
------------------ PHY RX1 interface signals ----------------------
	SIGNAL RxPhy1_Enable       : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_ClockIn      : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_RdClk        : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_InputA       : STD_LOGIC                       := '0'; 
	SIGNAL RxPhy1_InputB       : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_Strobe       : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_DataOut      : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RxPhy1_StatOut      : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RxPhy1_ParErrOut    : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_RxFlagOut    : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_RdEn         : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_TxErr        : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_nEmpty       : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_Transmit 	   : STD_LOGIC                       := '0';
	SIGNAL RxPhy1_TxWord       : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );

------------------ PHY RX2 interface signals ----------------------
	SIGNAL RxPhy2_Enable       : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_ClockIn      : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_RdClk        : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_InputA       : STD_LOGIC                       := '0'; 
	SIGNAL RxPhy2_InputB       : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_Strobe       : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_DataOut      : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RxPhy2_StatOut      : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RxPhy2_ParErrOut    : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_RxFlagOut    : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_RdEn         : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_TxErr        : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_nEmpty       : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_Transmit 	   : STD_LOGIC                       := '0';
	SIGNAL RxPhy2_TxWord       : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );



-------------------- Rx Control interface signals --------------------------	
	SIGNAL RXCNTL_Enable_IN     :  STD_LOGIC := '0';
	SIGNAL RXCNTL_Clk_IN        :  STD_LOGIC := '0';

	SIGNAL RXCNTL_nEmpty0_IN    :  STD_LOGIC := '0'; 
	SIGNAL RXCNTL_TxErr0_IN     :  STD_LOGIC := '0'; 

	SIGNAL RXCNTL_nEmpty1_IN    :  STD_LOGIC := '0'; 
	SIGNAL RXCNTL_TxErr1_IN     :  STD_LOGIC := '0'; 


	SIGNAL RXCNTL_WordIn_IN     :  STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXCNTL_WordStat_IN   :  STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXCNTL_ParError_IN   :  STD_LOGIC := '0';

	SIGNAL RXCNTL_NodeAddr_IN   :  STD_LOGIC_VECTOR(  4 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXCNTL_NodeSTAT_IN   :  STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );

	SIGNAL RXCNTL_WaitReq_IN    :  STD_LOGIC := '0';
	SIGNAL RXCNTL_RdReq0_OUT    :  STD_LOGIC := '0';
	SIGNAL RXCNTL_RdReq1_OUT    :  STD_LOGIC := '0';
	SIGNAL RXCNTL_WrEn_OUT      :  STD_LOGIC := '0';
	SIGNAL RXCNTL_DataOut_OUT   :  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXCNTL_ByteEn_OUT    :  STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 ) := ( OTHERS => '0' ); 
	SIGNAL RXCNTL_RAMAddr_OUT   :  STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXCNTL_StateReg_OUT  :  STD_LOGIC_VECTOR(  7 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXCNTL_Manage_OUT    :  STD_LOGIC_VECTOR(  7 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXCNTL_ComReady_OUT  :  STD_LOGIC := '0';
	SIGNAL RXCNTL_RxChan_OUT    :  STD_LOGIC := '0';
	SIGNAL RXCNTL_Data_Com_OUT  :  STD_LOGIC := '0';

	SIGNAL RXCNTL_RxWrdCnt_OUT  :  STD_LOGIC_VECTOR( 5 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXCNTL_RxSubAddr_OUT :  STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXCNTL_RxTx_OUT      :  STD_LOGIC := '0';
	SIGNAL RXCNTL_TxBlock0_OUT  :  STD_LOGIC := '0';  -- for enable/disable transmitter in other channel
	SIGNAL RXCNTL_TxBlock1_OUT  :  STD_LOGIC := '0';
	SIGNAL RXCNTL_BuffBusy_IN   :  STD_LOGIC := '0';
	


--------------- Avalon-MM Master interface signals ------------------------
	SIGNAL AVMM_Clock        : STD_LOGIC                       := '0';
	SIGNAL AVMM_nReset       : STD_LOGIC                       := '0';
	SIGNAL AVMM_RdEn         : STD_LOGIC                       := '0';
	SIGNAL AVMM_Ready        : STD_LOGIC                       := '0';   		
	SIGNAL AVMM_RdDataOut    : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL AVMM_WrEn		 : STD_LOGIC                       := '0';
    SIGNAL AVMM_AddrIn       : STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
    SIGNAL AVMM_WrDataIn     : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
    SIGNAL AVMM_ByteEnCode   : STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
    
    SIGNAL AVM_waitrequest   : STD_LOGIC := '0';                                                 
    SIGNAL AVM_address       : STD_LOGIC_VECTOR( ( RAM_RX_ADDR_WIDTH_PKG - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
    SIGNAL AVM_byteenable    : STD_LOGIC_VECTOR(  3 DOWNTO 0 ) := ( OTHERS => '0' );                           
    SIGNAL AVM_read          : STD_LOGIC := '0';                                                 
    SIGNAL AVM_readdata      : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );   
    SIGNAL AVM_readdatavalid : STD_LOGIC := '0';                                                 
    SIGNAL AVM_write         : STD_LOGIC := '0';                                                 
    SIGNAL AVM_writedata     : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );   




----------------- PHY TX1 interface signals ----------------------
	SIGNAL TxPhy1_Clk16MHz   : STD_LOGIC                        := '0';
	SIGNAL TxPhy1_OutA       : STD_LOGIC                        := '0';
	SIGNAL TxPhy1_OutB       : STD_LOGIC                        := '0';
	SIGNAL TxPhy1_Enable   	 : STD_LOGIC                        := '0';
	SIGNAL TxPhy1_WordIn   	 : STD_LOGIC_VECTOR( 15 DOWNTO 0 )  := ( OTHERS => '0' );     
	SIGNAL TxPhy1_WordStat 	 : STD_LOGIC_VECTOR(  1 DOWNTO 0 )  := ( OTHERS => '0' );
	SIGNAL TxPhy1_Transmit 	 : STD_LOGIC                        := '0';
	SIGNAL TxPhy1_Inhibit 	 : STD_LOGIC                        := '0';
	SIGNAL TxPhy1_TxWord     : STD_LOGIC_VECTOR( 15 DOWNTO 0 )  := ( OTHERS => '0' );
	SIGNAL TxPhy1_WrEn       : STD_LOGIC                        := '0';
	SIGNAL TxPhy1_Full       : STD_LOGIC                        := '0';
	SIGNAL TxPhy1_WrClk      : STD_LOGIC                        := '0';

----------------- PHY TX2 interface signals ----------------------
	SIGNAL TxPhy2_Clk16MHz   : STD_LOGIC                        := '0';
	SIGNAL TxPhy2_OutA       : STD_LOGIC                        := '0';
	SIGNAL TxPhy2_OutB       : STD_LOGIC                        := '0';
	SIGNAL TxPhy2_Enable   	 : STD_LOGIC                        := '0';
	SIGNAL TxPhy2_WordIn   	 : STD_LOGIC_VECTOR( 15 DOWNTO 0 )  := ( OTHERS => '0' );     
	SIGNAL TxPhy2_WordStat 	 : STD_LOGIC_VECTOR(  1 DOWNTO 0 )  := ( OTHERS => '0' );
	SIGNAL TxPhy2_Transmit 	 : STD_LOGIC                        := '0';
	SIGNAL TxPhy2_Inhibit 	 : STD_LOGIC                        := '0';
	SIGNAL TxPhy2_TxWord     : STD_LOGIC_VECTOR( 15 DOWNTO 0 )  := ( OTHERS => '0' );
	SIGNAL TxPhy2_WrEn       : STD_LOGIC                        := '0';
	SIGNAL TxPhy2_Full       : STD_LOGIC                        := '0';
	SIGNAL TxPhy2_WrClk      : STD_LOGIC                        := '0';


----================= Tx Control interface signals ==========================
	SIGNAL TXCNTL_Enable_IN        : STD_LOGIC := '0';
	SIGNAL TXCNTL_Clk_IN           : STD_LOGIC := '0';

	----------- MANAGE interfa---ce ---------
	SIGNAL TXCNTL_Manage_IN        : STD_LOGIC_VECTOR(  7 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXCNTL_ComReady_IN      : STD_LOGIC := '0';
	SIGNAL TXCNTL_RxChan_IN        : STD_LOGIC := '0';
	SIGNAL TXCNTL_Data_Com_IN      : STD_LOGIC := '0';

	---------- RAM Interface -----------------
	SIGNAL TXCNTL_Addr_OUT         : STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXCNTL_ByteEn_OUT       : STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXCNTL_RdEn_OUT         : STD_LOGIC := '0';
	SIGNAL TXCNTL_Load_IN          : STD_LOGIC := '0';
	SIGNAL TXCNTL_WordIn_IN        : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );

	-------- Tx Wr FIFO interf --cae------------
	SIGNAL TXCNTL_DataOut_OUT      : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXCNTL_WordStat_OUT     : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXCNTL_FIFO_WrEn0_OUT   : STD_LOGIC := '0';
	SIGNAL TXCNTL_FIFO_WrEn1_OUT   : STD_LOGIC := '0';
	SIGNAL TXCNTL_FIFO_Full0_IN    : STD_LOGIC := '0';
	SIGNAL TXCNTL_FIFO_Full1_IN    : STD_LOGIC := '0';

	---------- Config -----------------
	SIGNAL TXCNTL_NodeAddr_IN      : STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := ( OTHERS => '0' );	
	SIGNAL TXCNTL_TstNodeAddr_IN   : STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXCNTL_TstSubAddr_IN    : STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXCNTL_TstWordNum_IN    : STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXCNTL_TstTxChan_IN     : STD_LOGIC := '0';
	SIGNAL TXCNTL_TestEn_IN        : STD_LOGIC := '0';

	---------- WORK STATES -------------
	SIGNAL TXCNTL_StateReg_OUT     : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXCNTL_SendWordsNum_OUT : STD_LOGIC_VECTOR( 5 DOWNTO 0 ) := ( OTHERS => '0' );

	SIGNAL TXCNTL_TxStart_IN       : STD_LOGIC := '0';
	SIGNAL TXCNTL_TxComplete_IN       : STD_LOGIC := '0';
	SIGNAL TXCNTL_BuffBusy_IN      : STD_LOGIC := '0';
	


------------------ Timer interface signals -------------------------------
	SIGNAL TMR_Enable   : STD_LOGIC := '0';
	SIGNAL TMR_Clk_x16  : STD_LOGIC := '0';
	SIGNAL TMR_Time     : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TMR_ARST     : STD_LOGIC := '0';
	SIGNAL TMR_Single   : STD_LOGIC := '0'; -- 1 = Single, 0 - co
	SIGNAL TMR_Ready    : STD_LOGIC := '0';
	


-------------------- RAM MUX interface signals --------------------------
	SIGNAL RAMMUX_Clk        : STD_LOGIC := '0';
    SIGNAL RAMMUX_RdEn       : STD_LOGIC := '0';
    SIGNAL RAMMUX_WrEn       : STD_LOGIC := '0';
    SIGNAL RAMMUX_RdAddr     : STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
    SIGNAL RAMMUX_RdByteEn   : STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
    SIGNAL RAMMUX_WrAddr     : STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
    SIGNAL RAMMUX_WrByteEn   : STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
    SIGNAL RAMMUX_RamRdEn    : STD_LOGIC := '0';
    SIGNAL RAMMUX_RamWrEn    : STD_LOGIC := '0';
    SIGNAL RAMMUX_RamAddr    : STD_LOGIC_VECTOR( ( AV_RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
    SIGNAL RAMMUX_RamByteEn  : STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RAMMUX_WrDataIn   : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RAMMUX_RamWrData  : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	


------------------ RxPHY_MUX interface signals ----------------------
	SIGNAL RXPHYMUX_RxWord1_IN        : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' ); 
	SIGNAL RXPHYMUX_RxWordStat1_IN    : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXPHYMUX_RxParErr1_IN      : STD_LOGIC := '0';
	SIGNAL RXPHYMUX_RdEn1_IN          : STD_LOGIC := '0';
	SIGNAL RXPHYMUX_RxWord2_IN        : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' ); 
	SIGNAL RXPHYMUX_RxWordStat2_IN    : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXPHYMUX_RxParErr2_IN      : STD_LOGIC := '0';
	SIGNAL RXPHYMUX_RdEn2_IN          : STD_LOGIC := '0';
	SIGNAL RXPHYMUX_RxWordOut_OUT     : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXPHYMUX_RxWordStatOut_OUT : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RXPHYMUX_RxParErrOut_OUT   : STD_LOGIC := '0';
	

------------------- TxPHY_DMUX Interface signals -------------------
	SIGNAL TXPHYDMUX_WordIN_IN    : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXPHYDMUX_StatIN_IN    : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXPHYDMUX_WrEn0_IN     : STD_LOGIC := '0';
	SIGNAL TXPHYDMUX_WrEn1_IN     : STD_LOGIC := '0';
	SIGNAL TXPHYDMUX_WordOut0_OUT : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXPHYDMUX_StatOut0_OUT : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXPHYDMUX_WordOut1_OUT : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TXPHYDMUX_StatOut1_OUT : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );



------------------- Avalon-MM MUX Interface SIGNALS --------------------
	--SIGNAL AVMUX_Avalon_Clock_IN  : STD_LOGIC := '0';
	--SIGNAL AVMUX_Avalon_nReset_IN : STD_LOGIC := '0';
	------------------ Avalon-MM1 - IN-------------------------------------
	--SIGNAL AV2RAM_waitrequest_OUT   :  STD_LOGIC := '0';
	--SIGNAL AV2RAM_address_IN        :  STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 )  DOWNTO 0 ) := ( OTHERS => '0' );
	--SIGNAL AV2RAM_byteenable_IN     :  STD_LOGIC_VECTOR( (RAM_DATA_WIDTH/8 - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	--SIGNAL AV2RAM_read_IN           :  STD_LOGIC := '0';
	--SIGNAL AV2RAM_readdata_OUT      :  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	--SIGNAL AV2RAM_readdatavalid_OUT :  STD_LOGIC := '0';
	--SIGNAL AV2RAM_write_IN          :  STD_LOGIC := '0';
	--SIGNAL AV2RAM_writedata_IN      :  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );

	----------------- Avalon-MM   -IN2--------------------------------------	
	--SIGNAL AV2RAM2_waitrequest_OUT   :  STD_LOGIC := '0';
	--SIGNAL AV2RAM2_address_IN        :  STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	--SIGNAL AV2RAM2_byteenable_IN     :  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH/8 - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	--SIGNAL AV2RAM2_read_IN           :  STD_LOGIC := '0';
	--SIGNAL AV2RAM2_readdata_OUT      :  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	--SIGNAL AV2RAM2_readdatavalid_OUT :  STD_LOGIC := '0';
	--SIGNAL AV2RAM2_write_IN          :  STD_LOGIC := '0';
	--SIGNAL AV2RAM2_writedata_IN      :  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );

	----------------- Avalon-MM  --OUT------------------------------------
	--SIGNAL AVMO_waitrequest_IN    :  STD_LOGIC := '0';
	--SIGNAL AVMO_address_OUT       :  STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	--SIGNAL AVMO_byteenable_OUT    :  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH/8 - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	--SIGNAL AVMO_read_OUT          :  STD_LOGIC := '0';
	--SIGNAL AVMO_readdata_IN       :  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	--SIGNAL AVMO_readdatavalid_IN  :  STD_LOGIC := '0';
	--SIGNAL AVMO_write_OUT         :  STD_LOGIC := '0';
	--SIGNAL AVMO_writedata_OUT     :  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );


------------------- transmitter local signals ------------------------------	
	SIGNAL IntReaded         : STD_LOGIC := '0';	
	SIGNAL StateReaded       : STD_LOGIC := '0';
	SIGNAL StateREG          : STD_LOGIC_VECTOR( 31 DOWNTO 0 );-- := ( OTHERS => '0' );
	SIGNAL IntFlagREG        : STD_LOGIC_VECTOR( 31 DOWNTO 0 );-- := ( OTHERS => '0' );
	SIGNAL RxTxLine_Busy     : STD_LOGIC := '0';
	SIGNAL TxBusy            : STD_LOGIC := '0';	
	SIGNAL TxComplete        : STD_LOGIC := '0';
	
BEGIN
	
	LineRxPhy1: milstd1553rxphy
	PORT MAP(
		Enable      =>  RxPhy1_Enable,       
		ClockIn     =>  RxPhy1_ClockIn,      
		InputA      =>  RxPhy1_InputA,       
		InputB      =>  RxPhy1_InputB,       
		RdClk       =>  RxPhy1_RdClk,         
		RdEn        =>  RxPhy1_RdEn,         
		Transmit    =>  RxPhy1_Transmit,     
		TxWord      =>  RxPhy1_TxWord,       
		TxErr       =>  RxPhy1_TxErr,        
		Strobe      =>  RxPhy1_Strobe,       
		nEmpty      =>  RxPhy1_nEmpty,       
		DataOut     =>  RxPhy1_DataOut,      
		StatOut     =>  RxPhy1_StatOut,      
		ParError    =>  RxPhy1_ParErrOut,
		Rx_Flag     =>  RxPhy1_RxFlagOut
	
	);
	
	
	LineRxPhy2: milstd1553rxphy
	PORT MAP(
		Enable      =>  RxPhy2_Enable,
		ClockIn     =>  RxPhy2_ClockIn,
		InputA      =>  RxPhy2_InputA,
		InputB      =>  RxPhy2_InputB,
		RdClk       =>  RxPhy2_RdClk, 
		RdEn        =>  RxPhy2_RdEn,
		Transmit    =>  RxPhy2_Transmit,
		TxWord      =>  RxPhy2_TxWord,
		TxErr       =>  RxPhy2_TxErr,
		Strobe      =>  RxPhy2_Strobe,
		nEmpty      =>  RxPhy2_nEmpty,
		DataOut     =>  RxPhy2_DataOut,
		StatOut     =>  RxPhy2_StatOut,
		ParError    =>  RxPhy2_ParErrOut,
		Rx_Flag     =>  RxPhy2_RxFlagOut
	
	);
	
	
	
	TxControl: milstd1553_TxControl 
	GENERIC MAP(
		RAM_DataWidth =>  RAM_DATA_WIDTH,
		AddrWidth     =>  RAM_ADDR_WIDTH,
		AvAddrWidth   =>  AV_RAM_ADDR_WIDTH
	)
	PORT MAP(
		Enable       => TXCNTL_Enable_IN,        
		Clk          => TXCNTL_Clk_IN,            

		-------------- MANAGE interface ------------
		Manage       => TXCNTL_Manage_IN,        
		ComReady     => TXCNTL_ComReady_IN,      
		RxChan       => TXCNTL_RxChan_IN,        
		Data_Com     => TXCNTL_Data_Com_IN,      

		------------ RAM Interface --------------
		Addr         => TXCNTL_Addr_OUT,         
		ByteEn       => TXCNTL_ByteEn_OUT,       
		RdEn         => TXCNTL_RdEn_OUT,         
		Load         => TXCNTL_Load_IN,          
		WordIn       => TXCNTL_WordIn_IN,        

		-------- Tx Wr FIFO interface -------------
		DataOut      => TXCNTL_DataOut_OUT,
		WordStat     => TXCNTL_WordStat_OUT,
		FIFO_WrEn0   => TXCNTL_FIFO_WrEn0_OUT,
		FIFO_WrEn1   => TXCNTL_FIFO_WrEn1_OUT,
		FIFO_Full0   => TXCNTL_FIFO_Full0_IN,
		FIFO_Full1   => TXCNTL_FIFO_Full1_IN,

		----------- Config -----------------------
		NodeAddr     => TXCNTL_NodeAddr_IN,
		TstNodeAddr  => TXCNTL_TstNodeAddr_IN,
		TstSubAddr   => TXCNTL_TstSubAddr_IN,
		TstWordNum   => TXCNTL_TstWordNum_IN,
		TstTxChan    => TXCNTL_TstTxChan_IN,
		TestEn       => TXCNTL_TestEn_IN,

		------------ WORK STATES ----------------
		StateReg     => TXCNTL_StateReg_OUT,     
		SendWordsNum => TXCNTL_SendWordsNum_OUT, 

		TxStart      => TXCNTL_TxStart_IN,       
		TxComplete      => TXCNTL_TxComplete_IN,
		BuffBusy     => TXCNTL_BuffBusy_IN      
		
	
	);
	
	
	
	AvalonMaster: AVMM_Master_FIFO
	
	GENERIC MAP(
		CLOCK_FREQUENCE       =>  16000000,
		AVM_WRITE_ACKNOWLEDGE =>  2,
		AVM_READ_ACKNOWLEDGE  =>  2,
		AVM_DATA_WIDTH        =>  RAM_DATA_WIDTH,
		AVM_ADDR_WIDTH        =>  RAM_ADDR_WIDTH,
		FIFO_WORDS_NUM        =>  32,
		FIFO_USED_WIDTH       =>  5
		
		
	)
	PORT MAP(
		nReset            => AVMM_nReset,
		Clock             => AVMM_Clock,
		WrEn              => AVMM_WrEn,    
		RdEn              => AVMM_RdEn,
		AddrIn            => AVMM_AddrIn,
		WrDataIn          => AVMM_WrDataIn,
		ByteEnCode        => AVMM_ByteEnCode, 
		Ready             => AVMM_Ready,     
		RdDataOut         => AVMM_RdDataOut,    

		avm_waitrequest   => AVM_waitrequest,   
		avm_readdata      => AVM_readdata,      
		avm_readdatavalid => AVM_readdatavalid, 
		avm_address       => AVM_address,    
		avm_byteenable    => AVM_byteenable, 
		avm_read          => AVM_read,       
		avm_write         => AVM_write,     
		avm_writedata     => AVM_writedata 
	);
	
	
	
	LineTxPhy1: milstd1553txphy 
	PORT MAP(
		Enable    => TxPhy1_Enable,
		Clk16MHz  => TxPhy1_Clk16MHz,
		WrClk     => TxPhy1_WrClk,
		WrEn      => TxPhy1_WrEn,
		WordIn    => TxPhy1_WordIn,   
		WordStat  => TxPhy1_WordStat,
		OutA      => TxPhy1_OutA,  
		OutB      => TxPhy1_OutB,  
		Transmit  => TxPhy1_Transmit,
		TxInhibit => TxPhy1_Inhibit,
		TxWord    => TxPhy1_TxWord,
		Full      => TxPhy1_Full
	);


	LineTxPhy2: milstd1553txphy 
	PORT MAP(
		Enable    => TxPhy2_Enable,
		Clk16MHz  => TxPhy2_Clk16MHz,
		WrClk     => TxPhy2_WrClk, 
		WrEn      => TxPhy2_WrEn,
		WordIn    => TxPhy2_WordIn,   
		WordStat  => TxPhy2_WordStat,
		OutA      => TxPhy2_OutA,  
		OutB      => TxPhy2_OutB,  
		Transmit  => TxPhy2_Transmit,
		TxWord    => TxPhy2_TxWord,
		TxInhibit => TxPhy2_Inhibit,
		Full      => TxPhy2_Full
	);

	
	
	RxControl: milstd1553_RxControl 
	GENERIC MAP(
		AddrWidth  => RAM_ADDR_WIDTH,
		DataWidth  => RAM_DATA_WIDTH
	)
	PORT MAP(
		Enable     => RXCNTL_Enable_IN,
		Clk        => RXCNTL_Clk_IN,

		nEmpty0    => RXCNTL_nEmpty0_IN,
		TxErr0     => RXCNTL_TxErr0_IN,

		nEmpty1    => RXCNTL_nEmpty1_IN,
		TxErr1     => RXCNTL_TxErr1_IN,


		WordIn     => RXCNTL_WordIn_IN,
		WordStat   => RXCNTL_WordStat_IN,
		ParError   => RXCNTL_ParError_IN,

		NodeAddr   => RXCNTL_NodeAddr_IN,

		WaitReq    => RXCNTL_WaitReq_IN,
		RdReq0     => RXCNTL_RdReq0_OUT,
		RdReq1     => RXCNTL_RdReq1_OUT,
		WrEn       => RXCNTL_WrEn_OUT,
		DataOut    => RXCNTL_DataOut_OUT,
		ByteEn     => RXCNTL_ByteEn_OUT,
		RAMAddr    => RXCNTL_RAMAddr_OUT,
		StateReg   => RXCNTL_StateReg_OUT,
		Manage     => RXCNTL_Manage_OUT,
		ComReady   => RXCNTL_ComReady_OUT,
		RxChan     => RXCNTL_RxChan_OUT,
		Data_Com   => RXCNTL_Data_Com_OUT,

		RxWrdCnt   => RXCNTL_RxWrdCnt_OUT,
		RxSubAddr  => RXCNTL_RxSubAddr_OUT,
		RxTx       => RXCNTL_RxTx_OUT,
		TxBlock0   => RXCNTL_TxBlock0_OUT,
		TxBlock1   => RXCNTL_TxBlock1_OUT,
		BuffBusy   => RXCNTL_BuffBusy_IN
	);
	
	
	
	RxPHY_MUX: mil_RxPhyMUX 
	PORT MAP(
		RxWord1       => RXPHYMUX_RxWord1_IN,
		RxWordStat1   => RXPHYMUX_RxWordStat1_IN,
		RxParErr1     => RXPHYMUX_RxParErr1_IN,
		RdEn1         => RXPHYMUX_RdEn1_IN,
		RxWord2       => RXPHYMUX_RxWord2_IN,
		RxWordStat2   => RXPHYMUX_RxWordStat2_IN,
		RxParErr2     => RXPHYMUX_RxParErr2_IN,
		RdEn2         => RXPHYMUX_RdEn2_IN,
		RxWordOut     => RXPHYMUX_RxWordOut_OUT,
		RxWordStatOut => RXPHYMUX_RxWordStatOut_OUT,
		RxParErrOut   => RXPHYMUX_RxParErrOut_OUT
	);	
	
	
	TxPHY_DMUX: TxPhyDMUX 
	PORT MAP(
		WordIN   => TXPHYDMUX_WordIN_IN,    
		StatIN   => TXPHYDMUX_StatIN_IN,    
		WrEn0    => TXPHYDMUX_WrEn0_IN,     
		WrEn1    => TXPHYDMUX_WrEn1_IN,     
		WordOut0 => TXPHYDMUX_WordOut0_OUT, 
		StatOut0 => TXPHYDMUX_StatOut0_OUT, 
		WordOut1 => TXPHYDMUX_WordOut1_OUT, 
 		StatOut1 => TXPHYDMUX_StatOut1_OUT 
	);
	
	
	
	--Avalon_MUX: AvMM2Mux1 
	--GENERIC MAP(
		--DataWidth          => RAM_DATA_WIDTH, 
		--AddrWidth          => RAM_ADDR_WIDTH 
	--)
	--PORT MAP(
		--Avalon_Clock       => AVMUX_Avalon_Clock_IN,  
		--Avalon_nReset      => AVMUX_Avalon_nReset_IN, 
		----------------- Avalon-MM1 IN --------------
		--AV2RAM_waitrequest   => AV2RAM_waitrequest_OUT,   
		--AV2RAM_address       => AV2RAM_address_IN,        
		--AV2RAM_byteenable    => AV2RAM_byteenable_IN,     
		--AV2RAM_read          => AV2RAM_read_IN,           
		--AV2RAM_readdata      => AV2RAM_readdata_OUT,      
		--AV2RAM_readdatavalid => AV2RAM_readdatavalid_OUT, 
		--AV2RAM_write         => AV2RAM_write_IN,          
		--AV2RAM_writedata     => AV2RAM_writedata_IN,      

		------------------ Avalon-MM2 IN  -------------
		--AV2RAM2_waitrequest   => AV2RAM2_waitrequest_OUT,   
		--AV2RAM2_address       => AV2RAM2_address_IN,        
		--AV2RAM2_byteenable    => AV2RAM2_byteenable_IN,     
		--AV2RAM2_read          => AV2RAM2_read_IN,           
		--AV2RAM2_readdata      => AV2RAM2_readdata_OUT,      
		--AV2RAM2_readdatavalid => AV2RAM2_readdatavalid_OUT, 
		--AV2RAM2_write         => AV2RAM2_write_IN,          
		--AV2RAM2_writedata     => AV2RAM2_writedata_IN,      

		-------------------- Avalon-MM OUT ---------
		--AVMO_waitrequest   => AVMO_waitrequest_IN,    
		--AVMO_address       => AVMO_address_OUT,       
		--AVMO_byteenable    => AVMO_byteenable_OUT,    
		--AVMO_read          => AVMO_read_OUT,          
		--AVMO_readdata      => AVMO_readdata_IN,       
		--AVMO_readdatavalid => AVMO_readdatavalid_IN,  
		--AVMO_write         => AVMO_write_OUT,         
		--AVMO_writedata     => AVMO_writedata_OUT
	--);
	
	
	
	
	tmr: timer 
	PORT MAP(
		Enable   => TMR_Enable,    
		Clk_x16  => TMR_Clk_x16,   
		Time     => TMR_Time,      
		ARST     => TMR_ARST,      
		Single   => TMR_Single,    
		Ready    => TMR_Ready     
	);
	
	
	
	
	mux: ram_mux  
	GENERIC MAP(
		RamAddrWidth =>  RAM_ADDR_WIDTH,
		RdAddrWidth  =>  RAM_ADDR_WIDTH,--TX_RAM_ADDR_WIDTH,
		WrAddrWidth  =>  RAM_ADDR_WIDTH,
		BEWidth      =>  ( RAM_DATA_WIDTH / 8 )
	)
	PORT MAP(
		Clk        =>  RAMMUX_Clk,
		RdEn       =>  RAMMUX_RdEn,
		WrEn       =>  RAMMUX_WrEn,
		RdAddr     =>  RAMMUX_RdAddr,
		RdByteEn   =>  RAMMUX_RdByteEn,
		WrAddr     =>  RAMMUX_WrAddr,
		WrByteEn   =>  RAMMUX_WrByteEn,
		WrDataIn   =>  RAMMUX_WrDataIn,
		RamRdEn    =>  RAMMUX_RamRdEn,
		RamWrEn    =>  RAMMUX_RamWrEn,
		RamAddr    =>  RAMMUX_RamAddr,
		RamWrData  =>  RAMMUX_RamWrData,
		RamByteEn  =>  RAMMUX_RamByteEn
	);
	
	
	TxEndPulseFalse: pgen 
	GENERIC MAP(
		Edge   => '0'  -- falline edge 
	)
	PORT MAP(
		Enable =>  Avalon_nReset,
		Clk    =>  Avalon_Clock,
		Input  =>  TxBusy,
		Output =>  TxComplete
	);
	
	
	
	RxTxLine_Busy <= ( ( RxPhy1_RxFlagOut OR RxPhy2_RxFlagOut ) OR
	                   ( TxPhy1_Transmit OR TxPhy2_Transmit ) ); 
	

	TxBusy <= TxPhy1_Transmit OR TxPhy2_Transmit;
	
	-------------- Reset Signals ------------------------
	RXCNTL_Enable_IN <= Signal_Registers( CONFIG_REG_ADDR )( RXTX_EN );
	TXCNTL_Enable_IN <= Signal_Registers( CONFIG_REG_ADDR )( RXTX_EN );   
	TxPhy1_Enable    <= Signal_Registers( CONFIG_REG_ADDR )( RXTX_EN ) AND ( NOT RXCNTL_TxBlock0_OUT ); 
	TxPhy2_Enable    <= Signal_Registers( CONFIG_REG_ADDR )( RXTX_EN ) AND ( NOT RXCNTL_TxBlock1_OUT ); 
	RxPhy1_Enable    <= Signal_Registers( CONFIG_REG_ADDR )( RXTX_EN ); 
	RxPhy2_Enable    <= Signal_Registers( CONFIG_REG_ADDR )( RXTX_EN ); 
	TMR_Enable       <= Signal_Registers( CONFIG_REG_ADDR )( RXTX_EN );
	AVMM_nReset      <= Avalon_nReset;   
	--AVMUX_Avalon_nReset_IN <= Avalon_nReset;
	
	-------------- Clock Signals -------------------------
	RxPhy1_ClockIn   <= MilStd1553_Clock;
	RxPhy1_RdClk     <= Avalon_Clock;
	
	RxPhy2_ClockIn   <= MilStd1553_Clock;  
	RxPhy2_RdClk     <= Avalon_Clock;
	
	TxPhy1_Clk16MHz  <= MilStd1553_Clock;  
	TxPhy1_WrClk     <= Avalon_Clock;
	
	TxPhy2_Clk16MHz  <= MilStd1553_Clock;  
	TxPhy2_WrClk     <= Avalon_Clock;	
	
	RXCNTL_Clk_IN   <= Avalon_Clock;
	TXCNTL_Clk_IN   <= Avalon_Clock;
	TMR_Clk_x16     <= MilStd1553_Clock;
	AVMM_Clock      <= Avalon_Clock;
	RAMMUX_Clk      <= Avalon_Clock;
	
	--AVMUX_Avalon_Clock_IN <= Avalon_Clock;
	      
	-------------- Avalon-MM Master connections -------------
	AVMM_AddrIn     <= RAMMUX_RamAddr;
	AVMM_ByteEnCode <= RAMMUX_RamByteEn;
	AVMM_WrDataIn   <= RAMMUX_RamWrData; 
	AVMM_RdEn       <= RAMMUX_RamRdEn;
	AVMM_WrEn       <= RAMMUX_RamWrEn;
	
	AVM_waitrequest   <= AV2RAM_waitrequest;
	AVM_readdata      <= AV2RAM_readdata;
	AVM_readdatavalid <= AV2RAM_readdatavalid;
	
	
	-------------- RXPHY_MUX Connection -------------------
	RXPHYMUX_RxWord1_IN      <= RxPhy1_DataOut;
	RXPHYMUX_RxWordStat1_IN  <= RxPhy1_StatOut;
	RXPHYMUX_RxParErr1_IN    <= RxPhy1_ParErrOut;
	RXPHYMUX_RdEn1_IN        <= RXCNTL_RdReq0_OUT;
	RXPHYMUX_RxWord2_IN      <= RxPhy2_DataOut;
	RXPHYMUX_RxWordStat2_IN  <= RxPhy2_StatOut;
	RXPHYMUX_RxParErr2_IN    <= RxPhy2_ParErrOut;
	RXPHYMUX_RdEn2_IN        <= RXCNTL_RdReq1_OUT;
	

	------------- Rx Control connections -------------------
	RXCNTL_nEmpty0_IN        <= RxPhy1_nEmpty;
	RXCNTL_nEmpty1_IN        <= RxPhy2_nEmpty;
	RXCNTL_TxErr0_IN         <= RxPhy1_TxErr;
	RXCNTL_TxErr1_IN         <= RxPhy2_TxErr;
	
	RXCNTL_WordIn_IN         <= RXPHYMUX_RxWordOut_OUT; 
	RXCNTL_WordStat_IN       <= RXPHYMUX_RxWordStatOut_OUT;
	RXCNTL_ParError_IN       <= RXPHYMUX_RxParErrOut_OUT;

	RXCNTL_NodeAddr_IN       <= Signal_Registers( CONFIG_REG_ADDR )( NODE_ADDR_H DOWNTO NODE_ADDR_L ) WHEN 
	                            Signal_Registers( CONFIG_REG_ADDR )( SOFT_NODEADDR )  = '1' ELSE
	                            NodeAddrHard;
	                            
	RXCNTL_BuffBusy_IN       <= ( AV2PCIE_read OR AV2PCIE_write OR AV2RAM2_waitrequest OR AV2RAM2_readdatavalid );
	--RXCNTL_BuffBusy_IN       <= Signal_Registers( CONFIG_REG_ADDR )( CPU_BUFF_BUSY );  --( AV2PCIE_read OR AV2PCIE_write );
	
	RXCNTL_WaitReq_IN        <= '0';  -- NOT USED

	----------- Rx_PHY1 Connections -------------------------
	RxPhy1_InputA    <= MilStd1553_LineIA1;
	RxPhy1_InputB    <= MilStd1553_LineIB1;
	MilStd1553_RxEn1 <= RxPhy1_Strobe;	
	RxPhy1_RdEn      <= RXCNTL_RdReq0_OUT;
	RxPhy1_Transmit  <= TxPhy1_Transmit;
	RxPhy1_TxWord    <= TxPhy1_TxWord;
	
	----------- Rx_PHY2 Connections -------------------------
	RxPhy2_InputA    <= MilStd1553_LineIA2;
	RxPhy2_InputB    <= MilStd1553_LineIB2;
	MilStd1553_RxEn2 <= RxPhy2_Strobe;	
	RxPhy2_RdEn      <= RXCNTL_RdReq1_OUT;
	RxPhy2_Transmit  <= TxPhy2_Transmit;
    RxPhy2_TxWord    <= TxPhy2_TxWord;

	
	
	------------ Tx Control Connections --------------------
	TXCNTL_Manage_IN     <= RXCNTL_Manage_OUT;
	TXCNTL_ComReady_IN   <= RXCNTL_ComReady_OUT;
	TXCNTL_RxChan_IN     <= RXCNTL_RxChan_OUT;
	TXCNTL_Data_Com_IN   <= RXCNTL_Data_Com_OUT;
	
	TXCNTL_Load_IN       <= AVMM_Ready;
	TXCNTL_WordIn_IN     <= AVMM_RdDataOut;
	
	TXCNTL_FIFO_Full0_IN <= TxPhy1_Full;
	TXCNTL_FIFO_Full1_IN <= TxPhy2_Full;
	
	TXCNTL_NodeAddr_IN    <= Signal_Registers( CONFIG_REG_ADDR )( NODE_ADDR_H DOWNTO NODE_ADDR_L ) WHEN 
	                         Signal_Registers( CONFIG_REG_ADDR )( SOFT_NODEADDR )  = '1' ELSE
	                         NodeAddrHard;
						     
	TXCNTL_TstNodeAddr_IN <= Signal_Registers( CONFIG_REG_ADDR )( TST_NADDR_H DOWNTO TST_NADDR_L );
	TXCNTL_TstSubAddr_IN  <= Signal_Registers( CONFIG_REG_ADDR )( TST_SADDR_H DOWNTO TST_SADDR_L );
	TXCNTL_TstWordNum_IN  <= Signal_Registers( CONFIG_REG_ADDR )( TST_WRDSNUM_H DOWNTO TST_WRDSNUM_L );
	TXCNTL_TstTxChan_IN   <= Signal_Registers( CONFIG_REG_ADDR )( TST_TXCHANNEL );
	TXCNTL_TestEn_IN      <= Signal_Registers( CONFIG_REG_ADDR )( DIAG );
	
	TXCNTL_TxStart_IN     <= TMR_Ready;
	TXCNTL_TxComplete_IN     <= TxComplete;
	TXCNTL_BuffBusy_IN    <= ( AV2PCIE_read OR AV2PCIE_write OR AV2RAM2_waitrequest OR AV2RAM2_readdatavalid );
	--TXCNTL_BuffBusy_IN    <= Signal_Registers( CONFIG_REG_ADDR )( CPU_BUFF_BUSY );  -- ( AV2PCIE_read OR AV2PCIE_write );

	
	
	-------------- Tx PHY1 Connections ---------------------
	TxPhy1_WrEn     <= TXCNTL_FIFO_WrEn0_OUT;
	TxPhy1_WordIn   <= TXPHYDMUX_WordOut0_OUT;
	TxPhy1_WordStat <= TXPHYDMUX_StatOut0_OUT;
	
	MilStd1553_LineOA1 <= TxPhy1_OutA;   
	MilStd1553_LineOB1 <= TxPhy1_OutB;  
	MilStd1553_TxEn1   <= TxPhy1_Inhibit;
	
	
	-------------- Tx PHY2 Connections ---------------------
	TxPhy2_WrEn     <= TXCNTL_FIFO_WrEn1_OUT;
	TxPhy2_WordIn   <= TXPHYDMUX_WordOut1_OUT;
	TxPhy2_WordStat <= TXPHYDMUX_StatOut1_OUT;
	
	MilStd1553_LineOA2 <= TxPhy2_OutA;   
	MilStd1553_LineOB2 <= TxPhy2_OutB;  
	MilStd1553_TxEn2   <= TxPhy2_Inhibit;
	
	
	
	
	------------- RAM_MUX Connections ------------------------
	RAMMUX_WrAddr     <= RXCNTL_RAMAddr_OUT;
	RAMMUX_WrByteEn   <= RXCNTL_ByteEn_OUT;
	RAMMUX_WrEn       <= RXCNTL_WrEn_OUT;
	RAMMUX_RdAddr     <= TXCNTL_Addr_OUT;
	RAMMUX_RdByteEn   <= TXCNTL_ByteEn_OUT;
	RAMMUX_RdEn       <= TXCNTL_RdEn_OUT;
	RAMMUX_WrDataIn   <= RXCNTL_DataOut_OUT;
	
	
	-------------- Timer Connections -------------------
	TMR_Time      <= TIME_PAUSE; 
	TMR_ARST      <= RxPhy1_RxFlagOut OR RxPhy2_RxFlagOut;
	TMR_Single    <= '0';
	
	
	------------------ TXPHY DMUX connection -------------------------
	TXPHYDMUX_WordIN_IN <= TXCNTL_DataOut_OUT;
	TXPHYDMUX_StatIN_IN <= TXCNTL_WordStat_OUT;
	TXPHYDMUX_WrEn0_IN  <= TXCNTL_FIFO_WrEn0_OUT;
	TXPHYDMUX_WrEn1_IN  <= TXCNTL_FIFO_WrEn1_OUT;
	

	----------------- AVMM2MUX1 connection ---------------------------
	--AVMO_waitrequest_IN   <= AV2RAM_waitrequest;
	--AVMO_readdata_IN      <= AV2RAM_readdata;
	--AVMO_readdatavalid_IN <= AV2RAM_readdatavalid;
	
	--AV2RAM_address    <= AVMO_address_OUT;
	--AV2RAM_byteenable <= AVMO_byteenable_OUT;
	--AV2RAM_read       <= AVMO_read_OUT;
	--AV2RAM_write      <= AVMO_write_OUT;
	--AV2RAM_writedata  <= AVMO_writedata_OUT;
	
	AV2RAM_address    <= AVM_address;
	AV2RAM_byteenable <= AVM_byteenable;
	AV2RAM_read       <= AVM_read;
	AV2RAM_write      <= AVM_write;
	AV2RAM_writedata  <= AVM_writedata;
	
	AV2RAM2_address    <= AV2PCIE_address;
	AV2RAM2_byteenable <= AV2PCIE_byteenable;
    AV2RAM2_read       <= AV2PCIE_read;
	AV2RAM2_write      <= AV2PCIE_write;
	AV2RAM2_writedata  <= AV2PCIE_writedata;
	
	AV2PCIE_waitrequest   <= AV2RAM2_waitrequest;
	AV2PCIE_readdata      <= AV2RAM2_readdata;
	AV2PCIE_readdatavalid <= AV2RAM2_readdatavalid;
	
	
	
	
	LineSWOFF: PROCESS( Avalon_nReset, Avalon_Clock )
	BEGIN
		IF Avalon_nReset = '0' THEN
			LineTurnOFF1 <= '1';
		    LineTurnOFF2 <= '1';
		
		ELSIF RISING_EDGE( Avalon_Clock ) THEN
			IF RxTxLine_Busy = '0' THEN
				LineTurnOFF1 <= Signal_Registers( CONFIG_REG_ADDR )( LINE_OFF );	
				LineTurnOFF2 <= Signal_Registers( CONFIG_REG_ADDR )( LINE_OFF );
			END IF;
		END IF;
	
	END PROCESS;
	
	
		

	State_reg: PROCESS( Avalon_nReset, Avalon_Clock )
	VARIABLE byte_cnt : INTEGER RANGE 0 TO 3 := 0;
	VARIABLE busy_cnt : INTEGER RANGE 0 TO 7 := 0;
	vARIABLE ComReady : STD_LOGIC := '0';
	VARIABLE VarRxTx  : STD_LOGIC := '0';
	VARIABLE Manage   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := ( OTHERS => '0' ); 
	VARIABLE Data_Com : STD_LOGIC := '0';
	BEGIN
		IF Avalon_nReset = '0' THEN
			StateREG <= ( OTHERS => '0' );
			busy_cnt := 0;
			byte_cnt := 0;
			ComReady := '0';
			VarRxTx  := '0';
			Manage   := ( OTHERS => '0' );
			Data_Com := '0';                                    	

		ELSIF RISING_EDGE( Avalon_Clock ) THEN
			ComReady := RXCNTL_ComReady_OUT;
			VarRxTx  := RXCNTL_RxTx_OUT;
			Manage   := RXCNTL_Manage_OUT;
			Data_Com := RXCNTL_Data_Com_OUT;
			
		ELSIF FALLING_EDGE( Avalon_Clock ) THEN
			IF ComReady = '1' THEN
				
				IF ( VarRxTx = RX_TRANSACT ) AND ( Data_Com = DATA_OP ) THEN -- IF was data reception
					StateREG( RXWRD_CNT_H DOWNTO RXWRD_CNT_L ) <= RXCNTL_RxWrdCnt_OUT;
					StateREG( RX_LASTSUB_H DOWNTO RX_LASTSUB_L ) <= RXCNTL_RxSubAddr_OUT;
				END IF;
				
				IF byte_cnt = 0 THEN
					StateREG( MSG_ERR )  <= Manage(2);
					StateREG( INSTR )    <= Manage(1);
					StateREG( SERV_REQ ) <= Manage(0);
				ELSIF byte_cnt = 1 THEN
					StateREG( BROAD_COM )    <= Manage(4);
					StateREG( SUBSCR_BUSY )  <= Manage(3);
					StateREG( SUBSCR_ERR )   <= Manage(2);
					StateREG( BUS_CONTROL )  <= Manage(1);
					StateREG( TERMINAL_ERR ) <= Manage(0);
				END IF;
				
				IF byte_cnt < 3 THEN
					byte_cnt := byte_cnt + 1;
				END IF;
			ELSE
				byte_cnt := 0;
			END IF;
			
			StateREG( HARD_NODEADDR_H DOWNTO HARD_NODEADDR_L ) <= NodeAddrHard;
			
			--StateREG( TX_ERROR1 ) <= StateREG( TX_ERROR1 ) OR RxPhy1_TxErr;
			--StateREG( TX_ERROR2 ) <= StateREG( TX_ERROR2 ) OR RxPhy2_TxErr;
			
			IF ( AVM_read = '1' ) OR ( AVM_write = '1' ) THEN
				StateREG( FPGA_BUFF_BUSY ) <= '1';
				busy_cnt := 0;
			ELSE
				IF busy_cnt < 7 THEN
					busy_cnt := busy_cnt + 1;
				ELSE
					busy_cnt := 0;
					StateREG( FPGA_BUFF_BUSY ) <= '0';
				END IF;
			END IF;

		END IF;
	END PROCESS;
	
	
	
	
	IntFlag_Reg: PROCESS( Avalon_nReset, Avalon_Clock )
	VARIABLE IntFlagRegPREV : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	VARIABLE IntFlagRegDIF  : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	
	BEGIN
		IF Avalon_nReset = '0' THEN
			IntFlagREG <= ( OTHERS => '0' );
			
		ELSIF FALLING_EDGE( Avalon_Clock ) THEN
			IF IntReaded = '0' THEN
				IntFlagRegDIF := IntFlagRegPREV XOR IntFlagREG;
				
				IF ( ( IntFlagRegDIF AND IntFlagREG ) /= x"00000000" ) THEN
					Interrupt <= '1';
				ELSE	
					Interrupt <= '0';	
				END IF;
				
				IntFlagRegPREV := IntFlagREG;
				IntFlagREG( RX_OK )    <= RXCNTL_StateReg_OUT( 5 );
				IntFlagREG( TX_COMPL ) <= TxComplete; --TXCNTL_StateReg_OUT( 5 );
				IntFlagREG( TX_ERROR1 ) <= RxPhy1_TxErr;
			    IntFlagREG( TX_ERROR2 ) <= RxPhy2_TxErr;
				
			ELSE
				IntFlagREG <= ( OTHERS => '0' );
			END IF;
		END IF;
	
	END PROCESS;
	
	
	
	
	---------- ( Avalon-MM Slave ) Config Data Transmission ----------------
	
	PROCESS( Avalon_nReset, Avalon_Clock )
		VARIABLE address : INTEGER RANGE 3 DOWNTO 0        := 0;
		VARIABLE data    : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	BEGIN
		
		IF( Avalon_nReset = '0' ) THEN
			
			AVS_waitrequest   <= '0';
			AVS_readdatavalid <= '0';
			AVS_readdata      <= ( OTHERS => '0' );
			Signal_SlaveState <= AVALON_RESET;
			
		ELSIF RISING_EDGE( Avalon_Clock ) THEN
			
			CASE Signal_SlaveState IS
			
			WHEN AVALON_RESET =>
				AVS_waitrequest   <= '0';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_IDLE;
			
			WHEN AVALON_IDLE =>
				AVS_waitrequest   <= '0';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				IntReaded         <= '0';
				StateReaded       <= '0';
				IF IntReaded = '0' THEN 
					Signal_Registers( INTFLAG_REG_ADDR )  <= Signal_Registers( INTFLAG_REG_ADDR ) OR IntFlagREG;
				ELSE
					Signal_Registers( INTFLAG_REG_ADDR )  <= ( OTHERS => '0' );
				END IF;
				Signal_Registers( STATE_REG_ADDR )    <= StateREG;
					
				IF( AVS_write = '1' ) THEN
					Signal_SlaveState <= AVALON_WRITE;
				ELSIF( AVS_read = '1' ) THEN
					Signal_SlaveState <= AVALON_READ;
				END IF;
			
			WHEN AVALON_WRITE =>
				address           := TO_INTEGER( UNSIGNED( AVS_address ) );
				data              := AVS_writedata;
				AVS_waitrequest   <= '1';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_ACK_WRITE;
			
			WHEN AVALON_ACK_WRITE =>
				AVS_waitrequest             <= '0';
				AVS_readdatavalid           <= '0';
				AVS_readdata                <= ( OTHERS => '0' );
				Signal_Registers( address ) <= data;
				
				Signal_SlaveState           <= AVALON_IDLE;
				
			WHEN AVALON_READ =>
				address           := TO_INTEGER( UNSIGNED( AVS_address ) );
				AVS_waitrequest   <= '1';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_ACK_READ;
			
			WHEN AVALON_ACK_READ =>
				AVS_waitrequest   <= '0';
				AVS_readdatavalid <= '1';
				AVS_readdata      <= Signal_Registers( address );
				Signal_SlaveState <= AVALON_IDLE;
				
				IF address = INTFLAG_REG_ADDR THEN
					IntReaded     <= '1';
				ELSIF address = STATE_REG_ADDR THEN
					StateReaded   <= '1';
				END IF;
					
			
			END CASE;
			
		END IF;
		
	END PROCESS;
	
	
END logic;
