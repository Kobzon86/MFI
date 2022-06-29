LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.A708_pkg.ALL;

ENTITY A708_Transceiver IS
  
  PORT(
    
    Avalon_nReset         : IN  STD_LOGIC := '0';
    Avalon_Clock          : IN  STD_LOGIC;
    A708_Clock            : IN  STD_LOGIC;
    
    AVS_waitrequest       : OUT STD_LOGIC;
    AVS_address           : IN  STD_LOGIC_VECTOR(  1 DOWNTO 0 );
    AVS_byteenable        : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    AVS_read              : IN  STD_LOGIC;
    AVS_readdata          : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    AVS_readdatavalid     : OUT STD_LOGIC;
    AVS_write             : IN  STD_LOGIC;
    AVS_writedata         : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    
    ----------- for PCIE Slave Avalon-MM port -----------------
    AV2PCIE_waitrequest   : OUT STD_LOGIC;
    AV2PCIE_address       : IN  STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
    AV2PCIE_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    AV2PCIE_read          : IN  STD_LOGIC;
    AV2PCIE_readdata      : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV2PCIE_readdatavalid : OUT STD_LOGIC;
    AV2PCIE_write         : IN  STD_LOGIC;
    AV2PCIE_writedata     : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    
    -------------- for RAM Master Avalon-MM port ------------
    AV2RAM_waitrequest    : IN  STD_LOGIC;
    AV2RAM_address        : OUT STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
    AV2RAM_byteenable     : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    AV2RAM_read           : OUT STD_LOGIC;
    AV2RAM_readdata       : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV2RAM_readdatavalid  : IN  STD_LOGIC;
    AV2RAM_write          : OUT STD_LOGIC;
    AV2RAM_writedata      : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
        --------- Avalon-MM signals to RAM port2 PCIE to RAM --------------------
    AV2RAM2_waitrequest   : IN  STD_LOGIC;
    AV2RAM2_address       : OUT STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
    AV2RAM2_byteenable    : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    AV2RAM2_read          : OUT STD_LOGIC;
    AV2RAM2_readdata      : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV2RAM2_readdatavalid : IN  STD_LOGIC;
    AV2RAM2_write         : OUT STD_LOGIC;
    AV2RAM2_writedata     : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );

    inputA                : IN  STD_LOGIC;
    inputB                : IN  STD_LOGIC;
    RxEn                  : OUT STD_LOGIC;  -- Strobe
    OutputA               : OUT STD_LOGIC;
    OutputB               : OUT STD_LOGIC;
    TxInhibit             : OUT STD_LOGIC;
    LineTurnOFF           : OUT STD_LOGIC;
    Interrupt             : OUT STD_LOGIC;
  --========= FOR DEBUG ONLY WAS USED =========
    RxCompl               : OUT STD_LOGIC;  -- not used in project
    NewAvail              : IN STD_LOGIC    -- not used in project
  --==========================================
    
  );
  
END A708_Transceiver;

