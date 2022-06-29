-- ARINC 429  Receiver v.06
-- Synchronization by input data bits
-- Added output FIFO
-- Output 16-bit
-- Added Error output
-- Added TxError output


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.ALL;

ENTITY a429_RxPhy IS
	
	GENERIC(
		DataWidth    : INTEGER := 32;
		StopWidth    : INTEGER := 4;
		Pack_WN      : INTEGER := 16;
		UsedWidth    : INTEGER := 4  -- 2 ** USedWidth = Pack_WN
	);
	
	PORT(
		Enable      : IN  STD_LOGIC := '1';
		ClockIn     : IN  STD_LOGIC;
		ClockMux    : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		InputA      : IN  STD_LOGIC := '0';
		InputB      : IN  STD_LOGIC := '0';
		TxCntrl     : IN  STD_LOGIC;   -- if = '1' set receiver in Tx_Checker mode 
		InReg       : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		RxInvert    : IN  STD_LOGIC;   -- if = '1' then invert received bits
		RdClk       : IN  STD_LOGIC;
		RdReq       : IN  STD_LOGIC;
		ParOFF      : IN  STD_LOGIC;
		nEmpty      : OUT STD_LOGIC;		
		DataOut     : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		------ not buffered output signals (RxPhy STATE) -----
		ParErr      : OUT STD_LOGIC;
		TxErr       : OUT STD_LOGIC;
		RxFlag      : OUT STD_LOGIC
	);
	
END a429_RxPhy;

ARCHITECTURE RTL OF a429_RxPhy IS

	--COMPONENT FIFO IS
	--GENERIC(
		--DataWidth   : INTEGER := 8;
		--UsedWidth   : INTEGER := 4;
		--WordNum     : INTEGER := 16
	--);
	--PORT(
		--aclr        : IN  STD_LOGIC  := '0';
		--data        : IN  STD_LOGIC_VECTOR (( DataWidth - 1 ) DOWNTO 0);
		--rdclk       : IN  STD_LOGIC;
		--rdreq       : IN  STD_LOGIC;
		--wrclk       : IN  STD_LOGIC;
		--wrreq       : IN  STD_LOGIC;
		--q		    : OUT STD_LOGIC_VECTOR (( DataWidth - 1 ) DOWNTO 0);
		--rdempty     : OUT STD_LOGIC;
		--wrfull      : OUT STD_LOGIC 
	--);	
	--END COMPONENT;


	
	CONSTANT bitsCounterSize : INTEGER := DataWidth;
	CONSTANT PulseWidth      : INTEGER := 4;
	CONSTANT PulseDelay      : INTEGER := PulseWidth - 3; 
	CONSTANT timeoutCounterSize : INTEGER := ( ( StopWidth * PulseWidth ) - 1 );

	SIGNAL Clock          : STD_LOGIC;
	SIGNAL Timeout        : STD_LOGIC := '1';
	SIGNAL Buff           : STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL DataReady      : STD_LOGIC := '0';	
	SIGNAL bitsCounter    : INTEGER RANGE 0 TO ( bitsCounterSize + 1 );
	SIGNAL LatchClock     : STD_LOGIC := '0';	
	SIGNAL TimeShift      : STD_LOGIC_VECTOR(1 DOWNTO 0);
	
	--SIGNAL ClkCnt         : INTEGER RANGE 0 TO 15 := 0;
	SIGNAL ClkCnt         : UNSIGNED( 3 DOWNTO 0 );
	
	SIGNAL PulseShift     : STD_LOGIC_VECTOR( 5 DOWNTO 0 ) := ( OTHERS => '0' );  
	SIGNAL DataClk        : STD_LOGIC;
	SIGNAL timeoutCounter : INTEGER RANGE 0 TO timeoutCounterSize;
	SIGNAL ParBitCalc     : STD_LOGIC := '1';
	SIGNAL ParBitOk       : STD_LOGIC := '0'; 
	SIGNAL ParBitRx       : STD_LOGIC := '0'; 
	
	SIGNAL RxError       : STD_LOGIC := '0';
	SIGNAL c0, c1, c2    : STD_LOGIC;
	SIGNAL D0, D1        : STD_LOGIC_VECTOR( DataWidth - 1 DOWNTO 0 );
	SIGNAL Ready         : STD_LOGIC := '0';
	
	SIGNAL F_aclr_IN     : STD_LOGIC := '0';
	SIGNAL F_data_IN     : STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0) := ( OTHERS => '0' );
	SIGNAL F_rdclk_IN    : STD_LOGIC := '0';
	SIGNAL F_rdreq_IN    : STD_LOGIC := '0';
	SIGNAL F_wrclk_IN    : STD_LOGIC := '0';
	SIGNAL F_wrreq_IN    : STD_LOGIC := '0';
	SIGNAL F_q_OUT       : STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0) := ( OTHERS => '0' );
	SIGNAL F_rdempty_OUT : STD_LOGIC := '0';
	SIGNAL F_wrfull_OUT  : STD_LOGIC := '0'; 
	SIGNAL RxData	     : STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL InAt       : STD_LOGIC := '0';
	SIGNAL InBt       : STD_LOGIC := '0';
	
	SIGNAL InAt_n       : STD_LOGIC := '0';
	SIGNAL InBt_n       : STD_LOGIC := '0';
	
	SIGNAL InA_tmp    : STD_LOGIC := '0';
	SIGNAL InB_tmp    : STD_LOGIC := '0';
	SIGNAL InA        : STD_LOGIC := '0';
	SIGNAL InB        : STD_LOGIC := '0';
	
	SIGNAL LatchPulse : STD_LOGIC;
	SIGNAL lp1, lp2   : STD_LOGIC;
	SIGNAL ClockPulse : STD_LOGIC;
	SIGNAL cp1, cp2   : STD_LOGIC;

	
