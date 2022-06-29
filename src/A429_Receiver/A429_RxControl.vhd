-- A429_RxControl v0.3
-- state machine work on Av_clk clock instead Clk 
-- RAM_BUFFER is type of Ring Buffer but RdPtr and WrPtr
-- calculated in external component RingBuffPtr
-- Here just read and write operation implemented

LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

USE work.arinc429rx_pkg.ALL;

ENTITY A429_RxControl IS
  
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
    AddrMask   : OUT STD_LOGIC_VECTOR( ( MASK_ADDR_WIDTH - 1 ) DOWNTO 0 );
    RdMode     : IN  STD_LOGIC; -- 0 = File mode, 1 = address mode
    RxFlag     : IN  STD_LOGIC;
    TestEn     : IN  STD_LOGIC;
    RxSubAddr  : OUT STD_LOGIC_VECTOR(  7 DOWNTO 0 );
    RAMBusy    : IN  STD_LOGIC;
    AddrRol    : IN  STD_LOGIC;
    WrEn       : OUT STD_LOGIC;
    DataOut    : OUT STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
    ByteEn     : OUT STD_LOGIC_VECTOR( ( ( AR429_DATA_WIDTH / 8 ) - 1 ) DOWNTO 0 );
    RAMAddr    : OUT STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
    RxStateReg : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 )
  );
  
END A429_RxControl;