ARCHITECTURE logic OF A708_Transceiver IS
  
  COMPONENT AVMM_Master_FIFO IS
  GENERIC(
    CLOCK_FREQUENCE       : INTEGER := 62500000;
    AVM_WRITE_ACKNOWLEDGE : INTEGER := 15;
    AVM_READ_ACKNOWLEDGE  : INTEGER := 15;
    AVM_DATA_WIDTH        : INTEGER := 32;
    AVM_ADDR_WIDTH        : INTEGER := 16;
    FIFO_WORDS_NUM        : INTEGER := 32;
    FIFO_USED_WIDTH       : INTEGER := 5
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


  COMPONENT a708_receiver IS
  GENERIC(
    StartWidth   : INTEGER := 3;
    RxWordWidth  : INTEGER := 16;
    RxWordsNum   : INTEGER := 100;
    StopWidth    : INTEGER := 3
  );
  PORT(
    Enable      : IN  STD_LOGIC;
    ClockIn     : IN  STD_LOGIC;   -- 16MHz
    InputA      : IN  STD_LOGIC;
    InputB      : IN  STD_LOGIC;
    ReadEn      : IN  STD_LOGIC;
    ReadClk     : IN  STD_LOGIC;  -- Avalon_Clk
    Transmit    : IN  STD_LOGIC;
    TxRegIn     : IN  STD_LOGIC_VECTOR( ( RxWordWidth - 1 ) DOWNTO 0 );
    TxBusy      : IN  STD_LOGIC;
    Strobe      : OUT STD_LOGIC;
    Empty       : OUT STD_LOGIC;
    Ready       : OUT STD_LOGIC;
    DataOut     : OUT STD_LOGIC_VECTOR( ( RxWordWidth - 1 ) DOWNTO 0 );
    Rx_Flag     : OUT STD_LOGIC;
    Error       : OUT STD_LOGIC
  );
  END COMPONENT;
  
  COMPONENT a708_transmitter IS
  GENERIC(
    StartWidth : INTEGER := 3;
    DataWidth  : INTEGER := 16;
    TxWordsNum : INTEGER := 100; 
    TimeGap    : INTEGER := 5; -- time between packets in us
    StopWidth  : INTEGER := 3
  );
  PORT(
    Enable     : IN  STD_LOGIC;
    ClockIn    : IN  STD_LOGIC;         -- 16 MHz
    WriteEn    : IN  STD_LOGIC := '0';
    WriteClk   : IN  STD_LOGIC;    -- Avalon_Clk
    Data       : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
    OutputA    : OUT STD_LOGIC;
    OutputB    : OUT STD_LOGIC;
    Sleep      : OUT STD_LOGIC;
    TxInhibit  : OUT STD_LOGIC := '1'; 
    FIFO_Empty : OUT STD_LOGIC := '0';
    FIFO_Full  : OUT STD_LOGIC := '0';
    Busy       : OUT STD_LOGIC;
    Transmit   : OUT STD_LOGIC;
    TxRegOut   : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 )
  );
  END COMPONENT;
  
  COMPONENT A708_Control IS
  PORT(
    Enable     : IN  STD_LOGIC;
    Clk        : IN  STD_LOGIC; 
    
    RxReady    : IN  STD_LOGIC;
    RxError    : IN  STD_LOGIC;
    RxData     : IN  STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
    RxBusy     : IN  STD_LOGIC;
    RxEmpty    : IN  STD_LOGIC;
    RxRdReq    : OUT STD_LOGIC;
    RxOk       : OUT STD_LOGIC;
    
    TxBusy     : IN  STD_LOGIC;
    TxFull     : IN  STD_LOGIC;
    TxEmpty    : IN  STD_LOGIC;
    TxWrReq    : OUT STD_LOGIC;
    TxData     : OUT STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
    
    CPUBuffBusy : IN STD_LOGIC;
    RamNDAvail : IN  STD_LOGIC;
    Tx_Compl   : OUT STD_LOGIC;
    AV_Load    : IN  STD_LOGIC;
    AV_WordIn  : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV_RdEn    : OUT STD_LOGIC;
    AV_WrEn    : OUT STD_LOGIC;
    AV_RAMAddr : OUT STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
    AV_DataOut : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV_ByteEn  : OUT STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 )
    
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
  
  --======================== DATA TYPES ==================================
  TYPE   T_Avalon_State     IS ( AVALON_RESET, AVALON_IDLE, AVALON_WRITE, AVALON_READ );
  TYPE   T_Conf_Registers   IS ARRAY( 3 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  
  ATTRIBUTE enum_encoding : STRING;
  ATTRIBUTE enum_encoding OF T_Avalon_State : TYPE IS "safe,one-hot";
  
  --========================== SIGNALS =======================================
  SIGNAL Signal_SlaveState  : T_Avalon_State;
  
  SIGNAL Signal_Registers   : T_Conf_Registers;
  
--------------- Avalon-MM Master interface signals ------------------------
  SIGNAL AVMM_Clock        : STD_LOGIC;
  SIGNAL AVMM_nReset       : STD_LOGIC;
  SIGNAL AVMM_RdEn         : STD_LOGIC;
  SIGNAL AVMM_Ready        : STD_LOGIC;
  SIGNAL AVMM_RdDataOut    : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AVMM_WrEn         : STD_LOGIC;
  SIGNAL AVMM_AddrIn       : STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AVMM_WrDataIn     : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AVMM_ByteEnCode   : STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
  
  SIGNAL AVM_waitrequest   : STD_LOGIC;
  SIGNAL AVM_address       : STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AVM_byteenable    : STD_LOGIC_VECTOR(  3 DOWNTO 0 );
  SIGNAL AVM_read          : STD_LOGIC;
  SIGNAL AVM_readdata      : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AVM_readdatavalid : STD_LOGIC;
  SIGNAL AVM_write         : STD_LOGIC;
  SIGNAL AVM_writedata     : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );

----------------------- ARINC708 Receiver Signals ----------------------
  SIGNAL RXPHY_Enable_IN    : STD_LOGIC;
  SIGNAL RXPHY_ClockIn_IN   : STD_LOGIC; -- 16MHz
  SIGNAL RXPHY_InputA_IN    : STD_LOGIC;
  SIGNAL RXPHY_InputB_IN    : STD_LOGIC;
  SIGNAL RXPHY_ReadEn_IN    : STD_LOGIC;
  SIGNAL RXPHY_ReadClk_IN   : STD_LOGIC; -- Avalon_Clk
  SIGNAL RXPHY_Transmit_IN  : STD_LOGIC;
  SIGNAL RXPHY_TxRegIn_IN   : STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL RXPHY_TxBusy_IN    : STD_LOGIC;
  SIGNAL RXPHY_Strobe_OUT   : STD_LOGIC;
  SIGNAL RXPHY_Empty_OUT    : STD_LOGIC;
  SIGNAL RXPHY_Ready_OUT    : STD_LOGIC;
  SIGNAL RXPHY_DataOut_OUT  : STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL RXPHY_Rx_Flag_OUT  : STD_LOGIC;
  SIGNAL RXPHY_Error_OUT    : STD_LOGIC;
  SIGNAL CTRL_RxOk_OUT      : STD_LOGIC;
  
---------------------- ARINC708 Transmitter Signals -------------------
  SIGNAL TXPHY_Enable_IN      :  STD_LOGIC;
  SIGNAL TXPHY_ClockIn_IN     :  STD_LOGIC; -- 16 MHz
  SIGNAL TXPHY_WriteEn_IN     :  STD_LOGIC;
  SIGNAL TXPHY_WriteClk_IN    :  STD_LOGIC; -- Avalon_Clk
  SIGNAL TXPHY_Data_IN        :  STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL TXPHY_OutputA_OUT    :  STD_LOGIC;
  SIGNAL TXPHY_OutputB_OUT    :  STD_LOGIC;
  SIGNAL TXPHY_Sleep_OUT      :  STD_LOGIC;
  SIGNAL TXPHY_TxInhibit_OUT  :  STD_LOGIC ;
  SIGNAL TXPHY_FIFO_Empty_OUT :  STD_LOGIC;
  SIGNAL TXPHY_FIFO_Full_OUT  :  STD_LOGIC;
  SIGNAL TXPHY_Busy_OUT       :  STD_LOGIC;
  SIGNAL TXPHY_Transmit_OUT   :  STD_LOGIC;
  SIGNAL TXPHY_TxRegOut_OUT   :  STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
  
--------------------- A708_Control Signals ----------------------------
  SIGNAL CTRL_Enable_IN      :  STD_LOGIC;
  SIGNAL CTRL_Clk_IN         :  STD_LOGIC; 
  
  SIGNAL CTRL_RxReady_IN     :  STD_LOGIC;
  SIGNAL CTRL_RxError_IN     :  STD_LOGIC;
  SIGNAL CTRL_RxData_IN      :  STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_RxBusy_IN      :  STD_LOGIC;
  SIGNAL CTRL_RxEmpty_IN     :  STD_LOGIC;
  SIGNAL CTRL_RxRdReq_OUT    :  STD_LOGIC;
  
  SIGNAL CTRL_TxBusy_IN      :  STD_LOGIC;
  SIGNAL CTRL_TxFull_IN      :  STD_LOGIC;
  SIGNAL CTRL_TxEmpty_IN     :  STD_LOGIC;
  SIGNAL CTRL_TxWrReq_OUT    :  STD_LOGIC;
  SIGNAL CTRL_TxData_OUT     :  STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
  
  SIGNAL CTRL_CPUBuffBusy_IN   : STD_LOGIC;
  SIGNAL CTRL_RamNDAvail_IN    : STD_LOGIC;
  SIGNAL CTRL_FPGABuffBusy_OUT : STD_LOGIC;
  SIGNAL CTRL_Tx_Compl_OUT     : STD_LOGIC;
  SIGNAL CTRL_AV_Load_IN       : STD_LOGIC;
  SIGNAL CTRL_AV_WordIn_IN     : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_AV_RdEn_OUT      : STD_LOGIC;
  SIGNAL CTRL_AV_WrEn_OUT      : STD_LOGIC;
  SIGNAL CTRL_AV_RAMAddr_OUT   : STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_AV_DataOut_OUT   : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL CTRL_AV_ByteEn_OUT    : STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
  