BEGIN
	
	
--	rxfifo: FIFO 
--	GENERIC MAP(
--		DataWidth   => DataWidth,
--		UsedWidth   => UsedWidth,
--		WordNum     => Pack_WN
--	)
--	PORT MAP(
--		aclr        => F_aclr_IN,
--		data        => F_data_IN,
--		rdclk       => F_rdclk_IN,
--		rdreq       => F_rdreq_IN,
--		wrclk       => F_wrclk_IN,
--		wrreq       => F_wrreq_IN,
--		q		    => F_q_OUT,
--		rdempty     => F_rdempty_OUT,
--		wrfull      => F_wrfull_OUT
--	);
--	
	
	------------- FIFO Connections ------------------
--	F_rdclk_IN <= RdClk;
--	F_wrclk_IN <= ClockIn;
--	F_data_IN  <= RxData;
--	F_aclr_IN  <= ( NOT Enable );
--	-- F_wrreq_IN connected in ParityChecker PROCESS
--	
--	nEmpty     <= ( NOT F_rdempty_OUT );
--	DataOut    <= F_q_OUT;
--	F_rdreq_IN <= RdReq;


		--------- Input tripple sinchronizer -------------
	InputReg: PROCESS( Enable, ClockIn )
	BEGIN
		IF Enable = '0' THEN
			InAt    <= '0';
			InBt    <= '0';
			InA_tmp <= '0';
			InB_tmp <= '0';
			InA     <= '0';
			InB     <= '0';
			DataClk <= '0';
		ELSIF FALLING_EDGE( ClockIn ) THEN
			InAt    <= InputA;
			InBt    <= InputB;
			InA_tmp <= InAt;
			InB_tmp <= InBt;
			InA     <= InA_tmp;
			InB     <= InB_tmp;
			DataClk <= InAt XOR InBt;
		END IF;
	
	END PROCESS;




	PROCESS( Enable, ClockIn )
	BEGIN
		IF Enable = '0' THEN
			Clock  <= '0';
			ClkCnt <= ( OTHERS => '0' );
			LatchClock <= '0';
		ELSIF RISING_EDGE( ClockIn ) THEN
			IF ( ClkCnt < x"F" ) THEN
				ClkCnt <= ClkCnt + x"1";
			ELSE
				ClkCnt <= ( OTHERS => '0' );	
			END IF;
			
			CASE ClockMux IS
				WHEN "01"   => Clock <= STD_LOGIC_VECTOR(ClkCnt)(3); -- ClkIn / 16
				WHEN "10"   => Clock <= STD_LOGIC_VECTOR(ClkCnt)(1); -- ClkIn / 4
				WHEN "11"   => Clock <= STD_LOGIC_VECTOR(ClkCnt)(0); -- ClkIn / 2 = RxFreq * 8
				WHEN OTHERS => Clock <= '0';
			END CASE;
			
			LatchClock <= PulseShift( PulseDelay );	

			lp1 <= LatchClock;
			lp2 <= lp1;
			LatchPulse <= lp1 AND ( NOT lp2 );

			cp1 <= Clock;
			cp2 <= cp1;
			ClockPulse <= cp1 AND ( NOT cp2 );
				
		END IF;
	END PROCESS;



	PulseShiftGen: PROCESS( Enable, ClockIn )
	BEGIN
		IF Enable = '0' THEN
			RxFlag <= '0';
			PulseShift <= ( OTHERS => '0' );
		ELSIF RISING_EDGE( ClockIn ) THEN
			IF ClockPulse = '1' THEN
				PulseShift <= PulseShift( ( PulseShift'LEFT - 1 )  DOWNTO 0 ) & DataClk;
				IF PulseShift /= "000000" THEN
					RxFlag <= '1';
				ELSE
					RxFlag <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS;


	
	
	TimeOutCnt: PROCESS( Enable, ClockIn )
	BEGIN
		IF( Enable = '0' ) THEN
			timeoutCounter <= 0;
			Timeout        <= '1';
		ELSIF RISING_EDGE( ClockIn ) THEN
			IF ( timeoutCounter < timeoutCounterSize ) THEN
				Timeout <= '0';
			ELSE
				Timeout <= '1';
			END IF;
			IF ClockPulse = '1' THEN
				IF( DataClk  = '1' ) THEN
					timeoutCounter <= 0;
				ELSE
					IF( timeoutCounter < timeoutCounterSize ) THEN
						timeoutCounter <= ( timeoutCounter + 1 );
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
	

--	Timeout <= '0' WHEN ( timeoutCounter < timeoutCounterSize ) ELSE '1';
	
	
	DataLatch: PROCESS( Enable, ClockIn )	
	BEGIN
		
		IF Enable = '0' THEN -- <- OR Timeout = '1'  

			bitsCounter <= 0;
			ParBitCalc <= '1';
		
		ELSIF RISING_EDGE( ClockIn ) THEN
			IF Timeout = '1' THEN
				bitsCounter <= 0;
				ParBitCalc  <= '1';
			ELSIF LatchPulse = '1' THEN
				bitsCounter <= (bitsCounter + 1);
				IF( bitsCounter <= bitsCounterSize ) THEN
					
	--				IF( InputA = '1' ) THEN
					IF( InA = '1' ) THEN
						
						Buff( ( DataWidth - 1 ) DOWNTO 0 ) <= ( NOT RxInvert ) & Buff( ( DataWidth - 1 ) DOWNTO 1 );
						
					ELSE
			
						Buff( ( DataWidth - 1 ) DOWNTO 0 ) <= ( RxInvert ) & Buff( ( DataWidth - 1 ) DOWNTO 1 );
						
						IF bitsCounter < ( bitsCounterSize - 1 ) THEN
							
							ParBitCalc <= NOT ParBitCalc;  -- parity bit calculation
						
						END IF;
					
					END IF;
					
					
					IF ( bitsCounter = bitsCounterSize - 1 ) THEN
						
						ParBitRx <= InB;
						
					END IF;
					
				END IF;				
			END IF;
		
		END IF;
	
	END PROCESS;
	



	ParityChecker: PROCESS( Enable, ClockIn )
	BEGIN
		IF Enable = '0' THEN
			
			ParBitOk <= '0';			
			Ready    <= '0';	
			TxErr    <= '0';
--			ParErr   <= '0';
			
		ELSIF FALLING_EDGE( ClockIn ) THEN
	
			IF ( bitsCounter = bitsCounterSize ) THEN
				
				IF TxCntrl = '1' THEN  -- in Tx_Checker mode
					IF Buff = InReg THEN
						TxErr <= '0';
					ELSE
						TxErr <= '1';
					END IF;
				ELSE 
					-- parity bit check
					TxErr  <= '0';
					
--					IF ParOFF = '0' THEN 
--						ParErr <= ( ParBitCalc XOR ParBitRx ); -- AND ( NOT ParOFF );
--						--Ready  <= ( NOT ( ParBitCalc XOR ParBitRx ) );
--					ELSE
--						ParErr <= '0';
--						--Ready  <= '1';
--					END IF;
					Ready  <= '1';
					RxData <= Buff;
				END IF;
				
			ELSE
				ParBitOk <= '0';			
				Ready    <= '0';	
				TxErr    <= '0';
				--ParErr   <= '0';
			END IF;
		END IF;
	
	END PROCESS;



	OutDataGen: PROCESS( Enable, RdClk )
	BEGIN
		IF Enable = '0' THEN
			c0 <= '0';
			c1 <= '0';
			c2 <= '0';
			nEmpty <= '0';
			DataOut <= ( OTHERS => '0' );
			D0 <= ( OTHERS => '0' );
			D1 <= ( OTHERS => '0' );
			ParErr   <= '0';
		ELSE
		
			IF FALLING_EDGE( RdClk ) THEN
			    c1 <= Ready;
			    c2 <= c1;
			    D0 <= RxData;
			    F_wrreq_IN <= c1 AND ( NOT c2 ); -- single cycle width pulse
			    
				 -------------------------------------------
				IF Ready = '1' THEN
					IF ParOFF = '0' THEN 
						ParErr <= ( ParBitCalc XOR ParBitRx ); -- AND ( NOT ParOFF );
						--Ready  <= ( NOT ( ParBitCalc XOR ParBitRx ) );
					END IF;
				ELSE
					ParErr   <= '0';
				END IF;
			   --------------------------------------------- 
				 
				IF F_wrreq_IN = '1' THEN
					nEmpty  <= '1';
					DataOut <= D0; --RxData;
				ELSIF RdReq = '1' THEN
					nEmpty <= '0';
				END IF;
			   	
			    
		--	    IF RdReq = '0' THEN
		--			IF F_wrreq_IN = '1' THEN
		--				nEmpty  <= '1';
		--				DataOut <= D0; --RxData;
		--			END IF;
		--		ELSE
		--			nEmpty <= '0';
		--		END IF;
				
				
		--	ELSIF RISING_EDGE( RdClk ) THEN
		--		IF RdReq = '0' THEN
		--			IF F_wrreq_IN = '1' THEN
		--				nEmpty  <= '1';
		--				DataOut <= RxData;
		--			END IF;
		--		ELSE
		--			nEmpty <= '0';
		--		END IF;
			END IF;
		
		END IF;
	
	
	END PROCESS;



		
END RTL;
