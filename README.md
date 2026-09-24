# UART Transmitter (Verilog)

An 8-bit UART transmitter implemented in Verilog, built as a finite state machine (FSM) with a configurable baud rate generator. Simulated using Icarus Verilog and GTKWave.

## Overview

UART (Universal Asynchronous Receiver/Transmitter) converts parallel data into a serial bitstream, one bit at a time, over a single wire — with no shared clock between transmitter and receiver. Both sides agree on a fixed baud rate in advance, and each side times its own bits internally.

This project implements the **transmitter** side only, using the standard 8N1 frame format (8 data bits, no parity, 1 stop bit).

## Frame format

| Part | Bits | Value |
|---|---|---|
| Start bit | 1 | `0` |
| Data bits | 8 | LSB first |
| Stop bit | 1 | `1` |

The line idles high (`1`) when no transmission is active.

## Files

| File | Description |
|---|---|
| `baud_gen.v` | Clock divider that generates a single-cycle `tick` pulse once per bit period, based on `CLK_FREQ` and `BAUD_RATE` |
| `uart_tx.v` | The transmitter FSM — drives the `tx` line through IDLE → START → DATA → STOP |
| `uart_tx_tb.v` | Testbench that sends several test bytes and self-checks the transmitted bit pattern |

## FSM design

| Current state | Condition | Next state | `tx` output |
|---|---|---|---|
| IDLE | `tx_start = 1` | START | `1` |
| IDLE | `tx_start = 0` | IDLE (stay) | `1` |
| START | after 1 bit period | DATA | `0` |
| DATA | `bit_cnt < 7` | DATA (stay) | `data_in[bit_cnt]` |
| DATA | `bit_cnt = 7` | STOP | `data_in[7]` |
| STOP | after 1 bit period | IDLE | `1` |

State transitions are gated by a `tick` signal from `baud_gen`, not the raw system clock, so each state holds its output for exactly one bit period.

## Module ports

### `uart_tx`

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | input | 1 | System clock |
| `reset` | input | 1 | Synchronous active-high reset |
| `tx_start` | input | 1 | Pulse high to begin transmitting `data_in` |
| `data_in` | input | 8 | Byte to transmit |
| `tx` | output | 1 | Serial output line |
| `tx_busy` | output | 1 | High while a transmission is in progress |

Parameters: `CLK_FREQ` (default `50_000_000`), `BAUD_RATE` (default `9600`)

### `baud_gen`

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | input | 1 | System clock |
| `reset` | input | 1 | Synchronous active-high reset |
| `tick` | output | 1 | Single-cycle pulse once per bit period |

Parameters: `CLK_FREQ`, `BAUD_RATE`

## Running the simulation

Requires [Icarus Verilog](https://bleyer.org/icarus/) and [GTKWave](https://gtkwave.sourceforge.net/) (bundled with the Icarus Windows installer).

```
cd src
iverilog -o uart_tx_tb.vvp baud_gen.v uart_tx.v uart_tx_tb.v
vvp uart_tx_tb.vvp
gtkwave uart_tx_tb.vcd
```

The testbench uses scaled-down clock/baud values (`CLK_FREQ = 1000`, `BAUD_RATE = 100`) so simulation runs quickly, and prints `PASS`/`FAIL` to the console for each test byte.

### What to check in GTKWave

- `tx` idles high, drops low for one bit period (start bit), outputs 8 data bits LSB-first, then returns high (stop bit)
- `8'h55` (`01010101`) produces a clean alternating pattern — the easiest byte to visually verify
- `tx_busy` goes high right after `tx_start` and drops low exactly when the stop bit finishes

## Possible extensions

- UART receiver (`uart_rx`) to complete a full transceiver
- Parity bit support (even/odd)
- Configurable data width and stop bit count
- FIFO buffer for queuing multiple bytes
