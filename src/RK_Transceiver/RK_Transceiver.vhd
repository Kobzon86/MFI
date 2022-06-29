LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.rk_pkg.ALL;

ENTITY RK_Transceiver IS
  
  PORT(
    
    Avalon_nReset     : IN  STD_LOGIC := '0';
    Avalon_Clock      : IN  STD_LOGIC;
    
    AVS_waitrequest   : OUT STD_LOGIC;
    AVS_address       : IN  STD_LOGIC_VECTOR(  2 DOWNTO 0 );
    AVS_byteenable    : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    AVS_read          : IN  STD_LOGIC;
    AVS_readdata      : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    AVS_readdatavalid : OUT STD_LOGIC;
    AVS_write         : IN  STD_LOGIC;
    AVS_writedata     : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    
    Interrupt         : OUT STD_LOGIC;
    
    RK_VWet_Sel       : OUT STD_LOGIC;
    RK_Ths_Sel        : OUT STD_LOGIC;
    RK_Sense_Sel      : OUT STD_LOGIC;
    RK_In_Set         : OUT STD_LOGIC;
    RK_Input          : IN  STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    RK_Input_Addr     : IN  STD_LOGIC_VECTOR(  4 DOWNTO 0 );
    
    RK_Fault          : IN  STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    RK_Output         : OUT STD_LOGIC_VECTOR(  3 DOWNTO 0 );
    RK_27V_0V_Sel     : IN  STD_LOGIC;
    RK_27V_0V_Fault   : IN  STD_LOGIC;
    RK_TEST           : OUT STD_LOGIC;
    RK_27V_Output     : OUT STD_LOGIC;
    RK_0V_Output      : OUT STD_LOGIC
    
  );
  
END RK_Transceiver;

