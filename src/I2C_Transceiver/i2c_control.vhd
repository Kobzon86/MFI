-- I2C_control ver 1.2
-- Added Lux calculation for light sensors by datasheet formula
-- Lux = 2^(expo) * mant * 0.045
-- expo - 4-bit width
-- mant - 8-bit width
-- 0.045 ~= 11/256 = 0.043 + 4.5% error 
-- So result adapted formula will be
-- Lux = ( 2^(expo) * mant * 11 ) >> 8 );
-- where ">> 8" - right shift for 8 bits
-- added switch brightness mode in DAY/NIGHT by descret input RK1_IN (count from RK0_IN)

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.i2c_pkg.ALL;
USE work.key_codes_pkg.ALL;

LIBRARY lpm;
USE lpm.all;

ENTITY i2c_control IS

  PORT(
    
    Enable       : IN  STD_LOGIC;
    I2C_Clk      : IN  STD_LOGIC;  -- not used here. instead using AvClk divider. AvClk freq = 80 MHz.
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
    I2C_DevAddr  : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
    I2C_RW       : OUT STD_LOGIC;
    I2C_WrData   : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );
    I2C_RdData   : IN  STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );
    I2C_Err      : IN  STD_LOGIC;
    I2C_Busy     : IN  STD_LOGIC;
    Test_DayNight  : OUT STD_LOGIC_VECTOR( 11 DOWNTO 0 );
    Test_Manual    : OUT STD_LOGIC_VECTOR( 11 DOWNTO 0 );
    Test_Sensors   : OUT STD_LOGIC_VECTOR( 11 DOWNTO 0 );
    Test_AnalogExt : OUT STD_LOGIC_VECTOR(  8 DOWNTO 0 );

    ValCode : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    
  );
  
END i2c_control;

ARCHITECTURE RTL OF i2c_control IS
  
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
  
  COMPONENT lpm_mult
    GENERIC (
      lpm_hint           : STRING;
      lpm_representation : STRING;
      lpm_type           : STRING;
      lpm_widtha         : NATURAL;
      lpm_widthb         : NATURAL;
      lpm_widthp         : NATURAL
    );
    PORT (
      dataa  : IN  STD_LOGIC_VECTOR( ( lpm_widtha - 1 ) DOWNTO 0 );
      datab  : IN  STD_LOGIC_VECTOR( ( lpm_widthb - 1 ) DOWNTO 0 );
      result : OUT STD_LOGIC_VECTOR( ( lpm_widthp - 1 ) DOWNTO 0 )
    );
  END COMPONENT;
  
