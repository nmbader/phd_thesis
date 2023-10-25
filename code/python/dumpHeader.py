#!/usr/bin/env python3
import numpy as np
import sys
import argparse
import seppy

if __name__ == "__main__":

	parser = argparse.ArgumentParser()
	parser.add_argument("--input", type=str, default="None", help="Input file in numpy or SEPlib format")
	args = parser.parse_args()

	sep = seppy.sep()

	axes, data = sep.read_file(args.input)
	pdat = data.reshape(axes.n,order='F').T

	shape=pdat.shape

	if pdat.ndim==3:
		na=shape[2]
		nx=shape[1]
		ns=shape[0]

	else:
		na=shape[1]
		nx=shape[0]
		ns=1
		pdat=np.reshape(pdat,(ns,nx,na))

	for s in range(ns):
		for x in range(nx):
			for a in range(na):
				print("%.5f" %(pdat[s,x,a]),end="\t")
			print("")
