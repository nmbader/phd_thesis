##### 3D FWI for the stimulated reservoir #####

###############################################################################################################
# Mutes
###############################################################################################################

# keep positive offsets
${D}/ch6st_mute4_group1.H: ${D}/ch6un_mute3_group1.H
	Window < $< f2=600 | Pad beg2=600 datapath=${OUT} > $@

${D}/ch6st_mute4_group2.H: ${D}/ch6un_mute3_group2.H
	Window < $< f2=600 | Pad beg2=600 datapath=${OUT} > $@


# keep positive offsets for all times
${D}/ch6st_mute5_group1.H: ${D}/ch6un_mute_group1.H
	Window < $< f2=600 | Pad beg2=600 datapath=${OUT} > $@

${D}/ch6st_mute5_group2.H: ${D}/ch6un_mute_group1.H
	Window < $< f2=600 | Pad beg2=600 datapath=${OUT} > $@

###############################################################################################################
# estimate Matching filters between synthetic and field data using near offsets 0 to 200 m and early time < 0.2 sec
###############################################################################################################

${D}/ch6st_matched_group1.H.bp30100: ${D}/ch6un_syn_group1.H.bp30100 ${D}/ch6un_data_group1.H.bp30100 ${D}/ch6un_mute3_group1.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=0 max2=200 max1=0.2 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=0 max2=200 max1=0.2 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.1 bias_f=0.32 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch6st_sources_group1_matched30100.H: ${D}/ch6un_sources_group1.H ${D}/ch6st_matched_group1.H.bp30100
	./update_sources.sh $< $(word 2,$^).filter $@

${D}/ch6st_matched_group1.H.bp30150: ${D}/ch6un_syn_group1.H.bp30150 ${D}/ch6un_data_group1.H.bp30150 ${D}/ch6un_mute3_group1.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=0 max2=200 max1=0.2 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=0 max2=200 max1=0.2 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.15 bias_f=0.4 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch6st_sources_group1_matched30150.H: ${D}/ch6un_sources_group1.H ${D}/ch6st_matched_group1.H.bp30150
	./update_sources.sh $< $(word 2,$^).filter $@

${D}/ch6st_matched_group2.H.bp30100: ${D}/ch6un_syn_group2.H.bp30100 ${D}/ch6un_data_group2.H.bp30100 ${D}/ch6un_mute3_group2.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=0 max2=200 max1=0.2 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=0 max2=200 max1=0.2 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.1 bias_f=0.32 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch6st_sources_group2_matched30100.H: ${D}/ch6un_sources_group2.H ${D}/ch6st_matched_group2.H.bp30100
	./update_sources.sh $< $(word 2,$^).filter $@

${D}/ch6st_matched_group2.H.bp30150: ${D}/ch6un_syn_group2.H.bp30150 ${D}/ch6un_data_group2.H.bp30150 ${D}/ch6un_mute3_group2.H
	${Rm} test1.H test2.H
	Math file1=$< file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=0 max2=200 max1=0.2 datapath=${OUT} > test1.H
	Math file1=$(word 2,$^) file2=$(word 3,$^) exp='file1*file2' | Scale dscale=1 | Window min2=0 max2=200 max1=0.2 datapath=${OUT} > test2.H
	${B}/MATCHING.x < test1.H target=test2.H filter=$@.filter niter=5 filter_half_length=15 \
	t1=7 t2=11 t3=20 t4=24 stddev_t=0.12 bias_t=0.5 stddev_f=0.15 bias_f=0.4 verbose=1 | Scale dscale=1 datapath=${OUT} > $@
	${Rm} test1.H test2.H

${D}/ch6st_sources_group2_matched30150.H: ${D}/ch6un_sources_group2.H ${D}/ch6st_matched_group2.H.bp30150
	./update_sources.sh $< $(word 2,$^).filter $@

###############################################################################################################
# run 3D FWI
###############################################################################################################


# reference FWI with taper and mask, without Bsplines
${D}/ch6st_fwi3d_1.H: ${D}/ch6st_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6st_mute4_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
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
${D}/ch6st_fwi3d_1b.H: ${D}/ch6st_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6st_mute4_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
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
${D}/ch6st_fwi3d_2.H: ${D}/ch6st_sources_group2_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group2.H ${D}/ch6st_mute4_group2.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group2.txt ${D}/ch6un_bp30100.H 
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
${D}/ch6st_fwi3d_2b.H: ${D}/ch6st_sources_group2_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group2.H ${D}/ch6st_mute4_group2.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group2.txt ${D}/ch6un_bp30100.H 
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
${D}/ch6st_fwi3d_3.H: ${D}/ch6st_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6st_mute5_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
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
${D}/ch6st_fwi3d_3b.H: ${D}/ch6st_sources_group1_matched30100.H ${D}/ch6un_model_3d.H ${D}/ch6un_data_group1.H ${D}/ch6st_mute5_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30100.H 
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
${D}/ch6st_fwi3d_10b.H: ${D}/ch6st_sources_group1_matched30150.H ${D}/ch6st_fwi3d_1b.H ${D}/ch6un_data_group1.H ${D}/ch6st_mute4_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30150.H 
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
${D}/ch6st_fwi3d_12b.H: ${D}/ch6st_sources_group2_matched30150.H ${D}/ch6st_fwi3d_2b.H ${D}/ch6un_data_group2.H ${D}/ch6st_mute4_group2.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group2.txt ${D}/ch6un_bp30150.H 
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
# synthetic data
###############################################################################################################

${D}/ch6st_model_3d.H.syn_hf: ${D}/ch6st_sources_group1_matched30150.H ${D}/ch6un_model_3d.H ${D}/ch6un_srcoord_group1.txt
	${SRUN_MODELING11b} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=11 o3=0 d3=1 >> $@

${D}/ch6st_fwi3d_10b.H.syn_hf: ${D}/ch6st_sources_group1_matched30150.H ${D}/ch6st_fwi3d_10b.H ${D}/ch6un_srcoord_group1.txt
	${SRUN_MODELING11b} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=11 o3=0 d3=1 >> $@

${D}/ch6st_model_3d.H.syn_hf.bp30150: ${D}/ch6st_model_3d.H.syn_hf ${D}/ch6un_bp30150.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@

${D}/ch6st_fwi3d_10b.H.syn_hf.bp30150: ${D}/ch6st_fwi3d_10b.H.syn_hf ${D}/ch6un_bp30150.H
	${B}/FX_FILTER.x < $< filter=$(word 2,$^) datapath=${OUT} > $@



fwi_stimulated: ${D}/ch6st_fwi3d_10b.H ${D}/ch6st_fwi3d_12b.H ${D}/ch6un_data_group1.H.bp30150 ${D}/ch6st_model_3d.H.syn_hf.bp30150 ${D}/ch6st_fwi3d_10b.H.syn_hf.bp30150