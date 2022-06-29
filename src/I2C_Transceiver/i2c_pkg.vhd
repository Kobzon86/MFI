LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.key_codes_pkg.ALL;

PACKAGE i2c_pkg IS

	CONSTANT I2C_WR_BIT          : STD_LOGIC := '0';
	CONSTANT I2C_RD_BIT          : STD_LOGIC := '1';
	CONSTANT I2C_DATA_WIDTH      : INTEGER := 8;
	CONSTANT I2C_ADDR_WIDTH      : INTEGER := 7;
	CONSTANT I2C_DATA_LEN_MAX    : INTEGER := 63; -- maximal number of data bytes, readed from I2C
	
	
	CONSTANT CLKIN_FREQ_HZ     : INTEGER := 1_600_000;
	CONSTANT PWM_FREQ_HZ       : INTEGER := 200;
	CONSTANT PWM_MAX_VAL       : INTEGER := CLKIN_FREQ_HZ / PWM_FREQ_HZ;

	CONSTANT BTN_BRGHT_DEFAULT  : STD_LOGIC_VECTOR( 7 DOWNTO 0 )  := x"1F";  -- MAX_VAL = x"1F" due to PWM_MAX_VAL
	CONSTANT SPIN_BRGHT_DEFAULT : STD_LOGIC_VECTOR( 7 DOWNTO 0 )  := x"0F";  -- MAX_VAL = x"1F" due to PWM_MAX_VAL
	CONSTANT LCD_BRGHT_DEFAULT  : STD_LOGIC_VECTOR( 11 DOWNTO 0 ) := x"100"; -- MAX_VAL = x"1F4" due to PWM_MAX_VAL
	CONSTANT BTN_SPIN_MAX       : STD_LOGIC_VECTOR( 7 DOWNTO 0 )  := x"1F";
	CONSTANT LCD_BRGHT_MAX      : STD_LOGIC_VECTOR( 11 DOWNTO 0 ) := x"1F4"; 

	CONSTANT BTN_PWM_LSHIFT      : INTEGER := 5;
	CONSTANT SPIN_PWM_LSHIFT     : INTEGER := 5;
	CONSTANT LCD_PWM_LSHIFT      : INTEGER := 1;

	CONSTANT MPU_PWR_PACK_LEN    : INTEGER := 4;  -- bytes number must be readed from MPU_PWR through I2C

