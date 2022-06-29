-- PWM_Generator ver 1.0

-- PWM_Counter count by rising edge of ClkIn
-- pwm_val is edge value of PWM_Counter.  
-- pwm_val latch by rising edge Load
-- While PWM_Counter < pwm_val pwm_out = 1
-- when PWM_Counter >= pwm_val pwm_out = 0
-- PWM_Counter count up to PWM_MAX, and then start from 0
-- if pwm_val > PWM_MAX then pwm = 100%

LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY PWM_Gen16 IS
  GENERIC(
    CLK_FREQ_HZ : INTEGER := 1_600_000;
    PWM_FREQ_HZ : INTEGER := 200
  );
  PORT(
    Enable  : IN  STD_LOGIC;
    ClkIn   : IN  STD_LOGIC;
    Load    : IN  STD_LOGIC;
    pwm_val : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0 ); 
    pwm_out : OUT STD_LOGIC
    
  );
END PWM_Gen16;



ARCHITECTURE RTL OF PWM_Gen16 IS

  CONSTANT PWM_MAX     : INTEGER := CLK_FREQ_HZ / PWM_FREQ_HZ;
  CONSTANT PWM_STEP    : INTEGER := 20;

  SIGNAL pwm_val_reg   : INTEGER RANGE 0 TO 65535;
  SIGNAL pwm_val_latch : INTEGER RANGE 0 TO 65535;
  SIGNAL PWM_Counter   : INTEGER RANGE 0 TO PWM_MAX;

BEGIN
  
  
  
  load_val: PROCESS( Enable, ClkIn )
  BEGIN

    IF( Enable = '0' ) THEN

      pwm_val_reg <= 0;

    ELSIF( RISING_EDGE( ClkIn ) ) THEN

      IF( Load = '1' ) THEN

        IF( TO_INTEGER( UNSIGNED( pwm_val )) < PWM_MAX ) THEN
          pwm_val_reg <= TO_INTEGER( UNSIGNED( pwm_val ));
        ELSE
          pwm_val_reg <= PWM_MAX;
        END IF;

      END IF;

    END IF;
  
  END PROCESS;



  pwm_out_gen: PROCESS( Enable, ClkIn )
  BEGIN

    IF( Enable = '0' ) THEN

      PWM_Counter   <= 0;
      pwm_val_latch <= 0;
      pwm_out       <= '0';

    ELSIF( RISING_EDGE( ClkIn ) ) THEN

      IF PWM_Counter < PWM_MAX THEN

        PWM_Counter <= PWM_Counter + 1;

      ELSE

        IF( pwm_val_latch > pwm_val_reg ) THEN

          IF( ( pwm_val_latch - pwm_val_reg ) >= PWM_STEP ) THEN
            pwm_val_latch <= pwm_val_latch - PWM_STEP;
          ELSE
            pwm_val_latch <= pwm_val_reg;
          END IF;

        ELSIF( pwm_val_latch < pwm_val_reg ) THEN

          IF( ( pwm_val_reg - pwm_val_latch ) >= PWM_STEP ) THEN
            pwm_val_latch <= pwm_val_latch + PWM_STEP;
          ELSE
            pwm_val_latch <= pwm_val_reg;
          END IF;

        END IF;

        PWM_Counter <= 0;

      END IF;

      IF PWM_Counter < pwm_val_latch THEN
        pwm_out <= '1';
      ELSE
        pwm_out <= '0';
      END IF;

    END IF;

  END PROCESS;



END RTL;
