# // SPDX-License-Identifier: AGPL-3.0-or-later
# // openwifi-hw IP packaging project for the opendsss_rx core.
# //
# // Sourced by boards/package_ip_complex.tcl AFTER it `cd`s into ip/opendsss_rx
# // with argc=1, argv=[BOARD_NAME]. Creates a Vivado project whose TOP module is
# // the wrapper `opendsss_rx` (which fixes the packaged IP name / VLNV
# // user.org:user:opendsss_rx:1.0), sources the wrapper plus the pure DSSS RX PHY
# // from the opendsss submodule (../opendsss/verilog), tags the .sv files, and
# // leaves the project OPEN for ipx::package_project. It does NOT launch runs and
# // does NOT close the project (package_ip_complex does the packaging + cleanup
# // via close_project -delete). Modeled on ip/openofdm_rx/openofdm_rx.tcl and the
# // standalone opendsss/opendsss_rx.tcl. Plan D3 = B-clean: the arbiter/mux
# // (dsss_rx_and_mux) is NOT packaged here — it stays in rx_intf.

set origin_dir [file dirname [file normalize [info script]]]

set BOARD_NAME [expr {[llength $argv] > 0 ? [lindex $argv 0] : "antsdr_e200"}]
if {$BOARD_NAME eq ""} { set BOARD_NAME antsdr_e200 }

# board -> part (openwifi-hw's own mapping; sets $part_string from $BOARD_NAME)
source $origin_dir/../parse_board_name.tcl
if {$part_string eq ""} {
    error "opendsss_rx.tcl: could not resolve a part for BOARD_NAME='$BOARD_NAME'"
}

# Sources, dependency order (leaves first). Pure behavioral SystemVerilog PHY from
# the opendsss submodule + the openwifi-integration wrapper (top). NO arbiter, NO
# rx_intf deps. ipx::package_project -import_files copies these into the packaged IP.
set sub $origin_dir/../opendsss/verilog
set src_files [list \
    [file normalize $sub/dsss_crc.sv] \
    [file normalize $sub/dsss_plcp_crc.sv] \
    [file normalize $sub/dsss_controller.sv] \
    [file normalize $sub/dsss_p_norm.sv] \
    [file normalize $sub/dsss_despreader.sv] \
    [file normalize $sub/dsss_peak_finder.sv] \
    [file normalize $sub/dsss_demodulator.sv] \
    [file normalize $sub/dsss_farrow.sv] \
    [file normalize $sub/dsss_mu_track.sv] \
    [file normalize $sub/dsss_framer.sv] \
    [file normalize $sub/dsss_rx_fb.sv] \
    [file normalize $origin_dir/src/opendsss_rx.sv] \
]
foreach f $src_files {
    if {![file exists $f]} { error "opendsss_rx.tcl: source not found: $f" }
}

create_project -force opendsss_rx ./project_1 -part $part_string
set obj [current_project]
set_property -name "default_lib"        -value "xil_defaultlib" -objects $obj
set_property -name "target_language"    -value "Verilog"        -objects $obj
set_property -name "simulator_language" -value "Mixed"          -objects $obj
set_property -name "source_mgmt_mode"   -value "All"            -objects $obj

set sfs [get_filesets sources_1]
add_files -norecurse -fileset $sfs $src_files
# DSSS core is SystemVerilog; tag explicitly so packaging never mis-parses .sv as
# Verilog-2001 (the same guard rx_intf.tcl uses).
set_property file_type SystemVerilog [get_files -of_objects $sfs [list {*}$src_files]]
set_property top opendsss_rx $sfs
update_compile_order -fileset sources_1

puts "opendsss_rx.tcl: project created (top=opendsss_rx, part=$part_string, [llength $src_files] sources)"
