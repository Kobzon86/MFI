LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.A708_pkg.ALL;

ENTITY A708_Control IS
  
  PORT(
    
    Enable      : IN  STD_LOGIC;
    Clk         : IN  STD_LOGIC; 
    
    RxReady     : IN  STD_LOGIC;
    RxError     : IN  STD_LOGIC;
    RxData      : IN  STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
    RxBusy      : IN  STD_LOGIC;
    RxEmpty     : IN  STD_LOGIC;
    RxRdReq     : OUT STD_LOGIC;
    RxOk        : OUT STD_LOGIC;
    
    TxBusy      : IN  STD_LOGIC;
    TxFull      : IN  STD_LOGIC;
    TxEmpty     : IN  STD_LOGIC;
    TxWrReq     : OUT STD_LOGIC;
    TxData      : OUT STD_LOGIC_VECTOR( ( PHY_DATA_WIDTH - 1 ) DOWNTO 0 );
    
    RamNDAvail  : IN  STD_LOGIC;
    CPUBuffBusy : IN STD_LOGIC;
    Tx_Compl    : OUT STD_LOGIC;
    AV_Load     : IN  STD_LOGIC;
    AV_WordIn   : IN  STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV_RdEn     : OUT STD_LOGIC;
    AV_WrEn     : OUT STD_LOGIC;
    AV_RAMAddr  : OUT STD_LOGIC_VECTOR( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
    AV_DataOut  : OUT STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
    AV_ByteEn   : OUT STD_LOGIC_VECTOR( ( ( RAM_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 )
    
  );
  
END A708_Control;

ARCHITECTURE RTL OF A708_Control IS
  
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
  
  CONSTANT CLKFREQ_HZ      : INTEGER := 62500000;
  CONSTANT TXWORDS_TIME_MS : INTEGER := 5;
  
  CONSTANT TX_PAUSE_TIME   : STD_LOGIC_VECTOR( 19 DOWNTO 0 ) := STD_LOGIC_VECTOR( TO_UNSIGNED( CLKFREQ_HZ / 1000 * TXWORDS_TIME_MS , 20 ) );
  
  TYPE FSM_State IS ( RESET, IDLE, RD_RXPHY, WR_BUFF, WR_ADDR_CALC, RD_ADDR_CALC, RDBUFF_REQ, RD_WAIT, WR_TXPHY, FIFO_PURGE );
  
  ATTRIBUTE enum_encoding : STRING;
  ATTRIBUTE enum_encoding OF FSM_State : TYPE IS "safe,one-hot";
  
  SIGNAL PresState     : FSM_State;
  SIGNAL NextState     : FSM_State;
  SIGNAL PartsCnt      : INTEGER RANGE 0 TO ( WORDPARTS_16B * A708RXWORDS_NUM ) / 2;
  SIGNAL AV_WrData     : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AV_RdData     : STD_LOGIC_VECTOR( ( RAM_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AV_WrAddr     : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL AV_RdAddr     : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL BuffBusy      : STD_LOGIC;
  SIGNAL AV_HalfWrdCnt : INTEGER RANGE 0 TO 2;
  SIGNAL ReadyToRead   : STD_LOGIC;
  SIGNAL BuffFree      : STD_LOGIC;
  SIGNAL WordTxStart   : STD_LOGIC;
  SIGNAL WaitCnt       : INTEGER RANGE 0 TO 15;
  
BEGIN
  
  
  
  ReadyPulseGen : pgen 
  GENERIC MAP(
    Edge => '1'
  )
  PORT MAP(
    Enable => Enable,
    Clk    => Clk,
    Input  => RxReady,
    Output => ReadyToRead 
  );
  
  
  
  TxStarter : timer -- 5 ms timer interval
  PORT MAP(
    Enable   => RamNDAvail,
    Clk_x16  => Clk,
    Time     => TX_PAUSE_TIME,
    ARST     => '0',
    Single   => '0',
    Ready    => WordTxStart
  );
  
  
  
  StateSW : PROCESS( Enable, Clk )
  BEGIN
    
    IF( Enable = '0' ) THEN
      
      PresState <= RESET;
      
    ELSIF( RISING_EDGE( Clk ) ) THEN
      
      PresState <= NextState;
      
    END IF;
    
  END PROCESS;
  
  
  
  StateHandle : PROCESS( Enable, Clk )
  BEGIN
    
    IF Enable = '0' THEN
      
      AV_HalfWrdCnt <= 0;
      PartsCnt   <= 0;
      RxRdReq    <= '0';
      TxWrReq    <= '0';
      AV_WrEn    <= '0';
      AV_RdEn    <= '0';
      AV_WrAddr  <= RXBUFF_START;
      AV_RdAddr  <= TXBUFF_START;
      AV_DataOut <= ( OTHERS => '0' );
      AV_ByteEn  <= ( OTHERS => '0' );
      BuffBusy   <= '0';
      BuffFree   <= '1';
      WaitCnt    <= 0;
      RxOk       <= '0';
      Tx_Compl   <= '0';
      NextState  <= RESET;
      
    ELSIF FALLING_EDGE( Clk ) THEN
      
      CASE PresState IS
      
      WHEN IDLE =>
        IF( AV_RdAddr = TXBUFF_START ) THEN
          Tx_Compl <= '0';
        END IF;
        IF( ( ReadyToRead = '1' ) AND ( ( CPUBuffBusy = '0' ) AND ( RxEmpty = '0' ) ) ) THEN
          BuffBusy   <= '1';
          PartsCnt  <= 0;
          NextState  <= RD_RXPHY;
        ELSIF( WordTxStart = '1' ) THEN 
          BuffBusy  <= '1';
          PartsCnt  <= 0;
          NextState <= RD_ADDR_CALC;
        END IF;
        AV_HalfWrdCnt <= 0;
        RxRdReq    <= '0';
        TxWrReq    <= '0';
        AV_WrEn    <= '0';
        AV_RdEn    <= '0';
        AV_DataOut <= ( OTHERS => '0' );
        AV_ByteEn  <= ( OTHERS => '0' );
        WaitCnt    <= 0;
        RxOk       <= '0';
        BuffBusy   <= '0';
      
      WHEN RD_RXPHY =>
        IF( AV_HalfWrdCnt < 2 ) THEN
          RxRdReq <= '1';
          AV_HalfWrdCnt <= AV_HalfWrdCnt + 1;
        ELSE
          IF( AV_WrAddr <= RXBUFF_END ) THEN  -- A708RX_BUFF not full
            IF( PartsCnt < ( WORDPARTS_16B / 2 ) ) THEN -- not whole A708 word readed from RX_FIFO
              PartsCnt  <= PartsCnt + 1;
              AV_WrAddr <= AV_WrAddr + TO_UNSIGNED( 1, AV_WrAddr'LENGTH );
              NextState <= WR_BUFF;
            ELSE
              RxOk      <= '1';
              AV_ByteEn <= ( OTHERS => '0' );
              PartsCnt  <= 0;
              NextState <= IDLE; -- A708 whole word readed from RX_FIFO
            END IF;
          ELSE -- A708RX_BUFF full
            AV_ByteEn <= ( OTHERS => '0' );
            AV_WrAddr <= RXBUFF_START;  -- next time write to A708RX_BUFF from first address
            PartsCnt  <= 0;
            RxOk      <= '1';
            NextState <= IDLE;  -- A708 RX_BUFF full!
          END IF;
          RxRdReq       <= '0';
          AV_HalfWrdCnt <= 0;
        END IF;
        IF( AV_HalfWrdCnt > 0 ) THEN
          AV_WrData( ( AV_WrData'LEFT - PHY_DATA_WIDTH * ( AV_HalfWrdCnt - 1 ) ) DOWNTO ( AV_WrData'LENGTH - PHY_DATA_WIDTH * ( AV_HalfWrdCnt ) ) ) <= RxData;
        END IF;
        AV_WrEn    <= '0';
        AV_RAMAddr <= STD_LOGIC_VECTOR( AV_WrAddr );
      
      WHEN WR_BUFF =>
        AV_WrEn   <= '1';
        AV_ByteEn <= ( OTHERS => '1' );
        --==== Bytes swap for iMX6 sutable software ===============
        AV_DataOut(  7 DOWNTO  0 ) <= AV_WrData( 31 DOWNTO 24 );
        AV_DataOut( 15 DOWNTO  8 ) <= AV_WrData( 23 DOWNTO 16 );
        AV_DataOut( 23 DOWNTO 16 ) <= AV_WrData( 15 DOWNTO  8 );
        AV_DataOut( 31 DOWNTO 24 ) <= AV_WrData(  7 DOWNTO  0 );
        --=========================================================
        NextState <= RD_RXPHY;
      
      WHEN RD_ADDR_CALC =>
        IF( PartsCnt < WORDPARTS_16B / 2 ) THEN
          IF( AV_RdAddr <= ( TXBUFF_END  ) ) THEN
            AV_RdAddr  <= AV_RdAddr + TO_UNSIGNED( 1, AV_RdAddr'LENGTH );
            AV_RAMAddr <= STD_LOGIC_VECTOR( AV_RdAddr );
            AV_ByteEn  <= ( OTHERS => '1' );
            NextState  <= RDBUFF_REQ;
            Tx_Compl   <= '0';
          ELSE
            AV_RdAddr <= TXBUFF_START; 
            BuffBusy  <= '0';
            Tx_Compl  <= '1';
            NextState <= IDLE;
          END IF;
          PartsCnt <= PartsCnt + 1;
        ELSE
          NextState <= IDLE;
        END IF;
      
      WHEN RDBUFF_REQ =>
        AV_RdEn   <= '1';
        WaitCnt   <= 0;
        NextState <= RD_WAIT;
      
      WHEN RD_WAIT =>
        AV_RdEn <= '0';
        IF( WaitCnt < 15 ) THEN
          IF( AV_Load = '1' ) THEN
            AV_RdData <= AV_WordIn;
            NextState <= WR_TXPHY;
          END IF;
          WaitCnt <= WaitCnt + 1;
        ELSE
          NextState <= IDLE;
        END IF;
      
      WHEN WR_TXPHY =>
        IF( AV_HalfWrdCnt < 2 ) THEN
          IF( TxFull = '0' ) THEN
            TxWrReq       <= '1';
            TxData        <= ( AV_RdData( (  7 + PHY_DATA_WIDTH * AV_HalfWrdCnt ) DOWNTO ( 0 + PHY_DATA_WIDTH * AV_HalfWrdCnt ) ) &
                               AV_RdData( ( 15 + PHY_DATA_WIDTH * AV_HalfWrdCnt ) DOWNTO ( 8 + PHY_DATA_WIDTH * AV_HalfWrdCnt ) ) );
            AV_HalfWrdCnt <= AV_HalfWrdCnt + 1;
          ELSE
            TxWrReq   <= '0';
            NextState <= IDLE;
          END IF;
        ELSE 
          TxWrReq       <= '0';
          AV_HalfWrdCnt <= 0;
          NextState     <= RD_ADDR_CALC;
        END IF;
      
      WHEN OTHERS => 
        AV_HalfWrdCnt <= 0;
        PartsCnt      <= 0;
        RxRdReq       <= '0';
        TxWrReq       <= '0';
        AV_WrEn       <= '0';
        AV_RdEn       <= '0';
        AV_WrAddr     <= RXBUFF_START;
        AV_RdAddr     <= TXBUFF_START;
        AV_DataOut    <= ( OTHERS => '0' );
        AV_ByteEn     <= ( OTHERS => '0' );
        BuffBusy      <= '0';
        BuffFree      <= '1';
        WaitCnt       <= 0;
        RxOk          <= '0';
        Tx_Compl      <= '0';
        NextState     <= IDLE;
      
      END CASE;
      
    END IF;
    
  END PROCESS;
  
  
  
END RTL;
