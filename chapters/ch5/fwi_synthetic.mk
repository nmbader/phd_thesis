##### 2D FWI using synthetics #####
# 'make all_synthetic' then run Synthetic_figures notebook to generate figures

###############################################################################################################
# Generate source
###############################################################################################################

# true wavelet
${D}/ch5sy_wavelet0.H:
	GENERATE_WAVELET.x nt=201 dt=0.01 type=ricker wc=0.2 phase=zero shift=20 | Window f1=80 n1=101 | Scale datapath=${OUT} > $@

# add noise the wavelet
${D}/ch5sy_wavelet1.H: ${D}/ch5sy_wavelet0.H
	${Rm} noise.H filter.H filtered_noise.H envelop.H final_noise.H
	${B}/NOISE.x < $< type=normal mean=0 sigma=0.3 replace=1 seed=1234 datapath=${OUT} > noise.H
	GENERATE_WAVELET.x nt=101 dt=0.01 type=ricker wc=0.2 phase=zero | Scale datapath=${OUT} > filter.H
	${B}/FX_FILTER.x < noise.H filter=filter.H datapath=${OUT} > filtered_noise.H
	HILBERT.x < $< type=envelop datapath=${OUT} > envelop.H
	Math file1=filtered_noise.H file2=envelop.H exp='file1*file2' datapath=${OUT} > final_noise.H
	Add $< final_noise.H | Scale datapath=${OUT} > $@
	${Rm} noise.H filter.H filtered_noise.H envelop.H final_noise.H

# true moment tensor
mxx0=1
mzz0=0.75
mxz0=0

# distorted moment tensor
mxx1=0.9
mzz1=0.8675
mxz1=0

# true source location
sx0=0.4

# modified source location
sx1=0.399

###############################################################################################################
# homogeneous models and sensitivity kernels
###############################################################################################################

${D}/ch5sy_acoustic_model.H:
	${Rm} vp.H rho.H
	Vel n1=201 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 vc=3.0 datapath=${OUT} > vp.H
	Vel n1=201 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 vc=2.0 datapath=${OUT} > rho.H
	Cat vp.H rho.H axis=3 datapath=${OUT} > $@
	${Rm} vp.H rho.H

${D}/ch5sy_elastic_model.H:
	${Rm} vp.H vs.H rho.H
	Vel n1=201 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 vc=3.0 datapath=${OUT} > vp.H
	Vel n1=201 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 vc=1.5 datapath=${OUT} > vs.H
	Vel n1=201 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 vc=2.0 datapath=${OUT} > rho.H
	Cat vp.H vs.H rho.H axis=3 datapath=${OUT} > $@
	${Rm} vp.H vs.H rho.H

${D}/ch5sy_elastic_model_3d.H:
	${Rm} vp.H vs.H rho.H
	Vel n1=201 n2=201 n3=201 o1=0 o2=0 o3=-1 d1=0.010 d2=0.010 d3=0.01 n4=1 o4=0 d4=1 vc=3.0 datapath=${OUT} > vp.H
	Vel n1=201 n2=201 n3=201 o1=0 o2=0 o3=-1 d1=0.010 d2=0.010 d3=0.01 n4=1 o4=0 d4=1 vc=1.5 datapath=${OUT} > vs.H
	Vel n1=201 n2=201 n3=201 o1=0 o2=0 o3=-1 d1=0.010 d2=0.010 d3=0.01 n4=1 o4=0 d4=1 vc=2.0 datapath=${OUT} > rho.H
	Cat vp.H vs.H rho.H axis=4 datapath=${OUT} > $@
	${Rm} vp.H vs.H rho.H

# single trace data
${D}/ch5sy_acoustic_data.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_acoustic_model.H
	${B}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) output=$@ datapath=${OUT} \
	ns=1 sx0=0.8 sz0=1.0 sxinc=0 szinc=0 nr=1 rx0=1.2 rz0=1.0 rxinc=0.0 rzinc=0 \
	seismotype=0 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=0 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=3

${D}/ch5sy_elastic_data.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_elastic_model.H
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) output=$@ datapath=${OUT} \
	ns=1 sx0=0.8 sz0=1.0 sxinc=0 szinc=0 nr=1 rx0=1.2 rz0=1.0 rxinc=0.0 rzinc=0 \
	mt=0 fangle=0 \
	seismotype=0 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=0 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=3

