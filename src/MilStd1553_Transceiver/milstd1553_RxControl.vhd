-- MILSTD-1553 RxControl v02
-- for RAM with Avalon-MM interface
-- work with RxPhy FIFO
-- Double buffering eliminated


LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

USE work.milstd_1553_pkg.ALL;

ENTITY milstd1553_RxControl IS
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
		
		WaitReq    : IN  STD_LOGIC; -- NOT USED
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
	
END milstd1553_RxControl;



ARCHITECTURE RTL OF milstd1553_RxControl IS
	
	TYPE StateType IS ( IDLE, RD_EN, RD_WAIT, COM_WORD, DAT_MODE, WR_WRD, ANS_GEN, ANS_SEND, FORM38, COM_MODE, COM_DW, WAIT_MODE, REQ_MODE );
	TYPE LastAddrArrayType IS ARRAY ( 31 DOWNTO 0 ) OF UNSIGNED( AddrWidth DOWNTO 0 );
	
--	CONSTANT RAM_LEN       : UNSIGNED( AddrWidth DOWNTO 0 ) := TO_UNSIGNED( 4095, AddrWidth + 1 ); --( OTHERS => '0' ); -- FIFO Length in 16 bit words = 4096 
--	CONSTANT RX_SECTOR_LEN : UNSIGNED( AddrWidth DOWNTO 0 ) := TO_UNSIGNED(   64, AddrWidth + 1 ); -- SECTOR LEN for SubAddress
	
	CONSTANT TimeDelay_us : UNSIGNED( 15 DOWNTO 0 ) := x"0004";  -- pause MILSTD_1553 BUS between packets in us
	CONSTANT InitRamZero  : UNSIGNED( AddrWidth DOWNTO 0 )         := ( OTHERS => '0' );

	CONSTANT COM          : STD_LOGIC := '0';
	CONSTANT DATA         : STD_LOGIC := '1';
	CONSTANT Rx0_nEmpty   : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
	CONSTANT Rx1_nEmpty   : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "10";
	CONSTANT RxAll_Empty  : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
	
	
	SIGNAL IntStateReg  : STD_LOGIC_VECTOR(  7 DOWNTO 0 ) := ( OTHERS => '0' );  -- Internal state register
	SIGNAL TxDataWord   : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );  -- Output data from TxPhy, for Tx checking
	SIGNAL RxWord       : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );  -- receiverd word from RxPhy
	SIGNAL RxWordStat   : STD_LOGIC_VECTOR(  1 DOWNTO 0 ) := ( OTHERS => '0' );	 -- Receiver word state^ COMMAND, DATA
	SIGNAL FromTransmit : STD_LOGIC                       := '0';
	SIGNAL AnswerWord   : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );  -- Answer Word for MILSTD-1553
	
	SIGNAL AnswerData   : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL LastCommand  : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );  -- Last Received command word from MILSTD-1553
	SIGNAL RxCom_Len    : STD_LOGIC_VECTOR(  4 DOWNTO 0 ) := ( OTHERS => '0' );  -- received command code from MILSTD-1553
	SIGNAL RX_TR        : STD_LOGIC                       := '0';                -- received T-R bit from MILSTD-1553
	SIGNAL SubAddr      : STD_LOGIC_VECTOR(  4 DOWNTO 0 ) := ( OTHERS => '0' );  -- received subaddress or mode from MILSTD-1553
	SIGNAL StartAddr    : STD_LOGIC_VECTOR( AddrWidth DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RxAddr       : STD_LOGIC_VECTOR(  4 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL WR_HALF_SEL  : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '1' );   -- Rx data write half sector selector
	SIGNAL WR_HALF_SEL_BROAD  : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );   -- Rx data write half sector selector

	SIGNAL NextState    : StateType := IDLE;	
	SIGNAL PresState    : StateType := IDLE;	
	SIGNAL DL1, DL2, DL3     : STD_LOGIC := '0';
	SIGNAL DataLatched  : STD_LOGIC := '0';
	SIGNAL RxParityErr  : STD_LOGIC := '0';
	SIGNAL DataReception : STD_LOGIC := '0';
	
	SIGNAL WordNumWrite : UNSIGNED( 5 DOWNTO 0 )                 := ( OTHERS => '0' ); -- Data Length, in words number, from Data transfer command word
	SIGNAL RAMWordsCnt  : UNSIGNED( 5 DOWNTO 0 )                 := ( OTHERS => '0' ); -- FIFO words writed counter
	SIGNAL RAMAddrTmp   : UNSIGNED( AddrWidth DOWNTO 0 )         := ( OTHERS => '0' );
	SIGNAL RAMAddrTmp2  : UNSIGNED( AddrWidth DOWNTO 0 )         := ( OTHERS => '0' );	
	
	SIGNAL TxReq        : STD_LOGIC                       := '0';
	SIGNAL TxManByteCnt : UNSIGNED( 3 DOWNTO 0 )          := ( OTHERS => '0' ); -- MANAGE interface tansmitted bytes counter
	SIGNAL TxManByteNum : UNSIGNED( 3 DOWNTO 0 )          := ( OTHERS => '0' ); -- MANAGE interface to be tansmitted bytes 
	SIGNAL ComReadyTmp  : STD_LOGIC                       := '0';
	SIGNAL ManageTmp    : STD_LOGIC_VECTOR(  7 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL WrEnTmp      : STD_LOGIC := '0';
	
	SIGNAL RxLenError   : STD_LOGIC := '0';	
	SIGNAL MesgError    : STD_LOGIC := '0'; 
	SIGNAL RxMode       : STD_LOGIC := '0'; -- 0 = BM -> RT; 1 = RT -> RT;	
	SIGNAL TxAddr       : STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := ( OTHERS => '0' );  -- Terminal transmitter address
	SIGNAL AnswerReady  : STD_LOGIC := '0';
	SIGNAL Broad        : STD_LOGIC := '0';
	SIGNAL EP1, EP2     : STD_LOGIC := '0';
	SIGNAL EndPackPulse : STD_LOGIC := '0';	
	SIGNAL RAM_Full     : STD_LOGIC := '0';
	SIGNAL PrevStatWord : STD_LOGIC := '0';
	SIGNAL PrevAnswerWord : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS  => '0' );
	SIGNAL TransmitDelay  : STD_LOGIC := '0';
	
	SIGNAL CWRxOK         : STD_LOGIC := '0';
	SIGNAL CWRxErr        : STD_LOGIC := '0';
	SIGNAL TxBusy         : STD_LOGIC := '0';
	SIGNAL RAM_WrBusy     : STD_LOGIC := '0';
	SIGNAL ChannelNum     : INTEGER RANGE 0 TO 1 := 0;

	
	SIGNAL op             : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL op2            : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TxWait         : STD_LOGIC := '0';
	SIGNAL ParErrLoc      : STD_LOGIC := '0';
	
	SIGNAL AnsMode        : STD_LOGIC := '0';
	SIGNAL AnsError       : STD_LOGIC := '0';
	SIGNAL ProtError      : STD_LOGIC := '0';
	SIGNAL ANSW_Data      : STD_LOGIC := '0';
	SIGNAL Busy           : STD_LOGIC := '0';


	PROCEDURE MakeAnswerWord ( SIGNAL AnsWord : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
							   SIGNAL PrError : IN STD_LOGIC;
							   SIGNAL Addr    : IN STD_LOGIC_VECTOR(  4 DOWNTO 0 );
							   SIGNAL BrAddr  : IN STD_LOGIC;
							   SIGNAL TxFlag  : IN STD_LOGIC;
	                           SIGNAL StReg   : IN STD_LOGIC_VECTOR(  7 DOWNTO 0 ) ) IS

	BEGIN
	
		AnsWord( 15 DOWNTO 11 ) <= Addr;  -- Answer Node Address
		AnsWord( 10 ) <= PrError; -- Error 
		AnsWord( 9 )  <= '0';    -- 1 = CommandWord; 0 = Status Word
		AnsWord( 8 )  <= '0';    -- 1 = Service request;
		AnsWord( 7 DOWNTO 5 ) <= ( OTHERS => '0' );  -- reserved
		
		AnsWord( 4 )  <= BrAddr; 
		
		IF TxFlag = '1' THEN     --  Busy (NOT USED)
			AnsWord( 3 )  <= '0'; 
		ELSE
			AnsWord( 3 )  <= '0'; 
		END IF;
		
		AnsWord( 2 )  <= '0';  --  Subscriber fault (NOT USED)
		AnsWord( 1 )  <= '0';  --  Dynamic bus control acceptance (NOT USED)
		AnsWord( 0 )  <= StReg(2);  -- Terminal flag (Terminal Fault) (TxError indication)	
	
	END MakeAnswerWord;
	                           

	

