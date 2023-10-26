# 2D FWI for the monitor well
##### Preparations #####
# 'make prepare_data' then run Data_selection notebook, then 'make prepare_avo' then run AVO_estimation notebook


F = fig
D = dat
B=${PWD}/../../code/local/bin
BG=${PWD}/../../code/local_gpu/bin
P=${PWD}/../../code/python
OUT=${PWD}/dat/

MPIRUN=/sep/nmbader/openmpi/bin/mpirun --host jarvis -np 4 -bind-to none --oversubscribe

# Rm = python2.7 /opt/SEP/SEP7.0/bin/Rm
Rm = python3 ${PWD}/../../code/local/bin/remove.py

###############################################################################################################
# Inputs
###############################################################################################################

# DAS data after tube waves mute + convolution with Hankel function + mild denoising by FK filtering 
DATA=${PWD}/../ch4/dat/ch4_das.H
# DAS data after tube waves mute + mild denoising by FK filtering 
DATA_3D=${PWD}/../ch4/dat/ch4_das_3d.H
# Mask (and mute)
MASK=${PWD}/../ch4/dat/ch4_mute_mask.H
# Header attributes
ATTR=${PWD}/../../input_data/das/monitor_headers.H
# Reservoir horizon
HRZ=${PWD}/../ch4/dat/ch4_hrz.H
# VTI model
MODEL=${PWD}/../ch4/dat/ch4_elasticModelVTI1.H
# Sources estimated from unstimulated part
SRC=${PWD}/../ch4/dat/ch4_all_time_func.H
# Sources estimated from stimulated part
SRC_S=${PWD}/../ch4/dat/ch4_all_time_func_s.H

###############################################################################################################
# Operations on data
###############################################################################################################

# anti-alias low-pass filter 250 Hz, scale the filter so that its amplitude spectrum peaks at 1
${D}/ch5_lp250.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=301 dt=0.0005 type=butterworth low_cutoff=0.0 high_cutoff=0.2 half_order=2 phase=zero datapath=${OUT} > temp.H
	${B}/FX_FILTER.x < temp.H filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | Scale dscale=1 datapath=${OUT} > $@
	${Rm} temp.H

# AA-filter and resample to 2 ms
${D}/ch5_data.H: ${D}/ch5_lp250.H
	${B}/FX_FILTER.x < ${DATA} filter=$(word 1,$^) | ${B}/RESAMPLE.x si=0.002 type=sinc sinc_half_length=11 datapath=${OUT} > $@

# AA-filter and resample to 2 ms
${D}/ch5_data_3d.H: ${D}/ch5_lp250.H
	${B}/FX_FILTER.x < ${DATA_3D} filter=$(word 1,$^) | ${B}/RESAMPLE.x si=0.002 type=sinc sinc_half_length=11 datapath=${OUT} > $@

# resample the mute
${D}/ch5_mute.H:
	${B}/RESAMPLE.x < ${MASK} si=0.002 type=linear datapath=${OUT} > $@

# All 100 time functions scaled by the MTs - Pad time axis to match the data
${D}/ch5_sources.H:
	Pad < ${SRC} n1out=175 datapath=${OUT} > $@

# for the stimulated side, extrapolate first 10 shots to simplify the subsequent processing (they will be dropped later)
${D}/ch5_sources_s.H:
	Pad < ${SRC_S} n1out=175 beg2=10 extend=1 datapath=${OUT} > $@

# copy the header attributes
${D}/ch5_data.HH:
	Cp < ${ATTR} datapath=${OUT} > $@

###############################################################################################################
# Operations on model
###############################################################################################################

# cut the model
${D}/ch5_model.H:
	Window < ${MODEL} min1=1.88 datapath=${OUT} > $@

# Copy horizon
${D}/ch5_hrz.H:
	Cp < ${HRZ} datapath=${OUT} > $@

