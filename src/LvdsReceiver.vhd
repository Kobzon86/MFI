LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

LIBRARY altera_mf;
USE altera_mf.all;
USE altera_mf.altera_mf_components.all;

ENTITY LvdsReceiver IS
	
	GENERIC(
		FAMILY     : STRING( 1 TO 11 ) := "__Cyclone_V";
		CLOCK_RATE : STRING( 1 TO  3 ) := "DDR";
		COLOR_MODE : STRING( 1 TO  5 ) := "JEIDA"
	);
	
	PORT(
		nReset        : IN  STD_LOGIC := '0';
		Freerun_Clock : IN  STD_LOGIC;
		Serial_Clock  : IN  STD_LOGIC;
		Serial_Data   : IN  STD_LOGIC_VECTOR( 3 DOWNTO 0 );
		Video_Clock   : OUT STD_LOGIC;
		Video_HSync   : OUT STD_LOGIC;
		Video_VSync   : OUT STD_LOGIC;
		Video_Blank   : OUT STD_LOGIC;
		Video_Red     : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
		Video_Green   : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
		Video_Blue    : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
		Video_Locked  : OUT STD_LOGIC
	);
	
END LvdsReceiver;

ARCHITECTURE LvdsReceiver_RTL OF LvdsReceiver IS
	
	CONSTANT  MIN_SYNC_LENGTH  : INTEGER := 32;
	CONSTANT  MAX_SHIFT_STEPS  : INTEGER := 16;
	CONSTANT  IDLE_TIMEOUT     : INTEGER := 4096;
	
	COMPONENT altclkctrl IS
		GENERIC(
			clock_type                                 : string  := "AUTO";
			intended_device_family                     : string  := "UNUSED";
			ena_register_mode                          : string  := "falling edge";
			implement_in_les                           : string  := "OFF";
			number_of_clocks                           : natural := 4;
			use_glitch_free_switch_over_implementation : string  := "OFF";
			width_clkselect                            : natural := 2;
			lpm_hint                                   : string  := "UNUSED";
			lpm_type                                   : string  := "altclkctrl"
		);
		PORT(
			clkselect : IN  STD_LOGIC_VECTOR( ( width_clkselect - 1 ) DOWNTO 0 )  := ( OTHERS => '0' );
			ena       : IN  STD_LOGIC := '1';
			inclk     : IN  STD_LOGIC_VECTOR( ( number_of_clocks - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
			outclk    : OUT STD_LOGIC
		);
	END COMPONENT altclkctrl;
	
	COMPONENT altsource_probe IS
		GENERIC(
			enable_metastability    : STRING  := "NO";
			instance_id             : STRING  := "UNUSED";
			lpm_hint                : STRING  := "altsource_probe";
			lpm_type                : STRING  := "altsource_probe";
			probe_width             : NATURAL := 1;
			sld_auto_instance_index : STRING  := "YES";
			sld_instance_index      : NATURAL := 0;
			source_initial_value    : STRING  := "0";
			source_width            : NATURAL := 1
		);
		PORT(
			probe      : IN  STD_LOGIC_VECTOR( ( PROBE_WIDTH - 1 )  DOWNTO 0 ) := ( OTHERS => '0' );
			source     : OUT STD_LOGIC_VECTOR( ( SOURCE_WIDTH - 1 ) DOWNTO 0 );
			source_clk : IN  STD_LOGIC := '0';
			source_ena : IN  STD_LOGIC := '1'
		);
	END COMPONENT altsource_probe;
	
	TYPE T_SerialShiftHalf IS
		ARRAY( 0 TO 3 ) OF STD_LOGIC_VECTOR( 3 DOWNTO 0 );
	
	TYPE T_SerialShiftFull IS
		ARRAY( 0 TO 3 ) OF STD_LOGIC_VECTOR( 6 DOWNTO 0 );
	
	TYPE T_PhaseState IS (
		STATE_IDLE,
		STATE_BLANK,
		STATE_SHIFT,
		STATE_DONE,
		STATE_RESET
	);
	
	ATTRIBUTE syn_encoding                 : STRING;
	ATTRIBUTE syn_encoding OF T_PhaseState : TYPE IS "one-hot, safe";
	
	SIGNAL    Signal_InClkSel              : STD_LOGIC_VECTOR(  0 DOWNTO 0 );
	SIGNAL    Signal_InClock               : STD_LOGIC_VECTOR(  0 DOWNTO 0 );
	SIGNAL    Signal_RefClock              : STD_LOGIC;
	
	SIGNAL    Signal_Pll_Reset             : STD_LOGIC;
	SIGNAL    Signal_Pll_RefClk            : STD_LOGIC_VECTOR(  1 DOWNTO 0 );
	SIGNAL    Signal_Pll_OutClk            : STD_LOGIC_VECTOR( 17 DOWNTO 0 );
	SIGNAL    Signal_Pll_Locked            : STD_LOGIC;
	
	SIGNAL    Signal_PllStep               : STD_LOGIC;
	SIGNAL    Signal_PllUpDown             : STD_LOGIC;
	SIGNAL    Signal_PllCntSel             : STD_LOGIC_VECTOR(  4 DOWNTO 0 );
	
	SIGNAL    Signal_Pll_Step              : STD_LOGIC;
	SIGNAL    Signal_Pll_UpDown            : STD_LOGIC;
	SIGNAL    Signal_Pll_CntSel            : STD_LOGIC_VECTOR(  4 DOWNTO 0 );
	SIGNAL    Signal_Pll_Done              : STD_LOGIC;
	SIGNAL    Signal_Pll_C0Cnt             : STD_LOGIC_VECTOR(  4 DOWNTO 0 );
	SIGNAL    Signal_Pll_C1Cnt             : STD_LOGIC_VECTOR(  4 DOWNTO 0 );
	SIGNAL    Signal_SyncCounter           : INTEGER RANGE 0 TO ( MIN_SYNC_LENGTH - 1 );
	SIGNAL    Signal_ShiftCounter          : INTEGER RANGE 0 TO MAX_SHIFT_STEPS;
	SIGNAL    Signal_Timeout               : INTEGER RANGE 0 TO ( IDLE_TIMEOUT - 1 );
	SIGNAL    Signal_VSync_Check		      : STD_LOGIC;
	SIGNAL    Signal_PhaseState            : T_PhaseState;
	
	SIGNAL    Signal_FastClock             : STD_LOGIC;
	SIGNAL    Signal_SlowClock             : STD_LOGIC;
	
	SIGNAL    Signal_Data_Meta             : T_SerialShiftFull;
	SIGNAL    Signal_Data_Latch            : T_SerialShiftFull;
	
	SIGNAL    Signal_HSync                 : STD_LOGIC;
	SIGNAL    Signal_VSync                 : STD_LOGIC;
	SIGNAL    Signal_Blank                 : STD_LOGIC;
	SIGNAL    Signal_Red                   : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
	SIGNAL    Signal_Green                 : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
	SIGNAL    Signal_Blue                  : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
	
	SIGNAL    Signal_VideoLocked           : STD_LOGIC;
	SIGNAL    Signal_Video_Locked          : STD_LOGIC;
	
	attribute noprune 							: BOOLEAN;
	attribute noprune OF Signal_HSync      : SIGNAL IS TRUE;
	attribute noprune OF Signal_VSync      : SIGNAL IS TRUE;
	attribute noprune OF Signal_Blank      : SIGNAL IS TRUE;
	attribute noprune OF Signal_Red        : SIGNAL IS TRUE;
	attribute noprune OF Signal_Green      : SIGNAL IS TRUE;
	attribute noprune OF Signal_Blue       : SIGNAL IS TRUE;
	
	SIGNAL    Signal_Source                : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	
BEGIN
	
	
	
	Signal_Video_Locked <= Signal_Source( 8 )          WHEN( Signal_Source( 9 ) = '1' ) ELSE Signal_VideoLocked;
	Signal_Pll_Reset    <= Signal_Source( 7 )          WHEN( Signal_Source( 9 ) = '1' ) ELSE NOT( nReset );
	Signal_Pll_Step     <= Signal_Source( 6 )          WHEN( Signal_Source( 9 ) = '1' ) ELSE Signal_PllStep;
	Signal_Pll_UpDown   <= Signal_Source( 5 )          WHEN( Signal_Source( 9 ) = '1' ) ELSE Signal_PllUpDown;
	Signal_Pll_CntSel   <= Signal_Source( 4 DOWNTO 0 ) WHEN( Signal_Source( 9 ) = '1' ) ELSE Signal_PllCntSel;
	
	altsource_probe_0 : altsource_probe
		GENERIC MAP(
			enable_metastability    => "NO",
			instance_id             => "LVDS",
			lpm_hint                => "altsource_probe",
			lpm_type                => "altsource_probe",
			probe_width             => 0,
			sld_auto_instance_index => "YES",
			sld_instance_index      => 0,
			source_initial_value    => "0",
			source_width            => 10
		)
		PORT MAP(
			source_ena => '1',
			source_clk => Freerun_Clock,
			source     => Signal_Source,
			probe      => OPEN
		)
	;
	
	
	
	Signal_InClkSel  <= ( 0 => '0' );
	Signal_InClock   <= ( 0 => Serial_Clock );
	
	Signal_Pll_RefClk <= ( 0 => Signal_RefClock, 1 => '0' );
	Signal_FastClock  <= Signal_Pll_OutClk( 0 );
	Signal_SlowClock  <= Signal_Pll_OutClk( 1 );
	
	CycloneV_Family : IF( FAMILY = "__Cyclone_V" ) GENERATE
		
		COMPONENT LvdsInputSdrPll IS
			PORT(
				refclk     : IN  STD_LOGIC                      := '0';               --     refclk.clk
				rst        : IN  STD_LOGIC                      := '0';               --      reset.reset
				outclk_0   : OUT STD_LOGIC;                                           --    outclk0.clk
				outclk_1   : OUT STD_LOGIC;                                           --    outclk1.clk
				locked     : OUT STD_LOGIC;                                           --     locked.export
				phase_en   : IN  STD_LOGIC                      := '0';               --   phase_en.phase_en
				scanclk    : IN  STD_LOGIC                      := '0';               --    scanclk.scanclk
				updn       : IN  STD_LOGIC                      := '0';               --       updn.updn
				cntsel     : IN  STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := ( OTHERS => '0' ); --     cntsel.cntsel
				phase_done : OUT STD_LOGIC                                            -- phase_done.phase_done
			);
		END COMPONENT LvdsInputSdrPll;
		
		COMPONENT LvdsInputDdrPll IS
			PORT(
				refclk     : IN  STD_LOGIC                      := '0';               --     refclk.clk
				rst        : IN  STD_LOGIC                      := '0';               --      reset.reset
				outclk_0   : OUT STD_LOGIC;                                           --    outclk0.clk
				outclk_1   : OUT STD_LOGIC;                                           --    outclk1.clk
				locked     : OUT STD_LOGIC;                                           --     locked.export
				phase_en   : IN  STD_LOGIC                      := '0';               --   phase_en.phase_en
				scanclk    : IN  STD_LOGIC                      := '0';               --    scanclk.scanclk
				updn       : IN  STD_LOGIC                      := '0';               --       updn.updn
				cntsel     : IN  STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := ( OTHERS => '0' ); --     cntsel.cntsel
				phase_done : OUT STD_LOGIC                                            -- phase_done.phase_done
			);
		END COMPONENT LvdsInputDdrPll;
		
	BEGIN
		
		LvdsClkCtrl : altclkctrl
			GENERIC MAP(
				clock_type                                 => "AUTO",
				ena_register_mode                          => "falling edge",
				lpm_hint                                   => "UNUSED",
				lpm_type                                   => "LvdsClkCtrl",
				intended_device_family                     => "UNUSED",
				implement_in_les                           => "OFF",
				number_of_clocks                           => 1,
				use_glitch_free_switch_over_implementation => "OFF",
				width_clkselect                            => 1
			)
			PORT MAP(
				ena       => '1',
				clkselect => Signal_InClkSel,
				inclk     => Signal_InClock,
				outclk    => Signal_RefClock
			)
		;
		
		SDR_Pll : IF( CLOCK_RATE = "SDR" ) GENERATE
		BEGIN
			
			serial_input_pll : LvdsInputSdrPll
				PORT MAP(
					rst        => Signal_Pll_Reset,
					refclk     => Signal_Pll_RefClk( 0 ),
					outclk_0   => Signal_Pll_OutClk( 0 ),
					outclk_1   => Signal_Pll_OutClk( 1 ),
					locked     => Signal_Pll_Locked,
					scanclk    => Signal_Pll_RefClk( 0 ),
					phase_en   => Signal_Pll_Step,
					updn       => Signal_Pll_UpDown,
					cntsel     => Signal_Pll_CntSel,
					phase_done => Signal_Pll_Done
				)
			;
			
		END GENERATE;
		
--		DDR_Pll : IF( CLOCK_RATE = "DDR" ) GENERATE
--		BEGIN
--			
--			serial_input_pll : LvdsInputDdrPll
--				PORT MAP(
--					rst        => Signal_Pll_Reset,
--					refclk     => Signal_Pll_RefClk( 0 ),
--					outclk_0   => Signal_Pll_OutClk( 0 ),
--					outclk_1   => Signal_Pll_OutClk( 1 ),
--					locked     => Signal_Pll_Locked,
--					scanclk    => Signal_Pll_RefClk( 0 ),
--					phase_en   => Signal_Pll_Step,
--					updn       => Signal_Pll_UpDown,
--					cntsel     => Signal_Pll_CntSel,
--					phase_done => Signal_Pll_Done
--				)
--			;
--			
--		END GENERATE;
		
		Signal_Pll_C0Cnt <= "00000";
		Signal_Pll_C1Cnt <= "00001";
		
	END GENERATE;
	
	
	
	SDR_ShiftRegister : IF( CLOCK_RATE = "SDR" ) GENERATE
		SIGNAL Signal_SerialData       : STD_LOGIC_VECTOR( 3 DOWNTO 0 );
		SIGNAL Signal_SerialData_Meta  : STD_LOGIC_VECTOR( 3 DOWNTO 0 );
		SIGNAL Signal_SerialData_Latch : STD_LOGIC_VECTOR( 3 DOWNTO 0 );
		SIGNAL Signal_Data_Shift       : T_SerialShiftFull;
	BEGIN
		
--		ALTDDIO_IN_component : ALTDDIO_IN
--			GENERIC MAP (
--				intended_device_family => "Cyclone V",
--				invert_input_clocks    => "OFF",
--				lpm_hint               => "UNUSED",
--				lpm_type               => "altddio_in",
--				power_up_high          => "OFF",
--				width                  => 4
--			)
--			PORT MAP (
--				datain    => Serial_Data,
--				inclock   => Signal_FastClock,
--				dataout_h => Signal_SerialData
--			)
--		;
		
		PROCESS( Signal_FastClock )
		BEGIN
			
			IF( RISING_EDGE( Signal_FastClock ) ) THEN
				
				IF( Signal_Pll_Locked = '1' ) THEN
					
					Signal_SerialData_Meta  <= Serial_Data;
					Signal_SerialData_Latch <= Signal_SerialData_Meta;
					
				END IF;
				
			END IF;
			
		END PROCESS;
		
		PROCESS( Signal_FastClock )
		BEGIN
			
			IF( RISING_EDGE( Signal_FastClock ) ) THEN
				
				IF( Signal_Pll_Locked = '1' ) THEN
					
					FOR I IN 0 TO 3 LOOP
						Signal_Data_Shift( I ) <= Signal_Data_Shift( I )( ( Signal_Data_Shift( I )'LEFT - 1 ) DOWNTO Signal_Data_Shift( I )'RIGHT ) & Signal_SerialData_Latch( I );
					END LOOP;
					
				END IF;
				
			END IF;
			
		END PROCESS;
		
		PROCESS( Signal_SlowClock )
		BEGIN
			
			IF( RISING_EDGE( Signal_SlowClock ) ) THEN
				
				IF( Signal_Pll_Locked = '1' ) THEN
					
					Signal_Data_Meta  <= Signal_Data_Shift;
					Signal_Data_Latch <= Signal_Data_Meta;
					
				END IF;
				
			END IF;
			
		END PROCESS;
		
	END GENERATE;
	
	
	
	Decoder_JEIDA : IF( COLOR_MODE = "JEIDA" ) GENERATE
		
		PROCESS( Signal_SlowClock )
		BEGIN
			
			IF( RISING_EDGE( Signal_SlowClock ) ) THEN
				
				IF( Signal_Pll_Locked = '0' ) THEN
					
					Signal_HSync <= '0';
					Signal_VSync <= '0';
					Signal_Blank <= '0';
					Signal_Red   <= ( OTHERS => '0' );
					Signal_Green <= ( OTHERS => '0' );
					Signal_Blue  <= ( OTHERS => '0' );			
					
				ELSE
					
					Signal_HSync <= Signal_Data_Latch( 2 )( 4 );
					Signal_VSync <= Signal_Data_Latch( 2 )( 5 );
					Signal_Blank <= Signal_Data_Latch( 2 )( 6 );
					Signal_Red   <= Signal_Data_Latch( 0 )( 5 DOWNTO 0 )                                        & Signal_Data_Latch( 3 )( 1 DOWNTO 0 );
					Signal_Green <= Signal_Data_Latch( 1 )( 4 DOWNTO 0 ) & Signal_Data_Latch( 0 )( 6 )          & Signal_Data_Latch( 3 )( 3 DOWNTO 2 );
					Signal_Blue  <= Signal_Data_Latch( 2 )( 3 DOWNTO 0 ) & Signal_Data_Latch( 1 )( 6 DOWNTO 5 ) & Signal_Data_Latch( 3 )( 5 DOWNTO 4 );
					
				END IF;
				
			END IF;
			
		END PROCESS;
		
	END GENERATE;
	
	
	
	Decoder_SPWG : IF( COLOR_MODE = "_SPWG" ) GENERATE
		
		PROCESS( Signal_SlowClock )
		BEGIN
			
			IF( RISING_EDGE( Signal_SlowClock ) ) THEN
				
				IF( Signal_Pll_Locked = '0' ) THEN
					
					Signal_HSync <= '0';
					Signal_VSync <= '0';
					Signal_Blank <= '0';
					Signal_Red   <= ( OTHERS => '0' );
					Signal_Green <= ( OTHERS => '0' );
					Signal_Blue  <= ( OTHERS => '0' );			
					
				ELSE
					
					Signal_HSync <= Signal_Data_Latch( 2 )( 4 );
					Signal_VSync <= Signal_Data_Latch( 2 )( 5 );
					Signal_Blank <= Signal_Data_Latch( 2 )( 6 );
					Signal_Red   <= Signal_Data_Latch( 3 )( 1 DOWNTO 0 ) & Signal_Data_Latch( 0 )( 5 DOWNTO 0 );
					Signal_Green <= Signal_Data_Latch( 3 )( 3 DOWNTO 2 ) & Signal_Data_Latch( 1 )( 4 DOWNTO 0 ) & Signal_Data_Latch( 0 )( 6 );
					Signal_Blue  <= Signal_Data_Latch( 3 )( 5 DOWNTO 4 ) & Signal_Data_Latch( 2 )( 3 DOWNTO 0 ) & Signal_Data_Latch( 1 )( 6 DOWNTO 5 );				
					
				END IF;
				
			END IF;
			
		END PROCESS;
		
	END GENERATE;
	
	
	
	CheckLink : PROCESS( Signal_SlowClock )
	BEGIN
		
		IF( RISING_EDGE( Signal_SlowClock ) ) THEN
			
			IF( Signal_Pll_Locked = '0' ) THEN
				
				Signal_PllStep      <= '0';
				Signal_PllUpDown    <= '0';
				Signal_PllCntSel    <= ( OTHERS => 'X' );
				Signal_SyncCounter  <= 0;
				Signal_ShiftCounter <= 0;
				Signal_Timeout      <= 0;
				Signal_VideoLocked  <= '0';
				Signal_PhaseState   <= STATE_RESET;
				Signal_VSync_Check  <= '0';
				
			ELSE
				
				CASE Signal_PhaseState IS
				
				WHEN STATE_IDLE =>
					IF( Signal_Timeout < ( IDLE_TIMEOUT - 1 ) ) THEN
						IF( ( Signal_HSync = '0' ) AND ( Signal_Blank = '0' ) ) THEN
							Signal_PhaseState  <= STATE_BLANK;
							Signal_VSync_Check <= Signal_VSync;
						END IF;
						Signal_Timeout <= ( Signal_Timeout + 1 );
					ELSE
						Signal_VideoLocked <= '0';
						Signal_PhaseState  <= STATE_SHIFT;
					END IF;
					Signal_PllStep   <= '0';
					Signal_PllUpDown <= '0';
					Signal_PllCntSel <= ( OTHERS => 'X' );
				
				WHEN STATE_BLANK =>
					IF( Signal_Timeout < ( IDLE_TIMEOUT - 1 ) ) THEN
						IF( ( Signal_HSync = '0' ) AND ( Signal_Blank = '0' ) ) THEN
							IF( Signal_SyncCounter < ( MIN_SYNC_LENGTH - 1 ) ) THEN
								Signal_SyncCounter <= ( Signal_SyncCounter + 1 );
							END IF;
						ELSE
							IF( ( Signal_SyncCounter < ( MIN_SYNC_LENGTH - 1 ) ) OR ( Signal_VSync /= Signal_VSync_Check ) ) THEN
								Signal_VideoLocked <= '0';
								Signal_PhaseState  <= STATE_SHIFT;
							ELSE
								Signal_VideoLocked <= '1';
								Signal_PhaseState  <= STATE_IDLE;
							END IF;
						END IF;
						Signal_Timeout <= ( Signal_Timeout + 1 );
					ELSE
						Signal_VideoLocked <= '0';
						Signal_PhaseState  <= STATE_SHIFT;
					END IF;
					Signal_PllStep   <= '0';
					Signal_PllUpDown <= '0';
					Signal_PllCntSel <= ( OTHERS => 'X' );
				
				WHEN STATE_SHIFT =>
					IF( Signal_Pll_Done = '0' ) THEN
						IF( Signal_ShiftCounter < MAX_SHIFT_STEPS ) THEN
							Signal_PllCntSel    <= Signal_Pll_C0Cnt;
							Signal_ShiftCounter <= ( Signal_ShiftCounter + 1 );
						ELSE
							Signal_PllCntSel    <= Signal_Pll_C1Cnt;
							Signal_ShiftCounter <= 0;
						END IF;
						Signal_PhaseState <= STATE_DONE;
					END IF;
					Signal_PllStep   <= '1';
					Signal_PllUpDown <= '0';
				
				WHEN STATE_DONE =>
					IF( Signal_Pll_Done = '1' ) THEN
						IF( Signal_ShiftCounter = MAX_SHIFT_STEPS ) THEN
							Signal_PhaseState <= STATE_SHIFT;
						ELSE
							Signal_PhaseState <= STATE_IDLE;
						END IF;
					END IF;
					Signal_PllStep   <= '0';
					Signal_PllUpDown <= '0';
					Signal_PllCntSel <= ( OTHERS => 'X' );
				
				WHEN OTHERS =>
					Signal_PllStep     <= '0';
					Signal_PllUpDown   <= '0';
					Signal_PllCntSel   <= ( OTHERS => 'X' );
					Signal_SyncCounter <= 0;
					Signal_Timeout     <= 0;
					Signal_VSync_Check <= '0';
					Signal_PhaseState  <= STATE_IDLE;
				
				END CASE;
				
			END IF;
			
		END IF;
		
	END PROCESS;
	
	
	
	Video_Clock  <= Signal_SlowClock;
	Video_HSync  <= Signal_HSync;
	Video_VSync  <= Signal_VSync;
	Video_Blank  <= Signal_Blank;
	Video_Red    <= Signal_Red;
	Video_Green  <= Signal_Green;
	Video_Blue   <= Signal_Blue;
	Video_Locked <= Signal_Video_Locked;
	
	
	
END ARCHITECTURE LvdsReceiver_RTL;
