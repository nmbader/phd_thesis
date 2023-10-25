#!/bin/bash
#
# script to generate synthetic data using extended models (one model per source)

B=${PWD}/../../code/local/bin
BG=${PWD}/../../code/local_gpu/bin
P=${PWD}/../../code/python
Rm='python2.7 /opt/SEP/SEP7.0/bin/Rm'
OUT=${PWD}/dat/

source=$1
model=$2
attr=$3
output=$4

ns=$(In ${source} | grep n2=  | cut -d\  -f1 | cut -d= -f2 )
nm=$(In ${model}  | grep  n4= | cut -d\  -f1 | cut -d= -f2 )
na=$(In ${attr}   | grep n3=  | cut -d\  -f1 | cut -d= -f2 )
ntr=$(In ${attr}  | grep n2=  | cut -d\  -f1 | cut -d= -f2 )

echo "Nb of sources " ${ns}
echo "Nb of models " ${nm}

allsyn=""

if [ ${ns} -ne ${nm} ]; then
  echo "Nb of sources and models do not match"
  exit 1
fi
if [ ${ns} -ne ${na} ]; then
  echo "Nb of sources in wavelets and attributes do not match"
  exit 1
fi

# prepare coordinates file for all sources
Window < ${attr} n1=1 f1=0 datapath=${OUT} > sid.H
Window < ${attr} n1=1 f1=16 | Scale dscale=1e-5 datapath=${OUT} > rx.H
Window < ${attr} n1=1 f1=18 | Scale dscale=1e-5 datapath=${OUT} > rz.H
Window < ${attr} n1=1 f1=19 | Scale dscale=1e-5 datapath=${OUT} > sx.H
Window < ${attr} n1=1 f1=21 | Scale dscale=1e-5 datapath=${OUT} > sz.H
Window < ${attr} n1=1 f1=24 datapath=${OUT} > rdip.H
echo n1=1 n2=${ntr} n3=${na} >> sid.H
echo n1=1 n2=${ntr} n3=${na} >> sx.H
echo n1=1 n2=${ntr} n3=${na} >> sz.H
echo n1=1 n2=${ntr} n3=${na} >> rx.H
echo n1=1 n2=${ntr} n3=${na} >> rz.H
echo n1=1 n2=${ntr} n3=${na} >> rdip.H
Cat sid.H sx.H sz.H rx.H rz.H rdip.H axis=1 datapath=${OUT} > srcoord.H
${Rm} sid.H sx.H sz.H rx.H rz.H rdip.H

for (( s=0; s<${ns}; s+=1 ))
do
    echo "Source " $s

    Window < ${source} n2=1 f2=${s} datapath=${OUT} > src.H
    Window < ${model} n4=1 f4=${s} datapath=${OUT} > model.H
    Window < srcoord.H n3=1 f3=${s} datapath=${OUT} > srcoord0.H
    python ${P}/dumpHeader.py --input=srcoord0.H >> srcoord.txt

    ${BG}/WE_MODELING.x source=src.H model=model.H srcoord=srcoord.txt output=shot${s}.H datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_strength=0.02 \
	device=3

    ${Rm} src.H model.H srcoord0.H
    rm -f srcoord.txt
	
    allsyn=${allsyn}' 'shot${s}.H
done

echo ${allsyn}

Cat ${allsyn} axis=3 datapath=${OUT} > ${output}

${Rm} shot*.H srcoord.H