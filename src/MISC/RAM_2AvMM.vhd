-- RAM memory model with 2 Avalon-MM Slave ports
-- NOT Processing ByteEnable bits for write and read data 
-- RAM data Width is the SAME as the Avalon-MM port DataWidth
-- Avalon-MM port1 and port2 serves sequentially


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;


ENTITY RAM_2AvMM IS
	GENERIC(
		RAM_WordWidth : INTEGER := 8;
		RAM_WordNum   : INTEGER := 256; 
		AVS_AddrWidth : INTEGER := 8;
		AVS_BEWidth   : INTEGER := 4;
		AVS_DataWidth : INTEGER := 32
	);
	PORT(
		Avalon_nReset      : IN  STD_LOGIC := '0';
		Avalon_Clock       : IN  STD_LOGIC;

--		AVS1_waitrequest   : OUT STD_LOGIC;
--		AVS1_address       : IN  STD_LOGIC_VECTOR( ( AVS_AddrWidth - 1 ) DOWNTO 0 );
--		AVS1_byteenable    : IN  STD_LOGIC_VECTOR( ( AVS_BEWidth - 1 ) DOWNTO 0 );
--		AVS1_read          : IN  STD_LOGIC;
--		AVS1_readdata      : OUT STD_LOGIC_VECTOR( ( AVS_DataWidth - 1 ) DOWNTO 0 );
--		AVS1_readdatavalid : OUT STD_LOGIC;
--		AVS1_write         : IN  STD_LOGIC;
--		AVS1_writedata     : IN  STD_LOGIC_VECTOR( ( AVS_DataWidth - 1 ) DOWNTO 0 );
		
		AVS2_waitrequest   : OUT STD_LOGIC;
		AVS2_address       : IN  STD_LOGIC_VECTOR( ( AVS_AddrWidth - 1 ) DOWNTO 0 );
		AVS2_byteenable    : IN  STD_LOGIC_VECTOR( ( AVS_BEWidth - 1 ) DOWNTO 0 );
		AVS2_read          : IN  STD_LOGIC;
		AVS2_readdata      : OUT STD_LOGIC_VECTOR( ( AVS_DataWidth - 1 ) DOWNTO 0 );
		AVS2_readdatavalid : OUT STD_LOGIC;
		AVS2_write         : IN  STD_LOGIC;
		AVS2_writedata     : IN  STD_LOGIC_VECTOR( ( AVS_DataWidth - 1 ) DOWNTO 0 )
	);
	
END RAM_2AvMM;

