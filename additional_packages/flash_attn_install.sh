#!/bin/bash
# To run this script, type the following command in the terminal:
# bash path/to/flash_attn_install.sh whl
# This will prompt you to enter the wget URL for flash-attention.
# If you do not have a wget URL, you can skip this step by pressing Enter.
# The script will then install flash-attention with the default settings.

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

# check torch version 
torch_version=$(pip show torch | grep Version | awk '{print $2}')
echo "Torch version: $torch_version"

# check nvcc version
nvcc_version=$(nvcc --version | grep release | awk '{print $6}')
echo "Nvcc/CUDA version: $nvcc_version"

# check python version
python_version=$(python --version | awk '{print $2}')
echo "Python version: $python_version"

# convert python version to number
PYTHON_MAJOR=$(echo "$python_version" | cut -d'.' -f1) # 3
PYTHON_MINOR=$(echo "$python_version" | cut -d'.' -f2) # 8
PYTHON_VERSION_NUM=${PYTHON_MAJOR}${PYTHON_MINOR} # 38

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

# The `NVCC_VERSION` will be something like V12.8.61, extract the first part (12) and convert it to a number (12)
NVCC_MAJOR=$(echo "$nvcc_version" | cut -d'.' -f1)
NVCC_VERSION_NUM=$(echo "$NVCC_MAJOR" | sed 's/^0*//')  # Remove leading zeros
NVCC_VERSION_NUM=$(echo "$NVCC_VERSION_NUM" | tr -cd '0-9')  # remove any non-numeric characters
if [[ -z "$NVCC_VERSION_NUM" ]]; then
    echo "Failed to extract NVCC version number."
    exit 1
else
    echo "NVCC Version Number: $NVCC_VERSION_NUM"
fi

# for torch version like 2.5.0, the we need the fist two parts (2.5)
TORCH_MAJOR=$(echo "$torch_version" | cut -d'.' -f1) # 2
TORCH_MINOR=$(echo "$torch_version" | cut -d'.' -f2) # 5
TORCH_VERSION_NUM=${TORCH_MAJOR}.${TORCH_MINOR} # 2.5

# Flash attention only supports linux_x86_64 for whl
if [ "$1" = "whl" ]; then
    # check if the system is linux_x86_64
    if [ "$(uname -m)" != "x86_64" ]; then
        echo "Flash attention only supports linux_x86_64 for whl installation"
        exit 1
    fi
fi


# Check if argument is provided
if [ "$1" = "whl" ]; then
    echo "Installing flash-attention with whl settings..."
    echo "You can find the wget URL for flash-attention at https://github.com/Dao-AILab/flash-attention/releases, For your system, the recommanded tag is: flash_attn-2.8.0.post2+cu${NVCC_VERSION_NUM}torch${TORCH_VERSION_NUM}cxx11abi${using_CXX11}-cp${PYTHON_VERSION_NUM}-cp${PYTHON_VERSION_NUM}-linux_x86_64.whl To proceed, please follow these steps:"
    echo "- If you locate the file, right-click on the file and select 'Copy Link Address' to get the wget URL."
    echo "- If you do not have a wget URL, you can skip this step by pressing Enter. The script will then install flash-attention with the default 'pip install flash-attn --no-build-isolation --use-pep517' command."
    echo "⚠️ Attention for Yale cluster users: If you are using the Yale cluster, GLIBC version is older than 2.32, which is not compatible with the most recent flash-attention wheels. You can try to install an older version 2.7.4.post1 compiled with pytorch 2.6. This version is even compatible with pytorch 2.7.0. See the issue at https://github.com/Dao-AILab/flash-attention/issues/1644#issuecomment-2899396361"
    # Prompt user for wget URL
    read -p "Enter the wget URL for flash-attention (Press Enter to exit): " WGET_URL

    # Validate URL is not empty
    if [ -z "$WGET_URL" ]; then
        echo "URL is empty, using the default installation command."
        echo "Installing flash-attention with default settings..."
        pip install flash-attn --no-build-isolation --use-pep517
    else
    
        echo "Using URL: $WGET_URL"

        # before downloading, check if the file already exists
        file_name=$(basename $WGET_URL)
        if [ -f "$file_name" ]; then
            echo "File already exists. Skipping download."
        else
            wget $WGET_URL
        fi

        pip install $file_name

        # delete the downloaded file
        rm $file_name
        echo "File $file_name deleted."
    fi
else
    echo "Installing flash-attention with default settings..."
    pip install flash-attn --no-build-isolation --use-pep517
fi