-------------- FOR SYNTHESIS ----------------
	CONSTANT AVM_ADDR_WIDTH    : INTEGER := 6;  --12
	
	----------- FOR DEBUG ONLY -----------------
	--CONSTANT AVM_ADDR_WIDTH    : INTEGER := 4;
	
	CONSTANT AVM_DATA_WIDTH    : INTEGER := 32; 
	CONSTANT AVCFG_ADDR_WIDTH  : INTEGER := 3;
	
	
	CONSTANT TXBUFF_STARTADDR  : INTEGER := 16; -- First 16 words in RxTx_Buffer are for RxData
	CONSTANT I2C_TXBUF_LEN     : INTEGER := 16;    
	-------------------- I2C Internal Registers Mapping -------------------
	CONSTANT CONFIG_REG_ADDR     : INTEGER := 0;
	CONSTANT INTMASK_REG_ADDR    : INTEGER := 1;
	CONSTANT INTFLAG_REG_ADDR    : INTEGER := 2;
	
	--------------- CONFIG_REG BITS -------------------------------
	CONSTANT I2C_EN             : INTEGER := 0;
	CONSTANT CPU_BUFF_BUSY      : INTEGER := 26;
	
	
	------------- INTFLAG_REG BITS -------------------------------
	CONSTANT NEWDATA_RX         : INTEGER := 0;
	CONSTANT FAULT_27V1         : INTEGER := 1;
	CONSTANT FAULT_27V2         : INTEGER := 2;
	CONSTANT LCD_SIZE_L         : INTEGER := 3;
	CONSTANT LCD_SIZE_H         : INTEGER := 4;
	CONSTANT PWRBAD_BIT         : INTEGER := 5;
	CONSTANT BATLOW_BIT         : INTEGER := 6;
	CONSTANT FPGA_BUFF_BUSY     : INTEGER := 26;
	
	
	CONSTANT CLRBIT_H           : INTEGER := 0;
	CONSTANT CLRBIT_L           : INTEGER := 0; 
	
	CONSTANT I2C_NIOS_BUFF_STARTADDR : INTEGER := TO_INTEGER(x"0020_0080"/4);--TXBUFF_STARTADDR + I2C_TXBUF_LEN;
	CONSTANT I2C_NIOS_BUFF_LEN : INTEGER := 16;  -- Number of 32-bit words
	CONSTANT TERMO_DATA_LEN      : INTEGER := 2;  -- bytes number must be readed from TermoSensor through I2C
	
	----------------- I2C devices addresses -----------
	CONSTANT I2C_VALPORT_ADDR      : STD_LOGIC_VECTOR( 6 DOWNTO 0 ) := "0100001";  -- Valcoders I2C PORT
	CONSTANT I2C_KEYPORT_ADDR      : STD_LOGIC_VECTOR( 6 DOWNTO 0 ) := "0100000";  -- Matrix keyboard I2C PORT
	CONSTANT I2C_MPU_PWR_ADDR      : STD_LOGIC_VECTOR( 6 DOWNTO 0 ) := "0110000";  -- MPU_PWR I2C address
	CONSTANT I2C_TERMOSENS_ADDR    : STD_LOGIC_VECTOR( 6 DOWNTO 0 ) := "1001000";  -- Termo sensor I2C address
	CONSTANT I2C_LSENSE0_ADDR      : STD_LOGIC_VECTOR( 6 DOWNTO 0 ) := "1001010";  -- LEFT light sensor (front view)
	CONSTANT I2C_LSENSE1_ADDR      : STD_LOGIC_VECTOR( 6 DOWNTO 0 ) := "1001011";  -- RIGHT light sensor (front view)
	
	---------------- I2C PORT registers --------------
	CONSTANT I2CPORT_INREG0_ADDR    : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"00";
	CONSTANT I2CPORT_INREG1_ADDR    : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"01";
	CONSTANT I2CPORT_OUTREG0_ADDR   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"02";
	CONSTANT I2CPORT_OUTREG1_ADDR   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"03";
	CONSTANT I2CPORT_PINVREG0_ADDR  : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"04";
	CONSTANT I2CPORT_PINVREG1_ADDR  : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"05";
	CONSTANT I2CPORT_CFGREG0_ADDR   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"06";
	CONSTANT I2CPORT_CFGREG1_ADDR   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"07";

	---------------- I2C PORT Config reg values -------------------
	CONSTANT I2CVALPORT_CFGREG0     : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"FF";
	CONSTANT I2CVALPORT_CFGREG1     : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"FF";
	CONSTANT I2CKEYPORT_CFGREG0     : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"FF";  -- Horizontal scans by I2C PORT outputs 
	CONSTANT I2CKEYPORT_CFGREG1     : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"07";  -- x"07" Vertical checks by I2C PORT inputs 
	
	---------------- I2C TERMO SENSOR REGISTERS  ---------------------
	CONSTANT I2CTERMO_TEMPER_ADDR   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"00";
	CONSTANT I2CTERMO_CFGREG_ADDR   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"01";
	CONSTANT I2CTERMO_HISTER_ADDR   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"02";
	CONSTANT I2CTERMO_OVTEMP_ADDR   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"03";
	
	
	CONSTANT DIR_CW    : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
	CONSTANT DIR_CCW   : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "10";
	CONSTANT DIR_NO    : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "00";
	
	
	CONSTANT VAL_CCW1  : UNSIGNED( 3 DOWNTO 0 ) := x"2";
	CONSTANT VAL_CCW2  : UNSIGNED( 3 DOWNTO 0 ) := x"4";
	CONSTANT VAL_CCW3  : UNSIGNED( 3 DOWNTO 0 ) := x"B";
	CONSTANT VAL_CCW4  : UNSIGNED( 3 DOWNTO 0 ) := x"D";
	
	CONSTANT VAL_CW1  : UNSIGNED( 3 DOWNTO 0 ) := x"1";
	CONSTANT VAL_CW2  : UNSIGNED( 3 DOWNTO 0 ) := x"7";
	CONSTANT VAL_CW3  : UNSIGNED( 3 DOWNTO 0 ) := x"8";
	CONSTANT VAL_CW4  : UNSIGNED( 3 DOWNTO 0 ) := x"E";
	
	--CONSTANT KBD_COL_MAX : INTEGER := 6;
	--CONSTANT KBD_ROW_MAX : INTEGER := 5;
	
	CONSTANT KBD_COL_MAX : INTEGER := 8;
	CONSTANT KBD_ROW_MAX : INTEGER := 5;

	
	CONSTANT KEYPRESS_MAX_NUM : INTEGER := 2;
	CONSTANT KSCAN_START_CODE : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "01111111";  -- scan with running zero from MSb to LSb 
	
	CONSTANT KBD_10INCH  : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "00";
	CONSTANT KBD_12INCH  : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "01";
	CONSTANT KBD_15INCH  : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := "10";
	
	CONSTANT IND_MFI2     : STD_LOGIC_VECTOR( 2 DOWNTO 0 ) := "000";
	CONSTANT IND_MFI2_10  : STD_LOGIC_VECTOR( 2 DOWNTO 0 ) := "001";
	CONSTANT IND_MFI2_12  : STD_LOGIC_VECTOR( 2 DOWNTO 0 ) := "010";
	CONSTANT IND_MFI2_15  : STD_LOGIC_VECTOR( 2 DOWNTO 0 ) := "011";
	
	CONSTANT RES_320x240   : STD_LOGIC_VECTOR( 3 DOWNTO 0 ) := "0000";
	CONSTANT RES_640x480   : STD_LOGIC_VECTOR( 3 DOWNTO 0 ) := "0001";
	CONSTANT RES_800x600   : STD_LOGIC_VECTOR( 3 DOWNTO 0 ) := "0010";
	CONSTANT RES_1024x768  : STD_LOGIC_VECTOR( 3 DOWNTO 0 ) := "0011";
	CONSTANT RES_1920x1080 : STD_LOGIC_VECTOR( 3 DOWNTO 0 ) := "0100";
	
	---------- Brightness control modes -----------------
	CONSTANT BRGHT_MODE_AUTO   : STD_LOGIC := '0';  -- use light sensors for brightness correction
	CONSTANT BRGHT_MODE_MANUAL : STD_LOGIC := '1';  -- not use light sensors for brightness correction
	CONSTANT BRGHT_NO_AEXT     : STD_LOGIC := '0';  -- not use global brightness signal 
	CONSTANT BRGHT_USE_AEXT    : STD_LOGIC := '1';  -- use global brightness signal
	CONSTANT BRGHT_NO_DEXT     : STD_LOGIC := '0';  -- not use external device for brightness control
	CONSTANT BRGHT_USE_DEXT    : STD_LOGIC := '1';  -- use external device for brightness control
	
	
	
	TYPE keys_array IS ARRAY ( 0 TO KBD_ROW_MAX, 0 TO KBD_COL_MAX ) OF INTEGER RANGE 0 TO 1023; 

	-- Arinc429 word labels
	CONSTANT WORD_0357            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11101111"; -- o"357";
	CONSTANT WORD_0360            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11110000"; -- o"360";
	CONSTANT WORD_0361            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11110001"; -- o"361";
	CONSTANT WORD_0362            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11110010"; -- o"362";
	CONSTANT WORD_0363            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11110011"; -- o"363";
	CONSTANT WORD_0364            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11110100"; -- o"364";
	CONSTANT WORD_0365            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11110101"; -- o"365";
	CONSTANT WORD_0366            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11110110"; -- o"366";
	CONSTANT WORD_0367            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11110111"; -- o"367";
	CONSTANT WORD_0370            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11111000"; -- o"370";
	CONSTANT WORD_0371            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11111001"; -- o"371";
	CONSTANT WORD_0372            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11111010"; -- o"372";
	CONSTANT WORD_0373            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11111011"; -- o"373";
	CONSTANT WORD_0374            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11111100"; -- o"374";
	CONSTANT WORD_0375            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11111101"; -- o"375";
	CONSTANT WORD_0376            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11111110"; -- o"376";
	CONSTANT WORD_0377            : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11111111"; -- o"377";
	


	
	---- H5-V7 = VALLEFT_BTN 
	---- H5-V8 = VALRIGHT_BTN 
	-- valcoders buttons press codes 
	CONSTANT keyboard_codes15 : keys_array := ( --  V1         V2         V3          V4            V5         V6       V7          V8           N.C.
	                                          ( KEY_LEFT1, KEY_LEFT6,  KEY_DOWN4,  KEY_DOWN9,   KEY_RIGHT3, KEY_UP9, KEY_UP4,     NO_KEY      , NO_KEY ), -- H1
	                                          ( KEY_LEFT2, KEY_LEFT7,  KEY_DOWN5,  KEY_RIGHT7,  KEY_RIGHT2, KEY_UP8, KEY_UP3,     NO_KEY      , NO_KEY ), -- H2
	                                          ( KEY_LEFT3, KEY_DOWN1,  KEY_DOWN6,  KEY_RIGHT6,  KEY_RIGHT1, KEY_UP7, KEY_UP2,     NO_KEY      , NO_KEY ), -- H3
	                                          ( KEY_LEFT4, KEY_DOWN2,  KEY_DOWN7,  KEY_RIGHT5,  KEY_UP11,   KEY_UP6, KEY_UP1,     NO_KEY      , NO_KEY ), -- H4  <-= KEY_UP11 !!
	                                          ( KEY_LEFT5, KEY_DOWN3,  KEY_DOWN8,  KEY_RIGHT4,  KEY_UP10,   KEY_UP5, VALLEFT_BTN, VALRIGHT_BTN, NO_KEY ), -- H5
	                                          ( NO_KEY,    NO_KEY,     NO_KEY,     NO_KEY,      NO_KEY,     NO_KEY,  NO_KEY,      NO_KEY      , NO_KEY )  -- N.C.
	                                        ); 

	---- H5-V3 = VALLEFT_BTN 
	---- H5-V4 = VALRIGHT_BTN 
	
	CONSTANT keyboard_codes12 : keys_array := ( --  V1         V2         V3          V4            V5         V6      V7     V8     N.C.
	                                          ( KEY_LEFT1, KEY_LEFT6,  KEY_DOWN5,   KEY_RIGHT4,   KEY_UP8, KEY_UP4, NO_KEY, NO_KEY, NO_KEY ), -- H1
	                                          ( KEY_LEFT2, KEY_DOWN1,  KEY_DOWN6,   KEY_RIGHT3,   KEY_UP7, KEY_UP3, NO_KEY, NO_KEY, NO_KEY ), -- H2
	                                          ( KEY_LEFT3, KEY_DOWN2,  KEY_RIGHT6,  KEY_RIGHT2,   KEY_UP6, KEY_UP2, NO_KEY, NO_KEY, NO_KEY ), -- H3
	                                          ( KEY_LEFT4, KEY_DOWN3,  KEY_RIGHT5,  KEY_RIGHT1,   KEY_UP5, KEY_UP1, NO_KEY, NO_KEY, NO_KEY ), -- H4
	                                          ( KEY_LEFT5, KEY_DOWN4,  VALLEFT_BTN, VALRIGHT_BTN, NO_KEY,  NO_KEY,  NO_KEY, NO_KEY, NO_KEY ), -- H5
	                                          ( NO_KEY,    NO_KEY,     NO_KEY,      NO_KEY,       NO_KEY,  NO_KEY,  NO_KEY, NO_KEY, NO_KEY )  -- N.C.
	                                        );

	
	CONSTANT keyboard_codes10 : keys_array := ( -- V1         V2         V3          V4            V5        V6      V7      V8     N.C.
                                            ( KEY_UP2,   KEY_LEFT4,  KEY_DOWN4,   KEY_RIGHT3,   KEY_UP6,   NO_KEY, NO_KEY, NO_KEY, NO_KEY ), -- H1
                                            ( KEY_UP1,   KEY_LEFT5,  KEY_DOWN5,   KEY_RIGHT2,   KEY_UP5,   NO_KEY, NO_KEY, NO_KEY, NO_KEY ), -- H2
                                            ( KEY_LEFT1, KEY_DOWN1,  KEY_RIGHT5,  KEY_RIGHT1,   KEY_UP4,   NO_KEY, NO_KEY, NO_KEY, NO_KEY ), -- H3
                                            ( KEY_LEFT2, KEY_DOWN2,  KEY_RIGHT4,  KEY_UP7,      KEY_UP3,   NO_KEY, NO_KEY, NO_KEY, NO_KEY ), -- H4
                                            ( KEY_LEFT3, KEY_DOWN3,  VALLEFT_BTN, VALRIGHT_BTN, NO_KEY,    NO_KEY, NO_KEY, NO_KEY, NO_KEY ), -- H5
                                            ( NO_KEY,    NO_KEY,     NO_KEY,      NO_KEY,       NO_KEY,    NO_KEY, NO_KEY, NO_KEY, NO_KEY )  -- N.C.
                                          );

	
	
	----------- Light Sensors Registers Addressess ----------------
	CONSTANT LSENSE_CFGREG_ADDR   : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"02";	
	CONSTANT LSENSE_LUXHBREG_ADDR : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"03";	
	CONSTANT LSENSE_LUXLBREG_ADDR : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"04";	
	
	----------- Light Sensors Registers Value ---------------------
	CONSTANT LSENSE_CFGREG0       : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11001100"; --  CONT_MODE=1, MANUAL=1, TIM[2:0]=100b->integration time = 50ms
	CONSTANT LSENSE_CFGREG1       : STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "11001100"; --  CONT_MODE=1, MANUAL=1, TIM[2:0]=100b->integration time = 50ms
	

	                                        
	
	TYPE I2C_Rd_Array IS ARRAY ( 0 TO I2C_DATA_LEN_MAX ) OF STD_LOGIC_VECTOR( 7 DOWNTO 0 );	
	
	
	PROCEDURE i2c_reg_wr( CONSTANT dev_addr_in : IN STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );  -- I2C Bus device address
	                      CONSTANT reg_addr_in : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );  -- I2C Device internal register address
	                      CONSTANT regval_in   : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );  -- I2C Device internal register value to write
	                      SIGNAL  ByteCnt      : INOUT INTEGER RANGE 0 TO I2C_DATA_LEN_MAX; 
	                      SIGNAL dev_addr_out  : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 ); -- I2C Signal out to Phy I2C_master
	                      SIGNAL rw_out        : OUT STD_LOGIC;                                     -- I2C Signal out to Phy I2C_master
	                      SIGNAL ena           : INOUT STD_LOGIC;                                   -- I2C Signal out to Phy I2C_master
	                      SIGNAL busy          : IN  STD_LOGIC;                                     -- I2C Signal in from Phy I2C_master busy current value
	                      SIGNAL busy_prev     : IN  STD_LOGIC;                                     -- I2C Signal in from Phy I2C_master busy prev value
	                      SIGNAL done          : OUT STD_LOGIC;                                     -- Signal Done of operation
	                      SIGNAL byte_out      : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 )  -- I2C Signal out to Phy I2C_master
	                    );
	
	
	PROCEDURE i2c_reg_rd( CONSTANT dev_addr_in : IN STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );  -- I2C Bus device address
	                      CONSTANT reg_addr_in : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );  -- I2C Device internal register address
	                      SIGNAL   regval_rd   : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );  -- I2C Device internal register value readed
	                      SIGNAL ByteCnt       : INOUT INTEGER RANGE 0 TO I2C_DATA_LEN_MAX; 
	                      SIGNAL dev_addr_out  : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 ); -- I2C Signal out to Phy I2C_master
	                      SIGNAL rw_out        : OUT STD_LOGIC;                                     -- I2C Signal out to Phy I2C_master
	                      SIGNAL ena           : INOUT STD_LOGIC;                                   -- I2C Signal out to Phy I2C_master
	                      SIGNAL busy          : IN  STD_LOGIC;                                     -- I2C Signal in from Phy I2C_master busy current value
	                      SIGNAL busy_prev     : IN  STD_LOGIC;                                     -- I2C Signal in from Phy I2C_master busy prev value
	                      SIGNAL done          : INOUT STD_LOGIC;                                     -- Signal Done of operation
	                      SIGNAL byte_out      : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ); -- I2C Signal out to Phy I2C_master
	                      SIGNAL byte_in       : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 )   -- I2C Signal in from Phy I2C_master
	                    );


	
	PROCEDURE i2c_array_rd( CONSTANT dev_addr_in : IN STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      CONSTANT reg_addr_in : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );
	                      SIGNAL  regval_rd    : OUT I2C_Rd_Array; --STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	                      SIGNAL ByteCnt       : INOUT INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	                      SIGNAL I2C_DataLen   : IN INTEGER RANGE 0 TO 63;
	                      SIGNAL dev_addr_out  : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      SIGNAL rw_out        : OUT STD_LOGIC;
	                      SIGNAL ena           : INOUT STD_LOGIC;
	                      SIGNAL busy          : IN  STD_LOGIC;
	                      SIGNAL busy_prev     : IN  STD_LOGIC;
	                      SIGNAL done          : INOUT STD_LOGIC;
	                      SIGNAL byte_out      : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ); 
	                      SIGNAL byte_in       : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ) 
	                      ); 
	
	
	PROCEDURE i2c_mpupwr_array_rd( CONSTANT dev_addr_in : IN STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      SIGNAL  regval_rd    : OUT I2C_Rd_Array;  --STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	                      SIGNAL ByteCnt       : INOUT INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	                      SIGNAL I2C_DataLen   : IN INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	                      SIGNAL dev_addr_out  : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      SIGNAL rw_out        : OUT STD_LOGIC;
	                      SIGNAL ena           : INOUT STD_LOGIC;
	                      SIGNAL busy          : IN  STD_LOGIC;
	                      SIGNAL busy_prev     : IN  STD_LOGIC;
	                      SIGNAL done          : INOUT STD_LOGIC;
	                      SIGNAL byte_out      : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ); 
	                      SIGNAL byte_in       : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ) 
	                      );
	

	                  	
  	PROCEDURE Gray2Hex(
	                   SIGNAL GrayCodeIn  : IN STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	                   VARIABLE HexOut    : OUT UNSIGNED( 3 DOWNTO 0 )
	                   );


	PROCEDURE RotationDir(
	                    SIGNAL PrevState   : IN UNSIGNED( 3 DOWNTO 0 );
	                    VARIABLE CurState  : IN UNSIGNED( 3 DOWNTO 0 );
	                    VARIABLE Dir       : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 )  -- 01 = CW; 10 = CCW; 00 - No rotation 
	                    );

	
	PROCEDURE ValCalc(
	                 VARIABLE Direction   : IN STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	                 SIGNAL Counter       : INOUT SIGNED( 3 DOWNTO 0 )
	                 );
                    
	                      
