# Moment tensor inversion for the monitor well
# Results used in the Geophysics paper 2023
##### Preparations #####
# 'make all' will do all preparations ; then run the notebooks

F = fig
D = dat
B=${PWD}/../../code/local/bin
BG=${PWD}/../../code/local_gpu/bin
P=${PWD}/../../code/python
OUT=${PWD}/dat/

# Rm = python2.7 /opt/SEP/SEP7.0/bin/Rm
Rm = python3 ${PWD}/../../code/local/bin/remove.py

###############################################################################################################
# Inputs
###############################################################################################################

# Raw DAS data
DATA=${PWD}/../../input_data/das/monitor_data.H
# Mask
MASK=${PWD}/../../input_data/das/monitor_mask.H
# Header attributes
ATTR=${PWD}/../../input_data/das/monitor_headers.H
# raw well logs
LOGS=${PWD}/../ch0/dat

###############################################################################################################
# Coordinates (rotated) in km and attributes
###############################################################################################################

# true locations for all shots and channels
${D}/ch4_srcoord.txt:
	${Rm} sid.H sx.H sz.H rx.H rz.H rdip.H srcoord.H
	Window < ${ATTR} n1=1 f1=0 datapath=${OUT} > sid.H
	Window < ${ATTR} n1=1 f1=16 | Scale dscale=1e-5 datapath=${OUT} > rx.H
	Window < ${ATTR} n1=1 f1=18 | Scale dscale=1e-5 datapath=${OUT} > rz.H
	Window < ${ATTR} n1=1 f1=19 | Scale dscale=1e-5 datapath=${OUT} > sx.H
	Window < ${ATTR} n1=1 f1=21 | Scale dscale=1e-5 datapath=${OUT} > sz.H
	Window < ${ATTR} n1=1 f1=24 datapath=${OUT} > rdip.H
	echo n1=1 n2=1601 n3=100 >> sid.H
	echo n1=1 n2=1601 n3=100 >> sx.H
	echo n1=1 n2=1601 n3=100 >> sz.H
	echo n1=1 n2=1601 n3=100 >> rx.H
	echo n1=1 n2=1601 n3=100 >> rz.H
	echo n1=1 n2=1601 n3=100 >> rdip.H
	Cat sid.H sx.H sz.H rx.H rz.H rdip.H axis=1 datapath=${OUT} > srcoord.H
	python ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sz.H rx.H rz.H rdip.H srcoord.H

# true locations for one shot and limited offsets
${D}/ch4_srcoord_sp49.txt:
	${Rm} sid.H sx.H sz.H rx.H rz.H rdip.H srcoord.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=0 datapath=${OUT} > sid.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=16 | Scale dscale=1e-5 datapath=${OUT} > rx.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=18 | Scale dscale=1e-5 datapath=${OUT} > rz.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=19 | Scale dscale=1e-5 datapath=${OUT} > sx.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=21 | Scale dscale=1e-5 datapath=${OUT} > sz.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=24 datapath=${OUT} > rdip.H
	echo n1=1 n2=451 n3=1 >> sid.H
	echo n1=1 n2=451 n3=1 >> sx.H
	echo n1=1 n2=451 n3=1 >> sz.H
	echo n1=1 n2=451 n3=1 >> rx.H
	echo n1=1 n2=451 n3=1 >> rz.H
	echo n1=1 n2=451 n3=1 >> rdip.H
	Cat sid.H sx.H sz.H rx.H rz.H rdip.H axis=1 datapath=${OUT} > srcoord.H
	python ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sz.H rx.H rz.H rdip.H srcoord.H

# all attributes for shots
${D}/ch4_sattr.txt:
	${Rm} sattr.H
	Window < ${ATTR} n2=1 datapath=${OUT} > sattr.H
	python ${P}/dumpHeader.py --input=sattr.H >> $@
	${Rm} sattr.H

###############################################################################################################
# Build provisional 2D VTI model from well logs
###############################################################################################################

# smooth and resample to 0.5 m the vertical profiles
# also shift vertically to calibrate with the formation bottom horizon
# the shift should be 5.7 m downwards in real coordinates and 4 m downwards in rotated coordinates (here 4 m is used)
.PRECIOUS: ${D}/ch4_offset_%_smth_resamp.H
${D}/ch4_offset_%_smth_resamp.H:
	Smooth < ${LOGS}/ch0_offset_$*.H rect1=5 | Window min1=1692 | ${B}/RESAMPLE.x si=0.5 domain=time type=linear datapath=${OUT} output=$@
	echo o1=1696 >> $@

# build provisional 1D epsilon model from gamma ray ; the bulk shift is chosen so that the values in the basement can be clipped to 0
${D}/ch4_epsilon_1D.H: ${D}/ch4_offset_gamma_smth_resamp.H
	Math file1=$< exp='file1-0.083' | Clip clip=0.083 chop=less to=0 | Smooth rect1=2 repeat=2  datapath=${OUT} > $@

