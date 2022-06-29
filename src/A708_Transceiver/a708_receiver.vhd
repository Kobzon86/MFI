-- a708_receiver: ARINC 708 receiver
-- ver 0.5
-- Used ClockIn = 16 MHz
-- Output buffer 16-bit
-- Use output FIFO 16-bit 
-- Use shift register instead of 1600-bits input register
-- Added Error out. Check Media pairs connection.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY a708_receiver IS
  
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
    ReadClk     : IN  STD_LOGIC;  -- 16 MHz
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
  
END a708_receiver;

ARCHITECTURE RTL OF a708_receiver IS
  
  COMPONENT FIFO IS
    GENERIC(
      DataWidth  : INTEGER := 8;
      UsedWidth  : INTEGER := 8; -- 2 ** UsedWidth = WordNum
      WordNum    : INTEGER := 256
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
  
  CONSTANT FIFO_HeadWordsNum : INTEGER := 0;
  CONSTANT AfterWordTime_US  : INTEGER := 25;
  
  CONSTANT DataWidth   : INTEGER := RxWordWidth * RxWordsNum;
  CONSTANT BitSeqWidth : INTEGER := 12;
  CONSTANT StartSeqA1  : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 ) := "011111100000";  --"011111100000";
  CONSTANT StartSeqB1  : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 ) := "000000011111";  --"000000011111";    
  CONSTANT StartSeqA2  : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 ) := "011111000000";  --"011111100000";
  CONSTANT StartSeqB2  : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 ) := "000000111111";  --"000000011111";    
  CONSTANT StopSeqA1   : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 ) := "000000011111";  --"010000011111";
  CONSTANT StopSeqB1   : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 ) := "111111100000";  --"101111100000";    
  CONSTANT StopSeqA2   : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 ) := "000000011111";  --"010000011111";
  CONSTANT StopSeqB2   : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 ) := "111111000000";  --"101111100000";    
  
  TYPE FSM_StateType IS ( IDLE, START_SYNC, SHIFT_IN, STOP_SYNC );
  
  ATTRIBUTE enum_encoding : STRING;
  ATTRIBUTE enum_encoding OF FSM_StateType : TYPE IS "safe,one-hot";
  
  SIGNAL PresState         : FSM_StateType;
  SIGNAL NextState         : FSM_StateType;
  
  SIGNAL DataReady         : STD_LOGIC;
  SIGNAL BitSequenceA      : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 );
  SIGNAL BitSequenceB      : STD_LOGIC_VECTOR( ( BitSeqWidth - 1 ) DOWNTO 0 );

  SIGNAL Buff              : STD_LOGIC_VECTOR( ( RxWordWidth - 1 ) DOWNTO 0 );
  SIGNAL DoubleBitCnt      : UNSIGNED( 5 DOWNTO 0 );
  SIGNAL DoubleBitCntDelay : UNSIGNED( 5 DOWNTO 0 );
  SIGNAL RxWordsCnt        : INTEGER RANGE 0 TO RxWordsNum + 1;

  SIGNAL AB                : STD_LOGIC;
  SIGNAL RxClk             : STD_LOGIC;  -- 4MHz
               
  SIGNAL FIFO_WrReq        : STD_LOGIC;
  SIGNAL FIFO_InData       : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
  SIGNAL FIFO_OutData      : STD_LOGIC_VECTOR( ( RxWordWidth - 1 ) DOWNTO 0 );
  SIGNAL FIFO_WrClk        : STD_LOGIC;
  SIGNAL FIFO_RdClk        : STD_LOGIC;
  SIGNAL FIFO_WrFull       : STD_LOGIC;
  SIGNAL FIFO_RdReq        : STD_LOGIC;
  SIGNAL FIFO_RdEmpty      : STD_LOGIC;
  SIGNAL FIFO_WrEnable     : STD_LOGIC;
  SIGNAL FIFO_Busy         : STD_LOGIC;
  SIGNAL FIFO_WrReqTmp     : STD_LOGIC;
  SIGNAL FIFO_InDataTmp    : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
  
  
  SIGNAL inA1, inA2        : STD_LOGIC;
  SIGNAL inB1, inB2        : STD_LOGIC;
  SIGNAL ClkDivCnt         : UNSIGNED( 3 DOWNTO 0 );
  SIGNAL TxDataReg         : STD_LOGIC_VECTOR( ( RxWordWidth - 1 ) DOWNTO 0 );
  SIGNAL TxDataRegTmp      : STD_LOGIC_VECTOR( ( RxWordWidth - 1 ) DOWNTO 0 );
  SIGNAL BitCnt            : INTEGER RANGE 0 TO RxWordWidth;
  SIGNAL LOC_Ready         : STD_LOGIC;
  SIGNAL StopGAP_Cnt       : INTEGER RANGE 0 TO 127;
  SIGNAL Silence           : STD_LOGIC;
  SIGNAL RxFIFO_Clr        : STD_LOGIC;
  SIGNAL TransmitFall      : STD_LOGIC;
  
  SIGNAL RxClk_RP          : STD_LOGIC;
  SIGNAL cr1, cr2          : STD_LOGIC;
  
  SIGNAL RxClk_FP          : STD_LOGIC;
  SIGNAL cf1, cf2          : STD_LOGIC;
  
