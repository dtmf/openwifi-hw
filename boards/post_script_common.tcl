# // Author: Xianjun Jiao
# // SPDX-FileCopyrightText: 2025 UGent
# // SPDX-License-Identifier: AGPL-3.0-or-later

# common operations for all boards at the end of openwifi.tcl

open_bd_design {./src/system.bd}

if {$BOARD_NAME!="rfsoc4x2"} {
  set_property CONFIG.FREQ_HZ 40000000 [get_bd_pins /util_ad9361_divclk/clk_out]
}

update_compile_order -fileset sources_1

report_ip_status -name ip_status 
upgrade_ip [get_ips  {system_rx_intf_0_0 system_tx_intf_0_0 system_openofdm_tx_0_0 system_xpu_0_0 system_side_ch_0_0}] -log ip_upgrade.log
export_ip_user_files -of_objects [get_ips {system_rx_intf_0_0 system_tx_intf_0_0 system_openofdm_tx_0_0 system_xpu_0_0 system_side_ch_0_0}] -no_script -sync -force -quiet
report_ip_status -name ip_status

# ---------------------------------------------------------------------------
# DSSS B-clean (plan D3): instantiate the DSSS PHY (dsss_rx_fb) and modulator
# (dsss_tx) as first-class BD IP cells opendsss_rx_0 / opendsss_tx_0, siblings of
# openofdm_rx_0 / openofdm_tx_0. The arbiter/mux stays inside rx_intf/tx_intf and
# now reaches the PHY through ports (added to those IPs and refreshed onto the
# cells by the upgrade_ip above):
#   RX: opendsss_rx_0 taps the shared 20 MSPS sample net (exactly as openofdm_rx
#       does), takes enable (rx_intf_0/dsss_enable_out) + resetn (acc aresetn), and
#       returns its decode bus to rx_intf_0/dsss_phy_* (fed into dsss_rx_and_mux
#       where the internal dsss_rx_fb instance used to be).
#   TX: opendsss_tx_0 is fed by tx_intf_0/dsss_tx_* (reset/length/go/ack_mode/
#       sample_ready) and taps data_to_acc (shared BRAM doutb) for read data; it
#       returns samples/addr/status to tx_intf_0/dsss_tx_* (into dsss_tx_and_mux).
# Everything is guarded (safe no-op if a cell/pin is absent on a non-DSSS board or
# stub upgrade) and idempotent (create only if absent, join only if unconnected),
# so re-running on the git-tracked system.bd is a no-op.
# ---------------------------------------------------------------------------
update_ip_catalog -quiet

# Create $name (VLNV $vlnv) as a sibling of $sibling, only if it does not exist.
proc _dsss_bc_cell {name vlnv sibling} {
  set _ex [get_bd_cells -quiet -hierarchical $name]
  if {[llength $_ex]} { puts "DSSS-BCLEAN: $name already present; keep"; return [lindex $_ex 0] }
  set _sib [get_bd_cells -quiet -hierarchical $sibling]
  if {![llength $_sib]} { puts "DSSS-BCLEAN: sibling $sibling absent; cannot place $name; skip"; return {} }
  set _dir [file dirname [lindex $_sib 0]]
  set _cell [create_bd_cell -quiet -type ip -vlnv $vlnv $_dir/$name]
  puts "DSSS-BCLEAN: created $name ($vlnv) at $_dir/$name"
  return $_cell
}
# Add $new_pinpath to the net already on $ref_pinpath (clock/reset/sample/data taps).
proc _dsss_bc_join {ref_pinpath new_pinpath label} {
  set _r [get_bd_pins -quiet $ref_pinpath]
  set _n [get_bd_pins -quiet $new_pinpath]
  if {![llength $_r] || ![llength $_n]} { puts "DSSS-BCLEAN: $label pin absent (ref='$_r' new='$_n'); skip"; return }
  if {[llength [get_bd_nets -quiet -of_objects $_n]]} { puts "DSSS-BCLEAN: $label already connected; skip"; return }
  connect_bd_net $_r $_n
  puts "DSSS-BCLEAN: joined $label"
}
# Point-to-point connect (cell output -> intf input, or intf output -> cell input).
proc _dsss_bc_p2p {src_pinpath sink_pinpath label} {
  set _s [get_bd_pins -quiet $src_pinpath]
  set _k [get_bd_pins -quiet $sink_pinpath]
  if {![llength $_s] || ![llength $_k]} { puts "DSSS-BCLEAN: $label pin absent (src='$_s' sink='$_k'); skip"; return }
  if {[llength [get_bd_nets -quiet -of_objects $_k]]} { puts "DSSS-BCLEAN: $label sink already connected; skip"; return }
  connect_bd_net $_s $_k
  puts "DSSS-BCLEAN: connected $label"
}

