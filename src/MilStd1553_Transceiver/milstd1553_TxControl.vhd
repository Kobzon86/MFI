--  MIL-STD-1553 TXControl v0.2


LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

USE work.milstd_1553_pkg.ALL;


ENTITY milstd1553_TxControl IS
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
		TxComplete : IN STD_LOGIC;
		BuffBusy  : IN STD_LOGIC
		
	
	);

END milstd1553_TxControl;


ARCHITECTURE RTL OF milstd1553_TxControl IS


	TYPE StateType IS ( IDLE, TX_DATA, TX_ANSWER, RX_MANAGE, TEST, ADDR_CALC, RD_REQ, RD_WAIT, TST_WAIT );
	
	CONSTANT InitRAM_Zero  : UNSIGNED( AddrWidth DOWNTO 0 ) := ( OTHERS => '0' );
	CONSTANT AvalonACKWait : UNSIGNED( 3 DOWNTO 0 ) := x"F";--x"E"; -- Wait cycle number for Load signal
	CONSTANT DATA          : STD_LOGIC := '1';
	CONSTANT COM           : STD_LOGIC := '0';
	
	SIGNAL NextState : StateType := IDLE;
	SIGNAL PresState : StateType := IDLE;
	
	SIGNAL StartAddr   : UNSIGNED( AddrWidth DOWNTO 0 ) := ( OTHERS => '0' ); -- data sector start address
	SIGNAL TstStartAddr   : UNSIGNED( AddrWidth DOWNTO 0 ) := ( OTHERS => '0' ); -- data sector start address
	
	SIGNAL IntStateReg : STD_LOGIC_VECTOR(  7 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL AnswerWord  : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL DataWord    : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RAMData     : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TxStarted   : STD_LOGIC := '0';
	SIGNAL TxSubAddr   : STD_LOGIC_VECTOR(  4 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL WordCnt     : UNSIGNED( 4 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TxWordCnt   : UNSIGNED( 5 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL ReadyTmp    : STD_LOGIC := '0';
	SIGNAL RdEnTmp     : STD_LOGIC := '0';	
	SIGNAL StartLatch  : STD_LOGIC := '0';
	SIGNAL AnsType     : STD_LOGIC := '0';
	SIGNAL AnswerReady : STD_LOGIC := '0';
	SIGNAL Transmit    : STD_LOGIC := '0';
	
	SIGNAL ManageIn    : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL ManageTmp   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL Data_ComIn  : STD_LOGIC := '0';
	SIGNAL Data_ComTmp : STD_LOGIC := '0';
	SIGNAL RxChanIn    : STD_LOGIC := '0';
	SIGNAL RxChantmp   : STD_LOGIC := '0';
	SIGNAL ComReadyIn  : STD_LOGIC := '0';
	SIGNAL ComReadyStart : STD_LOGIC := '0';
	SIGNAL TxChan      : STD_LOGIC := '0';
	SIGNAL Broad       : STD_LOGIC := '0';
	SIGNAL ByteNum     : UNSIGNED( 4 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL TxPackLen   : UNSIGNED( 5 DOWNTO 0 ) := "000100";
	SIGNAL Busy        : STD_LOGIC := '0';

	SIGNAL TxOVF, TxCOMPL, TxEMPTY : STD_LOGIC := '0';
	SIGNAL NextDataReady : STD_LOGIC := '0';
	SIGNAL WaitTimer     : UNSIGNED( 3 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TxReq         : STD_LOGIC := '0';
	SIGNAL DatAnswReady  : STD_LOGIC := '0';
	SIGNAL LoadStretched : STD_LOGIC := '0';
	SIGNAL LS1           : STD_LOGIC := '1';
	SIGNAL RAM_RdBusy    : STD_LOGIC := '0';
	SIGNAL AddrTmp       : STD_LOGIC_VECTOR( ( AddrWidth ) DOWNTO 0 ) := ( OTHERS => '0' );	
	SIGNAL TestInProgress : STD_LOGIC := '0';
	SIGNAL TestEnLOC     : STD_LOGIC := '0';
	SIGNAL TxReseted     : STD_LOGIC := '0';
	
	
BEGIN



--	IntStateReg( 7 ) <= Enable;
--	IntStateReg( 6 ) <= TxOVF;
--	IntStateReg( 5 ) <= TxCOMPL;
--	IntStateReg( 4 ) <= TxEMPTY;
--	IntStateReg( 3 DOWNTO 2 ) <= ( OTHERS => '0' );  -- reserved bits
--	IntStateReg( 1 ) <= RAM_RdBusy OR Transmit;
--	IntStateReg( 0 ) <= '0';  -- reserved bit 
	
	
	
	
	
	StateSwitcher: PROCESS( Enable, Clk )
	VARIABLE BusyTimer : INTEGER RANGE 0 TO 31 := 0;
	BEGIN
		IF Enable = '0' THEN
			PresState <= IDLE;
			StateReg  <= ( OTHERS => '0' );
			Busy      <= '0';
			
		ELSIF RISING_EDGE( Clk ) THEN
			PresState <= NextState;	
			StateReg  <= IntStateReg;
			
			IntStateReg( 7 ) <= Enable;
			IntStateReg( 6 ) <= TxOVF;
			IntStateReg( 5 ) <= TxCOMPL;
			IntStateReg( 4 ) <= TxEMPTY;
			IntStateReg( 3 DOWNTO 2 ) <= ( OTHERS => '0' );  -- reserved bits
			IntStateReg( 1 ) <= RAM_RdBusy OR Transmit;
			IntStateReg( 0 ) <= '0';  -- reserved bit 
			
			------- BusyTimer --------------
			IF BuffBusy = '1' THEN 
				BusyTimer := 0;
				Busy <= '1';
			ELSE
				IF BusyTimer < 7 THEN  
					BusyTimer := BusyTimer + 1;
					Busy <= '1';
				ELSE
					Busy <= '0';
				END IF;
			
			END IF;
			
		END IF;
	END PROCESS;
	

	
	
	ManageREG: PROCESS( Enable, Clk )
	BEGIN
		IF Enable = '0' THEN
			ComReadyStart <= '0';
			ManageIn <= ( OTHERS => '0' );
			ComReadyIn <= '0';
			Data_ComIn <= '0';
			RxChanIn   <= '0';
			
		ELSIF RISING_EDGE( Clk ) THEN
			ComReadyStart <= ComReady;
			Data_ComTmp <= Data_Com;
			RxChanTmp   <= RxChan;
			ManageTmp   <= Manage;
			
			ComReadyIn <= ComReadyStart;
			Data_ComIn <= Data_ComTmp;
			RxChanIn   <= RxChanTmp;
			ManageIn   <= ManageTmp;
			
		END IF;
	END PROCESS;
	
	
	
	
	
	
	StateHandler: PROCESS( Enable, Clk )
	VARIABLE Rdata        : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' ); 
	CONSTANT TestPause_us : INTEGER := 30;
	VARIABLE cnt_30us     : INTEGER RANGE 0 TO ( 16 * TestPause_us ) := 0;
	BEGIN
		IF Enable = '0' THEN
	
			NextState  <= IDLE;
			WordCnt    <= ( OTHERS => '0' );
			cnt_30us   := 0;
			TestEnLOC  <= '0';
			RdEn       <= '0';
			FIFO_WrEn0 <= '0';
			FIFO_WrEn1 <= '0';
			Transmit   <= '0';
			TxCOMPL    <= '0';
			Broad      <= '0';
			
		ELSIF FALLING_EDGE( Clk ) THEN
			CASE PresState IS
			
			WHEN IDLE =>
				RdEn       <= '0';
				FIFO_WrEn0 <= '0';
				FIFO_WrEn1 <= '0';
				StartLatch <= '0';
				ByteNum    <= ( OTHERS => '0' );
				
				IF ComReadyStart = '1' THEN
					NextState <= RX_MANAGE;
				ELSIF TestEn = '1' THEN
					NextState <= TEST;
				END IF;
			


			WHEN RX_MANAGE =>
				IF TxStart = '1' THEN
					StartLatch <= '1';
				END IF;
				IF ComReadyIn = '1' THEN
					IF ( WordCnt < "00100" )  THEN
						WordCnt <= WordCnt + "00001";
						ByteNum <= ByteNum + TO_UNSIGNED( 1, 5 );
						
					END IF;	
					
					
					IF WordCnt = "00000" THEN
						
						AnswerWord( 15 DOWNTO 8 ) <= ManageIn;
						
					ELSIF WordCnt = "00001" THEN 
						AnsType <= Data_ComIn;
						AnswerWord( 7 DOWNTO 0 ) <= ManageIn;
						Broad <= ManageIn(4);
						TxChan <= RxChan;
					
					ELSIF WordCnt = "00010" THEN 
						IF Data_ComIn = '0' THEN
							DataWord( 15 DOWNTO 8 ) <= ManageIn;
						ELSE
							TxSubAddr <= ManageIn( 4 DOWNTO 0 );
						ENd IF;
							
					ELSIF WordCnt = "00011" THEN 
						IF Data_ComIn = '0' THEN 
							DataWord( 7 DOWNTO 0 ) <= ManageIn;
						ELSE
							IF ManageIn( 4 DOWNTO 0 ) = "00000" THEN
								TxPackLen <= "100000";
							ELSE
								TxPackLen <= UNSIGNED( '0' & ManageIn( 4 DOWNTO 0 ) );
							END IF;
						END IF;

					END IF; 
					
				
				ELSE  
					IF Broad = '0' THEN
						IF ( StartLatch = '1' ) AND ( Busy = '0' ) THEN
							WordCnt <= ( OTHERS => '0' );
							NextState <= TX_ANSWER;
						END IF;
					ELSE
						WordCnt <= ( OTHERS => '0' );
						NextState <= IDLE;
					END IF;
				END IF;
				
				
			
			WHEN TEST =>	-- CHECK in MODELSIM!!
				FIFO_WrEn0 <= '0';
				FIFO_WrEn1 <= '0';
				
				SendWordsNum <= ( OTHERS => '0' );
				AnswerWord( 15 DOWNTO 11 ) <= TstNodeAddr; 
				AnswerWord( 10 )           <= '0';
				AnswerWord( 9 DOWNTO 5 )   <= TstSubAddr;
				AnswerWord( 4 DOWNTO 0 )   <= TstWordNum;  --"11111";
				--TstStartAddr <= ( TX_BUFF_START + ( '0' & UNSIGNED( TstSubAddr ) & "00000" ) );
				--TstStartAddr <= ( "000" & UNSIGNED( TstSubAddr ) & "00000" );
				TstStartAddr <= ( OTHERS => '0' );
				TxPackLen    <= UNSIGNED( '0' & TstWordNum ); --"011111"; --"000000"; -- no data words transmission, transmit only answer word 
				TxWordCnt    <= ( OTHERS => '0' );
				AnsType      <= DATA;
				TxChan       <= TstTxChan;
				ByteNum      <= TO_UNSIGNED( 4, 5 );
				
				IF TxStart = '1' THEN
					StartLatch <= '1';
				END IF;
				
				IF TestEn = '0' THEN
					NextState <= IDLE;
				ELSE
					IF ( StartLatch = '1' ) AND ( Busy = '0' ) THEN
						NextState <= TX_ANSWER;
					END IF;
				END IF;
			
			
				
			
			WHEN TX_ANSWER =>		
				
				StartLatch <= '0';
				WordCnt <= WordCnt + "00001";
				IF ( FIFO_Full0 OR FIFO_Full1 ) = '1' THEN
					FIFO_WrEn0 <= '0';
					FIFO_WrEn1 <= '0';
					WordCnt    <= ( OTHERS => '0' );
					IF TestEn = '0' THEN
						NextState <= IDLE;
					ELSE
						NextState <= TEST;
					END IF;
					
				ELSIF WordCnt < "00010" THEN
					IF WordCnt = "00000" THEN
						
						FIFO_WrEn0 <= NOT TxChan;
						FIFO_WrEn1 <= TxChan;
						
						DataOut   <= AnswerWord;
						WordStat  <= SYNC_TYPE_COMM;
						
					ELSE
					
						IF AnsType = COM THEN	
							IF ByteNum = TO_UNSIGNED( 4, 5 ) THEN
								DataOut   <= DataWord;
								WordStat  <= SYNC_TYPE_DATA;
							ELSE
								FIFO_WrEn0 <= '0';
								FIFO_WrEn1 <= '0';
								ByteNum    <= ( OTHERS => '0' );
								WordCnt    <= ( OTHERS => '0' );
								NextState  <= IDLE;
							END IF;	
						
						ELSE
							IF ByteNum = TO_UNSIGNED( 2, 5 ) THEN -- AnswerWord for RxRequest
								FIFO_WrEn0 <= '0';
								FIFO_WrEn1 <= '0';
								ByteNum    <= ( OTHERS => '0' );
								WordCnt    <= ( OTHERS => '0' );
								NextState  <= IDLE;
							ELSIF ByteNum = TO_UNSIGNED( 4, 5 ) THEN -- Data Tx for TxRequest
							--	StartAddr <= ( TX_BUFF_START + ( '0' & UNSIGNED( TxSubAddr ) & "00000" ) );
								StartAddr <= ( "000" & UNSIGNED( TxSubAddr ) & "00000" );
								FIFO_WrEn0 <= '0';
								FIFO_WrEn1 <= '0';
								ByteNum    <= ( OTHERS => '0' );
								WordCnt    <= ( OTHERS => '0' );			
								NextState  <=  ADDR_CALC; --RD_REQ;
							
							END IF;
						END IF;
					END IF;
				ELSE
					FIFO_WrEn0 <= '0';
					FIFO_WrEn1 <= '0';
					WordCnt    <= ( OTHERS => '0' );
					NextState  <= IDLE;	
				END IF;
			
			
			
			WHEN ADDR_CALC =>
				FIFO_WrEn0 <= '0';
				FIFO_WrEn1 <= '0';
				
				IF TestEn = '0' THEN
					AddrTmp <= STD_LOGIC_VECTOR( StartAddr + TxWordCnt );	
				ELSE
					AddrTmp <= STD_LOGIC_VECTOR( TstStartAddr + TxWordCnt );
				END IF;
					
				NextState <= RD_REQ;
			
			
			WHEN RD_REQ => -- TxWordCnt calculate in TX_DATA
				FIFO_WrEn0 <= '0';
				FIFO_WrEn1 <= '0';
				RdEn       <= '1';
				IF TestEn = '0' THEN
					Addr <= AddrTmp( StartAddr'LEFT DOWNTO 1 );
				ELSE
					Addr <= AddrTmp( TstStartAddr'LEFT DOWNTO 1 );	
				END IF;
			
				IF AddrTmp(0) = '0' THEN
					ByteEn <= "1100";
				ELSE
					ByteEn <= "0011";
				END IF;	
			
				WaitTimer <= AvalonACKWait;
				NextState <= RD_WAIT;
				
			
			
			
			WHEN RD_WAIT =>
				
				RdEn <= '0';
				
				IF Load = '1' THEN
					
					IF AddrTmp(0) = '1' THEN
						Rdata := WordIn( WordIn'LEFT DOWNTO ( WordIn'LEFT - 15 ) );
					ELSE
						Rdata := WordIn( ( WordIn'LEFT - 16 ) DOWNTO ( WordIn'LEFT - 31 ) );
					END IF;
					
					RAMData       <= Rdata;
					NextDataReady <= '1';
					NextState     <= TX_DATA;
				
				ELSE
					
					IF WaitTimer = x"0" THEN
						
						Transmit <= '0';
						TxWordCnt <= ( OTHERS => '0' );
						NextState <= IDLE;
						
					ELSE
						
						WaitTimer <= WaitTimer - x"1";
						
						IF ComReadyIn = '1' AND Transmit = '0' THEN
							NextState <= RX_MANAGE;
						END IF;
					
					END IF;
				
				END IF;
			
			
			
			
			
			WHEN TX_DATA =>
				IF ( TxWordCnt < ( TxPackLen  ) ) AND ( ( FIFO_Full0 OR FIFO_Full1 ) = '0' ) THEN
					TxWordCnt     <= TxWordCnt + "000001";
					FIFO_WrEn0    <= NOT TxChan;
					FIFO_WrEn1    <= TxChan;
					TxCOMPL       <= '0';
					Transmit      <= '1';
					WordStat      <= SYNC_TYPE_DATA;
					DataOut       <= RAMData;--WordIn;
					
					IF TxWordCnt < ( TxPackLen - 1 ) THEN
						NextState <= ADDR_CALC; --RD_REQ;
					END IF;	
				
				ELSE
					SendWordsNum <= STD_LOGIC_VECTOR( TxPackLen );
					TxCOMPL      <= '1';
					Transmit     <= '0';
					TxWordCnt    <= ( OTHERS => '0' );
					FIFO_WrEn0    <= '0';
					FIFO_WrEn1    <= '0';
					IF TestEn = '0' THEN
						NextState <= IDLE;
					ELSE
						--Nextstate <= TEST;
						Nextstate <= TST_WAIT;
					END IF;
				END IF;
			
			
			WHEN TST_WAIT =>
				IF TxComplete = '1' THEN
					IF TestEn = '1' THEN
						NextState <= TEST;
					ELSE
						NextState <= IDLE;
					END IF;
				END IF;
			
			
			WHEN OTHERS =>
				NextState <= IDLE;
				
			END CASE;		
		END IF;
	END PROCESS;
	



END RTL;
