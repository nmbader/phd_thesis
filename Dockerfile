FROM ubuntu:18.04 as builder
MAINTAINER nmbader@sep.stanford.edu
RUN apt-get -y update
RUN apt-get -y install build-essential
RUN apt-get -y install wget git git-lfs gcc g++ gfortran make cmake vim lsof
RUN apt-get -y install pkg-config
RUN apt-get -y install libtbb-dev libboost-all-dev  libboost-dev
RUN apt-get -y install libelf-dev libffi-dev
RUN apt-get -y install libfftw3-3 libfftw3-dev libssl-dev
RUN apt-get -y install flex libxaw7-dev
RUN apt-get -y install x11-apps
RUN apt-get -y install texlive-latex-extra texlive-fonts-recommended dvipng cm-super

RUN apt-get -y update
RUN apt-get -y install python3-pip
RUN python3 -m pip install --no-cache-dir --upgrade pip

RUN python3 -m pip install --no-cache-dir numpy &&\
    python3 -m pip install --no-cache-dir jupyter &&\
    python3 -m pip install --no-cache-dir scipy &&\
    python3 -m pip install --no-cache-dir pandas &&\
    python3 -m pip install --no-cache-dir wheel &&\
    python3 -m pip install --no-cache-dir scikit-build &&\
    python3 -m pip install --no-cache-dir matplotlib &&\
    python3 -m pip install --no-cache-dir MTfit &&\
    python3 -m pip install --no-cache-dir mpltern

RUN cd /tmp &&\
    wget https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1.tar.gz &&\
    cd /tmp/ &&\
    tar xzf /tmp/cmake-3.22.1.tar.gz &&\
    cd cmake-3.22.1 &&\
    cmake . &&\
    make -j 12  &&\
    make -j 12 install &&\
    cd ../ &&\
    rm -rf *

RUN git clone http://zapad.Stanford.EDU/bob/SEPlib.git  /opt/sep-main/src && \
    cd /opt/sep-main/src &&\
    git checkout b106d7f0f33be36b4e19b91095def70e40981307 &&\
    mkdir /opt/sep-main/build &&\
    cd /opt/sep-main/build &&\
    cmake  -DCMAKE_INSTALL_PREFIX=/opt/SEP ../src &&\
    make  -j 12  install &&\
    rm -rf /opt/sep-main


RUN mkdir -p /opt/ispc/bin
RUN mkdir -p /home
RUN mkdir -p /home/thesis
WORKDIR /home
RUN wget https://github.com/ispc/ispc/releases/download/v1.17.0/ispc-v1.17.0-linux.tar.gz  &&\
    tar -xvf ispc-v1.17.0-linux.tar.gz &&\
    cp ispc-v1.17.0-linux/bin/ispc /opt/ispc/bin/ &&\
    rm -f ispc-v1.17.0-linux.tar.gz  &&\
    rm -rf ispc-v1.17.0-linux

ADD . /home/thesis

RUN cd /home/thesis/code &&\
    git clone https://github.com/nmbader/fwi2d.git &&\
    cd fwi2d  &&\
    git checkout 1f3b6cb1a3e8ff90a101e2d8ea1fcdc2f8fc4c26  &&\
    mkdir -p build &&\
    cd external/SEP &&\
    bash ./buildit.sh &&\
    cd ../../build  &&\
    cmake -DCMAKE_INSTALL_PREFIX=../../local -DISPC_PATH=/opt/ispc/bin/ispc -DENABLE_DEV=1 ../  &&\
    make -j  &&\
    make install &&\
    cd ../ &&\
    rm -rf build &&\
    cd ../ &&\
    mkdir -p local_gpu &&\
    cp -R local/bin local_gpu/

RUN cd /home/thesis/code &&\
    git clone https://github.com/nmbader/fwi3d.git &&\
    cd fwi3d  &&\
    git checkout 34228f733cea69686d2ffb2ec6be104a42099ddb  &&\
    mkdir -p build &&\
    cd external/SEP &&\
    bash ./buildit.sh &&\
    cd ../../build  &&\
    cmake -DCMAKE_INSTALL_PREFIX=../../local ../ &&\
    make -j  &&\
    make install &&\
    cd ../ &&\
    rm -rf build

RUN cd /home/thesis/code &&\
    git clone --recursive --branch devel https://github.com/geodynamics/specfem2d.git &&\
    cd specfem2d &&\
    git checkout fd7926e7eae5f9c0f614cf7d06e56c768ca3a9a4 &&\
    ./configure FC=gfortran CC=gcc &&\
    make

RUN apt-get -y clean


ENV HOME=/home 
ENV PATH="/home/thesis/code/local/bin:/opt/SEP/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/SEP/lib:/opt/SEP/lib/python3.8:${LD_LIBARY_PATH}"
ENV DATAPATH="/tmp/"
ENV PYTHONPATH="/home/thesis/code/local/bin:/opt/SEP/lib/python3.8:${PYTHONPATH}"
RUN echo 'alias python=python3' >> ~/.bashrc