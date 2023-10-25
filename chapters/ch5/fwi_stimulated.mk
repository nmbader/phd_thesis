##### 2D FWI for the stimulated reservoir #####

###############################################################################################################
# data selection : 150 < offsets < 650 m, perfs>=18, apply AVO correction
###############################################################################################################

${D}/ch5st_data_group2.H:
	${Rm} temp1.H temp2.H
	Window < ${DATA_G2} n3=16 f3=4 f2=950 n2=501 datapath=${OUT} > temp1.H
	Window < ${AVO_WEIGHTS} f1=950 n1=501 | Pad end2=174 extend=1 | Transp | Pad end3=15 extend=1 datapath=${OUT} > temp2.H
	Math file1=temp1.H file2=temp2.H exp='file1*file2' datapath=${OUT} > $@
	${Rm} temp1.H temp2.H

${D}/ch5st_data_group2.HH:
	Window < ${ATTR_G2} n3=16 f3=4 f2=950 n2=501 datapath=${OUT} > $@

${D}/ch5st_mute_group2.H:
	Window < ${MUTE_G2} n3=16 f3=4 f2=950 n2=501 datapath=${OUT} > $@

${D}/ch5st_sources_group2.H:
	Window < ${SRC_S_G2} n2=16 f2=4 datapath=${OUT} > $@

# frequency-velocity amplitude spectrum for full, near, and far offsets
${D}/ch5st_data_group2.H.fv: ${D}/ch5st_data_group2.H
	Window < $< min2=150 max2=650 | ${B}/FV.x vmin=1500 vmax=6500 datapath=${OUT} output=$@
	Window < $< min2=150 max2=200 | ${B}/FV.x vmin=1500 vmax=6500 datapath=${OUT} output=$@.near
	Window < $< min2=200 max2=650 | ${B}/FV.x vmin=1500 vmax=6500 datapath=${OUT} output=$@.far

###############################################################################################################
# Filters
###############################################################################################################

# band-pass filter 30-100 Hz, scale the filter so that its amplitude spectrum peaks at 1
${D}/ch5st_bp30100.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=75 dt=0.002 type=butterworth low_cutoff=0.12 high_cutoff=0.48 half_order=1 phase=zero datapath=${OUT} > temp.H
	Filter < temp.H filter=temp.H | Filter filter=temp.H | Filter filter=temp.H | Filter filter=temp.H | Filter filter=temp.H | Scale dscale=1.28053 datapath=${OUT} > $@
	${Rm} temp.H

# band-pass filter 30-150 Hz, scale the filter so that its amplitude spectrum peaks at 1
${D}/ch5st_bp30150.H:
	${Rm} temp.H
	${B}/GENERATE_WAVELET.x nt=75 dt=0.002 type=butterworth low_cutoff=0.12 high_cutoff=0.6 half_order=1 phase=zero datapath=${OUT} > temp.H
	Filter < temp.H filter=temp.H | Filter filter=temp.H | Filter filter=temp.H | Filter filter=temp.H | Filter filter=temp.H | Scale dscale=1.12197 datapath=${OUT} > $@
	${Rm} temp.H

.PRECIOUS: ${D}/ch5st_%.bp30100 ${D}/ch5st_%.bp30150

${D}/ch5st_%.bp30100: ${D}/ch5st_% ${D}/ch5st_bp30100.H
	Filter < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch5st_%.bp30150: ${D}/ch5st_% ${D}/ch5st_bp30150.H
	Filter < $< filter=$(word 2,$^) datapath=${OUT} > $@

###############################################################################################################
# Coordinates
###############################################################################################################

