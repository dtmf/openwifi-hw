# // SPDX-License-Identifier: AGPL-3.0-or-later
# // openwifi-hw IP packaging project for the opendsss_tx core.
# //
# // Sourced by boards/package_ip_complex.tcl AFTER it `cd`s into ip/opendsss_tx
# // with argc=1, argv=[BOARD_NAME]. Creates a Vivado project whose TOP module is
# // the wrapper `opendsss_tx` (VLNV user.org:user:opendsss_tx:1.0), sources the
# // wrapper plus the pure DSSS modulator from the opendsss submodule
# // (../opendsss/verilog), tags the .sv files, and leaves the project OPEN for
# // ipx::package_project. It does NOT launch runs and does NOT close the project.
# // Plan D3 = B-clean: the TX arbiter/mux (dsss_tx_and_mux) is NOT packaged here —
# // it stays in tx_intf.

set origin_dir [file dirname [file normalize [info script]]]

set BOARD_NAME [expr {[llength $argv] > 0 ? [lindex $argv 0] : "antsdr_e200"}]
if {$BOARD_NAME eq ""} { set BOARD_NAME antsdr_e200 }

# board -> part (sets $part_string from $BOARD_NAME)
source $origin_dir/../parse_board_name.tcl
if {$part_string eq ""} {
    error "opendsss_tx.tcl: could not resolve a part for BOARD_NAME='$BOARD_NAME'"
}

# Sources, dependency order (leaves first). Pure DSSS modulator from the opendsss
# submodule + the openwifi-integration wrapper (top). NO arbiter, NO tx_intf deps.
set sub $origin_dir/../opendsss/verilog
set src_files [list \
    [file normalize $sub/dsss_crc.sv] \
    [file normalize $sub/dsss_plcp_crc.sv] \
    [file normalize $sub/dsss_tx.sv] \
    [file normalize $origin_dir/src/opendsss_tx.sv] \
]
foreach f $src_files {
    if {![file exists $f]} { error "opendsss_tx.tcl: source not found: $f" }
}

create_project -force opendsss_tx ./project_1 -part $part_string
set obj [current_project]
set_property -name "default_lib"        -value "xil_defaultlib" -objects $obj
set_property -name "target_language"    -value "Verilog"        -objects $obj
set_property -name "simulator_language" -value "Mixed"          -objects $obj
set_property -name "source_mgmt_mode"   -value "All"            -objects $obj

set sfs [get_filesets sources_1]
add_files -norecurse -fileset $sfs $src_files
set_property file_type SystemVerilog [get_files -of_objects $sfs [list {*}$src_files]]
set_property top opendsss_tx $sfs
update_compile_order -fileset sources_1

puts "opendsss_tx.tcl: project created (top=opendsss_tx, part=$part_string, [llength $src_files] sources)"
