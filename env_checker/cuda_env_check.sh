#!/bin/bash

# List available conda environments
echo "Available conda environments:"
envs=($(conda env list | grep -v '#' | awk '{print $1}'))
if [ ${#envs[@]} -eq 0 ]; then
    echo "No conda environments found."
    exit 1
fi

# Display the list and prompt for selection
echo "Please select a conda environment:"
select env in "${envs[@]}"; do
    if [ -n "$env" ]; then
        CONDA_ENV_NAME="$env"
        echo "You selected: $CONDA_ENV_NAME"
        break
    else
        echo "Invalid selection. Try again."
    fi
done

# Activate the selected conda environment
echo "Activating the conda environment '$CONDA_ENV_NAME'..."
eval "$(conda shell.bash hook)"
conda activate "$CONDA_ENV_NAME"
if [ $? -ne 0 ]; then
    echo "Failed to activate the conda environment '$CONDA_ENV_NAME'."
    exit 1
fi
echo "Conda environment '$CONDA_ENV_NAME' is now active."

# check nvcc version
nvcc_version=$(nvcc --version | grep release | awk '{print $6}')
echo "Nvcc/CUDA version: $nvcc_version"

# check python version
python_version=$(python --version | awk '{print $2}')
echo "Python version: $python_version"

# Check GLIBCXX version by running Python code
glibcxx_version=$(python3 -c '
import sys
from ctypes.util import find_library
from ctypes import CDLL
libc = CDLL(find_library("c"))
try:
    version = libc.gnu_get_libc_version()
    print(f"{version}")
except AttributeError:
    print("Could not determine GLIBCXX version")
')
echo "GLIBCXX version: $glibcxx_version"

# Check if pytorch is using GLIBCXX
using_CXX11=$(python3 -c '
import torch
print(torch._C._GLIBCXX_USE_CXX11_ABI)
')
echo "Using CXX11 ABI: $using_CXX11"

# check torch version 
torch_version=$(pip show torch | grep Version | awk '{print $2}')
echo "Torch version: $torch_version"

# check torch.cuda.is_available()
cuda_available=$(python3 -c '
import torch
print(torch.cuda.is_available())
')
echo "CUDA available: $cuda_available"

