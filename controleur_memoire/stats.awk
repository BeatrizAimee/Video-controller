BEGIN {
        # 110 registres du wrapper à enlever
        REG_OFFSET=110
    }

/5\.48/ {OK=1;RESOURCES["LUT"]=0;RESOURCES["CARRY"]=0;RESOURCES["FF"]=0;RESOURCES["RAM40"]=0}
/^===\sdesign\shierarchy\s===/ {OK=0}
/SB_CARRY/ {if(OK) {RESOURCES["CARRY"]=$1;NEXT}}
/SB_LUT.*/ {if(OK) {RESOURCES["LUT"]+=$1}}
/SB_DFF.*/ {if(OK) {RESOURCES["FF"]+=$1}}
/SB_RAM40_4K/ {if(OK) {RESOURCES["RAM40"]=$1}}
END {
    RESOURCES["FF"] -= REG_OFFSET
    print "============================="
    print " + iCE40 Ressources:"
    print "============================="
    for (key in RESOURCES) {
        printf("SB%-10s%8d\n",key,RESOURCES[key])
    }
    print "============================="
}
