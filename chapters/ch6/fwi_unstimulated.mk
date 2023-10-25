##### 3D FWI for the unstimulated reservoir #####

###############################################################################################################
# shift by 10 ms
###############################################################################################################

${D}/ch6un_data_group1.H:
	Pad < ${DATA_G1} beg1=5 | Window n1=175 datapath=${OUT} > $@
	echo o1=0 >> $@

${D}/ch6un_data_group1.HH:
	Cp < ${ATTR_G1} datapath=${OUT} > $@

${D}/ch6un_mute_group1.H:
	Pad < ${MUTE_G1} beg1=5 | Window n1=175 datapath=${OUT} > $@
	echo o1=0 >> $@

${D}/ch6un_sources_group1.H:
	Pad < ${SRC_G1} beg1=5 | Window n1=175 datapath=${OUT} > $@
	echo o1=0 >> $@

${D}/ch6un_data_group2.H:
	Pad < ${DATA_G2} beg1=5 | Window n1=175 datapath=${OUT} > $@
	echo o1=0 >> $@

${D}/ch6un_data_group2.HH:
	Cp < ${ATTR_G2} datapath=${OUT} > $@

${D}/ch6un_mute_group2.H:
	Pad < ${MUTE_G2} beg1=5 | Window n1=175 datapath=${OUT} > $@
	echo o1=0 >> $@

${D}/ch6un_sources_group2.H:
	Pad < ${SRC_G2} beg1=5 | Window n1=175 datapath=${OUT} > $@
	echo o1=0 >> $@

###############################################################################################################
# Mutes
###############################################################################################################

# keep P-arrival
${D}/ch6un_mute1_group1.H: ${D}/ch6un_mute_group1.H
	${Rm} temp.H
	Math file1=$< exp='0*file1+1' | Mute vmute=2800 tramp=0.0 tmute=0.13 datapath=${OUT} > temp.H
	Math file1=temp.H exp="@ABS(1-file1)" | Smooth rect1=2 repeat=1 datapath=${OUT} > $@
	${Rm} temp.H
	
# keep P- and SH-arrivals
${D}/ch6un_mute2_group1.H: ${D}/ch6un_mute_group1.H
	${Rm} temp.H
	Math file1=$< exp='0*file1+1' | Mute vmute=1900 tramp=0.0 tmute=0.18 datapath=${OUT} > temp.H
	Math file1=temp.H exp="@ABS(1-file1)" | Smooth rect1=2 repeat=1 datapath=${OUT} > $@
	${Rm} temp.H

# combine mute and mask
${D}/ch6un_mute3_group1.H: ${D}/ch6un_mute2_group1.H ${D}/ch6un_mute_group1.H
	Math file1=$< file2=$(word 2, $^) exp='file1*file2' datapath=${OUT} > $@

${D}/ch6un_mute3_group2.H: ${D}/ch6un_mute2_group1.H ${D}/ch6un_mute_group2.H
	Math file1=$< file2=$(word 2, $^) exp='file1*file2' datapath=${OUT} > $@

# keep negative offsets
${D}/ch6un_mute4_group1.H: ${D}/ch6un_mute3_group1.H
	Window < $< n2=601 | Pad end2=600 datapath=${OUT} > $@

${D}/ch6un_mute4_group2.H: ${D}/ch6un_mute3_group2.H
	Window < $< n2=601 | Pad end2=600 datapath=${OUT} > $@


# keep negative offsets for all times
${D}/ch6un_mute5_group1.H: ${D}/ch6un_mute_group1.H
	Window < $< n2=601 | Pad end2=600 datapath=${OUT} > $@

${D}/ch6un_mute5_group2.H: ${D}/ch6un_mute_group1.H
	Window < $< n2=601 | Pad end2=600 datapath=${OUT} > $@


###############################################################################################################
# Filters
###############################################################################################################