# true locations for all shots and channels
${D}/ch5st_srcoord_group2.txt: ${D}/ch5st_data_group2.HH
	${Rm} sid.H sx.H sz.H rx.H rz.H rdip.H srcoord.H
	Window < $< n1=1 f1=0 datapath=${OUT} > sid.H
	Window < $< n1=1 f1=16 | Scale dscale=1e-5 datapath=${OUT} > rx.H
	Window < $< n1=1 f1=18 | Scale dscale=1e-5 datapath=${OUT} > rz.H
	Window < $< n1=1 f1=19 | Scale dscale=1e-5 datapath=${OUT} > sx.H
	Window < $< n1=1 f1=21 | Scale dscale=1e-5 datapath=${OUT} > sz.H
	Window < $< n1=1 f1=24 datapath=${OUT} > rdip.H
	echo n1=1 n2=501 n3=16 >> sid.H
	echo n1=1 n2=501 n3=16 >> sx.H
	echo n1=1 n2=501 n3=16 >> sz.H
	echo n1=1 n2=501 n3=16 >> rx.H
	echo n1=1 n2=501 n3=16 >> rz.H
	echo n1=1 n2=501 n3=16 >> rdip.H
	Cat sid.H sx.H sz.H rx.H rz.H rdip.H axis=1 datapath=${OUT} > srcoord.H
	python ${P}/dumpHeader.py --input=srcoord.H >> $@
	${Rm} sid.H sx.H sz.H rx.H rz.H rdip.H srcoord.H

###############################################################################################################
# synthetic data
###############################################################################################################

# using MT from stimulated side
${D}/ch5st_syn_group2.H: ${D}/ch5st_sources_group2.H ${D}/ch5_model.H ${D}/ch5st_srcoord_group2.txt
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_strength=0.02 \
	device=0
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

# using MT (and matched sources) from unstimulated side to estimate time shifts and deduce short-term Vp,Vs perturbations
${D}/ch5st_syn2_group2.H: ${D}/ch5un_sources_st_group2.H ${D}/ch5_model.H ${D}/ch5st_srcoord_group2.txt
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_strength=0.02 \
	device=1
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

${D}/ch5st_syn3_group2_matched30100.H: ${D}/ch5un_sources_st_group2_matched30100.H ${D}/ch5_model.H ${D}/ch5st_srcoord_group2.txt
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_strength=0.02 \
	device=1
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

${D}/ch5st_syn3_group2_matched30150.H: ${D}/ch5un_sources_st_group2_matched30150.H ${D}/ch5_model.H ${D}/ch5st_srcoord_group2.txt
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_strength=0.02 \
	device=1
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

###############################################################################################################
# The output above are used in ST_effect.ipynb for stimulation short term effects
###############################################################################################################

###############################################################################################################
# Calibrate the model to match near offsets 150 - 200 m
# 1) estimate matching filters between synthetic and field data using offsets 150 to 200 m
# 2) run extended FWI without regularization (as garbage collector)
# 3) use extended FWI model as starting model for next step
###############################################################################################################

# MT from stimulated side
${D}/ch5st_matched0_group2.H.bp30100: ${D}/ch5st_syn_group2.H.bp30100 ${D}/ch5st_data_group2.H.bp30100 ${D}/ch5st_mute_group2.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=150 max2=200 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=150 max2=200 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.1 bias_f=0.32 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch5st_sources0_group2_matched30100.H: ${D}/ch5st_sources_group2.H ${D}/ch5st_matched0_group2.H.bp30100
	./update_sources.sh $< $(word 2,$^).filter $@

# mute |offset| > 200 m
${D}/ch5st_mute0_group2.H: ${D}/ch5st_mute_group2.H
	Window < $< n2=51 | Pad n2out=501 datapath=${OUT} > $@

# Build starting 2D B-spline model by least-squares from the initial model : BS x-spacing is 50 m
${D}/ch5st_model0_2d.H: ${D}/ch5_model.H
	${B}/BSPLINES.x < $< nx=42 nz=101 niter=20 bsoutput=$@.bs datapath=${OUT} > $@

# Extend B-spline model along sources
${D}/ch5st_model0_2d.H.bs.ext: ${D}/ch5st_model0_2d.H
	Pad < $<.bs end4=15 extend=1 datapath=${OUT} > $@

