#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Fetch/checkout the opendsss submodule (the 802.11b 1 Mbps DSSS PHY, RX+TX)
# pinned by ip/opendsss in .gitmodules, mirroring get_ip_openofdm_rx.sh.
# Run from the openwifi-hw repo root.

home_dir=$(pwd)

set -x
cd ip/
git submodule init opendsss
git submodule update opendsss
# opendsss is SHA-pinned (no branch key in .gitmodules), same as openofdm_rx.

cd $home_dir