ARCHITECTURE logic OF RK_Transceiver IS
  
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
  
  TYPE   T_Avalon_State     IS ( AVALON_RESET, AVALON_IDLE, AVALON_WRITE,  AVALON_READ); --AVALON_ACK_WRITE, AVALON_ACK_READ );
  TYPE   T_Conf_Registers   IS ARRAY( 7 DOWNTO 0 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  
  ATTRIBUTE enum_encoding : STRING;
  ATTRIBUTE enum_encoding OF T_Avalon_State : TYPE IS "safe,one-hot";
  
  SIGNAL Signal_SlaveState  : T_Avalon_State;
  
  SIGNAL Signal_Registers   : T_Conf_Registers;
  
  SIGNAL TimerReady         : STD_LOGIC;
  SIGNAL AVM_Active         : STD_LOGIC;
  SIGNAL TimerTurnOff       : STD_LOGIC;
  SIGNAL RK_TurnOn          : STD_LOGIC;
  SIGNAL PrevIntFlagsReg    : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  SIGNAL RK_out_debug       : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
  SIGNAL Rx1, Rx2, RxEn     : STD_LOGIC;
  SIGNAL SelfTest           : STD_LOGIC;
  SIGNAL LocOut             : STD_LOGIC_VECTOR( 3 DOWNTO 0 );
  SIGNAL Loc_0V_Out         : STD_LOGIC;
  SIGNAL TurnOffTimerRST    : STD_LOGIC;
  SIGNAL RK_Clock           : STD_LOGIC;
  SIGNAL RK_OutEn_Pulse     : STD_LOGIC;
  SIGNAL RK_OutEn           : STD_LOGIC;
  
  SIGNAL address            : INTEGER RANGE 0 TO 7;
  SIGNAL data               : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
  
BEGIN
  
  
  
  AvClkDiv : timer 
  PORT MAP(
    Enable   => Avalon_nReset,
    Clk_x16  => Avalon_Clock,
    Time     => AvClkIN_Div,
    ARST     => '0',
    Single   => '0',
    Ready    => RK_Clock
  );
  
  OutputTimer : timer 
  PORT MAP(
    Enable   => Avalon_nReset,
    Clk_x16  => RK_Clock,
    Time     => Period,
    ARST     => '0',
    Single   => '0',
    Ready    => TimerReady
  );
  
  RKOFF_Timer : timer 
  PORT MAP(
    Enable   => Avalon_nReset,
    Clk_x16  => RK_Clock,
    Time     => RK_OFF_Timeout,
    ARST     => TurnOffTimerRST, --  AVM_Active,
    Single   => '1',
    Ready    => TimerTurnOff
  );
  
  RK_OUT_EN : timer 
  PORT MAP(
    Enable   => Avalon_nReset,
    Clk_x16  => RK_Clock,
    Time     => STD_LOGIC_VECTOR( TO_UNSIGNED(1_600_000, 20)),
    ARST     => '0',
    Single   => '0',
    Ready    => RK_OutEn_Pulse
  );
  
  
  
  TurnOffTimerRST <= AVM_Active OR SelfTest;
  RK_Output       <= LocOut AND ( NOT Signal_Registers( RK_IN_STATE_REG_ADDR )( 11 DOWNTO 8 ) );
  RK_0V_Output    <= Loc_0V_Out AND ( NOT Signal_Registers( RK_IN_STATE_REG_ADDR )( 12 ) );
  Interrupt       <= '1' WHEN ( Signal_Registers( RK_INTFLAG_REG_ADDR ) AND Signal_Registers( RK_INTMASK_REG_ADDR ) ) /= x"00000000" ELSE '0';
  AVM_Active      <= ( AVS_read OR AVS_write );
  SelfTest        <= Signal_Registers( RK_OUT_STATE_REG_ADDR ) ( TEST_EN_BIT );
  
  
  
  RxPulseGen: PROCESS ( Avalon_Clock )
  BEGIN
    IF RISING_EDGE( Avalon_Clock ) THEN
      Rx1  <= TimerReady;
      Rx2  <= Rx1;
      RxEn <= Rx1 AND ( NOT Rx2 );
    END IF;
  END PROCESS;
  
  
  
  -- add turn-off RK_OUT when no connection with iMX6
  -- and turn-on RK_OUT(1) - iMX6 connection error
  RK_OFF_TRIG: PROCESS( Avalon_nReset, Avalon_Clock )
  BEGIN
    
    IF( Avalon_nReset = '0' ) THEN
      
      RK_TurnOn <= '0';
      
    ELSIF( RISING_EDGE( Avalon_Clock ) ) THEN 
      
      IF( SelfTest = '0' ) THEN
        
        IF( AVM_Active = '1' ) THEN
          RK_TurnOn <= '1';
        ELSIF TimerTurnOff = '1' THEN
          RK_TurnOn <= '0';
        END IF;
        
      ELSE
        
        RK_TurnOn <= '1';
        
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  RK_OutGEN: PROCESS( Avalon_nReset, Avalon_Clock )
  BEGIN
    
    IF( Avalon_nReset = '0' ) THEN
      
      LocOut         <= ( OTHERS => '0' );
      Loc_0V_Out     <= '0';
      RK_27V_Output  <= '0';
      RK_OutEn       <= '0';
      
    ELSIF( RISING_EDGE( Avalon_Clock ) ) THEN
      
      IF( RK_OutEn_Pulse = '1' ) THEN
        RK_OutEn  <= '1';
      END IF;
      
      IF( RxEn = '1' ) THEN
        
        IF( ( RK_TurnOn = '1' ) AND ( RK_OutEn = '1' ) ) THEN  
          LocOut         <= Signal_Registers( RK_OUT_STATE_REG_ADDR )( 3 DOWNTO 0 ); 
          Loc_0V_Out     <= Signal_Registers( RK_OUT_STATE_REG_ADDR )( RK_OUT_27V0V ); 
          RK_27V_Output  <= '0';
          RK_VWet_Sel    <= Signal_Registers( RK_OUT_STATE_REG_ADDR )( VWET_BIT );
          RK_Ths_Sel     <= Signal_Registers( RK_OUT_STATE_REG_ADDR )( THS_BIT ); 
          RK_Sense_Sel   <= Signal_Registers( RK_OUT_STATE_REG_ADDR )( SENSE_BIT ); 
          RK_In_Set      <= Signal_Registers( RK_OUT_STATE_REG_ADDR )( IN_SET_BIT ); 
          RK_TEST        <= Signal_Registers( RK_OUT_STATE_REG_ADDR )( TEST_EN_BIT ); 
        ELSE
          LocOut        <= ( OTHERS => '0' );
          RK_27V_Output <= '0';
          Loc_0V_Out    <= '0';
        END IF;
        
      END IF;
      
    END IF;
    
   END PROCESS;
  
  
  
  -- Settings registers ( Avalon-MM Slave )
  PROCESS( Avalon_nReset, Avalon_Clock )
  BEGIN
    
    IF( Avalon_nReset = '0' ) THEN
      
      AVS_waitrequest   <= '1';
      AVS_readdatavalid <= '0';
      AVS_readdata      <= ( OTHERS => '0' );
      Signal_Registers  <= ( x"FFFFFFFF", x"FFFFFFFF", x"FFFFFFFF", x"FFFFFFFF", x"00000000", x"FFFFFFFF", x"00000001", x"00000000" );
      Signal_SlaveState <= AVALON_RESET;
      
    ELSIF( ( Avalon_Clock'EVENT ) AND ( Avalon_Clock = '1' ) ) THEN
      
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
        IF( ( RxEn = '1' ) AND ( RK_OutEn = '1' ) ) THEN
          Signal_Registers( RK_IN_STATE_REG_ADDR )( 7 DOWNTO 0 )   <= RK_Input;
          Signal_Registers( RK_IN_STATE_REG_ADDR )( 8 )            <= Signal_Registers( RK_IN_STATE_REG_ADDR )( 8 ) OR RK_Fault( 0 );
          Signal_Registers( RK_IN_STATE_REG_ADDR )( 9 )            <= Signal_Registers( RK_IN_STATE_REG_ADDR )( 9 ) OR RK_Fault( 1 );
          Signal_Registers( RK_IN_STATE_REG_ADDR )( 10 )           <= Signal_Registers( RK_IN_STATE_REG_ADDR )( 10 ) OR RK_Fault( 2 );
          Signal_Registers( RK_IN_STATE_REG_ADDR )( 11 )           <= Signal_Registers( RK_IN_STATE_REG_ADDR )( 11 ) OR RK_Fault( 3 );
          Signal_Registers( RK_IN_STATE_REG_ADDR )( 12 )           <= Signal_Registers( RK_IN_STATE_REG_ADDR )( 12 ) OR RK_27V_0V_Fault;
          Signal_Registers( RK_IN_STATE_REG_ADDR )( 26 DOWNTO 13 ) <= ( OTHERS => '0' );
					Signal_Registers( RK_IN_STATE_REG_ADDR )( 31 DOWNTO 27 ) <= RK_Input_Addr;
        END IF;
        FOR i IN 0 TO 7 LOOP
          IF Signal_Registers( RK_IN_STATE_REG_ADDR )(i) /= PrevIntFlagsReg(i) THEN
            Signal_Registers( RK_INTFLAG_REG_ADDR )(i) <= '1';
          END IF;
        END LOOP;
        address                                                <= TO_INTEGER( UNSIGNED( AVS_address ) );
        data                                                   <= AVS_writedata;
        AVS_readdatavalid                                      <= '0';
        AVS_readdata                                           <= ( OTHERS => '0' );
        PrevIntFlagsReg                                        <= Signal_Registers( RK_IN_STATE_REG_ADDR );
        Signal_Registers( RK_INTFLAG_REG_ADDR )( 31 DOWNTO 8 ) <= ( OTHERS => '0' );
      
      WHEN AVALON_WRITE =>
        AVS_waitrequest             <= '1';
        AVS_readdatavalid           <= '0';
        AVS_readdata                <= ( OTHERS => '0' );
        Signal_Registers( address ) <= data;
        Signal_SlaveState           <= AVALON_IDLE;
      
      WHEN AVALON_READ =>
        IF( address = RK_INTFLAG_REG_ADDR ) THEN
          Signal_Registers( RK_INTFLAG_REG_ADDR ) <= ( OTHERS => '0' );
        END IF;
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '1';
        AVS_readdata      <= Signal_Registers( address );
        Signal_SlaveState <= AVALON_IDLE;
      
      WHEN AVALON_RESET =>
        AVS_waitrequest   <= '1';
        AVS_readdatavalid <= '0';
        AVS_readdata      <= ( OTHERS => '0' );
        Signal_SlaveState <= AVALON_IDLE;
      
      END CASE;
      
    END IF;
    
  END PROCESS;
  
  
  
END logic;
