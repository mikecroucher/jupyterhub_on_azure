# Build numpy from source with no optimised BLAS and LAPCK
apt install gcc -y

conda create -n BLAS-unoptimised Python=3.6 cython ipykernel
source /opt/conda/etc/profile.d/conda.sh
conda activate BLAS-unoptimised
wget https://github.com/numpy/numpy/archive/v1.17.4.tar.gz
tar -xzf ./v1.17.4.tar.gz
cd numpy-1.17.4/
conda deactivate
