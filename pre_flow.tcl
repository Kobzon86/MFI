#
# Pre flow script
#

load_package flow
load_package misc

array set src_extensions { "*.vhd" "*.sv" "*.v" "" }

foreach src_file [ glob -type f "./ip/*" ] {
  foreach ext [ array get src_extensions ] {
    if { [ string length $ext ] > 0 && [ string match -nocase $ext $src_file ] == 1 } {
      set ext_length [ expr [ string length $ext ] - 1 ]
      set ip_name [ string range $src_file 0 end-$ext_length ]
      if { [ file exists "$ip_name.qip" ] == 0 } {
        qexec "$env(QUARTUS_BINDIR)/qmegawiz -silent $src_file > $ip_name.log"
      }
    }
  }
}

if { [ file exists "./qsys/synthesis/qsys.qip" ] == 0 } {
  qexec "$env(QSYS_ROOTDIR)/qsys-generate ./qsys/qsys.qsys --synthesis=VERILOG --output-directory=./qsys > ./qsys/qsys.log"
}