# convert units, and built a provisional flat VTI model with delta=0.5*epsilon
${D}/ch4_elasticModelVTI0_flat.H: ${D}/ch4_offset_vp_smth_resamp.H ${D}/ch4_offset_vs_slow_smth_resamp.H ${D}/ch4_offset_rho_smth_resamp.H ${D}/ch4_epsilon_1D.H
	${Rm} vp.H vs.H rho.H delta.H epsilon.H
	Pad < $(word 1,$^) end2=1 extend=1 | Scale dscale=0.001 datapath=${OUT} > vp.H
	Pad < $(word 2,$^) end2=1 extend=1 | Scale dscale=0.001 datapath=${OUT} > vs.H
	Pad < $(word 3,$^) end2=1 extend=1 | Scale dscale=0.001 datapath=${OUT} > rho.H
	Pad < $(word 4,$^) end2=1 extend=1 | Scale dscale=0.5 datapath=${OUT} > delta.H
	Pad < $(word 4,$^) end2=1 extend=1 | Scale dscale=1.0 datapath=${OUT} > epsilon.H
	Cat vp.H vs.H rho.H delta.H epsilon.H axis=3 | Pad end2=3687 extend=1 datapath=${OUT} > $@
	echo o1=1.696 o2=0.166 d1=0.0005 d2=0.0005 >> $@
	${Rm} vp.H vs.H rho.H delta.H epsilon.H

# convert units for the formation horizon
${D}/ch4_formation_hrz.H:
	Scale < ${LOGS}/ch0_formation_bottom_hrz_rotated.H dscale=0.001 datapath=${OUT} > $@
	echo o1=0.166 d1=0.0005 >> $@

# build a horizon conformal model by running a dummmy 0 iteration 1.5D FWI
${D}/ch4_elasticModelVTI0.H: ${D}/ch4_elasticModelVTI0_flat.H ${D}/ch4_formation_hrz.H
	${Rm} source.H data.H
	Spike n1=2 k1=1 d1=0.002 datapath=${OUT} > source.H
	Spike n1=2 k1=1 d1=0.002 datapath=${OUT} > data.H
	${B}/FWI2D.x source=source.H model=$(word 1, $^) data=data.H horizon=$(word 2, $^) output=$@ datapath=${OUT} format=0 \
	mt=0 seismotype=0 gl=0.01 fmax=250 courant=0.6 dt=0 sub=-1 \
	ns=1 sx0=1 sz0=1.9 nr=1 rx0=1.1 rz0=1.9 \
	vpmin=1 vpmax=9 vsmin=1 vsmax=9 rhomin=1 rhomax=9 soft_clip=0 \
	inversion1d=1 niter=0 verbose=3
	${Rm} source.H data.H

# cut the model above and subsample it to 2 m x 1 m to be used in anisotropy scan
${D}/ch4_elasticModelVTI0.H.cut: ${D}/ch4_elasticModelVTI0.H
	Window < $< min1=1.88 max1=1.98 | Transp plane=12 | ${B}/RESAMPLE.x si=0.002 type=linear | Transp plane=12 | ${B}/RESAMPLE.x si=0.001 type=linear | Pad beg2=83 end2=20 extend=1 datapath=${OUT} > $@
	echo o2=0 >> $@

###############################################################################################################
# Operations on data
###############################################################################################################

# select one shot from raw data for figures
${D}/ch4_das_raw_sp49.H:
	Window < ${DATA} n3=1 f3=49 datapath=${OUT} > $@

# Mute tube waves, apply mild FK-denoising, remove far offsets
${D}/ch4_das_proc_sp49.H: ${D}/ch4_das_raw_sp49.H ${D}/ch4_mute_mask.H
	${Rm} temp.H
	Window < $(word 2,$^) n3=1 f3=49 datapath=${OUT} > temp.H
	Math file1=$< file2=temp.H exp='file1*file2' | ${B}/FK_FILTER.x vmin=500 vmax=99999 | Window min2=-650 max2=650 datapath=${OUT} > $@
	${Rm} temp.H

# Compute FX, FK, and FV spectra
${D}/ch4_das_proc_sp49.H.fx: ${D}/ch4_das_proc_sp49.H
	${B}/FX.x < $< datapath=${OUT} > $@
${D}/ch4_das_proc_sp49.H.fk: ${D}/ch4_das_proc_sp49.H
	${B}/FK.x < $< datapath=${OUT} > $@
${D}/ch4_das_proc_sp49.H.fv: ${D}/ch4_das_proc_sp49.H
	${B}/FV.x < $< vmin=-6500 vmax=6500 nv=201 avmin=500 | Transp datapath=${OUT} > $@

# Mute above
${D}/ch4_mute1.H:
	Math file1=${MASK} exp='0*file1+1' | Mute vmute=6000 tramp=0.001 | Mute vmute=-6000 tramp=0.001 | Window f1=60 | Pad beg1=60 | Smooth rect1=5 repeat=3 datapath=${OUT} > $@
	
# different mute below for two families of shots
${D}/ch4_mute2.H:
	${Rm} temp1.H temp2.H temp.H
	Math file1=${MASK} exp='0*file1+1' | Mute vmute=1525 tramp=0.001 | Window3d n3=25 datapath=${OUT} > temp1.H
	Math file1=${MASK} exp='0*file1+1' | Mute vmute=1495 tramp=0.001 | Window3d f3=25 datapath=${OUT} > temp2.H
	Cat temp1.H temp2.H axis=3 datapath=${OUT} > temp.H 
	Math file1=temp.H exp='1-file1' | Window n1=700 | Smooth rect1=2 repeat=2 datapath=${OUT} > $@
	${Rm} temp1.H temp2.H temp.H

