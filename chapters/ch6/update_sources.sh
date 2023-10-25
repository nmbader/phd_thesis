#!/bin/bash
#
# script to filter source time functions using pre-computed matching filters

OUT=${PWD}/dat/


input=$1
filters=$2
output=$3

ns=$(In ${input} | grep n3= | cut -d\  -f1 | cut -d= -f2 )

allsrc=""

for (( s=0; s<${ns}; s+=1 ))
do
    echo "Source " $s

    Window < ${input} n3=1 f3=${s} > src.H
    Window < ${filters} n2=1 f2=${s} > filter.H
    FX_FILTER.x < src.H filter=filter.H > out${s}.H

    allsrc=${allsrc}' 'out${s}.H
done

echo ${allsrc}

Cat ${allsrc} axis=3 datapath=${OUT} > ${output}
python3 ${PWD}/../../code/local/bin/remove.py src.H filter.H out*.H

