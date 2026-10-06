# Correlator Specifications
This document desicribes a binary correlator FPGA logic block for lidar pulse compression.
These specifications will evolve with the application.  First, I want to see that something can be made to work using Claude. Then I can refine the requirements for the final application.

## Target Device
I to develop on a Digilent Arty A7-100T board. It carries a Xilinx XC7A100T-2. The internal clock speed will be twice the data sample rate.

## Data
The captured lidar return will be quantized to 1-bit corresponding to +1,-1. The return will have a length of 3*4095 to give room for a range of delays from the scene. The sample rate will be 150Msps.

## Verification
There should be a simulation test bench. I also want compile and run the design in hardware using synthetic data and observing with an ILA core.

## Interfaces
Interfaces will be clocked at 300MHz. Input and output data will follow axi streaming conventions.

s_tdata input data will arrive at 150Msps on every other clock cycle, qualified by a s_tvalid signal. s_tlast will indicate the last value of a sample record.

m_tdata output data will be qualified by m_tvalid. The last sample will be indicated by m_tlast.

## Template
The template can be 4095 taps with 1-bit coefficients. The binary (0,1) corresponds to (+1.-1).  The template length and coefficient values are fixed. 

### Template Sequence
The template sequence is generated from the script octave/m_sequence.m as below. This script is based on Xilinx document XAPP052.

