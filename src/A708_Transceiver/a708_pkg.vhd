LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;


PACKAGE a708_pkg IS

	CONSTANT RAM_ADDR_WIDTH   : INTEGER := 10; -- A708RX_BUFF size = 4096 bites = 1024 32-bit cells
	CONSTANT RAM_DATA_WIDTH   : INTEGER := 32;
	CONSTANT PHY_DATA_WIDTH   : INTEGER := 16;
	CONSTANT WORDPARTS_16B    : INTEGER := 100;
	
	--=========== DEBUG ONLY ======================
--	CONSTANT A708RXWORDS_NUM  : INTEGER := 3; --10;
--	CONSTANT A708TXWORDS_NUM  : INTEGER := 3; --10;
	--=========== SYNTESIS ======================
	CONSTANT A708RXWORDS_NUM  : INTEGER := 10;
	CONSTANT A708TXWORDS_NUM  : INTEGER := 1;
	
	
	CONSTANT RXBUFF_WORDS_START : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) :=  TO_UNSIGNED( 0, RAM_ADDR_WIDTH );
	CONSTANT RXBUFF_WORDS_END   : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) :=  TO_UNSIGNED( ( WORDPARTS_16B / 2 ) - 1, RAM_ADDR_WIDTH );
	CONSTANT TXBUFF_WORDS_START : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) :=  TO_UNSIGNED( ( WORDPARTS_16B / 2 ), RAM_ADDR_WIDTH );-- TO_UNSIGNED(  64, RAM_ADDR_WIDTH );
	CONSTANT TXBUFF_WORDS_END   : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) :=  TO_UNSIGNED( WORDPARTS_16B, RAM_ADDR_WIDTH );        -- TO_UNSIGNED( 127, RAM_ADDR_WIDTH );
	
	CONSTANT RXBUFF_START : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) :=  TO_UNSIGNED( 0, RAM_ADDR_WIDTH );
	CONSTANT RXBUFF_LEN   : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) :=  TO_UNSIGNED( ( WORDPARTS_16B / 2 * A708RXWORDS_NUM ) , RAM_ADDR_WIDTH );
	CONSTANT RXBUFF_END   : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) :=  RXBUFF_START + RXBUFF_LEN - 1; --TO_UNSIGNED( ( WORDPARTS_16B / 2 * A708RXWORDS_NUM ) - 1, RAM_ADDR_WIDTH );
	

	CONSTANT TXBUFF_START : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) :=  TO_UNSIGNED( 512, RAM_ADDR_WIDTH );
	CONSTANT TXBUFF_END   : UNSIGNED( ( RAM_ADDR_WIDTH - 1 ) DOWNTO 0 ) :=  TXBUFF_START + TO_UNSIGNED( ( WORDPARTS_16B / 2 * A708TXWORDS_NUM ) - 1, RAM_ADDR_WIDTH );  --TO_UNSIGNED( 562, RAM_ADDR_WIDTH );
	
	
	
	------------------- REGISTERS addresses ----------------------
	CONSTANT CONFIG_REG_ADDR   : INTEGER := 0;
	CONSTANT INTMASK_REG_ADDR  : INTEGER := 1;
	CONSTANT INTFLAG_REG_ADDR  : INTEGER := 2;

	----------- CONFIG_REG bits ---------------------
	CONSTANT CPU_BUFF_BUSY  : INTEGER := 26;
	CONSTANT LINE_OFF       : INTEGER := 7;
	CONSTANT NEW_DATA_AVAIL : INTEGER := 2;
	CONSTANT TX_EN          : INTEGER := 1;
	CONSTANT RX_EN          : INTEGER := 0;
	
	---------- INTFLAG_REG bits --------------------
	CONSTANT FPGA_BUFF_BUSY : INTEGER := 26;
	CONSTANT RXWRD_AVAIL_H  : INTEGER := 22;
	CONSTANT RXWRD_AVAIL_L  : INTEGER := 13;
	CONSTANT RD_PTR_H       : INTEGER := 12;
	CONSTANT RD_PTR_L       : INTEGER := 3;
	CONSTANT TX_ERROR       : INTEGER := 2;
	CONSTANT TX_COMPL       : INTEGER := 1;	
	CONSTANT RX_OK          : INTEGER := 0;
		
END a708_pkg;