# mute below for positive mid-far offsets (stimulated side)
${D}/ch4_mute3.H:
	${Rm} temp.H
	Math file1=${MASK} exp='0*file1+1' | Mute vmute=1100 tramp=0.001 datapath=${OUT} > temp.H
	Math file1=temp.H exp='1-file1' | Smooth rect1=2 repeat=2 datapath=${OUT} > $@
	${Rm} temp.H

# combine mutes with mask (to be used for stimulated and unstimulated sides)
${D}/ch4_mute_mask.H: ${D}/ch4_mute1.H ${D}/ch4_mute2.H ${D}/ch4_mute3.H
	${Rm} temp1.H temp2.H temp3.H 
	Window n2=940 < $(word 2,$^) | Pad n2out=1601 extend=0 datapath=${OUT} > temp1.H
	Window f2=940 < $(word 3,$^) | Pad beg2=940 extend=0 datapath=${OUT} > temp2.H
	Add temp1.H temp2.H datapath=${OUT} > temp3.H
	Math file1=${MASK} file2=$< file3=temp3.H exp='file1*file2*file3' datapath=${OUT} > $@
	${Rm} temp1.H temp2.H temp3.H

# Convolve data with sqrt(2.pi.sigma/t)H(t) to correct for 2D-3D wavelet effects (Auer et al., 2013)
# sigma=cr=4.5 km/s * 0.2 km
${D}/ch4_hankel.H:
	${B}/GENERATE_WAVELET.x nt=702 dt=0.0005 type=power pow=-0.5 | Scale dscale=2.378 | Scale dscale=0.0005 | Window f1=1 | Pad beg1=700 extend=0 datapath=${OUT} > $@
	echo o1=-0.35 >> $@

# mute + convolution with Hankel function + mild denoising by FK filtering 
${D}/ch4_das.H: ${D}/ch4_mute_mask.H ${D}/ch4_hankel.H
	${Rm} temp1.H temp2.H
	Math file1=${DATA} file2=$(word 1, $^) exp='file1*file2' datapath=${OUT} > temp1.H
	${B}/FX_FILTER.x < temp1.H filter=$(word 2,$^) datapath=${OUT} > temp2.H
	${B}/FK_FILTER.x < temp2.H vmin=500 vmax=99999  datapath=${OUT} > temp1.H
	Math file1=temp1.H file2=$(word 1, $^) exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp1.H temp2.H

# mute + mild denoising by FK filtering 
${D}/ch4_das_3d.H: ${D}/ch4_mute_mask.H
	${Rm} temp1.H temp2.H
	Math file1=${DATA} file2=$(word 1, $^) exp='file1*file2' datapath=${OUT} > temp2.H
	${B}/FK_FILTER.x < temp2.H vmin=500 vmax=99999  datapath=${OUT} > temp1.H
	Math file1=temp1.H file2=$(word 1, $^) exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp1.H temp2.H

# anti-alias low-pass filter 250 Hz, scale the filter so that its amplitude spectrum peaks at 1
### WARNING: in the original submission of the Geophysics paper, the scaling was based on the SEPlib program Spectra which wasn't giving the correct amplitudes
${D}/ch4_lp250.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=301 dt=0.0005 type=butterworth low_cutoff=0.0 high_cutoff=0.2 half_order=2 phase=zero datapath=${OUT} > temp.H
	${B}/FX_FILTER.x < temp.H filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | Scale dscale=1 datapath=${OUT} > $@
	${Rm} temp.H

# AA-filter and resample to 2 ms and select offsets for unstimulated and stimulated sides
${D}/ch4_das.H.ss: ${D}/ch4_das.H ${D}/ch4_lp250.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) | ${B}/RESAMPLE.x si=0.002 type=sinc sinc_half_length=11 | Window min2=-450 max2=-200 max1=0.3 datapath=${OUT} > $@

${D}/ch4_das.H.sss: ${D}/ch4_das.H ${D}/ch4_lp250.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) | ${B}/RESAMPLE.x si=0.002 type=sinc sinc_half_length=11 | Window min2=100 max2=450 max1=0.3 f3=10 datapath=${OUT} > $@

# same for shot 49 for aisotropy scan
${D}/ch4_das_sp49.H.ss: ${D}/ch4_das.H ${D}/ch4_lp250.H
	Window < $< n3=1 f3=49 min2=-650 max2=-200 max1=0.3 | ${B}/FX_FILTER.x filter=$(word 2,$^) | ${B}/RESAMPLE.x si=0.002 type=sinc sinc_half_length=11 datapath=${OUT} > $@

# resample the mute
${D}/ch4_mute_mask.H.ss: ${D}/ch4_mute_mask.H
	${B}/RESAMPLE.x < $< si=0.002 type=linear | Window min2=-450 max2=-200 max1=0.3 datapath=${OUT} > $@

