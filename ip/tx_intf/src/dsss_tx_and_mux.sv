// dsss_tx_and_mux.sv  —  TX-2c integration wrapper for the DSSS transmitter
// ---------------------------------------------------------------------------
// Sibling of rx_intf/src/dsss_rx_and_mux.sv (same structural style). Drops the
// verified dsss_tx modulator into openwifi's TX datapath and arbitrates, per
// frame, between OFDM (openofdm_tx) and DSSS (1 Mbps 802.11b) on the latched
// is_dsss = phy_hdr_config_current[21] selector. All selection lives HERE so
// the DSSS-vs-OFDM decision is in one place (DSSS_TX2_SCOPE.md §2 TX-2c, §9.3).
//
// Topology (DSSS_TX2_SCOPE.md §1, corrected by §9 / §10):
//   * SAMPLE MUX (pre-gain): dsss_mux_rf_* feeds tx_iq_intf's rf_i/rf_q/rf_iq_valid
//     INPUTS (which today are plain forwards of rf_*_from_acc). DSSS samples are
//     NOT bypassed around gain — they pass through bb_gain + csi_fuzzer like OFDM.
//   * GAIN/FUZZER MUX: dsss_tx bakes SCALE=24, and tx_iq_intf packs rf_i*bb_gain
//     then >>7 (tx_iq_intf.v:95,118-119). So for DSSS pick bb_gain=128 (unity:
//     128>>7=1; bb_gain=1 would be -42 dB) and fuzzer taps 0 (csi_fuzzer is
//     ADDITIVE, csi_fuzzer.v:63-64, so taps 0 = exact passthrough +1 fixed cyc).
//     These regs are GLOBAL slv_reg13/slv_reg5 (not per-packet), so the select is
//     RTL here, NOT a driver per-frame write.
//   * START GATE: ofdm_phy_tx_start_gated = phy_tx_start & ~is_dsss feeds
//     openofdm_tx (via the BD, TX-2f) so it does not free-run on a DSSS frame.
//   * DONE/STARTED MUX: muxed_tx_* are computed FROM the raw openofdm inputs
//     (tx_end/start_from_acc). TX-2f must re-source ONLY the sibling cells
//     (xpu_0 / side_ch_0) from these — re-driving tx_intf's OWN tx_end_from_acc
//     input from the muxed output is a combinational loop on OFDM frames (§9.1).
//   * BRAM-ADDR TIME-MUX: bram_addr_muxed drives tx_bit_intf port B; time-muxing
//     the shared payload BRAM is safe ONLY because openofdm_tx is start-gated off
//     during DSSS (it owns that port otherwise).
//
// No FIFO/buffer here (DSSS_TX_PLAN.md:107) — dsss_tx is paced by sample_ready =
// ~tx_hold, the same backpressure OFDM honors. Single 100 MHz acc clock, no CDC.
// ---------------------------------------------------------------------------
`timescale 1ns/1ps
module dsss_tx_and_mux #(
    parameter integer IQ_DATA_WIDTH          = 16,
    parameter integer CSI_FUZZER_WIDTH       = 7,   // = tx_intf's value (overrides tx_iq_intf default 6)
    parameter integer WIFI_TX_BRAM_ADDR_WIDTH = 10
)(
    input  wire                              clk,    // s00_axis_aclk, 100 MHz acc domain
    input  wire                              rstn,   // active-low (s00_axis_aresetn & ~slv_reg0[bit])

    input  wire                              is_dsss,        // per-frame selector (latched in tx_bit_intf)
    input  wire                              is_dsss_ack,    // 1 = this DSSS frame is the auto-ACK -> dsss_tx uses
                                                             //   the SHORT SIFS lead-in (held by tx_control across the ACK)
    input  wire                              phy_tx_start,   // shared start pulse (tx_bit_intf.start)

    // ---- OFDM baseband from openofdm_tx (tx_intf rf_*_from_acc inputs) ----
    input  wire signed [IQ_DATA_WIDTH-1:0]   rf_i_from_acc,
    input  wire signed [IQ_DATA_WIDTH-1:0]   rf_q_from_acc,
    input  wire                              rf_iq_valid_from_acc,

    // ---- downstream pacing + frame length ----
    input  wire                              tx_hold,        // tx_iq_intf FIFO backpressure
    input  wire        [12:0]                len_psdu,       // phy_hdr_config[12:0], DSSS payload octets (excl FCS)

    // ---- shared payload BRAM port B: openofdm's address (the DSSS read address now
    //      comes from the opendsss_tx cell; its read data taps data_to_acc at the BD) ----
    input  wire        [WIFI_TX_BRAM_ADDR_WIDTH-1:0] ofdm_bram_addr, // openofdm_tx's bram_addr (tx_intf input)

    // ---- raw openofdm done/started (NEVER drive these from the muxed outputs) ----
    input  wire                              tx_end_from_acc,   // openofdm phy_tx_done
    input  wire                              tx_start_from_acc, // openofdm phy_tx_started

    // ---- global gain / fuzzer regs (slv_reg13 / slv_reg5) ----
    input  wire signed [9:0]                 bb_gain_in,
    input  wire signed [CSI_FUZZER_WIDTH-1:0] bb_gain1_in,
    input  wire signed [CSI_FUZZER_WIDTH-1:0] bb_gain2_in,

    // ---- muxed sample stream -> tx_iq_intf rf_i/rf_q/rf_iq_valid ----
    output wire signed [IQ_DATA_WIDTH-1:0]   dsss_mux_rf_i,
    output wire signed [IQ_DATA_WIDTH-1:0]   dsss_mux_rf_q,
    output wire                              dsss_mux_rf_iq_valid,

    // ---- muxed BRAM address -> tx_bit_intf port B addrb ----
    output wire        [WIFI_TX_BRAM_ADDR_WIDTH-1:0] bram_addr_muxed,

    // ---- start gate -> openofdm_tx/phy_tx_start (via BD) ----
    output wire                              ofdm_phy_tx_start_gated,

    // ---- done/started mux (export to BD for the xpu/side_ch re-source) ----
    output wire                              muxed_tx_end,
    output wire                              muxed_tx_started,

    // ---- gain / fuzzer mux -> tx_iq_intf ----
    output wire signed [9:0]                 bb_gain_muxed,
    output wire signed [CSI_FUZZER_WIDTH-1:0] bb_gain1_muxed,
    output wire signed [CSI_FUZZER_WIDTH-1:0] bb_gain2_muxed,

    // ---- opendsss_tx BD IP cell interface (B-clean, plan D3) ----
    // The raw dsss_tx modulator moved OUT to the first-class opendsss_tx_0 cell. This
    // arbiter drives the cell's inputs and consumes its outputs via these ports; all the
    // muxing/gating below is byte-identical to before. The cell taps the shared payload
    // BRAM read data (tx_intf's data_to_acc) directly at the BD, so no bram_rd_data here.
    output wire                              dsss_tx_reset,        // = ~rstn        -> opendsss_tx_0/reset
    output wire        [12:0]                dsss_tx_length,       // = len_psdu     -> /length
    output wire                              dsss_tx_go,           // = phy_tx_start & is_dsss -> /go
    output wire                              dsss_tx_ack_mode,     // = is_dsss_ack  -> /ack_mode
    output wire                              dsss_tx_sample_ready, // = ~tx_hold     -> /sample_ready
    input  wire        [WIFI_TX_BRAM_ADDR_WIDTH-1:0] dsss_tx_bram_rd_addr, // <- opendsss_tx_0/bram_rd_addr
    input  wire signed [IQ_DATA_WIDTH-1:0]   dsss_tx_sample_i,     // <- /sample_i
    input  wire signed [IQ_DATA_WIDTH-1:0]   dsss_tx_sample_q,     // <- /sample_q
    input  wire                              dsss_tx_sample_valid, // <- /sample_valid
    input  wire                              dsss_tx_busy,         // <- /busy
    input  wire                              dsss_tx_done,         // <- /done

    // ---- status ----
    output wire                              dsss_busy
);
    // dsss_tx modulator: now the external opendsss_tx BD IP cell (plan D3, B-clean).
    // Drive its inputs, and alias its outputs to the internal names the muxes below use,
    // so all downstream logic is unchanged.
    wire                              dsss_reset = ~rstn;                 // active-HIGH synchronous reset
    wire                              dsss_go    = phy_tx_start & is_dsss; // start only on a DSSS frame

    assign dsss_tx_reset        = dsss_reset;
    assign dsss_tx_length       = len_psdu;
    assign dsss_tx_go           = dsss_go;
    assign dsss_tx_ack_mode     = is_dsss_ack;   // SHORT lead-in for the auto-ACK (meets SIFS); data keeps full runway
    assign dsss_tx_sample_ready = ~tx_hold;      // same backpressure OFDM writes honor (tx_iq_intf.v:120)

    wire signed [IQ_DATA_WIDTH-1:0]    dsss_sample_i     = dsss_tx_sample_i;
    wire signed [IQ_DATA_WIDTH-1:0]    dsss_sample_q     = dsss_tx_sample_q;
    wire                               dsss_sample_valid = dsss_tx_sample_valid;
    wire                               dsss_busy_w       = dsss_tx_busy;
    wire                               dsss_done         = dsss_tx_done;
    wire [WIFI_TX_BRAM_ADDR_WIDTH-1:0] dsss_bram_rd_addr = dsss_tx_bram_rd_addr;

    // started = rising edge of busy (arming-only enable for search_indication;
    // first-non-zero would arm ~400 samples late and miss the FIFO empty->non-empty
    // edge — Q7 §9.6). One register; everything else is combinational.
    reg busy_d;
    always @(posedge clk) begin
        if (dsss_reset) busy_d <= 1'b0;
        else            busy_d <= dsss_busy_w;
    end
    wire dsss_started = dsss_busy_w & ~busy_d;

    // 2:1 sample mux (pre-gain): DSSS samples still pass through bb_gain + csi_fuzzer
    assign dsss_mux_rf_i        = is_dsss ? dsss_sample_i     : rf_i_from_acc;
    assign dsss_mux_rf_q        = is_dsss ? dsss_sample_q     : rf_q_from_acc;
    assign dsss_mux_rf_iq_valid = is_dsss ? dsss_sample_valid : rf_iq_valid_from_acc;

    // shared payload BRAM address: dsss_tx prefetch addr on DSSS, openofdm otherwise
    assign bram_addr_muxed = is_dsss ? dsss_bram_rd_addr : ofdm_bram_addr;

    // start-gate openofdm_tx off during a DSSS frame
    assign ofdm_phy_tx_start_gated = phy_tx_start & ~is_dsss;

    // done/started re-source (computed FROM the raw openofdm inputs; see §9.1)
    assign muxed_tx_end     = is_dsss ? dsss_done    : tx_end_from_acc;
    assign muxed_tx_started = is_dsss ? dsss_started : tx_start_from_acc;

    // gain/fuzzer select: DSSS -> unity bb_gain (128>>7=1) + fuzzer taps 0 (passthrough)
    assign bb_gain_muxed  = is_dsss ? 10'sd128 : bb_gain_in;
    assign bb_gain1_muxed = is_dsss ? {CSI_FUZZER_WIDTH{1'b0}} : bb_gain1_in;
    assign bb_gain2_muxed = is_dsss ? {CSI_FUZZER_WIDTH{1'b0}} : bb_gain2_in;

    assign dsss_busy = dsss_busy_w;
endmodule
