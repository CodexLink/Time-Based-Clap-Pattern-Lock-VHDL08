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
        BTN_ACK_SEQ_RST, BTN_DISCARD_CURR_SEQ : IN STD_LOGIC := '0';
        CL_MIC_DTCTR : IN STD_LOGIC := '0'; -- MIC that detects clap.
        CL_RT_CLK : OUT INTEGER RANGE 0 TO CLAP_WIDTH; -- + 2 because, on + 1, becauase of WHILE Compensation.

        -- These CL status were divided due to One Process One Signal Drive!
        -- Keep in mind that, the use of Zero-Index is applied here.
        -- This means that instead providing of 5 DOWNTO 0 for a Size of 5.
        -- It was done to 4 DOWNTO 0.

        CL_PW_PHASE_DISP : OUT STRING (1 TO 3) := "RDY";
        CL_POST_STATE_DISP : OUT STRING (1 TO 3) := "LKD";
        CL_LSTN_PHASE_DISP : OUT STRING (1 TO 3) := "RDY";
        CL_TO_LCK_PHASE_DISP : OUT STRING (1 TO 3) := "RDY";

        CL_PW_PHASE_STATUS : OUT INTEGER RANGE 0 TO 3 := 0;
        CL_POST_STATE_STATUS : OUT INTEGER RANGE 0 TO 1 := 0;
        CL_LSTN_PHASE_STATUS : OUT INTEGER RANGE 0 TO 3 := 0;
        CL_TO_LCK_PHASE_STATUS : OUT INTEGER RANGE 0 TO 2 := 0;

        CL_TO_LCK_CLAP_SLTS : OUT STD_LOGIC_VECTOR (CLAP_CNT_TO_LCK_PH DOWNTO 0) := (OTHERS => '0'); -- Clap Slots for Locking Phase.
        LED_SEC_BLINK_DISP : IN STD_LOGIC := '0'; -- LED Indicator for each time passed. Turns of Before Phasing to Another Second.
        LED_LSTN_MODE : IN STD_LOGIC := '0'; -- LED Listening Mode Indicator
        PW_PTRN_RT : IN STD_LOGIC_VECTOR (CLAP_WIDTH DOWNTO 0) := (OTHERS => '0'); -- Runtime Storage
        PW_PTRN_ST : IN STD_LOGIC_VECTOR (CLAP_WIDTH DOWNTO 0) := (OTHERS => '0') -- Last Known Storage
    );

END CLAP_LOCK_VHDL;

