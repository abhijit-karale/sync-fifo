# Synchronous FIFO (Parameterizable Depth/Width)

A parameterizable synchronous FIFO (First-In-First-Out buffer) written in SystemVerilog, with a self-checking constrained-random testbench and a documented set of formal-style (SVA) safety properties.

## Design Overview
- **Parameters:** `WIDTH` (data width, default 8), `DEPTH` (entry count, default 16)
- **Interface:** `wr_en`/`rd_en` handshake, `full`/`empty` status flags, live `fifo_count`
- **Pointer scheme:** Gray-code-free binary pointers with an extra MSB wrap bit to distinguish full from empty without wasting a memory slot

## Verification
- Self-checking testbench (`tb/tb_sync_fifo.sv`) using a SystemVerilog queue as the reference (golden) model
- Directed tests: fill-to-full, drain-to-empty, overflow/underflow protection
- Constrained-random regression: 500 randomized read/write transactions
- Immediate-assertion scoreboard check: FIFO can never report `full` and `empty` simultaneously
- **Result: 265/265 checks passed**
- Formal-style SVA properties (for QuestaSim/Xcelium/VCS) documented in `docs/fifo_assertions_reference.sv`

## How to Run (Icarus Verilog, open-source)
```bash
cd rtl_or_project_root
iverilog -g2012 -o sim.out rtl/sync_fifo.sv tb/tb_sync_fifo.sv
vvp sim.out
```
This produces `waveform/sync_fifo.vcd`, viewable in GTKWave:
```bash
gtkwave waveform/sync_fifo.vcd
```

## Files
```
rtl/sync_fifo.sv                    - Synthesizable FIFO design
tb/tb_sync_fifo.sv                  - Self-checking testbench
waveform/sync_fifo.vcd              - Simulation waveform dump
waveform/sync_fifo_waveform.png     - Waveform preview image
docs/fifo_assertions_reference.sv   - Reference SVA properties for commercial simulators
```

## Author
Abhijit Karale — RTL Design & Verification
