LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;


PACKAGE i2c_heater_pkg IS

	CONSTANT I2C_DATA_WIDTH    : INTEGER := 8;
	CONSTANT I2C_ADDR_WIDTH    : INTEGER := 7;
	CONSTANT I2C_DATA_LEN_MAX  : INTEGER := 63;
	CONSTANT I2C_RD_BIT        : STD_LOGIC := '1';
	CONSTANT I2C_WR_BIT        : STD_LOGIC := '0';
	
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
END i2c_heater_pkg;	
	
	
PACKAGE BODY i2c_heater_pkg IS

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

END i2c_heater_pkg;