${D}/ch5sy_elastic_data_mt.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_elastic_model.H
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) output=$@ datapath=${OUT} \
	ns=1 sx0=0.8 sz0=1.0 sxinc=0 szinc=0 nr=1 rx0=1.2 rz0=1.0 rxinc=0.0 rzinc=0 \
	mt=1 mxx=1 mzz=0 mxz=0 \
	seismotype=0 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=0 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=3

${D}/ch5sy_elastic_data_3d.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_elastic_model_3d.H
	${B}/WE_MODELING_3D.x source=$(word 1, $^) model=$(word 2, $^) output=$@ datapath=${OUT} \
	ns=1 sx0=0.8 sy0=0.0 sz0=1.0 sxinc=0 szinc=0 nr=1 rx0=1.2 ry0=0.0 rz0=1.0 rxinc=0.0 rzinc=0 \
	mt=0 fangle=0 \
	seismotype=0 gl=0.0 fmax=25 \
	courant=0.55 dt=0 sub=0 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_front=30 taper_back=30 taper_strength=0.1 \
	verbose=3

# data shifted one sample
${D}/ch5sy_acoustic_data.H.shift: ${D}/ch5sy_acoustic_data.H
	Pad < $< beg1=1 | Window n1=101 datapath=${OUT} > $@
	echo o1=0 >> $@

${D}/ch5sy_elastic_data.H.shift: ${D}/ch5sy_elastic_data.H
	Pad < $< beg1=1 | Window n1=101 datapath=${OUT} > $@
	echo o1=0 >> $@

${D}/ch5sy_elastic_data_mt.H.shift: ${D}/ch5sy_elastic_data_mt.H
	Pad < $< beg1=1 | Window n1=101 datapath=${OUT} > $@
	echo o1=0 >> $@

${D}/ch5sy_elastic_data_3d.H.shift: ${D}/ch5sy_elastic_data_3d.H
	Pad < $< beg1=1 | Window n1=101 datapath=${OUT} > $@
	echo o1=0 >> $@

${D}/ch5sy_acoustic_kernel.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_acoustic_model.H ${D}/ch5sy_acoustic_data.H.shift
	${B}/FWI2D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) output=$@ datapath=${OUT} \
	ns=1 sx0=0.8 sz0=1.0 sxinc=0 szinc=0 nr=1 rx0=1.2 rz0=1.0 rxinc=0.0 rzinc=0 \
	seismotype=0 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=3 \
	niter=1 max_trial=0 isave=1 ioutput=$@.

${D}/ch5sy_elastic_kernel.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_elastic_model.H ${D}/ch5sy_elastic_data.H.shift
	${BG}/FWI2D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) output=$@ datapath=${OUT} \
	ns=1 sx0=0.8 sz0=1.0 sxinc=0 szinc=0 nr=1 rx0=1.2 rz0=1.0 rxinc=0.0 rzinc=0 \
	mt=0 fangle=0 \
	seismotype=0 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=3 \
	niter=1 max_trial=0 isave=1 ioutput=$@.

${D}/ch5sy_elastic_kernel_mt.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_elastic_model.H ${D}/ch5sy_elastic_data_mt.H.shift
	${BG}/FWI2D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) output=$@ datapath=${OUT} \
	ns=1 sx0=0.8 sz0=1.0 sxinc=0 szinc=0 nr=1 rx0=1.2 rz0=1.0 rxinc=0.0 rzinc=0 \
	mt=1 mxx=1 mzz=0 mxz=0 \
	seismotype=0 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=3 \
	niter=1 max_trial=0 isave=1 ioutput=$@.

${D}/ch5sy_elastic_kernel_3d.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_elastic_model_3d.H ${D}/ch5sy_elastic_data_3d.H.shift
	${B}/FWI3D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) output=$@ datapath=${OUT} \
	ns=1 sx0=0.8 sy0=0.0 sz0=1.0 sxinc=0 szinc=0 nr=1 rx0=1.2 ry0=0.0 rz0=1.0 rxinc=0.0 rzinc=0 \
	mt=0 fangle=0 faz=0 \
	seismotype=0 gl=0.0 fmax=25 \
	courant=0.55 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 bc_front=2 bc_back=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_front=30 taper_back=30 taper_strength=0.1 \
	verbose=3 \
	niter=1 max_trial=0 isave=1 ioutput=$@.

###############################################################################################################
# Generate model, and data
###############################################################################################################

