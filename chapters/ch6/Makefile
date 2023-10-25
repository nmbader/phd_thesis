# 3D MT inversion and FWI for the offset Western well
##### Preparations #####
# Run Model_build_3d notebook
# Run 'make all_prep' to prepare some data
# Run section "Vs0 and Anisotropy scan" with the corresponding notebook Model_scan to calibrate the VTI model
# Then 'make all_gf' will generate 6 3D Green's functions for the source inversion ; each will take ~ 12h on 24 cores machine
##### 3D MT inversion #####
# Then run MT_inversion notebook to invert the 3D MTs
# Then run Data_selection notebook to prepare data for FWI
##### Pre-stimulation FWI #####
# run 'make sensitivity_analysis'
# run 'make unstimulated'
# run 'make stimulated'
# run the notebook Model_QCs


F = fig
D = dat
B=${PWD}/../../code/local/bin
BG=${PWD}/../../code/local_gpu/bin
P=${PWD}/../../code/python
OUT=${PWD}/dat/

#SRUN_MODELING1=srun --mpi=pmi2 --job-name=modeling3d --time=01:00:00 --ntasks=1 --nodes=1 --ntasks-per-node=1 --cpus-per-task=12 --partition=serc,normal --output=slurm/slurm-%j.out
SRUN_MODELING1=srun --mpi=pmi2 --job-name=modeling3d --time=01:00:00 --ntasks=1 --nodes=1 --ntasks-per-node=1 --cpus-per-task=12 --partition=serc,normal
SRUN_MODELING11=srun --mpi=pmi2 --job-name=modeling3d --time=04:00:00 --ntasks=11 --nodes=11 --ntasks-per-node=1 --cpus-per-task=12 --partition=serc,normal
SRUN_MODELING11b=srun --mpi=pmi2 --job-name=modeling3d --time=01:30:00 --ntasks=11 --nodes=11 --ntasks-per-node=1 --cpus-per-task=12 --partition=serc,normal
SRUN_FWI3D=srun --mpi=pmi2 --job-name=fwi3d --time=48:00:00 --ntasks=11 --nodes=11 --ntasks-per-node=1 --cpus-per-task=24 --mem=72G --partition=serc,normal

# Rm = python2.7 /opt/SEP/SEP7.0/bin/Rm
Rm = python3 ${PWD}/../../code/local/bin/remove.py
# Rm = In $< | grep in= | cut -d"=" -f2 | rm

###############################################################################################################
# Inputs (the horizon and VTI model are generated in model_build_3d.ipynb)
###############################################################################################################

# Raw DAS data
DATA=${PWD}/../../input_data/das/west_data.H
# Mask
MASK=${PWD}/../../input_data/das/west_mask.H
# Header attributes
ATTR=${PWD}/../../input_data/das/west_headers.H
# Reservoir horizon
HRZ=${PWD}/../ch6/dat/ch6_hrz2d.H
# VTI model
MODEL=${PWD}/../ch6/dat/ch6_model3d.H

###############################################################################################################
# Operations on data
###############################################################################################################

# P to SH difference t_SH - t_P ~ 44 ms at offsetx = 0 ; offsety ~ 300 m ;
# t_SH - t_P = d/Vp(Vp/Vs - 1)
# Vp = Vp0 sqrt(1 + 2.eps)
# Vsh = Vs0 sqrt(1 + 2.gamma)
# weak SV can be observed on a handful of shots arriving later than SH as expected
# t_SV - t_SH = d/Vs0 (1 - 1 / sqrt(1 + 2.gamma) )
# t_SV - t_SH ~ 62 ms at offsetx = 200 m; this leads to gamma ~ 0.5 for Vs0 = 1.7 km/s

# anti-alias low-pass ${B}/FX_FILTER.x 250 Hz, scale the ${B}/FX_FILTER.x so that its amplitude spectrum peaks at 1
${D}/ch6_lp250.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=301 dt=0.0005 type=butterworth low_cutoff=0.0 high_cutoff=0.2 half_order=2 phase=zero datapath=${OUT} > temp.H
	${B}/FX_FILTER.x < temp.H filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | Scale dscale=1 datapath=${OUT} > $@
	${Rm} temp.H