------------------- Avalon-MM MUX Interface SIGNALS --------------------
  SIGNAL AVMUX_Avalon_Clock_IN  : STD_LOGIC;
  SIGNAL AVMUX_Avalon_nReset_IN : STD_LOGIC;
  
------------------- transmitter local signals ------------------------------  
  SIGNAL IntReaded         : STD_LOGIC;
  SIGNAL StateReaded       : STD_LOGIC;
  SIGNAL StateREG          : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  SIGNAL IntFlagREG        : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  SIGNAL IntFlagRegPREV    : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  SIGNAL RxTxLine_Busy     : STD_LOGIC;
  SIGNAL TxBusy            : STD_LOGIC;
  SIGNAL TxComplete        : STD_LOGIC;
  SIGNAL RxOk              : STD_LOGIC;
  SIGNAL FPGA_BuffBusy     : STD_LOGIC;
  SIGNAL PhyLinesEnable    : STD_LOGIC;
  SIGNAL FPGA_BusyCnt      : INTEGER RANGE 0 TO 7;
  
----------- TimerEnabler Signals ---------------
  SIGNAL TIM_Arst_IN       : STD_LOGIC;
  SIGNAL TIM_Ready_OUT     : STD_LOGIC;
  SIGNAL RelayOn           : STD_LOGIC;
  
  SIGNAL RxPhyEn           : STD_LOGIC;
  SIGNAL TxPhyEn           : STD_LOGIC;
  SIGNAL PhyEnTimer        : STD_LOGIC;
  
---------- FOR DEBUG ONLY WAS USED -----------------
  SIGNAL DataWrited       : STD_LOGIC;
  SIGNAL DataWriting      : STD_LOGIC;
  SIGNAL DataWrCnt        : INTEGER RANGE 0 TO 7;
----------------------------------------------------
  
  SIGNAL WrEnPulse   : STD_LOGIC;
  SIGNAL RdEnPulse   : STD_LOGIC;
  SIGNAL RdPtr       : STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL WordsAvail  : STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
  
  SIGNAL address : INTEGER RANGE 3 DOWNTO 0;
  SIGNAL data    : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  