# initial model
${D}/ch5sy_model0.H:
	${Rm} vp.H vs.H rho.H
	Vel n1=101 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 z1=0.4 vr1=3.0 const1=1 z2=0.6 vr2=5.5 const2=1 vc=4.5 datapath=${OUT} > vp.H
	Vel n1=101 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 z1=0.4 vr1=1.7 const1=1 z2=0.6 vr2=2.7 const2=1 vc=2.3 datapath=${OUT} > vs.H
	Vel n1=101 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 z1=0.4 vr1=2.0 const1=1 z2=0.6 vr2=2.5 const2=1 vc=2.3 datapath=${OUT} > rho.H
	Cat vp.H vs.H rho.H axis=3 | Smooth rect1=2 repeat=3 datapath=${OUT} > $@
#	Cat vp.H vs.H rho.H axis=3 datapath=${OUT} > $@
	${Rm} vp.H vs.H rho.H

# true model
${D}/ch5sy_model1.H: ${D}/ch5sy_model0.H
	${Rm} vp1.H vp2.H vp3.H vp.H vs1.H vs2.H vs3.H vs.H model.H
	Gauss n1=101 n2=201 n3=1 d1=0.01 d2=0.01 d3=1 maxvel=-0.5 var=0.0004 max1=0.5 max2=1.0 zero_at=0.1 datapath=${OUT} > vp1.H
	Gauss n1=101 n2=201 n3=1 d1=0.01 d2=0.01 d3=1 maxvel=+0.5 var=0.0004 max1=0.5 max2=0.5 zero_at=0.1 datapath=${OUT} > vp2.H
#	Gauss n1=101 n2=201 n3=1 d1=0.01 d2=0.01 d3=1 maxvel=-0.5 var=0.0004 max1=0.5 max2=1.5 zero_at=0.1 datapath=${OUT} > vp3.H
	Gauss n1=101 n2=201 n3=1 d1=0.01 d2=0.01 d3=1 maxvel=-0.4 var=0.0004 max1=0.5 max2=1.0 zero_at=0.1 datapath=${OUT} > vs1.H
	Gauss n1=101 n2=201 n3=1 d1=0.01 d2=0.01 d3=1 maxvel=+0.4 var=0.0004 max1=0.5 max2=0.5 zero_at=0.1 datapath=${OUT} > vs2.H
#	Gauss n1=101 n2=201 n3=1 d1=0.01 d2=0.01 d3=1 maxvel=-0.4 var=0.0004 max1=0.5 max2=1.5 zero_at=0.1 datapath=${OUT} > vs3.H
	Add vp1.H vp2.H datapath=${OUT} > vp.H
	Add vs1.H vs2.H datapath=${OUT} > vs.H
	Cat vp.H vs.H axis=3 | Pad end3=1 extend=0 datapath=${OUT} > model.H
	Add $< model.H datapath=${OUT} > $@
	${Rm} vp1.H vp2.H vp3.H vp.H vs1.H vs2.H vs3.H vs.H model.H

# mask
${D}/ch5sy_mask0.H:
	Vel n1=101 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 z1=0.4 vr1=1 const1=1 z2=0.6 vr2=0 const2=1 vc=0 | Smooth rect1=2 repeat=3 | Pad end3=1 extend=1 | Pad end3=1 extend=0 datapath=${OUT} > $@
#	Vel n1=101 n2=201 o1=0 o2=0 d1=0.010 d2=0.010 n3=1 o3=0 d3=1 z1=0.4 vr1=1 const1=1 z2=0.6 vr2=0 const2=1 vc=0 | Pad end3=1 extend=1 | Pad end3=1 extend=0 datapath=${OUT} > $@

# true data
${D}/ch5sy_data0.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_model1.H
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) output=$@ datapath=${OUT} \
	ns=3 sx0=${sx0} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx0} mzz=${mzz0} mxz=${mxz0} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=0 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=3
	echo n2=141 n3=3 n4=2 >> $@

# Add filtered noise to the data
${D}/ch5sy_data0_noisy.H: ${D}/ch5sy_data0.H
	${Rm} noise.H filter.H filtered_noise.H
	${B}/NOISE.x < $< type=normal mean=0 sigma=0.25 replace=1 seed=1234  datapath=${OUT} > noise.H
	GENERATE_WAVELET.x nt=101 dt=0.01 type=ricker wc=0.2 phase=zero | Scale datapath=${OUT} > filter.H
	${B}/FX_FILTER.x < noise.H filter=filter.H datapath=${OUT} > filtered_noise.H
	Add $< filtered_noise.H datapath=${OUT} > $@
	${Rm} noise.H filter.H filtered_noise.H

