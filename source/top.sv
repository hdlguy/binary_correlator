// top.sv
//
// Arty A7-100T hardware test: ROM playback (datagen) -> correlator -> ILA.
//
//   clk100 (100 MHz board oscillator) -> MMCM -> clk (300 MHz), clk_ila (150 MHz)
//   ck_rst_n  red RESET button, active low; also held in reset until the MMCM locks
//   sw[0]     0 = 150 Msps (one sample every 2 clocks), 1 = 300 Msps (every clock)
//   led[0]    MMCM locked
//   led[1]    heartbeat, about 1 Hz
//   led[2]    full-rate mode
//   led[3]    off
//
// The ILA (top_ila, created by implement/setup.tcl) captures the datagen stream and the
// correlator output. Compare a capture with source/datagen/corr_expected.txt.
// The ILA core cannot meet 300 MHz on a -1 part, so it runs at 150 MHz and captures two
// 300 MHz cycles per sample as two lanes: lane 0 is the earlier cycle, lane 1 the later.
//   probe0 = lane 0 correlator {tlast, tvalid, tdata[15:0]}
//   probe1 = lane 1 correlator {tlast, tvalid, tdata[15:0]}
//   probe2 = datagen {lane 1 {tlast, tvalid, tdata}, lane 0 {tlast, tvalid, tdata}}
// At 150 Msps every valid sample lands in the same lane.

module top (
    input   logic       clk100,
    input   logic       ck_rst_n,
    input   logic [0:0] sw,
    output  logic [3:0] led
);

    // 100 MHz -> VCO 900 MHz -> 300 MHz (/3) and 150 MHz (/6), edge aligned
    logic clk, clk_mmcm, clk_ila, clk_ila_mmcm, clkfb, clkfb_buf, locked;

    MMCME2_BASE #(
        .CLKIN1_PERIOD      (10.0),
        .DIVCLK_DIVIDE      (1),
        .CLKFBOUT_MULT_F    (9.0),
        .CLKOUT0_DIVIDE_F   (3.0),
        .CLKOUT1_DIVIDE     (6)
    ) mmcm (
        .CLKIN1     (clk100),
        .CLKFBIN    (clkfb_buf),
        .CLKFBOUT   (clkfb),
        .CLKFBOUTB  (),
        .CLKOUT0    (clk_mmcm),
        .CLKOUT0B   (),
        .CLKOUT1    (clk_ila_mmcm), .CLKOUT1B (),
        .CLKOUT2    (), .CLKOUT2B (),
        .CLKOUT3    (), .CLKOUT3B (),
        .CLKOUT4    (), .CLKOUT5  (), .CLKOUT6 (),
        .LOCKED     (locked),
        .PWRDWN     (1'b0),
        .RST        (1'b0)
    );

    BUFG fb_buf  (.I(clkfb),    .O(clkfb_buf));
    BUFG clk_buf (.I(clk_mmcm), .O(clk));
    BUFG ila_buf (.I(clk_ila_mmcm), .O(clk_ila));

    // reset and switch synchronizers
    (* ASYNC_REG = "TRUE" *) logic [1:0] rst_sync = '1;
    (* ASYNC_REG = "TRUE" *) logic [1:0] sw_sync  = '0;
    logic rst, full_rate;

    always_ff @(posedge clk or negedge locked) begin
        if (!locked) rst_sync <= '1;
        else         rst_sync <= {rst_sync[0], ~ck_rst_n};
    end
    always_ff @(posedge clk) begin
        sw_sync <= {sw_sync[0], sw[0]};
        rst     <= rst_sync[1];
    end
    assign full_rate = sw_sync[1];

    // data source and correlator
    logic        d_tvalid, d_tdata, d_tlast;
    logic        c_tvalid, c_tlast;
    logic [15:0] c_tdata;

    datagen #(.LEN(3069), .MEM_FILE("rx_record.mem")) gen (
        .clk, .rst, .enable(1'b1), .full_rate,
        .m_tvalid(d_tvalid), .m_tdata(d_tdata), .m_tlast(d_tlast)
    );

    correlator corr (
        .clk, .rst,
        .s_tvalid(d_tvalid), .s_tready(), .s_tdata(d_tdata), .s_tlast(d_tlast),
        .m_tvalid(c_tvalid), .m_tdata(c_tdata), .m_tlast(c_tlast)
    );

    // ILA capture: register at 300 MHz, then take two cycles per 150 MHz clock
    logic [20:0] cap0, cap1;            // {d_tlast, d_tvalid, d_tdata, c_tlast, c_tvalid, c_tdata}
    logic [20:0] lane0, lane1;
    always_ff @(posedge clk) begin
        cap0 <= {d_tlast, d_tvalid, d_tdata, c_tlast, c_tvalid, c_tdata};
        cap1 <= cap0;
    end
    always_ff @(posedge clk_ila) begin
        lane0 <= cap1;                  // earlier 300 MHz cycle
        lane1 <= cap0;                  // later 300 MHz cycle
    end

    top_ila ila (
        .clk    (clk_ila),
        .probe0 (lane0[17:0]),
        .probe1 (lane1[17:0]),
        .probe2 ({lane1[20:18], lane0[20:18]})
    );

    // status LEDs
    logic [27:0] heartbeat = '0;
    always_ff @(posedge clk) heartbeat <= heartbeat + 1'b1;

    assign led = {1'b0, full_rate, heartbeat[27], locked};

endmodule
