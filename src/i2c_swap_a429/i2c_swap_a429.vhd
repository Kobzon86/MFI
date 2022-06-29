LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.i2c_swap_a429_pkg.ALL;

ENTITY i2c_swap_a429 IS
	
	PORT(
		Avalon_nReset        : IN  STD_LOGIC := '0';
		Avalon_Clock         : IN  STD_LOGIC;
		A429_TxEnabled       : IN  STD_LOGIC := '0';
		
		----------- Avalon-MM Slave Config ------------------------------
		AVS_waitrequest      : OUT STD_LOGIC;
		AVS_address          : IN  STD_LOGIC_VECTOR( ( AVCFG_ADDR_WIDTH - 1 )  DOWNTO 0 );
		AVS_byteenable       : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AVS_read             : IN  STD_LOGIC;
		AVS_readdata         : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		AVS_readdatavalid    : OUT STD_LOGIC;
		AVS_write            : IN  STD_LOGIC;
		AVS_writedata        : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		--------- Avalon-MM signals to Avalon-MM BUS --------------------
		AV2RAM_waitrequest   : IN  STD_LOGIC;
		AV2RAM_address       : OUT STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM_byteenable    : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2RAM_read          : OUT STD_LOGIC;
		AV2RAM_readdata      : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM_readdatavalid : IN  STD_LOGIC;
		AV2RAM_write         : OUT STD_LOGIC;
		AV2RAM_writedata     : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 )
		
	);
	
END i2c_swap_a429;

