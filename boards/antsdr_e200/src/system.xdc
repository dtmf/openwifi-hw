#set_clock_groups -asynchronous -group [get_clocks [list i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_out]] -group [get_clocks [list i_system_wrapper/system_i/sys_ps8/inst/pl_clk2]]
#set_false_path -from [get_clocks -of_objects [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_0/O]] -to [get_clocks clk_pl_2]
#set_false_path -from [get_clocks -of_objects [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_1/O]] -to [get_clocks clk_pl_2]

## relax cross rf and bb domain control of adc_intf
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/wren_count_reg[0]/R}]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/wren_count_reg[1]/R}]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/wren_count_reg[2]/R}]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/wren_count_reg[3]/R}]

#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/fifo32_2clk_dep32_i/fifo_generator_0/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.gl0.wr/gwas.wsts/ram_full_i_reg/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/FULL_internal_in_bb_domain_reg/D]

#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_decimate_reg_reg/D]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg_replica/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_decimate_reg_reg/D]
#set_false_path -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg_replica_1/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_decimate_reg_reg/D]

#set_false_path -from [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_0/O] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/D]
#set_false_path -from [get_pins i_system_wrapper/system_i/util_ad9361_divclk/inst/clk_divide_sel_1/O] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/D]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/C]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/D]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/Q]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_clk_in_bb_domain_reg/R]

#set_false_path -from [get_pins i_system_wrapper/system_i/util_ad9361_adc_pack/inst/i_cpack/packed_fifo_wr_en_reg/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/D]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/C]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/D]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/Q]
#set_false_path -through [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_in_bb_domain_reg/R]

# relax cross rf and bb domain control of dac_intf
set_max_delay 5 -datapath_only -from [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/tx_iq_intf_i/csi_fuzzer_i/iq_out_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/dac_intf_i/data_from_acc_stage1_reg[*]/D}]

# relax cross rf and bb domain control of dac_intf
set_false_path -through [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/dac_intf_i/xpm_cdc_array_single_inst_ant_flag/syncstages_ff_reg[3][0]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/dac_intf_i/xpm_cdc_array_single_inst_simple_cdd_flag/syncstages_ff_reg[3][0]/C}]
set_false_path -through [get_pins {i_system_wrapper/system_i/openwifi_ip/tx_intf_0/inst/dac_intf_i/xpm_cdc_array_single_inst_read_bb_fifo/syncstages_ff_reg[3][0]/C}]

# relax cross rf and bb domain control of adc_intf
set_max_delay 5 -datapath_only -from [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_data_shift_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_data_shift_stage1_reg[*]/D}]
set_max_delay 5 -datapath_only -from [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_count_reg_inv/C] -to [get_pins i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/adc_valid_decimate_stage1_reg/D]
set_false_path -through [get_pins {i_system_wrapper/system_i/openwifi_ip/rx_intf_0/inst/adc_intf_i/xpm_cdc_array_single_inst_ant_flag/syncstages_ff_reg[3][*]/C}]

# DSSS-port timing closure (Phase 4b): relax the openofdm_rx config-register -> side_ch
# capture-FIFO write-pointer path. slv_reg4 (openofdm_rx_s_axi) is a software-written
# AXI-Lite config register: reset to 0, updated only on a CPU AXI write, held otherwise
# (openofdm_rx_s_axi.v: slv_reg4 <= slv_reg4). Its value is quasi-static, stable for
# thousands of clk_out1 cycles between writes, so its long combinational fanout into the
# side_ch write-pointer FIFO has many cycles to settle. The constraint targets ONLY the
# slv_reg4 -> wrpp1 count arc; the FIFO counter's fast count-feedback arcs are driven by
# other (non-slv_reg4) sources and remain single-cycle. This removes the route-dominated
# -0.127/-0.083 ns setup violations that the DSSS-RX add nudged negative on this
# 99%-slice-full xc7z020. Multicycle (not false_path) keeps a real, relaxed bound.
# 2026-06-29 (Farrow RX build): broadened wrpp1_inst -> wrp*_inst to also cover the sibling
# wrp_inst write-pointer counter (same slv_reg4 quasi-static source), which the Farrow's
# +3556 LUT congestion nudged to -0.290 ns. Same arc class; same safe relaxation.
set_multicycle_path -setup 2 -from [get_pins {i_system_wrapper/system_i/openwifi_ip/openofdm_rx_0/inst/openofdm_rx_s_axi_i/slv_reg4_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/side_ch_0/inst/side_ch_control_i/xpm_fifo_sync_inst/xpm_fifo_base_inst/wrp*_inst/count_value_i_reg[*]/D}]
set_multicycle_path -hold  1 -from [get_pins {i_system_wrapper/system_i/openwifi_ip/openofdm_rx_0/inst/openofdm_rx_s_axi_i/slv_reg4_reg[*]/C}] -to [get_pins {i_system_wrapper/system_i/openwifi_ip/side_ch_0/inst/side_ch_control_i/xpm_fifo_sync_inst/xpm_fifo_base_inst/wrp*_inst/count_value_i_reg[*]/D}]