ARCHITECTURE RTL OF A429_RxControl IS
  
  TYPE StateType IS ( IDLE, PHY_RD, PHY_RDEN, CHK_LABEL, MASK_RD, MASK_RD_WAIT, DW_WRITE, TEST );
  
  ATTRIBUTE enum_encoding              : STRING;
  ATTRIBUTE enum_encoding OF StateType : TYPE IS "safe,one-hot";
  
  SIGNAL IntStateReg  : STD_LOGIC_VECTOR(  7 DOWNTO 0 );                        -- Internal state register
  SIGNAL RxWord       : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );  -- receiverd word from RxPhy
  SIGNAL RxLabel      : STD_LOGIC_VECTOR(  7 DOWNTO 0 );
  SIGNAL NextState    : StateType;
  SIGNAL PresState    : StateType;
  SIGNAL RxParityErr  : STD_LOGIC;
  SIGNAL A429_Label   : UNSIGNED( 7 DOWNTO 0 );
  SIGNAL RAM_Full     : STD_LOGIC;
  SIGNAL RAM_Empty    : STD_LOGIC;
  SIGNAL RxWrdOk      : STD_LOGIC;
  SIGNAL TxCntrlErr   : STD_LOGIC;
  SIGNAL WrPtrNxt     : UNSIGNED( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL WrPtr        : UNSIGNED( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL RAM_AlmFull  : STD_LOGIC;
  SIGNAL BuffBusy     : STD_LOGIC;
  SIGNAL WrEnTmp      : STD_LOGIC;
  SIGNAL DataOutTmp   : STD_LOGIC_VECTOR( ( AR429_DATA_WIDTH - 1 ) DOWNTO 0 );
  SIGNAL RAMAddrTmp   : STD_LOGIC_VECTOR( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 );

BEGIN
  
  IntStateReg(7) <= EnableRx;
  IntStateReg(6) <= RAM_Full;
  IntStateReg(5) <= RxWrdOk;
  IntStateReg(4) <= RAM_AlmFull;  -- FIFO almoust full
  IntStateReg(3) <= TxCntrlErr;
  IntStateReg(2) <= RxParityErr;
  IntStateReg(1) <= RAM_Empty;    -- FIFO Buffer empty
  IntStateReg(0) <= '0';          -- reserved
  
  RxStateReg     <= IntStateReg;
  TxCntrlErr     <= TxErr;
  RxParityErr    <= ParErr;
  RxSubAddr      <= STD_LOGIC_VECTOR( A429_Label );
  
  RamBusyCnt: PROCESS( EnableRx, Clk )
    VARIABLE cnt : INTEGER RANGE 0 TO 7 := 0;
  BEGIN
    IF EnableRx = '0' THEN
      cnt      := 0;
      BuffBusy <= '0';
    ELSIF FALLING_EDGE( Clk ) THEN
      IF RAMBusy = '0' THEN
        IF cnt < 7 THEN
          cnt := cnt + 1;
        ELSE
          BuffBusy <= '0';
        END IF;
      ELSE
        BuffBusy <= '1';
        cnt      := 0;
      END IF;
    END IF;
  END PROCESS;
  
  StateSwitcher: PROCESS( EnableRx, Clk )
  BEGIN
    IF EnableRx = '0' THEN
      PresState <= IDLE;
    ELSIF FALLING_EDGE( Clk ) THEN
      PresState <= NextState;
    END IF;
  END PROCESS;
  
  WrEn_GEN: PROCESS( EnableRx, Clk )
  BEGIN
    IF EnableRx = '0' THEN
      WrEn <= '0';
      DataOut <= ( OTHERS => '0' );
      RAMAddr <= ( OTHERS => '0' );
    ELSIF FALLING_EDGE( Clk ) THEN
      WrEn    <= WrEnTmp;
      RAMAddr <= RAMAddrTmp;
      DataOut <= DataOutTmp;
    END IF;
  END PROCESS;
  
  StateHandler: PROCESS( EnableRx, Clk )
    VARIABLE LabelTemp       : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := ( OTHERS => '0' );
    VARIABLE MaskRdWaitCnt   : UNSIGNED( 1 DOWNTO 0 )         := ( OTHERS => '0' );
  BEGIN
    
    IF EnableRx = '0' THEN
      
      MaskRdEn  <= '0';
      WrPtrNxt  <= RXFIFO_OFFSET; 
      WrEnTmp   <= '0';
      NextState <= IDLE;
      
    ELSIF RISING_EDGE( Clk ) THEN
      
      CASE PresState IS
      
      WHEN IDLE =>
        MaskRdWaitCnt := ( OTHERS => '0' );
        WrEnTmp     <= '0';
        RdEn     <= '0';
        MaskRdEn <= '0';
        IF RdMode = RX_ADDR_MODE THEN
          WrPtrNxt <= RXFIFO_OFFSET;
          WrPtr    <= RXFIFO_OFFSET;
        END IF;
        IF ( ( nEmpty = '1' ) AND ( BuffBusy = '0' ) ) THEN 
          NextState <= PHY_RDEN;
        ELSE
          NextState <= IDLE; 
        END IF;
      
      WHEN PHY_RDEN =>
        RdEn      <= '1';
        RxWrdOk   <= '0';
        NextState <= PHY_RD;
      
      WHEN PHY_RD =>  
        RdEn <= '0';
        RxWord      <= RxData;
        IF AddrRol = '0' THEN
          LabelTemp := RxData(0) & RxData(1) & RxData(2) & RxData(3) & RxData(4) & RxData(5) & RxData(6) & RxData(7);
        ELSE
          LabelTemp := RxData( 7 DOWNTO 0 );
        END IF;
        A429_Label <= UNSIGNED( LabelTemp );
        NextState  <=  MASK_RD;
      
      WHEN MASK_RD =>
        MaskRdEn <= '1';
        AddrMask <= '0' & LabelTemp( 7 DOWNTO 5 );  
        NextState <= MASK_RD_WAIT;  
      
      WHEN MASK_RD_WAIT =>
        IF MaskRdWaitCnt < "10" THEN
          MaskRdWaitCnt := MaskRdWaitCnt + "01";
        ELSE
          NextState <= CHK_LABEL;
          MaskRdEn  <= '0';
          MaskRdWaitCnt := ( OTHERS => '0' );
        END IF;
      
      WHEN CHK_LABEL =>
        IF Mask( TO_INTEGER( A429_Label( 4 DOWNTO 0 ) ) ) = '1' THEN
          NextState <= DW_WRITE;
        ELSE
          NextState  <= IDLE;
        END IF;
      
      -- write single ARINC429 word 
      WHEN DW_WRITE =>
        IF RdMode = RX_FIFO_MODE THEN  -- file mode reception
          WrEnTmp                                <= '1';
          DataOutTmp( DataOutTmp'LEFT DOWNTO 8 ) <= RxWord( RxData'LEFT DOWNTO 8 );
          DataOutTmp( 7 DOWNTO 0 )               <= STD_LOGIC_VECTOR( A429_Label );
          RAMAddrTmp                             <= STD_LOGIC_VECTOR( WrPtrNxt );
          WrPtr                                  <= WrPtrNxt;
          ByteEn                                 <= x"F";
          IF WrPtrNxt < RXMAX_ADDR - x"1" THEN
            WrPtrNxt <= WrPtrNxt + x"1";
          ELSE
            WrPtrNxt <= RXFIFO_OFFSET;
          END IF;
          NextState  <= IDLE;
        ELSE   -- address mode reception
          WrEnTmp                                <= '1';
          RAMAddrTmp                             <= x"0" & STD_LOGIC_VECTOR( A429_Label ); -- no address multiplication ( STD_LOGIC_VECTOR( TO_UNSIGNED( 0, RAMAddr'LENGTH ) ) OR STD_LOGIC_VECTOR( A429_Label ) ); -- no address multiplication--
          DataOutTmp( DataOutTmp'LEFT DOWNTO 8 ) <= RxWord( RxData'LEFT DOWNTO 8 );
          DataOutTmp( 7 DOWNTO 0 )               <= STD_LOGIC_VECTOR( A429_Label );
          ByteEn                                 <= x"F";
          NextState                              <= IDLE;
        END IF;
        RxWrdOk   <= '1';
        NextState <= IDLE;
      
      WHEN TEST =>   -- NO TEST mode for Receiver
        NextState <= IDLE;
      
      WHEN OTHERS => 
        NextState <= IDLE;
      
      END CASE;
  
    END IF;
  END PROCESS;
  
END RTL;
