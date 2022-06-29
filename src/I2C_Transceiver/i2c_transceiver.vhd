LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.i2c_pkg.ALL;
USE work.key_codes_pkg.ALL;

ENTITY i2c_transceiver IS
	PORT(
		Avalon_nReset     : IN  STD_LOGIC := '0';
		Avalon_Clock      : IN  STD_LOGIC;
		
		i2c_Clk           : IN  STD_LOGIC;  -- 1,6MHz
		
		AVS_waitrequest   : OUT STD_LOGIC;
		AVS_address       : IN  STD_LOGIC_VECTOR( ( AVCFG_ADDR_WIDTH - 1 )  DOWNTO 0 );
		AVS_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AVS_read          : IN  STD_LOGIC;
		AVS_readdata      : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		AVS_readdatavalid : OUT STD_LOGIC;
		AVS_write         : IN  STD_LOGIC;
		AVS_writedata     : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		--------- Avalon-MM signals to RAM port1 receiver to RAM --------------------
		AV2RAM_waitrequest   : IN  STD_LOGIC;
		AV2RAM_address       : OUT STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM_byteenable    : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2RAM_read          : OUT STD_LOGIC;
		AV2RAM_readdata      : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM_readdatavalid : IN  STD_LOGIC;
		AV2RAM_write         : OUT STD_LOGIC;
		AV2RAM_writedata     : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		
				--------- Avalon-MM signals to RAM port2 PCIE to RAM --------------------
		AV2RAM2_waitrequest   : IN  STD_LOGIC;
		AV2RAM2_address       : OUT STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM2_byteenable    : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2RAM2_read          : OUT STD_LOGIC;
		AV2RAM2_readdata      : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM2_readdatavalid : IN  STD_LOGIC;
		AV2RAM2_write         : OUT STD_LOGIC;
		AV2RAM2_writedata     : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );

		
		---------- Avalon-MM signals from PCIE  ------------------
		AV2PCIE_waitrequest   : OUT STD_LOGIC;
		AV2PCIE_address       : IN  STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
		AV2PCIE_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2PCIE_read          : IN  STD_LOGIC;
		AV2PCIE_readdata      : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		AV2PCIE_readdatavalid : OUT STD_LOGIC;
		AV2PCIE_write         : IN  STD_LOGIC;
		AV2PCIE_writedata     : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		BTN_BKLT_PWM          : OUT STD_LOGIC;
		SPIN_BKLT_PWM         : OUT STD_LOGIC;
		
		LCD_BKLT_EN1          : OUT STD_LOGIC;
		LCD_BKLT_EN2          : OUT STD_LOGIC;
		LCD_BKLT_PWM          : OUT STD_LOGIC;
		LCD_BKLT_FLT          : IN  STD_LOGIC;

		DayNightBright        : IN  STD_LOGIC;

		nOUT_EN               : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );		
		
		SCL                   : INOUT STD_LOGIC;
		SDA                   : INOUT STD_LOGIC;

		LCD_Size_Code : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 )
	);
END i2c_transceiver;


