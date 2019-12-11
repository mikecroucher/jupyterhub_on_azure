#!/bin/bash
# THe point of this demo is to show that different implementations of BLAS matter a lot
# Provide kernels that just contain numpy and a BLAS

# Build numpy from source with no optimised BLAS and LAPCK
apt install gcc -y

source /opt/conda/etc/profile.d/conda.sh
conda create -n BLAS-unoptimised Python=3.6 cython ipykernel -y
conda activate BLAS-unoptimised
wget https://github.com/numpy/numpy/archive/v1.17.4.tar.gz
tar -xzf ./v1.17.4.tar.gz
cd numpy-1.17.4/
BLAS=None LAPACK=None ATLAS=None python setup.py install
conda deactivate
echo "Multiblas script finished"

## OpenBLAS
conda create -n BLAS-OpenBLAS Python=3.6 nomkl numpy ipykernel -y

## MKL
conda create -n BLAS-MKL Python=3.6 numpy ipykernel -y
