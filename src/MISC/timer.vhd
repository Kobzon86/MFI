-- timer v0.2

-- Minimal time = 1 period of CLK
-- IF TIME = 0 then READY pulse interval = 1 period of CLK 
-- IF TIME = 1 and greater then READY pulse interval equal TIME value
-- input ARST is asynchronous reset- narrow pulse
-- input Single switch between single work and continuous multicycle work
-- Input Time value in number of Cycle Clk_x16



LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY timer IS
	PORT(
		Enable   : IN  STD_LOGIC;
		Clk_x16  : IN  STD_LOGIC;
		Time     : IN  STD_LOGIC_VECTOR( 19 DOWNTO 0 );
		ARST     : IN  STD_LOGIC;
		Single   : IN  STD_LOGIC; -- 1 = Single, 0 - continuous work
		Ready    : OUT STD_LOGIC
	);
	
END timer;



ARCHITECTURE RTL OF timer IS
	CONSTANT ZeroTime  : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL TimeMax     : UNSIGNED( 19 DOWNTO 0 ) := ( OTHERS => '1' );
	SIGNAL TimeVal     : UNSIGNED( 19 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL TimerReady  : STD_LOGIC := '0';
	SIGNAL Reset       : STD_LOGIC := '0';
	SIGNAL StretchRST  : STD_LOGIC := '0';
	SIGNAL RST_Latched : STD_LOGIC := '0';
	SIGNAL TempRST     : STD_LOGIC := '0';
	SIGNAL tmp1, tmp2  : STD_LOGIC := '0';
	

BEGIN

	
--	Ready <= TimerReady AND ( NOT Clk_x16 );
	
	Ready <= tmp1 AND ( NOT tmp2 ) WHEN Enable = '1' ELSE '0';
		
	TimeLatch: PROCESS( Clk_x16 )
	BEGIN
		IF Enable = '0' THEN
			TimeMax <= x"00001";
		ELSIF RISING_EDGE( Clk_x16 ) THEN
			IF Time /= ZeroTime THEN
				TimeMax <= ( UNSIGNED( Time ) );
			ELSE
				TimeMax <= x"00001";
			END IF;
		END IF;
	END PROCESS;
	
	
	
	RstStretcher: PROCESS( Enable, ARST, RST_Latched )
	BEGIN
		IF Enable = '0' THEN
			StretchRST <= '0';
		ELSIF  ARST = '1' THEN 
			StretchRST <= '1';
		ELSIF RST_Latched = '1' THEN
			StretchRST <= '0';
		END IF;
	END PROCESS;


	
	RstLatcher: PROCESS( Enable, Clk_x16 )
	BEGIN
		IF Enable = '0' THEN
			RST_Latched <= '0';
		ELSIF RISING_EDGE( Clk_x16 ) THEN
			RST_Latched <= StretchRST;		
		END IF;
	END PROCESS;
	
	
	
	RstEdgeDetect: PROCESS( Enable, Clk_x16 )
	BEGIN
		IF Enable = '0' THEN
			Reset <= '1';
			tmp1  <= '0';
			tmp2  <= '0';
			
		ELSIF FALLING_EDGE( Clk_x16 ) THEN
			
			Reset <= RST_Latched;
			tmp1  <= TimerReady;
			tmp2  <= tmp1;
			
		END IF;
	
	END PROCESS;
	
	
	TimerPrc: PROCESS( Enable, Clk_x16 )
	BEGIN
		IF Enable = '0' THEN
			TimeVal <= x"00001";
			TimerReady   <= '0';
				
		ELSIF RISING_EDGE( Clk_x16 ) THEN
	
			IF Reset = '1' THEN
				TimeVal    <= x"00001";
				TimerReady <= '0';
			
			ELSIF TimeVal < ( TimeMax - 1 ) THEN
				TimerReady   <= '0';
				TimeVal <= TimeVal + 1;
			ELSE
				TimerReady   <= '1';
				IF Single = '0' THEN
					TimeVal <= ( OTHERS => '0' );	
				END IF;
			END IF;
			
		END IF;
	END PROCESS;



END RTL;

