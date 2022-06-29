-- Clock divider v 1.0

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY clk_divider IS
	GENERIC(
		DivTimes : INTEGER := 4
	);
	PORT(
		Enable : IN  STD_LOGIC;
		ClkIn  : IN  STD_LOGIC;
		ClkOut : OUT STD_LOGIC
	);
END clk_divider;


ARCHITECTURE RTL OF clk_divider IS

	SIGNAL DivCnt : INTEGER RANGE 0 TO DivTimes;
	SIGNAL DivClk : STD_LOGIC;

BEGIN

	ClkOut <= DivClk;

	PROCESS( Enable, ClkIn )
	BEGIN
		IF Enable = '0' THEN
			DivClk <= '0';
			DivCnt <= 0;
		ELSIF RISING_EDGE( ClkIn ) THEN
			IF DivTimes <= 2 THEN
				DivClk <= NOT DivClk;
			ELSE
				IF ( DivCnt < ( DivTimes/2 ) ) THEN
					DivCnt <= DivCnt + 1;
					DivClk <= '0';
				ELSIF ( DivCnt < ( DivTimes - 1 ) ) THEN
					DivCnt <= DivCnt + 1;
					DivClk <= '1';
				ELSE
					DivCnt <= 0;
				END IF;
				
			END IF;
		
		END IF;
		
		
	
	END PROCESS;
	

END RTL;


