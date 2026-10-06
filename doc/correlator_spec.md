# Correlator Specifications
This document describes a binary correlator FPGA logic block for lidar pulse compression.
These specifications will evolve with the application. First, I want to see that something can be made to work using Claude. Then I can refine the requirements for the final application.

## Target Device
I will develop on a Digilent Arty A7-100T board. It carries a Xilinx XC7A100T (part `xc7a100tcsg324-1`, speed grade -1).

- The board has a 100 MHz oscillator. An MMCM generates the 300 MHz processing clock.
- The internal clock rate is twice the data sample rate: 300 MHz clock, 150 Msps data.

## Data
The captured lidar return is quantized to 1 bit, representing +1 or -1. The mapping is the same for the data and the template:

| bit | value |
|-----|-------|
| 0   | +1    |
| 1   | -1    |

- The sample rate is 150 Msps.
- The transmitter sends one burst of the code per laser shot.
- The data source groups samples into records, one record per shot. A record of 3 × the template length (3 × 1023 = 3069 samples) leaves room for a range of delays from the scene. The correlator does not depend on the record length.

## Template
- The template is 1023 taps with 1-bit coefficients, using the mapping above. 1023 is the development length, chosen to keep simulation short. The final application is expected to use 4095 taps (`m_sequence(12)`), so the tap count is a parameter.
- The template length and coefficient values are fixed.
- The template is the degree-10 m-sequence from `octave/m_sequence.m`, which is based on Xilinx XAPP052. The full listing is in the appendix.
- Bit ordering: `t[i] = seq(i+1)` for i = 0..1022. `seq(1)`, the first chip transmitted, lines up with the oldest sample in the correlation window.
- Checked properties of the sequence:
  - It contains 512 ones and 511 zeros.
  - Its periodic autocorrelation is 1023 at zero lag and -1 at every other lag.
  - Its aperiodic (one-shot) autocorrelation has a largest sidelobe of 39, about 28 dB below the peak. Because the code is sent as one burst per shot, this is the sidelobe level to expect.
- Implementation: `octave/gen_template.m` generates the package `source/correlator/template_pkg.sv`, which defines the 127-, 1023- and 4095-tap templates as SystemVerilog constants. The template is not stored in BRAM. Synthesis folds the constant into the correlation logic.

## Processing Model
The correlator is a streaming FIR filter. It processes data in real time as it arrives and never stores a complete record.

- Every input sample produces exactly one output sample.
- The correlator holds only the most recent 1023 samples, in a delay line.
- There is no record counter. `s_tlast` is not used to compute anything; it is delayed and passed through as `m_tlast`.

## Correlation Definition
Let x[n] = ±1 be input sample n and t[i] = ±1 be template tap i. The output for input sample n is the correlation of the template with the 1023 most recent samples:

    y[n] = sum over i = 0..1022 of x[n − 1022 + i] · t[i]

- y[n] = 1023 − 2 · popcount(window XOR template). Its range is −1023..+1023, and it is always odd.
- A code that starts at sample d peaks at +1023 at output n = d + 1022, which is the sample where the last chip of the code arrives.
- The window always contains the 1023 most recent samples, whatever records they came from. This has two consequences:
  - The first 1022 outputs after reset are undefined, because the window still holds reset values.
  - The first 1022 outputs of a record mix in the tail of the previous record. Downstream logic decides which outputs to use.

## Interfaces
- All interfaces are clocked at 300 MHz and follow AXI-Stream conventions.
- Reset is synchronous and active high. It clears the output valid pipeline.

### Input (slave)
- `s_tdata` (1 bit) carries one sample per transfer, qualified by `s_tvalid`.
- In this application samples arrive at 150 Msps, on every other clock cycle. The design itself has no spacing requirement: it accepts a sample on every clock (300 Msps at 300 MHz), and any gaps between samples are allowed.
- `s_tlast` marks the last sample of a record.
- `s_tready` is always 1. The input cannot be stalled.

