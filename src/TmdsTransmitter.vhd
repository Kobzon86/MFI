-- 
-- Constraints:
-- set_multicycle_path -from {TmdsTransmitter*|Signal_*_D*} -to {*|tmds_encoder_dvi*o_tmds[*]} -setup -end 2
-- set_clock_groups -logically_exclusive \
--                  -group [get_clocks {*|TmdsOutputSdrPll_0|*|counter[0].output_counter|divclk}] \
--                  -group [get_clocks {*|TmdsOutputSdrPll_0|*|counter[1].output_counter|divclk}] \
--                  -group [get_clocks {int_osc}] \
--                  -group [get_clocks {si5332_clk1_p}]
-- 

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

--USE work.VideoStreamPackage.ALL;

ENTITY TmdsTransmitter IS
	GENERIC(
		CLOCK_RATE : STRING( 1 TO 3 ) := "SDR"
	);
	PORT(
		nReset            : IN  STD_LOGIC := '0';
		
		Video_Clock       : IN  STD_LOGIC;
		Video_HSync       : IN  STD_LOGIC;
		Video_VSync       : IN  STD_LOGIC;
		Video_Blank       : IN  STD_LOGIC;
		Video_Red         : IN  STD_LOGIC_VECTOR(  7 DOWNTO 0 );
		Video_Green       : IN  STD_LOGIC_VECTOR(  7 DOWNTO 0 );
		Video_Blue        : IN  STD_LOGIC_VECTOR(  7 DOWNTO 0 );
		
		Tmds_ClockOut     : OUT STD_LOGIC;
		Tmds_DataOut      : OUT STD_LOGIC_VECTOR(  2 DOWNTO 0 )
	);
	
END TmdsTransmitter;

ARCHITECTURE TmdsTransmitter_RTL OF TmdsTransmitter IS
	
	COMPONENT TmdsOutputSdrPll IS
	PORT(
		rst      : IN  STD_LOGIC := '0'; --   reset.reset
		refclk   : IN  STD_LOGIC := '0'; --  refclk.clk
		outclk_0 : OUT STD_LOGIC;        -- outclk0.clk
		outclk_1 : OUT STD_LOGIC;        -- outclk1.clk
		locked   : OUT STD_LOGIC         --  locked.export
	);
	END COMPONENT TmdsOutputSdrPll;
		
	COMPONENT tmds_encoder_dvi IS
		PORT(
			i_clk  : IN  STD_LOGIC;
			i_rst  : IN  STD_LOGIC;
			i_de   : IN  STD_LOGIC;
			i_ctrl : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			i_data : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			o_tmds : OUT STD_LOGIC_VECTOR( 9 DOWNTO 0 )
		);
	END COMPONENT tmds_encoder_dvi;
	
	SIGNAL   Signal_Ctrl                 : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL   Signal_RedEncoded           : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL   Signal_GreenEncoded         : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL   Signal_BlueEncoded          : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	
	SIGNAL   Signal_ClockShift           : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL   Signal_RedShift             : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL   Signal_GreenShift           : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL   Signal_BlueShift            : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	
	SIGNAL   Signal_nReset               : STD_LOGIC;

	SIGNAL   Signal_Red_D                : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL   Signal_Green_D              : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL   Signal_Blue_D               : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL   Signal_HSync_D 			 : STD_LOGIC;
	SIGNAL   Signal_VSync_D 			 : STD_LOGIC;
	SIGNAL   Signal_Blank_D 			 : STD_LOGIC;

	SIGNAL Signal_SerialClock : STD_LOGIC;
	SIGNAL Signal_PllLocked : STD_LOGIC;
	SIGNAL Signal_ParClock : STD_LOGIC;
	
