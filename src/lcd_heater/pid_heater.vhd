-- PID regulator  v1.0
-- for LCD heater
-- Now used just Pt and It coefficients.
-- Pd not used yet. It even not implemented.




LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.lcd_heater_pkg.ALL;
USE work.i2c_heater_pkg.ALL;

ENTITY pid_heater IS
	PORT(		
		Enable        : IN  STD_LOGIC;		
		AvClk         : IN  STD_LOGIC;		
		PWM_Load      : OUT STD_LOGIC;
		PWM_Value     : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		StartPulse    : IN  STD_LOGIC;
		TemperSetup   : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0 );  -- heater temperature should be solded
		I2C_Ena       : OUT STD_LOGIC;		
		I2C_DevAddr   : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );		
		I2C_RW        : OUT STD_LOGIC;		
		I2C_WrData    : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );		
		I2C_RdData    : IN  STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );		
		I2C_Err       : IN  STD_LOGIC;		
		I2C_Busy      : IN  STD_LOGIC;
		CurSens       : IN  STD_LOGIC;  -- Heater Current sensor
		HeaterError   : OUT STD_LOGIC;
		SensorsError  : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		PWM_State     : OUT STD_LOGIC;  -- PWM heater state: 0 = PWM OFF, 1 = PWM ON
		MeanTemper    : OUT STD_LOGIC_VECTOR( 8 DOWNTO 0 )	-- bits 8-7 = SIGN, bits 6-0 = heater temperature abs value
	);	
END pid_heater;
	
	
ARCHITECTURE RTL OF pid_heater IS

	TYPE pid_Tstate    IS ( IDLE, RD_TEMP1, RD_TEMP2, I2C_READDATA, TERMO_RD_DONE, ERR_CALC, PWM_CALC, PWM_ASSIGN );
	TYPE T_I2C_RdState IS ( I2C_WAITBYTE, I2C_RD_BYTE, I2C_RD_DONE );
	
	SIGNAL I2C_RxArray   : I2C_Rd_Array;
	
	CONSTANT TERMO_DATA_LEN      : INTEGER := 2;  -- bytes number must be readed from TermoSensor through I2C
	CONSTANT I2C_DATA_LEN_MAX    : INTEGER := 63; -- maximal number of data bytes, readed from I2C
	CONSTANT WAIT_MAX    : INTEGER := 2;
	
	SIGNAL NextState     : pid_Tstate;
	SIGNAL PresState     : pid_Tstate;
	SIGNAL RxDoneState   : pid_Tstate;	
	SIGNAL I2C_ReadState : T_I2C_RdState;
	
		
	SIGNAL CNT_MAX_VAL  : UNSIGNED( AVM_ADDR_WIDTH-1 DOWNTO 0 );
	SIGNAL RegRdDone    : STD_LOGIC;  
	SIGNAL RxByteCnt    : INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	SIGNAL I2C_ByteCnt  : INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	SIGNAL I2C_PackLen  : INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	SIGNAL I2C_BusyPrev : STD_LOGIC;
	SIGNAL TermoSensNum : INTEGER RANGE 0 TO 3;

	SIGNAL TermoAddr    : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL TermoData    : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL WaitCnt      : INTEGER RANGE 0 TO 3;
	SIGNAL Temper1      : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	SIGNAL Temper2      : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	SIGNAL TermoError   : STD_LOGIC;
	SIGNAL Sens1Err     : STD_LOGIC;
	SIGNAL Sens2Err     : STD_LOGIC;
	SIGNAL PWM_Value_LOC : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	
	-------------- PID regulator signals -----------------
	SIGNAL Pt           : SIGNED( 15 DOWNTO 0 );
	SIGNAL It           : SIGNED( 15 DOWNTO 0 );
	SIGNAL It_Prev      : SIGNED( 15 DOWNTO 0 );
	SIGNAL TemperCur    : SIGNED( 7 DOWNTO 0 );
	SIGNAL ErrorCur     : SIGNED( 7 DOWNTO 0 );
	SIGNAL ErrorPrev    : SIGNED( 7 DOWNTO 0 );

