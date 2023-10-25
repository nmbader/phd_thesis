##### some synthetic 3D modeling and sensitivity analysis #####


###############################################################################################################
# Inverse crime 3D FWI using unstimulated reservoir configuration
###############################################################################################################

# pseudo true model 
${D}/ch6an_pseudo_model.H: ${D}/ch6un_model_3d.H
	${Rm} temp1.H temp2.H temp3.H temp4.H temp5.H temp6.H temp7.H temp8.H
	Gauss n1=101 n2=761 n3=211 d1=0.001 d2=0.002 d3=0.002 o1=1.88 o2=0.5 o3=-0.31 maxvel=+10 var=0.000001 zero_at=0.001 max1=1.944 max3=-0.125 max2=1.0 | Smooth rect1=2 rect2=2 rect3=2 repeat=2 | Smooth rect2=21 rect3=21 repeat=3 | Scale | Scale dscale=0.1 | Pad beg4=1 | Pad end4=4 datapath=${OUT} > temp1.H
	Gauss n1=101 n2=761 n3=211 d1=0.001 d2=0.002 d3=0.002 o1=1.88 o2=0.5 o3=-0.31 maxvel=+10 var=0.000001 zero_at=0.001 max1=1.944 max3=-0.125 max2=1.2 | Smooth rect1=2 rect2=2 rect3=2 repeat=2 | Smooth rect2=21 rect3=21 repeat=3 | Scale | Scale dscale=0.1 | Pad end4=5 datapath=${OUT} > temp2.H
	Gauss n1=101 n2=761 n3=211 d1=0.001 d2=0.002 d3=0.002 o1=1.88 o2=0.5 o3=-0.31 maxvel=-10 var=0.000001 zero_at=0.001 max1=1.944 max3=-0.125 max2=1.4 | Smooth rect1=2 rect2=2 rect3=2 repeat=2 | Smooth rect2=21 rect3=21 repeat=3 | Scale | Scale dscale=0.1 | Pad beg4=1 | Pad end4=4 datapath=${OUT} > temp3.H
	Gauss n1=101 n2=761 n3=211 d1=0.001 d2=0.002 d3=0.002 o1=1.88 o2=0.5 o3=-0.31 maxvel=+10 var=0.000001 zero_at=0.001 max1=1.944 max3=-0.125 max2=1.6 | Smooth rect1=2 rect2=2 rect3=2 repeat=2 | Smooth rect2=21 rect3=21 repeat=3 | Scale | Scale dscale=0.1 | Pad end4=5 datapath=${OUT} > temp4.H
	Gauss n1=101 n2=761 n3=211 d1=0.001 d2=0.002 d3=0.002 o1=1.88 o2=0.5 o3=-0.31 maxvel=-10 var=0.000001 zero_at=0.001 max1=1.936 max3=-0.025 max2=1.0 | Smooth rect1=2 rect2=2 rect3=2 repeat=2 | Smooth rect2=21 rect3=21 repeat=3 | Scale | Scale dscale=0.1 | Pad end4=5 datapath=${OUT} > temp5.H
	Gauss n1=101 n2=761 n3=211 d1=0.001 d2=0.002 d3=0.002 o1=1.88 o2=0.5 o3=-0.31 maxvel=-10 var=0.000001 zero_at=0.001 max1=1.936 max3=-0.025 max2=1.2 | Smooth rect1=2 rect2=2 rect3=2 repeat=2 | Smooth rect2=21 rect3=21 repeat=3 | Scale | Scale dscale=0.1 | Pad beg4=1 | Pad end4=4 datapath=${OUT} > temp6.H
	Gauss n1=101 n2=761 n3=211 d1=0.001 d2=0.002 d3=0.002 o1=1.88 o2=0.5 o3=-0.31 maxvel=-10 var=0.000001 zero_at=0.001 max1=1.936 max3=-0.025 max2=1.4 | Smooth rect1=2 rect2=2 rect3=2 repeat=2 | Smooth rect2=21 rect3=21 repeat=3 | Scale | Scale dscale=0.1 | Pad end4=5 datapath=${OUT} > temp7.H
	Gauss n1=101 n2=761 n3=211 d1=0.001 d2=0.002 d3=0.002 o1=1.88 o2=0.5 o3=-0.31 maxvel=+10 var=0.000001 zero_at=0.001 max1=1.936 max3=-0.025 max2=1.6 | Smooth rect1=2 rect2=2 rect3=2 repeat=2 | Smooth rect2=21 rect3=21 repeat=3 | Scale | Scale dscale=0.1 | Pad beg4=1 | Pad end4=4 datapath=${OUT} > temp8.H
	Add $< temp1.H temp2.H temp3.H temp4.H temp5.H temp6.H temp7.H temp8.H datapath=${OUT} > $@
	${Rm} temp1.H temp2.H temp3.H temp4.H temp5.H temp6.H temp7.H temp8.H

