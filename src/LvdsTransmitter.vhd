LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY LvdsTransmitter IS
	
	GENERIC(
		CLOCK_RATE : STRING( 1 TO 3 ) := "SDR";
		COLOR_MODE : STRING( 1 TO 5 ) := "_SPWG"
	);
	
	PORT(
		nReset      : IN  STD_LOGIC := '0';
		
		Video_Clock : IN  STD_LOGIC;
		Video_HSync : IN  STD_LOGIC;
		Video_VSync : IN  STD_LOGIC;
		Video_Blank : IN  STD_LOGIC;
		Video_Red   : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0 );
		Video_Green : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0 );
		Video_Blue  : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0 );
		
		Lvds_Clock  : OUT STD_LOGIC;
		Lvds_Data   : OUT STD_LOGIC_VECTOR( 3 DOWNTO 0 )
	);
	
END LvdsTransmitter;

ARCHITECTURE LvdsTransmitter_RTL OF LvdsTransmitter IS
	
	COMPONENT clkctrl IS
		PORT(
			inclk  : IN  STD_LOGIC := 'X'; -- inclk
			outclk : OUT STD_LOGIC         -- outclk
		);
	END COMPONENT clkctrl;
	
	COMPONENT LvdsOutputSdrPll IS
		PORT(
			rst        : IN  STD_LOGIC := '0'; --   reset.reset
			refclk     : IN  STD_LOGIC := '0'; --  refclk.clk
			outclk_0   : OUT STD_LOGIC;        -- outclk0.clk
			outclk_1   : OUT STD_LOGIC;        -- outclk1.clk
			locked     : OUT STD_LOGIC         --     locked.export
		);
	END COMPONENT LvdsOutputSdrPll;
		
	TYPE T_LvdsShiftFull IS
		ARRAY( 0 TO 3 ) OF STD_LOGIC_VECTOR( 6 DOWNTO 0 );
	
	SIGNAL    Signal_PllReset              : STD_LOGIC;
	SIGNAL    Signal_RefClock              : STD_LOGIC;
	SIGNAL    Signal_SerialClock           : STD_LOGIC;
	SIGNAL    Signal_ParallelClock         : STD_LOGIC;
	SIGNAL    Signal_PllLocked             : STD_LOGIC;
	
	SIGNAL    Signal_HSync                 : STD_LOGIC;
	SIGNAL    Signal_VSync                 : STD_LOGIC;
	SIGNAL    Signal_Blank                 : STD_LOGIC;
	SIGNAL    Signal_Red                   : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL    Signal_Green                 : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL    Signal_Blue                  : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	
	SIGNAL    Signal_HSync_D               : STD_LOGIC;
	SIGNAL    Signal_VSync_D               : STD_LOGIC;
	SIGNAL    Signal_Blank_D               : STD_LOGIC;
	SIGNAL    Signal_Red_D                 : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL    Signal_Green_D               : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL    Signal_Blue_D                : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	
	SIGNAL    Signal_HSync_Q               : STD_LOGIC;
	SIGNAL    Signal_VSync_Q               : STD_LOGIC;
	SIGNAL    Signal_Blank_Q               : STD_LOGIC;
	SIGNAL    Signal_Red_Q                 : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL    Signal_Green_Q               : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL    Signal_Blue_Q                : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	
	SIGNAL    Signal_EncodedData           : T_LvdsShiftFull;
	
	SIGNAL    Signal_ShiftClock            : STD_LOGIC_VECTOR( 6 DOWNTO 0 );
	SIGNAL    Signal_ShiftData             : T_LvdsShiftFull;
	
