LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY CLAP_LOCK_VHDL IS
    GENERIC (
        CLAP_CNT_TO_LCK_PH : INTEGER := 0; -- Clap Count To Locking Phase.
        CLAP_MIN_LEN_PW : INTEGER := 0; -- Minimum Clap Length Password Pattern
        CLAP_MAX_LEN_PW : INTEGER := 0; -- Maximum Clap Length Password Pattern
        CLAP_SLOT_INTERVAL_TO_LOCK : TIME := 1 SEC; -- Clap Slot Interval To Verify.
        CLAP_WIDTH : INTEGER := 0 -- Clap Length, 1st Index Based! Code will handle it to zero-based.
        -- Keep in mind that CLAP_MIN_LEN_PW and CLAP_MAX_LEN_PW respects CLAP_WIDTH legnth!
    );

    PORT (
        -- Clap Signals Integer State Signals
        -- More information about these soon because it was looking redundant here.
        CL_PW_VECTOR_STATE_CODE : OUT INTEGER RANGE 0 TO 2 := 0;
        CL_PW_CLR_STATE_CODE : OUT INTEGER RANGE 0 TO 5 := 0;
        CL_PW_STORE_DCT_STATE_CODE : OUT INTEGER RANGE 0 TO 5 := 0;
        CL_POST_STATE_CODE : OUT INTEGER RANGE 0 TO 1 := 1;
        CL_TO_UNLCK_LSTN_STATE_CODE : OUT INTEGER RANGE 0 TO 4 := 0;
        CL_TO_LCK_LSTN_STATE_CODE : OUT INTEGER RANGE 0 TO 3 := 0;
        BTN_RST_SEQUENCER, BTN_DISCARD_CURR_SEQ : IN STD_LOGIC := '0';

        -- These CL displays were divided due to One Process, One Signal Drive!
        -- Keep in mind that, the use of Zero-Index is applied here.
        -- This means that instead providing of 5 DOWNTO 0 for a Size of 5.
        -- It was done to 4 DOWNTO 0.

        -- Clap Signals Readable State Contexts
        CL_PW_VECTOR_STATE_DISP : OUT STRING (1 TO 3) := "RDY";
        CL_PW_CLR_STATE_DISP : OUT STRING (1 TO 3) := "RDY";
        CL_PW_STORE_DCT_DISP : OUT STRING (1 TO 3) := "RDY";
        CL_POST_STATE_DISP : OUT STRING (1 TO 3) := "LKD";
        CL_TO_UNLCK_LSTN_STATE_DISP : OUT STRING (1 TO 3) := "RDY";
        CL_TO_LCK_LSTN_STATE_DISP : OUT STRING (1 TO 3) := "RDY";

        -- User Input and LED Indicator of Listening Mode.
        CL_MIC_DTCTR : IN STD_LOGIC := '0'; -- MIC that detects clap.
        LED_LSTN_MODE : IN STD_LOGIC := '0'; -- Listening Mode Indicator
        -- Runtime Indicators.
        -- CL_RT_CLK : IN INTEGER RANGE 0 TO CLAP_WIDTH; -- + 2 because, on + 1, becauase of WHILE Compensation.
        LED_SEC_BLINK_DISP : IN STD_LOGIC := '0'; -- Time Second Rising Edge Indicator.
        -- Clap Slots (Specifically for Unlocked to Lock Mechanism)
        CL_TO_LCK_CLAP_SLTS : OUT STD_LOGIC_VECTOR (CLAP_CNT_TO_LCK_PH DOWNTO 0) := (OTHERS => '0'); -- Clap Slots for Locking Phase.
        -- Password Storages
        PW_PTRN_RT : IN STD_LOGIC_VECTOR (CLAP_WIDTH DOWNTO 0) := (OTHERS => '0'); -- Runtime Storage
        PW_PTRN_ST : OUT STD_LOGIC_VECTOR (CLAP_WIDTH DOWNTO 0) := (OTHERS => '0') -- Last Known Storage
    );

END CLAP_LOCK_VHDL;