# pseudo true data 
${D}/ch6an_true_data.H: ${D}/ch6un_sources_group1.H ${D}/ch6an_pseudo_model.H ${D}/ch6un_srcoord_group1.txt
	${SRUN_MODELING11b} ${B}/WE_MODELING_3D.x source=$< model=$(word 2, $^) srcoord=$(word 3, $^) output=$@ datapath=${OUT} format=0 \
	verbose=3 courant=0.55 dt=0 fmax=250 mt=1 seismotype=0 gl=0.01 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	2> $@.log
	echo o2=-600 n2=1201 d2=1 n3=11 o3=0 d3=1 >> $@

# reference FWI with taper and mask, without Bsplines
${D}/ch6an_fwi3d_1.H: ${D}/ch6un_sources_group1.H ${D}/ch6un_model_3d.H ${D}/ch6an_true_data.H ${D}/ch6un_mute4_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30150.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=0 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 \
	2> $@.log

# reference FWI with taper and mask, with Bsplines
${D}/ch6an_fwi3d_1b.H: ${D}/ch6un_sources_group1.H ${D}/ch6un_model_3d.H ${D}/ch6an_true_data.H ${D}/ch6un_mute4_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30150.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 2, $^).bs data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=1 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 \
	2> $@.log

# reference FWI with taper and mask, without Bsplines, full trace
${D}/ch6an_fwi3d_3.H: ${D}/ch6un_sources_group1.H ${D}/ch6un_model_3d.H ${D}/ch6an_true_data.H ${D}/ch6un_mute5_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30150.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=0 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 \
	2> $@.log

# reference FWI with taper and mask, without Bsplines, full trace, full offsets
${D}/ch6an_fwi3d_4.H: ${D}/ch6un_sources_group1.H ${D}/ch6un_model_3d.H ${D}/ch6an_true_data.H ${D}/ch6un_mute_group1.H ${D}/ch6un_mask_taper.H ${D}/ch6un_srcoord_group1.txt ${D}/ch6un_bp30150.H 
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) weights=$(word 4, $^) mask=$(word 5, $^) srcoord=$(word 6, $^) filter=$(word 7, $^) output=$@ obj_func=$@.func datapath=${OUT} format=0 \
	mt=1 seismotype=0 gl=0.01 fmax=250 \
	courant=0.55 dt=0 sub=-1 \
	taper_top=20 taper_bottom=20 taper_left=25 taper_right=25 taper_front=25 taper_back=25 bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_strength=0.1 \
	verbose=3 \
	normalize=0 envelop=0 \
	bsplines=0 bs_nx=62 bs_ny=18 bs_nz=101 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	regularization=-1 lambda=0.0 normalize_obj_func=0 \
	nlsolver=lbfgs lbfgs_m=5 niter=20 threshold=0.0 max_trial=5 ls_c1=1e-3 ls_c2=0.9 \
	2> $@.log

sensitivity_analysis: ${D}/ch6an_fwi3d_1b.H ${D}/ch6an_pseudo_model.H