### Output (master)
- `m_tdata` is 16 bits, carrying y[n] as a signed two's-complement value (11 significant bits, sign-extended). It is qualified by `m_tvalid`.
- There is one output for every input. `m_tvalid` and `m_tlast` are `s_tvalid` and `s_tlast` delayed by the pipeline latency, so `m_tlast` marks the output for the input sample that carried `s_tlast`.
- There is no backpressure (no `m_tready`). The downstream block must accept every output.
- Latency from an input sample to its output is fixed: 12 clocks at 1023 taps (9 at 127 taps, 14 at 4095 taps). The RTL exposes it as the localparam `LATENCY`.

### Parameters
The tap count and template are module parameters (default 1023 taps). Simulations can then also use a short code, such as `m_sequence(7)` with 127 taps, and the design can later be scaled to 4095 taps.

## Resources and Timing
- The design must close timing at 300 MHz on the -1 part.
- The popcount tree is fully parallel and fully pipelined: 6-bit LUT counters, then one registered adder per tree level.
- Out-of-context place and route results (`implement/ooc_correlator.tcl`), xc7a100tcsg324-1 at 300 MHz:

| Taps | LUTs          | Registers     | BRAM / DSP | Setup slack (WNS) | Hold slack (WHS) |
|------|---------------|---------------|------------|-------------------|------------------|
| 1023 | 1,193 (1.9%)  | 2,444 (1.9%)  | 0 / 0      | +0.957 ns         | +0.107 ns        |
| 4095 | 4,777 (7.5%)  | 9,674 (7.6%)  | 0 / 0      | +0.718 ns         | +0.058 ns        |

## Verification
### Simulation
A self-checking SystemVerilog testbench compares every output against a behavioral reference model computed directly from the definition above, and checks that `m_tvalid` and `m_tlast` track `s_tvalid` and `s_tlast`. Test cases:

1. The code embedded at several delays, with random data elsewhere. Check the peak value and its position.
2. The same, with random bit flips (noise).
3. Fully random data.
4. All-zero data and all-one data.
5. Several records back to back, and records separated by gaps.
6. An s_tvalid pattern with irregular gaps.
7. Full rate, with a sample on every clock: a single record, records back to back, and full rate mixed with random gaps.

Each case runs with both the 127-tap and the 1023-tap configurations (`simulate/sim.sh`). The testbench also resets the design mid-stream and checks that outputs resume correctly.

### Hardware
The design will be compiled and run in hardware with synthetic data, and observed with an ILA core. The synthetic data source is to be decided.

## Open Items
- On-chip synthetic data generator for the hardware test (postponed).

## Appendix: Template Sequence
The template is `seq = m_sequence(10)` from `octave/m_sequence.m`, listed 64 chips per row. The numbers on the left are chip indices seq(1)..seq(1023).

```
   1-  64  1000000100100010000011001001101000010010101000011110101110101101
  65- 128  1011000000001100000110110011000010101101011100011011111100010001
 129- 192  1110011110110110100000001010000101101010100011111011110010010110
 193- 256  0000100110010001010001101101110000001111000111011111110010000110
 257- 320  0010110111010000110101011001111001011011001000001000100100110000
 321- 384  0010110001010011101100111000101111110101000101110110101100001100
 385- 448  1101101010000011101001111010011010100100111000001111100111001101
 449- 512  1110100010101011011111000010011101000111010111110110100100001000
 513- 576  0101001010110001110011111110110000100011010011100100111100001101
 577- 640  1101100011000111101111101001001010000001101000110010111010010110
 641- 704  1000100010110011010010100100011000011101101111000001011100101011
 705- 768  1001110111011100110011101010111011110110010100010011011000100001
 769- 832  1100101111100101001100110010101010011111100110001101011110011010
 833- 896  1101001100010010111000010111101010101011111111010000010101001011
 897- 960  1100010101111011101010011011100100011100011111111110000000111000
 961-1023  011111101110001001111100011001111101011001011001001001000000000
```