${D}/ch4_mute_mask.H.sss: ${D}/ch4_mute_mask.H
	${B}/RESAMPLE.x < $< si=0.002 type=linear | Window min2=100 max2=450 max1=0.3 f3=10 datapath=${OUT} > $@

# band pass filter, scale the filter so that its amplitude spectrum peaks at 1
${D}/ch4_bp.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=75 dt=0.002 type=butterworth low_cutoff=0.12 high_cutoff=0.48 half_order=1 phase=zero datapath=${OUT} > temp.H
	${B}/FX_FILTER.x < temp.H filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | Scale dscale=1.280528 datapath=${OUT} > $@
	${Rm} temp.H

${D}/ch4_das.H.ss.bp: ${D}/ch4_das.H.ss ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch4_das.H.sss.bp: ${D}/ch4_das.H.sss ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch4_das_sp49.H.ss.bp: ${D}/ch4_das_sp49.H.ss ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) | Scale datapath=${OUT} > $@

# mute below for shot 49 to keep the strong P-arrival for aisotropy scan
${D}/ch4_mute_sp49.H: ${D}/ch4_das_sp49.H.ss
	${Rm} temp.H
	Math file1=$< exp='0*file1+1' | Mute vmute=2700 tramp=0.01 datapath=${OUT} > temp.H
	Math file1=temp.H exp='1-file1' datapath=${OUT} > $@
	${Rm} temp.H

###############################################################################################################
# Anisotropy scan
###############################################################################################################

# Dirac function
${D}/ch4_dirac.H:
	Spike n1=151 d1=0.002 o1=0 k1=11 nsp=1 mag=500 datapath=${OUT} > $@

# Derivative and filter time functions to QC at far field: this to simulate a 1/2 step function for moment function
${D}/ch4_dirac.H.deriv2.bp: ${D}/ch4_dirac.H ${D}/ch4_bp.H
	Scale < $< dscale=0.5 | ${B}/DERIVATIVE.x | ${B}/DERIVATIVE.x | ${B}/FX_FILTER.x filter=$(word 2, $^) datapath=${OUT} > $@

# Derivative and filter time functions to QC at far field: this to simulate a pulse with 1/2 amplitude for moment function
${D}/ch4_dirac.H.deriv3.bp: ${D}/ch4_dirac.H ${D}/ch4_bp.H
	Scale < $< | Scale dscale=0.5 | ${B}/DERIVATIVE.x | ${B}/DERIVATIVE.x | ${B}/DERIVATIVE.x | ${B}/FX_FILTER.x filter=$(word 2, $^) datapath=${OUT} > $@

# build scaled anisotropy model: eps_scaled = scaler * eps_0
.PRECIOUS: ${D}/ch4_elasticModelVTI0.H.cut.scale%
${D}/ch4_elasticModelVTI0.H.cut.scale%: ${D}/ch4_elasticModelVTI0.H.cut
	${Rm} temp1.H temp2.H temp3.H
	Window < $< n3=3 datapath=${OUT} > temp1.H
	Window < $< n3=1 f3=4 | Scale dscale=$* datapath=${OUT} > temp2.H
	Scale < temp2.H dscale=0.5 datapath=${OUT} > temp3.H
	Cat temp1.H temp3.H temp2.H axis=3 datapath=${OUT} > $@
	${Rm} temp1.H temp2.H temp3.H

# generate DAS data for each scaled model
${D}/ch4_dxGnx_sp49_scale%.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI0.H.cut.scale% ${D}/ch4_srcoord_sp49.txt
	${BG}/WE_MODELING.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) datapath=${OUT} output=$@ \
	verbose=3 fmax=250 mt=1 mxx=1 mzz=1 mxz=0 seismotype=0 gl=0.01 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 \
	device=0
	echo o2=-650 n2=451 d2=1 n3=1 o3=0 d3=1 >> $@

${D}/ch4_dxGnx_sp49_scale_all.H: ${D}/ch4_dxGnx_sp49_scale1.H ${D}/ch4_dxGnx_sp49_scale1.04.H ${D}/ch4_dxGnx_sp49_scale1.08.H ${D}/ch4_dxGnx_sp49_scale1.12.H ${D}/ch4_dxGnx_sp49_scale1.16.H \
${D}/ch4_dxGnx_sp49_scale1.20.H ${D}/ch4_dxGnx_sp49_scale1.24.H ${D}/ch4_dxGnx_sp49_scale1.28.H ${D}/ch4_dxGnx_sp49_scale1.32.H ${D}/ch4_dxGnx_sp49_scale1.36.H ${D}/ch4_dxGnx_sp49_scale1.40.H
	Cat $(word 1, $^) $(word 2, $^) $(word 3, $^) $(word 4, $^) $(word 5, $^) $(word 6, $^) $(word 7, $^) $(word 8, $^) $(word 9, $^) $(word 10, $^) $(word 11, $^) axis=3 datapath=${OUT} > $@

${D}/ch4_dxGnx_sp49_scale_all.H.bp: ${D}/ch4_dxGnx_sp49_scale_all.H ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) | Scale datapath=${OUT} > $@

###############################################################################################################
# Update the VTI model based on the anisotropy scan, and extend the model to generate complete GFs for all perfs
# the optimal scaler is 1.32
###############################################################################################################