BEGIN




	StateHandler: PROCESS( Enable, AvClk )
	BEGIN
		IF Enable = '0' THEN
			RegRdDone   <= '0';
			I2C_ByteCnt <= 0;
			PresState   <= IDLE;
			I2C_Ena     <= '0';
			PWM_Load    <= '0';
			ErrorCur    <= ( OTHERS => '0' );
			It_Prev     <= ( OTHERS => '0' );
			It          <= ( OTHERS => '0' );
			Pt          <= ( OTHERS => '0' );
			SensorsError <= ( OTHERS => '0' );	
			Sens1Err     <= '0';
			Sens2Err     <= '0';
			MeanTemper   <= ( OTHERS => '0' );
			HeaterError  <= '0';
			
		ELSIF FALLING_EDGE( AvClk ) THEN
			
			I2C_BusyPrev <= I2C_Busy;
			
			CASE PresState IS
			WHEN IDLE =>
				PWM_Load <= '0';
				I2C_Ena  <= '0';
				RxByteCnt <= 0;
				ErrorCur  <= ( OTHERS => '0' );
				Sens1Err  <= '0';
				Sens2Err  <= '0';
				
				IF StartPulse = '1' THEN
					PresState <= RD_TEMP1;
				END IF;
			
			WHEN RD_TEMP1 =>
				IF I2C_BusyPrev = '0' THEN					
					I2C_DevAddr <= TERM1_I2C_ADDR;					
					I2C_RW      <= I2C_RD_BIT;					
					I2C_Ena     <= '1';					
					I2C_PackLen <= TERMO_DATA_LEN;					
					RxByteCnt   <= 0;					
					RxDoneState <= TERMO_RD_DONE;				
					TermoSensNum <= 1;
				ELSE					
					PresState     <= I2C_READDATA;					
					I2C_ReadState <= I2C_WAITBYTE;				
				END IF;
				
				
			WHEN RD_TEMP2 =>
				IF I2C_BusyPrev = '0' THEN					
					I2C_DevAddr <= TERM2_I2C_ADDR;					
					I2C_RW      <= I2C_RD_BIT;					
					I2C_Ena     <= '1';					
					I2C_PackLen <= TERMO_DATA_LEN;					
					RxByteCnt   <= 0;					
					RxDoneState <= TERMO_RD_DONE;				
					TermoSensNum <= 2;
				ELSE					
					PresState     <= I2C_READDATA;					
					I2C_ReadState <= I2C_WAITBYTE;				
				END IF;
			
			
			
			WHEN I2C_READDATA =>
				CASE I2C_ReadState IS
				WHEN I2C_WAITBYTE =>
					IF RxByteCnt = I2C_PackLen-1 THEN
						I2C_Ena <= '0';
					END IF;
					IF I2C_BusyPrev > I2C_Busy THEN
						I2C_RxArray( RxByteCnt ) <= I2C_RdData;
						I2C_ReadState <= I2C_RD_BYTE;
					ELSE
						I2C_ReadState <= I2C_WAITBYTE;
					END IF;
				
				WHEN I2C_RD_BYTE =>
					IF RxByteCnt < I2C_PackLen-1 THEN
						RxByteCnt <= RxByteCnt + 1;
						I2C_ReadState <= I2C_WAITBYTE;
					ELSE
						I2C_Ena   <= '0';
						RxByteCnt <= 0;
						I2C_ReadState <= I2C_RD_DONE;
					END IF;	
				
				WHEN I2C_RD_DONE =>
					IF I2C_Err = '1' THEN
						TermoError <= '1';
					ELSE
						TermoError <= '0';
					END IF;
					RxByteCnt <= 0;
					PresState <= RxDoneState;

				WHEN OTHERS => 
					I2C_ReadState <= I2C_WAITBYTE;
				END CASE;

			
			
			
			WHEN TERMO_RD_DONE =>
				IF TermoSensNum = 1 THEN				
					Temper1( 15 DOWNTO 8 ) <= I2C_RxArray(0);				
					Temper1(  7 DOWNTO 0 ) <= I2C_RxArray(1);				
					RegRdDone   <= '0';				
					I2C_ByteCnt <= 0;				
					RxByteCnt   <= 0;
					IF I2C_RxArray(0) < x"FF" OR I2C_RxArray(1) < x"FF" THEN
						Sens1Err <= Sens1Err OR TermoError;
					ELSE
						Sens1Err <= '1';
					END IF;				
				--	Sens1Err    <= Sens1Err OR TermoError;
					
					PresState   <= RD_TEMP2;
					
				ELSIF TermoSensNum = 2 THEN
					Temper2( 15 DOWNTO 8 ) <= I2C_RxArray(0);				
					Temper2(  7 DOWNTO 0 ) <= I2C_RxArray(1);				
					RegRdDone   <= '0';				
					I2C_ByteCnt <= 0;				
					RxByteCnt   <= 0;
					--TemperPrev  <= TemperCur;
					ErrorPrev   <= ErrorCur;
					It_Prev     <= It;
					IF I2C_RxArray(0) < x"FF" OR I2C_RxArray(1) < x"FF" THEN
						Sens2Err <= TermoError;
					ELSE
						Sens2Err <= '1';
					END IF;
				--	Sens2Err <= Sens2Err OR TermoError;
					
					PresState   <= ERR_CALC;
				END IF;
				
			
			WHEN ERR_CALC =>
				IF Sens1Err = '0' AND Sens2Err = '0' THEN	
					---- check TemperCur calculation. Temper1 and temper2 with different signs.
					TemperCur( 7 DOWNTO 0 ) <= shift_right( ( SIGNED( Temper1( 15 DOWNTO 8 ) ) + SIGNED( Temper2( 15 DOWNTO 8 ) ) ), 1 );
					ErrorCur <= SIGNED( TemperSetup ) - shift_right( ( SIGNED( Temper1( 15 DOWNTO 8 ) ) + SIGNED( Temper2( 15 DOWNTO 8 ) ) ), 1 );
				ELSE
					IF Sens1Err = '0' AND Sens2Err = '1' THEN
						TemperCur( 7 DOWNTO 0 ) <= SIGNED( Temper1( 15 DOWNTO 8 ) );
						ErrorCur <= SIGNED( TemperSetup ) - SIGNED( Temper1( 15 DOWNTO 8 ) );
					
					ELSIF Sens1Err = '1' AND Sens2Err = '0' THEN
						TemperCur( 7 DOWNTO 0 ) <= SIGNED( Temper2( 15 DOWNTO 8 ) );
						ErrorCur <= SIGNED( TemperSetup ) - SIGNED( Temper2( 15 DOWNTO 8 ) );
					END IF;
				
				END IF;
				PresState <= PWM_CALC;
			
			
			
			WHEN PWM_CALC =>
				IF Sens1Err = '0' OR Sens2Err = '0' THEN    
					IF ErrorCur(7) > '0' THEN  -- IF error is negative, i.e. TemperCur > TemperSetup turn-off PWM
						Pt <= ( OTHERS => '0' );
						It <= ( OTHERS => '0' );
					ELSIF UNSIGNED( PWM_Value_LOC ) < PWM_MAX_VAL THEN
						--Pt <= "000000" & ErrorCur & "00";  -- Kp = 4;
						--It <= It_Prev + ("00000000" & ErrorCur ); -- Ki = 1;
						
						Pt <= "0" & ErrorCur & "0000000";  -- Kp = 128;
						It <= It_Prev + ("000" & ErrorCur & "00000"); -- Ki = 32;
						
						IF PWM_Value_LOC > x"0000" THEN
							PWM_State <= '1';
						ELSE
							PWM_State <= '0';
						END IF;
						
					END IF;
					
				END IF;
				
				MeanTemper( 6 DOWNTO 0 ) <= STD_LOGIC_VECTOR( TemperCur( 6 DOWNTO 0 ) );
				
				IF Sens1Err = '1' AND Sens2Err = '1' THEN
					MeanTemper( 8 DOWNTO 7 ) <= "01";	
					MeanTemper( 6 DOWNTO 0 ) <= ( OTHERS => '0' );
				ELSIF TemperCur(7) > '0' THEN
					MeanTemper( 8 DOWNTO 7 ) <= "11";
				ELSE
					MeanTemper( 8 DOWNTO 7 ) <= "00";
				END IF;
				
				PresState <= PWM_ASSIGN;
				
			
			
			WHEN PWM_ASSIGN =>
				SensorsError <= Sens2Err & Sens1Err;
				PWM_Load  <= '1';
				IF Sens1Err = '1' AND Sens2Err = '1' THEN  -- Both termosensors are not answer. Turn-off heater
					PWM_Value_LOC <= ( OTHERS => '0' );
					PWM_Value     <= ( OTHERS => '0' );
				ELSE
					PWM_Value_LOC <= STD_LOGIC_VECTOR( Pt + It ); 
					PWM_Value     <= STD_LOGIC_VECTOR( Pt + It ); 
				END IF;
				PresState <= IDLE;
			
			
			WHEN OTHERS => 
				NextState <= IDLE;
			END CASE;
		END IF;
	END PROCESS;
	


	
END RTL;

