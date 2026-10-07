// datagen.sv
//
// Synthetic data source: plays a 1-bit record from block ROM as an AXI stream, in a
// continuous loop. The ROM is loaded from a $readmemb file made by octave/gen_rom_data.m
// (one bit per line, sample 0 first, 0 = +1 and 1 = -1). m_tlast marks the last sample
// of each pass. There is no backpressure; the stream feeds the correlator directly.
//
// Rate: full_rate = 0 gives one sample every 2 clocks (150 Msps at 300 MHz),
// full_rate = 1 gives one sample every clock.

module datagen #(
    parameter int    LEN      = 3069,
    parameter string MEM_FILE = "rx_record.mem"
)(
    input   logic   clk,
    input   logic   rst,        // synchronous, active high; restarts at sample 0
    input   logic   enable,
    input   logic   full_rate,
    //
    output  logic   m_tvalid,
    output  logic   m_tdata,
    output  logic   m_tlast
);

    localparam int AW = $clog2(LEN);

    (* rom_style = "block" *) logic [0:0] rom [0:LEN-1];
    initial $readmemb(MEM_FILE, rom);

    // issue one sample per clock, or every other clock
    logic          phase;
    logic          issue;
    logic [AW-1:0] addr;

    assign issue = enable & (full_rate | phase);

    always_ff @(posedge clk) begin
        phase <= ~phase;
        if (issue) addr <= (addr == AW'(LEN - 1)) ? '0 : addr + 1'b1;
        if (rst) begin
            phase <= 1'b0;
            addr  <= '0;
        end
    end

    // ROM read pipeline for 300 MHz: addr_q keeps the counter logic off the BRAM address
    // pins (synthesis absorbs it into the BRAM address register), and rd_data_q is the
    // BRAM output register.
    logic [AW-1:0] addr_q;
    logic          rd_data, rd_data_q;
    logic [2:0]    vpipe, lpipe;
    always_ff @(posedge clk) begin
        addr_q    <= addr;
        rd_data   <= rom[addr_q];
        rd_data_q <= rd_data;
        vpipe     <= {vpipe[1:0], issue};
        lpipe     <= {lpipe[1:0], issue & (addr == AW'(LEN - 1))};
        if (rst) vpipe <= '0;
    end

    assign m_tvalid = vpipe[2];
    assign m_tdata  = rd_data_q;
    assign m_tlast  = lpipe[2] & vpipe[2];

endmodule
