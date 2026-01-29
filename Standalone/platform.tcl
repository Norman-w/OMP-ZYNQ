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