BEGIN
  
  A708_RxPhy: a708_receiver 
  GENERIC MAP(
    StartWidth   => 3,
    RxWordWidth  => PHY_DATA_WIDTH,
    RxWordsNum   => 100,
    StopWidth    => 3
  )
  PORT MAP(
    Enable      => RXPHY_Enable_IN,
    ClockIn     => RXPHY_ClockIn_IN,
    InputA      => RXPHY_InputA_IN,
    InputB      => RXPHY_InputB_IN,
    ReadEn      => RXPHY_ReadEn_IN,
    ReadClk     => RXPHY_ReadClk_IN,
    Transmit    => RXPHY_Transmit_IN,
    TxRegIn     => RXPHY_TxRegIn_IN,
    TxBusy      => RXPHY_TxBusy_IN,
    Strobe      => RXPHY_Strobe_OUT,
    Empty       => RXPHY_Empty_OUT,
    Ready       => RXPHY_Ready_OUT,
    DataOut     => RXPHY_DataOut_OUT,
    Rx_Flag     => RXPHY_Rx_Flag_OUT,
    Error       => RXPHY_Error_OUT
  );
  
  A708_TxPhy : a708_transmitter 
  GENERIC MAP(
    StartWidth => 3,
    DataWidth  => PHY_DATA_WIDTH,
    TxWordsNum => 100,
    TimeGap    => 5,
    StopWidth  => 3
  )
  PORT MAP(
    Enable     => TXPHY_Enable_IN,
    ClockIn    => TXPHY_ClockIn_IN,
    WriteEn    => TXPHY_WriteEn_IN,
    WriteClk   => TXPHY_WriteClk_IN,
    Data       => TXPHY_Data_IN,
    OutputA    => TXPHY_OutputA_OUT,
    OutputB    => TXPHY_OutputB_OUT,
    Sleep      => TXPHY_Sleep_OUT,
    TxInhibit  => TXPHY_TxInhibit_OUT,
    FIFO_Empty => TXPHY_FIFO_Empty_OUT,
    FIFO_Full  => TXPHY_FIFO_Full_OUT,
    Busy       => TXPHY_Busy_OUT,
    Transmit   => TXPHY_Transmit_OUT,
    TxRegOut   => TXPHY_TxRegOut_OUT
  );
  
  a708_ctrl : A708_Control
  PORT MAP(
    Enable     =>  CTRL_Enable_IN,
    Clk        =>  CTRL_Clk_IN,
    RxReady    =>  CTRL_RxReady_IN,
    RxError    =>  CTRL_RxError_IN,
    RxData     =>  CTRL_RxData_IN,
    RxBusy     =>  CTRL_RxBusy_IN,
    RxEmpty    =>  CTRL_RxEmpty_IN,
    RxRdReq    =>  CTRL_RxRdReq_OUT,
    RxOk       =>  CTRL_RxOk_OUT,
    TxBusy     =>  CTRL_TxBusy_IN,
    TxFull     =>  CTRL_TxFull_IN,
    TxEmpty    =>  CTRL_TxEmpty_IN,
    TxWrReq    =>  CTRL_TxWrReq_OUT,
    TxData     =>  CTRL_TxData_OUT,
    CPUBuffBusy => CTRL_CPUBuffBusy_IN,
    RamNDAvail =>  CTRL_RamNDAvail_IN,
    Tx_Compl   =>  CTRL_Tx_Compl_OUT,
    AV_Load    =>  CTRL_AV_Load_IN,
    AV_WordIn  =>  CTRL_AV_WordIn_IN,
    AV_RdEn    =>  CTRL_AV_RdEn_OUT,
    AV_WrEn    =>  CTRL_AV_WrEn_OUT,
    AV_RAMAddr =>  CTRL_AV_RAMAddr_OUT,
    AV_DataOut =>  CTRL_AV_DataOut_OUT,
    AV_ByteEn  =>  CTRL_AV_ByteEn_OUT
    
  );
  
  AvalonMaster : AVMM_Master_FIFO
  GENERIC MAP(
    CLOCK_FREQUENCE       =>  16000000,
    AVM_WRITE_ACKNOWLEDGE =>  16,
    AVM_READ_ACKNOWLEDGE  =>  16,
    AVM_DATA_WIDTH        =>  RAM_DATA_WIDTH,
    AVM_ADDR_WIDTH        =>  RAM_ADDR_WIDTH,
    FIFO_WORDS_NUM        =>  64,
    FIFO_USED_WIDTH       =>  6
  )
  PORT MAP(
    nReset            => AVMM_nReset,
    Clock             => AVMM_Clock,
    WrEn              => AVMM_WrEn,
    RdEn              => AVMM_RdEn,
    AddrIn            => AVMM_AddrIn,
    WrDataIn          => AVMM_WrDataIn,
    ByteEnCode        => AVMM_ByteEnCode,
    Ready             => AVMM_Ready,
    RdDataOut         => AVMM_RdDataOut,
    avm_waitrequest   => AVM_waitrequest,
    avm_readdata      => AVM_readdata,
    avm_readdatavalid => AVM_readdatavalid,
    avm_address       => AVM_address,
    avm_byteenable    => AVM_byteenable,
    avm_read          => AVM_read,
    avm_write         => AVM_write,
    avm_writedata     => AVM_writedata
  );
  
  PtrGen : RingBuffPtr
  GENERIC MAP(
    ADDR_WIDTH => RAM_ADDR_WIDTH,
    START_ADDR => TO_INTEGER( RXBUFF_START ),
    BUFF_LEN   => TO_INTEGER( RXBUFF_LEN )
  )
  PORT MAP(
    Enable     => Avalon_nReset,
    Clk        => Avalon_Clock,
    WrEn       => WrEnPulse,
    RdEn       => RdEnPulse,
    RdPtr      => RdPtr,
    WordsAvail => WordsAvail
  );
  
  WrEnGen : pgen
  GENERIC MAP(
    Edge   => '1' -- by RISING EDGE
  )
  PORT MAP(
    Enable => Avalon_nReset,
    Clk    => Avalon_Clock, 
    Input  => AVM_write, 
    Output => WrEnPulse 
  );
  
  RdEnGen : pgen
  GENERIC MAP(
    Edge   => '1' -- by RISING EDGE
  )
  PORT MAP(
    Enable => Avalon_nReset,
    Clk    => Avalon_Clock,
    Input  => AV2RAM2_readdatavalid,
    Output => RdEnPulse 
  );
  
  write_compl_pulse : pgen -- Data write complete pulse generation
  GENERIC MAP(
    Edge   => '0' -- by FALLING EDGE
  )
  PORT MAP(
    Enable => TXPHY_Enable_IN,
    Clk    => Avalon_Clock,
    Input  => DataWriting,
    Output => DataWrited
  );
  
  
  
  ---======= DEBUG ONLY ==============
  --TXPHY_Enable_IN        <= '1';
  --RXPHY_Enable_IN        <= '1';
  --=================================
  
  --========= SYNTHESIS =============
  
  TXPHY_Enable_IN        <= Signal_Registers( CONFIG_REG_ADDR )( TX_EN );  --TxPhyEn;
  RXPHY_Enable_IN        <= Signal_Registers( CONFIG_REG_ADDR )( RX_EN );  --RxPhyEn;
  --================================
  
  AVMM_nReset            <= Avalon_nReset;
  AVMUX_Avalon_nReset_IN <= Avalon_nReset;
  CTRL_Enable_IN         <= Avalon_nReset;
  
  -------------- Clock Signals -------------------------
  AVMM_Clock             <= Avalon_Clock;
  AVMUX_Avalon_Clock_IN  <= Avalon_Clock;
  TXPHY_ClockIn_IN       <= A708_Clock;
  TXPHY_WriteClk_IN      <= Avalon_Clock;
  RXPHY_ClockIn_IN       <= A708_Clock;
  RXPHY_ReadClk_IN       <= Avalon_Clock;
  CTRL_Clk_IN            <= Avalon_Clock;
  
  --------------- A708 Receiver Connections ---------------
  RXPHY_InputA_IN        <= InputA; -- WHEN PhyLinesEnable = '1' ELSE '0';
  RXPHY_InputB_IN        <= InputB; -- WHEN PhyLinesEnable = '1' ELSE '0';
  RXPHY_ReadEn_IN        <= CTRL_RxRdReq_OUT;
  RXPHY_Transmit_IN      <= TXPHY_Transmit_OUT;
  RXPHY_TxRegIn_IN       <= TXPHY_TxRegOut_OUT;
  RxEn                   <= RXPHY_Strobe_OUT;
  RXPHY_TxBusy_IN        <= TXPHY_Busy_OUT;
  RxTxLine_Busy          <= RXPHY_Rx_Flag_OUT;
  
  --------------- A708 Transmitter Connections -----------
  TXPHY_WriteEn_IN       <= CTRL_TxWrReq_OUT;
  TXPHY_Data_IN          <= CTRL_TxData_OUT;
  OutputA                <= TXPHY_OutputA_OUT; -- WHEN PhyLinesEnable = '1' ELSE '0';
  OutputB                <= TXPHY_OutputB_OUT; -- WHEN PhyLinesEnable = '1' ELSE '0';
  TxInhibit               <= TXPHY_TxInhibit_OUT;
  
  --------------- A708_Control Connections ---------------
  CTRL_RxReady_IN        <= RXPHY_Ready_OUT;
  CTRL_RxError_IN        <= RXPHY_Error_OUT;
  CTRL_RxData_IN         <= RXPHY_DataOut_OUT;
  CTRL_RxBusy_IN         <= RXPHY_Rx_Flag_OUT;
  CTRL_RxEmpty_IN        <= RXPHY_Empty_OUT;
  CTRL_TxBusy_IN         <= TXPHY_Busy_OUT;
  CTRL_TxFull_IN         <= TXPHY_FIFO_Full_OUT;
  CTRL_TxEmpty_IN        <= TXPHY_FIFO_Empty_OUT;
  CTRL_CPUBuffBusy_IN    <= Signal_Registers( CONFIG_REG_ADDR )( CPU_BUFF_BUSY );
  CTRL_RamNDAvail_IN     <= Signal_Registers( CONFIG_REG_ADDR )( NEW_DATA_AVAIL );
  CTRL_AV_Load_IN        <= AVMM_Ready;
  CTRL_AV_WordIn_IN      <= AVMM_RdDataOut;
  
  RxOk                   <= CTRL_RxOk_OUT;
  RxCompl                <= DataWrited;
  
  -------------- Avalon-MM Master connections -------------
  AVMM_AddrIn            <= CTRL_AV_RAMAddr_OUT;
  AVMM_ByteEnCode        <= CTRL_AV_ByteEn_OUT;
  AVMM_WrDataIn          <= CTRL_AV_DataOut_OUT;
  AVMM_RdEn              <= CTRL_AV_RdEn_OUT;
  AVMM_WrEn              <= CTRL_AV_WrEn_OUT;
  
  -------------- Avalon-MM AV2RAM Connection ------------------------
  AVM_waitrequest        <=  AV2RAM_waitrequest;
  AV2RAM_address         <=  AVM_address;
  AV2RAM_byteenable      <=  AVM_byteenable;
  AV2RAM_read            <=  AVM_read;
  AVM_readdata           <=  AV2RAM_readdata;
  AVM_readdatavalid      <=  AV2RAM_readdatavalid;
  AV2RAM_write           <=  AVM_write;
  AV2RAM_writedata       <=  AVM_writedata;
  
  --------------- Avalon-MM AV2PCIE - AV2RAM2 Connection -----------------
  AV2PCIE_waitrequest    <= AV2RAM2_waitrequest;
  AV2RAM2_address        <= AV2PCIE_address;
  AV2RAM2_byteenable     <= AV2PCIE_byteenable;
  AV2RAM2_read           <= AV2PCIE_read;
  AV2PCIE_readdata       <= AV2RAM2_readdata;
  AV2PCIE_readdatavalid  <= AV2RAM2_readdatavalid;
  AV2RAM2_write          <= AV2PCIE_write;
  AV2RAM2_writedata      <= AV2PCIE_writedata;
  
  
  
  LineSWOFF: PROCESS( Avalon_nReset, Avalon_Clock )
  BEGIN
    
    IF( Avalon_nReset = '0' ) THEN
      
      LineTurnOFF <= '1';
      
    ELSIF( RISING_EDGE( Avalon_Clock ) ) THEN
      
      IF( RxTxLine_Busy = '0' ) THEN
        LineTurnOFF <= Signal_Registers( CONFIG_REG_ADDR )( LINE_OFF );
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  AVMWriteGen: PROCESS( Avalon_nReset, Avalon_Clock )
  BEGIN
    
    IF( Avalon_nReset = '0' )THEN
      
      DataWrCnt   <= 0;
      DataWriting <= '0';
      
    ELSIF( RISING_EDGE( Avalon_Clock ) ) THEN
      
      IF( AVM_write = '1' ) THEN
        
        DataWrCnt   <= 0;
        DataWriting <= '1';
        
      ELSIF( DataWrCnt < 7 ) THEN
        
        DataWrCnt <= DataWrCnt + 1;
        
      ELSE
        
        DataWriting <= '0';
        
      END IF;
      
    END IF;
  END PROCESS;
  
  
  
  IntFlag_Reg: PROCESS( Avalon_nReset, Avalon_Clock )
    VARIABLE IntFlagRegDIF : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  BEGIN
    
    IF( Avalon_nReset = '0' ) THEN
      
      FPGA_BusyCnt   <= 0;
      IntFlagRegPREV <= ( OTHERS => '0' );
      IntFlagREG     <= ( OTHERS => '0' );
      
    ELSIF( FALLING_EDGE( Avalon_Clock ) ) THEN
      
      IF( ( AVM_read = '1' ) OR ( AVM_write = '1' ) ) THEN
        
        FPGA_BuffBusy <= '1';
        FPGA_BusyCnt  <= 0;
        
      ELSE
        
        IF( FPGA_BusyCnt < 4 ) THEN
          FPGA_BusyCnt <= FPGA_BusyCnt + 1;
        ELSE
          FPGA_BuffBusy <= '0';
         END IF;
         
      END IF;
      
      IF( IntReaded = '0' ) THEN
        
        IntFlagRegDIF := IntFlagRegPREV XOR IntFlagREG;
        
        IF( ( ( IntFlagRegDIF( 2 DOWNTO 0 ) AND IntFlagREG( 2 DOWNTO 0 )  ) AND Signal_Registers( INTMASK_REG_ADDR )( 2 DOWNTO 0 )  ) /= x"00" ) THEN --x"00000000"
          Interrupt <= '1';
        ELSE
          Interrupt <= '0';
        END IF;
        
        IntFlagRegPREV <= IntFlagREG;
        IntFlagREG( RX_OK )                               <= RxOk;
        IntFlagREG( TX_COMPL )                            <= CTRL_Tx_Compl_OUT; --TxComplete;
        IntFlagREG( TX_ERROR )                            <= RXPHY_Error_OUT;
        IntFlagREG( FPGA_BUFF_BUSY )                      <= FPGA_BuffBusy;
        IntFlagREG( RD_PTR_H DOWNTO RD_PTR_L )            <= RdPtr;
        IntFlagREG( RXWRD_AVAIL_H DOWNTO RXWRD_AVAIL_L  ) <= WordsAvail;
        
      ELSE
        
        IntFlagREG( 2 DOWNTO 0 ) <= ( OTHERS => '0' );  -- ONLY LSB of IntFlagREG clear
        
      END IF;
      
    END IF;
  
  END PROCESS;
  
  
  
  PROCESS( Avalon_nReset, Avalon_Clock )
  BEGIN
    
    IF( Avalon_nReset = '0' ) THEN
      
      AVS_waitrequest   <= '1';
      AVS_readdatavalid <= '0';
      AVS_readdata      <= ( OTHERS => '0' );
      IntReaded         <= '0';
      Signal_Registers  <= ( ( OTHERS => '0' ), ( OTHERS => '0' ), ( OTHERS => '1' ), ( OTHERS => '0') );
      Signal_SlaveState <= AVALON_RESET;
      
    ELSIF RISING_EDGE( Avalon_Clock ) THEN
      
      CASE Signal_SlaveState IS
      
      WHEN AVALON_IDLE =>
        IF( IntReaded = '0' ) THEN 
          Signal_Registers( INTFLAG_REG_ADDR )(  2 DOWNTO 0 ) <= Signal_Registers( INTFLAG_REG_ADDR )( 2 DOWNTO 0 ) OR IntFlagREG( 2 DOWNTO 0 );
          Signal_Registers( INTFLAG_REG_ADDR )( 31 DOWNTO 3 ) <= IntFlagREG( 31 DOWNTO 3 );
        ELSE
          Signal_Registers( INTFLAG_REG_ADDR )( 2 DOWNTO 0 )  <= ( OTHERS => '0' );
        END IF;
        IF( CTRL_Tx_Compl_OUT = '1' ) THEN
          Signal_Registers( CONFIG_REG_ADDR )( NEW_DATA_AVAIL ) <= '0';
        END IF;
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
        IntReaded         <= '0';
        StateReaded       <= '0';
        address           <= TO_INTEGER( UNSIGNED( AVS_address ) );
        data              <= AVS_writedata;
      
      WHEN AVALON_WRITE =>
        AVS_waitrequest             <= '1';
        AVS_readdatavalid           <= '0';
        AVS_readdata                <= ( OTHERS => '0' );
        Signal_Registers( address ) <= data;
        Signal_SlaveState           <= AVALON_IDLE;
      
      WHEN AVALON_READ =>
        IF( address = INTFLAG_REG_ADDR ) THEN
          IntReaded <= '1';
        END IF;
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '1';
        AVS_readdata      <= Signal_Registers( address );
        Signal_SlaveState <= AVALON_IDLE;
      
      WHEN OTHERS =>
        IntReaded         <= '0';
        AVS_waitrequest   <= '1';
        data              <= ( OTHERS => '0' );
        address           <= 0;
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
        Signal_SlaveState <= AVALON_IDLE;
      
      END CASE;
      
    END IF;
    
  END PROCESS;
  
  
END logic;
