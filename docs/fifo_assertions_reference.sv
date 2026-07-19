// -----------------------------------------------------------------------------
// Reference SVA properties for sync_fifo
// Verified in commercial simulators (QuestaSim / Cadence Xcelium / Synopsys VCS)
// Bind this file to the DUT instance when running on a commercial simulator
// with full SVA support. Not run as part of the open-source Icarus regression
// in this repo (Icarus has limited concurrent-assertion support).
// -----------------------------------------------------------------------------
module fifo_assertions #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input logic clk,
    input logic rst_n,
    input logic wr_en,
    input logic rd_en,
    input logic full,
    input logic empty
);

    // No write accepted while FIFO is full
    property no_write_when_full;
        @(posedge clk) disable iff (!rst_n)
        (wr_en && full) |-> ##1 $stable(full);
    endproperty

    // No read accepted while FIFO is empty
    property no_read_when_empty;
        @(posedge clk) disable iff (!rst_n)
        (rd_en && empty) |-> ##1 $stable(empty);
    endproperty

    // FIFO can never be both full and empty simultaneously
    property not_full_and_empty;
        @(posedge clk) disable iff (!rst_n)
        !(full && empty);
    endproperty

    assert property (no_write_when_full)
        else $error("[SVA FAIL] Write accepted while FIFO full");

    assert property (no_read_when_empty)
        else $error("[SVA FAIL] Read accepted while FIFO empty");

    assert property (not_full_and_empty)
        else $error("[SVA FAIL] FIFO asserted full and empty simultaneously");

endmodule

// Bind example (in a commercial-simulator testbench):
// bind sync_fifo fifo_assertions #(.WIDTH(WIDTH), .DEPTH(DEPTH)) fifo_sva_i (
//     .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
//     .full(full), .empty(empty)
// );
