// dsss_rx_and_mux.sv
// ---------------------------------------------------------------------------
// Phase-2 integration glue for the 802.11b 1 Mbps DSSS receiver (dsss_rx) into
// openwifi-hw's rx_intf.  It does three things:
//
//   1. Runs dsss_rx on the baseband sample stream (rf_i0/rf_q0 @ 20 MSPS, one
//      sample_valid pulse per sample, on the rx_intf acc clock).
//   2. Re-shapes dsss_rx's outputs into the SAME boundary waveform that
//      openofdm_rx presents to rx_intf, so all of rx_intf's existing
//      header/DMA logic (byte_to_word_fcs_sn_insert, rx_intf_pl_to_m_axis)
//      is reused unchanged:
//         * a one-cycle pkt_header_valid_strobe (good header) at frame start,
//         * pkt_len = PSDU octets INCLUDING the 4-byte FCS,
//         * byte_in / byte_in_strobe with byte_count = 0 .. pkt_len-1
//           (the last 4 bytes are the received FCS),
//         * fcs_in_strobe asserted EXACTLY 2 clocks after the last byte strobe
//           (so byte_to_word_fcs_sn_insert's 2-deep delay lands the {fcs_ok,sn}
//           substitution on the final byte, identical to openofdm_rx),
//         * pkt_rate = 0x00  -> driver internal rate_idx 0 -> 1 Mbps,
//         * ht_*/phase_offset = 0.
//   3. Arbitrates OFDM vs DSSS into one muxed signal set with strict OFDM
//      priority. DSSS is granted the downstream path only when no OFDM frame
//      is active AND openofdm_rx is not already receiving one: the grant is
//      gated on ofdm_early_active (openofdm_rx demod_is_ongoing, asserted from
//      the OFDM long preamble) so DSSS cannot seize the path during an OFDM
//      preamble. A decoded OFDM header (ofdm_sig_valid) PREEMPTS an in-flight
//      DSSS frame: the DSSS FSM drops to D_IDLE and the OFDM header strobe is
//      forwarded the same cycle (see `sel` below), which also re-syncs the
//      downstream byte_to_word. A watchdog still releases the path if a DSSS
//      frame never completes.
//
// NOTE: ofdm_early_active is a NEW input. rx_intf.v gains a matching
// demod_is_ongoing input port, and system.bd must connect
// openofdm_rx_0/demod_is_ongoing -> rx_intf_0/demod_is_ongoing (a one-time
// block-design regeneration).
// ---------------------------------------------------------------------------
`timescale 1ns/1ps
module dsss_rx_and_mux #(
    parameter integer WATCHDOG_BITS = 21   // ~2^21 acc clocks (~21 ms @100MHz) frame guard
)(
    input  wire               clk,            // rx_intf acc clock (m00_axis_aclk)
    input  wire               rstn,           // active-low (m00_axis_aresetn & ...)
    input  wire               dsss_enable,    // 1 = DSSS RX active (default), 0 = OFDM-only

    // ---- DSSS PHY decode bus (from the opendsss_rx BD IP cell, via rx_intf ports) ----
    // B-clean (plan D3): dsss_rx_fb moved OUT of this arbiter to a first-class BD IP
    // cell (opendsss_rx_0). Its decode outputs now arrive here as input ports instead
    // of an internal instance. The baseband samples the PHY consumes are tapped at the
    // BD level (same sample net that feeds openofdm_rx), so this arbiter no longer sees
    // sample_i/q. params_datarate is dropped (it was always unused / WLAN_RATE_1=0).
    input  wire        [12:0] d_params_length,
    input  wire               d_params_valid,
    input  wire        [7:0]  d_data,
    input  wire               d_data_valid,
    input  wire               d_framer_done,
    input  wire               d_crc_correct,
    input  wire        [31:0] d_fcs_out,

    // ---- OFDM path (from openofdm_rx, i.e. rx_intf's input ports) ----
    input  wire               ofdm_pkt_header_valid,
    input  wire               ofdm_pkt_header_valid_strobe,
    input  wire               ofdm_ht_unsupport,
    input  wire        [7:0]  ofdm_pkt_rate,
    input  wire        [15:0] ofdm_pkt_len,
    input  wire               ofdm_ht_aggr,
    input  wire               ofdm_ht_aggr_last,
    input  wire               ofdm_ht_sgi,
    input  wire        [7:0]  ofdm_byte_in,
    input  wire               ofdm_byte_in_strobe,
    input  wire        [15:0] ofdm_byte_count,
    input  wire               ofdm_fcs_in_strobe,
    input  wire               ofdm_fcs_ok,
    input  wire signed [31:0] ofdm_phase_offset_taken,
    input  wire               ofdm_early_active,  // openofdm_rx demod_is_ongoing: OFDM RX in progress (asserts at the long preamble, before the header)

    // ---- muxed result -> rx_intf downstream (byte_to_word / pl_to_m_axis) ----
    output wire               pkt_header_valid,
    output wire               pkt_header_valid_strobe,
    output wire               ht_unsupport,
    output wire        [7:0]  pkt_rate,
    output wire        [15:0] pkt_len,
    output wire               ht_aggr,
    output wire               ht_aggr_last,
    output wire               ht_sgi,
    output wire        [7:0]  byte_in,
    output wire               byte_in_strobe,
    output wire        [15:0] byte_count,
    output wire               fcs_in_strobe,
    output wire               fcs_ok,
    output wire signed [31:0] phase_offset_taken,

    // status / debug
    output wire               dsss_active     // 1 while a DSSS frame owns the path
);

    // ---------------------------------------------------------------
    // dsss_rx PHY: now the external opendsss_rx BD IP cell (plan D3, B-clean).
    // Its decode bus (d_params_*, d_data*, d_framer_done, d_crc_correct, d_fcs_out)
    // arrives via the input ports above. The gating that used to live here
    // (reset = (~rstn)|(~dsss_enable), sample_valid & dsss_enable) moved into the
    // opendsss_rx wrapper, so this path is behaviorally bit-identical.
    // ---------------------------------------------------------------

    // ---------------------------------------------------------------
    // OFDM busy tracker (for arbitration).  A good OFDM header opens a
    // frame; the FCS strobe closes it.  Bad headers (sig_invalid) do not
    // open a frame.
    // ---------------------------------------------------------------
    wire ofdm_sig_valid = ofdm_pkt_header_valid_strobe & ofdm_pkt_header_valid;
    reg  ofdm_busy;
    reg  [WATCHDOG_BITS-1:0] ofdm_wdog;
    always @(posedge clk) begin
        if (!rstn) begin
            ofdm_busy <= 1'b0;
            ofdm_wdog <= {WATCHDOG_BITS{1'b0}};
        end else if (ofdm_sig_valid) begin       // (re-)arm on a fresh good OFDM header
            ofdm_busy <= 1'b1;
            ofdm_wdog <= {WATCHDOG_BITS{1'b0}};
        end else if (ofdm_fcs_in_strobe) begin    // normal completion
            ofdm_busy <= 1'b0;
            ofdm_wdog <= {WATCHDOG_BITS{1'b0}};
        end else if (ofdm_busy) begin
            // guard: if an OFDM frame opens but never completes (aborted/garbled decode
            // with no fcs strobe), release the path so DSSS is not blocked indefinitely.
            if (ofdm_byte_in_strobe)
                ofdm_wdog <= {WATCHDOG_BITS{1'b0}};       // activity -> keep waiting
            else if (ofdm_wdog == {WATCHDOG_BITS{1'b1}})
                ofdm_busy <= 1'b0;
            else
                ofdm_wdog <= ofdm_wdog + 1'b1;
        end
    end

    // ---------------------------------------------------------------
    // DSSS byte/FCS sequencer + ownership FSM
    // ---------------------------------------------------------------
    localparam [2:0] D_IDLE    = 3'd0,
                     D_HDR     = 3'd1,
                     D_STREAM  = 3'd2,
                     D_FCS     = 3'd3,   // emit the 4 received FCS bytes
                     D_FCSWAIT = 3'd4,   // 1-cycle gap (no byte strobe)
                     D_FCSSTB  = 3'd5,   // schedule fcs_in_strobe (+2 after last byte)
                     D_FCSDONE = 3'd6;   // hold sel=1 while the registered fcs_in_strobe is high

    reg  [2:0]  dstate;
    reg  [15:0] d_pkt_len;
    reg  [15:0] d_byte_idx;          // 0-based index presented with each byte strobe
    reg  [31:0] d_fcs_lat;
    reg         d_crc_lat;
    reg  [1:0]  d_fcs_cnt;           // which FCS byte (0..3)
    reg  [3:0]  d_hold;              // tail hold so pkt_len/context stays valid
                                     // through byte_to_word's delayed final flush

    // registered DSSS-side outputs (clean single-cycle strobes)
    reg         d_phv_strobe;
    reg  [7:0]  d_byte_in;
    reg         d_byte_in_strobe;
    reg  [15:0] d_byte_count;
    reg         d_fcs_in_strobe;
    reg         d_fcs_ok;

    reg  [WATCHDOG_BITS-1:0] d_wdog;

    // grant DSSS the path only when OFDM is fully idle this cycle (strict OFDM
    // priority): no decoded OFDM frame open (~ofdm_busy), no good OFDM header this
    // cycle (~ofdm_sig_valid), AND openofdm_rx not mid-reception (~ofdm_early_active,
    // i.e. demod_is_ongoing low) so DSSS cannot grab the path during an OFDM preamble.
    wire dsss_grant = dsss_enable & d_params_valid & ~ofdm_busy & ~ofdm_sig_valid & ~ofdm_early_active;

    // selected FCS byte for the current D_FCS beat (stream order: LSByte first)
    reg [7:0] d_fcs_byte;
    always @(*) begin
        case (d_fcs_cnt)
            2'd0:    d_fcs_byte = d_fcs_lat[7:0];
            2'd1:    d_fcs_byte = d_fcs_lat[15:8];
            2'd2:    d_fcs_byte = d_fcs_lat[23:16];
            default: d_fcs_byte = d_fcs_lat[31:24];
        endcase
    end

    always @(posedge clk) begin
        // Reset the adapter FSM on global reset OR when DSSS is disabled, so dropping
        // dsss_enable mid-frame cannot strand the FSM (and the path) until the watchdog.
        if (!rstn || !dsss_enable) begin
            dstate           <= D_IDLE;
            d_pkt_len        <= 16'd0;
            d_byte_idx       <= 16'd0;
            d_fcs_lat        <= 32'd0;
            d_crc_lat        <= 1'b0;
            d_fcs_cnt        <= 2'd0;
            d_hold           <= 4'd0;
            d_phv_strobe     <= 1'b0;
            d_byte_in        <= 8'd0;
            d_byte_in_strobe <= 1'b0;
            d_byte_count     <= 16'd0;
            d_fcs_in_strobe  <= 1'b0;
            d_fcs_ok         <= 1'b0;
            d_wdog           <= {WATCHDOG_BITS{1'b0}};
        end else begin
            // strobe defaults
            d_phv_strobe     <= 1'b0;
            d_byte_in_strobe <= 1'b0;
            d_fcs_in_strobe  <= 1'b0;

            // watchdog: counts while a frame is open, cleared on any progress
            if (dstate == D_IDLE)
                d_wdog <= {WATCHDOG_BITS{1'b0}};
            else if (d_params_valid | d_data_valid | d_framer_done)
                d_wdog <= {WATCHDOG_BITS{1'b0}};
            else
                d_wdog <= d_wdog + 1'b1;

            case (dstate)
                D_IDLE: begin
                    d_byte_count <= 16'd0;   // clear any stale index (e.g. after a watchdog abort)
                    if (dsss_grant) begin
                        d_pkt_len    <= {3'd0, d_params_length} + 16'd4; // + 4-byte FCS
                        d_byte_idx   <= 16'd0;
                        d_phv_strobe <= 1'b1;                            // good-header pulse
                        dstate       <= D_HDR;
                    end
                end

                D_HDR: begin
                    // header pulse emitted; wait for payload bytes
                    dstate <= D_STREAM;
                end

                D_STREAM: begin
                    // forward each payload byte from dsss_rx
                    if (d_data_valid) begin
                        d_byte_in        <= d_data;
                        d_byte_count     <= d_byte_idx;
                        d_byte_in_strobe <= 1'b1;
                        d_byte_idx       <= d_byte_idx + 16'd1;
                    end
                    // framer_done => all payload bytes done, fcs_out valid
                    if (d_framer_done) begin
                        d_fcs_lat <= d_fcs_out;
                        d_crc_lat <= d_crc_correct;
                        d_fcs_cnt <= 2'd0;
                        dstate    <= D_FCS;
                    end
                end

                D_FCS: begin
                    // emit one received-FCS byte per cycle (4 total)
                    d_byte_in        <= d_fcs_byte;
                    d_byte_count     <= d_byte_idx;
                    d_byte_in_strobe <= 1'b1;
                    d_byte_idx       <= d_byte_idx + 16'd1;
                    d_fcs_cnt        <= d_fcs_cnt + 2'd1;
                    if (d_fcs_cnt == 2'd3)
                        dstate <= D_FCSWAIT;   // last FCS byte strobed this cycle
                end

                D_FCSWAIT: begin
                    // exactly one idle cycle so fcs_in_strobe lands +2 after the
                    // last byte strobe (matches openofdm_rx / byte_to_word delay).
                    // Present byte_count==pkt_len for THIS single cycle so
                    // byte_to_word_fcs_sn_insert's `byte_count_final==num_byte`
                    // final-partial-word flush fires exactly once (openofdm holds
                    // byte_count at pkt_len for one cycle then drops it).
                    d_byte_count <= d_pkt_len;
                    dstate       <= D_FCSSTB;
                end

                D_FCSSTB: begin
                    d_byte_count    <= 16'd0;     // drop so the flush triggers only once
                    d_fcs_in_strobe <= 1'b1;      // registered: asserts next cycle (D_FCSDONE)
                    d_fcs_ok        <= d_crc_lat;
                    d_hold          <= 4'd8;
                    dstate          <= D_FCSDONE;
                end

                D_FCSDONE: begin
                    // fcs_in_strobe pulses for one cycle here (sel still 1, so it reaches
                    // downstream). Hold sel=1 a few more cycles so the muxed pkt_len/context
                    // stays valid through byte_to_word_fcs_sn_insert's 2-cycle-delayed final
                    // partial-word flush (byte_count_final==num_byte) and its forwarding.
                    if (d_hold == 4'd0)
                        dstate <= D_IDLE;
                    else
                        d_hold <= d_hold - 4'd1;
                end

                default: dstate <= D_IDLE;
            endcase

            // watchdog abort: drop the frame, release the path to OFDM
            if (dstate != D_IDLE && d_wdog == {WATCHDOG_BITS{1'b1}})
                dstate <= D_IDLE;

            // OFDM preemption (strict OFDM priority): a freshly decoded OFDM header
            // always wins the shared path. Abandon any in-flight DSSS frame so the real
            // OFDM frame is forwarded; its header strobe passes downstream THIS cycle via
            // the `sel` override below (sel=0 when ofdm_sig_valid), which also re-syncs
            // byte_to_word_fcs_sn_insert (its rstn includes ~m_pkt_header_valid_strobe).
            if (ofdm_sig_valid)
                dstate <= D_IDLE;
        end
    end

    assign dsss_active = (dstate != D_IDLE);

    // ---------------------------------------------------------------
    // Final mux: DSSS owns the path while a DSSS frame is active, EXCEPT on a
    // decoded-OFDM-header cycle (ofdm_sig_valid), where OFDM preempts: sel drops so
    // the OFDM header strobe + signals pass through immediately (re-syncing the
    // downstream byte_to_word) the same cycle the FSM is sent back to D_IDLE.
    // ---------------------------------------------------------------
    wire sel = dsss_active & ~ofdm_sig_valid;

    assign pkt_header_valid        = sel ? 1'b1            : ofdm_pkt_header_valid;
    assign pkt_header_valid_strobe = sel ? d_phv_strobe    : ofdm_pkt_header_valid_strobe;
    assign ht_unsupport            = sel ? 1'b0            : ofdm_ht_unsupport;
    assign pkt_rate                = sel ? 8'h00           : ofdm_pkt_rate;          // 1 Mbps DSSS
    assign pkt_len                 = sel ? d_pkt_len       : ofdm_pkt_len;
    assign ht_aggr                 = sel ? 1'b0            : ofdm_ht_aggr;
    assign ht_aggr_last            = sel ? 1'b0            : ofdm_ht_aggr_last;
    assign ht_sgi                  = sel ? 1'b0            : ofdm_ht_sgi;
    assign byte_in                 = sel ? d_byte_in       : ofdm_byte_in;
    assign byte_in_strobe          = sel ? d_byte_in_strobe: ofdm_byte_in_strobe;
    assign byte_count              = sel ? d_byte_count    : ofdm_byte_count;
    assign fcs_in_strobe           = sel ? d_fcs_in_strobe : ofdm_fcs_in_strobe;
    assign fcs_ok                  = sel ? d_fcs_ok        : ofdm_fcs_ok;
    assign phase_offset_taken      = sel ? 32'sd0          : ofdm_phase_offset_taken;

endmodule
