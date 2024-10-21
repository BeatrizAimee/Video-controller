
set TOP_MODULE $::env(TOP_MODULE)

## Get yosys commands ???
yosys -import

## Add design files
read_verilog  $TOP_MODULE.v

## Set TOP LEVEL module
hierarchy -top $TOP_MODULE

# Elaborate
prep

# Save the generic RTL synthesis for preview
write_json ${TOP_MODULE}_prep.json

# Synthesize to intel fpgas
synth_intel_alm -family cyclonev

# Save the synthesized project
write_json ${TOP_MODULE}_syn.json

# Save the verilog output
write_verilog ${TOP_MODULE}_syn.v


