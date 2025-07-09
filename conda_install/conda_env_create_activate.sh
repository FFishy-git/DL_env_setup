#!/bin/bash
# This script creates a new conda environment with a user-defined name and Python 3.8

# Ensure conda is available
if ! command -v conda &>/dev/null; then
    echo "conda is not installed. Please install Anaconda or Miniconda first."
    exit 1
fi

# Prompt the user for the environment name
read -p "Enter the conda environment name (press ENTER to skip): " ENV_NAME
read -p "Enter the Python version (default is 3.8) (press ENTER to skip): " PYTHON_VERSION
# Set default Python version if not provided
PYTHON_VERSION=${PYTHON_VERSION:-3.8}

# Check if the environment name is provided
if [ -z "$ENV_NAME" ]; then
    echo "Environment name is empty. Skip creating a new environment."
    return 1
fi


# Check if the environment already exists
if conda env list | grep -q "$ENV_NAME"; then
    echo "Environment '$ENV_NAME' already exists. Skipping creation."
else
    echo "Creating new conda environment: $ENV_NAME with Python $PYTHON_VERSION..."
    conda create -y -n "$ENV_NAME" python="$PYTHON_VERSION"
    if [ $? -ne 0 ]; then
        echo "Failed to create conda environment '$ENV_NAME'."
        exit 1
    fi
    echo "Conda environment '$ENV_NAME' created successfully."
fi

# Activate the new environment
echo "Activating the conda environment '$ENV_NAME'..."
eval "$(conda shell.bash hook)"
conda init bash && echo "conda activate $ENV_NAME" >> ~/.bashrc
conda activate "$ENV_NAME"
if [ $? -ne 0 ]; then
    echo "Failed to activate the conda environment '$ENV_NAME'."
    exit 1
fi
echo "Conda environment '$ENV_NAME' is now active."
echo "You might need to restart the terminal to see the changes, or run the following command: source ~/.bashrc"