# data mute for near offsets
${D}/ch5sy_mute0.H: ${D}/ch5sy_data0.H
	${Rm} temp1a.H temp1b.H temp2a.H temp2b.H temp2c.H temp3a.H temp3b.H
	Window < $< n3=1 n4=1 f2=31 datapath=${OUT} > temp1a.H
	Math file1=temp1a.H exp='0*file1+1' | Pad beg2=31 extend=0 datapath=${OUT} > temp1b.H
	Window < $< n3=1 n4=1 n2=50 datapath=${OUT} > temp2a.H
	Math file1=temp2a.H exp='0*file1+1' | Pad end2=41 extend=0 datapath=${OUT} > temp2b.H
	Math file1=temp2a.H exp='0*file1+1' datapath=${OUT} > temp2c.H
	Cat temp2b.H temp2c.H axis=2 datapath=${OUT} > temp2d.H
	Window < $< n3=1 n4=1 n2=110 datapath=${OUT} > temp3a.H
	Math file1=temp3a.H exp='0*file1+1' | Pad end2=31 extend=0  datapath=${OUT} > temp3b.H
	Cat temp1b.H temp2d.H temp3b.H axis=3 | Pad end4=1 extend=1 datapath=${OUT} > $@
	${Rm} temp1a.H temp1b.H temp2a.H temp2b.H temp2c.H temp2d.H temp3a.H temp3b.H

###############################################################################################################
# approximate inverse pseudo-Hessian
###############################################################################################################

# data with incorrect sources
${D}/ch5sy_data1.H: ${D}/ch5sy_wavelet1.H ${D}/ch5sy_model0.H
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) output=$@ wavefield=$@.wfld datapath=${OUT} \
	ns=3 sx0=${sx1} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx1} mzz=${mzz1} mxz=${mxz1} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=3
	echo n2=141 n3=3 n4=2 >> $@

# data with correct sources
${D}/ch5sy_data2.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_model0.H
	${BG}/WE_MODELING.x source=$(word 1, $^) model=$(word 2, $^) output=$@ wavefield=$@.wfld datapath=${OUT} \
	ns=3 sx0=${sx0} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx0} mzz=${mzz0} mxz=${mxz0} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=3
	echo n2=141 n3=3 n4=2 >> $@

# kinetic energy density stacked over time and summed over shots
${D}/ch5sy_data1.H.illumination: ${D}/ch5sy_data1.H ${D}/ch5sy_model0.H
	${Rm} temp.H temp2.H vx.H vz.H rho.H
	Window3d < $<.wfld n3=1 f3=0 datapath=${OUT} > vx.H
	Window3d < $<.wfld n3=1 f3=1 datapath=${OUT} > vz.H
	Window < $(word 2, $^) n3=1 f3=2 datapath=${OUT} > rho.H
	Math file1=vx.H file2=vz.H exp='file1^2+file2^2' datapath=${OUT} > temp.H
	Reshape < temp.H reshape=2,3,4 maxsize=500 | Stack axes=3 maxsize=500 datapath=${OUT} > temp2.H
	echo n1=101 n2=201 o1=0 o2=0 d1=0.01 d2=0.01 n3=1 >> temp2.H
	Math file1=temp2.H file2=rho.H exp='0.5*file1*file2' datapath=${OUT} > $@
	${Rm} temp.H temp2.H vx.H vz.H rho.H

# illumination compensation by clipping, smoothing and inverting the above
${D}/ch5sy_data1.H.invHessian: ${D}/ch5sy_data1.H.illumination
	${Rm} temp.H
#	Scale < $< | Clip clip=0.01 chop=less datapath=${OUT} > temp.H
	Math file1=$< exp='(file1-0.05)*(@SGN(file1-0.05)+1)*0.5+0.05' datapath=${OUT} > temp.H
	Math file1=temp.H exp='1.0/file1' | Scale | Pad end3=2 extend=1 datapath=${OUT} > $@
	${Rm} temp.H

###############################################################################################################
# Run conventional elastic FWI to assess the effects of several variables
# Fix the number of iterations for reproducibility (after having tested threshold) - see Geophysics paper for details
###############################################################################################################