ARCHITECTURE ARCH OF i2c_swap_a429 IS
	
	COMPONENT FIFO IS
	GENERIC(
		DataWidth  : INTEGER := 8;
		UsedWidth  : INTEGER := 8; -- 2 ** UsedWidth = WordNum
		WordNum    : INTEGER := 256
	);
	PORT(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		    : OUT STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		wrfull		: OUT STD_LOGIC 
	);
	END COMPONENT;
	
	COMPONENT AVMM_Master IS
	GENERIC(
		CLOCK_FREQUENCE       : INTEGER := 62500000;
		AVM_WRITE_ACKNOWLEDGE : INTEGER := 15;
		AVM_READ_ACKNOWLEDGE  : INTEGER := 15;
		AVM_DATA_WIDTH        : INTEGER := 32;
		AVM_ADDR_WIDTH        : INTEGER := 16
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
	
	COMPONENT swap_control IS
	PORT(
		Enable          : IN   STD_LOGIC;
		Clk             : IN   STD_LOGIC;
		AVM_WrEn        : OUT  STD_LOGIC;
		AVM_RdEn        : OUT  STD_LOGIC;
		AVM_Addr        : OUT  STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
		AVM_WrData      : OUT  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		AVM_ByteEnCode  : OUT  STD_LOGIC_VECTOR( ( ( AVM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
		AVM_Ready       : IN   STD_LOGIC;
		AVM_RdData      : IN   STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		FIFO_aclr		: OUT STD_LOGIC  := '0';
		FIFO_data		: OUT STD_LOGIC_VECTOR ( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0);
		FIFO_rdreq		: OUT STD_LOGIC;
		FIFO_wrreq		: OUT STD_LOGIC;
		FIFO_q		    : IN STD_LOGIC_VECTOR ( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0);
		FIFO_empty		: IN STD_LOGIC;
		FIFO_full		: IN STD_LOGIC;

		SwapStart       : IN STD_LOGIC
		
	);
	END COMPONENT;
	
	TYPE   T_Avalon_State     IS ( AVALON_RESET, AVALON_IDLE, AVALON_WRITE, AVALON_READ );
	TYPE   T_Conf_Registers   IS ARRAY( 3 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	
	SIGNAL Signal_SlaveState  : T_Avalon_State   := AVALON_RESET;
	SIGNAL Signal_Registers   : T_Conf_Registers := (  x"00000000", x"00000000", x"FFFFFFFF", x"00000000" ); -- default I2C_A429_Swap Disabled
--	SIGNAL Signal_Registers   : T_Conf_Registers := (  x"00000000", x"00000000", x"FFFFFFFF", x"00000001" ); -- default I2C_A429_Swap enabled
	
	SIGNAL LOC_IntFlagReg       : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL LOC_StateReg_DIF     : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL LOC_StateReg_PREV    : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL LOC_IntRegRead       : STD_LOGIC := '0';
	SIGNAL LOC_RamBusy          : STD_LOGIC;
	
	------------ for SYNTHESIS ----------------
	CONSTANT Time_IN_100kHz  : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( 625, 20 ) );    -- period 10 us 
	CONSTANT Time_IN_1kHz    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( 100, 20 ) );    -- period  1 ms 
	CONSTANT Time_IN_80Hz    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( 128, 20 ) );    -- period  12.5 ms 
	CONSTANT Time_IN_100Hz   : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( 1000, 20 ) );   -- period  10 ms 
	CONSTANT Time_IN_10Hz    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( 10000, 20 ) );  -- period 100 ms
	
	----------- Avalon-MM Interface SIGNALS -----------
	SIGNAL AVM_nReset_IN            : STD_LOGIC;
	SIGNAL AVM_Clock_IN             : STD_LOGIC;
	SIGNAL AVM_WrEn_IN              : STD_LOGIC;
	SIGNAL AVM_RdEn_IN              : STD_LOGIC;
	SIGNAL AVM_AddrIn_IN            : STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL AVM_WrDataIn_IN          : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL AVM_ByteEnCode_IN        : STD_LOGIC_VECTOR( ( ( AVM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
	SIGNAL AVM_Ready_OUT            : STD_LOGIC;
	SIGNAL AVM_RdDataOut_OUT        : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
	
	SIGNAL AVM_avm_waitrequest_IN   : STD_LOGIC;
	SIGNAL AVM_avm_readdata_IN      : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL AVM_avm_readdatavalid_IN : STD_LOGIC;
	SIGNAL AVM_avm_address_OUT      : STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL AVM_avm_byteenable_OUT   : STD_LOGIC_VECTOR( ( ( AVM_DATA_WIDTH / 8 ) - 1 )  DOWNTO 0 );
	SIGNAL AVM_avm_read_OUT         : STD_LOGIC;
	SIGNAL AVM_avm_write_OUT        : STD_LOGIC;
	SIGNAL AVM_avm_writedata_OUT    : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
	
	SIGNAL CTRL_Enable      : STD_LOGIC := '0';
	SIGNAL CTRL_Clk_62M5    : STD_LOGIC := '0';
	SIGNAL CTRL_I2C_Clk     : STD_LOGIC;
	SIGNAL CTRL_AvClk       : STD_LOGIC;
	SIGNAL CTRL_AvLoad      : STD_LOGIC;
	SIGNAL CTRL_WordIn      : STD_LOGIC_VECTOR( AVM_DATA_WIDTH-1 DOWNTO 0 );
	SIGNAL CTRL_RdEn        : STD_LOGIC;
	SIGNAL CTRL_WrEn        : STD_LOGIC;
	SIGNAL CTRL_RamAddr     : STD_LOGIC_VECTOR( AVM_ADDR_WIDTH-1 DOWNTO 0 );
	SIGNAL CTRL_WordOut     : STD_LOGIC_VECTOR( AVM_DATA_WIDTH-1 DOWNTO 0 );
	SIGNAL CTRL_ByteEn      : STD_LOGIC_VECTOR( ((AVM_DATA_WIDTH / 8) - 1) DOWNTO 0 );
	SIGNAL CTRL_RAM_Busy    : STD_LOGIC;
	SIGNAL CTRL_Start       : STD_LOGIC;
	
	SIGNAL LOC_Enable      : STD_LOGIC := '0';	
	
	SIGNAL FIFO_aclr_IN     : STD_LOGIC  := '0';
	SIGNAL FIFO_data_IN     : STD_LOGIC_VECTOR ( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0);
	SIGNAL FIFO_rdclk_IN    : STD_LOGIC ;
	SIGNAL FIFO_rdreq_IN    : STD_LOGIC ;
	SIGNAL FIFO_wrclk_IN    : STD_LOGIC ;
	SIGNAL FIFO_wrreq_IN    : STD_LOGIC ;
	SIGNAL FIFO_q_OUT       : STD_LOGIC_VECTOR ( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0);
	SIGNAL FIFO_rdempty_OUT	: STD_LOGIC ;
	SIGNAL FIFO_wrfull_OUT  : STD_LOGIC ;
	
	SIGNAL timer10us_ready  : STD_LOGIC;
	SIGNAL timer100ms_ready : STD_LOGIC;
	SIGNAL StartPulse       : STD_LOGIC;
	
	SIGNAL address          : INTEGER RANGE 0 TO ( ( 2 ** AVCFG_ADDR_WIDTH ) - 1 );
	SIGNAL data             : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
	
BEGIN
	
	timer_swap1: timer
	PORT MAP(
		Enable   => Avalon_nReset,  
		Clk_x16  => Avalon_Clock,
		Time     => Time_IN_100kHz,  
		ARST     => '0',
		Single   => '0',
		Ready    => timer10us_ready 
	);
	
	
	
	
	
	timer_swap2: timer
	PORT MAP(
		Enable   => LOC_Enable, --Avalon_nReset, 
		Clk_x16  => timer10us_ready, 
		Time     => Time_IN_10Hz,  --Time_IN_10Hz, 
		ARST     => '0',
		Single   => '0',
		Ready    => timer100ms_ready
	);
	

	StP_Gen: pgen
	GENERIC MAP(
		Edge   => '1'   -- rising edge 
	)
	PORT MAP(
		Enable => LOC_Enable,  --Avalon_nReset, 
		Clk    => Avalon_Clock, 
		Input  => timer100ms_ready, 
		Output => StartPulse
	);
	
	
	buf_fifo: FIFO 
	GENERIC MAP(
		DataWidth   => AVM_DATA_WIDTH,
		UsedWidth   => 4,   -- 2**4 = I2C_SWAP_DATA_LEN = 16
		WordNum     => TO_INTEGER( I2C_SWAP_DATA_LEN )
	)
	PORT MAP(
		aclr		=> FIFO_aclr_IN,     
		data		=> FIFO_data_IN,     
		rdclk		=> FIFO_rdclk_IN,    
		rdreq		=> FIFO_rdreq_IN,    
		wrclk		=> FIFO_wrclk_IN,    
		wrreq		=> FIFO_wrreq_IN,    
		q		    => FIFO_q_OUT,       
		rdempty		=> FIFO_rdempty_OUT,	
		wrfull		=> FIFO_wrfull_OUT  
	);
	
	
	
	AVM_Interface: AVMM_Master 
	GENERIC MAP(
		CLOCK_FREQUENCE       => 62_500_000, 
		AVM_WRITE_ACKNOWLEDGE => 15, 
		AVM_READ_ACKNOWLEDGE  => 15, 
		AVM_DATA_WIDTH        => AVM_DATA_WIDTH, 
		AVM_ADDR_WIDTH        => AVM_ADDR_WIDTH 
	)
	PORT MAP(
		nReset            => AVM_nReset_IN,            
		Clock             => AVM_Clock_IN,             
		WrEn              => AVM_WrEn_IN,              
		RdEn              => AVM_RdEn_IN,              
		AddrIn            => AVM_AddrIn_IN,            
		WrDataIn          => AVM_WrDataIn_IN,          
		ByteEnCode        => AVM_ByteEnCode_IN,        
		Ready             => AVM_Ready_OUT,            
		RdDataOut         => AVM_RdDataOut_OUT,        
		                                      
		avm_waitrequest   => AV2RAM_waitrequest,    
		avm_readdata      => AV2RAM_readdata,              
		avm_readdatavalid => AV2RAM_readdatavalid,  
		avm_address       => AV2RAM_address, 
		avm_byteenable    => AV2RAM_byteenable,     
		avm_read          => AV2RAM_read,
		avm_write         => AV2RAM_write,         
		avm_writedata     => AV2RAM_writedata     
	);
	
	
	
	swp_cntrl: swap_control
	PORT MAP( 
		Enable          => CTRL_Enable,    
		Clk             => CTRL_AvClk,  
		AVM_WrEn        => CTRL_WrEn,
		AVM_RdEn        => CTRL_RdEn, 
		AVM_Addr        => CTRL_RamAddr,   
		AVM_WrData      => CTRL_WordOut,
		AVM_ByteEnCode  => CTRL_ByteEn,         
		AVM_Ready       => CTRL_AvLoad,       
		AVM_RdData      => CTRL_WordIn,     
		  
		FIFO_aclr		=> FIFO_aclr_IN,     
		FIFO_data		=> FIFO_data_IN,    
		FIFO_rdreq		=> FIFO_rdreq_IN,    
		FIFO_wrreq		=> FIFO_wrreq_IN,       
		FIFO_q		    => FIFO_q_OUT,     
		FIFO_empty		=> FIFO_rdempty_OUT,	
		FIFO_full		=> FIFO_wrfull_OUT,      
		
		SwapStart       => CTRL_Start     
		
	);
	
	
	
	------------- RESET SYSTEM --------------
	AVM_nReset_IN <= Avalon_nReset;
	CTRL_Enable   <= Avalon_nReset AND LOC_Enable;
	
	----------- CLOCK SYSTEM ---------------
	AVM_Clock_IN    <= Avalon_Clock;
	CTRL_AvClk      <= Avalon_Clock;
	
	----------- Avalon-MM Master connection ---------
	AVM_WrEn_IN        <= CTRL_WrEn;
	AVM_RdEn_IN        <= CTRL_RdEn;
	AVM_AddrIn_IN      <= CTRL_RamAddr;
	AVM_WrDataIn_IN    <= CTRL_WordOut;  
	AVM_ByteEnCode_IN  <= CTRL_ByteEn;
	
	CTRL_AvLoad        <= AVM_Ready_OUT;      
	CTRL_WordIn        <= AVM_RdDataOut_OUT; 
	--CTRL_RAM_Busy      <= '0'; --( AV2PCIE_read OR AV2PCIE_write );
	CTRL_Start         <= StartPulse;
	
	------------- FIFO Connection -------------------
	FIFO_rdclk_IN      <= Avalon_Clock;
	FIFO_wrclk_IN      <= Avalon_Clock;
	
	---------- BITE ---------------------------
	--LOC_Enable <= '0';
	---------- SYNTHESIS ---------------------------
	LOC_Enable <= Signal_Registers( CONFIG_REG_ADDR )( SWAP_EN );
	--LOC_Enable <= A429_TxEnabled;
	
	--------- DEBUG ONLY -----------------------------
	--LOC_Enable <= '1'; 
	-------------------------------------------------------
	
	-- Settings registers ( Avalon-MM Slave )
	AVS_Config: PROCESS( Avalon_nReset, Avalon_Clock )
	BEGIN
		
		IF( Avalon_nReset = '0' ) THEN
			
			AVS_waitrequest   <= '0';
			AVS_readdatavalid <= '0';
			AVS_readdata      <= ( OTHERS => '0' );
			Signal_SlaveState <= AVALON_RESET;
			LOC_IntFlagReg    <= ( OTHERS => '0' );
			
		ELSIF RISING_EDGE( Avalon_Clock ) THEN
			
			CASE Signal_SlaveState IS
			
			WHEN AVALON_IDLE =>
				IF( AVS_write = '1' ) THEN
					AVS_waitrequest   <= '0';
					Signal_SlaveState <= AVALON_WRITE;
				ELSIF( AVS_read = '1' ) THEN
					AVS_waitrequest   <= '0';
					Signal_SlaveState <= AVALON_READ;
				ELSE
					AVS_waitrequest   <= '1';
				END IF;
				LOC_IntRegRead    <= '0';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				address           <= TO_INTEGER( UNSIGNED( AVS_address ) );
				data              <= AVS_writedata;
				
			WHEN AVALON_WRITE =>
				AVS_waitrequest             <= '1';
				AVS_readdatavalid           <= '0';
				AVS_readdata                <= ( OTHERS => '0' );
				Signal_Registers( address ) <= data;
				Signal_SlaveState           <= AVALON_IDLE;
			
			WHEN AVALON_READ =>
				IF( address = INTFLAG_REG_ADDR ) THEN
					LOC_IntRegRead <= '1';
				END IF;
				AVS_waitrequest   <= '1';
				AVS_readdatavalid <= '1';
				AVS_readdata      <= Signal_Registers( address );
				Signal_SlaveState <= AVALON_IDLE;
			
			WHEN OTHERS =>
				AVS_waitrequest   <= '1';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_IDLE;
			
			END CASE;
			
		END IF;
		
	END PROCESS;
	
END ARCH;