BEGIN

	IntStateReg(7) <= Enable;
	IntStateReg(6) <= RAM_Full;  -- Not used in Config
	IntStateReg(5) <= CWRxOK;
	IntStateReg(4) <= CWRxErr;
	IntStateReg(3) <= ( TxErr0 OR TxErr1 );
	IntStateReg(2) <= ParError;  --RxParityErr;	
	IntStateReg(1) <= RAM_WrBusy;	-- RAM_Wr_busy (reserved)
	IntStateReg(0) <= '0';	-- reserved
	
	RxTx <= RX_TR;
	
	StateReg <= IntStateReg;

	op       <= ( nEmpty1 & nEmpty0 );	


	
	
	StateSwitcher: PROCESS( Enable, Clk )
	VARIABLE BusyTimer : INTEGER RANGE 0 TO 31 := 0;
	BEGIN
		IF Enable = '0' THEN
			PresState <= IDLE;
			BusyTimer := 0;
			Busy <= '0';
			
		ELSIF RISING_EDGE( Clk ) THEN
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
			
			PresState <= NextState;		
		END IF;
	END PROCESS;






	StateHandler: PROCESS( Enable, Clk )
	VARIABLE AnswerWordSafe  : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );  -- Answer Word for MILSTD-1553
	VARIABLE AddrRAM         : UNSIGNED( AddrWidth DOWNTO 0 )  := ( OTHERS => '0' );
	
	VARIABLE RxCom_Len_var       : STD_LOGIC_VECTOR(  4 DOWNTO 0 ) := ( OTHERS => '0' );  -- received command code from MILSTD-1553
	VARIABLE SubAddr_var         : STD_LOGIC_VECTOR(  4 DOWNTO 0 ) := ( OTHERS => '0' );  -- received subaddress or mode from MILSTD-1553
	VARIABLE RxAddr_var          : STD_LOGIC_VECTOR(  4 DOWNTO 0 ) := ( OTHERS => '0' );
	VARIABLE RxWord_var          : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );  -- receiverd word from RxPhy
	VARIABLE waitcnt             : INTEGER RANGE 0 TO 15 := 0;
	
	BEGIN
	
		IF Enable = '0' THEN
	
			TxBlock0    <= '0';	
			TxBlock1    <= '0';	
			WrEnTmp     <= '0';
			RAM_WrBusy  <= '0';
			ComReady    <= '0';
			RxChan      <= '0';
			Data_Com    <= '0';
			WrEn        <= '0';
			RdReq0      <= '0';
			RdReq1      <= '0';
		
		ELSIF FALLING_EDGE( Clk ) THEN
			CASE PresState IS
			
			WHEN IDLE =>
			
				WrEn     <= '0';
				RdReq0   <= '0';
				RdReq1   <= '0';
				RAMWordsCnt <= ( OTHERS => '0' );
				ANSW_Data <= '0';

				IF ( Busy = '0' ) AND ( op /= RxAll_Empty ) THEN
					NextState <= RD_EN;
				END IF;

			
			WHEN RD_EN =>
				IF op = Rx0_nEmpty THEN
				
					RdReq0 <= '1';
					RdReq1 <= '0';
					ChannelNum <= 0;
					
				ELSIF op = Rx1_nEmpty THEN
					
					RdReq0 <= '0';
					RdReq1 <= '1';
					ChannelNum <= 1;
				
				ELSE
					NextState <= IDLE;	
				END IF;
				
				NextState <= COM_WORD;
				
			
			WHEN COM_WORD =>
				IF ( WordStat = SYNC_TYPE_PAUSE ) OR ( op( ChannelNum ) = '0' ) THEN

					NextState <= IDLE;
					RdReq0    <= '0';
					RdReq1    <= '0';
					
				ELSIF WordStat = SYNC_TYPE_COMM THEN 
					
					IF TxWait = '0' THEN
				
						RxAddr    <= WordIn( 15 DOWNTO 11 );
						SubAddr   <= WordIn(  9 DOWNTO  5 );
						RX_TR     <= WordIn( 10 );
						RxCom_Len <= WordIn(  4 DOWNTO  0 );
						RxWord    <= WordIn;
						
						RxAddr_var    := WordIn( 15 DOWNTO 11 );
						SubAddr_var   := WordIn(  9 DOWNTO  5 );
						RxWord_var    := WordIn;
						RxCom_Len_var := WordIn(  4 DOWNTO  0 );
						
						
						RxChan    <= STD_LOGIC( TO_UNSIGNED( ChannelNum, 1 )(0) );
						ParErrLoc <= ParErrLoc OR ParError;
						
						----------- Node Address filter -----------
						IF ( RxAddr_var = NodeAddr ) OR ( RxAddr_var = BROAD_ADDR ) THEN
							IF RxAddr_var = NodeAddr THEN
								Broad <= '0';
							ELSE
								Broad <= '1';
							END IF;
							
							IF ( SubAddr_var = DRV_MODE_0 ) OR ( SubAddr_var = DRV_MODE_1 ) THEN  -- Command mode
								
								NextState <= COM_MODE;
								
							ELSE   -- Data mode
								IF RxCom_Len_var = "00000" THEN
									WordNumWrite <= "100000";
								
								ELSE
									WordNumWrite( 5 ) <= '0';
									WordNumWrite( 4 DOWNTO 0 ) <= UNSIGNED( RxCom_Len_var );
								END IF;
								
								NextState <= DAT_MODE;
							
							END IF;
						
						ELSE
							NextState <= COM_WORD;
						END IF;
					ELSE
						NextState <= DAT_MODE;
					END IF;			
								
				ELSE
					NextState <= COM_WORD;
				END IF;
				
						
					
				
				
			WHEN COM_MODE =>	
					
				IF RX_TR = TX_TRANSACT THEN   -- if received proper command code. (Used only codes with RxTx-bit = TX_TRANSACT)
				---- CommandCode selection ----------
					CASE RxCom_Len IS
					
					WHEN TRANS_SHUTDWN =>
						
						CWRxErr <= '0';	
						IF ChannelNum = 0 THEN
							TxBlock0      <= '0';
							TxBlock1      <= '1';
						ELSE
							TxBlock0      <= '1';
							TxBlock1      <= '0';
						END IF;
						
						LastCommand  <= RxWord;
						ANSW_Data    <= '0';
						PrevStatWord <= '0';
					
					WHEN OVRD_TRANS_SHUTDWN =>
					
						CWRxErr <= '0';
						
						IF ChannelNum = 0 THEN	
							TxBlock1 <= '0';
						ELSE
							TxBlock0 <= '0';
						END IF;
						
						LastCommand  <= RxWord;
						ANSW_Data    <= '0';
						PrevStatWord <= '0';	
					
					WHEN RST_REMOTE_TERMINAL =>
						
						CWRxErr      <= '0';	
						TxBlock0     <= '0';
						TxBlock1     <= '0';
						LastCommand  <= RxWord;
						ANSW_Data    <= '0';
						PrevStatWord <= '0';
					
					WHEN TX_STAT_WRD =>
						
						CWRxErr <= '0';	
						LastCommand  <= RxWord;
						ANSW_Data    <= '0';
						PrevStatWord <= '1';
					
					WHEN TX_LAST_COMAND =>
					
						CWRxErr <= '0';	
						AnswerData   <= LastCommand;
						ANSW_Data    <= '1';
						PrevStatWord <= '0';
					
					
					WHEN OTHERS =>
						LastCommand  <= RxWord;
						CWRxErr      <= '0';	
						PrevStatWord <= '0';
						ANSW_Data    <= '0';
						NULL;
						
					END CASE;
					
				END IF;
				
				IF ( WordStat = SYNC_TYPE_PAUSE ) OR ( op( ChannelNum ) = '0' ) THEN
					RdReq0 <= '0';
					RdReq1 <= '0';
					AnsMode <= COM;
					AnsError <= ( ParErrLoc OR ProtError );
					NextState <= ANS_GEN;
				
				ELSIF WordStat = SYNC_TYPE_DATA THEN
					-- Command data word parsing
					-- Do nothing yet
					NULL;
				
				END IF;
				
			
			
			
				
			WHEN DAT_MODE =>
				IF WordStat = SYNC_TYPE_DATA THEN -- write data into RAM
					RxWord_var := WordIn;
					IF RX_TR = RX_TRANSACT THEN
						TxWait     <= '0';
						ParErrLoc  <= ( ParErrLoc OR ParError );
						
						IF RAMWordsCnt < WordNumWrite THEN
							WrEn        <= '1';
							RAMWordsCnt <= RAMWordsCnt + "000001";
							RAM_Full    <= '0'; 

							IF RAMWordsCnt = "000000" THEN	-- sector start address
								AddrRAM := ( "000" & UNSIGNED( SubAddr & "00000" ) );
							ELSE
								AddrRAM := AddrRAM + x"1";	
							END IF;
								
							RAMAddr <= STD_LOGIC_VECTOR( AddrRAM( AddrRAM'LEFT DOWNTO 1 ) );
						
							IF AddrRAM( 0 ) = '1' THEN
								ByteEn <= "1100";
								DataOut( ( DataOut'LEFT ) DOWNTO ( DataOut'LEFT - 15 ) ) <= RxWord_var;
								DataOut( 15 DOWNTO 0 ) <= ( OTHERS => '0' );
								---------------- SWAPPED BYTES IN WORD -------------------------------------------------
								--DataOut(( DataOut'LEFT ) DOWNTO ( DataOut'LEFT - 7 ) ) <= RxWord( 7 DOWNTO 0 );
								--DataOut(( DataOut'LEFT - 8 ) DOWNTO ( DataOut'LEFT - 15 ) ) <= RxWord( 15 DOWNTO 8 );
								-----------------------------------------------------------------------------------------
								
							ELSE
								
								ByteEn <= "0011";
								DataOut( ( DataOut'LEFT ) DOWNTO ( DataOut'LEFT - 15 ) ) <= ( OTHERS => '0' );
								DataOut( 15 DOWNTO 0 ) <= RxWord_var;
								---------------- SWAPPED BYTES IN WORD ----------------------
								--DataOut( 15 DOWNTO 8 ) <= RxWord( 7 DOWNTO 0 );
								--DataOut( 7 DOWNTO 0 ) <= RxWord( 15 DOWNTO 8 );
								------------------------------------------------------------
								
							END IF;
						
							--NextState <= WAIT_MODE;
						
						ELSE
							WrEn <= '0';
						END IF;
						
					ELSE
						WrEn <= '0';
						NextState <= IDLE;
					END IF;
				
				ELSIF ( WordStat = SYNC_TYPE_PAUSE ) OR ( op( ChannelNum ) = '0' ) THEN 			
				
					RdReq1 <= '0';
					RdReq0 <= '0';
					WrEn   <= '0';
					IF TxWait = '1' THEN
						NextState <= IDLE;
					ELSE
						AnsMode <= DATA;
						AnsError <= ParErrLoc;
						NextState <= ANS_GEN;
						
						IF RAMWordsCnt = WordNumWrite THEN
							MesgError <= ParErrLoc;
						ELSE
							IF RX_TR = RX_TRANSACT THEN
								MesgError <= '1';
							END IF;
						END IF;
						
					END IF;
				
				ELSIF WordStat = SYNC_TYPE_COMM THEN
					TxWait <= '1';
				
				ELSE
					NextState <= IDLE;
				
				END IF;
					
				
			
--			WHEN WAIT_MODE	=>
--				WrEn      <= '0';
--				IF WaitReq = '1' THEN
--					NextState <= REQ_MODE;
--					waitcnt   := 0;
--				ELSIF waitcnt < 15 THEN
--					waitcnt := waitcnt + 1;
--				ELSE
--					NextState <= DAT_MODE;
--					--NextState <= IDLE;
--					waitcnt := 0;
--							
--				END IF;
--			
--			
--			WHEN REQ_MODE =>
--				IF WaitReq = '0' THEN
--					NextState <= DAT_MODE;
--					waitcnt   := 0;
--				ELSIF waitcnt < 15 THEN
--					waitcnt := waitcnt + 1;
--				ELSE
--					NextState <= DAT_MODE;
--					--NextState <= IDLE;
--					waitcnt := 0;
--				END IF; 
			
			
			WHEN ANS_GEN =>

				MakeAnswerWord( AnswerWord, MesgError, NodeAddr, Broad, TxBusy, IntStateReg );
				
				IF ( AnsMode = DATA ) AND ( RX_TR = RX_TRANSACT ) THEN 
					RxWrdCnt  <= STD_LOGIC_VECTOR( RAMWordsCnt );
					RxSubAddr <= SubAddr;
					IF( ParErrLoc = '0' )THEN
						CWRxOK <= '1';
					ELSE
						CWRxOK <= '0';
					END iF;
				ELSE
					RxWrdCnt  <= ( OTHERS => '0' );
				END IF;
				
				IF AnsMode = COM THEN
					IF ANSW_Data = '1' THEN
						TxManByteNum <= x"4";
					ELSE
						TxManByteNum <= x"2";
					END IF;
				ELSIF AnsMode = DATA THEN
					IF RX_TR = TX_TRANSACT THEN
						TxManByteNum <= x"4";
						AnswerData( 4 DOWNTO 0 )  <= RxCom_Len; -- WordNumWrite( 4 DOWNTO 0 ); 
						AnswerData( 12 DOWNTO 8 ) <= SubAddr;
					ELSE
						TxManByteNum <= x"2";
					END IF;
				END IF;
				NextState <= ANS_SEND;
				
				




			WHEN ANS_SEND =>
			
				RAMWordsCnt <= ( OTHERS => '0' );
				RAM_WrBusy <= '0';

				IF TxManByteCnt <= TxManByteNum THEN
					
					TxManByteCnt <= TxManByteCnt + x"1";
					
					IF TxManByteCnt = x"0" THEN
						
						AnswerWordSafe := AnswerWord;
					
					ELSIF TxManByteCnt > x"0" THEN
						
						ComReady <= '1';
						Data_Com <= AnsMode;
						
						IF TxManByteCnt < x"3" THEN
							
							IF PrevStatWord = '0' THEN	
								
								AnswerWord <= AnswerWord( ( AnswerWord'LEFT - 8 ) DOWNTO 0 ) & AnswerWord( ( AnswerWord'LEFT ) DOWNTO ( AnswerWord'LEFT - 7 ) );
								Manage     <= AnswerWord( ( AnswerWord'LEFT ) DOWNTO ( AnswerWord'LEFT - 7 ) );
								
							ELSE
							
								PrevAnswerWord <= PrevAnswerWord( ( PrevAnswerWord'LEFT - 8 ) DOWNTO 0 ) & x"00";
								Manage         <= PrevAnswerWord( ( PrevAnswerWord'LEFT ) DOWNTO ( PrevAnswerWord'LEFT - 7 ) );
							
							END IF;
							
						ELSE
						
							AnswerData <= AnswerData( ( AnswerData'LEFT - 8 ) DOWNTO 0 ) & x"00";
							Manage     <= AnswerData( ( AnswerData'LEFT ) DOWNTO ( AnswerData'LEFT - 7 ) );
							
						END IF;
					
					END IF;					
				
				ELSE
				
					TxManByteCnt   <= ( OTHERS => '0' );
					PrevAnswerWord <= AnswerWordSafe; 
					
					ComReady  <= '0';
					Data_Com  <= '0';
					CWRxOK    <= '0';
					NextState <= IDLE;
				
				END IF;
				

			
			WHEN OTHERS => 
			
				NextState <= IDLE;
				
			END CASE;
				
		END IF;
	END PROCESS;




END RTL;
