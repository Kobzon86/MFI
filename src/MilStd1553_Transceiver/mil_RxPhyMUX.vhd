LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;
--USE work.milstd_1553_pkg.ALL;


ENTITY mil_RxPhyMUX IS
	PORT(
		RxWord1       : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
		RxWordStat1   : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		RxParErr1     : IN  STD_LOGIC;
		RdEn1         : IN  STD_LOGIC;
		RxWord2       : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
		RxWordStat2   : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		RxParErr2     : IN  STD_LOGIC;
		RdEn2         : IN  STD_LOGIC;
		RxWordOut     : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		RxWordStatOut : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		RxParErrOut   : OUT STD_LOGIC
		
	);
	
END mil_RxPhyMUX;


ARCHITECTURE RTL OF mil_RxPhyMUX IS

	SIGNAL op_mode    : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );	
	

BEGIN
	op_mode <= RdEn1 & RdEn2;
	
	RxWordOut     <= RxWord1 WHEN op_mode = "10" ELSE
		             RxWord2 WHEN op_mode = "01" ELSE
		             ( OTHERS => '0' );
		
	RxWordStatOut <= RxWordStat1 WHEN op_mode = "10" ELSE
	                 RxWordStat2 WHEN op_mode = "01" ELSE
	                 ( OTHERS => '0' );
	
	RxParErrOut   <= RxParErr1 WHEN op_mode = "10" ELSE
	                 RxParErr2 WHEN op_mode = "01" ELSE
	                 '0';
		

END RTL;