set _bc_rxc [_dsss_bc_cell opendsss_rx_0 user.org:user:opendsss_rx:1.0 rx_intf_0]
set _bc_txc [_dsss_bc_cell opendsss_tx_0 user.org:user:opendsss_tx:1.0 tx_intf_0]
set _bc_rx  [get_bd_cells -quiet -hierarchical rx_intf_0]
set _bc_of  [get_bd_cells -quiet -hierarchical openofdm_rx_0]
set _bc_tx  [get_bd_cells -quiet -hierarchical tx_intf_0]

if {[llength $_bc_rxc] && [llength $_bc_rx] && [llength $_bc_of]} {
  set R  [lindex $_bc_rxc 0]
  set RX [lindex $_bc_rx 0]
  set OF [lindex $_bc_of 0]
  # clock/reset: join the acc-domain nets rx_intf already sits on
  _dsss_bc_join $RX/m00_axis_aclk    $R/clock  "opendsss_rx_0/clock"
  _dsss_bc_join $RX/m00_axis_aresetn $R/resetn "opendsss_rx_0/resetn"
  # samples: tap the exact net that already feeds openofdm_rx_0
  _dsss_bc_join $OF/sample_in        $R/sample_in        "opendsss_rx_0/sample_in"
  _dsss_bc_join $OF/sample_in_strobe $R/sample_in_strobe "opendsss_rx_0/sample_in_strobe"
  # enable: rx_intf output -> cell
  _dsss_bc_p2p  $RX/dsss_enable_out  $R/enable "opendsss_rx_0/enable"
  # decode bus: cell outputs -> rx_intf inputs (params_datarate left unconnected, unused)
  _dsss_bc_p2p  $R/params_length $RX/dsss_phy_params_length "rx_intf_0/dsss_phy_params_length"
  _dsss_bc_p2p  $R/params_valid  $RX/dsss_phy_params_valid  "rx_intf_0/dsss_phy_params_valid"
  _dsss_bc_p2p  $R/data          $RX/dsss_phy_data          "rx_intf_0/dsss_phy_data"
  _dsss_bc_p2p  $R/data_valid    $RX/dsss_phy_data_valid    "rx_intf_0/dsss_phy_data_valid"
  _dsss_bc_p2p  $R/framer_done   $RX/dsss_phy_framer_done   "rx_intf_0/dsss_phy_framer_done"
  _dsss_bc_p2p  $R/crc_correct   $RX/dsss_phy_crc_correct   "rx_intf_0/dsss_phy_crc_correct"
  _dsss_bc_p2p  $R/fcs_out       $RX/dsss_phy_fcs_out       "rx_intf_0/dsss_phy_fcs_out"
}

if {[llength $_bc_txc] && [llength $_bc_tx]} {
  set T  [lindex $_bc_txc 0]
  set TX [lindex $_bc_tx 0]
  # clock: tx_intf acc domain
  _dsss_bc_join $TX/s00_axis_aclk $T/clock "opendsss_tx_0/clock"
  # tx_intf outputs -> cell inputs
  _dsss_bc_p2p  $TX/dsss_tx_reset        $T/reset        "opendsss_tx_0/reset"
  _dsss_bc_p2p  $TX/dsss_tx_length       $T/length       "opendsss_tx_0/length"
  _dsss_bc_p2p  $TX/dsss_tx_go           $T/go           "opendsss_tx_0/go"
  _dsss_bc_p2p  $TX/dsss_tx_ack_mode     $T/ack_mode     "opendsss_tx_0/ack_mode"
  _dsss_bc_p2p  $TX/dsss_tx_sample_ready $T/sample_ready "opendsss_tx_0/sample_ready"
  # BRAM read data: tap tx_intf's data_to_acc (shared BRAM doutb, feeds openofdm_tx too)
  _dsss_bc_join $TX/data_to_acc $T/bram_rd_data "opendsss_tx_0/bram_rd_data"
  # cell outputs -> tx_intf inputs
  _dsss_bc_p2p  $T/bram_rd_addr $TX/dsss_tx_bram_rd_addr "tx_intf_0/dsss_tx_bram_rd_addr"
  _dsss_bc_p2p  $T/sample_i     $TX/dsss_tx_sample_i     "tx_intf_0/dsss_tx_sample_i"
  _dsss_bc_p2p  $T/sample_q     $TX/dsss_tx_sample_q     "tx_intf_0/dsss_tx_sample_q"
  _dsss_bc_p2p  $T/sample_valid $TX/dsss_tx_sample_valid "tx_intf_0/dsss_tx_sample_valid"
  _dsss_bc_p2p  $T/busy         $TX/dsss_tx_busy         "tx_intf_0/dsss_tx_busy"
  _dsss_bc_p2p  $T/done         $TX/dsss_tx_done         "tx_intf_0/dsss_tx_done"
}