# AA-filter, resample to 2 ms, denoising by FK-filtering, remove far offsets and later time, shift 84 ms and apply smooth taper
${D}/ch6_data.H: ${D}/ch6_lp250.H
	${Rm} temp1.H temp2.H
	${B}/FX_FILTER.x < ${DATA} filter=$(word 1,$^) | ${B}/RESAMPLE.x si=0.002 type=sinc sinc_half_length=11 | ${B}/FK_FILTER.x vmin=1000 vmax=99999 |  Pad beg1=42 | Window min2=-600 max2=600.9 n1=175 datapath=${OUT} > temp1.H
	Vel n1=175 n2=1201 n3=41 d1=1 d2=1 d3=1 z1=43 const1=1 vr1=1 vc=0 | Smooth rect1=2 repeat=3 datapath=${OUT} > temp2.H
	Math file1=temp1.H file2=temp2.H exp='file1*file2' datapath=${OUT} > $@
	echo o1=0 >> $@
	${Rm} temp1.H temp2.H

# update the mask/mute and attributes
${D}/ch6_mute.H:
	${B}/RESAMPLE.x < ${MASK} si=0.002 type=linear | Pad beg1=42 | Window min2=-600 max2=600.9 n1=175 datapath=${OUT} > $@

${D}/ch6_data.HH:
	Window < ${ATTR} min2=-600 max2=600.9 datapath=${OUT} > $@

# band pass filter, scale the ${B}/FX_FILTER.x so that its amplitude spectrum peaks at 1
${D}/ch6_bp.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=75 dt=0.002 type=butterworth low_cutoff=0.12 high_cutoff=0.48 half_order=1 phase=zero datapath=${OUT} > temp.H
	${B}/FX_FILTER.x < temp.H filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | Scale dscale=1.17927 datapath=${OUT} > $@
	${Rm} temp.H

${D}/ch6_data.H.bp: ${D}/ch6_data.H ${D}/ch6_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

###############################################################################################################
# Coordinates
###############################################################################################################

# true locations for all shots and channels, recompute DAS dip and azimuth
# ${D}/ch6_srcoord.txt: ${D}/ch6_data.HH
${D}/ch6_srcoord.txt:
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H rx_p1.H rx_m1.H ry_p1.H ry_m1.H rz_p1.H rz_m1.H srcoord.H
	Window < $< n1=1 f1=2 datapath=${OUT} > sid.H
	Window < $< n1=1 f1=15 | Scale dscale=1e-3 datapath=${OUT} > rx.H
	Window < $< n1=1 f1=16 | Scale dscale=1e-3 datapath=${OUT} > ry.H
	Window < $< n1=1 f1=17 | Scale dscale=1e-3 datapath=${OUT} > rz.H
	Window < $< n1=1 f1=12 | Scale dscale=1e-3 datapath=${OUT} > sx.H
	Window < $< n1=1 f1=13 | Scale dscale=1e-3 datapath=${OUT} > sy.H
	Window < $< n1=1 f1=14 | Scale dscale=1e-3 datapath=${OUT} > sz.H
	Pad < rx.H end1=1 extend=1 | Window f1=1 datapath=${OUT} > rx_p1.H
	Pad < rx.H beg1=1 extend=1 | Window n1=1201 datapath=${OUT} > rx_m1.H
	Pad < ry.H end1=1 extend=1 | Window f1=1 datapath=${OUT} > ry_p1.H
	Pad < ry.H beg1=1 extend=1 | Window n1=1201 datapath=${OUT} > ry_m1.H
	Pad < rz.H end1=1 extend=1 | Window f1=1 datapath=${OUT} > rz_p1.H
	Pad < rz.H beg1=1 extend=1 | Window n1=1201 datapath=${OUT} > rz_m1.H
	Math file1=rz_p1.H file2=rz_m1.H file3=rx_p1.H file4=rx_m1.H file5=ry_p1.H file6=ry_m1.H exp='@ATAN((file1-file2)/(@SQRT(file3^2+file5^2)-@SQRT(file4^2+file6^2)))' datapath=${OUT} > rdip.H
	Math file1=ry_p1.H file2=ry_m1.H file3=rx_p1.H file4=rx_m1.H exp='@ATAN((file1-file2)/(file3-file4))' datapath=${OUT} > raz.H	
	echo n1=1 n2=1201 n3=41 >> sid.H
	echo n1=1 n2=1201 n3=41 >> sx.H
	echo n1=1 n2=1201 n3=41 >> sy.H
	echo n1=1 n2=1201 n3=41 >> sz.H
	echo n1=1 n2=1201 n3=41 >> rx.H
	echo n1=1 n2=1201 n3=41 >> ry.H
	echo n1=1 n2=1201 n3=41 >> rz.H
	echo n1=1 n2=1201 n3=41 >> rdip.H
	echo n1=1 n2=1201 n3=41 >> raz.H
	Cat sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H axis=1 datapath=${OUT} > srcoord.H
	python3 ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H rx_p1.H rx_m1.H ry_p1.H ry_m1.H rz_p1.H rz_m1.H srcoord.H

