LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY CLAP_LOCK_VHDL_TESTBENCH IS
END CLAP_LOCK_VHDL_TESTBENCH;

ARCHITECTURE CL_TESTBENCH_SIML OF CLAP_LOCK_VHDL_TESTBENCH IS

    -- Create emitting error here for constant not respecting CLAP_MIN_LEN_PW and CLAP_MAX_LEN_PW to CLAP_WIDTH.
    CONSTANT CLAP_CNT_TO_LCK_PH : INTEGER := 2;
    CONSTANT CLAP_MIN_LEN_PW : INTEGER := 3;
    CONSTANT CLAP_MAX_LEN_PW : INTEGER := 4;
    CONSTANT CLAP_SLOT_INTERVAL_TO_LOCK : TIME := 400 MS;
    CONSTANT CLAP_WIDTH : INTEGER := 7;

    SIGNAL CL_PW_VECTOR_STATE_CODE : INTEGER RANGE 0 TO 2 := 0;
    SIGNAL CL_PW_CLR_STATE_CODE : INTEGER RANGE 0 TO 5 := 0;
    SIGNAL CL_PW_STORE_DCT_STATE_CODE : INTEGER RANGE 0 TO 5 := 0;
    SIGNAL CL_POST_STATE_CODE : INTEGER RANGE 0 TO 1 := 0;
    SIGNAL CL_TO_UNLCK_LSTN_STATE_CODE : INTEGER RANGE 0 TO 4 := 0;
    SIGNAL CL_TO_LCK_LSTN_STATE_CODE : INTEGER RANGE 0 TO 3 := 0;

    SIGNAL CL_PW_VECTOR_STATE_DISP : STRING (1 TO 3) := "RDY";
    SIGNAL CL_PW_CLR_STATE_DISP : STRING (1 TO 3) := "RDY";
    SIGNAL CL_PW_STORE_DCT_DISP : STRING (1 TO 3) := "RDY";
    SIGNAL CL_POST_STATE_DISP : STRING (1 TO 3) := "CLK";
    SIGNAL CL_TO_UNLCK_LSTN_STATE_DISP : STRING (1 TO 3) := "RDY";
    SIGNAL CL_TO_LCK_LSTN_STATE_DISP : STRING (1 TO 3) := "RDY";

    SIGNAL BTN_RST_SEQUENCER, BTN_DISCARD_CURR_SEQ : STD_LOGIC := '0';
    SIGNAL LED_LSTN_MODE : STD_LOGIC := '0';
    SIGNAL CL_MIC_DTCTR : STD_LOGIC := '0';
    SIGNAL LED_SEC_BLINK_DISP : STD_LOGIC := '0';
    SIGNAL CL_RT_CLK : INTEGER RANGE 0 TO CLAP_WIDTH;

    SIGNAL CL_TO_LCK_CLAP_SLTS : STD_LOGIC_VECTOR (CLAP_CNT_TO_LCK_PH DOWNTO 0) := (OTHERS => '0');
    SIGNAL PW_PTRN_RT : STD_LOGIC_VECTOR (CLAP_WIDTH DOWNTO 0) := (OTHERS => '0');
    SIGNAL PW_PTRN_ST : STD_LOGIC_VECTOR (CLAP_WIDTH DOWNTO 0) := (OTHERS => '0');

