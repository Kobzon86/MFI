-- ARINC429 Transmitter v.02
-- TX_FIFO added


LIBRARY ieee;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

USE work.arinc429tx_pkg.ALL;

ENTITY a429_txphy IS
	PORT(
		Enable      : IN  STD_LOGIC;
		ClockIn     : IN  STD_LOGIC;
		ClockMux    : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
		------------- FIFO Signals ------------------
		Data        : IN  STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
		WrClk       : IN  STD_LOGIC;
		WrEn        : IN  STD_LOGIC;
		Full        : OUT STD_LOGIC;
		---------- PHY OUT Signals -----------------
		OutputA     : OUT STD_LOGIC;
		OutputB     : OUT STD_LOGIC;
		SlewRate    : OUT STD_LOGIC;
		OutReg      : OUT STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
		Busy        : OUT STD_LOGIC
	);
	
END a429_txphy;

ARCHITECTURE logic OF a429_txphy IS

	
	COMPONENT FIFO IS
	GENERIC(
		DataWidth  : INTEGER := 8;
		UsedWidth  : INTEGER := 8; -- 2 ** UsedWidth = WordNum
		WordNum    : INTEGER := 256
	);
	PORT(
		aclr        : IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q           : OUT STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		wrfull		: OUT STD_LOGIC 
	);
	END COMPONENT;
	
	
	
	CONSTANT StopWidth : INTEGER := 4;
	CONSTANT bitsCounterSize : INTEGER := ( ( ( AR429_DATA_WIDTH + StopWidth ) * 2 ) - 1 ); -- = 36*2 - 1 = 71 (0x47)
	CONSTANT stopTransmition : INTEGER := ( bitsCounterSize - ( StopWidth * 2 ) );          -- 71 - 8 = 63 (0x3F)
	
	SIGNAL Clock       : STD_LOGIC;
	SIGNAL TxClock     : STD_LOGIC := '0';
	SIGNAL Ready       : STD_LOGIC := '0';
	SIGNAL Transmit    : STD_LOGIC := '0';
	SIGNAL BitBuffer   : STD_LOGIC;
	SIGNAL Buff        : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL LoadPulse   : STD_LOGIC := '0';
	SIGNAL bitsCounter : INTEGER RANGE 0 TO bitsCounterSize;
	SIGNAL L1, L2      : STD_LOGIC := '0';
	SIGNAL Cnt         : STD_LOGIC_VECTOR( 5 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RdEn        : STD_LOGIC := '0';
	SIGNAL RdEnFIFO    : STD_LOGIC := '0';
	SIGNAL Re0, Re1    : STD_LOGIC := '0';
	SIGNAL RdData      : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL Empty       : STD_LOGIC := '0';
	SIGNAL ParBit      : STD_LOGIC := '1';
	SIGNAL F_clr       : STD_LOGIC := '0';
	SIGNAL OutputA_Tmp : STD_LOGIC := '0'; 
	SIGNAL OutputB_Tmp : STD_LOGIC := '0';
	SIGNAL OutRegTmp1  : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL OutRegTmp2  : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );	
	
