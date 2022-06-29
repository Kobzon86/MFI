-- A429_Receiver v.02
-- With Avalon-MM interface transaction for RAM_BUFFER
-- from PCIE-core
-- Added FIFO-mode realisation
-- Added calculation of number available words to read from RAM_Buffer in FIFO-mode
-- Added RAM for address mask

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.arinc429rx_pkg.ALL;

ENTITY A429_Receiver IS
  
  PORT(
    
    Avalon_nReset     : IN  STD_LOGIC := '0';
    Avalon_Clock      : IN  STD_LOGIC;
    
    AVS_waitrequest   : OUT STD_LOGIC;
    AVS_address       : IN  STD_LOGIC_VECTOR( ( AVCFG_ADDR_WIDTH - 1 )  DOWNTO 0 );
    AVS_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    AVS_read          : IN  STD_LOGIC;
    AVS_readdata      : OUT STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
    AVS_readdatavalid : OUT STD_LOGIC;
    AVS_write         : IN  STD_LOGIC;
    AVS_writedata     : IN  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
    
    --------- Avalon-MM signals to RAM port1 receiver to RAM --------------------
    AV2RAM_waitrequest   : IN  STD_LOGIC;
    AV2RAM_address       : OUT STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
    AV2RAM_byteenable    : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    AV2RAM_read          : OUT STD_LOGIC;
    AV2RAM_readdata      : IN  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV2RAM_readdatavalid : IN  STD_LOGIC;
    AV2RAM_write         : OUT STD_LOGIC;
    AV2RAM_writedata     : OUT STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
    
        --------- Avalon-MM signals to RAM port2 PCIE to RAM --------------------
    AV2RAM2_waitrequest   : IN  STD_LOGIC;
    AV2RAM2_address       : OUT STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
    AV2RAM2_byteenable    : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    AV2RAM2_read          : OUT STD_LOGIC;
    AV2RAM2_readdata      : IN  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV2RAM2_readdatavalid : IN  STD_LOGIC;
    AV2RAM2_write         : OUT STD_LOGIC;
    AV2RAM2_writedata     : OUT STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
    
    ---------- Avalon-MM signals from PCIE  ------------------
    AV2PCIE_waitrequest   : OUT STD_LOGIC;
    AV2PCIE_address       : IN  STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
    AV2PCIE_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    AV2PCIE_read          : IN  STD_LOGIC;
    AV2PCIE_readdata      : OUT STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV2PCIE_readdatavalid : OUT STD_LOGIC;
    AV2PCIE_write         : IN  STD_LOGIC;
    AV2PCIE_writedata     : IN  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
    
    Interrupt         : OUT STD_LOGIC;
    
    A429_Clock        : IN  STD_LOGIC;
    A429_TestA        : OUT STD_LOGIC;
    A429_TestB        : OUT STD_LOGIC;
    A429_LineA        : IN  STD_LOGIC;
    LineBusy          : OUT STD_LOGIC;
    SentWordIn        : IN  STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
    RxTestEn          : OUT STD_LOGIC;
    A429_LineB        : IN  STD_LOGIC
    
  );
  
END A429_Receiver;