BEGIN
	
	TmdsOutputSdrPll_0 : TmdsOutputSdrPll
	PORT MAP(
		rst      => '0',
		refclk   => Video_Clock,
		outclk_0 => Signal_SerialClock,
		outclk_1 => Signal_ParClock,
		locked   => Signal_PllLocked
	);
	
	PROCESS( Video_Clock)
	BEGIN
		IF( RISING_EDGE( Video_Clock ) ) THEN    
			Signal_Red_D   <= Video_Red  ;
			Signal_Green_D <= Video_Green;
			Signal_Blue_D  <= Video_Blue ;
			Signal_HSync_D <= Video_HSync;
			Signal_VSync_D <= Video_VSync;
			Signal_Blank_D <= Video_Blank;
		END IF;
	END PROCESS;

	OutputDelay : PROCESS( nReset, Video_Clock )
		CONSTANT DELAY      : INTEGER := 2600000;
		VARIABLE delayTimer : INTEGER RANGE 0 TO ( DELAY - 1 );
	BEGIN
		
		IF( nReset = '0' ) THEN	
			
			delayTimer    := 0;
			Signal_nReset <= '0';
			
		ELSIF( RISING_EDGE( Video_Clock ) ) THEN
			
			IF( delayTimer < ( DELAY - 1 ) ) THEN
				delayTimer    := ( delayTimer + 1 );
				Signal_nReset <= '0';
			ELSE
				Signal_nReset <= '1';
			END IF;
			
		END IF;
		
	END PROCESS;

	
	
	-- 8b->10b encoders
	
	Signal_Ctrl <= ( 1 => Signal_VSync_D, 0 => Signal_HSync_D );
  
	TmdsEncoder_Red : tmds_encoder_dvi
		PORT MAP(
			i_rst 	=> NOT nReset,
			i_clk 	=> Signal_ParClock,
			i_data	=> Signal_Red_D,
			i_ctrl	=> ( OTHERS => '0' ),
			i_de  	=> Signal_Blank_D,
			o_tmds	=> Signal_RedEncoded
		)
	;
	
	TmdsEncoder_Green : tmds_encoder_dvi
		PORT MAP(
			i_rst 	=> NOT nReset,
			i_clk 	=> Signal_ParClock,
			i_data	=> Signal_Green_D,
			i_ctrl	=> ( OTHERS => '0' ),
			i_de  	=> Signal_Blank_D,
			o_tmds	=> Signal_GreenEncoded
		)
	;
	
	TmdsEncoder_Blue : tmds_encoder_dvi
		PORT MAP(
			i_rst 	=> NOT nReset,
			i_clk 	=> Signal_ParClock,
			i_data	=> Signal_Blue_D,
			i_ctrl	=> Signal_Ctrl,
			i_de  	=> Signal_Blank_D,
			o_tmds	=> Signal_BlueEncoded
		)
	;
	
	
	
	-- SDR serializer
	
	SerializerSDR : IF( CLOCK_RATE = "SDR" ) GENERATE
		SIGNAL Signal_Counter  : INTEGER RANGE 0 TO 9;
		SIGNAL Signal_ClockOut : STD_LOGIC;
		SIGNAL Signal_DataOut  : STD_LOGIC_VECTOR( 2 DOWNTO 0 );
	BEGIN
		
		PROCESS( Signal_nReset, Signal_SerialClock )
		BEGIN
			
			IF( Signal_nReset = '0' ) THEN	
				
				Signal_Counter    <= 0;
				
				Signal_ClockShift <= ( OTHERS => 'X' );
				Signal_RedShift   <= ( OTHERS => 'X' );
				Signal_GreenShift <= ( OTHERS => 'X' );
				Signal_BlueShift  <= ( OTHERS => 'X' );
				
				Signal_ClockOut   <= 'X';
				Signal_DataOut    <= ( OTHERS => 'X' );
				
			ELSIF( RISING_EDGE( Signal_SerialClock ) ) THEN
				
				IF( Signal_Counter < 9 ) THEN
					
					Signal_Counter    <= ( Signal_Counter + 1 );
					
					Signal_ClockShift <= 'X' & Signal_ClockShift( 9 DOWNTO 1 );
					Signal_RedShift   <= 'X' & Signal_RedShift(   9 DOWNTO 1 );
					Signal_GreenShift <= 'X' & Signal_GreenShift( 9 DOWNTO 1 );
					Signal_BlueShift  <= 'X' & Signal_BlueShift(  9 DOWNTO 1 );
					
				ELSE
					
					Signal_Counter    <= 0;
					
					Signal_ClockShift <= "1111100000";
					Signal_RedShift   <= Signal_RedEncoded;
					Signal_GreenShift <= Signal_GreenEncoded;
					Signal_BlueShift  <= Signal_BlueEncoded;
					
				END IF;
				
				Signal_ClockOut <= Signal_ClockShift( 0 );
				Signal_DataOut  <= Signal_RedShift( 0 ) & Signal_GreenShift( 0 ) & Signal_BlueShift( 0 );
				
			END IF;
			
		END PROCESS;
		
		Tmds_ClockOut <= Signal_ClockOut;
		Tmds_DataOut  <= Signal_DataOut;
		
	END GENERATE;
	
END ARCHITECTURE TmdsTransmitter_RTL;
