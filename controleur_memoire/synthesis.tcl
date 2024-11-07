
## Get yosys commands inside the  tcl world
yosys -import

# variables
set TOP_MODULE $::env(TOP_MODULE)
set HDL_FILES $::env(HDL_FILES)


## Add design files 
## 1/It seems that the "read_slang" command doesnt allow reading file by file
## 2/It seems that the "read_slang" command doesnt allow reading a list of file in a string
## The workaround: use a list expansion operator...
set result [{*}"read_slang $HDL_FILES"]

log $result

### Set TOP LEVEL module

hierarchy -top $TOP_MODULE
#
## Elaborate
prep

## Save the generic RTL synthesis for preview
write_json ${TOP_MODULE}_prep.json

## Synthesize to intel fpgas
synth_intel_alm -family cyclonev

## Save the synthesized project
write_json ${TOP_MODULE}_syn.json

## Save the verilog output
write_verilog ${TOP_MODULE}_syn.v


