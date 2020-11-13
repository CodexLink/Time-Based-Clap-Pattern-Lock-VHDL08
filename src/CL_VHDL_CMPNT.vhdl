LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

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
        BTN_RST_SEQUENCER, BTN_DISCARD_CURR_SEQ : IN STD_LOGIC := '0';

        CL_MIC_DTCTR : IN STD_LOGIC := '0'; -- MIC that detects clap.
        CL_RT_CLK : OUT INTEGER RANGE 0 TO CLAP_WIDTH; -- + 2 because, on + 1, becauase of WHILE Compensation.

        -- These CL status were divided due to One Process, One Signal Drive!
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
        -- Clap Signals Integer State Signals
        CL_PW_VECTOR_STATE_CODE : OUT INTEGER RANGE 0 TO 2 := 0;
        CL_PW_CLR_STATE_CODE : OUT INTEGER RANGE 0 TO 5 := 0;
        CL_PW_STORE_DCT_STATE_CODE : OUT INTEGER RANGE 0 TO 4 := 0;
        CL_POST_STATE_CODE : OUT INTEGER RANGE 0 TO 1 := 0;
        CL_TO_UNLCK_LSTN_STATE_CODE : OUT INTEGER RANGE 0 TO 4 := 0;
        CL_TO_LCK_LSTN_STATE_CODE : OUT INTEGER RANGE 0 TO 3 := 0;
        -- Clap Slots (Specifically for Unlocked to Lock Mechanism)
        CL_TO_LCK_CLAP_SLTS : OUT STD_LOGIC_VECTOR (CLAP_CNT_TO_LCK_PH DOWNTO 0) := (OTHERS => '0'); -- Clap Slots for Locking Phase.
        -- LED Diode Displays
        LED_SEC_BLINK_DISP : IN STD_LOGIC := '0'; -- Time Second Rising Edge Indicator.
        LED_LSTN_MODE : IN STD_LOGIC := '0'; -- Listening Mode Indicator
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
    BEGIN
        -- Pre-requisites:
        -- It waits until :
        WAIT FOR 500 MS;

        -- There will be two loops for initialization!

        -- Checks the container if is malformed or has no password.
        -- We don't wanna check by statically declaring a bits of zeros since the width is dynamic.
        FOR eachIndexST IN 0 TO CLAP_WIDTH LOOP
            IF PW_PTRN_ST(eachIndexST) = '0' THEN
                HAS_NO_PASSWORD := TRUE;
                EXIT;
            END IF;
        END LOOP;

        IF HAS_NO_PASSWORD THEN
            CL_PW_VECTOR_STATE_CODE <= 1; --NPW, Sets to No Password State.
            -- We wait until it has been resolved.
            WAIT UNTIL CL_PW_STORE_DCT_STATE_CODE = 4;
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
            IF PW_CLAP_COUNT_HANDLER >= CLAP_WIDTH AND PW_CLAP_COUNT_HANDLER <= CLAP_WIDTH THEN
                CL_PW_VECTOR_STATE_CODE <= 0; -- RDY, All Clear.
            ELSE
                REPORT "Password is Malformed, Resetting Password in 1 Second.";
                CL_PW_VECTOR_STATE_CODE <= 2; -- MPW

                WAIT FOR 1 SEC;
                -- In the testbench, you have to clear the password there!
                -- A seperate process might be nice. But, let's see if that is gonna work.

                FOR EACH_INDEX IN 0 TO CLAP_WIDTH LOOP
                    PW_PTRN_ST(EACH_INDEX) <= '0';
                END LOOP;
                CL_PW_VECTOR_STATE_CODE <= 1;
                REPORT "Password has been reset.";

            END IF;
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
        WAIT UNTIL CL_MIC_DTCTR = '1'; -- 1.1. System detects a Clap was heard.
        WAIT UNTIL LED_LSTN_MODE = '1'; -- 1.2. With LED being turned on as well.
        WAIT UNTIL CL_PW_CLR_STATE_CODE = 0; -- 2. Password State Phase is on State 'Ready'.
        WAIT UNTIL CL_POST_STATE_CODE = 1; -- 3. Post State of the System Indicates the Lock was in Locked Mode.
        WAIT UNTIL CL_TO_UNLCK_LSTN_STATE_CODE = 0; -- 4. Listen Phase was Prematurely on Ready State Before Shifting to LTC Mode.
        WAIT UNTIL CL_TO_LCK_LSTN_STATE_CODE = 0; -- 5. Unlock To Lock Phase State should still be in RDY State.
        WAIT UNTIL CL_PW_VECTOR_STATE_CODE = 0; -- 6. Password Storage Malform Detection should be in OKY State.
        WAIT UNTIL CL_PW_STORE_DCT_STATE_CODE = 0; -- 7. No Password To Password Detection should be in RDY State.

        -- Set Listen Phase Status to Listen Mode.
        CL_TO_UNLCK_LSTN_STATE_CODE <= 1; -- LTC

        REPORT "Realtime Clock of Runtime Clap Processor Process Triggered.";

        -- Run the Iteration in Seconds delay.
        FOR RUNTIME_CNT_SEC IN 0 TO CLAP_WIDTH LOOP

            -- Wait for 1 Second Here To Compensate with 0 Second shifting to 1 Second.
            WAIT FOR 1 SEC;

            -- Checks with Excemption for CL_MIC_DTCTR. Because user could skip certain seconds for pattern.
            IF (BTN_DISCARD_CURR_SEQ = '0' AND LED_LSTN_MODE = '1') THEN

                -- Count over time, for incrementation with respect to CLAP_WIDTH, when true.
                -- Set Sequence Iteration Not Interrupted and Iterate Runtimes.

                CL_RT_CLK <= CL_RT_CLK + 1;
                IS_SEQ_ITER_INTERRUPTED := FALSE;

                REPORT "Triggered in IF.";

            ELSE
                -- Reset the Whole System State to Locked Mode.
                -- Set Sequence Iteration Interrupted and Iterate Runtimes to Zero.

                CL_RT_CLK <= 0;
                IS_SEQ_ITER_INTERRUPTED := TRUE;
                EXIT;

                REPORT "Triggered in ELSE.";

            END IF;
        END LOOP;

        IF IS_SEQ_ITER_INTERRUPTED THEN
            CL_TO_UNLCK_LSTN_STATE_CODE <= 3; -- IPR
        ELSE
            CL_TO_UNLCK_LSTN_STATE_CODE <= 2; -- PWV
        END IF;

        -- Cleanup Of Signals.
        -- Note that, I don't need to clear the Microphone and LED Status Here.
        -- It should be done after Iteration in the Testbench!
        -- Some signals has to be reverted back to a default value. Not sure if after scope will revert it back!
        CL_RT_CLK <= 0;
        -- Before we clear, we wait for the changes of this signal.
        WAIT ON CL_POST_STATE_CODE;
        CL_TO_UNLCK_LSTN_STATE_CODE <= 0;
        -- IS_SEQ_ITER_INTERRUPTED := FALSE; -- Check if it resets.
        REPORT "Realtime Clock of Runtime Clap Processor Process is Finished.";
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

    PROCESS (CL_TO_UNLCK_LSTN_STATE_CODE, CL_TO_LCK_LSTN_STATE_CODE) IS
    BEGIN

        REPORT "Password Checking Is Here!";

        -- Two Signals on Sensitivity List shouldn't have the same value!
        -- They should contain distinct values with another other to trigger certain signal modifications.
        -- Result of Conflict from Conditionals will only REPORT Not-So-Error Message. (See ELSE Clause Part.)
        IF CL_TO_UNLCK_LSTN_STATE_CODE = 2 AND CL_TO_LCK_LSTN_STATE_CODE = 0 THEN
            IF PW_PTRN_RT = PW_PTRN_ST THEN
                CL_POST_STATE_CODE <= 0;
                REPORT "The Lock is in Unlocked State.";
            ELSE
                CL_POST_STATE_CODE <= 1;
                REPORT "The Lock is in Locked State.";
            END IF;
        ELSIF CL_TO_LCK_LSTN_STATE_CODE = 2 AND CL_TO_UNLCK_LSTN_STATE_CODE = 0 THEN
            CL_POST_STATE_CODE <= 1;
            REPORT "The Lock is in Locked State caused by Unlock To Lock.";
        ELSIF CL_TO_LCK_LSTN_STATE_CODE = 0 AND CL_TO_UNLCK_LSTN_STATE_CODE = 0 THEN
            REPORT "On Initial Values, Ignored.";
        ELSE
            REPORT "Possible Conflict of Values. Have you tried changing other values of other signals???";
        END IF;

        CL_POST_STATE_CODE <= 0;

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
        VARIABLE VERIFIED_TO_LCK_PH : BOOLEAN := FALSE;
    BEGIN

        -- Pre-requisites
        -- It waits until :
        WAIT UNTIL CL_MIC_DTCTR = '1'; -- 1.1. System detects a Clap was heard.
        WAIT UNTIL LED_LSTN_MODE = '1'; -- 1.2. With LED being turned on as well.
        WAIT UNTIL CL_PW_CLR_STATE_CODE = 0; -- 2. Password Clearing Phase is on State Phase 'Ready'.
        WAIT UNTIL CL_POST_STATE_CODE = 0; -- 3. Post State of the System Indicates that the Lock was in Unlocked Mode.
        WAIT UNTIL CL_TO_UNLCK_LSTN_STATE_CODE = 0; -- 4. Listen Phase during Unlocking was on State 'Ready'.
        WAIT UNTIL CL_TO_LCK_LSTN_STATE_CODE = 1; -- 5. Listen Phase during Locking was on State 'QLC'.
        WAIT UNTIL CL_PW_VECTOR_STATE_CODE = 0; -- 6. -- 6. Password Storage Malform Detection should be in OKY State.
        WAIT UNTIL CL_PW_STORE_DCT_STATE_CODE = 0; -- 7. -- 7. No Password To Password Detection should be in RDY State.

        -- Once a clap was heard, register the first clap so that we won''t be getting delays.
        -- Increment the index from zeroth to first index.
        CL_TO_LCK_CLAP_SLTS(0) <= CL_MIC_DTCTR;
        CLAP_SLOT_ITER := CLAP_SLOT_ITER + 1;

        -- Iterate the remaining claps required before processing to Locked Mode.
        -- The remaining clap slots will iterate even when not detecting the claps.
        -- This means that the system will disgard it if the clap under constraint intervals did not meet.

        -- This part of the process DOES NOT manipulate the input. Testbench process is required.

        WHILE (CLAP_SLOT_ITER < CLAP_CNT_TO_LCK_PH) LOOP
            WAIT FOR CLAP_SLOT_INTERVAL_TO_LOCK; -- Wait for certain MS or whatever the constraint is before checking for the detection of claps.
            CL_TO_LCK_CLAP_SLTS(CLAP_SLOT_ITER) <= CL_MIC_DTCTR;
            CLAP_SLOT_ITER := CLAP_SLOT_ITER + 1;
        END LOOP;

        -- Verify if the Claps contains all ones.
        -- Or else, dismiss the request of Locking Phase.

        FOR eachClapsSlots IN 0 TO CLAP_CNT_TO_LCK_PH LOOP
            IF CL_TO_LCK_CLAP_SLTS(eachClapsSlots) = '1' THEN
                VERIFIED_TO_LCK_PH := TRUE;
                NEXT; -- Iterate next.
            ELSE
                VERIFIED_TO_LCK_PH := FALSE;
                EXIT; -- Breaking the loop here.
            END IF;

            IF VERIFIED_TO_LCK_PH THEN
                -- Reset the Runtime Password Pattern Storage HERE!
                -- Reset everything when returning to Locking State.
                -- LED_LSTN_MODE <= '0';
                -- CL_MIC_DTCTR <= '0';
                CL_TO_LCK_LSTN_STATE_CODE <= 2; -- VTL
                REPORT "Claps Verified with Timeframe Correct. Switching to Locked Mode.";
            ELSE
                -- Or else, repeat this process by manipulating the state.
                CL_TO_LCK_LSTN_STATE_CODE <= 3; -- Quick Spike before returning to Process Execution of this Process.
                WAIT FOR 250 MS;

                -- Wait for 250 MS Before rerunning this process.
                CL_TO_LCK_LSTN_STATE_CODE <= 1; -- Quick Spike before returning to Process Execution of this Process.
                REPORT "Claps Incomplete, Retained Locked Mode.";
            END IF;
        END LOOP;
        CL_TO_LCK_LSTN_STATE_CODE <= 0;
    END PROCESS;

    -- Internal Component Processor #5 — Reset Password on Storage Mechanism (Has Interrupts)
    -- Password Resetter.
    -- Description    : Resets Password by Filling Patterns Per Second with Button Instead of Clap.

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

        CL_PW_CLR_STATE_CODE <= 1; -- Allow Proces To Set Password.

        -- Iterate the remaining claps required before processing to Locked Mode.
        -- The remaining clap slots will iterate even when not detecting the claps.
        -- This means that the system will disgard it if the clap under constraint intervals did not meet.

        -- This part of the process DOES NOT manipulate the input. Testbench process is required.

        WAIT UNTIL CL_PW_CLR_STATE_CODE = 2; -- We wait for the input before attempt to check more.

        -- Verify The Buttons Sequence (also known as PW_PTRN_RT) with the PW_PTRN_ST.
        IF PW_PTRN_RT = PW_PTRN_ST THEN
            -- We cannot set the password of the storage here!
            FOR EACH_INDEX IN 0 TO CLAP_WIDTH LOOP
                PW_PTRN_ST(EACH_INDEX) <= '0';
            END LOOP;

            REPORT "Password Cleared.";
            CL_PW_CLR_STATE_CODE <= 3;
        ELSE
            REPORT "Invalid To Clear Password.";
            CL_PW_CLR_STATE_CODE <= 2;
        END IF;
        CL_PW_CLR_STATE_CODE <= 0;
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
    BEGIN

        WAIT ON CL_PW_CLR_STATE_CODE, CL_PW_VECTOR_STATE_CODE; -- Waits when it was Cleared for Password.

        IF CL_PW_CLR_STATE_CODE = 5 OR CL_PW_VECTOR_STATE_CODE = 1 THEN
            -- Set to Ready To Listen and wait for Feedback.
            CL_PW_STORE_DCT_STATE_CODE <= 2;

            WAIT UNTIL CL_MIC_DTCTR = '1';
            WAIT UNTIL LED_LSTN_MODE = '1';

            WAIT UNTIL CL_PW_STORE_DCT_STATE_CODE = 2;

            -- Once we finish the loop, Store the Password on PW_PTRN_ST.
            -- Keep in mind that the testbench will be the one to clear off PW_PTRN_RT!!!

            REPORT "Saving New Password...";
            PW_PTRN_ST <= PW_PTRN_RT;
            CL_PW_STORE_DCT_STATE_CODE <= 3;
            REPORT "Password Saved.";

            CL_PW_STORE_DCT_STATE_CODE <= 0;

            -- REPORT "Setting Values Back To Normal Mode.";
        ELSE
            REPORT "Possible Conflict of Condition Signals.";
        END IF;
    END PROCESS;

    -- Internal Component Processor #7 | Set of Processes Status Code to Interpretable Status Display (Concurrent Overtime) (No Interrupts)
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

    --      Password Clearing Phase + 1 (CL_PW_CLR_STATE_CODE)
    --          1. CL_PW_CLR_STATE_DISP <= 'CPW'; -- Inputting Password.
    --          2. CL_PW_CLR_STATE_DISP <= 'CBS'; -- Checking Button Sequence.
    --          3. CL_PW_CLR_STATE_DISP <= 'CPW'; -- Process Interrupted.
    --          4. CL_PW_CLR_STATE_DISP <= 'ICP'; -- Invalid To Clear Password.
    --          5. CL_PW_CLR_STATE_DISP <= 'CPW'; -- Cleared Password.

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
            WHEN OTHERS =>
                CL_PW_STORE_DCT_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_PW_CLR_STATE_CODE) IS
    BEGIN
        CASE CL_PW_CLR_STATE_CODE IS
            WHEN 0 =>
                CL_PW_CLR_STATE_DISP <= "CPW";
            WHEN 1 =>
                CL_PW_CLR_STATE_DISP <= "CBS";
            WHEN 2 =>
                CL_PW_CLR_STATE_DISP <= "CPW";
            WHEN 4 =>
                CL_PW_CLR_STATE_DISP <= "ICP";
            WHEN 5 =>
                CL_PW_CLR_STATE_DISP <= "CPW";
            WHEN OTHERS =>
                CL_PW_CLR_STATE_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_POST_STATE_CODE) IS
    BEGIN
        CASE CL_POST_STATE_CODE IS
            WHEN 0 =>
                CL_POST_STATE_DISP <= "LKD";
            WHEN 1 =>
                CL_POST_STATE_DISP <= "ULK";
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