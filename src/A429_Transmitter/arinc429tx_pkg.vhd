LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;


PACKAGE arinc429tx_pkg IS
	CONSTANT AR429_ADDR_WIDTH  : INTEGER := 12;
	CONSTANT AR429_DATA_WIDTH  : INTEGER := 32; 
	
	
	CONSTANT AVCFG_ADDR_WIDTH  : INTEGER := 4;--3;
	CONSTANT AV_DATA_WIDTH     : INTEGER := 32;
	
	CONSTANT AV_ADDR_STEP      : INTEGER := 1;
	CONSTANT MASK_ADDR_WIDTH   : INTEGER := 3;
	

	---------------- A429 Transmitter address constants ---------------
	CONSTANT AR429TX_ADDR_WIDTH : INTEGER := 11;
	CONSTANT TXFIFO_OFFSET : UNSIGNED( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := TO_UNSIGNED( 0, AR429TX_ADDR_WIDTH );  
	
	
	--============ TX_BUFF size same as in the CPU !!! ================= 
	--======= protocol TX_BUFF size in bytes = 2048!!! ==============
	CONSTANT TXFIFO_SIZE   : UNSIGNED( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := TO_UNSIGNED( 512, AR429TX_ADDR_WIDTH ); -- sinthesys 
	--===============================================================
	--===============================================================
	
	
--	CONSTANT TXFIFO_SIZE   : UNSIGNED( ( AR429TX_ADDR_WIDTH - 1 ) DOWNTO 0 ) := TO_UNSIGNED( 8, AR429TX_ADDR_WIDTH );   -- simulation
	
	--------------------- TX Registers Mapping ---------------
	CONSTANT TXCONFIG_REG_ADDR     : INTEGER := 0;
	CONSTANT TXINTMASK_REG_ADDR    : INTEGER := 1;
	CONSTANT TXINTFLAG_REG_ADDR    : INTEGER := 2;
	
	------------------ TXCONFIG_REG BITS ----------------
	CONSTANT CPU_BUFF_BUSY         : INTEGER := 26;
	CONSTANT ADDR_NROL             : INTEGER := 7;
	CONSTANT CLKMUX_H              : INTEGER := 1;
	CONSTANT CLKMUX_L              : INTEGER := 0;
	
	--------------------  TXINTFLAG_REG BITS ------------
	CONSTANT TXFPGA_BUFF_BUSY     : INTEGER := 26;
	CONSTANT TX_FREESPACE_H       : INTEGER := 25;
	CONSTANT TX_FREESPACE_L       : INTEGER := 16;
	CONSTANT INA_TEST             : INTEGER := 5;
	CONSTANT INB_TEST             : INTEGER := 4;
	CONSTANT TX_ERROR             : INTEGER := 3;	 	 
	CONSTANT TX_OVF               : INTEGER := 2;
	CONSTANT TX_TXCOMPL           : INTEGER := 1;
	CONSTANT TX_EMPTY             : INTEGER := 0;
	
	
	

END arinc429tx_pkg;