# dummy extended FWI to output the extension weights
${D}/ch5st_extension0_group2: ${D}/ch5st_sources0_group2_matched30100.H ${D}/ch5st_model0_2d.H ${D}/ch5st_model0_2d.H.bs.ext ${D}/ch5st_data_group2.H ${D}/ch5st_mute0_group2.H ${D}/ch5_mask.H ${D}/ch5st_srcoord_group2.txt ${D}/ch5st_bp30100.H 
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 3, $^) data=$(word 4, $^) weights=$(word 5, $^) mask=$(word 6, $^) srcoord=$(word 7, $^) filter=$(word 8, $^) \
	extension_weights=$@.weights datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_strength=0.02 \
	device=1 verbose=1 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=42 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 normalize_obj_func=0 \
	damping_widthx=0.2 damping_widthz=0.02 damping_floor=0.999 damping_power=6 lambda=0. xextension=-1 zextension=-1 \
	nlsolver=lbfgs lbfgs_m=5 niter=0 threshold=0.0 max_trial=0 ls_c1=1e-3 ls_c2=0.9 \
	2> $@

${D}/ch5st_extension1_group2: ${D}/ch5st_sources0_group2_matched30100.H ${D}/ch5st_model0_2d.H ${D}/ch5st_model0_2d.H.bs.ext ${D}/ch5st_data_group2.H ${D}/ch5st_mute0_group2.H ${D}/ch5_mask.H ${D}/ch5st_srcoord_group2.txt ${D}/ch5st_bp30100.H 
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 3, $^) data=$(word 4, $^) weights=$(word 5, $^) mask=$(word 6, $^) srcoord=$(word 7, $^) filter=$(word 8, $^) \
	extension_weights=$@.weights datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_strength=0.02 \
	device=1 verbose=1 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=42 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 normalize_obj_func=0 \
	damping_widthx=0.3 damping_widthz=0.05 damping_floor=0.999 damping_power=6 lambda=0. xextension=-1 zextension=-1 \
	nlsolver=lbfgs lbfgs_m=5 niter=0 threshold=0.0 max_trial=0 ls_c1=1e-3 ls_c2=0.9 \
	2> $@

# build extended mask from weights to limit the garbage collector FWI around the sources
${D}/ch5st_mask_garbage_extended0.H: ${D}/ch5st_extension0_group2 ${D}/ch5_mask.H
	${Rm} mask.H weights.H
	Pad < $(word 2,$^) end4=15 extend=1 datapath=${OUT} > mask.H
	Math file1=$(word 1,$^).weights exp='1-file1' | Pad end4=4 extend=1 | Transp plane=34 datapath=${OUT} > weights.H
	Math file1=mask.H file2=weights.H exp='file1*file2' datapath=${OUT} > $@
	${Rm} mask.H weights.H

${D}/ch5st_mask_garbage_extended1.H: ${D}/ch5st_extension1_group2 ${D}/ch5_mask.H
	${Rm} mask.H weights.H
	Pad < $(word 2,$^) end4=15 extend=1 datapath=${OUT} > mask.H
	Math file1=$(word 1,$^).weights exp='1-file1' | Pad end4=4 extend=1 | Transp plane=34 datapath=${OUT} > weights.H
	Math file1=mask.H file2=weights.H exp='file1*file2' datapath=${OUT} > $@
	${Rm} mask.H weights.H

# extended FWI with zero damping (same as single source FWI)
${D}/ch5st_fwi2d_0_group2.H: ${D}/ch5st_sources0_group2_matched30100.H ${D}/ch5st_model0_2d.H ${D}/ch5st_model0_2d.H.bs.ext ${D}/ch5st_data_group2.H ${D}/ch5st_mute0_group2.H ${D}/ch5_mask.H ${D}/ch5st_srcoord_group2.txt ${D}/ch5st_bp30100.H 
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 3, $^) data=$(word 4, $^) weights=$(word 5, $^) mask=$(word 6, $^) srcoord=$(word 7, $^) filter=$(word 8, $^) \
	output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_strength=0.02 \
	device=0 verbose=1 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=42 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 normalize_obj_func=0 \
	damping_widthx=0.3 damping_widthz=0.05 damping_floor=0.999 damping_power=6 lambda=0. xextension=0.0 zextension=-1 \
	nlsolver=lbfgs lbfgs_m=5 niter=25 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=25 ioutput=$@. \
	2> $@.log