${D}/ch4_elasticModelVTI0.H.aniso: ${D}/ch4_elasticModelVTI0.H
	${Rm} vpvsrho.H delta.H epsilon.H
	Window < $< max1=1.98 n3=3 f3=0 datapath=${OUT} > vpvsrho.H
	Window < $< max1=1.98 n3=1 f3=3 | Scale dscale=1.32 datapath=${OUT} > delta.H
	Window < $< max1=1.98 n3=1 f3=4 | Scale dscale=1.32 datapath=${OUT} > epsilon.H
	Cat vpvsrho.H delta.H epsilon.H axis=3 | Transp plane=12 | ${B}/RESAMPLE.x si=0.002 type=linear | Transp plane=12 | ${B}/RESAMPLE.x si=0.001 type=linear | Pad beg2=83 end2=20 beg1=346 extend=1 datapath=${OUT} > $@
	echo o2=0 >> $@
	${Rm} vpvsrho.H delta.H epsilon.H

# Extend and resample the horizon to match the model
${D}/ch4_hrz.H: ${D}/ch4_formation_hrz.H
	${B}/RESAMPLE.x < $< si=0.002 type=linear | Pad beg1=83 end1=20 extend=1 datapath=${OUT} > $@
	echo o1=0 >> $@

# build a horizon conformal model by running a dummmy 0 iteration 1.5D FWI
${D}/ch4_elasticModelVTI1.H: ${D}/ch4_elasticModelVTI0.H.aniso ${D}/ch4_hrz.H
	${Rm} source.H data.H
	Spike n1=2 k1=1 d1=0.002 datapath=${OUT} > source.H
	Spike n1=2 k1=1 d1=0.002 datapath=${OUT} > data.H
	${B}/FWI2D.x source=source.H model=$(word 1, $^) data=data.H horizon=$(word 2, $^) output=$@ datapath=${OUT} format=0 \
	mt=0 seismotype=0 gl=0.01 fmax=250 courant=0.6 dt=0 sub=-1 \
	ns=1 sx0=1 sz0=1.9 nr=1 rx0=1.1 rz0=1.9 \
	vpmin=1 vpmax=9 vsmin=1 vsmax=9 rhomin=1 rhomax=9 soft_clip=0 \
	inversion1d=1 niter=0 verbose=3
	${Rm} source.H data.H

###############################################################################################################
# Generate all Green's functions using Dirac moment rate function but keeping seismotype=0
###############################################################################################################

# Green's functions dxGnx
${D}/ch4_dxGnx.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI1.H ${D}/ch4_srcoord.txt
	${BG}/WE_MODELING.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 fmax=250 mt=1 mxx=1 mzz=0 mxz=0 seismotype=0 gl=0.01 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 \
	device=0 2> $@.log
	echo o2=-800 n2=1601 d2=1 n3=100 o3=0 d3=1 >> $@

# Green's functions dzGnz
${D}/ch4_dzGnz.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI1.H ${D}/ch4_srcoord.txt
	${BG}/WE_MODELING.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 fmax=250 mt=1 mxx=0 mzz=1 mxz=0 seismotype=0 gl=0.01 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 \
	device=1 2> $@.log
	echo o2=-800 n2=1601 d2=1 n3=100 o3=0 d3=1 >> $@

# Green's functions dxGnz
${D}/ch4_dxGnz.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI1.H ${D}/ch4_srcoord.txt
	${BG}/WE_MODELING.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 fmax=250 mt=1 mxx=0 mzz=0 mxz=1 seismotype=0 gl=0.01 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 \
	device=2 2> $@.log
	echo o2=-800 n2=1601 d2=1 n3=100 o3=0 d3=1 >> $@

###############################################################################################################
# Operations on GF's
###############################################################################################################

# for unstimulated side
${D}/ch4_dxGnx.H.ss: ${D}/ch4_dxGnx.H ${D}/ch4_mute_mask.H.ss
	${Rm} temp.H
	Window min2=-450 max2=-200 max1=0.3 < $< datapath=${OUT} > temp.H
	Math file1=temp.H file2=$(word 2, $^) exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp.H

${D}/ch4_dzGnz.H.ss: ${D}/ch4_dzGnz.H ${D}/ch4_mute_mask.H.ss
	${Rm} temp.H
	Window min2=-450 max2=-200 max1=0.3 < $< datapath=${OUT} > temp.H
	Math file1=temp.H file2=$(word 2, $^) exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp.H

${D}/ch4_dxGnz.H.ss: ${D}/ch4_dxGnz.H ${D}/ch4_mute_mask.H.ss
	${Rm} temp.H
	Window min2=-450 max2=-200 max1=0.3 < $< datapath=${OUT} > temp.H
	Math file1=temp.H file2=$(word 2, $^) exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp.H

${D}/ch4_dxGnx.H.ss.bp: ${D}/ch4_dxGnx.H.ss ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch4_dzGnz.H.ss.bp: ${D}/ch4_dzGnz.H.ss ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch4_dxGnz.H.ss.bp: ${D}/ch4_dxGnz.H.ss ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

