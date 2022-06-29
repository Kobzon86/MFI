LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY AvMM2Mux1 IS
	GENERIC(
		DataWidth : INTEGER := 32;
		AddrWidth : INTEGER := 16
	);
	PORT(
		Avalon_Clock       : IN STD_LOGIC;
		Avalon_nReset      : IN STD_LOGIC;
		---------------- Avalon-MM IN1 --------------------------------------
		AVI1_waitrequest   : OUT STD_LOGIC;
		AVI1_address       : IN  STD_LOGIC_VECTOR( ( AddrWidth - 1 )  DOWNTO 0 );
		AVI1_byteenable    : IN  STD_LOGIC_VECTOR( (DataWidth/8 - 1 ) DOWNTO 0 );
		AVI1_read          : IN  STD_LOGIC;
		AVI1_readdata      : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		AVI1_readdatavalid : OUT STD_LOGIC;
		AVI1_write         : IN  STD_LOGIC;
		AVI1_writedata     : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
	
		--------------- Avalon-MM IN2  ---------------------------------------	
		AVI2_waitrequest   : OUT STD_LOGIC;
		AVI2_address       : IN  STD_LOGIC_VECTOR( ( AddrWidth - 1 ) DOWNTO 0 );
		AVI2_byteenable    : IN  STD_LOGIC_VECTOR( ( DataWidth/8 - 1 ) DOWNTO 0 );
		AVI2_read          : IN  STD_LOGIC;
		AVI2_readdata      : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		AVI2_readdatavalid : OUT STD_LOGIC;
		AVI2_write         : IN  STD_LOGIC;
		AVI2_writedata     : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		
		--------------- Avalon-MM OUT --------------------------------------
		AVMO_waitrequest   : IN  STD_LOGIC;
		AVMO_address       : OUT STD_LOGIC_VECTOR( ( AddrWidth - 1 ) DOWNTO 0 );
		AVMO_byteenable    : OUT STD_LOGIC_VECTOR( ( DataWidth/8 - 1 ) DOWNTO 0 );
		AVMO_read          : OUT STD_LOGIC;
		AVMO_readdata      : IN  STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 );
		AVMO_readdatavalid : IN  STD_LOGIC;
		AVMO_write         : OUT STD_LOGIC;
		AVMO_writedata     : OUT STD_LOGIC_VECTOR( ( DataWidth - 1 ) DOWNTO 0 )
	
		
	);
END AvMM2Mux1;