# true locations for shot 14
# ${D}/ch6_srcoord_sp14.txt: ${D}/ch6_data.HH
${D}/ch6_srcoord_sp14.txt:
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H rx_p1.H rx_m1.H ry_p1.H ry_m1.H rz_p1.H rz_m1.H srcoord.H
	Window < $< n3=1 f3=14 n1=1 f1=2 datapath=${OUT} > sid.H
	Window < $< n3=1 f3=14 n1=1 f1=15 | Scale dscale=1e-3 datapath=${OUT} > rx.H
	Window < $< n3=1 f3=14 n1=1 f1=16 | Scale dscale=1e-3 datapath=${OUT} > ry.H
	Window < $< n3=1 f3=14 n1=1 f1=17 | Scale dscale=1e-3 datapath=${OUT} > rz.H
	Window < $< n3=1 f3=14 n1=1 f1=12 | Scale dscale=1e-3 datapath=${OUT} > sx.H
	Window < $< n3=1 f3=14 n1=1 f1=13 | Scale dscale=1e-3 datapath=${OUT} > sy.H
	Window < $< n3=1 f3=14 n1=1 f1=14 | Scale dscale=1e-3 datapath=${OUT} > sz.H
	Pad < rx.H end1=1 extend=1 | Window f1=1 datapath=${OUT} > rx_p1.H
	Pad < rx.H beg1=1 extend=1 | Window n1=1201 datapath=${OUT} > rx_m1.H
	Pad < ry.H end1=1 extend=1 | Window f1=1 datapath=${OUT} > ry_p1.H
	Pad < ry.H beg1=1 extend=1 | Window n1=1201 datapath=${OUT} > ry_m1.H
	Pad < rz.H end1=1 extend=1 | Window f1=1 datapath=${OUT} > rz_p1.H
	Pad < rz.H beg1=1 extend=1 | Window n1=1201 datapath=${OUT} > rz_m1.H
	Math file1=rz_p1.H file2=rz_m1.H file3=rx_p1.H file4=rx_m1.H file5=ry_p1.H file6=ry_m1.H exp='@ATAN((file1-file2)/(@SQRT(file3^2+file5^2)-@SQRT(file4^2+file6^2)))' datapath=${OUT} > rdip.H
	Math file1=ry_p1.H file2=ry_m1.H file3=rx_p1.H file4=rx_m1.H exp='@ATAN((file1-file2)/(file3-file4))' datapath=${OUT} > raz.H	
	echo n1=1 n2=1201 n3=1 >> sid.H
	echo n1=1 n2=1201 n3=1 >> sx.H
	echo n1=1 n2=1201 n3=1 >> sy.H
	echo n1=1 n2=1201 n3=1 >> sz.H
	echo n1=1 n2=1201 n3=1 >> rx.H
	echo n1=1 n2=1201 n3=1 >> ry.H
	echo n1=1 n2=1201 n3=1 >> rz.H
	echo n1=1 n2=1201 n3=1 >> rdip.H
	echo n1=1 n2=1201 n3=1 >> raz.H
	Cat sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H axis=1 datapath=${OUT} > srcoord.H
	python3 ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H rx_p1.H rx_m1.H ry_p1.H ry_m1.H rz_p1.H rz_m1.H srcoord.H

# Min max coordinates (in meters) for all 41 shots after selection above
# 		min			max
# sx	1171		1895
# sy	-254		-223
# sz	1944		1949
# rx	562			1968
# ry	46			53
# rz	1942		1946

###############################################################################################################
# Operations on model
###############################################################################################################

