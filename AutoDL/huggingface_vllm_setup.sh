#!/bin/bash
# This script creates a new conda environment with a user-defined name and Python 3.8

# Ensure conda is available
if ! command -v conda &>/dev/null; then
    echo "conda is not installed. Please install Anaconda or Miniconda first."
    exit 1
fi


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

# change the huggingface mirror
conda init bash && echo "conda activate $CONDA_ENV_NAME" >> ~/.bashrc
conda activate $CONDA_ENV_NAME
conda env config vars set HF_ENDPOINT='https://hf-mirror.com'
# check if the huggingface mirror is set
conda env config vars list | grep HF_ENDPOINT

# change the huggingface model cache path 
conda env config vars set HF_HOME='/root/autodl-tmp/.cache/huggingface'
# check if the huggingface cache path is set
conda env config vars list | grep HF_HOME

# change the huggingface data cache path
conda env config vars set HF_DATA_HOME='/root/autodl-tmp/.cache/huggingface/datasets'
# check if the huggingface data cache path is set
conda env config vars list | grep HF_DATA_HOME

# change the vllm cache path
conda env config vars set VLLM_CACHE_ROOT='/root/autodl-tmp/.cache/vllm'
# check if the vllm cache path is set
conda env config vars list | grep VLLM_CACHE_ROOT