if {[llength $_bc_rxc] || [llength $_bc_txc]} { validate_bd_design }

# ---------------------------------------------------------------------------
# DSSS OFDM-priority fix: route openofdm_rx's demod_is_ongoing (OFDM-RX-in-
# progress, asserts at the long preamble, before the header) into rx_intf so the
# DSSS/OFDM arbiter in dsss_rx_and_mux can (1) block a DSSS grant while OFDM is
# mid-preamble and (2) preempt an in-flight DSSS frame on a decoded OFDM header.
# This is the single block-design connection the fix requires (a new rx_intf
# input port). Guarded by pin existence so it is a safe no-op on any board whose
# rx_intf IP does not expose the pin.
# ---------------------------------------------------------------------------
# Cells live under a hierarchy (e.g. /openwifi_ip/rx_intf_0), so locate them by
# name with -hierarchical and build the pin paths from the returned cell paths.
set _rxcell [get_bd_cells -quiet -hierarchical rx_intf_0]
set _ofcell [get_bd_cells -quiet -hierarchical openofdm_rx_0]
set _rxpin {}
set _ofpin {}
if {[llength $_rxcell]} { set _rxpin [get_bd_pins -quiet [lindex $_rxcell 0]/demod_is_ongoing] }
if {[llength $_ofcell]} { set _ofpin [get_bd_pins -quiet [lindex $_ofcell 0]/demod_is_ongoing] }
if {[llength $_rxpin] && [llength $_ofpin]} {
  if {![llength [get_bd_nets -quiet -of_objects $_rxpin]]} {
    connect_bd_net $_ofpin $_rxpin
    puts "DSSS-FIX: connected $_ofpin -> $_rxpin"
  } else {
    puts "DSSS-FIX: $_rxpin already connected; skip"
  }
  validate_bd_design
} else {
  puts "DSSS-FIX: demod_is_ongoing pin absent (rxcell='$_rxcell' rxpin='$_rxpin' ofcell='$_ofcell' ofpin='$_ofpin'); skip (no-op)"
}

# ---------------------------------------------------------------------------
# DSSS TX-FIX (TX-2f): per-frame arbitration of openofdm_tx vs dsss_tx inside
# tx_intf. After TX-2d, tx_intf exports ofdm_phy_tx_start_gated (= phy_tx_start
# & ~is_dsss) and muxed_tx_end/started_for_xpu (= is_dsss ? dsss_* : openofdm_*).
# Two block-design edits:
#   (a) START-GATE: drive openofdm_tx_0/phy_tx_start from the exported gated
#       port so openofdm does not free-run (and hijack the shared payload BRAM
#       port / emit a wrong-length phy_tx_done) during a DSSS frame. Only
#       openofdm_tx_0 is gated; xpu_0/side_ch_0 keep the raw start.
#   (b) DONE/STARTED RE-SOURCE for the SIBLING MAC cells ONLY (xpu_0, side_ch_0)
#       from the muxed outputs. On a DSSS frame openofdm is gated off and never
#       asserts phy_tx_done, so without this xpu's tx_on_detection window
#       (tx_bb_is_ongoing) never closes (its timeout fallback is commented out)
#       and the MAC hangs. Per DSSS_TX2_SCOPE.md §9.1 the wrapper computes
#       muxed_* FROM tx_intf_0's own tx_end/start_from_acc inputs, so those
#       inputs are LEFT on the raw openofdm net (re-driving them from muxed_*
#       is a combinational loop on OFDM frames).
# Every step is guarded by cell/pin existence and is idempotent (system.bd is
# git-tracked and persists across rebuilds), so it is a safe no-op when a port
# or cell is absent (stub upgrade / non-DSSS-TX board) and logs a skip line.
# Standalone rationale: DSSS_TX2_SCOPE.md §5 (corrected by §9.1).
# ---------------------------------------------------------------------------
# Re-source a single sink pin from a new driver, detaching it from its current
# net WITHOUT disturbing that net's other sinks (so the raw openofdm net keeps
# driving tx_intf_0's own inputs). Idempotent + guarded.
proc _dsss_tx_resource {sink_cell sink_pin_name src_cell src_pin_name label} {
  if {![llength $sink_cell] || ![llength $src_cell]} {
    puts "DSSS-TX-FIX: $label cell absent; skip (no-op)"; return
  }
  set _sp [get_bd_pins -quiet [lindex $sink_cell 0]/$sink_pin_name]
  set _dp [get_bd_pins -quiet [lindex $src_cell 0]/$src_pin_name]
  if {![llength $_sp] || ![llength $_dp]} {
    puts "DSSS-TX-FIX: $label pin absent (sink='$_sp' src='$_dp'); skip (no-op)"; return
  }
  set _sn [get_bd_nets -quiet -of_objects $_sp]
  set _dn [get_bd_nets -quiet -of_objects $_dp]
  if {[llength $_sn] && [llength $_dn] && [string equal $_sn $_dn]} {
    puts "DSSS-TX-FIX: $label already re-sourced; skip"; return
  }
  if {[llength $_sn]} { disconnect_bd_net $_sn $_sp }
  connect_bd_net $_dp $_sp
  puts "DSSS-TX-FIX: re-sourced $label ($_dp -> $_sp)"
}

