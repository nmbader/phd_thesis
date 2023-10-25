#!/bin/bash
#
# script runs mesher and solver (in serial)
# using this example setup
#

echo "running SPECFEM2D to model particle velocity with provided source time function in txt file: `date`"
currentdir=`pwd`
echo ${currentdir}
echo

echo
echo "(will take about 5 minutes)"
echo

# sets up directory structure in current example directoy
echo
echo "   setting up the test"
echo

cd ../dat/

rm -rf OUTPUT_FILES
rm -rf DATA

mkdir -p OUTPUT_FILES
mkdir -p DATA

# sets up local DATA/ directory
cd DATA/
ln -s ../../specfem2d/par1.p Par_file
ln -s ../../specfem2d/src1.p SOURCE

# set up the interface for internal mesh
rm -f INTERFACE.txt
cp ../../specfem2d/interface1.p INTERFACE.txt

# links executables
cd ../
rm -f xmeshfem2D xspecfem2D
ln -s ../../../code/specfem2d/bin/xmeshfem2D
ln -s ../../../code/specfem2d/bin/xspecfem2D

# stores setup
cp DATA/Par_file OUTPUT_FILES/
cp DATA/SOURCE OUTPUT_FILES/

# runs database generation
echo
echo "  running mesher..."
echo
./xmeshfem2D

# runs simulation
echo
echo "  running solver..."
echo
./xspecfem2D

# stores output
cp DATA/*SOURCE* DATA/*STATIONS* OUTPUT_FILES

echo
echo "see results in directory: OUTPUT_FILES/"
echo
echo "done"
date

cd $currentdir