# for stimulated side
${D}/ch4_dxGnx.H.sss: ${D}/ch4_dxGnx.H ${D}/ch4_mute_mask.H.sss
	${Rm} temp.H
	Window min2=100 max2=450 max1=0.3 f3=10 < $< datapath=${OUT} > temp.H
	Math file1=temp.H file2=$(word 2, $^) exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp.H

${D}/ch4_dzGnz.H.sss: ${D}/ch4_dzGnz.H ${D}/ch4_mute_mask.H.sss
	${Rm} temp.H
	Window min2=100 max2=450 max1=0.3 f3=10 < $< datapath=${OUT} > temp.H
	Math file1=temp.H file2=$(word 2, $^) exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp.H

${D}/ch4_dxGnz.H.sss: ${D}/ch4_dxGnz.H ${D}/ch4_mute_mask.H.sss
	${Rm} temp.H
	Window min2=100 max2=450 max1=0.3 f3=10 < $< datapath=${OUT} > temp.H
	Math file1=temp.H file2=$(word 2, $^) exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp.H

${D}/ch4_dxGnx.H.sss.bp: ${D}/ch4_dxGnx.H.sss ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch4_dzGnz.H.sss.bp: ${D}/ch4_dzGnz.H.sss ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch4_dxGnz.H.sss.bp: ${D}/ch4_dxGnz.H.sss ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

###############################################################################################################
# generate 2D GFs for shot 49 using a homogeneous model deeper than the original one (to reduce bottom boundary reflections)
# OBSERVATIONS: The mid-field dzGnz contains both P and S waves in the x-direction, which are smaller but comparable to the dxGnx far-field contribution to P wave
# Similarily, the mid-field dxGnx contains S wave in the x-direction. Thus, even in a homogeneous model, the Mzz component of the MT is resolvable thanks to the
# mid-field contribution. Note that the near-field contributions are negligible in this configuration, but they make the S wave dimmer at near offsets and low frequency
###############################################################################################################

${D}/ch4_elasticModelVTI_homo.H: ${D}/ch4_elasticModelVTI1.H
	${Rm} temp.H vp.H vs.H rho.H del.H eps.H
	Window n3=1 f3=0 < $< datapath=${OUT} > temp.H
	Math file1=temp.H exp='0*file1+2.8' datapath=${OUT} > vp.H
	Math file1=temp.H exp='0*file1+1.7' datapath=${OUT} > vs.H
	Math file1=temp.H exp='0*file1+2.3' datapath=${OUT} > rho.H
	Math file1=temp.H exp='0*file1+0.325' datapath=${OUT} > del.H
	Math file1=temp.H exp='0*file1+0.65' datapath=${OUT} > eps.H
	Cat vp.H vs.H rho.H del.H eps.H axis=3 | Pad end1=300 extend=1 datapath=${OUT} > $@
	${Rm} temp.H vp.H vs.H rho.H del.H eps.H

${D}/ch4_dxGnx_homo_sp49.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI_homo.H ${D}/ch4_srcoord_sp49.txt
	${BG}/WE_MODELING.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} \
	verbose=3 fmax=250 mt=1 mxx=1 mzz=0 mxz=0 seismotype=0 gl=0.01 taper_top=30 taper_bottom=300 taper_left=30 taper_right=30 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 \
	device=1
	echo o2=-650 n2=451 d2=1 n3=1 o3=0 d3=1 >> $@

${D}/ch4_dzGnz_homo_sp49.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI_homo.H ${D}/ch4_srcoord_sp49.txt
	${BG}/WE_MODELING.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} \
	verbose=3 fmax=250 mt=1 mxx=0 mzz=1 mxz=0 seismotype=0 gl=0.01 taper_top=30 taper_bottom=300 taper_left=30 taper_right=30 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 \
	device=2
	echo o2=-650 n2=451 d2=1 n3=1 o3=0 d3=1 >> $@

${D}/ch4_dxGnx_homo_sp49.H.bp: ${D}/ch4_dxGnx_homo_sp49.H ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch4_dzGnz_homo_sp49.H.bp: ${D}/ch4_dzGnz_homo_sp49.H ${D}/ch4_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

###############################################################################################################
# generate 3D GFs for shot 49 using a flat model (with gamma=0.7*epsilon)
###############################################################################################################

${D}/ch4_srcoord_3d_sp49.txt:
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H srcoord.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=0 datapath=${OUT} > sid.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=16 | Scale dscale=1e-5 datapath=${OUT} > rx.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=16 | Scale dscale=0.00 datapath=${OUT} > ry.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=18 | Scale dscale=1e-5 datapath=${OUT} > rz.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=19 | Scale dscale=1e-5 datapath=${OUT} > sx.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=19 | Scale dscale=0.00 datapath=${OUT} > sy.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=21 | Scale dscale=1e-5 datapath=${OUT} > sz.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=24 datapath=${OUT} > rdip.H
	Window < ${ATTR} n3=1 f3=49 min2=-650 max2=-200 n1=1 f1=24 | Scale dscale=0.00 datapath=${OUT} > raz.H
	echo n1=1 n2=451 n3=1 >> sid.H
	echo n1=1 n2=451 n3=1 >> sx.H
	echo n1=1 n2=451 n3=1 >> sy.H
	echo n1=1 n2=451 n3=1 >> sz.H
	echo n1=1 n2=451 n3=1 >> rx.H
	echo n1=1 n2=451 n3=1 >> ry.H
	echo n1=1 n2=451 n3=1 >> rz.H
	echo n1=1 n2=451 n3=1 >> rdip.H
	echo n1=1 n2=451 n3=1 >> raz.H
	Cat sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H axis=1 datapath=${OUT} > srcoord.H
	python ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H srcoord.H

