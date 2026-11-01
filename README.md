# FPGA Signal Measurement Instrument

Verilog instrument for the Terasic DE10-Lite (Intel MAX 10, 10M50DAF484C7G) that measures the
frequency, period, HIGH time and duty cycle of a 3.3 V digital signal and shows the result on the
six seven-segment displays.

## Architecture
- Two-flop input synchronizer + edge detector
- Frequency: rising edges counted over a 1 s gate (50,000,000 clocks)
- Period / HIGH time: counted in 50 MHz clock cycles (20 ns resolution)
- Duty = floor(HIGH x 100 / period) using a 39-step restoring divider
  (replaced a combinational divider that failed 50 MHz timing by 264 ns)
- Built-in test generator (1 kHz / 10 kHz / 100 kHz / 1 MHz, four duty cycles) for loopback self-test

## Controls
| Switch | Function |
|---|---|
| SW[1:0] | Display: 00 frequency (Hz), 01 period (clocks), 10 HIGH (clocks), 11 duty (%) |
| SW[3:2] | Generator frequency: 00 1 kHz, 01 10 kHz, 10 100 kHz, 11 1 MHz |
| SW[5:4] | Generator duty: 00 50 %, 01 25 %, 10 75 %, 11 12.5 % |
| SW[6] | 0 = measure Arduino D3 pin, 1 = measure internal generator |
| KEY0 | Reset |

LEDR0 = value exceeds six digits (shows the lowest six). LEDR1 = measuring internal generator.

## Wiring (Arduino header, 3.3 V logic only, common ground)
- D2 (PIN_AB7) = test generator output
- D3 (PIN_AB8) = measurement input
- Loopback: jumper D2 to D3 with SW[6] = 0. Never drive D3 from a 5 V source.

## Build and simulate
- Quartus Prime Lite 18.1: open `signal_measurement.qpf`, run Full Compilation, program the `.sof`
- Simulation: `signal_measurement_tb.v` (ModelSim)

## Results
_Fill in: simulation, timing summary, hardware table, photo._
