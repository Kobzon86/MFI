-- V03 
-- tx freq 4 MHz
-- TxFIFO added
-- FSM using 


LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

USE work.milstd_1553_pkg.ALL;


ENTITY milstd1553txphy IS
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
		TxInhibit : OUT STD_LOGIC;
		TxWord    : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		Full      : OUT STD_LOGIC
	);

END milstd1553txphy;



ARCHITECTURE RTL of milstd1553txphy IS
	
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

	
	TYPE StatesType IS ( IDLE, RD_FIFO, BUFF_WR, TX_WORD, PAR_SEND );
	
	CONSTANT FIFO_DATAWIDTH  : INTEGER := 16;
	CONSTANT FIFO_USEDWIDTH  : INTEGER := 6;
	CONSTANT FIFO_WORDNUM    : INTEGER := 64;
	
	CONSTANT INIT_PARITY_BIT : STD_LOGIC_VECTOR( 3 DOWNTO 0 ) := "1100";
	
	SIGNAL NextState, PresState : StatesType := IDLE;
	
		
	SIGNAL ClkDiv   : UNSIGNED( 2 DOWNTO 0 ) := ( OTHERS => '0' );          -- divide to 8 times (16/8 = 2 MHz)

	SIGNAL Buff     : STD_LOGIC_VECTOR( 63 DOWNTO 0 ) := ( OTHERS => '0' ); -- TxClk = 4MHz	
	SIGNAL SYNC     : STD_LOGIC_VECTOR( 11 DOWNTO 0 ) := ( OTHERS => '0' );
	

	SIGNAL Clk2MHz  : STD_LOGIC := '0';
	SIGNAL Clk4MHz  : STD_LOGIC := '0';
	SIGNAL ShiftClk : STD_LOGIC := '0';
	SIGNAL BitCnt   : UNSIGNED( 7 DOWNTO 0 ) := x"FF"; --( OTHERS => '0' ); -- to 64 bits
	SIGNAL ParityBit : STD_LOGIC_VECTOR( 3 DOWNTO 0 ) := INIT_PARITY_BIT;	

	SIGNAL FIFO_RdEn     : STD_LOGIC := '0';
	SIGNAL FIFO_DatEmpty : STD_LOGIC := '0';
	SIGNAL FIFO_DatFull  : STD_LOGIC := '0';
	SIGNAL FIFO_StEmpty  : STD_LOGIC := '0';
	SIGNAL FIFO_StFull   : STD_LOGIC := '0';
	SIGNAL FIFO_WordOut  : STD_LOGIC_VECTOR( ( FIFO_DATAWIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL FIFO_StOut    : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL Load          : STD_LOGIC := '0'; -- pulse by falling edge of FIFO_RdEn
--	SIGNAL LastBit       : STD_LOGIC := '0'; -- Last bit transmission pulse, for new FIFO data reading
	SIGNAL LastWord      : STD_LOGIC := '0';
	SIGNAL FIFO_aclr     : STD_LOGIC := '0';

BEGIN


	WordFIFO : FIFO 
	GENERIC MAP(
		DataWidth  =>  FIFO_DATAWIDTH,
		UsedWidth  =>  FIFO_USEDWIDTH,
		WordNum    =>  FIFO_WORDNUM
	)
	PORT MAP(
		aclr        =>  FIFO_aclr,
		data		=>  WordIn,
		rdclk		=>  Clk4MHz,
		rdreq		=>  FIFO_RdEn,
		wrclk		=>  WrClk,
		wrreq		=>  WrEn,
		q           =>  FIFO_WordOut,
		rdempty		=>  FIFO_DatEmpty,
		wrfull		=>  FIFO_DatFull
	);
	
	
	
	StatFIFO : FIFO 
	GENERIC MAP(
		DataWidth  => 2, 
		UsedWidth  => FIFO_USEDWIDTH, 
		WordNum    => FIFO_WORDNUM 
	)
	PORT MAP(
		aclr        => FIFO_aclr,
		data		=> WordStat, 
		rdclk		=> Clk4MHz, 
		rdreq		=> FIFO_RdEn, 
		wrclk		=> WrClk, 
		wrreq		=> WrEn, 
		q           => FIFO_StOut, 
		rdempty		=> FIFO_StEmpty, 
		wrfull		=> FIFO_StFull 
	);

	FIFO_aclr <= NOT Enable; 
	
	Full      <= FIFO_DatFull;
	TxInhibit <= NOT Enable;

	
	ClockDivide: PROCESS( Enable, Clk16MHz ) 
	BEGIN
		IF Enable = '0' THEN
			ClkDiv <= ( OTHERS => '0' );
		ELSIF RISING_EDGE( Clk16MHz ) THEN
			IF ClkDiv < "111" THEN
				ClkDiv <= ClkDiv + "001";
			ELSE
				ClkDiv <= ( OTHERS => '0' );
			END IF;
		END IF;
	END PROCESS;

	Clk2MHz <= ClkDiv( 2 );
	Clk4MHz <= ClkDiv( 1 );



	FSM_TxPhy: PROCESS( Enable, Clk4MHz )	
	BEGIN
		IF Enable = '0' THEN
			
			NextState <= IDLE;
			SYNC      <= ( OTHERS => '0' );	
			Buff      <= ( OTHERS => '0' );
			Transmit  <= '0';
			OutA  <= '0';
			OutB  <= '0';
			FIFO_RdEn <= '0';
			LastWord  <= '0';
			TxWord    <= ( OTHERS => '0' );
		
		ELSIF RISING_EDGE( Clk4MHz ) THEN
		
			PresState <= NextState;
		
		ELSIF FALLING_EDGE( Clk4MHz ) THEN
			CASE PresState IS
			
			WHEN IDLE =>
					Transmit  <= '0';
					OutA  <= '0';
					OutB  <= '0';
					FIFO_RdEn <= '0';
					LastWord <= '0';
				
				IF FIFO_DatEmpty = '0' THEN
					NextState <= RD_FIFO;
				END IF;
			
			
			WHEN RD_FIFO =>
		
				FIFO_RdEn <= '1';
				NextState <= BUFF_WR;

			
			WHEN BUFF_WR =>
				
				FIFO_RdEn <= '0';
				
				IF FIFO_StOut = SYNC_TYPE_COMM THEN
					SYNC <= TX_SYNC_COMM;
				ELSIF FIFO_StOut = SYNC_TYPE_DATA THEN
					SYNC <= TX_SYNC_DATA;
				END IF;
				
				FOR i IN 0 TO 15 LOOP
					Buff( i*4 )         <= NOT FIFO_WordOut(i);
					Buff( ( i*4 ) + 1 ) <= NOT FIFO_WordOut(i);
					Buff( ( i*4 ) + 2 ) <= FIFO_WordOut(i);
					Buff( ( i*4 ) + 3 ) <= FIFO_WordOut(i);
				END LOOP;
				
				BitCnt    <= ( OTHERS => '0' );
				NextState <= TX_WORD;
			
			WHEN TX_WORD =>
			
				IF BitCnt < TX_WRD_LEN THEN 

					BitCnt <= BitCnt + x"01";
					Transmit <= '1';
					
					IF BitCnt < TX_SYNC_LEN THEN 
					
						IF FIFO_DatEmpty = '1' THEN
							LastWord <= '1';
						ELSE
							LastWord <= '0';
						END IF;
						
						SYNC <= SYNC( ( SYNC'LEFT - 1 ) DOWNTO 0 ) & '0';
						OutA <= SYNC( SYNC'LEFT );
						OutB <= NOT SYNC( SYNC'LEFT );
						ParityBit <= INIT_PARITY_BIT;

					ELSE
						IF BitCnt < ( TX_WRD_LEN - 4 ) THEN 						
							
							OutA <= Buff( Buff'LEFT );
							OutB <= NOT Buff( Buff'LEFT );
							
							IF BitCnt( 1 DOWNTO 0 ) = "00" THEN
								
								IF BitCnt >= TX_SYNC_LEN THEN
									IF Buff( Buff'LEFT DOWNTO ( Buff'LEFT - 3 ) ) = "1100" THEN     -- PARITY Calculation (Odd parity)
										ParityBit <= NOT ParityBit;
									END IF;
								ELSE
									ParityBit <= INIT_PARITY_BIT;
								END IF;
								
								
							END IF;
							
							Buff <= Buff( ( Buff'LEFT - 1 ) DOWNTO 0 ) & '0';
						
						ELSE  -- Parity bit transmission 
							
							OutA      <= ParityBit( ParityBit'LEFT );
							OutB      <= NOT ParityBit( ParityBit'LEFT );
							ParityBit <= ParityBit( ( ParityBit'LEFT - 1 ) DOWNTO 0 ) & '0';
						
							IF LastWord = '0' THEN
								
								IF BitCnt = ( TX_WRD_LEN - 4 ) THEN
									
									TxWord <= FIFO_WordOut;
									
									IF FIFO_DatEmpty = '0' THEN
										FIFO_RdEn <= '1';
									ELSE
										FIFO_RdEn <= '0';
									END IF;
									
								ELSIF BitCnt = ( TX_WRD_LEN - 3 ) THEN
									
									FIFO_RdEn <= '0';
									
									IF FIFO_StOut = SYNC_TYPE_COMM THEN
										SYNC <= TX_SYNC_COMM;
									ELSIF FIFO_StOut = SYNC_TYPE_DATA THEN
										SYNC <= TX_SYNC_DATA;
									END IF;
									
								ELSIF BitCnt = ( TX_WRD_LEN - 2 ) THEN
									
									FOR i IN 0 TO 15 LOOP
										Buff( i*4 )         <= NOT FIFO_WordOut(i);
										Buff( ( i*4 ) + 1 ) <= NOT FIFO_WordOut(i);
										Buff( ( i*4 ) + 2 ) <= FIFO_WordOut(i);
										Buff( ( i*4 ) + 3 ) <= FIFO_WordOut(i);
									END LOOP;

								ELSE
									
									BitCnt <= ( OTHERS => '0' );

								END IF;
								
							ELSE
								
								IF BitCnt = ( TX_WRD_LEN - 1 ) THEN
									TxWord <= FIFO_WordOut;
									NextState <= IDLE;
								END IF;
							
							END IF;
							
						END IF;
						
					END IF;
					
				ELSE
					OutA    <= '0';
					OutB    <= '0';	
					NextState <= IDLE;
					
				END IF;	 
				
			WHEN OTHERS =>
				NextState <= IDLE;
			END CASE;
	
		END IF;
		
	END PROCESS;


END RTL;
