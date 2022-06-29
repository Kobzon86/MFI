-- MIL-STD1553 receiver PHY-level
-- ver 0.2
-- Edited using A708Line_model
-- Used ClockIn = 16 MHz
-- Rx FIFO added: WordFIFO, StatFIFO, ParErrFIFO


LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

USE work.milstd_1553_pkg.ALL;

ENTITY milstd1553rxphy IS
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

END milstd1553rxphy;



ARCHITECTURE RTL OF milstd1553rxphy IS 

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

--	CONSTANT FreqMult     : INTEGER := 16; -- was 16	 RxClk = 4 MHz, real transmit freq = 1 MHz
--	CONSTANT SYNC_COMSTAT : STD_LOGIC_VECTOR( ( ( FreqMult * 3 ) - 1 ) DOWNTO 0 ) := x"7FFFFF000000"; --x"FFFFFF000000";
--	CONSTANT SYNC_COMSTAT2: STD_LOGIC_VECTOR( ( ( FreqMult * 3 ) - 1 ) DOWNTO 0 ) := x"FFFFFF000000"; --x"FFFFFF000000";
	
--	CONSTANT SYNC_DATA    : STD_LOGIC_VECTOR( ( ( FreqMult * 3 ) - 1 ) DOWNTO 0 ) := x"0000007FFFFF";
--	CONSTANT SYNC_DATA2   : STD_LOGIC_VECTOR( ( ( FreqMult * 3 ) - 1 ) DOWNTO 0 ) := x"8000007FFFFF";
	
	
--	CONSTANT SYNC_TYPE_DATA : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
--	CONSTANT SYNC_TYPE_COMM : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "10";
	
	CONSTANT FIFO_WORDS_NUM   : INTEGER := 64;
	CONSTANT FIFO_USED_WIDTH  : INTEGER := 6;
	CONSTANT PAUSE_TIMEOUT_US : INTEGER := 2;
	CONSTANT PAUSE_TIMEOUT    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( PAUSE_TIMEOUT_US * 16, 20 ) );
	
	CONSTANT WordLenBits    : UNSIGNED( 7 DOWNTO 0 ) := x"10"; 		
	
	SIGNAL InA     : STD_LOGIC := '0';
	SIGNAL InB     : STD_LOGIC := '0';
	SIGNAL InAt    : STD_LOGIC := '0';
	SIGNAL InBt    : STD_LOGIC := '0';
	SIGNAL InXor   : STD_LOGIC := '0';
	SIGNAL RxClk   : STD_LOGIC := '0'; -- ClockIn/4 = 4MHz
	
	SIGNAL SyncIn  : STD_LOGIC_VECTOR( ( ( FreqMult * 3 ) - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );	
	SIGNAL ShiftInBuf    : STD_LOGIC_VECTOR( ( ( FreqMult * 3 ) / 4 - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );	
	SIGNAL SyncType      : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' ); -- 10 = COMMAND_STAT, 01 = DATA
	SIGNAL SyncTypeReady : STD_LOGIC := '0';	

	SIGNAL ShiftCnt : UNSIGNED( 7 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL BitCnt   : UNSIGNED( 7 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL WordData : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL ReadyOut : STD_LOGIC := '0';
	SIGNAL R1, R2   : STD_LOGIC := '0';
	SIGNAL CalcParity   : STD_LOGIC := '1';
	SIGNAL RxParity : STD_LOGIC := '0';
	SIGNAL ParErrTmp : STD_LOGIC_VECTOR( 0 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL cnt      : UNSIGNED( 1 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL cnt2     : UNSIGNED( 1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL Reception : STD_LOGIC := '0';
	SIGNAL InA_Read  : STD_LOGIC := '0';
	SIGNAL WrEn      : STD_LOGIC := '0';
	SIGNAL w1, w2    : STD_LOGIC := '0';
	
	SIGNAL FIFO_aclr   : STD_LOGIC := '0';
	SIGNAL FIFO_Empty  : STD_LOGIC := '0';
	SIGNAL FIFO_InData : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL FIFO_InStat : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL FIFO_InDataT : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL FIFO_InStatT : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL FIFO_WrEn   : STD_LOGIC := '0';
	SIGNAL FIFO_Full   : STD_LOGIC := '0';
	SIGNAL FIFO_InPar  : STD_LOGIC_VECTOR( 0 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL FIFO_InParT  : STD_LOGIC_VECTOR( 0 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL FIFO_ParEmpty : STD_LOGIC := '0';
	SIGNAL FIFO_ParFull  : STD_LOGIC := '0';
	
	SIGNAL FIFO_StEmpty : STD_LOGIC := '0';
	SIGNAL FIFO_StFull  : STD_LOGIC := '0';
	
	SIGNAL TransmitDelay : STD_LOGIC := '0';
	SIGNAL PauseReady    : STD_LOGIC := '0';
	SIGNAL TimerRst      : STD_LOGIC := '0';
	SIGNAL PR1, PR2      : STD_LOGIC := '0';
	SIGNAL E1, E2, E3    : STD_LOGIC := '0';
	SIGNAL EmptyGenPulse : STD_LOGIC := '0';
	SIGNAL TIM_Enable    : STD_LOGIC := '0';
	
BEGIN

	DataFIFO: FIFO 
	GENERIC MAP(
		DataWidth  => 16,  
		UsedWidth  => FIFO_USED_WIDTH,   
		WordNum    => FIFO_WORDS_NUM 
	)
	PORT MAP(
		aclr        =>  FIFO_aclr,
		data		=>  FIFO_InData,
		rdclk		=>  RdClk,
		rdreq		=>  RdEn,
		wrclk		=>  ClockIn,
		wrreq		=>  FIFO_WrEn,
		q           =>  DataOut,
		rdempty		=>  FIFO_Empty,
		wrfull		=>  FIFO_Full
	);


	StatFIFO: FIFO 
	GENERIC MAP(
		DataWidth  => 2,  
		UsedWidth  => FIFO_USED_WIDTH,   
		WordNum    => FIFO_WORDS_NUM 
	)
	PORT MAP(
		aclr        =>  FIFO_aclr,
		data		=>  FIFO_InStat,
		rdclk		=>  RdClk,
		rdreq		=>  RdEn,
		wrclk		=>  ClockIn,
		wrreq		=>  FIFO_WrEn,
		q           =>  StatOut,
		rdempty		=>  FIFO_StEmpty,
		wrfull		=>  FIFO_StFull
	);
	
	
	ParErrFIFO: FIFO 
	GENERIC MAP(
		DataWidth  => 1,  
		UsedWidth  => FIFO_USED_WIDTH,   
		WordNum    => FIFO_WORDS_NUM 
	)
	PORT MAP(
		aclr        =>  FIFO_aclr,
		data		=>  FIFO_InPar,
		rdclk		=>  RdClk,
		rdreq		=>  RdEn,
		wrclk		=>  ClockIn,
		wrreq		=>  FIFO_WrEn,
		q           =>  ParErrTmp,
		rdempty		=>  FIFO_ParEmpty,
		wrfull		=>  FIFO_ParFull
	);
	
	
	PauseTimer: timer
	PORT MAP(
		Enable   =>  TIM_Enable,
		Clk_x16  =>  ClockIn,
		Time     =>  PAUSE_TIMEOUT,
		ARST     =>  TimerRst,
		Single   =>  '1',
		Ready    =>  PauseReady
	);
	

	ParError <= ParErrTmp(0);
	FIFO_aclr <= NOT Enable;
	Rx_Flag   <= Reception;
	Strobe    <= Enable;
	
	
	TimerEnabler: PROCESS( Enable, TimerRst )
	BEGIN
		IF Enable = '0' THEN
			TIM_Enable <= '0';
		ELSIF RISING_EDGE( TimerRst ) THEN
			TIM_Enable <= '1';
		END IF;
	END PROCESS;
	
	
	EmptyReg: PROCESS( Enable, FIFO_Empty, RdClk )
	BEGIN
		IF ( ( Enable = '0' ) OR ( FIFO_Empty = '1' ) ) THEN
		
			nEmpty <= '0';
			E2     <= '1';
			E3     <= '1';
		
		ELSIF FALLING_EDGE( RdClk ) THEN
	
			E2 <= NOT E1;
			E3 <= E2;
			EmptyGenPulse <= ( E2 AND ( NOT E3 ) );
			
		ELSIF RISING_EDGE( RdClk ) THEN
			
			IF ( ( EmptyGenPulse = '1' ) AND ( WrEn = '1' ) ) THEN
				IF FIFO_Empty = '0' THEN
					nEmpty <= '1';
				END IF;
			ELSIF FIFO_Full = '1' THEN
				nEmpty <= '1';
			END IF;
			
		END IF;
	END PROCESS;
	
	
		-------- Double input registers -------------
	InputReg: PROCESS( Enable, ClockIn )
	BEGIN
		IF Enable = '0' THEN
			InA   <= '0';
			InB   <= '0';
			InAt  <= '0';
			InBt  <= '0';
			InXor <= '0';
			E1    <= '0';
		
		ELSIF FALLING_EDGE( ClockIn ) THEN
			InAt <= InputA;
			InBt <= InputB;
			InXor <= InAt XOR InBt;
			InA  <= InAt;
			InB  <= InBt;
			W1   <= WrEn;
			W2   <= W1;
		--	PR1  <= PauseReady;
		--	PR2 <= PR1;
			FIFO_WrEn <= ( w1 AND ( NOT w2 ) ) OR PR1;
			FIFO_InData   <= FIFO_InDataT; 
			FIFO_InStat   <= FIFO_InStatT;
			E1            <= FIFO_InStatT(0) AND FIFO_InStatT(1);
			FIFO_InPar(0) <= FIFO_InParT(0);
			
			TimerRst <= InAt OR InBt;
			
		END IF;
		
	END PROCESS;

	
	RxClkGen: PROCESS( Enable,  ClockIn )
	VARIABLE cnt_t : UNSIGNED( 3 DOWNTO 0 ) := ( OTHERS => '0' );
	BEGIN
		IF Enable = '0' THEN
			
			cnt_t := ( OTHERS => '0' );
			WrEn   <= '0';
			TxErr  <= '0';
			cnt2   <= "11";
			
		ELSIF RISING_EDGE( ClockIn ) THEN
			
			--------- Line pause word Writing -------------
			IF PauseReady = '1' THEN
				IF ( FIFO_Full = '0' ) AND ( TransmitDelay = '0' ) THEN
					WrEn            <= '1';
					PR1             <= '1';
					FIFO_InDataT    <= ( OTHERS => '0' );
					FIFO_InStatT    <= "11";
 					FIFO_InParT(0)  <= '0';
				ELSE
					WrEn <= '0';
					PR1  <= '0';
				END IF;
			
			ELSIF BitCnt = ( WordLenBits + x"01" ) THEN
				IF ( TransmitDelay = '0' ) THEN
				
 					TxErr <= '0';
 					
					IF FIFO_Full = '0' THEN
						PR1    <= '0';
						WrEn   <= '1';
						FIFO_InDataT <= WordData;
						FIFO_InStatT <= SyncType;
						FIFO_InParT(0)  <= ( CalcParity XOR RxParity );
					
					ELSE
						WrEn <= '0';
					
					END IF;
				ELSE
					IF TxWord = WordData THEN
						TxErr <= '0';
					ELSE
						TxErr <= '1';
					END IF;
				
				END IF;
			
			ELSE			
				
				WrEn <= '0';
				PR1  <= '0';
				
			END IF;
			
			


			IF InXor = '1' THEN

				Reception <= '1';
				cnt2      <= ( OTHERS => '0' );
			
			ELSE
				IF cnt2 < "11" THEN
				
					Reception <= '1';
					cnt2      <= cnt2 + "01";
				
				ELSE
					
					Reception <= '0';					
					
				END IF;
				
			END IF;

			IF ( Reception = '1' ) OR ( InXor = '1' ) THEN
				
				SyncIn <= SyncIn( ( SyncIn'LEFT - 1 ) DOWNTO 0 ) & InA; 			

				IF  cnt < "11" THEN
					cnt <= cnt + "01";
				ELSE
					cnt <= ( OTHERS => '0' );
				END IF;
				
				IF ShiftCnt = ( ( WordLenBits + 1 ) * 4 ) THEN   -- was x"4F"
					
					IF ( R1 = '1' ) AND ( R2 = '1' ) THEN
						SyncType <= ( OTHERS => '0' );
					END IF;
				
				ELSE
					
					IF ( SyncIn = SYNC_COMSTAT ) OR ( SyncIn = SYNC_COMSTAT2 ) THEN	
					
						SyncType      <= SYNC_TYPE_COMM;
						SyncTypeReady <= '1';
						cnt           <= (OTHERS => '0');
					
					ELSIF ( SyncIn = SYNC_DATA ) OR ( SyncIn = SYNC_DATA2 ) 
					OR ( SyncIn = SYNC_DATA3 ) OR ( SyncIn = SYNC_DATA4 ) THEN

						SyncType      <= SYNC_TYPE_DATA;
						SyncTypeReady <= '1';
						cnt           <= ( OTHERS => '0' );
						
					ELSE
						
						SyncTypeReady <= '0';
						
					END IF;
				
				END IF;

			ELSE
			
				cnt      <= ( OTHERS => '0' );
				SyncType <= ( OTHERS => '0' );
				SyncIn   <= ( OTHERS => '0' );
				
			END IF;
			
		END IF;
	END PROCESS;


	RxClk <= STD_LOGIC( cnt( 1 ) );


	ShiftCounter: PROCESS( Reception, RxClk, SyncTypeReady )
	BEGIN

		IF Reception = '0' THEN
			
			ShiftCnt   <= ( OTHERS => '0' );
		
		ELSE
			IF SyncTypeReady = '1' THEN
				
				ShiftCnt <= ( OTHERS => '0' );
			
			ELSIF FALLING_EDGE( RxClk ) THEN
					
				IF ( ShiftCnt < ( WordLenBits + 4 ) * 4 ) THEN
					ShiftCnt <= ShiftCnt + x"01";
				ELSE
					ShiftCnt <= ( OTHERS => '0' );
				END IF;
			
			END IF;
					
		END IF;
	END PROCESS;





	WORD_ShiftIn: PROCESS( Enable, RxClk, SyncTypeReady )
	BEGIN
		IF Enable = '0' OR SyncTypeReady = '1' THEN
			
			BitCnt <= ( OTHERS => '0' );
			CalcParity <= '1';
			TransmitDelay <= '0';
						
		ELSIF RISING_EDGE ( RxClk ) THEN
			
			IF Reception = '1' THEN	
				
				IF ( ( SyncType /= "00" ) AND ( ShiftCnt( 1 DOWNTO 0 ) = "00" ) ) THEN
					
					IF ( BitCnt < ( WordLenBits ) ) THEN
		
						IF ShiftInBuf( 1 DOWNTO 0 ) = "01" THEN
							
							BitCnt <= BitCnt + x"01";
							WordData <= WordData( WordData'LEFT - 1 DOWNTO 0 ) & '0';
							
							IF BitCnt = ( WordLenBits - 1 ) THEN
								RxParity <= '0';
							END IF;
						
						ELSIF ShiftInBuf( 1 DOWNTO 0 ) = "10" THEN
							
							BitCnt <= BitCnt + x"01";
							WordData <= WordData( WordData'LEFT - 1 DOWNTO 0 ) & '1';
							CalcParity <= NOT CalcParity;	-- Parity calculation
							
						END IF;
						
						IF BitCnt = ( WordLenBits - 2 ) THEN
							TransmitDelay <= Transmit;
						END IF;
						
					ELSIF BitCnt = WordLenBits  THEN  -- Parity reception		
						BitCnt <= BitCnt + x"01";
						IF ShiftInBuf( 1 DOWNTO 0 ) = "10" THEN
							RxParity <= '1';
						ELSIF ShiftInBuf( 1 DOWNTO 0 ) = "01" THEN
							RxParity <= '0';
						END IF;
					ELSE
						BitCnt <= ( OTHERS => '0' );
					END IF;
					
				END IF;
		
			ELSE
				WordData <= ( OTHERS => '0' );	
				CalcParity <= '1';
			END IF;
		END IF;	
	END PROCESS;
		
			
		
	PROCESS( Enable, RxClk )
	BEGIN  
		IF Enable = '0' THEN
			ShiftInBuf <= ( OTHERS => '0' );
						
		ELSIF RISING_EDGE( RxClk ) THEN 
			
			IF ( Reception = '1' ) AND ( ShiftCnt( 0 ) = '1' ) THEN	
				IF SyncType /= "00" THEN
					ShiftInBuf <= ShiftInBuf( ( ShiftInBuf'LEFT - 1 ) DOWNTO 0 ) & InA; 
				ELSE
					ShiftInBuf <= ( OTHERS => '0' );
				END IF;
			END IF;
			
		END IF;
		
	END PROCESS;

END RTL;
