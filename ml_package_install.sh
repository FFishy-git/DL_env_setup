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

# check CUDA version
if ! command -v nvidia-smi &> /dev/null; then
    echo "nvidia-smi command not found. Please ensure NVIDIA drivers are installed."
    exit 1
else
    CUDA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
    echo "CUDA Version: $CUDA_VERSION"
fi

# check nvcc version
if ! command -v nvcc &> /dev/null; then
    echo "nvcc command not found. Please ensure CUDA toolkit is installed."
    exit 1
else
    NVCC_VERSION=$(nvcc --version | grep release | awk '{print $6}')
    echo "NVCC Version: $NVCC_VERSION"
fi

# Check gcc version
GCC_VERSION=$(gcc --version 2>&1 | grep gcc | awk '{print $3}')
if [[ -z "$GCC_VERSION" ]]; then
    echo "gcc is not installed or not found in PATH."
    exit 1
else
    echo "GCC Version: $GCC_VERSION"
fi

# check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
if [[ -z "$PYTHON_VERSION" ]]; then
    echo "Python3 is not installed or not found in PATH."
    exit 1
else
    echo "Python Version: $PYTHON_VERSION"
fi

# check pip version
PIP_VERSION=$(pip3 --version 2>&1 | awk '{print $2}')
if [[ -z "$PIP_VERSION" ]]; then
    echo "pip3 is not installed or not found in PATH."
    exit 1
else
    echo "pip Version: $PIP_VERSION"
fi

# check if pip is up to date
pip3 install --upgrade pip
if [[ $? -ne 0 ]]; then
    echo "Failed to upgrade pip. Please check your internet connection and try again."
    exit 1
else
    echo "pip upgraded successfully."
fi

apt-get update && apt-get install -y lsb-release
# Check ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
if [[ -z "$UBUNTU_VERSION" ]]; then
    echo "Ubuntu version not found. Please ensure lsb_release is installed."
    exit 1
else
    echo "Ubuntu Version: $UBUNTU_VERSION"
fi

# The `NVCC_VERSION` will be something like V12.8.61, extract the first two parts (12.8) and convert it to a number (128)
NVCC_MAJOR=$(echo "$NVCC_VERSION" | cut -d'.' -f1)
NVCC_MINOR=$(echo "$NVCC_VERSION" | cut -d'.' -f2)
NVCC_VERSION_NUM=$(echo "$NVCC_MAJOR$NVCC_MINOR" | sed 's/^0*//')  # Remove leading zeros
NVCC_VERSION_NUM=$(echo "$NVCC_VERSION_NUM" | tr -cd '0-9')  # remove any non-numeric characters
if [[ -z "$NVCC_VERSION_NUM" ]]; then
    echo "Failed to extract NVCC version number."
    exit 1
else
    echo "NVCC Version Number: $NVCC_VERSION_NUM"
fi

# # Install VLLM package with corresponding PyTorch using the NVCC version number
pip install vllm --extra-index-url "https://download.pytorch.org/whl/cu${NVCC_VERSION_NUM}"
# pip install https://github.com/Lightning-AI/lightning/archive/refs/heads/master.zip -U
pip install lightning
pip install packaging ninja
pip install --upgrade pip wheel

pip install notebook
pip install transformers
pip3 install -U scikit-learn
pip install -U matplotlib
pip install seaborn
pip install pandas
pip install accelerate # must be installed to use huggingface device_map
pip install datasets
pip install -U "huggingface_hub[cli]"

pip install wandb
# setup wandb API
read -s -p "Enter your wandb API key (press Enter to skip): " wandb_api_key
echo  # Add newline after hidden input

if [[ -n $wandb_api_key ]]; then
    # Only export if a key was entered
    export WANDB_API_KEY=$wandb_api_key
    echo "WANDB_API_KEY has been set, no need to login again."
else
    echo "No API key entered, proceeding without wandb key."
    echo "You can set it later by running 'wandb login' command."
fi


# setup git config
read -p "Enter your Git username (press Enter to skip): " git_username
if [[ -n "$git_username" ]]; then
    git config --global user.name "$git_username"
    echo "Git username has been set to '$git_username'."
else
    echo "No Git username entered, proceeding without setting username."
    echo "You can set it later by running 'git config --global user.name <username>'"
fi

read -p "Enter your Git email (press Enter to skip): " git_email
if [[ -n "$git_email" ]]; then
    git config --global user.email "$git_email"
    echo "Git email has been set to '$git_email'."
else
    echo "No Git email entered, proceeding without setting email."
    echo "You can set it later by running 'git config --global user.email <email>'"
fi

git config --global init.defaultBranch main
# print git config
echo "Current Git configuration:"
git config --list --show-origin
git config --global credential.helper store

# setup Huggingface token
read -s -p "Enter your Huggingface token (press Enter to skip): " hf_token
echo  # newline for better formatting

if [[ -n "$hf_token" ]]; then
    export HUGGINGFACE_TOKEN="$hf_token"
    echo "HUGGINGFACE_TOKEN has been set."
    # Optionally, you can also log in to Huggingface
    huggingface-cli login --token "$HUGGINGFACE_TOKEN" --add-to-git-credential
else
    echo "No Huggingface token entered, proceeding without token."
    echo "You can set it later by running 'huggingface-cli login --token <your_token> --add-to-git-credential'"
fi


# Let's conduct some checks 
echo "Conducting environment checks..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ====== check torch usage ======
source "$SCRIPT_DIR/env_checker/cuda_env_check.sh"

# ===== install flash attention =====
echo "Installing Flash Attention..."
pip uninstall flash-attn -y  # Uninstall any existing flash-attn package1
source "$SCRIPT_DIR/additional_packages/flash_attn_install.sh" "whl"

# ===== check the installation =====
echo "Checking the installation..."
source "$SCRIPT_DIR/env_checker/test_install.sh"