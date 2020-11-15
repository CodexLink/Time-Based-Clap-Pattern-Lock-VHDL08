    -- Internal Component Processor #5 — Reset Password on Storage Mechanism (Has Interrupts)
    -- Password Resetter.
    -- Description    : Resets Password by Filling Patterns with Claps Per Second.

    -- Notes:
    --  1. This process can be run if only if there's a # of CLAP_MIN_LEN_PW or CLAP_MAX_LEN_PW bits opened.
    --  2. This process is very similar in Process 1, except that it acknowledges the button inputs after iteration immediately.
    --  3. This function also doesn't care about your Microphone turned on (along with LED) because it has nothing to do with it.
    --  4. This process doesn't rely on other processors to check the password. It's best to check it inside the processor instead.

    PROCESS IS
    BEGIN
        -- Pre-requisites:
        -- It waits until :
        WAIT UNTIL CL_PW_CLR_STATE_CODE = 0; -- 1. Password Clearing Phase is on State Phase 'Ready'.
        WAIT UNTIL CL_POST_STATE_CODE = 1; -- 2. Post State of the System Indicates that the Lock was in Locked Mode.
        WAIT UNTIL CL_TO_UNLCK_LSTN_STATE_CODE = 0; -- 3. Listen Phase during Unlocking was on State 'Ready'.
        WAIT UNTIL CL_TO_LCK_LSTN_STATE_CODE = 0; -- 4. Listen Phase during Locking was on State 'Ready'.
        WAIT UNTIL CL_PW_VECTOR_STATE_CODE = 0; -- 6. -- 6. Password Storage Malform Detection should be in OKY State.
        WAIT UNTIL CL_PW_STORE_DCT_STATE_CODE = 0; -- 7. -- 7. No Password To Password Detection should be in RDY State.

        WAIT UNTIL BTN_RST_SEQUENCER = '1'; -- 5. Button must be pressed one time.
        -- Check for Password Integrity

        CL_PW_CLR_STATE_CODE <= 1; -- Allow Process To Set Password to Clear.
        -- Wait until the LED Listen Mode was turned off on Testbench Code.
        WAIT UNTIL LED_LSTN_MODE = '0';

        CL_PW_CLR_STATE_CODE <= 2;

        -- Verify The Buttons Sequence (also known as PW_PTRN_RT) with the PW_PTRN_ST.
        IF PW_PTRN_RT = PW_PTRN_ST THEN
            CL_PW_CLR_STATE_CODE <= 5;

            -- We cannot set the password of the storage here!
            -- The testbench external code can do it.
            -- FOR EACH_INDEX IN 0 TO CLAP_WIDTH LOOP
            --     PW_PTRN_ST(EACH_INDEX) <= '0';
            -- END LOOP;

            -- # !

            REPORT "Password Cleared.";
            CL_PW_CLR_STATE_CODE <= 3;
        ELSE
            REPORT "Invalid To Clear Password.";
            CL_PW_CLR_STATE_CODE <= 2;
        END IF;
        WAIT FOR 200 MS;
        CL_PW_CLR_STATE_CODE <= 0;
    END PROCESS;