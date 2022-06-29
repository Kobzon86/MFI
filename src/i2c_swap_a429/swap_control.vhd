LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.i2c_swap_a429_pkg.ALL;

ENTITY swap_control IS
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
		FIFO_q		    : IN  STD_LOGIC_VECTOR ( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0);
		FIFO_empty		: IN  STD_LOGIC;
		FIFO_full		: IN  STD_LOGIC;

		SwapStart       : IN  STD_LOGIC
	);
	
END swap_control;


ARCHITECTURE RTL OF swap_control IS

	CONSTANT WAIT_TIMER    : INTEGER := 7;
	CONSTANT WAIT_WR_TIMER : INTEGER := 2;
	CONSTANT WAIT_SRC_COUNTER : INTEGER := 64;
	CONSTANT I2C_TO_A429   : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
	CONSTANT A429_TO_I2C   : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "11";

--	TYPE   T_States     IS ( IDLE, RD_A429RX_AVAIL, CHK_A429RX_AVAIL, RD_A429RX_RDPTR, CHK_A429RX_RDPTR , RD_A429RX_BUSY, CHK_A429RX_BUSY, RD_A429RX, 
--	                         WR_FIFO, RD_FIFO, RD_I2C_BUSY, CHK_I2C_BUSY, WR_I2C_TX, RD_I2C_NEWRX, CHK_I2C_NEWRX, CHK_I2CRX_BUSY, 
--	                         RD_I2CRX, RD_A429TX0_BUSY, CHK_A429TX0_BUSY, WR_A429TX, RD_WAIT, WR_WAIT );

	TYPE   T_States     IS ( IDLE, RD_SRC_RAM, RD_WAIT, WR_FIFO, RD_FIFO, WR_DST_RAM, WR_WAIT, SWITCH_SRC, RD_SRC_FLAGS, CHK_SRC_AVAIL, SRC_WAIT );
 	                         
	SIGNAL NextState  : T_States;
	SIGNAL PresState  : T_States;
	SIGNAL WaitState  : T_States;
	SIGNAL RdState    : T_States;
	SIGNAL WrState    : T_States;
	
	SIGNAL PackLen         : UNSIGNED( ( RXWRD_AVAIL_H - RXWRD_AVAIL_L ) DOWNTO 0 );
	SIGNAL SrcAddrStart    : UNSIGNED( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL DstAddrStart    : UNSIGNED( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL A429TxAddrNext  : UNSIGNED( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL DataDirection   : STD_LOGIC_VECTOR( 1 DOWNTO 0 );	
	SIGNAL A429Rx_StartAddr : UNSIGNED( ( RD_PTR_H - RD_PTR_L ) DOWNTO 0 );  -- -1
	
	
	SIGNAL RdWordsCnt      : UNSIGNED( ( RXWRD_AVAIL_H - RXWRD_AVAIL_L - 1 ) DOWNTO 0 );
	SIGNAL AVMM_WordReaded : STD_LOGIC;
	SIGNAL AVMM_Wait       : STD_LOGIC;
	SIGNAL AvmAddrCnt      : UNSIGNED( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL WaitCnt         : INTEGER RANGE 0 TO 15;
	SIGNAL SrcWaitCnt      : INTEGER RANGE 0 TO 127;
	
	
BEGIN

	StateSwitcher: PROCESS( Enable, Clk )
	BEGIN
		IF Enable = '0' THEN
			PresState <= IDLE;
		ELSIF RISING_EDGE( Clk ) THEN
			PresState <= NextState;
		END IF;
	END PROCESS;
	
	
	
	StateHandler: PROCESS( Enable, Clk )
	BEGIN
		IF Enable = '0' THEN
			NextState   <= IDLE;
			AVM_RdEn    <= '0';
			AVM_WrEn    <= '0';
			FIFO_rdreq	<= '0';
			FIFO_wrreq	<= '0';
			WaitCnt     <= 0;
			FIFO_aclr   <= '1';
			SrcAddrStart <= I2C_NIOS_BUFF_STARTADDR; --  I2C_BUFF_ADDR;
			DstAddrStart <= A429TX_BUFF_ADDR;
			PackLen      <= I2C_SWAP_DATA_LEN;
			RdWordsCnt   <= ( OTHERS => '0' );
			DataDirection  <= I2C_TO_A429;
			AVM_ByteEnCode <= ( OTHERS => '0' );
			A429TxAddrNext  <= A429TX_BUFF_ADDR;
		
		ELSIF FALLING_EDGE( Clk ) THEN
			CASE PresState IS
			WHEN IDLE =>
				FIFO_aclr   <= '0';
				AVM_RdEn    <= '0';
				AVM_WrEn    <= '0';
				RdWordsCnt  <= ( OTHERS => '0' );
				PackLen     <= I2C_SWAP_DATA_LEN;
				DataDirection <= I2C_TO_A429;
				SrcAddrStart  <= I2C_NIOS_BUFF_STARTADDR;
				--DstAddrStart <= A429TX_BUFF_ADDR;
				DstAddrStart <= A429TxAddrNext;
				IF SwapStart = '1' THEN
					NextState <= RD_SRC_RAM;  --RD_SRC_FLAGS;  --
				END IF;
			
			
			WHEN RD_SRC_FLAGS =>
				AVM_RdEn       <= '1';
				IF DataDirection = I2C_TO_A429 THEN
					AVM_Addr <= STD_LOGIC_VECTOR( I2C_INTREG_ADDR );
				ELSIF DataDirection = A429_TO_I2C THEN
					AVM_Addr <= STD_LOGIC_VECTOR( A429RX_INTREG_ADDR );
				END IF;
				AVM_ByteEnCode <= ( OTHERS => '1' );
				NextState      <= RD_WAIT;
				WaitCnt        <= WAIT_TIMER;
				WaitState      <= CHK_SRC_AVAIL;
			


			WHEN CHK_SRC_AVAIL =>
				IF DataDirection = I2C_TO_A429 THEN
					IF AVM_RdData( FPGA_RXBUFF_BUSY ) = '1' THEN
						NextState <= SRC_WAIT;		
						SrcWaitCnt <= WAIT_SRC_COUNTER;
					ELSE
						SrcAddrStart <= I2C_NIOS_BUFF_STARTADDR;
						PackLen      <= I2C_SWAP_DATA_LEN;
						NextState    <= RD_SRC_RAM;
					END IF;
				
				ELSIF DataDirection = A429_TO_I2C THEN
					--A429Rx_StartAddr <= UNSIGNED( AVM_RdData( RD_PTR_H DOWNTO RD_PTR_L ) );
					
					IF ( AVM_RdData( RXWRD_AVAIL_H DOWNTO RXWRD_AVAIL_L ) /= 
						 STD_LOGIC_VECTOR( TO_UNSIGNED( 0, RXWRD_AVAIL_H - RXWRD_AVAIL_L + 1 ) ) ) THEN
						
						--- Check Buffer Busy ---------
						IF I2C_SWAP_DATA_LEN > UNSIGNED( AVM_RdData( RXWRD_AVAIL_H DOWNTO RXWRD_AVAIL_L ) ) THEN
							PackLen <= UNSIGNED( AVM_RdData( RXWRD_AVAIL_H DOWNTO RXWRD_AVAIL_L ) );
						ELSE
							PackLen <= I2C_SWAP_DATA_LEN;
						END IF;
						
						IF( AVM_RdData( FPGA_BUFF_BUSY ) = '0' ) THEN
							RdWordsCnt   <= ( OTHERS => '0' );
							-------------- devide SrcAddrStart for I2C and A429 --------------
							SrcAddrStart <= A429RX_FIFO_ADDR + UNSIGNED( AVM_RdData( RD_PTR_H DOWNTO RD_PTR_L ) );  --A429Rx_StartAddr;
							NextState    <= RD_SRC_RAM;
						ELSE
							NextState <= IDLE; 
						END IF;
					
					ELSE
						NextState <= IDLE;
					END IF;
				END IF;
			
			
			
			
			WHEN SRC_WAIT =>
				AVM_RdEn <= '0';
				IF SrcWaitCnt > 0 THEN
					SrcWaitCnt <= SrcWaitCnt - 1;
				ELSE
					SrcWaitCnt <= 0;
					NextState <= RD_SRC_FLAGS;
				END IF;
			
			
			
			
			WHEN RD_SRC_RAM =>
				FIFO_wrreq <= '0';
				IF RdWordsCnt < PackLen THEN
					RdWordsCnt <= RdWordsCnt + 1;
					AVM_RdEn   <= '1';
					IF DataDirection = I2C_TO_A429 THEN
						--AVM_Addr     <= STD_LOGIC_VECTOR( SrcAddrStart + resize( RdWordsCnt, AVM_ADDR_WIDTH ));
						SrcAddrStart <= SrcAddrStart + 1;
					ELSIF DataDirection = A429_TO_I2C THEN
						IF SrcAddrStart < ( A429RX_FIFO_ADDR + A429RX_BUFF_LEN ) THEN
							SrcAddrStart <= SrcAddrStart + 1;
						ELSE
							SrcAddrStart <= A429RX_FIFO_ADDR;
						END IF;
					END IF;
					
					AVM_Addr  <= STD_LOGIC_VECTOR( SrcAddrStart ); 
					AVM_ByteEnCode <= x"F";
					NextState <= RD_WAIT;
					WaitCnt   <= WAIT_TIMER;              
					WaitState <= WR_FIFO;
				ELSE
					RdWordsCnt <= ( OTHERS => '0' );
					NextState  <= RD_FIFO;
				END IF;

			
			WHEN RD_WAIT =>
				AVM_RdEn <= '0';
				IF WaitCnt > 0 THEN
					WaitCnt <= WaitCnt - 1;
					IF AVM_Ready = '1' THEN
						NextState <= WaitState;
					END IF;
				ELSE
					NextState <= IDLE;
				END IF;
			
			
			
			WHEN WR_FIFO =>
				IF FIFO_full = '0' THEN
					FIFO_wrreq <= '1';
					FIFO_data <= AVM_RdData;
					NextState <= RD_SRC_RAM;
				ELSE
					NextState <=  IDLE;
				END IF;

			
			
			WHEN RD_FIFO =>
				IF FIFO_empty = '0'  THEN
					FIFO_rdreq <= '1';
				END IF;  
				NextState <=  WR_DST_RAM;
			
			
			
			
			WHEN WR_DST_RAM =>
				FIFO_rdreq     <= '0';
				IF RdWordsCnt < PackLen THEN -- AND ( FIFO_empty = '0' ) ) THEN
					RdWordsCnt <= RdWordsCnt + 1;
					AVM_WrEn   <= '1';
					IF DataDirection = A429_TO_I2C THEN
						DstAddrStart <= DstAddrStart + 1;
					ELSIF DataDirection = I2C_TO_A429 THEN
						IF DstAddrStart < ( A429TX_BUFF_ADDR + A429TX_BUFF_LEN - 1 ) THEN
							DstAddrStart   <= DstAddrStart + 1;
							--A429TxAddrNext <= A429TxAddrNext + 1;
						ELSE
							DstAddrStart   <= A429TX_BUFF_ADDR;
							--A429TxAddrNext <= A429TX_BUFF_ADDR;
						END IF;
					END IF;
					AVM_Addr       <= STD_LOGIC_VECTOR( DstAddrStart ); 
					AVM_WrData     <= FIFO_q;
					AVM_ByteEnCode <= x"F";
					WaitCnt        <= WAIT_WR_TIMER;
					NextState      <= WR_WAIT;
					WaitState      <= RD_FIFO;
				ELSE
				--	IF DataDirection = I2C_TO_A429 THEN
				--		A429TxAddrNext <= DstAddrStart;
				--	END IF;
					RdWordsCnt <= ( OTHERS => '0' );
					NextState  <= SWITCH_SRC;
				END IF;
				
			
			
			WHEN WR_WAIT =>
				AVM_WrEn <= '0';
				IF WaitCnt > 0 THEN
					WaitCnt <= WaitCnt - 1;
				ELSE
					IF FIFO_empty = '0' THEN
						NextState <= WaitState;
					ELSE
						NextState <= SWITCH_SRC;
					END IF;
				END IF;
				IF DataDirection = I2C_TO_A429 THEN
					IF DstAddrStart < ( A429TX_BUFF_ADDR + A429TX_BUFF_LEN - 1 ) THEN
						A429TxAddrNext <= DstAddrStart; -- + 1;
					ELSE
						A429TxAddrNext <= A429TX_BUFF_ADDR;
					END IF;
					
				END IF;
			
			
			
			
			WHEN SWITCH_SRC =>
				FIFO_rdreq <= '0';
				AVM_WrEn   <= '0';
				AVM_RdEn   <= '0';
				RdWordsCnt <= ( OTHERS => '0' );
				IF DataDirection = A429_TO_I2C THEN
					DataDirection <= I2C_TO_A429;
					SrcAddrStart  <= I2C_NIOS_BUFF_STARTADDR; --I2C_BUFF_ADDR;
					DstAddrStart  <= A429TxAddrNext;          --A429TX_BUFF_ADDR;
					PackLen       <= I2C_SWAP_DATA_LEN;
					NextState <= IDLE;
				ELSIF DataDirection = I2C_TO_A429 THEN
					DataDirection <= A429_TO_I2C;
					SrcAddrStart  <= A429RX_FIFO_ADDR;
					DstAddrStart  <= I2C_TXBUFF_ADDR;
					PackLen       <= I2C_SWAP_DATA_LEN;  --( OTHERS => '0' );
					NextState     <= RD_SRC_RAM;         --RD_SRC_FLAGS;
				
				END IF;
			
			
			
						


				
			WHEN OTHERS =>
				NextState <= IDLE;
			END CASE;
		
		END IF;
	
	
	END PROCESS;


END RTL;
