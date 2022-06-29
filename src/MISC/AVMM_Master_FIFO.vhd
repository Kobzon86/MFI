LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AVMM_Master_FIFO IS
	
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
	
END AVMM_Master_FIFO;

ARCHITECTURE logic OF AVMM_Master_FIFO IS
	
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
	
	
	
	
	CONSTANT usMultiplier  : INTEGER := ( CLOCK_FREQUENCE / 1000000 );
	
	TYPE T_Avalon_State  IS ( AVALON_RESET, AVALON_IDLE, AVALON_WRITE, AVALON_ACK_WRITE, AVALON_READ, AVALON_ACK_READ, FIFO_RDWAIT );
	
	SIGNAL Signal_MasterState : T_Avalon_State                                               := AVALON_RESET;
	SIGNAL Signal_MasterWait  : STD_LOGIC                                                    := '0';
	SIGNAL Signal_MasterAddr  : STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 )          := ( OTHERS => '0' );
	SIGNAL Signal_MasterData  : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 )          := ( OTHERS => '0' );
	SIGNAL AV_RdWr            : STD_LOGIC                                                    := '0'; -- 0 = read; 1 = write
	--SIGNAL RxLatchEn          : STD_LOGIC                                                    := '0';
	--SIGNAL ReadyTmp           : STD_LOGIC                                                    := '0';
	
	SIGNAL FIFO_aclr          : STD_LOGIC                                                    := '0';  
	SIGNAL FIFO_RdEn          : STD_LOGIC                                                    := '0';
	SIGNAL FIFO_RdEnTmp       : STD_LOGIC                                                    := '0';
	SIGNAL FIFO_AddrOut       : STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 )          := ( OTHERS => '0' );
	SIGNAL FIFO_DataOut       : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 )          := ( OTHERS => '0' );
	SIGNAL FIFO_ByteEn        : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH / 8 ) - 1 DOWNTO 0 )      := ( OTHERS => '0' );
	SIGNAL FIFO_Empty         : STD_LOGIC                                                    := '0';
	SIGNAL FIFO_Full          : STD_LOGIC                                                    := '0';
	
	SIGNAL InputFIFO_IN       : STD_LOGIC_VECTOR( AVM_ADDR_WIDTH + AVM_DATA_WIDTH + ( AVM_DATA_WIDTH / 8 ) -1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL FIFO_Out           : STD_LOGIC_VECTOR( AVM_ADDR_WIDTH + AVM_DATA_WIDTH + ( AVM_DATA_WIDTH / 8 ) -1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL FIFO_WaitCnt       : INTEGER RANGE 0 TO 3;
	
BEGIN
	
--	AddrFIFO: FIFO 
	InputFIFO: FIFO -- ByteEn & Addr & Data
	GENERIC MAP(
		DataWidth  =>  AVM_ADDR_WIDTH + AVM_DATA_WIDTH + ( AVM_DATA_WIDTH / 8 ),
		UsedWidth  =>  FIFO_USED_WIDTH,
		WordNum    =>  FIFO_WORDS_NUM
	)
	PORT MAP(
		aclr		=> FIFO_aclr,
		data		=> InputFIFO_IN,  --( ByteEnCode & AddrIn & WrDataIn ),
		rdclk		=> Clock,
		rdreq		=> FIFO_RdEn,
		wrclk		=> Clock,
		wrreq		=> WrEn,
		q		    => FIFO_Out,
		rdempty		=> FIFO_Empty,
		wrfull		=> FIFO_Full
	);
	
	
	 InputFIFO_IN <= ( ByteEnCode & AddrIn & WrDataIn );
	 
	 
	 --FIFO_ByteEn  <= FIFO_Out( FIFO_Out'LEFT DOWNTO ( FIFO_Out'LEFT - ( AVM_DATA_WIDTH/8 - 1 ) ) ); 
	 --FIFO_AddrOut <= FIFO_Out( ( FIFO_Out'LEFT - AVM_DATA_WIDTH/8 ) DOWNTO ( FIFO_Out'LEFT - AVM_DATA_WIDTH/8 - ( AVM_ADDR_WIDTH - 1 ) ) );
	 --FIFO_DataOut <= FIFO_Out( ( FIFO_Out'LEFT - AVM_DATA_WIDTH/8 - AVM_ADDR_WIDTH ) DOWNTO 0 );
	 
	
	
	FIFO_SignReg: PROCESS( nReset, Clock )
	BEGIN
		IF nReset = '0' THEN
			FIFO_RdEn <= '0';
		ELSIF FALLING_EDGE( Clock ) THEN
			FIFO_RdEn <= FIFO_RdEnTmp;
		END IF;
	END PROCESS;
		

	--FIFO_DatReg: PROCESS( nReset, Clock )
	--BEGIN
		--IF nReset = '0' THEN
			--FIFO_ByteEn  <= ( OTHERS => '0' );
			--FIFO_AddrOut <= ( OTHERS => '0' );
			--FIFO_DataOut <= ( OTHERS => '0' );
		--ELSIF RISING_EDGE( Clock ) THEN
			--FIFO_ByteEn  <= FIFO_Out( FIFO_Out'LEFT DOWNTO ( FIFO_Out'LEFT - ( AVM_DATA_WIDTH/8 - 1 ) ) ); 
			--FIFO_AddrOut <= FIFO_Out( ( FIFO_Out'LEFT - AVM_DATA_WIDTH/8 ) DOWNTO ( FIFO_Out'LEFT - AVM_DATA_WIDTH/8 - ( AVM_ADDR_WIDTH - 1 ) ) );
			--FIFO_DataOut <= FIFO_Out( ( FIFO_Out'LEFT - AVM_DATA_WIDTH/8 - AVM_ADDR_WIDTH ) DOWNTO 0 );
		--END IF;
	--END PROCESS;	
	


	---- Ready Out Reg
	--PROCESS( Clock )
	--BEGIN
		--IF FALLING_EDGE( Clock ) THEN
			--Ready     <= ReadyTmp;
		--END IF;
	--END PROCESS;
	
	
	
	-- Avalon-MM Master
	PROCESS( nReset, Clock )
		VARIABLE writeAckCounter : INTEGER RANGE 0 TO AVM_WRITE_ACKNOWLEDGE := 0;
		VARIABLE readAckCounter  : INTEGER RANGE 0 TO AVM_READ_ACKNOWLEDGE  := 0;
	BEGIN
		
		IF( nReset = '0' ) THEN
			
			avm_write          <= '0';
			avm_read           <= '0';
			avm_address        <= ( OTHERS => '0' );
			avm_byteenable     <= ( OTHERS => '0' );
			avm_writedata      <= ( OTHERS => '0' );
			writeAckCounter    := 0;
			Signal_MasterWait  <= '0';
			Signal_MasterState <= AVALON_RESET;
			Ready              <= '0';
			
			FIFO_ByteEn  <= ( OTHERS => '0' );
			FIFO_AddrOut <= ( OTHERS => '0' );
			FIFO_DataOut <= ( OTHERS => '0' );
			FIFO_WaitCnt <= 0;

			
		ELSIF RISING_EDGE( Clock ) THEN
			
			FIFO_ByteEn  <= FIFO_Out( FIFO_Out'LEFT DOWNTO ( FIFO_Out'LEFT - ( AVM_DATA_WIDTH/8 - 1 ) ) ); 
			FIFO_AddrOut <= FIFO_Out( ( FIFO_Out'LEFT - AVM_DATA_WIDTH/8 ) DOWNTO ( FIFO_Out'LEFT - AVM_DATA_WIDTH/8 - ( AVM_ADDR_WIDTH - 1 ) ) );
			FIFO_DataOut <= FIFO_Out( ( FIFO_Out'LEFT - AVM_DATA_WIDTH/8 - AVM_ADDR_WIDTH ) DOWNTO 0 );
			
			CASE Signal_MasterState IS
			
			WHEN AVALON_RESET =>
				avm_write          <= '0';
				avm_read           <= '0';
				avm_address        <= ( OTHERS => '0' );
				avm_byteenable     <= ( OTHERS => '0' );
				avm_writedata      <= ( OTHERS => '0' );
				Signal_MasterState <= AVALON_IDLE;
				--ReadyTmp           <= '0';
				--RxLatchEn          <= '0';
			
			WHEN AVALON_IDLE =>
				IF( RdEn = '1' ) THEN
					Signal_MasterAddr  <= AddrIn;
				 	Signal_MasterState <= AVALON_READ;
				ELSE
					Signal_MasterAddr  <= ( OTHERS => '0' );
					Signal_MasterData  <= ( OTHERS => '0' );
					avm_write          <= '0';
					avm_read           <= '0';
					avm_byteenable     <= ( OTHERS => '0' );
					Ready              <= '0';
					FIFO_WaitCnt       <= 0;
					IF ( FIFO_Empty = '0' )	THEN
						FIFO_RdEnTmp <= '1';
						Signal_MasterState <= FIFO_RDWAIT;
					END IF;
				END IF;

			
			
			
				--avm_write       <= '0';
				--avm_read        <= '0';
				--avm_byteenable  <= ( OTHERS => '0' );
				--avm_writedata   <= ( OTHERS => '0' );
				
				--IF ( FIFO_Empty = '0' )	THEN
					--FIFO_RdEnTmp <= '1';
					--Signal_MasterState <= FIFO_RDWAIT;
				--ELSIF( RdEn = '1' ) THEN
					--Signal_MasterAddr  <= AddrIn;
				 	--Signal_MasterState <= AVALON_READ;
				
				----ELSIF RxLatchEn = '1' THEN
					----IF( avm_readdatavalid = '1' ) THEN
						----ReadyTmp  <= '1';
						----RdDataOut <= avm_readdata; 
						----RxLatchEn <= '0';
					----END IF;
				
				--END IF;
				
				--IF RxLatchEn = '0' THEN
					--ReadyTmp <= '0';
				--END IF;
			
			
			WHEN FIFO_RDWAIT => 
				FIFO_RdEnTmp       <= '0';
				IF FIFO_WaitCnt < 2 THEN
					FIFO_WaitCnt <= FIFO_WaitCnt + 1;
			    ELSE
					FIFO_WaitCnt <= 0;
					Signal_MasterState <= AVALON_WRITE;
				END IF;
			    
			WHEN AVALON_WRITE =>
				writeAckCounter    := AVM_WRITE_ACKNOWLEDGE;
				avm_write          <= '1';
				avm_read           <= '0';
				avm_address        <= FIFO_AddrOut;  
				avm_byteenable     <= FIFO_ByteEn;   
				avm_writedata      <= FIFO_DataOut;  
				--RxLatchEn          <= '0';
				IF( avm_waitrequest = '1' ) THEN
					Signal_MasterWait <= '1';
				ELSE
					Signal_MasterWait <= '0';
				END IF;
				Signal_MasterState <= AVALON_ACK_WRITE;
			
			
			WHEN AVALON_ACK_WRITE =>
				IF( Signal_MasterWait = '1' ) THEN
					IF( writeAckCounter > 0 )THEN
						writeAckCounter := ( writeAckCounter - 1 );
					ELSE
						Signal_MasterState <= AVALON_IDLE;
					END IF;
				ELSIF( avm_waitrequest = '0' ) THEN
					Signal_MasterState <= AVALON_IDLE;
				END IF;
			
			
			WHEN AVALON_READ =>
				readAckCounter     := AVM_READ_ACKNOWLEDGE;
				avm_write          <= '0';
				avm_read           <= '1';
				--RxLatchEn          <= '0';
				avm_address        <= Signal_MasterAddr;
				avm_byteenable     <= ByteEnCode;
				Ready              <= '0';
				IF( avm_waitrequest = '1' ) THEN
					Signal_MasterWait <= '1';
					Signal_MasterWait <= '1';
					Signal_MasterState <= AVALON_ACK_READ;
				ELSE
					Signal_MasterWait <= '0';
					IF( avm_readdatavalid = '1' ) THEN
						Ready        <= '1';
						RdDataOut    <= avm_readdata; 
						Signal_MasterState <= AVALON_IDLE;
					END IF;
				END IF;
				
			
			WHEN AVALON_ACK_READ =>
				IF( avm_readdatavalid = '1' ) THEN
					Ready     <= '1';
					RdDataOut <= avm_readdata; 
					Signal_MasterState <= AVALON_IDLE;
				ELSE
					Ready     <= '0';
					RdDataOut <= ( OTHERS => '0' );
					--RxLatchEn <= '0';
					IF( Signal_MasterWait = '1' ) THEN
						IF( readAckCounter > 0 )THEN
							readAckCounter := ( readAckCounter - 1 );
						ELSE
							Signal_MasterState <= AVALON_IDLE;
						END IF;
					ELSE
						Signal_MasterState <= AVALON_IDLE;
					END IF;
				END IF;
				
				
			
			
				--IF( Signal_MasterWait = '1' ) THEN
					--IF( readAckCounter > 0 )THEN
						--readAckCounter := ( readAckCounter - 1 );
					--ELSE
						--Signal_MasterState <= AVALON_IDLE;
					--END IF;
				--ELSIF( avm_waitrequest = '0' ) THEN
					--avm_read  <= '0';
					--RxLatchEn <= '1';
					--Signal_MasterState <= AVALON_IDLE;
				--END IF;
				
			END CASE;
			
		END IF;
		
	END PROCESS;
	
	
	
	
END logic;
