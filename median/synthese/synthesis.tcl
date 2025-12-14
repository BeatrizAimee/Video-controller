
set HDL_FILES [split $::env(HDL_FILES)]
set TOP_MODULE $::env(TOP_MODULE)

## Get yosys commands ???
yosys -import

## Add design files
foreach HDL_FILE $HDL_FILES {
    read_verilog -sv $HDL_FILE
}

## Set TOP LEVEL module
hierarchy -top $TOP_MODULE
flatten -noscopeinfo

# Elaborate
prep

# Save the generic RTL synthesis for preview
write_json ${TOP_MODULE}_prep.json

# Synthesize to ICE40 fpgas
synth_ice40

# Save the synthesized project
write_json ${TOP_MODULE}_syn.json

# Save the verilog output
write_verilog ${TOP_MODULE}_syn.v


