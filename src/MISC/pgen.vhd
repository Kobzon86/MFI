-- Pulse Generator v 1.0
-- Generate Output pulse with one clock cycle width
-- and DELAY for 2 CLOCK CYCLES
-- Output by rising edge of Clock
-- Input Signal pulse must be wider than one clock cycle
-- Parameter Edge have values: 
-- 1 = "generate output pulse byrising edge" or 
-- 0 = "generate output pulse by falling edge"


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY pgen IS
	GENERIC(
		Edge : STD_LOGIC
	);
	PORT(
		Enable : IN  STD_LOGIC;
		Clk    : IN  STD_LOGIC;
		Input  : IN  STD_LOGIC;
		Output : OUT STD_LOGIC
	);
END pgen;


ARCHITECTURE RTL OF pgen IS
	SIGNAL i1,i2 : STD_LOGIC := '0';

BEGIN

	PROCESS( Enable, Clk )
	BEGIN
		IF Enable = '0' THEN

			IF Edge = '1' THEN
				i1 <= '0';
				i2 <= '0';
			ELSE
				i1 <= '1';
				i2 <= '1';
				
			END IF;
			Output <= '0';
			
		ELSIF RISING_EDGE( Clk ) THEN
			
			IF Edge = '1' THEN
				i1 <= Input;
			ELSE
				i1 <= NOT Input;
			END IF;
			
			i2     <= i1;
			Output <= ( i1 AND ( NOT i2 ) );

		END IF;
	
	END PROCESS;

END RTL;
