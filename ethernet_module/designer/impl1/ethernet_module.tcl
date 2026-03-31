# Created by Microsemi Libero Software 11.9.6.7
# Thu Mar 26 13:06:34 2026

# (OPEN DESIGN)

open_design "ethernet_module.adb"

# set default back-annotation base-name
set_defvar "BA_NAME" "ethernet_module_ba"
set_defvar "IDE_DESIGNERVIEW_NAME" {Impl1}
set_defvar "IDE_DESIGNERVIEW_COUNT" "1"
set_defvar "IDE_DESIGNERVIEW_REV0" {Impl1}
set_defvar "IDE_DESIGNERVIEW_REVNUM0" "1"
set_defvar "IDE_DESIGNERVIEW_ROOTDIR" {C:\Users\zackp\OneDrive\Documents\ECE_4806\Libero\ethernet_module\designer}
set_defvar "IDE_DESIGNERVIEW_LASTREV" "1"


# import of input files
import_source  \
-format "edif" -edif_flavor "GENERIC" -netlist_naming "VERILOG" {../../synthesis/ethernet_module.edn} -merge_physical "yes" -merge_timing "yes"
compile
report -type "status" {ethernet_module_compile_report.txt}
report -type "pin" -listby "name" {ethernet_module_report_pin_byname.txt}
report -type "pin" -listby "number" {ethernet_module_report_pin_bynumber.txt}

save_design