ARCHITECTURE logic OF RAM_2AvMM IS
	
	TYPE RamType IS ARRAY ( ( RAM_WordNum - 1 ) DOWNTO 0 ) OF STD_LOGIC_VECTOR( ( RAM_WordWidth - 1 ) DOWNTO 0 );
	
	
	IMPURE FUNCTION init_mem( data_file : IN STRING ) RETURN RamType IS
		
		FILE in_file     : TEXT; -- OPEN READ_MODE IS "memory.dat";
		VARIABLE in_line : LINE;
		CONSTANT WordNum : INTEGER := RAM_WordNum;
		VARIABLE c       : STD_LOGIC_VECTOR( ( RAM_WordWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );	
		VARIABLE AddrCnt : INTEGER RANGE 0 TO ( WordNum - 1 ) := 0;
		VARIABLE CharCnt : INTEGER RANGE 0 TO 255 := 0;
		VARIABLE temp_mem : RamType;	
							
	BEGIN
								
		FILE_OPEN( in_file, data_file, READ_MODE ); --"memory.dat"
															
		WHILE NOT ENDFILE( in_file ) LOOP
									
			READLINE( in_file, in_line );
																											
			CharCnt := 0;
																																	
			WHILE CharCnt < in_line'Length LOOP
																																	
				READ( in_line, c );
			
				IF AddrCnt < ( WordNum - 1 ) THEN
			
					AddrCnt := AddrCnt + 1;
				
				ELSE
					
					AddrCnt := 0;
																																																																																		
				END IF;
																																																																																										
				--temp_mem( AddrCnt ) := STD_LOGIC_VECTOR( TO_UNSIGNED( c, TB_RAM_DataWidth ) );
				temp_mem( AddrCnt ) := c;
																																																																																																		
				CharCnt := CharCnt + 1;
																																																																																																									
				--	REPORT "Value readed from file = " & INTEGER'Image(c);
																																																																																																																
			END LOOP;
		END LOOP;	
																																																																																																																	
		ASSERT FALSE REPORT "Memory initialized" SEVERITY NOTE;
																																																																																																																															
		return temp_mem;
																																																																																																																			
	END FUNCTION;



	TYPE   T_Avalon_State     IS ( AVALON_RESET, AVALON_IDLE, AVALON_WRITE1, AVALON_ACK_WRITE1, AVALON_READ1, AVALON_ACK_READ1,
	                               AVALON_WRITE2, AVALON_ACK_WRITE2, AVALON_READ2, AVALON_ACK_READ2 );
	                               
	TYPE   T_Conf_Registers   IS ARRAY( 7 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	
	----------------- RAM buffer massive initializaion -----------------
	SIGNAL RAM_Mas            : Ramtype := init_mem("memory.mif");
	
	
	SIGNAL Signal_SlaveState  : T_Avalon_State   := AVALON_RESET;
	SIGNAL AVS1_RAMData       : STD_LOGIC_VECTOR( ( AVS_DataWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL AVS1_waitrequest   : STD_LOGIC := '0';
	SIGNAL AVS1_address       : STD_LOGIC_VECTOR( ( AVS_AddrWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL AVS1_byteenable    : STD_LOGIC_VECTOR( ( AVS_BEWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL AVS1_read          : STD_LOGIC := '0';
	SIGNAL AVS1_readdata      : STD_LOGIC_VECTOR( ( AVS_DataWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL AVS1_readdatavalid : STD_LOGIC := '0';
	SIGNAL AVS1_write         : STD_LOGIC := '0';
	SIGNAL AVS1_writedata     : STD_LOGIC_VECTOR( ( AVS_DataWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	
	
	
	
	
BEGIN
	------------- Check for correct GENERIC ----------------------------------
--	ASSERT RAM_WordNum = AVS_DataWidth 
--	REPORT "RAM_2AvMM | GENERIC: RAM_WordWidth must be equal to AVS_DataWidth" 
--	SEVERITY ERROR;
	
	ASSERT AVS_BEWidth = ( AVS_DataWidth / RAM_WordWidth ) 
	REPORT "RAM_2AvMM | GENERIC: AVS_BEWidth must be equal  AVS_DataWidth / RAM_WordWidth" 
	SEVERITY ERROR;
		
	
	ASSERT RAM_WordNum = 2**AVS_AddrWidth 
	REPORT "RAM_2AvMM | GENERIC: RAM_WordNum must be equal  2**AVS_AddrWidth" 
	SEVERITY ERROR;
	
	
	-- Avalon-MM Slave port1 and port2 to RAM Msassive
	
	AvalonMM:PROCESS( Avalon_nReset, Avalon_Clock )
		VARIABLE address : INTEGER RANGE 0 TO RAM_WordNum  := 0;
		VARIABLE data    : STD_LOGIC_VECTOR( ( AVS_DataWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	BEGIN
		
		IF( Avalon_nReset = '0' ) THEN
			
			AVS1_waitrequest   <= '0';
			AVS1_readdatavalid <= '0';
			AVS1_readdata      <= ( OTHERS => '0' );
			Signal_SlaveState <= AVALON_RESET;
			
		ELSIF( ( Avalon_Clock'EVENT ) AND ( Avalon_Clock = '1' ) ) THEN
			
			CASE Signal_SlaveState IS
			
			WHEN AVALON_RESET =>
				AVS1_waitrequest   <= '0';
				AVS1_readdatavalid <= '0';
				AVS1_readdata      <= ( OTHERS => '0' );
				AVS2_waitrequest   <= '0';
				AVS2_readdatavalid <= '0';
				AVS2_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_IDLE;
				
			
			WHEN AVALON_IDLE =>
				AVS1_waitrequest   <= '0';
				AVS1_readdatavalid <= '0';
				AVS1_readdata      <= ( OTHERS => '0' );
				AVS2_waitrequest   <= '0';
				AVS2_readdatavalid <= '0';
				AVS2_readdata      <= ( OTHERS => '0' );
				
				IF( AVS1_write = '1' ) THEN
					Signal_SlaveState <= AVALON_WRITE1;
				ELSIF( AVS1_read = '1' ) THEN
					Signal_SlaveState <= AVALON_READ1;
				ELSIF( AVS2_write = '1' ) THEN
					Signal_SlaveState <= AVALON_WRITE2;
				ELSIF( AVS2_read = '1' ) THEN
					Signal_SlaveState <= AVALON_READ2;	
				END IF;
			
			WHEN AVALON_WRITE1 =>
				address           := TO_INTEGER( UNSIGNED( AVS1_address ) );
				data              := AVS1_writedata;
				AVS1_waitrequest   <= '1';
				AVS1_readdatavalid <= '0';
				AVS1_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState  <= AVALON_ACK_WRITE1;
			
			WHEN AVALON_ACK_WRITE1 =>
				AVS1_waitrequest   <= '0';
				AVS1_readdatavalid <= '0';
				AVS1_readdata      <= ( OTHERS => '0' );
				
				FOR i IN AVS1_byteenable'RIGHT TO AVS1_byteenable'LEFT LOOP
					IF AVS1_byteenable(i) = '1' THEN
						RAM_Mas( address + i ) <= data( ( Data'RIGHT + RAM_WordWidth*(i+1) - 1 ) DOWNTO Data'RIGHT + RAM_WordWidth*i );
					END IF;
				END LOOP;
				
--				IF AVS1_byteenable(0) = '1' THEN
--					RAM_Mas( address ) <= data( ( Data'RIGHT + RAM_WordWidth - 1 ) DOWNTO Data'RIGHT );
--				END IF;
--				IF AVS1_byteenable(1) = '1' THEN
--					RAM_Mas( address + 1 ) <= data( ( Data'RIGHT + RAM_WordWidth*2 - 1 ) DOWNTO ( Data'RIGHT + RAM_WordWidth ) );
--				END IF;
--				IF AVS1_byteenable(2) = '1' THEN
--					RAM_Mas( address + 2 ) <= data( ( Data'RIGHT + RAM_WordWidth*3 - 1 ) DOWNTO ( Data'RIGHT + RAM_WordWidth*2 ) );
--				END IF;
--				IF AVS1_byteenable(3) = '1' THEN
--					RAM_Mas( address + 3 ) <= data( ( Data'RIGHT + RAM_WordWidth*4 - 1 ) DOWNTO ( Data'RIGHT + RAM_WordWidth*3 ) );
--				END IF;
				
				Signal_SlaveState  <= AVALON_IDLE;
			
			WHEN AVALON_READ1 =>
				address           := TO_INTEGER( UNSIGNED( AVS1_address ) );
				AVS1_waitrequest   <= '1';
				AVS1_readdatavalid <= '0';
				AVS1_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState  <= AVALON_ACK_READ1;
			
			WHEN AVALON_ACK_READ1 =>
				AVS1_waitrequest   <= '0';
				AVS1_readdatavalid <= '1';
				
				FOR i IN AVS1_byteenable'RIGHT TO AVS1_byteenable'LEFT LOOP
					IF AVS1_byteenable(i) = '1' THEN
						AVS1_readdata( ( AVS1_readdata'RIGHT + ( RAM_WordWidth*(i+1) ) - 1 ) DOWNTO 
									 ( AVS1_readdata'RIGHT + RAM_WordWidth*i ) ) <= RAM_Mas( address + i );
					ELSE
						AVS1_readdata( ( AVS1_readdata'RIGHT + ( RAM_WordWidth*(i+1) ) - 1 ) DOWNTO 
									 ( AVS1_readdata'RIGHT + RAM_WordWidth*i ) ) <= ( OTHERS => '0' );
					END IF;	
				END LOOP;	
					
					
--				AVS1_readdata      <= RAM_Mas( address + 3 ) AND ( AVS1_byteenable(3) 
--									  & RAM_Mas( address + 2 ) AND ( AVS1_byteenable(2)
--									  & RAM_Mas( address + 1 ) AND ( AVS1_byteenable(1)
--									  & RAM_Mas( address ) AND ( AVS1_byteenable(0)
--									  );
									  
				Signal_SlaveState  <= AVALON_IDLE;
			
			WHEN AVALON_WRITE2 =>
				address           := TO_INTEGER( UNSIGNED( AVS2_address ) );
				data              := AVS2_writedata;
				AVS2_waitrequest   <= '1';
				AVS2_readdatavalid <= '0';
				AVS2_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState  <= AVALON_ACK_WRITE2;
			
			WHEN AVALON_ACK_WRITE2 =>
				AVS2_waitrequest   <= '0';
				AVS2_readdatavalid <= '0';
				AVS2_readdata      <= ( OTHERS => '0' );
				
				FOR i IN AVS2_byteenable'RIGHT TO AVS2_byteenable'LEFT LOOP
					IF AVS2_byteenable(i) = '1' THEN
						RAM_Mas( address + i ) <= data( ( Data'RIGHT + RAM_WordWidth*(i+1) - 1 ) DOWNTO Data'RIGHT + RAM_WordWidth*i );
					END IF;
				END LOOP;
				
				
--				IF AVS2_byteenable(1) = '1' THEN
--					RAM_Mas( address + 1 ) <= data( ( Data'RIGHT + RAM_WordWidth*2 - 1 ) DOWNTO ( Data'RIGHT + RAM_WordWidth ) );
--				END IF;
--				IF AVS2_byteenable(2) = '1' THEN
--					RAM_Mas( address + 2 ) <= data( ( Data'RIGHT + RAM_WordWidth*3 - 1 ) DOWNTO ( Data'RIGHT + RAM_WordWidth*2 ) );
--				END IF;
--				IF AVS2_byteenable(3) = '1' THEN
--					RAM_Mas( address + 3 ) <= data( ( Data'RIGHT + RAM_WordWidth*4 - 1 ) DOWNTO ( Data'RIGHT + RAM_WordWidth*3 ) );
				
				
				Signal_SlaveState  <= AVALON_IDLE;
			
			WHEN AVALON_READ2 =>
				address           := TO_INTEGER( UNSIGNED( AVS2_address ) );
				AVS2_waitrequest   <= '1';
				AVS2_readdatavalid <= '0';
				AVS2_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_ACK_READ2;
			
			WHEN AVALON_ACK_READ2 =>
				AVS2_waitrequest   <= '0';
				AVS2_readdatavalid <= '1';
				
				FOR i IN AVS2_byteenable'RIGHT TO AVS2_byteenable'LEFT LOOP
					IF AVS2_byteenable(i) = '1' THEN
						AVS2_readdata( ( AVS2_readdata'RIGHT + ( RAM_WordWidth*(i+1) ) - 1 ) DOWNTO 
									 ( AVS2_readdata'RIGHT + RAM_WordWidth*i ) ) <= RAM_Mas( address + i );
					ELSE
						AVS2_readdata( ( AVS2_readdata'RIGHT + ( RAM_WordWidth*(i+1) ) - 1 ) DOWNTO 
									 ( AVS2_readdata'RIGHT + RAM_WordWidth*i ) ) <= ( OTHERS => '0' );
					END IF;	
				END LOOP;	
				
				--AVS2_readdata      <= RAM_Mas( address );
				
				Signal_SlaveState  <= AVALON_IDLE;
			
			END CASE;
			
		END IF;
		
	END PROCESS;
	
	
	
END logic;
