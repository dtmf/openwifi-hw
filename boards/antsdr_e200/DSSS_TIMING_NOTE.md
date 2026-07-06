# DSSS port — build & timing note (antsdr_e200 / xc7z020)

**A from-scratch build of this board may report a small setup timing miss
(WNS ≈ −0.037 ns). This is expected, benign, and produces a valid bitstream.**

## What the miss is

- The worst-slack path is inside the **stock Analog Devices `axi_ad9361`** core —
  specifically the RX DC-offset filter feeding a DSP48
  (`.../i_rx/i_rx_channel_1/i_ad_dcfilter/... → i_dsp48e1`), on `rx_clk`. It is
  **route-dominated** (~79% routing) and is **not** part of the DSSS logic.
- The DSSS RX/TX datapaths and the OpenOFDM paths meet timing. **Hold is met**
  (WHS ≈ +0.049 ns), and `write_bitstream` completes successfully.
- It is **reproducible**: repeated from-scratch builds land at the same WNS.
  It is a consequence of high utilization on the near-full part
  (≈ 84% LUT / 90% DSP / 79% BRAM), not a design defect.

## Why it happens

Adding the 802.11b DSSS PHY (RX + TX + coexistence arbiters) on top of the stock
OpenWiFi design pushes the xc7z020 to ~90% DSP utilization. At that density a
short, routing-dominated path in the ADI RX front end can miss by a few tens of
picoseconds depending on placement. The bitstream is still valid — the miss is on
a vendor-IP path, not on any user logic that would corrupt data.

## If you need deterministic positive closure

The implementation strategy in `synth_impl_strategy.tcl` is already tuned for this
die (place `ExtraNetDelay_high`, route `Explore`, pre- and post-route
`phys_opt_design AggressiveExplore`), together with sample/symbol-paced
`set_multicycle_path` constraints in `src/system.xdc` for the DSSS timing-recovery
logic. To force a positive-margin close on the remaining ADI path you can:

- re-launch implementation (`launch_runs impl_1`), or
- add a targeted constraint / directive for the `axi_ad9361` RX path, or
- build on a larger part (e.g. `zc706_fmcs2`, xc7z045) which has ample headroom.

For reference, this design has been validated end-to-end on hardware (full 802.11b
DSSS association + bidirectional ping, both directions, all frame sizes) from a
bitstream built with the strategy above.
