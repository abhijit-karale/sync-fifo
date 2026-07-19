#!/bin/bash
# Compile and simulate the synchronous FIFO with Icarus Verilog, then
# regenerate the waveform preview PNG from the resulting VCD.
set -e
iverilog -g2012 -o sim.out rtl/sync_fifo.sv tb/tb_sync_fifo.sv
vvp sim.out
python3 vcd_plot.py waveform/sync_fifo.vcd waveform/sync_fifo_waveform.png \
    clk rst_n wr_en rd_en din dout full empty --window 0 400
echo "Done. Open waveform/sync_fifo.vcd in GTKWave for full interactive waveform."