set _txintf [get_bd_cells -quiet -hierarchical tx_intf_0]
set _ofdmtx [get_bd_cells -quiet -hierarchical openofdm_tx_0]
set _xpu    [get_bd_cells -quiet -hierarchical xpu_0]
set _sidech [get_bd_cells -quiet -hierarchical side_ch_0]

# (a) start-gate openofdm_tx_0 only
_dsss_tx_resource $_ofdmtx phy_tx_start   $_txintf ofdm_phy_tx_start_gated  "openofdm_tx_0/phy_tx_start start-gate"
# (b) re-source SIBLING done/started (NOT tx_intf_0's own tx_end/start_from_acc, §9.1)
_dsss_tx_resource $_xpu    phy_tx_done    $_txintf muxed_tx_end_for_xpu      "xpu_0/phy_tx_done"
_dsss_tx_resource $_xpu    phy_tx_started $_txintf muxed_tx_started_for_xpu  "xpu_0/phy_tx_started"
_dsss_tx_resource $_sidech phy_tx_done    $_txintf muxed_tx_end_for_xpu      "side_ch_0/phy_tx_done"
_dsss_tx_resource $_sidech phy_tx_started $_txintf muxed_tx_started_for_xpu  "side_ch_0/phy_tx_started"

if {[llength $_txintf] && [llength $_ofdmtx]} { validate_bd_design }

# ---------------------------------------------------------------------------
# DSSS-ACK-RX (unicast-ACK B1): make xpu SEE a received DSSS frame. Today xpu's
# RX decode inputs are driven directly from openofdm_rx_0 (BD nets), so a DSSS
# reception (decoded only inside rx_intf's dsss_rx_and_mux) never reaches xpu's
# phy_rx_parse / tx_control auto-ACK trigger -> tx_control never tries to ACK a
# received DSSS frame. rx_intf now exports the SAME merged (OFDM|DSSS) decode bus
# it already feeds to the DMA path (the *_to_xpu outputs) plus is_dsss_rx
# (=dsss_active). Re-source each xpu decode pin from that merged bus and connect
# is_dsss_rx. The re-source detaches ONLY xpu's pin from the openofdm net; rx_intf
# keeps receiving the raw openofdm signals (the net's other sink), so openofdm_rx
# still drives rx_intf as before. When no DSSS frame is active the merged bus is
# combinationally identical to openofdm_rx, so the OFDM path (and the existing OFDM
# auto-ACK) is unchanged. Guarded + idempotent: a safe no-op (skip line) if a pin
# is absent (stub upgrade / non-DSSS board).
# ---------------------------------------------------------------------------
proc _dsss_ack_resource {sink_cell sink_pin_name src_cell src_pin_name label} {
  if {![llength $sink_cell] || ![llength $src_cell]} {
    puts "DSSS-ACK-RX: $label cell absent; skip (no-op)"; return
  }
  set _sp [get_bd_pins -quiet [lindex $sink_cell 0]/$sink_pin_name]
  set _dp [get_bd_pins -quiet [lindex $src_cell 0]/$src_pin_name]
  if {![llength $_sp] || ![llength $_dp]} {
    puts "DSSS-ACK-RX: $label pin absent (sink='$_sp' src='$_dp'); skip (no-op)"; return
  }
  set _sn [get_bd_nets -quiet -of_objects $_sp]
  set _dn [get_bd_nets -quiet -of_objects $_dp]
  if {[llength $_sn] && [llength $_dn] && [string equal $_sn $_dn]} {
    puts "DSSS-ACK-RX: $label already re-sourced; skip"; return
  }
  if {[llength $_sn]} { disconnect_bd_net $_sn $_sp }
  connect_bd_net $_dp $_sp
  puts "DSSS-ACK-RX: re-sourced $label ($_dp -> $_sp)"
}

