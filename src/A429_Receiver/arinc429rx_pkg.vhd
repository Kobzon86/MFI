LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;


PACKAGE arinc429rx_pkg IS
	CONSTANT AR429_ADDR_WIDTH  : INTEGER := 12;
	CONSTANT AR429_DATA_WIDTH  : INTEGER := 32; 
	
	
	CONSTANT AVCFG_ADDR_WIDTH  : INTEGER := 5;--3;
	CONSTANT AV_DATA_WIDTH     : INTEGER := 32;
	
	CONSTANT AV_ADDR_STEP      : INTEGER := 1;
	CONSTANT MASK_ADDR_WIDTH   : INTEGER := 4;--3;
	
	---------------- A429 Receiver address constants ------------
	CONSTANT RXFIFO_OFFSET : UNSIGNED( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 ) := TO_UNSIGNED( 256, AR429_ADDR_WIDTH ); -- in ARINC429 Words
	
	--========== FIFO SIZE must be same as in the CPU!!! =================

	--========== UNCOMMENT FOR SYNTHESIS!!! =============================
	CONSTANT RXFIFO_SIZE   : UNSIGNED( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 ) := TO_UNSIGNED( 768, AR429_ADDR_WIDTH );	-- in ARINC429 Words sinthesys words number
	--====================================================================

	--=========== UNCOMMENT FOR DEBUG ONLY!! ============================
	--CONSTANT RXFIFO_SIZE   : UNSIGNED( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 ) := TO_UNSIGNED( 4, AR429_ADDR_WIDTH );	-- in ARINC429 Words sinthesys words number
	--==================================================================
	
	CONSTANT ALMSTFULL_LVL : UNSIGNED( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 ) := TO_UNSIGNED( ( TO_INTEGER( RXFIFO_SIZE ) / 10 * 8 ), AR429_ADDR_WIDTH ); -- 80 % FIFO number of words writed for almoust full signalling
	CONSTANT RXMAX_ADDR    : UNSIGNED( ( AR429_ADDR_WIDTH - 1 ) DOWNTO 0 ) := ( RXFIFO_OFFSET + RXFIFO_SIZE );  

	CONSTANT RX_FIFO_MODE  : STD_LOGIC := '0';
	CONSTANT RX_ADDR_MODE  : STD_LOGIC := '1';
	
	-------------------- RX Registers Mapping -------------------
	CONSTANT RXCONFIG_REG_ADDR     : INTEGER := 0;
	CONSTANT RXINTMASK_REG_ADDR    : INTEGER := 1;
	CONSTANT RXINTFLAG_REG_ADDR    : INTEGER := 2;
	CONSTANT RXADDRMASK_START_ADDR : INTEGER := 4;
	CONSTANT RXADDRMASK_END_ADDR   : INTEGER := 11;
	CONSTANT NEWDATAREG_END_ADDR   : INTEGER := 19;

	------------------ RXCONFIG_REG BITS --------------------------
	CONSTANT CPU_BUFF_BUSY         : INTEGER := 26;
	CONSTANT ADDR_NROL             : INTEGER := 7;
	CONSTANT PARITY_OFF            : INTEGER := 6;
	CONSTANT TESTA_IN              : INTEGER := 5;
	CONSTANT TESTB_IN              : INTEGER := 4;
	CONSTANT TEST_EN               : INTEGER := 3;
	CONSTANT RD_MODE               : INTEGER := 2;
	CONSTANT CLK_MUX_H             : INTEGER := 1;
	CONSTANT CLK_MUX_L             : INTEGER := 0;
	
	------------------- RXINTFLAG_REG ------------------------
	CONSTANT RXFPGA_BUFF_BUSY      : INTEGER := 26;
	CONSTANT RXSUBADDR_H           : INTEGER := 25;
	CONSTANT RXSUBADDR_L           : INTEGER := 16;
	CONSTANT RXWRD_AVAIL_H         : INTEGER := 25;
	CONSTANT RXWRD_AVAIL_L         : INTEGER := 16;
	CONSTANT RD_PTR_H              : INTEGER := 15;
	CONSTANT RD_PTR_L              : INTEGER := 6;
	CONSTANT INA_TEST              : INTEGER := 5;
	CONSTANT INB_TEST              : INTEGER := 4;
	CONSTANT RX_OK                 : INTEGER := 3;
	CONSTANT RX_FULL               : INTEGER := 2;
	CONSTANT RX_ALMFULL            : INTEGER := 1;
	CONSTANT RX_ERROR              : INTEGER := 0;
	CONSTANT CLRBIT_H              : INTEGER := 3;
	CONSTANT CLRBIT_L              : INTEGER := 0;
	

END arinc429rx_pkg;