# extended FWI with more iterations
${D}/ch5st_fwi2d_0b_group2.H: ${D}/ch5st_sources0_group2_matched30100.H ${D}/ch5st_model0_2d.H ${D}/ch5st_model0_2d.H.bs.ext ${D}/ch5st_data_group2.H ${D}/ch5st_mute0_group2.H ${D}/ch5_mask.H ${D}/ch5st_srcoord_group2.txt ${D}/ch5st_bp30100.H 
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 3, $^) data=$(word 4, $^) weights=$(word 5, $^) mask=$(word 6, $^) srcoord=$(word 7, $^) filter=$(word 8, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_strength=0.02 \
	device=1 verbose=1 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=42 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 normalize_obj_func=0 \
	damping_widthx=0.3 damping_widthz=0.05 damping_floor=0.999 damping_power=6 lambda=0. xextension=0.0 zextension=-1 \
	nlsolver=lbfgs lbfgs_m=5 niter=50 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 \
	2> $@.log

# extended FWI with even more iterations
${D}/ch5st_fwi2d_0c_group2.H: ${D}/ch5st_sources0_group2_matched30100.H ${D}/ch5st_model0_2d.H ${D}/ch5st_model0_2d.H.bs.ext ${D}/ch5st_data_group2.H ${D}/ch5st_mute0_group2.H ${D}/ch5_mask.H ${D}/ch5st_srcoord_group2.txt ${D}/ch5st_bp30100.H 
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 3, $^) data=$(word 4, $^) weights=$(word 5, $^) mask=$(word 6, $^) srcoord=$(word 7, $^) filter=$(word 8, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_strength=0.02 \
	device=2 verbose=1 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=42 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 normalize_obj_func=0 \
	damping_widthx=0.3 damping_widthz=0.05 damping_floor=0.999 damping_power=6 lambda=0. xextension=0.0 zextension=-1 \
	nlsolver=lbfgs lbfgs_m=5 niter=100 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 \
	2> $@.log

# extended FWI using extended mask
${D}/ch5st_fwi2d_0d_group2.H: ${D}/ch5st_sources0_group2_matched30100.H ${D}/ch5st_model0_2d.H ${D}/ch5st_model0_2d.H.bs.ext ${D}/ch5st_data_group2.H ${D}/ch5st_mute0_group2.H ${D}/ch5st_mask_garbage_extended1.H ${D}/ch5st_srcoord_group2.txt ${D}/ch5st_bp30100.H 
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 3, $^) data=$(word 4, $^) weights=$(word 5, $^) mask=$(word 6, $^) srcoord=$(word 7, $^) filter=$(word 8, $^) \
	output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_strength=0.02 \
	device=3 verbose=1 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=42 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 normalize_obj_func=0 \
	damping_widthx=0.3 damping_widthz=0.05 damping_floor=0.999 damping_power=6 lambda=0. xextension=-1 zextension=-1 \
	nlsolver=lbfgs lbfgs_m=5 niter=25 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=25 ioutput=$@. \
	2> $@.log

