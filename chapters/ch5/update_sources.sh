#!/bin/bash
#
# script to filter source time functions using pre-computed matching filters

OUT=${PWD}/dat/


input=$1
filters=$2
output=$3

ns=$(In ${input} | grep n2= | cut -d\  -f1 | cut -d= -f2 )

allsrc=""

for (( s=0; s<${ns}; s+=1 ))
do
    echo "Source " $s

    Window < ${input} n2=1 f2=${s} > src.H
    Window < ${filters} n2=1 f2=${s} > filter.H
    Filter < src.H filter=filter.H > out${s}.H

    allsrc=${allsrc}' 'out${s}.H
done

echo ${allsrc}

Cat ${allsrc} axis=3 | Transp plane=23 datapath=${OUT} > ${output}
python3 ${PWD}/../../code/local/bin/remove.py src.H filter.H out*.H

