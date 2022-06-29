LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;
--USE work.milstd_1553_pkg.ALL;


ENTITY TxPhyDMUX IS
	PORT(
		WordIN   : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		StatIN   : IN  STD_LOGIC_VECTOR(  1 DOWNTO 0 );
		WrEn0    : IN  STD_LOGIC;
		WrEn1    : IN  STD_LOGIC;
		WordOut0 : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		StatOut0 : OUT STD_LOGIC_VECTOR(  1 DOWNTO 0 );
		WordOut1 : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0 );
		StatOut1 : OUT STD_LOGIC_VECTOR(  1 DOWNTO 0 )
	);
END TxPhyDMUX;


ARCHITECTURE RTL OF TxPhyDMUX IS
	SIGNAL op_mode : STD_LOGIC_VECTOR( 1 DOWNTO 0 ) := ( OTHERS => '0' );

BEGIN

	op_mode  <= WrEn1 & WrEn0;
	
	WordOut0 <= WordIN WHEN op_mode = "01" ELSE ( OTHERS => '0' );
	StatOut0 <= StatIN WHEN op_mode = "01" ELSE ( OTHERS => '0' );
	
	WordOut1 <= WordIN WHEN op_mode = "10" ELSE ( OTHERS => '0' );
	StatOut1 <= StatIN WHEN op_mode = "10" ELSE ( OTHERS => '0' );	


END RTL;

