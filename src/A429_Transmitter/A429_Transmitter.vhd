LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.arinc429tx_pkg.ALL;

ENTITY A429_Transmitter IS
	
	PORT(
		
		Avalon_nReset     : IN  STD_LOGIC; --:= '0';
		Avalon_Clock      : IN  STD_LOGIC;
		
		AVS_waitrequest   : OUT STD_LOGIC;
		AVS_address       : IN  STD_LOGIC_VECTOR(  ( AVCFG_ADDR_WIDTH - 1 ) DOWNTO 0 );
		AVS_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AVS_read          : IN  STD_LOGIC;
		AVS_readdata      : OUT STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
		AVS_readdatavalid : OUT STD_LOGIC;
		AVS_write         : IN  STD_LOGIC;
		AVS_writedata     : IN  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		----------- for PCIE Slave Avalon-MM port -----------------
		AV2PCIE_waitrequest   : OUT STD_LOGIC;
		AV2PCIE_address       : IN  STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 );
		AV2PCIE_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2PCIE_read          : IN  STD_LOGIC;
		AV2PCIE_readdata      : OUT STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
		AV2PCIE_readdatavalid : OUT STD_LOGIC;
		AV2PCIE_write         : IN  STD_LOGIC;
		AV2PCIE_writedata     : IN  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		-------------- for RAM Master Avalon-MM port ------------
		AV2RAM_waitrequest   : IN  STD_LOGIC;
		AV2RAM_address       : OUT STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM_byteenable    : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2RAM_read          : OUT STD_LOGIC;
		AV2RAM_readdata      : IN  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM_readdatavalid : IN  STD_LOGIC;
		AV2RAM_write         : OUT STD_LOGIC;
		AV2RAM_writedata     : OUT STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
		
			--------- Avalon-MM signals to RAM port2 PCIE to RAM --------------------
		AV2RAM2_waitrequest   : IN  STD_LOGIC;
		AV2RAM2_address       : OUT STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM2_byteenable    : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
		AV2RAM2_read          : OUT STD_LOGIC;
		AV2RAM2_readdata      : IN  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
		AV2RAM2_readdatavalid : IN  STD_LOGIC;
		AV2RAM2_write         : OUT STD_LOGIC;
		AV2RAM2_writedata     : OUT STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
		
		Interrupt         : OUT STD_LOGIC;
		RxTestEn          : IN STD_LOGIC;
		
		A429_Clock        : IN  STD_LOGIC;
		TxReg             : OUT STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
		TxFlag            : OUT STD_LOGIC;
		RxLineBusy        : IN  STD_LOGIC;
		A429_Slp          : OUT STD_LOGIC;
		A429_LineA        : OUT STD_LOGIC;
		A429_LineB        : OUT STD_LOGIC;
		A429_CtrlA        : IN  STD_LOGIC;
		A429_CtrlB        : IN  STD_LOGIC
		
	);
END A429_Transmitter;

