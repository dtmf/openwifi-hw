// SPDX-License-Identifier: GPL-2.0-or-later
//
// opendsss — 802.11b 1 Mbps DSSS PHY for openwifi
//
// Copyright (C) 2026 Will Scales.
//
// This program is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation; either version 2 of the License, or (at your option) any later
// version. Combined with GPL-2.0-or-later components derived from bladeRF-wiphy
// (Copyright (C) 2020 Nuand, LLC); see the LICENSE and NOTICE files.
//
// opendsss_rx.sv
// ---------------------------------------------------------------------------
// openwifi-hw Block-Design IP wrapper for the DSSS receiver PHY (dsss_rx_fb).
// Mirrors how openofdm_rx is packaged: a first-class BD IP cell (opendsss_rx_0)
// that taps the shared baseband sample bus (rx_intf `sample`/`sample_strobe`)
// and hands a decoded byte/FCS stream to the arbiter (dsss_rx_and_mux, which
// STAYS in rx_intf).
//
// The pure DSSS PHY RTL is single-sourced from the opendsss submodule
// (ip/opendsss/verilog). This wrapper is openwifi-integration glue: it
// (a) presents an openofdm-style 32-bit `sample_in = {I[31:16], Q[15:0]}` port
//     so the BD wires it to the exact net that already feeds openofdm_rx_0, and
// (b) reproduces the EXACT gating dsss_rx_and_mux applied to the PHY today
//     (dsss_rx_and_mux.sv:99,106):
//        reset(dsss_rst) = (~rstn) | (~dsss_enable)   -> ~resetn | ~enable
//        sample_valid    = sample_valid & dsss_enable -> sample_in_strobe & enable
//     so the packaged path is behaviorally bit-identical to the pre-split build.
//     `resetn` is active-low (= the arbiter's rstn = m00_axis_aresetn), so at the
//     BD it taps the same reset net that already feeds rx_intf_0/openofdm_rx_0.
//
// The internal instance is named `u_dsss_rx` (matching the arbiter's old name)
// so the synthesized hierarchy `u_dsss_rx/u_{demodulator,despreader,mu,farrow}`
// is preserved and the system.xdc multicycle constraints re-path by prefix only.
// ---------------------------------------------------------------------------
`timescale 1ns/1ps
module opendsss_rx (
    input  wire               clock,             // rx_intf acc clock (100 MHz)
    input  wire               resetn,            // active-low (= arbiter rstn = m00_axis_aresetn)
    input  wire               enable,            // 1 = DSSS RX active (= dsss_enable)
    input  wire        [31:0] sample_in,         // {rf_i0[31:16], rf_q0[15:0]}, 20 MSPS
    input  wire               sample_in_strobe,  // one pulse per baseband sample

    output wire        [12:0] params_length,
    output wire        [3:0]  params_datarate,   // unused by the arbiter (leave open at BD)
    output wire               params_valid,
    output wire        [7:0]  data,
    output wire               data_valid,
    output wire               framer_done,
    output wire               crc_correct,
    output wire        [31:0] fcs_out
);

    // Exact reproduction of dsss_rx_and_mux's PHY gating (see header).
    wire dsss_rst = ~resetn | ~enable;

    dsss_rx_fb u_dsss_rx (
        .clock          (clock),
        .reset          (dsss_rst),
        .sample_i       (sample_in[31:16]),
        .sample_q       (sample_in[15:0]),
        .sample_valid   (sample_in_strobe & enable),
        .params_length  (params_length),
        .params_datarate(params_datarate),
        .params_valid   (params_valid),
        .data           (data),
        .data_valid     (data_valid),
        .framer_done    (framer_done),
        .crc_correct    (crc_correct),
        .fcs_out        (fcs_out)
    );

endmodule
