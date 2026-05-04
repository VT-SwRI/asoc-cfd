# Created by Microsemi Libero Software 11.9.6.7
# Sat May 02 17:51:07 2026

# (NEW DESIGN)

# create a new design
new_design -name "fullsystem_top" -family "ProASIC3E"
set_device -die {A3PE1500} -package {208 PQFP} -speed {STD} -voltage {1.5} -IO_DEFT_STD {LVTTL} -RESERVEMIGRATIONPINS {1} -RESTRICTPROBEPINS {1} -RESTRICTSPIPINS {0} -TARGETDEVICESFORMIGRATION {IT10X10M3} -TEMPR {COM} -UNUSED_MSS_IO_RESISTOR_PULL {None} -VCCI_1.5_VOLTR {COM} -VCCI_1.8_VOLTR {COM} -VCCI_2.5_VOLTR {COM} -VCCI_3.3_VOLTR {COM} -VOLTR {COM}


# set default back-annotation base-name
set_defvar "BA_NAME" "fullsystem_top_ba"
set_defvar "IDE_DESIGNERVIEW_NAME" {Impl1}
set_defvar "IDE_DESIGNERVIEW_COUNT" "1"
set_defvar "IDE_DESIGNERVIEW_REV0" {Impl1}
set_defvar "IDE_DESIGNERVIEW_REVNUM0" "1"
set_defvar "IDE_DESIGNERVIEW_ROOTDIR" {C:\Users\aamar\Documents\SeniorSem2\4806-MDE\FullSystem\FullSystem\designer}
set_defvar "IDE_DESIGNERVIEW_LASTREV" "1"

# set working directory
set_defvar "DESDIR" "C:/Users/aamar/Documents/SeniorSem2/4806-MDE/FullSystem/FullSystem/designer/impl1"

# set back-annotation output directory
set_defvar "BA_DIR" "C:/Users/aamar/Documents/SeniorSem2/4806-MDE/FullSystem/FullSystem/designer/impl1"

# enable the export back-annotation netlist
set_defvar "BA_NETLIST_ALSO" "1"

# set EDIF options
set_defvar "EDNINFLAVOR" "GENERIC"

# set HDL options
set_defvar "NETLIST_NAMING_STYLE" "VERILOG"

# setup status report options
set_defvar "EXPORT_STATUS_REPORT" "1"
set_defvar "EXPORT_STATUS_REPORT_FILENAME" "fullsystem_top.rpt"

# legacy audit-mode flags (left here for historical reasons)
set_defvar "AUDIT_NETLIST_FILE" "1"
set_defvar "AUDIT_DCF_FILE" "1"
set_defvar "AUDIT_PIN_FILE" "1"
set_defvar "AUDIT_ADL_FILE" "1"

# import of input files
import_source  \
-format "edif" -edif_flavor "GENERIC" -netlist_naming "VERILOG" {../../synthesis/fullsystem_top.edn}

# save the design database
save_design {fullsystem_top.adb}


compile
report -type "status" {fullsystem_top_compile_report.txt}
report -type "pin" -listby "name" {fullsystem_top_report_pin_byname.txt}
report -type "pin" -listby "number" {fullsystem_top_report_pin_bynumber.txt}

save_design