BEGIN
  
  
  
  fifo_out: FIFO
  GENERIC MAP(
    DataWidth => 16,
    UsedWidth => 7, -- 2 ** UsedWidth = WordNum
    WordNum   => 128
  )
  PORT MAP(
    aclr    => RxFIFO_Clr,
    data    => FIFO_InData,
    rdclk   => FIFO_RdClk,
    rdreq   => FIFO_RdReq,
    wrclk   => ClockIn,
    wrreq   => FIFO_WrReq,
    q       => FIFO_OutData,
    rdempty => FIFO_RdEmpty,
    wrfull  => FIFO_WrFull
  );
  
  
  
  TransmitFallPulse: pgen 
  GENERIC MAP(
    Edge => '0'
  )
  PORT MAP(
    Enable => Enable,
    Clk    => RxClk,
    Input  => Transmit,
    Output => TransmitFall
  );  
  
  
  
  Strobe      <= Enable;
  FIFO_RdClk  <= ReadClk;
  Empty       <= FIFO_RdEmpty;
  FIFO_RdReq  <= ReadEn;
  DataOut     <= FIFO_OutData;
  
  
  
  inpDoubleBuff: PROCESS( Enable, ClockIn )
  BEGIN
    
    IF Enable = '0' THEN
      
      inA1 <= '0';
      inA2 <= '0';
      inB1 <= '0';
      inB2 <= '0';
      
    ELSIF RISING_EDGE( ClockIn ) THEN
      
      inA1 <= inputA;
      inA2 <= inA1;
      inB1 <= inputB;
      inB2 <= inB1;
      AB   <= ( InA2 OR InB2 );
      
    END IF;
    
  END PROCESS;
  
  
  
  SilenceGen: PROCESS( Enable, ClockIn )
  BEGIN
    
    IF Enable = '0' THEN
      
      StopGAP_Cnt <= 0;
      Silence     <= '1';
      
    ELSIF RISING_EDGE( ClockIn ) THEN
      
      IF ( AB = '1' ) THEN
        StopGAP_Cnt <= 0;
        Silence     <= '0';
      ELSIF StopGAP_Cnt < ( 16 * 2 ) THEN
        StopGAP_Cnt <= StopGAP_Cnt + 1;
      ELSE
        Silence <= '1';
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  ClkDevider: PROCESS( Enable, ClockIn )
  BEGIN
    
    IF Enable = '0' THEN
      
      ClkDivCnt <= ( OTHERS => '0' );
      RxClk       <= '0';
      FIFO_WrClk  <= '0';
      cr1         <= '0';
      cr2         <= '0';
      RxClk_RP    <= '0';
      cf1         <= '1';
      cf2         <= '1';
      RxClk_FP    <= '0';
      
    ELSIF RISING_EDGE( ClockIn ) THEN
      
      RxClk       <= STD_LOGIC( ClkDivCnt(1) ); -- devide 4 times
      FIFO_WrClk  <= STD_LOGIC( ClkDivCnt(1) ); --RxClk;
      cr1         <= STD_LOGIC( ClkDivCnt(1) ); 
      cr2         <= cr1;
      RxClk_RP    <= cr1 AND (NOT cr2);
      cf1         <= NOT STD_LOGIC( ClkDivCnt(1) ); 
      cf2         <= cf1;
      RxClk_FP    <= cf1 AND (NOT cf2);
      
      IF Silence = '0' THEN
        IF ClkDivCnt < TO_UNSIGNED( ( ( 2 ** 3 ) - 1 ), ClkDivCnt'LENGTH ) THEN
          ClkDivCnt <= ClkDivCnt + TO_UNSIGNED( 1, ClkDivCnt'LENGTH );
        ELSE
          ClkDivCnt <= ( OTHERS => '0' );  
        END IF;
      ELSE
        ClkDivCnt <= ( OTHERS => '0' );
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  BuffShiftIn: PROCESS( Enable, Silence, ClockIn )
  BEGIN
    
    IF Enable = '0' OR ( Silence = '1' ) THEN
      
      BitSequenceA <= ( OTHERS => '0' );
      BitSequenceB <= ( OTHERS => '0' );
      
    ELSIF RISING_EDGE( ClockIn ) THEN
      
      IF RxClk_RP = '1' THEN
        BitSequenceA <= BitSequenceA( BitSequenceA'LEFT - 1 DOWNTO 0 ) & InA2;
        BitSequenceB <= BitSequenceB( BitSequenceB'LEFT - 1 DOWNTO 0 ) & InB2;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  StateSW: PROCESS( Enable, Silence, ClockIn )
  BEGIN
    
    IF( ( Enable = '0' ) OR ( Silence = '1' ) ) THEN
      
      PresState <= IDLE;
      Error     <= '0';
      
    ELSIF RISING_EDGE( ClockIn ) THEN
      
      IF Transmit = '1' THEN
        TxDataRegTmp <= TxRegIn;
        Error        <= '0';
      END IF;
      
      IF DoubleBitCnt = TO_UNSIGNED( 32, DoubleBitCnt'LENGTH ) THEN
        TxDataReg <= TxDataRegTmp;
      END IF; 
      
      IF ( TxBusy = '1' ) AND ( DoubleBitCntDelay = TO_UNSIGNED( 63, DoubleBitCntDelay'LENGTH ) ) THEN
        IF TxDataReg = Buff THEN
          Error <= '0';
        ELSE
          Error <= '1';
        END IF;
      END IF;
      
      IF RxClk_RP = '1' THEN
        PresState <= NextState;
        Ready     <= LOC_Ready;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  StateHandle: PROCESS( Silence, ClockIn )
  BEGIN
    
    IF Silence = '1' THEN
      
      FIFO_WrReqTmp     <= '0';
      Rx_Flag           <= '0';
      DoubleBitCnt      <= ( OTHERS => '0' );
      DoubleBitCntDelay <= ( OTHERS => '0' );
      
      IF ( RxWordsCnt > 0 ) AND ( RxWordsCnt < RxWordsNum ) THEN
        RxFIFO_Clr  <= '1';
        RxWordsCnt   <= 0;
      ELSE
        RxFIFO_Clr  <= '0';
      END IF;    
      
      LOC_Ready    <= '0';
      NextState    <= START_SYNC; --IDLE;
      
    ELSIF RISING_EDGE( ClockIn ) THEN
      
      IF RxClk_FP = '1' THEN
        
        DoubleBitCntDelay <= DoubleBitCnt;
        
        CASE PresState IS
        
        WHEN IDLE =>  
          FIFO_WrReqTmp   <= '0';
          Rx_Flag      <= '0';
          DoubleBitCnt <= ( OTHERS => '0' );
          RxWordsCnt   <= 0;
          LOC_Ready    <= '0';
          IF AB = '1' THEN
            NextState <= START_SYNC;
          END IF;
        
        WHEN START_SYNC =>
          RxWordsCnt   <= 0;
          IF( ( BitSequenceA( ( BitSequenceA'LEFT - 1  ) DOWNTO 0 ) = StartSeqA1( ( StartSeqA1'LEFT - 1 ) DOWNTO 0 ) )  OR
            ( BitSequenceA( ( BitSequenceA'LEFT - 1 ) DOWNTO 0 ) = StartSeqA2( ( StartSeqA2'LEFT- 1 ) DOWNTO 0 ) ) ) AND
            ( BitSequenceB( ( BitSequenceB'LEFT - 1 ) DOWNTO 0 ) = StartSeqB1( ( StartSeqB1'LEFT - 1 ) DOWNTO 0 ) OR
            ( BitSequenceB( ( BitSequenceB'LEFT - 1 ) DOWNTO 0 ) = StartSeqB2( ( StartSeqB2'LEFT - 1 ) DOWNTO 0 ) ) ) THEN  
            IF FIFO_RdEmpty = '1' THEN
              NextState <= SHIFT_IN;
            ELSE
              NextState <= STOP_SYNC; -- generate ready for purge RxFIFO   --IDLE;  
            END IF;
          END IF;
        
        WHEN SHIFT_IN =>
          Rx_Flag <= '1';
          IF RxWordsCnt < RxWordsNum THEN
            IF DoubleBitCnt < TO_UNSIGNED( 63, DoubleBitCnt'LENGTH ) THEN
              DoubleBitCnt <= DoubleBitCnt + TO_UNSIGNED( 1, DoubleBitCnt'LENGTH );
              FIFO_WrReqTmp <= '0';
              IF DoubleBitCnt( 1 DOWNTO 0 ) = "11" THEN
                BitCnt <= BitCnt + 1;
                IF ( ( BitSequenceA( 2 DOWNTO 0 ) = "100" ) OR ( BitSequenceA( 1 DOWNTO 0 ) = "10" ) ) THEN
                  Buff( Buff'LEFT - BitCnt ) <= '1';
                ELSIF ( ( BitSequenceA( 2 DOWNTO 0 ) = "011" ) OR ( BitSequenceA( 1 DOWNTO 0 ) = "01" ) ) THEN
                  Buff( Buff'LEFT - BitCnt ) <= '0';
                END IF;
              END IF;
            ELSE
              IF DoubleBitCnt( 1 DOWNTO 0 ) = "11" THEN
                BitCnt <= BitCnt + 1;
                IF ( ( BitSequenceA( 2 DOWNTO 0 ) = "100" ) OR ( BitSequenceA( 1 DOWNTO 0 ) = "10" ) ) THEN
                  Buff( Buff'LEFT - BitCnt ) <= '1';
                ELSIF ( ( BitSequenceA( 2 DOWNTO 0 ) = "011" ) OR ( BitSequenceA( 1 DOWNTO 0 ) = "01" ) ) THEN
                  Buff( Buff'LEFT - BitCnt ) <= '0';
                END IF;
              END IF;
              IF ( ( FIFO_WrFull = '0' ) AND ( TxBusy = '0' ) ) THEN
                FIFO_WrReqTmp  <= '1';
              ELSE
                FIFO_WrReqTmp <= '0';
              END IF;
              DoubleBitCnt <= ( OTHERS => '0' );
              RxWordsCnt   <= RxWordsCnt + 1;
              BitCnt       <= 0;
            END IF;
          ELSE
            NextState  <= STOP_SYNC;
            FIFO_WrReqTmp <= '0';
          END IF;
        
        WHEN STOP_SYNC =>
          FIFO_WrReqTmp <= '0';
          IF ( ( BitSequenceA( ( BitSequenceA'LEFT - 2 ) DOWNTO 0 ) = StopSeqA1( ( StopSeqA1'LEFT - 2 ) DOWNTO 0 ) OR 
             ( BitSequenceA( ( BitSequenceA'LEFT - 2 ) DOWNTO 0 )   = StopSeqA2( ( StopSeqA2'LEFT - 2 ) DOWNTO 0 ) ) )  AND 
             ( ( BitSequenceB( ( BitSequenceB'LEFT - 2 ) DOWNTO 0 ) = StopSeqB1( ( StopSeqB1'LEFT - 2 ) DOWNTO 0 ) ) OR
             ( BitSequenceB( ( BitSequenceB'LEFT - 2 ) DOWNTO 0 )   = StopSeqB2( ( StopSeqB2'LEFT - 2 ) DOWNTO 0 ) ) ) ) THEN
              LOC_Ready     <= '1';
              NextState <= IDLE;
          END IF; 
        
        WHEN OTHERS => 
          NextState <= IDLE;
        
        END CASE;
        
      ELSE
        
        IF FIFO_WrReqTmp = '1' THEN -- generate FIFO_WrReqTmp pulse single ClockIn cycle width
          FIFO_WrReqTmp <= '0';
        END IF;
        
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
  FIFO_access: PROCESS( Enable, ClockIn )  
  BEGIN
    
    IF Enable = '0' THEN
      
      FIFO_WrReq  <= '0';
      FIFO_InData <= ( OTHERS => '0' );
      
    ELSIF FALLING_EDGE( ClockIn ) THEN
      
      IF FIFO_WrReqTmp = '1' THEN
        FIFO_WrReq  <= '1';
        FIFO_InData <= Buff;
      ELSE
        FIFO_WrReq <= '0';
      END IF;
      
    END IF;
    
  END PROCESS;
  
  
  
END RTL;
