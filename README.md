# FPGA-Based Clap Counter Peripheral

![Clap Counter Banner](https://user-images.githubusercontent.com/yourprofile/clap-counter-banner.png)

## 🌟 Overview

This project involves the design and implementation of a Clap Counter Peripheral for an FPGA-based SCOMP processor. The peripheral processes external audio inputs, such as claps or snaps, and provides real-time feedback to the processor. The primary goals of this project were to achieve robust snap detection, ensure accurate counting without overcounting, and provide configurable loudness thresholds. The project was implemented in VHDL and simulated using ModelSim, with a focus on readability, debuggability, and ease of code modification.

## 📋 Table of Contents

- [Introduction](#introduction)
- [Technologies Used](#technologies-used)
- [Design Overview](#design-overview)
- [Project Structure](#project-structure)
- [Setup and Installation](#setup-and-installation)
- [Key Features](#key-features)
  - [Snap Detection](#snap-detection)
  - [Configurable Thresholds](#configurable-thresholds)
  - [State Machine Implementation](#state-machine-implementation)
  - [Moving Averager](#moving-averager)
- [Simulation Results](#simulation-results)
- [Contributors](#contributors)
- [License](#license)

## 🚀 Introduction

This project was developed as part of a course on digital design and FPGA development at Georgia Tech. The Clap Counter Peripheral is designed to interface with the SCOMP processor, processing audio data to detect claps (or snaps) and count them accurately. The design is focused on robustness and configurability, making it adaptable to various environments and use cases.

## 🛠️ Technologies Used

- **VHDL**: Hardware description language used to design the clap counter peripheral.
- **ModelSim**: Simulation tool used to verify the VHDL code.
- **Quartus Prime/Xilinx ISE**: FPGA development tools for synthesis and implementation.
- **SCOMP Processor**: A simple computer processor model used as the core CPU for interfacing with the peripheral.

## 🏗️ Design Overview

### Device Functionality

The Clap Counter Peripheral processes audio signals from a microphone and provides two outputs to the SCOMP processor:
1. **Clap Count**: A 15-bit unsigned vector representing the number of claps detected since the last reset.
2. **Clap Signal**: A single bit that toggles whenever a clap is detected.

### API

The peripheral's interface is designed to be straightforward, with the clap count and signaling bit forming the core of the API. Users can configure the loudness threshold through the SCOMP’s IO bus, ensuring that the peripheral only detects claps that exceed a specified loudness.

### Configurable Thresholds

Users can set the loudness threshold using the 10 LSBs of the SCOMP’s IO bus. The peripheral stops detecting claps when the MSB of the input is set to high. This design allows the peripheral to operate in various environments by adjusting the sensitivity to sound.

### State Machine Implementation

The transition from a nested if-statement logic to a state machine was a critical design decision. The state machine improves code readability, debuggability, and maintainability. It operates in three states:
1. **Start Timer**: Initiates the timer when the audio average exceeds the loud threshold.
2. **Stop Timer**: Halts the timer when the audio falls below the quiet threshold.
3. **Clap Detection**: Checks the duration of the noise to confirm if it was a clap and increments the counter.

### Moving Averager

To filter out small fluctuations in the audio signal, which could lead to false detections, the peripheral uses a moving average of the past 32 samples of the audio data. This approach smooths out the input and improves the accuracy of clap detection.

## 🗂️ Project Structure

```plaintext
├── SCOMP.vo                   # VHDL/Verilog object file for the SCOMP processor
├── SCOMP_modelsim.xrf         # ModelSim report file
├── SCOMP.sft                  # Synthesis report file
├── src/                       # Source code directory containing HDL files
│   ├── clap_counter.vhd       # VHDL code for the Clap Counter Peripheral
│   ├── clap_counter_tb.vhd    # Testbench for the Clap Counter Peripheral
├── simulation/                # Simulation result files and waveforms
│   ├── clap_wave.do           # Waveform configuration file for ModelSim
│   ├── clap_wave.wlf          # Waveform output file from ModelSim
├── README.md                  # Project documentation
🛠️ Setup and Installation
Prerequisites
ModelSim: Required for simulating the VHDL code.
Quartus Prime/Xilinx ISE: Required for synthesis and FPGA implementation.
SCOMP Processor: Integrated with the peripheral for testing.
Installation Steps
Clone the repository:

bash
Copy code
git clone https://github.com/yourusername/clap-counter-peripheral.git
cd clap-counter-peripheral
Open the project in ModelSim:

Import the VHDL files from the src/ directory into ModelSim.
Set up the simulation environment using the provided .do files.
Run the simulation:

Simulate the VHDL code to verify the functionality of the Clap Counter Peripheral.
Analyze the waveforms to ensure accurate detection and counting of claps.
Synthesize the design:

Use Quartus Prime or Xilinx ISE to synthesize the design for FPGA implementation.
Generate the bitstream for uploading to an FPGA board.
✨ Key Features
Snap Detection
Robust Clap Detection: The peripheral reliably detects claps without overcounting, using a state machine to manage detection logic.
Configurable Thresholds
User-Defined Sensitivity: The loudness threshold is configurable, allowing the peripheral to adapt to different environments by adjusting the sensitivity to audio input.
State Machine Implementation
Improved Readability and Debuggability: Transitioning to a state machine made the design more maintainable and easier to debug, enhancing the overall reliability of the peripheral.
Moving Averager
Noise Filtering: The moving averager smooths out audio data, reducing the likelihood of false positives and ensuring accurate clap detection.
📊 Simulation Results
Functional Verification: The Clap Counter Peripheral was successfully verified using ModelSim, with accurate detection and counting of claps.
Waveform Analysis: The simulation waveforms confirm the correct operation of the state machine and the timing of the clap detection logic.
Waveform showing the detection and counting of claps by the Clap Counter Peripheral.

👥 Contributors
[Your Name] - FPGA and Digital Design Engineer
Expertise in VHDL, FPGA design, and digital logic simulation.
Developed this project as part of a coursework at Georgia Tech, demonstrating skills in hardware design and simulation.
LinkedIn | GitHub
Programmed a  FPGA board to pass and detect audio snaps as well as detect audio snaps of different magnitudes