ARCHITECTURE RTL OF AvMM2Mux1 IS

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
	
	
	SIGNAL control   : STD_LOGIC_VECTOR( 5 DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL RxLatch1  : STD_LOGIC := '0'; 
	SIGNAL RxLatch2  : STD_LOGIC := '0';
	SIGNAL ClrPulse1 : STD_LOGIC := '0'; -- Pulse on falling readdatavalid
	SIGNAL ClrPulse2 : STD_LOGIC := '0';
	SIGNAL ValidPulse : STD_LOGIC := '0';


BEGIN

	valPulse: pgen 
	GENERIC MAP(
		Edge   => '0' -- falling edge
	)
	PORT MAP(
		Enable =>  Avalon_nReset,
		Clk    =>  Avalon_Clock,
		Input  =>  AVMO_readdatavalid,
		Output =>  ValidPulse
	);
	
	
	latch: PROCESS( Avalon_nReset, Avalon_Clock )
	BEGIN
		IF Avalon_nReset = '0' THEN
			RxLatch1 <= '0';
			RxLatch2 <= '0';
		ELSIF RISING_EDGE( Avalon_Clock ) THEN
			IF AVI1_read = '1' THEN
				RxLatch1 <= '1';
			ELSIF ValidPulse = '1' THEN
				RxLatch1 <= '0';
			END IF;
			
			IF AVI2_read = '1' THEN
				RxLatch2 <= '1';
			ELSIF ValidPulse = '1' THEN
				RxLatch2 <= '0';
			END IF;
			
		END IF;
	END PROCESS;
	
	
	
	
	--latch2: PROCESS( Avalon_nReset, Avalon_Clock )
	--BEGIN
		--IF Avalon_nReset = '0' THEN
			--RxLatch2 <= '0';
		--ELSIF RISING_EDGE( Avalon_Clock ) THEN
			--IF AVI2_read = '1' THEN
				--RxLatch2 <= '1';
			--ELSIF ValidPulse = '1' THEN
				--RxLatch2 <= '0';
			--END IF;
		--END IF;
	--END PROCESS;

	
	
	control <= AVI1_read & AVI1_write & RxLatch1 & AVI2_read & AVI2_write & RxLatch2;
	

	WITH control SELECT
	AVMO_read <= '1' WHEN "100000",
	             '1' WHEN "101000",
	             '1' WHEN "000100",
	             '1' WHEN "000101",
	             '0' WHEN OTHERS;
	
	
	WITH control SELECT
	AVMO_write <= '1' WHEN "010000",
	              '1' WHEN "000010",
	              '0' WHEN OTHERS;
		
		
	WITH control SELECT
	AVMO_address <= AVI1_address WHEN "100000",
	                AVI1_address WHEN "101000",
	                AVI1_address WHEN "010000",
	                AVI1_address WHEN "011000",
	                AVI2_address WHEN "000100",
	                AVI2_address WHEN "000101",
	                AVI2_address WHEN "000010",
	                AVI2_address WHEN "000011",
	                --UNAFFECTED WHEN OTHERS;
	                ( OTHERS => '0' ) WHEN OTHERS;
		                
	                
	WITH control SELECT
	AVMO_byteenable <= AVI1_byteenable WHEN "100000",
	                   AVI1_byteenable WHEN "010000",
	                   AVI1_byteenable WHEN "101000",
	                   AVI1_byteenable WHEN "011000",
	                   AVI2_byteenable WHEN "000100",
	                   AVI2_byteenable WHEN "000010",
	                   AVI2_byteenable WHEN "000101",
	                   AVI2_byteenable WHEN "000011",
	                   --UNAFFECTED WHEN OTHERS;
	                   ( OTHERS => '0' ) WHEN OTHERS;


	WITH control SELECT
	AVMO_writedata <= AVI1_writedata WHEN "010000",
	                  AVI2_writedata WHEN "000010",
	                  --UNAFFECTED WHEN OTHERS;
	                  ( OTHERS => '0' ) WHEN OTHERS;
	
	
	WITH control SELECT
	AVI1_waitrequest <= AVMO_waitrequest WHEN "100000",
	                    AVMO_waitrequest WHEN "010000",
	                    AVMO_waitrequest WHEN "001000",
	                    AVMO_waitrequest WHEN "101000",
	                    '0' WHEN OTHERS;
	
	
	WITH control SELECT
	AVI2_waitrequest <= AVMO_waitrequest WHEN "000100",
	                    AVMO_waitrequest WHEN "000010",
	                    AVMO_waitrequest WHEN "000001",
	                    AVMO_waitrequest WHEN "000101",
	                    '0' WHEN OTHERS;
	
	
	WITH control SELECT
	AVI1_readdata <= AVMO_readdata WHEN "100000",
	                 AVMO_readdata WHEN "001000",
	                 AVMO_readdata WHEN "101000",
	                 --UNAFFECTED WHEN OTHERS;
	                 ( OTHERS => '0' ) WHEN OTHERS;
	
	
	WITH control SELECT
	AVI2_readdata <= AVMO_readdata WHEN "000100",
	                 AVMO_readdata WHEN "000001",
	                 AVMO_readdata WHEN "000101",
	                 --UNAFFECTED WHEN OTHERS;
	                 ( OTHERS => '0' ) WHEN OTHERS;
	
	WITH control SELECT
	AVI1_readdatavalid <= AVMO_readdatavalid WHEN "100000",
	                      AVMO_readdatavalid WHEN "001000",
	                      AVMO_readdatavalid WHEN "101000",
	                      '0' WHEN OTHERS;

	
	WITH control SELECT
	AVI2_readdatavalid <= AVMO_readdatavalid WHEN "000100",
	                      AVMO_readdatavalid WHEN "000001",
	                      AVMO_readdatavalid WHEN "000101",
	                      '0' WHEN OTHERS;             
	                      
	                               
END RTL;