# create a full mask for rho, delta, epsilon
${D}/ch5_mask0.H: ${D}/ch5_model.H
	Window < $< n3=1 f3=3 | Clip clip=0 chop=greater to=1 | Pad end3=1 extend=1 | Pad end3=3 extend=0 datapath=${OUT} > $@


# create reservoir layer mask for vp and vs and full mask for rho, delta, epsilon
${D}/ch5_mask.H: ${D}/ch5_model.H
	Window < $< n3=1 f3=3 | Clip clip=0.15 chop=less to=0 | Clip clip=0.1 chop=greater to=1 | Window min1=1.91 | Pad beg1=30 | Smooth rect1=3 rect2=21 | Scale | Pad end3=1 extend=1 | Pad end3=3 extend=0 datapath=${OUT} > $@


###############################################################################################################
# The outputs above are used in Data_selection.ipynb for data selection and grouping
# this results in 4 groups:
# group1: keep first perf per stage, total 20 perfs
# group2: keep second perf per stage, total 20 perfs
# group3: dropping low quality perfs, total 75 perfs
# group4: keep first AND second perf per stage, such that perf >=18 and <=80, total 24 perfs
# shots > 80 are not needed for unstimulated FWI
# shots < 18 are not needed for stimulated FWI
# the output of Data_selection.ipynb are listed below
###############################################################################################################

prepare_data: ${D}/ch5_data.H ${D}/ch5_mute.H ${D}/ch5_sources.H ${D}/ch5_sources_s.H ${D}/ch5_data.HH ${D}/ch5_model.H ${D}/ch5_hrz.H ${D}/ch5_mask.H

DATA_G1=./dat/ch5_data0_group1.H
DATA_G2=./dat/ch5_data0_group2.H
DATA_G3=./dat/ch5_data0_group3.H
DATA_G4=./dat/ch5_data0_group4.H
ATTR_G1=./dat/ch5_data0_group1.HH
ATTR_G2=./dat/ch5_data0_group2.HH
ATTR_G3=./dat/ch5_data0_group3.HH
ATTR_G4=./dat/ch5_data0_group4.HH
MUTE_G1=./dat/ch5_mute0_group1.H
MUTE_G2=./dat/ch5_mute0_group2.H
MUTE_G3=./dat/ch5_mute0_group3.H
MUTE_G4=./dat/ch5_mute0_group4.H
SRC_G1=./dat/ch5_sources0_group1.H
SRC_G2=./dat/ch5_sources0_group2.H
SRC_G3=./dat/ch5_sources0_group3.H
SRC_G4=./dat/ch5_sources0_group4.H
SRC_S_G1=./dat/ch5_sources0_group1_s.H
SRC_S_G2=./dat/ch5_sources0_group2_s.H
SRC_S_G3=./dat/ch5_sources0_group3_s.H
SRC_S_G4=./dat/ch5_sources0_group4_s.H

NSRC0_G1=20
NSRC0_G2=20
NSRC0_G3=75
NSRC0_G4=24


###############################################################################################################
# Prepare data and synthetic from group4 to conduct the AVO estimation
# drop |offsets| > 650 m
###############################################################################################################

# band pass filter, scale the filter so that its amplitude spectrum peaks at 1
${D}/ch5_bp.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=75 dt=0.002 type=butterworth low_cutoff=0.12 high_cutoff=0.6 half_order=1 phase=zero datapath=${OUT} > temp.H
	${B}/FX_FILTER.x < temp.H filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | Scale dscale=1.12197 datapath=${OUT} > $@
	${Rm} temp.H

${D}/ch5_data_group4.H.bp: ${D}/ch5_bp.H
	Window < ${DATA_G4} f2=150 n2=1301 | ${B}/FX_FILTER.x filter=$(word 1,$^) datapath=${OUT} > $@

${D}/ch5_mute_group4.H.select:
	Window < ${MUTE_G4} f2=150 n2=1301 datapath=${OUT} > $@

