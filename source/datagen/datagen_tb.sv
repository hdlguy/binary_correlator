// datagen_tb.sv
//
// Self-checking testbench for datagen.sv feeding correlator.sv. Checks that:
//   - datagen plays the ROM file in order, in a loop, with m_tlast on the last sample,
//     at one sample every 2 clocks (full_rate = 0) or every clock (full_rate = 1);
//   - the correlator output matches lidar_expected.txt from octave/gen_rom_data.m for
//     every output after the first pass (the first pass still holds reset values).
//
// Run from the simulate directory so the relative file paths resolve.

`timescale 1ns / 1ps

module datagen_tb;

    localparam int    LEN      = 3069;
    localparam string MEM_FILE = "../source/datagen/lidar_record.mem";
    localparam string EXP_FILE = "../source/datagen/lidar_expected.txt";
    localparam int    N_PASS   = 3;

    logic        clk = 0;
    logic        rst = 1;
    logic        enable = 0, full_rate = 0;
    logic        d_tvalid, d_tdata, d_tlast;
    logic        s_tready, m_tvalid, m_tlast;
    logic [15:0] m_tdata;

    always #1.6667 clk = ~clk;  // 300 MHz

    datagen #(.LEN(LEN), .MEM_FILE(MEM_FILE)) gen (
        .clk, .rst, .enable, .full_rate,
        .m_tvalid(d_tvalid), .m_tdata(d_tdata), .m_tlast(d_tlast)
    );

    correlator dut (
        .clk, .rst,
        .s_tvalid(d_tvalid), .s_tready, .s_tdata(d_tdata), .s_tlast(d_tlast),
        .m_tvalid, .m_tdata, .m_tlast
    );

    logic rom [LEN];
    int   expv [LEN];
    int   n_err = 0;

    // datagen stream checker
    int   n_in = 0;
    int   last_valid_cycle = -1, cycle = 0;
    always @(posedge clk) cycle <= cycle + 1;

    always @(posedge clk) if (d_tvalid) begin
        int i;
        i = n_in % LEN;
        if (d_tdata !== rom[i]) begin
            if (n_err < 10) $error("datagen sample %0d: %b, expected %b", n_in, d_tdata, rom[i]);
            n_err++;
        end
        if (d_tlast !== (i == LEN - 1)) begin
            $error("datagen tlast %b at sample %0d", d_tlast, n_in);
            n_err++;
        end
        if (last_valid_cycle >= 0 && cycle - last_valid_cycle != (full_rate ? 1 : 2)) begin
            $error("datagen spacing %0d clocks at sample %0d", cycle - last_valid_cycle, n_in);
            n_err++;
        end
        last_valid_cycle = cycle;
        n_in++;
    end

    // correlator output checker
    int n_out = 0, n_chk = 0;
    always @(posedge clk) if (m_tvalid) begin
        int i, y;
        i = n_out % LEN;
        y = $signed(m_tdata);
        if (m_tlast !== (i == LEN - 1)) begin
            $error("correlator tlast %b at output %0d", m_tlast, n_out);
            n_err++;
        end
        if (n_out >= LEN) begin
            n_chk++;
            if (y != expv[i]) begin
                if (n_err < 10) $error("output %0d (n = %0d): %0d, expected %0d", n_out, i, y, expv[i]);
                n_err++;
            end
        end
        n_out++;
    end

    task automatic run(input bit rate);
        rst <= 1; enable <= 0; full_rate <= rate;
        repeat (20) @(posedge clk);
        n_in = 0; n_out = 0; n_chk = 0; last_valid_cycle = -1;
        rst <= 0;
        @(posedge clk);
        enable <= 1;
        wait (n_out == N_PASS * LEN);
        @(posedge clk);
        enable <= 0;
        $display("  full_rate=%0d: %0d samples, %0d outputs, %0d compared with lidar_expected.txt",
                 rate, n_in, n_out, n_chk);
        repeat (50) @(posedge clk);
    endtask

    initial begin
        int fd;
        $readmemb(MEM_FILE, rom);
        fd = $fopen(EXP_FILE, "r");
        if (fd == 0) $fatal(1, "cannot open %s", EXP_FILE);
        for (int i = 0; i < LEN; i++) void'($fscanf(fd, "%d", expv[i]));
        $fclose(fd);

        $display("datagen_tb: LEN=%0d, %0d passes per rate", LEN, N_PASS);
        run(0);
        run(1);

        $display("datagen_tb: %0d errors", n_err);
        if (n_err == 0) $display("TEST PASSED");
        else            $display("TEST FAILED");
        $finish;
    end

endmodule