END i2c_pkg;	
	
	
PACKAGE BODY i2c_pkg IS

	PROCEDURE i2c_reg_wr( CONSTANT dev_addr_in : IN STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      CONSTANT reg_addr_in : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );
	                      CONSTANT regval_in   : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );
	                      SIGNAL ByteCnt       : INOUT INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	                      SIGNAL dev_addr_out  : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      SIGNAL rw_out        : OUT STD_LOGIC;
	                      SIGNAL ena           : INOUT STD_LOGIC;
	                      SIGNAL busy          : IN  STD_LOGIC;
	                      SIGNAL busy_prev     : IN  STD_LOGIC;
	                      SIGNAL done          : OUT STD_LOGIC;
	                      SIGNAL byte_out      : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ) ) IS
	
	BEGIN
		rw_out       <= I2C_WR_BIT;
		dev_addr_out <= dev_addr_in;
		
		IF ( ( ena = '0' ) AND ( busy = '0' ) ) THEN
			done <= '0';
			ena <= '1';
		ELSIF ( ( ena = '1' ) AND ( ByteCnt = 2 ) ) THEN
			ByteCnt <= 0;
			done <= '1';
			ena <= '0';
		ELSIF ( ( ena = '1' ) AND ( busy > busy_prev ) ) THEN
			IF ByteCnt < 2 THEN
				ByteCnt <= ByteCnt + 1;
			END IF;
		END IF;
		
		
		IF ByteCnt = 0 THEN
			byte_out  <= reg_addr_in;
		ELSIF ByteCnt = 1 THEN
			byte_out <= regval_in;
		END IF;
	
	END i2c_reg_wr;
	


	PROCEDURE i2c_reg_rd( CONSTANT dev_addr_in : IN STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      CONSTANT reg_addr_in : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );
	                      SIGNAL  regval_rd    : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );
	                      SIGNAL ByteCnt       : INOUT INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	                      SIGNAL dev_addr_out  : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      SIGNAL rw_out        : OUT STD_LOGIC;
	                      SIGNAL ena           : INOUT STD_LOGIC;
	                      SIGNAL busy          : IN  STD_LOGIC;
	                      SIGNAL busy_prev     : IN  STD_LOGIC;
	                      SIGNAL done          : INOUT STD_LOGIC;
	                      SIGNAL byte_out      : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ); 
	                      SIGNAL byte_in       : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ) ) IS
	
	BEGIN
		
		
		
		IF ( ( ena = '0' ) AND ( busy = '0' ) AND ( ByteCnt = 0 ) AND ( done = '0' ) ) THEN
			ena <= '1';
			dev_addr_out <= dev_addr_in;
			
		ELSIF ( ( ena = '1' ) AND ( ByteCnt = 2 ) ) THEN
			ena <= '0';
		ELSIF ( ( ena = '1' ) AND ( busy > busy_prev ) ) THEN
			IF ByteCnt < 2 THEN
				ByteCnt <= ByteCnt + 1;
			END IF;
		END IF;
	
		
		IF ByteCnt = 0 THEN
			byte_out  <= reg_addr_in;
			rw_out    <= I2C_WR_BIT;
		ELSIF ByteCnt = 1 THEN
			rw_out <= I2C_RD_BIT;
		ELSIF ( ( ByteCnt = 2 ) AND ( busy = '0' ) ) THEN
			regval_rd <= byte_in;
			ByteCnt <= 0;
			done <= '1';
		END IF;
		
	
	END i2c_reg_rd;



	PROCEDURE i2c_array_rd( CONSTANT dev_addr_in : IN STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      CONSTANT reg_addr_in : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );
	                      SIGNAL  regval_rd    : OUT I2C_Rd_Array;  --STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	                      SIGNAL ByteCnt       : INOUT INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	                      SIGNAL I2C_DataLen   : IN INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	                      SIGNAL dev_addr_out  : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      SIGNAL rw_out        : OUT STD_LOGIC;
	                      SIGNAL ena           : INOUT STD_LOGIC;
	                      SIGNAL busy          : IN  STD_LOGIC;
	                      SIGNAL busy_prev     : IN  STD_LOGIC;
	                      SIGNAL done          : INOUT STD_LOGIC;
	                      SIGNAL byte_out      : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ); 
	                      SIGNAL byte_in       : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ) ) IS
	
	BEGIN
		
		IF ( ( ena = '0' ) AND ( busy = '0' ) AND ( ByteCnt = 0 ) AND ( done = '0' ) ) THEN
			ena <= '1';
			dev_addr_out <= dev_addr_in;
			
		ELSIF ( ( ena = '1' ) AND ( ByteCnt = I2C_DataLen + 1 ) ) THEN
			ena <= '0';
		ELSIF ( ( ena = '1' ) AND ( busy > busy_prev ) ) THEN
			IF ByteCnt < ( I2C_DataLen + 1 ) THEN 
				ByteCnt <= ByteCnt + 1;
			END IF;
		END IF;
	
		
		IF ByteCnt = 0 THEN
			byte_out  <= reg_addr_in;
			rw_out    <= I2C_WR_BIT;
		ELSIF ByteCnt = 1 THEN
			rw_out <= I2C_RD_BIT;
		ELSIF ( ByteCnt > 1 ) AND ( ByteCnt < I2C_DataLen + 1 ) THEN
			regval_rd( ByteCnt - 2 ) <= byte_in;
		ELSIF ( ( ByteCnt = I2C_DataLen + 1 ) AND ( busy = '0' ) ) THEN
			regval_rd( ByteCnt - 2 ) <= byte_in;
			ByteCnt <= 0;
			done <= '1';
		END IF;
		
	END i2c_array_rd;


	
	
	
	PROCEDURE i2c_mpupwr_array_rd( CONSTANT dev_addr_in : IN STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      SIGNAL  regval_rd    : OUT I2C_Rd_Array;  --STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	                      SIGNAL ByteCnt       : INOUT INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	                      SIGNAL I2C_DataLen   : IN INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	                      SIGNAL dev_addr_out  : OUT STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );
	                      SIGNAL rw_out        : OUT STD_LOGIC;
	                      SIGNAL ena           : INOUT STD_LOGIC;
	                      SIGNAL busy          : IN  STD_LOGIC;
	                      SIGNAL busy_prev     : IN  STD_LOGIC;
	                      SIGNAL done          : INOUT STD_LOGIC;
	                      SIGNAL byte_out      : OUT STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ); 
	                      SIGNAL byte_in       : IN STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 ) ) IS
	
	BEGIN
		
		IF ( ( ena = '0' ) AND ( busy = '0' ) AND ( ByteCnt = 0 ) AND ( done = '0' ) ) THEN
			ena <= '1';
			dev_addr_out <= dev_addr_in;
			
		ELSIF ( ( ena = '1' ) AND ( ByteCnt = I2C_DataLen ) ) THEN
			ena <= '0';
		ELSIF ( ( ena = '1' ) AND ( busy > busy_prev ) ) THEN
			IF ByteCnt < ( I2C_DataLen ) THEN 
				ByteCnt <= ByteCnt + 1;
			END IF;
		END IF;
		
		IF ( ByteCnt < I2C_DataLen ) THEN
			rw_out <= I2C_RD_BIT;
			regval_rd( ByteCnt ) <= byte_in;
			done <= '0';
		ELSIF ( ( ByteCnt = I2C_DataLen ) AND ( busy = '0' ) ) THEN
			regval_rd( ByteCnt ) <= byte_in;
			ByteCnt <= 0;
			done <= '1';
		END IF;
		
	END i2c_mpupwr_array_rd;


		PROCEDURE Gray2Hex(
	                   SIGNAL GrayCodeIn  : IN STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	                   VARIABLE HexOut    : OUT UNSIGNED( 3 DOWNTO 0 )
	                   ) IS
	BEGIN
		CASE GrayCodeIn IS
		WHEN "00" =>
			HexOut :=  x"0";
		WHEN "01" =>
			HexOut :=  x"1";
		WHEN "11" =>
			HexOut :=  x"2";
		WHEN "10" =>
			HexOut :=  x"3";
		WHEN OTHERS => 
			NULL;
		END CASE;
		
	END Gray2Hex;

	
	
	PROCEDURE RotationDir(
	                    SIGNAL PrevState   : IN UNSIGNED( 3 DOWNTO 0 );
	                    VARIABLE CurState  : IN UNSIGNED( 3 DOWNTO 0 );
	                    VARIABLE Dir       : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 )  -- 01 = CW; 10 = CCW; 00 - No rotation 
	                    ) IS
	BEGIN
		
		CASE PrevState IS
		WHEN x"0" =>
			IF  CurState = x"3" THEN
				Dir := DIR_CCW;
			ELSIF CurState = x"1" THEN
				Dir := DIR_CW;
			ELSE 
				Dir := DIR_NO;
			END IF;
		
		WHEN x"1" | x"2" =>
			IF PrevState > CurState THEN
				Dir := DIR_CCW;
			ELSIF PrevState < CurState THEN
				Dir := DIR_CW;
			ELSE
				Dir := DIR_NO;
			END IF;
			
		WHEN x"3" =>
			IF CurState = x"0" THEN
				Dir := DIR_CW;
			ELSIF CurState = x"2" THEN
				Dir := DIR_CCW;
			ELSE
				Dir := DIR_NO;
			END IF;
		
		WHEN OTHERS =>
			NULL;
		END CASE;

	END RotationDir;




	PROCEDURE ValCalc(
	                 VARIABLE Direction   : IN STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	                 SIGNAL   Counter     : INOUT SIGNED( 3 DOWNTO 0 )
	                 ) IS
	BEGIN
		IF Direction = DIR_CW THEN
			IF Counter < x"7" THEN
				Counter <=  Counter + 1;
			END IF;
		ELSIF Direction = DIR_CCW THEN
			IF ( ( Counter > x"9" ) OR ( Counter = x"0" ) ) THEN
				Counter <= Counter - 1;
			END IF;
		END IF;
		
	
	END ValCalc;
	


 
END i2c_pkg;


