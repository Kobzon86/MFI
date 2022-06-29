LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY ram_mux IS 
	GENERIC(
		RamAddrWidth : INTEGER := 13;
		RdAddrWidth  : INTEGER := 12;
		WrAddrWidth  : INTEGER := 13;
		BEWidth      : INTEGER := 4
		
	);
	PORT(
		Clk        : IN STD_LOGIC;
		RdEn       : IN STD_LOGIC;
		WrEn       : IN STD_LOGIC;
		RdAddr     : IN STD_LOGIC_VECTOR( ( RdAddrWidth - 1 ) DOWNTO 0 );
		RdByteEn   : IN STD_LOGIC_VECTOR( ( BEWidth - 1 ) DOWNTO 0 );
		WrAddr     : IN STD_LOGIC_VECTOR( ( WrAddrWidth - 1 ) DOWNTO 0 );
		WrByteEn   : IN STD_LOGIC_VECTOR( ( BEWidth - 1 ) DOWNTO 0 );
		WrDataIn   : IN STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		RamWrData  : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		RamRdEn    : OUT STD_LOGIC;
		RamWrEn    : OUT STD_LOGIC;
		RamAddr    : OUT STD_LOGIC_VECTOR( ( RamAddrWidth - 1 ) DOWNTO 0 );
		RamByteEn  : OUT STD_LOGIC_VECTOR( ( BEWidth - 1 ) DOWNTO 0 )
	);

END ram_mux;



ARCHITECTURE RTL OF ram_mux IS

	SIGNAL LocRdEn, LocWrEn   : STD_LOGIC := '0';
	SIGNAL LocRdEn1, LocWrEn1 : STD_LOGIC := '0';
	SIGNAL LocRdEn2, LocWrEn2 : STD_LOGIC := '0';
	SIGNAL LocAddr          : STD_LOGIC_VECTOR( ( RamAddrWidth - 1 ) DOWNTO 0  ) := ( OTHERS => '0' );
	SIGNAL LocByteEn        : STD_LOGIC_VECTOR( ( BEWidth - 1 ) DOWNTO 0 ) := ( OTHERS => '0' );
	SIGNAL LocData          : STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := ( OTHERS => '0' );

BEGIN
	
	EnabReg: PROCESS( Clk )
	BEGIN
		IF RISING_EDGE( Clk ) THEN
			LocRdEn1 <= RdEn;
			LocRdEn2  <= LocRdEn1;
			
	--		LocWrEn1 <= WrEn;
	--		LocWrEn2  <= LocWrEn1;
		
		END IF;
	
	END PROCESS;

	
	InputReg: PROCESS( Clk )
	BEGIN
		IF RISING_EDGE( Clk ) THEN
			--IF LocRdEn2 /= LocWrEn2 THEN
			IF LocRdEn2 /= WrEn THEN
				IF ( LocRdEn2 = '1' ) THEN	
				
					LocAddr   <= RdAddr;
					LocByteEn <= RdByteEn;
					LocRdEn   <= '1';
					LocWrEn   <= '0';
					
				--ELSIF LocWrEn2 = '1' THEN
				ELSIF WrEn = '1' THEN
			
					LocAddr   <= WrAddr; --( ( WrAddr'LEFT ) DOWNTO 0 ) );
					LocByteEn <= WrByteEn;
					LocData   <= WrDataIn;
					LocRdEn   <= '0';
					LocWrEn   <= '1';
					
				END IF;

			ELSE
				LocRdEn <= '0';
				LocWrEn <= '0';
			
			END IF;
		
		END IF;
	
	END PROCESS;


	

	OutputReg: PROCESS( Clk )
	BEGIN
		IF FALLING_EDGE( Clk ) THEN
			
			RamAddr   <= LocAddr;
			RamRdEn   <= LocRdEn;
			RamWrEn   <= LocWrEn;
			RamByteEn <= LocByteEn;
			RamWrData <= LocData;
		
		END IF;
	END PROCESS;

END RTL;