BEGIN

    instClapLockModule : ENTITY work.CLAP_LOCK_VHDL(CL_DIGITAL_SIM)
        GENERIC MAP(
            CLAP_CNT_TO_LCK_PH => CLAP_CNT_TO_LCK_PH,
            CLAP_MIN_LEN_PW => CLAP_MIN_LEN_PW,
            CLAP_MAX_LEN_PW => CLAP_MAX_LEN_PW,
            CLAP_SLOT_INTERVAL_TO_LOCK => CLAP_SLOT_INTERVAL_TO_LOCK,
            CLAP_WIDTH => CLAP_WIDTH
        )
        PORT MAP(
            BTN_RST_SEQUENCER => BTN_RST_SEQUENCER,
            BTN_DISCARD_CURR_SEQ => BTN_DISCARD_CURR_SEQ,

            CL_MIC_DTCTR => CL_MIC_DTCTR,
            CL_RT_CLK => CL_RT_CLK,

            CL_PW_VECTOR_STATE_DISP => CL_PW_VECTOR_STATE_DISP,
            CL_PW_CLR_STATE_DISP => CL_PW_CLR_STATE_DISP,
            CL_PW_STORE_DCT_DISP => CL_PW_STORE_DCT_DISP,
            CL_POST_STATE_DISP => CL_POST_STATE_DISP,
            CL_TO_UNLCK_LSTN_STATE_DISP => CL_TO_UNLCK_LSTN_STATE_DISP,
            CL_TO_LCK_LSTN_STATE_DISP => CL_TO_LCK_LSTN_STATE_DISP,
            CL_PW_VECTOR_STATE_CODE => CL_PW_VECTOR_STATE_CODE,

            CL_PW_CLR_STATE_CODE => CL_PW_CLR_STATE_CODE,
            CL_PW_STORE_DCT_STATE_CODE => CL_PW_STORE_DCT_STATE_CODE,
            CL_POST_STATE_CODE => CL_POST_STATE_CODE,
            CL_TO_UNLCK_LSTN_STATE_CODE => CL_TO_UNLCK_LSTN_STATE_CODE,
            CL_TO_LCK_LSTN_STATE_CODE => CL_TO_LCK_LSTN_STATE_CODE,

            CL_TO_LCK_CLAP_SLTS => CL_TO_LCK_CLAP_SLTS,
            LED_SEC_BLINK_DISP => LED_SEC_BLINK_DISP,
            LED_LSTN_MODE => LED_LSTN_MODE,
            PW_PTRN_RT => PW_PTRN_RT,
            PW_PTRN_ST => PW_PTRN_ST
        );

    -- Simulation of Introduction of the Clap Lock

    PROCESS IS
    BEGIN

        REPORT "Testbench | The system will check for the password storage container after 300 ms.";

        WAIT FOR 300 MS;

        REPORT "Testbench | Waiting for Input Clap...";
        CL_MIC_DTCTR <= '1';
        LED_LSTN_MODE <= '1';

        -- Waits for Module to Set CL_PW_STORE_DCT_STATE_CODE to LTC.

        REPORT "Testbench | Ready, Waiting for State Change to CL_PW_STORE_DCT_STATE_CODE ...";
        WAIT UNTIL CL_PW_STORE_DCT_STATE_CODE = 1;

        -- Change the REPORT Display.
        REPORT "Testbench | CL_PW_STORE_DCT_STATE_CODE Value is " & INTEGER'image(CL_PW_STORE_DCT_STATE_CODE);

        WHILE (CL_PW_STORE_DCT_STATE_CODE /= 4) LOOP

            -- Input Password Per Pattern Slot for Processor #6
            -- FOR ITERATION_INDEX IN 0 TO CLAP_WIDTH - 1 LOOP
            --     IF CL_PW_STORE_DCT_STATE_CODE = 3 THEN
            --         REPORT "Testbench | Password has been reset due to Interrupted Process.";
            --         PW_PTRN_RT <= "00000000";
            --         EXIT;
            --     ELSE
            --         WAIT FOR 1 SEC;
            --         REPORT "Testbench | Iteration Index #" & INTEGER'image(ITERATION_INDEX) & " | With CL_MIC_DTCTR Value of " & STD_LOGIC'image(CL_MIC_DTCTR);
            --         PW_PTRN_RT(ITERATION_INDEX) <= CL_MIC_DTCTR;
            --     END IF;
            -- END LOOP;
            PW_PTRN_RT <= "10010110";
            WAIT FOR 250 MS;
            IF CL_PW_STORE_DCT_STATE_CODE = 3 THEN
                NEXT;
            END IF;
            PW_PTRN_RT <= "00000000";
        END LOOP;

        CL_MIC_DTCTR <= '0';
        LED_LSTN_MODE <= '0';

        WAIT FOR 1 SEC;

        REPORT "Testbench | Waiting for Input Clap to Unlock the System...";
        CL_MIC_DTCTR <= '1';
        LED_LSTN_MODE <= '1';


        -- Wait for 250MS to compensate to reading the data.
    END PROCESS;

    -- Internal Component Processor #7 — Password Reset Functionality
    -- Password Modification to PW_PTRN_ST has been found on two processes.
    -- It's to play under each processes state and do modifications.


    --     -- Omitted Tester Process #1
    --     --Step 1, Active Microphone and the Timer along with Runtime Password Pattern Checker.
    --     WAIT FOR 250 MS;
    --     CL_MIC_DTCTR <= '1';

    --     WAIT FOR 1 SEC;
    --     LED_LSTN_MODE <= '1' WHEN CL_MIC_DTCTR = '1' ELSE
    --         '0';

    --     WAIT UNTIL LED_LSTN_MODE = '1';
    --     WAIT FOR 1 SEC;

    --     FOR EACH_INDEX IN 0 TO CLAP_WIDTH - 1 LOOP
    --         IF (BTN_DISCARD_CURR_SEQ = '0' AND LED_LSTN_MODE = '1') THEN
    --             LED_SEC_BLINK_DISP <= NOT LED_SEC_BLINK_DISP;
    --             PW_PTRN_RT(EACH_INDEX) <= CL_MIC_DTCTR;

    --             WAIT FOR 1 SEC;
    --         ELSE
    --             PW_PTRN_RT <= "00000000";
    --             LED_LSTN_MODE <= '0';
    --             REPORT "PW_PTRN_RT has been reset.";
    --         END IF;
    --     END LOOP;
    --     -- Keep note that, after iteration, the PW_PTRN_RT should be reset here!
    --     -- The module cannot modify it since PW_PTRN_RT is in IN mode. INOUT cannot do
    --     LED_LSTN_MODE <= '0';
    --     REPORT "PW_PTRN_RT has been finished.";

    --     -- Next Step, Password Checking
    --     -- CL_STATUS_CODE <= 5; -- Set to Status Code 5 to Check Password Given.
    --     WAIT;
    -- END PROCESS;

    -- LED Trigger with respect to Clap Mic Detection — TEST BENCH
    -- This reduce the need of modifying signals throughout testbench.

    -- PROCESS (CL_MIC_DTCTR) IS
    -- BEGIN
    --
    -- END PROCESS;
END ARCHITECTURE;

-- 362
-- FOR BTN_INDEX_ITER IN 0 TO CLAP_WIDTH LOOP
-- WAIT FOR 1 SEC; -- Wait for certain MS or whatever the constraint is before checking for the detection of claps.
-- PW_PTRN_RT(BTN_INDEX_ITER) <= BTN_RST_SEQUENCER;
-- END LOOP;