ARCHITECTURE CL_DIGITAL_SIM OF CLAP_LOCK_VHDL IS
BEGIN
    -- Internal Component Processor #1 — Password Vector Bit Detection (Initial / Startup) (No Interrupts)
    -- Password Detection for Malform or Non-Malformed or No Password.
    -- Description    : Checks if the password container contains data or else restrict the system to do anything
    --                  unless the user sets a password to allow Locking and Unlocking Capabilities.

    -- Notes:
    --  1. This process can be executed in the beginning so, there's no wait for other signals that are essential in the whole operation.
    --  2. This process only alters CL_PW_VECTOR_STATE_CODE and other processors depend on it.
    --  3. This processor has a WAIT statement for PW_PTRN_RT and PW_PTRN_ST.
    --  4. This process will only run ONE TIME. It is a startup process that checks for the input.
    --  5. It has a delay to compensate for the initialization of the device.
    --  6. Once it resolves things over time, it will wait until PW_PTRN_ST has been changed.

    PROCESS IS
        VARIABLE HAS_NO_PASSWORD : BOOLEAN := FALSE;
        VARIABLE PW_CLAP_COUNT_HANDLER : INTEGER := 0;
        VARIABLE INIT_FLAG : BOOLEAN := TRUE;
        VARIABLE ON_BIT_COUNT : INTEGER := 0;
    BEGIN
        -- Pre-requisites:
        -- It waits until :

        -- On initialization, we run this process.
        -- After triggering this process, it has to wait for PW_PTRN_ST to change before running it again.

        -- Pre Initialization, Checking of Constraint of Claps Width.
        -- Checks if CLAP_MIN_LEN_PW and CLAP_MAX_LEN_PW respects CLAP_WIDTH.
        -- CLAP_MIN_LEN_PW and CLAP_MAX_LEN_PW can have the same value as long as it was not conflicting.
        -- The use of negative sign is not allowed here!

        IF INIT_FLAG = TRUE THEN
            IF CLAP_MIN_LEN_PW < 0 THEN
                REPORT "Initialization Processor #1 | Minimum Allowed Claps is out of bounds of acceptable range. (Range should be 0 to Positive Number.)" SEVERITY FAILURE;
                WAIT;
            END IF;

            IF CLAP_MAX_LEN_PW < 0 THEN
                REPORT "Initialization Processor #1 | Maximum Allowed Claps is out of bounds! (Range should be 0 to Positive Number.)" SEVERITY FAILURE;
                WAIT;
            END IF;

            IF CLAP_MIN_LEN_PW > CLAP_MAX_LEN_PW THEN
                REPORT "Initialization Processor #1 | Minimum Allowed Claps is expected to be lower than CLAP_MAX_LEN_PW! Please check your value assignment before port instantiation!" SEVERITY FAILURE;
                WAIT;
            END IF;

            IF CLAP_MIN_LEN_PW > CLAP_WIDTH THEN
                REPORT "Initialization Processor #1 | Minimum Allowed Claps weren't respecting the value of CLAP_WIDTH. Please check your value assignment before port instantiation!" SEVERITY FAILURE;
                WAIT;
            END IF;

            IF CLAP_MAX_LEN_PW > CLAP_WIDTH THEN
                REPORT "Initialization Processor #1 | Maximum Allowed Claps weren't respecting the value of CLAP_WIDTH. Please check your value assignment before port instantiation!" SEVERITY FAILURE;
                WAIT;
            END IF;

            WAIT FOR 250 MS;
            REPORT "Processor #1 | Initialization Started, setting it to False.";
            INIT_FLAG := FALSE;
        ELSE
            REPORT "Processor #1 | After Initialization Phase, On Wait For Next Changes.";
            WAIT ON PW_PTRN_ST; -- Wait for changes.
            REPORT "Processor #1 | Changes on Password Pattern Storage Detected!";

        END IF;

        -- There will be two loops for initialization!

        -- Checks the container if is malformed or has no password.
        -- We don't wanna check by statically declaring a bits of zeros since the width is dynamic.
        FOR EACH_PW_INDEX IN 0 TO CLAP_WIDTH - 1 LOOP
            IF PW_PTRN_ST(EACH_PW_INDEX) = '1' THEN
                ON_BIT_COUNT := ON_BIT_COUNT + 1;
            END IF;
        END LOOP;

        HAS_NO_PASSWORD := TRUE WHEN ON_BIT_COUNT = 0 ELSE
            FALSE;

        ON_BIT_COUNT := 0;

        IF HAS_NO_PASSWORD THEN
            CL_PW_VECTOR_STATE_CODE <= 1; --NPW, Sets to No Password State.
            REPORT "Processor #1 | The system detects no password. Set to NPW state and waiting for resolve.";

            -- We wait until it has been resolved.
            WAIT UNTIL CL_PW_STORE_DCT_STATE_CODE = 4;
            CL_PW_VECTOR_STATE_CODE <= 0;
            HAS_NO_PASSWORD := FALSE;
            REPORT "Processor #1 | The system has a password because of state CL_PW_VECTOR_STATE_CODE to 4. Issue Resolved. Ready to Unlock.";

        ELSE

            -- If it has a password, then check for the password if malformed.
            -- If we assumed that the data is retained on initialization then we could check.

            FOR PW_INDEX_ITERATION IN 0 TO CLAP_WIDTH LOOP
                IF PW_PTRN_ST(PW_INDEX_ITERATION) = '1' THEN
                    PW_CLAP_COUNT_HANDLER := PW_CLAP_COUNT_HANDLER + 1;
                ELSE
                    NEXT;
                END IF;
            END LOOP;

            -- After checking if the length respects CLAP_MIN_LEN_PW and CLAP_MAX_LEN_PW.
            -- It will determines if it was malformed, if it is, then a reset to the password is needed.

            IF PW_CLAP_COUNT_HANDLER >= CLAP_MIN_LEN_PW AND PW_CLAP_COUNT_HANDLER <= CLAP_MAX_LEN_PW THEN
                REPORT "Processor #1 | All Clear.";
                CL_PW_VECTOR_STATE_CODE <= 0; -- RDY, All Clear.
            ELSE
                REPORT "Processor #1 | The system detects that the Password is Malformed, Resetting Password in 1 Second.";
                CL_PW_VECTOR_STATE_CODE <= 2; -- MPW

                WAIT FOR 250 MS;

                WAIT ON PW_PTRN_ST; -- Assumes that it will reset!

                -- In the testbench, you have to clear the password there!
                -- A seperate process might be nice. But, let's see if that is gonna work.

                -- FOR EACH_INDEX IN 0 TO CLAP_WIDTH LOOP
                --     PW_PTRN_ST(EACH_INDEX) <= '0';
                -- END LOOP;

                CL_PW_VECTOR_STATE_CODE <= 1;
                REPORT "Processor #1 | Password has been reset.";

            END IF;
            PW_CLAP_COUNT_HANDLER := 0;
        END IF;
        WAIT;

    END PROCESS;

    -- Internal Component Processor #2 — Realtime Clock of Runtime Clap Processor (Has Interrupts)
    -- Input for Unlocking.
    -- Description    : Runs everytime when a clap was heard for the first time.
    --                  It does not record the first clap as a zero index of PW_PTRN_RT.
    --
    -- Notes:
    --  1.  This does not run under Unlock To Lock Phase since it has different constraints
    --      and different parameters to take. I cannot optimize this mechanism into one
    --      functionality due to nature of VHDL Programming. (This means of not being able to apply DRY Principles.)
    --  2.  This does not handle the Clap Input (Microphone) but rather iterates through time!
    --      The testbench should handle the inputs.
    --  3.  This function only handles interrupts over time that the Testbench cannot handle. (except sending signals ofc.)

    PROCESS IS
        VARIABLE IS_SEQ_ITER_INTERRUPTED : BOOLEAN := FALSE; -- Boolean for Sequence Iteration Interrupted.
    BEGIN

        -- Pre-requisites
        -- It waits until :
        WAIT UNTIL LED_LSTN_MODE = '1'; -- 1.2. With LED being turned on as well.
        -- 2. Password State Phase is on State 'Ready'.
        -- 3. Post State of the System Indicates the Lock was in Locked Mode.
        -- 4. Listen Phase was Prematurely on Ready State Before Shifting to LTC Mode.
        -- 5. Unlock To Lock Phase State should still be in RDY State.
        -- 6. Password Storage Malform Detection should be in OKY State.
        -- 7. No Password To Password Detection should be in RDY State.

        IF CL_PW_CLR_STATE_CODE = 0 AND CL_POST_STATE_CODE = 1 AND CL_TO_UNLCK_LSTN_STATE_CODE = 0 AND CL_TO_LCK_LSTN_STATE_CODE = 0 AND CL_PW_VECTOR_STATE_CODE = 0 AND CL_PW_STORE_DCT_STATE_CODE = 0 THEN
            REPORT "Processor #2 | Realtime Clock of Runtime Clap Processor Process Triggered.";

            WHILE (CL_POST_STATE_CODE /= 0) LOOP
                -- Set Listen Phase Status to Listen Mode.
                CL_TO_UNLCK_LSTN_STATE_CODE <= 1; -- LTC
                -- Run the Iteration in Seconds delay.
                FOR RUNTIME_CNT_SEC IN 0 TO CLAP_WIDTH LOOP
                    -- Wait for 1 Second Here To Compensate with 0 Second shifting to 1 Second.
                    WAIT FOR 1 SEC;

                    -- Checks with Excemption for CL_MIC_DTCTR. Because user could skip certain seconds for pattern.
                    IF (BTN_DISCARD_CURR_SEQ = '0' AND LED_LSTN_MODE = '1') THEN
                        IS_SEQ_ITER_INTERRUPTED := FALSE;

                    ELSE
                        -- Reset the Whole System State to Locked Mode.
                        -- Set Sequence Iteration Interrupted and Iterate Runtimes to Zero.
                        IS_SEQ_ITER_INTERRUPTED := TRUE;
                        EXIT;

                    END IF;
                END LOOP;

                IF IS_SEQ_ITER_INTERRUPTED THEN
                    REPORT "Processor #2 | Process Interrupted due to Button Push.";
                    CL_TO_UNLCK_LSTN_STATE_CODE <= 3; -- IPR
                ELSE
                    REPORT "Processor #2 | Process On Password Validation.";
                    CL_TO_UNLCK_LSTN_STATE_CODE <= 2; -- PWV
                END IF;

                WAIT FOR 500 MS;

                IF CL_POST_STATE_CODE = 0 THEN
                    CL_TO_UNLCK_LSTN_STATE_CODE <= 0;
                    EXIT;
                ELSE
                    NEXT;
                END IF;

                IS_SEQ_ITER_INTERRUPTED := FALSE; -- Check if it resets.
                REPORT "Processor #2 | Realtime Clock of Runtime Clap Processor Process is Finished.";
            END LOOP;
        END IF;
    END PROCESS;

    -- Internal Component Processor #3 — Password Validation to Unlock or Retained State Phase Mechanism (No Interrupts) (Multi-Usage)
    -- Password Verifier to Unlock.
    -- Description    : Checks for Password Everytime CL_TO_UNLCK_LSTN_STATE_DISP has a value of 2 which is Password Checking Mode.
    --
    -- Notes:
    --  1.  This process assumes that the PW_PTRN_ST contains Vectored Password Pattern!
    --      It does not check it because we have a signal that displays if the state of the lock has a password.
    --  2. This is where the comparison happens between PW_PTRN_RT and PW_PTRN_ST.
    --  3. This function only change the state of the lock, it does not however change other signals.
    --  4. This function can be used by Unlocked to Locked Mechanism but the implementation will be different.
    --  5. This function also doesn't care about your Microphone turned on (along with LED) because it has nothing to do with it.
    -- 1. CL_TO_UNLCK_LSTN_STATE_CODE should be under PWV State.
    -- 2. CL_TO_LCK_LSTN_STATE_CODE should be under VTL State.
    --
    -- These two pre-requisites shouldn't conflict on '1' Value as they should be unique on multiple occasions.

    PROCESS IS
    BEGIN
        WAIT ON CL_TO_UNLCK_LSTN_STATE_CODE, CL_TO_LCK_LSTN_STATE_CODE;

        -- Two Signals on Wait Statement shouldn't have the same value!
        -- They should contain distinct values with another other to trigger certain signal modifications.
        -- Result of Conflict from Conditionals will only REPORT Not-So-Error Message. (See ELSE Clause Part.)

        IF CL_TO_UNLCK_LSTN_STATE_CODE = 2 AND CL_TO_LCK_LSTN_STATE_CODE = 0 THEN
            REPORT "Processor #3 | Validating Password...";
            IF PW_PTRN_RT = PW_PTRN_ST THEN
                CL_POST_STATE_CODE <= 0;
                REPORT "Processor #3 | The Lock is now in Unlocked State.";
            ELSE
                CL_POST_STATE_CODE <= 1;
                REPORT "Processor #3 | The Lock is now in Locked State.";
            END IF;
        ELSIF CL_TO_LCK_LSTN_STATE_CODE = 2 AND CL_TO_UNLCK_LSTN_STATE_CODE = 0 THEN
            CL_POST_STATE_CODE <= 1;
            REPORT "Processor #3 | The Lock is in Locked State caused by Unlock To Lock.";

        END IF;
    END PROCESS;

    -- Internal Component Processor #4 — Runtime Unlock to Lock Phase Processor (No Interrupts)
    -- Input for Locking.
    -- Description    : Runs only when CL_POST_STATE_CODE is in 'ULK' state.
    --                  It does not record the first clap as a first index of PW_PTRN_RT.
    --
    -- Notes:
    --  1.  This does not run under Unlock To Lock Phase since it has different constraints
    --      and different parameters to take. I cannot optimize this mechanism into one
    --      functionality due to nature of VHDL Programming. (This means of not being able to apply DRY Principles.)
    --  2.  This process checks for the claps in a short amount of time! As it only takes a # of claps to Lock the Vault Back.

    PROCESS IS
        VARIABLE CLAP_SLOT_ITER : INTEGER := 0;
        VARIABLE VERIFIED_TO_LCK_PH : BOOLEAN := TRUE;
    BEGIN

        -- Pre-requisites
        -- It waits until :
        WAIT ON CL_POST_STATE_CODE; -- 1.2. With LED being turned on as well.

        IF CL_POST_STATE_CODE = 0 THEN
            CL_TO_LCK_LSTN_STATE_CODE <= 1;
        ELSE
            WAIT FOR 1 SEC;
            CL_TO_LCK_LSTN_STATE_CODE <= 0;

        END IF;
        WAIT FOR 500 MS;
        IF CL_PW_CLR_STATE_CODE = 0 AND CL_POST_STATE_CODE = 0 AND CL_TO_UNLCK_LSTN_STATE_CODE = 2 AND CL_TO_LCK_LSTN_STATE_CODE = 1 AND CL_PW_VECTOR_STATE_CODE = 0 AND CL_PW_STORE_DCT_STATE_CODE = 0 THEN
            -- Once a clap was heard, register the first clap so that we won''t be getting delays.
            -- Increment the index from zeroth to first index.
            CL_TO_LCK_LSTN_STATE_CODE <= 1;
            CL_TO_LCK_CLAP_SLTS(0) <= CL_MIC_DTCTR;
            CLAP_SLOT_ITER := CLAP_SLOT_ITER + 1;

            REPORT "Processor #4 | Set First Clap in Zero-th Index of CL_TO_LCK_CLAP_SLTS";

            -- Iterate the remaining claps required before processing to Locked Mode.
            -- The remaining clap slots will iterate even when not detecting the claps.
            -- This means that the system will disgard it if the clap under constraint intervals did not meet.

            -- This part of the process DOES NOT manipulate the input. Testbench process is required.
            WHILE (CL_TO_LCK_LSTN_STATE_CODE /= 2) LOOP
                WHILE (CLAP_SLOT_ITER < CLAP_CNT_TO_LCK_PH) LOOP
                    WAIT FOR CLAP_SLOT_INTERVAL_TO_LOCK; -- Wait for certain MS or whatever the constraint is before checking for the detection of claps.
                    -- CL_RT_CLK <= CL_RT_CLK + 1;
                    CL_TO_LCK_CLAP_SLTS(CLAP_SLOT_ITER) <= CL_MIC_DTCTR;
                    CLAP_SLOT_ITER := CLAP_SLOT_ITER + 1;
                    REPORT "Processor #4 | Clap Slot " & INTEGER'image(CLAP_SLOT_ITER) & " out of " & INTEGER'image(CLAP_CNT_TO_LCK_PH) & " | Value is " & STD_LOGIC'image(CL_MIC_DTCTR);
                END LOOP;

                CLAP_SLOT_ITER := 0;

                REPORT "Processor #4 | Iteration To Clap Finished.";

                -- CL_RT_CLK <= 0;
                WAIT FOR 250 MS;
                -- Verify if the Claps contains all ones.
                -- Or else, dismiss the request of Locking Phase.

                FOR eachClapsSlots IN 0 TO CLAP_CNT_TO_LCK_PH - 1 LOOP
                    REPORT "Processor #4 | Bit Checking | (" & INTEGER'image(eachClapsSlots) & " out of " & INTEGER'image(CLAP_CNT_TO_LCK_PH - 1) & ") | Value is " & STD_LOGIC'image(CL_TO_LCK_CLAP_SLTS(eachClapsSlots));
                    IF CL_TO_LCK_CLAP_SLTS(eachClapsSlots) = '0' THEN
                        VERIFIED_TO_LCK_PH := FALSE;
                        REPORT "Processor #4 | Bit Checking | Invalid to Lock Phase.";
                        EXIT; -- Breaking the loop here.
                    END IF;
                END LOOP;

                IF VERIFIED_TO_LCK_PH THEN
                    -- Reset the Runtime Password Pattern Storage HERE!
                    -- Reset everything when returning to Locking State.
                    CL_TO_LCK_LSTN_STATE_CODE <= 2; -- VTL
                    REPORT "Processor #4 | Claps Verified with Timeframe Correct. Switching to Locked Mode.";

                ELSE
                    -- Or else, repeat this process by manipulating the state.
                    CL_TO_LCK_LSTN_STATE_CODE <= 3; -- Quick Spike before returning to Process Execution of this Process.
                    REPORT "Processor #4 | Claps Incomplete, Retained Locked Mode.";

                    WAIT FOR 250 MS;

                    -- Wait for 250 MS Before rerunning this process.
                    CL_TO_LCK_LSTN_STATE_CODE <= 1; -- Quick Spike before returning to Process Execution of this Process.
                END IF;

                -- Cleanup.
                FOR eachClapSlots IN 0 TO CLAP_CNT_TO_LCK_PH LOOP
                    CL_TO_LCK_CLAP_SLTS(eachClapSlots) <= '0';
                END LOOP;

                VERIFIED_TO_LCK_PH := TRUE;

                WAIT FOR 500 MS;
            END LOOP;
        END IF;

        -- Cleanup in Out of Scope of Loop.
        CL_TO_LCK_LSTN_STATE_CODE <= 0;
    END PROCESS;

    -- Internal Component Processor #6 — Clap Input to Password Storage (Non-Runtime) (Password Container) (Has Interrupts)
    -- Password Setter.
    -- Description    : Inputs password to PW_PTRN_RT and saves to PW_PTRN_ST one-time only.

    -- Notes:
    --  1. This process depends to Extra 2 - Password Vector Bit Detection. It should be the only one to trigger this process.
    --  2. Other signals were ignored in this process other than LED_LSTN_MODE and CL_MIC_DTCTR.
    --  3. This process never checks for PW_PTRN_ST's data as it only overrides it here.
    --     Extra 2 Password Vector Bit Detection should be the check it.

    -- Pre-requisites:
    -- It waits until :
    --  1.  CL_PW_CLR_STATE_CODE turns to 'CPW', Cleared Password State.
    --  2.  CL_PW_VECTOR_STATE_CODE turns to 'NPW', No Password State.
    PROCESS IS
        VARIABLE BIT_ON_COUNTER : INTEGER := 0;
    BEGIN

        WAIT ON CL_PW_CLR_STATE_CODE, CL_PW_VECTOR_STATE_CODE; -- Waits when it was Cleared for Password.

        IF CL_PW_CLR_STATE_CODE = 5 OR CL_PW_VECTOR_STATE_CODE = 1 OR CL_PW_VECTOR_STATE_CODE = 2 THEN

            -- Set to Ready To Listen and wait for Feedback.
            REPORT "Processor #6 | State of No Password Or Cleared Password Condition Met. Waiting for Feedback...";
            -- Waits for Testbench To Trigger Signals Required.
            WAIT UNTIL LED_LSTN_MODE = '1';

            WHILE (CL_PW_STORE_DCT_STATE_CODE /= 4) LOOP
                CL_PW_STORE_DCT_STATE_CODE <= 1;
                REPORT "Processor #6 | CL_PW_STORE_DCT_STATE_CODE has been set to Listen to Claps Mode. Iterating...";

                -- Requires with Respect to Claps of Min and Max.
                FOR ITERATION_INDEX IN 0 TO CLAP_WIDTH - 1 LOOP
                    -- This statement will cancel and wait for the claps again to record it to the storage.
                    IF BTN_DISCARD_CURR_SEQ = '1' THEN
                        REPORT "Processor #6 | Process Interrupted. Password to Storage Cancelled.";
                        CL_PW_STORE_DCT_STATE_CODE <= 3;
                        EXIT;
                    ELSE
                        -- CL_RT_CLK <= CL_RT_CLK + 1;
                        REPORT "Processor #6 | Iteration " & INTEGER'image(ITERATION_INDEX) & " Finished.";
                        WAIT FOR 1 SEC;
                    END IF;
                END LOOP;
                -- WAIT UNTIL CL_PW_STORE_DCT_STATE_CODE = 2;
                -- Once we finish the loop, Store the Password on PW_PTRN_ST.
                -- Keep in mind that the testbench will be the one to clear off PW_PTRN_RT!!!

                IF CL_PW_STORE_DCT_STATE_CODE /= 3 THEN
                    REPORT "Processor #6 | Checking for CLAP_WIDTH with PW_PTRN_RT (with Respect to CLAP_MIN_LEN_PW and CLAP_MAX_LEN_PW)";
                    WAIT FOR 10 MS; -- To compensate with the last bit.

                    FOR EACH_BIT_IDX IN 0 TO CLAP_WIDTH LOOP
                        IF PW_PTRN_RT(EACH_BIT_IDX) = '1' THEN
                            BIT_ON_COUNTER := BIT_ON_COUNTER + 1;
                        END IF;

                    END LOOP;

                    IF BTN_DISCARD_CURR_SEQ /= '1' AND BIT_ON_COUNTER >= CLAP_MIN_LEN_PW AND BIT_ON_COUNTER <= CLAP_MAX_LEN_PW THEN

                        CL_PW_STORE_DCT_STATE_CODE <= 4;
                        REPORT "Processor #6 | Signal Sent to Save the Password.";
                        WAIT FOR 250 MS;
                        CL_PW_STORE_DCT_STATE_CODE <= 0;
                        EXIT;
                    ELSE
                        IF BTN_DISCARD_CURR_SEQ = '1' THEN
                            REPORT "Processor #6 | Password Input has been interrupted.";
                            CL_PW_STORE_DCT_STATE_CODE <= 3; -- No need of process to handle PW_PTRN_RT.
                            WAIT FOR 1 SEC; -- Gives Compensation so that the user has the chance latch it away to avoid infinite loop.
                            -- Reset States.
                            BIT_ON_COUNTER := 0;
                            CL_PW_STORE_DCT_STATE_CODE <= 1; -- No need of process to handle PW_PTRN_RT.
                        ELSE

                            REPORT "Processor #6 | Password Input were not allowed because its not respecting CLAP_MIN_LEN_PW and CLAP_MAX_LEN_PW Constraints. (" & INTEGER'image(BIT_ON_COUNTER) & ")";
                            CL_PW_STORE_DCT_STATE_CODE <= 5; -- No need of process to handle PW_PTRN_RT.
                            WAIT FOR 250 MS;
                            -- Reset States.
                            BIT_ON_COUNTER := 0;

                            CL_PW_STORE_DCT_STATE_CODE <= 1; -- No need of process to handle PW_PTRN_RT.
                        END IF;
                    END IF;
                ELSE
                    NEXT; -- This assume that the value of CL_PW_STORE_DCT_STATE_CODE is 3!
                END IF;
                WAIT FOR 250 MS;
                CL_PW_STORE_DCT_STATE_CODE <= 0; -- No need of process to handle PW_PTRN_RT.
                -- REPORT "Setting Values Back To Normal Mode.";
            END LOOP;
            -- ELSE
            --     REPORT "Processor #6 | Possible Conflict of Condition Signals. (CL_PW_CLR_STATE_CODE,CL_PW_VECTOR_STATE_CODE) = " & INTEGER'image(CL_PW_CLR_STATE_CODE) & ", " & INTEGER'image(CL_PW_VECTOR_STATE_CODE);
        END IF;
    END PROCESS;

    -- Internal Component Processor #7 — Password Reset Functionality
    -- Password Modification to PW_PTRN_ST has been found on two processes.
    -- It's to play under each processes state and do modifications.

    -- HAS ISSUES.
    PROCESS IS
        VARIABLE PW_STORED_STATE : BOOLEAN := FALSE;
        VARIABLE PW_RESET_STATE : BOOLEAN := FALSE;
    BEGIN
        -- For Scenario only when user has already set a password and just wants to lock the vault.
        -- PW_PTRN_ST(1) <= '1';
        -- PW_PTRN_ST(3) <= '1';
        -- PW_PTRN_ST(5) <= '1';

        WAIT ON CL_PW_VECTOR_STATE_CODE, CL_PW_CLR_STATE_CODE, CL_PW_STORE_DCT_STATE_CODE;

        -- REPORT INTEGER'image(CL_PW_VECTOR_STATE_CODE) & INTEGER'image(CL_PW_CLR_STATE_CODE) & INTEGER'image(CL_PW_STORE_DCT_STATE_CODE);
        -- Has issues when it has malformed and can't reset.
        IF (CL_PW_VECTOR_STATE_CODE = 2 OR CL_PW_CLR_STATE_CODE = 5) AND CL_PW_STORE_DCT_STATE_CODE = 0 AND PW_RESET_STATE = FALSE THEN
            PW_STORED_STATE := TRUE;
            PW_RESET_STATE := FALSE;
            PW_PTRN_ST <= "00000000";
            FOR EACH_PW_INDEX IN 0 TO CLAP_WIDTH LOOP
                PW_PTRN_ST(EACH_PW_INDEX) <= '0';
                REPORT STD_LOGIC'image(PW_PTRN_ST(EACH_PW_INDEX));
            END LOOP;
            -- PW_PTRN_ST <= PW_PTRN_RT;
            REPORT "Processor #7 | Storage Password was Reset to Default (All Zeros).";

            -- Unclear.
        ELSIF CL_PW_STORE_DCT_STATE_CODE = 4 AND (CL_PW_VECTOR_STATE_CODE = 0 AND CL_PW_CLR_STATE_CODE = 0) AND PW_STORED_STATE = FALSE THEN
            PW_PTRN_ST <= PW_PTRN_RT;
            PW_STORED_STATE := TRUE;
            PW_RESET_STATE := FALSE;
            REPORT "Processor #7 | Storage Password was Saved.";
        END IF;
    END PROCESS;

    -- Internal Component Processor #8 | Set of Processes Status Code to Interpretable Status Display (Concurrent Overtime) (No Interrupts)
    -- Set of Process Async.
    -- This is the process that outputs rhe status of the system to a Seven Segment or an LCD Display in Status Abbreviation Form.
    -- Current List of Known Values for Each Processes.

    --      Pre-State of Processes, Before Setting Post-State of Clap Lock. (CL_XX_XX_[...])
    --          0. CL_XX_XX_.._DISP <= 'RDY'; -- Ready. -- Shared Across Except CL_PW_VECTOR_STATE_CODE.

    --      Password Vector Bit Shift Detection State + 1 (CL_PW_VECTOR_STATE_CODE)
    --          0. CL_PW_VECTOR_STATE_DISP <= 'OKY'; -- No Errors.
    --          1. CL_PW_VECTOR_STATE_DISP <= 'NPW'; -- No Password.
    --          2. CL_PW_VECTOR_STATE_DISP <= 'MPW'; -- Malformed Password. (CLAP_WIDTH doesn't get respected)

    --      No Password To Password Stored Detection State + 1 (CL_PW_STORE_DCT_STATE_CODE)
    --          1. CL_PW_STORE_DCT_DISP <= 'LTC'; --  Listening To Claps.
    --          2. CL_PW_STORE_DCT_DISP <= 'PRC'; -- Processing Claps.
    --          3. CL_PW_STORE_DCT_DISP <= 'IPR'; -- Interrupted Process. — BTN_DISCARD_CURR_SEQ
    --          4. CL_PW_STORE_DCT_DISP <= 'PWS'; -- Password Stored.
    --          5. CL_PW_STORE_DCT_DISP <= 'CNM'; -- Constraints Not Met.

    --      Password Clearing Phase + 1 (CL_PW_CLR_STATE_CODE)
    --          1. CL_PW_CLR_STATE_DISP <= 'IPW'; -- Inputting Password.
    --          2. CL_PW_CLR_STATE_DISP <= 'CBS'; -- Checking Button Sequence.
    --          3. CL_PW_CLR_STATE_DISP <= 'CPW'; -- Process Interrupted.
    --          4. CL_PW_CLR_STATE_DISP <= 'ICP'; -- Invalid To Clear Password.
    --          5. CL_PW_CLR_STATE_DISP <= 'CLR'; -- Cleared Password.

    --      Post-State of Clap Lock (After Multiple Statement Displays) Default. (CL_POST_STATE_CODE)
    --          0. CL_POST_STATE_DISP <= 'ULK'; -- Unlocked Mode.
    --          1. CL_POST_STATE_DISP <= 'LKD'; -- Locked Mode.

    --      Runtime Listening Mode from Lock to Unlock Phase + 1 (CL_TO_UNLCK_LSTN_STATE_CODE)
    --          1. CL_TO_UNLCK_LSTN_STATE_DISP <= 'LTC'; --  Listening To Claps.
    --          2. CL_TO_UNLCK_LSTN_STATE_DISP <= 'PWV'; -- Password Validation.
    --          3. CL_TO_UNLCK_LSTN_STATE_DISP <= 'IPR'; -- Interrupted Process. — BTN_DISCARD_CURR_SEQ
    --          4. CL_TO_UNLCK_LSTN_STATE_DISP <= 'IPW'; -- Invalid Password.

    --      For Unlock To Lock Phase (CL_TO_LCK_LSTN_STATE_CODE)
    --          1. CL_TO_LCK_LSTN_STATE_DISP <= 'QLC'; -- Quick Listening Clap Mode.
    --          2. CL_TO_LCK_LSTN_STATE_DISP <= 'VTL'; -- Invalid To Locking Phase.
    --          3. CL_TO_LCK_LSTN_STATE_DISP <= 'ITL'; -- Valid To Locking Phase.

    PROCESS (CL_PW_VECTOR_STATE_CODE) IS
    BEGIN
        CASE CL_PW_VECTOR_STATE_CODE IS
            WHEN 0 =>
                CL_PW_VECTOR_STATE_DISP <= "OKY";
            WHEN 1 =>
                CL_PW_VECTOR_STATE_DISP <= "NPW";
            WHEN 2 =>
                CL_PW_VECTOR_STATE_DISP <= "MPW";
            WHEN OTHERS =>
                CL_PW_VECTOR_STATE_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_PW_STORE_DCT_STATE_CODE) IS
    BEGIN
        CASE CL_PW_STORE_DCT_STATE_CODE IS
            WHEN 0 =>
                CL_PW_STORE_DCT_DISP <= "RDY";
            WHEN 1 =>
                CL_PW_STORE_DCT_DISP <= "LTC";
            WHEN 2 =>
                CL_PW_STORE_DCT_DISP <= "PRC";
            WHEN 3 =>
                CL_PW_STORE_DCT_DISP <= "IPR";
            WHEN 4 =>
                CL_PW_STORE_DCT_DISP <= "PWS";
            WHEN 5 =>
                CL_PW_STORE_DCT_DISP <= "CNM";
            WHEN OTHERS =>
                CL_PW_STORE_DCT_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_PW_CLR_STATE_CODE) IS
    BEGIN
        CASE CL_PW_CLR_STATE_CODE IS
            WHEN 0 =>
                CL_PW_CLR_STATE_DISP <= "RDY";
            WHEN 1 =>
                CL_PW_CLR_STATE_DISP <= "IPW";
            WHEN 2 =>
                CL_PW_CLR_STATE_DISP <= "CBS";
            WHEN 3 =>
                CL_PW_CLR_STATE_DISP <= "CPW";
            WHEN 4 =>
                CL_PW_CLR_STATE_DISP <= "ICP";
            WHEN 5 =>
                CL_PW_CLR_STATE_DISP <= "CLR";
            WHEN OTHERS =>
                CL_PW_CLR_STATE_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_POST_STATE_CODE) IS
    BEGIN
        CASE CL_POST_STATE_CODE IS
            WHEN 0 =>
                CL_POST_STATE_DISP <= "ULK";
            WHEN 1 =>
                CL_POST_STATE_DISP <= "LKD";
            WHEN OTHERS =>
                CL_POST_STATE_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_TO_UNLCK_LSTN_STATE_CODE) IS
    BEGIN
        CASE CL_TO_UNLCK_LSTN_STATE_CODE IS
            WHEN 0 =>
                CL_TO_UNLCK_LSTN_STATE_DISP <= "RDY";
            WHEN 1 =>
                CL_TO_UNLCK_LSTN_STATE_DISP <= "LTC";
            WHEN 2 =>
                CL_TO_UNLCK_LSTN_STATE_DISP <= "PWV";
            WHEN 3 =>
                CL_TO_UNLCK_LSTN_STATE_DISP <= "IPR";
            WHEN 4 =>
                CL_TO_UNLCK_LSTN_STATE_DISP <= "IPW";
            WHEN OTHERS =>
                CL_TO_UNLCK_LSTN_STATE_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_TO_LCK_LSTN_STATE_CODE) IS
    BEGIN
        CASE CL_TO_LCK_LSTN_STATE_CODE IS
            WHEN 0 =>
                CL_TO_LCK_LSTN_STATE_DISP <= "RDY";
            WHEN 1 =>
                CL_TO_LCK_LSTN_STATE_DISP <= "QLC";
            WHEN 2 =>
                CL_TO_LCK_LSTN_STATE_DISP <= "ITL";
            WHEN 3 =>
                CL_TO_LCK_LSTN_STATE_DISP <= "VTL";
            WHEN OTHERS =>
                CL_TO_LCK_LSTN_STATE_DISP <= "NKN";
        END CASE;
    END PROCESS;
END ARCHITECTURE;