# reference FWI
${D}/ch5sy_fwi0.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_model0.H ${D}/ch5sy_data0.H ${D}/ch5sy_mask0.H
	${BG}/FWI2D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) mask=$(word 4, $^) datapath=${OUT} output=$@ obj_func=$@.func \
	ns=3 sx0=${sx0} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx0} mzz=${mzz0} mxz=${mxz0} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=1 device=2 \
	bsplines=0 bs_nx=51 bs_nz=101 soft_clip=1 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	niter=120 max_trial=5 lbfgs_m=5 ls_c1=1e-3 ls_c2=0.9 threshold=0.0 isave=200 ioutput=$@. \
	2> $@.log

# effect of source wavelet distortion + source mechanism error + source location error
${D}/ch5sy_fwi5.H: ${D}/ch5sy_wavelet1.H ${D}/ch5sy_model0.H ${D}/ch5sy_data0.H ${D}/ch5sy_mask0.H
	${BG}/FWI2D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) mask=$(word 4, $^) datapath=${OUT} output=$@ obj_func=$@.func \
	ns=3 sx0=${sx1} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx1} mzz=${mzz1} mxz=${mxz1} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=1 device=2 \
	bsplines=0 bs_nx=51 bs_nz=101 soft_clip=1 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	niter=50 max_trial=5 lbfgs_m=5 ls_c1=1e-3 ls_c2=0.9 threshold=0.0 isave=50 ioutput=$@. \
	2> $@.log

###############################################################################################################
# Try different approaches to cope with artifacts
# extension along sources - suffix 'e'
# mute near offsets < 200 m - suffix 'm'
# B-splines - suffix 'b'
# gradient preconditioning by inverse pseudo-Hessian - suffix 'h'
# heuristic gradient preconditioning - suffix 'p'
# 2nd order Tikhonov regularization - suffix 'r'
###############################################################################################################

${D}/ch5sy_model0_ibs.H: ${D}/ch5sy_model0.H
	${B}/BSPLINES.x < $< nx=51 nz=101 niter=10 bsoutput=$@.bs datapath=${OUT} > $@

${D}/ch5sy_model0.H.ext: ${D}/ch5sy_model0.H
	Pad < $< end4=2 extend=1 datapath=${OUT} > $@

${D}/ch5sy_model0.H.cp: ${D}/ch5sy_model0.H
	Cp < $< > $@

${D}/ch5sy_fwi0e.H: ${D}/ch5sy_wavelet0.H ${D}/ch5sy_model0.H ${D}/ch5sy_data0.H ${D}/ch5sy_mask0.H
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) mask=$(word 4, $^) datapath=${OUT} output=$@ obj_func=$@.func \
	ns=3 sx0=${sx0} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx0} mzz=${mzz0} mxz=${mxz0} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=1 device=3 \
	bsplines=0 bs_nx=51 bs_nz=101 soft_clip=1 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	niter=120 max_trial=5 lbfgs_m=5 ls_c1=1e-3 ls_c2=0.9 threshold=0.0 isave=200 ioutput=$@. \
	damping_widthx=0.2 damping_widthz=0.2 damping_floor=0.999 damping_power=6 lambda=5 xextension=0 zextension=-1 extension_weights=$@.weights \
	2> $@.log

${D}/ch5sy_fwi5e.H: ${D}/ch5sy_wavelet1.H ${D}/ch5sy_model0.H ${D}/ch5sy_data0.H ${D}/ch5sy_mask0.H
	${BG}/FWI2D_MODEL_EXTENSION.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) mask=$(word 4, $^) datapath=${OUT} output=$@ obj_func=$@.func \
	ns=3 sx0=${sx1} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx1} mzz=${mzz1} mxz=${mxz1} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=1 device=3 \
	bsplines=0 bs_nx=51 bs_nz=101 soft_clip=1 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	niter=50 max_trial=5 lbfgs_m=5 ls_c1=1e-3 ls_c2=0.9 threshold=0.0 isave=100 ioutput=$@. \
	damping_widthx=0.2 damping_widthz=0.2 damping_floor=0.999 damping_power=6 lambda=5 xextension=0 zextension=-1 \
	2> $@.log

${D}/ch5sy_fwi5m.H: ${D}/ch5sy_wavelet1.H ${D}/ch5sy_model0.H ${D}/ch5sy_data0.H ${D}/ch5sy_mask0.H ${D}/ch5sy_mute0.H
	${BG}/FWI2D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) mask=$(word 4, $^) weights=$(word 5, $^) datapath=${OUT} output=$@ obj_func=$@.func \
	ns=3 sx0=${sx1} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx1} mzz=${mzz1} mxz=${mxz1} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=1 device=0 \
	bsplines=0 bs_nx=51 bs_nz=101 soft_clip=1 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	niter=50 max_trial=5 lbfgs_m=5 ls_c1=1e-3 ls_c2=0.9 threshold=0.0 isave=50 ioutput=$@. \
	2> $@.log