set _ackrx_rxintf [get_bd_cells -quiet -hierarchical rx_intf_0]
set _ackrx_xpu    [get_bd_cells -quiet -hierarchical xpu_0]
set _ackrx_txintf [get_bd_cells -quiet -hierarchical tx_intf_0]

# 12 frame-decode pins: xpu_0/<pin>  <-  rx_intf_0/<pin>_to_xpu (merged OFDM|DSSS bus)
_dsss_ack_resource $_ackrx_xpu pkt_header_valid        $_ackrx_rxintf pkt_header_valid_to_xpu        "xpu_0/pkt_header_valid"
_dsss_ack_resource $_ackrx_xpu pkt_header_valid_strobe $_ackrx_rxintf pkt_header_valid_strobe_to_xpu "xpu_0/pkt_header_valid_strobe"
_dsss_ack_resource $_ackrx_xpu ht_unsupport            $_ackrx_rxintf ht_unsupport_to_xpu            "xpu_0/ht_unsupport"
_dsss_ack_resource $_ackrx_xpu pkt_rate                $_ackrx_rxintf pkt_rate_to_xpu                "xpu_0/pkt_rate"
_dsss_ack_resource $_ackrx_xpu pkt_len                 $_ackrx_rxintf pkt_len_to_xpu                 "xpu_0/pkt_len"
_dsss_ack_resource $_ackrx_xpu byte_in_strobe          $_ackrx_rxintf byte_in_strobe_to_xpu          "xpu_0/byte_in_strobe"
_dsss_ack_resource $_ackrx_xpu byte_in                 $_ackrx_rxintf byte_in_to_xpu                 "xpu_0/byte_in"
_dsss_ack_resource $_ackrx_xpu byte_count              $_ackrx_rxintf byte_count_to_xpu              "xpu_0/byte_count"
_dsss_ack_resource $_ackrx_xpu fcs_in_strobe           $_ackrx_rxintf fcs_in_strobe_to_xpu           "xpu_0/fcs_in_strobe"
_dsss_ack_resource $_ackrx_xpu fcs_ok                  $_ackrx_rxintf fcs_ok_to_xpu                  "xpu_0/fcs_ok"
_dsss_ack_resource $_ackrx_xpu rx_ht_aggr              $_ackrx_rxintf ht_aggr_to_xpu                 "xpu_0/rx_ht_aggr"
_dsss_ack_resource $_ackrx_xpu rx_ht_aggr_last         $_ackrx_rxintf ht_aggr_last_to_xpu            "xpu_0/rx_ht_aggr_last"
# is_dsss_rx: fresh xpu input (no existing driver) <- rx_intf_0/is_dsss_rx
_dsss_ack_resource $_ackrx_xpu is_dsss_rx              $_ackrx_rxintf is_dsss_rx                     "xpu_0/is_dsss_rx"
# is_dsss_ack (unicast-ACK B2): TX side. xpu's held DSSS-ACK selector (output, sourced in
# tx_control from is_dsss_rx) -> tx_intf's fresh is_dsss_ack input (no existing driver). Routes
# the auto-ACK to dsss_tx (is_dsss override + length=10 + read-substitution off so dsss_tx reads
# the BRAM words tx_control wrote). Defaults safe: an unconnected tx_intf input reads 0 -> OFDM ACK.
_dsss_ack_resource $_ackrx_txintf is_dsss_ack         $_ackrx_xpu    is_dsss_ack                    "tx_intf_0/is_dsss_ack"
# is_dsss_tx (unicast-ACK RECV side, 2026-07-02): xpu's fresh input <- tx_intf_0/is_dsss (latched
# phy_hdr_config[21], already a tx_intf top port that gates openofdm start + muxes tx_end/started).
# Adds xpu as an extra sink on the existing is_dsss net. Lets xpu widen its recv-ACK timeout windows
# when the board's OUTGOING frame is DSSS, so it waits for the peer's slow long-preamble DSSS ACK
# (durable replacement for the volatile slv_reg16=0x89C404B0 runtime workaround). Unconnected stub
# reads 0 -> OFDM windows unchanged. Guarded/idempotent like the rest.
_dsss_ack_resource $_ackrx_xpu    is_dsss_tx          $_ackrx_txintf is_dsss                        "xpu_0/is_dsss_tx"

if {[llength $_ackrx_rxintf] && [llength $_ackrx_xpu]} { validate_bd_design }

save_bd_design