# band-pass filter 30-100 Hz, scale the filter so that its amplitude spectrum peaks at 1
${D}/ch6un_bp30100.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=75 dt=0.002 type=butterworth low_cutoff=0.12 high_cutoff=0.48 half_order=1 phase=zero datapath=${OUT} > temp.H
	${B}/FX_FILTER.x < temp.H filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | Scale dscale=1.17927 datapath=${OUT} > $@
	${Rm} temp.H

# band-pass filter 30-150 Hz, scale the filter so that its amplitude spectrum peaks at 1
${D}/ch6un_bp30150.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=75 dt=0.002 type=butterworth low_cutoff=0.12 high_cutoff=0.6 half_order=1 phase=zero datapath=${OUT} > temp.H
	${B}/FX_FILTER.x < temp.H filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | ${B}/FX_FILTER.x filter=temp.H | Scale dscale=1.07971 datapath=${OUT} > $@
	${Rm} temp.H

.PRECIOUS: ${D}/ch6un_%.bp30100 ${D}/ch6un_%.bp30150

${D}/ch6un_%.bp30100: ${D}/ch6un_% ${D}/ch6un_bp30100.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch6un_%.bp30150: ${D}/ch6un_% ${D}/ch6un_bp30150.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

###############################################################################################################
# Coordinates
###############################################################################################################

# true locations for all shots and channels
${D}/ch6un_srcoord_group1.txt: ${D}/ch6un_data_group1.HH
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
	echo n1=1 n2=1201 n3=11 >> sid.H
	echo n1=1 n2=1201 n3=11 >> sx.H
	echo n1=1 n2=1201 n3=11 >> sy.H
	echo n1=1 n2=1201 n3=11 >> sz.H
	echo n1=1 n2=1201 n3=11 >> rx.H
	echo n1=1 n2=1201 n3=11 >> ry.H
	echo n1=1 n2=1201 n3=11 >> rz.H
	echo n1=1 n2=1201 n3=11 >> rdip.H
	echo n1=1 n2=1201 n3=11 >> raz.H
	Cat sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H axis=1 datapath=${OUT} > srcoord.H
	python3 ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H rx_p1.H rx_m1.H ry_p1.H ry_m1.H rz_p1.H rz_m1.H srcoord.H


${D}/ch6un_srcoord_group2.txt: ${D}/ch6un_data_group2.HH
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
	echo n1=1 n2=1201 n3=11 >> sid.H
	echo n1=1 n2=1201 n3=11 >> sx.H
	echo n1=1 n2=1201 n3=11 >> sy.H
	echo n1=1 n2=1201 n3=11 >> sz.H
	echo n1=1 n2=1201 n3=11 >> rx.H
	echo n1=1 n2=1201 n3=11 >> ry.H
	echo n1=1 n2=1201 n3=11 >> rz.H
	echo n1=1 n2=1201 n3=11 >> rdip.H
	echo n1=1 n2=1201 n3=11 >> raz.H
	Cat sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H axis=1 datapath=${OUT} > srcoord.H
	python3 ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sy.H sz.H rx.H ry.H rz.H rdip.H raz.H rx_p1.H rx_m1.H ry_p1.H ry_m1.H rz_p1.H rz_m1.H srcoord.H

###############################################################################################################
# synthetic data
###############################################################################################################

${D}/ch6un_syn_group1.H: ${D}/ch6un_sources_group1.H ${D}/ch6_model_scan.H ${D}/ch6un_srcoord_group1.txt
	${SRUN_MODELING11b} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=11 o3=0 d3=1 >> $@

${D}/ch6un_syn_group2.H: ${D}/ch6un_sources_group2.H ${D}/ch6_model_scan.H ${D}/ch6un_srcoord_group2.txt
	${SRUN_MODELING11b} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=11 o3=0 d3=1 >> $@

###############################################################################################################
# estimate Matching filters between synthetic and field data using near offsets -200 to 0 m and early time < 0.2 sec
###############################################################################################################