${D}/ch5st_fwi2d_0e_group2.H: ${D}/ch5st_sources0_group2_matched30100.H ${D}/ch5st_model0_2d.H ${D}/ch5st_model0_2d.H.bs.ext ${D}/ch5st_data_group2.H ${D}/ch5st_mute0_group2.H ${D}/ch5st_mask_garbage_extended0.H ${D}/ch5st_srcoord_group2.txt ${D}/ch5st_bp30100.H 
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 3, $^) data=$(word 4, $^) weights=$(word 5, $^) mask=$(word 6, $^) srcoord=$(word 7, $^) filter=$(word 8, $^) \
	output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_strength=0.02 \
	device=3 verbose=1 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=42 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 normalize_obj_func=0 \
	damping_widthx=0.3 damping_widthz=0.05 damping_floor=0.999 damping_power=6 lambda=0. xextension=-1 zextension=-1 \
	nlsolver=lbfgs lbfgs_m=5 niter=50 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=25 ioutput=$@. \
	2> $@.log

# synthetic using the extended FWI above
${D}/ch5st_fwi2d_0_group2_syn.H: ${D}/ch5st_sources_group2.H ${D}/ch5st_fwi2d_0_group2.H ${D}/ch5st_data_group2.HH
	./extended_model_synthetic.sh $< $(word 2,$^).ext $(word 3,$^) $@
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

${D}/ch5st_fwi2d_0b_group2_syn.H: ${D}/ch5st_sources_group2.H ${D}/ch5st_fwi2d_0b_group2.H ${D}/ch5st_data_group2.HH
	./extended_model_synthetic.sh $< $(word 2,$^).ext $(word 3,$^) $@
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

${D}/ch5st_fwi2d_0c_group2_syn.H: ${D}/ch5st_sources_group2.H ${D}/ch5st_fwi2d_0c_group2.H ${D}/ch5st_data_group2.HH
	./extended_model_synthetic.sh $< $(word 2,$^).ext $(word 3,$^) $@
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

${D}/ch5st_fwi2d_0d_group2_syn.H: ${D}/ch5st_sources_group2.H ${D}/ch5st_fwi2d_0d_group2.H ${D}/ch5st_data_group2.HH
	./extended_model_synthetic.sh $< $(word 2,$^).ext $(word 3,$^) $@
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

${D}/ch5st_fwi2d_0e_group2_syn.H: ${D}/ch5st_sources_group2.H ${D}/ch5st_fwi2d_0e_group2.H ${D}/ch5st_data_group2.HH
	./extended_model_synthetic.sh $< $(word 2,$^).ext $(word 3,$^) $@
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

###############################################################################################################
# estimate Matching filters between synthetic and field data using near offsets 200 to 250 m
###############################################################################################################

${D}/ch5st_matched_group2.H.bp30100: ${D}/ch5st_fwi2d_0e_group2_syn.H.bp30100 ${D}/ch5st_data_group2.H.bp30100 ${D}/ch5st_mute_group2.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=200 max2=250 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=200 max2=250 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.1 bias_f=0.32 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch5st_sources_group2_matched30100.H: ${D}/ch5st_sources_group2.H ${D}/ch5st_matched_group2.H.bp30100
	./update_sources.sh $< $(word 2,$^).filter $@

${D}/ch5st_matched_group2.H.bp30150: ${D}/ch5st_fwi2d_0e_group2_syn.H.bp30150 ${D}/ch5st_data_group2.H.bp30150 ${D}/ch5st_mute_group2.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=200 max2=250 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=200 max2=250 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.15 bias_f=0.4 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch5st_sources_group2_matched30150.H: ${D}/ch5st_sources_group2.H ${D}/ch5st_matched_group2.H.bp30150
	./update_sources.sh $< $(word 2,$^).filter $@

# generate synthetics using the extended model and the matched sources
${D}/ch5st_fwi2d_0e_group2_syn_hf.H: ${D}/ch5st_sources_group2_matched30150.H ${D}/ch5st_fwi2d_0e_group2.H ${D}/ch5st_data_group2.HH
	./extended_model_synthetic.sh $< $(word 2,$^).ext $(word 3,$^) $@
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

###############################################################################################################
# run 2D FWI
###############################################################################################################

# mute |offset| < 200 m
${D}/ch5st_mute2_group2.H: ${D}/ch5st_mute_group2.H
	Window < $< f2=50 | Pad beg2=50 datapath=${OUT} > $@