${D}/ch4_elasticModelVTI1_3d_flat.H: ${D}/ch4_elasticModelVTI1.H
	${Rm} gamma.H
	Window < $< n3=1 f3=4 | Scale dscale=0.7 datapath=${OUT} > gamma.H
	Cat $< gamma.H axis=3 | Window min1=1.85 | Pad beg4=125 end4=125 extend=1 | Transp plane=34 maxsize=2500 datapath=${OUT} > $@
	echo o3=-0.25 d3=0.002 >> $@
	${Rm} gamma.H

# model with gamma=0
${D}/ch4_elasticModelVTI1_3d_flat2.H: ${D}/ch4_elasticModelVTI1.H
	${Rm} gamma.H
	Window < $< n3=1 f3=4 | Scale dscale=0. datapath=${OUT} > gamma.H
	Cat $< gamma.H axis=3 | Window min1=1.85 | Pad beg4=125 end4=125 extend=1 | Transp plane=34 maxsize=2500 datapath=${OUT} > $@
	echo o3=-0.25 d3=0.002 >> $@
	${Rm} gamma.H

# model with gamma=0 and wider in y-direction
${D}/ch4_elasticModelVTI1_3d_flat3.H: ${D}/ch4_elasticModelVTI1_3d_flat2.H
	Pad < $< beg3=50 end3=50 extend=1 datapath=${OUT} > $@

${D}/ch4_dxGnx_3d_sp49.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI1_3d_flat.H ${D}/ch4_srcoord_3d_sp49.txt
	${B}/WE_MODELING_3D.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 courant=0.55 mxx=1 myy=0 mzz=0 mxy=0 mxz=0 myz=0 \
	taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_front=50 taper_back=50 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1
	echo o2=-650 n2=451 d2=1 n3=1 o3=0 d3=1 >> $@

${D}/ch4_dyGny_3d_sp49.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI1_3d_flat.H ${D}/ch4_srcoord_3d_sp49.txt
	${B}/WE_MODELING_3D.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 courant=0.55 mxx=0 myy=1 mzz=0 mxy=0 mxz=0 myz=0 \
	taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_front=50 taper_back=50 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1
	echo o2=-650 n2=451 d2=1 n3=1 o3=0 d3=1 >> $@

${D}/ch4_dzGnz_3d_sp49.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI1_3d_flat.H ${D}/ch4_srcoord_3d_sp49.txt
	${B}/WE_MODELING_3D.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 courant=0.55 mxx=0 myy=0 mzz=1 mxy=0 mxz=0 myz=0 \
	taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_front=50 taper_back=50 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1
	echo o2=-650 n2=451 d2=1 n3=1 o3=0 d3=1 >> $@

${D}/ch4_dxGnx_3d2_sp49.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI1_3d_flat2.H ${D}/ch4_srcoord_3d_sp49.txt
	${B}/WE_MODELING_3D.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 courant=0.55 mxx=1 myy=0 mzz=0 mxy=0 mxz=0 myz=0 \
	taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_front=50 taper_back=50 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1
	echo o2=-650 n2=451 d2=1 n3=1 o3=0 d3=1 >> $@

# line receivers in the y-direction at x-offset -400 m
${D}/ch4_dxGnx_3d3_sp49.H: ${D}/ch4_dirac.H ${D}/ch4_elasticModelVTI1_3d_flat3.H
	${B}/WE_MODELING_3D.x source=$(word 1, $^) model=$(word 2, $^) output=$@ datapath=${OUT} verbose=3 \
	sx0=1.20065 sy0=0 sz0=1.94277 ns=1 rx0=0.79461 ry0=-0.1 rz0=1.94390 rdip0=0.01329 ryinc=0.002 nr=101 \
	mt=1 fmax=250 seismotype=0 gl=0.01 courant=0.55 mxx=1 myy=0 mzz=0 mxy=0 mxz=0 myz=0 \
	taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_front=50 taper_back=50 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1
	echo o2=-100 n2=101 d2=1 n3=1 o3=0 d3=1 >> $@

# Convolve GF with sqrt(2.pi.sigma/t)H(t) to correct for 2D-3D wavelet effects (Auer et al., 2013)
# sigma=cr=4.5 km/s * 0.2 km
# The purpose from applying this filter here is to adjust (partially) the amplitudes and kinematics before 3D MT inversion so the latter
# can be compared with the "pure" 2D MT inversion
${D}/ch4_hankel_ss.H:
	${B}/GENERATE_WAVELET.x nt=302 dt=0.002 type=power pow=-0.5 | Scale dscale=2.378 | Scale dscale=0.002 | Window f1=1 | Pad beg1=300 extend=0 datapath=${OUT} > $@
	echo o1=-0.6 >> $@

