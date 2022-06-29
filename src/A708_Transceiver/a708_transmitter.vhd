-- a708_transmitter: ARINC 708 transmitter
-- ver 0.5
-- 16 bit input data
-- ClockIn = 16 MHz
-- Structural implementation
-- Internal Clock = 2 MHz
-- added input FIFO
-- ClockIn total synchronization!! 

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY a708_transmitter IS
  
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
    WriteClk   : IN  STD_LOGIC := '0';
    Data       : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
    OutputA    : OUT STD_LOGIC;
    OutputB    : OUT STD_LOGIC;
    Sleep      : OUT STD_LOGIC;
    TxInhibit  : OUT STD_LOGIC := '1';  -- was 'X'
    FIFO_Empty : OUT STD_LOGIC := '0';
    FIFO_Full  : OUT STD_LOGIC := '0';
    Busy       : OUT STD_LOGIC;
    Transmit   : OUT STD_LOGIC;
    TxRegOut   : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 )
  );
  
END a708_transmitter;

ARCHITECTURE RTL OF a708_transmitter IS
  
  COMPONENT FIFO IS
    GENERIC(
      DataWidth : INTEGER := 8;
      UsedWidth : INTEGER := 8; -- 2 ** UsedWidth = WordNum
      WordNum   : INTEGER := 256
    );
    PORT(
      aclr    : IN  STD_LOGIC  := '0';
      data    : IN  STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0 );
      rdclk   : IN  STD_LOGIC ;
      rdreq   : IN  STD_LOGIC ;
      wrclk   : IN  STD_LOGIC ;
      wrreq   : IN  STD_LOGIC ;
      q       : OUT STD_LOGIC_VECTOR ( ( DataWidth - 1 ) DOWNTO 0 );
      rdempty : OUT STD_LOGIC ;
      wrfull  : OUT STD_LOGIC 
    );
  END COMPONENT;

  CONSTANT SeqWidth    : INTEGER := StartWidth * 2;
  CONSTANT StartSeqA   : STD_LOGIC_VECTOR( ( SeqWidth - 1 ) DOWNTO 0 ) := "111000"; -- for simulation
  CONSTANT StopSeqA    : STD_LOGIC_VECTOR( ( SeqWidth - 1 ) DOWNTO 0 ) := "000111";
  CONSTANT WordWidth   : INTEGER := ( DataWidth * 2 );
  
  CONSTANT FIFO_WordsNum  : INTEGER := 128;
  CONSTANT FIFO_UsedWidth : INTEGER := 7;
  
  TYPE FSM_State IS ( IDLE, GAP, START_SYNC, LOAD_BUFF, SHIFT, STOP_SYNC );
  
  ATTRIBUTE enum_encoding : STRING;
  ATTRIBUTE enum_encoding OF FSM_State : TYPE IS "safe,one-hot";
  
  SIGNAL NextState     : FSM_State;
  SIGNAL PresState     : FSM_State;
  
  SIGNAL Transmission  : STD_LOGIC;
  SIGNAL BitBuffer     : STD_LOGIC;
  SIGNAL LoadStop      : STD_LOGIC;
  SIGNAL Buff          : STD_LOGIC_VECTOR( ( WordWidth - 1 ) DOWNTO 0 );
  SIGNAL outBuff       : STD_LOGIC_VECTOR( ( SeqWidth ) DOWNTO 0 );
  SIGNAL BuffHigh      : STD_LOGIC;
  SIGNAL PreLoad       : STD_LOGIC;
  SIGNAL WrdCntClk     : STD_LOGIC;
  SIGNAL T1, T2        : STD_LOGIC;
  
  SIGNAL bitsCounter   : UNSIGNED( 11 DOWNTO 0 );
  
  SIGNAL WordsCounter  : INTEGER RANGE 0 TO ( TxWordsNum + 2 );
  SIGNAL Clock2MHz     : STD_LOGIC;
  SIGNAL ClockDiv      : UNSIGNED( 3 DOWNTO 0 );
  
  ------------ FIFO SIGNALS ----------------------
  SIGNAL FIFO_inData   : STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
  SIGNAL FIFO_RdClk    : STD_LOGIC;
  SIGNAL FIFO_RdReq    : STD_LOGIC;
  SIGNAL FIFO_WrClk    : STD_LOGIC;
  SIGNAL FIFO_WrReq    : STD_LOGIC;
  SIGNAL FIFO_outData  : STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
  SIGNAL FIFO_RdEmpty  : STD_LOGIC;
  SIGNAL FIFO_WrFull   : STD_LOGIC;
  SIGNAL FIFO_TxClr    : STD_LOGIC;
  SIGNAL FIFO_RdReqTmp : STD_LOGIC;
  
  SIGNAL Load          : STD_LOGIC;
  
  SIGNAL Clock2MHz_RP  : STD_LOGIC;
  SIGNAL cr1, cr2      : STD_LOGIC;
  SIGNAL Clock2MHz_FP  : STD_LOGIC;
  SIGNAL cf1, cf2      : STD_LOGIC;
  