ARCHITECTURE CL_DIGITAL_SIM OF CLAP_LOCK_VHDL IS
BEGIN

    -- Realtime Clock for Runtime.
    -- Only runs everytime LED_LSTN_MODE bit is True or 1.
    PROCESS IS
        VARIABLE RUNTIME_COUNT : INTEGER := 0;
        VARIABLE IS_INTERRUPTED : BOOLEAN := FALSE;
    BEGIN

        WAIT UNTIL LED_LSTN_MODE = '1';
        CL_LSTN_PHASE_STATUS <= 1;

        REPORT "Triggered because LED_LSTN_MODE is one.";
        WHILE (RUNTIME_COUNT < CLAP_WIDTH) LOOP
            WAIT FOR 1 SEC;

            REPORT "The value of BTN_DISCARD_CURR_SEQ is " & STD_LOGIC'image(BTN_DISCARD_CURR_SEQ) & " and LED_LSTN_MODE is " & STD_LOGIC'image(LED_LSTN_MODE);
            IF (BTN_DISCARD_CURR_SEQ = '0' AND LED_LSTN_MODE = '1') THEN

                -- Count over time, for incrementation with respect to CLAP_WIDTH.
                CL_RT_CLK <= CL_RT_CLK + 1;
                IS_INTERRUPTED := TRUE;
                RUNTIME_COUNT := RUNTIME_COUNT + 1;
                REPORT "Has been triggered on time.";

            ELSE
                -- Reset the whole system state to Locked Mode.
                CL_PW_PHASE_STATUS <= 3;
                CL_RT_CLK <= 0;
                IS_INTERRUPTED := FALSE;
                RUNTIME_COUNT := 0;
                REPORT "Has been finish in ELSE.";

            END IF;
        END LOOP;

        -- ADD SOME STATE HERE FOR COMPENSATING FOR PASSWORD VALIDATION MODE.

        IF IS_INTERRUPTED THEN
            CL_PW_PHASE_STATUS <= 2;
        ELSE
            CL_PW_PHASE_STATUS <= 3;
        END IF;

        CL_RT_CLK <= 0;
        RUNTIME_COUNT := 0;
        REPORT "Has been reset with finished loop.";

    END PROCESS;

    -- Runtime Unlock to Lock Phase Processor — UNTESTED!
    -- It is a process that checks for another set claps in a short time limit.
    -- to set the lock as a literal Locked Mode.
    PROCESS IS
        VARIABLE CLAP_SLOT_ITER : INTEGER := 0;
        VARIABLE VERIFIED_TO_LCK_PH : BOOLEAN := FALSE;
    BEGIN

        -- Wait until we hear a clap and other such factors.
        -- There are lots of things to consider before processing this one.

        WAIT UNTIL LED_LSTN_MODE = '1'; -- Must be Listening Mode.
        WAIT UNTIL CL_MIC_DTCTR = '1'; -- Which Should Be Detecting Clap in the First Place.
        WAIT UNTIL CL_POST_STATE_STATUS = 1; -- Should be Unlocked Mode.

        -- Once a clap was heard, register the first clap so that we wont be getting delays.
        CL_TO_LCK_CLAP_SLTS(0) <= '1';
        CLAP_SLOT_ITER := CLAP_SLOT_ITER + 1;

        -- Iterate the remaining claps before processing to Locked Mode.
        -- The remaining clap slots will iterate even when not detecting the claps.
        -- This means that the system will disgard it if the clap under constraint intervals did not meet.

        WHILE (CLAP_SLOT_ITER < CLAP_CNT_TO_LCK_PH) LOOP
            WAIT FOR CLAP_SLOT_INTERVAL_TO_LOCK; -- Wait for certain MS or whatever the constraint is before checkinf for the detection of claps.
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
                -- Reset everything when returning to Locking State.
                -- LED_LSTN_MODE <= '0';
                -- CL_MIC_DTCTR <= '0';
                CL_TO_LCK_PHASE_STATUS <= 1;
                -- Reset the Runtime Password Pattern Storage HERE!
                REPORT "Claps Verified with Timeframe Correct. Switching to Locked Mode.";
            ELSE
                -- Or else, repeat this process by manipulating the state.
                CL_TO_LCK_PHASE_STATUS <= 2; -- Quick Spike before returning to Process Execution of this Process.
                REPORT "Claps Incomplete, Retained Locked Mode.";
            END IF;
        END LOOP;

    END PROCESS;

    -- Locking or Unlocking Phase Mechanism — UNTESTED!
    -- This process assumes that PW_PTRN_ST contains DATA!
    --
    -- This is where the comparison happens between PW_PTRN_RT and PW_PTRN_ST.

    PROCESS IS
    BEGIN
        WAIT UNTIL CL_LSTN_PHASE_STATUS = 2;
        REPORT "Password Checking Is Here!";
        IF PW_PTRN_RT = PW_PTRN_ST THEN
            CL_POST_STATE_STATUS <= 0;
            REPORT "The Lock is in Unlocked State.";
        ELSE
            CL_POST_STATE_STATUS <= 1;
            REPORT "The Lock is in Locked State.";
            REPORT "The state should be running a process that gets data.";
        END IF;

    END PROCESS;

    -- -- Reset Runtime Storage Mechanism
    -- -- A process that can be triggered everytime a user makes mistakes.
    -- -- It resets the runtime container and resets the whole mechanism.
    -- PROCESS ()
    -- BEGIN

    -- END PROCESS;

    -- -- Reset Password on Storage Mechanism
    -- -- This is the process that runs after pressing RST_STORAGE button and listens for sequence.
    -- PROCESS ()
    -- BEGIN

    -- END PROCESS;

    -- A Set of Processes Status Code to Interpretable Seven Display
    -- This is the process that output status of the system to a Seven Segment or an LCD Display.
    -- We can do Abbreviation only.

    -- Current List of Known Values for Each Processes.

    --      Pre-State of Processes, Before Setting Post-State of Clap Lock.
    --          0. CL_XX_XX_.._DISP <= 'RDY'; -- Ready. -- Shared Across.

    --      Password Clearing Phase + 2
    --          1. CL_PW_PHASE_DISP <= 'NPW'; -- No Password or Cleared Password.
    --          2. CL_PW_PHASE_DISP <= 'CPW'; -- Changed Password.
    --          3. CL_PW_PHASE_DISP <= 'ICP'; -- Invalid To Clear Password

    --      Post-State of Clap Lock (After Multiple Statement Displays) Default.
    --          0. CL_POST_STATE_DISP <= 'ULK'; -- Unlocked Mode.
    --          1. CL_POST_STATE_DISP <= 'LKD'; -- Locked Mode.

    --      Runtime Listening Mode from Lock to Unlock Phase + 2
    --          1. CL_LSTN_PHASE_DISP <= 'PCL'; --  Processing Claps — Listen Mode.
    --          2. CL_LSTN_PHASE_DISP <= 'PWV'; -- Password Validation.
    --          3. CL_LSTN_PHASE_DISP <= 'IPR'; -- Interrupted Process. — BTN_DISCARD_CURR_SEQ
    --      For Unlock To Lock Phase + 2
    --          1. CL_TO_LCK_PHASE_DISP <= 'VTL'; -- Valid To Locking Phase.
    --          2. CL_TO_LCK_PHASE_DISP <= 'ITL'; -- Invalid To Locking Phase.

    PROCESS (CL_PW_PHASE_STATUS) IS
    BEGIN
        CASE CL_PW_PHASE_STATUS IS
            WHEN 0 =>
                CL_PW_PHASE_DISP <= "RDY";
            WHEN 1 =>
                CL_PW_PHASE_DISP <= "NPW";
            WHEN 2 =>
                CL_PW_PHASE_DISP <= "CPW";
            WHEN 3 =>
                CL_PW_PHASE_DISP <= "ICP";
            WHEN OTHERS =>
                CL_PW_PHASE_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_POST_STATE_STATUS) IS
    BEGIN
        CASE CL_POST_STATE_STATUS IS
            WHEN 0 =>
                CL_POST_STATE_DISP <= "LKD";
            WHEN 1 =>
                CL_POST_STATE_DISP <= "ULK";
            WHEN OTHERS =>
                CL_POST_STATE_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_LSTN_PHASE_STATUS) IS
    BEGIN
        CASE CL_LSTN_PHASE_STATUS IS
            WHEN 0 =>
                CL_LSTN_PHASE_DISP <= "RDY";
            WHEN 1 =>
                CL_LSTN_PHASE_DISP <= "PCL";
            WHEN 2 =>
                CL_LSTN_PHASE_DISP <= "PWV";
            WHEN 3 =>
                CL_LSTN_PHASE_DISP <= "IPR";
            WHEN OTHERS =>
                CL_LSTN_PHASE_DISP <= "NKN";
        END CASE;
    END PROCESS;

    PROCESS (CL_TO_LCK_PHASE_STATUS) IS
    BEGIN
        CASE CL_TO_LCK_PHASE_STATUS IS
            WHEN 0 =>
                CL_TO_LCK_PHASE_DISP <= "RDY";
            WHEN 1 =>
                CL_TO_LCK_PHASE_DISP <= "ITL";
            WHEN 2 =>
                CL_TO_LCK_PHASE_DISP <= "VTL";
            WHEN OTHERS =>
                CL_TO_LCK_PHASE_DISP <= "NKN";
        END CASE;
    END PROCESS;
END ARCHITECTURE;