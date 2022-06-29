LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

USE work.arinc429tx_pkg.ALL;

ENTITY a429_TxControl IS
  
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
    StateRegRst  : IN  STD_LOGIC;
    AVM_RdValid  : IN STD_LOGIC;
    RAMWrAddr    : IN STD_LOGIC_VECTOR( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 );
    AddrRol      : IN STD_LOGIC;
    RAM_WrEn  : IN STD_LOGIC;
    ByteEn    : OUT STD_LOGIC_VECTOR( ( ( AV_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
    TxMode    : OUT STD_LOGIC;
    FreeSpace : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
    TxPause   : OUT STD_LOGIC_VECTOR( 19 DOWNTO 0 )
  );

END a429_TxControl;

ARCHITECTURE RTL OF a429_TxControl IS
  
  TYPE StateType IS ( IDLE, TX_DATA, TEST, RD_REQ, ADDR_CALC, RD_WAIT );
  
  ATTRIBUTE enum_encoding : STRING;
  ATTRIBUTE enum_encoding OF StateType : TYPE IS "safe,one-hot";
  
  CONSTANT AvalonACKWait : UNSIGNED( 7 DOWNTO 0 ) := TO_UNSIGNED( 64, 8 ); --x"F";--x"7"; -- Wait cycle number for Load signal
  
  --CONSTANT Pause : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( ( 1600 * 1 ), 20 ) ); -- 1 ms pause between words in media
  --CONSTANT Pause : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( ( 512 ), 20 ) );      -- 320 us pause between words in media. good transmission
  CONSTANT Pause : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( ( 2 ), 20 ) );          -- 1.25 us Pause minimal available. TxStarter after previous transmission
  
  SIGNAL NextState : StateType := IDLE;
  SIGNAL PresState : StateType := IDLE;
  
  SIGNAL IntStateReg : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL RAMData     : STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 )    := ( OTHERS => '0' );
  SIGNAL TxModeBit   : STD_LOGIC := '0'; -- 0 = Cyclic data transmission, 1 = Single data transmission after iMX6 command
  SIGNAL WordCnt     : UNSIGNED( 4 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL WrEnTmp     : STD_LOGIC := '0';
  SIGNAL RdEnTmp     : STD_LOGIC := '0';  
  SIGNAL WrDataTmp   : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0  );
  SIGNAL StartPulse  : STD_LOGIC := '0';
  SIGNAL l1, l2      : STD_LOGIC := '0';

  SIGNAL TxFULL_Tmp    : STD_LOGIC := '0'; 
  SIGNAL TxCOMPL       : STD_LOGIC := '0'; -- TxFULL_Tmp For internal use only
  SIGNAL TxEMPTY       : STD_LOGIC := '1';

  SIGNAL TxFULL        : STD_LOGIC := '0';
  SIGNAL NextDataReady : STD_LOGIC := '0';
  SIGNAL WaitTimer     : UNSIGNED( 7 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL LoadStretched : STD_LOGIC := '0';
  SIGNAL LS1, LS2      : STD_LOGIC := '1';
  SIGNAL TC1, TC2      : STD_LOGIC := '0';
  SIGNAL SR1, SR2      : STD_LOGIC := '0';
  SIGNAL WrPtr         : UNSIGNED( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' ); -- Next address pointer should be writed
  SIGNAL RdPtr         : UNSIGNED( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' ); -- Already readed Address Pointer
  SIGNAL RdPtrTmp      : UNSIGNED( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' ); 
  SIGNAL FreeAvail     : UNSIGNED( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );  
  
  SIGNAL te1, te2, tf1,tf2     : STD_LOGIC := '0';
  SIGNAL txe1, txe2            : STD_LOGIC := '0';
  SIGNAL FIFO_OP               : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL rv1, rv2, valid_pulse : STD_LOGIC := '0';
  SIGNAL rw1, rw2, wr_pulse    : STD_LOGIC := '0';
  SIGNAL RamBusy               : STD_LOGIC := '0';
  SIGNAL RamBusyTmp            : STD_LOGIC := '0';
  SIGNAL RingFull              : STD_LOGIC := '0';
  
  
BEGIN
  
  
  
  RamBusy <= RamBusyTmp OR BuffBusy;
  
  
  
  PulseGen: PROCESS( Enable, AvClk ) 
  BEGIN
    
    IF Enable = '0' THEN
      
      rv1 <= '1';
      rv2 <= '1';
      rw1 <= '0';
      rw2 <= '0';
      
    ELSIF RISING_EDGE( AvClk ) THEN
      
      rv1 <= NOT AVM_RdValid;
      rv2 <= rv1;
      valid_pulse <= rv1 AND ( NOT rv2 );
      rw1 <= RAM_WrEn;
      rw2 <= rw1;
      wr_pulse <= rw2 AND ( NOT rw1 );
      
    END IF;
    
  END PROCESS;
  
  
  
  BusyCounter: PROCESS( Enable, AvClk )
    VARIABLE BusyCnt : INTEGER RANGE 0 TO 7 := 0;
  BEGIN
  
    IF Enable = '0' THEN
    
      BusyCnt := 0;
      
    ELSIF FALLING_EDGE( AvClk ) THEN
    
      IF BuffBusy = '1' THEN
        BusyCnt := 0;
        RamBusyTmp <= '1';
      ELSE
        IF BusyCnt < 7 THEN
          BusyCnt := BusyCnt + 1;
        ELSE
          BusyCnt := 0;
          RamBusyTmp <= '0';
        END IF;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  ReadPointerLatch: PROCESS( Enable, AvClk )
  BEGIN
    
    IF Enable = '0' THEN
      
      WrPtr <= ( OTHERS => '0' );
      
    ELSIF FALLING_EDGE( AvClk ) THEN
      
      IF wr_pulse = '1' AND ( TxFULL = '0' ) THEN
        IF WrPtr < ( TXFIFO_SIZE - 1 ) THEN
          WrPtr <= WrPtr + TO_UNSIGNED( 1, WrPtr'LENGTH );
        ELSE
          WrPtr <= ( OTHERS => '0' );
        END IF;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  FIFO_OP <= wr_pulse & valid_pulse;
  
  
  
  StateOut: PROCESS( Enable, AvClk )
  BEGIN
    
    IF Enable = '0' THEN
    
      te1 <= '0';
      te2 <= '0';
      tf1 <= '0';
      tf2 <= '0';
      txe1 <= '0';
      txe2 <= '0';
    
    ELSIF RISING_EDGE( AvClk ) THEN
      
      TxPause <= Pause;
      
      te1 <= TxEMPTY;
      te2 <= te1;
      
      tf1 <= TxFULL;
      tf2 <= tf1;
      
      txe1 <= TxLineErr;
      txe2 <= txe1;
      
      IntStateReg( TX_ERROR )    <= ( txe1 AND ( NOT txe2 ) );  -- TxLineErr pulse generation
      IntStateReg( TX_OVF )      <= ( tf1 AND ( NOT tf2 ) );    -- TxFULL pulse generation
      IntStateReg( TX_TXCOMPL )  <= TxCOMPL;                    -- already pulse generated in TxComplPulse PROCESS
      IntStateReg( TX_EMPTY )    <= ( te1 AND ( NOT te2 ) );    -- TxEMPTY pulse generation
      
    END IF;
    
  END PROCESS;
  
  
  
  TxComplPulse: PROCESS( Enable, AvClk )
  BEGIN
    
    IF Enable = '0' THEN
      
      TxCOMPL <= '0';
      TC1     <= '1';
      TC2     <= '1';
      
    ELSIF RISING_EDGE( AvClk ) THEN
      
      TC1     <= NOT TxPhyBusy;
      TC2     <= TC1;
      TxCOMPL <= TC1 AND ( NOT TC2 );
      
    END IF;
    
  END PROCESS;
  
  
  
  TxStarter: PROCESS( Enable,  AvClk )
  BEGIN
    
    IF Enable = '0' THEN
      
      l1 <= '0';
      l2 <= '0';
      StartPulse <= '0';
      
    ELSIF RISING_EDGE( AvClk ) THEN
      
      IF ( ( LineBusy AND ( TxPhyBusy AND RamBusy ) ) = '0' ) THEN 
        IF  TxEMPTY = '0' THEN
          l1 <= TxStart;
          l2 <= l1;
          StartPulse <= l1 AND ( NOT l2 );
        ELSE   
          StartPulse <= '0'; 
          l1 <= '0';
          l2 <= '0';
        END IF;
      
      ELSE
        StartPulse <= '0';
        l1 <= '0';
        l2 <= '0';
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  LoadSync: PROCESS( AvClk )
  BEGIN
    
    IF RISING_EDGE( AvClk ) THEN
      
      LS1 <= Load;
      LS2 <= LS1;
      LoadStretched <= LS1 AND ( NOT LS2 );  
      
    END IF;
    
  END PROCESS;
  
  
  
  --------- pulse stretch for ClockIn --------------  
  WrEn_GEN: PROCESS( AvClk )
  BEGIN
    
    IF FALLING_EDGE( AvClk ) THEN
      
      RdEn  <= RdEnTmp;
      
    ELSIF RISING_EDGE( AvClk ) THEN
      
      WrEn   <= WrEnTmp;
      WrData <= WrDataTmp;
      
    END IF;
    
  END PROCESS;
  
  
  
  StateSwitcher: PROCESS( Enable, AvClk )
  BEGIN
    IF Enable = '0' THEN

      PresState <= IDLE;
      State     <= ( OTHERS => '0' );

    ELSIF FALLING_EDGE( AvClk ) THEN

      PresState <= NextState;  
      State     <= IntStateReg;

    END IF;
  END PROCESS;
  
  
  
  StateHandler: PROCESS( Enable, AvClk )
    VARIABLE Rdata : STD_LOGIC_VECTOR( ( AV_DATA_WIDTH - 1 ) DOWNTO 0 ) := ( OTHERS => '0' ); 
  BEGIN
    
    IF Enable = '0' THEN
      
      RdPtr    <= TXFIFO_SIZE - x"1";
      RdPtrTmp <= TXFIFO_SIZE - x"1";
      TxEMPTY  <= '1';
      
    ELSIF RISING_EDGE( AvClk ) THEN
      
      CASE FIFO_OP IS
      
      WHEN "01" => --reading
        IF TxEMPTY = '0' THEN
          TxFULL <= '0';
          IF WrPtr > RdPtr THEN
            FreeAvail <= ( TXFIFO_SIZE - WrPtr + RdPtr );
            IF  WrPtr = ( RdPtr + 1 ) THEN
              IF TxFULL = '0' THEN
                TxEMPTY <= '1';
              END IF;
            END IF;
          ELSIF WrPtr < RdPtr THEN
            IF ( ( WrPtr = x"0" ) AND ( RdPtr = TXFIFO_SIZE - 1 ) ) THEN
              IF TxFULL = '0' THEN
                TxEMPTY <= '1';
              END IF;
            END IF;
            FreeAvail <= ( RdPtr - WrPtr - 1 );
          ELSE
            FreeAvail <= TXFIFO_SIZE;
          END IF;
        END IF;
        
      WHEN "10" => -- writing
        IF TxFULL = '0' THEN  -- <- WAS COMMENTED, uncomment for simple FIFO mode
          TxEMPTY <= '0';
          IF WrPtr > RdPtr THEN
            FreeAvail <= ( TXFIFO_SIZE -  WrPtr + RdPtr );
          ELSIF WrPtr < RdPtr THEN
            FreeAvail <= ( RdPtr - WrPtr );
           ELSE
            FreeAvail <= ( OTHERS => '0' );
          END IF;
          IF WrPtr = RdPtr THEN
            TxFULL <= '1';
          END IF;
        END IF; -- <- WAS COMMENTED, uncomment for simple FIFO mode
        
      WHEN OTHERS =>
        NULL;
      
      END CASE;
      
      FreeSpace( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 )      <= STD_LOGIC_VECTOR( FreeAvail );
      FreeSpace( FreeSpace'LEFT DOWNTO AR429TX_ADDR_WIDTH ) <= ( OTHERS => '0' );
      
      CASE PresState IS
      
      WHEN IDLE =>
        WrEnTmp <= '0';
        WordCnt <= ( OTHERS => '0' );
        TxMode  <= '0';  -- cyclic transmission 
        ClkMUX  <= ConfReg( 1 DOWNTO 0 );
        IF TestEn = '1' THEN
          NextState <= TEST;
        ELSE
          IF ( ( NextDataReady = '1' ) AND ( Full = '0' ) ) THEN
            NextState <= TX_DATA;
          ELSE
            IF StartPulse = '1' THEN
              IF ( TxEMPTY = '0' ) AND ( RamBusy = '0' ) AND ( Full = '0' ) THEN
                NextState <= ADDR_CALC;
              END IF;
            END IF;
          END IF;
        END IF;
      
      WHEN TX_DATA =>
        WrEnTmp      <= '1';
        IF AddrRol = '0' THEN
          WrDataTmp( WrData'LEFT DOWNTO 8 ) <= RAMData( RAMData'LEFT DOWNTO 8 );
          WrDataTmp(7) <= RAMData(0);
          WrDataTmp(6) <= RAMData(1); 
          WrDataTmp(5) <= RAMData(2);
          WrDataTmp(4) <= RAMData(3);
          WrDataTmp(3) <= RAMData(4);
          WrDataTmp(2) <= RAMData(5);
          WrDataTmp(1) <= RAMData(6);
          WrDataTmp(0) <= RAMData(7);
        ELSE
          WrDataTmp <= RAMData;
        END IF;
        NextDataReady <= '0';
        NextState <= IDLE;
      
      WHEN TEST =>  -- not ready yet
        NextState <= IDLE;
      
      WHEN ADDR_CALC =>
        IF TxFULL = '0' THEN
          IF RdPtrTmp < ( TXFIFO_SIZE - x"1" ) THEN
            RdPtrTmp <= RdPtrTmp + x"1"; 
          ELSE
            RdPtrTmp <= ( OTHERS => '0' );
          END IF;  
        END IF;
        NextState <= RD_REQ;
      
      WHEN RD_REQ =>
        RdEnTmp   <= '1';
        Addr      <= STD_LOGIC_VECTOR( RdPtrTmp );  
        RdPtr     <= RdPtrTmp;
        WaitTimer <= AvalonACKWait;
        ByteEn    <= "1111";
        NextState <= RD_WAIT;
      
      WHEN RD_WAIT =>
        RdEnTmp <= '0';
        IF LoadStretched = '1' THEN
          RAMData       <= WordIn;
          NextDataReady <= '1';
          NextState     <= IDLE;
        ELSE
          IF WaitTimer = x"0" THEN
            NextDataReady <= '0';
            NextState     <= IDLE;
          ELSE
            WaitTimer <= WaitTimer - x"1";
          END IF;
        END IF;
      
      WHEN OTHERS =>
        NextState <= IDLE;
      
      END CASE;
      
    END IF;
  
  END PROCESS;
  
  
  
END RTL;