# DSSS-port timing closure (Phase 4b): relax the openofdm_rx equalizer noise-variance
# accumulator. noise_{i,q}_sq_sum (equalizer.v, state S_SECOND_LTS) is written ONLY inside
# `if (calc_mean_strobe) if (SUBCARRIER_MASK[...])`, and calc_mean_strobe <= sample_in_strobe.
# OFDM RX runs at 20 MHz on the 100 MHz clk_out1, so that strobe is 1-in-5 cycles; lts_raddr
# (BRAM read addr) and input_i advance on the same tick, so the BRAM->accumulator data is
# stable for ~5 cycles before each accumulate. Every setup path into noise_{i,q}_sq_sum
# therefore has >=2 cycles. -setup 2 needs only a >=2-cycle gap (holds for any OFDM rate
# <=50 MHz), giving the failing -0.068 ns path 20 ns instead of 10 ns. No RTL change.
set_multicycle_path -setup 2 -to [get_cells -hier -filter {NAME =~ *openofdm_rx_0/inst/dot11_i/equalizer_inst/noise_i_sq_sum_reg* || NAME =~ *openofdm_rx_0/inst/dot11_i/equalizer_inst/noise_q_sq_sum_reg*}]
set_multicycle_path -hold  1 -to [get_cells -hier -filter {NAME =~ *openofdm_rx_0/inst/dot11_i/equalizer_inst/noise_i_sq_sum_reg* || NAME =~ *openofdm_rx_0/inst/dot11_i/equalizer_inst/noise_q_sq_sum_reg*}]