# Build starting 2D B-spline model by least-squares from the initial model : BS x-spacing is 50 m
${D}/ch5st_model_2d.H: ${D}/ch5_model.H
	${B}/BSPLINES.x < $< nx=42 nz=101 niter=20 nthreads=12 bsoutput=$@.bs datapath=${OUT} > $@


# FWI + matched sources + B-splines + model extension, fixed threshold = 0.0003 translated to fixed niter to ensure reproducibility
${D}/ch5st_fwi2d_1.H: ${D}/ch5st_sources_group2_matched30100.H ${D}/ch5st_model_2d.H ${D}/ch5st_fwi2d_0e_group2.H ${D}/ch5st_data_group2.H ${D}/ch5st_mute2_group2.H ${D}/ch5_mask.H ${D}/ch5st_srcoord_group2.txt ${D}/ch5st_bp30100.H 
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 3, $^).model_iter_50.H data=$(word 4, $^) weights=$(word 5, $^) mask=$(word 6, $^) srcoord=$(word 7, $^) filter=$(word 8, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_strength=0.02 \
	device=1 verbose=1 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=42 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 normalize_obj_func=0 \
	damping_widthx=0.3 damping_widthz=0.05 damping_floor=0.9999 damping_power=6 lambda=0. xextension=0.0 zextension=-1 \
	nlsolver=lbfgs lbfgs_m=5 niter=64 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 isave=100 ioutput=$@. \
	2> $@.log

# starting from ch1st_fwi2d_1 and moving to higher frequencies
${D}/ch5st_fwi2d_2.H: ${D}/ch5st_sources_group2_matched30150.H ${D}/ch5st_fwi2d_1.H ${D}/ch5st_data_group2.H ${D}/ch5st_mute2_group2.H ${D}/ch5_mask.H ${D}/ch5st_srcoord_group2.txt ${D}/ch5st_bp30150.H 
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 2, $^).model_iter_64.H data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_strength=0.02 \
	device=1 verbose=1 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=42 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 normalize_obj_func=0 \
	damping_widthx=0.3 damping_widthz=0.05 damping_floor=0.9999 damping_power=6 lambda=0. xextension=0.0 zextension=-1 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 \
	2> $@.log

###############################################################################################################
# synthetic data from any given model
###############################################################################################################

.PRECIOUS: ${D}/ch5st_%.H.syn
${D}/ch5st_%.H.syn: ${D}/ch5st_sources_group2_matched30100.H ${D}/ch5st_%.H ${D}/ch5st_srcoord_group2.txt
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_strength=0.02 \
	device=0
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

.PRECIOUS: ${D}/ch5st_%.H.syn_hf
${D}/ch5st_%.H.syn_hf: ${D}/ch5st_sources_group2_matched30150.H ${D}/ch5st_%.H ${D}/ch5st_srcoord_group2.txt
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} verbose=3 \
	mt=1 fmax=250 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_strength=0.02 \
	device=3
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@

# generate synthetics using the extended model and the matched sources
${D}/ch5st_fwi2d_2_syn_hf.H: ${D}/ch5st_sources_group2_matched30150.H ${D}/ch5st_fwi2d_2.H ${D}/ch5st_data_group2.HH
	./extended_model_synthetic.sh $< $(word 2,$^).ext $(word 3,$^) $@
	echo o2=150 n2=501 d2=1 n3=16 o3=0 d3=1 >> $@



fwi_stimulated: ${D}/ch5st_fwi2d_2.H ${D}/ch5st_fwi2d_2_syn_hf.H.bp30150 \
${D}/ch5st_model_2d.H.syn_hf.bp30150 ${D}/ch5st_data_group2.H.bp30150 \
${D}/ch5st_data_group2.H.bp30100 ${D}/ch5st_syn3_group2_matched30100.H.bp30100 ${D}/ch5st_data_group2.H.fv