# build a horizon conformal model by running a dummmy 0 iteration 2.5D FWI
${D}/ch6_elasticModelVTI0.H:
	${Rm} source.H data.H
	Spike n1=2 k1=1 d1=0.002 datapath=${OUT} > source.H
	Spike n1=2 k1=1 d1=0.002 datapath=${OUT} > data.H
	${SRUN_MODELING1} ${B}/FWI3D.x source=source.H model=${MODEL} data=data.H horizon=${HRZ} output=$@ datapath=${OUT} format=0 \
	mt=0 seismotype=0 gl=0.01 fmax=250 courant=0.55 dt=0 sub=-1 \
	ns=1 sx0=1 sy0=0 sz0=1.9 nr=1 rx0=1.1 ry0=0 rz0=1.9 \
	vpmin=1 vpmax=9 vsmin=1 vsmax=9 rhomin=1 rhomax=9 soft_clip=0 \
	inversion1d=1 niter=0 verbose=3
	${Rm} source.H data.H

# resize the model to accommodate Western well data, round the origin to the nearest sample
${D}/ch6_model.H: ${D}/ch6_elasticModelVTI0.H
	Window < ${MODEL} min2=0.5 max2=2.0219 max3=0.1109 | Pad beg3=23 extend=1 datapath=${OUT} > $@
	echo o3=-0.310 >> $@

# Same for horizon
${D}/ch6_hrz.H:
	Window < ${HRZ} min1=0.5 max1=2.0219 max2=0.1109 | Pad beg2=23 extend=1 datapath=${OUT} > $@
	echo o2=-0.310 >> $@

# create reservoir layer mask for vp and vs and full mask for rho, delta, epsilon
${D}/ch6_mask.H: ${D}/ch6_model.H
	Window < $< n4=1 f4=3 | Clip clip=0.15 chop=less to=0 | Clip clip=0.1 chop=greater to=1 | Window min1=1.92 | Pad beg1=40 | Smooth rect1=3 rect2=21 | Scale | Pad end4=1 extend=1 | Pad end4=4 extend=0 datapath=${OUT} > $@

all_prep: ${D}/ch6_data.H.bp ${D}/ch6_mute.H ${D}/ch6_hrz.H ${D}/ch6_mask.H

###############################################################################################################
# Vs0 and Anisotropy (epsilon, gamma) scan
###############################################################################################################

# Dirac function
${D}/ch6_dirac.H:
	Spike n1=175 d1=0.002 o1=0 k1=11 nsp=1 mag=500 > $@

# build scaled Vs0 model inside reservoir layer: Vs0_scaled = (1 - scaler*mask) * Vs0_reference
.PRECIOUS: ${D}/ch6_model.H.vs%
${D}/ch6_model.H.vs%: ${D}/ch6_model.H ${D}/ch6_mask.H
	${Rm} temp1.H temp2.H temp3.H temp4.H
	Window < $(word 2, $^) n4=1 f4=0 datapath=${OUT} > temp1.H
	Scale < temp1.H dscale=$* datapath=${OUT} > temp2.H
	Math file1=temp2.H exp='1-file1' datapath=${OUT} > temp1.H
	Math file1=temp1.H exp='0*file1+1' datapath=${OUT} > temp2.H
	Math file1=temp1.H exp='0*file1+1' datapath=${OUT} > temp3.H
	Cat temp2.H temp1.H temp3.H axis=4 | Pad end4=3 extend=1 datapath=${OUT} > temp4.H
	Math file1=$< file2=temp4.H exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp1.H temp2.H temp3.H temp4.H

# generate DAS data for each scaled model
${D}/ch6_dyGny_sp14_vs%.H: ${D}/ch6_dirac.H ${D}/ch6_model.H.vs% ${D}/ch6_srcoord_sp14.txt
	${SRUN_MODELING1} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 mxx=0 myy=1 mzz=0 mxy=0 mxz=0 myz=0 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=1 o3=0 d3=1 >> $@

${D}/ch6_dyGny_sp14_vs_all.H: ${D}/ch6_dyGny_sp14_vs0.00.H ${D}/ch6_dyGny_sp14_vs0.01.H ${D}/ch6_dyGny_sp14_vs0.02.H ${D}/ch6_dyGny_sp14_vs0.03.H ${D}/ch6_dyGny_sp14_vs0.04.H ${D}/ch6_dyGny_sp14_vs0.05.H
	Cat $(word 1, $^) $(word 2, $^) $(word 3, $^) $(word 4, $^) $(word 5, $^) $(word 6, $^) axis=3 datapath=${OUT} > $@

${D}/ch6_dyGny_sp14_vs_all.H.bp: ${D}/ch6_dyGny_sp14_vs_all.H ${D}/ch6_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

# run Part 1 in notebook Model_scan