${D}/ch6un_matched_group1.H.bp30100: ${D}/ch6un_syn_group1.H.bp30100 ${D}/ch6un_data_group1.H.bp30100 ${D}/ch6un_mute3_group1.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=-200 max2=0 max1=0.2 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=-200 max2=0 max1=0.2 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.1 bias_f=0.32 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch6un_sources_group1_matched30100.H: ${D}/ch6un_sources_group1.H ${D}/ch6un_matched_group1.H.bp30100
	./update_sources.sh $< $(word 2,$^).filter $@

${D}/ch6un_matched_group1.H.bp30150: ${D}/ch6un_syn_group1.H.bp30150 ${D}/ch6un_data_group1.H.bp30150 ${D}/ch6un_mute3_group1.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=-200 max2=0 max1=0.2 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=-200 max2=0 max1=0.2 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.15 bias_f=0.4 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch6un_sources_group1_matched30150.H: ${D}/ch6un_sources_group1.H ${D}/ch6un_matched_group1.H.bp30150
	./update_sources.sh $< $(word 2,$^).filter $@

${D}/ch6un_matched_group2.H.bp30100: ${D}/ch6un_syn_group2.H.bp30100 ${D}/ch6un_data_group2.H.bp30100 ${D}/ch6un_mute3_group2.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=-200 max2=0 max1=0.2 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=-200 max2=0 max1=0.2 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.1 bias_f=0.32 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch6un_sources_group2_matched30100.H: ${D}/ch6un_sources_group2.H ${D}/ch6un_matched_group2.H.bp30100
	./update_sources.sh $< $(word 2,$^).filter $@

${D}/ch6un_matched_group2.H.bp30150: ${D}/ch6un_syn_group2.H.bp30150 ${D}/ch6un_data_group2.H.bp30150 ${D}/ch6un_mute3_group2.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=-200 max2=0 max1=0.2 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=-200 max2=0 max1=0.2 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.15 bias_f=0.4 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch6un_sources_group2_matched30150.H: ${D}/ch6un_sources_group2.H ${D}/ch6un_matched_group2.H.bp30150
	./update_sources.sh $< $(word 2,$^).filter $@

###############################################################################################################
# run 3D FWI
###############################################################################################################

# Build starting 3D B-spline model by least-squares from the initial model : BS x-spacing is 25 m, y-spacing is 25 m
${D}/ch6un_model_3d.H: ${D}/ch6_model_scan.H
	${B}/BSPLINES3D.x < $< nx=62 ny=18 nz=101 niter=20 nthreads=24 bsoutput=$@.bs datapath=${OUT} > $@

# Build starting 3D B-spline model by least-squares from the initial model : BS x-spacing is 25 m, y-spacing is 60 m
${D}/ch6un_model2_3d.H: ${D}/ch6_model_scan.H
	${B}/BSPLINES3D.x < $< nx=62 ny=8 nz=101 niter=20 nthreads=24 bsoutput=$@.bs datapath=${OUT} > $@

# Smooth the original mask
${D}/ch6un_mask.H: ${D}/ch6_mask.H
	${B}/BSPLINES3D.x < $< nx=62 ny=8 nz=101 nthreads=24 datapath=${OUT} > $@

# build mask to taper gradients around sources and DAS fiber
${D}/ch6un_taper.H:
	Vel n1=211 n2=301 n3=1 d1=0.002 d2=0.002 d3=0.001 o1=-0.31 o2=1.2 vc=0.05 z1=-0.205 alfa1=-2.3 vr1=1 const1=1 z2=0.03 vr2=0.05 const2=1 | Pad beg2=350 n2out=761 extend=1 | Smooth rect1=3 rect2=5 repeat=5 datapath=${OUT} > $@

# combine mask and taper
${D}/ch6un_mask_taper.H: ${D}/ch6un_taper.H ${D}/ch6un_mask.H
	${Rm} temp.H
	Pad < $< end3=100 extend=1 | Transp plane=13 | Pad end4=5 extend=1 datapath=${OUT} > temp.H
	Math file1=$(word 2, $^) file2=temp.H exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp.H
	

