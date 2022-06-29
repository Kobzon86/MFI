-- Read pointer calculator for Ring Buffer
-- Write and read sequetially accepted only!



LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY RingBuffPtr IS
	GENERIC(
		ADDR_WIDTH : INTEGER := 8;
		START_ADDR : INTEGER := 0;
		BUFF_LEN   : INTEGER := 16
	);
	
	PORT(
		Enable     : IN  STD_LOGIC;
		Clk        : IN  STD_LOGIC;
		WrEn       : IN  STD_LOGIC; -- 1 cycle pulse
		RdEn       : IN  STD_LOGIC; -- 1 cycle pulse
		RdPtr      : OUT STD_LOGIC_VECTOR( ( ADDR_WIDTH - 1 ) DOWNTO 0 );
		WordsAvail : OUT STD_LOGIC_VECTOR( ( ADDR_WIDTH - 1 ) DOWNTO 0 )
		
	);
END RingBuffPtr;




ARCHITECTURE RTL OF RingBuffPtr IS

	CONSTANT MIN_PTR  : UNSIGNED( ( ADDR_WIDTH - 1 ) DOWNTO 0 ) := TO_UNSIGNED( START_ADDR , ADDR_WIDTH );   
	CONSTANT MAX_PTR  : UNSIGNED( ( ADDR_WIDTH - 1 ) DOWNTO 0 ) := TO_UNSIGNED( START_ADDR + BUFF_LEN , ADDR_WIDTH );
	
	SIGNAL RdPtrLoc   : UNSIGNED( ( ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL WordsAvLoc : UNSIGNED( ( ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL WrPtrLoc   : UNSIGNED( ( ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL Writed     : UNSIGNED( ( ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL Empty      : STD_LOGIC := '0';	
	SIGNAL RdWas      : STD_LOGIC := '0';

BEGIN

	--RdPtr      <= STD_LOGIC_VECTOR( RdPtrLoc ) ; --WHEN ( FullWas = '1' OR RdWas = '1' ) ELSE STD_LOGIC_VECTOR( MIN_PTR );	
	--WordsAvail <= STD_LOGIC_VECTOR( WordsAvLoc );

	
	
	PtrCalc: PROCESS( Enable, Clk )
	BEGIN
		IF Enable = '0' THEN
			RdPtrLoc   <= MIN_PTR;   --MAX_PTR;
			WrPtrLoc   <= MIN_PTR;
			WordsAvLoc <= ( OTHERS => '0' );
			Empty      <= '1';
			RdWas      <= '0';
			
			
		--ELSIF FALLING_EDGE( Clk ) THEN
		ELSIF RISING_EDGE( Clk ) THEN
			RdWas <= RdEn;
			
			IF WrEn = '1' THEN
			
				Writed <= WrPtrLoc;
				Empty <= '0';
				
				IF WrPtrLoc < ( MAX_PTR - x"1" ) THEN
					WrPtrLoc <= WrPtrLoc + x"1";
				ELSE
					WrPtrLoc <= MIN_PTR;
				END IF;
				
				IF WordsAvLoc < TO_UNSIGNED( BUFF_LEN , WordsAvLoc'LENGTH ) THEN
					WordsAvLoc <= WordsAvLoc + TO_UNSIGNED( 1 , WordsAvLoc'LENGTH );
				END IF;
				
				IF ( ( Empty = '0' ) AND ( WrPtrLoc = RdPtrLoc ) ) THEN
					IF RdPtrLoc < (MAX_PTR - x"1") THEN
						RdPtrLoc <= RdPtrLoc + x"1";
					ELSE
						RdPtrLoc <= MIN_PTR;
					END IF;
				END IF;
				
			ELSIF RdEn = '1' THEN
				IF Empty = '0' THEN
					
					IF WordsAvLoc > TO_UNSIGNED( 0 , WordsAvLoc'LENGTH ) THEN
						WordsAvLoc <= WordsAvLoc - TO_UNSIGNED( 1 , WordsAvLoc'LENGTH );
					
						IF RdPtrLoc < (MAX_PTR - x"1") THEN
							RdPtrLoc <= RdPtrLoc + "1";
						ELSE
							RdPtrLoc <= MIN_PTR;
						END IF;
					ELSE
						Empty <= '1';
					END IF;
				
				END IF;
			END IF;

			
			IF ( ( RdWas = '1' ) AND ( WordsAvLoc = TO_UNSIGNED( 0 , WordsAvLoc'LENGTH ) ) ) THEN
				Empty <= '1';
			END IF;
			
			
			IF RdPtrLoc >= MAX_PTR THEN
				RdPtrLoc <= MIN_PTR;
			END IF;

			
			IF WrPtrLoc >= MAX_PTR THEN
				WrPtrLoc <= MIN_PTR;
			END IF;

		ELSIF FALLING_EDGE( Clk ) THEN
			RdPtr      <= STD_LOGIC_VECTOR( RdPtrLoc ) ; --WHEN ( FullWas = '1' OR RdWas = '1' ) ELSE STD_LOGIC_VECTOR( MIN_PTR );	
			WordsAvail <= STD_LOGIC_VECTOR( WordsAvLoc );
		END IF;
		
		
	
	END PROCESS;
	
	
END RTL;
