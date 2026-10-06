# Correlator Specifications
This document desicribes a binary correlator FPGA logic block for lidar pulse compression.
These specifications will evolve with the application.  First, I want to see that something can be made to work using Claude. Then I can refine the requirements for the final application.

## Target Device
I to develop on a Digilent Arty A7-100T board. It carries a Xilinx XC7A100T-2. The internal clock speed will be twice the data sample rate.

## Template
The template can be 4095 taps with 1-bit coefficients. The binary (0,1) corresponds to (+1.-1).  The template length and coefficient values are fixed. 

## Data
The captured lidar return will be quantized to 1-bit corresponding to +1,-1. The return will have a length of 3*4095 to give room for different delays from the scene. The sample rate will be 150Msps.

## Verification
There should be a simulation test bench. I also want compile and run the design in hardware using synthetic data and observing with an ILA core.

## Interfaces
Interfaces will be clocked at 300MHz. Input and output data will follow axi streaming conventions.

s_tdata input data will arrive at 150Msps on every other clock cycle, qualified by a s_tvalid signal. s_tlast will indicate the last value of a sample record.

m_tdata output data will be qualified by m_tvalid. The last sample will be indicated by m_tlast.



