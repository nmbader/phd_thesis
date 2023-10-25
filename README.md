# PhD dissertation: SEISMIC SOURCE AND ELASTIC FULL-WAVEFORM INVERSION USING DISTRIBUTED ACOUSTIC SENSING AND PERFORATION SHOTS IN UNCONVENTIONAL RESERVOIRS

- [Description](#Description)
- [Installation with Docker](#Installation-with-Docker)
- [Installation with Docker with GPU enabled](#Installation-with-Docker-with-GPU-enabled)
- [Running jupyter notebook](#Running-jupyter-notebook)
- [Reproducing thesis results](#Reproducing-thesis-results)
- [Getting the input field data](#Getting-the-input-field-data)

## Description

This project aims at reproducing the results in the PhD dissertation "**SEISMIC SOURCE AND ELASTIC FULL-WAVEFORM INVERSION USING DISTRIBUTED ACOUSTIC SENSING AND PERFORATION SHOTS IN UNCONVENTIONAL RESERVOIRS**" published by Stanford University in 2023 and authored by *Milad Bader*.

## Installation with Docker

Build the docker image (it should take about 15 minutes)
```
docker build -f Dockerfile -t phd23 .
```

Then run a container
```
docker run -it -p 8080:8080 phd23
```

By default a bash shell will be opened at */home* inside the container.

## Installation with Docker with GPU enabled

FWI (in 2D) will run much faster if a CUDA enabled GPU is available. Repeat the process above after replacing 'Dockerfile' with 'Dockerfile_gpu'.

## Running jupyter notebook

Run jupyter notebook from within the container
```
jupyter notebook --ip 0.0.0.0 --port 8080 --no-browser --allow-root &
```

Open the browser at *localhost:8080/​* and use the printed token to authenticate.

## Reproducing thesis results

To reproduce the field data results figuring in the Phd dissertation, the starting DAS data and well logs must be copied into */home/thesis/input_data* (see next section). Otherwise, only the synthetic data results and corresponding figures in Chapters 2, 3, and 5 can be reproduced. In all cases, it is best (and even necessary) to reproduce the results sequentially (Chapter 2 then 3 then 4 etc.).

* Chapter 2

Go to */home/thesis/chapters/ch2/notebooks* and run both notebooks (in whichever order).

* Chapter 3

Go to */home/thesis/chapters/ch3/notebooks* and run the notebook.

* Chapter 4

Go first to */home/thesis/chapters/ch0/notebooks* and run the notebook. This requires the *input_data* directory. Then, go to */home/thesis/chapters/ch4* and run
```
make all
``` 
from the terminal. Peek into the Makefile to see what is happening.
Finally, go to */home/thesis/chapters/ch4/notebooks* and run the notebooks *Radiation_pattern*, *MT_inversion_unstimulated*, *MT_inversion_stimulated*, and *MT_inversion_3d*.

* Chapter 5 (and Appendix D)

Go to */home/thesis/chapters/ch5*.
To generate synthetic FWI results and figures, run
```
make all_synthetic
```
then go to the *notebooks* directory and run the notebook *Synthetic_figures*.
For the field data results and figures, assuming *input_data* is available and Chapter 4 results have been generated, follow these steps:
- run ```make prepare_data```
- run the notebook *Data_selection*
- run ```make prepare_avo```
- run the notebook *AVO_estimation*
- run ```make fwi_unstimulated``` and ```make fwi_stimulated``` (it will take a while)
- run the notebooks *Dispersion_analysis*, *Field_figures_thesis*, and *ST_effects*

* Chapter 6

The computation and results in this chapter were performed using Stanford HPC cluster Sherlock and could take hours to days to complete. Go to */home/thesis/chapters/ch6* and follow the instructions in the *Makefile*. For the FWI results, it may be better to submit each computation job manually using Slurm (check for the corresponding targets in the make files). Slurm script examples are provided.

* Appendix E

Go to */home/thesis/chapters/ch99/notebooks* and run the notebook *Attenuation_modeling*.

## Getting the input field data

The field data is stored in a separate git repository as a .tar lfs file. If permissions are granted, follow these steps to copy the data into the appropriate location:
```
cd /home
git clone https://premonition.Stanford.EDU/nmbader/phd_dissertation.git
cp phd_dissertation/input_data.tar /home/thesis/
cd /home/thesis/
tar -xvf input_data.tar
rm input_data.tar
```