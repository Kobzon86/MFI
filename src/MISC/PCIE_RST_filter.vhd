LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY PCIE_RST_filter IS
	PORT(
		GCLK          : IN  STD_LOGIC;
		PWR_nReset    : IN  STD_LOGIC;
		PCIE_nRST_In  : IN  STD_LOGIC;
		PCIE_nRST_Out : OUT STD_LOGIC
	);

END PCIE_RST_filter;


ARCHITECTURE RTL OF PCIE_RST_filter IS

BEGIN

-- Фильтрация PCIE_nRST
	
	PROCESS( PWR_nReset, GCLK )
		VARIABLE resetShift : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	BEGIN
		
		IF( PWR_nReset = '0' ) THEN
			
			PCIE_nRST_Out <= '0';
			
		ELSIF( ( GCLK'EVENT ) AND ( GCLK = '1' ) ) THEN
			
			resetShift := resetShift( 3 DOWNTO 0 ) & PCIE_nRST_In;
			IF( resetShift = "01111" ) THEN
				PCIE_nRST_Out <= '1';
			ELSIF( resetShift = "10000" ) THEN
				PCIE_nRST_Out <= '0';
			END IF;
			
		END IF;
		
	END PROCESS;

END RTL;