BEGIN
	
	
	
	Signal_PllReset <= NOT( nReset );
	
	
	
	--LvdsClkCtrl_0 : clkctrl
	--	PORT MAP(
	--		inclk  => Video_Clock,
	--		outclk => Signal_RefClock
	--	)
	--;
	
	
	
	Signal_HSync <= Video_HSync;
	Signal_VSync <= Video_VSync;
	Signal_Blank <= Video_Blank;
	Signal_Red   <= Video_Red;
	Signal_Green <= Video_Green;
	Signal_Blue  <= Video_Blue;
	
	
	
	InputTrigger : PROCESS( Signal_ParallelClock )
	BEGIN
		
		IF( RISING_EDGE( Signal_ParallelClock ) ) THEN
			
			Signal_HSync_D <= Signal_HSync;
			Signal_VSync_D <= Signal_VSync;
			Signal_Blank_D <= Signal_Blank;
			Signal_Red_D   <= Signal_Red;
			Signal_Green_D <= Signal_Green;
			Signal_Blue_D  <= Signal_Blue;
			
			Signal_HSync_Q <= Signal_HSync_D;
			Signal_VSync_Q <= Signal_VSync_D;
			Signal_Blank_Q <= Signal_Blank_D;
			Signal_Red_Q   <= Signal_Red_D;
			Signal_Green_Q <= Signal_Green_D;
			Signal_Blue_Q  <= Signal_Blue_D;
			
		END IF;
		
	END PROCESS;
	
	
	
	Encoder_SPWG : IF( COLOR_MODE = "_SPWG" ) GENERATE
	BEGIN
		
		PROCESS( Signal_ParallelClock )
		BEGIN
			
			IF( RISING_EDGE( Signal_ParallelClock ) ) THEN
				
				Signal_EncodedData( 3 ) <= '0' & Signal_Blue_Q( 7 DOWNTO 6 ) & Signal_Green_Q( 7 DOWNTO 6 ) & Signal_Red_Q( 7 DOWNTO 6 );
				Signal_EncodedData( 2 ) <= Signal_Blank_Q & Signal_VSync_Q & Signal_HSync_Q & Signal_Blue_Q( 5 DOWNTO 2 );
				Signal_EncodedData( 1 ) <= Signal_Blue_Q( 1 DOWNTO 0 ) & Signal_Green_Q( 5 DOWNTO 1 );
				Signal_EncodedData( 0 ) <= Signal_Green_Q( 0 ) & Signal_Red_Q( 5 DOWNTO 0 );
				
			END IF;
			
		END PROCESS;
		
	END GENERATE;
	
	
	
	Encoder_JEIDA : IF( COLOR_MODE = "JEIDA" ) GENERATE
	BEGIN
		
		PROCESS( Signal_ParallelClock )
		BEGIN
			
			IF( RISING_EDGE( Signal_ParallelClock ) ) THEN
				
				Signal_EncodedData( 3 ) <= '0' & Signal_Blue_Q( 1 DOWNTO 0 ) & Signal_Green_Q( 1 DOWNTO 0 ) & Signal_Red_Q( 1 DOWNTO 0 );
				Signal_EncodedData( 2 ) <= Signal_Blank_Q & Signal_VSync_Q & Signal_HSync_Q & Signal_Blue_Q( 7 DOWNTO 4 );
				Signal_EncodedData( 1 ) <= Signal_Blue_Q( 3 DOWNTO 2 ) & Signal_Green_Q( 7 DOWNTO 3 );
				Signal_EncodedData( 0 ) <= Signal_Green_Q( 2 ) & Signal_Red_Q( 7 DOWNTO 2 );
				
			END IF;
			
		END PROCESS;
		
	END GENERATE;
	
	
	
	SerializerSDR : IF( CLOCK_RATE = "SDR" ) GENERATE
		SIGNAL Signal_Counter  : INTEGER RANGE 0 TO 6;
		SIGNAL Signal_ClockOut : STD_LOGIC;
		SIGNAL Signal_DataOut  : STD_LOGIC_VECTOR( 3 DOWNTO 0 );
	BEGIN
		
		LvdsOutputSdrPll_0 : LvdsOutputSdrPll
			PORT MAP(
				rst        => Signal_PllReset,
				refclk     => Video_Clock,
				outclk_0   => Signal_SerialClock,
				outclk_1   => Signal_ParallelClock,
				locked     => Signal_PllLocked
			)
		;
		
		PROCESS( Signal_SerialClock )
		BEGIN
			
			IF( RISING_EDGE( Signal_SerialClock ) ) THEN
				
				IF( Signal_Counter < 6 ) THEN
					
					Signal_Counter    <= ( Signal_Counter + 1 );
					Signal_ShiftClock <= Signal_ShiftClock( ( Signal_ShiftClock'LEFT - 1 ) DOWNTO Signal_ShiftClock'RIGHT ) & 'X';
					FOR I IN 0 TO 3 LOOP
						Signal_ShiftData( I ) <= Signal_ShiftData( I )( ( Signal_ShiftData( I )'LEFT - 1 ) DOWNTO Signal_ShiftData( I )'RIGHT ) & 'X';
					END LOOP;
					
				ELSE
					
					Signal_Counter    <= 0;
					Signal_ShiftClock <= "1100011";
					Signal_ShiftData  <= Signal_EncodedData;
					
				END IF;
				
			END IF;
			
		END PROCESS;
		
		PROCESS( Signal_SerialClock )
		BEGIN
			
			IF( RISING_EDGE( Signal_SerialClock ) ) THEN
				
				Signal_ClockOut <= Signal_ShiftClock( Signal_ShiftClock'LEFT );
				FOR I IN 0 TO 3 LOOP
					Signal_DataOut( I ) <= Signal_ShiftData( I )( Signal_ShiftData( I )'LEFT );
				END LOOP;
				
			END IF;
			
		END PROCESS;
		
		Lvds_Clock <= Signal_ClockOut;
		Lvds_Data  <= Signal_DataOut;
		
	END GENERATE;
	
END ARCHITECTURE LvdsTransmitter_RTL;
