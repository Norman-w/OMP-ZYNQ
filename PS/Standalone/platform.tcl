# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\ZYNQ\Norman\OMP\Standalone\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\ZYNQ\Norman\OMP\Standalone\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {Standalone}\
-hw {D:\ZYNQ\Norman\OMP\PL\System_wrapper.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {D:/ZYNQ/Norman/OMP}

platform write
platform generate -domains 
platform active {Standalone}
platform generate
bsp reload
bsp setlib -name lwip211 -ver 1.5
bsp write
bsp reload
catch {bsp regenerate}
platform config -updatehw {D:/ZYNQ/Norman/OMP/PL/System_wrapper.xsa}
bsp reload
catch {bsp regenerate}
catch {bsp regenerate}
platform generate -domains standalone_domain 
bsp reload
domain remove standalone_domain
platform generate -domains 
platform write
domain create -name {Standalone} -os {standalone} -proc {ps7_cortexa9_0} -arch {32-bit} -display-name {Standalone} -desc {} -runtime {cpp}
platform generate -domains 
platform write
domain -report -json
bsp reload
platform active {Standalone}
bsp reload
bsp setlib -name lwip211 -ver 1.5
bsp write
bsp reload
catch {bsp regenerate}
platform generate -domains Standalone,standalone_domain 
platform clean
platform generate