ARCHITECTURE logic OF A429_Transmitter IS
	
	COMPONENT a429_txphy IS
	PORT(
		Enable      : IN  STD_LOGIC;
		ClockIn     : IN  STD_LOGIC;
		ClockMux    : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
		Data        : IN  STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
		WrClk       : IN  STD_LOGIC;
		WrEn        : IN  STD_LOGIC;
		Full        : OUT STD_LOGIC;
		OutputA     : OUT STD_LOGIC;
		OutputB     : OUT STD_LOGIC;
		SlewRate    : OUT STD_LOGIC;
		OutReg      : OUT STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
		Busy        : OUT STD_LOGIC
	);
	END COMPONENT;
	
	COMPONENT a429_RxPhy IS
	GENERIC(
		DataWidth    : INTEGER := 32;
		StopWidth    : INTEGER := 4;
		Pack_WN      : INTEGER := 16;
		UsedWidth    : INTEGER := 4
	);
	PORT(
		Enable      : IN  STD_LOGIC := '1';
		ClockIn     : IN  STD_LOGIC;
		ClockMux    : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		InputA      : IN  STD_LOGIC := '0';
		InputB      : IN  STD_LOGIC := '0';
		TxCntrl     : IN  STD_LOGIC;
		InReg       : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		RxInvert    : IN  STD_LOGIC;
		RdClk       : IN  STD_LOGIC;
		RdReq       : IN  STD_LOGIC;
		ParOFF      : IN  STD_LOGIC;
		nEmpty      : OUT STD_LOGIC;		
		DataOut     : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		ParErr      : OUT STD_LOGIC;
		TxErr       : OUT STD_LOGIC;
		RxFlag      : OUT STD_LOGIC
	);
	END COMPONENT;	
	
	COMPONENT a429_TxControl IS
	PORT(
		Enable    : IN  STD_LOGIC;
		AvClk     : IN  STD_LOGIC;
		WordIn    : IN  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
		TxStart   : IN  STD_LOGIC;
		TestEn    : IN  STD_LOGIC;
		Load      : IN  STD_LOGIC;
		LineBusy  : IN  STD_LOGIC;
		ConfReg   : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		TxPhyBusy : IN  STD_LOGIC;
		TxLineErr : IN  STD_LOGIC;
		WrEn      : OUT STD_LOGIC;
		Addr      : OUT STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 );
		RdEn      : OUT STD_LOGIC;
		WrData    : OUT STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
		Full      : IN  STD_LOGIC; 
		ClkMUX    : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		State     : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		BuffBusy     : IN STD_LOGIC;
		StateRegRst  : IN STD_LOGIC;
		AVM_RdValid  : IN STD_LOGIC;
		RAMWrAddr    : IN STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 );
		RAM_WrEn  : IN STD_LOGIC;
		AddrRol   : IN STD_LOGIC;
		ByteEn    : OUT STD_LOGIC_VECTOR( ( ( AV_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
		TxMode    : OUT STD_LOGIC;
		FreeSpace : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		TxPause   : OUT STD_LOGIC_VECTOR( 19 DOWNTO 0 )
	);
	END COMPONENT;
	
	COMPONENT timer IS
	PORT(
		Enable   : IN  STD_LOGIC;
		Clk_x16  : IN  STD_LOGIC;
		Time     : IN  STD_LOGIC_VECTOR( 19 DOWNTO 0 );
		ARST     : IN  STD_LOGIC;
		Single   : IN  STD_LOGIC;
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
	
	COMPONENT AvMM2Mux1 IS
  GENERIC(
    DataWidth : INTEGER := 32;
    AddrWidth : INTEGER := 16
  );
  PORT(
    Avalon_Clock       : IN STD_LOGIC;
    Avalon_nReset      : IN STD_LOGIC;
    AVI1_waitrequest   : OUT STD_LOGIC;
    AVI1_address       : IN  STD_LOGIC_VECTOR( ( AddrWidth - 1 )  DOWNTO 0 );
    AVI1_byteenable    : IN  STD_LOGIC_VECTOR( (DataWidth/8 - 1 ) DOWNTO 0 );
    AVI1_read          : IN  STD_LOGIC;
    AVI1_readdata      : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
    AVI1_readdatavalid : OUT STD_LOGIC;
    AVI1_write         : IN  STD_LOGIC;
    AVI1_writedata     : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
    AVI2_waitrequest   : OUT STD_LOGIC;
    AVI2_address       : IN  STD_LOGIC_VECTOR( ( AddrWidth - 1 ) DOWNTO 0 );
    AVI2_byteenable    : IN  STD_LOGIC_VECTOR( ( DataWidth/8 - 1 ) DOWNTO 0 );
    AVI2_read          : IN  STD_LOGIC;
    AVI2_readdata      : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
    AVI2_readdatavalid : OUT STD_LOGIC;
    AVI2_write         : IN  STD_LOGIC;
    AVI2_writedata     : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
    AVMO_waitrequest   : IN  STD_LOGIC;
    AVMO_address       : OUT STD_LOGIC_VECTOR( ( AddrWidth - 1 ) DOWNTO 0 );
    AVMO_byteenable    : OUT STD_LOGIC_VECTOR( ( DataWidth/8 - 1 ) DOWNTO 0 );
    AVMO_read          : OUT STD_LOGIC;
    AVMO_readdata      : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
    AVMO_readdatavalid : IN  STD_LOGIC;
    AVMO_write         : OUT STD_LOGIC;
    AVMO_writedata     : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 )
  );
  END COMPONENT;
  
  TYPE   T_Avalon_State     IS ( AVALON_RESET, AVALON_IDLE,  AVALON_WRITE, AVALON_READ );
  TYPE   T_Conf_Registers   IS ARRAY( 7 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  
  ATTRIBUTE enum_encoding : STRING;
  ATTRIBUTE enum_encoding OF T_Avalon_State : TYPE IS "safe,one-hot";
  
  SIGNAL Signal_SlaveState  : T_Avalon_State;
  
  SIGNAL Signal_Registers   : T_Conf_Registers;
  
  -------------- A429_TX PHY Signals --------------------
  SIGNAL PHY_Enable_IN    :  STD_LOGIC := '0';
  SIGNAL PHY_ClockIn_IN   :  STD_LOGIC := '0';
  SIGNAL PHY_ClockMux_IN  :  STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
  SIGNAL PHY_WrClk_IN     :  STD_LOGIC := '0';
  SIGNAL PHY_WrEn_IN      :  STD_LOGIC := '0';
  SIGNAL PHY_Full_OUT     :  STD_LOGIC := '0';
  SIGNAL PHY_Data_IN      :  STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL PHY_OutputA_OUT  :  STD_LOGIC := '0';
  SIGNAL PHY_OutputB_OUT  :  STD_LOGIC := '0';
  SIGNAL PHY_SlewRate_OUT :  STD_LOGIC := '0';
  SIGNAL PHY_OutReg_OUT   :  STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL PHY_Busy_OUT     :  STD_LOGIC := '0';
  
  --------------- A429_TxControl signals -----------------
  SIGNAL CTRL_Enable_IN      : STD_LOGIC := '0';
  SIGNAL CTRL_Clk_IN         : STD_LOGIC := '0'; -- 1600 kHz
  SIGNAL CTRL_AvClk_IN       : STD_LOGIC := '0';    
  SIGNAL CTRL_WordIn_IN      : STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_TxStart_IN     : STD_LOGIC := '0';
  SIGNAL CTRL_TestEn_IN      : STD_LOGIC := '0';
  SIGNAL CTRL_Load_IN        : STD_LOGIC := '0';
  SIGNAL CTRL_LineBusy_IN    : STD_LOGIC := '0';
  SIGNAL CTRL_ConfReg_IN     : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_TxPhyBusy_IN   : STD_LOGIC := '0';
  SIGNAL CTRL_WrEn_OUT       : STD_LOGIC := '0';
  SIGNAL CTRL_Addr_OUT       : STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_RdEn_OUT       : STD_LOGIC := '0';
  SIGNAL CTRL_WrData_OUT     : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_Full_IN        : STD_LOGIC := '0';
  SIGNAL CTRL_ClkMUX_OUT     : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_EnableTx_OUT   : STD_LOGIC := '0';
  SIGNAL CTRL_State_OUT      : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_BuffBusy_IN    : STD_LOGIC := '0';
  SIGNAL CTRL_StateRegRst_IN : STD_LOGIC := '0';
  SIGNAL CTRL_RAMWrAddr_IN   : STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_RAM_WrEn_IN    : STD_LOGIC := '0';
  SIGNAL CTRL_ByteEn_OUT     : STD_LOGIC_VECTOR( ( ( AV_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_TxMode_OUT     : STD_LOGIC := '0';
  SIGNAL CTRL_RamFull_OUT    : STD_LOGIC := '0';
  SIGNAL CTRL_TxPause_OUT    : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_AVM_RdValid_IN : STD_LOGIC := '0';
  SIGNAL CTRL_TxLineErr_IN   : STD_LOGIC := '0';
  SIGNAL CTRL_AddrRol_IN     : STD_LOGIC := '0';
  SIGNAL CTRL_FreeSpace_OUT  : STD_LOGIC_VECTOR( 15 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL CTRL_nEmpty_IN      : STD_LOGIC := '0';
  
  ---------------- TX Line control signals -----------------
  SIGNAL TXCHK_Enable_IN    : STD_LOGIC := '0';
  SIGNAL TXCHK_ClockIn_IN   : STD_LOGIC := '0';
  SIGNAL TXCHK_ClockMux_IN  : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
  SIGNAL TXCHK_InputA_IN    : STD_LOGIC := '0';
  SIGNAL TXCHK_InputB_IN    : STD_LOGIC := '0';
  SIGNAL TXCHK_TxCntrl_IN   : STD_LOGIC := '0';   -- if = '1' set receiver in Tx_Checker mode 
  SIGNAL TXCHK_InReg_IN     : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL TXCHK_RxInvert_IN  : STD_LOGIC := '0';   -- if = '1' then invert received bits
  SIGNAL TXCHK_ParOFF_IN    :  STD_LOGIC := '0';
  SIGNAL TXCHK_Ready_OUT    : STD_LOGIC := '0';    
  SIGNAL TXCHK_DataOut_OUT  : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL TXCHK_ParErr_OUT   : STD_LOGIC := '0';
  SIGNAL TXCHK_TxErr_OUT    : STD_LOGIC := '0';
  SIGNAL TXCHK_RxFlag_OUT   : STD_LOGIC := '0';
  SIGNAL TXCHK_RdClk_IN     : STD_LOGIC := '0';
  SIGNAL TXCHK_RdReq_IN     : STD_LOGIC := '0';
  SIGNAL TXCHK_nEmpty_OUT   : STD_LOGIC := '0';
  
  --------------- Timer Signals ----------------------
  SIGNAL TIM_Enable_IN  :  STD_LOGIC := '0';
  SIGNAL TIM_Clk_x16_IN :  STD_LOGIC := '0';
  SIGNAL TIM_Time_IN    :  STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL TIM_ARST_IN    :  STD_LOGIC := '0';
  SIGNAL TIM_Single_IN  :  STD_LOGIC := '0'; -- 1 = Single, 0 - continuous work
  SIGNAL TIM_Ready_OUT  :  STD_LOGIC := '0';
  
  -------------- Avalon-MM Master Signals -------------
  SIGNAL AVM1_nReset_IN            :  STD_LOGIC := '0';
  SIGNAL AVM1_Clock_IN             :  STD_LOGIC := '0';
  SIGNAL AVM1_WrEn_IN              :  STD_LOGIC := '0';
  SIGNAL AVM1_RdEn_IN              :  STD_LOGIC := '0';
  SIGNAL AVM1_AddrIn_IN            :  STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL AVM1_WrDataIn_IN          :  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL AVM1_ByteEnCode_IN        :  STD_LOGIC_VECTOR( ( ( AV_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL AVM1_Ready_OUT            :  STD_LOGIC := '0';
  SIGNAL AVM1_RdDataOut_OUT        :  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  
  SIGNAL AVM1_avm_waitrequest_IN   :  STD_LOGIC := '0';
  SIGNAL AVM1_avm_readdata_IN      :  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL AVM1_avm_readdatavalid_IN :  STD_LOGIC := '0';
  SIGNAL AVM1_avm_address_OUT      :  STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL AVM1_avm_byteenable_OUT   :  STD_LOGIC_VECTOR( ( ( AV_DATA_WIDTH / 8 ) - 1 )  DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL AVM1_avm_read_OUT         :  STD_LOGIC := '0';
  SIGNAL AVM1_avm_write_OUT        :  STD_LOGIC := '0';
  SIGNAL AVM1_avm_writedata_OUT    :  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  
  ---------------- LOCAL SIGNALS ----------------------
  SIGNAL LOC_TestEn    : STD_LOGIC := '0'; --not driven? but used for test initiation  
  SIGNAL LOC_IntReaded : STD_LOGIC := '0';
  
  SIGNAL address : INTEGER RANGE 0 TO 7; 
  SIGNAL data    : STD_LOGIC_VECTOR( 31 DOWNTO 0 ); 
  
BEGIN
  
  TxPHY: a429_txphy 
  PORT MAP(
    Enable      => PHY_Enable_IN,    
    ClockIn     => PHY_ClockIn_IN,   
    ClockMux    => PHY_ClockMux_IN,  
    ------------- FIFO Signals ------------------
    Data        => PHY_Data_IN, 
    WrClk       => PHY_WrClk_IN,  
    WrEn        => PHY_WrEn_IN,   
    Full        => PHY_Full_OUT,  
    ---------- PHY OUT Signals -----------------
    OutputA     => PHY_OutputA_OUT,  
    OutputB     => PHY_OutputB_OUT,  
    SlewRate    => PHY_SlewRate_OUT, 
    OutReg      => PHY_OutReg_OUT,   
    Busy        => PHY_Busy_OUT     
  );
  
  TxCntrl: a429_TxControl
  PORT MAP(
    Enable    =>  CTRL_Enable_IN,
    AvClk     =>  CTRL_AvClk_IN,
    WordIn    =>  CTRL_WordIn_IN,
    TxStart   =>  CTRL_TxStart_IN,
    TestEn    =>  CTRL_TestEn_IN,
    Load      =>  CTRL_Load_IN,
    LineBusy  =>  CTRL_LineBusy_IN,
    ConfReg   =>  CTRL_ConfReg_IN,
    TxPhyBusy =>  CTRL_TxPhyBusy_IN,
    TxLineErr =>  CTRL_TxLineErr_IN,
    WrEn      =>  CTRL_WrEn_OUT,
    Addr      =>  CTRL_Addr_OUT,
    RdEn      =>  CTRL_RdEn_OUT,
    WrData    =>  CTRL_WrData_OUT,
    Full      =>  CTRL_Full_IN,
    ClkMUX    =>   CTRL_ClkMUX_OUT,
    BuffBusy  =>   CTRL_BuffBusy_IN,
    State     =>   CTRL_State_OUT,
    StateRegRst => CTRL_StateRegRst_IN,
    AVM_RdValid => CTRL_AVM_RdValid_IN,
    RAMWrAddr   => CTRL_RAMWrAddr_IN,    
    RAM_WrEn  =>   CTRL_RAM_WrEn_IN,
    AddrRol   =>   CTRL_AddrRol_IN,
    ByteEn    =>   CTRL_ByteEn_OUT,
    TxMode    =>   CTRL_TxMode_OUT,
    FreeSpace =>   CTRL_FreeSpace_OUT,
    TxPause   =>   CTRL_TxPause_OUT
  );
  
  tim1: timer 
  PORT MAP(
    Enable   => TIM_Enable_IN,  
    Clk_x16  => TIM_Clk_x16_IN, 
    Time     => TIM_Time_IN,    
    ARST     => TIM_ARST_IN,    
    Single   => TIM_Single_IN,  
    Ready    => TIM_Ready_OUT  
  );
  
  LineCtrl: a429_RxPhy 
  GENERIC MAP(
    DataWidth    => 32,  
    StopWidth    => 4, -- added timer for minimal time pause 
    Pack_WN      => 2, 
    UsedWidth    => 1 
  )
  PORT MAP(
    Enable      => TXCHK_Enable_IN,   
    ClockIn     => TXCHK_ClockIn_IN,  
    ClockMux    => TXCHK_ClockMux_IN, 
    InputA      => TXCHK_InputA_IN,   
    InputB      => TXCHK_InputB_IN,   
    TxCntrl     => TXCHK_TxCntrl_IN,  
    InReg       => TXCHK_InReg_IN,    
    RxInvert    => TXCHK_RxInvert_IN, 
    RdClk       => TXCHK_RdClk_IN, 
    RdReq       => TXCHK_RdReq_IN,   
    ParOFF      => TXCHK_ParOFF_IN,
    nEmpty      => open, --TXCHK_nEmpty_OUT,   
    DataOut     => open, --TXCHK_DataOut_OUT, 
    ------ not buf
    ParErr      => open, --TXCHK_ParErr_OUT, 
    TxErr       => TXCHK_TxErr_OUT,          
    RxFlag      => TXCHK_RxFlag_OUT          
  );
  
  avm1: AVMM_Master
  GENERIC MAP(
    CLOCK_FREQUENCE       => 62500000,
    AVM_WRITE_ACKNOWLEDGE => 15,
    AVM_READ_ACKNOWLEDGE  => 15,
    AVM_DATA_WIDTH        => AV_DATA_WIDTH,
    AVM_ADDR_WIDTH        => AR429TX_ADDR_WIDTH
  )
  PORT MAP(
    nReset            => AVM1_nReset_IN,            
    Clock             => AVM1_Clock_IN,             
    WrEn              => AVM1_WrEn_IN,              
    RdEn              => AVM1_RdEn_IN,              
    AddrIn            => AVM1_AddrIn_IN,            
    WrDataIn          => AVM1_WrDataIn_IN,          
    ByteEnCode        => AVM1_ByteEnCode_IN,        
    Ready             => AVM1_Ready_OUT,            
    RdDataOut         => AVM1_RdDataOut_OUT,        
    avm_waitrequest   => AVM1_avm_waitrequest_IN,   
    avm_readdata      => AVM1_avm_readdata_IN,      
    avm_readdatavalid => AVM1_avm_readdatavalid_IN, 
    avm_address       => AVM1_avm_address_OUT,      
    avm_byteenable    => AVM1_avm_byteenable_OUT,   
    avm_read          => AVM1_avm_read_OUT,         
    avm_write         => AVM1_avm_write_OUT,        
    avm_writedata     => AVM1_avm_writedata_OUT    
  );
  
  -------------- Reset Sysytem ---------------------
  CTRL_Enable_IN  <= ( Signal_Registers( TXCONFIG_REG_ADDR )( CLKMUX_H ) OR Signal_Registers( TXCONFIG_REG_ADDR )( CLKMUX_L ) );
  PHY_Enable_IN   <= CTRL_Enable_IN; --CTRL_EnableTx_OUT;
  TIM_Enable_IN   <= CTRL_Enable_IN; --CTRL_EnableTx_OUT;
  AVM1_nReset_IN  <= Avalon_nReset;
  TXCHK_Enable_IN <= CTRL_Enable_IN; --CTRL_EnableTx_OUT;
  
  -------------- Clock Sysytem ---------------------
  PHY_ClockIn_IN   <= A429_Clock;
  PHY_WrClk_IN     <= Avalon_Clock;
  CTRL_Clk_IN      <= A429_Clock;
  CTRL_AvClk_IN    <= Avalon_Clock;
  TIM_Clk_x16_IN   <= A429_Clock;
  AVM1_Clock_IN    <= Avalon_Clock;
  TXCHK_ClockIn_IN <= A429_Clock;
  TXCHK_RdClk_IN   <= '0'; --Avalon_Clock;
  
  ------------- A429 TX PHY connection ----------------
  PHY_ClockMux_IN <= CTRL_ClkMUX_OUT; 
  PHY_WrEn_IN     <= CTRL_WrEn_OUT;
  PHY_Data_IN     <= CTRL_WrData_OUT;
  A429_LineA      <= PHY_OutputA_OUT;
  A429_LineB      <= PHY_OutputB_OUT;
  A429_Slp        <= PHY_SlewRate_OUT;
  TxReg           <= PHY_OutReg_OUT;
  TxFlag          <= PHY_Busy_OUT;
  
  ----------- Tx Line Control Connection -----------------
  TXCHK_ClockMux_IN <= CTRL_ClkMUX_OUT;
  TXCHK_InputA_IN   <= A429_CtrlA;
  TXCHK_InputB_IN   <= A429_CtrlB;
  TXCHK_TxCntrl_IN  <= '1';
  TXCHK_InReg_IN    <= PHY_OutReg_OUT;
  TXCHK_RxInvert_IN <= '0';
  TXCHK_RdReq_IN    <= CTRL_WrEn_OUT;
  
  --------------- A429 TX CONTROL connections -------------
  CTRL_WordIn_IN      <= AVM1_RdDataOut_OUT;
  CTRL_TxStart_IN     <= TIM_Ready_OUT;
  CTRL_TestEn_IN      <= LOC_TestEn;
  CTRL_Load_IN        <= AVM1_Ready_OUT;
  CTRL_LineBusy_IN    <= RxLineBusy;
  CTRL_ConfReg_IN     <= Signal_Registers( TXCONFIG_REG_ADDR ); 
  CTRL_TxPhyBusy_IN   <= PHY_Busy_OUT;
  CTRL_StateRegRst_IN <= LOC_IntReaded; 
  CTRL_RAM_WrEn_IN    <= AV2PCIE_write;
  
  -------------- FOR SINTHESYS (uncomment) -----------------
  CTRL_BuffBusy_IN    <= Signal_Registers( TXCONFIG_REG_ADDR )( CPU_BUFF_BUSY );
  CTRL_AVM_RdValid_IN <= AVM1_avm_readdatavalid_IN;
  CTRL_RAMWrAddr_IN   <= AV2PCIE_address;
  CTRL_TxLineErr_IN   <= TXCHK_TxErr_OUT WHEN ( ( TXCHK_Ready_OUT AND PHY_Busy_OUT )  = '1' ) ELSE '0'; 
  CTRL_Full_IN        <= PHY_Full_OUT;
  CTRL_AddrRol_IN     <= Signal_Registers( TXCONFIG_REG_ADDR )( ADDR_NROL );
  
  --------------- Avalon-MM Master connection ------------
  AVM1_WrEn_IN       <= '0';
  AVM1_RdEn_IN       <= CTRL_RdEn_OUT;
  AVM1_AddrIn_IN     <= CTRL_Addr_OUT;
  AVM1_WrDataIn_IN   <= ( OTHERS => '0' );
  AVM1_ByteEnCode_IN <= CTRL_ByteEn_OUT;
  
  --------------- Timer Connections ----------------------
  TIM_Single_IN <= '0'; --CTRL_TxMode_OUT;
  TIM_Time_IN   <= CTRL_TxPause_OUT;
  TIM_ARST_IN   <= PHY_Busy_OUT OR TXCHK_RxFlag_OUT;   --RxLineBusy;
  
    ---------------- Avalon Ports Connection ----------------
  ------------- Avalon-MM to RAM1 ------------------
  AVM1_avm_waitrequest_IN   <=   AV2RAM_waitrequest;
  AV2RAM_address            <=   AVM1_avm_address_OUT;         
  AV2RAM_byteenable         <=   AVM1_avm_byteenable_OUT;
  AVM1_avm_readdatavalid_IN <=   AV2RAM_readdatavalid;
  AV2RAM_read               <=   AVM1_avm_read_OUT;
  AVM1_avm_readdata_IN      <=   AV2RAM_readdata;      
  AV2RAM_write              <=   AVM1_avm_write_OUT;       
  AV2RAM_writedata          <=   AVM1_avm_writedata_OUT;    
  
  ---------------- Avalon-MM PCIE to RAM --------------------
  AV2PCIE_waitrequest    <= AV2RAM2_waitrequest;   
  AV2RAM2_address        <= AV2PCIE_address; 
  AV2RAM2_byteenable     <= AV2PCIE_byteenable;
  AV2RAM2_read           <= AV2PCIE_read;
  AV2PCIE_readdata       <= AV2RAM2_readdata;      
  AV2PCIE_readdatavalid  <= AV2RAM2_readdatavalid; 
  AV2RAM2_write          <= AV2PCIE_write;
  AV2RAM2_writedata      <= AV2PCIE_writedata;
  
  Interrupt_GEN: PROCESS( Avalon_Clock ) -- generate repeatable events interrupts
  BEGIN
    IF RISING_EDGE( Avalon_Clock ) THEN 
      IF ( CTRL_State_OUT AND Signal_Registers( TXINTMASK_REG_ADDR ) ) = x"00000000" THEN
        Interrupt <= '0';
      ELSE
        Interrupt <= '1';
      END IF;
    END IF;
  END PROCESS;
  
  -- Settings registers ( Avalon-MM Slave )
  
  PROCESS( Avalon_nReset, Avalon_Clock )
    VARIABLE IntFlagReg_LOC  : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
    VARIABLE IntFlagReg_PREV : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
    VARIABLE IntFlagReg_DIF  : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
    VARIABLE busy_cnt        : INTEGER RANGE 0 TO 7 := 0;
  BEGIN
    
    IF( Avalon_nReset = '0' ) THEN
      
      AVS_waitrequest   <= '1';
      AVS_readdatavalid <= '0';
      AVS_readdata      <= ( OTHERS => '0' );
      Signal_Registers  <= ( x"FFFFFFFF", x"FFFFFFFF", x"FFFFFFFF", x"FFFFFFFF", x"FFFFFFFF", x"00000000", x"0000000C", x"00000003" );
      Signal_SlaveState <= AVALON_RESET;
      
    ELSIF( ( Avalon_Clock'EVENT ) AND ( Avalon_Clock = '1' ) ) THEN
      
      IF( IntFlagReg_DIF /= x"00000000" ) THEN
        IntFlagReg_LOC( 3 DOWNTO 0 ) := IntFlagReg_LOC( 3 DOWNTO 0 ) OR CTRL_State_OUT( 3 DOWNTO 0 );  
      ELSIF LOC_IntReaded = '1' THEN
        IntFlagReg_LOC( 3 DOWNTO 0 ) := ( OTHERS => '0' );
      END IF;
      
      IF( RxTestEn = '1' ) THEN
        IntFlagReg_LOC( INA_TEST ) := A429_CtrlA;  -- In protocol this is A429_CtrlB in test mode (schematic bug)
        IntFlagReg_LOC( INB_TEST ) := A429_CtrlB;  -- In protocol this is A429_CtrlA in test mode (schematic bug)
      ELSE
        IntFlagReg_LOC( INA_TEST ) := '0';
        IntFlagReg_LOC( INB_TEST ) := '0';
      END IF;
      
      IntFlagReg_DIF  := IntFlagReg_PREV XOR CTRL_State_OUT;
      IntFlagReg_PREV := CTRL_State_OUT;
      
      Signal_Registers( TXINTFLAG_REG_ADDR )( 15 DOWNTO 0 ) <= IntFlagReg_LOC( 15 DOWNTO 0 );
      Signal_Registers( TXINTFLAG_REG_ADDR )( TX_FREESPACE_H DOWNTO TX_FREESPACE_L ) <= CTRL_FreeSpace_OUT( ( TX_FREESPACE_H - TX_FREESPACE_L ) DOWNTO 0 );
      
      IF( ( AVM1_WrEn_IN = '1' ) OR ( AVM1_RdEn_IN = '1' ) OR ( AVM1_avm_read_OUT = '1' ) OR ( AVM1_avm_write_OUT = '1' ) ) THEN
        Signal_Registers( TXINTFLAG_REG_ADDR )( TXFPGA_BUFF_BUSY ) <= '1';
        busy_cnt := 0;
      ELSE
        IF busy_cnt < 7 THEN
          busy_cnt := busy_cnt + 1;
        ELSE
          busy_cnt := 0;
          Signal_Registers( TXINTFLAG_REG_ADDR )( TXFPGA_BUFF_BUSY ) <= '0';
        END IF;
      END IF;
      
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
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
        LOC_IntReaded     <= '0';
        address           <= ( TO_INTEGER( UNSIGNED( AVS_address ) ) );
        data              <= AVS_writedata;
      
      WHEN AVALON_WRITE =>
        AVS_waitrequest             <= '1';
        AVS_readdatavalid           <= '0';
        AVS_readdata                <= ( OTHERS => '0' );
        Signal_Registers( address ) <= data;
        Signal_SlaveState           <= AVALON_IDLE;
      
      WHEN AVALON_READ =>
        IF( address = TXINTFLAG_REG_ADDR ) THEN
          LOC_IntReaded <= '1';
        END IF;
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '1';
        AVS_readdata      <= Signal_Registers( address );
        Signal_SlaveState <= AVALON_IDLE;
      
      WHEN OTHERS =>
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
        data              <= ( OTHERS => '0' );
        address           <= 0;
        Signal_SlaveState <= AVALON_IDLE;
      
      END CASE;
      
      
    END IF;
    
  END PROCESS;
  
  
  
END logic;