BEGIN

	tx_fifo: FIFO 
	GENERIC MAP(
		DataWidth  => AR429_DATA_WIDTH,
		UsedWidth  => 1, 
		WordNum    => 2 
	)
	PORT MAP(
		aclr        => F_clr,
		data		=> Data,  
		rdclk		=> ClockIn, 
		rdreq		=> RdEnFIFO, 
		wrclk		=> WrClk, 
		wrreq		=> WrEn, 
		q           => RdData, 
		rdempty		=> Empty, 
		wrfull		=> Full 
	);

	F_clr <= ( NOT Enable ); 
	
	GenClocks: PROCESS( ClockIn )
	BEGIN
		IF RISING_EDGE( ClockIn ) THEN
			IF Cnt < "111111" THEN
				Cnt <= STD_LOGIC_VECTOR( UNSIGNED( Cnt ) + "000001" );
			ELSE
				Cnt <= ( OTHERS => '0' );
			END IF;
			
			CASE ClockMux IS
				WHEN "01"   => Clock <= Cnt(5); 
				WHEN "10"   => Clock <= Cnt(3); 
				WHEN "11"   => Clock <= Cnt(2); 
				WHEN OTHERS => Clock <= '0';
			END CASE;
			
			CASE ClockMux IS
				WHEN "01"   => SlewRate <= '0';
				WHEN OTHERS => SlewRate <= '1';
			END CASE;
			
		END IF;
		
	END PROCESS;

	
	
	OutReg_Sync: PROCESS( Enable, ClockIn ) 
	BEGIN
		IF Enable = '0' THEN
			OutReg     <= ( OTHERS => '0' );
			OutRegTmp2 <= ( OTHERS => '0' );
		ELSIF RISING_EDGE( ClockIn ) THEN
			OutRegTmp2 <= OutRegTmp1;
			OutReg     <= OutRegTmp2;
		END IF;
	END PROCESS;
	
	
	
	FIFO_RdEnGen: PROCESS( Enable, ClockIn )
	BEGIN
		IF Enable = '0' THEN
			Re0 <= '0';
			Re1 <= '0';
		ELSIF FALLING_EDGE( ClockIn ) THEN
			Re0 <= RdEn;
			Re1 <= Re0;
			RdEnFIFO <= Re0 AND ( NOT Re1 );
		END IF;
	END PROCESS;
	
	
	
	
	Transmission: PROCESS( Enable, Clock )
	BEGIN
		
		IF( Enable = '0' ) THEN
			
		--	Busy <= '0';
		--	OutputA <= 'Z';
		--	OutputB <= 'Z';
			ParBit  <= '1';
			RdEn    <= '0';
			OutRegTmp1 <= ( OTHERS => '0' );

		ELSIF RISING_EDGE( Clock ) THEN
			IF Ready = '0' THEN
				IF Empty = '0' THEN
					RdEn <= '1';
				ELSE
					RdEn <= '0';
				END IF;
			ELSE
				RdEn <= '0';
			END IF;
			
			IF( RdEn = '1' ) THEN
				
				TxClock <= '0';
				Ready  <= '1';
				ParBit <= '1';
				
				Buff( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) <= ( RdData( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) ); 
				
				bitsCounter <= 0;
				
			ELSIF( Ready = '1' ) THEN
				
				TxClock <= NOT TxClock;
				
				IF( bitsCounter <= stopTransmition ) THEN
					Transmit  <= '1';
					
					IF ( bitsCounter < ( stopTransmition - 2 ) ) THEN

						BitBuffer <= Buff( 0 );
						OutRegTmp1( ( AR429_DATA_WIDTH - 2 ) DOWNTO 0 ) <= ( RdData( ( AR429_DATA_WIDTH - 2 ) DOWNTO 0 ) ); -- -1

					ELSIF ( bitsCounter = ( stopTransmition - 1 ) ) THEN  -- -2

						BitBuffer <= ParBit; -- should be ParBit, 

					END IF;
					
					IF( TxClock = '1' ) THEN
						Buff( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) <= ( '0' & Buff( ( AR429_DATA_WIDTH - 1 ) DOWNTO 1 ) );
						
						IF ( bitsCounter < ( stopTransmition - 1 ) ) THEN
							--IF Buff( 0 ) = '0' THEN -- should be '1', but Buff <= NOT RdData. So we must count zeroes instead of 1-s 
							IF Buff( 0 ) = '1' THEN 
								ParBit <= NOT ParBit;

							END IF;
						END IF;
					
						OutRegTmp1( OutRegTmp1'LEFT ) <= ParBit;
						
					END IF;
				ELSE
					Transmit <= '0';
				END IF;
				
				IF( bitsCounter < bitsCounterSize ) THEN
					bitsCounter <= ( bitsCounter + 1 );
				ELSE
					Ready  <= '0';
					--ParBit <= '1';
				END IF;
				
			END IF;
			
		--	Busy    <= ( Transmit OR Ready );
		--	OutputA <= ( Transmit AND TxClock AND BitBuffer );
		--	OutputB <= ( Transmit AND TxClock AND ( NOT BitBuffer ) );
			
		END IF;
		
	END PROCESS;
	
	
	
	
	
	OutGen: PROCESS( Enable, Clock )
	BEGIN
		IF( Enable = '0' ) THEN
			
			Busy    <= '0';
			OutputA <= 'Z';
			OutputB <= 'Z';
			
		ELSIF FALLING_EDGE( Clock ) THEN
		
			OutputA_Tmp <= ( Transmit AND TxClock AND BitBuffer );
			OutputB_Tmp <= ( Transmit AND TxClock AND ( NOT BitBuffer ) );
			
		--	OutputA <= OutputA_Tmp;
		--	OutputB <= OutputB_Tmp;
		
		ELSIF RISING_EDGE( Clock ) THEN
			
			Busy    <= ( Transmit OR Ready );
			OutputA <= OutputA_Tmp;
			OutputB <= OutputB_Tmp; 
			
		
		END IF;
	
	END PROCESS;
	
END logic;
