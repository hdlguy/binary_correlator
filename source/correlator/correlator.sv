// correlator.sv

module correlator #(
)(
    input   logic       clk,
    //
    input   logic       s_tvalid,
    output  logic       s_tready,
    input   logic       s_tdata, // 1-bit data(0,1) interpreted as (+1,-1)
    input   logic       s_tlast,
    //
    input   logic       m_tvalid,
    output  logic[15:0] m_tready,
    input   logic       m_tdata,
    input   logic       m_tlast
);

endmodule


