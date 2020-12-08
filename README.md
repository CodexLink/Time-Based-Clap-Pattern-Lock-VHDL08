<h1 align="center">Time-Based Clap-Pattern Lock</h1>
<h4 align="center">A Time-Based Clap Lock Mechanism in Lower-Level Machine Implementation.</h4>

<h4 align="center">Created by a 4-Member Team VHDL Project in CPE 016 — Introduction to VHDL | Implemented in VHDL 2008.</h4>

<div align="center">

<!-- [![CodeFactor](https://www.codefactor.io/repository/github/codexlink/tasktoremindme/badge)](https://www.codefactor.io/repository/github/codexlink/tasktoremindme)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/6c3ef6df0d4c4ffebdd5099b4b87e3e6)](https://www.codacy.com/manual/CodexLink/TaskToRemindMe?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=CodexLink/TaskToRemindMe&amp;utm_campaign=Badge_Grade)
[![Repository Downloads](https://badgen.net/github/assets-dl/CodexLink/TaskToRemindMe_CPlusPlus)](https://github.com/CodexLink/TaskToRemindMe_CPlusPlus)
[![Repository License](https://badgen.net/github/license/CodexLink/TaskToRemindMe_CPlusPlus)](https://github.com/CodexLink/TaskToRemindMe_CPlusPlus) -->

</div>

## 👋 Welcome

Hello! This is a repository dedicated to show the concept and the implementation behind the Clap Lock in VHDL.

## ❗ Disclaimer

The repository is **free-of-charge** and is under [MIT License](https://github.com/CodexLink/Time-Based_Clap-Pattern-Lock_VHDL08/blob/master/LICENSE), so you can fork and make changes without me being notified about it.

Also, keep in mind that, the implementation on this branch is heavily confusing because of how VHDL handles signals and how they make it hard as possible to drive certain signals and things and other such. I'm not sure if I wanna **rewrite** it, because of the convienience of the IDE such as `ModelSim` is **not so great after all**.

And last, but not the least, expect it to be really confusing but it **works**. We made this project in time interval of **3 DAYS**.

## 🚦 Getting Started

In this part of the README, you will learn how to setup from cloning / forking the repository to the simulation process.

### ❓ Pre-requisites

In order to get started, as literally, get started, you must have the following materials / software that would help us get through the process of debugging and simulating the system.

1. *[Visual Studio Code](https://code.visualstudio.com/) — A Scalable IDE with Multiple Supported Essential Extension and Components for Easy Development and Integration.
2. *[ModelSim PE Student Edition 10.4a](https://www.mentor.com/company/higher_ed/modelsim-student-edition) — A 2015 No-Support-For-Student-Edition VHDL Simulation.

> Software or materials that has a label of * were my preferrable choice. It is not technically a required software to use. You could use other software that has the same funtionalities. So it depends if you wanna follow the certain materials / software but those are the materials / software that I used after the project making,

If you're using **Visual Studio Code**, here's a list of extensions that I used for convenience.

1. [VHDL Formatter](https://marketplace.visualstudio.com/items?itemName=Vinrobot.vhdl-formatter) by [Vinrobot](https://marketplace.visualstudio.com/publishers/Vinrobot) — VHDL Formatter for Visual Studio Code.
2. [Modern VHDL](https://marketplace.visualstudio.com/items?itemName=rjyoung.vscode-modern-vhdl-support) by [rjyoung](https://marketplace.visualstudio.com/publishers/rjyoung) — This extension add language support for VHDL, based on the 2008 standard. Also includes syntax highlighting of constants, types and functions for the following standard packages:

### 💻 Repository Setup

In this part, I assume that you have the materials / software installed and properly configured. To start off, you have **two ways** to get this project. By (1) **Cloning** or (2) **Forking**.

#### What's the difference???

1. **Cloning** — You replicate the project for your local usage. You do not however inherit the project (unless you're a contributer here) and you don't have the capability to generate PRs to issue with the original repo.
1. **Forking** — You are able to replicate the project and at the same time, you were able to get inheritance of the project. You're allowed to make changes, reflect into your account, and create PR to the original repo.

### 📂 Project Setup

In this part of the subsection, I'm only going to introduce the setup part in Simulation which is ModelSim. If you have other simulators, please keep in note that you have set the Compiler to **VHDL08** Compiler. The default compiler which is **VHDL92** does not allow to display output of the signals.

![Compiler Options](https://github.com/CodexLink/Time-Based_Clap-Pattern-Lock_VHDL08/blob/LEGACY_WORK/imgs/compiler-options.png)

***Keep in mind that, you have to set the compiler options from both files. (This is ModelSim Use-Case.)***

After setting up the compiler from both files and compiled them. You have to Start the Simulation from **(1) clap_lock_vhdl_testbench** and **(2) Add Waveform** to it.

| (1) | (2) |
| ----------- | ----------- |
| ![Simulation Choices](https://github.com/CodexLink/Time-Based_Clap-Pattern-Lock_VHDL08/blob/LEGACY_WORK/imgs/simulation_to_choose.png) | ![Adding Waveform to Simulation](https://github.com/CodexLink/Time-Based_Clap-Pattern-Lock_VHDL08/blob/LEGACY_WORK/imgs/adding_waveform.png) |


Once you were able to set those, its time to adjust the runtime length.

![Runtime Adjustment](https://github.com/CodexLink/Time-Based_Clap-Pattern-Lock_VHDL08/blob/LEGACY_WORK/imgs/runtime-adjustment.png)

*This was done so that, there's a time interval of 1 second per each **run** command being executed.*

And last but not the least, fill in the waveform objects. There are only few selected objects that has to be looked at as other objects weren't useful at all.

![Objects on Waveform](https://github.com/CodexLink/Time-Based_Clap-Pattern-Lock_VHDL08/blob/LEGACY_WORK/imgs/objects-on-waveform.png)

Once you hit the **run** command in the transcript, you have to keep going until you have the following waveform.

![Runtime Expectation Simulation](https://github.com/CodexLink/Time-Based_Clap-Pattern-Lock_VHDL08/blob/LEGACY_WORK/imgs/overall-tests.png)

**The setup is completed! If you want to know more about the runtime of each waveform for every second it runs, please check the documentation. Thanks!**

## 🎆 Post-Work: Result, Demo, Introduction

This project was documented in the midst of the progression. Please check the following materials for more information about this project.

**Documentation**: [Time Based Clap Pattern Lock (Legacy Documentation)](https://docs.google.com/document/d/e/2PACX-1vTUnYAJOs-qG_l9PuymwabFcxyMn1Tjp9Wpv740VC6ZmB9t__RQLubPL7nblfp3ak2VWWbWzI1mAPTH/pub)

**Youtube Video** (*with Simulation and Introduction to the VHDL Programming*): [Clap Lock VHDL Final Project](https://www.youtube.com/watch?v=qh50Q9WZq30)

## Post-Work: To-Do List

Due to time constraints, we're having struggles to add more feature that is very essential to the concept of clap lock.

I, the maintainer, have listed the things that I could have done but decided to postponed it for now.

***I promise to have it finished before this year.***

* Separate **PW_PTRN_RT** from Testbench to Module File with INOUT Port Mode.
* Make **LED Turn ON** (via Process) in Module instead of Testbench, whenever **CL_MIC_DTCTR** is on.
* Make **LED_SEC_BLINK_DISP** blink according to changes on **CL_RT_CLK**.
* Make Type to Remove **CL_XX_XX_XX_CODE** and retain only **CL_XX_XX_XX_DISP**.
* Attempt to consolidate redundant iterations to one processor.
* Implement Max With **CLAP_WIDTH** of 8. (Because we are in 8-bit.) Requires investigation.
* Create **Unittests** that breaks down the test bench's functionality (from the demo).
* Implement Timer Display for the sake of knowning the nth second for nth pattern by one processor instead of replicating it.

## Contributing

I won't be making such changes (unless if I wanted to in unknown times) in the future because its hard to work with the project. Though I wanna rewrite it as possible but its best to have other things to do than this one, occasionally.

If you're interested on working on this project, please feel free to do it and I'm glad to have someone else to take interest of it. Remember that this is only a concept, but there would still be a room for a change.

## Versioning

Currently, I haven't used any software versioning on this project, just like Semantic Versioning. I won't be doing because it took me 3 days to realize I should've dooe so. 

## 🏆 ✍ Authors

Here are the list of authors who is still taking part of the project.

1. **Licas, Janrey** — *Lead Developer and Leader* — [CodexLink](https://github.com/CodexLink)
2. **Imperial, Justine** — *Video Editor, Visualizer* — No Github Profile
3. **Jantoc, Janos Angelo** — *Documentator, Project Initiator* — [BigBossCodes](https://github.com/BigBossCodes)
4. **Langaoan, Ronald** — *Docuemntator, Project Support* — [AliasBangis](https://github.com/AliasBangis)

## 📚 License

This project is licensed under the **MIT License**, see the [LICENSE.md](https://github.com/CodexLink/Time-Based_Clap-Pattern-Lock_VHDL08/blob/master/LICENSE) file for more information.
