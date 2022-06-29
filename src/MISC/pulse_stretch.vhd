-- pulse stretcheer v 1.0
-- It stretch input pulse to 1 Clk cycle for PulseOut
-- PulseOut synchronous to Clk rising edge


LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY pulse_stretch IS
	PORT(
		Enable   : IN  STD_LOGIC;
		Clk      : IN  STD_LOGIC;
		PulseIn  : IN  STD_LOGIC;
		PulseOut : OUT STD_LOGIC
	);
END pulse_stretch;


ARCHITECTURE RTL OF pulse_stretch IS

	SIGNAL tmp1, tmp2 : STD_LOGIC;

BEGIN
	
	tmp1_gen: PROCESS( Enable, PulseIn, Clk )
	BEGIN
		IF Enable = '0' THEN
			tmp1 <= '0';
		ELSIF PulseIn = '1' AND tmp2 = '0' THEN
			tmp1 <= '1';
		ELSIF RISING_EDGE( Clk ) THEN
			IF tmp2 = '1' THEN
				tmp1 <= '0';
			END IF;
		END IF;
	END PROCESS;
	

	
	tmp2_gen: PROCESS( Enable, Clk )
	BEGIN
		IF Enable = '0' THEN
			tmp2 <= '0';
		ELSIF FALLING_EDGE( Clk ) THEN
			tmp2 <= tmp1;
		END IF;
	
	END PROCESS;


	
	
	out_gen: PROCESS( Enable, Clk )
	BEGIN
		IF Enable = '0' THEN
			PulseOut <= '0';
		ELSIF RISING_EDGE( Clk ) THEN
			PulseOut <= tmp2;
		END IF;
	END PROCESS;


END RTL;




