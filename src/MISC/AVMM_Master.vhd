LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AVMM_Master IS
	
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
	
END AVMM_Master;

ARCHITECTURE logic OF AVMM_Master IS
	
	CONSTANT usMultiplier  : INTEGER := ( CLOCK_FREQUENCE / 1000000 );
	
	TYPE T_Avalon_State  IS ( AVALON_RESET, AVALON_IDLE, AVALON_WRITE, AVALON_ACK_WRITE, AVALON_READ, AVALON_ACK_READ );
	
	SIGNAL Signal_MasterState : T_Avalon_State                                               := AVALON_RESET;
	SIGNAL Signal_MasterWait  : STD_LOGIC                                                    := '0';
	SIGNAL Signal_MasterAddr  : STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 )          := ( OTHERS => '0' );
	SIGNAL Signal_MasterData  : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 )          := ( OTHERS => '0' );
	SIGNAL AV_RdWr            : STD_LOGIC                                                    := '0'; -- 0 = read; 1 = write
	SIGNAL ReadyTmp           : STD_LOGIC;
	SIGNAL RdDataOutTmp       : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
	
BEGIN
	
	
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
			Signal_MasterAddr  <= ( OTHERS => '0' );
			Signal_MasterData  <= ( OTHERS => '0' );
			Signal_MasterState <= AVALON_RESET;
			ReadyTmp           <= '0';
			RdDataOutTmp       <= ( OTHERS => '0' );
			
		ELSIF RISING_EDGE( Clock ) THEN
			Ready <= ReadyTmp;
			RdDataOut <= RdDataOutTmp;
		
			CASE Signal_MasterState IS
			
			WHEN AVALON_RESET =>
				avm_write          <= '0';
				avm_read           <= '0';
				avm_address        <= ( OTHERS => '0' );
				avm_byteenable     <= ( OTHERS => '0' );
				avm_writedata      <= ( OTHERS => '0' );
				Signal_MasterAddr  <= ( OTHERS => '0' );
				Signal_MasterData  <= ( OTHERS => '0' );
				Signal_MasterState <= AVALON_IDLE;
				ReadyTmp           <= '0';

			
			WHEN AVALON_IDLE =>
				IF( WrEn = '1' ) THEN
					Signal_MasterAddr  <= AddrIn;
					Signal_MasterData  <= WrDataIn;
					Signal_MasterState <= AVALON_WRITE;
				ELSIF( RdEn = '1' ) THEN
					Signal_MasterAddr  <= AddrIn;
				 	Signal_MasterState <= AVALON_READ;
				ELSE
				--	Signal_MasterAddr  <= ( OTHERS => '0' );
				--	Signal_MasterData  <= ( OTHERS => '0' );
					avm_write          <= '0';
					avm_read           <= '0';
					avm_byteenable     <= ( OTHERS => '0' );
					ReadyTmp              <= '0';
				END IF;

				
			WHEN AVALON_WRITE =>
				writeAckCounter    := AVM_WRITE_ACKNOWLEDGE;
				avm_write          <= '1';
				avm_read           <= '0';
				avm_address        <= Signal_MasterAddr;
				avm_byteenable     <= ByteEnCode;
				avm_writedata      <= Signal_MasterData;
				IF( avm_waitrequest = '1' ) THEN
					Signal_MasterWait <= '1';
				ELSE
					Signal_MasterWait <= '0';
				END IF;
				Signal_MasterState <= AVALON_ACK_WRITE;

			
			WHEN AVALON_ACK_WRITE =>
				IF( avm_waitrequest = '0' ) THEN
					avm_write <= '0';
					Signal_MasterState <= AVALON_IDLE;
				ELSIF( Signal_MasterWait = '1' ) THEN
					IF( writeAckCounter > 0 )THEN
						writeAckCounter := ( writeAckCounter - 1 );
					ELSE
						avm_write <= '0';
						Signal_MasterState <= AVALON_IDLE;
					END IF;
				END IF;

			
			WHEN AVALON_READ =>
				readAckCounter     := AVM_READ_ACKNOWLEDGE;
				avm_write          <= '0';
				avm_read           <= '1';
				avm_address        <= Signal_MasterAddr;
				avm_byteenable     <= ByteEnCode;
				IF( avm_waitrequest = '1' ) THEN
					Signal_MasterWait <= '1';
					Signal_MasterState <= AVALON_ACK_READ;
				ELSE
					Signal_MasterWait <= '0';
					IF( avm_readdatavalid = '1' ) THEN
						ReadyTmp     <= '1';
						RdDataOutTmp <= avm_readdata; 
						Signal_MasterState <= AVALON_IDLE;
					END IF;
				END IF;
				
			
			WHEN AVALON_ACK_READ =>
				IF( avm_readdatavalid = '1' ) THEN
					ReadyTmp     <= '1';
					RdDataOutTmp <= avm_readdata; 
					Signal_MasterState <= AVALON_IDLE;
				ELSE
					ReadyTmp     <= '0';
					RdDataOutTmp <= ( OTHERS => '0' );
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
			
			END CASE;
			
		END IF;
		
	END PROCESS;
	
	
	
	
END logic;