# build scaled epsilon-gamma model starting from the optimal VTI model based on the Vs0 scan: aniso_scaled = scaler * aniso_reference
.PRECIOUS: ${D}/ch6_model.H.aniso%
${D}/ch6_model.H.aniso%: ${D}/ch6_model.H.vs0.02
	${Rm} temp1.H temp2.H
	Window < $< n4=3 datapath=${OUT} > temp1.H
	Window < $< n4=3 f4=3 |  Scale dscale=$* datapath=${OUT} > temp2.H
	Cat temp1.H temp2.H axis=4 datapath=${OUT} > $@
	${Rm} temp1.H temp2.H

# generate DAS data for each scaled model
${D}/ch6_dyGny_sp14_aniso%.H: ${D}/ch6_dirac.H ${D}/ch6_model.H.aniso% ${D}/ch6_srcoord_sp14.txt
	${SRUN_MODELING1} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 mxx=0 myy=1 mzz=0 mxy=0 mxz=0 myz=0 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=1 o3=0 d3=1 >> $@

${D}/ch6_dyGny_sp14_aniso_all.H: ${D}/ch6_dyGny_sp14_aniso1.00.H ${D}/ch6_dyGny_sp14_aniso0.96.H ${D}/ch6_dyGny_sp14_aniso0.92.H ${D}/ch6_dyGny_sp14_aniso0.88.H ${D}/ch6_dyGny_sp14_aniso0.84.H ${D}/ch6_dyGny_sp14_aniso0.80.H ${D}/ch6_dyGny_sp14_aniso0.76.H ${D}/ch6_dyGny_sp14_aniso0.72.H
	Cat $(word 1, $^) $(word 2, $^) $(word 3, $^) $(word 4, $^) $(word 5, $^) $(word 6, $^) $(word 7, $^) $(word 8, $^) axis=3 datapath=${OUT} > $@

${D}/ch6_dyGny_sp14_aniso_all.H.bp: ${D}/ch6_dyGny_sp14_aniso_all.H ${D}/ch6_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

# run Part 2 in notebook Model_scan

###############################################################################################################
# Build the optimal VTI model based on the Vs0/anisotropy scan, then generate all Green's functions using Dirac moment rate function but keeping seismotype=0
# the optimal scalers are: 0.02 for Vs0, 0.8 for epsilon, 0.92 for gamma
###############################################################################################################

${D}/ch6_model_scan.H: ${D}/ch6_model.H.vs0.02
	${Rm} temp1.H temp2.H temp3.H
	Window < $< n4=3 datapath=${OUT} > temp1.H
	Window < $< n4=2 f4=3 |  Scale dscale=0.8 datapath=${OUT} > temp2.H
	Window < $< n4=1 f4=5 |  Scale dscale=0.92 datapath=${OUT} > temp3.H
	Cat temp1.H temp2.H temp3.H axis=4 datapath=${OUT} > $@
	${Rm} temp1.H temp2.H temp3.H

${D}/ch6_dyGny_sp14_scan.H: ${D}/ch6_dirac.H ${D}/ch6_model_scan.H ${D}/ch6_srcoord_sp14.txt
	${SRUN_MODELING1} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 mxx=0 myy=1 mzz=0 mxy=0 mxz=0 myz=0 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=1 o3=0 d3=1 >> $@

# Green's functions dxGnx
${D}/ch6_dxGnx.H: ${D}/ch6_dirac.H ${D}/ch6_model_scan.H ${D}/ch6_srcoord.txt
	${SRUN_MODELING11} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 mxx=1 myy=0 mzz=0 mxy=0 mxz=0 myz=0 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=41 o3=0 d3=1 >> $@

${D}/ch6_dyGny.H: ${D}/ch6_dirac.H ${D}/ch6_model_scan.H ${D}/ch6_srcoord.txt
	${SRUN_MODELING11} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 mxx=0 myy=1 mzz=0 mxy=0 mxz=0 myz=0 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=41 o3=0 d3=1 >> $@

${D}/ch6_dzGnz.H: ${D}/ch6_dirac.H ${D}/ch6_model_scan.H ${D}/ch6_srcoord.txt
	${SRUN_MODELING11} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 mxx=0 myy=0 mzz=1 mxy=0 mxz=0 myz=0 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=41 o3=0 d3=1 >> $@