octave:11> seq=m_sequence(12); seq
seq =

 Columns 1 through 42:

   1   1   1   1   0   1   1   1   0   0   1   1   1   1   1   1   1   0   1   0   0   1   0   1   1   1   0   1   1   1   1   1   0   1   1   0   0   1   0   0   0   0

 Columns 43 through 84:

   1   1   1   0   0   1   1   1   0   1   0   0   0   1   0   1   1   1   0   1   0   1   0   0   0   1   1   1   0   0   1   0   1   1   0   0   0   0   0   0   0   0

 Columns 85 through 126:

   1   1   0   1   0   1   0   0   0   0   0   1   0   1   1   1   1   0   1   1   1   0   0   0   0   0   0   1   0   0   1   1   0   1   0   1   0   0   0   1   1   0

 Columns 127 through 168:

   1   1   0   0   0   0   1   0   0   1   1   1   1   1   0   0   0   0   0   1   1   0   1   1   1   1   1   0   0   0   0   0   0   0   1   0   1   0   0   0   0   0

 Columns 169 through 210:

   1   1   1   1   1   0   1   1   1   0   0   1   0   0   0   0   1   0   1   0   0   0   0   1   0   0   0   1   0   1   0   1   1   1   1   0   1   1   1   1   1   1

 Columns 211 through 252:

   1   0   1   0   1   0   1   0   1   0   1   0   1   1   0   0   1   0   0   1   1   1   1   0   0   1   1   0   0   1   0   0   0   0   1   0   0   1   1   1   0   0

 Columns 253 through 294:

   1   1   0   1   1   0   1   0   0   0   0   0   0   1   1   0   1   0   0   1   1   1   0   1   0   1   1   1   0   0   1   0   0   0   1   0   1   0   0   1   1   1

 Columns 295 through 336:

   1   0   1   1   0   1   0   1   0   1   0   1   0   0   1   0   0   0   1   0   1   0   1   0   0   0   1   1   0   0   0   1   1   0   1   0   1   0   1   0   0   0

 Columns 337 through 378:

   0   1   1   1   0   1   1   1   1   1   0   0   0   1   1   1   1   1   1   0   1   0   0   1   1   0   0   0   0   0   0   0   1   1   1   0   0   1   1   0   1   0

 Columns 379 through 420:

   1   0   1   0   1   1   1   0   1   0   1   0   1   1   0   0   1   1   1   0   0   1   0   1   1   1   1   1   1   0   1   1   1   1   1   1   0   1   0   1   1   1

 Columns 421 through 462:

   0   1   1   0   0   1   0   0   1   1   0   0   1   1   1   0   1   1   1   0   1   1   1   0   1   1   0   1   0   0   0   0   1   1   0   0   0   0   1   1   1   1

 Columns 463 through 504:

   0   1   0   1   0   0   0   0   1   1   0   1   0   0   1   0   0   1   0   0   0   0   0   0   0   0   1   1   1   0   1   0   0   1   1   1   0   1   1   0   0   0

 Columns 505 through 546:

   0   1   0   1   0   0   0   1   0   1   1   0   0   1   0   0   1   0   0   0   1   0   0   0   1   0   1   1   1   1   1   0   1   1   1   0   1   0   1   1   0   1

 Columns 547 through 588:

   0   1   1   0   1   1   1   0   1   1   1   1   1   1   0   0   1   0   0   1   1   0   0   0   0   0   1   1   0   0   1   1   1   0   1   0   0   1   0   1   0   1

 Columns 589 through 630:

   0   1   0   0   1   1   1   1   0   0   0   1   0   0   0   1   0   0   1   1   1   0   1   1   1   0   0   0   0   1   1   0   1   0   0   0   1   1   0   0   1   1

 Columns 631 through 672:

   1   0   0   1   1   0   0   0   1   0   0   1   1   1   0   0   0   0   1   0   1   1   0   1   0   0   1   1   1   0   0   1   0   0   1   1   1   0   0   0   1   0

 Columns 673 through 714:

   1   0   1   1   0   1   0   1   0   0   1   1   0   1   1   1   0   1   0   1   0   0   1   0   0   0   0   1   0   1   1   1   1   1   1   1   1   1   1   0   0   1

 Columns 715 through 756:

   0   0   0   0   1   1   0   1   1   0   1   0   1   0   0   0   1   0   1   0   0   0   1   1   1   1   0   1   0   0   0   0   0   1   0   1   0   0   0   1   1   0

 Columns 757 through 798:

   0   1   0   0   1   1   1   0   1   1   0   1   1   1   0   0   0   1   1   0   1   1   0   0   1   1   0   1   0   0   0   0   1   1   1   1   1   1   1   0   0   0

 Columns 799 through 840:

   0   1   1   0   1   1   1   1   0   1   1   1   0   1   1   1   1   0   0   1   1   1   1   1   0   1   0   1   1   1   1   0   0   1   0   0   1   1   1   1   1   1

 Columns 841 through 882:

   0   0   0   1   0   1   0   0   1   0   1   1   0   0   0   0   1   1   1   1   1   0   1   0   0   1   1   1   1   1   1   0   1   1   0   1   1   1   1   0   0   1

 Columns 883 through 924:

   0   1   1   1   1   0   0   1   0   1   0   0   0   1   0   0   1   0   0   0   1   0   1   1   0   1   1   0   0   0   1   0   0   0   0   1   0   1   0   1   1   1

 Columns 925 through 966:

   0   0   1   1   0   0   1   1   0   0   0   0   1   0   1   0   1   1   0   1   1   0   1   1   1   0   1   0   1   1   1   0   1   0   1   1   0   0   1   0   0   0

 Columns 967 through 1008:

   0   0   0   0   1   0   0   0   0   0   1   1   1   1   0   1   0   0   1   1   1   0   0   0   1   1   0   1   0   1   1   0   1   1   0   1   0   0   1   0   0   0

 Columns 1009 through 1050:

   0   0   0   1   1   0   0   1   1   0   1   0   1   0   0   1   0   0   1   1   0   1   1   0   0   0   1   1   0   0   0   0   1   1   0   0   1   0   0   0   1   1

 Columns 1051 through 1092:

   0   0   0   0   1   0   1   1   0   0   1   1   0   1   0   1   1   1   0   1   0   0   0   1   1   1   1   1   1   0   0   1   1   0   1   1   1   1   0   0   1   1

 Columns 1093 through 1134:

   0   0   0   1   1   1   0   0   1   1   1   1   0   1   1   0   0   1   0   1   1   1   0   1   0   1   1   1   1   0   1   0   1   1   1   0   0   0   1   1   1   1

 Columns 1135 through 1176:

   1   0   1   0   1   0   0   0   1   0   0   1   1   1   1   0   0   0   0   1   1   1   1   1   1   0   1   1   1   0   0   0   1   1   1   0   0   1   0   0   0   1

 Columns 1177 through 1218:

   1   0   1   1   1   0   0   0   0   1   0   1   0   1   0   1   0   0   0   0   0   0   0   1   1   0   0   0   1   0   1   1   0   0   0   0   0   1   1   1   0   1

 Columns 1219 through 1260:

   1   0   1   1   0   1   1   1   1   0   1   0   1   0   1   0   0   1   0   1   1   0   1   1   1   0   1   0   0   0   0   1   1   1   0   0   0   0   0   1   1   1

 Columns 1261 through 1302:

   1   1   1   0   0   0   0   1   0   1   0   0   1   0   1   0   1   1   1   0   0   0   0   1   1   1   0   1   1   0   0   0   1   0   1   0   0   1   1   0   0   1

 Columns 1303 through 1344:

   0   1   1   0   1   1   0   0   1   0   1   1   0   1   0   1   1   0   0   0   0   1   1   0   0   0   1   1   1   1   0   1   1   0   0   0   1   0   0   1   1   0

 Columns 1345 through 1386:

   1   1   1   0   0   1   0   1   0   0   1   1   0   0   0   1   0   0   0   0   0   1   0   1   1   0   0   1   0   1   0   1   1   0   0   1   1   0   1   1   0   0

 Columns 1387 through 1428:

   0   0   0   1   1   0   1   0   0   0   0   0   1   1   1   0   0   1   0   1   0   1   1   1   0   1   1   1   0   1   0   1   0   1   0   1   1   0   1   0   1   1

 Columns 1429 through 1470:

   1   0   0   0   0   0   0   0   1   1   0   1   1   0   1   1   0   1   1   0   0   1   0   0   0   1   0   0   0   0   1   0   0   1   0   0   1   1   1   0   1   0

 Columns 1471 through 1512:

   1   0   0   1   1   1   1   1   1   1   0   0   1   1   0   0   0   0   0   0   1   0   0   0   0   1   0   0   0   1   1   0   1   0   1   0   0   1   1   1   0   0

 Columns 1513 through 1554:

   0   0   0   1   0   0   0   0   1   1   1   1   0   1   1   0   1   1   0   1   0   0   0   1   1   1   0   1   1   0   1   0   1   0   0   1   0   1   0   0   1   1

 Columns 1555 through 1596:

   0   1   1   0   1   0   1   1   1   1   0   0   0   1   1   0   1   0   0   0   1   0   1   1   0   1   0   1   1   1   1   1   1   1   0   1   1   0   1   0   0   0

 Columns 1597 through 1638:

   1   0   0   1   0   1   1   0   1   1   0   1   0   1   0   1   1   0   1   1   1   1   1   1   1   0   0   1   0   1   1   1   0   1   1   0   0   0   1   1   0   1

 Columns 1639 through 1680:

   1   1   0   1   1   1   0   0   0   1   0   0   1   1   1   1   1   1   1   1   1   0   0   0   1   1   1   0   0   0   1   1   1   1   0   1   0   1   1   1   1   1

 Columns 1681 through 1722:

   1   0   1   0   0   0   0   1   1   0   1   1   1   0   1   0   0   1   1   0   0   1   1   1   1   0   0   0   0   0   0   0   0   1   0   1   0   1   1   1   1   1

 Columns 1723 through 1764:

   0   0   0   1   0   0   0   0   1   1   0   1   0   1   0   1   1   1   1   1   1   0   0   1   1   1   0   0   0   1   1   1   0   1   0   1   1   0   0   0   1   1

 Columns 1765 through 1806:

   1   0   1   1   1   1   0   1   1   1   1   0   0   0   1   1   1   0   1   1   0   0   1   0   1   0   0   1   0   0   0   0   0   1   0   0   1   0   0   0   1   1

 Columns 1807 through 1848:

   0   0   1   1   0   1   1   0   1   1   1   1   1   0   1   0   0   0   1   1   1   0   0   0   1   0   0   0   1   1   1   0   0   1   1   0   0   1   0   1   1   1

 Columns 1849 through 1890:

   0   0   1   0   0   1   0   1   0   0   1   0   0   1   1   1   0   0   1   0   1   0   0   0   0   1   1   0   0   1   1   0   0   1   0   1   0   0   1   1   1   1

 Columns 1891 through 1932:

   1   0   0   1   1   1   0   1   1   0   0   1   1   0   1   1   1   1   1   1   0   0   0   1   1   0   1   1   1   1   0   0   0   0   1   1   0   0   0   0   0   0

 Columns 1933 through 1974:

   0   0   0   0   1   0   0   0   1   1   0   0   1   0   1   0   0   0   0   0   0   1   1   1   0   1   1   1   0   0   1   1   0   0   0   0   1   1   0   1   0   1

 Columns 1975 through 2016:

   1   0   0   0   1   0   0   1   0   1   0   0   1   1   1   0   0   1   1   1   0   0   1   1   1   1   1   0   0   1   0   0   1   0   1   1   1   0   1   0   0   0

 Columns 2017 through 2058:

   0   0   0   0   1   0   1   1   1   1   1   0   0   0   0   1   1   1   0   0   0   1   1   0   0   1   0   0   0   0   0   1   1   0   1   0   1   1   1   1   1   0

 Columns 2059 through 2100:

   0   1   0   1   1   0   1   0   0   0   1   1   0   1   0   0   0   0   1   0   0   0   0   1   0   1   1   0   0   0   0   1   0   0   0   0   0   0   1   1   1   1

 Columns 2101 through 2142:

   0   0   0   0   1   0   0   0   0   1   1   0   0   1   0   1   1   0   0   0   1   1   1   1   0   0   0   1   1   0   0   1   1   1   1   1   0   0   0   1   1   0

 Columns 2143 through 2184:

   0   0   0   0   0   1   1   1   1   1   1   1   1   1   1   1   1   0   1   0   1   1   0   1   0   0   0   1   0   1   0   1   0   1   1   0   0   0   1   1   0   1

 Columns 2185 through 2226:

   0   0   1   0   1   0   1   1   0   1   1   1   0   0   0   0   0   1   0   1   1   1   0   1   0   0   1   1   1   1   0   0   1   0   1   1   0   0   1   1   1   1

 Columns 2227 through 2268:

   0   1   0   0   0   1   1   0   1   1   1   1   1   1   1   1   1   0   1   1   0   0   1   1   1   1   1   1   0   0   1   0   1   0   0   1   0   1   1   1   1   1

 Columns 2269 through 2310:

   1   1   0   0   0   1   0   0   1   1   0   0   0   0   1   0   0   1   0   0   0   0   0   1   1   1   0   1   0   1   0   0   0   0   0   0   1   0   0   1   0   1

 Columns 2311 through 2352:

   0   1   1   1   1   1   1   1   1   0   0   1   1   1   1   1   1   0   1   0   1   0   0   1   0   1   1   1   0   0   0   0   0   1   1   0   0   0   0   0   1   1

 Columns 2353 through 2394:

   1   1   0   0   1   1   0   1   0   1   1   0   1   0   1   0   1   0   0   1   1   0   0   1   1   0   0   1   1   0   1   1   1   0   0   0   1   0   1   0   0   0

 Columns 2395 through 2436:

   1   0   0   0   1   1   1   1   1   0   0   0   1   0   1   1   1   0   1   1   0   1   1   0   0   0   0   0   0   0   1   0   0   1   1   1   0   1   0   0   1   1

 Columns 2437 through 2478:

   0   1   0   0   0   1   1   1   1   0   0   1   1   1   0   1   0   1   1   0   1   1   0   0   1   1   0   0   1   1   1   0   0   0   0   1   1   0   0   1   1   1

 Columns 2479 through 2520:

   1   0   1   1   1   1   0   1   1   0   0   1   1   0   0   0   0   0   1   0   1   1   0   1   0   1   0   0   0   0   1   0   1   0   1   0   0   1   1   1   0   1

 Columns 2521 through 2562:

   1   1   1   1   1   1   1   0   1   0   0   0   1   0   0   1   1   0   0   1   1   0   1   0   0   1   1   0   0   1   0   0   0   1   0   1   1   1   0   0   1   0

 Columns 2563 through 2604:

   1   0   1   0   0   1   0   1   0   1   0   0   1   1   0   1   0   0   1   0   0   0   1   1   1   0   1   1   1   0   1   0   0   1   0   1   1   0   1   0   0   1

 Columns 2605 through 2646:

   0   0   1   1   1   1   1   0   1   1   1   1   1   0   1   0   1   1   0   0   1   1   1   1   1   0   1   1   0   0   0   1   1   1   0   0   0   0   0   0   0   0

 Columns 2647 through 2688:

   0   1   0   1   1   0   0   0   1   0   1   1   0   1   1   1   1   1   0   0   1   1   1   1   0   0   1   0   0   0   1   1   1   0   0   0   0   1   1   1   1   0

 Columns 2689 through 2730:

   0   1   0   1   0   1   1   0   1   0   0   1   1   0   1   1   0   0   1   0   0   1   0   1   1   0   1   0   1   0   1   1   1   0   0   0   1   0   0   0   0   0

 Columns 2731 through 2772:

   0   1   0   0   0   1   0   1   1   0   0   0   1   1   0   0   1   1   0   0   0   1   0   1   0   0   0   0   1   1   1   1   0   0   0   1   0   1   1   0   1   0

 Columns 2773 through 2814:

   0   0   0   0   1   0   0   1   1   1   1   0   1   1   1   0   1   0   0   0   1   0   0   0   0   1   1   1   0   1   0   0   0   0   0   1   1   0   1   1   0   0

 Columns 2815 through 2856:

   0   1   0   1   1   1   0   0   0   1   0   1   1   1   1   0   0   1   1   0   1   1   0   0   1   1   1   0   1   1   0   1   0   0   1   1   0   0   0   1   1   1

 Columns 2857 through 2898:

   1   1   0   0   1   0   1   0   1   0   1   0   1   0   0   0   1   1   1   1   1   0   1   1   0   1   1   0   0   1   1   1   1   0   0   1   1   1   1   0   1   0

 Columns 2899 through 2940:

   1   1   0   0   0   0   0   0   1   1   0   0   0   0   1   0   0   0   1   1   1   0   1   0   0   1   0   0   1   0   1   1   1   1   0   1   1   0   1   1   1   0

 Columns 2941 through 2982:

   1   1   0   0   0   0   0   1   0   1   0   1   0   1   1   1   1   1   0   1   1   0   1   0   1   1   0   1   0   0   1   0   1   0   0   0   1   0   1   0   1   1

 Columns 2983 through 3024:

   0   0   1   0   1   0   0   0   1   1   1   0   1   0   1   0   1   1   1   1   0   0   1   1   1   0   0   1   0   0   0   0   0   1   0   1   0   1   1   0   0   0

 Columns 3025 through 3066:

   1   0   1   0   1   0   0   1   0   0   1   0   1   0   0   0   1   1   0   1   0   1   1   1   0   0   1   1   1   1   0   0   0   1   1   1   1   0   0   1   0   0

 Columns 3067 through 3108:

   1   0   0   0   0   1   1   1   1   1   0   0   1   1   0   1   0   0   0   1   0   0   0   1   0   0   0   0   0   1   1   0   0   1   0   0   1   0   0   1   0   1

 Columns 3109 through 3150:

   1   0   0   1   0   1   1   0   0   1   0   0   0   1   1   1   1   1   1   1   1   0   0   0   0   0   0   1   0   1   0   0   1   1   1   0   1   0   0   0   0   1

 Columns 3151 through 3192:

   0   0   1   1   0   1   1   0   1   1   0   0   0   1   1   1   1   1   1   1   0   1   1   1   0   1   1   0   0   1   1   1   0   0   0   1   0   0   1   0   0   0

 Columns 3193 through 3234:

   0   1   0   0   0   0   0   1   0   0   0   1   1   1   1   0   1   1   1   1   1   0   0   1   0   0   0   1   0   0   1   1   0   1   0   0   1   1   1   1   0   1

 Columns 3235 through 3276:

   0   1   0   1   1   1   0   1   1   0   1   0   1   1   1   0   1   1   1   1   0   1   0   0   0   1   0   1   0   0   1   0   0   0   1   1   0   1   0   0   1   1

 Columns 3277 through 3318:

   0   1   0   1   1   0   0   1   0   1   1   1   1   0   1   0   1   0   0   1   1   0   0   0   0   1   1   1   0   1   0   1   1   1   1   1   0   1   0   1   0   1

 Columns 3319 through 3360:

   1   0   1   0   0   0   0   1   0   1   1   1   0   0   0   0   1   0   0   1   0   1   1   1   1   1   0   0   1   1   0   0   1   1   1   1   1   1   1   1   0   1

 Columns 3361 through 3402:

   1   1   1   0   0   1   0   0   0   0   0   0   1   0   1   1   0   1   1   0   1   1   0   1   0   1   1   0   0   1   1   0   0   0   1   1   0   1   1   0   1   0

 Columns 3403 through 3444:

   0   1   1   1   1   1   0   1   0   0   0   0   0   0   1   0   1   0   1   0   0   0   0   0   1   1   0   0   0   1   1   0   0   1   0   1   1   1   1   1   0   1

 Columns 3445 through 3486:

   0   0   1   0   0   0   0   1   1   0   0   0   1   0   0   0   1   1   0   1   1   0   1   1   1   0   0   1   0   0   1   1   0   1   1   1   1   1   0   1   1   1

 Columns 3487 through 3528:

   1   0   1   0   1   1   0   1   1   1   1   0   0   0   1   0   0   1   0   1   1   1   0   0   1   1   1   0   1   1   1   1   0   0   0   0   0   0   1   1   0   1

 Columns 3529 through 3570:

   1   1   0   0   1   1   0   1   1   1   0   1   1   0   1   1   1   1   1   1   0   1   1   0   0   0   0   0   0   1   0   1   1   1   0   0   1   1   0   1   0   0

 Columns 3571 through 3612:

   1   0   1   1   0   0   1   1   0   0   1   0   0   1   1   0   1   0   0   0   0   0   0   0   0   1   0   0   1   0   0   1   0   0   1   0   0   0   1   1   1   1

 Columns 3613 through 3654:

   0   0   0   0   0   1   1   1   0   0   0   1   0   1   1   0   0   1   1   1   0   1   0   1   0   1   0   0   0   1   0   0   0   0   0   0   0   1   1   1   1   1

 Columns 3655 through 3696:

   0   0   0   0   1   0   0   1   1   0   0   0   1   0   1   1   1   1   1   1   0   0   0   0   0   1   0   1   0   0   1   0   0   1   0   0   1   1   1   1   0   1

 Columns 3697 through 3738:

   0   0   1   0   0   1   1   0   0   0   1   1   0   0   0   1   0   0   1   0   0   1   1   0   1   0   1   1   1   1   0   1   1   0   0   0   0   1   1   0   1   1

 Columns 3739 through 3780:

   0   0   1   0   1   0   1   0   1   1   0   1   1   0   0   0   0   1   1   1   0   0   1   0   0   1   0   0   1   1   0   0   1   0   0   1   0   1   0   1   0   1

 Columns 3781 through 3822:

   1   1   0   0   1   0   1   1   0   1   1   1   1   0   1   1   0   1   0   0   1   0   1   1   1   1   0   0   0   1   0   1   0   1   0   1   0   1   1   1   1   0

 Columns 3823 through 3864:

   1   0   0   0   0   1   0   1   0   0   1   1   0   1   0   1   0   1   1   0   0   0   0   0   1   0   0   1   0   1   1   0   0   0   1   0   0   0   1   0   1   0

 Columns 3865 through 3906:

   0   0   0   0   0   0   0   0   1   1   0   0   1   0   1   0   1   1   1   1   0   0   0   0   0   1   0   0   1   1   0   0   1   0   1   0   1   0   0   0   1   0

 Columns 3907 through 3948:

   1   1   1   1   0   1   0   0   1   1   0   1   1   1   1   0   1   0   0   1   0   1   0   0   1   0   1   0   0   0   0   1   0   1   1   0   1   1   1   0   0   1

 Columns 3949 through 3990:

   1   1   0   0   0   0   0   0   1   1   1   0   0   0   0   1   0   0   0   1   0   0   1   0   0   1   0   1   0   1   1   0   0   0   0   1   0   1   1   1   1   0

 Columns 3991 through 4032:

   0   0   0   1   0   1   1   1   0   1   1   1   0   0   1   0   1   1   1   0   0   0   1   1   0   0   0   1   1   1   0   1   0   0   0   1   1   0   0   0   0   0

 Columns 4033 through 4074:

   1   0   0   0   1   0   0   0   1   1   0   0   0   1   0   1   0   1   1   1   0   1   0   0   1   0   0   0   1   0   0   1   0   1   0   1   0   0   0   0   1   0

 Columns 4075 through 4095:

   0   1   0   1   0   0   0   0   0   1   0   0   0   0   0   0   0   0   0   0   0

octave:12>
