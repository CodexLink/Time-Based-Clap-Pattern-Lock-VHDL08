# VHDL_Clap_Lock

Clap Lock Mechanism in Lower-Level Machine Implementation | A 4-Member Team VHDL Project in CPE 016 — Introduction to VHDL


Todo:

Due to time constraints that were given weren't enough. I have listed the things that I could have done but decided to postponed it for now.

I promise to have it finished before doing any other projects.

- Separate PW_PTRN_RT from Testbench to Module File with INOUT Port Mode.
- Make LED Turn ON (via Process) in Module instead of Testbench, whenever CL_MIC_DTCTR is on.
- Make LED_SEC_BLINK_DISP blink according to changes on CL_RT_CLK.
- Make Type to Remove CL_XX_XX_XX_CODE and retain only CL_XX_XX_XX_DISP.
- Attempt to consolidate redundant iterations to one processor.
- Implement Max With CLAP_WIDTH of 8. (Because we are in 8-bit.) Requires investigation.
- Create Unittests that breaks down the test bench's functionality (from the demo).
- Implement Timer Display for the sake of knowning the nth second for nth pattern.