# coordinates
${D}/ch5_srcoord_group4.txt:
	${Rm} sid.H sx.H sz.H rx.H rz.H rdip.H srcoord.H
	Window < ${ATTR_G4} f2=150 n2=1301 n1=1 f1=0 datapath=${OUT} > sid.H
	Window < ${ATTR_G4} f2=150 n2=1301 n1=1 f1=16 | Scale dscale=1e-5 datapath=${OUT} > rx.H
	Window < ${ATTR_G4} f2=150 n2=1301 n1=1 f1=18 | Scale dscale=1e-5 datapath=${OUT} > rz.H
	Window < ${ATTR_G4} f2=150 n2=1301 n1=1 f1=19 | Scale dscale=1e-5 datapath=${OUT} > sx.H
	Window < ${ATTR_G4} f2=150 n2=1301 n1=1 f1=21 | Scale dscale=1e-5 datapath=${OUT} > sz.H
	Window < ${ATTR_G4} f2=150 n2=1301 n1=1 f1=24 datapath=${OUT} > rdip.H
	echo n1=1 n2=1301 n3=24 >> sid.H
	echo n1=1 n2=1301 n3=24 >> sx.H
	echo n1=1 n2=1301 n3=24 >> sz.H
	echo n1=1 n2=1301 n3=24 >> rx.H
	echo n1=1 n2=1301 n3=24 >> rz.H
	echo n1=1 n2=1301 n3=24 >> rdip.H
	Cat sid.H sx.H sz.H rx.H rz.H rdip.H axis=1 datapath=${OUT} > srcoord.H
	python3 ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sz.H rx.H rz.H rdip.H srcoord.H

