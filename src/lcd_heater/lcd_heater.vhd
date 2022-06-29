LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.i2c_heater_pkg.ALL;	
USE work.lcd_heater_pkg.ALL;


ENTITY lcd_heater IS
	PORT(
		Avalon_nReset     : IN  STD_LOGIC := '0';
		Avalon_Clock      : IN  STD_LOGIC;
		
		AVS_waitrequest   : OUT STD_LOGIC;
		AVS_address       : IN  STD_LOGIC_VECTOR( ( AVCFG_ADDR_WIDTH - 1 )  DOWNTO 0 );
		AVS_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AVS_read          : IN  STD_LOGIC;
		AVS_readdata      : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		AVS_readdatavalid : OUT STD_LOGIC;
		AVS_write         : IN  STD_LOGIC;
		AVS_writedata     : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		LCD_HEAT          : OUT STD_LOGIC;
		nHEAT_CUR_SENS    : IN  STD_LOGIC;   -- 0 = current present, 1 = no heater current
		
		I2C_SCL           : INOUT STD_LOGIC;
		I2C_SDA           : INOUT STD_LOGIC

	);

END lcd_heater;


ARCHITECTURE ARCH OF lcd_heater IS

	COMPONENT pid_heater IS
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
		CurSens       : IN  STD_LOGIC;  -- LCD heater current sensor
		HeaterError   : OUT STD_LOGIC;
		SensorsError  : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		PWM_State     : OUT STD_LOGIC;
		MeanTemper    : OUT STD_LOGIC_VECTOR( 8 DOWNTO 0 )	-- bits 8-7 = SIGN, bits 6-0 = heater temperature abs value
	);
	END COMPONENT;
		
	
	COMPONENT i2c_master_heater IS
	  GENERIC(
		input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
		bus_clk   : INTEGER := 100_000
	  );
	  PORT(
		clk       : IN     STD_LOGIC;                    --system clock
		reset_n   : IN     STD_LOGIC;                    --active low reset
		ena       : IN     STD_LOGIC;                    --latch in command
		addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
		rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
		data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
		busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
		data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
		ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
		sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
		scl       : INOUT  STD_LOGIC
		
	  );
	END COMPONENT;	



	COMPONENT PWM_Gen16 IS
	GENERIC(
		CLK_FREQ_HZ : INTEGER := 1_600_000;
		PWM_FREQ_HZ : INTEGER := 200
	);
	PORT(
		Enable  : IN  STD_LOGIC;
		ClkIn   : IN  STD_LOGIC;
		Load    : IN  STD_LOGIC;
		pwm_val : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
		pwm_out : OUT STD_LOGIC
		
	);
	END COMPONENT;
	
	
	
	COMPONENT timer IS
	PORT(
		Enable   : IN  STD_LOGIC;
		Clk_x16  : IN  STD_LOGIC;
		Time     : IN  STD_LOGIC_VECTOR( 19 DOWNTO 0 );
		ARST     : IN  STD_LOGIC;
		Single   : IN  STD_LOGIC; -- 1 = Single, 0 - continuous work
		Ready    : OUT STD_LOGIC
	);
	END COMPONENT;
	
	
	
	COMPONENT pgen IS
	GENERIC(
		Edge : STD_LOGIC
	);
	PORT(
		Enable : IN  STD_LOGIC;
		Clk    : IN  STD_LOGIC;
		Input  : IN  STD_LOGIC;
		Output : OUT STD_LOGIC
	);
	END COMPONENT;
	
	
	
	
	COMPONENT pulse_stretch IS
	PORT(
		Enable   : IN  STD_LOGIC;
		Clk      : IN  STD_LOGIC;
		PulseIn  : IN  STD_LOGIC;
		PulseOut : OUT STD_LOGIC
	);
	END COMPONENT;
		
		
		
		
	--------------- PID Heater SIGNALS ----------------------
	SIGNAL PID_Enable_IN       :  STD_LOGIC;		
	SIGNAL PID_AvClk_IN        :  STD_LOGIC;		
	SIGNAL PID_PWM_Load_OUT    :  STD_LOGIC;
	SIGNAL PID_PWM_Value_OUT   :  STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	SIGNAL PID_StartPulse_IN   :  STD_LOGIC;
	SIGNAL PID_TemperSetup_IN  :  STD_LOGIC_VECTOR( 7 DOWNTO 0 );  -- heater temperature should be holded
	SIGNAL PID_I2C_Ena_OUT     :  STD_LOGIC;		
	SIGNAL PID_I2C_DevAddr_OUT :  STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );		
	SIGNAL PID_I2C_RW_OUT      :  STD_LOGIC;		
	SIGNAL PID_I2C_WrData_OUT  :  STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );		
	SIGNAL PID_I2C_RdData_IN   :  STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );		
	SIGNAL PID_I2C_Err_IN      :  STD_LOGIC;		
	SIGNAL PID_I2C_Busy_IN     :  STD_LOGIC;
	SIGNAL PID_CurSens_IN      :  STD_LOGIC;
	SIGNAL PID_HeaterError_OUT :  STD_LOGIC;
	SIGNAL PID_PWM_State_OUT   :  STD_LOGIC;
	SIGNAL PID_SensorsError_OUT:  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL PID_MeanTemper_OUT  :  STD_LOGIC_VECTOR( 8 DOWNTO 0 );	-- bits 8-7 = SIGN, bits 6-0 = heater temperature abs value
	
	
	------------- i2c_master Signals --------------------------
	SIGNAL I2C_clk_IN           :  STD_LOGIC;                    --system clock
	SIGNAL I2C_reset_n_IN       :  STD_LOGIC;                    --active low reset
	SIGNAL I2C_ena_IN           :  STD_LOGIC;                    --latch in command
	SIGNAL I2C_addr_IN          :  STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
	SIGNAL I2C_rw_IN            :  STD_LOGIC;                    --'0' is write, '1' is read
	SIGNAL I2C_data_wr_IN       :  STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
	SIGNAL I2C_busy_OUT         :  STD_LOGIC;                    --indicates transaction in progress
	SIGNAL I2C_data_rd_OUT      :  STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
	SIGNAL I2C_ack_error_BUFFER :  STD_LOGIC;                    --flag if improper acknowledge from slave
	SIGNAL I2C_sda_INOUT        :  STD_LOGIC;                    --serial data output of i2c bus
	SIGNAL I2C_scl_INOUT        :  STD_LOGIC;
	
	
	------------------ PWM_GEN16 SIGNALS ------------------
	SIGNAL PWM_Enable_IN   :  STD_LOGIC;
	SIGNAL PWM_ClkIn_IN    :  STD_LOGIC;
	SIGNAL PWM_Load_IN     :  STD_LOGIC;
	SIGNAL PWM_pwm_val_IN  :  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
	SIGNAL PWM_pwm_out_OUT :  STD_LOGIC;
	
	
	SIGNAL clk_625kHz      : STD_LOGIC;
	
	TYPE   T_Avalon_State     IS ( AVALON_RESET, AVALON_IDLE, AVALON_WRITE, AVALON_ACK_WRITE, AVALON_READ, AVALON_ACK_READ, AVALON_FIN_READ, RAM_RD, RAM_WR );
	TYPE   T_Conf_Registers   IS ARRAY( 2 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	
	
	SIGNAL Signal_SlaveState  : T_Avalon_State   := AVALON_RESET;
	SIGNAL Signal_Registers   : T_Conf_Registers := ( x"00000000", x"FFFFFFFF", x"00000000" ); -- default RxTx 


	SIGNAL LOC_IntFlagReg       : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL LOC_StateReg_DIF     : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL LOC_StateReg_PREV    : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL LOC_IntRegRead       : STD_LOGIC := '0';
	
	SIGNAL LOC_Enable           : STD_LOGIC;

	SIGNAL address : INTEGER RANGE 0 TO ( ( 2 ** AVCFG_ADDR_WIDTH ) - 1 )  := 0;  -- Signal_Registers number	
	SIGNAL TMR_StartPulse_OUT   : STD_LOGIC;
	
	


BEGIN


	pid_regulator: pid_heater 
	PORT MAP(		
		Enable        =>  PID_Enable_IN,
		AvClk         =>  PID_AvClk_IN,
		PWM_Load      =>  PID_PWM_Load_OUT,
		PWM_Value     =>  PID_PWM_Value_OUT,
		StartPulse    =>  PID_StartPulse_IN,
		TemperSetup   =>  PID_TemperSetup_IN,
		I2C_Ena       =>  PID_I2C_Ena_OUT,
		I2C_DevAddr   =>  PID_I2C_DevAddr_OUT,
		I2C_RW        =>  PID_I2C_RW_OUT,
		I2C_WrData    =>  PID_I2C_WrData_OUT,
		I2C_RdData    =>  PID_I2C_RdData_IN,
		I2C_Err       =>  PID_I2C_Err_IN,
		I2C_Busy      =>  PID_I2C_Busy_IN,
		CurSens       =>  PID_CurSens_IN,
		HeaterError   =>  PID_HeaterError_OUT,
		SensorsError  =>  PID_SensorsError_OUT,
		PWM_State     =>  PID_PWM_State_OUT,
		MeanTemper    =>  PID_MeanTemper_OUT
	); 




	
	i2c_mstr_phy: i2c_master_heater 
	GENERIC MAP(
		input_clk =>  CLKIN_FREQ_HZ,
		bus_clk   =>  I2C_CLK_FREQ_HZ
	)
	PORT MAP(
		clk       => I2C_clk_IN,
		reset_n   => I2C_reset_n_IN,       
		ena       => I2C_ena_IN,           
		addr      => I2C_addr_IN,          
		rw        => I2C_rw_IN,            
		data_wr   => I2C_data_wr_IN,       
		busy      => I2C_busy_OUT,         
		data_rd   => I2C_data_rd_OUT,      
		ack_error => I2C_ack_error_BUFFER, 
		sda       => I2C_SDA, 
		scl       => I2C_SCL  
		
	);




	pwm_gen: PWM_Gen16 
	GENERIC MAP(
		CLK_FREQ_HZ => PWM_CLKIN_FREQ_HZ,
		PWM_FREQ_HZ => PWM_FREQ_HZ
	)
	PORT MAP(
		Enable  => PWM_Enable_IN,   
		ClkIn   => PWM_ClkIn_IN,    
		Load    => PWM_Load_IN,    
		pwm_val => PWM_pwm_val_IN,  
		pwm_out => PWM_pwm_out_OUT 
	);

	
	
	
	clk_625kHz_gen: timer 
	PORT MAP(
		Enable   => Avalon_nReset, 
		Clk_x16  => Avalon_Clock,  -- 62,5 MHz
		Time     => x"00064",      -- divider 100
		ARST     => '0', 
		Single   => '0', 
		Ready    => clk_625kHz 
	);
	
	
	
	start_pulse_gen: timer 
	PORT MAP(
		Enable   => Avalon_nReset, 
		Clk_x16  => clk_625kHz,     -- 625 kHz
		Time     => TIMER_100MS,      --TIMER_1MS,      --
		ARST     => '0', 
		Single   => '0', 
		Ready    =>  TMR_StartPulse_OUT
	);
	
	

	start_pulse_narrow_dwn: pgen
	GENERIC MAP(
		Edge => '1'
	)
	PORT MAP(
		Enable => Avalon_nReset,
		Clk    => Avalon_Clock,
		Input  => TMR_StartPulse_OUT,
		Output => PID_StartPulse_IN
	);
	 
	
	

	LoadStretch: pulse_stretch
	PORT MAP(
		Enable   =>  Avalon_nReset,
		Clk      =>  clk_625kHz,
		PulseIn  =>  PID_PWM_Load_OUT,
		PulseOut =>  PWM_Load_IN
	);


	
	---------- SYNTHESYS ---------------
	--LOC_Enable <= Signal_Registers( CONFIG_REG_ADDR )( HEATER_EN );
	------------------------------------
	------ FOR DEBUG ONLY!! -------------
	LOC_Enable <= '1';  
	-----------------------------------
	
	------------- PID heater connection------------
	--PID_TemperSetup_IN <= Signal_Registers( CONFIG_REG_ADDR )( TEMPER_H  DOWNTO TEMPER_L );
	--------------- DEBUG ONLY!! -------------------
	--PID_TemperSetup_IN <= x"28"; -- +40 degree Celsius for table test
	PID_TemperSetup_IN <= x"F6"; -- -10 degree Celsius for termocamera
	-------------------------------------------------
	
	

	  
	--============ COMPONENTS CONNECTIONS ==========
	------------ reset system ------------------
	I2C_reset_n_IN <= Avalon_nReset AND LOC_Enable;
	PID_Enable_IN  <= Avalon_nReset AND LOC_Enable;
	PWM_Enable_IN  <= Avalon_nReset AND LOC_Enable;
	
	------------- clock system -----------------
	I2C_clk_IN     <= Avalon_Clock;
	PID_AvClk_IN   <= Avalon_Clock;
	PWM_ClkIn_IN   <= clk_625kHz;

	-------- PID heater connection --------------
	PID_I2C_RdData_IN  <= I2C_data_rd_OUT;
	PID_I2C_Err_IN     <= I2C_ack_error_BUFFER;
	PID_I2C_Busy_IN    <= I2C_busy_OUT;
	PID_CurSens_IN     <= nHEAT_CUR_SENS;
	-- PID_StartPulse_IN connected to start_pulse_narrow_dwn!!

	
	--------- i2c_master Connection --------------
	I2C_ena_IN        <= PID_I2C_Ena_OUT;
	I2C_addr_IN       <= PID_I2C_DevAddr_OUT;
	I2C_rw_IN         <= PID_I2C_RW_OUT;
	I2C_data_wr_IN    <= PID_I2C_WrData_OUT;
    

	-------------- PWM_GEN Connection-------------	
--	PWM_Load_IN connected to LoadStretch	
	PWM_pwm_val_IN    <= PID_PWM_Value_OUT;
	LCD_HEAT          <= PWM_pwm_out_OUT; 
	
	
	
	
	
		-- Settings registers ( Avalon-MM Slave )
	PROCESS( Avalon_nReset, Avalon_Clock )
		VARIABLE data    : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	BEGIN
		
		IF( Avalon_nReset = '0' ) THEN
			
			AVS_waitrequest   <= '0';
			AVS_readdatavalid <= '0';
			AVS_readdata      <= ( OTHERS => '0' );
			Signal_SlaveState <= AVALON_RESET;
			LOC_IntFlagReg    <= ( OTHERS => '0' );
			address           <= 0;
			
		ELSIF RISING_EDGE( Avalon_Clock ) THEN
			
			---------------- LOC_IntFlagReg -------------------------------
			
			LOC_IntFlagReg( PWM_ON )     <= PID_PWM_State_OUT;
			LOC_IntFlagReg( TEMP1_ERR )  <= LOC_IntFlagReg( TEMP1_ERR ) OR PID_SensorsError_OUT(0);
			LOC_IntFlagReg( TEMP2_ERR )  <= LOC_IntFlagReg( TEMP2_ERR ) OR PID_SensorsError_OUT(1);
			LOC_IntFlagReg( SIGN_ERR_H DOWNTO TEMP_L )  <= PID_MeanTemper_OUT;
			
			Signal_Registers( INTFLAG_REG_ADDR ) <= LOC_IntFlagReg;
				
			CASE Signal_SlaveState IS
			
			WHEN AVALON_RESET =>
				AVS_waitrequest   <= '0';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_IDLE;
			
			WHEN AVALON_IDLE =>
				LOC_IntRegRead    <= '0';			
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				
				IF( AVS_write = '1' ) THEN
					Signal_SlaveState <= AVALON_WRITE;
					address           <= TO_INTEGER( UNSIGNED( AVS_address ) );
					data              := AVS_writedata;
					AVS_waitrequest   <= '1';
					AVS_readdatavalid <= '0';
				
				ELSIF( AVS_read = '1' ) THEN
					Signal_SlaveState <= AVALON_READ;
					address           <= TO_INTEGER( UNSIGNED( AVS_address ) );
					AVS_waitrequest   <= '1';
					AVS_readdatavalid <= '0';
				
				END IF;
				
					
			WHEN AVALON_WRITE =>
				AVS_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_ACK_WRITE;
			
			WHEN AVALON_ACK_WRITE =>
				AVS_waitrequest             <= '0';
				AVS_readdatavalid           <= '0';
				AVS_readdata                <= ( OTHERS => '0' );
				Signal_Registers( address ) <= data;
				
				Signal_SlaveState <= AVALON_IDLE;
			
			WHEN AVALON_READ =>
				AVS_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_ACK_READ;
			
			WHEN AVALON_ACK_READ =>
				AVS_waitrequest   <= '0';
				AVS_readdatavalid <= '1';
				AVS_readdata      <= Signal_Registers( address );
			
				IF address = INTFLAG_REG_ADDR THEN
					LOC_IntRegRead <= '1';	
					LOC_IntFlagReg( CLRBIT_H DOWNTO CLRBIT_L ) <= ( OTHERS => '0' );
				END IF;
				Signal_SlaveState <= AVALON_IDLE;
						
			
			WHEN OTHERS => 
				Signal_SlaveState <= AVALON_IDLE;
			END CASE;
			
		END IF;
		
	END PROCESS;
    


	  
END ARCH;