${D}/ch4_dxGnx_3d_sp49.H.hankel: ${D}/ch4_dxGnx_3d_sp49.H ${D}/ch4_hankel_ss.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@
${D}/ch4_dyGny_3d_sp49.H.hankel: ${D}/ch4_dyGny_3d_sp49.H ${D}/ch4_hankel_ss.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@
${D}/ch4_dzGnz_3d_sp49.H.hankel: ${D}/ch4_dzGnz_3d_sp49.H ${D}/ch4_hankel_ss.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@
${D}/ch4_dxGnx_3d2_sp49.H.hankel: ${D}/ch4_dxGnx_3d2_sp49.H ${D}/ch4_hankel_ss.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@
	
# Operations on GF's as in the 2D case
${D}/ch4_dxGnx_3d_sp49.H.ss.bp: ${D}/ch4_dxGnx_3d_sp49.H.hankel ${D}/ch4_mute_mask.H.ss ${D}/ch4_bp.H
	${Rm} temp1.H temp2.H
	Window min2=-450 max2=-200 max1=0.3 < $< datapath=${OUT} > temp1.H
	Window min2=-450 max2=-200 max1=0.3 n3=1 f3=49 < $(word 2, $^) datapath=${OUT} > temp2.H
	Math file1=temp1.H file2=temp2.H exp='file1*file2' |  ${B}/FX_FILTER.x filter=$(word 3,$^) datapath=${OUT} > $@
	${Rm} temp1.H temp2.H

${D}/ch4_dyGny_3d_sp49.H.ss.bp: ${D}/ch4_dyGny_3d_sp49.H.hankel ${D}/ch4_mute_mask.H.ss ${D}/ch4_bp.H
	${Rm} temp1.H temp2.H
	Window min2=-450 max2=-200 max1=0.3 < $< datapath=${OUT} > temp1.H
	Window min2=-450 max2=-200 max1=0.3 n3=1 f3=49 < $(word 2, $^) datapath=${OUT} > temp2.H
	Math file1=temp1.H file2=temp2.H exp='file1*file2' |  ${B}/FX_FILTER.x filter=$(word 3,$^) datapath=${OUT} > $@
	${Rm} temp1.H temp2.H

${D}/ch4_dzGnz_3d_sp49.H.ss.bp: ${D}/ch4_dzGnz_3d_sp49.H.hankel ${D}/ch4_mute_mask.H.ss ${D}/ch4_bp.H
	${Rm} temp1.H temp2.H
	Window min2=-450 max2=-200 max1=0.3 < $< datapath=${OUT} > temp1.H
	Window min2=-450 max2=-200 max1=0.3 n3=1 f3=49 < $(word 2, $^) datapath=${OUT} > temp2.H
	Math file1=temp1.H file2=temp2.H exp='file1*file2' |  ${B}/FX_FILTER.x filter=$(word 3,$^) datapath=${OUT} > $@
	${Rm} temp1.H temp2.H

${D}/ch4_dxGnx_3d2_sp49.H.ss.bp: ${D}/ch4_dxGnx_3d2_sp49.H.hankel ${D}/ch4_mute_mask.H.ss ${D}/ch4_bp.H
	${Rm} temp1.H temp2.H
	Window min2=-450 max2=-200 max1=0.3 < $< datapath=${OUT} > temp1.H
	Window min2=-450 max2=-200 max1=0.3 n3=1 f3=49 < $(word 2, $^) datapath=${OUT} > temp2.H
	Math file1=temp1.H file2=temp2.H exp='file1*file2' |  ${B}/FX_FILTER.x filter=$(word 3,$^) datapath=${OUT} > $@
	${Rm} temp1.H temp2.H

###############################################################################################################
# The outputs above are used in MT_inversion_unstimulated.ipynb and MT_inversion_stimulated.ipynb for MT inversion
###############################################################################################################

all: ${D}/ch4_das.H.ss.bp ${D}/ch4_mute_mask.H.ss ${D}/ch4_dxGnx.H.ss.bp ${D}/ch4_dzGnz.H.ss.bp ${D}/ch4_dxGnz.H.ss.bp ${D}/ch4_sattr.txt \
${D}/ch4_das.H.sss.bp ${D}/ch4_mute_mask.H.sss ${D}/ch4_dxGnx.H.sss.bp ${D}/ch4_dzGnz.H.sss.bp ${D}/ch4_dxGnz.H.sss.bp \
${D}/ch4_das_raw_sp49.H ${D}/ch4_das_proc_sp49.H ${D}/ch4_das_proc_sp49.H.fx ${D}/ch4_das_proc_sp49.H.fk ${D}/ch4_das_proc_sp49.H.fv \
${D}/ch4_dirac.H.deriv2.bp ${D}/ch4_dirac.H.deriv3.bp ${D}/ch4_das_3d.H \
${D}/ch4_dxGnx_3d_sp49.H.ss.bp ${D}/ch4_dyGny_3d_sp49.H.ss.bp ${D}/ch4_dzGnz_3d_sp49.H.ss.bp

###############################################################################################################
# Default make rules
###############################################################################################################

burn:
	rm -f ${F}/*

clean:
	rm -f ${F}/*
	${Rm} -f ${D}/*.H*
	rm -f ${D}/*