ARCHITECTURE RTL OF i2c_transceiver IS

	COMPONENT i2c_control IS
	PORT(
		Enable       : IN  STD_LOGIC;
		I2C_Clk      : IN  STD_LOGIC;
		AvClk        : IN  STD_LOGIC;
		AvLoad       : IN  STD_LOGIC;
		WordIn       : IN  STD_LOGIC_VECTOR( AVM_DATA_WIDTH-1 DOWNTO 0 );
		RdEn         : OUT STD_LOGIC;
		WrEn         : OUT STD_LOGIC;
		RamAddr      : OUT STD_LOGIC_VECTOR( AVM_ADDR_WIDTH-1 DOWNTO 0 );
		WordOut      : OUT STD_LOGIC_VECTOR( AVM_DATA_WIDTH-1 DOWNTO 0 );
		ByteEn       : OUT STD_LOGIC_VECTOR( ((AVM_DATA_WIDTH / 8) - 1) DOWNTO 0 );
		RAM_Busy     : IN  STD_LOGIC;
		Start        : IN  STD_LOGIC;
		ValCheck     : IN  STD_LOGIC;
		DataReceived : OUT STD_LOGIC;

		PWM_Wr       : OUT STD_LOGIC;
		PWM_nFault   : IN  STD_LOGIC;
		PWM_BTN      : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		PWM_SPIN     : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );		
		PWM_LCD      : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );		
		PWM_EN1      : OUT STD_LOGIC;
		PWM_EN2      : OUT STD_LOGIC;
		
		DayNight     : IN  STD_LOGIC; -- 1 = Night brightness mode, 0 = Day brightness mode 
		nOUT31_EN    : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );  -- bits positions ( OUT3_EN : OUT1_EN )		
		Fault_27V    : OUT STD_LOGIC_VECTOR( 3 DOWNTO 0 );
		LCD_Size_Code : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 ); -- KbdType format; KBD_10INCH, KBD_12INCH, KBD_15INCH

		I2C_Load     : OUT STD_LOGIC;
		I2C_DevAddr  : OUT STD_LOGIC_VECTOR( (I2C_ADDR_WIDTH - 1) DOWNTO 0 );
		I2C_RW       : OUT STD_LOGIC;
		I2C_WrData   : OUT STD_LOGIC_VECTOR( ( I2C_DATA_WIDTH - 1 ) DOWNTO 0 );
		I2C_RdData   : IN  STD_LOGIC_VECTOR( ( I2C_DATA_WIDTH - 1 ) DOWNTO 0 );
		I2C_Err      : IN  STD_LOGIC;
		I2C_Busy     : IN  STD_LOGIC;
		ValCode      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
	END COMPONENT;
	
	
	COMPONENT i2c_master IS
	  GENERIC(
	    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
	    bus_clk   : INTEGER := 100_000);   --speed the i2c bus (scl) will run at in Hz
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
	  );                   --serial clock output of i2c bus
	END COMPONENT;

	COMPONENT recalc IS
	GENERIC(
		NAME : STRING := "NONE";
		INIT_FILE : STRING := "NONE"
	);
	PORT(
		clk_i      : IN  STD_LOGIC;
		DayNight_i : IN  STD_LOGIC;
		ValCode_i  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		load_i     : IN  STD_LOGIC;
		enable_i   : IN  STD_LOGIC;
		enable_o   : OUT STD_LOGIC;
		load_o     : OUT STD_LOGIC;
		pwm_o      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
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

	
	
	COMPONENT AVMM_Master IS
	
	GENERIC(
		CLOCK_FREQUENCE       : INTEGER := 62500000;
		AVM_WRITE_ACKNOWLEDGE : INTEGER := 15;
		AVM_READ_ACKNOWLEDGE  : INTEGER := 15;
		AVM_DATA_WIDTH        : INTEGER := 32;
		AVM_ADDR_WIDTH        : INTEGER := 16
	);
	
	PORT(
		nReset            : IN  STD_LOGIC;
		Clock             : IN  STD_LOGIC;
		WrEn              : IN  STD_LOGIC;
		RdEn              : IN  STD_LOGIC;
		AddrIn            : IN  STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
		WrDataIn          : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		ByteEnCode        : IN  STD_LOGIC_VECTOR( ( ( AVM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
		Ready             : OUT STD_LOGIC;
		RdDataOut         : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		avm_waitrequest   : IN  STD_LOGIC;
		avm_readdata      : IN  STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
		avm_readdatavalid : IN  STD_LOGIC;
		avm_address       : OUT STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
		avm_byteenable    : OUT STD_LOGIC_VECTOR( ( ( AVM_DATA_WIDTH / 8 ) - 1 )  DOWNTO 0 );
		avm_read          : OUT STD_LOGIC;
		avm_write         : OUT STD_LOGIC;
		avm_writedata     : OUT STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 )
	);
	
	END COMPONENT;
	
	
	CONSTANT I2C_INCLK_FREQ  : INTEGER := 1_600_000;
	CONSTANT I2C_BUSCLK_FREQ : INTEGER := 100_000;
	
	TYPE T_Avalon_State   IS ( AVALON_IDLE, AVALON_WRITE, AVALON_ACK_WRITE, AVALON_READ, AVALON_ACK_READ, AVALON_FIN_READ, RAM_RD, RAM_WR, AVALON_RESET );
	TYPE T_Conf_Registers IS ARRAY( 2 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	
	ATTRIBUTE enum_encoding                   : STRING;
	ATTRIBUTE enum_encoding OF T_Avalon_State : TYPE IS "safe, one-hot";
	
	SIGNAL Signal_SlaveState : T_Avalon_State := AVALON_RESET;
	
	SIGNAL Signal_Registers : T_Conf_Registers := ( x"00000000", x"FFFFFFFF", x"00000001" ); -- default RxTx 
	
	SIGNAL LOC_IntFlagReg       : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL LOC_StateReg_DIF     : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL LOC_StateReg_PREV    : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
	
	SIGNAL LOC_IntRegRead       : STD_LOGIC := '0';
	
	SIGNAL LOC_Enable           : STD_LOGIC;
	
	------------ for SYNTHESIS ----------------
	CONSTANT TKEY_Time_IN    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( I2C_INCLK_FREQ / 10 , 20 ) ); -- period 100 ms 
	--CONSTANT TKEY_Time_IN    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( I2C_INCLK_FREQ / 128 , 20 ) ); -- period 12.5 ms 
	--CONSTANT TKEY_Time_IN    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( I2C_INCLK_FREQ / 100 , 20 ) ); -- period 10 ms 
	
	CONSTANT TVAL_Time_IN    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( I2C_INCLK_FREQ / 1000 , 20 ) ); -- period 1 ms (minimal allowed period 360 us)
	--CONSTANT TVAL_Time_IN    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( I2C_INCLK_FREQ / 650 , 20 ) ); -- period 1.5 ms (minimal allowed period 360 us)
	
	-------- for DEBUG ONLY -------------------
	--CONSTANT TKEY_Time_IN    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( I2C_INCLK_FREQ / 500 , 20 ) ); -- period 100 ms 
	--CONSTANT TVAL_Time_IN    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( I2C_INCLK_FREQ / 1000 , 20 ) ); -- period 25 ms
	------------------------------------------


	---------- I2C Control Signals ------------------
	SIGNAL CTRL_Enable      : STD_LOGIC := '0';
	SIGNAL CTRL_Clk_62M5    : STD_LOGIC := '0';
	SIGNAL CTRL_I2C_Clk     : STD_LOGIC;
	SIGNAL CTRL_AvClk       : STD_LOGIC;
	SIGNAL CTRL_AvLoad      : STD_LOGIC;
	SIGNAL CTRL_WordIn      : STD_LOGIC_VECTOR( AVM_DATA_WIDTH-1 DOWNTO 0 );
	SIGNAL CTRL_RdEn        : STD_LOGIC;
	SIGNAL CTRL_WrEn        : STD_LOGIC;
	SIGNAL CTRL_RamAddr     : STD_LOGIC_VECTOR( AVM_ADDR_WIDTH-1 DOWNTO 0 );
	SIGNAL CTRL_WordOut     : STD_LOGIC_VECTOR( AVM_DATA_WIDTH-1 DOWNTO 0 );
	SIGNAL CTRL_ByteEn      : STD_LOGIC_VECTOR( ((AVM_DATA_WIDTH / 8) - 1) DOWNTO 0 );
	SIGNAL CTRL_RAM_Busy    : STD_LOGIC;
	SIGNAL CTRL_Start       : STD_LOGIC;
	SIGNAL CTRL_ValCheck    : STD_LOGIC;
	SIGNAL CTRL_I2C_Load    : STD_LOGIC;
	SIGNAL CTRL_I2C_DevAddr : STD_LOGIC_VECTOR( ( I2C_ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL CTRL_I2C_RW      : STD_LOGIC;
	SIGNAL CTRL_I2C_WrData  : STD_LOGIC_VECTOR( ( I2C_DATA_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL CTRL_I2C_RdData  : STD_LOGIC_VECTOR( ( I2C_DATA_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL CTRL_I2C_Err     : STD_LOGIC;
	SIGNAL CTRL_I2C_Busy    : STD_LOGIC;
	SIGNAL CTRL_RxStateReg_OUT : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL CTRL_DataReceived : STD_LOGIC;
	
	SIGNAL CTRL_PWM_Wr_OUT    : STD_LOGIC;
	SIGNAL CTRL_PWM_nFault_IN : STD_LOGIC;
	SIGNAL CTRL_PWM_BTN_OUT   : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	SIGNAL CTRL_PWM_SPIN_OUT  : STD_LOGIC_VECTOR( 15 DOWNTO 0 );		
	SIGNAL CTRL_PWM_LCD_OUT   : STD_LOGIC_VECTOR( 15 DOWNTO 0 );		
	SIGNAL CTRL_PWM_EN1_OUT   : STD_LOGIC;
	SIGNAL CTRL_PWM_EN2_OUT   : STD_LOGIC;
	SIGNAL CTRL_Fault_27V     : STD_LOGIC_VECTOR( 3 DOWNTO 0 );
	SIGNAL CTRL_LCD_Size_Code : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	
	
	------------- I2C_PHY_MASTER SIGNALS --------------
    SIGNAL I2C_I2C_clk   : STD_LOGIC;                    --system clock
    SIGNAL I2C_reset_n   : STD_LOGIC;                    --active low reset
    SIGNAL I2C_ena       : STD_LOGIC;                    --latch in command
    SIGNAL I2C_addr      : STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    SIGNAL I2C_rw        : STD_LOGIC;                    --'0' is write, '1' is read
    SIGNAL I2C_data_wr   : STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    SIGNAL I2C_busy      : STD_LOGIC;                    --indicates transaction in progress
    SIGNAL I2C_data_rd   : STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    SIGNAL I2C_ack_error : STD_LOGIC;                    --flag if improper acknowledge from slave
    SIGNAL I2C_sda       : STD_LOGIC;                    --serial data output of i2c bus
    SIGNAL I2C_scl       : STD_LOGIC;

	----------- Avalon-MM Interface SIGNALS -----------
	SIGNAL AVM_nReset_IN            : STD_LOGIC;
	SIGNAL AVM_Clock_IN             : STD_LOGIC;
	SIGNAL AVM_WrEn_IN              : STD_LOGIC;
	SIGNAL AVM_RdEn_IN              : STD_LOGIC;
	SIGNAL AVM_AddrIn_IN            : STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL AVM_WrDataIn_IN          : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL AVM_ByteEnCode_IN        : STD_LOGIC_VECTOR( ( ( AVM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
	SIGNAL AVM_Ready_OUT            : STD_LOGIC;
	SIGNAL AVM_RdDataOut_OUT        : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
                            
	SIGNAL AVM_avm_waitrequest_IN   : STD_LOGIC;
	SIGNAL AVM_avm_readdata_IN      : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL AVM_avm_readdatavalid_IN : STD_LOGIC;
	SIGNAL AVM_avm_address_OUT      : STD_LOGIC_VECTOR( ( AVM_ADDR_WIDTH - 1 ) DOWNTO 0 );
	SIGNAL AVM_avm_byteenable_OUT   : STD_LOGIC_VECTOR( ( ( AVM_DATA_WIDTH / 8 ) - 1 )  DOWNTO 0 );
	SIGNAL AVM_avm_read_OUT         : STD_LOGIC;
	SIGNAL AVM_avm_write_OUT        : STD_LOGIC;
	SIGNAL AVM_avm_writedata_OUT    : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 );

	SIGNAL address : INTEGER RANGE 0 TO ( ( 2 ** AVCFG_ADDR_WIDTH ) - 1 )  := 0;  -- Signal_Registers number
	SIGNAL data    : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	
	--------------- BTN PWM Generator Signals ----------------
	SIGNAL PWMBTN_Enable  :  STD_LOGIC;
	SIGNAL PWMBTN_ClkIn   :  STD_LOGIC;
	SIGNAL PWMBTN_Load    :  STD_LOGIC;
	SIGNAL PWMBTN_pwm_val :  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
	SIGNAL PWMBTN_pwm_out :  STD_LOGIC;

	
	------------- SPIN PWM Generator Signals ----------------
	SIGNAL PWMSPIN_Enable  :  STD_LOGIC;
	SIGNAL PWMSPIN_ClkIn   :  STD_LOGIC;
	SIGNAL PWMSPIN_Load    :  STD_LOGIC;
	SIGNAL PWMSPIN_pwm_val :  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
	SIGNAL PWMSPIN_pwm_out :  STD_LOGIC;
	
	
	------------- LCD-matrix brightness PWM Signals --------------
	SIGNAL PWMLCD_Enable  :  STD_LOGIC;
	SIGNAL PWMLCD_ClkIn   :  STD_LOGIC;
	SIGNAL PWMLCD_Load    :  STD_LOGIC;
	SIGNAL PWMLCD_pwm_val :  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
	SIGNAL PWMLCD_pwm_out :  STD_LOGIC;
	
	------------- timer_Keycheck SIGNALS --------------------
	SIGNAL TKEY_Enable_IN  : STD_LOGIC;
	SIGNAL TKEY_Clk_x16_IN : STD_LOGIC;
	SIGNAL TKEY_Ready_OUT  : STD_LOGIC;
	
	-------------- timer_ValCheck SIGNALS --------------------
	SIGNAL TVAL_Enable_IN  : STD_LOGIC;
	SIGNAL TVAL_Clk_x16_IN : STD_LOGIC;
	SIGNAL TVAL_Ready_OUT  : STD_LOGIC;
	SIGNAL RamBusy         : STD_LOGIC;
	SIGNAL ValCode         : STD_LOGIC_VECTOR(7 DOWNTO 0);

	SIGNAL BTN_Load_o: STD_LOGIC;
	SIGNAL LCD_Load_o: STD_LOGIC;

	SIGNAL I2C_Clk_div   : STD_LOGIC;
	SIGNAL PWM_Out_LCD: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL PWM_Out_BTN: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL BTN_PWM_Enable: STD_LOGIC;
	SIGNAL LCD_PWM_Enable: STD_LOGIC;

BEGIN
	
	i2c_ctrl: i2c_control 
	PORT MAP(
		Enable       =>  CTRL_Enable,
		I2C_Clk      =>  CTRL_I2C_Clk,     
		AvClk        =>  CTRL_AvClk,       
		AvLoad       =>  CTRL_AvLoad,      
		WordIn       =>  CTRL_WordIn,      
		RdEn         =>  CTRL_RdEn,        
		WrEn         =>  CTRL_WrEn,        
		RamAddr      =>  CTRL_RamAddr,     
		WordOut      =>  CTRL_WordOut,     
		ByteEn       =>  CTRL_ByteEn,      
		RAM_Busy     =>  CTRL_RAM_Busy,    
		Start        =>  CTRL_Start,       
		ValCheck     =>  CTRL_ValCheck,    
		DataReceived =>  CTRL_DataReceived,

		PWM_Wr       =>  CTRL_PWM_Wr_OUT,    
		PWM_nFault   =>  CTRL_PWM_nFault_IN, 
		PWM_BTN      =>  CTRL_PWM_BTN_OUT,   
		PWM_SPIN     =>  CTRL_PWM_SPIN_OUT,  	
		PWM_LCD      =>  CTRL_PWM_LCD_OUT,   	
		PWM_EN1      =>  CTRL_PWM_EN1_OUT,    
		PWM_EN2      =>  CTRL_PWM_EN2_OUT,    
		
		DayNight     => DayNightBright,
		
		nOUT31_EN    => nOUT_EN,
		Fault_27V    => CTRL_Fault_27V,
		LCD_Size_Code => CTRL_LCD_Size_Code,
		
		I2C_Load     =>  CTRL_I2C_Load,    
		I2C_DevAddr  =>  CTRL_I2C_DevAddr, 
		I2C_RW       =>  CTRL_I2C_RW,      
		I2C_WrData   =>  CTRL_I2C_WrData,  
		I2C_RdData   =>  CTRL_I2C_RdData,  
		I2C_Err      =>  CTRL_I2C_Err,     
		I2C_Busy     =>  CTRL_I2C_Busy,
		ValCode      =>  ValCode
	);
	
	
	
	i2c_phy: i2c_master
	  GENERIC MAP(
	    input_clk => I2C_INCLK_FREQ,  
	    bus_clk   => I2C_BUSCLK_FREQ  
	  )
	  PORT MAP(
	    clk       => I2C_I2C_clk,   
	    reset_n   => I2C_reset_n,   
	    ena       => I2C_ena,        
	    addr      => I2C_addr,       
	    rw        => I2C_rw,         
	    data_wr   => I2C_data_wr,    
	    busy      => I2C_busy,       
	    data_rd   => I2C_data_rd,    
	    ack_error => I2C_ack_error,  
	    sda       => SDA,  --I2C_sda,        
	    scl       => SCL  --I2C_scl        
	  ); 
	
	
	
	btn_pwm_gen: PWM_Gen16
	GENERIC MAP(
		CLK_FREQ_HZ => CLKIN_FREQ_HZ, 
		PWM_FREQ_HZ => PWM_FREQ_HZ 
	)
	PORT MAP(
		Enable  => BTN_PWM_Enable,   
		ClkIn   => PWMBTN_ClkIn,    
		Load    => BTN_Load_o,     
		pwm_val => PWM_Out_BTN,   
		pwm_out => PWMBTN_pwm_out  
	);

	
	spin_pwm_gen: PWM_Gen16
	GENERIC MAP(
		CLK_FREQ_HZ => CLKIN_FREQ_HZ, 
		PWM_FREQ_HZ => PWM_FREQ_HZ 
	)
	PORT MAP(
		Enable  => BTN_PWM_Enable,    
		ClkIn   => PWMSPIN_ClkIn,     
		Load    => BTN_Load_o,      
		pwm_val => PWM_Out_BTN,    
		pwm_out => PWMSPIN_pwm_out  
	);


	lcd_pwm_gen: PWM_Gen16
	GENERIC MAP(
		CLK_FREQ_HZ => CLKIN_FREQ_HZ, 
		PWM_FREQ_HZ => PWM_FREQ_HZ 
	)
	PORT MAP(
		Enable  => LCD_PWM_Enable,    
		ClkIn   => PWMLCD_ClkIn,     
		Load    => LCD_Load_o,      
		pwm_val => PWM_Out_LCD,    
		pwm_out => PWMLCD_pwm_out  
	);

	
	timer_KeyCheck: timer
	PORT MAP(
		Enable   => TKEY_Enable_IN,   
		Clk_x16  => TKEY_Clk_x16_IN,  
		Time     => TKEY_Time_IN,     
		ARST     => '0',     
		Single   => '0',   
		Ready    => TKEY_Ready_OUT   
	);
	
	recalc_lcd: recalc
	GENERIC MAP(
	  NAME      => "LCDB",
	  INIT_FILE => "lcd_brght.mif"
  )
	PORT MAP(
		clk_i      => PWMLCD_ClkIn,
		DayNight_i => DayNightBright,
		ValCode_i  => ValCode,
		load_i     => CTRL_PWM_Wr_OUT,
		enable_i   => LOC_Enable,
		enable_o   => LCD_PWM_Enable,
		load_o     => LCD_Load_o,
		pwm_o      => PWM_Out_LCD
	);
	
	recalc_btn: recalc
	GENERIC MAP(
	  NAME      => "BTNB",
	  INIT_FILE => "btn_brght.mif"
  )
	PORT MAP(
		clk_i      => PWMLCD_ClkIn,
		DayNight_i => DayNightBright,
		ValCode_i  => ValCode,
		load_i     => CTRL_PWM_Wr_OUT,
		enable_i   => LOC_Enable,
		enable_o   => BTN_PWM_Enable,
		load_o     => BTN_Load_o,
		pwm_o      => PWM_Out_BTN
	);
	
	
	timer_ValCheck: timer
	PORT MAP(
		Enable   => TVAL_Enable_IN,   
		Clk_x16  => TVAL_Clk_x16_IN,  
		Time     => TVAL_Time_IN,     
		ARST     => '0',     
		Single   => '0',   
		Ready    => TVAL_Ready_OUT   
	);
	
	
	
	
	
	AVM_Interface: AVMM_Master 
	GENERIC MAP(
		CLOCK_FREQUENCE       => 62_500_000, 
		AVM_WRITE_ACKNOWLEDGE => 15, 
		AVM_READ_ACKNOWLEDGE  => 15, 
		AVM_DATA_WIDTH        => AVM_DATA_WIDTH, 
		AVM_ADDR_WIDTH        => AVM_ADDR_WIDTH 
	)
	PORT MAP(
		nReset            => AVM_nReset_IN,            
		Clock             => AVM_Clock_IN,             
		WrEn              => AVM_WrEn_IN,              
		RdEn              => AVM_RdEn_IN,              
		AddrIn            => AVM_AddrIn_IN,            
		WrDataIn          => AVM_WrDataIn_IN,          
		ByteEnCode        => AVM_ByteEnCode_IN,        
		Ready             => AVM_Ready_OUT,            
		RdDataOut         => AVM_RdDataOut_OUT,        
		                                      
		avm_waitrequest   => AV2RAM_waitrequest,    
		avm_readdata      => AV2RAM_readdata,              
		avm_readdatavalid => AV2RAM_readdatavalid,  
		avm_address       => AV2RAM_address, 
		avm_byteenable    => AV2RAM_byteenable,     
		avm_read          => AV2RAM_read,
		avm_write         => AV2RAM_write,         
		avm_writedata     => AV2RAM_writedata     
	);
	
	
	
	------------- RESET SYSTEM --------------

	--AVM_nReset_IN  <= Avalon_nReset;
	--CTRL_Enable    <= Avalon_nReset AND LOC_Enable;
	--I2C_reset_n    <= Avalon_nReset AND LOC_Enable;
	--TKEY_Enable_IN <= Avalon_nReset AND LOC_Enable;
	--TVAL_Enable_IN <= Avalon_nReset AND LOC_Enable;
	--PWMBTN_Enable  <= Avalon_nReset AND LOC_Enable;
	--PWMSPIN_Enable <= Avalon_nReset AND LOC_Enable;
	--PWMLCD_Enable  <= Avalon_nReset AND LOC_Enable;
	
	------------- DEBUG without iMX6 ----------------
	AVM_nReset_IN  <= LOC_Enable;
	CTRL_Enable    <= LOC_Enable;
	I2C_reset_n    <= LOC_Enable;
	TKEY_Enable_IN <= LOC_Enable;
	TVAL_Enable_IN <= LOC_Enable;
	PWMBTN_Enable  <= LOC_Enable;
	PWMSPIN_Enable <= LOC_Enable;
	PWMLCD_Enable  <= LOC_Enable;

	
	
	
	----------- CLOCK SYSTEM ---------------
	AVM_Clock_IN    <= Avalon_Clock;
	CTRL_I2C_Clk    <= I2C_Clk_div;
	CTRL_AvClk      <= Avalon_Clock;
	I2C_I2C_Clk     <= I2C_Clk_div;
	TKEY_Clk_x16_IN <= I2C_Clk_div;
	TVAL_Clk_x16_IN <= I2C_Clk_div;
	PWMBTN_ClkIn    <= I2C_Clk_div;
	PWMSPIN_ClkIn   <= I2C_Clk_div;
	PWMLCD_ClkIn    <= I2C_Clk_div;

	I2C_Clk_div     <= i2c_Clk;
	
	----------- I2C Master Connect ---------
	I2C_ena      <= CTRL_I2C_Load;
	I2C_addr     <= CTRL_I2C_DevAddr;
	I2C_rw       <= CTRL_I2C_RW;
	I2C_data_wr  <= CTRL_I2C_WrData;
	
	
	---------- I2C Control connect --------
	CTRL_I2C_RdData <= I2C_data_rd;
	CTRL_I2C_Busy   <= I2C_busy;
	CTRL_I2C_Err    <= I2C_ack_error;
	CTRL_Start      <= TKEY_Ready_OUT;
	CTRL_ValCheck   <= TVAL_Ready_OUT;
	CTRL_AvLoad     <= AVM_Ready_OUT;      
	CTRL_WordIn     <= AVM_RdDataOut_OUT; 
	
	PWMBTN_Load     <= CTRL_PWM_Wr_OUT;
	PWMSPIN_Load    <= CTRL_PWM_Wr_OUT;
	PWMLCD_Load     <= CTRL_PWM_Wr_OUT;
	
	PWMBTN_pwm_val  <= CTRL_PWM_BTN_OUT;
	PWMSPIN_pwm_val <= CTRL_PWM_SPIN_OUT;
	PWMLCD_pwm_val  <= CTRL_PWM_LCD_OUT;
	

	------------- FOR SINTHESYS ------------------
	CTRL_RAM_Busy   <= ( AV2PCIE_read OR AV2PCIE_write ); -- OR RamBusy );
	--------------- FOR DEBUG ONLY -------------------
	--CTRL_RAM_Busy   <= '0'; 
	--------------------------------------------------
	
	
	----------- Avalon-MM Master connection ---------
	AVM_WrEn_IN        <= CTRL_WrEn;
	AVM_RdEn_IN        <= CTRL_RdEn;
	AVM_AddrIn_IN      <= CTRL_RamAddr;
	AVM_WrDataIn_IN    <= CTRL_WordOut;  
	AVM_ByteEnCode_IN  <= CTRL_ByteEn;

	
	--------- PCIE2RAM to AVM2RAM2 ------------------
	AV2PCIE_waitrequest   <= AV2RAM2_waitrequest;    
	AV2PCIE_readdata      <= AV2RAM2_readdata;                             
	AV2PCIE_readdatavalid <= AV2RAM2_readdatavalid;                        
	
	AV2RAM2_address       <= AV2PCIE_address;    
	AV2RAM2_byteenable    <= AV2PCIE_byteenable; 
	AV2RAM2_read          <= AV2PCIE_read;       
	AV2RAM2_write         <= AV2PCIE_write;      
	AV2RAM2_writedata     <= AV2PCIE_writedata;  
	
	
	------------ PWM Output ------------------------
	BTN_BKLT_PWM    <= PWMBTN_pwm_out;
	SPIN_BKLT_PWM   <= '0'; 
	LCD_BKLT_PWM    <= PWMLCD_pwm_out;
	
	LCD_BKLT_EN1    <= CTRL_PWM_EN1_OUT;
	LCD_BKLT_EN2    <= CTRL_PWM_EN2_OUT;
	CTRL_PWM_nFault_IN <= LCD_BKLT_FLT;
	
	
		
	
	
	
	
	
	---------- FOR SYNTHESIS ------------------------
	LOC_Enable <= Signal_Registers( CONFIG_REG_ADDR )( I2C_EN );
	---------------------------------------------
	
	---------- DEBUG ONLY ------------------------
	--LOC_Enable <= '1'; --Signal_Registers( CONFIG_REG_ADDR )( I2C_EN );
	---------------------------------------------
	
	
	RamBusy    <= Signal_Registers( CONFIG_REG_ADDR )( CPU_BUFF_BUSY );
	
	
	--ClkDivider: PROCESS( LOC_Enable, Avalon_Clock )	
	--VARIABLE cnt : INTEGER RANGE 0 TO 63 := 0;
	--BEGIN
	--	IF LOC_Enable = '0' THEN
	--		cnt := 0;
	--		I2C_Clk_div <= '0';
	--	ELSIF RISING_EDGE( Avalon_Clock ) THEN  -- Avalon_Clk = 62.5 MHz
	--		IF cnt < 20 THEN
	--			cnt := cnt + 1;
	--		ELSE
	--			cnt := 0;
	--			I2C_Clk_div <= NOT I2C_Clk_div;  -- I2C_Clk_div = 1.56 MHz
	--		END IF;
	--	END IF;
	--END PROCESS;

	
	
	
	
	
	
	
	
	-- Settings registers ( Avalon-MM Slave )
	PROCESS( Avalon_nReset, Avalon_Clock )
	BEGIN
		
		IF( Avalon_nReset = '0' ) THEN
			
			AVS_waitrequest   <= '1';
			AVS_readdatavalid <= '0';
			AVS_readdata      <= ( OTHERS => '0' );
			Signal_SlaveState <= AVALON_RESET;
			LOC_IntFlagReg    <= ( OTHERS => '0' );
			address           <= 0;
			
		ELSIF RISING_EDGE( Avalon_Clock ) THEN
			
			LCD_Size_Code <= CTRL_LCD_Size_Code;

			------------- NEWDATA_RX flag -----------------------------------------
			IF CTRL_DataReceived = '1' THEN
				LOC_IntFlagReg( NEWDATA_RX ) <= '1'; 
			ELSIF LOC_IntRegRead = '1' THEN  
				LOC_IntFlagReg( CLRBIT_H DOWNTO CLRBIT_L ) <= ( OTHERS => '0' );
			END IF;
			
			--------------RAM RX_buffer Busy flag  ---------------------------------
			IF ( ( CTRL_WrEn = '1' ) OR ( CTRL_RdEn = '1') ) THEN
				LOC_IntFlagReg( FPGA_BUFF_BUSY ) <= '1'; --receiver only writes data into RAM_BUFF
			ELSE
				LOC_IntFlagReg( FPGA_BUFF_BUSY ) <= '0';
			END IF;
			
			------------- FAULT 27V bits --------------------
			LOC_IntFlagReg( FAULT_27V1 ) <= CTRL_Fault_27V( 0 );
			LOC_IntFlagReg( FAULT_27V2 ) <= CTRL_Fault_27V( 1 );
			LOC_IntFlagReg( PWRBAD_BIT ) <= CTRL_Fault_27V( 2 );
			LOC_IntFlagReg( BATLOW_BIT ) <= CTRL_Fault_27V( 3 );
			
			------------- LCD Size code --------------------
			LOC_IntFlagReg( LCD_SIZE_L ) <= CTRL_LCD_Size_Code( 0 );
			LOC_IntFlagReg( LCD_SIZE_H ) <= CTRL_LCD_Size_Code( 1 );
			
			Signal_Registers( INTFLAG_REG_ADDR ) <= LOC_IntFlagReg;
			
			CASE Signal_SlaveState IS
			
			WHEN AVALON_IDLE =>
				IF( AVS_write = '1' ) THEN
					AVS_waitrequest   <= '0';
					Signal_SlaveState <= AVALON_WRITE;
				ELSIF( AVS_read = '1' ) THEN
					AVS_waitrequest   <= '0';
					Signal_SlaveState <= AVALON_READ;
				ELSE
					AVS_waitrequest <= '1';
				END IF;
				LOC_IntRegRead    <= '0';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				address           <= TO_INTEGER( UNSIGNED( AVS_address ) );
				data              <= AVS_writedata;
			
			WHEN AVALON_WRITE =>
				AVS_waitrequest   <= '1';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				Signal_Registers( address ) <= data;
				Signal_SlaveState <= AVALON_IDLE;
			
			WHEN AVALON_READ =>
				IF( address = INTFLAG_REG_ADDR ) THEN
					LOC_IntRegRead <= '1';
					LOC_IntFlagReg( CLRBIT_H DOWNTO CLRBIT_L ) <= ( OTHERS => '0' );
				END IF;
				AVS_waitrequest   <= '1';
				AVS_readdatavalid <= '1';
				AVS_readdata      <= Signal_Registers( address );
				Signal_SlaveState <= AVALON_IDLE;
			
			WHEN OTHERS => 
				AVS_waitrequest   <= '1';
				AVS_readdatavalid <= '0';
				AVS_readdata      <= ( OTHERS => '0' );
				Signal_SlaveState <= AVALON_IDLE;
			
			END CASE;
			
		END IF;
		
	END PROCESS;



END RTL;

