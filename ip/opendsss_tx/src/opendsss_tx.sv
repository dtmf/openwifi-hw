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
// opendsss_tx.sv
// ---------------------------------------------------------------------------
// openwifi-hw Block-Design IP wrapper for the DSSS modulator (dsss_tx).
// Mirrors how openofdm_tx is packaged: a first-class BD IP cell (opendsss_tx_0).
// The OFDM/DSSS arbitration (sample mux, gain/fuzzer mux, shared-BRAM address
// time-mux, done/started mux, openofdm start-gate) all STAYS in dsss_tx_and_mux
// (tx_intf); only the raw modulator moves out here.
//
// The pure DSSS modulator RTL is single-sourced from the opendsss submodule
// (ip/opendsss/verilog). This wrapper is a thin, transparent pass-through: the
// modulator already takes an active-high reset and needs no gating, so the
// wrapper exists only to give the packaged IP the name `opendsss_tx` (the VLNV
// user.org:user:opendsss_tx:1.0) and a stable BD port list.
//
// The internal instance is named `u_dsss_tx` (matching the arbiter's old name).
// ---------------------------------------------------------------------------
`timescale 1ns/1ps
module opendsss_tx (
    input  wire               clock,          // tx_intf acc clock (100 MHz)
    input  wire               reset,          // active-high (= ~rstn)
    input  wire        [63:0] bram_rd_data,   // shared payload BRAM doutb (1-cyc registered)
    input  wire        [12:0] length,         // DSSS payload octets (excl FCS) = len_psdu
    input  wire               go,             // start pulse (phy_tx_start & is_dsss)
    input  wire               ack_mode,       // 1 = auto-ACK frame (short SIFS lead-in)
    input  wire               sample_ready,   // downstream accept (= ~tx_hold)

    output wire        [9:0]  bram_rd_addr,   // prefetch addr -> tx_intf bram_addr time-mux
    output wire signed [15:0] sample_i,
    output wire signed [15:0] sample_q,
    output wire               sample_valid,
    output wire               busy,
    output wire               done
);

    dsss_tx u_dsss_tx (
        .clock       (clock),
        .reset       (reset),
        .bram_rd_addr(bram_rd_addr),
        .bram_rd_data(bram_rd_data),
        .length      (length),
        .go          (go),
        .ack_mode    (ack_mode),
        .sample_ready(sample_ready),
        .sample_i    (sample_i),
        .sample_q    (sample_q),
        .sample_valid(sample_valid),
        .busy        (busy),
        .done        (done)
    );

endmodule