BEGIN
  
  
  
  tx_fifo: FIFO 
  GENERIC MAP(
    DataWidth  => DataWidth,
    UsedWidth  => FIFO_UsedWidth, 
    WordNum    => FIFO_WordsNum 
  )
  PORT MAP(
    aclr    => FIFO_TxClr,
    data    => FIFO_inData,
    rdclk   => FIFO_RdClk,
    rdreq   => FIFO_RdReq,
    wrclk   => FIFO_WrClk,
    wrreq   => FIFO_WrReq,
    q       => FIFO_outData,
    rdempty => FIFO_RdEmpty,
    wrfull  => FIFO_WrFull
  );
  
  
  
  FIFO_RdClk  <= ClockIn;
  FIFO_Empty  <= FIFO_RdEmpty;
  FIFO_Full   <= FIFO_WrFull;
  FIFO_WrClk  <= ( WriteClk ) AND ( Enable );
  FIFO_WrReq  <= WriteEn AND Enable;
  FIFO_inData <= Data;
  FIFO_TxClr  <= NOT Enable;
  Sleep       <=  NOT Transmission; 
  OutputA     <= Buff( Buff'LEFT )     WHEN Transmission = '1' ELSE '0';
  OutputB     <= NOT Buff( Buff'LEFT ) WHEN Transmission = '1' ELSE '0';
  
  
  
  BusyGen: PROCESS( Enable, ClockIn )
    VARIABLE cnt : INTEGER RANGE 0 TO 15 := 0;
  BEGIN
    
    IF Enable = '0' THEN
      
      Busy <= '0';
      cnt  := 0;
      
    ELSIF RISING_EDGE( ClockIn ) THEN
      
      IF Transmission = '1' THEN
        Busy <= Transmission;
        cnt  := 0;
      ELSIF cnt < 4 THEN 
        cnt := cnt + 1;
      ELSE
        cnt := 0;
        Busy <= Transmission;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  ClockDivider: PROCESS( Enable, ClockIn )
  BEGIN
    
    IF Enable = '0' THEN
      
      ClockDiv     <= ( OTHERS => '0' );
      Clock2MHz    <= '0';
      cr1          <= '0';
      cr2          <= '0';
      cf1          <= '1';
      cf2          <= '1';
      Clock2MHz_RP <= '0';
      Clock2MHz_FP <= '0';
      
    ELSIF RISING_EDGE( ClockIn ) THEN 
      
      IF ClockDiv < x"F" THEN
        ClockDiv <= ClockDiv + x"1";
      ELSE
        ClockDiv <= ( OTHERS => '0' );
      END IF;
      
      Clock2MHz    <= STD_LOGIC( ClockDiv(2) );
      cr1          <= STD_LOGIC( ClockDiv(2) );
      cr2          <= cr1;
      Clock2MHz_RP <= cr1 AND (NOT cr2);
      cf1          <= NOT STD_LOGIC( ClockDiv(2) );
      cf2          <= cf1;
      Clock2MHz_FP <= cf1 AND (NOT cf2);
      
    END IF;
    
  END PROCESS;
  
  
  
  StateSW: PROCESS( Enable, ClockIn )
  BEGIN
    
    IF Enable = '0' THEN
      
      PresState  <= IDLE;
      
    ELSIF RISING_EDGE( ClockIn ) THEN
      
      T1       <= FIFO_RdReq;
      T2       <= T1;
      Transmit <= T2; -- Delay Transmit signal for 2 Cycles
      TxRegOut <= FIFO_outData;
      
      IF Clock2MHz_FP = '1' THEN
        PresState <= NextState;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  StateHandle: PROCESS( Enable, ClockIn )
  BEGIN
    
    IF Enable = '0' THEN
      
      Transmission  <= '0';
      TxInhibit     <= '1'; -- Disable transmitter circuit
      Buff          <= ( OTHERS => '0' );
      bitsCounter   <= ( OTHERS => '0' );
      WordsCounter  <= 0;
      FIFO_RdReqTmp <= '0';
      
    ELSIF RISING_EDGE( ClockIn ) THEN
      
      IF Clock2MHz_RP = '1' THEN
        
        CASE PresState IS
        
        WHEN IDLE =>
          Transmission <= '0';
          TxInhibit    <= '1'; -- Disable transmitter circuit
          Buff         <= ( OTHERS => '0' );  
          bitsCounter  <= ( OTHERS => '0' );
          WordsCounter <= 0;
          FIFO_RdReqTmp   <= '0';
          IF ( FIFO_RdEmpty = '0' ) AND ( Enable = '1' ) THEN
            NextState <= GAP;
          END IF;
        
        WHEN GAP =>
          IF bitsCounter < TO_UNSIGNED( TimeGap * 2 , bitsCounter'LENGTH ) THEN
            bitsCounter <= bitsCounter + x"001";
            TxInhibit   <= '0';  -- Enable transmitter circuit
          ELSE
            NextState   <= START_SYNC;
            Transmission    <= '1';
            bitsCounter <= ( OTHERS => '0' );
            Buff( ( WordWidth - 1 ) DOWNTO ( WordWidth - SeqWidth ) ) <= StartSeqA;
          END IF;
        
        WHEN START_SYNC =>
          IF bitsCounter < TO_UNSIGNED( SeqWidth - 1, bitsCounter'LENGTH ) THEN
            bitsCounter <= bitsCounter + x"001";
            Buff        <= Buff( ( WordWidth - 2 ) DOWNTO 0 ) & '0';  -- Shift out StartSeqA
            IF bitsCounter = TO_UNSIGNED( SeqWidth - 3 , bitsCounter'LENGTH ) THEN -- read FIFO
              FIFO_RdReqTmp <= '1';
            ELSE
              FIFO_RdReqTmp <= '0';
            END IF;
          ELSE
            FOR i IN 0 TO ( DataWidth - 1 ) LOOP
              IF FIFO_outData(i) = '0' THEN
                Buff( i * 2 )         <= '1';
                Buff( ( i * 2 ) + 1 ) <= '0';
              ELSIF FIFO_outData(i) = '1' THEN
                Buff( i * 2 )         <= '0';
                Buff( ( i * 2 ) + 1 ) <= '1';
              END IF;
            END LOOP;
            bitsCounter <= ( OTHERS => '0' );
            NextState   <= SHIFT;
            FIFO_RdReqTmp  <= '0';
          END IF;
        
        WHEN SHIFT =>
          IF bitsCounter < TO_UNSIGNED( WordWidth-1, bitsCounter'LENGTH ) THEN
            bitsCounter <= bitsCounter + x"001";
            Buff        <= Buff( ( WordWidth - 2 ) DOWNTO 0 ) & '0';  -- Shift out StartSeqA
            IF bitsCounter = TO_UNSIGNED( (WordWidth - 3), bitsCounter'LENGTH ) THEN
              IF ( FIFO_RdEmpty = '0' ) AND ( WordsCounter < TxWordsNum - 1 ) THEN
                FIFO_RdReqTmp <= '1';
              END IF;
            ELSE
              FIFO_RdReqTmp <= '0';
            END IF;
          ELSE
            bitsCounter <= ( OTHERS => '0' );
            FIFO_RdReqTmp  <= '0';
            IF WordsCounter < ( TxWordsNum - 1 )  THEN 
              WordsCounter <= WordsCounter + 1;
              FOR i IN 0 TO ( DataWidth - 1 ) LOOP
                IF FIFO_outData(i) = '0' THEN
                  Buff( i * 2 )         <= '1';
                  Buff( ( i * 2 ) + 1 ) <= '0';
                ELSIF FIFO_outData(i) = '1' THEN
                  Buff( i * 2 )         <= '0';
                  Buff( ( i * 2 ) + 1 ) <= '1';
                END IF;
              END LOOP;
            ELSE
              WordsCounter <= 0;
              Buff( ( WordWidth - 1 ) DOWNTO ( WordWidth - SeqWidth ) ) <= StopSeqA; 
              NextState <= STOP_SYNC;
            END IF;
          END IF;
        
        WHEN STOP_SYNC =>
          IF bitsCounter < TO_UNSIGNED( SeqWidth, bitsCounter'LENGTH ) THEN
            Buff        <= Buff( ( WordWidth - 2 ) DOWNTO 0 ) & '0';  -- Shift out StopSeqA
            IF bitsCounter = TO_UNSIGNED( SeqWidth - 1, bitsCounter'LENGTH ) THEN
              Transmission <= '0';
            ELSE
              Transmission <= '1';
            END IF;
            bitsCounter <= bitsCounter + x"001";
          ELSE
            Transmission   <= '0';
            FIFO_RdReqTmp <= '0';
            Buff       <= ( OTHERS => '0' );
            NextState  <= IDLE;
          END IF;
        
        WHEN OTHERS => 
          NextState <= IDLE;
        
        END CASE;
        
      ELSE
        
        IF FIFO_RdReqTmp = '1' THEN
          FIFO_RdReqTmp <= '0';
        END IF;
        
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  FIFO_Access: PROCESS( Enable, ClockIn )
  BEGIN
    
    IF Enable = '0' THEN
      
      FIFO_RdReq <= '0';
      
    ELSIF FALLING_EDGE( ClockIn ) THEN
      
      FIFO_RdReq <= FIFO_RdReqTmp;
      
    END IF;
    
  END PROCESS;
  
  
  
END RTL;