${D}/ch6_dxGny.H: ${D}/ch6_dirac.H ${D}/ch6_model_scan.H ${D}/ch6_srcoord.txt
	${SRUN_MODELING11} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 mxx=0 myy=0 mzz=0 mxy=1 mxz=0 myz=0 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=41 o3=0 d3=1 >> $@

${D}/ch6_dxGnz.H: ${D}/ch6_dirac.H ${D}/ch6_model_scan.H ${D}/ch6_srcoord.txt
	${SRUN_MODELING11} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 mxx=0 myy=0 mzz=0 mxy=0 mxz=1 myz=0 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=41 o3=0 d3=1 >> $@

${D}/ch6_dyGnz.H: ${D}/ch6_dirac.H ${D}/ch6_model_scan.H ${D}/ch6_srcoord.txt
	${SRUN_MODELING11} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 mxx=0 myy=0 mzz=0 mxy=0 mxz=0 myz=1 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=41 o3=0 d3=1 >> $@

# apply BP filter
${D}/ch6_%.H.bp: ${D}/ch6_%.H ${D}/ch6_bp.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

###############################################################################################################
# The outputs above are used in MT_inversion.ipynb for MT inversion
###############################################################################################################

all_gf: all_prep ${D}/ch6_dxGnx.H.bp ${D}/ch6_dyGny.H.bp ${D}/ch6_dzGnz.H.bp ${D}/ch6_dxGny.H.bp ${D}/ch6_dxGnz.H.bp ${D}/ch6_dyGnz.H.bp

# copy back to OAS to perform the MT inversion there, then copy back the sources
# otherwise, perform everything on Sherlock using OnDemand Jupyter Notebook
.PHONY: oas
oas: ${D}/ch6_data.H.bp ${D}/ch6_data.HH ${D}/ch6_mute.H ${D}/ch6_dxGnx.H.bp ${D}/ch6_dyGny.H.bp ${D}/ch6_dzGnz.H.bp ${D}/ch6_dxGny.H.bp ${D}/ch6_dxGnz.H.bp ${D}/ch6_dyGnz.H.bp
	rm -f ./to_oas/dat/*
	Cp < $(word 1, $^) > ./to_oas/$(word 1, $^) datapath=stdout
	Cp < $(word 2, $^) > ./to_oas/$(word 2, $^) datapath=stdout
	Cp < $(word 3, $^) > ./to_oas/$(word 3, $^) datapath=stdout
	Cp < $(word 4, $^) > ./to_oas/$(word 4, $^) datapath=stdout
	Cp < $(word 5, $^) > ./to_oas/$(word 5, $^) datapath=stdout
	Cp < $(word 6, $^) > ./to_oas/$(word 6, $^) datapath=stdout
	Cp < $(word 7, $^) > ./to_oas/$(word 7, $^) datapath=stdout
	Cp < $(word 8, $^) > ./to_oas/$(word 8, $^) datapath=stdout
	Cp < $(word 9, $^) > ./to_oas/$(word 9, $^) datapath=stdout
	scp ./to_oas/dat/* nmbader@oas.stanford.edu:/sep/nmbader/thesis/chapters/ch6/to_sherlock/dat/

###############################################################################################################
# The outputs above are used in Data_selection.ipynb for data selection and grouping
# this results in 2 groups:
# group1: keep last perf per stage, total 11 perfs
# group2: keep second to last perf per stage, total 11 perfs
# the output of Data_selection.ipynb are listed below
###############################################################################################################

DATA_G1=./dat/ch6_data0_group1.H
DATA_G2=./dat/ch6_data0_group2.H
ATTR_G1=./dat/ch6_data0_group1.HH
ATTR_G2=./dat/ch6_data0_group2.HH
MUTE_G1=./dat/ch6_mute0_group1.H
MUTE_G2=./dat/ch6_mute0_group2.H
SRC_G1=./dat/ch6_sources0_group1.H
SRC_G2=./dat/ch6_sources0_group2.H

NSRC0_G1=11
NSRC0_G2=11

###############################################################################################################
# FWI runs
###############################################################################################################

include fwi_unstimulated.mk
include fwi_stimulated.mk
include synthetic_analysis.mk

###############################################################################################################
# second pass of 3D MT inversion using updated GFs
###############################################################################################################

include mt_inversion_bis.mk

###############################################################################################################
# Default make rules
###############################################################################################################

burn:
	rm -f ${F}/*

clean:
	rm -f ${F}/*
	${Rm} -f ${D}/*.H*
	rm -f ${D}/*