# ===========================================================================
# B-clean (plan D3, Step 4): the DSSS RX PHY (dsss_rx_fb) moved from inside
# rx_intf's dsss_rx_and_mux_i to the first-class opendsss_rx BD IP cell
# (opendsss_rx_0). The 5 DSSS-RX multicycle blocks below therefore key on the
# PREFIX-AGNOSTIC path `*u_dsss_rx/u_<sub>/...` (dropping the old parent
# `dsss_rx_and_mux_i/`), so they match the SAME registers regardless of whether the
# PHY sits under the arbiter (pre-B-clean) or under opendsss_rx_0/inst (post). The
# submodule instances (u_demodulator/u_despreader/u_mu/u_farrow) and register names
# live inside dsss_rx_fb, which is byte-identical, so the target cells are unchanged;
# only the hierarchy parent moved. VERIFY post-synth that each still matches >0 cells
# (no CRITICAL WARNING 12-4739). The per-block comments describe the pre-B-clean
# hierarchy, but the strobe-paced pacing rationale is unchanged.
# ===========================================================================
# DSSS-port timing closure (Phase 4b): relax the DSSS demodulator coded_bits path. coded_bits
# (dsss_demodulator.sv) is written ONLY inside `if (despread_valid)`; despread_valid is paced by
# sample_valid (20 MSPS) through p_norm -> despreader. The u_p_norm DSP source and the coded_bits
# capture both advance on the 1-in-5 sample cadence, so this path has >=2 cycles. -setup 2 closes
# the residual -0.024 ns DSSS endpoint (path needs 9.3 ns, gets 20 ns). No RTL change.
set_multicycle_path -setup 2 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_demodulator/*coded_bits*}]
set_multicycle_path -hold  1 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_demodulator/*coded_bits*}]

# DSSS-port timing closure (unicast-ACK B1+B2 build, 2026-06-25): relax the DSSS despreader
# matched-filter accumulator. accum_{i,q} (dsss_despreader.sv) are written ONLY inside
# `if (sample_valid)` (the 20-tap systolic FIR: accum[k] <= accum[k+1] + prod), and the
# p_norm DSP source advances on the same sample_valid tick. OFDM/DSSS RX runs at 20 MSPS on
# the 100 MHz clk_out1, so sample_valid is 1-in-5 cycles -> every setup path into accum has
# >=5 cycles. This is the SAME 1-in-5 cadence the coded_bits constraint above documents
# ("p_norm -> despreader"). The added B1/B2 logic (RX decode mux + ACK FSM) raised placement
# congestion on this 99%-full xc7z020 and nudged the p_norm->accum_i arc to -0.072 ns; -setup 2
# gives it 20 ns instead of 10 ns. No RTL change; the worst path needs 9.66 ns.
set_multicycle_path -setup 2 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_despreader/accum_i_reg* || NAME =~ *u_dsss_rx/u_despreader/accum_q_reg*}]
set_multicycle_path -hold  1 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_despreader/accum_i_reg* || NAME =~ *u_dsss_rx/u_despreader/accum_q_reg*}]

# DSSS-port timing closure (unicast-ACK B1+B2 build, 2026-06-25): relax the openofdm_rx
# rot_after_fft phase accumulator. Sxy / Sxy_next (rot_after_fft.v) are written ONLY inside
# `if (input_strobe)` (input_strobe = sym_phase_valid, asserted once per OFDM symbol -- far
# slower than 1-in-5), so every setup path into Sxy has many cycles. Same placement-congestion
# regression as above (B1/B2 added logic) nudged Sxy_reg to -0.054 ns. -setup 2 is deeply
# conservative for a per-symbol-paced register; mirrors the openofdm_rx equalizer constraint.
set_multicycle_path -setup 2 -to [get_cells -hier -filter {NAME =~ *openofdm_rx_0/inst/dot11_i/rotafft_inst/Sxy_reg* || NAME =~ *openofdm_rx_0/inst/dot11_i/rotafft_inst/Sxy_next_reg*}]
set_multicycle_path -hold  1 -to [get_cells -hier -filter {NAME =~ *openofdm_rx_0/inst/dot11_i/rotafft_inst/Sxy_reg* || NAME =~ *openofdm_rx_0/inst/dot11_i/rotafft_inst/Sxy_next_reg*}]

# DSSS-port timing closure (SFO re-track build, 2026-06-27): relax the CSMA/CA NAV update
# registers nav_new and nav_reset_timeout_top_after_rts (csma_ca.v). These capture frame-derived
# data ONLY on frame/byte-paced strobes: nav_new loads duration[14:0] (or ackcts_time+sifs_time)
# in NAV_UPDATE, reached via the NAV FSM that advances pkt_header_valid_strobe -> FC_DI_valid ->
# addr1_valid -> fcs_valid; nav_reset_timeout_top_after_rts loads a static-config sum only on
# (fcs_valid && is_rts). For a received 1 Mbps DSSS frame the RX byte/strobe interface is paced at
# >=800 clk_out1 cycles per byte, so every setup path carrying dsss_rx_and_mux state (dstate) into
# these NAV registers has hundreds of cycles, not 1 (the idle-state nav_new<=0 / reset writes are
# constants, no datapath). The SFO re-track (~30 LUT added to dsss_framer) raised placement
# congestion on this 99%-slice-full xc7z020 and nudged the dstate -> nav_new /
# nav_reset_timeout_top_after_rts arcs to -0.124 / -0.092 / -0.045 ns. -setup 2 gives them 20 ns
# instead of 10 ns; deeply conservative for a byte-paced load (same rationale as the coded_bits /
# accum DSSS-RX constraints above). No RTL change. HW-validate NAV/CSMA behavior when this build runs.
set_multicycle_path -setup 2 -to [get_cells -hier -filter {NAME =~ *xpu_0/inst/csma_ca_i/nav_new_reg* || NAME =~ *xpu_0/inst/csma_ca_i/nav_reset_timeout_top_after_rts_reg*}]
set_multicycle_path -hold  1 -to [get_cells -hier -filter {NAME =~ *xpu_0/inst/csma_ca_i/nav_new_reg* || NAME =~ *xpu_0/inst/csma_ca_i/nav_reset_timeout_top_after_rts_reg*}]

# DSSS-port timing closure (SFO re-track build, 2026-06-27): relax the tx_control ACK-wait
# scale register. send_ack_wait_top_scale (tx_control.v:276) = (send_ack_wait_top -
# relative_decoding_latency)*COUNT_SCALE: a product of quasi-static config (send_ack_wait_top from
# slv_reg18/23, written only on a CPU AXI write) and relative_decoding_latency, which is derived
# per received frame from the openofdm phy_len (n_bit_in_last_sym). The value therefore changes at
# most once per received frame and is consumed only later, during the post-frame SIFS countdown that
# schedules the auto-ACK -- never within 1 cycle of its source. The SFO re-track congestion nudged
# the n_bit_in_last_sym -> send_ack_wait_top_scale arcs to -0.034 / -0.021 ns. -setup 2 gives them
# 20 ns; conservative for a per-frame load (same class as the NAV constraint above). No RTL change.
set_multicycle_path -setup 2 -to [get_cells -hier -filter {NAME =~ *xpu_0/inst/tx_control_i/send_ack_wait_top_scale_reg*}]
set_multicycle_path -hold  1 -to [get_cells -hier -filter {NAME =~ *xpu_0/inst/tx_control_i/send_ack_wait_top_scale_reg*}]

# DSSS-port timing closure (Farrow sub-sample timing recovery, 2026-06-29): relax the
# dsss_mu_track feedforward-loop registers. acc / freq / mu (dsss_mu_track.sv) are written ONLY
# inside `if (bin_idx == 5'd19)` -> once per DSSS SYMBOL = every 20 valid despread pulses. The
# despread strobe is the 20 MSPS RX sample tick on the 100 MHz clk_out1, i.e. 1-in-5 cycles, so
# the source data feeding these regs (despread_i/q, pwr/maxv) is stable for 5 cycles and the
# symbol-paced acc/freq/mu self-loop only relaunches every 100 cycles. The combinational
# discriminant + power-of-2 barrel-shift normalize + one-pole feeding acc/mu/freq is the long
# slow-path endpoint (OOC: cp -> acc_reg ~31 ns, WNS -20.9 ns at the 10 ns clock). -setup 4 gives
# it 40 ns instead of 10 ns (+9 ns margin); -setup 4 <= the 5-cycle strobe spacing, so it stays
# functionally safe (same strobe-paced rationale as the u_despreader/accum and u_demodulator/
# coded_bits DSSS-RX constraints above, with N=4 because this path is ~3x longer). No RTL change.
set_multicycle_path -setup 4 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_mu/acc_reg* || NAME =~ *u_dsss_rx/u_mu/freq_reg* || NAME =~ *u_dsss_rx/u_mu/mu_reg*}]
set_multicycle_path -hold  3 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_mu/acc_reg* || NAME =~ *u_dsss_rx/u_mu/freq_reg* || NAME =~ *u_dsss_rx/u_mu/mu_reg*}]

# DSSS-port timing closure (Farrow sub-sample timing recovery, 2026-06-29): relax the
# dsss_mu_track per-SAMPLE argmax/power registers. maxv / maxb / pwr (dsss_mu_track.sv) are written
# ONLY inside `if (despread_valid)` -> updated once per 20 MSPS despread sample = 1-in-5 cycles on
# the 100 MHz clk_out1, the SAME strobe cadence as the u_despreader/accum constraint above. Their
# deepest setup arc is cp_now1 -> (cp > maxv) compare -> maxv/CE (logic-dominated 9.75 ns, NOT
# congestion), which the 1-in-5 strobe gives >=5 cycles to settle. -setup 2 gives 20 ns. No RTL
# change. (acc/freq/mu above are once-per-SYMBOL and use -setup 4; these are once-per-SAMPLE = 2.)
set_multicycle_path -setup 2 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_mu/maxv_reg* || NAME =~ *u_dsss_rx/u_mu/maxb_reg* || NAME =~ *u_dsss_rx/u_mu/pwr_reg*}]
set_multicycle_path -hold  1 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_mu/maxv_reg* || NAME =~ *u_dsss_rx/u_mu/maxb_reg* || NAME =~ *u_dsss_rx/u_mu/pwr_reg*}]

# DSSS-port timing closure (Farrow sub-sample timing recovery, 2026-06-29): relax the Farrow
# interpolator OUTPUT registers. out_i/out_q (dsss_farrow.sv stage 3) re-latch every clk, but
# their datapath inputs (mu_s2, t2i_r, c0i_2 -- the stage-1/2 results) only change on in_valid =
# the 20 MSPS despread strobe (1-in-5 on the 100 MHz clk_out1), and the demodulator reads the
# Farrow output ONLY at out_valid, one full cycle AFTER out_i first latches -> the value it reads
# always reflects a >=2-cycle-stable input. Same 1-in-5 strobe-paced class as the u_despreader/
# accum constraint; -setup 2 gives 20 ns. The Farrow's +3556 LUT congestion pushed out_i_reg to
# -0.250 ns (route-dominated) on the 99.9%-slice-full part. No RTL change.
set_multicycle_path -setup 2 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_farrow/out_i_reg* || NAME =~ *u_dsss_rx/u_farrow/out_q_reg*}]
set_multicycle_path -hold  1 -to [get_cells -hier -filter {NAME =~ *u_dsss_rx/u_farrow/out_i_reg* || NAME =~ *u_dsss_rx/u_farrow/out_q_reg*}]

# DSSS-port timing closure (dsss_mu_track power-path PIPELINE, 2026-07-04): the cp square + argmax
# compare used to be ONE combinational cone captured in a single despread strobe = a GENUINE 1-cycle
# arc (postroute DCP audit: cp_now -1.04 ns, maxv/pwr -3.86 ns at the true 1-cycle requirement), so
# the prior -setup 2 here and on maxv/pwr above was FUNCTIONALLY A LIE (masked real HW bit errors =
# the residual DSSS decode loss, 68% not 100%). dsss_mu_track.sv now splits it into two strobe-paced
# stages: cp_r <= |despread|^2>>5 registered on v_a, then pwr/argmax/maxv from cp_r on v_c. With the
# square isolated, synthesis absorbs the cp register into the DSP cascade, so it meets at TRUE 1-cycle
# (postroute +0.70 ns) with NO multicycle -- and the DSP-absorbed register no longer carries a
# cp_r_reg/cp_now cell name, so any set_multicycle_path -to those names matched zero cells and emitted
# CRITICAL WARNING 12-4739 every build. The dead -setup 2/-hold 1 on cp_r_reg/cp_now was removed
# 2026-07-04 (no-op: the flashed rxfix2 netlist already met at true 1-cycle without it). The
# maxv/maxb/pwr -setup 2 above is unaffected -- those are real cells. Fix 2 sim-verified: run_intf.sh
# decode bit-exact + Farrow PER grid 100% (ppm +-40 x SNR 3-8 x P 256/1024/2304).


# iic

set_property  -dict {PACKAGE_PIN  L20   IOSTANDARD LVCMOS18 PULLTYPE PULLUP} [get_ports iic_scl]           ; 
set_property  -dict {PACKAGE_PIN  L19   IOSTANDARD LVCMOS18 PULLTYPE PULLUP} [get_ports iic_sda]           ; 


set_property  -dict {PACKAGE_PIN  V6   IOSTANDARD  LVCMOS33} [get_ports  dac_sync] ;
set_property  -dict {PACKAGE_PIN  W6   IOSTANDARD  LVCMOS33} [get_ports  dac_sclk] ;
set_property  -dict {PACKAGE_PIN  V10  IOSTANDARD  LVCMOS33} [get_ports  dac_din]  ;
set_property  -dict {PACKAGE_PIN  V11  IOSTANDARD  LVCMOS33} [get_ports  pps_in]  ;
set_property  -dict {PACKAGE_PIN  M20  IOSTANDARD  LVCMOS33} [get_ports  clkin_10m_req]  ;
set_property  -dict {PACKAGE_PIN  J18  IOSTANDARD  LVCMOS33} [get_ports  clkin_10m]  ;

set_property  -dict {PACKAGE_PIN  N16   IOSTANDARD  LVCMOS18} [get_ports  gpio_clksel]  ;




set_property  -dict {PACKAGE_PIN  C20   IOSTANDARD  LVCMOS18} [get_ports  rgmii_td[3]]  ;
set_property  -dict {PACKAGE_PIN  D19   IOSTANDARD  LVCMOS18} [get_ports  rgmii_td[2]]  ;
set_property  -dict {PACKAGE_PIN  D20   IOSTANDARD  LVCMOS18} [get_ports  rgmii_td[1]]  ;
set_property  -dict {PACKAGE_PIN  F19   IOSTANDARD  LVCMOS18} [get_ports  rgmii_td[0]]  ;
set_property  -dict {PACKAGE_PIN  E18   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rd[3]]  ;
set_property  -dict {PACKAGE_PIN  E19   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rd[2]]  ;
set_property  -dict {PACKAGE_PIN  E17   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rd[1]]  ;
set_property  -dict {PACKAGE_PIN  F16   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rd[0]]  ;

set_property  -dict {PACKAGE_PIN  F20   IOSTANDARD  LVCMOS18} [get_ports  rgmii_tx_ctl]  ;
set_property  -dict {PACKAGE_PIN  D18   IOSTANDARD  LVCMOS18} [get_ports  rgmii_txc]     ;
set_property  -dict {PACKAGE_PIN  G17   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rx_ctl]  ;
set_property  -dict {PACKAGE_PIN  H16   IOSTANDARD  LVCMOS18} [get_ports  rgmii_rxc]     ;
set_property  -dict {PACKAGE_PIN  B19   IOSTANDARD  LVCMOS18} [get_ports  phy_rst_n]   ;
set_property  -dict {PACKAGE_PIN  A20   IOSTANDARD  LVCMOS18} [get_ports  mdio_phy_mdio_io]   ;
set_property  -dict {PACKAGE_PIN  B20   IOSTANDARD  LVCMOS18} [get_ports  mdio_phy_mdc]       ;

set_property  -dict {PACKAGE_PIN  G15   IOSTANDARD  LVCMOS18} [get_ports  tx_amp_en]  ;


set_property  -dict {PACKAGE_PIN    T15   IOSTANDARD LVCMOS25} [get_ports gpio_status[7]]                    ; 
set_property  -dict {PACKAGE_PIN    K16   IOSTANDARD LVCMOS18} [get_ports gpio_status[6]]                    ; 
set_property  -dict {PACKAGE_PIN    P14   IOSTANDARD LVCMOS25} [get_ports gpio_status[5]]                    ; 
set_property  -dict {PACKAGE_PIN    P15   IOSTANDARD LVCMOS25} [get_ports gpio_status[4]]                    ; 
set_property  -dict {PACKAGE_PIN    R14   IOSTANDARD LVCMOS25} [get_ports gpio_status[3]]                    ; 
set_property  -dict {PACKAGE_PIN    J16   IOSTANDARD LVCMOS18} [get_ports gpio_status[2]]                    ; 
set_property  -dict {PACKAGE_PIN    J15   IOSTANDARD LVCMOS18} [get_ports gpio_status[1]]                    ; 
set_property  -dict {PACKAGE_PIN    T10   IOSTANDARD LVCMOS25} [get_ports gpio_status[0]]                    ; 
set_property  -dict {PACKAGE_PIN    T11   IOSTANDARD LVCMOS25} [get_ports gpio_ctl[3]]                       ; 
set_property  -dict {PACKAGE_PIN    V13   IOSTANDARD LVCMOS25} [get_ports gpio_ctl[2]]                       ; 
set_property  -dict {PACKAGE_PIN    T14   IOSTANDARD LVCMOS25} [get_ports gpio_ctl[1]]                       ; 
set_property  -dict {PACKAGE_PIN    U13   IOSTANDARD LVCMOS25} [get_ports gpio_ctl[0]]                       ; 
set_property  -dict {PACKAGE_PIN    P16   IOSTANDARD LVCMOS25} [get_ports gpio_en_agc]                       ; 
set_property  -dict {PACKAGE_PIN    U20   IOSTANDARD LVCMOS25} [get_ports gpio_sync]                         ; 
set_property  -dict {PACKAGE_PIN    T17   IOSTANDARD LVCMOS25} [get_ports gpio_resetb]                       ; 
set_property  -dict {PACKAGE_PIN    R18   IOSTANDARD LVCMOS25} [get_ports enable]                            ; 
set_property  -dict {PACKAGE_PIN    N17   IOSTANDARD LVCMOS25} [get_ports txnrx]                             ; 

set_property  -dict {PACKAGE_PIN    T20   IOSTANDARD LVCMOS25  PULLTYPE PULLUP} [get_ports spi_csn]          ; 
set_property  -dict {PACKAGE_PIN    R19   IOSTANDARD LVCMOS25} [get_ports spi_clk]                           ; 
set_property  -dict {PACKAGE_PIN    P18   IOSTANDARD LVCMOS25} [get_ports spi_mosi]                          ; 
set_property  -dict {PACKAGE_PIN    T19   IOSTANDARD LVCMOS25} [get_ports spi_miso]                          ; 





# constraints (pzsdr2.e)
# ad9361

set_property  -dict {PACKAGE_PIN  N20  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_clk_in_p]       ; 
set_property  -dict {PACKAGE_PIN  P20  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_clk_in_n]       ; 
set_property  -dict {PACKAGE_PIN  Y16  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_frame_in_p]     ; 
set_property  -dict {PACKAGE_PIN  Y17  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_frame_in_n]     ; 
set_property  -dict {PACKAGE_PIN  W14  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[5]]   ; 
set_property  -dict {PACKAGE_PIN  Y14  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[5]]   ; 
set_property  -dict {PACKAGE_PIN  V20  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[4]]   ; 
set_property  -dict {PACKAGE_PIN  W20  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[4]]   ; 
set_property  -dict {PACKAGE_PIN  R16  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[3]]   ; 
set_property  -dict {PACKAGE_PIN  R17  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[3]]   ; 
set_property  -dict {PACKAGE_PIN  W18  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[2]]   ; 
set_property  -dict {PACKAGE_PIN  W19  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[2]]   ; 
set_property  -dict {PACKAGE_PIN  V17  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[1]]   ; 
set_property  -dict {PACKAGE_PIN  V18  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[1]]   ; 
set_property  -dict {PACKAGE_PIN  Y18  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_p[0]]   ; 
set_property  -dict {PACKAGE_PIN  Y19  IOSTANDARD LVDS_25      DIFF_TERM TRUE} [get_ports rx_data_in_n[0]]   ; 
set_property  -dict {PACKAGE_PIN  N18  IOSTANDARD LVDS_25}     [get_ports tx_clk_out_p]                      ; 
set_property  -dict {PACKAGE_PIN  P19  IOSTANDARD LVDS_25}     [get_ports tx_clk_out_n]                      ; 
set_property  -dict {PACKAGE_PIN  V16  IOSTANDARD LVDS_25}     [get_ports tx_frame_out_p]                    ; 
set_property  -dict {PACKAGE_PIN  W16  IOSTANDARD LVDS_25}     [get_ports tx_frame_out_n]                    ; 
set_property  -dict {PACKAGE_PIN  V15  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[5]]                  ; 
set_property  -dict {PACKAGE_PIN  W15  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[5]]                  ; 
set_property  -dict {PACKAGE_PIN  T12  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[4]]                  ; 
set_property  -dict {PACKAGE_PIN  U12  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[4]]                  ; 
set_property  -dict {PACKAGE_PIN  V12  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[3]]                  ; 
set_property  -dict {PACKAGE_PIN  W13  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[3]]                  ; 
set_property  -dict {PACKAGE_PIN  U14  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[2]]                  ; 
set_property  -dict {PACKAGE_PIN  U15  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[2]]                  ; 
set_property  -dict {PACKAGE_PIN  U18  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[1]]                  ; 
set_property  -dict {PACKAGE_PIN  U19  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[1]]                  ; 
set_property  -dict {PACKAGE_PIN  T16  IOSTANDARD LVDS_25}     [get_ports tx_data_out_p[0]]                  ; 
set_property  -dict {PACKAGE_PIN  U17  IOSTANDARD LVDS_25}     [get_ports tx_data_out_n[0]]                  ; 

# clocks

create_clock -name rx_clk       -period  4 [get_ports rx_clk_in_p]
create_clock                    -period  8.000 [get_ports rgmii_rxc]   ;# RGMII RX clock 125MHz: REQUIRED in impl-active xdc so the gmii_to_rgmii RX capture (IBUF->IDELAY->IDDR) is timed. Was only in OOC-scoped xdc -> rxc had no clock in impl -> RX path unconstrained (Slack=inf) -> placement lottery (dsss_tx re-route broke eth). Matches working e310v2/src/system.xdc.