# reference FWI with taper and mask, without Bsplines
${D}/ch6un_fwi3d_1.H: ${D}/ch6un_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6un_mute4_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=0 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=20 ioutput=$@. \
	2> $@.log

# taper and mask with Bsplines
${D}/ch6un_fwi3d_1b.H: ${D}/ch6un_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6un_mute4_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 2, $^).bs data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=20 ioutput=$@. \
	2> $@.log


# reference FWI using group2
${D}/ch6un_fwi3d_2.H: ${D}/ch6un_sources_group2_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group2.H ${D}/ch6un_mute4_group2.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group2.txt ${D}/ch6un_bp30100.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=0 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=20 ioutput=$@. \
	2> $@.log

# using group2 with Bsplines
${D}/ch6un_fwi3d_2b.H: ${D}/ch6un_sources_group2_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group2.H ${D}/ch6un_mute4_group2.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group2.txt ${D}/ch6un_bp30100.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 2, $^).bs data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=20 ioutput=$@. \
	2> $@.log


# reference FWI with taper and mask, without Bsplines, full trace
${D}/ch6un_fwi3d_3.H: ${D}/ch6un_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6un_mute5_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=0 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=20 ioutput=$@. \
	2> $@.log

# taper and mask with Bsplines
${D}/ch6un_fwi3d_3b.H: ${D}/ch6un_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6un_mute5_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 2, $^).bs data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=20 ioutput=$@. \
	2> $@.log

# reference FWI with taper and mask, without Bsplines, full trace, full offsets
${D}/ch6un_fwi3d_4.H: ${D}/ch6un_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6un_mute_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=0 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=20 ioutput=$@. \
	2> $@.log

# taper and mask with Bsplines
${D}/ch6un_fwi3d_4b.H: ${D}/ch6un_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6un_mute_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 2, $^).bs data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=20 ioutput=$@. \
	2> $@.log


# input reference FWI with taper, mask, and Bsplines and move to higher frequencies
${D}/ch6un_fwi3d_10b.H: ${D}/ch6un_sources_group1_matched30150.H ${D}/ch6un_fwi3d_1b.H ${D}/ch6un_data_group1.H ${D}/ch6un_mute4_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30150.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 2, $^).model_iter_20.H data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=10 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=10 ioutput=$@. \
	2> $@.log

# using group2
${D}/ch6un_fwi3d_12b.H: ${D}/ch6un_sources_group2_matched30150.H ${D}/ch6un_fwi3d_2b.H ${D}/ch6un_data_group2.H ${D}/ch6un_mute4_group2.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group2.txt ${D}/ch6un_bp30150.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 2, $^).model_iter_20.H data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=10 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=10 ioutput=$@. \
	2> $@.log

###############################################################################################################
# synthetic data from any given model
###############################################################################################################

.PRECIOUS: ${D}/ch6un_%.H.syn
${D}/ch6un_%.H.syn: ${D}/ch6un_sources_group1_matched30100.H ${D}/ch6un_%.H ${D}/ch6un_srcoord_group1.txt
	${SRUN_MODELING11b} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=11 o3=0 d3=1 >> $@

.PRECIOUS: ${D}/ch6un_%.H.syn_hf
${D}/ch6un_%.H.syn_hf: ${D}/ch6un_sources_group1_matched30150.H ${D}/ch6un_%.H ${D}/ch6un_srcoord_group1.txt
	${SRUN_MODELING11b} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=11 o3=0 d3=1 >> $@



fwi_unstimulated: ${D}/ch6un_data_group1.HH ${D}/ch6un_data_group2.HH ${D}/ch6un_fwi3d_10b.H ${D}/ch6un_fwi3d_1b.H \
${D}/ch6un_data_group1.H.bp30150 ${D}/ch6un_model_3d.H.syn_hf.bp30150 ${D}/ch6un_fwi3d_10b.H.syn_hf.bp30150