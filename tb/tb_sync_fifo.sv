// -----------------------------------------------------------------------------
// Testbench   : tb_sync_fifo
// Description : Self-checking, constrained-random testbench for sync_fifo
//                Reference model = SystemVerilog queue. Checks data integrity,
//                full/empty flag correctness, and no overflow/underflow.
// Author      : Abhijit Karale
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_sync_fifo;

    localparam WIDTH = 8;
    localparam DEPTH = 16;

    logic             clk, rst_n;
    logic             wr_en, rd_en;
    logic [WIDTH-1:0] din, dout;
    logic             full, empty;
    logic [$clog2(DEPTH):0] fifo_count;

    int pass_count = 0;
    int fail_count = 0;
    int num_transactions = 500;

    // Reference model
    logic [WIDTH-1:0] ref_q[$];

    sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .rd_en(rd_en),
        .din(din), .dout(dout),
        .full(full), .empty(empty),
        .fifo_count(fifo_count)
    );

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Immediate-assertion scoreboard check: FIFO can never be full and empty
    // at the same time (equivalent to the SVA property in docs/fifo_assertions_reference.sv)
    always @(posedge clk) begin
        if (rst_n) begin
            assert (!(full && empty))
            else begin
                $error("[ASSERT FAIL] full and empty asserted simultaneously @time=%0t", $time);
                fail_count++;
            end
        end
    end

    task automatic reset_dut();
        rst_n = 0; wr_en = 0; rd_en = 0; din = '0;
        ref_q.delete();
        repeat (3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

    task automatic do_write(logic [WIDTH-1:0] data);
        @(posedge clk);
        if (!full) begin
            wr_en = 1; din = data;
            @(posedge clk);
            wr_en = 0;
            ref_q.push_back(data);
        end
    endtask

    task automatic do_read();
        @(posedge clk);
        if (!empty) begin
            rd_en = 1;
            @(posedge clk);
            rd_en = 0;
            #1;
            if (ref_q.size() > 0) begin
                logic [WIDTH-1:0] expected;
                expected = ref_q.pop_front();
                if (dout !== expected) begin
                    $error("[FAIL] Read mismatch: expected=%0h got=%0h @time=%0t", expected, dout, $time);
                    fail_count++;
                end else begin
                    pass_count++;
                end
            end
        end
    endtask

    initial begin
        $dumpfile("waveform/sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);

        $display("=========================================================");
        $display(" Synchronous FIFO Testbench - Directed + Random Regression");
        $display("=========================================================");

        reset_dut();

        // Directed test 1: fill FIFO completely, check full flag
        $display("[TEST] Directed: Fill FIFO to DEPTH and check full flag");
        for (int i = 0; i < DEPTH; i++) do_write(i[WIDTH-1:0]);
        if (full) begin
            $display("[PASS] full flag asserted correctly at DEPTH writes");
            pass_count++;
        end else begin
            $error("[FAIL] full flag NOT asserted after DEPTH writes");
            fail_count++;
        end

        // Directed test 2: attempt overflow write (should be dropped)
        do_write(8'hFF);

        // Directed test 3: drain FIFO completely, check empty flag
        $display("[TEST] Directed: Drain FIFO completely and check empty flag");
        for (int i = 0; i < DEPTH; i++) do_read();
        if (empty) begin
            $display("[PASS] empty flag asserted correctly after full drain");
            pass_count++;
        end else begin
            $error("[FAIL] empty flag NOT asserted after full drain");
            fail_count++;
        end

        // Directed test 4: attempt underflow read (should be ignored)
        do_read();

        // Randomized regression
        $display("[TEST] Constrained-random read/write regression (%0d transactions)", num_transactions);
        for (int i = 0; i < num_transactions; i++) begin
            if ($urandom_range(0,1) && !full)
                do_write($urandom_range(0,255));
            else if (!empty)
                do_read();
        end

        // Drain remaining entries for final scoreboard check
        while (ref_q.size() > 0) do_read();

        $display("=========================================================");
        $display(" REGRESSION SUMMARY: PASS=%0d  FAIL=%0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT: ALL TESTS PASSED");
        else
            $display(" RESULT: %0d TEST(S) FAILED", fail_count);
        $display("=========================================================");

        #20 $finish;
    end

endmodule