ARCHITECTURE logic OF A429_Receiver IS
  
  COMPONENT a429_RxPhy IS
    GENERIC(
      DataWidth    : INTEGER := 32;
      StopWidth    : INTEGER := 4;
      Pack_WN      : INTEGER := 16;
      UsedWidth    : INTEGER := 4  -- 2 ** USedWidth = Pack_WN
    );
    PORT(
      Enable      : IN  STD_LOGIC := '1';
      ClockIn     : IN  STD_LOGIC;
      ClockMux    : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
      InputA      : IN  STD_LOGIC := '0';
      InputB      : IN  STD_LOGIC := '0';
      TxCntrl     : IN  STD_LOGIC;   -- if = '1' set receiver in Tx_Checker mode 
      InReg       : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
      RxInvert    : IN  STD_LOGIC;   -- if = '1' then invert received bits
      RdClk       : IN  STD_LOGIC;
      RdReq       : IN  STD_LOGIC;
      ParOFF      : IN  STD_LOGIC;
      nEmpty      : OUT STD_LOGIC;    
      DataOut     : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
      ------ not buffered output signals (RxPhy STATE) -----
      ParErr      : OUT STD_LOGIC;
      TxErr       : OUT STD_LOGIC;
      RxFlag      : OUT STD_LOGIC
    );
  END COMPONENT;
  
  
  COMPONENT A429_RxControl IS
    PORT(
      EnableRx   : IN  STD_LOGIC;
      Clk        : IN  STD_LOGIC;
      nEmpty     : IN  STD_LOGIC;
      RdEn       : OUT STD_LOGIC;
      RxData     : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
      ParErr     : IN  STD_LOGIC;
      TxErr      : IN  STD_LOGIC;
      Mask       : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
      MaskRdEn   : OUT STD_LOGIC;
      AddrMask   : OUT STD_LOGIC_VECTOR( ( MASK_ADDR_WIDTH - 1 )  DOWNTO 0 );  -- RAM MASK read address
      RdMode     : IN  STD_LOGIC;                                              -- 0 = File mode, 1 = address mode
      RxFlag     : IN  STD_LOGIC;
      TestEn     : IN  STD_LOGIC;
      RxSubAddr  : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 ); 
      RAMBusy    : IN  STD_LOGIC;
      AddrRol    : IN  STD_LOGIC;
      WrEn       : OUT STD_LOGIC;
      DataOut    : OUT STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
      ByteEn     : OUT STD_LOGIC_VECTOR( ( ( AR429_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 ); 
      RAMAddr    : OUT STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
      RxStateReg : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 )
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
  
  COMPONENT RingBuffPtr IS
    GENERIC(
      ADDR_WIDTH : INTEGER := 8;
      START_ADDR : INTEGER := 0;
      BUFF_LEN   : INTEGER := 16
    );
    PORT(
      Enable     : IN  STD_LOGIC;
      Clk        : IN  STD_LOGIC;
      WrEn       : IN  STD_LOGIC;
      RdEn       : IN  STD_LOGIC;
      RdPtr      : OUT STD_LOGIC_VECTOR( ( ADDR_WIDTH - 1 ) DOWNTO 0 );
      WordsAvail : OUT STD_LOGIC_VECTOR( ( ADDR_WIDTH - 1 ) DOWNTO 0 )
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
  
  COMPONENT RAM IS
    GENERIC(
      DataWidth : INTEGER := 8;
      AddrWidth : INTEGER := 9
    );
    PORT(
      address : IN STD_LOGIC_VECTOR ( ( AddrWidth - 1 ) DOWNTO 0 );
      clock   : IN STD_LOGIC := '1';
      data    : IN STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0 );
      rden    : IN STD_LOGIC := '1';
      wren    : IN STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0 )
    );
  END COMPONENT;
  
  TYPE T_Avalon_State   IS ( AVALON_IDLE, AVALON_WRITE, AVALON_READ, AVALON_ACK_READ, RAM_RD, RAM_WR, AVALON_RESET );
  TYPE T_Conf_Registers IS ARRAY( 3 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  
  ATTRIBUTE enum_encoding                   : STRING;
  ATTRIBUTE enum_encoding OF T_Avalon_State : TYPE IS "safe,one-hot";
  
  SIGNAL Signal_SlaveState  : T_Avalon_State;
  SIGNAL Signal_Registers   : T_Conf_Registers; -- default RxFreq = 100 kHz,  ADDRESS_MODE operation
  
  -------------- A429 PHY SIGNALS -----------------------
  SIGNAL PHY_Enable_IN   : STD_LOGIC := '1';
  SIGNAL PHY_ClockIn_IN  : STD_LOGIC := '0';
  SIGNAL PHY_ClockMux_IN : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
  SIGNAL PHY_InputA_IN   : STD_LOGIC := '0';
  SIGNAL PHY_InputB_IN   : STD_LOGIC := '0';
  SIGNAL PHY_TxCntrl_IN  : STD_LOGIC := '0';   -- if = '1' set receiver in Tx_Checker mode 
  SIGNAL PHY_InReg_IN    : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL PHY_RxInvert_IN : STD_LOGIC := '0';   -- if = '1' then invert received bits
  SIGNAL PHY_RdEn_IN     : STD_LOGIC := '0';    
  SIGNAL PHY_DataOut_OUT : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL PHY_ParErr_OUT  : STD_LOGIC := '0';
  SIGNAL PHY_TxErr_OUT   : STD_LOGIC := '0';
  SIGNAL PHY_RxFlag_OUT  : STD_LOGIC := '0';
  SIGNAL PHY_nEmpty_OUT  : STD_LOGIC := '0';
  SIGNAL PHY_ParOFF_IN   : STD_LOGIC := '0'; 
  
  -------------- A429 RxControl SIGNALS -----------------
  SIGNAL CTRL_EnableRx_IN    :  STD_LOGIC := '0';
  SIGNAL CTRL_Load_IN        :  STD_LOGIC := '0';
  SIGNAL CTRL_RxData_IN      :  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  SIGNAL CTRL_ParErr_IN      :  STD_LOGIC := '0';
  SIGNAL CTRL_TxErr_IN       :  STD_LOGIC := '0';
  SIGNAL CTRL_Mask_IN        :  STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_RdMode_IN      :  STD_LOGIC := '0';  -- 0 = File mode, 1 = address mode
  SIGNAL CTRL_RAMRdAddr_IN   :  STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_RxFlag_IN      :  STD_LOGIC := '0';
  SIGNAL CTRL_TestEn_IN      :  STD_LOGIC := '0';
  SIGNAL CTRL_WrEn_OUT       :  STD_LOGIC := '0';
  SIGNAL CTRL_DataOut_OUT    :  STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_ByteEn_OUT     :  STD_LOGIC_VECTOR( ( ( AR429_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
  SIGNAL CTRL_RAMAddr_OUT    :  STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_RxStateReg_OUT :  STD_LOGIC_VECTOR(  7 DOWNTO 0 );
  SIGNAL CTRL_RAMEmpty_OUT   :  STD_LOGIC := '0';
  SIGNAL CTRL_RxWrdCnt_OUT   :  STD_LOGIC_VECTOR( 9 DOWNTO 0 );
  SIGNAL CTRL_AVM_Write_IN   :  STD_LOGIC := '0';
  SIGNAL CTRL_nEmpty_IN      :  STD_LOGIC := '0';
  SIGNAL CTRL_AddrRol_IN     :  STD_LOGIC := '0';
  SIGNAL CTRL_RdEn_OUT       :  STD_LOGIC := '0';
  SIGNAL CTRL_RAMBusy_IN     :  STD_LOGIC := '0';
  SIGNAL CTRL_MaskRdEn       :  STD_LOGIC := '0';
  SIGNAL CTRL_AddrMask_OUT   :  STD_LOGIC_VECTOR( ( MASK_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_RdPoint_OUT    :  STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_RxSubAddr_OUT  :  STD_LOGIC_VECTOR( 7 DOWNTO 0 ); 
  
  --------------- Avalon-MM Master Signals --------------
  SIGNAL AVM_nReset_IN            : STD_LOGIC := '0';
  SIGNAL AVM_Clock_IN             : STD_LOGIC := '0';
  SIGNAL AVM_WrEn_IN              : STD_LOGIC := '0';
  SIGNAL AVM_RdEn_IN              : STD_LOGIC := '0';
  SIGNAL AVM_AddrIn_IN            : STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AVM_WrDataIn_IN          : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AVM_ByteEnCode_IN        : STD_LOGIC_VECTOR( ( ( AR429_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
  SIGNAL AVM_Ready_OUT            : STD_LOGIC := '0';
  SIGNAL AVM_RdDataOut_OUT        : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );

  SIGNAL AVM_avm_waitrequest_IN   : STD_LOGIC := '0';
  SIGNAL AVM_avm_readdata_IN      : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AVM_avm_readdatavalid_IN : STD_LOGIC := '0';
  SIGNAL AVM_avm_address_OUT      : STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AVM_avm_byteenable_OUT   : STD_LOGIC_VECTOR( ( ( AR429_DATA_WIDTH / 8 ) - 1 )  DOWNTO 0 );
  SIGNAL AVM_avm_read_OUT         : STD_LOGIC := '0';
  SIGNAL AVM_avm_write_OUT        : STD_LOGIC := '0';
  SIGNAL AVM_avm_writedata_OUT    : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );

  ----------------- RAM CONFIG signals ---------------------
  SIGNAL RAM_address : STD_LOGIC_VECTOR ( ( MASK_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL RAM_clock   : STD_LOGIC;
  SIGNAL RAM_data    : STD_LOGIC_VECTOR ( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL RAM_rden    : STD_LOGIC;
  SIGNAL RAM_wren    : STD_LOGIC;
  SIGNAL RAM_q       : STD_LOGIC_VECTOR ( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 );

  --------------- Local AR429 Receiver Signals --------------
  SIGNAL LOC_Enable   : STD_LOGIC := '0';
  
  SIGNAL LOC_RdMode           : STD_LOGIC := '0';
  SIGNAL LOC_ClkMUX           : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );  
  SIGNAL LOC_TxWrd            : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );  -- Word from transmitter send to media
  SIGNAL LOC_IntFlagReg       : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL LOC_StateReg_DIF     : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL LOC_StateReg_PREV    : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
  
  SIGNAL LOC_IntRegRead       : STD_LOGIC := '0';
  SIGNAL StateReg_Change      : STD_LOGIC := '0';  -- show if any bit in RxStateReg_OUT was set
  
  SIGNAL TEST_ENABLE          : STD_LOGIC := '0';
  SIGNAL TESTA_INP, TESTB_INP : STD_LOGIC := '0';
  SIGNAL INPA_TEST, INPB_TEST : STD_LOGIC := '0';
  SIGNAL AV2RAM_write_LOC     : STD_LOGIC := '0';
  SIGNAL AV2RAM2_read_LOC     : STD_LOGIC := '0';
  
  SIGNAL wr1, wr2, wr_pulse   : STD_LOGIC := '0';
  SIGNAL rd1, rd2, rd_pulse   : STD_LOGIC := '0';
  SIGNAL AV2RAM_address_LOC   : STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL AV2RAM2_address_LOC  : STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );

  CONSTANT OP_RD              : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
  CONSTANT OP_WR              : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "10";
  SIGNAL   RAM_op             : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
  
  SIGNAL RdPtr        : STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL WordsAvail   : STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  
  SIGNAL LOC_FileMode : STD_LOGIC := '0';
  
  SIGNAL bit_num      : INTEGER RANGE 0 TO ( AV_DATA_WIDTH - 1 ) := 0;
  SIGNAL op           : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL RamMaskBusy  : STD_LOGIC := '0';
  
  SIGNAL address : INTEGER RANGE 0 TO ( ( 2 ** AVCFG_ADDR_WIDTH ) - 1 )  := 0;  -- Signal_Registers number
  SIGNAL data    : STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
  
BEGIN
  
  a429phy: a429_RxPhy 
  GENERIC MAP(
    DataWidth    => AR429_DATA_WIDTH,  
    StopWidth    => 4,                  
    Pack_WN      => 8, 
    UsedWidth    => 3 
  )
  PORT MAP(
    Enable      => PHY_Enable_IN,    
    ClockIn     => PHY_ClockIn_IN,   
    ClockMux    => PHY_ClockMux_IN,  
    InputA      => PHY_InputA_IN,    
    InputB      => PHY_InputB_IN,    
    TxCntrl     => PHY_TxCntrl_IN,   
    InReg       => PHY_InReg_IN,     
    RxInvert    => PHY_RxInvert_IN,  
    RdClk       => Avalon_Clock, 
    RdReq       => PHY_RdEn_IN, 
    ParOFF      => PHY_ParOFF_IN,
    nEmpty      => PHY_nEmpty_OUT, 
    DataOut     => PHY_DataOut_OUT,  
    ------ not buf---------------------
    ParErr      => PHY_ParErr_OUT,   
    TxErr       => PHY_TxErr_OUT,    
    RxFlag      => PHY_RxFlag_OUT    
  );
  
  
  
  a429rxctrl: A429_RxControl 
  PORT MAP(
    EnableRx   => CTRL_EnableRx_IN,    
    Clk        => Avalon_Clock,         
    nEmpty     => CTRL_nEmpty_IN,        
    RdEn       => CTRL_RdEn_OUT,
    RxData     => CTRL_RxData_IN,      
    ParErr     => CTRL_ParErr_IN,      
    TxErr      => CTRL_TxErr_IN,       
    Mask       => CTRL_Mask_IN,    
    MaskRdEn   => CTRL_MaskRdEn,
    AddrMask   => CTRL_AddrMask_OUT,
    RdMode     => CTRL_RdMode_IN,      
    RxFlag     => CTRL_RxFlag_IN,      
    TestEn     => CTRL_TestEn_IN,
    RxSubAddr  => CTRL_RxSubAddr_OUT,     
    RAMBusy    => CTRL_RAMBusy_IN,    
    AddrRol    => CTRL_AddrRol_IN,
    WrEn       => CTRL_WrEn_OUT,       
    DataOut    => CTRL_DataOut_OUT,    
    ByteEn     => CTRL_ByteEn_OUT,     
    RAMAddr    => CTRL_RAMAddr_OUT,    
    RxStateReg => CTRL_RxStateReg_OUT
      
  );
  
  avm_master: AVMM_Master
  GENERIC MAP(
    CLOCK_FREQUENCE       =>  62500000,
    AVM_WRITE_ACKNOWLEDGE =>  16, --15,
    AVM_READ_ACKNOWLEDGE  =>  16, --15,
    AVM_DATA_WIDTH        =>  AR429_DATA_WIDTH,
    AVM_ADDR_WIDTH        =>  AR429_ADDR_WIDTH 
    
  )
  
  PORT MAP(
    nReset            =>  AVM_nReset_IN,
    Clock             =>  AVM_Clock_IN,
    WrEn              =>  AVM_WrEn_IN,
    RdEn              =>  AVM_RdEn_IN,
    AddrIn            =>  AVM_AddrIn_IN,
    WrDataIn          =>  AVM_WrDataIn_IN,
    ByteEnCode        =>  AVM_ByteEnCode_IN,
    Ready             =>  AVM_Ready_OUT,
    RdDataOut         =>  AVM_RdDataOut_OUT,

    avm_waitrequest   =>  AV2RAM_waitrequest,
    avm_readdata      =>  AV2RAM_readdata,
    avm_readdatavalid =>  AV2RAM_readdatavalid,
    avm_address       =>  AV2RAM_address_LOC,
    avm_byteenable    =>  AV2RAM_byteenable,
    avm_read          =>  AV2RAM_read,
    avm_write         =>  AV2RAM_write_LOC,
    avm_writedata     =>  AV2RAM_writedata
  );
  
  
  
  
  --av_mux: AvMM2Mux1
  --GENERIC MAP(
    --DataWidth =>  AR429_DATA_WIDTH,
    --AddrWidth =>  AR429_ADDR_WIDTH
  --)
  --PORT MAP(
    --Avalon_Clock       =>  Avalon_Clock,
    --Avalon_nReset      =>  Avalon_nReset,
    ------------------ Avalon-MM IN1 -----------------
    --AVI1_waitrequest   =>  AVM_avm_waitrequest_IN,  
    --AVI1_address       =>  AVM_avm_address_OUT,
    --AVI1_byteenable    =>  AVM_avm_byteenable_OUT,
    --AVI1_read          =>  AVM_avm_read_OUT,
    --AVI1_readdata      =>  AVM_avm_readdata_IN,
    --AVI1_readdatavalid =>  AVM_avm_readdatavalid_IN,       
    --AVI1_write         =>  AVM_avm_write_OUT,       
    --AVI1_writedata     =>  AVM_avm_writedata_OUT,   
  
    ----------------- Avalon-MM IN2 ----------------
    --AVI2_waitrequest   =>  AV2PCIE_waitrequest,
    --AVI2_address       =>  AV2PCIE_address,
    --AVI2_byteenable    =>  AV2PCIE_byteenable,
    --AVI2_read          =>  AV2PCIE_read,
    --AVI2_readdata      =>  AV2PCIE_readdata,
    --AVI2_readdatavalid =>  AV2PCIE_readdatavalid,
    --AVI2_write         =>  AV2PCIE_write,
    --AVI2_writedata     =>  AV2PCIE_writedata,
    
    ----------------- Avalon-MM OUT -----------------
    --AVMO_waitrequest   =>  AV2RAM_waitrequest,
    --AVMO_address       =>  AV2RAM_address_LOC,
    --AVMO_byteenable    =>  AV2RAM_byteenable,
    --AVMO_read          =>  AV2RAM_read_LOC,
    --AVMO_readdata      =>  AV2RAM_readdata,
    --AVMO_readdatavalid =>  AV2RAM_readdatavalid,
    --AVMO_write         =>  AV2RAM_write_LOC,
    --AVMO_writedata     =>  AV2RAM_writedata
  
    
  --);            
            
  
  mask_ram: RAM 
  GENERIC MAP(
    DataWidth =>  AV_DATA_WIDTH,
    AddrWidth =>  MASK_ADDR_WIDTH
  )
  PORT MAP(
    address => RAM_address, 
    clock   => RAM_clock,   
    data    => RAM_data,    
    rden    => RAM_rden,    
    wren    => RAM_wren,    
    q       => RAM_q       
  );            



  PtrGen: RingBuffPtr
  GENERIC MAP(
    ADDR_WIDTH => AR429_ADDR_WIDTH,
    START_ADDR => TO_INTEGER( RXFIFO_OFFSET ),
    BUFF_LEN   => TO_INTEGER( RXFIFO_SIZE  )

  )
  PORT MAP(
    Enable     => ( LOC_FileMode AND LOC_Enable ),  --( NOT LOC_RdMode ), -- Avalon_nReset AND 
    Clk        => Avalon_Clock,
    WrEn       => wr_pulse,
    RdEn       => rd_pulse,
    RdPtr      => RdPtr,
    WordsAvail => WordsAvail
    
  );

  
  
               
  
  
  AV2RAM_address <= AV2RAM_address_LOC;
  AV2RAM_write   <= AV2RAM_write_LOC; 
  
                
  ------------ Reset system ----------------------
  PHY_Enable_IN    <= LOC_Enable;
  CTRL_EnableRx_IN <= LOC_Enable;
  AVM_nReset_IN    <= Avalon_nReset;
  
  ------------- Clock system ---------------------
  PHY_ClockIn_IN <= A429_Clock;
  AVM_Clock_IN   <= Avalon_Clock;
  RAM_clock      <= Avalon_Clock;
  
  ------------- A429 PHY Connections -------------
  
  PHY_ClockMux_IN <= LOC_ClkMUX;
  PHY_InputA_IN   <= A429_LineA;
  PHY_InputB_IN   <= A429_LineB;
  PHY_TxCntrl_IN  <= '0';             -- NOT USED
  PHY_InReg_IN    <= SentWordIn;          
  PHY_RxInvert_IN <= '0';             -- receive not inverted bits
  LineBusy        <= PHY_RxFlag_OUT;
  PHY_ParOFF_IN   <= Signal_Registers( RXCONFIG_REG_ADDR )( PARITY_OFF );
  
  --------------- A429 Control connections ---------------
  PHY_RdEn_IN      <= CTRL_RdEn_OUT;
  CTRL_nEmpty_IN   <= PHY_nEmpty_OUT;
  CTRL_RxData_IN   <= PHY_DataOut_OUT;
  CTRL_ParErr_IN   <= PHY_ParErr_OUT;
  CTRL_TxErr_IN    <= PHY_TxErr_OUT;
  ---------------------------------
  CTRL_Mask_IN     <= RAM_q;
  ---------------------------------
  CTRL_RdMode_IN    <= LOC_RdMode;
  CTRL_RxFlag_IN    <= PHY_RxFlag_OUT;
  CTRL_TestEn_IN    <= '0'; 
  CTRL_AVM_Write_IN <= AV2RAM_write_LOC;  -- AVM_avm_write_OUT;
  CTRL_RAMRdAddr_IN <= AV2PCIE_address;
  
  --==========
--  CTRL_RAMBusy_IN   <= ( AV2RAM2_readdatavalid OR ( AV2PCIE_read OR AV2PCIE_write ) );
  CTRL_RAMBusy_IN   <= Signal_Registers( RXCONFIG_REG_ADDR )( CPU_BUFF_BUSY );
  --=========
  
  CTRL_AddrRol_IN   <= Signal_Registers( RXCONFIG_REG_ADDR )( ADDR_NROL );
  
  ---------------- Avalon-M master Connections ------------
  AVM_WrEn_IN       <= CTRL_WrEn_OUT;   
  AVM_RdEn_IN       <= '0';
  AVM_AddrIn_IN     <= CTRL_RAMAddr_OUT;
  AVM_WrDataIn_IN   <= CTRL_DataOut_OUT;
  AVM_ByteEnCode_IN <= CTRL_ByteEn_OUT;
  
  
  ----------- Config Register Parsing --------------------
  LOC_Enable <= Avalon_nReset AND ( Signal_Registers( RXCONFIG_REG_ADDR )( CLK_MUX_L )  OR 
               Signal_Registers( RXCONFIG_REG_ADDR )( CLK_MUX_H ) );
  
  
  ------------ FOR SINTHESYS -----------------------------
  LOC_RdMode   <= Signal_Registers( RXCONFIG_REG_ADDR )( RD_MODE ); -- FOR SYNTHESIS
  --------------------------------------------------------
  ------------- FOR DEBUG ONLY --------------
  --LOC_RdMode   <= '0';
  ------------------------------------------
  
  LOC_FileMode <= NOT LOC_RdMode;
  
  LOC_ClkMUX   <= Signal_Registers( RXCONFIG_REG_ADDR )( CLK_MUX_H  DOWNTO CLK_MUX_L ); -- FOR SYNTHESIS
  
  TEST_ENABLE  <= Signal_Registers( RXCONFIG_REG_ADDR )( TEST_EN );  -- Test enable bit
  RxTestEn     <= TEST_ENABLE;
  TESTA_INP    <= Signal_Registers( RXCONFIG_REG_ADDR )( TESTA_IN );
  TESTB_INP    <= Signal_Registers( RXCONFIG_REG_ADDR )( TESTB_IN );
  
  
  
  ------------ PCIE 2 RAM Avalon-MM ----------------------
  AV2PCIE_waitrequest   <= AV2RAM2_waitrequest; 
  AV2PCIE_readdata      <= AV2RAM2_readdata;      
  AV2PCIE_readdatavalid <= AV2RAM2_readdatavalid; 

  AV2RAM2_address_LOC   <= AV2PCIE_address; 
  AV2RAM2_byteenable    <= AV2PCIE_byteenable;
  AV2RAM2_read_LOC      <= AV2PCIE_read;
  AV2RAM2_write         <= AV2PCIE_write;     
  AV2RAM2_writedata     <= AV2PCIE_writedata; 
  AV2RAM2_address       <= AV2PCIE_address; --AV2RAM2_address_LOC;
  AV2RAM2_read          <= AV2PCIE_read; --AV2RAM2_read_LOC;
  
  
  
  Tester: PROCESS( Avalon_Clock )
  BEGIN
    IF RISING_EDGE( Avalon_Clock ) THEN
      IF TEST_ENABLE = '1' THEN
        A429_TestA <= TESTA_INP;
        A429_TestB <= TESTB_INP;
      ELSE
        A429_TestA <= '0';
        A429_TestB <= '0';
      END IF;
    END IF;
  END PROCESS;
  
  
  
  wr_pulse_gen: PROCESS( Avalon_nReset, Avalon_Clock )
  BEGIN
    IF Avalon_nReset = '0' THEN
      wr1 <= '0';
      wr2 <= '0';
      
    ELSIF FALLING_EDGE( Avalon_Clock ) THEN
      wr1 <= ( AV2RAM_write_LOC AND NOT( AV2RAM_waitrequest ) );
      wr2 <= wr1;
    END IF;
  END PROCESS;
  
  rd_pulse_gen: PROCESS( Avalon_nReset, Avalon_Clock )
  BEGIN
    IF Avalon_nReset = '0' THEN
      rd1 <= '0';
      rd2 <= '0';
    ELSIF FALLING_EDGE( Avalon_Clock ) THEN
      rd1 <= AV2RAM2_readdatavalid;
      rd2 <= rd1;
    END IF;
  END PROCESS;
  
  wr_pulse  <= wr1 AND ( NOT wr2 );
  rd_pulse  <= rd1 AND ( NOT rd2 );
  RAM_op    <= wr_pulse & rd_pulse;
  
  
  
  -- Settings registers ( Avalon-MM Slave )
  PROCESS( Avalon_nReset, Avalon_Clock )
    VARIABLE RAM_MASK_DATA_DELAY : INTEGER RANGE 0 TO 4 := 0;
  BEGIN
    
    IF( Avalon_nReset = '0' ) THEN
      
      AVS_waitrequest   <= '1';
      AVS_readdatavalid <= '0';
      AVS_readdata      <= ( OTHERS => '0' );
      LOC_IntFlagReg    <= ( OTHERS => '0' );
      RAM_rden          <= '0';
      RAM_wren          <= '0';
      address           <= 0;
      data              <= ( OTHERS => '0' );
      Signal_Registers  <= (  x"FFFFFFFF", x"00000000", x"FFFFFFFF", x"00000007" );
      Signal_SlaveState <= AVALON_RESET;
      
    ELSIF RISING_EDGE( Avalon_Clock ) THEN
      
      LOC_StateReg_DIF(  7 DOWNTO 0 )  <= LOC_StateReg_PREV( 7 DOWNTO 0 ) XOR CTRL_RxStateReg_OUT;
      LOC_StateReg_DIF( 31 DOWNTO 8 )  <= ( OTHERS => '0' );
      
      LOC_StateReg_PREV (  7 DOWNTO 0 ) <= CTRL_RxStateReg_OUT;
      LOC_StateReg_PREV ( 31 DOWNTO 8 ) <= ( OTHERS => '0' );
      
      IF ( ( LOC_StateReg_DIF AND LOC_StateReg_PREV ) AND Signal_Registers( RXINTMASK_REG_ADDR ) ) /= x"00000000" THEN
        Interrupt <= '1';
      ELSE
        Interrupt <= '0';
      END IF;
      
      IF LOC_StateReg_DIF /= x"00000000" THEN  -- accumulate LOC_IntFlagReg 
        LOC_IntFlagReg( RX_ERROR )   <= LOC_IntFlagReg( RX_ERROR ) OR CTRL_RxStateReg_OUT( 2 ); -- RxError interrupt
        LOC_IntFlagReg( RX_ALMFULL ) <= LOC_IntFlagReg( RX_ALMFULL ) OR CTRL_RxStateReg_OUT( 4 ); -- FIFO almoust full
        LOC_IntFlagReg( RX_FULL )    <= LOC_IntFlagReg( RX_FULL ) OR CTRL_RxStateReg_OUT( 6 ); -- FIFO Full 
        LOC_IntFlagReg( RX_OK )      <= LOC_IntFlagReg( RX_OK ) OR CTRL_RxStateReg_OUT( 5 ); -- Rx Ok
      -- clear flag bits in register when readed    
      -- Received words number not cleared in this case
      ELSIF LOC_IntRegRead = '1' THEN  
        LOC_IntFlagReg( CLRBIT_H DOWNTO CLRBIT_L ) <= ( OTHERS => '0' );
      END IF;
      
      ----------- FIFO Data Available length in ARINC429 words ----------------
      IF LOC_FileMode = '1' THEN
        LOC_IntFlagReg( RXWRD_AVAIL_H DOWNTO RXWRD_AVAIL_L ) <= WordsAvail( ( RXWRD_AVAIL_H - RXWRD_AVAIL_L ) DOWNTO 0 );
      ELSE
        LOC_IntFlagReg( ( RXWRD_AVAIL_L + CTRL_RxSubAddr_OUT'LEFT ) DOWNTO RXWRD_AVAIL_L ) <= CTRL_RxSubAddr_OUT; 
        LOC_IntFlagReg( RXWRD_AVAIL_H DOWNTO ( RXWRD_AVAIL_L + CTRL_RxSubAddr_OUT'LEFT + 1 ) ) <= ( OTHERS => '0' ); 
      END IF;
      
      ----------- Read Pointer for CPU ---------------------------------------
      LOC_IntFlagReg( RD_PTR_H DOWNTO RD_PTR_L ) <= STD_LOGIC_VECTOR( UNSIGNED( RdPtr ) - RXFIFO_OFFSET )(( RD_PTR_H - RD_PTR_L ) DOWNTO 0 );
            
      ----------- INPUT TEST SIGNALS ------------------------------------------
      IF TEST_ENABLE = '1' THEN
        LOC_IntFlagReg( INA_TEST ) <= A429_LineA; -- INPA_TEST 
        LOC_IntFlagReg( INB_TEST ) <= A429_LineB; -- INPB_TEST
      ELSE
        LOC_IntFlagReg( INA_TEST ) <= '0';
        LOC_IntFlagReg( INB_TEST ) <= '0';
      END IF;
      
      --------------RAM buffer Busy flag  ---------------------------------
      IF AVM_WrEn_IN = '1' THEN
        LOC_IntFlagReg( RXFPGA_BUFF_BUSY ) <= '1'; --AV2RAM_write_LOC OR wr_pulse OR AVM_WrEn_IN; -- OR RamMaskBusy OR CTRL_MaskRdEn;  --receiver only writes data into RAM_BUFF
      ELSIF wr2 = '1' THEN
        LOC_IntFlagReg( RXFPGA_BUFF_BUSY ) <= '0';
      END IF;
      
      Signal_Registers( RXINTFLAG_REG_ADDR ) <= LOC_IntFlagReg;
      
      CASE Signal_SlaveState IS
      
      WHEN AVALON_IDLE =>
        IF( AVS_write = '1' ) THEN
          address           <= TO_INTEGER( UNSIGNED( AVS_address ) );
          data              <= AVS_writedata;
          AVS_waitrequest   <= '0';
          AVS_readdatavalid <= '0';
          Signal_SlaveState <= AVALON_WRITE;
        ELSIF( AVS_read = '1' ) THEN
          address           <= TO_INTEGER( UNSIGNED( AVS_address ) );
          AVS_waitrequest   <= '0';
          AVS_readdatavalid <= '0';
          Signal_SlaveState <= AVALON_READ;
        ELSIF( ( ( RAM_op = OP_RD ) OR ( RAM_op = OP_WR ) ) AND ( LOC_RdMode = RX_ADDR_MODE ) ) THEN
          IF( RAM_op = OP_WR ) THEN
            address     <= 8 + ( TO_INTEGER( UNSIGNED( AV2RAM_address_LOC( AV2RAM_address_LOC'LEFT DOWNTO 5 ) ) ) );
            bit_num     <= TO_INTEGER( UNSIGNED( AV2RAM_address_LOC( 4 DOWNTO 0 ) ) ); 
            RAM_address <= STD_LOGIC_VECTOR( TO_UNSIGNED( ( 8 + ( TO_INTEGER( UNSIGNED( AV2RAM_address_LOC( AV2RAM_address_LOC'LEFT DOWNTO 5 ) ) ) ) ), RAM_address'LENGTH ) );
          ELSIF( RAM_op = OP_RD ) THEN
            address     <= 8 + ( TO_INTEGER( UNSIGNED( AV2RAM2_address_LOC( AV2RAM2_address_LOC'LEFT DOWNTO 5 ) ) ) );
            bit_num     <= TO_INTEGER( UNSIGNED( AV2RAM2_address_LOC( 4 DOWNTO 0 ) ) ); 
            RAM_address <= STD_LOGIC_VECTOR( TO_UNSIGNED( ( 8 + ( TO_INTEGER( UNSIGNED( AV2RAM2_address_LOC( AV2RAM2_address_LOC'LEFT DOWNTO 5 ) ) ) ) ) , RAM_address'LENGTH ) );
          END IF;
          op                  <= RAM_op;
          RAM_rden            <= '1';
          Signal_SlaveState   <= RAM_RD;
          AVS_waitrequest     <= '1';
          RAM_MASK_DATA_DELAY := 0;
        ELSE
          RAM_wren          <= '0';
          RAM_rden          <= CTRL_MaskRdEn;
          RAM_address       <= CTRL_AddrMask_OUT;
          AVS_waitrequest   <= '1';
        END IF;
        LOC_IntRegRead    <= '0';
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
      
      WHEN AVALON_WRITE =>
        IF( address < RXADDRMASK_START_ADDR ) THEN
          Signal_Registers( address ) <= data;
        ELSIF( address <= RXADDRMASK_END_ADDR ) THEN
          RAM_address <= STD_LOGIC_VECTOR( TO_UNSIGNED( ( address - RXADDRMASK_START_ADDR ), MASK_ADDR_WIDTH ) );
          RAM_data    <= data;
          RAM_wren    <= '1';
        END IF;
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
        Signal_SlaveState <= AVALON_IDLE;
      
      WHEN AVALON_READ =>
        IF( ( address >= RXADDRMASK_START_ADDR ) AND ( address <= NEWDATAREG_END_ADDR ) ) THEN
          RAM_address <= STD_LOGIC_VECTOR( TO_UNSIGNED( ( address - RXADDRMASK_START_ADDR ), MASK_ADDR_WIDTH ) );
          RAM_rden    <= '1';
        ELSE
          RAM_rden <= '0';
        END IF;
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
        Signal_SlaveState <= AVALON_ACK_READ;
      
      WHEN AVALON_ACK_READ =>
        IF( address < RXADDRMASK_START_ADDR ) THEN
          IF( address = RXINTFLAG_REG_ADDR ) THEN
            LOC_IntRegRead <= '1';
          END IF;
          AVS_readdata <= Signal_Registers( address );
        ELSIF( address <= NEWDATAREG_END_ADDR ) THEN
          RAM_rden     <= '0';
          AVS_readdata <= RAM_q;
          Signal_SlaveState <= AVALON_IDLE;
        END IF;
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '1';
        Signal_SlaveState <= AVALON_IDLE;
      
      WHEN RAM_RD =>
        IF RAM_MASK_DATA_DELAY < 2 THEN
          RAM_MASK_DATA_DELAY := RAM_MASK_DATA_DELAY + 1;
        ELSE
          Signal_SlaveState <= RAM_WR;
        END IF;
        RAM_rden <= '0';
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
      
      WHEN RAM_WR =>
        IF( op = OP_WR ) THEN
          RAM_data <= RAM_q OR STD_LOGIC_VECTOR( ( TO_UNSIGNED( 1, RAM_data'LENGTH ) SLL bit_num ) );
        ELSIF( op = OP_RD ) THEN
          RAM_data <= RAM_q AND ( NOT ( STD_LOGIC_VECTOR( ( TO_UNSIGNED( 1, RAM_data'LENGTH ) SLL bit_num ) ) ) );
        END IF;
        RAM_wren          <= '1';
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
        Signal_SlaveState <= AVALON_IDLE;
      
      WHEN OTHERS =>
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
        Signal_SlaveState <= AVALON_IDLE;
      
      END CASE;
      
    END IF;
    
  END PROCESS;
  
  
  
END logic;
