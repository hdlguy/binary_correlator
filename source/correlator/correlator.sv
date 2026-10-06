// correlator.sv
//
// Streaming binary correlator for lidar pulse compression (see doc/correlator_spec.md).
//
// Data and template are 1-bit, 0 = +1 and 1 = -1. Every input sample produces one output:
//
//     y[n] = sum_{i=0}^{N_TAPS-1} x[n-N_TAPS+1+i] * t[i]  =  N_TAPS - 2*popcount(window ^ TEMPLATE)
//
// The window holds the N_TAPS most recent samples, oldest at bit 0, so it lines up with
// TEMPLATE[i] = seq(i+1). The popcount is a fully parallel, fully pipelined tree:
// 6-bit LUT counters followed by a registered binary adder tree. The tree runs every
// clock; only the delay line is enabled by s_tvalid. m_tvalid and m_tlast are s_tvalid
// and s_tlast delayed by LATENCY clocks.

module correlator #(
    parameter int                N_TAPS   = 1023,
    parameter logic [N_TAPS-1:0] TEMPLATE = template_pkg::TEMPLATE_1023[N_TAPS-1:0]
)(
    input   logic           clk,
    input   logic           rst,        // synchronous, active high; clears valid pipeline
    //
    input   logic           s_tvalid,   // at most one valid every 2 clocks
    output  logic           s_tready,
    input   logic           s_tdata,    // 1-bit data (0,1) interpreted as (+1,-1)
    input   logic           s_tlast,
    //
    output  logic           m_tvalid,
    output  logic [15:0]    m_tdata,    // signed correlation, -N_TAPS..+N_TAPS
    output  logic           m_tlast
);

    localparam int GRP   = 6;                           // bits per LUT counter
    localparam int N_GRP = (N_TAPS + GRP - 1) / GRP;
    localparam int SUM_W = $clog2(N_TAPS + 1);

    function automatic int tree_levels(int n);
        int l = 0;
        while (n > 1) begin
            n = (n + 1) / 2;
            l++;
        end
        return l;
    endfunction

    function automatic int level_nodes(int n, int lvl);
        for (int l = 0; l < lvl; l++) n = (n + 1) / 2;
        return n;
    endfunction

    localparam int N_LVL = tree_levels(N_GRP);

    // input reg + delay line + group count + N_LVL adder levels + output reg
    localparam int LATENCY = 4 + N_LVL;

    assign s_tready = 1'b1;

    // input register
    (* max_fanout = 64 *) logic in_valid;
    logic in_data;
    always_ff @(posedge clk) begin
        in_valid <= s_tvalid;
        in_data  <= s_tdata;
    end

    // delay line: newest sample enters at the top, oldest at bit 0
    logic [N_TAPS-1:0] window = '0;
    always_ff @(posedge clk) begin
        if (in_valid) window <= {in_data, window[N_TAPS-1:1]};
    end

    // mismatch bits, zero padded to a whole number of groups
    logic [N_GRP*GRP-1:0] mismatch;
    assign mismatch = (N_GRP*GRP)'(window ^ TEMPLATE);

    // popcount tree; node[l][j] holds level l, node j. Level 0 is the 6-bit counts.
    logic [SUM_W-1:0] node [N_LVL+1][N_GRP];

    for (genvar j = 0; j < N_GRP; j++) begin : g_count
        always_ff @(posedge clk) begin
            node[0][j] <= SUM_W'($countones(mismatch[j*GRP +: GRP]));
        end
    end

    for (genvar l = 1; l <= N_LVL; l++) begin : g_level
        localparam int N_PREV = level_nodes(N_GRP, l - 1);
        for (genvar j = 0; j < level_nodes(N_GRP, l); j++) begin : g_node
            always_ff @(posedge clk) begin
                if (2*j + 1 < N_PREV) node[l][j] <= node[l-1][2*j] + node[l-1][2*j+1];
                else                  node[l][j] <= node[l-1][2*j];
            end
        end
    end

    // y = N_TAPS - 2*popcount
    always_ff @(posedge clk) begin
        m_tdata <= 16'(N_TAPS) - 16'({node[N_LVL][0], 1'b0});
    end

    // valid and last pipeline
    logic [LATENCY-1:0] vpipe, lpipe;
    always_ff @(posedge clk) begin
        vpipe <= {vpipe[LATENCY-2:0], s_tvalid};
        lpipe <= {lpipe[LATENCY-2:0], s_tlast};
        if (rst) vpipe <= '0;
    end
    assign m_tvalid = vpipe[LATENCY-1];
    assign m_tlast  = lpipe[LATENCY-1] & vpipe[LATENCY-1];

endmodule