${D}/ch5_syn_group4.H: ${D}/ch5_model.H ${D}/ch5_srcoord_group4.txt
	${BG}/WE_MODELING.x source=${SRC_G4} model=$(word 1, $^) srcoord=$(word 2, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_strength=0.02 \
	device=0
	echo o2=-650 n2=1301 d2=1 n3=24 o3=0 d3=1 >> $@

${D}/ch5_syn_group4.H.bp: ${D}/ch5_syn_group4.H ${D}/ch5_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@


###############################################################################################################
# generate 3D synthetic data for shot 49 using a flat model (with gamma=0)
###############################################################################################################

# coordinates
${D}/ch5_srcoord_3d_sp49.txt:
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H srcoord.H
	Window < ${ATTR} n3=1 f3=49 f2=150 n2=1301 n1=1 f1=0 datapath=${OUT} > sid.H
	Window < ${ATTR} n3=1 f3=49 f2=150 n2=1301 n1=1 f1=16 | Scale dscale=1e-5 datapath=${OUT} > rx.H
	Window < ${ATTR} n3=1 f3=49 f2=150 n2=1301 n1=1 f1=16 | Scale dscale=0.00 datapath=${OUT} > ry.H
	Window < ${ATTR} n3=1 f3=49 f2=150 n2=1301 n1=1 f1=18 | Scale dscale=1e-5 datapath=${OUT} > rz.H
	Window < ${ATTR} n3=1 f3=49 f2=150 n2=1301 n1=1 f1=19 | Scale dscale=1e-5 datapath=${OUT} > sx.H
	Window < ${ATTR} n3=1 f3=49 f2=150 n2=1301 n1=1 f1=19 | Scale dscale=0.00 datapath=${OUT} > sy.H
	Window < ${ATTR} n3=1 f3=49 f2=150 n2=1301 n1=1 f1=21 | Scale dscale=1e-5 datapath=${OUT} > sz.H
	Window < ${ATTR} n3=1 f3=49 f2=150 n2=1301 n1=1 f1=24 datapath=${OUT} > rdip.H
	Window < ${ATTR} n3=1 f3=49 f2=150 n2=1301 n1=1 f1=24 | Scale dscale=0.00 datapath=${OUT} > raz.H
	echo n1=1 n2=1301 n3=1 >> sid.H
	echo n1=1 n2=1301 n3=1 >> sx.H
	echo n1=1 n2=1301 n3=1 >> sy.H
	echo n1=1 n2=1301 n3=1 >> sz.H
	echo n1=1 n2=1301 n3=1 >> rx.H
	echo n1=1 n2=1301 n3=1 >> ry.H
	echo n1=1 n2=1301 n3=1 >> rz.H
	echo n1=1 n2=1301 n3=1 >> rdip.H
	echo n1=1 n2=1301 n3=1 >> raz.H
	Cat sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H axis=1 datapath=${OUT} > srcoord.H
	python3 ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H srcoord.H

${D}/ch5_source_3d_sp49.H: ${D}/ch5_sources.H
	${Rm} mxx.H myy.H mzz.H
	Window < $< n2=1 f2=49 | Window n2=1 f2=0 datapath=${OUT} > mxx.H
	Window < $< n2=1 f2=49 | Window n2=1 f2=0 | Scale dscale=0 datapath=${OUT} > myy.H
	Window < $< n2=1 f2=49 | Window n2=1 f2=1 datapath=${OUT} > mzz.H
	Cat mxx.H myy.H mzz.H axis=2 | Pad end2=3 datapath=${OUT} > $@
	${Rm} mxx.H myy.H mzz.H

${D}/ch5_model_3d_flat.H: ${D}/ch5_model.H
	Pad < $< beg4=100 end4=100 extend=1 | Transp plane=34 | Pad end4=1 datapath=${OUT} > $@
	echo o3=-0.2 d3=0.002 >> $@

${D}/ch5_syn_3d_sp49.H: ${D}/ch5_source_3d_sp49.H ${D}/ch5_model_3d_flat.H ${D}/ch5_srcoord_3d_sp49.txt
	${B}/WE_MODELING_3D.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 courant=0.55 dt=0 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=80 taper_back=80 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.05
	echo o2=-650 n2=1301 d2=1 n3=1 o3=0 d3=1 >> $@

# apply Hankel filter sqrt(2.pi.sigma/t)H(t) to correct for 2D-3D wavelet effects (Auer et al., 2013)
# sigma=cr=4.5 km/s * 0.2 km
${D}/ch5_hankel.H:
	${B}/GENERATE_WAVELET.x nt=302 dt=0.002 type=power pow=-0.5 | Scale dscale=2.378 | Scale dscale=0.002 | Window f1=1 | Pad beg1=300 extend=0 datapath=${OUT} > $@
	echo o1=-0.6 >> $@

${D}/ch5_syn_3d_sp49.H.hankel: ${D}/ch5_syn_3d_sp49.H ${D}/ch5_hankel.H
	${B}/FX_FILTER.x < $< filter=$(word 2, $^) datapath=${OUT} > $@

${D}/ch5_syn_3d_sp49.H.hankel.bp: ${D}/ch5_syn_3d_sp49.H.hankel ${D}/ch5_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

###############################################################################################################
# The outputs above are used in AVO_estimation.ipynb for AVO estimation
# the output of AVO_estimation.ipynb are listed below
###############################################################################################################

prepare_avo: ${D}/ch5_data_group4.H.bp ${D}/ch5_mute_group4.H.select ${D}/ch5_syn_group4.H.bp ${D}/ch5_syn_3d_sp49.H.hankel.bp

AVO_WEIGHTS=./dat/ch5_avo_weights.H


###############################################################################################################
# FWI runs
###############################################################################################################

include fwi_synthetic.mk
include fwi_unstimulated.mk
include fwi_stimulated.mk

###############################################################################################################
# Default make rules
###############################################################################################################

burn:
	rm -f ${F}/*

clean:
	rm -f ${F}/*
	${Rm} -f ${D}/*.H*
	rm -f ${D}/*