--  TYPE T_I2C_State   IS ( I2C_CONF, IDLE, VAL_RD, LSENSE0_SCAN, LSENSE1_SCAN, KBD_WR, KBD_WAIT, KBD_RD, KBD_SCAN,
--                          KEY_CALC, WRD_GEN, RXBUFF_WR, RXBUFF_WR_WAIT, RD_REQ, RD_WAIT, TXWRD_GEN, EXTLGHT_RD, PWM_ASSIGN, TERMO_RD,
--                          EXTLGHT_DONE, TERMO_RD_DONE, I2C_READDATA, RESET );
--  TYPE T_CfgState    IS ( VALPORT_CFG0, VALPORT_CFG1, KEYPORT_CFG0, KEYPORT_CFG1, LSNS_CFG0, LSNS_CFG1, KBD_CHK, CONF_DONE, RESET );
  TYPE T_I2C_State   IS ( I2C_CONF, IDLE, VAL_RD, LSENSE0_SCAN, LSENSE1_SCAN, KBD_WR, KBD_WAIT, KBD_RD, KBD_SCAN, KBD_CHK,
                          KEY_CALC, WRD_GEN, RXBUFF_WR, RXBUFF_WR_WAIT, RD_REQ, RD_WAIT, TXWRD_GEN, EXTLGHT_RD, PWM_ASSIGN, TERMO_RD,
                          EXTLGHT_DONE, TERMO_RD_DONE, I2C_READDATA, RESET );
  TYPE T_CfgState    IS ( VALPORT_CFG0, VALPORT_CFG1, KEYPORT_CFG0, KEYPORT_CFG1, LSNS_CFG0, LSNS_CFG1, CONF_DONE, RESET );
  TYPE T_I2C_RdState IS ( I2C_WAITBYTE, I2C_RD_BYTE, I2C_RD_DONE, RESET );
  
  ATTRIBUTE enum_encoding                  : STRING;
  ATTRIBUTE enum_encoding OF T_I2C_State   : TYPE IS "safe,one-hot";
  ATTRIBUTE enum_encoding OF T_CfgState    : TYPE IS "safe,one-hot";
  ATTRIBUTE enum_encoding OF T_I2C_RdState : TYPE IS "safe,one-hot";
  
  TYPE keys_col_array IS ARRAY( INTEGER RANGE 0 TO (KEYPRESS_MAX_NUM - 1) ) OF INTEGER RANGE 0 TO KBD_COL_MAX; 
  TYPE keys_row_array IS ARRAY( INTEGER RANGE 0 TO (KEYPRESS_MAX_NUM - 1) ) OF INTEGER RANGE 0 TO KBD_ROW_MAX; 
  
  CONSTANT VAL_CNT_LOW         : UNSIGNED( 3 DOWNTO 0 ) := x"0";
  CONSTANT VAL_CNT_MID         : UNSIGNED( 3 DOWNTO 0 ) := x"7";
  CONSTANT VAL_CNT_MAX         : UNSIGNED( 3 DOWNTO 0 ) := x"F";
  
  CONSTANT LIGHT_SENS_NIGHTMAX : UNSIGNED( 11 DOWNTO 0 ) := x"00F";
  CONSTANT LIGHT_DAY           : UNSIGNED( 11 DOWNTO 0 ) := x"00F"; -- x"07F"
  CONSTANT LIGHT_NIGHT         : UNSIGNED( 11 DOWNTO 0 ) := ( OTHERS => '0' );
  CONSTANT LIGHTNESS_MAX       : STD_LOGIC_VECTOR( 11 DOWNTO 0 ) := x"0FF";
  CONSTANT LUX_MEAN_L          : INTEGER := 8;
  CONSTANT LUX_MEAN_H          : INTEGER := 17;
  CONSTANT LUX_ALL_ONES        : UNSIGNED( (LUX_MEAN_H - LUX_MEAN_L) DOWNTO 0 ) := ( OTHERS => '1' );
  CONSTANT LUX_SAMPLE_NUM      : INTEGER := 4;
  CONSTANT EXT_BRGHT_MINVAL    : UNSIGNED( 15 DOWNTO 0 ) := x"0070";
  
  CONSTANT WD_limit            : integer := 400_000;

  SIGNAL prevState       : T_I2C_State;
  
  SIGNAL Watchdog        : INTEGER RANGE 0 TO ( WD_limit - 1 ) ;
  
  SIGNAL PresState       : T_I2C_State;
  SIGNAL RxDoneState     : T_I2C_State;
  SIGNAL I2C_ReadState   : T_I2C_RdState;
  
  SIGNAL ConfState       : T_CfgState;
  
  SIGNAL RegWrDone       : STD_LOGIC;
  SIGNAL RegRdDone       : STD_LOGIC;
  
  SIGNAL I2C_ByteCnt     : INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
  SIGNAL I2C_PackLen     : INTEGER RANGE 0 TO 63;
  
  SIGNAL StartPulse      : STD_LOGIC;
  SIGNAL ValPulse        : STD_LOGIC;
  SIGNAL I2C_Ena         : STD_LOGIC;
  SIGNAL I2C_BusyPrev    : STD_LOGIC;
  
  ---------- I2C valid flags ------------
  SIGNAL ValidFlagVal    : STD_LOGIC;
  SIGNAL ValidFlagKeys   : STD_LOGIC;
  SIGNAL ValidFlagLS0    : STD_LOGIC;
  SIGNAL ValidFlagLS1    : STD_LOGIC;
  SIGNAL ValidFlagTermo  : STD_LOGIC;
  
  --------- Valcoders States -----------
  SIGNAL ValCurState     : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL ValPrevState    : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL ValChange       : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL ValFirstCheck   : STD_LOGIC;
  
  SIGNAL ValCount0       : SIGNED( 3 DOWNTO 0 );  -- Left_Low
  SIGNAL ValCount1       : SIGNED( 3 DOWNTO 0 );  -- Left_High
  SIGNAL ValCount2       : SIGNED( 3 DOWNTO 0 );  -- Right_low
  SIGNAL ValCount3       : SIGNED( 3 DOWNTO 0 );  -- Right_High
  
  SIGNAL ValBrghtCnt     : UNSIGNED( 7 DOWNTO 0 );
  SIGNAL ValBrght_LOW    : UNSIGNED( 3 DOWNTO 0 );
  SIGNAL ValBrght_HIGH   : UNSIGNED( 3 DOWNTO 0 );
  SIGNAL LowCntFull      : STD_LOGIC;
  SIGNAL HighCntEmpty    : STD_LOGIC;
  
  -------- Light Sensors Signals --------------
  SIGNAL LSense0_HB      : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL LSense0_LB      : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL LSense1_HB      : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL LSense1_LB      : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL LSenseHB_Ready  : STD_LOGIC;
  SIGNAL LSenseLB_Ready  : STD_LOGIC;
  
  SIGNAL Lux             : STD_LOGIC_VECTOR( 27 DOWNTO 0 );
  SIGNAL LuxMean         : UNSIGNED( 27 DOWNTO 0 );
  SIGNAL LuxAcc          : UNSIGNED( 31 DOWNTO 0 );
  
  SIGNAL LuxSampleCnt    : INTEGER RANGE 0 TO 8;  
  SIGNAL Lux0_expo       : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
  SIGNAL Lux0_Mant       : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL Lux_em          : STD_LOGIC_VECTOR( Lux0_expo'LENGTH + Lux0_Mant'LENGTH - 1 DOWNTO 0 );
  
  SIGNAL Lux1_expo       : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
  SIGNAL Lux1_Mant       : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  
  SIGNAL Lux_expo_calc   : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
  SIGNAL Lux_Mant_calc   : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  
  SIGNAL NIOS_Buff_Write : STD_LOGIC;
  
  -------- Keyboard scan signals --------------
  CONSTANT KBD_DELAY     : INTEGER := 8;
  SIGNAL KbdScanCode     : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL KbdCount_H      : INTEGER RANGE 0 TO KBD_ROW_MAX;
  SIGNAL KbdCount_V      : INTEGER RANGE 0 TO KBD_COL_MAX;
  SIGNAL KeyRdRegNum     : INTEGER RANGE 0 TO 1;
  SIGNAL I2C_Key_RdByte  : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL KbdRdCode_V     : STD_LOGIC_VECTOR( ( KBD_COL_MAX - 1 ) DOWNTO 0 );  
  SIGNAL ScreenRes       : STD_LOGIC_VECTOR( 3 DOWNTO 0 );
  SIGNAL KeyPressN       : INTEGER RANGE 0 TO 2;
  SIGNAL P_V, C_V        : keys_col_array;  -- pressed before and current keys col numbers
  SIGNAL P_H, C_H        : keys_row_array;  -- pressed before and current keys row numbers
  SIGNAL KeyPressCode0   : INTEGER RANGE 0 TO 1023;
  SIGNAL KeyPressCode1   : INTEGER RANGE 0 TO 1023;
  SIGNAL KeysPosFound    : STD_LOGIC;
  SIGNAL KeysWaitCnt     : INTEGER;
  
  --------- Words Gen Signals ---------------
  CONSTANT OUT_WORDS_COUNT  : INTEGER := 15;
  SIGNAL WrdCnt             : INTEGER RANGE 0 TO OUT_WORDS_COUNT;
  TYPE   T_OutWords         IS ARRAY( INTEGER RANGE <> ) OF STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  CONSTANT OUT_WORDS_LIST   : T_OutWords( 0 TO ( OUT_WORDS_COUNT - 1 ) ) := (  0 => WORD_0362,
                                                                               1 => WORD_0363,
                                                                               2 => WORD_0364,
                                                                               3 => WORD_0365,
                                                                               4 => WORD_0366,
                                                                               5 => WORD_0367,
                                                                               6 => WORD_0370,
                                                                               7 => WORD_0371,
                                                                               8 => WORD_0372,
                                                                               9 => WORD_0373,
                                                                              10 => WORD_0374,
                                                                              11 => WORD_0375,
                                                                              12 => WORD_0376,
                                                                              13 => WORD_0377,
                                                                              14 => WORD_0357 );
  
  SIGNAL RAM_WrWord      : STD_LOGIC_VECTOR( AVM_DATA_WIDTH-1 DOWNTO 0 );
  SIGNAL Parity          : STD_LOGIC;
  SIGNAL OutWordCode     : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL WrEn_Tmp        : STD_LOGIC;
  
  SIGNAL RamAddr_Tmp     : STD_LOGIC_VECTOR( AVM_ADDR_WIDTH - 1 DOWNTO 0 );
  SIGNAL WordOut_Tmp     : STD_LOGIC_VECTOR( AVM_DATA_WIDTH - 1 DOWNTO 0 );
  SIGNAL ByteEn_Tmp      : STD_LOGIC_VECTOR( ((AVM_DATA_WIDTH / 8) - 1) DOWNTO 0 );
  SIGNAL RamAddr_Tmp2    : STD_LOGIC_VECTOR( AVM_ADDR_WIDTH - 1 DOWNTO 0 );
  SIGNAL WordOut_Tmp2    : STD_LOGIC_VECTOR( AVM_DATA_WIDTH - 1 DOWNTO 0 );
  SIGNAL ByteEn_Tmp2     : STD_LOGIC_VECTOR( ((AVM_DATA_WIDTH / 8) - 1) DOWNTO 0 );

  
  SIGNAL WE0, WE1, WE2   : STD_LOGIC;
  SIGNAL RdEn_Tmp        : STD_LOGIC;
  SIGNAL RE0, RE1, RE2   : STD_LOGIC;
  SIGNAL RC0, RC1, RC2   : STD_LOGIC;
  
  SIGNAL LO_Set0, LO_Set1          : STD_LOGIC;
  SIGNAL LO_Rst0, LO_Rst1, LO_Rst2 : STD_LOGIC;
  SIGNAL AvLoadStretched           : STD_LOGIC;
  SIGNAL AvLoadStretched1          : STD_LOGIC;
  SIGNAL WordIn_Tmp                : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0  );
  SIGNAL WordIn_Tmp1               : STD_LOGIC_VECTOR( ( AVM_DATA_WIDTH - 1 ) DOWNTO 0  );
  
  ------------ I2C TX words -----------------------
  CONSTANT I2C_TXPACK_LEN   : INTEGER := 6; -- number of bytes for MPU_PWR should be transmitted through I2C
  CONSTANT AVM_ACK_WAIT     : INTEGER := 2;
  SIGNAL TxWrdCnt           : INTEGER RANGE 0 TO I2C_TXBUF_LEN;
  SIGNAL WaitTimer          : INTEGER RANGE 0 TO AVM_ACK_WAIT; 
  SIGNAL RAM_RdWord         : STD_LOGIC_VECTOR( AVM_DATA_WIDTH-1 DOWNTO 0 );
  SIGNAL WordID             : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  
  TYPE T_i2c_txarray IS ARRAY ( INTEGER RANGE <> ) OF STD_LOGIC_VECTOR( (I2C_DATA_WIDTH-1) DOWNTO 0 );
  SIGNAL I2C_TxArray : T_i2c_txarray( 0 TO I2C_TXPACK_LEN-1 );
  
  SIGNAL I2C_RxDataLen : INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
  SIGNAL I2C_RxArray   : I2C_Rd_Array;
  SIGNAL RxByteCnt     : INTEGER RANGE 0 TO 15;
  
  ------------- PWM SIGNALS ---------------------
  SIGNAL BTN_PWM     : UNSIGNED( 15 DOWNTO 0 );
  SIGNAL SPIN_PWM    : UNSIGNED( 15 DOWNTO 0 );
  SIGNAL LCD_PWM     : UNSIGNED( 15 DOWNTO 0 );
  
  ----------- Valcoders Signals ---------------
  SIGNAL ValStatePrev0  : UNSIGNED( 3 DOWNTO 0 );
  SIGNAL ValStatePrev1  : UNSIGNED( 3 DOWNTO 0 );
  SIGNAL ValStatePrev2  : UNSIGNED( 3 DOWNTO 0 );
  SIGNAL ValStatePrev3  : UNSIGNED( 3 DOWNTO 0 );
  
  SIGNAL Lightness      : STD_LOGIC_VECTOR( 11 DOWNTO 0 );
  
  SIGNAL Light_DayNight  : UNSIGNED( 11 DOWNTO 0 );
  SIGNAL Light_Manual    : UNSIGNED( 11 DOWNTO 0 );
  SIGNAL Light_Sensors   : UNSIGNED( 11 DOWNTO 0 );
  SIGNAL Light_AnalogExt : UNSIGNED( 8 DOWNTO 0 );
  SIGNAL BrightManAuto   : STD_LOGIC;
  SIGNAL BrightUseAExt   : STD_LOGIC;
  
  SIGNAL BtnBrightPres  : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL SpinBrightPres : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL LCDBrightPres  : STD_LOGIC_VECTOR( 11 DOWNTO 0 );
  SIGNAL RAM_BtnBright  : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL RAM_SpinBright : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  SIGNAL RAM_LCDBright  : STD_LOGIC_VECTOR( 11 DOWNTO 0 );
  
  SIGNAL RxComplete     : STD_LOGIC;
  
  SIGNAL KbdType        : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
  SIGNAL PU_TypeRegVal  : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
  
  SIGNAL DefaultBrightnessSet : STD_LOGIC;
  
  SIGNAL ExtBrightness : UNSIGNED( 15 DOWNTO 0 );
  SIGNAL ExtBrightSamples : INTEGER RANGE 0 TO 8;
  SIGNAL ExtBrightAcc  : UNSIGNED( 18 DOWNTO 0 );
  SIGNAL ExtBrightMean : UNSIGNED( 15 DOWNTO 0 );
  
  SIGNAL pwm_btn_val  : UNSIGNED( 15 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL pwm_spin_val : UNSIGNED( 15 DOWNTO 0 ) := ( OTHERS => '0' );
  SIGNAL pwm_lcd_val  : UNSIGNED( 15 DOWNTO 0 ) := ( OTHERS => '0' );
  
  SIGNAL PWR_Fault_Was : STD_LOGIC;
  SIGNAL PWR_Fault_Cnt : INTEGER RANGE 0 TO 3;  
  SIGNAL PWR_27V_State : STD_LOGIC_VECTOR( 1 DOWNTO 0 ); 
  SIGNAL IndicatorID   : STD_LOGIC_VECTOR( 2 DOWNTO 0 );  
  
  SIGNAL TemperReaded  : STD_LOGIC_VECTOR( 15 DOWNTO 0 );
  
  SIGNAL RD_Waited     : STD_LOGIC;
  
BEGIN
  
  StartPGen : pgen 
  GENERIC MAP (
    Edge => '1'
  ) PORT MAP (
    Enable => Enable,
    Clk    => I2C_Clk,
    Input  => Start,
    Output => StartPulse
  );
  
  
  
  ValPGen : pgen 
  GENERIC MAP (
    Edge => '1'
  ) PORT MAP (
    Enable => Enable,
    Clk    => I2C_Clk,
    Input  => ValCheck,
    Output => ValPulse
  );
  


  ------------- Multiplications for Lux calculation -------------------
  L0_mult_expo_mant : lpm_mult
  GENERIC MAP (
    lpm_hint           => "MAXIMIZE_SPEED=5",
    lpm_representation => "UNSIGNED",
    lpm_type           => "LPM_MULT",
    lpm_widtha         => 16,
    lpm_widthb         => 8,
    lpm_widthp         => 24
  ) PORT MAP (
      dataa  => Lux_expo_calc,
      datab  => Lux_Mant_calc,
      result => Lux_em
  );
  
  L0_mult_x11 : lpm_mult
  GENERIC MAP (
    lpm_hint           => "INPUT_B_IS_CONSTANT=YES,MAXIMIZE_SPEED=5",
    lpm_representation => "UNSIGNED",
    lpm_type           => "LPM_MULT",
    lpm_widtha         => 24,
    lpm_widthb         => 4,
    lpm_widthp         => 28
  ) PORT MAP (
      dataa  => Lux_em,
      datab  => "1011",
      result => Lux
  );
  
  
  
  I2C_Load <= I2C_Ena;
  
  Parity <= ( ( ( ( RAM_WrWord(30) XOR RAM_WrWord(29) ) XOR ( RAM_WrWord(28) XOR RAM_WrWord(27) ) )     XOR
                ( ( RAM_WrWord(26) XOR RAM_WrWord(25) ) XOR ( RAM_WrWord(24) XOR RAM_WrWord(23) ) ) )   XOR 
              ( ( ( RAM_WrWord(22) XOR RAM_WrWord(21) ) XOR ( RAM_WrWord(20) XOR RAM_WrWord(19) ) )     XOR 
                ( ( RAM_WrWord(18) XOR RAM_WrWord(17) ) XOR ( RAM_WrWord(16) XOR RAM_WrWord(29) ) ) ) ) XOR 
            ( ( ( ( RAM_WrWord(14) XOR RAM_WrWord(29) ) XOR ( RAM_WrWord(12) XOR RAM_WrWord(29) ) )     XOR 
                ( ( RAM_WrWord(10) XOR RAM_WrWord(29) ) XOR ( RAM_WrWord(8)  XOR RAM_WrWord(29) ) ) )   XOR
              ( ( ( RAM_WrWord(6)  XOR RAM_WrWord(29) ) XOR ( RAM_WrWord(4)  XOR RAM_WrWord(29) ) )     XOR 
                ( ( RAM_WrWord(2)  XOR RAM_WrWord(29) ) XOR ( RAM_WrWord(0)  XOR '1') ) ) );
  
  
  
  StateHandler: PROCESS( Enable, I2C_Clk )
    CONSTANT odin          : UNSIGNED( 15 DOWNTO 0 ) := "0000000000000001";
    CONSTANT PWM_DAY_MAX   : INTEGER                 := 4096;
    CONSTANT PWM_DAY_MIN   : INTEGER                 := 0;
    CONSTANT PWM_NIGHT_MAX : INTEGER                 := 4096;
    CONSTANT PWM_NIGHT_MIN : INTEGER                 := 0;
    VARIABLE ValChange     : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    VARIABLE ValState0     : UNSIGNED( 3 DOWNTO 0 );
    VARIABLE ValState1     : UNSIGNED( 3 DOWNTO 0 );
    VARIABLE ValState2     : UNSIGNED( 3 DOWNTO 0 );
    VARIABLE ValState3     : UNSIGNED( 3 DOWNTO 0 );
    VARIABLE RotDir0       : STD_LOGIC_VECTOR( 1 DOWNTO 0 ); 
    VARIABLE RotDir1       : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
    VARIABLE RotDir2       : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
    VARIABLE RotDir3       : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
  BEGIN
    
    IF( Enable = '0' ) THEN
      
      I2C_Ena      <= '0';
      RdEn_Tmp     <= '0';
      WrEn_Tmp     <= '0';
      ConfState    <= VALPORT_CFG0;
      I2C_ByteCnt  <= 0;
      RegWrDone    <= '0';
      RegRdDone    <= '0';
      I2C_BusyPrev <= '0';
      
      ValidFlagVal  <= '0';
      ValidFlagKeys <= '0';
      ValidFlagLS0  <= '0';
      ValidFlagLS1  <= '0';
      ValChange     := ( OTHERS => '0' );
      
      ValState0 := ( OTHERS => '0' ); 
      ValState1 := ( OTHERS => '0' );  
      ValState2 := ( OTHERS => '0' );  
      ValState3 := ( OTHERS => '0' );  
      
      ValStatePrev0 <= ( OTHERS => '0' ); 
      ValStatePrev1 <= ( OTHERS => '0' );  
      ValStatePrev2 <= ( OTHERS => '0' );  
      ValStatePrev3 <= ( OTHERS => '0' );  
      
      RotDir0 := ( OTHERS => '0' );
      RotDir1 := ( OTHERS => '0' ); 
      RotDir2 := ( OTHERS => '0' ); 
      RotDir3 := ( OTHERS => '0' ); 
      
      ValCount0 <= ( OTHERS => '0' );  
      ValCount1 <= ( OTHERS => '0' ); 
      ValCount2 <= ( OTHERS => '0' ); 
      ValCount3 <= ( OTHERS => '0' ); 
      
      ValFirstCheck <= '1';    -- Valcoders not checked yet
      
      KbdScanCode <= KSCAN_START_CODE;
      KbdCount_H  <= 0;
      KbdCount_V  <= 0;
      KeyRdRegNum <= 0;
      KeyPressN   <= 0;
      RAM_WrWord  <= ( OTHERS => '0' );
      
      BtnBrightPres  <= BTN_BRGHT_DEFAULT;
      SpinBrightPres <= SPIN_BRGHT_DEFAULT;
      LCDBrightPres  <= LCD_BRGHT_DEFAULT;
      
      TemperReaded <= ( OTHERS => '0' );
      LSenseHB_Ready <= '0';
      LSenseLB_Ready <= '0';
      DefaultBrightnessSet <= '0';
      
      AvLoadStretched <= '0';
      WordIn_Tmp      <= ( OTHERS => '0' );
      
      KbdType <= ( OTHERS => '0' );
      
      Lux0_expo <= ( OTHERS => '0' );
      Lux0_Mant <= ( OTHERS => '0' );
      Lux1_expo <= ( OTHERS => '0' );
      Lux1_Mant <= ( OTHERS => '0' );
      
      LuxSampleCnt <= 0;
      LuxMean      <= ( OTHERS => '0' );
      LuxAcc       <= ( OTHERS => '0' );
      ExtBrightSamples <= 0;
      ExtBrightAcc  <= ( OTHERS => '0' );
      ExtBrightMean <= ( OTHERS => '0' );
      
      PresState     <= RESET;
      prevState     <= RESET;
      Watchdog      <= 0;

      PWR_Fault_Was <= '0';
      PWR_Fault_Cnt <= 0;
      PWR_27V_State <= ( OTHERS => '0' );
      RD_Waited     <= '0';
      ValBrght_LOW  <= VAL_CNT_MID;       --( OTHERS => '1' );
      ValBrght_HIGH <= ( OTHERS => '0' ); --VAL_CNT_MID;
      
      Light_Manual    <= ( OTHERS => '0' );
      Light_Sensors   <= ( OTHERS => '0' );
      Light_AnalogExt <= ( OTHERS => '0' );
      BrightManAuto   <= BRGHT_MODE_AUTO; -- BRGHT_MODE_MANUAL
      BrightUseAExt   <= BRGHT_USE_AEXT;  -- BRGHT_NO_AEXT;
      
    ELSIF( FALLING_EDGE( I2C_Clk ) ) THEN
      
      I2C_BusyPrev <= I2C_Busy;
      
      AvLoadStretched <= AvLoadStretched1;
      WordIn_Tmp      <= WordIn_Tmp1;
      
      ValBrghtCnt     <= ValBrght_HIGH & ValBrght_LOW; 
      
      -------- Lightness modes calculations --------------------
      IF DayNight = '1' THEN
        Light_DayNight <= LIGHT_NIGHT;
        Light_Manual    <= "0000000" & ValBrghtCnt( 3 DOWNTO 0 ) & "0";
        IF BrightManAuto = BRGHT_MODE_AUTO THEN
          IF LuxMean( 20 DOWNTO 9 ) < LIGHT_SENS_NIGHTMAX THEN
            Light_Sensors <= UNSIGNED( LuxMean( 20 DOWNTO 9 ) );
          ELSE
            Light_Sensors <= LIGHT_SENS_NIGHTMAX;
          END IF;
        ELSE
          Light_Sensors <= ( OTHERS => '0' );
        END IF;
      ELSE
        Light_DayNight <= LIGHT_DAY;
        Light_Manual    <= "0000" & ValBrghtCnt( 3 DOWNTO 0 ) & "0000";
        IF BrightManAuto = BRGHT_MODE_AUTO THEN
          Light_Sensors <= UNSIGNED( LuxMean( 20 DOWNTO 9 ) );
        ELSE
          Light_Sensors <= ( OTHERS => '0' );
        END IF;
      END IF;
      
      IF BrightUseAExt = BRGHT_USE_AEXT THEN
        Light_AnalogExt <= ExtBrightMean( 12 DOWNTO 4 );
      ELSE
        Light_AnalogExt <= ( OTHERS => '0' );
      END IF;
      
      Lightness <= STD_LOGIC_VECTOR( Light_DayNight + Light_Manual + Light_Sensors + Light_AnalogExt );
      
      Test_DayNight  <= STD_LOGIC_VECTOR( Light_DayNight  );
      Test_Manual    <= STD_LOGIC_VECTOR( "00000000" & ValBrghtCnt( 3 DOWNTO 0 ) );
      Test_Sensors   <= STD_LOGIC_VECTOR( LuxMean( 20 DOWNTO 9 )   );
      Test_AnalogExt <= STD_LOGIC_VECTOR( ExtBrightMean( 12 DOWNTO 4 ) );
      
      CASE PresState IS

      WHEN I2C_CONF =>
        ValBrght_LOW  <= VAL_CNT_MID;
        ValBrght_HIGH <= ( OTHERS => '0' );
        CASE ConfState IS
        -------- CONFIG I2C_VALPORT ---------
        WHEN VALPORT_CFG0 =>
          IF( RegWrDone = '0' ) THEN
            i2c_reg_wr(  I2C_VALPORT_ADDR,    -- I2C Bus device Address
                         I2CPORT_INREG0_ADDR, -- I2C device internal register address
                         I2CVALPORT_CFGREG0,  -- I2C device register value to be writeed
                         I2C_ByteCnt,         -- Byte Counter
                         I2C_DevAddr,         
                         I2C_RW,              
                         I2C_Ena,             
                         I2C_Busy,            
                         I2C_BusyPrev,        
                         RegWrDone,           
                         I2C_WrData );
          ELSE
            ConfState <= VALPORT_CFG1;
            RegWrDone <= '0';
          END IF; 
        WHEN VALPORT_CFG1 =>
          IF( RegWrDone = '0' ) THEN
            i2c_reg_wr( I2C_VALPORT_ADDR, 
                        I2CPORT_INREG1_ADDR, 
                        I2CVALPORT_CFGREG1,
                        I2C_ByteCnt,  
                        I2C_DevAddr, 
                        I2C_RW,      
                        I2C_Ena,     
                        I2C_Busy,    
                        I2C_BusyPrev,
                        RegWrDone,   
                        I2C_WrData );
          ELSE
            ConfState <= KEYPORT_CFG0;
            RegWrDone <= '0';
          END IF; 
        ------- CONFIG I2C_KEYPORT ---------
        WHEN KEYPORT_CFG0 =>
          IF( RegWrDone = '0' ) THEN
            i2c_reg_wr( I2C_KEYPORT_ADDR, 
                        I2CPORT_CFGREG0_ADDR,
                        I2CKEYPORT_CFGREG0, 
                        I2C_ByteCnt,  
                        I2C_DevAddr, 
                        I2C_RW,      
                        I2C_Ena,     
                        I2C_Busy,    
                        I2C_BusyPrev,
                        RegWrDone,   
                        I2C_WrData );
          ELSE
            ConfState <= KEYPORT_CFG1;
            RegWrDone <= '0';
          END IF;
        WHEN KEYPORT_CFG1 =>
          IF( RegWrDone = '0' ) THEN
            i2c_reg_wr( I2C_KEYPORT_ADDR, 
                        I2CPORT_CFGREG1_ADDR,
                        I2CKEYPORT_CFGREG1, 
                        I2C_ByteCnt,  
                        I2C_DevAddr, 
                        I2C_RW,      
                        I2C_Ena,     
                        I2C_Busy,    
                        I2C_BusyPrev,
                        RegWrDone,   
                        I2C_WrData );
          ELSE
            ConfState <= LSNS_CFG0;
            RegWrDone <= '0';
          END IF;
        ------ CONFIG LSENSE0 -------------
        WHEN LSNS_CFG0 =>
          IF( RegWrDone = '0' ) THEN
            i2c_reg_wr( I2C_LSENSE0_ADDR,  
                        LSENSE_CFGREG_ADDR,
                        LSENSE_CFGREG0, 
                        I2C_ByteCnt,  
                        I2C_DevAddr, 
                        I2C_RW,      
                        I2C_Ena,     
                        I2C_Busy,    
                        I2C_BusyPrev,
                        RegWrDone,   
                        I2C_WrData );
          ELSE
            ConfState <= LSNS_CFG1;
            RegWrDone <= '0';
          END IF;
        -------- CONFIG LSENSE1 ----------
        WHEN LSNS_CFG1 =>
          IF( RegWrDone = '0' ) THEN
            i2c_reg_wr( I2C_LSENSE1_ADDR,  
                        LSENSE_CFGREG_ADDR,
                        LSENSE_CFGREG1, 
                        I2C_ByteCnt,  
                        I2C_DevAddr, 
                        I2C_RW,      
                        I2C_Ena,     
                        I2C_Busy,    
                        I2C_BusyPrev,
                        RegWrDone,   
                        I2C_WrData );
          ELSE
--            ConfState <= KBD_CHK;
            ConfState <= CONF_DONE;
            RegWrDone <= '0';
          END IF;
        ---------- PU type Check ------------
--        WHEN KBD_CHK =>
--          IF( RegRdDone = '0' ) THEN
--            i2c_reg_rd( I2C_VALPORT_ADDR,    -- I2C Bus device Address
--                        I2CPORT_INREG1_ADDR, -- I2C device internal register address
--                        PU_TypeRegVal,       -- I2C device register readed value
--                        I2C_ByteCnt,         -- Byte Counter
--                        I2C_DevAddr,         
--                        I2C_RW,              
--                        I2C_Ena,             
--                        I2C_Busy,            
--                        I2C_BusyPrev,        
--                        RegRdDone,           -- Data Read Ready Flag
--                        I2C_WrData,
--                        I2C_RdData );
--          ELSE    
--            KbdType   <= PU_TypeRegVal( 7 DOWNTO 6 );
--            ConfState <= CONF_DONE;
--            RegRdDone <= '0';
--          END IF;
        WHEN CONF_DONE =>  
          I2C_ByteCnt <= 0;
          IF( I2C_Busy = '0' ) THEN
            PresState <= IDLE;
          END IF;
        WHEN OTHERS =>
          ConfState <= VALPORT_CFG0;
        END CASE;
      
      WHEN IDLE =>
        I2C_Ena        <= '0';
        ValidFlagVal   <= '0';
        ValidFlagKeys  <= '0';
        ValidFlagLS0   <= '0';
        ValidFlagLS1   <= '0';
        ValidFlagTermo <= '0';
        I2C_ByteCnt    <= 0;
        KbdCount_H     <= 0;
        KbdCount_V     <= 0;
        KeyPressN      <= 0;
        KbdScanCode    <= KSCAN_START_CODE;
        KeysPosFound   <= '0';  -- flag for KEY_CALC state
        PWM_Wr         <= '0';
        Lux0_expo      <= ( OTHERS => '0' );
        Lux0_Mant      <= ( OTHERS => '0' );
        Lux1_expo      <= ( OTHERS => '0' );
        Lux1_Mant      <= ( OTHERS => '0' );
        IF( I2C_Busy = '0' ) THEN
          IF( StartPulse = '1' ) THEN
            I2C_RxDataLen <= MPU_PWR_PACK_LEN;
            PresState     <= EXTLGHT_RD; 
          ELSIF ValPulse = '1' THEN
            RegRdDone   <= '0';
            I2C_ByteCnt <= 0;
--            PresState   <= VAL_RD;
            PresState   <= KBD_CHK;
          END IF;
        ELSE
          PresState <= IDLE;
        END IF;
      
      WHEN KBD_CHK =>
        IF( RegRdDone = '0' ) THEN
          i2c_reg_rd( I2C_VALPORT_ADDR,    -- I2C Bus device Address
                      I2CPORT_INREG1_ADDR, -- I2C device internal register address
                      PU_TypeRegVal,       -- I2C device register readed value
                      I2C_ByteCnt,         -- Byte Counter
                      I2C_DevAddr,         
                      I2C_RW,              
                      I2C_Ena,             
                      I2C_Busy,            
                      I2C_BusyPrev,        
                      RegRdDone,           -- Data Read Ready Flag
                      I2C_WrData,
                      I2C_RdData );
          PresState <= KBD_CHK;
        ELSE    
          KbdType   <= PU_TypeRegVal( 7 DOWNTO 6 );
          PresState <= VAL_RD;
          RegRdDone <= '0';
        END IF;
      
      WHEN VAL_RD =>
        IF( RegRdDone = '0' ) THEN    
          i2c_reg_rd( I2C_VALPORT_ADDR,    -- I2C Bus device Address
                      I2CPORT_INREG0_ADDR, -- I2C device internal register address
                      ValCurState,         -- I2C device register readed value
                      I2C_ByteCnt,          -- Byte Counter
                      I2C_DevAddr,         
                      I2C_RW,              
                      I2C_Ena,             
                      I2C_Busy,            
                      I2C_BusyPrev,        
                      RegRdDone,           -- Data Read Ready Flag
                      I2C_WrData,
                      I2C_RdData );
          PresState <= VAL_RD;
        ELSE 
          IF( I2C_Err = '0' ) THEN  -- if I2C register readed successfully
            ValChange    := ValCurState XOR ValPrevState;
            ValidFlagVal <= '1';
            IF( ValFirstCheck = '0' ) THEN
              IF( ValChange( 1 DOWNTO 0 ) /= "00" ) THEN     -- ValCoder0
                Gray2Hex( ValCurState( 1 DOWNTO 0 ), ValState0 );
                RotationDir( ValStatePrev0, ValState0, RotDir0 );
                ValCalc( RotDir0, ValCount0);
                ValStatePrev0 <= ValState0;
                RegRdDone     <= '0';
              ELSIF( ValChange( 3 DOWNTO 2 ) /= "00" ) THEN  -- Valcoder1
                Gray2Hex( ValCurState( 3 DOWNTO 2 ), ValState1 );
                RotationDir( ValStatePrev1, ValState1, RotDir1 );
                ValCalc( RotDir1, ValCount1);
                ValStatePrev1 <= ValState1;
                RegRdDone     <= '0';
              ELSIF( ValChange( 5 DOWNTO 4 ) /= "00" ) THEN  -- Valcoder2
                Gray2Hex( ValCurState( 5 DOWNTO 4 ), ValState2 );
                RotationDir( ValStatePrev2, ValState2, RotDir2 );
                ValCalc( RotDir2, ValCount2);
                ValStatePrev2 <= ValState2;
                RegRdDone     <= '0';
              ELSIF( ValChange( 7 DOWNTO 6 ) /= "00" ) THEN  -- Valcoder3
                Gray2Hex( ValCurState( 7 DOWNTO 6 ), ValState3 );
                RotationDir( ValStatePrev3, ValState3, RotDir3 );
                ValCalc( RotDir3, ValCount3);
                ValStatePrev3 <= ValState3;
                RegRdDone     <= '0';
              ELSE
                ValPrevState  <= ValCurState;
                ValStatePrev0 <= ValState0;
                ValStatePrev1 <= ValState1;
                ValStatePrev2 <= ValState2;
                ValStatePrev3 <= ValState3;
                RegRdDone     <= '0';
              END IF;
            ELSE
              ValPrevState  <= ValCurState;
              ValStatePrev0 <= ValState0;
              ValStatePrev1 <= ValState1;
              ValStatePrev2 <= ValState2;
              ValStatePrev3 <= ValState3;
              ValFirstCheck <= '0';
              RegRdDone     <= '0';
            END IF;
            ValPrevState <= ValCurState;
          ELSE
            ValPrevState <= ValCurState;
            ValStatePrev0 <= ValState0;
            ValStatePrev1 <= ValState1;
            ValStatePrev2 <= ValState2;
            ValStatePrev3 <= ValState3;
            ValidFlagVal <= '0';
            RegRdDone <= '0';
          END IF;    
          PresState <= IDLE;
        END IF;
      
      WHEN EXTLGHT_RD =>
        IF( I2C_BusyPrev = '0' ) THEN
          I2C_DevAddr <= I2C_MPU_PWR_ADDR;
          I2C_RW      <= I2C_RD_BIT;
          I2C_Ena     <= '1';
          RxByteCnt   <= 0;
          I2C_PackLen <= MPU_PWR_PACK_LEN;
          RxDoneState <= EXTLGHT_DONE;
        ELSE
          I2C_ReadState <= I2C_WAITBYTE;
          PresState     <= I2C_READDATA; 
        END IF;
      
      WHEN I2C_READDATA =>
        CASE I2C_ReadState IS
        WHEN I2C_WAITBYTE =>
          IF( RxByteCnt = I2C_PackLen-1 ) THEN
            I2C_Ena <= '0';
          END IF;
          IF( I2C_BusyPrev > I2C_Busy ) THEN
            I2C_RxArray( RxByteCnt ) <= I2C_RdData;
            I2C_ReadState            <= I2C_RD_BYTE;
          ELSE
            I2C_ReadState <= I2C_WAITBYTE;
          END IF;
        WHEN I2C_RD_BYTE =>
          IF( RxByteCnt < I2C_PackLen-1 ) THEN
            RxByteCnt     <= RxByteCnt + 1;
            I2C_ReadState <= I2C_WAITBYTE;
          ELSE
            I2C_Ena       <= '0';
            RxByteCnt     <= 0;
            I2C_ReadState <= I2C_RD_DONE;
          END IF;  
        WHEN I2C_RD_DONE =>
          RxByteCnt <= 0;
          PresState <= RxDoneState;
        WHEN OTHERS => 
          I2C_ReadState <= I2C_WAITBYTE;
        END CASE;
      
      WHEN EXTLGHT_DONE =>
        ExtBrightness(  7 DOWNTO 0 ) <= UNSIGNED( I2C_RxArray(0) );
        ExtBrightness( 15 DOWNTO 8 ) <= UNSIGNED( I2C_RxArray(1) );
        PWR_27V_State                <= I2C_RxArray(2)( 1 DOWNTO 0 );
        Fault_27V                    <= I2C_RxArray(2)( 3 DOWNTO 0 );   
        PresState                    <= LSENSE0_SCAN;
      
      WHEN LSENSE0_SCAN =>
        IF( PWR_27V_State = "11" ) THEN
          IF( PWR_Fault_Cnt < 3 ) THEN
            PWR_Fault_Cnt <= PWR_Fault_Cnt + 1;
            PWR_Fault_Was <= '0';
          ELSE  
            PWR_Fault_Was <= '1';
          END IF;
        ELSE
          IF( PWR_Fault_Cnt > 0 ) THEN
            PWR_Fault_Cnt <= PWR_Fault_Cnt - 1;
          ELSE
            PWR_Fault_Was <= '0';
          END IF;
        END IF;
        IF( LSenseHB_Ready = '0' AND LSenseLB_Ready = '0' )THEN
          i2c_reg_rd( I2C_LSENSE0_ADDR,      -- I2C Bus device Address
                      LSENSE_LUXHBREG_ADDR , -- I2C device internal register address
                      LSense0_HB,            -- I2C device register readed value
                      I2C_ByteCnt,           -- Byte Counter
                      I2C_DevAddr,         
                      I2C_RW,              
                      I2C_Ena,             
                      I2C_Busy,            
                      I2C_BusyPrev,        
                      LSenseHB_Ready,        -- Data Read Ready Flag
                      I2C_WrData,
                      I2C_RdData );
          PresState <= LSENSE0_SCAN;
        ELSIF( LSenseHB_Ready = '1' AND LSenseLB_Ready = '0' ) THEN
          i2c_reg_rd( I2C_LSENSE0_ADDR,      -- I2C Bus device Address
                      LSENSE_LUXLBREG_ADDR , -- I2C device internal register address
                      LSense0_LB,            -- I2C device register readed value
                      I2C_ByteCnt,           -- Byte Counter
                      I2C_DevAddr,         
                      I2C_RW,              
                      I2C_Ena,             
                      I2C_Busy,            
                      I2C_BusyPrev,        
                      LSenseLB_Ready,        -- Data Read Ready Flag
                      I2C_WrData,
                      I2C_RdData );
          PresState <= LSENSE0_SCAN;
        ELSIF( LSenseLB_Ready = '1' ) THEN    
          IF( I2C_Err = '0' ) THEN  -- if I2C register readed successfully
            ValidFlagLS0 <= '1';
            -------- LUX0 Calculation --------------
            Lux0_expo <= STD_LOGIC_VECTOR( shift_left( odin, TO_INTEGER( UNSIGNED(LSense0_HB(7 DOWNTO 4) ) ) ) );
            Lux0_Mant <= LSense0_HB( 3 DOWNTO 0 ) & LSense0_LB( 3 DOWNTO 0 );
            -----------------------------------------------
          ELSE
            ValidFlagLS0 <= '0';
          END IF;
          PresState      <= LSENSE1_SCAN;
          RegRdDone      <= '0';    
          LSenseHB_Ready <= '0';
          LSenseLB_Ready <= '0';
          -------------- ExtLight Average ----------------------
          IF( ExtBrightSamples < LUX_SAMPLE_NUM-1 ) THEN
            ExtBrightSamples <= ExtBrightSamples + 1;
            ExtBrightAcc     <= ExtBrightAcc + ExtBrightness; -- EXT_BRGHT_MINVAL;
          ELSE
            ExtBrightSamples <= 0;
            ExtBrightMean    <= ExtBrightAcc( 17 DOWNTO 2 );
            ExtBrightAcc     <= ( OTHERS => '0' );
          END IF;
          ------------------------------------------------------
        ELSE
          PresState <= LSENSE0_SCAN;
        END IF;
      
      WHEN LSENSE1_SCAN =>
        IF( LSenseHB_Ready = '0' AND LSenseLB_Ready = '0' ) THEN
          i2c_reg_rd( I2C_LSENSE1_ADDR,      -- I2C Bus device Address
                      LSENSE_LUXHBREG_ADDR , -- I2C device internal register address
                      LSense1_HB,            -- I2C device register readed value
                      I2C_ByteCnt,           -- Byte Counter
                      I2C_DevAddr,         
                      I2C_RW,              
                      I2C_Ena,             
                      I2C_Busy,            
                      I2C_BusyPrev,        
                      LSenseHB_Ready,           -- Data Read Ready Flag
                      I2C_WrData,
                      I2C_RdData );
          PresState <= LSENSE1_SCAN;
        ELSIF( LSenseHB_Ready = '1' AND LSenseLB_Ready = '0' ) THEN    
          i2c_reg_rd( I2C_LSENSE1_ADDR,      -- I2C Bus device Address
                      LSENSE_LUXLBREG_ADDR , -- I2C device internal register address
                      LSense1_LB,            -- I2C device register readed value
                      I2C_ByteCnt,           -- Byte Counter
                      I2C_DevAddr,         
                      I2C_RW,              
                      I2C_Ena,             
                      I2C_Busy,            
                      I2C_BusyPrev,        
                      LSenseLB_Ready,           -- Data Read Ready Flag
                      I2C_WrData,
                      I2C_RdData );
          PresState <= LSENSE1_SCAN;
        ELSIF( LSenseLB_Ready = '1' ) THEN
          IF( I2C_Err = '0' ) THEN  -- if I2C register readed successfully
            ValidFlagLS1 <= '1';
            -------- LUX1 Calculation --------------
            Lux1_expo <= STD_LOGIC_VECTOR( shift_left( odin, TO_INTEGER( UNSIGNED(LSense1_HB(7 DOWNTO 4) ) ) ) );
            Lux1_Mant <= LSense1_HB( 3 DOWNTO 0 ) & LSense1_LB( 3 DOWNTO 0 );
            -----------------------------------------------
          ELSE
            ValidFlagLS1 <= '0';
          END IF;    
          IF( DefaultBrightnessSet = '1' ) THEN
            PresState      <= TERMO_RD; 
            RegRdDone      <= '0';
            I2C_ByteCnt    <= 0;
            I2C_RxDataLen  <= TERMO_DATA_LEN;
            LSenseHB_Ready <= '0';
            LSenseLB_Ready <= '0';
          ELSE
            DefaultBrightnessSet <= '1';
            PresState            <=  PWM_ASSIGN;  
          END IF;
        ELSE
          PresState <= LSENSE1_SCAN;
        END IF;
      
      WHEN TERMO_RD =>
        --------- Select Brightest Light sensor ----------------
        IF( Lux0_expo > Lux1_expo ) THEN
          Lux_expo_calc <= Lux0_expo;
          Lux_Mant_calc <= Lux0_Mant;
        ELSIF( Lux0_expo < Lux1_expo ) THEN
          Lux_expo_calc <= Lux1_expo;
          Lux_Mant_calc <= Lux1_Mant;
        ELSE
          IF( Lux0_Mant > Lux1_Mant ) THEN
            Lux_expo_calc <= Lux0_expo;
            Lux_Mant_calc <= Lux0_Mant;
          ELSE
            Lux_expo_calc <= Lux1_expo;
            Lux_Mant_calc <= Lux1_Mant;
          END IF;
        END IF;
        ------- Try to read termo sensor register without reg_address ---------------         
        IF( I2C_BusyPrev = '0' ) THEN
          I2C_DevAddr <= I2C_TERMOSENS_ADDR;
          I2C_RW      <= I2C_RD_BIT;
          I2C_Ena     <= '1';
          I2C_PackLen <= TERMO_DATA_LEN;
          RxByteCnt   <= 0;
          RxDoneState <= TERMO_RD_DONE;
        ELSE
          PresState     <= I2C_READDATA;
          I2C_ReadState <= I2C_WAITBYTE;
        END IF;
      
      WHEN TERMO_RD_DONE =>
        TemperReaded( 15 DOWNTO 8 ) <= I2C_RxArray(0);
        TemperReaded(  7 DOWNTO 0 ) <= I2C_RxArray(1);
        RegRdDone                   <= '0';
        RegWrDone                   <= '0';
        I2C_ByteCnt                 <= 0;
        RxByteCnt                   <= 0;
        ValidFlagTermo              <= '1';
        PresState                   <= KBD_WR;
        IF( LuxSampleCnt < LUX_SAMPLE_NUM-1 ) THEN
          LuxSampleCnt <= LuxSampleCnt + 1;
          LuxAcc       <= LuxAcc + UNSIGNED( Lux );
        ELSE 
          LuxSampleCnt <= 0;
          LuxAcc       <= ( OTHERS => '0' );
        END IF;
      
      WHEN KBD_WR =>
        IF( LuxSampleCnt = LUX_SAMPLE_NUM-1 ) THEN
          LuxMean <= LuxAcc( 29 DOWNTO 2 );
        END IF;
        i2c_reg_wr( I2C_KEYPORT_ADDR,  
                    I2CPORT_OUTREG1_ADDR, --I2CPORT_OUTREG0_ADDR,
                    KbdScanCode, 
                    I2C_ByteCnt,  
                    I2C_DevAddr, 
                    I2C_RW,      
                    I2C_Ena,     
                    I2C_Busy,    
                    I2C_BusyPrev,
                    RegWrDone,   
                    I2C_WrData );
        IF( RegWrDone = '1' ) THEN
          RegWrDone   <= '0';
          I2C_ByteCnt <= 0;
          PresState   <= KBD_WAIT; 
          KeysWaitCnt <= 0;
        ELSE
          PresState <= KBD_WR;
        END IF;
      
      WHEN KBD_WAIT =>
        IF( KeysWaitCnt < KBD_DELAY ) THEN
          KeysWaitCnt <= KeysWaitCnt + 1;
          PresState <= KBD_WAIT;
        ELSE
          KeyRdRegNum <= 0;
          PresState <= KBD_RD;
        END IF;
      
      WHEN KBD_RD =>
        IF( KeyRdRegNum = 0 ) THEN
          i2c_reg_rd( I2C_KEYPORT_ADDR,      -- I2C Bus device Address
                      I2CPORT_INREG0_ADDR,   -- I2C device internal register address
                      I2C_Key_RdByte,        -- I2C device register readed value
                      I2C_ByteCnt,           -- Byte Counter
                      I2C_DevAddr,         
                      I2C_RW,              
                      I2C_Ena,             
                      I2C_Busy,            
                      I2C_BusyPrev,        
                      RegRdDone,           -- Data Read Ready Flag
                      I2C_WrData,
                      I2C_RdData );
          IF( RegRdDone = '1' ) THEN
            IF( I2C_Err = '0' ) THEN
              ValidFlagKeys <= '1';
            ELSE
              ValidFlagKeys <= '0';
            END IF;
            KbdRdCode_V( ( KBD_COL_MAX - 1 ) DOWNTO ( KBD_COL_MAX - KBD_ROW_MAX ) ) <= I2C_Key_RdByte( ( KBD_COL_MAX - KBD_ROW_MAX + 1 ) DOWNTO 0 );
            KeyRdRegNum <= KeyRdRegNum + 1;
            RegRdDone   <= '0';
          END IF;
        ELSE
          i2c_reg_rd( I2C_KEYPORT_ADDR,      -- I2C Bus device Address
                      I2CPORT_INREG1_ADDR,   -- I2C device internal register address
                      I2C_Key_RdByte,        -- I2C device register readed value
                      I2C_ByteCnt,           -- Byte Counter
                      I2C_DevAddr,         
                      I2C_RW,              
                      I2C_Ena,             
                      I2C_Busy,            
                      I2C_BusyPrev,        
                      RegRdDone,           -- Data Read Ready Flag
                      I2C_WrData,
                      I2C_RdData );
          IF( RegRdDone = '1' ) THEN
            KbdRdCode_V( 2 ) <= I2C_Key_RdByte( 0 );
            KbdRdCode_V( 1 ) <= I2C_Key_RdByte( 1 );
            KbdRdCode_V( 0 ) <= I2C_Key_RdByte( 2 );
            RegRdDone        <= '0';
            PresState        <= KBD_SCAN;
          ELSE
            PresState        <= KBD_RD;
          END IF;
        END IF;
      
      WHEN KBD_SCAN =>
        IF( KbdCount_H < KBD_ROW_MAX ) THEN
          IF( KbdCount_V < KBD_COL_MAX ) THEN
            IF( KbdRdCode_V( 0 ) = '0' ) THEN  -- if was key pressed
              IF( KeyPressN < KEYPRESS_MAX_NUM ) THEN
                C_H( KeyPressN ) <= KbdCount_H;
                C_V( KeyPressN ) <= KbdCount_V;
                KeyPressN        <= KeyPressN + 1;
              ELSE
                PresState <= KEY_CALC;
              END IF;
            END IF;
            KbdRdCode_V <= '1' & KbdRdCode_V( KbdRdCode_V'LEFT DOWNTO 1 );
            KbdCount_V  <= KbdCount_V + 1;
          ELSE
            KbdCount_H  <= KbdCount_H + 1;
            KbdScanCode <= '1' & KbdScanCode( KbdScanCode'LEFT DOWNTO 1 );
            KbdCount_V  <= 0;
            PresState   <= KBD_WR;
          END IF;
        ELSE
          PresState <= KEY_CALC;
        END IF;
      
      WHEN KEY_CALC =>
        IF( KeysPosFound = '0' ) THEN 
          IF( KeyPressN > 0 ) THEN     -- if keys pressed
            IF( KeyPressN = 1 ) THEN  -- if pressed 1 key
              P_H(0) <= C_H(0);
              P_V(0) <= C_V(0);
              P_H(1) <= KBD_ROW_MAX;
              P_V(1) <= KBD_COL_MAX;
            ELSE                   -- if pressed 2 keys
              IF( ( P_H(0) = C_H(0) ) AND ( P_V(0) = C_V(0) ) ) THEN
                P_H(1) <= C_H(1);
                P_V(1) <= C_V(1);
              ELSIF( ( P_H(0) = C_H(1) ) AND ( P_V(0) = C_V(1) ) ) THEN
                P_H(1) <= C_H(0);
                P_V(1) <= C_V(0);
              ELSIF( ( P_H(1) = C_H(0) ) AND ( P_V(1) = C_V(0) )  ) THEN
                P_H(0) <= C_H(0);
                P_V(0) <= C_V(0);
                P_H(1) <= C_H(1);
                P_V(1) <= C_V(1);
              ELSIF( ( P_H(1) = C_H(1) ) AND ( P_V(1) = C_V(1) ) ) THEN 
                P_H(0) <= C_H(1);
                P_V(0) <= C_V(1);
                P_H(1) <= C_H(0);
                P_V(1) <= C_V(0);
              ELSE
                P_H(0) <= C_H(0);
                P_V(0) <= C_V(0);
                P_H(1) <= C_H(1);
                P_V(1) <= C_V(1);
              END IF;
            END IF;
          ELSE                       -- if no keys pressed
            P_H(0) <= KBD_ROW_MAX;
            P_H(1) <= KBD_ROW_MAX;
            P_V(0) <= KBD_COL_MAX;
            P_V(1) <= KBD_COL_MAX;
          END IF;
          KeysPosFound <= '1';   -- keys positions found
          PresState    <= KEY_CALC;
        ELSE  -- calculate keys codes from keys positions 
          CASE KbdType IS
          WHEN KBD_10INCH =>
            KeyPressCode0 <= keyboard_codes10( P_H(0), P_V(0) );
            KeyPressCode1 <= keyboard_codes10( P_H(1), P_V(1) );
            nOUT31_EN     <= "01"; -- 10" LCD Led driver
            IndicatorID   <= IND_MFI2_10;
            ScreenRes     <= RES_1024x768;
          WHEN KBD_12INCH =>
            KeyPressCode0 <= keyboard_codes12( P_H(0), P_V(0) );
            KeyPressCode1 <= keyboard_codes12( P_H(1), P_V(1) );
            nOUT31_EN     <= ( OTHERS => '0' ); -- 12" LCD Led driver
            IndicatorID   <= IND_MFI2_12;
            ScreenRes     <= RES_1024x768;
          WHEN KBD_15INCH =>
            KeyPressCode0 <= keyboard_codes15( P_H(0), P_V(0) );
            KeyPressCode1 <= keyboard_codes15( P_H(1), P_V(1) );
            nOUT31_EN     <= "10"; -- 15" LCD Led driver
            IndicatorID   <= IND_MFI2_15;
            ScreenRes     <= RES_1920x1080;
          WHEN OTHERS => -- default 12 inch LCD and keys
            KeyPressCode0 <= keyboard_codes12( P_H(0), P_V(0) );
            KeyPressCode1 <= keyboard_codes12( P_H(1), P_V(1) );
            nOUT31_EN     <= ( OTHERS => '0' ); -- 12" LCD Led driver
            IndicatorID   <= IND_MFI2_12;
            ScreenRes     <= RES_1024x768;
          END CASE;
          LCD_Size_Code <= KbdType;
          WrdCnt        <= 0;
          RAM_WrWord    <= ( OTHERS => '0' );
          PresState     <= WRD_GEN;
          OutWordCode   <= OUT_WORDS_LIST( 0 );
        END IF;
      
      WHEN WRD_GEN =>
        WrEn_Tmp <= '0';
        CASE OutWordCode IS
        WHEN WORD_0360 =>
          RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          RAM_WrWord( 28 DOWNTO 10 ) <= ( OTHERS => '0' );
        WHEN WORD_0361 =>
          RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          RAM_WrWord( 28 DOWNTO 10 ) <= ( OTHERS => '0' );
        WHEN WORD_0362 =>
          RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          RAM_WrWord( 28 DOWNTO 18 ) <= "00000000000";
          RAM_WrWord( 17 DOWNTO 10 ) <= RAM_BtnBright; --BtnBrightPres;
        WHEN WORD_0363 =>
          RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          RAM_WrWord( 28 DOWNTO 22 ) <= "0000000";
          RAM_WrWord( 21 DOWNTO 10 ) <=  RAM_LCDBright; --LCDBrightPres;
        WHEN WORD_0364 =>
          IF( ValidFlagTermo = '1' ) THEN
            IF( TemperReaded( 15 ) = '0' ) THEN
              RAM_WrWord( 30 DOWNTO 29 ) <= "00";
              RAM_WrWord( 28 DOWNTO 22 ) <= TemperReaded( 14 DOWNTO 8 );
            ELSE
              RAM_WrWord( 30 DOWNTO 29 ) <= "11";
              RAM_WrWord( 28 DOWNTO 22 ) <= STD_LOGIC_VECTOR( UNSIGNED( NOT ( TemperReaded( 14 DOWNTO 8 ) ) ) + "0000001" ); --TO_UNSIGNED( 1, 7 ) );
            END IF;
            ValidFlagTermo <= '0';
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
            RAM_WrWord( 28 DOWNTO 22 ) <=( OTHERS => '0' );
          END IF;
          RAM_WrWord( 21 DOWNTO 10 ) <=  STD_LOGIC_VECTOR( Light_Sensors );
        WHEN WORD_0365 =>
          RAM_WrWord( 28 DOWNTO 21 ) <= x"00";--Signal_Reboot_Src;
          RAM_WrWord( 20 DOWNTO 18 ) <= IndicatorID;  --"000";  -- LCD_Size_Code
          RAM_WrWord( 17 DOWNTO 14 ) <= ScreenRes;  --"0011"; --Signal_Tft_Type; 1024x768
          RAM_WrWord( 13 )           <= '1';  --Signal_Cyr_nLat; Cyrilic = '1', Latin = '0'
          RAM_WrWord( 12 )           <= '0';  --Signal_NightVision;
          RAM_WrWord( 11 )           <= '0';  --Signal_Reprog;
          RAM_WrWord( 10 )           <= '1';  --Signal_Brightness4K; Brightness Range = (0 - 4095)
        WHEN WORD_0366 =>
          RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          RAM_WrWord( 28 DOWNTO 10 ) <= ( OTHERS => '0' );
        WHEN WORD_0367 =>
          IF( ValidFlagVal = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          RAM_WrWord( 28 DOWNTO 26 ) <= "000";
          RAM_WrWord( 25 DOWNTO 22 ) <= STD_LOGIC_VECTOR( ValCount1 );--Signal_EncLeftUp;
          RAM_WrWord( 21 DOWNTO 18 ) <= STD_LOGIC_VECTOR( ValCount0 );--Signal_EncLeftDown;
          RAM_WrWord( 17 DOWNTO 14 ) <= STD_LOGIC_VECTOR( ValCount3 );--Signal_EncRightUp;
          RAM_WrWord( 13 DOWNTO 10 ) <= STD_LOGIC_VECTOR( ValCount2 );--Signal_EncRightDown;
        WHEN WORD_0370 =>
          IF( ValidFlagKeys = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          IF( ( KeyPressCode0 >= WORD_0370_CODE_START ) AND ( KeyPressCode0 <= WORD_0370_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode0 - ( WORD_0370_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
          IF( ( KeyPressCode1 >= WORD_0370_CODE_START ) AND ( KeyPressCode1 <= WORD_0370_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode1 - ( WORD_0370_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
          --------- Valcoder Brightness Counter calculation ----------------
          IF ValCount0 >= x"0" THEN
            IF ValBrghtCnt < x"0F" THEN
              IF ValBrght_LOW < VAL_CNT_MAX - UNSIGNED( ValCount0 )  THEN
                ValBrght_LOW <= ValBrght_LOW + UNSIGNED( ValCount0 );
              ELSE
                ValBrght_LOW <= VAL_CNT_MAX;
              END IF;
            END IF;
          ELSE
            IF ValBrghtCnt <= x"0F" THEN
              IF ValBrght_LOW > ( NOT( UNSIGNED( ValCount0 ) ) + x"1")  THEN
                ValBrght_LOW <= ValBrght_LOW - ( NOT( UNSIGNED( ValCount0 ) ) + x"1");
              ELSE
                ValBrght_LOW <= x"1"; --( OTHERS => '0' );
              END IF;
            END IF;
          END IF;  
        WHEN WORD_0371 =>
          IF( ValidFlagKeys = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          IF( ( KeyPressCode0 >= WORD_0371_CODE_START ) AND ( KeyPressCode0 <= WORD_0371_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode0 - ( WORD_0371_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
          IF( ( KeyPressCode1 >= WORD_0371_CODE_START ) AND ( KeyPressCode1 <= WORD_0371_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode1 - ( WORD_0371_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
        WHEN WORD_0372 =>
          IF( ValidFlagKeys = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          RAM_WrWord( 28 DOWNTO 10 ) <= ( OTHERS => '0' );
        WHEN WORD_0373 =>
          IF( ValidFlagKeys = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          IF( ( KeyPressCode0 >= WORD_0373_CODE_START ) AND ( KeyPressCode0 <= WORD_0373_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode0 - ( WORD_0373_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
          IF( ( KeyPressCode1 >= WORD_0373_CODE_START ) AND ( KeyPressCode1 <= WORD_0373_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode1 - ( WORD_0373_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
        WHEN WORD_0374 =>
          IF( ValidFlagKeys = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          IF( ( KeyPressCode0 >= WORD_0374_CODE_START ) AND ( KeyPressCode0 <= WORD_0374_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode0 - ( WORD_0374_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
          IF( ( KeyPressCode1 >= WORD_0374_CODE_START ) AND ( KeyPressCode1 <= WORD_0374_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode1 - ( WORD_0374_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
        WHEN WORD_0375 =>
          IF( ValidFlagKeys = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          RAM_WrWord( 28 DOWNTO 10 ) <= ( OTHERS => '0' );
        WHEN WORD_0376 =>
          IF( ValidFlagKeys = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          RAM_WrWord( 28 DOWNTO 10 ) <= ( OTHERS => '0' );
        WHEN WORD_0377 =>
          IF( ValidFlagKeys = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          RAM_WrWord( 28 DOWNTO 10 ) <= ( OTHERS => '0' );
        WHEN WORD_0357 =>
          IF( ValidFlagKeys = '1' ) THEN
            RAM_WrWord( 30 DOWNTO 29 ) <= "00";
          ELSE
            RAM_WrWord( 30 DOWNTO 29 ) <= "01";
          END IF;
          IF( ( KeyPressCode0 >= WORD_0357_CODE_START ) AND ( KeyPressCode0 <= WORD_0357_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode0 - ( WORD_0357_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
          IF( ( KeyPressCode1 >= WORD_0357_CODE_START ) AND ( KeyPressCode1 <= WORD_0357_CODE_STOP ) ) THEN
            FOR I IN 10 TO 28 LOOP
              IF( I = ( KeyPressCode1 - ( WORD_0357_CODE_START - 10 ) ) ) THEN
                RAM_WrWord( I ) <= RAM_WrWord( I ) OR '1';
              END IF;
            END LOOP;
          END IF;
        WHEN OTHERS => 
          RAM_WrWord( 30 DOWNTO 10 ) <= ( OTHERS => 'U' );
        END CASE;
        RAM_WrWord( 7 DOWNTO 0 ) <= OutWordCode;
        PresState <= RXBUFF_WR;
      
      WHEN RXBUFF_WR =>
        RD_Waited <= '0';
        IF( RAM_Busy = '0' ) THEN
          IF( WrdCnt < OUT_WORDS_COUNT ) THEN
            IF( NIOS_Buff_Write = '0' ) THEN
              RamAddr_Tmp     <= STD_LOGIC_VECTOR( TO_UNSIGNED( WrdCnt, AVM_ADDR_WIDTH ) );
              WrEn_Tmp        <= '1';  
              PresState       <= RXBUFF_WR_WAIT;
            ELSE
              RamAddr_Tmp <= STD_LOGIC_VECTOR( TO_UNSIGNED( ( I2C_NIOS_BUFF_STARTADDR + WrdCnt ), AVM_ADDR_WIDTH ) );
              WrEn_Tmp    <= '1';  
              PresState   <= RXBUFF_WR_WAIT; 
            END IF;
            WordOut_Tmp( 30 DOWNTO 0 ) <= RAM_WrWord( 30 DOWNTO 0 );
            WordOut_Tmp( 31 ) <= Parity; 
            ByteEn_Tmp      <= ( OTHERS => '1' );
            ------ Clear Valcoders Counters -------------
            IF( OutWordCode  = WORD_0370 ) THEN
              ValCount0 <= ( OTHERS => '0' );  --x"08";
              ValCount1 <= ( OTHERS => '0' );  --x"08";
              ValCount2 <= ( OTHERS => '0' );  --x"08";
              ValCount3 <= ( OTHERS => '0' );  --x"08";
            END IF;
          ELSE
            TxWrdCnt <= 0;
            RxComplete <= '1';
            PresState <= RD_REQ; 
            WrdCnt <= 0;
          END IF;
        ELSE
          PresState <= RXBUFF_WR;
        END IF;
      
      WHEN RXBUFF_WR_WAIT =>        
        WrEn_Tmp <= '0';
        IF( RD_Waited = '1' ) THEN        
          IF( NIOS_Buff_Write = '0' ) THEN
            NIOS_Buff_Write <= '1';
            PresState       <= RXBUFF_WR;
          ELSE
            NIOS_Buff_Write <= '0';
            OutWordCode     <= OUT_WORDS_LIST( WrdCnt+1 );
            WrdCnt          <= WrdCnt + 1;
            RAM_WrWord      <= ( OTHERS => '0' );
            PresState       <= WRD_GEN;
          END IF;
        ELSE
          RD_Waited <= '1';
        END IF;
      
      WHEN RD_REQ =>
        RxComplete <= '0';
        IF( RAM_Busy = '0' ) THEN
          IF( TxWrdCnt < I2C_TXBUF_LEN ) THEN
            TxWrdCnt  <= TxWrdCnt + 1;
            RdEn_Tmp  <= '1';
            RamAddr_Tmp   <= STD_LOGIC_VECTOR( TO_UNSIGNED( ( TXBUFF_STARTADDR + ( TxWrdCnt ) ), AVM_ADDR_WIDTH ) );  
            ByteEn_Tmp    <= ( OTHERS => '1' );
            WaitTimer <= AVM_ACK_WAIT;
            PresState <= RD_WAIT;
          ELSE
            PresState <= IDLE;
          END IF;
        ELSE
          PresState <= RD_REQ;
        END IF;
      
      WHEN RD_WAIT =>
        RdEn_Tmp <= '0';
        IF( AvLoadStretched = '1' ) THEN
          RAM_RdWord  <= WordIn_Tmp;
          PresState   <= TXWRD_GEN;
        ELSE
          IF( WaitTimer = 0 ) THEN
            PresState <= IDLE;
          ELSE
            WaitTimer <= WaitTimer - 1;
            PresState <= RD_WAIT;
          END IF;
        END IF;
      
      WHEN TXWRD_GEN =>
        IF( RAM_RdWord( 30 DOWNTO 29 ) = "00" ) THEN
          CASE RAM_RdWord( 7 DOWNTO 0 ) IS 
          WHEN WORD_0362 =>  -- button brightness to MPU_PWR
            RAM_BtnBright  <= RAM_RdWord( 17 DOWNTO 10 );
            RAM_SpinBright <= RAM_RdWord( 17 DOWNTO 10 );
          WHEN WORD_0363 => -- LCD-matrix brightness to MPU_PWR
            RAM_LCDBright  <= RAM_RdWord( 21 DOWNTO 10 );
          WHEN OTHERS =>
            NULL;
          END CASE;
          IF( TxWrdCnt < I2C_TXBUF_LEN ) THEN
            PresState <= RD_REQ;
          ELSE
            IF( Lightness < LIGHTNESS_MAX ) THEN
              BtnBrightPres  <= STD_LOGIC_VECTOR( Lightness( 7 DOWNTO 0 ) );
              SpinBrightPres <= STD_LOGIC_VECTOR( Lightness( 7 DOWNTO 0 ) );
              LCDBrightPres  <= STD_LOGIC_VECTOR( Lightness( 7 DOWNTO 0 ) ) & "0000";
            ELSE
              BtnBrightPres  <= STD_LOGIC_VECTOR( LIGHTNESS_MAX( 7 DOWNTO 0 ) );
              SpinBrightPres <= STD_LOGIC_VECTOR( LIGHTNESS_MAX( 7 DOWNTO 0 ) );
              LCDBrightPres  <= STD_LOGIC_VECTOR( LIGHTNESS_MAX( 7 DOWNTO 0 ) ) & "0000";
            END IF;
            PresState <= PWM_ASSIGN; 
          END IF;
        ELSE
          IF( TxWrdCnt < I2C_TXBUF_LEN ) THEN
            PresState <= RD_REQ;
          ELSE
            PresState <= IDLE;
          END IF;
        END IF;
      
      WHEN PWM_ASSIGN =>
        PWM_Wr <= '1';
        IF( PWM_nFault = '1' AND PWR_Fault_Was = '0' ) THEN
          CASE KbdType IS
          WHEN KBD_10INCH =>
            PWM_EN1 <= '0';
            PWM_EN2 <= '1';
          WHEN KBD_12INCH =>
            PWM_EN1 <= '1';
            PWM_EN2 <= '0';
          WHEN KBD_15INCH =>
            PWM_EN1 <= '1';
            PWM_EN2 <= '1';
          WHEN OTHERS => -- LCD not defined. Backlight turned-OFF
            PWM_EN1 <= '0';
            PWM_EN2 <= '0';
          END CASE;
          PWM_BTN  <= x"0" & BtnBrightPres & x"0";   -- allign to the LSB
          PWM_SPIN <= "00000000" & SpinBrightPres;  -- allign to the LSB
          PWM_LCD  <= "000" & LCDBrightPres & '0'; 
        ELSE
          PWM_EN1  <= '0';
          PWM_EN2  <= '0';
          PWM_BTN  <= ( OTHERS => '0' );
          PWM_SPIN <= ( OTHERS => '0' );
          PWM_LCD  <= ( OTHERS => '0' );
        END IF;
        PresState <= IDLE;
      WHEN OTHERS => 
        PresState <= I2C_CONF;  --RST;
      END CASE;
      
      IF( prevState /= PresState ) THEN
        Watchdog <= 0;
      ELSIF( watchdog < ( WD_limit - 1 ) ) THEN
        Watchdog <= Watchdog + 1;
      ELSE
      	Watchdog  <= 0;  
        PresState <= IDLE;
      END IF;    
      
      prevState <= PresState;
      
    END IF;
    
  END PROCESS;
  
  
  
  AvmWrRdPulseGen: PROCESS( Enable, AvClk )
  BEGIN

    IF( Enable = '0' ) THEN

      WrEn             <= '0';
      WE0              <= '0';
      WE1              <= '0';
      WE2              <= '0';
      RdEn             <= '0';
      RE0              <= '0';
      RE1              <= '0';
      RE2              <= '0';
      RC0              <= '0';
      RC1              <= '0';
      RC2              <= '0';
      LO_Set0          <= '0';
      LO_Set1          <= '0';
      LO_Rst0          <= '0';
      LO_Rst1          <= '0';
      LO_Rst2          <= '0';
      AvLoadStretched1 <= '0';
      WordIn_Tmp1      <= (  OTHERS => '0' );
      RamAddr_Tmp2     <= ( OTHERS => '0' );
      WordOut_Tmp2     <= ( OTHERS => '0' );
      ByteEn_Tmp2      <= ( OTHERS => '0' );
      RamAddr          <= ( OTHERS => '0' );
      WordOut          <= ( OTHERS => '0' );
      ByteEn           <= ( OTHERS => '0' );
      
    ELSIF FALLING_EDGE( AvClk ) THEN
      
      IF( AvLoad = '1' ) THEN
        WordIn_Tmp1 <= WordIn;
        LO_Set0     <= '1';
      ELSE
        LO_Set0 <= '0';
      END IF;
      
      LO_Set1 <= LO_Set0;
      LO_Rst0 <= NOT I2C_Clk;
      LO_Rst1 <= LO_Rst0;
      
      IF( ( LO_Set0 AND ( NOT LO_Set1 ) ) = '1' ) THEN
        LO_Rst2 <= '1';
      ELSIF( ( LO_Rst0 AND ( NOT LO_Rst1 ) )  = '1' ) THEN
        LO_Rst2 <= '0';
      END IF; 
      
      AvLoadStretched1 <= LO_Rst2;
      
      WE0  <= WrEn_Tmp;
      WE1  <= WE0;
      WE2  <= WE0 AND ( NOT WE1 ); -- pulse 1 cycle width WrEn gen
      WrEn <= WE2;
      
      RE0  <= RdEn_Tmp;
      RE1  <= RE0;
      RdEn <= RE0 AND ( NOT RE1 ); -- 1 pulse cycle width RdEn gen
      
      RamAddr_Tmp2 <= RamAddr_Tmp;
      WordOut_Tmp2 <= WordOut_Tmp;
      ByteEn_Tmp2  <= ByteEn_Tmp;
      
      
      RamAddr <= RamAddr_Tmp2;
      WordOut <= WordOut_Tmp2;
      ByteEn  <= ByteEn_Tmp2;
      
      RC0          <= RxComplete;
      RC1          <= RC0;
      RC2          <= RC0 AND ( NOT RC1 );  -- 1 pulse cycle DataReceived signal 
      DataReceived <= RC2; 
      
    END IF;

  END PROCESS;
  
  ValCode <= std_logic_vector(ValBrghtCnt);
  
END RTL;