${D}/ch5sy_fwi5mb.H: ${D}/ch5sy_wavelet1.H ${D}/ch5sy_model0_ibs.H ${D}/ch5sy_model0_ibs.H.bs ${D}/ch5sy_data0.H ${D}/ch5sy_mask0.H ${D}/ch5sy_mute0.H
	${BG}/FWI2D.x source=$(word 1, $^) model=$(word 2, $^) bsmodel=$(word 3, $^) data=$(word 4, $^) mask=$(word 5, $^) weights=$(word 6, $^) datapath=${OUT} output=$@ obj_func=$@.func \
	ns=3 sx0=${sx1} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx1} mzz=${mzz1} mxz=${mxz1} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=1 device=1 \
	bsplines=1 bs_nx=51 bs_nz=101 soft_clip=1 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	niter=50 max_trial=5 lbfgs_m=5 ls_c1=1e-3 ls_c2=0.9 threshold=0.0 isave=50 ioutput=$@. \
	2> $@.log

${D}/ch5sy_fwi5mh.H: ${D}/ch5sy_wavelet1.H ${D}/ch5sy_model0.H ${D}/ch5sy_data0.H ${D}/ch5sy_mask0.H ${D}/ch5sy_mute0.H ${D}/ch5sy_data1.H.invHessian
	${BG}/FWI2D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) mask=$(word 4, $^) weights=$(word 5, $^) inverse_diagonal_hessian=$(word 6, $^) datapath=${OUT} output=$@ obj_func=$@.func \
	ns=3 sx0=${sx1} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx1} mzz=${mzz1} mxz=${mxz1} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=1 device=2 \
	bsplines=0 bs_nx=51 bs_nz=101 soft_clip=1 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	niter=50 max_trial=7 lbfgs_m=5 ls_c1=1e-3 ls_c2=0.9 threshold=0.0 isave=50 ioutput=$@. \
	2> $@.log

${D}/ch5sy_fwi5p.H: ${D}/ch5sy_wavelet1.H ${D}/ch5sy_model0.H ${D}/ch5sy_data0.H ${D}/ch5sy_mask0.H
	${BG}/FWI2D.x source=$(word 1, $^) model=$(word 2, $^) data=$(word 3, $^) mask=$(word 4, $^) datapath=${OUT} output=$@ obj_func=$@.func \
	ns=3 sx0=${sx1} sz0=0.5 sxinc=0.6 szinc=0 nr=141 rx0=0.3 rz0=0.5 rxinc=0.01 rzinc=0 \
	mt=1 mxx=${mxx1} mzz=${mzz1} mxz=${mxz1} seismotype=1 gl=0.0 fmax=25 \
	courant=0.6 dt=0 sub=-1 \
	bc_top=2 bc_bottom=2 bc_left=2 bc_right=2 taper_top=30 taper_bottom=30 taper_left=30 taper_right=30 taper_strength=0.1 \
	verbose=1 device=3 \
	bsplines=0 bs_nx=51 bs_nz=101 soft_clip=1 \
	vpmin=2 vpmax=6.2 vsmin=1 vsmax=3.6 rhomin=2 rhomax=3 soft_clip=1 model_parameterization=1 \
	niter=50 max_trial=5 lbfgs_m=5 ls_c1=1e-3 ls_c2=0.9 threshold=0.0 isave=50 ioutput=$@. \
	gradient_preconditioning=1 damping_widthx=0.2 damping_widthz=0.2 damping_floor=0.999 damping_power=6 lambda=5 xextension=0 zextension=-1 \
	2> $@.log

###############################################################################################################
# make all what is needed for figures
###############################################################################################################

all_synthetic: ${D}/ch5sy_fwi0.H ${D}/ch5sy_fwi0e.H ${D}/ch5sy_fwi5.H ${D}/ch5sy_fwi5e.H ${D}/ch5sy_fwi5m.H ${D}/ch5sy_fwi5mb.H ${D}/ch5sy_fwi5mh.H ${D}/ch5sy_fwi5p.H \
${D}/ch5sy_acoustic_kernel.H ${D}/ch5sy_elastic_kernel.H ${D}/ch5sy_elastic_kernel_mt.H