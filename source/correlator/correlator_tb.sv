// correlator_tb.sv
//
// Self-checking testbench for correlator.sv (see doc/correlator_spec.md, Verification).
// Every output is compared with a behavioral model computed directly from the definition,
// and must arrive exactly dut.LATENCY clocks after its input with the matching tlast.
// Outputs whose window reaches back before the first sample after reset are undefined
// and are not compared.
//
// Run with -generic_top N_TAPS=127 or N_TAPS=1023.

`timescale 1ns / 1ps

module correlator_tb #(
    parameter int N_TAPS = 1023
);

    localparam logic [N_TAPS-1:0] TEMPLATE =
        (N_TAPS == 127)  ? template_pkg::TEMPLATE_127[N_TAPS-1:0]  :
        (N_TAPS == 1023) ? template_pkg::TEMPLATE_1023[N_TAPS-1:0] :
                           template_pkg::TEMPLATE_4095[N_TAPS-1:0];
    localparam int REC_LEN = 3 * N_TAPS;

    logic        clk = 0;
    logic        rst = 1;
    logic        s_tvalid = 0, s_tdata = 0, s_tlast = 0;
    logic        s_tready;
    logic        m_tvalid, m_tlast;
    logic [15:0] m_tdata;

    always #1.6667 clk = ~clk;  // 300 MHz

    correlator #(.N_TAPS(N_TAPS), .TEMPLATE(TEMPLATE)) dut (.*);

    // ---------------- reference model and scoreboard ----------------

    typedef struct {
        int  y;
        bit  last;
        bit  check;
        longint cycle;
    } exp_t;

    longint cycle = 0;
    always @(posedge clk) cycle <= cycle + 1;

    bit     hist [$];       // input samples since reset, oldest first
    exp_t   exp_q [$];
    int     out_y [$];      // DUT outputs of the current record, for peak checks
    int     n_out = 0, n_checked = 0, n_err = 0;

    function automatic int ref_corr();
        int y = 0;
        int base = hist.size() - N_TAPS;
        for (int i = 0; i < N_TAPS; i++)
            y += ((hist[base + i] ^ TEMPLATE[i]) ? -1 : 1);
        return y;
    endfunction

    // model: sample inputs on the same edge as the DUT
    always @(posedge clk) begin
        if (s_tvalid) begin
            exp_t e;
            hist.push_back(s_tdata);
            e.check = (hist.size() >= N_TAPS);
            e.y     = e.check ? ref_corr() : 0;
            e.last  = s_tlast;
            e.cycle = cycle;
            exp_q.push_back(e);
            if (hist.size() > N_TAPS) void'(hist.pop_front());
        end
    end

    // checker
    always @(posedge clk) begin
        if (m_tvalid) begin
            exp_t e;
            int   y;
            y = $signed(m_tdata);
            n_out++;
            out_y.push_back(y);
            if (exp_q.size() == 0) begin
                $error("output with no matching input at cycle %0d", cycle);
                n_err++;
            end else begin
                e = exp_q.pop_front();
                if (cycle - e.cycle != dut.LATENCY) begin
                    $error("latency %0d, expected %0d", cycle - e.cycle, dut.LATENCY);
                    n_err++;
                end
                if (m_tlast !== e.last) begin
                    $error("m_tlast %b, expected %b at output %0d", m_tlast, e.last, n_out);
                    n_err++;
                end
                if (e.check) begin
                    n_checked++;
                    if (y != e.y) begin
                        if (n_err < 20) $error("output %0d: y = %0d, expected %0d", n_out, y, e.y);
                        n_err++;
                    end
                end
            end
        end
    end

    // ---------------- stimulus ----------------

    int max_gap = 1;        // extra idle clocks are random in 0..max_gap-1 (on top of the mandatory 1)

    task automatic send(input bit d, input bit last);
        s_tvalid <= 1; s_tdata <= d; s_tlast <= last;
        @(posedge clk);
        s_tvalid <= 0; s_tdata <= 0; s_tlast <= 0;
        @(posedge clk);
        repeat ($urandom_range(max_gap - 1, 0)) @(posedge clk);
    endtask

    // one record of REC_LEN samples; the code starts at sample `delay` (<0 for none),
    // background is `fill` (0, 1, or 2 = random), each sample flipped with probability flip_pct%
    task automatic send_record(input int delay, input int fill, input int flip_pct);
        for (int n = 0; n < REC_LEN; n++) begin
            bit d;
            if (delay >= 0 && n >= delay && n < delay + N_TAPS) d = TEMPLATE[n - delay];
            else if (fill == 2) d = $urandom_range(1, 0);
            else                d = fill[0];
            if ($urandom_range(99, 0) < flip_pct) d = ~d;
            send(d, n == REC_LEN - 1);
        end
    endtask

    task automatic drain();
        repeat (dut.LATENCY + 4) @(posedge clk);
    endtask

    // the peak of the last record's outputs must be at output delay + N_TAPS - 1
    task automatic check_peak(input string name, input int delay, input int min_peak);
        int best = -100000, best_i = -1;
        foreach (out_y[i]) if (out_y[i] > best) begin best = out_y[i]; best_i = i; end
        if (best_i != delay + N_TAPS - 1 || best < min_peak) begin
            $error("%s: peak %0d at output %0d, expected >= %0d at output %0d",
                   name, best, best_i, min_peak, delay + N_TAPS - 1);
            n_err++;
        end else
            $display("  %-28s peak %5d at output %5d  ok", name, best, best_i);
    endtask

    task automatic run_record(input string name, input int delay, input int fill,
                              input int flip_pct, input int min_peak);
        out_y.delete();
        send_record(delay, fill, flip_pct);
        drain();
        if (out_y.size() != REC_LEN) begin
            $error("%s: %0d outputs, expected %0d", name, out_y.size(), REC_LEN);
            n_err++;
        end
        if (delay >= 0) check_peak(name, delay, min_peak);
        else            $display("  %-28s done", name);
    endtask

    int delays [] = '{0, 1, N_TAPS/2, N_TAPS-1, 2*N_TAPS};

    initial begin
        $display("correlator_tb: N_TAPS=%0d LATENCY=%0d", N_TAPS, dut.LATENCY);
        repeat (10) @(posedge clk);
        rst <= 0;
        repeat (5) @(posedge clk);

        // 1. code at several delays on random background
        foreach (delays[k])
            run_record($sformatf("clean, delay %0d", delays[k]), delays[k], 2, 0, N_TAPS);

        // 2. with 10% bit flips
        run_record("10% flips, delay 37", 37, 2, 10, N_TAPS/2);
        run_record("10% flips, delay 4N/3", 4*N_TAPS/3, 2, 10, N_TAPS/2);

        // 3. random data, 4. constant data
        run_record("random", -1, 2, 0, 0);
        run_record("all zeros", -1, 0, 0, 0);
        run_record("all ones", -1, 1, 0, 0);

        // 5. records separated by a long gap, then back to back
        repeat (500) @(posedge clk);
        run_record("after gap, delay 5", 5, 2, 0, N_TAPS);
        out_y.delete();
        send_record(10, 2, 0);
        send_record(N_TAPS, 2, 0);
        drain();
        if (out_y.size() != 2*REC_LEN) begin
            $error("back to back: %0d outputs, expected %0d", out_y.size(), 2*REC_LEN);
            n_err++;
        end else
            $display("  %-28s done", "back to back records");

        // 6. irregular valid spacing
        max_gap = 4;
        run_record("irregular gaps, delay 99", 99, 2, 0, N_TAPS);
        max_gap = 1;

        // reset in the middle of the stream; the model restarts too
        rst <= 1;
        @(posedge clk);
        rst <= 0;
        hist.delete();
        exp_q.delete();
        run_record("after reset, delay 0", 0, 2, 0, N_TAPS);

        drain();
        if (exp_q.size() != 0) begin
            $error("%0d expected outputs never arrived", exp_q.size());
            n_err++;
        end
        $display("correlator_tb: %0d outputs, %0d compared, %0d errors", n_out, n_checked, n_err);
        if (n_err == 0) $display("TEST PASSED");
        else            $display("TEST FAILED");
        $finish;
    end

endmodule
