// -----------------------------------------------------------------------------
// Module      : sync_fifo
// Description : Parameterizable synchronous FIFO with full/empty flags
// Author      : Abhijit Karale
// -----------------------------------------------------------------------------
module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16 
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             wr_en,
    input  logic             rd_en,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout,
    output logic             full,
    output logic             empty,
    output logic [$clog2(DEPTH):0] fifo_count
);

    localparam PTR_W = $clog2(DEPTH);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_W:0]   wr_ptr, rd_ptr;

    assign empty      = (wr_ptr == rd_ptr);
    assign full        = (wr_ptr[PTR_W] != rd_ptr[PTR_W]) &&
                         (wr_ptr[PTR_W-1:0] == rd_ptr[PTR_W-1:0]);
    assign fifo_count = wr_ptr - rd_ptr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[PTR_W-1:0]] <= din;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= '0;
            dout   <= '0;
        end else if (rd_en && !empty) begin
            dout   <= mem[rd_ptr[PTR_W-1:0]];
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Note: Formal-style SVA properties for this design (verified on
    // QuestaSim/Xcelium/VCS) are provided separately in
    // verification/fifo_assertions.sv - Icarus Verilog (used for the
    // open-source demo/regression in this repo) has limited SVA support,
    // so equivalent checks are instead enforced via immediate assertions
    // in the testbench scoreboard.

endmodule
